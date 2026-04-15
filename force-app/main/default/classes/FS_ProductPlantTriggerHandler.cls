public with sharing class FS_ProductPlantTriggerHandler implements FS_Utility.ITriggerHandler{
    
    public FS_ProductPlantTriggerHandler() {}

    public void beforeInsert() {
        List<FS_ProductPlant__c> newList = Trigger.new;
        FS_ProductManager.processProductPlant(newList, null);
    }
    public void afterInsert() {
        List<FS_ProductPlant__c> newList = Trigger.new;

    }
    public void beforeUpdate() {
        List<FS_ProductPlant__c> newList = Trigger.new;
        Map<Id, FS_ProductPlant__c> oldMap = (Map<Id, FS_ProductPlant__c>) Trigger.oldMap;
        FS_ProductManager.processProductPlant(newList, oldMap);
        
    }
    public void afterUpdate(){
        List<FS_ProductPlant__c> newList = Trigger.new;
        Map<Id, FS_ProductPlant__c> oldMap = (Map<Id, FS_ProductPlant__c>) Trigger.oldMap;

    }
    public void beforeDelete() {}
    public void afterDelete() {}
    public void afterUndelete() {}
}