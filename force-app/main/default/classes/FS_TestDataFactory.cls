@IsTest
public class FS_TestDataFactory {
    private FS_TestDataFactory() {
    }

//    public static User createTestUser(String alias)
//    {
//        // ITSFDC - 1047 Had to change this to be able to deploy as the 'SVMX PS - Field Engineer' profile as been removed
//        //Profile p = [SELECT Id FROM Profile WHERE Name = 'SVMX PS - Field Engineer'];
//        Profile p = [SELECT Id FROM Profile WHERE Name = 'PROFILE: Field Service Engineer'];
//        User user = new User(alias = alias, email = alias+'Mail@yahoo.com',
//                emailEncodingKey = 'UTF-8', languageLocaleKey = 'en_US', firstname = alias, lastName = 'Testofferson',
//                localeSidKey = 'en_US', timeZoneSidKey = 'America/Los_Angeles', profileId = p.Id,
//                /*PKI_GBL_Job_Family__c = 'Service',*/ username = alias+'Mail@yahoo.com', communityNickname = alias+'Boy');
//        // 3/17/2022 - Added WirelessEmail so we can bypass Process Builder P.FLOW_9020: Update User that causes a MIXED DML error
//        insert user;
//
//         // Query the Permission Set by API name
//        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name='FSL_Resource_Permissions' LIMIT 1];
//        PermissionSet ps3 = [SELECT Id FROM PermissionSet WHERE Name='FSL_Resource_License' LIMIT 1];
//        PermissionSet ps10 = [SELECT Id FROM PermissionSet WHERE Name='FSL_Mobile_License' LIMIT 1];
//
//        // Assign the Permission Set to the user
//        PermissionSetAssignment psa = new PermissionSetAssignment(
//            AssigneeId = user.Id,
//            PermissionSetId = ps.Id
//        );
//        insert psa;
//        PermissionSetAssignment psa3 = new PermissionSetAssignment(
//            AssigneeId = user.Id,
//            PermissionSetId = ps3.Id
//        );
//        insert psa3;
//
//        PermissionSetAssignment psa10 = new PermissionSetAssignment(
//            AssigneeId = user.Id,
//            PermissionSetId = ps10.Id
//        );
//        insert psa10;
//        PermissionSet ps2 = [SELECT Id FROM PermissionSet WHERE Name='CUSTOM_C_PERM_9200_Allow_Creating_Account' LIMIT 1];
//         SetupEntityAccess sea = new SetupEntityAccess();
//            sea.ParentId = ps2.Id;
//            sea.SetupEntityId = [select Id from CustomPermission where DeveloperName = 'C_PERM_9200_Allow_Creating_Account'][0].Id;
//            //insert sea;
//
//        PermissionSetAssignment psa5 = new PermissionSetAssignment();
//        psa5.AssigneeId = user.id;
//        psa5.PermissionSetId = ps2.Id;
//        insert psa5;
//
//        return user;
//    }

    public static Account createTestAccount(String name, String extId)
    {
        return createTestAccount(name, extId, 'US');
    }

    public static Account createTestAccount(String name, String extId, String countryCode)
    {
        //RecordType customerRecType =FS_Utility.getRecordType('Account', 'Customer');
        Account acct = new Account();
        //acct.RecordTypeId = customerRecType.Id;
        acct.Name = name;
        acct.SAP_Customer_Number__c = extId;
        acct.SAP_Customer_Number_Formatted__c = extId;
        acct.SAP_Country_Code__c = countryCode;
        // 2018-03-16 MAPLES - Added the new fields for Payer address
        acct.ShippingStreet = '123 TEST Street';
        acct.ShippingCity = 'No-where';
        acct.ShippingState = 'California';
        acct.ShippingStateCode='CA';
        acct.ShippingPostalCode = '12345';
        acct.ShippingCountry ='United States';
        acct.ShippingCountryCode='US';
        acct.CurrencyIsoCode = 'USD';
        
        // 2018-03-16 MAPLES - END of Updates
       // acct.BillingCountry = countryCode;
        // 8/12/20 tony - Added MDM_Status__c field value as new validation rule requires it.
        acct.MDM_Status__c = 'Test123';
        insert acct;

        return acct;
    }

    public static Account createTestErpAccount(String name, Integer clusterID, String erpID, String salesOrg)
    {
        Account acct = new Account();
        acct.Name = name;
        acct.MDM_Cluster_ID__c = clusterID;
        acct.Account_Domains__c='testDomain';
        insert acct;

        Country__c lkupCountry = new Country__c();
        lkupCountry.Name = 'United States';
        lkupCountry.SFDC_Country_Name__c = 'United States';
        lkupCountry.Country_ISO_Alpha_2__c = 'US';
        lkupCountry.Global_Territory__c = 'AMERICAS';
        lkupCountry.Sub_Territory__c = 'NORTH AMERICA';
        lkupCountry.Super_Territory__c = 'AMERICAS';
        lkupCountry.Territory__c = 'NORTH AMERICA';
        insert lkupCountry;

        State__c lkupState = new State__c();
        lkupState.Name = 'Florida';
        lkupState.SFDC_State_Name__c = 'Florida';
        lkupState.ISOCode__c = 'FL';
        lkupState.Country__c = lkupCountry.Id;
        insert lkupState;

        ERP_Address__c master = new ERP_Address__c();
        master.Address_Type__c = 'Master';
        master.ERP_Customer_Number__c = erpID;
        master.MDM_Cluster_Id__c = clusterID;
        master.Address_Street_Line_1__c = '123 Main St';
        master.Address_City__c = 'Tampa';
        master.Address_Postal_Code__c = '33626';
        master.LKUP_State__c = lkupState.Id;
        master.LKUP_Country__c = lkupCountry.Id;
        master.Account__c = acct.Id;
        insert master;

        List<ERP_Address__c> newAddresses = new List<ERP_Address__c>();
        ERP_Address__c soldTo = new ERP_Address__c();
        soldTo.Name = 'SoldTo-' + salesOrg + '-' + erpID;
        soldTo.Address_Type__c = 'Sold To';
        soldTo.ERP_Sales_Org__c = salesOrg;
        soldTo.External_Id__c = erpID + '-' + soldTo.Name;
        soldTo.Master_Address__c = master.Id;
        soldTo.Target_Address__c = master.Id;
        soldTo.Account__c = acct.Id;
        newAddresses.add(soldTo);

        ERP_Address__c shipTo = new ERP_Address__c();
        shipTo.Name = 'ShipTo-' + salesOrg + '-' + erpID;
        shipTo.Address_Type__c = 'Ship To';
        shipTo.ERP_Sales_Org__c = salesOrg;
        shipTo.External_Id__c = erpID + '-' + shipTo.Name;
        shipTo.Master_Address__c = master.Id;
        shipTo.Target_Address__c = master.Id;
        shipTo.Account__c = acct.Id;
        newAddresses.add(shipTo);

        ERP_Address__c payer = new ERP_Address__c();
        payer.Name = 'Payer-' + salesOrg + '-' + erpID;
        payer.Address_Type__c = 'Payer';
        payer.ERP_Sales_Org__c = salesOrg;
        payer.External_Id__c = erpID + '-' + payer.Name;
        payer.Master_Address__c = master.Id;
        payer.Target_Address__c = master.Id;
        payer.Account__c = acct.Id;
        newAddresses.add(payer);

        insert newAddresses;

        return acct;
    }

    public static Contact createTestContact(String first, String last, Account acct, String contactID)
    {
        Contact c = new Contact();
        c.FirstName = first;
        c.LastName = last;
        c.SAP_Contact_ID__c = contactID;
        c.AccountId = acct.Id;
        c.MailingCountry = 'United States';
        insert c;

        ERP_Relationship__c rel = new ERP_Relationship__c();
        rel.External_Id__c = contactID;
        rel.Contact__c = c.Id;
        insert rel;

        return c;
    }

    public static ServiceResource createTestTechnician(String teamName, User user, String techName, String plant, String locCode)
    {
        return createTestTechnician(teamName, user, techName, plant, locCode, locCode);
    }

    public static ServiceResource createTestTechnician(String teamName, User user, String techName, String plant, String locCode, String workCenter)
    {
        ServiceResource tech = new ServiceResource();
        tech.Plant__c = plant;
        tech.LocationCode__c = locCode;
        tech.Work_Center__c = workCenter;
        tech.External_ID__c = plant + workCenter;
        tech.ResourceType ='T';
        tech.RelatedRecordId = (user == null) ? null : user.Id;
        tech.IsActive = true;
        //tech.SVMXC__Enable_Scheduling__c = true;
        tech.Name='test';
        insert tech;

        return tech;
    }
    
    public static List<Schema.Skill> loadTestSkills(Integer count)
    {
        List<Schema.Skill> skills = [SELECT Id, DeveloperName, MasterLabel FROM Skill LIMIT :count];
        return skills;
    }

    public static ServiceTerritory createTestTerritory(String territoryName, String territoryType, Id parentTerritory, OperatingHours hours)
    {
        ServiceTerritory terr = new ServiceTerritory();
        terr.Name = territoryName;
        terr.Type__c = territoryType;
        terr.OperatingHoursId = hours.Id;
        terr.IsActive = true;
        if (parentTerritory != null) {
            terr.ParentTerritoryId = parentTerritory;
        }
        insert terr;
        return terr;
    }

    public static ServiceTerritory createTestGeography(String locCode, OperatingHours hours)
    {
        return createTestGeography(locCode, null, hours);
    }

    public static ServiceTerritory createTestGeography(String locCode, Id parentId, OperatingHours hours)
    {
        return createTestTerritory(locCode, 'Geography', parentId, hours);
    }

    public static ServiceTerritoryMember createTestTerritoryMember(ServiceResource tech, ServiceTerritory geo, String tType) {
        ServiceTerritoryMember geoTech1 = new ServiceTerritoryMember();
        geoTech1.ServiceResourceId = tech.Id;
        geoTech1.Location__c = geo.LocationCode__c; // 'TST10'
        geoTech1.ServiceTerritoryId = geo.Id;
        geoTech1.TerritoryType = tType;
        geoTech1.EffectiveStartDate = Date.today();
        insert geoTech1;
        return geoTech1;
    }

    public static ServiceResourceSkill createTestExpertise(ServiceResource tech, Schema.Skill skill)
    {
        ServiceResourceSkill expertise = new ServiceResourceSkill();
        //expertise.SVMXC__Service_Group__c = tech.SVMXC__Service_Group__c;
        expertise.ServiceResourceId = tech.Id;
        expertise.SkillId = skill.Id;
        expertise.EffectiveStartDate = Date.today().addDays(-1);
        expertise.Expertise_External_ID__c = expertise.ServiceResourceId + '-' + expertise.SkillId;
        insert expertise;
        return expertise;
    }

    public static FS_Experience__c createTestExperience(Id techId, Id skillId, Decimal fieldScore, Decimal trainingScore)
    {
        FS_Experience__c experience = new FS_Experience__c();
        experience.Technician__c = techId;
        experience.Related_Skill__c = skillId;
        experience.Field_Score__c = fieldScore;
        experience.Training_Score__c = trainingScore;
        experience.External_Key__c = techId + '-' + skillId;
        insert experience;
        return experience;
    }

    public static FS_TrainedSkill__c createTestTrainedSkill(Id skillId, Id trainingCourseId)
    {
        FS_TrainedSkill__c trainingCourse = new FS_TrainedSkill__c();
        trainingCourse.Skill__c = skillId;
        trainingCourse.Related_Training_Course__c = trainingCourseId;
        insert trainingCourse;
        return trainingCourse;
    }

    public static FS_TrainingCourse__c createTestTrainingCourse(String trainingCourseName, String activityTypes)
    {
        FS_TrainingCourse__c trainingCourse = new FS_TrainingCourse__c();

        // ITSVMX-761 2/9/2022 tony - Name was changed to an Auto-Number field so we use the new SMAX_PS_Course_Title__c field to store the Course Name
        // trainingCourse.Name = trainingCourseName;
        trainingCourse.Course_Title__c = trainingCourseName;
        trainingCourse.Activity_Type__c = activityTypes;
        insert trainingCourse;
        return trainingCourse;
    }

    public static FS_CompletedTraining__c createTestCompletedTraining(Id techId, Id trainingCourseId, Date completionDate)
    {
        FS_CompletedTraining__c completedTraining = new FS_CompletedTraining__c();
        completedTraining.Related_Technician__c = techId;
        completedTraining.Training_Course__c = trainingCourseId;
        completedTraining.Completion_Date__c = completionDate;
        insert completedTraining;
        return completedTraining;
    }

    /*public static SMAX_PS_Geography_Technician__c createTestGeoTech(SMAX_PS_Geography__c geo, SVMXC__Service_Group_Members__c tech, Integer rank)
    {
        SMAX_PS_Geography_Technician__c gt1 = new SMAX_PS_Geography_Technician__c();
        gt1.SMAX_PS_Geography__c = geo.Id;
        gt1.SMAX_PS_Technician__c = tech.Id;
        gt1.SMAX_PS_Location__c = geo.SMAX_PS_LocationCode__c;
        gt1.SMAX_PS_Rank__c = rank;
        insert gt1;
        return gt1;
    }*/

    public static Schema.Location createTestLocation(Account acct, String name, String extId, String locCode)
    {
        Schema.Location loc = new Schema.Location();
        loc.Name = name;
        loc.Account__c = acct.Id;
        loc.External_ID__c = extId;
        loc.LocationCode__c = locCode;
        //loc.ShipTo__c = acct.Id;
        //loc.Payer__c = acct.Id;
        //loc.BillTo__c = acct.Id;
        // 2023-09-14 Adding SalesOrg and Plant to help SOQL and logic
        loc.MaintenancePlant__c = 'TS12';
        loc.SalesOrg__c = 'TS10';
        insert loc;

        return loc;
    }
    
    // 02/07/2023 Added Owned By Company as this is now required for accepting the WO from the queue
    public static WorkOrder createWO(Asset ip, Contact c){
        Datetime startDate = System.now();
        WorkOrder wo = new WorkOrder();
        wo.Record_Type__c = 'Field Service';
        wo.AssetId = ip.Id;
        //wo.Perform_Auto_Entitlement__c = true;
        wo.Billing_Type__c = 'Billable';
        wo.Order_Type__c = 'Repair';
        wo.AccountId = ip.AccountId;
        wo.LocationId = ip.LocationId;
        wo.Scheduled_Date_Time__c = startDate.addMonths(1);
        wo.ContactId = c.Id;
        // 2023-09-14 Adding SalesOrg and Plant to help SOQL and logic
        wo.SAP_Maintenance_Plant__c = ip.MaintenancePlant__c;
       // wo.SalesOrg__c = ip.SMAX_PS_SalesOrg__c;
        insert wo;
        return wo;
    }

    //Create a Work Order for Auto Entitlement Testing
    public static WorkOrder createContractWO(Asset ip, Contact c){
        WorkOrder wo = new WorkOrder();
        wo.AssetId = ip.Id;
        wo.Perform_Auto_Entitlement__c = true;
        wo.Billing_Type__c = 'Contract';
        wo.Order_Type__c = 'Repair';
        wo.AccountId = ip.AccountId;
        wo.LocationId = ip.LocationId;
        //wo.Scheduled_Date__c = startDate.addMonths(1);
        wo.ContactId = c.Id;
        wo.Record_Type__c='Field Service';
        insert wo;
        return wo;
    }

   /* public static SVMXC__Service_Order__c createRemoteWO(SVMXC__Installed_Product__c ip, Contact c){
        Date startDate = System.today();
        RecordType recType = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Remote');
        SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
        wo.RecordTypeId = recType.Id;
        wo.SVMXC__Component__c = ip.id;
        wo.SVMXC__Perform_Auto_Entitlement__c = TRUE;
        wo.SVMXC__Order_Type__c = 'Phone';
        wo.SVMXC__Company__c = ip.SVMXC__Company__c;
        wo.SVMXC__Site__c = ip.SVMXC__Site__c;
        wo.SVMXC__Scheduled_Date__c = startDate;
        wo.SVMXC__Contact__c = c.Id;
        insert wo;
        return wo;
    }

    // 02/07/2023 Added Owned By Company as this is now required for accepting the WO from the queue
    public static SVMXC__Service_Order__c createInstallWO(Account acct, SVMXC__Site__c loc, Product2 prod, Contact c){

        return createInstallWO(acct, loc, prod, c, 'AES');
    }

    public static SVMXC__Service_Order__c createInstallWO(Account acct, SVMXC__Site__c loc, Product2 prod, Contact c, String ownedByCompany){
        Date startDate = System.today();
        SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
        wo.SVMXC__Perform_Auto_Entitlement__c = TRUE;
        wo.SVMXC__Billing_Type__c = 'Installation';
        wo.SVMXC__Order_Type__c = 'Installation';
        wo.SVMXC__Scheduled_Date__c = startDate.addMonths(1);
        wo.SVMXC__Company__c = acct.Id;
        wo.SVMXC__Site__c = loc.Id;
        wo.SVMXC__Product__c = (prod == null) ? null : prod.Id;
        wo.SVMXC__Contact__c = c.Id;
        wo.SMAX_PS_Owned_By_Company__c = ownedByCompany;
        insert wo;
        return wo;
    }

    // 02/07/2023 Added Owned By Company as this is now required for accepting the WO from the queue
    public static SVMXC__Service_Order__c createServiceEstimateWO(SVMXC__Installed_Product__c ip, Contact c){

        return createServiceEstimateWO(ip, c, 'AES');
    }

    public static SVMXC__Service_Order__c createServiceEstimateWO(SVMXC__Installed_Product__c ip, Contact c, String ownedByCompany){
        RecordType recType = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order__c', 'Service_Request');
        Date startDate = System.today();
        SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
        wo.RecordTypeId = recType.Id;
        wo.SVMXC__Component__c = ip.id;
        wo.SVMXC__Perform_Auto_Entitlement__c = FALSE;
        wo.SVMXC__Billing_Type__c = 'Billable';
        wo.SVMXC__Order_Type__c = 'Repair';
        wo.SVMXC__Order_Status__c = 'Open'; // ITSVMX-35 Added this to be true to SFM mappings
        wo.SVMXC__Company__c = ip.SVMXC__Company__c;
        wo.SVMXC__Site__c = ip.SVMXC__Site__c;
        wo.SVMXC__Scheduled_Date__c = startDate.addMonths(1);
        wo.SVMXC__Contact__c = c.Id;
        wo.SMAX_PS_Perform_Auto_Assignment__c = FALSE;
        wo.SMAX_PS_Owned_By_Company__c = ownedByCompany;
        insert wo;
        return wo;
    }
*/
    public static WorkOrderLineItem createWorkDetailUsage(WorkOrder wo, String lineType, Product2 prod)
    {
        WorkOrderLineItem wd = new WorkOrderLineItem(
                WorkOrderId=wo.Id,
                Record_Type__c='Usage',
                Line_Type__c = lineType,
                Part__c = prod.Id,
                Status='Open',
                Quantity__c = 1);
        insert wd;
        return wd;
    }
/*
    public static SVMXC__Service_Order_Line__c createWorkDetailUsage_NoInsert(SVMXC__Service_Order__c wo, String lineType, Product2 prod)
    {
        Id usageRecTypeId = SMAX_PS_Utility.getRecordType('SVMXC__Service_Order_Line__c', 'UsageConsumption').Id;
        SVMXC__Service_Order_Line__c wd = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id,
                RecordTypeId=usageRecTypeId,
                SVMXC__Line_Type__c = lineType,
                SVMXC__Product__c = prod.Id,
                SVMXC__Line_Status__c='Open',
                SVMXC__Actual_Quantity2__c = 1);
        return wd;
    }

    // 10/22/21 Tony - Added to allow creation of Work Detail Lines of different record types
    public static SVMXC__Service_Order_Line__c createWorkDetail(SVMXC__Service_Order__c wo, String lineType, Product2 prod, Id recordTypeId)
    {
        SVMXC__Service_Order_Line__c wd = new SVMXC__Service_Order_Line__c(
                SVMXC__Service_Order__c=wo.Id,
                RecordTypeId= recordTypeId,
                SVMXC__Line_Type__c = lineType,
                SVMXC__Product__c = prod.Id,
                SVMXC__Line_Status__c='Open',
                SVMXC__Actual_Quantity2__c = 1);
        insert wd;
        return wd;
    }*/

    public static Product2 createTestProduct(String name, String productCode, String productLine)
    {
        return createTestProduct(name, productCode, productLine, 'Service Parts');
    }

    public static Product2 createTestProduct(String name, String productCode, String productLine, String prodType)
    {
        return createTestProduct(name, productCode, productLine, prodType, null, null);
    }

    public static Product2 createTestProduct(String name, String productCode, String productLine, String prodType, String uom, String uomCode)
    {
        Product2 p = new Product2();
        p.Name = name;
        p.ProductCode = productCode;
        p.Part_Number__c = productCode;
        p.Product_Line__c = productLine;
        p.Product_Type__c = prodType;
        p.QuantityUnitOfMeasure = uom;
        p.Unit_of_Measure_Code__c = uomCode;
        insert p;
        return p;
    }

   public static ProductItem createTestProductStock(Schema.Location loc, Product2 prod, String status, Integer qty)
    {
        ProductItem ps = new ProductItem();
        ps.LocationId = loc.Id;
        ps.Product2Id = prod.Id;
        //ps.Status__c = status;
        ps.QuantityOnHand = qty;
        ps.External_Id__c = loc.External_ID__c + '-' + prod.Partnum__c;
        insert ps;
        return ps;
    }

    public static ProductItem createTestSerializedProductStock(Schema.Location loc, Product2 prod, Integer qty, String trackingType, String serialNum)
    {
        ProductItem ps = new ProductItem();
        ps.LocationId = loc.Id;
        ps.Product2Id = prod.Id;
        //ps.Status__c = status;
        ps.QuantityOnHand = qty;
        ps.External_Id__c = loc.External_ID__c + '-' + prod.Partnum__c + '-' + serialNum;
        ps.Serial_Tracking_Type__c = trackingType;
        ps.SerialNumber = serialNum;
        insert ps;
        return ps;
    }

    public static OperatingHours createDefaultOperatingHours() {
        OperatingHours oh = new OperatingHours();
        oh.Name = 'DEFAULT';
        insert oh;
        return oh;
    }

    //Create an Installed Product
    public static Asset createIP(String serialNO){
        Asset ip = new Asset();
        ip.SerialNumber = serialNO;
        insert ip;
        return ip;
    }

    public static Asset createIP(String serialNO, Account acct, Schema.Location loc, String modelSeries)
    {
        return createIP(serialNO, acct, loc, modelSeries, null);
    }

    public static Asset createIP(String serialNO, Account acct, Schema.Location loc, String modelSeries, Product2 prodct)
    {
        Asset ip = new Asset();
        ip.AccountId = acct.Id;
        ip.LocationId = loc.Id;
        ip.SerialNumber = serialNO;
        //ip.SMAX_PS_ModelSeries__c = modelSeries;
        if (prodct != null) {
            ip.Product2Id = prodct.Id;
        }
        // 02/07/2023 Added Owned By Company as this is now required for accepting the WO from the queue
        //ip.SMAX_PS_Owned_By_Company__c = 'AES';
        // 2023-09-14 Adding SalesOrg and Plant to help SOQL and logic
        ip.MaintenancePlant__c = loc.MaintenancePlant__c;
        ip.SalesOrg__c = loc.SalesOrg__c;
        ip.Name=serialNO;
        insert ip;
        return ip;
    }
    
    //Create a Service Contract
    public static ServiceContract createSvcMaintContract(String svcName, Id acctId, Date startDate, Date endDate){
        ServiceContract sc = new ServiceContract ();
        sc.Name = svcName;
        sc.AccountId= acctId;
        sc.StartDate= startDate;
        sc.EndDate= endDate;
        sc.Active__c = true;
        sc.SalesOrg__c = 'US10';
        insert sc;
        return sc;
    }

    //Create a Service Contract
    public static ServiceContract createContractItem(ServiceContract contract, String svcName, Date startDate, Date endDate, Product2 material){
        ServiceContract sc = new ServiceContract();
        sc.Name = svcName;
        sc.ParentServiceContractId= contract.Id;
        sc.AccountId = contract.AccountId;
        sc.StartDate= startDate;
        sc.EndDate= endDate;
        sc.Active__c = true;
        sc.Contract_Material__c = material.Id;
        sc.SalesOrg__c = contract.SalesOrg__c;
        insert sc;
        return sc;
    }

  /*  //Create an SLA
    public static SVMXC__Service_Level__c createSLATerms(String slaName ){
        SVMXC__Service_Level__c sla = new SVMXC__Service_Level__c();
        sla.Name = slaName;
        sla.SVMXC__Onsite_Response_Tracked_On__c = 'Workorder';
        sla.SVMXC__Resolution_Tracked_On__c = 'Workorder';
        sla.SVMXC__Restoration_Tracked_On__c = 'Workorder';
        //Business Hours
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault=true];
        sla.SVMXC__Business_Hours__c = bh.id;
        insert sla;
        return sla;
    }*/

    //Create a Covered Product
    public static ContractLineItem createCoveredIP(ServiceContract sc, Date startDate, Date endDate, Asset ip){
        ContractLineItem cp = new ContractLineItem();
        cp.ServiceContractId = sc.Id;
        cp.Parent_Contract__c = sc.ParentServiceContractId;
        cp.StartDate = startDate;
        cp.EndDate = endDate;
        cp.AssetId = ip.Id;
        cp.Quantity = 1;
        cp.UnitPrice = 0;

        insert cp;
        return cp;

    }

    //Create an Entitlement Date
    public static FS_EntitlementDate__c createEntitlementDate(ContractLineItem cp, Entitlement ent, Date plannedDate){
        FS_EntitlementDate__c ed = new FS_EntitlementDate__c();
        ed.CoveredProduct__c = cp.Id;
        ed.Entitlement__c = ent.Id;
        ed.PlannedDate__c = plannedDate;
        ed.ContractItem__c = cp.ServiceContractId;
        insert ed;
        return ed;
    }

    //Create an Available Service
   /* public static  SVMXC__Service__c createAvailableService(String strName){
        SVMXC__Service__c availService = new SVMXC__Service__c();
        //SVMXC__ServiceMax_Processes__c sp = [SELECT ID from SVMXC__ServiceMax_Processes__c where SVMXC__Name__c = 'SVMXSTD: Generic Type Work Order'];
        availService.SVMXC__Data_Type__c = 'Text';
        availService.SVMXC__Qualifying_Criteria__c = 'a65g0000000976SAAQ';
        availService.Name = strName;
        insert availService;
        return availService;
    }*/

    //Included Services - called Entitlements
    public static Entitlement createEntitlement(ServiceContract sc, String entType, Integer entitledQty, Integer remainingQty){
        Entitlement ent = new Entitlement();
        ent.ServiceContractId = sc.Id;
        ent.EntitlementType__c = entType;
        ent.Name = sc.Name + '-' + entType;
        ent.EntitledQty__c = entitledQty;
        ent.EntitledQtyRemaining__c = remainingQty;
        ent.Labor_Discount_Covered__c = 100;
        ent.Parts_Discount_Covered__c = 50;
        ent.Travel_Discount_Covered__c = 100;
        ent.ConsumableDiscountCovered__c = 75;
        ent.ServicePartsDiscountCovered__c = 25;
        insert ent;
        return ent;
    }

    //Create an HSI Custom Setting
    public static C_SET_6910_HSI__c createHSICustomSetting(String strCountryCode, String strProductLine){
        System.debug('Loading the SMAX_PS_HSI_Settings__c');
        C_SET_6910_HSI__c hsicstm = new C_SET_6910_HSI__c();
        hsicstm.Name = strCountryCode + ' - '+ strProductLine;
        hsicstm.Active__c = true;
        hsicstm.Country_Code__c = strCountryCode;
        hsicstm.Product_Line__c = strProductLine;
        insert hsicstm;
        return hsicstm;
    }

    public static ProductRequest createTestProductRequest(Account acct, Contact c, Schema.Location loc, ServiceResource tech, WorkOrder wo, String extId, String relatedExtId)
    {
        ProductRequest po = new ProductRequest();
        po.Status = 'Open';
        po.Expected_Delivery_Date__c = Date.today();
        if (acct != null)
        {
            po.AccountId = acct.Id;
        }
        po.Contact_Name__c = c.Name;
        if (loc != null)
        {
            po.DestinationLocationId = loc.Id;
        }
        if (tech != null)
        {
            po.ServiceResource__c = tech.Id;
        }
        if (wo != null)
        {
            po.WorkOrderId = wo.Id;
        }
        po.RelatedExternalId__c = relatedExtId;
        po.ExternalId__c = extId;
        insert po;
        return po;
    }

    /*
    public static SVMXC__RMA_Shipment_Order__c createTestPartsOrder(RecordType recType, Account acct, Contact c, SVMXC__Site__c loc, SVMXC__Service_Group_Members__c tech, SVMXC__Service_Order__c wo, String extId, String relatedExtId)
    {

        return createTestPartsOrder(recType.Id, acct, c, loc, tech, wo, extId, relatedExtId);
//        SVMXC__RMA_Shipment_Order__c po = new SVMXC__RMA_Shipment_Order__c(RecordTypeId=recType.Id);
//        po.SVMXC__Order_Status__c = 'Open';
//        po.SVMXC__Expected_Receive_Date__c = Date.today();
//        if (acct != null)
//        {
//            po.SVMXC__Company__c = acct.Id;
//        }
//        po.SVMXC__Contact__c = c.Id;
//        if (loc != null)
//        {
//            po.SVMXC__Destination_Location__c = loc.Id;
//        }
//        if (tech != null)
//        {
//            po.SMAX_PS_Technician__c = tech.Id;
//        }
//        if (wo != null)
//        {
//            po.SVMXC__Service_Order__c = wo.Id;
//        }
//        po.SMAX_PS_RelatedExternalId__c = relatedExtId;
//        po.SMAX_PS_ExternalId__c = extId;
//        insert po;
//        return po;
    }

    // 5/21/21 Created for use by ITSVMX-461 Trigger to cancel RMA when Depot Repair Work Order is Canceled
    public static SVMXC__RMA_Shipment_Line__c createTestPartsOrderLine(RecordType recType, SVMXC__Site__c destinationLoc, SVMXC__Service_Order__c wo, SVMXC__RMA_Shipment_Order__c partsOrder, String extId)
    {
        SVMXC__RMA_Shipment_Line__c pol = new SVMXC__RMA_Shipment_Line__c(RecordTypeId=recType.Id);
        pol.SVMXC__Line_Status__c = 'Open';
        pol.SVMXC__Expected_Receipt_Date__c = Date.today();
        if (destinationLoc != null)
        {
            pol.SVMXC__Ship_Location__c = destinationLoc.Id;
        }
        if (wo != null)
        {
            pol.SVMXC__Service_Order__c = wo.Id;
        }
        if (partsOrder != null) {
            pol.SVMXC__RMA_Shipment_Order__c = partsOrder.Id;
        }
        pol.SMAX_PS_ExternalId__c = extId;
        insert pol;
        return pol;
    }
*/
    public static FS_FaultCode__c createTestFaultCode(String family, String groupVal, String code, String codeDesc, Boolean complaintReq)
    {
        FS_FaultCodeGroup__c fcg = new FS_FaultCodeGroup__c();
        fcg.Code_Family__c = family;
        fcg.Code_Group__c = groupVal;
        fcg.Code_Group_Type__c = 'Fault Code';
        fcg.Name = groupVal;
        insert fcg;

        FS_FaultCode__c fc = new FS_FaultCode__c();
        fc.Fault_Code_Group__c = fcg.Id;
        fc.Code_Family__c = family;
        fc.Code_Group__c = groupVal;
        fc.Code__c = code;
        fc.Code_Description__c = codeDesc;
        fc.Complaint_Required__c = (complaintReq ? 1 : 0);
        fc.Name = code;
        insert fc;

        return fc;
    }

    // 10/19/2022 ITSVMX-1029 Polaris Translation / Output Documents
    public static FS_Translation__c createTestTranslation(String name, String countryCode)
    {
        FS_Translation__c t = new FS_Translation__c();
        t.Name = name;
        t.Country__c = countryCode;
        t.Logo_Image__c = 'LOGO_AES';
        insert t;

        return t;
    }

    public static ServiceReport createTestServiceReport(Id woId, String template, String title) {
        ServiceReport rpt = new ServiceReport();
        rpt.ParentId = woId;
        rpt.DocumentTemplate = template;
        rpt.DocumentBody = Blob.valueOf(generateRandomString(255));
        rpt.DocumentName = template;
        rpt.DocumentContentType ='application/pdf';
//        ContentVersion file = generateFile(woId, title, title + '.pdf');
//        rpt.ContentVersionDocumentId = file.Id;
        insert rpt;
        return rpt;
    }

    // Salesforce Files
//    @TestVisible
//    private static ContentVersion generateFile(Id linkedEntityId, String title, String fileName) {
//        // Setup the ContentVersion record
//        ContentVersion contentVer = new ContentVersion(
//                Title = title,
//                PathOnClient = fileName,
//                ContentLocation = 'S'
//        );
//        contentVer.VersionData = Blob.valueOf(generateRandomString(255));
//        insert contentVer;
//
//        // Get the ContentDocumentId. Oddly, contentVer is not updated with this upon insert
//        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:contentVer.Id].ContentDocumentId;
//
//        ContentDocumentLink contentDocLink = new ContentDocumentLink (
//                LinkedEntityId = linkedEntityId,
//                ContentDocumentId = contentDocId
//        );
//        insert contentDocLink;
//
//        return contentVer;
//    }

    private static Set<String> priorRandoms;
    private static String generateRandomString(Integer length){
        if (priorRandoms == null) {
            priorRandoms = new Set<String>();
        }

        if (length == null) {
            length = 1+Math.round( Math.random() * 8 );
        }
        String characters = 'abcdefghijklmnopqrstuvwxyz1234567890';
        String returnString = '';
        while(returnString.length() < length){
            Integer charpos = Math.round( Math.random() * (characters.length()-1) );
            returnString += characters.substring( charpos , charpos+1 );
        }
        if(priorRandoms.contains(returnString)) {
            return generateRandomString(length);
        } else {
            priorRandoms.add(returnString);
            return returnString;
        }
    }

}