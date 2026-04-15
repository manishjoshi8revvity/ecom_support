/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*  ECOM-1028
*
* 2. Description - Test class for ECOM_PunchoutLoginController
*
* 3. Objects referenced
*    - WebStore
*    - Account
*    - Network
*    - CartItem

* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_TestUtil
*  	 - ECOM_PunchoutLoginController

* 6. Test Class Name:
*
* 7. Is @Invocable : No
*
* 8. Author Name(s):
*    - Vasudev 2023.09.19
*    - Kushal 2026.03.11 Added method testInsertPOSRRequestLog_Success, testInsertPOSRResponseLog_success and updated testGetPunchoutUserInformationByUserNameForLogin for code coverage - RWPS-5776
*/
@isTest
public class ECOM_PunchoutLoginController_Test {
    
    private final static String PASSWORD_CHARSET_ALPHABETS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    private final static String PASSWORD_CHARSET_NUMERIC = '0123456789';
    private final static String PASSWORD_CHARSET_ALPHANUMERIC = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
    private static final String CLASS_NAME = 'ECOM_PunchoutLoginController_Test';
    private static final String METHOD_NAME = 'TestAllMethods';
    private static final String MODULE_NAME = 'Test ECOM_ApplicationLogs';
    private static final String RESPONSE = 'RESPONSE';
    private static final String SUPPORT_DATA = 'suppport data';    
    
    public class ECOM_ApplicationLogsUtilException extends Exception{}

/*
* @description this method is used to create test data.
*/
    @TestSetup
    public static void testData(){
        //ECOM_TestUtil.testDataIntialSetup();
        //ECOM_TestUtil.initialStorefrontSetup();
        //ECOM_TestUtil.createPunchoutLoginData();
		
		Account acc = new Account();
        acc.Name = ECOM_TestUtil.REVVITY_ACCOUNT;
        acc.Type = 'Customer';
        acc.ShippingStreet = 'test';
        acc.ShippingCountry = 'United States';
        acc.ShippingState = 'Alabama';
        acc.ShippingPostalCode = '12345';
        acc.BillingStreet = 'test';
        acc.BillingCity = 'Cambridge';
        acc.BillingState = 'Alabama';
        acc.BillingCountry = 'United States';
        acc.CurrencyISOCode = 'USD';
		insert acc;
		Account newAccount = acc;
        
		 Contact con = new Contact();
        con.FirstName = 'test';
        con.LastName = 'Contact';
        con.Email = 'test@test.com';
        con.AccountId = acc.Id;
        con.MailingStreet = 'test';
        con.MailingCity = 'Norcross';
        con.MailingState = 'Alabama';
        con.MailingCountry = 'United States';
        con.MailingPostalCode = '123321';
        con.AccountId = acc.Id;
        con.ECOM_AddressRegistration__c = 'Select ST & BT';
        con.Phone = '1231234567';
        con.ECOM_Attention_Recipient__c ='';
        //con.Default_Ship_to_ERP_Address__c = '';
        //con.Default_Bill_to_ERP_Address__c = '';
        con.ECOM_NeedsVerification__c = false;
        con.ECOM_Is_Mapped__c = true; //RWPS-2683
        con.ECOM_CountryProvided__c = 'United States'; //RWPS-2683
		insert con;
		User portalUser = ECOM_TestUtil.createPortalUser(con);
        Contact newContact = con;
        Id erpDefaultRT = [SELECT Id FROM RecordType where SobjectType ='ERP_Address__c' AND DeveloperName='Default' LIMIT 1].Id;
        ERP_Address__c erpAddress = new ERP_Address__c();
        erpAddress.RecordTypeId = erpDefaultRT;
        erpAddress.Address_Street_Line_1__c = '8000 Regency Parkway';
        erpAddress.Address_City__c = 'Cary';
        erpaddress.Address_State__c = 'NC';
        erpAddress.Address_Country__c = 'US';
        erpAddress.Address_Postal_Code__c = '27518';

        erpAddress.CurrencyIsoCode = 'USD';
        erpAddress.Address_Type__c = 'Master';
        
        erpAddress.ECOM_Review_Status__c = 'Approved';
        erpAddress.ECOM_POSR_Sender_Shared_Identity__c = 'RVVTY';
        erpAddress.ECOM_POSR_Sender_Shared_Secret__c = 'SharedSecret';
        erpAddress.ECOM_Punchout_Account_TimeZone_SID__c = 'America/New_York';
        //erpAddress.ECOM_Punchout_Country_Locale__c = 'us-en';
        erpAddress.ECOM_Punchout_Customer_Id__c = 'RVTYPNCHOUT';
        erpAddress.ECOM_Punchout_Customer_Logo__c = '';
        erpAddress.ECOM_Punchout_Customer_Name__c = 'Revvity Punchout';
        erpAddress.ECOM_Punchout_Format__c = 'cXML';
        erpAddress.ECOM_Punchout_Is_Enabled__c = true;
        erpAddress.ECOM_Punchout_Processors__c = 'HazardousTrueFalse';
        erpAddress.ECOM_Punchout_Products_Include_Query__c = 'SHOW Product WHERE Radioactive = TRUE';
        erpAddress.ECOM_Punchout_Show_List_Price__c = true;
        erpAddress.ECOM_Punchout_Unit_Of_Measurement__c = 'EA';
        erpAddress.ECOM_isEnabled__c = true;
        erpAddress.External_Id__c = '123444444';
        erpAddress.SAP_Name_1__c = '11122333';
        erpAddress.CurrencyIsoCode = 'USD';
        erpAddress.ECOM_Punchout_Default_Payer__c = '123444444'; //RWPS-2830
        erpAddress.ECOM_Punchout_Sales_Org__c = 'US10';
        insert erpAddress;
		ERP_Address__c masterAddress = erpAddress;
        System.debug('---------- master external Id'+JSON.serializePretty(erpAddress));
       
        
		List<ERP_Address__c> newAddressList = new List<ERP_Address__c>();
        //ShipTo
        ERP_Address__c shipToAddress = new ERP_Address__c(Account__c = newAccount.Id, 
                                                          ECOM_Punchout_Is_Enabled__c=true,
                                                          ECOM_isEnabled__c=true,
                                                          ECOM_Review_Status__c = 'Approved', 
                                                          Address_Street_Line_1__c = masterAddress.Address_Street_Line_1__c,
                                                          Address_City__c = masterAddress.Address_City__c,
                                                          Address_State__c = masterAddress.Address_State__c,
                                                          Address_Country__c = masterAddress.Address_Country__c,
                                                          Address_Postal_Code__c = masterAddress.Address_Postal_Code__c,
                                                          Target_Address__c = masterAddress.Id,
                                                          Master_Address__c = masterAddress.Id,
                                                          Address_Type__c = 'Ship To',
                                                          RecordTypeId = erpDefaultRT,
                                                          ERP_Marked_for_Deletion__c = false,
                                                          ERP_Sales_Org__c = masterAddress.ECOM_Punchout_Sales_Org__c
                                                         );
        insert shipToAddress;
        newAddressList.add(shipToAddress);
        //SoldTo
        ERP_Address__c soldToAddress = new ERP_Address__c(Account__c = newAccount.Id, 
                                                          ECOM_Punchout_Is_Enabled__c=true,
                                                          ECOM_isEnabled__c=true,
                                                          ECOM_Review_Status__c = 'Approved',
                                                          Target_Address__c = masterAddress.Id,
                                                          Master_Address__c = masterAddress.Id,
                                                          Address_Type__c = 'Sold To',
                                                          RecordTypeId = erpDefaultRT,
                                                          ERP_Marked_for_Deletion__c = false,
                                                          ERP_Sales_Org__c = masterAddress.ECOM_Punchout_Sales_Org__c);
        insert soldToAddress;
        newAddressList.add(soldToAddress);
        
        //Payer
        ERP_Address__c payerToAddress = new ERP_Address__c(Account__c = newAccount.Id, 
                                                          ECOM_Punchout_Is_Enabled__c=true,
                                                          ECOM_isEnabled__c=true,
                                                          ECOM_Review_Status__c = 'Approved',
                                                          Target_Address__c = masterAddress.Id,
                                                          Master_Address__c = masterAddress.Id,
                                                          Address_Type__c = 'Payer',
                                                          RecordTypeId = erpDefaultRT,
                                                          ERP_Marked_for_Deletion__c = false,
                                                          ERP_Sales_Org__c = masterAddress.ECOM_Punchout_Sales_Org__c);
        insert payerToAddress;
        newAddressList.add(payerToAddress);
        ERP_Address__c rec = masterAddress;
        System.debug('JSON:: '+ JSON.serializePretty(newAddressList));
        Punchout_Maintenance__c maint = [SELECT ECOM_Punchout_Is_Enabled__c, ECOM_Punchout_Customer_Name__c, Default_Domain__c, ECOM_Punchout_Customer_Id__c, ECOM_Punchout_Account_TimeZone_SID__c,
                                         ECOM_Punchout_Show_List_Price__c, ECOM_POSR_Sender_Shared_Secret__c, ECOM_Punchout_Default_UNSPSC__c, 
                                         ECOM_POSR_Sender_Shared_Identity__c, ECOM_Punchout_Products_Include_Query__c, ECOM_Punchout_Products_Exclude_Query__c,
                                         ECOM_Punchout_Processors__c, ECOM_Punchout_Format__c, ECOM_Punchout_Unit_Of_Measurement__c, ECOM_Punchout_Default_Payer__c, 
                                         ECOM_Punchout_Customer_Logo__c, ECOM_Punchout_Sales_Org__c, ECOM_Punchout_Country_Locale__c, ECOM_isEnabled__c, Account__c,
                                         External_Id__c, ERP_Address__c, CurrencyIsoCode, Ecom_Punchout_Additional_Email_Address__c, ECOM_Punchout_User_Email__c
                                         FROM Punchout_Maintenance__c where External_Id__c = :masterAddress.External_Id__c LIMIT 1];
        
        //Punchout_Maintenance__c maint = new Punchout_Maintenance__c();
        maint.ECOM_Punchout_Is_Enabled__c = rec.ECOM_Punchout_Is_Enabled__c;
        maint.ECOM_Punchout_Customer_Name__c = rec.ECOM_Punchout_Customer_Name__c;
        maint.Default_Domain__c = rec.Default_Domain__c;
        maint.ECOM_Punchout_Customer_Id__c = rec.ECOM_Punchout_Customer_Id__c;
        maint.ECOM_Punchout_Account_TimeZone_SID__c = rec.ECOM_Punchout_Account_TimeZone_SID__c;
        maint.ECOM_Punchout_Show_List_Price__c = rec.ECOM_Punchout_Show_List_Price__c;
        maint.ECOM_POSR_Sender_Shared_Secret__c = rec.ECOM_POSR_Sender_Shared_Secret__c;
        maint.ECOM_Punchout_Default_UNSPSC__c= rec.ECOM_Punchout_Default_UNSPSC__c;
        maint.ECOM_POSR_Sender_Shared_Identity__c = rec.ECOM_POSR_Sender_Shared_Identity__c;
        maint.ECOM_Punchout_Products_Include_Query__c = rec.ECOM_Punchout_Products_Include_Query__c;
        maint.ECOM_Punchout_Products_Exclude_Query__c = rec.ECOM_Punchout_Products_Exclude_Query__c;
        maint.ECOM_Punchout_Processors__c = rec.ECOM_Punchout_Processors__c;
        maint.ECOM_Punchout_Format__c = rec.ECOM_Punchout_Format__c;
        maint.ECOM_Punchout_Unit_Of_Measurement__c = rec.ECOM_Punchout_Unit_Of_Measurement__c;
        maint.ECOM_Punchout_Default_Payer__c = rec.ECOM_Punchout_Default_Payer__c;
        maint.ECOM_Punchout_Customer_Logo__c = rec.ECOM_Punchout_Customer_Logo__c;
        maint.ECOM_Punchout_Sales_Org__c = rec.ECOM_Punchout_Sales_Org__c;
        maint.ECOM_Punchout_Country_Locale__c = rec.ECOM_Punchout_Country_Locale__c;
        maint.ECOM_isEnabled__c = rec.ECOM_isEnabled__c;
        maint.Account__c = newAccount.Id;
        maint.External_Id__c = rec.External_Id__c;
        maint.ERP_Address__c = rec.Id;
        maint.CurrencyIsoCode = rec.CurrencyIsoCode;
        maint.Ecom_Punchout_Additional_Email_Address__c = rec.Ecom_Punchout_Additional_Email_Address__c;
        maint.ECOM_Punchout_User_Email__c = rec.ECOM_Punchout_User_Email__c;
        upsert maint;
		Punchout_Maintenance__c pm = [SELECT Id, External_Id__c,ECOM_Punchout_Sales_Org__c,
                                      Account__c,ECOM_Punchout_Default_Payer__c,ECOM_isEnabled__c,ECOM_Punchout_Is_Enabled__c FROM Punchout_Maintenance__c where External_Id__c = :masterAddress.External_Id__c];
        System.debug('-------------------------- pm'+JSON.serializePretty(pm));
		
		
		
    }
    
    //Test Method to test punchoutLogin() Method
    
    /*@isTest
    static void testpunchoutLogin() {
       User usr= [Select Id from User ORDER BY CREATEDDATE DESC LIMIT 1];
        Account testAcc= [Select Id from Account ORDER BY CREATEDDATE DESC LIMIT 1];
        Contact testCon= [Select Id from Contact ORDER BY CREATEDDATE DESC LIMIT 1];
        ERP_Address__c testErp= [Select Id,Master_Address__c,ECOM_Review_Status__c from ERP_Address__c WHERE Address_Type__c='Payer' ORDER BY CREATEDDATE DESC LIMIT 1];
        
        ERP_Address__c testErp2= [Select Id,Account__c,Master_Address__c,ECOM_isEnabled__c,Address_Type__c,Address_City__c,Address_Street_Line_1__c,apiCountry__c,apiState__c,Address_Postal_Code__c,ECOM_Review_Status__c,fxIsECOMenabled__c,ECOM_Punchout_Is_Enabled__c,ECOM_Punchout_Customer_Id__c from ERP_Address__c WHERE Id=:testErp.Master_Address__c ORDER BY CREATEDDATE DESC LIMIT 1];
        
        //erpAddress.ECOM_Punchout_Is_Enabled__c=true;
        ERP_Address__c testErpApproved=ECOM_TestUtil.createNewApprovedAddress(testErp2,'Ship To');
        testErpApproved.Account__c=  testAcc.Id;
        testErpApproved.Contact__c=  testCon.Id;
        //update testErpApproved;
        //ERP_Address__c testErpMass=ECOM_TestUtil.createPunchoutMasterErpaddress();
        //ERP_Address__c testErp1=ECOM_TestUtil.createPunchoutErpaddress(testAcc,testCon, testErpMass);
        
        System.debug('testErpApproved______________'+testErpApproved.Account__c);  
        System.debug('testErpApproved______________'+testErpApproved.Id);  
        
        System.debug('testErp2______________'+testErp2.Account__c); 
        System.debug('testErpMass______________'+testErp2.fxIsECOMenabled__c);  
        
        System.runAs(usr){
            Test.startTest();
            PageReference returnPageRef = ECOM_PunchoutLoginController.punchoutLogin();
            //Validating the result    
            System.assertNotEquals(null, returnPageRef, 'The returnURL should not be empty');
            Test.stopTest();
        }

     
    }*/
    
    
    //Test Method to test getUserInformation Method
    @isTest
    static void testgetModelFromString() {
        User usr = [Select Id,UserName from User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(usr){
            Test.startTest();
            ECOM_PunchoutWrapper.PunchoutServiceRequest returnWrapper = ECOM_PunchoutLoginController.getModelFromString('firstName=Test&lastName=user&lang=EN');
            Test.stopTest(); 
            
            //Validating the result    
            System.assertEquals('user', returnWrapper.lastName, 'lastName should be user');

        }
    }
    
    @isTest
    static void getSalesOrgForCountry(){
        Test.startTest();
        ECOM_PunchoutLoginController.getSalesOrgForCountry('United States');
        ECOM_PunchoutUserCreation.getSalesOrgForCountry('United States');
        Map<String,String> params = new Map<String,String>();
        params.put('test','test');
        ECOM_PunchoutUserCreation.fetchValueForProperty(params,'test');
        Test.stopTest();
    }
    
    @isTest
    static void testGetPunchoutUserForUserName(){
        Account newAccount = [SELECT id, Name FROM Account WHERE Name = :ECOM_TestUtil.REVVITY_ACCOUNT LIMIT 1];
        Contact newContact = [SELECT Id, FirstName, LastName, Email FROM Contact WHERE accountId =: newAccount.Id LIMIT 1];
        User newUser = [SELECT Id, Firstname, LastName, Email, UserName FROM User WHERE contactId = :newContact.Id AND accountId =: newAccount.Id LIMIT 1];
        
        Test.startTest();
        ECOM_PunchoutLoginController.getPunchoutUserForUserName(newUser.Username);
        Test.stopTest();
    }
  

    @isTest
    static void testPunchoutLogin1(){
        //covwer normal user flow(user updated to punchout)
        //Create mock response headers
            Map<String, String> responseHeaders = new Map<String, String>();
            responseHeaders.put('Content-Type', 'application/json');
            Test.startTest();
            // Create mock HTTP response using Generic mock class ECOM_MockHttpResponseGenerator
            ECOM_MockHttpResponseGenerator mockResponse = new ECOM_MockHttpResponseGenerator(200, 'OK', '{"storefrontURL": "/login","USERNAME":"test@test.com","PASSWORD":"test@123","COOKIE":""}', responseHeaders);
            // Set the mock response for the HTTP callout
            Test.setMock(HttpCalloutMock.class, mockResponse);
            ECOM_PunchoutLoginController.punchoutLogin();
            Test.stopTest();
        //cover punchout flow
        //ECOM_PunchoutLoginController.punchoutLogin();
    }
       @isTest
    static void testPunchoutLogin2(){
        //covwer normal user flow(user updated to punchout)
        //Create mock response headers
            Map<String,Object> reqData = new Map<String,Object>();
            reqData.put('encryptedToken', '');
            Map<String, String> responseHeaders = new Map<String, String>();
            responseHeaders.put('Content-Type', 'application/json');
        	RestRequest req = new RestRequest(); 
           	RestResponse res = new RestResponse();
        
            req.requestURI = '/PunchoutUserCreation/';  
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueof(JSON.serialize(reqData));
            RestContext.request = req;
            RestContext.response= res;
            Test.startTest();
            // Create mock HTTP response using Generic mock class ECOM_MockHttpResponseGenerator
            ECOM_MockHttpResponseGenerator mockResponse = new ECOM_MockHttpResponseGenerator(200, 'OK', '{"storefrontURL": "/login","USERNAME":"test@test.com","PASSWORD":"test@123","COOKIE":""}', responseHeaders);
            // Set the mock response for the HTTP callout
            Test.setMock(HttpCalloutMock.class, mockResponse);
            ECOM_PunchoutUserCreation.validatePunchoutUser();
        	ECOM_PunchoutUserCreation.loginUserToSite('test@test.com','test@123','');
            Test.stopTest();
        //cover punchout flow
        //ECOM_PunchoutLoginController.punchoutLogin();
    }
    


     @isTest
    static void testGetEncryptedStoreUrl(){
        String userNameString = '%@noemail.com';
        User userRecord = [SELECT Id, Email FROM User WHERE UserName LIKE : userNameString LIMIT 1];
        
        userRecord = ECOM_PunchoutLoginController.getPunchoutUserInformationByUserNameForLogin(userRecord.Email);
        ECOM_PunchoutWrapper.PunchoutServiceRequest request = ECOM_TestUtil.createPOSRModelForRevvityPunchoutForExistingUser();
        ECOM_PunchoutLoginController.getEncryptedStoreUrl(ECOM_Constant.POTYPE_PUNCHOUT_USER, userRecord, 'TestLoginUrl', request, false);
        Map<String,String> paramMap = ECOM_PunchoutUserCreation.getEncryptedStoreUrl(ECOM_Constant.POTYPE_PUNCHOUT_USER, userRecord, 'TestLoginUrl', request, false);//NEW
    }
    
    @isTest
    static void testValidateAndCreateContact(){

        ECOM_PunchoutWrapper.PunchoutServiceRequest request = ECOM_TestUtil.createPOSRModelForRevvityPunchoutForExistingUser();
        request.userEmail = 'test@test.com';
        ERP_AddressModel addressModel = ERP_AddressUtil.getPunchoutAddressesForERPAddressModel('RVTYPNCHOUT');
        Test.startTest();
        ECOM_PunchoutLoginController.validateAndCreateContact(request, addressModel);
        Test.stopTest();
    }
	//commented
    /*@isTest
    static void testGetUserServiceInstance(){
        Test.startTest();
        ECOM_PunchoutLoginController.getCartServiceInstance();
        Test.stopTest();
    }*/

	@isTest
    static void testGetRequestModelForTestUser(){
        Test.startTest();
        ECOM_PunchoutLoginController.getRequestModelForTestUser();
        Test.stopTest();
    }
   
    @isTest
    static void testResetPassword(){
        User userRecord = [SELECT Id, FirstName, LastName, Email, UserName 
                           FROM User 
                           ORDER BY CREATEDDATE DESC
                           LIMIT 1];
        ECOM_MockHttpResponseGenerator mockResponse = new ECOM_MockHttpResponseGenerator(200, 'OK', '{"result": "success"}', new Map<String,String>());
        Test.setMock(HttpCalloutMock.class, mockResponse);
        Test.startTest();
        String resetPassword = ECOM_PunchoutLoginController.getNewPassword();
        ECOM_PunchoutLoginController.resetPassword(userRecord.Id, resetPassword);
        Test.stopTest();
    }
    
    @isTest 
    static void testGetPunchoutUserInformationByUserName(){
        User userRecord = [SELECT Id, FirstName, LastName, Email, UserName 
                           FROM User 
                           ORDER BY CREATEDDATE DESC 
                           LIMIT 1];
        
        Test.startTest();
        ECOM_PunchoutLoginController.getPunchoutUserInformationByUserName(userRecord.UserName);
        Test.stopTest();
    }
    
    @isTest
    static void testValidateTestUserForAccountId(){
        Account newAccount = [SELECT Id FROM Account WHERE Name = 'Test Revvity Account' LIMIT 1];
        System.debug('Account Id-----------'+JSON.serializePretty(newAccount));
        Id erpDefaultRT = [SELECT Id FROM RecordType where SobjectType ='ERP_Address__c' AND DeveloperName='Default' LIMIT 1].Id;
        ERP_Address__c erpAddress = new ERP_Address__c();
        erpAddress.RecordTypeId = erpDefaultRT;
        erpAddress.Address_Street_Line_1__c = '8000 Regency Parkway';
        erpAddress.Address_City__c = 'Cary';
        erpaddress.Address_State__c = 'NC';
        erpAddress.Address_Country__c = 'US';
        erpAddress.Address_Postal_Code__c = '27518';

        erpAddress.CurrencyIsoCode = 'USD';
        erpAddress.Address_Type__c = 'Master';
        
        erpAddress.ECOM_Review_Status__c = 'Approved';
        erpAddress.ECOM_POSR_Sender_Shared_Identity__c = 'RVVTY';
        erpAddress.ECOM_POSR_Sender_Shared_Secret__c = 'SharedSecret';
        erpAddress.ECOM_Punchout_Account_TimeZone_SID__c = 'America/New_York';
        //erpAddress.ECOM_Punchout_Country_Locale__c = 'us-en';
        erpAddress.ECOM_Punchout_Customer_Id__c = 'RVTYPNCHOUT';
        erpAddress.ECOM_Punchout_Customer_Logo__c = '';
        erpAddress.ECOM_Punchout_Customer_Name__c = 'Revvity Punchout';
        erpAddress.ECOM_Punchout_Format__c = 'cXML';
        erpAddress.ECOM_Punchout_Is_Enabled__c = true;
        erpAddress.ECOM_Punchout_Processors__c = 'HazardousTrueFalse';
        erpAddress.ECOM_Punchout_Products_Include_Query__c = 'SHOW Product WHERE Radioactive = TRUE';
        erpAddress.ECOM_Punchout_Show_List_Price__c = true;
        erpAddress.ECOM_Punchout_Unit_Of_Measurement__c = 'EA';
        erpAddress.ECOM_isEnabled__c = true;
        erpAddress.External_Id__c = '123444445';
        erpAddress.SAP_Name_1__c = '11122333';
        erpAddress.CurrencyIsoCode = 'USD';
        erpAddress.ECOM_Punchout_Default_Payer__c = '123444444'; //RWPS-2830
        erpAddress.ECOM_Punchout_Sales_Org__c = 'US10';
        insert erpAddress;
        /*Punchout_Maintenance__c pm = [SELECT Id, Account__c,ECOM_isEnabled__c,
                                      ECOM_Punchout_Default_Payer__c, ERP_Address__c,
                                      ECOM_Punchout_Is_Enabled__c FROM Punchout_Maintenance__c LIMIT 1];
        pm.Account__c = newAccount.Id;
        update pm;
        System.debug(JSON.serializePretty(pm));*/
        ERP_Address__c masterAddress = erpAddress;//[SELECT Id,External_Id__c,ECOM_Punchout_Sales_Org__c,ECOM_Punchout_Default_Payer__c FROM ERP_Address__c where Address_Type__c ='Master' AND ECOM_Punchout_Default_Payer__c='123444444' LIMIT 1];
        Punchout_Maintenance__c pm = [SELECT Id, External_Id__c,ECOM_Punchout_Sales_Org__c,
                                      Account__c,ECOM_Punchout_Default_Payer__c FROM Punchout_Maintenance__c LIMIT 1];
        pm.Account__c = newAccount.Id;
        pm.ECOM_Punchout_Sales_Org__c = masterAddress.ECOM_Punchout_Sales_Org__c;
        pm.ECOM_Punchout_Default_Payer__c = masterAddress.ECOM_Punchout_Default_Payer__c;
        pm.ECOM_isEnabled__c = true; 
        pm.ECOM_Punchout_Is_Enabled__c = true;
        pm.ERP_Address__c =masterAddress.Id;
        update pm;
         System.debug('-------------------------- pm'+JSON.serializePretty(pm));
        System.debug('--------------------------'+JSON.serializePretty( [SELECT Id, ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, Address_Type__c, MDM_Customer_Status__c, 
        Address_Street_Line_1__c, RecordType.Name, Address_Street_Line_2__c, Address_City__c, Address_State__c, Address_Country__c, 
        apiState__c, Address_Postal_Code__c, apiCountry__c, fxAddress_City__c,fxAddress_CountryCode__c, fxAddress_Postal__c, 
        fxAddress_StateName__c, fxAddress_Street__c, fxAddressFull__c, External_Id__c, CurrencyIsoCode,fxAddress_CountryName__c,
        ERP_Account_Group__c,ERP_Customer_Number__c, ERP_Sales_Org__c,ERP_Account_Name__c, ERP_Marked_for_Deletion__c, ERP_Partner_Code__c,
        Account__c, Account__r.Name, Account__r.CurrencyIsoCode,Contact__c,  
        ECOM_Punchout_Is_Enabled__c, ECOM_Punchout_Customer_Id__c, ECOM_Punchout_Customer_Logo__c, ECOM_Punchout_Customer_Name__c, 
        ECOM_Punchout_Products_Exclude_Query__c, ECOM_Punchout_Products_Include_Query__c, ECOM_Punchout_Show_List_Price__c, 
        ECOM_Punchout_Unit_Of_Measurement__c, ECOM_POSR_Sender_Shared_Identity__c, ECOM_POSR_Sender_Shared_Secret__c, ECOM_Punchout_Format__c,
        ECOM_Punchout_Account_TimeZone_SID__c, ECOM_Punchout_Processors__c, ECOM_Punchout_Country_Locale__c, 
        ECOM_Punchout_Default_UNSPSC__c ,ECOM_Punchout_Sales_Org__c,ECOM_Punchout_Default_Payer__c
        FROM ERP_Address__c
        WHERE ERP_Marked_for_Deletion__c = false 
        AND RecordType.DeveloperName = 'Default'
        AND ECOM_Review_Status__c = 'Approved'
        AND fxIsECOMenabled__c = true
        AND ((Address_Type__c IN ('Sold To','Ship To') AND Master_Address__r.External_Id__c = :masterAddress.External_Id__c AND Target_Address__r.External_Id__c =: masterAddress.External_Id__c AND ERP_Sales_Org__c = :masterAddress.ECOM_Punchout_Sales_Org__c)
        OR (Address_Type__c IN  ( 'Payer' ) AND Master_Address__r.External_Id__c =:masterAddress.External_Id__c AND Target_Address__r.External_Id__c =  :masterAddress.ECOM_Punchout_Default_Payer__c AND ERP_Sales_Org__c = :masterAddress.ECOM_Punchout_Sales_Org__c))
        LIMIT 49999 ]));
        Test.startTest();
        ECOM_PunchoutLoginController.validateTestUserForAccountId(newAccount.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testCalloutToLoginTestUser(){
        User userRecord = [SELECT Id, FirstName, LastName, Email, UserName 
                           FROM User 
                            ORDER BY CREATEDDATE DESC
                           LIMIT 1];
        Map<String,String> responseMap = new Map<String,String>();
        responseMap.put(ECOM_Constant.PARAM_STOREFRONT_URL, 'TestLoginUrl');
        ECOM_MockHttpResponseGenerator mockResponse = new ECOM_MockHttpResponseGenerator(200, 'OK', JSON.serialize(responseMap), new Map<String,String>());
        Test.setMock(HttpCalloutMock.class, mockResponse);
        Test.startTest();
        
        Map<String,Object> requestObjectMap = new Map<String,Object>();
        
        //List<User> userRecords = ECOM_PunchoutLoginController.getPunchoutUserInformationByUserName(userRecord.UserName);
        //userRecord = userRecords[0];
        requestObjectMap.put(ECOM_Constant.PARAM_USER_RECORD, JSON.serialize(userRecord));
        ECOM_PunchoutWrapper.PunchoutServiceRequest requestModel = ECOM_TestUtil.createPOSRModelForRevvityPunchoutForExistingUser();
        requestObjectMap.put(ECOM_Constant.PARAM_REQUEST_MODEL, JSON.serialize(requestModel));
        ECOM_PunchoutLoginController.calloutToLoginTestUser(requestObjectMap);
        Test.stopTest();
    }

    @isTest
    static void updateUserAsPunchoutUserTest(){
        List<User> userRecord = [SELECT Id,Email, ContactId FROM User ORDER BY CreatedDate DESC LIMIT 1];
        Test.startTest();
        ECOM_PunchoutLoginController.updateUserAsPunchoutUserOrContact(userRecord[0].Id, 'User');
        ECOM_PunchoutLoginController.loginUserToSite('test@test.com','test@123','');
        ECOM_PunchoutLoginController.validateContactAndContactAddress(userRecord[0], new ERP_AddressModel());
        Test.stopTest();
        
    }
    
    @isTest
    static void getParametersMap(){
        Test.startTest();
        ECOM_PunchoutLoginController.getParamsMap();
        Test.stopTest();
    }
    
    //test method for logFailure() method
    @isTest
    static void logFailureTest(){
        Test.startTest();
        try{
            throw new ECOM_ApplicationLogsUtilException();
        }catch(Exception e){
            ECOM_PunchoutLoginController.logFailure(e, MODULE_NAME, CLASS_NAME, METHOD_NAME, SUPPORT_DATA);
        }
        ECOM_PunchoutLoginController.logFailure(null, MODULE_NAME, CLASS_NAME, METHOD_NAME, SUPPORT_DATA);

        Test.stopTest();
        
    }
    
    @isTest
    public static void validateContactAndContactAddress(){
        Contact con = [SELECT Id, Email FROM Contact LIMIT 1];
        User user = [SELECT Id, Email, ContactId FROM User WHERE ContactId =: con.Id LIMIT 1];
        Test.startTest();         
        ERP_AddressModel addressModel = ERP_AddressUtil.getPunchoutAddressesForERPAddressModel('RVTYPNCHOUT');
		ECOM_PunchoutLoginController.validateContactAndContactAddress(user,addressModel);
        Test.stopTest();
    }
    
    @isTest
    public static void checkAndProvisionNewContactAndUser1(){
        Contact con = [SELECT Id, Email FROM Contact LIMIT 1];
        Test.startTest();         
        ECOM_PunchoutWrapper.PunchoutServiceRequest returnWrapper = ECOM_PunchoutLoginController.getModelFromString('firstName=Test&lastName=user&lang=EN');
		ECOM_PunchoutUserCreation.checkAndProvisionNewContactAndUser(returnWrapper);
        Test.stopTest();
    }
    @isTest
    public static void checkAndProvisionNewContactAndUser2(){
        Contact con = [SELECT Id, Email FROM Contact LIMIT 1];
        Test.startTest();         
        ECOM_PunchoutWrapper.PunchoutServiceRequest returnWrapper = ECOM_PunchoutUserCreation.getModelFromString('firstName=Test&lastName=user&lang=EN');
        Test.stopTest();
    }
    
    @isTest
    static void getSystemLimits(){
        Test.startTest();
        List<String> limits = ECOM_PunchoutLoginController.getSystemLimits();
        Test.stopTest();
    }
    
    @isTest
    static void getParamsMapTest(){
        Test.startTest();
        Map<String,String> response = ECOM_PunchoutLoginController.getParamsMap();
        ECOM_PunchoutLoginService.createPOSRModelForRevvityPunchoutForNewUser();
        ECOM_PunchoutLoginService.getProductSales('AL555s','US10');
        ECOM_PunchoutLoginService.decryptWithAES256('test');
        ECOM_PunchoutLoginService.getAccount(123456534);
        Map<String,ERP_Address__c> addressMap = ECOM_PunchoutLoginService.gePunchoutAddress('UTOR');
        ECOM_PunchoutLoginService.validatePunchoutPartnerFunctions(addressMap);
        Test.stopTest();
    }

    /** RWPS-3528 Start */
    @isTest
    public static void getSalesOrgForCountryNegativeTest() {
        String salesOrgRecieved;
        Test.startTest();
            salesOrgRecieved = ECOM_PunchoutUserCreation.getSalesOrgForCountry('Test');
        Test.stopTest();
        System.assert(salesOrgRecieved == null);
    }  

    @isTest
    public static void checkAndProvisionNewContactAndUser3(){
        Test.startTest();         
        ECOM_PunchoutWrapper.PunchoutServiceRequest returnWrapper = ECOM_PunchoutUserCreation.getModelFromString('firstName=Test&lastName=user&lang=EN&buyerCookie={test}&emailEncodingKey=test');
		ECOM_PunchoutUserCreation.checkAndProvisionNewContactAndUser(returnWrapper);
        Map<String,ERP_Address__c> addressMap = new Map<String,ERP_Address__c>();
        addressMap.put(ECOM_Constant.ERP_ADDRESS_TYPE_PAYER, null);
        addressMap.put(ECOM_Constant.ERP_ADDRESS_TYPE_MASTER, null);
        addressMap.put(ECOM_Constant.ERP_ADDRESS_TYPE_SHIP_TO, null);
        addressMap.put(ECOM_Constant.ERP_ADDRESS_TYPE_SOLD_TO, null);

        ECOM_PunchoutUserCreation.validateAndCreateContact1(returnWrapper, addressMap);
        Test.stopTest();
    }

    @isTest
    public static void checkAndProvisionNewContactAndUser4(){

        Test.startTest();         
        ECOM_PunchoutWrapper.PunchoutServiceRequest returnWrapper = ECOM_PunchoutUserCreation.getModelFromString('firstName=Test&lastName=user&lang=EN&buyerCookie={test}&emailEncodingKey=test');
		returnWrapper.userEmail = 'test@test.com';
        ECOM_PunchoutUserCreation.checkAndProvisionNewContactAndUser(returnWrapper);
        Map<String,ERP_Address__c> addressMap = new Map<String,ERP_Address__c>();
        ERP_Address__c master = [SELECT Id,ECOM_Punchout_Default_Payer__c FROM ERP_Address__c where Address_Type__c='Master' LIMIT 1];
        ERP_Address__c payer = [SELECT Id, Target_Address__c,Target_Address__r.External_Id__c FROM ERP_Address__c where Address_Type__c='Payer' AND Master_Address__c=:master.Id LIMIT 1];
        addressMap.put(ECOM_Constant.ERP_ADDRESS_TYPE_PAYER, payer);
        addressMap.put(ECOM_Constant.ERP_ADDRESS_TYPE_MASTER, master);
        addressMap.put(ECOM_Constant.ERP_ADDRESS_TYPE_SHIP_TO, null);
        addressMap.put(ECOM_Constant.ERP_ADDRESS_TYPE_SOLD_TO, null);
        ECOM_PunchoutUserCreation.validateAndCreateContact1(returnWrapper, addressMap);
        Test.stopTest();
    }

    @isTest
    public static void testEmptyEmailPunchoutLogin() {
         Account newAccount = [SELECT Id FROM Account WHERE Name = 'Test Revvity Account' LIMIT 1];
         ERP_Address__c erpAddress = [SELECT Id,External_Id__c,ECOM_Punchout_Sales_Org__c,ECOM_Punchout_Default_Payer__c FROM ERP_Address__c where Address_Type__c ='Master' LIMIT 1];
        Id erpDefaultRT = [SELECT Id FROM RecordType where SobjectType ='ERP_Address__c' AND DeveloperName='Default' LIMIT 1].Id;
        //ERP_Address__c erpAddress = new ERP_Address__c();
        erpAddress.RecordTypeId = erpDefaultRT;
        erpAddress.Address_Street_Line_1__c = '8000 Regency Parkway';
        erpAddress.Address_City__c = 'Cary';
        erpaddress.Address_State__c = 'NC';
        erpAddress.Address_Country__c = 'US';
        erpAddress.Address_Postal_Code__c = '27518';

        erpAddress.CurrencyIsoCode = 'USD';
        erpAddress.Address_Type__c = 'Master';
        
        erpAddress.ECOM_Review_Status__c = 'Approved';
        erpAddress.ECOM_POSR_Sender_Shared_Identity__c = 'RVVTY';
        erpAddress.ECOM_POSR_Sender_Shared_Secret__c = 'SharedSecret';
        erpAddress.ECOM_Punchout_Account_TimeZone_SID__c = 'America/New_York';
        //erpAddress.ECOM_Punchout_Country_Locale__c = 'us-en';
        erpAddress.ECOM_Punchout_Customer_Id__c = 'RVTYPNCHOUT';
        erpAddress.ECOM_Punchout_Customer_Logo__c = '';
        erpAddress.ECOM_Punchout_Customer_Name__c = 'Revvity Punchout';
        erpAddress.ECOM_Punchout_Format__c = 'cXML';
        erpAddress.ECOM_Punchout_Is_Enabled__c = true;
        erpAddress.ECOM_Punchout_Processors__c = 'HazardousTrueFalse';
        erpAddress.ECOM_Punchout_Products_Include_Query__c = 'SHOW Product WHERE Radioactive = TRUE';
        erpAddress.ECOM_Punchout_Show_List_Price__c = true;
        erpAddress.ECOM_Punchout_Unit_Of_Measurement__c = 'EA';
        erpAddress.ECOM_isEnabled__c = true;
        erpAddress.External_Id__c = '123444444';
        erpAddress.SAP_Name_1__c = '11122333';
        erpAddress.CurrencyIsoCode = 'USD';
        erpAddress.ECOM_Punchout_Default_Payer__c = '123444444'; //RWPS-2830
        erpAddress.ECOM_Punchout_Sales_Org__c = 'US10';
        update erpAddress;
        /*Punchout_Maintenance__c pm = [SELECT Id, Account__c,ECOM_isEnabled__c,
                                      ECOM_Punchout_Default_Payer__c, ERP_Address__c,
                                      ECOM_Punchout_Is_Enabled__c FROM Punchout_Maintenance__c LIMIT 1];
        pm.Account__c = newAccount.Id;
        update pm;
        System.debug(JSON.serializePretty(pm));*/
        ERP_Address__c masterAddress = erpAddress;//[SELECT Id,External_Id__c,ECOM_Punchout_Sales_Org__c,ECOM_Punchout_Default_Payer__c FROM ERP_Address__c where Address_Type__c ='Master' AND ECOM_Punchout_Default_Payer__c='123444444' LIMIT 1];
        Punchout_Maintenance__c pm = [SELECT Id, External_Id__c,ECOM_Punchout_Sales_Org__c,
                                      Account__c,ECOM_Punchout_Default_Payer__c FROM Punchout_Maintenance__c LIMIT 1];
        pm.Account__c = newAccount.Id;
        pm.External_Id__c = masterAddress.External_Id__c;
        pm.ECOM_Punchout_Sales_Org__c = masterAddress.ECOM_Punchout_Sales_Org__c;
        pm.ECOM_Punchout_Default_Payer__c = masterAddress.ECOM_Punchout_Default_Payer__c;
        pm.ECOM_isEnabled__c = true; 
        pm.ECOM_Punchout_Is_Enabled__c = true;
        pm.ERP_Address__c =masterAddress.Id;
        update pm;
         List<ERP_Address__c> newAddressList = new List<ERP_Address__c>();
        //ShipTo
        ERP_Address__c shipToAddress = new ERP_Address__c(Account__c = newAccount.Id, 
                                                          ECOM_Punchout_Is_Enabled__c=true,
                                                          ECOM_isEnabled__c=true,
                                                          ECOM_Review_Status__c = 'Approved', 
                                                          Address_Street_Line_1__c = masterAddress.Address_Street_Line_1__c,
                                                          Address_City__c = masterAddress.Address_City__c,
                                                          Address_State__c = masterAddress.Address_State__c,
                                                          Address_Country__c = masterAddress.Address_Country__c,
                                                          Address_Postal_Code__c = masterAddress.Address_Postal_Code__c,
                                                          Target_Address__c = masterAddress.Id,
                                                          Master_Address__c = masterAddress.Id,
                                                          Address_Type__c = 'Ship To',
                                                          RecordTypeId = erpDefaultRT,
                                                          ERP_Marked_for_Deletion__c = false,
                                                          ERP_Sales_Org__c = masterAddress.ECOM_Punchout_Sales_Org__c
                                                         );
        insert shipToAddress;
        //SoldTo
        ERP_Address__c soldToAddress = new ERP_Address__c(Account__c = newAccount.Id, 
                                                          ECOM_Punchout_Is_Enabled__c=true,
                                                          ECOM_isEnabled__c=true,
                                                          ECOM_Review_Status__c = 'Approved',
                                                          Target_Address__c = masterAddress.Id,
                                                          Master_Address__c = masterAddress.Id,
                                                          Address_Type__c = 'Sold To',
                                                          RecordTypeId = erpDefaultRT,
                                                          ERP_Marked_for_Deletion__c = false,
                                                          ERP_Sales_Org__c = masterAddress.ECOM_Punchout_Sales_Org__c);
        insert soldToAddress;
        //BillTo
        ERP_Address__c billToAddress = new ERP_Address__c(Account__c = newAccount.Id, 
                                                          ECOM_Punchout_Is_Enabled__c=true,
                                                          ECOM_isEnabled__c=true,
                                                          ECOM_Review_Status__c = 'Approved',
                                                          Target_Address__c = masterAddress.Id,
                                                          Master_Address__c = masterAddress.Id,
                                                          Address_Type__c = 'Bill To',
                                                          RecordTypeId = erpDefaultRT,
                                                          ERP_Marked_for_Deletion__c = false,
                                                          ERP_Sales_Org__c = masterAddress.ECOM_Punchout_Sales_Org__c);
        insert billToAddress;
        //Payer
        ERP_Address__c payerToAddress = new ERP_Address__c(Account__c = newAccount.Id, 
                                                          ECOM_Punchout_Is_Enabled__c=true,
                                                          ECOM_isEnabled__c=true,
                                                          ECOM_Review_Status__c = 'Approved',
                                                          Target_Address__c = masterAddress.Id,
                                                          Master_Address__c = masterAddress.Id,
                                                          Address_Type__c = 'Payer',
                                                          RecordTypeId = erpDefaultRT,
                                                          ERP_Marked_for_Deletion__c = false,
                                                          ERP_Sales_Org__c = masterAddress.ECOM_Punchout_Sales_Org__c);
        insert payerToAddress;
        Test.startTest();         
        ECOM_PunchoutWrapper.PunchoutServiceRequest returnWrapper = ECOM_PunchoutUserCreation.getModelFromString('firstName=Test&lastName=user&lang=EN&buyerCookie={test}&emailEncodingKey=test');
       	returnWrapper.userEmail = '';
        returnWrapper.fromCredentialIdentity = 'RVTYPNCHOUT';
        ECOM_PunchoutUserCreation.punchoutLogin(returnWrapper);
        Test.stopTest();
    }

    /*@isTest
    public static void testGetPunchoutUserInformationByUserNameForLogin() {
        Test.startTest();
            Contact contact = [SELECT Id, Email FROM Contact LIMIT 1];
            List<User> lstUser = [select id,username from user where contactId =: contact.Id];
            ECOM_PunchoutUserCreation.getPunchoutUserInformationByUserNameForLogin(lstUser[0].username);
            //RWPS-5776 Start
            Punchout_Maintenance__c punchoutconfig = [SELECT Id, ECOM_Punchout_Default_Payer__c FROM Punchout_Maintenance__c LIMIT 1];
            punchoutconfig.Default_Domain__c = 'test';
            update punchoutconfig;
            //RWPS-5776 End
            ECOM_PunchoutWrapper.PunchoutServiceRequest returnWrapper = ECOM_PunchoutUserCreation.getModelFromString('firstName=Test&lastName=user&lang=EN&buyerCookie={test}&emailEncodingKey=test');
            returnWrapper.userEmail = '';
            returnWrapper.fromCredentialIdentity = 'RVTYPNCHOUT';
            ECOM_PunchoutUserCreation.punchoutLogin(returnWrapper);
        Test.stopTest();
    }*/

    @isTest
    public static void testPunchoutLoginWithUserPresent() {
        Contact contact = [SELECT Id, Email FROM Contact LIMIT 1];
        List<User> lstUser = [select id,username from user where contactId =: contact.Id];

        Test.startTest();
            ECOM_PunchoutWrapper.PunchoutServiceRequest returnWrapper = ECOM_PunchoutUserCreation.getModelFromString('firstName=Test&lastName=user&lang=EN&buyerCookie={test}&emailEncodingKey=test');
            returnWrapper.userEmail = lstUser[0].username;
            returnWrapper.fromCredentialIdentity = 'RVTYPNCHOUT';
            ECOM_PunchoutUserCreation.punchoutLogin(returnWrapper);
        Test.stopTest();
    }

    @isTest
    public static void testPunchoutLoginWithUserPresentAndNoMasterERP() {
        Contact contact = [SELECT Id, Email FROM Contact LIMIT 1];
        List<User> lstUser = [select id,username from user where contactId =: contact.Id];

        Test.startTest();
            ECOM_PunchoutWrapper.PunchoutServiceRequest returnWrapper = ECOM_PunchoutUserCreation.getModelFromString('firstName=Test&lastName=user&lang=EN&buyerCookie={test}&emailEncodingKey=test');
            returnWrapper.userEmail = lstUser[0].username;
            returnWrapper.fromCredentialIdentity = 'TEST';
            ECOM_PunchoutUserCreation.punchoutLogin(returnWrapper);
        Test.stopTest();
    }
    /** RWPS-3528 End */

    //RWPS-5776 Start
    @isTest
    static void testInsertPOSRRequestLog_Success() {
        User logOwner = [SELECT Id, Username FROM User ORDER BY CreatedDate DESC LIMIT 1];
        ECOM_PunchoutWrapper.PunchoutServiceRequest req = ECOM_TestUtil.createPOSRModelForRevvityPunchoutForExistingUser();
        Test.startTest();
        ECOM_PunchoutLoginController.insertPOSRRequestLog(true, req, logOwner);
        Test.stopTest();
        ECOM_Application_Logs__c logRec = [
            SELECT Id, ECOM_Log_Type__c, ECOM_Account__c, OwnerId, SupportData__c,
                   ModuleName__c, ClassName__c, MethodName__c, ECOM_Log_Status__c, ExceptionRunningUser__c
            FROM ECOM_Application_Logs__c
            WHERE MethodName__c = 'insertPOSRRequestLog'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals(System.Label.ECOM_LogType_POSR_Request, logRec.ECOM_Log_Type__c, 'Log type should be POSR Request');
        System.assertEquals(logOwner.Id, logRec.OwnerId, 'Owner should be set to provided user');
        System.assertEquals('Punchout', logRec.ModuleName__c, 'Module name should be Punchout');
        System.assertEquals('ECOM_PunchoutLoginController', logRec.ClassName__c, 'Class name should match');
        System.assertEquals('insertPOSRRequestLog', logRec.MethodName__c, 'Method name should match');
        System.assertEquals('Success', logRec.ECOM_Log_Status__c, 'Status should be Success for true flag');
        System.assertNotEquals(null, logRec.SupportData__c, 'SupportData should store serialized request');
        System.assertEquals(UserInfo.getUserId(), logRec.ExceptionRunningUser__c, 'Running user should be stamped');
    }

    @isTest
    static void testInsertPOSRResponseLog_success() {
        User logOwner = [SELECT Id, Username, Email FROM User ORDER BY CreatedDate DESC LIMIT 1];
        String redirectUrl = '/storefront/login';
        String accountId = [SELECT Id FROM Account WHERE Name = :ECOM_TestUtil.REVVITY_ACCOUNT LIMIT 1].Id;
        Test.startTest();
        ECOM_PunchoutLoginController.insertPOSRResponseLog(true, redirectUrl, logOwner, null, accountId);
        Test.stopTest();
        ECOM_Application_Logs__c logRec = [
            SELECT Id, ECOM_Log_Status__c, OwnerId, SupportData__c
            FROM ECOM_Application_Logs__c
            WHERE MethodName__c = 'insertPOSRResponseLog'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals('Success', logRec.ECOM_Log_Status__c);
        System.assertEquals(logOwner.Id, logRec.OwnerId);
        Map<String,Object> supportMap =
            (Map<String,Object>)JSON.deserializeUntyped(logRec.SupportData__c);
        System.assertEquals(true,
            (Boolean)supportMap.get(ECOM_Constant.PARAM_PUNCHOUT_USER_LOGIN_SUCCESS));
    }
    //RWPS-5776 End
    
    @isTest
    static void testCreateNewPunchoutUser_Success() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
       
        Contact testContact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@test.com',
            AccountId = testAccount.Id
        );
        insert testContact;
       
        ECOM_PunchoutWrapper.PunchoutServiceRequest requestModel = new ECOM_PunchoutWrapper.PunchoutServiceRequest();
        requestModel.firstName = 'John';
        requestModel.lastName = 'Doe';
        requestModel.userEmail = 'john.doe@test.com';
        requestModel.locale = 'en_US';
       
        ERP_AddressModel addressModel = new ERP_AddressModel();
        addressModel.po_TimeZone = 'America/New_York';
        addressModel.po_CurrencyIsoCode = 'USD';
        addressModel.po_CountryCode = 'US';
       
        Test.startTest();
        Map<String, Object> result = ECOM_PunchoutLoginController.createNewPunchoutUser(
            requestModel,
            addressModel,
            testContact
        );
        Test.stopTest();
       
        System.assertNotEquals(null, result, 'Response map should not be null');
        System.assertEquals(true, result.containsKey(ECOM_Constant.PARAM_SUCCESS),
                          'Response should contain success key');
        System.assertEquals('john.doe@test.com', result.get(ECOM_Constant.PARAM_USER_NAME),
                          'Username should match email');
    }
    
     @isTest
    static void testGetERPMasterAddressForPunchoutAccountId() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        ERP_Address__c addr = new ERP_Address__c(
            Account__c = acc.Id,
            ERP_Marked_for_Deletion__c = false,
            ECOM_Review_Status__c = 'Approved',
            ECOM_Punchout_Is_Enabled__c = true
        );
        insert addr;
        Test.startTest();
        List<ERP_Address__c> result =
            ECOM_PunchoutLoginService.getERPMasterAddressForPunchoutAccountId(acc.Id);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }
 
    @isTest
    static void testGetPunchoutAddressesForERPMasterAddressId(){
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        ERP_Address__c masterAddr = new ERP_Address__c(
            Account__c = acc.Id,
            Address_Type__c = 'Master',
            ERP_Marked_for_Deletion__c = false,
            ECOM_Review_Status__c = 'Approved',
            ECOM_Punchout_Is_Enabled__c = true
        );
        insert masterAddr;
        ERP_Address__c payerAddr = new ERP_Address__c(
            Account__c = acc.Id,
            Address_Type__c = 'Payer',
            Master_Address__c = masterAddr.Id,
            ERP_Marked_for_Deletion__c = false,
            ECOM_Review_Status__c = 'Approved',
            ECOM_Punchout_Is_Enabled__c = true
        );
        insert payerAddr;
        Test.startTest();
        List<ERP_Address__c> result =
            ECOM_PunchoutLoginService.getPunchoutAddressesForERPMasterAddressId(masterAddr.Id);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testCreateNewPunchoutUser1() {
        Contact con = new Contact(LastName='TestContact', Email='testuser'+Math.random()+'@test.com');
        insert con;
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        Account masterAcc = new Account(Name='MasterAcc', CurrencyIsoCode='USD');
        insert masterAcc;
        Account shipAcc = new Account(Name='ShipAcc', CurrencyIsoCode='USD');
        insert shipAcc;
        ERP_Address__c master = new ERP_Address__c(Account__c = masterAcc.Id);
        insert master;
        ERP_Address__c shipTo = new ERP_Address__c(Account__c = shipAcc.Id);
        insert shipTo;
        ERP_Address__c payer = new ERP_Address__c();
        insert payer;
        ERP_Address__c soldTo = new ERP_Address__c();
        insert soldTo;
        Punchout_Maintenance__c configRec = new Punchout_Maintenance__c(ECOM_Punchout_Account_TimeZone_SID__c='America/Los_Angeles');
        insert configRec;

        Map<String,Object> addressMap = new Map<String,Object>{
            ECOM_Constant.ERP_ADDRESS_TYPE_MASTER => master,
            ECOM_Constant.ERP_ADDRESS_TYPE_SHIP_TO => shipTo,
            ECOM_Constant.ERP_ADDRESS_TYPE_PAYER => payer,
            ECOM_Constant.ERP_ADDRESS_TYPE_SOLD_TO => soldTo,
            ECOM_Constant.PUNCHOUT_CONFIG_REC => configRec
        };
        ECOM_PunchoutWrapper.PunchoutServiceRequest req = new ECOM_PunchoutWrapper.PunchoutServiceRequest();
        req.firstName = 'John';
        req.lastName = 'Doe'+Math.random();
        req.userEmail = 'john.doe'+Math.random()+'@test.com';
        req.locale = 'en_US';

        Test.startTest();
        Map<String,Object> response = ECOM_PunchoutUserCreation.createNewPunchoutUser1(req, addressMap, con);
        Test.stopTest();

        System.assert(response.containsKey(ECOM_Constant.PARAM_USER_RECORD));
        System.assert(response.containsKey(ECOM_Constant.PARAM_SUCCESS));
        System.assert(response.get(ECOM_Constant.PARAM_SUCCESS) instanceof Boolean);
    }

    @isTest
    static void testValidateAndCreateContact1_AllPaths() {
        Account payerAcc = new Account(Name='PayerAcc', CurrencyIsoCode='USD');
        insert payerAcc;
        Account shipAcc = new Account(Name='ShipAcc', CurrencyIsoCode='USD');
        insert shipAcc;
        Account masterAcc = new Account(Name='MasterAcc', CurrencyIsoCode='USD');
        insert masterAcc;
        ERP_Address__c master = new ERP_Address__c(Account__c=masterAcc.Id);
        insert master;
        ERP_Address__c shipTo = new ERP_Address__c(Account__c=shipAcc.Id);
        insert shipTo;
        ERP_Address__c payer = new ERP_Address__c(Account__c=payerAcc.Id);
        insert payer;
        ERP_Address__c soldTo = new ERP_Address__c();
        insert soldTo;
        Punchout_Maintenance__c configRec = new Punchout_Maintenance__c(ECOM_Punchout_Customer_Name__c='TestCustomer');
        insert configRec;
        Map<String,Object> addressMap = new Map<String,Object>{
            ECOM_Constant.ERP_ADDRESS_TYPE_MASTER => master,
            ECOM_Constant.ERP_ADDRESS_TYPE_SHIP_TO => shipTo,
            ECOM_Constant.ERP_ADDRESS_TYPE_PAYER => payer,
            ECOM_Constant.ERP_ADDRESS_TYPE_SOLD_TO => soldTo,
            ECOM_Constant.PUNCHOUT_CONFIG_REC => configRec,
            'ExtraKey' => 'ExtraValue'
        };

        Test.startTest();
        ECOM_PunchoutWrapper.PunchoutServiceRequest reqNew = new ECOM_PunchoutWrapper.PunchoutServiceRequest();
        reqNew.firstName = 'Alice';
        reqNew.lastName = 'Doe'+Math.random();
        reqNew.userEmail = 'alice.doe'+Math.random()+'@test.com';

        Map<String,Object> responseNew = ECOM_PunchoutUserCreation.validateAndCreateContact1(reqNew, addressMap);
        Contact createdContact = (Contact)responseNew.get(ECOM_Constant.PARAM_CONTACT_RECORD);
        System.assertEquals(reqNew.userEmail, createdContact.Email);
        System.assertEquals(true, responseNew.get(ECOM_Constant.PARAM_SUCCESS));
        System.assertEquals(true, createdContact.ECOM_Is_Punchout_Contact__c);
        Contact existingCon = new Contact(FirstName='Existing', LastName='Contact', Email='existing'+Math.random()+'@test.com');
        insert existingCon;

        ECOM_PunchoutWrapper.PunchoutServiceRequest reqExisting = new ECOM_PunchoutWrapper.PunchoutServiceRequest();
        reqExisting.firstName = 'Existing';
        reqExisting.lastName = 'Contact';
        reqExisting.userEmail = existingCon.Email;

        Map<String,Object> responseElse = ECOM_PunchoutUserCreation.validateAndCreateContact1(reqExisting, addressMap);
        Contact updatedCon = (Contact)responseElse.get(ECOM_Constant.PARAM_CONTACT_RECORD);
        System.assertEquals(shipTo.Account__c, updatedCon.AccountId);
        System.assertEquals(true, responseElse.get(ECOM_Constant.PARAM_SUCCESS));
        Test.stopTest();
    }
    
    @isTest
    static void testResetUserPassword(){
        List<User> userList = [SELECT Id, Email FROM User WHERE IsPortalEnabled = true LIMIT 1];
        String passwordResetProcess;
        if (userList.isEmpty() == false) {
            passwordResetProcess = ECOM_PunchoutUserCreation.resetUserPassword(userList[0].Id);
        }
        
    }
    
    @isTest
    static void testAssignPermissionSetToUser(){
           
            Account acc = ECOM_TestUtil.createAccount('TestClass Account');
            insert acc;
            
            BuyerAccount buyerAccount = new BuyerAccount(BuyerId = acc.Id, Name = 'TestClass Account', IsActive = true);
            insert buyerAccount;
            
            List<String> lstBuyerGroup = new List<String>();
            lstBuyerGroup.add('Revvity Buyer Group');
            List<BuyerGroup> retBgList = ECOM_TestUtil.prepareBuyerGroup(lstBuyerGroup);
            insert retBgList;
            
            List<BuyerGroupMember> bgmList = ECOM_TestUtil.createBuyerGroupMember(retBgList , new List<Account>{acc});
            insert bgmList;
        
            Contact con = new Contact();
            con.FirstName = 'test';
            con.LastName = 'Contact';
            con.Email = 'test1@test.com';
            con.AccountId = acc.Id;
            con.MailingStreet = 'test';
            con.MailingCity = 'Norcross';
            con.MailingState = 'Alabama';
            con.MailingCountry = 'United States';
            con.MailingPostalCode = '123321';
            con.AccountId = acc.Id;
            con.ECOM_AddressRegistration__c = 'Select ST & BT';
            con.Phone = '1231234567';
            con.ECOM_Attention_Recipient__c ='';
            con.ECOM_NeedsVerification__c = false;
            con.ECOM_Is_Mapped__c = true;
            con.ECOM_CountryProvided__c = 'United States';
            insert con;
        
        	User user;

            System.runAs(new User(Id=UserInfo.getUserId())) {
                user = ECOM_TestUtil.createUser(con,acc.Id);
                insert user;
            }
            
            ECOM_PunchoutUserCreation.assignPermissionSetToUser(user.Id);
    }
}