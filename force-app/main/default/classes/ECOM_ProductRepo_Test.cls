/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    Not Applicable    
*
* 2. Description - This class is a test class
*
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
*   - ECOM_ProductRepo
*   - ECOM_TestUtil
*    
*   
* 6. Test Class Name: 
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vipul 2023.09.07
*    - Manoj 2023.09.07
*    - Manoj 2024.01.17 Ticket - ECOM-2065
*    - Poonam 2025.02.04 Added method testGetProductTnCById Ticket - RWPS- 1456
*    - Poonam 2025.02.05 Added method testGetProductSalesRecord Ticket - RWPS- 1456
*    - Poonam 2025.02.05 Added method testGetProductSalesWithProductList, testGetZCProductSalesWithMaterialCodes, testGetZCProducts, testGetProductsBasedOnQuery Ticket - RWPS- 1456
*************************************************************/
@isTest(SeeAllData=false)
public with sharing class ECOM_ProductRepo_Test {
        
        /**
        * @description //To setup test Data
        * @author Vipul Goyal | 09-20-2023 
        **/
    @TestSetup
        public static void testSetupData()
        {
            ECOM_TestUtil.initialStorefrontSetup();
        }

    /**
    * @description //To test product retrieval
    * @author Vipul Goyal | 09-20-2023 
    **/
    @isTest
    static void testGetProductsBasedOnPartNumber() {
        User u = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        List<String> partNumbers = new List<String>{'123', '456'};
        List<Product2> products = new List<Product2>();
        for (String partNumber : partNumbers) {
            products.add(ECOM_TestUtil.createProduct('Test Product', partNumber, 'CODE123', true));
        }
        List<Product2> result; 
        System.runAs(u){
             result = ECOM_ProductRepo.getProductsBasedOnPartNumber(partNumbers);
        }
       
        
        System.assertEquals(products.size(), result.size(), 'Incorrect number of products returned');
    }

    
    /**
    * @description //To test product retrieval display url
    * @author Sidak Singh | 04-22-2024
    **/
    @isTest
    static void testGetProductDisplayUrlForProductCode() {
        User u = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        String partNumber = 'CODE123';
        List<Product2> products = new List<Product2>();
        products.add(ECOM_TestUtil.createProduct('Test Product', partNumber, 'CODE123', true));
        
        List<Product2> result;
        System.runAs(u){
             result = ECOM_ProductRepo.getProductDisplayUrlForProductCode(partNumber);
        }
    }

    /**
    * @description //To test product retrieval
    * @author Sidak Singh | 04-22-2024 
    **/
    @isTest
    static void testGetProductsForPartNumbers() {
        User u = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Set<String> partNumbers = new Set<String>{'123', '456'};
        List<Product2> products = new List<Product2>();
        for (String partNumber : partNumbers) {
            products.add(ECOM_TestUtil.createProduct('Test Product', partNumber, 'CODE123', true));
        }
        List<Product2> result;
        System.runAs(u){
             result = ECOM_ProductRepo.getProductsForPartNumbers(partNumbers);
        }        
    }
    
    /**
    * @description //To test producr Sales retrieval
    * @author Vipul Goyal | 09-20-2023 
    **/
    @isTest
    static void testGetProductSales() {
        Product2 product = ECOM_TestUtil.createProduct('Test Product', '123', 'CODE123', true);
        Set<String> prodIds = new Set<String>{product.Id};
        
        List<Product_Sales__c> productSales = new List<Product_Sales__c>();
       
             
        List<Product_Sales__c> result = ECOM_ProductRepo.getProductSales(prodIds, new List<String>());
        
        System.assertEquals(productSales.size(), result.size(), 'Incorrect number of product sales records returned');
    }   
    
    /**
    * @description //To test product Sales retrieval based on material codes
    * @author Akash Arora | 01-16-2024 
    **/
    @isTest
    static void testGetProductSalesByMaterialCode() {
        Product2 product = ECOM_TestUtil.createProduct('Test Product', '123', 'CODE123', true);
        Set<String> prodIds = new Set<String>{product.Id};
        List<Product_Sales__c> productSales = new List<Product_Sales__c>();
        // RWPS-1456 - START
        Account ac = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
        Product2 pr = [SELECT Id FROM Product2 ORDER BY CREATEDDATE DESC LIMIT 1];
        // RWPS-1456 - END
        List<Product_Sales__c> result = ECOM_ProductRepo.getProductSalesByProdIdAndMaterialCodes(prodIds, new List<String>{'ZW'});
        System.assertEquals(productSales.size(), result.size(), 'Incorrect number of product sales records returned');
    }

     /**
    * @description //To test product retrieval based on Name
    * @author Vipul Goyal | 09-20-2023 
    **/
    @isTest
    static void testGetProductsByName() {
        // Retrieve latest created Product2 record
        Product2 pr = [SELECT Id FROM Product2 ORDER BY CreatedDate DESC LIMIT 1];
        String productId = pr.Id;
        List<Product2> products = ECOM_ProductRepo.getProductsByName('Test Product');
    }
    
     /**
    * @description //To test webstore product retrieval
    * @author Akash Arora | 01-16-2024 
    **/
    @isTest
    static void testWebstoreProductsRetrieval() {
        // Retrieve latest created Product2 record
        Product2 pr = [SELECT Id FROM Product2 ORDER BY CreatedDate DESC LIMIT 1];
        String webstoreId = '';
        String effectiveAccountId = '';
        ConnectApi.ProductOverviewCollection objCollection = ECOM_ProductRepo.getProducts(webstoreId,effectiveAccountId,new List<String>{pr.Id}, new List<String>{'Name'}, true);
    }

     /**
    * @description //To test product retrieval by Id
    * @author Vipul Goyal | 09-20-2023 
    **/
    @isTest
    static void testGetProductsByIds() {
        Product2 pr1 = [SELECT Id FROM Product2 ORDER BY CreatedDate DESC LIMIT 1];
        // String productId = pr1.Id;
        Product2 pr2 = [SELECT Id FROM Product2 ORDER BY CreatedDate DESC LIMIT 1];
        // String productId = pr2.Id;
        
        Set<String> productIds = new Set<String>{ pr1.Id, pr2.Id };
        List<Product2> products = ECOM_ProductRepo.getProductsByIds(productIds);
        // System.assertEquals(2, products.size());
    }

     /**
    * @description //To test Product Media Retrieval.
    * @author Vipul Goyal | 09-20-2023 
    **/
    @isTest
    static void testGetElMediaIds() {
        // Create test data
        Product2 pr = [SELECT Id FROM Product2 ORDER BY CreatedDate DESC LIMIT 1];
        String productId = pr.Id;
        
        List<Id> productIds = new List<Id>{ pr.Id };
        
        // Call the method and perform assertions
        List<ProductMedia> productMediaList = ECOM_ProductRepo.getElMediaIds(productIds);
        // Add assertions
        
        // Clean up test data if necessary
        delete pr;
    }

     /**
    * @description //To test product insertion
    * @author Vipul Goyal | 09-20-2023 
    **/
    @isTest
    static void testInsertProducts() {
        // Create test data
        Product2 pr1 = new Product2(
            Name = 'Test Product 1',
            Part_Number__c = '123',
            StockKeepingUnit = 'SKU123'
            // Add other required fields as needed
        );
        Product2 pr2 = new Product2(
            Name = 'Test Product 2',
            Part_Number__c = '456',
            StockKeepingUnit = 'SKU456'
            // Add other required fields as needed
        );
        List<Product2> insertedProducts = ECOM_ProductRepo.insertProducts(new List<Product2>{ pr1, pr2 });        
        // Clean up test data if necessary
        delete insertedProducts;
    }
    
    /**
    * @description Get GetProductTnC
    * @author Poonam Shukla | 02-04-2025
    */
	@isTest
    public static void testGetProductTnCById() {
        Set<String> productIds = new Set<String>();
        // Create Product records with and without ECOM_Product_TnC__c populated
        Product2 productWithTnC = new Product2(Name = 'Product With TnC', ECOM_Product_TnC__c = 'Test TnC', Part_Number__c = 'PN-001');
        insert productWithTnC;
        productIds.add(productWithTnC.Id);
        Product2 productWithoutTnC = new Product2(Name = 'Product Without TnC', ECOM_Product_TnC__c = null, Part_Number__c = 'PN-002');
        insert productWithoutTnC;
        productIds.add(productWithoutTnC.Id);
        // Step 2: Run the method being tested
        Test.startTest();
        List<Product2> result = ECOM_ProductRepo.getProductTnCById(productIds);
        Test.stopTest();
        // Step 3: Assertions to check if the result is correct
        // Check that the result is not null
        System.assertNotEquals(result, null, 'Expected product list to be returned.');
        // Check that the correct number of products are returned (should exclude productWithoutTnC)
        System.assertEquals(result.size(), 1, 'Expected only 1 product with non-null ECOM_Product_TnC__c to be returned.');
        // Check that the returned product has ECOM_Product_TnC__c populated
        System.assertNotEquals(result[0].ECOM_Product_TnC__c, null, 'ECOM_Product_TnC__c should not be null for the returned product.');
        // Check that the returned product is the one with the ECOM_Product_TnC__c field set
        System.assertEquals(result[0].Id, productWithTnC.Id, 'The returned product should be the one with ECOM_Product_TnC__c populated.');
    }
   	
    /**
    * @description Get Product Sales records from material code and salesOrg
    * @author Poonam Shukla
    * @date 02-06-2025
    */
    @isTest
    static void testGetProductSalesRecord() {
        User u = [Select Id,LastName, AccountId From User ORDER BY CREATEDDATE DESC LIMIT 1];
        String materialCode = 'ZW';  // Example part number
        String salesOrg = 'US01';         // Example sales org
        Product2 product = new Product2(Name = 'Test Product', Part_Number__c = 'AL34455');
        insert product;
        Product_Sales__c prodSale = new Product_Sales__c(
            Product__c = product.Id,
            Sales_Org__c = salesOrg,
            Distribution_ChainSpecificMaterialStatus__c = 'ZC'  // Example valid status
        );
        insert prodSale;
        List<Product_Sales__c> result;
         System.runAs(u){
            result = ECOM_ProductRepo.getProductSales(materialCode, salesOrg);
         }       
    }

     /**
    * @description Get Product Sales records from material code, salesOrg, ProductList
    * @author Poonam Shukla
    * @date 02-07-2025
    */
    @isTest
    static void testGetProductSalesWithProductList() {
        User u = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        String testSalesOrg = 'EBE2';
        Product2 testProduct1 = new Product2(Name = 'Test Product 1', Part_Number__c = 'PN1', IsActive = true);
        Product2 testProduct2 = new Product2(Name = 'Test Product 2', Part_Number__c = 'PN2', IsActive = true);
        insert new List<Product2>{ testProduct1, testProduct2 };
        List<String> testMaterialCodes = new List<String>{ 'ZW', 'ZX' };
        List<Product2> productList = new List<Product2>{ testProduct1, testProduct2 };
        List<Product_Sales__c> result;
        System.runAs(u){
             result =  ECOM_ProductRepo.getProductSales(testSalesOrg, testMaterialCodes, productList);
        }
    }

    /**
    * @description Get ZC Product Sales records from material code, custom material code, salesOrg, ProductList
    * @author Poonam Shukla
    * @date 02-07-2025
    */
    @isTest
    static void testGetZCProductSalesWithMaterialCodes() {
        User u = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        String testSalesOrg = 'EBE2';
        Product2 testProduct1 = new Product2(Name = 'Test Product 1', Part_Number__c = 'PN1', IsActive = true);
        Product2 testProduct2 = new Product2(Name = 'Test Product 2', Part_Number__c = 'PN2', IsActive = true);
        Product2 testProduct3 = new Product2(Name = 'Test Product 3', Part_Number__c = 'PN3', IsActive = true);
        insert new List<Product2>{ testProduct1, testProduct2, testProduct3 };
        List<String> testMaterialCodes = new List<String>{ 'Code1', 'Code2' };
        List<String> testCustomMaterialCodes = new List<String>{ 'ZC', 'ZCC' };
        List<Product2> partProds = new List<Product2>{ testProduct1 };
        List<Product2> inclusionProds = new List<Product2>{ testProduct2 };
        List<Product_Sales__c> result;
        System.runAs(u){
             result = ECOM_ProductRepo.getZCProductSalesWithMaterialCodes(testSalesOrg, testMaterialCodes, testCustomMaterialCodes, partProds, inclusionProds);
        }
    }

    /**
    * @description Get ZC Product Sales records from custom material code, salesOrg, ProductList
    * @author Poonam Shukla
    * @date 02-07-2025
    */
    @isTest
    static void testGetZCProducts() {
        User u = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        String testSalesOrg = 'EBE2';
        Product2 testProduct1 = new Product2(Name = 'Test Product 1', Part_Number__c = 'PN1', IsActive = true);
        Product2 testProduct2 = new Product2(Name = 'Test Product 2', Part_Number__c = 'PN2', IsActive = true);
        insert new List<Product2>{ testProduct1, testProduct2 };
        List<String> testCustomMaterialCodes = new List<String>{ 'ZC', 'CustomCode2' };
        List<String> testPartNumbers = new List<String>{ 'PN1', 'PN2' };
        Product_Sales__c testSale1 = new Product_Sales__c(
            Sales_Org__c = testSalesOrg,
            Product__c = testProduct1.Id,
            Distribution_ChainSpecificMaterialStatus__c = 'ZC'
        );
        Product_Sales__c testSale2 = new Product_Sales__c(
            Sales_Org__c = testSalesOrg,
            Product__c = testProduct2.Id,
            Distribution_ChainSpecificMaterialStatus__c = 'ZX'
        );
        Product_Sales__c testSale3 = new Product_Sales__c(
            Sales_Org__c = testSalesOrg,
            Product__c = testProduct1.Id,
            Distribution_ChainSpecificMaterialStatus__c = 'ZS'
        );
        insert new List<Product_Sales__c>{ testSale1, testSale2, testSale3 };
        List<Product_Sales__c> result;
        System.runAs(u){
             result = ECOM_ProductRepo.getZCProducts(testSalesOrg, testCustomMaterialCodes, testPartNumbers);
        }
    }

    /**
    * @description It executes base query and return related products
    * @author Poonam Shukla
    * @date 02-07-2025
    */
    @isTest
    static void testGetProductsBasedOnQuery() {
        User u = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Id webstoreId = [SELECT Id FROM WebStore LIMIT 1].Id;
        List<WebStoreCatalog> prodCatalog = [SELECT ProductCatalogId FROM WebStoreCatalog WHERE SalesStoreId =: webstoreId];
        Id catalogId= prodCatalog[0].ProductCatalogId;
        String testPartNumber = '%PN%';
        String testCurrencyCode = 'USD';
        Product2 testProduct1 = new Product2(Name = 'Test Product 1', Part_Number__c = 'PN1', IsActive = true);
        Product2 testProduct2 = new Product2(Name = 'Test Product 2', Part_Number__c = 'PN2', IsActive = true);
        Product2 testProduct3 = new Product2(Name = 'Test Product 3', Part_Number__c = 'PN3', IsActive = true);
        insert new List<Product2>{ testProduct1, testProduct2, testProduct3 };
        String baseQuery = 'SELECT Id FROM Product2 WHERE IsActive = true AND Part_Number__c LIKE :partNumber' +
                        ' AND Id IN (SELECT Product2Id FROM PricebookEntry WHERE CurrencyIsoCode = :currencyCode )' +
                        ' AND Id IN (SELECT ProductId FROM ProductCategoryProduct WHERE CatalogId = :catalogId)';
        List<Product2> result;
        System.runAs(u){
             result = ECOM_ProductRepo.getProductsBasedOnQuery(baseQuery,testPartNumber,testCurrencyCode,catalogId);
        }
    }
}