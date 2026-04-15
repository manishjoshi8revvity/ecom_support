/**************************************************************

* 1. Jira Ticket(s) that relates to this class
*  
* 2. Description - This class is a test class for ECOM_AccountUtil.
					- Call the ECOM_TestUtilClass to create test data and test each methods.
					- Used System Assertion to Confirm the functionalities.
*
* 3. Objects referenced
*    - Account
*    - Contact
*    - Account_Function__c
*    - ContactPointAddress
* 
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_TestUtil
*    - ECOM_AccountUtil
*    - ECOM_AccountWrapper
*
* 6. Test Class Name:
*    -None
*
* 7. Is @Invocable : No
*
* 8. Author Name(s):
*    - Manoj 2023.09.19
*    - Sidak 2024.11.21 Updated method getAccountNameMap, added accountIdToCountryMap parameter
*************************************************************/

@isTest(SeeAllData=false)
private with sharing class ECOM_AccountUtil_Test {
    
    //String constant for reused texts
    public static final String REVVITY_ACCOUNT ='Test Revvity Account';
    
    @TestSetup
    static void setupTestData() {
         ECOM_TestUtil.initialStorefrontSetup();
        //Creating Test data
        //Account testAccount= ECOM_TestUtil.createAccount();
        //Contact testContact = ECOM_TestUtil.createContact(testAccount);
        //Account_Function__c accFunction=ECOM_TestUtil.createAccountFunction(testAccount.Id);
        //ContactPointAddress billCpaAddress=ECOM_TestUtil.insertContactPointAddress(testAccount.Id,'Billing');
        //testContact.ECOM_DefaultBillToCPA__c=billCpaAddress.Id;
        //testContact.ECOM_DefaultShipToCPA__c=billCpaAddress.Id;
        //update testContact;
    }
    
    //Test for the createAccountDetailList method
    /*@isTest
    static void createAccountDetailList() {
        Account testAccount=[SELECT Id,Name From Account WHERE Name = 'TestClass Account'];
        ERP_Address__c testErp = [Select Id ,ERP_Account_Name__c From ERP_Address__c where ERP_Account_Name__c=:testAccount.Id];
        
        /*Contact testContact=[SELECT Id, Name,AccountId,Account.SAP_Customer_Number_Formatted__c,ECOM_DefaultBillToAccount__r.SAP_Customer_Number_Formatted__c,ECOM_DefaultShipToAccount__r.SAP_Customer_Number_Formatted__c,
                             Account.Name,ECOM_DefaultBillToAccount__r.Name,ECOM_DefaultBillToAccount__r.BillingStreet,ECOM_DefaultBillToAccount__r.BillingState,ECOM_DefaultBillToAccount__r.BillingCity,
                             ECOM_DefaultBillToAccount__r.BillingCountry,ECOM_DefaultBillToAccount__r.BillingPostalCode,ECOM_DefaultShipToAccount__r.Name,ECOM_DefaultShipToAccount__r.ShippingStreet,ECOM_DefaultShipToAccount__r.ShippingState,ECOM_DefaultShipToAccount__r.ShippingCity,
                             ECOM_DefaultShipToAccount__r.ShippingCountry,ECOM_DefaultShipToAccount__r.ShippingPostalCode,ECOM_DefaultShipToCPA__c,ECOM_DefaultBillToCPA__r.Name,ECOM_DefaultShipToCPA__r.Name,ECOM_DefaultBillToCPA__c,ECOM_DefaultBillToCPA__r.Address,ECOM_DefaultShipToCPA__r.Address, ECOM_DefaultBillToCPA__r.Street,ECOM_DefaultBillToCPA__r.State,ECOM_DefaultBillToCPA__r.City,
                             ECOM_DefaultBillToCPA__r.Country,ECOM_DefaultBillToCPA__r.PostalCode, ECOM_DefaultShipToCPA__r.Street,ECOM_DefaultShipToCPA__r.State,ECOM_DefaultShipToCPA__r.City,
                             ECOM_DefaultShipToCPA__r.Country,ECOM_DefaultShipToCPA__r.PostalCode
                             FROM Contact WHERE AccountId=:testAccount.Id ORDER BY CREATEDDATE DESC LIMIT 1];
        Contact testContact = [Select Id,LastName,AccountId,Account.Name, Account.SAP_Customer_Number_Formatted__c,ECOM_DefaultBillToAccount__c,ECOM_DefaultBillToAccount__r.Name,ECOM_DefaultBillToAccount__r.BillingStreet,ECOM_DefaultBillToAccount__r.BillingState,ECOM_DefaultBillToAccount__r.BillingCity,
                             ECOM_DefaultBillToAccount__r.BillingCountry,ECOM_DefaultBillToAccount__r.BillingPostalCode,ECOM_DefaultShipToAccount__r.Name,ECOM_DefaultShipToAccount__r.ShippingStreet,ECOM_DefaultShipToAccount__r.ShippingState,ECOM_DefaultShipToAccount__r.ShippingCity,
                             ECOM_DefaultShipToAccount__r.ShippingCountry,ECOM_DefaultShipToAccount__r.ShippingPostalCode From Contact Where AccountId =:testAccount.Id ORDER BY CREATEDDATE DESC LIMIT 1];
        User u = [Select Id,LastName,ContactId From User Where ContactId =:testContact.Id ORDER BY CREATEDDATE DESC LIMIT 1];
        // ContactPointAddress testCpa=[SELECT Id,Name,Address FROM ContactPointAddress WHERE ParentId=:testAccount.Id AND Type='Billing'];
        
// Account_Function__c accFunction= [SELECT Source_Account__c, SAP_Partner_Type__c, Account_Function__c.Target_Account__c,Source_Account__r.Name,Source_Account__r.SAP_Customer_Number_Formatted__c,
//                                           SAP_Source_Account_Number__c,SAP_Sales_Org__c,Source_Account__r.RAD_Identifier__c,Target_Account__r.SAP_Customer_Number_Formatted__c,Target_Account__r.Name,Target_Account__r.BillingStreet,Target_Account__r.BillingState,Target_Account__r.BillingCity,
//                                           Target_Account__r.BillingCountry,Target_Account__r.BillingPostalCode
//                                           FROM Account_Function__c WHERE Source_Account__c=:testAccount.Id];
//         List<Account_Function__c> aacFunctionList=new List<Account_Function__c> ();
//         aacFunctionList.add(accFunction);
        
        //Calling createAccountDetailList method
        System.runAs(u){
        Test.startTest();
        List<ECOM_AccountWrapper.AccountDetails> resultAccountList= ECOM_AccountUtil.createAccountDetailList(testContact);
        //List<ECOM_AccountWrapper.AccountDetails> result = ECOM_AccountUtil.createAccountDetailList(aacFunctionList);
        //List<ECOM_AccountWrapper.AccountDetails>resultCpa=ECOM_AccountUtil.getCPA(testContact);
        Test.stopTest();
        
        //Validating result
        System.assertEquals(1,resultAccountList.size(),'List size expected value was 1'); 
        }
    }*/
    
    // Test the parseWishListSummary method
    @isTest
    static void testParseWishListSummary() {
        ConnectApi.Wishlist wishList;
        // Calling the parseWishListSummary method
        Test.startTest();
        String  resultWishList = ECOM_AccountUtil.parseWishListSummary( wishList);
        
        // Validate the results
        System.assertEquals('success',resultWishList,'Expected value was that we created success');
        Test.stopTest();
        
    }
    
    //Test method for getAccountNameMap-- VRa Punchout changes
    @isTest
    static void getAccountNameMap(){
        Test.startTest();
        List<Account> accountsList= ECOM_AccountRepo.getAccountsForSearchString('TestClass Account');
        Map<String,String> accountIdToCountryMap = new Map<String,String>();
        accountIdToCountryMap.put('TestClass Account','United States');
        List<ECOM_AccountWrapper.ComboBoxWrapper> wrapper = ECOM_AccountUtil.getAccountNameMap(accountsList,accountIdToCountryMap);
        Test.stopTest();
        Assert.isNotNull(wrapper, 'Expected a not-null list');
    }
}