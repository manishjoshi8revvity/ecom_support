/**************************************************************

* 1. Jira Ticket(s) that relates to this class
*  
*
* 2. Description - This is a test class
*
* 3. Objects referenced
*    - User
*    - Profile
*    - Contact

*	 

* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_TestUtil

* 6. Test Class Name:
*
* 7. Is @Invocable : No
*
* 8. Author Name(s):
*    - Manojkumar 2023.09.18
*************************************************************/
@isTest(SeeAllData=false)
public with sharing class ECOM_UserModel_Test {
    @isTest
    static void testPasswordRequest() {
        Profile portalProfile = [SELECT Id FROM Profile WHERE Name = :ECOM_Constant.PROFILE_NAME LIMIT 1];
        User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact'
        );
        insert testContact;
        
        //User portalUser = ECOM_TestUtil.createPortalUser(testContact, portalProfile);
        ECOM_UserModel.PasswordRequest request;
        System.runAs(u){
            request = new ECOM_UserModel.PasswordRequest();
            request.userName = 'testuser';
            request.userId = u.Id;
            request.password = 'NewP@ssw0rd';
            request.token = 'exampleToken';
            request.code = '123456';
            request.profileId = portalProfile.Id;  
        }
        
        
        // Add assertions to validate the request object
        System.assertEquals('testuser', request.userName);
        System.assertEquals(u.Id, request.userId);
        System.assertEquals('NewP@ssw0rd', request.password);
        System.assertEquals('exampleToken', request.token);
        System.assertEquals('123456', request.code);
        System.assertEquals(portalProfile.Id, request.profileId);
    }
    
    @isTest
    static void testPasswordResponse() {
        User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        ECOM_UserModel.PasswordResponse response;
        System.runAs(u){
            response  = new ECOM_UserModel.PasswordResponse();
            response.userName = 'testuser';
            response.success = true;
            response.message = 'Password changed successfully';
        }
        
        
        // Add assertions to validate the response object
        System.assertEquals('testuser', response.userName);
        System.assertEquals(true, response.success);
        System.assertEquals('Password changed successfully', response.message);
    }
    
    
}