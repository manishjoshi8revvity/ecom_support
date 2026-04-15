/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*	  - ECOM-1224
*
*
* 2. Description - This is a util class for all requests from frequently purchased products page
* 				 - Returns a map of Products and partNumber information
*
*
* 3. Objects referenced
*    -WebCart
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_FrequentlyPurchasedController
*
* 6. Test Class Name: 
*    - ECOM_TODO
*
* 7. Is @Invocable: No
*
* 8. Author Name(s):
*    - Vasudev Ramachandran 18 Dec 2023
*    - Manoj 2024.09.09 RWPS-1387 read image from Product2.ECOM_Product_Media_URI__c(DAM) instead product media
*************************************************************/
public class ECOM_FrequentlyPurchasedUtil {

    private static final String CLASSNAME = 'ECOM_FrequentlyPurchasedUtil';
    
    /**
     * @description This method returns list of products that have been ordered most 
     * @author vramachandran@rafter.one | 18 Dec 2023
     * @param orderSummaries | List<SAP_Order_Summary__c> 
     * @param accountId | String
     * @returns Map<String, Integer>
     */
    public static ECOM_FrequentlyPurchasedWrapper getFrequentlyPurchasedProductInfo(List<SAP_Order_Summary__c> orderSummaryList, String accountId){
        
        ECOM_FrequentlyPurchasedWrapper productWrapper = new ECOM_FrequentlyPurchasedWrapper();
        
        List<ECOM_FrequentlyPurchasedWrapper.Product> frequentlyPurchasedList = new List<ECOM_FrequentlyPurchasedWrapper.Product>();
        List<SAP_Order_Items__c> orderItemsList = new List<SAP_Order_Items__c>();
        
        Set<String> productMaterialNumberSet = new Set<String>();
        
        Map<String,Integer> productOrderCountMap = new Map<String,Integer>();
        
        try{
            
            productWrapper.products = frequentlyPurchasedList;
                
            //Get order item list
            for(SAP_Order_Summary__c orderSummary : orderSummaryList){
                System.debug('orderSummary:: '+ orderSummary);
                if(null!= orderSummary && null != orderSummary.SAP_Order_Items__r && !orderSummary.SAP_Order_Items__r.isEmpty()){
                    System.debug('orderSummary:: ' + orderSummary.SAP_Order_Items__r);
                    System.debug('orderSummary size:: ' + orderSummary.SAP_Order_Items__r.size());
                     orderItemsList.addAll(orderSummary.SAP_Order_Items__r);
                }
            }
            
            System.debug('oderItemsList:: '+ orderItemsList);
            System.debug('oderItemsList size:: '+ orderItemsList.size());
            
            //iterate order items and get product part number, get map of times product has been ordered 
            for(SAP_Order_Items__c orderItem : orderItemsList){
                String materialNumber = orderItem?.Material_Number__c;
                System.debug('materialNumber::'+ materialNumber);
                productMaterialNumberSet.add(materialNumber);
                
                if(productOrderCountMap.containsKey(materialNumber)){
                    productOrderCountMap.put(materialNumber, productOrderCountMap.get(materialNumber) + 1);
                } else {
                    productOrderCountMap.put(materialNumber, 1);
                }
            }
            
            System.debug('productMaterialNumberSet:: '+ productMaterialNumberSet);
            System.debug('productOrderCountMap:: '+ productOrderCountMap);
            
            if(productMaterialNumberSet != null && !productMaterialNumberSet.isEmpty()){
                List<String> productIds = new List<String>();
                //
                List<Product2> productsList = ECOM_SAPOrderSummaryRepo.getProductDetailsForPartNumbers(productMaterialNumberSet);
                if(null != productsList && !productsList.isEmpty()){
                    for(Product2 prod : productsList){
                        productIds.add(prod.Id);
                    }
                }
                 String webStoreId = ECOM_WebStoreRepo.getWebStoreByName(System.Label.ECOM_WebStore_Name)[0].Id;
                //RWPS-1387
                //ConnectApi.ProductOverviewCollection productsOverview = ECOM_ProductService.getProducts(webstoreId, accountId, productIds, productFields, false);
                Map<String,String> productImageMap = new  Map<String,String>();// getProductImageMap(webstoreId, accountId, productIds, false);
                frequentlyPurchasedList = getMappedList(productsList, productOrderCountMap, productImageMap);
                productWrapper.products = frequentlyPurchasedList;
                productWrapper.wishlistsItems = getWishlistItemsForUserId();
            }  

            System.debug('frequentlyPurchasedList:: '+ frequentlyPurchasedList);
            
        }catch(Exception e){
            System.debug('Exception:: '+  e.getMessage() + ' stack:: '+ e.getStackTraceString());
            ECOM_ApplicationLogsUtil.logFailure(e , 'Frequently Purchased:: Fetch frequently purchased product - Failed' , 'UTIL' , 'getFrequentlyPurchasedProductInfo', 'Message:: ' + e.getMessage() + ' Stack:: '+ e.getStackTraceString());
        }
        
        return productWrapper;
    }
    
    /**
     * @description This method returns the model for purchased products
     * @author vramachandran@rafter.one | 18 Dec 2023
     * @param productsList | List<Product2>
     * @param productOrderCountMap | Map<String,Integer>
     * @param productImageMap | Map<String,String>
     * @return List<ECOM_FrequentlyPurchasedWrapper>
     */
    public static List<ECOM_FrequentlyPurchasedWrapper.Product> getMappedList(List<Product2> productsList, Map<String,Integer> productOrderCountMap, Map<String,String> productImageMap){
        List<ECOM_FrequentlyPurchasedWrapper.Product> frequentlyPurchasedWrapperList = new List<ECOM_FrequentlyPurchasedWrapper.Product>();
        
        for(Product2 productRecord : productsList){
            ECOM_FrequentlyPurchasedWrapper.Product frequentlyPurchasedRecord = new ECOM_FrequentlyPurchasedWrapper.Product();
            frequentlyPurchasedRecord.productId = productRecord?.Id;
            frequentlyPurchasedRecord.productName = productRecord?.Name;
            frequentlyPurchasedRecord.productClass = productRecord?.ProductClass;
            frequentlyPurchasedRecord.productPartNumber = productRecord?.Part_Number__c;
            //frequentlyPurchasedRecord.productBrand = productRecord?.ProductBrand;
            frequentlyPurchasedRecord.productClass = productRecord?.ProductClass;
            //frequentlyPurchasedRecord.productPACCode = productRecord?.P;
            frequentlyPurchasedRecord.productBusinessUnit  = productRecord?.Business_Unit__c ;
            //frequentlyPurchasedRecord.productPortfolioLevel2 = productRecord?.Business_Unit__c;
            //RWPS-1387
            frequentlyPurchasedRecord.productPurchaseCount = productOrderCountMap.containsKey(frequentlyPurchasedRecord.productPartNumber) ? productOrderCountMap.get(frequentlyPurchasedRecord.productPartNumber) : 1;
            //frequentlyPurchasedRecord.productSapstatus = productRecord?.S
			frequentlyPurchasedRecord.productHasImage = String.isNotEmpty(productRecord?.ECOM_Product_Media_URI__c) ? true: false;
            frequentlyPurchasedRecord.productDisplayUrl =  productRecord?.ECOM_Product_Media_URI__c;// null != productImageMap && productImageMap.containsKey(productRecord?.Id) ? productImageMap.get(productRecord?.Id)  : productRecord?.DisplayUrl ;
            frequentlyPurchasedRecord.productCurrencyCode = productRecord?.CurrencyIsoCode;
            frequentlyPurchasedRecord.productClass = productRecord?.ProductClass;
            frequentlyPurchasedRecord.productLine = productRecord?.Product_Line__c;
            frequentlyPurchasedRecord.productNavigationUrl =  productRecord?.DisplayUrl;
            
            frequentlyPurchasedWrapperList.add(frequentlyPurchasedRecord);
            
        }
        
        return frequentlyPurchasedWrapperList;
    }
    
    /**
     * @description This method returns wishlist items for a userId
     * @author vramachandran@rafter.one | 18 Dec 2023
     * @return List<WishlistItem>
     */
    public static List<WishlistItem> getWishlistItemsForUserId(){
        List<Wishlist> wishlists = new List<Wishlist>();
        List<WishListItem> wishListItems = new List<WishListItem>();
        
        wishlists = ECOM_AccountService.fetchWishList(UserInfo.getUserId());
        if(null != wishlists && !wishlists.isEmpty()){
            for(Wishlist wishlistRecord : wishlists){
                if(wishlistRecord != null && null != wishListRecord?.WishlistItems && !wishListRecord?.WishlistItems.isEmpty()){
                    wishListItems.addAll(wishListRecord.WishlistItems);
                }
            }
        }
        
        return wishListItems;
    }
    
    /**
     * @description This method returns a map of product id and product display image
     * @author vramachandran@rafter.one | 24 Jan 2024
     * @param webStoreId | String 
     * @param accountId | String 
     * @param productIds | List<String>
     * @param productFields | List<String> 
     * @param excludeMedia | boolean
     * @returns Map<String,String>
     */
    public  static Map<String,String> getProductImageMap(String webStoreId, String accountId, List<String> productIds, Boolean excludeMedia){
        Map<String,String> productImageMap = new Map<String,String>();
        
        ConnectApi.ProductOverviewCollection prodOverViewCollection = ECOM_ProductService.getProducts(webStoreId, accountId, productIds, new List<String>(), excludeMedia);
        if(null != prodOverViewCollection && null != prodOverViewCollection.products && !prodOverViewCollection.products.isEmpty()){
            for(ConnectApi.ProductOverview prodOverView : prodOverViewCollection.products){
                String imageUrl = prodOverView.defaultImage.url;
                productImageMap.put(prodOverView.id, imageUrl);
            }
        }

        return productImageMap;
    }
    
}