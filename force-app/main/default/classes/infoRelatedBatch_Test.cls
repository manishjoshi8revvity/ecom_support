@isTest 
public class infoRelatedBatch_Test {

    @testSetup static void setup() {
        // create account for test class
       Account ac= new Account(Name ='Test OppLDR',Phone='1234567890',
                               PKI_SAP_Phone__c='0987654321',
                              Billingstreet='test street',Billingcity='test city',Billingstate ='Texas',
                               Billingpostalcode='007',BillingCountry='United States'); 
        insert ac;
        // Create Info central row for test class
        INFO_Central__c infocnt = new INFO_Central__c();
        infocnt.Name='1234567890';
        infocnt.Input_Value__c='1234567890';
        infocnt.Type__c='Phone';
        insert infocnt; 
    }
    static testMethod void testMethod1(){
        string str='SELECT Id,name,Phone,PKI_SAP_Phone__c,Account_Email__c,BillingStreet,BillingCity,BillingState,BillingPostalCode,BillingCountry from Account';
        string st='Name,Phone,PKI_SAP_Phone__c,Account_Email__c,BillingStreet,BillingCity,BillingState,BillingPostalCode,BillingCountry';
        Database.executeBatch(new infoRelatedBatch(str,st), 200);
   }
}