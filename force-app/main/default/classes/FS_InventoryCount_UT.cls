@IsTest
private class FS_InventoryCount_UT {

	@TestSetup
	static void setupTest() {
	}

	@IsTest
	static void testInventoryCount()
	{
		FS_TestDataFactory.createDefaultOperatingHours();

		User techUser = new User(Id = UserInfo.getUserId());
		ServiceResource tech = FS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001');
		Account acct = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
		//Contact c = FS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');

		Schema.Location loc = FS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', 'TSTC01');
		loc.Service_Engineer__c = techUser.Id;
		loc.IsInventoryLocation=true;
		update loc;

		Product2 p = FS_TestDataFactory.createTestProduct('Test Product', 'TPRD1001', 'AA');
		ProductItem ps1 = FS_TestDataFactory.createTestProductStock(loc, p, 'Available', 4);

		Test.startTest();

		// Fill in RequestedFrom__c (Location)
		FS_InventoryCount__c ic = new FS_InventoryCount__c();
		ic.Status__c = 'Open';
		ic.RequestedFrom__c = loc.Id;
		insert ic;

		// Assert RequestedTechnician__c is not blank (Technician)
		FS_InventoryCount__c icResult = [SELECT Id, Name, RequestedTechnician__c FROM FS_InventoryCount__c WHERE Id = :ic.Id];
		//System.assertEquals(tech.Id, icResult.RequestedTechnician__c);

		// Lines.. Assert ProductStock__c is auto-filled based on Product__c
		FS_InventoryCountLine__c line1 = new FS_InventoryCountLine__c();
		line1.InventoryCount__c = ic.Id;
		line1.Product__c = p.Id;
		insert line1;

		FS_InventoryCountLine__c lineResult = [SELECT Id, ProductStock__c FROM FS_InventoryCountLine__c WHERE Id = :line1.Id];
		//System.assertEquals(ps1.Id, lineResult.ProductStock__c);

		line1.Is_Serialized__c = true;
		line1.Expected_Serial_Numbers__c = 'ABC123,ABC234';
		line1.CountedQty__c = 3;
		Database.SaveResult r1 = Database.update(line1, false);
		//System.assert(r1.isSuccess() == false); // Actual Serials is blank

		line1.Actual_Serial_Numbers__c = 'ABC123,ABC098';
		Database.SaveResult r2 = Database.update(line1, false);
		//System.assert(r2.isSuccess() == false); // Wrong number

		line1.Actual_Serial_Numbers__c = 'ABC123,ABC234,ABC098';
		Database.SaveResult r3 = Database.update(line1, false);
		//System.assert(r3.isSuccess() == true);

		// Change Status__c == 'Confirmed'
		ic.Status__c = 'Confirmed';
		update ic;

		// Change Status__c == 'Approved' .. send event
		ic.Status__c = 'Approved';
		update ic;

		Test.stopTest();
	}

	 @IsTest
	 static void test_lookupFilters() {
		 // Setup Data
		 User techUser = new User(Id = UserInfo.getUserId());
		 ServiceResource tech = FS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001');
 
		 // Execute
		 FS_Inventory_Count_Approval.InventoryCountFilterData lookupFilters = FS_Inventory_Count_Approval.lookupFilters();
		 System.debug('lookupFilters: ' + lookupFilters);
 
		 // Validate
		 System.assertEquals('TS12', lookupFilters.allPlants[0].value, 'Expected a plant value of TS12');
		 System.assertEquals(true, lookupFilters.allStatuses.size() > 0, 'Expected a set of status values');
	 }


	 @IsTest
	 static void test_updateInventory() {
		 // Setup Data
		 System.debug('Setting up test data');
		 OperatingHours hours = FS_TestDataFactory.createDefaultOperatingHours();

		 //create territories
		 ServiceTerritory territory1 = FS_TestDataFactory.createTestTerritory('Americas', 'Super Territory', null, hours);
		 ServiceTerritory territory2 = FS_TestDataFactory.createTestTerritory('United States', 'Country', territory1.Id, hours);
		 ServiceTerritory territory3 = FS_TestDataFactory.createTestTerritory('US Rockies', 'Super District', territory2.Id, hours);
		 ServiceTerritory territory4 = FS_TestDataFactory.createTestTerritory('United Kingdom', 'Sub Territory', territory3.Id, hours);

		 //create users
		 User user1 = new User(Id = UserInfo.getUserId());
 
		 //create technicians and service teams
		 ServiceResource tech1 = FS_TestDataFactory.createTestTechnician('Billable Service Team', user1, 'Tech Name1', 'Plant1', 'Loc1');
		 //tech1.SVMXC__Service_Territory__c = territory3.Id;
		 //tech1.Technician_Geographies__c = 'USROCK';
		 update tech1;
//		 ServiceResource tech2 = FS_TestDataFactory.createTestTechnician('US Enterprise - GSK', null, 'Tech Name2', 'Plant2', 'Loc2');
//		 ServiceResource tech3 = FS_TestDataFactory.createTestTechnician('US DX West', null, 'Tech Name3', 'Plant3', 'Loc3');
//		 ServiceResource tech4 = FS_TestDataFactory.createTestTechnician('Puerto Rico - Enterprise', null, 'Tech Name4', 'Plant4', 'Loc4');
 
		 //create accounts
		 Account acct = FS_TestDataFactory.createTestAccount('Account 1', 'Acc1');
 
		 //create locations
		 Schema.Location location1 = FS_TestDataFactory.createTestLocation(acct, 'US Loc1', 'Loc1', 'Loc1');
		 location1.IsInventoryLocation = true;
		 update location1;
		 Schema.Location location2 = FS_TestDataFactory.createTestLocation(acct, 'US Loc2', 'Loc2', 'Loc2');
		 location2.IsInventoryLocation = true;
		 update location2;
 
		 //create geography
		 ServiceTerritory geo1 = FS_TestDataFactory.createTestGeography('Loc1', territory3.Id, hours);
		 ServiceTerritory geo2 = FS_TestDataFactory.createTestGeography('Loc2', territory3.Id, hours);
		 ServiceTerritory geo3 = FS_TestDataFactory.createTestGeography('Loc3', territory3.Id, hours);
		 ServiceTerritory geo4 = FS_TestDataFactory.createTestGeography('Loc4', null, hours); // don't set a territory for this geo

		 //create dispatcher access
//		 SVMXC__Dispatcher_Access__c dispatcherAccess = new SVMXC__Dispatcher_Access__c(SVMXC__Dispatcher__c=user1.Id, ServiceTerritory=territory3.Id);
//		 insert dispatcherAccess;
 
		 //create geo tech
//		 Geography_Technician__c geoTech = FS_TestDataFactory.createTestGeoTech(geo2, tech1, 1);

		 //create Product
		 Product2 product1 = FS_TestDataFactory.createTestProduct('Prod1', 'PC1', 'ZZZ');
 
		 //create Product Stock
		 ProductItem productStock1 = FS_TestDataFactory.createTestProductStock(location1, product1, 'Available', 12);
		 productStock1.Product_Cost__c = 150.00;
		 update productStock1;
		 ProductItem productStock2 = FS_TestDataFactory.createTestProductStock(location2, product1, 'Available', 10);
		 productStock2.Product_Cost__c = 200.00;
		 update productStock2;
 
		 //create Inventory Count
		 createTestInventoryCount('US Loc1');
		 createTestInventoryCount('US Loc2');
		 List<FS_InventoryCount__c> inventoryCounts = [SELECT Id, Status__c, Service_Engineer__c, Service_Manager__c
		 	FROM FS_InventoryCount__c];
		 System.debug('~~ inventoryCounts: ' + inventoryCounts);
		 inventoryCounts[0].Status__c = 'Submitted';
		 inventoryCounts[0].RequestedTechnician__c = tech1.Id;
		 inventoryCounts[0].Service_Engineer__c = user1.Id;
		 inventoryCounts[1].Status__c = 'Confirmed';
		 inventoryCounts[1].RequestedTechnician__c = tech1.Id;
		 inventoryCounts[1].Service_Engineer__c = user1.Id;
		 update inventoryCounts;
		 System.debug('inventoryCounts Updated: ' + inventoryCounts);
 
		 List<FS_InventoryCountLine__c> inventoryCountLines = [SELECT Id, Name, CountedQty__c, BookedQty__c FROM FS_InventoryCountLine__c];
		 inventoryCountLines[0].BookedQty__c = 8;
		 inventoryCountLines[0].CountedQty__c = 9;
		 inventoryCountLines[1].BookedQty__c = 6;
		 inventoryCountLines[1].CountedQty__c = 7;
		 inventoryCountLines[1].InvCnt_Status__c = 'Confirmed';
		 update inventoryCountLines;
		 System.debug('inventoryCountLines: ' + inventoryCountLines);
 
		 List<Id> fixedSearchResults = new List<Id>();
		 List<ServiceResource> techs = [SELECT Id FROM ServiceResource];
		 for (ServiceResource tech :techs) {
			 fixedSearchResults.add(tech.Id);
		 }
 
		 List<Schema.Location> locs = [SELECT Id FROM Location];
		 for (Schema.Location loc :locs) {
			 fixedSearchResults.add(loc.Id);
		 }
 
		 Test.setFixedSearchResults(fixedSearchResults);
 
		 List<String> selectedIds = new List<String> {techs[0].Id};
		 System.debug('selectedIds: ' + selectedIds);
		 List<FS_CustomLookupService.LookupSearchResult> lookupSearchResults = FS_CustomLookupService.searchTechnicians('US', selectedIds);
		 System.debug('lookupSearchResults: ' + lookupSearchResults);
 
		 // Execute
		 FS_Inventory_Count_Approval.InventoryCountFilter filter = new FS_Inventory_Count_Approval.InventoryCountFilter();
		 filter.selectedPlants = new List<String>{'TS12'};
		 filter.selectedStatuses = new List<String>{'Submitted', 'Confirmed'};
		 System.debug('lookupSearchResults[0]: ' + lookupSearchResults[0]);
		 filter.selectedTechnicians = lookupSearchResults;
		 filter.selectedTechnician = lookupSearchResults[0].id;
 
		 //lookupSearchResults: (LookupSearchResult:[icon=custom:custom32, id=Plant1, sObjectType=PLANT, subtitle=Plant, title=Plant1], LookupSearchResult:[icon=custom:custom32, id=Plant3, sObjectType=PLANT, subtitle=Plant, title=Plant3], LookupSearchResult:[icon=custom:custom32, id=Plant4, sObjectType=PLANT, subtitle=Plant, title=Plant4], LookupSearchResult:[icon=custom:custom24, id=a80K0000000CmhjIAC, sObjectType=Schema.Location, subtitle=Location • Loc1, title=US Loc1], LookupSearchResult:[icon=custom:custom24, id=a80K0000000CmhkIAC, sObjectType=Schema.Location, subtitle=Location • Loc2, title=US Loc2], LookupSearchResult:[icon=custom:custom15, id=a7iK0000000D9ABIA0, sObjectType=ServiceResource, subtitle=Technician • Loc1, title=a7iK0000000D9AB], LookupSearchResult:[icon=custom:custom15, id=a7iK0000000D9ADIA0, sObjectType=ServiceResource, subtitle=Technician • Loc3, title=a7iK0000000D9AD], LookupSearchResult:[icon=custom:custom15, id=a7iK0000000D9AEIA0, sObjectType=ServiceResource, subtitle=Technician • Loc4, title=a7iK0000000D9AE])
 
		 List<FS_InventoryCount__c> filterInventory = FS_Inventory_Count_Approval.filterInventory(filter);
		 System.debug('filterInventory: ' + filterInventory);
 
		 List<FS_InventoryCount__c> invCount = [SELECT Id, Name, RequestedTechnician__c, RequestedTechnician__r.LocationCode__c, RequestedTechnician__r.Name, RequestedTechnician__r.Plant__c, RequestedFrom__c, RequestedFrom__r.Name, Status__c, LastModifiedDate, Booked_Qty_Total__c, Counted_Qty_Total__c, Entry_Qty_Total__c, Lines_Count__c, Is_Found_Item_True_Count__c, CurrencyIsoCode, Is_Found_Item_True_Qty__c, Difference_Value_Total__c FROM FS_InventoryCount__c ORDER BY Name LIMIT 1000];
		 System.debug('invCount: ' + invCount);
		 List<FS_InventoryCountLine__c> getLines1 = FS_Inventory_Count_Approval.getLines(invCount[0].Id);
		 System.debug('getLines1: ' + getLines1);
		 List<FS_InventoryCountLine__c> getLines2 = FS_Inventory_Count_Approval.getLines(invCount[1].Id);
		 System.debug('getLines2: ' + getLines2);

		 Test.startTest();

		 // Test Submitted to Recount
		 FS_Inventory_Count_Approval.InventoryUpdateList iList = new FS_Inventory_Count_Approval.InventoryUpdateList();
		 iList.selectedLines = new List<String> {getLines1[0].Id};
		 iList.selectedReviewStatus = 'Recount';
		 iList.selectedRejectReason = 'Test Recount';
		 String updateInventory1 = FS_Inventory_Count_Approval.updateInventory(iList);
		 System.debug('updateInventory1 (Submitted->Recount): ' + updateInventory1);
		 List<FS_InventoryCountLine__c> lines1 = [SELECT Id, InvCnt_Status__c, Why_Recount_Needed__c,
				 Confirmed_Date__c, Confirmed_By__c, Recount_Requested_Date__c, Recount_Requested_By__c
		 FROM FS_InventoryCountLine__c WHERE Id IN :iList.selectedLines];
		 System.debug('lines1: ' + lines1);
		 System.assertEquals('Recount', lines1[0].InvCnt_Status__c);
 
		 // Test Submitted to Confirmed
		 iList.selectedLines = new List<String> {getLines1[0].Id};
		 iList.selectedReviewStatus = 'Confirmed';
		 getLines1[0].InvCnt_Status__c = 'Submitted';
		 getLines1[0].Why_Recount_Needed__c = '';
		 update getLines1[0];
		 String updateInventory2 = FS_Inventory_Count_Approval.updateInventory(iList);
		 System.debug('updateInventory2 (Submitted->Confirmed): ' + updateInventory2);
		 List<FS_InventoryCountLine__c> lines2 = [SELECT Id, InvCnt_Status__c, Why_Recount_Needed__c,
				 Confirmed_Date__c, Confirmed_By__c, Recount_Requested_Date__c, Recount_Requested_By__c
		 FROM FS_InventoryCountLine__c WHERE Id IN :iList.selectedLines];
		 System.debug('lines2: ' + lines2);
		 System.assertEquals('Confirmed', lines2[0].InvCnt_Status__c);
 
		 // Test Confirmed to Approved
		 iList.selectedLines = new List<String> {getLines2[0].Id};
		 iList.selectedReviewStatus = 'Approved';
		 iList.selectedRejectReason = '';
		 String updateInventory3 = FS_Inventory_Count_Approval.updateInventory(iList);
		 System.debug('updateInventory3 (Confirmed->Approved): ' + updateInventory3);
		 List<FS_InventoryCountLine__c> lines3 = [SELECT Id, InvCnt_Status__c, Why_Recount_Needed__c,
				 Confirmed_Date__c, Confirmed_By__c, Recount_Requested_Date__c, Recount_Requested_By__c
		 FROM FS_InventoryCountLine__c WHERE Id IN :iList.selectedLines];
		 System.debug('lines3: ' + lines3);
		 System.assertEquals('Approved', lines3[0].InvCnt_Status__c);

		 Test.stopTest();
	 }
 
	 @IsTest
	 static void test_updateInventoryFromHeader() {
		 // Setup Data
		 System.debug('Setting up test data');
		 OperatingHours hours = FS_TestDataFactory.createDefaultOperatingHours();
 
		 //create territories
		 //create territories
		 ServiceTerritory territory1 = FS_TestDataFactory.createTestTerritory('Americas', 'Super Territory', null, hours);
		 ServiceTerritory territory2 = FS_TestDataFactory.createTestTerritory('United States', 'Country', territory1.Id, hours);
		 ServiceTerritory territory3 = FS_TestDataFactory.createTestTerritory('US Rockies', 'Super District', territory2.Id, hours);
		 ServiceTerritory territory4 = FS_TestDataFactory.createTestTerritory('United Kingdom', 'Sub Territory', territory3.Id, hours);

		 //create users
		 User user1 = new User(Id = UserInfo.getUserId());
 
		 //create technicians and service teams
		 ServiceResource tech1 = FS_TestDataFactory.createTestTechnician('Billable Service Team', user1, 'Tech Name1', 'Plant1', 'Loc1');
//		 tech1.SVMXC__Service_Territory__c = territory3.Id;
//		 tech1.Technician_Geographies__c = 'USROCK';
//		 update tech1;
//		 ServiceResource tech2 = FS_TestDataFactory.createTestTechnician('US Enterprise - GSK', null, 'Tech Name2', 'Plant2', 'Loc2');
//		 ServiceResource tech3 = FS_TestDataFactory.createTestTechnician('US DX West', null, 'Tech Name3', 'Plant3', 'Loc3');
//		 ServiceResource tech4 = FS_TestDataFactory.createTestTechnician('Puerto Rico - Enterprise', null, 'Tech Name4', 'Plant4', 'Loc4');
 
		 //create accounts
		 Account acct = FS_TestDataFactory.createTestAccount('Account 1', 'Acc1');
 
		 //create locations
		 Schema.Location location1 = FS_TestDataFactory.createTestLocation(acct, 'US Loc1', 'Loc1', 'Loc1');
		 location1.IsInventoryLocation = true;
		 update location1;
		 Schema.Location location2 = FS_TestDataFactory.createTestLocation(acct, 'US Loc2', 'Loc2', 'Loc2');
		 location2.IsInventoryLocation = true;
		 update location2;
 
		 //create geography
		 ServiceTerritory geo1 = FS_TestDataFactory.createTestGeography('Loc1', territory3.Id, hours);
		 ServiceTerritory geo2 = FS_TestDataFactory.createTestGeography('Loc2', territory3.Id, hours);
		 ServiceTerritory geo3 = FS_TestDataFactory.createTestGeography('Loc3', territory3.Id, hours);
		 ServiceTerritory geo4 = FS_TestDataFactory.createTestGeography('Loc4', null, hours); // don't set a territory for this geo
 
		 //create dispatcher access
//		 SVMXC__Dispatcher_Access__c dispatcherAccess = new SVMXC__Dispatcher_Access__c(SVMXC__Dispatcher__c=user1.Id, ServiceTerritory=territory3.Id);
//		 insert dispatcherAccess;
 
		 //create geo tech
//		 Geography_Technician__c geoTech = FS_TestDataFactory.createTestGeoTech(geo2, tech1, 1);
 
		 //create Product
		 Product2 product1 = FS_TestDataFactory.createTestProduct('Prod1', 'PC1', 'ZZZ');
 
		 //create Product Stock
		 ProductItem productStock1 = FS_TestDataFactory.createTestProductStock(location1, product1, 'Available', 12);
		 productStock1.Product_Cost__c = 150.00;
		 update productStock1;
		 ProductItem productStock2 = FS_TestDataFactory.createTestProductStock(location2, product1, 'Available', 10);
		 productStock2.Product_Cost__c = 200.00;
		 update productStock2;
 
		 //create Inventory Count
		 createTestInventoryCount('US Loc1');
		 createTestInventoryCount('US Loc2');
		 List<FS_InventoryCount__c> inventoryCounts = [SELECT Id, Status__c FROM FS_InventoryCount__c];
		 System.debug('inventoryCounts: ' + inventoryCounts);
		 inventoryCounts[0].Status__c = 'Submitted';
		 inventoryCounts[0].RequestedTechnician__c = tech1.Id;
		 inventoryCounts[0].Service_Engineer__c = user1.Id;
		 inventoryCounts[1].Status__c = 'Confirmed';
		 inventoryCounts[1].RequestedTechnician__c = tech1.Id;
		 inventoryCounts[1].Service_Engineer__c = user1.Id;
		 update inventoryCounts;
		 System.debug('inventoryCounts Updated: ' + inventoryCounts);
 
		 List<FS_InventoryCountLine__c> inventoryCountLines = [SELECT Id, Name, CountedQty__c, BookedQty__c FROM FS_InventoryCountLine__c];
		 inventoryCountLines[0].BookedQty__c = 8;
		 inventoryCountLines[0].CountedQty__c = 9;
		 inventoryCountLines[1].BookedQty__c = 6;
		 inventoryCountLines[1].CountedQty__c = 7;
		 inventoryCountLines[1].InvCnt_Status__c = 'Confirmed';
		 update inventoryCountLines;
		 System.debug('inventoryCountLines: ' + inventoryCountLines);
 
 
		 List<Id> fixedSearchResults = new List<Id>();
		 List<ServiceResource> techs = [SELECT Id FROM ServiceResource];
		 for (ServiceResource tech :techs) {
			 fixedSearchResults.add(tech.Id);
		 }
 
		 List<Schema.Location> locs = [SELECT Id FROM Location];
		 for (Schema.Location loc :locs) {
			 fixedSearchResults.add(loc.Id);
		 }
 
		 Test.setFixedSearchResults(fixedSearchResults);
 
		 List<String> selectedIds = new List<String> {techs[0].Id};
		 System.debug('selectedIds: ' + selectedIds);
		 List<FS_CustomLookupService.LookupSearchResult> lookupSearchResults = FS_CustomLookupService.searchTechnicians('US', selectedIds);
		 System.debug('lookupSearchResults: ' + lookupSearchResults);
 
		 // Execute
		 FS_Inventory_Count_Approval.InventoryCountFilter filter = new FS_Inventory_Count_Approval.InventoryCountFilter();
		 filter.selectedPlants = new List<String>{'TS12'};
		 filter.selectedStatuses = new List<String>{'Submitted', 'Confirmed'};
		 System.debug('lookupSearchResults[0]: ' + lookupSearchResults[0]);
		 filter.selectedTechnicians = lookupSearchResults;
		 filter.selectedTechnician = lookupSearchResults[0].id;
 
		 //lookupSearchResults: (LookupSearchResult:[icon=custom:custom32, id=Plant1, sObjectType=PLANT, subtitle=Plant, title=Plant1], LookupSearchResult:[icon=custom:custom32, id=Plant3, sObjectType=PLANT, subtitle=Plant, title=Plant3], LookupSearchResult:[icon=custom:custom32, id=Plant4, sObjectType=PLANT, subtitle=Plant, title=Plant4], LookupSearchResult:[icon=custom:custom24, id=a80K0000000CmhjIAC, sObjectType=Schema.Location, subtitle=Location • Loc1, title=US Loc1], LookupSearchResult:[icon=custom:custom24, id=a80K0000000CmhkIAC, sObjectType=Schema.Location, subtitle=Location • Loc2, title=US Loc2], LookupSearchResult:[icon=custom:custom15, id=a7iK0000000D9ABIA0, sObjectType=ServiceResource, subtitle=Technician • Loc1, title=a7iK0000000D9AB], LookupSearchResult:[icon=custom:custom15, id=a7iK0000000D9ADIA0, sObjectType=ServiceResource, subtitle=Technician • Loc3, title=a7iK0000000D9AD], LookupSearchResult:[icon=custom:custom15, id=a7iK0000000D9AEIA0, sObjectType=ServiceResource, subtitle=Technician • Loc4, title=a7iK0000000D9AE])
 
		 List<FS_InventoryCount__c> filterInventory = FS_Inventory_Count_Approval.filterInventory(filter);
		 System.debug('filterInventory: ' + filterInventory);
 
		 List<FS_InventoryCount__c> invCount = [SELECT Id, Name, RequestedTechnician__c, RequestedTechnician__r.LocationCode__c, RequestedTechnician__r.Name, RequestedTechnician__r.Plant__c, RequestedFrom__c, RequestedFrom__r.Name, Status__c, LastModifiedDate, Booked_Qty_Total__c, Counted_Qty_Total__c, Entry_Qty_Total__c, Lines_Count__c, Is_Found_Item_True_Count__c, CurrencyIsoCode, Is_Found_Item_True_Qty__c, Difference_Value_Total__c FROM FS_InventoryCount__c ORDER BY Name LIMIT 1000];
		 System.debug('invCount: ' + invCount);
		 List<FS_InventoryCountLine__c> getLines1 = FS_Inventory_Count_Approval.getLines(invCount[0].Id);
		 System.debug('getLines1: ' + getLines1);
		 List<FS_InventoryCountLine__c> getLines2 = FS_Inventory_Count_Approval.getLines(invCount[1].Id);
		 System.debug('getLines2: ' + getLines2);
 
		 // Test Submitted to Recount
		 FS_Inventory_Count_Approval.InventoryHeaderUpdateData iList = new FS_Inventory_Count_Approval.InventoryHeaderUpdateData();
		 iList.selectedHeaderLine = getLines1[0].InventoryCount__c;
		 iList.selectedReviewStatus = 'Recount';
		 iList.selectedRejectReason = 'Test Recount';
		 String updateInventory1 = FS_Inventory_Count_Approval.updateInventoryFromHeader(iList);
		 System.debug('updateInventory1 (Submitted->Recount): ' + updateInventory1);
		 List<FS_InventoryCountLine__c> lines1 = [SELECT Id, InvCnt_Status__c, Why_Recount_Needed__c,
				 Confirmed_Date__c, Confirmed_By__c, Recount_Requested_Date__c, Recount_Requested_By__c
		 FROM FS_InventoryCountLine__c WHERE Id = :getLines1[0].Id];
		 System.debug('lines1: ' + lines1);
		 System.assertEquals('Recount', lines1[0].InvCnt_Status__c);
 
		 // Test Submitted to Confirmed
		 iList.selectedHeaderLine = getLines1[0].InventoryCount__c;
		 iList.selectedReviewStatus = 'Confirmed';
		 getLines1[0].InvCnt_Status__c = 'Submitted';
		 getLines1[0].Why_Recount_Needed__c = '';
		 update getLines1[0];
		 String updateInventory2 = FS_Inventory_Count_Approval.updateInventoryFromHeader(iList);
		 System.debug('updateInventory2 (Submitted->Confirmed): ' + updateInventory2);
		 List<FS_InventoryCountLine__c> lines2 = [SELECT Id, InvCnt_Status__c, Why_Recount_Needed__c,
				 Confirmed_Date__c, Confirmed_By__c, Recount_Requested_Date__c, Recount_Requested_By__c
		 FROM FS_InventoryCountLine__c WHERE Id = :getLines1[0].Id];
		 System.debug('lines2: ' + lines2);
		 System.assertEquals('Confirmed', lines2[0].InvCnt_Status__c);
 
		 // Test Confirmed to Approved
		 iList.selectedHeaderLine = getLines2[0].InventoryCount__c;
		 iList.selectedReviewStatus = 'Approved';
		 iList.selectedRejectReason = '';
		 String updateInventory3 = FS_Inventory_Count_Approval.updateInventoryFromHeader(iList);
		 System.debug('updateInventory3 (Confirmed->Approved): ' + updateInventory3);
		 List<FS_InventoryCountLine__c> lines3 = [SELECT Id, InvCnt_Status__c, Why_Recount_Needed__c,
				 Confirmed_Date__c, Confirmed_By__c, Recount_Requested_Date__c, Recount_Requested_By__c
		 FROM FS_InventoryCountLine__c WHERE Id = :getLines2[0].Id];
		 System.debug('lines3: ' + lines3);
		 System.assertEquals('Approved', lines3[0].InvCnt_Status__c);
	 }

	private static void createTestInventoryCount(String locName)
	{
		Schema.Location loc = [SELECT Id, Name, LocationCode__c, MaintenancePlant__c
			FROM Location WHERE Name = :locName AND IsInventoryLocation = TRUE];

		List<FS_InventoryCount__c> existingCounts = [SELECT Id, Name, Status__c
			FROM FS_InventoryCount__c WHERE RequestedFrom__c = :loc.Id];
		if (!existingCounts.isEmpty()) {
			System.debug('Existing Inventory Counts found, exiting... ' + existingCounts);
			return;
		}

		FS_InventoryCount__c count = new FS_InventoryCount__c(Status__c = 'Open',
			RequestedFrom__c = loc.Id, DocumentDate__c = Date.today(),
			PlannedDate__c = Date.today().addDays(14));
		insert count;

		List<FS_InventoryCountLine__c> lines = new List<FS_InventoryCountLine__c>();
		List<ProductItem> availStock = [SELECT Id, ProductItemNumber, Product2Id, QuantityOnHand
			FROM ProductItem WHERE LocationId = :loc.Id];
		for (ProductItem stock : availStock)
		{
			FS_InventoryCountLine__c line = new FS_InventoryCountLine__c(InventoryCount__c = count.Id,
				ProductStock__c = stock.Id, Product__c = stock.Product2Id, InvCnt_Status__c = 'Open',
				BookedQty__c = stock.QuantityOnHand);
			lines.add(line);
		}
		insert lines;
		System.debug('Created Inventory Count with ' + lines.size() + ' lines.');
	}

}