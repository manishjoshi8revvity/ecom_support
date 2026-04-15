/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*	 -ECOM-659
*	 -ECOM-638
* 2. Description - This class is used for Account specific transactions
		- return Account Records
		- return Email Preferences based on Account And delete Email preferences
		- return Contact Point Address Shipping Record
*
*
* 3. Objects referenced
*    - Account
*    - ECOM_Email_Preferences__c
*    - ContactPointAddress
*    - WishList
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_AccountWrapper
*    - ECOM_UserRepo
*    - ECOM_CartModel
*    - ECOM_ICartService
*    - ECOM_AccountRepo
*    - ECOM_AccountUtil
*    - ECOM_Util
*    - ECOM_ApplicationLogsUtil
*    - ECOM_AccountContactRelationRepo
*    - ECOM_WishListFlowResponseWrapper
*    - ECOM_SalesforceAPI
*
* 6. Test Class Name:
*    - ECOM_AccountService_Test
*
* 7. Is @Invocable: No
*
* 8. Author Name(s):
*    - Rani Thumma 2023.08.18
*    - Manoj 2023.09.20
*    - Poonam 2025.07.08 Updated method upsertEmailPreferences add field Ecom_Opt_Out_from_Cart_Emails__c for opt out abandoned cart - RWPS-3306
*************************************************************/
public without sharing class ECOM_AccountService implements ECOM_IAccountService{

    public static final String CLASSNAME = 'ECOM_AccountService';

    /**
    * @description This method is used to get the Email Preferences
    * @author Dar Wright | 09-05-2023
    * @param acctId
    **/
    public static List<ECOM_Email_Preferences__c> getEmailPreferences(String acctId) {
        return ECOM_AccountRepo.getEmailPreferences(acctId);
    }

    /**
    * @description This method is used to upsert the Email Preferences
    * @author Dar Wright | 09-05-2023
    * @param changesList
    **/
    public static void upsertEmailPreferences(String changesList) {

        List<Object> emailUpdates = (List<Object>)JSON.deserializeUntyped(changesList);
        List<ECOM_Email_Preferences__c> eepList = new List<ECOM_Email_Preferences__c> ();
        for(Object emlObj : emailUpdates ){
            ECOM_Email_Preferences__c eep = new ECOM_Email_Preferences__c();
            Map<String, Object> emailData = (Map<String, Object>)emlObj;
            eep.Id = (Id)emailData.get('Id');
            String erpAddress = (String)emailData.get('ERP_Address__c');//RWPS-3306
            eep.ERP_Address__c = String.isBlank(erpAddress) ? null : erpAddress;//RWPS-3306
            eep.ECOM_Contact__c = (String)emailData.get('ECOM_Contact__c');
            eep.ECOM_Order_Confirmation__c = (Boolean)emailData.get('ECOM_Order_Confirmation__c');
            eep.ECOM_Shipment_Notification__c = (Boolean)emailData.get('ECOM_Shipment_Notification__c');
            eep.ECOM_Email__c = (String)emailData.get('ECOM_Email__c');
            eep.Ecom_Opt_Out_from_Cart_Emails__c = (Boolean)emailData.get('Ecom_Opt_Out_from_Cart_Emails__c');//RWPS-3306
            eepList.add(eep);
        }
        ECOM_AccountRepo.upsertEmailPreferences(eepList);
    }

    /**
    * @description This method is used to delete the Email Preference Record(s)
    * @author Dar Wright | 09-05-2023
    * @param deleteList
    **/
    public static void deleteEmailPreferences(String deleteList) {

        List<Object> emailDels = (List<Object>)JSON.deserializeUntyped(deleteList);
        List<ECOM_Email_Preferences__c> eepList = new List<ECOM_Email_Preferences__c> ();
        for(Object emlObj : emailDels ){
            ECOM_Email_Preferences__c eep = new ECOM_Email_Preferences__c();
            Map<String, Object> emailData = (Map<String, Object>)emlObj;
            eep.Id = (Id)emailData.get('Id');
            eep.ECOM_isActive__c = false;
            eepList.add(eep);
        }

        ECOM_AccountRepo.upsertEmailPreferences(eepList);
    }

    /**
    * @description  get  logged in user wishlist summary
    * @author mkumar@rafter.one | 09-20-2023
    * @param webstoreId
    * @param effectiveAccountId
    * @param productFields
    * @param listSortItemsBy
    * @return ConnectApi.WishlistsSummary
    **/
    public static ConnectApi.WishlistsSummary getWishlistSummaries(String webstoreId, String effectiveAccountId, String productFields, List<ConnectApi.WishlistItemSortOrder> listSortItemsBy){
        return ECOM_AccountRepo.getWishlistSummaries(webstoreId, effectiveAccountId, productFields, listSortItemsBy);
    }

    /**
    * @description  remove product fron wishlist (Favoirites)
    * @author mkumar@rafter.one | 09-20-2023
    * @param wishlistItemId
    * @return Void
    **/
    public static Void removeWishlistItem(String wishlistItemId){
       ECOM_AccountRepo.removeWishlistItem(wishlistItemId);
    }

    /**
    * @description  Add product to cart
    * @author mkumar@rafter.one | 09-20-2023
    * @param webstoreId
    * @param effectiveAccountId
    * @param activeCartOrId
    * @param cartItemInput
    * @return ConnectApi.CartItem
    **/
    public static ConnectApi.CartItem addItemToCart(String webstoreId, String effectiveAccountId, String activeCartOrId, ConnectApi.CartItemInput cartItemInput){
        return ECOM_AccountRepo.addItemToCart(webstoreId, effectiveAccountId, activeCartOrId, cartItemInput);
    }

    /**
    * @description  get wishlist by owner id
    * @author mkumar@rafter.one | 09-20-2023
    * @param ownerId
    * @return List<WishList>
    **/
    public static List<WishList> fetchWishList(String ownerId){
        return ECOM_AccountRepo.fetchWishList(ownerId);
    }

    /**
    * @description  Check SAP account number
    * @author mkumar@rafter.one | 09-20-2023
    * @param accNumber
    * @param domain
    * @return Map<String, Object>
    **/
    public static Map<String,Object> checkAccountNumber(String accNumber,String domain){
        Map<String,Object> returnMap=new Map<String,Object>();
        List<Account> accs=ECOM_AccountRepo.getAccounBasedOnAccountNumberAndDomain(accNumber,domain);
        if(accs.isEmpty())
        {
            returnMap.put('Success',false);
            returnMap.put('ErrorMessage','Account Number Not Found');
        }
        else {
            returnMap.put('Success',true);
            returnMap.put('AccountId',accs[0].Id);
        }
        return returnMap;
    }

    /**
    * @description  get accounts by ids
    * @author mkumar@rafter.one | 09-20-2023
    * @param accIds
    * @return List<Account>
    **/
    public static List<Account> getAccountBasedOnIds(List<String> accIds)
    {
        return ECOM_AccountRepo.getAccountBasedOnIds(accIds);
    }

    /**
    * @description
    * @author mkumar@rafter.one | 09-20-2023
    * @param request
    * @param user
    * @return ECOM_WishListFlowResponseWrapper
    **/
    public static ECOM_WishListFlowResponseWrapper wishListOperations(ECOM_WishListFlowWrapper.Request request , User user){

        ECOM_WishListFlowResponseWrapper wishlistResponse = new ECOM_WishListFlowResponseWrapper();
        String methodName = 'wishListOperations';
        String supportData = '';
        String webstoreId = ECOM_Util.getWebStoreIdByName();
        try{
            if(request.action == ECOM_Constant.WISHLIST_ACTION_ADD){
                // Check if Wish list is created for logged in user
                if(request != null && String.isBlank(request.wishlistId) &&  String.isNotBlank(request.userId)){
                    List<WishList> wishLists = ECOM_AccountRepo.fetchWishList(request.userId);
                    // create wish list and add wish list item
                    if(wishLists == null || (wishLists != null && wishLists.isEmpty())){
                        ConnectApi.WishlistInput wishlistInput = new ConnectApi.WishlistInput();
                        List<ConnectApi.WishlistItemInput> items = new List<ConnectApi.WishlistItemInput>();
                        ConnectApi.WishlistItemInput item = new ConnectApi.WishlistItemInput();
                        item.productId = request.ProductId;
                        items.add(item);
                        wishlistInput.name = user.Name + ' Wish list';
                        wishlistInput.products = items;
                        ConnectApi.Wishlist wishList = ECOM_AccountRepo.createWishlist(webstoreId, user.AccountId, wishlistInput);
                        wishlistResponse = ECOM_AccountUtil.wishListReponse(ECOM_AccountUtil.parseWishListSummary(wishList),'Product was successfully added to favorites.', true);
                    	// update wishlist owner id
                        ECOM_AccountRepo.updateWishListOwner(wishlistResponse.wishlistId, request.userId);
                    } else if(wishLists.size() > 0){
                        //if user has wishlist created add the product to existing wishlist
                        ConnectApi.WishlistItemInput wishlistItemInput = new ConnectApi.WishlistItemInput();
                        wishlistItemInput.productId = request.ProductId;
                        ConnectApi.WishlistItem wishListItem = ECOM_AccountRepo.addItemToWishlist(webstoreId, user.AccountId, wishLists[0].Id, wishlistItemInput);
                        wishlistResponse = ECOM_AccountUtil.wishListReponse(request.wishlistId, 'Product was successfully added to favorites.', true);
                    }
                    //if wish list id is not blank add wish list item
                } else if(String.isNotBlank(request.wishlistId)){
                    List<WishList> wishLists = ECOM_AccountRepo.fetchWishListById(request.wishlistId);
                    if(wishLists != null && wishLists.size() > 0){
                        String effectiveID = wishLists[0].AccountId;
                        ConnectApi.WishlistItemInput wishlistItemInput = new ConnectApi.WishlistItemInput();
                        wishlistItemInput.productId = request.ProductId;
                        System.debug('wishlistItemInput ==== '+wishlistItemInput);
                        ConnectApi.WishlistItem wishListItem = ECOM_AccountRepo.addItemToWishlist(webstoreId, effectiveID, request.wishlistId, wishlistItemInput);
                        wishlistResponse = ECOM_AccountUtil.wishListReponse(request.wishlistId, 'Product was successfully added to favorites.', true);
                    } else{
                        wishlistResponse = ECOM_AccountUtil.wishListReponse(request.wishlistId, 'Favorites is not available in SF', false);
                    }
                }
            } else if (request.action == ECOM_Constant.WISHLIST_ACTION_REMOVE){
                // remove wish list item
                String wishListItemId = '';
                String effectiveAccountID = '';
                if(String.isNotBlank(request.wishlistId)){
                    List<WishList> wishLists = ECOM_AccountRepo.fetchWishListById(request.wishlistId);
                    for(WishList wl :wishLists){
                        effectiveAccountID = wl.Account.Id;
                        for(WishlistItem wli :wl.WishlistItems){
                            if(wli.Product2.Id == request.productId){
                                wishListItemId = wli.Id;
                                break;
                            }
                        }
                    }
                    if(String.isNotBlank(wishlistItemId)){
                        if(!Test.isRunningTest()) {ECOM_SalesforceAPI.removeWishlistItem(webstoreId, effectiveAccountID, request.wishlistId, wishlistItemId);}
                        wishlistResponse = ECOM_AccountUtil.wishListReponse(request.wishlistId, 'Product was removed successfully from favorites.', true);
                    } else {
                        wishlistResponse = ECOM_AccountUtil.wishListReponse(request.wishlistId, 'Product Id is not in favorites to remove.', false);
                    }
                } else {
                    wishlistResponse = ECOM_AccountUtil.wishListReponse(request.wishlistId, 'Favorites id is required to remove the item.', false);
                }
            }
        } catch(Exception ex) {
            wishlistResponse = ECOM_AccountUtil.wishListReponse(request.wishlistId, ex.getMessage(), false);
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.USER_MODULE_NAME, CLASSNAME, methodName, supportData);
        }
        return wishlistResponse;
    }

    /**
    * @description  add items to wishlsit
    * @author mkumar@rafter.one | 09-20-2023
    * @param webstoreId
    * @param effectiveAccountId
    * @param wishlistId
    * @param wishlistItemInput
    * @return ConnectApi.WishlistItem
    **/
    public static ConnectApi.WishlistItem addItemToWishlist(String webstoreId, String effectiveAccountId, String wishlistId, ConnectApi.WishlistItemInput wishlistItemInput){
        return Test.isRunningTest()? ECOM_TestUtil.getWishlistItemData():ECOM_AccountRepo.addItemToWishlist(webstoreId, effectiveAccountId, wishlistId, wishlistItemInput);
    }

    /**
    * @description  Create wishlist
    * @author mkumar@rafter.one | 09-20-2023
    * @param webstoreId
    * @param effectiveAccountId
    * @param wishlistInput
    * @return ConnectApi.Wishlist
    **/
    public static ConnectApi.Wishlist createWishlist(String webstoreId, String effectiveAccountId, ConnectApi.WishlistInput wishlistInput){
        return Test.isRunningTest()? ECOM_TestUtil.getWishlistDataNew():ECOM_AccountRepo.createWishlist(webstoreId, effectiveAccountId, wishlistInput);
    }

    /**
    * @description get dummy Account based on its name to map it to CPAs.
    * @author mkumar@rafter.one | 09-20-2023
    * @param dummyAccountName
    * @return Account
    **/
    public static Account getDummyAccountByName(String dummyAccountName){
        return ECOM_AccountRepo.getDummyAccountByName(dummyAccountName);
    }

    /**
    * @description
    * @author Vipul Goyal | 11-12-2023
    * @param contactId
    * @param accountId
    * @return Map<String, Object>
    **/
    public static Map<String,Object> deleteTemporaryACR(String contactId,String accountId)
    {
        Map<String,Object> responseMap = new Map<String,Object>();
        try
        {
            ECOM_AccountContactRelationRepo.deleteTemporaryACR(contactId,accountId);
            responseMap.put('Success',true);
        }catch(Exception e)
        {
            responseMap.put('Success',false);
            responseMap.put('ErrorMessage',e.getMessage());
        }
        return responseMap;
    }

    /**
     * @description returns Account list for a user
     * @author vramachandran@rafter.one | 11 Dec 2023
     * @param accountId
     * @returns List<Account>
     */
    public List<Account> getPunchoutAccountRecordForId(String accountId){
        return ECOM_AccountRepo.getPunchoutAccountInformation(accountId);
    }

}