/**
 * Created by frankvanloon on 4/4/24.
 */
trigger FS_EntitlementDate on FS_EntitlementDate__c (before insert, before update, before delete, after insert, after update, after delete) {
	FS_Utility.executeHandler(new FS_EntitlementDateTriggerHandler());
}