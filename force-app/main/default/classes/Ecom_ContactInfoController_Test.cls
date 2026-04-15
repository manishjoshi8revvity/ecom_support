/**************************************************************

* 1. Jira Ticket(s) that relates to this class

*  

*

* 2. Description - This class is a test class for ECOM_ContactInfoController.
					- Call the ECOM_TestUtil Class to create test data and test each methods.
					- Used System Assertion to Confirm the functionalities.
*

* 3. Objects referenced

*    - cases

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

*************************************************************/
@isTest
public with sharing class Ecom_ContactInfoController_Test {

     @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
    }

    @IsTest
    static void testGetUserData() {
        Contact con = [SELECT ID,Name FROM Contact ORDER BY CREATEDDATE DESC LIMIT 1]; // ECOM_TestUtil.portalContact;
        User testUser = [SELECT ID,Name FROM USER ORDER BY CREATEDDATE DESC LIMIT 1];  //ECOM_TestUtil.portalUser;//new User(firstname = 'ABC',
        System.runAs(testUser) {
            Test.startTest();
                ECOM_ContactInfoController.getUserData();
            Test.stopTest();
            // Verify the results
            User userInfo = [SELECT Id, Username, LastName, FirstName, ContactId FROM User WHERE Id = :testUser.Id];
            // Ensure that the method returned the expected user information
            System.assertEquals(userInfo.Id, ((User)ECOM_ContactInfoController.getUserData()).Id,'User Id matched with method user id');
        }
    }

    @IsTest
     
    static void testupdateUserData() {
        
       Contact con = [SELECT ID,Name FROM Contact ORDER BY CREATEDDATE DESC LIMIT 1]; // ECOM_TestUtil.portalContact;
        User testUser = [SELECT ID,Name FROM USER ORDER BY CREATEDDATE DESC LIMIT 1];  //ECOM_TestUtil.portalUser;//new User(firstname = 'ABC',

  
        // Create a modified user data
        User modifiedUserData = new User(
            Id = testUser.Id,
            Street = '123 Main St',
            City = 'Test City',
            State = 'CA',
            PostalCode = '12345',
            Country = 'US'
        );

        Test.startTest();
        Boolean result = ECOM_ContactInfoController.updateUserData(modifiedUserData);
        // Query the newly created Case (if any)
        List<Case> cases = [SELECT Id FROM Case WHERE Subject = 'User requested for Address update'];
        Boolean caseCreated = cases.size() == 1;
        Test.stopTest();

        // Assertions
        System.assertEquals(true, result, 'updateUserData should return true');

        if (modifiedUserData.Street != null || modifiedUserData.City != null || modifiedUserData.State != null || modifiedUserData.PostalCode != null || modifiedUserData.Country != null) {
            System.assertEquals(true, caseCreated, 'A Case should be created');
        } else {
            System.assertEquals(0, cases.size(), 'No Case should be created');
        }
    }
}