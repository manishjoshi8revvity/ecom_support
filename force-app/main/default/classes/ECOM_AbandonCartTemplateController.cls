/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM- 91     
*
* 2. Description - This class is used for Abandoned Cart Email Template
*
*
* 3. Objects referenced
*    - WebCart
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_CustomMetadataService
*    - ECOM_CartService
*    - ECOM_Constant
*    - ECOM_ApplicationLogsUtil
*
* 6. Test Class Name: 
*    - ECOM_AbandonCartTemplateControllerTest
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vipul Goyal 2024.04.23 Abandoned Cart Email Template.
*    - Gaurav 2025.05.16 Updated getCartDetails to send Abandoned Cart Email Template with promo code msg. RWPS-3225
*    - Prabhat 2025.06.16 Updated method ECOM_AbandonCartTemplateController - RWPS-2786
*    - Kushal 2025.12.31 Updated the copyright year to be dynamic - RWPS-5616
*************************************************************/
public without sharing class ECOM_AbandonCartTemplateController {

    public WebCart cart {get; set;}
    public List<CartItem> cartItemsOriginal {get; set;}
    public List<CartItem> cartItems {get; set;}
    public String cartOwner{get; set;}
    public Id cartRecordId;
    public String customerCareEmail {get; set;}
    public String customerCareNumber {get; set;}
    public Map<String, Boolean> discontinuedProductsMap {get; set;} //RWPS-2786

    public Boolean promoActive {get; set;}  //RWPS-3225
    //RWPS-5616 Start
    public String copyrightText {
        get {return String.format(Label.ECOM_ET_Copyright, new Object[] {Date.today().year()});}
    }
    //RWPS-5616 End
    public Id getCartRecordId(){ return cartRecordId; }
	public void setCartRecordId(Id s){
		cartRecordId = s;
        if(cartRecordId != null){
            getCartDetails();
        }
	}


    public void getCartDetails() {
        try{

            cart = ECOM_CartService.getCartandCartItemsById(cartRecordId)[0];
            cartOwner = cart.Owner.Name;
            cartItemsOriginal = cart.cartItems;
            cartItems = new List<CartItem>();
            //RWPS-3225 start
            if(ECOM_OrderRepo.getUserOrderCount(cart.OwnerId) > 0 || ECOM_cartRepo.isFirstTimePromoActive() == 0)
                promoActive = false;
            else {
                promoActive = true;
            }
            //RWPS-3225 End
            Map<String,CartItem> partNumberToCartItems = new Map<String,CartItem> ();
            Map<String,Decimal> partNumberToQuantity = new Map<String,Decimal> ();
            Set<String> productIdSet = New Set<String>(); //RWPS-2786
            for(CartItem cItem:cartItemsOriginal)
            {
                if(String.isNotBlank(cItem.Product2.Part_Number__c))
                {
                    productIdSet.add(cItem.product2Id);//RWPS-2786
                    if(partNumberToCartItems.containsKey(cItem.Product2.Part_Number__c))
                    {
                        partNumberToQuantity.put(cItem.Product2.Part_Number__c,(partNumberToQuantity.get(cItem.Product2.Part_Number__c)+cItem.Quantity));
                    }
                    else 
                    {
                        partNumberToCartItems.put(cItem.Product2.Part_Number__c,cItem);
                        partNumberToQuantity.put(cItem.Product2.Part_Number__c,cItem.Quantity);
                    }
                }
            }
            //RWPS-2786- Start
            Set<String> lstDiscontinuedProducts = ECOM_CartUtil.getInActiveProducts(cart,productIdSet);
            discontinuedProductsMap = New Map<String, Boolean>();
            for(CartItem cItem:cartItemsOriginal){
                if(lstDiscontinuedProducts.contains(cItem.Product2Id)){
                    discontinuedProductsMap.put(cItem.Product2Id, true);
                } else {
                    discontinuedProductsMap.put(cItem.Product2Id, false);
                }
            }
           //RWPS-2786- End

            for(String key:partNumberToCartItems.keySet())
            {
                CartItem temp = new CartItem();
                temp = partNumberToCartItems.get(key);
                temp.Quantity = partNumberToQuantity.get(key);
                cartItems.add(temp);
            }

            String country='';
            if(String.isNotBlank(cart.Default_Ship_to_ERP_Address__r.ApiCountry__c))
            {
                country = cart.Default_Ship_to_ERP_Address__r.ApiCountry__c;
            }
            else 
            {
                country = cart.Default_Ship_to_ERP_Address__r.fxAddress_CountryName__c;
            }
            Map<String,String> contactDetailsMap = ECOM_CustomMetadataService.getEmailContactDetails(country);
            // Changing the custom care email to the sender address
            List<OrgWideEmailAddress> orgwideaddreslist = [SELECT Id,Address FROM OrgWideEmailAddress 
                                                           WHERE DisplayName =: ECOM_Constant.ABANDONED_CART_ORGWIDEADDRESS_NAME LIMIT 1];
            if(!orgwideaddreslist.isEmpty()){
                customerCareNumber = orgwideaddreslist[0]?.Id;
            }
           //RWPS-3225
            if(Test.isRunningTest() || contactDetailsMap.containsKey(ECOM_Constant.CUSTOMER_CARE_NUMBER) && contactDetailsMap.get(ECOM_Constant.CUSTOMER_CARE_NUMBER) != null){
                customerCareNumber = contactDetailsMap.get(ECOM_Constant.CUSTOMER_CARE_NUMBER);
            }
        }
        catch (Exception ex){
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.ABANDONED_CART_MODULE_NAME, 'ECOM_AbandonCartTemplateController', 'ECOM_AbandonCartTemplateController', cartRecordId);
        }
    }
}