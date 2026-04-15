trigger FS_ProductSales on Product_Sales__c(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    FS_Utility.executeHandler(new FS_ProductSalesTriggerHandler());
}