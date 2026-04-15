/**************************************************************

* 1. Jira Ticket(s) that relates to this class
*  
* 2. Description - This class is a test class for ECOM_OrderUtil.
					- Call the ECOM_TestUtil Class to create test data and test each methods.
					- Used System Assertion to Confirm the functionalities.
* 3. Objects referenced
*    - Account
*    - Contact
*    - User
*    - Order
* 
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_TestUtil
*
* 6. Test Class Name:
*    -None
*
* 7. Is @Invocable : No
*
* 8. Author Name(s):
*    - Manoj 2023.09.19
*    - Gaurang 2024.05.12
*    - Manish Joshi 2024.04.28 Updated method testGetOrderModelList for code coverage - RWPS-3026
*    - Poonam 2025.07.2 Added method testupdateOrders and updated testGetOrderModelList -  RWPS-2786                                                                                                                                                                                                                                       for code coverage - RWPS-2786
*    - Gaurav 2025.08.06 Updated method testGetOrderModelList to add fxCustomerName_Target__c property - RWPS-3868
*    - Gaurav 2025.08.22 Updated method testGetOrderModelList to add ecom_parent_item__c property - RWPS-3811
*    - Poonam 2025.1.10 Updated method testGetContactNumber1, testGetContactNumber2 to increase coverage
*************************************************************/
@isTest
public with sharing class ECOM_OrderUtil_Test {
    
    @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
    }
    
    // Create a test method to test the getContactNumber method
    @isTest
    static  void testGetContactNumber() {
        Contact testContact = [Select Id,LastName From Contact ORDER BY CREATEDDATE DESC LIMIT 1];
        Account testAccount  = [Select Id From Account ORDER BY CREATEDDATE DESC LIMIT 1];
        User testUser = [Select Id,LastName,ContactId From User Where ContactId =:testContact.Id ORDER BY CREATEDDATE DESC LIMIT 1];
        
        ERP_Relationship__c erpRelation = new 	ERP_Relationship__c();
        erpRelation.Contact__c = testContact.Id;
        erpRelation.Name ='testerp';
        //erpRelation.ERP_Address__c = erpAddress.Id;
        insert erpRelation;
        
        List<ERP_RelationShip__c> erpRelationlist = new List<ERP_RelationShip__c>();
        erpRelationlist.add(erpRelation);
        
        ERP_Address__c testAdd = new ERP_Address__c();
        insert testAdd;

        System.runAs(testUser){
            Test.startTest();
            String shipToId = testAdd.Id; 
            String result = ECOM_OrderUtil.getContactNumber(shipToId); 
            Test.stopTest();
            
            // Assert the expected result
            System.assertNotEquals('Null', result);
        }
        
    }
    @isTest
    static  void testGetContactNumberexemption() {
        Contact testContact = [Select Id,LastName From Contact ORDER BY CREATEDDATE DESC LIMIT 1];
        Account testAccount  = [Select Id From Account ORDER BY CREATEDDATE DESC LIMIT 1];
        User testUser = [Select Id,LastName,ContactId From User Where ContactId =:testContact.Id ORDER BY CREATEDDATE DESC LIMIT 1];
        
        ERP_Relationship__c erpRelation = new 	ERP_Relationship__c();
        erpRelation.Contact__c = testContact.Id;
        erpRelation.Name ='testerp';
        //erpRelation.ERP_Address__c = erpAddress.Id;
        insert erpRelation;
        
        List<ERP_RelationShip__c> erpRelationlist = new List<ERP_RelationShip__c>();
        erpRelationlist.add(erpRelation);
        
        
        Test.startTest();
        String shipToId = 'ShipToId1'; 
        String result = ECOM_OrderUtil.getContactNumber(shipToId); 
        Test.stopTest();
        
        // Assert the expected result
        System.assertNotEquals('Null', result,'ExpectedResult');
        
        
    }
    
    
    
    @isTest
    static void testGetOrderModelList() {
        Order order = [SELECT Id,Type, OwnerId, ContractId, AccountId, Pricebook2Id, OriginalOrderId, EffectiveDate, EndDate, Status, Description, 
                              PoNumber, ActivatedDate, ActivatedById, StatusCode, CurrencyIsoCode, RelatedOrderId, SalesStoreId, OrderNumber, TotalAmount, 
                              CreatedDate, CreatedById,  ECOM_SAP_Order_Number__c, ECOM_Promo_Code__c, ECOM_Total_Savings__c, ECOM_Quote_Number__c,
                              ECOM_Order_On_Hold__c, ECOM_Order_Create_Retry__c, TotalAdjustedProductAmount, TotalAdjDeliveryAmtWithTax, 
                              TotalTaxAmount, GrandTotalAmount, ECOM_Cart_Id__c, Default_Bill_to_ERP_Address__r.Target_Address__c,Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c, Default_Ship_to_ERP_Address__r.Target_Address__c, Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c,
                              ECOM_BillToAccount__r.SAP_Customer_Number_Formatted__c, ECOM_ShipToAccount__r.SAP_Customer_Number_Formatted__c,ShippingCountry,ECOM_isTaxExempt__c,SAP_Contact_ID__c,fxContactEmail__c, 
                              Owner.FirstName, Owner.LastName, Owner.Email, Default_Bill_to_ERP_Address__r.fxAddress_CountryName__c, Default_Bill_to_ERP_Address__r.apiCountry__c, Default_Bill_to_ERP_Address__r.Address_Country__c, 
                              ECOM_Designated_Approver__c, ECOM_E_Invoice_Code1__c, ECOM_E_Invoice_Code2__c, ECOM_E_Invoice_Code3__c, ECOM_E_Invoice_Code4__c, ECOM_E_Invoice_Cost_Center__c, ECOM_E_Invoice_Tax_Exempt__c, // ECOM-1947 - added invoice fields by sathiya on 2024/05/13
                              Default_Bill_to_ERP_Address__r.ECOM_VAT_Number__c, Default_Bill_to_ERP_Address__r.ECOM_E_Invoice_Cust_Id__c, Default_Bill_to_ERP_Address__r.ECOM_EAN_Do_Not_Use__c, Default_Bill_to_ERP_Address__r.ECOM_Email_To_Invoice__c,
                              Default_Bill_to_ERP_Address__r.Target_Address__r.ECOM_VAT_Number__c, Default_Bill_to_ERP_Address__r.Target_Address__r.ECOM_E_Invoice_Cust_Id__c, Default_Bill_to_ERP_Address__r.Target_Address__r.ECOM_EAN_Do_Not_Use__c, Default_Bill_to_ERP_Address__r.Target_Address__r.ECOM_Email_To_Invoice__c,
                              Default_Invoice_ERP_Address__r.Target_Address__c, Default_Invoice_ERP_Address__r.Target_Address__r.External_Id__c,OrderedDate,
                              ECOM_Accepted_Date__c,ECOM_End_User_For_Trade__c,ECOM_End_User_Address__c,Default_Invoice_ERP_Address__r.ECOM_Review_Status__c,
                              Total_Tariff_Surcharge__c, ECOM_Order_Summary_Status__c,BillToContactId,Default_Bill_to_ERP_Address__r.ECOM_Review_Status__c,
                      		  Default_Bill_to_ERP_Address__r.Address_City__c,Default_Bill_to_ERP_Address__r.Address_Postal_Code__c,Default_Bill_to_ERP_Address__r.apiState__c,Default_Bill_to_ERP_Address__r.fxCustomerName_Target__c, //RWPS-3868
                      		  Default_Bill_to_ERP_Address__r.Address_Street_Line_1__c,Default_Bill_to_ERP_Address__r.fxAccountName__c,Default_Bill_to_ERP_Address__r.fxAddress_City__c,
                      		  Default_Ship_to_ERP_Address__r.fxAddress_City__c,Default_Ship_to_ERP_Address__r.fxAddress_CountryName__c,Default_Bill_to_ERP_Address__r.fxAddress_Postal__c,
                      		  Default_Ship_to_ERP_Address__r.fxAddress_Postal__c,Default_Ship_to_ERP_Address__r.fxAddress_StateName__c,Default_Ship_to_ERP_Address__r.fxAddress_Street__c,
							  Default_Ship_to_ERP_Address__r.fxAccountName__c,Default_Ship_to_ERP_Address__r.ERP_Sales_Org__c,Default_Ship_to_ERP_Address__r.fxCustomerName_Master__c,
							  ECOM_ApprovalRejection_Comment__c,ECOM_Total_Items__c,TotalAdjustedProductTaxAmount,                      
                              (SELECT Id, Product2Id, Product2.Name,Product2.Business_Unit__c,Product2.Product_Line__c,Product2.Item_Class__c, Product2.Part_Number__c, Product2.DisplayUrl, OrderId, PricebookEntryId, OriginalOrderItemId, AvailableQuantity, Quantity,
                               CurrencyIsoCode, UnitPrice, ListPrice, TotalPrice, ServiceDate, EndDate, Description, TotalLineAmount, RelatedOrderItemId, Type, TypeCode, LineNumber, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, OrderItemNumber, Tariff_Surcharge__c, ecom_parent_item__c,//RWPS-3026
                               ECOM_Earliest_Shipping_Date__c, ECOM_Selected_Shipping_Date__c, Product2.Product_Display_Name__c,ECOM_OS_Expected_Ship_date__c,
                               ECOM_Order_Item_Status__c,Product2.ECOM_Product_Media_URI__c FROM OrderItems WHERE Type = 'Order Product'),
                              (SELECT Id, OrderId, DeliveryInstructions, DeliverToName, Description,ECOM_Special_Instructions__c, DesiredDeliveryDate, OrderDeliveryMethod.name, OrderDeliveryMethod.Id FROM OrderDeliveryGroups)
                              FROM Order ORDER BY CREATEDDATE DESC LIMIT 1];
        
        
        
        List<Order> orderList = new List<Order>();
        orderList.add(order);
        Test.startTest();
        List<ECOM_OrderModel> result = ECOM_OrderUtil.getOrderModelList(orderList);
        List<Map<String, String>> le = ECOM_OrderUtil.getFieldMappingByType(result[0],'test');//RWPS-3026
        ECOM_OrderModel de = ECOM_OrderUtil.getOrderDetails(orderList);//RWPS-3026
        Test.stopTest();
        
        // Assert the results
        System.assertEquals(1, result.size()); 
        ECOM_OrderModel orderModel = result[0];
        System.assertEquals(order.Id, orderModel.id); 
        System.assertEquals(order.OwnerId, orderModel.ownerId); 
        
    }
    
    
    
    @isTest
    static void testGetOrderItemlist() {
        OrderItem orderItem1 = [Select Id From OrderItem ORDER BY CreatedDate DESC LIMIT 1];
        List<OrderItem> orderItemList = new List<OrderItem>();
        orderItemList.add(orderItem1);
        Test.startTest();
        List<ECOM_OrderModel.OrderItems> result = ECOM_OrderUtil.getOrderItemlist(orderItemList);
        Test.stopTest();
        
        System.assertnotEquals(null,result,'expected orderitems should not be null');        
    }

    //ECOM-112 - garora@rafter.one - added test method to increase coverage - 12 May 2024
    @isTest
    static void setupAddressDataTest(){
        Order testOrder = [SELECT Id,ShippingStreet,ShippingCity,ShippingCountry,ShippingState,
                           ShippingPostalCode FROM Order LIMIT 1];
        OrderItem orderitem = new OrderItem();
        orderitem.OrderId = testOrder.Id;
        ECOM_FormWrapper.AddressInfo response = new ECOM_FormWrapper.AddressInfo();
        Test.startTest();
        response = ECOM_OrderUtil.setupAddressData(orderitem);
        
        Test.stopTest();
        system.assertEquals(testOrder.ShippingStreet,response.line,'Value mismatch');
    }

    //RWPS-2786 - Poonam - added test method to increase coverage - 2nd July 2025
    @isTest
    static void testupdateOrders(){
         User u = [SELECT Id,AccountId, ContactId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        Product2 prod = [SELECT Id from product2 LIMIT 1];
        Order order = [Select Id, Name From Order ORDER BY CREATEDDATE DESC LIMIT 1];
        update order;
        List<Order> ordList = new List<order>();
        set<string> ordId = new set<string>();
        ordId.add(order.id);
        ordList.add(order);
        Test.startTest();
        system.runAs(u){
            ECOM_OrderUtil.updateOrders(ordList);
        }   
        Test.stopTest();
    }

    @isTest
    static  void testGetContactNumber1() {
        Contact testContact = [Select Id,LastName From Contact ORDER BY CREATEDDATE DESC LIMIT 1];
        Account testAccount  = [Select Id From Account ORDER BY CREATEDDATE DESC LIMIT 1];
        User testUser = [Select Id,LastName,ContactId From User Where ContactId =:testContact.Id ORDER BY CREATEDDATE DESC LIMIT 1];
         ERP_Relationship__c erpRelation = [Select Id ,Name , ERP_Address__c From ERP_Relationship__c  ORDER BY CreatedDate DESC LIMIT 1];
         erpRelation.Contact__c= testContact.Id;
         update erpRelation;
        List<ERP_RelationShip__c> erpRelationships = new List<ERP_RelationShip__c>();
        erpRelationships.add(erpRelation);
        
        ERP_Address__c testAdd = new ERP_Address__c();
        insert testAdd;

        System.runAs(testUser){
            Test.startTest();
            String shipToId = testAdd.Id; 
            String result = ECOM_OrderUtil.getContactNumber(shipToId); 
            Test.stopTest();
            
            System.assertNotEquals('Null', result);
        }    
    }

    @isTest
    static  void testGetContactNumber2() {
        Contact testContact = [Select Id,LastName From Contact ORDER BY CREATEDDATE DESC LIMIT 1];
        Account testAccount  = [Select Id From Account ORDER BY CREATEDDATE DESC LIMIT 1];
        User testUser = [Select Id,LastName,ContactId From User Where ContactId =:testContact.Id ORDER BY CREATEDDATE DESC LIMIT 1];
        ERP_Relationship__c erpRelation = [SELECT Id, Name, ERP_Address__c FROM ERP_Relationship__c ORDER BY CreatedDate DESC LIMIT 1];
        erpRelation.Contact__c = testContact.Id;
        update erpRelation;

        ERP_Relationship__c erpRelation1 = [SELECT Id, Name, ERP_Address__c FROM ERP_Relationship__c ORDER BY CreatedDate DESC LIMIT 1];
        erpRelation1.Contact__c = testContact.Id;
        update erpRelation1;

        List<ERP_Relationship__c> erpRelationships = new List<ERP_Relationship__c>();
        erpRelationships.add(erpRelation);
        erpRelationships.add(erpRelation1);

        System.runAs(testUser){ 
            Test.startTest();
            String result = ECOM_OrderUtil.getContactNumber(erpRelationships[0].Id); 
            Test.stopTest();
            
        }
        
    }


   @isTest
    static void testGetOrderModelList1() {
        
        
    }

}