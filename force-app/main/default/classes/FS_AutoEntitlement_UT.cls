@IsTest
private class FS_AutoEntitlement_UT {

    @IsTest static void testScheduledWorkOrders()
    {
        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        FS_TestDataFactory.createDefaultOperatingHours();
        Account acct = FS_TestDataFactory.createTestAccount('Revity', 'TESTX000000001');
        Contact c = FS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        Schema.Location loc = FS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);

        Product2 prod = FS_TestDataFactory.createTestProduct('TestProduct', 'TEST001', 'ZZZ');
        Asset ip = FS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries, prod);
        ip.Building__c = 'The Best Building EVER Created';
        ip.Room__c = '1234567890';
        update ip;

        Date startDate = System.today();
        Date endDate = startDate.addMonths(12);
        ServiceContract sc = FS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.AccountId, startDate, endDate);
        sc.ContactId = c.Id;
        sc.ContractType__c = 'ZOSC'; // IsEnterprise = TRUE
        update sc;
        System.debug('SCHED_WO TEST: Service Contract = ' + sc);

        ServiceContract item = FS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate, prod);
        ContractLineItem cp = FS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        Entitlement ent = FS_TestDataFactory.createEntitlement(sc,'PM', 5, 2);

        FS_EntitlementDate__c edate = FS_TestDataFactory.createEntitlementDate(cp, ent, startDate.addDays(1));
        System.debug('SCHED_WO TEST: Entitlement Date = ' + edate);

        Test.startTest();

        // SVMXCFG-701 Scheduled WO - Change Parameters
        //SMAX_PS_CreateScheduledWorkOrdersBatch b = new SMAX_PS_CreateScheduledWorkOrdersBatch(Date.today().addDays(-30), 2, new Set<String> { 'TST2' });
        FS_CreateScheduledWorkOrdersBatch b = new FS_CreateScheduledWorkOrdersBatch(Date.today().addDays(-30), 2, new Set<String> { 'US10' });
        Database.executeBatch(b);

        Test.stopTest();

        /* WorkOrder result = [SELECT Id, Name, ServiceContractId, SMAX_PS_ContractItem__c, SVMX_PS_Problem_Summary__c,
           SMAX_PS_ContractEntitlement__c, SMAX_PS_CoveredProduct__c, SVMXC__Auto_Entitlement_Status__c, SVMXC__Is_Entitlement_Performed__c,
           SMAX_PS_Offline_Contract_Discounts__c, SMAX_PS_Is_Enterprise__c, SMAX_PS_Customer_Required_Start_Date__c
           FROM WorkOrder WHERE SVMXC__Entitlement_Type__c = 'SCHEDULED'];

        System.debug('AUTO-ENTITLE RESULT WO: ' + result);
         System.assertEquals(TRUE, result.SVMXC__Is_Entitlement_Performed__c);
         System.assertEquals(item.SVMX_PS_Parent_Contract__c, result.SVMXC__Service_Contract__c);
         System.assertEquals(item.Id, result.SMAX_PS_ContractItem__c);
         System.assertEquals(ent.Id, result.SMAX_PS_ContractEntitlement__c);
         System.assertEquals(cp.Id, result.SMAX_PS_CoveredProduct__c);
         System.assertNotEquals(null, result.SVMX_PS_Problem_Summary__c);
         System.assert(result.SVMX_PS_Problem_Summary__c.contains('-PM-'));
         System.assert(result.SVMX_PS_Problem_Summary__c.length() == 40);
         System.assert(result.SVMX_PS_Problem_Summary__c.endsWith('...'));
         System.assertEquals(TRUE, result.SMAX_PS_Is_Enterprise__c);
         System.assertNotEquals(null, result.SMAX_PS_Offline_Contract_Discounts__c);
         System.assertEquals('Success', result.SVMXC__Auto_Entitlement_Status__c);
         System.assertEquals(edate.SMAX_PS_PlannedDate__c, result.SMAX_PS_Customer_Required_Start_Date__c);

         // Make sure EntitlmentDate has the WO Lookup
         FS_EntitlementDate__c edResult = [SELECT Id, Name, SMAX_PS_WorkOrder__c FROM FS_EntitlementDate__c WHERE Id = :edate.Id];
         System.assertNotEquals(null, edResult.SMAX_PS_WorkOrder__c);*/
    }

    @IsTest static void testScheduledWorkOrderTypeErrors()
    {
        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        FS_TestDataFactory.createDefaultOperatingHours();
        Account acct = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = FS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        Schema.Location loc = FS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);

        Product2 prod = FS_TestDataFactory.createTestProduct('TestProduct', 'TEST001', 'ZZZ');
        Asset ip = FS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries, prod);
        ip.Building__c = 'The Best Building EVER Created';
        ip.Room__c = '1234567890';
        update ip;

        Date startDate = System.today();
        Date endDate = startDate.addMonths(12);
        ServiceContract sc = FS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.AccountId, startDate, endDate);
        sc.ContactId = c.Id;
        sc.ContractType__c = 'ZOSC'; // IsEnterprise = TRUE
        update sc;
        System.debug('SCHED_WO TEST: Service Contract = ' + sc);

        ServiceContract item = FS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate, prod);
        ContractLineItem cp = FS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        // SVMXCFG-999 Blank Entitlement Type should error out
        Entitlement ent = FS_TestDataFactory.createEntitlement(sc, null, 5, 2);

        FS_EntitlementDate__c edate = FS_TestDataFactory.createEntitlementDate(cp, ent, startDate.addDays(1));
        System.debug('SCHED_WO TEST: Entitlement Date = ' + edate);

        Test.startTest();

        FS_CreateScheduledWorkOrdersBatch b = new FS_CreateScheduledWorkOrdersBatch(Date.today().addDays(-30), 2, new Set<String> { 'US10' });
        Database.executeBatch(b);

        Test.stopTest();

        /*List<WorkOrder> results = [SELECT Id, Name, SVMXC__Service_Contract__c, SMAX_PS_ContractItem__c, SVMX_PS_Problem_Summary__c,
          SMAX_PS_ContractEntitlement__c, SMAX_PS_CoveredProduct__c, SVMXC__Auto_Entitlement_Status__c, SVMXC__Is_Entitlement_Performed__c,
          SMAX_PS_Offline_Contract_Discounts__c, SMAX_PS_Is_Enterprise__c, SMAX_PS_Customer_Required_Start_Date__c
          FROM WorkOrder WHERE SVMXC__Entitlement_Type__c = 'SCHEDULED'];

        System.debug('AUTO-ENTITLE RESULT WO: ' + results);
        System.assertEquals(0, results.size());

        // Make sure EntitlmentDate has the WO Lookup
        FS_EntitlementDate__c edResult = [SELECT Id, Name, SMAX_PS_WorkOrder__c FROM FS_EntitlementDate__c WHERE Id = :edate.Id];
        System.assertEquals(null, edResult.SMAX_PS_WorkOrder__c);

        List<SMAX_PS_ErrorLog__c> errors = [SELECT Id, Name, SMAX_PS_Link__c FROM SMAX_PS_ErrorLog__c];
        System.assertEquals(1, errors.size());*/
    }

    @IsTest static void testScheduledWorkOrderErrors()
    {
        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        FS_TestDataFactory.createDefaultOperatingHours();
        Account acct = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = FS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        Schema.Location loc = FS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);

        Product2 prod = FS_TestDataFactory.createTestProduct('TestProduct', 'TEST001', 'ZZZ');
        Asset ip = FS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries, prod);
        ip.Building__c = 'The Best Building EVER Created';
        ip.Room__c = '1234567890';
        // SVMXCFG-699 Scheduled WO - Do not create without related data
        ip.LocationId = null;
        update ip;

        Date startDate = System.today();
        Date endDate = startDate.addMonths(12);
        ServiceContract sc = FS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.AccountId, startDate, endDate);
        sc.ContactId = c.Id;
        sc.ContractType__c = 'ZOSC'; // IsEnterprise = TRUE
        update sc;
        System.debug('SCHED_WO TEST: Service Contract = ' + sc);

        ServiceContract item = FS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate, prod);
        ContractLineItem cp = FS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        Entitlement ent = FS_TestDataFactory.createEntitlement(sc,'PM', 5, 2);

        FS_EntitlementDate__c edate = FS_TestDataFactory.createEntitlementDate(cp, ent, startDate.addDays(1));
        System.debug('SCHED_WO TEST: Entitlement Date = ' + edate);

        Test.startTest();

        FS_CreateScheduledWorkOrdersBatch b = new FS_CreateScheduledWorkOrdersBatch(Date.today().addDays(-30), 2, new Set<String> { 'US10' });
        Database.executeBatch(b);

        Test.stopTest();

        /*List<WorkOrder> results = [SELECT Id, Name, SVMXC__Service_Contract__c, SMAX_PS_ContractItem__c, SVMX_PS_Problem_Summary__c,
            SMAX_PS_ContractEntitlement__c, SMAX_PS_CoveredProduct__c, SVMXC__Auto_Entitlement_Status__c, SVMXC__Is_Entitlement_Performed__c,
            SMAX_PS_Offline_Contract_Discounts__c, SMAX_PS_Is_Enterprise__c, SMAX_PS_Customer_Required_Start_Date__c
        FROM WorkOrder WHERE SVMXC__Entitlement_Type__c = 'SCHEDULED'];

        System.debug('AUTO-ENTITLE RESULT WO: ' + results);
        System.assertEquals(0, results.size());

        // Make sure EntitlmentDate has the WO Lookup
        FS_EntitlementDate__c edResult = [SELECT Id, Name, SMAX_PS_WorkOrder__c FROM FS_EntitlementDate__c WHERE Id = :edate.Id];
        System.assertEquals(null, edResult.SMAX_PS_WorkOrder__c);

        List<SMAX_PS_ErrorLog__c> errors = [SELECT Id, Name, SMAX_PS_Link__c FROM SMAX_PS_ErrorLog__c];
        System.assertEquals(1, errors.size());*/
    }

    //ITSVMX-435 5/21/21 Update PM Scheduled Batch Job to Create Depot Work Order
    @IsTest static void testScheduledWorkOrdersDepot()
    {
        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        FS_TestDataFactory.createDefaultOperatingHours();
        Account acct = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = FS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        Schema.Location loc = FS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        //loc.SMAX_PS_SalesOrg__c = 'TST2';
        //update loc;

        Product2 prod = FS_TestDataFactory.createTestProduct('TestProduct', 'TEST001', 'ZZZ');
        Asset ip = FS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries, prod);
        ip.Building__c = 'The Best Building EVER Created';
        ip.Room__c = '1234567890';
        update ip;

        Date startDate = System.today();
        Date endDate = startDate.addMonths(12);
        ServiceContract sc = FS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.AccountId, startDate, endDate);
        sc.ContactId = c.Id;
        //sc.SMAX_PS_SalesOrg__c = 'TST2';
        sc.ContractType__c = 'ZOSC'; // IsEnterprise = TRUE
        update sc;
        System.debug('SCHED_WO TEST: Service Contract = ' + sc);

        ServiceContract item = FS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate, prod);
        item.SLA_Terms_Notes__c = 'Testing terms like ZDPM- go in this field';
        update item;

        ContractLineItem cp = FS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        Entitlement ent = FS_TestDataFactory.createEntitlement(sc,'PM', 5, 2);

        FS_EntitlementDate__c edate = FS_TestDataFactory.createEntitlementDate(cp, ent, startDate.addDays(1));
        edate.EntitlementCondition__c = 'ZDPM';
        update edate;
        System.debug('SCHED_WO TEST: Entitlement Date = ' + edate);

        //ITSVMX-435 5/21/21 Update PM Scheduled Batch Job to Create Depot Work Order
        /*RecordType depotRepairRT = SMAX_PS_Utility.getRecTypeDevNameMap('WorkOrder').get('Depot_Repair');
        Group unassignedDepotQueue = [
            SELECT Id, DeveloperName, Type
            FROM Group
            WHERE Type = 'Queue'
            AND DeveloperName = 'SMAX_PS_Unassigned_Depot_PMs' LIMIT 1
        ];
        Id unassignedDepotQueueId = unassignedDepotQueue.Id;
        System.debug('unassignedDepotQueueId: ' + unassignedDepotQueueId);*/

        Test.startTest();

        // SVMXCFG-701 Scheduled WO - Change Parameters
        //SMAX_PS_CreateScheduledWorkOrdersBatch b = new SMAX_PS_CreateScheduledWorkOrdersBatch(Date.today().addDays(-30), 2, new Set<String> { 'TST2' });
        FS_CreateScheduledWorkOrdersBatch b = new FS_CreateScheduledWorkOrdersBatch(Date.today().addDays(-30), 2, new Set<String> { 'US10' });
        Database.executeBatch(b);

        Test.stopTest();

        /* WorkOrder result = [SELECT Id, Name, SVMXC__Service_Contract__c, SMAX_PS_ContractItem__c, SVMX_PS_Problem_Summary__c,
             SMAX_PS_ContractEntitlement__c, SMAX_PS_CoveredProduct__c, SVMXC__Auto_Entitlement_Status__c, SVMXC__Is_Entitlement_Performed__c,
             SMAX_PS_Offline_Contract_Discounts__c, SMAX_PS_Is_Enterprise__c, SMAX_PS_Customer_Required_Start_Date__c,
             OwnerId, RecordTypeId
         FROM WorkOrder WHERE SVMXC__Entitlement_Type__c = 'SCHEDULED'];

         System.debug('AUTO-ENTITLE RESULT WO: ' + result);
         System.assertEquals(TRUE, result.SVMXC__Is_Entitlement_Performed__c);
         System.assertEquals(item.SVMX_PS_Parent_Contract__c, result.SVMXC__Service_Contract__c);
         System.assertEquals(item.Id, result.SMAX_PS_ContractItem__c);
         System.assertEquals(ent.Id, result.SMAX_PS_ContractEntitlement__c);
         System.assertEquals(cp.Id, result.SMAX_PS_CoveredProduct__c);
         System.assertNotEquals(null, result.SVMX_PS_Problem_Summary__c);
         System.assert(result.SVMX_PS_Problem_Summary__c.contains('-PM-'));
         System.assert(result.SVMX_PS_Problem_Summary__c.length() == 40);
         System.assert(result.SVMX_PS_Problem_Summary__c.endsWith('...'));
         System.assertEquals(TRUE, result.SMAX_PS_Is_Enterprise__c);
         System.assertNotEquals(null, result.SMAX_PS_Offline_Contract_Discounts__c);
         System.assertEquals('Success', result.SVMXC__Auto_Entitlement_Status__c);
         System.assertEquals(edate.SMAX_PS_PlannedDate__c, result.SMAX_PS_Customer_Required_Start_Date__c);
         System.assertEquals(unassignedDepotQueueId, result.OwnerId);
         System.assertEquals(depotRepairRT.Id, result.RecordTypeId);

         // Make sure EntitlmentDate has the WO Lookup
         FS_EntitlementDate__c edResult = [SELECT Id, Name, SMAX_PS_WorkOrder__c FROM FS_EntitlementDate__c WHERE Id = :edate.Id];
         System.assertNotEquals(null, edResult.SMAX_PS_WorkOrder__c);*/
    }

    @IsTest
    static void testExtendedCoverage()
    {
        FS_TestDataFactory.createDefaultOperatingHours();

        // Insert Product
        Product2 eqProd = new Product2(Name='Test Equipment Product', Description='Test Equipment Product Description',
                Partnum__c='TESTT00100101', Product_Type__c='Service Parts', Activity_Type__c='ACT001');
        Product2 part1 = new Product2(Name='Test Part', Description='Test Part Description',
                Partnum__c='TESTP00100101', Product_Type__c='Consumable');
        Product2 part2 = new Product2(Name='Test Part 2', Description='Test Part 2 Description',
                Partnum__c='TESTP00200202', Product_Type__c='Consumable');
        insert new List<Product2> { eqProd, part1, part2 };

        FS_ExtendedWarrantyPart__c ewp1a = new FS_ExtendedWarrantyPart__c(Equipment_Product__c = eqProd.Id,
                Last_Txn_Number__c = 'ABC', Sales_Org__c = 'TS11', External_Key__c = eqProd.Partnum__c+'-TS11-'+part1.Partnum__c,
                Covered_Part__c = part1.Id, Extended_Months__c = 9);
        FS_ExtendedWarrantyPart__c ewp1b = new FS_ExtendedWarrantyPart__c(Equipment_Product__c = eqProd.Id,
                Last_Txn_Number__c = 'ABC', Sales_Org__c = 'XX11', External_Key__c = eqProd.Partnum__c+'-XX11-'+part1.Partnum__c,
                Covered_Part__c = part1.Id, Extended_Months__c = 18);
        FS_ExtendedWarrantyPart__c ewp2 = new FS_ExtendedWarrantyPart__c(Equipment_Product__c = eqProd.Id,
                Last_Txn_Number__c = 'ABC', Sales_Org__c = null, External_Key__c = eqProd.Partnum__c+'-*-'+part2.Partnum__c,
                Covered_Part__c = part2.Id, Extended_Months__c = 15);
        insert new List<FS_ExtendedWarrantyPart__c> { ewp1a, ewp1b, ewp2 };

        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        Account acct = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = FS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        Schema.Location loc = FS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        loc.SalesOrg__c = 'XX11';
        update loc;
        Asset ip = FS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries, eqProd);

        Date startDate = System.today().addYears(-2);
        Date endDate = startDate.addMonths(12);
        ServiceContract sc = FS_TestDataFactory.createSvcMaintContract('ExpiredWarranty', ip.AccountId, startDate, endDate);
        sc.ContractType__c = 'ZW01';
        sc.SalesOrg__c = 'XX11';
        update sc;
        ServiceContract item = FS_TestDataFactory.createContractItem(sc, 'ExpiredWarrantyItem', startDate, endDate, eqProd);
        ContractLineItem cp = FS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        Entitlement ent1 = FS_TestDataFactory.createEntitlement(item,'REP', 5, 0);
        Entitlement ent2 = FS_TestDataFactory.createEntitlement(item,'ZZZ', 0, 0);

        Test.startTest();

        WorkOrder wo = FS_TestDataFactory.createWO(ip, c);

        List<FS_ExtendedWarrantyCoverage__c> results = [SELECT Id, Name, Covered_Part__c, Covered_Until__c,
                Warranty_Contract__c, Warranty_Contract_Item__c, Warranty_Work_Order__c
        FROM FS_ExtendedWarrantyCoverage__c WHERE Parent_Work_Order__c = :wo.Id];
        System.assertEquals(2, results.size());
        
        FS_EntitlementDate__c dt1= new FS_EntitlementDate__c();
        dt1.Entitlement__c =ent1.id;
        dt1.CoveredProduct__c=cp.id;
        dt1.ContractItem__c= item.id;
        insert dt1;

        // Test coverage on Asset also...
        FS_ExtendedWarranty.getCoverages(new List<Id> { ip.Id }, null);

        Test.stopTest();

        // NEW: Update Coverage record.. let WO auto-create!
//      results[0].Create_Warranty_Work_Order__c = true;
//      update results[0];
//
//      WorkOrder result = [SELECT Id, WorkOrderNumber, ServiceContractId, ContractItem__c,
//              ContractEntitlement__c, CoveredProduct__c, Auto_Entitlement_Status__c,
//              Is_Entitlement_Performed__c, Entitlement_Type__c, Entitlement_Notes__c,
//              Description, AssetId
//          FROM WorkOrder WHERE ParentWorkOrderId = :wo.Id];
//
//      System.debug('COMPLETE-ENTITLE RESULT WO: ' + result);
//      System.assertEquals(true, result.Is_Entitlement_Performed__c);
//      System.assertEquals(item.ParentServiceContractId, result.ServiceContractId);
//      System.assertEquals(item.Id, result.ContractItem__c);
//      System.assertEquals(ent2.Id, result.ContractEntitlement__c);
//      System.assertEquals(cp.Id, result.CoveredProduct__c);
//      System.assertEquals('Success', result.Auto_Entitlement_Status__c);
//      System.assertEquals('SAP', result.Entitlement_Type__c);
//
//      // Test getCoverages method
//     List<FS_ExtendedWarranty.ExtendedWarrantyCoverage> coverages = FS_ExtendedWarranty.getCoveragesForIp(result.AssetId);
//      System.assertEquals(true, coverages.size() > 0);

    }

    @IsTest
    static void testEntitleByDate()
    {
        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        FS_TestDataFactory.createDefaultOperatingHours();
        Account acct = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = FS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        Schema.Location loc = FS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        Product2 prod = FS_TestDataFactory.createTestProduct('TestProduct', 'TEST001', 'ZZZ');
        Asset ip = FS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries, prod);

        Date startDate = System.today().addMonths(-1);
        Date endDate = startDate.addMonths(11);
        ServiceContract sc = FS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.AccountId, startDate, endDate);
        ServiceContract item = FS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate, prod);
        ContractLineItem cp = FS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        Entitlement ent = FS_TestDataFactory.createEntitlement(item,'REP', 5, 2);

        FS_EntitlementDate__c edate1 = FS_TestDataFactory.createEntitlementDate(cp, ent, startDate.addDays(1));
        edate1.ServiceOrderNumber__c = 'XYZABC'; // This should no be skipped
        FS_EntitlementDate__c edate2 = FS_TestDataFactory.createEntitlementDate(cp, ent, startDate.addDays(10));
        edate2.SAP_Notification_ID__c = 'ABCXYZ'; // This should also be skipped
        FS_EntitlementDate__c edate3 = FS_TestDataFactory.createEntitlementDate(cp, ent, startDate.addDays(20));
        update new List<FS_EntitlementDate__c> { edate1, edate2 };

        Test.startTest();

        WorkOrder wo = FS_TestDataFactory.createContractWO(ip, c);

        WorkOrder result = [SELECT Id, WorkOrderNumber, ServiceContractId, ContractItem__c, Entitlement_Notes__c,
                ContractEntitlement__c, CoveredProduct__c, Auto_Entitlement_Status__c, Is_Entitlement_Performed__c
            FROM WorkOrder WHERE Id = :wo.Id];

        System.debug('AUTO-ENTITLE RESULT WO: ' + result);
        System.assertEquals(true, result.Is_Entitlement_Performed__c);
        System.assertEquals(item.ParentServiceContractId, result.ServiceContractId);
        System.assertEquals(item.Id, result.ContractItem__c);
        System.assertEquals(ent.Id, result.ContractEntitlement__c);
        System.assertEquals(cp.Id, result.CoveredProduct__c);
        System.assertEquals('Success', result.Auto_Entitlement_Status__c);
        System.assertEquals(true, result.Entitlement_Notes__c.contains('Non-Consumed EntitlementDate Matched'));
        System.assertEquals(3, result.Entitlement_Notes__c.countMatches('Checking EntitlementDate'));

        Test.stopTest();

        // Make sure EntitlmentDate has the WO Lookup
        //FS_EntitlementDate__c edResult = [SELECT Id, Name, WorkOrder__c FROM FS_EntitlementDate__c WHERE Id = :edate.Id];
        // KNOWN-ISSUE .. see Auto-Entitlement line 230
        //System.assertNotEquals(null, edResult.WorkOrder__c);
    }

    @IsTest
    static void testCompleteEntitlement()
    {
        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        FS_TestDataFactory.createDefaultOperatingHours();
        Account acct = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = FS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        Schema.Location loc = FS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        Product2 prod = FS_TestDataFactory.createTestProduct('TestProduct', 'TEST001', 'ZZZ');
        Asset ip = FS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries, prod);

        Date startDate = System.today();
        Date endDate = startDate.addMonths(12);
        ServiceContract sc = FS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.AccountId, startDate, endDate);
        ServiceContract item = FS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate, prod);
        ContractLineItem cp = FS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        Entitlement ent = FS_TestDataFactory.createEntitlement(item,'REP', 5, 2);
        //FS_EntitlementDate__c edate = FS_TestDataFactory.createEntitlementDate(cp, ent, startDate.addDays(1));

        Test.startTest();

        WorkOrder wo = new WorkOrder();
        wo.Record_Type__c = 'Field Service';
        wo.AssetId = ip.Id;
        wo.Billing_Type__c = 'Contract';
        wo.Order_Type__c = 'Repair';
        wo.AccountId = ip.AccountId;
        wo.LocationId = ip.LocationId;
        wo.Customer_Required_Start_Date__c = startDate.addMonths(1);
        wo.ContactId = c.Id;
        wo.ServiceContractId = sc.Id;
        wo.ContractItem__c = item.Id;
        insert wo;

        WorkOrder result = [SELECT Id, WorkOrderNumber, ServiceContractId, ContractItem__c,
                ContractEntitlement__c, CoveredProduct__c, Auto_Entitlement_Status__c,
                Is_Entitlement_Performed__c, Entitlement_Type__c, Entitlement_Notes__c
            FROM WorkOrder WHERE Id = :wo.Id];

        System.debug('COMPLETE-ENTITLE RESULT WO: ' + result);
        System.assertEquals(true, result.Is_Entitlement_Performed__c);
        System.assertEquals(item.ParentServiceContractId, result.ServiceContractId);
        System.assertEquals(item.Id, result.ContractItem__c);
        System.assertEquals(ent.Id, result.ContractEntitlement__c);
        System.assertEquals(cp.Id, result.CoveredProduct__c);
        System.assertEquals('Success', result.Auto_Entitlement_Status__c);
        System.assertEquals('SAP', result.Entitlement_Type__c);
        System.assertEquals(true, result.Entitlement_Notes__c.contains('Matching to Entitlement by Qty'));

        //Database.executeBatch(new AutoEntitlementWoLoadFix(result.Name));

        Test.stopTest();

    }
}