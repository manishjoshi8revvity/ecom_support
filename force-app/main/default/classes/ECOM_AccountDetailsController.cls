/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*	 -ECOM-659
*	 -ECOM-638
* 2. Description - This class is used to get the request from flow 'SUB.FLOW_4497: ECOM - Fetch Account Details' and sends it to service class for further processing.
*	-  prepare request for service layer to process
*   -  check SAP Account number and return Map of Account Record

*
*
* 3. Objects referenced
*    -AccountContactRelation
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
*
* 5. Dependant Class(es):
*    - ECOM_AccountUtil
*    - ECOM_AccountService
*	 - ECOM_ContactController
*	 - ECOM_ContactService
*	 - ECOM_AccountDetailsFlowWrapper
*	 - ECOM_AccountWrapper
*	 - ECOM_AccountDetailsModel
*
* 6. Test Class Name: 
*	- ECOM_AccountDetailsController_Test
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vipul 2023.08.09
*    - Rani Thumma 2023.08.19
*	 - Manoj 2023.09.20
* 	 - vramachandran@rafter.one | 11 Dec 2023
*    - Manoj 2024.05.28 - RWPS-741 SFB2B - Technical - Trim down the Fetch User API - Remove Cart Items
*    - Sidak 2024.09.20 - RWPS-1535 Updated method fetchAccountDetailsByUserId, added logic to fetch the cart items
*    - Manish Joshi 2025.02.28 - Updated method fetchAccountDetailsByUserId, added first order placed flag logic - RWPS-2684
*   -  Prabhat 2025.03.20 - Updated the method fetchAccountDetailsByUserId to pass Cart details - RWPS-2830
*   -  Manish Joshi 2025.04.16 - Updated the method fetchAccountDetailsByUserId, added recentlyOrderedItems logic - RWPS-3023
*   -  Manish Joshi 2025.04.25 - Updated the method fetchAccountDetailsByUserId, added punchout check - RWPS-3023
*   -  Manish Joshi 2025.08.21 - Updated method fetchAccountDetailsByUserId unblocked punchout RWPS-4147
*    - Chirag L 2025.09.29 - Populated mappings for the new attributes related to dealer changes in fetchAccountDetailsByUserId and getAccountDetailsResponse methods - RWPS-4475
*   -  Kushal Shah 2026.03.02 - Updated method getPunchoutAccountModelForAccountId - RWPS-5807
*/
public class ECOM_AccountDetailsController {
    
    public static final String className = 'ECOM_AccountDetailsController';
    
	private static ERP_IAddressService addressService;//VRa- punchout changes
    
    /**
     * This method is used to get the request from flow 'SUB.FLOW_4497: ECOM - Fetch Account Details' and sends it to service class for further processing.
     * @param request List<ECOM_AccountDetailsFlowWrapper.Request>
     * @return List<ECOM_AccountDetailsFlowWrapper.Response>
     * @author Rani Thumma | 2023-08-19
     */
    @InvocableMethod(Label='Fetch Account Details' Category='Account details' Description='This is to fetch details relatated user Accounts')
    public static List<ECOM_AccountDetailsFlowWrapper.Response> fetchAccountDetailsByUserId(List<ECOM_AccountDetailsFlowWrapper.Request> accRequestList) {
        String methodName = 'fetchAccountDetailsByUserId';
        String supportData = accRequestList[0].userId;
        List<ECOM_AccountDetailsFlowWrapper.Response> accResponseList = new List<ECOM_AccountDetailsFlowWrapper.Response>();
        ECOM_AccountWrapper.Response response = new ECOM_AccountWrapper.Response();
        
        try{  
            //fetch user record 
            Type userService = Type.forName(ECOM_Constant.USER_Service);
            ECOM_IUserService userServiceInstance = (ECOM_IUserService)userService.newInstance();
            User u = userServiceInstance.getUserByUser(accRequestList[0].userId);
            
            Type sapOrderSummaryService = Type.forName(ECOM_Constant.SAP_ORDER_SUMMARY_SERIVCE);//VRa-Punchout changes
            ECOM_ISAPOrderSummary sapOrderSummary = (ECOM_ISAPOrderSummary)sapOrderSummaryService.newInstance();//VRa-Punchout changes
            
            if(u != null){
                //Fetch Active Cart
                List<ECOM_CartModel> carts = new List<ECOM_CartModel>();
                ECOM_CartModel cart = new ECOM_CartModel();
                cart.accountId = u.AccountId;
                cart.userId = u.Id;
                carts.add(cart);
                Type cartService = Type.forName(ECOM_Constant.CART_SERVICE);
                ECOM_ICartService cartServiceInstance = (ECOM_ICartService)cartService.newInstance();
                List<ECOM_CartModel> cs = cartServiceInstance.fetchCart(carts);
                //RWPS-741
                //ECOM_CartModel cartModel =  ECOM_cartUtil.populateCartDetailsWithoutCartItem(cs[0].cartId);
                //RWPS-1535
                ECOM_CartModel cartModel =  ECOM_CartUtil.populateCartDetailsWithCartItems(cs[0].cartId);
                response.cartDetails = cartModel;
                System.debug('response.cartDetails service ==> '+response.cartDetails);
                
                //Fetch WishList
                Type accountservice = Type.forName(ECOM_Constant.ACCOUNT_SERVICE);
                ECOM_IAccountService accServiceInstance = (ECOM_IAccountService)accountservice.newInstance();
                List<WishList> wlists = accServiceInstance.fetchWishList(u.Id);
                response.wishlistDetails = ECOM_AccountUtil.getWishListDetails(wlists);
                System.debug('wishListModels.response service ==> '+response.wishlistDetails);
                
                // Account details
                List<ECOM_AccountWrapper.AccountDetails> accDetails = ECOM_UserUtil.getERPAddressDetails(u, cs[0].cartId);//RWPS-2830 - Added Parameter cart ids
                response.accountDetails = accDetails;
                
                //Punchout details //VRa - Punchout changes - begin
                response.isPunchoutUser = u?.ECOM_Is_Punchout_User__c;
                //If user is a punchout user add punchout account information and Frequently bought products information
                System.debug('PunchoutAccount:: '+ u?.ECOM_Is_Punchout_User__c);
                if(u?.ECOM_Is_Punchout_User__c && String.isNotEmpty(u?.AccountId)){
                    
                    response.punchoutAccount = getPunchoutAccountModelForAccountId(String.valueOf(u?.AccountId));
                    response.frequentlyOrderedProducts = getFrequentlyBoughtProductsForUserEmail(u?.Email, u?.AccountId);
                    
                }
                //Punchout details //VRa - Punchout changes - end
                
                response.success = true;
                response.firstName = u.FirstName;
                response.lastName = u.LastName;
                response.emailId = u.Email;
                response.userId = u.Id;
                response.isMappedAccount = String.valueOf(u.Contact.ECOM_Is_Mapped__c);

                if (u.ECOM_Is_Punchout_User__c == false) {
                    response.ecomRegistrationCountry = u.Contact.ECOM_CountryProvided__c; // RWPS-4475
                }

                // Changes done by sathiya for adding approval needed flag
                Integer orderCount = ECOM_OrderService.getOrdersForApprovalCount(u?.Id, u?.Email);
                response.isApprovalNeeded = orderCount > 0;
                // Changes end
                // RWPS-2684 - START
                response.firstOrderPlaced = ECOM_OrderRepo.getUserOrderCount(u?.Id)>0?true:false;
                // RWPS-2684 - ENDS
                //RWPS-3023 ,RWPS-4147 - START
                List<Network> networks = ECOM_WebStoreRepo.getNetworks(Label.ECOM_WebStore_Name);
                Map<String,Object> recentOrderedItemsMap = ECOM_ProductService.getRecentlyPurchasedProducts(networks.get(0).Id,u?.Id);
                List<Product_Sales__c> productSales = (List<Product_Sales__c>)recentOrderedItemsMap.get('products');
                List<Id> product2IDS = new List<Id>();
                for(Product_Sales__c rec:productSales){
                    product2IDS.add(rec.Product__c);
                }
                response.recentlyOrderedItems = product2IDS;
                //RWPS-3023,RWPS-4147 - END
                String baseUrl = 'https://'+ECOM_Util.fetchBaseSiteURL(System.Label.ECOM_SiteName).Domain.Domain;
                
                if(String.isNotBlank(u.Contact.ECOM_AddressRegistration__c) && u.Contact.ECOM_AddressRegistration__c == 'Populate ST & BT'){
                    //https://revvity--ecomdev.sandbox.my.site.com/dashboard?addressStatus=addAddress
                    response.redirectURL = baseUrl +'/'+ECOM_Constant.ADD_ADDRESS;
                } else if(String.isNotBlank(u.Contact.ECOM_AddressRegistration__c) && u.Contact.ECOM_AddressRegistration__c != 'Completed'){
                    //https://revvity--ecomdev.sandbox.my.site.com/dashboard?addressStatus=selectAddress
                    response.redirectURL = baseUrl +'/'+ECOM_Constant.SELECT_ADDRESS;
                } else {
                    response.redirectURL = '';
                }
            } else{
                response.userId = accRequestList[0].userId;
                response.success = false;
                response.varMessage = 'No User with provided user ID';
            }
            
        } catch(Exception ex){
            System.debug('Exception '+ex);
            response.userId = accRequestList[0].userId;
            response.success = false;
            response.varMessage = System.Label.ECOM_105001;//'No User with provided user ID'; ex.getMessage();
            ECOM_ApplicationLogsUtil.logFailure(ex, 'Fetch Account Details', className, methodName, supportData);
        }
        accResponseList.add(getAccountDetailsResponse(response));
        return accResponseList;
    }
    
     /**
     * description : this method is used to prepare request for service layer to process
     * @param request ECOM_AccountDetailsFlowWrapper.Request
     * @return ECOM_AccountWrapper.Request
     * @author Rani Thumma | 2023-08-19
     */ 
    public static ECOM_AccountWrapper.Request getAccountDetailsRequest(ECOM_AccountDetailsFlowWrapper.Request req){
        ECOM_AccountWrapper.Request rq = new ECOM_AccountWrapper.Request();
        rq.userId = req.userId;
        return rq;
    } 
     /**
     * description : this method is used to prepare response for retrun to flow
     * @param request ECOM_AccountWrapper.Response
     * @return ECOM_AccountDetailsFlowWrapper.Response
     * @author Rani Thumma | 2023-08-19
     */
    public static ECOM_AccountDetailsFlowWrapper.Response getAccountDetailsResponse(ECOM_AccountWrapper.Response resp){
        ECOM_AccountDetailsFlowWrapper.Response rp = new ECOM_AccountDetailsFlowWrapper.Response();
        ECOM_AccountDetailsModel accModel = new ECOM_AccountDetailsModel();
        accModel.cartDetails = resp.cartDetails;
        accModel.wishlistDetails = resp.wishlistDetails;
        accModel.accountDetails = resp.accountDetails;
        accModel.success = resp.success;
        accModel.varMessage = resp.varMessage;
        accModel.firstName = resp.firstName;
        accModel.lastName = resp.lastName;
        accModel.emailId = resp.emailId;
        accModel.userId = resp.userId;
        accModel.isMappedAccount = resp.isMappedAccount;
        accModel.redirectURL = resp.redirectURL;
        accModel.punchoutAccount = resp.punchoutAccount;//VRa-Punchout changes
        accModel.frequentlyOrderedProducts = (resp.frequentlyOrderedProducts != null && !resp.frequentlyOrderedProducts.isEmpty()) ? resp.frequentlyOrderedProducts : new List<String>();//VRa-Punchout changes
        accModel.isPunchoutUser = resp.isPunchoutUser;//VRa-Punchout changes
        accModel.firstOrderPlaced = resp.firstOrderPlaced;//RWPS-2684
        accModel.recentlyOrderedItems = resp.recentlyOrderedItems;//RWPS-3023
        accModel.ecomRegistrationCountry = resp.ecomRegistrationCountry; // RWPS-4475
        System.debug('wishListModels. ==> '+resp.wishlistDetails);
        rp.accDetailsModel = accModel;
        System.debug('response ==> '+rp);
        return rp;
    } 
	
     /**
     * description : This method is used to check SAP account number
     * @param accNumber String
     * @param domain  String
     * @return Map<String,Object>
     * @author Vipul | 2023-08-19
     */
    @AuraEnabled
    public static Map<String,Object> checkAccountNumber(String accNumber,String domain){
        try {
            return ECOM_AccountService.checkAccountNumber(accNumber,domain);
        } catch (Exception e) {
            Map<String,Object> returnMap=ECOM_ContactService.createErrorMap(e);
            return returnMap;
        }
    }
    
     /**
     * @description This method returns the punchout account model for a given accountId 
     * @author vramachandran@rafter.one | 02 Jan 2024
     * @param accountId | String 
     * @returns ECOM_PunchoutAccountModel
     */
    @TestVisible
    private static ECOM_PunchoutAccountModel getPunchoutAccountModelForAccountId(String accountId){
        ECOM_PunchoutAccountModel accountModel = new ECOM_PunchoutAccountModel();
        //RWPS-5807 Start
        Punchout_Maintenance__c punchoutMaint;
        //addressModel = getAddressServiceInstance().getERPAddressModelForPunchoutAccountId(accountId);
        Map<String,Object> punchoutResponse = ECOM_PunchoutLoginService.getPunchoutAddressesForAccountId(accountId);
        if (punchoutResponse != null && punchoutResponse.containsKey(ECOM_Constant.PUNCHOUT_CONFIG_REC)) {
            punchoutMaint = (Punchout_Maintenance__c) punchoutResponse.get(ECOM_Constant.PUNCHOUT_CONFIG_REC);
        }   
        System.debug('getPunchoutAccountModelForAccountId.addressModel:: '+ JSON.serialize(punchoutMaint));
        
        if(null != punchoutMaint){
            accountModel.accountLogo = punchoutMaint.ECOM_Punchout_Customer_Logo__c;
            accountModel.accountName = punchoutMaint.ECOM_Punchout_Customer_Name__c;
            accountModel.displayListPrice = punchoutMaint.ECOM_Punchout_Show_List_Price__c;
            accountModel.productCatalogExcludeQuery = punchoutMaint.ECOM_Punchout_Products_Exclude_Query__c;
            accountModel.productCatalogIncludeQuery = punchoutMaint.ECOM_Punchout_Products_Include_Query__c;
        }
        //RWPS-5807 End
        return accountModel;
    }
    
    /**
     * @description This method returns the frequently bought products for a given user email
     * @author vramachandran@rafter.one | 02 Jan 2023
     * @param userEmail | String 
     * @param accountId | String
     * @returns List<String>
     */
    @TestVisible
    private static List<String> getFrequentlyBoughtProductsForUserEmail(String userEmail, String accountId){
        List<String> frequentlyPurchasedProductsList = new List<String>();
        
        Set<String> frequentlyPurchasedProductsSet = ECOM_FrequentlyPurchasedController.getFrequentlyBoughtProductsForUserEmail(userEmail, accountId);
		frequentlyPurchasedProductsList = (null != frequentlyPurchasedProductsSet && !frequentlyPurchasedProductsSet.isEmpty()) ? new List<String>(frequentlyPurchasedProductsSet) : new List<String>();
        
        return frequentlyPurchasedProductsList;
    }
    
    
    /**
     * @description This method checks if the erpAddressService is intantiated, else returns a new instance
     * @author vramachandran@rafter.one | 22 Dec 2023
     * @returns ERP_IAddressService
     */
    @TestVisible
    private static ERP_IAddressService getAddressServiceInstance(){
        if(null == addressService){
            Type addressServiceType = Type.forName(ECOM_Constant.ERP_ADDRESS_SERVICE);
            addressService = (ERP_IAddressService) addressServiceType.newInstance();
        } 
        
        return addressService;
    }
}