/**************************************************************

* 1. Jira Ticket(s) that relates to this class
*  
*
* 2. Description - This is a test class
*
* 3. Objects referenced
*    - User
*	 - Account
*	 - Contact

* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_TestUtil
*    - classes called from test class
 
* 6. Test Class Name:
*
* 7. Is @Invocable : No
*
* 8. Author Name(s):
*    - Manojkumar 2023.09.01
*************************************************************/
@isTest(SeeAllData=false)
public class ECOM_UserFlowServiceWrapper_Test {
    @TestSetup
    public static void testData(){
        ECOM_TestUtil.testDataIntialSetup();
    }
    
    @isTest
    static void testUserFlowServiceWrapper() {
        // Create an instance of the DataWrapper class
        ECOM_UserFlowServiceWrapper.DataWrapper input = new ECOM_UserFlowServiceWrapper.DataWrapper();
        input.lastName = 'Doe';
        
        // Call the flow and pass the input
        ECOM_UserFlowServiceWrapper.ResultWrapper result = new ECOM_UserFlowServiceWrapper.ResultWrapper();
        result.alias = 'JohnD';
        result.communityNickname = 'JD';
        
        // Assert the output values
        System.assertEquals('JohnD', result.alias);
        System.assertEquals('JD', result.communityNickname);
    }
}