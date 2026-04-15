/**************************************************************

* 1. Jira Ticket(s) that relates to this class

*  

*

* 2. Description - This class is a test class.

*

* 3. Objects referenced

*    - Account

*    - Contact

*.   -User

* 4. Callouts to additional Components (including their methods) or None:

*    - None

*

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

*    - Manoj 2023.09.19

*************************************************************/

@isTest(SeeAllData=false)
public class ECOM_UserFlowController_Test {
    @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
    }
    
    @isTest
    static void testCreateAlias() {
        Account testAccount = [SELECT Id, Name FROM Account  ORDER BY CREATEDDATE DESC  LIMIT 1];
        Contact testContact = [SELECT Id, LastName FROM Contact  ORDER BY CREATEDDATE DESC  LIMIT 1];
        User u = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        // Create test data for the input wrapper
        ECOM_UserFlowServiceWrapper.DataWrapper inputWrapper = new ECOM_UserFlowServiceWrapper.DataWrapper();
        inputWrapper.lastName = testContact.LastName;
        
        
        List<ECOM_UserFlowServiceWrapper.DataWrapper> inputData = new List<ECOM_UserFlowServiceWrapper.DataWrapper>{inputWrapper};
            
            Test.startTest();
        List<ECOM_UserFlowServiceWrapper.ResultWrapper> result;
        System.runAs(u){
            result = ECOM_UserFlowController.createAlias(inputData);
        }
        Test.stopTest();
        
        
        System.assertNotEquals(null, result);           
        System.assertEquals(1, result.size());   
        
        // Check the values in the result wrapper
        ECOM_UserFlowServiceWrapper.ResultWrapper resultWrapper = result[0];
        System.assertNotEquals(null, resultWrapper.alias);
        System.assertNotEquals(null, resultWrapper.communityNickname);
        
        
    }
}