/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-3225
*
* 2. Description - This class is used as controller in Self-Service Application. It manages to get order details from SAP. If the details are not found, it checks the Order object for matching details. Additionally, it also ensures SSO authentication with Microsoft Entra and returns an encrypted session to be stored on browser
*
* 3. Objects referenced
*   - SAP_Order_Summary__c
*   - Order
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_ApplicationLogsUtil
*    - ECOM_SelfServiceUtils
*    - ECOM_SelfServiceRepo
*
* 6. Test Class Name: ECOM_SelfServiceController_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Abhishek Joshi 2024.06.19
*    - Abhishek Joshi 2025.01.21 - Added getNonShippableItems method - RWPS-2227
*    - Abhishek Joshi 2025.05.02 - Updated getOrderDetails method - RWPS-3289
*    - Manish Joshi 2025.06.18 - Updated getOrderDetails method - RWPS-3293
*    - Abhishek Joshi 2025.10.27 - Added getOrdersFromHierarchyNumber method - RWPS-3834
*
*************************************************************/

public with sharing class ECOM_SelfServiceController {
    private static final String CLASS_NAME = 'ECOM_SelfServiceController';

    /**
     * @description This method returns the order details if correct data is entered by user
     * @author abhishek.joshi@revvity.com | 17 June 2024
     * @param dataMap | Map<String, Object>
     * @return Map<String, Object>
     */
    @AuraEnabled
    public static Map<String, Object> getOrderDetails(Map<String, Object> dataMap) {
        String userEmail = 'Guest';
        try {
            String orderNumber = (String) dataMap.get('orderNumber');
            String orderNumberPadded = (String) dataMap.get('orderNumberPadded');
            String poNumberOrPostalCode = (String) dataMap.get('poNumberOrPostalCode');

            Boolean loggedInAttempt = String.isBlank(poNumberOrPostalCode);

            Map<String, Object> responseMap = new Map<String, Object>();

            // Check if it is a Revvity SSO user (If so, no need of verification via PO number/Postal Code)
            if(loggedInAttempt) {
                String encryptedSession = (String) dataMap.get('encryptedSession');
                Map<String,Object> userData = ECOM_SelfServiceUtils.getUserData(encryptedSession);

                String email = (String) userData.get('email');

                if(String.isNotBlank(email)) {
                    userEmail = email;
                }

                if(String.isBlank(encryptedSession) || (Integer) userData.get('success') != 1
                ) {
                    responseMap.put('loginError', (Object) true);
                    return responseMap;
                }
            }

            // Check for data is SAP_Order_Summary__c object
            List<SAP_Order_Summary__c> sapOrderDetails =
                ECOM_SelfServiceRepo.findSelfServiceOrderDataFromSAPOrderSummary(
                    orderNumberPadded,
                    orderNumber,
                    poNumberOrPostalCode
                );

            String sapOrderNumber = orderNumber;
            Boolean sapOrderDetailsFound = sapOrderDetails.size() > 0;
            if(sapOrderDetailsFound) {
                if(String.isNotBlank(sapOrderDetails[0].Name)) {
                    sapOrderNumber = sapOrderDetails[0].Name;
                }
            }

            Map<String, Object> sapData = ECOM_SelfServiceService.getOrderFromSAP(sapOrderNumber);
            String SAPResponseIndicatorKey = ECOM_SelfServiceConstants.SAP_RESPONSE_INDICATOR_KEY;
            if(sapData.containsKey(SAPResponseIndicatorKey) && (Boolean) sapData.get(SAPResponseIndicatorKey)) {
                // RWPS-3289 start
                ECOM_Selfservice_Setting__mdt excludedOrderTypes =
                    ECOM_SelfServiceRepo.getSelfServiceMetadata(
                        ECOM_SelfServiceConstants.EXCLUDED_ORDER_TYPES_METADATA
                    );

                String orderTypeKey = ECOM_SelfServiceConstants.SAP_RESPONSE_ORDER_TYPE_KEY;
                //RWPS-3293 - START
                Set<String> excludedOrderTypesSet;
                if(!String.isBlank(excludedOrderTypes.Value__c))
                {
                    List<String> excludedOrderTypesList = excludedOrderTypes.Value__c.split(',');
                    excludedOrderTypesSet = new Set<String>(excludedOrderTypesList);
                }
                //RWPS-3293 - END
                if(
                    (
                        loggedInAttempt ||
                        sapData.get('PONumber') == poNumberOrPostalCode ||
                        sapData.get('ShippingPostalCode') == poNumberOrPostalCode
                    ) && (
                        //String.isBlank(excludedOrderTypes?.Value__c) || //RWPS-3293 - START
                        excludedOrderTypesSet.isEmpty() ||
                        !sapData.containsKey(orderTypeKey) ||
                        //!excludedOrderTypes.Value__c.contains((String) sapData.get(orderTypeKey))
                        !excludedOrderTypesSet.contains((String) sapData.get(orderTypeKey)) //RWPS-3293 - END
                    )
                ) {
                    // RWPS-3289 end
                    responseMap.put('sapOrder', (Object) sapData);

                    if(sapOrderDetailsFound) {
                        responseMap.put('Order__r', (Object) sapOrderDetails[0].Order__r);
                    }

                    if(!loggedInAttempt) {
                        sapData.remove('customerWillAcceptDate');
                        sapData.remove('creditStatus');
                        sapData.remove('DeliveryBlock');
                        sapData.remove('DeliveryBlockDescription');
                    }
                    responseMap.put('SAPOrderNumber', (Object) sapOrderNumber);
                    // RWPS-3289 start
                    ECOM_Selfservice_Setting__mdt trackingMap =
                        ECOM_SelfServiceRepo.getSelfServiceMetadata(
                            ECOM_SelfServiceConstants.TRACKING_MAP_METADATA
                        );
                    responseMap.put('trackingMap', (Object) (trackingMap?.Value__c));
                    // RWPS-3289 end
                }
                return responseMap;
            }

            // Check for data in Order object in case it is not yet in SAP
            List<Order> orderDetails = ECOM_SelfServiceRepo.findSelfServiceOrderDataFromOrder(orderNumberPadded, orderNumber, poNumberOrPostalCode);

            if(orderDetails.size() > 0) {
                responseMap.put('orderData', (Object) orderDetails[0]);
                return responseMap;
            }

            return responseMap;
        } catch (Exception e) {
            ECOM_SelfServiceUtils.selfserviceLogException(new Map<String, Object> {'className' => (Object) CLASS_NAME, 'methodName' => (Object) 'getOrderDetails', 'moduleName' => (Object) 'SelfServiceControllerOrderDetails', 'supportData' => (Object) ('User: ' + userEmail + ' || Cause: ' + e.getCause())}, e);
            return new Map<String, Object>{};
        }

    }

    /**
     * @description This method returns the encrypted user data after receiving data from Entra using access token
     * @author abhishek.joshi@revvity.com | 17 June 2024
     * @param accessToken | String
     * @param email | String
     * @param sub | String
     * @return Map<String, Object>
     */
    @AuraEnabled
    public static Map<String, String> authWithEntra(String accessToken, String email, String sub) {
        return ECOM_SelfServiceService.authWithEntra(accessToken, email, sub);
    }

    /**
     * @description This method returns the name and verifies the authenticity on internal Revvity user
     * @author abhishek.joshi@revvity.com | 17 June 2024
     * @param encryptedData | String
     * @return Map<String, Object>
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getUserData(String encryptedData) {
        return ECOM_SelfServiceUtils.getUserData(encryptedData);
    }

    /**
     * @description This method returns the non shippable part numbers among given list
     * @author abhishek.joshi@revvity.com | 2025.01.21
     * @param partNumbers | List<String>
     * @return List<Product2>
     */
    @AuraEnabled(cacheable=true)
    public static List<Product2> getNonShippableItems(List<String> partNumbers) {
        return ECOM_SelfServiceRepo.getNonShippableItems(partNumbers);
    }

    /**
     * @description This method returns the orders for the order listing page using hierarchy number and search term
     * @param requestMap | Map<String, Object>
     * @return List<Map<String, Object>>
     * @author Abhishek Joshi | 2025.10.28 - RWPS-3834
     */
    @AuraEnabled
    public static List<Map<String,Object>> getOrdersFromHierarchyNumber(Map<String, Object> requestMap) {
        String hierarchyNumber = requestMap.containsKey('hierarchyNumber') ? (String) requestMap.get('hierarchyNumber') : '';
        String searchString = requestMap.containsKey('searchString') ? (String) requestMap.get('searchString') : '';
        String salesOrg = requestMap.containsKey('salesOrg') ? (String) requestMap.get('salesOrg') : '';
        Integer startDateMonthOffset = requestMap.containsKey('startDateMonthOffset') ? Integer.valueOf(requestMap.get('startDateMonthOffset')) : 0;

        String hierarchyNumberDecrypted;
        String searchStringDecrypted;
        String salesOrgDecrypted;
        List<Map<String,Object>> orderList = new List<Map<String,Object>>();
        try {
            hierarchyNumberDecrypted = ECOM_EncryptUtil.decryptWithAES256(hierarchyNumber);
            searchStringDecrypted = ECOM_EncryptUtil.decryptWithAES256(searchString);
            salesOrgDecrypted = ECOM_EncryptUtil.decryptWithAES256(salesOrg);

            List<ERP_Address__c> addressList =
                ECOM_SelfServiceRepo.getAddressesFromHierarchyNumberAndSalesOrg(hierarchyNumberDecrypted, salesOrgDecrypted);

            Set<String> soldToCustomerNumbers = new Set<String>();
            for(ERP_Address__c addr : addressList) {
                String master = addr.fxCustomerNumber_Master__c;
                if(String.isNotBlank(master)) {
                    soldToCustomerNumbers.add(master);
                }
            }
            List<AggregateResult> orderAggregateResults =
                ECOM_SelfServiceRepo.searchOrdersByCustomerDataAndSearchTerm(
                    soldToCustomerNumbers, searchStringDecrypted, startDateMonthOffset
                );

            for(AggregateResult ar : orderAggregateResults) {
                Map<String,Object> orderMap = new Map<String,Object>();
                orderMap.put('OrderNumber', ar.get('OrderNumber'));
                orderMap.put('CustomerPONumber', ar.get('CustomerPONumber'));
                orderMap.put('OrderDate', ar.get('OrderDate'));
                orderMap.put('OrderStatus', ar.get('OrderStatus'));
                orderMap.put('PostalCode', ar.get('PostalCode'));
                orderList.add(orderMap);
            }
        } catch(Exception e) {
            ECOM_SelfServiceUtils.selfserviceLogException(new Map<String, Object> {'className' => (Object) CLASS_NAME, 'methodName' => (Object) 'getOrdersFromHierarchyNumber', 'moduleName' => (Object) 'SelfServiceControllerOrderListing', 'supportData' => (Object) ('HierarchyNumber: ' + hierarchyNumber + 'hierarchyNumberDecrypted: ' + hierarchyNumberDecrypted + 'SearchString: ' + searchString + 'SearchStringDecrypted: ' + searchStringDecrypted + ' || Cause: ' + e.getCause())}, e);
        }
        return orderList;
    }
}