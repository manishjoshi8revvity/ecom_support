/**
 *  Trigger Handler for Product Stock [ProductItem]
 *  2017-09-07      Veerendra Moodbidri       Initial creation, for Product Stock Integration.
 *  2022-10-24      Bolt Data - E. Ross       Modifications for Polaris Project.
 *  CONVERTED to SFS by frankvanloon on 4/8/24.
 */
public with sharing class FS_ProductItemTriggerHandler implements FS_Utility.ITriggerHandler {

	public FS_ProductItemTriggerHandler() {
	}

	public void beforeInsert() {
		List<ProductItem> newPstockList = Trigger.new;
//		SMAX_PS_OwnedByCompanyManager.updateSobjectOwnedByCompany(newPstockList, null);
	}
	public void afterInsert() {}
	public void beforeUpdate() {
		List<ProductItem> newPstockList = Trigger.new;
		Map<Id, ProductItem> oldPstockMap = (Map<Id, ProductItem>) Trigger.oldMap;
//		SMAX_PS_OwnedByCompanyManager.updateSobjectOwnedByCompany(newPstockList, oldPstockMap);
	}
	public void afterUpdate()
	{
		List<ProductItem> newPstockList = Trigger.new;
		Map<Id, ProductItem> oldPstockMap = (Map<Id, ProductItem>) Trigger.oldMap;
		FS_InventoryManager.afterUpdateComplete(newPstockList, oldPstockMap);
	}

	public void beforeDelete() {}
	public void afterDelete() {}
	public void afterUndelete() {}

}