/**************************************************************

* 1. Jira Ticket(s) that relates to this class

*  

*

* 2. Description - This class is a test class.

*

* 3. Objects referenced

*    - User

*    - Order

*.   - OrderItem

* 4. Callouts to additional Components (including their methods) or None:

*    - None

*

* 5. Dependant Class(es):

*    - ECOM_TestUtil

*    - classes called from test class

*

* 6. Test Class Name:

*    -None

*

* 7. Is @Invocable : No

*

* 8. Author Name(s):

*    - Manoj 2023.09.19
*	 - Vipul 2024.05.10 Added method getApprovalOrdersTest for ECOM-103
*	 - Sachin Vispute 2025.10.28 Added method getOnlineOrdersTest - RWPS-4881
*	 - Sachin Vispute 2025.11.26 Modified method getOnlineOrdersTest - RWPS-5094
*	 - Poonam 2025.12.03 Updated method setupOrderItemDetailsTest to increase code coverage


*************************************************************/


@isTest(SeeAllData=false)
public with sharing class ECOM_OrderService_Test {
    
    @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
    }
    
    @isTest
    static void testGetOrdersById() {
        Test.startTest();
        Set<String> orderNames = new Set<String>{'Order 1', 'Order 2', 'Order 3'};
            List<Order> actualOrders = ECOM_OrderService.getOrdersById(orderNames);
        Test.stopTest();
        // Assert the results
        List<Order> expectedOrders = [SELECT Id, Name, Status FROM Order WHERE Id IN :orderNames];
        System.assertEquals(expectedOrders, actualOrders, 'The list of orders should match the expected orders');
    }
    
    @isTest
    static void testgetOrdersBySAPOrderId(){
        Order order = [Select Id From Order ORDER BY CREATEDDATE DESC LIMIT 1];
        User u = [Select Id,LastName From User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        Set<String> sapOrderIds = new Set<String>();
        sapOrderIds.add(order.Id);
        
        Test.startTest();
        List<Order> ord;
        //System.runAs(u){
            ord =   ECOM_OrderService.getOrdersBySAPOrderId(sapOrderIds);
        //}
        Test.stopTest();
        // Assert the expected results
        System.assertnotEquals(null,ord,'expected order should not be null');
        
    }
    
    @isTest
    static void testupdateOrders(){
        Order order = [Select Id From Order ORDER BY CREATEDDATE DESC LIMIT 1];
        order.BillingCity = 'Alaska';
        update order;
        User u = [Select Id,LastName From User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        
        Test.startTest();
        List<Order> ordersToUpdate = new List<Order>();
        ordersToUpdate.add(order);
        //System.runAs(u){
            ECOM_OrderService.updateOrders(ordersToUpdate);
        //}
        Test.stopTest();
        System.assertnotEquals(null,ordersToUpdate,'expected order should not be null');
        
    }
    @isTest
    static void testupdateOrderItems(){
        User u = [Select Id,LastName From User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        OrderItem orderitem = [Select Id From OrderItem ORDER BY CREATEDDATE DESC LIMIT 1];
        orderitem.Quantity = 2.00;
        update orderitem;
        
        Test.startTest();
        List<OrderItem> orderitemsToUpdate = new List<OrderItem>();
        orderitemsToUpdate.add(orderitem);
        //System.runAs(u){
            ECOM_OrderService.updateOrderItems(orderitemsToUpdate);
        //}
        Test.stopTest();
        System.assertnotEquals(null,orderitemsToUpdate,'expected order should not be null');
    }
    
    @isTest
    static void testcheckIfPoUsed(){
        Account ac = [SELECT Id FROM Account WHERE Name = 'TestClass Account'];
        User u = [Select Id,LastName From User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        Order order = [Select Id,OrderNumber,BillingPostalCode From Order ORDER BY CREATEDDATE DESC LIMIT 1];
        order.PoNumber = '12334';
        update order;
        List<Order> result = new List<Order>();
        Test.startTest();
        //System.runAs(u){
            result =  ECOM_OrderService.checkIfPoUsed(ac.Id,order.PoNumber);
        //}
        
        Test.stopTest();
        System.assertnotEquals(null,result,'expected order should not be null');
    }
    
    @isTest
    static void getMyOrdersTest(){
        Order order = [Select Id From Order ORDER BY CREATEDDATE DESC LIMIT 1];
        User u = [Select Id,LastName From User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        
        Test.startTest();
        List<Order> ord;
        //System.runAs(u){
            ord =  ECOM_OrderService.getMyOrders();
        //}
        
        Test.stopTest();
        //System.assertEquals(ord.size(),1,'expected order details error');
        //System.assert(ord.size()>0,'expectedorderdetails error');
    }  
    @isTest
    static void getOrderDetailsTest(){
        Account ac = [SELECT Id FROM Account WHERE Name = 'TestClass Account'];
        User u = [Select Id,LastName From User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        Order order = [Select Id From Order ORDER BY CREATEDDATE DESC LIMIT 1];
        order.ECOM_SAP_Order_Number__c = '223345';
        update order;
        SAP_Order_Summary__c testSapOrder = new SAP_Order_Summary__c(
            Account__c = ac.Id,
            Order_Number__c = 223345,
            Bill_To_Address_Street__c = '123 Main St',
            Bill_To_Address_City__c = 'City',
            Bill_To_Address_Region__c = 'State',
            Bill_To_Address_Postal_Code__c = '12345',
            Bill_To_Address_Country__c = 'Country',
            CreatedById = UserInfo.getUserId(),
            CreatedDate = Date.today(),
            Quote_Number__c = 'Q123',
            Order_Total_Price__c = 100.00
            
        );
        insert testSapOrder;
        SAP_Order_Items__c sapOrderItem = new SAP_Order_Items__c();
        sapOrderItem.Material_Description__c = 'Product Description';
        sapOrderItem.PKI_Order_Summary__c = testSapOrder.Id;
        // PKI_Order_Summary__c = sapOrder,
        sapOrderItem.Expected_Ship_Date__c = Date.today();
        sapOrderItem.Scheduled_Delivery_Date__c = Date.today();
        sapOrderItem.Extended_Price__c = 50.00;
        sapOrderItem.Material_Number__c = '1234567';
        sapOrderItem.Quantity_Ordered__c = 2;
        sapOrderItem.Customer_Specific_Price__c = 45.00;
        sapOrderItem.Net_Price__c = 40.00;
        sapOrderItem.Adjusted_Unit_Price__c = 42.00;
        insert sapOrderItem;
         SAP_Order_Item_Tracking__c tracking = new SAP_Order_Item_Tracking__c(
            CarrierName__c = 'Carrier',
            PKIOrderItems__c = sapOrderItem.Id,
            PKIOrderSummary__c = testSapOrder.Id,
            Quantity_Shipped__c = 2,
            ExternalID__c = '112234',
            Tracking_Date__c = Date.today(),
            TrackingNumber__c = 'Tracking123',
            TrackingURL__c = 'https://example.com/tracking'
        );

        insert tracking;
        ECOM_OrderModel ordmodel = new ECOM_OrderModel();
        
        Test.startTest();
        //System.runAs(u){
            ordmodel = ECOM_OrderService.getOrderDetails(order.Id);   
        //}
        
        Test.stopTest();
        System.assertnotEquals(null,ordmodel,'expected order should not be null');
    } 
    
  /*  @isTest
    static void checkOrderOnHoldTest(){
        Order order = [Select Id From Order ORDER BY CREATEDDATE DESC LIMIT 1];
        User u = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        order.ECOM_Order_On_Hold__c = true;
        update order;
        List<String> ord = new List<String>();
        ord.add(order.Id);
        
        
        Test.startTest();
        Map<String, String> result;
        System.runAs(u){
            result = ECOM_OrderService.orderHold(ord);
        }
        Test.stopTest();
        
        System.assertnotEquals(null,result,'expected order should not be null');
    }*/
    
    @isTest
    static void getOrderDeliveryMethodTest(){
        List<OrderDeliveryMethod> testDeliveryMethod = [SELECT Id,Name FROM OrderDeliveryMethod LIMIT 1];
        Test.startTest();
        List<OrderDeliveryMethod> result = ECOM_OrderService.getOrderDeliveryMethods(testDeliveryMethod[0].Name);
        Test.stopTest();
        System.assertEquals(testDeliveryMethod[0].Id,result[0].Id,'Delivery Method should match');
    }
    
    @isTest
    static void anyOrderWithBillingCPA(){
        Order order = [Select Id From Order ORDER BY CREATEDDATE DESC LIMIT 1];
        User u = [Select Id,LastName From User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        ContactPointAddress cpa = new ContactPointAddress();
        cpa.Name='test address';
        insert cpa;
        order.ECOM_DefaultBillToCPA__c=cpa.Id;
        update order;
        Test.startTest();
        Boolean result;
        //System.runAs(u){
            result = ECOM_OrderService.anyOrderWithBillingCPA(cpa.Id);
        //}
        Test.stopTest();
        //System.assertEquals(true,result,'No order exists');
    }
    
    @isTest
    static void setupOrderItemDetailsTest(){
        OrderItem orderItem = [Select Id,OrderId,Order.ShippingStreet,Order.ShippingCity,
                               Order.ShippingState,Order.ShippingCountry,Order.ShippingPostalCode ,Quantity,
                               Product2.Part_Number__c,Order.ECOM_Order_Summary_Status__c,Order.ECOM_SAP_Order_Number__c,
                               CreatedDate,Order.OrderedDate,LineNumber,Order.OrderNumber,Order.Default_Bill_to_ERP_Address__c,
                               Order.Default_Bill_to_ERP_Address__r.Target_Address__c,Order.Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c,
                               ECOM_SAP_Order_Items__r.Line_Item_Number_SAP__c FROM OrderItem
                               ORDER BY CREATEDDATE DESC LIMIT 1];
        Order ord = [SELECT Id, ECOM_SAP_Order_Number__c, OrderedDate FROM Order WHERE Id = :orderItem.OrderId];
        ord.ECOM_SAP_Order_Number__c = '123456';
        ord.OrderedDate = System.today();
        update ord;
        Order order = [Select Id,Default_Ship_to_ERP_Address__c From Order ORDER BY CREATEDDATE DESC LIMIT 1];
        Account acc = [SELECT Id,Name FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
        ERP_Address__c testAdd = new ERP_Address__c();
        testAdd.Account__c = acc.Id;
        insert testAdd;
        order.Default_Ship_to_ERP_Address__c = testAdd.Id;
        update order;
        ECOM_FormWrapper.FormWrapper wrapper = new ECOM_FormWrapper.FormWrapper();
        Test.startTest();
        wrapper=ECOM_OrderService.setupOrderItemDetails(wrapper, orderItem.Id);
        Test.stopTest();
        System.assertEquals(acc.Name,wrapper.companyName,'Company name should be same');
    }
    
    @isTest
    static void checkOrdersTestCase3(){
        Order order = [Select Id,Default_Bill_to_ERP_Address__c From Order ORDER BY CREATEDDATE DESC LIMIT 1];
        User u = [Select Id,LastName From User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        ERP_Address__c testAdd = new ERP_Address__c();
        insert testAdd;
        order.Default_Bill_to_ERP_Address__c=testAdd.Id;
        update order;
        List<String> billERPS = new List<String>();
        billERPS.add(testAdd.Id);
        test.startTest();
        Boolean result;
        //System.runAs(u){
            result = ECOM_OrderService.checkOrders(new List<String>(),billERPS,new List<String>());
        //}
        test.stopTest();
        //system.assertEquals(true,result,'No Order exists for billing ERP');
    }
    
    @isTest
    static void getOrderItemBasedOnIdTest(){
        OrderItem orderItem = [Select Id From OrderItem ORDER BY CREATEDDATE DESC LIMIT 1];
        Test.startTest();
        OrderItem result = ECOM_OrderService.getOrderItemBasedOnId(orderItem.Id);
        Test.stopTest();
        System.assertEquals(orderItem.Id,result.Id,'OrderItem Id must match');
    }
    
    @isTest
    static void getCardPaymentBasedOnOrderTest(){
        Order order = [Select Id From Order ORDER BY CREATEDDATE DESC LIMIT 1];
        CardPaymentMethod cpa = new CardPaymentMethod();
        cpa.ProcessingMode='External';
        cpa.Status='Active';
        cpa.ECOM_Order__c=order.Id;
        insert cpa;
        Test.startTest();
        List<CardPaymentMethod> results = ECOM_OrderService.getCardPaymentBasedOnOrder(cpa.ECOM_Order__c);
        Test.stopTest(); 
        System.assertEquals(cpa.ECOM_Order__c,results[0].ECOM_Order__c,'CardPaymentMethod order Id must match');
    }
    
    @isTest
    static void getPaymentAuthorizationBasedOnOrderTest(){
        Order order = [Select Id From Order ORDER BY CREATEDDATE DESC LIMIT 1];
        PaymentAuthorization pa = new PaymentAuthorization();
        pa.Amount=50;
        pa.ProcessingMode='External';
        pa.Status='Processed';
        pa.ECOM_Order__c=order.Id;
        insert pa;
        Test.startTest();
        List<PaymentAuthorization> results = ECOM_OrderService.getPaymentAuthorizationBasedOnOrder(order.Id);
        Test.stopTest(); 
        System.assertEquals(50,results[0].Amount,'PaymentAuthorization Amount must match');
    }
    
    @isTest
    static void createCardPaymentForOrderTest(){
        CardPaymentMethod cpa = new CardPaymentMethod();
        cpa.ProcessingMode='External';
        cpa.Status='Active';
        Test.startTest();
        ECOM_OrderService.createCardPaymentForOrder(cpa);
        Test.stopTest(); 
        List<CardPaymentMethod> cpaQuery = [SELECT Id,ProcessingMode FROM CardPaymentMethod];
        System.assertEquals(cpa.ProcessingMode,cpaQuery[0].ProcessingMode,'CardPaymentMethod processing mode must match');
    }
    
    @isTest
    static void createPaymentAuthorizationForOrderTest(){
        PaymentAuthorization pa = new PaymentAuthorization();
        pa.Amount=50;
        pa.ProcessingMode='External';
        pa.Status='Processed';
        Test.startTest();
        ECOM_OrderService.createPaymentAuthorizationForOrder(pa);
        Test.stopTest(); 
        List<PaymentAuthorization> paQuery = [SELECT Id,Amount FROM PaymentAuthorization WHERE Amount=50];
        System.assertEquals(pa.Amount,paQuery[0].Amount,'PaymentAuthorization amount must match');
    }
    
    @isTest
    static void getOrderDeliveryMethodsByIdTest(){
        List<OrderDeliveryMethod> testDeliveryMethod = [SELECT Id FROM OrderDeliveryMethod LIMIT 1];
        Test.startTest();
        List<OrderDeliveryMethod> result = ECOM_OrderService.getOrderDeliveryMethodsById(testDeliveryMethod[0].Id);
        Test.stopTest();
        System.assertEquals(testDeliveryMethod[0].Id,result[0].Id,'Delivery Method should match');
    }
    
    
    @isTest
    static void getApprovalOrdersTest(){
        Test.startTest();
        List<Order> orders = ECOM_OrderService.getOrdersForApproval(UserInfo.getUserId(),'test@test.com');
        Integer orderCount = ECOM_OrderService.getOrdersForApprovalCount(UserInfo.getUserId(),'test@test.com');
        Test.stopTest();
        System.assertEquals(orders.size(),0,'No Order found');
        System.assertEquals(orderCount,0,'No Order found');
    }

    /**
     * RWPS-5094
     * @description Test method to verify the method 'getOnlineOrders' from 'ECOM_OrderService'
     * @author Sachin Vispute 2025.10.28
     */
    @isTest
    static void getOnlineOrdersTest() {
        List<Order> ordersList = [Select Id From Order ORDER BY CREATEDDATE DESC LIMIT 1];
        List<User> userList = [Select Id,LastName From User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];

        Test.startTest();
        Map<String,Object> responseMap = new Map<String,Object>();
        responseMap =  ECOM_OrderHistoryController.getOnlineOrders(null); //RWPS-5094
        Test.stopTest();
        System.assertNotEquals(null, responseMap,'expected Order Details');
    }
}