/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM- 691
*
* 2. Description - This class is for order simulation /
*
*
*
* 3. Objects referenced
*    -WebCart
*
* 4. Callouts to additional Components (including their methods) or None:
*    - ECOM_CartHelper
*	 - ECOM_CartService
*
* 5. Dependant Class(es):
*    - 
*
* 6. Test Class Name:        
*    - ECOM_SimulateOrderWrapper_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Manoj 2023.07.17
*    - Vipul 2023.09.20
*    - Manoj 2024-04-30 RWPS-584 Instrument freight not applying as expected on web orders(Updated new attribute 'component' to request)
*    - Prabhat 2025.04.25 Added new attribute 'tariff_surcharge' to ProductList - RWPS-3026
*    - Prabhat 2025.09.11 Added new attribute 'bogo_applicable' to ProductList - RWPS-3811
*************************************************************/
public with sharing class ECOM_SimulateOrderWrapper {
  
    OrderRequest request;
	OrderResponse response;

	//This class is used for Order Request
    public class OrderRequest {
       
        @AuraEnabled public String bill_to;
        @AuraEnabled public String Ship_to;
        @AuraEnabled public String country;	
        @AuraEnabled public Date requested_date;
        @AuraEnabled public String promo_code;	
        @AuraEnabled public String cart_id;
        @AuraEnabled public String payment_type;
        @AuraEnabled public String component;
        @AuraEnabled public String po_no;
        @AuraEnabled public List<Item> product_list;
	}

	//This class is used for Order Item
    public class Item {
		@AuraEnabled public Integer item_number;
		@AuraEnabled public String part_number;
		@AuraEnabled public Decimal quantity;
		@AuraEnabled public Boolean qtyLimitExceeded;
		@AuraEnabled public Boolean bogo_applicable;//RWPS-3811
	}

	//This class is used for Order Response
    public class OrderResponse{
        @AuraEnabled public String paymentTerms;
        @AuraEnabled public String incoTerms;
        @AuraEnabled public String incoCode;
        @AuraEnabled public String currencyCode;
        @AuraEnabled public String shippingCost;
		@AuraEnabled  public String totalTaxVat;
        @AuraEnabled public String totalPrice;
        @AuraEnabled public List<ProductList> productList;
		@AuraEnabled public Error error;
    }

	//This class is used for Product
	public class ProductList {
		@AuraEnabled public String itemNumber;
		@AuraEnabled public String partNumber;
		@AuraEnabled public String shippingPoint;
		@AuraEnabled public String linePrice;
		@AuraEnabled public Decimal discount;
		@AuraEnabled public Decimal handling;
		@AuraEnabled public Decimal freight;
		@AuraEnabled public String taxVat;
		@AuraEnabled public String salesPrice;

		@AuraEnabled public String listPrice;

		@AuraEnabled public List<ItemDetail> itemDetail;
		@AuraEnabled public Decimal tariff_surcharge; //RWPS-3026
		@AuraEnabled public Boolean bogo_applicable;//RWPS-3811
		
	}

	//This class is used for Item Detail
	public class ItemDetail {
		@AuraEnabled public String availableQty;
		@AuraEnabled public String availableDate;
	}

	//This class is used Error
	public class Error {
		@AuraEnabled public List<ErrorDetails> errorDetails;
	}

	//This class is used for Error Details
	public class ErrorDetails {
		@AuraEnabled public String errorMessage;
		@AuraEnabled public String errorCode;
	}
	public static OrderResponse parse(String json){
		return (OrderResponse) System.JSON.deserialize(json, OrderResponse.class);
	}

}