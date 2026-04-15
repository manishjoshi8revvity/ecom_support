/**************************************************************
* 1. Jira Ticket(s) that relates to this class 
*    - ECOM-2302
*
* 2. Description - Test class for ECOM_RegistrationService  
*
*
* 3. Objects referenced
*    -
*
* 4. Callouts to additional Components (including their methods) or None:
*    - FLOW: SUB_FLOW_4494_ECOM_User_Registration
*
* 5. Dependant Class(es):
*    - ECOM_RegistrationWrapper
*
* 6. Test Class Name: 
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vasudev R 2024-04-02 : Initial creation
*************************************************************/
@isTest
public class ECOM_RegistrationService_Test {
    
    @TestSetup
    public static void testData(){
        ECOM_TestUtil.testDataIntialSetup();
    }

    @isTest
    static void resetRegisteredUserPasswordTest() {
        
        List<User> usersList = [SELECT Id, Email, UserName from User ORDER BY CreatedDate DESC LIMIT 1];
        System.debug('usersList:: '+ JSON.serialize(usersList));
        User userRecord;
        if(usersList != null && !usersList.isEmpty()) {
            
            userRecord = usersList[0];
        }
        
        Test.startTest();
        String successResponseBody = '{"status": "success"}';
        Test.setMock(HttpCalloutMock.class, new ECOM_MockHttpResponseGenerator(200, 'OK', successResponseBody, null));
        ECOM_RegistrationService.resetRegisteredUserPassword(userRecord.Email);
        Test.stopTest();
    }
    
    @isTest
    static void registerNewAccountTest() {
        Test.startTest();
        ECOM_RegistrationService service = new ECOM_RegistrationService();
        String successResponseBody = '[{"actionName":"SUB_FLOW_4494_ECOM_User_Registration","errors":null,"invocationId":null,"isSuccess":true,"outputValues":{"varResponseMessage":"The user has been registered.","Flow__InterviewGuid":"427097900c54c229c58e2ce303ef190b896df30-74bf","varUserRegistered":true,"varIsMapped":false,"Flow__InterviewStatus":"Finished","resultSuccess":true},"sortOrder":-1,"version":1}]';
        Test.setMock(HttpCalloutMock.class, new ECOM_MockHttpResponseGenerator(200, 'OK', successResponseBody, null));
        service.registerNewAccount(new Map<String, Object>());
        Test.stopTest();
    }
}