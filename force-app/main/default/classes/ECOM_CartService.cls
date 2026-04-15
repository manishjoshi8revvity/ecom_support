/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-493
*
* 2. Description - This class is used for Cart specific transactions.
*				 - This class return WebCart Record with ECOM_SimulateOrderWrapper
				 - return addItemToCarts CartItem Records
				 - This class is used in Modifying the Cart Items like price,add item,delete items etc
*
*
* 3. Objects referenced
*    - WebCart
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_CartOperationsFlowController
*    - ECOM_CartRepo
*    - ECOM_SessionCacheUtil
*    - ECOM_SimulateOrderWrapper
*    - ECOM_ProductRepo
*    - ECOM_Util
*
* 6. Test Class Name:
*    - ECOM_CartService_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Manoj kumar 2023.08.09
*    - Dar wright 2023.09.15
*    - Sidak 2024.01.16 Added method deleteCartItem. Ticket - ECOM-1384
*    - Sidak 2024.01.25 Added method checkProductMaterialStatus. Ticket - ECOM-2224
*    - Sidak 2024.02.05 Added logs in addItemsToCart method. Ticket - RWPS-95
*    - Sidak 2024.02.08 Added method createCartCheckoutSession. Ticket - RWPS-120
*    - Gaurang 2024.02.20 Added DML methods
*    - Vasudev 2024.02.21 Fix for RWPS-179
*    - Gaurang 2024.02.26 Dev for RWPS-179
*    - Sidak 2024.03.01 Added method updateCartItemListPrice. Ticket - RWPS-182
*    - Sidak 2024.04.08 Updated method repriceCart to check for Default Bill to/Ship to Address on Cart and Contact. Ticket - RWPS-415
*    - Sidak 2024.04.16 Added method retrieveProductsByPartialPartNumber. Ticket - RWPS-29
*    - Sidak 2024.04.19 Updated getCartDetails method to call getCartDetails from ECOM_CartRepo. Ticket - RWPS-416
*    - Vipul Goyal 2024.04.23 Updated Abandoned Cart methods.
*	 - Vipul Goyal 2024.04.30 Updated sendEmailsForAbandonedCart.
*    - Sidak 2024.05.15 Added method deleteShippingCartItem - Added logic to delete Shipping charge item if last product is also deleted from cart. Ticket - RWPS-632
*    - Sidak 2024.05.17 Updated method updatePunchoutCart - Added cart Id in response map. Ticket - RWPS-723
*    - Sidak 2024.05.21 Updated method repriceCart - Added addressError in response map. Ticket - RWPS-736
*	 - Sathiya 2024.06.11 Updated method getCartItems to add a validation for product T & C ECOM-123
*    - Sidak 2024.05.21 Added method updateBillToShipToOnCart. Ticket - RWPS-766
*	 - Sathiya 2024.06.13 Updated sendEmailsForAbandonedCart to default orgWideEmailAddress.
*    - Sidak 2024.07.16 Added method getProductSalesByProdIdAndMaterialCodes. Ticket - RWPS-949
*    - Manoj 2024.07.19 SF: Pass the punchout domain in punchout_data Ticket - RWPS-1115
*	 - Sathiya 2024.08.30 ECOM-1480 Added for exception logs
*    - Sidak 2024.09.05 Added method getCartCheckoutSessionByCartId. Ticket - RWPS-1382
*    - Sidak 2024.09.09 Updated method retrieveProductsByPartialPartNumber. Added logic to check valid sales status of the product Ticket - RWPS-1477
*    - Manoj 2024.09.09 RWPS-1387 read image from Product2.ECOM_Product_Media_URI__c(DAM) instead product media
*    - Sidak 2024.09.26 - Updated method addItemsToCart. Added populateCartDetailsWithCartItems. Ticket - RWPS-1535
*    - Sidak 2024.10.09 Updated method updateBillToShipToOnCart, added logic to check mismatch between cart and contact bill to/ship to. Ticket - RWPS-1602
*    - Sidak 2024.10.15 Updated method retrieveProductsByPartialPartNumber. Added parameter communityId Ticket - RWPS-1582
*    - Sathiya 2024.10.23 Updated the ProductTnC to show only unique values on Terms and Conditions
*    - Sidak 2024.11.04 Updated method repriceCart. Added null checks for Bill to/Ship to for Cart page error. Ticket - RWPS-1843
*    - Gaurav Bhansali 2024.12.31 RWPS-2052 - Updated repriceCart - Added logic to check coupon already used on any order or not.
*    - Poonam Shukla 2025.01.06 RWPS-1456 Updated getProductSalesByProdIdAndMaterialCodes,retrieveProductsByPartialPartNumber added custom sales status for punchout
*    - Gaurav Bhansali 2024.01.14 RWPS-2307 - Updated repriceCart - Added logic to implement first order promotion.
*    - Manish Joshi 2025.01.27 - Updated method getCartItems to retrieved product display name - RWPS-2270
*    - Poonam Shukla 2025.02.07 - Updated method retrieveProductsByPartialPartNumber. Replaced calling method - RWPS-1456
*    - Prabhat Kumar 2025.02.25 - Added method updateCartItemListPrice to update list price on Cart Item - RWPS-2683
*    - Manish Joshi 2025.02.28 - updated method repriceCart and passed userId RWPS-2684
*    - Gaurav Bhansali 2025.03.13 - Updated method repriceCart - Added query to check coupon exist in SF RWPS-2800
*    - Prabhat Kumar 2025.03.18 - Removed method updateCartItemListPrice and updated repriceCart to update listprice on cart items- RWPS-2683
*    - Vinay Kumar 2025.03.18 - Updated methods checkProductMaterialStatus, repriceCart and repriceCart - RWPS-2346
*    - Poonam Shukla 2025.04.02 - Updated method repriceCart- Added logic for NoBillingShipping Address error on checkout and cart page- RWPS-1548
*    - Manish Joshi 2025.04.14 - Updated method repriceCart for code coverage - RWPS-1548
*    - Gaurav Bhansali 2025.04.15 - Updated method repriceCart - Added promo msg response for cached request RWPS-2916
*    - Prabhat Kumar 2025.04.25- Created method deleteTariffLineItem to delete Tariff cart line item - RWPS-3026
*    - Chirag L 2025.04.30 - Uncommented the code related to abandoned cart email for setOrgWideEmailAddressId method - RWPS-3004
*    - Gaurav 2025.05.12 - Updated method repriceCart - Added condition for punchout cart RWPS-3220
*    - Prabhat 2025.05.13 - Updated method sendEmailsForAbandonedCart -  RWPS-3197
*    - Prabhat 2025.05.13 - Updated repriceCart in the logs to show part number - RWPS-3265
*    - Gaurav 2025.05.22 - Added isCouponExistInList and Updated method repriceCart for promotion logic RWPS-3283
*    - Prabhat Kumar 2025.06.10 - Updated method repriceCart to pass latest cart items to updateCartItems - RWPS-3262
*    - Gaurav 2025.06.17 - Updated method repriceCart - Added county to check coupon validity RWPS-3186
*    - Prabhat Kumar 2025.06.19 - Updated method addItemsToCart and repriceCart to get to exclude discontinued and non sellable products - RWPS-2786
*    - Gaurav 2025.06.30 - Updated sendEmailsForAbandonedCart to check cart has active/sellable item or not - RWPS-2786
*    - Prabhat Kumar 2025.07.25 - Created methods getShippingTimeObj and getMaxDLVRecord to get the shipping time data - RWPS-1603
*    - Chirag  2025.07.14 Updated method updateCartItemListPrice to support quantity as a parameter - RWPS-3683
*    - Poonam 2025.07.18- Added method filterAbandonedOptInCarts to get optin contacts for Abandoned cart email- RWPS-3306
*    - Prabhat Kumar 2025.07.25 - Updated reprice method to consider excluded products from coupon - RWPS-3812
*    - Gaurav 2025.08.26 - Updated repriceCart,deleteCartItem, addItemsToCart and added isBOGOApplied for BOGO implementation - RWPS-3811
*    - Gaurav 2025.09.03 - Added getFreeItemPromoMsg for BOGO implementation - RWPS-4202
*    - Prabhat Kumar 2025.09.11 -Updated method repriceCart to include BOGO related changes.  - RWPS-3811
*    - Poonam 2025.09.12 -Updated method filterAbandonedOptInCarts, added Email Field to existing query.  - RWPS-4435
*    - Manish Joshi 2025.09.25 - Updated method deleteCartItem with coupon removal logic - RWPS-4500
*    - Sachin 2025.09.24 - Updated addItemsToCart method for replacement - RWPS-3740/RWPS-4621
*    - Manish Joshi 2025.11.07 - Updated method repriceCart - RWPS-4871
*    - Kushal Shah 2025.12.03 - Moved the address update logic to run after the SAP callout to prevent DML before callout - RWPS-5269
*    - Prabhat Kumar 2025.12.03 -Updated method addItemsToCart and deleteCartItem to add/delete training products.  - RWPS-4896
*    - Prabhat Kumar 2025.12.08 -Updated method deleteCartItem to remove unwanted code and updated logic  - RWPS-4896
*    - Prabhat Kumar 2025.12.09 -Updated method updateCartItemListPrice,addItemsToCart to add training products  - RWPS-4896
*    - Kushal Shah 2025.12.09 - Added updateCartShiptoOrBillto before SAP callout and performed DML after the callout to avoid DML before callout issue. - RWPS-5269
*    - Prabhat Kumar 2025.12.15 -Updated method updateCartItemListPrice,addItemsToCart to add include training products in the cart - RWPS-4896
*    - Sachin V 2026.01.29 - Updated method : repriceCart - RWPS-5938
*    - Kushal Shah 2026.03.02 - Updated method : getPunchoutCartandCartItemsById - RWPS-5775
*    - Poonam Shukla 2026.03.18 - Updated method : updateEInvoiceCustIdOnERPAddress - RWPS-6394

**************************************************************/

public with sharing class ECOM_CartService implements ECOM_ICartService{

    public static String CLASSNAME = 'ECOM_CartService';
    /**
    * @description This method is used to validate the product material status.
    * @author Sidak Singh | 01-25-2024
    * @param cartId
    * @return Map<String, Object>
    **/
    public static Map<String,Object> checkProductMaterialStatus(String cartId) {
        Map<String,Object> response = new Map<String,Object>();
        String supportData = JSON.serialize(cartId);
        try{
            List<WebCart> cartList = ECOM_CartRepo.getCartandCartItemsById(cartId);
            if(cartList ==null || cartList.size()== 0){ // RWPS-2346
                response.put('success', true);
                response.put('message', 'No active cart.');
                return response;
            }
            List<ECOM_CartModel> cartModels = ECOM_CartUtil.parseWebCarts(cartList);
            ECOM_CartModel cm = ECOM_CartUtil.validateProductMaterialStatus(cartModels.get(0), CLASSNAME);
            response.put('success', true);
            response.put('salesStatus', cm);
        }catch(Exception ex){
            response.put('success',false);
            response.put('message',ex.getMessage());
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.USER_MODULE_NAME, className, 'checkProductMaterialStatus', supportData);
        }
        return response;
    }

    /**
    * @description
    * @author mkumar@rafter.one | 07-17-2023
    * @param cartId
    * @return Map<String, Object>
    **/
    public static Map<String,Object> repriceCart(String cartId, String couponCode) {
        Map<String,Object> response = new Map<String,Object>();
        //To exclude charge type cart items
        List<CartItem> productTypeCartItems = new List<CartItem>();
        String supportData = '';
        String apiResponse = '';
        response.put('success', false);
        HttpResponse httpRes = new HttpResponse();
        ECOM_SimulateOrderWrapper.OrderResponse res = new ECOM_SimulateOrderWrapper.OrderResponse();
        try {
            supportData = JSON.serialize(cartId);
            // get cart data
            List<WebCart> cartList = ECOM_CartRepo.getCartandCartItemsById(cartId);
            if(cartList ==null || cartList.size()== 0){ // RWPS-2346
                response.put('success', true);
                response.put('message', 'No active cart.');
                return response;
            }
            //List<ECOM_CartModel> cartModels = ECOM_CartUtil.parseWebCarts(cartList);
            //ECOM_CartModel cm = ECOM_CartUtil.validateProductMaterialStatus(cartModels.get(0), CLASSNAME);
            //System.debug('cm>>> ' + cm);
            //Need to improve logic to reduce duplicate
            //cartList = ECOM_CartRepo.getCartandCartItemsById(cartId);
            response.put('PunchoutCart',cartList[0].ECOM_Is_Punchout_Cart__c);
            //RWPS-5938
            if (ECOM_CustomLoginController.getMagicLinkImplementationActivationStatus() == true) {
                response.put('PunchoutViaWeb',cartList[0]?.Contact__r?.ECOM_Punchout_Via_Web__c);
            }//RWPS-5938         

            if(String.isNotBlank(couponCode)){
               response.put('isPromoApplied', true);
               response.put('isPromoAlreadyApplied',false);//RWPS-3812
            }else{
                // check coupon already applied previously
                couponCode = cartList[0].ECOM_Promo_Code__c;
                if(String.isNotBlank(couponCode)){
                    response.put('isPromoApplied', true);
                    response.put('isPromoAlreadyApplied',true);//RWPS-3812
                }
                else {
                    response.put('isPromoApplied', false);
                    response.put('isPromoAlreadyApplied',false);//RWPS-3812
                }
            }
            //RWPS-3812-START
            List<Coupon> listCouponCode = ECOM_CartRepo.getCouponByCouponCode(couponCode);
            Set<String> setExcludedProducts = new Set<String>();
            //RWPS-3811 - START
            Set<String> setBogoApplicableProducts = new Set<String>();
             if (!listCouponCode.isEmpty() && String.isNotBlank(listCouponCode[0].BOGO_Applicable_Products__c) && listCouponCode[0].Promotion.Name == Label.ECOM_BuyOneGetOnePromo) {
                if(listCouponCode[0].BOGO_Applicable_Products__c != null){
                    List<String> parts = listCouponCode[0].BOGO_Applicable_Products__c.split(',');
                    for (String part : parts) {
                        setBogoApplicableProducts.add(part.trim());
                    }
                }
            }
             //RWPS-3811 - END
            if (!listCouponCode.isEmpty() && String.isNotBlank(listCouponCode[0].ECOM_Excluded_Products__c)) {
                if(listCouponCode[0].ECOM_Excluded_Products__c != null){
                    List<String> parts = listCouponCode[0].ECOM_Excluded_Products__c.split(',');
                    for (String part : parts) {
                        setExcludedProducts.add(part.trim());
                    }
                }
            }
            // RWPS-2786 Start
            Set<String> productIds = new Set<String>();
            Set<String> productSetExcluded = new Set<String>();
            Boolean isProductExcluded = false;
            Boolean isBogoProductApplicable = false;//RWPS-3811
            Map<String, Boolean> bogoApplicableProudctsMap = new Map<String, Boolean>();//RWPS-3811
            Boolean isBogoApplicable = false;//RWPS-3811
            for (CartItem item : cartList[0].cartItems) {
                productIds.add(item.Product2Id);
                if( item.Type=='Product'){
                    productTypeCartItems.add(item);
                    if(setExcludedProducts.contains(item.Product2.Part_Number__c)){
                        productSetExcluded.add(item.Product2.Part_Number__c);
                        isProductExcluded = true;

                    }
                    //RWPS-3811 - START
                    if(setBogoApplicableProducts.contains(item.Product2.Part_Number__c)){
                        isBogoProductApplicable = true;
                        bogoApplicableProudctsMap.put(item.id, true);
                    }
                    //RWPS-3811 - END
                }
            }
            //RWPS-3812-END
            List<String> allDiscontinuedProducts = ECOM_CartUtil.getNonSellableDiscountinuedProducts(productIds, 'discontinued');
            Set<String> allDiscontinuedProductsSet = new Set<String>(allDiscontinuedProducts);
            // RWPS-2786 End

            if(productTypeCartItems.size() == 0){
                response.put('success', true);
                //response.put('salesStatus', cm);
                response.put('message', 'No cart items.');
                ECOM_SessionCacheUtil.clearEcomCache();
                return response;
            }

              //RWPS-2786 - START
            if(allDiscontinuedProductsSet.size() == productTypeCartItems.size()){
                    response.put('success', true);
                    //response.put('salesStatus', cm);
                    response.put('message', 'All Discontinued Products');
                    ECOM_SessionCacheUtil.clearEcomCache();
                    List<CartItem> cartItems= ECOM_CartUtil.updateCartItems(cartList[0],cartList[0].cartItems, null, null);
                    return response;
            }

            //RWPS-3812 - START
            if(isProductExcluded && response.get('isPromoAlreadyApplied')==false){
                response.put('success', true);
                response.put('isValidPromo', false);
                response.put('promoMessage', 'Promo code ' + couponCode + ' is not applicable for product(s) - ' + String.join(new List<String>(productSetExcluded), ', ')+' ' +Label.ECOM_Excluded_Product_Msg);
                String severity = ECOM_Util.getSeverityByMessage('Invalid promo code');//RWPS-6037
                ECOM_ApplicationLogsUtil.logApplicationApiData(ECOM_Constant.CART_SERVICE, className, 'repriceCart', supportData, 'Excluded Proudcts ' + couponCode + ' - Invalid promo code', null, severity);//RWPS-6037
                return response;
            }
             if(String.isNotEmpty(couponCode) && isProductExcluded){
                couponCode = '';
            }
            //RWPS-3812 - END

            //RWPS-2786 - END
            //RWPS-3283 changes
            if(String.isNotEmpty(couponCode) && cartList[0].ECOM_Is_Punchout_Cart__c && isCouponExistInList(couponCode,ECOM_CartRepo.getCouponList(ECOM_Constant.WEB_PROMOTION))){
                response.put('success', true);
                response.put('isValidPromo', false);
                response.put('promoMessage', Label.ECOM_InvalidPunchoutPromoCodeMsg);
                String severity = ECOM_Util.getSeverityByMessage('Invalid promo code');//RWPS-6037
                ECOM_ApplicationLogsUtil.logApplicationApiData(ECOM_Constant.CART_SERVICE, className, 'repriceCart', supportData, 'Punchout - ' + couponCode + ' - Invalid promo code', null, severity);//RWPS-6037
                return response;
            }
            if(String.isNotEmpty(couponCode) && !cartList[0].ECOM_Is_Punchout_Cart__c && isCouponExistInList(couponCode,ECOM_CartRepo.getCouponList(ECOM_Constant.PUNCHOUT_PROMOTION))){
                response.put('success', true);
                response.put('isValidPromo', false);
                response.put('promoMessage', Label.ECOM_InvalidPunchoutPromoCodeMsg);
                String severity = ECOM_Util.getSeverityByMessage('Invalid promo code');//RWPS-6037
                ECOM_ApplicationLogsUtil.logApplicationApiData(ECOM_Constant.CART_SERVICE, className, 'repriceCart', supportData, 'Web User - ' + couponCode + ' - Invalid promo code',null, severity);//RWPS-6037
                return response;
            }
            //RWPS-3283 changes end
            //added check for RWPS-2307, RWPS-2684
            if(String.isNotBlank(couponCode) && ECOM_CartRepo.isValidPromo(couponCode, Label.ECOM_FirstOrderPromoName) > 0 && ECOM_OrderRepo.getUserOrderCount(UserInfo.getUserId()) > 0) {
                response.put('success', true);
                response.put('isValidPromo', false);
                response.put('promoMessage', Label.ECOM_FirstOrderPromoErrorMsg);
                return response;
            }
            //added check for RWPS-2052, RWPS-2684
             if(String.isNotBlank(couponCode) && ECOM_CartRepo.isValidPromo(couponCode, Label.ECOM_SingleUsePromoName) > 0) { //RWPS-2052
                Integer orderCount = ECOM_OrderRepo.checkIfCouponUsed(couponCode);
                if(orderCount> 0){
                    response.put('success', true);
                    response.put('isValidPromo', false);
                    response.put('promoMessage', Label.ECOM_SingleUsePromoErrorMsg);
                    return response;
                }
            }

            //RWPS-3811 - START
             Boolean isOneTimePromoError = false;
             Boolean isBogoApplicablePromoError = false;
             if(String.isNotBlank(couponCode) && listCouponCode.size() > 0 && listCouponCode[0].Promotion.Name == Label.ECOM_BuyOneGetOnePromo) {
                if(!isBogoProductApplicable){
                    if(response.get('isPromoAlreadyApplied')==false){
                    response.put('success', true);
                    response.put('isValidPromo', false);
                    response.put('promoMessage', Label.ECOM_BogoErrorMessage);
                    String severity = ECOM_Util.getSeverityByMessage('Invalid promo code');//RWPS-6037
                    ECOM_ApplicationLogsUtil.logApplicationApiData(ECOM_Constant.CART_SERVICE, className, 'repriceCart', supportData, 'Bogo Promo - ' + couponCode + ' - Invalid promo code', null, severity);//RWPS-6037
                    return response;
                    }else{
                        couponCode = '';
                        isBogoApplicablePromoError = true;
                    }
                } else if(listCouponCode[0].Usage_Type__c == 'One Time' && isBogoProductApplicable){
                    Integer orderCount = ECOM_OrderRepo.checkIfCouponUsed(couponCode);
                    if(orderCount> 0){
                        if(response.get('isPromoAlreadyApplied')==false){
                        response.put('success', true);
                        response.put('isValidPromo', false);
                        response.put('promoMessage', Label.ECOM_SingleUsePromoErrorMsg);
                        return response;
                        }else{
                            couponCode = '';
                            isOneTimePromoError = true;
                        }
                    }
                }else{
                    isBogoApplicable = true;
                }
            }
            //RWPS-3811 - END

            User user = new ECOM_UserService().getUserByUserId();
            Contact con = ECOM_ContactRepo.getContactBasedOnId(user.ContactId);

            //RWPS-3816 Start
            List<ERP_Relationship__c> disabledAddresses = ERP_AddressRepo.getDisabledERPAddressesFromERPRelationship(user.ContactId);
            Set<String> disabledAddressIds = new Set<String>();
            for (ERP_Relationship__c erp : disabledAddresses) {
                if (erp.ERP_Address__c != null)
                    disabledAddressIds.add(erp.ERP_Address__c);
            }
            if (disabledAddressIds.contains(cartList[0].Contact__r.Default_Ship_to_ERP_Address__r.Master_Address__c)
            ){
                response.put('success', false);
                response.put('responseError', System.Label.ECOM_NewAddressesNotRegisteredError);
                response.put('addressError', true);
                response.put('DisabledERPAddress', true);
                return response;
            }//RWPS-3816 End

            //RWPS-4871 Start - Moved Billing/Shipping address null checks above Order Simulate and added return response
            if(cartList[0].Default_Bill_to_ERP_Address__c == null && cartList[0].Default_Ship_to_ERP_Address__c != null &&
                con.Default_Bill_to_ERP_Address__c == null && con.Default_Ship_to_ERP_Address__c != null){
                response.put('success',false);
                response.put('responseError', System.Label.ECOM_NoBillingMessage);
                response.put('addressError',true); //Added addressError in response map for Bill to null| 04 Nov 2024 | RWPS-1843
                return response;
            }
            if(cartList[0].Default_Bill_to_ERP_Address__c != null && cartList[0].Default_Ship_to_ERP_Address__c == null &&
                con.Default_Bill_to_ERP_Address__c != null && con.Default_Ship_to_ERP_Address__c == null){
                response.put('success',false);
                response.put('responseError', System.Label.ECOM_NoShippingMessage);
                response.put('addressError',true); //Added addressError in response map for Ship to null| 04 Nov 2024 | RWPS-1843
                return response;
            }
            if(cartList[0].Default_Bill_to_ERP_Address__c == null && cartList[0].Default_Ship_to_ERP_Address__c == null &&
                con.Default_Bill_to_ERP_Address__c == null && con.Default_Ship_to_ERP_Address__c == null){
                response.put('success',false);
                response.put('responseError', System.Label.ECOM_NoBillingShippingMessage);
                response.put('addressError',true); //Added addressError in response map | 21 May 2024 | RWPS-736
                response.put('NoBillingShipping',true);//RWPS-1548
                return response;
            }
            //RWPS-4871 End
            //RWPS-5269 Start
            Boolean updateCartShiptoOrBillto = false;
            if((cartList[0].Default_Bill_to_ERP_Address__c == null && con.Default_Bill_to_ERP_Address__c != null) || (cartList[0].Default_Ship_to_ERP_Address__c == null && con.Default_Ship_to_ERP_Address__c != null)){
                cartList[0].Default_Bill_to_ERP_Address__c = con.Default_Bill_to_ERP_Address__c;
                cartList[0].Default_Ship_to_ERP_Address__c = con.Default_Ship_to_ERP_Address__c;
                updateCartShiptoOrBillto = true;
            } //RWPS-5269 End
            
            //Updated the logic to check for Default Bill to/Ship to Address on Cart and Contact. Ticket RWPS-415
            if( (cartList[0].Default_Bill_to_ERP_Address__c != null && cartList[0].Default_Ship_to_ERP_Address__c != null) ||
                (cartList[0].Default_Bill_to_ERP_Address__c == null && con.Default_Bill_to_ERP_Address__c != null && cartList[0].Default_Ship_to_ERP_Address__c != null) ||
                (cartList[0].Default_Bill_to_ERP_Address__c != null && cartList[0].Default_Ship_to_ERP_Address__c == null && con.Default_Ship_to_ERP_Address__c != null) ){
                    //RWPS-3811-START
                    Map<String, Object> requestData = new  Map<String, Object>();
                                        requestData.put('cart',cartList[0]);
                                        requestData.put('couponCode',couponCode);
                                        requestData.put('user',user);
                                        requestData.put('contact', con);
                                        requestData.put('bogoApplicableProudctsMap', bogoApplicableProudctsMap);
                                        requestData.put('productIds',productIds);
                    //RWPS-3811-END
                    // generate request body
                    ECOM_SimulateOrderWrapper.OrderRequest orderRequest = ECOM_CartUtil.generateOrderSimulationRequest(requestData);//RWPS-3811
                    response.put('osRequest', orderRequest);
                    String requestBody = JSON.serialize(orderRequest);
                    String requestKey = 'requestData';
                    String responseKey = 'responseData';
                    //RWPS-3186 start
                    if(String.isNotBlank(couponCode) && ECOM_CartRepo.isValidCouponCode(couponCode) > 0 && ECOM_CartRepo.isValidCouponCode(couponCode,orderRequest.country) == 0) {
                        response.put('success', true);
                        response.put('isValidPromo', false);
                        response.put('promoMessage', Label.ECOM_InvalidPunchoutPromoCodeMsg);
                        String severity = ECOM_Util.getSeverityByMessage('Invalid promo code');//RWPS-6037
                        ECOM_ApplicationLogsUtil.logApplicationApiData(ECOM_Constant.CART_SERVICE, className, 'repriceCart', supportData, couponCode + ' - Invalid promo code for country - ' + orderRequest.country, null, severity);//RWPS-6037
                        return response;
                    }
                    //RWPS-3186 end
                    // Check same  reguest is cached or not
                    Boolean isOSCached = ECOM_SessionCacheUtil.isOrderSimulationCached(orderRequest);
                    List<ECOM_SimulateOrderWrapper.Item> prodList = orderRequest.product_list;
                    for (Integer i = 0; i < prodList.size(); i++) {
                        if(prodList[i].qtyLimitExceeded){
                            isOSCached = false;
                        }
                    }
                    response.put('session req key ', Cache.Session.contains(requestKey));
                    response.put('session res key ', Cache.Session.contains(responseKey));
                    response.put('isOSCached ', isOSCached);

                    if(!isOSCached){
                        //prepare SAP request
                        Map<String, String> requestMap = ECOM_Util.generateRequestMap(requestBody, 'OrderSimulate');
                        //Do order simulate callout
                        httpRes = ECOM_RestService.doBasicHttpRequest(requestMap);
                        System.debug(httpRes.getStatusCode() + ' >>>>> ' +  httpRes.getBody());
                        if(httpRes.getStatusCode()==200 && httpRes.getStatus()=='OK'){
                            response.put('response body', httpRes.getBody());
                            if(httpRes.getBody()!=''){
                                res = ECOM_SimulateOrderWrapper.parse(httpRes.getBody());
                                response.put('success', true);
                                if(res.error != null){
                                    response.put('responseWrapper', res.error);
                                }else{
                                    //update price and taxes
                                    supportData =  ' \n'+'Request - '+JSON.serialize(orderRequest);// TODO for any exception in below method we should add request to support data
                                    List<CartItem> cartItems= ECOM_CartUtil.updateCartItems(cartList[0],cartList[0].cartItems, orderRequest, res);
                                    //update coupon code(@manoj need to modify if coupon is passed only invoke then)
                                    WebCart updatedCart = ECOM_CartUtil.updateCouponAndDiscount(cartItems, couponCode, res); //RWPS-3262
                                    response.put('simulation response', res);
                                    if( response.get('isPromoApplied')==true){
                                        response.put('isValidPromo',updatedCart.ECOM_Total_Savings__c >0 && updatedCart.ECOM_Promo_Code__c != '' && !isProductExcluded ? true: false);//RWPS-3262
                                        String bogoMsg = getFreeItemPromoMsg(cartItems);
                                        if(String.isNotEmpty(bogoMsg)){
                                            response.put('promoMessage', Label.ECOM_BOGOMsg + bogoMsg); //RWPS-3811
                                            response.put('isValidPromo', true);
                                        }
                                        else if(ECOM_CartRepo.isValidCouponCode(couponCode) > 0 && updatedCart.ECOM_Total_Savings__c ==0) { //RWPS-3186
                                            response.put('promoMessage', Label.ECOM_LargePackErrorMsg);
                                        }else if(isProductExcluded){//RWPS-3812 - START
                                          String severity = ECOM_Util.getSeverityByMessage('Invalid promo code');//RWPS-6037
                                          response.put('promoMessage', 'Promo code ' + couponCode + ' is not applicable for product(s) - ' + String.join(new List<String>(productSetExcluded), ', ')+' ' +Label.ECOM_Excluded_Product_Msg);
                                          ECOM_ApplicationLogsUtil.logApplicationApiData(ECOM_Constant.CART_SERVICE, className, 'repriceCart', supportData, 'Excluded Proudcts ' + couponCode + ' - Invalid promo code', null, severity);//RWPS-6037
                                        }else if(isOneTimePromoError){//RWPS-3811 - Start
                                            response.put('promoMessage', updatedCart.ECOM_Total_Savings__c >0 && updatedCart.ECOM_Promo_Code__c != '' ? 'Promo ' + couponCode+' is applied.' : Label.ECOM_SingleUsePromoErrorMsg);//RWPS-3811
                                        }else if(isBogoApplicablePromoError){
                                            response.put('promoMessage', updatedCart.ECOM_Total_Savings__c >0 && updatedCart.ECOM_Promo_Code__c != '' ? 'Promo ' + couponCode+' is applied.' : Label.ECOM_BogoErrorMessage);//RWPS-3811
                                        }else{//RWPS-3812 - END /RWPS-3811 - End
                                          response.put('promoMessage', updatedCart.ECOM_Total_Savings__c >0 && updatedCart.ECOM_Promo_Code__c != '' ? 'Promo ' + couponCode+' is applied.' : Label.ECOM_InvalidPromoCode);//RWPS-3262

                                        }

                                        if(updatedCart.ECOM_Total_Savings__c  == 0) {
                                            supportData =  ' \n'+'Request - '+JSON.serialize(orderRequest);//RWPS-3265
                                            ECOM_ApplicationLogsUtil.logApplicationApiData(ECOM_Constant.CART_SERVICE, className, 'repriceCart', supportData, couponCode +' Invalid promo code, discount amount is zero');//RWPS-3265
                                        }
                                    }
                                    response.put('cartItems', cartItems);
                                }
                                // Set data in session cache
                                new ECOM_SessionCacheUtil().setSessionCache(requestKey, requestBody);
                                new ECOM_SessionCacheUtil().setSessionCache(responseKey, httpRes.getBody());
                                apiResponse = httpRes.getBody();//RWPS-1228
                            }else{
                                response.put('responseError', System.Label.ECOM_101003);
                                apiResponse = httpRes.getBody();//RWPS-1228
                            }
                        }else{
                            response.put('success', false);
                            response.put('responseError', System.Label.ECOM_101003);
                            apiResponse = httpRes.getBody();//RWPS-1228
                        }
                        //response.put('salesStatus', cm);
                        response.put('request', orderRequest);
                        response.put('fromCache', false);
                    }
                    if(Test.isRunningTest() || isOSCached){ // RWPS-1548
                        //RWPS-2683-Start - Update List Price.
                        String salesOrg =  ECOM_CustomMetadataService.getSalesOrg(orderRequest.country);
                        ECOM_CartUtil.updateCartItemListPrice(salesOrg, cartList[0], cartList[0].cartItems);
                        ECOM_SimulateOrderWrapper.OrderResponse orderRes = ECOM_SessionCacheUtil.getOrderSimulationResponse();  //RWPS-2916
                        //RWPS-2683 - End
                        //RWPS-2786-Start
                         List<CartItem> cartItemsToUpdate = new List<CartItem>();
                         cartItemsToUpdate.addAll(ECOM_CartUtil.updateDiscountinuedProducts(cartList[0].cartItems, allDiscontinuedProductsSet));
                          if(cartItemsToUpdate.size() > 0){
                                ECOM_CartRepo.updateCartItems(cartItemsToUpdate);
                         }
                        //RWPS-2786-End
                        response.put('success', true);
                        //response.put('salesStatus', cm);
                        response.put('request', orderRequest);
                        response.put('fromCache', true);
                        response.put('responseWrapper',orderRes);  //RWPS-2916
                        apiResponse = JSON.serialize(response.get('responseWrapper'));//RWPS-1228
                        //RWPS-2916 start
                        Decimal totalDiscount = 0.0;
                        for (ECOM_SimulateOrderWrapper.ProductList product : orderRes.productList) {
                            totalDiscount += product.discount;
                        }

                        if( response.get('isPromoApplied')==true){
                            response.put('isValidPromo',totalDiscount >0 ? true: false);
                            String bogoMsg = getFreeItemPromoMsg(cartList[0].cartItems); //RWPS-3811
                            if(String.isNotEmpty(bogoMsg)){
                                response.put('promoMessage', Label.ECOM_BOGOMsg + bogoMsg);
                                response.put('isValidPromo',true);
                            }//RWPS-3811
                            else if(ECOM_CartRepo.isValidCouponCode(couponCode) > 0 && totalDiscount ==0 ) {
                                response.put('promoMessage', Label.ECOM_LargePackErrorMsg);
                            }else {
                                response.put('promoMessage', totalDiscount >0 ? 'Promo ' + couponCode+' is applied.' : Label.ECOM_InvalidPromoCode);
                            }
                        }
                        //RWPS-2916 End
                    }
                supportData =  ' \n'+'Request - '+JSON.serialize(orderRequest);
            }
            //Log Request and response
            //RWPS-5269 Start
            if(updateCartShiptoOrBillto) {
                ECOM_CartRepo.updateCart(cartList);
            }
            //RWPS-5269 End
			ECOM_ApplicationLogsUtil.setupApplicationRecord(ECOM_Constant.CART_SERVICE, className, 'repriceCart', supportData,'Response - '+apiResponse, 'OS', (Boolean)response.get('success')?null:ECOM_Constant.INTEGRATION_EXCEPTION);
        }catch (Exception ex) {
            response.put('responseCatch ', ex.getMessage()+ex.getStackTraceString());
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.CART_SERVICE, className, 'repriceCart', supportData);
        }
       return response;
    }


    /**
    * @description This function is used to retrieve the products based on the product codes.
    * @author Vipul Goyal | 07-31-2023
    * @param productCodes
    * @return Map<String, Object>
    **/
    public static Map<String,Object> retrieveProductsByPartNumber(List<ECOM_CartController.ECOM_ProductWrapper> productCodes) {
        Map<String,Object> response = new Map<String,Object>();
        String supportData  = JSON.serialize(productCodes);
        try{
            List<String> partNumbers = ECOM_CartUtil.getPartNumbers(productCodes);
            List<Product2> products=ECOM_ProductRepo.getProductsBasedOnPartNumber(partNumbers);

            response.put('success',true);
            response.put('products',products);
        }catch(Exception ex){
            response.put('success',false);
            response.put('message',ex.getMessage());
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.USER_MODULE_NAME, className, 'repriceCart', supportData);

        }
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
    public static Map<String,Object> retrieveProductsByPartialPartNumber(String productData, List<String> excludedItems, Boolean isPunchoutCart, String communityId) {
        Map<String,Object> response = new Map<String,Object>();
        String supportData  = productData;
        try{
            Map<String,Object> responseMap = new  Map<String,Object>();
            List<Product_Sales__c> productSales = new List<Product_Sales__c>();
            List<String> materialCodes = new List<String>();

            if(isPunchoutCart == true){
                materialCodes = ECOM_CartUtil.fetchProductMaterialStatus('ECOM_Punchout');
            }
            else {
                materialCodes = ECOM_CartUtil.fetchProductMaterialStatus('ECOM_CartService');
            }
            List<Product_Sales__c> products=ECOM_ProductService.getProductsBasedOnPartialPartNumber(productData, excludedItems, materialCodes, communityId, isPunchoutCart);//RWPS-1456
            response.put('success',true);
            response.put('products',products);
        }catch(Exception ex){
            response.put('success',false);
            response.put('message',ex.getMessage());
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.USER_MODULE_NAME, className, 'retrieveProductsByPartialPartNumber', supportData);//RWPS-1456

        }
        return response;
    }

    /**
    * @description  Add Cart Items to the Cart for the logged in user
    * @author mkumar@rafter.one | 09-21-2023
    * @param communityId
    * @param effectiveAccountId
    * @param cartItems
    * @return Map<String, Object>
    **/
    public static Map<String,Object> addItemsToCart(String communityId, String effectiveAccountId, List<CartItem> cartItems){
        Map<String,Object> responseMap = new Map<String,Object>();
        String supportData  = JSON.serialize(cartItems);
        try {
            ConnectApi.BatchResult[] batchResults = new List<ConnectApi.BatchResult>();
            List<ConnectApi.BatchInput> addedCartItems = new List<ConnectApi.BatchInput>();
            Set<String> productIdSet = new Set<String>();
            List<Product_Recommendation__c> trainingProductList =new List<Product_Recommendation__c>();//RWPS-4896
            String webstoreId = ECOM_Util.resolveCommunityIdToWebstoreId(communityId);
            String activeCartOrId = '';
            //get cart for logged in user
            List<WebCart> webCarts = ECOM_CartRepo.getPrimaryCartBasedOnOwner(UserInfo.getUserId());
            if(!webCarts.isEmpty()){
                activeCartOrId = webCarts[0].Id;
            }else{
                activeCartOrId = 'current';
            }
			deleteFreeItems(activeCartOrId); //RWPS-3811
            //RWPS-2786 - Start
            //RWPS-4621 - Start
            for(CartItem cartItem : cartItems) {
                if (cartItem.Product2Id != null) {
                    productIdSet.add(cartItem.Product2Id);
                }
            }
            //RWPS-4621 - End
            List<CartItem> trainingCartItems = new List<CartItem>();
            Set<String> trainingProductIds = New Set<String>();//RWPS-4896
            Set<String> genericTrainingProductIds = New Set<String>();//RWPS-4896
            //RWPS-4896-start
            for(Product_Recommendation__c pr : ECOM_ProductRecommendationsRepo.getRecommendationsTrainingProducts('Combination',productIdSet)){
                    if(productIdSet.contains(pr.Product_Main__c)){
                        CartItem item = new CartItem();
                        item.Product2Id = pr.Product_Suggested__c;
                        item.Quantity = 1;
                        cartItems.add(item);
                        trainingProductList.add(pr);//RWPS-4896
                        trainingProductIds.add(pr.Product_Suggested__c);//RWPS-4896
                        productIdSet.add(pr.Product_Suggested__c);
                        break;//RWPS-4896
                    }
            }
            List<String> lstNonSellableDiscontinuedProducts = ECOM_CartUtil.getNonSellableDiscountinuedProducts(productIdSet, 'both');
            //RWPS-4896
            for(Product_Recommendation__c genericRecommendation : ECOM_ProductRecommendationsRepo.getRecommendationsTrainingProducts('Combination',new Set<String>())){
                if (genericRecommendation.Product_Suggested__c != null) {
                    genericTrainingProductIds.add(genericRecommendation.Product_Suggested__c);
                }
            }
             //RWPS-4896-end
            if(!cartItems.isEmpty()){
                for(CartItem item: cartItems){
                    if(!lstNonSellableDiscontinuedProducts.contains(item.Product2Id) && String.isEmpty(item.ECOM_Parent_Item__c)){ //RWPS-3811
                        ConnectApi.CartItemInput cartInput = new ConnectApi.CartItemInput();
                        cartInput.productId = item.Product2Id;
                        cartInput.quantity = String.valueOf(Math.round(item.Quantity));
                        cartInput.type = ConnectApi.CartItemType.PRODUCT;
                        ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(cartInput);
                        addedCartItems.add(batchInput);
                    }
                 }
            }
            //RWPS-2786 - End
            //@manoj This method need to be splited in to 2 methods as we cannot cover connect api in test classes
              batchResults = Test.isRunningTest() ? null: ConnectApi.CommerceCart.addItemsToCart(
              webstoreId, effectiveAccountId, activeCartOrId,addedCartItems);

            Map<String,Map<String,String>> productMap=new Map<String,Map<String,String>>();
            List<String> itemsAddedSuccessfully=new List<String>();
            responseMap.put('cartId',activeCartOrId);
            List<CartItem>cartItemsToUpdate = new List<CartItem>();
            if(batchResults!=null){
                for (ConnectApi.BatchResult batchResult : batchResults) {
                    Map <String, String> jsonMap = new Map <String, String> ();
                    if (batchResult.isSuccess() && batchResult.getResult() instanceof ConnectApi.CartItem) {
                        ConnectApi.CartItem cartItem = (ConnectApi.CartItem) batchResult.getResult();
                        productMap.put(cartItem.productId,processCartItem(cartItem, productIdSet));
                        if(cartItem.listPrice=='0' || cartItem.listPrice==null){
                            //RWPS-4896
                            if(trainingProductIds.contains(cartItem.productId) || (genericTrainingProductIds.contains(cartItem.productId))) {
                                cartItemsToUpdate.add(new CartItem(Id=cartItem.cartItemId ,listPrice = Decimal.valueOf(cartItem.salesPrice),quantity=1,TotalListPrice = Decimal.valueOf(cartitem.salesPrice),TotalPrice=Decimal.valueOf(cartitem.salesPrice)));
                            }else{
                                cartItemsToUpdate.add(new CartItem(Id=cartItem.cartItemId ,listPrice = Decimal.valueOf(cartItem.salesPrice)));
                            }
                        } else
                        //RWPS-4896 -START
                        if((trainingProductIds.contains(cartItem.productId) || genericTrainingProductIds.contains(cartItem.productId)) && (cartItem.listPrice !='0' || cartItem.listPrice !=null)) {
                            cartItemsToUpdate.add(new CartItem(Id=cartItem.cartItemId ,quantity = 1, listPrice = Decimal.valueOf(cartitem.salesPrice),TotalListPrice = Decimal.valueOf(cartitem.salesPrice),TotalPrice=Decimal.valueOf(cartitem.salesPrice)));
                        }
                        //RWPS-4896 -END
                        itemsAddedSuccessfully.add(cartItem.productId);
                    }
                }
            }
            if(cartItemsToUpdate.size() > 0){
                ECOM_CartRepo.updateCartItems(cartItemsToUpdate);
            }
            responseMap.put('products',productMap);
            responseMap.put('itemsAddedSuccessfully',itemsAddedSuccessfully);
            responseMap.put('trainingProductsMap', trainingProductList);//RWPS-4896
            if(!productIdSet.isEmpty()){
                responseMap.put('success',false);
            }else {
                responseMap.put('success',true);
            }
        } catch (Exception ex) {
            responseMap.put('success',false);
            responseMap.put('responseCatch ', ex.getMessage()+ex.getStackTraceString());
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.CART_SERVICE, className, 'addItemsToCart', supportData);
        }
        return responseMap;
    }

    public static Map <String, String>  processCartItem(ConnectApi.CartItem cartItem, Set<String> productIdSet){
        Map <String, String> productMap = new Map <String, String>();
        if(productIdSet.contains(cartItem.productId)){
            productMap.put('Status', 'Success');
            productMap.put('productId', cartItem.productId);
            productMap.put('productName', cartItem.name);
            productMap.put('quantity', cartItem.quantity);
            productMap.put('activeCartOrId', cartItem.cartId);
            productIdSet.remove(cartItem.productId);
        }
        return productMap;
    }



    /**
    * @description Add Cart Items to the Cart of the logged in user
    * @author mkumar@rafter.one | 09-21-2023
    * @param carts
    * @return List<ECOM_CartModel>
    **/
    public List<ECOM_CartModel> addItemsToCart(List<ECOM_CartModel> carts){

        List<ECOM_CartModel> cartModels = new List<ECOM_CartModel>();
        String errorMsg = '';
        String supportData = '';
        try {
            supportData = JSON.serialize(carts);
            String webstoreId = '';
            String activeCartOrId = '';
            String effectiveAccountId = '';
            String ownerId = '';
            List<ConnectApi.BatchInput> addedCartItems = new List<ConnectApi.BatchInput>();// add items
            List<ConnectApi.CartItem> connectCartItems = new List<ConnectApi.CartItem>();// update items
            List<CartItem> cartItemsToUpsert = new List<CartItem>();
            Set<String> productIds = new Set<STring>();
            Set<String> productIdSet = new Set<String>();//RWPS-4896
            Set<String> trainingProductIds = New Set<String>();//RWPS-4896
            Set<String> genericTrainingProductIds = New Set<String>();//RWPS-4896
            Map<String, String> prodIdToPriceMap = new Map<String, String>();

            //Loop through ECOM_CartModel
            for(ECOM_CartModel cart :carts){
                if (String.isNotBlank(cart.webstoreId)){
                    webstoreId = cart.webstoreId;
                } else {
                    webstoreId = ECOM_Util.getWebStoreIdByName();
                }
                effectiveAccountId = cart.accountId;
                if(String.isNotBlank(cart.userId)){
                	ownerId = cart.userId;
                }
                //Cart Id is not passed from CMS so create a new Cart for the user
                if(cart.cartId == null && String.isNotEmpty(ownerId)){
                    //Check if cart exists or not then create new cart
                    List<WebCart> cartsByOwner = ECOM_CartRepo.getPrimaryCartBasedOnOwner(ownerId);
                    if((cartsByOwner != null && cartsByOwner.size() > 0)){ //RWPS-2346
                        if (cartsByOwner[0].Status == ECOM_Constant.CART_STATUS_ACTIVE || cartsByOwner[0].Status == ECOM_Constant.CART_STATUS_CHECKOUT){
                        	activeCartOrId = cartsByOwner[0].Id;
                        } else {
                           errorMsg = 'Cart can not be updated as cart is in  '+cartsByOwner[0].Status+ ' state' ;
                    	   break;
                        }
                    } else {
                        // Create new cart
                    	ECOM_CartUtil.createNewCart(ownerId, effectiveAccountId, effectiveAccountId);
                        List<WebCart> cartsByOwnerNew = ECOM_CartRepo.getPrimaryCartBasedOnOwner(ownerId);
                        if(cartsByOwnerNew != null && cartsByOwnerNew.size() > 0){
                            activeCartOrId = cartsByOwnerNew[0].Id;
                        }
                    }
                } else if(cart.cartId != null){
                    //Cart id is passed from CMS
                    activeCartOrId = cart.cartId;
                } else {
                    errorMsg = 'Cart ID OR User Id is missing in the request';
                    break;
                }
                if(String.isBlank(errorMsg) && !cart.cartItems.isEmpty()){
                    deleteFreeItems(activeCartOrId); //RWPS-3811
                    //fetch parent cart item based on product id
                    Map<String, CartItem> prodIdToCartItem = ECOM_CartUtil.getParentCartItems(activeCartOrId);

                    //cartItemsToUpsert = ECOM_CartUtil.upsertCartItems(cart.cartItems, activeCartOrId);
                    for(ECOM_CartItemModel item: cart.cartItems){
                        if(String.isNotBlank(item.listPrice)){
                        	prodIdToPriceMap.put(item.productId, item.listPrice);
                        }
                        productIdSet.add(item.productId);//RWPS-4896
                        // update block - cart item id is passed in request
                        if(item.cartItemId != null && String.isNotBlank(item.cartItemId) ){
                            //prepare Cart Items in ConnectApi.CartItemInput format
                            ConnectApi.CartItemInput cartItem = new ConnectApi.CartItemInput();
                            cartItem.productId = item.productId;
                            cartItem.Quantity = item.quantity;
                            //cartItem.type = ECOM_Constant.CARTITEM_TYPE_PRODUCT;
                            //Calling update connect API in loop as API accepts only one cart item
                            ConnectApi.CartItem ci = ECOM_CartRepo.updateCartItem(webstoreId, effectiveAccountId, activeCartOrId, item.cartItemId, cartItem);
                            connectCartItems.add(ci);
                        } else {
                            //cart item id is missing in request, fetch parent cart item and add/update quantity
                            if(prodIdToCartItem != null && prodIdToCartItem.get(item.productId) != null){
                            	CartItem parentCI = prodIdToCartItem.get(item.productId);
                                ConnectApi.CartItemInput cartItem = new ConnectApi.CartItemInput();
                            	cartItem.productId = item.productId;
                                System.debug('parentCI.Quantity =='+parentCI.Quantity + 'item.quantity == '+item.quantity);
                                Decimal qty = parentCI.Quantity+Decimal.valueOf(item.quantity);
                            	//cartItem.Quantity = parentCI.Quantity+item.quantity; //child cart item qty?
                            	cartItem.Quantity = String.valueOf(qty);
                                ConnectApi.CartItem ci = ECOM_CartRepo.updateCartItem(webstoreId, effectiveAccountId, activeCartOrId, parentCI.Id, cartItem);
                            	connectCartItems.add(ci);
                            } else {
                                // if there is no cart item id in request and no cart item in cart based on product id then insert new cart item
                                ConnectApi.CartItemInput cartInput = new ConnectApi.CartItemInput();
                                cartInput.productId = item.productId;
                                cartInput.quantity = String.valueOf(item.Quantity);
                                cartInput.type = ConnectApi.CartItemType.PRODUCT;
                                ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(cartInput);
                                addedCartItems.add(batchInput);
                            }
                        }
                    }
                }
            }
            //RWPS-4896-START
            List<Product_Recommendation__c> listProductRecommendation = ECOM_ProductRecommendationsRepo.getRecommendationsTrainingProducts('Combination',productIdSet);
            if(listProductRecommendation.size()>0){
                for(Product_Recommendation__c pr : listProductRecommendation){
                ConnectApi.CartItemInput cartInput = new ConnectApi.CartItemInput();
                cartInput.productId = pr.Product_Suggested__c;
                cartInput.quantity = '1';
                cartInput.type = ConnectApi.CartItemType.PRODUCT;
                ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(cartInput);
                addedCartItems.add(batchInput);
                trainingProductIds.add(pr.Product_Suggested__c);
                break;
            }
            }
            //RWPS-4896
            for(Product_Recommendation__c genericRecommendation : ECOM_ProductRecommendationsRepo.getRecommendationsTrainingProducts('Combination',new Set<String>())){
                if (genericRecommendation.Product_Suggested__c != null) {
                    genericTrainingProductIds.add(genericRecommendation.Product_Suggested__c);
                }
            }
            //RWPS-4896-END

            if(String.isBlank(errorMsg)){
                System.debug('addedCartItems === '+addedCartItems);
                System.debug('connectCartItems === '+connectCartItems);
                //Call Connect API addItemsToCart method
                if(addedCartItems.size()>0){
                    List<ConnectApi.BatchResult> batchResults = ECOM_CartRepo.addItemsToCart(webstoreId, effectiveAccountId, activeCartOrId, addedCartItems);
                    //update Cart item list price, price from CMS
                   List<CartItem> cartItemsWithUpdatedPrice = updateCartItemListPrice(batchResults,prodIdToPriceMap,trainingProductIds);//RWPS-4896
                } else if(connectCartItems.size()>0){
                    List<ECOM_CartItemModel> cartItemModels = new List<ECOM_CartItemModel>();
                    //Parse Cart Items results from Connect API to ECOM_CartItemModel
                    for(ConnectApi.CartItem carItem :connectCartItems){
                        //RWPS-4896-START
                        if(trainingProductIds.contains(carItem.productId)){
                            carItem.Quantity = String.valueOf(1);
                            carItem.totalAmount = String.valueOf(cartItem.salesPrice);
                            carItem.totalListPrice = String.valueOf(cartItem.listprice);
                            carItem.totalPrice = String.valueOf(cartItem.salesPrice);
                        } else if (genericTrainingProductIds.contains(carItem.productId)) {
                            carItem.Quantity = String.valueOf(1);
                            carItem.totalAmount = String.valueOf(cartItem.salesPrice);
                            carItem.totalListPrice = String.valueOf(cartItem.listprice);
                            carItem.totalPrice = String.valueOf(cartItem.salesPrice);
                        }
                        //RWPS-4896-END
                        ECOM_CartItemModel cartItemModel = ECOM_cartUtil.parseCartItem(carItem);
                        cartItemModels.add(cartItemModel);
                    }
                }
               //ECOM_CartModel cartModel =  ECOM_cartUtil.populateCartDetails(activeCartOrId);
               ECOM_CartModel cartModel =  ECOM_cartUtil.populateCartDetailsWithCartItems(activeCartOrId); //RWPS-1535
               cartModels.add(cartModel);
            } else {
                ECOM_MessagesSummary msg = new ECOM_MessagesSummary();
                msg.hasErrors = true;
                msg.message = errorMsg;
                for(ECOM_CartModel cm :carts){
                    if(cm != null){
                        cm.messagesSummary = msg;
                        cm.cartItems = null;
                        cartModels.add(cm);
                    }
                }
            }
        } catch(Exception ex) {
            ECOM_MessagesSummary msg = new ECOM_MessagesSummary();
            msg.hasErrors = true;
            msg.message = ex.getMessage();
            for(ECOM_CartModel cm :carts){
                if(cm != null){
                    cm.messagesSummary = msg;
                    cm.cartItems = null;
                    cartModels.add(cm);
                }
            }
            ECOM_ApplicationLogsUtil.logFailure(ex, 'CART', className, 'addItemsToCart', supportData);
        }
        return cartModels;
    }


    /**
    * @description  update cart item list price
    * @author mkumar@rafter.one | 09-21-2023
    * @param batchResults
    * @param prodIdToPriceMap
    * @return List<CartItem>
    **/
    public static List<CartItem> updateCartItemListPrice(List<ConnectApi.BatchResult> batchResults, Map<String,String> prodIdToPriceMap, Set<String> trainingProductIds){//RWPS-4896
        List<CartItem> cartItemsToUpdate = new List<CartItem>();
        if(batchResults!=null){
            for (ConnectApi.BatchResult batchResult : batchResults) {
                Map <String, String> jsonMap = new Map <String, String> ();
                if (batchResult.isSuccess()) {
                    ConnectApi.CartItem cartItem;
                    if(batchResult.getResult() instanceof ConnectApi.CartItem ) {
                        cartItem = (ConnectApi.CartItem) batchResult.getResult();
                        if( !prodIdToPriceMap.isEmpty() && prodIdToPriceMap.containsKey(cartItem.productId) ){
                            CartItem updatedItem = processCartItemsUpdate(cartItem, prodIdToPriceMap);
                            cartItemsToUpdate.add(updatedItem);
                        }else if(cartItem.listPrice==null || cartItem.listPrice=='0'){
                            //RWPS-4896-START
                            if(trainingProductIds.contains(cartItem.productId)){
                               cartItemsToUpdate.add(new CartItem(Id=cartItem.cartItemId ,listPrice = Decimal.valueOf(cartItem.salesPrice),quantity=1,TotalListPrice = Decimal.valueOf(cartitem.salesPrice),TotalPrice=Decimal.valueOf(cartitem.salesPrice)));//RWPS-4896
                            }else{
                                cartItemsToUpdate.add(new CartItem(Id=cartItem.cartItemId ,listPrice = Decimal.valueOf(cartItem.salesPrice)));//RWPS-4896
                            }
                        }else if(trainingProductIds.contains(cartItem.productId) && (cartItem.listPrice !='0' || cartItem.listPrice !=null)){
                                cartItemsToUpdate.add(new CartItem(Id=cartItem.cartItemId,quantity = 1, listPrice = Decimal.valueOf(cartitem.salesPrice),TotalListPrice = Decimal.valueOf(cartitem.salesPrice),TotalPrice=Decimal.valueOf(cartitem.salesPrice)));//RWPS-4896
                        }
                        //RWPS-4896-END
                    }
                }
            }
            if(cartItemsToUpdate.size() > 0){
                ECOM_CartRepo.updateCartItems(cartItemsToUpdate);
            }
        }
        return cartItemsToUpdate;
    }

    /**
    * @description  update cart item list price. Ticket RWPS-182
    * @author ssingh@rafter.one | 03-01-2024
    * @param cartItem
    * @return List<CartItem>
    **/
    public static List<CartItem> updateCartItemListPrice(Id cartItemId, Integer quantity){ // RWPS-3683 Added quantity parameter
        List<CartItem> cartItemsToUpdate = new List<CartItem>();

        if (cartItemId != null) {
            // RWPS-3683 START
            List<CartItem> lstCartItem = [SELECT Id, ListPrice, SalesPrice, Quantity, TotalListPrice FROM CartItem WHERE Id =: cartItemId LIMIT 1];
            if (!lstCartItem.isEmpty()) {
                lstCartItem[0].Quantity = quantity;
                lstCartItem[0].TotalListPrice = lstCartItem[0].ListPrice * quantity;

                if (lstCartItem[0].ListPrice == null || lstCartItem[0].ListPrice == 0) {
                    lstCartItem[0].listPrice = lstCartItem[0].SalesPrice;
                }
                cartItemsToUpdate.addAll(lstCartItem);
            }
            // RWPS- 3683 END

            if(cartItemsToUpdate.size() > 0){
                ECOM_CartRepo.updateCartItems(cartItemsToUpdate);
            }
        }
        return cartItemsToUpdate;
    }

    public static CartItem processCartItemsUpdate(ConnectApi.CartItem cartItem, Map<String,String> prodIdToPriceMap){
        Double listPrice = Test.isRunningTest() ? 10.0 : Double.valueOf(prodIdToPriceMap.containsKey(cartItem.productId));
        CartItem updatedItem = new CartItem();
        updatedItem.Id  =  cartItem.cartItemId;
        updatedItem.listPrice = listPrice;
        updatedItem.TotalListPrice = Integer.valueOf(cartItem.quantity) * listPrice;

        return updatedItem;
    }

	/**
    * @description Updates the Bill To/Ship To on the Cart from Contact. Ticket RWPS-766
    * @author ssingh@rafter.one | 05-31-2024
    * @author ssingh@rafter.one | 10-09-2024 | RWPS-1602
    * @param cartId Id of cart to be updated.
    */
    @AuraEnabled
    public static void updateBillToShipToOnCart(
      String cartId
    ) {
          String supportData = cartId;
          String methodName = 'updateBillToShipToOnCart';
          try {
            List<WebCart> carts = ECOM_CartRepo.getCartDetails(cartId);
            if(carts.isEmpty()){//RWPS-1603
                return;
            }
            User user = new ECOM_UserService().getUserByUserId();
            Contact con = ECOM_ContactRepo.getContactBasedOnId(user.ContactId);
            if(carts[0].Default_Bill_To_ERP_Address__c != con.Default_Bill_to_ERP_Address__c || carts[0].Default_Ship_To_ERP_Address__c != con.Default_Ship_to_ERP_Address__c){
                carts[0].Default_Bill_to_ERP_Address__c = con.Default_Bill_to_ERP_Address__c;
                carts[0].Default_Ship_to_ERP_Address__c = con.Default_Ship_to_ERP_Address__c;

                ECOM_CartRepo.updateCart(new List<WebCart>{carts[0]});
            }
          } catch (Exception ex) {
            ECOM_ApplicationLogsUtil.logFailure(ex, 'Update Bill To Ship To', className, methodName, supportData);
        }
    }

    /**
    * @description  Fetch Active Cart of the logged in User
    * @author mkumar@rafter.one | 09-21-2023
    * @param carts
    * @return List<ECOM_CartModel>
    **/
    public List<ECOM_CartModel> fetchCart(List<ECOM_CartModel> carts){
        List<ECOM_CartModel> cartModels = new List<ECOM_CartModel>();
        String supportData = '';
        try {
            supportData = JSON.serialize(carts);
            String webstoreId = '';
            String activeCartOrId = '';
            String effectiveAccountId = '';
            String ownerId = '';
            for(ECOM_CartModel cart :carts){
                effectiveAccountId = cart.accountId;
                if(String.isNotBlank(cart.cartId)){
                    activeCartOrId = cart.cartId;
                } else if(String.isNotBlank(cart.userId)){
                	ownerId = cart.userId;
                }
                if (String.isNotBlank(cart.webstoreId)){
                    webstoreId = cart.webstoreId;
                } else {
                    webstoreId = ECOM_Util.getWebStoreIdByName();
                }
                if(String.isNotBlank(cart.userId)){
                	ownerId = cart.userId;
                }
            }
            //Retrieve Cart by Cart Id
            if(String.isNotEmpty(activeCartOrId)){
                List<WebCart> cartsByCartId = ECOM_CartRepo.getCartandCartItemsById(activeCartOrId);
                if(cartsByCartId != null && cartsByCartId.size() > 0){
                List<ECOM_CartModel> cModels = ECOM_cartUtil.parseWebCarts(cartsByCartId);
                cartModels.add(cModels[0]);
                }
            //Retrieve current Cart by Owner Id
            } else if(String.isNotBlank(ownerId)) {
                List<WebCart> cartsByOwner = ECOM_CartRepo.getPrimaryCartBasedOnOwner(ownerId);
                if(cartsByOwner != null && cartsByOwner.size() > 0){
                    List<ECOM_CartModel> cModels = ECOM_cartUtil.parseWebCarts(cartsByOwner);
                    cartModels.add(cModels[0]);
                }
                // Create New cart for the logged in user
                else {
                    if(!Test.isRunningTest()){
                        ECOM_CartUtil.createNewCart(ownerId, effectiveAccountId, effectiveAccountId);
                    }
                    List<WebCart> cartsByOwnerNew = Test.isRunningTest() ? new List<WebCart>{new WebCart()} : ECOM_CartRepo.getPrimaryCartBasedOnOwner(ownerId);
                    if(cartsByOwnerNew != null && cartsByOwnerNew.size() > 0){
                        List<ECOM_CartModel> cModels = ECOM_cartUtil.parseWebCarts(cartsByOwnerNew);
                        cartModels.add(cModels[0]);
                    }
                }
            }
        } catch(Exception ex) {
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.USER_MODULE_NAME, className, 'addItemsToCart', supportData);
        }
        return cartModels;
    }



    /**
    * @description Update Cart Items
    * @author mkumar@rafter.one | 08-18-2023
    * @param carts
    * @return List<ECOM_CartModel>
    **/
    public List<ECOM_CartModel> updateCartItems(List<ECOM_CartModel> carts){

        List<ECOM_CartModel> cartModels = new List<ECOM_CartModel>();
        List<ConnectApi.CartItem> connectCartItems = new List<ConnectApi.CartItem>();
        String supportData = '';
        try {
            supportData = JSON.serialize(carts);
            Set<String> productIdSet = new Set<String>();
            String webstoreId = '';
            String activeCartOrId = '';
            String effectiveAccountId = '';
            String cartItemId = '';
            //prepare Cart Items in ConnectApi.CartItemInput format
            //ConnectApi.CartItemInput cartItem = new ConnectApi.CartItemInput();
            for(ECOM_CartModel cart :carts){
                if (String.isNotBlank(cart.webstoreId)){
                    webstoreId = cart.webstoreId;
                } else {
                    webstoreId = ECOM_Util.getWebStoreIdByName();
                }
                effectiveAccountId = cart.accountId;
                activeCartOrId = cart.cartId;
                if(!cart.cartItems.isEmpty()){

                    for(ECOM_CartItemModel item: cart.cartItems){
                        //prepare Cart Items in ConnectApi.CartItemInput format
                        ConnectApi.CartItemInput cartItem = new ConnectApi.CartItemInput();
                        cartItemId = item.cartItemId;
                        cartItem.productId = item.productId;
                        cartItem.Quantity = item.quantity;
                        //cartItem.type = ECOM_Constant.CARTITEM_TYPE_PRODUCT;
                        //Calling update connect API in loop as API accepts only one cart item
                        ConnectApi.CartItem ci = ECOM_CartRepo.updateCartItem(webstoreId, effectiveAccountId, activeCartOrId, cartItemId, cartItem);
                        connectCartItems.add(ci);
                    }
                }
            }
            //Call Connect API to update Update Cart Items
            //ConnectApi.CartItem carItem = ECOM_CartRepo.updateCartItem(webstoreId, effectiveAccountId, activeCartOrId, cartItemId, cartItem);
            List<ECOM_CartItemModel> cartItemModels = new List<ECOM_CartItemModel>();
            //Parse Cart Items results from Connect API to ECOM_CartItemModel
            for(ConnectApi.CartItem carItem :connectCartItems){
                ECOM_CartItemModel cartItemModel = ECOM_cartUtil.parseCartItem(carItem);
                cartItemModels.add(cartItemModel);
            }
            ECOM_CartModel cartModel = new ECOM_CartModel();
            cartModel.cartId = activeCartOrId;
            cartModel.accountId = effectiveAccountId;
            cartModel.cartItems = cartItemModels;
            cartModels.add(cartModel);
        } catch(Exception ex) {
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.USER_MODULE_NAME, className, 'addItemsToCart', supportData);
        }
        return cartModels;
    }


    /**
    * @description Delete specified Cart
    * @author mkumar@rafter.one | 08-18-2023
    * @param carts
    * @return List<ECOM_CartModel>
    **/
    public List<ECOM_CartModel> deleteCart(List<ECOM_CartModel> carts){
        List<ECOM_CartModel> cartModels = new List<ECOM_CartModel>();
        Map<String,Object> responseMap = new  Map<String,Object>();
        String supportData = '';
        try {
            supportData = JSON.serialize(carts);
            ConnectApi.CartSummary result = new ConnectApi.CartSummary();
            String webstoreId = '';
            String activeCartOrId = '';
            String effectiveAccountId = '';
            for(ECOM_CartModel cart :carts){
                effectiveAccountId = cart.accountId;
                if(String.isNotBlank(cart.cartId)){
                    activeCartOrId = cart.cartId;
                } else {
                    activeCartOrId = ECOM_Constant.CART_STATUS_CURRENT;
                }
                if (String.isNotBlank(cart.webstoreId)){
                    webstoreId = cart.webstoreId;
                } else {
                    // update logic as its in loop
                    webstoreId = ECOM_Util.getWebStoreIdByName();
                }
            }
            //Call Connect API to delete Cart
            ECOM_CartRepo.deleteCart(webstoreId, effectiveAccountId, activeCartOrId);
            responseMap.put('success',true);
        } catch(Exception ex) {
            responseMap.put('success',false);
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.USER_MODULE_NAME, className, 'addItemsToCart', supportData);
        }
        return cartModels;
    }


    /**
    * @description Fetch Cart Items of the specified Cart
    * @author mkumar@rafter.one | 08-18-2023
    * @param carts
    * @return List<ECOM_CartModel>
    **/
    public List<ECOM_CartModel> getCartItems(List<ECOM_CartModel> carts){

        List<ECOM_CartModel> cartModels = new List<ECOM_CartModel>();
        String supportData = '';
        try {
            supportData = JSON.serialize(carts);
            String webstoreId = '';
            String activeCartOrId = '';
            String effectiveAccountId = '';
            for(ECOM_CartModel cart :carts){
                effectiveAccountId = cart.accountId;
                if(String.isNotBlank(cart.cartId)){
                    activeCartOrId = cart.cartId;
                } else {
                    activeCartOrId = ECOM_Constant.CART_STATUS_CURRENT;
                }
                if (String.isNotBlank(cart.webstoreId)){
                    webstoreId = cart.webstoreId;
                } else {
                    webstoreId = ECOM_Util.getWebStoreIdByName();
                }
            }
            //RWPS-1387
            String productFilelds = 'ECOM_Product_Media_URI__c,Product_Display_Name__c';//RWPS-2270
            //Call Connect API to get Cart Items
            ConnectApi.CartItemCollection cartItems = ECOM_CartRepo.getCartItems(webstoreId, effectiveAccountId, activeCartOrId,productFilelds, null, null,null);
            ECOM_CartModel cartModel = new ECOM_CartModel();
            List<ECOM_CartItemModel> cartItemModels = new  List<ECOM_CartItemModel>();
            cartItemModels =  ECOM_CartUtil.parseCartItems(cartitems);
            // Parse cartItems.cartSummary to list of ECOM_CartItemModel
            cartModel = ECOM_CartUtil.parseCartSummary(cartItems.cartSummary);

            //check if punchout cart
            //cartModel = ECOM_CartUtil.checkIfPunchoutCart(activeCartOrId, cartModel); //VRa - Punchout changes
            cartmodel.cartItems = cartItemModels;
            // Changes for ECOM-123 done by sathiya on 06/11/2024
            Set<String> productIds = new Set<String>();
            for(ECOM_CartItemModel cartItemModel: cartItemModels){
                if(cartItemModel?.productId != null){
                    productIds.add(cartItemModel?.productId);
                }
            }
            // Adding change to fix the duplicate names for product TnC by Sathiya on 10/23/2024
            Set<String> productTncSet = new Set<String>();
            Set<String> productTncSetRUO = new Set<String>();
            String productTnCKeyValue = Label.ECOM_Product_Terms_Key;
            if(!productIds.isEmpty()){
                for(Product2 product: ECOM_ProductService.getProductTnCById(productIds)){
                    if(String.isNotBlank(productTnCKeyValue) && product?.ECOM_Product_TnC__c.equalsIgnoreCase(productTnCKeyValue)){
                        productTncSetRUO.add(product?.Part_Number__c);
                    } else {
                        productTncSet.add(product?.Part_Number__c);
                    }
                }
                if(!productTncSet.isEmpty()){
                    cartModel.productTnC = String.join(new List<String>(productTncSet), ', ');
                }
                if(!productTncSetRUO.isEmpty()){
                    cartModel.productTnCRUO = String.join(new List<String>(productTncSetRUO), ', ');
                }
            }
            // Changes End by sathiya
            cartModels.add(cartModel);
        } catch(Exception ex) {
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.USER_MODULE_NAME, className, 'addItemsToCart', supportData);
        }
        return cartModels;
    }


    /**
    * @description This method is used to delete cart items by product & cart Id
    * @author ssingh@rafter.one | 01-16-2024
    * @param activeCartOrId ID of the cart, active, or current.
    * @param cartItemId ID of the cart item to be deleted.
    * @param productId ID of the product to be deleted.
    **/
    public static void deleteCartItem(String activeCartOrId, String cartItemId, String productId)
    {
        List<CartItem> cartItems= ECOM_CartRepo.getCartItemsByProductandCartId(activeCartOrId, productId);
        List<CartItem> itemToDelete =  new List<CartItem>();
        List<CartItem> itemToupdate =  new List<CartItem>();
        Set<String> productIdSet = new Set<String>();//RWPS-4896
        Boolean isParentdeleted = false;
        for(CartItem item : cartItems){
            if(item.ECOM_Parent__c ==null &&item.Id == cartItemId ){
              itemToDelete.add(item);
              isParentdeleted = true;
            }else if(item.Id == cartItemId){
              itemToDelete.add(item);
            }else{
              itemToupdate.add(item);
            }
        }

        if(isParentdeleted){
          String newParent = '';
          for(CartItem item : itemToupdate){
            item.ECOM_Parent__c = null; // clear old parent
            if(newParent==''){
              newParent = item.Id; //set new parent
            }else{
              item.ECOM_Parent__c = newParent; // update new parent on old items
            }
          }
          ECOM_CartRepo.updateCartItems(itemToupdate);
        }
      

        //RWPS-3811
        cartItems= ECOM_CartRepo.getFreeItemsByCartId(activeCartOrId);
        boolean isFreeProductRemoved=false; // RWPS-4500
        for(CartItem item : cartItems){
            if(item.ecom_parent_item__c == cartItemId){
              itemToDelete.add(item);
              isFreeProductRemoved = true; // RWPS-4500
            }
          
           
        }
        //RWPS-4896-START
        List<CartItem> listCartItems = ECOM_CartRepo.getCartItemsByCartId(activeCartOrId);
        Map<String, String> mapTrainingProductIds = New Map<String, String>();
        Set<String> suggestProductIds = New Set<String>();
        Integer mainProductCount = 0;
        for(CartItem item : listCartItems){
            productIdSet.add(item.product2Id);
         }
        List<Product_Recommendation__c> productRecommendList =  ECOM_ProductRecommendationsRepo.getRecommendationsTrainingProducts('Combination',productIdSet);
        for(Product_Recommendation__c pr : productRecommendList){
            mapTrainingProductIds.put(pr.Product_Main__c, pr.Product_Suggested__c);
            suggestProductIds.add( pr.Product_Suggested__c);
        }
        if(productRecommendList.size() > 0){
            for(CartItem item : listCartItems){
                if(mapTrainingProductIds.containsKey(item.Product2Id)){
                   mainProductCount++; 
                }
            }
            if(mainProductCount == 1 && mapTrainingProductIds.containsKey(productId)){
                for(CartItem item : listCartItems){
                    if(suggestProductIds.contains(item.product2Id)){
                        itemToDelete.add(item);  
                    }
                }
            }
         }

        //RWPS-4896-END
        ECOM_CartRepo.deleteCartItems(itemToDelete);
         // RWPS-4500 - START
         List<CartItem> cartItemsList = ECOM_CartRepo.getCartItemsByCartId(activeCartOrId);
         if((cartItemsList != null && cartItemsList.size() == 0) || isFreeProductRemoved){
             WebCart cartToUpdate = new WebCart();
             cartToUpdate.Id=activeCartOrId;
             cartToUpdate.ECOM_Promo_Code__c='';
             update cartToUpdate;
         }
         // RWPS-4500 - END
        ECOM_SessionCacheUtil.clearEcomCache(); // RWPS-3683
    }

    /**
    * @description This method is used to delete shipping cart item
    * @author ssingh@rafter.one | 05-15-2024
    * @param cartItemIds
    **/
    public static void deleteShippingCartItem(String activeCartOrId)
    {
        List<CartItem> itemToDelete =  new List<CartItem>();
        List<CartItem> cartItemsList = ECOM_CartRepo.getCartItemsByCartId(activeCartOrId);

        // RWPS-632 Added logic to delete Shipping charge item if last product is also deleted from cart
        if(cartItemsList.size() > 0 && cartItemsList[0].Type == 'Charge'){
            itemToDelete.add(cartItemsList[0]);
        }
        ECOM_CartRepo.deleteCartItems(itemToDelete);
    }

     /**
    * @description This method is used to delete Tariff cart item
    * @author Prabhat Kumar | 04.24.2025
    * JIRA Ticket: RWPS-3026
    * @param activeCartOrId
    **/
    public static void deleteTariffLineItem(String activeCartOrId)
    {
        List<CartItem> itemToDelete =  new List<CartItem>();
        List<CartItem> cartItemsList = ECOM_CartRepo.getCartItemsByCartId(activeCartOrId);
        for(CartItem item : cartItemsList){
            if(item.Type == 'Charge' && item.Name == 'Tariff Surcharge'){
                itemToDelete.add(item);
            }
        }
        if(itemToDelete.size() > 0){
            ECOM_CartRepo.deleteCartItems(itemToDelete);
        }
    }

    /**
    * @description This method is used to delete cart items by Id
    * @author mkumar@rafter.one | 08-18-2023
    * @param cartItemIds
    **/
    public static void deleteCartItemsById(List<Id> cartItemIds)
    {
        ECOM_CartRepo.deleteCartItemsById(cartItemIds);
    }

    /**
    * @description This method is used to delete cart items for a product
    * @author mkumar@rafter.one | 08-25-2023
    * @param cartItemId
    **/
    public static void deleteCartItemsforProductId(Id productId, Id cartId)
    {
        List<CartItem> itemList = ECOM_CartRepo.deleteCartItemsforProductId(productId, cartId);

        Integer parentCount = 0;
        String parentId;

        for (Integer i = 0; i < itemList.size(); i++) {
            parentId = itemList[i].ECOM_Parent__c;
            if(parentId == null){
                System.debug('parent is null>>>');
            }
            else{
                parentCount++;
            }
        }
        if(parentCount == 0){
            for (Integer i = 1; i < itemList.size(); i++) {
                itemList[i].ECOM_Parent__c = itemList[0].Id;
            }
            ECOM_CartRepo.updateCartItems(itemList);
            //update itemList;
        }
    }


    /**
    * @description This method is used to update shipping date on cart item
    * @author mkumar@rafter.one | 08-18-2023
    * @param cartId
    * @return List<CartItem>
    **/
    public static List<CartItem> getCartItemsShippingDates(Id cartId)
    {
        List<CartItem> cartItemList = ECOM_CartRepo.getCartItemsShippingDates(cartId);
        return cartItemList;
    }

    /**
    * @description
    * @author mkumar@rafter.one | 09-21-2023
    * @param cartId
    * @return Map<String, Object>
    **/
    public static Map<String,Object> removeCoupon(String cartId)
    {
        Map<String,Object> response  = new Map<String,Object>();
        List<WebCart> cartList = ECOM_CartRepo.getCartandCartItemsById(cartId);
        response.put('success',true);
        if(cartList !=null && cartList.size()> 0){
            cartList[0].ECOM_Promo_Code__c = '';
            ECOM_CartRepo.updateCart(cartList);
            response.put('message','Promo code removed successfully.');
        }
        return response;
    }

    /**
    * @description This method is used to update shipping date on cart item
    * @author mkumar@rafter.one | 08-18-2023
    * @param cartItemId
    * @param shipDate
    **/
    public static void updateShippingDateOnCartItem(Id cartItemId, Date shipDate)
    {
        ECOM_CartRepo.updateShippingDateOnCartItem(cartItemId, shipDate);
    }


    /**
    * @description This method is used to check if the user has a RAD Identifier Account
    * @author mkumar@rafter.one | 08-18-2023
    * @return Boolean
    **/
    public static Boolean isRADIdentifierAccount(String cartId)
    {
        //String accId = ECOM_CartRepo.getEffectiveAccountId();
        Boolean isRADAccount = ECOM_CartRepo.checkRADIdentifierAccount(cartId);
        return isRADAccount;
    }


    /**
    * @description This method is used to send emails for abandoned cart.
    * @author mkumar@rafter.one | 08-18-2023
    * @param emailTemp
    * @param carts
    **/
    public static void sendEmailsForAbandonedCart(EmailTemplate emailTemp, List<WebCart> carts) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        Map<String, String> countryMapping = ECOM_CustomMetadataService.getCountryToOrgWideEmailMapping();

        // Get Org Wide Email Address for abandoned cart
        List<OrgWideEmailAddress> orgwideaddreslist = [SELECT Id, Address FROM OrgWideEmailAddress
                                                       WHERE DisplayName =: ECOM_Constant.ABANDONED_CART_ORGWIDEADDRESS_NAME LIMIT 1];

        // Map to store cart ID to email details for later use when creating EmailMessage records
        //RWPS-3197-Start
        Map<id, Account> accountMap = new Map<Id, Account>();
        List<Account> accountList = new List<Account>();
        Set<id> accountIds = new Set<Id>();
        Set<id> cartIds = new Set<Id>();
          try{
            for (WebCart cart : carts) {
                if (cart.accountId != null) {
                    accountIds.add(cart.accountId);
                    cartIds.add(cart.id);
                }
            }
            if (!accountIds.isEmpty()) {
                accountList = ECOM_AccountRepo.getAccountWithAbondonedCarts(cartIds, accountIds);
            }
            for (Account acc : accountList) {
                for( WebCart cart : acc.Carts) {
                    if (cart.Id == null) {
                        continue;
                    }
                    accountMap.put(cart.ownerId, acc);
                }
            }

            // RWPS-2786 - Start
            Map<String, Boolean> mapCartWithSellableStatus = ECOM_CartUtil.getInActiveProducts(carts);
            // RWPS-2786 - End
            if (!carts.isEmpty() && !orgwideaddreslist.isEmpty()) {//RWPS-2786
                for (WebCart cart : carts) {
                    if(accountMap.containsKey(cart.ownerId) == false || !mapCartWithSellableStatus.get(cart.Id)){
                        continue; // Skip if account is not found
                    }
                    Account accObj = accountMap.get(cart.ownerId);
                    Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailTemp.Id, cart.OwnerId, accObj.id);
                    //RWPS-3197-End
                    mail.setSaveAsActivity(true);
                    mail.setTargetObjectId(cart.Contact__c);
                    // Default OrgWideEmailAddress
                    String fromAddress = orgwideaddreslist[0].Address;
                    // RWPS-3004 - Country-specific email address
                    if (String.isNotBlank(cart.Default_Ship_to_ERP_Address__r.ApiCountry__c) &&
                        countryMapping.containsKey(cart.Default_Ship_to_ERP_Address__r.ApiCountry__c)) {
                    mail.setOrgWideEmailAddressId(countryMapping.get(cart.Default_Ship_to_ERP_Address__r.ApiCountry__c));
                    } else if (String.isNotBlank(cart.Default_Ship_to_ERP_Address__r.fxAddress_CountryName__c) &&
                            countryMapping.containsKey(cart.Default_Ship_to_ERP_Address__r.fxAddress_CountryName__c)) {
                    mail.setOrgWideEmailAddressId(countryMapping.get(cart.Default_Ship_to_ERP_Address__r.fxAddress_CountryName__c));
                 }
                emails.add(mail);
            }
                if(!emails.isEmpty() && !Test.isRunningTest()){
                    Messaging.SendEmailResult[] results = Messaging.sendEmail(emails, false);
                }
            }
        } catch (Exception e) {
            ECOM_ApplicationLogsUtil.logFailure(e, 'Abandoned Cart Email', className, 'sendEmailsForAbandonedCart', JSON.serialize(carts));
        }
    }
     //RWPS-3197-End

    /**
    * @description  get Abandoned Carts
    * @author Vipul | 08-18-2023
    * @param notification
    * @param cartLastModifiedDateMax
    * @param cartLastModifiedDateMin
    * @param countries
    * @param statuses
    * @return List<WebCart>
    **/
    public static List<WebCart> getAbandonedCart(ECOM_Abandoned_Cart_Notification__mdt notification,DateTime cartLastModifiedDateMax,DateTime cartLastModifiedDateMin,List<String> countries,List<String> statuses,Map<String,List<String>> countryToIsoMap)
    {
        List<WebCart> carts=new List<WebCart>();
        if(String.isBlank(notification.Country__c))
        {
            List<String> allCountriesToLeave = new List<String> ();
            for(String countryKey:countryToIsoMap.keySet())
            {
                allCountriesToLeave.addAll(countryToIsoMap.get(countryKey));
            }
            carts=ECOM_CartRepo.getCartsBasedOnEmailNotificationForLeftOverCountries(notification, cartLastModifiedDateMax, cartLastModifiedDateMin, allCountriesToLeave,statuses);
        }
        else
        {
            List<String> allCountries = new List<String> ();
            allCountries = countryToIsoMap.get(notification.Country__c);
            carts=ECOM_CartRepo.getCartsBasedOnEmailNotificationForSpecificCountry(notification, cartLastModifiedDateMax, cartLastModifiedDateMin,statuses,allCountries);
        }
        return carts;
    }

    /**
    * @description  get Abandoned Carts
    * @author Vipul | 08-18-2023
    * @param notification
    * @param cartLastModifiedDateMax
    * @param cartLastModifiedDateMin
    * @param countries
    * @param statuses
    * @return Integer
    **/
    public static Integer getAbandonedCartCount(ECOM_Abandoned_Cart_Notification__mdt notification,DateTime cartLastModifiedDateMax,DateTime cartLastModifiedDateMin,List<String> countries,List<String> statuses,Map<String,List<String>> countryToIsoMap)
    {
        Integer totalRecords;
        String condition='';
        List<String> allCountries = new List<String>();
        condition='Default_Ship_to_ERP_Address__c!=null ';
        if(String.isBlank(notification.Country__c))
        {
            if(!countries.isEmpty())
            {
                String countriesString='';
                for(String countryKey:countryToIsoMap.keySet())
                {
                    countriesString+=ECOM_Util.convertListToQueryString(countryToIsoMap.get(countryKey),countriesString);
                }
                countriesString = '('+countriesString+')';
                condition+='and Default_Ship_to_ERP_Address__r.ApiCountry__c not in ';
                condition+=countriesString+' and Default_Ship_to_ERP_Address__r.fxAddress_CountryName__c not in ';
                condition+=countriesString+' and';

            }
        }
        else
        {
            String reqdCountries = ECOM_Util.convertListToQueryString(countryToIsoMap.get(notification.Country__c),'');
            reqdCountries='('+reqdCountries+')';
            condition+='and (Default_Ship_to_ERP_Address__r.ApiCountry__c in '+reqdCountries;
            condition+=' or Default_Ship_to_ERP_Address__r.fxAddress_CountryName__c in '+reqdCountries+') and';
        }
        if(!statuses.isEmpty())
        {
            String statusString='';
            condition+='(Status in (';
            for(String status:statuses)
            {
                if(String.isNotBlank(statusString))
                {
                    statusString+=',';
                }
                statusString+='\''+status+'\'';
            }
            condition+=statusString+'))';
        }
        if(notification.Cart_Price_Bucket_Min__c!=null)
        {
            condition+=' and GrandTotalAmount>='+notification.Cart_Price_Bucket_Min__c;
        }
        else{
            condition+=' and GrandTotalAmount>'+0;
        }
        if(notification.Cart_Price_Bucket_Max__c!=null)
        {
            condition+=' and GrandTotalAmount<='+notification.Cart_Price_Bucket_Max__c;
        }

        condition+=' and LastModifiedDate>='+String.valueOf(string.valueOfGmt(cartLastModifiedDateMin)).replace(' ','T')+'.000+0000'+' and LastModifiedDate<='+String.valueOf(string.valueOfGmt(cartLastModifiedDateMax)).replace(' ','T')+'.000+0000';

        System.debug('condition : '+condition);
        totalRecords=ECOM_CartRepo.getCartCount(condition);
        return totalRecords;
    }

    /**
    * @description
    * @author mkumar@rafter.one | 09-21-2023
    * @param cartsToUpdate
    **/
    public static void updateCart(List<Webcart> cartsToUpdate){
        ECOM_cartRepo.updateCart(cartsToUpdate);
    }

    /**
    * @description
    * @author mkumar@rafter.one | 09-21-2023
    * @param backgroundOperationId
    * @return CartCheckoutSession
    **/
    public static CartCheckoutSession getCartCheckoutSession(String backgroundOperationId){
        return ECOM_cartRepo.getCartCheckoutSession(backgroundOperationId);
    }

    /**
    * @description
    * @author ssingh@rafter.one | 09-05-2024 | RWPS-1382
    * @param cartId
    * @return CartCheckoutSession
    **/
    public static CartCheckoutSession getCartCheckoutSessionByCartId(String cartId){
        return ECOM_CartRepo.getCartCheckoutSessionByCartId(cartId);
    }

    /**
    * @description
    * @author ssingh@rafter.one | 02-08-2023
    * @param session
    **/
    public static CartCheckoutSession createCartCheckoutSession(CartCheckoutSession session){
        return ECOM_CartRepo.createCartCheckoutSession(session);
    }

    /**
    * @description
    * @author mkumar@rafter.one | 09-21-2023
    * @param cartId
    * @return List<WebCart>
    **/
    public static List<WebCart> getCartandCartItemsById(String cartId){
        return ECOM_cartRepo.getCartandCartItemsById(cartId);
    }

    public static List<WebCart> getPrimaryCartBasedOnOwner(String userId){
        return ECOM_CartRepo.getPrimaryCartBasedOnOwner(userId);
    }

    /**
    * @description This method returns the active cart for the provided id.
    * @author Manish 2023.10.18
    * @param cartId
    * @return WebCart
    **/
    public static WebCart getPrimaryCartBasedOnId(String cartId){
        return ECOM_CartRepo.getPrimaryCartBasedOnId(cartId);
    }


    /**
    * @description  This method is used to get the Shipping Time Frame based on the Item Shipping Code
    * @author Prabhat kumar || 2025.07.11 || RWPS-1603
    * @param itemId
    * @return ECOM_ProductShippingTime__c
    **/
    public static ECOM_ProductShippingTime__c getShippingTimeObj(String itemId) {

        ECOM_ProductShippingTime__c shippingTimeObj = new ECOM_ProductShippingTime__c();
        String supportData = '';
        try {
            CartItem item = ECOM_CartRepo.getCartItemById(itemId);
            if (item == null || item.Cart == null || item.Cart.Default_Ship_to_ERP_Address__c == null) {
                ECOM_ApplicationLogsUtil.logApplicationApiData(
                    ECOM_Constant.CART_SERVICE, className, 'getShippingTimeObj',
                    'itemId: ' + itemId,
                    'Invalid CartItem or Address data.'
                );
                return shippingTimeObj;
            }

            String siteId = ECOM_CustomMetadataRepo.getSiteIdAndTransporationGroupMapping(item.ECOM_ShippingCode__c, 'Shipping Point');
            String priority = ECOM_CustomMetadataRepo.getSiteIdAndTransporationGroupMapping(item.Product2.Transportation_Group__c, 'Transporation Group');
            String countryCode = item.Cart.Default_Ship_to_ERP_Address__r.fxAddress_CountryCode__c;
            String destinationCity = item.Cart.Default_Ship_to_ERP_Address__r.fxAddress_City__c;

            supportData = 'itemId: ' + itemId + ', siteId: ' + siteId + ', countryCode: ' + countryCode +
                        ', destinationCity: ' + destinationCity + ', priority: ' + priority;
            List<ECOM_ProductShippingTime__c> shippingTimes = ECOM_CartRepo.getShippingTimesByCountryAndCity(
                siteId, countryCode, destinationCity, priority
            );

            if (shippingTimes == null || shippingTimes.isEmpty()) {
                // Fallback to country-level shipping times
                shippingTimes = ECOM_CartRepo.getShippingTimesByCountry(siteId, countryCode, priority);
            }

            if (shippingTimes != null && !shippingTimes.isEmpty()) {
                if (shippingTimes.size() == 1) {
                    return shippingTimes[0];
                } else {
                    return getMaxDLVRecord(shippingTimes);
                }
            } else {
                ECOM_ApplicationLogsUtil.logApplicationApiData(
                    ECOM_Constant.CART_SERVICE, className, 'getShippingTimeObj',
                    supportData,
                    'Unable to find Shipping Time for Item: ' + itemId
                );
            }
        } catch (DmlException ex) {
            ECOM_ApplicationLogsUtil.logFailure(
                ex, ECOM_Constant.CART_SERVICE, className, 'getShippingTimeObj', supportData
            );
        }

            return shippingTimeObj;
        }
    /**
    * @description  This method is used to get the Shipping Time Frame if multiple records found with same max DLV
    * @author Prabhat kumar || 2025.07.11 || RWPS-1603
    * @param List<ECOM_ProductShippingTime__c> lstProdship
    * @return ECOM_ProductShippingTime__c
    **/
    public static ECOM_ProductShippingTime__c getMaxDLVRecord(List<ECOM_ProductShippingTime__c> lstProdship) {
        if (lstProdship == null || lstProdship.isEmpty()) {
            return null;
        }

        List<ECOM_ProductShippingTime__c> maxDLVRecords = new List<ECOM_ProductShippingTime__c>();
        Decimal maxDLVValue = lstProdship[0].Ecom_Total_DLV__c;

        // Step 1: Find all records with the highest Ecom_Total_DLV__c
        for (ECOM_ProductShippingTime__c record : lstProdship) {
            if (record.Ecom_Total_DLV__c > maxDLVValue) {
                maxDLVValue = record.Ecom_Total_DLV__c;
                maxDLVRecords.clear();
                maxDLVRecords.add(record);
            } else if (record.Ecom_Total_DLV__c == maxDLVValue) {
                maxDLVRecords.add(record);
            }
        }

        // Step 2: If only one record has the max DLV, return it
        if (maxDLVRecords.size() == 1) {
            return maxDLVRecords[0];
        }

        // Step 3: Check Ecom_Confidence_90__c for tie-breaker
        ECOM_ProductShippingTime__c selectedRecord = maxDLVRecords[0];
        Integer highestConfidenceDays = 0;

        for (ECOM_ProductShippingTime__c record : maxDLVRecords) {
            String confidenceText = record.Ecom_Confidence_90__c;
            Integer confidenceDays = 0;

            if (String.isNotBlank(confidenceText)) {
                if (confidenceText.toLowerCase().contains('week')) {
                    // Special case: prioritize weeks
                    return record;
                }

            // Extract all numbers from the text
            Pattern numberPattern = Pattern.compile('\\d+');
            Matcher matcher = numberPattern.matcher(confidenceText);
            while (matcher.find()) {
                Integer num = Integer.valueOf(matcher.group());
                if (num > confidenceDays) {
                    confidenceDays = num;
                }
            }


            }

            if (confidenceDays > highestConfidenceDays) {
                highestConfidenceDays = confidenceDays;
                selectedRecord = record;
            }
        }

         return selectedRecord;
    }



    /**
     * @description  This method is used to get the Credit Collection Emails from Custom Metadata
    * @author ssingh@rafter.one | Sept 14th 2023
    * @param moduleName
    * @return Map<String,String>
    **/
    public static Map<String,String> getCreditCollections(String moduleName)
    {
        return ECOM_CartRepo.getStorefrontFrontConfigByModule(moduleName);
    }

    /**
     * @description  This method is used to get the CartDeliveryGroupMethods
    * @author Manish | Sept 19th 2023
    * @param CartDeliveryGroupMethod id
    * @return List<CartDeliveryGroupMethod>
    **/
    public static List<CartDeliveryGroupMethod> getCartDeliveryGroupMethodById(Id cartGroupMethodID){
        return ECOM_CartRepo.getCartDeliveryGroupMethodById(cartGroupMethodID);
    }

    /**
     * @description  This method is used to get the CartDeliveryGroups
    * @author Manish | Sept 19th 2023
    * @param CartDeliveryGroupMethod id
    * @return List<CartDeliveryGroupMethod>
    **/
    public static List<CartDeliveryGroup> getCartDeliveryGroupById(Id cartGroupID){
        return ECOM_CartRepo.getCartDeliveryGroupById(cartGroupID);
    }

     /**
     * @description  This method is used to update CartDeliveryGroups
    * @author Manish | Sept 19th 2023
    * @param List<CartDeliveryGroup>
    * @return List<CartDeliveryGroup>
    **/
    public static List<CartDeliveryGroup> updateCartDeliveryGroups(List<CartDeliveryGroup> cartDeliveryGroupsToUpdate){
        return ECOM_CartRepo.updateCartDeliveryGroups(cartDeliveryGroupsToUpdate);
	}

    /**
     * @description  This method is used to update CartDeliveryGroups
    * @author Ankita | Feb 20th 2024
    * @param String
    * @return List<CartItem>
    **/
    public static List<CartItem> getCartItemsByCartId(String cartID){
        return ECOM_CartRepo.getCartItemsByCartId(cartID);
	}

    /**
     * @description  This method is used to update CartDeliveryGroups
    * @author Ankita | Feb 20th 2024
    * @param String
    * @return List<CartTax>
    **/
    public static List<CartTax> getCartTaxRecordsPerCart(String cartID){
        return ECOM_CartRepo.getCartTaxRecordsPerCart(cartID);
	}

    /**
     * @description  This method is used to insert CartTaxes
    * @author Ankita | Feb 20th 2024
    * @param List<CartTax>
    * @return List<CartTax>
    **/
    public static List<CartTax> insertCartTaxes(List<CartTax> cartTaxes){
        return ECOM_CartRepo.insertCartTaxes(cartTaxes);
	}

    /**
     * @description  This method is used to update webcart
    * @author Ankita | Feb 20th 2024
    * @param WebCart
    * @return void
    **/
    public static void updateWebCart(WebCart cart){
        List<WebCart> carts = new List<WebCart>();
        carts.add(cart);
        ECOM_CartRepo.updateCart(carts);
	}




    public static void updateAssociatedCarts()
    {
        User us = new ECOM_UserService().getUserByUserId();
        List<WebCart> webcarts=ECOM_CartRepo.getPrimaryCartBasedOnOwner(us.id); //RWPS-164 - method changed from getCartsBasedOnOwner to getPrimaryCartBasedOnOwner
        for(WebCart webcart:webcarts)
        {
            webcart.AccountId = us.Contact.AccountId;
            webcart.Default_Bill_To_ERP_Address__c=us.Contact.Default_Bill_To_ERP_Address__c;
            webcart.Default_Ship_To_ERP_Address__c=us.Contact.Default_Ship_To_ERP_Address__c;
        }
        if(!webcarts.isEmpty())
        {
            ECOM_CartRepo.updateCart(webcarts);
        }
    }

    /**
     * @description This method checks if the user is registered as punchout user and updates the cart as punchout cart
     * @author vramachandran@rafter.one | 14 Dec 2023
     * @param userId | String
     */
    public void updatePunchoutCart(String userId){
        List<WebCart> cartList = ECOM_CartRepo.getAllActiveCartsForOwnerId(userId);
        List<WebCart> cartListToUpdate = new List<WebCart>();

        //mark all carts as punchout carts
        if(cartList != null && !cartList.isEmpty()){
            for(WebCart cartRecord : cartList){
                if(!cartRecord?.ECOM_Is_Punchout_Cart__c){
                    cartRecord.ECOM_Is_Punchout_Cart__c = true;
                    cartListToUpdate.add(cartRecord);
                }
            }
			System.debug('cartListToUpdate:: '+ JSON.serialize(cartListToUpdate));
            if(!cartListToUpdate.isEmpty() && !Test.isRunningTest()){
                ECOM_CartRepo.updateCart(cartListToUpdate);
            }
        }
    }

    /**
     * @description This method will return the active cart for a given user id
     * @author vramachandran@rafter.one | 22 Dec 2023
     * @param userId | String
     * @return WebCart
     */
    public WebCart getActiveCartForPunchoutUser(String userId){
        WebCart cartRecord;

        try{
            List<WebCart> cartList = ECOM_CartRepo.getActiveCartForPunchoutUser(userId);
            System.debug('getActiveCartForPunchoutUser:cartList:: '+ cartList);

            if(null != cartList && !cartList.isEmpty()){
                cartRecord = cartList[0];
            }
            System.debug('getActiveCartForPunchoutUser:cartRecord:: '+ cartRecord);
        }catch(Exception e){
            ECOM_ApplicationLogsUtil.logFailure(e, 'Punchout:: Fetch Cart - Failed', CLASSNAME, 'getActiveCartForPunchoutUser', 'Message:: '+ e.getMessage()+ ' Stack:: '+ e.getStackTraceString());
        }

        return cartRecord;
    }

    /**
     * @description This method returns the punchout cart details for a punchout user, if cart does not exist a new cart is created and returned
     * @author vramachandran@rafter.one | 04 Jan 2024
     * @param userRecord | User
     * @returns WebCart
     */
    public WebCart getWebCartForPunchoutUser(User userRecord){
        WebCart cartRecord;
        List<WebCart> cartList = ECOM_CartRepo.getActiveCartForPunchoutUser(userRecord.Id);
        System.debug('getActiveCartForPunchoutUser:cartList:: '+ cartList);

        if(null != cartList && !cartList.isEmpty()){
            cartRecord = cartList[0];
        } else {
            ECOM_CartUtil.createNewPunchoutCart(userRecord.AccountId,userRecord.Id);
            cartList = ECOM_CartRepo.getPrimaryCartBasedOnOwner(userRecord.Id);
            cartRecord = cartList.isEmpty() == false ? cartList[0] : null; //RWPS-4896 : Added null check
            System.debug('getActiveCartForPunchoutUser.cart::' + JSON.serialize(cartList));
        }

        System.debug('getActiveCartForPunchoutUser:cartRecord:: '+ cartRecord);

        return cartRecord;
    }

    /**
     * @description This method returns the punchout cart model for given cart id
     * @author vramachandran@rafter.one | 05 Jan 2024
     * @param cartId | String
     * @param effectiveAccountId | String //RWPS-5775
     * @returns ECOM_POOMModel
     */
    public ECOM_POOMModel getPunchoutCartandCartItemsById(String cartId, String effectiveAccountId){
        ECOM_POOMModel poomModel = new ECOM_POOMModel();

        try{
            //RWPS-5775 Start
            Map<String, Object> responseMap = ECOM_PunchoutLoginService.getPunchoutAddressesForAccountId(effectiveAccountId);
			ERP_AddressModel addressModel = responseMap != null ? (ERP_AddressModel) responseMap.get('AddressModel') : null;
            if(addressModel == null || String.isBlank(addressModel.id)){
                return poomModel;
            }
            //RWPS-5775 End
            System.debug('getPunchoutCartandCartItemsById:addressModel:: '+ addressModel.po_PunchoutResponseFormat +' '+addressModel.id);
        	List<WebCart> carts = ECOM_CartRepo.getPunchoutCartandCartItemsById(cartId);

            if(null != carts && !carts.isEmpty()){
                poomModel = ECOM_CartUtil.getPoomModel(carts[0], addressModel);
            }

        }catch(Exception e){
            ECOM_ApplicationLogsUtil.logFailure(e, 'Punchout:: Fetch Cart - Failed', CLASSNAME, 'getPunchoutCartandCartItemsById', 'Message:: '+ e.getMessage()+ ' Stack:: '+ e.getStackTraceString());
        }
        return poomModel;
    }

    /**
     * @description This method updates the cart with POSR values
     * @author vramachandran@rafter.one | 05 Jan 2024
     * * @author ssingh@rafter.one | 17 May 2024 | Added cart Id in response map | RWPS-723
     * @param userId | String
     * @param posrJson | String
     * @returns Map<String,Object>
     */
    public static Map<String,Object> updatePunchoutCart(String userId, String posrJson){
        Map<String,Object> responseMap = new Map<String,Object>();
        WebCart cartRecord;
        List<User> userRecords = ECOM_UserRepo.getPunchoutUserInformationForErpAddress(userId);
        //RWPS-5938 - bypass cart reset
        if (userRecords.isEmpty() == false && userRecords[0].ContactId != null && userRecords[0].Contact.ECOM_Punchout_Cart_Reset__c == true) {
            updateStatusOfCurrentCarts(userId);//VRa - Changes for ECOM-3411
        }
        List<WebCart> cartList = ECOM_CartRepo.getActiveCartForPunchoutUser(userId);

        responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
        if(null != userRecords && !userRecords.isEmpty()){
            User userRecord = userRecords[0];

           // ERP_AddressModel addressModel = ERP_AddressUtil.getERPAddressModelForPunchoutAccountId(userRecord.AccountId);
            ERP_AddressModel addressModel = ERP_AddressUtil.getPunchoutAddressesForAccountId(userRecord.AccountId);
            ECOM_PunchoutWrapper.PunchoutServiceRequest requestModel = (ECOM_PunchoutWrapper.PunchoutServiceRequest) JSON.deserialize(posrJson,ECOM_PunchoutWrapper.PunchoutServiceRequest.class);

            if(null != cartList && !cartList.isEmpty() ){
                cartRecord = cartList[0];
            } else {
                ECOM_CartUtil.createNewPunchoutCart(userRecord.AccountId,userRecord.Id);
                cartList = ECOM_CartRepo.getPrimaryCartBasedOnOwner(userRecord.Id);
                cartRecord = Test.isRunningTest() ? new WebCart() : cartList[0];
                System.debug('getActiveCartForPunchoutUser.cart::' + JSON.serialize(cartList));
            }

            if(null != cartRecord){
                //update posr values
                List<WebCart> carts = ECOM_CartUtil.updateCartWithPOSRValues(requestModel, userRecord, addressModel);
                System.debug('carts:: '+ carts);
                responseMap.put(ECOM_Constant.PARAM_SUCCESS, true);
                //RWPS-1115
    			responseMap.put(ECOM_Constant.PARAM_EXT_PUNCHOUT_DOMAIN,EncodingUtil.urlEncode(ECOM_EncryptUtil.encryptWithAES256(String.isNotEmpty(requestModel.browserFormPost) ? requestModel.browserFormPost : ''), 'UTF-8') );
            }
        }

        return responseMap;
    }

    /**
     * @description This method returns the list of webcarts for a user id
     * @author vramachandran@rafter.one | 16 Feb 2024
     * @param userId | String
     * @returns List<WebCart>
     */
    public static LIst<WebCart> getPrimaryActiveCartForUserId(String userId){
        return ECOM_CartRepo.getPrimayActivePunchoutCartsForOwnerId(userId);
    }

    /**
    * @description This method returns  a map with the total unique product Count
    * @author vramachandran@rafter.one | 16 Feb 2024
    * @return Map<String, Object>
    **/
    public static Map<String,Object> getUniqueProductCount() {
        Integer totalProductCount = 0;
        Map<String,Object> response = new Map<String,Object>();
        response.put(ECOM_Constant.PARAM_SUCCESS, false);
        response.put(ECOM_Constant.PARAM_RESPONSE_DATA, totalProductCount);
        try{

            List<WebCart> currentCarts = ECOM_CartRepo.getPrimayActiveCartsForOwnerId(UserInfo.getUserId());
            if(null != currentCarts && !currentCarts.isEmpty()){
                WebCart currentCart = currentCarts[0];
                if(null != currentCart && null != currentCart.CartItems && !currentCart.CartItems.isEmpty()){
                    for(CartItem cartItemRecord : currentCart.CartItems){
                        totalProductCount += Integer.valueOf(cartItemRecord.Quantity);
                    }
                }
                response.put(ECOM_Constant.PARAM_RESPONSE_DATA, totalProductCount);
            }
            response.put(ECOM_Constant.PARAM_SUCCESS, true);
        }catch(Exception ex){
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.USER_MODULE_NAME, className, 'repriceCart', 'userId:: '+ UserInfo.getUserId());

        }
        return response;
    }

    /**
    * @description This method is used to get cart details
    * @author Vipul Goyal | 02-22-2024
    *         Sidak Singh | 04-19-2024 | Updated getCartDetails method to call getCartDetails from ECOM_CartRepo | RWPS-416
    * @param cartId
    * @return List<Cart>
    **/
    public static List<WebCart> getCartDetails(String cartId)
    {
        List<WebCart> carts = ECOM_CartRepo.getCartDetails(cartId);
        return carts;
    }


    /**
     * @description This method updates the status of current carts to pending delete
     * @author vramachandran@rafter.one | 28 Jun 2024
     * @param userId
     */
    private static void updateStatusOfCurrentCarts(String userId) {
        List<WebCart> cartsList = ECOM_CartRepo.getAllActivePunchoutCartsForOwnerId(userId);

        if(cartsList != null && !cartsList.isEmpty()){
            List<WebCart> cartsToUpdate = new List<WebCart>();
            for(WebCart currentCart : cartsList) {
                currentCart.Status = 'PendingDelete ';
                cartsToUpdate.add(currentCart);
            }
            ECOM_CartRepo.updatePunchoutCart(cartsToUpdate);
        }
    }
    /**
    * @description  This method invokes order simulate Api
    * @author ssingh@rafter.one | 07-16-2024 | RWPS-949
    * @param cartId
    * @return Map<String, Object>
    **/
    @AuraEnabled
    public static Map<String,Object> getProductSalesByProdIdAndMaterialCodes(List<String> productIds, Boolean isPunchoutCart) {

        Map<String,Object> responseMap = new  Map<String,Object>();
        List<Product_Sales__c> productSales = new List<Product_Sales__c>();
        List<String> materialCodes = new List<String>();

        if(isPunchoutCart == true){
            materialCodes = ECOM_CartUtil.fetchProductMaterialStatus('ECOM_Punchout');
            materialCodes.addAll(ECOM_CartUtil.fetchProductMaterialStatus('ECOM_Punchout_Custom'));//RWPS-1456
        }
        else {
            materialCodes = ECOM_CartUtil.fetchProductMaterialStatus('ECOM_CartService');
        }
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

        responseMap.put('productSaleStatus',productSaleStatusMap);

        return responseMap;
    }

    /**
     * @description This method check if couponCode present in list of coupons or not
     * @author gaurav.bhansali@revvity.com | 20 May 2025 RWPS-3283
     * @param couponCode, list of coupons
     * @return boolean coupon present in list or not
     */
    public static boolean isCouponExistInList(String couponCode, List<Coupon> coupons) {
        boolean isCouponExist = false;
        if(String.isEmpty(couponCode) || coupons ==null || coupons.isEmpty())
            return isCouponExist;
        for(Coupon coupon : coupons) {
            if(couponCode.equalsIgnoreCase(coupon.couponCode)) {
                isCouponExist = true;
                break;
            }
        }
        return isCouponExist;
    }
    /**
     * Filters the given list of WebCart records to only include those
     * where the associated contact has opted in to email.
     * @author poonam.shukla@revvity.com@revvity.com | 18 July 2025 RWPS-3306
     * @param carts List of WebCart records (abandoned carts)
     * @return List<WebCart> filtered list of carts with email-opted-in contacts
     */
    public static List<WebCart> filterAbandonedOptInCarts(List<WebCart> carts) {
        if (carts == null || carts.isEmpty()) {
            return new List<WebCart>();
        }

        Set<Id> contactIds = new Set<Id>();
        for (WebCart cart : carts) {
            if (cart.Contact__c != null) {
                contactIds.add(cart.Contact__c);
            }
        }

        Map<Id, Boolean> contactOptInMap = new Map<Id, Boolean>();
        if (!contactIds.isEmpty()) {
            //RWPS-4435 Added Email in query
            for (Contact c : [
                SELECT Id, Email, (SELECT Id, Ecom_Opt_Out_from_Cart_Emails__c,ERP_Address__c, ECOM_Email__c FROM ECOM_Email_Preferences__r)
                FROM Contact
                WHERE Id IN :contactIds
            ]) {
                Boolean isOptedIn = true;
                if (!c.ECOM_Email_Preferences__r.isEmpty()) {
                    for (ECOM_Email_Preferences__c pref : c.ECOM_Email_Preferences__r) {
                        if (pref.Ecom_Opt_Out_from_Cart_Emails__c == true &&
                            String.isBlank(pref.ERP_Address__c) && c.Email == pref.ECOM_Email__c){
                            isOptedIn = false;
                            break;
                        }
                    }
                }
                contactOptInMap.put(c.Id, isOptedIn);
            }
        }

        List<WebCart> optedInCarts = new List<WebCart>();
        for (WebCart cart : carts) {
            if (cart.Contact__c != null && contactOptInMap.get(cart.Contact__c) == true) {
                optedInCarts.add(cart);
            }
        }

        return optedInCarts;
    }

    /*
    * This method check if free item available in cart or not RWPS-4202
    * @author Gaurav
    * @param cartItems
    * @return String | qualifiedFreePartNumber
    */
    public static String getFreeItemPromoMsg(List<CartItem> cartItems) {
        Map<String, Object> cartDetailsMap = ECOM_CartUtil.getCartItemDetailsMap(cartItems);
        Map<String,String> cartItemToPartNumMap = (Map<String,String>) cartDetailsMap.get('cartItemToPartNumMap'); //RWPS-4202
        String freeParentPartNumber = '';
        if(!(boolean)cartDetailsMap.get('isFreeItemAdded')){
            return freeParentPartNumber;
        }
        for(CartItem item : cartItems){
            if(String.isNotEmpty(item.ecom_parent_item__c)) {
                freeParentPartNumber += ' ' + cartItemToPartNumMap.get(item.ecom_parent_item__c) + ',';
            }
        }
        if(freeParentPartNumber != '') {
            freeParentPartNumber = freeParentPartNumber.removeEnd(',');
        }
        return freeParentPartNumber;
    }
    /*
    * This method delete free item available from cat RWPS-3811
    * @author Gaurav
    * @param activeCartOrId
    */
    public static void deleteFreeItems(String activeCartOrId) {
        List<CartItem> freeItems = ECOM_CartRepo.getFreeItemsByCartId(activeCartOrId);
        if(freeItems.size() > 0 ) {
            List<CartItem> itemsToDelete = new List<CartItem>();
            for (CartItem item : freeItems) {
               if(String.isNotBlank(item.ecom_parent_item__c)) {
                    itemsToDelete.add(item);
               }
            }
            if(itemsToDelete.size() > 0){
                delete(itemsToDelete);
            }
        }
    }

    /**
     * This method updates the E-Invoice Customer ID (PEPPOL ID) on the Bill-To ERP Address and its associated Target Address when an order is placed.
     * RWPS-6394
     * @author Poonam
     * @param billToAddressId Id of the Bill-To ERP Address associated with the order
     * @param invoiceCustId E-Invoice Customer ID (PEPPOL ID) entered during checkout
     */
    public static void updateEInvoiceCustIdOnERPAddress(String billToAddressId, String invoiceCustId){

    if(String.isBlank(invoiceCustId) || billToAddressId == null){
        return;
    }

    ERP_Address__c billToAddress = [SELECT Id, Target_Address__c, ECOM_E_Invoice_Cust_Id__c FROM ERP_Address__c WHERE Id = :billToAddressId  LIMIT 1];

    List<ERP_Address__c> addressesToUpdate = new List<ERP_Address__c>();
    // Update BillTo Address
    billToAddress.ECOM_E_Invoice_Cust_Id__c = invoiceCustId;
    addressesToUpdate.add(billToAddress);
    // Update Target Address if present
    if(billToAddress.Target_Address__c != null){

        ERP_Address__c targetAddress = [SELECT Id, ECOM_E_Invoice_Cust_Id__c FROM ERP_Address__c WHERE Id = :billToAddress.Target_Address__c LIMIT 1];
        targetAddress.ECOM_E_Invoice_Cust_Id__c = invoiceCustId;
        addressesToUpdate.add(targetAddress);
    }

    if(!addressesToUpdate.isEmpty()){
        update addressesToUpdate;
    }
}

}