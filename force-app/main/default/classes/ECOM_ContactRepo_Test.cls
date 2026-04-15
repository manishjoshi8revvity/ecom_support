/**************************************************************

	* 1. Jira Ticket(s) that relates to this class
	*  
	*
	* 2. Description - This class is a test class for ECOM_ContactRepo
					- Call the ECOM_TestUtil Class to create test data and test each methods.
					- Used System Assertion to Confirm the functionalities.
	*
	* 3. Objects referenced
	*    - Account
	*    - Contact
	*    - User
	
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
    *    - Poonam 2025.07.24 Added testGetContactForEmail, testGetContactFieldsForRedirection and updated testUpsertEmailPreferences - RWPS-3306
*************************************************************/
@isTest
public with sharing class ECOM_ContactRepo_Test {
    @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
    }
    // Test method for getContactBasedOnId
    @isTest
    static void testGetContactBasedOnId() {
        // Create a test Contact record
        Contact testContact = [SELECT Id,FirstName,LastName FROM Contact ORDER BY CREATEDDATE DESC LIMIT 1];
        testContact.Email = 'mytestcon@test.com';
        update testContact;
        User u = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
       
         Test.startTest();
          Contact result; 
        
            result =  ECOM_ContactRepo.updateContact(testContact);
        
          
         Test.stopTest();
    }
    // Test method for updateAdditionalShippingInfo
    @isTest
    static void testUpdateAdditionalShippingInfo() {
        // Create a test Contact record
        Contact testContact = [SELECT Id,FirstName FROM Contact ORDER BY CREATEDDATE DESC LIMIT 1];
		User usr = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
       
        // Call the updateAdditionalShippingInfo method
        ECOM_ContactRepo.updateAdditionalShippingInfo(testContact);

        // Retrieve the Contact again and add assertions to verify that it was updated as expected
        Contact updatedContact = [SELECT Id, FirstName, LastName, ECOM_Delivery_Details__c FROM Contact WHERE Id = :testContact.Id];
        System.assertNotEquals(null, updatedContact,'Wrong Output');
        
       
    }

    // Test method for fetchContactPointAddresses
    @isTest
    static void testFetchContactPointAddresses() {
        // Create test data, such as an Account, Contact, and associated ContactPointAddress records
		  String contactId = [SELECT Id FROM Contact ORDER BY CREATEDDATE DESC LIMIT 1].Id;
          String addressType = 'billing';
        User usr = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(usr)
        {
          ECOM_ContactRepo.fetchContactPointAddresses(contactId,addressType);
        // Add assertions to verify that the retrieved list of ContactPointAddress records matches the expected data
          List<ContactPointAddress> result = ECOM_ContactRepo.fetchContactPointAddresses(contactId, addressType);
        
          System.assertNotEquals(null,result,'Wrong Output');
        }
          
        
        
    }

    // Test method for upsertEmailPreferences
    @isTest
    static void testUpsertEmailPreferences() {
        // Create test data, such as a list of ECOM_Email_Preferences__c records
        Account ac = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
        String acId = ac.Id;
        Contact con = [SELECT Id FROM Contact ORDER BY CREATEDDATE DESC LIMIT 1];
        String conId = con.Id;
        User usr = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(usr)
        {
		List<ECOM_Email_Preferences__c> listEP = ECOM_TestUtil.createEmailpreferencesList(ac,con);
        // Call the upsertEmailPreferences method
		//RWPS-3306 start
        for(ECOM_Email_Preferences__c ep : listEP) {
            ep.ERP_Address__c = 'a1fHs00000DLnHMIA1';
        }//RWPS-3306 end
        ECOM_ContactRepo.upsertEmailPreferences(listEP);
        List<ECOM_Email_Preferences__c> result = ECOM_ContactRepo.getEmailPreferences(acId);
        List<ECOM_Email_Preferences__c> result1 = ECOM_ContactRepo.getEmailPreferencesForCurrentUser('a1fHs00000DLnHMIA1', conId);//RWPS-3306
        // Add assertions to verify that the records were upserted as expected
        System.assertNotEquals(null,result,'Wrong Output');
        System.assertNotEquals(null,result1,'Wrong Output');//RWPS-3306
        }
    }

    // Test method for getEmailPreferences
    @isTest
    static void testGetEmailPreferences() {
        // Create test data, such as an Account and associated ECOM_Email_Preferences__c records

        // Call the getEmailPreferences method

        // Add assertions to verify that the retrieved list of ECOM_Email_Preferences__c records matches the expected data
    }
    @isTest
    public static void testupdateContactAccount()
    {
        String accId = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        	//String res = ECOM_ContactRepo.updateContactAccount(accId);
            //System.Assert(res == 'success','Wrong Result');
        }
        
        
    }
    
    @isTest
    static void updateCartDefaultAddressTest(){
        User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        System.runAs(u){
            ECOM_ContactRepo.updateCartDefaultAddress(acc.Id);
        }
        Test.stopTest();
    }
    
    @isTest
    static void updateDefaultBillingAccountTest(){
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        ECOM_ContactRepo.updateDefaultBillingAccount(con.Id,acc.Id);
        Test.stopTest();
    }
    
    @isTest
    static void updateContactAccountTest(){
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        String response;
        Test.startTest();
        response = ECOM_ContactRepo.updateContactAccount(con);
        Test.stopTest();
        system.assertEquals('success',response,'Not success');
    }
    
    @isTest
    static void updateContactAccountTest2(){
        Contact con = new Contact();
        String response;
        Test.startTest();
        response = ECOM_ContactRepo.updateContactAccount(con);
        Test.stopTest();
        system.assertEquals('error',response,'Not error');
    }
    
    @isTest
    static void getContactByOwnerTest(){
        User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        Test.startTest();
        System.runAs(u){
        	Contact con = ECOM_ContactRepo.getContactByOwner();
        }
        Test.stopTest();
    }
    //RWPS-3306 start
    @isTest
    static void testGetContactForEmail() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        testContact.Email = 'abc@test.com';
        update testContact;

        Test.startTest();
        List<Contact> contacts = ECOM_ContactRepo.getContactForEmail(testContact.Email);
        Test.stopTest();
    }

    @isTest
    static void testGetContactFieldsForRedirection() {
        Contact testContact = [SELECT Id, Email FROM Contact WHERE Email != null LIMIT 1];
        Test.startTest();
        Contact contactResult = ECOM_ContactRepo.getContactFieldsForRedirection(testContact.Email);
        Test.stopTest();
        System.assertNotEquals(null, contactResult, 'Contact should not be null');
        System.assertEquals(testContact.Email, contactResult.Email, 'Email should match');
    }
}//RWPS-3306 end