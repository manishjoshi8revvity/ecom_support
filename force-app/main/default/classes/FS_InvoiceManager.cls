public with sharing class FS_InvoiceManager {

	private FS_InvoiceManager() {
	}

	// RETIRING THIS ... no longer needed, as we are doing this in onNewInvoice instead
	// For SVMXCFG-607 - copy billing address from account into proforma invoice - added 6/18/18
//	public static void copyBillingAddressFromAcct(List<FS_Proforma_Invoice_Line__c> invDetList)
//	{
//		Set<Id> setIds = new Set<ID>();
//		for (FS_Proforma_Invoice_Line__c invDet : invDetList)
//		{
//			setIds.add(invDet.id);
//		}
//
//		Map<Id,FS_Proforma_Invoice_Line__c> mapIds = new Map<Id,FS_Proforma_Invoice_Line__c>(
//		[SELECT Id, Proforma_Invoice__c,
//				Proforma_Invoice__r.Account__r.BillingStreet,
//				Proforma_Invoice__r.Account__r.BillingCity,
//				Proforma_Invoice__r.Account__r.BillingState,
//				Proforma_Invoice__r.Account__r.BillingPostalCode
//		FROM FS_Proforma_Invoice_Line__c WHERE Id IN :setIds]);
//
//		List<FS_Proforma_Invoice__c> invToUpd = new List<FS_Proforma_Invoice__c>();
//
//		for (FS_Proforma_Invoice_Line__c invDetUpd : mapIds.values())
//		{
//			FS_Proforma_Invoice__c inv = invDetUpd.Proforma_Invoice__r;
//			if(inv != null && inv.Account__r != null)
//			{
//				inv.Billing_Street__c = inv.Account__r.BillingStreet;
//				inv.Billing_City__c = inv.Account__r.BillingCity;
//				inv.Billing_State__c = inv.Account__r.BillingState;
//				inv.Billing_Postal_Code__c = inv.Account__r.BillingPostalCode;
//				invToUpd.add(inv);
//			}
//		}
//		update invToUpd;
//	}

	/**
   * Should be called from the BEFORE INSERT Trigger
   * SVMXINT-654 When Cancelation Invoices are received from SAP, change all Amount fields to negative
   */
	public static void updateCancelationDetailFields(List<FS_Proforma_Invoice_Line__c> invDetList, Map<Id, FS_Proforma_Invoice_Line__c> oldMap)
	{
		if (!FS_Utility.isActive('Cancelation Detail Fields', 'Update Detail fields for Cancelation Proforma Invoices.')) { return; }

		Set<Id> invIds = new Set<Id>();
		for (FS_Proforma_Invoice_Line__c detail : invDetList)
		{
			invIds.add(detail.Proforma_Invoice__c);
		}

		Map<Id, FS_Proforma_Invoice__c> invMap = new Map<Id, FS_Proforma_Invoice__c>(
				[SELECT Id, Name, Canceled_On__c FROM FS_Proforma_Invoice__c WHERE Id IN :invIds]);
		for (FS_Proforma_Invoice_Line__c detail : invDetList)
		{
			FS_Proforma_Invoice__c inv = invMap.get(detail.Proforma_Invoice__c);
			if (inv != null && inv.Canceled_On__c != null)
			{
				detail.NetAmount__c = negative(detail.NetAmount__c);
				detail.TaxAmount__c = negative(detail.TaxAmount__c);
				detail.Total_Line_Price__c = negative(detail.Total_Line_Price__c);
			}
		}
	}

	private static Decimal negative(Decimal amount)
	{
		if (amount != null)
		{
			amount = Math.abs(amount) * -1.00;
		}
		return amount;
	}

	// RETIRING THIS ... no longer needed, as we are doing this in onNewInvoice instead
	// JIRA #389 - Populate Account on Proforma Invoice, from WO
//	public static void updateDetailFields(List<FS_Proforma_Invoice_Line__c> invDetList, Map<Id, FS_Proforma_Invoice_Line__c> oldMap)
//	{
//		if (!FS_Utility.isActive('Update Detail Fields', 'Update Account in Proforma Invoice.'))
//			return;
//
//		Set<Id> wdIds = new Set<Id>();
//		for (FS_Proforma_Invoice_Line__c detail : invDetList)
//		{
//			FS_Proforma_Invoice_Line__c old = (oldMap == null) ? null : oldMap.get(detail.Id);
//			if (detail.Work_Order_Line_Item__c != null)
//			{
//				wdIds.add(detail.Work_Order_Line_Item__c);
//			}
//		}
//
//		if (wdIds.isEmpty())
//			return;
//
//		List<WorkOrderLineItem> wdList = [select id,WorkOrderId from WorkOrderLineItem where Id IN:wdIds];
//		Map<Id,Id> wdWOIdMap = new Map<Id,Id>();
//		for (WorkOrderLineItem detail : wdList)
//		{
//			wdWOIdMap.put(detail.id,detail.WorkOrderId);
//		}
//
//		Map<Id, FS_Proforma_Invoice__c> invMap = new Map<Id, FS_Proforma_Invoice__c>();
//		Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>(
//				[SELECT Id, AccountId FROM WorkOrder WHERE Id IN :wdWOIdMap.values()]);
//		for (FS_Proforma_Invoice_Line__c detail : invDetList)
//		{
//			FS_Proforma_Invoice_Line__c old = (oldMap == null) ? null : oldMap.get(detail.Id);
//			if (detail.Work_Order_Line_Item__c != null)
//			{
//				WorkOrder wo = woMap.get(wdWOIdMap.get(detail.Work_Order_Line_Item__c));
//				if (wo != null && wo.AccountId != null)
//				{
//					FS_Proforma_Invoice__c inv = new FS_Proforma_Invoice__c();
//					inv.Id = detail.Proforma_Invoice__c;
//					inv.Account__c = wo.AccountId;
//					inv.Work_Order__c = wo.Id;
//					invMap.put(inv.Id, inv);
//				}
//			}
//		}
//
//		if (!invMap.isEmpty())
//			update invMap.values();
//	}

	public static void adjustDMR(List<FS_Proforma_Invoice_Line__c> invLineNewList, Map<Id, FS_Proforma_Invoice_Line__c> invLineOldMap)
	{
		if (!FS_Utility.isActive('Adjust DMR', 'Create WO Event and Update the Status Field to Locked in Proforma Invoice.'))
			return;

		Set<Id> invSet = new Set<Id>();
		Map<Id, FS_Proforma_Invoice__c> invUpdateMap = new Map<Id, FS_Proforma_Invoice__c>();
		List<FS_WorkOrder_Event__e> events = new List<FS_WorkOrder_Event__e>();

		for (FS_Proforma_Invoice_Line__c il : invLineNewList) {
			invSet.add(il.Proforma_Invoice__c);
		}

		Map<Id, FS_Proforma_Invoice__c> invRecordTypeMap = new Map<Id, FS_Proforma_Invoice__c>(
				[Select Id, Status__c from FS_Proforma_Invoice__c Where Id in :invSet]);

		for (FS_Proforma_Invoice_Line__c invLine : invLineNewList)
		{
			FS_Proforma_Invoice__c invoice = invRecordTypeMap.get(invLine.Proforma_Invoice__c);
			FS_Proforma_Invoice_Line__c old = (invLineOldMap == null) ? null : invLineOldMap.get(invLine.id);
			if ( old != null &&
					(old.ServiceAmountAdjustment__c != invLine.ServiceAmountAdjustment__c
							|| old.ServiceAmountAdjustmentType__c != invLine.ServiceAmountAdjustmentType__c
							|| old.ServicePercentAdjustment__c != invLine.ServicePercentAdjustment__c
							|| old.ServicePercentAdjustmentType__c != invLine.ServicePercentAdjustmentType__c
							|| old.ReplacementBasePrice__c != invLine.ReplacementBasePrice__c
							|| old.ContractPercentDiscount__c != invLine.ContractPercentDiscount__c
							|| old.EInvoice_Code_1__c != invLine.EInvoice_Code_1__c
							|| old.EInvoice_Code_2__c != invLine.EInvoice_Code_2__c
							|| old.EInvoice_Code_3__c != invLine.EInvoice_Code_3__c
							|| old.Material_Part_Description__c != invLine.Material_Part_Description__c)
					&& invoice != null &&  invoice.Status__c == 'Open')
			{
				if (invLine.AutoAdjust_InvoiceNotReq__c == TRUE)
				{
					// SVMXINT-566 DMR - Invoice Not Required - Event already sent in invoiceNotRequired(...) method
					continue;
				}

				if (invUpdateMap.containsKey(invLine.Proforma_Invoice__c))
				{
					continue; // Already processed this Invoice
				}

				FS_Proforma_Invoice__c inv = new FS_Proforma_Invoice__c(Id=invLine.Proforma_Invoice__c);
				// Update Invoice Status
				inv.Status__c = 'Locked';
				invUpdateMap.put(inv.Id, inv);
				// Create Work Order Event
				FS_WorkOrder_Event__e iEvent = new FS_WorkOrder_Event__e();
				iEvent.Action__c = 'ADJUST DMR';
				iEvent.InvoiceId__c = invLine.Proforma_Invoice__c;
				events.add(iEvent);
			}
		}
		if (!invUpdateMap.isEmpty())
			update invUpdateMap.values();

		if (!FS_Utility.isActive('Create WO Invoice Events', 'Create Work Order Platform Event when Proforma Invoice is Adjusted.'))
			return;

		FS_PlatformEventUtility.publishEvents(events, 'InvoiceId__c', 'Action__c');
	}
	private static Boolean PREVENT_CANCEL_INVOICE_EVENT = false;

	public static void cancelInvoice(List<FS_Proforma_Invoice__c> invNewList, Map<Id, FS_Proforma_Invoice__c> invOldMap)
	{
		if (!FS_Utility.isActive('Create Work Order Events', 'Create Work Order Platform Event when Proforma Invoice is Canceled.'))
			return;

		if (PREVENT_CANCEL_INVOICE_EVENT)
		{
			System.debug('Skipping cancelInvoice Event Logic.');
			return;
		}

		List<FS_WorkOrder_Event__e> events = new List<FS_WorkOrder_Event__e>();
		Set<Id> invoiceIds = new Set<Id>();
		Set<String> dmrNums = new Set<String>();
		for (FS_Proforma_Invoice__c inv : invNewList)
		{
			FS_Proforma_Invoice__c old = (invOldMap == null) ? null : invOldMap.get(inv.id);
			FS_WorkOrder_Event__e iEvent = new FS_WorkOrder_Event__e();
			if ( old != null && old.Status__c != inv.Status__c && inv.Status__c == 'Canceled'  ) {
				iEvent.Action__c = 'CANCEL BILLING';
				iEvent.InvoiceId__c = inv.Id;
				iEvent.SAP_InvoiceNumber__c  = inv.SAP_InvoiceNumber__c;
				events.add(iEvent);
				invoiceIds.add(inv.Id);
				if (inv.SAP_Invoice_DMR_Number__c != null)
					dmrNums.add(inv.SAP_Invoice_DMR_Number__c);
			}
		}
		system.debug('Events->'+events);

		if (!invoiceIds.isEmpty())
		{
			List<WorkOrder> wosToUpdate = new List<WorkOrder>();
			List<FS_Proforma_Invoice_Line__c> details = [SELECT Id,Work_Order_Line_Item__c, Work_Order_Line_Item__r.WorkOrderId, Work_Order_Line_Item__r.WorkOrder.Status
			FROM FS_Proforma_Invoice_Line__c WHERE Proforma_Invoice__c IN :invoiceIds];
			for (FS_Proforma_Invoice_Line__c detail : details)
			{
				if (detail.Work_Order_Line_Item__c != null)
				{
					WorkOrder wo = new WorkOrder();
					wo.Id = detail.Work_Order_Line_Item__r.WorkOrderId;
					wo.Status = 'Ready for Review';
					wosToUpdate.add(wo);
				}
			}
			if (!wosToUpdate.isEmpty())
				update wosToUpdate;
		}

		// JIRA #388 - Change DMR to "Open" when Invoice Cancelled
		if (!dmrNums.isEmpty())
		{
			List<FS_Proforma_Invoice__c> dmrInvoices = [SELECT Id, Status__c FROM FS_Proforma_Invoice__c WHERE SAP_DMR_Number__c IN :dmrNums];
			for (FS_Proforma_Invoice__c dmr : dmrInvoices)
			{
				dmr.Status__c = 'Open';
			}

			if (!dmrInvoices.isEmpty())
				update dmrInvoices;
		}

		FS_PlatformEventUtility.publishEvents(events, 'InvoiceId__c', 'Action__c');
	}

	public static void copyPriceAdjustments(List<FS_Proforma_Invoice__c> invNewList, Map<Id, FS_Proforma_Invoice__c> invOldMap)
	{
		if (!FS_Utility.isActive('Copy Price Adjustments', 'Copy Adjustments to Invoice Lines from Work Detail Lines.')) {
			return;
		}

		Map<Id, FS_Proforma_Invoice__c> invMap = new Map<Id, FS_Proforma_Invoice__c>();
		Set<Id> invLineSet = new Set<Id>();
		Set<Id> woIdSet = new Set<Id>();
		Set<Id> wdetailIdSet = new Set<Id>();
		List<FS_Proforma_Invoice_Line__c> invLineUpdateList = new List<FS_Proforma_Invoice_Line__c>();

		for (FS_Proforma_Invoice__c inv : invNewList)
		{
			FS_Proforma_Invoice__c old = (invOldMap == null) ? null : invOldMap.get(inv.Id);
			if (old != null
					&& old.CompletedTxnNumber__c != inv.CompletedTxnNumber__c
					&& inv.Status__c == 'New'
					&& inv.Type__c == 'DMR')
			{
				invMap.put(inv.Id, inv);
				if (inv.Work_Order__c != null) {
					woIdSet.add(inv.Work_Order__c);
				}
			}
		}

		if (woIdSet.isEmpty()) {
			return;
		}

		System.debug('~~ Trying to Copy Adjustments for Invoices: ' + invMap.keySet());

		// Lookup Invoice Details & Lines..
		List<FS_Proforma_Invoice_Line__c> invoiceDetails = [SELECT Id, Name, Proforma_Invoice__c,
				Work_Order_Line_Item__c, Product__c, Quantity__c
			FROM FS_Proforma_Invoice_Line__c WHERE Proforma_Invoice__c IN :invMap.keySet()];

		// Lookup WO & Work Details..
		// SVMXCFG-795 Copy E-Invoice Fields to Invoice from WO
		// SVMXCFG-950 Only copy from Usage lines (filter by record type)
		Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>([SELECT Id,
				ServiceContractId, ContractItem__c, ContractEntitlement__c,
				EInvoice_Platform_Id__c, EInvoice_Customer_Id__c,
				EInvoice_Code_1__c, EInvoice_Code_2__c, EInvoice_Code_3__c,
				(SELECT Id, LineItemNumber, Status, Line_Type__c, Quantity__c,
					ReplacementBasePrice__c, ContractPercentDiscount__c,
					ServicePercentAdjustment__c, ServiceAmountAdjustment__c,
					ServiceAmountAdjustmentType__c, ServicePercentAdjustmentType__c,
					EInvoice_Code_1__c, EInvoice_Code_2__c, EInvoice_Code_3__c,
					Material_Part_Description__c, Part__c, Part__r.Name
				FROM WorkOrderLineItems)
			FROM WorkOrder WHERE Id IN :woIdSet]);

		for (FS_Proforma_Invoice_Line__c invLine : invoiceDetails)
		{
			FS_Proforma_Invoice__c inv = invMap.get(invLine.Proforma_Invoice__c);
			Boolean anyUnmatchedLines = false;
			WorkOrder wo = woMap.get(inv.Work_Order__c);
			if (wo == null)
			{
				//System.debug('~~ Could not find WO: ' + invoiceDetail.WorkOrderID + ' for DMR Detail: ' + invoiceDetail.Id);
				continue;
			}

			// SVMXCFG-476 - Populate Contract Item and Contract Entitlement onto the Proforma Invoice
			inv.Contract_Item__c = wo.ContractItem__c;
			inv.Contract_Entitlement__c = wo.ContractEntitlement__c;

			// SVMXCFG-795 Copy E-Invoice Fields to Invoice from WO
			inv.EInvoice_Platform_Id__c = wo.EInvoice_Platform_Id__c;
			inv.EInvoice_Customer_Id__c = wo.EInvoice_Customer_Id__c;
			inv.EInvoice_Code_1__c = wo.EInvoice_Code_1__c;
			inv.EInvoice_Code_2__c = wo.EInvoice_Code_2__c;
			inv.EInvoice_Code_3__c = wo.EInvoice_Code_3__c;

			String lineNotes = null;
			WorkOrderLineItem match = null;
			// SVMXCFG-499: DMR Price Adjustments Improvements
			List<WorkOrderLineItem> matchingLines = new List<WorkOrderLineItem>();
			Decimal totalQty = 0;
			// Match-up each ProformaInvoiceLine to a WorkDetailLine.
			for (WorkOrderLineItem wd : wo.WorkOrderLineItems)
			{
				if (wd.Status == 'Canceled') {
					continue;
				}

				// The Work Detail lines must not be cancelled, and must have the same Product + Qty as the Proforma Line.
				if (invLine.Product__c == wd.Part__c && invLine.Quantity__c == wd.Quantity__c)
				{
					match = wd;
					lineNotes = 'Adjustments copied from Work Detail: ' + wd.LineItemNumber;
					break;
				}
				if (invLine.Product__c == wd.Part__c && invLine.Quantity__c != wd.Quantity__c)
				{
					matchingLines.add(wd);
					totalQty += wd.Quantity__c;
				}
			}

			// SVMXCFG-499: DMR Price Adjustments Improvements
			if (match == null && !matchingLines.isEmpty() && totalQty == invLine.Quantity__c)
			{
				// Found multiple lines to merge...
				Set<String> mergedLineNames = new Set<String>();
				Set<String> fieldsOutOfSync = new Set<String>();
				match = matchingLines.remove(0);
				Decimal totalAmtAdj = 0.00;
				if (match.ServiceAmountAdjustment__c != null)
				{
					totalAmtAdj = match.ServiceAmountAdjustment__c * (match.ServiceAmountAdjustmentType__c == 'Discount' ? -1.00 : 1.00);
				}
				mergedLineNames.add(match.LineItemNumber);
				for (WorkOrderLineItem line : matchingLines)
				{
					mergedLineNames.add(line.LineItemNumber);
					if (match.ContractPercentDiscount__c != line.ContractPercentDiscount__c)
					{
						match.ContractPercentDiscount__c = null;
						fieldsOutOfSync.add('Contract Discount');
					}
					if (match.ReplacementBasePrice__c != line.ReplacementBasePrice__c)
					{
						match.ReplacementBasePrice__c = null;
						fieldsOutOfSync.add('Replacement Base Price');
					}
					if (match.ServicePercentAdjustment__c != line.ServicePercentAdjustment__c || match.ServicePercentAdjustmentType__c != line.ServicePercentAdjustmentType__c)
					{
						match.ServicePercentAdjustment__c = null;
						match.ServicePercentAdjustmentType__c = null;
						fieldsOutOfSync.add('Service Percent Adjustment');
					}
					if (line.ServiceAmountAdjustment__c != null)
					{
						totalAmtAdj += line.ServiceAmountAdjustment__c * (line.ServiceAmountAdjustmentType__c == 'Discount' ? -1.00 : 1.00);
					}
					// SVMXCFG-897 Material Part Description
					if (match.Material_Part_Description__c != line.Material_Part_Description__c)
					{
						match.Material_Part_Description__c = null;
						fieldsOutOfSync.add('Material Part Description');
					}
				}

				if (totalAmtAdj == 0.00)
				{
					match.ServiceAmountAdjustment__c = null;
					match.ServiceAmountAdjustmentType__c = null;
				}
				else
				{
					match.ServiceAmountAdjustment__c = Math.abs(totalAmtAdj);
					match.ServiceAmountAdjustmentType__c = (totalAmtAdj < 0.00) ? 'Discount' : 'Uplift';
				}

				if (fieldsOutOfSync.isEmpty())
				{
					lineNotes = 'Adjustments copied from Work Details: ' + mergedLineNames;
				}
				else
				{
					anyUnmatchedLines = true;
					lineNotes = 'Adjustments partially copied from Work Details: ' + mergedLineNames
							+ ' ... but the following Adjustments were skipped because they were not consistent: '
							+ fieldsOutOfSync;
				}
			}

			if (match == null)
			{
				anyUnmatchedLines = true;
				lineNotes = 'No Adjustments were copied. No matching Work Detail(s) found.';
			}

			// Copy all of the pricing fields from the WorkDetails to the InvoiceLines
			FS_Proforma_Invoice_Line__c invLineUpd = new FS_Proforma_Invoice_Line__c(Id=invLine.Id);
			if (match != null)
			{
				// SVMXCFG-832 Adding back the Replacement Base Price
				invLineUpd.ReplacementBasePrice__c = (match.ReplacementBasePrice__c == null || match.ReplacementBasePrice__c == 0)
						? null : match.ReplacementBasePrice__c;
				invLineUpd.ContractPercentDiscount__c = match.ContractPercentDiscount__c;
				invLineUpd.ServiceAmountAdjustment__c = match.ServiceAmountAdjustment__c;
				invLineUpd.ServiceAmountAdjustmentType__c = match.ServiceAmountAdjustmentType__c;
				invLineUpd.ServicePercentAdjustment__c = match.ServicePercentAdjustment__c;
				invLineUpd.ServicePercentAdjustmentType__c = match.ServicePercentAdjustmentType__c;
				invLineUpd.Work_Order_Line_Item__c = match.Id;
				invLineUpd.Line_Type__c = match.Line_Type__c;

				// SVMXCFG-795 Copy E-Invoice Fields to Invoice Line from Work Detail
				invLineUpd.EInvoice_Code_1__c = match.EInvoice_Code_1__c;
				invLineUpd.EInvoice_Code_2__c = match.EInvoice_Code_2__c;
				invLineUpd.EInvoice_Code_3__c = match.EInvoice_Code_3__c;

				// SVMXCFG-897 Material Part Description
				// SVMXCFG-1002 DMR - Only Copy Material Description when changed
				if (match.Material_Part_Description__c != null
						&& match.Material_Part_Description__c != match.Part__r.Name)
				{
					invLineUpd.Material_Part_Description__c = match.Material_Part_Description__c;
				}
			}
			invLineUpd.Line_Notes__c = lineNotes;
			invLineUpdateList.add(invLineUpd);

			// IF any adjustments, set SMAX_PS_Lines_for_Review__c = TRUE
			if (invLineUpd.ReplacementBasePrice__c > 0.0 || invLineUpd.ContractPercentDiscount__c > 0.0
					|| invLineUpd.ServiceAmountAdjustment__c > 0.0 || invLineUpd.ServicePercentAdjustment__c > 0.0
					|| invLineUpd.Material_Part_Description__c != null)
			{
				inv.Lines_for_Review__c = true;
			}

			// Update the Invoice to 'Open' or 'Needs Review'
			inv.Status__c = (anyUnmatchedLines ? 'Needs Review' : 'Open');

		}

		if (!invLineUpdateList.isEmpty()) {
			update invLineUpdateList;
		}
	}

	public static void unlockDMR(List<FS_Proforma_Invoice__c> invNewList, Map<Id, FS_Proforma_Invoice__c> invOldMap)
	{
		if (!FS_Utility.isActive('Unlock DMR', 'Update the Status Field in Proforma Invoice.'))
			return;

		if (!invNewList.isEmpty()) {
			for (FS_Proforma_Invoice__c inv : invNewList)
			{
				FS_Proforma_Invoice__c old = (invOldMap == null) ? null : invOldMap.get(inv.id);
				if ( old != null && old.CompletedTxnNumber__c  != inv.CompletedTxnNumber__c && inv.Status__c == 'Locked' ) {
					inv.Status__c = 'Open';
				}
			}
		}
	}

	public static void defaultFields(List<FS_Proforma_Invoice__c> invNewList)
	{
		if (!FS_Utility.isActive('Default Fields', 'Update Status Field in Invoice.'))
			return;

		for (FS_Proforma_Invoice__c inv : invNewList)
		{
			if (inv.Status__c == null)
				inv.Status__c = 'New';
		}
	}
	private static String INVOICE_NOT_REQUIRED = 'Invoice Not Required';
	/*
	 *  SVMXINT-566 DMR - Invoice Not Required
	 *  Should be called from the BEFORE UPDATE trigger
	 */
	public static void invoiceNotRequired(List<FS_Proforma_Invoice__c> invNewList, Map<Id, FS_Proforma_Invoice__c> invOldMap)
	{
		if (!FS_Utility.isActive('Invoice Not Required', 'When Invoice Not Required is checked, auto discount all lines to 100% and change status.'))
			return;

		// Find "Invoice Not Required" where either it was just set or unlocked
		Map<Id, FS_Proforma_Invoice__c> invoicesToAdjust = new Map<Id, FS_Proforma_Invoice__c>();
		Map<Id, FS_Proforma_Invoice__c> invoicesToVerify = new Map<Id, FS_Proforma_Invoice__c>();
		for (FS_Proforma_Invoice__c inv : invNewList)
		{
			FS_Proforma_Invoice__c old = (invOldMap == null) ? null : invOldMap.get(inv.id);
			if (old != null && old.Status__c == INVOICE_NOT_REQUIRED && inv.Status__c != old.Status__c)
			{
				// SVMXINT-653 DMR: Invoice Not Required INFINITE-LOOP ... when Status changed back, uncheck also
				inv.Invoice_Not_Required__c = false;
			}

			if (old == null || inv.Invoice_Not_Required__c == false)
			{
				continue;
			}

			System.debug('Invoice Not Required.. ' + inv);
			if (old.Invoice_Not_Required__c == false)
			{
				// Invoice Not Required was just checked.. adjust to 100% if necessary
				invoicesToAdjust.put(inv.Id, inv);
			}
			else if (old.Status__c == 'Locked' && inv.Status__c == 'Open' )
			{
				// Invoice Not Required.. just Unlocked.. should be adjusted to 100% and done.
				invoicesToVerify.put(inv.Id, inv);
			}
		}

		// Need to verify both.. but only adjust the ones that havent been adjusted yet
		invoicesToVerify.putAll(invoicesToAdjust);

		if (invoicesToVerify.isEmpty())
			return;

		System.debug('Invoice Not Required.. ' + invoicesToVerify);

		Map<Id, List<FS_Proforma_Invoice_Line__c>> lineMap = new Map<Id, List<FS_Proforma_Invoice_Line__c>>();
		List<FS_Proforma_Invoice_Line__c> allLines = [SELECT Id, Name,Proforma_Invoice__c,
				ServicePercentAdjustment__c, ServicePercentAdjustmentType__c
		FROM FS_Proforma_Invoice_Line__c WHERE Proforma_Invoice__c IN :invoicesToVerify.keySet()];
		for (FS_Proforma_Invoice_Line__c line : allLines)
		{
			if (!lineMap.containsKey(line.Proforma_Invoice__c))
				lineMap.put(line.Proforma_Invoice__c, new List<FS_Proforma_Invoice_Line__c>());
			lineMap.get(line.Proforma_Invoice__c).add(line);
		}

		Set<Id> finishedInvoiceIds = new Set<Id>();
		List<FS_WorkOrder_Event__e> events = new List<FS_WorkOrder_Event__e>();
		List<FS_Proforma_Invoice_Line__c> linesToAdjust = new List<FS_Proforma_Invoice_Line__c>();
		for (Id invId : invoicesToVerify.keySet())
		{
			FS_Proforma_Invoice__c inv = invoicesToVerify.get(invId);
			List<FS_Proforma_Invoice_Line__c> lines = lineMap.get(invId);
			if (lines == null) lines = new List<FS_Proforma_Invoice_Line__c>();

			Boolean canAdjust = invoicesToAdjust.containsKey(invId);
			Boolean allDiscounted = TRUE;
			for (FS_Proforma_Invoice_Line__c line : lines)
			{
				// Find lines that need adjusting still
				if (line.ServicePercentAdjustment__c != 100 || line.ServicePercentAdjustmentType__c != 'Discount')
				{
					allDiscounted = FALSE;
					if (canAdjust)
					{
						line.ServicePercentAdjustment__c = 100;
						line.ServicePercentAdjustmentType__c = 'Discount';
						line.AutoAdjust_InvoiceNotReq__c = TRUE;
						linesToAdjust.add(line);
					}
					else
					{
						// WHAT DO WE DO?? Status = "ERROR"?  Don't want to cause an adjustment infinite loop...
						System.debug('Invoice Not Required.. but adjustment loop detected!!');
					}
				}
			}

			if (allDiscounted == TRUE)
			{
				inv.Status__c = INVOICE_NOT_REQUIRED;
				finishedInvoiceIds.add(inv.Id);
			}
			else
			{
				inv.Status__c = 'Locked';

				// Create Work Order Event
				FS_WorkOrder_Event__e iEvent = new FS_WorkOrder_Event__e();
				iEvent.Action__c = 'ADJUST DMR';
				iEvent.InvoiceId__c = inv.Id;
				events.add(iEvent);
			}
		}

		if (!linesToAdjust.isEmpty())
			update linesToAdjust;

		FS_PlatformEventUtility.publishEvents(events, 'InvoiceId__c', 'Action__c');

		if (finishedInvoiceIds.isEmpty())
			return;

		// Last step.. update the WO Status
		Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>();
		List<FS_Proforma_Invoice_Line__c> details = [SELECT Id, Name,Work_Order_Line_Item__c, Work_Order_Line_Item__r.WorkOrderId
		FROM FS_Proforma_Invoice_Line__c WHERE Proforma_Invoice__c IN :finishedInvoiceIds];
		for (FS_Proforma_Invoice_Line__c detail : details)
		{
			if (detail.Work_Order_Line_Item__c != null)
			{
				WorkOrder wo = new WorkOrder();
				wo.Id = detail.Work_Order_Line_Item__r.WorkOrderId;
				wo.Status = INVOICE_NOT_REQUIRED;
				woMap.put(wo.Id, wo);
			}
		}

		if (!woMap.isEmpty())
			update woMap.values();
	}

	/**
	 * Should be called from the BEFORE INSERT Trigger
	 * SVMXINT-654 When Invoices are received from SAP, determine if they are Cancellations by comparing their
	 * "SAP Invoice Number" to the "SAP Cancel Invoice Number" on existing Invoices
	 */
	public static void onCancellationInvoice(List<FS_Proforma_Invoice__c> invList)
	{
		if (!FS_Utility.isActive('Cancelation Invoices', 'Update Record Type for Cancelation Proforma Invoices.')) { return; }

		List<FS_Proforma_Invoice__c> invToLookup = new List<FS_Proforma_Invoice__c>();
		Set<String> invoiceNumbers = new Set<String>();
		for (FS_Proforma_Invoice__c inv : invList)
		{
			if ( inv.SAP_InvoiceNumber__c != null)
			{
				invoiceNumbers.add(inv.SAP_InvoiceNumber__c);
				invToLookup.add(inv);
			}
		}

		if (invoiceNumbers.isEmpty()) { return; }

		Map<String, FS_Proforma_Invoice__c> canceledInvoices = new Map<String, FS_Proforma_Invoice__c>();
		for (FS_Proforma_Invoice__c inv : [SELECT Id, Name, SAP_CancelInvoiceNumber__c
			FROM FS_Proforma_Invoice__c
			WHERE SAP_CancelInvoiceNumber__c IN :invoiceNumbers])
		{
			canceledInvoices.put(inv.SAP_CancelInvoiceNumber__c, inv);
		}

		for (FS_Proforma_Invoice__c inv : invToLookup)
		{
			if (canceledInvoices.containsKey(inv.SAP_InvoiceNumber__c))
			{
				// Found a Canceled Invoice that matches this Invoice Number
				inv.Type__c = 'Cancelation';
				inv.Status__c = 'New';
			}
		}
	}
	/**
	 * Should be called from the BEFORE INSERT/UPDATE Trigger
	 * SVMXCFG-1144 When Invoices are received from SAP, copy the Invoice Number to the assoc DMR if necessary
	 */
	public static void onNewInvoice(List<FS_Proforma_Invoice__c> invList)
	{
		if (!FS_Utility.isActive('On New Invoice', 'When Invoices are received from SAP, copy the Invoice Number to the assoc DMR if necessary.')) {
			return;
		}

		// Link the Invoice to the DMR and the WO
		Map<String, String> dmrInvMap = new Map<String, String>();
		Map<String, FS_Proforma_Invoice__c> invMap = new Map<String, FS_Proforma_Invoice__c>();
		for (FS_Proforma_Invoice__c inv : invList)
		{
			if (String.isNotBlank(inv.SAP_InvoiceNumber__c) && String.isNotBlank(inv.SAP_Invoice_DMR_Number__c))
			{
				dmrInvMap.put(inv.SAP_Invoice_DMR_Number__c, inv.SAP_InvoiceNumber__c);
				invMap.put(inv.SAP_InvoiceNumber__c, inv);
			}
		}

		if (!dmrInvMap.isEmpty()) {
			List<FS_Proforma_Invoice__c> dmrList = [SELECT Id, Name,
					SAP_DMR_Number__c, SAP_DMR_InvoiceNumber__c, Work_Order__c
				FROM FS_Proforma_Invoice__c
				WHERE SAP_DMR_Number__c IN :dmrInvMap.keySet() ];
			for (FS_Proforma_Invoice__c dmr : dmrList)
			{
				String invNum = dmrInvMap.get(dmr.SAP_DMR_Number__c);
				if (invNum != null && dmr.SAP_DMR_InvoiceNumber__c == null)
				{
					dmr.SAP_DMR_InvoiceNumber__c = invNum;
				}
				FS_Proforma_Invoice__c inv = invMap.get(invNum);
				if (dmr.Work_Order__c != null && inv != null && inv.Work_Order__c == null) {
					inv.Work_Order__c = dmr.Work_Order__c;
				}
			}

			if (!dmrList.isEmpty())
			{
				update dmrList;
			}
		}

		// Copy the Account from the WO
		Set<Id> woIds = new Set<Id>();
		List<FS_Proforma_Invoice__c> invToUpdate = new List<FS_Proforma_Invoice__c>();
		for (FS_Proforma_Invoice__c inv : invList)
		{
			if (inv.Work_Order__c != null && inv.Account__c == null)
			{
				woIds.add(inv.Work_Order__c);
				invToUpdate.add(inv);
			}
		}

		if (!woIds.isEmpty()) {
			Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>([SELECT Id, AccountId,
					Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode,
					Status
				FROM WorkOrder WHERE Id IN :woIds]);
			List<WorkOrder> woUpdates = new List<WorkOrder>();
			for (FS_Proforma_Invoice__c inv : invToUpdate) {
				WorkOrder wo = woMap.get(inv.Work_Order__c);
				if (wo != null && wo.AccountId != null) {
					inv.Account__c = wo.AccountId;
					inv.Billing_Street__c = wo.Account.BillingStreet;
					inv.Billing_City__c = wo.Account.BillingCity;
					inv.Billing_State__c = wo.Account.BillingState;
					inv.Billing_Postal_Code__c = wo.Account.BillingPostalCode;

					if (inv.Type__c == 'Invoice') {
						wo.Status = 'Invoiced';
						woUpdates.add(wo);
					}
				}
			}

			if (!woUpdates.isEmpty()) {
				update woUpdates;
			}
		}
	}

	public static void rejectDMR(List<FS_Proforma_Invoice__c> invNewList, Map<Id, FS_Proforma_Invoice__c> invOldMap)
	{
		if (!FS_Utility.isActive('Create Work Order Events', 'Create Work Order Platform Event when Proforma Invoice is Rejected.')) {
			return;
		}

		List<FS_WorkOrder_Event__e> events = new List<FS_WorkOrder_Event__e>();
		Set<String> invoiceNumbersToCancel = new Set<String>();
		Set<Id> woIds = new Set<Id>();
		for (FS_Proforma_Invoice__c inv : invNewList)
		{
			FS_Proforma_Invoice__c old = (invOldMap == null) ? null : invOldMap.get(inv.Id);
			if ( old != null && old.Status__c != inv.Status__c && inv.Status__c == 'Rejected'  ) {
				FS_WorkOrder_Event__e iEvent = new FS_WorkOrder_Event__e();
				iEvent.Action__c = 'CANCEL BILLING';
				iEvent.InvoiceId__c = inv.Id;
				iEvent.SAP_DMR_Number__c = inv.SAP_DMR_Number__c;
				if (String.isNotBlank(inv.SAP_DMR_InvoiceNumber__c))
				{
					// If Invoice Number has already been generated, Need to Cancel Invoice also..
					iEvent.SAP_InvoiceNumber__c  = inv.SAP_DMR_InvoiceNumber__c;
					invoiceNumbersToCancel.add(inv.SAP_DMR_InvoiceNumber__c);
				}
				events.add(iEvent);
				if (inv.Work_Order__c != null) {
					woIds.add(inv.Work_Order__c);
				}
			}
		}
		System.debug('Events->'+events);

		if (!invoiceNumbersToCancel.isEmpty())
		{
			// Update the Invoice to "Canceled" Status if it exists
			List<FS_Proforma_Invoice__c> invoicesToCancel = [SELECT Id, Name, Status__c, SAP_InvoiceNumber__c
			FROM FS_Proforma_Invoice__c
			WHERE SAP_InvoiceNumber__c IN :invoiceNumbersToCancel];
			for (FS_Proforma_Invoice__c inv : invoicesToCancel)
			{
				inv.Status__c = 'Canceled';
			}
			// The following flag makes sure we do not send 2 WO 'CANCEL BILLING' events
			PREVENT_CANCEL_INVOICE_EVENT = true;
			if (!invoicesToCancel.isEmpty()) {
				update invoicesToCancel;
			}
		}

		if (!woIds.isEmpty())
		{
			List<WorkOrder> wosToUpdate = new List<WorkOrder>();
			for (Id woId : woIds)
			{
				WorkOrder wo = new WorkOrder();
				wo.Id = woId;
				wo.Status = 'DMR Rejected';
				wosToUpdate.add(wo);
			}

			if (!wosToUpdate.isEmpty()) {
				update wosToUpdate;
			}
		}

		FS_PlatformEventUtility.publishEvents(events, 'InvoiceId__c', 'Action__c');
	}

	// Get Record Type Id for DMR Invoices
	public static void releaseInvoice(List<FS_Proforma_Invoice__c> invNewList, Map<Id, FS_Proforma_Invoice__c> invOldMap)
	{
		if (!FS_Utility.isActive('Create Work Order Events', 'Create Work Order Platform Event when Proforma Invoice is released.'))
			return;

		List<FS_WorkOrder_Event__e> events = new List<FS_WorkOrder_Event__e>();

		if (!invNewList.isEmpty()){

			for (FS_Proforma_Invoice__c inv : invNewList)
			{
				FS_Proforma_Invoice__c old = (invOldMap == null) ? null : invOldMap.get(inv.id);
				FS_WorkOrder_Event__e iEvent = new FS_WorkOrder_Event__e();
				if ( old != null && old.Status__c != inv.Status__c && inv.Status__c == 'Released'  ) {
					iEvent.Action__c = 'RELEASE INVOICE';
					iEvent.InvoiceId__c = inv.Id;
					iEvent.SAP_DMR_Number__c = inv.SAP_DMR_Number__c;
					events.add(iEvent);
				}
			}
			system.debug('Events->'+events);
		}

		FS_PlatformEventUtility.publishEvents(events, 'SMAX_PS_InvoiceId__c', 'SMAX_PS_Action__c');
	}
	public static void reviewDMRAdjustments(List<FS_Proforma_Invoice__c> invNewList, Map<Id, FS_Proforma_Invoice__c> invOldMap)
	{
		if (!FS_Utility.isActive('Review Adjustments', 'Review and Release DMR Adjustments.'))
			return;

		Map<Id, FS_Proforma_Invoice__c> invUpdateMap = new Map<Id, FS_Proforma_Invoice__c>();
		Map<Id, FS_Proforma_Invoice__c> invMap = new Map<Id, FS_Proforma_Invoice__c>();
		List<FS_WorkOrder_Event__e> events = new List<FS_WorkOrder_Event__e>();
		for (FS_Proforma_Invoice__c invoice : invNewList)
		{
			FS_Proforma_Invoice__c old = (invOldMap == null) ? null : invOldMap.get(invoice.id);
			if ( old != null && old.Adjustments_Reviewed__c != invoice.Adjustments_Reviewed__c  )
			{
				invMap.put(invoice.Id, invoice);

				// SVMXCFG-795 Make sure a DMR is sent for E-Invoice DMR header values..
				if (invoice.EInvoice_Platform_Id__c != null || invoice.EInvoice_Customer_Id__c != null
						|| invoice.EInvoice_Code_1__c != null || invoice.EInvoice_Code_2__c != null
						|| invoice.EInvoice_Code_3__c != null)
				{
					FS_Proforma_Invoice__c inv = new FS_Proforma_Invoice__c(Id=invoice.Id);
					// Update Invoice Status
					inv.Status__c = 'Locked';
					invUpdateMap.put(inv.Id, inv);
					// Create Work Order Event
					FS_WorkOrder_Event__e iEvent = new FS_WorkOrder_Event__e();
					iEvent.Action__c = 'ADJUST DMR';
					iEvent.InvoiceId__c = invoice.Id;
					events.add(iEvent);
				}
			}
		}

		// Select the Invoice Lines that qualify for adjustments related to the passed DMR Invoices
		List<FS_Proforma_Invoice_Line__c> invLineList = new List<FS_Proforma_Invoice_Line__c>([SELECT Id, Name,
				ServiceAmountAdjustment__c, ServicePercentAdjustment__c,Proforma_Invoice__c
		FROM FS_Proforma_Invoice_Line__c WHERE Proforma_Invoice__c IN :invMap.keySet()
		AND (ServiceAmountAdjustment__c > 0.0 OR ServicePercentAdjustment__c > 0.0
		OR ReplacementBasePrice__c > 0.0 OR ContractPercentDiscount__c > 0.0
		OR EInvoice_Code_1__c != null OR EInvoice_Code_2__c != null
		OR EInvoice_Code_3__c != null OR Material_Part_Description__c != null)]);
		if (!invLineList.isEmpty())
		{
			for (FS_Proforma_Invoice_Line__c invLine : invLineList)
			{
				if (invUpdateMap.containsKey(invLine.Proforma_Invoice__c)) {
					continue; // Already processed this Invoice
				}

				FS_Proforma_Invoice__c inv = new FS_Proforma_Invoice__c(Id = invLine.Proforma_Invoice__c);
				// Update Invoice Status
				inv.Status__c = 'Locked';
				invUpdateMap.put(inv.Id, inv);
				// Create Work Order Event
				FS_WorkOrder_Event__e iEvent = new FS_WorkOrder_Event__e();
				iEvent.Action__c = 'ADJUST DMR';
				iEvent.InvoiceId__c = invLine.Proforma_Invoice__c;
				events.add(iEvent);
			}
		}

		if (!invUpdateMap.isEmpty())
			update invUpdateMap.values();

		if (!FS_Utility.isActive('Create WO Invoice Events', 'Create Work Order Platform Event when Proforma Invoice is Adjusted.'))
			return;

		FS_PlatformEventUtility.publishEvents(events, 'InvoiceId__c', 'Action__c');
	}

	//SVMXCFG-591
	public static void updateRejectionReason(List <FS_Proforma_Invoice__c> newList, Map <Id, FS_Proforma_Invoice__c> oldMap)
	{
		System.debug('~~ Trying to update Rejection Reason.');

		//list of work orders that have updated rejection reasons
		List <WorkOrder> updatedWoList = new List <WorkOrder>();
		//iterate through updated proforma invoice records
		set<Id> wdids=new set<Id>();
		for (FS_Proforma_Invoice__c pf : newList)
		{
			wdids.add(pf.Work_Order__c);
		}


		for (FS_Proforma_Invoice__c pf : newList)
		{
			//get string of old value of rejection reason
			String oldRejectionReason = (oldMap == null) ? null :
					oldMap.get(pf.id).Rejection_Reason__c;

			//assess if rejection reason has been updated
			if(pf.Work_Order__c != null && pf.Rejection_Reason__c != oldRejectionReason)
			{
				WorkOrder wo = new WorkOrder();
				wo.Id = pf.Work_Order__c;
				//pass rejection reason from proforma invoice to rejection reason on the work order
				wo.Rejection_Reason__c = pf.Rejection_Reason__c;
				//add the work orders to updated list
				updatedWoList.add(wo);
				System.debug('~~ Updated WO Rejection Reason: ' + wo);
			}
		}

		//null check for updatedWoList
		if(updatedWoList.size()>0)
		{
			//update wo list
			update updatedWoList;
		}
	}

}