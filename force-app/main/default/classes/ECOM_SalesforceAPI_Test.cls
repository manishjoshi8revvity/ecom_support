@isTest(SeeAllData=false)
private with sharing class ECOM_SalesforceAPI_Test 
{
    @TestSetup
    static void testSetupData()
    {
    ECOM_TestUtil.initialStorefrontSetup();
    }
    @isTest
    static void testCreateCart() {
        WebStore testWebStore = new WebStore(Name = 'revStore');
        testWebStore = ECOM_TestUtil.prepareWebStore('revStore');
        insert testWebStore;
        String webstoreId = testWebStore.Id;
        Network comm = [SELECT Id, name FROM Network ORDER BY CREATEDDATE DESC limit 1]; 
        Account ac = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
        Webcart cart = [SELECT Id FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
        String communityId = (String)comm.Id;
        String effectiveAccountId = (String)ac.Id;
        String activeCartOrId=(String)cart.Id;
        CartItem itm = [SELECT Id FROM CartItem ORDER BY CREATEDDATE DESC LIMIT 1];
        String cartItemId = (String)itm.Id;
        ConnectApi.CartInput cartz = new ConnectApi.CartInput();  
        ConnectApi.CartItemInput cartItem = new ConnectApi.CartItemInput();    
        String pageParam = 'param';
        Integer pageSize = 10;
        List<String> productIds = new List<String>{[SELECT Id, Name FROM Product2 ORDER BY CreatedDate DESC LIMIT 1].Id};
        List<String> productFields = new List<String>{'Name', 'Price'};
        Boolean excludeMedia = false;    
		User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
            test.startTest();
            ConnectApi.CartSummary result = ECOM_SalesforceAPI.createCart(webstoreId, cartz);
            ConnectApi.CartSummary result1 = ECOM_SalesforceAPI.getOrCreateActiveCartSummary(webstoreId, effectiveAccountId, activeCartOrId);
            //ECOM_SalesforceCartAPI.deleteCart(webstoreId, effectiveAccountId, activeCartOrId);
            ConnectApi.CartItem returnedCartItem = ECOM_SalesforceAPI.updateCartItem(webstoreId, effectiveAccountId, activeCartOrId, cartItemId, cartItem);
            ConnectApi.CartItemCollection result3 = ECOM_SalesforceAPI.getCartItems(webstoreId, effectiveAccountId, activeCartOrId, pageParam, pageSize);
            ConnectApi.ProductOverviewCollection result4= ECOM_SalesforceAPI.getProducts(webstoreId, effectiveAccountId, productIds, productFields, excludeMedia);
            ECOM_SalesforceAPI.deleteCart(webstoreId, effectiveAccountId, activeCartOrId);
            List<ConnectApi.BatchInput> cartItems = new List<ConnectApi.BatchInput>();
            ConnectApi.CartItemInput cartItemInput = new ConnectApi.CartItemInput();
            ECOM_SalesforceAPI.addItemsToCart(webstoreId, effectiveAccountId, activeCartOrId, cartItems);
            
            ECOM_SalesforceAPI.addItemToCart(webstoreId, effectiveAccountId, activeCartOrId, cartItemInput);
            List<ConnectApi.WishlistItemSortOrder> listSortItemsBy = new List<ConnectApi.WishlistItemSortOrder>();
            ECOM_SalesforceAPI.getWishlistSummaries(webstoreId, effectiveAccountId, 'fields', listSortItemsBy);
            ECOM_SalesforceAPI.deleteCart(webstoreId, effectiveAccountId, activeCartOrId);
            ECOM_SalesforceAPI.deleteCartItem(webstoreId, effectiveAccountId, activeCartOrId, cartItemId);
            ConnectApi.WishlistInput wishlistInput = new ConnectApi.WishlistInput();
            ConnectApi.WishlistItemInput wishlistItemInput = new ConnectApi.WishlistItemInput();
            ECOM_SalesforceAPI.addItemToWishlist(webstoreId, effectiveAccountId, 'testwishlistid', wishlistItemInput);
            ECOM_SalesforceAPI.createWishlist(webstoreId, effectiveAccountId, wishlistInput);
            Wishlist wl = ECOM_TestUtil.createWishlist(effectiveAccountId, webStoreId, u.Id);
            WishlistItem wli = ECOM_TestUtil.createWishlistItem(productIds[0], wl.Id);
            ECOM_SalesforceAPI.removeWishlistItem(webstoreId, effectiveAccountId, wl.Id, wli.Id);
            test.stopTest();
        }
               
        }
    
   

}