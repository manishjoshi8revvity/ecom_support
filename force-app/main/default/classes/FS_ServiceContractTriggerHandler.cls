public with sharing class FS_ServiceContractTriggerHandler implements FS_Utility.ITriggerHandler {

    public FS_ServiceContractTriggerHandler() {
    }

    public void beforeInsert() {
        List<ServiceContract> newContractList = Trigger.new;

        FS_ServiceContractManager.updateLookups(newContractList, null);
        FS_ServiceContractManager.updateIsDeletedByCancelNotes(newContractList, null);
        FS_ServiceContractManager.updateRenewedFromAndRenewedTo(newContractList, null);
        //SMAX_PS_ServiceContractManager.copyRemoteHoursRemaining(newContractList);

        // ITSVMX-228 Map contract type from Parent contract (header) to line items (create a new field on the page layout)
        FS_ServiceContractManager.updateContractItemFromParent(newContractList);
        //SMAX_PS_OwnedByCompanyManager.updateSobjectOwnedByCompany(newContractList, null);
    }
    public void afterInsert() {}

    public void beforeUpdate() {
        List<ServiceContract> newContractList = Trigger.new;
        Map<Id, ServiceContract> oldContractMap = (Map<Id, ServiceContract>) Trigger.oldMap;
        FS_ServiceContractManager.updateLookups(newContractList, oldContractMap);
        FS_ServiceContractManager.updateIsDeletedByCancelNotes(newContractList, oldContractMap);
        FS_ServiceContractManager.updateRenewedFromAndRenewedTo(newContractList, oldContractMap);
        FS_ServiceContractManager.updateContractItemFromParent(newContractList);
        //SMAX_PS_ServiceContractManager.copyRemoteHoursRemaining(newContractList);
        //SMAX_PS_OwnedByCompanyManager.updateSobjectOwnedByCompany(newContractList, oldContractMap);
    }
    public void afterUpdate() {
        List<ServiceContract> newContractList = Trigger.new;
        Map<Id, ServiceContract> oldContractMap = (Map<Id, ServiceContract>) Trigger.oldMap;
        FS_ServiceContractManager.updateIsDeleted(newContractList, oldContractMap);
    }

    public void beforeDelete() {}
    public void afterDelete() {}
    public void afterUndelete() {}
}