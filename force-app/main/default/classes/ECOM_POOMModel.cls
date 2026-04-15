/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM -  1533
*
* 2. Description - This class is used for Cart specific operations.
* 		such as returning poom log
		- This class is used as a Wrapper class 
*
* 3. Objects referenced
*    - WebCart
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
*
* 5. Dependant Class(es):
*    - used in SUB_FLOW_4496_ECOM_Cart_Operations flow
*    - ECOM_CartService
*
* 6. Test Class Name: 
*    - ECOM_POOMModel_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - vramachandran@rafter.one | 05 Jan 2024
*    - garora@rafter.one | 06 Mar 2024 - RWPS-213 - mapped to Punchout Unit Of Measurement on ERP address
*    - garora@rafter.one | 03 April 2024 RWPS-410 - mapped to ECOM Punchout Default UNSPSC on ERP address
*    - Prabhat Kumar 2026.01.07 Added totalTariff property to model- RWPS-5603
*************************************************************/

global class ECOM_POOMModel {
    
    @invocableVariable @auraEnabled public Integer uniqueProductCount;
    
    @invocableVariable @auraEnabled public Boolean isPunchoutCart;//VRa Punchout Changes ECOM_Is_Punchout_Cart__c 
    
    @invocableVariable @auraEnabled public String accountId;
    @invocableVariable @auraEnabled public String cartId;	
    @invocableVariable @auraEnabled public String currencyIsoCode;	
    @invocableVariable @auraEnabled public String grandTotalAmount;
    @invocableVariable @auraEnabled public boolean isSecondary;
    @invocableVariable @auraEnabled public String name;
    @invocableVariable @auraEnabled public String ownerId;	
    @invocableVariable @auraEnabled public String purchaseOrderNumber;
    @invocableVariable @auraEnabled public String status;	
    @invocableVariable @auraEnabled public String taxType;	
    @invocableVariable @auraEnabled public String totalChargeAmount;	
    @invocableVariable @auraEnabled public String totalListPrice;	
    @invocableVariable @auraEnabled public String totalSaving;	
    @invocableVariable @auraEnabled public String totalProductAmount;
    @invocableVariable @auraEnabled public String totalProductAmountAfterAdjustments;	
    @invocableVariable @auraEnabled public String totalProductCount;	
    @invocableVariable @auraEnabled public String totalPromotionalAdjustmentAmount;	
    @invocableVariable @auraEnabled public String totalTaxAmount;	
    @invocableVariable @auraEnabled public String type;	
    @invocableVariable @auraEnabled public String webstoreId;	
    @invocableVariable @auraEnabled public String totalTariff;//RWPS-5603
    
    @invocableVariable @auraEnabled public String userId;
    @invocableVariable @auraEnabled public String accountName;//VRa Punchout Changes
    @invocableVariable @auraEnabled public String accountNumber;//VRa Punchout Changes
    @invocableVariable @auraEnabled public String userName;//VRa Punchout Changes
    @invocableVariable @auraEnabled public String processor;//GAr Punchout Changes - ECOM 2100 - new field introduced for mapping
    
    
    @invocableVariable @auraEnabled public String fromCredentialDomain;
    @invocableVariable @auraEnabled public String fromCredentialIdentity;
    @invocableVariable @auraEnabled public String toCredentialDomain;
    @invocableVariable @auraEnabled public String toCredentialIdentity;
    @invocableVariable @auraEnabled public String senderSharedSecret;
    @invocableVariable @auraEnabled public String browserFormPost;
    @invocableVariable @auraEnabled public String firstName;
    @invocableVariable @auraEnabled public String lastName;
    @invocableVariable @auraEnabled public String uniqueName;
    @invocableVariable @auraEnabled public String userEmail;
    @invocableVariable @auraEnabled public String payLoadId;
    @invocableVariable @auraEnabled public String version;
    @invocableVariable @auraEnabled public String timestamp;
    @invocableVariable @auraEnabled public String lang;
    @invocableVariable @auraEnabled public String buyerCookie;
    @invocableVariable @auraEnabled public String totalMoney;
    @invocableVariable @auraEnabled public String shippingMoney;
    //@invocableVariable @auraEnabled public String supplierPartId;
    @invocableVariable @auraEnabled public String format;
    @invocableVariable @auraEnabled public String epPromoCode;
    @invocableVariable @auraEnabled public String supplierPartAuxiliaryId;
    @invocableVariable @auraEnabled public String punchoutUOM; //RWPS - 213 GAr 6 March 2024 - mapped to Punchout Unit Of Measurement on ERP address
    @invocableVariable @auraEnabled public Boolean defaultUNSPSC; //RWPS - 410 GAr 3 April 2024 - mapped to ECOM Punchout Default UNSPSC on ERP address
    
    @invocableVariable @auraEnabled global List<ECOM_POOMCartItem> cartItems;

}