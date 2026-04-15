/**************************************************************

* 1. Jira Ticket(s) that relates to this class
*    RWPS-2307
* 2. Description - This class is a test class.
*
* 3. Objects referenced
*    - Product2
*    - Order
*    - WebCart
*    - Account
*    - Contact
*    - User
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
* 
*    - classes called from test class
*    - ECOM_TestUtil
*    - ECOM_OrderRepo
* 6. Test Class Name:
*    -None
*
* 7. Is @Invocable : No
*
* 8. Author Name(s):
*    - Manoj 2023.09.19
*	 - Manish 2025.15.01 Updated method getOrderByIdTest for increasing code coverage
*	 - Prabhat 2025.06.24 Created method testgetOrderItems  for increasing code coverage - RWPS-2786
*	 - Sachin Vispute 2025.10.28 Added Method getOnlineOrdersTest - RWPS-4881
*	 - Sachin Vispute 2025.11.26 Modified getOnlineOrdersTest, created getOnlineOrdersWithSearchStringTest - RWPS-5094
*	 - Sachin Vispute 2025.12.30 Modified testGetOrderItems - RWPS-5507

*************************************************************/

@isTest
public class ECOM_OrderRepo_Test {
    @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
    }

   @isTest
    static void getOrderByIdTest(){
        Product2 prod = [SELECT Id from product2 LIMIT 1];
        Order order = [Select Id, Name From Order ORDER BY CREATEDDATE DESC LIMIT 1];
        order.ECOM_SAP_Order_Number__c='32332323';// RWPS-2307
        update order;// RWPS-2307
        List<Order> ordList = new List<order>();
        // RWPS-2307 START
        set<string> ordId = new set<string>();
        ordId.add(order.id);
        ordList.add(order);
        // RWPS-2307 END
        Test.startTest();
        ordList =  ECOM_OrderRepo.getOrderById(order.Id);// RWPS-2307
        String query = ECOM_OrderRepo.getQueryStringForBatch(order.Id);
        String result = ECOM_OrderRepo.getShippedOrders();
        ECOM_OrderRepo.getOrderDeliveryGroups(ordId);// RWPS-2307
        OrderDeliveryMethod odm = new OrderDeliveryMethod();
        odm.ProductId = prod.id;
        odm.name = 'Test';
        ECOM_OrderRepo.insertOrderDeliveryMethods(new List<OrderDeliveryMethod>{odm});
        OrderDeliveryMethod odm1 = new OrderDeliveryMethod();
        odm1.ProductId = prod.id;
        odm1.name = 'Test 1';
        ECOM_OrderRepo.updateOrderDeliveryMethods(new List<OrderDeliveryMethod>{odm1});
        // RWPS-2307 START
        ECOM_OrderRepo.getOrderDeliveryMethods('Test');
        OrderDeliveryMethod orderDeMethods = [SELECT Id, ProductId FROM OrderDeliveryMethod LIMIT 1];
        ECOM_OrderRepo.getOrderDeliveryMethodsById(orderDeMethods.id);
        ECOM_OrderRepo.getOrdersById(ordId);
        ECOM_OrderRepo.updateOrders(ordList);
        WebCart cart = [SELECT Id, Default_Bill_to_ERP_Address__c, Default_Ship_to_ERP_Address__c FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];   
        User u = [SELECT Id,AccountId, ContactId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        String acId = u.AccountId;
        Account acc = [SELECT Id FROM Account WHERE Id =: acId LIMIT 1];
        Contact con = [SELECT Id, Default_Ship_to_ERP_Address__c, Default_Bill_to_ERP_Address__c FROM Contact WHERE Id =: u.ContactId LIMIT 1];
        ECOM_OrderRepo.checkIfPoUsed(acId,null);
        system.runAs(u){
            ECOM_OrderRepo.getMyOrders();
        }
        set<string> te = new set<string>();
        te.add('32332323');
        ECOM_OrderRepo.getOrderDetails(order.Id);
        ECOM_OrderRepo.findOrderByOrderNumberAndZip(order.Name,'121221');
        //ECOM_OrderRepo.fetchOrdersBySAPOrderId();
        // RWPS-2307 END
        Test.stopTest();
        System.assertNotEquals(null,result,'result should not null');
    }
   	//RWPS-2786 - START 
    @isTest
    static void testGetOrderItems(){
        User u = [SELECT Id,AccountId, ContactId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
    	Contact con = [SELECT Id, Default_Ship_to_ERP_Address__c, Default_Bill_to_ERP_Address__c FROM Contact WHERE Id =: u.ContactId LIMIT 1]; 	  
        //RWPS-5507 - Start
        List<String> poTypesList = new List<String>();
        List<C_META_Storefront_Configuration__mdt> storeFrontConfigurations = ECOM_CustomMetadataRepo.fetchStoreConfigMdtBasedOnModuleName('POTypesWeb');
        if (storeFrontConfigurations.isEmpty() == false && storeFrontConfigurations[0].Value__c != null) {
            poTypesList = storeFrontConfigurations[0].Value__c.split(',');
        }
        ECOM_OrderRepo.getOrderItems(con.id, poTypesList);
        //RWPS-5507 - End
    }
    //RWPS-2786 - END 
    
    @isTest
    static void updatePaymentAuthorizationForOrderTest(){
        CardPaymentMethod cpa = new CardPaymentMethod();
        cpa.ProcessingMode='External';
        cpa.Status='Active';
          ECOM_OrderRepo.createCardPaymentForOrder(cpa);
        cpa.Phone = '1236556677';
        ECOM_OrderRepo.updateCardPaymentForOrder(cpa);
      
       
        //System.assertEquals(cpa.ProcessingMode,cpaQuery[0].ProcessingMode,'CardPaymentMethod processing mode must match');
    }

    /**
     * RWPS-4881
     * @description Test method to verify the method 'getOnlineOrders' from 'ECOM_OrderRepo'
     * @author Sachin Vispute 2025.10.28
     */
    @isTest
    static void getOnlineOrdersTest() {
        Product2 prod = [SELECT Id from product2 LIMIT 1];
        Order order = [Select Id, Name From Order ORDER BY CREATEDDATE DESC LIMIT 1];
        order.ECOM_SAP_Order_Number__c='32332323';// RWPS-2307
        update order;// RWPS-2307
        List<Order> ordList = new List<order>();
        // RWPS-2307 START
        set<string> ordId = new set<string>();
        ordId.add(order.id);
        ordList.add(order);
        // RWPS-2307 END
        Test.startTest();
        List<User> userList = [SELECT Id,AccountId, ContactId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        List<Order> orderList = new List<Order>();
        Map<String,Object> responseMap = new Map<String,Object>();
        System.runAs(userList[0]) {
            responseMap = ECOM_OrderHistoryController.getOnlineOrders(null); //RWPS-4881
        }
        Test.stopTest();
        System.assertNotEquals(null, responseMap,'orders should not be null');
    }

    /**
     * RWPS-5094
     * @description Test method to verify the method 'getOnlineOrders' from 'ECOM_OrderRepo'
     * @author Sachin Vispute 2025.11.26
     */
    @isTest
    static void getOnlineOrdersWithSearchStringTest() {
        Product2 prod = [SELECT Id from product2 LIMIT 1];
        Order order = [Select Id, Name From Order ORDER BY CREATEDDATE DESC LIMIT 1];
        order.ECOM_SAP_Order_Number__c='32332323';// RWPS-2307
        update order;// RWPS-2307
        List<Order> ordList = new List<order>();
        // RWPS-2307 START
        set<string> ordId = new set<string>();
        ordId.add(order.id);
        ordList.add(order);
        // RWPS-2307 END
        Test.startTest();
        List<User> userList = [SELECT Id,AccountId, ContactId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        List<Order> orderList = new List<Order>();
        Map<String,Object> responseMap = new Map<String,Object>();
        System.runAs(userList[0]) {
            responseMap = ECOM_OrderHistoryController.getOnlineOrders('T'); //RWPS-4881
        }
        Test.stopTest();
        System.assertNotEquals(null, responseMap,'orders should not be null');
    }
}