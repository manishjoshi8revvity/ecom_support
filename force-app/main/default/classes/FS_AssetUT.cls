@IsTest
public class FS_AssetUT
{
	@IsTest
	static void createTestData()
	{
		FS_TestDataFactory.createDefaultOperatingHours();

		// Insert Product
		Product2 prod = new Product2(Name='Test Product');
		insert prod;

		String erpID = 'TESTX00001';
		Account acct1 = FS_TestDataFactory.createTestErpAccount('FieldServiceTest', 999, erpID, 'TS10');
		Schema.Location loc = FS_TestDataFactory.createTestLocation(acct1, 'TestLoc', 'T001002993', 'T001');
		Schema.Location loc2 = FS_TestDataFactory.createTestLocation(acct1, 'TestLoc2', 'T002003992', 'T002');

		// Insert Installed Product
		Asset ip = new Asset(SoldTo_ExtId__c=erpID, Name='Test Asset', Product2Id = prod.Id, LocationId =loc.Id);
		insert ip;

		ip.CompletedTxnNum__c='ABC';
		ip.LocationId  = loc2.Id;
		update ip;

		Asset updated = [SELECT Id, Name, City FROM Asset WHERE Id = :ip.Id];
		System.assertEquals(loc2.City__c, updated.City);

		delete ip;
	}

	@IsTest
	static void testLookups()
	{
		OperatingHours oh = new OperatingHours();
		oh.Name='DEFAULT';
		insert oh;

		String erpID = 'TESTX00001';
		Account acct = FS_TestDataFactory.createTestErpAccount('FieldServiceTest', 999, erpID, 'TS10');
		Product2 pd = FS_TestDataFactory.createTestProduct('TestProduct', '106018','ZZZ');
		Schema.Location loc = FS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', 'LOC101');
		Asset ip = FS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TestSeries001', pd);

		Asset result = [SELECT Id, Name, Preferred_Technician__c, Secondary_Technician__c,SoldTo_Account__c, ShipTo_Account__c, BillTo_Account__c, Payer_Account__c,LL_ShipTo_Account__c, LL_BillTo_Account__c FROM Asset WHERE Id = :ip.Id];

		/* System.assertEquals(null, result.SVMXC__Preferred_Technician__c);
		 System.assertEquals(null, result.SMAX_PS_Secondary_Technician__c);
		 System.assertEquals(null, result.SMAX_PS_SoldTo_Account__c);
		 System.assertEquals(null, result.SMAX_PS_ShipTo_Account__c);
		 System.assertEquals(null, result.SMAX_PS_BillTo_Account__c);
		 System.assertEquals(null, result.SMAX_PS_Payer_Account__c);
		 System.assertEquals(null, result.SMAX_PS_LL_ShipTo_Account__c);
		 System.assertEquals(null, result.SMAX_PS_LL_BillTo_Account__c);*/

		Asset update1 = new Asset();
		update1.AccountId=acct.Id;
		update1.Id = ip.Id;
		update1.PreferredTechnicianNumber__c = 'T001';
		update1.SecondaryTechnicianNumber__c = 'JUNK_VALUE';
		update1.SoldTo_ExtId__c = erpID;
		update1.ShipTo_ExtId__c = erpID;
		update1.BillTo_ExtId__c = 'JUNK_VALUE';
		update1.Payer_ExtId__c = erpID;
		update1.LL_ShipTo_ExtId__c = null;
		update1.LL_BillTo_ExtId__c = erpID;
		update update1;

		result = [SELECT Id, Name, Preferred_Technician__c, Secondary_Technician__c,SoldTo_Account__c, ShipTo_Account__c, BillTo_Account__c, Payer_Account__c,LL_ShipTo_Account__c,LL_BillTo_Account__c FROM Asset WHERE Id = :ip.Id];

		//System.assertEquals(tech.Id, result.SVMXC__Preferred_Technician__c);
		//System.assertEquals(null, result.SMAX_PS_Secondary_Technician__c);
		System.assertNotEquals(null, result.SoldTo_Account__c);
		System.assertNotEquals(null, result.ShipTo_Account__c);
		System.assertEquals(null, result.BillTo_Account__c);
		System.assertNotEquals(null, result.Payer_Account__c);

		//Asset update2 = new Asset();
		//update2.Id = ip.Id;
		//update2.PreferredTechnicianNumber__c = tech2.External_ID__c;
		//update2.SecondaryTechnicianNumber__c = tech.External_ID__c;
	}

	@IsTest
	static void testCalibratedTools()
	{
		//RecordType calToolRecType =FS_Utility.getRecordType('Asset', 'Calibrated_Tools');
		Account acct1 = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
		Asset ip = new Asset();
		ip.SerialNumber = 'CALTOOL001';
		ip.Name='123';
		ip.AccountId=acct1.Id;
		insert ip;

		ip.MTE_Change_Reason__c = 'Data Correction';
		ip.MTE_Change_Description__c = 'Testing...';
		ip.SerialNumber = 'CALTOOL001-01';
		update ip;

	}

	// SVMXCFG-711 Ensure IP address is synced with Location address
	@IsTest
	static void testIpAddressBatch()
	{
		Account acct1 = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');

		Schema.Location loc1 = new  Schema.Location();
		loc1.Name='tt';
		loc1.Street__c = '123 Main Street';
		loc1.City__c = 'Anytown';
		loc1.State__c = 'FL';
		loc1.Zip__c = '33601';
		loc1.Country__c = 'US';
		insert loc1;

		Asset ip = FS_TestDataFactory.createIP('001', acct1, loc1,'TestSeries001');
		ip.Street = '';
		ip.City = '';
		ip.State = '';
		ip.PostalCode = '';
		ip.Country= '';
		update ip;

		Test.startTest();

		/* FS_InstalledProductAddresses_Batch bat1 = new SMAX_PS_InstalledProductAddresses_Batch();
		 Database.executeBatch(bat1);

		 SMAX_PS_InstalledProductAddresses_Batch bat2 = new SMAX_PS_InstalledProductAddresses_Batch();
		 System.schedule('testSchedJob', '0 0 23 * * ?', bat2);*/

		Test.stopTest();
	}
}