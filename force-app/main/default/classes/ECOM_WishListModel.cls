/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM - 801   
*
* 2. Description - This class acts as a wrapper for wishlist data.
*
*
*
* 3. Objects referenced
*    -Wishlist
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
*
* 5. Dependant Class(es):
*    - None
*	
* 6. Test Class Name:         
*    - ECOM_WishListModel_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vipul 2023.08.19

*************************************************************/
public class ECOM_WishListModel {
    @AuraEnabled public String wishListId;
    @AuraEnabled public String accountId;
    @AuraEnabled public String wishlistProductCount;
    @AuraEnabled public String wishListName;
    @AuraEnabled public String ownerId;
    @AuraEnabled public Boolean isDefault; //ECOM_Default__c 
    @AuraEnabled public List<ECOM_WishListItemModel> wishListItems;
}