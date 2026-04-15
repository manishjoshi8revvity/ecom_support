/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-109
*
* 2. Description - This class is used for Order specific transactions.
*
* 3. Objects referenced
*    - Order
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
*
* 5. Dependant Class(es):
*    -
*
* 6. Test Class Name:
*    - ECOM_OrderUtil_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Rani 2023.08.16
*	 - Sathiya 2024.04.29 - Adding field mapping for ECOM-1933 and ECOM-1942
*    - Gaurang 2024.05.02 - mapping to rollup field with total quantity on order - ECOM-3150
*    - Gaurang 2024.05.12 - added fields and their mappings - ECOM-112
*	 - Sathiya 2024.04.13 - Adding field mapping for ECOM-1947
*    - Manoj 2024-05-06 RWPS-622 Hide Availability date when the Order contains an Instrument(Added isLargePackShipingOrder logic)
*    - Gaurang 2024.04.06 ECOM-1931 - mapping sales org field
*	 - Sathiya 2024.06.27 - Adding field mapping for ECOM-3389
*	 - Sathiya 2024.07.01 - Adding field mapping for ECOM-3410
*    - Sathiya 2024.08.06 Email Temp Fix
*    - Sidak 2024.09.09 Updated method getOrderDetails. Added logic to pick Account name from Default_Ship_to_ERP_Address__r.fxCustomerName_Master__c. Ticket - RWPS-1306
*    - Sidak 2024.12.06 Updated method getOrderDetails. Added new field approvalRejectionComment. RWPS-1885
*    - Manish Joshi 2025.01.27 - Updated method getOrderDetails to get product display name instead of name - RWPS-2270
*    - Poonam Shukla 2025.04.24 - Updated method getOrderModelList, getOrderDetails  to get tariffSurcharge, totaltariffSurcharge in order item and Total Order Summary for Order Confirmation and Order History detauls Page - RWPS-3026
*    - Prabhat Kumar 2025.06.19 - Updated method getOrderDetails to get non-sellable and discontinued products - RWPS-2786
*    - Gaurav Bhansali 2025.08.04 - Added customerTargetName in getOrderDetails method response - RWPS-3868
*    - Prabhat Kumar 2025.08.25 - Added add logic to show free items in method getOrderDetails - RWPS-3811
*    - Sachin Vispute 2025.10.03 - updated Method getOrderDetails - RWPS-4602
*    - Prabhat Kumar 2025.12.03 - updated Method getOrderDetails - RWPS-4896
*    - Poonam Shukla 2026.03.31 - updated Method getOrderDetails - RWPS-6880
*************************************************************/
public with sharing class ECOM_OrderUtil {

    /**
    * @description This method is used to update orders.
    * @author Rani Thumma | 2023-08-23
    * @param List<Order>
    * @return
    **/
    public static void updateOrders(List<Order> ordersToUpdate){
        if(ordersToUpdate != null && ordersToUpdate.size() > 0){
            ECOM_OrderRepo.updateOrders(ordersToUpdate);
        }
    }

    /**
    * @description This method is used to get order & order item details.
    * @author Sidak Singh | 2023-09-12
    * @param Id
    * @return
    **/
    public static ECOM_OrderModel getOrderDetails(List<Order> orderList){
        ECOM_OrderModel order = new ECOM_OrderModel();
        //RWPS-622
        Boolean isLargePackShippingOrder = false;
        ECOM_OrderModel.BillingAddress billingAdd = new ECOM_OrderModel.BillingAddress();
        ECOM_OrderModel.ShippingAddress shippingAdd = new ECOM_OrderModel.ShippingAddress();
        ECOM_OrderModel.InvoiceMailingAddress mailingAdd = new ECOM_OrderModel.InvoiceMailingAddress();
        Set<String> SAPOrderItemIds = new Set<String>();
         Set<String> productIdSet = new Set<String>();//RWPS-2786

        billingAdd.id = orderList[0].Default_Bill_to_ERP_Address__c;
        if(orderList[0].Default_Bill_to_ERP_Address__r?.ECOM_Review_Status__c=='Approved'){
            billingAdd.city = orderList[0].Default_Bill_to_ERP_Address__r.fxAddress_City__c;
            billingAdd.country = orderList[0].Default_Bill_to_ERP_Address__r.fxAddress_CountryName__c;
            billingAdd.postalCode = orderList[0].Default_Bill_to_ERP_Address__r.fxAddress_Postal__c;
            billingAdd.state = orderList[0].Default_Bill_to_ERP_Address__r.fxAddress_StateName__c;
            billingAdd.street = orderList[0].Default_Bill_to_ERP_Address__r.fxAddress_Street__c;
        } else {
            billingAdd.city = orderList[0].Default_Bill_to_ERP_Address__r?.Address_City__c;
            billingAdd.country = orderList[0].Default_Bill_to_ERP_Address__r?.apiCountry__c;
            billingAdd.postalCode = orderList[0].Default_Bill_to_ERP_Address__r?.Address_Postal_Code__c ;
            billingAdd.state = orderList[0].Default_Bill_to_ERP_Address__r?.apiState__c;
            billingAdd.street = orderList[0].Default_Bill_to_ERP_Address__r?.Address_Street_Line_1__c;
        }
        billingAdd.customerTargetName = orderList[0].Default_Bill_to_ERP_Address__r?.fxCustomerName_Target__c; //RWPS-3868
		billingAdd.companyName = orderList[0].Default_Bill_to_ERP_Address__r?.fxAccountName__c; //ECOM-112 - garora@rafter.one - for company name - 12 May 2024
		billingAdd.showCompanyName = orderList[0].Default_Bill_to_ERP_Address__r?.Target_Address__c != null;

        shippingAdd.id = orderList[0].Default_Ship_to_ERP_Address__c;
        shippingAdd.city = orderList[0].Default_Ship_to_ERP_Address__r.fxAddress_City__c;
        shippingAdd.country = orderList[0].Default_Ship_to_ERP_Address__r.fxAddress_CountryName__c;
        shippingAdd.postalCode = orderList[0].Default_Ship_to_ERP_Address__r.fxAddress_Postal__c;
        shippingAdd.state = orderList[0].Default_Ship_to_ERP_Address__r.fxAddress_StateName__c;
        shippingAdd.street = orderList[0].Default_Ship_to_ERP_Address__r.fxAddress_Street__c;
        shippingAdd.companyName = orderList[0].Default_Ship_to_ERP_Address__r?.fxAccountName__c; //ECOM-112 - garora@rafter.one - for company name - 12 May 2024
		shippingAdd.showCompanyName = orderList[0].Default_Ship_to_ERP_Address__r?.Target_Address__c != null;

        //ECOM-112 - garora@rafter.one - adding new fields for invoice mailing address - 12 May 2024 -starts
        mailingAdd.id = orderList[0].Default_Invoice_ERP_Address__c;
        if(orderList[0].Default_Invoice_ERP_Address__r?.ECOM_Review_Status__c=='Approved'){
            mailingAdd.city = orderList[0].Default_Invoice_ERP_Address__r.fxAddress_City__c;
            mailingAdd.country = orderList[0].Default_Invoice_ERP_Address__r.fxAddress_CountryName__c;
            mailingAdd.postalCode = orderList[0].Default_Invoice_ERP_Address__r.fxAddress_Postal__c;
            mailingAdd.state = orderList[0].Default_Invoice_ERP_Address__r.fxAddress_StateName__c;
            mailingAdd.street = orderList[0].Default_Invoice_ERP_Address__r.fxAddress_Street__c;
        } else {
            mailingAdd.city = orderList[0].Default_Invoice_ERP_Address__r?.Address_City__c;
            mailingAdd.country = orderList[0].Default_Invoice_ERP_Address__r?.apiCountry__c;
            mailingAdd.postalCode = orderList[0].Default_Invoice_ERP_Address__r?.Address_Postal_Code__c ;
            mailingAdd.state = orderList[0].Default_Invoice_ERP_Address__r?.apiState__c;
            mailingAdd.street = orderList[0].Default_Invoice_ERP_Address__r?.Address_Street_Line_1__c;
        }
        mailingAdd.companyName = orderList[0].Default_Invoice_ERP_Address__r?.fxAccountName__c;
        mailingAdd.showCompanyName = orderList[0].Default_Invoice_ERP_Address__r?.Target_Address__c != null;
        //ECOM-112 - garora@rafter.one - adding new fields for invoice mailing address - 12 May 2024 -ends

        order.billingAddress = billingAdd;
        order.shippingAddress = shippingAdd;
        order.mailingAddress = mailingAdd; //ECOM-112 - garora@rafter.one - for invoice mailing address
        // ECOM-3410 added by sathiya
        if(orderList[0]?.Default_Bill_to_ERP_Address__r?.Target_Address__c != null){
            order.vatNumber = orderList[0].Default_Bill_to_ERP_Address__r?.Target_Address__r?.ECOM_VAT_Number__c;
            order.invoiceCustId = orderList[0].Default_Bill_to_ERP_Address__r?.Target_Address__r?.ECOM_E_Invoice_Cust_Id__c;
            order.eanDoNotUse = orderList[0].Default_Bill_to_ERP_Address__r?.Target_Address__r?.ECOM_EAN_Do_Not_Use__c;
            order.emailToInvoice = orderList[0].Default_Bill_to_ERP_Address__r?.Target_Address__r?.ECOM_Email_To_Invoice__c;
        } else {
            // Mapping changes done by sathiya on 2024-04-29 for ECOM-1933 and ECOM-1942
            order.vatNumber = orderList[0].Default_Bill_to_ERP_Address__r?.ECOM_VAT_Number__c;
            order.invoiceCustId = orderList[0].Default_Bill_to_ERP_Address__r?.ECOM_E_Invoice_Cust_Id__c;
            order.eanDoNotUse = orderList[0].Default_Bill_to_ERP_Address__r?.ECOM_EAN_Do_Not_Use__c;
            // Changes end
            // Mapping changes done by sathiya on 2024-06-27 for ECOM-3389
            order.emailToInvoice = orderList[0].Default_Bill_to_ERP_Address__r?.ECOM_Email_To_Invoice__c;
            // Changes End
        }
        // Changes End for ECOM-3410
        // Mapping changes done by sathiya on 2024-04-12 for ECOM-1947
        order.einvoice1 = orderList[0]?.ECOM_E_Invoice_Code1__c == null?'':orderList[0]?.ECOM_E_Invoice_Code1__c;
        order.einvoice2 = orderList[0]?.ECOM_E_Invoice_Code2__c == null?'':orderList[0]?.ECOM_E_Invoice_Code2__c;
        order.einvoice3 = orderList[0]?.ECOM_E_Invoice_Code3__c == null?'':orderList[0]?.ECOM_E_Invoice_Code3__c;
        order.einvoice4 = orderList[0]?.ECOM_E_Invoice_Code4__c == null?'':orderList[0]?.ECOM_E_Invoice_Code4__c;
        order.einvoice5 = orderList[0]?.ECOM_E_Invoice_Cost_Center__c == null?'':orderList[0]?.ECOM_E_Invoice_Cost_Center__c;
        order.einvoice6 = orderList[0]?.ECOM_E_Invoice_Tax_Exempt__c == null?'':orderList[0]?.ECOM_E_Invoice_Tax_Exempt__c;
        order.isInvoiceMailingAddress = (orderList[0]?.Default_Invoice_ERP_Address__c != null &&
            ((orderList[0]?.Default_Invoice_ERP_Address__r?.Master_Address__c != null && orderList[0]?.Default_Invoice_ERP_Address__r?.Target_Address__c == null) ||
            (orderList[0]?.Default_Invoice_ERP_Address__r?.Master_Address__c != orderList[0]?.Default_Invoice_ERP_Address__r?.Target_Address__c
            && orderList[0]?.Default_Invoice_ERP_Address__r?.Target_Address__c != null)));

        // Changes end
        order.salesOrg = orderList[0].Default_Ship_to_ERP_Address__r.ERP_Sales_Org__c; //ECOM-1931 - mapping sales org field - Gaurang - 4 June 2024
        order.accountId = orderList[0].AccountId;
        order.accountName = orderList[0].Default_Ship_to_ERP_Address__r.fxCustomerName_Master__c; //RWPS-1306
        if(orderList[0].Default_Ship_to_ERP_Address__c != null && orderList[0].Default_Ship_to_ERP_Address__r.Target_Address__c != null){
            order.accountNumber = orderList[0].Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c;
        }
        order.createdById = orderList[0].CreatedById;
        order.createdDate = orderList[0].CreatedDate;
        order.promoCode = orderList[0].ECOM_Promo_Code__c;
        order.quoteNumber = orderList[0].ECOM_Quote_Number__c;
        order.grandTotalAmount = orderList[0].GrandTotalAmount;
        order.totalSavings = orderList[0].ECOM_Total_Savings__c;
        order.sapOrderNumber = orderList[0].ECOM_SAP_Order_Number__c;
        order.id = orderList[0].Id;
        order.currencyIsoCode = orderList[0].CurrencyIsoCode;
        order.approvalRejectionComment = orderList[0]?.ECOM_ApprovalRejection_Comment__c; //RWPS-1885

        order.totalItems = orderList[0].ECOM_Total_Items__c; //ECOM-3150 - garora@rafter.one - mapping rollup field with total quantity on order - 2 May 2024
        //RWPS-2786 - Start
         for (OrderItem item : orderList[0].OrderItems) {
            productIdSet.add(item.Product2Id);
         }

         //RWPS-3811 - START
        Set<Id> parentItemIds = new Set<Id>();
        for (OrderItem item : orderList[0].OrderItems) {
            if (item.ECOM_Parent_Item__c != null) {
                parentItemIds.add(item.ECOM_Parent_Item__c);
            }
        }
        Map<Id, CartItem> parentItemMap = ECOM_CartRepo.getParentCartItemsWithPartNumbers(parentItemIds);
         //RWPS-3811 - END

        List<String> lstNonSellableDiscontinuedProducts = ECOM_CartUtil.getNonSellableDiscountinuedProducts(productIdSet, 'both');
        List<String> lstNonSellableProducts = ECOM_CartUtil.getNonSellableDiscountinuedProducts(productIdSet, 'non_sellable'); //RWPS-4602
        //RWPS-2786- End
        //RWPS-4896-START
        Set<String> trainingProdIds = new set<String>();
        List<Product_Recommendation__c> listProductTraining = ECOM_ProductRecommendationsRepo.getRecommendationsTrainingProducts('Combination',productIdSet);
        if(listProductTraining != null && listProductTraining.size() > 0){
            for(Product_Recommendation__c productTraining : listProductTraining){  
                trainingProdIds.add(productTraining.Product_Suggested__c);

            }
        }
        //RWPS-4896-END
        //RWPS-6880 start
        Set<String> excludedPartNumbersSet = new Set<String>();
        User us = new ECOM_UserService().getUserByUserId();
        Boolean isPunchoutUser = us != null && us.ECOM_Is_Punchout_User__c;
        if (isPunchoutUser && orderList != null && !orderList.isEmpty()) {
            Set<String> partNumberSetPunchout = new Set<String>();
            for (OrderItem item : orderList[0].OrderItems) {
                if (item.Product2 != null && String.isNotBlank(item.Product2.Part_Number__c)) {
                    partNumberSetPunchout.add(item.Product2.Part_Number__c);
                }
            }
            if (!partNumberSetPunchout.isEmpty()) {
                excludedPartNumbersSet = ECOM_Util.getExcludedPartNumbersForPunchout(partNumberSetPunchout);
            }
        }
        //RWPS-6880 end
        List<ECOM_OrderModel.OrderItems> orderItemsList = new List<ECOM_OrderModel.OrderItems>();
        Map<String, String> productMediaMap = new Map<String, String>();
        for (OrderItem item : orderList[0].OrderItems) {
            ECOM_OrderModel.OrderItems orderItem = new ECOM_OrderModel.OrderItems();
            ECOM_OrderModel.Product orderProduct = new ECOM_OrderModel.Product();
            orderItem.description = item.Description;
            orderItem.earliestShippingDate = item.ECOM_OS_Expected_Ship_date__c;
            //orderItem.earliestShippingDate = item.ECOM_Earliest_Shipping_Date__c;
            orderItem.selectedShippingDate = item.ECOM_Selected_Shipping_Date__c;
            orderItem.status = item.ECOM_Order_Item_Status__c;
            orderItem.id = item.Id;
            orderItem.listPrice = item.ListPrice;
            orderItem.orderId = item.OrderId;
            orderProduct.id = item.Product2.Id;
            //RWPS-2270 START
            //orderProduct.name = item.Product2.Name;
            orderProduct.name = item.Product2.Product_Display_Name__c!=null?item.Product2.Product_Display_Name__c:item.Product2.Name;
            //RWPS-2270 END
            orderProduct.partNumber = item.Product2.Part_Number__c;
            orderProduct.displayUrl = item.Product2.DisplayUrl;
            orderItem.product = orderProduct;
            orderItem.product2Id = item.Product2Id;
            orderItem.quantity = item.Quantity;
            orderItem.totalLineAmount = item.TotalLineAmount;
            orderItem.totalPrice = item.TotalPrice;
            orderItem.type = item.Type;
            orderItem.unitPrice = item.UnitPrice;
            orderItem.tariffSurcharge = item.Tariff_Surcharge__c;//RWPS-3026
            orderItem.currencyIsoCode = orderList[0].CurrencyIsoCode; //RWPS-3026
            orderItem.parentItem = item.ECOM_Parent_Item__c; //RWPS-3811
            //RWPS-3811-Start
            if (item.ECOM_Parent_Item__c != null && parentItemMap.containsKey(item.ECOM_Parent_Item__c)) {
                    orderItem.parentPartNumber = parentItemMap.get(item.ECOM_Parent_Item__c).Product2.Part_Number__c;
            }
            //RWPS-3811-End
            //RWPS-2786 - Start
            if(lstNonSellableDiscontinuedProducts.contains(item.Product2Id)){
                orderItem.isNonSellableOrDiscontinuedProduct = true;
            } else {
                orderItem.isNonSellableOrDiscontinuedProduct = false;
            }
            // //RWPS-2786 - End
             //RWPS-4896-START
            if(trainingProdIds.contains(item.Product2Id)){
                 orderItem.isTrainingProduct = true;
            }else{
                 orderItem.isTrainingProduct = false;
            }
            //RWPS-4896 - END
            //RWPS-4602 - Start
            if(lstNonSellableProducts.contains(item.Product2Id)){
                orderItem.isNonSellableProduct = true;
            } else {
                orderItem.isNonSellableProduct = false;
            }
            if(lstNonSellableDiscontinuedProducts.contains(item.Product2Id) && lstNonSellableProducts.contains(item.Product2Id) == false) {
                orderItem.isDiscontinuedProduct = true;
            } else {
                orderItem.isDiscontinuedProduct = false;
            }
            //RWPS-4602 - End
            // RWPS-6880 start     
            if (orderProduct != null && String.isNotBlank(orderProduct.partNumber) && excludedPartNumbersSet.contains(orderProduct.partNumber)) {               
                orderItem.isExcludedProduct = true;
            } else {
                orderItem.isExcludedProduct = false;
            }
            // RWPS-6880 end
        
            orderItemsList.add(orderItem);
            //RWPS-622
            if(!isLargePackShippingOrder && (item.Product2.Item_Class__c=='1' || item.Product2.Item_Class__c=='2')){
                isLargePackShippingOrder = true;
            }
            productMediaMap.put(item.Id, (item?.Product2?.ECOM_Product_Media_URI__c != null)?item?.Product2?.ECOM_Product_Media_URI__c:'');
        }
        for(OrderDeliveryGroup od : orderList[0].OrderDeliveryGroups){
            order.shippingInstructions = od.ECOM_Special_Instructions__c;
            order.deliveryDetails = od.DeliveryInstructions;
            if(od.DeliverToName != 'Deliver to'){
            	order.attentionRecipient = od.DeliverToName;
        	}
        }

        order.orderItems = orderItemsList;
        order.orderNumber = orderList[0].OrderNumber;
        order.ownerId = orderList[0].OwnerId;
        order.poNumber = orderList[0].PoNumber;
        order.salesStoreId = orderList[0].SalesStoreId;
        order.status = orderList[0].ECOM_Order_Summary_Status__c;
        order.totalAmount = orderList[0].TotalAmount;
        order.totalTariffSurcharge = orderList[0].Total_Tariff_Surcharge__c;//RWPS-3026
        order.totalTaxAmount = orderList[0].TotalAdjustedProductTaxAmount;
        order.totalShippingAmount = orderList[0].TotalAdjDeliveryAmtWithTax - order.totalTariffSurcharge;//RWPS-3026
        order.totalProdAmount = orderList[0].TotalAdjustedProductAmount;
		//RWPS-622
        order.isLargePackShipingOrder = isLargePackShippingOrder;
        if(order.sapOrderNumber != null){
            SAP_Order_Summary__c sapOrder = ECOM_OrderRepo.fetchOrdersBySAPOrderNumber(order.sapOrderNumber);
            if(sapOrder != null){
                List<SAP_Order_Items__c> sapOrderItems = sapOrder.SAP_Order_Items__r;
                for (Integer i = 0; i < sapOrderItems.size(); i++) {
                    SAPOrderItemIds.add(sapOrderItems[i].Id);
                }
            }
        }

        Map<String,List<ECOM_OrderModel.OrderItemTracking>> itemTrackings = new Map<String,List<ECOM_OrderModel.OrderItemTracking>>();
        //fetch SAP order Item Tracking
        if(SAPOrderItemIds != null){
            Map<String, List<ECOM_OrderModel.OrderItemTracking>> itemToTrackings = new Map<String, List<ECOM_OrderModel.OrderItemTracking>>();
            List<SAP_Order_Item_Tracking__c> trackings = ECOM_SAPOrderSummaryService.getSAPOrderItemTrackings(SAPOrderItemIds);
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
                tracking.partNumber = tr.fxMaterialNumber__c;
                tracking.productName = tr.fxMaterialDescription__c;
                tracking.productMediaURI = productMediaMap.get(tr.PKIOrderItems__r.Order_Product__c);
                tracking.quantityOrdered = tr.PKIOrderItems__r.Quantity_Ordered__c;
                tracking.orderItem = tr.PKIOrderItems__r.Order_Product__c;
                orderItemTrackings.add(tracking);
                if(itemToTrackings.get(tr.PKIOrderItems__c) == null){
                    itemToTrackings.put(tr.PKIOrderItems__c, new List<ECOM_OrderModel.OrderItemTracking>());
                }
                itemToTrackings.get(tr.PKIOrderItems__c).add(tracking);
            }


            //Assign SAP order item trackings to related order item
            Integer count = 0;
            if(itemToTrackings != null && itemToTrackings.size() > 0){
                for(ECOM_OrderModel.OrderItems oi: order.orderItems){
                    for(String saporderItemId :SAPOrderItemIds){
                        if(itemToTrackings.get(saporderItemId) != null && itemToTrackings.get(saporderItemId).size() > 0 &&
                           //itemToTrackings.get(saporderItemId)[0].partNumber == oi.product.partNumber
                           itemToTrackings.get(saporderItemId)[0].orderItem == oi.Id
                          ){
                            if(itemTrackings.get(oi.id) == null){
                            	itemTrackings.put(oi.id,new List<ECOM_OrderModel.OrderItemTracking>());
                            }
                            oi.OrderItemTrackings = itemToTrackings.get(saporderItemId);
                            itemTrackings.put(oi.id, itemToTrackings.get(saporderItemId));

                            break;
                        }
                        System.debug('trackings map==' +itemTrackings);
                    }
                }
            }
        }
        order.itemTrackings = itemTrackings;
		System.debug('Order model with values == '+order);
        return order;
    }

    public static ECOM_FormWrapper.AddressInfo setupAddressData(OrderItem orderItem)
    {
        ECOM_FormWrapper.AddressInfo addressInfo=new ECOM_FormWrapper.AddressInfo();
        addressInfo.line=orderItem.Order.ShippingStreet;
        addressInfo.city=orderItem.Order.ShippingCity;
        addressInfo.state=orderItem.Order.ShippingState;
        addressInfo.country=orderItem.Order.ShippingCountry;
        addressInfo.postal=orderItem.Order.ShippingPostalCode;
        return addressInfo;
    }

    public static ECOM_FormWrapper.OrderInfo setupOrderData(OrderItem orderItem)
    {
        ECOM_FormWrapper.OrderInfo orderInfo=new ECOM_FormWrapper.OrderInfo();
        orderInfo.quantity=orderItem.Quantity;
        orderInfo.partNumber=orderItem.Product2.Part_Number__c;

        if(String.isNotBlank(orderItem.OrderId))
            orderInfo.status=orderItem.Order.ECOM_Order_Summary_Status__c;

        if(String.isBlank(orderItem.Order.ECOM_SAP_Order_Number__c))
        {
            orderInfo.number_replace='';
        }
        else
        {
            orderInfo.number_replace=orderItem.Order.ECOM_SAP_Order_Number__c;
        }

        if(orderItem.Order.OrderedDate==null)
        {
            orderInfo.date_replace=orderItem.CreatedDate;
        }
        else
        {
            orderInfo.date_replace=orderItem.Order.OrderedDate;
        }

        orderInfo.webLineNumber=orderItem.LineNumber;
        orderInfo.webOrderNumber=orderItem.Order.OrderNumber;

        if(String.isNotBlank(orderItem.Order.Default_Bill_to_ERP_Address__c) && String.isNotBlank(orderItem.Order.Default_Bill_to_ERP_Address__r.Target_Address__c)
            && String.isNotBlank(orderItem.Order.Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c))
        {
            orderInfo.payer=orderItem.Order.Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c;
        }
        else{
            orderInfo.payer=orderItem.Order.Default_Bill_to_ERP_Address__c;
        }

        if(String.isNotBlank(orderItem.Order.Default_Ship_to_ERP_Address__c) && String.isNotBlank(orderItem.Order.Default_Ship_to_ERP_Address__r.Target_Address__c)
            && String.isNotBlank(orderItem.Order.Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c))
        {
            orderInfo.soldTo=orderItem.Order.Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c;
            orderInfo.contactNumber=getContactNumber(orderItem.Order.Default_Ship_to_ERP_Address__r.Target_Address__c);
        }
        else
        {
            orderInfo.soldTo=orderItem.Order.Default_Ship_to_ERP_Address__c;
            orderInfo.contactNumber='';
        }

        if(String.isNotBlank(orderItem.ECOM_SAP_Order_Items__c) && String.isNotBlank(orderItem.ECOM_SAP_Order_Items__r.Line_Item_Number_SAP__c))
        {
            orderInfo.line=orderItem.ECOM_SAP_Order_Items__r.Line_Item_Number_SAP__c;
        }
        else
        {
            orderInfo.line='';
        }
        orderInfo.contactNumber=''; //From where to get this

        return orderInfo;


    }

    public static String getContactNumber(String shipToId)
    {
        String returnVal='';
        User us = new ECOM_UserService().getUserByUserId();
         System.debug('us'+us);
        System.debug('us.contactId'+us.contactId);
        List<ERP_RelationShip__c> erpRelationships=ERP_AddressRepo.fetchERPRelationshipsByContactId(us.contactId);
        System.debug('erpRelationships'+erpRelationships);
        if(!erpRelationships.isEmpty())
        {
            if(erpRelationships.size()==1)
            {
                returnVal=erpRelationships[0].Name;
            }
            else
            {
                for(ERP_RelationShip__c erps:erpRelationships)
                {
                    if(erps.ERP_Address__c==shipToId)
                    {
                        returnVal=erps.Name;
                        break;
                    }
                }
            }
        }
        else
        {
            returnVal='';
        }
        return returnVal;
    }

    /**
     * @description This method returns a list of wrapped order details
     * @author vramachandran@rafter.one | 12 Dec 2023
     * @param orderList | List<Order>
     * @return List<ECOM_OrderModel>
     */
    public static List<ECOM_OrderModel> getOrderModelList(List<Order> orderList){
        List<ECOM_OrderModel> orderModelList = new List<ECOM_OrderModel>();

        //check if null and loop through order list and map details
        if(orderList != null && !orderList.isEmpty()){
            for(Order orderRecord: orderList){
                ECOM_OrderModel orderModel = new ECOM_OrderModel();
                orderModel.id = orderRecord?.Id;
                orderModel.ownerId = orderRecord?.OwnerId;
                orderModel.orderNumber = orderRecord?.OrderNumber;
                orderModel.createdDate = orderRecord?.CreatedDate;
                orderModel.createdById = orderRecord?.CreatedById;
                orderModel.originalOrderId = orderRecord?.OriginalOrderId;
                orderModel.accountId = orderRecord?.AccountId;
                orderModel.sapOrderNumber = orderRecord?.ECOM_SAP_Order_Number__c;
                orderModel.effectiveDate = orderRecord?.EffectiveDate;
                orderModel.totalAmount = orderRecord?.TotalAmount;
                orderModel.totalTariffSurcharge = orderRecord?.Total_Tariff_Surcharge__c;//RWPS-3026
                orderModel.grandTotalAmount = orderRecord?.GrandTotalAmount;
                orderModel.orderedDate = orderRecord?.OrderedDate;
                orderModel.status = orderRecord?.ECOM_Order_Summary_Status__c;
                orderModel.description = orderRecord?.Description;
                orderModel.salesStoreId = orderRecord?.SalesStoreId;
                orderModel.poNumber = orderRecord?.PoNumber;
                orderModel.billToContactId = orderRecord?.BillToContactId;
                orderModel.pricebook2Id = orderRecord?.Pricebook2Id;
                orderModel.currencyIsoCode = orderRecord?.CurrencyIsoCode;

                //map order items
                orderModel.orderItems = getOrderItemlist(orderRecord?.orderItems);

                //add to list
                orderModelList.add(orderModel);
            }
        }

        return orderModelList;
    }

    /**
     * @description This method returns a list of wrapped order items
     * @author vramachandran@rafter.one | 12 Dec 2023
     * @param orderItemList | List<OrderItem>
     * @return List<ECOM_OrderModel.OrderItems>
     */
    public static List<ECOM_OrderModel.OrderItems> getOrderItemlist(List<OrderItem> orderItemList){
        List<ECOM_OrderModel.OrderItems> orderItemModelList = new List<ECOM_OrderModel.OrderItems>();

        if(orderItemList != null && !orderItemList.isEmpty()){
            for(OrderItem orderItemRecord : orderItemList){
                ECOM_OrderModel.OrderItems newOrderItem = new ECOM_OrderModel.OrderItems();
                newOrderItem.id = newOrderItem?.Id;
                newOrderItem.orderId = newOrderItem?.OrderId;
                newOrderItem.product2Id = newOrderItem?.Product2Id;
                newOrderItem.quantity = newOrderItem?.Quantity;
            }
        }

        return orderItemModelList;
    }

    /**
     * @description This method returns a list of Field Mapping based on available values
     * @author sveeraraghavan@rafter.one | 24 May 2024
     * @param ECOM_OrderModel | String
     * @return List<Map<String, String>>
     */
    public static List<Map<String, String>> getFieldMappingByType(ECOM_OrderModel orderModel, String mdtLabelType){
        List<Map<String, String>> responseList = new List<Map<String, String>>();
        if(String.isNotBlank(orderModel?.billingAddress?.country)){
            String country = orderModel?.billingAddress?.country.toLowerCase();
            string configStr = ECOM_CustomMetadataService.getStoreConfigurationByLabel(mdtLabelType);
            Map<String,Object> orderObjConvert =  (Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(orderModel));
            for(Object orderObj: (List<Object>)JSON.deserializeUntyped(configStr)){
                Map<String, Object> configMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(orderObj));
                Map<String, Object> validationMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(configMap.get(ECOM_Constant.API_VALIDATION)));
                if(validationMap.containsKey(country) && String.isNotBlank((String)orderObjConvert.get((String)configMap.get(ECOM_Constant.API_FIELDNAME)))){
                    Map<String, Object> countryMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(validationMap.get(country)));
                    responseList.add(new Map<String, String>{ ECOM_Constant.API_LABEL => (String)countryMap.get(ECOM_Constant.API_DISPLABEL), ECOM_Constant.API_VALUE => (String)orderObjConvert.get((String)configMap.get(ECOM_Constant.API_FIELDNAME))});
                }
                if(validationMap.containsKey('default') && String.isNotBlank((String)orderObjConvert.get((String)configMap.get(ECOM_Constant.API_FIELDNAME)))){
                    Map<String, Object> countryMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(validationMap.get('default')));
                    responseList.add(new Map<String, String>{ ECOM_Constant.API_LABEL => (String)countryMap.get(ECOM_Constant.API_DISPLABEL), ECOM_Constant.API_VALUE => (String)orderObjConvert.get((String)configMap.get(ECOM_Constant.API_FIELDNAME))});
                }
            }
        }
        return responseList;
    }

}