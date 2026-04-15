@IsTest(SeeAllData=false)
public class FS_Product_UT
{
    @IsTest
    static void createProductTestData()
    {
        // Insert Product
        Product2 prod = new Product2(Name='Test Product', Description='Test Product Description this is a really long one to make sure we test the truncation logic when the description is too long and to make sure this is a really long one we will keep repeating ourselves repeating ourselves repeating ourselves repeating ourselves repeating ourselves repeating ourselves', 
            Partnum__c='TESTT00100101', Product_Type__c='Service Parts', Activity_Type__c='ACT001');
        Product2 part = new Product2(Name='Test Part', Description='Test Part Description',
                Partnum__c='TESTP00100101', Product_Type__c='Consumable');
        Product2 returnPart = new Product2(Name='Test Return Part', Description='Test Return Part Description',
                Partnum__c='TESTP00100101C', Product_Type__c='Consumable');
        insert new List<Product2> { prod, part, returnPart };

        // Insert Product Revision
        //SMAX_PS_ProductRevision__c prodRev = new SMAX_PS_ProductRevision__c(SMAX_PS_Product__c=prod.Id);
        //insert prodRev;

        // Insert Product Classification
        Product_Classification__c prodCls = new Product_Classification__c(
            Product__c=prod.Id,
            Characteristic__c = 'PE_MEDICAL_DEVICE',
            Value__c = 'Y');
        insert prodCls;

        // Insert Product Sales
        Product_Sales__c prodSales = new Product_Sales__c(
            Product__c=prod.Id);
        insert prodSales;
        prodSales.Sales_Org__c = 'US10';
        update prodSales;

        // Insert Product Plant
        FS_ProductPlant__c prodPlant = new FS_ProductPlant__c(
            Product__c=prod.Id, Plant__c = 'TS12');
        FS_ProductPlant__c partPlant = new FS_ProductPlant__c(
                Product__c=part.Id, Plant__c = 'TS12', Return_Part_Number__c = returnPart.Partnum__c);
        insert new List<FS_ProductPlant__c> { prodPlant, partPlant };

        // ITSFDC-350 Adding Contract Discount Exception (CDE)
        FS_Contract_Discount_Exception__c cde1 = new FS_Contract_Discount_Exception__c(Parts_Product__c = prod.Id,
            Last_Txn_Number__c = 'Joe', Discount_Type__c = 'Service Parts', SAP_Activity_Type__c = 'PM',
            Sales_Org__c = 'US11', External_ID__c = prod.Partnum__c+'-US11-PM-*');
        FS_Contract_Discount_Exception__c cde2 = new FS_Contract_Discount_Exception__c(Parts_Product__c = prod.Id,
                Last_Txn_Number__c = 'ABC', Discount_Type__c = 'Service Parts', SAP_Activity_Type__c = 'REP',
                Sales_Org__c = 'US11', External_ID__c = prod.Partnum__c+'-US11-REP-*');
        insert new List<FS_Contract_Discount_Exception__c> { cde1, cde2 };

        // ITSFDC-507 Adding Extended Warranty Parts (EWP)
        FS_ExtendedWarrantyPart__c ewp1 = new FS_ExtendedWarrantyPart__c(Equipment_Product__c = prod.Id,
            Last_Txn_Number__c = 'Joe', Sales_Org__c = 'US11', External_Key__c = prod.Partnum__c+'-US11-'+part.Partnum__c,
            Covered_Part__c = part.Id, Extended_Months__c = 9);
        FS_ExtendedWarrantyPart__c ewp2 = new FS_ExtendedWarrantyPart__c(Equipment_Product__c = prod.Id,
                Last_Txn_Number__c = 'ABC', Sales_Org__c = null, External_Key__c = prod.Partnum__c+'-*-'+part.Partnum__c,
                Covered_Part__c = part.Id, Extended_Months__c = 15);
        insert new List<FS_ExtendedWarrantyPart__c> { ewp1, ewp2 };

        prod.CompletedTxnNum__c='ABC';
        update prod;

        //Product2 updated = [SELECT Id, Name, ProductCode, Medical_Classification__c FROM Product2 WHERE Id = :prod.Id];
        //System.assertEquals('Y', updated.Medical_Classification__c);

        //Product_Sales__c prodSalesResult = [SELECT Id, Name, Part_Description__c, Part_Number__c, Product_Type__c, SAP_Activity_Type__c FROM Product_Sales__c WHERE Id = :prodSales.Id];
        //System.assertNotEquals(null, prodSalesResult.SMAX_PS_PartDescription__c);
        //System.assertEquals(prod.Partnum__c, prodSalesResult.SMAX_PS_PartNumber__c);
        //System.assertEquals(prod.SVMXC__Product_Type__c, prodSalesResult.SMAX_PS_ProductType__c);
        //System.assertEquals(prod.SMAX_PS_ActivityType__c, prodSalesResult.SMAX_PS_SAP_ActivityType__c);

       // FS_ProductPlant__c partPlantResult = [SELECT Id, Name, Return_Part__c FROM FS_ProductPlant__c WHERE Id = :partPlant.Id];
        //System.assertEquals(returnPart.Id, partPlantResult.BD_Return_Part__c);

        //List<FS_Contract_Discount_Exception__c> cdeResults = [SELECT Id, Name FROM FS_Contract_Discount_Exception__c WHERE Parts_Product__c = :prod.Id];
        //System.assertEquals(1, cdeResults.size());

        //List<FS_ExtendedWarrantyPart__c> ewpResults = [SELECT Id, Name, External_Key__c FROM FS_ExtendedWarrantyPart__c WHERE Equipment_Product__c = :prod.Id AND Is_Deleted__c = FALSE];
        //System.assertEquals(1, ewpResults.size());

        delete prod;
    }

    /*// 2022/07/13 Tony ITSVMX-562 Modify the replenishment parts ordering process
    @IsTest
    static void testProcessProductPlantForRefurbishedParts() {

        Account acct = FS_TestDataFactory.createTestAccount('Test Acct', 'TST1001001');

        // Create an Active Service Contract
        Date startDate = System.today() - 30;
        Date endDate = System.today() + 30;
        Servicecontract serviceContract = SMS_TestDataFactory.createSvcMaintContract('TestSvcContract', acct.Id, startDate, endDate);
        Servicecontract serviceContractItem = SMAX_PS_TestDataFactory.createContractItem(serviceContract, 'TestSvcContractItem', startDate, endDate);

        // Create Service Contract Services with Service Parts Discount Covered = 100.00
        SVMXC__Service_Contract_Services__c serviceContractServices = SMAX_PS_TestDataFactory.createEntitlement(serviceContractItem, 'Parts', 10, 10);
        serviceContractServices.SMAX_PS_ServicePartsDiscountCovered__c = 100.00;
        update serviceContractServices;
        System.debug('serviceContractServices: ' + serviceContractServices);

        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct, 'Test Loc', 'TLOC0010101', 'TST001');
        Product2 product1 = SMAX_PS_TestDataFactory.createTestProduct('Test Product', 'TPRD1001', 'Test');
        Product2 product2 = SMAX_PS_TestDataFactory.createTestProduct('Test Refurb Product', 'Refurb123', 'Test');

        // Create an Installed Product with Medical Device = FALSE
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TST00101', product1);
        ip.SMAX_PS_MaintenancePlant__c = 'P123';
        update ip;
        System.debug('ip.SMAX_PS_IsMedicalDevice__c: ' + ip.SMAX_PS_IsMedicalDevice__c);

        // Create Product Plant
        SMAX_PS_ProductPlant__c productPlant = new SMAX_PS_ProductPlant__c();
        productPlant.SMAX_PS_Product__c = product1.Id;
        productPlant.SMAX_PS_Plant__c = 'P123';
//      productPlant.BD_Refurbished_Part__c = product2.Id;  // This should be set by the code in SMAX_PS_ProductManager.processProductPlant()
        productPlant.BD_Refurbished_Part_Number__c = 'Refurb123';
        insert productPlant;
        productPlant.SMAX_PS_PlannedDeliveryTimeInDays__c = '3';
        update productPlant;

        List<SMAX_PS_ProductPlant__c> testProductPlants = [SELECT Id, BD_Refurbished_Part_Number__c, BD_Refurbished_Part__c FROM SMAX_PS_ProductPlant__c WHERE BD_Refurbished_Part__c = :product2.Id];
        System.debug('testProductPlants: ' + testProductPlants.size() + ' ' + testProductPlants);
        System.assertEquals(1, testProductPlants.size(), 'There should be 1 record that has the correct Refurbished Part associated to it.');

    }*/
}