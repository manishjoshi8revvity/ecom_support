/************************************************************************
* 1. Jira Ticket(s) that relates to this class
*	 ECOM-719, ECOM-721
* 2. Description - Utility class for sending email
* 3. Objects referenced
*    -Order
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*   
*
* 5. Dependant Class(es):
* 6. Invocable: True
*
* 7. Test Class Name: NA
*
* 8. Author Name(s): 
*    - Sathiya 06/13/2024
*
************************************************************************/ 
@isTest
public class ECOM_Invoke_Approval_Email_Test {
    @TestSetup
    public static void testSetupData(){
        ECOM_TestUtil.initialStorefrontSetup();
    }
    // Test Method
	@isTest
    static void testInvocableMethod(){
        Order testOrder = [SELECT Id, Status FROM Order ORDER BY CreatedDate DESC LIMIT 1];
        Test.startTest();
		testOrder.Status = 'Approved';
        ECOM_Invoke_Approval_Email.initApprovalEmail(new List<Order>{testOrder});
        testOrder.Status = 'Pending Review';
        ECOM_Invoke_Approval_Email.initApprovalEmail(new List<Order>{testOrder});
        Test.stopTest();
    }
}