/**
 * Created by frankvanloon on 5/7/24.
 */
public with sharing class FS_ReturnOrderManager {

	public static void copyRelatedData(List<ReturnOrder> poList) {
		if (!FS_Utility.isActive('Copy Related Data', 'Copy Account Details to Parts Order.')) {
			return;
		}

		// If DestinationLocationId, but no Technician__c..
		// Find a Tech referencing the same Loc Id in SVMXC__Inventory_Location__c
		Set<Id> locIds = new Set<Id>();
		// SVMXCFG-541 - WO Ship To Mappings
		Set<Id> woIds = new Set<Id>();
		for (ReturnOrder po : poList) {
			if (po.DestinationLocationId != null && po.Technician__c == null) {
				locIds.add(po.DestinationLocationId);
			} else if (po.SourceLocationId != null && po.Technician__c == null) {
				locIds.add(po.SourceLocationId);
			}
			if (po.Work_Order__c != null) {
				woIds.add(po.Work_Order__c);
			}
		}

		Boolean anyMissingTechs = false;
		if (!locIds.isEmpty()) {
			Map<Id, ServiceResource> locTechMap = new Map<Id, ServiceResource>();
			for (ServiceResource tech : [
					SELECT Id, Name, LocationId, Location.SalesOrg__c
					FROM ServiceResource
					WHERE LocationId IN :locIds
			]) {
				locTechMap.put(tech.LocationId, tech);
			}

			for (ReturnOrder po : poList) {
				if (po.DestinationLocationId != null && po.Technician__c == null
						&& locTechMap.containsKey(po.DestinationLocationId)) {
					ServiceResource tech = locTechMap.get(po.DestinationLocationId);
					po.Technician__c = tech.Id;
					if (po.SalesOrg__c == null) {
						po.SalesOrg__c = tech.Location.SalesOrg__c;
					}
				} else if (po.SourceLocationId != null && po.Technician__c == null
						&& locTechMap.containsKey(po.SourceLocationId)) {
					// ITSVMX-266 Map Tech from the Source Location also
					ServiceResource tech = locTechMap.get(po.SourceLocationId);
					po.Technician__c = tech.Id;
					if (po.SalesOrg__c == null) {
						po.SalesOrg__c = tech.Location.SalesOrg__c;
					}
				}

				if (po.Technician__c == null) {
					anyMissingTechs = true;
				}
			}
		}

		// ITSVMX-1227 Reordering the To-Location SalesOrg logic to run prior to the Current User Tech logic
		// SVMXCFG-614: Last try.. if we didn't find a Tech for the StorageLocation, look it up directly for the SalesOrg
		locIds.clear();
		for (ReturnOrder po : poList) {
			if (po.DestinationLocationId != null &&
					(po.SalesOrg__c == null || po.AccountId == null)) {
				locIds.add(po.DestinationLocationId);
			}
		}

		if (!locIds.isEmpty()) {
			Map<Id, Schema.Location> locMap = new Map<Id, Schema.Location>([
					SELECT Id, Name, SalesOrg__c, Account__c
					FROM Location
					WHERE Id IN :locIds
			]);
			for (ReturnOrder po : poList) {
				if (po.DestinationLocationId != null) {
					Schema.Location loc = locMap.get(po.DestinationLocationId);
					if (loc != null) {
						if (po.SalesOrg__c == null) {
							po.SalesOrg__c = loc.SalesOrg__c;
						}
						if (po.AccountId == null) {
							po.AccountId = loc.Account__c;
						}
					}
				}
			}
		}

		// SVMXCFG-614: Try to auto-fill Technician by Current User..
		if (anyMissingTechs) {
			List<ServiceResource> debriefTechs = [SELECT Id, Name FROM ServiceResource WHERE RelatedRecordId = :UserInfo.getUserId()];

			if (debriefTechs.size() > 0) {
				for (ReturnOrder po : poList) {
					if (po.Technician__c == null) {
						po.Technician__c = debriefTechs[0].Id;
					}
				}
			}
		}

		Set<Id> techIds = new Set<Id>();
		for (ReturnOrder po : poList) {
			if (po.Technician__c != null) {
				techIds.add(po.Technician__c);
			}
		}

		if (!techIds.isEmpty()) {
			Map<Id, ServiceResource> techMap = new Map<Id, ServiceResource>(
			[
					SELECT Id, Name, LocationId, Location.Account__c, Location.SalesOrg__c,
							Technician_Manager_Email__c, Work_Center__c
					FROM ServiceResource
					WHERE Id IN :techIds
			]);
			for (ReturnOrder po : poList) {
				if (po.Technician__c != null) {
					ServiceResource tech = techMap.get(po.Technician__c);
					if (tech != null && tech.LocationId != null) {
						if (po.AccountId == null) {
							po.AccountId = tech.Location.Account__c;
						}
						if (po.SalesOrg__c == null) {
							po.SalesOrg__c = tech.Location.SalesOrg__c;
						}
					}
					po.Warehouse__c = tech.Name + ' [' + tech.Work_Center__c + ']';

					// SVMXCFG-914 Fill in Technician_Manager_Email__c
					if (tech != null) {
						po.Technician_Manager_Email__c = tech.Technician_Manager_Email__c;
					}
				}
			}
		}

		/*
			SVMXCFG-541 - Ship To Mappings
			- Pull from PO.ShipTo__c OR po.SVMXC__Company__c INSTEAD.
			Map the (Transportation_Zone__c) from the Work Order Ship To Account (ShipTo__c) to (Transportation_Zone__c) on the Parts Order
			Map the (PKI_SAP_Language__c) from the Work Order Ship To Account (ShipTo__c) to the (Language__c) on the Parts Order
		*/
		if (!woIds.isEmpty()) {
			Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>([
					SELECT Id, WorkOrderNumber, ShipTo__c,
							// TODO: ShipTo__r.Transportation_Zone__c, ShipTo__r.PKI_SAP_Language__c,
							SalesOrg__c
					FROM WorkOrder
					WHERE Id IN :woIds
			]);
			for (ReturnOrder po : poList) {
				WorkOrder wo = (po.Work_Order__c != null) ? woMap.get(po.Work_Order__c) : null;
				if (wo != null && wo.ShipTo__c != null) {
					// TODO: Fill in from ERP Address?
//					po.Transportation_Zone__c = wo.ShipTo__r.Transportation_Zone__c;
//					po.Language__c = wo.ShipTo__r.PKI_SAP_Language__c;
					// ITSFDC-863 - Map the ShipTo from the Work Order
					if (po.ShipTo__c == null) {
						po.ShipTo__c = wo.ShipTo__c;
					}
				}
				if (wo != null && po.SalesOrg__c == null) {
					// Added for Loaners and RMA
					po.SalesOrg__c = wo.SalesOrg__c;
				}
			}
		}

		// SVMXINT-630 Lookup Shipment and Delivery Accounts
		Set<String> accountExtIds = new Set<String>();
		// ITSVMX-153 Lookup Destination Location using the Ship to External Ids also
		Set<String> locExtIds = new Set<String>();
		for (ReturnOrder po : poList) {
			if (po.AccountId == null && po.SoldTo_ExtId__c != null) {
				accountExtIds.add(po.SoldTo_ExtId__c);
			}
			if (po.SourceLocationId == null && po.ShipTo_ExtId__c != null) {
				locExtIds.add(po.ShipTo_ExtId__c);
			}
		}

		Map<String, Account> accountMap = FS_AccountManager.findAccounts(accountExtIds);
		Set<String> customerNumbers = new Set<String>();
		Set<Id> acctIds = new Set<Id>();
		Set<String> salesOrgs = new Set<String>();
		for (ReturnOrder po : poList) {
			if (po.AccountId == null && po.SoldTo_ExtId__c != null) {
				Account acct = accountMap.get(po.SoldTo_ExtId__c);
				if (acct != null) {
					po.AccountId = acct.Id;
				}
			}
			if (po.AccountId != null && po.SalesOrg__c != null) {
				acctIds.add(po.AccountId);
				salesOrgs.add(po.SalesOrg__c);
				if (po.SoldTo__c == null && po.SoldTo_ExtId__c != null) {
					customerNumbers.add(po.SoldTo_ExtId__c);
				}
				if (po.ShipTo__c == null && po.ShipTo_ExtId__c != null) {
					customerNumbers.add(po.ShipTo_ExtId__c);
				}
			}
		}

		if (!customerNumbers.isEmpty()) {
			Map<String, ERP_Address__c> erpMap = new Map<String, ERP_Address__c>();
			for (ERP_Address__c erp : [
					SELECT Id, Name, Address_Type__c, ERP_Sales_Org__c, fxCustomerNumber_Target__c
					FROM ERP_Address__c
					WHERE Account__c IN :acctIds AND ERP_Sales_Org__c IN :salesOrgs
					AND fxCustomerNumber_Target__c IN :customerNumbers
			]) {
				String erpKey = getErpKey(erp.Address_Type__c, erp.ERP_Sales_Org__c, erp.fxCustomerNumber_Target__c);
				erpMap.put(erpKey, erp);
			}

			for (ReturnOrder po : poList) {
				String soldToKey = getErpKey('Sold To', po.SalesOrg__c, po.SoldTo_ExtId__c);
				if (po.SoldTo_ExtId__c != null && erpMap.containsKey(soldToKey)) {
					po.SoldTo__c = erpMap.get(soldToKey).Id;
				}
				String shipToKey = getErpKey('Ship To', po.SalesOrg__c, po.ShipTo_ExtId__c);
				if (po.ShipTo_ExtId__c != null && erpMap.containsKey(shipToKey)) {
					po.ShipTo__c = erpMap.get(shipToKey).Id;
				}
			}
		}

		// ITSVMX-153 Lookup Destination Location using the Ship to External Ids also
		if (!locExtIds.isEmpty()) {
			Map<String, Schema.Location> locMap = new Map<String, Schema.Location>();
			for (Schema.Location loc : [
					SELECT Id, Name, External_ID__c
					FROM Location
					WHERE External_ID__c IN :locExtIds
			]) {
				locMap.put(loc.External_ID__c, loc);
			}
			for (ReturnOrder po : poList) {
				if (po.SourceLocationId == null && po.ShipTo_ExtId__c != null) {
					Schema.Location loc = locMap.get(po.ShipTo_ExtId__c);
					if (loc != null) {
						po.SourceLocationId = loc.Id;
					}
				}
			}
		}

		// TODO: Redesign to ERP_Address?
		// SVMXINT-612 map the Transportation Zone and Language from Account if no WO
//		Set<Id> acctIds = new Set<Id>();
//		for (ReturnOrder po : poList)
//		{
//			if (po.Work_Order__c == null && po.AccountId != null)
//			{
//				acctIds.add(po.AccountId);
//			}
//		}
//
//		if (!acctIds.isEmpty())
//		{
//			Map<Id, Account> acctMap = new Map<Id, Account>([SELECT Id, Name,
//					Transportation_Zone__c, SAP_Language__c
//			FROM Account WHERE Id IN :acctIds]);
//			for (ReturnOrder po : poList)
//			{
//				if (po.Work_Order__c == null && po.AccountId != null)
//				{
//					Account acct = acctMap.get(po.AccountId);
//					if (acct != null)
//					{
//						po.Transportation_Zone__c = acct.Transportation_Zone__c;
//						po.Language__c = acct.SAP_Language__c;
//					}
//				}
//			}
//		}
	}

	public static String getErpKey(String type, String salesOrg, String extId) {
		return type + '-' + salesOrg + '-' + extId;
	}

	public static void autoCreateRMA(List<WorkOrder> woList, Map<Id, WorkOrder> oldMap) {
		if (!FS_Utility.isActive('Work Order Auto Create RMA', 'When WO is changed to "Depot" OR is "Depot" and gets a SAP Id... auto-create RMA.')) {
			return;
		}

		// 11/13/20 tony - Auto Create Parts Request - initialize
		Map<Id, WorkOrder> depotWorkOrders = new Map<Id, WorkOrder>();
		for (WorkOrder wo : woList) {
			// ITSVMX-253 Only run when NOT on credit-hold
			// ITSVMX-500 Only run when a "Depot Plant" is already assigned to the WO
			WorkOrder old = (oldMap == null) ? null : oldMap.get(wo.Id);
			if (wo.Record_Type__c == 'Depot' && wo.External_ID__c != null && wo.CreditHold__c == false
					&& wo.Depot_Plant__c != null
					&& (old == null || old.Record_Type__c != wo.Record_Type__c
					|| wo.External_ID__c != old.External_ID__c
					|| wo.CreditHold__c != old.CreditHold__c
					|| wo.Depot_Plant__c != old.Depot_Plant__c)) {
				depotWorkOrders.put(wo.Id, wo);
			}
		}

		if (depotWorkOrders.isEmpty()) {
			return;
		}

		// Check for pre-existing RMA (if found, stop)
		List<ReturnOrder> existingRMAs = [
				SELECT Id, ReturnOrderNumber, Work_Order__c
				FROM ReturnOrder
				WHERE Work_Order__c IN :depotWorkOrders.keySet()
		];

		// ITSFDC-1047: Lookup new WO "From" Fields
		Map<Id, WorkOrder> woDetailMap = new Map<Id, WorkOrder>([
				SELECT Id, WorkOrderNumber,
						LocationId, Location.Name, Location.Street__c, Location.City__c,
						Location.State__c, Location.Country__c, Location.Zip__c, Location.MaintenancePlant__c,
						Depot_Plant__c, Depot_Plant__r.Depot_Location__r.Name,
						Depot_Plant__r.Depot_Location__r.Street__c, Depot_Plant__r.Depot_Location__r.City__c,
						Depot_Plant__r.Depot_Location__r.LKUP_State__c, Depot_Plant__r.Depot_Location__r.LKUP_Country__c,
						Depot_Plant__r.Depot_Location__r.Zip__c, Depot_Plant__r.Depot_Location__r.Depot_Work_Center__c,
						FromStreet1__c, FromStreet2__c, FromStreet3__c, FromStreet4__c, FromStreet5__c,
						LKUP_Country__c, LKUP_State__c,
						Source_City__c, Source_Zip__c, SourceName1__c, SourceName2__c, SourceName3__c,
						ContactId, ContactName__c, Contact_Phone__c, SalesOrg__c,
						Product__r.Part_Number__c,
						Asset.Product2Id, Asset.SerialNumber, Asset.Product2.Part_Number__c,
						SoldTo__c, SoldTo__r.fxCustomerNumber_Target__c,
						ShipTo__c, ShipTo__r.fxCustomerNumber_Target__c
				FROM WorkOrder
				WHERE Id IN :depotWorkOrders.keySet()
		]);

		List<ReturnOrder> rmaList = new List<ReturnOrder>();
		for (WorkOrder wo : depotWorkOrders.values()) {
			ReturnOrder woRMA = null;
			for (ReturnOrder rma : existingRMAs) {
				if (rma.Work_Order__c == wo.Id) {
					woRMA = rma;
					break;
				}
			}

			if (woRMA == null) {
				WorkOrder woDetail = woDetailMap.get(wo.Id);

				// Didn't find one, so auto-create one...
				woRMA = new ReturnOrder();
				woRMA.Work_Order__c = wo.Id;
				woRMA.AccountId = wo.AccountId;
				woRMA.Status = 'Open';
				woRMA.Return_Type__c = 'Instrument';
				woRMA.Requested_Delivery_Date__c = Date.today();

				if (woDetail.SoldTo__c != null) {
					woRMA.SoldTo__c = woDetail.SoldTo__c;
					woRMA.SoldTo_ExtId__c = woDetail.SoldTo__r.fxCustomerNumber_Target__c;
				}
				if (woDetail.ShipTo__c != null) {
					woRMA.ShipTo__c = woDetail.ShipTo__c;
					woRMA.ShipTo_ExtId__c = woDetail.ShipTo__r.fxCustomerNumber_Target__c;
				}

				// Map the Source (From) fields from the Location...
				woRMA.SourceLocationId = wo.LocationId;
				// ITSFDC-1047 Copy the Customer Address (From XXX) from WO to RMA
				woRMA.FromStreet1__c = woDetail.FromStreet1__c;
				woRMA.FromStreet2__c = woDetail.FromStreet2__c;
				woRMA.FromStreet3__c = woDetail.FromStreet3__c;
				woRMA.FromStreet4__c = woDetail.FromStreet4__c;
				woRMA.FromStreet5__c = woDetail.FromStreet5__c;
				woRMA.SourceName1__c = woDetail.SourceName1__c;
				woRMA.SourceName2__c = woDetail.SourceName2__c;
				woRMA.SourceName3__c = woDetail.SourceName3__c;
				woRMA.Source_City__c = woDetail.Source_City__c;
				woRMA.Source_Zip__c = woDetail.Source_Zip__c;
				woRMA.ShipFromCity = woDetail.Source_City__c;
				woRMA.ShipFromPostalCode = woDetail.Source_Zip__c;
				woRMA.From_Country__c = woDetail.LKUP_Country__c;
				woRMA.From_State__c = woDetail.LKUP_State__c;

				// ITSFDC-863: Also copy the Contact fields...
				woRMA.ContactId = woDetail.ContactId;
				woRMA.Contact_Name__c = woDetail.ContactName__c;
				woRMA.Contact_Phone__c = woDetail.Contact_Phone__c;
				woRMA.SalesOrg__c = woDetail.SalesOrg__c;

				// Map the Destination (To) fields from the "Depot Plant" Location
				Schema.Location loc = woDetail.Depot_Plant__r.Depot_Location__r;
				if (loc != null) {
					woRMA.Warehouse__c = loc.Name + ' [' + loc.Depot_Work_Center__c + ']';
					woRMA.Destination_Street__c = loc.Street__c;
					woRMA.Destination_City__c = loc.City__c;
					woRMA.Destination_State__c = loc.LKUP_State__c;
					woRMA.Destination_Zip__c = loc.Zip__c;
					woRMA.Destination_Country__c = loc.LKUP_Country__c;
				}

				rmaList.add(woRMA);
			}
		}

		if (rmaList.isEmpty()) {
			return;
		}

		insert rmaList;

		List<ReturnOrderLineItem> rmaLines = new List<ReturnOrderLineItem>();
		for (ReturnOrder partsOrder : rmaList) {
			// Create lines & then update to "Submitted to ERP"
			WorkOrder wo = depotWorkOrders.get(partsOrder.Work_Order__c);
			WorkOrder woDetail = woDetailMap.get(wo.Id);

			ReturnOrderLineItem partsLine = new ReturnOrderLineItem();
			partsLine.ReturnOrderId = partsOrder.Id;
			partsLine.QuantityExpected = 1;
			partsLine.QuantityReturned = 1;
			partsLine.AssetId = wo.AssetId;
			partsLine.Product2Id = wo.Product__c;
			// Added to map the raw Part Number in BOOMI
			partsLine.Partnum__c = woDetail.Product__r.Part_Number__c;

			partsLine.SerialNum__c = woDetail.Asset.SerialNumber;
			if (partsLine.Product2Id == null) {
				partsLine.Product2Id = woDetail.Asset.Product2Id;
			}
			if (String.isBlank(partsLine.Partnum__c)) {
				partsLine.Partnum__c = woDetail.Asset.Product2.Part_Number__c;
			}

			rmaLines.add(partsLine);

			// Also submit the RMA...
			partsOrder.Status = 'Submitted';
		}
		System.debug('rmaLines: '+rmaLines);
		insert rmaLines;
		update rmaList;
	}

	/**
	 * 5/21/21 ITSVMX-461 Trigger to cancel RMA when Depot Repair Work Order is Canceled
	 * Cancel any RMA associated to a Work Order with a Record Type of “Depot Repair”.
	 * NOTE: Should be called by BeforeUpdate trigger handler event.
	*/
	public static void cancelDepotReturnOrders(List<WorkOrder> woList, Map<Id, WorkOrder> oldMap) {

		System.debug('Entering SMAX_PS_WorkOrderManager.cancelDepotRepairRMA method');
		if (!FS_Utility.isActive('Cancel Depot Return Orders', 'When a Depot Repair Work Order is canceled or changed to Field Service, then cancel the RMA Parts Orders and there Parts Order Lines.')) {
			return;
		}

		// Check for Canceled Depot Repair Work Orders and create a set of Ids
		Set<Id> canceledWoIds = new Set<Id>();
		for (WorkOrder wo :woList) {
			WorkOrder old = (oldMap == null) ? null : oldMap.get(wo.Id);
			if (wo.Status == 'Canceled' && wo.Record_Type__c == 'Depot'
					&& (old == null || wo.Status != old.Status)) {
				canceledWoIds.add(wo.Id);
			} else if (old != null && old.Record_Type__c == 'Depot' && wo.Record_Type__c == 'Field Service') {
				canceledWoIds.add(wo.Id);
			}
		}
		System.debug('canceledWoIds: ' + canceledWoIds);

		if (canceledWoIds.size() == 0) return;

		// Get the RMA Parts Orders for the canceled Work Orders
		List<ReturnOrder> rmaPartsOrders = [SELECT Id, Status, Work_Order__c
			FROM ReturnOrder WHERE Work_Order__c IN :canceledWoIds AND Return_Type__c = 'Instrument'];
		System.debug('rmaPartsOrders: ' + rmaPartsOrders);

		// Set the RMA Parts Orders to canceled
		Set<Id> rmaPartsOrderIds = new Set<Id>();
		for (ReturnOrder rmaPartsOrder :rmaPartsOrders) {
			rmaPartsOrder.Status = 'Canceled';
			rmaPartsOrderIds.add(rmaPartsOrder.Id);
		}
		update rmaPartsOrders;

//		// Get the RMA Parts Order Lines for the canceled RMA Parts Orders
//		List<ReturnOrderLineItem> rmaPartsOrderLines = [
//				SELECT Id, SVMXC__Line_Status__c, ReturnOrderId
//				FROM ReturnOrderLineItem
//				WHERE ReturnOrderId IN :rmaPartsOrderIds
//		];
//		System.debug('rmaPartsOrderLines: ' + rmaPartsOrderLines);
//
//		// Set the RMA Parts Orders Lines to canceled
//		for (ReturnOrderLineItem rmaPartsOrderLine :rmaPartsOrderLines) {
//			rmaPartsOrderLine.SVMXC__Line_Status__c = 'Canceled';
//		}
//		update rmaPartsOrderLines;

	}


}