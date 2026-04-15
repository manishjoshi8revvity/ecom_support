/**
 *  Trigger Handler for IntegrationError [SMAX_PS_IntegrationError__c]
 *  2017-09-28      Veerendra Moodbidri       Initial creation, for IntegrationError Integration.
 *  2017-12-04      Frank VanLoon             Added related element method.
 *  CONVERTED to SFS by frankvanloon on 4/8/24.
 */
public with sharing class FS_IntegrationErrorTriggerHandler implements FS_Utility.ITriggerHandler {

	public FS_IntegrationErrorTriggerHandler() {
	}

	public void beforeInsert()
	{
		List<FS_IntegrationError__c> newList = Trigger.new;
		FS_IntegrationErrorManager.updateRelatedElement(newList);
	}
	public void afterInsert()
	{
		List<FS_IntegrationError__c> newList = Trigger.new;
		FS_IntegrationErrorManager.updateIntegrationStatusInWorkOrderLineItem(newList);
		FS_IntegrationErrorManager.updateWorkOrderLastError(newList);
		FS_IntegrationErrorManager.updateProductRequestErrorStatus(newList);
		FS_IntegrationErrorManager.updateReturnOrderErrorStatus(newList);
        FS_IntegrationErrorManager.updateProductTransferErrorStatus(newList);
		FS_IntegrationErrorManager.unlockDMR(newList);
	}
	public void beforeUpdate() {}
	public void afterUpdate() {}
	public void beforeDelete() {}
	public void afterDelete() {}
	public void afterUndelete() {}

}