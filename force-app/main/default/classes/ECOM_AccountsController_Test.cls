/**************************************************************

* 1. Jira Ticket(s) that relates to this class
*  
* 2. Description 
*    - This class is the test class for ECOM_AccountsController.
*
* 3. Objects referenced
*    - Account
*    - Contact
*    - User
*    - ECOM_Email_Preferences__c
* 
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_TestUtil
*    - ECOM_AccountsController
*    - ECOM_AccountDetailsModel
*
* 6. Test Class Name:
*    -None
*
* 7. Is @Invocable : No
*
* 8. Author Name(s):
*    - Manoj 2023.09.19

*************************************************************/

@isTest(SeeAllData=false)
public with sharing class ECOM_AccountsController_Test {
    
    //String constant for reused texts
    public static final String REVVITY_ACCOUNT ='Test Revvity Account';
   
    // Set up test data
    @TestSetup
    public static void testData() {
         ECOM_TestUtil.initialStorefrontSetup();
        //Creating Test data
        Account testAccount= ECOM_TestUtil.createAccount();
        Contact testContact = ECOM_TestUtil.createContact(testAccount);
        //ContactPointaddress testCpa= ECOM_TestUtil.insertContactPointAddressWithContactId(testContact.Id);
        List<ECOM_Email_Preferences__c> eepList=ECOM_TestUtil.createEmailpreferencesList(testAccount,testContact);
        User portalUser = ECOM_TestUtil.createPortalUser(testContact);
        
        //create new Punchout Master Address
        ERP_Address__c masterAddress =ECOM_TestUtil.createPunchoutMasterErpaddress();
        ERP_Address__c testErpApproved=ECOM_TestUtil.createNewApprovedAddress(masterAddress,'Ship To');
    }
    
    // Test the getUserInfo method
    /*@isTest
    static void testGetUserInfo() {
        Account testAccount=[SELECT Id,Name From Account WHERE Account.Name=:ECOM_TestUtil.REVVITY_ACCOUNT];
          Contact testContact=[SELECT Id, Name,AccountId FROM Contact WHERE AccountId=:testAccount.Id];
        User u = [SELECT Id FROM User LIMIT 1];
       // ContactPointaddress testCpa = [Select Id,Contact__c, AddressType, Name, CompanyName, Street, City, State, PostalCode, Country, PhoneNumber,ECOM_Review_Status__c,ECOM_Associated_ShipTo__c From ContactPointaddress Where Contact__c= :testContact.Id ORDER BY CREATEDDATE DESC LIMIT 1];
       ContactPointAddress testCpa = new ContactPointAddress();
        testCpa.AddressType='Billing';
        testCpa.Contact__c= testContact.Id;
        testCpa.Country='United States';
        testCpa.Name='Home';
        testCpa.AddressType = 'Billing';
        testCpa.ECOM_Review_Status__c='New';
        testCpa.ECOM_Associated_ShipTo__c='000000000000000AAA';
        insert testCpa;
        System.debug('testCpa'+testCpa);
        List<ContactPointAddress> listBillingCPAs = new List<ContactPointAddress>();
        listBillingCPAs.add(testCpa);
        // Call the getUserInfo method
        Test.startTest();
        Map<String,Object> resultMap;
        User testuser;
        System.runAs(u){
        resultMap = ECOM_AccountsController.getUserInfo();
        testuser =(User)resultMap.get('user');
        }
        Test.stopTest();
        
        // Validate the results
        System.assertEquals('SUCCESS', resultMap.get('status'),'Status should be SUCCESS');
        
    }*/
    
    // Test the saveAddressesOnCPA method
  /*  @isTest
    static void testSaveAddressesOnCPA() { 
        
        //Creating Request data
        Account testAccount = [SELECT Id ,Account_Domains__c, BillingStreet,BillingCity, 
                               BillingState,BillingPostalCode,
                               BillingCountry,ShippingStreet, ShippingCity, 
                               ShippingState, ShippingPostalCode,
                               ShippingCountry  FROM Account WHERE Name=:ECOM_TestUtil.REVVITY_ACCOUNT];
        Account acc = new Account(Name='Dummy Account - United States');
        insert acc;
        List<User> users= [Select Id , Alias from User ORDER BY CREATEDDATE DESC LIMIT 1];
        Map<string,string> shippingAddressFieldToValue = new Map<string,string>();
        shippingAddressFieldToValue.put('companyName','Raftre');
        shippingAddressFieldToValue.put('Address1','121');
        shippingAddressFieldToValue.put('city','NY');
        shippingAddressFieldToValue.put('state','Alaska');
        shippingAddressFieldToValue.put('zip','1234');
        shippingAddressFieldToValue.put('country','United States');
        shippingAddressFieldToValue.put('phone','4356543211');
        shippingAddressFieldToValue.put('extn','extn');
        
        Map<string,string> billingAddressFieldToValue = new Map<string,string>();
        billingAddressFieldToValue.put('companyName','Raftre');
        billingAddressFieldToValue.put('Address1','121');
        billingAddressFieldToValue.put('city','NY');
        billingAddressFieldToValue.put('state','Alaska');
        billingAddressFieldToValue.put('zip','1234');
        billingAddressFieldToValue.put('country','United States');
        billingAddressFieldToValue.put('phone','4356543211');
        billingAddressFieldToValue.put('extn','extn');
        Map<String,Object> addressesMap= new Map<String,Object>();
        String billingAddressString = JSON.serialize(billingAddressFieldToValue);
        String shippingAddressString = JSON.serialize(shippingAddressFieldToValue);
        addressesMap.put('shippingAddressInfo',shippingAddressString);
        addressesMap.put('billingAddressInfo',billingAddressString);
        
        //Running test in context of this user , one method needs user id
        System.runAs(new User(Id=users[0].Id)){
            
            // Call the saveAddressesOnCPA method
            Test.startTest();
            Map<String,Object> resultMap = ECOM_AccountsController.saveAddressesOnCPA(addressesMap,'attRecipient','United States');
            Test.stopTest();
            
            // Validate the results
            System.assertnotEquals(null, resultMap.get('status'),'Status should be SUCCESS');
        }
    }*/
    
    /*@isTest
    static void testSaveAddressesOnCPAExceptionCase() {
        Test.startTest();
        Map<String,Object> result = ECOM_AccountsController.saveAddressesOnCPA(new Map<String,Object>(),'','');
        Test.stopTest();
    }*/
    
    //Test the getEmailPreferences method
    @isTest
    static void testGetEmailPreferences() {
        //Query account created in test setup
        Account acc = [SELECT Id ,Name  FROM Account WHERE Name=:ECOM_TestUtil.REVVITY_ACCOUNT];
        
        // Call the getUserInfo method
        Test.startTest();
        List<ECOM_Email_Preferences__c> epList = ECOM_AccountsController.getEmailPreferences(acc.Id);
        Test.stopTest();
        
        // Validate the results
        //System.assertEquals(1, epList.size(),'List size should be 1');
        
    }
    //Test the upsertEmailPreferences and deleteEmailPreferences method
    @isTest
    static void testUpsertAndDeleteEmailPreferences() {
        //Query account created in test setup
        Account acc = [SELECT Id ,Name  FROM Account WHERE Name=:ECOM_TestUtil.REVVITY_ACCOUNT];
        Contact con = [SELECT Id ,Name,AccountId  FROM Contact WHERE AccountId=:acc.Id];
        List<ECOM_Email_Preferences__c> eepList=new List<ECOM_Email_Preferences__c>();
        ECOM_Email_Preferences__c eep = new ECOM_Email_Preferences__c();
        eep.ECOM_Account__c=acc.Id;
        eep.ECOM_Contact__c=con.Id;
        eep.ECOM_Email__c='test1@yopmail.com';
        eepList.add(eep);
        insert eepList;
        String jsonList = JSON.serialize(eepList);
        
        // Call the upsertEmailPreferences method
        Test.startTest();
        ECOM_AccountsController.upsertEmailPreferences(jsonList);
        List<ECOM_Email_Preferences__c> resultList1=[SELECT Id ,Name  FROM ECOM_Email_Preferences__c];
        
        // Validate the results
        System.assertEquals(2, resultList1.size(),'2 item in list');
        
        // Call the deleteEmailPreferences method
        ECOM_AccountsController.deleteEmailPreferences(jsonList);
        List<ECOM_Email_Preferences__c> resultList2=[SELECT Id ,Name  FROM ECOM_Email_Preferences__c];
        
        // Validate the results
        //System.assertEquals(1, resultList2.size(),'1 item in list');
        Test.stopTest();
    }
    
    //Test the getEmailPreferences method
    @isTest
    static void testAccountFlowWrapperClass() {
        
        // Call the class constructors
        Test.startTest();
        ECOM_AccountDetailsModel instance= new ECOM_AccountDetailsModel();
        instance.success=true;
        
        Test.stopTest();
        
        //Validate the results
        System.assertEquals(true,instance.success,'List size should be 1');
        
    }
    
    //
    //
    
    @isTest
    static void testUpdateContactandCart() {
        Account testAccount = [SELECT Id ,Name  FROM Account WHERE Name=:ECOM_TestUtil.REVVITY_ACCOUNT];
        Contact testContact = [SELECT Id ,Name,AccountId  FROM Contact WHERE AccountId=:testAccount.Id];
        ERP_Address__c erpAddress = new ERP_Address__c();
        erpAddress.Account__c = testAccount.Id;
        insert erpAddress;
        
        // Set up parameters for the method
        String contactId = testContact.Id;
        String accountId = testAccount.Id;
        String erpShipToId = erpAddress.Id;
        String erpBillToId = erpAddress.Id;
        String erpSoldToId = erpAddress.Id;
        Boolean emptySoldTo = true; // Set to true or false as needed
        
        // Call the method in the test context
        Test.startTest();
        String result = ECOM_AccountsController.updateContactandCart(contactId, accountId, erpShipToId, erpBillToId, erpSoldToId, '', emptySoldTo);
        Test.stopTest();
        
        System.assertEquals('Success', result);
    }
    
    @isTest
    static void updateContactandCartException(){
        Test.startTest();
        String response = ECOM_AccountsController.updateContactandCart('','','','','', '',null);
        Test.stopTest();
    }
    
        @isTest
    static void testFetchERPAddressDetails() {
        // Create a test User
        Account testAccount = [SELECT Id ,Name  FROM Account WHERE Name=:ECOM_TestUtil.REVVITY_ACCOUNT];
        Contact testContact = [SELECT Id ,Name,AccountId,ECOM_CountryProvided__c FROM Contact WHERE AccountId=:testAccount.Id];
        User testUser = [Select Id,ContactId From User WHERE ContactId=:testContact.Id ORDER BY CREATEDDATE DESC LIMIT 1];
        testContact.ECOM_CountryProvided__c='United States';
        update testContact;
        ERP_Address__c newAdd = new ERP_Address__c();
        newAdd.Contact__c=testContact.Id;
        newAdd.Address_Type__c='Ship To';
        newAdd.ECOM_Review_Status__c='New';
         newAdd.SAP_Name_1__c = 'testsapname1';
            newAdd.SAP_Name_2__c = 'testsapname2';
            newAdd.SAP_Name_3__c = 'testsapname3';
        insert newAdd;
        // Set up the test context
        Test.startTest();
        
        // Call the method in the test context
        system.runAs(testUser){
        Map<String, Object> result = ECOM_AccountsController.fetchERPAddressDetails();
        }
        
        // Stop the test context
        Test.stopTest();
        
        // Add your assertions here to validate the result
        //System.assert(result.get('success') == true);
        
        
    }
           @isTest
    static void testFetchERPAddressDetailscase2() {
        // Create a test User
        Account testAccount = [SELECT Id ,Name  FROM Account WHERE Name=:ECOM_TestUtil.REVVITY_ACCOUNT];
        Contact testContact = [SELECT Id ,Name,AccountId,ECOM_CountryProvided__c FROM Contact WHERE AccountId=:testAccount.Id];
        User testUser = [Select Id,ContactId From User WHERE ContactId=:testContact.Id ORDER BY CREATEDDATE DESC LIMIT 1];
        testContact.ECOM_CountryProvided__c='United States';
        update testContact;
        ERP_Address__c newAdd = new ERP_Address__c();
        newAdd.Contact__c=testContact.Id;
        newAdd.Address_Type__c='Payer';
        newAdd.ECOM_Review_Status__c='New';
         newAdd.SAP_Name_1__c = 'testsapname1';
            newAdd.SAP_Name_2__c = 'testsapname2';
            newAdd.SAP_Name_3__c = 'testsapname3';
        insert newAdd;
        // Set up the test context

        Test.startTest();
        
        // Call the method in the test context
        system.runAs(testUser){
        Map<String, Object> result = ECOM_AccountsController.fetchERPAddressDetails();
        }
        
        // Stop the test context
        Test.stopTest();
        
        // Add your assertions here to validate the result
        //System.assert(result.get('success') == true);
        
        
    }
    
    @isTest
    static void testFetchERPAddressDetailsExceptionCase() {
        // Create a test User
        Account testAccount = [SELECT Id ,Name  FROM Account WHERE Name=:ECOM_TestUtil.REVVITY_ACCOUNT];
        Contact testContact = [SELECT Id ,Name,AccountId  FROM Contact WHERE AccountId=:testAccount.Id];
        User testUser = [Select Id,ContactId From User WHERE ContactId=:testContact.Id ORDER BY CREATEDDATE DESC LIMIT 1];
        
        // Set up the test context
        Test.startTest();
        
        // Call the method in the test context
        Map<String, Object> result = ECOM_AccountsController.fetchERPAddressDetails();
        
        // Stop the test context
        Test.stopTest();
        
        // Add your assertions here to validate the result
        //System.assert(result.get('success') == true);
        
        
    }
    
    
    @isTest
    static void testFetchAccountDetails() {
        
        Account testAccount = [SELECT Id ,Name  FROM Account WHERE Name=:ECOM_TestUtil.REVVITY_ACCOUNT];
        Contact testContact = [SELECT Id ,Name,AccountId  FROM Contact WHERE AccountId=:testAccount.Id];
        User testUser = [Select Id,ContactId From User WHERE ContactId=:testContact.Id ORDER BY CREATEDDATE DESC LIMIT 1];
        
        // Set up the test context
        Test.startTest();
        
        // Call the method in the test context
        List<ECOM_MyAccountModel> accountDetails = ECOM_AccountsController.fetchAccountDetails();
        
        // Stop the test context
        Test.stopTest();
        
        // Add your assertions to validate the result
        System.assertNotEquals(null, accountDetails, 'Account details should not be null');
        
    }
    
    @isTest
    static void testAddERPAddresses() {
        Account testAccount = [SELECT Id ,Name  FROM Account WHERE Name=:ECOM_TestUtil.REVVITY_ACCOUNT];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
       /* ERP_Address__c erpAddress = new ERP_Address__c();
        erpAddress.Account__c = testAccount.Id;
        erpAddress.ECOM_Review_Status__c = 'New';
        insert erpAddress;
        List<String> billToIds=new List<String>();
        billToIds.add(erpAddress.Id);
        List<String> shipToIds=new List<String>();
        shipToIds.add(erpAddress.Id);
        List<ERP_AddressModel> testErpAddresses = new List<ERP_AddressModel>();
        ERP_AddressModel erpModel = new ERP_AddressModel();
        erpModel.associatedAddresses = testErpAddresses;  */      
       ERP_AddressModel  testRecord = new ERP_AddressModel();
           testRecord.externalId = 'SAP123';
        testRecord.isNew = true;
        testRecord.isSelected = false;
        testRecord.isAddNewAddress = true;
        testRecord.accountId = testAccount.Id;
        testRecord.customerNumber = '12345';
        testRecord.erpAccountName = 'Test Account';
        testRecord.accountGroup = '0001';
        testRecord.contactId = con.Id;
        testRecord.isEcomEnabled = true;
        testRecord.ecomReviewStatus = 'New';
        testRecord.addressType = 'Ship To';
        testRecord.street = '123 Main St';
        testRecord.city = 'Cityville';
        testRecord.state = 'ST';
        testRecord.postalCode = '12345';
        testRecord.country = 'US';
        testRecord.fxAddress = '456 Secondary St';
        testRecord.sapName = 'SAPName';
        testRecord.showSapName = false;
      
        // Serialize the test data to JSON
         List<ERP_AddressModel> addressmodel = new  List<ERP_AddressModel>();
        addressmodel.add(testRecord);
        String testRecordJson = JSON.serialize(addressmodel);
        // Set up the test context
        Test.startTest();
        
        // Call the method in the test context
        Map<String, Object> response = ECOM_AccountsController.addERPAddresses(testRecordJson);
        
        // Stop the test context
        Test.stopTest();
        
        // Add your assertions to validate the result
        /*System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(true, response.get('success'), 'Success should be true');*/
        
    }
    
    
    @isTest
    static void testAddERPAddressesExceptionCase() {
        Account testAccount = [SELECT Id ,Name  FROM Account WHERE Name=:ECOM_TestUtil.REVVITY_ACCOUNT];
       /* ERP_Address__c erpAddress = new ERP_Address__c();
        erpAddress.Account__c = testAccount.Id;
        erpAddress.ECOM_Review_Status__c = 'New';
        insert erpAddress;
        List<String> billToIds=new List<String>();
        billToIds.add(erpAddress.Id);
        List<String> shipToIds=new List<String>();
        shipToIds.add(erpAddress.Id);
        List<ERP_AddressModel> testErpAddresses = new List<ERP_AddressModel>();
        ERP_AddressModel erpModel = new ERP_AddressModel();
        erpModel.associatedAddresses = testErpAddresses;  */      
       ERP_AddressModel  testRecord = new ERP_AddressModel();
           testRecord.externalId = 'SAP123';
        testRecord.isNew = true;
        testRecord.isSelected = false;
        testRecord.isAddNewAddress = true;
        testRecord.accountId = testAccount.Id;
        testRecord.customerNumber = '12345';
        testRecord.erpAccountName = 'Test Account';
        testRecord.accountGroup = '0001';
        testRecord.contactId = 'A987';
        testRecord.isEcomEnabled = true;
        testRecord.ecomReviewStatus = 'Pending';
        testRecord.addressType = 'Sold To';
        testRecord.street = '123 Main St';
        testRecord.city = 'Cityville';
        testRecord.state = 'ST';
        testRecord.postalCode = '12345';
        testRecord.country = 'US';
        testRecord.fxAddress = '456 Secondary St';
        testRecord.sapName = 'SAPName';
        testRecord.showSapName = false;
      
        // Serialize the test data to JSON
       String testRecordJson = JSON.serialize(testRecord);
         List<ERP_AddressModel> addressmodel = new  List<ERP_AddressModel>();
        addressmodel.add(testRecord);
        // Set up the test context
        Test.startTest();
        
        // Call the method in the test context
        Map<String, Object> response = ECOM_AccountsController.addERPAddresses(testRecordJson);
        
        // Stop the test context
        Test.stopTest();
        
    }
            @isTest
    static void testFetchERPAddressDetailscase() {
        // Create a test User
        Account testAccount = [SELECT Id ,Name  FROM Account WHERE Name=:ECOM_TestUtil.REVVITY_ACCOUNT];
        Contact testContact = [SELECT Id ,Name,AccountId,ECOM_CountryProvided__c FROM Contact WHERE AccountId=:testAccount.Id];
        User testUser = [Select Id,ContactId From User WHERE ContactId=:testContact.Id ORDER BY CREATEDDATE DESC LIMIT 1];
        testContact.ECOM_CountryProvided__c='United States';
        update testContact;
        ERP_Address__c newAdd = new ERP_Address__c();
        newAdd.Contact__c=testContact.Id;
        newAdd.Account__c = testAccount.id;
        newAdd.Address_Type__c='Ship To';
        newAdd.ECOM_Review_Status__c=null;
         newAdd.SAP_Name_1__c = 'testsapname1';
            newAdd.SAP_Name_2__c = 'testsapname2';
            newAdd.SAP_Name_3__c = 'testsapname3';
        insert newAdd;
        // Set up the test context
        Test.startTest();
        
        // Call the method in the test context
        system.runAs(testUser){
        Map<String, Object> result = ECOM_AccountsController.fetchERPAddressDetails();
        }
        
        // Stop the test context
        Test.stopTest();
        
        // Add your assertions here to validate the result
        //System.assert(result.get('success') == true);
        
        
    }
    
    //test method for getSearchedPunchoutAccounts() -- VRa Punchout Changes
	/*@isTest
    static void getSearchedPunchoutAccounts(){
        Test.startTest();
        Map<String,Object> responseMap = ECOM_AccountsController.getSearchedPunchoutAccounts(REVVITY_ACCOUNT);
        Test.stopTest();
        Assert.isTrue(responseMap.containsKey(ECOM_Constant.PARAM_SUCCESS)? (Boolean)responseMap.get(ECOM_Constant.PARAM_SUCCESS) : false, 'Expected a successful response');
    }*/
    
	@isTest
    static void testGetPunchoutAccounts(){
        Test.startTest();
        Map<String,Object> responseMap = ECOM_AccountsController.getPunchoutAccounts();
        Assert.isNotNull(responseMap, 'Expected a not null Map'); 
        Test.stopTest();
    }
}