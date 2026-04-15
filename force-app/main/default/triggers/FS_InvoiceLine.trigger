trigger FS_InvoiceLine  on FS_Proforma_Invoice_Line__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    FS_Utility.executeHandler(new FS_InvoiceLineTriggerHandler());
}