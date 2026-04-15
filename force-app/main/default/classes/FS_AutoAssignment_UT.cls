/**
 * Created by frankvanloon on 7/16/24.
 */
@IsTest
public class FS_AutoAssignment_UT {

	@TestSetup
	static void setupTest() {
		FS_TestDataFactory.createDefaultOperatingHours();
	}

	@IsTest
	static void test_createResourcePreferences()
	{
		Account acct = FS_TestDataFactory.createTestErpAccount('PkiTest', 999,'TESTX000000001','GB');
		Contact cont = FS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
		Product2 pd = FS_TestDataFactory.createTestProduct('TestProduct', '106018','ZZZ');
		pd.Super_Business_Unit__c = 'DAS';
		update pd;

		Schema.Location loc = FS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
		loc.MaintenancePlant__c = 'TT12';
		update loc;

		Product2 laborProd = FS_TestDataFactory.createTestProduct('TestLabor', 'LAB100101', 'ZZZ', 'Labor');
		Product2 travelProd = FS_TestDataFactory.createTestProduct('TestTravel', 'TRV10011', 'ZZZ', 'Travel');

		User techUser = new User(Id = UserInfo.getUserId());
		ServiceResource tech = FS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001', 'TS12T001');

		Asset ip = FS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);
		ip.PreferredTechnicianNumber__c = tech.External_ID__c;
		update ip;

		// Insert Work Order
		WorkOrder wo = FS_TestDataFactory.createWO(ip, cont);

		WorkOrder result = [SELECT Id, WorkOrderNumber, Super_Business_Unit__c FROM WorkOrder WHERE Id = :wo.Id];
		System.assertEquals(pd.Super_Business_Unit__c, result.Super_Business_Unit__c);

		Test.startTest();

		wo.External_ID__c = 'SO001991992';
		wo.SAP_SystemStatus__c = 'REL';
		wo.CreditHold__c = false;
		wo.SAP_Work_Center__c = tech.Work_Center__c;
		update wo;

		List<ResourcePreference> prefs = [SELECT Id, ResourcePreferenceNumber FROM ResourcePreference
			WHERE RelatedRecordId = :wo.Id];
		System.assertEquals(false, prefs.isEmpty());

		Test.stopTest();
	}

}