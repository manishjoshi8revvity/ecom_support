/*
 *  Trigger Handler for Inventory Count Line [SMAX_PS_InventoryCountLine__c]
 *  2017-10-05      Frank VanLoon       Initial creation, for Inventory Count Integration.
 */
public with sharing class FS_InventoryCountLineTriggerHandler implements FS_Utility.ITriggerHandler {

  public FS_InventoryCountLineTriggerHandler() {
  }

  public void beforeInsert()
  {
    List<FS_InventoryCountLine__c> lineList = Trigger.new;
    lookupLineStock(lineList, null);
    validateSerialNumbers(lineList);
  }
  public void afterInsert() {}

  public void beforeUpdate()
  {
    List<FS_InventoryCountLine__c> lineList = Trigger.new;
    Map<Id, FS_InventoryCountLine__c> oldLineMap = (Map<Id, FS_InventoryCountLine__c>) Trigger.oldMap;
    lookupLineStock(lineList, oldLineMap);
    validateSerialNumbers(lineList);
  }
  public void afterUpdate()
  {
    /*List<FS_InventoryCountLine__c> lineList = Trigger.new;
    Map<Id, FS_InventoryCountLine__c> oldLineMap = (Map<Id, FS_InventoryCountLine__c>) Trigger.oldMap;
    allLinesConfirmed(lineList, oldLineMap);
    allLinesApproved(lineList, oldLineMap);*/
  }

  public void beforeDelete() {}
  public void afterDelete() {}
  public void afterUndelete() {}

  /**
   *  Should be called from the BEFORE INSERT / UPDATE Triggers of SMAX_PS_InventoryCountLine__c
   */
  public static void lookupLineStock(List<FS_InventoryCountLine__c> lineList, Map<Id, FS_InventoryCountLine__c> oldMap)
  {
    if (!FS_Utility.isActive('InvCountLine Lookup Stock', 'Lookup the Inventory Count Lines Product Stock'))
      return;

    List<FS_InventoryCountLine__c> linesToUpdate = new List<FS_InventoryCountLine__c>();
    Set<Id> countIds = new Set<Id>();
    Set<Id> productIds = new Set<Id>();
    for (FS_InventoryCountLine__c line : lineList)
    {
      FS_InventoryCountLine__c old = (oldMap == null) ? null : oldMap.get(line.Id);
      Boolean productChanged = (old != null && line.Product__c != old.Product__c);
      if (line.Product__c != null && (line.ProductStock__c == null || productChanged))
      {
        linesToUpdate.add(line);
        countIds.add(line.InventoryCount__c);
        productIds.add(line.Product__c);
      }
    }

    if (linesToUpdate.isEmpty())
      return;

    // Lookup Inventory Counts.. and their Locations
    Map<Id, FS_InventoryCount__c> countMap = new Map<Id, FS_InventoryCount__c>(
    [SELECT Id, Name, RequestedFrom__c FROM FS_InventoryCount__c WHERE Id IN :countIds]);
    Set<Id> locIds = new Set<Id>();
    for (FS_InventoryCount__c count : countMap.values())
    {
      locIds.add(count.RequestedFrom__c);
    }

    // Lookup all ProductStock with xref of Location and Product
    Map<String, ProductItem> stockMap = new Map<String, ProductItem>();
    for (ProductItem stock : [SELECT Id, LocationId, Product2Id FROM ProductItem WHERE LocationId IN :locIds AND Product2Id IN :productIds])
    {
      String key = stock.LocationId + '-' + stock.Product2Id;
      stockMap.put(key, stock);
    }

    // Assign ProductStock to each count line
    for (FS_InventoryCountLine__c line : linesToUpdate)
    {
      FS_InventoryCount__c count = countMap.get(line.InventoryCount__c);
      String key = count.RequestedFrom__c + '-' + line.Product__c;
      if (stockMap.containsKey(key))
      {
        ProductItem stock = stockMap.get(key);
        line.ProductStock__c = stock.Id;
      }
    }
  }

  /**
   *  Should be called from the AFTER UPDATE Trigger of SMAX_PS_InventoryCountLine__c
   */
 /* public static void allLinesConfirmed(List<SMAX_PS_InventoryCountLine__c> lineList, Map<Id, SMAX_PS_InventoryCountLine__c> oldMap)
  {
    if (!SMAX_PS_Utility.isActive('InvCountLine All Confirmed', 'When all Inventory Count Lines are Confirmed update the Inventory Count Status'))
      return;

    Set<Id> countIds = new Set<Id>();
    Set<Id> confirmedLines = new Set<Id>();
    for (SMAX_PS_InventoryCountLine__c line : lineList)
    {
      SMAX_PS_InventoryCountLine__c old = (oldMap == null) ? null : oldMap.get(line.Id);
      if (line.SMAX_PS_InvCnt_Status__c == 'Confirmed'
          && old != null && old.SMAX_PS_InvCnt_Status__c != line.SMAX_PS_InvCnt_Status__c)
      {
        confirmedLines.add(line.Id);
        countIds.add(line.SMAX_PS_InventoryCount__c);
      }
    }

    if (countIds.isEmpty()) {
      return;
    }

    List<SMAX_PS_InventoryCount__c> countsToUpdate = new List<SMAX_PS_InventoryCount__c>();
    List<SMAX_PS_InventoryCount__c> counts = [SELECT Id, Name, SMAX_PS_Status__c,
    (SELECT Id, Name, SMAX_PS_InvCnt_Status__c FROM Inventory_Count_Lines__r
    WHERE Id NOT IN :confirmedLines AND SMAX_PS_InvCnt_Status__c != 'Confirmed')
    FROM SMAX_PS_InventoryCount__c WHERE Id IN :countIds];
    for (SMAX_PS_InventoryCount__c count : counts)
    {
      if (count.SMAX_PS_Status__c == 'Submitted')
      {
        if (count.Inventory_Count_Lines__r == null || count.Inventory_Count_Lines__r.isEmpty())
        {
          count.SMAX_PS_Status__c = 'Confirmed';
          countsToUpdate.add(count);
        }
        else
        {
          System.debug('Inv Count NOT ready to move to Confirmed: ' + count);
        }
      }
    }

    if (!countsToUpdate.isEmpty()) {
      update counts;
    }
  }

  public static void allLinesApproved(List<SMAX_PS_InventoryCountLine__c> lineList, Map<Id, SMAX_PS_InventoryCountLine__c> oldMap)
  {
    if (!SMAX_PS_Utility.isActive('InvCountLine All Confirmed', 'When all Inventory Count Lines are Confirmed update the Inventory Count Status'))
      return;

    Set<Id> countIds = new Set<Id>();
    Set<Id> approvedLines = new Set<Id>();
    for (SMAX_PS_InventoryCountLine__c line : lineList)
    {
      SMAX_PS_InventoryCountLine__c old = (oldMap == null) ? null : oldMap.get(line.Id);
      if (line.SMAX_PS_InvCnt_Status__c == 'Approved'
          && old != null && old.SMAX_PS_InvCnt_Status__c != line.SMAX_PS_InvCnt_Status__c)
      {
        approvedLines.add(line.Id);
        countIds.add(line.SMAX_PS_InventoryCount__c);
      }
    }

    if (countIds.isEmpty()) {
      return;
    }

    List<SMAX_PS_InventoryCount__c> countsToUpdate = new List<SMAX_PS_InventoryCount__c>();
    List<SMAX_PS_InventoryCount__c> counts = [SELECT Id, Name, SMAX_PS_Status__c,
    (SELECT Id, Name, SMAX_PS_InvCnt_Status__c FROM Inventory_Count_Lines__r
    WHERE Id NOT IN :approvedLines AND SMAX_PS_InvCnt_Status__c != 'Approved')
    FROM SMAX_PS_InventoryCount__c WHERE Id IN :countIds];
    for (SMAX_PS_InventoryCount__c count : counts)
    {
      if (count.SMAX_PS_Status__c == 'Confirmed')
      {
        if (count.Inventory_Count_Lines__r == null || count.Inventory_Count_Lines__r.isEmpty())
        {
          count.SMAX_PS_Status__c = 'Approved';
          countsToUpdate.add(count);
        }
        else
        {
          System.debug('Inv Count NOT ready to move to Approved: ' + count);
        }
      }
    }

    if (!countsToUpdate.isEmpty()) {
      update counts;
    }
  }
*/
  public static void validateSerialNumbers(List<FS_InventoryCountLine__c> lines)
  {
    for (FS_InventoryCountLine__c line : lines)
    {
      //SMAX_PS_InventoryCountLine__c old = (oldMap == null) ? null : oldMap.get(line.Id);
      if (line.CountedQty__c > 0 && line.Is_Serialized__c == true
          && String.isNotBlank(line.Expected_Serial_Numbers__c))
      {
        // Found a line expecting Serial Numbers to match Counted Qty...
        String serials = line.Actual_Serial_Numbers__c;
        if (String.isBlank(serials)) {
          line.addError('Actual Serial Numbers are required to save the Counted Qty on this line.');
        } else {
          String[] serialList = serials.split(',');
          if (line.CountedQty__c != serialList.size()) {
            line.addError('Must provide Actual Serial Numbers matching the Counted Qty. Expected: '
              + line.CountedQty__c + ', Found: ' + serialList.size());
          }
        }
      }
    }
  }

}