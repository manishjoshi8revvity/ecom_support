/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM -  
*
* 2. Description - This class is used for Cart specific operations.
* 		such as add to cart, fetch cart, update cart etc..
		- This class is used as a Wrapper class 
*
* 3. Objects referenced
*    - Cart
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
*
* 5. Dependant Class(es):
*    - used in SUB_FLOW_4496_ECOM_Cart_Operations flow
*    - ECOM_CartOperationsFlowController
*    - ECOM_CartService
*
* 6. Test Class Name: 
*    - ECOM_CartModel_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Manoj kumar 2023.08.02
*    - Manoj kumar 2023.09.21
*	 - sathiya 2024.05.10 new fields added for ECOM-1947
*************************************************************/
public with sharing class ECOM_CartModel{
    @auraEnabled public String accountId;
	@auraEnabled public String cartId;	
	@auraEnabled public String currencyIsoCode;	
	@auraEnabled public String grandTotalAmount;
	@auraEnabled public boolean isSecondary;
	@auraEnabled public String name;
	@auraEnabled public String ownerId;	
	@auraEnabled public String purchaseOrderNumber;
	@auraEnabled public String status;	
	@auraEnabled public String taxType;	
	@auraEnabled public String totalChargeAmount;	
	@auraEnabled public String totalListPrice;	
	@auraEnabled public String totalSaving;	
	@auraEnabled public String totalProductAmount;
	@auraEnabled public String totalProductAmountAfterAdjustments;	
	@auraEnabled public String totalProductCount;	
	@auraEnabled public String totalPromotionalAdjustmentAmount;	
	@auraEnabled public String totalTaxAmount;	
	@auraEnabled public String type;	
	@auraEnabled public Integer uniqueProductCount;	
	@auraEnabled public String webstoreId;	
    @auraEnabled public ECOM_MessagesSummary messagesSummary;
    @auraEnabled public List<ECOM_CartItemModel> cartItems;
	@auraEnabled public String userId;
    @auraEnabled public String accountName;//VRa Punchout Changes
    @auraEnabled public String accountNumber;//VRa Punchout Changes
    @auraEnabled public String userName;//VRa Punchout Changes
    @auraEnabled public Boolean isPunchoutCart;//VRa Punchout Changes
	@AuraEnabled public String shipToSalesOrg;
	@AuraEnabled public String billToSalesOrg;
    // E- Invoice Fields added for ECOM-1947 By Sathiya
    @AuraEnabled public String einvoice1;
    @AuraEnabled public String einvoice2;
    @AuraEnabled public String einvoice3;
    @AuraEnabled public String einvoice4;
    @AuraEnabled public String einvoice5;
    @AuraEnabled public String einvoice6;
    // Changes End By Sathiya
    // Product T & C Fields added for ECOM-123 By Sathiya
    @AuraEnabled public String productTnC;
	@AuraEnabled public String productTnCRUO;
    // Changes End by Sathiya
}