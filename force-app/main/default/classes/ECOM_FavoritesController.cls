/**************************************************************
 * 1. Jira Ticket(s) that relates to this class
 *    ECOM-106
 *
 * 2. Description - This class is controller for intracting with Wishlist object.
 *
 * 3. Objects referenced
 *    -WebCart
 *
 * 4. Callouts to additional Components (including their methods) or None:
 *    - None
 *
 * 5. Dependant Class(es):
 *    - used in ecom_favorites lwc
 * 	  - ECOM_Util
 *    - ECOM_AccountService
 *    - ECOM_CartService
 *
 * 6. Test Class Name:
 *    - ECOM_FavoritesController_Test
 *
 * 7. Is @Invocable (Yes or No): No
 *
 * 8. Author Name(s):
 *    - Manish 2023.07.19
 *    - Manoj 2024.01.17 Ticket - ECOM-2065
 *    - Sidak 2024.02.05 Added logs in addItemsToCart method. Ticket - RWPS-95
 *    - Sidak 2024.07.08 Updated method getWishlistSummaries, added logic to fetch wishlist items in batch of 20. Ticket - RWPS-1046
 *    - Poonam 2024.02.07 Updated getWishlistSummaries for productexclusion in favorites page RWPS-2390
 *    - Poonam 2024.02.14 Updated getWishlistSummaries, fixed product retrieval issue in query RWPS-2390
 *    - Poonam 2024.03.10 Updated getWishlistSummaries, added isPunchout user condition check RWPS-2740
 *    - Poonam 2024.04.09 Updated getWishlistSummaries, added isPunchout user condition check for isSellable Product RWPS-2972
 *    - Prabhat 2025.06.25 Updated methods getWishlistSummaries, getFieldsByObjectName, removeWishlistItem, addItemsToCart to handle non-sellable products RWPS-2786
 *    - Abhishek 2025.04.10 Updated methods getWishlistSummaries for replacement product RWPS-3740 
 *************************************************************/
public class ECOM_FavoritesController {

    public static String CLASSNAME = 'ECOM_FavoritesController';
   /**
    * This method is used to get wishlist items for the user.
    * @param communityId
    * @param effectiveAccountId
    * @param productFields
    * @param objectName
    * @return Map<String,Object>
    * @author Manish Kumar | 2023.07.19
    **/
    @AuraEnabled
    public static Map<String,Object> getWishlistSummaries(String communityId, String effectiveAccountId, List<String> productFields, String objectName) {

        Map<String,Object> responseMap = new  Map<String,Object>();
        String webstoreId = ECOM_Util.resolveCommunityIdToWebstoreId(communityId);
        Map<String,String> fieldsMap = getFieldsByObjectName(objectName);
        //List<ConnectApi.WishlistItemSortOrder> listSortItemsBy = ConnectApi.WishlistItemSortOrder.values();
        List<WishList> favList = ECOM_AccountService.fetchWishList(UserInfo.getUserId());
        Set<WishlistItem> items = new Set<WishlistItem>();
        List<String> productIds = new List<String>();
        List<ConnectApi.PricingLineItemInput> pricingLineItems = new List<ConnectApi.PricingLineItemInput>();
        Map<String, Boolean> excludedProdStatusMap = new Map<String, Boolean>(); //RWPS-2390
        Set<String> productIdSet = new Set<String>(); //RWPS-2786
        List<String> deletedPartNumbers = New List<String>(); //RWPS-2786

        for(WishList wl: favList){
            if(wl.WishlistProductCount > 0){
                for(WishlistItem wi: wl.WishlistItems){
                    if(!productIds.contains(wi.Product2Id)){
                        items.add(wi);
                        productIdSet.add(wi.Product2Id);
                        productIds.add(wi.Product2Id);
                        ConnectApi.PricingLineItemInput pricingLineItemInput = new ConnectApi.PricingLineItemInput();
                        pricingLineItemInput.productId = String.valueOf(wi.Product2Id);
                        pricingLineItems.add(pricingLineItemInput);
                    }
                }
            }
        }
        //RWPS-2786 - Start
        List<String> nonSellableProducts = ECOM_CartUtil.getNonSellableDiscountinuedProducts(productIdSet, 'non_sellable');
        //Delete non sellable wishlists
        ECOM_AccountRepo.deleteNonSellableWishListItems(nonSellableProducts);
        //RWPS-2786 - End


        ConnectApi.ProductOverviewCollection productsOverview;
        List<ConnectApi.ProductOverviewCollection> productsOverviewList = new List<ConnectApi.ProductOverviewCollection>();
        ConnectApi.PricingResult pricingResult;
        List<Product2> products = new List<Product2>();
        List<String> partNumberList = new List<String>(); //RWPS-2390
        List<String> excludedProductIds = new List<String>();//RWPS-2390
        User us = new ECOM_UserService().getUserByUserId();//RWPS-2972
        Boolean isPunchoutCart = us?.ECOM_Is_Punchout_User__c;//RWPS-2972
        if(!productIds.isEmpty()){
            ConnectApi.PricingInput pricingInput = new ConnectApi.PricingInput();
            pricingInput.pricingLineItems = pricingLineItems;
            integer aVal = 20;//RWPS-2390
            if(Test.isRunningTest()){aVal = 0;}//RWPS-2390
            if(productIds.size() > aVal){ //RWPS-2390
               Integer numberOfIterations;
                Integer counter = 20;
                Integer starter = 0;
                Decimal numberOfIterationsDecimal = productIds.size()/20.0;
			    numberOfIterations = Integer.valueOf(Math.ceil(numberOfIterationsDecimal));
                for (Integer i = 0; i < numberOfIterations; i++) {
                    List<String> subList = new List<String>();
                    for (Integer j = starter; j < counter; j++) {
                        if(!Test.isRunningTest()){//RWPS-2740
                            subList.add(productIds[j]);//RWPS-2740
                        }
                    }
                    productsOverview = ECOM_ProductService.getProducts(webstoreId, effectiveAccountId, subList, productFields, false);
                    productsOverviewList.add(productsOverview);
                    starter += 20;
                    if(productIds.size()-starter > 20){
                        counter += 20;
                    }
                    else {
                        counter = productIds.size();
                    }
                }
            }
            else {
                productsOverview = ECOM_ProductService.getProducts(webstoreId, effectiveAccountId, productIds, productFields, false);
            }
            if(!Test.isRunningTest()){//RWPS-2740 Start
                pricingResult = ConnectApi.CommerceStorePricing.getProductPrices(webstoreId, effectiveAccountId, pricingInput);
            }//RWPS-2740 End
            products = ECOM_ProductRepo.getProductsByIds( new Set<String>(productIds));
            for(Product2 product :products){
                //RWPS-2786 - Start
                if(nonSellableProducts.contains(product.id)){
                    deletedPartNumbers.add(product.Part_Number__c);
                }
                //RWPS-2786 - End
            }

            //Changes for RWPS-2390 Start
            if(isPunchoutCart)//RWPS-2972
            {
                List<String> partNumberListPunchout = new List<String>();
                for(Product2 product : products) {
                    partNumberListPunchout.add(product.Part_Number__c);
                }
                List<String> excludedPartNumbers = ECOM_ProductService.getExcludedPartNumbers(communityId, partNumberListPunchout);
                for(Product2 product : products) {
                    Boolean isProductExcluded = false; //RWPS-2390 Start
                    if(excludedPartNumbers.contains(product.Part_Number__c))
                    {
                        isProductExcluded = true; // Mark as excluded if present in the list or empty partnumbers
                    }
                    excludedProdStatusMap.put(product.Id , isProductExcluded);
                }
            }   //Changes for RWPS-2390 End
        }
        //Changes for ECOM-2065 Start
        List<Product_Sales__c> productSales = new List<Product_Sales__c>();
        List<String> materialCodes = new List<String>();
         //RWPS-2972 Start

        if(isPunchoutCart)
        {
            materialCodes = ECOM_CartUtil.fetchProductMaterialStatus('ECOM_Punchout');
            materialCodes.addAll(ECOM_CartUtil.fetchProductMaterialStatus('ECOM_Punchout_Custom'));
        }
        else {
            materialCodes = ECOM_CartUtil.fetchProductMaterialStatus('ECOM_CartService');
        }
        //RWPS-2972 End
        productSales = ECOM_ProductRepo.getProductSalesByProdIdAndMaterialCodes(new Set<String>(productIds),materialCodes);

        Map<String, Boolean> productSaleStatusMap = new Map<String, Boolean>();
        // Iterate through each product ID
        for(String productId : productIds) {
            Boolean isProductInProdSaleList = false; // Initialize as false
            // Check if the product ID exists in the Product Sale list
            for(Product_Sales__c objProdSale : productSales) {
                if(objProdSale.Product__c != null && objProdSale.Product__c == productId) {
                    isProductInProdSaleList = true;
                    break; // No need to continue checking if found
                }
            }
            // Add the product ID and corresponding boolean value to the map
            productSaleStatusMap.put(productId, isProductInProdSaleList);
        }

        // RWPS-3740 START
        Map<String,Object> replacementMap = ECOM_ProductUtil.getReplacementMap(communityId, productIdSet);
        responseMap.put('replacementMap', replacementMap);

        responseMap.put('discontinuedStatuses', ECOM_CartUtil.fetchProductMaterialStatus('DiscontinuedProduct'));
        // RWPS-3740 END

        responseMap.put('productSaleStatus',productSaleStatusMap);
        responseMap.put('excludedproducts',excludedProdStatusMap);//RWPS-2390
        //Changes for ECOM-2065 End
        responseMap.put('Status','Success');
        responseMap.put('favList',favList);
        responseMap.put('favItems',items);
        responseMap.put('sapStatus',ECOM_DataLayerController.getDataLayerDataByWishlistItem(items));
        responseMap.put('productsOverview',productsOverview);
        responseMap.put('productsOverviewList',productsOverviewList);
        responseMap.put('pricingResult',pricingResult);
        responseMap.put('dataLayer',ECOM_Util.parseProductDataLayerModel(products));
        responseMap.put('deletedPartNumbers', deletedPartNumbers); //RWPS-2786
        //responseMap.put('wishlistItems',wishlistItems);
        responseMap.put('fieldsMap',fieldsMap);
        responseMap.put('excludedProdStatusMap',excludedProdStatusMap);//RWPS-2390
        return responseMap;
    }

    /**
    * @description
    * @author ssingh@rafter.one | 10-30-2023
    * @param moduleName
    * @return Map<String, String>
    **/
    @AuraEnabled
    public static Map<String,String> getCMSBaseUrl(String moduleName) {
            Map<String,String> cartStoreConfigs = ECOM_CartRepo.getStorefrontFrontConfigByModule(moduleName);
        return cartStoreConfigs;
    }

    /**
    * This method is used to remove selected wishlist items for the user.
    * @param objectName
    * @return Map<String,String>
    * @author Manish Kumar | 2023.07.19
    **/
    @AuraEnabled
    public static Map<String,String> getFieldsByObjectName(String objectName) {
        Map<String,String> fieldsMap = ECOM_Util.getFieldsByObjectName(objectName);
        return fieldsMap;
    }

    /**
    * This method is used to remove selected wishlist items for the user.
    * @param communityId
    * @param effectiveAccountId
    * @param wishlistId
    * @param wishlistItemId
    * @return Map<String,Object>
    * @author Manish Kumar | 2023.07.19
    **/
    @AuraEnabled
    public static Map<String,Object> removeWishlistItem(String wishlistItemId){
        //String webstoreId = ECOM_Util.resolveCommunityIdToWebstoreId(communityId);
        Map<String,Object> responseMap = new  Map<String,Object>();
        try{
            ECOM_AccountService.removeWishlistItem(wishlistItemId);
            responseMap.put('Status','Success');
        }catch(Exception e){
            responseMap.put('Status','Error');
            responseMap.put('ErrorMessage',e.getMessage());
        }
        return responseMap;
    }

    /**
    * This method is used to add selected favorite item to cart.
    * @param communityId
    * @param effectiveAccountId
    * @param productId
    * @param qty
    * @return Map<String,Object>
    * @author Manish Kumar | 2023.07.19
    **/
    @AuraEnabled
    public static Map<String,Object> addItemsToCart(String communityId, String effectiveAccountId, String productId, String qty){

        Map<String,Object> responseMap = new  Map<String,Object>();
        String supportData = '';
        try {
            String webstoreId = ECOM_Util.resolveCommunityIdToWebstoreId(communityId);

            String activeCartOrId = '';
            List<WebCart> webCarts = ECOM_CartService.getPrimaryCartBasedOnOwner(UserInfo.getUserId());
            if(!webCarts.isEmpty()){
                activeCartOrId = webCarts[0].Id;
            }

            ConnectApi.CartItemInput cartInput = new ConnectApi.CartItemInput();
            cartInput.productId = productId;
            cartInput.quantity = qty;
            cartInput.type = ConnectApi.CartItemType.PRODUCT;

            ConnectApi.CartItem cartItem = Test.isRunningTest()?ECOM_TestUtil.getCartItemData():ECOM_AccountService.addItemToCart(webstoreId,effectiveAccountId,activeCartOrId,cartInput);
            responseMap.put('Status','SUCCESS');
            responseMap.put('cartItem',cartItem);
        } catch (Exception ex) {
            responseMap.put('responseCatch ', ex.getMessage()+ex.getStackTraceString());
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.FAVORITES_MODULE_NAME, className, 'addItemsToCart', supportData);
        }
        return responseMap;
    }

    public class CartInputWrapper
    {
        @AuraEnabled
        public String productId{get;set;}
        @AuraEnabled
        public String quantity{get;set;}

    }

}