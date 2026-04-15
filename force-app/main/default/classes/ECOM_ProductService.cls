/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM - 123
*
* 2. Description - This class is used for Product specific transactions.
*	It returns product images from cms using product ids
*	it returns products connect api wrapper
	it return Product Sales records 
* 3. Objects referenced
*    - None
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
*
* 5. Dependant Class(es):
*    - ECOM_ProductRepo
*
* 6. Test Class Name: ECOM_OrderHistory_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Sidak 2023.09.13
*    - Sidak 2024.04.16 Added method getProductsBasedOnPartialPartNumber. Ticket - RWPS-29
*    - Gaurang 2024.05.10 - ECOM-112 - added a null check
*	 - Sathiya 2024.06.11 Added method getProductTnCById for ECOM-123 to validate Product T & C
*    - Manoj 2024.09.09 RWPS-1387 read image from Product2.ECOM_Product_Media_URI__c(DAM) instead product media
*    - Sidak 2024.09.09 Updated method getProductsBasedOnPartialPartNumber. Added logic to check valid sales status of the product Ticket - RWPS-1477
*    - Sidak 2024.10.15 Updated method getProductsBasedOnPartialPartNumber. Added logic to check valid products Ticket - RWPS-1582
*    - Poonam 2025.01.03 Updated method getProductsBasedOnPartialPartNumber. Added logic for include and exclude query for Punchout user - RWPS- 1456
*    - Poonam 2025.01.03 RWPS-2132 Exclude Specific Products from Punchout Based on Product Numbers : Exclude Query 
*    - Poonam 2025.01.03 Added buildCustomProductQueryForQuickOrderPunchout, processWhereClause for RWPS-2132, RWPS-1456
*    - Poonam 2025.01.10 Added method extractPartNumbers,processWhereClause & Updated method buildCustomProductQueryForQuickOrderPunchout. Added logic for handling exclude partnumbers for Punchout users and return list - RWPS-2132
*    - Poonam 2025.02.02 Added method getFilteredProductSales returns the ZC and other list of Products of respective material codes  - RWPS- 1456, RWPS-2132
*    - Poonam 2025.02.06 Updated method getFilteredProductSales to fix issue for exclude query excel upload- RWPS-2367
*    - Poonam 2025.01.10 Added method getExcludedPartNumbers. It returns excluded part numbers for Punchout user - RWPS- 1456
*    - Poonam 2025.02.14 Updated method getExcludedPartNumbers. Added logic for Radioactive exclusion product for favorite list - RWPS- 2390
*    - Poonam 2025.02.20 Updated method getExcludedPartNumbers. Optimized query for favorite list product exclusion RWPS- 2390
*    - Gaurav 2025.03.03 Updated method getProdImages - removed code to fix product image issue on order history  RWPS-2731
*    - Poonam 2025.03.10 Updated method getExcludedPartNumbers - retrieve currency code from Account  RWPS-2740
*    - Poonam 2025.03.13 Updated method getProductsBasedOnPartialPartNumber - retrieve currency code from Account  RWPS-2829
*    - Prabhat Kumar 2025.28.03 - Created method getRecentlyPurchasedProducts, getFilteredProductSales to reterive recently purchased Products - RWPS-2855
*    - Poonam 2025.09.4 - Updated method getExcludedPartNumbers to exclude custom partnumbers in favorite list when not configured in include/exclude query - RWPS-2972
*    - Manish Joshi 2025.04.17 Updated method getRecentlyPurchasedProducts for UserId - RWPS-3023
*    - Manish Joshi 2025.08.21 Updated method getRecentlyPurchasedProducts for punchout RWPS-4147
*    - Sachin Vispute 2025.10.13 - Updated method 'getProductsBasedOnPartialPartNumber' , Added logic for fetching salesOrg for dealers - RWPS-4759
*    - Sachin Vispute 2025.12.15 - Updated method 'getRecentlyPurchasedProducts' - RWPS-5507
*    - Princy Anthony 2026.02.04 - Updated method 'getRecentlyPurchasedProducts' - RWPS-6212
*    - Poonam Shukla 2026.02.19 - Updated method 'getRecentlyPurchasedProducts' - RWPS-5777
*    - Kushal Shah 2026.02.24 - Updated method 'getProductsBasedOnPartialPartNumber', 'getExcludedPartNumbers' - RWPS-5774

*************************************************************/
public class ECOM_ProductService{
    
    public static String CLASSNAME = 'ECOM_ProductService';

    /**
    * @description // Fetch product images
    * @author Vipul Goyal | 09-20-2023 
    * @param productIds 
    * @param communityId 
    * @return Map<String, String> 
    **/
    public static Map<String, Object> getProdImages(List<Id> productIds, String communityId){
        Map<String, Object> productImageUrlsByProductIds = new Map<String, Object>();
        try{
            /* Removed code as its not require, we already have productId list RWPS-2731
            get product medias
            List<ProductMedia> prodMedia = ECOM_ProductRepo.getElMediaIds(productIds);
            if(!prodMedia.isEmpty() || Test.isRunningTest()){ //ECOM-112 - garora@rafter.one - added a null check - 10-05-2024
                List<String>pidList =  new List<String>();
                //electronic media map
                if (prodMedia != null && prodMedia.size() > 0) {
                    for (ProductMedia p : prodMedia) {
                        pidList.add(p.ProductId);
                    }
                } */
                String webstoreId = ECOM_Util.resolveCommunityIdToWebstoreId(communityId);
                //RWPS-1387
                ConnectApi.ProductOverviewCollection productOverviewCollection =  getProducts(webstoreId,null,productIds,new List<String>{'ECOM_Product_Media_URI__c'},false);
                List<ConnectApi.ProductOverview> products = productOverviewCollection.products;
                productImageUrlsByProductIds = getProdMedia(products);
            
        }catch(Exception e){
            productImageUrlsByProductIds.put('exception', e.getMessage()+e.getStackTraceString());
        }
        return productImageUrlsByProductIds;
    }

    /**
    * @description // Fetch product media
    * @author Sidak Singh | 12-07-2023 
    * @param products 
    * @return Map<String, String> 
    **/
    public static Map<String, Object> getProdMedia(List<ConnectApi.ProductOverview> products){
        Map<String, Object> productImageUrlsByProductIds = new Map<String, Object>();
        for (ConnectApi.ProductOverview productOverview : products) {
            //RWPS-1387
            if(productOverview.fields !=null){
            	Map<String, String> fields = productOverview.fields;
                if(fields.containsKey('ECOM_Product_Media_URI__c')){
                    productImageUrlsByProductIds.put(productOverview.id,fields.get('ECOM_Product_Media_URI__c'));
                }
        	}
            /*if(productOverview.defaultImage!=null){
                ConnectApi.ProductMedia productMedia = productOverview.defaultImage;
                
                if(String.isNotBlank(productMedia.url)){
                    String url =  productMedia.url;
                    productImageUrlsByProductIds.put(productOverview.id,url);
                }
            }*/
        }
        return productImageUrlsByProductIds;
    }


    /**
    * @description //To get Products
    * @author Vipul Goyal | 09-20-2023 
    * @param webstoreId 
    * @param effectiveAccountId 
    * @param ProductIds 
    * @param productFields 
    * @param excludeMedia 
    * @return ConnectApi.ProductOverviewCollection 
    **/
    public static ConnectApi.ProductOverviewCollection getProducts(String webstoreId, String effectiveAccountId,List<String> ProductIds, List<String> productFields, Boolean excludeMedia){
        return ECOM_ProductRepo.getProducts(webstoreId, effectiveAccountId, ProductIds, productFields, false);
    }

    /**
    * @description  // Fetch Product Sales records 
    * @author Vipul Goyal | 09-20-2023 
    * @param prodIds 
    * @param materialCodes 
    * @return List<Product_Sales__c> 
    **/
    public static List<Product_Sales__c> getProductSales(Set<String> prodIds, List<String> materialCodes){
        return ECOM_ProductRepo.getProductSales(prodIds, materialCodes);
    } 
    
    /**
    * @description  fetch cms url for a given part number 
    * @author Vasudev R | 11-27-2023 
    * @param productCode 
    * @param userLocale 
    * @return String 
    **/
    public static String getCmsPdpUrl(String productCode, String userLocale){
        String cmsPdpUrl = '';
        List<Product2> productsList = ECOM_ProductRepo.getProductDisplayUrlForProductCode(productCode);
        if(null != productsList && !productsList.isEmpty()){
            String displayUrl = productsList[0].DisplayUrl;
            String cmsBaseUrl = ECOM_Util.getCmsBaseUrl(ECOM_Constant.SITE_MODULE_NAME_FOR_BASE_URL, userLocale);
            cmsPdpUrl = cmsBaseUrl + displayUrl;
        }
        return cmsPdpUrl;
    }   
	
    /**
    * @description This method returns the list of product information based on prodIds
    * @author sveeraraghavan@rafter.one | 11 Jun 2024
    * @param productIds | Set<String> 
    * @return List<Product2> 
    **/
    public static List<Product2> getProductTnCById(Set<String> productIds){
        return ECOM_productRepo.getProductTnCById(productIds);
    }
    /**
    * @description This method returns the punchout maintainence tab Include and exclude fields where clause
    * @author poonam.shukla@revvity.com | 01-03-2025
    * @param includeQuery | String , excludeQuery | String
    * @return Map<String, String>
    **/
   public static Map<String, String> buildCustomProductQueryForQuickOrderPunchout(String includeQuery, String excludeQuery) {
       Map<String, String> queryMap = new Map<String, String>();
       String processedIncludeQuery = processWhereClause(includeQuery);
       String processedExcludeQuery = processWhereClause(excludeQuery);
       List<String> parts = new List<String>();
       List<String> excludeParts = new List<String>();
       List<String> finalExcludeParts = new List<String>();
       String resultIncludeQuery ='';
       String resultExcludeQuery ='';
       String partNumberCondition = '';
       if (processedIncludeQuery != null && processedIncludeQuery.trim() != '') {
            parts = processedIncludeQuery.split('(?i)\\sOR\\s');
            for (Integer i = 0; i < parts.size(); i++) {
                parts[i] = parts[i].trim(); 
                if (parts[i].contains('Part_Number__c')) {
                    partNumberCondition = parts[i];  
                    parts.remove(i);  
                    i--;  
                }
            }
        resultIncludeQuery =  String.join(parts, ' OR ');
       }
        if (processedExcludeQuery != null && processedExcludeQuery.trim() != '') {
            excludeParts = processedExcludeQuery.split('(?i)\\sOR\\s');
            for (Integer i = 0; i < excludeParts.size(); i++) {
                excludeParts[i] = excludeParts[i].trim(); 
                finalExcludeParts.add(excludeParts[i]);
            }
            resultExcludeQuery =  String.join(finalExcludeParts, ' AND ');
        }

       queryMap.put('IncludePartNumberWhereClause', partNumberCondition);
       queryMap.put('IncludeWhereClause', resultIncludeQuery);
       queryMap.put('ExcludeWhereClause', resultExcludeQuery=='' ? processedExcludeQuery : resultExcludeQuery);
       return queryMap; 
    }

    /**
    * @description This method returns the punchout maintainence tab Include and exclude fields where clause radioactive, pac code, partnumber, productline
    * @author poonam.shukla@revvity.com | 01-03-2025
    * @param query | String
    * @return String
    **/
    private static String processWhereClause(String query) {
        if (String.isEmpty(query)) {
            return '';
        }
        Pattern wherePattern = Pattern.compile('(?i)\\bwhere\\b'); 
        Matcher matcher = wherePattern.matcher(query);
        String whereClause = '';
        if (matcher.find()) {
            whereClause = query.substring(matcher.end()).trim();
        }
        else {
            return '';
        }
        Map<String, String> replacements=new Map<String, String>{
            'PartNumber' => 'Part_Number__c',
            'PacCode' => 'IGOR_PAC__c',
            'ProductLine' => 'Product_Line__c'
        };
        for (String key : replacements.keySet()) {
            Pattern pattern = Pattern.compile('(?i)\\b' + key + '\\b'); 
            Matcher keyMatcher = pattern.matcher(whereClause);
            whereClause = keyMatcher.replaceAll(replacements.get(key));
        }
        Map<String, String> radioactiveReplacements = new Map<String, String>{
            '(?i)Radioactive\\s?=\\s?true'   => 'Dangerous_Goods_Indicator_Profile__c IN (\'Yes\', \'Y\', \'RAD\')',
                '(?i)Radioactive\\s?!=\\s?false' => 'Dangerous_Goods_Indicator_Profile__c NOT IN (\'Yes\', \'Y\', \'RAD\')',//For Exclude query ticket RWPS-2132
                '(?i)Radioactive\\s?=\\s?false'  => 'Dangerous_Goods_Indicator_Profile__c NOT IN (\'Yes\', \'Y\', \'RAD\')',
                '(?i)Radioactive\\s?!=\\s?true'  => 'Dangerous_Goods_Indicator_Profile__c IN (\'Yes\', \'Y\', \'RAD\')' //For Exclude query ticket-RWPS-2132
        };
        for (String pattern : radioactiveReplacements.keySet()) {
            whereClause = whereClause.replaceAll(pattern, radioactiveReplacements.get(pattern));
        }
        return whereClause;
	}

    
    /**
    * @description This method returns part number from excludeQuery in list 
    * @author Poonam Shukla | 01-10-2025
    * @param excludeQuery | String
    * @return List<String> 
    **/
    public static List<String> extractPartNumbers(String excludeQuery) {
        List<String> partNumbers = new List<String>();
        if(excludeQuery==null){
            return partNumbers;
        }
        Pattern partNumberPattern = Pattern.compile('\'([^\']+)\'');
        Matcher m = partNumberPattern.matcher(excludeQuery);
        while (m.find()) {
            partNumbers.add(m.group(1)); 
        }
        return partNumbers;
    }

    /**
    * @description This function is used to retrieve the products based on the partial product codes.
    * @author Sidak Singh | 04-16-2024
    * @author Sidak Singh | 09-09-2024 | RWPS-1477
    * @author Sidak Singh | 10-15-2024 | RWPS-1582
    * @param partNumber | String
    * @param excludedItems | List<String>
    * @param materialCodes | List<String>
    * @param communityId | String
    * @param isPunchoutCart | boolean
    * @return List<Product_Sales__c>
    **/
public static List<Product_Sales__c> getProductsBasedOnPartialPartNumber(String partNumber, List<String> excludedItems,
    List<String> materialCodes, String communityId, Boolean isPunchoutCart)
    {
        User us = new ECOM_UserService().getUserByUserId();
        //RWPS-4759 - Start
        String salesOrg;
        if (us != null && us.Contact != null && us.Contact.Default_Ship_to_ERP_Address__r != null && us.Contact.Default_Ship_to_ERP_Address__r.Master_Address__r.Dealer_Type__c != null && us.Contact.Default_Ship_to_ERP_Address__r.Master_Address__r.Dealer_Type__c.equalsIgnoreCase(ECOM_Constant.DEALER_IDENTIFICATION_VALUE)) {
            salesOrg = us.Contact.Default_Ship_to_ERP_Address__r.fxAddress_CountryCode__c != null ? ECOM_CustomMetadataService.getSalesOrg(us.Contact.Default_Ship_to_ERP_Address__r.fxAddress_CountryCode__c) : null;
        } else {
            salesOrg = ECOM_CustomMetadataService.getSalesOrg(ECOM_Util.getCountryFromUser(us));
        }
        //RWPS-4759 - End
        //Changes for RWPS-2829 Start
        List<String> accIdList = new List<String>{us.AccountId.toString()};
        List<Account> account = ECOM_AccountRepo.getAccountBasedOnIds(accIdList);
        String currencyCode = account[0].CurrencyIsoCode;
         //Changes for RWPS-2829 End
        String webstoreId = ECOM_Util.resolveCommunityIdToWebstoreId(communityId);
        List<WebStoreCatalog> prodCatalog = [SELECT ProductCatalogId FROM WebStoreCatalog WHERE SalesStoreId =: webstoreId];
        partNumber +='%';
        Id catalogId= prodCatalog[0].ProductCatalogId;
        String baseQuery = 'SELECT Id FROM Product2 WHERE IsActive = true AND Part_Number__c LIKE :partNumber AND  Id IN (SELECT Product2Id FROM PricebookEntry WHERE CurrencyIsoCode =: currencyCode) AND Id IN (SELECT ProductId FROM ProductCategoryProduct WHERE CatalogId =: catalogId)';        
        // RWPS- 1456 START
        if (isPunchoutCart)
        {   
            //RWPS-5774 Start
            Map<String, String> querybuilder = new Map<String, String>();
            Punchout_Maintenance__c punchoutConfig;
            String masterAddressId = us.Contact?.Default_Ship_to_ERP_Address__r?.Master_Address__c;
            List<Punchout_Maintenance__c> punchoutConfigs = ERP_AddressRepo.getPunchoutConfigs(null,new Set<Id>{us.AccountId},null,masterAddressId);
            punchoutConfig = punchoutConfigs.isEmpty() ? null : punchoutConfigs[0];
            if (punchoutConfig != null && 
            (String.isNotBlank(punchoutConfig.ECOM_Punchout_Products_Exclude_Query__c) || 
            String.isNotBlank(punchoutConfig.ECOM_Punchout_Products_Include_Query__c)))
            {   
                String excludeQuery = String.isNotBlank(punchoutConfig.ECOM_Punchout_Products_Exclude_Query__c)
                ? punchoutConfig.ECOM_Punchout_Products_Exclude_Query__c
                : '';
                String includeQuery =String.isNotBlank(punchoutConfig.ECOM_Punchout_Products_Include_Query__c)
                ? punchoutConfig.ECOM_Punchout_Products_Include_Query__c
                : '';
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
                        List<Product2> excludeProds = ECOM_ProductRepo.getProductsBasedOnQuery(baseQuery, partNumber, currencyCode, catalogId);
                        return ECOM_ProductRepo.getProductSales(salesOrg, materialCodes, excludeProds);
                    }
                }
                //include query
                productSalesList = getFilteredProductSales(baseQuery, partnumber, currencyCode, catalogId, includeWhereClause, includePartNumberWhereClause, salesOrg, materialCodes);
                return productSalesList;
            }
            List<Product2> prods = ECOM_ProductRepo.getProductsBasedOnQuery(baseQuery, partNumber, currencyCode, catalogId);
            return ECOM_ProductRepo.getProductSales(salesOrg,materialCodes,prods); 
        }
        else
        {//non punchout user
            List<Product2> prods = ECOM_ProductRepo.getProductsBasedOnQuery(baseQuery, partNumber, currencyCode, catalogId);
            return ECOM_ProductRepo.getProductSales(salesOrg,materialCodes,prods);
        }// RWPS- 1456 END
    }


    /**
    * @description This method returns the filtered list of Products for Include and Exclude query configured for Punxhot user
    * @author Poonam Shukla | 2-2-2025
    * @param baseQuery | String, partnumber | String , currencyCode | String , catalogId | String , includeWhereClause | String , includePartNumberWhereClause | String , salesOrg | String,  materialCodes | List<String>
    * @return List<Product_Sales__c>
    **/ 
    public static List<Product_Sales__c> getFilteredProductSales(String baseQuery, String partnumber, String currencyCode, Id catalogId, String includeWhereClause, String includePartNumberWhereClause, String salesOrg, List<String> materialCodes) 
    {
        List<String> partNumbers = new List<String>(); 
        List<Product_Sales__c> productSalesList = new List<Product_Sales__c>();
        if(!String.isBlank(includeWhereClause))
        {   
            String includePartNumber = '';
            String zcIncludePartNumber = '';
            if (!String.isBlank(includePartNumberWhereClause)) 
            {
                List<String> customMaterialCode = ECOM_CartUtil.fetchProductMaterialStatus(ECOM_Constant.PUNCHOUT_CUSTOM_MATERIAL_CODE);
                String partNumbersString = includePartNumberWhereClause.substring(includePartNumberWhereClause.indexOf('(') + 1, includePartNumberWhereClause.indexOf(')')); 
                List<String> partNumbersRaw = partNumbersString.split(',');
                for (String pn : partNumbersRaw) {
                    partNumbers.add(pn.trim().replace('\'', '')); 
                }
                List<Product_Sales__c> zcProducts =new List<Product_Sales__c>();
                if (partNumbers != null && !partNumbers.isEmpty() && customMaterialCode != null && !customMaterialCode.isEmpty()) {
                    zcProducts = ECOM_ProductRepo.getZCProducts(salesOrg, customMaterialCode, partNumbers);
                }
                List<String> zcPartNumbers = new List<String>();
                for (Product_Sales__c zcProduct : zcProducts) {
                    zcPartNumbers.add(zcProduct.Product__r.Part_Number__c);
                }
            	List<String> filteredPartNumbers = new List<String>();
                for (String pn : partNumbers) {
                if (!zcPartNumbers.contains(pn.trim())) {
                            filteredPartNumbers.add(pn.trim());
                    }
                }
                if (filteredPartNumbers.size() > 0) {
                    includePartNumber = 'Part_Number__c IN (\'' + String.join(filteredPartNumbers, '\', \'') + '\')';}
                if(zcPartNumbers.size() > 0){ 
                    zcIncludePartNumber = 'Part_Number__c IN (\'' + String.join(zcPartNumbers, '\', \'') + '\')';
                }
                if (zcPartNumbers.isEmpty()) {
                    baseQuery += ' AND (' + includeWhereClause + ' OR ' + includePartNumberWhereClause +' )';       
                    //include partnumber and other conditions
                    List<Product2> partProds = ECOM_ProductRepo.getProductsBasedOnQuery(baseQuery, partnumber, currencyCode, catalogId);
                    productSalesList = ECOM_ProductRepo.getProductSales(salesOrg,materialCodes,partProds);
                }
                else
                {
                    if(String.isBlank(includePartNumber) && !String.isBlank(zcIncludePartNumber))
                    {
                        String baseQuery1 = baseQuery +' AND (' + zcIncludePartNumber + ')';
                        //include only ZC partnumber
                        List<Product2> inclusionProds = ECOM_ProductRepo.getProductsBasedOnQuery(baseQuery1, partnumber, currencyCode, catalogId);
                        baseQuery += ' AND (' + includeWhereClause +' )';
                        //include other conditions
                        List<Product2> partProds = ECOM_ProductRepo.getProductsBasedOnQuery(baseQuery, partnumber, currencyCode, catalogId);
                        productSalesList = ECOM_ProductRepo.getZCProductSalesWithMaterialCodes(salesOrg, materialCodes, customMaterialCode, partProds, inclusionProds);
                    }
                }
                return  productSalesList;  
            }
            else
            {   baseQuery += ' AND (' + includeWhereClause +' )';   
                //include other conditions
                List<Product2> includeProds = ECOM_ProductRepo.getProductsBasedOnQuery(baseQuery, partnumber, currencyCode, catalogId);
                return ECOM_ProductRepo.getProductSales(salesOrg,materialCodes,includeProds);
            }
        }
        else if(!String.isBlank(includePartNumberWhereClause))
        {	
            List<String> customMaterialCode = ECOM_CartUtil.fetchProductMaterialStatus('ECOM_Punchout_Custom');
            List<Product_Sales__c> zcProducts = new List<Product_Sales__c>();
            String partNumbersString = includePartNumberWhereClause.substring(includePartNumberWhereClause.indexOf('(') + 1, includePartNumberWhereClause.indexOf(')')); 
            List<String> partNumbersRaw = partNumbersString.split(',');
            for (String pn : partNumbersRaw) {
                partNumbers.add(pn.trim().replace('\'', '')); 
            }
            if (partNumbers != null && !partNumbers.isEmpty() && customMaterialCode != null && !customMaterialCode.isEmpty()) {
                zcProducts = ECOM_ProductRepo.getZCProducts(salesOrg, customMaterialCode, partNumbers);
            }
            if(zcProducts.size() == 0)
            {
                string nonZCbaseQuery= '';                    
                nonZCbaseQuery += baseQuery + ' AND (' + includePartNumberWhereClause + ')';
                //Query contains only Partnumber no other condition, in partnumber if zc partnumber is empty
                List<Product2> partProds =ECOM_ProductRepo.getProductsBasedOnQuery(nonZCbaseQuery, partnumber, currencyCode, catalogId);
                productSalesList = ECOM_ProductRepo.getProductSales(salesOrg, materialCodes, partProds);
            }
            else
            {
                //no zc only normal catalog part numbers
                List<Product2> prods = ECOM_ProductRepo.getProductsBasedOnQuery(baseQuery, partnumber, currencyCode, catalogId);
                String zcBaseQuery = baseQuery +' AND (' + includePartNumberWhereClause + ')';
                List<Product2> inclusionProds = ECOM_ProductRepo.getProductsBasedOnQuery(zcBaseQuery, partnumber, currencyCode, catalogId);
                productSalesList = ECOM_ProductRepo.getZCProductSalesWithMaterialCodes(salesOrg, materialCodes, customMaterialCode, prods, inclusionProds);
            }
        }   
        return productSalesList;
    }

    /**
    * @description This method returns excluded product for logged in Punchout user
    * @author Poonam Shukla | 01-10-2025
    * @param communityId | String, partNumberList | List<String>
    * @return List<String> 
    **/
   public static List<String> getExcludedPartNumbers(String communityId, List<String> partNumberList) {
   try{   
        User us = new ECOM_UserService().getUserByUserId();
        String salesOrg = ECOM_CustomMetadataService.getSalesOrg(ECOM_Util.getCountryFromUser(us));
        //Changes for RWPS-2740 Start
        List<String> accIdList = new List<String>{us.AccountId.toString()};
        List<Account> account = ECOM_AccountRepo.getAccountBasedOnIds(accIdList);
        String currencyCode = account[0].CurrencyIsoCode;
         //Changes for RWPS-2740 End
        String webstoreId = ECOM_Util.resolveCommunityIdToWebstoreId(communityId);        
        List<WebStoreCatalog> prodCatalog = [SELECT ProductCatalogId FROM WebStoreCatalog WHERE SalesStoreId =: webstoreId];
        Id catalogId= prodCatalog[0].ProductCatalogId;
        List<Product_Sales__c> productSalesList = new List<Product_Sales__c>();
        String baseQuery = 'SELECT Id, Part_Number__c FROM Product2 WHERE IsActive = true  AND  Id IN (SELECT Product2Id FROM PricebookEntry WHERE CurrencyIsoCode =: currencyCode) AND Id IN (SELECT ProductId FROM ProductCategoryProduct WHERE CatalogId =: catalogId)';        
        List<String> materialCodes = new List<String>();
        materialCodes = ECOM_CartUtil.fetchProductMaterialStatus('ECOM_Punchout');
        //RWPS-5774 Start
        String masterAddressId = us.Contact?.Default_Ship_to_ERP_Address__r?.Master_Address__c;
        List<Punchout_Maintenance__c> punchoutConfigs = ERP_AddressRepo.getPunchoutConfigs(null, new Set<Id>{us.AccountId}, null, masterAddressId);
        Punchout_Maintenance__c punchoutConfig = punchoutConfigs.isEmpty() ? null : punchoutConfigs[0];
        Map<String, String> querybuilder = new Map<String, String>();
        List<Product2> excludeProds=new List<Product2>();
        String queryPartNumber= '' ;
        //RWPS-2972 Start
        List<String> productSalesPartNumbers = new List<String>();  // To store part numbers from product sales
        List<String> partNumbersFoundInSales = new List<String>();  // To store part numbers found in sales
        List<String> partNumbers = new List<String>();
        for (String pno : partNumberList) {
            String partNumber = pno;  // Retrieve PartNumber
            if (String.isNotBlank(partNumber)) {
                    partNumbers.add(partNumber);  // Add part number to the list
            }
        }//RWPS-2972 End
        if (punchoutConfig != null && 
                (String.isNotBlank(punchoutConfig.ECOM_Punchout_Products_Exclude_Query__c) || 
                String.isNotBlank(punchoutConfig.ECOM_Punchout_Products_Include_Query__c)))
        {   
            String excludeQuery = String.isNotBlank(punchoutConfig.ECOM_Punchout_Products_Exclude_Query__c)
                    ? punchoutConfig.ECOM_Punchout_Products_Exclude_Query__c
                    : '';
            String includeQuery = String.isNotBlank(punchoutConfig.ECOM_Punchout_Products_Include_Query__c)
                    ? punchoutConfig.ECOM_Punchout_Products_Include_Query__c
                    : '';          
            //RWPS-5774 End
            querybuilder = ECOM_ProductService.buildCustomProductQueryForQuickOrderPunchout(includeQuery , excludeQuery);
            String includeWhereClause = querybuilder.get('IncludeWhereClause');
            String excludeWhereClause = querybuilder.get('ExcludeWhereClause'); 
            String includePartNumberWhereClause = querybuilder.get('IncludePartNumberWhereClause');
            if (!String.isBlank(excludeWhereClause)) {
                if (String.isEmpty(includeWhereClause)) {
                    //RWPS- 2367 Start
                    List<String> excludeConditions = excludeWhereClause.split('AND');
                    for (Integer i = 0; i < excludeConditions.size(); i++) {
                        if (excludeConditions[i].toLowerCase().contains('not in') && !excludeConditions[i].contains('Dangerous_Goods_Indicator_Profile__c')) {
                            excludeConditions[i] = excludeConditions[i].replaceAll('(?i)(?<![a-zA-Z_])not In(?![a-zA-Z_])', 'IN');
                        }
                        //RWPS-2390 Start
                        else if (excludeConditions[i].contains('Dangerous_Goods_Indicator_Profile__c')) {
                           // If it contains 'IN', replace it with 'NOT IN'
                           if (excludeConditions[i].toLowerCase().contains('in') && !excludeConditions[i].toLowerCase().contains('not in')) {
                               excludeConditions[i] = excludeConditions[i].replaceAll('(?i)(?<![a-zA-Z_])in(?![a-zA-Z_])', 'NOT IN');
                           }
                           // If it contains 'NOT IN', replace it with 'IN'
                           else if (excludeConditions[i].toLowerCase().contains('not in')) {
                               excludeConditions[i] = excludeConditions[i].replaceAll('(?i)(?<![a-zA-Z_])not In(?![a-zA-Z_])', 'IN');
                           }
                       }//RWPS-2390 End
                        else
                           excludeConditions[i] = excludeConditions[i].trim();
                    }
                    String updatedWhereClause = String.join(excludeConditions, ' OR ');//RWPS-2390
                    baseQuery += ' AND ('  + updatedWhereClause + ' ) ';//RWPS-2367 End
                    //get only excluded partnumbers
                    excludeProds = ECOM_ProductRepo.getProductsBasedOnQuery(baseQuery, queryPartNumber, currencyCode, catalogId);
                    productSalesList = ECOM_ProductRepo.getProductSales(salesOrg, materialCodes, excludeProds);
                    List<String> customMaterialCode = ECOM_CartUtil.fetchProductMaterialStatus('ECOM_Punchout_Custom');
                    //get zc partnumbers if present in excel
                    List<Product_Sales__c> productZCSalesList = ECOM_ProductRepo.getZCProducts(salesOrg, customMaterialCode, partNumberList);                
                    for (Product_Sales__c ps : productSalesList) {
                        productSalesPartNumbers.add(ps.Product__r.Part_Number__c);
                    }
                    for (Product_Sales__c pzc : productZCSalesList) {
                        productSalesPartNumbers.add(pzc.Product__r.Part_Number__c);
                    }
                    // Filter out found part productSalesPartNumbers
                    for (String partNumber : partNumbers) {
                        if (productSalesPartNumbers.contains(partNumber)) {
                            partNumbersFoundInSales.add(partNumber);
                        }
                    }   
                    return partNumbersFoundInSales;//RWPS-2367 
                 }
             }
             //RWPS-2390 Start
             List<String> quotedPartNumbers = new List<String>();
             for (String pno : partNumberList) {
                quotedPartNumbers.add('\'' + pno + '\''); // Add single quotes around each part number
             }
             String excelPartNumbersString = String.join(quotedPartNumbers, ',');
             baseQuery += ' AND Part_Number__c in ( '+ excelPartNumbersString +' )';
             //RWPS-2390 End
             //for Include Where clause get Product Sales list
             productSalesList = getFilteredProductSales(baseQuery, '', currencyCode, catalogId, includeWhereClause, includePartNumberWhereClause, salesOrg, materialCodes);
             if (!String.isBlank(includeWhereClause) || !String.isBlank(includePartNumberWhereClause)) {//RWPS-2390
                List<Product2> productList = new List<Product2>();
                List<String> notFoundPartNumbers = new List<String>(); 
                Set<String> foundPartNumbers = new Set<String>(); 
                Boolean containsZCInFound = false;//check if a ZC part number exists in found list RWPS-2390
                for (Product_Sales__c ps : productSalesList) {
                   if (ps.Distribution_ChainSpecificMaterialStatus__c == 'ZC' && !containsZCInFound)
                   {
                       containsZCInFound = true;//Set flag to true if ZC part numbers are found RWPS-2390 
                   }
                   productSalesPartNumbers.add(ps.Product__r.Part_Number__c); // list of all query defined products
                }          
                for (String partNumber : partNumbers) {
                    if (!productSalesPartNumbers.contains(partNumber)) {
                        notFoundPartNumbers.add(partNumber); // those defined in the excel but not part of query
                    } 
                }
                if (containsZCInFound && notFoundPartNumbers.isEmpty()) { //If ZC part numbers exist in the found list, clear the notFoundPartNumbers list and return it RWPS-2390
                    return new List<String>();
                }
                return notFoundPartNumbers; // If atleast one product in excel is not defined as part of query
             }
             return new List<String>();
         }
         else
         {
            //RWPS-2972 Start When no query is configured and adding ZC product is not allowed
            List<String> customMaterialCode = ECOM_CartUtil.fetchProductMaterialStatus(ECOM_Constant.PUNCHOUT_CUSTOM_MATERIAL_CODE);
            List<Product_Sales__c> productZCSalesList = ECOM_ProductRepo.getZCProducts(salesOrg, customMaterialCode, partNumberList);                
            for (Product_Sales__c pzc : productZCSalesList) {
                productSalesPartNumbers.add(pzc.Product__r.Part_Number__c);
            }
            for (String partNumber : partNumbers) {
                if (productSalesPartNumbers.contains(partNumber)) {
                    partNumbersFoundInSales.add(partNumber);
                }
            }          
            return partNumbersFoundInSales;//RWPS-2972 end
         }
         }catch(Exception ex){
             ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.USER_MODULE_NAME, 'ECOM_ProductService', 'getExcludedPartNumbers', '');//RWPS-1456
             return new List<String>();
         }
    }
    
    /**
    * @description This method return recently Purchased Products based on the user.
    * @author prabhat.kumar4@rzensar.com | 28 Mar 2025
    * @return Map<String, Object> 
    * @param String communityId
    * @param String userId
    **/
    public static Map<String,Object> getRecentlyPurchasedProducts(String communityId, String userId) {
        Map<String,Object> response = new Map<String,Object>();
        Set<String> productIds = new Set<String>();
        User us = ECOM_UserRepo.getUserByUserId(userId);// RWPS-3023
        Boolean isPunchoutCart = us?.ECOM_Is_Punchout_User__c;
        String supportData = us.contactId;
        Map<String, OrderItem> productToOrderItemMap = new Map<String, OrderItem>(); // RWPS-4147
        Map<String, SAP_Order_Items__c> productToSAPSummaryOrderItemMap = new Map<String, SAP_Order_Items__c>(); // RWPS-4147
        Map<String,Id> materialToProductId = new Map<String,Id>(); // RWPS-4147
        try {
            if(!isPunchoutCart)
            {
                //RWPS-5507 - Start
                List<String> poTypesList = new List<String>();
                List<C_META_Storefront_Configuration__mdt> storeFrontConfigurations = ECOM_CustomMetadataRepo.fetchStoreConfigMdtBasedOnModuleName('POTypesWeb');
                if (storeFrontConfigurations.isEmpty() == false && storeFrontConfigurations[0].Value__c != null) {
                    poTypesList = storeFrontConfigurations[0].Value__c.split(',');
                }
                // Query OrderItem sorted by CreatedDate DESC to get latest first
                List<OrderItem> orderItemList = ECOM_OrderRepo.getOrderItems(us.contactId, poTypesList);
                //RWPS-5507 - End
                // Map to store the latest OrderItem per Product2Id
                for (OrderItem item : orderItemList) {
                    if (!productToOrderItemMap.containsKey(item.Product2Id) || 
                        item.CreatedDate > productToOrderItemMap.get(item.Product2Id).CreatedDate) {
                        productToOrderItemMap.put(item.Product2Id, item);
                    }
                    productIds.add(item.Product2Id);
                }
            }
            else // RWPS-4147 - Start
            {
                // Query SAP Order Summary records sorted by actual_Order_Date__c DESC to get latest first
                Set<String> materialNumbers = new Set<String>();
                List<String> emails = new List<String>();
                emails.add(us.Email);
                //RWPS-5507 - Start
                  //RWPS-5777 start
                String masterId = us?.Contact?.Default_Ship_to_ERP_Address__r?.Master_Address__c;
                Map<String, String> emailMap = ECOM_Util.getPunchoutEmailDetails(masterId);

                String additionalEmails = emailMap.get('additionalEmails');
                String selectedEmailType = emailMap.get('selectedEmailType');
                //RWPS-5777 end
                List<String> alternateEmailList = new List<String>();
                if (String.isNotBlank(additionalEmails)) {
                    for (String email : additionalEmails.split(',')) {
                        email = email.trim();
                        if (String.isNotBlank(email)) {
                            alternateEmailList.add(email);
                        }
                    }
                }
                List<String> orderTypesList = new List<String>();
                List<String> poTypesList = new List<String>();
                List<C_META_Storefront_Configuration__mdt> storeFrontConfigurations = ECOM_CustomMetadataRepo.fetchStoreConfigMdtBasedOnModuleName('POTypesPunchout');
                storeFrontConfigurations.add(ECOM_CustomMetadataRepo.fetchStoreConfigMdtBasedOnModuleName('PunchoutOrderTypes')[0]);
                poTypesList = storeFrontConfigurations[0].Value__c.split(',');
                orderTypesList = storeFrontConfigurations[1].Value__c.split(',');
                List<SAP_Order_Summary__c> sapOrderSummaryList = ECOM_SAPOrderSummaryRepo.fetchSAPOrders(emails, selectedEmailType, alternateEmailList, orderTypesList,
                    poTypesList, ECOM_Constant.RECENTLY_PURCHASED_PRODUCTS, true, null, null);
                //RWPS-5507 - End
                for(SAP_Order_Summary__c rec:sapOrderSummaryList){
                    for(SAP_Order_Items__c sapOrderItem : rec.SAP_Order_Items__r)
                    {
                        if (!productToSAPSummaryOrderItemMap.containsKey(sapOrderItem.Material_Number__c) ||
                        sapOrderItem.CreatedDate > productToSAPSummaryOrderItemMap.get(sapOrderItem.Material_Number__c).CreatedDate)
                        {
                            productToSAPSummaryOrderItemMap.put(sapOrderItem.Material_Number__c, sapOrderItem);
                        }
                        materialNumbers.add(sapOrderItem.Material_Number__c);
                    }
                }
                List<Product2> productsIdSet = ECOM_ProductRepo.getProductsBasedOnPartNumber(new List<String>(materialNumbers));
                for(Product2 rec:productsIdSet){
                    productIds.add(rec.Id);
                    materialToProductId.put(rec.Part_Number__c,rec.Id);
                }
            }
            // RWPS-4147 - End

            List<String> materialCodes = new List<String>();
            if (isPunchoutCart == true) {
                materialCodes = ECOM_CartUtil.fetchProductMaterialStatus('ECOM_Punchout');
            } else {
                materialCodes = ECOM_CartUtil.fetchProductMaterialStatus('ECOM_CartService');
            }

            // Fetch all Product_Sales__c records
            List<Product_Sales__c> allProducts = ECOM_ProductUtil.getProudctSalesByProductIds(productIds, materialCodes, communityId, isPunchoutCart,userId);// RWPS-3023
            Map<String, Product_Sales__c> productSalesMap = new Map<String, Product_Sales__c>();
            Map<String, Product_Sales__c>  productCodeToSalesMap = new Map<String,Product_Sales__c>(); //RWPS-4147
            for (Product_Sales__c ps : allProducts) {
                productSalesMap.put(ps.Product__c, ps); // Map Product__c to Product_Sales__c
                productCodeToSalesMap.put(ps.Product__r.Part_Number__c,ps); //RWPS-4147
            }
             // Build sorted list based on OrderItem CreatedDate
             List<Product_Sales__c> recentlyOrderedProducts = new List<Product_Sales__c>();//RWPS-6212
            // Create a list of Product2Ids sorted by CreatedDate
            List<String> sortedProductIds = new List<String>();
            if(!productToOrderItemMap.isEmpty())
            {
                for (OrderItem oi : productToOrderItemMap.values()) {
                    if (productSalesMap.containsKey(oi.Product2Id)) {
                        sortedProductIds.add(oi.Product2Id);
                    }
                }
            }  
            // RWPS-4147 - Start
            if(!productToSAPSummaryOrderItemMap.isEmpty())
            {
                for (SAP_Order_Items__c rec : productToSAPSummaryOrderItemMap.values()) {
                    if (productCodeToSalesMap.containsKey(rec.Material_Number__c) && materialToProductId.containsKey(rec.Material_Number__c)) {
                        sortedProductIds.add(materialToProductId.get(rec.Material_Number__c));
                    }
                }
            }  
            // RWPS-4147 - End
            
            
           // RWPS-6212 - Start - Get limit from custom metadata for recently ordered items
            Integer recently_ordered_productLimit = 6; // Default fallback
            List<C_META_Storefront_Configuration__mdt> configs = ECOM_CustomMetadataRepo.fetchStoreConfigMdtBasedOnModuleName('Recently_Ordered_Max_Items');

            if (!configs.isEmpty() && String.isNotBlank(configs[0].Value__c)) {
                recently_ordered_productLimit = Integer.valueOf(configs[0].Value__c);
               }
            // RWPS-6212 - End
            for (String prodId : sortedProductIds) {
                if (recentlyOrderedProducts.size() <recently_ordered_productLimit ) {//RWPS-6212
                    recentlyOrderedProducts.add(productSalesMap.get(prodId));//RWPS-6212
                } else {
                    break;
                }
            }
    
            response.put('success', true);
            response.put('products', recentlyOrderedProducts);//RWPS-6212
        } catch (Exception ex) {
            response.put('success', false);
            response.put('message', ex.getMessage());
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.USER_MODULE_NAME, 'ECOM_ProductService', 'getRecentlyPurchasedProducts', supportData);
        }
        return response;
    }
}