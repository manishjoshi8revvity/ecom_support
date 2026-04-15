/**
 * Created by frankvanloon on 5/8/24.
 */
public with sharing class FS_ReturnOrderTriggerHandler implements FS_Utility.ITriggerHandler{

	public FS_ReturnOrderTriggerHandler() {
	}

	public void beforeInsert() {
		List<ReturnOrder> newList = Trigger.new;

		FS_ReturnOrderManager.copyRelatedData(newList);
		//SMAX_PS_PartsOrderManager.lookupMasterPartsOrder(newList, null);
		//SMAX_PS_PartsOrderManager.lookupLoanerEquipment(newList, null);
		//SMAX_PS_PartsOrderManager.trimValues(newList, null);
		// 2022-04-05 Tony ITSVMX-562 Modify the replenishment parts ordering process
		//FS_ReturnOrderManager.refurbishedPartsAllowed(newList, null);
		//SMAX_PS_OwnedByCompanyManager.updateSobjectOwnedByCompany(newList, null);
	}
	public void beforeUpdate() {
		List<ReturnOrder> newList = Trigger.new;
		Map<Id, ReturnOrder> oldMap = (Map<Id, ReturnOrder>) Trigger.oldMap;

		FS_ReturnOrderManager.copyRelatedData(newList);
		//SMAX_PS_PartsOrderManager.lookupMasterPartsOrder(newList, oldMap);
		//SMAX_PS_PartsOrderManager.lookupLoanerEquipment(newList, oldMap);
		//SMAX_PS_PartsOrderManager.trimValues(newList, oldMap);
		//SMAX_PS_PartsOrderManager.poStatusChanges(newList, oldMap);
		// 2022-04-05 Tony ITSVMX-562 Modify the replenishment parts ordering process
		//FS_ReturnOrderManager.refurbishedPartsAllowed(newList, oldMap);
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
		SMAX_PS_PartsOrderManager.createPartsOrderEvents(newList, oldMap);*/
	}
	public void beforeDelete() {}
	public void afterDelete() {}
	public void afterUndelete() {}

}