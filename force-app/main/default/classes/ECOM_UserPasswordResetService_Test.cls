/**************************************************************
*
* 1. Jira Ticket(s) that relates to this class
*    ECOM-2302
*
* 2. Description - This is a test class for ECOM_UserPasswordResetService
*
*
*
* 3. Objects referenced
*    -None
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
*
* 5. Dependant Class(es):
*    - None
*	
* 6. Test Class Name:         
*    - 
*
* 7. Is @Invocable (Yes or No): Yes
*
* 8. Author Name(s):
*    - vramachandran@rafter.one | 09 May 2024
*************************************************************/
@isTest
public class ECOM_UserPasswordResetService_Test {
    
    @testSetup
    static void testSetup() {
        ECOM_TestUtil.testDataIntialSetup();
    }

    @isTest
    static void getSiteUrlTest() {
        Test.startTest();
        //ECOM_UserPasswordResetService.getSiteUrl();
        Test.stopTest();
    }
    
    @isTest
    static void encryptStringTest(){
        Test.startTest();
        ECOM_UserPasswordResetService.encryptString('Test');
        Test.stopTest();
    }
    
    @isTest
    static void resetUserPasswordTest(){
        List<User> usersList = [SELECT Id, Email FROM User ORDER BY CreatedDate DESC LIMIT 1];
        User userRecord;
        
        if(null != usersList && !usersList.isEmpty()){
        	userRecord = usersList[0];    
        }
        
        Test.startTest();
        ECOM_UserPasswordResetService.resetUserPassword(userRecord.Email, System.Label.ECOM_RegisteredUserPasswordResetEndpoint);
        Test.stopTest();
    }
        
}