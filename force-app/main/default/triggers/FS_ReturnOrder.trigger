/**
 * Created by frankvanloon on 5/8/24.
 */
trigger FS_ReturnOrder on ReturnOrder (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	FS_Utility.executeHandler(new FS_ReturnOrderTriggerHandler());
}