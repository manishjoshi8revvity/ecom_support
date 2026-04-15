/**
 * Created by frankvanloon on 4/8/24.
 */

public with sharing class FS_InventoryManager {

    public static void afterUpdateComplete(List<ProductItem> newList, Map<Id, ProductItem> oldMap)
    {
        if (!FS_Utility.isActive('Completed Stock Transaction',
                'Update Serialized ProductItems when Completed Stock Transaction Number is updated.'))
        {
            return;
        }

        Set<Id> locIds = new Set<Id>();
		Set<Id> prodIds = new Set<Id>();
        List<ProductItem> itemsToCheck = new List<ProductItem>();
        for (ProductItem item : newList)
        {
			ProductItem old = (oldMap == null) ? null : oldMap.get(item.Id);
            if ( old != null && old.CompletedTxnNum__c != item.CompletedTxnNum__c && item.SerialNumber == null) {
                itemsToCheck.add(item);
                locIds.add(item.LocationId);
				prodIds.add(item.Product2Id);
            }
        }
        if (itemsToCheck.isEmpty()) {
            return;
        }

        List<ProductItem> serializedItems = [SELECT Id, LocationId, Product2Id, ProductItemNumber,
                LastTxnNum__c, QuantityOnHand, SerialNumber
            FROM ProductItem WHERE LocationId IN :locIds AND Product2Id IN :prodIds AND SerialNumber != NULL];
        Map<String, List<ProductItem>> serialItemMap = new Map<String, List<ProductItem>>();
        // Fill in Location_Product -> ProductItem map
        for (ProductItem item : serializedItems)
        {
			String key = item.LocationId+'_'+item.Product2Id;
            if(!serialItemMap.containsKey(key)) {
				serialItemMap.put(key, new List<ProductItem>());
            }
			serialItemMap.get(key).add(item);
        }

        // Main process
        //List<ProductItem> stockToUpdate = new List<ProductItem>();
        Set<Id> stockToDelete = new Set<Id>();
        for (ProductItem item : itemsToCheck)
        {
			String key = item.LocationId+'_'+item.Product2Id;
            List<ProductItem> serialItemList = (serialItemMap.containsKey(key)) ? serialItemMap.get(key) : null;
            if (serialItemList != null)
            {
                // Found Serialized Items.. need to delete this non-serialized item
                stockToDelete.add(item.Id);
                for (ProductItem serialItem : serialItemList)
                {
                    // Serialized item not included in latest txn... delete it (or zero it?)
                    if (item.CompletedTxnNum__c != serialItem.LastTxnNum__c) {
                        //serialItem.QuantityOnHand = 0;
                        //stockToUpdate.add(serialItem);
                        stockToDelete.add(serialItem.Id);
                    }
                }
            }
        }

        //if (!stockToUpdate.isEmpty()) {
        //    update stockToUpdate;
        //}
        if (!stockToDelete.isEmpty()) {
            deleteStockFuture(stockToDelete);
        }
    }

    @Future
    public static void deleteStockFuture(Set<Id> stockIds) {
        List<ProductItem> stockToDelete = [SELECT Id FROM ProductItem WHERE Id IN :stockIds];
        delete stockToDelete;
    }
}