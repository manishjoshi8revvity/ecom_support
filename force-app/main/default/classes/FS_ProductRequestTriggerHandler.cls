public with sharing class FS_ProductRequestTriggerHandler implements FS_Utility.ITriggerHandler{
    
    public FS_ProductRequestTriggerHandler() {
    }
    
    public void beforeInsert() {
        List<ProductRequest> newList = Trigger.new;

        FS_ProductRequestManager.copyRelatedData(newList);
        //SMAX_PS_PartsOrderManager.lookupMasterPartsOrder(newList, null);
        //SMAX_PS_PartsOrderManager.lookupLoanerEquipment(newList, null);
        //SMAX_PS_PartsOrderManager.trimValues(newList, null);
        // 2022-04-05 Tony ITSVMX-562 Modify the replenishment parts ordering process
        FS_ProductRequestManager.refurbishedPartsAllowed(newList, null);
        //SMAX_PS_OwnedByCompanyManager.updateSobjectOwnedByCompany(newList, null);
    }
    public void beforeUpdate() {
        List<ProductRequest> newList = Trigger.new;
        Map<Id, ProductRequest> oldMap = (Map<Id, ProductRequest>) Trigger.oldMap;

        FS_ProductRequestManager.copyRelatedData(newList);
        //SMAX_PS_PartsOrderManager.lookupMasterPartsOrder(newList, oldMap);
        //SMAX_PS_PartsOrderManager.lookupLoanerEquipment(newList, oldMap);
        //SMAX_PS_PartsOrderManager.trimValues(newList, oldMap);
        //SMAX_PS_PartsOrderManager.poStatusChanges(newList, oldMap);
        // 2022-04-05 Tony ITSVMX-562 Modify the replenishment parts ordering process
        FS_ProductRequestManager.refurbishedPartsAllowed(newList, oldMap);
        //SMAX_PS_OwnedByCompanyManager.updateSobjectOwnedByCompany(newList, oldMap);
    }
    public void afterInsert()
    {
        /*List<SVMXC__RMA_Shipment_Order__c> newList = Trigger.new;
        Map<Id, SVMXC__RMA_Shipment_Order__c> oldMap = (Map<Id, SVMXC__RMA_Shipment_Order__c>) Trigger.oldMap;
        SMAX_PS_PartsOrderManager.createPartsOrderEvents(newList, oldMap);*/
    }
    public void afterUpdate()
    {
        /*List<SVMXC__RMA_Shipment_Order__c> newList = Trigger.new;
        Map<Id, SVMXC__RMA_Shipment_Order__c> oldMap = (Map<Id, SVMXC__RMA_Shipment_Order__c>) Trigger.oldMap;
        //SMAX_PS_PartsOrderManager.assignToDepot(newList, oldMap);
        SMAX_PS_PartsOrderManager.createPartsOrderEvents(newList, oldMap);*/
    }
    public void beforeDelete() {}
    public void afterDelete() {}
    public void afterUndelete() {}   
}