/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-928
*
* 2. Description 
*   - This class is a test class for ERP_AddressUtil
*
* 3. Objects referenced
*    - ERP Address
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
* 5. Dependant Class(es):
*    
*
* 6. Test Class Name: 
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Rani Thumma 2023.10.10
*    - Vipul Goyal 2024.01.31 Ticket - RWPS-100
*	 - vramachandran@rafter.one | 10 Feb 2023 : ECOM-2504 - updates for test code coverage
*    - Sidak Singh 2024.05.01 Ticket - RWPS-564. Updated methods testconvertERPAddressesToModel2, testconvertERPAddressesToModel3, testconvertERPToAddressModel4, testconvertNewERPAddressesToShipToList
*    - Sidak 2024.11.21 Updated method getPunchoutAccountIdListTest, updated List to Map
*    - Poonam 2026.03.11 Added method testconvertNewERPAddressesToShipToListCase1, getPunchoutAddressesForAccountIdCase1 and Updated testRepoMethods to increase code coverage RWPS-5776
*************************************************************/
@isTest
public class ERP_AddressUtil_Test {
    @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
        
    }
    
    @isTest
    static void testconvertERPToAddressModel(){
        Account testAccount = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1 ];
        Contact testContact = [SELECT Id ,Name,AccountId,ECOM_CountryProvided__c FROM Contact WHERE AccountId=:testAccount.Id LIMIT 1];//RWPS-3740
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
        
         Test.startTest();
        
        // Call the method in the test context
        system.runAs(testUser){
        ERP_AddressUtil.convertERPToAddressModel(newAdd);
        }
        
        // Stop the test context
        Test.stopTest();
    }
    
    @isTest
    static void testconvertERPToAddressModel2(){
        Account testAccount = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1 ];
        Contact testContact = [SELECT Id ,Name,AccountId,ECOM_CountryProvided__c FROM Contact WHERE AccountId=:testAccount.Id limit 1];//RWPS-3740
        User testUser = [Select Id,ContactId From User WHERE ContactId=:testContact.Id ORDER BY CREATEDDATE DESC LIMIT 1];
        testContact.ECOM_CountryProvided__c='United States';
        update testContact;
        
        ERP_Address__c newAdd1 = new ERP_Address__c();
        newAdd1.Contact__c=testContact.Id;
        newAdd1.Account__c = testAccount.id;
        newAdd1.Address_Type__c='Master';
        newAdd1.ECOM_Review_Status__c=null;
        newAdd1.SAP_Name_1__c = 'testsapname1';
        newAdd1.SAP_Name_2__c = 'testsapname2';
        newAdd1.SAP_Name_3__c = 'testsapname3';
        newAdd1.ECOM_Review_Status__c = 'New';
        newAdd1.SAP_Name_1__c = 'Test';
        insert newAdd1;
        
        ERP_Address__c newAdd = new ERP_Address__c();
        newAdd.Contact__c=testContact.Id;
        newAdd.Account__c = testAccount.id;
        newAdd.Address_Type__c='Ship To';
        newAdd.ECOM_Review_Status__c=null;
        newAdd.SAP_Name_1__c = 'testsapname1';
        newAdd.SAP_Name_2__c = 'testsapname2';
        newAdd.SAP_Name_3__c = 'testsapname3';
        newAdd.ECOM_Review_Status__c = 'New';
        newAdd.Target_Address__c = newAdd1.Id;
        insert newAdd;
        
         Test.startTest();
        
        // Call the method in the test context
        system.runAs(testUser){
        ERP_AddressUtil.convertERPToAddressModel(newAdd);
        }
        
        // Stop the test context
        Test.stopTest();
    }
    
    @isTest
    static void testconvertERPAddressesToModel(){
        Account testAccount = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1 ];
        Contact testContact = [SELECT Id ,Name,AccountId,ECOM_CountryProvided__c FROM Contact WHERE AccountId=:testAccount.Id limit 1];//RWPS-3740
        User testUser = [Select Id,ContactId, Contact.Default_Ship_to_ERP_Address__c, Contact.Default_Bill_to_ERP_Address__c, Contact.Default_Invoice_ERP_Address__c From User WHERE ContactId=:testContact.Id ORDER BY CREATEDDATE DESC LIMIT 1];
        testContact.ECOM_CountryProvided__c='United States';
        update testContact;
        ERP_Address__c newMaster = new ERP_Address__c();
        newMaster.Contact__c=testContact.Id;
        newMaster.Account__c = testAccount.id;
        newMaster.Address_Type__c='Master';
        newMaster.ECOM_Review_Status__c='Approved';
        newMaster.SAP_Name_1__c = 'testsapname1';
        newMaster.SAP_Name_2__c = 'testsapname2';
        newMaster.SAP_Name_3__c = 'testsapname3';
        insert newMaster;
        ERP_Address__c newSoldTo = new ERP_Address__c();
        newSoldTo.Account__c = testAccount.id;
        newSoldTo.Address_Type__c='Ship To';
        newSoldTo.Target_Address__c = newMaster.Id;
        newSoldTo.Master_Address__c = newMaster.Id;
        newSoldTo.ECOM_Review_Status__c='Approved';
        newSoldTo.SAP_Name_1__c = 'testsapname1';
        newSoldTo.SAP_Name_2__c = 'testsapname2';
        newSoldTo.SAP_Name_3__c = 'testsapname3';
        insert newSoldTo;
        ERP_Address__c newAdd = new ERP_Address__c();
        newAdd.Account__c = testAccount.id;
        newAdd.Address_Type__c='Payer';
        newAdd.Target_Address__c = newMaster.Id;
        newAdd.Master_Address__c = newMaster.Id;
        newAdd.ECOM_Review_Status__c='Approved';
        newAdd.SAP_Name_1__c = 'testsapname1';
        newAdd.SAP_Name_2__c = 'testsapname2';
        newAdd.SAP_Name_3__c = 'testsapname3';
        insert newAdd;
        ERP_Address__c newAdd1 = new ERP_Address__c();
        newAdd1.Account__c = testAccount.id;
        newAdd1.Address_Type__c='Bill To';
        newAdd1.Target_Address__c = newMaster.Id;
        newAdd1.Master_Address__c = newMaster.Id;
        newAdd1.ECOM_Review_Status__c='Approved';
        newAdd1.SAP_Name_1__c = 'testsapname1';
        newAdd1.SAP_Name_2__c = 'testsapname2';
        newAdd1.SAP_Name_3__c = 'testsapname3';
        insert newAdd1;
        List<ERP_Address__c> erpAddresses = new List<ERP_Address__c>();
        erpAddresses.add(newAdd);
        erpAddresses.add(newAdd1);
        erpAddresses.add(newSoldTo);
         Test.startTest();
        
        // Call the method in the test context
        system.runAs(testUser){
        ERP_AddressUtil.convertERPAddressesToModel(erpAddresses);
            List<ECOM_MyAccountModel> models = ERP_AddressUtil.convertERPAddressesToModel(erpAddresses, testUser);
        }
        
        // Stop the test context
        Test.stopTest();
    }
    
    @isTest
    static void testconvertERPAddressesToModel2(){
        Account testAccount = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1 ];
        Contact testContact = [SELECT Id ,Name,AccountId,ECOM_CountryProvided__c,ECOM_AccountNameProvided__c FROM Contact WHERE AccountId=:testAccount.Id LIMIT 1];//RWPS-3740
        User testUser = [Select Id,ContactId, Contact.Default_Ship_to_ERP_Address__c, Contact.ECOM_AccountNameProvided__c, Contact.Default_Bill_to_ERP_Address__c, Contact.Default_Invoice_ERP_Address__c From User WHERE ContactId=:testContact.Id ORDER BY CREATEDDATE DESC LIMIT 1];
        testContact.ECOM_CountryProvided__c='United States';
        update testContact;
        ERP_Address__c newAdd = new ERP_Address__c();
        newAdd.Contact__c=testContact.Id;
        newAdd.Account__c = testAccount.id;
        newAdd.Address_Type__c='Ship To';
        newAdd.ECOM_Review_Status__c='New';
        newAdd.SAP_Name_1__c = 'testsapname1';
        newAdd.SAP_Name_2__c = 'testsapname2';
        newAdd.SAP_Name_3__c = 'testsapname3';
        insert newAdd;
        
        List<ERP_Address__c> erpAddresses = new List<ERP_Address__c>();
        erpAddresses.add(newAdd);
         Test.startTest();
        
        // Call the method in the test context
        system.runAs(testUser){
        ERP_AddressUtil.convertERPAddressesToModel(erpAddresses);
            List<ECOM_MyAccountModel> models = ERP_AddressUtil.convertERPAddressesToModel(erpAddresses, testUser);
        }
        
        // Stop the test context
        Test.stopTest();
    }
    
    @isTest
    static void testconvertERPAddressesToModel3(){
        Account testAccount = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1 ];
        Contact testContact = [SELECT Id ,Name,AccountId,ECOM_CountryProvided__c,ECOM_AccountNameProvided__c FROM Contact WHERE AccountId=:testAccount.Id LIMIT 1];//RWPS-3740
        User testUser = [Select Id,ContactId, Contact.Default_Ship_to_ERP_Address__c, Contact.ECOM_AccountNameProvided__c, Contact.Default_Bill_to_ERP_Address__c, Contact.Default_Invoice_ERP_Address__c From User WHERE ContactId=:testContact.Id ORDER BY CREATEDDATE DESC LIMIT 1];
        testContact.ECOM_CountryProvided__c='United States';
        update testContact;
        ERP_Address__c newAdd = new ERP_Address__c();
        newAdd.Contact__c=testContact.Id;
        newAdd.Account__c = testAccount.id;
        newAdd.Address_Type__c='Payer';
        newAdd.ECOM_Review_Status__c='New';
        newAdd.SAP_Name_1__c = 'testsapname1';
        newAdd.SAP_Name_2__c = 'testsapname2';
        newAdd.SAP_Name_3__c = 'testsapname3';
        insert newAdd;
        
        List<ERP_Address__c> erpAddresses = new List<ERP_Address__c>();
        erpAddresses.add(newAdd);
         Test.startTest();
        
        // Call the method in the test context
        system.runAs(testUser){
        ERP_AddressUtil.convertERPAddressesToModel(erpAddresses);
            List<ECOM_MyAccountModel> models = ERP_AddressUtil.convertERPAddressesToModel(erpAddresses, testUser);
        }
        
        // Stop the test context
        Test.stopTest();
    }
    
        @isTest
    static void testconvertERPAddressesToModel4(){
        Account testAccount = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1 ];
        Contact testContact = [SELECT Id ,Name,AccountId,ECOM_CountryProvided__c FROM Contact WHERE AccountId=:testAccount.Id LIMIT 1];//RWPS-3740
        User testUser = [Select Id,ContactId, Contact.Default_Ship_to_ERP_Address__c, Contact.Default_Bill_to_ERP_Address__c, Contact.Default_Invoice_ERP_Address__c From User WHERE ContactId=:testContact.Id ORDER BY CREATEDDATE DESC LIMIT 1];
        testContact.ECOM_CountryProvided__c='United States';
        update testContact;
        ERP_Address__c newAdd = new ERP_Address__c();
        newAdd.Contact__c=testContact.Id;
        newAdd.Account__c = testAccount.id;
        newAdd.Address_Type__c='Ship To';
        newAdd.ECOM_Review_Status__c='Approved';
        newAdd.SAP_Name_1__c = 'testsapname1';
        newAdd.SAP_Name_2__c = 'testsapname2';
        newAdd.SAP_Name_3__c = 'testsapname3';
        insert newAdd;
        
        List<ERP_Address__c> erpAddresses = new List<ERP_Address__c>();
        erpAddresses.add(newAdd);
         Test.startTest();
        
        // Call the method in the test context
        system.runAs(testUser){
        ERP_AddressUtil.convertERPAddressesToModel(erpAddresses);
            List<ECOM_MyAccountModel> models = ERP_AddressUtil.convertERPAddressesToModel(erpAddresses, testUser);
        }
        
        // Stop the test context
        Test.stopTest();
    }
    
    @isTest
    static void testconvertNewERPAddressesToShipToList(){
        
        Account testAccount = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1 ];
        Contact testContact = [SELECT Id ,Name,AccountId,ECOM_CountryProvided__c FROM Contact WHERE AccountId=:testAccount.Id limit 1];//RWPS-3740
        User testUser = [Select Id,ContactId, Contact.Default_Ship_to_ERP_Address__c, Contact.Default_Bill_to_ERP_Address__c, Contact.Default_Invoice_ERP_Address__c From User WHERE ContactId=:testContact.Id ORDER BY CREATEDDATE DESC LIMIT 1];
        testContact.ECOM_CountryProvided__c='United States';
        update testContact;
        ERP_Address__c newAdd = new ERP_Address__c();
        newAdd.Contact__c=testContact.Id;
        newAdd.Account__c = testAccount.id;
        newAdd.Address_Type__c='Payer';
        newAdd.ECOM_Review_Status__c='Approved';
        newAdd.SAP_Name_1__c = 'testsapname1';
        newAdd.SAP_Name_2__c = 'testsapname2';
        newAdd.SAP_Name_3__c = 'testsapname3';
        
        insert newAdd;
        
        List<ERP_Address__c> erpAddresses = new List<ERP_Address__c>();
        erpAddresses.add(newAdd);
        Test.startTest();
        
        // Call the method in the test context
        System.runAs(testUser){
        	ERP_AddressUtil.convertNewERPAddressesToShipToList(erpAddresses, testUser);
        	ERP_AddressModel model = ERP_AddressUtil.convertNewERPAddressesToShipToList(erpAddresses, testUser);
        }
        
        // Stop the test context
        Test.stopTest();
    }
    
    @isTest
    static void testcreateDummySoldTo(){
        Test.startTest();
        ERP_AddressUtil.createDummySoldTo();
        Test.stopTest();
    }
    
    @isTest
    public static void mapERPModelToSObjectTest(){
        List<ERP_AddressModel> newErpAddresses = new List<ERP_AddressModel>();
        ERP_AddressModel erpAdd = new ERP_AddressModel();
        erpAdd.erpAccountName = 'Test Account';
        erpAdd.addressType  = 'Ship To';
        erpAdd.street = '123 main st';
        erpAdd.city = 'MainCity';
        erpAdd.state = 'New York';
        erpAdd.postalCode = '09909';
        erpAdd.country = 'United States';
        erpAdd.isEcomEnabled = true;
        erpAdd.ecomReviewStatus = 'New';
        newErpAddresses.add(erpAdd);
        List<ERP_Address__c>  erps = ERP_AddressUtil.mapErpRequestToSObject(newErpAddresses);
    }
    
    @isTest
    static void getERPAddressModelForPunchoutAccountIdTest(){
        User user = [SELECT Id,AccountId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        Account testAccount = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
       	ERP_Address__c masterAdd = new ERP_Address__c();
        masterAdd.Address_Type__c = 'Master';
        masterAdd.ECOM_Review_Status__c = 'Approved';
        masterAdd.ECOM_isEnabled__c = true;
        masterAdd.ECOM_Punchout_Is_Enabled__c = true;
        masterAdd.ECOM_Punchout_Customer_Id__c = 'test';
        insert masterAdd;
        ERP_Address__c testAdd = new ERP_Address__c();
        testAdd.ECOM_Review_Status__c = 'Approved';
        testAdd.Account__c = testAccount.Id;
        testAdd.ECOM_isEnabled__c = true;
        testAdd.ECOM_Punchout_Is_Enabled__c = true;
        testAdd.Address_Type__c = 'Ship To';
        testAdd.Master_Address__c = masterAdd.Id;
        testAdd.Target_Address__c = masterAdd.Id;
        testAdd.ERP_Marked_for_Deletion__c = false;
        testAdd.ECOM_Punchout_Customer_Id__c = 'test';
        insert testAdd;
        Test.startTest();
        ERP_AddressModel response = ERP_AddressUtil.getERPAddressModelForPunchoutAccountId(testAccount.Id);
        Test.stopTest();
    }
    
    @isTest
    static void getMasterERPAddressModelForPunchoutUserTest(){
    	User user = [SELECT Id,AccountId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        Account testAccount = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
       	ERP_Address__c masterAdd = new ERP_Address__c();
        masterAdd.Address_Type__c = 'Master';
        masterAdd.ECOM_Review_Status__c = 'Approved';
        masterAdd.ECOM_isEnabled__c = true;
        masterAdd.ECOM_Punchout_Is_Enabled__c = true;
        masterAdd.ECOM_Punchout_Customer_Id__c = 'test';
        insert masterAdd;
        ERP_Address__c testAdd = new ERP_Address__c();
        testAdd.ECOM_Review_Status__c = 'Approved';
        testAdd.Account__c = testAccount.Id;
        testAdd.ECOM_isEnabled__c = true;
        testAdd.ECOM_Punchout_Is_Enabled__c = true;
        testAdd.Address_Type__c = 'Ship To';
        testAdd.Master_Address__c = masterAdd.Id;
        testAdd.Target_Address__c = masterAdd.Id;
        testAdd.ERP_Marked_for_Deletion__c = false;
        testAdd.ECOM_Punchout_Customer_Id__c = 'test';
        insert testAdd;
        Test.startTest();
        ERP_AddressModel response = ERP_AddressUtil.getMasterERPAddressModelForPunchoutUser(user);
        Test.stopTest();
    }
    
    @isTest
    static void getPunchoutAccountIdListTest(){
        Account testAccount = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
        ERP_Address__c testAdd = new ERP_Address__c();
        testAdd.ECOM_Punchout_Is_Enabled__c = true;
        testAdd.Account__c = testAccount.Id;
        insert testAdd;
        Test.startTest();
        Map<String,String> response = ERP_AddressUtil.getPunchoutAccountIdList();
        Test.stopTest();
    }
    
    @isTest
    static void getPunchoutAddressesForERPAddressModelTest(){
        Account testAccount = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
       	ERP_Address__c masterAdd = new ERP_Address__c();
        masterAdd.Address_Type__c = 'Master';
        masterAdd.ECOM_Review_Status__c = 'Approved';
        masterAdd.ECOM_isEnabled__c = true;
        masterAdd.ECOM_Punchout_Is_Enabled__c = true;
        masterAdd.ECOM_Punchout_Customer_Id__c = 'test';
        insert masterAdd;
        ERP_Address__c testAdd = new ERP_Address__c();
        testAdd.ECOM_Review_Status__c = 'Approved';
        testAdd.Account__c = testAccount.Id;
        testAdd.ECOM_isEnabled__c = true;
        testAdd.ECOM_Punchout_Is_Enabled__c = true;
        testAdd.Address_Type__c = 'Ship To';
        testAdd.Master_Address__c = masterAdd.Id;
        testAdd.Target_Address__c = masterAdd.Id;
        testAdd.ERP_Marked_for_Deletion__c = false;
        testAdd.ECOM_Punchout_Customer_Id__c = 'test';
        insert testAdd;
        Test.startTest();
        ERP_AddressModel response = ERP_AddressUtil.getPunchoutAddressesForERPAddressModel('test');
        Test.stopTest();
    }
    
    @isTest
    static void getPunchoutAddressesForAccountIdTest(){
   		Account testAccount = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
        system.debug('before: '+[SELECT Id FROM ERP_Address__c WHERE Account__c=:testAccount.Id]);
       	ERP_Address__c masterAdd = new ERP_Address__c();
        masterAdd.Address_Type__c = 'Master';
        masterAdd.ECOM_Review_Status__c = 'Approved';
        masterAdd.ECOM_isEnabled__c = true;
        masterAdd.ECOM_Punchout_Is_Enabled__c = true;
        insert masterAdd;
        ERP_Address__c testAdd = new ERP_Address__c();
        testAdd.ECOM_Review_Status__c = 'Approved';
        testAdd.Account__c = testAccount.Id;
        testAdd.ECOM_isEnabled__c = true;
        testAdd.ECOM_Punchout_Is_Enabled__c = true;
        testAdd.Address_Type__c = 'Ship To';
        testAdd.Master_Address__c = masterAdd.Id;
        testAdd.Target_Address__c = masterAdd.Id;
        testAdd.ERP_Marked_for_Deletion__c = false;
        insert testAdd;
        Test.startTest();
        ERP_AddressModel response = ERP_AddressUtil.getPunchoutAddressesForAccountId(testAccount.Id);
        Test.stopTest();
    }

    
    @isTest
    static void testconvertERPToAddressModel3(){
        Account testAccount = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1 ];
        Contact testContact = [SELECT Id ,Name,AccountId,ECOM_CountryProvided__c FROM Contact WHERE AccountId=:testAccount.Id LIMIT 1];//RWPS-3740
        User testUser = [Select Id,ContactId, Contact.Default_Bill_to_ERP_Address__c, Contact.Default_Ship_to_ERP_Address__c,Contact.Default_Sold_to_ERP_Address__c, Contact.Default_Invoice_ERP_Address__c  From User WHERE ContactId=:testContact.Id ORDER BY CREATEDDATE DESC LIMIT 1];
        testContact.ECOM_CountryProvided__c='United States';
        update testContact;
        ERP_Address__c newAdd = new ERP_Address__c();
        newAdd.Contact__c=testContact.Id;
        newAdd.Account__c = testAccount.id;
        newAdd.Address_Type__c='Sold To';
        newAdd.ECOM_Review_Status__c=null;
         newAdd.SAP_Name_1__c = 'testsapname1';
            newAdd.SAP_Name_2__c = 'testsapname2';
            newAdd.SAP_Name_3__c = 'testsapname3';
        insert newAdd;
		
         Test.startTest();
        
        // Call the method in the test context
        system.runAs(testUser){
            ERP_AddressUtil.convertERPAddressesToModel(new List<ERP_Address__c>{newAdd}, testUser);
        }
        
        // Stop the test context
        Test.stopTest();
    }
    
    @isTest
    static void testconvertERPToAddressModel4(){
        Account testAccount = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1 ];
        Contact testContact = [SELECT Id ,Name,AccountId,ECOM_CountryProvided__c,ECOM_AccountNameProvided__c FROM Contact WHERE AccountId=:testAccount.Id LIMIT 1];//RWPS-3740
        User testUser = [Select Id,ContactId, Contact.Default_Bill_to_ERP_Address__c, Contact.Default_Invoice_ERP_Address__c, Contact.ECOM_AccountNameProvided__c, Contact.Default_Ship_to_ERP_Address__c,Contact.Default_Sold_to_ERP_Address__c  From User WHERE ContactId=:testContact.Id ORDER BY CREATEDDATE DESC LIMIT 1];
        testContact.ECOM_CountryProvided__c='United States';
        update testContact;
        ERP_Address__c newAdd = new ERP_Address__c();
        newAdd.Contact__c=testContact.Id;
        newAdd.Account__c = testAccount.id;
        newAdd.Address_Type__c='Payer';
        newAdd.ECOM_Review_Status__c='New';
         newAdd.SAP_Name_1__c = 'testsapname1';
            newAdd.SAP_Name_2__c = 'testsapname2';
            newAdd.SAP_Name_3__c = 'testsapname3';
        insert newAdd;
		
         Test.startTest();
        
        // Call the method in the test context
        system.runAs(testUser){
            ERP_AddressUtil.convertERPAddressesToModel(new List<ERP_Address__c>{newAdd}, testUser);
        }
        
        // Stop the test context
        Test.stopTest();
    }
    
    @isTest
    static void testRepoMethods(){
       Account testAccount = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];//RWPS-5776
       Contact testContact = [SELECT Id ,Name,AccountId,ECOM_CountryProvided__c,ECOM_AccountNameProvided__c FROM Contact WHERE AccountId=:testAccount.Id LIMIT 1];//RWPS-5776
        Test.startTest();
        ERP_AddressRepo.fetchERPAddressesByIds(new List<String>(), '');
        ERP_AddressRepo.getErpAddressForAccountId('', new List<String>());
        ERP_AddressRepo.getErpAddressForAccountId('', null);        
        //RWPS-5776 start
        ERP_AddressRepo.getAccountsFromAcrBasedOnContact(testContact.Id);      
        ERP_AddressRepo.getAccountsFromAcrBasedOnContact(null);        
        ERP_AddressRepo.getPunchoutMasterERPAddressesMasterIds( new List<String>());
        //RWPS-5776 end
        Test.stopTest();
    }
    
    //RWPS-5776 start
    @isTest
    static void testconvertNewERPAddressesToShipToListCase1(){
        Account testAccount = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1 ];
        User testUser = [SELECT Id, Email, ContactId, AccountId, ECOM_Is_Punchout_User__c FROM User ORDER BY CreatedDate DESC LIMIT 1];
        List<ERP_Address__c> erpAddresses = new List<ERP_Address__c>();
        System.runAs(new User(Id = UserInfo.getUserId())) {
        testUser.ECOM_Is_Punchout_User__c = true;
        update testUser;
        Contact testContact = [SELECT Id, Default_Ship_to_ERP_Address__r.Master_Address__c FROM Contact WHERE Id = :testUser.ContactId];
        if(testContact.Default_Ship_to_ERP_Address__r != null){
            String masterAddressId = testContact.Default_Ship_to_ERP_Address__r.Master_Address__c;
            ERP_Address__c newAdd = new ERP_Address__c();
            newAdd.Account__c = testAccount.Id;
            newAdd.Address_Type__c = 'Payer';
            newAdd.ECOM_Review_Status__c = 'Approved';
            newAdd.SAP_Name_1__c = 'testsapname1';
            newAdd.SAP_Name_2__c = 'testsapname2';
            newAdd.SAP_Name_3__c = 'testsapname3';
            newAdd.Target_Address__c = masterAddressId;
            newAdd.Master_Address__c = masterAddressId;
            insert newAdd;
            erpAddresses.add(newAdd);
        }

        Test.startTest();
        ERP_AddressModel model = ERP_AddressUtil.convertNewERPAddressesToShipToList(erpAddresses, testUser);
        Test.stopTest();
    }
    }
   
    @isTest
    static void getPunchoutAddressesForAccountIdCase1(){
   		Account testAccount = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
        system.debug('before: '+[SELECT Id FROM ERP_Address__c WHERE Account__c=:testAccount.Id]);
       	ERP_Address__c masterAdd = new ERP_Address__c();
        masterAdd.Address_Type__c = 'Master';
        masterAdd.ECOM_Review_Status__c = 'Approved';
        masterAdd.ECOM_isEnabled__c = true;
        masterAdd.ECOM_Punchout_Is_Enabled__c = true;
        insert masterAdd;
        ERP_Address__c testAdd = new ERP_Address__c();
        testAdd.ECOM_Review_Status__c = 'Approved';
        testAdd.Account__c = testAccount.Id;
        testAdd.ECOM_isEnabled__c = true;
        testAdd.ECOM_Punchout_Is_Enabled__c = true;
        testAdd.Address_Type__c = 'Payer';
        testAdd.Master_Address__c = masterAdd.Id;
        testAdd.Target_Address__c = masterAdd.Id;
        testAdd.ERP_Marked_for_Deletion__c = false;
        insert testAdd;
        Test.startTest();
        ERP_AddressModel response = ERP_AddressUtil.getPunchoutAddressesForAccountId(testAccount.Id);
        Test.stopTest();
    }//RWPS-5776 end
    
    
}