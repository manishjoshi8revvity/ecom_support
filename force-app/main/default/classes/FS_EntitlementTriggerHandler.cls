public with sharing class FS_EntitlementTriggerHandler implements FS_Utility.ITriggerHandler {

	public FS_EntitlementTriggerHandler () {
	}

	public void beforeInsert() {
		List<Entitlement> newList = Trigger.new;

		// Added by Frank - Nov 17 2017
		FS_Utility.updateMappedValues('Entitlement', newList, null);
		FS_ServiceContractManager.updateEntitlementLookups(newList, null);
	}

	public void beforeUpdate() {
		List<Entitlement> newList = Trigger.new;
		Map<Id, Entitlement> oldMap = (Map<Id, Entitlement>) Trigger.oldMap;

		// Added by Frank - Nov 17 2017
		FS_Utility.updateMappedValues('Entitlement', newList, oldMap);
		FS_ServiceContractManager.updateEntitlementLookups(newList, oldMap);
	}

	public void afterInsert() {}
	public void afterUpdate() {}
	public void beforeDelete() {}
	public void afterDelete() {}
	public void afterUndelete() {}
}