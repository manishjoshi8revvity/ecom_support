/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM - 125 
*
* 2. Description - This Scheduler invokes batch job to Sync Orders to SAP via Boomi
*
*
* 3. Objects referenced
*    - Order
*    - OrderItem
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_OrderRepo
*    - ECOM_OrderCreateBatch
*
* 6. Test Class Name: 
*    - ECOM_OrderCreateScheduler_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Rani Thumma 2023.11.21
*************************************************************/
public class ECOM_OrderCreateScheduler implements Schedulable{
    
    //This is a method to invoke the batch job
    public void execute(SchedulableContext sc)
    {
        String query = ECOM_OrderRepo.getQueryStringForBatch(null);
        Database.executeBatch(new ECOM_OrderCreateBatch(query),1);
    }

}