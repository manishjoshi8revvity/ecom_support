/**************************************************************
 * 1. Ticket(s) that relates to this class
 * - ECOM-
 * 
 * 2. Description - It is a controller class used in wishlist api flow.
 *					
 *
 * 3. Objects referenced
 * - WishList
 *
 * 4. Callouts to additional Components (including their methods) or None:
 * - None
 *
 * 5. Dependant Class(es):
 * - ECOM_WishListFlowWrapper
 *
 * 6. Test Class Name: Test_Class_Name
 *
 * 7. Is @Invocable (Yes or No): Yes
 *
 * 8. Author Name(s): 
 * - Rani Thumma 2023.09.09
 *
*************************************************************/ 
public class ECOM_WishListFlowController {
    
    /**
     * this method is used to get the request from flow 'SUB.FLOW_4450: ECOM - WishList Operrations Flow' and sends it to service class for further processing.
     * @param request List<ECOM_WishListFlowWrapper.Request>
     * @return List<ECOM_WishListFlowWrapper.Response>
     * @author Rani Thumma | 2023-09-09
     */
    @InvocableMethod(Label='Manage WishList' Category='Wishlist API' Description='This is to manipulate wishlist records')
    public static List<ECOM_WishListFlowWrapper.Response> fetchAccountDetailsByUserId(List<ECOM_WishListFlowWrapper.Request> wishListRequests) {
        List<ECOM_WishListFlowWrapper.Response> wishListResponses = new List<ECOM_WishListFlowWrapper.Response>();
        User user;
        System.debug('wishListRequests === '+wishListRequests);
        // if user id is passed in reqest then create wish list for the user 
        if(String.isNotBlank(wishListRequests[0].userId)){
            ECOM_UserService userServiceInstance = new ECOM_UserService();
            user = userServiceInstance.getUserByUser(wishListRequests[0].userId);
        }
        Type accountservice = Type.forName(ECOM_Constant.ACCOUNT_SERVICE);
		ECOM_IAccountService accServiceInstance = (ECOM_IAccountService)accountservice.newInstance();
        ECOM_WishListFlowResponseWrapper res = new ECOM_WishListFlowResponseWrapper();
        res = accServiceInstance.wishListOperations(wishListRequests[0] , user);
        wishListResponses.add(getWishListResponse(res));
        
        return wishListResponses;
    }
    
    /**
     * description : this method is used to prepare response for retrun to flow
     * @param request ECOM_WishListFlowResponseWrapper
     * @return ECOM_WishListFlowWrapper.Response
     * @author Rani Thumma | 2023-09-09
     */
    public static ECOM_WishListFlowWrapper.Response getWishListResponse(ECOM_WishListFlowResponseWrapper resp){
        ECOM_WishListFlowWrapper.Response rp = new ECOM_WishListFlowWrapper.Response();
        rp.wishlistReponse = resp;
        return rp;
    } 


}