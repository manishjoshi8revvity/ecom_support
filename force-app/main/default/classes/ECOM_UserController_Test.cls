/**************************************************************

* 1. Jira Ticket(s) that relates to this class
*
* 2. Description - This class is a test class.
*
* 3. Objects referenced
*    - Account
*    - Contact
*    - User
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_TestUtil
*    - ECOM_UserController
*
* 6. Test Class Name:
*    -None
*
* 7. Is @Invocable : No
*
* 8. Author Name(s):
*    - Manoj 2023.09.19
*    - Abhishek 2025.07.15 Added method testgetCountriesBannerMsgLoggedin - RWPS-3651
*    - Sachin V 2025.12.29 Added method testGetOrganizationDetails, testGetTestUserConfigurations - RWPS-5436

*************************************************************/


@isTest(SeeAllData=false)
private with sharing class ECOM_UserController_Test {
    //Creating Test Data
    @TestSetup
    static void setupTestData() {
        ECOM_TestUtil.testDataIntialSetup();
    }
 @isTest
    static void testGetUser() {

        //Calling getUser method
        Test.startTest();
        Map<String, Object> result = ECOM_UserController.getUser();
        Test.stopTest();

        //Validating result
        System.assertEquals(true, result.get('Success'), 'Expected Success to be true');
        User us = (User) result.get('User');
        System.assertNotEquals(null, us, 'Expected User not to be null');
    }

    //Test  method for updateUser Method
    @isTest
    static void testUpdateUser(){
        User U = [Select Id,LastName From User Where LastName = 'TestPortal'];
        User updatedUserData = [SELECT Id, LastName FROM User WHERE Id = :U.Id];
        updatedUserData.LastName = 'TestPortalnew';

        // Call the updateUser method
        Test.startTest();
        ECOM_UserController.updateUser(updatedUserData);
        Test.stopTest();

        // Verify that the user's data has been updated
        User updatedUser = [SELECT LastName FROM User WHERE Id = :U.Id];
        System.assertEquals('TestPortalnew', updatedUser.LastName);
    }

    //Test  method for futureUpdateUserPassword Method
    @isTest
    static void testFutureUpdateUserPassword() {

        User U = [Select Id,LastName From User Where LastName = 'TestPortal'];

        // Create a test password string
        String testPassword = 'TestPassword123';

        // Call the updateUserPassword method
        Test.startTest();
        ECOM_UserController.updateUserPassword(testPassword);
        Test.stopTest();


    }

    //Test  method for getUserNavigationConfig Method
    @isTest
    static void testGetUserNavigationConfig(){
        User U = [Select Id,LastName,ECOM_Is_Test_User__c From User Where LastName = 'TestPortal'];
            String userType;
            if(U.ECOM_Is_Test_User__c){
                userType='storeTestUser';
            }
        // Call the getUserNavigationConfig method
        Test.startTest();
        Map<String,Object> result = ECOM_UserController.getUserNavigationConfig(userType);
        Test.stopTest();

        // Verifying the result
        System.assertEquals(true, result.get('success'));
    }

    //Test  method for getEncryptedParmeters Method
    @isTest
    static void testGetEncryptedParmeters(){
            String urlParams='userType';

        // Call the getEncryptedParmeters method
        Test.startTest();
        Map<String,Object> result = ECOM_UserController.getEncryptedParmeters(urlParams);
        Test.stopTest();

        // Verifying the result
        System.assertEquals(true, result.get('success'));
    }
    @isTest
    static void testGetEncyrptedSessionParametersForCMS(){
         String urlParams='userType';

        // Call the getEncryptedParmeters method
        Test.startTest();
        Map<String,Object> result = ECOM_UserController.getEncyrptedSessionParametersForCMS();
        Test.stopTest();

        // Verifying the result
        //System.assertEquals(true, result.get('success'));
    }

    @isTest
    static void getUserNavigationConfigTestFail(){
        Test.startTest();
        ECOM_UserController.getUserNavigationConfig(null);
        Test.stopTest();
    }

    @isTest
    static void getCMSRedirectDataMapTest(){
        Test.startTest();
        String encryptedCmsParams = ECOM_EncryptUtil.encryptWithAES256('testcmsString');
        String encryptedCmsLocale = ECOM_EncryptUtil.encryptWithAES256('testcmsLocale');
        String encryptedCmsRedirectTo = ECOM_EncryptUtil.encryptWithAES256('testcmsRedirectTo');
        ECOM_UserController.getCMSRedirectDataMap(encryptedCmsParams, encryptedCmsLocale, encryptedCmsRedirectTo);

        Test.stopTest();
    }

    @isTest
    static void getCmsRedirectMapForWebUserTest() {
        Test.startTest();
        ECOM_UserController.getCmsRedirectMapForWebUser();
        Test.stopTest();
    }

    @isTest
    static void testgetCountriesBannerMsgLoggedin() {
        User U = [Select Id,LastName From User Where LastName = 'TestPortal'];

        ECOM_CountryBasedBannerMsg__mdt bannerMsg = [SELECT DeveloperName FROM ECOM_CountryBasedBannerMsg__mdt WHERE DeveloperName != null LIMIT 1];

        System.runAs(U) {
            Test.startTest();
                ECOM_UserController.getCountriesBannerMsgLoggedin(new List<String>{bannerMsg.DeveloperName});
            Test.stopTest();
        }
    }

    /**
     * @description This test method is to test getOrganizationDetails method in ECOM_UserController class.
     * @author Sachin V | 2025.12.29 | RWPS-5436
     */
    @isTest
    static void testGetOrganizationDetails() {
        List<Organization> organizationDetailsList = new List<Organization>();
        Test.startTest();
        organizationDetailsList = ECOM_UserController.getOrganizationDetails();
        Test.stopTest();
        Assert.areEqual(false, organizationDetailsList.isEmpty(), 'Organization details should be fetched');
    }

    /**
     * @description This test method is to test getTestUserConfigurations method in ECOM_UserController class.
     * @author Sachin V | 2026.01.02 | RWPS-5436
     */
    @isTest
    static void testGetTestUserConfigurations() {
        Map<Object, Object> testUserConfigurationsMap = new Map<Object, Object>();
        Test.startTest();
        testUserConfigurationsMap = ECOM_UserController.getTestUserConfigurations();
        Test.stopTest();
        Assert.areEqual(false, testUserConfigurationsMap.isEmpty(), 'Test user configurations should be fetched');
    }
}