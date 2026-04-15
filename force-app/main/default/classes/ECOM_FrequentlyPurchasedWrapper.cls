/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*	  - ECOM-1224
*
*
* 2. Description - Wrapper class for Frequently Purchased Products
*
*
* 3. Objects referenced
*    -Product2
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_FrequentlyPurchasedController
* 	 - ECOM_FrequentlyPurchasedUtil
*
* 6. Test Class Name: 
*    - ECOM_TODO
*
* 7. Is @Invocable: No
*
* 8. Author Name(s):
*    - Vasudev Ramachandran 18 Dec 2023
*************************************************************/
public class ECOM_FrequentlyPurchasedWrapper {
    
    @AuraEnabled public List<Product> products;
    @AuraEnabled public List<WishlistItem> wishlistsItems;
    
    public class Product{
        @AuraEnabled public String productId;
        @AuraEnabled public String productName;
        @AuraEnabled public String productPACCode;
        @AuraEnabled public String productBusinessUnit;
        @AuraEnabled public String productPortfolioLevel2;
        @AuraEnabled public String productLine;
        @AuraEnabled public String productClass;
        @AuraEnabled public String productBrand;
        @AuraEnabled public String productSapstatus;
        @AuraEnabled public String productCurrencyCode;
        @AuraEnabled public String productPartNumber;
        @AuraEnabled public String productDisplayUrl;
        @AuraEnabled public String productNavigationUrl;
        
        @AuraEnabled public Integer productQuantity;
        @AuraEnabled public Integer productPurchaseCount;
        
        @AuraEnabled public Double productPrice;
        @AuraEnabled public Double productListPrice;
        
        @AuraEnabled public Boolean productHasImage;
    }

    

}