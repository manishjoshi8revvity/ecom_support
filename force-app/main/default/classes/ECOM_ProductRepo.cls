/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-123
*
* 2. Description - This class is used to retrieve/insert/updates Product2 records.
*
*
*
* 3. Objects referenced
*    -Product2
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_ProductService
*
* 6. Test Class Name:
*    - ECOM_ProductRepo_Test
*
* 7. Is @Invocable: No
*
* 8. Author Name(s):
*    - Vipul Goyal 2023.07.31
*    - Manish 2023.08.20
*	 - Sathiya 2024.06.11 Added method getProductTnCById for ECOM-123 to validate Product T & C
*    - Poonam 2025.02.02 Added method getZCProducts, getZCProductSalesWithMaterialCodes, getProductSales returns It returns the ZC and other list of Products of respective material codes  - RWPS- 1456, RWPS-2132
*    - Poonam 2025.02.07 Added method getProductsBasedOnQuery executes base query and return related products RWPS- 1456, RWPS-2132
*    - Poonam 2025.02.20 Updated method getProductSales, getZCProductSalesWithMaterialCodes, getZCProducts updated query limit size RWPS-2390
*    - Prabhat Kumar 2025.04.01 Update method getProductSales to include Product_Display_Name__c and ECOM_Product_Media_URI__c in query - RWPS-2855
*    - Prabhat Kumar 2025.06.25 created method getProductSalesAbandonedCart to get abandoned cart Product Sales - RWPS-2786
*    - Abhishek J 2025.09.25 created method getProductSalesAndReplacementByProdIdAndMaterialCodes to get replacable product - RWPS-3740
*    - Abhishek 2025.09.25 updated methods getProductsByIds, getProductsForPartNumbers. Added method getProductsByProductModelsAndIds - RWPS-4437
*    - Abhishek 2026.03.10 Updated method getZCProductSalesWithMaterialCodes - RWPS-5774
*************************************************************/
public without sharing class ECOM_ProductRepo {


    /**
    * @description This method returns product records based on Part Number.
    * @author Vipul Goyal | 07-31-2023
    * @param partNumbers
    * @return List<Product2>
    **/
    public static List<Product2> getProductsBasedOnPartNumber(List<String> partNumbers)
    {
        return [Select id,Part_Number__c,StockKeepingUnit from Product2 where Part_Number__c in :partNumbers];
    }

     /**
     * @description Fetch Product Sales records based on Product Ids and supported material codes
     * @author Akash Arora | 06-25-2025
     * @param prodIds
     * @param materialCodes
     * @param salesOrg
     * JIRA - RWPS-2786
     * @return List<Product_Sales__c>
     **/
     public static List<Product_Sales__c> getProductSalesAbandonedCart(Set<String> prodIds, List<String> materialCodes, String salesOrg){
        List<Product_Sales__c> prodSales = [SELECT Id, Distribution_ChainSpecificMaterialStatus__c, Product__c, Product__r.Part_Number__c
                                            FROM Product_Sales__c
        									WHERE Product__c IN :prodIds AND Sales_Org__c = :salesOrg AND Distribution_ChainSpecificMaterialStatus__c IN:materialCodes];
        return prodSales ;
    }

    /**
    * @description Fetch Products by Name
    * @author Vipul Goyal | 09-20-2023
    * @param name
    * @return List<Product2>
    **/
    public static List<Product2> getProductsByName(String name){
        return [SELECT Id, Name,Part_Number__c, StockKeepingUnit FROM Product2 WHERE Name = :name];
    }

    /**
    * @description Fetch Products by Ids
    * @author Vipul Goyal | 09-20-2023
    * @param ids
    * @return List<Product2>
    **/
    public static List<Product2> getProductsByIds(Set<String> ids){
        return [SELECT Id, Name,Part_Number__c,IGOR_Item_Class_Desc__c,IGOR_Description__c,Product_Line_Name__c, StockKeepingUnit,Dangerous_Goods_Indicator_Profile__c,Type ,Business_Unit__c, Discount_Type__c,
        Item_Class__c, Part_Type__c,
        Product_Line__c, Product_Type__c,IGOR_PAC__c,Sub_Business_Unit__c,Super_Business_Unit__c, Product_Model_Identifier__c FROM Product2 WHERE Id IN :ids]; // RWPS-4437
    }


    /**
    * @description Fetch Electronic Media Ids
    * @author Vipul Goyal | 09-20-2023
    * @param productIds
    * @return List<ProductMedia>
    **/
    public static List<ProductMedia> getElMediaIds (List<Id> productIds){
        return [SELECT ElectronicMediaId, ProductId FROM ProductMedia WHERE ProductId IN :productIds ORDER BY SortOrder];
    }

    /**
    * @description Create Products
    * @author Vipul Goyal | 09-20-2023
    * @param productsToInsert
    * @return List<Product2>
    **/
    public static List<Product2> insertProducts(List<Product2> productsToInsert){
        insert productsToInsert;
        return productsToInsert;
    }

     /**
     * @description Fetch Product Sales records
     * @author Vipul Goyal | 09-20-2023
     * @param prodIds
     * @param materialCodes
     * @return List<Product_Sales__c>
     **/
     public static List<Product_Sales__c> getProductSales(Set<String> prodIds, List<String> materialCodes){
        User us = new ECOM_UserService().getUserByUserId();
		String salesOrg = ECOM_CustomMetadataService.getSalesOrg(ECOM_Util.getCountryFromUser(us));
        List<Product_Sales__c> prodSales = [SELECT Id, Distribution_ChainSpecificMaterialStatus__c, Product__c, Product__r.Part_Number__c
                                            FROM Product_Sales__c
        									WHERE Product__c IN :prodIds AND Sales_Org__c = :salesOrg];
        return prodSales ;
    }

    /**
     * @description Fetch Product Sales records based on Product Ids and supported material codes
     * @author Akash Arora | 01-10-2024
     * @param prodIds
     * @param materialCodes
     * @return List<Product_Sales__c>
     **/
     public static List<Product_Sales__c> getProductSalesByProdIdAndMaterialCodes(Set<String> prodIds, List<String> materialCodes){
        User us = new ECOM_UserService().getUserByUserId();
		String salesOrg = ECOM_CustomMetadataService.getSalesOrg(ECOM_Util.getCountryFromUser(us));
        List<Product_Sales__c> prodSales = [SELECT Id, Distribution_ChainSpecificMaterialStatus__c, Product__c, Product__r.Part_Number__c
                                            FROM Product_Sales__c
        									WHERE Product__c IN :prodIds AND Sales_Org__c = :salesOrg AND Distribution_ChainSpecificMaterialStatus__c IN:materialCodes];
        return prodSales ;
    }

    /**
    * @description get product related Info with Images
    * @author Vipul Goyal | 09-20-2023
    * @param webstoreId
    * @param effectiveAccountId
    * @param ProductIds
    * @param productFields
    * @param excludeMedia
    * @return ConnectApi.ProductOverviewCollection
    **/
    public static ConnectApi.ProductOverviewCollection getProducts(String webstoreId, String effectiveAccountId,List<String> ProductIds, List<String> productFields, Boolean excludeMedia){
        return ECOM_SalesforceAPI.getProducts(webstoreId, effectiveAccountId, ProductIds, productFields, excludeMedia);
    }

    /**
    * @description get products for product code
    * @author Vasudev R | 11-27-2023
    * @param productCode
    * @return List<Product2>
    **/
    public static List<Product2> getProductDisplayUrlForProductCode(String productCode){
        return [SELECT Id, DisplayUrl FROM Product2 WHERE ProductCode =: productCode LIMIT 1];
    }

    /**
    * @description This method returns the product information for par numbers
    * @author vramachandran@rafter.one | 11 Dec 2023
    * @param partNumbers | Set<String>
    * @return List<Product2>
    **/
    public static List<Product2> getProductsForPartNumbers(Set<String> partNumbers){
        return [SELECT Id, Name, Part_Number__c, DisplayUrl, Dangerous_Goods_Indicator_Profile__c, ECOM_Product_Media_URI__c, Product_Display_Name__c, Product_Model_Identifier__c, Product_Model_Name__c FROM Product2 WHERE Part_Number__c IN : partNumbers]; // RWPS-4437
    }

    /**
     * @description Fetch Product Sales records, for punchout
     * @author vramachandran@rafter.one | 24 Jan 2024
     * @param prodIds
     * @param materialCodes
     * @return List<Product_Sales__c>
     **/
    public static List<Product_Sales__c> getProductSales(String materialCode, String salesOrg){
        List<String> validDistributionStatus = System.Label.ECOM_ValidDistributionChainSpecificMaterialStatus.split(',');
        System.debug('validDistributionStatus:: '+ validDistributionStatus + ' salesOrg:: '+ salesOrg);
        List<Product_Sales__c> prodSales = [SELECT Id, Distribution_ChainSpecificMaterialStatus__c, Product__c, Product__r.Part_Number__c
                                            FROM Product_Sales__c
                                            WHERE Product__r.Part_Number__c =: materialCode
                                            AND Sales_Org__c = :salesOrg
                                            AND Distribution_ChainSpecificMaterialStatus__c IN :validDistributionStatus
                                            LIMIT 1];
        return prodSales ;
    }

    /**
    * @description This method returns the list of product information based on prodIds
    * @author sveeraraghavan@rafter.one | 11 Jun 2024
    * @param productIds | Set<String>
    * @return List<Product2>
    **/
    public static List<Product2> getProductTnCById(Set<String> productIds){
        return [SELECT Id, ECOM_Product_TnC__c, Part_Number__c FROM Product2 WHERE Id IN : productIds AND ECOM_Product_TnC__c != null LIMIT 49999];
    }

    /**
    * @description This method returns the lits of Products of respective material codes
    * @author Poonam Shukla | 2-2-2025
    * @param salesOrg | String, materialCodes | List<String>, products | List<Product2>
    * @return List<Product_Sales__c>
    **/
    public static List<Product_Sales__c> getProductSales(String salesOrg, List<String> materialCodes, List<Product2> products) {
        return [
            SELECT Id, Distribution_ChainSpecificMaterialStatus__c, Product__c, Product__r.ECOM_Product_Media_URI__c, Product__r.Name, Product__r.Product_Display_Name__c, //RWPS-2855
            Product__r.Dangerous_Goods_Indicator_Profile__c, Product__r.Part_Number__c, Sales_Org__c,  Product__r.DisplayUrl
            FROM Product_Sales__c
            WHERE Sales_Org__c = :salesOrg
            AND Product__c IN :products
            AND Distribution_ChainSpecificMaterialStatus__c IN :materialCodes
            LIMIT 49999 //RWPS-2390
        ];
    }

    /**
    * @description This method returns the ZC and other list of Products of respective material codes
    * @author Poonam Shukla | 2-2-2025
    * @params salesOrg | String , materialCodes | List<String>, customMaterialCodes | List<String> ,  partProds | List<Product2>, inclusionProds | List<Product2>
    * @return List<Product_Sales__c>
    **/
    public static List<Product_Sales__c> getZCProductSalesWithMaterialCodes(String salesOrg, List<String> materialCodes, List<String> customMaterialCodes, List<Product2> partProds, List<Product2> inclusionProds) {
        return [
            //RWPS-5774 Start
            SELECT Id, Distribution_ChainSpecificMaterialStatus__c, Product__c, Product__r.ECOM_Product_Media_URI__c, Product__r.Name, Product__r.Product_Display_Name__c,
            Product__r.Dangerous_Goods_Indicator_Profile__c, Product__r.Part_Number__c, Sales_Org__c,  Product__r.DisplayUrl
            //RWPS-5774 End
            FROM Product_Sales__c
            WHERE Sales_Org__c = :salesOrg
            AND (
                (Product__c IN :partProds AND Distribution_ChainSpecificMaterialStatus__c IN :materialCodes)
                OR
                (Product__c IN :inclusionProds AND Distribution_ChainSpecificMaterialStatus__c IN :customMaterialCodes)
            )
            LIMIT 49999 //RWPS-2390
        ];
    }

    /**
    * @description This method returns the ZC Products of respective material codes
    * @author Poonam Shukla | 2-2-2025
    * @params salesOrg | String , materialCodes | List<String>, partnumbers | List<String>
    * @return List<Product_Sales__c>
    **/
   public static List<Product_Sales__c> getZCProducts(String salesOrg, List<String> customMaterialCode, List<String> partnumbers) {
    	return [
            SELECT Id, Distribution_ChainSpecificMaterialStatus__c, Product__c, Product__r.Part_Number__c, Sales_Org__c
            FROM Product_Sales__c
            WHERE Sales_Org__c = :salesOrg
            AND Product__r.Part_Number__c IN :partnumbers
            AND Distribution_ChainSpecificMaterialStatus__c IN :customMaterialCode
            LIMIT 49999 //RWPS-2390
    	];
    }

     /**
    * @description This method executes base query and return related products
    * @author Poonam Shukla | 02-07-2025
    * @params baseQuery | String
    * @return List<Product2>
    **/
    public static List<Product2> getProductsBasedOnQuery(String baseQuery, String partNumber, String currencyCode, Id catalogId){
        baseQuery += ' LIMIT 49999 ';//RWPS-2390
        return Database.query(baseQuery);
    }

    /**
     * @description Fetch Product Sales records based on Product Ids, supported material codes and sales org
     * @author Abhishek Joshi | 09.08.2025 | RWPS-3772
     * @param prodIds | Set<String>
     * @param materialCodes | List<String>
     * @param salesOrg | String
     * @return List<Product_Sales__c>
     **/
    public static List<Product_Sales__c> getProductSalesAndReplacementByProdIdAndMaterialCodes(Set<String> prodIds, List<String> materialCodes, String salesOrg){
        return [
            SELECT Distribution_ChainSpecificMaterialStatus__c, Product__c, Product__r.Replacement_Product__c,Product__r.Replacement_Product__r.Part_Number__c, Product__r.Replacement_Alternatives__c, Product__r.Part_Number__c
            FROM Product_Sales__c
            WHERE Product__c IN :prodIds AND Sales_Org__c = :salesOrg AND Distribution_ChainSpecificMaterialStatus__c IN:materialCodes
        ];
    }

    /**
    * @description Fetch Products by model
    * @author Abhishek Joshi 2025.09.15 | RWPS-4437
    * @param models | Set<String>
    * @param productIds | Set<String>
    * @return List<Product2>
    **/
    public static List<Product2> getProductsByProductModelsAndIds(Set<String> models, Set<String> productIds){
        return [SELECT Id, Name,Part_Number__c,IGOR_Item_Class_Desc__c,IGOR_Description__c,Product_Line_Name__c, StockKeepingUnit,Dangerous_Goods_Indicator_Profile__c,Type ,Business_Unit__c, Discount_Type__c,
        Item_Class__c, Part_Type__c,
        Product_Line__c, Product_Type__c,IGOR_PAC__c,Sub_Business_Unit__c,Super_Business_Unit__c, Product_Model_Identifier__c FROM Product2 WHERE Product_Model_Identifier__c IN :models OR Id IN :productIds];
    }
}