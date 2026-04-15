public without sharing class ECOM_TestRecommendations {
    public static final String COMMUNITY_ID = '0DBHs000000Ckk5OAC';

    public static final List<String> INCLUDED_ORDER_TYPES = new List<String>{
        'ZEDI', 'ZECC', 'ZCND', 'ZSTD', 'ZWEB', 'ZWCC', 'ZGNA'
    };

    public static final List<String> INCLUDED_COUNTRIES = new List<String>{
        'AU', 'AT', 'BE', 'CA', 'DK', 'FI', 'FR', 'DE', 'IE', 'IT', 'LU', 'NL', 'NO', 'ES', 'SE', 'CH', 'GB', 'US'
    };

    public static final List<String> EXCLUDED_PAYERS_NUMBERS = new List<String>{
        '4702906', '4734664', '4528645', '4740457', '4677641', '4702014', '4704153', '4742924', '4538246', '4638856',
        '4002180', '4535382', '4567394', '4661595', '4597811', '4652636', '4687880', '4525329', '4037773', '4630404',
        '4688165', '4666302', '4687982', '4637177', '4693473', '4040539', '4623311', '4741007', '4009814', '4647008',
        '4738132', '4660882', '4613041', '4637876', '4644256', '4676520', '4710536', '4728900', '4747723', '4754129',
        '4034231', '4555875', '4688056', '4017445', '4685795', '4000739', '4605851', '4660638', '4748364', '4047410',
        '4685885', '4001749', '4006593', '4057230', '4566939', '4634549', '4641380', '4689942', '4600259', '4742685',
        '4048279', '4045849', '4048176', '4603931', '4734202', '4514373', '4542390', '4563359', '4573033', '4599300',
        '4682444', '4575737', '4615473', '4595326', '4598111', '4726403', '4034570', '4751892', '4734252', '4739062',
        '4741032', '4685024'
    };

    public static final List<String> EXCLUDED_EMAIL_DOMAINS = new List<String>{
        'THERMOFISHER.COM', 'REVVITY.COM', 'NETASCIENTIFIC.COM', 'AVANTORSCIENCES.COM', 'BIOPROCURE.COM',
        'ZAGENO.COM', 'QUARTZY.COM', 'AMICIPROCUREMENT.COM', 'PERKINELMER.COM', 'CITY-LAB.FI',
        'PEPOLSKA.PL', 'VWR.COM', 'GOVSCI.COM'
    };

    public static List<RecommendationsSortingWrapper> filterRecommendations(List<RecommendationsSortingWrapper> recommendations, String salesOrg, Boolean prodIdIsPn) {
        List<String> materialCodes = ECOM_CartUtil.fetchProductMaterialStatus('ECOM_CartService');

        Id catalogId = ECOM_ProductUtil.getCatalogueId(COMMUNITY_ID);
        C_META_Countries__mdt currencyData = ECOM_CustomMetadataRepo.getCurrencyCodeFromSalesOrg(salesOrg);

        String currencyCode = currencyData != null ? currencyData.CurrencyISOCode__c : null;
        if(String.isBlank(currencyCode)) { return new List<RecommendationsSortingWrapper>(); }

        List<String> productIds = new List<String>();

        for(Integer i = 0; i < recommendations.size(); i++) {
            productIds.add((String) recommendations[i].record.get('prodId'));
        }

        List<Product2> productList;

        if(prodIdIsPn) {
            productList = [SELECT Id FROM Product2 WHERE IsActive = true AND Part_Number__c IN :productIds AND Id IN (SELECT Product2Id FROM PricebookEntry WHERE CurrencyIsoCode =: currencyCode) AND Id IN (SELECT ProductId FROM ProductCategoryProduct WHERE CatalogId =: catalogId)];
        } else {
            productList = [SELECT Id FROM Product2 WHERE IsActive = true AND Id IN :productIds AND Id IN (SELECT Product2Id FROM PricebookEntry WHERE CurrencyIsoCode =: currencyCode) AND Id IN (SELECT ProductId FROM ProductCategoryProduct WHERE CatalogId =: catalogId)];
        }

        if (productList.isEmpty()) { return new List<RecommendationsSortingWrapper>(); }
        List<Product_Sales__c> sellable = ECOM_ProductRepo.getProductSales(salesOrg, materialCodes, productList);
        Map<String, Boolean> sellableMap = new Map<String, Boolean>();
        for(Product_Sales__c ps : sellable) {
            if(prodIdIsPn) {
                sellableMap.put(ps.Product__r.Part_Number__c, true);
            } else {
                sellableMap.put(ps.Product__c, true);
            }
        }

        List<RecommendationsSortingWrapper> filteredRecommendations = new List<RecommendationsSortingWrapper>();
        for(RecommendationsSortingWrapper rec : recommendations) {
            String prodId = (String) rec.record.get('prodId');
            if(sellableMap.containsKey(prodId)) {
                filteredRecommendations.add(rec);
            }
        }

        return filteredRecommendations;
    }

    public static List<RecommendationsSortingWrapper> getSellableRecommendations(List<RecommendationsSortingWrapper> recommendations, List<String> productIds, String salesOrg) {
        List<Product_Sales__c> sellable = ECOM_CartController.getSellableProducts(productIds, salesOrg, COMMUNITY_ID);

        Map<String, Boolean> sellableMap = new Map<String, Boolean>();
        for(Product_Sales__c ps : sellable) {
            sellableMap.put(ps.Product__r.Part_Number__c, true);
        }

        List<RecommendationsSortingWrapper> filteredRecommendations = new List<RecommendationsSortingWrapper>();
        for(RecommendationsSortingWrapper rec : recommendations) {
            String prodId = (String) rec.record.get('prodId');
            if(sellableMap.containsKey(prodId)) {
                filteredRecommendations.add(rec);
            }
        }

        return filteredRecommendations;
    }

    public class RecommendationsSortingWrapper implements Comparable {

        public Map<String,Object> record;

        public RecommendationsSortingWrapper(Map<String,Object> record) {
            this.record = record;
        }

        private Integer compareDecimals(Decimal a, Decimal b, Boolean isAscending) {
            if (a > b) return isAscending ? 1 : -1;
            if (a < b) return isAscending ? -1 : 1;
            return 0;
        }

        public Integer compareTo(Object compareTo) {
            RecommendationsSortingWrapper compareToMap = (RecommendationsSortingWrapper)compareTo;

            Integer compareResult = 0;

            compareResult = compareDecimals((Decimal) record.get('score'), (Decimal) compareToMap.record.get('score'), false);
            if (compareResult != 0) {
                return compareResult;
            }

            compareResult = compareDecimals((Decimal) record.get('sameOrderCount'), (Decimal) compareToMap.record.get('sameOrderCount'), false);
            if (compareResult != 0) {
                return compareResult;
            }

            compareResult = compareDecimals((Decimal) record.get('count'), (Decimal) compareToMap.record.get('count'), false);
            if (compareResult != 0) {
                return compareResult;
            }

            compareResult = compareDecimals((Decimal) record.get('recency'), (Decimal) compareToMap.record.get('recency'), true);
            if (compareResult != 0) {
                return compareResult;
            }

            String prodId = (String) record.get('prodId');
            String compareToProdId = (String) compareToMap.record.get('prodId');
            return prodId.compareTo(compareToProdId);
        }
    }

    @AuraEnabled
    public static Map<String, Object> getProductRecommendations(List<String> productIds, Map<String, Object> configuration) {
        Decimal recencyFactor = 200;
        if(configuration.containsKey('recencyFactor')) {
            recencyFactor = (Decimal) configuration.get('recencyFactor');
        }

        Decimal steepnessFactor = 30;
        if(configuration.containsKey('steepnessFactor')) {
            steepnessFactor = (Decimal) configuration.get('steepnessFactor');
        }

        Integer maxRecs = 20;
        if(configuration.containsKey('maxRecs')) {
            maxRecs = Integer.valueOf(configuration.get('maxRecs'));
        }

        Integer samplesetSize = maxRecs * 10;
        if(configuration.containsKey('samplesetSize')) {
            samplesetSize = Integer.valueOf(configuration.get('samplesetSize'));
        }

        Decimal sameOrderBoost = 100;
        if(configuration.containsKey('sameOrderBoost')) {
            sameOrderBoost = (Decimal) configuration.get('sameOrderBoost');
        }

        Boolean disableMultiProductSOB = false;
        if(configuration.containsKey('disableMultiProductSOB')) {
            disableMultiProductSOB = (Boolean) configuration.get('disableMultiProductSOB');
        }

        Datetime startDate = DateTime.newInstance(0);
        if(configuration.containsKey('startDate')) {
            startDate = DateTime.newInstance(Long.valueOf((String) configuration.get('startDate')));
        }

        Datetime endDate = System.now();
        if(configuration.containsKey('endDate')) {
            endDate = Datetime.newInstance(Long.valueOf((String) configuration.get('endDate')));
        }

        String salesOrg = null;
        if(configuration.containsKey('salesOrg')) {
            salesOrg = (String) configuration.get('salesOrg');
        }

        List<Product2> baseProducts = ECOM_ProductRepo.getProductsByIds(new Set<String>(productIds));

        Map<String, Object> returnMap = new Map<String, Object>{
            'configuration' => new Map<String, Object>{
                'recencyFactor' => recencyFactor,
                'steepnessFactor' => steepnessFactor,
                'maxRecs' => maxRecs,
                'samplesetSize' => samplesetSize,
                'sameOrderBoost' => sameOrderBoost,
                'disableMultiProductSOB' => disableMultiProductSOB,
                'startDate' => startDate,
                'endDate' => endDate,
                'salesOrg' => salesOrg
            },
            'baseProducts' => baseProducts
        };

        if(baseProducts.isEmpty()) {
            return returnMap;
        }

        Set<Id> contactIds = new Set<Id>();
        Map<String, Set<String>> baseProductOrders = new Map<String, Set<String>>();
        for (OrderItem oi : [
            SELECT Order.CustomerAuthorizedById, OrderId, Product2Id
            FROM OrderItem
            WHERE Product2Id IN :productIds
                AND Order.CustomerAuthorizedById != null
                AND Product2.Part_Number__c != null
                AND Order.Status != 'Cancelled'
                AND Order.ECOM_Order_Summary_Status__c != 'Cancelled'
                AND Order.CreatedDate >= :startDate
                AND Order.CreatedDate <= :endDate
        ]) {
            contactIds.add(oi.Order.CustomerAuthorizedById);
            if(!baseProductOrders.containsKey(oi.OrderId)) {
                baseProductOrders.put(oi.OrderId, new Set<String>{oi.Product2Id});
            } else {
                baseProductOrders.get(oi.OrderId).add(oi.Product2Id);
            }
        }
        if(contactIds.isEmpty()) {
            return returnMap;
        }

        List<AggregateResult> recommendations = [
            SELECT Product2Id prodId, COUNT_DISTINCT(OrderId) ct
            FROM OrderItem
            WHERE Order.CustomerAuthorizedById IN :contactIds
                AND Product2Id NOT IN :productIds
                AND Product2.Part_Number__c != null
                AND Order.Status != 'Cancelled'
                AND Order.ECOM_Order_Summary_Status__c != 'Cancelled'
                AND Order.CreatedDate >= :startDate
                AND Order.CreatedDate <= :endDate
            GROUP BY Product2Id
            ORDER BY COUNT_DISTINCT(OrderId) DESC, MAX(CreatedDate) DESC
            LIMIT :samplesetSize
        ];
        if(recommendations.isEmpty()) {
            return returnMap;
        }

        List<String> recommendationProductIds = new List<String>();
        for (AggregateResult ar : recommendations) {
            recommendationProductIds.add((String)ar.get('prodId'));
        }

        List<AggregateResult> orderItems = [
            SELECT OrderId, Product2Id pid, MAX(Order.CreatedDate) oiDate
            FROM OrderItem
            WHERE Product2Id IN :recommendationProductIds
                AND Order.CustomerAuthorizedById IN :contactIds
                AND Order.Status != 'Cancelled'
                AND Order.ECOM_Order_Summary_Status__c != 'Cancelled'
                AND Order.CreatedDate >= :startDate
                AND Order.CreatedDate <= :endDate
            GROUP BY OrderId, Product2Id
        ];
        if(orderItems.isEmpty()) {
            return returnMap;
        }

        Decimal sameOrderBoostFactor = sameOrderBoost / 100;

        Map<String, Map<String, Object>> recencyMap = new Map<String, Map<String, Object>>();
        Long currentTime = endDate.getTime();

        for(AggregateResult oi : orderItems) {
            String prodIdKey = (String) oi.get('pid');
            Decimal recencyValue = Decimal.valueOf(currentTime - ((Datetime) oi.get('oiDate')).getTime()) / (1000 * 60 * 60 * 24);

            Decimal exponent = (recencyValue - recencyFactor) / steepnessFactor;
            Decimal score = 1 / (1 + Math.exp(exponent));

            Integer sameOrderCount = 0;
            if(baseProductOrders.containsKey((String) oi.get('OrderId'))) {
                if(disableMultiProductSOB) {
                    sameOrderCount = 1;
                } else {
                    sameOrderCount = baseProductOrders.get((String) oi.get('OrderId')).size();
                }

                score += score * sameOrderBoostFactor * sameOrderCount;
            }

            if(!recencyMap.containsKey(prodIdKey)) {
                recencyMap.put(prodIdKey, new Map<String, Object>{
                    'recency' => recencyValue,
                    'count' => 1,
                    'score' => score,
                    'prodId' => prodIdKey,
                    'sameOrderCount' => sameOrderCount
                });
            } else {
                Map<String, Object> existingData = recencyMap.get(prodIdKey);

                Integer oldCount = (Integer) existingData.get('count');
                Integer newCount = oldCount + 1;
                Decimal newRecency = ((Decimal) existingData.get('recency') * oldCount + recencyValue) / newCount;

                existingData.put('count', newCount);
                existingData.put('recency', newRecency);
                existingData.put('score', (Decimal) existingData.get('score') + score);
                existingData.put('sameOrderCount', (Integer) existingData.get('sameOrderCount') + sameOrderCount);
            }
        }

        List<RecommendationsSortingWrapper> finalRecommendations = new List<RecommendationsSortingWrapper>();

        for(AggregateResult ar : recommendations) {
            String prodId = (String) ar.get('prodId');

            if(!recencyMap.containsKey(prodId)) {
                continue;
            }

            Map<String, Object> recencyData = recencyMap.get(prodId);

            finalRecommendations.add(new RecommendationsSortingWrapper(recencyData));
        }

        if(String.isNotBlank(salesOrg)) {
            finalRecommendations = filterRecommendations(finalRecommendations, salesOrg, false);
        }

        finalRecommendations.sort();

        List<Map<String, Object>> topRecommendations = new List<Map<String, Object>>();
        Set<String> uniqueProductIds = new Set<String>();

        for(Integer i = 0; i < Math.min(maxRecs, finalRecommendations.size()); i++) {
            Map<String,Object> record = finalRecommendations[i].record;
            String prodId = (String) record.get('prodId');

            topRecommendations.add(record);
            uniqueProductIds.add(prodId);
        }

        List<Product2> products = ECOM_ProductRepo.getProductsByIds(uniqueProductIds);
        Map<String, Product2> productMap = new Map<String, Product2>();
        for(Product2 product : products) {
            productMap.put(product.Id, product);
        }
        for(Map<String, Object> rec : topRecommendations) {
            String prodId = (String) rec.get('prodId');
            if(productMap.containsKey(prodId)) {
                Product2 productRecord = productMap.get(prodId);

                rec.put('product', productRecord);

                System.debug('Recommendation: ' + productRecord.Part_Number__c + ', Name: ' + productRecord.Name + ', count: ' + rec.get('count') + ', recency: ' + rec.get('recency') + ', score: ' + rec.get('score'));
            } else {
                rec.put('product', null);
            }
        }

        returnMap.put('recommendations', topRecommendations);
        return returnMap;
    }

    @AuraEnabled
    public static Map<String, Object> getProductRecommendationsSAP(List<String> productIds, Map<String, Object> configuration) {
        Decimal recencyFactor = 200;
        if(configuration.containsKey('recencyFactor')) {
            recencyFactor = (Decimal) configuration.get('recencyFactor');
        }

        Decimal steepnessFactor = 30;
        if(configuration.containsKey('steepnessFactor')) {
            steepnessFactor = (Decimal) configuration.get('steepnessFactor');
        }

        Integer maxRecs = 20;
        if(configuration.containsKey('maxRecs')) {
            maxRecs = Integer.valueOf(configuration.get('maxRecs'));
        }

        Integer samplesetSize = maxRecs * 10;
        if(configuration.containsKey('samplesetSize')) {
            samplesetSize = Integer.valueOf(configuration.get('samplesetSize'));
        }

        Decimal sameOrderBoost = 100;
        if(configuration.containsKey('sameOrderBoost')) {
            sameOrderBoost = (Decimal) configuration.get('sameOrderBoost');
        }

        Boolean disableMultiProductSOB = false;
        if(configuration.containsKey('disableMultiProductSOB')) {
            disableMultiProductSOB = (Boolean) configuration.get('disableMultiProductSOB');
        }

        Datetime startDate = DateTime.newInstance(0);
        if(configuration.containsKey('startDate')) {
            startDate = DateTime.newInstance(Long.valueOf((String) configuration.get('startDate')));
        }

        Datetime endDate = System.now();
        if(configuration.containsKey('endDate')) {
            endDate = Datetime.newInstance(Long.valueOf((String) configuration.get('endDate')));
        }

        String salesOrg = null;
        if(configuration.containsKey('salesOrg')) {
            salesOrg = (String) configuration.get('salesOrg');
        }

        Boolean internalUse = false;
        if(configuration.containsKey('internalUse')) {
            internalUse = (Boolean) configuration.get('internalUse');
        }

        List<Product2> baseProducts = ECOM_ProductRepo.getProductsByIds(new Set<String>(productIds));

        Map<String, Object> returnMap = new Map<String, Object>{
            'configuration' => new Map<String, Object>{
                'recencyFactor' => recencyFactor,
                'steepnessFactor' => steepnessFactor,
                'maxRecs' => maxRecs,
                'samplesetSize' => samplesetSize,
                'sameOrderBoost' => sameOrderBoost,
                'disableMultiProductSOB' => disableMultiProductSOB,
                'startDate' => startDate,
                'endDate' => endDate,
                'salesOrg' => salesOrg
            },
            'baseProducts' => baseProducts
        };

        if(baseProducts.isEmpty()) {
            return returnMap;
        }
        List<String> baseProductPartNumbers = new List<String>();
        for(Product2 product : baseProducts) {
            baseProductPartNumbers.add(product.Part_Number__c);
        }

        Set<String> contactIds = new Set<String>();
        Map<String, Set<String>> baseProductOrders = new Map<String, Set<String>>();
        for (SAP_Order_Items__c oi : [
            SELECT PKI_Order_Summary__r.Sold_To_Customer_Id__c, PKI_Order_Summary__r.Bill_To_Customer_Id__c, PKI_Order_Summary__r.Contact_Email__c, PKI_Order_Summary__r.Name, Material_Number__c
            FROM SAP_Order_Items__c
            WHERE Material_Number__c IN :baseProductPartNumbers
                AND PKI_Order_Summary__r.Sold_To_Customer_Id__c != null
                AND PKI_Order_Summary__r.fxStatusB2B__c != 'Cancelled'
                AND PKI_Order_Summary__r.CreatedDate >= :startDate
                AND PKI_Order_Summary__r.CreatedDate <= :endDate
        ]) {
            String billToCustomerId = oi.PKI_Order_Summary__r.Bill_To_Customer_Id__c;
            if(String.isNotBlank(billToCustomerId)) {
                billToCustomerId = billToCustomerId.replaceFirst('^0+', '');
                if(EXCLUDED_PAYERS_NUMBERS.contains(billToCustomerId)) {
                    continue;
                }
            }

            String customerEmail = oi.PKI_Order_Summary__r.Contact_Email__c;
            if(String.isNotBlank(customerEmail)) {
                List<String> customerEmailSplit = customerEmail.split('@');
                if(customerEmailSplit.size() > 1) {
                    customerEmail = customerEmailSplit[1];
                    if(EXCLUDED_EMAIL_DOMAINS.contains(customerEmail.toUpperCase())) {
                        continue;
                    }
                }
            }

            contactIds.add(oi.PKI_Order_Summary__r.Sold_To_Customer_Id__c);
            String orderNumber = oi.PKI_Order_Summary__r.Name;
            if(!baseProductOrders.containsKey(orderNumber)) {
                baseProductOrders.put(orderNumber, new Set<String>{oi.Material_Number__c});
            } else {
                baseProductOrders.get(orderNumber).add(oi.Material_Number__c);
            }
        }
        if(contactIds.isEmpty()) {
            return returnMap;
        }

        // returnMap.put('contactIds', contactIds);

        List<AggregateResult> recommendations = [
            SELECT Material_Number__c prodId, COUNT_DISTINCT(PKI_Order_Summary__r.Name) ct
            FROM SAP_Order_Items__c
            WHERE PKI_Order_Summary__r.Sold_To_Customer_Id__c IN :contactIds
                AND Material_Number__c NOT IN :baseProductPartNumbers
                AND Material_Number__c != null
                AND PKI_Order_Summary__r.fxStatusB2B__c != 'Cancelled'
                AND PKI_Order_Summary__r.Sold_To_Address_Country__c IN :INCLUDED_COUNTRIES
                AND PKI_Order_Summary__r.Source_Type__c IN :INCLUDED_ORDER_TYPES
                AND PKI_Order_Summary__r.CreatedDate >= :startDate
                AND PKI_Order_Summary__r.CreatedDate <= :endDate
            GROUP BY Material_Number__c
            ORDER BY COUNT_DISTINCT(PKI_Order_Summary__r.Name) DESC, MAX(CreatedDate) DESC
            LIMIT :samplesetSize
        ];
        if(recommendations.isEmpty()) {
            return returnMap;
        }

        List<String> recommendationProductIds = new List<String>();
        for (AggregateResult ar : recommendations) {
            recommendationProductIds.add((String)ar.get('prodId'));
        }

        List<AggregateResult> orderItems = [
            SELECT PKI_Order_Summary__r.Name order_number, Material_Number__c pid, MAX(PKI_Order_Summary__r.CreatedDate) oiDate
            FROM SAP_Order_Items__c
            WHERE Material_Number__c IN :recommendationProductIds
                AND PKI_Order_Summary__r.Sold_To_Customer_Id__c IN :contactIds
                AND PKI_Order_Summary__r.fxStatusB2B__c != 'Cancelled'
                AND PKI_Order_Summary__r.CreatedDate >= :startDate
                AND PKI_Order_Summary__r.CreatedDate <= :endDate
            GROUP BY PKI_Order_Summary__r.Name, Material_Number__c
        ];
        if(orderItems.isEmpty()) {
            return returnMap;
        }

        Decimal sameOrderBoostFactor = sameOrderBoost / 100;

        Map<String, Map<String, Object>> recencyMap = new Map<String, Map<String, Object>>();
        Long currentTime = endDate.getTime();

        Map<String, Set<String>> recommendationOrders = new Map<String, Set<String>>();

        for(AggregateResult oi : orderItems) {
            String prodIdKey = (String) oi.get('pid');
            Decimal recencyValue = Decimal.valueOf(currentTime - ((Datetime) oi.get('oiDate')).getTime()) / (1000 * 60 * 60 * 24);

            Decimal exponent = (recencyValue - recencyFactor) / steepnessFactor;
            Decimal score = 1 / (1 + Math.exp(exponent));

            String orderNumber = (String) oi.get('order_number');
            if(!recommendationOrders.containsKey(prodIdKey)) {
                recommendationOrders.put(prodIdKey, new Set<String>());
            }
            recommendationOrders.get(prodIdKey).add(orderNumber);

            Integer sameOrderCount = 0;
            if(baseProductOrders.containsKey(orderNumber)) {
                if(disableMultiProductSOB) {
                    sameOrderCount = 1;
                } else {
                    sameOrderCount = baseProductOrders.get(orderNumber).size();
                }

                score += score * sameOrderBoostFactor * sameOrderCount;
            }

            if(!recencyMap.containsKey(prodIdKey)) {
                recencyMap.put(prodIdKey, new Map<String, Object>{
                    'recency' => recencyValue,
                    'count' => 1,
                    'score' => score,
                    'prodId' => prodIdKey,
                    'sameOrderCount' => sameOrderCount
                });
            } else {
                Map<String, Object> existingData = recencyMap.get(prodIdKey);

                Integer oldCount = (Integer) existingData.get('count');
                Integer newCount = oldCount + 1;
                Decimal newRecency = ((Decimal) existingData.get('recency') * oldCount + recencyValue) / newCount;

                existingData.put('count', newCount);
                existingData.put('recency', newRecency);
                existingData.put('score', (Decimal) existingData.get('score') + score);
                existingData.put('sameOrderCount', (Integer) existingData.get('sameOrderCount') + sameOrderCount);
            }
        }

        List<RecommendationsSortingWrapper> finalRecommendations = new List<RecommendationsSortingWrapper>();
        Set<String> uniqueProductIds = new Set<String>();

        for(AggregateResult ar : recommendations) {
            String prodId = (String) ar.get('prodId');

            if(!recencyMap.containsKey(prodId)) {
                continue;
            }

            Map<String, Object> recencyData = recencyMap.get(prodId);

            uniqueProductIds.add(prodId);
            finalRecommendations.add(new RecommendationsSortingWrapper(recencyData));
        }

        List<Product2> products = [SELECT Id, Name, Part_Number__c, DisplayUrl FROM Product2 WHERE Part_Number__c IN : uniqueProductIds];

        List<String> productSfId = new List<String>();
        Map<String, Product2> productMap = new Map<String, Product2>();
        for(Product2 product : products) {
            productMap.put(product.Part_Number__c, product);
            productSfId.add(product.Id);
        }

        if(internalUse) {
            if(String.isNotBlank(salesOrg)) {
                finalRecommendations = filterRecommendations(finalRecommendations, salesOrg, true);
            }
        } else {
            finalRecommendations = getSellableRecommendations(finalRecommendations, productSfId, salesOrg);
        }

        finalRecommendations.sort();

        List<Map<String, Object>> topRecommendations = new List<Map<String, Object>>();

        List<String> debugArray = new List<String>();
        String basePartNumbersString = String.join(baseProductPartNumbers, ', ');

        for(Integer i = 0; i < Math.min(maxRecs, finalRecommendations.size()); i++) {
            Map<String,Object> record = finalRecommendations[i].record;
            String prodId = (String) record.get('prodId');

            if(productMap.containsKey(prodId)) {
                Product2 productRecord = productMap.get(prodId);

                record.put('product', productRecord);

                // System.debug('Recommendation: ' + productRecord.Part_Number__c + ', Name: ' + productRecord.Name + ', count: ' + rec.get('count') + ', recency: ' + rec.get('recency') + ', score: ' + rec.get('score'));

                // System.debug(String.join(baseProductPartNumbers, ', ') + '\t ' + productRecord.Part_Number__c + '\t ' + ((Decimal) rec.get('score')).setScale(2) + '\t ' + rec.get('count') + '\t ' + String.join(recommendationOrders.get(prodId), ', '));
                debugArray.add(String.join(new List<String>{
                    basePartNumbersString,
                    productRecord.Part_Number__c,
                    ((Decimal) record.get('score')).setScale(2).format(),
                    String.valueOf(record.get('sameOrderCount')),
                    String.valueOf(record.get('count')),
                    String.join(recommendationOrders.get(prodId), ', ')
                }, '\t'));
            } else {
                record.put('product', null);
            }

            topRecommendations.add(record);
        }

        returnMap.put('debugArray', String.join(debugArray, '\n'));

        returnMap.put('recommendations', topRecommendations);
        return returnMap;
    }

    @AuraEnabled
    public static Map<String,Object> getCustomersAlsoBought(List<String> productIdentifiers, Map<String, Object> configuration){
        productIdentifiers = ECOM_ProductRecommendationsUtil.getProductDataByCommonModel(new Set<String>(productIdentifiers)).get('productIds');
        return ECOM_ProductRecommendationsService.getCustomersAlsoBought(productIdentifiers, configuration);

        // List<String> productIdentifiers = new List<String>{'3018-0010'};
        // Map<String, Object> configuration =
        //     new Map<String, Object> {
        //         'startDate' => '2023-01-01',
        //         'endDate' => '2025-02-01',
        //         'maxRecsToReturn' => 10
        //     };

    //     Map<String,Object> trainedData = ECOM_ProductRecommendationsService.getCustomersAlsoBought(productIdentifiers, configuration);

    //     List<String> sortedProductIds = (List<String>) trainedData.get('sortedProductIds');
    //     Map<String,Product2> productIdMap = (Map<String,Product2>) trainedData.get('productIdMap');

    //     List<String> baseProductPartNumbers = new List<String>();
    //     for(String i : productIdentifiers) {
    //         Product2 p = productIdMap.get(i);
    //         baseProductPartNumbers.add(p.Part_Number__c);
    //     }
    //     Date startDate = Date.valueOf('2025-02-01');
    //     Date endDate = Date.valueOf('2025-05-23');

    //     Map<String,String> configMap = ECOM_CustomMetadataRepo.getRecommendationsConfig();
    //     Map<String, Object> parameters = (Map<String, Object>) JSON.deserializeUntyped(configMap.get('Recommendation_Parameters'));
    //     List<String> includedOrderTypes = configMap.get('Included_Order_Types').split(',');
    //     List<String> includedCountries = configMap.get('Included_Countries').split(',');
    //     List<String> excludedPayers = configMap.get('Excluded_Payers').split(',');
    //     List<String> excludedEmailDomains = configMap.get('Excluded_Email_Domains').split(',');

    //     Set<String> soldToNumbers = new Set<String>();
    //     Map<String, Set<String>> baseProductOrders = new Map<String, Set<String>>();

    //     for (
    //         SAP_Order_Items__c oi : [
    //             SELECT PKI_Order_Summary__r.Sold_To_Customer_Id__c, PKI_Order_Summary__r.Bill_To_Customer_Id__c, PKI_Order_Summary__r.Contact_Email__c, PKI_Order_Summary__r.ShipTo_Email__c, PKI_Order_Summary__r.Name, Material_Number__c
    //             FROM SAP_Order_Items__c
    //             WHERE
    //                 Material_Number__c IN :baseProductPartNumbers AND
    //                 PKI_Order_Summary__r.Sold_To_Address_Country__c IN :includedCountries AND
    //                 PKI_Order_Summary__r.Source_Type__c IN :includedOrderTypes AND
    //                 PKI_Order_Summary__r.Sold_To_Customer_Id__c != null AND
    //                 PKI_Order_Summary__r.fxStatusB2B__c != 'Cancelled' AND
    //                 (
    //                     (
    //                         PKI_Order_Summary__r.Actual_Order_Date__c >= :startDate AND
    //                         PKI_Order_Summary__r.Actual_Order_Date__c <= :endDate
    //                     )
    //                     OR
    //                     (
    //                         PKI_Order_Summary__r.Actual_Order_Date__c = null AND
    //                         DAY_ONLY(PKI_Order_Summary__r.CreatedDate) >= :startDate AND
    //                         DAY_ONLY(PKI_Order_Summary__r.CreatedDate) <= :endDate
    //                     )
    //                 )
    //             ORDER BY PKI_Order_Summary__r.Actual_Order_Date__c DESC, PKI_Order_Summary__r.CreatedDate DESC
    //             LIMIT 50000
    //         ]
    //     ) {
    //         String billToCustomerId = oi.PKI_Order_Summary__r.Bill_To_Customer_Id__c;

    //         if(String.isNotBlank(billToCustomerId)) {
    //             billToCustomerId = billToCustomerId.replaceFirst('^0+', '');
    //             if(excludedPayers.contains(billToCustomerId)) { continue; }
    //         }

    //         List<String> emails = new List<String>{
    //             oi.PKI_Order_Summary__r.Contact_Email__c,
    //             oi.PKI_Order_Summary__r.ShipTo_Email__c
    //         };

    //         Boolean skipRecord = false;

    //         for (String email : emails) {
    //             if (String.isNotBlank(email)) {
    //                 Integer atIndex = email.indexOf('@');
    //                 if (atIndex > -1 && atIndex < email.length() - 1) {
    //                     String domain = email.substring(atIndex + 1).toUpperCase();
    //                     if (excludedEmailDomains.contains(domain)) {
    //                         skipRecord = true;
    //                         break;
    //                     }
    //                 }
    //             }
    //         }

    //         if (skipRecord) { continue; }

    //         soldToNumbers.add(oi.PKI_Order_Summary__r.Sold_To_Customer_Id__c);
    //     }

    //     List<String> recParts = new List<String>();

    //     // need to test the output
    //     for(String i : sortedProductIds) {
    //         Product2 p = productIdMap.get(i);
    //         String partNumber = p.Part_Number__c;

    //         recParts.add(partNumber);
    //     }

    //     List<AggregateResult> productGroup = [
    //         SELECT Material_Number__c prodPn, COUNT_DISTINCT(PKI_Order_Summary__r.Name) ct
    //         FROM SAP_Order_Items__c
    //         WHERE
    //             PKI_Order_Summary__r.Sold_To_Customer_Id__c IN :soldToNumbers
    //             AND Material_Number__c IN :recParts
    //             AND Material_Number__c != null
    //             AND PKI_Order_Summary__r.fxStatusB2B__c != 'Cancelled'
    //             AND
    //             (
    //                 (
    //                     PKI_Order_Summary__r.Actual_Order_Date__c >= :startDate AND
    //                     PKI_Order_Summary__r.Actual_Order_Date__c <= :endDate
    //                 )
    //                 OR
    //                 (
    //                     PKI_Order_Summary__r.Actual_Order_Date__c = null AND
    //                     DAY_ONLY(PKI_Order_Summary__r.CreatedDate) >= :startDate AND
    //                     DAY_ONLY(PKI_Order_Summary__r.CreatedDate) <= :endDate
    //                 )
    //             )
    //         GROUP BY Material_Number__c
    //     ];

    //     trainedData.put('periodAccuracy', Decimal.valueOf(productGroup.size())/Decimal.valueOf(recParts.size()));

    //     productGroup = [
    //          SELECT Material_Number__c prodPn, COUNT_DISTINCT(PKI_Order_Summary__r.Name) ct
    //         FROM SAP_Order_Items__c
    //         WHERE
    //             PKI_Order_Summary__r.Sold_To_Customer_Id__c IN :soldToNumbers
    //             AND Material_Number__c IN :recParts
    //             AND Material_Number__c != null
    //             AND PKI_Order_Summary__r.fxStatusB2B__c != 'Cancelled'
    //         GROUP BY Material_Number__c
    //     ];

    //     trainedData.put('totalAccuracy', Decimal.valueOf(productGroup.size())/Decimal.valueOf(recParts.size()));

    //     productGroup = [
    //          SELECT PKI_Order_Summary__r.Sold_To_Customer_Id__c soldTo, COUNT_DISTINCT(Material_Number__c) ct
    //         FROM SAP_Order_Items__c
    //         WHERE
    //             PKI_Order_Summary__r.Sold_To_Customer_Id__c IN :soldToNumbers
    //             AND Material_Number__c IN :recParts
    //             AND Material_Number__c != null
    //             AND PKI_Order_Summary__r.fxStatusB2B__c != 'Cancelled'
    //             AND
    //             (
    //                 (
    //                     PKI_Order_Summary__r.Actual_Order_Date__c >= :startDate AND
    //                     PKI_Order_Summary__r.Actual_Order_Date__c <= :endDate
    //                 )
    //                 OR
    //                 (
    //                     PKI_Order_Summary__r.Actual_Order_Date__c = null AND
    //                     DAY_ONLY(PKI_Order_Summary__r.CreatedDate) >= :startDate AND
    //                     DAY_ONLY(PKI_Order_Summary__r.CreatedDate) <= :endDate
    //                 )
    //             )
    //         GROUP BY PKI_Order_Summary__r.Sold_To_Customer_Id__c
    //     ];

    //     if(productGroup.size() > 0) {
    //         Decimal sum = 0;
    //         for(AggregateResult ar : productGroup) {
    //             sum += (Decimal) ar.get('ct');
    //         }
    //         Decimal avg = sum / productGroup.size();
    //         trainedData.put('periodCustomerLevelAccuracy', avg / recParts.size());
    //     }

    //     productGroup = [
    //          SELECT PKI_Order_Summary__r.Sold_To_Customer_Id__c soldTo, COUNT_DISTINCT(Material_Number__c) ct
    //         FROM SAP_Order_Items__c
    //         WHERE
    //             PKI_Order_Summary__r.Sold_To_Customer_Id__c IN :soldToNumbers
    //             AND Material_Number__c IN :recParts
    //             AND Material_Number__c != null
    //             AND PKI_Order_Summary__r.fxStatusB2B__c != 'Cancelled'
    //         GROUP BY PKI_Order_Summary__r.Sold_To_Customer_Id__c
    //     ];

    //     if(productGroup.size() > 0) {
    //         Decimal sum = 0;
    //         for(AggregateResult ar : productGroup) {
    //             sum += (Decimal) ar.get('ct');
    //         }
    //         Decimal avg = sum / productGroup.size();
    //         trainedData.put('totalCustomerLevelAccuracy', avg / recParts.size());
    //     }

    //     return trainedData;
    }
}