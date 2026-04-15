/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM- 1931    
*
* 2. Description - This scheduable class is used to trigger the batch job - ECOM_InvoiceURLExpiryBatch.
*
*
* 3. Objects referenced
*    - None
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_InvoiceURLExpiryBatch
*
* 6. Test Class Name: 
*    - ECOM_InvoiceURLExpirySchedulableTest
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*   - Gaurang Arora 2024.06.11
*************************************************************/
public class ECOM_InvoiceURLExpirySchedulable implements Schedulable{
    public void execute(SchedulableContext sc)
    {
        Database.executeBatch(new ECOM_InvoiceURLExpiryBatch(),2000);
    }
}