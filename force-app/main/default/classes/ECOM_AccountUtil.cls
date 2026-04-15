/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    - ECOM-69    
*	 - ECOM-659
*	 - ECOM-638
* 	 - ECOM-1028
* 2. Description - This class acts as a utility class for accounts.
*				 - return List of Account Records in ECOM_AccountWrapper Type.
				 - return Contact point address
				 - Create Billing Data and return Wishlist Records
				 - Create Map for combobox
*
*
* 3. Objects referenced
*    - Account
*    - Account_Function__c
*    - Contact
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
*
* 5. Dependant Class(es):
*    - ECOM_UserUtil
*    - ECOM_AccountWrapper
*    - ECOM_ContactRepo
*    - ECOM_AccountContactRelationRepo
*    - ECOM_WishListItemModel
*    - ECOM_WishListFlowResponseWrapper
*    - ECOM_AccountService
*    - ECOM_DashboardRepo
*    - ECOM_OrderHistoryController
*
* 6. Test Class Name: 
*    - ECOM_AccountUtil_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vipul 2023.07.19
*    - Rani 2023.09.09 
*    - Sidak 2024.11.11 - Added parameter getAccountNameMap in method getAccountNameMap to append country name in label - RWPS-1809
*************************************************************/

public without sharing class ECOM_AccountUtil {
    
    //This method is used to get the Account details of a user.

    /**
    * @description 
    * @author Vipul 2023.07.19 
    * @param contactId String
    * @param accountId  String
    * @param isDirectDetailsOnly 
    * @return List<ECOM_AccountWrapper.AccountDetails> 
    **/
    /*public static List<ECOM_AccountWrapper.AccountDetails> getAccountDetails(String contactId,String accountId,Boolean isDirectDetailsOnly)
    {
        List<ECOM_AccountWrapper.AccountDetails> accountDetails=new List<ECOM_AccountWrapper.AccountDetails>();
        if(String.isBlank(contactId)){
            return accountDetails;
        }
        if(isDirectDetailsOnly){
            Contact userContact=ECOM_ContactRepo.getContactBasedOnId(contactId);
            if(String.isNotBlank(userContact.ECOM_DefaultBillToAccount__c) && String.isNotBlank(userContact.ECOM_DefaultShipToAccount__c))
            {
                accountDetails=createAccountDetailList(userContact);
            }
            else if(String.isNotBlank(userContact.ECOM_DefaultBillToCPA__c) && String.isNotBlank(userContact.ECOM_DefaultShipToCPA__c))
            {
                accountDetails=getCPA(userContact);
            } 
        }else{
            List<String> accountIds=new List<String>();
            accountIds= ECOM_AccountContactRelationRepo.getAssociatedAccounts(contactId); 
            System.debug('accountIds : '+accountIds);
            List<Account_Function__c> accountFunctions= ECOM_AccountFunctionRepo.getAccountFunctions(accountIds,new List<String>{'RG','WE'});
            System.debug('Account_Function__c : '+JSOn.serialize(accountFunctions));
            accountDetails=createAccountDetailList(accountFunctions);
            System.debug('accountDetails : '+JSON.serialize(accountDetails));
        }
        return accountDetails;
    }*/

    /*public static List<ECOM_AccountWrapper.AccountDetails> getCPA(Contact userContact)
    {
        List<ECOM_AccountWrapper.AccountDetails> accountDetailsList=new List<ECOM_AccountWrapper.AccountDetails>();
        ECOM_AccountWrapper.AccountDetails accountDetails=new ECOM_AccountWrapper.AccountDetails();
        accountDetails.accountName=userContact.Account.Name;
        accountDetails.accountId=userContact.AccountId;
        accountDetails.sapAccountNumber=userContact.Account.SAP_Customer_Number_Formatted__c;
        accountDetails.allowRadioaActiveProductsBooking='false';
        List<ECOM_AccountWrapper.ShippingDetails> shippingDetailsList=new List<ECOM_AccountWrapper.ShippingDetails>();
        if(String.isNotBlank(userContact.ECOM_DefaultShipToCPA__c))
        {
            ECOM_AccountWrapper.ShippingDetails shippingDetails= new ECOM_AccountWrapper.ShippingDetails ();
            shippingDetails.shipToId=userContact.ECOM_DefaultShipToCPA__c;
            shippingDetails.shipToName=userContact.ECOM_DefaultShipToCPA__r.Name;
            shippingDetails.shipToStreet=userContact.ECOM_DefaultShipToCPA__r.Street;
            shippingDetails.shipToState=userContact.ECOM_DefaultShipToCPA__r.State;
            shippingDetails.shipToCity=userContact.ECOM_DefaultShipToCPA__r.City;
            shippingDetails.shipToCountry=userContact.ECOM_DefaultShipToCPA__r.Country;
            shippingDetails.shipToPostalCode=userContact.ECOM_DefaultShipToCPA__r.PostalCode;
            shippingDetailsList.add(shippingDetails);
        }
        List<ECOM_AccountWrapper.BillingDetails> billingDetailsList=new List<ECOM_AccountWrapper.BillingDetails>();
        if(String.isNotBlank(userContact.ECOM_DefaultBillToCPA__c))
        {
            ECOM_AccountWrapper.BillingDetails billingDetails= new ECOM_AccountWrapper.BillingDetails ();
            billingDetails.billToId=userContact.ECOM_DefaultBillToCPA__c;
            billingDetails.billToName=userContact.ECOM_DefaultBillToCPA__r.Name;
            billingDetails.billToStreet=userContact.ECOM_DefaultBillToCPA__r.Street;
            billingDetails.billToState=userContact.ECOM_DefaultBillToCPA__r.State;
            billingDetails.billToCity=userContact.ECOM_DefaultBillToCPA__r.City;
            billingDetails.billToCountry=userContact.ECOM_DefaultBillToCPA__r.Country;
            billingDetails.billToPostalCode=userContact.ECOM_DefaultBillToCPA__r.PostalCode;
            billingDetailsList.add(billingDetails);
        }
        accountDetails.shipToDetails=shippingDetailsList;
        accountDetails.billToDetails=billingDetailsList;
        // if(billingDetailsList.size()>0 && shippingDetailsList.size()>0){
        //     accountDetails.isCPA = true;
        // }
        accountDetailsList.add(accountDetails);
        return accountDetailsList;

    }
*/
    
    /**
    * @description 
    * @author Vipul 2023.07.19 
    * @param userContact 
    * @return List<ECOM_AccountWrapper.AccountDetails> 
    **/
    /*public static List<ECOM_AccountWrapper.AccountDetails> createAccountDetailList(Contact userContact)
    {
        List<ECOM_AccountWrapper.AccountDetails> accountDetails=new List<ECOM_AccountWrapper.AccountDetails>();
        ECOM_AccountWrapper.AccountDetails temp= new ECOM_AccountWrapper.AccountDetails();
        temp.accountId=userContact.AccountId;
        temp.accountName=userContact.Account.Name;
        temp.sapAccountNumber=userContact.Account.SAP_Customer_Number_Formatted__c;
        temp.billToDetails.add(createBillingData(userContact,'ECOM_DefaultBillToAccount__c'));
        temp.shipToDetails.add(createShippingData(userContact,'ECOM_DefaultShipToAccount__c'));
        accountDetails.add(temp);
        return accountDetails;
    }*/
    
    /**
    * @description This method is used to create the account details list from the Account Functions.
    * @author Vipul 2023.07.19
    * @param accountFunctions 
    * @return List<ECOM_AccountWrapper.AccountDetails> 
    **/
    /*public static List<ECOM_AccountWrapper.AccountDetails> createAccountDetailList(List<Account_Function__c> accountFunctions)
    {        
        Map<String, ECOM_AccountWrapper.AccountDetails> accountIdToWrapperMap=new Map<String, ECOM_AccountWrapper.AccountDetails>();
        for(Account_Function__c accountFunction:accountFunctions)
        {
            ECOM_AccountWrapper.AccountDetails accountDetail= new ECOM_AccountWrapper.AccountDetails();
            Boolean isTargetAvailable=String.isNotBlank(accountFunction.Target_Account__c)?true:false;
            if(accountIdToWrapperMap.containsKey(accountFunction.Source_Account__c)){
                accountDetail=accountIdToWrapperMap.get(accountFunction.Source_Account__c);
            }else
            {
                accountDetail.accountId=accountFunction.Source_Account__c;
                accountDetail.accountName=accountFunction.Source_Account__r.Name;
                //accountDetail.sapAccountNumber=accountFunction.Source_Account__r.AccountNumber;
                accountDetail.sapAccountNumber = accountFunction.Source_Account__r.SAP_Customer_Number_Formatted__c;
                if (accountFunction.Source_Account__r.RAD_Identifier__c == 'RAD'){
                    accountDetail.allowRadioaActiveProductsBooking = 'true';
                } else {
                	accountDetail.allowRadioaActiveProductsBooking = 'false';
                }
            }
            if(accountFunction.SAP_Partner_Type__c.equalsIgnoreCase('RG'))
            {
                accountDetail.billToDetails.add(createBillingData(accountFunction,returnObjectNameToGetAddress(isTargetAvailable)));
            }
            else if(accountFunction.SAP_Partner_Type__c.equalsIgnoreCase('WE'))
            { 
                accountDetail.shipToDetails.add(createShippingData(accountFunction,returnObjectNameToGetAddress(isTargetAvailable)));
            }
            //accountDetail.isCPA = false;
            accountIdToWrapperMap.put(accountFunction.Source_Account__c,accountDetail);
        }
        return accountIdToWrapperMap.values();
    }*/

    /**
    * @description This method is used to accumulate data into Billing Address wrapper. 
    * @author Vipul 2023.07.19
    * @param addressObject 
    * @param objectRelation 
    * @return ECOM_AccountWrapper.BillingDetails 
    **/
    /*public static ECOM_AccountWrapper.BillingDetails createBillingData(sObject addressObject,String objectRelation)
    {
        ECOM_AccountWrapper.BillingDetails billingDetails= new ECOM_AccountWrapper.BillingDetails();
        billingDetails.billToId=(String)addressObject.get(objectRelation);
        objectRelation=objectRelation.replace('__c','__r');
        billingDetails.billToName=(String)addressObject.getSObject(objectRelation).get('Name');
        billingDetails.billToStreet=(String)addressObject.getSObject(objectRelation).get('BillingStreet');
        billingDetails.billToState=(String)addressObject.getSObject(objectRelation).get('BillingState');
        billingDetails.billToCity=(String)addressObject.getSObject(objectRelation).get('BillingCity');
        billingDetails.billToCountry=(String)addressObject.getSObject(objectRelation).get('BillingCountry');
        billingDetails.billToPostalCode=(String)addressObject.getSObject(objectRelation).get('BillingPostalCode');
        //billingDetails.sapAccountNumber=(String)addressObject.getSObject(objectRelation).get('AccountNumber');
        billingDetails.sapAccountNumber=(String)addressObject.getSObject(objectRelation).get('SAP_Customer_Number_Formatted__c');
        return billingDetails;
    }*/
    

    /**
    * @description This method is used to accumulate data into Shipping Address wrapper. 
    * @author Vipul 2023.07.19
    * @param addressObject 
    * @param objectRelation 
    * @return ECOM_AccountWrapper.ShippingDetails 
    **/
    /*public static ECOM_AccountWrapper.ShippingDetails createShippingData(sObject addressObject,String objectRelation)
    {
        ECOM_AccountWrapper.ShippingDetails shippingDetails= new ECOM_AccountWrapper.ShippingDetails();
        shippingDetails.shipToId=(String)addressObject.get(objectRelation);
        objectRelation=objectRelation.replace('__c','__r');
        shippingDetails.shipToName=(String)addressObject.getSObject(objectRelation).get('Name');
        shippingDetails.shipToStreet=(String)addressObject.getSObject(objectRelation).get('ShippingStreet');
        shippingDetails.shipToState=(String)addressObject.getSObject(objectRelation).get('ShippingState');
        shippingDetails.shipToCity=(String)addressObject.getSObject(objectRelation).get('ShippingCity');
        shippingDetails.shipToCountry=(String)addressObject.getSObject(objectRelation).get('ShippingCountry');
        shippingDetails.shipToPostalCode=(String)addressObject.getSObject(objectRelation).get('ShippingPostalCode');
        //shippingDetails.sapAccountNumber=(String)addressObject.getSObject(objectRelation).get('AccountNumber');
        shippingDetails.sapAccountNumber=(String)addressObject.getSObject(objectRelation).get('SAP_Customer_Number_Formatted__c');
        return shippingDetails;
    }*/


    /**
    * @description This method is used to get the address reference.
    * @author Vipul 2023.07.19
    * @param isTargetAvailable 
    * @return String 
    **/
    /*public static String returnObjectNameToGetAddress(Boolean isTargetAvailable)
    {
        return isTargetAvailable?'Target_Account__c':'Source_Account__c';
    }*/
    
    /**
    * @description This method is used to get the wishlist by user id.
    * @author Rani 2023.08.18
    * @param ownerId 
    * @return String 
    **/
    public static List<ECOM_AccountWrapper.WishlistDetails> getWishListDetails(List<WishList> wls){
        
        Map<String, ECOM_AccountWrapper.WishlistDetails> accountToWishListMap = new Map<String,ECOM_AccountWrapper.WishlistDetails>();
        //List<WishList> wls = ECOM_AccountRepo.fetchWishList(ownerId);
        for(WishList w :wls)
        {
            ECOM_AccountWrapper.WishlistDetails temp = new ECOM_AccountWrapper.WishlistDetails();
            ECOM_WishListModel wlm = new ECOM_WishListModel();
            List<ECOM_WishListItemModel> wlts = new List<ECOM_WishListItemModel>();
            if(accountToWishListMap.containsKey(w.AccountId)){
                temp=accountToWishListMap.get(w.AccountId);
            }
            else{
                temp.userAccountId = w.AccountId;
                temp.userAccountName = w.Account.Name;
            }
            //temp.wishlist.add(w);
            wlm.wishListId = w.Id;
    		wlm.accountId = w.AccountId;
    		wlm.wishlistProductCount = String.valueOf(w.WishlistProductCount);
    		wlm.wishListName = w.Name;
   			wlm.ownerId = w.OwnerId;
            wlm.isDefault = w.ECOM_Default__c;
            for(WishListItem wi :w.WishListItems){
                ECOM_WishListItemModel wim = new ECOM_WishListItemModel();
                wim.wishListItemId = wi.Id;
                wim.productId = wi.Product2.Id;
                wim.productName = wi.Product2.Name;
                wlts.add(wim);
            }
            wlm.wishListItems = wlts;
            temp.wishListModels.add(wlm);
            accountToWishListMap.put(w.AccountId,temp);
            System.debug('wishlist === '+temp);
        }
        System.debug('accountToWishListMap === '+accountToWishListMap.values());
        return accountToWishListMap.values();
    }

    /**
    * @description 
    * @author Vickal 2023.08.31 
    * @param contactId String
    * @param accountId  String
    * @return List<ECOM_AccountWrapper.AccountDetails> 
    *
    public static List<ECOM_AccountWrapper.AccountDetails> getAllAccountDetails(String contactId,String accountId)
    {
        List<ECOM_AccountWrapper.AccountDetails> accountDetails=new List<ECOM_AccountWrapper.AccountDetails>();
        if(String.isBlank(contactId)){
            return accountDetails;
        }
        List<String> accountIds=new List<String>();
        accountIds = ECOM_AccountContactRelationRepo.getAssociatedAccounts(contactId); 
        List<Account_Function__c> accountFunctions = ECOM_AccountFunctionRepo.getAccountFunctions(accountIds,new List<String>());
        if(!accountFunctions.isEmpty()){
            accountDetails=createAccountDetailList(accountFunctions);
        }
        return accountDetails;
    }*/
    
    /**
    * @description  - method is used to parse return data from wish list create API
    * @author Rani Thumma 2023.09.09 
    * @param ConnectApi.Wishlist 
    * @return String
    **/
    public static String parseWishListSummary(ConnectApi.Wishlist wishList){
        //ConnectApi.WishlistSummary summary = new ConnectApi.WishlistSummary();
        if(!Test.isRunningTest()) {
            ConnectApi.WishlistSummary summary = wishList.summary;
            String wishListId = summary.Id;
            return wishListId;}
        else{
            ConnectApi.Wishlist response=ECOM_TestUtil.getWishlistDataNew();
            return 'success';
        }
    }
    /**
    * @description  - method is used to prepare wish list API response
    * @author Rani Thumma 2023.09.09 
    * @param WishlistId, Boolean
    * @return wishlistResponse
    **/
    public static ECOM_WishListFlowResponseWrapper wishListReponse(String wishListId, String message, Boolean isSuccess){
        ECOM_WishListFlowResponseWrapper wishlistResponse = new ECOM_WishListFlowResponseWrapper();
        wishlistResponse.success = isSuccess;
        wishlistResponse.wishlistId = wishListId;
        wishlistResponse.message = message;
        return wishlistResponse;
    }
    
    /**
     * @description Returns a map of account name from list of accounts to be displayed as combobox values
     * @author vramachandran@rafter.one | 2023-Dec-01
     * @author ssingh@rafter.one | 11 Nov 2024 | RWPS-1809
     * @param List<Account>
     * @param Map<String,String>
     * @return List<ECOM_AccountWrapper.ComboBoxWrapper>
     */
    public static List<ECOM_AccountWrapper.ComboBoxWrapper> getAccountNameMap(List<Account> accountList, Map<String,String> accountIdToCountryMap){
        List<ECOM_AccountWrapper.ComboBoxWrapper> accountComboboxList = new List<ECOM_AccountWrapper.ComboBoxWrapper>();
        System.debug('accountList:: '+ JSON.serialize(accountList));
        if(null != accountList && !accountList.isEmpty()){
            System.debug('accountList:: '+ JSON.serialize(accountList));
            
            ECOM_AccountWrapper.ComboBoxWrapper wrapper;
            for(Account accountRecord : accountList){
                wrapper = new ECOM_AccountWrapper.ComboBoxWrapper();
                wrapper.label = accountRecord?.Name;
                wrapper.value = accountRecord?.Id;
                if(accountIdToCountryMap.containsKey(accountRecord?.Id) && accountIdToCountryMap.get(accountRecord?.Id) != null){
                    wrapper.label += ' (' + accountIdToCountryMap.get(accountRecord?.Id) + ')';
                }
                accountComboboxList.add(wrapper);
            }
        }
        System.debug('accountComboboxList:: '+ accountComboboxList);
        return accountComboboxList;
    }
    
    /**
     * @description This method returns ECOM_PunchoutAccountModel for account information
     * @author vramachandran@rafter.one | 11 Dec 2023
     * @param accountRecord | Account
     * @return ECOM_PunchoutAccountModel
     */
    public static ECOM_PunchoutAccountModel getPunchoutAccountModel(Account accountRecord){
        ECOM_PunchoutAccountModel poAccountModel = new ECOM_PunchoutAccountModel();
        poAccountModel.accountLogo = accountRecord?.ECOM_Punchout_Customer_Org_Logo__c;
        poAccountModel.accountName = accountRecord?.ECOM_Punchout_Company_Name__c;
        poAccountModel.displayListPrice = accountRecord?.ECOM_PO_Display_List_Price__c;
        if(String.isNotBlank(accountRecord?.ECOM_PO_Product_Catalog_Include_Query__c)) poAccountModel.productCatalogIncludeQuery = accountRecord?.ECOM_PO_Product_Catalog_Include_Query__c;
        if(String.isNotBlank(accountRecord?.ECOM_PO_Product_Catalog_Exclude_Query__c)) poAccountModel.productCatalogExcludeQuery = accountRecord?.ECOM_PO_Product_Catalog_Exclude_Query__c;
        
        return poAccountModel;
    }
    
}