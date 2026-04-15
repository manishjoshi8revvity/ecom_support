public with sharing class FS_ExperienceTriggerHandler implements FS_Utility.ITriggerHandler{

    public FS_ExperienceTriggerHandler () {
    }

    public void beforeInsert() {
        List<FS_Experience__c> newList = Trigger.new;
        FS_ExperienceManager.syncSkills(newList, null);
        FS_ExperienceManager.updateFinalScore(newList, null);
    }

    public void afterInsert() {}

    public void beforeUpdate() {
        List<FS_Experience__c> newList = Trigger.new;
        Map<Id, FS_Experience__c> oldMap = (Map<Id, FS_Experience__c>) Trigger.oldMap;
        FS_ExperienceManager.syncSkills(newList, oldMap);
        FS_ExperienceManager.updateFinalScore(newList, oldMap);
    }

    public void afterUpdate() {}
    public void beforeDelete() {}
    public void afterDelete() {}
    public void afterUndelete() {}
}