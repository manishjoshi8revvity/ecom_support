/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM -    
*
* 2. Description - This class is used to retrieve Account, Account Contact relation records and also manipulate records.
*					- returns the wishlist and wishlist item record 
					- returnsAccount records nased on Domain
					- update or Insert the email preferences
*
*
* 3. Objects referenced
*	 - Account
*    - AccountContactRelation
*    - ECOM_Email_Preferences__c
*    - WishList
*    - ContactPointAddress
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
*
* 5. Dependant Class(es):
*    - ECOM_AccountUtil
*    - ECOM_AccountService
*    - ECOM_SalesforceAPI
*
* 6. Test Class Name: 
*    - ECOM_AccountRepo_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vipul 2023.07.19
*    - Manoj 2023.09.20
*    - Sidak 2024.04.04 - Added CurrencyIsoCode field in method getAccountBasedOnIds - RWPS-419
*    - Sidak 2024.04.04 - Updated parameter accountIds type to Set in method getPunchoutAccountsForAccountIds - RWPS-1809
*    - Manish Joshi 2025.01.27 - Updated method fetchWishList,fetchWishListById to retrieved product display name - RWPS-2270
*    - Prabhat Kumar 2025.05.28 - Added method getAccountWithAbondonedCarts to fetch accounts with abandoned carts - RWPS-3197
*    - Prabhat Kumar 2025.30.06 - Added method deleteNonSellableWishListItems to delete non-sellable wishlist items - RWPS-2786
*************************************************************/
public without sharing class ECOM_AccountRepo {
    
    /**
    * @description This method is used to get the Wishlist by owner id
    * @author Rani Thumma| 19-09-2023 
    * @param ownerId
    **/
    public static List<WishList> fetchWishList(String ownerId){
        try {
            List<WishList> wishlist = [SELECT Id, AccountId, Account.Name, WishlistProductCount, WebStoreId, Name, OwnerId, ECOM_Default__c,
                                   (SELECT Id, Product2.Name, Product2.Id, CurrencyIsoCode,Product2.Product_Display_Name__c  FROM WishlistItems) //RWPS-2270
                                   FROM Wishlist where OwnerId = :ownerId];
                                   
            return wishList;
           } 
            catch (System.QueryException e) {
                ECOM_ApplicationLogsUtil.logFailure(e, ECOM_Constant.USER_MODULE_NAME, 'AccountRepo',  'fetchWishList', '', UserInfo.getUserName());//RWPS-Exception
                return new List<WishList>();
            }
    }
    /**
    * @description This method is used to get the Wishlist by id
    * @author Rani Thumma | 09-09-2023 
    * @param wishListId
    **/
    public static List<WishList> fetchWishListById(String wishListId){
        List<WishList> wishlist = [SELECT Id, AccountId, Account.Name, WishlistProductCount, WebStoreId, Name, OwnerId, ECOM_Default__c,
                                   (SELECT Id, Product2.Name, Product2.Id,Product2.Product_Display_Name__c FROM WishlistItems) //RWPS-2270
                                   FROM Wishlist where Id = :wishListId];
        return wishList;
    }
   
    public static List<Account> getAccountBasedOnIds(List<String> accs)
    {
        List<Account> accounts=[ SELECT Id,AccountNumber,
                                 SAP_Customer_Number_Formatted__c,SAP_Customer_Base_Name__c,
                                 BillingStreet,BillingCity, 
                                 BillingState,BillingPostalCode,
                                 BillingCountry,ShippingStreet, ShippingCity, 
                                 ShippingState, ShippingPostalCode,
                                 ShippingCountry, CurrencyIsoCode 
                                 FROM Account WHERE 
                                 Id IN :accs
                               ];
        return accounts;
    }

    /**
    * @description This method is used to get the Email Preferences
    * @author Dar Wright | 09-05-2023 
    * @param acctId
    **/
    public static List<ECOM_Email_Preferences__c> getEmailPreferences(String acctId) { 
        List<ECOM_Email_Preferences__c> eepList = [SELECT Id, ECOM_Account__c,
                                                    ECOM_Contact__c, ECOM_Email__c, 
                                                    ECOM_Order_Confirmation__c, ECOM_Shipment_Notification__c, ERP_Address__c, Ecom_Opt_Out_from_Cart_Emails__c//RWPS-3306
                                                    FROM ECOM_Email_Preferences__c
                                                    WHERE ECOM_Account__c =: Id.valueOf(acctId)
        ];
        return eepList;
    }

    /**
    * @description This method is used to upsert the Email Preferences
    * @author Dar Wright | 09-05-2023 
    * @param eepList
    **/
    public static void upsertEmailPreferences(List<ECOM_Email_Preferences__c> eepList) { 
        try{
            upsert eepList;
        } catch(DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
    }

     /**
    * @description This method is used to delete the Email Preference Record(s)
    * @author Dar Wright | 09-05-2023 
    * @param eepList
    **/
    public static void deleteEmailPreferences(List<ECOM_Email_Preferences__c> eepList) { 
        try{
            delete eepList;
        } catch(DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
    }
    
    public static List<Account> getAccountBasedOnDomainsAndCountry(String domain,String country)
    {
        String start=domain+',%';
        String mid='%,'+domain+',%';
        String endString='%,'+domain;
        List<Account> accounts=[ Select id,AccountNumber,
                                 SAP_Customer_Number_Formatted__c,
                                 BillingStreet,BillingCity, 
                                 BillingState,BillingPostalCode,
                                 BillingCountry,ShippingStreet, ShippingCity, 
                                 ShippingState, ShippingPostalCode,
                                 ShippingCountry 
                                 from Account where 
                                 (Account_Domains__c=:domain 
                                 or 
                                 Account_Domains__c like :start
                                 or 
                                 Account_Domains__c like :mid
                                 or 
                                 Account_Domains__c like :endString) 
                                 and
                                 ShippingCountry=:country
                               ];
        return accounts;
    }

    public static List<Account> getAccounBasedOnAccountNumberAndDomain(String accNumber,String domain)
    {
        String start=domain+',%';
        String mid='%,'+domain+',%';
        String endString='%,'+domain;
        List<Account> accounts=[ Select id,AccountNumber,
                                 SAP_Customer_Number_Formatted__c,
                                 BillingStreet,BillingCity, 
                                 BillingState,BillingPostalCode,
                                 BillingCountry,ShippingStreet, ShippingCity, 
                                 ShippingState, ShippingPostalCode,
                                 ShippingCountry 
                                 from Account where 
                                 (Account_Domains__c=:domain 
                                 or 
                                 Account_Domains__c like :start
                                 or 
                                 Account_Domains__c like :mid
                                 or 
                                 Account_Domains__c like :endString) 
                                 and
                                 SAP_Customer_Number_Formatted__c=:accNumber
                               ];
        return accounts;
    }

    // Fetch wish list summary
    public static ConnectApi.WishlistsSummary getWishlistSummaries(String webstoreId, String effectiveAccountId, String productFields, List<ConnectApi.WishlistItemSortOrder> listSortItemsBy){
        ConnectApi.WishlistsSummary response = Test.isRunningTest() ? ECOM_TestUtil.getWishlistsSummaryData():ECOM_SalesforceAPI.getWishlistSummaries(webstoreId, effectiveAccountId, productFields, listSortItemsBy);
        return response;
    }
    
    //Create Wish list
    public static ConnectApi.Wishlist createWishlist(String webstoreId, String effectiveAccountId, ConnectApi.WishlistInput wishlistInput){
        ConnectApi.Wishlist response = Test.isRunningTest() ? null:ECOM_SalesforceAPI.createWishlist(webstoreId, effectiveAccountId, wishlistInput);
        return response;
    }
    
    //Create Wish list Item
    public static ConnectApi.WishlistItem addItemToWishlist(String webstoreId, String effectiveAccountId, String wishlistId, ConnectApi.WishlistItemInput wishlistItemInput){
        ConnectApi.WishlistItem response = Test.isRunningTest() ? null:ECOM_SalesforceAPI.addItemToWishlist(webstoreId, effectiveAccountId, wishlistId, wishlistItemInput);
        return response;
    }

    //Remove Wishlist item using Std API
    public static Void removeWishlistItem(String webstoreId, String effectiveAccountId, String wishlistId, String wishlistItemId){
       if(!Test.isRunningTest()){
            ECOM_SalesforceAPI.removeWishlistItem(webstoreId, effectiveAccountId, wishlistId, wishlistItemId);
        }
    } 
    //RWPS-2786 - Start
    public static void deleteNonSellableWishListItems(List<String> productSet){

       delete[select id from WishlistItem where Product2Id IN: productSet AND Wishlist.ownerId =: UserInfo.getUserId()];
    }
     //RWPS-2786 - End

    //Delete wishlist item using SOQL
    public static Void removeWishlistItem(String wishlistItemId){
        WishlistItem wishlistItemToRemove = [SELECT Id FROM WishlistItem WHERE Id =: wishlistItemId];
        delete wishlistItemToRemove;
    }

    public static ConnectApi.CartItem addItemToCart(String webstoreId, String effectiveAccountId, String activeCartOrId, ConnectApi.CartItemInput cartItemInput){
        ConnectApi.CartItem response = Test.isRunningTest() ? null: ECOM_SalesforceAPI.addItemToCart(webstoreId, effectiveAccountId, activeCartOrId, cartItemInput);
        return response;
    }
    
    public static void updateWishListOwner(String wishListId, String OwnerId){
        WishList wl = new WishList();
        wl.Id = wishListId;
        wl.OwnerId = OwnerId;
        update wl;
    }

    //get dummy Account based on its name
    public static Account getDummyAccountByName(String dummyAccountName){
        return [SELECT Id, Name FROM Account WHERE Name =: dummyAccountName];
    }
    
    /**
     * @description method to fetch accounts, for names which match the search string and is marked as punchout
     * @author vramachandran@rafter.one | 11 Dec 2023
     * @param searchString
     * return List<Account>
     */
    public static List<Account> getAccountsForSearchString(String searchString){
        final String KEY = searchString +'%';
        final String SPACED_KEY = '% '+ searchString + '%';
        return [SELECT Id, Name,AccountNumber FROM Account WHERE Name LIKE :KEY OR NAME LIKE :SPACED_KEY LIMIT 49999];
    }
    
    /**
     * @description fetch punchout user account information for a account Id
     * @author vramachandran@rafter.one | 11 Dec 2023
     * @param accountId
     * @return List<Account>
     */
    public static List<Account> getPunchoutAccountInformation(String accountId){
        return [SELECT Id, Name, ECOM_PO_Display_List_Price__c, ECOM_Is_Punchout_Account__c, 
                ECOM_PO_Product_Catalog_Exclude_Query__c, ECOM_PO_Product_Catalog_Include_Query__c, 
                ECOM_Punchout_Company_Name__c, ECOM_Punchout_Customer_Org_Logo__c, ECOM_Punchout_CXML_Or_OCI__c, 
                ECOM_Punchout_Description__c, ECOM_Punchout_Domain__c, ECOM_Punchout_Platform_Name__c, 
                ECOM_Punchout_UOM__c  
                FROM Account
               	WHERE Id =: accountId 
               	LIMIT 1];
    }
    
    /**
     * @description This method returns the accounts for a given account ids
     * @author vramachandran@rafter.one | 07 Jan 2024
     * @author ssingh@rafter.one | 05 Nov 2024 | RWPS-1809
     * @param accountIds | Set<String>
     * @returns List<Account>
     */
    public static List<Account> getPunchoutAccountsForAccountIds(Set<String> accountIds){
        return [SELECT Id, Name
               	FROM Account 
               	WHERE Id in: accountIds
               	LIMIT 49999];
    }

     /**
     * @description This method returns list of accounts with abandoned carts
     * @author Prabhat Kumar | 028 May 2025
     * @param cartIds | Set<id>
     *  @param accountIds | Set<id>
     * @returns List<Account>
     */
    public static List<Account> getAccountWithAbondonedCarts(Set<id> cartIds, Set<id> accountIds){

        return[select id, (select id, ownerId from Carts where id IN: cartIds) from account where id IN: accountIds];
    }
    
    

}