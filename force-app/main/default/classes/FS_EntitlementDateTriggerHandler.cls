/**
 *  Trigger Handler for Entitlement Date [SMAX_PS_EntitlementDate__c]
 *  2022-10-24      Bolt Data - E. Ross      Modifications for Polaris Project.
 *  CONVERTED to SFS by frankvanloon on 4/4/24.
 */
public with sharing class FS_EntitlementDateTriggerHandler  implements FS_Utility.ITriggerHandler {
	public FS_EntitlementDateTriggerHandler() {
	}

	public void beforeInsert()
	{
		List<FS_EntitlementDate__c> newList = Trigger.new;

		// SVMXCFG-455: When the ServiceOrderNumber is filled in on Entitlement Date, try to fill in the WO Lookup.
		FS_ServiceContractManager.lookupWorkOrders(newList, null);
		//SMAX_PS_OwnedByCompanyManager.updateSobjectOwnedByCompany(newList, null);
	}

	public void afterInsert() {}
	public void beforeUpdate()
	{
		List<FS_EntitlementDate__c> newList = Trigger.new;
		Map<Id, FS_EntitlementDate__c> oldMap = (Map<Id, FS_EntitlementDate__c>) Trigger.oldMap;

		// SVMXCFG-455: When the ServiceOrderNumber is filled in on Entitlement Date, try to fill in the WO Lookup.
		FS_ServiceContractManager.lookupWorkOrders(newList, oldMap);
		//SMAX_PS_OwnedByCompanyManager.updateSobjectOwnedByCompany(newList, oldMap);
	}
	public void afterUpdate() {}
	public void beforeDelete() {}
	public void afterDelete() {}
	public void afterUndelete() {}
}