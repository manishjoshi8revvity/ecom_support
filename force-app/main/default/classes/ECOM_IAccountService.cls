/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    -ECOM-659
*	 -ECOM-638
*
* 2. Description - This class is used for Account specific transactions.
*
* 3. Objects referenced
*    -Account
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
* 5. Dependant Class(es):
*    - ECOM_AccountService
*
* 6. Test Class Name: ECOM_AccountService_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Rani Thumma 2023.08.18
* 	 - vramachandran@rafter.one | 22 Dec 2023
*************************************************************/
public interface ECOM_IAccountService {

	//ECOM_AccountWrapper.Response fetchAccountDetails(ECOM_AccountWrapper.Request request); 
    List<WishList> fetchWishList(String ownerId);
    ECOM_WishListFlowResponseWrapper wishListOperations(ECOM_WishListFlowWrapper.Request request , User user);
    List<Account> getPunchoutAccountRecordForId(String accountId);//VRa - punchout changes
    

}