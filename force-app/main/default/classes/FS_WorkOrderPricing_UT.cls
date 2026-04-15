/**
 * Created by frankvanloon on 7/14/24.
 */
@IsTest
public class FS_WorkOrderPricing_UT {

	@TestSetup
	static void setupData() {
		FS_TestDataFactory.createDefaultOperatingHours();
	}

	@IsTest
	static void testWorkOrderPricing()
	{
		String erpID = 'TESTX00001';
		Account acct = FS_TestDataFactory.createTestErpAccount('PkiTest', 999, erpID, 'TS10');
		Contact c = FS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
		Schema.Location loc = FS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', 'TSTC01');
		Product2 prod = FS_TestDataFactory.createTestProduct('TestProduct', 'PRD10010', 'ZZZ');
		Asset ip = FS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TST001', prod);
		ip.SoldTo_ExtId__c = erpID;
		ip.ShipTo_ExtId__c = erpID;
		ip.BillTo_ExtId__c = erpID;
		ip.Payer_ExtId__c = erpID;
		update ip;

		Product2 laborProd = FS_TestDataFactory.createTestProduct('TestLabor', 'LAB10010', 'ZZZ', 'Labor');
		Product2 travelProd = FS_TestDataFactory.createTestProduct('TestTravel', 'TRV10010', 'ZZZ', 'Travel');
		Product2 partsProd = FS_TestDataFactory.createTestProduct('TestParts', 'PRT10010', 'ZZZ', 'Service Parts');

		Date startDate = Date.today().addMonths(-1);
		Date endDate = startDate.addMonths(11);
		ServiceContract sc = FS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.AccountId, startDate, endDate);
		ServiceContract item = FS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate, prod);
		ContractLineItem cp = FS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
		Entitlement ent = FS_TestDataFactory.createEntitlement(item,'REP', 5, 2);

		WorkOrder wo = FS_TestDataFactory.createContractWO(ip, c);
		WorkOrderLineItem wd1 = FS_TestDataFactory.createWorkDetailUsage(wo, 'Labor', laborProd);
		WorkOrderLineItem wd2 = FS_TestDataFactory.createWorkDetailUsage(wo, 'Travel', travelProd);
		WorkOrderLineItem wd3 = FS_TestDataFactory.createWorkDetailUsage(wo, 'Parts', partsProd);
		List<WorkOrderLineItem> lines = new List<WorkOrderLineItem>();
		lines.add(wd1);
		lines.add(wd2);
		lines.add(wd3);

		Test.startTest();

		loc.SalesOrg__c = null;
		update loc;
		ip.SalesOrg__c = null;
		update ip;

		FS_WorkOrderPricingAction.PricingRequest request = new FS_WorkOrderPricingAction.PricingRequest();
		request.workOrderId = wo.Id;

		List<FS_WorkOrderPricingAction.PricingRequest> requests = new List<FS_WorkOrderPricingAction.PricingRequest> { request };
		List<FS_WorkOrderPricingAction.PricingResult> results = FS_WorkOrderPricingAction.calculatePricing(requests);
		FS_WorkOrderPricingAction.PricingResult result1 = results[0];
		System.assertNotEquals(null, result1.errorMessage);

		loc.SalesOrg__c = 'TS10';
		update loc;

		List<FS_WorkOrderPricingAction.PricingResult> results2 = FS_WorkOrderPricingAction.calculatePricing(requests);
		FS_WorkOrderPricingAction.PricingResult result2 = results2[0];
		System.assertEquals(null, result2.errorMessage);

		Test.stopTest();
	}

	@IsTest
	static void testWorkOrderPricingCDE()
	{
		String erpID = 'TESTX00001';
		Account acct = FS_TestDataFactory.createTestErpAccount('PkiTest', 999, erpID, 'TS10');
		Contact c = FS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
		Schema.Location loc = FS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', 'TSTC01');
		Product2 instrumentProd = FS_TestDataFactory.createTestProduct('TestInstrument', 'INS10010', 'ZZZ');
		Asset ip = FS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TST001', instrumentProd);
		ip.SoldTo_ExtId__c = erpID;
		ip.ShipTo_ExtId__c = erpID;
		ip.BillTo_ExtId__c = erpID;
		ip.Payer_ExtId__c = erpID;
		update ip;

		Product2 laborProd = FS_TestDataFactory.createTestProduct('TestLabor', 'LAB10010', 'ZZZ', 'Labor');
		Product2 travelProd = FS_TestDataFactory.createTestProduct('TestTravel', 'TRV10010', 'ZZZ', 'Travel');
		Product2 partsProd = FS_TestDataFactory.createTestProduct('TestConsumable', 'CON10010', 'ZZZ', 'Consumable');

		FS_Contract_Discount_Exception__c cde1 = new FS_Contract_Discount_Exception__c(Parts_Product__c = partsProd.Id,
				Discount_Type__c = 'Other Parts', Instrument_Product__c = null,
				Sales_Org__c = 'TS10', SAP_Activity_Type__c = 'REP');
		FS_Contract_Discount_Exception__c cde2 = new FS_Contract_Discount_Exception__c(Parts_Product__c = partsProd.Id,
				Discount_Type__c = 'Service Parts', Instrument_Product__c = instrumentProd.Id,
				Sales_Org__c = 'TS10', SAP_Activity_Type__c = 'REP');
		FS_Contract_Discount_Exception__c cde3 = new FS_Contract_Discount_Exception__c(Parts_Product__c = partsProd.Id,
				Discount_Type__c = 'Labor', Instrument_Product__c = null,
				Sales_Org__c = 'TS10', SAP_Activity_Type__c = 'PM');
		insert new List<FS_Contract_Discount_Exception__c> { cde1, cde2, cde3 };

		Date startDate = Date.today().addMonths(-1);
		Date endDate = startDate.addMonths(11);
		ServiceContract sc = FS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.AccountId, startDate, endDate);
		ServiceContract item = FS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate, instrumentProd);
		ContractLineItem cp = FS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
		Entitlement ent = FS_TestDataFactory.createEntitlement(item,'REP', 5, 2);

		WorkOrder wo = FS_TestDataFactory.createContractWO(ip, c);
		WorkOrderLineItem wd1 = FS_TestDataFactory.createWorkDetailUsage(wo, 'Labor', laborProd);
		WorkOrderLineItem wd2 = FS_TestDataFactory.createWorkDetailUsage(wo, 'Travel', travelProd);
		WorkOrderLineItem wd3 = FS_TestDataFactory.createWorkDetailUsage(wo, 'Parts', partsProd);
		List<WorkOrderLineItem> lines = new List<WorkOrderLineItem>();
		lines.add(wd1);
		lines.add(wd2);
		lines.add(wd3);

		Test.startTest();

		FS_WorkOrderPricingAction.PricingRequest request = new FS_WorkOrderPricingAction.PricingRequest();
		request.workOrderId = wo.Id;

		List<FS_WorkOrderPricingAction.PricingRequest> requests = new List<FS_WorkOrderPricingAction.PricingRequest> { request };
		List<FS_WorkOrderPricingAction.PricingResult> results = FS_WorkOrderPricingAction.calculatePricing(requests);
		FS_WorkOrderPricingAction.PricingResult result1 = results[0];
		System.assertEquals(null, result1.errorMessage);

		List<WorkOrderLineItem> lineResults = result1.lines;
		WorkOrderLineItem partsResult = lineResults[2];
		System.assertEquals(cde2.Discount_Type__c, partsResult.Discount_Type__c);
		System.assertEquals(ent.ServicePartsDiscountCovered__c, partsResult.ContractPercentDiscount__c);

		Test.stopTest();
	}
	
}