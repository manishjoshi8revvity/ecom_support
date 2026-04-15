public without sharing class FS_ExtendedWarranty {

	/* public class ExtendedWarrantyCoverage {
	   @AuraEnabled public String extendedWarrantyPart {get;set;}
	   @AuraEnabled public String warrantyContract {get;set;}
	   @AuraEnabled public String warrantyContractItem {get;set;}
	   @AuraEnabled public String coveredPart {get;set;}
	   @AuraEnabled public Date coveredUntil {get;set;}

	   @AuraEnabled public String extendedWarrantyPartId {get;set;}
	   @AuraEnabled public String warrantyContractId {get;set;}
	   @AuraEnabled public String warrantyContractItemId {get;set;}
	   @AuraEnabled public String coveredPartId {get;set;}
	 }

	 // ITSVMX-386 Used by the smaxExtendedWarranty LWC
	 @AuraEnabled(Cacheable=true)
	 public static List<ExtendedWarrantyCoverage> getCoveragesForIp(Id ipId)
	 {
	   List<Id> ipIds = new List<Id>();
	   ipIds.add(ipId);

	   List<BD_Extended_Warranty_Coverage__c> coverages = getCoverages(ipIds, null);
	   System.debug('coverages: ' + coverages);

	   Set<Id> warrantyPartIds = new Set<Id>();
	   Set<Id> warrantyContractIds = new Set<Id>();
	   Set<Id> warrantyContractItemIds = new Set<Id>();
	   Set<Id> coveredPartIds = new Set<Id>();
	   for (BD_Extended_Warranty_Coverage__c coverage :coverages) {
		 warrantyPartIds.add(coverage.BD_Extended_Warranty_Part__c);
		 warrantyContractIds.add(coverage.BD_Warranty_Contract__c);
		 warrantyContractItemIds.add(coverage.BD_Warranty_Contract_Item__c);
		 coveredPartIds.add(coverage.BD_Covered_Part__c);
	   }

	   Map<Id, BD_Extended_Warranty_Part__c> warrantyPartMap = new Map<Id, BD_Extended_Warranty_Part__c>([
		   SELECT Id, Name
		   FROM BD_Extended_Warranty_Part__c
		   WHERE Id IN :warrantyPartIds
	   ]);

	   Map<Id, SVMXC__Service_Contract__c> warrantyContractMap = new Map<Id, SVMXC__Service_Contract__c>([
		   SELECT Id, Name
		   FROM SVMXC__Service_Contract__c
		   WHERE Id IN :warrantyContractIds
	   ]);

	   Map<Id, SVMXC__Service_Contract__c> warrantyContractItemMap = new Map<Id, SVMXC__Service_Contract__c>([
		   SELECT Id, Name
		   FROM SVMXC__Service_Contract__c
		   WHERE Id IN :warrantyContractItemIds
	   ]);

	   Map<Id, Product2> coveredPartMap = new Map<Id, Product2>([
		   SELECT Id, Name
		   FROM Product2
		   WHERE Id IN :coveredPartIds
	   ]);

	   List<ExtendedWarrantyCoverage> extendedWarrantyCoverages = new List<ExtendedWarrantyCoverage>();
	   for (BD_Extended_Warranty_Coverage__c coverage :coverages) {
		 ExtendedWarrantyCoverage ewc = new ExtendedWarrantyCoverage();
		 ewc.extendedWarrantyPart = warrantyPartMap.get(coverage.BD_Extended_Warranty_Part__c).Name;
		 ewc.warrantyContract = warrantyContractMap.get(coverage.BD_Warranty_Contract__c).Name;
		 ewc.warrantyContractItem = warrantyContractItemMap.get(coverage.BD_Warranty_Contract_Item__c).Name;
		 ewc.coveredPart = coveredPartMap.get(coverage.BD_Covered_Part__c).Name;
		 ewc.coveredUntil = coverage.BD_Covered_Until__c;

		 ewc.extendedWarrantyPartId = warrantyPartMap.get(coverage.BD_Extended_Warranty_Part__c).Id;
		 ewc.warrantyContractId = warrantyContractMap.get(coverage.BD_Warranty_Contract__c).Id;
		 ewc.warrantyContractItemId = warrantyContractItemMap.get(coverage.BD_Warranty_Contract_Item__c).Id;
		 ewc.coveredPartId = coveredPartMap.get(coverage.BD_Covered_Part__c).Id;
		 extendedWarrantyCoverages.add(ewc);
	   }
	   System.debug('extendedWarrantyCoverages: ' + extendedWarrantyCoverages);

	   return extendedWarrantyCoverages;
	 }*/

	public static List<FS_ExtendedWarrantyCoverage__c> getCoverages(List<Id> ipIds, List<WorkOrder> woToProcess)
	{
		System.debug('ipIds: ' + ipIds);
		System.debug('woToProcess: ' + woToProcess);

		List<FS_ExtendedWarrantyCoverage__c> newCoverages = new List<FS_ExtendedWarrantyCoverage__c>();
		Set<Id> productIds = new Set<Id>();
		Map<Id, ContractLineItem> ipCpMap = new Map<Id, ContractLineItem>();
		List<ContractLineItem> cpList = [SELECT Id,
				AssetId, Asset.Product2Id, Asset.Location.SalesOrg__c,
				ServiceContract.Id, ServiceContract.fxIs_Warranty__c, ServiceContract.SLA_Terms_Notes__c,
				ServiceContract.SalesOrg__c, ServiceContract.ParentServiceContractId,
				StartDate, EndDate
			FROM ContractLineItem
			WHERE AssetId IN :ipIds AND EndDate < TODAY AND IsDeleted__c = FALSE
				AND ServiceContract.fxIs_Warranty__c = TRUE
			ORDER BY EndDate];
		for (ContractLineItem cp : cpList)
		{
			// ITSVMX-1251 Adding check of the Sales Org to make sure we only select Contracts in the same Sales Org as the IP/Location
			if (cp.AssetId != null && cp.Asset.Product2Id != null
					&& cp.Asset.Location.SalesOrg__c == cp.ServiceContract.SalesOrg__c)
			{
				// NOTE: If more than one CP per IP found this will overwrite with the latest thanks to the ORDER BY above
				ipCpMap.put(cp.AssetId, cp);
				productIds.add(cp.Asset.Product2Id);
			}
		}

		// No Expired Contracts found.. go ahead and exit now
		if (productIds.isEmpty())
		{
			return newCoverages;
		}

		List<FS_ExtendedWarrantyPart__c> allEWP = [SELECT Id, Name, Equipment_Product__c,
				Extended_Months__c, Covered_Part__c, Sales_Org__c
		FROM FS_ExtendedWarrantyPart__c WHERE Equipment_Product__c IN :productIds AND Is_Deleted__c = FALSE];

		// If no Extended Warranty Parts were found.. go ahead and exit now
		if (allEWP.isEmpty())
		{
			return newCoverages;
		}

		Map<Id, List<FS_ExtendedWarrantyPart__c>> eqEwpMap = new Map<Id, List<FS_ExtendedWarrantyPart__c>>();
		for (FS_ExtendedWarrantyPart__c ewp : allEWP)
		{
			if (!eqEwpMap.containsKey(ewp.Equipment_Product__c))
			{
				eqEwpMap.put(ewp.Equipment_Product__c, new List<FS_ExtendedWarrantyPart__c>());
			}
			eqEwpMap.get(ewp.Equipment_Product__c).add(ewp);
		}

		if (woToProcess == null)
		{
			for (Id ipId : ipIds)
			{
				ContractLineItem cp = ipCpMap.get(ipId);
				if (cp != null)
				{
					ServiceContract item = cp.ServiceContract;
					Id eqProdId = cp.Asset.Product2Id;
					String salesOrg = (cp.Asset.Location == null) ? null:
							cp.Asset.Location.SalesOrg__c;

					List<FS_ExtendedWarrantyPart__c> ewpList = eqEwpMap.get(eqProdId);
					if (ewpList == null || ewpList.isEmpty())
					{
						continue;
					}

					for (FS_ExtendedWarrantyPart__c ewp : ewpList)
					{
						// If SalesOrgs match... create a Extended Warranty Coverage (EWC)
						if (salesOrg == null || ewp.Sales_Org__c == null || ewp.Sales_Org__c.equalsIgnoreCase(salesOrg))
						{
							FS_ExtendedWarrantyCoverage__c ewc = new FS_ExtendedWarrantyCoverage__c();
							ewc.Extended_Warranty_Part__c = ewp.Id;
							ewc.Parent_Work_Order__c = null;
							ewc.Warranty_Contract__c = item.ParentServiceContractId;
							ewc.Warranty_Contract_Item__c = item.Id;
							ewc.Covered_Part__c = ewp.Covered_Part__c;
							ewc.Covered_Until__c = cp.EndDate.addMonths(ewp.Extended_Months__c.intValue());

							newCoverages.add(ewc);
						}
					}
				}
			}
		} else
		{
			for (WorkOrder wo : woToProcess)
			{
				ContractLineItem cp = ipCpMap.get(wo.AssetId);
				if (cp != null)
				{
					ServiceContract item = cp.ServiceContract;
					Id eqProdId = cp.Asset.Product2Id;
					String salesOrg = (cp.Asset.LocationId == null) ? null: cp.Asset.Location.SalesOrg__c;
					List<FS_ExtendedWarrantyPart__c> ewpList = eqEwpMap.get(eqProdId);
					if (ewpList == null || ewpList.isEmpty())
					{
						continue;
					}

					for (FS_ExtendedWarrantyPart__c ewp : ewpList)
					{
						// If SalesOrgs match... create a Extended Warranty Coverage (EWC)
						if (salesOrg == null || ewp.Sales_Org__c == null || ewp.Sales_Org__c.equalsIgnoreCase(salesOrg))
						{
							FS_ExtendedWarrantyCoverage__c ewc = new FS_ExtendedWarrantyCoverage__c();
							ewc.Extended_Warranty_Part__c = ewp.Id;
							ewc.Parent_Work_Order__c = wo.Id;
							ewc.Warranty_Contract__c = item.ParentServiceContractId;
							ewc.Warranty_Contract_Item__c = item.Id;
							ewc.Covered_Part__c = ewp.Covered_Part__c;
							ewc.Covered_Until__c = cp.EndDate.addMonths(ewp.Extended_Months__c.intValue());

							newCoverages.add(ewc);
						}
					}
				}
			}
		}

		return newCoverages;
	}

	public static void createCoverage(List<WorkOrder> woList)
	{
		if (!FS_Utility.isActive('WO Extended Warranty Coverage', 'Create Extended Warranty Coverage records for the Work Order, if corresponding Expired Warranty and Extended Warranty Parts records are found.'))
		{  return;  }

		// TODO: Do we need to support changes to the Lookup(Installed Product)? (would need to add to update trigger)

		Set<Id> ipIds = new Set<Id>();
		List<WorkOrder> woToProcess = new List<WorkOrder>();
		for (WorkOrder wo : woList)
		{
			// NOTE: Assume that if the WO is "Entitled by Warranty" then an "Extended Warranty" would NOT apply
			if (wo.IsEntitledWarranty__c == false && wo.AssetId != null)
			{
				ipIds.add(wo.AssetId);
				woToProcess.add(wo);
			}
		}

		if (woToProcess.isEmpty())
		{
			return;
		}

		List<FS_ExtendedWarrantyCoverage__c> newCoverages = getCoverages(new List<Id>(ipIds), woList);

		if (!newCoverages.isEmpty())
		{
			insert newCoverages;
		}
	}

	/*public static void createExtendedWarrantyWorkOrders(List<BD_Extended_Warranty_Coverage__c> ewcList, Map<Id, BD_Extended_Warranty_Coverage__c> oldMap)
	{
	  if (!SMAX_PS_Utility.isActive('WO Extended Warranty WOs', 'Create Extended Warranty Work Orders for the Coverage, if corresponding Create Work Order is checked.'))
	  {  return;  }

	  Set<Id> woIds = new Set<Id>();
	  List<BD_Extended_Warranty_Coverage__c> ewcToUpdate = new List<BD_Extended_Warranty_Coverage__c>();
	  for (BD_Extended_Warranty_Coverage__c ewc : ewcList)
	  {
		BD_Extended_Warranty_Coverage__c old = (oldMap == null) ? null : oldMap.get(ewc.Id);
		if (old != null && ewc.BD_Create_Warranty_Work_Order__c == TRUE && ewc.BD_Warranty_Work_Order__c == null
			&& old.BD_Create_Warranty_Work_Order__c != ewc.BD_Create_Warranty_Work_Order__c)
		{
		  // When the "Create Work Order" checkbox is checked, create a Work Order...
		  ewcToUpdate.add(ewc);
		  woIds.add(ewc.BD_Parent_Work_Order__c);
		}
	  }

	  if (ewcToUpdate.isEmpty())
	  {
		return;
	  }

	  Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>([SELECT Id, Name, RecordTypeId,
		  SVMXC__Billing_Type__c, SVMXC__Order_Type__c, SVMX_PS_Origin__c, SVMXC__Priority__c,
		  SVMXC__Company__c, SMAX_PS_BillTo__c, SMAX_PS_Payer__c, SMAX_PS_ShipTo__c, SVMXC__Component__c,
		  SVMXC__Site__c, SVMXC__Contact__c, SVMXC__Group_Member__c, SMAX_PS_Customer_Required_Start_Date__c,
		  SVMXC__Problem_Description__c, SVMX_PS_Problem_Summary__c,
		  SMAX_PS_SettlementOrderType__c, SMAX_PS_SettlementReciever__c,
		  SVMXC__City__c, SVMXC__State__c, SVMXC__Street__c, SVMXC__Zip__c, SVMXC__Country__c
		FROM WorkOrder WHERE Id IN :woIds]);

	  RecordType fsRT = SMAX_PS_Utility.getRecordType('WorkOrder', 'Field_Service');
	  Map<BD_Extended_Warranty_Coverage__c, WorkOrder> ewcWoMap = new Map<BD_Extended_Warranty_Coverage__c, WorkOrder>();
	  for (BD_Extended_Warranty_Coverage__c ewc : ewcToUpdate)
	  {
		WorkOrder wo = woMap.get(ewc.BD_Parent_Work_Order__c);
		if (wo != null)
		{
		  WorkOrder newWO = new WorkOrder();
		  newWO.SVMX_PS_Parent_Work_Order__c = wo.Id;
		  newWO.RecordTypeId = fsRT.Id;
		  newWO.SVMXC__Order_Status__c = 'Initializing';
		  newWO.SVMXC__Billing_Type__c = 'Contract';
		  newWO.SVMXC__Service_Contract__c = ewc.BD_Warranty_Contract__c;
		  newWO.SMAX_PS_ContractItem__c = ewc.BD_Warranty_Contract_Item__c;
		  newWO.SVMXC__Order_Type__c = wo.SVMXC__Order_Type__c;
		  newWO.SVMX_PS_Origin__c = wo.SVMX_PS_Origin__c;
		  newWO.SVMXC__Priority__c = wo.SVMXC__Priority__c;
		  newWO.SVMXC__Company__c = wo.SVMXC__Company__c;
		  newWO.SMAX_PS_BillTo__c = wo.SMAX_PS_BillTo__c;
		  newWO.SMAX_PS_Payer__c = wo.SMAX_PS_Payer__c;
		  newWO.SMAX_PS_ShipTo__c = wo.SMAX_PS_ShipTo__c;
		  newWO.SVMXC__Component__c = wo.SVMXC__Component__c;
		  newWO.SVMXC__Site__c = wo.SVMXC__Site__c;
		  newWO.SVMXC__Contact__c = wo.SVMXC__Contact__c;
		  newWO.SVMXC__Group_Member__c = wo.SVMXC__Group_Member__c;
		  newWO.SMAX_PS_Customer_Required_Start_Date__c = wo.SMAX_PS_Customer_Required_Start_Date__c;
		  newWO.SVMXC__Problem_Description__c = ewc.BD_Extended_Warranty_Description__c
			+ '\n' + wo.SVMXC__Problem_Description__c;
		  newWO.SVMX_PS_Problem_Summary__c = wo.SVMX_PS_Problem_Summary__c;
		  newWO.SMAX_PS_SettlementOrderType__c = wo.SMAX_PS_SettlementOrderType__c;
		  newWO.SMAX_PS_SettlementReciever__c = wo.SMAX_PS_SettlementReciever__c;
		  newWO.SVMXC__City__c = wo.SVMXC__City__c;
		  newWO.SVMXC__State__c = wo.SVMXC__State__c;
		  newWO.SVMXC__Street__c = wo.SVMXC__Street__c;
		  newWO.SVMXC__Zip__c = wo.SVMXC__Zip__c;
		  newWO.SVMXC__Country__c = wo.SVMXC__Country__c;

		  ewcWoMap.put(ewc, newWO);
		}

	  }

	  if (ewcWoMap.isEmpty())
	  {
		return;
	  }

	  insert ewcWoMap.values();

	  for (BD_Extended_Warranty_Coverage__c ewc : ewcWoMap.keySet())
	  {
		WorkOrder wo = ewcWoMap.get(ewc);
		if (wo != null)
		{
		  ewc.BD_Warranty_Work_Order__c = wo.Id;
		}
	  }
	}*/
}