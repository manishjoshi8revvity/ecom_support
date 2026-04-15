/**************************************************************

	* 1. Jira Ticket(s) that relates to this class
  *    - ECOM-RWPS-592
	*
	*
	* 2. Description - This class is a test class for ECOM_ContentDocumentRepo
					 - Call the ECOM_TestUtil Class to create test data and test each methods.
					 - Used System Assertion to Confirm the functionalities.
	*
	* 3. Objects referenced
	*    - Contact
	*    - User
	*    - ContentDocumentLink

	* 4. Callouts to additional Components (including their methods) or None:
	*    - None
	*
	* 5. Dependant Class(es):
	*    - ECOM_TestUtil
    *    - ECOM_ContentDocumentRepo

	* 6. Test Class Name:
	*
	* 7. Is @Invocable : No
	*
	* 8. Author Name(s):
    *    - Abhishek Joshi 2024.04.30 added methods testSetupData, testFetchContentDocumentLink for ticket RWPS-592
*************************************************************/
@isTest
public class ECOM_ContentDocumentRepo_Test {
    /**
    * @description This method is used to get setup data for testing
    * @author Manish Joshi| 30-05-2024
    **/
    @TestSetup
    public static void testSetupData() {
        ECOM_TestUtil.initialStorefrontSetup();
        User u = [SELECT Id,ContactId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        ECOM_TestUtil.createContentDocumentLink(u.ContactId, true);
    }
	
    /**
    * @description This method is used to test fetchContentDocumentLink method
    * @author Manish Joshi| 30-05-2024
    **/
    @IsTest
    public static void testFetchContentDocumentLink() {
        User u = [SELECT Id,ContactId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        Set<String> validCD = new Set<String>();
        System.runAs(u) {
            Test.startTest();
            List<ContentDocumentLink> cdlList = ECOM_ContentDocumentRepo.fetchContentDocumentLink(u.ContactId,validCD);
            System.assertEquals(1,cdlList.size(),'There should be only one ContentDocumentLink record');
            Test.stopTest();
        }
    }
}