/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*	  - ECOM-1533
*
*
* 2. Description - This is a model class for POOM Request to Boomi. 
*				 - This class provides a model to map the cart item values 
*
*
* 3. Objects referenced
*	 - WebCart
*    -CartItems
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_PunchoutPOOMFlowController
*
* 6. Test Class Name: 
*    - ECOM_PunchoutPOOMFlowController_Test
*
* 7. Is @Invocable: No
*
* 8. Author Name(s):
*    - Vasudev Ramachandran 18 Dec 2023
*    - Gaurang Arora 6 Mar 2024 - RWPS 213 - new field mappings
*    - Manoj 2024.06.14 RWPS-586 - New processor needed for our OCI response to send to Galapagos via EDI
*    - Prabhat Kumar 2025.04.10 Added shippingCostItem variable to model- RWPS-2941
*    - Prabhat Kumar 2026.01.07 Added totalTariffItem property to model- RWPS-5603
*************************************************************/
public class ECOM_POOMCartItem {
    
    @invocableVariable @auraEnabled public String cartId;	//0a6DW0000008Q7JYAU
    @invocableVariable @auraEnabled public String cartItemId;	//0a9DW0000008PURYA2
    @invocableVariable @auraEnabled public String currencyIsoCode;	//USD
    @invocableVariable @auraEnabled public String itemizedAdjustmentAmount;	//0.00
    @invocableVariable @auraEnabled public String listPrice;	//1093.95
    @invocableVariable @auraEnabled public String name;	//INSTA-GEL PL / 2x5 L
    @invocableVariable @auraEnabled public String productId;	//01tDW000009ckIgYAI
    @invocableVariable @auraEnabled public String quantity;	//127
    @invocableVariable @auraEnabled public String salesPrice;	//1093.95
    @invocableVariable @auraEnabled public String totalAdjustmentAmount;	//0.00
    @invocableVariable @auraEnabled public String totalAmount;	//138942.65
    @invocableVariable @auraEnabled public String totalListPrice;	//0.00
    @invocableVariable @auraEnabled public String totalPrice;	//138931.65
    @invocableVariable @auraEnabled public String totalTax;	//11.00
    @invocableVariable @auraEnabled public String type;	//Product
    @invocableVariable @auraEnabled public String unitAdjustedPrice;	//1093.95
    @invocableVariable @auraEnabled public String unitAdjustmentAmount;	//0.00
    @invocableVariable @auraEnabled public String productDescription;
    @invocableVariable @auraEnabled public String unspsc;
    @invocableVariable @auraEnabled public String displayUrl;
    @invocableVariable @auraEnabled public String supplierPartId;
    @invocableVariable @auraEnabled public String unitPrice;
    @invocableVariable @auraEnabled public String unitOfMeasure;    
    @invocableVariable @auraEnabled public String manufacturerPartId;
    @invocableVariable @auraEnabled public String thumbnailImageURL;
    @invocableVariable @auraEnabled public String leadTime;
    @invocableVariable @auraEnabled public String isoUom; //RWPS-213 GAr 6 Mar 2024 - mapped to ISO UOM field on Product2
    @invocableVariable @auraEnabled public String unUom; //RWPS-213 GAr 6 Mar 2024 - mapped to UNUOM field on Product2
    @invocableVariable @auraEnabled public String ansiUom; //RWPS-213 GAr 6 Mar 2024 - mapped to ANSI UOM field  on Product2
    @invocableVariable @auraEnabled public String shippingCostItem; //RWPS-2941
    @invocableVariable @auraEnabled public String totalTariffItem; //RWPS-5603
    
    @invocableVariable @auraEnabled public Boolean hazardousMaterial;
    @invocableVariable @auraEnabled public Boolean radioactive;
    @invocableVariable @auraEnabled public String intrastatCode;//RWPS-586
}