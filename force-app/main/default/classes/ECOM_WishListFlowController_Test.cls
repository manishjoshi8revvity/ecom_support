/**************************************************************

* 1. Jira Ticket(s) that relates to this class

*  

*

* 2. Description - This class is a test class.

*

* 3. Objects referenced


*.   -User

* 4. Callouts to additional Components (including their methods) or None:

*    - None


* 5. Dependant Class(es):

*    - ECOM_TestUtil

*    - classes called from test class

*

* 6. Test Class Name:

*    -None

*

* 7. Is @Invocable : No

*

* 8. Author Name(s):

*    - Manoj 2023.11.09
*************************************************************/
@isTest
public class ECOM_WishListFlowController_Test {
    @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
    }
    
    @isTest
    static void testFetchAccountDetailsByUserId(){
        User testUser = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        
        ECOM_WishListFlowWrapper.Request request = new ECOM_WishListFlowWrapper.Request();
        request.userId = testUser.Id; 
        
        Test.startTest();
        List<ECOM_WishListFlowWrapper.Response> responses = ECOM_WishListFlowController.fetchAccountDetailsByUserId(new List<ECOM_WishListFlowWrapper.Request>{request});
        Test.stopTest();
        
        System.assertnotEquals(null,responses,'expected order should not be null');
        
    }
}