/**
 * Created by frankvanloon on 4/8/24.
 */
trigger FS_IntegrationError on FS_IntegrationError__c (before insert, before update, before delete, after insert, after update, after delete) {
	FS_Utility.executeHandler(new FS_IntegrationErrorTriggerHandler());
}