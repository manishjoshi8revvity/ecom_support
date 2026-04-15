/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM- 1931    
*
* 2. Description - This class is used as a Test Class for ECOM_InvoiceURLExpirySchedulable.
*
*
* 3. Objects referenced
*    - None
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_InvoiceURLExpirySchedulable
*
* 6. Test Class Name: 
*    - ECOM_InvoiceURLExpirySchedulable_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*   - Gaurang Arora 2024.06.11
**************************************************************/
@isTest
public class ECOM_InvoiceURLExpirySchedulable_Test {
	@isTest
    static void testExecute() {
       	ECOM_Invoice__c invoice = new ECOM_Invoice__c();
        invoice.ECOM_Url_Generated_Time__c = System.now().addDays(-5);
        invoice.ECOM_Download_URL__c = 'test';
        insert invoice;
        Test.startTest();
        // Create an instance of the Schedulable class
        ECOM_InvoiceURLExpirySchedulable schedulableInstance = new ECOM_InvoiceURLExpirySchedulable();

        String chron = '0 0 23 * * ?'; 
        String jobid = System.schedule('Test ECOM_InvoiceURLExpirySchedulable', chron, schedulableInstance);
        Test.stopTest();
        
    }
}