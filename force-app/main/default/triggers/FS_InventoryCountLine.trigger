trigger FS_InventoryCountLine on FS_InventoryCountLine__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    FS_Utility.executeHandler(new FS_InventoryCountLineTriggerHandler());
}