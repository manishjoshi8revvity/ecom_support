/**************************************************************
 * 1. Ticket(s) that relates to this class
 *		ECOM - 125 
 * 
 * 2. Description - This wrapper class is used to build request to SAP as part of Order Sync to SAP
 *					
 *
 * 3. Objects referenced
 * 		- Order
 * 		- Order Product
 *
 * 4. Callouts to additional Components (including their methods) or None:
 * 	- None
 *
 * 5. Dependant Class(es):
 * 	 - ECOM_OrderCreateAPIUtil
 * 	 - ECOM_OrderCreateBatch
 * 	 - ECOM_OrderCreateFlowController
 * 	 - ECOM_OrderUtil
 *
 * 6. Test Class Name: Test_Class_Name
 *
 * 7. Is @Invocable (Yes or No): No
 *
 * 8. Author Name(s): 
 * - Rani thumma 2023.08.20
 * - Sathiya 2024.06.11, added new variables for mapping additional information to SAP ECOM-3257
 * - Gaurav 2025.04.21, added new variables in order request for mapping additional information to SAP RWPS-1285
 * - Poonam 2025.06.11, added new variable eInvoiceEmail in order request for mapping additional information to SAP RWPS-1882
*************************************************************/ 
public class ECOM_OrderSummaryRequestWrapper {
    
    public OrderRequest OrderRequest;
    
    public class OrderRequest {
		public Header Header;
		public OrderRequestHeader OrderRequestHeader;
		public List<OrderRequestDetail> OrderRequestDetail;
	}
    
    public class Header {
		public Sender Sender;
	}
    
    public class Sender {
		public String Component;
		public String Task;
	}

    public class OrderRequestHeader {
		public String SalesOrgID;
		public String DistChannelID;
		public String DivisionID;
		public String Language;
		public String PurchaseOrderID;
        public String PromoCode;
        public String AgentOrderId; // where is it ?
		public String PaymentType;
        public String DeliveryBlockStatus; // ?
		public String DeliveryBlockText; // ?
        public String AdditionalInfo; //?
        public String AttentionLinesBillto; //?
        public List<CreditCardDetails> CreditCardDetails;
		public String WebOrderNumber;
		public String NumberOfItems;
		public List<Partner> Partner;
		public String AttentionLines;
        public String SpecialHandlingInstructions;
		public String TelephoneNumber;
        public String QuoteNumber;
        public String TaxExempt;
        // Adding Mapping fields for SAP Integration ECOM - 3257 by sathiya on 06/11/2024
        public String eInvoiceCode1;
        public String eInvoiceCode2;
        public String eInvoiceCode3;
        public String eInvoiceCode4;
        public String eInvoiceCostCenter;
        public String eInvoiceTaxExempt;
		public String acceptanceDate; //RWPS-1285
		public String endUserForTrade; //RWPS-1285
		// Changes End
	}

	public class OrderRequestDetail {
		public String OrderLineNumber;
		public String ProductID;
		public String Quantity;
		public String RequestedDate;
        public String ShippingInstructions; //at header level, where are we capturing on line level
	}
    
    public class Partner {
		public String PartnerID;
		public String PartnerType;
        // Adding Mapping fields for SAP Integration ECOM - 3257 by sathiya on 06/11/2024
        public String eanDoNotUse;
        public String eInvoiceCustId;
        public String vatNumber;
        // Changes End
		public String eInvoiceEmail;//RWPS-1882
		public String Id;
	}
    
    public class CreditCardDetails {
		public String CreditCardType;//visa or mastercard
		public String CreditCardNumber;
		public String HolderName; //Kevin Fu
		public String ExpirationMonth;// 03
		public String ExpirationYear;//2023
		public String SecurityNumber;//153
        public String AuthFlag;//X
		public String AuthAmount;//152.04
		public String CurrencyCode;//USD
		public DateTime TransactionDate;//20230923
		public String AuthorizationNumber;//PPS974
		public String PageTransactionid;//204914151610
		public String React;//A
		public String ReactAmount;//152.04
		public String StatEx; //C
		public String PageReturnDescription;//APPROVAL
		public String MerchantId;//313286330888
		public String AuthType;//A
	}

}