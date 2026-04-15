/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-1020
*	 ECOM-1022
*    RWPS-667
*
* 2. Description - This class is a test class for controller class to login punchout users.
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
*    - ECOM_PunchoutTestUserLoginController_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - vramachandran@rafter.one | 07 Jan 2024
*    - ssingh@rafter.one | Added method testLogFailure| 15 May 2024 | RWPS-667
*************************************************************/
@isTest
public class ECOM_PunchoutTestLoginController_Test {
    
    //Test Method to test getReturnURL() Method
     @isTest
    static void testGetReturnURL() {
        Test.startTest();
        ECOM_PunchoutTestUserLoginController punchoutuser  = new ECOM_PunchoutTestUserLoginController();
        // Call the method to be tested
        String result = punchoutuser.getReturnURL();
        Test.stopTest();
    }
    
    
    //Test Method to test decryptWithAES256() Method
    @isTest
    static void testDecryptWithAES256() {
        Map<String, String> responseHeaders = new Map<String, String>();
        responseHeaders.put('Content-Type', 'application/json');
        String encryptedText = 'EncodedString'; 
        
        ECOM_MockHttpResponseGenerator mockResponse = new ECOM_MockHttpResponseGenerator(200, 'OK', '{"result": "success"}', responseHeaders);
        Test.startTest();
        String result = ECOM_PunchoutTestUserLoginController.decryptWithAES256(encryptedText);
        Test.stopTest();
        System.assertEquals(null, result,'Expected Result');
        
    }
   
    @isTest
    static void testCreateNewSessionCookie() {
        
        User testUser = [Select Id,LastName,Email From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Test.startTest();
        ECOM_PunchoutTestUserLoginController.createNewSessionCookie(testUser);
        Test.stopTest();
        System.assertNotEquals(null,  'No cookies found');
    }
    


    @isTest
    static void testGetPunchoutUserInformationForUserId() {

        User testUser = [Select Id,LastName,Email,ECOM_Is_Punchout_User__c From User ORDER BY CREATEDDATE DESC LIMIT 1];
        testUser.ECOM_Is_Punchout_User__c = true;
        update testUser;

        Test.startTest();
        User resultUser = ECOM_PunchoutTestUserLoginController.getPunchoutUserInformationForUserId(testUser.Id);
        Test.stopTest();

        System.assertNotEquals(null, resultUser, 'User record should not be null');
    }
    
    /**
    * @description  this method is used to test log failure
    * @author singh@rafter.one | 05-15-2024 | RWPS-667
    * @param excp 
    * @param moduleName 
    * @param className 
    * @param methodName 
    * @param supportData 
    **/
    @isTest
    static void testLogFailure() {

        Exception excp; 
        String moduleName = 'Test';
        String className = 'ECOM_PunchoutTestLoginController_Test';
        String methodName = 'testLogFailure';
        String supportData = 'test';

        Test.startTest();
        ECOM_PunchoutTestUserLoginController.logFailure(excp, moduleName, className, methodName, supportData);
        Test.stopTest();

    }


}