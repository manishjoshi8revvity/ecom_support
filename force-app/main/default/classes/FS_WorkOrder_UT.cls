@IsTest
public class FS_WorkOrder_UT {

    @TestSetup
    static void setupTest() {
        FS_TestDataFactory.createDefaultOperatingHours();
    }

    @IsTest
    static void createWorkOrderTestData()
    {
        Account acct = FS_TestDataFactory.createTestErpAccount('PkiTest', 999,'TESTX000000001','GB');
        Contact cont = FS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = FS_TestDataFactory.createTestProduct('TestProduct', '106018','ZZZ');
        pd.Super_Business_Unit__c = 'DAS';
        update pd;

        Schema.Location loc = FS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
        loc.MaintenancePlant__c = 'TT12';
        // SVMXCFG-903 Copy Local Language Accounts to WO
//      loc.LL_BillToExtID__c = acctMap.get('LocalLangBillTo').PKI_SAP_Customer_Number__c;
//      loc.LL_ShipToExtID__c = acctMap.get('LocalLangShipTo').PKI_SAP_Customer_Number__c;
        update loc;

        Product2 laborProd = FS_TestDataFactory.createTestProduct('TestLabor', 'LAB100101', 'ZZZ', 'Labor');
        Product2 travelProd = FS_TestDataFactory.createTestProduct('TestTravel', 'TRV10011', 'ZZZ', 'Travel');

        Asset ip = FS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);

        WorkType wrkType = new WorkType(
                Product_Line__c = FS_WorkOrderStandardJobTime.WILDCARD,
                Model_Series__c = FS_WorkOrderStandardJobTime.WILDCARD,
                Order_Type__c = 'Repair',
                EstimatedDuration = 3.00,
                DurationType = 'Hours',
                Status__c = 'Active',
                Name = 'RepairTest'
        );
        insert wrkType;
        WorkType wtResult = [SELECT Id, External_ID__c FROM WorkType WHERE Id = :wrkType.Id];
        System.debug('WorkType ExternalKey=' + wtResult.External_ID__c);

        // Insert Work Order
        WorkOrder wo = FS_TestDataFactory.createWO(ip, cont);

        WorkOrder result = [SELECT Id, WorkOrderNumber, WorkTypeId, Super_Business_Unit__c FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals(pd.Super_Business_Unit__c, result.Super_Business_Unit__c);
        System.assertEquals(wrkType.Id, result.WorkTypeId);

        wo.External_ID__c = 'SO001991992';
        wo.SAP_SystemStatus__c = 'CRTD';
        update wo;

        wo.SAP_SystemStatus__c = 'REL';
        wo.CreditHold__c = true;
        update wo;

        wo.SAP_SystemStatus__c = 'REL';
        wo.CreditHold__c = false;
        update wo;

        Test.startTest();

        WorkOrderLineItem laborLine = new WorkOrderLineItem(
                WorkOrderId=wo.Id, Record_Type__c='Usage', Line_Type__c = 'Labor', Status='Confirmed',
                Part__c = laborProd.Id, Quantity__c = 1.5);
        WorkOrderLineItem travelLine = new WorkOrderLineItem(
                WorkOrderId=wo.Id, Record_Type__c='Usage', Line_Type__c = 'Travel', Status='Confirmed',
                Part__c = travelProd.Id, Quantity__c = 2);
        List<WorkOrderLineItem> lines = new List<WorkOrderLineItem> { laborLine, travelLine };
        insert lines;

        wo.Customer_Required_Start_Date__c = Date.today().addDays(2);
        wo.SubmitAllLines__c = true;
        update wo;

        wo.Status='Work Complete';
        update wo;

        // Should fail.. No Fault Lines..
        result = [SELECT Id, WorkOrderNumber, Status FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals('Work Complete - Error', result.Status);
        for (WorkOrderLineItem line : lines) {
            line.Status = 'Canceled';
        }
        update lines;

        wo = new WorkOrder();
        wo.Id = result.Id;
        wo.Status='Work Complete';
        update wo;

        result = [SELECT Id, WorkOrderNumber, Status, Completion_Errors__c FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals(null, result.Completion_Errors__c);
        System.assertEquals('Work Complete', result.Status);

        wo.SAP_SystemStatus__c='TECO';
        update wo;

        wo.DMR_Number__c = 'TST11001001';
        update wo;

        wo.SAP_SystemStatus__c = 'CLSD';
        update wo;

        Test.stopTest();
    }
    
    @IsTest
    static void workOrderDuplicateTest()
    {
        Account acct = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
        Contact cont = FS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = FS_TestDataFactory.createTestProduct('TestProduct', '106018','ZZZ');
        pd.Super_Business_Unit__c = 'DAS';
        update pd;

        Schema.Location loc = FS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
        loc.MaintenancePlant__c = 'TT12';
        update loc;

        //Schema.Location expLoc = FS_TestDataFactory.createTestLocation(acct,'Test Expense Loc', 'TT12F000', 'LOC123');

        Product2 laborProd = FS_TestDataFactory.createTestProduct('TestLabor', 'LAB100101', 'ZZZ', 'Labor');

        Asset ip = FS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);

        // Insert Work Order
        WorkOrder wo = FS_TestDataFactory.createWO(ip, cont);

        WorkOrder result = [SELECT Id, WorkOrderNumber, Super_Business_Unit__c FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals(pd.Super_Business_Unit__c, result.Super_Business_Unit__c);

        WorkOrderLineItem laborLine = new WorkOrderLineItem(
                WorkOrderId=wo.Id, Record_Type__c='Usage', Line_Type__c = 'Labor', Status='Submitted',
                Part__c = laborProd.Id, Quantity__c = 1.5);
        List<WorkOrderLineItem> lines = new List<WorkOrderLineItem> { laborLine };
        insert lines;

        Test.startTest();

        wo.External_ID__c = 'SO001991992';
        wo.SAP_Notification_ID__c = 'NO0019291293';
        wo.SAP_SystemStatus__c = 'CRTD';
        update wo;

        List<FS_IntegrationError__c> errors = [SELECT Id, Name FROM FS_IntegrationError__c WHERE WorkOrder__c = :wo.Id];
        System.assertEquals(0, errors.size());

        wo.External_ID__c = 'SO001991111';
        wo.SAP_Notification_ID__c = 'NO0019291111';
        update wo;

        errors = [SELECT Id, Name FROM FS_IntegrationError__c WHERE WorkOrder__c = :wo.Id];
        System.assertEquals(2, errors.size());

        laborLine.SAP_Confirmation__c = 'WD112233';
        update laborLine;

        List<FS_IntegrationError__c> lineErrors = [SELECT Id, Name FROM FS_IntegrationError__c WHERE WorkOrderLineItem__c = :laborLine.Id];
        System.assertEquals(0, lineErrors.size());

        laborLine.SAP_Confirmation__c = 'WD112244';
        update laborLine;

        lineErrors = [SELECT Id, Name FROM FS_IntegrationError__c WHERE WorkOrderLineItem__c = :laborLine.Id];
        System.assertEquals(1, lineErrors.size());

        laborLine.CancellationNumber__c = '332211DW';
        update laborLine;

        laborLine.CancellationNumber__c = '442211DW';
        update laborLine;

        lineErrors = [SELECT Id, Name FROM FS_IntegrationError__c WHERE WorkOrderLineItem__c = :laborLine.Id];
        System.assertEquals(2, lineErrors.size());

        Test.stopTest();
    }

    @IsTest
    static void createInvalidWorkOrder()
    {
        Account acct = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
        Contact cont = FS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');

        WorkOrder fsWO = new WorkOrder(Record_Type__c = 'Field Service',
                AccountId = acct.Id, ContactId = cont.Id,
                SAP_SystemStatus__c='TECO', External_ID__c = 'SAP100299345', SAP_Notification_ID__c = 'NOT1002993');
        Database.SaveResult result1 = Database.insert(fsWO, false);
        System.debug('WO1 ERRORS: ' + result1.getErrors());
        System.assertEquals(false, result1.isSuccess());

        WorkOrder rmWO = new WorkOrder(Record_Type__c = 'Depot',
                AccountId = acct.Id, ContactId = cont.Id,
                SAP_SystemStatus__c='TECO', External_ID__c = 'SAP100299345R', SAP_Notification_ID__c = 'NOT1002993R');
        Database.SaveResult result2 = Database.insert(rmWO, false);
        System.debug('WO2 ERRORS: ' + result2.getErrors());
        System.assertEquals(true, result2.isSuccess());
    }

    @IsTest
    static void testForceIntegration()
    {
        Account acct = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
        Contact cont = FS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = FS_TestDataFactory.createTestProduct('TestProduct', '106018','ZZZ');
        Schema.Location loc = FS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
        Asset ip = FS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);
        WorkOrder wo = FS_TestDataFactory.createWO(ip, cont);

        wo.ForceIntegration__c = true;
        update wo;

        wo.External_ID__c = 'SO001991992';
        wo.ForceIntegration__c = true;
        update wo;

        wo.SAP_SystemStatus__c = 'TECO';
        wo.ForceIntegration__c = true;
        update wo;
    }

    @IsTest
    static void testSubmitWithoutPrice()
    {
        // SVMXCFG-335 WO Submit Lines: Skip Priced on 100% Discount Lines
        String modelSeries = 'TST001';
        String locCode = 'TSTC01';

        Account acct = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact c = FS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        Schema.Location loc = FS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', locCode);
        Product2 prod = FS_TestDataFactory.createTestProduct('TestInstrument', 'INS10010', 'ZZZ', null);
        Asset ip = FS_TestDataFactory.createIP('TESTX0000234001', acct, loc, modelSeries, prod);

        Product2 laborProd = FS_TestDataFactory.createTestProduct('TestLabor', 'LAB10010', 'ZZZ', 'Labor');
        Product2 travelProd = FS_TestDataFactory.createTestProduct('TestTravel', 'TRV10010', 'ZZZ', 'Travel');
        Product2 svcPartsProd = FS_TestDataFactory.createTestProduct('TestSvcPart', 'SVP10010', 'ZZZ', 'Service Parts');

        Date startDate = System.today().addDays(-30);
        Date endDate = startDate.addMonths(11);
        ServiceContract sc = FS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.AccountId, startDate, endDate);
        ServiceContract item = FS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate, svcPartsProd);
        ContractLineItem cp = FS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        Entitlement ent = FS_TestDataFactory.createEntitlement(item,'REP', 0, 0);
        ent.ServicePartsDiscountCovered__c = 100;
        update ent;

        FS_FaultCode__c fc = FS_TestDataFactory.createTestFaultCode('TFAM', 'TFAM-TTT', 'TTT2', 'Testing', true);

        Test.startTest();

        WorkOrder wo = FS_TestDataFactory.createContractWO(ip, c);

        String usage = 'Usage';
        WorkOrderLineItem laborLine = new WorkOrderLineItem(
                WorkOrderId=wo.Id, Record_Type__c=usage, Line_Type__c = 'Labor', Status='Open',
                Part__c = laborProd.Id, Quantity__c = 1.5);
        WorkOrderLineItem travelLine = new WorkOrderLineItem(
                WorkOrderId=wo.Id, Record_Type__c=usage, Line_Type__c = 'Travel', Status='Open',
                Part__c = travelProd.Id, Quantity__c = 2);
        WorkOrderLineItem svcPartsLine = new WorkOrderLineItem(
                WorkOrderId=wo.Id, Record_Type__c=usage, Line_Type__c = 'Parts', Status='Open',
                Part__c = svcPartsProd.Id, Quantity__c = 1);
        WorkOrderLineItem fcl = new WorkOrderLineItem(
                WorkOrderId=wo.Id, Record_Type__c=usage, Line_Type__c = 'Fault Code', Status='Open',
                Fault_Code__c = fc.Id); //, ActionFaultCode__c = fc.Id, InstallationFaultCode__c = fc.Id, CompletionFaultCode__c = fc.Id);
        List<WorkOrderLineItem> lines = new List<WorkOrderLineItem> { laborLine, travelLine, svcPartsLine, fcl };
        insert lines;

        wo.SubmitAllLines__c = true;
        update wo;

        Test.stopTest();

        WorkOrder result = [SELECT Id, WorkOrderNumber, Status, Completion_Errors__c, ServiceContractId, ContractItem__c,
                ContractEntitlement__c, CoveredProduct__c, Auto_Entitlement_Status__c, Is_Entitlement_Performed__c
            FROM WorkOrder WHERE Id = :wo.Id];
        System.debug('WO Status: ' + result.Status + ' [' + result.Completion_Errors__c + ']');

        List<WorkOrderLineItem> results = [SELECT Id, LineItemNumber, Status, Line_Type__c, ContractPercentDiscount__c
            FROM WorkOrderLineItem WHERE Id IN :lines];
        for (WorkOrderLineItem line : results)
        {
            System.assertEquals('Submitted', line.Status, line.Line_Type__c + 'Line not Submitted');
            if (line.Line_Type__c != 'Fault Code') {
                System.assertEquals(100, line.ContractPercentDiscount__c);
            }
        }
    }

    @IsTest
    static void testComplaints()
    {
        Account acct = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
        Contact cont = FS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = FS_TestDataFactory.createTestProduct('TestProduct', '106018','ZZZ');
        Schema.Location loc = FS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');

        //Schema.Location expLoc = FS_TestDataFactory.createTestLocation(acct,'Test Expense Loc', 'TT12F000', 'LOC123');

        Asset ip = FS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);
        ip.CatalogProfile__c = 'TCP';
        update ip;
        C_SET_6910_HSI__c hsi = FS_TestDataFactory.createHSICustomSetting('GB','ZZZ');  // Should force HSI rules

        // Fault Code data
        C_SET_6850_CATALOG_PROFILE__c catProf = new C_SET_6850_CATALOG_PROFILE__c(Name = 'TCP',
                Catalog_Profile__c = 'TCP', Code_Family__c = 'TFAM');
        insert catProf;

        FS_FaultCode__c fc = FS_TestDataFactory.createTestFaultCode('TFAM',
            'TFAM-TTT', 'TTT2', 'Testing', true);

        Test.startTest();

        // Insert Work Order
        WorkOrder wo = FS_TestDataFactory.createWO(ip, cont);

        WorkOrder hsiWO = [SELECT Id, WorkOrderNumber, Status, HSI_Required__c, ShipTo__c, AssetId FROM WorkOrder WHERE Id = :wo.Id];
        System.debug('WO COMPLAINTS: HSI WO = ' + hsiWO);
        System.assertEquals('HSI', hsiWO.Status);
        System.assertEquals(true, hsiWO.HSI_Required__c);

        wo.HSI1_Answer__c = 'No';
        wo.HSI2_Answer__c = 'Unknown';
        wo.HSI3_Answer__c = 'Yes';
        wo.Status = 'Initializing';
        update wo;

        wo.External_ID__c = 'SO001991993';
        wo.SAP_SystemStatus__c = 'REL';
        update wo;

        // Add Fault Code line
        WorkOrderLineItem fcl = new WorkOrderLineItem(WorkOrderId=wo.Id, Record_Type__c='Usage',
                Line_Type__c = 'Fault Code', Status='Confirmed', Fault_Code__c = fc.Id);
        //, ActionFaultCode__c = fc.Id, InstallationFaultCode__c = fc.Id, CompletionFaultCode__c = fc.Id);
        insert fcl;

        wo.Priority = 'X'; // Manual Complaint
        update wo;

        WorkOrder complaintWO = [SELECT Id, WorkOrderNumber, Complaint_Required_Details_Check__c, Complaint_Required_Details__c FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals(true, complaintWO.Complaint_Required_Details_Check__c);
        System.assertEquals(true, complaintWO.Complaint_Required_Details__c.contains('HSI'));
        System.assertEquals(true, complaintWO.Complaint_Required_Details__c.contains('Manual Complaint'));
        System.assertEquals(true, complaintWO.Complaint_Required_Details__c.contains('Fault Codes'));

        // Try to Complete.. catch the Error
        wo.Status = 'Work Complete';
        Database.SaveResult sr = Database.update(wo, false);

        // SVMXCFG-327 - Use a Order Status / Message field instead of Apex Errors
        //System.debug('WO COMPLAINTS: Complete Error = ' + sr.getErrors());
        //System.assertEquals(false, sr.isSuccess());
        //System.assertEquals(true, (sr.getErrors() + '').contains('ACTIONS NEEDED'));
        WorkOrder completeWO = [SELECT Id, WorkOrderNumber, Completion_Errors__c, Status FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals('Work Complete - Error', completeWO.Status);
        System.assertEquals(true, completeWO.Completion_Errors__c.contains('ACTIONS NEEDED'));

        // Fill in complaint data, Complete again.. should work now
        wo = new WorkOrder();
        wo.Id = completeWO.Id;
        wo.Q1_Answer__c = 'A1';
        wo.Q2_Answer__c = 'A2';
        wo.Q3_Answer__c = 'A3';
        wo.Q4_Answer__c = 'A4';
        wo.Q5_Answer__c = 'A5';
        update wo;

        wo.HSI2_Answer__c = 'No';
        wo.Q1_Response__c = 'No';
        wo.Q2_Response__c = 'Yes';
        wo.Q3_Response__c = 'No';
        wo.Q4_Response__c = 'Yes';
        wo.Q5_Response__c = 'No';
        wo.Status = 'Work Complete';
        update wo;

        completeWO = [SELECT Id, WorkOrderNumber, Completion_Errors__c, Status FROM WorkOrder WHERE Id = :wo.Id];
        System.debug('COMPLAINTS: Complete WO: ' + completeWO);
        System.assertEquals('Work Complete', completeWO.Status);
        System.assertEquals(null, completeWO.Completion_Errors__c);

        Test.stopTest();
    }

    @IsTest
    static void ipCustomerMasterTest()
    {
        String erpID = 'TESTX00001';
        Account acct = FS_TestDataFactory.createTestErpAccount('PkiTest', 999, erpID, 'TS10');
        Contact cont = FS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX0001A');
        Product2 pd = FS_TestDataFactory.createTestProduct('TestProduct', '106018','ZZZ');
        Schema.Location loc = FS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
        Asset ip = FS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);

        ip.SoldTo_ExtId__c = erpID;
        ip.ShipTo_ExtId__c = erpID;
        ip.BillTo_ExtId__c = erpID;
        ip.Payer_ExtId__c = erpID;
        // SVMXCFG-903 Copy Local Language Accounts to WO
        //ip.LL_BillTo_ExtId__c = acctMap.get('LocalLangBillTo').PKI_SAP_Customer_Number__c;
        //ip.LL_ShipTo_ExtId__c = acctMap.get('LocalLangShipTo').PKI_SAP_Customer_Number__c;
        update ip;

        // Insert Work Order
        WorkOrder wo = FS_TestDataFactory.createWO(ip, cont);

        WorkOrder result = [SELECT Id, WorkOrderNumber, AccountId, ShipTo__c, BillTo__c, Payer__c,
                EInvoice_Platform_Id__c, EInvoice_Customer_Id__c,
                Local_Language_Bill_To_Account__c, Local_Language_Ship_To_Account__c
            FROM WorkOrder WHERE Id = :wo.Id];

        ip = [SELECT Id, Name, AccountId, SoldTo_Account__c, ShipTo_Account__c, BillTo_Account__c,
                Payer_Account__c, LL_BillTo_Account__c, LL_ShipTo_Account__c
            FROM Asset WHERE Id = :ip.Id];
        System.assertNotEquals(null, ip.SoldTo_Account__c);

        System.assertEquals(ip.AccountId, result.AccountId);
        System.assertEquals(ip.ShipTo_Account__c, result.ShipTo__c);
        System.assertEquals(ip.BillTo_Account__c, result.BillTo__c);
        System.assertEquals(ip.Payer_Account__c, result.Payer__c);

        System.assertEquals(ip.LL_BillTo_Account__c, result.Local_Language_Bill_To_Account__c);
        System.assertEquals(ip.LL_ShipTo_Account__c, result.Local_Language_Ship_To_Account__c);
    }

/*
    @IsTest
    static void woLoadTest()
    {
        // 1/28/22 Added System.runAs current user to get around the MIXED DML error caused by the Process Builder P.FLOW_9020: Update User
        System.runAs(new User(Id = UserInfo.getUserId())) {

            Account acct = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001', 'GB');

            Account soldTo = FS_TestDataFactory.createTestAccount('IP Partner Test', 'TESTX00FF001', 'GB');
            Map<String, Account> acctMap = FS_TestDataFactory.createTestPartnerAccounts(soldTo);

            Account sapAcct = FS_TestDataFactory.createTestAccount('SAP Partner Test', 'TESTX00SAP001', 'GB');
            Map<String, Account> sapAcctMap = FS_TestDataFactory.createTestPartnerAccounts(sapAcct);

            Contact cont = FS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
            Product2 pd = FS_TestDataFactory.createTestProduct('TestProduct', '106018', 'ZZZ');
            Schema.Location loc = FS_TestDataFactory.createTestLocation(acct, 'TestLocationSite', '121212', 'LOC123');

            Asset ip = FS_TestDataFactory.createIP('123456', acct, loc, '5545333', pd);
            ip.SoldTo_Account__c = soldTo.Id;
            ip.ShipTo_Account__c = acctMap.get('ShipTo').Id;
            ip.BillTo_Account__c = acctMap.get('BillTo').Id;
            ip.Payer_Account__c = acctMap.get('Payer').Id;
            update ip;

            Profile p = [SELECT Id FROM Profile WHERE Name = 'PROFILE: Integration'];
            User integrationUser = [SELECT Id FROM User WHERE Alias = 'webm' AND ProfileId = :p.Id];
//          new User(alias = 'itest', email = 'testIntegration@yahoo.com',
//                  emailEncodingKey = 'UTF-8', languageLocaleKey = 'en_US', firstname = 'Testopher', lastName = 'Testintegration',
//                  localeSidKey = 'en_US', timeZoneSidKey = 'America/New_York', profileId = p.Id,
//                  username = 'testIntegration@yahoo.com', communityNickname = 'TestieInt');
//          insert integrationUser;
//          //PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'SETTING_System_Modify_All_Data_9000x39'];
//          PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'MODULE_Servicemax_Objects_2000_Read_Only'];
//          insert new PermissionSetAssignment(AssigneeId = integrationUser.Id, PermissionSetId = ps.Id);

            Test.startTest(); // 1/27/22 Added to fix issue with TOO MANY SOQL QUERIES

            System.runAs(integrationUser) {
                // Insert Work Order
                RecordType fsRecType = Utility.getRecordType('WorkOrder', 'Field_Service');
                Date startDate = System.today();
                WorkOrder wo = new WorkOrder();
                wo.Record_Type__c = fsRecType.Id;
                wo.AssetId = ip.id;
                wo.SVMXC__Perform_Auto_Entitlement__c = TRUE;
                wo.SAP_OrderType__c = 'ZM02';
                wo.SAP_ActivityType__c = 'REP';
                wo.Schema.Location = ip.Schema.Location;
                wo.SVMXC__Scheduled_Date__c = startDate.addMonths(1);
                wo.ContactId = cont.Id;
                wo.AccountId = sapAcct.Id;
                wo.ShipTo__c = sapAcctMap.get('ShipTo').Id;
                wo.BillTo__c = sapAcctMap.get('BillTo').Id;
                wo.Payer__c = sapAcctMap.get('Payer').Id;
                wo.External_ID__c = 'SAP000000000';
                wo.Perform_Auto_Assignment__c = true;
                wo.SAP_Work_Center__c = 'TSNULL'; // Not found.. tech will be null
                wo.SAP_Maintenance_Plant__c = 'TS12';
                insert wo;

                WorkOrder result = [
                        SELECT Id, Name, SVMXC__Billing_Type__c, SVMXC__Order_Type__c,
                                AccountId, ShipTo__c, BillTo__c, Payer__c
                        FROM WorkOrder
                        WHERE Id = :wo.Id
                ];
                // Make sure correct SMax values assigned..
                System.assertEquals('Billable', result.SVMXC__Billing_Type__c);
                System.assertEquals('Repair', result.SVMXC__Order_Type__c);

                // Make sure the triggers do not change the values...
                System.assertEquals(wo.AccountId, result.AccountId);
                System.assertEquals(wo.ShipTo__c, result.ShipTo__c);
                System.assertEquals(wo.BillTo__c, result.BillTo__c);
                System.assertEquals(wo.Payer__c, result.Payer__c);

                Test.stopTest(); // 1/27/22 Added to fix issue with TOO MANY SOQL QUERIES

                // SVMXINT-605 End of WO Load, send UPDATE even if above logic didnt fire
                // Simulate the update at the end of the load.. make sure an event is sent
                wo.SAP_SystemStatus__c = 'REL';
                wo.CreditHold__c = false;
                update wo;
            }
        }
    }
*/
    @IsTest
    static void testOneClickComplete_Simple()
    {
        Account acct = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
        Contact cont = FS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = FS_TestDataFactory.createTestProduct('TestProduct', '106018','ZZZ');
        pd.Super_Business_Unit__c = 'DAS';
        update pd;

        Schema.Location loc = FS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
        loc.MaintenancePlant__c = 'TT12';
        update loc;

        //Schema.Location expLoc = FS_TestDataFactory.createTestLocation(acct,'Test Expense Loc', 'TT12F000', 'LOC123');

        Product2 laborProd = FS_TestDataFactory.createTestProduct('TestLabor', 'LAB100101', 'ZZZ', 'Labor');
        Product2 travelProd = FS_TestDataFactory.createTestProduct('TestTravel', 'TRV10011', 'ZZZ', 'Travel');
        FS_FaultCode__c fc = FS_TestDataFactory.createTestFaultCode('TFAM', 'TFAM-TTT', 'TTT2', 'Testing', false);

        Asset ip = FS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);

        // Insert Work Order
        WorkOrder wo = FS_TestDataFactory.createWO(ip, cont);

        WorkOrder result = [SELECT Id, WorkOrderNumber, Super_Business_Unit__c FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals(pd.Super_Business_Unit__c, result.Super_Business_Unit__c);

        // Simulate SAP success
        wo.External_ID__c = 'SO001991992';
        wo.SAP_SystemStatus__c = 'REL';
        wo.CreditHold__c = false;
        update wo;

        Test.startTest();

        String usage = 'Usage';
        WorkOrderLineItem laborLine = new WorkOrderLineItem(
                WorkOrderId=wo.Id, Record_Type__c=usage, Line_Type__c = 'Labor', Status='Priced',
                Part__c = laborProd.Id, Quantity__c = 1.5);
        WorkOrderLineItem travelLine = new WorkOrderLineItem(
                WorkOrderId=wo.Id, Record_Type__c=usage, Line_Type__c = 'Travel', Status='Priced',
                Part__c = travelProd.Id, Quantity__c = 2);
        WorkOrderLineItem fcl = new WorkOrderLineItem(
                WorkOrderId=wo.Id, Record_Type__c=usage, Line_Type__c = 'Fault Code', Status='Open',
                Fault_Code__c = fc.Id);
        List<WorkOrderLineItem> lines = new List<WorkOrderLineItem> { laborLine, travelLine, fcl };
        insert lines;

        wo.Status='Work Complete';  // One-Click Complete
        update wo;

        // Should fail.. No Fault Lines..
        //result = [SELECT Id, Name, Status FROM WorkOrder WHERE Id = :wo.Id];
        //System.assertEquals('Work Complete - Error', result.Status);

        result = [SELECT Id, WorkOrderNumber, Status, Completion_Errors__c FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals(null, result.Completion_Errors__c);
        System.assertEquals('Work Complete - Pending', result.Status);

        List<WorkOrderLineItem> lineResults = [SELECT Id, LineItemNumber, Status FROM WorkOrderLineItem WHERE WorkOrderId = :wo.Id];
        for (WorkOrderLineItem lineResult : lineResults)
        {
            System.assertEquals('Submitted', lineResult.Status);
        }

        // Simulate a success response from SAP
        FS_WorkOrderDebriefService.DebriefResponse rsp = new FS_WorkOrderDebriefService.DebriefResponse();
        rsp.ServiceOrderNumber = wo.External_ID__c;
        rsp.NotificationNumber = 'NO' + wo.External_ID__c;
        rsp.CreditHold = false;
        rsp.SystemStatus = 'TECO';
        // 12/1/20 tony - Removed DIR, SRA, and CMPT as these picklist values are inactive or removed
        //rsp.UserStatus = 'CMPT;DIR;SRA';
        rsp.UserStatus = '';
        rsp.TransactionNumber = 'IDOC0007';
        rsp.Lines = new List<FS_WorkOrderDebriefService.DebriefLine>();
        for (WorkOrderLineItem lineResult : lineResults)
        {
            FS_WorkOrderDebriefService.DebriefLine dline = new FS_WorkOrderDebriefService.DebriefLine();
            dline.LineId = lineResult.LineItemNumber;
            dline.ConfirmationNumber = 'SAPCONF-' + lineResult.LineItemNumber;
            rsp.Lines.add(dline);
        }
        String svcResult = FS_WorkOrderDebriefService.submitDebriefResponse(rsp);
        System.assertEquals('Successfully processed Debrief Response', svcResult);

        result = [SELECT Id, WorkOrderNumber, Status, Completion_Errors__c FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals(null, result.Completion_Errors__c);
        System.assertEquals('Work Complete', result.Status);

        Test.stopTest();
    }

    @IsTest
    static void testOneClickComplete_SkipPricing()
    {
        Account acct = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
        Contact cont = FS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = FS_TestDataFactory.createTestProduct('TestProduct', '106018','ZZZ');
        pd.Super_Business_Unit__c = 'DAS';
        update pd;

        Schema.Location loc = FS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
        loc.MaintenancePlant__c = 'TT12';
        update loc;

        //Schema.Location expLoc = FS_TestDataFactory.createTestLocation(acct,'Test Expense Loc', 'TT12F000', 'LOC123');

        Product2 laborProd = FS_TestDataFactory.createTestProduct('TestLabor', 'LAB100101', 'ZZZ', 'Labor');
        Product2 travelProd = FS_TestDataFactory.createTestProduct('TestTravel', 'TRV10011', 'ZZZ', 'Travel');
        FS_FaultCode__c fc = FS_TestDataFactory.createTestFaultCode('TFAM', 'TFAM-TTT', 'TTT2', 'Testing', false);

        Asset ip = FS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);

        Date startDate = System.today().addMonths(-1);
        Date endDate = startDate.addMonths(11);
        ServiceContract sc = FS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.AccountId, startDate, endDate);
        ServiceContract item = FS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate, pd);
        ContractLineItem cp = FS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        Entitlement ent = FS_TestDataFactory.createEntitlement(item,'REP', 0, 0);
        ent.ServicePartsDiscountCovered__c = 100;
        update ent;

        // Insert Work Order
        WorkOrder wo = FS_TestDataFactory.createContractWO(ip, cont);

        WorkOrder result = [SELECT Id, WorkOrderNumber, Super_Business_Unit__c FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals(pd.Super_Business_Unit__c, result.Super_Business_Unit__c);

        // Simulate SAP success
        wo.External_ID__c = 'SO001991992';
        wo.SAP_SystemStatus__c = 'REL';
        wo.CreditHold__c = false;
        update wo;

        Test.startTest();

        String usage = 'Usage';
        WorkOrderLineItem laborLine = new WorkOrderLineItem(
                WorkOrderId=wo.Id, Record_Type__c=usage, Line_Type__c = 'Labor', Status='Open',
                Part__c = laborProd.Id, Quantity__c = 1.5);
        WorkOrderLineItem travelLine = new WorkOrderLineItem(
                WorkOrderId=wo.Id, Record_Type__c=usage, Line_Type__c = 'Travel', Status='Open',
                Part__c = travelProd.Id, Quantity__c = 2);
        WorkOrderLineItem fcl = new WorkOrderLineItem(
                WorkOrderId=wo.Id, Record_Type__c=usage, Line_Type__c = 'Fault Code', Status='Open',
                Fault_Code__c = fc.Id);
        List<WorkOrderLineItem> lines = new List<WorkOrderLineItem> { laborLine, travelLine, fcl };
        insert lines;

        wo.Status='Work Complete';  // One-Click Complete
        update wo;

        // Should fail.. No Fault Lines..
        //result = [SELECT Id, Name, Status FROM WorkOrder WHERE Id = :wo.Id];
        //System.assertEquals('Work Complete - Error', result.Status);

        result = [SELECT Id, WorkOrderNumber, Status, Completion_Errors__c FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals(null, result.Completion_Errors__c);
        System.assertEquals('Work Complete - Pending', result.Status);

        List<WorkOrderLineItem> lineResults = [SELECT Id, LineItemNumber, Status FROM WorkOrderLineItem WHERE WorkOrderId = :wo.Id];
        for (WorkOrderLineItem lineResult : lineResults)
        {
            System.assertEquals('Submitted', lineResult.Status);
        }

        // Simulate a success response from SAP
        FS_WorkOrderDebriefService.DebriefResponse rsp = new FS_WorkOrderDebriefService.DebriefResponse();
        rsp.ServiceOrderNumber = wo.External_ID__c;
        rsp.NotificationNumber = 'NO' + wo.External_ID__c;
        rsp.CreditHold = false;
        rsp.CreditHoldReason = '';
        rsp.SystemStatus = 'TECO';
        // 12/1/20 tony - Removed CMPT as this picklist value is inactive or removed
        //rsp.UserStatus = 'CMPT';
        rsp.UserStatus = '';
        rsp.TransactionNumber = 'IDOC0007';
        rsp.Lines = new List<FS_WorkOrderDebriefService.DebriefLine>();
        for (WorkOrderLineItem lineResult : lineResults)
        {
            FS_WorkOrderDebriefService.DebriefLine dline = new FS_WorkOrderDebriefService.DebriefLine();
            dline.LineId = lineResult.LineItemNumber;
            dline.ConfirmationNumber = 'SAPCONF-' + lineResult.LineItemNumber;
            rsp.Lines.add(dline);
        }
        String svcResult = FS_WorkOrderDebriefService.submitDebriefResponse(rsp);
        System.assertEquals('Successfully processed Debrief Response', svcResult);

        result = [SELECT Id, WorkOrderNumber, Status, Completion_Errors__c FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals(null, result.Completion_Errors__c);
        System.assertEquals('Work Complete', result.Status);

        Test.stopTest();
    }

    @IsTest
    static void testOneClickComplete_CantSubmit()
    {
        Account acct = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
        Contact cont = FS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = FS_TestDataFactory.createTestProduct('TestProduct', '106018','ZZZ');
        pd.Super_Business_Unit__c = 'DAS';
        update pd;

        Schema.Location loc = FS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
        loc.MaintenancePlant__c = 'TT12';
        update loc;

        Schema.Location expLoc = FS_TestDataFactory.createTestLocation(acct,'Test Expense Loc', 'TT12F000', 'LOC123');

        Product2 laborProd = FS_TestDataFactory.createTestProduct('TestLabor', 'LAB100101', 'ZZZ', 'Labor');
        Product2 travelProd = FS_TestDataFactory.createTestProduct('TestTravel', 'TRV10011', 'ZZZ', 'Travel');
        FS_FaultCode__c fc = FS_TestDataFactory.createTestFaultCode('TFAM', 'TFAM-TTT', 'TTT2', 'Testing', false);

        Asset ip = FS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);

        Date startDate = System.today().addMonths(-1);
        Date endDate = startDate.addMonths(11);
        ServiceContract sc = FS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.AccountId, startDate, endDate);
        ServiceContract item = FS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate, pd);
        ContractLineItem cp = FS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
        Entitlement ent = FS_TestDataFactory.createEntitlement(item,'REP', 0, 0);
        ent.Labor_Discount_Covered__c = 10; // This discount wont allow it to submit without pricing
        ent.Travel_Discount_Covered__c = 100;
        update ent;

        // Insert Work Order
        WorkOrder wo = FS_TestDataFactory.createContractWO(ip, cont);

        WorkOrder result = [SELECT Id, WorkOrderNumber, Super_Business_Unit__c FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals(pd.Super_Business_Unit__c, result.Super_Business_Unit__c);

        // Simulate SAP success
        wo.External_ID__c = 'SO001991992';
        wo.SAP_SystemStatus__c = 'REL';
        wo.CreditHold__c = false;
        update wo;

        Test.startTest();

        String usage = 'Usage';
        WorkOrderLineItem laborLine = new WorkOrderLineItem(
                WorkOrderId=wo.Id, Record_Type__c=usage, Line_Type__c = 'Labor', Status='Open',
                Part__c = laborProd.Id, Quantity__c = 1.5);
        WorkOrderLineItem travelLine = new WorkOrderLineItem(
                WorkOrderId=wo.Id, Record_Type__c=usage, Line_Type__c = 'Travel', Status='Open',
                Part__c = travelProd.Id, Quantity__c = 2);
        WorkOrderLineItem fcl = new WorkOrderLineItem(
                WorkOrderId=wo.Id, Record_Type__c=usage, Line_Type__c = 'Fault Code', Status='Invalid',
                Fault_Code__c = fc.Id); // Not Open, Priced, Canceled, Confirmed or Submitted.. Anything else will fail
        List<WorkOrderLineItem> lines = new List<WorkOrderLineItem> { laborLine, travelLine, fcl };
        insert lines;

        wo.Status='Work Complete';  // One-Click Complete
        update wo;

        // Should fail.. No Fault Lines..
        //result = [SELECT Id, Name, Status FROM WorkOrder WHERE Id = :wo.Id];
        //System.assertEquals('Work Complete - Error', result.Status);

        result = [SELECT Id, WorkOrderNumber, Status, Completion_Errors__c FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals(true, result.Completion_Errors__c.contains('Non-Confirmed line is not able to be Submitted'));
        System.assertEquals('Work Complete - Error', result.Status);

        List<WorkOrderLineItem> lineResults = [SELECT Id, LineItemNumber, Status, Line_Type__c FROM WorkOrderLineItem WHERE WorkOrderId = :wo.Id];
        for (WorkOrderLineItem lineResult : lineResults)
        {
            if (lineResult.Line_Type__c == 'Labor') {
                System.assertEquals('Open', lineResult.Status);
            }
            else if (lineResult.Line_Type__c == 'Travel') {
                System.assertEquals('Submitted', lineResult.Status);
            }
        }

        // Should fail.. not allowed.
        FS_WorkOrderDebriefService.DebriefResponse rsp = new FS_WorkOrderDebriefService.DebriefResponse();
        rsp.ServiceOrderNumber = wo.External_ID__c;
        String svcResult = FS_WorkOrderDebriefService.submitDebriefResponse(rsp);
        //System.assertEquals(true, svcResult.startsWith('Cannot process Debrief Response'));

        Test.stopTest();
    }

    @IsTest
    static void testOneClickComplete_StuckLines()
    {
        Account acct = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
        Contact cont = FS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = FS_TestDataFactory.createTestProduct('TestProduct', '106018','ZZZ');
        pd.Super_Business_Unit__c = 'DAS';
        update pd;

        Schema.Location loc = FS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
        loc.MaintenancePlant__c = 'TT12';
        update loc;

        Schema.Location expLoc = FS_TestDataFactory.createTestLocation(acct,'Test Expense Loc', 'TT12F000', 'LOC123');

        Product2 laborProd = FS_TestDataFactory.createTestProduct('TestLabor', 'LAB100101', 'ZZZ', 'Labor');
        Product2 travelProd = FS_TestDataFactory.createTestProduct('TestTravel', 'TRV10011', 'ZZZ', 'Travel');
        FS_FaultCode__c fc = FS_TestDataFactory.createTestFaultCode('TFAM', 'TFAM-TTT', 'TTT2', 'Testing', false);

        Asset ip = FS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);

        // Insert Work Order
        WorkOrder wo = FS_TestDataFactory.createWO(ip, cont);

        WorkOrder result = [SELECT Id, WorkOrderNumber, Super_Business_Unit__c FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals(pd.Super_Business_Unit__c, result.Super_Business_Unit__c);

        // Simulate SAP success
        wo.External_ID__c = 'SO001991992';
        wo.SAP_SystemStatus__c = 'REL';
        wo.CreditHold__c = false;
        update wo;

        Test.startTest();

        String usage = 'Usage';
        WorkOrderLineItem laborLine = new WorkOrderLineItem(
                WorkOrderId=wo.Id, Record_Type__c=usage, Line_Type__c = 'Labor', Status='Submitted',
                Part__c = laborProd.Id, Quantity__c = 1.5);
        WorkOrderLineItem travelLine = new WorkOrderLineItem(
                WorkOrderId=wo.Id, Record_Type__c=usage, Line_Type__c = 'Travel', Status='Submitted',
                Part__c = travelProd.Id, Quantity__c = 2);
        WorkOrderLineItem fcl = new WorkOrderLineItem(
                WorkOrderId=wo.Id, Record_Type__c=usage, Line_Type__c = 'Fault Code', Status='Submitted',
                Fault_Code__c = fc.Id); // "Stuck" in Submitted.. this will fail
        List<WorkOrderLineItem> lines = new List<WorkOrderLineItem> { laborLine, travelLine, fcl };
        insert lines;

        wo.Status='Work Complete';  // One-Click Complete
        update wo;

        // Should fail.. No Fault Lines..
        //result = [SELECT Id, Name, Status FROM WorkOrder WHERE Id = :wo.Id];
        //System.assertEquals('Work Complete - Error', result.Status);

        result = [SELECT Id, WorkOrderNumber, Status, Completion_Errors__c FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals(true, result.Completion_Errors__c.contains('Wait for the 3 Submitted Line(s) to finish processing.'));
        System.assertEquals('Work Complete - Error', result.Status);

        // Should fail.. not found.
        FS_WorkOrderDebriefService.DebriefResponse rsp = new FS_WorkOrderDebriefService.DebriefResponse();
        rsp.ServiceOrderNumber = 'FrankWasHere';
        String svcResult = FS_WorkOrderDebriefService.submitDebriefResponse(rsp);
        System.assertEquals(true, svcResult.contains('Could NOT find Work Order with External ID'));

        Test.stopTest();
    }

    @IsTest
    static void testOneClickComplete_NonConsumable()
    {
        Account acct = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
        Contact cont = FS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = FS_TestDataFactory.createTestProduct('TestProduct', '106018','ZZZ');
        pd.Super_Business_Unit__c = 'DAS';
        update pd;

        Schema.Location loc = FS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
        loc.MaintenancePlant__c = 'BR12'; // This creates a "Non Consumable" Location
        update loc;

//      Schema.Location expLoc = FS_TestDataFactory.createTestLocation(acct,'Test Expense Loc', 'TT12F000', 'LOC123');

        Product2 laborProd = FS_TestDataFactory.createTestProduct('TestLabor', 'LAB100101', 'ZZZ', 'Labor');
        Product2 travelProd = FS_TestDataFactory.createTestProduct('TestTravel', 'TRV10011', 'ZZZ', 'Travel');
        Product2 partsProd = FS_TestDataFactory.createTestProduct('TestPart', 'PRT100101', 'ZZZ', 'Service Parts');
        FS_FaultCode__c fc = FS_TestDataFactory.createTestFaultCode('TFAM', 'TFAM-TTT', 'TTT2', 'Testing', false);

        Asset ip = FS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);

//      Date startDate = System.today();
//      Date endDate = startDate.addMonths(12);
//      ServiceContract sc = FS_TestDataFactory.createSvcMaintContract('TestServiceContract', ip.AccountId, startDate, endDate);
//      ServiceContract item = FS_TestDataFactory.createContractItem(sc, 'TestServiceContract', startDate, endDate);
//      ContractLineItem cp = FS_TestDataFactory.createCoveredIP(item, startDate, endDate, ip);
//      Entitlement ent = FS_TestDataFactory.createEntitlement(item,'REP', 0, 0);
//      ent.SVMXC__Labor_Discount_Covered__c = 10; // This discount wont allow it to submit without pricing
//      ent.SVMXC__Travel_Discount_Covered__c = 100;
//      update ent;

        // Insert Work Order
        System.debug('ip.Id: ' + ip.Id);
        System.debug('ip.MaintenancePlant__c: ' + ip.MaintenancePlant__c);
        System.debug('ip.SalesOrg__c: ' + ip.SalesOrg__c);
        WorkOrder wo = FS_TestDataFactory.createWO(ip, cont);

        WorkOrder result = [SELECT Id, WorkOrderNumber, Super_Business_Unit__c
            FROM WorkOrder WHERE Id = :wo.Id];
        System.debug('result: ' + result);
        System.assertEquals(pd.Super_Business_Unit__c, result.Super_Business_Unit__c);

        // Simulate SAP success
        wo.External_ID__c = 'SO001991992';
        wo.SAP_SystemStatus__c = 'REL';
        wo.CreditHold__c = false;
        update wo;

        Test.startTest();

        String usage = 'Usage';
        WorkOrderLineItem laborLine = new WorkOrderLineItem(
                WorkOrderId=wo.Id, Record_Type__c=usage, Line_Type__c = 'Labor', Status='Priced',
                Part__c = laborProd.Id, Quantity__c = 1.5);
        WorkOrderLineItem travelLine = new WorkOrderLineItem(
                WorkOrderId=wo.Id, Record_Type__c=usage, Line_Type__c = 'Travel', Status='Priced',
                Part__c = travelProd.Id, Quantity__c = 2);
        WorkOrderLineItem partsLine = new WorkOrderLineItem(
                WorkOrderId=wo.Id, Record_Type__c=usage, Line_Type__c = 'Parts', Status='Priced',
                Part__c = partsProd.Id, Quantity__c = 1, Consumed_From_Location__c = loc.Id);
        WorkOrderLineItem fcl = new WorkOrderLineItem(
                WorkOrderId=wo.Id, Record_Type__c=usage, Line_Type__c = 'Fault Code', Status='Open',
                Fault_Code__c = fc.Id);
        List<WorkOrderLineItem> lines = new List<WorkOrderLineItem> { laborLine, travelLine, partsLine, fcl };
        insert lines;

        wo.Status='Work Complete';  // One-Click Complete
        update wo;

        result = [SELECT Id, WorkOrderNumber, Status, Completion_Errors__c FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals(true, result.Completion_Errors__c.contains('Non-Consumable'));
        System.assertEquals('Work Complete - Material Follow Up', result.Status);

        List<WorkOrderLineItem> lineResults = [SELECT Id, LineItemNumber, Status, Line_Type__c FROM WorkOrderLineItem WHERE WorkOrderId = :wo.Id];
        for (WorkOrderLineItem lineResult : lineResults)
        {
            if (lineResult.Line_Type__c == 'Parts') {
                System.assertEquals('Priced', lineResult.Status);
            } else {
                System.assertEquals('Submitted', lineResult.Status);
            }
        }

        Test.stopTest();
    }

    @IsTest
    static void testCancelWorkOrder()
    {
        Account acct = FS_TestDataFactory.createTestErpAccount('PkiTest', 999, 'TESTX000000001','GB');
        Contact cont = FS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = FS_TestDataFactory.createTestProduct('TestProduct', '106018','ZZZ');
        pd.Super_Business_Unit__c = 'DAS';
        update pd;

        Schema.Location loc = FS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
//      loc.MaintenancePlant__c = 'TS12';
//      update loc;

        //Schema.Location expLoc = FS_TestDataFactory.createTestLocation(acct,'Test Expense Loc', 'TT12F000', 'LOC123');

        Product2 laborProd = FS_TestDataFactory.createTestProduct('TestLabor', 'LAB100101', 'ZZZ', 'Labor');
        Product2 travelProd = FS_TestDataFactory.createTestProduct('TestTravel', 'TRV10011', 'ZZZ', 'Travel');

        Asset ip = FS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);

        System.debug('SOQL Queries before WO creation: ' + Limits.getQueries());

        // Insert Work Order
        WorkOrder wo = FS_TestDataFactory.createWO(ip, cont);

        // Fake an Assignment..
//      User techUser = new User(Id = UserInfo.getUserId());
//      ServiceResource tech = FS_TestDataFactory.createTestTechnician('TestTeam01', techUser, 'Test Tech1', 'TS12', 'T001');
//      wo.SVMXC__Group_Member__c = tech.Id;
//      update wo;
//
//      System.debug('SOQL Queries before Event creation: ' + Limits.getQueries());
//
//      Event e = new Event();
//      e.Subject = 'Test Event';
//      e.WhatId = wo.Id;
//      e.OwnerId = techUser.Id;
//      e.StartDateTime = System.now();
//      e.EndDateTime = e.StartDateTime.addHours(3);
//      insert e;

        WorkOrder result = [SELECT Id, WorkOrderNumber, Super_Business_Unit__c FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals(pd.Super_Business_Unit__c, result.Super_Business_Unit__c);

        System.debug('SOQL Queries before Test.startTest: ' + Limits.getQueries());

        Test.startTest(); // 01/11/2023 tony Moved Test.startTest to here for get around SOQL Query 101 Limit

        wo.External_ID__c = 'SO001991993';
        wo.SAP_SystemStatus__c = 'REL';
        update wo;

        String usage = 'Usage';
        WorkOrderLineItem laborLine = new WorkOrderLineItem(
                WorkOrderId=wo.Id, Record_Type__c=usage, Line_Type__c = 'Labor', Status='Confirmed',
                Part__c = laborProd.Id, Quantity__c = 1.5);
        WorkOrderLineItem travelLine = new WorkOrderLineItem(
                WorkOrderId=wo.Id, Record_Type__c=usage, Line_Type__c = 'Travel', Status='Confirmed',
                Part__c = travelProd.Id, Quantity__c = 2);
        List<WorkOrderLineItem> lines = new List<WorkOrderLineItem> { laborLine, travelLine };
        insert lines;

        //Test.startTest();

        wo = new WorkOrder();
        wo.Id = result.Id;
        wo.Status='Canceled';
        wo.Canceled_Date_Time__c = Datetime.now();
        wo.Canceled_Reason__c = 'Duplicate Entry';

        // Should fail.. Lines are not Canceled..
        Database.SaveResult results = Database.update(wo, false);
        System.assertEquals(false, results.isSuccess());

//      List<Event> eventList = [SELECT Id, Subject FROM Event WHERE WhatId = :wo.Id];
//      System.assertEquals(1, eventList.size());

        // Cancel the lines..
        for (WorkOrderLineItem line : lines)
        {
            //line.Status = 'Canceled';
            line.Cancel_Line__c = true;
            line.Cancel_Reason__c = 'Other';
        }
        update lines;

        // Try again..
        wo = new WorkOrder();
        wo.Id = result.Id;
        wo.Status='Canceled';
        wo.Canceled_Date_Time__c = Datetime.now();
        wo.Canceled_Reason__c = 'Duplicate Entry';

        update wo;

        System.debug('SOQL Queries before Test.stopTest: ' + Limits.getQueries());

        Test.stopTest();

        result = [SELECT Id, WorkOrderNumber, Status FROM WorkOrder WHERE Id = :wo.Id];
        //System.assertEquals(null, result.SVMXC__Group_Member__c);

        // SVMXCFG-837 Make sure WO Status does NOT change to Open in this scenario..
        System.assertEquals('Canceled', result.Status);

//      eventList = [SELECT Id, Subject FROM Event WHERE WhatId = :wo.Id];
//      System.assertEquals(0, eventList.size());
    }

    @IsTest
    static void testOneClickComplete_Error()
    {
        Account acct = FS_TestDataFactory.createTestErpAccount('PkiTest', 999, 'TESTX000000001','GB');
        Contact cont = FS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = FS_TestDataFactory.createTestProduct('TestProduct', '106018','ZZZ');
        pd.Super_Business_Unit__c = 'DAS';
        update pd;

        Schema.Location loc = FS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
        loc.MaintenancePlant__c = 'TT12';
        update loc;

        //Schema.Location expLoc = FS_TestDataFactory.createTestLocation(acct,'Test Expense Loc', 'TT12F000', 'LOC123');

        Product2 laborProd = FS_TestDataFactory.createTestProduct('TestLabor', 'LAB100101', 'ZZZ', 'Labor');
        Product2 travelProd = FS_TestDataFactory.createTestProduct('TestTravel', 'TRV10011', 'ZZZ', 'Travel');
        FS_FaultCode__c fc = FS_TestDataFactory.createTestFaultCode('TFAM', 'TFAM-TTT', 'TTT2', 'Testing', false);

        Asset ip = FS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);

        // Insert Work Order
        WorkOrder wo = FS_TestDataFactory.createWO(ip, cont);

        WorkOrder result = [SELECT Id, WorkOrderNumber, Super_Business_Unit__c FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals(pd.Super_Business_Unit__c, result.Super_Business_Unit__c);

        // Simulate SAP success
        wo.External_ID__c = 'SO001991992';
        wo.SAP_SystemStatus__c = 'REL';
        wo.CreditHold__c = false;
        update wo;

        Test.startTest();

        String usage = 'Usage';
        WorkOrderLineItem laborLine = new WorkOrderLineItem(
                WorkOrderId=wo.Id, Record_Type__c=usage, Line_Type__c = 'Labor', Status='Priced',
                Part__c = laborProd.Id, Quantity__c = 1.5);
        WorkOrderLineItem travelLine = new WorkOrderLineItem(
                WorkOrderId=wo.Id, Record_Type__c=usage, Line_Type__c = 'Travel', Status='Priced',
                Part__c = travelProd.Id, Quantity__c = 2);
        WorkOrderLineItem fcl = new WorkOrderLineItem(
                WorkOrderId=wo.Id, Record_Type__c=usage, Line_Type__c = 'Fault Code', Status='Open',
                Fault_Code__c = fc.Id);
        List<WorkOrderLineItem> lines = new List<WorkOrderLineItem> { laborLine, travelLine, fcl };
        insert lines;

        wo.Status='Work Complete';  // One-Click Complete
        update wo;

        // Should fail.. No Fault Lines..
        //result = [SELECT Id, Name, Status FROM WorkOrder WHERE Id = :wo.Id];
        //System.assertEquals('Work Complete - Error', result.Status);

        result = [SELECT Id, WorkOrderNumber, Status, Completion_Errors__c FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals(null, result.Completion_Errors__c);
        System.assertEquals('Work Complete - Pending', result.Status);

        List<WorkOrderLineItem> lineResults = [SELECT Id, LineItemNumber, Status, Line_Type__c
            FROM WorkOrderLineItem WHERE WorkOrderId = :wo.Id];
        for (WorkOrderLineItem lineResult : lineResults)
        {
            System.assertEquals('Submitted', lineResult.Status);
        }

        // Simulate a success response from SAP
        FS_WorkOrderDebriefService.DebriefResponse rsp = new FS_WorkOrderDebriefService.DebriefResponse();
        rsp.ServiceOrderNumber = wo.External_ID__c;
        rsp.NotificationNumber = 'NO' + wo.External_ID__c;
        rsp.CreditHold = false;
        rsp.SystemStatus = 'TECO';
        rsp.UserStatus = 'CMPT;DIR;SRA';
        rsp.TransactionNumber = 'IDOC0007';
        rsp.ErrorMessage = 'Test Header Msg';
        rsp.Lines = new List<FS_WorkOrderDebriefService.DebriefLine>();
        for (WorkOrderLineItem lineResult : lineResults)
        {
            FS_WorkOrderDebriefService.DebriefLine dline = new FS_WorkOrderDebriefService.DebriefLine();
            dline.LineId = lineResult.LineItemNumber;
            dline.LineType = lineResult.Line_Type__c;
            //dline.ConfirmationNumber = 'SAPCONF-' + lineResult.Name;
            if (dline.LineType == 'Fault Code')
            {
                dline.ConfirmationNumber = '0000000000';
            }
            else
            {
                dline.ConfirmationNumber = '0000000000-00000000';
                dline.ErrorMessage = 'Testing Line Errors';
            }
            rsp.Lines.add(dline);
        }
        FS_WorkOrderDebriefService.DebriefLine dlineX = new FS_WorkOrderDebriefService.DebriefLine();
        dlineX.LineId = 'BAD_LINE_ID';
        rsp.Lines.add(dlineX);

        String svcResult = FS_WorkOrderDebriefService.submitDebriefResponse(rsp);
        //System.assertEquals('Successfully processed Debrief Response', svcResult);

        //result = [SELECT Id, Name, Status, Completion_Errors__c FROM WorkOrder WHERE Id = :wo.Id];
        //System.assertEquals(null, result.Completion_Errors__c);
        //System.assertEquals('Work Complete', result.Status);

        Test.stopTest();
    }

    // 10/19/20222 ITSVMX-1029 Polaris Translation / Output Documents
    @IsTest
    static void testTranslationLookup()
    {
        FS_Translation__c t1 = FS_TestDataFactory.createTestTranslation('English (US)', 'US');
        FS_Translation__c t2 = FS_TestDataFactory.createTestTranslation('Spanish (ES)', 'ES');

        Account acct = FS_TestDataFactory.createTestErpAccount('PkiTest', 999, 'TESTX000000001','GB');
        Contact cont = FS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = FS_TestDataFactory.createTestProduct('TestProduct', '106018','ZZZ');
        Schema.Location loc = FS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
        loc.Country__c = 'US';
        update loc;

        Asset ip = FS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);

        Test.startTest();

        // Insert Work Order.. Translation should auto populate
        WorkOrder wo = FS_TestDataFactory.createWO(ip, cont);

        Test.stopTest();

        WorkOrder woResult = [SELECT Id, WorkOrderNumber, Translation__c FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals(t1.Id, woResult.Translation__c);

        // Simulate a User changing it manually.. shouldn't auto populate again
        woResult.Translation__c = t2.Id;
        update woResult;

        WorkOrder woResult2 = [SELECT Id, WorkOrderNumber, Translation__c FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals(t2.Id, woResult2.Translation__c);
    }

    @IsTest
    static void testTranslationLookupDefault()
    {
        FS_Translation__c t1 = FS_TestDataFactory.createTestTranslation('English (US)', 'US');
        FS_Translation__c t2 = FS_TestDataFactory.createTestTranslation('Spanish (US)', 'US');
        t2.Is_Default__c = true;
        update t2;

        Account acct = FS_TestDataFactory.createTestErpAccount('PkiTest', 999, 'TESTX000000001','BE');
        Contact cont = FS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = FS_TestDataFactory.createTestProduct('TestProduct', '106018','ZZZ');
        Schema.Location loc = FS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
        loc.Country__c = 'US';
        update loc;

        Asset ip = FS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);

        Test.startTest();

        // Insert Work Order.. Translation should auto populate
        WorkOrder wo = FS_TestDataFactory.createWO(ip, cont);

        Test.stopTest();

        WorkOrder woResult = [SELECT Id, WorkOrderNumber, CountryCode, Translation__c FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals(t2.Id, woResult.Translation__c);

        // Simulate a User changing it manually.. shouldn't auto populate again
        woResult.Translation__c = t1.Id;
        update woResult;

        WorkOrder woResult2 = [SELECT Id, WorkOrderNumber, Translation__c FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals(t1.Id, woResult2.Translation__c);
    }
/*

    static testMethod void testWorkOrderQueue()
    {
        Account acct = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX0PO000002');
        Contact cont = FS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Schema.Location loc = FS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TLOC1001001', 'TL0101');
        loc.MaintenancePlant__c = 'TT12';
        update loc;
        Product2 prod = FS_TestDataFactory.createTestProduct('Test Eq Product', 'TSTEQ01', 'ZZZ');

        ProductPlant__c pp1 = new ProductPlant__c(Plant__c = 'TT12', Product__c = prod.Id,
                BD_Return_Part_Number__c = 'L' + prod.Partnum__c);
        insert new List<ProductPlant__c> { pp1 };

        Group g1 = new Group(Name = 'TST WO Queue', DeveloperName = 'TST_WO_TS12_Depot', Type = 'Queue');
        insert g1;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            QueueSobject q1 = new QueueSobject(QueueId = g1.Id, SobjectType = 'WorkOrder');
            insert q1;
        }

        SVMXC__Service_Group_Members__c tech = FS_TestDataFactory.createTestTechnician('TestQueue01',
                null, 'Test Queue1', 'TS12', 'T001', null);
        tech.BD_Depot_Queue_Name__c = g1.DeveloperName;
        tech.SVMXC__Role__c = 'Work Order Queue';
        update tech;

        // 2/17/22 ITSMVX-767 Using Mass Assignment of Service Request to Depot should NOT change the Order Type or the Record Type
        SVMXC__Service_Group_Members__c tech2 = FS_TestDataFactory.createTestTechnician('TestQueue02',
                null, 'Test Queue2', 'TS13', 'T002', null);
        tech2.BD_Depot_Queue_Name__c = g1.DeveloperName;
        tech2.SVMXC__Role__c = 'Depot Queue';
        update tech2;

        Asset ip = FS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TST00101', prod);

        Test.startTest();

        WorkOrder wo = FS_TestDataFactory.createWO(ip, cont);
        wo.Status = 'Initializing';
        update wo;

        wo.External_ID__c = 'SOTST1001001';
        wo.SAP_SystemStatus__c = 'REL';
        update wo;

        // "Instrument Return to Depot" SFM...
        wo.SVMXC__Group_Member__c = tech.Id;
        update wo;

        // 2/17/22 ITSMVX-767 Using Mass Assignment of Service Request to Depot should NOT change the Order Type or the Record Type
        WorkOrder wo2 = FS_TestDataFactory.createWO(ip, cont);
        wo2.Status = 'Initializing';
        update wo2;

        wo2.External_ID__c = 'SOTST1001002';
        wo2.SAP_SystemStatus__c = 'REL';
        update wo2;

        // "Mass Assign to Depot Repair Queue"
        wo2.SVMXC__Group_Member__c = tech2.Id;
        update wo2;


        WorkOrder woResult = [
                SELECT Id, Name, SVMXC__Group_Member__c, RecordType.DeveloperName, OwnerId,
                        External_ID__c, BD_Equipment_Part_Return_Number__c
                FROM WorkOrder
                WHERE Id = :wo.Id
        ];
        // Make sure the RT does NOT change to Depot
        System.assertNotEquals('Depot_Repair', woResult.RecordType.DeveloperName);
        System.assertEquals(g1.Id, woResult.OwnerId);

        // 2/17/22 ITSMVX-767 Using Mass Assignment of Service Request to Depot should NOT change the Order Type or the Record Type
        WorkOrder woResult2 = [
                SELECT Id, Name, SVMXC__Group_Member__c, RecordType.DeveloperName, OwnerId,
                        External_ID__c, BD_Equipment_Part_Return_Number__c
                FROM WorkOrder
                WHERE Id = :wo2.Id
        ];
        // Make sure the RT does change to Depot for WOs with Record Type != Service_Request
        System.assertEquals('Depot_Repair', woResult2.RecordType.DeveloperName);
        System.assertEquals(g1.Id, woResult2.OwnerId);

        Test.stopTest();

    }
    */

    // 2022-05-09 Tony ITSVMX-562 Modify the replenishment parts ordering process
    @IsTest
    static void testRefurbishedPartsAllowed() {

        Account acct = FS_TestDataFactory.createTestAccount('Test Acct', 'TST1001001');
        Product2 product1 = FS_TestDataFactory.createTestProduct('Test Product', 'TPRD1001', 'ZZZ');
        Product2 product2 = FS_TestDataFactory.createTestProduct('Test Refurb Product', 'Refurb123', 'ZZZ');

        // Create an Active Service Contract
        Date startDate = System.today() - 30;
        Date endDate = System.today() + 30;
        ServiceContract serviceContract = FS_TestDataFactory.createSvcMaintContract('TestSvcContract', acct.Id, startDate, endDate);
        ServiceContract serviceContractItem = FS_TestDataFactory.createContractItem(serviceContract, 'TestSvcContractItem', startDate, endDate, product1);

        // Create Service Contract Services with Service Parts Discount Covered = 100.00
        Entitlement serviceContractServices = FS_TestDataFactory.createEntitlement(serviceContractItem, 'Parts', 10, 10);
        serviceContractServices.ServicePartsDiscountCovered__c = 100.00;
        update serviceContractServices;
        System.debug('serviceContractServices: ' + serviceContractServices);

        Contact cont = FS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        Schema.Location loc = FS_TestDataFactory.createTestLocation(acct, 'Test Loc', 'TLOC0010101', 'TST001');

        // Create an Installed Product with Medical Device = FALSE
        Asset ip = FS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TST00101', product1);
        ip.MaintenancePlant__c = 'P123';
        update ip;
        System.debug('ip.IsMedicalDevice__c: ' + ip.fxIsMedicalDevice__c);

        // Create Product Plant
        FS_ProductPlant__c productPlant = new FS_ProductPlant__c();
        productPlant.Product__c = product1.Id;
        productPlant.Plant__c = 'P123';
//      productPlant.Refurbished_Part__c = product2.Id;  // This should be set by the code in ProductManager.processProductPlant()
        productPlant.Refurbished_Part_Number__c = 'Refurb123';
        insert productPlant;
        productPlant.PlannedDeliveryTimeInDays__c = '3';
        update productPlant;

        FS_ProductPlant__c plantResult = [SELECT Id, Name, Refurbished_Part__c FROM FS_ProductPlant__c WHERE Id = :productPlant.Id];
        System.assertEquals(product2.Id, plantResult.Refurbished_Part__c);

        // Create Work Order that will have Use Refurbished Parts = TRUE
        WorkOrder wo = FS_TestDataFactory.createWO(ip, cont);
        wo.ContractItem__c = serviceContractItem.Id;
        wo.ContractEntitlement__c = serviceContractServices.Id;
        wo.SAP_Maintenance_Plant__c = 'T123';
        update wo;
        System.debug('wo.ContractItem__c: ' + wo.ContractItem__c);

        WorkOrder testWO = [SELECT Id, Use_Refurbished_Parts__c FROM WorkOrder WHERE Id = :wo.Id];
        System.debug('testWO.BD_Use_Refurbished_Parts__c: ' + testWO.Use_Refurbished_Parts__c);
        System.assertEquals(true, testWO.Use_Refurbished_Parts__c, 'Use Refurbished Parts should be set to true on Work Order: ' + testWO.Id);
        wo.SAP_SystemStatus__c ='TECO';
        wo.REcord_Type__C = 'Field Service';
        update wo;
    }
}