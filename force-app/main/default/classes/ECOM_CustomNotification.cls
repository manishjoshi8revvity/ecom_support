/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    RWPS - 1287    
*
* 2. Description - This class is an utility class for application logs.
*
*
* 3. Objects referenced
*    - Order
*    - Group
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_OrderCreateFlowController
*	 - ECOM_ApplicationLogsUtil
* 6. Test Class Name: 
*	- ECOM_OrderCreateFlowController_Test
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Manoj 2024.08.27 RWPS-1287 Need a notification for order types other than ZWCC & ZWEB 
*************************************************************/
public class ECOM_CustomNotification {
    public String notificationType;
    public static String CLASSNAME = 'ECOM_CustomNotification';
    public ECOM_CustomNotification(String notificationType){
        this.notificationType = notificationType;
    }
    
    public Map<String,Object> sendNotification(object obj ,String objectName){
        Map<String,Object> response = new Map<String,Object>();
		Set<String> recipientsIds = new Set<String>();
        String supportData = '';
        // Get the Id for our custom notification type
        CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName=:notificationType];
        // Create a new custom notification
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        if(objectName=='Order'){
            Order order = (Order )obj;
            List<Group> largePackOrderGroups = [SELECT Id,Name,DeveloperName FROM Group WHERE  DeveloperName =:System.label.ECOM_Large_Order_Notification_Group_Name];
            if(largePackOrderGroups.size()> 0){
                recipientsIds.add(largePackOrderGroups[0].Id);
                String notificationLabel = System.Label.ECOM_Large_Order_Notification_Msg;
                List<String> params = new List<String> {order.OrderNumber};
                String formattedLabel = String.format(notificationLabel, params);
                notification.setTitle(formattedLabel);
                notification.setTargetId(order.Id);
                notification.setBody(formattedLabel);
            }
            supportData+= 'Order id :' +order.id + ' Order number : '+order.OrderNumber +' Recipients :'+ JSON.serialize(recipientsIds);
           
        } 
        // Set the notification type and target
        notification.setNotificationTypeId(notificationType.Id);
        // Actually send the notification
        try {
            notification.send(recipientsIds);
        }
        catch (Exception ex) {
            ECOM_ApplicationLogsUtil.logFailure(ex, 'Custom Notification', CLASSNAME, 'sendNotification', supportData);
        }finally{
           ECOM_ApplicationLogsUtil.logApplicationApiData('Custom Notification',CLASSNAME,'sendNotification',supportData,'');
        }
        
        return response;
        
    }

}