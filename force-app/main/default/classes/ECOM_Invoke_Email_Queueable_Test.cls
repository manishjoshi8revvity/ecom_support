/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM- 719    
*
* 2. Description - Test Class for ECOM_Invoke_Email_Queueable
*
*
* 3. Objects referenced
*    - Order
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*
* 6. Test Class Name: 
*    - NA
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*   - Sathiya 2024.06.13 Initial Create
*************************************************************/
@isTest
public class ECOM_Invoke_Email_Queueable_Test {
	@TestSetup
    public static void testSetupData(){
        ECOM_TestUtil.initialStorefrontSetup();
    }
    // Test Method
	@isTest
    static void testQueueableMethod(){
        Order testOrder = [SELECT Id, Status FROM Order ORDER BY CreatedDate DESC LIMIT 1];
        Test.startTest();
        ECOM_Invoke_Email_Queueable emailQueue = new ECOM_Invoke_Email_Queueable();
		testOrder.Status = 'Approved';
        System.enqueueJob(new ECOM_Invoke_Email_Queueable(testOrder, 'Order'));
        testOrder.Status = 'Pending Review';
        System.enqueueJob(new ECOM_Invoke_Email_Queueable(testOrder, 'Approval'));
        Test.stopTest();
    }
}