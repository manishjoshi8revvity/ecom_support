public with sharing class FS_ComplaintTriggerHandler implements FS_Utility.ITriggerHandler{
    
    public FS_ComplaintTriggerHandler () {
    }
    
    public void beforeInsert() {
        List<FS_Complaint__c> newList = Trigger.new;
        FS_ComplaintManager.updateLookups(newList, null);
    }
    public void afterInsert() {}
    public void beforeUpdate() {
        List<FS_Complaint__c> newList = Trigger.new;
        Map<Id, FS_Complaint__c> oldMap = (Map<Id, FS_Complaint__c>) Trigger.oldMap;
        FS_ComplaintManager.updateLookups(newList, oldMap);
    }
    public void afterUpdate()
    {
        List<FS_Complaint__c> newList = Trigger.new;
        Map<Id, FS_Complaint__c> oldMap = (Map<Id, FS_Complaint__c>) Trigger.oldMap;
        FS_ComplaintManager.deleteComplaintChildRecords(newList, oldMap);
    }
    public void beforeDelete() {}
    public void afterDelete() {}
    public void afterUndelete() {}   
}