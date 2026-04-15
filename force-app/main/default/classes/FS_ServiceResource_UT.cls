/**
 * Created by @Saurabh B on 09/05/2024
 * Covering Class: FS_ServiceResourceManager
 */
@IsTest
public class FS_ServiceResource_UT {

	@TestSetup
	static void setup() {
		User user1 = new User(Id = UserInfo.getUserId());

		Schema.Location loc = new Schema.Location();
		loc.Name='Test';
		loc.LocationType='Site';
		loc.IsInventoryLocation=true;
		loc.IsMobile= true;
		loc.External_ID__c='GBA2F006';
		insert loc;

		ServiceResource tech1 = new ServiceResource(
				Name='Test',
				Plant__c = 'GBA1',
				LocationId=loc.Id,
				RelatedRecordId=user1.Id,
				LocationCode__c = 'F006',
				External_ID__c='GBA2F006',
				IsActive=true);

		insert new List<ServiceResource>{tech1};
	}

	@IsTest
	static void testUpdateTechnicianLocations() {
		List<ServiceResource> serRes = [SELECT Id, Name, Plant__c, LocationId,RelatedRecordId, LocationCode__c FROM ServiceResource];
		serRes[0].Plant__c = 'GBA2';

		Test.startTest();
		update serRes;
		Test.stopTest();

		ServiceResource updatedTech = [SELECT LocationId FROM ServiceResource WHERE Id = :serRes[0].Id];
		System.assertNotEquals(null, updatedTech.LocationId, 'LocationId should not be null after update');
	}

	@IsTest
	static void testLocationLookup()
	{
		OperatingHours hours = FS_TestDataFactory.createDefaultOperatingHours();

		Test.startTest();

		ServiceResource tech = [SELECT Id, Name, Plant__c, LocationId, RelatedRecordId, LocationCode__c FROM ServiceResource][0];

		Account acct = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
		Schema.Location loc = FS_TestDataFactory.createTestLocation(acct, 'ParentLocTest',
				tech.Plant__c + tech.LocationCode__c, tech.LocationCode__c);

		// 2/11/21 Tony - added as SMAX_PS_Geography__c is now required
		ServiceTerritory geo1 = FS_TestDataFactory.createTestGeography('Loc1', hours);
		ServiceTerritory geo2 = FS_TestDataFactory.createTestGeography('Loc2', hours);
		ServiceTerritory geo3 = FS_TestDataFactory.createTestGeography('Loc3', hours);
		ServiceTerritory geo4 = FS_TestDataFactory.createTestGeography('Loc4', hours);

		ServiceTerritoryMember geoTech1 = FS_TestDataFactory.createTestTerritoryMember(tech, geo1, 'P');
		ServiceTerritoryMember geoTech2 = FS_TestDataFactory.createTestTerritoryMember(tech, geo2, 'S');
		ServiceTerritoryMember geoTech3 = FS_TestDataFactory.createTestTerritoryMember(tech, geo3, 'S');
		ServiceTerritoryMember geoTech4 = FS_TestDataFactory.createTestTerritoryMember(tech, geo4, 'S');

		Test.stopTest();

		delete geoTech2;
		delete geoTech3;
		delete geoTech4;
	}

	@IsTest
	static void testGeoTechBatch()
	{
		OperatingHours hours = FS_TestDataFactory.createDefaultOperatingHours();

		ServiceResource tech = [SELECT Id, Name, Plant__c, LocationId, RelatedRecordId, LocationCode__c
			FROM ServiceResource][0];

		// 2/11/21 Tony - added as SMAX_PS_Geography__c is now required
		ServiceTerritory geo1 = FS_TestDataFactory.createTestGeography('TST10', hours);
		ServiceTerritory geo2 = FS_TestDataFactory.createTestGeography('TST12', hours);
		ServiceTerritory geo3 = FS_TestDataFactory.createTestGeography('TST13', hours);
		ServiceTerritory geo4 = FS_TestDataFactory.createTestGeography('TST14', hours);

		ServiceTerritoryMember geoTech1 = FS_TestDataFactory.createTestTerritoryMember(tech, geo1, 'P');
		ServiceTerritoryMember geoTech2 = FS_TestDataFactory.createTestTerritoryMember(tech, geo2, 'S');
		ServiceTerritoryMember geoTech3 = FS_TestDataFactory.createTestTerritoryMember(tech, geo3, 'S');
		ServiceTerritoryMember geoTech4 = FS_TestDataFactory.createTestTerritoryMember(tech, geo4, 'S');

		Test.startTest();

		//SMAX_PS_TechnicianGeoBatch b1 = new SMAX_PS_TechnicianGeoBatch();
		//Database.executeBatch(b1);

		Test.stopTest();
	}

}