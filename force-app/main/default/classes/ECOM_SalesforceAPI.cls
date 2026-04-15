/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*        
*
* 2. Description - This class is used to call ConnectApi for Cart related operations
*
*
* 3. Objects referenced
*    - WebCart
*     - CartItem
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
*
* 5. Dependant Class(es):
*    - ConnectApi
*	 - ECOM_CartRepo
*	
* 6. Test Class Name: 
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Rani 2023.08.01
*    - Manoj 2023.09.04
*    - Manoj 2024.09.09 RWPS-1387 read image from Product2.ECOM_Product_Media_URI__c(DAM) instead product media
*************************************************************/

public with sharing class ECOM_SalesforceAPI {
	
    

    /**
    * @description // Create cart
    * @author Vipul Goyal | 09-20-2023 
    * @param webstoreId 
    * @param cart 
    * @return ConnectApi.CartSummary 
    **/
    public static ConnectApi.CartSummary createCart(String webstoreId, ConnectApi.CartInput cart) {
        return Test.isRunningTest()?ECOM_TestUtil.createDataConnectApi_CartSummary():ConnectApi.CommerceCart.createCart(webstoreId, cart);
    }

    /**
    * @description //Fetch cart
    * @author Vipul Goyal | 09-20-2023 
    * @param webstoreId 
    * @param effectiveAccountId 
    * @param activeCartOrId 
    * @return ConnectApi.CartSummary 
    **/
    public static ConnectApi.CartSummary getOrCreateActiveCartSummary(String webstoreId, String effectiveAccountId, String activeCartOrId) {
        return Test.isRunningTest()?ECOM_TestUtil.createDataConnectApi_CartSummary():ConnectApi.CommerceCart.getOrCreateActiveCartSummary(webstoreId, effectiveAccountId, activeCartOrId);
    }


    /**
    * @description //Delete Cart
    * @author Vipul Goyal | 09-20-2023 
    * @param webstoreId 
    * @param effectiveAccountId 
    * @param activeCartOrId  
    * @return Void 
    **/
    public static Void deleteCart(String webstoreId, String effectiveAccountId, String activeCartOrId){
         if(!Test.isRunningTest())
         {
             ConnectApi.CommerceCart.deleteCart(webstoreId, effectiveAccountId, activeCartOrId);
         }
         
    }


    /**
    * @description  // Add single Cart Item to the Cart
    * @author Vipul Goyal | 09-20-2023 
    * @param webstoreId 
    * @param effectiveAccountId 
    * @param activeCartOrId 
    * @param cartItemInput 
    * @return ConnectApi.CartItem 
    **/
    public static ConnectApi.CartItem addItemToCart(String webstoreId, String effectiveAccountId, String activeCartOrId, ConnectApi.CartItemInput cartItemInput){
        return Test.isRunningTest()?ECOM_TestUtil.getCartItemData():ConnectApi.CommerceCart.addItemToCart(webstoreId, effectiveAccountId, activeCartOrId, cartItemInput);
    }

    
    /**
    * @description  // Add Cart Items to the Cart
    * @author Vipul Goyal | 09-20-2023 
    * @param webstoreId 
    * @param effectiveAccountId 
    * @param activeCartOrId 
    * @param cartItems 
    * @return List<ConnectApi.BatchResult> 
    **/
    public static List<ConnectApi.BatchResult> addItemsToCart(String webstoreId, String effectiveAccountId, String activeCartOrId, List<ConnectApi.BatchInput> cartItems) {
        return Test.isRunningTest()? null:ConnectApi.CommerceCart.addItemsToCart(webstoreId, effectiveAccountId, activeCartOrId, cartItems);
    }

    /*public static ConnectApi.CartItemCollection getCartItems(String webstoreId, String effectiveAccountId, String activeCartOrId) {
        return this.getCartItems(webstoreId, effectiveAccountId, activeCartOrId, null, null);
    }*/
    

    /**
    * @description 	// Fetch Cart Items
    * @author Vipul Goyal | 09-20-2023 
    * @param webstoreId 
    * @param effectiveAccountId 
    * @param activeCartOrId 
    * @param pageParam 
    * @param pageSize 
    * @return ConnectApi.CartItemCollection 
    **/
    public static ConnectApi.CartItemCollection getCartItems(String webstoreId, String effectiveAccountId, String activeCartOrId, String pageParam, Integer pageSize) {
        return Test.isRunningTest()?ECOM_TestUtil.testConnectApiCartItemCollection() : ConnectApi.CommerceCart.getCartItems(webstoreId, effectiveAccountId, activeCartOrId,pageParam, pageSize);
    }
    
      /**
    * @description 	// Fetch Cart Items with product attributes
    * @author Manoj | 09-09-2024
    * @param webstoreId 
    * @param effectiveAccountId 
    * @param activeCartOrId 
    * @param productFields
    * @param pageParam 
    * @param pageSize
    * @param sortOrder 
    * @return ConnectApi.CartItemCollection 
    **/
    public static ConnectApi.CartItemCollection getCartItems(String webstoreId, String effectiveAccountId, String activeCartOrId, String productFields,String pageParam, Integer pageSize,ConnectApi.CartItemSortOrder sortOrder) {
        return Test.isRunningTest()?ECOM_TestUtil.testConnectApiCartItemCollection() : ConnectApi.CommerceCart.getCartItems(webstoreId, effectiveAccountId, activeCartOrId, productFields,pageParam, pageSize,sortOrder);
    }


    /**
    * @description // Update Cart Item
    * @author Vipul Goyal | 09-20-2023 
    * @param webstoreId 
    * @param effectiveAccountId 
    * @param activeCartOrId 
    * @param cartItemId 
    * @param cartItem 
    * @return ConnectApi.CartItem 
    **/
    public static ConnectApi.CartItem updateCartItem(String webstoreId, String effectiveAccountId, String activeCartOrId, String cartItemId, ConnectApi.CartItemInput cartItem) {
        return Test.isRunningTest()?ECOM_TestUtil.createDataConnectApi_CartItem('testproduct'):ConnectApi.CommerceCart.updateCartItem(webstoreId, effectiveAccountId, activeCartOrId, cartItemId, cartItem);
    }

    
    /**
    * @description 
    * @author mkumar@rafter.one | 09-21-2023 
    * @param webstoreId 
    * @param effectiveAccountId 
    * @param activeCartOrId 
    * @param cartItemId 
    **/
    public static void deleteCartItem(String webstoreId, String effectiveAccountId, String activeCartOrId, String cartItemId) {
        if(!Test.isRunningTest())
        {
             ConnectApi.CommerceCart.deleteCartItem(webstoreId, effectiveAccountId, activeCartOrId, cartItemId);
        }
        
    }
    

    /**
    * @description //get product related Info with Images
    * @author Vipul Goyal | 09-20-2023 
    * @param webstoreId 
    * @param effectiveAccountId 
    * @param ProductIds 
    * @param productFields 
    * @param excludeMedia 
    * @return ConnectApi.ProductOverviewCollection 
    **/
    public static ConnectApi.ProductOverviewCollection getProducts(String webstoreId, String effectiveAccountId,List<String> ProductIds, List<String> productFields, Boolean excludeMedia){
        return Test.isRunningTest()?ECOM_TestUtil.getProductOverviewCollection(): ConnectApi.CommerceCatalog.getProducts(webstoreId, effectiveAccountId, ProductIds, null, productFields, excludeMedia);
    }
	
	

    /**
    * @description //Fetch Wish cart summary
    * @author Vipul Goyal | 09-20-2023 
    * @param webstoreId 
    * @param effectiveAccountId 
    * @param productFields 
    * @param listSortItemsBy 
    * @return ConnectApi.WishlistsSummary 
    **/
    public static ConnectApi.WishlistsSummary getWishlistSummaries(String webstoreId, String effectiveAccountId, String productFields, List<ConnectApi.WishlistItemSortOrder> listSortItemsBy){
        return Test.isRunningTest()?ECOM_TestUtil.getWishlistsSummaryData():ConnectApi.CommerceWishlist.getWishlistSummaries(webstoreId, effectiveAccountId, true, productFields, null, listSortItemsBy[1]);
    }
    

    /**
    * @description     //Create Wish list
    * @author Vipul Goyal | 09-20-2023 
    * @param webstoreId 
    * @param effectiveAccountId 
    * @param wishlistInput 
    * @return ConnectApi.Wishlist 
    **/
    public static ConnectApi.Wishlist createWishlist(String webstoreId, String effectiveAccountId, ConnectApi.WishlistInput wishlistInput){
        return Test.isRunningTest()?ECOM_TestUtil.getWishlistDataNew():ConnectApi.CommerceWishlist.createWishlist(webstoreId, effectiveAccountId, wishlistInput);
    }

    /**
    * @description //Create Wish list Item
    * @author Vipul Goyal | 09-20-2023 
    * @param webstoreId 
    * @param effectiveAccountId 
    * @param wishlistId 
    * @param wishlistItemInput 
    * @return ConnectApi.WishlistItem 
    **/
    public static ConnectApi.WishlistItem addItemToWishlist(String webstoreId, String effectiveAccountId, String wishlistId, ConnectApi.WishlistItemInput wishlistItemInput){
        System.debug('webstoreId =='+webstoreId);
        System.debug('wishlistId =='+wishlistId);
        System.debug('wishlistItemInput =='+wishlistItemInput);
        return Test.isRunningTest()?ECOM_TestUtil.getWishlistItemData():ConnectApi.CommerceWishlist.addItemToWishlist(webstoreId, effectiveAccountId, wishlistId, wishlistItemInput);
    }
	

    /**
    * @description     //Delete Wish list item
    * @author Vipul Goyal | 09-20-2023 
    * @param webstoreId 
    * @param effectiveAccountId 
    * @param wishlistId 
    * @param wishlistItemId 
    * @return Void 
    **/
    public static Void removeWishlistItem(String webstoreId, String effectiveAccountId, String wishlistId, String wishlistItemId){
        if(!Test.isRunningTest())
        {
             ConnectApi.CommerceWishlist.removeWishlistItem(webstoreId, effectiveAccountId, wishlistId, wishlistItemId);
        }
       
    }
    
    /**
    * @description     //Create order summary
    * @author Rani Thumma | 09-11-2023 
    * @param webstoreId 
    * @return ConnectApi.OrderSummaryOutputRepresentation 
    **/
    public static ConnectApi.OrderSummaryOutputRepresentation createOrderSummary(ConnectApi.OrderSummaryInputRepresentation orderSummaryInput){
        return Test.isRunningTest()?null:ConnectApi.OrderSummaryCreation.createOrderSummary(orderSummaryInput);        
    }
}