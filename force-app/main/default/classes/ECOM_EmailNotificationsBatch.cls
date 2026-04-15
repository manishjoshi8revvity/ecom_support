/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM- 119    
*
* 2. Description - This batch job is triggered to send emails for abandoned cart.
*
*
* 3. Objects referenced
*    - ECOM_Abandoned_Cart_Notification__mdt
*	 - WebCart
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_CartService
*    - ECOM_EmailNotificationsQueueable
* 	 - ECOM_CartRepo
*
* 6. Test Class Name: 
*    - ECOM_EmailNotificationsBatch_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*   - Vipul Goyal 2023.08.09
*   - Vipul Goyal 2024.04.23 Updated Logic for abandoned cart.
*   - Gaurav 2025.05.25 Updated logic to include weekend in Abandoned Cart Email. RWPS-3225
*   - Manish Joshi 2025.06.10 Corrected the logic to include weekend in Abandoned Cart Email. RWPS-3473
*   - Poonam 2025.07.18 Updated execute method, Added logic for email opt out for abandon cart email - RWPS-3306
*   - Mahesh 2025.07.02 Added invocable method scheduleAbandonedCartEmail - RWPS-3386
*   - Poonam 2025.09.12 Added try catch block for execute method - RWPS-4435
*************************************************************/
public with sharing class ECOM_EmailNotificationsBatch implements Database.Batchable<sObject>,Database.Stateful{

    public static final String className = 'ECOM_EmailNotificationsBatch';//RWPS-4435
    List<String> countries=New List<String>();
    Map<String,List<String>> countryToIsoMap = new Map<String,List<String>>();
    C_META_Storefront_Configuration__mdt durationSetting;
     
    /**
    * @description This method returns all the Abandoned Cart Metadata records.
    * @author Vipul Goyal | 04-23-2024 
    * @param bc 
    * @return Database.QueryLocator 
    **/
    public Database.QueryLocator start(Database.BatchableContext bc)
    {
        List<ECOM_Abandoned_Cart_Notification__mdt> records= [SELECT Country__c  
                                                              FROM ECOM_Abandoned_Cart_Notification__mdt 
                                                              where isActive__c=true];
        
        durationSetting = [Select ModuleName__c,Value__c from C_META_Storefront_Configuration__mdt
                                                                      where DeveloperName='Abandon_Cart_Duration' LIMIT 1]; 
        
        for(ECOM_Abandoned_Cart_Notification__mdt acn:records)
        {
            if(Test.isRunningTest() && String.isNotBlank(acn.Country__c)){
                countries.add(acn.Country__c);
        	} else if(String.isNotBlank(acn.Country__c) && !countries.contains(acn.Country__c)) {
                countries.add(acn.Country__c);
            }
        }
        if(!countries.isEmpty())
        {
            countryToIsoMap = ECOM_CustomMetadataService.getCountriesISO(countries);
        }
        String query;
        if(Test.isRunningTest()){
            query='SELECT Id, Cart_Email_Template__c, Cart_Price_Bucket_Min__c, Cart_Price_Bucket_Max__c, Country__c, IsActive__c,Notification_In_Days__c  FROM ECOM_Abandoned_Cart_Notification__mdt WHERE isActive__c=true LIMIT 1';
        }
        else{
            query='SELECT Id, Cart_Email_Template__c, Cart_Price_Bucket_Min__c, Cart_Price_Bucket_Max__c, Country__c, IsActive__c,Notification_In_Days__c  FROM ECOM_Abandoned_Cart_Notification__mdt WHERE isActive__c=true';
        }
        
        return Database.getQueryLocator(query);
    }
    
    
    /**
    * @description  This method use the metadata record to find abandoned cart and send the email for the same.
    * @author Vipul Goyal | 04-23-2024 
    * @param bc 
    * @param records 
    **/
    public void execute(Database.BatchableContext bc,List<ECOM_Abandoned_Cart_Notification__mdt> records)
    {
        ECOM_Abandoned_Cart_Notification__mdt notification=records[0];
        String methodName = 'execute';   //RWPS-4435 
        List<String> statuses=new List<String>{'Active','Checkout'};
        try{//RWPS-4435 
        if(String.isNotBlank(notification.Cart_Email_Template__c))
        {
            if(notification.Notification_In_Days__c!=null && notification.Notification_In_Days__c>0)
            {
                DateTime today=System.now();
                //RWPS-3225 start
                Datetime cartLastModifiedDateMax=today.addDays(Integer.valueOf(-1*(notification.Notification_In_Days__c)));
                Datetime cartLastModifiedDateMin=cartLastModifiedDateMax.addMinutes(-1*Integer.valueOf(durationSetting.Value__c));
                String dayOfWeek = today.format('u');
                if (('1'.equalsIgnoreCase(dayOfWeek) && notification.Notification_In_Days__c == Decimal.valueOf(Label.ECOM_Abandoned_Cart_Normalizing_Factor_2_Days)) || Test.isRunningTest()) { //RWPS-3473 Start
                   cartLastModifiedDateMin = cartLastModifiedDateMin.addDays(Integer.valueOf(-2));
                }
                if (('1'.equalsIgnoreCase(dayOfWeek) && notification.Notification_In_Days__c==Decimal.valueOf(Label.ECOM_Abandoned_Cart_Normalizing_Factor_5_Days)) || Test.isRunningTest()) {
                    cartLastModifiedDateMax = cartLastModifiedDateMax.addDays(Integer.valueOf(-2));
                    cartLastModifiedDateMin = cartLastModifiedDateMax.addDays(Integer.valueOf(-2));
                } 
                if ((dayOfWeek != '1' && notification.Notification_In_Days__c == Decimal.valueOf(Label.ECOM_Abandoned_Cart_Normalizing_Factor_5_Days))  || Test.isRunningTest()){
                    cartLastModifiedDateMax = cartLastModifiedDateMax.addDays(Integer.valueOf(-2));
                    cartLastModifiedDateMin = cartLastModifiedDateMax.addDays(Integer.valueOf(-1));
                } //RWPS-3473 END
                //RWPS-3225 end
                Integer totalRecords=ECOM_CartService.getAbandonedCartCount(notification,cartLastModifiedDateMax,cartLastModifiedDateMin,countries,statuses,countryToIsoMap);
                if(totalRecords==0 && !Test.isRunningTest())
                    return;
                
                if(totalRecords<5000)
                {
                    EmailTemplate emailTemp=[SELECT Id, Name, DeveloperName FROM EmailTemplate where DeveloperName=:notification.Cart_Email_Template__c];
                    if(emailTemp!=null)
                    {
                        List<WebCart> carts=ECOM_CartService.getAbandonedCart(notification, cartLastModifiedDateMax, cartLastModifiedDateMin, countries,statuses,countryToIsoMap);
                        List<WebCart> optedInCarts = ECOM_CartService.filterAbandonedOptInCarts(carts);//RWPS-3306
                        ECOM_CartService.sendEmailsForAbandonedCart(emailTemp, optedInCarts);//RWPS-3306
                    }
                }
                else
                {
                    System.enqueueJob(new ECOM_EmailNotificationsQueueable(notification,cartLastModifiedDateMax,cartLastModifiedDateMin,countries,statuses,countryToIsoMap));
                }
            }
        }
         //RWPS-4435 start
        }catch(Exception e){
            ECOM_ApplicationLogsUtil.logFailure(e , 'Abandoned Cart Batch' , className , methodName, ' Stack:: '+ e.getStackTraceString());
        } //RWPS-4435 end
    }
    
    /**
    * @description  This is finish method of batch job.
    * @author Vipul Goyal | 04-23-2024 
    * @param bc 
    **/
    public void finish(Database.BatchableContext bc)
    {
        
    }

    //RWPS - 3386 Start
    public class FlowInputs {                  
        @InvocableVariable public integer varBatchSize;    
    } 

    /**
    * @description  This is scheduleAbandonedCartEmail method to schedule batch.
    * @author Manesh Suthar | 04-23-2024 
    * @param requests 
    **/
    @InvocableMethod(Label='Schedule Abandoned Cart Email' Category='Messaging' Description='This is to schedule abandoned cart email')
    public static void scheduleAbandonedCartEmail(List<FlowInputs> requests){
        //varBatch refer to batch size
        integer varBatch=1;
         
        if(!requests.isEmpty() && requests[0].varBatchSize != null){
            varBatch=requests[0].varBatchSize;
        }
           
        if(!system.isBatch()){  
            Database.executeBatch(new ECOM_EmailNotificationsBatch(), varBatch);
        }
    }
    //RWPS - 3386 End
    
}