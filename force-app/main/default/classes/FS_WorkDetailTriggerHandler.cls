public with sharing class FS_WorkDetailTriggerHandler implements FS_Utility.ITriggerHandler{
    
    public FS_WorkDetailTriggerHandler() {
    }
    
    public void beforeInsert() 
    {
        List<WorkOrderLineItem> newList = Trigger.new;
        // SVMXCFG-329 - Copy Currency Code from WO
        FS_WorkDetailManager.copyRelatedData(newList);
        FS_WorkDetailManager.updateTechOnDebriefLine(newList, null);
        FS_WorkDetailManager.updateUnitOfMeasureCodes(newList, null);
        FS_WorkDetailManager.updateFaultCodes(newList, null);
        FS_WorkDetailManager.updateFieldValues(newList, null);
        // ITSFDC-509 Lookup Product Plant (and related fields)
        FS_WorkDetailManager.lookupProductPlant(newList, null);
        // 08/04/2023 ITSVMX-1227 Update Work Order Plant and Work Center from either Technician or Additional Work Center
        FS_WorkDetailManager.updateWorkDetailPlantAndWorkCenter(newList, null);
    }
    
    public void afterInsert() 
    {
        List<WorkOrderLineItem> newList = Trigger.new;
       // FS_WorkDetailManager.consumeRemoteHours(newList, null);
        // 11/16/21 ITSVMX-624 Suggested Parts Automation
        //SMAX_PS_Kit_Parts.explodeWorkDetailKitParts(newList, null);
        //ITSVMX-705 Copy HSN Code for India Region
        FS_WorkDetailManager.addsummaryAfter(newList, null);
    }

    public void beforeUpdate() 
    {
        List<WorkOrderLineItem> newList = Trigger.new;
        Map<Id, WorkOrderLineItem> oldMap = (Map<Id, WorkOrderLineItem>) Trigger.oldMap;
        FS_WorkDetailManager.copyRelatedData(newList);
        FS_WorkDetailManager.updateUnitOfMeasureCodes(newList, oldMap);
        FS_WorkDetailManager.updateFaultCodes(newList, oldMap);
        FS_WorkDetailManager.updateDetailLineAndIntegrationStatus(newList, oldMap);
        FS_WorkDetailManager.toggleIntegrationStatus(newList, oldMap);
        FS_WorkDetailManager.updateFieldValues(newList, oldMap);
        // SVMXINT-528-530 WO One-Click Complete - Swapping out calls..
        FS_WorkDetailManager.cancelLines(newList, oldMap);
        // ITSFDC-509 Lookup Product Plant (and related fields)
        FS_WorkDetailManager.lookupProductPlant(newList, oldMap);
        //SVMXCFG-690 copy first 40 chars of Work Description to Work Summary
        FS_WorkDetailManager.addWorkSummary(newList);
        // 08/04/2023 ITSVMX-1227 Update Work Order Plant and Work Center from either Technician or Additional Work Center
        FS_WorkDetailManager.updateWorkDetailPlantAndWorkCenter(newList, oldMap);
    }

    public void afterUpdate() 
    {
        List<WorkOrderLineItem> newList = Trigger.new;
        Map<Id, WorkOrderLineItem> oldMap = (Map<Id, WorkOrderLineItem>) Trigger.oldMap;
        // SVMXINT-502: Create Int Errors to detect duplicate processing
        FS_WorkDetailManager.logDuplicateErrors(newList, oldMap);
        //FS_WorkDetailManager.consumeRemoteHours(newList, oldMap);
        // 11/16/21 ITSVMX-624 Suggested Parts Automation
        //SMAX_PS_Kit_Parts.explodeWorkDetailKitParts(newList, oldMap);
        // 06/20/2022 ITSVMX-831 Delete Work Detail Records when they have been marked for deletion
        FS_WorkDetailManager.deleteWorkDetailRecords(newList, oldMap);
    }

    public void beforeDelete() {}
    public void afterDelete()
    {
        List<WorkOrderLineItem> oldList = Trigger.old;
        //FS_WorkDetailManager.consumeRemoteHours(oldList, null);
    }
    public void afterUndelete()
    {
        List<WorkOrderLineItem> newList = Trigger.new; 
        //FS_WorkDetailManager.consumeRemoteHours(newList, null);
    }
}