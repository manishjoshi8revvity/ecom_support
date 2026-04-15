public with sharing class FS_ProductTriggerHandler implements FS_Utility.ITriggerHandler{

    public FS_ProductTriggerHandler () {
    }

    public void afterUpdate()
    {
        List<Product2> newProdList = Trigger.new;
        Map<Id, Product2> oldProdMap = (Map<Id, Product2>) Trigger.oldMap;
        FS_ProductManager.updateDeletedFlag(newProdList, oldProdMap);            
    }
        
    public void afterDelete()
    {
        List<Product2> oldProdList = Trigger.old;
        FS_ProductManager.deleteProductChildRecords(oldProdList);            
    }

    public void beforeUpdate() {}
    public void beforeInsert() {}
    public void afterInsert() {}
    public void beforeDelete() {}
    public void afterUndelete() {}

}