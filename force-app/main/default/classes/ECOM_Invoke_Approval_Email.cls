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
* 7. Test Class Name: ECOM_Invoke_Approval_Email_Test
*
* 8. Author Name(s): 
*    - Sathiya 06/13/2024
*
************************************************************************/ 
public class ECOM_Invoke_Approval_Email {
    // Invocable method initiation
	@InvocableMethod(label='Invoke Approval Email Action' description='To Initate the approval email with async method' category='Order')
    public static void initApprovalEmail(List<Order> orderList){
        // Check if orderList is empty
        if(!orderList.isEmpty()){
            for(Order order: orderList){
                System.enqueueJob(new ECOM_Invoke_Email_Queueable(order, (order?.Status == 'Pending Review' || order?.Status == 'Rejected')?'Approval':'Order'));
            }
        }
    }
}