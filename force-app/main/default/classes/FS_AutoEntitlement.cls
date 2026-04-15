public with sharing class FS_AutoEntitlement {

	public class EntitlementWrapper implements Comparable
	{
		public String entType;
		public ContractLineItem cp;
		public List<FS_EntitlementDate__c> entitlementDates;
		public Entitlement ent;

		public EntitlementWrapper(ContractLineItem cp, Entitlement ent)
		{
			this.entType = ent.EntitlementType__c;
			this.cp = cp;
			this.ent = ent;

			this.entitlementDates = new List<FS_EntitlementDate__c>();
			try
			{
				if (cp.Entitlement_Dates__r != null)
				{
					for (FS_EntitlementDate__c ed : cp.Entitlement_Dates__r)
					{
						if (ed.Entitlement__c == ent.Id)
						{
							this.entitlementDates.add(ed);
						}
					}
				}
			}
			catch (Exception e1)
			{
				System.debug('!! Received Error trying to access "cp.Entitlement_Dates__r"... using direct SOQL Query: ' + e1);
				// We are receiving this error if more than 200 Entitlement Dates:
				/* FATAL_ERROR System.QueryException: Aggregate query has too many rows for direct assignment, use FOR loop */
				this.entitlementDates = [SELECT Id, CoveredProduct__c, Entitlement__c,
						IsDeleted__c, PlannedDate__c, ServiceOrderNumber__c,
						SAP_Notification_ID__c,WorkOrder__c
				FROM FS_EntitlementDate__c
				WHERE CoveredProduct__c = :cp.Id AND Entitlement__c = :ent.Id
				AND IsDeleted__c = FALSE
				ORDER BY PlannedDate__c];
			}

		}

		// Compare CP/Entitlement based on various factors...
		public Integer compareTo(Object compareTo) {
			// Cast argument to EntitlementWrapper
			EntitlementWrapper that = (EntitlementWrapper)compareTo;
			Integer returnValue = 0;
			// SVMXCFG-525: Multiple CPs: Try to find exact match first, then ZZZ
			if (this.entType != that.entType)
			{
				returnValue = (this.entType == DEFAULT_ENTITLEMENT_TYPE) ? 1 : -1;
			}
			// SVMXCFG-525: Auto-Entitlement - Sort by NumberOfEntitlementDates (to ensure ones with ED are processed before those without)
			// SVMXCFG-1162 Only count the "non-consumed" Entitlement Dates
			else if (this.countAvailableEntDates() != that.countAvailableEntDates())
			{
				returnValue = (this.countAvailableEntDates() < that.countAvailableEntDates()) ? 1 : -1;
			}
			// SVMXCFG-700 Select highest total coverage item
			else if (this.ent.fxTotal_Coverage__c != that.ent.fxTotal_Coverage__c)
			{
				returnValue = (this.ent.fxTotal_Coverage__c < that.ent.fxTotal_Coverage__c) ? 1 : -1;
			}
			return returnValue;
		}

		private Integer availableDateCount = null;
		public Integer countAvailableEntDates()
		{
			if (this.availableDateCount != null) {
				return this.availableDateCount;
			}

			Integer result = 0;
			for (FS_EntitlementDate__c ed : this.entitlementDates)
			{
				if (ed != null && ed.ServiceOrderNumber__c == null && ed.SAP_Notification_ID__c == null && ed.WorkOrder__c == null)
				{
					result++;
				}
			}
			this.availableDateCount = result;
			return result;
		}
	}

	private static Set<String> ENT_BILLING_TYPES = new Set<String> { 'Contract' };
	private static String DEFAULT_ENTITLEMENT_TYPE = 'ZZZ';

	public static void completeEntitlement(List<WorkOrder> wos, Map<Id, WorkOrder> oldMap)
	{
		if (!FS_Utility.isActive('WO Complete Entitlement', 'Complete the Entitlement on the WO based on the Contract Item assigned in SAP'))
		{  return;  }

		List<WorkOrder> wosToCheck = new List<WorkOrder>();
		List<WorkOrder> wosToUpdate = new List<WorkOrder>();
		List<FS_EntitlementDate__c> edsToUpdate = new List<FS_EntitlementDate__c>();
		//Map<Id, List<CoveredProductWrapper>> ipCpMap = new Map<Id, List<CoveredProductWrapper>>();
		Map<Id, List<ContractLineItem>> ipCpMap = new Map<Id, List<ContractLineItem>>();
		Map<Id, Map<String, Entitlement>> itemEntMap = new Map<Id, Map<String, Entitlement>>();
		Map<Id, Id> contrItemParentContract = new Map<Id, Id>();
		Set<Id> ContractItemIDs = new Set<Id>();
		Set<Id> IBIds = new Set<Id>();
		List<Date> scheduledDates = new List<Date>();
		for (WorkOrder wo : wos)
		{
			//WorkOrder old = (oldMap == null) ? null : oldMap.get(wo.Id);
			if (wo.Is_Entitlement_Performed__c == false
					&& wo.ServiceContractId != null && wo.ContractItem__c != null
					&& wo.ContractEntitlement__c == null && wo.CoveredProduct__c == null)
			{
				System.debug('COMPLETE-ENTITLE Running on WO: ' + wo);
				wosToCheck.add(wo);
				IBIds.add(wo.AssetId);
				ContractItemIDs.add(wo.ContractItem__c);
				// SVMXCFG-884 Update Auto-ContractItem__c to use Customer Required Start Date
				Date entDate = getEntitlementDate(wo);
				scheduledDates.add(entDate);
				// Auto-Entitlement Notes [SVMXCFG-465]
				wo.Entitlement_Notes__c = '* WO Complete-Entitlement Running...';
			} else {
				System.debug('COMPLETE-ENTITLE NOT-Running on WO: ' + wo);
			}
		}

		if(wosToCheck.isEmpty()) {
			return;
		}

		//Sort the List of Date
		scheduledDates.sort();
//    Date startDate = scheduledDates.get(0);
//    Date endDate = scheduledDates.get(scheduledDates.size() - 1);

		//Map of Installed Products and their Covered Products
		//Load the covered products contract items such that we can get the Entitlements
		for(ContractLineItem cp : [SELECT Id, AssetId,
				ServiceContract.Id, ServiceContract.fxIs_Warranty__c,
				ServiceContract.SLA_Terms_Notes__c, ServiceContract.ParentServiceContractId,
				//ServiceContract.fxIs_Enterprise__c,
				//SVMXC__Service_Contract__r.SVMX_PS_Parent_Contract__r.SMAX_PS_ContractType__c,
				StartDate, EndDate, LineItemNumber,
				(SELECT Id, CoveredProduct__c,
					Entitlement__c,
					IsDeleted__c,
					PlannedDate__c,
					ServiceOrderNumber__c,
					SAP_Notification_ID__c,
					WorkOrder__c
				FROM Entitlement_Dates__r WHERE IsDeleted__c = FALSE ORDER BY PlannedDate__c)
			FROM ContractLineItem
			WHERE AssetId IN :IBIds AND ServiceContractId IN :ContractItemIDs AND IsDeleted__c = FALSE])
		//AND SMAX_PS_Active__c = true
		//AND SVMXC__Start_Date__c <= :startDate
		//AND SVMXC__End_Date__c >= :endDate
		{
			if (!ipCpMap.containsKey(cp.AssetId)) {
				ipCpMap.put(cp.AssetId, new List<ContractLineItem>());
			}
			//CoveredProductWrapper cpWrap = new CoveredProductWrapper(cp, cp.Entitlement_Dates__r);
			ipCpMap.get(cp.AssetId).add(cp);
			//ContractItemIDs.add(cp.SVMXC__Service_Contract__r.Id);
			if(!contrItemParentContract.containsKey(cp.ServiceContract.Id)) {
				contrItemParentContract.put(cp.ServiceContract.Id, cp.ServiceContract.ParentServiceContractId);
			}
		}

		//If IPCP Map is Empty - bail out.
		if(!ipCpMap.isEmpty())
		{
			//Map of Contract Items and their Entitlements
			for(Entitlement ent : [SELECT Id, Name,
					EntitlementType__c,
					EntitledQty__c,
					EntitledQtyRemaining__c,
					ServiceContractId,
					Labor_Discount_Covered__c,
					Travel_Discount_Covered__c,
					Parts_Discount_Covered__c,
					ServicePartsDiscountCovered__c,
					ConsumableDiscountCovered__c,
					fxTotal_Coverage__c
			FROM Entitlement
			WHERE ServiceContractId IN: ContractItemIDs
			AND IsDeleted__c = FALSE])
			{
				if (!itemEntMap.containsKey(ent.ServiceContractId)) {
					itemEntMap.put(ent.ServiceContractId, new Map<String, Entitlement>());
				}
				itemEntMap.get(ent.ServiceContractId).put(ent.EntitlementType__c, ent);
			}
		}

		//Now the main logic
		for(WorkOrder wo :  wosToCheck)
		{
			Boolean woEntitled = false;

			//Get the Covered Product Entry for this WO
			List<ContractLineItem> cpList = ipCpMap.get(wo.AssetId);
			if (cpList == null)
			{
				cpList = new List<ContractLineItem>();
				wo.Entitlement_Notes__c += '\n No Covered Products found.';
			}

			wo.Entitlement_Notes__c += '\n Finding Entitlements matching: ' + wo.SAP_ActivityType__c;
			List<EntitlementWrapper> entOptions = getEntitlementOptions(wo.SAP_ActivityType__c, cpList, itemEntMap, true);
			for (EntitlementWrapper entWrap : entOptions)
			{
				ContractLineItem cp = entWrap.cp;
				// NOTE: Do not check entitlement date for "complete".. already entitled, no need to validate

				String entitlementType = entWrap.entType;
				//Get the id from the Contract Item
				Id contractItemId = cp.ServiceContract.Id;
				if (wo.ContractItem__c != contractItemId) {
					continue;
				}

				wo.Entitlement_Notes__c += '\n Trying to entitle to CP: ' + cp.LineItemNumber + ' for Entitlement Type: ' + entitlementType;
				List<FS_EntitlementDate__c> eDates = entWrap.entitlementDates;

				Entitlement ent = entWrap.ent;
				if (ent != null)
				{
					woEntitled = isEntitled(wo, ent, eDates, edsToUpdate);
					if (woEntitled == false) {
						ent = null;
					}
				}

				if(woEntitled)
				{
					//wo.SVMXC__Service_Contract__c = contrItemParentContract.get(contractItemId);
					//wo.SMAX_PS_ContractItem__c = contractItemId;
					wo.ContractEntitlement__c = ent.Id;
					wo.CoveredProduct__c = cp.Id;
					wo.Auto_Entitlement_Status__c = 'Success';
					wo.Entitlement_Type__c = 'SAP';
					wo.Is_Entitlement_Performed__c = true;
					wo.Entitlement_Notes__c += '\n Complete Entitlement was Successful.';
					if (wo.Entitlement_Notes__c.length() >= 32000)
					{
						wo.Entitlement_Notes__c = wo.Entitlement_Notes__c.substring(0, 32000) + '...';
					}
					wo.Perform_Auto_Entitlement__c = false;
					String slaTerms = cp.ServiceContract.SLA_Terms_Notes__c;
					if (slaTerms != null && slaTerms.length() >= 255)
					{
						slaTerms = slaTerms.substring(0, 252) + '...';
					}
					wo.SLA_Terms_Notes__c = slaTerms;
					// SVMXCFG-549 : Map new IsEnteprise and IsWarranty fields
					wo.IsEntitledWarranty__c = cp.ServiceContract.fxIs_Warranty__c;
					//wo.Is_Enterprise__c = cp.ServiceContract.fxIs_Enterprise__c;

					// SVMXCFG-574 Off-Line Price Fields - To support Offline Contract Discounts
					wo.Offline_Contract_Discounts__c = calculateOfflineDiscounts(wo, ent);

					// SVMXCFG-916 Copy Service Contract PO Number to WO - We should not do this here, for WO Load

					wosToUpdate.add(wo);
					break; // Stop looping over the CPs.. found a match.
				}
			}

			if (!woEntitled)
			{
				// FOR COMPLETE-ENTITLEMENT ... don't want to "fail"
				wo.Auto_Entitlement_Status__c = 'Failed';
				wo.Entitlement_Type__c = 'SAP';
				wo.Is_Entitlement_Performed__c = true;
				wo.Entitlement_Notes__c += '\n Complete Entitlement was NOT Successful.';
				wo.Perform_Auto_Entitlement__c = false;
			}
		}

		if (!edsToUpdate.isEmpty()) {
			update edsToUpdate;
		}

		// NOTE: No need to update "wosToUpdate".. this is invoked in "before update"

	}


	public static String calculateOfflineDiscounts(WorkOrder wo, Entitlement ent)
	{
		/*
		{ "Labor":100.0, "Travel":90.0, "Parts":80.0, "Other Parts":80.0, "Service Parts":70.0, "Consumable":60.0}
		*/
		wo.Offline_Contract_Discount_Labor__c = ent.Labor_Discount_Covered__c == null ? 0 : ent.Labor_Discount_Covered__c;
		wo.Offline_Contract_Discount_Travel__c = ent.Travel_Discount_Covered__c == null ? 0 : ent.Travel_Discount_Covered__c;
		wo.Offline_Contract_Discount_Parts__c = ent.Parts_Discount_Covered__c == null ? 0 : ent.Parts_Discount_Covered__c;
		wo.Offline_Contract_Discount_ServiceParts__c = ent.ServicePartsDiscountCovered__c == null ? 0 : ent.ServicePartsDiscountCovered__c;
		wo.Offline_Contract_Discount_Consumable__c = ent.ConsumableDiscountCovered__c == null ? 0 : ent.ConsumableDiscountCovered__c;

		JSONGenerator gen = JSON.createGenerator(false);
		gen.writeStartObject();
		gen.writeNumberField('Labor', wo.Offline_Contract_Discount_Labor__c);
		gen.writeNumberField('Travel', wo.Offline_Contract_Discount_Travel__c);
		gen.writeNumberField('Parts', wo.Offline_Contract_Discount_Parts__c);
		gen.writeNumberField('Other Parts', wo.Offline_Contract_Discount_Parts__c);
		gen.writeNumberField('Service Parts', wo.Offline_Contract_Discount_ServiceParts__c);
		gen.writeNumberField('Consumable', wo.Offline_Contract_Discount_Consumable__c);
		gen.writeEndObject();

		return gen.getAsString();
	}

	// SVMXCFG-884 Update Auto-Entitlement to use Customer Required Start Date
	private static Date getEntitlementDate(WorkOrder wo)
	{
		// Use Today if no ScheduledDate populated (below also)
		if (wo.Scheduled_Date_Time__c == null) {
			wo.Scheduled_Date_Time__c = Date.today();
		}

		return (wo.Customer_Required_Start_Date__c != null) ?
				wo.Customer_Required_Start_Date__c : wo.Scheduled_Date_Time__c.date();
	}

	private static Boolean isEntitled(WorkOrder wo, Entitlement ent, List<FS_EntitlementDate__c> eDates, List<FS_EntitlementDate__c> edsToUpdate)
	{
		wo.Entitlement_Notes__c += '\n Checking Entitlement: ' + ent.Name + ' (' + ent.EntitlementType__c + ')';
		Boolean woEntitled = false;

		// ITSFDC-1047 For "REMOTE" also ensure Hours remain in the Block ...
//		RecordType remoteRT = FS_Utility.getRecordType('WorkOrder', 'Remote');
//		Boolean isRemoteWO = (wo.RecordTypeId == remoteRT.Id);
//		Boolean isRemoteEnt = (ent.EntitledQtyRemaining__c != null);
//		if (isRemoteWO && isRemoteEnt)
//		{
//			if (ent.EntitledQtyRemaining__c > 0)
//			{
//				woEntitled = true;
//				System.debug('AUTO-ENTITLE Matching to Entitlement for Block of Hours: ' + ent);
//				wo.Entitlement_Notes__c += '\n Matching to Entitlement of Remote Hours: ' + ent.Name + ' [' + ent.EntitledQtyRemaining__c + ' Hours Remaining]';
//			}
//			else
//			{
//				woEntitled = false;
//				System.debug('AUTO-ENTITLE NOT Matching to Entitlement of Remote Hours: ' + ent);
//				wo.Entitlement_Notes__c += '\n NOT Matching to Entitlement of Remote Hours [NO HOURS REMAINING]: ' + ent.Name;
//			}
//			return woEntitled;
//		}
//		else if (isRemoteWO || isRemoteEnt)
//		{
//			// Mis-match between WO & Entitlement (Remote vs Field Service)
//			woEntitled = false;
//			wo.Entitlement_Notes__c += '\n NOT Matching to Entitlement of Remote Hours [Remote/Field mismatch]: ' + ent.Name;
//			return woEntitled;
//		}

		if (!woEntitled && eDates != null && !eDates.isEmpty())
		{
			//Get the first Entitlement Date that does not have a WO Number
			for(FS_EntitlementDate__c ed : eDates)
			{
				if (ed.Entitlement__c == ent.Id)
				{
					wo.Entitlement_Notes__c += '\n Checking EntitlementDate: ' + ed.PlannedDate__c;
					if (ed.ServiceOrderNumber__c == null && ed.SAP_Notification_ID__c == null && ed.WorkOrder__c == null)
					{
						woEntitled = true;
						wo.Entitlement_Notes__c += '\n Non-Consumed EntitlementDate Matched: ' + ed.PlannedDate__c;
						break;
					}
					else if (wo.External_ID__c != null && ed.ServiceOrderNumber__c != null)
					{
						String formatted = '00000000000' + ed.ServiceOrderNumber__c;
						formatted = formatted.substring(formatted.length()-12);
						String soNumber = wo.External_ID__c;
						if (soNumber != null && soNumber.equals(formatted))
						{
							// Found a match for a SAP Service Order Number ... WO Loads
							woEntitled = true;
							//System.debug('AUTO-ENTITLE Existing EntitlementDate mapping found: ' + ed);
							wo.Entitlement_Notes__c += '\n Pre-Consumed EntitlementDate Matched: ' + ed.PlannedDate__c;
							break;
						}
					}
				}
			}

			if (woEntitled == false) {
				System.debug('AUTO-ENTITLE No Matching EntitlementDate found..');
			}
		}

		//Are there quantities available on the Entitlment? (NOTE: 0/0 will be entitled)
		if(!woEntitled &&
				ent.EntitledQty__c != null && ent.EntitledQtyRemaining__c != null
				&& (ent.EntitledQtyRemaining__c > 0 || ent.EntitledQty__c == 0))
		{
			woEntitled = true;
			System.debug('AUTO-ENTITLE Matching to Entitlement by Qty: ' + ent);
			wo.Entitlement_Notes__c += '\n Matching to Entitlement by Qty: ' + ent.Name;
		}

		return woEntitled;
	}


	private static List<EntitlementWrapper> getEntitlementOptions(String entType, List<ContractLineItem> cpList, Map<Id, Map<String, Entitlement>> itemEntMap, Boolean allowDefaultEntType)
	{
		List<EntitlementWrapper> result = new List<EntitlementWrapper>();

		// SVMXCFG-525: Multiple CPs: Try to find exact match first, then ZZZ
		List<String> entTypes = new List<String> { entType };
		if (allowDefaultEntType == true) {
			entTypes.add(DEFAULT_ENTITLEMENT_TYPE);
		}

		for (String entitlementType : entTypes)
		{
			for(ContractLineItem cp : cpList)
			{
				//Get the id from the Contract Item
				Id contractItemId = cp.ServiceContract.Id;

				//Load the list of "Entitlements"
				Map<String, Entitlement> entMap = itemEntMap.get(contractItemId);
				Entitlement ent = (entMap == null) ? null : entMap.get(entitlementType);
				if (ent != null)
				{
					EntitlementWrapper entWrap = new EntitlementWrapper(cp, ent);
					result.add(entWrap);
				}
				//else
				//{
				//  wo.SVMXC__Entitlement_Notes__c += '\n No Entitlement Found matching: ' + entitlementType;
				//}
			}
		}

		result.sort();
		return result;
	}

	public static void performAutoEntitlementCheck(List<WorkOrder> wos, Map<Id, WorkOrder> oldMap)
	{
		if (!FS_Utility.isActive('WO Entitlement Check', 'Perform a Auto-Entitlement check on the WO based on the IP, Order Type and Scheduled Date'))
		{  return;  }

		//RecordType remoteRT = SMAX_PS_Utility.getRecordType('WorkOrder', 'Remote');

		List<WorkOrder> wosToCheck = new List<WorkOrder>();
		List<WorkOrder> wosToUpdate = new List<WorkOrder>();
		List<FS_EntitlementDate__c> edsToUpdate = new List<FS_EntitlementDate__c>();
		//Map<Id, List<CoveredProductWrapper>> ipCpMap = new Map<Id, List<CoveredProductWrapper>>();
		Map<Id, List<ContractLineItem>> ipCpMap = new Map<Id, List<ContractLineItem>>();
		Map<Id, Map<String, Entitlement>> itemEntMap = new Map<Id, Map<String, Entitlement>>();
		Map<Id, Id> contrItemParentContract = new Map<Id, Id>();
		Set<Id> ContractItemIDs = new Set<Id>();
		Set<Id> IBIds = new Set<Id>();
		List<Date> scheduledDates = new List<Date>();
		for (WorkOrder wo : wos)
		{
			Boolean readyForCheck = false;
			//Check if update
			WorkOrder old = (oldMap == null) ? null : oldMap.get(wo.Id);
			if(old == null && (wo.Perform_Auto_Entitlement__c == true
					&& ENT_BILLING_TYPES.contains(wo.Billing_Type__c) ) ) {
				readyForCheck = true;
			}
			else if (old == null && wo.Record_Type__c =='Remote' && wo.AssetId != null) {
				// ITSFDC-1047 Remote Support Hour Blocks
				readyForCheck = true;
			}
			if(old != null && (wo.AssetId != old.AssetId
					|| wo.Billing_Type__c != old.Billing_Type__c
					|| wo.SAP_ActivityType__c != old.SAP_ActivityType__c
					|| (wo.Perform_Auto_Entitlement__c != old.Perform_Auto_Entitlement__c && wo.Perform_Auto_Entitlement__c == true)
			) && (wo.Perform_Auto_Entitlement__c == true || wo.Is_Entitlement_Performed__c == true)
					&& ENT_BILLING_TYPES.contains(wo.Billing_Type__c) ) {
				readyForCheck = true;
			}

			// 6/15/2020 Tony - ITSVMX-49 - RWO without IP should not go through entitlement check
			// if(readyForCheck){
			// 6/1/2021 ITSVMX-307 - Canceled WOs should not go through entitlement check
			//if(readyForCheck && wo.SVMXC__Component__c != null){
			if(readyForCheck && wo.AssetId != null && wo.Status != 'Canceled'){
				System.debug('AUTO-ENTITLE Running on WO: ' + wo);
				wosToCheck.add(wo);
				IBIds.add(wo.AssetId);
				// SVMXCFG-884 Update Auto-Entitlement to use Customer Required Start Date
				Date entDate = getEntitlementDate(wo);
				scheduledDates.add(entDate);
				// Auto-Entitlement Notes [SVMXCFG-465]
				wo.Entitlement_Notes__c = '* WO Auto-Entitlement Running...';
			} else {
				System.debug('AUTO-ENTITLE NOT-Running on WO: ' + wo);
			}
		}

		if(wosToCheck.isEmpty()) {
			return;
		}

		//Sort the List of Date
		scheduledDates.sort();
		Date startDate = scheduledDates.get(0);
		Date endDate = scheduledDates.get(scheduledDates.size() - 1);

		//Map of Installed Products and their Covered Products
		//Load the covered products contract items such that we can get the Entitlements
		for(ContractLineItem cp : [SELECT Id, LineItemNumber, AssetId,
				ServiceContract.Id,
				ServiceContract.fxIs_Warranty__c, ServiceContract.SLA_Terms_Notes__c,
				ServiceContract.ParentServiceContractId, ServiceContract.ParentServiceContract.PONumber__c,
				//ServiceContract.fxIs_Enterprise__c,
				//SVMXC__Service_Contract__r.SVMX_PS_Parent_Contract__r.SMAX_PS_ContractType__c,
				StartDate, EndDate,
				(SELECT Id, CoveredProduct__c, Entitlement__c, IsDeleted__c, PlannedDate__c,
					ServiceOrderNumber__c, SAP_Notification_ID__c, WorkOrder__c
					FROM Entitlement_Dates__r WHERE IsDeleted__c = FALSE ORDER BY PlannedDate__c)
			FROM ContractLineItem
			WHERE AssetId IN :IBIds AND fxActive__c = TRUE AND StartDate <= :startDate AND EndDate >= :endDate
				AND IsDeleted__c = FALSE])
		{
			if (!ipCpMap.containsKey(cp.AssetId)) {
				ipCpMap.put(cp.AssetId, new List<ContractLineItem>());
			}
			//CoveredProductWrapper cpWrap = new CoveredProductWrapper(cp, cp.Entitlement_Dates__r);
			ipCpMap.get(cp.AssetId).add(cp);
			ContractItemIDs.add(cp.ServiceContract.Id);
			if(!contrItemParentContract.containsKey(cp.ServiceContract.Id)) {
				contrItemParentContract.put(cp.ServiceContract.Id, cp.ServiceContract.ParentServiceContractId);
			}
		}

		//If IPCP Map is Empty - bail out.
		if(!ipCpMap.isEmpty())
		{
			//Map of Contract Items and their Entitlements
			for(Entitlement ent : [SELECT Id, Name,
					EntitlementType__c,
					EntitledQty__c,
					EntitledQtyRemaining__c,
					ServiceContractId,
					Labor_Discount_Covered__c,
					Travel_Discount_Covered__c,
					Parts_Discount_Covered__c,
					ServicePartsDiscountCovered__c,
					ConsumableDiscountCovered__c,
					fxTotal_Coverage__c
			FROM Entitlement
			WHERE ServiceContractId IN: ContractItemIDs
			AND IsDeleted__c = FALSE])
			{
				if (!itemEntMap.containsKey(ent.ServiceContractId)) {
					itemEntMap.put(ent.ServiceContractId, new Map<String, Entitlement>());
				}
				itemEntMap.get(ent.ServiceContractId).put(ent.EntitlementType__c, ent);
			}
		}

		//Now the main logic
		for(WorkOrder wo :  wosToCheck)
		{
			Boolean woEntitled = false;

			//Get the Covered Product Entry for this WO
			List<ContractLineItem> cpList = ipCpMap.get(wo.AssetId);
			if (cpList == null)
			{
				cpList = new List<ContractLineItem>();
				wo.Entitlement_Notes__c += '\n No Covered Products found.';
			}

			// ITSFDC-1047 ONLY lookup Ent Options for "PHN" (and not "ZZZ")
			String entType = wo.SAP_ActivityType__c;
			Boolean isRemote = false; // (wo.Record_Type__c == 'Remote');

			wo.Entitlement_Notes__c += '\n Finding Entitlements matching: ' + entType;
			List<EntitlementWrapper> entOptions = getEntitlementOptions(entType, cpList, itemEntMap, !isRemote);
			for (EntitlementWrapper entWrap : entOptions)
			{
				ContractLineItem cp = entWrap.cp;
				// SVMXCFG-884 Update Auto-Entitlement to use Customer Required Start Date
				Date entDate = getEntitlementDate(wo);
				if (entDate < cp.StartDate || entDate > cp.EndDate)
				{
					wo.Entitlement_Notes__c += '\n Skipping CP due to coverage dates: ' + cp.LineItemNumber;
					continue;
				}

				String entitlementType = entWrap.entType;
				wo.Entitlement_Notes__c += '\n Trying to entitle to CP: ' + cp.LineItemNumber + ' for Entitlement Type: ' + entitlementType;
				//Get the id from the Contract Item
				Id contractItemId = cp.ServiceContract.Id;
				List<FS_EntitlementDate__c> eDates = entWrap.entitlementDates;

				Entitlement ent = entWrap.ent;
				if (ent != null)
				{
					woEntitled = isEntitled(wo, ent, eDates, edsToUpdate);
					if (woEntitled == false) {
						ent = null;
					}
				}

				if(woEntitled)
				{
					wo.ServiceContractID = contrItemParentContract.get(contractItemId);
					wo.ContractItem__c = contractItemId;
					wo.ContractEntitlement__c = ent.Id;
					wo.CoveredProduct__c = cp.Id;
					wo.Auto_Entitlement_Status__c = 'Success';
					wo.Entitlement_Type__c = 'AUTO';
					wo.Is_Entitlement_Performed__c = true;
					wo.Entitlement_Notes__c += '\n Auto Entitlement Completed and is Successful.';
					if (wo.Entitlement_Notes__c.length() >= 32000)
					{
						wo.Entitlement_Notes__c = wo.Entitlement_Notes__c.substring(0, 31995) + '...';
					}
					wo.Perform_Auto_Entitlement__c = false;
					wo.Billing_Type__c = 'Contract';
					String slaTerms = cp.ServiceContract.SLA_Terms_Notes__c;
					if (slaTerms != null && slaTerms.length() >= 255)
					{
						slaTerms = slaTerms.substring(0, 252) + '...';
					}
					wo.SLA_Terms_Notes__c = slaTerms;
					// SVMXCFG-549 : Map new IsEnteprise and IsWarranty fields
					wo.IsEntitledWarranty__c = cp.ServiceContract.fxIs_Warranty__c;
					//wo.Is_Enterprise__c = cp.ServiceContract.fxIs_Enterprise__c;

					// SVMXCFG-574 Off-Line Price Fields - To support Offline Contract Discounts
					wo.Offline_Contract_Discounts__c = calculateOfflineDiscounts(wo, ent);

					// SVMXCFG-916 Copy Service Contract PO Number to WO
					if (wo.CustomerPO__c == null)
					{
						wo.CustomerPO__c = cp.ServiceContract.ParentServiceContract.PONumber__c;
					}

					// ITSFDC-1047 Change "Remote" WO Status to ensure it is sent to SAP
					if (isRemote) {
						// NOTE: We could change to "Field_Service" RecordType as well, but more "correct" to leave as "Remote"
						wo.Status = 'Initializing';
						wo.Is_Remote_Support_Hours__c = true;
					}

					// NOTE: Whenever the above mappings change, also change "completeEntitlement" below AND SMAX_PS_CreateScheduledWorkOrdersBatch

					wosToUpdate.add(wo);
					break; // Stop looping over the CPs.. found a match.
				}
			}

			// ITSFDC-1047 Do NOT error-out "Remote" Work Orders
			if ((!woEntitled) && (!isRemote))
			{
				// FRANK 20171213 - PKI decided to cause this txn to fail when not entitled instead
				wo.Order_Type__c = null;
				wo.Billing_Type__c = 'Billable';
				wo.addError('Contract Entitlement failed. Please select a Billing Type of "Billable" or a different Order Type.');

				// None of the CPs were a match..
				//wo.SVMXC__Service_Contract__c = null;
				//wo.SMAX_PS_ContractItem__c = null;
				//wo.SMAX_PS_ContractEntitlement__c = null;
				//wo.SMAX_PS_CoveredProduct__c = null;
				//wo.SVMXC__Auto_Entitlement_Status__c = 'Failed';
				//wo.SVMXC__Entitlement_Type__c = 'AUTO';
				//wo.SVMXC__Is_Entitlement_Performed__c = TRUE;
				//wo.SVMXC__Entitlement_Notes__c = 'Auto Entitlement Failed.';
				//wo.SVMXC__Perform_Auto_Entitlement__c = FALSE;
				//wo.SVMXC__Billing_Type__c = 'Billable';
				//wosToUpdate.add(wo);
			} else if ((!woEntitled) && isRemote) {
				// Blank out the Remote WO Billing Type if failed entitlement
				wo.Billing_Type__c = null;
			}
		}

		if (!edsToUpdate.isEmpty()) {
			update edsToUpdate;
		}

		// NOTE: No need to update "wosToUpdate".. this is invoked in "before update"

	}

	public static void syncIsBillable(List<WorkOrder> wos, Map<Id, WorkOrder> oldMap)
	{
		if (!FS_Utility.isActive('Sync Is Billable', 'Copy the Is Billable flag from the Entitled Contract Item to the WO'))
		{  return;  }

		Set<Id> itemIds = new Set<Id>();
		List<WorkOrder> wosToCheck = new List<WorkOrder>();
		for (WorkOrder wo : wos)
		{
			WorkOrder old = (oldMap == null) ? null : oldMap.get(wo.Id);
			if (wo.Billing_Type__c == 'Billable') {
				wo.Is_Billable__c = true;
			}
			else if (wo.ContractItem__c != null
					&& (old == null || (old != null && wo.ContractItem__c != old.ContractItem__c))) {
				itemIds.add(wo.ContractItem__c);
				wosToCheck.add(wo);
			}
		}

		if (itemIds.isEmpty()) {
			return;
		}

		Map<Id, ServiceContract> itemMap = new Map<Id, ServiceContract>(
				[SELECT Id, Is_Billable__c FROM ServiceContract WHERE Id IN :itemIds]);
		for (WorkOrder wo : wosToCheck)
		{
			ServiceContract item = itemMap.get(wo.ContractItem__c);
			if (item != null) {
				wo.Is_Billable__c = item.Is_Billable__c;
			}
		}
	}


}