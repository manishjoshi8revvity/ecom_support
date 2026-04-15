/**************************************************************
 * 1. Ticket(s) that relates to this class
 *	 -ECOM-659
 *	 -ECOM-638
 * 2. Description - It is a wrapper class used in SUB_FLOW_4497_ECOM_Fetch_Account_Details flow to 
 * 					create apex varaible for response of fetch Account details.
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
 * - ECOM_AccountWrapper
 *
 * 6. Test Class Name: Test_Class_Name
 *
 * 7. Is @Invocable (Yes or No): No
 *
 * 8. Author Name(s): 
 * - Rani thumma 2023.08.19
 * - Manish Joshi 2025.02.28 - Added parameter first order placed - RWPS-2684
 * - Manish Joshi 2025.04.16 - Added parameter recentlyOrderedItems - RWPS-3023
 * - Chirag L 2025.09.29 - Added new attributes for dealer changes - RWPS-4475
*************************************************************/ 
public class ECOM_AccountDetailsModel {
    @auraEnabled public Boolean success;
    @auraEnabled public String varMessage;
    @auraEnabled public String firstName;
    @auraEnabled public String lastName;
    @auraEnabled public String emailId;
    @auraEnabled public String userId;
    @auraEnabled public String isMappedAccount;
    @auraEnabled public String redirectURL;
    @auraEnabled public List<ECOM_AccountWrapper.AccountDetails> accountDetails;
    @auraEnabled public ECOM_CartModel cartDetails;
    @auraEnabled public List<ECOM_AccountWrapper.WishlistDetails> wishlistDetails;
    @auraEnabled public ECOM_PunchoutAccountModel punchoutAccount;//VRa-Punchout changes
    @auraEnabled public List<String> frequentlyOrderedProducts ;//VRa-Punchout changes
    @auraEnabled public Boolean isPunchoutUser;//VRa-Punchout changes
    @auraEnabled public Boolean firstOrderPlaced;//RWPS-2684
    @auraEnabled public List<String> recentlyOrderedItems;//RWPS-3023
    @auraEnabled public String ecomRegistrationCountry; // RWPS-4475
}