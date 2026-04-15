/*
 *  Trigger Handler for Installed Product [SVMXC__Installed_Product__c]
 *  2017-08-14      Veerendra Moodbidri       Initial creation, for Installed Product Integration.
 *  2022-10-24      Bolt Data - E. Ross      MOdifications for Polaris Project.
 */

public with sharing class FS_AssetTriggerHandler implements FS_Utility.ITriggerHandler {

	public FS_AssetTriggerHandler() {
	}

	public void beforeInsert()
	{
		List<Asset> newList = Trigger.new;

		FS_AssetManager.updateAssetAddressFields(newList, null);
		FS_AssetManager.updateLookups(newList, null);
		//BD_Address_i18n.formatAddressTrigger(newList, null);
		//SMAX_PS_OwnedByCompanyManager.updateSobjectOwnedByCompany(newList, null);
	}

	public void afterInsert() {}
	public void beforeUpdate()
	{
		List<Asset> newList = Trigger.new;
		Map<Id, Asset> oldMap = (Map<Id, Asset>) Trigger.oldMap;
		// SVMXCFG-482 - Update IP Address when Location changes
		FS_AssetManager.updateAssetAddressFields(newList, oldMap);
		FS_AssetManager.updateLookups(newList, oldMap);
		// SVMXCFG-253 - Calibrated Tool Log - 20180124
		FS_AssetManager.calibratedToolChangeLog(newList, oldMap);
		//BD_Address_i18n.formatAddressTrigger(newList, oldMap);
		//SMAX_PS_OwnedByCompanyManager.updateSobjectOwnedByCompany(newList, oldMap);
	}
	public void afterUpdate()
	{
		//List<Asset> newList = Trigger.new;
		//ap<Id, Asset> oldMap = (Map<Id, Asset>) Trigger.oldMap;
		//FS_AssetManager.deleteIPclassifications(newList, oldMap);
	}
	public void beforeDelete() {}
	public void afterDelete() {}
	public void afterUndelete() {}

}