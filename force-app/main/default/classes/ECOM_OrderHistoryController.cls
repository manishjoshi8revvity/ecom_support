/**************************************************************
 * 1. Jira Ticket(s) that relates to this class
 *    ECOM-109
 *
 * 2. Description - This class is used to fetch Order Summary/Order Items/SAP Order Summary details.
 *
 * 3. Objects referenced
 *    - OrderSummary
 *	 - SAP_Order_Summary__c
 *    - ECOM_ProductService
 *
 * 4. Callouts to additional Components (including their methods) or None:
 *    - None
 *
 * 5. Dependant Class(es):
 * 	 - ECOM_OrderService
 *    - ECOM_SAPOrderSummaryService
 *
 * 6. Test Class Name:
 *    - ECOM_OrderHistoryController_Test
 *
 * 7. Is @Invocable (Yes or No): No
 *
 * 8. Author Name(s):
 *    - Vickal
 *    - Sidak
 *	   - vramachandran@rafter.one | 12 Dec 2023
 *	   - Sathiya 2024.04.29 - Adding validation config for ECOM-1933 and ECOM -1942
 *    - Gaurang 2024.05.02 - mapping to rollup field to get total quantity on order - ECOM - 3150
 *    - Gaurang 2024.05.12 - mapping of companyName to respective fields - ECOM-112
 *    - Gaurang 2024.06.04 - mapping sales org field - ECOM-1931
 *    - Sidak 2024.06.20 Updated logic to pass contact email list in findSapOrderByOrderNumberAndZip and getAllMySapOrders methods. Ticket - RWPS-313
 *    - Poonam 2025.04.24 - mapping totalTariffSurcharge,tariffSurcharge field - RWPS-3026
 *    - Gaurav 2025.07.25 - Updated getAllMySapOrders to get order based on email RWPS-3741
 *    - Chirag 2025.09.01 - Added Method checkIfCurrentUserIsPunchoutUser to check if the logged in user is punchout user or not - RWPS-4196
 *    - Prabhat 2025.09.23  Updated method getAllMySapOrders to include email type in the parameter - RWPS-4131
 *    - Poonam 2025.09.29  Updated method getAllMySapOrders to include Additional Email for contact - RWPS-4082
 *    - Manish Joshi 2025.09.30 Added method getOrderDetailsAndReplacement - RWPS-4602
 *    - Sachin Vispute 2025.09.30 - Added method fetchProductUnavailability - RWPS-4621
 *    - Poonam 2025.10.07 Updated method getAllMySapOrders to send Contact email in parameter for method fetchSAPOrdersByEmail - RWPS-4443
 *    - Sachin Vispute 2025.10.28 - Created methods getOnlineOrders, getOfflineOrders, getEncodedValues - RWPS-4881
 *    - Sachin Vispute 2025.11.05 - Modified methods getOnlineOrders, getOfflineOrders, created fetchSalesOrg - RWPS-4881
 *    - Sachin Vispute 2025.11.11 - Modified method createOrderModel - RWPS-5149
 *    - Sachin Vispute 2025.11.14 - Modified method getOrderDetails - RWPS-5230
 *    - Sachin Vispute 2025.11.20 - Modified method createOrderModel - RWPS-5181
 *    - Sachin Vispute 2025.11.05 - Modified methods getOnlineOrders, getOfflineOrders - RWPS-5094
 *    - Sachin Vispute 2025.11.27 - Modified methods createOrderModel - RWPS-5180
 *    - Prabhat Kumar 2025.12.03 -  Updated method createOrderModel- RWPS-4896
 *    - Sachin Vispute 2025.12.16 -  Updated method createOrderModel- RWPS-5180
 *    - Poonam Shukla 2026.02.19 -  Updated method getAllMySapOrders and getOfflineOrders- RWPS-5777
 *    - Poonam Shukla 2026.03.30 - Updated method createOrderModel RWPS-6880
 *************************************************************/
public with sharing class ECOM_OrderHistoryController {

    @AuraEnabled(cacheable=true)
    public static List<Order> getMyOrders() {
        List<Order> orders = ECOM_OrderService.getMyOrders();
        return orders;
    }

    /**
     * RWPS-4881
     * @description This method returns the online order details for a user
     * @author Sachin V | 2025-10-28
     * @param searchString | String
     * @return Map<String, Object>
     */
    @AuraEnabled
    public static Map<String,Object> getOnlineOrders(String searchString) {
        Map<String,Object> responseMap = new  Map<String,Object>();
        //RWPS-5094
        Id userId = UserInfo.getUserId();
        User user = ECOM_UserRepo.getUserByUserId(String.valueOf(userId));
        Boolean isPunchoutUser = ECOM_OrderHistoryController.checkIfCurrentUserIsPunchoutUser();
        List<String> orderTypesList = new List<String>();
        List<String> poTypesList = new List<String>();
        if (isPunchoutUser == true) {
            List<C_META_Storefront_Configuration__mdt> storeFrontConfigurations = ECOM_CustomMetadataRepo.fetchStoreConfigMdtBasedOnModuleName('POTypesPunchout');
            storeFrontConfigurations.add(ECOM_CustomMetadataRepo.fetchStoreConfigMdtBasedOnModuleName('PunchoutOnlineOrderTypes')[0]);
            poTypesList = storeFrontConfigurations[0].Value__c.split(',');
            orderTypesList = storeFrontConfigurations[1].Value__c.split(',');
        } else {
            List<C_META_Storefront_Configuration__mdt> storeFrontConfigurations = ECOM_CustomMetadataRepo.fetchStoreConfigMdtBasedOnModuleName('POTypesWeb');
            poTypesList = storeFrontConfigurations[0].Value__c.split(',');
        }
        List<Order> orders = ECOM_OrderService.getOnlineOrders(searchString, user, isPunchoutUser, orderTypesList, poTypesList);
        //RWPS-5094
        responseMap.put('onlineOrders' , orders);

        Map<String,Object> sapOrders = getOfflineOrders(searchString, true);
        responseMap.put('addOnOrders' , sapOrders.get('orders'));
        responseMap.put('orderModel', sapOrders.get('orderModel'));
        responseMap.put('partNoVsProductMap', sapOrders.get('partNoVsProductMap'));
        return responseMap;
    }

    /**
     * @description This method returns the order details for a user
     * @author vramachandran@rafter.one | 12 Dec 2023
     * @param isPunchoutUser | Boolean
     * @return List<ECOM_OrderModel>
     */
    @AuraEnabled(cacheable=true)
    public static List<ECOM_OrderModel> getMyOrdersMapped(Boolean isPunchoutUser) {
        List<ECOM_OrderModel> orderModelList;

        //get instance for services
        Type orderServiceType = Type.ForName(ECOM_Constant.ORDER_SERVICE);
        Type sapOrderServiceType = Type.ForName(ECOM_Constant.SAP_ORDER_SUMMARY_SERIVCE);

        ECOM_ISAPOrderSummary orderSummary = (ECOM_ISAPOrderSummary) sapOrderServiceType.newInstance();
        ECOM_IOrderService orderService = (ECOM_IOrderService) orderServiceType.newInstance();

        if(!isPunchoutUser){
            orderModelList = orderService.getMyOrdersModel();
        } else {

        }

        return orderModelList;
    }

    @AuraEnabled
    public static Map<String,Object> getOrderDetails(Id orderId) {
        ECOM_OrderModel orderModel = new ECOM_OrderModel();
        Map<String,Object> responseMap = new  Map<String,Object>();
        Map<String,Boolean> salesStatusMap = new Map<String,Boolean>();
        if(orderId.getSobjectType() == Schema.Order.SObjectType){
            orderModel = ECOM_OrderService.getOrderDetails(orderId);
            List<CardPaymentMethod> cpmList = ECOM_OrderService.getCardPaymentBasedOnOrder(orderModel.id);
            if(!cpmList.isEmpty()){
                responseMap.put('CardPaymentMethod',cpmList[0]);
            }
        }
        else if(orderId.getSobjectType() == Schema.SAP_Order_Summary__c.SObjectType){
            Set<String> summaryIds = new Set<String>();
            summaryIds.add(String.valueOf(orderId));
            List<SAP_Order_Summary__c> sapOrders = ECOM_SAPOrderSummaryService.fetchSAPOrderSummariesById(summaryIds);
            Set<String> ItemPartNumberSet = new Set<String>();
            Map<String, Product2> partNoVsProductMap = new Map<String, Product2>();
            for (SAP_Order_Items__c item : sapOrders[0].SAP_Order_Items__r) {
                ItemPartNumberSet.add(item.Material_Number__c);
            }
            if(ItemPartNumberSet != null){

                List<Product2> products = ECOM_SAPOrderSummaryService.getProductsBasedOnPartnumber(ItemPartNumberSet);
                for(Product2 p: products){
                    if(ItemPartNumberSet.contains(p.Part_Number__c)){
                        partNoVsProductMap.put(p.Part_Number__c, p);
                    }
                }
            }
            orderModel = createOrderModel(sapOrders, partNoVsProductMap);
        }
        Set<String> productIds = new Set<String>();
        for(ECOM_OrderModel.OrderItems item : orderModel.orderItems) {
            productIds.add(item.product2Id);
        }
        String moduleName = 'ECOM_CartService';
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
        responseMap.put('productIds',productIds); // RWPS-4602
        responseMap.put('Status','Success');
        responseMap.put('orderModel',orderModel);
        responseMap.put('salesStatus', salesStatusMap);
        // Added by sathiya on 2024/04/29 for ECOM-1933
        responseMap.put('billToValidationFields', ECOM_CustomMetadataService.getStoreConfigurationByLabel(ECOM_Constant.BILL_TO_FIELD_VALIDATION));
        // Changes end by sathiya
        // Added by sathiya on 2024/05/13 for ECOM-1947
        responseMap.put('invoiceValidationFields', ECOM_CustomMetadataService.getStoreConfigurationByLabel(ECOM_Constant.INVOICE_FIELD_VALIDATION));
        // Changes end by sathiya
        return responseMap;
    }

    public static ECOM_OrderModel createOrderModel(List<SAP_Order_Summary__c> orderList, Map<String, Product2> partNoVsProductMap){

        ECOM_OrderModel order = new ECOM_OrderModel();
        ECOM_OrderModel.BillingAddress billingAdd = new ECOM_OrderModel.BillingAddress();
        ECOM_OrderModel.ShippingAddress shippingAdd = new ECOM_OrderModel.ShippingAddress();
        ECOM_OrderModel.InvoiceMailingAddress mailingAdd = new ECOM_OrderModel.InvoiceMailingAddress(); //ECOM-112 - garora@rafter.one - added field invoice mailing address - 12 May 2024
        Decimal itemDiscount = 0.00; //RWPS-5180
        Set<String> orderItemIds = new Set<String>();

        order.accountId = orderList[0].Account_Ship_To__c;
        order.accountName = orderList[0].Ship_To_Customer_Name__c;
        order.accountNumber = orderList[0].Ship_To_Customer_Id__c;

        billingAdd.street = orderList[0].Bill_To_Address_Street__c;
        billingAdd.city = orderList[0].Bill_To_Address_City__c;
        billingAdd.state = orderList[0].Bill_To_Address_Region__c;
        billingAdd.postalCode = orderList[0].Bill_To_Address_Postal_Code__c;
        billingAdd.stateCode = orderList[0].Bill_To_Address_Region__c;
        billingAdd.country = orderList[0].Bill_To_Address_Country__c;
        billingAdd.countryCode = orderList[0].Bill_To_Address_Country__c;
        billingAdd.companyName = orderList[0].Bill_To_Customer_Name__c; //ECOM-112 - garora@rafter.one - added field for company name - 12 May 2024

        order.billingAddress = billingAdd;

        shippingAdd.street = orderList[0].Ship_To_Address_Street__c;
        shippingAdd.city = orderList[0].Ship_To_Address_City__c;
        shippingAdd.state = orderList[0].Ship_To_Address_Region__c;
        shippingAdd.postalCode = orderList[0].Ship_To_Address_Postal_Code__c;
        shippingAdd.stateCode = orderList[0].Ship_To_Address_Region__c;
        shippingAdd.country = orderList[0].Ship_To_Address_Country__c;
        shippingAdd.countryCode = orderList[0].Ship_To_Address_Country__c;
        shippingAdd.companyName = orderList[0].Ship_To_Customer_Name__c; //ECOM-112 - garora@rafter.one - added field for company name - 12 May 2024
        order.shippingAddress = shippingAdd;

        //ECOM-112 - garora@rafter.one - added invoice mailing address fields - 12 May 2024 - starts
        mailingAdd.street = orderList[0].Invoice_Mailing_Address_Street__c;
        mailingAdd.city = orderList[0].Invoice_Mailing_Address_City__c;
        mailingAdd.state = orderList[0].Invoice_Mailing_Address_Region__c;
        mailingAdd.postalCode = orderList[0].Invoice_Mailing_Address_Postal_Code__c;
        mailingAdd.country = orderList[0].Invoice_Mailing_Address_Country__c;
        mailingAdd.companyName = orderList[0].Invoice_Mailing_Customer_Name__c;
        order.mailingAddress = mailingAdd;
        //ECOM-112 - garora@rafter.one - added invoice mailing address fields - 12 May 2024 - ends

        //order.createdById = orderList[0].CreatedById;
        order.createdDate = orderList[0].Actual_Order_Date__c;// CreatedDate
        //order.promoCode = orderList[0].;
        order.quoteNumber = orderList[0].Quote_Number__c;
        order.grandTotalAmount = orderList[0].Order_Total_Price__c;
        order.id = orderList[0].Id;
        order.isSapOrder = true;
        order.currencyIsoCode = orderList[0].Order_Net_Currency__c;
        order.shippingInstructions = orderList[0].Special_Handling_Instructions__c;
        order.attentionRecipient = orderList[0].Ship_To_Attention__c;
        order.totalItems = orderList[0].fxItemsQuantityTotal__c; //ECOM-3150 - garora@rafter.one - mapping to rollup field to get total quantity on order - 2 May 2024
        order.salesOrg = String.isNotBlank(orderList[0].Sales_Org__c) ? orderList[0].Sales_Org__c : orderList[0].Order__r.Default_Ship_to_ERP_Address__r.ERP_Sales_Org__c; //ECOM-1931 - mapping sales org field - Gaurang - 4 June 2024
        List<ECOM_OrderModel.OrderItems> orderItemsList = new List<ECOM_OrderModel.OrderItems>();
        //RWPS-5230
        Set<String> productIdSet = new Set<String>();
        for (SAP_Order_Items__c item : orderList[0].SAP_Order_Items__r) {
            if (partNoVsProductMap != null && partNoVsProductMap.get(item.Material_Number__c) != null && partNoVsProductMap.get(item.Material_Number__c).Id != null) {
                productIdSet.add(partNoVsProductMap.get(item.Material_Number__c).Id);
            }
        }
        List<String> lstNonSellableDiscontinuedProducts = ECOM_CartUtil.getNonSellableDiscountinuedProducts(productIdSet, 'both');
        List<String> lstNonSellableProducts = ECOM_CartUtil.getNonSellableDiscountinuedProducts(productIdSet, 'non_sellable'); //RWPS-4602
        //RWPS-5230
        // RWPS-6880 Start
        Set<String> excludedPartNumbersSet = new Set<String>();
        User us = new ECOM_UserService().getUserByUserId();
        Boolean isPunchoutUser = us != null && us.ECOM_Is_Punchout_User__c;
        if (isPunchoutUser && orderList != null && !orderList.isEmpty()) {
            Set<String> partNumberSetPunchout = new Set<String>();
            for (String pn : partNoVsProductMap.keySet()) {
                if (String.isNotBlank(pn)) {
                    partNumberSetPunchout.add(pn);
                }
            }
            if (!partNumberSetPunchout.isEmpty()) {
                excludedPartNumbersSet = ECOM_Util.getExcludedPartNumbersForPunchout(partNumberSetPunchout);
            }
        }
        //RWPS-6880 end

        //RWPS-4896-START
        Set<String> trainingProdIds = new set<String>();
        List<Product_Recommendation__c> listProductTraining = ECOM_ProductRecommendationsRepo.getRecommendationsTrainingProducts('Combination',productIdSet);
        if(listProductTraining != null && listProductTraining.size() > 0){
            for(Product_Recommendation__c productTraining : listProductTraining){  
                trainingProdIds.add(productTraining.Product_Suggested__c);

            }
        }
        //RWPS-4896-END


        for (SAP_Order_Items__c item : orderList[0].SAP_Order_Items__r) {
            ECOM_OrderModel.OrderItems orderItem = new ECOM_OrderModel.OrderItems();
            ECOM_OrderModel.Product orderProduct = new ECOM_OrderModel.Product();
			orderItem.description = item.Material_Description__c ;//(Billing_Block_Description__c, Delivery_Block_Description__c, Line_Item_Block_Description__c, Material_Description__c)
            orderItem.earliestShippingDate = item.Expected_Ship_Date__c;
            orderItem.selectedShippingDate = item.Scheduled_Delivery_Date__c;
            orderItem.id = item.Id;//ext_item_id__c - is it sap order item
            orderItem.listPrice = item.Extended_Price__c;
            orderItem.orderId = item.PKI_Order_Summary__c;//is it SAP order number
			//RWPS-5181
			if (String.isNotBlank(item.fxItemStatus__c)) {
				orderItem.status = item.fxItemStatus__c.equalsIgnoreCase(System.label.ECOM_Tracking_Timeline_Values.split(',')[0]) || item.fxItemStatus__c.equalsIgnoreCase(ECOM_Constant.NOT_SHIPPED) ? System.label.ECOM_Tracking_Timeline_Values.split(',')[0] : item.fxItemStatus__c;
			}
			//RWPS-5181
			if(partNoVsProductMap != null && partNoVsProductMap.get(item.Material_Number__c) != null){
                orderProduct.id = partNoVsProductMap.get(item.Material_Number__c).Id;//item.Product2.Id;
                orderProduct.displayUrl = partNoVsProductMap.get(item.Material_Number__c).DisplayUrl !=null ? partNoVsProductMap.get(item.Material_Number__c).DisplayUrl: '';
                orderItem.product2Id = partNoVsProductMap.get(item.Material_Number__c).Id;//item.Product2Id;
            }
            orderProduct.name = item.Material_Description__c;
            orderProduct.partNumber = item.Material_Number__c;
            orderItem.product = orderProduct;
            orderItem.quantity = item.Quantity_Ordered__c;
            orderItem.totalLineAmount = item.Customer_Specific_Price__c;
            orderItem.totalPrice = item.Net_Price__c;
            orderItem.type = 'Order Product';
            orderItem.unitPrice = item.Extended_Price__c;
            orderItem.tariffSurcharge = item.Tariff_Surcharge__c; //RWPS-5180
            itemDiscount += item.Discounts__c != null? item.Discounts__c : 0; //RWPS-5180
            //RWPS-5230 - Start
            if(lstNonSellableDiscontinuedProducts.isEmpty() == false && orderProduct != null && orderProduct.id != null && lstNonSellableDiscontinuedProducts.contains(orderProduct.id)) {
                orderItem.isNonSellableOrDiscontinuedProduct = true;
            } else {
                orderItem.isNonSellableOrDiscontinuedProduct = false;
            }

            //RWPS-4896-START
            if(trainingProdIds.contains(orderProduct.id)){
                 orderItem.isTrainingProduct = true;
            }else{
                 orderItem.isTrainingProduct = false;
            }

            //RWPS-4896 - END
            if(lstNonSellableProducts.contains(orderProduct.id)){
                orderItem.isNonSellableProduct = true;
            } else {
                orderItem.isNonSellableProduct = false;
            }
            if(lstNonSellableDiscontinuedProducts.contains(orderProduct.id) && lstNonSellableProducts.contains(orderProduct.id) == false) {
                orderItem.isDiscontinuedProduct = true;
            } else {
                orderItem.isDiscontinuedProduct = false;
            }
            //RWPS-5230 - End
            // RWPS-6880 start
            if(orderProduct != null && String.isNotBlank(orderProduct.partNumber) && excludedPartNumbersSet.contains(orderProduct.partNumber)) {
                orderItem.isExcludedProduct = true;
            } else {
                orderItem.isExcludedProduct = false;
            }
            // RWPS-6880 end
            orderItemsList.add(orderItem);
            orderItemIds.add(item.Id);
        }
        order.orderItems = orderItemsList;
        order.orderNumber = String.valueOf(orderList[0].Order_Number__c);
        order.ownerId = orderList[0].OwnerId;
        order.poNumber = orderList[0].Customer_PO_Number__c;
        order.salesStoreId =  ECOM_Util.getWebStoreIdByName();
        order.status = orderList[0].fxStatusB2B__c;
        order.totalAmount = orderList[0].Order_Total_Price__c;
        order.totalTaxAmount = orderList[0].Order_Level_Tax__c;
        order.totalSavings = itemDiscount; //RWPS-5180
        order.totalShippingAmount = orderList[0].Handling_Charges__c ;
        order.totalProdAmount = orderList[0].Order_Net_Value__c; //orderList[0].Order_Total_Price__c
        order.sourceType = String.isNotBlank(orderList[0].Source_Type__c) ? orderList[0].Source_Type__c : null; //RWPS-5149
        order.sfOrder = orderList[0].Order__c != null ? orderList[0].Order__c : null ; //RWPS-5149
        order.totalTariffSurcharge = orderList[0].Total_Tariff_Surcharge__c; //RWPS-5149
        Map<String,List<ECOM_OrderModel.OrderItemTracking>> itemTrackings = new Map<String,List<ECOM_OrderModel.OrderItemTracking>>();

        //fetch SAP order Item Tracking
        if(orderItemIds != null){
            Map<String, List<ECOM_OrderModel.OrderItemTracking>> itemToTrackings = new Map<String, List<ECOM_OrderModel.OrderItemTracking>>();
            List<SAP_Order_Item_Tracking__c> trackings = ECOM_SAPOrderSummaryService.getSAPOrderItemTrackings(orderItemIds);
            List<ECOM_OrderModel.OrderItemTracking> orderItemTrackings = new List<ECOM_OrderModel.OrderItemTracking>();
            for(SAP_Order_Item_Tracking__c tr :trackings){
                ECOM_OrderModel.OrderItemTracking tracking = new ECOM_OrderModel.OrderItemTracking();
                tracking.carrierName = tr.CarrierName__c;
                tracking.OrderItemId = tr.PKIOrderItems__c;
                tracking.OrderSummaryId = tr.PKIOrderSummary__c;
                tracking.quantityShipped = tr.Quantity_Shipped__c;
                tracking.trackingDate = tr.Tracking_Date__c;
                tracking.trackingNumber = tr.TrackingNumber__c;
                tracking.trackingURL = tr.TrackingURL__c;
                orderItemTrackings.add(tracking);
                if(itemToTrackings.get(tr.PKIOrderItems__c) == null){
                    itemToTrackings.put(tr.PKIOrderItems__c, new List<ECOM_OrderModel.OrderItemTracking>());
                }
                itemToTrackings.get(tr.PKIOrderItems__c).add(tracking);
            }
            //Assign SAP order item trackings to related order item
            if(itemToTrackings != null && itemToTrackings.size() > 0){
                for(ECOM_OrderModel.OrderItems oi: order.OrderItems){
                    if(itemToTrackings.get(oi.id) != null){
                        oi.OrderItemTrackings = itemToTrackings.get(oi.id);
                        itemTrackings.put(oi.id,itemToTrackings.get(oi.id));
                    } else{
						itemTrackings.put(oi.id,new List<ECOM_OrderModel.OrderItemTracking>());
                    }
                }
                
            }
            
        }
        order.itemTrackings = itemTrackings;
        
        return order;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Order> findOrderByOrderNumberAndZip(String orderNumber, String zipCode) {
        List<Order> orderSummaryList = ECOM_OrderService.findOrderByOrderNumberAndZip(orderNumber, zipCode);
        return orderSummaryList;
    }
    
    @AuraEnabled
    public static Map<String, Object> getProdImages(List<Id> productIds, Id communityId) {
        Map<String, Object> prodImageMap = ECOM_ProductService.getProdImages(productIds, communityId);
        return prodImageMap;
    }
    
    @AuraEnabled
    public static List<ECOM_AccountWrapper.WishlistDetails> getWishlistDetails()
    {
        Type accountService = Type.forName(ECOM_Constant.ACCOUNT_SERVICE);
        ECOM_IAccountService accountServiceInstance = (ECOM_IAccountService)accountService.newInstance();
        List<WishList> wls = accountServiceInstance.fetchWishList(UserInfo.getUserId());
        List<ECOM_AccountWrapper.WishlistDetails> wishListDetails = ECOM_AccountUtil.getWishListDetails(wls);
        return wishListDetails;
    }
    
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
            wishListItem = Test.isRunningTest()? ECOM_TestUtil.getWishlistItemData():  ConnectApi.CommerceWishlist.addItemToWishlist( webstoreId,  wishListId,  wishlistItemInput);
        }else{
            //Create a wishlistInput to be created
            ConnectApi.WishlistInput wishlistInput = new ConnectApi.WishlistInput();
            wishlistInput.name = 'My favorite list';
            wishlistInput.products = new List<ConnectApi.WishlistItemInput>{
                wishlistItemInput
            };
            wishlist = test.IsRunningTest()? ECOM_TestUtil.getWishlistData():  ConnectApi.CommerceWishlist.createWishlist(
                webstoreId,
            effectiveAccountId,
            wishlistInput
                );
            
            ConnectApi.WishlistItemCollection collection =  wishlist.page;
            List<ConnectApi.WishlistItem> wishListItems = collection.items;
            wishListItem = wishListItems.size() > 0? wishListItems[0] : null;
        }
        return wishListItem;
    }
    
    @AuraEnabled
    public static Map<String,Object> addItemsToCart(String communityId,
    String effectiveAccountId,
    List<CartItem> cartItems
    ) {
        
        Map<String,Object> response = ECOM_CartService.addItemsToCart(communityId,effectiveAccountId,cartItems);
        return response;
    }
    
    @AuraEnabled
    public static Map<String,Object> getAllMySapOrders() {
        ECOM_OrderModel orderModel = new ECOM_OrderModel();
        Map<String,Object> responseMap = new  Map<String,Object>();
        system.debug('getAllMySapOrders');
        Type userService = Type.forName(ECOM_Constant.USER_Service);
        ECOM_IUserService userServiceInstance = (ECOM_IUserService)userService.newInstance();
        User user = userServiceInstance.getUserByUserId();
        
        Map<String, C_META_Storefront_Configuration__mdt> storeConfigMdtMap= ECOM_CustomMetadataService.fetchSapOrderHistoryDateData();
        Date sapOrderEndDate = date.valueOf(storeConfigMdtMap.get('SAP_Order_End_Date').Value__c);
        Integer sapOrderStartDateInYrs = Integer.valueOf(storeConfigMdtMap.get('SAP_Order_Start_Date_in_Past_Years').Value__c);
        system.debug('sapOrderStartDateInYrs =>'+sapOrderStartDateInYrs);
        system.debug('sapOrderEndDate =>'+sapOrderEndDate);
        Date sapOrderStartDate = System.today().addYears(-1*sapOrderStartDateInYrs);
        system.debug('sapOrderStartDate =>'+sapOrderStartDate);
        
        //VRa changes for punchout --Begin
        List<SAP_Order_Summary__c> orders = new List<SAP_Order_Summary__c>();
        List<String> sourceTypes = new List<String>();
        List<String> contactEmailList = new List<String>();
        String contactEmail = user.Email;
        String priorEmail = user.Contact.Prior_Email__c;
        
        //fetch orders based on user type
        if(user != null && user?.ECOM_Is_Punchout_User__c){
           //RWPS-5777 start
            String masterId = user?.Contact?.Default_Ship_to_ERP_Address__r?.Master_Address__c;
            Map<String, String> emailMap = ECOM_Util.getPunchoutEmailDetails(masterId);

            String additionalEmails = emailMap.get('additionalEmails');
            String selectedEmailType = emailMap.get('selectedEmailType');
            //RWPS-5777 end
            contactEmailList.add(contactEmail);
            if(String.isNotBlank(priorEmail)){
                contactEmailList.add(priorEmail);
            }
            List<String> alternateEmailList = new List<String>();//RWPS-4082
            //RWPS-4082 start
            if (String.isNotBlank(additionalEmails))
            {
                for (String email : additionalEmails.split(',')) {
                    email = email.trim();
                    if (String.isNotBlank(email)) {
                        alternateEmailList.add(email);//RWPS-4082
                    }
                }
            }
        //RWPS-4082 end
            
            //orders = ECOM_SAPOrderSummaryService.fetchSAPOrdersByEmail(contactEmailList, selectedEmailType, alternateEmailList); //RWPS-4131 ////RWPS-4082
            //RWPS-4443
            orders = ECOM_SAPOrderSummaryService.fetchSAPOrdersByEmail(contactEmailList, selectedEmailType, alternateEmailList, contactEmail); //RWPS-4131 //RWPS-4082 //RWPS-4443
            //RWPS-3741
            //sourceTypes = System.Label.ECOM_OrderTypes_Punchout.split(',');
            //orders = ECOM_SAPOrderSummaryService.fetchSAPOrderByEmailAndSourceType(contactEmailList, sourceTypes, sapOrderStartDate, sapOrderEndDate);
        } else {
            orders = ECOM_SAPOrderSummaryService.fetchSAPOrderSummariesByEmail(contactEmailList, sapOrderStartDate, sapOrderEndDate);
        }
        //VRa changes for punchout --Begin
        
        
        Set<String> ItemPartNumberSet = new Set<String>();
        Map<String, Product2> partNoVsProductMap = new Map<String, Product2>();
        for (SAP_Order_Summary__c o : orders) {
            for (SAP_Order_Items__c item : o.SAP_Order_Items__r) {
                ItemPartNumberSet.add(item.Material_Number__c);
            }
        }
        if(ItemPartNumberSet != null){
            List<Product2> products = ECOM_SAPOrderSummaryService.getProductsBasedOnPartnumber(ItemPartNumberSet);
            for(Product2 p: products){
                if(ItemPartNumberSet.contains(p.Part_Number__c)){
                    partNoVsProductMap.put(p.Part_Number__c, p);
                }
            }
        }
        if(!orders.isEmpty()){
            orderModel = createOrderModel(orders, partNoVsProductMap);
        }
        responseMap.put('Status','Success');
        responseMap.put('orders',orders);
        responseMap.put('orderModel',orderModel);
        responseMap.put('partNoVsProductMap',partNoVsProductMap);
        return responseMap;
        //return orders;
    }
    
    /**
     * RWPS-4881
     * @description This method returns the offline/SAP orders details for a user
     * @author Sachin V | 2025-10-28
     * @param searchString | String
     * @return ap<String,Object>
     */
    @AuraEnabled
    public static Map<String,Object> getOfflineOrders(String searchString, Boolean onlineOrdersTab) {
        ECOM_OrderModel orderModel = new ECOM_OrderModel();
        Map<String,Object> responseMap = new  Map<String,Object>();
        Type userService = Type.forName(ECOM_Constant.USER_Service);
        ECOM_IUserService userServiceInstance = (ECOM_IUserService)userService.newInstance();
        User user = userServiceInstance.getUserByUserId();

        //VRa changes for punchout --Begin
        List<SAP_Order_Summary__c> orders = new List<SAP_Order_Summary__c>();
        List<String> contactEmailList = new List<String>();
        String contactEmail = user.Email;
        String priorEmail = user.Contact.Prior_Email__c;
        //fetch orders based on user type
        List<SAP_Order_Summary__c> ordersList = new List<SAP_Order_Summary__c>();
        List<SAP_Order_Summary__c> finalOrderSummaryList = new List<SAP_Order_Summary__c>();
        if(user != null && user?.ECOM_Is_Punchout_User__c) {
           //RWPS-5777 start
            String masterId = user?.Contact?.Default_Ship_to_ERP_Address__r?.Master_Address__c;
            Map<String, String> emailMap = ECOM_Util.getPunchoutEmailDetails(masterId);

            String additionalEmails = emailMap.get('additionalEmails');
            String selectedEmailType = emailMap.get('selectedEmailType');
            //RWPS-5777 end
            contactEmailList.add(contactEmail);
            if(String.isNotBlank(priorEmail)){
                contactEmailList.add(priorEmail);
            }
            List<String> alternateEmailList = new List<String>();//RWPS-4082
            //RWPS-4082 start
            if (String.isNotBlank(additionalEmails))
            {
                for (String email : additionalEmails.split(',')) {
                    email = email.trim();
                    if (String.isNotBlank(email)) {
                        alternateEmailList.add(email);//RWPS-4082
                    }
                }
            }
            //RWPS-4881
            List<String> orderTypesList = new List<String>();
            List<String> poTypesList = new List<String>(); // RWPS-5094
            if (onlineOrdersTab == true) {
                List<C_META_Storefront_Configuration__mdt> storeFrontConfigurations = ECOM_CustomMetadataRepo.fetchStoreConfigMdtBasedOnModuleName('POTypesPunchout');
                storeFrontConfigurations.add(ECOM_CustomMetadataRepo.fetchStoreConfigMdtBasedOnModuleName('PunchoutOrderTypes')[0]);
                poTypesList = storeFrontConfigurations[0].Value__c.split(',');
                orderTypesList = storeFrontConfigurations[1].Value__c.split(',');
            }
            ordersList = ECOM_SAPOrderSummaryRepo.fetchSAPOrderForPunchoutUsers(contactEmailList,selectedEmailType, alternateEmailList, contactEmail, searchString, orderTypesList, poTypesList); //RWPS-5094
        } else if (onlineOrdersTab == false) {
            //RWPS-4881
            ordersList = ECOM_SAPOrderSummaryRepo.fetchSAPOrderForWebUsers(contactEmailList, searchString);
        }
        if (String.isNotBlank(searchString)) {
            for (SAP_Order_Summary__c orderSummary : ordersList) {
                for (SAP_Order_Items__c orderItem : orderSummary.SAP_Order_Items__r) {
                    if ((orderItem.PKI_Order_Summary__r.Customer_PO_Number__c != null && orderItem.PKI_Order_Summary__r.Customer_PO_Number__c.containsIgnoreCase(searchString)) ||
                        (orderItem.PKI_Order_Summary__r.Order_Number__c != null && String.valueOf(orderItem.PKI_Order_Summary__r.Order_Number__c).containsIgnoreCase(searchString)) ||
                        (orderItem.Order_Product__r != null && orderItem.Order_Product__r.Product2 != null && orderItem.Order_Product__r.Product2.Part_Number__c != null && orderItem.Order_Product__r.Product2.Part_Number__c.containsIgnoreCase(searchString)) ||
                        (String.isNotBlank(orderItem.Material_Number__c) && orderItem.Material_Number__c.containsIgnoreCase(searchString))
                    ) {
                        if (finalOrderSummaryList.contains(orderSummary) == false) {
                            finalOrderSummaryList.add(orderSummary);
                        }
                    }
                }
            }
            orders = finalOrderSummaryList;
        } else {
            orders = ordersList;
        }
        //RWPS-4881
        
        //VRa changes for punchout --Begin
        
        
        Set<String> ItemPartNumberSet = new Set<String>();
        Map<String, Product2> partNoVsProductMap = new Map<String, Product2>();
        for (SAP_Order_Summary__c o : orders) {
            for (SAP_Order_Items__c item : o.SAP_Order_Items__r) {
                ItemPartNumberSet.add(item.Material_Number__c);
            }
        }
        if(ItemPartNumberSet != null){
            List<Product2> products = ECOM_SAPOrderSummaryService.getProductsBasedOnPartnumber(ItemPartNumberSet);
            for(Product2 p: products){
                if(ItemPartNumberSet.contains(p.Part_Number__c)){
                    partNoVsProductMap.put(p.Part_Number__c, p);
                }
            }
        }
        if(!orders.isEmpty()){
            orderModel = createOrderModel(orders, partNoVsProductMap);
        }
        responseMap.put('Status','Success');
        responseMap.put('orders',orders);
        responseMap.put('orderModel',orderModel);
        responseMap.put('partNoVsProductMap',partNoVsProductMap);
        return responseMap;
    }
    
    @AuraEnabled
    public static List<SAP_Order_Summary__c> findSapOrderByOrderNumberAndZip(String orderNumber, String zipCode) {
        Type userService = Type.forName(ECOM_Constant.USER_Service);
        ECOM_IUserService userServiceInstance = (ECOM_IUserService)userService.newInstance();
        User user = userServiceInstance.getUserByUserId();
        String contactEmail = user.Email;
        String priorEmail = user.Contact.Prior_Email__c;
        List<String> contactEmailList = new List<String>{contactEmail,priorEmail};
        
        //VRa: Punchout Changes: Begin
        List<SAP_Order_Summary__c> orderSummaryList;
        
        if(user.ECOM_Is_Punchout_User__c){
            orderSummaryList = ECOM_SAPOrderSummaryService.findPunchoutSapOrderByOrderNumberAndZip(contactEmailList, orderNumber, zipCode);
        } else {
            orderSummaryList = ECOM_SAPOrderSummaryService.findSapOrderByOrderNumberAndZip(contactEmailList, orderNumber, zipCode);
        }
        
        //VRa: Punchout Changes: End
        
        return orderSummaryList;
    }
    
    /**
     * @description  Get ERP address
     * @author ssingh@rafter.one | 11-09-2023
     * @param erpShipToId, erpBillToId
     * @return Map<String,Object>
     **/
    @AuraEnabled
    public static Map<String,Object> getERPAddress(String erpShipToId, String erpBillToId){
        Map<String,Object> response=new Map<String,Object>();
        try {
            response.put('success',false);
            Type erpAddressService = Type.forName(ECOM_Constant.ERP_ADDRESS_SERVICE);
            ERP_IAddressService erpAddressServiceInstance = (ERP_IAddressService)erpAddressService.newInstance();
            //ERP_AddressModel shiptToModel = new ERP_AddressModel();
            //ERP_AddressModel billToModel = new ERP_AddressModel();
            if(String.isNotBlank(erpBillToId))
            {
                ERP_Address__c billToERP=erpAddressServiceInstance.fetchERPAddressesById(erpBillToId)[0];
                response.put('billToAddress',ERP_AddressUtil.convertERPToAddressModel(billToERP));
            }
            if(String.isNotBlank(erpShipToId))
            {
                ERP_Address__c shipToERP=erpAddressServiceInstance.fetchERPAddressesById(erpShipToId)[0];
                response.put('shipToAddress',ERP_AddressUtil.convertERPToAddressModel(shipToERP));
            }
            response.put('success',true);
        } catch (Exception e) {
            response.put('success',false);
        }
        return response;
    }
    
    /**
     * @description  get accounts by ids
     * @author ssingh@rafter.one | 11-09-2023
     * @param accIds
     * @return List<Account>
     **/
    @AuraEnabled
    public static List<Account> getAccountBasedOnIds(List<String> accIds)
    {
        return ECOM_AccountRepo.getAccountBasedOnIds(accIds);
    }
    
    /**
     * @description - Method to check if the user is punchout user or not - RWPS-4196
     * @author Chirag
     * @return Boolean
     **/
    @AuraEnabled
    public static Boolean checkIfCurrentUserIsPunchoutUser() {
        if (!ECOM_UserRepo.getPunchoutUserInformationByUserId(UserInfo.getUserId()).isEmpty()) {
            return true;
        } else {
            return false;
        }
    }
    
    /**
     * RWPS-4621
     * @description This function is used to fetch the unavailability(discontinued & non-sellable) of products provided along with replacement if present
     * @author Sachin Vispute | 30-09-2025
     * @param productIdList : Collection of product Ids for which the unavailability needs to be checked
     * @return Map<String, Object> productUnavailabilityDetailsMap : collection containing unavilable products with details
     **/
    @AuraEnabled
public static Map<String,Object> fetchProductUnavailability(List<String> productIdList) {
    Map<String,Object> productUnavailabilityDetailsMap = new Map<String,Object>();
    try {
        List<String> discontinuedProducts = new List<String>();
        List<String> nonSellableProductIdList = new List<String>();
        Map<String,String> directReplacementProductMap = new Map<String,String>();
        Map<String,String> indirectReplacementProductMap = new Map<String,String>();
            List<String> discontinuedAndNonSellableMaterialCodes = new List<String>();
        List<String> replacementProductIdsList = new List<String>();
            discontinuedAndNonSellableMaterialCodes = ECOM_CartUtil.fetchProductMaterialStatus(ECOM_Constant.DISCONTINUED_PRODUCT);
            for (String materialCode : ECOM_CartUtil.fetchProductMaterialStatus(ECOM_Constant.ECOM_NON_SELLABLE_PRODUCT)) {
                discontinuedAndNonSellableMaterialCodes.add(materialCode);
            }
            List<String> replacementProductsPartNumberList = new List<String>(); //List that holds replacement part numbers
        User user = new ECOM_UserService().getUserByUserId();
        String salesOrg = ECOM_CustomMetadataService.getSalesOrg(ECOM_Util.getCountryFromUser(user));
        Set<String> productIds = new Set<String>(productIdList);
List<Product_Sales__c> discontinuedAndNonSellableProducts = ECOM_ProductRepo.getProductSalesAndReplacementByProdIdAndMaterialCodes(productIds, discontinuedAndNonSellableMaterialCodes, salesOrg);
            for(Product_Sales__c discontinuedAndNonSellableProduct : discontinuedAndNonSellableProducts) {
                // Checking whether product is discontinued
                if (discontinuedAndNonSellableProduct != null && discontinuedAndNonSellableProduct.Distribution_ChainSpecificMaterialStatus__c != null && ECOM_CartUtil.fetchProductMaterialStatus(ECOM_Constant.DISCONTINUED_PRODUCT).isEmpty() == false && ECOM_CartUtil.fetchProductMaterialStatus(ECOM_Constant.DISCONTINUED_PRODUCT).contains(discontinuedAndNonSellableProduct.Distribution_ChainSpecificMaterialStatus__c)) {
                    discontinuedProducts.add(discontinuedAndNonSellableProduct.Product__c);
                    // Checking whether the direct replacement is available
                    if (discontinuedAndNonSellableProduct.Product__r != null && discontinuedAndNonSellableProduct.Product__r.Replacement_Product__c != null) {
                        directReplacementProductMap.put(discontinuedAndNonSellableProduct.Product__c,discontinuedAndNonSellableProduct.Product__r.Replacement_Product__r.Part_Number__c);
                        replacementProductsPartNumberList.add(discontinuedAndNonSellableProduct.Product__r.Replacement_Product__r.Part_Number__c);
                    } else {
                if (String.isNotBlank(discontinuedAndNonSellableProduct.Product__r.Replacement_Alternatives__c)) {
                            // logic for indirect replacement
                            indirectReplacementProductMap.put(discontinuedAndNonSellableProduct.Product__c,discontinuedAndNonSellableProduct.Product__r.Replacement_Alternatives__c);
                            replacementProductsPartNumberList.addAll(discontinuedAndNonSellableProduct.Product__r.Replacement_Alternatives__c.trim().split(','));
                }
            }
// Checking whether product is non-sellable
                } else if (discontinuedAndNonSellableProduct != null && discontinuedAndNonSellableProduct.Distribution_ChainSpecificMaterialStatus__c != null && ECOM_CartUtil.fetchProductMaterialStatus(ECOM_Constant.ECOM_NON_SELLABLE_PRODUCT).isEmpty() == false && ECOM_CartUtil.fetchProductMaterialStatus(ECOM_Constant.ECOM_NON_SELLABLE_PRODUCT).contains(discontinuedAndNonSellableProduct.Distribution_ChainSpecificMaterialStatus__c)) {
                    nonSellableProductIdList.add(discontinuedAndNonSellableProduct.Product__c);
                }
            }
            //Logic to check and remove replacement products if non-sellable - start
            List<Product2> replacementProductList = ECOM_ProductRepo.getProductsBasedOnPartNumber(replacementProductsPartNumberList); //Fetching product details of replacement products on basis on part number
            for (Product2 product : replacementProductList) {
                if (product.id != null) {
                    replacementProductIdsList.add(product.id);
                }
            }
            //Fetching non-sellable replacement products
                List<Product_Sales__c> nonSellableProductList = ECOM_ProductRepo.getProductSalesAndReplacementByProdIdAndMaterialCodes(new Set<String>(replacementProductIdsList), ECOM_CartUtil.fetchProductMaterialStatus(ECOM_Constant.ECOM_NON_SELLABLE_PRODUCT), salesOrg);
            List<String> nonSellablePartsList = new List<String>();
            if (nonSellableProductList.isEmpty() == false) {
                for (Product_Sales__c nonSellableProduct : nonSellableProductList) {
                    // Checking whether there is any replacement product present that is non-sellable and storing them into nonSellableIds collection
                    if (nonSellableProductIdList.contains(nonSellableProduct.Product__r.Part_Number__c) == false) {
                        nonSellableProductIdList.add(nonSellableProduct.Product__r.Part_Number__c);
                    }
                }
                for (String key : directReplacementProductMap.keySet()) {
                    // Checking whether any product contains direct replacement products that are non-sellable
                    for (String value : directReplacementProductMap.get(key).split(',')) {
                        if (nonSellableProductIdList.contains(value)) {
                            nonSellablePartsList.add(key);
                        }
                    }
                }
                for (String key : indirectReplacementProductMap.keySet()) {
                    // Checking whether any product contains indirect replacement products that are non-sellable
                    for (String value : indirectReplacementProductMap.get(key).split(',')) {
                        if (nonSellableProductIdList.contains(value)) {
                            nonSellablePartsList.add(key);
                }
            }
        }
                // Ultimatelly removing the replacement products and pairs that are non-sellable
                for (String nonSellableReplacementPart : nonSellablePartsList) {
                    if (discontinuedProducts.contains(nonSellableReplacementPart) == false) {
                        discontinuedProducts.add(nonSellableReplacementPart);
                    }
                    if (directReplacementProductMap.containsKey(nonSellableReplacementPart)) {
                        directReplacementProductMap.remove(nonSellableReplacementPart);
                    }
                    if (indirectReplacementProductMap.containsKey(nonSellableReplacementPart)) {
                        indirectReplacementProductMap.remove(nonSellableReplacementPart);
                    }
                }
            }
            //Logic to check and remove replacement products if non-sellable - end
        productUnavailabilityDetailsMap.put('discontinuedProducts', discontinuedProducts);
        productUnavailabilityDetailsMap.put('directReplacementProductMap', directReplacementProductMap);
        productUnavailabilityDetailsMap.put('indirectReplacementProductMap', indirectReplacementProductMap);
        productUnavailabilityDetailsMap.put('nonSellableProducts', nonSellableProductIdList);
        productUnavailabilityDetailsMap.put('success',true);
        } catch(Exception exceptionInstance) {
            productUnavailabilityDetailsMap.put('success',false);
            productUnavailabilityDetailsMap.put('message',exceptionInstance.getMessage());
            ECOM_ApplicationLogsUtil.logFailure(exceptionInstance, ECOM_Constant.USER_MODULE_NAME, 'ECOM_OrderHistoryController', 'fetchProductUnavailability', '');
    }
    return productUnavailabilityDetailsMap;
}

    /**
     * RWPS-4602
     * @description This function is used to retrieve the order details and replacement information
     * @author Manish Joshi | 30-09-2025
     * @param orderId
     * @param communityId
     * @return Map<String, Object>
     **/
    @AuraEnabled
    public static Map<String,Object> getorderDetailsAndReplacement(Id orderId,String communityId)
    {
        Map<String,Object> responseMap = new Map<String,Object>();
        try
        {
            responseMap = getOrderDetails(orderId);
            Map<String,Object> replacementMap = ECOM_ProductUtil.getReplacementMap(communityId,(Set<String>) responseMap.get('productIds'));
            responseMap.put('replacementMap', replacementMap);
            responseMap.put('replacementSuccess',true);
        }
        catch(Exception ex)
        {
            responseMap.put('success',false);
            responseMap.put('message',ex.getMessage());
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.USER_MODULE_NAME, 'ECOM_OrderHistoryController', 'getorderDetailsAndReplacement', '');
        }
        return responseMap;
    }

    /**
     * RWPS-4881
     * @description This function is used to convert normal URL parameters into encrypted
     * @author Sachin Vispute | 28-10-2025
     * @param urlParametersMap
     * @return Map<String, String>
     **/
    @AuraEnabled
    public static Map<String,String> getEncodedValues(Map<String,String> urlParametersMap) {
        if (urlParametersMap.isEmpty() == false) {
            for (String key : urlParametersMap.keySet()) {
                if (String.isNotBlank(urlParametersMap.get(key))) {
                    urlParametersMap.put(key, ECOM_EncryptUtil.encryptWithAES256(urlParametersMap.get(key)));
                }
            }
        }
        return urlParametersMap;
    }

    /**
     * RWPS-4881
     * @description This function is used to fetch salesOrg of currently logged in user
     * @author Sachin Vispute | 04-11-2025
     * @return String
     **/
    @AuraEnabled(cacheable=true)
    public static String fetchSalesOrg() {
        List<User> userList = new List<User> {new ECOM_UserService().getUserByUserId()};
        String salesOrg = null;
        if (userList.isEmpty() == false) {
            salesOrg = ECOM_CustomMetadataService.getSalesOrg(ECOM_Util.getCountryFromUser(userList[0]));
        }
        return salesOrg;
    }
}