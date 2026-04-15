@IsTest
public class FS_ReturnOrder_UT {

    @TestSetup
    static void setupTest() {
        FS_TestDataFactory.createDefaultOperatingHours();
        
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
    static void createWorkOrderTestData()
    {
        Account acct = FS_TestDataFactory.createTestErpAccount('PkiTest', 999,'TESTX000000001','GB');
        //Account acct2 = FS_TestDataFactory.createTestErpAccount('PkiTest2', 9993,'TESTX000000002','GB');
        
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

//      Schema.Location expLoc = FS_TestDataFactory.createTestLocation(acct,'Test Expense Loc', 'TT12F000', 'LOC123');

        Product2 laborProd = FS_TestDataFactory.createTestProduct('TestLabor', 'LAB100101', 'ZZZ', 'Labor');
        Product2 travelProd = FS_TestDataFactory.createTestProduct('TestTravel', 'TRV10011', 'ZZZ', 'Travel');

        Asset ip = FS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);

        // Insert Work Order
        WorkOrder wo = FS_TestDataFactory.createWO(ip, cont);
        
        

        WorkOrder result = [SELECT Id, WorkOrderNumber, Super_Business_Unit__c FROM WorkOrder WHERE Id = :wo.Id];
        
        
          // Insert location
        Schema.Location loc1 = FS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TLOC1001001', 'TL0101');
        loc1.IsInventoryLocation = true;
        loc1.IsMobile = true;
        update loc1;
        
          // Insert location
        Schema.Location loc3 = FS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TLOC1001003', 'TL0103');
        loc3.IsInventoryLocation = true;
        loc3.IsMobile = true;
        loc3.LocationType='Depot';
        update loc3;
        
        FS_DepotPlant__c dp =new FS_DepotPlant__c();
        dp.Depot_Location__c =loc3.id;
        insert dp;
        
        result.Record_Type__c='Depot';
        result.CreditHold__c=false;
        result.Depot_Plant__c=dp.id;
        result.External_ID__c='998877';
        update result;
        
          // Insert location
            Schema.Location loc2 = FS_TestDataFactory.createTestLocation(acct, 'Test Location2', 'TLOC1001002', 'TL0102');
        loc2.IsInventoryLocation = true;
        loc2.IsMobile = true;
        update loc2;
        List<ServiceResource> serRes = [SELECT Id, Name, Plant__c, LocationId,RelatedRecordId, LocationCode__c FROM ServiceResource];
        serRes[0].Plant__c = 'GBA2';
        serRes[0].LocationId=loc1.id;
        update serRes[0];



        Test.startTest();

        ReturnOrder  ro = new ReturnOrder();
        ro.AccountId= acct.id;
        ro.SourceLocationId=loc1.id;
        ro.DestinationLocationId=loc2.id;
        ro.Technician__c=serRes[0].id;
        ro.Work_Order__c=wo.id;
        insert ro;

        FS_IntegrationError__c err1 = new FS_IntegrationError__c();
        err1.RelatedElementType__c = 'ReturnOrderId';
        err1.RelatedElementIdentifier__c = ro.Id;
        err1.ErrorMessage__c = 'Testing Return Order Error by Id';
        insert err1;

        ro.ExternalId__c = 'ABC123SAP4ME';
        update result;

        FS_IntegrationError__c err2 = new FS_IntegrationError__c();
        err2.RelatedElementType__c = 'ReturnOrderNumber';
        err2.RelatedElementIdentifier__c = ro.ExternalId__c;
        err2.ErrorMessage__c = 'Testing Return Order Error by Number';
        insert err2;

        ReturnOrder  ro1 = new ReturnOrder();
        //ro1.AccountId= acct.id;
        ro1.SourceLocationId=loc1.id;
        //ro1.DestinationLocationId=loc2.id;
        ro1.Technician__c=serRes[0].id;
        ro1.Work_Order__c=wo.id;
        //ro1.SoldTo_ExtId__c='1122323';
        insert ro1;

        ro1.SoldTo_ExtId__c ='1122323';
        update ro1;
        
        FS_ReturnOrderManager.autoCreateRMA(new List<WorkORder>{wo},null);
        
        result.status ='Canceled';
        update result;
        FS_ReturnOrderManager.cancelDepotReturnOrders(new List<WorkORder>{result},null);

        Test.stopTest();
    }
}