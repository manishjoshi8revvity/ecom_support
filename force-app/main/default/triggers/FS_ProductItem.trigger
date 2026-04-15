/**
 * Created by frankvanloon on 4/8/24.
 */

trigger FS_ProductItem on ProductItem (before insert, before update, before delete, after insert, after update, after delete) {
	FS_Utility.executeHandler(new FS_ProductItemTriggerHandler());
}