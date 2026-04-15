/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM - 125 
*
* 2. Description - This Scheduler invokes batch job to Activate orders and also to create Order Summaries
*
*
* 3. Objects referenced
*    - Order
*    - OrderItem
* 	 - Order Summary
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_OrderRepo
*    - ECOM_OrderActivateBatch
*
* 6. Test Class Name: 
*    - ECOM_OrderActivateScheduler_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Rani Thumma 2023.11.21
*************************************************************/
public class ECOM_OrderActivateScheduler implements Schedulable{
    //This is a method to invoke the batch job
    public void execute(SchedulableContext sc)
    {
        String query = ECOM_OrderRepo.getShippedOrders();
        Database.executeBatch(new ECOM_OrderActivateBatch(query),10);
    }

}