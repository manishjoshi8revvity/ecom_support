/**************************************************************

* 1. Jira Ticket(s) that relates to this class
*  
*
* 2. Description - This is a test class
*
* 3. Objects referenced
*    - User
*    - Account
*    - Contact
*	 

* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_TestUtil
*    - classes called from test class

* 6. Test Class Name:
*   
*
* 7. Is @Invocable : No
*
* 8. Author Name(s):
*    - Manojkumar 2023.09.17
*    - Prabhat 2025.03.21 Updated method getERPAddressDetailsTest to increase code coverage - RWPS-2830
*    - Prabhat 2025.10.09 - Updated method testGetLoginResponse to increase code coverage -RWPS-3740
*************************************************************/
@isTest(SeeAllData=false)
public with sharing class ECOM_UserUtil_Test {
     @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
    }
    
    @isTest
    static void testGetLoginResponse() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'TestClass Account'];
        Contact testContact =[Select Id,AccountId FROM Contact Where AccountId =: testAccount.Id LIMIT 1];//RWPS-3740
        User testUser = [Select Id,LastName,Username,FirstName,Email,ContactId From User Where ContactId = :testContact.Id ORDER BY CREATEDDATE DESC LIMIT 1];
        ECOM_LoginWrapper.LoginResponse response;
        
            response = ECOM_UserUtil.getLoginResponse(testUser.Username, true, 'TestPageURL');
        
        // Perform assertions on the response and related data
        System.assertEquals(testUser.FirstName, response.userFirstName);
        System.assertEquals(testUser.LastName, response.userLastName);
        System.assertEquals(testUser.Id, response.userId);
        System.assertEquals(testUser.Email, response.userEmail);
        
        response = ECOM_UserUtil.populateUserValues(testUser, response);
        System.assertEquals(testUser.Email, response.userEmail);
        
    }
    
     @isTest
    static void getUserModelForUserRecordTest() {
        User testUser = [Select Id,FirstName,LastName,Username,ContactId,Email,AccountId,Contact.Email,Contact.ECOM_CountryProvided__c,Contact.FirstName,Contact.LastName,Account.Name From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Test.startTest();
        ECOM_POUserModel result = ECOM_UserUtil.getUserModelForUserRecord(testUser);
        Test.stopTest();
        System.assertNotEquals(null, result,'expected order should not be null');

    }
    
     @isTest
    static void testGetPunchoutUserForUserId() {
        User testUser = [Select Id,FirstName,LastName,Username From User ORDER BY CREATEDDATE DESC LIMIT 1];
        testUser.ECOM_Is_Punchout_User__c = true;
        update testUser;
        List<User> userList = new  List<User>();
        userList.add(testUser);
        
         Test.startTest();
        User resultUser = ECOM_UserUtil.getPunchoutUserForUserId(testUser.Id);
        Test.stopTest();

        // Assert that the result is not null and has the expected values
        System.assertNotEquals(null, resultUser, 'PunchoutUserRecord should not be null');
    }
    
    @isTest
    static void getEcomSiteBaseUrlTest(){
        Test.startTest();
        ECOM_UserUtil.getEcomSiteBaseUrl();
        Test.stopTest();
    }
    
    @isTest
    static void prepareRequestForTestUserPasswordResetTest(){
        
        Test.startTest();
        ECOM_UserUtil.prepareRequestForTestUserPasswordReset('TestString');
        ECOM_UserUtil.preparePasswordResetRequest(new Map<String, String>());
        Test.stopTest();
    }
    
    @isTest
    static void provisionNewUserWithoutWelcomeEmailTest(){
        Test.startTest();
        ECOM_UserUtil.provisionNewUserWithoutWelcomeEmail(new User());
        Test.stopTest();
    }
    
    @isTest
    static void preparePunchoutLoginRequestTest(){
        Test.startTest();
        Map<String,String> parameterMap = new Map<String,String>();
        parameterMap.put('Test','Test');
        parameterMap.put('TestOne', 'TestOne');
        ECOM_UserUtil.preparePunchoutLoginRequest(parameterMap);
        Test.stopTest();
    }
    
    @isTest
    static void getERPAddressDetailsTest(){
        Test.startTest();
        Webcart cart = [SELECT Id, Default_Ship_to_ERP_Address__r.Target_Address__c, Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c, 
                        Default_Bill_to_ERP_Address__r.Target_Address__c, Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c,
                        BillingCountryCode,Default_Bill_to_ERP_Address__c,Default_Ship_to_ERP_Address__c,PoNumber,PaymentMethodId FROM Webcart ORDER BY 
                        CREATEDDATE DESC LIMIT 1]; //RWPS-2830

        User userRecord = [SELECT Id, Name, FirstName, Lastname, Phone, Fax, Email, ContactId, Contact.Name, Contact.AccountId, 
                                    Contact.fxDomain__c, Account.Name, Contact.ECOM_CountryProvided__c,
                                    Contact.Default_Ship_to_ERP_Address__c, Contact.Default_Bill_to_ERP_Address__c,
                                    Contact.Default_Bill_to_ERP_Address__r.Account__r.Name,Contact.Default_Bill_to_ERP_Address__r.ERP_Account_Name__c,
                                    Contact.Default_Bill_to_ERP_Address__r.fxAddress_Street__c,Contact.Default_Bill_to_ERP_Address__r.fxAddress_StateName__c,
                                    Contact.Default_Bill_to_ERP_Address__r.fxAddress_City__c,Contact.Default_Bill_to_ERP_Address__r.fxAddress_CountryName__c,
                                    Contact.Default_Bill_to_ERP_Address__r.fxAddress_Postal__c,Contact.Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c,
                                    Country, UserName, ECOM_Is_Punchout_User__c, AccountId,Account.ShippingCountry,Account.SAP_Customer_Number_Formatted__c,
                           			Contact.Default_Ship_to_ERP_Address__r.RAD_Identifier__c,Contact.Default_Ship_to_ERP_Address__r.Account__c,
                           			Contact.Default_Ship_to_ERP_Address__r.ERP_Account_Name__c,Contact.Default_Ship_to_ERP_Address__r.fxAddress_Street__c,
                           			Contact.Default_Ship_to_ERP_Address__r.fxAddress_StateName__c,Contact.Default_Ship_to_ERP_Address__r.fxAddress_City__c,
                           			Contact.Default_Ship_to_ERP_Address__r.fxAddress_CountryName__c,Contact.Default_Ship_to_ERP_Address__r.fxAddress_Postal__c,
                           			Contact.Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c, Contact.ECOM_Is_Mapped__c//RWPS-2830
                                    FROM User 
                                    WHERE ECOM_Is_Punchout_User__c = true ORDER BY CreatedDate DESC
                                    LIMIT 1 ];
       
        
        ECOM_UserUtil.getERPAddressDetails(userRecord, cart.id);//RWPS-2830
        ECOM_UserUtil.generateRandomString(10);
        
        ECOM_UserFlowServiceWrapper.DataWrapper wrapper = new ECOM_UserFlowServiceWrapper.DataWrapper();
        wrapper.lastName = 'TestUSerLastaname';
        ECOM_UserUtil.getSuppressedLastName(new List<ECOM_UserFlowServiceWrapper.DataWrapper>{wrapper});
        
        ECOM_UserUtil.setupFormWrapperFields(new ECOM_FormWrapper.FormWrapper(), 'formFactor', 'reason', 'comment');
        Test.stopTest();
    }
    
}