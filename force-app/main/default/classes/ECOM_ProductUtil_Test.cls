/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*
* 2. Description - This class is a test class
*
*
* 3. Objects referenced
*    -Product2
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
*
* 5. Dependant Class(es):
*   - ECOM_ProductUtil
*
*
*
* 6. Test Class Name:
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*  - Prabhat Kumar 2025.28.03 - Created method testgetRecentlyPurchasedProductsIncludeQuery, testgetRecentlyPurchasedProducts - RWPS-2855
*  - Manish Joshi 2025.17.04 - Updated test methods for code coverage - RWPS-3023
*  - Abhishek Joshi 2025.07.15 - Created method testgetSellableProductsForGuest - RWPS-3697
*  - Sachin Vispute 2025.10.08 - Created method testGetReplacementMap, testGetProudctSalesByProductIds - RWPS-3772

*************************************************************/
@isTest
public with sharing class ECOM_ProductUtil_Test {

    @TestSetup
    public static void testData(){
        ECOM_TestUtil.initialStorefrontSetupForNonPunchout(); //RWPS-3772
    }

    /**
    * @description Test class to verify the recently purchased Products.
    * @author Prabhat Kumar
    * @date 01-04-2025
    */
    @isTest
    static void testgetRecentlyPurchasedProducts(){

        Network comm = [SELECT id, name FROM Network ORDER BY CREATEDDATE DESC limit 1];
        String communityId = (String)comm.Id;
        User u = [Select Id,LastName, ContactId, AccountId From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Product2 testProduct = ECOM_TestUtil.createProduct('TestProduct12','1','TP143',True);
        Product_Sales__c productSales = ECOM_TestUtil.createProduct_Sales(testProduct.Id);
        ERP_Address__c master = ECOM_TestUtil.createNewPunchoutMasterAddressConfiguration();
        master.ECOM_Punchout_Products_Exclude_Query__c = 'SHOW PRODUCT Where RadioActive != true AND PartNumber not in (\'1234567\')';
        master.ECOM_Punchout_Products_Include_Query__c='';
        update master;
        Account acc = [SELECT Id FROM Account where Id =:u.AccountId LIMIT 1];
        ECOM_TestUtil.createRelatedAddresses(acc,master);
        List<String> partNumberQuantityList = new List<String>{'PART123', 'PART456'};
        List<String> result;
        System.runAs(u){
            ECOM_ProductService.getRecentlyPurchasedProducts(communityId,u.Id);// RWPS-3023
        }


    }


    /**
    * RWPS-3772
    * @description Test method to verify the methid 'getProudctSalesByProductIds'
    * @author Sachin Vispute
    * @date 09-10-2025
    */
    @isTest
    static void testGetProudctSalesByProductIds() {

        Product2 sellableProduct = ECOM_TestUtil.createProduct('Test Sellable Product', 'TEST-0000', 'TEST-PC-0000', true);
        Product2 sellableAlternativeProduct = ECOM_TestUtil.createProduct('Test Sellable Alternate Product', 'TEST-0001', 'TEST-PC-0001', true);
        Product2 discontinuedProduct = ECOM_TestUtil.createProduct('Test Discontinued Product', 'TEST-0002', 'TEST-PC-0002', true);
        Product2 nonSellableProduct = ECOM_TestUtil.createProduct('Test NonSellableProduct Product', 'TEST-0003', 'TEST-PC-0003', true);
        Product2 discontinuedDirectReplacementProduct = ECOM_TestUtil.createProduct('Test DirectReplacementProduct Product', 'TEST-0004', 'TEST-PC-0004', true);
        Product2 discontinuedDirectReplacementDisabledProduct = ECOM_TestUtil.createProduct('Test DirectReplacementProduct Product', 'TEST-0005', 'TEST-PC-0005', true);
        Product2 discontinuedIndirectReplacementProduct = ECOM_TestUtil.createProduct('Test IndirectReplacementProduct Product', 'TEST-0006', 'TEST-PC-0006', true);
        Product2 discontinuedIndirectReplacementDisabledProduct = ECOM_TestUtil.createProduct('Test IndirectReplacementProduct Product', 'TEST-0007', 'TEST-PC-0007', true);
        Product2 discontinuedWithReplacementDiscontinuedProduct = ECOM_TestUtil.createProduct('Test DicontinuedReplacement Product', 'TEST-0008', 'TEST-PC-0008', true);

        List<Product2> productUpdateList = new List<Product2>();
        discontinuedDirectReplacementProduct.Replacement_Product__c = sellableProduct.Id;
        discontinuedIndirectReplacementProduct.Replacement_Alternatives__c = sellableProduct.Part_Number__c +','+ sellableProduct.Part_Number__c;
        discontinuedDirectReplacementDisabledProduct.Replacement_Product__c = sellableAlternativeProduct.Id;
        discontinuedIndirectReplacementDisabledProduct.Replacement_Alternatives__c = sellableAlternativeProduct.Part_Number__c +','+ sellableProduct.Part_Number__c;
        productUpdateList.add(discontinuedDirectReplacementProduct);
        productUpdateList.add(discontinuedIndirectReplacementProduct);
        productUpdateList.add(discontinuedDirectReplacementDisabledProduct);
        productUpdateList.add(discontinuedIndirectReplacementDisabledProduct);
        productUpdateList.add(sellableAlternativeProduct);
        productUpdateList.add(discontinuedProduct);
        productUpdateList.add(nonSellableProduct);
        productUpdateList.add(sellableProduct);
        productUpdateList.add(discontinuedWithReplacementDiscontinuedProduct);
        update productUpdateList;

        Product_Sales__c sellableProductSales = ECOM_TestUtil.createProduct_Sales(String.valueOf(sellableProduct.Id));
        Product_Sales__c sellableAlternativeProductSales = ECOM_TestUtil.createProduct_Sales(String.valueOf(sellableAlternativeProduct.Id));
        Product_Sales__c discontinuedProductSales = ECOM_TestUtil.createProduct_Sales(String.valueOf(discontinuedProduct.Id));
        Product_Sales__c nonSellableProductSales = ECOM_TestUtil.createProduct_Sales(String.valueOf(nonSellableProduct.Id));
        Product_Sales__c discontinuedDirectReplacementProductSales = ECOM_TestUtil.createProduct_Sales(String.valueOf(discontinuedDirectReplacementProduct.Id));
        Product_Sales__c discontinuedDirectReplacementAlternativeProductSales = ECOM_TestUtil.createProduct_Sales(String.valueOf(discontinuedDirectReplacementDisabledProduct.Id));
        Product_Sales__c discontinuedIndirectReplacementProductSales = ECOM_TestUtil.createProduct_Sales(String.valueOf(discontinuedIndirectReplacementProduct.Id));
        Product_Sales__c discontinuedWithReplacementDiscontinuedProductSales = ECOM_TestUtil.createProduct_Sales(String.valueOf(discontinuedIndirectReplacementDisabledProduct.Id));
        List<Product_Sales__c> productSalesUpdateList = new List<Product_Sales__c>();

        sellableProductSales.Distribution_ChainSpecificMaterialStatus__c = 'ZW';
        sellableProductSales.Sales_Org__c = 'US10';

        sellableAlternativeProductSales.Distribution_ChainSpecificMaterialStatus__c = 'ZS';
        sellableAlternativeProductSales.Sales_Org__c = 'US10';

        discontinuedProductSales.Distribution_ChainSpecificMaterialStatus__c = '02';
        discontinuedProductSales.Sales_Org__c = 'US10';

        nonSellableProductSales.Distribution_ChainSpecificMaterialStatus__c = 'ZS';
        nonSellableProductSales.Sales_Org__c = 'US10';

        discontinuedDirectReplacementProductSales.Distribution_ChainSpecificMaterialStatus__c = '02';
        discontinuedDirectReplacementProductSales.Sales_Org__c = 'US10';

        discontinuedDirectReplacementAlternativeProductSales.Distribution_ChainSpecificMaterialStatus__c = '02';
        discontinuedDirectReplacementAlternativeProductSales.Sales_Org__c = 'US10';

        discontinuedIndirectReplacementProductSales.Distribution_ChainSpecificMaterialStatus__c = '02';
        discontinuedIndirectReplacementProductSales.Sales_Org__c = 'US10';

        discontinuedWithReplacementDiscontinuedProductSales.Distribution_ChainSpecificMaterialStatus__c = '02';
        discontinuedWithReplacementDiscontinuedProductSales.Sales_Org__c = 'US10';

        productSalesUpdateList.add(sellableProductSales);
        productSalesUpdateList.add(sellableAlternativeProductSales);
        productSalesUpdateList.add(discontinuedProductSales);
        productSalesUpdateList.add(nonSellableProductSales);
        productSalesUpdateList.add(discontinuedDirectReplacementProductSales);
        productSalesUpdateList.add(discontinuedDirectReplacementAlternativeProductSales);
        productSalesUpdateList.add(discontinuedIndirectReplacementProductSales);
        productSalesUpdateList.add(discontinuedWithReplacementDiscontinuedProductSales);
        insert productSalesUpdateList;

        List<Pricebook2> pricebookList = [SELECT Id FROM Pricebook2 WHERE IsActive = true LIMIT 1];
        List<Network> networkList = [SELECT Id, name FROM Network LIMIT 1];
        Id catalogId = ECOM_ProductUtil.getCatalogueId(networkList[0].Id);
        List<ProductCategory> productCategoryList = [SELECT Id, Name FROM ProductCategory WHERE CatalogId = :catalogId];
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

        Network comm = [SELECT id, name FROM Network ORDER BY CREATEDDATE DESC limit 1];
        String communityId = (String)comm.Id;

        List<Account> accountsList =[ SELECT Id,AccountNumber FROM Account];
        List<User> userList = [Select Id,LastName, ContactId, AccountId, Account.CurrencyIsoCode From User WHERE ECOM_Is_Punchout_User__c = true AND AccountId != null AND AccountId IN : accountsList LIMIT 1];
        Product2 testProduct = ECOM_TestUtil.createProduct('TestProduct12','1','TP143',True);
        Product_Sales__c productSales = ECOM_TestUtil.createProduct_Sales(testProduct.Id);
        ERP_Address__c master = ECOM_TestUtil.createNewPunchoutMasterAddressConfiguration();
        master.ECOM_Punchout_Products_Exclude_Query__c = 'SHOW PRODUCT Where RadioActive != true AND PartNumber not in (\'1234567\')';
        master.ECOM_Punchout_Products_Include_Query__c='';
        update master;
        List<Account> accountList = [SELECT Id FROM Account where Id IN :accountsList LIMIT 1];
        ECOM_TestUtil.createRelatedAddresses(accountList[0],master);
        List<String> partNumberQuantityList = new List<String>{'PART123', 'PART456'};
        List<String> result;
        //System.runAs(u) {
        List<Product_Sales__c> productSalesList = ECOM_ProductUtil.getProudctSalesByProductIds(new Set<String> {
            sellableProduct.Id,
            discontinuedProduct.Id,
            nonSellableProduct.Id,
            discontinuedDirectReplacementProduct.Id,
            discontinuedDirectReplacementDisabledProduct.Id,
            discontinuedIndirectReplacementProduct.Id,
            discontinuedIndirectReplacementDisabledProduct.Id
        } , new List<String> { sellableProduct.Id,
            discontinuedProduct.Part_Number__c,
            nonSellableProduct.Part_Number__c,
            discontinuedDirectReplacementProduct.Part_Number__c,
            discontinuedDirectReplacementDisabledProduct.Part_Number__c,
            discontinuedIndirectReplacementProduct.Part_Number__c,
            discontinuedIndirectReplacementDisabledProduct.Part_Number__c}, networkList[0].Id ,true, userList[0].Id);
    }

    /**
    * @description Test class to verify the recently purchased Products.
    * @author Prabhat Kumar
    * @date 01-04-2025
    */
    @isTest
    static void testgetRecentlyPurchasedProductsIncludeQuery(){

        Network comm = [SELECT id, name FROM Network ORDER BY CREATEDDATE DESC limit 1];
        String communityId = (String)comm.Id;
        User u = [Select Id,LastName, ContactId, AccountId From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Product2 testProduct = ECOM_TestUtil.createProduct('TestProduct12','1','TP143',True);
        Product_Sales__c productSales = ECOM_TestUtil.createProduct_Sales(testProduct.Id);
        ERP_Address__c master = ECOM_TestUtil.createNewPunchoutMasterAddressConfiguration();
        master.ECOM_Punchout_Products_Exclude_Query__c = '';
        master.ECOM_Punchout_Products_Include_Query__c='SHOW PRODUCT Where RadioActive != true AND PartNumber not in (\'1234567\')';
        update master;
        Account acc = [SELECT Id FROM Account where Id =:u.AccountId LIMIT 1];
        ECOM_TestUtil.createRelatedAddresses(acc,master);
        List<String> partNumberQuantityList = new List<String>{'PART123', 'PART456'};
        List<String> result;
        System.runAs(u){
            ECOM_ProductService.getRecentlyPurchasedProducts(communityId,u.Id);// RWPS-3023
        }


    }

    /**
    * @description Test class to verify the recently purchased Products.
    * @author Abhishek Joshi 2025.07.15
    */
    @isTest
    static void testgetSellableProductsForGuest(){
        Network comm = [SELECT id, name FROM Network ORDER BY CREATEDDATE DESC limit 1];
        String communityId = (String)comm.Id;

        ECOM_ProductUtil.getSellableProductsForGuest(new Set<String>{'test'},
                                                     new List<String>{'ZW'},
                                                     communityId,
                                                     'US10');
    }

    /**
     * RWPS-3772
    * @description Test class to verify the method 'getReplacementMap' from 'ECOM_ProductUtil'
    * @author Sachin Vispute 2025.10.08
    */
    @isTest
    private static void testGetReplacementMap() {
        List<User> userList = [SELECT Id, LastName, AccountId, Contact.ECOM_CountryProvided__c From User WHERE AccountId != null AND ECOM_Is_Punchout_User__c = false AND Contact.ECOM_CountryProvided__c = 'United States' ORDER BY CreatedDate DESC LIMIT 1];
        Product2 sellableProduct = ECOM_TestUtil.createProduct('Test Sellable Product', 'TEST-0000', 'TEST-PC-0000', true);
        Product2 sellableAlternativeProduct = ECOM_TestUtil.createProduct('Test Sellable Alternate Product', 'TEST-0001', 'TEST-PC-0001', true);
        Product2 discontinuedProduct = ECOM_TestUtil.createProduct('Test Discontinued Product', 'TEST-0002', 'TEST-PC-0002', true);
        Product2 nonSellableProduct = ECOM_TestUtil.createProduct('Test NonSellableProduct Product', 'TEST-0003', 'TEST-PC-0003', true);
        Product2 discontinuedDirectReplacementProduct = ECOM_TestUtil.createProduct('Test DirectReplacementProduct Product', 'TEST-0004', 'TEST-PC-0004', true);
        Product2 discontinuedDirectReplacementDisabledProduct = ECOM_TestUtil.createProduct('Test DirectReplacementProduct Product', 'TEST-0005', 'TEST-PC-0005', true);
        Product2 discontinuedIndirectReplacementProduct = ECOM_TestUtil.createProduct('Test IndirectReplacementProduct Product', 'TEST-0006', 'TEST-PC-0006', true);
        Product2 discontinuedIndirectReplacementDisabledProduct = ECOM_TestUtil.createProduct('Test IndirectReplacementProduct Product', 'TEST-0007', 'TEST-PC-0007', true);
        Product2 discontinuedWithReplacementDiscontinuedProduct = ECOM_TestUtil.createProduct('Test DicontinuedReplacement Product', 'TEST-0008', 'TEST-PC-0008', true);

        List<Product2> productUpdateList = new List<Product2>();
        discontinuedDirectReplacementProduct.Replacement_Product__c = sellableProduct.Id;
        discontinuedIndirectReplacementProduct.Replacement_Alternatives__c = sellableProduct.Part_Number__c +','+ sellableProduct.Part_Number__c;
        discontinuedDirectReplacementDisabledProduct.Replacement_Product__c = sellableAlternativeProduct.Id;
        discontinuedIndirectReplacementDisabledProduct.Replacement_Alternatives__c = sellableAlternativeProduct.Part_Number__c +','+ sellableProduct.Part_Number__c;
        productUpdateList.add(discontinuedDirectReplacementProduct);
        productUpdateList.add(discontinuedIndirectReplacementProduct);
        productUpdateList.add(discontinuedDirectReplacementDisabledProduct);
        productUpdateList.add(discontinuedIndirectReplacementDisabledProduct);
        productUpdateList.add(sellableAlternativeProduct);
        productUpdateList.add(discontinuedProduct);
        productUpdateList.add(nonSellableProduct);
        productUpdateList.add(sellableProduct);
        productUpdateList.add(discontinuedWithReplacementDiscontinuedProduct);
        update productUpdateList;

        Product_Sales__c sellableProductSales = ECOM_TestUtil.createProduct_Sales(String.valueOf(sellableProduct.Id));
        Product_Sales__c sellableAlternativeProductSales = ECOM_TestUtil.createProduct_Sales(String.valueOf(sellableAlternativeProduct.Id));
        Product_Sales__c discontinuedProductSales = ECOM_TestUtil.createProduct_Sales(String.valueOf(discontinuedProduct.Id));
        Product_Sales__c nonSellableProductSales = ECOM_TestUtil.createProduct_Sales(String.valueOf(nonSellableProduct.Id));
        Product_Sales__c discontinuedDirectReplacementProductSales = ECOM_TestUtil.createProduct_Sales(String.valueOf(discontinuedDirectReplacementProduct.Id));
        Product_Sales__c discontinuedDirectReplacementAlternativeProductSales = ECOM_TestUtil.createProduct_Sales(String.valueOf(discontinuedDirectReplacementDisabledProduct.Id));
        Product_Sales__c discontinuedIndirectReplacementProductSales = ECOM_TestUtil.createProduct_Sales(String.valueOf(discontinuedIndirectReplacementProduct.Id));
        Product_Sales__c discontinuedWithReplacementDiscontinuedProductSales = ECOM_TestUtil.createProduct_Sales(String.valueOf(discontinuedIndirectReplacementDisabledProduct.Id));
        List<Product_Sales__c> productSalesUpdateList = new List<Product_Sales__c>();

        sellableProductSales.Distribution_ChainSpecificMaterialStatus__c = 'ZW';
        sellableProductSales.Sales_Org__c = 'US10';

        sellableAlternativeProductSales.Distribution_ChainSpecificMaterialStatus__c = 'ZS';
        sellableAlternativeProductSales.Sales_Org__c = 'US10';

        discontinuedProductSales.Distribution_ChainSpecificMaterialStatus__c = '02';
        discontinuedProductSales.Sales_Org__c = 'US10';

        nonSellableProductSales.Distribution_ChainSpecificMaterialStatus__c = 'ZS';
        nonSellableProductSales.Sales_Org__c = 'US10';

        discontinuedDirectReplacementProductSales.Distribution_ChainSpecificMaterialStatus__c = '02';
        discontinuedDirectReplacementProductSales.Sales_Org__c = 'US10';

        discontinuedDirectReplacementAlternativeProductSales.Distribution_ChainSpecificMaterialStatus__c = '02';
        discontinuedDirectReplacementAlternativeProductSales.Sales_Org__c = 'US10';

        discontinuedIndirectReplacementProductSales.Distribution_ChainSpecificMaterialStatus__c = '02';
        discontinuedIndirectReplacementProductSales.Sales_Org__c = 'US10';

        discontinuedWithReplacementDiscontinuedProductSales.Distribution_ChainSpecificMaterialStatus__c = '02';
        discontinuedWithReplacementDiscontinuedProductSales.Sales_Org__c = 'US10';

        productSalesUpdateList.add(sellableProductSales);
        productSalesUpdateList.add(sellableAlternativeProductSales);
        productSalesUpdateList.add(discontinuedProductSales);
        productSalesUpdateList.add(nonSellableProductSales);
        productSalesUpdateList.add(discontinuedDirectReplacementProductSales);
        productSalesUpdateList.add(discontinuedDirectReplacementAlternativeProductSales);
        productSalesUpdateList.add(discontinuedIndirectReplacementProductSales);
        productSalesUpdateList.add(discontinuedWithReplacementDiscontinuedProductSales);
        insert productSalesUpdateList;

        List<Pricebook2> pricebookList = [SELECT Id FROM Pricebook2 WHERE IsActive = true LIMIT 1];
        List<Network> networkList = [SELECT Id, name FROM Network LIMIT 1];
        Id catalogId = ECOM_ProductUtil.getCatalogueId(networkList[0].Id);
        List<ProductCategory> productCategoryList = [SELECT Id, Name FROM ProductCategory WHERE CatalogId = :catalogId];
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
        if (userList.isEmpty() == false) {
            System.runAs(userList[0]) {
                Map<String,Object> productDetailsMap = ECOM_ProductUtil.getReplacementMap(networkList[0].Id , new Set<String>{
                    sellableProduct.Id,
                    discontinuedProduct.Id,
                    nonSellableProduct.Id,
                    discontinuedDirectReplacementProduct.Id,
                    discontinuedDirectReplacementDisabledProduct.Id,
                    discontinuedIndirectReplacementProduct.Id,
                    discontinuedIndirectReplacementDisabledProduct.Id
                });
                Assert.areEqual(false, productDetailsMap.isEmpty(), 'ProductDetails Must be received');
            }
        }
    }
}