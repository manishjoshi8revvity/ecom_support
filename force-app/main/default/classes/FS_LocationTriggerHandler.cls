/**
 *  Trigger Handler for Location [Schema.Location]
 *  2017-07-03      Frank VanLoon       Initial creation, for Location Integration.
 *  2017-11-28      Frank VanLoon       Added Geography Lookup
 *  2018-03-20      Frank VanLoon       Added Storage Address Lookup [SVMXCFG-401]
 *  CONVERTED to SFS by frankvanloon on 3/22/24.
 */
public with sharing class FS_LocationTriggerHandler implements FS_Utility.ITriggerHandler {

	public void beforeInsert()
	{
		List<Schema.Location> newList = Trigger.new;

		FS_LocationManager.lookupLocationCustomers(newList, null);
		FS_LocationManager.lookupLocationGeography(newList, null);
		FS_LocationManager.lookupInventoryAddress(newList, null);
		FS_LocationManager.lookupCountryState(newList, null);
		FS_LocationManager.updateDepotQueues(newList, null);
	}

	public void afterInsert()
	{
		List<Schema.Location> newList = Trigger.new;
	}

	public void beforeUpdate()
	{
		List<Schema.Location> newList = Trigger.new;
		Map<Id, Schema.Location> oldMap = (Map<Id, Schema.Location>) Trigger.oldMap;

		FS_LocationManager.lookupLocationCustomers(newList, oldMap);
		FS_LocationManager.lookupLocationGeography(newList, oldMap);
		FS_LocationManager.lookupInventoryAddress(newList, oldMap);
		FS_LocationManager.lookupCountryState(newList, oldMap);
		FS_LocationManager.updateDepotQueues(newList, oldMap);
	}

	public void afterUpdate()
	{
		List<Schema.Location> newList = Trigger.new;
		Map<Id, Schema.Location> oldMap = (Map<Id, Schema.Location>) Trigger.oldMap;

		// Added by Frank, but after clarification from Paul removed it
		//FS_LocationManager.afterCompletedStockTransaction(newList, oldMap);
		// Added by Veerendra 2017-08-14
		FS_LocationManager.updateAssetAddressFieldsWhenLocAdrChanged(newList, oldMap);
	}

	public void beforeDelete() {}
	public void afterDelete() {}
	public void afterUndelete() {}
	
}