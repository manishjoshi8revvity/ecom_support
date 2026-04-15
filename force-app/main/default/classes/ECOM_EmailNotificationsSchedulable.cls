/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM- 119    
*
* 2. Description - This scheduable class is used to trigger the batch job - ECOM_EmailNotificationsSchedulable.
*
*
* 3. Objects referenced
*    - None
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_EmailNotificationsBatch
*
* 6. Test Class Name: 
*    - ECOM_EmailNotificationsSchedulable_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*   - Vipul Goyal 2023.08.11
*   - Vipul Goyal 2024.04.23 UPdated comments.
*************************************************************/
public class ECOM_EmailNotificationsSchedulable implements Schedulable{
    
    /**
    * @description This is a method to invoke the batch job
    * @author Vipul Goyal | 04-23-2024 
    * @param sc 
    **/
    public void execute(SchedulableContext sc)
    {
        Database.executeBatch(new ECOM_EmailNotificationsBatch(),1);
    }

}