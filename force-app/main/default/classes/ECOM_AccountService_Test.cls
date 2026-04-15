/**************************************************************

* 1. Jira Ticket(s) that relates to this class
*  
* 2. Description - This class is a test class fro ECOM_AccountService.
				- Call the ECOM_TestUtilClass to create test data and test each methods.
				- Used System Assertion to Confirm the functionalities.
*
* 3. Objects referenced
*    - Account
*    - Contact
*    - User
*    - WebStore
*    - ContactPointAddress
*    - Product2
*    - WishList
* 
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_TestUtil
*    - ECOM_WishListFlowWrapper
*    - ECOM_AccountService
*    - ECOM_WishListFlowResponseWrapper
*
* 6. Test Class Name:
*    -None
*
* 7. Is @Invocable : No
*
* 8. Author Name(s):
*    - Manoj 2023.09.19
*    - Poonam Added test_checkAccountNumber_Success,test_checkAccountNumber_NoFound, test_getAccountBasedOnIds to increase code coverage- RWPS-3306

*************************************************************/


@isTest(SeeAllData=false)
public with sharing class ECOM_AccountService_Test {

    // Set up test data
    @TestSetup
    public static void testData() {
        //Creating Test data
        Account testAccount= ECOM_TestUtil.createAccount();
        Contact testContact = ECOM_TestUtil.createContact(testAccount);
        User testUser=ECOM_TestUtil.createPortalUser(testContact);
        //Creating WebStore
        WebStore testWebStore = ECOM_TestUtil.prepareWebStore(ECOM_TestUtil.STORE_NAME);
        insert testWebStore;

    }
    
   /* @isTest
    static void fetchAccountDetailsTest(){
        User u = [SELECT Id FROM User ORDER BY CreatedDate DESC LIMIT 1];
        
        ECOM_AccountWrapper.Request request = new ECOM_AccountWrapper.Request();
        request.userId=u.Id;
        test.startTest();
        ECOM_AccountWrapper.Response response;
        System.runAs(u){
            ECOM_AccountService inst = new ECOM_AccountService();
            response = inst.fetchAccountDetails(request);
        }
        test.stopTest();
    }*/
    
    @isTest
    static void upsertEmailPreferencesTest(){
        Contact con=[SELECT Id FROM Contact LIMIT 1];
        ERP_Address__c testAdd = new ERP_Address__c();
        insert testAdd;
        ECOM_Email_Preferences__c testEmail = new ECOM_Email_Preferences__c();
        testEmail.ERP_Address__c=testAdd.Id;
        testEmail.ECOM_Contact__c=con.Id;
        testEmail.ECOM_Order_Confirmation__c=true;
        testEmail.ECOM_Shipment_Notification__c=true;
        testEmail.ECOM_Email__c='test@email.com';
        insert testEmail;
        Map<String,Object> dataMap = new Map<String,Object>();
        dataMap.put('Id',testEmail.Id);
        dataMap.put('ERP_Address__c',testEmail.ERP_Address__c);
        dataMap.put('ECOM_Contact__c',testEmail.ECOM_Contact__c);
        dataMap.put('ECOM_Order_Confirmation__c',testEmail.ECOM_Order_Confirmation__c);
        dataMap.put('ECOM_Shipment_Notification__c',testEmail.ECOM_Shipment_Notification__c);
        dataMap.put('ECOM_Email__c',testEmail.ECOM_Email__c);
        List<Map<String,Object>> emails = new List<Map<String,Object>>();
        emails.add(dataMap);
        String jsonString = JSON.serialize(emails);
        test.startTest();
        ECOM_AccountService.upsertEmailPreferences(jsonString);
        test.stopTest();
    }
    
    @isTest
    static void deleteEmailPreferencesTest(){
    	ECOM_Email_Preferences__c testEmail = new ECOM_Email_Preferences__c();
        insert testEmail;
        Map<String,Object> dataMap = new Map<String,Object>();
        dataMap.put('Id',testEmail.Id);
        List<Map<String,Object>> emails = new List<Map<String,Object>>();
        emails.add(dataMap);
        String jsonString = JSON.serialize(emails);
		test.startTest();
        ECOM_AccountService.deleteEmailPreferences(jsonString);
        test.stopTest();
    }
    
   /* @isTest
    static void getBillingCPAsTest(){
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        ContactPointAddress shipAdd = new ContactPointAddress();
        shipAdd.Name='ShippingtestAdd';
        insert shipAdd;
        ContactPointAddress cpa = new ContactPointAddress();
        cpa.Name='BillingtestAdd';
        cpa.Contact__c=con.Id;
        cpa.AddressType='Billing';
        cpa.ECOM_Review_Status__c='New';
        cpa.ECOM_Associated_ShipTo__c=shipAdd.Id;
        insert cpa;
        test.startTest();
        List<ContactPointAddress> response = ECOM_AccountService.getBillingCPAs(con.Id);
        test.stopTest();
        system.assertEquals(cpa.Id,response[0].Id,'ContactPointAddress Id mismatch');
    }*/
    
    /*@isTest
    static void getShippingCPAsTest(){
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        ContactPointAddress cpa = new ContactPointAddress();
        cpa.Name='ShippingtestAdd';
        cpa.Contact__c=con.Id;
        cpa.AddressType='Shipping';
        insert cpa;
        test.startTest();
        Set<String> cpaIds = new Set<String>();
        cpaIds.add(cpa.Id);
        List<ContactPointAddress> response = ECOM_AccountService.getShippingCPAs(cpaIds);
        test.stopTest();
        system.assertEquals(cpa.Id,response[0].Id,'ContactPointAddress Id mismatch');
    }*/
    
    @isTest
    static void removeWishlistItemTest(){
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        WebStore wb = [SELECT Id FROM WebStore LIMIT 1];
        Wishlist testList = new Wishlist();
        testList.Name='testListWish';
        testList.AccountId=acc.Id;
        testList.WebStoreId = wb.Id;
        insert testList;
        Product2 prod = new Product2();
        prod.Name='testProd';
        insert prod;
        WishlistItem wi = new WishlistItem();
        wi.Name=prod.Name;
        wi.Product2Id=prod.Id;
        wi.WishlistId=testList.Id;
        insert wi;
        Test.startTest();
        ECOM_AccountService.removeWishlistItem(wi.Id);
        Test.stopTest();
    }
    
    @isTest
    static void getEmailPreferencesTest(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        test.startTest();
        List<ECOM_Email_Preferences__c> response = ECOM_AccountService.getEmailPreferences(acc.Id);
        test.stopTest();
    }

    // Test the createCPAs method
    // @isTest
//     static void testCreateCPAs() {
//         Account testAccount=[Select Id, Name FROM Account WHERE Name=:ECOM_TestUtil.REVVITY_ACCOUNT];
//         ContactPointAddress testCpa = ECOM_TestUtil.createContactPointAddress(testAccount);
        
//         //Calling the createCPAs method
//         Test.startTest();
//         List<ContactPointAddress> resultCpaList = ECOM_AccountService.createCPAs(new List<ContactPointAddress>{testCpa});
//         String resultCpaStatus= ECOM_AccountService.getCpaStatus(testCpa.Id);
//         Test.stopTest();
        
//         // Validate the results
//         System.assertEquals(1, resultCpaList.size(),'Size of List should be 1');
//         System.assertEquals('New', resultCpaStatus,'Status shall be new');
        
//         }
 
    
    // Test method for getWishlistSummaries
    @isTest
    static void testGetWishlistSummaries() {
        WebStore testStore= [SELECT Id , Name FROM WebStore WHERE Name=:ECOM_TestUtil.STORE_NAME];
        Account testAccount= [SELECT Id , Name FROM Account WHERE Name=:ECOM_TestUtil.REVVITY_ACCOUNT];
        List<ConnectApi.WishlistItemSortOrder> sortby=new List<ConnectApi.WishlistItemSortOrder>();
        ConnectApi.WishlistItemSortOrder CreatedDateAsc;
        sortby.add(CreatedDateAsc);
        
        //Calling the getWishlistSummaries method
        Test.startTest();
        ConnectApi.WishlistsSummary  res= ECOM_AccountService.getWishlistSummaries(testStore.Id,testAccount.Id,'Name',sortby);
        Test.stopTest();
        
        //Validating results
        System.assertEquals(1,res.wishlistCount,'Expected value was Null');
    }
    // Test the getAccountFunctions method
    /*@isTest
    static void testGetAccountFunctions() {
        Account testAccount=[Select Id, Name FROM Account WHERE Name=:ECOM_TestUtil.REVVITY_ACCOUNT];
        Map<String,Object> returnMap = new Map<String,Object>();
        
        // Call the getAccountFunctions method
        Test.startTest();
        Map<String,Object> resultMap = ECOM_AccountService.getAccountFunctions(returnMap,testAccount.Id,'Org');
        Test.stopTest();
        
        // Validate the results
        System.assertEquals('true', resultMap.get('success'),'Success should be true');
        }
    */
    // Test the getCpaBasedOnContactAccountAndType method
    /*@isTest
    static void testGetCpaBasedOnContactAccountAndType() {
        Account testAccount=[SELECT Id, Name FROM Account WHERE Name=:ECOM_TestUtil.REVVITY_ACCOUNT];
        Contact testContact=[SELECT Id, Name FROM Contact WHERE AccountId=:testAccount.Id];
        Map<String,Object> returnMap = new Map<String,Object>();

        // Call the getCpaBasedOnContactAccountAndType method
        Test.startTest();
        Map<String,Object> resultMap = ECOM_AccountService.getCpaBasedOnContactAccountAndType(returnMap,testAccount.Id,testContact.Id);
        Test.stopTest();
        
        // Validate the results
        System.assertEquals('true', resultMap.get('success'),'Success should be true');
        }
    
    // Test the getAccountBasedOnIds,getAccountBasedOnDomainsAndCountry and getAssociatedAccounts method
    @isTest
    static void testGetAccountBasedOnIds() {
        Account testAccount=[SELECT Id ,Account_Domains__c, BillingStreet,BillingCity, 
                               BillingState,BillingPostalCode,
                               BillingCountry,ShippingStreet, ShippingCity, 
                               ShippingState, ShippingPostalCode,
                               ShippingCountry  FROM Account WHERE Name=:ECOM_TestUtil.REVVITY_ACCOUNT];
         Contact testContact=[SELECT Id, Name FROM Contact WHERE AccountId=:testAccount.Id];

        // Call the getAccountBasedOnIds method
        Test.startTest();
        List<Account> resultList1 = ECOM_AccountService.getAccountBasedOnIds(new List<String>{testAccount.Id});
        
        // Validate the results
        System.assertEquals(1, resultList1.size(),'Size should be 1');
        
        List<Account> resultList2 = ECOM_AccountService.getAccountBasedOnDomainsAndCountry(testAccount.Account_Domains__c,testAccount.BillingCountry);

        // Validate the results
        System.assertEquals(1, resultList2.size(),'Size should be 1');
        
        List<String> resultList3 = ECOM_AccountService.getAssociatedAccounts(testContact.Id);
        
        // Validate the results
        System.assertEquals(1, resultList3.size(),'Size should be 1');
        Test.stopTest();
        }
    */
    @isTest
    static void fetchWishListTest(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        WebStore wb = [SELECT Id FROM WebStore LIMIT 1];
        Wishlist testList = new Wishlist();
        testList.Name='testListWish';
        testList.AccountId=acc.Id;
        testList.WebStoreId = wb.Id;
        insert testList;
        test.startTest();
        List<WishList> response = ECOM_AccountService.fetchWishList(UserInfo.getUserId());
        test.stopTest();
        system.assertEquals(testList.Id,response[0].Id,'Wishlist Id Mismatch');
    }
    
   /* @isTest
    static void getCPAForCPAIdTest(){
        ContactPointAddress cpa = new ContactPointAddress();
        cpa.Name='testaddbillship';
        insert cpa;
        test.startTest();
        ContactPointAddress result = ECOM_AccountService.getCPAForCPAId(cpa.Id);
       	test.stopTest();
        System.assertEquals(cpa.Id,result.Id,'CPA Id Mismatch');
    }
   
    // Test method for upsertCPAs
    @isTest
    static void testUpsertCPAs() {
        List<ContactPointAddress> cpaList = new List<ContactPointAddress>();
        ContactPointAddress cpa = new ContactPointAddress();
        cpa.AddressType='Shipping';
        cpa.Country='United States';
        cpa.Name='Office';
        cpa.SAP_Contact_ID__c='testCId123';
        cpaList.add(cpa);
        
        // Call the upsertCPAs method
        Test.startTest();
        List<ContactPointAddress> cpaList2=ECOM_AccountService.upsertCPAs(cpaList);
        Test.stopTest();
        
        // Validate the results
        System.assertEquals(1,cpaList2.size(),'Expected value was 1');
    }
    */
    // Test the wishListOperations method 1 scenario when wishlist id we have
    @isTest
    static void testWishListOperations1() {
        WebStore testStore= [SELECT Id , Name FROM WebStore WHERE Name=:ECOM_TestUtil.STORE_NAME];
        Account testAccount= [SELECT Id , Name FROM Account WHERE Name=:ECOM_TestUtil.REVVITY_ACCOUNT];
        User testUser = [SELECT Id , Alias,Name FROM User WHERE Alias=:ECOM_TestUtil.USER_ALIAS];
        
        //Creating test wishlist 
        WishList testWList=ECOM_TestUtil.createWishlist(testAccount.Id,testStore.Id,testUser.Id);
        //Creating test product
        Product2 testProd = ECOM_TestUtil.createProduct('TestProduct','TestPartNumber', 'Code123', true);
        
        ECOM_WishListFlowWrapper.Request req1 = new ECOM_WishListFlowWrapper.Request(); 
        req1.action='add';
        req1.userId=testUser.Id;
        req1.productId=testProd.Id;
        req1.wishlistId=testWList.Id;
        
        // Call the wishListOperations method for scenario having existing wishlist and action add
        Test.startTest();
        ECOM_WishListFlowResponseWrapper result1 = ECOM_AccountService.wishListOperations(req1,testUser);
        
        // Validate the results
        System.assertEquals(true,result1.success,'Expected value was true');
        
        //Creating wishlist item
        WishListItem testWListItem=ECOM_TestUtil.createWishlistItem(testProd.Id,testWList.Id);
        
        ECOM_WishListFlowWrapper.Request req3 = new ECOM_WishListFlowWrapper.Request(); 
        req3.action='remove';
        req3.userId=testUser.Id;
        req3.productId=testProd.Id;
        req3.wishlistId=testWList.Id;
        
        // Call the wishListOperations method for scenario having existing wishlist as well as wishlistitem and action remove
        ECOM_WishListFlowResponseWrapper result3 = ECOM_AccountService.wishListOperations(req3,testUser);
        
        //Validating results
        System.assertEquals('Product was removed successfully from favorites.',result3.message,'Expected value was remove message');

        Test.stopTest();
        
        }
    

    // Test the wishListOperations method 2nd scenario when wishlist id=null 
    @isTest
    static void testWishListOperations2() {
        WebStore testStore= [SELECT Id , Name FROM WebStore WHERE Name=:ECOM_TestUtil.STORE_NAME];
        Account testAccount= [SELECT Id , Name FROM Account WHERE Name=:ECOM_TestUtil.REVVITY_ACCOUNT];
        User testUser = [SELECT Id , Alias,Name FROM User WHERE Alias=:ECOM_TestUtil.USER_ALIAS];
        
        //Creating test product
        Product2 testProd = ECOM_TestUtil.createProduct('TestProduct','TestPartNumber', 'Code123', true);
        
        ECOM_WishListFlowWrapper.Request req = new ECOM_WishListFlowWrapper.Request(); 
        req.action='add';
        req.userId=testUser.Id;
        req.productId=testProd.Id;
        req.wishlistId=null;
        
        // Call the wishListOperations method
        Test.startTest();
        ECOM_WishListFlowResponseWrapper result = ECOM_AccountService.wishListOperations(req,testUser);
        Test.stopTest();
        
     }
    
    // Test the createWishlist method
    @isTest
    static void testCreateWishlist() {
        // Call the createWishlist method
        ConnectApi.WishlistInput wishlistInput = new ConnectApi.WishlistInput();
        ConnectApi.WishlistItemInput wishlistItemInput = new ConnectApi.WishlistItemInput();
        
        //Calling the createWishlist,addItemToWishlist,removeWishlistItem methods
        Test.startTest();
        ConnectApi.Wishlist createdWishlist=ECOM_AccountService.createWishlist('webstoreId','effectiveAccountId', wishlistInput);
        ConnectApi.WishlistItem result =ECOM_AccountService.addItemToWishlist('webstoreId','effectiveAccountId','wishlistId',wishlistItemInput);
        //ECOM_AccountService.removeWishlistItem('webstoreId', 'effectiveAccountId','wishlistId','wishlistItemId');
        Test.stopTest();
        
        //Validating the results
        System.assertEquals('WishList Name',createdWishlist.summary.name,'Expected name is Wishlist Name');
        System.assertEquals(10.00,result.salesPrice,'Expected name is 10.00');
        
        }
    
      // Test method for getAccounBasedOnAccountNumberAndDomain, getAccountBasedOnDomainsAndCountry
   /* @isTest
    static void testCheckAccountNumber() {
        Account testAccount=[SELECT Id,Name,SAP_Customer_Number_Formatted__c,Account_Domains__c,ShippingCountry FROM Account WHERE Name=:ECOM_TestUtil.REVVITY_ACCOUNT];
    
        //Calling checkAccountNumber method
        Test.startTest();
        Map<String,Object> resultMap1=ECOM_AccountService.checkAccountNumber(testAccount.SAP_Customer_Number_Formatted__c,testAccount.Account_Domains__c);
        Map<String,Object> resultMap2=ECOM_AccountService.checkAccountNumber('','');
        Test.stopTest();
        
        //Validating the results
        System.assertEquals(true,resultMap1.get('Success'),'Expected value of success is true');
        System.assertEquals(false,resultMap2.get('Success'),'Expected value of success is false');
    }
    
      // Test method for getCPAForContact
    @isTest
    static void testGetCPAForContact() {
         Contact testContact=[SELECT Id, Name FROM Contact WHERE Name=:ECOM_TestUtil.CONTACT_NAME];
    
        //Calling getCPAForContact method
        Test.startTest();
        List<ContactPointAddress> resultCpaList=ECOM_AccountService.getCPAForContact(testContact.Id);
        Test.stopTest();
        
        //Validating the results
        System.assertEquals(false,resultCpaList.size()>0,'Expected value for list size>0');
    }
    
   // @isTest
//     Static void testGetCPAs(){
//         Account testAccount=[SELECT Id, Name FROM Account WHERE Name=:ECOM_TestUtil.REVVITY_ACCOUNT];
//         Contact testContact=[SELECT Id, Name FROM Contact WHERE AccountId=:testAccount.Id];
//         ContactPointAddress testCpa = ECOM_TestUtil.createContactPointAddress(testAccount);
//         List<ContactPointAddress> listCPAs = new List<ContactPointAddress>();
//         listCPAs.add(testCpa);
//         Test.startTest();
//         List<ContactPointAddress> resultCpaList=ECOM_AccountService.GetCPAs(testAccount.Id,testContact.Id);
//         Test.stopTest();
        
//     }
    */
    @isTest
    static void getDummyAccountByNameTest(){
        Account acc = [SELECT Id,Name FROM Account LIMIT 1];
        test.startTest();
        Account result = ECOM_AccountService.getDummyAccountByName(acc.Name);
        test.stopTest();
        system.assertEquals(acc.Id,result.Id,'Account Id Mismatch');
    }
    
    @isTest
    static void deleteACR(){
        Account account = [SELECT Id,Name FROM Account LIMIT 1];
        Contact contact = [SELECT ID, Name FROM Contact LIMIT 1];
        test.startTest();
        	Map<String,Object> result = ECOM_AccountService.deleteTemporaryACR(contact.Id, account.Id);
        test.stopTest();
    }
    //RWPS-3306 START
    @isTest
    static void test_checkAccountNumber_Success() {
        Account acc = [SELECT Id, Account_Domains__c FROM Account  LIMIT 1];
         test.startTest();
        Map<String, Object> result = ECOM_AccountService.checkAccountNumber(acc.Id, acc.Account_Domains__c);
        test.stopTest();
    }

    @isTest
    static void test_checkAccountNumber_NotFound() {
        Map<String, Object> result = ECOM_AccountService.checkAccountNumber('NON_EXISTENT', 'InvalidDomain');

        System.assertEquals(false, result.get('Success'));
        System.assertEquals('Account Number Not Found', result.get('ErrorMessage'));
    }

    @isTest
    static void test_getAccountBasedOnIds() {
        List<Account> insertedAccounts = [SELECT Id FROM Account LIMIT 1];
        List<String> ids = new List<String>();
        for (Account a : insertedAccounts) {
            ids.add(a.Id);
        }

        List<Account> result = ECOM_AccountService.getAccountBasedOnIds(ids);
        System.assertEquals(1, result.size());
    }
    //RWPS-3306 END
}