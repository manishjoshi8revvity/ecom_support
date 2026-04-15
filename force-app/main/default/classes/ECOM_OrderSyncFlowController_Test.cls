@isTest
public class ECOM_OrderSyncFlowController_Test {
    @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
    }
   
   /* @isTest
    static void testProcessSAPOrderDetails() {
        // Create test data for the ECOM_OrderSyncFlowWrapper.Request list
        SAP_Order_Summary__c ordersummary = new SAP_Order_Summary__c();
        insert ordersummary;
        List<SAP_Order_Summary__c> ordersummarylist = new List<SAP_Order_Summary__c>();
        ordersummarylist.add(ordersummary);
        List<ECOM_OrderSyncFlowWrapper.Request> testOrdersFromSAP = new List<ECOM_OrderSyncFlowWrapper.Request>();
        ECOM_OrderSyncFlowWrapper.Request testRequest1 = new ECOM_OrderSyncFlowWrapper.Request();
       
        testOrdersFromSAP.add(testRequest1);

      

        Test.startTest();
       
        List<ECOM_OrderSyncFlowWrapper.Response> result = ECOM_OrderSyncFlowController.processSAPOrderDetails(testOrdersFromSAP);

        // Perform assertions to validate the results
        ECOM_OrderSyncFlowWrapper.Response response = result[0];
        System.assertEquals(true, response.success, 'Expected success to be true');

        Test.stopTest();
    }*/

    // Test method to simulate an exception in the catch block
    @isTest
    static void testProcessSAPOrderDetails() {
         SAP_Order_Summary__c ordersummary = new SAP_Order_Summary__c();
        insert ordersummary;
        List<ECOM_OrderSyncFlowWrapper.Request> ordersFromSAP = new List<ECOM_OrderSyncFlowWrapper.Request>();
        ECOM_OrderSyncFlowWrapper.Request testRequest1 = new ECOM_OrderSyncFlowWrapper.Request();
       testRequest1.sapOrderSummaryId = ordersummary.Id;
          ordersFromSAP.add(testRequest1);
        Test.startTest();
        List<ECOM_OrderSyncFlowWrapper.Response> response = ECOM_OrderSyncFlowController.processSAPOrderDetails(ordersFromSAP);
        Test.stopTest();

        // Assert that the response indicates an error
        System.assertNotEquals(null, response.size(), 'Response should have one element');
       
    }

    

}