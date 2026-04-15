/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM- 119,RWPS-3386   
*
* 2. Description - Test class to cover main class ECOM_EmailNotificationsBatch
*
*
* 3. Objects referenced
*    - ECOM_Abandoned_Cart_Notification__mdt , EmailTemplate
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - 
*
* 6. Test Class Name: 
*    - 
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*   - Vipul Goyal 2023.08.09
*   - Manish Joshi 2025.08.11 Added logic to call a scheduled flow for code coverage - RWPS-3386
*************************************************************/
@isTest
public class ECOM_EmailNotificationsBatch_Test {
    
    @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();        
    }
    
    static testMethod void testBatchExecution() {
        //  Abandoned Cart Notification metadata records
        ECOM_Abandoned_Cart_Notification__mdt notificationMetadata = [SELECT Id,Cart_Email_Template__c,Country__c,Cart_Price_Bucket_Min__c,Cart_Price_Bucket_Max__c 
                                                     FROM ECOM_Abandoned_Cart_Notification__mdt LIMIT 1];
        //  Email Template
        EmailTemplate emailTemp = ECOM_TestUtil.createEmailTemplate();
        insert emailTemp;
        Test.startTest();
        // RWPS-3386 - START
        Map<String, Object> inputs = new Map<String, Object>();
        inputs.put('varBatchSize', 1);
		Flow.Interview.L_FLOW_4305_ECOM_Cart_Abandoned_Notification_Scheduler myFlow =  new Flow.Interview.L_FLOW_4305_ECOM_Cart_Abandoned_Notification_Scheduler(inputs);
        myFlow.start();
        // RWPS-3386 - END
        Test.stopTest();
    }
    
}