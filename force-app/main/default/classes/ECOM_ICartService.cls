/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    - ECOM-493
*    - ECOM-96
*
* 2. Description - This class is used for Cart specific transactions.
*
* 3. Objects referenced
*    -WebCart
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
* 5. Dependant Class(es):
*    - ECOM_CartService
*
* 6. Test Class Name: ECOM_CartService_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Manoj 2023.08.02
* 	 - vramachandran@rafter.one | 22 Dec 2023
*************************************************************/
public interface ECOM_ICartService {
    
	Map<String,Object> repriceCart(String cartId, String couponCode);
    //Map<String,Object> repriceCart(String cartId);
    List<ECOM_CartModel> addItemsToCart(List<ECOM_CartModel> carts);
    List<ECOM_CartModel> fetchCart(List<ECOM_CartModel> carts);
    List<ECOM_CartModel> updateCartItems(List<ECOM_CartModel> carts);
    List<ECOM_CartModel> deleteCart(List<ECOM_CartModel> carts);
    List<ECOM_CartModel> getCartItems(List<ECOM_CartModel> carts);
    List<CartDeliveryGroupMethod> getCartDeliveryGroupMethodById(Id cartGroupMethodID);
    List<CartDeliveryGroup> getCartDeliveryGroupById(Id cartGroupID);
    List<CartDeliveryGroup> updateCartDeliveryGroups(List<CartDeliveryGroup> cartDeliveryGroupsToUpdate);
    List<WebCart> getPrimaryCartBasedOnOwner(String userId);
    void updateCart(List<Webcart> cartsToUpdate);
    void updatePunchoutCart(String userId);//VRa - punchout changes
    WebCart getActiveCartForPunchoutUser(String userId);//VRa - punchout changes
    WebCart getWebCartForPunchoutUser(User userRecord);//VRa - punchout changes
    ECOM_POOMModel getPunchoutCartandCartItemsById(String cartId, String effectiveAccountId);//VRa - punchout changes
    Map<String,Object> updatePunchoutCart(String userId, String posrJson);//VRa - punchout changes
}