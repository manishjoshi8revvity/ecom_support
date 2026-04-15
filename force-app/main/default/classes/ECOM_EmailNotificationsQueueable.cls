/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM- 119    
*
* 2. Description - This queueable job is triggered when the cart count exceeds the threshold to move them to a batch job.
*
*
* 3. Objects referenced
*    - ECOM_Abandoned_Cart_Notification__mdt
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_EmailNotificationsBatch
*    - ECOM_BulkCartEmailNotificationsBatch
*
* 6. Test Class Name: 
*    - ECOM_EmailNotificationsQueueable_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*   - Vipul Goyal 2023.08.09
*   - Vipul Goyal 2024.04.23 UPdates the execute method to handle Countries based on different ISO Codes.
*************************************************************/
public class ECOM_EmailNotificationsQueueable implements Queueable{
    
    ECOM_Abandoned_Cart_Notification__mdt notification;
    DateTime cartLastModifiedDateMax;
    DateTime cartLastModifiedDateMin;
    List<String> statuses;
    List<String> countries;
    Map<String,List<String>> countryToIsoMap = new Map<String,List<String>>();
    

    /**
    * @description Non-parameterized Constructor
    * @author Vipul Goyal | 04-23-2024 
    **/
    public ECOM_EmailNotificationsQueueable()
    {   
    }
        
    /**
    * @description  Constructor to accept the values essential to retrieve cart data.
    * @author Vipul Goyal | 04-23-2024 
    * @param notification 
    * @param cartLastModifiedDateMax 
    * @param cartLastModifiedDateMin 
    * @param countries 
    * @param statuses 
    * @param countryToIsoMap 
    **/
    public ECOM_EmailNotificationsQueueable(ECOM_Abandoned_Cart_Notification__mdt notification,DateTime cartLastModifiedDateMax,DateTime cartLastModifiedDateMin,
                                            List<String> countries,List<String> statuses,Map<String,List<String>> countryToIsoMap)
    {
        this.notification=notification;
        this.cartLastModifiedDateMax=cartLastModifiedDateMax;
        this.cartLastModifiedDateMin=cartLastModifiedDateMin;
        this.countries=countries;
        this.statuses=statuses;
        this.countryToIsoMap = countryToIsoMap;
    }
    
    /**
    * @description Standard Queueable method that is being used to execute the batch job.
    * @author Vipul Goyal | 04-23-2024 
    * @param qc 
    **/
    public void execute(QueueableContext qc)
    {
        //This method invokes a batch class to handle all the pending carts.
        Database.executeBatch(new ECOM_BulkCartEmailNotificationsBatch(notification,cartLastModifiedDateMax,cartLastModifiedDateMin,countries,statuses,countryToIsoMap),100);
    }

}