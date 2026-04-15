/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-69  
*
* 2. Description - This test class is for ECOM_LoginController.
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
*    - Vipul 2023.08.11

*************************************************************/
@IsTest
public with sharing class ECOM_LoginController_Test {
    
    /**
* @description this method is used to create test data.
*/
    @TestSetup
    public static void testData(){
        ECOM_TestUtil.testDataIntialSetup();
    }
    
   /* @isTest
    public static void testGetReturnURL(){
        Test.startTest();
        User u = [SELECT Id, Username, Email FROM User WHERE Lastname = 'TestPortal' LIMIT 1];
     
        
        Map<String, String> mapPageParams = new Map<String, String>();
        String strEncryptedToken = ECOM_EncryptUtil.encryptWithAES256(u.Username);
        String strEncryptedCode = ECOM_EncryptUtil.encryptWithAES256('Test@Password123');
        
        PageReference pageRef = new PageReference('/apex/ECOM_LoginPage');
        pageRef.setRedirect(true);
        pageRef.getParameters().put('encryptedToken',strEncryptedToken);
        pageRef.getParameters().put('encryptedCode',strEncryptedCode);
        pageRef.getParameters().put('storefrontPath','%2Fcart');
        pageRef.getParameters().put('locale', 'en_US');
        pageRef.getParameters().put('currencyCode', 'USD');
        pageRef.getParameters().put('countryCode', 'US');
        ECOM_LoginController lgnc = new ECOM_LoginController();
        String returnURL = lgnc.getReturnURL();
        Test.stopTest();
    }*/
    
    /*@IsTest
static void testGetReturnURL1() {    
// Create test data
Account testAccount = new Account(Name = 'Test Account2315');
insert testAccount;
Contact testContact = new Contact(LastName = 'Test Contact2315', AccountId = testAccount.Id);
insert testContact;
String profileName = 'PROFILE: ECOM Community User';
List<Profile> prf1 = [Select Id FROM Profile WHERE Name = :profileName];
Profile prof;
if(!prf1.isEmpty()){
prof = prf1[0];
}else{
System.assert(false,'profile not added:'+profileName);
}
User testUser = new User(Username = 'tinku3245@yopmail.com', Email = 'tinku3245@yopmail.com',
FirstName = 'Tes4511', LastName = 'Us54r', ContactId = testContact.Id,
Alias = 'testyr11', TimeZoneSidKey = 'America/Los_Angeles', LocaleSidKey = 'en_US',
EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', ProfileId= prof.Id, IsActive = true);
// Cart testWebCart = new Cart(Account__c = testAccount.Id, Contact__c = testContact.Id, User__c = testUser.Id);
Test.startTest();
ECOM_LoginController lgnc = new ECOM_LoginController();
String returnURL = lgnc.getReturnURL();
Test.stopTest();
*/
    /* // Simulate page parameters with encrypted token and code (for example purposes)
Map<String, String> ecomParams = new Map<String, String>();
ecomParams.put('encryptedToken', 'test_encrypted_token');
ecomParams.put('encryptedCode', 'test_encrypted_code');
Test.setCurrentPageParameters(ecomParams);

// Start the test
Test.startTest();

// Calling the method
returnURL = lgnc .getReturnURL();

// Validating the response
ECOM_LoginController.ECOM_LoginWrapper.acls_LoginResponse resp = (ECOM_LoginController.ECOM_LoginWrapper.acls_LoginResponse)JSON.deserialize(returnURL, ECOM_LoginController.ECOM_LoginWrapper.acls_LoginResponse.class);
System.assertEquals(true, resp.success, 'Login should be successful with valid credentials.');

Test.stopTest();*/
    //} 
    
    @isTest
    static void testGetDefaultStoreFrontPath() {
        // Create a test Contact
        Contact testContact = new Contact(
            ECOM_AddressRegistration__c = 'Populate ST & BT'
        );
        
        // Call the getDefaultStoreFrontPath method
        Test.startTest();
        Map<String, Object> result = ECOM_LoginController.getDefaultStoreFrontPath(testContact);
        Test.stopTest();
        
        // Perform assertions to validate the results
        System.assertEquals('/dashboard', result.get('defaultPathForAddressRegistration'), 'Expected default path to be "/dashboard"');
        System.assertEquals('addressStatus=addAddress', result.get('addressAction'), 'Expected address action to be "addressStatus=addAddress"');
    }
    
    
    @isTest
    static void testGetUsersByUsername() {
        
        User testUser =   [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        
        // Call the getUsersByUsername method
        Test.startTest();
        List<User> result = ECOM_LoginController.getUsersByUsername('testuser'); 
        Test.stopTest();
        System.assertnotEquals(null,result,'expected order should not be null');
    }
    
    @isTest
    static void testPopulateUserValues() {
        
        User testUser =   [Select Id,LastName,FirstName,Email From User ORDER BY CREATEDDATE DESC LIMIT 1];
        
        // Create a test ECOM_LoginWrapper.LoginResponse
        ECOM_LoginWrapper.LoginResponse testResponse = new ECOM_LoginWrapper.LoginResponse();
        testResponse.userFirstName = 'PlaceholderFirstName';
        testResponse.userLastName = 'PlaceholderLastName';
        testResponse.userId = 'PlaceholderUserId';
        testResponse.userEmail = 'placeholder@example.com';
        testResponse.isMappedAccount = false; // Set as needed
        
        // Call the populateUserValues method
        ECOM_LoginWrapper.LoginResponse result = ECOM_LoginController.populateUserValues(testUser, testResponse);
        
        // Perform assertions to validate the results
        System.assertEquals(testUser.FirstName, result.userFirstName, 'Expected userFirstName to match the test User FirstName');
        System.assertEquals(testUser.LastName, result.userLastName, 'Expected userLastName to match the test User LastName');
        System.assertEquals(testUser.Id, result.userId, 'Expected userId to match the test User Id');
        System.assertEquals(testUser.Email, result.userEmail, 'Expected userEmail to match the test User Email');
        
    }
    
    
    @isTest
    static void testGetLoginResponse() {
        User testUser =  [Select Id,LastName,FirstName,Email,Username From User ORDER BY CREATEDDATE DESC LIMIT 1];
        
        // Create a test ECOM_LoginWrapper.LoginResponse
        ECOM_LoginWrapper.LoginResponse testResponse = new ECOM_LoginWrapper.LoginResponse();
        
        // Call the getLoginResponse method with populateUserInfo set to true
        Test.startTest();
        ECOM_LoginWrapper.LoginResponse result = ECOM_LoginController.getLoginResponse(testUser.Username, true, 'testPageURL');
        Test.stopTest();
        
        // Perform assertions to validate the results
        System.assertEquals(testUser.FirstName, result.userFirstName, 'Expected userFirstName to match the test User FirstName');
        System.assertEquals(testUser.LastName, result.userLastName, 'Expected userLastName to match the test User LastName');
        System.assertEquals(testUser.Id, result.userId, 'Expected userId to match the test User Id');
        System.assertEquals(testUser.Email, result.userEmail, 'Expected userEmail to match the test User Email');
    }
    
    
    @isTest
    static void testGetContactBasedOnId() {
        
        Contact testContact = [SELECT Id,FirstName,LastName,Email FROM Contact ORDER BY CREATEDDATE DESC LIMIT 1];
        
        // Call the getContactBasedOnId method
        Test.startTest();
        Contact result = ECOM_LoginController.getContactBasedOnId(testContact.Id);
        Test.stopTest();
        
        // Perform assertions to validate the results
        System.assertEquals(testContact.FirstName, result.FirstName, 'Expected FirstName to match the test Contact FirstName');
        System.assertEquals(testContact.LastName, result.LastName, 'Expected LastName to match the test Contact LastName');
        System.assertEquals(testContact.Email, result.Email, 'Expected Email to match the test Contact Email');
        
    }
    
    
    @isTest
    static void testGetStrDefaultCartPath() {
        // Create a map with test values
        Map<String, String> valueMap = new Map<String, String>();
        valueMap.put('sourceURL', '/example/sourceURL');
        valueMap.put('storefrontPath', '/example/storefrontPath');
        
        // Call the getStrDefaultCartPath method
        Test.startTest();
        String result = ECOM_LoginController.getStrDefaultCartPath(valueMap);
        valueMap.remove('sourceURL');
        String result2 = ECOM_LoginController.getStrDefaultCartPath(valueMap);
        
        Test.stopTest();
        
        // Perform assertions to validate the results
        System.assertEquals('/demo/po-redirection?sourceURL=/example/sourceURL', result, 'Expected result for sourceURL');
    }
    
    
    
    
    
    @isTest
    static void testDecryptWithAES256() {
        // Define your test data
        String encryptedText = 'YourEncryptedText'; // Replace with the actual encrypted text
        String secretKey = 'YourSecretKey'; // Replace with the actual secret key
        String initializationVector = 'YourInitializationVector'; // Replace with the actual initialization vector
        
        // Call the decryptWithAES256 method
        Test.startTest();
        String decryptedString = ECOM_LoginController.decryptWithAES256(encryptedText);
        Test.stopTest();
        
        // Perform assertions to validate the results
        //System.assertEquals('ExpectedDecryptedString', decryptedString, 'Decryption failed');
        
        
    }
    
  
    @isTest
    static void testGetReturnURL() {
        User testUser = [Select Id,LastName,FirstName,Email,Username From User ORDER BY CREATEDDATE DESC LIMIT 1];

        Contact testContact = [SELECT Id,FirstName,LastName,Email FROM Contact ORDER BY CREATEDDATE DESC LIMIT 1];
		String username = testUser.UserName;
        // Instantiate the controller class
        ECOM_LoginController controller = new ECOM_LoginController();

        // Create a test page parameters map
        Map<String, String> testPageParams = new Map<String, String>();
        testPageParams.put('ENCRYPTED_TOKEN', username);

       System.runAs(testUser)
       {
        Test.startTest();
        String returnURL = controller.getReturnURL();
        System.assertNotEquals('', returnURL, 'The returnURL should not be empty');
        Test.stopTest();
       }

     
    }
    
    
     @isTest
    static void testUserLogin() {
        // Create test data or parameters that you want to pass to the method
        Map<String, String> mapPageParams = new Map<String, String>();
        mapPageParams.put('defaultPathForAddressRegistration', 'test-address-registration');
        mapPageParams.put('addressAction', 'test-address-action');
        mapPageParams.put('encryptedToken','TESTENCRYPTED_TOKEN');
        mapPageParams.put('encryptedCode','TestENCRYPTED_CODE');

        // Set up the test environment
        Test.startTest();

        // Instantiate the class that contains the userLogin method
        ECOM_LoginController Instance = new ECOM_LoginController();

        // Call the userLogin method with your test parameters
        String returnURL = Instance.userLogin(mapPageParams);
        Map<String,String> nullMap  =new Map<String,String>();
        String returnNullURL = Instance.userLogin(nullMap);

        // Assert the behavior of the method
        System.assertNotEquals(null, returnURL);
        // Add more specific assertions as needed based on your code

        Test.stopTest();
    }
    @isTest
    static void testGetValueFromMap() {
        Map<String, String> testMap = new Map<String, String>();
        testMap.put('key1', 'Test Value 1');
        testMap.put('key2', null);
        String result1 = ECOM_LoginController.getValueFromMap(testMap, 'key1');
        System.assertEquals('Test Value 1', result1);
        String result2 = ECOM_LoginController.getValueFromMap(testMap, 'key2');
        System.assertEquals('', result2); // Expecting an empty string

        // Test when the key doesn't exist in the map
        String result3 = ECOM_LoginController.getValueFromMap(testMap, 'nonexistentKey');
        System.assertEquals('', result3); 
    }
    
    @isTest
    public static void encryptDataTest() {
        Test.startTest();
        ECOM_LoginWrapper.EncryptionRequest requestBody = new ECOM_LoginWrapper.EncryptionRequest();
        requestBody.userName = 'Testencrypt@testenc.com';
        requestBody.password = 'password';
        ECOM_EncryptUtil.encryptData(requestBody);
        Test.stopTest();
    }
}