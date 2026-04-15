/**************************************************************
*
* 1. Jira Ticket(s) that relates to this class
*    ECOM-1533
*	 ECOM-1022
*
* 2. Description 
*    - This class is a test class for ECOM_PunchoutPOOMFlowController
*
* 3. Objects referenced
*    -None
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - None
*	
* 6. Test Class Name:         
*    - None
*
* 7. Is @Invocable (Yes or No): Yes
*
* 8. Author Name(s):
*    -vramachandran@rafter.one | 05 Dec 2024

*************************************************************/
@isTest
public class ECOM_PunchoutPOOMFlowController_Test {

    @TestSetup
    public static void testData(){
        ECOM_TestUtil.initialStorefrontSetup();
    }
    
    @isTest
    static void testGetUserServiceInstance() {
        // Test case 1: When userService is null
        ECOM_IUserService userServiceInstance1 = ECOM_PunchoutPOOMFlowController.getUserServiceInstance();
        System.assertNotEquals(null, userServiceInstance1, 'userService should not be null after the first call');
        
        // Test case 2: When userService is not null
        ECOM_IUserService userServiceInstance2 = ECOM_PunchoutPOOMFlowController.getUserServiceInstance();
        System.assertEquals(userServiceInstance1, userServiceInstance2, 'userService should be the same instance after the second call');
    }
    
     @isTest
    static void testGetAddressServiceInstance() {
        // Test case 1: When addressService is null
        ERP_IAddressService addressServiceInstance1 = ECOM_PunchoutPOOMFlowController.getAddressServiceInstance();
        System.assertNotEquals(null, addressServiceInstance1, 'addressService should not be null after the first call');
        
        // Test case 2: When addressService is not null
        ERP_IAddressService addressServiceInstance2 = ECOM_PunchoutPOOMFlowController.getAddressServiceInstance();
        System.assertEquals(addressServiceInstance1, addressServiceInstance2, 'addressService should be the same instance after the second call');
    }
    
   

    @isTest
    static void testInsertBoomiPOOMLogs() {
        // Create a test ECOM_POOMModel
        ECOM_POOMModel testPoomRequest = new ECOM_POOMModel();
        
        Map<String, Object> testPoomBody = new Map<String, Object>();
        testPoomBody.put('poomResponse', testPoomRequest);

        // Create a test boomiResponse
        String testBoomiResponse = 'Test Boomi Response';

        // Call the method
        ECOM_PunchoutPOOMFlowController.insertBoomiPOOMLogs(testPoomBody, testBoomiResponse, true);

        // Retrieve and verify logs
        List<ECOM_Application_Logs__c> logs = [SELECT Id, OwnerId, ClassName__c, ECOM_Account__c, ECOM_Log_Type__c, SupportData__c FROM ECOM_Application_Logs__c];

        System.assertEquals(2, logs.size(), 'Two logs should be inserted (request and response logs)');

        // Verify the details of the request log
        ECOM_Application_Logs__c requestLog = logs[0];
        //System.assertEquals(ECOM_PunchoutPOOMFlowController, requestLog.ClassName__c, 'Incorrect request log ClassName__c');
        // Add more assertions for other fields of the request log

        // Verify the details of the response log
        ECOM_Application_Logs__c responseLog = logs[1];
        //System.assertEquals(ECOM_PunchoutPOOMFlowController, responseLog.ClassName__c, 'Incorrect response log ClassName__c');
    
}

}