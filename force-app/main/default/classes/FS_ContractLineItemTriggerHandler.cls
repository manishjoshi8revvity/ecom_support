/**
 * Created by frankvanloon on 4/18/24.
 */

public with sharing class FS_ContractLineItemTriggerHandler implements FS_Utility.ITriggerHandler{

	public FS_ContractLineItemTriggerHandler () {
	}

	public void beforeInsert() {
		List<ContractLineItem> newList = Trigger.new;
		FS_ServiceContractManager.updateLineItemLookups(newList, null);
	}
	public void afterInsert() {}
	public void beforeUpdate() {
		List<ContractLineItem> newList = Trigger.new;
		Map<Id, ContractLineItem> oldMap = (Map<Id, ContractLineItem>) Trigger.oldMap;
		FS_ServiceContractManager.updateLineItemLookups(newList, oldMap);
	}
	public void afterUpdate() {}
	public void beforeDelete() {}
	public void afterDelete() {}
	public void afterUndelete() {}
}