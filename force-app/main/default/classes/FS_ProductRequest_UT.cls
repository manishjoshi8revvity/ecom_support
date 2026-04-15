/**
 * Created by frankvanloon on 7/11/24.
 */
@IsTest
public class FS_ProductRequest_UT {

	@TestSetup
	static void setupTestData() {
		FS_TestDataFactory.createDefaultOperatingHours();
	}

	@IsTest
	static void createPartsOrderTestData()
	{
		// Insert Account  
		String erpID = 'TESTX00001';
		Account acct = FS_TestDataFactory.createTestErpAccount('PkiTest', 999, erpID, 'US10');
		acct.Transportation_Zone__c = '1';
		acct.SAP_Language__c = 'ES';
		update acct;

		// Insert Contact  
		Contact cont = FS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX0001A');

		// Insert location
		Schema.Location loc = FS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TLOC1001001', 'TL0101');
		loc.IsInventoryLocation = true;
		loc.IsMobile = true;
		update loc;

		User u = new User();
		u.Id = UserInfo.getUserId();
		ServiceResource tech = FS_TestDataFactory.createTestTechnician('TEST', u, 'Test Tech', 'TS01', 'TST001');
		tech.LocationId = loc.Id;
		update tech;

		// Insert Parts Order
		ProductRequest po = FS_TestDataFactory.createTestProductRequest(acct, cont, loc, null, null, null, null);
		// Blanked out the tech to get this condition to run: po.DestinationLocationId != null && po.ServiceResource__c == null

		Test.startTest();

		po.SoldTo_ExtId__c = erpID;
		po.ShipTo_ExtId__c = erpID;
		po.ShipToCity = 'Tampa';
		po.ShipToPostalCode = '33626';
		po.Status='Submitted';
		update po;

		FS_IntegrationError__c err1 = new FS_IntegrationError__c();
		err1.RelatedElementType__c = 'ProductRequestId';
		err1.RelatedElementIdentifier__c = po.Id;
		err1.ErrorMessage__c = 'Testing Product Request Error by Id';
		insert err1;

		ProductRequest result = [SELECT Id, ProductRequestNumber, Transportation_Zone__c, Language__c,
				ShipToCity, ShipToPostalCode, Status, ExternalId__c
			FROM ProductRequest WHERE Id = :po.Id];

		System.assertEquals('Error', result.Status);

		result.ExternalId__c = 'ABC123SAP4ME';
		update result;

		FS_IntegrationError__c err2 = new FS_IntegrationError__c();
		err2.RelatedElementType__c = 'ProductRequestNumber';
		err2.RelatedElementIdentifier__c = result.ExternalId__c;
		err2.ErrorMessage__c = 'Testing Product Request Error by Number';
		insert err2;

		Test.stopTest();

		// SVMXINT-612 map the Transportation Zone and Language from Account if no WO
//		System.assertEquals(acct.Transportation_Zone__c, result.Transportation_Zone__c);
//		System.assertEquals(acct.SAP_Language__c, result.Language__c);
//		System.assertEquals(40, result.ShipToCity.length());
//		System.assertEquals(10, result.ShipToPostalCode.length());
	}

	@IsTest
	static void createLinkedOrders()
	{
		User u = new User(Id = UserInfo.getUserId());
		ServiceResource tech = FS_TestDataFactory.createTestTechnician('TestTeam01', u, 'Test Tech1', 'TS12', 'T001');

		Account acct = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX0PO000002');
		Contact cont = FS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
		Schema.Location loc = FS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TLOC1001001', 'TL0101');
		loc.IsInventoryLocation = true;
		loc.IsMobile = true;
		update loc;

//		tech.LocationId = loc.Id;
//		update tech;

		Product2 prod = FS_TestDataFactory.createTestProduct('Test Product', 'TPRD001', 'ZZZ');
		Product2 refurb = FS_TestDataFactory.createTestProduct('Refurb Product', 'RTPRD001', 'ZZZ');

		FS_ProductPlant__c pplant = new FS_ProductPlant__c();
		pplant.Plant__c = loc.MaintenancePlant__c;
		pplant.Product__c = prod.Id;
		pplant.Refurbished_Part_Number__c = refurb.Part_Number__c;
		insert pplant;

		Asset ip = FS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TST00101');
		ip.Preferred_Technician__c = tech.Id;
		update ip;

		WorkOrder wo = FS_TestDataFactory.createWO(ip, cont);
		wo.Use_Refurbished_Parts__c = true;
		update wo;

		Test.startTest();

		// Create PO w/o Account, but with Tech.StorageLocation... and test SalesOrg too
		// Leaving tech null, along with no linkage from Location to Tech.. should find current user tech
		ProductRequest poReq = FS_TestDataFactory.createTestProductRequest(null, cont, loc, null, wo, null, null);
		poReq.Use_Refurbished_Parts__c = true;
		update poReq;

		// Add lines...
		ProductRequestLineItem line = new ProductRequestLineItem();
		line.Product2Id = prod.Id;
		line.QuantityRequested = 1;
		line.ParentId = poReq.Id;
		insert line;

		// Refurbished Part should have been used instead...
		ProductRequestLineItem lineResult = [SELECT Id, Product2Id FROM ProductRequestLineItem WHERE Id = :line.Id];
		System.assertEquals(refurb.Id, lineResult.Product2Id);

		// Mimic the tech relasing it to SAP..
		poReq.Status = 'Submitted';
		update poReq;

		// Mimic BOOMI assgning the SAP Id...
		poReq.ExternalId__c = 'PO-REQ-0001';
		update poReq;

		ProductRequest reqResult = [SELECT Id, ProductRequestNumber, Status FROM ProductRequest WHERE Id = :poReq.Id];

		// Create linked Shipment, Deliveries (on lines)
		line.SAP_Shipment_Number__c = 'SHIP0001';
		update line;

		line.SAP_Delivery_Number__c = 'DLVR0001';
		update line;

		Test.stopTest();

		//ProductRequest poRma = FS_TestDataFactory.createTestPartsOrder(poRmaRT, null, cont, loc, tech, null, 'PO-RMA-0001', 'PO-REQ-0001');
	}

	@IsTest
	static void createProductRequestWithSalesOrg()
	{
		// Insert Account
		String erpID = 'TESTX00001';
		Account acct = FS_TestDataFactory.createTestErpAccount('PkiTest', 999, erpID, 'US10');
		acct.Transportation_Zone__c = '1';
		acct.SAP_Language__c = 'ES';
		update acct;

		// Insert Contact
		Contact cont = FS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX0001A');

		// Insert location
		Schema.Location sloc = FS_TestDataFactory.createTestLocation(acct, 'Test Location', 'SLOC1001001', 'SL0101');
		sloc.IsInventoryLocation = true;
		sloc.IsMobile = true;
		sloc.SalesOrg__c = 'EEU2';
		update sloc;

		User u = new User();
		u.Id = UserInfo.getUserId();
		ServiceResource tech = FS_TestDataFactory.createTestTechnician('TEST', u, 'Test Tech', 'TS01', 'TST001');
		tech.LocationId = sloc.Id;
		update tech;

		Product2 pd = FS_TestDataFactory.createTestProduct('TestProduct', '106018','ZZZ');
		Schema.Location floc = FS_TestDataFactory.createTestLocation(acct, 'Test Functional Location', 'FLOC1001001', 'FL0101');
		Asset ip = FS_TestDataFactory.createIP('123456',acct,floc,'5545333',pd);
		WorkOrder wo = FS_TestDataFactory.createWO(ip, cont);

		WorkOrder woResult = [SELECT Id, WorkOrderNumber, SalesOrg__c FROM WorkOrder WHERE Id = :wo.Id];
		System.debug('WO SALES-ORG=' + woResult.SalesOrg__c);

		Test.startTest();

		// Insert Parts Order
		ProductRequest po = FS_TestDataFactory.createTestProductRequest(acct, cont, sloc, tech, wo, null, null);

		ProductRequest result = [SELECT Id, ProductRequestNumber, SalesOrg__c FROM ProductRequest WHERE Id = :po.Id];
		System.assertEquals(sloc.SalesOrg__c, result.SalesOrg__c);

		Test.stopTest();
	}

}