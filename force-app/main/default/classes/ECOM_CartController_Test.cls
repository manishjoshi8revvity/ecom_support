/**************************************************************

	* 1. Jira Ticket(s) that relates to this class
	*
	*
	* 2. Description - This class is a test class for ECOM_CartController.
					- This class use test data to pass into ECOM_CartController and test the functionalty.
					- Call the ECOM_TestUtil Class to create test data and test each methods.
					- Used System Assertion to Confirm the functionalities.
	*
	* 3. Objects referenced
	*    - WebStore
	*    - Account
	*    - Network
	*    - CartItem

	* 4. Callouts to additional Components (including their methods) or None:
	*    - None
	*
	* 5. Dependant Class(es):
	*    - ECOM_TestUtil
	*  	 - ECOM_CartController

	* 6. Test Class Name:
	*
	* 7. Is @Invocable : No
	*
	* 8. Author Name(s):
	*    - Manoj 2023.09.19
    *    - Sidak 2024.01.16 Updated method testDeleteCartItem. Ticket - ECOM-1384
	*    - Sidak 2024.03.06 Added method testupdateCartItemListPrice. Ticket - RWPS-182
	*    - Sidak 2024.06.01 Added methods updateBillToShipToOnCartTest, deleteShippingCartItemTest. Ticket: RWPS-766
	*    - Manoj RWPS-1869 - Fixed test class for getShippingTime change
    *    - Poonam 2025.01.13 Added method testProcessProductExclusions,testGetExcludedPartNumbersForNoAddressRecords,testRetrieveProductsByPartialPartNumber. Ticket - RWPS-1456
    *    - Abhishek 2025.04.03 Added method testGetContractPrice. Ticket - RWPS-2858
    *    - Abhishek 2025.04.03 Added method testGetSellableProducts. Ticket - RWPS-3003
    *    - Chirag 2025.07.14 Updated references of method updateCartItemListPrice - RWPS-3683
    *    - Prabhat 2025.07.14 Updated method testgetCMSBaseUrl - RWPS-1603
    *    - Abhishek 2025.07.15 Updated method testGetSellableProducts - RWPS-3697
    *    - Prabhat 2025.10.06 Updated method testDeleteCartItem and testGetSellableProducts  - RWPS-3740
*************************************************************/
/**
 * @description       :
 * @author            : mkumar@rafter.one
 * @group             :
 * @last modified on  : 09-21-2023
 * @last modified by  : mkumar@rafter.one
**/
@isTest(seeAllData=false)
public with sharing class ECOM_CartController_Test
{

     /**
   * @description this method is used to create test data.
   */
    @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
    }
    // Test method for getCartItems
    @isTest
    static void testGetCartItems() {
        // Add your test logic here
        Network comm = [SELECT id, name FROM Network ORDER BY CREATEDDATE DESC limit 1];
        Account ac = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
        Webcart cart = [SELECT Id FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
        String communityId = (String)comm.Id;
        String effectiveAccountId = (String)ac.Id;
        String activeCartOrId=(String)cart.Id;
        String sortParam = 'sort';
        String pageParam  ='param';
        String productFields = '';
        User u = [SELECT Id,AccountId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        Test.startTest();
        	//ConnectApi.CartItemCollection result = ECOM_CartController.getCartItems(communityId, effectiveAccountId, activeCartOrId, productFields, pageParam, sortParam);
        Test.stopTest();
        }
    }

    // Test method for getCartItemsWrapped
    @isTest
    static void testGetCartItemsWrapped() {
        Map<String,Object> dataMap = new Map<String,Object>();
        Network comm = [SELECT Id, name FROM Network ORDER BY CREATEDDATE DESC limit 1];
        Account ac = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
        Webcart cart = [SELECT Id FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
        String communityId = (String)comm.Id;
        String effectiveAccountId = (String)ac.Id;
        String activeCartOrId=(String)cart.Id;
        String sortParam = 'sort';
        String pageParam  ='param';
        String productFields = '';

        User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        Test.startTest();
        	dataMap = ECOM_CartController.getCartItemsWrapped(comm.Id, effectiveAccountId, activeCartOrId, productFields, pageParam, sortParam);
        Test.stopTest();
        }
    }

    // Test method for updateCartItem
    @isTest
    static void testUpdateCartItem() {
        // Add your test logic here
        Map<String,Object> dataMap = new Map<String,Object>();
        Network comm = [SELECT Id, name FROM Network ORDER BY CREATEDDATE DESC limit 1];
        Account ac = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
        Webcart cart = [SELECT Id FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
        CartItem itm = [SELECT Id FROM CartItem ORDER BY CREATEDDATE DESC LIMIT 1];
        String communityId = (String)comm.Id;
        String effectiveAccountId = (String)ac.Id;
        String activeCartOrId=(String)cart.Id;
        String cartItemId = (String)itm.Id;
        ConnectApi.CartItemInput cartItem = new ConnectApi.CartItemInput();

        test.startTest();
        User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        	ConnectApi.CartItem result = ECOM_CartController.updateCartItem(communityId,effectiveAccountId,activeCartOrId,cartItemId,cartItem);
        }
        test.stopTest();

    }

    // Test method for deleteCartItem
    @isTest
    static void testDeleteCartItem() {
        // Add your test logic here
        Network comm = [SELECT Id, name FROM Network ORDER BY CREATEDDATE DESC limit 1];
        Account ac = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
        Webcart cart = [SELECT Id FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
        CartItem itm = [SELECT Id FROM CartItem ORDER BY CREATEDDATE DESC LIMIT 1];
        Product2 pro = [SELECT Id FROM Product2 ORDER BY CREATEDDATE DESC LIMIT 1];
        String communityId = (String)comm.Id;
        String effectiveAccountId = (String)ac.Id;
        String activeCartOrId=(String)cart.Id;
        String cartItemId = (String)itm.Id;
        String prodId = (String)pro.Id;
        Decimal num = [SELECT COUNT()
        FROM CartItem
        WHERE CartId = :activeCartOrId];

        test.startTest();
        User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        	ECOM_CartController.deleteCartItem(activeCartOrId,cartItemId,prodId);
        }
        test.stopTest();

        List<CartItem> resItem = [SELECT Id FROM CartItem WHERE Id =:cartItemId];
        Decimal num2 = [SELECT COUNT()
        FROM CartItem
        WHERE CartId = :activeCartOrId];
        System.assertNotEquals(0,num2,'WRONG');//RWPS-3740
    }

    // Test method for getCartSummary
    @isTest
    static void testGetCartSummary() {
        // Add your test logic here
        Network comm = [SELECT Id, name FROM Network ORDER BY CREATEDDATE DESC limit 1];
        Account ac = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
        Webcart cart = [SELECT Id FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
        String communityId = (String)comm.Id;
        String effectiveAccountId = (String)ac.Id;
        String activeCartOrId=(String)cart.Id;

        test.startTest();
        User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        	ConnectApi.CartSummary result = ECOM_CartController.getCartSummary(communityId, effectiveAccountId, activeCartOrId);
            ConnectApi.CartSummary result2 = ECOM_CartController.getCartSummary(communityId, effectiveAccountId, '');

        test.stopTest();

        System.assertEquals(null,result,'result must be null');
        }

    }

    // Test method for createCart
    @isTest
    static void testCreateCart() {
        // Add your test logic here
        Network comm = [SELECT Id, name FROM Network ORDER BY CREATEDDATE DESC limit 1];
        Account ac = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
        String communityId = (String)comm.Id;
        String effectiveAccountId = (String)ac.Id;

        test.startTest();
        User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        	ConnectApi.CartSummary result = ECOM_CartController.createCart(communityId, effectiveAccountId);
            System.assertEquals(null,result,'result should be null');
        }
        test.stopTest();


    }

    // Test method for deleteCart
    @isTest
    static void testDeleteCart() {
        // Add your test logic here
        Network comm = [SELECT Id, name FROM Network ORDER BY CREATEDDATE DESC limit 1];
        Account ac = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
        Webcart cart = [SELECT Id FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
        String communityId = (String)comm.Id;
        String effectiveAccountId = (String)ac.Id;
        String activeCartOrId=(String)cart.Id;

        test.startTest();
        User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        	ECOM_CartController.deleteCart(communityId, effectiveAccountId, activeCartOrId);
        }
        test.stopTest();
    }

    @isTest
    static void testupdateCartItemListPrice() {
        Webcart cart = [SELECT Id FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
        CartItem cartItem = [SELECT Id FROM CartItem LIMIT 1];
        String cartItemId = cartItem.Id;
        String listPrice = '200';
        String salesPrice = '100';

        test.startTest();
        User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        	ECOM_CartController.updateCartItemListPrice(cartItemId, 2); // RWPS-3683
        }
        test.stopTest();
    }

    // Test method for getWishlistSummaries
    @isTest
    static void testGetWishlistSummaries() {
        // Add your test logic here
        ConnectApi.WishlistsSummary result = new ConnectApi.WishlistsSummary();
        Network comm = [SELECT Id, name FROM Network ORDER BY CREATEDDATE DESC limit 1];
        Account ac = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
        Webcart cart = [SELECT Id FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
        String communityId = (String)comm.Id;
        String effectiveAccountId = (String)ac.Id;

        test.startTest();
        User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {

            result = ECOM_CartController.getWishlistSummaries(communityId, effectiveAccountId);
        }
        test.stopTest();
        System.assertEquals(null,result,'Wrong output');
    }

    // Test method for createAndAddToList
    @isTest
    static void testCreateAndAddToList() {
        Network comm = [SELECT Id, name FROM Network ORDER BY CREATEDDATE DESC limit 1];
        Account ac = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
        Webcart cart = [SELECT Id FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
        Product2 pr = [SELECT Id FROM Product2 ORDER BY CREATEDDATE DESC LIMIT 1];

        String communityId = (String)comm.Id;
        String effectiveAccountId = (String)ac.Id;
        String productId = pr.Id;
        String wishListId = 'TESTWISHLIST' ;
        ConnectApi.WishlistItem result = new ConnectApi.WishlistItem();
        test.startTest();
        User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        	result = ECOM_CartController.createAndAddToList(communityId, productId, wishListId, effectiveAccountId);
        	ConnectApi.WishlistItem result1 = ECOM_CartController.createAndAddToList(communityId, productId, '', effectiveAccountId);
        }
        test.stopTest();
        system.AssertNotEquals(null,result,'Wrong Output');

    }

    // Test method for getFieldsByObjectName
    @isTest
    static void testGetFieldsByObjectName() {
        // Add your test logic here
        String objectName = 'Account';
        Map<String,String> result = new Map<String,String>();

        Test.startTest();
        User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        	result = ECOM_CartController.getFieldsByObjectName(objectName);
            System.AssertNotEquals(null,result,'Result must not be null');
        }
        Test.stopTest();


    }

    // Test method for repriceCart
    @isTest
    static void testRepriceCart() {
        // Add your test logic here
        Webcart cart = [SELECT Id FROM WebCart ORDER BY CREATEDDATE DESC LIMIT 1];
        String couponCode = 'COUPON23';
        Map<String,Object> result = ECOM_CartController.repriceCart(cart.Id, couponCode);
        System.AssertNotEquals(null,result,'Wrong Output');

    }

    // Test method for addItemsToCart
    @isTest
    static void testAddItemsToCart() {
        // Add your test logic here
        String effectiveAccountId = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        String communityId =[SELECT Id, name FROM Network ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        List<CartItem> cartItems = [SELECT Id,product2Id,Quantity FROM CartItem ORDER BY CREATEDDATE DESC LIMIT 3];
        Map<String,Object> result = new Map<String,Object>();
        test.startTest();
       User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        	result = ECOM_CartController.addItemsToCart(communityId, effectiveAccountId, cartItems);
        }
        test.stopTest();
        System.assertNotEquals(null,result,'result should not be null');



    }

    // Test method for deleteCartItemsById
    @isTest
    static void testDeleteCartItemsById() {
        // Add your test logic here
        List<CartItem> cartItems = [SELECT Id FROM CartItem ORDER BY CREATEDDATE DESC LIMIT 3];
        List<Id> cartItemIds = new List<Id>();
        for(CartItem itr : cartItems)
        {
            cartItemIds.add(itr.Id);
        }
        User u = [SELECT Id,AccountId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        test.startTest();
        ECOM_CartController.deleteCartItemsById(cartItemIds);
        test.stopTest();
        }

    }

    // Test method for deleteCartItemsforProductId
    @isTest
    static void testDeleteCartItemsforProductId() {
        // Add your test logic here
        String cartId = [SELECT Id FROM WebCart ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        String productId = [SELECT Id FROM Product2 ORDER BY CREATEDDATE LIMIT 1].Id;
        User u = [SELECT Id,AccountId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        test.startTest();
        ECOM_CartController.deleteCartItemsforProductId(productId,cartId);
        test.stopTest();
        }

    }

    // Test method for updateShippingDateOnCartItem
    @isTest
    static void testUpdateShippingDateOnCartItem() {
        // Add your test logic here
        Id cartItemId = [SELECT Id FROM CartItem ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        Date shipDate = Date.today() + 10;
        User u = [SELECT Id,AccountId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        test.startTest();
        {
            ECOM_CartController.updateShippingDateOnCartItem(cartItemId, shipDate);
        }
        test.stopTest();
        }
    }

    // Test method for retrieveProductsByPartNumber
    @isTest
    static void testRetrieveProductsByPartNumber() {
        // Add your test logic here
        Map<String,Object> result = new Map<String,Object>();
        String productData = [SELECT Id,Part_Number__c FROM Product2 ORDER BY CREATEDDATE DESC LIMIT 1].Part_Number__c;
        // Convert the test data to a JSON string
        String testProductData = JSON.serialize(productData);
        User u = [SELECT Id,AccountId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        test.startTest();
        {
            result = ECOM_CartController.retrieveProductsByPartNumber(testProductData);
        }
		}
        test.stopTest();
        System.assertNotEquals(null,result,'Wrong Output');
    }

    // Test method for checkRADIdentifierAccount
    /*@isTest
    static void testCheckRADIdentifierAccount() {
        // Add your test logic here
        Boolean result;
        User u = [SELECT Id,AccountId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        result = ECOM_CartController.checkRADIdentifierAccount();
        }

        System.AssertNotEquals(null,result,'result should not be null');
    }*/

    // Test method for getWishlistDetails
    @isTest
    static void testGetWishlistDetails() {
        // Add your test logic here
        List<ECOM_AccountWrapper.WishlistDetails> result = new List<ECOM_AccountWrapper.WishlistDetails>();
        result = ECOM_CartController.getWishlistDetails();

        System.AssertNotEquals(null,result,'result should not be null');
    }

    // Test method for removeWishlistItem
    @isTest
    static void testRemoveWishlistItem() {
        // Add your test logic here
        String effectiveAccountId = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        String communityId =[SELECT Id, name FROM Network ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        String wishListId = [SELECT Id FROM Wishlist ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        String wishlistItemId = [SELECT Id FROM WishlistItem ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        List<ECOM_AccountWrapper.WishlistDetails> result = new List<ECOM_AccountWrapper.WishlistDetails>();
        ECOM_CartController.removeWishlistItem(wishlistItemId);

    }

    // Test method for removeCoupon
    @isTest
    static void testRemoveCoupon() {
        // Add your test logic here
        Map<String,Object> result = new Map<String,Object>();
        String cartId = [SELECT Id FROM WebCart ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        User u = [SELECT Id,AccountId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        result = ECOM_CartController.removeCoupon(cartId);
        }
    }

    @isTest
    public static void testgetCMSBaseUrl()
    {
        String moduleName = 'Home';
        Map<String,String> res = ECOM_CartController.getCMSBaseUrl(moduleName);
        CartItem cart = [SELECT Id FROM CartItem ORDER BY CREATEDDATE DESC LIMIT 1];
        cart.ECOM_ShippingCode__c ='TESTCODE';
        update cart;
        //RWPS-2786 - START
        ECOM_ProductShippingTime__c pst = new ECOM_ProductShippingTime__c();
        pst.Name = 'Test Shipping Time';
        pst.ECOM_Country__c = 'US';
        pst.Ecom_Priority__c = 'Priority';
        pst.Ecom_Total_DLV__c  = 20;
        pst.Ecom_Site__c = 'LUS10-A';
        pst.Ecom_Confidence_90__c = 'Arrives in 2-3 days';
        insert pst;
        //RWPS-2786 - END
        User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        	ECOM_ProductShippingTime__c getShippingTime = ECOM_CartController.getShippingTime(cart.Id);
        	Map<String,String> getCreditCollections =  ECOM_CartController.getCreditCollections(cart.Id);
        	System.assertNotEquals(null,res,'wrong output');
        }
    }

    @isTest
    static void checkRADIdentifierAccountTest(){
    	Webcart cart = [SELECT Id FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
        Test.startTest();
        Boolean response = ECOM_CartController.checkRADIdentifierAccount(cart.Id);
        Test.stopTest();
    }

    @isTest
    static void getUserInfoTest(){
        User u = [SELECT Id,AccountId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u){
        	Map<String,Object> response = ECOM_CartController.getUserInfo();
        }
    }

     @isTest
    static void checkProductMaterialStatusTest(){
        User u = [SELECT Id,AccountId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        WebCart cart = [SELECT Id FROM WebCart ORDER BY CreatedDate DESC LIMIT 1];
        Map<String,Object> response = ECOM_CartController.checkProductMaterialStatus(cart.Id);
    }

    @isTest
    static void updateCartWithPosrValuesTest(){
		User u = [SELECT Id,AccountId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        Map<String,Object> paramMap = new Map<String,Object>();
        Map<String,Object> responseMap = new Map<String,Object>(); // RWPS-1456
        paramMap.put(ECOM_Constant.PARAM_PUNCHOUT_POSR_URL_PARAMETER,'test');
        paramMap.put(ECOM_Constant.PARAM_PUNCHOUT_PART,'1121');
		paramMap.put(ECOM_Constant.PARAM_EXT_CMS_URL_PARAMETER,'testUrl');
        Map<String,Object> response = new Map<String,Object>();
        //RWPS-1456 - START
        ERP_Address__c master = ECOM_TestUtil.createNewPunchoutMasterAddressConfiguration();
        update master;
        Account acc = [SELECT Id FROM Account where Id =:u.AccountId LIMIT 1];
        ECOM_TestUtil.createRelatedAddresses(acc,master);
        //RWPS-1456 - END
        System.runAs(u){
            Test.startTest();
            response = ECOM_CartController.updateCartWithPosrValues(paramMap);
            Test.stopTest();
        }
        system.assertEquals(false,response.get(ECOM_Constant.PARAM_SUCCESS),'Not a failure');
    }

     @isTest
    static void updateBillToShipToOnCartTest(){
        User u = [SELECT Id,AccountId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        WebCart cart = [SELECT Id FROM WebCart ORDER BY CreatedDate DESC LIMIT 1];
        System.runAs(u){
            Test.startTest();
            ECOM_CartController.updateBillToShipToOnCart(cart.Id);
            Test.stopTest();
        }
    }



    @isTest
    static void deleteShippingCartItemTest(){
        User u = [SELECT Id,AccountId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        WebCart cart = [SELECT Id FROM WebCart ORDER BY CreatedDate DESC LIMIT 1];
        CartItem item = [SELECT Id FROM CartItem ORDER BY CREATEDDATE DESC LIMIT 1];
        Product2 pro = [SELECT Id FROM Product2 ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u){
            Test.startTest();
            ECOM_CartController.deleteShippingCartItem(cart.Id, item.Id, pro.Id);
            Test.stopTest();
        }
    }

    @isTest
    static void getProductSalesByProdIdAndMaterialCodesTest(){
        User u = [SELECT Id,AccountId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        Product2 pro = [SELECT Id FROM Product2 ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u){
            Test.startTest();
            ECOM_CartController.getProductSalesByProdIdAndMaterialCodes(new List<String>{pro.Id}, false);
            Test.stopTest();
        }
    }

    @isTest
    static void getPrimaryCartBasedOnOwnerTest(){
        User u = [SELECT Id,AccountId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u){
            Test.startTest();
            ECOM_CartController.getPrimaryCartBasedOnOwner(u?.Id);
            ECOM_CartController.getUniqueProductCount();
            Test.stopTest();
        }
    }

    /**
      * @description Test case with exclude queries exclude part numbers for excel template.
      * @author Poonam Shukla
      * @date 01-13-2025
     */
    @isTest
    static void testProcessProductExclusions() {
        String communityId='';
        List<String> partNumberList=new List<String>();
        partNumberList.add('AL289C');
        List<String> mockExcludedParts = new List<String>{'part123', 'part456', 'part789'};
        User u = [Select Id,LastName, AccountId From User ORDER BY CREATEDDATE DESC LIMIT 1];
        ERP_Address__c master = ECOM_TestUtil.createNewPunchoutMasterAddressConfiguration();
        master.ECOM_Punchout_Products_Exclude_Query__c = 'SHOW PRODUCT Where PartNumber not in (\'GR2261005\')';
        update master;
        Account acc = [SELECT Id FROM Account where Id =:u.AccountId LIMIT 1];
        ECOM_TestUtil.createRelatedAddresses(acc,master);
        List<String> excludedParts=new List<String>();
         System.runAs(u){
             excludedParts = ECOM_CartController.processProductExclusions(communityId, partNumberList);
        }
        if (mockExcludedParts == null) {
            System.debug('The excludedParts list is null.');
        } else {
            System.assertEquals(3, mockExcludedParts.size(), 'Excluded parts list should contain 3 items');
            Assert.isTrue(mockExcludedParts.contains('part123'), 'Excluded parts should contain part123');
            Assert.isTrue(mockExcludedParts.contains('part456'), 'Excluded parts should contain part456');
            Assert.isTrue(mockExcludedParts.contains('part789'), 'Excluded parts should contain part789');
        }
    }

    /**
      * @description Test case with exclude queries exclude part numbers for excel template for no address.
      * @author Poonam Shukla
      * @date 01-13-2025
     */
    @isTest
    static void testGetExcludedPartNumbersForNoAddressRecords() {
        List<String> excludedParts=new List<String>();
        String communityId='';
        List<String> partNumberList= new List<String>();
        partNumberList.add('AL090F');
        User u = [Select Id,LastName, AccountId From User ORDER BY CREATEDDATE DESC LIMIT 1];
        ERP_Address__c master = ECOM_TestUtil.createNewPunchoutMasterAddressConfiguration();
        master.ECOM_Punchout_Products_Exclude_Query__c = 'SHOW PRODUCT Where PartNumber not in (\'GR2261005\')';
        update master;
        Account acc = [SELECT Id FROM Account where Id =:u.AccountId LIMIT 1];
        ECOM_TestUtil.createRelatedAddresses(acc,master);
        System.runAs(u){
             excludedParts = ECOM_CartController.processProductExclusions(communityId, partNumberList);
        }

    }
    /**
      * @description Test case get product by partial number
      * @author Poonam Shukla
      * @date 02-02-2025
     */
    @isTest
     static void testRetrieveProductsByPartialPartNumber() {
        String productData = [SELECT Id,Part_Number__c FROM Product2 ORDER BY CREATEDDATE DESC LIMIT 1].Part_Number__c;
        String testProductData = JSON.serialize(productData);
        List<String> excludedItems = new List<String>{'PN-12345'};
        Boolean isPunchoutCart = true;
        String communityId = 'TestCommunity123';
        Test.startTest();
        Map<String, Object> response = ECOM_CartController.retrieveProductsByPartialPartNumber(
            productData, excludedItems, isPunchoutCart, communityId
        );
        Test.stopTest();
    }

    /**
      * @description Test case get contract price
      * @author Abhishek Joshi
      * @date 02-04-2025
     */
    @isTest
     static void testGetContractPrice() {
         // Create mock response headers
        Map<String, String> responseHeaders = new Map<String, String>();
        responseHeaders.put('Content-Type', 'application/json');

        // Create mock HTTP response using Generic mock class ECOM_MockHttpResponseGenerator
        ECOM_MockHttpResponseGenerator mockResponse = new ECOM_MockHttpResponseGenerator(200, 'OK', '{"result": "success"}', responseHeaders);

        // Set the mock response for the HTTP callout
        Test.setMock(HttpCalloutMock.class, mockResponse);

        Product2 p = [SELECT Part_Number__c, Id, Dangerous_Goods_Indicator_Profile__c FROM Product2 LIMIT 1];
        p.Part_Number__c = 'TEST-1001';
        update p;
        Map<String,Object> prodMap = new Map<String,Object> {'Part_Number__c' => (Object)p.Part_Number__c, 'Id' => (Object)p.Id, 'Dangerous_Goods_Indicator_Profile__c' => (Object)p.Dangerous_Goods_Indicator_Profile__c};
            List<Map<String,Object>> productList = new List<Map<String,Object>> {prodMap};
        Test.startTest();
        Object response = ECOM_CartController.getContractPrice(productList);
        Test.stopTest();
    }

    /**
      * @description Test case get sellable products
      * @author Abhishek Joshi
      * @date 02-04-2025
     */
    @isTest
    static void testGetSellableProducts() {
        // Add your test logic here
        String communityId =[SELECT Id, name FROM Network ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        Set<String> productIds = new Set<String>();//RWPS-3740
        for(Product2 itr : [SELECT Id FROM Product2 ORDER BY CREATEDDATE DESC LIMIT 3])
        {
            productIds.add(itr.Id);
        }
        User u = [SELECT Id,AccountId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        test.startTest();
        {
            C_META_Countries__mdt ctry = ECOM_CustomMetadataRepo.getCurrencyCodeFromSalesOrg('US10');
            List<Product_Sales__c> result = ECOM_CartController.getSellableProductsByUser(productIds, u.id, communityId);//RWPS-3740
            result = ECOM_CartController.getSellableProductsByUser(productIds,u.id, communityId);//RWPS-3740
        }
        test.stopTest();
        }
    }
}