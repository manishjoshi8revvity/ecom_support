trigger FS_Invoice  on FS_Proforma_Invoice__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    FS_Utility.executeHandler(new FS_InvoiceTriggerHandler());
}