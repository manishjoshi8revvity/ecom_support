/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-3225
*
* 2. Description - This class is used for getting order-related data from Salesforce Objects of SAP_Order_Summary__c and Order to be used in Self-Service Application.
*
* 3. Objects referenced
*   - Order
*   - SAP_Order_Summary__c
*   - Product2
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_ApplicationLogsUtil
*
* 6. Test Class Name: ECOM_SelfServiceRepo_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Abhishek 2024.06.19
*	 - Manish Joshi 2024.12.13 Added method getOrgType, used to fetch org type using custom setting. Ticket - RWPS-1662
*    - Abhishek Joshi 2025.01.21 - Added getNonShippableItems method - RWPS-2227
*    - Abhishek Joshi 2025.05.02 - Added getSelfServiceMetadata method - RWPS-3289
*    - Abhishek Joshi 2025.10.27 - Added getAddressesFromHierarchyNumberAndSalesOrg and searchOrdersByCustomerDataAndSearchTerm methods - RWPS-3834
*
*************************************************************/

public without sharing class ECOM_SelfServiceRepo {
    public static final String EMPTY_STRING = '';

    /**
     * @description This method returns SAP order data from Salesforce.
     * @author abhishek.joshi@revvity.com | 17 June 2024
     * @param orderNumberPadded | String
     * @param orderNumber | String
     * @param poNumberOrPostalCode | String
     * @return List<SAP_Order_Summary__c>
     */
    public static List<SAP_Order_Summary__c> findSelfServiceOrderDataFromSAPOrderSummary(
        String orderNumberPadded, String orderNumber, String poNumberOrPostalCode
    ) {
        // Order numbers are received from user input. For security purpose, below approach is used instead of direct query.
        String dynamicQuery = 'SELECT Name, Order__r.CreatedDate FROM SAP_Order_Summary__c WHERE (Name =: orderNumber OR Order__r.OrderNumber =: orderNumberPadded)';
        return Database.query(String.escapeSingleQuotes(dynamicQuery));
    }

    /**
     * @description This method returns Order data from Salesforce (Will only be used if Order not present in SAP Order Summary).
     * @author abhishek.joshi@revvity.com | 17 June 2024
     * @param orderNumberPadded | String
     * @param orderNumber | String
     * @param poNumberOrPostalCode | String
     * @return List<Order>
     */
    public static List<Order> findSelfServiceOrderDataFromOrder(
        String orderNumberPadded, String orderNumber, String poNumberOrPostalCode
    ) {
        String dynamicQuery =
            'SELECT OrderNumber, PoNumber, CreatedDate, TotalAmount, CurrencyIsoCode, count_items__c, ECOM_Order_Summary_Status__c, Default_Ship_to_ERP_Address__r.fxCustomerNumber_Master__c, Default_Ship_to_ERP_Address__r.fxAccountName__c, Default_Ship_to_ERP_Address__r.fxAddressFull__c, Default_Bill_to_ERP_Address__r.fxAddressFull__c, CustomerAuthorizedBy.ECOM_Attention_Recipient__c, ' +
            '(SELECT Product2.ProductCode, Description, Quantity, ECOM_Status__c FROM OrderItems WHERE Product2.ProductCode !=: EMPTY_STRING) ' +
            'FROM Order WHERE (OrderNumber =: orderNumberPadded OR ECOM_SAP_Order_Summary__r.Name =: orderNumber)';

        if(!String.isBlank(poNumberOrPostalCode)) {
            dynamicQuery += ' AND (PoNumber =: poNumberOrPostalCode OR ShippingPostalCode =: poNumberOrPostalCode)';
        }

        dynamicQuery += ' LIMIT 1';

        return Database.query(String.escapeSingleQuotes(dynamicQuery));
    }

    /**
     * @description This method returns the non shippable part numbers among given list
     * @author abhishek.joshi@revvity.com | 2025.01.21
     * @param partNumbers | List<String>
     * @return List<Product2>
     */
    public static List<Product2> getNonShippableItems(List<String> partNumbers) {
        List<String> nonShippableItemClass =
            System.Label.ECOM_Self_Service_Non_Shippable_Products_Item_Classes.split(',');
        return [SELECT Part_Number__c FROM Product2 WHERE Part_Number__c IN :partNumbers AND Item_Class__c IN :nonShippableItemClass];
    }

    /**
    * @description This method is used to check if an org is sandbox or not using custom setting
    * @author Manish | 2024.12.13 | RWPS-1662
    **/
    public static Boolean getOrgType()
    {
        C_SET_9999_ORG_SETTINGS__c settings = C_SET_9999_ORG_SETTINGS__c.getInstance();
        return settings.isSBX__c;
    }

    /**
    * @description This method is used to get self service metadata
    * @author Abhishek | 2025.05.27 | RWPS-1662
    **/
    public static ECOM_Selfservice_Setting__mdt getSelfServiceMetadata(String metadataName) {
        return [SELECT Value__c FROM ECOM_Selfservice_Setting__mdt WHERE DeveloperName = :metadataName LIMIT 1];
    }

    /**
    * @description This method is used to get addresses from hierarchy number
    * @author Abhishek | 2025.10.27 | RWPS-3834
    **/
    public static List<ERP_Address__c> getAddressesFromHierarchyNumberAndSalesOrg(String hierarchyNumber, String salesOrg) {
        return [SELECT fxCustomerNumber_Master__c FROM ERP_Address__c WHERE Master_Address__r.ERP_Customer_Base_Number__c = :hierarchyNumber AND Address_Type__c = 'Sold To' AND ERP_Sales_Org__c = :salesOrg];
    }

    /**
    * @description This method is used to get order data using customer data and search term
    * @author Abhishek | 2025.10.27 | RWPS-3834
    **/
    public static List<AggregateResult> searchOrdersByCustomerDataAndSearchTerm(Set<String> soldToCustomerNumbers, String searchString, Integer startDateMonthOffset) {
        Date startDate = Date.today().addMonths(startDateMonthOffset);

        return [
            SELECT PKI_Order_Summary__r.Name OrderNumber, PKI_Order_Summary__r.Customer_PO_Number__c CustomerPONumber, PKI_Order_Summary__r.Actual_Order_Date__c OrderDate, PKI_Order_Summary__r.Ship_To_Address_Postal_Code__c PostalCode, MAX(PKI_Order_Summary__r.fxStatusB2B__c) OrderStatus
            FROM SAP_Order_Items__c
            WHERE
            (
                PKI_Order_Summary__r.Sold_To_ERP_Address__r.fxCustomerNumber_Master__c IN :soldToCustomerNumbers OR
                PKI_Order_Summary__r.Sold_To_Customer_Id__c IN :soldToCustomerNumbers
            ) AND
            (
                PKI_Order_Summary__r.Name LIKE :('%' + searchString + '%') OR
                PKI_Order_Summary__r.Customer_PO_Number__c LIKE :('%' + searchString + '%') OR
                Material_Number__c LIKE :('%' + searchString + '%')
            ) AND
            (
                PKI_Order_Summary__r.Actual_Order_Date__c >= :startDate OR
                (
                    PKI_Order_Summary__r.Actual_Order_Date__c = null AND
                    DAY_ONLY(PKI_Order_Summary__r.CreatedDate) >= :startDate
                )
            )
            GROUP BY PKI_Order_Summary__r.Name, PKI_Order_Summary__r.Customer_PO_Number__c, PKI_Order_Summary__r.Actual_Order_Date__c, PKI_Order_Summary__r.Ship_To_Address_Postal_Code__c
            ORDER BY MAX(PKI_Order_Summary__r.Actual_Order_Date__c) DESC, MAX(PKI_Order_Summary__r.CreatedDate) DESC
            LIMIT 2000
        ];
    }
}