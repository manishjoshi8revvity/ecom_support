trigger FS_Experience on FS_Experience__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
   FS_Utility.executeHandler(new FS_ExperienceTriggerHandler());
}