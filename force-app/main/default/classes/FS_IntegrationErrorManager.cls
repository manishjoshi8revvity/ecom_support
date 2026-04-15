/**
 *  Apex Class for Integration Error [FS_IntegrationError__c] Business Logic.
 *  2017-09-28      Veerendra Moodbidri       Initial creation, for Work Order Outbound Integration.
 *  1. Update Integration Status in the associated Work Detail
 *  2. Fill in the Lookup fields based on the Related Element Identifier & Type fields
 *  CONVERTED to SFS by frankvanloon on 4/8/24.
 */
public with sharing class FS_IntegrationErrorManager {

	public static void updateIntegrationStatusInWorkOrderLineItem(List<FS_IntegrationError__c> ieNewList)
	{
		Set<Id> wdIds = new Set<Id>();
		List<WorkOrderLineItem> wDetailUpdateList = new List<WorkOrderLineItem>();

		// Collect qualified Work Detail Ids
		if (!ieNewList.isEmpty()) {
			for (FS_IntegrationError__c ie : ieNewList)
			{
				if ( ie.WorkOrderLineItem__c != null )
					wdIds.add(ie.WorkOrderLineItem__c);
			}
		}
		if (wdIds.isEmpty())
			return;

		// Select the Work Detail lines which qualify for updation
		List<WorkOrderLineItem> wdList = new List<WorkOrderLineItem>([SELECT Id, LineItemNumber FROM WorkOrderLineItem WHERE Id IN :wdIds]);

		// Update Work Detail Integration Error field
		if (!wdList.isEmpty()) {
			for ( WorkOrderLineItem wd : wdList ) {
				WorkOrderLineItem wdUpdate = new WorkOrderLineItem(Id=wd.Id);
				wdUpdate.IntegrationStatus__c='Error';
				wDetailUpdateList.add(wdUpdate);
			}
			if (!wDetailUpdateList.isEmpty())
				update wDetailUpdateList;
		}
	}

	public static void updateWorkOrderLastError(List<FS_IntegrationError__c> ieNewList)
	{
		Map<Id, String> woErrorMap = new Map<Id, String>();
		for (FS_IntegrationError__c ie : ieNewList)
		{
			if ( ie.WorkOrder__c != null && ie.ErrorMessage__c != null )
			{
				Id woId = ie.WorkOrder__c;
				String msg = '[' + System.now() + '] ' + ie.ErrorMessage__c;
				if (msg.length() > 255)
					msg = msg.substring(0, 252) + '...';

				woErrorMap.put(woId, msg);
			}
		}

		if (woErrorMap.isEmpty())
			return;

		List<WorkOrder> woList = [SELECT Id, WorkOrderNumber, Status,
				Completion_Errors__c, Last_Integration_Error__c
			FROM WorkOrder WHERE Id IN :woErrorMap.keySet()];
		for (WorkOrder wo : woList)
		{
			String msg = woErrorMap.get(wo.Id);
			wo.Last_Integration_Error__c = msg;
			if (wo.Status == FS_WorkOrderDebriefManager.WORK_COMPLETE_PENDING
					|| wo.Status == FS_WorkOrderDebriefManager.WORK_COMPLETE)
			{
				wo.Completion_Errors__c = 'Integration Error Received: ' + msg;
				wo.Status = FS_WorkOrderDebriefManager.WORK_COMPLETE_ERROR;
			}
		}

		// SVMXCFG-1020 WO Integration Error when in CreditHold - Catch Errors...
		//List<SMAX_PS_ErrorLog__c> logs = new List<SMAX_PS_ErrorLog__c>();
		Database.SaveResult[] results = Database.update(woList, false);
		for (Integer i = 0; i < results.size(); i++)
		{
			Database.SaveResult result = results[i];
			WorkOrder wo = woList[i];
			if (!result.isSuccess())
			{
				String errorMsg = 'Error updating Work Order with Integration Error: ' + wo.WorkOrderNumber + ' - ' + result.getErrors();
				System.debug('INT_ERROR_WO: ' + errorMsg);
				//logs.add(SMAX_PS_LogUtility.createLog(SMAX_PS_LogUtility.ERROR, errorMsg, 'SMAX_PS_IntegrationErrorManager', null, wo.Id));
			}
			else
			{
				System.debug('INT_ERROR_WO: Success updating Work Order: ' + wo.Id);
			}
		}

//		if (!logs.isEmpty())
//			insert logs;
	}

	/**
	 * SVMXCFG-1006 Re-opening parts orders with integration errors
	 */
	public static void updateProductRequestErrorStatus(List<FS_IntegrationError__c> ieNewList)
	{
		Set<Id> poIds = new Set<Id>();
		for (FS_IntegrationError__c ie : ieNewList)
		{
			if ( ie.ProductRequest__c != null && ie.ErrorMessage__c != null )
			{
				Id poId = ie.ProductRequest__c;
				poIds.add(poId);
			}
		}

		if (poIds.isEmpty())
			return;

		List<ProductRequest> poList = [SELECT Id, ProductRequestNumber, Status
			FROM ProductRequest WHERE Id IN :poIds];
		for (ProductRequest po : poList)
		{
			if (po.Status == 'Submitted')
			{
				po.Status = 'Error';
			}
		}

		//List<SMAX_PS_ErrorLog__c> logs = new List<SMAX_PS_ErrorLog__c>();
		Database.SaveResult[] results = Database.update(poList, false);
		for (Integer i = 0; i < results.size(); i++)
		{
			Database.SaveResult result = results[i];
			ProductRequest po = poList[i];
			if (!result.isSuccess())
			{
				String errorMsg = 'Error updating Product Request with Integration Error: ' + po.ProductRequestNumber + ' - ' + result.getErrors();
				System.debug('INT_ERROR_PO: ' + errorMsg);
				//logs.add(SMAX_PS_LogUtility.createLog(SMAX_PS_LogUtility.ERROR, errorMsg, 'SMAX_PS_IntegrationErrorManager', null, po.Id));
			}
			else
			{
				System.debug('INT_ERROR_PO: Success updating Product Request: ' + po.Id);
			}
		}

//		if (!logs.isEmpty())
//			insert logs;
	}

	public static void updateReturnOrderErrorStatus(List<FS_IntegrationError__c> ieNewList)
	{
		Set<Id> poIds = new Set<Id>();
		for (FS_IntegrationError__c ie : ieNewList)
		{
			if ( ie.ReturnOrder__c != null && ie.ErrorMessage__c != null )
			{
				Id poId = ie.ReturnOrder__c;
				poIds.add(poId);
			}
		}

		if (poIds.isEmpty())
			return;

		List<ReturnOrder> poList = [SELECT Id, ReturnOrderNumber, Status
			FROM ReturnOrder WHERE Id IN :poIds];
		for (ReturnOrder po : poList)
		{
			if (po.Status == 'Submitted')
			{
				po.Status = 'Error';
			}
		}

		//List<SMAX_PS_ErrorLog__c> logs = new List<SMAX_PS_ErrorLog__c>();
		Database.SaveResult[] results = Database.update(poList, false);
		for (Integer i = 0; i < results.size(); i++)
		{
			Database.SaveResult result = results[i];
			ReturnOrder po = poList[i];
			if (!result.isSuccess())
			{
				String errorMsg = 'Error updating Return Order with Integration Error: ' + po.ReturnOrderNumber + ' - ' + result.getErrors();
				System.debug('INT_ERROR_PO: ' + errorMsg);
				//logs.add(SMAX_PS_LogUtility.createLog(SMAX_PS_LogUtility.ERROR, errorMsg, 'SMAX_PS_IntegrationErrorManager', null, po.Id));
			}
			else
			{
				System.debug('INT_ERROR_PO: Success updating Return Order: ' + po.Id);
			}
		}

//		if (!logs.isEmpty())
//			insert logs;
	}

	/**
	 * SVMXCFG-1056 Updating stock transfers with integration errors
	 */
	public static void updateProductTransferErrorStatus(List<FS_IntegrationError__c> ieNewList)
	{
		Set<Id> stIds = new Set<Id>();
		for (FS_IntegrationError__c ie : ieNewList)
		{
			if ( ie.StockTransfer__c != null && ie.StockTransfer__c != null )
			{
				Id stId = ie.StockTransfer__c;
				stIds.add(stId);
			}
		}

		if (stIds.isEmpty())
			return;

		List<ProductTransfer> stList = [SELECT Id, ProductTransferNumber, Status
			FROM ProductTransfer WHERE Id IN :stIds];
		for (ProductTransfer st : stList)
		{
			if (st.Status == 'Submitted')
			{
				st.Status = 'Error';
			}
		}

		//List<SMAX_PS_ErrorLog__c> logs = new List<SMAX_PS_ErrorLog__c>();
		Database.SaveResult[] results = Database.update(stList, false);
		for (Integer i = 0; i < results.size(); i++)
		{
			Database.SaveResult result = results[i];
			ProductTransfer st = stList[i];
			if (!result.isSuccess())
			{
				String errorMsg = 'Error updating Product Transfer with Integration Error: ' + st.ProductTransferNumber + ' - ' + result.getErrors();
				System.debug('INT_ERROR_PO: ' + errorMsg);
				//logs.add(SMAX_PS_LogUtility.createLog(SMAX_PS_LogUtility.ERROR, errorMsg, 'SMAX_PS_IntegrationErrorManager', null, st.Id));
			}
			else
			{
				System.debug('INT_ERROR_PO: Success updating Product Transfer: ' + st.Id);
			}
		}

//		if (!logs.isEmpty())
//			insert logs;
	}

	/**
	 *  SVMXINT-572 DMR - No changes "Error"
	 *  Should be called from AFTER INSERT
	 */
	public static void unlockDMR(List<FS_IntegrationError__c> ieNewList)
	{
		Set<Id> invoiceIds = new Set<Id>();
		for (FS_IntegrationError__c ie : ieNewList)
		{
			if ( ie.Invoice__c != null && ie.ErrorMessage__c != null )
			{
				Id invoiceId = ie.Invoice__c;
				if (ie.ErrorMessage__c.contains('No New values found to update DMR'))
				{
					// This is really a warning.. should still "Unlock" DMR
					invoiceIds.add(invoiceId);
				}
			}
		}

		if (invoiceIds.isEmpty())
			return;

		List<FS_Proforma_Invoice__c> invoiceToUpdate = new List<FS_Proforma_Invoice__c>();
		List<FS_Proforma_Invoice__c> invoices = [SELECT Id, Name, Status__c
			FROM FS_Proforma_Invoice__c WHERE Id IN :invoiceIds];
		for (FS_Proforma_Invoice__c inv : invoices)
		{
			if ( inv.Status__c == 'Locked' )
			{
				inv.Status__c = 'Open';
				invoiceToUpdate.add(inv);
			}
		}

		if (!invoiceToUpdate.isEmpty())
			update invoiceToUpdate;
	}

	/**
	 *  SHOULD BE CALLED FROM BEFORE INSERT
	 */
	public static void updateRelatedElement(List<FS_IntegrationError__c> ieNewList)
	{
		Map<String, List<FS_IntegrationError__c>> ieMap = new Map<String, List<FS_IntegrationError__c>>();
		for (FS_IntegrationError__c ie : ieNewList)
		{
			String ieType = ie.RelatedElementType__c;
			if (String.isNotBlank(ieType))
			{
				if (!ieMap.containsKey(ieType)) {
					ieMap.put(ieType, new List<FS_IntegrationError__c>());
				}
				ieMap.get(ieType).add(ie);
			}
		}

		for (String ieType : ieMap.keySet())
		{
			List<FS_IntegrationError__c> ieList = ieMap.get(ieType);
			Set<String> identifiers = new Set<String>();
			for (FS_IntegrationError__c ie : ieList)
			{
				identifiers.add(ie.RelatedElementIdentifier__c);
			}

			if (ieType == 'WorkOrderId')
			{
				Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>(
						[SELECT Id, WorkOrderNumber FROM WorkOrder WHERE Id IN :identifiers]);
				for (FS_IntegrationError__c ie : ieList)
				{
					WorkOrder wo = woMap.get(ie.RelatedElementIdentifier__c);
					if (wo != null) {
						ie.WorkOrder__c = wo.Id;
					}
				}
			}
			else if (ieType == 'ServiceOrderNumber')
			{
				Map<String, WorkOrder> woMap = new Map<String, WorkOrder>();
				for (WorkOrder wo : [SELECT Id, External_ID__c
					FROM WorkOrder WHERE External_ID__c IN :identifiers])
				{
					woMap.put(wo.External_ID__c, wo);
				}

				for (FS_IntegrationError__c ie : ieList)
				{
					WorkOrder wo = woMap.get(ie.RelatedElementIdentifier__c);
					if (wo != null) {
						ie.WorkOrder__c = wo.Id;
					}
				}
			}
			else if (ieType == 'WorkOrderLineItemId')
			{
				Map<Id, WorkOrderLineItem> wdMap = new Map<Id, WorkOrderLineItem>(
						[SELECT Id, LineItemNumber, WorkOrderId FROM WorkOrderLineItem WHERE Id IN :identifiers]);
				for (FS_IntegrationError__c ie : ieList)
				{
					WorkOrderLineItem wd = wdMap.get(ie.RelatedElementIdentifier__c);
					if (wd != null)
					{
						ie.WorkOrderLineItem__c = wd.Id;
						ie.WorkOrder__c = wd.WorkOrderId;
					}
				}
			}
			else if (ieType == 'InvoiceId')
			{
				Map<Id, FS_Proforma_Invoice__c> invMap = new Map<Id, FS_Proforma_Invoice__c>(
						[SELECT Id, Name FROM FS_Proforma_Invoice__c WHERE Id IN :identifiers]);
				for (FS_IntegrationError__c ie : ieList)
				{
					FS_Proforma_Invoice__c inv = invMap.get(ie.RelatedElementIdentifier__c);
					if (inv != null) {
						ie.Invoice__c = inv.Id;
					}
				}
			}
			else if (ieType == 'InvoiceNumber')
			{
				Map<String, FS_Proforma_Invoice__c> invMap = new Map<String, FS_Proforma_Invoice__c>();
				for (FS_Proforma_Invoice__c inv : [SELECT Id, SAP_DMR_Number__c, SAP_InvoiceNumber__c
					FROM FS_Proforma_Invoice__c WHERE SAP_DMR_Number__c IN :identifiers OR SAP_InvoiceNumber__c IN :identifiers])
				{
					if (String.isNotBlank(inv.SAP_DMR_Number__c)) {
						invMap.put(inv.SAP_DMR_Number__c, inv);
					}
					if (String.isNotBlank(inv.SAP_InvoiceNumber__c)) {
						invMap.put(inv.SAP_InvoiceNumber__c, inv);
					}
				}

				for (FS_IntegrationError__c ie : ieList)
				{
					FS_Proforma_Invoice__c inv = invMap.get(ie.RelatedElementIdentifier__c);
					if (inv != null) {
						ie.Invoice__c = inv.Id;
					}
				}
			}
			else if (ieType == 'ProductRequestId')
			{
				Map<Id, ProductRequest> poMap = new Map<Id, ProductRequest>(
						[SELECT Id, ProductRequestNumber FROM ProductRequest WHERE Id IN :identifiers]);
				for (FS_IntegrationError__c ie : ieList)
				{
					ProductRequest po = poMap.get(ie.RelatedElementIdentifier__c);
					if (po != null) {
						ie.ProductRequest__c = po.Id;
					}
				}
			}
			else if (ieType == 'ProductRequestNumber')
			{
				Map<String, ProductRequest> poMap = new Map<String, ProductRequest>();
				for (ProductRequest po : [SELECT Id, ExternalId__c
					FROM ProductRequest WHERE ExternalId__c IN :identifiers])
				{
					poMap.put(po.ExternalId__c, po);
				}

				for (FS_IntegrationError__c ie : ieList)
				{
					ProductRequest po = poMap.get(ie.RelatedElementIdentifier__c);
					if (po != null) {
						ie.ProductRequest__c = po.Id;
					}
				}
			}
			else if (ieType == 'ProductTransferId' || ieType == 'StockTransferId')
			{
				Map<Id, ProductTransfer> stMap = new Map<Id, ProductTransfer>(
						[SELECT Id, ProductTransferNumber FROM ProductTransfer WHERE Id IN :identifiers]);
				for (FS_IntegrationError__c ie : ieList)
				{
					ProductTransfer st = stMap.get(ie.RelatedElementIdentifier__c);
					if (st != null)
						ie.StockTransfer__c = st.Id;
				}
			}
			else if (ieType == 'ReturnOrderId')
			{
				Map<Id, ReturnOrder> poMap = new Map<Id, ReturnOrder>(
						[SELECT Id, ReturnOrderNumber FROM ReturnOrder WHERE Id IN :identifiers]);
				for (FS_IntegrationError__c ie : ieList)
				{
					ReturnOrder po = poMap.get(ie.RelatedElementIdentifier__c);
					if (po != null) {
						ie.ReturnOrder__c = po.Id;
					}
				}
			}
			else if (ieType == 'ReturnOrderNumber')
			{
				Map<String, ReturnOrder> poMap = new Map<String, ReturnOrder>();
				for (ReturnOrder po : [SELECT Id, ExternalId__c
					FROM ReturnOrder WHERE ExternalId__c IN :identifiers])
				{
					poMap.put(po.ExternalId__c, po);
				}

				for (FS_IntegrationError__c ie : ieList)
				{
					ReturnOrder po = poMap.get(ie.RelatedElementIdentifier__c);
					if (po != null) {
						ie.ReturnOrder__c = po.Id;
					}
				}
			}
//			else if (ieType == 'ContactId')
//			{
//				Map<Id, Contact> cMap = new Map<Id, Contact>(
//						[SELECT Id, Name FROM Contact WHERE Id IN :identifiers]);
//				for (FS_IntegrationError__c ie : ieList)
//				{
//					Contact c = cMap.get(ie.RelatedElementIdentifier__c);
//					if (c != null)
//						ie.SMAX_PS_Contact__c = c.Id;
//				}
//			}
//			else if (ieType == 'ContactNumber')
//			{
//				Map<String, Contact> cMap = new Map<String, Contact>();
//				for (Contact c : [SELECT Id, PKI_SAP_Contact_ID__c
//				FROM Contact WHERE PKI_SAP_Contact_ID__c IN :identifiers])
//				{
//					cMap.put(c.PKI_SAP_Contact_ID__c, c);
//				}
//
//				for (FS_IntegrationError__c ie : ieList)
//				{
//					Contact c = cMap.get(ie.RelatedElementIdentifier__c);
//					if (c != null)
//						ie.SMAX_PS_Contact__c = c.Id;
//				}
//			}
			else if (ieType == 'InventoryCountId')
			{
				Map<Id, FS_InventoryCount__c> icMap = new Map<Id, FS_InventoryCount__c>(
						[SELECT Id, Name FROM FS_InventoryCount__c WHERE Id IN :identifiers]);
				for (FS_IntegrationError__c ie : ieList)
				{
					FS_InventoryCount__c ic = icMap.get(ie.RelatedElementIdentifier__c);
					if (ic != null)
						ie.InventoryCount__c = ic.Id;
				}
			}
			else if (ieType == 'CaseId')
			{
				Map<Id, Case> caseMap = new Map<Id, Case>(
						[SELECT Id, CaseNumber FROM Case WHERE Id IN :identifiers]);
				for (FS_IntegrationError__c ie : ieList)
				{
					Case c = caseMap.get(ie.RelatedElementIdentifier__c);
					if (c != null)
						ie.Case__c = c.Id;
				}
			}
			else if (ieType == 'ServiceContractId')
			{
				Map<Id, ServiceContract> contractMap = new Map<Id, ServiceContract>(
						[SELECT Id, Name FROM ServiceContract WHERE Id IN :identifiers]);
				for (FS_IntegrationError__c ie : ieList)
				{
					ServiceContract c = contractMap.get(ie.RelatedElementIdentifier__c);
					if (c != null)
						ie.ServiceContract__c = c.Id;
				}
			}
		}

	}	
}