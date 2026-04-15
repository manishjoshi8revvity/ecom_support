/**************************************************************

* 1. Jira Ticket(s) that relates to this class

*  

*

* 2. Description - This class is a test class for ECOM_ContactController.
- Call the ECOM_TestUtil Class to create test data and test each methods.
- Used System Assertion to Confirm the functionalities.

*

* 3. Objects referenced

*    - Account

*    - Contact

*.   -User

* 4. Callouts to additional Components (including their methods) or None:

*    - None

*

* 5. Dependant Class(es):

*    - ECOM_TestUtil

*    - classes called from test class

*

* 6. Test Class Name:

*    -None

*

* 7. Is @Invocable : No

*

* 8. Author Name(s):

*    - Manoj 2023.09.19
*    - Sidak 2024.04.22 | Updated updateShiptToAndBillToTest method for Assertion error
*    - Sidak 2024.05.17 | Added testGetContactInfo method
*    - Gaurang 2024.07.08 | Added createLoginActivityTest method
*    - Manish Joshi 2025.01.31 | Updated method checkSoldToERPAddressTest for code coverage of RWPS-1520
*    - Poonam Shukla 2025.04.22 | Updated & added few methods code coverage of RWPS-1506
*    - Manish Joshi 2025.07.24 - Updated method getChangeAccountDataTestCase2 - RWPS-3657
*    - Mahesh Suthar 2025.12.11 - Created new methods to increase test coverage - RWPS-5118
*************************************************************/
@isTest(SeeAllData=false)
public with sharing class ECOM_ContactController_Test {
    @TestSetup
    static void testData() {
        ECOM_TestUtil.initialStorefrontSetup();//RWPS-1506
   }
    
    
    @isTest
    static void testSaveContact_Success() {
        User u = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        // Create a test Contact record
        Contact con = [Select Id, FirstName,Phone From Contact LIMIT 1];//RWPS-1506
        con.Phone = '1234567890';
        update con;
        
        Contact testContact  = [SELECT Id, FirstName, LastName, Email,Phone FROM Contact WHERE Id = :con.Id];
        Test.startTest();
        Map<String, Object> result;
        System.runAs(u){
            result = ECOM_ContactController.saveContact(testContact);
        }
        
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testSaveContact_Error() {
        User u = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Contact testContact = new Contact();
        
        // Call the method under test
        Test.startTest();
        Map<String, Object> result;
        System.runAs(u){
            result = ECOM_ContactController.saveContact(testContact);
        }
        
        Test.stopTest();
        
        System.assertNotEquals(null, result.get('ErrorMessage'));
        
    }
    @isTest
    static void testgetContactBasedOnId(){
        
        Contact con = [Select Id ,FIrstName,Default_Bill_to_ERP_Address__c,Default_Ship_to_ERP_Address__c From Contact LIMIT 1];//RWPS-1506
        User u = [Select Id,LastName,ContactId From User Where ContactId = :con.Id ORDER BY CREATEDDATE DESC LIMIT 1];
        ERP_Address__c testAdd = new ERP_Address__c();
        testAdd.SAP_Name_1__c = 'testsapname1';
        testAdd.SAP_Name_2__c = 'testsapname2';
        testAdd.SAP_Name_3__c = 'testsapname3';
        testAdd.SAP_Name_4__c = 'testsapname4';
        testAdd.Contact__c = con.Id;
        testAdd.Address_Type__c = 'Payer';
        insert testAdd;
        con.Default_Bill_to_ERP_Address__c=testAdd.Id;
        con.Default_Ship_to_ERP_Address__c=testAdd.Id;
        update con;
        Test.startTest();
        System.runAs(u){
            ECOM_ContactController.getContactBasedOnId(con.Id);
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void getAddressDetailsTestCase1(){
        User u = [Select Id,LastName,ContactId From User ORDER BY CREATEDDATE DESC LIMIT 1]; //RWPS-1506
        Contact con = [Select Id ,ECOM_CountryProvided__c From Contact Where Id = :u.ContactId];
        ERP_Address__c testAdd = new ERP_Address__c();
        insert testAdd;
        con.ECOM_CountryProvided__c='United States';
        con.ECOM_AddressRegistration__c='Select ST & BT';
        con.ECOM_RegistrationPattern__c='Domain Match';
        update con;
        
        Test.startTest();
        Map<String,Object> result;
        System.runAs(u){
            result = ECOM_ContactController.getAddressDetails();
        }
        Test.stopTest();
        
        System.assertEquals(true,result.get('success'),'Value mismatch');
    }
    
    @isTest
    static void getAddressDetailsTestCase2(){
        User u = [Select Id,LastName,ContactId From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Contact con = [Select Id ,ECOM_CountryProvided__c From Contact Where Id = :u.ContactId];
        ERP_Address__c testAdd = new ERP_Address__c();
        insert testAdd;
        
        Test.startTest();
        Map<String,Object> result;
        System.runAs(u){
            result = ECOM_ContactController.getAddressDetails();
        }
        Test.stopTest();
        
        System.assertEquals(true,result.get('success'),'Value mismatch');
    }
    
    @isTest
    static void getAddressDetailsTestCase3(){    
        Test.startTest();
        Map<String,Object> result;
        result = ECOM_ContactController.getAddressDetails();
    }
    
    @isTest
    static void saveSoldToERPAddressTest(){
        User u = [Select Id,LastName,ContactId From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Contact con = [Select Id ,ECOM_CountryProvided__c From Contact Where Id = :u.ContactId];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        ERP_Address__c testAdd = new ERP_Address__c();
        insert testAdd;
        con.ECOM_CountryProvided__c='United States';
        con.ECOM_AddressRegistration__c='Select ST & BT';
        con.ECOM_RegistrationPattern__c='Domain Match';
        update con;
        
        Test.startTest();
        Map<String,Object> result;
        System.runAs(u){
            result = ECOM_ContactController.saveSoldToERPAddress(testAdd.Id,acc.Id,'Select ST & BT');
        }
        Test.stopTest();
        
        System.assertEquals(true,result.get('success'),'Value mismatch');
    }
    
    @isTest
    static void saveSoldToERPAddressTest2(){
        Map<String,Object> result = ECOM_ContactController.saveSoldToERPAddress('','','');        
    }
    
    @isTest
    static void updateShiptToAndBillToTest(){
        User u = [Select Id,LastName,ContactId From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Contact con = [SELECT Id,ECOM_CountryProvided__c, ECOM_Attention_Recipient__c,ECOM_AddressRegistration__c,Default_Ship_to_ERP_Address__c,Default_Bill_to_ERP_Address__c,ECOM_NeedsVerification__c,AccountId FROM Contact ORDER BY CREATEDDATE DESC LIMIT 1];//RWPS-1506
        ERP_Address__c testAdd = new ERP_Address__c();
        insert testAdd;
        Account ac = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];//RWPS-1506
        Test.startTest();
        //RWPS-1520 Start
        Map<String,Object> result1;
        Map<String,Object> result2;
        System.runAs(u)
        {
            result1=ECOM_ContactController.updateShiptToAndBillTo(con.Id, testAdd.Id, testAdd.Id,testAdd.Id,testAdd.Id, 'Select BT', 'Select BT');
            result2=ECOM_ContactController.updateShiptToAndBillTo(con.Id, testAdd.Id, testAdd.Id,testAdd.Id,testAdd.Id, 'In Progress', 'Test');
        }//RWPS-1520 End
        Test.stopTest();
    }
    
    @isTest
    static void getChangeAccountDataTestCase1(){
        Account acc = new Account();
        acc.Name = 'PLACEHOLDER- United States';
        insert acc;
		User u = [Select Id,LastName,ContactId From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Contact con = [Select Id ,ECOM_CountryProvided__c From Contact Where Id = :u.ContactId];
        con.ECOM_CountryProvided__c='United States';
        con.ECOM_AddressRegistration__c='Select BT';
        con.ECOM_RegistrationPattern__c='Domain Match';
        update con;
		Test.startTest();
        Map<String,Object> result;
        System.runAs(u){
            result = ECOM_ContactController.getChangeAccountData();
        }
		Test.stopTest();   
        System.assertEquals(true,result.get('success'),'Value mismatch');
    }
    
    @isTest
    static void getChangeAccountDataTestCase2(){
        Account acc = new Account();
        acc.Name = 'PLACEHOLDER- United States';
        insert acc;
		User u = [Select Id,LastName,ContactId From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Contact con = [Select Id ,ECOM_CountryProvided__c From Contact Where Id = :u.ContactId];
        con.ECOM_CountryProvided__c='United States';
        update con;
		
        Map<String,Object> result;
        //RWPS-3657 - START
        String mockBody = JSON.serialize(new Map<String, Object>{
                'totalSize' => 1,
                'done' => true,
                'records' => new List<Map<String, Object>>{
                    new Map<String, Object>{
                        'Id' => '0HzXXXX',
                        'ContactId' => u.ContactId,
                        'Field' => 'Default_Bill_to_ERP_Address__c',
                        'OldValue' => 'Payer--',
                        'NewValue' => 'Payer--0100123456',
                        'CreatedDate' => '2025-07-01T10:00:00.000+0000'
                    }
                }
            });
        System.runAs(u){
            ECOM_MockHttpResponseGenerator mockResponse = new ECOM_MockHttpResponseGenerator(200, 'OK', mockBody, new Map<String,String>());
        	Test.setMock(HttpCalloutMock.class, mockResponse);// RWPS-3657 - END
            Test.startTest();
            result = ECOM_ContactController.getChangeAccountData();
            Test.stopTest(); 
        }
		 
        System.assertEquals(true,result.get('success'),'Value mismatch');
    }
    
    @isTest
    static void checkSoldToERPAddressTest(){
        User u = [Select Id,LastName,ContactId From User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u){
            Test.startTest();
            Map<String,Object> result = ECOM_ContactController.checkSoldToERPAddress('test12345', 'test12345');//RWPS-1520
            Test.stopTest();//RWPS-1520
        	System.assertEquals(false,result.get('success'),'Value mismatch');
        }
    }

    
    
    @isTest
    static void createERPAddressesTestCase1(){
        ECOM_DummyAccountCountryMapping__mdt item = [SELECT Id,Dummy_Account__c,Country__c FROM ECOM_DummyAccountCountryMapping__mdt WHERE Dummy_Account__c!=NULL AND Country__c!=NULL LIMIT 1];
        Account acc = new Account();
        acc.Name = item.Dummy_Account__c;
        insert acc;
        User u = [Select Id,LastName,ContactId From User ORDER BY CREATEDDATE DESC LIMIT 1];
        //u.Country = 'United States';
        //update u;
        Contact con = [Select Id ,ECOM_CountryProvided__c From Contact Where Id = :u.ContactId];
        Order ord = [SELECT Id,Default_Bill_to_ERP_Address__c,Default_Ship_to_ERP_Address__c FROM Order ORDER BY CreatedDate DESC LIMIT 1];
        con.ECOM_CountryProvided__c=item.Country__c;
        update con;
        ERP_Address__c testAdd = new ERP_Address__c();
        testAdd.Account__c = acc.Id;
        insert testAdd;
        ord.Default_Bill_to_ERP_Address__c=testAdd.Id;
        ord.Default_Ship_to_ERP_Address__c=testAdd.Id;
        update ord;
        ERP_AddressModel testModel = new ERP_AddressModel();
        testModel.id=testAdd.Id;
        testModel.externalId='test123';
        testModel.addressType='Ship To';
        testModel.ecomReviewStatus='New';
        testModel.contactId=con.Id;
        // RWPS-1520 - START
        ERP_AddressModel testModel1 = new ERP_AddressModel();
        testModel1.id=testAdd.Id;
        testModel1.externalId='test123';
        testModel1.addressType='Bill To';
        testModel1.ecomReviewStatus='New';
        testModel1.contactId=con.Id;
        ERP_AddressModel testModel2 = new ERP_AddressModel();
        testModel2.id=testAdd.Id;
        testModel2.externalId='test123';
        testModel2.addressType='Payer';
        testModel2.ecomReviewStatus='New';
        testModel2.contactId=con.Id;
        // RWPS-1520 - END
        List<ERP_AddressModel> testModels = new List<ERP_AddressModel>();
        testModels.add(testModel);
        // RWPS-1520 - START
        testModels.add(testModel1);
        testModels.add(testModel2);
        // RWPS-1520 - END
        String jsonString = JSON.serialize(testModels);
        Test.startTest();
        Map<String,Object> result;
        System.runAs(u){
           result=ECOM_ContactController.createERPAddresses(jsonString, 'testAddress'); 
        }
        Test.stopTest();
        
        system.assertEquals(false,result.get('success'),'value mismatch');
    }
    
    @isTest
    static void createERPAddressesTestCase2(){
        ECOM_DummyAccountCountryMapping__mdt item = [SELECT Id,Dummy_Account__c,Country__c FROM ECOM_DummyAccountCountryMapping__mdt WHERE Dummy_Account__c!=NULL AND Country__c!=NULL LIMIT 1];
        Account acc = new Account();
        acc.Name = item.Dummy_Account__c;
        insert acc;
        User u = [Select Id,LastName,ContactId From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Contact con = [Select Id ,ECOM_CountryProvided__c From Contact Where Id = :u.ContactId];
        con.ECOM_CountryProvided__c = item.Country__c;
        update con;
        ERP_Address__c testAdd = new ERP_Address__c();
        insert testAdd;
        ERP_AddressModel testModel = new ERP_AddressModel();
        testModel.id=testAdd.Id;
        testModel.externalId='test123';
        testModel.addressType='Payer';
        testModel.ecomReviewStatus='New';
        testModel.contactId=con.Id;
        List<ERP_AddressModel> testModels = new List<ERP_AddressModel>();
        testModels.add(testModel);
        String jsonString = JSON.serialize(testModels);
        Test.startTest();
        Map<String,Object> result;
        System.runAs(u){
           result=ECOM_ContactController.createERPAddresses(jsonString, 'testAddress'); 
        }
        Test.stopTest();
        
        system.assertEquals(true,result.get('success'),'value mismatch');
    }
    
    @isTest
    static void fetchNewERPAddressesTest(){
    	User u = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Contact con = [Select Id ,FIrstName From Contact LIMIT 1];//RWPS-1506
        Test.startTest();
        Map<String,Object> response;
        System.runAs(u){
            response = ECOM_ContactController.fetchNewERPAddresses();
        }
        Test.stopTest();
        System.assertEquals(null,response.get('attentionRecipient'),'unexpected response');
    }
    @isTest
    static void testgetContactBasedOnIdcase2(){
        User u = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Contact con = [Select Id ,FIrstName,Default_Bill_to_ERP_Address__c,Default_Ship_to_ERP_Address__c From Contact LIMIT 1];//RWPS-1506
        ERP_Address__c testAdd = new ERP_Address__c();
        testAdd.ECOM_Review_Status__c = 'New';
        insert testAdd;
        con.Default_Bill_to_ERP_Address__c=testAdd.Id;
        con.Default_Ship_to_ERP_Address__c=testAdd.Id;
        update con;
        Test.startTest();
        System.runAs(u){
            ECOM_ContactController.getContactBasedOnId(con.Id);
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetContactInfo(){
        User u = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Test.startTest();
        System.runAs(u){
            ECOM_ContactController.getContactInfo();
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void createLoginActivityTest(){
        Map<String,String> requestMap = new Map<String,String>();
        requestMap.put('loggedInContactId','test');
        Test.startTest();
        requestMap = ECOM_ContactController.createLoginActivity(requestMap);
        Test.stopTest();
    }
   
    //RWPS-1506 Start
    @isTest
    static void testUpdateShiptToAndBillTo_success() {
        Account acc = [SELECT Id,Name FROM Account where Name ='TestClass Account'];
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        ERP_Address__c masterAddress = [SELECT Id FROM ERP_Address__c where Address_Type__c='Master'];
        masterAddress.ECOM_Review_Status__c = 'Approved';
        update masterAddress;
        ERP_Address__c shipTo = [SELECT Id,Account__c FROM ERP_Address__c where Address_Type__c='Ship To'];
        shipTo.Account__c = acc.Id;
        update shipTo;
        ERP_Address__c erpaddressPayer = [SELECT Id,Account__c FROM ERP_Address__c where Address_Type__c='Payer'];
        erpaddressPayer.Account__c = acc.Id;
        update erpaddressPayer;
        Test.startTest();
        Map<String, Object> result = ECOM_ContactController.updateShiptToAndBillTo(
            con.Id,
            shipTo.Id,
            shipTo.Id,
            erpaddressPayer.Id,
            shipTo.Id,
            'In Progress',
            'John Doe'
        );
        Test.stopTest();
    }

   @isTest
    static void createERPAddressesTestCase3(){
        ECOM_DummyAccountCountryMapping__mdt item = [SELECT Id,Dummy_Account__c,Country__c FROM ECOM_DummyAccountCountryMapping__mdt WHERE Dummy_Account__c!=NULL AND Country__c!=NULL LIMIT 1];
        Account acc = new Account();
        acc.Name = item.Dummy_Account__c;
        insert acc;
        User u = [Select Id,LastName,ContactId From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Contact con = [Select Id ,ECOM_CountryProvided__c From Contact Where Id = :u.ContactId];
        con.ECOM_CountryProvided__c = item.Country__c;
        update con;
        ERP_Address__c testAdd = new ERP_Address__c();
        insert testAdd;
        ERP_Address__c testAdd1 = new ERP_Address__c();
        insert testAdd1;
        ERP_AddressModel testModel = new ERP_AddressModel();
        testModel.id=testAdd.Id;
        testModel.externalId='test123';
        testModel.addressType='Payer';
        testModel.ecomReviewStatus='New';
        testModel.contactId=con.Id;
         
        ERP_AddressModel testModel1 = new ERP_AddressModel();
        testModel1.id=testAdd1.Id;
        testModel1.externalId='test1234';
        testModel1.addressType='Ship To';
        testModel1.ecomReviewStatus='New';
        testModel1.contactId=con.Id;
        List<ERP_AddressModel> testModels = new List<ERP_AddressModel>();
        testModels.add(testModel1);
        testModels.add(testModel);
        String jsonString = JSON.serialize(testModels);
        Test.startTest();
        Map<String,Object> result;
        System.runAs(u){
           result=ECOM_ContactController.createERPAddresses(jsonString, 'testAddress'); 
        }
        Test.stopTest();
        
        system.assertEquals(true,result.get('success'),'value mismatch');
    }

    @isTest
    static void checkSoldToERPAddressTest1(){
        User u = [Select Id,LastName,ContactId From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Account acc = [SELECT Id,Name FROM Account where Name ='TestClass Account'];
        ERP_Address__c masterAddress = [SELECT Id FROM ERP_Address__c where Address_Type__c='Master'];
        masterAddress.ECOM_Review_Status__c = 'Approved';
        update masterAddress;
        insert ECOM_TestUtil.createErpaddressSoldTo(acc.Id);
        ERP_Address__c soldTo = [SELECT Id,Account__c,Name FROM ERP_Address__c where Address_Type__c='Sold To' LIMIT 1];
        System.runAs(u){
            Test.startTest();
            Map<String,Object> result = ECOM_ContactController.checkSoldToERPAddress(soldTo.Name, 'test12345');
            System.assertEquals(false,result.get('success'),'Value mismatch');
            Test.stopTest();
        }        
    }
    //RWPS-1506 end
    
     //RWPS-5118 Start 
    @isTest
    static void testGetAddressDetails_ExceptionHandling() {
        // Test exception handling in getAddressDetails
        Test.startTest();
        Map<String,Object> result = ECOM_ContactController.getAddressDetails();
        Test.stopTest();
        
        // Should not throw an exception
        System.assertNotEquals(null, result);
    }
    
    @isTest
    static void testSaveSoldToERPAddress_ExceptionHandling() {
        // Test exception handling in saveSoldToERPAddress
        Test.startTest();
        Map<String,Object> result = ECOM_ContactController.saveSoldToERPAddress('invalid_id', 'invalid_id', 'invalid_reg');
        Test.stopTest();
        
        // Should not throw an exception
        System.assertNotEquals(null, result);
    }
    
    @isTest
    static void testUpdateShiptToAndBillTo_ExceptionHandling() {
        // Test exception handling in updateShiptToAndBillTo
        Test.startTest();
        Map<String,Object> result = ECOM_ContactController.updateShiptToAndBillTo('invalid_id', 'invalid_id', 'invalid_id', 'invalid_id', 'invalid_id', 'invalid_reg', 'test');
        Test.stopTest();
        
        // Should not throw an exception
        System.assertNotEquals(null, result);
    }
    
    @isTest
    static void testSaveContact_WithPhone() {
        User u = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Contact con = [Select Id, FirstName,Phone From Contact LIMIT 1];
        con.Phone = '1234567890';
        
        Test.startTest();
        Map<String, Object> result;
        System.runAs(u){
            result = ECOM_ContactController.saveContact(con);
        }
        Test.stopTest();
        
        // Verify that phone was updated
        System.assertNotEquals(null, result.get('Contact'));
    }
    
    @isTest
    static void testgetContactBasedOnId_NoAddresses() {
        Contact con = [Select Id ,FIrstName From Contact LIMIT 1];
        User u = [Select Id,LastName,ContactId From User Where ContactId = :con.Id ORDER BY CREATEDDATE DESC LIMIT 1];
        
        Test.startTest();
        System.runAs(u){
            Map<String,Object> result = ECOM_ContactController.getContactBasedOnId(con.Id);
            System.assertEquals(true, result.get('success'));
        }
        Test.stopTest();
    }
    
    @isTest
    static void getAddressDetailsTestCase4_NullRegistration() {
        User u = [Select Id,LastName,ContactId From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Contact con = [Select Id ,ECOM_CountryProvided__c From Contact Where Id = :u.ContactId];
        con.ECOM_AddressRegistration__c = null;
        update con;
        
        Test.startTest();
        Map<String,Object> result;
        System.runAs(u){
            result = ECOM_ContactController.getAddressDetails();
        }
        Test.stopTest();
        
        System.assertEquals(true, result.get('success'));
    }
    
    @isTest
    static void saveSoldToERPAddressTest3_WithNullValues() {
        User u = [Select Id,LastName,ContactId From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Test.startTest();
        Map<String,Object> result;
        System.runAs(u){
            result = ECOM_ContactController.saveSoldToERPAddress(null, null, null);
        }
        Test.stopTest();
        
        // Should not throw an exception
        System.assertNotEquals(null, result);
    }
    
    @isTest
    static void updateShiptToAndBillToTest_Error() {
        User u = [Select Id,LastName,ContactId From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        ERP_Address__c testAdd = new ERP_Address__c();
        insert testAdd;
        
        Test.startTest();
        Map<String,Object> result;
        System.runAs(u){
            result = ECOM_ContactController.updateShiptToAndBillTo(con.Id, testAdd.Id, testAdd.Id, testAdd.Id, testAdd.Id, 'Invalid', 'Test');
        }
        Test.stopTest();
        
        // Should not fail even with invalid address registration
        System.assertNotEquals(null, result);
    }
    
    @isTest
    static void checkSoldToERPAddressTest2_ValidAccount() {
        User u = [Select Id,LastName,ContactId From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Contact con = [Select Id, ECOM_CountryProvided__c From Contact Where Id = :u.ContactId];
        con.ECOM_CountryProvided__c = 'United States';
        update con;
        
        Test.startTest();
        Map<String,Object> result;
        System.runAs(u){
            result = ECOM_ContactController.checkSoldToERPAddress('123456789', 'Select ST & BT');
        }
        Test.stopTest();
        
        // Should not throw an exception
        System.assertNotEquals(null, result);
    }
    
    @isTest
    static void checkSoldToERPAddressTest3_DisabledAccount() {
        User u = [Select Id,LastName,ContactId From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Test.startTest();
        Map<String,Object> result;
        System.runAs(u){
            result = ECOM_ContactController.checkSoldToERPAddress('1234567890', 'Select ST & BT');
        }
        Test.stopTest();
        
        // Should not throw an exception
        System.assertNotEquals(null, result);
    }
    
    @isTest
    static void fetchNewERPAddressesTest2() {
        User u = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Test.startTest();
        Map<String,Object> response;
        System.runAs(u){
            response = ECOM_ContactController.fetchNewERPAddresses();
        }
        Test.stopTest();
        
        // Verify response structure
        System.assertNotEquals(null, response.get('success'));
        System.assertNotEquals(null, response.get('erpAddresses'));
    }
    
    // Specific tests for uncovered code paths
    @isTest
    static void testCreateLoginActivity_StatusSuccess() {
        // Test the Status Success assignment in createLoginActivity
        Map<String,String> requestMap = new Map<String,String>();
        requestMap.put('loggedInContactId','test');
        Test.startTest();
        Map<String,String> result = ECOM_ContactController.createLoginActivity(requestMap);
        Test.stopTest();
        
        // Verify that Status is set to Success
        System.assertEquals('Success', result.get('Status'));
    }
    
    @isTest
    static void testCreateERPAddresses_ContactIdAssignment() {
        // Test the contactId assignment in createERPAddresses
        ECOM_DummyAccountCountryMapping__mdt item = [SELECT Id,Dummy_Account__c,Country__c FROM ECOM_DummyAccountCountryMapping__mdt WHERE Dummy_Account__c!=NULL AND Country__c!=NULL LIMIT 1];
        Account acc = new Account();
        acc.Name = item.Dummy_Account__c;
        insert acc;
        User u = [Select Id,LastName,ContactId From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Contact con = [Select Id ,ECOM_CountryProvided__c From Contact Where Id = :u.ContactId];
        con.ECOM_CountryProvided__c = item.Country__c;
        update con;
        ERP_Address__c testAdd = new ERP_Address__c();
        insert testAdd;
        ERP_AddressModel testModel = new ERP_AddressModel();
        testModel.id=testAdd.Id;
        testModel.externalId='test123';
        testModel.addressType='Ship To';
        testModel.ecomReviewStatus='New';
        testModel.contactId=con.Id;
        List<ERP_AddressModel> testModels = new List<ERP_AddressModel>();
        testModels.add(testModel);
        String jsonString = JSON.serialize(testModels);
        Test.startTest();
        Map<String,Object> result;
        System.runAs(u){
           result=ECOM_ContactController.createERPAddresses(jsonString, 'testAddress'); 
        }
        Test.stopTest();
        
        // Should not throw an exception
        System.assertNotEquals(null, result);
    }
    
    @isTest
    static void testCreateERPAddresses_InvoiceErpIdAssignment() {
        // Test the invoiceErpId assignment in createERPAddresses
        ECOM_DummyAccountCountryMapping__mdt item = [SELECT Id,Dummy_Account__c,Country__c FROM ECOM_DummyAccountCountryMapping__mdt WHERE Dummy_Account__c!=NULL AND Country__c!=NULL LIMIT 1];
        Account acc = new Account();
        acc.Name = item.Dummy_Account__c;
        insert acc;
        User u = [Select Id,LastName,ContactId From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Contact con = [Select Id ,ECOM_CountryProvided__c From Contact Where Id = :u.ContactId];
        con.ECOM_CountryProvided__c = item.Country__c;
        update con;
        ERP_Address__c testAdd = new ERP_Address__c();
        insert testAdd;
        ERP_AddressModel testModel = new ERP_AddressModel();
        testModel.id=testAdd.Id;
        testModel.externalId='test123';
        testModel.addressType='Bill To';
        testModel.ecomReviewStatus='New';
        testModel.contactId=con.Id;
        List<ERP_AddressModel> testModels = new List<ERP_AddressModel>();
        testModels.add(testModel);
        String jsonString = JSON.serialize(testModels);
        Test.startTest();
        Map<String,Object> result;
        System.runAs(u){
           result=ECOM_ContactController.createERPAddresses(jsonString, 'testAddress'); 
        }
        Test.stopTest();
        
        // Should not throw an exception
        System.assertNotEquals(null, result);
    }
    //RWPS-5118 END
}