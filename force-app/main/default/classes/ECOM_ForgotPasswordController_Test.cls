/**************************************************************
* 1. Jira Ticket(s) that relates to this class 
*    - ECOM-2302
*
* 2. Description - Test class for ECOM_ForgotPasswordController   
*
*
* 3. Objects referenced
*    -
*
* 4. Callouts to additional Components (including their methods) or None:
*    - 
*
* 5. Dependant Class(es):
*    - ECOM_RegistrationWrapper
*
* 6. Test Class Name: 
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vasudev R 2024-05-16 : Initial creation
* 	 - Sachin V 2026.03.16 - Added method : resetUserPasswordForPunchoutTest - RWPS-5938
*************************************************************/
@isTest
public class ECOM_ForgotPasswordController_Test {
    
    @testSetup
    static void testSetup() {
        ECOM_TestUtil.testDataIntialSetup();
        
    }

    @isTest
    static void resetUserPasswordTest() {
        List<User> userRecords = [SELECT Id, Name, Email FROM User ORDER BY CreatedDate DESC LIMIT 1];
        User userRecord; 
        
        if(null != userRecords && !userRecords.isEmpty()) {
            userRecord = userRecords[0];
        }
        
        Test.startTest();
        
        String successResponseBody = '{"status": "success"}';
        Test.setMock(HttpCalloutMock.class, new ECOM_MockHttpResponseGenerator(200, 'OK', successResponseBody, null));
        ECOM_ForgotPasswordController.resetUserPassword(userRecord.Email);
        
        Test.stopTest();
        
    }

    /**
     * RWPS-5938
     * @description This is test method to verify the resetUserPassword for punchout user
     */
    @isTest
    static void resetUserPasswordForPunchoutTest() {
        List<User> userRecords = [SELECT Id, Name, Email FROM User WHERE ECOM_Is_Punchout_User__c = true ORDER BY CreatedDate DESC LIMIT 1];
        User userRecord; 

        if(null != userRecords && !userRecords.isEmpty()) {
            userRecord = userRecords[0];
        }

        Test.startTest();
        String successResponseBody = '{"status": "success"}';
        Test.setMock(HttpCalloutMock.class, new ECOM_MockHttpResponseGenerator(200, 'OK', successResponseBody, null));
        ECOM_ForgotPasswordController.resetUserPassword(userRecord.Email);
        Test.stopTest();
    }
}