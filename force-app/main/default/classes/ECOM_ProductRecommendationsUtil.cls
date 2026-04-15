/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    RWPS-4437
*
* 2. Description - This class is a service class for Product Recommendations
*
* 3. Objects referenced
*
* 4. Callouts to additional Components (including their methods) or None:
*    None
*
* 5. Dependant Class(es):
*
* 6. Test Class Name:
*    - ECOM_ProductRecommendationsUtil_Test
*
* 7. Is @Invocable: No
*
* 8. Author Name(s):
*    - Abhishek Joshi 2025.09.15 - Created the class - RWPS-4437
*    - Abhishek Joshi 2025.10.29 - Updated method getRecommendations - RWPS-5046
*    - Abhishek Joshi 2025.11.13 - Updated method getRecommendations - RWPS-5223
*************************************************************/

public without sharing class ECOM_ProductRecommendationsUtil {
    public static final String CLASS_NAME = 'ECOM_ProductRecommendationsUtil';

    public static final String CUSTOMERS_ALSO_BOUGHT = 'Companion';

    public static String sellableRecommendationsKey = 'sellableRecommendations';
    public static String sortedProductIdsKey = 'sortedProductIds';
    public static String recommendationsScoreMapKey = 'recommendationsScoreMap';
    public static String productIdMapKey = 'productIdMap';

    public static String emptyKey = '<empty>';

    /**
    * @description This function is used to generate replacement product map
    * @author Abhishek Joshi
    * @param recommendations | Map<String,Object>
    * @param userData | Map<String,Object>
    * @param communityId | String
    * @return Map<String,Object>
    **/
    public static Map<String,Object> getSellableRecommendations(
        Map<String,Object> recommendationsData,
        Map<String,Object> userData,
        String communityId,
        Map<String,Object> config
    ) {
        List<String> unfilteredProductIds = (List<String>) recommendationsData.get(sortedProductIdsKey);
        if(unfilteredProductIds == null || unfilteredProductIds.isEmpty()) {
            recommendationsData.put(sellableRecommendationsKey, new List<String>()); return recommendationsData;
        }
        Set<String> unfilteredProductIdSet = new Set<String>(unfilteredProductIds);

        List<Product_Sales__c> sellableProducts;

        if(userData.containsKey('userId')) {
            sellableProducts =
                ECOM_CartController.getSellableProductsByUser(
                    unfilteredProductIdSet,
                    (String) userData.get('userId'),
                    communityId
                );
        } else {
            List<String> materialCodes = ECOM_CartUtil.fetchProductMaterialStatus('ECOM_CartService');
            sellableProducts = ECOM_ProductUtil.getSellableProductsForGuest(unfilteredProductIdSet, materialCodes, communityId, (String) userData.get('salesOrg'));
        }

        Map<String, Boolean> sellableMap = new Map<String, Boolean>();
        for(Product_Sales__c ps : sellableProducts) {
            sellableMap.put(ps.Product__c, true);
        }

        List<String> filteredProductIds = new List<String>();
        for(String pid : unfilteredProductIds) {
            if(sellableMap.containsKey(pid)) {
                filteredProductIds.add(pid);
            }
        }

        Map<String, Product2> productIdMap;
        if(recommendationsData.containsKey(productIdMapKey)) {
            productIdMap =
                (Map<String, Product2>) recommendationsData.get(productIdMapKey);
        } else {
            List<Product2> filteredProducts = ECOM_ProductRepo.getProductsByIds(new Set<String>(filteredProductIds));
            productIdMap = new Map<String, Product2>();
            for(Product2 p : filteredProducts) {
                productIdMap.put(p.Id, p);
            }
        }

        Boolean maxRecsExist = config.containsKey('maxRecs');
        Integer maxRecs = 0;
        if(maxRecsExist) {
            maxRecs = Integer.valueOf(config.get('maxRecs'));
        }

        Map<String,Boolean> productModelExistsMap = new Map<String,Boolean>();
        List<String> finalFilteredProductIds = new List<String>();
        Integer recsCount = 0;
        for(String pid : filteredProductIds) {
            if(productIdMap.containsKey(pid)) {
                String model = productIdMap.get(pid).Product_Model_Identifier__c;
                if(String.isBlank(model)) {
                    model = pid;
                }
                if(!productModelExistsMap.containsKey(model)) {
                    productModelExistsMap.put(model, true);
                    finalFilteredProductIds.add(pid);
                    recsCount++;
                    if(maxRecsExist && recsCount >= maxRecs) { break; }
                }
            }
        }

        recommendationsData.put(
            sellableRecommendationsKey,
            finalFilteredProductIds
        );
        recommendationsData.put(
            productIdMapKey,
            productIdMap
        );
        return recommendationsData;
    }

    /**
    * @description Method to get product data by common model
    * @author Abhishek Joshi
    * @param productIds | Set<String>
    * @return Map<String,List<String>>
    **/
    public static Map<String,List<String>> getProductDataByCommonModel(Set<String> productIds) {
        List<Product2> products = ECOM_ProductRepo.getProductsByIds(productIds);
        Set<String> models = new Set<String>();

        for(Product2 prod : products){
            if(String.isNotBlank(prod.Product_Model_Identifier__c)) {
                models.add(prod.Product_Model_Identifier__c);
            }
        }
        if(!models.isEmpty()) {
            products = ECOM_ProductRepo.getProductsByProductModelsAndIds(models, productIds);
        }

        List<String> productIdList = new List<String>();
        List<String> partNumberList = new List<String>();
        for(Product2 p : products) {
            productIdList.add(p.Id);
            partNumberList.add(p.Part_Number__c);
        }
        return new Map<String,List<String>>{
            'productIds' => productIdList,
            'partNumbers' => partNumberList
        };
    }

    /**
    * @description Future method for asynchronous refresh of recommendations
    * @author Abhishek Joshi
    * @param productIds | Set<String>
    * @return void
    **/
    @future
    public static void refreshProductRecommendations(Set<String> productIds) {
        String currentBaseProduct = '';

        try{
            List<Product_Recommendation__c> upsertList = new List<Product_Recommendation__c>();
            List<Product_Recommendation__c> deleteList = new List<Product_Recommendation__c>();

            Map<String, List<String>> insertMap = new Map<String, List<String>>();
            Map<String, Map<String,Decimal>> recommendationsScoreMap = new Map<String, Map<String,Decimal>>();
            Map<String,Product2> productIdMap = new Map<String,Product2>();

            for(String productId : productIds) {
                if(Limits.getLimitQueryRows() - Limits.getQueryRows() < 10000) {break;}

                currentBaseProduct = productId;

                Map<String,List<String>> productData = getProductDataByCommonModel(new Set<String>{productId});
                List<String> excludedParts = productData.get('partNumbers');

                List<Product_Recommendation__c> cachedData =
                    ECOM_ProductRecommendationsRepo.getCachedECOMRecommendation(
                        CUSTOMERS_ALSO_BOUGHT, new List<String>{productId}, new List<String>{}
                    );

                Map<String,Product_Recommendation__c> existingCacheMap = new Map<String,Product_Recommendation__c>();

                Boolean skipRefresh = true;
                if(cachedData.size() == 0) {
                    skipRefresh = false;
                }

                for(Product_Recommendation__c crc : cachedData) {
                    if(!crc.Active__c && skipRefresh) {
                        skipRefresh = false;
                    }

                    String suggestedProduct = crc.Product_Suggested__c;
                    if(suggestedProduct == null) {
                        suggestedProduct = emptyKey;
                    }

                    if(existingCacheMap.containsKey(suggestedProduct)) {
                        deleteList.add(crc);
                    } else {
                        existingCacheMap.put(
                            suggestedProduct, crc
                        );
                    }
                }

                if(skipRefresh) { continue; }

                Map<String,Object> unfilteredRecommendations =
                    ECOM_ProductRecommendationsService.getCustomersAlsoBought(
                        new List<String>{productId},
                        new Map<String, Object>{
                            'excludedPartNumbers' => excludedParts
                        }
                    );
                productIdMap.putAll((Map<String,Product2>) unfilteredRecommendations.get(productIdMapKey));

                // update existing recommendations, delete extra ones and add new if needed
                Map<String,Boolean> addedProducts = new Map<String,Boolean>();

                List<String> recommendedProductIds = (List<String>) unfilteredRecommendations.get(sortedProductIdsKey);
                if(recommendedProductIds == null || recommendedProductIds.size() == 0) {
                    recommendedProductIds = new List<String>();
                    addedProducts.put(emptyKey, true);
                } else {
                    recommendationsScoreMap.put(
                        productId,
                        (Map<String,Decimal>) unfilteredRecommendations.get(recommendationsScoreMapKey)
                    );
                }

                insertMap.put(productId, new List<String>());

                for(String pid : recommendedProductIds) {
                    insertMap.get(productId).add(pid);
                    addedProducts.put(pid, true);
                }

                for(
                    Product_Recommendation__c crc : cachedData
                ) {
                    String suggestedProduct = crc.Product_Suggested__c;
                    if(suggestedProduct == null) {
                        suggestedProduct = emptyKey;
                    }

                    if(!addedProducts.containsKey(suggestedProduct)) {
                        deleteList.add(crc);
                    }
                }
            }

            if(!deleteList.isEmpty()) {
                delete deleteList;
            }

            List<Product_Recommendation__c> insertList = createRecommendationsCache(insertMap, recommendationsScoreMap, CUSTOMERS_ALSO_BOUGHT, productIdMap);

            upsertList.addAll(insertList);
            upsert upsertList ExternalId__c;

        } catch(Exception ex) {
            ECOM_ApplicationLogsUtil.logFailure(ex, 'ProductRecommendationsCaching', CLASS_NAME, 'refreshProductRecommendations', currentBaseProduct + ' cache update failed');
        }
    }

    /**
    * @description Add new cache
    * @author Abhishek Joshi
    * @param cacheName | String
    * @param cacheGroup | String
    * @param cacheValue | String
    * @return List<Product_Recommendation__c>
    **/
    public static List<Product_Recommendation__c> createRecommendationsCache(
        Map<String, List<String>> insertMap,
        Map<String, Map<String,Decimal>> recommendationsScoreMap,
        String recommendationType,
        Map<String, Product2> productIdMap
    ) {
        List<Product_Recommendation__c> insertList = new List<Product_Recommendation__c>();

        for(String baseProduct : insertMap.keySet()) {
            if(!productIdMap.containsKey(baseProduct)) {
                continue;
            }

            List<String> productIds = insertMap.get(baseProduct);
            if(productIds.size() == 0) {
                productIds = new List<String>{''};
            }

            for(String pid : productIds) {
                Product_Recommendation__c newCache = new Product_Recommendation__c();
                newCache.Active__c = true;
                newCache.Product_Main__c = baseProduct;
                if(String.isNotBlank(pid)) {
                    newCache.Product_Suggested__c = pid;
                }
                newCache.Suggest_Type__c = recommendationType;
                newCache.Use_Case_Type__c = 'Web';
                newCache.Rank__c =
                    recommendationsScoreMap.containsKey(baseProduct) && recommendationsScoreMap.get(baseProduct).containsKey(pid)
                    	? recommendationsScoreMap.get(baseProduct).get(pid) : 0;

                String recPartNumber = '';
                if(productIdMap.containsKey(pid)) { recPartNumber = productIdMap.get(pid).Part_Number__c; }

                String extId = productIdMap.get(baseProduct).Part_Number__c + '-' + recPartNumber + '-' + recommendationType + '-' + newCache.Use_Case_Type__c;
                if(extId.length() > 50) {
                    extId = extId.substring(0, 49) + '-';
                }

                newCache.ExternalId__c = extId;

                insertList.add(newCache);
            }
        }

        return insertList;

    }

    /**
    * @description Method to get recommendations
    * @author Abhishek Joshi
    * @param productIds | List<String>
    * @param userData | Map<String,Object>
    * @param communityId | String
    * @param config | Map<String,Object>
    * @return Map<String,Object>
    **/
    public static Map<String,Object> getRecommendations(
        List<String> baseProductIds,
        Map<String,Object> userData,
        String communityId,
        Map<String,Object> config
    ) {
        try {
            List<String> requestedIdentifiers = new List<String>();
            requestedIdentifiers.addAll(baseProductIds); //RWPS-5223

            Map<String,List<String>> productDataByModel = getProductDataByCommonModel(new Set<String>(baseProductIds));
            List<String> excludedProductIds = productDataByModel.get('productIds');

            if(!config.containsKey('bypassProductModel')) {
                baseProductIds = excludedProductIds;
            }


            String salesOrg =
                userData.containsKey('salesOrg')
                ? (String) userData.get('salesOrg') : null;
            String userId =
                userData.containsKey('userId')
                ? (String) userData.get('userId') : null;

            List<Product_Recommendation__c> cachedData =
                ECOM_ProductRecommendationsRepo.getCachedECOMRecommendation(
                    CUSTOMERS_ALSO_BOUGHT,
                    baseProductIds,
                    excludedProductIds
                );

            Datetime cutoff =
                Datetime.now().addDays(
                    -1 * Integer.valueOf(System.Label.ECOM_Product_Recommendations_Cache_Life_Days)
                );

            List<String> sortedCacheProdId = new List<String>();
            Map<String, Product2> productIdMap = new Map<String, Product2>();

            Map<String, List<Product_Recommendation__c>> addedProductMap = new Map<String, List<Product_Recommendation__c>>();
            Set<String> outdatedList = new Set<String>();

            for(Product_Recommendation__c crc : cachedData) {
                if(crc.Product_Suggested__c != null) {
                    sortedCacheProdId.add(crc.Product_Suggested__c);
                    productIdMap.put(crc.Product_Suggested__c, crc.Product_Suggested__r);
                }

                if(addedProductMap.containsKey(crc.Product_Main__c)) {
                    addedProductMap.get(crc.Product_Main__c).add(crc);
                } else {
                    addedProductMap.put(
                        crc.Product_Main__c, new List<Product_Recommendation__c>{crc}
                    );
                }

                if(cutoff > crc.LastModifiedDate && crc.Active__c) {
                    outdatedList.add(crc.Product_Main__c);
                }
            }

            Set<String> missingBaseProductIds = new Set<String>();
            for(String pid : baseProductIds) {
                if(!addedProductMap.containsKey(pid)) {
                    missingBaseProductIds.add(pid);
                }
            }

            Set<String> recalculationList = new Set<String>();
            recalculationList.addAll(outdatedList);
            recalculationList.addAll(missingBaseProductIds);

            Map<String, Object> finalReturnData =
                new Map<String,Object>{
                    sellableRecommendationsKey => new List<String>()
                };
            List<Product_Recommendation__c> upsertList = new List<Product_Recommendation__c>();

            if(sortedCacheProdId.size() > 0) {
                finalReturnData =
                    getSellableRecommendations(
                        new Map<String,Object>{
                            sortedProductIdsKey => sortedCacheProdId,
                            productIdMapKey => productIdMap
                        },
                        userData,
                        communityId,
                        config
                    );
            } else if(missingBaseProductIds.size() > 0) {
                Map<String,Object> unfilteredRecommendations =
                    ECOM_ProductRecommendationsService.getCustomersAlsoBought(
                        new List<String>(missingBaseProductIds),
                        new Map<String, Object>{
                            'excludedPartNumbers' => productDataByModel.get('partNumbers'),
                            'requestedIdentifiers' => requestedIdentifiers //RWPS-5223
                        }
                    );

                finalReturnData =
                    getSellableRecommendations(
                        unfilteredRecommendations,
                        userData,
                        communityId,
                        config
                    );

                if(missingBaseProductIds.size() == 1) {
                    recalculationList.removeAll(missingBaseProductIds);

                    String tempId = missingBaseProductIds.iterator().next();

                    List<String> tempRecProdId =
                        (List<String>) unfilteredRecommendations.get(sortedProductIdsKey);

                    if(tempRecProdId == null) {
                        tempRecProdId = new List<String>();
                    }

                    Map<String,Decimal> tempRecScoreMap =
                        (Map<String,Decimal>) unfilteredRecommendations.get(recommendationsScoreMapKey);
                    if(tempRecScoreMap == null) {
                        tempRecScoreMap = new Map<String,Decimal>();
                    }

                    upsertList.addAll(
                        createRecommendationsCache(
                            new Map<String, List<String>>{
                                tempId => tempRecProdId
                            },
                            new Map<String, Map<String,Decimal>>{
                                tempId => tempRecScoreMap
                            },
                            CUSTOMERS_ALSO_BOUGHT,
                            (Map<String, Product2>) unfilteredRecommendations.get(productIdMapKey)
                        )
                    );
                }
            }

            for(String pid : outdatedList) {
                if(addedProductMap.containsKey(pid)) {
                    for(Product_Recommendation__c crc : addedProductMap.get(pid)) {
                        crc.Active__c = false;
                        upsertList.add(crc);
                    }
                }
            }

            if(upsertList.size() > 0) {
                try {
                    upsert upsertList;
                } catch(Exception e) {
                    // do nothing. This may occur due to lock error as cache may be updating in future method
                }
            }

            if(recalculationList.size() > 0) {
                List<Set<String>> recalculationBatches = new List<Set<String>>();
                Set<String> currentBatch = new Set<String>();
                Integer count = 0;
                Integer batchSize = Integer.valueOf(System.Label.ECOM_Product_Recommendations_Future_Batch_Size);
                for(String pid : recalculationList) {
                    currentBatch.add(pid);
                    count++;
                    if(count == batchSize) {
                        recalculationBatches.add(currentBatch);
                        currentBatch = new Set<String>();
                        count = 0;
                    }
                }
                if(currentBatch.size() > 0) {
                    recalculationBatches.add(
                        currentBatch
                    );
                }

                for(Set<String> batch : recalculationBatches) {
                    refreshProductRecommendations(
                        batch
                    );
                }
            }

            return finalReturnData;
        } catch(Exception ex) {
            ECOM_ApplicationLogsUtil.logFailure(
                ex,
                'ProductRecommendationsFetching',
                CLASS_NAME,
                'getRecommendations',
                ex.getMessage() + ' | ' + ex.getStackTraceString() + ' | BaseProductIds: ' + String.join(baseProductIds, ',') + ' | userData: ' + userData.toString() + ' | communityId: ' + communityId + ' | config: ' + config.toString() // RWPS-5046
            );
            return new Map<String,Object>{sellableRecommendationsKey => new List<String>()};
        }
    }
}