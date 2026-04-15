/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-109
*
* 2. Description - This class is used for creating Order & Order Items model
*
* 3. Objects referenced
*    - Order
*    - OrderItem
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_OrderService
* 	 - ECOM_OrderUtil
* 	 - ECOM_OrderHistoryController
*
* 6. Test Class Name:
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Rani 2023.09.16
* 	 - vramachandran@rafter.one | 12 Dec 2023
*	 - sathiya 2024.04.29 new fields added for ECOM-1933 and ECOM-1942
*    - Gaurang 2024.05.02 new field added for ECOM-3150
*    - Gaurang 2024.05.09 new fields added for ECOM-112 - 12 May 2024
*	 - sathiya 2024.05.10 new fields added for ECOM-1947
*    - Gaurang 2024.05.24 additonal fields added for mapping ECOM-3271,1931
*    - Manoj 2024-05-06 RWPS-622 Hide Availability date when the Order contains an Instrument(Added isLargePackShipingOrder attribute)
*    - Gaurang 2024-06-04 ECOM-1931 - added and removed some fields
*	 - Sathiya 2024.06.27 Added emailToInvoice field for ECOM-3389
*    - Gaurang 2024.07.12 UI Fix
*    - Sathiya 2024.08.06 Email Temp Fix
*	 - Sathiya 2024.11.12 Adding new field for invoice field PDF fix RWPS-1990
*    - Sidak 2024.12.06 Added new field approvalRejectionComment. RWPS-1885
*    - Poonam 2025.04.24 Added new field totalTariffSurcharge, tariffSurcharge. RWPS-3026
*    - Gaurav 2025.08.04 Added new field customerTargetName. RWPS-3868
*    - Prabhat 2025.08.25 Added new properties parentPartNumber and parent items . RWPS-3811
*    - Sachin Vispute 2025.10.03 - Added properties isNonSellableProduct and isDiscontinuedProduct - RWPS-3740
*    - Sachin Vispute 2025.11.11 - Added variables - sourceType, sfOrder - RWPS-5149
*    - Prabhat Kumar 2025.12.03 - Added variable isTrainingProduct - RWPS-4896
*    - Poonam Shukla 2026.03.30 - Added variable isExcludedProduct - RWPS-6880
*************************************************************/
public class ECOM_OrderModel{
	@AuraEnabled public String status;
	@AuraEnabled public String accountId;
	@AuraEnabled public String accountName;
	@AuraEnabled public String accountNumber;
	@AuraEnabled public String approvalRejectionComment; //RWPS-1885
	@AuraEnabled public List<OrderItems> orderItems{get;set;}
	@AuraEnabled public String poNumber;
	@AuraEnabled public String promoCode;
    @AuraEnabled public String quoteNumber;
	@AuraEnabled public String orderNumber;
	@AuraEnabled public Decimal totalAmount;
	@AuraEnabled public Double grandTotalAmount;
	@AuraEnabled public Double totalProdAmount;
	@AuraEnabled public Double totalShippingAmount;
	@AuraEnabled public BillingAddress billingAddress;
	@AuraEnabled public ShippingAddress shippingAddress;
    // Fields Added for ECOM-1933 & ECOM-1942 on 2024-04-29 by sathiya
    @AuraEnabled public String invoiceCustId;
    @AuraEnabled public String eanDoNotUse;
    @AuraEnabled public String vatNumber;
    // End of field addition
    //Fields Added for ECOM-3389 on 2024-06-27 by sathiya
    @AuraEnabled public String emailToInvoice;
    //End of field addition
	@AuraEnabled public InvoiceMailingAddress mailingAddress; //ECOM-112 - garora@rafter.one - new field created for mapping mailing address of invoice - 12 May 2024
	@AuraEnabled public Invoice invoice; //ECOM-112 - garora@rafter.one - new field created for mapping invoice - 12 May 2024
	@AuraEnabled public String ownerId;
    @AuraEnabled public String originalOrderId;//VRa- punchout changes
    @AuraEnabled public Date effectiveDate; //VRa - punchout changes
    @AuraEnabled public DateTime orderedDate;//VRa - punchout changes
    @AuraEnabled public String description;//VRa - punchout changes
    @AuraEnabled public String pricebook2Id;//VRa - punchout changes
    @AuraEnabled public String billToContactId;//VRa - punchout changes
	@AuraEnabled public String createdById;
	@AuraEnabled public Double totalTaxAmount;
    @AuraEnabled public Double totalSavings;
	@AuraEnabled public Datetime createdDate;
	@AuraEnabled public String id;
	@AuraEnabled public String salesStoreId;
	@AuraEnabled public Boolean isSapOrder = false;
	@AuraEnabled public String sapOrderNumber;
	@AuraEnabled public String shippingInstructions;
    @AuraEnabled public String deliveryDetails;
	@AuraEnabled public String attentionRecipient;
	@AuraEnabled public String currencyIsoCode;
    @AuraEnabled public Boolean isLargePackShipingOrder = false;//RWPS-622
    @AuraEnabled public Boolean isInvoiceMailingAddress; // Added for Email Template by sathiya
	@AuraEnabled public Decimal totalItems; //ECOM-3150 - garora@rafter.one - will be mapped to rollup field with total quantity on order - 2 May 2024
	@AUraEnabled public String salesOrg; //ECOM-1931 - garora@rafter.one - As boomi is populating sales org, so creating additional field for order model to capture sales org - 4 June 2024
    // E- Invoice Fields added for ECOM-1947 By Sathiya
    @AuraEnabled public String einvoice1;
    @AuraEnabled public String einvoice2;
    @AuraEnabled public String einvoice3;
    @AuraEnabled public String einvoice4;
    @AuraEnabled public String einvoice5;
    @AuraEnabled public String einvoice6;
    @AuraEnabled public Double totalTariffSurcharge;//RWPs-3026
    // Changes End By Sathiya
	@AuraEnabled public Map<String,List<OrderItemTracking>> itemTrackings;
	@AuraEnabled  public String sourceType; //RWPS-5149
	@AuraEnabled  public Id sfOrder; //RWPS-5149
	public class OrderItems {
		@AuraEnabled public Double unitPrice;
		@AuraEnabled public String type;
		@AuraEnabled public String product2Id;
		@AuraEnabled public String description;
		@AuraEnabled public Product product;
		@AuraEnabled public Decimal totalPrice;
		@AuraEnabled public Decimal totalLineAmount;
		@AuraEnabled public Decimal quantity;
		@AuraEnabled public String id{get;set;}
		@AuraEnabled public String orderId;
		@AuraEnabled public Double listPrice;
		@AuraEnabled public Date earliestShippingDate;
        @AuraEnabled public Date selectedShippingDate;
        @AuraEnabled public String status;
		@AuraEnabled public List<OrderItemTracking> OrderItemTrackings;
		@AuraEnabled public String currencyIsoCode;
        @AuraEnabled public Double tariffSurcharge;//RWPS-3026
		@AuraEnabled public Boolean isNonSellableOrDiscontinuedProduct;//RWPS-2786
		@AuraEnabled public String parentItem;//RWPS-3811
		@AuraEnabled public String parentPartNumber ;//RWPS-3811
		@AuraEnabled public Boolean isNonSellableProduct;//RWPS-4602
		@AuraEnabled public Boolean isDiscontinuedProduct;//RWPS-4602
		@AuraEnabled public Boolean isTrainingProduct;//RWPS-4896
		@AuraEnabled public Boolean isExcludedProduct;//RWPS-6880

	}

	public class OrderItemTracking {
		@AuraEnabled public String OrderItemId{get; set;}
		@AuraEnabled public String OrderSummaryId{get; set;}
		@AuraEnabled public String carrierName{get; set;}
		@AuraEnabled public Date trackingDate{get; set;}
        @AuraEnabled public String trackingNumber {get; set;}
		@AuraEnabled public String trackingURL {get; set;}
		@AuraEnabled public Decimal quantityShipped{get; set;}
        @AuraEnabled public String partNumber{get; set;}
        @AuraEnabled public String productName{get; set;}
        @AuraEnabled public String productMediaURI{get; set;}
        @AuraEnabled public Decimal quantityOrdered{get; set;}
        @AuraEnabled public String orderItem{get; set;}
	}

	public class Product {
		@AuraEnabled public String partNumber;
		@AuraEnabled public String name;
		@AuraEnabled public String id;
		@AuraEnabled public String displayUrl;

	}
	public class BillingAddress {
		@AuraEnabled public String street;
		@AuraEnabled public String city;
		@AuraEnabled public String state;
		@AuraEnabled public String postalCode;
		@AuraEnabled public String country;
		@AuraEnabled public String stateCode;
		@AuraEnabled public String countryCode;
		@AuraEnabled public String id;
		@AuraEnabled public String companyName; //ECOM-112 - garora@rafter.one - new field created for companyName - 12 May 2024
        @AuraEnabled public Boolean showCompanyName;
		@AuraEnabled public String customerTargetName; //RWPS-3868
	}

	public class ShippingAddress {
		@AuraEnabled public String street;
		@AuraEnabled public String city;
		@AuraEnabled public String state;
		@AuraEnabled public String postalCode;
		@AuraEnabled public String country;
		@AuraEnabled public String stateCode;
		@AuraEnabled public String countryCode;
		@AuraEnabled public String id;
		@AuraEnabled public String companyName; //ECOM-112 - garora@rafter.one - new field created for companyName - 12 May 2024
        @AuraEnabled public Boolean showCompanyName;
	}

	//ECOM-112 - garora@rafter.one - new fields created for ECOM_Invoice__c and ECOM_InvoiceLine__c - starts - 12 May 2024

	public class InvoiceMailingAddress {
		@AuraEnabled public String street;
		@AuraEnabled public String city;
		@AuraEnabled public String state;
		@AuraEnabled public String postalCode;
		@AuraEnabled public String country;
		@AuraEnabled public String stateCode;
		@AuraEnabled public String countryCode;
		@AuraEnabled public String id;
		@AuraEnabled public String companyName;
        @AuraEnabled public Boolean showCompanyName;
	}

	public class Invoice {
		@AuraEnabled public String Id{get;set;}
		@AuraEnabled public String name{get;set;}
		@AuraEnabled public Date invoiceDate{get;set;}
		@AuraEnabled public Decimal totalItems{get;set;}
		@AuraEnabled public String currencyIsoCode{get;set;}
		@AuraEnabled public Decimal subtotal{get;set;}
		@AuraEnabled public Decimal tax{get;set;}
		@AuraEnabled public Decimal total{get;set;}
		@AuraEnabled public List<InvoiceLine> invoiceLines{get;set;}
		//ECOM-3271 - Gaurang - additonal fields added for mapping - 24 May 2024 - starts
		@AuraEnabled public String downloadUrl{get;set;}
		@AuraEnabled public String invoiceNumber{get;set;}
		//ECOM-3271 - Gaurang - additonal fields added for mapping - 24 May 2024 - ends
		//RWPS-1990 - Sathiya - enable pdf when the flag is set to true - 12 Nov 2024 - starts
		@AuraEnabled public Boolean isPDFEnabled{get;set;}
        //RWPS-1990 - Sathiya - enable pdf when the flag is set to true - 12 Nov 2024 - End
        @AuraEnabled public Double totalTariffSurcharge;//RWPs-3026
	}

	public class InvoiceLine {
		@AuraEnabled public String Id;
		@AuraEnabled public String productId;
		@AuraEnabled public String name;
		@AuraEnabled public String partNumber;
		@AuraEnabled public String currencyIsoCode;
		@AuraEnabled public Decimal listPrice;
		@AuraEnabled public Decimal quantity;
		@AuraEnabled public Decimal subtotal;
		@AuraEnabled public Decimal tax;
		@AuraEnabled public Decimal total;
		@AuraEnabled public String displayUrl; //UI Fix - Gaurang - 12 July 2024
        @AuraEnabled public String imgUrl;
        @AuraEnabled public Double tariffSurcharge;//RWPS-3026

	}
	//ECOM-112 - garora@rafter.one - new fields created for ECOM_Invoice__c and ECOM_InvoiceLine__c - ends - 12 May 2024

	public static ECOM_OrderModel parse(String json){
		return (ECOM_OrderModel) System.JSON.deserialize(json, ECOM_OrderModel.class);
	}
}