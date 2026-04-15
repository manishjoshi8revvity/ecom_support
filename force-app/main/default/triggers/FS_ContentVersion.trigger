trigger FS_ContentVersion on ContentVersion (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
 FS_Utility.executeHandler(new FS_ContentVersionTriggerHandler());
}