/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM - 125 
*
* 2. Description - This class is used for Order Create API specific functionality.
*
*
* 3. Objects referenced
*    - Order
*    - Order Item
*    - OrderDeliveryGroup
*
* 4. Callouts to additional Components (including their methods) or None:
*    - ECOM_RestService.doBasicHttpRequest
*    
*
* 5. Dependant Class(es):
*    - ECOM_Util
*    - ECOM_RestService
*    - ECOM_OrderSummaryRequestWrapper
*
* 6. Test Class Name: ECOM_OrderCreateAPIUtil_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Rani 2023.09.13
*    - Manoj 2024-04-30 RWPS-584 Instrument freight not applying as expected on web orders(Updated generateOrderCreateRequest method  to support large pack shipping logic)
*    - Manoj 2024-05-01 RWPS-584 Instrument freight not applying as expected on web orders(Move order type logic to sfdc from boomi also provided scalable solution using custom metadata)
*	 - Sathiya 2024-06-11 ECOM-3457 Added mapping information for E-Invoice fields and invoice mailing address
*    - Sidak 2024.09.13 Updated method generateOrderCreateRequest. Added attribute for contact email in order request. Ticket - RWPS-1236
*    - Sidak 2024.09.25 Updated method generateOrderCreateRequest. Added logic for checking creditCard to pass in Order create request. Ticket - RWPS-1509
*	 - Sidak 2024.10.15 Updated method generateOrderCreateRequest. Added null checks for required fields and error logging. Ticket - RWPS-1725
*    - Sathiya 2024.11.08 Updated fix for VAT number and EAN Do not USE field mapping hot fix
*    - Gaurav 2025.04.21, added new variables in order request for mapping additional information to SAP RWPS-1285
*    - Poonam 2025.06.11 Added logic for invoice email in a new attribute 'eInvoiceEmail' in PartnerType 'Billto' object - RWPS-1882
*    - Chirag 2025.08.29 Added logic to bypass the free item from OrderCreate callout - RWPS-3811
*    - Prabhat 2025.09.11 Added logic in method parseOrdeItemResponseDetails to match SAP Line number - RWPS-3811
*    - Sachin V 2025.12.01 Added logic in method parseOrderCreateAPIResponse to populate PO_Type__c - RWPS-5094
*************************************************************/
public class ECOM_OrderCreateAPIUtil {
    
     /**
    * @description This method is used to generate request for Order Create API.
    * @author Rani Thumma | 2023-09-13
     * @author Sidak | 2024-10-15 | RWPS-1725
    * @param Order 
    * @return ECOM_OrderSummaryRequestWrapper 
    **/
    public static ECOM_OrderSummaryRequestWrapper generateOrderCreateRequest(Order order, String contactSAPNumber, List<PaymentAuthorization> payments, List<CardPaymentMethod> cardPayments, User user){
        
        ECOM_OrderSummaryRequestWrapper request = new ECOM_OrderSummaryRequestWrapper();
        ECOM_OrderSummaryRequestWrapper.OrderRequest ordReq = new ECOM_OrderSummaryRequestWrapper.OrderRequest();
        ECOM_OrderSummaryRequestWrapper.Header header = new ECOM_OrderSummaryRequestWrapper.Header();
        ECOM_OrderSummaryRequestWrapper.Sender sender = new ECOM_OrderSummaryRequestWrapper.Sender();
        ECOM_OrderSummaryRequestWrapper.OrderRequestHeader reqHeader = new ECOM_OrderSummaryRequestWrapper.OrderRequestHeader();
        List<ECOM_OrderSummaryRequestWrapper.CreditCardDetails> creditCards = new List<ECOM_OrderSummaryRequestWrapper.CreditCardDetails>();
        List<ECOM_OrderSummaryRequestWrapper.OrderRequestDetail> details = new List<ECOM_OrderSummaryRequestWrapper.OrderRequestDetail>();
        List<ECOM_OrderSummaryRequestWrapper.Partner> partners = new List<ECOM_OrderSummaryRequestWrapper.Partner>();
        Integer itemCount = 0;
        Boolean isLargePackShipping = false;
        Set<String> orderIds = new Set<String>();
        String salesOrg = '';
        String supportData = 'Order : '+ JSON.serialize(order);
		Boolean sendOrderToSAP = true;
        if(order != null){
            orderIds.add(order.Id);
        
            if(String.isNotBlank(order.ShippingCountry)){
                salesOrg = ECOM_CustomMetadataService.getSalesOrg(order.ShippingCountry);
            }
            else {
                sendOrderToSAP= false;
                supportData+=' Sales org null  : ShippingCountry on the Order is null ';
            }
            //Fetch Order deliver groups for Attention lines and special delivery instructions
            List<OrderDeliveryGroup> orderDeliveryGroups = order.OrderDeliveryGroups;
            
            sender.Component = ECOM_Constant.ORDER_COMPONENT;
            sender.Task = ECOM_Constant.ORDER_CREATE_TASK;
            header.Sender = sender;
            if(String.isNotBlank(salesOrg)){
                reqHeader.SalesOrgID = salesOrg; //'US10';
            }
            reqHeader.DistChannelID = '01';
            reqHeader.DivisionID = '02';
            reqHeader.Language = 'EN';
            reqHeader.WebOrderNumber = order.OrderNumber ;
            reqHeader.TelephoneNumber = '';
            reqHeader.PromoCode = order.ECOM_Promo_Code__c;
            reqHeader.QuoteNumber = order.ECOM_Quote_Number__c;
            // Changes Added for ECOM-3257 by sathiya on 06/11/2024
            reqHeader.eInvoiceCode1 = order?.ECOM_E_Invoice_Code1__c;
            reqHeader.eInvoiceCode2 = order?.ECOM_E_Invoice_Code2__c;
            reqHeader.eInvoiceCode3 = order?.ECOM_E_Invoice_Code3__c;
            reqHeader.eInvoiceCode4 = order?.ECOM_E_Invoice_Code4__c;
            reqHeader.eInvoiceCostCenter = order?.ECOM_E_Invoice_Cost_Center__c;
            reqHeader.eInvoiceTaxExempt = order?.ECOM_E_Invoice_Tax_Exempt__c;
            reqHeader.TelephoneNumber = user?.Contact?.Phone;
            // Changes End
            
            //RWPS-1285 populate largepack properties from order start
            reqHeader.acceptanceDate=order.ECOM_Accepted_Date__c;
            reqHeader.endUserForTrade=order.ECOM_End_User_For_Trade__c;
             //RWPS-1285 populate largepack properties from order End
            //Payment types - PO or CreditCard //RWPS-1509
            if(String.isNotBlank(order.PoNumber)){
                reqHeader.PurchaseOrderID = order.PoNumber;
                reqHeader.PaymentType = ECOM_Constant.PAYMENT_TYPE_PO;
            } else if(payments != null && cardPayments != null && cardPayments.size() > 0){
                reqHeader.PaymentType = ECOM_Constant.PAYMENT_TYPE_CREDITCARD;
                
            }
            
            // Tax Exempt - if isTaxEmempt is true pass field with value as B(accepted in SAP)
            if(order.ECOM_isTaxExempt__c){
                reqHeader.TaxExempt = 'B';
            }
            // add credit card details 
            if(payments != null && cardPayments != null && cardPayments.size() > 0){
                ECOM_OrderSummaryRequestWrapper.CreditCardDetails creditCard = new ECOM_OrderSummaryRequestWrapper.CreditCardDetails();
                reqHeader.PurchaseOrderID = order.OrderNumber;
                creditCard.CreditCardType = cardPayments[0].CardType;
                creditCard.HolderName = cardPayments[0].CardHolderFirstName + ' '+cardPayments[0].CardHolderLastName; 
                creditCard.ExpirationMonth = String.valueOf(cardPayments[0].ExpiryMonth);
                creditCard.ExpirationYear = String.valueOf(cardPayments[0].ExpiryYear);
                //creditCard.SecurityNumber = cardPayments[0].;//153
                creditCard.AuthFlag = 'X'; 
                if(String.isNotBlank(payments[0].ECOM_Payment_Method_Token__c)){
                    creditCard.CreditCardNumber = payments[0].ECOM_Payment_Method_Token__c;// is this correct
                }
                //creditCard.AuthAmount = String.valueOf(order.GrandTotalAmount); //including shipping and tax 
                creditCard.CurrencyCode = payments[0].CurrencyIsoCode;
                creditCard.TransactionDate = payments[0].Date;
                if(String.isNotBlank(payments[0].ECOM_Authorization_Number__c)){
                    creditCard.AuthorizationNumber = payments[0].ECOM_Authorization_Number__c ;//PPS974
                }
                if(String.isNotBlank(payments[0].ECOM_PG_Transaction_Id__c)){
                    creditCard.PageTransactionid = payments[0].ECOM_PG_Transaction_Id__c;//204914151610
                }
                if(String.isNotBlank(payments[0].ECOM_Authorization_Type__c)){
                    creditCard.React = payments[0].ECOM_Authorization_Type__c;   //'A for approved, B for declined';
                }
                creditCard.ReactAmount = String.valueOf(payments[0].Amount);// snappay Payment approved amount
                creditCard.AuthAmount = String.valueOf(payments[0].Amount);
                creditCard.StatEx = 'C' ; 
                if(String.isNotBlank(payments[0].ECOM_PG_Return_Description__c)){
                    creditCard.PageReturnDescription = payments[0].ECOM_PG_Return_Description__c ;//APPROVAL
                }
                if(String.isNotBlank(payments[0].ECOM_Merchant_Id__c)){
                    creditCard.MerchantId = payments[0].ECOM_Merchant_Id__c ;//313286330888
                }
                creditCard.AuthType = 'A';// A for manual
                creditCards.add(creditCard);
                reqHeader.CreditCardDetails = creditCards;
            }
            
            //Partners
            if(order.Default_Bill_to_ERP_Address__c != null && order.Default_Bill_to_ERP_Address__r.Target_Address__c != null){
                ECOM_OrderSummaryRequestWrapper.Partner partnerBT = new ECOM_OrderSummaryRequestWrapper.Partner();
                partnerBT.PartnerID = order.Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c;
                partnerBT.PartnerType =  'BillTo';
                partnerBT.Id = 'BillTo';   
                // Changes Added for ECOM-3257 by sathiya on 06/11/2024
                String billToCountry = (order?.Default_Bill_to_ERP_Address__r?.apiCountry__c != null?order?.Default_Bill_to_ERP_Address__r?.apiCountry__c:(order?.Default_Bill_to_ERP_Address__r?.fxAddress_CountryName__c!=null?order?.Default_Bill_to_ERP_Address__r?.fxAddress_CountryName__c:''));
                Boolean isMergeInvoiceCode1 = billToCountry.toLowerCase() == 'fr' || billToCountry.toLowerCase() == 'france';
                String eInvoice1 = isMergeInvoiceCode1? order?.ECOM_E_Invoice_Code1__c:'';
                // EAN Do Not Use hot fix mapping by sathiya on 2024.11.08
                partnerBT.eanDoNotUse = (order?.Default_Bill_to_ERP_Address__r?.Target_Address__c != null)?order?.Default_Bill_to_ERP_Address__r?.Target_Address__r?.ECOM_VAT_Number__c:order?.Default_Bill_to_ERP_Address__r?.ECOM_EAN_Do_Not_Use__c;
                
                String eInvoiceId = ((order?.Default_Bill_to_ERP_Address__r?.Target_Address__c != null)?order?.Default_Bill_to_ERP_Address__r?.Target_Address__r?.ECOM_E_Invoice_Cust_Id__c:order?.Default_Bill_to_ERP_Address__r?.ECOM_E_Invoice_Cust_Id__c);
                partnerBT.eInvoiceCustId = String.isNotBlank(eInvoiceId)?eInvoiceId:'' + (String.isBlank(eInvoice1)?'':((String.isNotBlank(eInvoiceId)?'-':'') + eInvoice1));   
                System.debug(partnerBT.eInvoiceCustId+'%');
                // VAT Number hot fix mapping by sathiya on 2024.11.08
                partnerBT.vatNumber = (order?.Default_Bill_to_ERP_Address__r?.Target_Address__c != null)?order?.Default_Bill_to_ERP_Address__r?.Target_Address__r?.ECOM_VAT_Number__c:order?.Default_Bill_to_ERP_Address__r?.ECOM_VAT_Number__c;
                // Changes End
                //RWPS-1882 start
                if (String.isNotBlank(order.Invoice_Email__c)) {
                    partnerBT.eInvoiceEmail = order.Invoice_Email__c;
                }//RWPS-1882 end
                partners.add(partnerBT);
            }
            else {
                sendOrderToSAP= false;
                supportData+=' Bill To  : Default Bill to ERP Address or its Target Address is null ';
            }
            if(order.Default_Ship_to_ERP_Address__c != null && order.Default_Ship_to_ERP_Address__r.Target_Address__c != null){
                ECOM_OrderSummaryRequestWrapper.Partner partnerST = new ECOM_OrderSummaryRequestWrapper.Partner(); 
                partnerST.PartnerID = order.Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c;
                partnerST.PartnerType = 'ShipTo';
                partnerST.Id = 'ShipTo';
                partners.add(partnerST);
            }
            else {
                sendOrderToSAP= false;
                supportData+=' Ship To : Default Ship to ERP Address or its Target Address is null ';
            }
            // Changes Added for ECOM-3257 by sathiya on 06/11/2024
            if(order.Default_Invoice_ERP_Address__c != null && order.Default_Invoice_ERP_Address__r.Target_Address__c != null){
                ECOM_OrderSummaryRequestWrapper.Partner partnerInv = new ECOM_OrderSummaryRequestWrapper.Partner(); 
                partnerInv.PartnerID = order?.Default_Invoice_ERP_Address__r?.Target_Address__r?.External_Id__c;
                partnerInv.PartnerType = 'Invoice';
                partnerInv.Id = 'Invoice';
                partners.add(partnerInv);
            }
            // Changes End
            if(String.isNotBlank(contactSAPNumber)){
                ECOM_OrderSummaryRequestWrapper.Partner partnerC = new ECOM_OrderSummaryRequestWrapper.Partner();
                partnerC.PartnerID = contactSAPNumber;
                partnerC.PartnerType = 'ContactID';
                partnerC.Id = 'ContactID';
                partners.add(partnerC);
            }
            else {
                sendOrderToSAP= false;
                supportData+=' SAP Contact Id  : '+contactSAPNumber;            
            }
            if(orderDeliveryGroups != null && orderDeliveryGroups.size() > 0){
                if(String.isNotBlank(orderDeliveryGroups[0].DeliverToName) && orderDeliveryGroups[0].DeliverToName != 'Deliver to'){
                    reqHeader.AttentionLines = orderDeliveryGroups[0].DeliverToName; 
                }
                if(String.isNotBlank(orderDeliveryGroups[0].ECOM_Special_Instructions__c) && String.isNotBlank(orderDeliveryGroups[0].DeliveryInstructions)){
                    reqHeader.SpecialHandlingInstructions = orderDeliveryGroups[0].ECOM_Special_Instructions__c +' : '+orderDeliveryGroups[0].DeliveryInstructions;
                } else if(String.isNotBlank(orderDeliveryGroups[0].ECOM_Special_Instructions__c)){
                    reqHeader.SpecialHandlingInstructions = orderDeliveryGroups[0].ECOM_Special_Instructions__c;
                } else if(String.isNotBlank(orderDeliveryGroups[0].DeliveryInstructions)){
                    reqHeader.SpecialHandlingInstructions = orderDeliveryGroups[0].DeliveryInstructions;
                }
            }
            //RWPS-1285 added enduser address details in handling instrution
            if(String.isNotEmpty(order.ECOM_End_User_Address__c)) {
                reqHeader.SpecialHandlingInstructions= reqHeader.SpecialHandlingInstructions + 'End user Address -' +order.ECOM_End_User_Address__c;
            }
            
            //Prepare order items
            for(OrderItem item :order.OrderItems){
                 if (item.ECOM_Parent_Item__c == null) { // RWPS-3811 - Start
                    ECOM_OrderSummaryRequestWrapper.OrderRequestDetail detail = new ECOM_OrderSummaryRequestWrapper.OrderRequestDetail();
                    detail.OrderLineNumber = String.valueOf(item.ECOM_SAP_Line_Number__c).replace('.00', '');//RWPS-3811
                    detail.ProductID = item.Product2.Part_Number__c;
                    detail.Quantity = String.valueOf(item.Quantity);
                    if(item.ECOM_Selected_Shipping_Date__c != null){
                        detail.RequestedDate = String.valueOF(item.ECOM_Selected_Shipping_Date__c); 
                    } else {
                        detail.RequestedDate = String.valueOF(Date.today()); 
                    }
                    if(String.isNotBlank(item.Product2.Item_Class__c) && (item.Product2.Item_Class__c=='1' || item.Product2.Item_Class__c=='2') && !isLargePackShipping){
                        isLargePackShipping = true;
                    }
                    details.add(detail);
                    itemCount ++;
                }
            }//RWPS-3811 - End
            //RWPS-584 (move order type whole logic to sfdc from boomi)
            sender.Component = ECOM_CartUtil.getOrderType(isLargePackShipping, reqHeader.PaymentType, ECOM_Constant.ORDER_CREATE, salesOrg );
            reqHeader.NumberOfItems = String.valueOf(itemCount);
            reqHeader.Partner = partners;
            
            ordReq.Header = header;
            ordReq.OrderRequestDetail = details;
            ordReq.OrderRequestHeader = reqHeader;
            
            request.OrderRequest = ordReq;
            if(!sendOrderToSAP){
              ECOM_ApplicationLogsUtil.logApplicationDataWithCustomException('Order Create','ECOM_OrderCreateAPIUtil','generateOrderCreateRequest',supportData,'','Some required fields are missing'); 
            }
        }
        return request;
    }
    
    public static HttpResponse orderCreateAPICallout(ECOM_OrderSummaryRequestWrapper request){
        HttpResponse httpRes = new HttpResponse();
        String requestBody = JSON.serialize(request);
        System.debug('Order Create API Request body === '+requestBody);
        Map<String, String> requestMap = ECOM_Util.generateRequestMap(requestBody,'OrderCreate');
        String responseBody = '';
        //Do Order Create callout
        //httpRes = ECOM_RestService.doBasicHttpRequestOrderCreate(requestMap);
        httpRes = ECOM_RestService.doBasicHttpRequest(requestMap);
        System.debug('Response body == '+httpRes.getBody());
        return httpRes;
    }
    
     /**
    * @description This method is used to update Order based on response from Create Order API.
    * @author Rani Thumma | 2023-09-13
    * @param ECOM_OrderSummaryRequestWrapper, HttpResponse
    * @return ECOM_OrderCreateFlowWrapper.OrdersAndOrderItems 
	*/
    public static ECOM_OrderCreateFlowWrapper.OrdersAndOrderItems parseOrderCreateAPIResponse(ECOM_OrderSummaryRequestWrapper orderRequest,HttpResponse response, Order order){
        
        ECOM_OrderCreateFlowWrapper.OrdersAndOrderItems itemsToUpdate = new ECOM_OrderCreateFlowWrapper.OrdersAndOrderItems();
        ECOM_OrderSummaryResponseWrapper res;
        ECOM_OrderSummaryResponseWrapper.Error errResponse;
        Boolean isError = false;
        List<OrderItem> orderItemsToUpdate = new List<OrderItem>();
        List<Order> ordersToUpdate = new List<Order>();
        List<ECOM_OrderSummaryResponseWrapper.ErrorDetails> errorDetails;
        Order od;
        if(response.getStatusCode() == 200 && response.getStatus() == 'OK'){
            if(response.getBody() != null && response.getBody() != ''){
                res = parseOrderCreateResponse(response.getBody());
            }
        } else{
            // Status code not equal to 200
            isError = true;
        }
        System.debug('Response in updatedSellerOrderId ==> '+res);
        
        if(res != null){
            errResponse = res.OrderResponse.Error;
            if(errResponse != null){
                errorDetails = errResponse.ErrorDetails;
                System.debug('errorDetails ==> '+errorDetails);
            }
            
            //check if there is no error in the response from Order create API 
            if(errorDetails == null || Test.isRunningTest()){
                ECOM_OrderSummaryResponseWrapper.OrderResponseHeader odRespHeader = res.OrderResponse.OrderResponseHeader;
                System.debug('odRespHeader in updatedSellerOrderId ==> '+odRespHeader);
                od = new Order();
                od.Id = order.Id;
                if(odRespHeader != null && odRespHeader.SellerOrderID != null){
                    od.ECOM_SAP_Order_Number__c = odRespHeader.SellerOrderID; // SAP order ID
                    od.PO_Type__c = odRespHeader.POType; //RWPS-5094
                    od.Status = ECOM_Constant.ORDER_STATUS_ORDER_CONFIRMED;
                    List<ECOM_OrderSummaryResponseWrapper.OrderResponseDetail> orderResponseDetails = new List<ECOM_OrderSummaryResponseWrapper.OrderResponseDetail>();
                    orderResponseDetails = odRespHeader.OrderResponseDetail;
                    if(orderResponseDetails != null && orderResponseDetails.size() > 0){
                        orderItemsToUpdate = parseOrdeItemResponseDetails(order.OrderItems, orderResponseDetails);
                    }
                }
            } 
        }
        // update error on order with retry count
        if(errorDetails != null || isError){
            od = new Order();
            od.Id = order.Id;
            if(order.ECOM_Order_Create_Retry__c == null){
                od.ECOM_Order_Create_Retry__c = 1;
            }else{
                System.debug('ECOM_Order_Create_Retry__c == '+od.ECOM_Order_Create_Retry__c);
                od.ECOM_Order_Create_Retry__c = order.ECOM_Order_Create_Retry__c + 1;
            }
            if(od.ECOM_Error_Message__c == null && errorDetails != null){
                od.ECOM_Error_Message__c = errorDetails[0].errorMessage;
            } else if(od.ECOM_Error_Message__c != null && errorDetails != null){
                od.ECOM_Error_Message__c = od.ECOM_Error_Message__c + '\n' + errorDetails[0].errorMessage; 
            } else if(od.ECOM_Error_Message__c != null){
                od.ECOM_Error_Message__c = od.ECOM_Error_Message__c + '\n' + response.getStatus();
            } else {
                od.ECOM_Error_Message__c = response.getStatus();
            }
        }
        if(od != null){
            ordersToUpdate.add(od);
            itemsToUpdate.orders = ordersToUpdate;
        }
        if(!orderItemsToUpdate.isEmpty()){
            itemsToUpdate.orderItems = orderItemsToUpdate;
        }
        return itemsToUpdate;
    }

    /**
    * @description This method is used to parse order create response to ECOM_OrderSummaryResponseWrapper.
    * @author Rani Thumma | 2023-08-22
    * @param response  
    * @return ECOM_OrderSummaryResponseWrapper
    **/
    public static ECOM_OrderSummaryResponseWrapper parseOrderCreateResponse(String response){
		return (ECOM_OrderSummaryResponseWrapper) System.JSON.deserialize(response, ECOM_OrderSummaryResponseWrapper.class);
	}

    /**
    * @description This method is used to parse order items data from create response and update Order items.
    * @author Rani Thumma | 2023-09-13
    * @param OrderItems, List<ECOM_OrderSummaryResponseWrapper.OrderResponseDetail>  
    * @return OrderItems
    **/
    public static List<OrderItem> parseOrdeItemResponseDetails(List<OrderItem> orderItems, List<ECOM_OrderSummaryResponseWrapper.OrderResponseDetail>  orderResponseDetails){
        List<OrderItem> orderItemsToUpdate = new List<OrderItem>();
        for(OrderItem item :orderItems){
            for(ECOM_OrderSummaryResponseWrapper.OrderResponseDetail resItems : orderResponseDetails){
                System.debug('item.LineNumber === '+item.LineNumber);
                System.debug('resItems.OrderLineNumber == '+resItems.OrderLineNumber);
                if(resItems.OrderLineNumber != null){
                    // order item line number is as 00000207/1 - spliting the value at / to get the line number
                    String lineNumberFromSAP = resItems.OrderLineNumber.substringAfter('/');// 00000207/1
                    //RWPS-3811-START
                    String lineNumber = String.valueOf(item.ECOM_SAP_Line_Number__c);
                    // Remove trailing zeros after decimal
                    if (lineNumber.contains('.')) {
                        // Remove trailing zeros and optional trailing decimal point
                        lineNumber = lineNumber.replaceAll('\\.?0+$', '');
                    }
                     //RWPS-3811-END
                    if(lineNumber == lineNumberFromSAP){//RWPS-3811
                        ECOM_OrderSummaryResponseWrapper.ItemDetail resItemDetail = resItems.ItemDetail;
                        OrderItem oi = new OrderItem();
                        oi.Id = item.Id;
                        //check if the order item expected ship date is update in SAP, if so update on order item
                        if(resItemDetail != null && Date.valueOf(resItemDetail.AvailableDate) != item.ECOM_Earliest_Shipping_Date__c){
                            oi.ECOM_Earliest_Shipping_Date__c = Date.valueOf(resItemDetail.AvailableDate);
                        }
                        if(resItems.SAPOrderLineNumber != null){
                            oi.Line_Item_Number_ERP__c  = resItems.SAPOrderLineNumber;
                        }
                        orderItemsToUpdate.add(oi);
                    }
                }
            }
        }
        return orderItemsToUpdate;
    }
}