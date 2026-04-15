/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM - 566
*
* 2. Description - This class is used for Cart specific operations.
* 		such as add to cart, fetch cart, update cart etc..
*
* 3. Objects referenced
*    - Cart
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
* 5. Dependant Class(es):
*    - SUB_FLOW_4496_ECOM_Cart_Operations flow
*    - ECOM_CartOperationsFlowController
*
* 6. Test Class Name: 
*
* 7. Is @Invocable (Yes or No): Yes
*
* 8. Author Name(s):
*    - Manish kumar 2023.08.02
*    - Manoj Kumar 2023.09.21
* 	 - Vasudev R   2023.12.08
*************************************************************/
public with sharing class ECOM_CartFlowWrapper {
    @InvocableVariable public String accountId;	
	@InvocableVariable public String cartId;	
	@InvocableVariable public String currencyIsoCode;
	@InvocableVariable public String webstoreId;	
    @InvocableVariable public String operationType;
    @InvocableVariable public List<ECOM_CartItemModel> cartItems;
    @InvocableVariable public ECOM_CartModel cartModel;
    @InvocableVariable public String userId;
    @invocableVariable public String responseJsonString;//VRa Punchout Changes
    @invocableVariable public String accountName;//VRa Punchout Changes
    @invocableVariable public String accountNumber;//VRa Punchout Changes
    @invocableVariable public String userName;//VRa Punchout Changes
    @invocableVariable public Boolean isPunchoutUser;//VRa Punchout Changes
}