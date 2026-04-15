/**
 * Created by frankvanloon on 3/18/24.
 */
trigger FS_ServiceAlert on FS_ServiceAlert__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	FS_Utility.executeHandler(new FS_ServiceAlertTriggerHandler());
}