/*
  Test Class for  SMAX_PS_InvoiceManager
  Client      :   PerkinElmer
  Created by  :   Veerendra on 2017-11-16
*/
@IsTest(SeeAllData=false)
public class FS_Invoice_UT
{
	@TestSetup
	static void setupTestData() {
		FS_TestDataFactory.createDefaultOperatingHours();
	}

	@IsTest
	static void dmrInvoiceCreateCancel()
	{
		Account acct = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
		Contact cont = FS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
		Schema.Location loc = FS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', 'TST001');
		Asset ip = FS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TEST01');
		WorkOrder wo = FS_TestDataFactory.createWO(ip, cont);

		// Insert DMR Invoice
		FS_Proforma_Invoice__c dmr = new FS_Proforma_Invoice__c( Status__c='Open', Type__c='DMR');
		// SVMXCFG-1144 make sure this gets auto populated now...
		//dmr.SMAX_PS_SAP_DMR_InvoiceNumber__c = 'ABC12345678';
		dmr.SAP_DMR_Number__c = 'DEF0001001001';
		dmr.Work_Order__c = wo.Id;
		insert dmr;

		/*SVMXC__Proforma_Invoice_Detail__c dmrDetail = new SVMXC__Proforma_Invoice_Detail__c();
		dmrDetail.FS_Proforma_Invoice__c = dmr.Id;
		dmrDetail.SVMXC__Work_Order__c = wo.Id;
		insert dmrDetail;*/

		FS_Proforma_Invoice_Line__c dmrLine = new FS_Proforma_Invoice_Line__c();
		//dmrLine.SVMXC__Proforma_Invoice_Detail__c = dmrDetail.Id;
		dmrLine.Proforma_Invoice__c = dmr.Id;
		insert dmrLine;

		dmr.Status__c='Released';
		update dmr;

		/* FS_Proforma_Invoice__c dmrResult = [SELECT Id, Name, Work_Order__c, SMAX_PS_SAP_DMR_InvoiceNumber__c
		   FROM FS_Proforma_Invoice__c WHERE Id = :dmr.Id];
		 System.assertEquals(wo.Id, dmrResult.SMAX_PS_Work_Order__c);
		 System.assertEquals(null, dmrResult.SMAX_PS_SAP_DMR_InvoiceNumber__c);*/

		dmr.Status__c='Rejected';
		dmr.Rejection_Reason__c = 'Duplicate';
		update dmr;

		// WorkOrder woResult = [SELECT Id, Name, SMAX_PS_Rejection_Reason__c FROM WorkOrder WHERE Id = :wo.Id];
		// System.assertEquals(dmr.SMAX_PS_Rejection_Reason__c, woResult.SMAX_PS_Rejection_Reason__c);

		Test.startTest();

		// Insert Invoice
		FS_Proforma_Invoice__c inv = new FS_Proforma_Invoice__c(
				Type__c='Invoice',
				Status__c='Open');
		inv.SAP_InvoiceNumber__c = 'ABC12345678';
		inv.SAP_Invoice_DMR_Number__c = 'DEF0001001001';
		insert inv;

		/*dmrResult = [SELECT Id, Name, SMAX_PS_Work_Order__c, SMAX_PS_SAP_DMR_InvoiceNumber__c
		  FROM FS_Proforma_Invoice__c WHERE Id = :dmr.Id];
		// SVMXCFG-1144 make sure this gets auto populated now...
		System.assertEquals(inv.SMAX_PS_SAP_InvoiceNumber__c, dmrResult.SMAX_PS_SAP_DMR_InvoiceNumber__c);

		SVMXC__Proforma_Invoice_Detail__c invDetail = new SVMXC__Proforma_Invoice_Detail__c();
		invDetail.FS_Proforma_Invoice__c = inv.Id;
		invDetail.SVMXC__Work_Order__c = wo.Id;
		invDetail.SMAX_PS_TotalNetAmount__c = 180.00;
		invDetail.SMAX_PS_TotalTaxAmount__c = 20.00;
		invDetail.SVMXC__Total_Amount__c = 200.00;
		insert invDetail;*/

		FS_Proforma_Invoice_Line__c invLine = new FS_Proforma_Invoice_Line__c();
		//invLine.SVMXC__Proforma_Invoice_Detail__c = invDetail.Id;
		invLine.Proforma_Invoice__c = inv.Id;
		invLine.NetAmount__c = 180.00;
		invLine.TaxAmount__c = 20.00;
		invLine.Total_Line_Price__c = 200.00;
		insert invLine;

		inv.Status__c='Canceled';
		inv.SAP_CancelInvoiceNumber__c = 'CANC12345678';
		update inv;

		/* FS_Proforma_Invoice__c invResult = [SELECT Id, Name, SMAX_PS_Work_Order__c, RecordType.Name,
		   (SELECT Id, Name, SVMXC__Total_Amount__c, SMAX_PS_TotalNetAmount__c, SMAX_PS_TotalTaxAmount__c
		   FROM SVMXC__Proforma_Invoice_Detail__r),
		   (SELECT Id, Name, SVMXC__Billable_Line_Price__c, SMAX_PS_NetAmount__c, SVMXC__Price__c,
			 SMAX_PS_TaxAmount__c, SVMXC__Total_Line_Price__c FROM SVMXC__Proforma_Invoice_Lines__r)
		   FROM FS_Proforma_Invoice__c WHERE Id = :inv.Id];
		 System.assertEquals(wo.Id, invResult.SMAX_PS_Work_Order__c);
		 System.assertEquals('Invoice', invResult.RecordType.Name);
		 for (SVMXC__Proforma_Invoice_Detail__c resultDet : invResult.SVMXC__Proforma_Invoice_Detail__r)
		 {
		   System.assert(resultDet.SVMXC__Total_Amount__c > 0, 'Invoice Total Amount should be positive');
		 }
		 for (FS_Proforma_Invoice_Line__c resultLine : invResult.SVMXC__Proforma_Invoice_Lines__r)
		 {
		   System.assert(resultLine.SVMXC__Total_Line_Price__c > 0, 'Invoice Line Total Line Price should be positive');
		 }*/

		// Insert Cancelation Invoice
		FS_Proforma_Invoice__c cancel = new FS_Proforma_Invoice__c(
				Type__c = 'Invoice',
				Status__c='Open');
		cancel.SAP_InvoiceNumber__c = 'CANC12345678';
		cancel.SAP_Invoice_DMR_Number__c = 'DEF0001001001';
		insert cancel;

		/*SVMXC__Proforma_Invoice_Detail__c cancelDetail = new SVMXC__Proforma_Invoice_Detail__c();
		cancelDetail.FS_Proforma_Invoice__c = cancel.Id;
		cancelDetail.SVMXC__Work_Order__c = wo.Id;
		cancelDetail.SMAX_PS_TotalNetAmount__c = 180.00;
		cancelDetail.SMAX_PS_TotalTaxAmount__c = 20.00;
		cancelDetail.SVMXC__Total_Amount__c = 200.00;
		insert cancelDetail;*/

		FS_Proforma_Invoice_Line__c cancelLine = new FS_Proforma_Invoice_Line__c();
		// cancelLine.SVMXC__Proforma_Invoice_Detail__c = cancelDetail.Id;
		cancelLine.Proforma_Invoice__c = cancel.Id;
		cancelLine.NetAmount__c = 180.00;
		cancelLine.TaxAmount__c = 20.00;
		cancelLine.Total_Line_Price__c = 200.00;
		insert cancelLine;

		/* FS_Proforma_Invoice__c cancelResult = [SELECT Id, Name, SMAX_PS_Work_Order__c, RecordType.Name,
		   (SELECT Id, Name, SVMXC__Total_Amount__c, SMAX_PS_TotalNetAmount__c, SMAX_PS_TotalTaxAmount__c
		   FROM SVMXC__Proforma_Invoice_Detail__r),
		   (SELECT Id, Name, SVMXC__Billable_Line_Price__c, SMAX_PS_NetAmount__c, SVMXC__Price__c,
			 SMAX_PS_TaxAmount__c, SVMXC__Total_Line_Price__c FROM SVMXC__Proforma_Invoice_Lines__r)
		   FROM FS_Proforma_Invoice__c WHERE Id = :cancel.Id];
		 System.assertEquals(wo.Id, cancelResult.SMAX_PS_Work_Order__c);
		 System.assertEquals('Cancelation', cancelResult.RecordType.Name);
		 for (SVMXC__Proforma_Invoice_Detail__c resultDet : cancelResult.SVMXC__Proforma_Invoice_Detail__r)
		 {
		   System.assert(resultDet.SVMXC__Total_Amount__c < 0, 'Cancelation Total Amount should be negative');
		 }
		 for (FS_Proforma_Invoice_Line__c resultLine : cancelResult.SVMXC__Proforma_Invoice_Lines__r)
		 {
		   System.assert(resultLine.SVMXC__Total_Line_Price__c < 0, 'Cancelation Line Total Line Price should be negative');
		 }*/

		Test.stopTest();
	}

	@IsTest
	static void dmrAdjustments()
	{
		Account acct = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
		Contact cont = FS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
		Schema.Location loc = FS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', 'TST001');
		Asset ip = FS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TEST01');
		WorkOrder wo = FS_TestDataFactory.createWO(ip, cont);
		update wo;

		Product2 prod = FS_TestDataFactory.createTestProduct('Test Product', 'TPRD001', 'ZZZ');

		//Id usageRecTypeId = FS_Utility.getRecordType('WorkOrderLineItem', 'UsageConsumption').Id;
		WorkOrderLineItem wd = new WorkOrderLineItem();
		wd.WorkOrderId = wo.Id;
		wd.Status = 'Priced';
		wd.Line_Type__c = 'Parts';
		wd.Unit_Price__c= 100.00;
		wd.Quantity__c= 2;
		wd.Part__c= prod.Id;
		wd.ServiceAmountAdjustment__c = 25.00;
		wd.ServiceAmountAdjustmentType__c = 'Uplift';
		// SVMXCFG-897 Material Part Description
		wd.Material_Part_Description__c = 'Frank was here';
		insert wd;

		// Get DMR Record type Id for Invoice
		//Id invDMRRecordTypeId = SMAX_PS_Utility.getRecordType('FS_Proforma_Invoice__c', 'DMR').Id;

		// Insert DMR Invoice
		FS_Proforma_Invoice__c inv = new FS_Proforma_Invoice__c();
		inv.Status__c='New';
		inv.Type__c = 'DMR';
		inv.Work_Order__c = wo.Id;
		insert inv;

		/*SVMXC__Proforma_Invoice_Detail__c det = new SVMXC__Proforma_Invoice_Detail__c();
		det.FS_Proforma_Invoice__c = inv.Id;
		det.SVMXC__Work_Order__c = wo.Id;
		insert det;*/

		FS_Proforma_Invoice_Line__c line = new FS_Proforma_Invoice_Line__c();
		//line.SVMXC__Proforma_Invoice_Detail__c = det.Id;
		line.Proforma_Invoice__c = inv.Id;
		line.Product__c = prod.Id;
		line.Quantity__c = 2;
		insert line;

		inv.CompletedTxnNumber__c = 'TST000000001';
		update inv;

		// Copy Price Adjustments should run...
		/*FS_Proforma_Invoice_Line__c result = [SELECT Id, Name, SMAX_PS_ContractPercentDiscount__c,
			SMAX_PS_ServiceAmountAdjustment__c, SMAX_PS_ServiceAmountAdjustmentType__c,
			SVMXC__Proforma_Invoice__r.SVMXC__Status__c, SMAX_PS_Material_Part_Description__c
		FROM FS_Proforma_Invoice_Line__c WHERE Id = :line.Id];
		System.assertEquals(null, result.SMAX_PS_ContractPercentDiscount__c);
		System.assertEquals(wd.SMAX_PS_ServiceAmountAdjustment__c, result.SMAX_PS_ServiceAmountAdjustment__c);
		System.assertEquals(wd.SMAX_PS_ServiceAmountAdjustmentType__c, result.SMAX_PS_ServiceAmountAdjustmentType__c);
		System.assertEquals('Open', result.SVMXC__Proforma_Invoice__r.SVMXC__Status__c);
		System.assertEquals(wd.SMAX_PS_Material_Part_Description__c, result.SMAX_PS_Material_Part_Description__c);*/

		// Review and approve adjustments..
		inv.Adjustments_Reviewed__c = true;
		update inv;

		/* result = [SELECT Id, Name, SMAX_PS_ContractPercentDiscount__c,
			 SMAX_PS_ServiceAmountAdjustment__c, SMAX_PS_ServiceAmountAdjustmentType__c,
			 SVMXC__Proforma_Invoice__r.SVMXC__Status__c
		 FROM FS_Proforma_Invoice_Line__c WHERE Id = :line.Id];
		 System.assertEquals('Locked', result.SVMXC__Proforma_Invoice__r.SVMXC__Status__c);*/

		// Unlock DMR (simulate update back from SAP)
		inv.CompletedTxnNumber__c = 'TST000000002';
		update inv;

		/*result = [SELECT Id, Name, SMAX_PS_ContractPercentDiscount__c,
			SMAX_PS_ServiceAmountAdjustment__c, SMAX_PS_ServiceAmountAdjustmentType__c,
			SVMXC__Proforma_Invoice__r.SVMXC__Status__c
		FROM FS_Proforma_Invoice_Line__c WHERE Id = :line.Id];
		System.assertEquals('Open', result.SVMXC__Proforma_Invoice__r.SVMXC__Status__c);*/

		// Make Price Adjustments now..

		FS_Proforma_Invoice_Line__c lineUpdate = new FS_Proforma_Invoice_Line__c();
		lineUpdate.Id = line.Id;
		lineUpdate.ContractPercentDiscount__c = 10.00;
		update lineUpdate;

		/*result = [SELECT Id, Name, SMAX_PS_ContractPercentDiscount__c,
			SMAX_PS_ServiceAmountAdjustment__c, SMAX_PS_ServiceAmountAdjustmentType__c,
			SVMXC__Proforma_Invoice__r.SVMXC__Status__c
		FROM FS_Proforma_Invoice_Line__c WHERE Id = :line.Id];
		System.assertEquals(10.00, result.SMAX_PS_ContractPercentDiscount__c);
		System.assertEquals('Locked', result.SVMXC__Proforma_Invoice__r.SVMXC__Status__c);*/

		inv.CompletedTxnNumber__c = 'TST000000002';
		update inv;

	}

	@IsTest
	static void dmrEInvoiceAdjustments()
	{
		Account acct = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
		Contact cont = FS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
		Schema.Location loc = FS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', 'TST001');
		Asset ip = FS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TEST01');
		WorkOrder wo = FS_TestDataFactory.createWO(ip, cont);
		// SVMXCFG-795 Copy E-Invoice Fields to Invoice from WO
		wo.EInvoice_Platform_Id__c = 'PLATFORM00100101';
		wo.EInvoice_Customer_Id__c = 'CUSTOMER00100101';
		wo.EInvoice_Code_1__c = 'CODE1111111H';
		wo.EInvoice_Code_2__c = 'CODE2222222H';
		wo.EInvoice_Code_3__c = 'CODE3333333H';
		update wo;

		Product2 prod = FS_TestDataFactory.createTestProduct('Test Product', 'TPRD001', 'ZZZ');

		//Id usageRecTypeId = SMAX_PS_Utility.getRecordType('WorkOrderLineItem', 'UsageConsumption').Id;
		WorkOrderLineItem wd = new WorkOrderLineItem();
		wd.WorkOrderId = wo.Id;
		wd.Status = 'Priced';
		wd.Line_Type__c = 'Parts';
		wd.Unit_Price__c = 100.00;
		wd.Quantity__c = 2;
		wd.Part__c = prod.Id;
		wd.EInvoice_Code_1__c = 'CODE1111111';
		wd.EInvoice_Code_2__c = 'CODE2222222';
		wd.EInvoice_Code_3__c = 'CODE3333333';
		insert wd;

		// Get DMR Record type Id for Invoice
		// Id invDMRRecordTypeId = SMAX_PS_Utility.getRecordType('FS_Proforma_Invoice__c', 'DMR').Id;

		// Insert DMR Invoice
		FS_Proforma_Invoice__c inv = new FS_Proforma_Invoice__c();
		inv.Status__c='New';
		inv.Type__c='DMR';
		inv.Work_Order__c = wo.Id;
		insert inv;

		/*SVMXC__Proforma_Invoice_Detail__c det = new SVMXC__Proforma_Invoice_Detail__c();
		det.FS_Proforma_Invoice__c = inv.Id;
		det.SVMXC__Work_Order__c = wo.Id;
		insert det;*/

		FS_Proforma_Invoice_Line__c line = new FS_Proforma_Invoice_Line__c();
		// line.SVMXC__Proforma_Invoice_Detail__c = det.Id;
		line.Proforma_Invoice__c = inv.Id;
		line.Product__c = prod.Id;
		line.Quantity__c = 2;
		insert line;

		inv.CompletedTxnNumber__c = 'TST000000001';
		update inv;

		// Copy Price Adjustments should run...

		// SVMXCFG-795 Copy E-Invoice Fields to Invoice from WO
		/* FS_Proforma_Invoice__c invResult = [SELECT Id, Name,
			 SMAX_PS_EInvoice_Platform_Id__c, SMAX_PS_EInvoice_Customer_Id__c
		 FROM FS_Proforma_Invoice__c WHERE Id = :inv.Id];
		 System.assertEquals(wo.SMAX_PS_EInvoice_Platform_Id__c, invResult.SMAX_PS_EInvoice_Platform_Id__c);
		 System.assertEquals(wo.SMAX_PS_EInvoice_Customer_Id__c, invResult.SMAX_PS_EInvoice_Customer_Id__c);

		 FS_Proforma_Invoice_Line__c result = [SELECT Id, Name, SMAX_PS_ContractPercentDiscount__c,
			 SMAX_PS_ServiceAmountAdjustment__c, SMAX_PS_ServiceAmountAdjustmentType__c,
			 SVMXC__Proforma_Invoice__r.SVMXC__Status__c,
			 SMAX_PS_EInvoice_Code_1__c, SMAX_PS_EInvoice_Code_2__c, SMAX_PS_Material_Part_Description__c
		 FROM FS_Proforma_Invoice_Line__c WHERE Id = :line.Id];
		 System.assertEquals('Open', result.SVMXC__Proforma_Invoice__r.SVMXC__Status__c);
		 System.assertEquals(wd.SMAX_PS_EInvoice_Code_1__c, result.SMAX_PS_EInvoice_Code_1__c);
		 System.assertEquals(wd.SMAX_PS_EInvoice_Code_2__c, result.SMAX_PS_EInvoice_Code_2__c);
		 System.assertEquals(wd.SMAX_PS_Material_Part_Description__c, result.SMAX_PS_Material_Part_Description__c);*/

		// Review and approve adjustments..
		inv.Adjustments_Reviewed__c = true;
		update inv;

		/*result = [SELECT Id, Name, SMAX_PS_ContractPercentDiscount__c,
			SMAX_PS_ServiceAmountAdjustment__c, SMAX_PS_ServiceAmountAdjustmentType__c,
			SVMXC__Proforma_Invoice__r.SVMXC__Status__c
		FROM FS_Proforma_Invoice_Line__c WHERE Id = :line.Id];
		System.assertEquals('Locked', result.SVMXC__Proforma_Invoice__r.SVMXC__Status__c);*/

		// Unlock DMR (simulate update back from SAP)
		inv.CompletedTxnNumber__c = 'TST000000002';
		update inv;

		/*result = [SELECT Id, Name, SMAX_PS_ContractPercentDiscount__c,
			SMAX_PS_ServiceAmountAdjustment__c, SMAX_PS_ServiceAmountAdjustmentType__c,
			SVMXC__Proforma_Invoice__r.SVMXC__Status__c
		FROM FS_Proforma_Invoice_Line__c WHERE Id = :line.Id];
		System.assertEquals('Open', result.SVMXC__Proforma_Invoice__r.SVMXC__Status__c);*/

	}

	@IsTest
	static void testCopyAdjustmentsContract()
	{
		String modelSeries = 'TST001';
		String locCode = 'TSTC01';

		Account acct = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
		Contact c = FS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
		Schema.Location loc = FS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);

		Product2 prod = FS_TestDataFactory.createTestProduct('TestLabor', 'LAB10010', 'ZZZ', 'Labor');
		Product2 prod2 = FS_TestDataFactory.createTestProduct('TestSvcPart', 'TSP10010', 'ZZZ', 'Service Parts');

		Asset ip = FS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries, prod2);
		Date startDate = System.today().addDays(-30);
		Date endDate = startDate.addMonths(11);
		ServiceContract sc = FS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.AccountId, startDate, endDate);
		ServiceContract item = FS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate, prod2);
		ContractLineItem cp = FS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
		Entitlement ent = FS_TestDataFactory.createEntitlement(item,'REP', 0, 0);

		Test.startTest();

		WorkOrder wo = FS_TestDataFactory.createContractWO(ip, c);

		//Id usage = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Usage/Consumption').getRecordTypeId();
		WorkOrderLineItem wd = new WorkOrderLineItem(
				WorkOrderId=wo.Id,  Line_Type__c = 'Labor', Status='Confirmed',
				Part__c = prod.Id, Quantity__c = 1.5, ContractPercentDiscount__c = 100);
		List<WorkOrderLineItem> lines = new List<WorkOrderLineItem> { wd };
		insert lines;

		// Get DMR Record type Id for Invoice
		// Id invDMRRecordTypeId = SMAX_PS_Utility.getRecordType('FS_Proforma_Invoice__c', 'DMR').Id;

		// Insert DMR Invoice
		FS_Proforma_Invoice__c inv = new FS_Proforma_Invoice__c();
		inv.Status__c='New';
		inv.Type__c='DMR';
		inv.Work_Order__c = wo.Id;
		insert inv;

		/*SVMXC__Proforma_Invoice_Detail__c det = new SVMXC__Proforma_Invoice_Detail__c();
		det.FS_Proforma_Invoice__c = inv.Id;
		det.SVMXC__Work_Order__c = wo.Id;
		insert det;*/

		FS_Proforma_Invoice_Line__c line = new FS_Proforma_Invoice_Line__c();
		//line.SVMXC__Proforma_Invoice_Detail__c = det.Id;
		line.Proforma_Invoice__c = inv.Id;
		line.Product__c = prod.Id;
		line.Quantity__c = 2;
		insert line;

		inv.CompletedTxnNumber__c = 'TST000000001';
		update inv;

		/* // Copy Price Adjustments should run...
		 FS_Proforma_Invoice__c result = [SELECT Id, Name, SMAX_PS_Contract_Item__c, SMAX_PS_Contract_Entitlement__c
		 FROM FS_Proforma_Invoice__c WHERE Id = :inv.Id];
		 System.assertEquals(item.Id, result.SMAX_PS_Contract_Item__c);
		 System.assertEquals(ent.Id, result.SMAX_PS_Contract_Entitlement__c);*/
	}

	@IsTest
	static void testCopyAdjustmentsMergedLines()
	{
		String modelSeries = 'TST001';
		String locCode = 'TSTC01';

		Account acct = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
		Contact c = FS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
		Schema.Location loc = FS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);

		Product2 prod = FS_TestDataFactory.createTestProduct('TestLabor', 'LAB10010', 'ZZZ', 'Labor');
		Product2 prod2 = FS_TestDataFactory.createTestProduct('TestSvcPart', 'TSP10010', 'ZZZ', 'Service Parts');

		Asset ip = FS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries, prod2);
		Date startDate = System.today().addDays(-30);
		Date endDate = startDate.addMonths(11);
		ServiceContract sc = FS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.AccountId, startDate, endDate);
		ServiceContract item = FS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate, prod2);
		ContractLineItem cp = FS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
		Entitlement ent = FS_TestDataFactory.createEntitlement(item,'REP', 0, 0);

		WorkOrder wo = FS_TestDataFactory.createContractWO(ip, c);
		//WorkOrder wo = FS_TestDataFactory.createWO(ip, c);

		//Id usage = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Usage/Consumption').getRecordTypeId();
		WorkOrderLineItem wd1 = new WorkOrderLineItem(
				WorkOrderId=wo.Id,  Line_Type__c = 'Labor', Status='Confirmed',
				Part__c= prod.Id, Quantity__c = 1.5, ContractPercentDiscount__c = 100,
				ServiceAmountAdjustment__c = 50, ServiceAmountAdjustmentType__c = 'Discount',
				ServicePercentAdjustment__c = 5, ServicePercentAdjustmentType__c = 'Discount',
				Material_Part_Description__c = prod.Name);
		WorkOrderLineItem wd2 = new WorkOrderLineItem(
				WorkOrderId=wo.Id, Line_Type__c = 'Labor', Status='Confirmed',
				Part__c= prod.Id, Quantity__c = 2.5, ContractPercentDiscount__c = 100,
				ServiceAmountAdjustment__c = 70, ServiceAmountAdjustmentType__c = 'Uplift',
				ServicePercentAdjustment__c = 10, ServicePercentAdjustmentType__c = 'Discount',
				Material_Part_Description__c = prod.Name);
		WorkOrderLineItem wd3 = new WorkOrderLineItem(
				WorkOrderId=wo.Id, Line_Type__c = 'Parts', Status='Confirmed',
				Part__c= prod2.Id, Quantity__c = 1, ContractPercentDiscount__c = 50,
				Material_Part_Description__c = 'Custom');
		List<WorkOrderLineItem> lines = new List<WorkOrderLineItem> { wd1, wd2, wd3 };
		insert lines;

		Test.startTest();

		// Get DMR Record type Id for Invoice
		//Id invDMRRecordTypeId = SMAX_PS_Utility.getRecordType('FS_Proforma_Invoice__c', 'DMR').Id;

		// Insert DMR Invoice
		FS_Proforma_Invoice__c inv = new FS_Proforma_Invoice__c();
		inv.Status__c='New';
		inv.Type__c='DMR';
		inv.Work_Order__c = wo.Id;
		insert inv;

		/* SVMXC__Proforma_Invoice_Detail__c det = new SVMXC__Proforma_Invoice_Detail__c();
		 det.FS_Proforma_Invoice__c = inv.Id;
		 det.SVMXC__Work_Order__c = wo.Id;
		 insert det;*/

		FS_Proforma_Invoice_Line__c line1 = new FS_Proforma_Invoice_Line__c();
		//line1.SVMXC__Proforma_Invoice_Detail__c = det.Id;
		line1.Proforma_Invoice__c = inv.Id;
		line1.Product__c = prod.Id;
		line1.Quantity__c = 4;

		FS_Proforma_Invoice_Line__c line2 = new FS_Proforma_Invoice_Line__c();
		//line2.SVMXC__Proforma_Invoice_Detail__c = det.Id;
		line2.Proforma_Invoice__c = inv.Id;
		line2.Product__c = prod2.Id;
		line2.Quantity__c = 1;

		insert new List<FS_Proforma_Invoice_Line__c> { line1, line2 };

		inv.CompletedTxnNumber__c = 'TST000000001';
		update inv;

		// Copy Price Adjustments should run...
		/*FS_Proforma_Invoice__c result = [SELECT Id, Name, SMAX_PS_Contract_Item__c, SMAX_PS_Contract_Entitlement__c
		FROM FS_Proforma_Invoice__c WHERE Id = :inv.Id];
		System.assertEquals(item.Id, result.SMAX_PS_Contract_Item__c);
		System.assertEquals(ent.Id, result.SMAX_PS_Contract_Entitlement__c);

		FS_Proforma_Invoice_Line__c resultLine1 = [SELECT Id, Name, SVMXC__Line_Notes__c, SMAX_PS_ContractPercentDiscount__c,
			SMAX_PS_ServiceAmountAdjustment__c, SMAX_PS_ServiceAmountAdjustmentType__c,
			SMAX_PS_ServicePercentAdjustment__c, SMAX_PS_ServicePercentAdjustmentType__c,
			SMAX_PS_Material_Part_Description__c
		FROM FS_Proforma_Invoice_Line__c WHERE Id = :line1.Id];
		System.assert(resultLine1.SVMXC__Line_Notes__c.contains('Adjustments partially copied from Work Details:'));
		System.assert(resultLine1.SVMXC__Line_Notes__c.contains('Service Percent Adjustment'));
		System.assertEquals(null, resultLine1.SMAX_PS_ServicePercentAdjustment__c);
		System.assertEquals('Uplift', resultLine1.SMAX_PS_ServiceAmountAdjustmentType__c);
		System.assertEquals(20, resultLine1.SMAX_PS_ServiceAmountAdjustment__c);
		System.assertEquals(100, resultLine1.SMAX_PS_ContractPercentDiscount__c);

		FS_Proforma_Invoice_Line__c resultLine2 = [SELECT Id, Name, SVMXC__Line_Notes__c, SMAX_PS_ContractPercentDiscount__c,
			SMAX_PS_ServiceAmountAdjustment__c, SMAX_PS_ServiceAmountAdjustmentType__c,
			SMAX_PS_ServicePercentAdjustment__c, SMAX_PS_ServicePercentAdjustmentType__c,
			SMAX_PS_Material_Part_Description__c
		FROM FS_Proforma_Invoice_Line__c WHERE Id = :line2.Id];
		System.assert(resultLine2.SVMXC__Line_Notes__c.contains('Adjustments copied from Work Detail:'));
		System.assertEquals(null, resultLine2.SMAX_PS_ServicePercentAdjustment__c);
		System.assertEquals(null, resultLine2.SMAX_PS_ServiceAmountAdjustment__c);
		System.assertEquals(50, resultLine2.SMAX_PS_ContractPercentDiscount__c);

		// SVMXCFG-1002 DMR - Only Copy Material Description when changed
		System.assertEquals(null, resultLine1.SMAX_PS_Material_Part_Description__c); // Did not copy.. was not modified
		System.assertEquals(wd3.SMAX_PS_Material_Part_Description__c, resultLine2.SMAX_PS_Material_Part_Description__c); // Did copy.. was modified*/

		Test.stopTest();
	}

	// For SVMXCFG-607 - added 6/18/18
	@IsTest
	static void testCopyBillingAddressFromAcct()
	{
		Account acct = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
		FS_Proforma_Invoice__c inv = new FS_Proforma_Invoice__c();
		inv.Type__c='DMR';
		insert inv;
		// SVMXC__Proforma_Invoice_Detail__c invDet = new SVMXC__Proforma_Invoice_Detail__c();

		acct.BillingStreet = '123 Main St';
		acct.BillingCity = 'Fake City';
		acct.BillingState = 'North Carolina';
		acct.BillingPostalCode = '11111';
		acct.BillingCountry = 'United States';
		update acct;

		inv.Account__c = acct.Id;
		update inv;

		//invDet.FS_Proforma_Invoice__c = inv.id;

		//trigger to run
		Test.startTest();

		//insert invDet;

		Test.stopTest();

		/*FS_Proforma_Invoice__c invResult = [SELECT id, SVMXC__Billing_Street__c,SVMXC__Billing_City__c,SVMXC__Billing_State__c,SVMXC__Billing_Postal_Code__c
		FROM FS_Proforma_Invoice__c WHERE Id = :inv.Id];

		System.assertEquals(invResult.SVMXC__Billing_Street__c,acct.BillingStreet);
		System.assertEquals(invResult.SVMXC__Billing_City__c,acct.BillingCity);
		System.assertEquals(invResult.SVMXC__Billing_State__c,acct.BillingState);
		System.assertEquals(invResult.SVMXC__Billing_Postal_Code__c,acct.BillingPostalCode);*/

		// invDet.Quantity__c = 1;
		// update invDet;

		//delete invDet;
	}

	// SVMXINT-566 DMR - Invoice Not Required
	@IsTest
	static void testInvoiceNotRequired()
	{
		Account acct = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
		Contact cont = FS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
		Schema.Location loc = FS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', 'TST001');
		Asset ip = FS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TEST01');
		WorkOrder wo = FS_TestDataFactory.createWO(ip, cont);

		// Get DMR Record type Id for Invoice
		//Id invDMRRecordTypeId = SMAX_PS_Utility.getRecordType('FS_Proforma_Invoice__c', 'DMR').Id;

		// Insert DMR Invoice
		FS_Proforma_Invoice__c inv = new FS_Proforma_Invoice__c( Status__c='Open');
		inv.SAP_DMR_InvoiceNumber__c = 'ABC12345678';
		inv.SAP_DMR_Number__c = 'DEF0001001001';
		inv.Type__c='DMR';
		inv.Work_Order__c = wo.Id;
		insert inv;

		/*SVMXC__Proforma_Invoice_Detail__c det = new SVMXC__Proforma_Invoice_Detail__c();
		det.FS_Proforma_Invoice__c = inv.Id;
		det.SVMXC__Work_Order__c = wo.Id;
		insert det;*/

		FS_Proforma_Invoice_Line__c line = new FS_Proforma_Invoice_Line__c();
		//line.SVMXC__Proforma_Invoice_Detail__c = det.Id;
		line.Proforma_Invoice__c = inv.Id;
		insert line;

		Test.startTest();

		// This should cause an auto adjustment of the line to 100% Discount, and Lock the header..
		inv.Invoice_Not_Required__c = true;
		update inv;

		/*FS_Proforma_Invoice_Line__c lineResult = [SELECT Id, Name, SMAX_PS_ServicePercentAdjustment__c,
			SMAX_PS_ServicePercentAdjustmentType__c, SMAX_PS_AutoAdjust_InvoiceNotReq__c
		FROM FS_Proforma_Invoice_Line__c WHERE Id = :line.Id];
		System.assertEquals(100, lineResult.SMAX_PS_ServicePercentAdjustment__c);
		System.assertEquals('Discount', lineResult.SMAX_PS_ServicePercentAdjustmentType__c);
		System.assertEquals(TRUE, lineResult.SMAX_PS_AutoAdjust_InvoiceNotReq__c);

		FS_Proforma_Invoice__c invResult = [SELECT Id, Name, SVMXC__Status__c FROM FS_Proforma_Invoice__c WHERE Id = :inv.Id];
		System.assertEquals('Locked', invResult.SVMXC__Status__c);*/

		// Simulate the SAP response now..
		inv.CompletedTxnNumber__c = 'TST000000001';
		update inv;

		Test.stopTest();

		/*FS_Proforma_Invoice__c invResult2 = [SELECT Id, Name, SVMXC__Status__c FROM FS_Proforma_Invoice__c WHERE Id = :inv.Id];
		System.assertEquals('Invoice Not Required', invResult2.SVMXC__Status__c);

		WorkOrder woResult = [SELECT Id, Name, SVMXC__Order_Status__c FROM WorkOrder WHERE Id = :wo.Id];
		System.assertEquals('Invoice Not Required', woResult.SVMXC__Order_Status__c);*/

	}

	@IsTest
	static void testInvoiceErrors()
	{
		Account acct = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
		Contact cont = FS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
		Schema.Location loc = FS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', 'TST001');
		Asset ip = FS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TEST01');
		WorkOrder wo = FS_TestDataFactory.createWO(ip, cont);

		// Insert DMR Invoice
		FS_Proforma_Invoice__c inv = new FS_Proforma_Invoice__c(Status__c='Open');
		inv.SAP_DMR_InvoiceNumber__c = 'ABC12345678';
		inv.SAP_DMR_Number__c = 'DEF0001001001';
		inv.Type__c='DMR';
		inv.Work_Order__c = wo.Id;
		insert inv;

		FS_Proforma_Invoice_Line__c line = new FS_Proforma_Invoice_Line__c();
		line.Proforma_Invoice__c = inv.Id;
		insert line;

		Test.startTest();

		FS_IntegrationError__c err1 = new FS_IntegrationError__c();
		err1.RelatedElementType__c = 'InvoiceId';
		err1.RelatedElementIdentifier__c = inv.Id;
		err1.ErrorMessage__c = 'Testing Product Transfer Errors';
		insert err1;

		FS_IntegrationError__c err2 = new FS_IntegrationError__c();
		err2.RelatedElementType__c = 'InvoiceNumber';
		err2.RelatedElementIdentifier__c = inv.SAP_DMR_Number__c;
		err2.ErrorMessage__c = 'Testing: No New values found to update DMR';
		insert err2;

		Test.stopTest();

		/*FS_Proforma_Invoice__c invResult2 = [SELECT Id, Name, SVMXC__Status__c FROM FS_Proforma_Invoice__c WHERE Id = :inv.Id];
		System.assertEquals('Invoice Not Required', invResult2.SVMXC__Status__c);

		WorkOrder woResult = [SELECT Id, Name, SVMXC__Order_Status__c FROM WorkOrder WHERE Id = :wo.Id];
		System.assertEquals('Invoice Not Required', woResult.SVMXC__Order_Status__c);*/

	}

}