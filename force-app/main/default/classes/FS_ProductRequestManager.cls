/**
 *  Apex Class for Product Request Business Logic.
 *  2017-10-05      Veerendra Moodbidri       Initial creation, for Parts Order Outbound Integration.
 *  1. Create Parts Order Event when Order Status is Submitted to ERP.
 * 2022-04-05   Tony    ITSVMX-562 Modify the replenishment parts ordering process in SVMX to automatically change the ordered part from new to refurbished if a refurbished option is available IF the customer/contract allows
 * 2022-08-02   Tony    ITSVMX-562 We no longer want to exclude APAC as this with be done by master data not having refurbished parts
 * CONVERTED to SFS by frankvanloon on 5/6/24.
 */
public with sharing class FS_ProductRequestManager {

	public static void copyRelatedData(List<ProductRequest> poList) {
		if (!FS_Utility.isActive('Copy Related Data', 'Copy Account Details to Parts Order.')) {
			return;
		}

		// If DestinationLocationId, but no ServiceResource__c..
		// Find a Tech referencing the same Loc Id in SVMXC__Inventory_Location__c
		Set<Id> locIds = new Set<Id>();
		// SVMXCFG-541 - WO Ship To Mappings
		Set<Id> woIds = new Set<Id>();
		for (ProductRequest po : poList) {
			if (po.DestinationLocationId != null && po.ServiceResource__c == null) {
				locIds.add(po.DestinationLocationId);
			} else if (po.SourceLocationId != null && po.ServiceResource__c == null) {
				locIds.add(po.SourceLocationId);
			}
			if (po.WorkOrderId != null) {
				woIds.add(po.WorkOrderId);
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

			for (ProductRequest po : poList) {
				if (po.DestinationLocationId != null && po.ServiceResource__c == null
						&& locTechMap.containsKey(po.DestinationLocationId)) {
					ServiceResource tech = locTechMap.get(po.DestinationLocationId);
					po.ServiceResource__c = tech.Id;
					if (po.SalesOrg__c == null) {
						po.SalesOrg__c = tech.Location.SalesOrg__c;
						System.debug('--SET SalesOrg FROM destination tech.location');
					}
				} else if (po.SourceLocationId != null && po.ServiceResource__c == null
						&& locTechMap.containsKey(po.SourceLocationId)) {
					// ITSVMX-266 Map Tech from the Source Location also
					ServiceResource tech = locTechMap.get(po.SourceLocationId);
					po.ServiceResource__c = tech.Id;
					if (po.SalesOrg__c == null) {
						po.SalesOrg__c = tech.Location.SalesOrg__c;
						System.debug('--SET SalesOrg FROM source tech.location');
					}
				}

				if (po.ServiceResource__c == null) {
					anyMissingTechs = true;
				}
			}
		}

		// ITSVMX-1227 Reordering the To-Location SalesOrg logic to run prior to the Current User Tech logic
		// SVMXCFG-614: Last try.. if we didn't find a Tech for the StorageLocation, look it up directly for the SalesOrg
		locIds.clear();
		for (ProductRequest po : poList) {
			if (po.DestinationLocationId != null && (po.SalesOrg__c == null || po.AccountId == null
					|| po.SoldTo__c == null || po.ShipTo__c == null)) {
				locIds.add(po.DestinationLocationId);
			}
		}

		if (!locIds.isEmpty()) {
			Map<Id, Schema.Location> locMap = new Map<Id, Schema.Location>([
					SELECT Id, Name, SalesOrg__c, Account__c, ShipTo__c, SoldTo__c
					FROM Location
					WHERE Id IN :locIds
			]);
			for (ProductRequest po : poList) {
				if (po.DestinationLocationId != null) {
					Schema.Location loc = locMap.get(po.DestinationLocationId);
					if (loc != null) {
						if (po.SalesOrg__c == null) {
							po.SalesOrg__c = loc.SalesOrg__c;
							System.debug('--SET SalesOrg FROM dest location');
						}
						if (po.AccountId == null) {
							po.AccountId = loc.Account__c;
						}
						if (po.SoldTo__c == null) {
							po.SoldTo__c = loc.SoldTo__c;
						}
						if (po.ShipTo__c == null) {
							po.ShipTo__c = loc.ShipTo__c;
						}
					}
				}
			}
		}

		// SVMXCFG-614: Try to auto-fill Technician by Current User..
		if (anyMissingTechs) {
			List<ServiceResource> debriefTechs = [SELECT Id, Name FROM ServiceResource WHERE RelatedRecordId = :UserInfo.getUserId()];

			if (debriefTechs.size() > 0) {
				for (ProductRequest po : poList) {
					if (po.ServiceResource__c == null) {
						po.ServiceResource__c = debriefTechs[0].Id;
					}
				}
			}
		}

		Set<Id> techIds = new Set<Id>();
		for (ProductRequest po : poList) {
			if (po.ServiceResource__c != null) {
				techIds.add(po.ServiceResource__c);
			}
		}

		if (!techIds.isEmpty()) {
			Map<Id, ServiceResource> techMap = new Map<Id, ServiceResource>([
					SELECT Id, Name,
							LocationId, Location.Account__c, Location.SalesOrg__c, Technician_Manager_Email__c, Work_Center__c
					FROM ServiceResource
					WHERE Id IN :techIds
			]);
			for (ProductRequest po : poList) {
				if (po.ServiceResource__c != null) {
					ServiceResource tech = techMap.get(po.ServiceResource__c);
					if (tech != null && tech.LocationId != null) {
						if (po.AccountId == null) {
							po.AccountId = tech.Location.Account__c;
						}
						if (po.SalesOrg__c == null) {
							po.SalesOrg__c = tech.Location.SalesOrg__c;
							System.debug('--SET SalesOrg FROM tech.location');
						}
					}

//                  if (tech != null && po.RecordTypeId == rmaRT.Id)
//                  {
//                      po.SVMXC__Warehouse__c = tech.Name + ' [' + tech.Work_Center__c + ']';
//                  }

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
							//ShipTo__r.Transportation_Zone__c, ShipTo__r.PKI_SAP_Language__c,
							SalesOrg__c
					FROM WorkOrder
					WHERE Id IN :woIds
			]);
			for (ProductRequest po : poList) {
				WorkOrder wo = (po.WorkOrderId != null) ? woMap.get(po.WorkOrderId) : null;
				if (wo != null && wo.ShipTo__c != null) {
					// TODO: Fill in Transportation_Zone and Language...
//                  po.Transportation_Zone__c = wo.ShipTo__r.Transportation_Zone__c;
//                  po.Language__c = wo.ShipTo__r.PKI_SAP_Language__c;
					// ITSFDC-863 - Map the ShipTo from the Work Order
					if (po.ShipTo__c == null) {
						po.ShipTo__c = wo.ShipTo__c;
					}
				}
//				if (wo != null && po.SalesOrg__c == null) {
//					// Added for Loaners and RMA
//					po.SalesOrg__c = wo.SalesOrg__c;
//					System.debug('--SET SalesOrg FROM WO');
//				}
			}
		}

		// SVMXINT-630 Lookup Shipment and Delivery Accounts
		Set<String> accountExtIds = new Set<String>();
		// ITSVMX-153 Lookup Destination Location using the Ship to External Ids also
		Set<String> locExtIds = new Set<String>();
		for (ProductRequest po : poList) {
			if (po.AccountId == null && po.SoldTo_ExtId__c != null) {
				accountExtIds.add(po.SoldTo_ExtId__c);
			}
			if (po.DestinationLocationId == null && po.ShipTo_ExtId__c != null) {
				locExtIds.add(po.ShipTo_ExtId__c);
			}
		}

		Map<String, Account> accountMap = FS_AccountManager.findAccounts(accountExtIds);
		Set<String> customerNumbers = new Set<String>();
		Set<Id> acctIds = new Set<Id>();
		Set<String> salesOrgs = new Set<String>();
		for (ProductRequest po : poList) {
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
					AND fxCustomerNumber_Target__c IN :customerNumbers]) {
				String erpKey = getErpKey(erp.Address_Type__c, erp.ERP_Sales_Org__c, erp.fxCustomerNumber_Target__c);
				erpMap.put(erpKey, erp);
			}

			for (ProductRequest po : poList) {
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
			for (ProductRequest po : poList) {
				if (po.DestinationLocationId == null && po.ShipTo_ExtId__c != null) {
					Schema.Location loc = locMap.get(po.ShipTo_ExtId__c);
					if (loc != null) {
						po.DestinationLocationId = loc.Id;
					}
				}
			}
		}

		// TODO: Redesign to ERP_Address?
		// SVMXINT-612 map the Transportation Zone and Language from Account if no WO
//      Set<Id> acctIds = new Set<Id>();
//      for (ProductRequest po : poList)
//      {
//          if (po.WorkOrderId == null && po.AccountId != null)
//          {
//              acctIds.add(po.AccountId);
//          }
//      }
//
//      if (!acctIds.isEmpty())
//      {
//          Map<Id, Account> acctMap = new Map<Id, Account>([SELECT Id, Name,
//                  Transportation_Zone__c, SAP_Language__c
//          FROM Account WHERE Id IN :acctIds]);
//          for (ProductRequest po : poList)
//          {
//              if (po.WorkOrderId == null && po.AccountId != null)
//              {
//                  Account acct = acctMap.get(po.AccountId);
//                  if (acct != null)
//                  {
//                      po.Transportation_Zone__c = acct.Transportation_Zone__c;
//                      po.Language__c = acct.SAP_Language__c;
//                  }
//              }
//          }
//      }

	}

	public static String getErpKey(String type, String salesOrg, String extId) {
		return type + '-' + salesOrg + '-' + extId;
	}

	// 2022-04-16 Tony ITSVMX-562 Modify the replenishment parts ordering process
	// NOTE: Should be called on before insert and before update
	public static void useRefurbishedParts(List<ProductRequestLineItem> partsOrderLines, Map<Id, ProductRequestLineItem> oldMap) {
		if (!FS_Utility.isActive('Use Refurbished Part on Order Line', 'If Refurbished Parts are allowed then use them on this Parts Order Line.'))
			return;

		System.debug('Entering SMAX_PS_InventoryManager.useRefurbishedParts');

		// Get Sets of Ids for Parts Orders, Work Orders, and Products
		Set<Id> partsOrderIds = new Set<Id>();
		Set<Id> productIds = new Set<Id>();
		for (ProductRequestLineItem partsOrderLine :partsOrderLines) {

			if (partsOrderLine.ParentId != null) partsOrderIds.add(partsOrderLine.ParentId);
			if (partsOrderLine.Product2ID != null) productIds.add(partsOrderLine.Product2ID);
		}

		System.debug('partsOrderIds: ' + partsOrderIds.size() + ' ' + partsOrderIds);
		System.debug('productIds: ' + productIds.size() + ' ' + productIds);

		// 7/14/2022 We are getting the "Too Many SOQL Queries" error in our unit tests. Exit early if there are no partsOrderIds or productIds
		if (partsOrderIds.isEmpty() && productIds.isEmpty()) return;

		// Get the List of Parts Orders with Use Refurbished Parts value
		List<ProductRequest> partsOrders = [
				SELECT Id,Use_Refurbished_Parts__c, WorkOrderId
				FROM ProductRequest
				WHERE Id IN :partsOrderIds
		];

		// Create a Map of Parts Order Ids to Use Refurbished Parts values AND Get a Set of Ids for Work Orders
		Set<Id> workOrderIds = new Set<Id>();
		Map<Id, Boolean> partsOrderIdToUseRefurbPartValue = new Map<Id, Boolean>();
		Map<Id, Id> partsOrderIdToWorkOrderId = new Map<Id, Id>();
		for (ProductRequest partsOrder :partsOrders) {

			partsOrderIdToUseRefurbPartValue.put(partsOrder.Id, partsOrder.Use_Refurbished_Parts__c);

			System.debug('partsOrder.SVMXC__Service_Order__c: ' + partsOrder.WorkOrderId);
			if (partsOrder.WorkOrderId != null) workOrderIds.add(partsOrder.WorkOrderId);
			partsOrderIdToWorkOrderId.put(partsOrder.Id, partsOrder.WorkOrderId);
		}
		System.debug('workOrderIds: ' + workOrderIds.size() + ' ' + workOrderIds);
		System.debug('partsOrderIdToWorkOrderId: ' + partsOrderIdToWorkOrderId.size() + ' ' + partsOrderIdToWorkOrderId);

		// Get the List of Work Orders with Use Refurbished Parts values and Plant Codes
		List<WorkOrder> workOrders = [
				SELECT Id,Use_Refurbished_Parts__c, Asset.MaintenancePlant__c
				FROM WorkOrder
				WHERE Id IN:workOrderIds
		];

		// Create Maps of Work Order Ids to Use Refurbished Parts values and Work Order Ids to Plant Codes
		Map<Id, Boolean> workOrderIdToUseRefurbPartValue = new Map<Id, Boolean>();
		Map<Id, String> workOrderIdToPlantCode = new Map<Id, String>();
		for (WorkOrder workOrder :workOrders) {

			workOrderIdToUseRefurbPartValue.put(workOrder.Id, workOrder.Use_Refurbished_Parts__c);
			workOrderIdToPlantCode.put(workOrder.Id, workOrder.Asset.MaintenancePlant__c);
		}
		System.debug('workOrderIdToUseRefurbPartValue: ' + workOrderIdToUseRefurbPartValue.size() + ' ' + workOrderIdToUseRefurbPartValue);
		System.debug('workOrderIdToPlantCode: ' + workOrderIdToPlantCode.size() + ' ' + workOrderIdToPlantCode);

		// Get the list of Parts Order Lines that have a Parts Order with BD_Use_Refurbished_Parts__c = TRUE and Work Order with BD_Use_Refurbished_Parts__c = TRUE
		List<ProductRequestLineItem> partsOrderLinesToUpdate = new List<ProductRequestLineItem>();
		for (ProductRequestLineItem partsOrderLine :partsOrderLines) {

			System.debug('partsOrderLine.SVMXC__RMA_Shipment_Order__c: ' + partsOrderLine.ParentId);
			Id workOrderId = partsOrderIdToWorkOrderId.get(partsOrderLine.ParentId);
			System.debug('Parts Order workOrderId: ' + workOrderId);
			if (partsOrderIdToUseRefurbPartValue.get(partsOrderLine.ParentId) == true
					&& workOrderIdToUseRefurbPartValue.get(workOrderId) == true) {

				System.debug('Adding Parts Order Line to partsOrderLinesToUpdate: ' + partsOrderLine);
				partsOrderLinesToUpdate.add(partsOrderLine);
			}
		}

		if (partsOrderLinesToUpdate.isEmpty()) {
			System.debug('There are no Parts Order Lines that qualify to use Refurbished Parts');
			return;
		}

		// Get the list of Product Plants that have the same Product and Plant as our Parts Order Line/Work Order
		List<FS_ProductPlant__c> productPlants = [
				SELECT Id, Product__c, Plant__c, Refurbished_Part__c, Refurbished_Part_Number__c
				FROM FS_ProductPlant__c
				WHERE Product__c IN :productIds
				AND Plant__c IN :workOrderIdToPlantCode.values()
		];
		System.debug('productPlants: ' + productPlants.size() + ' ' + productPlants);

		// Create Maps using a combination key of product-plant to BD_Refurbished_Part__c and BD_Refurbished_Part_Number__c
		Map<String, Id> productPlantToRefurbPart = new Map<String, Id>();
		Map<String, String> productPlantToRefurbPartNumber = new Map<String, String>();
		for (FS_ProductPlant__c productPlant :productPlants) {

			productPlantToRefurbPart.put(productPlant.Product__c + '-' + productPlant.Plant__c, productPlant.Refurbished_Part__c);
			productPlantToRefurbPartNumber.put(productPlant.Product__c + '-' + productPlant.Plant__c, productPlant.Refurbished_Part_Number__c);
		}
		System.debug('productPlantToRefurbPart: ' + productPlantToRefurbPart.size() + ' ' + productPlantToRefurbPart);
		System.debug('productPlantToRefurbPartNumber: ' + productPlantToRefurbPartNumber.size() + ' ' + productPlantToRefurbPartNumber);

		// Update the Parts Order Line SVMXC__Product__c and Partnum__c
		for (ProductRequestLineItem partsOrderLine :partsOrderLinesToUpdate) {

			Id workOrderId = partsOrderIdToWorkOrderId.get(partsOrderLine.ParentId);
			String plantCode = workOrderIdToPlantCode.get(workOrderId);
			Id productId = partsOrderLine.Product2Id;

			//06/10/2022 Tony Fix SVMXC__Product__c and Partnum__c being set to null when no refurbished part was found
			//partsOrderLine.SVMXC__Product__c = productPlantToRefurbPart.get(productId + '-' + plantCode);
			//partsOrderLine.Partnum__c = productPlantToRefurbPartNumber.get(productId + '-' + plantCode);
			Id refurbPart = productPlantToRefurbPart.get(productId + '-' + plantCode);
			String refurbPartNum = productPlantToRefurbPartNumber.get(productId + '-' + plantCode);
			if (refurbPart != null && refurbPartNum != null) {

				partsOrderLine.Product2ID = refurbPart;
				partsOrderLine.Partnum__c = refurbPartNum;
			}
		}
		System.debug('partsOrderLinesToUpdated: ' + partsOrderLinesToUpdate.size() + ' ' + partsOrderLinesToUpdate);

		System.debug('Exiting SMAX_PS_InventoryManager.useRefurbishedParts');
	}

	// 2022-04-05 Tony ITSVMX-562 Modify the replenishment parts ordering process
	// NOTE: Should be called on before insert and before update
	public static void refurbishedPartsAllowed(List<ProductRequest> partsOrders, Map<Id, ProductRequest> oldMap)
	{
		if (!FS_Utility.isActive('Parts Order Refurbished Parts Allowed', 'If Refurbished Parts are allowed then set the checkbox fields.'))
			return;

		System.debug('Entering SMAX_PS_PartsOrderManager.refurbishedPartsAllowed');

		Set<Id> refurbishWorkOrderIds = new Set<Id>();
		List<ProductRequest> refurbishPartsOrders = new List<ProductRequest>();

		// Get the list of parts orders that might qualify for Refurbished Parts
		for (ProductRequest po :partsOrders) {
			ProductRequest old = (oldMap == null) ? null : oldMap.get(po.Id);

			// 8/2/2022 ITSVMX-562 We no longer want to exclude APAC as this with be done by master data not having refurb parts
			// if (po.BD_Refurbished_Parts_Allowed__c == false && po.SMAX_PS_Is_APAC_Parts_Order__c == false) {
			if (po.Refurbished_Parts_Allowed__c == false) {

				//System.debug('Found a Parts Order that might qualify to use Refurbished Parts: ' + po.Name);
				refurbishWorkOrderIds.add(po.WorkOrderId);
				refurbishPartsOrders.add(po);
			}
		}

		if (refurbishPartsOrders.isEmpty()) return;

		// Get Work Orders with Use Refurbished Parts checkbox
		List<WorkOrder> workOrderWithUseRefurbPartsList = [
				SELECT Id, Use_Refurbished_Parts__c
				FROM WorkOrder
				WHERE Id IN :refurbishWorkOrderIds
		];

		// Create Work Order Id to Use Refurbished Parts mapping
		Map<Id, Boolean> workOrderIdToUseRefurbPartsMap = new Map<Id, Boolean>();
		for (WorkOrder wo :workOrderWithUseRefurbPartsList) {
			workOrderIdToUseRefurbPartsMap.put(wo.Id, wo.Use_Refurbished_Parts__c);
		}

		// Update parts orders that qualify to use refurbished parts
		for (ProductRequest po :refurbishPartsOrders) {
			if (workOrderIdToUseRefurbPartsMap.get(po.WorkOrderId) == true) {

				po.Refurbished_Parts_Allowed__c = true;
				po.Use_Refurbished_Parts__c = true;
			}
		}
		System.debug('refurbishPartsOrders after updates: ' + refurbishPartsOrders.size() + ' ' + refurbishPartsOrders);

		System.debug('Exiting SMAX_PS_PartsOrderManager.refurbishedPartsAllowed');
	}
}