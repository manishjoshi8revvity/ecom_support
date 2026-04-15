public with sharing class FS_ProductRequestLineItemTriggerHandler implements FS_Utility.ITriggerHandler {

  public void beforeInsert() {
    List<ProductRequestLineItem> newList = Trigger.new;

    // 2022-04-16 Tony ITSVMX-562 Modify the replenishment parts ordering process
    FS_ProductRequestManager.useRefurbishedParts(newList, null);
  }

  public void afterInsert() {
    List<ProductRequestLineItem> newList = Trigger.new;

    //SMAX_PS_InventoryManager.deliveryLineReplacements(newList);

    // 11/23/21 ITSVMX-624 Suggested Parts Automation
    //SMAX_PS_Kit_Parts.explodePartsOrderLineKitParts(newList, null);
  }

  public void beforeUpdate() {
    List<ProductRequestLineItem> newList = Trigger.new;
    Map<Id, ProductRequestLineItem> oldMap = (Map<Id, ProductRequestLineItem>) Trigger.oldMap;

    // 2022-04-16 Tony ITSVMX-562 Modify the replenishment parts ordering process
    FS_ProductRequestManager.useRefurbishedParts(newList, oldMap);
  }

  public void afterUpdate() {
    List<ProductRequestLineItem> newList = Trigger.new;
    Map<Id, ProductRequestLineItem> oldMap = (Map<Id, ProductRequestLineItem>) Trigger.oldMap;

    // 11/23/21 ITSVMX-624 Suggested Parts Automation
    //SMAX_PS_Kit_Parts.explodePartsOrderLineKitParts(newList, oldMap);
  }

  public void beforeDelete() {
  }

  public void afterDelete() {
  }

  public void afterUndelete() {
  }
}