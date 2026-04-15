public with sharing class FS_InvoiceLineTriggerHandler  implements FS_Utility.ITriggerHandler{
    
    public FS_InvoiceLineTriggerHandler() {
    }
    
    public void beforeInsert()
    {
        List<FS_Proforma_Invoice_Line__c> newList = Trigger.new;
        // SVMTINT-654 - added 2019-05-01
        FS_InvoiceManager.updateCancelationDetailFields(newList, null);
    }
    public void afterInsert() 
    {
        //List<FS_Proforma_Invoice_Line__c> newList = Trigger.new;
        //FS_InvoiceManager.updateDetailFields(newList, null);
        //FS_InvoiceManager.updateWOstatusToInvoiced(newList); 
        // For SVMXCFG-607 - added 6/18/18
        //FS_InvoiceManager.copyBillingAddressFromAcct(newList);
    }

    public void beforeUpdate()
    {
        List<FS_Proforma_Invoice_Line__c> newList = Trigger.new;
        Map<Id, FS_Proforma_Invoice_Line__c> oldMap = (Map<Id, FS_Proforma_Invoice_Line__c>) Trigger.oldMap;
        // SVMTINT-654 - added 2019-05-01
        FS_InvoiceManager.updateCancelationDetailFields(newList, oldMap);
    }
    public void afterUpdate() {
        List<FS_Proforma_Invoice_Line__c> newList = Trigger.new;
        Map<Id, FS_Proforma_Invoice_Line__c> oldMap = (Map<Id, FS_Proforma_Invoice_Line__c>) Trigger.oldMap;
        // SVMTINT-654 - added 2019-05-01
        FS_InvoiceManager.adjustDMR(newList, oldMap);
    }
    public void beforeDelete() {}
    public void afterDelete() {}
    public void afterUndelete() {}   
}