@IsTest
public class FS_CreateInstallWorkOrdersBatch_UT {

	@TestSetup
	static void setupTestData() {
		FS_TestDataFactory.createDefaultOperatingHours();
	}

	@IsTest
	public static void testSuccessBatch(){

		String erpId = 'TESTXYZ0000001';
		Account acct = FS_TestDataFactory.createTestErpAccount('PkiTest', 999, erpId, 'GB');
		Contact cont = FS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTXYZ000001A');
		Product2 pd = FS_TestDataFactory.createTestProduct('TestProduct', 'PRXYZ106','ZZZ');

		Schema.Location loc = FS_TestDataFactory.createTestLocation(acct,'TestLocationSite', 'TESTXYZ121212','LOC123');

		Asset ip = FS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);
		ip.External_ID__c = 'TESTXYZ00001I';
		update ip;

		FS_InstallRequest__c ir = new FS_InstallRequest__c();
		ir.Account_ExtId__c = erpId;
		ir.Contact_ExtId__c = cont.SAP_Contact_ID__c;
		ir.Asset_ExtId__c= ip.External_ID__c;
		ir.Location_ExtId__c = loc.External_ID__c;
		ir.Product_ExtId__c = pd.Partnum__c;
		ir.InstallType__c = 'INSTALLATION';
		ir.SalesOrderNumber__c = 'SOXYZ10010';
		ir.SalesOrderLineNumber__c = '0012';
		ir.External_Id__c = ir.SalesOrderNumber__c + '-' + ir.SalesOrderLineNumber__c + '-' + ir.Asset_ExtId__c;

		insert ir;

		Test.startTest();

		FS_CreateInstallWorkOrdersBatch obj = new FS_CreateInstallWorkOrdersBatch(new Set<String> { 'TS10' });
		Database.executeBatch(obj);

		Test.stopTest();

		/*FS_InstallRequest__c result = [SELECT Id, Name, SMAX_PS_Status__c, SMAX_PS_Account__c, SMAX_PS_Location__c, SMAX_PS_Product__c,
		  SMAX_PS_InstalledProduct__c, SMAX_PS_Contact__c FROM SMAX_PS_Install_Request__c WHERE Id = :ir.Id];
		System.debug('RESULT InstallRequest (Success): ' + result);
		System.assertEquals(acct.Id, result.SMAX_PS_Account__c);
		System.assertEquals(loc.Id, result.SMAX_PS_Location__c);
		System.assertEquals(pd.Id, result.SMAX_PS_Product__c);
		System.assertEquals(ip.Id, result.SMAX_PS_InstalledProduct__c);
		System.assertEquals(cont.Id, result.SMAX_PS_Contact__c);
		System.assertEquals('Success', result.SMAX_PS_Status__c);*/
	}


	@IsTest
	public static void testOnHoldBatch(){

		String erpId = 'TESTXYZ0000001';
		Account acct = FS_TestDataFactory.createTestErpAccount('PkiTest', 999, erpId, 'GB');
		Contact cont = FS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTXYZ000001A');
		Product2 pd = FS_TestDataFactory.createTestProduct('TestProduct', 'PRXYZ106','ZZZ');

		Schema.Location loc = FS_TestDataFactory.createTestLocation(acct,'TestLocationSite', 'TESTXYZ121212','LOC123');
		Asset ip = FS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);
		ip.External_ID__c = 'TESTXYZ00001I';
		update ip;

		FS_InstallRequest__c ir = new FS_InstallRequest__c();
		ir.Account_ExtId__c = erpId + '??';
		ir.Contact_ExtId__c = cont.SAP_Contact_ID__c + '??';
		ir.Asset_ExtId__c = ip.External_ID__c + '??';
		ir.Location_ExtId__c = loc.External_ID__c + '??';
		ir.Product_ExtId__c = pd.Partnum__c + '??';
		ir.InstallType__c = 'INSTALLATION';
		ir.SalesOrderNumber__c = 'SOXYZ10010';
		ir.SalesOrderLineNumber__c = '0012';
		ir.External_Id__c = ir.SalesOrderNumber__c + '-' + ir.SalesOrderLineNumber__c + '-' + ir.Asset_ExtId__c;

		insert ir;

		Test.startTest();

		FS_CreateInstallWorkOrdersBatch obj = new FS_CreateInstallWorkOrdersBatch(null);
		Database.executeBatch(obj);

		Test.stopTest();

		/*SMAX_PS_Install_Request__c result = [SELECT Id, Name, SMAX_PS_Status__c, SMAX_PS_Account__c, SMAX_PS_Location__c, SMAX_PS_Product__c,
		  SMAX_PS_InstalledProduct__c, SMAX_PS_Contact__c FROM SMAX_PS_Install_Request__c WHERE Id = :ir.Id];
		System.debug('RESULT InstallRequest (On-Hold): ' + result);
		System.assertEquals(null, result.SMAX_PS_Account__c);
		System.assertEquals(null, result.SMAX_PS_Location__c);
		System.assertEquals(null, result.SMAX_PS_Product__c);
		System.assertEquals(null, result.SMAX_PS_InstalledProduct__c);
		System.assertEquals(null, result.SMAX_PS_Contact__c);
		System.assertEquals('On-Hold', result.SMAX_PS_Status__c);*/
	}

	@IsTest
	public static void testSalesOrgBatch(){

		String erpId = 'TESTXYZ0000001';
		Account acct = FS_TestDataFactory.createTestErpAccount('PkiTest', 999, erpId, 'GB');
		Contact cont = FS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTXYZ000001A');
		Product2 pd = FS_TestDataFactory.createTestProduct('TestProduct', 'PRXYZ106','ZZZ');

		Schema.Location loc1 = FS_TestDataFactory.createTestLocation(acct,'TestLocationSite1', 'TESTXYZ121111','LOC1_1');
		Schema.Location loc2 = FS_TestDataFactory.createTestLocation(acct,'TestLocationSite2', 'TESTXYZ122222','LOC1_2');
		loc1.SalesOrg__c = 'TST1';
		loc2.SalesOrg__c = 'TST2';
		update new List<Schema.Location> { loc1, loc2 };

		Asset ip1 = FS_TestDataFactory.createIP('123456-1',acct,loc1,'5545333',pd);
		ip1.External_ID__c = 'TESTXYZ00001I';
		Asset ip2 = FS_TestDataFactory.createIP('123456-2',acct,loc2,'5545333',pd);
		ip2.External_ID__c = 'TESTXYZ00002I';
		update new List<Asset> { ip1, ip2 };

		FS_InstallRequest__c ir1 = new FS_InstallRequest__c ();
		ir1.Account_ExtId__c = erpId;
		ir1.Contact_ExtId__c = cont.SAP_Contact_ID__c;
		ir1.Asset_ExtId__c= ip1.External_ID__c;
		ir1.Location_ExtId__c = loc1.External_ID__c;
		ir1.Product_ExtId__c = pd.Partnum__c;
		ir1.InstallType__c = 'INSTALLATION';
		ir1.SalesOrderNumber__c = 'SOXYZ10010';
		ir1.SalesOrderLineNumber__c = '0012';
		ir1.External_Id__c = ir1.SalesOrderNumber__c + '-' + ir1.SalesOrderLineNumber__c + '-' + ir1.Asset_ExtId__c;

		FS_InstallRequest__c ir2 = new FS_InstallRequest__c ();
		ir2.Account_ExtId__c = erpId;
		ir2.Contact_ExtId__c = cont.SAP_Contact_ID__c;
		ir2.Asset_ExtId__c= ip2.External_ID__c;
		ir2.Location_ExtId__c = loc2.External_ID__c;
		ir2.Product_ExtId__c = pd.Partnum__c;
		ir2.InstallType__c = 'INSTALLATION';
		ir2.SalesOrderNumber__c = 'SOXYZ10010';
		ir2.SalesOrderLineNumber__c = '0012';
		ir2.External_Id__c = ir2.SalesOrderNumber__c + '-' + ir2.SalesOrderLineNumber__c + '-' + ir2.Asset_ExtId__c;

		insert new List<FS_InstallRequest__c > { ir1, ir2 };

		Test.startTest();

		FS_CreateInstallWorkOrdersBatch obj = new FS_CreateInstallWorkOrdersBatch(new Set<String> { 'TST2' });
		Database.executeBatch(obj);

		Test.stopTest();

		/* SMAX_PS_Install_Request__c result1 = [SELECT Id, Name, SMAX_PS_Status__c, SMAX_PS_Account__c, SMAX_PS_Location__c, SMAX_PS_Product__c,
		   SMAX_PS_InstalledProduct__c, SMAX_PS_Contact__c, SMAX_PS_Error_Message__c FROM SMAX_PS_Install_Request__c WHERE Id = :ir1.Id];
		 System.debug('RESULT InstallRequest (SalesOrg On-Hold): ' + result1);
		 System.assertNotEquals(null, result1.SMAX_PS_Location__c);
		 // ITSVMX-1278 Do not set to On-Hold
		 //System.assertEquals('On-Hold', result1.SMAX_PS_Status__c);
		 System.assert(result1.SMAX_PS_Error_Message__c.contains('SalesOrg'));

		 SMAX_PS_Install_Request__c result2 = [SELECT Id, Name, SMAX_PS_Status__c, SMAX_PS_Account__c, SMAX_PS_Location__c, SMAX_PS_Product__c,
		   SMAX_PS_InstalledProduct__c, SMAX_PS_Contact__c, SMAX_PS_Error_Message__c FROM SMAX_PS_Install_Request__c WHERE Id = :ir2.Id];
		 System.debug('RESULT InstallRequest (SalesOrg Success): ' + result2);
		 System.assertNotEquals(null, result2.SMAX_PS_Location__c);
		 System.assertEquals('Success', result2.SMAX_PS_Status__c);*/
	}
}