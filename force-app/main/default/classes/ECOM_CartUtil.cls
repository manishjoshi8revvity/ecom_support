/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-
*	 ECOM-2554
*
* 2. Description - This class acts as an utility class for webcart.
*				 - return Webcart record, create webcart record, get webcart record
				 - Parse ConnectApi.CartSummary data from Conect API to ECOM_CartModel
				 - Given a community ID, returns the relavent webstore ID for use in B2B Commerce on lightning
*
*
* 3. Objects referenced
*    -WebCart
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
*
* 5. Dependant Class(es):
*    - ECOM_UserUtil
*    - ECOM_CartController
*
* 6. Test Class Name:
*    - ECOM_CartUtil_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vipul 2023.07.19
*    - Manoj 2023.07.19
*    - Dar Sept 13th 2023 ECOM-493
*	 - Vasudev R 2023.12.08
*	 - Vasudev R 2024.02.14 : ECOM-2554
*    - Sidak 2024.02.27 Added a fix for Entity is deleted logs.
*    - Gaurang 2024.03.06 RWPS-213 - mapping to new fields and some changes for existing ones as discussed on the ticket
*    - Sidak 2024.03.27 RWPS-394 - Replaced ECOM_POSR_Browser_Form_Post__c with ECOM_POSR_Browser_Form_Post_Url__c
*    - Gaurang 2024.04.03 RWPS-410 - mapping to ECOM Punchout Default UNSPSC on ERP address
*    - Sidak 2024.04.08 - Updated method generateOrderSimulationRequest with User & Contact paramaters & to check for Default Bill to/Ship to on Cart and Contact. Ticket - RWPS-415
*    - Sidak 2024.04.29 - Updated method updateCartItems, removed the check for tax greater than 0 . Ticket - RWPS-551
*    - Manoj 2024-05-01 RWPS-584 Instrument freight not applying as expected on web orders(Updated generateOrderSimulationRequest method  to support large pack shipping logic)
*    - Sidak 2024.05.27 - Updated method generateOrderSimulationRequest, Updated logic to get external Id from ERP Address of Contact. Ticket - RWPS-766
*    - Manoj 2024.05.28 - RWPS-741 SFB2B - Technical - Trim down the Fetch User API - Remove Cart Items
*    - Sidak 2024.06.10 - Updated method generateOrderSimulationRequest, Updated logic to populate bill to/ship to from metadata. Ticket - RWPS-843
*    - Manoj 2024.06.14 - RWPS-586 - New processor needed for our OCI response to send to Galapagos via EDI
*    - Manoj 2024.06.17 - RWPS-1041 - user had two carts within 0 seconds(Revert code as it is not working in production)
*    - Sidak 2024.07.10 - Updated method validateProductMaterialStatus, Added logic to fetch material status based on punchout/non-punchout cart. Ticket - RWPS-949
*    - Manoj 2024.08.21 - read billing country code from payer instead account (Updated generateOrderSimulationRequest method) RWPS-1305
*    - Sidak 2024.08.30 - read billing country code from payer instead account for both mapped & unmapped user (Updated generateOrderSimulationRequest method) RWPS-1305
*    - Manoj 2024.09.09 - RWPS-1387 read image from Product2.ECOM_Product_Media_URI__c(DAM) instead product media
*    - Sidak 2024.09.16 - Updated method validateProductMaterialStatus, Added logic for logging and error message if product sales record in not found. Ticket - RWPS-1401
*    - Sidak 2024.09.20 - Added method populateCartDetailsWithCartItems. Ticket - RWPS-1535
*    - Sidak 2024.11.20 - Updated method generateOrderSimulationRequest, Added logic to pick country code from contact if bill to of cart is null. Ticket - RWPS-1773
*    - Sidak 2024.11.26 - Updated method generateOrderSimulationRequest, Added logic to pick bill to/ship to from contact if bill to/ship to on cart is null. Ticket - RWPS-2080
*    - Poonam 2025.01.03 - Updated validateProductMaterialStatus Added custom material code logic for punchout user RWPS- 1456
*    - Manish Joshi 2025.01.27 - Updated method parseCartItems to get product display name & instead of name - RWPS-2270
*    - Poonam 2025.02.07 - Updated fetchProductMaterialStatus. Added custom material code logic for punchout user RWPS- 1456
*    - Prabhat 2025.03.18 - Updated method updateCartItems,generateOrderSimulationRequest, created method updateCartItemListPrice to update the list price of cart items. RWPS-2683
*    - Abhishek 2025.03.25 Added method getAddressesForCallout - RWPS-2858
*    - Prabhat Kumar 2025.04.10 Updated updateCartItems and getPoomCartItemModel to update shipping line item cost in POOM request - RWPS-2941
*    - Gaurav Bhansali 2025.04.21 Added isLargePackItemExist method to check if large pack item exist in cart or not - RWPS-1285
*    - Prabhat Kumar 2025.04.25 Updated updateCartItems and added createCartDeliveryTariffCharge, getDefaultTariffSurchargeProduct2Id to add Tariff Surcharge line item - RWPS-3026
*    - Prabhat Kumar 2025.05.08 Updated updateCartItems to tariff_Surcharge is not null  - RWPS-3026
*    - Prabhat Kumar 2025.06.10 - Updated method updateCouponAndDiscount, updateCartItemListPrice to apply condition on Total savings- RWPS-3262
*    - Poonam 2025.06.11 - Added the isInvoiceEmailExist method to verify whether the Invoice Email Address exists on the Contact's Default Bill to ERP Address - RWPS-1882
*    - Prabhat Kumar 2025.06.20 - Updated methods validateProductMaterialStatus, updateCartItems, fetchProductMaterialStatus and added methods updateDiscountinuedProducts, updateDiscontinuedCartItem,
       getNonSellableDiscountinuedProducts, fetchNonSellableDiscontinuedCartItems- RWPS-2786
*    - Gaurav Bhansali 2025.06.27 - Added methods getInActiveProducts to get non sellable and discontinue products- RWPS-2786
*    - Chirag Lapasia 2025.07.02 - Added logic to remove non sellable and discontinued products- RWPS-2786
*    - Prabhat Kumar 2025.17.7 - Updated getPoomCartItemModels to add lead times attribute in POOM request - RWPS-3658
*    - Gaurav Bhansali 2025.06.27 - Updated methods generateOrderSimulationRequest,updateCartItems and updateCouponAndDiscount for BOGO implementation- RWPS-3811
*    - Chirag L 2025.08.25 Updated method isInvoiceEmailExist to get the invoice email from payer's target address in case of mapped customer - RWPS-4154
*    - Gaurav Bhansali 2025.09.03 - Added getCartItemDetailsMap and Updated updateCouponAndDiscount for BOGO implementation- RWPS-4202
*    - Prabhat Kumar 2025.09.11 - Updated updateCartItems, generateOrderSimulationRequest to add ECOM SAP Line Number field on the cart items - RWPS-3811
*    - Manish Joshi 2025.09.25 - Updated method updateCartItems added CurrencyIsoCode value - RWPS-4500
*    - Poonam Shukla 2025.10.01 - Updated updateCouponAndDiscount to fix total Savings issue on mixed promo cart- RWPS-4630
*    - Abhishek J 2025.10.04 - Updated fetchProductMaterialStatus method for replacement - RWPS-3740
*    - Manish Joshi 2025.10.16 - Updated method generateOrderSimulationRequest,getOrderType - RWPS-4848
*    - Mahesh Suthar 2025.10.06 -  Updated updateCartItems method - Added continue to prevent split item deletion - RWPS-4081
*    - Poonam Shukla 2025.10.28 -  Updated updateCartItems method and updateCouponAndDiscount to fix split quantity and its saving issue - RWPS-4081
*    - Prabhat Kumar 2025.12.03 -  Updated validateProductMaterialStatus to fix training product with non sellable - RWPS-4896
*    - Prabhat Kumar 2026.01.07 -  Updated methods getPoomModel and getPoomCartItemModel to include tariff charges - RWPS-5603
*    - Prabhat Kumar 2026.01.14 -  Updated methods getPoomModel and getPoomCartItemModel to exclude tariff charges - RWPS-5603
*    - Prabhat Kumar 2026.02.04 -  Created methods updatePunchoutLogWithPOSRValues,updatePunchoutLogWithPOSRValues - RWPS-6095
*    - Prabhat Kumar 2026.03.05 -  Updated method updatePunchoutLogWithPOSRValues to get punchout format - RWPS-6095
*    - Poonam Shukla 2026.03.09 -  Added the isEInvoiceCustIdExist method to Check if EInvoiceCustId (Peppol ID) exists or not - RWPS-6394

*************************************************************/
public class ECOM_CartUtil {

    // A cache which maps community Ids to WebStore Ids
    private static Map<String, String> communityIdToWebStoreIdCache = new Map<String, String>();

    // A cache to map a string to ConnectApi.CartItemSortOrder
    private static Map<String, ConnectApi.CartItemSortOrder> sortOrderCache = new Map<String, ConnectApi.CartItemSortOrder>();

    /**
    * @description this method is used to fetch cart details.
    * @author Vipul Goyal | 07-19-2023
    * @param strOwnerId
    * @param effectiveAccountId
    * @param defaultShipToAccount
    * @param createNewCart
    * @return WebCart
    **/
    public static WebCart fetchCartDetails(String strOwnerId , String effectiveAccountId ,
                                           String defaultShipToAccount , Boolean createNewCart)
    {
        WebCart cartObject = null;
        if(String.isNotBlank(strOwnerId) && String.isNotBlank(effectiveAccountId))
        {
            List<WebCart> carts = ECOM_CartRepo.getPrimaryCartBasedOnOwner(strOwnerId);
            if(carts.isEmpty() && createNewCart)
            {
                createNewCart(strOwnerId,effectiveAccountId,defaultShipToAccount);
                carts = ECOM_CartRepo.getPrimaryCartBasedOnOwner(strOwnerId);
            }
            if(!carts.isEmpty())
            {
                cartObject = carts[0];
            }
        }
        return cartObject;
    }

    //this method is used to create a new cart.
  /**
   * @description Given a sortParam string, return null or the relavent ConnectApi.CartItemSortOrder enum value
   * See https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/connectAPI_enums.htm#cartItemSortOrderEnum for the enum values
   * @param strOwnerId A string representing Id of the Owner.
   * @param effectiveAccountId A string representing effectiveAccountId of the User.
   * @param defaultShipToAccount A string representing Id of ship to Account
   *
   * @example
   * ConnectApi.CartItemSortOrder sortParam = B2BUtils.resolveSortParam('CreatedDateAsc');
   */
    public static void createNewCart(String strOwnerId, String effectiveAccountId, String defaultShipToAccount)
    {
        ConnectApi.CartInput cartInputObject = new ConnectApi.CartInput();
        List<WebCart> cartsToUpdate = new List<WebCart>();
        cartInputObject.effectiveAccountId = effectiveAccountId;
        cartInputObject.isSecondary = true;
        List<WebStore> webStores= ECOM_WebStoreRepo.getWebStoreByName(Label.ECOM_WebStore_Name);
        Type userService = Type.forName(ECOM_Constant.USER_Service);
        ECOM_IUserService userServiceInstance = (ECOM_IUserService)userService.newInstance();
        User user = userServiceInstance.getUserByUser(strOwnerId);
        if(!webStores.isEmpty())
        {
            String webstoreId = webStores[0].Id;
            ConnectApi.CartSummary cartSummaryObject = ECOM_CartRepo.createCart(webstoreId , cartInputObject);
            if(cartSummaryObject!=null)
            {
                WebCart webNewCartObject = new WebCart();
                webNewCartObject.Id = cartSummaryObject.cartId;
                webNewCartObject.OwnerId = strOwnerId;

                if(User != null && User.ContactId != null){
                	webNewCartObject.CurrencyIsoCode = user.Account.CurrencyIsoCode;
                    webNewCartObject.Default_Ship_to_ERP_Address__c = user.Contact.Default_Ship_to_ERP_Address__c;
                    webNewCartObject.Default_Bill_to_ERP_Address__c = user.Contact.Default_Bill_to_ERP_Address__c;
            	}
                cartsToUpdate.add(webNewCartObject);
                ECOM_CartRepo.updateCart(cartsToUpdate);
                If(!Test.isRunningTest())
                {
                    ConnectApi.CommerceActionResult commerceActionResultObject = ConnectApi.CommerceCart.makeCartPrimary(webstoreId ,cartSummaryObject.cartId , effectiveAccountId);
                }
            }
        }
    }

  /**
   * @description Given a sortParam string, return null or the relavent ConnectApi.CartItemSortOrder enum value
   * See https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/connectAPI_enums.htm#cartItemSortOrderEnum for the enum values
   * @param  sortParam A string representing a sort Param.
   * @return resolvedSortParam A ConnectApi.CartItemSortOrder enum value or null
   * @example
   * ConnectApi.CartItemSortOrder sortParam = B2BUtils.resolveSortParam('CreatedDateAsc');
   */
    public static ConnectApi.CartItemSortOrder resolveSortParam(
        String sortParam
    ) {
        if (sortOrderCache.isEmpty()) {
            for (
                ConnectApi.CartItemSortOrder sortOrder : ConnectApi.CartItemSortOrder.values()
            ) {
                sortOrderCache.put(sortOrder.name(), sortOrder);
            }
        }
        return sortOrderCache.get(sortParam);
    }

    /**
    * @description  Parse ConnectApi.CartSummary data from Conect API to ECOM_CartModel
    * @author mkumar@rafter.one | 09-21-2023
    * @param cartSummary
    * @return ECOM_CartModel
    **/
    public static ECOM_CartModel parseCartSummary(ConnectApi.CartSummary cartSummary){
        ECOM_CartModel cart = new ECOM_CartModel();
        cart.accountId = cartSummary.accountId;
        cart.cartId = cartSummary.cartId;
        cart.currencyIsoCode = cartSummary.currencyIsoCode;
        cart.grandTotalAmount = cartSummary.grandTotalAmount;
        cart.isSecondary = cartSummary.isSecondary;
        cart.name = cartSummary.name;
        cart.ownerId = cartSummary.ownerId;
        cart.purchaseOrderNumber = cartSummary.purchaseOrderNumber;
        cart.status = String.valueOf(cartSummary.status);
        cart.taxType = String.valueOf(cartSummary.taxType);
        cart.totalChargeAmount = cartSummary.totalChargeAmount;
        cart.totalListPrice = cartSummary.totalListPrice;
        cart.totalProductAmount = cartSummary.totalProductAmount;
        cart.totalProductAmountAfterAdjustments = cartSummary.totalProductAmountAfterAdjustments;
        cart.totalProductCount = cartSummary.totalProductCount;
        cart.totalPromotionalAdjustmentAmount = cartSummary.totalPromotionalAdjustmentAmount;
        cart.totalTaxAmount = cartSummary.totalTaxAmount;
        cart.type = String.valueOf(cartSummary.type);
        cart.uniqueProductCount = cartSummary.uniqueProductCount;
        cart.webstoreId = cartSummary.webStoreId;
        cart.messagesSummary = null;
        cart.cartItems = null;
        return cart;
    }

    // Parse WebCart data to ECOM_CartModel
    public static List<ECOM_CartModel> parseWebCarts(List<WebCart> webCarts){
        List<ECOM_CartModel> carts = new List<ECOM_CartModel>();
        Map<String, List<CartItem>> prodIdToCartItems = new Map<String, List<CartItem>>();
        Map<String, Decimal> parentProdToQty = new Map<String, Decimal>();
        for(WebCart c :WebCarts){
            List<ECOM_CartItemModel> items = new List<ECOM_CartItemModel>();
            ECOM_CartModel cart = new ECOM_CartModel();
            cart.cartId = c.Id;
            cart.accountId = c.AccountId;
            cart.currencyIsoCode = c.CurrencyIsoCode;
            cart.grandTotalAmount = String.valueOf(c.GrandTotalAmount);
            cart.isSecondary = c.IsSecondary;
            cart.name = c.Name;
            cart.ownerId = c.OwnerId;
            cart.purchaseOrderNumber = c.PoNumber;
            cart.status = String.valueOf(c.Status);
            cart.taxType = String.valueOf(c.TaxType);
            cart.totalChargeAmount = String.valueOf(c.TotalChargeAmount);
            cart.totalListPrice = String.valueOf(c.TotalListAmount);
            cart.totalProductAmount = String.valueOf(c.TotalProductAmount);
            cart.totalProductAmountAfterAdjustments = String.valueOf(c.TotalAdjustmentAmount);
            cart.totalProductCount = String.valueOf(c.TotalProductCount);
            cart.totalPromotionalAdjustmentAmount = String.valueOf(c.TotalPromoAdjustmentAmount);
            cart.totalTaxAmount = String.valueOf(c.TotalTaxAmount);
            cart.type = String.valueOf(c.Type);
            cart.uniqueProductCount = c.UniqueProductCount;
            cart.totalSaving = c.ECOM_Total_Savings__c!=null?String.valueOf(c.ECOM_Total_Savings__c):'0';
            cart.webstoreId = c.WebStoreId;
            cart.messagesSummary = null;
            cart.cartItems = null;
            cart.isPunchoutCart = null != c?.ECOM_Is_Punchout_Cart__c ? c?.ECOM_Is_Punchout_Cart__c : false;  //VRa - Punchout Changes
            for(CartItem cartItem : c.cartItems){
                ECOM_CartItemModel cItem = new ECOM_CartItemModel();
                cItem.cartItemId = cartItem.Id;
                cItem.productId = cartItem.Product2Id;
                cItem.quantity = String.valueOf(cartItem.Quantity);
                cItem.listPrice = String.valueOf(cartItem.ListPrice);
                cItem.salesPrice = String.valueOf(cartItem.SalesPrice);
                cItem.totalAdjustmentAmount = String.valueOf(cartItem.TotalAdjustmentAmount);
                cItem.totalAmount = String.valueOf(cartItem.TotalAmount);
                cItem.totalListPrice = String.valueOf(cartItem.TotalListPrice);
                cItem.totalPrice = String.valueOf(cartItem.TotalPrice);
                cItem.totalTax = String.valueOf(cartItem.TotalTaxAmount);
                cItem.type = cartItem.Type; //RWPS-1401
                cItem.unitAdjustedPrice = String.valueOf(cartItem.UnitAdjustedPrice);
                cItem.unitAdjustmentAmount = String.valueOf(cartItem.UnitAdjustmentAmount);
                //RWPS-1387
                if(cartItem?.Product2?.ECOM_Product_Media_URI__c !=null){
                	cItem.thumbnailImageURL = cartItem?.Product2?.ECOM_Product_Media_URI__c;
                }
                //Prepare product id to cart items map  - split cart items
                if(prodIdToCartItems.containsKey(cartItem.Product2Id)){
                    prodIdToCartItems.get(cartItem.Product2Id).add(cartItem);
                } else {
                    prodIdToCartItems.put(String.valueOf(cartItem.Product2Id), new List<CartItem>{cartItem});
                }
                if(cartItem.ECOM_Parent__c == null){
                    items.add(cItem);
                }
            }
            cart.cartItems = items;
        	carts.add(cart);
        }
        for(String prodId :prodIdToCartItems.keySet()){
            // if the list of cart items per product is more than one - split cart item
            if(prodIdToCartItems.get(prodId).size() > 1){
                Decimal qty = 0;
                for(CartItem ci :prodIdToCartItems.get(prodId)){
                    // sum up all split cart item quantities
                    qty += ci.Quantity;
                }
                parentProdToQty.put(prodId, qty);
            }
        }
        // update parent cart item quantity with total quantity from child cart items
        for(ECOM_CartModel cModel : carts){
            for(ECOM_CartItemModel ciModel :cModel.cartItems){
                if(parentProdToQty != null && parentProdToQty.get(ciModel.productId) != null ){
                    ciModel.quantity = String.valueOf(parentProdToQty.get(ciModel.productId));
                }
            }
        }
        return carts;
    }

    /**
    * @description parse cart to ECOM_CartModel
    * @author Manoj  | 05-28-2024
    * @param cartId
    * @return ECOM_CartModel
    **/
     public static List<ECOM_CartModel> parseWebCartsWithoutCartItems(List<WebCart> webCarts){
        List<ECOM_CartModel> carts = new List<ECOM_CartModel>();
        Map<String, List<CartItem>> prodIdToCartItems = new Map<String, List<CartItem>>();
        Map<String, Decimal> parentProdToQty = new Map<String, Decimal>();
        for(WebCart c :WebCarts){
            List<ECOM_CartItemModel> items = new List<ECOM_CartItemModel>();
            ECOM_CartModel cart = new ECOM_CartModel();
            cart.cartId = c.Id;
            cart.accountId = c.AccountId;
            cart.currencyIsoCode = c.CurrencyIsoCode;
            cart.grandTotalAmount = String.valueOf(c.GrandTotalAmount);
            cart.isSecondary = c.IsSecondary;
            cart.name = c.Name;
            cart.ownerId = c.OwnerId;
            cart.purchaseOrderNumber = c.PoNumber;
            cart.status = String.valueOf(c.Status);
            cart.taxType = String.valueOf(c.TaxType);
            cart.totalChargeAmount = String.valueOf(c.TotalChargeAmount);
            cart.totalListPrice = String.valueOf(c.TotalListAmount);
            cart.totalProductAmount = String.valueOf(c.TotalProductAmount);
            cart.totalProductAmountAfterAdjustments = String.valueOf(c.TotalAdjustmentAmount);
            cart.totalProductCount = String.valueOf(c.TotalProductCount);
            cart.totalPromotionalAdjustmentAmount = String.valueOf(c.TotalPromoAdjustmentAmount);
            cart.totalTaxAmount = String.valueOf(c.TotalTaxAmount);
            cart.type = String.valueOf(c.Type);
            cart.uniqueProductCount = c.UniqueProductCount;
            cart.totalSaving = c.ECOM_Total_Savings__c!=null?String.valueOf(c.ECOM_Total_Savings__c):'0';
            cart.webstoreId = c.WebStoreId;
            cart.messagesSummary = null;
            cart.cartItems = null;
            cart.isPunchoutCart = null != c?.ECOM_Is_Punchout_Cart__c ? c?.ECOM_Is_Punchout_Cart__c : false;  //VRa - Punchout Changes
        	carts.add(cart);
        }

        return carts;
    }
    /**
    * @description Parse ConnectApi.CartItem data to ECOM_CartItemModel
    * @author mkumar@rafter.one | 09-21-2023
    * @param cartItem
    * @return ECOM_CartItemModel
    **/
    public static ECOM_CartItemModel parseCartItem(ConnectApi.CartItem cartItem){
        ECOM_CartItemModel cItem = new ECOM_CartItemModel();
        cItem.cartItemId = cartItem.cartItemId;
        cItem.productId = cartItem.productId;
        cItem.quantity = cartItem.quantity;
        cItem.itemizedAdjustmentAmount = cartItem.itemizedAdjustmentAmount;
        cItem.listPrice = cartItem.listPrice;
        cItem.salesPrice = cartItem.salesPrice;
        cItem.totalAdjustmentAmount = cartItem.totalAdjustmentAmount;
        cItem.totalAmount = cartItem.totalAmount;
        cItem.totalListPrice = cartItem.totalListPrice;
        cItem.totalPrice = cartItem.totalPrice;
        cItem.totalTax = cartItem.totalTax;
        cItem.unitAdjustedPrice = cartItem.unitAdjustedPrice;
        cItem.unitAdjustmentAmount = cartItem.unitAdjustmentAmount;
        return cItem;
    }

   // Parse ConnectApi.CartItemCollection data from Connect API to List of ECOM_CartItemModel
    public static List<ECOM_CartItemModel> parseCartItems(ConnectApi.CartItemCollection cItems){
        List<ECOM_CartItemModel> items = new List<ECOM_CartItemModel>();
        for(ConnectApi.CartItemResult cItem :cItems.cartItems){
            ECOM_CartItemModel item = new ECOM_CartItemModel();
            ConnectApi.CartItem ci = (ConnectApi.CartItem)cItem.cartItem;
            //RWPS-1387
            ConnectApi.CartItemProduct productDetails = ci.productDetails ;
            item.thumbnailImageURL = '';
            if(productDetails!=null && productDetails?.fields!=null && productDetails?.fields.containsKey('ECOM_Product_Media_URI__c') ){
            	item.thumbnailImageURL = productDetails.fields.get('ECOM_Product_Media_URI__c');

            }
            //RWPS-2270 START
            if(productDetails!=null && productDetails?.fields!=null && productDetails?.fields.containsKey('Product_Display_Name__c') ){
            	String displayName = productDetails.fields.get('Product_Display_Name__c');
                item.cartItemName = displayName!=null?displayName:ci.name;
            }
            //RWPS-2270 END
            //item.thumbnailImageURL = Test.isRunningTest()?null:cItem.cartItem.productDetails.thumbnailImage.url;
            item.productId = cItem.cartItem.productId;
            item.quantity = cItem.cartItem.quantity;
            item.cartItemId = cItem.cartItem.cartItemId;
            //item.cartItemName = cItem.cartItem.name;//RWPS-2270
            item.totalPrice = ci.totalPrice;
            items.add(item);
        }
        return items;
    }



    /**
    * @description Parse List of ConnectApi.BatchResult data form Connect API to List ECOM_CartItemModel
    * @author mkumar@rafter.one | 09-21-2023
    * @param batchResults
    * @return List<ECOM_CartItemModel>
    **/
    public static List<ECOM_CartItemModel> parseCartItemsBatchResults(List<ConnectApi.BatchResult> batchResults){
      List<ECOM_CartItemModel> items = new List<ECOM_CartItemModel>();
      for (ConnectApi.BatchResult batchResult : batchResults) {
        if (batchResult.isSuccess()) {
            ConnectApi.CartItem cartItem;
            if(batchResult.getResult() instanceof ConnectApi.CartItem) {
                cartItem = (ConnectApi.CartItem) batchResult.getResult();
                ECOM_CartItemModel cartItemModel = parseCartItem(cartItem);
                items.add(cartItemModel);
            }
        }
      }
      return items;
    }

  /**
    * @description  This method is used to update prices from SAP.
    * @author mkumar@rafter.one | 07-28-2023
    * @param requestBody
    * @return Map<String, String>
    **/   
    public static List<CartItem> updateCartItems(WebCart cart,List<CartItem> cartItems, ECOM_SimulateOrderWrapper.OrderRequest orderRequest, ECOM_SimulateOrderWrapper.OrderResponse orderSimulateResponse){
        Map<String,CartItem> partNumberToCartItemMap = new Map<String,CartItem>();
        Map<String,CartTax> cartItemtoTaxMap = new Map<String,CartTax>();
        List<CartItem> cartItemsToInsert = new List<CartItem>();
        List<CartItem> cartItemsToUpsert = new List<CartItem>();
        List<CartItem> cartItemsToUpdate = new List<CartItem>();
        List<CartItem> itemsToDelete = new List<CartItem>();
        Set<String> cartItemsSet = new Set<String>();
        List<CartTax> cartTaxestoInsert = new List<CartTax>();
        Set<String> productIdSet = new Set<String>(); //RWPS-2786
        Id cartId = cartItems[0].CartId;
        Id cartDeliveryGroupId = cartItems[0].CartDeliveryGroupId;
        Id chargeTypeItemId;
        Id chargeTariffItemId; //RWPS-3026
        List<CartItem> tempCartItems = new List<CartItem>();//RWPS-3811
        for (CartItem item : cartItems) {
            cartItemsSet.add(item.Id);
            if(item.ECOM_Parent__c!=null || String.isNotBlank(item.ecom_parent_item__c))
            { //RWPS-3811 - delete free items before simulation call
                itemsToDelete.add(item);
                continue; //RWPS-4081
            }
            else{
                productIdSet.add(item.product2Id); //RWPS-2786
                partNumberToCartItemMap.put(item.Product2.Part_Number__c,item);
            }
            if(item.Type == 'Charge' && item.Name == 'Shipping Cost'){//RWPS-3026
                chargeTypeItemId = item.Id;
            }
            if(item.Type == 'Charge' && item.Name == 'Tariff Surcharge'){//RWPS-3026
                chargeTariffItemId = item.Id;
            }
            if(String.isBlank(item.ecom_parent_item__c)){//RWPS-3811
                tempCartItems.add(item);
            }
        }
            //move to repo class
        if(itemsToDelete.size() > 0){
            delete(itemsToDelete);    
        }

        List<String> lstDiscountinuedProducts = getNonSellableDiscountinuedProducts(productIdSet, 'discontinued');//RWPS-2786
        List<CartTax> cartItemTax = ECOM_CartRepo.getCartTaxRecords(cartItemsSet);
        for (CartTax tax : cartItemTax) {
            cartItemtoTaxMap.put(tax.CartItemId,tax);
        }
        Decimal shippingAmount = 0.0;
        Decimal tariffChargeAmount = 0.0;
        if (Test.isRunningTest()) {
            tariffChargeAmount = 50.0;
        }
        Integer count = 0;
            Decimal quantity; //RWPS-3811
            String freeParentItemId; //RWPS-3811
            if(orderSimulateResponse != null){//RWPS-2786 - START
            for (ECOM_SimulateOrderWrapper.ProductList product : orderSimulateResponse.productList) {
                    if(partNumberToCartItemMap.containsKey(product.partNumber) && product.itemDetail!=null){ //RWPS-3811
                    CartItem item = partNumberToCartItemMap.get(product.partNumber);
                    Decimal salesPrice = Decimal.valueOf(product.salesPrice);
                    Decimal cartItemShippingCost = product.freight + product.handling; //RWPS-2941
                    Date earliestShipDate;
                    quantity =0;
                    Boolean parentItem = false;
                    Decimal originalQuantity = 0;
                    Decimal roundedQuantity = 0;
                    Decimal quantityToAdd = 0;
                    CartItem cartItem;
                    String partNumber = product.partNumber;
                    Decimal tariffSurchargeCost = product.tariff_surcharge; //RWPS-3026
                    Integer lastIndex = product.itemDetail!=null?product.itemDetail.size() - 1:0;//RWPS-3811
                    freeParentItemId=item.id;
                    Decimal sapItemNumber = Decimal.ValueOf(product.itemNumber);//RWPS-3811
                    if(product.itemDetail!=null) //RWPS-3811
                    {
                        for (Integer i = 0; i < product.itemDetail.size(); i++){
                            if(Decimal.valueOf(product.itemDetail[i].availableQty) == 0 && product.itemDetail.size() > 1){
                                continue;
                            }
                            else if(Decimal.valueOf(product.itemDetail[i].availableQty) == 0 && product.itemDetail.size() == 1 && orderRequest.product_list[count].part_number == partNumber){
                                originalQuantity += orderRequest.product_list[count].quantity;
                                quantity = orderRequest.product_list[count].quantity;
                            }else{
                                originalQuantity +=  Decimal.valueOf(product.itemDetail[i].availableQty);
                                quantity = Decimal.valueOf(product.itemDetail[i].availableQty);
                                if(i == lastIndex && quantity > 0 && quantity < 1){
                                    quantity = 1;
                                }
                                else {
                                    quantity = quantity.round(System.RoundingMode.DOWN);
                                }
                            }
                            roundedQuantity += quantity;
                            quantityToAdd = originalQuantity - roundedQuantity;
                            earliestShipDate = Date.valueOf(product.itemDetail[i].availableDate);
                            if(!parentItem && quantity > 0){
                                parentItem = true;
                                if(quantityToAdd > 0 && i == lastIndex){ //RWPS-2941 and  RWPS-3026 Start - Added field to populate Shipping cost and Tariff_Surcharge__c RWPS-3811 - Added field ECOM_SAP_Line_Number__c = product.itemNumber
                                    cartItem = new CartItem(ECOM_SAP_Line_Number__c = sapItemNumber, Tariff_Surcharge__c = tariffSurchargeCost, ECOM_Shipping_Cost__c = cartItemShippingCost, SalesPrice =salesPrice,UnitAdjustedPrice =salesPrice,Quantity = (quantity+quantityToAdd),TotalLineAmount = (quantity+quantityToAdd)*salesPrice,TotalPrice = (quantity+quantityToAdd)*salesPrice,NetUnitPrice = salesPrice,ECOM_Earliest_Shipping_Date__c = earliestShipDate,ECOM_ShippingCode__c = product.shippingPoint,Id = item.Id);
                                }
                                else {
                                    cartItem = new CartItem(ECOM_SAP_Line_Number__c = sapItemNumber, Tariff_Surcharge__c = tariffSurchargeCost, ECOM_Shipping_Cost__c = cartItemShippingCost, SalesPrice =salesPrice,UnitAdjustedPrice =salesPrice,Quantity = quantity,TotalLineAmount = quantity*salesPrice,TotalPrice = quantity*salesPrice,NetUnitPrice = salesPrice,ECOM_Earliest_Shipping_Date__c = earliestShipDate,ECOM_ShippingCode__c = product.shippingPoint,Id = item.Id);
                                }
                            }else{
                                if((i < lastIndex && quantity > 0) || (i == lastIndex && quantityToAdd == 0 && quantity > 0)){
                                    cartItemsToInsert.add(new CartItem(ECOM_SAP_Line_Number__c = sapItemNumber, Tariff_Surcharge__c = tariffSurchargeCost, ECOM_Shipping_Cost__c = cartItemShippingCost, AdjustmentAmount = 0,CartDeliveryGroupId = item.CartDeliveryGroupId,CartId = item.CartId,ListPrice = item.ListPrice,Name = item.Product2.Name,Product2Id = item.Product2Id,Quantity = quantity,SalesPrice = salesPrice,Sku = product.partNumber,TotalAdjustmentAmount = 0,TotalLineAmount = quantity*salesPrice,ECOM_Parent__c = item.Id,TotalPrice = quantity*salesPrice,Type = 'Product',UnitAdjustmentAmount = 0,UnitAdjustedPrice = salesPrice,ECOM_ShippingCode__c =  product.shippingPoint,ECOM_Earliest_Shipping_Date__c = earliestShipDate,CurrencyISOCode = item.CurrencyISOCode));
                                }
                                else if(i == lastIndex && quantityToAdd > 0 && quantity > 0){
                                    cartItemsToInsert.add(new CartItem(ECOM_SAP_Line_Number__c = sapItemNumber, Tariff_Surcharge__c = tariffSurchargeCost, ECOM_Shipping_Cost__c = cartItemShippingCost, AdjustmentAmount = 0,CartDeliveryGroupId = item.CartDeliveryGroupId,CartId = item.CartId,ListPrice = item.ListPrice,Name = item.Product2.Name,Product2Id = item.Product2Id,Quantity = (quantity+quantityToAdd),SalesPrice = salesPrice,Sku = product.partNumber,TotalAdjustmentAmount = 0,TotalLineAmount = (quantity+quantityToAdd)*salesPrice,ECOM_Parent__c = item.Id,TotalPrice = (quantity+quantityToAdd)*salesPrice,Type = 'Product',UnitAdjustmentAmount = 0,UnitAdjustedPrice = salesPrice,ECOM_ShippingCode__c =  product.shippingPoint,ECOM_Earliest_Shipping_Date__c = earliestShipDate,CurrencyISOCode = item.CurrencyISOCode));
                                }
                            }
                        }
                        //RWPS-2941 and RWPS-3026 End
                    }
                    if(cartItem != null){
                        cartItemsToUpdate.add(cartItem);
                    }
                        //need to refine the logic as we are deleting old child items
                    if(cart.ECOM_isTaxExempt__c==false){
                            if(product.taxVat !=null){  //ssingh@rafter.one | 04-29-2024 | Removed the check for tax greater than 0 | RWPS-551
                            if(cartItemtoTaxMap.containsKey(item.Id)){
                                CartTax existingTax =  cartItemtoTaxMap.get(item.Id);
                                cartTaxestoInsert.add(new CartTax(id=existingTax.Id,Amount = Decimal.valueOf(product.taxVat),CartItemId = item.Id,Name = 'Tax',TaxCalculationDate = Date.today(),TaxType = 'Estimated'));
                            }else{
                                CartTax tax = new CartTax(Amount = Decimal.valueOf(product.taxVat),CartItemId = item.Id,Name = 'Tax',TaxCalculationDate = Date.today(),TaxType = 'Estimated');
                                cartTaxestoInsert.add(tax);
                            }
                        }
                    }
                    shippingAmount += (product.freight + product.handling);
                        if(product.tariff_surcharge!=null)//RWPS-3026
                            tariffChargeAmount += product.tariff_surcharge; //RWPS-3026
                }else{
                        //add logic to add free item and ECOM_SAP_Line_Number__c RWPS-3811
                    Set<String> freeProductPartNumber = new Set<String>();
                    freeProductPartNumber.add(product.partNumber); //  AL3099F
                    List<Product2> freeProduct = ECOM_ProductRepo.getProductsForPartNumbers(freeProductPartNumber);
                    if(freeProduct.size() > 0) {
                        cartItemsToInsert.add(new CartItem(ECOM_SAP_Line_Number__c = Decimal.valueOf(product.itemNumber), CartDeliveryGroupId = cartDeliveryGroupId,CartId = CartId,ListPrice = 0,Name = freeProduct[0].Name,ecom_parent_item__c = freeParentItemId, Product2Id = freeProduct[0].Id,Quantity = quantity,SalesPrice = 0,Sku = product.partNumber,TotalAdjustmentAmount = 0,TotalLineAmount = 0,TotalPrice = 0,Type = 'Product',UnitAdjustmentAmount = 0,ECOM_ShippingCode__c =  product.shippingPoint, CurrencyISOCode = cart.CurrencyIsoCode)); // RWPS-4500
                    }
                }
                count++;
                }//RWPS-2786 - END
        }else{
                //RWPS-2786 - Start
            for(CartItem item : cartItems) {
                if(cartItemtoTaxMap.containsKey(item.Id)){
                    CartTax existingTax =  cartItemtoTaxMap.get(item.Id);
                    cartTaxestoInsert.add(new CartTax(id=existingTax.Id,Amount = 0.00, TaxCalculationDate = Date.today()));
                }
                if(item.Type=='Charge'){
                    cartItemsToUpdate.AddAll(ECOM_CartUtil.updateDiscontinuedCartItem(item));
                }
            }
        }
        Set<String> allDiscontinuedProductsSet = new Set<String>(lstDiscountinuedProducts);
        cartItemsToUpdate.AddAll(updateDiscountinuedProducts(cartItems, allDiscontinuedProductsSet));
            //RWPS-2786 - End
        
        //insert shipping change for cart
        cartItemsToUpsert.add(createCartDeliveryChargeItem(shippingAmount,cartId,cartDeliveryGroupId,chargeTypeItemId));
        //insert tariff surcharge change for cart
        if(tariffChargeAmount > 0){
            cartItemsToUpsert.add(createCartDeliveryTariffCharge(tariffChargeAmount,cartId,cartDeliveryGroupId,chargeTariffItemId)); //RWPS-3026
        }else{
            ECOM_CartService.deleteTariffLineItem(cartId);
        }

            // RWPS-2683-Start - Update List Price.

            //RWPS-2786-START
        String salesOrg = '';
        if(orderRequest != null){
            salesOrg =  ECOM_CustomMetadataService.getSalesOrg(orderRequest.country);
        }
        //RWPS-2786-END
        ECOM_CartUtil.updateCartItemListPrice(salesOrg, cart, tempCartItems);
            //RWPS-2683 - End
        if(cartItemsToUpsert.size() > 0){
            ECOM_CartRepo.upsertCartItems(cartItemsToUpsert);
        }
        if(cartItemsToUpdate.size() > 0){
            ECOM_CartRepo.updateCartItems(cartItemsToUpdate);
        }
        if(cartItemsToInsert.size() > 0){
            ECOM_CartRepo.insertCartItems(cartItemsToInsert);
            tempCartItems.addAll(cartItemsToInsert);//RWPS-4081
        }
        if(cartTaxestoInsert.size() > 0){
            ECOM_CartRepo.upsertCartTax(cartTaxestoInsert);
        }

    	updateCouponAndDiscount(tempCartItems, '', orderSimulateResponse);//RWPS-4081
        List<WebCart> cartList = ECOM_CartRepo.getCartandCartItemsById(cartId);

        return cartList[0].cartItems;
    }

        /**
     * @description This method updates Cart item prices to 0.
     * @author prabhat.kumar@zensar.com | 3 July 2025
     * @param Set<String> allDiscontinuedProductsSet
     * @param List<CartItem> cartItems
     * JIRA - RWPS-2786
     */
     public static List<CartItem> updateDiscountinuedProducts(List<CartItem> cartItems, Set<String> allDiscontinuedProductsSet){
        List<CartItem> cartItemsToUpdate = New List<CartItem>();
         for(Cartitem item : cartItems){
            if(allDiscontinuedProductsSet.contains(item.product2Id)){
                cartItemsToUpdate.addAll(updateDiscontinuedCartItem(item));
            }
        }
        return cartItemsToUpdate;
     }

        /**
     * @description This method updates Cart item prices to 0.
     * @author prabhat.kumar@zensar.com | 3 July 2025
     * @param String cart
     * @param List<CartItem> cartItems
     * JIRA - RWPS-2786
     */
    public static List<CartItem> updateDiscontinuedCartItem(CartItem item){
            List<CartItem> cartItemsToUpdate = New List<CartItem>();
            CartItem cartItem;
            cartItem = new CartItem(ListPrice = 0.00, TotalListPrice = 0.00, Tariff_Surcharge__c = 0.00, ECOM_Shipping_Cost__c = 0.00, SalesPrice =0.00,UnitAdjustedPrice =0.00,Quantity = 1,TotalLineAmount = 0.00,TotalPrice = 0.00,NetUnitPrice = 0.00,Id = item.id);
            cartItemsToUpdate.add(cartItem);
            return cartItemsToUpdate;
    }

       /**
     * @description This method update the list price on cart item if not updated.
     * @author prabhat.kumar@zensar.com | 25 Feb 2025
     * @param String salesOrg
     * @param String cart
     * @param List<CartItem> cartItems
     * JIRA - RWPS-2683
     */
    public static void updateCartItemListPrice(String salesOrg, WebCart cart, List<CartItem> cartItems){

            Set<Id> productIds = New Set<id>();
            List<CartItem> cartItemsToUpdate = New List<CartItem>();
            for (CartItem item : cartItems) {
                if (item.Type == 'Product' && item.product2Id != null) {
                    productIds.add(item.product2Id);
                }
            }
            Map<Id, Decimal> mapProductToPrice = ECOM_CartRepo.getPricebookEntryListPrices(salesOrg, cart.CurrencyIsoCode, productIds);
            for (CartItem item : cartItems) {
                if (item.Type == 'Product' && item.product2Id != null) {
                    if (mapProductToPrice.containsKey(item.product2Id) && (mapProductToPrice.get(item.product2Id) != item.listPrice || item.TotalListPrice == null)) {////RWPS-3262
                        item.listPrice = mapProductToPrice.get(item.product2Id);
                        item.TotalListPrice =  mapProductToPrice.get(item.product2Id) * item.quantity;//RWPS-3262
                        cartItemsToUpdate.add(item);
                    }
                }
            }

            if (cartItemsToUpdate.size() > 0) {
                ECOM_CartRepo.updateCartItems(cartItemsToUpdate);
            }
    }

     /**
    * @description  Create Cart Item for the Tariff Surcharge
    * @author Prabhat Kumar | 04.25.2025
    * @param tariffChargemaount | RWPS-3026
    * @param cartId
    * @param cartDeliveryGroupId
    * @return CartItem
    **/
    public static CartItem createCartDeliveryTariffCharge(Decimal tariffChargeAmount, String cartId , Id cartDeliveryGroupId, Id chargeTariffItemId) {
        WebCart cart = ECOM_CartRepo.getPrimaryCartBasedOnId(cartId);
        CartItem deliveryCharge = new CartItem(
            Id = chargeTariffItemId,
            Type = 'Charge',
            Product2Id = getDefaultTariffSurchargeProduct2Id(),
            Quantity = 1.0,
            TotalPrice = tariffChargeAmount,
            SalesPrice = tariffChargeAmount,
            ListPrice = tariffChargeAmount,
            TotalListPrice = tariffChargeAmount,
            TotalLineAmount = tariffChargeAmount,
            AdjustmentAmount = 0.0,
            CartId = cartId,
            CartDeliveryGroupId = cartDeliveryGroupId,
            Name = 'Tariff Surcharge',
            CurrencyISOCode = cart.CurrencyISOCode
        );
        return deliveryCharge;
    }

    /**
    * @description  create a cart item for  charge type
    * @author mkumar@rafter.one | 08-25-2023
    * @param shippingAmount
    * @param cartId
    * @param cartDeliveryGroupId
    * @return CartItem
    **/
    public static CartItem createCartDeliveryChargeItem(Decimal shippingAmount, String cartId , Id cartDeliveryGroupId, Id chargeTypeItemId) {
        WebCart cart = ECOM_CartRepo.getPrimaryCartBasedOnId(cartId);
        CartItem deliveryCharge = new CartItem(
            Id = chargeTypeItemId,
            Type = 'Charge',
            Product2Id = getDefaultShippingChargeProduct2Id(),
            Quantity = 1.0,
            TotalPrice = shippingAmount,
            SalesPrice = shippingAmount,
            ListPrice = shippingAmount,
            TotalListPrice = shippingAmount,
            TotalLineAmount = shippingAmount,
            AdjustmentAmount = 0.0,
            CartId = cartId,
            CartDeliveryGroupId = cartDeliveryGroupId,
            Name = 'Shipping Cost',
            CurrencyISOCode = cart.CurrencyISOCode
        );
        return deliveryCharge;
    }

     /**
     * @description update promotional or contractual discount on cart if any
     * @author mkumar@rafter.one | 08-25-2023
     * @param cart
     * @param couponCode
     * @param orderSimulateResponse
     * @return WebCart
     **/
     public static WebCart updateCouponAndDiscount(List<CartItem> cartItems, String couponCode, ECOM_SimulateOrderWrapper.OrderResponse orderSimulateResponse ){//RWPS-2786
        //RWPS-2786 -Start
        WebCart carttoUpdate = new WebCart();
        WebCart cart = cartItems[0].Cart;
        Map<String, Object> cartDetailsMap = getCartItemDetailsMap(cartItems); //RWPS-4202 start
        Map<String,CartItem> partNumberToCartItemMap = (Map<String,CartItem>) cartDetailsMap.get('partNumberToCartItemMap'); //RWPS-4202
        Set<String> productIdSet = (Set<String>) cartDetailsMap.get('productIdSet');
        boolean isFreeItemAdded = (boolean) cartDetailsMap.get('isFreeItemAdded'); //RWPS-4202 End
        List<String> lstDiscountinuedProducts = getNonSellableDiscountinuedProducts(productIdSet, 'discontinued');//RWPS-2786
        carttoUpdate.id = cart.Id;
        Decimal totalDiscount = 0.0;
        //RWPS-3262 - Start
        Decimal promotionalDiscount = 0.0;
        //RWPS-4081 fix for Split quantity Savings calculation
        Decimal totalSavings = 0.0;
        //Recalculate List Total and Sales Total directly from CartItems 
        Decimal calculatedListTotal = 0.0;
        Decimal calculatedSalesTotal = 0.0;

        for (CartItem item : cartItems) {
            if (item.Type != 'Product') continue;
            Decimal listPrice = (item.ListPrice != null) ? item.ListPrice : 0;
            Decimal qty = (item.Quantity != null) ? item.Quantity : 0;
            Decimal lineListTotal = listPrice * qty;
            Decimal lineSellTotal = (item.TotalLineAmount != null) ? item.TotalLineAmount : 0;
            calculatedListTotal += lineListTotal;
            calculatedSalesTotal += lineSellTotal;
        }

        // Promotional Discount 
        promotionalDiscount = (calculatedListTotal > calculatedSalesTotal) ? (calculatedListTotal - calculatedSalesTotal) : 0.0;

        // API (Coupon/Simulated) Discounts  RWPS-4081 end
        if(orderSimulateResponse != null){
            for(ECOM_SimulateOrderWrapper.ProductList product : orderSimulateResponse.productList) {
                CartItem item = partNumberToCartItemMap.get(product.partNumber);
                    if(lstDiscountinuedProducts.size()==0 || !lstDiscountinuedProducts.contains(item.product2Id)){
                        totalDiscount += product.discount;
                    }
            }
        }else{
             carttoUpdate.ECOM_Total_Savings__c = 0.00;

        }
        carttoUpdate.ECOM_Total_Savings__c = (totalDiscount > 0 && promotionalDiscount > 0) ? promotionalDiscount :(totalDiscount > 0) ? totalDiscount :(promotionalDiscount > 0) ? promotionalDiscount : 0.00;//RWPS-4630
        //RWPS-3262 - End
        if(String.isNotBlank(couponCode) && totalDiscount > 0){
            carttoUpdate.ECOM_Promo_Code__c = couponCode;
        }else if(isFreeItemAdded) { 
            carttoUpdate.ECOM_Promo_Code__c = couponCode; //RWPS-3811
        }
        else{
            carttoUpdate.ECOM_Promo_Code__c = '';
        }
        //update cart
        ECOM_CartRepo.updateCart(new List<WebCart>{carttoUpdate});
        return carttoUpdate;
        //RWPS-2786 -End
    }

    /**
    * @description This method is used to generate request for order simulation.
    * @author mkumar@rafter.one | 07-28-2023
    *         ssingh@rafter.one | 04-08-2024 | Added parameters user & con in generateOrderSimulationRequest method | RWPS-415
    *         ssingh@rafter.one | 05-27-2024 | Updated logic to get external Id from ERP Address of Contact | RWPS-766
    *         ssingh@rafter.one | 06-10-2024 | Updated logic to populate bill to/ship to from metadata | RWPS-843
    *         ssingh@rafter.one | 11-26-2024 | Updated logic to populate bill to/ship to from contact if cart has null | RWPS-2080
    * @param cartList
    * @return ECOM_SimulateOrderWrapper.OrderRequest
    **/
    public static ECOM_SimulateOrderWrapper.OrderRequest generateOrderSimulationRequest(Map<String, Object> requestData)
{       //RWPS-3811-START
        WebCart cart = (WebCart)requestData.get('cart');
        String couponCode = (String) requestData.get('couponCode');
        User user = (User) requestData.get('user');
        Contact con = (Contact) requestData.get('contact');
        Map<String,Boolean> bogoApplicableProudctsMap = (Map<String,Boolean>)requestData.get('bogoApplicableProudctsMap');
        Set<String> productIds = (Set<String>)requestData.get('productIds');
        //RWPS-3811-END

        String accId = ECOM_CartRepo.getEffectiveAccountId();
        Boolean isMapped = con.ECOM_Is_Mapped__c;
		Boolean isLargePackShipping = false;
        String accCountryCode = '';//RWPS-1305 for unmaped use case read country code from account
        Integer count = 1;
        ECOM_DummyAccountCountryMapping__mdt defaultmdt ;
        if(!user.ECOM_Is_Punchout_User__c ){
        	defaultmdt = ECOM_CustomMetadataService.fetchDummyAccountCountryMappingData(ECOM_Util.getCountryFromUser(user));
        }
        ECOM_SimulateOrderWrapper.OrderRequest orderRequest = new ECOM_SimulateOrderWrapper.OrderRequest();
        //RWPS-2080
        if(isMapped == true){
            if(cart.Default_Bill_to_ERP_Address__c != null && cart.Default_Bill_to_ERP_Address__c == con.Default_Bill_to_ERP_Address__c && cart.Default_Ship_to_ERP_Address__c != null && cart.Default_Ship_to_ERP_Address__c == con.Default_Ship_to_ERP_Address__c){
                orderRequest.bill_to = cart.Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c != null ? cart.Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c : con.Default_Bill_to_ERP_Address__c != null ? con.Default_Bill_To_ERP_Address__r.Target_Address__r.External_Id__c : null;
                orderRequest.Ship_to = cart.Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c != null ? cart.Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c : con.Default_Ship_to_ERP_Address__c != null ? con.Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c : null;
            }
            else if ((cart.Default_Bill_to_ERP_Address__c != con.Default_Bill_to_ERP_Address__c) || (cart.Default_Ship_to_ERP_Address__c != con.Default_Ship_to_ERP_Address__c)) {
                orderRequest.bill_to = con.Default_Bill_To_ERP_Address__r.Target_Address__r.External_Id__c;
                orderRequest.Ship_to = con.Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c;
            }
            if((cart.Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c == null && con.Default_Bill_To_ERP_Address__r.Target_Address__r.External_Id__c == null) || (cart.Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c == null && con.Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c == null)){
                orderRequest.bill_to = defaultmdt.Default_Bill_To__c;
                orderRequest.Ship_to = defaultmdt.Default_Ship_to__c;
            }
        }
        else if (isMapped == false && defaultmdt != null){
            orderRequest.bill_to = defaultmdt.Default_Bill_To__c;
            orderRequest.Ship_to = defaultmdt.Default_Ship_to__c;
        }

        accCountryCode = cart.Default_Bill_to_ERP_Address__c!= null ? cart.Default_Bill_to_ERP_Address__r.fxAddress_CountryCode__c : con.Default_Bill_To_ERP_Address__r.fxAddress_CountryCode__c; //RWPS-1305 //RWPS-1773
        //RWPS-2683 - Start
        if(accCountryCode == null && con.ECOM_CountryProvided__c != null){
            List<C_META_Countries__mdt> userSalesOrgconfigs =  ECOM_CustomMetadataRepo.getSalesOrgs(con.ECOM_CountryProvided__c);
            String countryCode = '';
            countryCode = userSalesOrgconfigs.size() >0? userSalesOrgconfigs[0].CountryISOAlpha2__c: '';
            accCountryCode = countryCode;
        }
        //RWPS-2683 - End

        // //Assuming punchout cart will have  bill to , ship to populated always
        // if(cart.Default_Bill_to_ERP_Address__c != null && cart.Default_Bill_to_ERP_Address__r.Target_Address__c != null){
        // 	orderRequest.bill_to = cart.Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c;
        // } else if(defaultmdt != null){
        //     //add place holder default bill to
        //     orderRequest.bill_to = defaultmdt.Default_Bill_To__c;
        // }
        // if(cart.Default_Ship_to_ERP_Address__c != null && cart.Default_Ship_to_ERP_Address__r.Target_Address__c != null){
        // 	orderRequest.Ship_to = cart.Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c;
        // } else if(defaultmdt != null){
        //     //add place holder default ship to
        //     orderRequest.Ship_to = defaultmdt.Default_Ship_to__c;
        // }
		//RWPS-1305
        // if(String.isBlank(accCountryCode)){
        // 	accCountryCode = ECOM_CartRepo.getAccountCountryCode(accId);
        // }
        orderRequest.country = accCountryCode;

        orderRequest.requested_date = System.today();
        orderRequest.promo_code = couponCode; //cart.Promo_Code__c; //Custom field needs to be created to store Promo code
        orderRequest.cart_id = cart.Id;
        orderRequest.payment_type = cart.PaymentMethodId;
        orderRequest.po_no = cart.PoNumber;
        List<ECOM_SimulateOrderWrapper.Item> productList = new List<ECOM_SimulateOrderWrapper.Item>();
		 List<String> allDiscontinuedeProducts = ECOM_CartUtil.getNonSellableDiscountinuedProducts(productIds, 'discontinued');
         Set<String> allDiscontinuedProductsSet = new Set<String>(allDiscontinuedeProducts);
		// RWPS-2786 End


        Set<String> uniquePartNumbers = new Set<String>();
        for (CartItem item : cart.CartItems) {
            if(item.Type=='Product'){
				// RWPS-2786 Start
				if ((!allDiscontinuedProductsSet.isEmpty() && allDiscontinuedProductsSet.contains(item.Product2Id))) {
					continue;
				}
				// RWPS-2786 End
                //RWPS-3811 Don't add in list as its free item
                if(String.isNotBlank(item.ecom_parent_item__c)) {
                    continue;
                }
                ECOM_SimulateOrderWrapper.Item cartItem = new ECOM_SimulateOrderWrapper.Item();
                //RWPS-3811-START
                cartItem.bogo_applicable = bogoApplicableProudctsMap.containsKey(item.id) ? true : false;
                //RWPS-3811-END

                cartItem.item_number = count;
                cartItem.part_number = item.Product2.Part_Number__c;
                cartItem.quantity = item.Quantity;
                cartItem.qtyLimitExceeded = false;
                if(item.Quantity > 999){
                    cartItem.quantity = 999;
                    cartItem.qtyLimitExceeded = true;
                }
                if(uniquePartNumbers.contains(item.Product2.Part_Number__c)){
                    for (Integer i = 0; i < productList.size(); i++) {
                        if(productList[i].part_number == item.Product2.Part_Number__c){
                            if((productList[i].quantity + item.Quantity) <= 999){
                                productList[i].quantity += item.Quantity;
                            }
                            else {
                                productList[i].quantity = 999;
                                productList[i].qtyLimitExceeded = true;
                            }
                        }
                    }
                } else {
                    productList.add(cartItem);
                    count++;
                }
                uniquePartNumbers.add(item.Product2.Part_Number__c);
                if(String.isNotBlank(item.Product2.Item_Class__c) && (item.Product2.Item_Class__c=='1' || item.Product2.Item_Class__c=='2') && !isLargePackShipping){
                	isLargePackShipping = true;
            	}
            }
        }
        orderRequest.product_list = productList;
        //RWPS-584 (if large pack shipping send order type ZGNA for all orders)
        String salesOrg = ECOM_CustomMetadataService.getSalesOrg(orderRequest.country);
        if(isLargePackShipping){
          orderRequest.Component = getOrderType(isLargePackShipping, '', ECOM_Constant.ORDER_SIMULATE, salesOrg );
        }else{
            orderRequest.Component = user.ECOM_Is_Punchout_User__c?
                                   getOrderType(isLargePackShipping, '', ECOM_Constant.ORDER_SIMULATE, 'Punchout_Default'):
                                   getOrderType(isLargePackShipping, '', ECOM_Constant.ORDER_SIMULATE, 'Default' );//RWPS-4848
        }
        
        return orderRequest;
    }

    public static ECOM_SimulateOrderWrapper.OrderRequest populateBillToShipTo(ECOM_SimulateOrderWrapper.OrderRequest request, WebCart cart){
        	if(cart.Default_Ship_to_ERP_Address__r.Target_Address__c != null){
                request.Ship_to = cart.Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c;
            }
            if(cart.Default_Bill_to_ERP_Address__r.Target_Address__c != null){
                request.bill_to = cart.Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c;
            }
        return request;
    }


        /**
    * @description Only used for testing credit block data
    * @author mkumar@rafter.one | 07-28-2023
    * @param cartList
    * @return ECOM_SimulateOrderWrapper.OrderRequest
    **/
    public static ECOM_SimulateOrderWrapper.OrderRequest getCreditBlockExampleData()
    {
        ECOM_SimulateOrderWrapper.OrderRequest orderRequest = new ECOM_SimulateOrderWrapper.OrderRequest();
        orderRequest.bill_to = '0004062757'; //payerAccount[0].SAP_Target_Account_Number__c;
        orderRequest.Ship_to = '0100064982'; //shipToAccount[0].SAP_Source_Account_Number__c;
        orderRequest.country = 'US';
        orderRequest.requested_date = System.today();
        List<ECOM_SimulateOrderWrapper.Item> productList = new List<ECOM_SimulateOrderWrapper.Item>();

        //for (CartItem item : cart.CartItems) {
            ECOM_SimulateOrderWrapper.Item cartItem = new ECOM_SimulateOrderWrapper.Item();
            cartItem.item_number = 1;
            cartItem.part_number = 'TRF1293-S';
            cartItem.quantity = 500000;
            productList.add(cartItem);
        //}
        orderRequest.product_list = productList;

        return orderRequest;
    }

    /**
    * @description  This method is used to generate request map for REST Service callout.
    * @author mkumar@rafter.one | 07-28-2023
    * @param requestBody
    * @return Map<String, String>
    **/
    public static Map<String, String> generateRequestMap(String requestBody){

        Map<String, String> requestMap = new Map<String, String>();
        requestMap.put(ECOM_Constant.HTTP_REQUEST_TYPE, ECOM_Constant.HTTP_REQUEST_POST);
        requestMap.put(ECOM_Constant.HTTP_REQUEST_BODY, requestBody);

        return requestMap;
    }

    /**
    * @description This method is used to get part numbers from ProductWrapper
    * @author Vipul Goyal | 07-31-2023
    * @param productCodes
    * @return List<String>
    **/
    public static List<String> getPartNumbers(List<ECOM_CartController.ECOM_ProductWrapper> productCodes)
    {
        List<String> partNumbers=new List<String>();
        for(ECOM_CartController.ECOM_ProductWrapper product:productCodes)
        {
            partNumbers.add(product.partNumber);
        }
        return partNumbers;
    }

    //This method is used to insert cart delivery group method or update if it already exists
    public static Id populateDefaultCartDeliveryGroupMethod(Id cartDeliveryGroupId,Id deliveryMethodId,WebCart webCartObject, Decimal amount){
        String cartCurrency = webCartObject.CurrencyIsoCode ;
        Id defaultDeliveryMethodId = null;
        List<CartDeliveryGroupMethod> lstCartDelivery = ECOM_CartRepo.getCartDeliveryGroupMethodByCart(webCartObject.Id);
        if(lstCartDelivery != null && lstCartDelivery.isEmpty())
        {
            List<CartDeliveryGroupMethod> cartDeliveryGroupMethodsToInsert = new List<CartDeliveryGroupMethod>();
            CartDeliveryGroupMethod cartDeliveryGroupMethod = new CartDeliveryGroupMethod(
                    CartDeliveryGroupId = cartDeliveryGroupId,
                    DeliveryMethodId = deliveryMethodId,
                    ExternalProvider = '',
                    Name = ' Delivery Group Method',
                    ShippingFee = amount,
                    WebCartId = webCartObject.Id,
                    CurrencyIsoCode = cartCurrency
            );
            cartDeliveryGroupMethodsToInsert.add(cartDeliveryGroupMethod);
            List<CartDeliveryGroupMethod> cartDeliveryGroupMethods = ECOM_CartRepo.insertCartDeliveryGroupMethod(cartDeliveryGroupMethodsToInsert);
            defaultDeliveryMethodId = cartDeliveryGroupMethods[0].Id;
        }else
        {
            List<CartDeliveryGroupMethod> cartDeliveryGroupMethodsToUpdate = new List<CartDeliveryGroupMethod>();
            CartDeliveryGroupMethod  objDeliveryGrp  = lstCartDelivery[0];
            objDeliveryGrp.CurrencyIsoCode = cartCurrency ;
            cartDeliveryGroupMethodsToUpdate.add(objDeliveryGrp);
            List<CartDeliveryGroupMethod> cartDeliveryGroupMethods = ECOM_CartRepo.updateCartDeliveryGroupMethod(cartDeliveryGroupMethodsToUpdate);
            defaultDeliveryMethodId = cartDeliveryGroupMethods[0].Id;
        }
        return defaultDeliveryMethodId;
    }

    //This method is used to fetch default order delivery method and insert it
    public static Id getDefaultOrderDeliveryMethod() {
        Id defaultDeliveryMethodId = null;
        Id product2IdForThisDeliveryMethod = getDefaultShippingChargeProduct2Id();
        // Check to see if a default OrderDeliveryMethod already exists.
        // If it doesn't exist, create one.
        List<OrderDeliveryMethod> defaultOrderDeliveryMethods = ECOM_OrderRepo.getOrderDeliveryMethods(ECOM_Constant.DEFAULT_DELIVERY_METHOD);
        if (defaultOrderDeliveryMethods != null && defaultOrderDeliveryMethods.isEmpty())
        {
            List<OrderDeliveryMethod> orderDeliveryMethodsToInsert = new List<OrderDeliveryMethod>();
            OrderDeliveryMethod defaultOrderDeliveryMethod = new OrderDeliveryMethod(
                    Name = ECOM_Constant.DEFAULT_DELIVERY_METHOD,
                    IsActive = true,
                    ProductId = product2IdForThisDeliveryMethod
            );
            orderDeliveryMethodsToInsert.add(defaultOrderDeliveryMethod);
            List<OrderDeliveryMethod> orderDeliveryMethods = ECOM_OrderRepo.insertOrderDeliveryMethods(orderDeliveryMethodsToInsert);
            defaultDeliveryMethodId = orderDeliveryMethods[0].Id;
        }
        else
        {
            // If the OrderDeliveryMethod doesn't have a Product2 associated with it, assign one
            OrderDeliveryMethod defaultOrderDeliveryMethod = defaultOrderDeliveryMethods[0];
            List<OrderDeliveryMethod> OrderDeliveryMethodsToUpdate = new List<OrderDeliveryMethod>();
            if (defaultOrderDeliveryMethod.ProductId == null) {
                defaultOrderDeliveryMethod.ProductId = product2IdForThisDeliveryMethod;
                OrderDeliveryMethodsToUpdate.add(defaultOrderDeliveryMethod);
                List<OrderDeliveryMethod> OrderDeliveryMethods = ECOM_OrderRepo.updateOrderDeliveryMethods(OrderDeliveryMethodsToUpdate);
                defaultDeliveryMethodId = OrderDeliveryMethods[0].Id;
            }
            else {
                defaultDeliveryMethodId = defaultOrderDeliveryMethod.Id;
            }
        }
        return defaultDeliveryMethodId;
    }


     /**
    * @description This method is used to get default tariff surcharge product id
    * @author Prabhat Kumar | 2025.04.25
    * @param none | RWPS-3026
    * @return ID
    **/
    public static Id getDefaultTariffSurchargeProduct2Id() {
        List<Product2> tariffChargeProducts = ECOM_ProductRepo.getProductsByName(ECOM_Constant.TARIFF_CHARGE_PRODUCT);
        if (tariffChargeProducts != null && tariffChargeProducts.isEmpty())
        {
            List<Product2> productsToInsert = new List<Product2>();
            Product2 tariffChargeProduct = new Product2(
                    IsActive = true,
                    Name = ECOM_Constant.TARIFF_CHARGE_PRODUCT
            );
            productsToInsert.add(tariffChargeProduct);
            List<Product2> products = ECOM_ProductRepo.insertProducts(productsToInsert);
            return products[0].Id;
        }
        else
        {
            return tariffChargeProducts[0].Id;
        }
    }




    //This method is used to get default shipping charge by product
    public static Id getDefaultShippingChargeProduct2Id() {
        // Name the product representing shipping charges as 'Shipping Charge for this delivery method'.
        // Check to see if a Product2 with that name already exists.
        // If it doesn't exist, create one.
        List<Product2> shippingChargeProducts = ECOM_ProductRepo.getProductsByName(ECOM_Constant.SHIPPING_CHARGE_PRODUCT);
        if (shippingChargeProducts != null && shippingChargeProducts.isEmpty())
        {
            List<Product2> productsToInsert = new List<Product2>();
            Product2 shippingChargeProduct = new Product2(
                    IsActive = true,
                    Name = ECOM_Constant.SHIPPING_CHARGE_PRODUCT
            );
            productsToInsert.add(shippingChargeProduct);
            List<Product2> products = ECOM_ProductRepo.insertProducts(productsToInsert);
            return products[0].Id;
        }
        else
        {
            return shippingChargeProducts[0].Id;
        }
    }

    //This method is used to add order delivery method to cart delivery group
    public static Id addOrderDeliveryMethodToCartDeliveryGroup(Id cartID, Id orderDeliveryMethodId) {
        Id defaultDeliveryMethodId = null;
        // The OrderDeliveryMethod is added to the CartDeliveryGroup for the order to be properly created during checkout.
        List<CartDeliveryGroup> cartDeliveryGroup = ECOM_CartRepo.getCartDeliveryGroupByCart(cartID);
        if(cartDeliveryGroup != null && cartDeliveryGroup.isEmpty())
        {
            List<CartDeliveryGroup> cartDeliveryGroupsToInsert = new List<CartDeliveryGroup>();
            CartDeliveryGroup defaultCartDeliveryGroup = new CartDeliveryGroup(
                    CartId = cartID,
                    Name = 'Default Delivery',
                    DeliverToName = 'Default Delivery',
                    DeliveryMethodId = orderDeliveryMethodId);
            cartDeliveryGroupsToInsert.add(defaultCartDeliveryGroup);
            List<CartDeliveryGroup> cartDeliveryGroups = ECOM_CartRepo.insertCartDeliveryGroups(cartDeliveryGroupsToInsert);
            defaultDeliveryMethodId = cartDeliveryGroups[0].Id;
        }else
        {
            List<CartDeliveryGroup> cartDeliveryGroupsToUpdate = new List<CartDeliveryGroup>();
            CartDeliveryGroup defaultCartDeliveryGroup = cartDeliveryGroup[0];
            defaultCartDeliveryGroup.DeliveryMethodId = orderDeliveryMethodId;
            defaultCartDeliveryGroup.Name = 'Default Delivery';
            defaultCartDeliveryGroup.DeliverToName = 'Default Delivery';
            cartDeliveryGroupsToUpdate.add(defaultCartDeliveryGroup);
            List<CartDeliveryGroup> cartDeliveryGroups = ECOM_CartRepo.updateCartDeliveryGroups(cartDeliveryGroupsToUpdate);
            defaultDeliveryMethodId = cartDeliveryGroups[0].Id;
        }
        return defaultDeliveryMethodId;
    }


    /**
    * @description validate if the product is valid based on material staus code
    * @author mkumar@rafter.one | 09-21-2023
    * @author ssingh@rafter.one | 07-10-2024 | RWPS-949
    * @param cart
    * @param moduleName
    * @return ECOM_CartModel
    **/
    public static ECOM_CartModel validateProductMaterialStatus(ECOM_CartModel cart, String moduleName){
        //List<String> productIds = new List<String>();
        String supportData = JSON.serialize(cart);
        try {
            String punchoutModuleName = 'ECOM_Punchout';
            List<String> materialCodes = new List<String>();
            List<String> materialCodesNonSellable = new List<String>(); //RWPS-2786
            Set<String> prodIdsInCart = new Set<String>();
            Set<String> itemIdsInCart = new Set<String>();
            Map<String, String> mapProdItemId = new Map<String,String>();//RWPS-4896
            Map<string, string> mapProdCartItemId = New Map<string, string>();//RWPS-4896
            List<Product_Sales__c> productSales = new List<Product_Sales__c>();
            if(cart.isPunchoutCart == true){
                materialCodes = fetchProductMaterialStatus(punchoutModuleName);
                materialCodes.addAll(ECOM_CartUtil.fetchProductMaterialStatus('ECOM_Punchout_Custom'));//RWPS- 1456
            }
            else {
                materialCodes = fetchProductMaterialStatus(moduleName);
            }
            materialCodesNonSellable = fetchProductMaterialStatus('ECOM_Non_Sellable_Products'); //RWPS-2786
            List<ECOM_CartItemModel> cartItemModels = cart.cartItems;
            List<ECOM_CartItemModel> cartItemModlesTraining = cart.cartItems;//RWPS-4896
            if(cartItemModels != null && cartItemModels.size() > 0){
                for(ECOM_CartItemModel ci: cartItemModels){
                    if(ci.type == 'Product'){
                        prodIdsInCart.add(ci.productId);
                        itemIdsInCart.add(ci.cartItemId);
                        mapProdItemId.put(ci.productId, ci.cartItemId);//RWPS-4896
                    }
                }
                //fetch Product sales records for the prodcuts in the cart
                productSales = ECOM_ProductRepo.getProductSales(prodIdsInCart, materialCodes);
                if(productSales.size() == prodIdsInCart.size()){
                    System.debug('in if>>> ' + productSales.size() + ' ' + prodIdsInCart.size());
                    Set<String> prodsNotInProductSales = new Set<String>();
                    Map<String, Product_Sales__c> prodSalesMap = new Map<String, Product_Sales__c>();
                    List<Id> itemsToDelete = new List<Id>();
                    for(Product_Sales__c ps :productSales){
                        prodSalesMap.put(ps.Product__c, ps);
                    }
                
                    for (Integer i = (cartItemModels.size()-1); i>= 0 ; i--){
                        String prod = cartItemModels[i].productId;
                        // if prod status code is not prodsInProductSales then remove the cart item
                        if(prodSalesMap != null && prodSalesMap.get(prod) != null && materialCodesNonSellable.contains(prodSalesMap.get(prod).Distribution_ChainSpecificMaterialStatus__c)){ //RWPS-2786
                            itemsToDelete.add(cartItemModels[i].cartItemId);
                            prodsNotInProductSales.add(cartItemModels[i].productId);
                            mapProdCartItemId.put(cartItemModels[i].productId,cartItemModels[i].cartItemId);//RWPS-4896
                            cartItemModels.remove(i);
                        }
                    }

                    //RWPS-4896-START
                    List<Product_Recommendation__c> productRecommendList =  ECOM_ProductRecommendationsRepo.getRecommendationsTrainingProducts('Combination',mapProdItemId.keySet());//RWPS-4896

                    Map<String, String> mapTrainingProductIds = New Map<String, String>();
                    Set<String> suggestProductIds = New Set<String>();
                    Integer mainProductCount = 0;
                    String trainingproductId = '';
                    if(!itemsToDelete.isEmpty()){
                       for(Product_Recommendation__c pr : productRecommendList){
                            mapTrainingProductIds.put(pr.Product_Main__c, pr.Product_Suggested__c);
                            suggestProductIds.add( pr.Product_Suggested__c);
                        }
                        if(productRecommendList.size() > 0){
                            for(String prodId : mapProdItemId.keyset()) {
                                if(mapTrainingProductIds.containsKey(prodId)){
                                    mainProductCount++; 
                                }
                            }
                            for(String prodId : mapProdCartItemId.keyset()) {
                                if(mainProductCount == 1 && mapTrainingProductIds.containsKey(prodId)){
                                    for(ECOM_CartItemModel ci: cartItemModlesTraining){
                                        if(suggestProductIds.contains(ci.productid)){
                                            itemsToDelete.add(ci.cartItemId);  
                                        }
                                    }
                                }else if(mapProdItemId.values().size() == mapProdCartItemId.values().size()){
                                    for(ECOM_CartItemModel ci: cartItemModlesTraining){
                                        if(suggestProductIds.contains(ci.productid)){
                                            itemsToDelete.add(ci.cartItemId);  
                                        }
                                    }         
                                }
                            }
                        }
                        //RWPS-4896-END
                        ECOM_CartRepo.deleteCartItemsById(itemsToDelete);
                        ECOM_MessagesSummary msg = new ECOM_MessagesSummary();
                        msg.hasErrors = true;
                        msg.message = '';
                        List<Product2> prodsDeleted = ECOM_ProductRepo.getProductsByIds(prodsNotInProductSales);
                        if(prodsDeleted != null && prodsDeleted.size() > 0){
                            for(Product2 p :prodsDeleted){
                                msg.message = msg.message+p.Part_Number__c+', ';
                            }
                        }
                        String partNums = msg.message.subStringBeforeLast(',');
                        msg.message = partNums + ' ' + ECOM_Constant.MATERIAL_STATUS_ERROR_MSG;
                        cart.cartItems = cartItemModels;
                        cart.messagesSummary = msg;
                        cart.name = 'test msg';
                    }
                }
                else if(productSales.size() != prodIdsInCart.size()) { //RWPS-1401
                    System.debug('in else if>>> ' + productSales.size() + ' ' + prodIdsInCart.size());
                    System.debug('productSales>>>> ' + productSales + ' prodIdsInCart>>> ' + prodIdsInCart);
                    Map<String, Product_Sales__c> prodSales = new Map<String, Product_Sales__c>();
                    List<Id> itemsToDel = new List<Id>();
                    Set<Id> prodsInProdSales = new Set<Id>();

                    if(productSales.size() > 0){
                        for(Product_Sales__c ps :productSales){
                            prodsInProdSales.add(ps.Product__c);
                        }
                        for(ECOM_CartItemModel ci: cartItemModels){
                            if(!prodsInProdSales.contains(ci.productId)){
                                itemsToDel.add(ci.cartItemId);
                            }
                        }
                    }
                    else {
                        for (String itemId : itemIdsInCart) {
                            itemsToDel.add(itemId);
                        }
                    }

                    if(!itemsToDel.isEmpty()){
                        ECOM_CartRepo.deleteCartItemsById(itemsToDel);
                    }

                    ECOM_MessagesSummary msg = new ECOM_MessagesSummary();
                    msg.hasErrors = true;
                    msg.message = '';
                    msg.message = System.Label.ECOM_Product_Sales_Error;
                    cart.cartItems = cartItemModels;
                    cart.messagesSummary = msg;
                    cart.name = 'test msg';

                    supportData += ' Prod sales:: ' + productSales + ' Product Ids in Cart:: ' + prodIdsInCart;
                    ECOM_ApplicationLogsUtil.logApplicationDataWithCustomException(moduleName, 'ECOM_CartUtil', 'validateProductMaterialStatus', supportData, '', 'Product Sales record not found');
                }
            }
        } catch(Exception ex){
            ECOM_ApplicationLogsUtil.logFailure(ex, moduleName, 'ECOM_CartUtil', 'validateProductMaterialStatus', supportData);
        }
        return cart;
    }

    /**
    * @description Get products based on material status: non-sellable, discontinued, or both
    * @author Prabhat Kumar | 06-20-2025
    * @param Set<String> productSet - Set of product IDs
    * @param String filterType - 'non_sellable', 'discontinued', or 'both'
    * @return List<String> - Filtered product IDs
    **/
    public static List<String> getNonSellableDiscountinuedProducts(Set<String> productSet, String filterType) {
        List<String> filteredProducts = new List<String>();
        Set<String> materialStatusCodes = new Set<String>();

        // Fetch material status codes based on filter type
        if (filterType == 'non_sellable') {
            materialStatusCodes.addAll(fetchProductMaterialStatus('ECOM_Non_Sellable_Products'));
        } else if (filterType == 'discontinued') {
            materialStatusCodes.addAll(fetchProductMaterialStatus('DiscontinuedProduct'));
        } else if (filterType == 'both') {
            materialStatusCodes.addAll(fetchProductMaterialStatus('ECOM_Non_Sellable_Products'));
            materialStatusCodes.addAll(fetchProductMaterialStatus('DiscontinuedProduct'));
        } else {
            // Invalid filter type
            throw new IllegalArgumentException('Invalid filterType. Use "non_sellable", "discontinued", or "both".');
        }

        // Fetch product sales data
        List<Product_Sales__c> productSalesList = ECOM_ProductService.getProductSales(productSet, new List<String>(materialStatusCodes));

        for (Product_Sales__c productSale : productSalesList) {
            if (materialStatusCodes.contains(productSale.Distribution_ChainSpecificMaterialStatus__c)) {
                filteredProducts.add(productSale.Product__c);
            }
        }

        return filteredProducts;
    }




    /**
     * @description Fetches cart item IDs that are either non-sellable or discontinued based on material status codes.
     * Combines logic for both product types to reduce duplication and improve performance.
     * @author Prabhat Kumar | 06-13-2025
     * @param String cartId - The ID of the cart to evaluate.
     * @return List<String> - List of cart item IDs to be deleted.
     */
    public static List<CartItem> fetchNonSellableDiscontinuedCartItems(String cartId) {
        List<CartItem> cartItemToDelete = new List<CartItem>();

        // Retrieve cart items and map Product2Id to CartItem Id
        List<CartItem> cartItems = ECOM_CartService.getCartItemsByCartId(cartId);
        Map<String, CartItem> productToCartItemMap = new Map<String, CartItem>();

        for (CartItem item : cartItems) {
            if (item.Type == 'Product') {
                productToCartItemMap.put(item.Product2Id, item);
            }
        }

        if (productToCartItemMap.isEmpty()) {
            return cartItemToDelete; // No products to evaluate
        }

        // Fetch material status codes from both modules
        Set<String> materialStatusCodes = new Set<String>();
        materialStatusCodes.addAll(fetchProductMaterialStatus('ECOM_Non_Sellable_Products'));
        materialStatusCodes.addAll(fetchProductMaterialStatus('DiscontinuedProduct'));
        if (materialStatusCodes.isEmpty()) {
            return cartItemToDelete; // No status codes to match
        }

        // Fetch product sales data and filter based on material status codes
        List<Product_Sales__c> productSalesList = ECOM_ProductService.getProductSales(productToCartItemMap.keySet(), new List<String>(materialStatusCodes));
        for (Product_Sales__c productSales : productSalesList) {
            if (materialStatusCodes.contains(productSales.Distribution_ChainSpecificMaterialStatus__c)) {
                CartItem item = productToCartItemMap.get(productSales.Product__c);
                if (item != null) {
                    cartItemToDelete.add(item);
                }
            }
        }
        return cartItemToDelete;
    }




	/**
    * @description Fetch Product Material Satus Codes.
    **/
    //Fetch Product Material Satus Codes
    public static List<String> fetchProductMaterialStatus(String moduleName){
        List<String> statusCodes = new List<String>();
        Map<String,String> cartStoreConfigs = ECOM_CartRepo.getStorefrontFrontConfigByModule(moduleName);
        String statusCodeString = '';
        if(moduleName == 'ECOM_Punchout'){
            statusCodeString = cartStoreConfigs.get(ECOM_Constant.MATERIAL_STATUS_CODES_PUNCHOUT);
        }
        //RWPS- 1456 START
        else if(moduleName == 'ECOM_Punchout_Custom')
        {
           statusCodeString = cartStoreConfigs.get(ECOM_Constant.PUNCHOUT_CUSTOM_MATERIAL_CODE);
        }
        //RWPS- 1456 END
        else {
           statusCodeString = cartStoreConfigs.get(ECOM_Constant.MATERIAL_STATUS_CODES);
        }
        //RWPS-2786 - START
        if(moduleName == 'ECOM_Non_Sellable_Products'){
            statusCodeString = cartStoreConfigs.get(ECOM_Constant.NON_SELLABLE_PRODUCTS);
        }
        if(moduleName == 'DiscontinuedProduct'){
            statusCodeString = cartStoreConfigs.get(ECOM_Constant.DISCONTINUED_PRODUCTS);
        }
        //RWPS-2786 - END

        // RWPS-3740 START
        if(moduleName == 'DirectReplacementStatus') {
            statusCodeString = cartStoreConfigs.get(ECOM_Constant.DIRECT_REPLACEMENT_PRODUCTS);
        } else if(moduleName == 'AlternativeReplacementStatus') {
            statusCodeString = cartStoreConfigs.get(ECOM_Constant.ALTERNATIVE_REPLACEMENT_PRODUCTS);
        }
        // RWPS-3740 END

        if(String.isNotEmpty(statusCodeString)){
            statusCodes = statusCodeString.split(',');
        }
        return statusCodes;
    }

    //Fetch Parent cart item from split cart items
    public static Map<String, CartItem> getParentCartItems(String cartId){
        List<ECOM_CartItemModel> cartItems = new List<ECOM_CartItemModel>();
        List<WebCart> carts = ECOM_CartRepo.getCartandCartItemsById(cartId);
        Map<String, CartItem> prodIdToCartItemMap = new Map<String, CartItem>();
        for(WebCart c :carts){
            for(CartItem ci :c.CartItems){
                //Select main Cart Item to update qty
                if(ci.ECOM_Parent__c == null){
                    // one parent cart item per product in the cart
                    prodIdToCartItemMap.put(ci.Product2.Id, ci);
                }
            }
        }
        return prodIdToCartItemMap;
    }

    //Add or update cart items
    public static List<CartItem> upsertCartItems(List<ECOM_CartItemModel> items, String cartId){
        List<ECOM_CartItemModel> cartItems = new List<ECOM_CartItemModel>();
        List<CartItem> cartItemsToUpsert = new List<CartItem>();
        for(ECOM_CartItemModel item: items){
            CartITem ci = new CartItem();
            ci.CartId = cartId;
            if(item.cartItemId != null){
                ci.id = item.cartItemId;
            }
            ci.product2Id = item.productId;
            ci.quantity = Decimal.valueOf(item.Quantity);
            ci.type = String.valueOf(ConnectApi.CartItemType.PRODUCT);
            cartItemsToUpsert.add(ci);
        }
        return cartItemsToUpsert;
    }

    //Update or insert cart items
    public static Boolean upsertCartItems(List<CartItem> cartItemsToUpsert){
        Boolean isSuccess = false;
        if(cartItemsToUpsert != null && cartItemsToUpsert.size() > 0){
        	ECOM_CartRepo.upsertCartItems(cartItemsToUpsert);
            isSuccess = true;
        }
        return isSuccess;
    }

    //fetch cart and cart item details for Addd cart items API call
    public static ECOM_CartModel populateCartDetails(String cartId){
        List<WebCart> cartsById = ECOM_CartRepo.getCartandProductTypeCartItemsById(cartId);
        List<ECOM_CartModel> carts = new List<ECOM_CartModel>();
        carts = parseWebCarts(cartsById);
        return carts[0];
    }

    /**
    * @description return ECOM_CartModel from webcart with cart items
    * @author Sidak  | 09-20-2024 | RWPS-1535
    * @param cartId
    * @return ECOM_CartModel
    **/
    public static ECOM_CartModel populateCartDetailsWithCartItems(String cartId){
        List<WebCart> cartsById = ECOM_CartRepo.getCartandProductTypeCartItemsSortedWithLimit(cartId);
        List<ECOM_CartModel> carts = new List<ECOM_CartModel>();
        carts = parseWebCarts(cartsById);
        return carts[0];
    }

     /**
    * @description return ECOM_CartModel from webcart without cart item
    * @author Manoj  | 05-28-2024
    * @param cartId
    * @return ECOM_CartModel
    **/
    public static ECOM_CartModel populateCartDetailsWithoutCartItem(String cartId){
        List<WebCart> cartsById = ECOM_CartRepo.getCartandProductTypeCartItemsById(cartId);
        List<ECOM_CartModel> carts = new List<ECOM_CartModel>();
        carts = parseWebCartsWithoutCartItems(cartsById);
        return carts[0];
    }

    /**
    * @description //To update cart on Contact update
    * @author Vipul Goyal | 09-21-2023
    * @param contactId
    * @return Map<String, Object>
    **/
    public static Map<String,Object> updateCartForAccountSwitch(String contactId)
    {
        Map<String,Object> responseMap=new Map<String,Object>();
        try{
            Contact con=ECOM_ContactService.getContactDetails(contactId);
            List<WebCart> carts=ECOM_CartService.getPrimaryCartBasedOnOwner(UserInfo.getUserId());
            if(!carts.isEmpty())
            {
                for(WebCart cart:carts)
                {
                    cart.AccountId=con.AccountId;
                    cart.ECOM_BillToAccount__c=con.ECOM_DefaultBillToAccount__c;
                    cart.ECOM_ShipToAccount__c=con.ECOM_DefaultShipToAccount__c;
                    cart.ECOM_DefaultBillToCPA__c=con.ECOM_DefaultBillToCPA__c;
                    cart.ECOM_DefaultShipToCPA__c=con.ECOM_DefaultShipToCPA__c;
                }
                ECOM_CartService.updateCart(carts);
            }
            responseMap.put('Success',true);
        }
        catch(Exception e)
        {
            responseMap.put('Success',false);
            responseMap.put('ErrorMessage',e.getStackTraceString());
        }
        return responseMap;

    }

    /** VRA punchout changes
     * @description update the cart model to include punchout related parameters
     * @author vramachandran@rafter.one | 08 Dec 2023
     * @param ECOM_CartFlowWrapper request
     * @param ECOM_CartModel cartModel
     * @return ECOM_CartModel
     */
    public static ECOM_CartFlowWrapper updatePunchoutData(ECOM_CartFlowWrapper request, ECOM_CartFlowWrapper response){
        if(null != request && request.operationType == System.Label.ECOM_CartOperation_GetCartItems && request.isPunchoutUser){
            ECOM_CartModel cartModel = response.cartModel;
            cartModel.accountName = request?.accountName;
            //cartModel.isPunchoutUser = request?.isPunchoutUser;
            cartModel.accountNumber = request?.accountNumber;
            cartModel.userName = request?.userName;
            response.responseJsonString = JSON.serialize(response.cartModel);
        }
        return response;
    }

    /**
     * @description This method updates the cart model flag for punchout cart
     * @author cartId | String
     * @return ECOM_CartModel
     */
    public static ECOM_CartModel checkIfPunchoutCart(String cartId, ECOM_CartModel cartModel){
        WebCart cartRecord = Test.isRunningTest() ? new WebCart() : ECOM_CartRepo.getPrimaryCartBasedOnId(cartId);
        if(cartRecord != null){
            cartModel.isPunchoutCart = Test.isRunningTest() ? true : cartRecord?.ECOM_Is_Punchout_Cart__c;
        }

        return cartModel;
    }

    /**
     * @description This method returns wrapped model from a given cart Record
     * @author vramachandran@rafter.one | 05 Jan 2024
     * @param cartRecord | WebCart
     * @returns ECOM_POOMModel
     */
    public static ECOM_POOMModel getPoomModel(WebCart cartRecord, ERP_AddressModel addressModel){
        ECOM_POOMModel poomCartModel = new ECOM_POOMModel();
        //ECOM_POOMModel.ECOM_POOMCart poomCartModel = new ECOM_POOMModel.ECOM_POOMCart();
        // Manoj 2024.06.14 RWPS-586 - New processor needed for our OCI response to send to Galapagos via EDI
        String processors = String.isNotBlank(addressModel?.po_Processors) ? addressModel?.po_Processors.replace(';',',') : ''; //GAr ECOM-2100 - converting multiple fields values into CSV
        poomCartModel.cartId = cartRecord.Id;
	    poomCartModel.currencyIsoCode = cartRecord?.CurrencyIsoCode;
        poomCartModel.format = addressModel?.po_PunchoutResponseFormat;
        poomCartModel.accountId = cartRecord?.AccountId;
        poomCartModel.accountName = cartRecord?.Account?.Name;
        //RWPS-5603-START
         poomCartModel.totalTariff = processors.contains('Tariff') ? String.valueOf(cartRecord?.Total_Tariff_Surcharge__c) : '0.0';
         //RWPS-5603-END
        //poomModel.accountNumber = cartRecord?.Account?.AccountNumber;
        poomCartModel.browserFormPost = cartRecord?.ECOM_POSR_Browser_Form_Post_Url__c;
        poomCartModel.buyerCookie = cartRecord?.ECOM_POSR_Buyer_Cookie__c;
        poomCartModel.firstName = cartRecord?.Owner?.FirstName;
        poomCartModel.lastName = cartRecord?.Owner?.LastName;
        poomCartModel.fromCredentialDomain = cartRecord?.ECOM_POSR_Header_From_Credential_Domain__c;
        poomCartModel.fromCredentialIdentity = cartRecord?.ECOM_POSR_Header_From_Credential_Ident__c;
        poomCartModel.grandTotalAmount = String.valueOf(cartRecord?.GrandTotalAmount);
        poomCartModel.isPunchoutCart = cartRecord?.ECOM_Is_Punchout_Cart__c;
        poomCartModel.lang = cartRecord?.ECOM_POSR_Header_Lang__c;
        poomCartModel.name = cartRecord?.Name;
        poomCartModel.ownerId = cartRecord?.OwnerId;
        poomCartModel.payLoadId = cartRecord?.ECOM_POSR_Header_Payload_Id__c;
        poomCartModel.purchaseOrderNumber = cartRecord?.PoNumber;
        poomCartModel.senderSharedSecret = addressModel?.po_SenderSharedSecret;
        poomCartModel.shippingMoney = String.valueOf(cartRecord?.ECOM_POOM_Shipping_Money__c);
        poomCartModel.status = cartRecord?.Status;
       // poomCartModel.supplierPartId = cartRecord?.ECOM_POSR_Supplier_Part_Id__c;
        poomCartModel.taxType = cartRecord?.TaxType;
        poomCartModel.toCredentialDomain = cartRecord?.ECOM_POSR_Header_To_Credential_Domain__c;
        poomCartModel.toCredentialIdentity = cartRecord?.ECOM_POSR_Header_To_Identity__c;
        poomCartModel.totalChargeAmount = String.valueOf((cartRecord?.Total_Tariff_Surcharge__c != null && cartRecord?.Total_Tariff_Surcharge__c > 0) ? (cartRecord?.TotalChargeAmount - cartRecord?.Total_Tariff_Surcharge__c): cartRecord?.TotalChargeAmount);//RWPS-5603
        poomCartModel.totalListPrice = String.valueOf(cartRecord?.TotalListAmount);
        poomCartModel.epPromoCode = cartRecord?.ECOM_Promo_Code__c;
        poomCartModel.totalTaxAmount = null != cartRecord?.TotalTaxAmount ? String.valueOf(cartRecord?.TotalTaxAmount) : '';
        //poomModel.totalMoney = cartRecord?.Total

        poomCartModel.webstoreId = cartRecord?.WebStoreId;
        poomCartModel.version = cartRecord?.ECOM_POSR_Header_Version__c;
        poomCartModel.userName = cartRecord?.Owner?.UserName;
        poomCartModel.userEmail = cartRecord?.Owner?.Email;
        poomCartModel.userId = cartRecord?.OwnerId;
        poomCartModel.uniqueName = addressModel?.po_AccountName;
        poomCartModel.type = cartRecord?.Type;
        poomcartModel.timestamp = cartRecord?.ECOM_POSR_Header_TimeStamp__c;

        poomCartModel.isSecondary = cartRecord?.IsSecondary;
        poomCartModel.supplierPartAuxiliaryId  = cartRecord?.Id;
        poomCartModel.processor = processors;
        poomCartModel.punchoutUOM = String.isNotBlank(addressModel?.po_UnitOfMeasure) ? addressModel?.po_UnitOfMeasure : ''; // RWPS-213 GAr - 6 Mar 2024 - mapping to Punchout UOM on ERP address
        poomCartModel.defaultUNSPSC = addressModel?.po_DefaultUNSPSC; //RWPS-410 GAr - 3 April 2024 - mapping to ECOM Punchout Default UNSPSC on ERP address
        poomCartModel.cartItems = new List<ECOM_POOMCartItem>();

        Map<String,Object> responseMap = getPoomCartItemModel(cartRecord?.CartItems, addressModel);

        if(null != responseMap && responseMap.containsKey(ECOM_Constant.PARAM_CART_ITEMS)){
            poomCartModel.cartItems = (List<ECOM_POOMCartItem>) responseMap.get(ECOM_Constant.PARAM_CART_ITEMS);
            poomCartModel.uniqueProductCount = (null != poomCartModel.cartItems && !poomCartModel.cartItems.isEmpty() ? poomCartModel.cartItems.size() : 0 );
        }
        if(null != responseMap && responseMap.containsKey(ECOM_Constant.PARAM_TOTAL_SHIPPING)){
            poomCartModel.shippingMoney = String.valueOf((Double) responseMap.get(ECOM_Constant.PARAM_TOTAL_SHIPPING));
        }

        System.debug('getPoomModel.poomCartModel:: '+ JSON.serialize(poomCartModel));
        //TODO: total product count
        //poomModel.poomCartModel = poomCartModel;
       return poomCartModel;
    }

	/**
	 * @description This method returns the List of mapped poom cart items
	 * @author vramachandran@rafter.one | 05 Jan 2024
	 * param cartItems | List<CartItems>
	 * @returns List<ECOM_POOMModel.POOMCartItem>
	 */
    public static Map<String,Object>  getPoomCartItemModel(List<CartItem> cartItems, ERP_AddressModel addressModel){
        Map<String,Object> responseMap = new Map<String,Object>();
        Double shippingCost = 0.0;
        Boolean isLargePackOrder = false; //RWPS-3658
        //RWPS-586
        List<C_META_Storefront_Configuration__mdt> euSalesOrgsConfigs =  ECOM_CustomMetadataRepo.fetchStoreConfigMdtBasedOnModuleName('EUSalesOrgs');
        List<C_META_Countries__mdt> userSalesOrgconfigs =  ECOM_CustomMetadataRepo.getSalesOrgs(addressModel.po_CountryCode);
		String userSalesOrg = '';
        userSalesOrg = userSalesOrgconfigs.size() >0? userSalesOrgconfigs[0].SalesOrg__c: '';
        String euSalesOrgs = '';
        euSalesOrgs = euSalesOrgsConfigs.size() >0? euSalesOrgsConfigs[0].Value__c: '';
        Boolean isEUUser = euSalesOrgs.contains(userSalesOrg);
        List<ECOM_POOMCartItem> poomItemsList = new List<ECOM_POOMCartItem>();
        System.debug('cartItems:: '+ cartItems);
        try{
            if( null != cartItems && !cartItems.isEmpty()){

                // RWPS-2786 Start
                Set<String> productIds = new Set<String>();
                for (CartItem cartItem : cartItems) {
                    productIds.add(cartItem.Product2Id);
                    //RWPS-3658 - Start
                    if (cartItem.Product2.Item_Class__c == '1' || cartItem.Product2.Item_Class__c == '2') {
                        isLargePackOrder = true;
                    }
                    //RWPS-3658 - End
                }

                List<String> allDiscontinuedNonSellableProducts = getNonSellableDiscountinuedProducts(productIds, 'both');
                Set<String> allDiscontinuedNonSellableProductsSet = new Set<String>(allDiscontinuedNonSellableProducts);
                // RWPS-2786 End
                //RWPS-5603-START
                String processors = String.isNotBlank(addressModel?.po_Processors) ? addressModel?.po_Processors.replace(';',',') : '';
                //RWPS-5603-END

                for(CartItem cartItem : cartItems) {

                    // RWPS-2786 Start
                    if ((!allDiscontinuedNonSellableProductsSet.isEmpty() && allDiscontinuedNonSellableProductsSet.contains(cartItem.Product2Id))) {
                        continue;
                    }
                    // RWPS-2786 End

                    if(cartItem.Type == ECOM_Constant.CARTITEM_TYPE_PRODUCT){
                        String accountUom = (null != addressModel && String.isNotBlank(addressModel.po_UnitOfMeasure)) ? addressModel.po_UnitOfMeasure : '';
                        System.debug('cartItem:: '+ cartItem);

                        ECOM_POOMCartItem poomItem = new ECOM_POOMCartItem();
                        poomItem.cartId = cartItem?.CartId;
                        poomItem.cartItemId = cartItem?.Id;
                        poomItem.currencyIsoCode = cartitem?.CurrencyIsoCode;
                        //poomItem.epPromoCode = cartItem?.
                        poomItem.hazardousMaterial = String.isNotEmpty(cartItem?.Product2?.Dangerous_Goods_Indicator_Profile__c) ? true : false;
                        poomItem.radioactive = String.isNotEmpty(cartItem?.Product2?.Dangerous_Goods_Indicator_Profile__c) ? true : false;
                        poomItem.itemizedAdjustmentAmount = String.valueOf(cartItem?.ItemizedAdjustmentAmount);
                        //RWPS-3658 - Start
                        poomItem.leadTime = String.valueOf(isLargePackOrder ? 0 :(cartItem?.ECOM_Selected_Shipping_Date__c != null ?Math.max(System.today().daysBetween(cartItem.ECOM_Selected_Shipping_Date__c), 0) :0));
                        //RWPS-3658 - End
                        poomItem.listPrice = String.valueOf(cartItem?.ListPrice);
                        //poomItem.manufacturerPartId = cartItem?.
                        poomItem.name = cartItem?.Name;
                        poomItem.type = cartItem?.Type;
                        poomItem.productDescription = cartItem?.Product2?.Description;
                        poomItem.productId = cartItem?.Product2Id;
                        poomItem.quantity = String.valueOf(cartItem?.Quantity);
                        poomItem.salesPrice = (cartItem?.SalesPrice) != 0 ?  String.valueOf(cartItem?.SalesPrice) : '0.0';
                        poomItem.totalAdjustmentAmount = (cartItem?.TotalAdjustmentAmount) != 0 ? String.valueOf(cartItem?.TotalAdjustmentAmount) : '0.0';
                        poomItem.totalAmount = (cartItem?.TotalAmount) != 0 ? String.valueOf(cartItem?.TotalAmount) : '0.0';
                        poomItem.totalListPrice = (cartItem?.TotalListPrice != 0) ? String.valueOf(cartItem?.TotalListPrice) : '0.0';
                        poomItem.totalPrice = (cartItem?.TotalListPrice) != 0 ? String.valueOf(cartItem?.TotalListPrice) : '0.0';
                        poomItem.totalTax = (cartItem?.TotalTaxAmount) != 0 ? String.valueOf(cartItem?.TotalTaxAmount) : '0.0';
                        poomItem.shippingCostItem = (cartItem?.ECOM_Shipping_Cost__c) != 0 ? String.valueOf(cartItem?.ECOM_Shipping_Cost__c) : '0.0'; //RWPS-2941
                        poomItem.totalTariffItem = processors.contains('Tariff') ? String.valueOf(cartItem?.Tariff_Surcharge__c) : '0.0';//RWPS-5603
                        poomItem.unitAdjustedPrice = (cartItem?.UnitAdjustedPrice) != 0 ? String.valueOf(cartItem?.UnitAdjustedPrice) : '0.0';
                        poomItem.unitAdjustmentAmount = (cartItem?.UnitAdjustmentAmount) != 0 ?  String.valueOf(cartItem?.UnitAdjustmentAmount) : '0.0';
                        poomItem.unspsc = String.valueOf(cartItem?.ECOM_POOM_fx_UNSPSC_Code__c);
                        poomItem.displayUrl = cartItem?.Product2?.DisplayUrl;
                        poomItem.thumbnailImageURL = cartItem?.Product2?.DisplayUrl;
                        poomItem.unitOfMeasure = String.isNotBlank(cartItem?.Product2?.QuantityUnitOfMeasure) ? cartItem?.Product2?.QuantityUnitOfMeasure : ''; //RWPS-213 GAr - 6 Mar 2024 - Mapping to Standard UOM on Product2
                        poomItem.isoUom = String.isNotBlank(cartItem?.Product2?.ECOM_ISO_UOM__c) ? cartItem?.Product2?.ECOM_ISO_UOM__c : ''; //RWPS-213 GAr - 6 Mar 2024 - Mapping to ISO UOM field on Product2
                        poomItem.unUom = String.isNotBlank(cartItem?.Product2?.ECOM_UNUOM__c) ? cartItem?.Product2?.ECOM_UNUOM__c : ''; //RWPS-213 GAr - 6 Mar 2024 - Mapping to UNUOM field on Product2
                        poomItem.ansiUom = String.isNotBlank(cartItem?.Product2?.ECOM_ANSI_UOM__c) ? cartItem?.Product2?.ECOM_ANSI_UOM__c : ''; //RWPS-213 GAr - 6 Mar 2024 - Mapping to ANSI UOM field on Product2
                        poomItem.unitPrice = ((cartItem?.SalesPrice) != 0 && String.isNotBlank(String.valueOf(cartItem?.SalesPrice)))  ?  String.valueOf(cartItem?.SalesPrice) :'0.0' ;//VRa: ECOM-2554 2024.02.14 - changed mapping to SalesPrice
                        poomItem.manufacturerPartId  = cartItem?.Product2?.Part_Number__c;
                        poomItem.supplierPartId = cartItem?.Product2?.Part_Number__c;
                        //RWPS-586
                        if( isEUUser){
                            poomItem.intrastatCode =cartItem?.Product2?.Intrastat_CommodityCode_EU__c!=null? cartItem?.Product2?.Intrastat_CommodityCode_EU__c:'';
                        }else{
                            poomItem.intrastatCode =cartItem?.Product2?.Intrastat_CommodityCode_ROW__c!=null ? cartItem?.Product2?.Intrastat_CommodityCode_ROW__c:'';
                        }
                        poomItemsList.add(poomItem);
                    } else if(cartItem.Type == ECOM_Constant.CARTITEM_TYPE_CHARGE && cartItem.Name == 'Shipping Cost'){//RWPS-5603
                        shippingCost += cartItem.TotalPrice;
                    }
                }
            }
        }catch(Exception e){
            System.debug('Cause:: '+ e.getMessage() + ' stack trace:: '+ e.getStackTraceString());
        }
                responseMap.put(ECOM_Constant.PARAM_TOTAL_SHIPPING, shippingCost);
        responseMap.put(ECOM_Constant.PARAM_CART_ITEMS, poomItemsList);

        return responseMap;
    }

    /**
     * @description This method creates and returns a new punchout cart
     * @author vramachandran@rafter.one | 05 Jan 2024
     * @param webstoreId | String
     * @param effectiveAccountId | String
     * @param addressModel | ERP_AddressModel
     * @result WebCart
     */
    public static void createNewPunchoutCart(String effectiveAccountId, String ownerId){
        System.debug('Creating new punchout cart');
        ConnectApi.CartInput cartInputObject = new ConnectApi.CartInput();
        List<WebCart> cartsToUpdate = new List<WebCart>();
        cartInputObject.effectiveAccountId = effectiveAccountId;
        //cartInputObject.isSecondary = true;//RWPS-1041
        List<WebStore> webStores= ECOM_WebStoreRepo.getWebStoreByName(Label.ECOM_WebStore_Name);
        Type userService = Type.forName(ECOM_Constant.USER_Service);
        ECOM_IUserService userServiceInstance = (ECOM_IUserService)userService.newInstance();
        if(!webStores.isEmpty())
        {
            String webstoreId = webStores[0].Id;

            ConnectApi.CartSummary cartSummaryObject = Test.isRunningTest() ? new ConnectApi.CartSummary() : ConnectApi.CommerceCart.createCart(webstoreId , cartInputObject);
            System.debug('cartSummaryObject.cartId:: '+ cartSummaryObject.cartId);
            if(cartSummaryObject!=null)
            {
                WebCart webNewCartObject = new WebCart();
                webNewCartObject.Id = cartSummaryObject.cartId;
                webNewCartObject.OwnerId = ownerId;
                webNewCartObject.ECOM_Is_Punchout_Cart__c = true;

                cartsToUpdate.add(webNewCartObject);

                If(!Test.isRunningTest())
                {
                    ECOM_CartRepo.updateCart(cartsToUpdate);
                    //ConnectApi.CommerceActionResult commerceActionResultObject = ConnectApi.CommerceCart.makeCartPrimary(webstoreId ,cartSummaryObject.cartId , effectiveAccountId);
                }
            }
        }
    }

    /**
     * @description This method returns the punchout cart details for a punchout user, if cart does not exist a new cart is created and returned
     * @author vramachandran@rafter.one | 04 Jan 2024
     * @param userRecord | User
     * @returns WebCart
     */
    public static WebCart getWebCartForPunchoutUser(User userRecord){
        WebCart cartRecord;
        List<WebCart> cartList = ECOM_CartRepo.getActiveCartForPunchoutUser(userRecord.Id);
        System.debug('getActiveCartForPunchoutUser:cartList:: '+ cartList);

        if(null != cartList && !cartList.isEmpty()){
            cartRecord = cartList[0];
        } else {
            if(!Test.isRunningTest()) ECOM_CartUtil.createNewPunchoutCart(userRecord.AccountId,userRecord.Id);
            cartList = Test.isRunningTest() ? new List<WebCart>() : ECOM_CartRepo.getPrimaryCartBasedOnOwner(userRecord.Id);
            cartRecord = Test.isRunningTest() ? new WebCart() : cartList[0];
            System.debug('getActiveCartForPunchoutUser.cart::' + JSON.serialize(cartList));
        }

        System.debug('getActiveCartForPunchoutUser:cartRecord:: '+ cartRecord);

        return cartRecord;
    }

     /**
     * @description This method updates Punchout logs using POSR values.
     * @author prabhat.kumar4@zensar.com | 3 Feb 2026
     * @param requestModel | ECOM_PunchoutWrapper.PunchoutServiceRequest
     * @param userRecord | User
     * JIRA : RWPS-6095
     */
    public static void updatePunchoutLogWithPOSRValues(ECOM_PunchoutWrapper.PunchoutServiceRequest requestModel, User userRecord) {
    // Serialize input for debugging purposes in case of failure
    Map<String, Object> supportMap = new Map<String, Object>{
        'request' => requestModel,
        'user' => userRecord
    };
    String supportData = JSON.serialize(supportMap);

        try {

            //get Punchout Format 
            //RWPS-6095 - START
            String punchoutFormat = '';
            Id masterAddressId = userRecord.Contact?.Default_Ship_to_ERP_Address__r?.Master_Address__c;
            List<Punchout_Maintenance__c> lstPunchoutConfig = ERP_AddressRepo.getPunchoutConfigBasedOnMaster(masterAddressId);
            if (!lstPunchoutConfig.isEmpty()) {
                punchoutFormat = lstPunchoutConfig[0].ECOM_Punchout_Format__c;
                    }
            //RWPS-6095 - END
            WebCart cartRecord = Test.isRunningTest() ? new WebCart() : getWebCartForPunchoutUser(userRecord);
            ECOM_Punchout_Log__c logEntry = new ECOM_Punchout_Log__c();
            
            if(punchoutFormat == 'OCI'){
                 logEntry.Payload_ID__c = cartRecord?.Id + requestModel.browserFormPost;
            }else{
                logEntry.Payload_ID__c = requestModel.payLoadId;
            }
            
            logEntry.Buyer_Cookie__c = requestModel.buyerCookie ?? '';
            logEntry.Contact__c = userRecord.ContactId;
            logEntry.Cart__c = cartRecord?.Id;
            logEntry.Customer_Name__c = userRecord.Contact?.Default_Ship_to_ERP_Address__r?.Master_Address__r?.ECOM_Punchout_Customer_Name__c ?? '';
            logEntry.Master_ERP_Address__c = userRecord.Contact?.Default_Ship_to_ERP_Address__r?.Master_Address__c;
            logEntry.Parser__c = punchoutFormat;
            logEntry.POSR_URL_params__c = JSON.serialize(requestModel);
            logEntry.Post_Form__c = requestModel.browserFormPost ?? '';
            logEntry.POSR_Timestamp__c = system.now();
            logEntry.Test_Record__c = userRecord.Name?.contains('Test User') ?? false;

            Database.UpsertResult sr = Database.upsert(logEntry, ECOM_Punchout_Log__c.Fields.Payload_ID__c, false);

        } catch (Exception ex) {
            // Log the failure using your Utility class
            ECOM_ApplicationLogsUtil.logFailure(
                ex, 
                'Update Punchout log with POSR Values', 
                'ECOM_CartUtil', 
                'updatePunchoutLogWithPOSRValues', 
                supportData
            );
        }
    }


      /**
     * @description This method updates Punchout log records using POOM values.
     * @author prabhat.kumar4@zensar.com | 3 Feb 2026
     * @param poomCartModel | ECOM_POOMModel
     * JIRA : RWPS-6095
     */
    public static void updatePunchoutLogWithPOOMvalues(ECOM_POOMModel poomCartModel, String poomResponse) {

            String supportData = JSON.serialize(poomCartModel);
            try {
                if (poomCartModel == null) return;
                    String punchoutFormat = poomCartModel.format;
                    String searchKey =  (punchoutFormat == 'cXML') ? poomCartModel.payLoadId : 
                                    (punchoutFormat == 'OCI') ? poomCartModel.cartId + poomCartModel.browserFormPost : null;


                    if (String.isBlank(searchKey)) return;

                    // Fetch log - Now contains ID
                List<ECOM_Punchout_Log__c> logs = ECOM_ApplicationLogsRepo.getPunchoutLogs(searchKey);
                    if (logs.isEmpty()) return;

                    ECOM_Punchout_Log__c logEntry = logs[0];

                    Decimal totalQuantity = 0;
                    Integer itemCount = 0;
                    if (poomCartModel.cartItems != null) {
                        itemCount = poomCartModel.cartItems.size();
                        for (ECOM_POOMCartItem item : poomCartModel.cartItems) {
                            totalQuantity += (item.quantity != null) ? Decimal.valueOf(item.quantity) : 0;
                        }
                    }
                    logEntry.Line_Items__c = itemCount;
                    logEntry.Order_Total__c = String.isNotBlank(poomCartModel.grandTotalAmount) ? Decimal.valueOf(poomCartModel.grandTotalAmount) : 0;
                    logEntry.POOM_Timestamp__c = System.now();
                    logEntry.Quantity__c = totalQuantity;
                    logEntry.POOM_Request__c = JSON.serialize(poomCartModel);
                    logEntry.CurrencyIsoCode = poomCartModel.currencyIsoCode;
                logEntry.POOM_cXML__c = poomResponse;
                    Database.update(logEntry, false); 

                }catch (Exception ex) {
                    ECOM_ApplicationLogsUtil.logFailure(ex, 'Update Punchout log with POOM Values', 'ECOM_CartUtil', 'updatePunchoutLogWithPOOMvalues', supportData);
                }
        }
    /**
     * @description This method updates POSR values on the current active cart for punchout user
     * @author vramachandran@rafter.one | 22 Dec 2023
     * @param requestModel | ECOM_PunchoutWrapper.PunchoutServiceRequest
     * @param userRecord | User
     */
    public static List<WebCart> updateCartWithPOSRValues(ECOM_PunchoutWrapper.PunchoutServiceRequest requestModel, User userRecord, ERP_AddressModel addressModel){
        List<WebCart> cartsToUpdate = new List<WebCart>();
        //WebCart cartRecord = ECOM_CartUtil.getWebCartForPunchoutUser(userRecord);
        WebCart cartRecord = Test.isRunningTest() ? new WebCart() : getWebCartForPunchoutUser(userRecord);
        //update cart fields
        //
        System.debug('updateCartWithPOSRValues:: requestModel: ' + JSON.serialize(requestModel));
        if(null != cartRecord){
            cartRecord.ECOM_Is_Punchout_Cart__c = true;
            cartRecord.ECOM_POSR_Browser_Form_Post_Url__c = String.isNotEmpty(requestModel.browserFormPost) ? requestModel.browserFormPost : '';
            cartRecord.ECOM_POSR_Buyer_Cookie__c = String.isNotEmpty(requestModel.buyerCookie) ? requestModel.buyerCookie : '';
            cartRecord.ECOM_POSR_First_Name__c = String.isNotEmpty(requestModel.firstName) ? requestModel.firstName : '';
            cartRecord.ECOM_POSR_Header_From_Credential_Domain__c = String.isNotEmpty(requestModel.fromCredentialDomain) ? requestModel.fromCredentialDomain : '';
            cartRecord.ECOM_POSR_Header_From_Credential_Ident__c = String.isNotEmpty(requestModel.fromCredentialIdentity) ? requestModel.fromCredentialIdentity : '';
            cartRecord.ECOM_POSR_Header_Lang__c = String.isNotEmpty(requestModel.lang) ? requestModel.lang : '';
            cartRecord.ECOM_POSR_Header_Payload_Id__c = String.isNotEmpty(requestModel.payLoadId) ? requestModel.payLoadId : '';
            cartRecord.ECOM_POSR_Header_Sender_Identity__c = String.isNotEmpty(requestModel.senderIdentity) ? requestModel.senderIdentity : '';
            cartRecord.ECOM_POSR_Header_SenderCredential_Domain__c = String.isNotEmpty(requestModel.senderCredentialDomain) ? requestModel.senderCredentialDomain : '';
            cartRecord.ECOM_POSR_Header_TimeStamp__c = String.isNotEmpty(requestModel.timeStamp) ? requestModel.timeStamp : '';
            cartRecord.ECOM_POSR_Header_To_Identity__c = String.isNotEmpty(requestModel.toIdentity) ?  requestModel.toIdentity : '';
            cartRecord.ECOM_POSR_Header_To_Credential_Domain__c = String.isNotEmpty(requestModel.toDomain) ? requestModel.toDomain : '';
            cartRecord.ECOM_POSR_Header_Version__c = String.isNotEmpty(requestModel.version) ? requestModel.version : '';
            cartRecord.ECOM_POSR_Last_Name__c = String.isNotEmpty(requestModel.lastName) ? requestModel.lastName : '';
            cartRecord.ECOM_POSR_Punchout_Format__c = String.isNotEmpty(requestModel.punchoutFormat) ?  requestModel.punchoutFormat : '';
            //cartRecord.ECOM_POSR_Selected_Item__c = String.isNotEmpty(requestModel.
            //cartRecord.ECOM_POSR_Supplier_Part_Id__c
            cartRecord.ECOM_POSR_Unique_Name__c = String.isNotEmpty(requestModel.uniqueName) ? requestModel.uniqueName : '' ;
            cartRecord.ECOM_POSR_UserEmail__c = String.isNotEmpty(requestModel.userEmail) ? requestModel.userEmail : '' ;
            cartRecord.ECOM_BillToAccount__c = userRecord.AccountId;// String.isNotEmpty(addressModel.accountId) ? addressModel.accountId : '' ;
            //cartRecord.ECOM_DefaultBillToCPA__c = (null != addressModel?.po_BillToAddress) ? addressModel.po_BillToAddress.id;
            //cartRecord.ECOM_DefaultShipToCPA__c = (null != addressModel?.po_ShipToAddress) ? addressModel.po_ShipToAddress.id;
            cartRecord.ECOM_ShipToAccount__c =  userRecord.AccountId;//String.isNotEmpty(addressModel.accountId) ? addressModel.accountId : '' ;
            if(null != addressModel.po_BillToAddress) cartRecord.Default_Bill_to_ERP_Address__c = addressModel.po_BillToAddress.id;
            if(null != addressModel.po_ShipToAddress) cartRecord.Default_Ship_to_ERP_Address__c = addressModel.po_ShipToAddress.id;
            //if(String.isNotEmpty(cartRecord.Default_Bill_to_ERP_Address__c) && String.isNotEmpty(cartRecord.Default_Ship_to_ERP_Address__c))
            cartsToUpdate.add(cartRecord);

            cartsToUpdate = Test.isRunningTest() ? cartsToUpdate : ECOM_CartRepo.updatePunchoutCart(cartsToUpdate);


        }
        //RWPS-6095
        updatePunchoutLogWithPOSRValues(requestModel,userRecord);
        return cartsToUpdate;
    }

    /**
     * @description This method is used to get order type based on products , sales org and payment type
     * @author Manoj | 2024.05.01
     * @param isLargePackOrder | Boolean
     * @param paymentType | String
     * @param requestType | String
     * @param salesOrg | String
     */
    public static String getOrderType (Boolean isLargePackOrder, String paymentType, String requestType , String salesOrg){
        C_META_ECOM_Order_Type_Mapping__mdt orderMapping  = ECOM_CustomMetadataRepo.fetchOrderTypeByDeveloperName(salesOrg);
        String orderType = salesOrg.equalsIgnoreCase('Punchout_Default')? orderMapping.Standard_Code__c:ECOM_Constant.ORDER_COMPONENT;//RWPS-4848
		if( requestType=='OrderSimulate'){
            if(isLargePackOrder){
               orderType = orderMapping!=null ? String.valueOf(orderMapping.Standard_Code__c ): orderType;
            }
        }else{
            if(isLargePackOrder && paymentType ==ECOM_Constant.PAYMENT_TYPE_CREDITCARD){
                orderType = orderMapping!=null ?  String.valueOf(orderMapping.Credit_Card_Code__c ) : ECOM_Constant.ORDER_COMPONENT_ZWCC;
            }else if(isLargePackOrder && paymentType ==ECOM_Constant.PAYMENT_TYPE_PO){
                orderType = orderMapping!=null ?  String.valueOf(orderMapping.Standard_Code__c ): orderType;
            }else{
            	orderType = paymentType == ECOM_Constant.PAYMENT_TYPE_CREDITCARD ? ECOM_Constant.ORDER_COMPONENT_ZWCC: orderType;
            }
        }
        return orderType;
}

    /**
    * @description This method returns the bill to and ship to of current user
    * @author Abhishek Joshi | 03-26-2025
    * @return Map<String,String>
    **/
    public static Map<String,String> getAddressesForCallout(){
        User u = ECOM_UserRepo.getUserByUserId(UserInfo.getUserId());
        String shipTo, billTo, country;
        if(
            u.Contact?.Default_Bill_to_ERP_Address__r?.Target_Address__r?.External_Id__c != null
            && u.Contact?.Default_Ship_to_ERP_Address__r?.Target_Address__r?.External_Id__c != null
        ) {
            billTo = u.Contact.Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c;
            shipTo = u.Contact.Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c;
            country = u.Contact.Default_Bill_to_ERP_Address__r.fxAddress_CountryCode__c;
        } else {
            ECOM_DummyAccountCountryMapping__mdt defaultmdt;
            defaultmdt = ECOM_CustomMetadataService.fetchDummyAccountCountryMappingData(ECOM_Util.getCountryFromUser(u));

            billTo = defaultmdt.Default_Bill_To__c;
            shipTo = defaultmdt.Default_Ship_to__c;
            List<C_META_Countries__mdt> userSalesOrgconfigs =  ECOM_CustomMetadataRepo.getSalesOrgs(u.Contact.ECOM_CountryProvided__c);
            country = userSalesOrgconfigs.size() > 0 ? userSalesOrgconfigs[0].CountryISOAlpha2__c: u.CountryCode;
        }

        return new Map<String,String>{'billTo' => billTo, 'shipTo' => shipTo, 'country' => country};
    }

     /**
      * RWPS-1285
      * @description  Added method to check if cart has largepack product.
      * @authro Gaurav Bhansali
      * @return boolean
      * @param cartId
      */
      @AuraEnabled
      public static boolean isLargePackItemExist(String cartId){
          List<CartItem> items = ECOM_CartService.getCartItemsByCartId(cartId);
             for(CartItem item : items){
                 if(item.Type=='Product' && String.isNotBlank(item.Product2.Item_Class__c) && (item.Product2.Item_Class__c=='1' || item.Product2.Item_Class__c=='2')){
                      return true;
                  }
              }
          return false;
      }

    /**
      * RWPS-1882
      * @description  Added method to check if InvoiceEmail exists for Contact Default bill to Address.
      * @author Poonam Shukla
      * @return boolean
      */
      public static boolean isInvoiceEmailExist(){
          User u = ECOM_UserRepo.getUserByUserId(UserInfo.getUserId());
          String billToEmailInvoice;
          String billToEInvoiceCustId;
            if(u.Contact?.Default_Bill_to_ERP_Address__r != null) {
                billToEmailInvoice = (u.Contact.Default_Bill_to_ERP_Address__r.Target_Address__c == null) ? u.Contact.Default_Bill_to_ERP_Address__r.ECOM_Email_to_invoice__c : u.Contact.Default_Bill_to_ERP_Address__r.Target_Address__r.ECOM_Email_to_invoice__c; // RWPS-4154
                billToEInvoiceCustId = (u.Contact.Default_Bill_to_ERP_Address__r.Target_Address__c == null) ? u.Contact.Default_Bill_to_ERP_Address__r.ECOM_E_Invoice_Cust_Id__c : u.Contact.Default_Bill_to_ERP_Address__r.Target_Address__r.ECOM_E_Invoice_Cust_Id__c; // RWPS-4154
            }
            if ((billToEmailInvoice == null || billToEmailInvoice.trim() == '') && (billToEInvoiceCustId == null || billToEInvoiceCustId.trim() == '')) {
                return false;
            } else {
                return true;
            }
      }

      /**
       * @author gaurav.bhansali@revvity.com | 27 June 2025 RWPS-2786
       * @description  Added method to get list of InActive Products.
       * @param cart, productIdSet
       * @return Set<String>
       */
      public static Set<String> getInActiveProducts(WebCart cart, Set<String> productIdSet) {
            Set<String> nonSellableDiscontinuedProducts = new Set<String>();
            List<String> materialStatusCodes =  new List<String>();
            materialStatusCodes.addAll(fetchProductMaterialStatus('ECOM_Non_Sellable_Products'));
            materialStatusCodes.addAll(fetchProductMaterialStatus('DiscontinuedProduct'));
            Type userService = Type.forName(ECOM_Constant.USER_Service);
            ECOM_IUserService userServiceInstance = (ECOM_IUserService)userService.newInstance();
            User us = userServiceInstance.getUserByUser(cart.ownerId);
            String salesOrg = ECOM_CustomMetadataService.getSalesOrg(ECOM_Util.getCountryFromUser(us));
            List<Product_Sales__c> lstProductSales = ECOM_ProductRepo.getProductSalesAbandonedCart(productIdSet,materialStatusCodes,salesOrg);
            if(lstProductSales.size() > 0){
                for(Product_Sales__c prodSales : lstProductSales){
                    nonSellableDiscontinuedProducts.add(prodSales.Product__c);
                }
            }
            return nonSellableDiscontinuedProducts;
      }

      /**
       * @author gaurav.bhansali@revvity.com | 27 June 2025 RWPS-2786
       * @description  Added method to get list of InActive Products.
       * @param cart, productIdSet
       * @return Set<String>
       */
      public static Map<String, Boolean> getInActiveProducts(List<WebCart> lstCart) {
            Map<String, Boolean> mapCartWithSellableStatus = new Map<String, Boolean>();
            Set<String> nonSellableDiscontinuedProducts = new Set<String>();
            List<String> materialStatusCodes =  new List<String>();
            materialStatusCodes.addAll(fetchProductMaterialStatus('ECOM_Non_Sellable_Products'));
            materialStatusCodes.addAll(fetchProductMaterialStatus('DiscontinuedProduct'));

            // Fetch all users and Product Ids
            Set<String> allUserIds = new Set<String>();
            Set<String> allProductIds = new Set<String>();

            for (Webcart webcart : lstCart) {
                allUserIds.add(webcart.OwnerId);
                for (CartItem cartItem : webcart.cartItems) {
                    allProductIds.add(cartItem.Product2Id);
                }
            }

            // Fetch all Sales Org and Associate Owner with Sales org
            Set<String> allSalesOrg = new Set<String>();
            Map<String, String> mapOwnerIdWithSalesOrg = new Map<String, String>();

            // Metadata retrieval is present in the for loop as it does not encounter against governer limits
            for (User user : ECOM_UserRepo.getUsersByUserIds(allUserIds)) {
                String salesOrg = ECOM_CustomMetadataService.getSalesOrg(ECOM_Util.getCountryFromUser(user));
                allSalesOrg.add(salesOrg);
                mapOwnerIdWithSalesOrg.put(user.Id, salesOrg);
            }

            List<Product_Sales__c> lstProductSales =
                [SELECT Id, Distribution_ChainSpecificMaterialStatus__c, Product__c, Product__r.Part_Number__c, Sales_Org__c
                FROM Product_Sales__c
                WHERE Product__c IN :allProductIds AND Sales_Org__c IN:allSalesOrg AND Distribution_ChainSpecificMaterialStatus__c IN:materialStatusCodes];

            Set<String> allNonSellableProductSaleRecords = new Set<String>();

            if (lstProductSales.size() > 0) {
                for (Product_Sales__c prodSales : lstProductSales){
                    String productSaleRecord = prodSales.Product__c + '-' + prodSales.Sales_Org__c;
                    allNonSellableProductSaleRecords.add(productSaleRecord);
                }
            }
			// If there is no non sellable/discontinued record found, then directly show them sellable
            if (allNonSellableProductSaleRecords.isEmpty()) {
                for (Webcart webcart : lstCart) {
                    mapCartWithSellableStatus.put(webcart.Id, true);
                }
            } else {
                for (Webcart webcart : lstCart) {
                    mapCartWithSellableStatus.put(webcart.Id, false);
                    for (CartItem cartItem : webcart.cartItems) {
                        if (cartItem.Type == 'Product') {
                            String productSaleComparisonLiteral = cartItem.Product2Id + '-' + mapOwnerIdWithSalesOrg.get(webcart.OwnerId);
                            if (
                                !allNonSellableProductSaleRecords.contains(productSaleComparisonLiteral)
                            ) {
                                mapCartWithSellableStatus.put(webcart.Id, true);
                                break;
                            }
                        }

                    }
                }
            }

            return mapCartWithSellableStatus;
      }

      /**
       * @author gaurav.bhansali@revvity.com | 3 Sep 2025 RWPS-4202
       * @description  create map for cartitems to reduce cartItem iteration
       * @param cartItems
       * @return Map<String, Boolean>
       */
      public static Map<String, Object> getCartItemDetailsMap(List<CartItem> cartItems) {
        Map<String, Object> cartItemDetailsMap = new Map<String, Object>();
        Map<String, CartItem> partNumberToCartItemMap = new Map<String, CartItem>();
        Map<String, String> cartItemToPartNumMap = new Map<String, String>();
        Set<String> productIdSet = new Set<String>();
        boolean isFreeItemAdded = false;
        for(CartItem item : cartItems){
            productIdSet.add(item.product2Id);
            partNumberToCartItemMap.put(item.Product2.Part_Number__c,item);
            cartItemToPartNumMap.put(item.Id,item.Product2.Part_Number__c);
            if(String.isNotBlank(item.ecom_parent_item__c))
                isFreeItemAdded = true;
        }
        cartItemDetailsMap.put('partNumberToCartItemMap',partNumberToCartItemMap);
        cartItemDetailsMap.put('isFreeItemAdded',isFreeItemAdded);
        cartItemDetailsMap.put('productIdSet',productIdSet);
        cartItemDetailsMap.put('cartItemToPartNumMap',cartItemToPartNumMap);
        return cartItemDetailsMap;
    }

    
    /**
     * RWPS-6394
     * @description Check if EInvoiceCustId (Peppol ID) exists or not
     * @author Poonam Shukla
     * @return Boolean
    */
    public static Boolean isEInvoiceCustIdExist(){

        User userRecord = ECOM_UserRepo.getUserByUserId(UserInfo.getUserId());
        String eInvoiceCustId;

        Map<String,String> cartStoreConfigs = ECOM_CartRepo.getStorefrontFrontConfigByModule('ECOM_InvoiceCustId_Countries');

        String invoiceCustIdCountries = cartStoreConfigs.get(ECOM_Constant.ECOM_INVOICE_CUSTID_COUNTRIES);

        Boolean isCountryEnabled = false;

        if(String.isNotBlank(invoiceCustIdCountries)){
            for(String country : invoiceCustIdCountries.split(',')){
                if(country.trim() == userRecord.Contact.ECOM_CountryProvided__c){
                    isCountryEnabled = true;
                    break;
                }
            }
        }

        if(!isCountryEnabled){
            return true;
        }

        if(userRecord.Contact?.Default_Bill_to_ERP_Address__c != null){
            eInvoiceCustId =  (userRecord.Contact.Default_Bill_to_ERP_Address__r.Target_Address__c != null) ? userRecord.Contact.Default_Bill_to_ERP_Address__r.Target_Address__r.ECOM_E_Invoice_Cust_Id__c: userRecord.Contact.Default_Bill_to_ERP_Address__r.ECOM_E_Invoice_Cust_Id__c;
        }

        if(String.isBlank(eInvoiceCustId))
        { 
            return false; 
        }
        else 
        {
            return true;
        }
    }
}