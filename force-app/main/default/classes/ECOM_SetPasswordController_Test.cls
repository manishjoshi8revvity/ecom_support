/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-1554
*
* 2. Description - This class is a test class For ECOM_SetPasswordController
*
* 3. Objects referenced
*    - User
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
* 5. Dependant Class(es):
*    
*
* 6. Test Class Name: 
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
* 	 - vramachandran@rafer.one | 15 May 2024
*************************************************************/
@isTest
public class ECOM_SetPasswordController_Test {
    
    @TestSetup
    public static void testData(){
        ECOM_TestUtil.testDataIntialSetup();
    }

    @isTest
    static void setNewPasswordAndRedirectUserTest(){
        
        List<User> usersList = [SELECT Id, Email, UserName from User ORDER BY CreatedDate DESC LIMIT 1];
        System.debug('usersList:: '+ JSON.serialize(usersList));
        User userRecord;
        if(usersList != null && !usersList.isEmpty()) {
            
            userRecord = usersList[0];
        }
        
        ECOM_RegistrationWrapper.ValidationResult wrapper = new ECOM_RegistrationWrapper.ValidationResult();
        wrapper.message = 'test';
        wrapper.success = true;
        
        String successResponseBody = JSON.serialize(wrapper);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ECOM_MockHttpResponseGenerator(200, 'OK', successResponseBody, null));
        ECOM_SetPasswordController.setNewPasswordAndRedirectUser(userRecord.userName, 'newPassword@123', ECOM_SetPasswordController.encryptWithAES256('TestUser123'));
        Test.stopTest();
    }
}