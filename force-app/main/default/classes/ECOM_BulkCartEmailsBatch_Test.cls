/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-    
*
* 2. Description - This class is a Test class. for ECOM_BulkCartEmailNotificationsBatch
				 - Call the ECOM_TestUtilClass to create test data and test each methods.
					- Used System Assertion to Confirm the functionalities.
*
*
* 3. Objects referenced
*    - ECOM_Abandoned_Cart_Notification__mdt
*    - ECOM_Application_Logs__c
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
*
* 5. Dependant Class(es):
*    - ECOM_TestUtil
*	 - ECOM_BulkCartEmailNotificationsBatch
	 - Webcart
* 6. Test Class Name: 
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Manoj 2023.07.19
*    - Poonam 2025.07.24 Added method testPublicNotificationBatchWithExecuteCoverage - RWPS-3306

*************************************************************/

@isTest
public with sharing class ECOM_BulkCartEmailsBatch_Test {

    @TestSetup
    static void setupTestData() 
    {
        ECOM_TestUtil.initialStorefrontSetup();
    }
    
    @isTest
    public static void testPublicNotificationBatch()
    {
        User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
            EmailTemplate newet = ECOM_TestUtil.createEmailTemplate();
            insert newet;        
            List<Webcart> carts = [SELECT Id FROM WebCart ORDER BY CREATEDDATE DESC LIMIT 2];
            ECOM_BulkCartEmailNotificationsBatch obj = new ECOM_BulkCartEmailNotificationsBatch();
            String result;
            test.startTest();
			ECOM_Abandoned_Cart_Notification__mdt notification = [SELECT Id,Cart_Email_Template__c,Country__c,Cart_Price_Bucket_Min__c,Cart_Price_Bucket_Max__c 
                                                     FROM ECOM_Abandoned_Cart_Notification__mdt where IsActive__c=true   LIMIT 1];
            EmailTemplate et = [SELECT Id,DeveloperName FROM EmailTemplate WHERE DeveloperName = :notification.Cart_Email_Template__c LIMIT 1];
            newet.DeveloperName = et.DeveloperName;
            update newet;
            DateTime cartLastModifiedDateMax = DateTime.now();
        	DateTime cartLastModifiedDateMin = cartLastModifiedDateMax.addDays(-30);
            List<String> countries = new List<String>();
        	countries.add(notification.Country__c);
           	List<String> statuses = new List<String>{'Active', 'Checkout'};
            User usr = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
            System.runAs(usr)
        	{
                Map<String,List<String>> countryToIsoMap = ECOM_CustomMetadataService.getCountriesISO(countries);
                ECOM_BulkCartEmailNotificationsBatch batchInstance = new ECOM_BulkCartEmailNotificationsBatch(notification, cartLastModifiedDateMax, cartLastModifiedDateMin, countries, statuses, countryToIsoMap);
                result = Database.executeBatch(batchInstance);
                Database.BatchableContext bc;
                batchInstance.execute(bc,carts);
                test.stopTest();
            }       
        	System.assertNotEquals(null,result,'Wrong Output');
        }
        
    }

    //RWPS-3306 - START
    @isTest
    public static void testPublicNotificationBatchWithExecuteCoverage()
    {
        User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
            EmailTemplate newet = ECOM_TestUtil.createEmailTemplate();
            insert newet;
            List<Webcart> carts = [SELECT Id FROM WebCart ORDER BY CREATEDDATE DESC LIMIT 2];
            ECOM_BulkCartEmailNotificationsBatch obj = new ECOM_BulkCartEmailNotificationsBatch();
                String result;
                test.startTest();
            ECOM_Abandoned_Cart_Notification__mdt newNotification = new ECOM_Abandoned_Cart_Notification__mdt(
                Cart_Email_Template__c = newet.DeveloperName,
                Country__c = '',
                Cart_Price_Bucket_Min__c = 0,
                Cart_Price_Bucket_Max__c = 99999
            );
            DateTime cartLastModifiedDateMax = DateTime.now();
            DateTime cartLastModifiedDateMin = cartLastModifiedDateMax.addDays(-30);
            EmailTemplate et = [SELECT Id,DeveloperName FROM EmailTemplate WHERE DeveloperName = :newNotification.Cart_Email_Template__c LIMIT 1];
            newet.DeveloperName = et.DeveloperName;
            update newet;
            List<String> countries = new List<String>();
            List<String> statuses = new List<String>{'Active', 'Checkout'};
            User usr = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
            System.runAs(usr)
            {
                Map<String, List<String>> countryToIsoMap = new Map<String, List<String>>();
                countryToIsoMap.put('TestCountry', new List<String>{'US', 'CA'});
                ECOM_BulkCartEmailNotificationsBatch batchInstance = new ECOM_BulkCartEmailNotificationsBatch(newNotification, cartLastModifiedDateMax, cartLastModifiedDateMin, countries, statuses, countryToIsoMap);
                result = Database.executeBatch(batchInstance);
                test.stopTest();
                System.assertNotEquals(null, result, 'Batch execution did not return a result');
            }
        }
    }
    //RWPS-3306 - END

}