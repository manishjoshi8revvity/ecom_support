/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-2555
*
* 2. Description - This test class is for ECOM_CustomLoginController.
*
*
*
* 3. Objects referenced
*    -ECOM_Application_logs__c
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
*
* 5. Dependant Class(es):
*    - ECOM_LoginController
*
* 6. Test Class Name:
*
* 7. Is @Invocable: No
*
* 8. Author Name(s):
*    - Vasudev 2024.04.29
*    - Abhishek Joshi 2026.01.13 - Added methods calloutToLoginAndGetRedirectUrlTestError, generateLoginUrlTest and loginUserToSiteLWC_Success_Test and modified method fetchStorefrontConfigByModuleTest - RWPS-3415
*    - Sachin V 2026.03.16 - Added method : processSecureAccessWithValidLinkTest, processSecureAccessWithInvalidLinkTest, processSecureAccessWithInvalidEmailTest - RWPS-5938
*************************************************************/
@isTest
public class ECOM_CustomLoginController_Test {

    /**
     * description Test Data setup
     */
    @TestSetup
    public static void testData(){
        ECOM_TestUtil.testDataIntialSetup();
    }

    @isTest
    static void loginUserTest(){
        Test.startTest();
        	ECOM_CustomLoginController.loginUser('username', 'password', 'returl');
        Test.stopTest();
    }

    @isTest
    static void validateUserCredentialsTest() {
        List<User> usersList = [SELECT Id, UserName from User Order By CreatedDate DESC LIMIT 1];
        System.debug('usersList:: '+ JSON.serialize(usersList));

        if(usersList != null && !usersList.isEmpty()) {

            User userRecord = usersList[0];

            Test.startTest();
            ECOM_CustomLoginController.validateUserCredentials(userRecord.userName);
            ECOM_CustomLoginController.validateUserCredentials('userName');
            Test.stopTest();


        }
    }

    @isTest
    static void calloutToLoginAndGetRedirectUrlTest() {
        List<User> usersList = [SELECT Id, UserName from User Order By CreatedDate DESC LIMIT 1];
        System.debug('usersList:: '+ JSON.serialize(usersList));

        if(usersList != null && !usersList.isEmpty()) {

            User userRecord = usersList[0];

            Test.startTest();

            String successResponseBody = '{"status": "success"}';
            Test.setMock(HttpCalloutMock.class, new ECOM_MockHttpResponseGenerator(200, 'OK', successResponseBody, null));

            ECOM_CustomLoginController.calloutToLoginAndGetRedirectUrl('username', 'password', 'returl', userRecord);
            Test.stopTest();
        }
    }

    /**
     * RWPS-3415
     * @description Tests for calloutToLoginAndGetRedirectUrl covering success and failure paths
     * @author Abhishek Joshi 2026.01.13
     */
    @isTest
    static void calloutToLoginAndGetRedirectUrlTestError() {
        List<User> usersList = [SELECT Id, UserName from User Order By CreatedDate DESC LIMIT 1];
        System.debug('usersList:: '+ JSON.serialize(usersList));

        if(usersList != null && !usersList.isEmpty()) {

            User userRecord = usersList[0];

            Test.startTest();

            String successResponseBody = '{"status": "failure"}';
            Test.setMock(HttpCalloutMock.class, new ECOM_MockHttpResponseGenerator(404, 'Not Found', successResponseBody, null));

            ECOM_CustomLoginController.calloutToLoginAndGetRedirectUrl('username', 'password', 'returl', userRecord);
            Test.stopTest();
        }
    }

    @isTest
    static void prepareHttpRequestForQueryParameterTest() {
        Test.startTest();


        ECOM_CustomLoginController.prepareHttpRequestForQueryParameter('endpoint', 'encryptedToken', 'encryptedCode', 'retUrl');
        Test.stopTest();
    }

    @isTest
    static void getCMSUrlTest(){
        Test.startTest();

        ECOM_CustomLoginController.getCMSUrl();
        Test.stopTest();
    }

    //Added Jul 18
    @isTest
    static void getValueFromMapTest(){
        Map<String, String> testMap = new Map<String, String>{'key' => 'value'};

		Test.startTest();
        ECOM_CustomLoginController.getValueFromMap(testMap, 'key');
        Test.stopTest();
    }

    @isTest
    static void decryptWithAES256Test(){
        String encryptedString = ECOM_CustomLoginController.encryptWithAES256('TestString');
        Test.startTest();
        ECOM_CustomLoginController.decryptWithAES256(encryptedString);
        Test.stopTest();

    }

    @isTest
    static void fetchConfigByValueTest(){
        Test.startTest();
        ECOM_CustomLoginController.fetchConfigByValue(ECOM_Constant.SECRET_KEY);
        Test.stopTest();
    }

    @isTest
    static void encryptWithAES256Test(){
        Test.startTest();
        ECOM_CustomLoginController.encryptWithAES256('Test');
        Test.stopTest();
    }

    @isTest
    static void getStoreNavigationConfigMapTest(){
        Test.startTest();
        ECOM_CustomLoginController.getStoreNavigationConfigMap('UserTypeNavConfiguration', 'punchoutUser');
        Test.stopTest();
    }


    @isTest
    static void getStoreForwardingUrlTest(){
        User userRecord;
        List<User> users = [SELECT Id,LocaleSidKey, Email, userName FROM User Order By CreatedDate DESC LIMIT 1];

        if(users != null && !users.isEmpty()){
            Test.startTest();
            ECOM_CustomLoginController.getStoreForwardingUrl(users[0], 'google');
            ECOM_CustomLoginController.loginUserToSite(users[0].userName , 'password', 'storeForwardingUrl');
            new ECOM_CustomLoginController().getReturnURL();
            Test.stopTest();
        }

    }

    @isTest
    static void getUsersByUsernameTest(){
        Test.startTest();
        ECOM_CustomLoginController.getUsersByUsername('');
        Test.stopTest();
    }

    /**
     * RWPS-4881
     * @description Test method to verify the method 'mapRequestValues' from 'ECOM_CustomLoginController'
     * @author Sachin Vispute 2025.11.06
     */
    @isTest
    private static void mapRequestValuesTest() {
        Map<String, String> requestMap = new Map<String, String>();
        requestMap.put('Method Type', 'GET');
        requestMap.put('requestEndPoint', 'test@test.com');
        requestMap.put('requestBody', 'testBody');
        requestMap.put('test', 'testBody');
        HttpRequest request = new HttpRequest();
        Test.startTest();
        request = ECOM_CustomLoginController.mapRequestValues(requestMap);
        Test.stopTest();
        System.assertEquals(true, request != null);
    }

    /**
     * RWPS-4881
     * @description Test method to verify the method 'getOrganizationId' from 'ECOM_CustomLoginController'
     * @author Sachin Vispute 2025.11.06
     */
    @isTest
    private static void getOrganizationIdTest() {
        System.assertEquals(true, String.isNotBlank(ECOM_CustomLoginController.getOrganizationId()));
    }

    /**
     * RWPS-4881
     * @description Test method to verify the method 'fetchStorefrontConfigByModule' from 'ECOM_CustomLoginController'
     * @author Sachin Vispute 2025.11.06
     */
    @isTest
    private static void fetchStorefrontConfigByModuleTest() {
        Map<String, Object> mapModuleConstants = new Map<String, Object>();
        Test.startTest();
        mapModuleConstants = ECOM_CustomLoginController.fetchStorefrontConfigByModule('ECOMInvoiceCase');
        Test.stopTest();
        System.assertEquals(true, mapModuleConstants != null);
    }

    /**
     * RWPS-3415
     * @description Generate login URL
     * @author Abhishek Joshi 2026.01.13
     */
    @isTest
    private static void generateLoginUrlTest() {
        ECOM_CustomLoginController.generateLoginUrl('unknown@unknown.com','asfasef','',null);
    }

    /**
     * RWPS-3415
     * @description Tests for loginUserToSiteLWC covering success and failure paths
     * @author Abhishek Joshi 2026.01.13
     */
    @isTest
    private static void loginUserToSiteLWC_Success_Test() {
        User u = [SELECT Id, Username, Email, LocaleSidKey FROM User ORDER BY CreatedDate DESC LIMIT 1];

        String storeForwardingUrl = '/s/forward?x=y';

        Test.startTest();

        Map<String, Object> result = ECOM_CustomLoginController.loginUserToSiteLWC(u, 'password', storeForwardingUrl);
        Test.stopTest();
    }

    /**
     * RWPS-5938
     * @description This is test method to verify the processSecureAccessLink for valid parameters
     */
    @IsTest
    private static void processSecureAccessWithValidLinkTest() {
        List<User> userList = [SELECT Id, Email FROM User WHERE ECOM_Is_Punchout_User__c = TRUE ORDER BY CreatedDate DESC LIMIT 1];
        System.debug('userList:: ' + userList);
        if (userList.isEmpty() == false) {
            String email = userList[0].Email;
            Test.startTest();
            String body = '{"access_token":"Testing-ABC99X2MqYh","sfdc_community_url":"https://test.com","sfdc_community_id":"Test001","scope":"web openid api","instance_url":"https://test.com","id":"https://test.salesforce.com/id/Test","token_type":"Bearer"}';
            ECOM_MockHttpResponseGenerator mockResponse = new ECOM_MockHttpResponseGenerator(200, 'OK', body, new Map<String,String>());
        	Test.setMock(HttpCalloutMock.class, mockResponse);
            Map<String, Object> response = ECOM_CustomLoginController.processSecureAccessLink('quote123', email);
            Test.stopTest();
            System.debug('Response from processSecureAccessLinkTest: ' + response);
        }
    }

    /**
     * RWPS-5938
     * @description This is test method to verify the processSecureAccessLink for invalid parameters
     */
    @IsTest
    private static void processSecureAccessWithInvalidLinkTest() {
        List<User> userList = [SELECT Id, Email FROM User WHERE ECOM_Is_Punchout_User__c = TRUE ORDER BY CreatedDate DESC LIMIT 1];
        System.debug('userList:: ' + userList);
        if (userList.isEmpty() == false) {
            String email = userList[0].Email;
            Test.startTest();
            String body = '{"sfdc_community_url":"https://test.com","sfdc_community_id":"Test001","scope":"web openid api","instance_url":"https://test.com","id":"https://test.salesforce.com/id/Test","token_type":"Bearer"}';
            ECOM_MockHttpResponseGenerator mockResponse = new ECOM_MockHttpResponseGenerator(200, 'OK', body, new Map<String,String>());
        	Test.setMock(HttpCalloutMock.class, mockResponse);
            Map<String, Object> response = ECOM_CustomLoginController.processSecureAccessLink('quote123', email);
            Test.stopTest();
            System.debug('Response from processSecureAccessLinkTest: ' + response);
        }
    }

    /**
     * RWPS-5938
     * @description This is test method to verify the processSecureAccessLink for invalid Email
     */
    @IsTest
    private static void processSecureAccessWithInvalidEmailTest() {
        String email = 'Test@test.com';
        Test.startTest();
        String body = '{"sfdc_community_url":"https://test.com","sfdc_community_id":"Test001","scope":"web openid api","instance_url":"https://test.com","id":"https://test.salesforce.com/id/Test","token_type":"Bearer"}';
        ECOM_MockHttpResponseGenerator mockResponse = new ECOM_MockHttpResponseGenerator(200, 'OK', body, new Map<String,String>());
        Test.setMock(HttpCalloutMock.class, mockResponse);
        Map<String, Object> response = ECOM_CustomLoginController.processSecureAccessLink('quote123', email);
        Test.stopTest();
        System.debug('Response from processSecureAccessLinkTest: ' + response);
    }
}