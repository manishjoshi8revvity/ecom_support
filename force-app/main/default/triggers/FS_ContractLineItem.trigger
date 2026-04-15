/**
 * Created by frankvanloon on 4/18/24.
 */

trigger FS_ContractLineItem on ContractLineItem (before insert, before update, before delete, after insert, after update, after delete) {
	FS_Utility.executeHandler(new FS_ContractLineItemTriggerHandler());
}