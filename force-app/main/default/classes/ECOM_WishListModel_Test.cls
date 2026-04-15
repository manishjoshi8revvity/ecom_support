/**************************************************************

	* 1. Jira Ticket(s) that relates to this class
	*  
	*
	* 2. Description - This is a test class
	*
	* 3. Objects referenced
	*    - User
	*    - Account
	*    - WebStore
	*	 

	* 4. Callouts to additional Components (including their methods) or None:
	*    - None
	*
	* 5. Dependant Class(es):
	*    - ECOM_TestUtil
	 
	* 6. Test Class Name:
	*
	* 7. Is @Invocable : No
	*
	* 8. Author Name(s):
	*    - Sukumar 2023.09.17
	*************************************************************/
 
@isTest(SeeAllData=false)
public class ECOM_WishListModel_Test {
   @isTest
    static void testECOM_WishListModel() {
        // Create test data
        /*Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Product2 testProduct = new Product2(Name = 'Test Product');
        insert testProduct;
        
        WebStore testWebStore = new WebStore(Name = 'revStore');
        testWebStore = ECOM_TestUtil.prepareWebStore('revStore');
        insert testWebStore;
        String webstoreId = testWebStore.Id;
        User u = [SELECT Id, Username FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        String userId = (String)u.Id;
        
        Wishlist testWishlist = ECOM_TestUtil.createWishlist(testAccount.Id, webstoreId, userId);
        WishlistItem testWishlistItem = ECOM_TestUtil.createWishlistItem(testWishlist, testProduct);
        
        // Instantiate ECOM_WishListModel
        ECOM_WishListModel wishListModel = new ECOM_WishListModel();
        wishListModel.wishListId = testWishlist.Id;
        wishListModel.accountId = testAccount.Id;
        wishListModel.wishlistProductCount = '2';
        wishListModel.wishListName = 'Test Wishlist';
        wishListModel.ownerId = userId;
        wishListModel.isDefault = true;
        wishListModel.wishListItems = new List<ECOM_WishListItemModel>();
        
        // Add test data to wishListItems
        ECOM_WishListItemModel wishlistItemModel = new ECOM_WishListItemModel();
        wishlistItemModel.wishlistItemId = testWishlistItem.Id;
        wishlistItemModel.productName = testProduct.Name;
        wishlistItemModel.productId = testProduct.Id;
        wishListModel.wishListItems.add(wishlistItemModel);
        
        // Test the ECOM_WishListModel
        System.assertEquals(testWishlist.Id, wishListModel.wishListId);
        System.assertEquals(testAccount.Id, wishListModel.accountId);
        System.assertEquals('2', wishListModel.wishlistProductCount);
        System.assertEquals('Test Wishlist', wishListModel.wishListName);
        System.assertEquals(userId, wishListModel.ownerId);
        System.assertEquals(true, wishListModel.isDefault);
        System.assertEquals(1, wishListModel.wishListItems.size());
        System.assertEquals(testWishlistItem.Id, wishListModel.wishListItems[0].wishlistItemId);
        System.assertEquals(testProduct.Name, wishListModel.wishListItems[0].productName);
        System.assertEquals(testProduct.Id, wishListModel.wishListItems[0].productId);*/
    }
}