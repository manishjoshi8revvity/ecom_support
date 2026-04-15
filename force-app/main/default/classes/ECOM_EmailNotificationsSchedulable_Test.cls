/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM- 119    
*
* 2. Description - This scheduable class is used as a Test Class for ECOM_EmailNotificationsSchedulable.
*
*
* 3. Objects referenced
*    - None
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_EmailNotificationsSchedulable
*
* 6. Test Class Name: 
*    - ECOM_EmailNotificationsSchedulable_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*   - Vipul Goyal 2024.04.23 Updated Test Class.
*************************************************************/
@isTest(SeeAllData=false)
public class ECOM_EmailNotificationsSchedulable_Test {
    @isTest
    static void testExecute() {
       
        Test.startTest();
        // Create an instance of the Schedulable class
        ECOM_EmailNotificationsSchedulable schedulableInstance = new ECOM_EmailNotificationsSchedulable();

        String chron = '0 0 23 * * ?'; 
        String jobid = System.schedule('Test ECOM_EmailNotificationsSchedulable', chron, schedulableInstance);
        Test.stopTest();
        
    }
}