/**
 * Trigger Handler for ServiceResource (aka Technician)
 * CONVERTED to SFS by frankvanloon on 3/25/24.
 */
public with sharing class FS_ServiceResourceTriggerHandler implements FS_Utility.ITriggerHandler {

	public void beforeInsert()
	{
		List<ServiceResource> newList = Trigger.new;

		FS_ServiceResourceManager.updateTechnicianLocations(newList, null);
		//FS_ServiceResourceManager.updateDepotQueues(newList, null);
	}

	public void afterInsert() {
		List<ServiceResource> newList = Trigger.new;

	}
	public void beforeUpdate()
	{
		List<ServiceResource> newList = Trigger.new;
		Map<Id, ServiceResource> oldMap = (Map<Id, ServiceResource>) Trigger.oldMap;

//		SMAX_PS_TechnicianManager.validateTechnicianGeographies(newList, oldMap);
		FS_ServiceResourceManager.updateTechnicianLocations(newList, oldMap);
		//FS_ServiceResourceManager.updateDepotQueues(newList, oldMap);
	}
	public void afterUpdate() {
		List<ServiceResource> newList = Trigger.new;
		Map<Id, ServiceResource> oldMap = (Map<Id, ServiceResource>) Trigger.oldMap;

	}
	public void beforeDelete() {}
	public void afterDelete() {}
	public void afterUndelete() {}

}