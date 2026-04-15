/**
 *  Schedulable Batch class for Creating Install Work Orders
 *  2017-11-14      Veerendra Moodbidri     Initial creation.
 *  2018-05-01		Frank VanLoon			Changes for SVMXINT-518: External ID Fields, Status, Error Message
 *  2018-06-18		Frank VanLoon			Updated for Phase 1.0: SVMXCFG-605
 *  CONVERTED to SFS by frankvanloon on 4/29/24.
 */
global class FS_CreateInstallWorkOrdersBatch implements Database.Batchable<SObject> , Schedulable {

	private static Map<String, String> ORDER_TYPE_MAP = new Map<String, String> { 'PIV' => 'Pre Install Visit', 'PHONE' => 'Phone', 'INSTALLATION' => 'Installation' };

	global Set<String> SALES_ORGS;

	public FS_CreateInstallWorkOrdersBatch(Set<String> salesOrgs)
	{
		this.SALES_ORGS = salesOrgs;
	}

	/** 
		Schedulable methods 
	**/

	global void execute(SchedulableContext sc) {
		FS_CreateInstallWorkOrdersBatch cInstallWObatch = new FS_CreateInstallWorkOrdersBatch(this.SALES_ORGS);
		Database.executeBatch(cInstallWObatch, 1);
	}

	/* 
		Batchable methods 
	*/

	global Database.QueryLocator start(Database.BatchableContext BC) {

		return Database.getQueryLocator([SELECT Id, Name, Status__c,
				InstallType__c, Account__c, Location__c, Product__c,
				Asset__c, SalesOrderNumber__c, SalesOrderLineNumber__c,
				Contact__c, ContactName__c, ContactPhone__c, ContactEmail__c,
				TechnicianAccount__c, ProductSeries__c, SalesOrderLinesDescription__c,
				Asset__r.Location.ShipTo__c,
				Asset__r.Location.BillTo__c,
				Asset__r.Location.Payer__c,
				Account_ExtId__c, Contact_ExtId__c, Asset_ExtId__c,
				Location_ExtId__c, Product_ExtId__c
			FROM FS_InstallRequest__c WHERE WorkOrder__c = NULL AND Status__c != 'Canceled']);
	}

	global void execute(Database.BatchableContext BC, List<FS_InstallRequest__c> irList)
	{
		// First pass.. collect external ids to related objects
		Set<String> acctExtIds = new Set<String>();
		Set<String> contactExtIds = new Set<String>();
		Set<String> ipExtIds = new Set<String>();
		Set<String> locExtIds = new Set<String>();
		Set<Id> locIds = new Set<Id>();
		Set<String> productExtIds = new Set<String>();
		Set<Id> ipIds = new Set<Id>();
		for (FS_InstallRequest__c ir : irList) {
			if (ir.Account__c == null && String.isNotBlank(ir.Account_ExtId__c)) {
				acctExtIds.add(ir.Account_ExtId__c);
			}
			if (ir.Contact__c == null && String.isNotBlank(ir.Contact_ExtId__c)) {
				contactExtIds.add(ir.Contact_ExtId__c);
			}
			if (ir.Asset__c == null && String.isNotBlank(ir.Asset_ExtId__c)) {
				ipExtIds.add(ir.Asset_ExtId__c);
			}
			if (ir.Location__c == null && String.isNotBlank(ir.Location_ExtId__c)) {
				locExtIds.add(ir.Location_ExtId__c);
			}
			if (ir.Location__c != null) {
				locIds.add(ir.Location__c);
			}
			if (ir.Product__c == null && String.isNotBlank(ir.Product_ExtId__c)) {
				productExtIds.add(ir.Product_ExtId__c);
			}
			if (ir.Asset__c != null) {
				ipIds.add(ir.Asset__c);
			}
		}

		// Lookup related records using their external ids
		Map<String, Account> acctMap = new Map<String, Account>();
		if (!acctExtIds.isEmpty())
		{
			//System.debug('~~~ LOOKUP Accounts: ' + acctExtIds);
			acctMap = FS_AccountManager.findAccounts(acctExtIds);
		}

		Map<String, Contact> contactMap = new Map<String, Contact>();
		if (!contactExtIds.isEmpty())
		{
			for (ERP_Relationship__c erp : [SELECT Id, Name, External_Id__c, Contact__r.Id, Contact__r.Name
				FROM ERP_Relationship__c WHERE External_Id__c IN :contactExtIds AND Contact__c != NULL])
			{
				contactMap.put(erp.External_Id__c, erp.Contact__r);
			}
		}

		Map<String, Asset> ipMap = new Map<String, Asset>();
		Map<Id, Asset> ipIdMap = new Map<Id, Asset>();
		if (!ipExtIds.isEmpty())
		{
			for (Asset ip : [SELECT Id, Name, External_ID__c, Technical_ID_Number__c, Building__c, Room__c
				FROM Asset WHERE External_ID__c IN :ipExtIds])
			{
				ipMap.put(ip.External_ID__c, ip);
				ipIdMap.put(ip.Id, ip);
			}
		}
		if (!ipIds.isEmpty())
		{
			for (Asset ip : [SELECT Id, Name, External_ID__c, Technical_ID_Number__c, Building__c, Room__c
				FROM Asset WHERE Id IN :ipIds])
			{
				ipIdMap.put(ip.Id, ip);
			}
		}

		// SVMXCFG-605: Batch Jobs - i18n Parameters
		Map<Id, String> locSalesOrgMap = new Map<Id, String>();

		Map<String, Schema.Location> locMap = new Map<String, Schema.Location>();
		if (!locExtIds.isEmpty())
		{
			for (Schema.Location loc : [SELECT Id, Name, External_ID__c, SalesOrg__c FROM Location WHERE External_ID__c IN :locExtIds])
			{
				locMap.put(loc.External_ID__c, loc);
				locSalesOrgMap.put(loc.Id, loc.SalesOrg__c);
			}
		}

		if (!locIds.isEmpty())
		{
			for (Schema.Location loc : [SELECT Id, Name, SalesOrg__c FROM Location WHERE Id IN :locIds])
			{
				locSalesOrgMap.put(loc.Id, loc.SalesOrg__c);
			}
		}

		Map<String, Product2> productMap = new Map<String, Product2>();
		if (!productExtIds.isEmpty())
		{
			for (Product2 prdct : [SELECT Id, Name, Part_Number__c FROM Product2 WHERE Part_Number__c IN :productExtIds])
			{
				productMap.put(prdct.Part_Number__c, prdct);
			}
		}

		//RecordType fieldServiceRT = Utility.getRecTypeDevNameMap('WorkOrder').get('Field_Service');
		List<WorkOrder> woList = new List<WorkOrder>();
		List<FS_InstallRequest__c> irWoList = new List<FS_InstallRequest__c>();
		for (FS_InstallRequest__c ir : irList) {
			// Assign Lookups... 
			List<String> missingLookups = new List<String>();
			if (ir.Account__c == null && String.isNotBlank(ir.Account_ExtId__c)) {
				Account acct = acctMap.get(ir.Account_ExtId__c);
				//System.debug('~~~ UPDATING Account: ' + acct);
				if (acct != null) {
					ir.Account__c = acct.Id;
				} else {
					missingLookups.add('Account not found: ' + ir.Account_ExtId__c);
				}
			}
			if (ir.Contact__c == null && String.isNotBlank(ir.Contact_ExtId__c)) {
				Contact cntct = contactMap.get(ir.Contact_ExtId__c);
				if (cntct != null) {
					ir.Contact__c = cntct.Id;
				} else {
					missingLookups.add('Contact not found: ' + ir.Contact_ExtId__c);
				}
			}
			if (ir.Asset__c == null && String.isNotBlank(ir.Asset_ExtId__c)) {
				Asset ip = ipMap.get(ir.Asset_ExtId__c);
				if (ip != null) {
					ir.Asset__c = ip.Id;
				} else {
					missingLookups.add('Installed Product not found: ' + ir.Asset_ExtId__c);
				}
			}
			if (ir.Location__c == null && String.isNotBlank(ir.Location_ExtId__c)) {
				Schema.Location loc = locMap.get(ir.Location_ExtId__c);
				if (loc != null) {
					ir.Location__c = loc.Id;
				} else {
					missingLookups.add('Location not found: ' + ir.Location_ExtId__c);
				}
			}
			if (ir.Product__c == null && String.isNotBlank(ir.Product_ExtId__c)) {
				Product2 prdct = productMap.get(ir.Product_ExtId__c);
				if (prdct != null) {
					ir.Product__c = prdct.Id;
				} else {
					missingLookups.add('Product not found: ' + ir.Product_ExtId__c);
				}
			}

			// If any Lookups are missing, put On-Hold and skip
			if (!missingLookups.isEmpty()) {
				ir.Status__c = 'On-Hold';
				ir.Error_Message__c = 'On-Hold due to missing lookup data: ' + missingLookups;
				continue;
			}

			// SVMXCFG-605: Batch Jobs - i18n Parameters
			if (this.SALES_ORGS != null && !this.SALES_ORGS.isEmpty())
			{
				String salesOrg = locSalesOrgMap.get(ir.Location__c);
				if (String.isBlank(salesOrg))
				{
					ir.Status__c = 'On-Hold';
					ir.Error_Message__c = 'On-Hold because unable to determine SalesOrg of Location: ' + ir.Location__c;
					continue;
				}
				else if (!this.SALES_ORGS.contains(salesOrg))
				{
					// ITSVMX-1278 Do not set to On-Hold, but don't process the WO either since it's not correct Sales Org
//					ir.Status__c = 'On-Hold';
					ir.Error_Message__c = 'Skipping due to SalesOrg: ' + salesOrg + ' ... not included in configured SalesOrg list: ' + this.SALES_ORGS;
					continue;
				}
			}

			WorkOrder wo = new WorkOrder();
			wo.Record_Type__c = 'Field Service';
			wo.Status = 'Initializing';
			wo.Billing_Type__c = 'Installation';
			wo.Order_Type__c = ORDER_TYPE_MAP.get(ir.InstallType__c);
			wo.AccountId = ir.Account__c;
			wo.LocationId = ir.Location__c;
			wo.Product__c = ir.Product__c;
			wo.AssetId = ir.Asset__c;
			wo.SalesOrderNumber__c = ir.SalesOrderNumber__c;
			wo.SalesOrderLineNumber__c = ir.SalesOrderLineNumber__c;
			wo.ContactId = ir.Contact__c;
			wo.ContactName__c = ir.ContactName__c;
			wo.Contact_Phone__c = ir.ContactPhone__c;
			wo.Contact_Email__c = ir.ContactEmail__c;
			//wo.SVMXC__Group_Member__c = ir.TechnicianAccount__c;
			wo.ProductSeries__c = ir.ProductSeries__c;
			wo.Internal_Description__c = ir.SalesOrderLinesDescription__c; // FORMERLY wo.SVMXC__Special_Instructions__c
			wo.Perform_Auto_Entitlement__c = false;
			wo.Perform_Auto_Assignment__c = false; //(ir.InstallType__c != 'PIV')
			wo.ShipTo__c = ir.Asset__r.Location.ShipTo__c;
			wo.BillTo__c = ir.Asset__r.Location.BillTo__c;
			wo.Payer__c = ir.Asset__r.Location.Payer__c;
			wo.Customer_Required_Start_Date__c = Date.today(); // FORMERLY: wo.SVMXC__Scheduled_Date__c

			// SVMXCFG-523: Problem Summary: MM/YYYY-Maintenance Activity Type-Technical ID-Building-Room
			Datetime entDate = Datetime.newInstance(wo.Customer_Required_Start_Date__c, Time.newInstance(0, 0, 0, 0));
			String ps = entDate.format('MM/yyyy') + '-' + ir.InstallType__c;

			Asset ip = (ir.Asset__c == null) ? null : ipIdMap.get(ir.Asset__c);
			if (ip != null) {
				if (String.isNotBlank(ip.Technical_ID_Number__c)) {
					ps += '-' + ip.Technical_ID_Number__c;
				}
				if (String.isNotBlank(ip.Building__c)) {
					ps += '-' + ip.Building__c;
				}
				if (String.isNotBlank(ip.Room__c)) {
					ps += '-' + ip.Room__c;
				}
			}

			wo.Description = ps;
			wo.Problem_Summary__c = (ps.length() > 40) ? ps.substring(0, 37) + '...' : ps;

			woList.add(wo);
			irWoList.add(ir);
		}

		//List<ErrorLog__c> logs = new List<ErrorLog__c>();
		if (!woList.isEmpty())
		{
			Database.SaveResult[] results = Database.insert(woList, false);
			for (Integer i = 0; i < results.size(); i++)
			{
				Database.SaveResult result = results[i];
				FS_InstallRequest__c ir = irWoList[i];
				WorkOrder wo = woList[i];
				if (!result.isSuccess())
				{
					String errorMsg = 'Error inserting Work Order for Install Request: ' + ir.Name + ' - ' + result.getErrors();
					System.debug(errorMsg);
					//logs.add(LogUtility.createLog(LogUtility.ERROR, errorMsg, 'CreateInstallWorkOrdersBatch', null, ir.Id));
					ir.Status__c = 'Error';
					ir.Error_Message__c = errorMsg;
				}
				else
				{
					System.debug('Success creating Install Request Work Order: ' + wo.Id);
					ir.Status__c = 'Success';
					ir.WorkOrder__c = wo.Id;
					ir.Error_Message__c = null;
				}
			}
		}

		update irList;

//		if (!logs.isEmpty())
//			insert logs;
	}

	global void finish(Database.BatchableContext BC) {
	}

	/*Public static void SchedulerMethod() {
	 // Run a Schedulable class once i.e. after 2 minutes
	String hour = String.valueOf(Datetime.now().hour());
	String min = String.valueOf(Datetime.now().minute() + 2); 
	String ss = String.valueOf(Datetime.now().second());
	//parse to cron expression
	String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
	FS_CreateInstallWorkOrdersBatch cWObatch = new FS_CreateInstallWorkOrdersBatch(); 
	System.schedule('Create Install Work Orders - Job Started At ' + String.valueOf(Datetime.now()), nextFireTime, cWObatch);
	}*/
}