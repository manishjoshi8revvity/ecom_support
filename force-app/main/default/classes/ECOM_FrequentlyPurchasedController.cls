/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*	  - ECOM-1224
*
*
* 2. Description - This class is controller for frequently purchased product page.
*
*
* 3. Objects referenced
*    -WebCart
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - used in ecom_frequentlyPurchased lwc
* 	 - ECOM_Util
*    - ECOM_AccountService
*    - ECOM_CartService
*
* 6. Test Class Name: 
*    - ECOM_TODO
*
* 7. Is @Invocable: No
*
* 8. Author Name(s):
*    - Vasudev Ramachandran 30 Nov 2023
*    - Sidak 2024.06.20 Updated logic to pass contact email list in findSapOrderByOrderNumberAndZip and getFrequentlyPurchasedProducts methods. Ticket - RWPS-313
*    - Sachin Vispute 2025.12.17 - Updated method 'getFrequentlyPurchasedProducts' - RWPS-5507
*    - Poonam Shukla 2026-02-19 - Updated method getFrequentlyPurchasedProducts - RWPS-5777
*************************************************************/
public without sharing class ECOM_FrequentlyPurchasedController {
    
    final static String CLASSNAME = 'ECOM_FrequentlyPurchasedController';
    
    /**
     * @description This method returns the map of frequentyly purchased products for the previous year
     * @author vramachandran@rafter.one | 02 Jan 2024
     * @param userEmail | String
     * @return Map<String,Object>
     */
    @AuraEnabled
    public static Map<String,Object> getFrequentlyPurchasedProductForLoggedInUser(){
        System.debug('UserInfo email:: '+ UserInfo.getUserEmail());
        Type userService = Type.forName(ECOM_Constant.USER_Service);
        ECOM_IUserService userServiceInstance = (ECOM_IUserService)userService.newInstance();
        User userRecord = userServiceInstance.getUserByUser(UserInfo.getUserId());
        return getFrequentlyPurchasedProducts(UserInfo.getUserEmail(), userRecord.AccountId);
    }

    /**
    * @description This method computes frequently purchased products from orders placed in previous year
	* @param userEmail | String
    * @return Map<String,Object>
	* @author vramachandran@rafter.one | 30 Nov 2023
    **/
    @AuraEnabled
    public static Map<String,Object> getFrequentlyPurchasedProducts(String userEmail, String accountId){
        final String METHOD_NAME = 'getFrequentlyPurchasedProducts';
        Map<String,Object> responseMap = new Map<String,Object>();
        try{
            Type sapOrderServiceType = Type.forName(ECOM_Constant.SAP_ORDER_SUMMARY_SERIVCE);
            ECOM_ISAPOrderSummary sapOrderService = (ECOM_ISAPOrderSummary) sapOrderServiceType.newInstance();
            
            List<ECOM_FrequentlyPurchasedWrapper.Product> frequentlyPurchasedList = new List<ECOM_FrequentlyPurchasedWrapper.Product>();
            
            ECOM_FrequentlyPurchasedWrapper productWrapper = new ECOM_FrequentlyPurchasedWrapper();
            productWrapper.products = frequentlyPurchasedList;
            
            //fetch orders for last year
            Date startDate = Date.today().addYears(-1);
            Date endDate = Date.today();
            
            List<SAP_Order_Summary__c> orderSummaries;
            List<String> sourceTypes = System.Label.ECOM_OrderTypes_Punchout.split(',');
            List<String> contactEmailList = new List<String>{userEmail};
           
            //RWPS-5507 - Start
            List<User> userList = ECOM_UserRepo.getUserRecordByUserEmail(userEmail);
            User user = userList.isEmpty() == false ? userList[0] : null;
            if (user != null) {
                //RWPS-5777 start
                String masterId = user?.Contact?.Default_Ship_to_ERP_Address__r?.Master_Address__c;
                Map<String, String> emailMap = ECOM_Util.getPunchoutEmailDetails(masterId);

                String additionalEmails = emailMap.get('additionalEmails');
                String selectedEmailType = emailMap.get('selectedEmailType');
                //RWPS-5777 end
                List<String> alternateEmailList = new List<String>();
                List<String> orderTypesList = new List<String>();
                List<String> poTypesList = new List<String>();
                if (String.isNotBlank(additionalEmails)) {
                    for (String email : additionalEmails.split(',')) {
                        email = email.trim();
                        if (String.isNotBlank(email)) {
                            alternateEmailList.add(email);
                        }
                    }
                }
                if(user != null && user?.ECOM_Is_Punchout_User__c) {
                    List<C_META_Storefront_Configuration__mdt> storeFrontConfigurations = ECOM_CustomMetadataRepo.fetchStoreConfigMdtBasedOnModuleName('POTypesPunchout');
                    storeFrontConfigurations.add(ECOM_CustomMetadataRepo.fetchStoreConfigMdtBasedOnModuleName('PunchoutOrderTypes')[0]);
                    poTypesList = storeFrontConfigurations[0].Value__c.split(',');
                    orderTypesList = storeFrontConfigurations[1].Value__c.split(',');
                }
                //orderSummaries = sapOrderService.fetchSAPOrderByEmailAndSourceType(contactEmailList, sourceTypes, startDate, endDate);	//VRa - changed 02 Jan 2024, for new configuration
                orderSummaries = ECOM_SAPOrderSummaryRepo.fetchSAPOrders(contactEmailList, selectedEmailType, alternateEmailList, orderTypesList,
                    poTypesList, ECOM_Constant.FREQUENTLY_PURCHASED_PRODUCTS, true, startDate, endDate);
            }
            //RWPS-5507 - End

            //get parnumber product map 
            if(orderSummaries != null && !orderSummaries.isEmpty()){
                productWrapper = ECOM_FrequentlyPurchasedUtil.getFrequentlyPurchasedProductInfo(orderSummaries, accountId);
            }
            
            responseMap.put(ECOM_Constant.PARAM_RESPONSE_DATA, productWrapper);
            responseMap.put(ECOM_Constant.PARAM_SUCCESS, true);
            
        }catch(Exception e){
            responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
            responseMap.put(ECOM_Constant.PARAM_MESSAGE, e.getMessage() + ' stack:: '+ e.getStackTraceString());
            ECOM_ApplicationLogsUtil.logFailure(e , 'Frequently Purchased:: Fetch frequently purchased product - Failed' , CLASSNAME , METHOD_NAME, 'Message:: ' + e.getMessage() + ' Stack:: '+ e.getStackTraceString());
        }
        return responseMap;
    }
    
    /**
     * @description This method returns current wishList for userId
     * @author vramachandran@rafter.one | 19 Dec 2023
     * @param wishlistItemId | String
     * @returns Map<String,Object> 
     */
    @AuraEnabled
    public static Map<String,Object> removeWishListItem(String wishListItemId){
        final String METHOD_NAME = 'removeWishListItem';
        Map<String,Object> responseMap = new Map<String,Object>();
        
        ECOM_FrequentlyPurchasedWrapper wrapper = new ECOM_FrequentlyPurchasedWrapper();
        wrapper.wishlistsItems = new List<WishlistItem>();
        try{
            
            ECOM_AccountService.removeWishlistItem(wishListItemId);
            
            wrapper.wishlistsItems = ECOM_FrequentlyPurchasedUtil.getWishlistItemsForUserId();
        	
            responseMap.put(ECOM_Constant.PARAM_RESPONSE_DATA, wrapper);
            responseMap.put(ECOM_Constant.PARAM_SUCCESS, true);
        }catch(Exception e){
            responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
            responseMap.put(ECOM_Constant.PARAM_MESSAGE, e.getMessage() + ' stack:: '+ e.getStackTraceString());
            ECOM_ApplicationLogsUtil.logFailure(e , 'ECOM_FrequentlyPurchasedController- remove from wishlist failed' , CLASSNAME , METHOD_NAME, 'Message:: ' + e.getMessage() + ' Stack:: '+ e.getStackTraceString());
        }
        
        return responseMap;
    }
    
    /**
     * @description This method returns current wishList for userId
     * @author vramachandran@rafter.one | 19 Dec 2023
     * @param wishlistItemId | String
     * @returns Map<String,Object> 
     */
    @AuraEnabled
    public static Map<String,Object> addWishListItem(String communityId, String wishListId, String productId,String effectiveAccountId){
        final String METHOD_NAME = 'addWishListItem';
        Map<String,Object> responseMap = new Map<String,Object>();
        
        ECOM_FrequentlyPurchasedWrapper wrapper = new ECOM_FrequentlyPurchasedWrapper();
        wrapper.wishlistsItems = new List<WishlistItem>();
        
        try{
            String webstoreId = ECOM_Util.resolveCommunityIdToWebstoreId(communityId);
            
            ConnectApi.WishlistItemInput wishlistItemInput = new ConnectApi.WishlistItemInput();
            wishlistItemInput.productId = productId;
            
            if(String.isNotBlank(wishListId)){
                
                if(!Test.isRunningTest())ConnectApi.CommerceWishlist.addItemToWishlist( webstoreId,  wishListId,  wishlistItemInput);
                
            } else {
                ConnectApi.WishlistInput wishlistInput = new ConnectApi.WishlistInput();
                wishlistInput.name = 'My favorite list';
                wishlistInput.products = new List<ConnectApi.WishlistItemInput>{wishlistItemInput};
                ConnectApi.CommerceWishlist.createWishlist(webstoreId,effectiveAccountId,wishlistInput);
            }
            
            wrapper.wishlistsItems = ECOM_FrequentlyPurchasedUtil.getWishlistItemsForUserId();
        	
            responseMap.put(ECOM_Constant.PARAM_RESPONSE_DATA, wrapper);
            responseMap.put(ECOM_Constant.PARAM_SUCCESS, true);
        }catch(Exception e){
            responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
            responseMap.put(ECOM_Constant.PARAM_MESSAGE, e.getMessage() + ' stack:: '+ e.getStackTraceString());
            ECOM_ApplicationLogsUtil.logFailure(e , 'ECOM_FrequentlyPurchasedController- remove from wishlist failed' , CLASSNAME , METHOD_NAME, 'Message:: ' + e.getMessage() + ' Stack:: '+ e.getStackTraceString());
        }
        
        return responseMap;
    }
    
    /**
     * @description This method returns the list of frequently bought products for a user email
     * @author vramachandran@rafter.one | 02 Jan 2024
     * @param userEmail | String 
     * @returns List<String>
     */
    public static Set<String> getFrequentlyBoughtProductsForUserEmail(String userEmail, String accountId){
        Set<String> productIdSet = new Set<String>();
        
        //fetch frequently bought product model map
        Map<String,Object> responseMap = getFrequentlyPurchasedProducts(userEmail, accountId);
        
        //get list of products
        List<Product2> productList = new List<Product2>();
        ECOM_FrequentlyPurchasedWrapper productsWrapper;
       	productsWrapper = (ECOM_FrequentlyPurchasedWrapper) responseMap.get(ECOM_Constant.PARAM_RESPONSE_DATA);
        
        
        if(null != productsWrapper && null != productsWrapper.products && !productsWrapper.products.isEmpty()){
            for(ECOM_FrequentlyPurchasedWrapper.Product productRecord : productsWrapper.products){
                if(!productIdSet.contains(productRecord.productId)){
                    productIdSet.add(productRecord.productId);
                }
            }
        }
        
        return productIdSet;
    }

}