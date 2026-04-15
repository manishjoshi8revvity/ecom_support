/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM- 1931   
*
* 2. Description - This batch job is triggered to clear invoice Download Url field after expiry time
*
*
* 3. Objects referenced
*    - ECOM_Invoice__c
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_EmailNotificationsQueueable
*
* 6. Test Class Name: 
*    - ECOM_InvoiceURLExpiryBatch
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*   - Gaurang Arora 2024.06.11
*************************************************************/
public with sharing class ECOM_InvoiceURLExpiryBatch implements Database.Batchable<sObject> {

    public Database.QueryLocator start(Database.BatchableContext bc){
        Datetime currentTime = Datetime.now().addDays(-1*(Integer.valueOf(System.Label.ECOM_InvoiceURL_Expiry_Days)));
        String query = 'SELECT Id, ECOM_Download_URL__c,ECOM_URL_Generated_Time__c FROM ECOM_Invoice__c WHERE ECOM_Download_URL__c<>NULL AND ECOM_URL_Generated_Time__c<=:currentTime LIMIT 49999';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<ECOM_Invoice__c> invoices){
        if(!invoices.isEmpty()){
            for(ECOM_Invoice__c invoice : invoices) {
                invoice.ECOM_Download_URL__c = null;
                invoice.ECOM_URL_Generated_Time__c = null;
            }
        update invoices;
        }
    }

    public void finish(Database.BatchableContext bc){

    }
}