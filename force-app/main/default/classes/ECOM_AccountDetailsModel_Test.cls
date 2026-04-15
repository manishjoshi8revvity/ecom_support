/**************************************************************

* 1. Jira Ticket(s) that relates to this class
*  RWPS-2684
* 2. Description 
*    - This class is a test class.
*	 - Test class for ECOM_AccountDetailsModel.
*	 - Number of Methods : 1 setup.
*
* 3. Objects referenced
* 
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_AccountWrapper
*    - ECOM_PunchoutAccountModel
*
* 6. Test Class Name:
*    -None
*
* 7. Is @Invocable : No
*
* 8. Author Name(s):
*    - Manish Joshi 2025.03.03

*************************************************************/

@isTest 
public class ECOM_AccountDetailsModel_Test {
    @TestSetup
    public static void testData(){
        ECOM_TestUtil.testDataIntialSetup();
    }

	/*@isTest
    public static void test(){
        Test.startTest();
        ECOM_AccountDetailsModel obj = new ECOM_AccountDetailsModel();
        obj.success = true;
        obj.varMessage = 'test';
        obj.firstName = 'test';
        obj.lastName = 'test';
        obj.emailId = 'test@yopmail.com';
        obj.userId = 'test123';
        obj.redirectURL = '';
        obj.isMappedAccount = '';
        obj.accountDetails = new List<ECOM_AccountWrapper.AccountDetails>();
        obj.cartDetails = new ECOM_CartModel();
        obj.wishlistDetails = new List<ECOM_AccountWrapper.WishlistDetails>();
        obj.punchoutAccount = new ECOM_PunchoutAccountModel();
        obj.frequentlyOrderedProducts = new List<String>(); 
        obj.isPunchoutUser = true;
        obj.firstOrderPlaced = true;
        
        Test.stopTest();
    }*/
    
    @isTest
    public static void testSetUserPassword(){
        User u = [SELECT Id, Username, Email FROM User WHERE Lastname = 'TestPortal'];
        //To set  the user as a portal user
        Test.startTest();
        //Creating input map
        Map<String, Object> inputs = new Map<String, Object>();
        inputs.put('varUserId',u.Id);
        Flow.Interview flw = new Flow.Interview.SUB_FLOW_4497_ECOM_Fetch_Account_Details(inputs);
        Test.stopTest();
    }
}