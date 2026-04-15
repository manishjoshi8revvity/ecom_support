/**
 * Created by frankvanloon on 3/25/24.
 */

trigger FS_ServiceResource on ServiceResource (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	FS_Utility.executeHandler(new FS_ServiceResourceTriggerHandler());
}