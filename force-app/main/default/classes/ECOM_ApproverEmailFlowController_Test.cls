@IsTest
public with sharing class ECOM_ApproverEmailFlowController_Test {
    @TestSetup
   	static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
    }
    
    @isTest
    static void checkEmailsTest(){
        User u = [SELECT Email FROM User ORDER BY CreatedDate DESC LIMIT 1];
        List<ECOM_ApproverEmailFlowController.Request> requests = new List<ECOM_ApproverEmailFlowController.Request>();
        ECOM_ApproverEmailFlowController.Request request = new ECOM_ApproverEmailFlowController.Request();
        request.emails = 'test@gmail.com;'+u.Email;
        requests.add(request);
        List<ECOM_ApproverEmailFlowController.Result> results = ECOM_ApproverEmailFlowController.checkEmails(requests);
        system.debug(results);
    }

}