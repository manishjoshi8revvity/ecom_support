/**************************************************************

* 1. Jira Ticket(s) that relates to this class
*  
* 2. Description - This class is a test class for ECOM_AccountRepo
					- Call the ECOM_TestUtilClass to create test data and test each methods.
					- Used System Assertion to Confirm the functionalities.
*
* 3. Objects referenced
*    - Account
*    - Contact
*    - User
*    - WebStore
*    - WishList
*    - Product2
*    - WishListItem
*    - ECOM_Email_Preferences__c
* 
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_TestUtil
*    - ECOM_AccountRepo
*
* 6. Test Class Name:
*    -None
*
* 7. Is @Invocable : No
*
* 8. Author Name(s):
*    - Manoj 2023.09.19
*    - Poonam 2025.07.02 Added testdeleteNonSellableWishListItems, testremoveWishListItems,testGetDummyAccountByName, testGetPunchoutAccountsForAccountIds for increase code coverage - RWPS-2786
*************************************************************/


@isTest(SeeAllData=false)
private with sharing class ECOM_AccountRepo_Test {
    
    //String constant for reused texts
    public static final String REVVITY_ACCOUNT ='Test Revvity Account';
    
    //Creating test data
    @TestSetup
    static void setupTestData() {
        
        //Creating WebStore
        WebStore testWebStore = ECOM_TestUtil.prepareWebStore(ECOM_TestUtil.STORE_NAME);
        insert testWebStore;

        // Creating Account, Contact and User
        Account testAccount= ECOM_TestUtil.createAccount();
        Contact testContact = ECOM_TestUtil.createContact(testAccount);
        User portalUser = ECOM_TestUtil.createPortalUser(testContact);
        
        //Creating WishList
        WishList testWishList=ECOM_TestUtil.createWishlist(testAccount,portalUser,testWebStore);
        insert testWishList;
        
        //creating product and WishListItems
        Product2 testProduct = ECOM_TestUtil.createProduct('TestProduct','1','TP123',True);
        WishlistItem testWishlistItems =  ECOM_TestUtil.createWishlistItem(testProduct.Id,testWishList.Id);
        
        //Creating List of ECOM_Email_Preferences__c
        List<ECOM_Email_Preferences__c> eepList=ECOM_TestUtil.createEmailpreferencesList(testAccount,testContact);
        
    }
    // Test method for fetchWishList
    @isTest
    static void testFetchWishList() {
        User testUser =  [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        
        //Calling the fetchWishList method
        Test.startTest();
        List<WishList> resultList;
        System.runAs(testUser){
             resultList = ECOM_AccountRepo.fetchWishList(testUser.Id);
        }
       
        Test.stopTest();
        
        //Validating Result
        System.assertEquals(1,resultList.size(),'Expected value was 1');

        
    }
    // Test method for fetchWishListById
    @isTest
    static void testFetchWishListById() {
        User testUser = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        WishList wList = [SELECT Id ,Name FROM WishList WHERE Name=:ECOM_TestUtil.WISHLIST_NAME];
        
        //Calling the  fetchWishListById method
        Test.startTest();
        List<WishList> resultList;
         resultList = ECOM_AccountRepo.fetchWishListById(wList.Id);
        Test.stopTest();
        
        //Validating result       
        System.assertEquals(1,resultList.size(),'Expected value was 1');

    }
    // Test method for getAccountBasedOnDomains
    /*@isTest
    static void testGetAccountBasedOnDomains() {
        User testUser = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Account testAccount = [SELECT Id ,Account_Domains__c, BillingStreet,BillingCity, 
                               BillingState,BillingPostalCode,
                               BillingCountry,ShippingStreet, ShippingCity, 
                               ShippingState, ShippingPostalCode,
                               ShippingCountry  FROM Account WHERE Name=:ECOM_TestUtil.REVVITY_ACCOUNT];
        String accountDomain = testAccount.Account_Domains__c;
       
        //Calling the getAccountBasedOnDomains method
        Test.startTest();
        List<Account> resultList = ECOM_AccountRepo.getAccountBasedOnDomains(accountDomain);
        Test.stopTest();
        
        //Validating Result
        System.assertEquals(1,resultList.size(),'Expected value was 1');
        System.assertEquals('121',resultList[0].BillingStreet,'Expected 121');

    }*/
    // Test method for getAccountBasedOnIds
    @isTest
    static void testGetAccountBasedOnIds() {
        User testUser = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Account testAccount = [SELECT Id ,Account_Domains__c, BillingStreet,BillingCity, 
                       BillingState,BillingPostalCode,
                       BillingCountry,ShippingStreet, ShippingCity, 
                       ShippingState, ShippingPostalCode,
                       ShippingCountry  FROM Account WHERE Name=:ECOM_TestUtil.REVVITY_ACCOUNT];
        String accountId = testAccount.Id;
        List<String> accIds = new List <String>();
        accIds.add(accountId);
        
        //Calling the getAccountBasedOnIds method
        Test.startTest();
        List<Account> resultList = ECOM_AccountRepo.getAccountBasedOnIds(accIds);
        Test.stopTest();
        
        //Validating result
        System.assertEquals(1,resultList.size(),'Expected value was 1');

    }
    
    // Test method for createCPAs
    /*@isTest
    static void testCreateCPAs() {
        User testUser = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        List<ContactPointAddress> cpaList = new List<ContactPointAddress>();
        ContactPointAddress cpa = new ContactPointAddress();
        cpa.AddressType='Billing';
        cpa.Country='United States';
        cpa.Name='Home';
        cpa.SAP_Contact_ID__c='testCId123';
        cpaList.add(cpa);
        
        //Calling the createCPAs method
        Test.startTest();
        List<ContactPointAddress> resultList = ECOM_AccountRepo.createCPAs(cpaList);
        Test.stopTest();
        
        //Validating results
        System.assertEquals(1,resultList.size(),'Expected value was 1');

    }*/
    // Test method for getEmailPreferences
    @isTest
    static void testGetEmailPreferences() {
        Account acc = [SELECT Id ,Name  FROM Account WHERE Name=:ECOM_TestUtil.REVVITY_ACCOUNT];
        User testUser = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        //Calling the getEmailPreferences method
        Test.startTest();
        List<ECOM_Email_Preferences__c> resultList = ECOM_AccountRepo.getEmailPreferences(acc.Id);
        Test.stopTest();
        
        //Validating results
        System.assertEquals(1,resultList.size(),'Expected value was 1');

    }
    // Test method for upsertEmailPreferences,deleteEmailPreferences
    @isTest
    static void testUpsertDeleteEmailPreferences() {
        Account testAccount=[SELECT Id,Name FROM Account WHERE Name=:ECOM_TestUtil.REVVITY_ACCOUNT];
        Contact testContact=[SELECT Id,Name FROM Contact WHERE AccountId=:testAccount.Id];
        User testUser = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        List<ECOM_Email_Preferences__c> eepList = new  List<ECOM_Email_Preferences__c>();
        ECOM_Email_Preferences__c eep = new ECOM_Email_Preferences__c();
        eep.ECOM_Account__c=testAccount.Id;
        eep.ECOM_Contact__c=testContact.Id;
        eep.ECOM_Email__c='test2@yopmail.com';
        eepList.add(eep);
        
        //Calling the upsertEmailPreferences and deleteEmailPreferences methods
        Test.startTest();
        ECOM_AccountRepo.upsertEmailPreferences(eepList);
        List<ECOM_Email_Preferences__c> upList=[SELECT ECOM_Account__c,ECOM_Contact__c,ECOM_Email__c FROM ECOM_Email_Preferences__c];
        System.assertEquals(2,upList.size(),'Expected value was 2');
        ECOM_AccountRepo.deleteEmailPreferences(eepList);
        List<ECOM_Email_Preferences__c> delList=[SELECT ECOM_Account__c,ECOM_Contact__c,ECOM_Email__c FROM ECOM_Email_Preferences__c];
        System.assertEquals(1,delList.size(),'Expected value was 1');
        Test.stopTest();
    }
    // Test method for upsertCPAs
    /*@isTest
    static void testUpsertCPAs() {
        User testUser = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        List<ContactPointAddress> cpaList = new List<ContactPointAddress>();
        ContactPointAddress cpa = new ContactPointAddress();
        cpa.AddressType='Shipping';
        cpa.Country='United States';
        cpa.Name='Office';
        cpa.SAP_Contact_ID__c='testCId123';
        cpaList.add(cpa);
        
        //Calling the upsertCPAs method
        Test.startTest();
        ECOM_AccountRepo.upsertCPAs(cpaList);
        List<ContactPointAddress> cpaResultList=[SELECT AddressType,Country,Name FROM ContactPointAddress];
        Test.stopTest();
        
        //Validating results
        System.assertEquals(1,cpaResultList.size(),'Expected value was 1');

    }
    // Test method for getCPAs, getCpaBasedOnContactAccountAndType, getCpaBasedOnContactAccountTypeAndStatus
    @isTest
    static void testGetCpa() {
        Account testAccount=[SELECT Id,Name FROM Account WHERE Name=:ECOM_TestUtil.REVVITY_ACCOUNT];
        String testAccountId=testAccount.Id;
        Contact testContact=[SELECT Id,Name FROM Contact WHERE AccountId=:testAccount.Id];
        String testContactId=testContact.Id;
        User testUser = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        List<String> reviewStatusList= new List<String>();
        reviewStatusList.add('New');
        ContactPointAddress cpa = new ContactPointAddress();
        cpa.Contact__c=testContact.Id;
        cpa.ParentId=testAccount.Id;
        cpa.AddressType='Shipping';
        cpa.Country='United States';
        cpa.Name='Office';
        cpa.ECOM_Review_Status__c='New';
        cpa.SAP_Contact_ID__c='testCId123';
        insert cpa;
        
        //Calling the getCPAs, getCpaBasedOnContactAccountAndType and getCpaBasedOnContactAccountTypeAndStatus Methods
        Test.startTest();
        List<ContactPointAddress> cpaList1 =ECOM_AccountRepo.getCPAs(testAccountId,testContactId);
        List<ContactPointAddress> cpaList2 = ECOM_AccountRepo.getCpaBasedOnContactAccountAndType(testAccountId,testContactId,'Shipping');
         List<ContactPointAddress> cpaList3 = ECOM_AccountRepo.getCpaBasedOnContactAccountTypeAndStatus(testAccountId,testContactId,'Shipping',reviewStatusList);
        Test.stopTest();
        
        //Validating the results
        System.assertEquals(1,cpaList1.size(),'Expected value was 1');
        System.assertEquals(1,cpaList2.size(),'Expected value was 1');
        System.assertEquals(1,cpaList3.size(),'Expected value was 1');
    }*/
    // Test method for getAccounBasedOnAccountNumberAndDomain, getAccountBasedOnDomainsAndCountry
    @isTest
    static void testGetAccountBasedOnDomainsAndCountryAndAccountNumber() {
        Account testAccount=[SELECT Id,Name,SAP_Customer_Number_Formatted__c,Account_Domains__c,ShippingCountry FROM Account WHERE Name=:ECOM_TestUtil.REVVITY_ACCOUNT];
        User testUser = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        //Calling the getAccounBasedOnAccountNumberAndDomain and getAccountBasedOnDomainsAndCountry method 
        Test.startTest();
        List<Account> result1=ECOM_AccountRepo.getAccounBasedOnAccountNumberAndDomain(testAccount.SAP_Customer_Number_Formatted__c,testAccount.Account_Domains__c);
        List<Account> result2=ECOM_AccountRepo.getAccountBasedOnDomainsAndCountry(testAccount.Account_Domains__c,testAccount.ShippingCountry);
        Test.stopTest();
        
        //Validating results
        System.assertEquals(1,result1.size(),'Expected value was 1');
        System.assertEquals(1,result2.size(),'Expected value was 1');

    }
    // Test method for updateWishListOwner
    @isTest
    static void testUpdateWishListOwner() {
        Account testAccount = [SELECT Id ,Name FROM Account WHERE Name=:ECOM_TestUtil.REVVITY_ACCOUNT];
        WebStore testWebStore  =[SELECT Id ,Name FROM WebStore WHERE Name=:ECOM_TestUtil.STORE_NAME];
       User testUser = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        
        WishList wList = new WishList();
        wList.WebStoreId=testWebStore.Id;
        wList.AccountId=testAccount.Id;
        wList.Name='testWL';
        insert wList;
        
        //Calling the updateWishListOwner method
        Test.startTest();
        ECOM_AccountRepo.updateWishListOwner(wList.Id,testUser.Id);
        Test.stopTest();
        
        //Validating Results
        WishList testWList = [SELECT Id ,Name,OwnerId FROM WishList ORDER BY CreatedDate DESC LIMIT 1];
        System.assertEquals(testUser.Id,testWList.OwnerId);
    }
    // Test method for GetCpaStatus
    /*@isTest
    static void testGetCpaStatus() {
        User testUser = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        ContactPointAddress cpa = new ContactPointAddress();
        cpa.AddressType='Shipping';
        cpa.Country='United States';
        cpa.Name='Office';
        cpa.SAP_Contact_ID__c='testCId123';
        cpa.ECOM_Review_Status__c='New';
        insert cpa;
        
        ContactPointAddress newcpa=[SELECT Id,AddressType,Country,Name,ECOM_Review_Status__c FROM ContactPointAddress ORDER BY CREATEDDATE DESC LIMIT 1];
        
        //Calling the GetCpaStatus method 
        Test.startTest();
        String reviewStatus =ECOM_AccountRepo.GetCpaStatus(newcpa.Id);
        Test.stopTest();
        
        //Validating result
        System.assertEquals('New',reviewStatus,'Expected value was New');

    }*/
    // Test method for getWishlistSummaries
    @isTest
    static void testGetWishlistSummaries() {
        WebStore testStore= [SELECT Id , Name FROM WebStore WHERE Name=:ECOM_TestUtil.STORE_NAME];
        Account testAccount= [SELECT Id , Name FROM Account WHERE Name=:ECOM_TestUtil.REVVITY_ACCOUNT];
        User testUser = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        List<ConnectApi.WishlistItemSortOrder> sortby=new List<ConnectApi.WishlistItemSortOrder>();
        ConnectApi.WishlistItemSortOrder CreatedDateAsc;
        sortby.add(CreatedDateAsc);
        
        //Calling the getWishlistSummaries method
        Test.startTest();
        ConnectApi.WishlistsSummary  res= ECOM_AccountRepo.getWishlistSummaries(testStore.Id,testAccount.Id,'Name',sortby);
        Test.stopTest();
        
        //Validating result
        System.assertEquals(1,res.wishlistCount,'Expected value was Null');

        
    }
    // Test method for createWishlist
    @isTest
    static void testCreateWishlist() {
       User testUser = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        //Calling the createWishlist method
        Test.startTest();
        ECOM_AccountRepo.createWishlist('webstoreId','effectiveAccountId',null);
        Test.stopTest();
        
        //Validating result
        System.assertEquals(null,ECOM_AccountRepo.createWishlist('webstoreId','effectiveAccountId',null),'Expected value was Null');
        
    }
   
    // Test method for removeWishlistItem
    @isTest
    static void testRemoveWishlistItem() {
        User testUser = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        //Calling the removeWishlistItem method
        Test.startTest();
        ECOM_AccountRepo.removeWishlistItem('webstoreId','effectiveAccountId','whishlistId','whishlistItemId');
        Test.stopTest();

    }
    
    // Test method for addItemToCart
    @isTest
    static void testAddItemToCart() {
       User testUser = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        //Calling the addItemToCart method
        Test.startTest();
        System.runAs(testUser){
           ECOM_AccountRepo.addItemToCart('webstoreId','effectiveAccountId','activeCartOrId',null);  
        }
       
        Test.stopTest();
        
        //Validating result
        System.assertEquals(null,ECOM_AccountRepo.addItemToCart('webstoreId','effectiveAccountId','activeCartOrId',null),'Expected value was Null');
        
    }
    
    //Test method for getAccountsForSearchString -- VRa punchout changes
    @isTest
    static void getAccountsForSearchString(){
        Test.startTest();
        List<Account> accounts = ECOM_AccountRepo.getAccountsForSearchString(REVVITY_ACCOUNT);
        Test.stopTest();
        Assert.isNotNull(accounts, 'Expected a non-empty list');
    }

    //RWPS- 2786 start
    @isTest
    static void testdeleteNonSellableWishListItems() {
        Account testAccount = [SELECT Id ,Name  FROM Account WHERE Name=:ECOM_TestUtil.REVVITY_ACCOUNT];
        Contact testContact = [SELECT Id ,Name,AccountId,ECOM_CountryProvided__c FROM Contact WHERE AccountId=:testAccount.Id];
        User testUser = [Select Id,ContactId From User WHERE ContactId=:testContact.Id ORDER BY CREATEDDATE DESC LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'TestProduct' LIMIT 1];
        WishlistItem wiBefore = [SELECT Id FROM WishlistItem WHERE Product2Id = :prod.Id LIMIT 1];
        List<WishlistItem> itemsBefore = [SELECT Id FROM WishlistItem WHERE Product2Id = :prod.Id];
        System.assertEquals(1, itemsBefore.size(), 'WishlistItem should exist before deletion');
        System.runAs(testUser) {
            Test.startTest();
            ECOM_AccountRepo.deleteNonSellableWishListItems(new List<String>{prod.Id});
            Test.stopTest();
        }
    }

     @isTest
    static void testremoveWishListItems() {
        Account testAccount = [SELECT Id ,Name  FROM Account WHERE Name=:ECOM_TestUtil.REVVITY_ACCOUNT];
        Contact testContact = [SELECT Id ,Name,AccountId,ECOM_CountryProvided__c FROM Contact WHERE AccountId=:testAccount.Id];
        User testUser = [Select Id,ContactId From User WHERE ContactId=:testContact.Id ORDER BY CREATEDDATE DESC LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'TestProduct' LIMIT 1];
        WishlistItem wi = [SELECT Id FROM WishlistItem WHERE Product2Id = :prod.Id LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            ECOM_AccountRepo.removeWishlistItem(wi.Id);
            Test.stopTest();
        }
    }

      @isTest
    static void testGetDummyAccountByName() {
     
        Account dummyAccount = new Account(Name = 'Dummy Test Account');
        insert dummyAccount;

        Account result = ECOM_AccountRepo.getDummyAccountByName('Dummy Test Account');
        System.assertNotEquals(null, result, 'Returned account should not be null');
        System.assertEquals(dummyAccount.Id, result.Id, 'Account ID should match the inserted one');
        System.assertEquals('Dummy Test Account', result.Name, 'Account Name should match');
    }

      @isTest
    static void testGetPunchoutAccountsForAccountIds() {
       
        Account acc1 = new Account(Name = 'Punchout Account 1');
        Account acc2 = new Account(Name = 'Punchout Account 2');
        insert new List<Account>{ acc1, acc2 };

        Set<String> accountIds = new Set<String>{ acc1.Id, acc2.Id };

        List<Account> results = ECOM_AccountRepo.getPunchoutAccountsForAccountIds(accountIds);
        System.assertEquals(2, results.size(), 'Should return two matching accounts');

        Set<String> resultIds = new Set<String>();
        for (Account a : results) {
            resultIds.add(a.Id);
        }

        System.assert(resultIds.contains(acc1.Id), 'Returned list should contain acc1');
        System.assert(resultIds.contains(acc2.Id), 'Returned list should contain acc2');
    }
 //RWPS-2786 end 
}