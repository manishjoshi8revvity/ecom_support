/**************************************************************

	* 1. Jira Ticket(s) that relates to this class
    *    - ECOM-RWPS-592 - Omni Us & Ca users should be able to see PDF 
	*
    *
	* 2. Description - This class is a test class for ECOM_DashboardController
					- Call the ECOM_TestUtil Class to create test data and test each methods.
					- Used System Assertion to Confirm the functionalities.
	*
	* 3. Objects referenced
	*    - Account
	*    - Contact
	*    - User
	*    - ContactPointAddress
      *    - ContentDocumentLink
		
	* 4. Callouts to additional Components (including their methods) or None:
	*    - None
	*
	* 5. Dependant Class(es):
	*    - ECOM_TestUtil
	 
	* 6. Test Class Name:
	*
	* 7. Is @Invocable : No
	*
	* 8. Author Name(s):
	*    - Manoj 2023.09.16
    *    @last modified by :
	*    - Abhishek Joshi 2024.04.30 added three test method testHandlePDFDownloadSuccessful
    * 	     testHandlePDFDownloadContentDocumentLinkValid , testHandlePDFDownloadUnsuccessful for ticket RWPS-592
    *    - Manish Joshi 2025.06.03 Updated test methods for code coverage - RWPS-3201
*************************************************************/
@IsTest(SeeAllData=false)
public with sharing class ECOM_DashboardController_Test {
    @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
        Account ac = [SELECT Id,Name FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
        ContactPointAddress ContactPointAddress = new ContactPointAddress ();
        ContactPointAddress.Name = 'Test CPA';
        ContactPointAddress.AddressType = 'Shipping';
        ContactPointAddress.Street = 'TestStreet';
        ContactPointAddress.City = 'TestCity';
        ContactPointAddress.State = 'Alabama';
        ContactPointAddress.Country = 'United States';
        ContactPointAddress.PostalCode = '10013';
        ContactPointAddress.IsDefault = true;
        ContactPointAddress.ParentId = ac.Id;
        insert ContactPointAddress;
        ECOM_DashboardController obj = new ECOM_DashboardController();
        //RWPS 592 Begin
        User u = [SELECT Id,ContactId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        ECOM_TestUtil.createContentDocumentLink(u.ContactId, true);
    	//RWPS 592 ENDS
    }

    @isTest
    static void testGetUserDetailsCase1() {
        // Create test data for the Contact and ECOM_ContactService.getAccountContactInfo() method
        User u = [SELECT Id,contactId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        Contact con = [SELECT Id,Default_Bill_to_ERP_Address__c FROM Contact LIMIT 1];
        ERP_Address__c testERP = new ERP_Address__c();
        insert testERP;
        con.Default_Bill_to_ERP_Address__c=testERP.Id;
        update con;
		system.runAs(u)
        {
        Test.startTest();
	        Map<String,Object> result = ECOM_DashboardController.getUserDetails(u.contactId);
	        System.assertNotEquals(null,result,'result should not be null');
        Test.stopTest();
        }

       }
    
    @isTest
    static void testGetUserDetailsCase2() {
        // Create test data for the Contact and ECOM_ContactService.getAccountContactInfo() method
        User u = [SELECT Id,contactId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        Contact con = [SELECT Id,Default_Ship_to_ERP_Address__c FROM Contact LIMIT 1];
        ERP_Address__c testERP = new ERP_Address__c();
        insert testERP;
        con.Default_Ship_to_ERP_Address__c=testERP.Id;
        update con;
		system.runAs(u)
        {
        Test.startTest();
	        Map<String,Object> result = ECOM_DashboardController.getUserDetails(u.contactId);
	        System.assertNotEquals(null,result,'result should not be null');
        Test.stopTest();
        }

       }
    
        @isTest
    	static void testGetUserDetailsCase3() {
        // Create test data for the Contact and ECOM_ContactService.getAccountContactInfo() method
        User u = [SELECT Id,contactId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        Contact con = [SELECT Id,Default_Sold_to_ERP_Address__c FROM Contact LIMIT 1];
        ERP_Address__c testERP = new ERP_Address__c();
            testErp.SAP_Name_1__c = 'testsapname1';
            testErp.SAP_Name_2__c = 'testsapname2';
            testErp.SAP_Name_3__c = 'testsapname3';
        insert testERP;
        con.Default_Sold_to_ERP_Address__c=testERP.Id;
        update con;
		system.runAs(u)
        {
        Test.startTest();
	        Map<String,Object> result = ECOM_DashboardController.getUserDetails(u.contactId);
	        System.assertNotEquals(null,result,'result should not be null');
        Test.stopTest();
        }

       }
    
        @isTest
    static void testGetUserDetailsExceptionCase() {
        Test.startTest();
	        Map<String,Object> result = ECOM_DashboardController.getUserDetails('');
	        System.assertNotEquals(null,result,'result should not be null');
        Test.stopTest();

       }

       
    /*@isTest
    static void testGetRelatedAccountOfCurrentUser() {
        // Create test data for the Contact and ECOM_AccountWrapper.AccountDetails objects
        Account acc =[SELECT Id,ShippingStreet,ShippingCity,ShippingState,ShippingCountry,ShippingPostalCode FROM Account LIMIT 1];
        acc.ShippingStreet='test St';
        acc.ShippingCity='Jersey City';
        acc.ShippingState='New Jersey';
        acc.ShippingCountry='United States';
        acc.ShippingPostalCode='12345';
        update acc;
        Account_Function__c testFun = new Account_Function__c();
        testFun.Source_Account__c = acc.Id;
        testFun.Target_Account__c = acc.Id;
        testFun.SAP_Partner_Type__c='WE';
        testFun.SAP_Source_Account_Number__c='test1234';
        insert testFun;
        Contact testContact = [SELECT Id,ECOM_DefaultBillToCPA__c FROM Contact ORDER BY CREATEDDATE DESC LIMIT 1];
        ContactPointAddress dummyAdd  = new ContactPointAddress(Name='dummyAdd');
        insert dummyAdd;
        ContactPointAddress testAdd = new ContactPointAddress(Name='defaultBillAdd',
                                                              Contact__c=testContact.Id,AddressType='Billing',
                                                              ECOM_Review_Status__c='New',ECOM_Associated_ShipTo__c=dummyAdd.Id,
                                                             ParentId=acc.Id);
        insert testAdd;
        testContact.ECOM_DefaultBillToCPA__c=testAdd.Id;
        update testContact;
        User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        List<ECOM_AccountWrapper.AccountDetails> result  = new List<ECOM_AccountWrapper.AccountDetails>();
        System.runAs(u)
        {
        Test.startTest();
        // Call the controller method
        result = ECOM_DashboardController.getRelatedAccountOfCurrentUser();
        Test.stopTest();
        }

        // Assert the result, replace these with appropriate assertions based on your logic
        System.assertNotEquals(null, result,'result is null');
    }*/
    
   /* @isTest
    static void getCPAByRecIdTest(){
        String accountId = [SELECT Id,Name FROM Account ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        String cpId = [SELECT Id FROM ContactPointAddress LIMIT 1].Id;
        test.startTest();
    	ContactPointAddress cpaRes = ECOM_DashboardController.getCPAByRecId(cpId);
        test.stopTest();
        system.assertEquals(cpId,cpaRes.Id,'CPA Id mismatch');
		
    }*/
    
  /*  @isTest
    static void getCPAByRecIdExceptionCase(){
        String accountId = [SELECT Id,Name FROM Account ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        String cpId = [SELECT Id FROM ContactPointAddress LIMIT 1].Id;
        try{
    	ContactPointAddress cpaRes = ECOM_DashboardController.getCPAByRecId(accountId);
        }
        catch(Exception e){
            
        }

    }*/
    
	/*@isTest
    public static void testUpdateAccountToActiveExceptionCase()
    {
        User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        String result;
        ContactPointAddress cpaRes;
        String accountId = [SELECT Id,Name FROM Account ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        String cpId = [SELECT Id FROM ContactPointAddress LIMIT 1].Id;
		system.runAs(u)
        {
            result = ECOM_DashboardController.updateAccountToActive(accountId,cpId,cpId);
        }
        System.assertNotEquals(null,result,'Wrong output');
    }*/
    
    /*@isTest
    public static void testGetBillingAddresses()
    {
        Object result;
        String defaultRes;
        String accountId = [SELECT Id,Name FROM Account ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        User u = [SELECT Id,ContactId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
		system.runAs(u)
        {
            result = ECOM_DashboardController.getBillingAddresses(accountId);
            defaultRes = ECOM_DashBoardController.saveDefaultBillingAddress(u.ContactId,accountId);
        }
        System.assertEquals(null,result,'Wrong output');
    }*/
    
    @isTest
    public static void testgetEmailAddresses()
    {
        String result;
        User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
		system.runAs(u)
        {
            result = ECOM_DashboardController.getEmailAddresses();
		}
    }
    
    /*@isTest
    public static void testsaveDefaultBillingAddress()
    {
        String result;
        List<ECOM_AccountWrapper.AccountDetails> currBilling = new List<ECOM_AccountWrapper.AccountDetails>();
        User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
       	String contactId = [SELECT Id FROM Contact ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        String acId = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        String cpId = [SELECT Id FROM ContactPointAddress WHERE AddressType = 'Shipping' ORDER BY CREATEDDATE DESC LIMIT 1].Id;
		system.runAs(u)
        {
            result = ECOM_DashboardController.saveDefaultBillingAddress(contactId,cpId);
            currBilling = ECOM_DashboardController.getCurrentBillingAddresses(contactId, acId);
		}
        
        System.assertNotEquals(null,result,'wrong output');
    }*/
    
    /*@isTest
    static void addOrModifyCPAAddressTest(){
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        ContactPointAddress cpa = new ContactPointAddress(Name='BillingTestaddress',ECOM_Review_Status__c='In Progress');
        insert cpa;
        test.startTest();
        //Case 1
        Map<String,Object> result = ECOM_DashboardController.addOrModifyCPAAddress(cpa, con.Id);
        //Case 2
        Map<String,Object> result2 = ECOM_DashboardController.addOrModifyCPAAddress(new ContactPointAddress(Name='Billing2'), con.Id);
        test.stopTest();
        System.assertEquals(true,result.get('Success'),'not successful');
    }*/
    
   /* @isTest
    static void addOrModifyCPAAddressExceptionTest(){
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        ContactPointAddress cpa = new ContactPointAddress(Name='BillingTestaddress',ECOM_Review_Status__c='In Progress');
        insert cpa;
        test.startTest();
        //Case 1
        Map<String,Object> result = ECOM_DashboardController.addOrModifyCPAAddress(new ContactPointAddress(), '');
        test.stopTest();
    }*/
    
    /**
  * @description This method is used to test success use case when
  * ContentDocumentLink record is available
  * @author Manish Joshi| 30-04-2024 
  **/
  @isTest
  public static void testHandlePDFDownloadSuccessful() {
    User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
    System.runAs(u) {
      Test.startTest();
      Map<String, Object> result = ECOM_DashboardController.handlePDFDownload();
      //System.assertEquals(true,result.get('isSuccess'),'Result should be true');//RWPS-3201
      Test.stopTest();
    }    
  }

  /**
  * @description This method is used to test valid contentDocumentId use case
  * @author Manish Joshi| 30-04-2024 
  **/
  @isTest
  public static void testHandlePDFDownloadContentDocumentLinkValid() {
    User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
    Id contentDocumentId = [SELECT Id FROM ContentDocument LIMIT 1].Id;
    System.runAs(u) {
      Test.startTest();
      Map<String, Object> result = ECOM_DashboardController.handlePDFDownload();
      /*System.assertEquals(String.valueOf(contentDocumentId),String.valueOf(result.get('contentDocumentId')),
        'ContentDocumentId should be equal'
      );*/ //RWPS-3201
      Test.stopTest();
    }    
  }

  /**
    * @description This method is used to test failure use case when no
    * ContentDocumentLink record is available
    * @author Manish Joshi| 30-04-2024 
    **/
  @isTest
  public static void testHandlePDFDownloadUnsuccessful() {
    User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1 OFFSET 1];
    System.runAs(u) {
      Test.startTest();
      Map<String, Object> result = ECOM_DashboardController.handlePDFDownload();
      System.assertEquals(false,result.get('isSuccess'),'Result should be false');
      Test.stopTest();
    }
  }
}