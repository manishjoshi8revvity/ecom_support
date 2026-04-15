/**************************************************************

	* 1. Jira Ticket(s) that relates to this class
	*  
	*
	* 2. Description - This class is a test class for ECOM_ContactService
	*					- Call the ECOM_TestUtil Class to create test data and test each methods.
					- Used System Assertion to Confirm the functionalities.
	* 3. Objects referenced
	*    - Account
	*    - Contact
	*    - User
		
	* 4. Callouts to additional Components (including their methods) or None:
	*    - None
	*
	* 5. Dependant Class(es):
	*    - ECOM_TestUtil
	*    - ECOM_AccountWrapper
	*	 - ECOM_ContactService
	 
	* 6. Test Class Name:
	*   - ECOM_ContactService_Test
	* 7. Is @Invocable : No
	*
	* 8. Author Name(s):
	*    - Mayank 2023.09.17
	*    - Gaurang 2024.07.08 | Added getContactRecordForEmailTest,updateContactTest methods

*************************************************************/

 
@isTest
public with sharing class ECOM_ContactService_Test {
    @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
        Account acc = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
    }
    // Test method for getContactDetails
    static testMethod void testGetContactDetails() {
        // Create a test Contact record
         Contact testContact = [SELECT Id,FirstName,LastName FROM Contact ORDER BY CREATEDDATE DESC LIMIT 1];


        // Call the getContactDetails method
          Contact retrievedContact = ECOM_ContactService.getContactDetails(testContact.Id);

        // Add assertions to verify that the retrievedContact matches the expected data
        User usr = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(usr)
        {
        System.assertEquals(testContact.FirstName, retrievedContact.FirstName,'Wrong Output');
        }
    }

    // Test method for saveAdditionalShippingInfo
    public static testMethod void testSaveAdditionalShippingInfo() {
        // Create a test Contact record
        Contact testContact = [SELECT Id,FirstName,LastName FROM Contact ORDER BY CREATEDDATE DESC LIMIT 1];
        testContact.ECOM_Delivery_Details__c = 'Test Delivery Details';
        // Call the saveAdditionalShippingInfo method
        ECOM_ContactService obj = new ECOM_ContactService();
        obj.saveAdditionalShippingInfo(testContact);

        // Retrieve the Contact again and add assertions to verify that it was updated as expected
        Contact updatedContact = [SELECT Id, FirstName, LastName, ECOM_Delivery_Details__c FROM Contact WHERE Id = :testContact.Id];
        System.assertNotEquals(null, updatedContact.ECOM_Delivery_Details__c);
        // Add more assertions as needed
    }

    // Test method for saveOrUpdate
    static testMethod void testSaveOrUpdate() {
        // Create test data, such as a list of ECOM_Email_Preferences__c records
		Account ac = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
        String acId = ac.Id;
        Contact con = [SELECT Id FROM Contact ORDER BY CREATEDDATE DESC LIMIT 1];
        String conId = con.Id;
		List<ECOM_Email_Preferences__c> listEP = ECOM_TestUtil.createEmailpreferencesList(ac,con);
        ECOM_ContactService obj = new ECOM_ContactService();
        // Call the saveOrUpdate method
		obj.SaveOrUpdate(listEP);
        // Add assertions to verify that the records were saved or updated as expected
    }

    // Test method for getEmailPreferences
    static testMethod void testGetEmailPreferences() {
        // Create test data, such as an Account and associated ECOM_Email_Preferences__c records
		Account ac = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
        Contact con = [SELECT Id,ECOM_Attention_Recipient__c,ECOM_AddressRegistration__c,Default_Ship_to_ERP_Address__c,Default_Bill_to_ERP_Address__c,ECOM_NeedsVerification__c,AccountId 
                       FROM Contact 
                       ORDER BY CREATEDDATE 
                       DESC LIMIT 1];
        User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
            ECOM_ContactService obj = new ECOM_ContactService();
            //String result = ECOM_ContactService.makeAccountActive(ac.Id,'12132','32123');
            String result1 = ECOM_ContactService.makeAccountActive(con,ac.Id,'a1JDW000001DL2o2AG','a1JDW000001DL2o2AG','a1JDW000001DL2o2AG','Select BT','');
            String result2 = ECOM_ContactService.makeAccountActive(con,ac.Id,'a1JDW000001DL2o2AG','a1JDW000001DL2o2AG','a1JDW000001DL2o2AG');
            String result3 = ECOM_ContactService.makeAccountActive(con,ac.Id,'a1JDW000001DL2o2AG','a1JDW000001DL2o2AG','a1JDW000001DL2o2AG','a1JDW000001DL2o2AG','Select BT','');
            ECOM_ContactService.saveRegistrationInfo(con.Id,'a1JDW000001DL2o2AG','a1JDW000001DL2o2AG','');
            List<ECOM_Email_Preferences__c> listEP = obj.getEmailPreferences(ac.Id);
            System.AssertNotEquals(null,listEP,'Wrong Output');
        }
    }
    
    @isTest
    public static void testGetRedirectionEndpointForContact(){
        Contact con = [SELECT Id, Email FROM Contact ORDER BY CREATEDDATE DESC LIMIT 1];
        Test.startTest();
        ECOM_ContactService.getRedirectionEndpointForContact(con?.Email);
        Test.stopTest();
    }
    
    @isTest
    public static void testCreateLoginActivity(){
        Contact con = [SELECT Id, Email FROM Contact ORDER BY CREATEDDATE DESC LIMIT 1];
        Map<String,String> requestMap = new Map<String,String>();
        requestMap.put('firstName', 'test');
        requestMap.put('lastName', 'test');
        requestMap.put('loggedInContactId', con.Id);
        Test.startTest();
        ECOM_ContactService.createLoginActivity(requestMap);
        Test.stopTest();
    }
    
    /*@isTest
    public static void testgetAddressDetails()
    {
        Contact con = [SELECT Id FROM Contact ORDER BY CREATEDDATE DESC LIMIT 1];
        Map<String,Object> result = new Map<String,Object>();
        result = ECOM_ContactService.getAddressDetails(con.Id);
        Map<String,Object> result1 = ECOM_ContactService.getAddressDetails(null);
        User usr = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(usr)
        {
        System.AssertNotEquals(null,result,'Wrong Output');
        }
        
    }*/
	@isTest
    public static void testsaveAccountAndGetDetails()
    {
        Map<String,Object> result =new Map<String,Object>();
        Account newAc = ECOM_TestUtil.createAccount('RevvTest');
        insert newAc;
        Contact con = [SELECT Id,AccountId,ECOM_AddressRegistration__c FROM Contact ORDER BY CREATEDDATE DESC LIMIT 1];
        User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        	result = ECOM_ContactService.saveAccountAndGetDetails(newAc.Id, con);
        	Boolean res = ECOM_ContactService.getIsMapped(con.Id);
        }
        System.AssertNotEquals(null,result,'Wrong Output');
    }
    /*@isTest
    public static void testgetAllRelatedAccount()
    {
        List<ECOM_AccountWrapper.AccountDetails> accountWrappers = new List<ECOM_AccountWrapper.AccountDetails>();
        User u = [SELECT Id,ContactId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
            accountWrappers = ECOM_ContactService.getAllRelatedAccount();
            Contact acContact = ECOM_ContactService.getAccountContactInfo();
            Contact result = ECOM_ContactService.getAccountContactInfoById(u.ContactId);
            
            //System.assertNotEquals(null,accountWrappers,'Wrong Output');
            System.assertNotEquals(null,acContact,'Wrong Output');
        }
    }*/
    
    @isTest
    public static void testDashboardWrapper()
    {
        List<ECOM_AccountWrapper.AccountDetails> testList = new List<ECOM_AccountWrapper.AccountDetails>();
        ECOM_ContactService outerInstance = new ECOM_ContactService();
		//outerInstance.DashboardWrapper innerInstance = outerInstance.new DashboardWrapper();
        
        //innerInstance.contact = [SELECT Id FROM Contact LIMIT 1];
        //innerInstance.accountDetails = testList;
    }
    @isTest
    public static void testsaveContact()
    {
        Map<String,Object> returnMap=new Map<String,Object>();
        Contact con = [SELECT Id,FirstName,LastName FROM Contact ORDER BY CREATEDDATE DESC LIMIT 1];
        returnMap = ECOM_ContactService.saveContact(con);
        User usr = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(usr)
        {
        System.assertEquals(true,returnMap.get('Success'),'Wrong Output');
        }
    }
    /*@isTest
    public static void testupsertBillingCPA()
    {
        Contact con = [SELECT Id FROM Contact ORDER BY CREATEDDATE DESC LIMIT 1];
        ContactPointAddress cpa = [SELECT Id FROM ContactPointAddress ORDER BY CREATEDDATE DESC LIMIT 1];
        
        Contact result = ECOM_ContactService.upsertBillingCPA(cpa, con.Id);
        
        System.assertNotEquals(null,result,'Wrong Output');
    }*/
    
    
    @IsTest
    static void testcreateErrorMap() {
        try {
            throw new DMLException('My DML EXCEPTION'); 
        } catch (Exception e) {
            Map<String,Object> result=new Map<String,Object>();
            result = ECOM_ContactService.createErrorMap(e);
            System.assertNotEquals(null,result,'Wrong Output');
        }
    }
    
    @isTest
    public static void testContactDependentMethods()
    {
        List<Contact> con = [SELECT Id,FirstName,LastName,Phone,ECOM_AddressRegistration__c,ECOM_Phone_Extension__c,ECOM_Attention_Recipient__c,ECOM_Special_Instructions__c,ECOM_Delivery_Details__c 
                             FROM Contact ORDER BY CREATEDDATE DESC LIMIT 1];
        String conString = JSON.serialize(con);
        
        ECOM_ContactService.changeStringToContact(conString);
        Map<String,Object> returnMap=new Map<String,Object>();
        //List<ECOM_AccountWrapper.AccountDetails> accountDetails=new List<ECOM_AccountWrapper.AccountDetails>();
        Contact con1 = [SELECT Id,FirstName,LastName,Phone,ECOM_AddressRegistration__c,ECOM_Phone_Extension__c,ECOM_Attention_Recipient__c,ECOM_Special_Instructions__c,ECOM_Delivery_Details__c 
                        FROM Contact ORDER BY CREATEDDATE DESC LIMIT 1];
        Account acc = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
        returnMap = ECOM_ContactService.getDefaultStoreFrontPath(con1);
        User usr = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(usr)
        {
            //accountDetails = ECOM_ContactService.getCPAForCurrentContact(con1.Id,acc.Id);
            //ECOM_ContactService.updateDefaultBillingAddress(con1.Id,acc.Id);
            Contact co = ECOM_ContactService.getAccountContactInfo();
            System.assertNotEquals(null,returnMap,'Wrong Output');
            //System.assertNotEquals(null,accountDetails,'Wrong Output');
        }
    }
    
    @isTest static void getEmailPreferencesByUserTest()
    {
		User usr = [SELECT Id,ContactId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(usr)
        {
            ECOM_ContactService obj = new ECOM_ContactService();
            List<ECOM_Email_Preferences__c> res = obj.getEmailPreferencesByUser('a1JDW000001DL2o2AG',usr.ContactId);
        }
    }
    /*@isTest static void prepareActiveAccountAddressTest()
    {
        Account ac = [SELECT Id,Name FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
        // creating wrapper data
        ECOM_AccountWrapper.AccountDetails obj = new ECOM_AccountWrapper.AccountDetails();
        obj.accountName = ac.Name;
        obj.accountId = ac.Id;
        obj.sapAccountNumber = 'TESTSAP';
        obj.location = 'USA';
        List<ECOM_AccountWrapper.BillingDetails> billToDetail = new List<ECOM_AccountWrapper.BillingDetails>();
        List<ECOM_AccountWrapper.ShippingDetails> shipToDetail = new List<ECOM_AccountWrapper.ShippingDetails>();
        ECOM_AccountWrapper.BillingDetails o1 = new ECOM_AccountWrapper.BillingDetails();
        ECOM_AccountWrapper.ShippingDetails o2 = new ECOM_AccountWrapper.ShippingDetails();
        o2.shipToId = '';
        o2.sapAccountNumber = '';
        o2.shipToPostalCode = '';
        o2.shipToCountry = 'USA';
        o2.shipToState = 'CA';
        o2.shipToCity = '';
        o2.shipToStreet = 'xxxx';
        o2.shipToName = 'Test User';
        
        o1.billToId = '';
        o1.sapAccountNumber = '';
        o1.billToPostalCode = '';
        o1.billToCountry = 'USA';
        o1.billToState = 'CA';
        o1.billToCity = '';
        o1.billToStreet = 'xxxx';
        o1.billToName = 'Test User';
        
        User u = [SELECT Id,ContactId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        Contact con = [SELECT Id,
                       ECOM_DefaultBillToAccount__c,
                       ECOM_DefaultBillToAccount__r.Name,ECOM_DefaultBillToAccount__r.BillingStreet,
                      ECOM_DefaultBillToAccount__r.BillingState,ECOM_DefaultBillToAccount__r.BillingCity,ECOM_DefaultBillToAccount__r.BillingCountry,
                      ECOM_DefaultBillToAccount__r.BillingPostalCode,ECOM_DefaultShipToAccount__c,ECOM_DefaultShipToAccount__r.Name,ECOM_DefaultShipToAccount__r.ShippingStreet,
                      ECOM_DefaultShipToAccount__r.ShippingState,ECOM_DefaultShipToAccount__r.ShippingCity,ECOM_DefaultShipToAccount__r.ShippingCountry,ECOM_DefaultShipToAccount__r.ShippingPostalCode 
                      FROM Contact ORDER BY CREATEDDATE DESC LIMIT 1];
        con.ECOM_DefaultBillToAccount__c = ac.Id;
        update con;
        billToDetail.add(o1);
        shipToDetail.add(o2);
       	obj.billToDetails = billToDetail;
        obj.shipToDetails= shipToDetail;
        System.runAs(u)
        {
            obj=ECOM_ContactService.prepareActiveAccountAddress(obj,con);
            
        }
        
    }*/
     @isTest
    static void testGetERPData() 
    {
        // Create a test user and contact
        Contact testContact = [SELECT FirstName,LastName,Id,Default_Ship_to_ERP_Address__c FROM Contact ORDER BY CREATEDDATE DESC LIMIT 1];
        testContact.ECOM_CountryProvided__c = 'BB';
        update testContact;
        
        User testUser = [SELECT Id,ContactId,Contact.ECOM_CountryProvided__c,Contact.Default_Sold_to_ERP_Address__r.Master_Address__r.External_Id__c,Contact.Default_Ship_to_ERP_Address__c,Contact.Default_Bill_to_ERP_Address__c FROM User ORDER BY CREATEDDATE DESC LIMIT 1];

        // Mock your dependencies, if needed
        Test.startTest();

        // Call the method you want to test
        Map<String, Object> result = ECOM_ContactService.getERPData(testUser);
        Test.stopTest();

        // Add assertions to verify the results
        System.assertEquals(true, result.get('success'));
        System.assertEquals('BB', result.get('countryProvided'));
        // Add more assertions for other expected values
    }

    @isTest
    static void testGetNewErpData() {
        Contact testContact = [SELECT Id
                               /*,ECOM_DefaultBillToCPA__c,
                       ECOM_DefaultBillToAccount__c,
                       ECOM_DefaultBillToAccount__r.Name,ECOM_DefaultBillToAccount__r.BillingStreet,
                      ECOM_DefaultBillToAccount__r.BillingState,ECOM_DefaultBillToAccount__r.BillingCity,ECOM_DefaultBillToAccount__r.BillingCountry,
                      ECOM_DefaultBillToAccount__r.BillingPostalCode,ECOM_DefaultShipToAccount__c,ECOM_DefaultShipToAccount__r.Name,ECOM_DefaultShipToAccount__r.ShippingStreet,
                      ECOM_DefaultShipToAccount__r.ShippingState,ECOM_DefaultShipToAccount__r.ShippingCity,ECOM_DefaultShipToAccount__r.ShippingCountry,ECOM_DefaultShipToAccount__r.ShippingPostalCode */
                      FROM Contact ORDER BY CREATEDDATE DESC LIMIT 1];
        
        User testUser = [SELECT Id,ContactId,Contact.ECOM_CountryProvided__c,Contact.Default_Sold_to_ERP_Address__r.Master_Address__r.External_Id__c FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        Test.startTest();

        // Call the method you want to test
        List<ERP_Address__c> result = ECOM_ContactService.getNewErpData(testUser);
        Test.stopTest();

        // Add assertions to verify the results
        // For example, you can check if the result is not null and contains the expected records
        System.assertNotEquals(null, result);
    }
    
    @isTest
    static void updateContactTest(){
        Contact con = new Contact();
        Test.startTest();
        try{
        	ECOM_ContactService.updateContact(con);
        }
        catch(Exception e){
            
        }
        Test.stopTest();
    }
    
    @isTest
    static void getContactRecordForEmailTest(){
        Contact con = [SELECT Id,Email FROM Contact ORDER BY CreatedDate DESC LIMIT 1];
        Test.startTest();
        con = ECOM_ContactService.getContactRecordForEmail(con.Email);
        Test.stopTest();
    }
    
     /*  @isTest
    static void testPrepareCPABillAndAccountShipAddress() {
Contact testContact = [SELECT Id,ECOM_DefaultBillToCPA__c,
                       ECOM_DefaultBillToAccount__c,
                       ECOM_DefaultBillToAccount__r.Name,ECOM_DefaultBillToAccount__r.BillingStreet,ECOM_DefaultBillToCPA__r.Name,ECOM_DefaultBillToCPA__r.Street,ECOM_DefaultBillToCPA__r.State,
                       ECOM_DefaultBillToCPA__r.City,ECOM_DefaultBillToCPA__r.Country,ECOM_DefaultBillToCPA__r.PostalCode,
                      ECOM_DefaultBillToAccount__r.BillingState,ECOM_DefaultBillToAccount__r.BillingCity,ECOM_DefaultBillToAccount__r.BillingCountry,
                      ECOM_DefaultBillToAccount__r.BillingPostalCode,ECOM_DefaultShipToAccount__c,ECOM_DefaultShipToAccount__r.Name,ECOM_DefaultShipToAccount__r.ShippingStreet,
                      ECOM_DefaultShipToAccount__r.ShippingState,ECOM_DefaultShipToAccount__r.ShippingCity,ECOM_DefaultShipToAccount__r.ShippingCountry,ECOM_DefaultShipToAccount__r.ShippingPostalCode 
                      FROM Contact ORDER BY CREATEDDATE DESC LIMIT 1];        
        User testUser = [SELECT Id,ContactId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];

        ECOM_AccountWrapper.AccountDetails accountDetails = new ECOM_AccountWrapper.AccountDetails();
        ECOM_AccountWrapper.BillingDetails billingDetails = new ECOM_AccountWrapper.BillingDetails();
        ECOM_AccountWrapper.ShippingDetails shippingDetails = new ECOM_AccountWrapper.ShippingDetails();
        
        accountDetails.billToDetails.add(billingDetails);
        accountDetails.shipToDetails.add(shippingDetails);

        // Call the method you want to test
        ECOM_AccountWrapper.AccountDetails updatedAccountDetails = ECOM_ContactService.prepareCPABillAndAccountShipAddress(accountDetails, testContact);

        //
        System.assertNotEquals('TestBillToId', updatedAccountDetails.billToDetails[0].billToId);
        System.assertNotEquals('TestShipToId', updatedAccountDetails.shipToDetails[0].shipToId);
    }
        */
 }