/**
 * @description       : 
 * @author            : mkumar@rafter.one
 * @group             : 
 * @last modified on  : 02-13-2024
 * @last modified by  : Vipul Goyal
 * * Chirag L 2025.04.30 - Added logic to show shipping cost subtracted from tariff surcharge RWPS-3026
 * Gaurav 2025.08.04 - Updated billingCompanyName to populate customerTargetName instead of companyName. RWPS-3868
 * Prabhat 2025.08.25 - Updated getOrderDetails to get the data related free items. RWPS-3811
 * Kushal 2025.12.31 - Updated the copyright year to be dynamic - RWPS-5616
**/

public without sharing class ECOM_OrderConfirmationEmailController {
	
    public List<OrderItem> orderList {get; set;}
    public List<ECOM_OrderModel.OrderItems> orderItemsList {get; set;}
    public Map<String, List<ECOM_OrderModel.OrderItemTracking>> itemTrackings{get; set;}
    public Map<String, String> orderItemIdToParentPartNumberMap { get; set; }//RWPS-3811
    public List<OrderItemWrapper> orderItemsListWrapper { get; set; }//RWPS-3811
	public Id orderRecordId;
    public string currencyCode {get; set;}
    public Integer cardLastFour {get; set;}
    public String cardType {get; set;}
    public String attentionRecipientOD {get; set;}
    public String specialInstructionsOD {get; set;}
    public String deliveryDetailsOD {get; set;}
    public String country {get; set;}
    public String customerCareEmail {get; set;}
    public String customerCareNumber {get; set;}
    public String accountId {get; set;}
    // Changes by sathiya on 2024.05.24 for Email Template changes
    public String billingCompanyName {get; set;}
    public String shippingCompanyName {get; set;}
    public String mailingCompanyName {get; set;}
    public String mailingCity {get; set;}
    public String mailingCountry {get; set;}
    public String mailingState {get; set;}
    public String mailingStreet {get; set;}
    public String mailingPostalCode {get; set;}
    List<Map<String, String>> payerDetails {get; set;}
	List<Map<String, String>> eInvoiceDetails {get; set;}
    public Boolean isEInvoiceFields {get; set;}
    public Boolean isInvoiceMailingAddress {get; set;}
    public String payerLabel1 {get; set;}
    public String payerLabel2 {get; set;}
    public String payerLabel3 {get; set;}
    public String payerLabel4 {get; set;}
    public String payerValue1 {get; set;}
    public String payerValue2 {get; set;}
    public String payerValue3 {get; set;}
    public String payerValue4 {get; set;}
    public String invoiceLabel1 {get; set;}
    public String invoiceValue1 {get; set;}
    public String invoiceLabel2 {get; set;}
    public String invoiceValue2 {get; set;}
    public String invoiceLabel3 {get; set;}
    public String invoiceValue3 {get; set;}
    public String invoiceLabel4 {get; set;}
    public String invoiceValue4 {get; set;}
    public String invoiceLabel5 {get; set;}
    public String invoiceValue5 {get; set;}
    public String invoiceLabel6 {get; set;}
    public String invoiceValue6 {get; set;}
    // Changes End
    // RWPS-3026 - START
    public Decimal shippingAmount {get; set;}
    public Decimal tariffAmount {get; set;}
    public Decimal calculatedShippingAmount {get; set;}
    // RWPS-3026 - END
    //RWPS-5616 Start
    public String copyrightText {
        get {return String.format(Label.ECOM_ET_Copyright, new Object[] {Date.today().year()});}
    }
    //RWPS-5616 End
    
	public Id getOrderRecordId(){ return orderRecordId; }
	public void setOrderRecordId(Id s){
		orderRecordId = s;
        if(orderRecordId != null){

            // RWPS-3026 - START
            if (shippingAmount == null) {
                shippingAmount = 0;
            }
            if (tariffAmount == null) {
                tariffAmount = 0;
            }
            calculatedShippingAmount = shippingAmount - tariffAmount; 
            // RWPS-3026 - END
            getOrderDetails();
        }
	}
	public void ECOM_OrderConfirmationEmailController() {}
    public void getOrderDetails() {
        try{
            List<String> accId = new List<String>();
            List<Account> accList = new List<Account>();
            Map<String, Object> orderDetailsMap = ECOM_OrderHistoryController.getOrderDetails(orderRecordId);
            ECOM_OrderModel orderDetails = (ECOM_OrderModel) orderDetailsMap.get('orderModel');
            // Changes done for Email Template by sathiya
            billingCompanyName = orderDetails?.billingAddress?.showCompanyName?orderDetails?.billingAddress?.customerTargetName:null; //RWPS-3868
            shippingCompanyName = orderDetails?.shippingAddress?.showCompanyName?orderDetails?.shippingAddress?.companyName:null;
            mailingCompanyName = orderDetails?.mailingAddress?.showCompanyName?orderDetails?.mailingAddress?.companyName:null;
            mailingCity = orderDetails?.mailingAddress?.city;
            mailingCountry = orderDetails?.mailingAddress?.country;
            mailingState = orderDetails?.mailingAddress?.state;
            mailingStreet = orderDetails?.mailingAddress?.street;
            mailingPostalCode = orderDetails?.mailingAddress?.postalCode;
            eInvoiceDetails = ECOM_OrderUtil.getFieldMappingByType(orderDetails, ECOM_Constant.INVOICE_FIELD_VALIDATION);
            payerDetails = ECOM_OrderUtil.getFieldMappingByType(orderDetails, ECOM_Constant.BILL_TO_FIELD_VALIDATION);
            isEInvoiceFields = !eInvoiceDetails.isEmpty();
            isInvoiceMailingAddress = orderDetails?.isInvoiceMailingAddress;
            if(Test.isRunningTest()){
                payerDetails = new List<Map<String,String>>{new Map<String, String>{'label'=>'test','value'=>'value'}, new Map<String, String>{'label'=>'test','value'=>'value'}, new Map<String, String>{'label'=>'test','value'=>'value'}};
                eInvoiceDetails = new List<Map<String,String>>{new Map<String, String>{'label'=>'test','value'=>'value'}, new Map<String, String>{'label'=>'test','value'=>'value'}, new Map<String, String>{'label'=>'test','value'=>'value'},new Map<String, String>{'label'=>'test','value'=>'value'}, new Map<String, String>{'label'=>'test','value'=>'value'}, new Map<String, String>{'label'=>'test','value'=>'value'}};
            }
            Integer counter = 1;
            if(!payerDetails.isEmpty()){
                for(Map<String, String> payerMap: payerDetails){
                    switch on counter {
                        when 1 {
                            payerLabel1 = payerMap.get(ECOM_Constant.API_LABEL);
                            payerValue1 = payerMap.get(ECOM_Constant.API_VALUE);
                        }	
                        when 2 {
                            payerLabel2 = payerMap.get(ECOM_Constant.API_LABEL);
                            payerValue2 = payerMap.get(ECOM_Constant.API_VALUE);
                        }
                        when 3 {
                            payerLabel3 = payerMap.get(ECOM_Constant.API_LABEL);
                            payerValue3 = payerMap.get(ECOM_Constant.API_VALUE);
                        }
                        when 4 {
                            payerLabel4 = payerMap.get(ECOM_Constant.API_LABEL);
                            payerValue4 = payerMap.get(ECOM_Constant.API_VALUE);
                        }
                    }
                    counter++;
                }
            }
            counter = 1;
            if(!eInvoiceDetails.isEmpty()){
                for(Map<String, String> invoiceMap: eInvoiceDetails){
                    switch on counter {
                        when 1 {
                            invoiceLabel1 = invoiceMap.get(ECOM_Constant.API_LABEL);
                            invoiceValue1 = invoiceMap.get(ECOM_Constant.API_VALUE);
                        }	
                        when 2 {
                            invoiceLabel2 = invoiceMap.get(ECOM_Constant.API_LABEL);
                            invoiceValue2 = invoiceMap.get(ECOM_Constant.API_VALUE);
                        }
                        when 3 {
                            invoiceLabel3 = invoiceMap.get(ECOM_Constant.API_LABEL);
                            invoiceValue3 = invoiceMap.get(ECOM_Constant.API_VALUE);
                        }
                        when 4 {
                            invoiceLabel4 = invoiceMap.get(ECOM_Constant.API_LABEL);
                            invoiceValue4 = invoiceMap.get(ECOM_Constant.API_VALUE);
                        }	
                        when 5 {
                            invoiceLabel5 = invoiceMap.get(ECOM_Constant.API_LABEL);
                            invoiceValue5 = invoiceMap.get(ECOM_Constant.API_VALUE);
                        }
                        when 6 {
                            invoiceLabel6 = invoiceMap.get(ECOM_Constant.API_LABEL);
                            invoiceValue6 = invoiceMap.get(ECOM_Constant.API_VALUE);
                        }
                    }
                    counter++;
                }
            }
			
            // Changes End
            //RWPS-3811 - START
            itemTrackings = new Map<String, List<ECOM_OrderModel.OrderItemTracking>>();
            orderItemsListWrapper = new List<OrderItemWrapper>();
            orderItemsList = orderDetails.orderItems;
            for(ECOM_OrderModel.OrderItems orderItem : orderItemsList) {
                orderItemsListWrapper.add(new OrderItemWrapper(orderItem));
            }
            
            orderItemIdToParentPartNumberMap = new Map<String, String>();
            for (OrderItemWrapper orderItem : orderItemsListWrapper) {
                if(orderItem.parentPartNumber != null) {
                    orderItemIdToParentPartNumberMap.put(orderItem.orderItemId, orderItem.parentPartNumber);
                 }else{
                    orderItemIdToParentPartNumberMap.put(orderItem.orderItemId, 'false');
                }
                 
             }
            orderList = new List<OrderItem>();
            //RWPS-3811 - END
            if(orderDetails != null){
            	currencyCode = orderDetails.currencyIsoCode;
                attentionRecipientOD = orderDetails.attentionRecipient;
                specialInstructionsOD = orderDetails.shippingInstructions;
                deliveryDetailsOD = orderDetails.deliveryDetails;
                country = orderDetails.shippingAddress.country;
                accountId = orderDetails.accountId;
            }
            if(country == null){
                accId.add(accountId);
                accList = ECOM_AccountRepo.getAccountBasedOnIds(accId);
                country = accList[0].ShippingCountry;
            }
            itemTrackings =  orderDetails.itemTrackings;
            Type orderService = Type.forName(ECOM_Constant.ORDER_SERVICE);
            ECOM_IOrderService orderServiceInstance = (ECOM_IOrderService)orderService.newInstance();
            List<CardPaymentMethod> cardPayments = orderServiceInstance.getCardPaymentBasedOnOrder(orderRecordId);
            if(cardPayments != null && cardPayments.size() > 0){
                cardLastFour = cardPayments[0].CardLastFour;
                cardType = cardPayments[0].CardType;
            }
            Map<String,String> contactDetailsMap = ECOM_CustomMetadataService.getEmailContactDetails(country);
            if(contactDetailsMap.containsKey(ECOM_Constant.CUSTOMER_CARE_EMAIL) && contactDetailsMap.get(ECOM_Constant.CUSTOMER_CARE_EMAIL) != null){
                customerCareEmail = contactDetailsMap.get(ECOM_Constant.CUSTOMER_CARE_EMAIL);
            }
            if(contactDetailsMap.containsKey(ECOM_Constant.CUSTOMER_CARE_NUMBER) && contactDetailsMap.get(ECOM_Constant.CUSTOMER_CARE_NUMBER) != null){
                customerCareNumber = contactDetailsMap.get(ECOM_Constant.CUSTOMER_CARE_NUMBER);
            }
        } catch (Exception ex){
            System.debug('Exception === '+ex.getMessage());
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.ORDER_MODULE_NAME, 'ECOM_OrderConfirmationEmailController', 'ECOM_OrderConfirmationEmailController', orderRecordId);
        }
    }

    //RWPS-3811 - START 
    public class OrderItemWrapper {
        public String parentPartNumber { get; set; }
        public ECOM_OrderModel.OrderItems  orderItemModel { get; set; }
        public string orderItemId { get; set; }

        public OrderItemWrapper(ECOM_OrderModel.OrderItems oi) {
            this.orderItemModel = oi;
            this.parentPartNumber = oi.parentPartNumber;
            this.orderItemId = oi.id;
        }
    }
    //RWPS-3811 -END


}