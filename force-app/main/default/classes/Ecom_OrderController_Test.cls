/**************************************************************
 * 1. Jira Ticket(s) that relates to this class
 *    ECOM-103
 * 	  ECOM-114
 * 
 * 2. Description - This class acts as a test class for controller class ECOM_OrderController.
 * 
 * 3. Objects referenced
 *    - None
 * 
 * 4. Callouts to additional Components (including their methods) or None:
 *    - None
 * 
 * 5. Dependant Class(es):
 *    - ECOM_OrderController
 * 
 * 6. Test Class Name: NA
 * 
 * 7. Is @Invocable (Yes or No): No
 * 
 * 8. Author Name(s):
 *    - Vipul Goyal 2024.05.06 Added method testOrderApprovalDetailsApproved,testOrderApprovalDetailsRejected,testOrderApprovalDetailsPR,testOrderApprovalCount,testOrderApproval for ECOM-103
 * 	  - Prabhat Kumar 2025.01.04 Added method getRecentlyPurchasedProducts to check if the Products are returned.
 * 	  - Manish Joshi 2025.04.17 Updated test method to increase code coverage - RWPS-3023
 *************************************************************/
@isTest
public with sharing class Ecom_OrderController_Test {
    
    @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
    }
    @isTest
    static void testmakeCallout(){
         Order testOrder = [SELECT Id ,OrderNumber,ECOM_Promo_Code__c,PoNumber FROM Order ORDER BY CreatedDate DESC LIMIT 1];
        OrderItem testOrderItem = [SELECT Id  FROM OrderItem ORDER BY CreatedDate DESC LIMIT 1];
        ECOM_MockHttpResponseGenerator mock = new ECOM_MockHttpResponseGenerator(200, 'OK', 'body', null);
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
          Map<String,Object> resultmap = Ecom_OrderController.makeCallout(testOrderItem.Id,'test1','test2','test3');
        
        Test.stopTest();
     System.assertEquals(resultmap.get('Success'), true,'Error message');
        
    }
    //to cover catch
    @isTest
    static void testmakeCalloutExemption(){
         Order testOrder = [SELECT Id ,OrderNumber,ECOM_Promo_Code__c,PoNumber FROM Order ORDER BY CreatedDate DESC LIMIT 1];
         OrderItem testOrderItem = [SELECT Id  FROM OrderItem ORDER BY CreatedDate DESC LIMIT 1];
        Test.startTest();
        Ecom_OrderController.makeCallout('testOrderItem.Id','test1','test2','test3');
        Test.stopTest();
    }
    
     @isTest
    static void testgetAssociatedReasonst(){
        Order testOrder = [SELECT Id ,OrderNumber,ECOM_Promo_Code__c,PoNumber FROM Order ORDER BY CreatedDate DESC LIMIT 1];
        OrderItem testOrderItem = [SELECT Id  FROM OrderItem ORDER BY CreatedDate DESC LIMIT 1];
        Test.startTest();
        Map<String,Object> resultmap = Ecom_OrderController.getAssociatedReasons(testOrderItem.Id);
        Map<String,Object> resultmap1 = Ecom_OrderController.getAssociatedReasons('');//RWPS-3023
        Test.stopTest();
     	System.assertEquals(resultmap.get('Success'), true,'Error message');
    }
    
    
    @isTest
    static void testOrderApproval(){
        Order testOrder = [SELECT Id ,OrderNumber,ECOM_Promo_Code__c,PoNumber,status FROM Order ORDER BY CreatedDate DESC LIMIT 1];
        OrderItem testOrderItem = [SELECT Id  FROM OrderItem ORDER BY CreatedDate DESC LIMIT 1];
        Test.startTest();
        Map<String,Object> resultmap = ECOM_OrderController.updateOrderStatus(testOrder.Id,'Rejected','Order Rejected');
        Map<String,Object> resultmap2 = ECOM_OrderController.updateOrderStatus('','Rejected','Order Rejected');//RWPS-3023
        Test.stopTest();
     	System.assertEquals(resultmap.get('Success'), true,'Success');
    }
    
    //RWPS-3023 - START
    @isTest
    static void testOrderApproval1(){
        Order testOrder = [SELECT Id ,OrderNumber,ECOM_Promo_Code__c,PoNumber,status FROM Order ORDER BY CreatedDate DESC LIMIT 1];
        OrderItem testOrderItem = [SELECT Id  FROM OrderItem ORDER BY CreatedDate DESC LIMIT 1];
        Test.startTest();
        Map<String,Object> resultmap = ECOM_OrderController.updateOrderStatus(testOrder.Id,'Draft','Order Draft');
        Test.stopTest();
    }
    //RWPS-3023 - END
    
     @isTest
    static void testOrderApprovalCount(){
         Order testOrder = [SELECT Id ,OrderNumber,ECOM_Promo_Code__c,PoNumber FROM Order ORDER BY CreatedDate DESC LIMIT 1];
         OrderItem testOrderItem = [SELECT Id  FROM OrderItem ORDER BY CreatedDate DESC LIMIT 1];
        
        Test.startTest();
          Map<String,Object> resultmap = ECOM_OrderController.getApprovalCount();
        
        Test.stopTest();
     System.assertEquals(resultmap.get('Success'), true,'Success');
    }
    
     @isTest
    static void testOrderApprovalDetailsPR(){
         Order testOrder = [SELECT Id ,OrderNumber,ECOM_Promo_Code__c,PoNumber,status,OwnerID,ECOM_Designated_Approver__c FROM Order ORDER BY CreatedDate DESC LIMIT 1];
         testOrder.status ='Pending Review';
         testOrder.OwnerID = UserInfo.getUserId();
         testOrder.ECOM_Designated_Approver__c = 'test@test.com';
       	 update testOrder;
         OrderItem testOrderItem = [SELECT Id  FROM OrderItem ORDER BY CreatedDate DESC LIMIT 1];
        
        Test.startTest();
          Map<String,Object> resultmap = ECOM_OrderController.getOrderApprovalDetails();
        
        Test.stopTest();
     System.assertEquals(resultmap.get('Success'), true,'Success');
    }

	@isTest
    static void testOrderApprovalDetailsRejected(){
         Order testOrder = [SELECT Id ,OrderNumber,ECOM_Promo_Code__c,PoNumber,status,OwnerID,ECOM_Designated_Approver__c FROM Order ORDER BY CreatedDate DESC LIMIT 1];
         testOrder.status ='Rejected';
         testOrder.OwnerID = UserInfo.getUserId();
         testOrder.ECOM_Designated_Approver__c = 'test@test.com';
       	 update testOrder;
         OrderItem testOrderItem = [SELECT Id  FROM OrderItem ORDER BY CreatedDate DESC LIMIT 1];
        
        Test.startTest();
          Map<String,Object> resultmap = ECOM_OrderController.getOrderApprovalDetails();
        
        Test.stopTest();
     System.assertEquals(resultmap.get('Success'), true,'Success');
    }
    
    @isTest
    static void testOrderApprovalDetailsApproved(){
         Order testOrder = [SELECT Id ,OrderNumber,ECOM_Promo_Code__c,PoNumber,status,OwnerID,ECOM_Designated_Approver__c FROM Order ORDER BY CreatedDate DESC LIMIT 1];
         testOrder.status ='Approved';
         testOrder.OwnerID = UserInfo.getUserId();
         testOrder.ECOM_Designated_Approver__c = 'test@test.com';
       	 update testOrder;
         OrderItem testOrderItem = [SELECT Id  FROM OrderItem ORDER BY CreatedDate DESC LIMIT 1];
        
        Test.startTest();
          Map<String,Object> resultmap = ECOM_OrderController.getOrderApprovalDetails();
        
        Test.stopTest();
     System.assertEquals(resultmap.get('Success'), true,'Success');
    }
        
    
    /**
    * @description Test class to verify the recently purchased Products.
    * @author Prabhat Kumar
    * @date 01-04-2025
    */
    @isTest
    static void getRecentlyPurchasedProducts(){
        
        Network comm = [SELECT id, name FROM Network ORDER BY CREATEDDATE DESC limit 1]; 
        String communityId = (String)comm.Id;
        User u = [Select Id,LastName, ContactId, AccountId From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Product2 testProduct = ECOM_TestUtil.createProduct('TestProduct12','1','TP143',True);
        Product_Sales__c productSales = ECOM_TestUtil.createProduct_Sales(testProduct.Id);
        ERP_Address__c master = ECOM_TestUtil.createNewPunchoutMasterAddressConfiguration();
        master.ECOM_Punchout_Products_Exclude_Query__c = 'SHOW PRODUCT Where RadioActive != true AND PartNumber not in (\'1234567\')';
        master.ECOM_Punchout_Products_Include_Query__c='';
        update master;
        Account acc = [SELECT Id FROM Account where Id =:u.AccountId LIMIT 1];
        ECOM_TestUtil.createRelatedAddresses(acc,master);
        List<String> partNumberQuantityList = new List<String>{'PART123', 'PART456'};
        List<String> result;
        System.runAs(u){
            ECOM_OrderController.getRecentlyPurchasedProducts(communityId);
        }
    }
    
}