/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*
* 2. Description - This class is a test class
*
*
* 3. Objects referenced
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
*
* 5. Dependant Class(es):
*
*
*
* 6. Test Class Name:
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*  - Abhishek Joshi 2025.10.08 - Created the test class - RWPS-4437
*  - Abhishek Joshi 2025.10.29 - Updated testGetCustomersAlsoBought method - RWPS-5046
*  - Abhishek Joshi 2025.12.08 - Updated testGetCustomersAlsoBought method - RWPS-5223

*************************************************************/

@isTest(SeeAllData=false)
public without sharing class ECOM_ProductRecommendationsCtrler_Test {
    /**
    * @description //To setup test Data
    * @author Abhishek Joshi | 2025.10.06
    **/
    @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
    }

    /**
    * @description //To test product recommendation retrieval
    * @author Abhishek Joshi | 2025.10.06
    **/
    @isTest
    public static void testGetCustomersAlsoBought() {
        Network comm = [SELECT Id, name FROM Network ORDER BY CREATEDDATE DESC limit 1];
        String communityId = (String)comm.Id;

        User u = [SELECT Id, LastName, AccountId, Contact.ECOM_CountryProvided__c FROM User WHERE Username='testR1@test.org' LIMIT 1];

        Product2 product1 = ECOM_TestUtil.createProduct('Test1', 'Test1', 'Test1', true);
        Product2 product2 = ECOM_TestUtil.createProduct('Test2', 'Test2', 'Test2', true);
        Product2 product3 = ECOM_TestUtil.createProduct('Test3', 'Test3', 'Test3', true);

        Product_Sales__c product1Sales = ECOM_TestUtil.createProduct_Sales(String.valueOf(product1.Id));
        Product_Sales__c product2Sales = ECOM_TestUtil.createProduct_Sales(String.valueOf(product2.Id));
        Product_Sales__c product3Sales = ECOM_TestUtil.createProduct_Sales(String.valueOf(product3.Id));

        insert new List<Product_Sales__c>{product1Sales,product2Sales,product3Sales};

        product1Sales.Distribution_ChainSpecificMaterialStatus__c = 'ZW';
        product1Sales.Sales_Org__c = 'US10';
        product2Sales.Distribution_ChainSpecificMaterialStatus__c = 'ZW';
        product2Sales.Sales_Org__c = 'US10';
        product3Sales.Distribution_ChainSpecificMaterialStatus__c = 'ZW';
        product3Sales.Sales_Org__c = 'US10';

        update new List<Product_Sales__c>{product1Sales,product2Sales,product3Sales};

        List<Pricebook2> pricebookList = [SELECT Id FROM Pricebook2 WHERE IsActive = true LIMIT 1];
        List<Network> networkList = [SELECT Id, name FROM Network LIMIT 1];
        Id catalogId = ECOM_ProductUtil.getCatalogueId(networkList[0].Id);
        List<ProductCategory> productCategoryList = [SELECT Id, Name FROM ProductCategory WHERE CatalogId = :catalogId];

        List<Product2> productUpdateList = new List<Product2>{product1,product2,product3};

        if (productCategoryList.isEmpty() == false && pricebookList.isEmpty() == false) {
            List<ProductCategoryProduct> categoryProductList = new List<ProductCategoryProduct>();
            List<PriceBookEntry> pricebookEntryList = new List<PriceBookEntry>();
            for (Product2 product : productUpdateList) {
                categoryProductList.add(new ProductCategoryProduct(ProductId = product.Id, ProductCategoryId = productCategoryList[0].Id));
                pricebookEntryList.add(new PriceBookEntry(Product2Id = product.Id, Pricebook2Id = pricebookList[0].Id, UnitPrice = 100, IsActive = true, CurrencyIsoCode = 'USD'));
            }
            insert pricebookEntryList;
            insert categoryProductList;
        }

        product1.Product_Model_Identifier__c = 'pm1';
        update product1;

        Product_Recommendation__c r1 = new Product_Recommendation__c();
        r1.Active__c = false;
        r1.ExternalId__c = 'testext';
        r1.Product_Main__c = product2.Id;
        r1.Product_Suggested__c = product1.Id;
        r1.Suggest_Type__c = 'Companion';
        r1.Use_Case_Type__c = 'Web';
        insert r1;

        Datetime pastDate = Datetime.now().addDays(-10);
        Test.setCreatedDate(r1.Id, pastDate);

        System.runAs(u) {
            Test.startTest();

            SAP_Order_Summary__c sapOrder = new SAP_Order_Summary__c();
            sapOrder.Sold_To_Customer_Id__c = 't1';
            sapOrder.Bill_To_Customer_Id__c = 't1'; // RWPS-5223
            sapOrder.Name = '1234567890';
            sapOrder.Sold_To_Address_Country__c = 'US';
            sapOrder.Source_Type__c = 'ZWEB';
            sapOrder.Contact_Email__c = 'a@a.a';
            sapOrder.ShipTo_Email__c = 'a@a.a';

            insert sapOrder;

            SAP_Order_Items__c sapOrderItem1 = new SAP_Order_Items__c();
            sapOrderItem1.PKI_Order_Summary__c = sapOrder.Id;
            sapOrderItem1.Material_Number__c = product1.Part_Number__c;

            SAP_Order_Items__c sapOrderItem2 = new SAP_Order_Items__c();
            sapOrderItem2.PKI_Order_Summary__c = sapOrder.Id;
            sapOrderItem2.Material_Number__c = product2.Part_Number__c;

            SAP_Order_Items__c sapOrderItem3 = new SAP_Order_Items__c();
            sapOrderItem3.PKI_Order_Summary__c = sapOrder.Id;
            sapOrderItem3.Material_Number__c = product3.Part_Number__c;

            insert new List<SAP_Order_Items__c>{sapOrderItem1, sapOrderItem2, sapOrderItem3};

            Map<String, Object> recommendedProducts1 = ECOM_ProductRecommendationsController.getCustomersAlsoBought(new List<String>{product1.Id}, communityId, new Map<String, Object>());
            Map<String, Object> recommendedProducts2 = ECOM_ProductRecommendationsController.getCustomersAlsoBought(new List<String>{product1.Id,product2.Id}, communityId, new Map<String, Object>());

            ECOM_ProductRecommendationsController.ECOM_ProductRecommendationsReqWrapper req = new ECOM_ProductRecommendationsController.ECOM_ProductRecommendationsReqWrapper();
            req.productIds = new List<String>{product1.Id};
            req.userId = u.Id;
            List<ECOM_ProductRecommendationsController.ECOM_ProductRecommendationsReqWrapper> reqList = new List<ECOM_ProductRecommendationsController.ECOM_ProductRecommendationsReqWrapper>{req};
            List<ECOM_ProductRecommendationsController.ECOM_ProductRecommendationsResWrapper> resList = ECOM_ProductRecommendationsController.getRecommendationsInvocable(reqList);

            req.userId = null;
            req.salesOrg = 'US10';
            reqList = new List<ECOM_ProductRecommendationsController.ECOM_ProductRecommendationsReqWrapper>{req};
            resList = ECOM_ProductRecommendationsController.getRecommendationsInvocable(reqList);

            req.salesOrg = null;
            reqList = new List<ECOM_ProductRecommendationsController.ECOM_ProductRecommendationsReqWrapper>{req};
            resList = ECOM_ProductRecommendationsController.getRecommendationsInvocable(reqList);

            Test.stopTest();

            Map<String, Object> recommendedProducts3 = ECOM_ProductRecommendationsController.getCustomersAlsoBought(new List<String>{product1.Id}, communityId, new Map<String, Object>());
        }

        List<Product_Recommendation__c> recs = [SELECT Id, Active__c FROM Product_Recommendation__c];
        for(Product_Recommendation__c r: recs) {
            r.Active__c = false;
        }
        update recs;
        Assert.areEqual(true, recs.size()>0);

        Map<String, Object> recommendedProducts4 = ECOM_ProductRecommendationsController.getCustomersAlsoBought(new List<String>{product1.Id}, communityId, new Map<String, Object>{'salesOrg' => 'US10'});
    }
}