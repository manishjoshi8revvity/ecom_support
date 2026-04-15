/*
 *  Trigger Handler for Proforma Invoice [SVMXC__Proforma_Invoice__c]
 *  2022-10-24      Bolt Data - E. Ross      Modifications for Polaris Project.
 */
public with sharing class FS_InvoiceTriggerHandler implements FS_Utility.ITriggerHandler{
    
    public FS_InvoiceTriggerHandler () {
    }
    
    public void beforeInsert() 
    {
        List<FS_Proforma_Invoice__c> newList = Trigger.new;
        Map<Id, FS_Proforma_Invoice__c> oldMap = (Map<Id, FS_Proforma_Invoice__c>) Trigger.oldMap;

        FS_InvoiceManager.defaultFields(newList);
        FS_InvoiceManager.onNewInvoice(newList);
        FS_InvoiceManager.onCancellationInvoice(newList);
        //SMAX_PS_OwnedByCompanyManager.updateProformaInvObject(newList, oldMap);
    }

    public void afterInsert()
    {
        //List<FS_Proforma_Invoice__c> newList = Trigger.new;

        // Moved this to before insert/update
        //FS_InvoiceManager.onNewInvoice(newList);
    }

    public void beforeUpdate()
    {
        List<FS_Proforma_Invoice__c> newList = Trigger.new;
        Map<Id, FS_Proforma_Invoice__c> oldMap = (Map<Id, FS_Proforma_Invoice__c>) Trigger.oldMap;
        FS_InvoiceManager.onNewInvoice(newList);
        FS_InvoiceManager.unlockDMR(newList, oldMap);
        FS_InvoiceManager.copyPriceAdjustments(newList, oldMap);
        FS_InvoiceManager.invoiceNotRequired(newList, oldMap);
        //SMAX_PS_OwnedByCompanyManager.updateProformaInvObject(newList, oldMap);
    }

    public void afterUpdate() {
        List<FS_Proforma_Invoice__c> newList = Trigger.new;
        Map<Id, FS_Proforma_Invoice__c> oldMap = (Map<Id, FS_Proforma_Invoice__c>) Trigger.oldMap;
        FS_InvoiceManager.releaseInvoice(newList, oldMap);
        FS_InvoiceManager.rejectDMR(newList, oldMap);
        FS_InvoiceManager.cancelInvoice(newList, oldMap);
        FS_InvoiceManager.reviewDMRAdjustments(newList, oldMap);
        FS_InvoiceManager.updateRejectionReason(newList, oldMap);
    }
    public void beforeDelete() {}
    public void afterDelete() {}
    public void afterUndelete() {}   
}