@IsTest
public class FS_ServiceContract_UT
{
	@IsTest
	static void updateServiceContractDeleted()
	{
		Map<String, SObject> data = createTestData();
		ServiceContract scParent = (ServiceContract) data.get('Contract');
		ServiceContract item = (ServiceContract) data.get('Item');

		// update Parent contract Completed Transaction Number
		scParent.CompletedTxnNum__c='tran2';
		update scParent;
		item.PreviousContractNumber__c='EXT_ID1';
		item.RenewalContractNumber__c='EXT_ID2';
		update item;

		// NOTE: In the above test, since "SMAX_PS_LastTxnNum__c" didn't match, the trigger marked all for deletion

		// Now we'll restore them...
		scParent.CompletedTxnNum__c='tran1';
		update scParent;

		// Now test by Cancel Notes..
		item.Cancelation_Notes__c = '17';
		update item;

		scParent.CompletedTxnNum__c='tran2';
		update scParent;

		scParent.CompletedTxnNum__c='tran1';
		update scParent;
	}

	@IsTest
	static void updateServiceContractSuccess()
	{
		Map<String, SObject> data = createTestData();
		ServiceContract scParent = (ServiceContract) data.get('Contract');
		ServiceContract item = (ServiceContract) data.get('Item');

		Test.startTest();

		// update Parent contract Completed Transaction Number
		scParent.CompletedTxnNum__c='tran1';
		update scParent;

		item.PreviousContractNumber__c='EXT_ID1';
		item.RenewalContractNumber__c='EXT_ID2';
		update item;

		Test.stopTest();

		// ITSVMX-228 Map contract type from Parent contract (header) to line items (create a new field on the page layout)
		// Test that the Line Item was updated
		List<ServiceContract> scChild = [ SELECT Id, ContractType__c FROM ServiceContract WHERE Id = :item.Id  ];
		//System.debug('Parent Service Contract - Contract Type: ' + scParent.SMAX_PS_ContractType__c);
		//System.debug('Contract Item - Contract Type: ' + scChild[0].SMAX_PS_ContractType__c);
		//System.assertEquals(scParent.SMAX_PS_ContractType__c, scChild[0].SMAX_PS_ContractType__c);

		Account acct = (Account) data.get('Account');
		Contact cont = (Contact) data.get('Contact');
		Schema.Location loc = ( Schema.Location) data.get('Location');
		FS_EntitlementDate__c ed = (FS_EntitlementDate__c) data.get('EntDate');

		// NOTE: In the above test, since ALL of the child records populated "SMAX_PS_LastTxnNum__c", the trigger DID NOT mark for deletion
		Asset ip = FS_TestDataFactory.createIP('123456',acct,loc,'5545333',null);
		WorkOrder wo = FS_TestDataFactory.createWO(ip, cont);
		wo.External_ID__c = 'TEST1001001001';
		update wo;

		ed.ServiceOrderNumber__c = wo.External_ID__c;
		update ed;

		//FS_EntitlementDate__c result = [SELECT Id, Name, WorkOrder__c FROM FS_EntitlementDate__c WHERE Id = :ed.Id];
		//System.assertEquals(wo.Id, result.SMAX_PS_WorkOrder__c);

		// SVMXINT-571 validate that the Service Contract Event was sent
		//List<SObject> testEvents = FS_Utility.retrieveTestEvents('FS_ServiceContract_Event__e');
		//System.assertEquals(1, testEvents.size());
	}

	@IsTest
	static void test_getEntitlementCoverage() {
		Map<String, SObject> data = createTestData();
		Asset ip = (Asset) data.get('Asset');

		Test.startTest();

		List<FS_ServiceContractManager.EntitlementCoverage> ipCoverage = FS_ServiceContractManager.getEntitlementCoverage(ip.Id);
		System.assertEquals(false, ipCoverage.isEmpty());

		Test.stopTest();
	}

	private static Map<String, SObject> createTestData()
	{
		String erpID = 'TESTX00001';
		Account acct = FS_TestDataFactory.createTestErpAccount('PkiTest', 999, erpID, 'US10');
		String contactExtId = 'TESTX0001A';
		Contact cont = FS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, contactExtId);
		Product2 prod = FS_TestDataFactory.createTestProduct('Prod', 'PROD1234', 'HCS');
		// Insert location
		Schema.Location loc = new Schema.Location(
				Name='Test Location',
				Street__c='123 street',
				City__c='123 city',
				State__c='123 state',
				Zip__c='12345',
				Country__c='US');
		insert loc;

		Asset ip = FS_TestDataFactory.createIP('123456',acct,loc,'5545333',null);

		// insert Service Contract
		// ITSVMX-228 Added Contract Type
		Date startDt = Date.today().addMonths(-1);
		Date endDt = Date.today().addMonths(11);
		ServiceContract scParent = new ServiceContract(
				Name='Test Parent Contract',
				AccountId=acct.Id,
				ContactId=cont.Id,
				StartDate=startDt,
				EndDate=endDt,
				LastTxnNum__c ='tran1',
				CompletedTxnNum__c='tran',
				External_ID__c='EXT_ID1',
				ContractType__c = 'ContractType',
				SoldToNumber__c = erpID,
				ShipToNumber__c = erpID,
				Contact_External_ID__c = contactExtId
		);
		insert scParent;

		Pricebook2 pb = new Pricebook2();
		pb.Name='test';
		pb.IsActive = true;
		insert pb;

		Id pricebookId = Test.getStandardPricebookId();
		Pricebook2 standardPricebook = new Pricebook2(
				Id = pricebookId,
				IsActive = true
		);
		update standardPricebook;

		PricebookEntry pbe2 = new PricebookEntry();
		pbe2.Pricebook2Id= pricebookId;
		pbe2.Product2Id = prod.Id;
		pbe2.UnitPrice=20;
		pbe2.IsActive=true;
		insert pbe2;

		PricebookEntry pbe = new PricebookEntry();
		pbe.Pricebook2Id= pb.Id;
		pbe.Product2Id = prod.Id;
		pbe.UnitPrice=20;
		pbe.IsActive=true;
		insert pbe;

		// ITSVMX-228 added Contract Item record type
		//Id contractItemRTId = Schema.SObjectType.ServiceContract.getRecordTypeInfosByDeveloperName().get('ContractItem').getRecordTypeId();
		ServiceContract item = new ServiceContract(
				Name='Test Contract',
				AccountId=acct.Id,
				ContactId=cont.Id,
				StartDate=startDt,
				EndDate=endDt,
				LastTxnNum__c ='tran1',
				ParentServiceContractId=scParent.Id,
				Pricebook2Id=pb.Id
		);
		insert item;

		// insert covered Product
		ContractLineItem cp = new ContractLineItem(
				LastTxnNum__c ='tran1',
				ServiceContractId=item.Id,
				AssetId = ip.Id,
				Quantity=1,
				UnitPrice=20,
				StartDate=startDt,
				EndDate=endDt,
				PricebookEntryId=pbe.Id,
				Parent_Contract__c = scParent.Id,
				SLA_Terms_Notes__c = 'Testing');
		insert cp;
		// insert included Services
		Entitlement is = new Entitlement(
				Name = 'test',
				AccountId=acct.Id,
				LastTxnNum__c ='tran1',
				ServiceContractId=item.Id);
		insert is;

		// insert Entitlement Dates
		FS_EntitlementDate__c ed = new FS_EntitlementDate__c(
				LastTxnNum__c ='tran1',
				Entitlement__c=is.Id,
				CoveredProduct__c=cp.Id,
				ContractItem__c = item.Id,
				PlannedDate__c = Date.today());
		insert ed;

		Map<String, SObject> result = new Map<String, SObject>();
		result.put('Account', acct);
		result.put('Contact', cont);
		result.put('Location', loc);
		result.put('Asset', ip);
		result.put('Contract', scParent);
		result.put('Item', item);
		result.put('EntDate', ed);

		return result;
	}

	/*static testMethod void svcContract_TxnBatch_Sucess()
	{
	  Map<String, SObject> data = createTestData();
	  ServiceContract scParent = (ServiceContract) data.get('Contract');
	  ServiceContract item = (ServiceContract) data.get('Item');

	  Test.startTest();
	  SMAX_PS_ServiceContract_TxnNum_Batch b = new SMAX_PS_ServiceContract_TxnNum_Batch();
	  b.execute(null);
	  //Database.executeBatch(b);
	  Test.stopTest();
	}

	static testMethod void svcContract_TxnBatch_Deleted()
	{
	  Map<String, SObject> data = createTestData();
	  SVMXC__Service_Contract__c scParent = (SVMXC__Service_Contract__c) data.get('Contract');
	  // This will cause the children to not match, and get marked as deleted
	  scParent.SMAX_PS_LastTxnNum__c = 'tran2';
	  update scParent;

	  Test.startTest();
	  SMAX_PS_ServiceContract_TxnNum_Batch b = new SMAX_PS_ServiceContract_TxnNum_Batch();
	  b.execute(null);
	  //Database.executeBatch(b);
	  Test.stopTest();
	}

	@IsTest static void svcContract_TxnNumController()
	{
	  Map<String, SObject> data = createTestData();
	  SVMXC__Service_Contract__c scParent = (SVMXC__Service_Contract__c) data.get('Contract');
	  SVMXC__Service_Contract__c item = (SVMXC__Service_Contract__c) data.get('Item');
	  //item.SMAX_PS_IsDeleted__c = true;
	  //item.SVMXC__Cancelation_Notes__c = '';
	  //update item;

	  PageReference pageRef = Page.SMAX_PS_ServiceContract_TxnNum;
	  pageRef.getParameters().put('id', item.Id);
	  Test.setCurrentPage(pageRef);

	  //ApexPages.currentPage().getParameters().put('id', item.Id);

	  Apexpages.StandardController sc = new Apexpages.StandardController(item);

	  SMAX_PS_ServiceContract_TxNumController controller = new SMAX_PS_ServiceContract_TxNumController(sc);

	  Test.startTest();
	  controller.scheduleServiceContractTxnNumBatch();
	  Test.stopTest();
	}*/
}