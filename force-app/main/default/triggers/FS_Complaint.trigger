trigger FS_Complaint on FS_Complaint__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    FS_Utility.executeHandler(new FS_ComplaintTriggerHandler());
}