/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-####
*    ECOM-96
*    ECOM-493
*    ECOM-####
*
* 2. Description - This class is invoked from shopping cart page, it does add to cart, update cart, add to favourites, order simulation calls.
*				 - This class return, Update,Delete Cart Items Records
				 - This class Create WebCart Record and add Item to cart
				 - Create wishlist and Wishlist Item Record
*
*
* 3. Objects referenced
*    -WebCart
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_CartUtil
*    - ECOM_SalesforceAPI
*    - ECOM_CartService
*
* 6. Test Class Name:
*    - ECOM_CartController_Test
*
* 7. Is @Invocable: No
*
* 8. Author Name(s):
*    - Manoj Kumar 2023.07.23
*    - Dar Wright 2023.09.15
*    - vramachandran@rafter.one | 05 Jan 2024
*    - Sidak 2024.01.16 Updated method deleteCartItem. Ticket - ECOM-1384
*    - Sidak 2024.01.25 Added method checkProductMaterialStatus. Ticket - ECOM-2224
*    - Sidak 2024.02.06 Added logs in getCartSummary, getCreditCollections, updateCartItem methods. Ticket - RWPS-95
*    - Sidak 2024.01.25 Updated method removeWishlistItem. Ticket - ECOM-2604
*    - Vasudev 2024.02.21 Fix for RWPS-179
*    - Sidak 2024.03.01 Added method updateCartItemListPrice. Ticket - RWPS-182
*    - Sidak 2024.04.16 Added method retrieveProductsByPartialPartNumber. Ticket - RWPS-29
*    - Manoj 2024-05-06 RWPS-622 Hide Availability date when the Order contains an Instrument(updated getCartItemsWrapped method to support large pack shipping)
*    - Sidak 2024.05.15 Added method deleteShippingCartItem Ticket - RWPS-632
*    - Sidak 2024.05.17 Updated method updateCartWithPosrValues - Added posr values in logging Ticket - RWPS-723
*    - Sidak 2024.05.21 Added method updateBillToShipToOnCart. Ticket - RWPS-766
*    - Sidak 2024.06.04 Added logic to update Contact on Cart in getCartSummary method. Ticket - RWPS-708
*    - Sidak 2024.06.18 Updated method updateCartWithPosrValues - Added exception cause in logging  - RWPS-723
*    - Sidak 2024.07.16 Added methods getPrimaryCartBasedOnOwner, getProductSalesByProdIdAndMaterialCodes. Ticket - RWPS-949
*    - Sidak 2024.08.30 Updated method removeCoupon - Added exception logging. Ticket - RWPS-1372
*    - Sidak 2024.09.09 Updated method retrieveProductsByPartialPartNumber. Added logic to check valid sales status of the product Ticket - RWPS-1477
*    - Manoj 2024.10.08 RWPS-1653 Exception log - Attempt to de-reference a null object on cart update
*    - Sidak 2024.10.15 Updated method retrieveProductsByPartialPartNumber. Added parameter communityId Ticket - RWPS-1582
*    - Sidak 2024.11.29 Updated method getCartItemsWrapped. Cleared cache when cart is emptied. Ticket - RWPS-2107
*    - Sidak 2024.12.16 Updated method updateCartWithPosrValues - Moved getCMSBaseUrl logic. Ticket - RWPS-2168
*    - Poonam 2025.01.10 Added method processProductExclusions. Added logic for handling exclude partnumbers for Punchout users - RWPS-2132
*    - Poonam 2025.02.07 Updated method processProductExclusions. Changed paarmater partnumberquantitylist to partnumberlist
*    - Abhishek 2025.03.25 Added method getContractPrice - RWPS-2858
*    - Prabhat 2025.04.25 Updated method getCartItemsWrapped. Added logic to get tariff Surcharge amount-RWPS-3026
*    - Abhishek 2025.03.25 Added method getSellableProducts - RWPS-3003
*    - Prabhat 2025.06.20 Updated method getCartItemsWrapped  to get discontinued products and sales status of the products - RWPS-2786
*    - Prabhat 2025.07.11 Updated method getShippingTime to get the shipping time data - RWPS-1603
*    - Chirag  2025.07.14 Updated method updateCartItemListPrice to support quantity as a parameter - RWPS-3683
*    - Abhishek 2025.07.15 Updated method getSellableProducts - RWPS-3697
*    - Abhishek 2025.10.03 Updated method getSellableProducts and getSellableProductsByUser - RWPS-4437
*    - Prabhat 2025.10.03 Updated method getCartItemsWrapped - RWPS-3740
*    - Prabhat 2025.10.06 Updated method getCartItemsWrapped and changed the variable name to allReplacement - RWPS-3740
*    - Prabhat 2025.12.16 Updated the getCartItemWrapped method to retrieve only training data - RWPS-4896
*    - Poonam 2025.12.23 Updated the getCartItemWrapped method to add try catch block - RWPS-5153

*************************************************************/
public with sharing class ECOM_CartController {

  private static final String CLASS_NAME = 'ECOM_CartController';//VRa - Punchout changes

  private static ECOM_ICartService cartService;//VRa - Punchout changes

//This is a wrapper class for productcodes received from ecom_quickOrder
public class ECOM_ProductWrapper {
  @AuraEnabled
  public String partNumber;
  @AuraEnabled
  public String quantity;
}

/**  // will be removed later
 * @description Demonstrates how to call ConnectApi.CommerceCart.getCartItems
 * @param  communityId The Id of the community from which the call originated
 * @param effectiveAccountId ID of the account for which the request is made. If null, defaults to the account ID for the context user.
 * @param activeCartOrId ID of the cart, active, or current.
 * @param productFields Specifies fileds to be shown in cart item card.
 * @param pageParam Specifies the page token to be used to view a page of information.
 * @param sortParam Sort order for items in a cart.
 * @return CartItemCollection A collection of cart items
 */
@AuraEnabled
public static ConnectApi.CartItemCollection getCartItems(
    String communityId,
    String effectiveAccountId,
    String activeCartOrId,
    String productFields,
    String pageParam,
    String sortParam
) {
    /*
  // Lookup the webstore ID associated with the community
    String webstoreId = ECOM_Util.resolveCommunityIdToWebstoreId(communityId);

    // Get the ConnectApi.CartItemSortOrder enum value from string.
    // For the list of possible values, see:
    // see https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/connectAPI_enums.htm#cartItemSortOrderEnum
    ConnectApi.CartItemSortOrder resolvedSortParam = ECOM_CartUtil.resolveSortParam(
    sortParam
    );

    // For more details, see:
    // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceCart_static_methods.htm
    // write test wrapper for Connect Api
    ConnectApi.CartItemCollection response = Test.isRunningTest() ? null: ConnectApi.CommerceCart.getCartItems(
        webstoreId,
        effectiveAccountId,
        activeCartOrId,
        productFields,
        pageParam,
        100,
        resolvedSortParam
    );*/
    return null;
}








/**
* @description
* @author mkumar@rafter.one | 08-18-2023
* @param communityId
* @param effectiveAccountId
* @param activeCartOrId
* @param productFields
* @param pageParam
* @param sortParam
* @return Map<String, Object>
**/
@AuraEnabled
public static Map<String,Object> getCartItemsWrapped(
    String communityId,
    String effectiveAccountId,
    String activeCartOrId,
    String productFields,
    String pageParam,
    String sortParam
) {
  Map<String,Object> cartItemsMap = new Map<String,Object>();
  try {//RWPS-5153
     Map<String,Object> shippingDatesMap = new Map<String,Object>();
    Map<String,Object> tariffSurchargeMap = new Map<String,Object>();//RWPS-3026
    Map<String,Boolean> salesStatusMap = new Map<String,Boolean>();
    Map<String,Boolean> discontinuedProductMap = new Map<String,Boolean>();//RWPS-2786
    Map<String, Object> replacementProductsMap = new Map<String, Object>(); // RWPS-3740
    Map<String,Boolean> trainingProductMap = New Map<String,Boolean>();//RWPS-4896
    Map<String,Boolean> genericTrainingProductMap = New Map<String,Boolean>();//RWPS-4896
    String moduleNameDiscontinued = 'DiscontinuedProduct';//RWPS-2786
    Map<String,Boolean> errorLogFieldMap = new Map<String,Boolean>();//RWPS-5153
    //RWPS-622
    Boolean isLargePackOrder = false;
    //get existing shipping dates
    List<CartItem> sdList = ECOM_CartService.getCartItemsShippingDates(activeCartOrId);

    String webstoreId = ECOM_Util.resolveCommunityIdToWebstoreId(communityId);
    ConnectApi.CartItemSortOrder resolvedSortParam = ECOM_CartUtil.resolveSortParam(
    sortParam
    );

  //get cart items using connect api
    ConnectApi.CartItemCollection response = Test.isRunningTest() ? null: ConnectApi.CommerceCart.getCartItems(webstoreId,effectiveAccountId,activeCartOrId,productFields,pageParam,100,resolvedSortParam);
    List<WebCart> activeCarts = ECOM_CartRepo.getCartandCartItemsById(activeCartOrId);
    Set<String> productIds = new Set<String>();
    for(CartItem item : sdList) {
      //RWPS-3026
      if(item.Tariff_Surcharge__c != null){
          tariffSurchargeMap.put(item.id, item);
      }
      shippingDatesMap.put(item.id, item);
      productIds.add(item.Product2Id);
        //RWPS-622
        if(!isLargePackOrder && (item.Product2.Item_Class__c=='1' || item.Product2.Item_Class__c=='2')){
            isLargePackOrder = true;
        }
    }
    //RWPS-4896
    List<Product_Recommendation__c> productRecommendList = ECOM_ProductRecommendationsRepo.getRecommendationsTrainingProducts('Combination',productIds);
    List<Product_Recommendation__c> genericProductRecommendList = ECOM_ProductRecommendationsRepo.getRecommendationsTrainingProducts('Combination',new Set<String>()); //RWPS-4896
    for(Product_Recommendation__c pr : productRecommendList){

       if(productIds.contains(pr.Product_Main__c)){
          trainingProductMap.put(pr.Product_Suggested__c, true);//RWPS-4896
       }
       //RWPS-4896
    }

    //RWPS-4896
    for(Product_Recommendation__c genericRecommendation : genericProductRecommendList) {
      if (genericRecommendation.Product_Suggested__c != null) {
          genericTrainingProductMap.put(genericRecommendation.Product_Suggested__c, true);
      }
    }
    //RWPS-4896

    String moduleName = 'ECOM_CartService';
    //RWPS-2786 - Start
    List<String> materialCodesDiscontinued = ECOM_CartUtil.fetchProductMaterialStatus(moduleNameDiscontinued);
    List<Product_Sales__c> prodSalesDisContinued = ECOM_ProductService.getProductSales(productIds, materialCodesDiscontinued);

    for (Product_Sales__c prod : prodSalesDisContinued) {
      if(materialCodesDiscontinued.contains(prod.Distribution_ChainSpecificMaterialStatus__c)){
        discontinuedProductMap.put(prod.Product__c, true);
      }
      else {
        discontinuedProductMap.put(prod.Product__c, false);
      }
    }
    //RWPS-2786 - End
    //RWPS-5153 start
    Map<String,String> cartStoreConfigs = ECOM_CartRepo.getStorefrontFrontConfigByModule('ErrorLogField');   
    String reqField = cartStoreConfigs.get(ECOM_Constant.ERROR_LOG_FIELD);  
    Map<String, Boolean> logFieldMap = new Map<String, Boolean>();
    if (!String.isBlank(reqField)) {
        for (String str : reqField.split(',')) {
            logFieldMap.put(str.trim(), true);
        }
    }//RWPS-5153 end 
    List<String> materialCodes = ECOM_CartUtil.fetchProductMaterialStatus(moduleName);
    List<Product_Sales__c> prodSales = ECOM_ProductService.getProductSales(productIds, materialCodes);
    Map<String,String> productToSalesStatus = new Map<String,String>();
    for (Product_Sales__c prod : prodSales) {
      productToSalesStatus.put(prod.Product__c, prod.Distribution_ChainSpecificMaterialStatus__c);
      if(prod.Distribution_ChainSpecificMaterialStatus__c == 'ZM'){
        salesStatusMap.put(prod.Product__c, true);
      }
      else {
        salesStatusMap.put(prod.Product__c, false);
      }
    }
    replacementProductsMap = ECOM_ProductUtil.getReplacementMap(communityId, productIds); // RWPS-3740
    if(response!=null && response.cartItems.size() == 0){ //RWPS-2107
      ECOM_SessionCacheUtil.clearEcomCache();
    }
    cartItemsMap.put('dataLayer',ECOM_Util.parseDataLayerModel(activeCarts));
    cartItemsMap.put('productSalesStatus',productToSalesStatus);
    cartItemsMap.put('connectApi',response);
    cartItemsMap.put('dates',shippingDatesMap);
    cartItemsMap.put('salesStatus', salesStatusMap);
    cartItemsMap.put('discontinuedProducts', discontinuedProductMap);//RWPS-2786
    cartItemsMap.put('trainingProducts', trainingProductMap);//RWPS-4896
    cartItemsMap.put('genericTrainingProducts', genericTrainingProductMap);//RWPS-4896
    if (replacementProductsMap.isEmpty() == false) { // RWPS-3740
      cartItemsMap.put('allReplacement',  replacementProductsMap);//RWPS-3740
    }
    //RWPS-3026
    cartItemsMap.put('tariffSurcharge', tariffSurchargeMap);
    //RWPS-622
    cartItemsMap.put('isLargePackOrder', isLargePackOrder);
    cartItemsMap.put('cart',activeCarts.size() > 0 ? activeCarts[0]: null);
    cartItemsMap.put('logFieldError', logFieldMap);//RWPS-5153
    return cartItemsMap;
  } catch (Exception e) {
    cartItemsMap.put('success', false);
    cartItemsMap.put('message', e.getMessage());
    ECOM_ApplicationLogsUtil.logFailure(e, ECOM_Constant.USER_MODULE_NAME, 'CartController',  'getCartItems', 'CartId=' + activeCartOrId + ', AccountId=' + effectiveAccountId, UserInfo.getUserName());
    return cartItemsMap;
  }//RWPS-5153 end
}


/**
* @description Demonstrates how to call ConnectApi.CommerceCart.updateCartItem
* @param  communityId The Id of the community from which the call originated
* @param effectiveAccountId ID of the account for which the request is made. If null, defaults to the account ID for the context user.
* @param activeCartOrId ID of the cart, active, or current.
* @param cartItemId ID of the cart item to be updated.
* @return CartItem The updated cart item
*/
@AuraEnabled
public static ConnectApi.CartItem updateCartItem(
  String communityId,
  String effectiveAccountId,
  String activeCartOrId,
  String cartItemId,
  ConnectApi.CartItemInput cartItem
) {
  ConnectApi.CartItem cartItems;
  String supportData = JSON.serialize(cartItemId);
  String methodName = 'updateCartItem';
  try {
    // Lookup the webstore ID associated with the community
    String webstoreId = ECOM_Util.resolveCommunityIdToWebstoreId(communityId);

    cartItems = Test.isRunningTest() ? null:  ECOM_SalesforceAPI.updateCartItem(webstoreId, effectiveAccountId, activeCartOrId, cartItemId, cartItem);
  } catch (Exception ex) {
    ECOM_ApplicationLogsUtil.logFailure(ex, 'Update Cart Item', CLASS_NAME, methodName, supportData);
}
return cartItems;
}

/**
* @description Updates the List Price on the Cart Item. Ticket RWPS-182
* @author ssingh@rafter.one | 03-01-2024
* @param cartItemId Id of cart item to be updated.
* @param listPrice Sales price of cart item. Removed as part of RWPS-3683
* @param salesPrice Sales price of cart item. Removed as part of RWPS-3683
* @param quantity Quantity of cart item.
* @return List<CartItem> The updated cart item
*/
@AuraEnabled
public static List<CartItem> updateCartItemListPrice(
  Id cartItemId,
  Integer quantity // RWPS-3683
) {
  String supportData = JSON.serialize(cartItemId);
  String methodName = 'updateCartItemListPrice';
  List<CartItem> cartItemList = new List<CartItem>();
  try {
    cartItemList = ECOM_CartService.updateCartItemListPrice(cartItemId, quantity); // RWPS-3683
  } catch (Exception ex) {
    ECOM_ApplicationLogsUtil.logFailure(ex, 'Update Cart Item Price', CLASS_NAME, methodName, supportData);
}
return cartItemList;
}

/**
* @description Updates the Bill To/Ship To on the Cart. Ticket RWPS-766
* @author ssingh@rafter.one | 05-31-2024
* @param cartId Id of cart to be updated.
*/
@AuraEnabled
public static void updateBillToShipToOnCart(
  String cartId
) {
  String supportData = cartId;
  String methodName = 'updateBillToShipToOnCart';
  try {
    ECOM_CartService.updateBillToShipToOnCart(cartId);
  } catch (Exception ex) {
    ECOM_ApplicationLogsUtil.logFailure(ex, 'Update Bill To Ship To', CLASS_NAME, methodName, supportData);
}
}

/**
* @description This method is used to delete cart items
* @param activeCartOrId ID of the cart, active, or current.
* @param cartItemId ID of the cart item to be deleted.
* @param productId ID of the product to be deleted.
*/
@AuraEnabled
public static void deleteCartItem(
String activeCartOrId,
String cartItemId,
String productId
) {
  ECOM_CartService.deleteCartItem(activeCartOrId,cartItemId,productId);
}

/**
* @description Deleted the Shipping cart item List Price on the Cart Item. Ticket RWPS-632
* @author ssingh@rafter.one | 05-15-2024
* @param activeCartOrId ID of the cart, active, or current.
*/
@AuraEnabled
public static void deleteShippingCartItem(
String activeCartOrId,
String cartItemId,
String productId
) {
  ECOM_CartService.deleteShippingCartItem(activeCartOrId);
}


/**
* @description Demonstrates how to call ConnectApi.CommerceCart.getCartSummary
* @author Sidak 2023.06.04 | Added logic to update Contact on Cart | RWPS-708
* @param  communityId The Id of the community from which the call originated
* @param effectiveAccountId ID of the account for which the request is made. If null, defaults to the account ID for the context user.
* @param activeCartOrId ID of the cart, active, or current.
*/
@AuraEnabled
public static ConnectApi.CartSummary getCartSummary(
String communityId,
String effectiveAccountId,
String activeCartOrId
) {
  ConnectApi.CartSummary cartSummary;
  String supportData = JSON.serialize(activeCartOrId);
  String methodName = 'getCartSummary';
  try {
    // Lookup the webstore ID associated with the community
    String webstoreId = ECOM_Util.resolveCommunityIdToWebstoreId(communityId);
    if(String.isBlank(activeCartOrId)){
      activeCartOrId = 'active';
    }
// For more details, see:
// https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceCart_static_methods.htm
 cartSummary = Test.isRunningTest() ? null:  ECOM_SalesforceAPI.getOrCreateActiveCartSummary(webstoreId, effectiveAccountId,activeCartOrId);
    List< WebCart > cartsToUpdate = new List< WebCart >();
    WebCart cart = ECOM_CartRepo.getPrimaryCartBasedOnId(cartSummary.cartId);
    if( cart.Contact__c == null || String.isBlank(cart.Contact__c)){
        User user = ECOM_UserRepo.getUserByUserId(UserInfo.getUserId());
        cart.Contact__c = user.ContactId;
        cartsToUpdate.add(cart);
         ECOM_CartRepo.updateCart(cartsToUpdate);
     }

} catch (Exception ex) {
    ECOM_ApplicationLogsUtil.logFailure(ex, 'Get Cart Summary', CLASS_NAME, methodName, supportData);
  }
  return cartSummary;
}

/**  // will me removed later
* @description Demonstrates how to call ConnectApi.CommerceCart.createCart
* @param  communityId The Id of the community from which the call originated
* @param effectiveAccountId ID of the account for which the request is made. If null, defaults to the account ID for the context user.
*/
@AuraEnabled
public static ConnectApi.CartSummary createCart(
String communityId,
String effectiveAccountId
) {
// Lookup the webstore ID associated with the community
String webstoreId = ECOM_Util.resolveCommunityIdToWebstoreId(communityId);
ConnectApi.CartInput cartInput = new ConnectApi.CartInput();
cartInput.effectiveAccountId = effectiveAccountId;
// For more details, see:
// https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceCart_static_methods.htm
return Test.isRunningTest() ? null :ECOM_SalesforceAPI.createCart(webstoreId, cartInput);
}

/**  // will me removed later
* @description Demonstrates how to call ConnectApi.CommerceCart.deleteCart
* @param  communityId The Id of the community from which the call originated
* @param effectiveAccountId ID of the account for which the request is made. If null, defaults to the account ID for the context user.
* @param activeCartOrId ID of the cart, active, or current.
*/
@AuraEnabled
public static void deleteCart(
String communityId,
String effectiveAccountId,
String activeCartOrId
) {
// Lookup the webstore ID associated with the community
String webstoreId = ECOM_Util.resolveCommunityIdToWebstoreId(communityId);

// For more details, see:
// https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceCart_static_methods.htm

if(!Test.isRunningTest())
{
  ECOM_SalesforceAPI.deleteCart(webstoreId, effectiveAccountId, activeCartOrId);
}
}


// will me removed later
@AuraEnabled
public static ConnectApi.WishlistsSummary getWishlistSummaries(
String communityId,
String effectiveAccountId
) {
// Lookup the webstore ID associated with the community
String webstoreId = ECOM_Util.resolveCommunityIdToWebstoreId(communityId);
Map<String,String> fieldsMap = getFieldsByObjectName('Product2');
List<ConnectApi.WishlistItemSortOrder> listSortItemsBy = ConnectApi.WishlistItemSortOrder.values();
// https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceWishlist_static_methods.htm#apex_ConnectAPI_CommerceWishlist_static_methods
return Test.isRunningTest()?null:ECOM_SalesforceAPI.getWishlistSummaries(webstoreId,effectiveAccountId,'',listSortItemsBy);
}
// will me removed later
@AuraEnabled
public static ConnectApi.WishlistItem createAndAddToList(
String communityId,
String productId,
String wishListId,
String effectiveAccountId
) {
  // Lookup the webstore ID associated with the community
  String webstoreId = ECOM_Util.resolveCommunityIdToWebstoreId(communityId);
  ConnectApi.Wishlist wishlist;
  ConnectApi.WishlistItem wishListItem;
  // Store the product in a WishlistItemInput to pass to the Wishlist
  ConnectApi.WishlistItemInput wishlistItemInput = new ConnectApi.WishlistItemInput();
  wishlistItemInput.productId = productId;



if(String.isNotBlank(wishListId)){
    wishListItem = !Test.isRunningTest()?  ECOM_SalesforceAPI.addItemToWishlist( webstoreId, effectiveAccountId, wishListId,  wishlistItemInput) : ECOM_TestUtil.getWishlistItemData();
}else{
    //Create a wishlistInput to be created
    ConnectApi.WishlistInput wishlistInput = new ConnectApi.WishlistInput();
    wishlistInput.name = 'My favorite list';
    wishlistInput.products = new List<ConnectApi.WishlistItemInput>{
      wishlistItemInput
    };
    wishlist =  !Test.isRunningTest() ?  ECOM_SalesforceAPI.createWishlist(webstoreId,effectiveAccountId,wishlistInput): ECOM_TestUtil.getWishlistData();

    ConnectApi.WishlistItemCollection collection =  wishlist.page;
    List<ConnectApi.WishlistItem> wishListItems = collection.items;
    wishListItem = wishListItems.size() > 0? wishListItems[0] : null;
  }
return wishListItem;
}


/**
* @description This method is used to fetch the fields associated with the object
* @author mkumar@rafter.one | 08-18-2023
* @param objectName
* @return Map<String, String>
**/
@AuraEnabled
public static Map<String,String> getFieldsByObjectName(
String objectName
) {
Map<String,String> fieldsMap = ECOM_Util.getFieldsByObjectName(objectName);
return fieldsMap;
}

/**
* @description  This method invokes order simulate Api
* @author ssingh@rafter.one | 01-25-2024
* @param cartId
* @return Map<String, Object>
**/
@AuraEnabled
public static Map<String,Object> checkProductMaterialStatus(String cartId) {
Map<String,Object> response = ECOM_CartService.checkProductMaterialStatus(cartId);
return response;
}

/**
* @description  This method invokes order simulate Api
* @author mkumar@rafter.one | 07-28-2023
* @param cartId
* @return Map<String, Object>
**/
@AuraEnabled
public static Map<String,Object> repriceCart(String cartId, String couponCode) {
Map<String,Object> response = ECOM_CartService.repriceCart(cartId, couponCode);
return response;
}

/**
* @description
* @author mkumar@rafter.one | 08-18-2023
* @param communityId
* @param effectiveAccountId
* @param cartItems
* @return Map<String, Object>
**/
@AuraEnabled
public static Map<String,Object> addItemsToCart(String communityId,
String effectiveAccountId,
List<CartItem> cartItems
) {

Map<String,Object> response = ECOM_CartService.addItemsToCart(communityId,effectiveAccountId,cartItems);
return response;
}


/**
* @description  This method is used to delete cart items by Id
* @author mkumar@rafter.one | 08-18-2023
* @param cartItemIds
**/
@AuraEnabled
public static void deleteCartItemsById(List<Id> cartItemIds)
{
ECOM_CartService.deleteCartItemsById(cartItemIds);
}

/**
* @description  This method is used to delete cart items for a product
* @author mkumar@rafter.one | 08-25-2023
* @param cartItemId
**/
@AuraEnabled
public static void deleteCartItemsforProductId(Id productId, Id cartId)
{
ECOM_CartService.deleteCartItemsforProductId(productId, cartId);
}


/**
* @description This method is used to update shipping date on cart item
* @author mkumar@rafter.one | 08-18-2023
* @param cartItemId
* @param shipDate
**/
@AuraEnabled
public static void updateShippingDateOnCartItem(Id cartItemId, Date shipDate)
{
ECOM_CartService.updateShippingDateOnCartItem(cartItemId, shipDate);
}

/**
* @description This function is used to retrieve the products based on the product codes.
* @author Vipul Goyal | 07-31-2023
* @param productCodes
* @return Map<String, Object>
**/
@AuraEnabled
public static Map<String,Object> retrieveProductsByPartNumber(String productData)
{
List<ECOM_ProductWrapper> productCodes=(List<ECOM_ProductWrapper>)JSON.deserialize(productData, List<ECOM_ProductWrapper>.class);
Map<String,Object> response = ECOM_CartService.retrieveProductsByPartNumber(productCodes);
return response;
}

/**
* @description This function is used to retrieve the products based on the partial product codes.
* @author Sidak Singh | 04-16-2024
* @author Sidak Singh | 09-09-2024 | RWPS-1477
* @author Sidak Singh | 10-15-2024 | RWPS-1582
* @param productCodes
* @return Map<String, Object>
**/
@AuraEnabled
public static Map<String,Object> retrieveProductsByPartialPartNumber(String productData,List<String> excludedItems,Boolean isPunchoutCart, String communityId)
{
//List<ECOM_ProductWrapper> productCodes=(List<ECOM_ProductWrapper>)JSON.deserialize(productData, List<ECOM_ProductWrapper>.class);
Map<String,Object> response = ECOM_CartService.retrieveProductsByPartialPartNumber(productData, excludedItems, isPunchoutCart, communityId);
return response;
}


/**
* @description  This method is used to check if the user has a RAD Identifier Account
* @author mkumar@rafter.one | 08-14-2023
* @return Boolean
**/
@AuraEnabled
public static Boolean checkRADIdentifierAccount(String cartId)
{
Boolean response = ECOM_CartService.isRADIdentifierAccount(cartId);
return response;
}


/**
* @description
* @author mkumar@rafter.one | 09-21-2023
* @return List<ECOM_AccountWrapper.WishlistDetails>
**/
@AuraEnabled
public static List<ECOM_AccountWrapper.WishlistDetails> getWishlistDetails()
{
  Type accountService = Type.forName(ECOM_Constant.ACCOUNT_SERVICE);
  ECOM_IAccountService accountServiceInstance = (ECOM_IAccountService)accountService.newInstance();
  List<WishList> wls = accountServiceInstance.fetchWishList(UserInfo.getUserId());
  List<ECOM_AccountWrapper.WishlistDetails> wishListDetails = ECOM_AccountUtil.getWishListDetails(wls);
  return wishListDetails;
}

/**
* @description
* @author ssingh@rafter.one | 02-19-2024
* @param wishlistItemId
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
* @description
* @author mkumar@rafter.one | 09-21-2023
* @author ssingh@rafter.one | 08-30-2024 | RWPS-1372
* @param cartId
* @return Map<String, Object>
**/
@AuraEnabled
public static Map<String,Object> removeCoupon(String cartId) {
  Map<String,Object> response = new Map<String,String>();
  String supportData = 'Cart Id: ' + cartId;
  String methodName = 'removeCoupon';
  try {
    response = ECOM_CartService.removeCoupon(cartId);
  } catch (Exception ex) {
    ECOM_ApplicationLogsUtil.logFailure(ex, 'Remove coupon', CLASS_NAME, methodName, supportData);
  }
  return response;
}

/**
* @description
* @author mkumar@rafter.one | 09-21-2023
* @param moduleName
* @return Map<String, String>
**/
@AuraEnabled
public static Map<String,String> getCMSBaseUrl(String moduleName) {
    Map<String,String> cartStoreConfigs = ECOM_CartRepo.getStorefrontFrontConfigByModule(moduleName);
  return cartStoreConfigs;
}

/**
* @description  This method is used to get the Shipping Time Frame based on the Item Shipping Code
* @author dar.wright@rafter.one | Sept 14th 2023
* @param itemId
* @return ECOM_ProductShippingTime__c
**/
@AuraEnabled
public static ECOM_ProductShippingTime__c getShippingTime(String itemId)
{
    return ECOM_CartService.getShippingTimeObj(itemId);//RWPS-1603
}

/**
* @description  This method is used to get the Credit Collection Emails from Custom Metadata
* @author ssingh@rafter.one | Sept 14th 2023
* @param moduleName
* @return Map<String,String>
**/
@AuraEnabled
public static Map<String,String> getCreditCollections(String moduleName)
{
  Map<String,String> response = new Map<String,String>();
  String supportData = '';
  String methodName = 'getCreditCollections';
  try {
    response = ECOM_CartService.getCreditCollections(moduleName);
} catch (Exception ex) {
    ECOM_ApplicationLogsUtil.logFailure(ex, moduleName, CLASS_NAME, methodName, supportData);
  }
  return response;
}

/**
* @description  This method is used to get the user details for validating address on cart
* @author manish.kumar@rafter.one | Nov 29th 2023
* @return Map<String,String>
**/
@AuraEnabled
public static Map<String,Object> getUserInfo(){

String supportData = 'quering user data';
String methodName = 'getUserInfo';
Map<String,Object> responseMap = new  Map<String,Object>();
try {
        Type userService = Type.forName(ECOM_Constant.USER_Service);
        ECOM_IUserService userServiceInstance = (ECOM_IUserService)userService.newInstance();
        User user = userServiceInstance.getUserByUserId();
        responseMap.put('status','SUCCESS');
        responseMap.put('user',user);
} catch (Exception ex) {
  system.debug('Exception '+ex);
  ECOM_ApplicationLogsUtil.logFailure(ex, '', 'ECOM_CartController', methodName, supportData);
}
return responseMap;
}

/**
   * @description This method checks if a active cart exists for punchout user and updates the cart with posr values
   * @author vramachandran@rafter.one | 05 Jan 2024
   * @author ssingh@rafter.one | 17 May 2024 | Added posr values in logging | RWPS-723
   * @param posrValues | String
   * @return Map<String,Object>
   */
  @AuraEnabled
  public static Map<String,Object> updateCartWithPosrValues(Map<String,Object> paramMap){
      Map<String,Object> responseMap = new Map<String,Object>();

      String posrValues = (String) paramMap.get(ECOM_Constant.PARAM_PUNCHOUT_POSR_URL_PARAMETER);
      String poPartNumber = (String) paramMap.get(ECOM_Constant.PARAM_PUNCHOUT_PART);
      String cmsParams = (String) paramMap.get(ECOM_Constant.PARAM_EXT_CMS_URL_PARAMETER);
      String displayUrl;
      posrValues = ECOM_EncryptUtil.decryptWithAES256(posrValues);
      try{
          String decryptedString = ECOM_EncryptUtil.decryptWithAES256(cmsParams);
          String sessionStartTimeStamp = String.valueOf(DateTime.now().millisecond());


          //decryptedString = decryptedString + '&' + ECOM_Constant.PARAM_EXT_SESSION_STARTED_TIMESTAMP + '=' + timeStamp;
          //decryptedString = decryptedString + '&' + ECOM_Constant.PARAM_EXT_IF_SESSION_STARTED_FLAG + '=' + String.valueOf(1);

          //responseMap.put(ECOM_Constant.PARAM_RESPONSE_DATA, ECOM_EncryptUtil.encryptWithAES256(decryptedString));
          //RWPS-3026 - Start
          String encrypted;
		  if(!Test.isRunningTest()){
          	 encrypted = EncodingUtil.urlEncode(ECOM_EncryptUtil.encryptWithAES256(decryptedString), 'UTF-8');
          }
          //RWPS-3026 - End
          try { //RWPS-2168
              responseMap = ECOM_CartService.updatePunchoutCart(UserInfo.getUserId(), posrValues);
          }
          catch (Exception ex) {
          }
          responseMap.putAll(getCMSBaseUrl(System.Label.ECOM_CMSSiteUrl)); //RWPS-2168
          //get ERP Address model for punchout user locale
          //User userRecord = ECOM_UserUtil.getPunchoutUserForUserId(UserInfo.getUserId());
          // RWPS-1653
          User userRecord = ECOM_UserRepo.getUserByUserId(UserInfo.getUserId());
          ERP_AddressModel addressModel = ERP_AddressUtil.getPunchoutAddressesForAccountId(userRecord.AccountId);
          if(String.isNotEmpty(poPartNumber)){
              List<Product2> products = ECOM_SAPOrderSummaryRepo.getProductsBasedOnPartnumber(new set<String>{poPartNumber});
              if(null != products && !products.isEmpty()){
                  displayUrl = products[0].DisplayUrl;
                  responseMap.put(ECOM_Constant.PARAM_EXT_PRODUCT_URL, displayUrl);
              }
          }
          responseMap.put(ECOM_Constant.PARAM_LOCALE, (null != addressModel && String.isNotEmpty(addressModel.po_Locale)) ? addressModel.po_Locale : '' );
          responseMap.put(ECOM_Constant.PARAM_RESPONSE_DATA, EncodingUtil.urlEncode(encrypted, 'UTF-8'));
          System.debug('responseMap:: '+ JSON.serialize(responseMap));
      }catch(Exception e){
          responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
          System.debug('Cause:: '+ e.getCause() + ' ' + e.getMessage() + ' Exception:: '+ e.getStackTraceString());
          ECOM_ApplicationLogsUtil.logFailure(e, 'Punchout:: Update POSR To Cart - Failed', CLASS_NAME , 'getCartModelForPOOM', 'Message:: '+ e.getMessage()+ 'Cause:: ' + e.getCause() + 'stack trace:: ' + e.getStackTraceString() + ' POSR Values:: ' + posrValues);
      }
      return responseMap;
  }

  /**
  * @description This method returns  a map with the total unique product Count
  * @author vramachandran@rafter.one | 16 Feb 2024
  * @return Map<String, Object>
  **/
  @AuraEnabled
  public static Map<String,Object> getUniqueProductCount() {
      return ECOM_CartService.getUniqueProductCount();
  }

  /**
  * @description This method is used to fetch Owner's primary cart
  * @author ssingh@rafter.one | 07-16-2024
  * @param userId
  * @return Map<String, Object>
  **/
  @AuraEnabled
  public static List<WebCart> getPrimaryCartBasedOnOwner(String userId) {
    return ECOM_CartService.getPrimaryCartBasedOnOwner(userId);
  }

  /**
  * @description  This method is used to fetch sales status of product
  * @author ssingh@rafter.one | 07-16-2024 | RWPS-949
  * @param productIds
  * @param isPunchoutCart
  * @return Map<String, Object>
  **/
  @AuraEnabled
  public static Map<String,Object> getProductSalesByProdIdAndMaterialCodes(List<String> productIds, Boolean isPunchoutCart) {
    Map<String,Object> response = ECOM_CartService.getProductSalesByProdIdAndMaterialCodes(productIds, isPunchoutCart);
    return response;
  }

  /**
  * @description This method returns excluded product for logged in user
  * @author Poonam Shukla | 01-10-2025
  * @params communityId | String, partNumberQuantityList | List<String>
  * @return List<String>
  **/
  @AuraEnabled
  public static List<String> processProductExclusions(String communityId, List<String> partNumberList) {
    List<String> excludedParts = ECOM_ProductService.getExcludedPartNumbers(communityId, partNumberList);
    return excludedParts;
  }

  /**
  * @description This method returns the contract price
  * @author Abhishek Joshi | 03-26-2025
  * @params products | List<Map<String,Object>>
  * @return Map<String,Object>
  **/
  @AuraEnabled
  public static Object getContractPrice(List<Map<String,Object>> products){
    List<String> radIndicators = new List<String>{'yes', 'y', 'rad'};
    Object returnData;

    try {
      Map<String,String> addressMap =
          ECOM_CartUtil.getAddressesForCallout();
      List<Map<String,Object>> productMap = new List<Map<String,Object>>();
      for (Map<String,Object> product : products) {
        String rad =
            (String)product.get('Dangerous_Goods_Indicator_Profile__c');
        if(String.isBlank(rad)) {
          rad = '';
        }
        Map<String,Object> productMapItem =
            new Map<String,Object>{
                'part_number' => product.get('Part_Number__c'),
                'is_rad' =>
                    (Object)radIndicators.contains(rad.toLowerCase())
            };

        productMap.add(productMapItem);
      }

      Map<String,Object> requestMap =
          new Map<String,Object>{
              'bill_to' => (Object)addressMap.get('billTo'),
              'Ship_to' => (Object)addressMap.get('shipTo'),
              'country' => (Object)addressMap.get('country'),
              'product_list' => (Object) productMap
          };

      String requestString = JSON.serialize(requestMap);
      HttpResponse httpRes = new HttpResponse();

      httpRes = ECOM_RestService.doBasicHttpRequest(ECOM_Util.generateRequestMap(requestString, 'ContractPrice'));

      if(
          httpRes.getStatusCode() == 200
          && httpRes.getStatus() == 'OK'
      ) {
        returnData = JSON.deserializeUntyped(httpRes.getBody());
      }
    } catch (Exception e) {
      System.debug('Cause:: '+ e.getCause() + ' ' + e.getMessage() + ' Exception:: '+ e.getStackTraceString());
      ECOM_ApplicationLogsUtil.logFailure(e, 'Get contract price - Failed', CLASS_NAME , 'getContractPrice', 'Message:: '+ e.getMessage()+ 'Cause:: ' + e.getCause() + 'stack trace:: ' + e.getStackTraceString());
    }

    return returnData;
  }

  /**
  * @description This method returns the sellable products by user
  * @author Abhishek Joshi | 2025.09.17
  * @params productIdSet | Set<String>
  * @params userId | String
  * @params communityId | String
  * @return List<Product_Sales__c>
  **/
  public static List<Product_Sales__c> getSellableProductsByUser(Set<String> productIdSet, String userId, String communityId){
    try {

      // RWPS-4437 - START
      User user = ECOM_UserRepo.getUserByUserId(userId);
      if(user==null)
          return new List<Product_Sales__c>();
      Boolean isPunchoutCart = user?.ECOM_Is_Punchout_User__c;

      List<String> materialCodes =
        ECOM_CartUtil.fetchProductMaterialStatus(
          isPunchoutCart
          ? 'ECOM_Punchout' : 'ECOM_CartService'
        );
      // RWPS-4437 - END

      return ECOM_ProductUtil.getProudctSalesByProductIds(
          productIdSet,
          materialCodes,
          communityId,
          isPunchoutCart,
          userId
        );
    } catch (Exception e) {System.debug('Cause:: '+ e.getCause() + ' ' + e.getMessage() + ' Exception:: '+ e.getStackTraceString());
      ECOM_ApplicationLogsUtil.logFailure(e, 'Get sellable products - Failed', CLASS_NAME , 'getSellableProductsByUser', 'Message:: '+ e.getMessage()+ 'Cause:: ' + e.getCause() + 'stack trace:: ' + e.getStackTraceString());
    } return null;
  }

  /**
  * @description This method returns the sellable products
  * @author Abhishek Joshi | 2025.07.15
  * @params productIds | List<String>
  * @params salesOrg | String
  * @params communityId | String
  * @return List<Product_Sales__c>
  **/
  @AuraEnabled
  public static List<Product_Sales__c> getSellableProducts(List<String> productIds, String salesOrg, String communityId){
    try {
      // RWPS-3697 start
      Boolean guestUser = Auth.CommunitiesUtil.isGuestUser();

      Set<String> productIdSet = new Set<String>(productIds);
      List<String> materialCodes = guestUser ? ECOM_CartUtil.fetchProductMaterialStatus('ECOM_CartService') : new List<String>();

      if(guestUser) {return ECOM_ProductUtil.getSellableProductsForGuest(productIdSet, materialCodes, communityId, salesOrg);}
      // RWPS-3697 end

      String userId = UserInfo.getUserId();

      return getSellableProductsByUser(productIdSet, userId, communityId); // RWPS-3740
    } catch (Exception e) {System.debug('Cause:: '+ e.getCause() + ' ' + e.getMessage() + ' Exception:: '+ e.getStackTraceString());
      ECOM_ApplicationLogsUtil.logFailure(e, 'getSellableProducts', CLASS_NAME , 'getSellableProducts', 'Message:: '+ e.getMessage()+ 'Cause:: ' + e.getCause() + 'stack trace:: ' + e.getStackTraceString());
    } return null;
  }


}