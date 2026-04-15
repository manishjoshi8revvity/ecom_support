/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM- 119    
*
* 2. Description - This batch job is triggered to send emails for abandoned cart.
*				- send emails to the owner of abandoned carts and notify the owner
				- use custom metadata ECOM_Abandoned_Cart_Notification__mdt to fetch the email templates
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
*
* 6. Test Class Name: 
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*   - Vipul Goyal 2023.08.09
*   - Vipul Goyal 2024.04.23 Updated logic for Abandoned Carts and Introduced an new method to handle query creation.
*	- Vipul Goyal 2024.04.30 Updated query.
*   - Poonam Shukla 2025.07.18 Added logic for Opt in Abandoned Carts - RWPS-3306
*************************************************************/
public class ECOM_BulkCartEmailNotificationsBatch implements Database.Batchable<sObject>,Database.Stateful{
    
    ECOM_Abandoned_Cart_Notification__mdt notification;
    DateTime cartLastModifiedDateMax;
    DateTime cartLastModifiedDateMin;
    List<String> countries;
    List<String> statuses;
    EmailTemplate emailTemp;
    Map<String,List<String>> countryToIsoMap = new Map<String,List<String>>();
    
    /**
    * @description Non-parameterized Constructor
    * @author Vipul Goyal | 04-23-2024 
    **/
    public ECOM_BulkCartEmailNotificationsBatch()
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
    public ECOM_BulkCartEmailNotificationsBatch(ECOM_Abandoned_Cart_Notification__mdt notification,DateTime cartLastModifiedDateMax,DateTime cartLastModifiedDateMin,List<String> countries,List<String> statuses,Map<String,List<String>> countryToIsoMap)
    {
        this.notification=notification;
        this.cartLastModifiedDateMax=cartLastModifiedDateMax;
        this.cartLastModifiedDateMin=cartLastModifiedDateMin;
        this.countries=countries;
        this.statuses=statuses;
        this.countryToIsoMap = countryToIsoMap;
    }
        
    /**
    * @description  This method is used to query all the carts that fulfill the metadata conditions.
    * @author Vipul Goyal | 04-23-2024 
    * @param bc 
    * @return Database.QueryLocator 
    **/
    public Database.QueryLocator start(Database.BatchableContext bc)
    {
        
        emailTemp=[SELECT Id, Name, DeveloperName FROM EmailTemplate where DeveloperName=:notification.Cart_Email_Template__c LIMIT 1];
        String mvcountry = '';
        String query=generateQuery(notification,countryToIsoMap);
        return Database.getQueryLocator(query);
    }
    
    /** 
    * @description  This method is used to send emails to the abandoned cart.
    * @author Vipul Goyal | 04-23-2024 
    * @param bc 
    * @param carts 
    **/
    public void execute(Database.BatchableContext bc,List<WebCart> carts)
    {
        if(emailTemp!=null)
        {
             if(!Test.isRunningTest()){
                List<WebCart> optedInCarts = ECOM_CartService.filterAbandonedOptInCarts(carts);//RWPS-3306
             }
            ECOM_CartService.sendEmailsForAbandonedCart(emailTemp, carts);
        }
    }
    
    
    /**
    * @description This is finish method of batch job.
    * @author Vipul Goyal | 04-23-2024 
    * @param bc 
    **/
    public void finish(Database.BatchableContext bc)
    {
        
    }
    
    
    /**
    * @description This method is used to create the query for the batch class. 
    * @author Vipul Goyal | 04-23-2024 
    * @param notification 
    * @param countryToIsoMap 
    * @return String 
    **/
    public static String generateQuery(ECOM_Abandoned_Cart_Notification__mdt notification,Map<String,List<String>> countryToIsoMap)
    {       
        
        String query='';
        query+='Select id,GrandTotalAmount,OwnerId,Owner.Name,Owner.Email,Owner.Phone,Default_Ship_to_ERP_Address__r.ApiCountry__c,Default_Ship_to_ERP_Address__r.fxAddress_CountryName__c';
        query+=' from WebCart where';
        query+=' GrandTotalAmount>='+notification.Cart_Price_Bucket_Min__c+' and GrandTotalAmount<='+notification.Cart_Price_Bucket_Max__c;
        query+=' and LastModifiedDate>=:cartLastModifiedDateMin and LastModifiedDate<=:cartLastModifiedDateMax';
        if(String.isBlank(notification.Country__c))
        {
            String countriesString='';
            for(String countryKey:countryToIsoMap.keySet())
            {
                countriesString+=ECOM_Util.convertListToQueryString(countryToIsoMap.get(countryKey),countriesString);
            }
            countriesString = '('+countriesString+')';
            query+=' and Default_Ship_to_ERP_Address__r.ApiCountry__c not in ';
            query+=countriesString+' and Default_Ship_to_ERP_Address__r.fxAddress_CountryName__c not in ';
            query+=countriesString;
        }else
        {
            String reqdCountries = ECOM_Util.convertListToQueryString(countryToIsoMap.get(notification.Country__c),'');
            reqdCountries='('+reqdCountries+')';
            query+=' and (Default_Ship_to_ERP_Address__r.ApiCountry__c in '+reqdCountries;
            query+=' or Default_Ship_to_ERP_Address__r.fxAddress_CountryName__c in '+reqdCountries+')';        
        }
       
        query+=' and Status in :statuses';
        return query;
    }

}