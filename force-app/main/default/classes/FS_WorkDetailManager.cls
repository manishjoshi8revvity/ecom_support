public without sharing class FS_WorkDetailManager {
	private FS_WorkDetailManager() {
	}
	public static void addWorkSummary(List<WorkOrderLineItem> wdList)
	{
		//Map<String,SMAX_PS_HSN_Code_Setting__c> hsncodeIndia = SMAX_PS_HSN_Code_Setting__c.getAll();

		for(WorkOrderLineItem wd:wdList)
		{
			if (wd.Work_Description__c != null)
			{
				String wdSum = (wd.Work_Description__c.length() > 40) ?
						wd.Work_Description__c.substring(0,40) : wd.Work_Description__c;
				wd.WorkSummary__c = wdSum;
			}
			if (wd.CurrencyIsoCode =='INR' && wd.fxHSN_Code__c != null)
			{
				if (wd.Work_Description__c != null)
				{
					// SVMXCFG-1054 - Populate the "Concat Part Work Description"
					wd.Concat_Part_Work_Description__c = wd.Material_Part_Description__c + '<br/>' + wd.Work_Description__c + '<br/>' + 'HSN Code : ' + wd.fxHSN_Code__c;
				}
				else if (wd.Work_Description__c == null)
				{
					wd.Concat_Part_Work_Description__c = wd.Material_Part_Description__c + '<br/>' + 'HSN Code : ' + wd.fxHSN_Code__c;
				}
			}
			else if (wd.Work_Description__c != null)
			{
				wd.Concat_Part_Work_Description__c = wd.Material_Part_Description__c + '<br/>' + wd.Work_Description__c;
			}
		}
	}

	public static void addsummaryAfter(List<WorkOrderLineItem> workDetailLines, Map<Id, WorkOrderLineItem> oldMap) {
		//Map<String,SMAX_PS_HSN_Code_Setting__c> hsncodeIndia = SMAX_PS_HSN_Code_Setting__c.getAll();
		Set<Id> woIds = new Set<Id>();
		//Set<Id> prodIds = new Set<Id>();
		List<WorkOrderLineItem> wdToProcess = new List<WorkOrderLineItem>();
		for (WorkOrderLineItem wd : workDetailLines)
		{
			WorkOrderLineItem old = (oldMap == null) ? null : oldMap.get(wd.Id);
			woIds.add(wd.WorkOrderId);
			wdToProcess.add(wd);
			System.debug('wdToProcess: ' + wdToProcess);
			System.debug('woIds: ' + woIds);
		}
		if (wdToProcess.isEmpty()) return;
		List<WorkOrderLineItem> linesToCreate = new List<WorkOrderLineItem>();
		for (WorkOrderLineItem line : wdToProcess)
		{
			//WorkOrderLineItem old = (oldMap == null) ? null : oldMap.get(line.Id);
			//wdlines.add(new WorkOrderLineItem(Id = line.Id) );
			WorkOrderLineItem wdlines = new WorkOrderLineItem(Id = line.Id);
			if (line.Work_Description__c != null)
			{
				String wdSum = (line.Work_Description__c.length() > 40) ?
						line.Work_Description__c.substring(0,40) : line.Work_Description__c;
				wdlines.WorkSummary__c = wdSum;
			}
			if (/*hsncodeIndia.keyset().contains(line.CurrencyIsoCode)*/ line.CurrencyIsoCode == 'INR' && line.fxHSN_Code__c != null)
			{
				if (line.Work_Description__c != null)
				{
					// SVMXCFG-1054 - Populate the "Concat Part Work Description"
					wdlines.Concat_Part_Work_Description__c = line.Material_Part_Description__c + '<br/>' + line.Work_Description__c + '<br/>' + 'HSN Code : ' + line.fxHSN_Code__c;
				}
				else if (line.Work_Description__c == null)
				{
					wdlines.Concat_Part_Work_Description__c = line.Material_Part_Description__c + '<br/>' + 'HSN Code : ' + line.fxHSN_Code__c ;
				}
			}
			else if (line.Work_Description__c != null)
			{
				wdlines.Concat_Part_Work_Description__c = line.Material_Part_Description__c + '<br/>' + line.Work_Description__c;
			}
			linesToCreate.add(wdlines);
			System.debug('linesToCreate: ' + linesToCreate);
		}
		update linesToCreate;
	}

	/**
	*  Replaces createWorkOrderEvent(...), removing the submit logic, and adding txnId
	*  Should be called from the before update (but after toggleIntegrationStatus(...))
	*/
	public static void cancelLines(List<WorkOrderLineItem> wDetailNewList, Map<Id, WorkOrderLineItem> wDetailOldMap)
	{
		if (!FS_Utility.isActive('Work Detail Cancel Lines', 'Create Work Order Platform Events when Work Details are Cancelled.')) {
			return;
		}

		Set<Id> cancelledWoIds = new Set<Id>();
		String txnId = String.valueOf(Datetime.now().formatGmt('yyyy-MM-dd HH:mm:ss.SSS'));

		// Collect qualified Work Order Ids for which Events have to be created
		for (WorkOrderLineItem wd : wDetailNewList) {
			WorkOrderLineItem old = (wDetailOldMap == null) ? null : wDetailOldMap.get(wd.Id);
			// SVMXINT-512: Adding the Pending Check..
			if ( old != null && old.Status != wd.Status && wd.IntegrationStatus__c == 'Pending')
			{
				if (wd.Status == 'Canceled') {
					wd.SubmitTxnId__c = txnId;
					cancelledWoIds.add(wd.WorkOrderId);
				}
			}
		}

		if (cancelledWoIds.isEmpty()) {
			return;
		}

		// Publish the Event(s)
		List<FS_WorkOrder_Event__e> events = new List<FS_WorkOrder_Event__e>();
		for (Id woId : cancelledWoIds) {
			FS_WorkOrder_Event__e iEvent = new FS_WorkOrder_Event__e();
			iEvent.Action__c = 'CANCEL';
			iEvent.SubmitTxnId__c = txnId;
			iEvent.WorkOrderId__c = woId;
			events.add(iEvent);
		}

		FS_PlatformEventUtility.publishEvents(events, 'WorkOrderId__c', 'Action__c');
	}

	public static void copyRelatedData(List<WorkOrderLineItem> detailList)
	{
		if (!FS_Utility.isActive('Work Detail Copy Related Data', 'Copy related data to the WOLI')) {
			return;
		}

		Set<Id> itemIds = new Set<Id>();
		Set<Id> salesIds = new Set<Id>();
		List<WorkOrderLineItem> itemLines = new List<WorkOrderLineItem>();
		List<WorkOrderLineItem> salesLines = new List<WorkOrderLineItem>();
		for (WorkOrderLineItem wd : detailList)
		{
			if (wd.Consumed_Product_Stock__c != null && wd.Part__c == null) {
				itemIds.add(wd.Consumed_Product_Stock__c);
				itemLines.add(wd);
			}
			if (wd.Travel_Labor_Product__c != null && wd.Part__c == null) {
				salesIds.add(wd.Travel_Labor_Product__c);
				salesLines.add(wd);
			}
		}

		if (!itemLines.isEmpty()) {
			Map<Id, ProductItem> itemMap = new Map<Id, ProductItem>([SELECT Id, Product2Id
				FROM ProductItem WHERE Id IN :itemIds]);
			for (WorkOrderLineItem line : itemLines) {
				ProductItem item = itemMap.get(line.Consumed_Product_Stock__c);
				if (item != null) {
					line.Part__c = item.Product2Id;
				}
			}
		}

		if (!salesLines.isEmpty()) {
			Map<Id, Product_Sales__c> salesMap = new Map<Id, Product_Sales__c>([SELECT Id, Product__c
				FROM Product_Sales__c WHERE Id IN :salesIds]);
			for (WorkOrderLineItem line : salesLines) {
				Product_Sales__c sales = salesMap.get(line.Travel_Labor_Product__c);
				if (sales != null) {
					line.Part__c = sales.Product__c;
				}
			}
		}
   }

	public static void deleteWorkDetailRecords(List<WorkOrderLineItem> workDetailList, Map<Id, WorkOrderLineItem> oldMap)
	{
		if (!FS_Utility.isActive('Delete Work Detail Records', 'Delete Work Detail records when they are marked for deletion.')) {
			return;
		}

		// Get the WDL Ids list of records that are marked for deletion
		Set<Id> workDetailIdsToDelete = new Set<Id>();
		for(WorkOrderLineItem workDetail :workDetailList) {

			if (workDetail.Delete_Line__c == true) {

				workDetailIdsToDelete.add(workDetail.Id);
			}
		}

		if (workDetailIdsToDelete.isEmpty()) {
			return;
		}

		// Get the list of Work Detail records to delete
		// 2024-07-16: DISABLING for SFS. Flow L.FLOW_6812: Work Order Line Item - Delete - General conflicts with this
//		List<WorkOrderLineItem> workDetailsToDelete = [SELECT Id, Delete_Line__c FROM WorkOrderLineItem WHERE Id IN: workDetailIdsToDelete];
//		System.debug('Deleting Work Details: ' + workDetailsToDelete.size() + ' ' + workDetailsToDelete);
//		delete workDetailsToDelete;
	}

	public static void logDuplicateErrors(List<WorkOrderLineItem> wdList, Map<Id, WorkOrderLineItem> oldMap)
	{
		if (!FS_Utility.isActive('Work Detail Dulicate Errors', 'Create Integration Errors when SAP Confirmation Numbers are changed.')) {
			return;
		}

		List<FS_IntegrationError__c> errorList = new List<FS_IntegrationError__c>();
		for (WorkOrderLineItem detail : wdList)
		{
			WorkOrderLineItem old = (oldMap == null) ? null : oldMap.get(detail.Id);
			if (old == null) {
				continue;
			}

			if (old.SAP_Confirmation__c != null && detail.SAP_Confirmation__c != old.SAP_Confirmation__c)
			{
				FS_IntegrationError__c ie = new FS_IntegrationError__c();
				ie.RelatedElementType__c = 'WorkOrderLineItemId';
				ie.RelatedElementIdentifier__c = detail.Id;
				ie.ErrorMessage__c = 'DUPLICATE PROCESSING: Work Detail posted as multiple SAP Confirmation Numbers: '
						+ old.SAP_Confirmation__c + ', ' + detail.SAP_Confirmation__c;
				errorList.add(ie);
			}
			if (old.CancellationNumber__c != null && detail.CancellationNumber__c != old.CancellationNumber__c)
			{
				FS_IntegrationError__c ie = new FS_IntegrationError__c();
				ie.RelatedElementType__c = 'WorkOrderLineItemId';
				ie.RelatedElementIdentifier__c = detail.Id;
				ie.ErrorMessage__c = 'DUPLICATE PROCESSING: Work Order posted as multiple SAP Cancellation Numbers: '
						+ old.CancellationNumber__c + ', ' + detail.CancellationNumber__c;
				errorList.add(ie);
			}
		}

		if (!errorList.isEmpty()) {
			insert errorList;
		}
	}

	public static void lookupProductPlant(List<WorkOrderLineItem> wdList, Map<Id, WorkOrderLineItem> oldMap)
	{
		if (!FS_Utility.isActive('Work Detail Product Plant', 'Lookup the Product Plant for Parts lines.')) {
			return;
		}

		Set<Id> woIds = new Set<Id>();
		Set<Id> prodIds = new Set<Id>();
		Set<Id> prdStkIds = new Set<Id>();
		List<WorkOrderLineItem> wdToUpdate = new List<WorkOrderLineItem>();
		for (WorkOrderLineItem wd : wdList)
		{
			WorkOrderLineItem old = (oldMap == null) ? null : oldMap.get(wd.Id);
			if (wd.Line_Type__c == 'Parts' && wd.Consumed_Product_Stock__c != null
					&& (old == null || old.Consumed_Product_Stock__c != wd.Consumed_Product_Stock__c))
			{
				woIds.add(wd.WorkOrderId);
				prdStkIds.add(wd.Consumed_Product_Stock__c);
				wdToUpdate.add(wd);
			}
		}

		if (wdToUpdate.isEmpty())
		{
			return;
		}

		Set<String> plants = new Set<String>();
		Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>([SELECT Id,
				LocationId, Location.MaintenancePlant__c,Any_Parts_Eligible_for_Return__c
		FROM WorkOrder WHERE Id IN :woIds]);
		for (WorkOrder wo : woMap.values())
		{
			if (wo.LocationId != null && wo.Location.MaintenancePlant__c != null)
			{
				plants.add(wo.Location.MaintenancePlant__c);
			}
		}

		if (plants.isEmpty())
		{
			return;
		}

		List<ProductItem> prdItemList =[SELECT Id,Product2Id FROM ProductItem WHERE Id IN:prdStkIds];
		Map<Id,Id> prdItem = new Map<Id,Id>();
		for(ProductItem pd: prdItemList){
			prodIds.add(pd.Product2Id);
			prdItem.put(pd.Id, pd.Product2Id);
		}
		List<FS_ProductPlant__c> allProductPlants = [SELECT Id, Name, Product__c, Plant__c,
				Return_Part__c,Return_Part_Number__c, Credit_Relevant_Part__c
		FROM FS_ProductPlant__c WHERE Product__c IN :prodIds AND Plant__c IN :plants];
		Map<String, FS_ProductPlant__c> ppMap = new Map<String, FS_ProductPlant__c>();
		for (FS_ProductPlant__c pp : allProductPlants)
		{
			String key = pp.Product__c + '-' + pp.Plant__c;
			ppMap.put(key, pp);
		}

		Map<Id, WorkOrder> woUpdateMap = new Map<Id, WorkOrder>();
		for (WorkOrderLineItem wd: wdToUpdate)
		{
			WorkOrder wo = woMap.get(wd.WorkOrderId);
			String plant = (wo != null && wo.LocationId != null) ? wo.Location.MaintenancePlant__c : null;
			String key = prdItem.get(wd.Consumed_Product_Stock__c) + '-' + plant;
			FS_ProductPlant__c pp = ppMap.get(key);
			if (pp != null)
			{
				wd.Product_Plant__c = pp.Id;
				wd.Eligible_for_Return__c = (pp.Return_Part__c != null || pp.Return_Part_Number__c != null);
				wd.Return_Part_Number__c = pp.Return_Part_Number__c;
				//wd.Return_Part__c = pp.Return_Part__c;

				// Update the WO also...
				Boolean newValue = wo.Any_Parts_Eligible_for_Return__c || wd.Eligible_for_Return__c;
				if (newValue != wo.Any_Parts_Eligible_for_Return__c)
				{
					wo.Any_Parts_Eligible_for_Return__c = newValue;
					woUpdateMap.put(wo.Id, wo);
				}
			}
		}

		if (!woUpdateMap.isEmpty())
		{
			// NOTE: might need to move this to a future call IF problematic
			update woUpdateMap.values();
		}
	}

	public static void toggleIntegrationStatus(List<WorkOrderLineItem> wDetailNewList, Map<Id, WorkOrderLineItem> wDetailOldMap)
	{
		if (!FS_Utility.isActive('Work Detail Toggle Int Status', 'Toggle Integration Status when Work Details are Submitted or Cancelled.')) {
			return;
		}

		// Update the Integration status in Work Detail
		if (!wDetailNewList.isEmpty()) {
			for (WorkOrderLineItem wd : wDetailNewList) {
				WorkOrderLineItem old = (wDetailOldMap == null) ? null : wDetailOldMap.get(wd.Id);
				if ( old != null && old.Status != wd.Status)
				{
					if (wd.Status == 'Submitted') {
						wd.IntegrationStatus__c='Pending';
					}
					else if (wd.Status == 'Canceled') {
						// SVMXINT-512: Work Detail: Only Cancel if Confirmed
						if (String.isNotBlank(wd.SAP_Confirmation__c)) {
							wd.IntegrationStatus__c='Pending';
						} else {
							wd.IntegrationStatus__c = null;
						}
					}
				}
			}
		}
	}

	private static Set<String> PRE_CONFIRMED = new Set<String> { 'Open', 'Submitted', 'Priced' };

	public static void updateDetailLineAndIntegrationStatus(List<WorkOrderLineItem> wDetailNewList, Map<Id, WorkOrderLineItem> wDetailOldMap)
	{
		if (!FS_Utility.isActive('Update Detail And Integration Status', 'Update the Line Status and the Integration Status in Work Detail when the SAP Confirmation and the Cancellation Number are changed.')) {
			return;
		}

		// Update Work Detail Line and Integration Status
		if (!wDetailNewList.isEmpty()) {
			for (WorkOrderLineItem wd : wDetailNewList) {
				WorkOrderLineItem old = (wDetailOldMap == null) ? null : wDetailOldMap.get(wd.Id);

				// SVMXCFG-494: PREVENT lost SAP Confirmation numbers
				if ( old != null && String.isBlank(wd.SAP_Confirmation__c) && String.isNotBlank(old.SAP_Confirmation__c))
				{
					wd.SAP_Confirmation__c = old.SAP_Confirmation__c;
					wd.Status='Confirmed';
					wd.IntegrationStatus__c='Completed';
				}
				// SVMXCFG-530: Work Detail: Prevent Status Rollback
				if ( old != null && old.Status == 'Confirmed' && PRE_CONFIRMED.contains(wd.Status))
				{
					wd.Status='Confirmed';
				}
				if ( old != null && wd.SAP_Confirmation__c != null && wd.SAP_Confirmation__c != old.SAP_Confirmation__c )
				{
					wd.Status='Confirmed';
					wd.IntegrationStatus__c='Completed';
				}
				if ( old != null && wd.Status == 'Confirmed' && wd.Status != old.Status )
				{
					wd.IntegrationStatus__c='Completed';
				}
				if ( old != null && wd.CancellationNumber__c != null && wd.CancellationNumber__c != old.CancellationNumber__c )
				{
					wd.Status='Canceled';
					wd.IntegrationStatus__c='Completed';
				}
			}
		}
	}

	public static void updateFaultCodes(List<WorkOrderLineItem> detailList, Map<Id, WorkOrderLineItem> oldMap)
	{
		if (!FS_Utility.isActive('Update Fault Codes', 'Update the Fault Code Complaint Required field in Work Detail from the Fault Codes object.')) {
			return;
		}

		List<WorkOrderLineItem> faultCodeLines = new List<WorkOrderLineItem>();
		Set<Id> faultCodeIds = new Set<Id>();
		for (WorkOrderLineItem detail : detailList)
		{
			WorkOrderLineItem old = (oldMap == null) ? null : oldMap.get(detail.Id);
			if (detail.Line_Type__c != 'Fault Code') {
				continue;
			}

			faultCodeLines.add(detail);
			if (detail.Fault_Code__c != null)
			{
				faultCodeIds.add(detail.Fault_Code__c);
			}
			if (detail.ActionFaultCode__c != null)// && (old == null || detail.SMAX_PS_ActionFaultCode__c != old.SMAX_PS_ActionFaultCode__c))
			{
				faultCodeIds.add(detail.ActionFaultCode__c);
			}
			if (detail.InstallationFaultCode__c != null)// && (old == null || detail.SMAX_PS_InstallationFaultCode__c != old.SMAX_PS_InstallationFaultCode__c))
			{
				faultCodeIds.add(detail.InstallationFaultCode__c);
			}
			if (detail.CompletionFaultCode__c != null)// && (old == null || detail.SMAX_PS_CompletionFaultCode__c != old.SMAX_PS_CompletionFaultCode__c))
			{
				faultCodeIds.add(detail.CompletionFaultCode__c);
			}
		}

		if (faultCodeLines.isEmpty()) {
			return;
		}

		Map<Id, FS_FaultCode__c> faultCodeMap = new Map<Id, FS_FaultCode__c>(
		[SELECT Id, Name, Code_Description__c, Code__c, Complaint_Required__c
		FROM FS_FaultCode__c WHERE Id IN :faultCodeIds]);
		for (WorkOrderLineItem detail : faultCodeLines)
		{
			Decimal complaintRequired = 0;
			if (detail.Fault_Code__c != null && faultCodeMap.containsKey(detail.Fault_Code__c))
			{
				FS_FaultCode__c fc = faultCodeMap.get(detail.Fault_Code__c);
				complaintRequired += (fc.Complaint_Required__c == null) ? 0 : fc.Complaint_Required__c;
			}
			if (detail.ActionFaultCode__c != null && faultCodeMap.containsKey(detail.ActionFaultCode__c))
			{
				FS_FaultCode__c fc = faultCodeMap.get(detail.ActionFaultCode__c);
				detail.Fault_Code_Action__c = fc.Code_Description__c + '~' + fc.Code__c;
				complaintRequired += (fc.Complaint_Required__c == null) ? 0 : fc.Complaint_Required__c;
			}
			if (detail.InstallationFaultCode__c != null && faultCodeMap.containsKey(detail.InstallationFaultCode__c))
			{
				FS_FaultCode__c fc = faultCodeMap.get(detail.InstallationFaultCode__c);
				detail.Installation_Code__c = fc.Code__c + ' ~ ' + fc.Code_Description__c;
				complaintRequired += (fc.Complaint_Required__c == null) ? 0 : fc.Complaint_Required__c;
			}
			if (detail.CompletionFaultCode__c != null && faultCodeMap.containsKey(detail.CompletionFaultCode__c))
			{
				FS_FaultCode__c fc = faultCodeMap.get(detail.CompletionFaultCode__c);
				detail.Completion_Code__c = fc.Code__c + ' ~ ' + fc.Code_Description__c;
				complaintRequired += (fc.Complaint_Required__c == null) ? 0 : fc.Complaint_Required__c;
			}
			detail.Fault_Code_Complaint_Required__c = complaintRequired;
		}
	}

	public static void updateFieldValues(List<WorkOrderLineItem> detailList, Map<Id, WorkOrderLineItem> oldMap)
	{
		if (!FS_Utility.isActive('Work Detail Update Field Values', 'Update Work Detail fields when Work Details are updated.')) {
			return;
		}

		for (WorkOrderLineItem wd : detailList)
		{
			// [SVMXCFG-436] Copy the Contract Discount to the OOTB Discount field
			//wd.Discount = wd.ContractPercentDiscount__c;
			// [SVMXCFG-519] Round Labor and Travel to 1 decimal place
			if ((wd.Line_Type__c == 'Labor' || wd.Line_Type__c == 'Travel') && wd.Quantity__c != null)
			{
				wd.Quantity__c = wd.Quantity__c.setScale(1, System.RoundingMode.DOWN);
			}

			// [ITSFDC-89] If Adjustment value, but no "Type", default to "Uplift"
			if (wd.ServiceAmountAdjustment__c != null && wd.ServiceAmountAdjustmentType__c == null)
			{
				wd.ServiceAmountAdjustmentType__c = 'Uplift';
			}
			if (wd.ServicePercentAdjustment__c != null && wd.ServicePercentAdjustmentType__c == null)
			{
				wd.ServicePercentAdjustmentType__c = 'Uplift';
			}
		}
	}

	public static void updateTechOnDebriefLine(List<WorkOrderLineItem> newList, Map<Id, WorkOrderLineItem> oldMap)
	{
		// call to service register
		if (!FS_Utility.isActive('updateTechOnDebriefLine','Places the ID of Technician working on a detail into the Technician field')) { return; }

		List<ServiceResource> debriefTechs = [SELECT Id, Name
			FROM ServiceResource WHERE RelatedRecordId = :UserInfo.getUserId()];

		if (debriefTechs.size() > 0 )
		{
			for (WorkOrderLineItem wd : newList)
			{
				// ITSFDC-1047 Include "Remote" Work Details
				if (wd.Service_Resource__c == null  && debriefTechs[0] != null && wd.Record_Type__c == 'Usage')
				{
					wd.Service_Resource__c = debriefTechs[0].Id;
				}
			}
		}
	}

	public static void updateWorkDetailPlantAndWorkCenter(List<WorkOrderLineItem> workDetailList, Map<Id, WorkOrderLineItem> oldMap){

		System.debug('Entering SMAX_PS_WorkDetailManager.updateWorkDetailPlantAndWorkCenter method');

		Set<Id> workOrderIds = new Set<Id>();
		Set<Id> technicianIds = new Set<Id>();

		// Get the Word Detail records that we need to process
		Set<WorkOrderLineItem> workDetailsToProcess = new Set<WorkOrderLineItem>();
		for(WorkOrderLineItem workDetail :workDetailList) {
			// 08/24/2023: Only process Usage/Consumption + Labor/Travel lines
			Boolean isLaborTravel = (workDetail.Record_Type__c == 'Usage' &&
				(workDetail.Line_Type__c == 'Labor' || workDetail.Line_Type__c == 'Travel'));
			if (!isLaborTravel) {
				continue;
			}

			WorkOrderLineItem old = oldMap == null ? null : oldMap.get(workDetail.Id);
			if ( old == null
					|| workDetail.Service_Resource__c != old.Service_Resource__c
					|| workDetail.Plant__c == null
					|| workDetail.Work_Center__c == null) {

				workDetailsToProcess.add(workDetail);
				workOrderIds.add(workDetail.Service_Resource__c);
				if (workDetail.Service_Resource__c != null) {
					technicianIds.add(workDetail.Service_Resource__c);
				}
			}
		}
		System.debug('workDetailsToProcess: ' + workDetailsToProcess.size() + ' ' + workDetailsToProcess);
		System.debug('workOrderIds: ' + workOrderIds.size() + ' ' + workOrderIds);
		System.debug('technicianIds: ' + technicianIds.size() + ' ' + technicianIds);

		if (workDetailsToProcess.isEmpty()) return;

		// Create a Work Order Id to Work Order Map
		Map<Id, ServiceResource> woTechMap = FS_WorkOrderManager.lookupAssignedResources(workOrderIds);
//		Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>([
//				SELECT Id, SAP_Maintenance_Plant__c, SAP_Work_Center__c
//				FROM WorkOrder
//				WHERE Id IN: workOrderIds
//		]);

		/* // 08/24/2023 Collect the WO Technician Ids also...
			for (WorkOrder wo : workOrderMap.values()) {
				if (wo.Service_Resource__c != null) {
					technicianIds.add(wo.Service_Resource__c);
				}
			}*/

		// Create a Technician Id to Technician Map
		Map<Id, ServiceResource> technicianMap = new Map<Id, ServiceResource>([
				SELECT Id, Plant__c, Work_Center__c
				FROM ServiceResource
				WHERE Id IN: technicianIds
		]);
		System.debug('technicianMap: ' + technicianMap.size() + ' ' + technicianMap);

		// Get Additional Work Center External Ids
		/* Set<String> additionalWorkCenterIds = new Set<String>();
		 for (WorkOrderLineItem workDetail : workDetailsToProcess) {
			 WorkOrder workOrder = workOrderMap.get(workDetail.WorkORderId);
			 //Id techId = (workDetail.Service_Resource__c != null) ? workDetail.Service_Resource__c : workOrder.Service_Resource__c;
			 Id techId = workDetail.Service_Resource__c;
			 additionalWorkCenterIds.add(techId + '-' + technicianMap.get(wworkDetail.Service_Resource__c).Plant__c);
		 }
		 System.debug('additionalWorkCenterIds: ' + additionalWorkCenterIds.size() + ' ' + additionalWorkCenterIds);*/

		// Get the Service Debrief Settings
		//Map<String, SMAX_PS_Service_Debrief_Settings__mdt> serviceDebriefSettingsMap = SMAX_PS_Service_Debrief_Settings__mdt.getAll();

		// Get Technician Additional Work Centers
		/*Map<String, Additional_Work_Centers__c> externalIdToAdditionalWorkCentersMap = new Map<String, SMAX_PS_Additional_Work_Centers__c>();
		List<SMAX_PS_Additional_Work_Centers__c> additionalWorkCenters = [
				SELECT Id, SMAX_PS_External_ID__c, SMAX_PS_Technician_Equipment__c, SMAX_PS_Plant__c, SMAX_PS_Work_Center__c
				FROM SMAX_PS_Additional_Work_Centers__c
				WHERE SMAX_PS_External_ID__c IN :additionalWorkCenterIds
		];
		for(SMAX_PS_Additional_Work_Centers__c additionalWorkCenter :additionalWorkCenters) {
			externalIdToAdditionalWorkCentersMap.put(additionalWorkCenter.SMAX_PS_External_ID__c, additionalWorkCenter);
		}
		System.debug('externalIdToAdditionalWorkCentersMap: ' + externalIdToAdditionalWorkCentersMap.size() + ' - ' + externalIdToAdditionalWorkCentersMap);*/

		for(WorkOrderLineItem woDetail :workDetailsToProcess){

			//WorkOrder workOrder = workOrderMap.get(woDetail.WorkOrderId);
			// 08/24/2023 Lookup Tech from EITHER WO or WorkDetail
			ServiceResource tech = (woDetail.Service_Resource__c == null) ? woTechMap.get(woDetail.WorkOrderId) : technicianMap.get(woDetail.Service_Resource__c);
			if (tech == null) {
				System.debug('Skipping Work Detail because no Tech found on Work Detail or Work Order: ' + woDetail);
				continue;
			}
			System.debug('tech' + tech);
			// ITSVMX-1295 Fill in the Work Detail -> Technician lookup if blank
			if (woDetail.Service_Resource__c == null) {
				woDetail.Service_Resource__c = tech.Id;
			}
			// ITSVMX-1227 If Tech's Plant is blank skip this logic
			if (String.isBlank(tech.Plant__c)) {
				System.debug('Skipping Work Detail because Tech has a blank Plant: ' + woDetail);
				continue;
			}
			// ITSVMX-1227/ITSVMX-1343 Exclude Enterprise WOs from Additional Work Center logic/error
//			if (workOrder.Is_Enterprise__c == true) {
//				System.debug('Skipping Work Detail because WO Is Enterprise: ' + woDetail);
//				continue;
//			}

			// If MDT Labor/Travel is enabled for the Work Order Company then use the Technician record values or the Additional Work Center record values
			/*if (workOrder.SMAX_PS_Owned_By_Company__c != null
					&& serviceDebriefSettingsMap.containsKey(workOrder.SMAX_PS_Owned_By_Company__c)
					&& serviceDebriefSettingsMap.get(workOrder.SMAX_PS_Owned_By_Company__c).SMAX_PS_Enable_Additional_LaborTravel__c == true) {

				// if the work order plant is equal to the technician plant then use the Technician record values
				if (workOrder.SMAX_PS_SAP_Maintenance_Plant__c == tech.SMAX_PS_Plant__c){
					woDetail.SMAX_PS_Plant__c = tech.SMAX_PS_Plant__c;
					woDetail.SMAX_PS_Work_Center__c = tech.SMAX_PS_Work_Center__c;
					System.debug('Set the Work Detail Plant and Work Center to the Technician Plant and Work Center');
				} else {
					// if the technician is not null and the work order plant is not equal to the technician plant then use the Additional Work Center record values
					SMAX_PS_Additional_Work_Centers__c additionalWorkCenter = externalIdToAdditionalWorkCentersMap.get(tech.Id + '-' + workOrder.SMAX_PS_SAP_Maintenance_Plant__c);
					if (additionalWorkCenter != null) {
						woDetail.SMAX_PS_Plant__c = additionalWorkCenter.SMAX_PS_Plant__c;
						woDetail.SMAX_PS_Work_Center__c = additionalWorkCenter.SMAX_PS_Work_Center__c;
						System.debug('Set the Work Detail Plant and Work Center to the Additional Work Center Plant and Work Center');
					} else {
						System.debug('SMAX_PS_WorkDetailManager.updateWorkDetailPlantAndWorkCenter() - Error: Technician or Additional Work Center is null');
						woDetail.addError('You do not have access to debrief Labor or Travel for this Work Order\'s shared Work Centre.  Please contact your System Administrator for resolution.');
					}
				}
			} else {*/
			// if the "Enable Additional LaborTravel" setting is disabled then use the Technician record values
			woDetail.Plant__c = tech.Plant__c;
			woDetail.Work_Center__c = tech.Work_Center__c;
			System.debug('Set the Work Detail Plant and Work Center to the Technician Plant and Work Center');
			//}
		}
	}

	public static void updateUnitOfMeasureCodes(List<WorkOrderLineItem> lineList, Map<Id, WorkOrderLineItem> oldMap)
	{
		if (!FS_Utility.isActive('Update Unit Of Measure Codes', 'Update the Unit of Measurement codes.')) {
			return;
		}

		// Based on this Checkbox.. Use_Product_Sales_UOM__c
		// Update this field:  UnitOfMeasure__c
		// And this field:  UOM_Code__c
		List<WorkOrderLineItem> linesToUpdate = new List<WorkOrderLineItem>();
		Set<Id> woIds = new Set<Id>();
		Set<Id> productIds = new Set<Id>();
		for (WorkOrderLineItem line : lineList)
		{
			WorkOrderLineItem old = (oldMap == null) ? null : oldMap.get(line.Id);
			if (line.UnitOfMeasure__c == null || line.UOM_Code__c == null
					|| (old != null && (line.Use_Product_Sales_UOM__c != old.Use_Product_Sales_UOM__c
					|| line.Product2Id != old.Product2Id)))
			{
				linesToUpdate.add(line);
				woIds.add(line.WorkOrderId);
				productIds.add(line.Product2Id);
			}
		}

		if (linesToUpdate.isEmpty()) {
			return;
		}

		// ProductSales below is based on SalesOrg from Location... SalesOrg__c
		Set<String> salesOrgs = new Set<String>();
		Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>(
				[SELECT Id, LocationId, Location.SalesOrg__c FROM WorkOrder WHERE Id IN :woIds]);
		for (WorkOrder wo : woMap.values())
		{
			if (wo.LocationId != null && wo.Location.SalesOrg__c != null)
			{
				salesOrgs.add(wo.Location.SalesOrg__c);
			}
		}

		Map<Id, Product2> productMap = new Map<Id, Product2>(
		[SELECT Id, ProductCode, QuantityUnitOfMeasure, Unit_of_Measure_Code__c,
		(SELECT Id, External_ID__c, Sales_Org__c, Sales_Unit__c, Sales_Unit_Code__c
		FROM Product_Sales__r WHERE Sales_Org__c IN :salesOrgs)
		FROM Product2 WHERE Id IN :productIds]);

		// ... from either Product: (if false)   QuantityUnitOfMeasure , PKI_Qty_UOM_Code__c
		// OR from the SalesProduct [ProductSales__c]: (if true)  SalesUnit__c , Sales_Unit_Code__c
		for (WorkOrderLineItem line : linesToUpdate)
		{
			Product2 prod = productMap.get(line.Product2Id);
			WorkOrder wo = woMap.get(line.WorkOrderId);
			String salesOrg = wo.Location.SalesOrg__c;
			updateUnitOfMeasureCodes(line, salesOrg, prod);
		}
	}

	public static void updateUnitOfMeasureCodes(WorkOrderLineItem line, String salesOrg, Product2 prod)
	{
		if (!FS_Utility.isActive('Update Unit Of Measure Codes', 'Update WorkOrderLineItem Qty UOM from the Product.')) {
			return;
		}

		if (prod == null) {
			return;
		}

		if (line.Use_Product_Sales_UOM__c == true)
		{
			Product_Sales__c productSales = null;
			for (Product_Sales__c sales : prod.Product_Sales__r)
			{
				if (sales.Sales_Org__c == salesOrg)
				{
					productSales = sales;
					break;
				}
			}

			if (productSales == null)
			{
				String errorMsg = 'ProductSales for Product: ' + prod.ProductCode + ' and SalesOrg: '
						+ salesOrg + ' not found.  Cannot use "Sales UOM".';
				System.debug(errorMsg);
				//line.addError(errorMsg);
				line.Use_Product_Sales_UOM__c = false;
			}
			else if (productSales.Sales_Unit__c == null || productSales.Sales_Unit_Code__c == null)
			{
				String errorMsg = 'ProductSales: ' + productSales.External_ID__c
						+ ' does not have "Sales UOM" values.  Cannot use "Sales UOM".';
				System.debug(errorMsg);
				//line.addError(errorMsg);
				line.Use_Product_Sales_UOM__c = false;
			}
			else
			{
				line.UnitOfMeasure__c = productSales.Sales_Unit__c;
				line.UOM_Code__c = productSales.Sales_Unit_Code__c;
			}
		}

		if (line.Use_Product_Sales_UOM__c == false)
		{
			line.UnitOfMeasure__c = prod.QuantityUnitOfMeasure;
			line.UOM_Code__c = prod.Unit_of_Measure_Code__c;
		}
	}
}