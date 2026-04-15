/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-109
*
* 2. Description - This class acts as an Repository class for Order.
*
* 3. Objects referenced
*    - Order
*    - Order Item
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_OrderService
*
* 6. Test Class Name:
*    - ECOM_OrderService_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Manoj 2023.08.07
*    - Sathiya 2024.04.29 - Adding fields realated for ECOM-1933 and ECOM -1942
*    - Gaurang 2024.05.02 - new rollup field for getting sum of quantities - 2 May 2024 - ECOM-3150, ECOM-95
*    - Vipul Goyal 2024.05.03 - Updated getOrdersById.
*    - Vipul Goyal 2024.05.06 - Added getOrdersForApproval.(ECOM-103)
*    - Gaurang Arora 2024.05.12 - Added additional fields in SOQL queries - ECOM-112
*    - Sathiya 2024.05.13 - Added invoice fields to relevant queries.
*    - Sathiya 2024.05.15 - Added a method to validate exisiting erp address linked to the orders based on owner (getOrderBasedOnOwnerByErpAddressTypes)
*    - Manoj 2024.05.03 RWPS-553 Sending Contact ID to SAP(updated getOrdersById & getOrderById method with SAP_Contact_ID__c field )
*    - Manoj 2024-05-06 RWPS-622 Hide Availability date when the Order contains an Instrument(updated getOrderById, findOrderByOrderNumberAndZip, fetchOrdersBySAPOrderId   )
*    - Sathiya 2024-06-11 Fields added for ECOM-3257 on getOrdersById method
*    - Gaurang 2024.06.04 - ECOM-1931 - As boomi is populating sales org, we are going to refer sales org from ship to in order
*    - Sidak 2024.06.11 Updated method getOrdersById, added Owner.FirstName, Owner.LastName, Owner.Email fields in query. Ticket: RWPS-554
*    - Gaurang 2024.06.24 Added ERP_Invoice_Number__c field in Invoice queries - ECOM-3304
*    - Sathiya 2024.06.27 - Added invoice fields to relevant queries. ECOM-3389
*    - Gaurang 2024.07.01 - added a method that queries user object, and returns list of emails matching criteria - ECOM-3322
*    - Sathiya 2024.07.01 - Adding fields for Target Address for ECOM-3410
*    - Sidak 2024.09.09 Updated method getOrderDetails. Added Default_Ship_to_ERP_Address__r.fxCustomerName_Master__c in query. Ticket - RWPS-1306
*    - Sidak 2024.09.13 Updated method getOrdersById. Added fxContactEmail__c in query. Ticket - RWPS-1236
*    - Sidak 2024.12.06 Added new field ECOM_ApprovalRejection_Comment__c in getOrderDetails method. RWPS-1885
*    - Gaurav Bhansali 2024.12.31 RWPS-2052 - Added checkIfCouponUsed method to check coupon already used on any order or not.
*    - Gaurav Bhansali 2025.01.15 RWPS-2307 - Added getUserOrderCount method to return user order count.
*    - Manish Joshi 2025.01.27 RWPS-2270 - Updated method getOrdersById to retrieve prodyct display name
*    - Manish Joshi 2025.02.28 - updated method getUserOrderCount declaration & made it generic by adding parameter userId - RWPS-2684
*    - Prabhat Kumar 2025.04.01 - Added method getOrderItems to return the Order Item - RWPS-2855
*    - Gaurav Bhansali 2025.04.21 - Updated getOrdersById to return large pack order properties- RWPS-1285
*    - Poonam Shukla 2025.04.24 - Updated getOrdersById, getOrderDetails. Added Total_Tariff_Surcharge__c, Tariff_Surcharge__c in query- RWPS-3026
*    - Poonam Shukla 2025.06.13 - Updated method getOrdersById. Added Invoice_Email__c - RWPS-1882
*    - Prabhat Kumar 2025.06.19 - Updated method getMyOrders - RWPS-2786
*    - Manish Joshi 2025.07.10 - Updated Method getMyOrders, removed unused code - RWPS-3657
*    - Gaurav Bhansali 2025.08.04 - Added fxCustomerName_Target__c in getOrderDetails method response - RWPS-3868
*    - Gaurav Bhansali 2025.08.22 - Added ecom_parent_item__c in getOrdersById and getOrderDetails method response - RWPS-3811
*    - Prabhat Kumar 2025.08.22 - Updated method getOrderDetails,getOrdersById to get the data - RWPS-3811
*    - Prabhat Kumar 2025.09.11 - Updated method getOrdersById's query with field ECOM_SAP_Line_Number__c  - RWPS-3811
*    - Sachin Vispute 2025.10.28 - Created method getOnlineOrders - RWPS-4881
*    - Sachin Vispute 2025.11.17 - Updated method getOnlineOrders - RWPS-5094
*    - Sachin Vispute 2025.12.08 - Updated method getOnlineOrders (PO Type condition) - RWPS-5094
*    - Sachin Vispute 2025.12.30 - Updated method getOrderItems (PO Types condition inclusion) - RWPS-5507
*************************************************************/
public without sharing  class ECOM_OrderRepo {

    //Create OrderDeliveryMethods
    public static List<OrderDeliveryMethod> insertOrderDeliveryMethods(List<OrderDeliveryMethod> orderDeliveryMethodsToInsert){
        insert orderDeliveryMethodsToInsert;
        return orderDeliveryMethodsToInsert;
    }

    //Update Order Delivery Methods
    public static List<OrderDeliveryMethod> updateOrderDeliveryMethods(List<OrderDeliveryMethod> orderDeliveryMethodsToUpdate){
        insert orderDeliveryMethodsToUpdate;
        return orderDeliveryMethodsToUpdate;
    }

    //Fetch Order Delivery Methods
    public static List<OrderDeliveryMethod> getOrderDeliveryMethods(String methodName){
        List<OrderDeliveryMethod> orderDeliveryMethods = [SELECT Id, ProductId FROM OrderDeliveryMethod WHERE Name = :methodName LIMIT 1];
        return orderDeliveryMethods;
    }
    //Fetch Order Delivery Method by id
    public static List<OrderDeliveryMethod> getOrderDeliveryMethodsById(String methodId){
        List<OrderDeliveryMethod> orderDeliveryMethods = [SELECT Id, ProductId FROM OrderDeliveryMethod WHERE Id = :methodId LIMIT 1];
        return orderDeliveryMethods;
    }

    //Fetch Order Delivery Group
    public static List<OrderDeliveryGroup> getOrderDeliveryGroups(Set<String> orderIds){
        List<OrderDeliveryGroup> orderDeliveryGroups = [SELECT Id, OrderId, DeliveryInstructions, DeliverToName, Description,
                                                           DesiredDeliveryDate, OrderDeliveryMethod.name, OrderDeliveryMethod.Id
                                                           FROM OrderDeliveryGroup WHERE OrderId IN :orderIds LIMIT 1000];
        return orderDeliveryGroups;
    }

    //Fetch Order and Order products by id
    public static List<Order> getOrdersById(Set<String> Ids){
        List<Order> orders = [SELECT Id,Type, OwnerId, ContractId, AccountId, Pricebook2Id, OriginalOrderId, EffectiveDate, EndDate, Status, Description,
                              PoNumber, ActivatedDate, ActivatedById, StatusCode, CurrencyIsoCode, RelatedOrderId, SalesStoreId, OrderNumber, TotalAmount,
                              CreatedDate, CreatedById,  ECOM_SAP_Order_Number__c, ECOM_Promo_Code__c, ECOM_Total_Savings__c, ECOM_Quote_Number__c,
                              ECOM_Order_On_Hold__c, ECOM_Order_Create_Retry__c, TotalAdjustedProductAmount, TotalAdjDeliveryAmtWithTax, Default_Bill_to_ERP_Address__r.fxAddress_City__c,
                              TotalTaxAmount, GrandTotalAmount, ECOM_Cart_Id__c, Default_Bill_to_ERP_Address__r.Target_Address__c,Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c, Default_Ship_to_ERP_Address__r.Target_Address__c, Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c,
                              ECOM_BillToAccount__r.SAP_Customer_Number_Formatted__c, ECOM_ShipToAccount__r.SAP_Customer_Number_Formatted__c,ShippingCountry,ECOM_isTaxExempt__c,SAP_Contact_ID__c,fxContactEmail__c,
                              Owner.FirstName, Owner.LastName, Owner.Email, Default_Bill_to_ERP_Address__r.fxAddress_CountryName__c, Default_Bill_to_ERP_Address__r.apiCountry__c, Default_Bill_to_ERP_Address__r.Address_Country__c,
                              ECOM_Designated_Approver__c, ECOM_E_Invoice_Code1__c, ECOM_E_Invoice_Code2__c, ECOM_E_Invoice_Code3__c, ECOM_E_Invoice_Code4__c, ECOM_E_Invoice_Cost_Center__c, ECOM_E_Invoice_Tax_Exempt__c, // ECOM-1947 - added invoice fields by sathiya on 2024/05/13
                              Default_Bill_to_ERP_Address__r.ECOM_VAT_Number__c, Default_Bill_to_ERP_Address__r.ECOM_E_Invoice_Cust_Id__c, Default_Bill_to_ERP_Address__r.ECOM_EAN_Do_Not_Use__c, Default_Bill_to_ERP_Address__r.ECOM_Email_To_Invoice__c,
                              Default_Bill_to_ERP_Address__r.Target_Address__r.ECOM_VAT_Number__c, Default_Bill_to_ERP_Address__r.Target_Address__r.ECOM_E_Invoice_Cust_Id__c, Default_Bill_to_ERP_Address__r.Target_Address__r.ECOM_EAN_Do_Not_Use__c, Default_Bill_to_ERP_Address__r.Target_Address__r.ECOM_Email_To_Invoice__c,
                              Default_Invoice_ERP_Address__r.Target_Address__c, Default_Invoice_ERP_Address__r.Target_Address__r.External_Id__c, // Fields added by sathiya for ECOM-3257,
                              ECOM_Accepted_Date__c,ECOM_End_User_For_Trade__c,ECOM_End_User_Address__c,// field added by Gaurav RWPS-1285
                              Total_Tariff_Surcharge__c, // RWPS-3026
                              Invoice_Email__c, //RWPS-1882
                              (SELECT Id, Product2Id, Product2.Name,Product2.Business_Unit__c,Product2.Product_Line__c,Product2.Item_Class__c, Product2.Part_Number__c, Product2.DisplayUrl, OrderId, PricebookEntryId, OriginalOrderItemId, AvailableQuantity, Quantity,
                               CurrencyIsoCode, UnitPrice, ListPrice, TotalPrice, ServiceDate, EndDate, Description, TotalLineAmount, RelatedOrderItemId, Type, TypeCode, LineNumber, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, OrderItemNumber, Tariff_Surcharge__c, ecom_parent_item__c,ECOM_SAP_Line_Number__c, //RWPS-3026 RWPS-3811
                               ECOM_Earliest_Shipping_Date__c, ECOM_Selected_Shipping_Date__c, Product2.Product_Display_Name__c FROM OrderItems WHERE Type = 'Order Product' ORDER BY ECOM_SAP_Line_Number__c ASC), // RWPS-2270 RWPS-3818
                              (SELECT Id, OrderId, DeliveryInstructions, DeliverToName, Description,ECOM_Special_Instructions__c, DesiredDeliveryDate, OrderDeliveryMethod.name, OrderDeliveryMethod.Id FROM OrderDeliveryGroups)
                              FROM Order WHERE ID IN :Ids LIMIT 1000];

        return orders;
    }

     //Fetch Order and Order products by id
     public static List<Order> getOrderById(String orderId){
        List<Order> orders = [SELECT Id,Type, OwnerId, ContractId, AccountId, Pricebook2Id, OriginalOrderId, EffectiveDate, EndDate, Status, Description,
                              PoNumber, ActivatedDate, ActivatedById, StatusCode, CurrencyIsoCode, RelatedOrderId, SalesStoreId, OrderNumber, TotalAmount,
                              CreatedDate, CreatedById,  ECOM_SAP_Order_Number__c, ECOM_Promo_Code__c, ECOM_Total_Savings__c, ECOM_Quote_Number__c,
                              ECOM_Order_On_Hold__c, ECOM_Order_Create_Retry__c, TotalAdjustedProductAmount, TotalAdjDeliveryAmtWithTax,
                              TotalTaxAmount, GrandTotalAmount, ECOM_Cart_Id__c, Default_Bill_to_ERP_Address__r.Target_Address__c,Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c, Default_Ship_to_ERP_Address__r.Target_Address__c, Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c,
                              ECOM_BillToAccount__r.SAP_Customer_Number_Formatted__c, ECOM_ShipToAccount__r.SAP_Customer_Number_Formatted__c,ShippingCountry,ECOM_isTaxExempt__c,SAP_Contact_ID__c,
                              ECOM_E_Invoice_Code1__c, ECOM_E_Invoice_Code2__c, ECOM_E_Invoice_Code3__c, ECOM_E_Invoice_Code4__c, ECOM_E_Invoice_Cost_Center__c, ECOM_E_Invoice_Tax_Exempt__c,
                              (SELECT Id, Product2Id, Product2.Name, Product2.Part_Number__c,Product2.Product_Type__c,Product2.Item_Class__c,Product2.Business_Unit__c,Product2.Discount_Type__c,Product2.Product_Line__c,Product2.Part_Type__c,Product2.IGOR_PAC__c, Product2.DisplayUrl ,OrderId, PricebookEntryId, OriginalOrderItemId, AvailableQuantity, Quantity, CurrencyIsoCode, UnitPrice, ListPrice, TotalPrice, ServiceDate, EndDate, Description, TotalLineAmount, RelatedOrderItemId, Type, TypeCode, LineNumber, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, OrderItemNumber, ECOM_Earliest_Shipping_Date__c, ECOM_Selected_Shipping_Date__c, Product2.IGOR_Item_Class_Desc__c,Product2.Product_Line_Name__c,Product2.IGOR_Description__c,Product2.Sub_Business_Unit__c,Product2.Super_Business_Unit__c,ECOM_OS_Expected_Ship_date__c,ECOM_Parent_Item__c FROM OrderItems WHERE Type = 'Order Product'), //RWPS-3811
                              (SELECT Id, OrderId, DeliveryInstructions, DeliverToName, Description,ECOM_Special_Instructions__c, DesiredDeliveryDate, OrderDeliveryMethod.name, OrderDeliveryMethod.Id FROM OrderDeliveryGroups)
                              FROM Order WHERE ID =:orderId LIMIT 1];
        return orders;
    }

    //update orders
    public static void updateOrders(List<Order> orders){
        update orders;
    }

    //update order Items
    public static void updateOrderItems(List<OrderItem> orderItems){
        update orderItems;
    }

    //Query to fetch all orders to be synced to SAP
    public Static String getQueryStringForBatch(String orderId){
        String query = 'SELECT Id,Type, OwnerId, ContractId, AccountId, Pricebook2Id, OriginalOrderId, EffectiveDate, EndDate, Status, Description , '+
            'PoNumber, ActivatedDate, ActivatedById, StatusCode, CurrencyIsoCode, RelatedOrderId, SalesStoreId, OrderNumber, TotalAmount, '+
            'CreatedDate, CreatedById,  ECOM_SAP_Order_Number__c, ECOM_Promo_Code__c, ECOM_Total_Savings__c, ECOM_Quote_Number__c,'+
            'ECOM_Order_On_Hold__c, ECOM_Order_Create_Retry__c, TotalAdjustedProductAmount, TotalAdjDeliveryAmtWithTax, '+
            'TotalTaxAmount, GrandTotalAmount, ECOM_Cart_Id__c, Default_Bill_to_ERP_Address__r.apiCountry__c , Default_Bill_to_ERP_Address__r.Target_Address__c,Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c, Default_Ship_to_ERP_Address__r.Target_Address__c, Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c,'+
            'Default_Invoice_ERP_Address__r.Target_Address__c, Default_Invoice_ERP_Address__r.Target_Address__r.External_Id__c, Default_Bill_to_ERP_Address__r.ECOM_VAT_Number__c, Default_Bill_to_ERP_Address__r.ECOM_E_Invoice_Cust_Id__c, Default_Bill_to_ERP_Address__r.ECOM_EAN_Do_Not_Use__c, Default_Bill_to_ERP_Address__r.ECOM_Email_To_Invoice__c, ' +
            'Default_Bill_to_ERP_Address__r.Target_Address__r.ECOM_VAT_Number__c, Default_Bill_to_ERP_Address__r.Target_Address__r.ECOM_E_Invoice_Cust_Id__c, Default_Bill_to_ERP_Address__r.Target_Address__r.ECOM_EAN_Do_Not_Use__c, Default_Bill_to_ERP_Address__r.Target_Address__r.ECOM_Email_To_Invoice__c, ' +
            'ECOM_E_Invoice_Code1__c, ECOM_E_Invoice_Code2__c, ECOM_E_Invoice_Code3__c, ECOM_E_Invoice_Code4__c, ECOM_E_Invoice_Cost_Center__c, ECOM_E_Invoice_Tax_Exempt__c, '+
            'ECOM_BillToAccount__r.SAP_Customer_Number_Formatted__c, ECOM_ShipToAccount__r.SAP_Customer_Number_Formatted__c,ShippingCountry,ECOM_isTaxExempt__c, '+
            '(SELECT Id, Product2Id, Product2.Name, Product2.Part_Number__c, OrderId, PricebookEntryId, OriginalOrderItemId, AvailableQuantity, Quantity, CurrencyIsoCode, UnitPrice, ListPrice, TotalPrice, ServiceDate, EndDate, Description, TotalLineAmount, RelatedOrderItemId, Type, TypeCode, LineNumber, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, OrderItemNumber, ECOM_Earliest_Shipping_Date__c, ECOM_Selected_Shipping_Date__c,ECOM_OS_Expected_Ship_date__c, Product2.Item_Class__c FROM OrderItems WHERE Type = \'Order Product\'), '+
            '(SELECT Id, OrderId, DeliveryInstructions, DeliverToName, Description,ECOM_Special_Instructions__c, DesiredDeliveryDate, OrderDeliveryMethod.name, OrderDeliveryMethod.Id FROM OrderDeliveryGroups)'+
            ' FROM Order WHERE ECOM_SAP_Order_Number__c = null AND Status = \'Draft\' AND ECOM_Order_On_Hold__c = false AND '+
            '(ECOM_Order_Create_Retry__c = null OR ECOM_Order_Create_Retry__c < 5) ';
        if(String.isNotBlank(orderId)){
            query += 'AND Id = \''+orderId+ '\' ';
        }
        System.debug('Query == '+query);
        return query;
    }

    /**
    * @description  Method to check if current PO by user is already used for .
    * @author Manish 2023.08.24
    * @param effectiveAccountId
    * @param poNumber
    * @return List<Order>
    **/
    public static List<Order> checkIfPoUsed(String effectiveAccountId, String poNumber){
        return [SELECT Id, PoNumber, ContractId, AccountId, Status, EffectiveDate, Type, ActivatedDate, ActivatedById, OrderNumber FROM Order WHERE AccountId =: effectiveAccountId AND PoNumber =: poNumber];
    }

    // Fetch Oder Summary by Owner Id
    public static List<Order> getMyOrders() {

        List<Order> orderList = [SELECT Id, OwnerId, OrderNumber, CreatedDate, CreatedById, OriginalOrderId, AccountId, ECOM_SAP_Order_Number__c,
                                            EffectiveDate, TotalAmount, GrandTotalAmount, OrderedDate, Status, ECOM_Order_Summary_Status__c, Description, SalesStoreId, PoNumber,
                                            BillToContactId, Pricebook2Id, CurrencyIsoCode,
                                            ECOM_Total_Items__c, ECOM_Cart_Id__c, //RWPS-2786 //ECOM-3150 - garora@rafter.one - new rollup field for getting sum of quantities - 2 May 2024
                                            ECOM_E_Invoice_Code1__c, ECOM_E_Invoice_Code2__c, ECOM_E_Invoice_Code3__c, ECOM_E_Invoice_Code4__c, ECOM_E_Invoice_Cost_Center__c, ECOM_E_Invoice_Tax_Exempt__c, // ECOM-1947 - added invoice fields by sathiya on 2024/05/13
                                            Default_Bill_to_ERP_Address__c,Default_Invoice_ERP_Address__c,Default_Ship_to_ERP_Address__c,Default_Ship_to_ERP_Address__r.Target_Address__c,Default_Ship_to_ERP_Address__r.Master_Address__c,//RWPS-3657
                                            (SELECT Id, OrderId, Product2Id, Quantity,Product2.Part_Number__c,ECOM_Parent_Item__c FROM OrderItems WHERE Type = 'Order Product'),// RWPS-3811
                                            (SELECT Id,Name,CurrencyIsoCode,ECOM_Invoice_Date__c,ECOM_Total__c,ECOM_Total_Items__c,ERP_Invoice_Number__c //ECOM-3304 - garora@rafter.one - new field populated by Boomi - 24 June 2024
                                            FROM Invoices__r ORDER BY Name ASC) FROM Order
                                            WHERE OwnerId =: UserInfo.getUserId() ORDER BY CreatedDate DESC];
        return orderList;
    }

    /**
    * RWPS-4881
    * @description  Method to fetch Salesforce/Online Orders belongs to logged-in user
    * @author Sachin Vispute | 2025.10.28
    * @param searchString
    * @return List<Order>
    **/
    public static List<Order> getOnlineOrders(String searchString, User user, Boolean isPunchoutUser, List<String> orderTypesList, List<String> poTypesList) { //RWPS-5094
        String type = ECOM_Constant.ORDER_PRODUCT_TYPE;
        Id userId = user.Id;
        String query = 'SELECT Id, OwnerId, OrderNumber, CreatedDate, CreatedById, OriginalOrderId, AccountId, ECOM_SAP_Order_Number__c,';
        query += ' EffectiveDate, TotalAmount, GrandTotalAmount, OrderedDate, Status, ECOM_Order_Summary_Status__c, Description, SalesStoreId, PoNumber,';
        query += ' BillToContactId, Pricebook2Id, CurrencyIsoCode, ECOM_Total_Items__c, ECOM_Cart_Id__c,'; //RWPS-2786 //ECOM-3150 - garora@rafter.one - new rollup field for getting sum of quantities - 2 May 2024
        query += ' ECOM_E_Invoice_Code1__c, ECOM_E_Invoice_Code2__c, ECOM_E_Invoice_Code3__c, ECOM_E_Invoice_Code4__c, ECOM_E_Invoice_Cost_Center__c, ECOM_E_Invoice_Tax_Exempt__c,'; // ECOM-1947 - added invoice fields by sathiya on 2024/05/13
        query += ' Default_Bill_to_ERP_Address__c,Default_Invoice_ERP_Address__c,Default_Ship_to_ERP_Address__c,Default_Ship_to_ERP_Address__r.Target_Address__c,Default_Ship_to_ERP_Address__r.Master_Address__c,'; //RWPS-3657
        query += ' (SELECT Id, OrderId, Product2Id, Quantity,Product2.Part_Number__c,ECOM_Parent_Item__c FROM OrderItems WHERE Type =:type),';// RWPS-3811
        query += ' (SELECT Id,Name,CurrencyIsoCode,ECOM_Invoice_Date__c,ECOM_Total__c,ECOM_Total_Items__c,ERP_Invoice_Number__c FROM Invoices__r ORDER BY Name ASC)'; //ECOM-3304 - garora@rafter.one - new field populated by Boomi - 24 June 2024';
        query += ' FROM Order WHERE';

        //RWPS-4881
        if (isPunchoutUser == true && user != null && user.Email != null) {
            String userEmail = (String)user.Email;
            query += ' CustomerAuthorizedBy.Email =:userEmail';
            query += ' AND Type IN :orderTypesList'; //RWPS-5094
            query += ' AND ECOM_SAP_Order_Summary__r.PO_Type__c IN :poTypesList'; //RWPS-5094
        } else {
            query += ' OwnerId =:userId';
            query += ' AND (ECOM_SAP_Order_Summary__c = null OR (ECOM_SAP_Order_Summary__c != null AND ECOM_SAP_Order_Summary__r.PO_Type__c IN :poTypesList))'; //RWPS-5094
        }

        if (String.isNotBlank(searchString)) {
            searchString = '%' + searchString + '%';
            query += ' AND Id IN (SELECT OrderId FROM OrderItem WHERE Order.PoNumber LIKE :searchString OR Order.ECOM_SAP_Order_Number__c LIKE :searchString OR Order.OrderNumber LIKE :searchString OR Product2.Part_Number__c LIKE :searchString)';
        }
        //RWPS-4881
        query += ' ORDER BY CreatedDate DESC LIMIT 49999';
        return Database.query(String.escapeSingleQuotes(query));
    }

    // Fetch Order Items, Order by Order Id
    public static List<Order> getOrderDetails(Id orderId) {

        List<Order> orderList = [SELECT Id, OwnerId, OrderNumber, CreatedDate, CreatedById, AccountId, TotalAmount, TotalAdjustedProductTaxAmount, GrandTotalAmount, OriginalOrderId, Status, Description, Total_Tariff_Surcharge__c,//RWPS-3026
                                SalesStoreId, PoNumber, Pricebook2Id, ECOM_Promo_Code__c, ECOM_Quote_Number__c, ECOM_SAP_Order_Number__c, ECOM_Total_Savings__c, BillingAddress, TotalAdjustedProductAmount,ECOM_ApprovalRejection_Comment__c, //RWPS-1885
                                TotalAdjDeliveryAmtWithTax,ECOM_Order_On_Hold__c,ECOM_Order_Create_Retry__c,ECOM_Error_Message__c,CurrencyIsoCode,Default_Bill_to_ERP_Address__c,Default_Ship_to_ERP_Address__c,
                                Default_Ship_to_ERP_Address__r.Address_Street_Line_1__c,Default_Ship_to_ERP_Address__r.Address_Street_Line_2__c,Default_Ship_to_ERP_Address__r.Address_City__c,Default_Ship_to_ERP_Address__r.Address_Postal_Code__c,
                                Default_Ship_to_ERP_Address__r.Address_State__c,Default_Ship_to_ERP_Address__r.Address_Country__c, Default_Ship_to_ERP_Address__r.ApiCountry__c, //ECOM-3322 - Gaurang - added a method that queries user object, and returns list of emails matching criteria - 7 July 2024
                                Default_Bill_to_ERP_Address__r.Address_Street_Line_1__c,Default_Bill_to_ERP_Address__r.Address_Street_Line_2__c,Default_Bill_to_ERP_Address__r.Address_City__c,Default_Bill_to_ERP_Address__r.Address_Postal_Code__c,
                                Default_Bill_to_ERP_Address__r.Address_State__c,Default_Bill_to_ERP_Address__r.Address_Country__c,ECOM_Order_Summary_Status__c,
                                 Default_Bill_to_ERP_Address__r.fxAddress_City__c, Default_Bill_to_ERP_Address__r.Master_Address__c, Default_Bill_to_ERP_Address__r.Target_Address__c,
                                Default_Bill_to_ERP_Address__r.fxAddress_CountryName__c,
                                Default_Bill_to_ERP_Address__r.fxAddress_Postal__c,
                                Default_Bill_to_ERP_Address__r.fxAddress_StateName__c,
                                Default_Bill_to_ERP_Address__r.fxAddress_Street__c,
                                Default_Bill_to_ERP_Address__r.fxCustomerName_Target__c, //RWPS-3868
                                Default_Bill_to_ERP_Address__r.fxAccountName__c,//ECOM-112 - garora@rafter.one - field added for getting company name - 12 May 2024
                                Default_Ship_to_ERP_Address__r.fxAddress_City__c,
                                Default_Ship_to_ERP_Address__r.fxAddress_CountryName__c,
                                Default_Ship_to_ERP_Address__r.fxAddress_Postal__c,
                                Default_Ship_to_ERP_Address__r.fxAddress_StateName__c,
                                Default_Ship_to_ERP_Address__r.fxAddress_Street__c, Default_Ship_to_ERP_Address__r.Master_Address__c, Default_Ship_to_ERP_Address__r.Target_Address__c,
                                Default_Ship_to_ERP_Address__r.fxAccountName__c,//ECOM-211 - garora@rafter.one - field added for getting company name - 12 May 2024
                                Default_Ship_to_ERP_Address__r.ERP_Sales_Org__c,//ECOM-1931 - garora@rafter.one - As boomi is populating sales org, we are going to refer sales org from ship to in order - 4 June 2024
                                Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c,
                                Default_Bill_to_ERP_Address__r.ECOM_Review_Status__c,
                                Default_Ship_to_ERP_Address__r.fxCustomerName_Master__c, //RWPS-1306
                                //ECOM-112 - garora@rafter.one - new invoice mailing address field - 12 May 2024 - starts
                                Default_Invoice_ERP_Address__r.ECOM_Review_Status__c, Default_Invoice_ERP_Address__r.Address_City__c, Default_Invoice_ERP_Address__r.apiCountry__c,
                                Default_Invoice_ERP_Address__r.Address_Postal_Code__c, Default_Invoice_ERP_Address__r.apiState__c, Default_Invoice_ERP_Address__r.Address_Street_Line_1__c,
                                Default_Invoice_ERP_Address__c, Default_Invoice_ERP_Address__r.fxAddress_City__c,
                                Default_Invoice_ERP_Address__r.fxAddress_CountryName__c, Default_Invoice_ERP_Address__r.fxAddress_Postal__c,
                                Default_Invoice_ERP_Address__r.fxAddress_StateName__c, Default_Invoice_ERP_Address__r.fxAddress_Street__c,
                                 Default_Invoice_ERP_Address__r.Master_Address__c, Default_Invoice_ERP_Address__r.Target_Address__c, Default_Invoice_ERP_Address__r.Target_Address__r.External_Id__c,
                                //ECOM-112 - garora@rafter.one - new invoice mailing address field - 12 May 2024 - ends
                                Default_Invoice_ERP_Address__r.fxAccountName__c,//ECOM-211 - garora@rafter.one - field added for getting company name
                                 Account.Name,ECOM_isTaxExempt__c, Default_Bill_to_ERP_Address__r.apiCountry__c, Default_Bill_to_ERP_Address__r.apiState__c,
                                 Default_Bill_to_ERP_Address__r.ECOM_VAT_Number__c, Default_Bill_to_ERP_Address__r.ECOM_E_Invoice_Cust_Id__c,
                                 Default_Bill_to_ERP_Address__r.ECOM_EAN_Do_Not_Use__c, // Fields added by sathiya for ECOM-1933 and ECOM-1942,
                                 Default_Bill_to_ERP_Address__r.ECOM_Email_To_Invoice__c, // Fiekds added by sathiya for ECOM-3389
                                 Default_Bill_to_ERP_Address__r.Target_Address__r.ECOM_VAT_Number__c,
                                 Default_Bill_to_ERP_Address__r.Target_Address__r.ECOM_E_Invoice_Cust_Id__c,
                                 Default_Bill_to_ERP_Address__r.Target_Address__r.ECOM_EAN_Do_Not_Use__c,
                                 Default_Bill_to_ERP_Address__r.Target_Address__r.ECOM_Email_To_Invoice__c,
                                 ECOM_E_Invoice_Code1__c, ECOM_E_Invoice_Code2__c, ECOM_E_Invoice_Code3__c, ECOM_E_Invoice_Code4__c, ECOM_E_Invoice_Cost_Center__c, ECOM_E_Invoice_Tax_Exempt__c, // ECOM-1947 - added invoice fields by sathiya on 2024/05/13
                                 ECOM_Total_Items__c, //ECOM-3150 - garora@rafter.one - new rollup field for getting sum of quantities - 2 May 2024,
                                (SELECT Id, Product2Id, Product2.Name, Product2.Part_Number__c,Product2.Item_Class__c ,LineNumber, OrderId, Quantity, UnitPrice, Tariff_Surcharge__c, ListPrice, TotalPrice, ECOM_Earliest_Shipping_Date__c, ECOM_Selected_Shipping_Date__c, //RWPS-3026
                                ECOM_Order_Item_Status__c, Type, Description, TotalLineAmount, Product2.DisplayUrl,CurrencyIsoCode, ECOM_OS_Expected_Ship_date__c, Product2.ECOM_Product_Media_URI__c,Product2.Product_Display_Name__c,ECOM_Parent_Item__c // RWPS-2270 RWPS-3811
                                FROM OrderItems WHERE Type = 'Order Product'),
                                (SELECT Id, OrderId, DeliveryInstructions, DeliverToName, Description,ECOM_Special_Instructions__c, DesiredDeliveryDate, OrderDeliveryMethod.name, OrderDeliveryMethod.Id
                                 FROM OrderDeliveryGroups)
                                FROM Order
                                WHERE Id =: orderId];
        return orderList;
    }

    // Fetch Order Summary by Owner Id, Order Number, Postal Code
    public static List<Order> findOrderByOrderNumberAndZip(String orderNumber, String zipCode) {

        List<Order> orderSummaryList = [SELECT Id, OwnerId, OrderNumber, CreatedDate, CreatedById, OriginalOrderId, AccountId, ECOM_DefaultShipToCPA__c, ECOM_DefaultShipToCPA__r.PostalCode, ECOM_SAP_Order_Number__c,
                                               EffectiveDate, TotalAmount, GrandTotalAmount, OrderedDate, Status, Description, SalesStoreId, PoNumber, ECOM_ShipToAccount__c, ECOM_ShipToAccount__r.ShippingPostalCode,
                                               ECOM_Order_Summary_Status__c, CurrencyIsoCode, BillToContactId, Pricebook2Id, ECOM_Total_Items__c, //ECOM-3150 - garora@rafter.one - new rollup field for getting sum of quantities - 2 May 2024
                                                ECOM_E_Invoice_Code1__c, ECOM_E_Invoice_Code2__c, ECOM_E_Invoice_Code3__c, ECOM_E_Invoice_Code4__c, ECOM_E_Invoice_Cost_Center__c, ECOM_E_Invoice_Tax_Exempt__c, // ECOM-1947 - added invoice fields by sathiya on 2024/05/13
                                               (SELECT Id, OrderId, Product2Id, Quantity, Product2.Part_Number__c,Product2.Item_Class__c,ECOM_OS_Expected_Ship_date__c FROM OrderItems WHERE Type = 'Order Product'),
                                               (SELECT Id,Name,CurrencyIsoCode,ECOM_Invoice_Date__c,ECOM_Total__c,ECOM_Total_Items__c,ERP_Invoice_Number__c //ECOM-3304 - garora@rafter.one - new field populated by Boomi - 24 June 2024
                                                FROM Invoices__r ORDER BY Name ASC) //RWPS-95 - garora@rafter.one - invoices fields added to query - 2 May 2024
                                                FROM Order
                                               WHERE OwnerId =: UserInfo.getUserId()
                                               AND (OrderNumber =: orderNumber OR PoNumber =: orderNumber OR ECOM_SAP_Order_Number__c =:orderNumber)
                                               AND (ECOM_ShipToAccount__r.ShippingPostalCode =: zipCode OR ECOM_DefaultShipToCPA__r.PostalCode =: zipCode OR ShippingPostalCode =: zipCode)
                                               ];//AND createdById =: UserInfo.getUserId()];
        return orderSummaryList;
    }
    //Fetch orders and order by SAP order id
    public static List<Order> fetchOrdersBySAPOrderId(Set<String> sapOrderIds){
        List<Order> orderList = [SELECT Id, OwnerId, OrderNumber, CreatedDate, CreatedById, AccountId, TotalAmount, TotalTaxAmount, GrandTotalAmount, OriginalOrderId, Status, Description,
                                SalesStoreId, PoNumber, Pricebook2Id, ECOM_Promo_Code__c, ECOM_Quote_Number__c, ECOM_SAP_Order_Number__c, ECOM_Total_Savings__c, BillingAddress,
                                (SELECT Id, Product2Id, Product2.Name, Product2.Part_Number__c,Product2.Item_Class__c, OrderId, Quantity, UnitPrice, ListPrice, TotalPrice, ECOM_Earliest_Shipping_Date__c, ECOM_Selected_Shipping_Date__c,
                                Type, Description, TotalLineAmount, LineNumber,ECOM_OS_Expected_Ship_date__c
                                FROM OrderItems)
                                FROM Order
                                WHERE ECOM_SAP_Order_Number__c IN :sapOrderIds];
        return orderList;
    }
    //Fetch order items by SAP order number
    public static SAP_Order_Summary__c fetchOrdersBySAPOrderNumber(String sapOrderNumber){
        Decimal sapNumber = Decimal.valueOf(sapOrderNumber);
        List<SAP_Order_Summary__c> sapOrder = [SELECT Id, Name, Order_Number__c,
                                        (SELECT Id, Name FROM SAP_Order_Items__r)
                                        FROM SAP_Order_Summary__c
                                        WHERE Order_Number__c =: sapNumber];

        return sapOrder.size()>0 ?sapOrder[0] :null;
    }
    //Fetch order Items based on Order Item Id
    public static OrderItem getOrderItemBasedOnId(String orderItemId)
    {
        return [
                 Select Id,OrderID,Order.AccountId,Order.Account.Name,Order.OrderedDate,
                 Order.ShippingStreet, Order.ShippingCity,Order.Status,
                 Order.ShippingState, Order.ShippingPostalCode,Order.ShippingCountry,Order.ECOM_SAP_Order_Number__c,
                 ECOM_Status__c,LineNumber,Quantity,Product2Id,Product2.Part_Number__c,CreatedDate,
                 Order.ECOM_Order_Summary_Status__c,Order.OrderNumber,
                 Order.Default_Bill_to_ERP_Address__c,Order.Default_Bill_to_ERP_Address__r.Target_Address__c,Order.Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c,
                 Order.Default_Ship_to_ERP_Address__c,Order.Default_Ship_to_ERP_Address__r.Target_Address__c,Order.Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c,
                 Order.Default_Ship_to_ERP_Address__r.Account__c, Order.Default_Ship_to_ERP_Address__r.Account__r.Name,
                 ECOM_Order_Item_Status__c,ECOM_SAP_Order_Items__c,ECOM_SAP_Order_Items__r.Line_Item_Number_SAP__c
                 from OrderItem where Id= :orderItemId
               ];
    }


    /**
    * @description // To get orders based on OwnerId and BillingCPA
    * @author Vipul Goyal | 09-24-2023
    * @param cpaId
    * @return List<Order>
    **/
    public static List<Order> getOrderBasedOnOwnerAndCpa(String cpaId)
    {
        List<Order> orders=[Select id from Order where ECOM_DefaultBillToCPA__c=:cpaId and OwnerID = :UserInfo.getUserId()];
        return orders;
    }

    /**
    * @description This query returns Card Payment Method records related to the Order Id, which was created during checkout.
    * @author Manish Kumar | 10-20-2023
    * @param orderId
    * @return List<CardPaymentMethod>
    **/
    public static List<CardPaymentMethod> getCardPaymentBasedOnOrder(String orderId)
    {
        return [SELECT Id, CardCategory, CardHolderFirstName, CardHolderLastName, CardLastFour, CardType, ECOM_Order__c, Email, ExpiryMonth, ExpiryYear,
                ProcessingMode, Status FROM CardPaymentMethod WHERE ECOM_Order__c =: orderId ORDER BY CreatedDate DESC LIMIT 1];
    }

    /**
    * @description This query returns PaymentAuthorization  records related to the Order Id, which was created during checkout.
    * @author Manish Kumar | 10-20-2023
    * @param orderId
    * @return List<PaymentAuthorization>
    **/
    public static List<PaymentAuthorization> getPaymentAuthorizationBasedOnOrder(String orderId)
    {
        return [SELECT Id, ECOM_Authorization_Number__c, ECOM_Merchant_Id__c, ECOM_Payment_Method_Token__c, ECOM_PG_Return_Description__c, ECOM_PG_Transaction_Id__c,
                CurrencyIsoCode, Status, Amount, Date, ECOM_Authorization_Flag__c, ECOM_Authorization_Type__c
                FROM PaymentAuthorization WHERE Status = 'Processed' AND ECOM_Order__c =: orderId ORDER BY CreatedDate DESC LIMIT 1];
    }

    /**
    * @description This method is used to create Card Payment Method record during checkout.
    * @author Manish Kumar | 10-20-2023
    * @param cpm
    **/
    public static void createCardPaymentForOrder(CardPaymentMethod cpm)
    {
        insert cpm;
    }

    /**
    * @description This method is used to update Card Payment Method record during checkout.
    * @author Manish Kumar | 11-08-2023
    * @param cpm
    **/
    public static void updateCardPaymentForOrder(CardPaymentMethod cpm)
    {
        update cpm;
    }

    /**
    * @description This method is used to create Payment Authorization record during checkout.
    * @author Manish Kumar | 10-20-2023
    * @param pa
    **/
    public static void createPaymentAuthorizationForOrder(PaymentAuthorization pa)
    {
        insert pa;
    }

    /**
    * @description This method is used to update Payment Authorization record during checkout.
    * @author Manish Kumar | 11-08-2023
    * @param pa
    **/
    public static void updatePaymentAuthorizationForOrder(PaymentAuthorization pa)
    {
        update pa;
    }
	
    //RWPS-3657- START
    /*public static List<Order> getOrderBasedOnOwnerShipToAndBillTo(List<String> shipToErpIds,List<String> billToErpIds)
    {
        List<Order> orders=[Select id from Order where (Default_Ship_to_ERP_Address__c in :shipToErpIds or Default_Bill_to_ERP_Address__c in :billToErpIds)  and OwnerID = :UserInfo.getUserId()];
        return orders;
    }

    public static List<Order> getOrderBasedOnOwnerAndShipTo(List<String> shipToErpIds)
    {
        List<Order> orders=[Select id from Order where Default_Ship_to_ERP_Address__c in :shipToErpIds and OwnerID = :UserInfo.getUserId()];
        return orders;
    }

    public static List<Order> getOrderBasedOnOwnerAndBillTo(List<String> billToErpIds)
    {
        List<Order> orders=[Select id from Order where Default_Bill_to_ERP_Address__c in :billToErpIds  and OwnerID = :UserInfo.getUserId()];
        return orders;
    }*/
    //RWPS-3657- END
    
    /**
    * @description Fetch Invoice Mailing Address from order based on owner
    * @author Sathiya | 05-14-2024
    * @param shipToErpIds
    * @param billToErpIds
    * @param invoiceErpIds
    * @param userId
    * @return List<Order>
    **/
    public static List<Order> getOrderBasedOnOwnerByErpAddressTypes(List<String> shipToErpIds,List<String> billToErpIds, List<String> invoiceErpIds, string userId){
        Map<String, Object> bindVars = new Map<String, Object>{'shipToErpIds' => shipToErpIds
            , 'billToErpIds' => billToErpIds, 'invoiceErpIds' => invoiceErpIds, 'userId' => userId};
        String query = 'SELECT id FROM Order WHERE ( ';
        if(!shipToErpIds.isEmpty()){
            query += ' Default_Ship_to_ERP_Address__c IN :shipToErpIds ';
        }
        if(!billToErpIds.isEmpty()){
            query += !shipToErpIds.isEmpty()? ' OR ': '';
            query += ' Default_Bill_to_ERP_Address__c IN :billToErpIds ';
        }
        if(!invoiceErpIds.isEmpty()){
            query += !billToErpIds.isEmpty()? ' OR ': '';
            query += ' Default_Invoice_ERP_Address__c IN :invoiceErpIds ';
        }
        query += ') AND OwnerID = :userId';
        List<Order> orders= Test.isRunningTest()? Database.queryWithBinds(query, bindVars, AccessLevel.SYSTEM_MODE):Database.queryWithBinds(query, bindVars, AccessLevel.USER_MODE); //ECOM-128 - Gaurang - test condition added - 8 July 2024
        return orders;
    }
    /**
    * @description     //Create order summary
    * @author Rani Thumma | 09-11-2023
    * @param webstoreId
    * @return ConnectApi.OrderSummaryOutputRepresentation
    **/
    public static ConnectApi.OrderSummaryOutputRepresentation createOrderSummary(ConnectApi.OrderSummaryInputRepresentation orderSummaryInput){
        return ECOM_SalesforceAPI.createOrderSummary(orderSummaryInput);
    }

    public static String getShippedOrders(){
        String query = 'SELECT Id, Status, ECOM_Order_Summary_Status__c '+
                       'FROM Order WHERE ECOM_SAP_Order_Number__c != null AND Status != \'Shipped\' AND ECOM_Order_Summary_Status__c = \'Shipped\' ';
    return query;
    }


    /**
    * @description Method to query orders that are approved or pending for approval.
    * @author Vipul Goyal | 05-06-2024
    * @param userId
    * @param userEmail
    * @return List<Order>
    **/
    public static List<Order> getOrdersForApproval(String userId,String userEmail)
    {
        String emailAtBeginning = userEmail + ';%';
        String emailInBetween = '%;'+userEmail+';%';
        String emailInTheEnd = '%;'+userEmail;

        List<Order> orders = [SELECT Id,Type, OwnerId, ContractId, AccountId, Pricebook2Id, OriginalOrderId, EffectiveDate, EndDate, Status, Description,
                              PoNumber, ActivatedDate, ActivatedById, StatusCode, CurrencyIsoCode, RelatedOrderId, SalesStoreId, OrderNumber, TotalAmount,
                              CreatedDate, CreatedById,  ECOM_SAP_Order_Number__c, ECOM_Promo_Code__c, ECOM_Total_Savings__c, ECOM_Quote_Number__c,OrderedDate,ECOM_Total_Items__c, Owner.FirstName, Owner.LastName, Owner.Email,
                              ECOM_Order_On_Hold__c, ECOM_Order_Create_Retry__c, TotalAdjustedProductAmount, TotalAdjDeliveryAmtWithTax,ECOM_Designated_Approver__c, ECOM_ApprovalRejection_Comment__c, ECOM_ApprovedRejectedBy__r.Name, ECOM_ApprovedRejectedBy__r.Email, ECOM_ApprovedRejectedBy__c,
                              TotalTaxAmount, GrandTotalAmount, ECOM_Cart_Id__c, Default_Bill_to_ERP_Address__r.Target_Address__c,Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c, Default_Ship_to_ERP_Address__r.Target_Address__c, Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c,
                              ECOM_BillToAccount__r.SAP_Customer_Number_Formatted__c, ECOM_ShipToAccount__r.SAP_Customer_Number_Formatted__c,ShippingCountry,ECOM_isTaxExempt__c,
                              (SELECT Id, Product2Id, Product2.Name, Product2.Part_Number__c,Product2.Product_Type__c,Product2.Item_Class__c,Product2.Business_Unit__c,Product2.Discount_Type__c,Product2.Product_Line__c,Product2.Part_Type__c,Product2.IGOR_PAC__c, Product2.DisplayUrl ,OrderId, PricebookEntryId, OriginalOrderItemId, AvailableQuantity, Quantity, CurrencyIsoCode, UnitPrice, ListPrice, TotalPrice, ServiceDate, EndDate, Description, TotalLineAmount, RelatedOrderItemId, Type, TypeCode, LineNumber, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, OrderItemNumber, ECOM_Earliest_Shipping_Date__c, ECOM_Selected_Shipping_Date__c, Product2.IGOR_Item_Class_Desc__c,Product2.Product_Line_Name__c,Product2.IGOR_Description__c,Product2.Sub_Business_Unit__c,Product2.Super_Business_Unit__c,ECOM_OS_Expected_Ship_date__c FROM OrderItems WHERE Type = 'Order Product'),
                              (SELECT Id, OrderId, DeliveryInstructions, DeliverToName, Description,ECOM_Special_Instructions__c, DesiredDeliveryDate, OrderDeliveryMethod.name, OrderDeliveryMethod.Id FROM OrderDeliveryGroups)
                              FROM Order
                               WHERE Status != 'Draft' AND ((ECOM_Designated_Approver__c = :userEmail or ECOM_Designated_Approver__c like :emailAtBeginning or ECOM_Designated_Approver__c like :emailInBetween or ECOM_Designated_Approver__c like :emailInTheEnd)
                               OR
                               (OwnerId = :userId AND ECOM_Designated_Approver__c!=''))
                               ORDER BY
                               CreatedDate Desc
                               ];

        return orders;

    }


    /**
    * @description Method to query order count that are approved or pending for approval.
    * @author Vipul Goyal | 05-06-2024
    * @param userId
    * @param userEmail
    * @return Integer
    **/
    public static Integer getOrdersForApprovalCount(String userId,String userEmail)
    {
        String emailAtBeginning = userEmail + ';%';
        String emailInBetween = '%;'+userEmail+';%';
        String emailInTheEnd = '%;'+userEmail;

        Integer orderCount = [SELECT count()
                              FROM Order
                               WHERE Status != 'Draft' AND ((ECOM_Designated_Approver__c = :userEmail or ECOM_Designated_Approver__c like :emailAtBeginning or ECOM_Designated_Approver__c like :emailInBetween or ECOM_Designated_Approver__c like :emailInTheEnd)
                               OR
                               (OwnerId = :userId and ECOM_Designated_Approver__c!=''))
                               ];

        return orderCount;

    }

   /**
     * @description This method returns count of the Coupon from Order
     * @author gaurav.bhansali@revvity.com | 31 Dec 2024 RWPS-2052
     * @param couponId | String
     * @returns Integer
    **/
    public static Integer checkIfCouponUsed(String couponId){
        return [SELECT count() FROM order where ECOM_Promo_Code__c=: couponId AND OwnerId =: UserInfo.getUserId() and status!='Cancelled'];
    }

    /**
     * @description This method returns order count for user
     * @author gaurav.bhansali@revvity.com | 14 Jan 2025 RWPS-2307
     * @returns Integer
    **/
    public static Integer getUserOrderCount(Id userId){
        return [SELECT count() FROM order where OwnerId =: userId AND status!='Cancelled'];
    }
    /**
     * @description This method returns order Product
     * @author prabhat.kumar4@revvity.com | 28 Mar 2025
     * @returns List<OrderItem>
    **/
    public static List<OrderItem> getOrderItems(String contactId, List<String> poTypesList) { //RWPS-5507 : Added poTypesList parameter
        // First get the last 10 orders for this contact
        List<Order> recentOrders = [SELECT Id FROM Order WHERE CustomerAuthorizedById = :contactId AND (ECOM_SAP_Order_Summary__c = null OR (ECOM_SAP_Order_Summary__c != null AND ECOM_SAP_Order_Summary__r.PO_Type__c IN :poTypesList)) ORDER BY CreatedDate DESC LIMIT 10];
        // Extract the order IDs
        Set<Id> orderIds = new Set<Id>();
        for(Order ord : recentOrders){
            orderIds.add(ord.Id);
        }

        // Return order items for these orders
        return [SELECT Id, Product2Id, OrderItem.CreatedDate, Order.CompanyAuthorizedById FROM OrderItem WHERE OrderId IN :orderIds AND Type = 'Order Product' ORDER BY CreatedDate DESC];
     }
}