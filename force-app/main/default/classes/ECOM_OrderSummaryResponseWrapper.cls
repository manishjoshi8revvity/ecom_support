/**************************************************************
 * 1. Ticket(s) that relates to this class
 *    ECOM - 125 
 * 
 * 2. Description - This wrapper class is used to map SAP/Boomi reponse as part of order sync to SAP
 *					
 * 3. Objects referenced
 * 	 - Order
 * 	 - Order Product
 *
 * 4. Callouts to additional Components (including their methods) or None:
 * 	 - None
 *
 * 5. Dependant Class(es):
 * 	 - ECOM_OrderCreateAPIUtil
 * 	 - ECOM_OrderUtil
 *
 * 6. Test Class Name: Test_Class_Name
 *
 * 7. Is @Invocable (Yes or No): No
 *
 * 8. Author Name(s): 
 * - Rani thumma 2023.08.20
 * - Chirag L 2025.12.05 Added attribute POType in OrderResponseHeader wrapper class - RWPS-5094

*************************************************************/ 
public class ECOM_OrderSummaryResponseWrapper {
    
	public OrderResponse OrderResponse ; 
	
    public class OrderResponse {
		public OrderResponseHeader OrderResponseHeader ;
        public Error Error;
	}
	
	public class OrderResponseHeader {
        public String PurchaseOrderID ;
        public String SellerOrderID ;
		public String POType; // RWPS-5094
        public String ShippingCost ;
        public String CreditCardNumber ;
		public String CreditCardType ;
		public String TelephoneNumber ;
		public String AdditionalInfo ;
		public String SpecialHandlingInstructions ;
        public DateAndTime DateAndTime ;// in json: Datetime
        public List<OrderResponseDetail> OrderResponseDetail ;
		
	}
    
	public class DateAndTime {
		public String Year ;
		public String Month ;
		public String Day ;
		public String Hour ;
		public String Minute ;
		public String Second ;
		public String Subsecond ;
		public String Timezone ;
	}
    
	public class Userarea {
	}
	
	public class OrderResponseDetail {
		public String ShippingPoint ;
		public String OrderLineNumber ;
        public String SAPOrderLineNumber ;
		public String ProductID ;
		public String Description ;
		public String AdjustedPrice ;
		public String Discount ;
		public String TaxVAT ;
		public ItemDetail ItemDetail ;
	}
    
    public class ItemDetail {
		public String AvailableQty;
		public String AvailableDate;
	}
    public class Error {
		public List<ErrorDetails> ErrorDetails;
	}
	public class ErrorDetails {
		public String errorMessage;	
		public String errorCode;	
	}
}