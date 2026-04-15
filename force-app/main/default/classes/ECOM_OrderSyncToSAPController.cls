/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-130    
*
* 2. Description - This class is used to send Order to SAP
*
*
* 3. Objects referenced
*    - Order
*    - Order Items
*
* 4. Callouts to additional Components (including their methods) or None:
*    - Yes
*
* 5. Dependant Class(es):
*    - ECOM_OrderService
* 
* 6. Test Class Name: 
*    - ECOM_OrderSyncToSAPController_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Rani Thumma 2023.09.13
*	 - Sathiya 2024.06.11 changes done per the dependent method structure change generateOrderCreateRequest
*    - Sidak 2024.12.18 Added check for DML statements before callout. RWPS-2185
*************************************************************/
public class ECOM_OrderSyncToSAPController {
    
    public static String CLASSNAME = 'ECOM_OrderSyncToSAPController';
    
    @AuraEnabled
    public static Map<String,Object> syncOrderToSAP(String recordId){
        Map<String,Object> responseMap = new  Map<String,Object>();
        Set<String> orderIds = new Set<String>();
        String supportData = '';
        List<Order> ordersToUpdate = new List<Order>();
        List<OrderItem> orderItemsToUpdate = new List<OrderItem>();
        List<ECOM_OrderCreateFlowWrapper.Response> response = new List<ECOM_OrderCreateFlowWrapper.Response>();
        try {
            supportData = JSON.serialize(recordId);
            Type orderService = Type.forName(ECOM_Constant.ORDER_SERVICE);
            ECOM_IOrderService orderServiceInstance = (ECOM_IOrderService)orderService.newInstance();
            orderIds.add(recordId);
            // fetch orders
            List<Order> orders = orderServiceInstance.getOrdersById(orderIds);
            List<PaymentAuthorization> payments;
            List<CardPaymentMethod> cardPayments;
            if(orders != null && orders.size() > 0){
                if(orders[0].ECOM_SAP_Order_Number__c == null && orders[0].Status == 'Draft' && orders[0].ECOM_Order_On_Hold__c == false &&(orders[0].ECOM_Order_Create_Retry__c == null || orders[0].ECOM_Order_Create_Retry__c < 5)){
                    
                    String contactSAPNumber = null;
                    User us = new ECOM_UserService().getUserByUser(String.valueOf(orders[0].OwnerId)); 
                    // fetch SAP Contact number from ERP relationships
                    Type erpAddressService = Type.forName(ECOM_Constant.ERP_ADDRESS_SERVICE);
        			ERP_IAddressService erpAddressServiceInstance = (ERP_IAddressService)erpAddressService.newInstance();
                    List<ERP_RelationShip__c> erpRelationships = erpAddressServiceInstance.fetchERPRelationshipsByERPAddress(us.ContactId, String.valueOf(orders[0].Default_Ship_to_ERP_Address__r.Target_Address__c));
                    if(erpRelationships != null && erpRelationships.size() > 0){
                        contactSAPNumber = erpRelationships[0].ERP_Contact_ID__c;
                    }
                    // fetch credit card payment details if PO Number is empty
                    if(orders[0].PoNumber == null){
                        payments = orderServiceInstance.getPaymentAuthorizationBasedOnOrder(String.valueOf(orders[0].Id));
                        cardPayments = orderServiceInstance.getCardPaymentBasedOnOrder(String.valueOf(orders[0].Id));
                    }
                    // Changes done by sathiya on 2024.06.11
                    ECOM_OrderSummaryRequestWrapper orderRequest = ECOM_OrderCreateAPIUtil.generateOrderCreateRequest(orders[0], contactSAPNumber, payments, cardPayments, us);
                    // Changes End
          			System.debug('orderRequest'+orderRequest);
                    System.debug('dmllimit ' + Limits.getDMLStatements());
                    if(Limits.getDMLStatements() == 0 || Test.isRunningTest()){ //RWPS-2185
                        //Do Order Create callout
                        HttpResponse httpRes = ECOM_OrderCreateAPIUtil.orderCreateAPICallout(orderRequest);
                        System.debug('httpRes'+httpRes);
                        
                        ECOM_OrderCreateFlowWrapper.OrdersAndOrderItems itemsToUpdate = ECOM_OrderCreateAPIUtil.parseOrderCreateAPIResponse(orderRequest, httpRes, orders[0]);
                        
                        //Update orders with SAP order number(Success) or Retry count and Error message(Failure)
                        if(itemsToUpdate != null){
                            if(itemsToUpdate.orders != null){
                                ordersToUpdate.addAll(itemsToUpdate.orders);
                            }
                            if(itemsToUpdate.orderItems != null){
                                orderItemsToUpdate.addAll(itemsToUpdate.orderItems);
                            }
                            ECOM_OrderUtil.updateOrders(ordersToUpdate);
                        }
                        //Log Request and response
                        supportData = orders[0].Id + ' \n'+'Request - '+JSON.serialize(orderRequest);
                        ECOM_ApplicationLogsUtil.setupApplicationRecord(ECOM_Constant.ORDER_MODULE_NAME, className, 'syncOrderToSAP', supportData,'Response - '+httpRes.getBody(), 'OC');
                        // Update Order 
                        if(!orderItemsToUpdate.isEmpty()){
                            orderServiceInstance.updateOrderItems(orderItemsToUpdate);
                        }
                        //Update Order Items
                        if(!ordersToUpdate.isEmpty()){
                            orderServiceInstance.updateOrders(ordersToUpdate);
                        }
                        responseMap.put('Status','Success');
                        responseMap.put('ErrorMessage', 'Order on Hold');
                    }
                }
                responseMap.put('Status','Error');
            }
        }catch(Exception ex){
            responseMap.put('Status','Error');
            responseMap.put('ErrorMessage', ex.getMessage());
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.ORDER_MODULE_NAME, className, 'syncOrderToSAP', supportData);
        }
        return responseMap;
    }
}