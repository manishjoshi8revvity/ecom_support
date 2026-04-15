public with sharing class FS_ProductSalesTriggerHandler implements FS_Utility.ITriggerHandler{
    
    public FS_ProductSalesTriggerHandler () {}

    public void beforeInsert() {
        List<Product_Sales__c> newList = Trigger.new;
        FS_ProductManager.processProductSales(newList, null);
    }
    public void afterInsert() {
        List<Product_Sales__c> newList = Trigger.new;

    }
    public void beforeUpdate() {
        List<Product_Sales__c> newList = Trigger.new;
        Map<Id, Product_Sales__c> oldMap = (Map<Id, Product_Sales__c>) Trigger.oldMap;
        FS_ProductManager.processProductSales(newList, oldMap);
    }
    public void afterUpdate(){
        List<Product_Sales__c> newList = Trigger.new;
        Map<Id, Product_Sales__c> oldMap = (Map<Id, Product_Sales__c>) Trigger.oldMap;

    }
    public void beforeDelete() {}
    public void afterDelete() {}
    public void afterUndelete() {}
}