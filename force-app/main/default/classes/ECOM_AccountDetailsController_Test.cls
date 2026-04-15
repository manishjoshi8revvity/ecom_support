/**************************************************************

* 1. Jira Ticket(s) that relates to this class
*  
* 2. Description 
*    - This class is a test class.
*	 - Test class for ECOM_AccountDetailsController.
*	 - Number of Methods : 2 + 1 setup.
*
* 3. Objects referenced
*    - Account
*.   - User
* 
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_TestUtil
*    - ECOM_AccountDetailsFlowWrapper
*    - ECOM_AccountDetailsController
*
* 6. Test Class Name:
*    -None
*
* 7. Is @Invocable : No
*
* 8. Author Name(s):
*    - Manoj 2023.09.19
*    - Princy Anthony 2026.03.11 - Added method testGetAddressServiceInstance - RWPS-5807

*************************************************************/


@isTest(SeeAllData=false)
public with sharing class ECOM_AccountDetailsController_Test {
    
    // Set up test data
    @TestSetup
    public static void testData() {
        //Creating Test data
        Account testAccount= ECOM_TestUtil.createAccount();
        Map<String,Object> respponse = ECOM_TestUtil.initialStorefrontSetup();
    }
    
    // Test the fetchAccountDetailsByUserId method
    @isTest
    static void testFetchAccountDetailsByUserId() {
        // Create a test request
        ECOM_AccountDetailsFlowWrapper.Request accRequest = new ECOM_AccountDetailsFlowWrapper.Request();
        List<User> users= [Select Id , Alias from User ORDER BY CREATEDDATE DESC LIMIT 1];
        accRequest.userId = users[0].Id;
        List<ECOM_AccountDetailsFlowWrapper.Request> accRequestList = new List<ECOM_AccountDetailsFlowWrapper.Request>();
        accRequestList.add(accRequest);
        
        // Call the fetchAccountDetailsByUserId method
        System.runAs(new User(Id=users[0].Id)){
            Test.startTest();
            List<ECOM_AccountDetailsFlowWrapper.Response> accResponseList = ECOM_AccountDetailsController.fetchAccountDetailsByUserId(accRequestList);
            Test.stopTest();
            
            // Validate the results
            System.assertEquals(1, accResponseList.size(),'Size should be 1');
        }
        
    }
    
    @isTest
    static void testFetchAccountDetailsByUserIdExceptionCase() {
        // Create a test request
        ECOM_AccountDetailsFlowWrapper.Request accRequest = new ECOM_AccountDetailsFlowWrapper.Request();
        List<ECOM_AccountDetailsFlowWrapper.Request> accRequestList = new List<ECOM_AccountDetailsFlowWrapper.Request>();
        accRequestList.add(accRequest);
        
        Test.startTest();
        List<ECOM_AccountDetailsFlowWrapper.Response> accResponseList = ECOM_AccountDetailsController.fetchAccountDetailsByUserId(accRequestList);
        Test.stopTest();
        
    }
    
    @isTest
    static void testCheckAccountNumber() {
        // Querying Account
        Account testAccount=[SELECT Id,Name,SAP_Customer_Number_Formatted__c,Account_Domains__c,ShippingCountry FROM Account WHERE Name=:ECOM_TestUtil.REVVITY_ACCOUNT];
        User testUser=[SELECT Id,Name,Email FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        // Call the checkAccountNumber method
        Test.startTest();
        Map<String,Object> accResponseMap;
        System.runAs(testUser){
            accResponseMap = ECOM_AccountDetailsController.checkAccountNumber(testAccount.SAP_Customer_Number_Formatted__c,testAccount.Account_Domains__c);
        }
        
        Test.stopTest();
        
        // Validate the results
        System.assertEquals(true, accResponseMap.get('Success'),'Success in response map should be true  ');
    }
  
    @isTest
    static void testGetAccountDetailsRequest() {
        // Create a test request for ECOM_AccountDetailsFlowWrapper.Request
        ECOM_AccountDetailsFlowWrapper.Request testRequest = new ECOM_AccountDetailsFlowWrapper.Request();
        testRequest.userId = 'TestUserId';

        // Call the ECOM_AccountWrapper.getAccountDetailsRequest method
        Test.startTest();
        ECOM_AccountWrapper.Request result = ECOM_AccountDetailsController.getAccountDetailsRequest(testRequest);
		Test.stopTest();
        // Perform assertions to validate the results
        System.assertEquals(testRequest.userId, result.userId, 'Expected userId to be the same as in the test request');
    }
    
    /**
    * @description Verifies the getAddressServiceInstance method correctly initializes and returns a non-null instance of ERP_IAddressService
    * @author Anthony, Princy
    * @date 11-03-2026
    */
    @isTest
    static void testGetAddressServiceInstance() {  
        Test.startTest();
        ERP_IAddressService service =
            ECOM_AccountDetailsController.getAddressServiceInstance();
        Test.stopTest();
        System.assertNotEquals(null, service);
    }
    // Add more test methods to cover different scenarios, edge cases, and error handling.
}