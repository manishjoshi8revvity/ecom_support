/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*
*
* 2. Description - This class is used for Product specific transactions.
*
* 3. Objects referenced
*    - Product
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
*
* 5. Dependant Class(es):
*    -
*
* 6. Test Class Name:
*    ECOM_ProductUtil_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Prabhat Kumar 2025.28.03 - Created method getProudctSalesByProductIds - RWPS-2855
*    - Manish Joshi 2025.04.17 Updated method getProudctSalesByProductIds for UserId - RWPS-3023
*    - Abhishek Joshi 2025.06.24 Updated method getProudctSalesByProductIds - RWPS-3491
*    - Abhishek Joshi 2025.07.15 Updated method getProudctSalesByProductIds, created methods getCatalogueId and getSellableProductsForGuest - RWPS-3697
*    - Abhishek Joshi 2025.10.03 Added method getReplacementMap RWPS-3740
*    - Kushal Shah 2026.02.24 - Updated method 'getProudctSalesByProductIds' - RWPS-5774
*************************************************************/

public without sharing class ECOM_ProductUtil {

    /**
    * @description This function is used to retrieve Product ids based on the include and exclude query.
    * @author Prabhat Kumar
    * @param productIds | Set<String>
    * @param materialCodes | List<String>
    * @param communityId | String
    * @param isPunchoutCart | boolean
    * @param userId | userId
    * @return Set<String>
    **/
    public static List<Product_Sales__c> getProudctSalesByProductIds(
        Set<String> productIds,
        List<String> materialCodes,
        String communityId,
        Boolean isPunchoutCart,
        String userId // RWPS-3023
    ) {
        // RWPS-3491 start
        if(productIds.isEmpty()) {
            return new List<Product_Sales__c>();
        }
        // RWPS-3491 end
        User us = ECOM_UserRepo.getUserByUserId(userId);// RWPS-3023
        String salesOrg = ECOM_CustomMetadataService.getSalesOrg(ECOM_Util.getCountryFromUser(us));
        List<String> accIdList = new List<String>{us.AccountId.toString()};
        List<Account> account = ECOM_AccountRepo.getAccountBasedOnIds(accIdList);
        String currencyCode = account[0].CurrencyIsoCode;
        String partnumber = '';

        // RWPS-3491 start
        List<Product2> productData = ECOM_ProductRepo.getProductsByIds(productIds);
        partnumber = '(';
        for (Product2 productItem : productData) {
            partnumber += '\'' + productItem.Part_Number__c + '\',';
        }
        partnumber = partnumber.removeEnd(',') + ')';
        // RWPS-3491 end

        Id catalogId = ECOM_ProductUtil.getCatalogueId(communityId); // RWPS-3697
        String baseQuery = 'SELECT Id FROM Product2 WHERE IsActive = true AND Part_Number__c IN ' + partnumber + ' AND Id IN (SELECT Product2Id FROM PricebookEntry WHERE CurrencyIsoCode =: currencyCode) AND Id IN (SELECT ProductId FROM ProductCategoryProduct WHERE CatalogId =: catalogId)'; // RWPS-3491
        if (isPunchoutCart)
        {   
            //RWPS-5774 Start
            List<Punchout_Maintenance__c> punchoutConfigs = ERP_AddressRepo.getPunchoutConfigs(null,new Set<Id>{us.AccountId},null,null);
            Punchout_Maintenance__c punchoutConfig = punchoutConfigs.isEmpty() ? null : punchoutConfigs[0];
            Map<String, String> querybuilder = new Map<String, String>();
            if (punchoutConfig != null &&
            (String.isNotBlank(punchoutConfig.ECOM_Punchout_Products_Exclude_Query__c) || String.isNotBlank(punchoutConfig.ECOM_Punchout_Products_Include_Query__c)))
            {
                String excludeQuery = String.isNotBlank(punchoutConfig.ECOM_Punchout_Products_Exclude_Query__c)? punchoutConfig.ECOM_Punchout_Products_Exclude_Query__c : '';
                String includeQuery =String.isNotBlank(punchoutConfig.ECOM_Punchout_Products_Include_Query__c) ? punchoutConfig.ECOM_Punchout_Products_Include_Query__c : '';
                //RWPS-5774 End
                querybuilder = ECOM_ProductService.buildCustomProductQueryForQuickOrderPunchout(includeQuery , excludeQuery);
                String includeWhereClause = querybuilder.get('IncludeWhereClause');
                String excludeWhereClause = querybuilder.get('ExcludeWhereClause');
                String includePartNumberWhereClause = querybuilder.get('IncludePartNumberWhereClause');
                List<Product_Sales__c> productSalesList = new List<Product_Sales__c>();
                // exclude query
                if (!String.isBlank(excludeWhereClause))
                {
                    if(String.isEmpty(includeWhereClause))
                    {
                        baseQuery += ' AND ('  + excludeWhereClause + ' ) ';
                        List<Product2> excludeProds =  Database.query(baseQuery);
                        return ECOM_ProductRepo.getProductSales(salesOrg, materialCodes, excludeProds);
                    }
                }
                //include query
                productSalesList = ECOM_ProductService.getFilteredProductSales(baseQuery, partnumber, currencyCode, catalogId, includeWhereClause, includePartNumberWhereClause, salesOrg, materialCodes);
                return productSalesList;
            }
            List<Product2> prods = Database.query(baseQuery);
            return ECOM_ProductRepo.getProductSales(salesOrg,materialCodes,prods);
        }
        else
        {
            List<Product2> prods = Database.query(baseQuery);
            return ECOM_ProductRepo.getProductSales(salesOrg,materialCodes,prods);
        }
    }

    /**
    * @description Get catalogue Id based on communityId.
    * @author Abhishek Joshi
    * @param communityId | String
    * @return Id
    **/
    public static Id getCatalogueId(String communityId) {
        String webstoreId = ECOM_Util.resolveCommunityIdToWebstoreId(communityId);
        List<WebStoreCatalog> prodCatalog = [SELECT ProductCatalogId FROM WebStoreCatalog WHERE SalesStoreId =: webstoreId];
        return prodCatalog[0].ProductCatalogId;
    }

    /**
    * @description This function is used to retrieve Product ids based guest user sales org.
    * @author Abhishek Joshi
    * @param productIds | Set<String>
    * @param materialCodes | List<String>
    * @param communityId | String
    * @param salesOrg | String
    * @return List<Product_Sales__c>
    **/
    public static List<Product_Sales__c> getSellableProductsForGuest(Set<String> productIds, List<String> materialCodes, String communityId, String salesOrg) {
        // RWPS-4437 start
        if(String.isBlank(salesOrg)) {
            return new List<Product_Sales__c>();
        }
        // RWPS-4437 end

        Id catalogId = ECOM_ProductUtil.getCatalogueId(communityId);
        C_META_Countries__mdt currencyData = ECOM_CustomMetadataRepo.getCurrencyCodeFromSalesOrg(salesOrg);

        String currencyCode = currencyData != null ? currencyData.CurrencyISOCode__c : null;
        if(String.isBlank(currencyCode)) { return new List<Product_Sales__c>(); }

        List<Product2> productList = [SELECT Id FROM Product2 WHERE IsActive = true AND Id IN :productIds AND Id IN (SELECT Product2Id FROM PricebookEntry WHERE CurrencyIsoCode =: currencyCode) AND Id IN (SELECT ProductId FROM ProductCategoryProduct WHERE CatalogId =: catalogId)];

        if (productList.isEmpty()) { return new List<Product_Sales__c>(); }
        return ECOM_ProductRepo.getProductSales(salesOrg, materialCodes, productList);
    }

    /**
    * @description This function is used to generate replacement product map - RWPS-3740
    * @author Abhishek Joshi
    * @param communityId | String
    * @param baseProductIds | Set<String>
    * @return Map<String,Object>
    **/
    public static Map<String,Object> getReplacementMap(String communityId, Set<String> baseProductIds) {
        List<String> directReplacementCodes = ECOM_CartUtil.fetchProductMaterialStatus('DirectReplacementStatus');
        List<String> alternativeReplacementCodes = ECOM_CartUtil.fetchProductMaterialStatus('AlternativeReplacementStatus');

        List<String> allMaterialCodes = new List<String>();
        allMaterialCodes.addAll(directReplacementCodes);
        allMaterialCodes.addAll(alternativeReplacementCodes);

        User us = new ECOM_UserService().getUserByUserId();
		String salesOrg = ECOM_CustomMetadataService.getSalesOrg(ECOM_Util.getCountryFromUser(us));

        List<Product_Sales__c> productsAvailableForReplacement =
            ECOM_ProductRepo.getProductSalesAndReplacementByProdIdAndMaterialCodes(baseProductIds, allMaterialCodes, salesOrg);

        List<String> allReplacementIds = new List<String>();
        Map<String,String> directReplacementMap = new Map<String,String>();

        Set<String> altReplacementParts = new Set<String>();
        Map<String,List<String>> altReplacementPartMap = new Map<String,List<String>>();

        for(Product_Sales__c ps : productsAvailableForReplacement) {
            String directReplacementId = ps.Product__r?.Replacement_Product__c;
            if(String.isNotBlank(directReplacementId) && directReplacementCodes.contains(ps.Distribution_ChainSpecificMaterialStatus__c)) {
                allReplacementIds.add(directReplacementId);
                directReplacementMap.put(ps.Product__c, directReplacementId);
            }

            String altReplacementPn = ps.Product__r?.Replacement_Alternatives__c;
            if(String.isNotBlank(altReplacementPn) && alternativeReplacementCodes.contains(ps.Distribution_ChainSpecificMaterialStatus__c)) {
                List<String> altReplacements = altReplacementPn.trim().split(',');

                List<String> finalAltReplacementParts = new List<String>();

                for(Integer i=0; i<altReplacements.size(); i++) {
                    String temp = altReplacements[i].trim();
                    if(String.isNotBlank(temp)) {
                        finalAltReplacementParts.add(temp);
                    }
                }

                if(finalAltReplacementParts.size() > 0) {
                    altReplacementParts.addAll(finalAltReplacementParts);
                    altReplacementPartMap.put(ps.Product__c, finalAltReplacementParts);
                }
            }
        }

        List<Product2> altReplacementProducts = ECOM_ProductRepo.getProductsForPartNumbers(altReplacementParts);
        Map<String, String> altReplacementIdMap = new Map<String, String>();
        for(Product2 p : altReplacementProducts) {
            altReplacementIdMap.put(p.Part_Number__c, p.Id);
            allReplacementIds.add(p.Id);
        }

        List<Product_Sales__c> sellableReplacements = ECOM_CartController.getSellableProducts(allReplacementIds, '', communityId);
        Set<String> sellableReplacementPn = new Set<String>();
        if(sellableReplacements != null && !sellableReplacements.isEmpty()) { // RWPS-3740
            for(Product_Sales__c ps : sellableReplacements) {
                sellableReplacementPn.add(ps.Product__r.Part_Number__c);
            }
        }

        List<Product2> sellableReplacementProducts = ECOM_ProductRepo.getProductsForPartNumbers(sellableReplacementPn);

        Map<String, Product2> sellableReplacementMap = new Map<String, Product2>();
        for(Product2 p : sellableReplacementProducts) {
            sellableReplacementMap.put(p.Id, p);
        }

        Map<String,Object> replacementMap = new Map<String,Object>();

        for(Product_Sales__c ps : productsAvailableForReplacement) {
            String productId = ps.Product__c;
            Boolean directReplacementFound = false;

            if(directReplacementMap.containsKey(productId)) {
                String directReplacementId = directReplacementMap.get(productId);
                if(sellableReplacementMap.containsKey(directReplacementId)) {
                    Map<String, Object> tempMap = new Map<String, Object>();
                    tempMap.put('DirectReplacement', sellableReplacementMap.get(directReplacementId));
                    replacementMap.put(productId, tempMap);
                    directReplacementFound = true;
                }
            }

            if(!directReplacementFound && altReplacementPartMap.containsKey(productId)) {
                List<String> altReplacements = altReplacementPartMap.get(productId);
                List<Product2> finalAltReplacementProducts = new List<Product2>();
                for(String altPn : altReplacements) {
                    if(altReplacementIdMap.containsKey(altPn)) {
                        String altId = altReplacementIdMap.get(altPn);
                        if(sellableReplacementMap.containsKey(altId)) {
                            finalAltReplacementProducts.add(sellableReplacementMap.get(altId));
                        }
                    }
                }
                if(!finalAltReplacementProducts.isEmpty()) {
                    Map<String, Object> tempMap = new Map<String, Object>();
                    tempMap.put('AlternativeReplacements', finalAltReplacementProducts);
                    replacementMap.put(productId, tempMap);
                }
            }
        }
        return replacementMap;
    }
}