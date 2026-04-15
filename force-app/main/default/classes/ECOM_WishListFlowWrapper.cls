/**************************************************************
 * 1. Ticket(s) that relates to this class
 * - ECOM-
 * 
 * 2. Description - It is a wrapper class used to store request and response wrapper object for wishlist api.
 *					
 *
 * 3. Objects referenced
 * - WishList
 *
 * 4. Callouts to additional Components (including their methods) or None:
 * - None
 *
 * 5. Dependant Class(es):
 * - ECOM_WishListFlowController
 *
 * 6. Test Class Name: Test_Class_Name
 *
 * 7. Is @Invocable (Yes or No): No
 *
 * 8. Author Name(s): 
 * - Rani Thumma 2023.09.09
 *
*************************************************************/ 
public class ECOM_WishListFlowWrapper {
    
     //this class is to accept wishlist API request
    public class Request{
        @InvocableVariable
        public String userId;
        @InvocableVariable
        public String action;
        @InvocableVariable
    	public String productId;
        @InvocableVariable
        public String wishlistId;
    }
    
     //this class is to accept wishlist API reponse
    public class Response{
        @InvocableVariable
        public String success;
        @InvocableVariable
        public String wishlist_id;
        @InvocableVariable
    	public String message;
        @InvocableVariable
        public ECOM_WishListFlowResponseWrapper wishlistReponse;
    }

}