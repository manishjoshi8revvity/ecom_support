@isTest
public class FS_Location_UT {
	@testSetup
	static void setup() {
		Account acc= new Account();
		acc.Name='Test Account';
		insert acc;

		Contact con = new Contact();
		con.FirstName='New';
		con.LastName='Test';
		insert con;
		ERP_Address__c add = new ERP_Address__c();

		insert add;
		Country__c country = new Country__c();
		country.Global_Territory__c='EM INDIA';
		country.Sub_Territory__c='INDIA SA';
		country.Super_Territory__c='KOSJ';
		country.Territory__c='EMT AND INDIA';
		insert country;
		State__c state = new State__c();
		state.Country__c=country.Id;
		state.ISOCode__c='INMaharashtra';

		insert state;

		OperatingHours op =new OperatingHours();
		op.Name='DEFAULT';
		insert op;

		Schema.Location loc = new Schema.Location();
		loc.Name='Test';
		loc.LocationType='Site';
		loc.IsInventoryLocation=true;
		loc.IsMobile= true;
		loc.External_ID__c='GBA2F006';
		loc.SoldToExtID__c='GBA2F006';
		loc.ContactExtId__c='1UZ2GBA2F007';
		loc.Contact__c=con.Id;
		loc.SalesOrg__c='EEU2';
		loc.Account__c=acc.Id;
		loc.BillToExtID__c='';
		loc.PayerExtId__c='';
		loc.ShipToExtID__c='';
		loc.LL_BillToExtID__c='';
		loc.LL_ShipToExtID__c='';
		loc.ShipTo__c=add.Id;
		loc.Country__c='';
		loc.State__c='';
		// loc.Depot_Queue_Name__c='Queue';
		//loc.LocationCode__c='F003';
		insert loc;

		/*   Asset asst = new Asset();
		   asst.Name='Test Asset Id';
		   asst.LocationId = loc.Id;
		   asst.AccountId=acc.id;
		  // asst.ContactId=con.Id;
		   insert asst;*/

		/* Group grop = new Group();
		 grop.DeveloperName='Queue';
		 insert grop;*/

		ERP_Relationship__c relation= new ERP_Relationship__c();
		relation.Contact__c=con.Id;
		relation.External_Id__c='1UZ2GBA2F008';
		insert relation;
	}
	@isTest
	static void testUpdateTechnicianLocations() {
		Account acco =[Select Id, Name from Account];
		List<Schema.Location> serRes = [SELECT Id, Name, IsInventoryLocation, External_ID__c,Geography__c,AltCustomerNumber__c,SoldTo__c,BillToExtID__c,PayerExtId__c,ContactExtId__c,
				Account__c,SalesOrg__c,Contact__c,Country__c,BillTo__c,LKUP_Country__c,LKUP_State__c,Payer__c,LL_ShipTo__c,ShipTo__c,LL_BillTo__c,ShipToExtID__c,LL_BillToExtID__c,LL_ShipToExtID__c, LocationCode__c FROM Location];


		serRes[0].SoldToExtID__c = acco.Id;
		serRes[0].ContactExtId__c='1UZ2GBA2F008';
		serRes[0].BillToExtID__c='1UZ2GBA2F008';
		serRes[0].PayerExtId__c='1UZ2GBA2F008';
		serRes[0].ShipToExtID__c='1UZ2GBA2F008';
		serRes[0].LL_BillToExtID__c='1UZ2GBA2F008';
		serRes[0].LL_ShipToExtID__c='1UZ2GBA2F008';
		serRes[0].Country__c='IN';
		serRes[0].State__c='Maharashtra';

		update serRes[0];
		Map<Id, Schema.Location> oldMap = new Map<Id, Schema.Location>([SELECT Id, Name, IsInventoryLocation,AltCustomerNumber__c,
				Account__c,SalesOrg__c,LKUP_Country__c,Geography__c,LKUP_State__c,Payer__c,LL_ShipTo__c,ShipTo__c,LL_BillTo__c,BillTo__c,LL_ShipToExtID__c,ShipToExtID__c,LL_BillToExtID__c,External_ID__c,BillToExtID__c,SoldTo__c,PayerExtId__c,Contact__c,Country__c, ContactExtId__c, SoldToExtID__c
		FROM Location]);
		Test.startTest();
		FS_LocationManager.lookupLocationCustomers(serRes, oldMap);
		Test.stopTest();

	}
	@isTest
	static void updateInventoryAddressTest(){
		List<Account> acco =[Select Id, Name,SAP_City__c,SAP_Region__c,SAP_Postal_Code__c,SAP_Country_Code__c from Account];
		List<Schema.Location> serRes = [SELECT Id, Name, IsInventoryLocation, External_ID__c,AltCustomerNumber__c,Geography__c,SoldTo__c,BillToExtID__c,PayerExtId__c,ContactExtId__c,
				Account__c,SalesOrg__c,Contact__c,Country__c,BillTo__c,LKUP_Country__c,LKUP_State__c,Payer__c,LL_ShipTo__c,ShipTo__c,LL_BillTo__c,ShipToExtID__c,LL_BillToExtID__c,LL_ShipToExtID__c, LocationCode__c FROM Location];

		acco[0].SAP_Street__c='Test';
		acco[0].SAP_City__c='Pune';
		acco[0].SAP_Region__c='Maharashtra';
		acco[0].SAP_Postal_Code__c='410511';
		acco[0].SAP_Country_Code__c='91';
		update acco[0];
		Map<Id, Account> oldMap= new Map<Id, Account>([Select Id, Name,SAP_City__c,SAP_Region__c,SAP_Postal_Code__c,SAP_Country_Code__c  from Account]);
		Test.startTest();
		//   FS_LocationManager.updateInventoryAddress(acco, oldMap);
		Test.stopTest();
	}

	@isTest
	static void lookupLocationGeographyTest(){
		List<Schema.Location> serRes = [SELECT Id, Name, IsInventoryLocation, External_ID__c,AltCustomerNumber__c,SoldTo__c,BillToExtID__c,PayerExtId__c,ContactExtId__c,
				Account__c,SalesOrg__c,Contact__c,Country__c,BillTo__c,LKUP_Country__c,Geography__c,LKUP_State__c,Payer__c,LL_ShipTo__c,ShipTo__c,LL_BillTo__c,ShipToExtID__c,LL_BillToExtID__c,LL_ShipToExtID__c, LocationCode__c FROM Location];


		serRes[0].ContactExtId__c='1UZ2GBA2F008';
		serRes[0].BillToExtID__c='1UZ2GBA2F008';
		serRes[0].PayerExtId__c='1UZ2GBA2F008';
		serRes[0].ShipToExtID__c='1UZ2GBA2F008';
		serRes[0].LL_BillToExtID__c='1UZ2GBA2F008';
		serRes[0].LL_ShipToExtID__c='1UZ2GBA2F008';
		serRes[0].Country__c='IN';
		serRes[0].State__c='Maharashtra';
		serRes[0].LocationCode__c='USFL05';
		serRes[0].IsInventoryLocation=false;
		update serRes[0];
		Map<Id, Schema.Location> oldMap = new Map<Id, Schema.Location>([SELECT Id, Name, IsInventoryLocation,AltCustomerNumber__c,
				Account__c,SalesOrg__c,LKUP_Country__c,Geography__c,LKUP_State__c,Payer__c,LL_ShipTo__c,ShipTo__c,LL_BillTo__c,BillTo__c,LL_ShipToExtID__c,ShipToExtID__c,LL_BillToExtID__c,External_ID__c,BillToExtID__c,SoldTo__c,PayerExtId__c,Contact__c,Country__c, ContactExtId__c, SoldToExtID__c
		FROM Location]);
		Test.startTest();
		FS_LocationManager.lookupLocationGeography(serRes, oldMap);
		Test.stopTest();
	}

	@IsTest
	static void testInvLocaiton() {
		String erpID = 'TESTX000000001';
		Account acct1 = FS_TestDataFactory.createTestErpAccount('FieldServiceTest', 999, erpID, 'US10');

		Test.startTest();

		Schema.Location loc = new Schema.Location();
		loc.Name = 'TestLoc';
		loc.Account__c = acct1.Id;
		loc.External_ID__c = erpID;
		loc.LocationCode__c = 'T001';
		loc.MaintenancePlant__c = 'US12';
		loc.SalesOrg__c = 'US10';
		loc.IsInventoryLocation = true;
		loc.IsMobile = true;
		insert loc;

		Schema.Location locResult = [SELECT Id, Name, ShipTo__c FROM Location WHERE Id = :loc.Id];
		Assert.areNotEqual(null, locResult.ShipTo__c);

		Test.stopTest();
	}

}