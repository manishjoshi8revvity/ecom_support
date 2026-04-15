/**************************************************************
 * 1. Ticket(s) that relates to this class
 * - ECOM-
 * 
 * 2. Description - It is a wrapper class used to store request and response wrapper object for wishlist api.
 *					
 *
 * 3. Objects referenced
 * - WishList
 *
 * 4. Callouts to additional Components (including their methods) or None:
 * - None
 *
 * 5. Dependant Class(es):
 * - ECOM_AccountUtil
 * 
 * 6. Test Class Name:         
 * - ECOM_WishListItemModel_Test
 *
 * 7. Is @Invocable (Yes or No): No
 *
 * 8. Author Name(s): 
 * - Rani Thumma 2023.09.09
 *
*************************************************************/ 
public class ECOM_WishListItemModel {
    
    @AuraEnabled public String wishListItemId;
    @AuraEnabled public String productId;
    @AuraEnabled public String productName;
    @AuraEnabled public String imageUrl;
	@AuraEnabled public String listPrice;
    @AuraEnabled public String salesPrice;


}