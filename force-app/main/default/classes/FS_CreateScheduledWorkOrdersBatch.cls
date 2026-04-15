/*
 *  Schedulable Batch class for Creating Scheduled Work Orders
 *  2017-09-18		Bill Convis		Initial creation, for Batch Creation of WO via custom PM Schedule.
 *  2017-12-05      Frank VanLoon   Refactoring, fine-tuning.
 *  2018-06-18		Frank VanLoon	Updated for Phase 1.0: SVMXCFG-604, SVMXCFG-605
 *  CONVERTED to SFS by frankvanloon on 4/29/24.
*/
global class FS_CreateScheduledWorkOrdersBatch implements Database.Batchable<SObject> , Schedulable {

	global String CONTRACT_ITEM_ID;
	global String PARENT_CONTRACT_ID;
	global Date START_DATE;
	global Date END_DATE;
	global Integer NUM_DAYS_OUT;
	global Set<String> SALES_ORGS;

	public FS_CreateScheduledWorkOrdersBatch() {}
	public FS_CreateScheduledWorkOrdersBatch(String contractItemId, String parentContractId, Integer numDaysOut)
	{
		this.CONTRACT_ITEM_ID = contractItemId;
		this.PARENT_CONTRACT_ID = parentContractId;
		this.NUM_DAYS_OUT = numDaysOut;
	}

	public FS_CreateScheduledWorkOrdersBatch(Date startDate, Integer numDaysOut, Set<String> salesOrgs)
	{
		this.START_DATE = startDate;
		this.NUM_DAYS_OUT = numDaysOut;
		this.SALES_ORGS = salesOrgs;
	}

	/**
		Schedulable methods
	**/

	global void execute(SchedulableContext sc)
	{
		FS_CreateScheduledWorkOrdersBatch b = new FS_CreateScheduledWorkOrdersBatch(this.START_DATE, this.NUM_DAYS_OUT, this.SALES_ORGS);
		Database.executeBatch(b, 1);
	}

	/*
		Batchable methods
	*/

	global Database.QueryLocator start(Database.BatchableContext BC)
	{
		// SVMXCFG-604: Scheduled WO Batch Job - Monthly
		//Integer numMonths = (NUM_MONTHS_OUT == null) ? 2 : NUM_MONTHS_OUT;
		//END_DATE = System.today().addMonths(numMonths+1).toStartOfMonth();

		// SVMXCFG-701 Revert to Num Days
		Integer numDays = (NUM_DAYS_OUT == null) ? 60 : NUM_DAYS_OUT;
		END_DATE = System.today().addDays(numDays);

		String query = 'SELECT Id, Name, PlannedDate__c, EntitlementCondition__c, '
				+ 'ContractItem__c, ContractItem__r.ParentServiceContractId, '
				+ 'ContractItem__r.ParentServiceContract.ContactId, '
				+ 'ContractItem__r.ParentServiceContract.Contact.FirstName, '
				+ 'ContractItem__r.ParentServiceContract.Contact.LastName, '
				+ 'ContractItem__r.ParentServiceContract.SalesOrg__c, '
				+ 'ContractItem__r.ParentServiceContract.PONumber__c, '
				+ 'ContractItem__r.ParentServiceContract.Active__c, '
				+ 'ContractItem__r.SLA_Terms_Notes__c, '
				+ 'ContractItem__r.fxIs_Warranty__c, '
				//+ 'ContractItem__r.fxIs_Enterprise__c, '
				+ 'Entitlement__c, Entitlement__r.EntitlementTypeName__c, '
				+ 'Entitlement__r.EntitlementType__c, '
				+ 'Entitlement__r.Labor_Discount_Covered__c, '
				+ 'Entitlement__r.Travel_Discount_Covered__c, '
				+ 'Entitlement__r.Parts_Discount_Covered__c, '
				+ 'Entitlement__r.ServicePartsDiscountCovered__c, '
				+ 'Entitlement__r.ConsumableDiscountCovered__c, '
				+ 'CoveredProduct__c, CoveredProduct__r.AssetId, '
				+ 'CoveredProduct__r.Asset.Product2Id, '
				+ 'CoveredProduct__r.Asset.LocationId, '
				+ 'CoveredProduct__r.Asset.Location.Account__c, '
				+ 'CoveredProduct__r.Asset.Location.Account__r.Name, '
				+ 'CoveredProduct__r.Asset.Location.ShipTo__c, '
				+ 'CoveredProduct__r.Asset.Location.BillTo__c, '
				+ 'CoveredProduct__r.Asset.Location.Payer__c, '
				+ 'CoveredProduct__r.Asset.ContactId, '
				+ 'CoveredProduct__r.Asset.Technical_ID_Number__c, '
				+ 'CoveredProduct__r.Asset.Building__c, '
				+ 'CoveredProduct__r.Asset.Room__c, '
				+ 'CoveredProduct__r.Asset.Preferred_Technician__c, '
				// 8/26/21 Tony ITSVMX-580: Added the From address fields that are required when RMAs are auto-created
				+ 'CoveredProduct__r.Asset.Street, '
				+ 'CoveredProduct__r.Asset.City, '
				+ 'CoveredProduct__r.Asset.PostalCode '
				+ 'FROM FS_EntitlementDate__c WHERE ServiceOrderNumber__c = NULL'
				+ ' AND SAP_Notification_ID__c = NULL'
				+ ' AND WorkOrder__c = NULL'
				+ ' AND PlannedDate__c < :END_DATE'
				+ ' AND IsDeleted__c = FALSE';

		if (START_DATE != null)
		{
			query += ' AND PlannedDate__c >= :START_DATE';
		}
		// SVMXCFG-605: Batch Jobs - i18n Parameters
		if (SALES_ORGS != null && !SALES_ORGS.isEmpty())
		{
			//query += ' AND CoveredProduct__r.Asset.SVMXC__Site__r.SalesOrg__c IN :SALES_ORGS';
			query += ' AND ContractItem__r.ParentServiceContract.SalesOrg__c IN :SALES_ORGS';
		}
		if (PARENT_CONTRACT_ID != null)
		{
			query += ' AND ContractItem__r.ParentServiceContractId = :PARENT_CONTRACT_ID';
		}
		if (CONTRACT_ITEM_ID != null)
		{
			query += ' AND ContractItem__c = :CONTRACT_ITEM_ID';
		}
		System.debug('SCHEDULED WO QUERY = ' + query);
		System.debug('SCHEDULED WO QUERY VALUES = ' + this);

		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<FS_EntitlementDate__c> entDateList)
	{
		//RecordType fieldServiceRT = Utility.getRecTypeDevNameMap('WorkOrder').get('Field_Service');

		//ITSVMX-435 5/21/21 Update PM Scheduled Batch Job to Create Depot Work Order
//		Group unassignedDepotQueue = [
//				SELECT Id, DeveloperName, Type
//				FROM Group
//				WHERE Type = 'Queue'
//				AND DeveloperName = 'Unassigned_Depot_PMs' LIMIT 1
//		];
		Id unassignedDepotQueueId = null; //unassignedDepotQueue.Id;
		System.debug('unassignedDepotQueueId: ' + unassignedDepotQueueId);

		List<WorkOrder> woList = new List<WorkOrder>();

		for (FS_EntitlementDate__c ed : entDateList) {
			Asset ip = ed.CoveredProduct__r.Asset;

			WorkOrder wo = new WorkOrder();
			wo.Record_Type__c = 'Field Service';
			wo.Status = 'Initializing';
			wo.Billing_Type__c = 'Contract';
			wo.Order_Type__c = ed.Entitlement__r.EntitlementTypeName__c;
			if (String.isBlank(wo.Order_Type__c))
			{
				// SVMXCFG-999 Scheduled WO - Do not create without Order Type
				wo.addError('Cannot create a Work Order without an Order Type.');
				woList.add(wo);
				continue;
			}

			if (ed.ContractItem__r.ParentServiceContract.Active__c == false)
			{
				// SVMXCFG-1005 Scheduled Work Orders & "Credit Okay"
				wo.addError('Cannot create a Work Order when Service Contract is on Credit Hold.');
				woList.add(wo);
				continue;
			}

			wo.Priority = '3'; // Service Medium

			// 9/23/21 Tony ITSVMX-612 SMAX Scheduled Work Orders AMERICAS Core batch job failing with Attempt to de-reference a null object
			//if (ip.SVMXC__Site__c == null || ip.Location.SVMXC__Account__c == null)
			if (ip == null || ip.LocationId == null || ip.Location.Account__c == null)
			{
				// SVMXCFG-699 Scheduled WO - Do not create without related data
				wo.addError('Cannot create a Work Order without an IP or with an IP that does not have a Location or Account.');
				woList.add(wo);
				continue;
			}

			// Accounts / Master Data
			wo.AccountId = ip.Location.Account__c;
			wo.ShipTo__c = ip.Location.ShipTo__c;
			wo.BillTo__c = ip.Location.BillTo__c;
			wo.Payer__c = ip.Location.Payer__c;
			// QUESTION: Should we instead use the ContractItem fields for ShipTo, BillTo, SoldTo, Payer?
			wo.LocationId = ip.LocationId;
			wo.Product__c = ip.Product2Id;
			wo.AssetId = ed.CoveredProduct__r.AssetId;
			//wo.SVMXC__Contact__c = ip.SVMXC__Contact__c;
			wo.ContactId = ed.ContractItem__r.ParentServiceContract.ContactId;

			//wo.SVMXC__Scheduled_Date__c = ed.PlannedDate__c;
			// SVMXINT-562 Basic Start Date
			wo.Customer_Required_Start_Date__c = ed.PlannedDate__c;
			// ONLY run auto-assignment when WO Scheduled for 2+ weeks out
			wo.Perform_Auto_Assignment__c = (wo.Customer_Required_Start_Date__c >= Date.today().addDays(14));

			// Entitlement results
			wo.ServiceContractId = ed.ContractItem__r.ParentServiceContractId;
			wo.ContractItem__c = ed.ContractItem__c;
			wo.ContractEntitlement__c = ed.Entitlement__c;
			wo.CoveredProduct__c = ed.CoveredProduct__c;
			wo.Auto_Entitlement_Status__c = 'Success';
			wo.Entitlement_Type__c = 'SCHEDULED';
			wo.Is_Entitlement_Performed__c = true;
			wo.Entitlement_Notes__c = 'Scheduled Entitlement Completed and is Successful.';
			wo.Perform_Auto_Entitlement__c = false;

			// SVMXCFG-523: Problem Summary: MM/YYYY-Maintenance Activity Type-Technical ID-Building-Room
			Datetime entDate = Datetime.newInstance(ed.PlannedDate__c, Time.newInstance(0, 0, 0, 0));
			String ps = entDate.format('MM/yyyy') + '-' + ed.Entitlement__r.EntitlementType__c;
			if (String.isNotBlank(ip.Technical_ID_Number__c)) {
				ps += '-' + ip.Technical_ID_Number__c;
			}
			if (String.isNotBlank(ip.Building__c)) {
				ps += '-' + ip.Building__c;
			}
			if (String.isNotBlank(ip.Room__c)) {
				ps += '-' + ip.Room__c;
			}

			wo.Description = ps;
			wo.Problem_Summary__c = (ps.length() > 40) ? ps.substring(0, 37) + '...' : ps;

			// SVMXCFG-685 - Map other Service Contract fields to WO
			String slaTerms = ed.ContractItem__r.SLA_Terms_Notes__c;
			if (slaTerms != null && slaTerms.length() >= 255)
			{
				slaTerms = slaTerms.substring(0, 252) + '...';
			}
			wo.SLA_Terms_Notes__c = slaTerms;
			wo.IsEntitledWarranty__c = ed.ContractItem__r.fxIs_Warranty__c;
			//wo.Is_Enterprise__c = ed.ContractItem__r.fxIs_Enterprise__c;
			wo.Offline_Contract_Discounts__c = FS_AutoEntitlement.calculateOfflineDiscounts(wo, ed.Entitlement__r);

			// SVMXCFG-916 Copy Service Contract PO Number to WO
			wo.CustomerPO__c = ed.ContractItem__r.ParentServiceContract.PONumber__c;
			//wo.CustomerPODate__c = Date.today();

			//ITSVMX-435 5/21/21 Update PM Scheduled Batch Job to Create Depot Work Order
			String entitlementCondition = ed.EntitlementCondition__c;
			if (entitlementCondition != null && entitlementCondition == 'ZDPM') {
				System.debug('Creating a Depot Repair Work Order');
				wo.Record_Type__c = 'Depot';
				// 6/16/21 Tony - Updated to ignore the ip.SVMXC__Preferred_Technician__c per UAT meeting
				//if (ip.SVMXC__Preferred_Technician__c == null && unassignedDepotQueueId != null) {
				if (unassignedDepotQueueId != null) {
					wo.OwnerId = unassignedDepotQueueId;
				}

				// 8/26/21 Tony ITSVMX-580: Added the From address fields that are required when RMAs are auto-created
				wo.FromStreet1__c = ed.CoveredProduct__r.Asset.Street;
				wo.Source_City__c = ed.CoveredProduct__r.Asset.City;
				wo.Source_Zip__c = ed.CoveredProduct__r.Asset.PostalCode;
				wo.SourceName1__c = ip.Location.Account__r.Name;
				wo.SourceName2__c = ed.ContractItem__r.ParentServiceContract.Contact.FirstName
						+ ' ' + ed.ContractItem__r.ParentServiceContract.Contact.LastName;
			}

			woList.add(wo);
		}

//		List<ErrorLog__c> logs = new List<ErrorLog__c>();
		Database.SaveResult[] results = Database.insert(woList, false);
		for (Integer i = 0; i < results.size(); i++)
		{
			Database.SaveResult result = results[i];
			FS_EntitlementDate__c ed = entDateList[i];
			WorkOrder wo = woList[i];
			if (!result.isSuccess())
			{
				String errorMsg = 'Error inserting Work Order for Entitlement Date: ' + ed.Name + ' - ' + result.getErrors();
				System.debug('SCHED_WO: ' + errorMsg);
//				logs.add(LogUtility.createLog(LogUtility.ERROR, errorMsg, 'CreateScheduledWorkOrdersBatch', null, ed.Id));
				ed.Error_Message__c = errorMsg;
			}
			else
			{
				System.debug('SCHED_WO: Success creating Scheduled Work Order: ' + wo.Id);
				ed.WorkOrder__c = wo.Id;
			}
		}

		update entDateList;

//		if (!logs.isEmpty())
//			insert logs;
	}

	global void finish(Database.BatchableContext BC)
	{
	}

}