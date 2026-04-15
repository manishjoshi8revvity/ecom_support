/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM- 69  
*
* 2. Description - This class is an wrapper class for account data.
				- return Billing Details and Shipping Details Wrapper
				- return Account Detail Wrapper
				- return Wishlist Detail Wrapper
*
*
*
* 3. Objects referenced
*    -None
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
*
* 5. Dependant Class(es):
*    - ECOM_AccountUtil
*	 - ECOM_LoginWrapper
*    - ECOM_AccountService
*	
* 6. Test Class Name: 
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vipul 2023.07.19
*    - Rani 2023.08.18
*    - Manish Joshi 2025.02.28 - Updated inner class Response for first_order_placed flag - RWPS-2684
*    - Manish Joshi 2025.04.16 - Updated inner class Response for recentlyOrderedItems list - RWPS-3023
*    - Chirag L 2025.09.29 - Added new attributes for dealer changes - RWPS-4475
*************************************************************/
global class ECOM_AccountWrapper {
    
    //This class is used to bind account data
    global class AccountDetails
    {
        @AuraEnabled
        global String accountName;
        @AuraEnabled
        global String accountId;
        @AuraEnabled
        global String sapAccountNumber;
        @AuraEnabled
        global String location;
        @AuraEnabled
        global String allowRadioaActiveProductsBooking;
        @AuraEnabled
        global List<ShippingDetails> shipToDetails;
        @AuraEnabled
        global List<BillingDetails> billToDetails;
        @AuraEnabled
        global Boolean isCPA;
        @AuraEnabled
        global Boolean isDealer; // RWPS-4475

        global AccountDetails(){
            accountName='';
            accountId='';
            shipToDetails=new List<ShippingDetails>();
            billToDetails=new List<BillingDetails>();
            sapAccountNumber='';
        }
    }
    
    //This class is used to bind shipping details(address).
    global class ShippingDetails
    {
        @AuraEnabled
        global String shipToId;
        @AuraEnabled
        global String sapAccountNumber;
        @AuraEnabled
        global String shipToName;
        @AuraEnabled
        global String shipToStreet;
        @AuraEnabled
        global String shipToCity;
        @AuraEnabled
        global String shipToState;
        @AuraEnabled
        global String shipToCountry;
        @AuraEnabled
        global String shipToPostalCode;
    }
    
    //This class is used to bind billing details(address).
    global class BillingDetails
    {
        @AuraEnabled
        global String billToId;
        @AuraEnabled
        global String sapAccountNumber;
        @AuraEnabled
        global String billToName;
        @AuraEnabled
        global String billToStreet;
        @AuraEnabled
        global String billToCity;
        @AuraEnabled
        global String billToState;
        @AuraEnabled
        global String billToCountry;
        @AuraEnabled
        global String billToPostalCode;
    }
    
    //this class is to accept fetchAccount details request
    public class Request{
        @AuraEnabled
        public String userId;
    }
    
	//this class is to send fetchAccount details response
    public class Response{
        @AuraEnabled
        public Boolean success;
        @AuraEnabled
        public String varMessage;
        @auraEnabled 
        public String firstName;
        @auraEnabled 
        public String lastName;
        @auraEnabled 
        public String emailId;
        @auraEnabled 
        public String userId;
        @auraEnabled 
        public String isMappedAccount;
        @auraEnabled 
        public String redirectURL;
        @auraEnabled 
        public Boolean isApprovalNeeded;
        @AuraEnabled
        public List<AccountDetails> accountDetails;
        @AuraEnabled
        public ECOM_CartModel cartDetails;
        @AuraEnabled
        public List<WishlistDetails> wishlistDetails;
        @AuraEnabled
        public List<ECOM_WishListModel> wishListModels;
        @AuraEnabled
        public ECOM_PunchoutAccountModel punchoutAccount{get;set;} //VRa-punchout changes
        @AuraEnabled
        public List<String> frequentlyOrderedProducts{get;set;}//VRa-punchout changes
        @AuraEnabled
        public Boolean isPunchoutUser;//VRa-punchout changes
        @AuraEnabled
        public Boolean firstOrderPlaced;//RWPS-2684
        @AuraEnabled
        public List<String> recentlyOrderedItems;//RWPS-3023
        @AuraEnabled
        public String ecomRegistrationCountry; // RWPS-4475
    }
    
    //This class to Buiild information about users wishlist
    public class WishlistDetails{
        @AuraEnabled
        public String userAccountName;
        @AuraEnabled
        public String userAccountId;
        @AuraEnabled
        public List<ECOM_WishListModel> wishListModels;
        public WishlistDetails(){
            userAccountName = '';
            userAccountId = '';
            wishListModels = new List<ECOM_WishListModel>();
        }
    }
    
    //this class is used to build options for combobox //VRa-Punchout changes
    public class ComboBoxWrapper{
        @AuraEnabled
        public String value;
        @AuraEnabled
        public String label;
    }
    
    //This class is used to build punchout //VRa-Punchout changes
    public class PunchoutAccountModel{
        @AuraEnabled
        public String accountName;
        @AuraEnabled
        public String accountLogo;
        @AuraEnabled
        public String productCatalogIncludeQuery;
        @AuraEnabled
        public String productCatalogExcludeQuery;
        @AuraEnabled
        public Boolean displayListPrice;
    }
    
    

}