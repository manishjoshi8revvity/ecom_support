trigger FS_WorkDetail on WorkOrderLineItem (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    FS_Utility.executeHandler(new FS_WorkDetailTriggerHandler());
}