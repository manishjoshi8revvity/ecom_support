trigger FS_ProductPlant on FS_ProductPlant__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    FS_Utility.executeHandler(new FS_ProductPlantTriggerHandler());
}