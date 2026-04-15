/**************************************************************
 * 1. Ticket(s) that relates to this class
 *	 -ECOM-659
 *	 -ECOM-638
 * 2. Description - 
 * 		- It is a wrapper class used to store request
 * 		- response wrapper object for fetch Account details.
 *					
 *
 * 3. Objects referenced
 * - Account
 * - WebCart
 * - WishList
 *
 * 4. Callouts to additional Components (including their methods) or None:
 * - None
 *
 * 5. Dependant Class(es):
 * - ECOM_AccountDetailsController
 * -ECOM_AccountWrapper
 *
 * 6. Test Class Name: Test_Class_Name
 *
 * 7. Is @Invocable (Yes or No): No
 *
 * 8. Author Name(s): 
 * - Rani thumma 2023.08.19
 *
*************************************************************/ 
public class ECOM_AccountDetailsFlowWrapper {
    
     //this class is to accept fetchAccount details request
    public class Request{
        @InvocableVariable
        public String userId;
    }
    
	//this class is to send fetchAccount details response
    public class Response{
        @InvocableVariable
        public Boolean success;
        @InvocableVariable
        public String varMessage;
        @InvocableVariable
        public List<ECOM_AccountWrapper.AccountDetails> accountDetails;
        @InvocableVariable
        public ECOM_CartModel cartDetails;
        @InvocableVariable
        public List<ECOM_AccountWrapper.WishlistDetails> wishlistDetails;
        @InvocableVariable
        public ECOM_AccountDetailsModel accDetailsModel;
        
    }

}