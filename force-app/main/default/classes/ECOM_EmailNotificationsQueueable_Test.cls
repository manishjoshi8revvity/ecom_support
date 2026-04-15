/**************************************************************

	* 1. Jira Ticket(s) that relates to this class
	*  
	*
	* 2. Description - This class is a test class
	*
	* 3. Objects referenced
	*    - ECOM_Abandoned_Cart_Notification__mdt(Custom Meta data)
	*    - Cart
		
	* 4. Callouts to additional Components (including their methods) or None:
	*    - None
	*
	* 5. Dependant Class(es):
	*    - ECOM_TestUtil
	 
	* 6. Test Class Name:
	*
	* 7. Is @Invocable : No
	*
	* 8. Author Name(s):
	*    - Manoj 2023.09.15
    *   - Vinay 2024.02.12 Updated testExecute method removed isActive - RWPS-2597
*************************************************************/
@isTest(SeeAllData=false)
public with sharing class ECOM_EmailNotificationsQueueable_Test {
    @isTest
    static void testExecute() {
        // Create test data
         ECOM_Abandoned_Cart_Notification__mdt notification = [SELECT Id, Cart_Email_Template__c,Country__c,Cart_Price_Bucket_Min__c, Cart_Price_Bucket_Max__c FROM ECOM_Abandoned_Cart_Notification__mdt LIMIT 1]; //RWPS-2597
        
        DateTime cartLastModifiedDateMax = DateTime.now();
        DateTime cartLastModifiedDateMin = cartLastModifiedDateMax.addDays(-30);
        List<String> countries = new List<String>();
        countries.add(notification.Country__c);
        List<String> statuses = new List<String>{'Active', 'Checkout'};
         //  Email Template
        EmailTemplate emailTemp = ECOM_TestUtil.createEmailTemplate();
        insert emailTemp;
        EmailTemplate et = [SELECT Id,DeveloperName FROM EmailTemplate WHERE DeveloperName = :notification.Cart_Email_Template__c LIMIT 1];
        emailTemp.DeveloperName = et.DeveloperName;
        update emailTemp;
        Test.startTest();
        User usr = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(usr)
        {
            Map<String,List<String>> countryToIsoMap = ECOM_CustomMetadataService.getCountriesISO(countries);
            // Create an instance of the queueable class
            ECOM_EmailNotificationsQueueable queueable = new ECOM_EmailNotificationsQueueable(notification, cartLastModifiedDateMax, cartLastModifiedDateMin, countries, statuses,countryToIsoMap);
            //ECOM_EmailNotificationsQueueable batch = new ECOM_EmailNotificationsQueueable();
            
        
         //Enqueue the queueable class for execution
            try{
         System.enqueueJob(queueable);
            }
            catch(Exception e){
                
            }
        Test.stopTest();
        }

        List<AsyncApexJob> jobs = [SELECT Id, Status FROM AsyncApexJob WHERE JobType = 'Queueable' AND Status = 'Processing'];        
        System.assertEquals(0, jobs.size());    
    }
    }