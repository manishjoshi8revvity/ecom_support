/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*
* 2. Description - An apex page controller test class for code coverage
*
* 3. Objects referenced
*    - 
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
*
* 5. Dependant Class(es):
*
* 6. Test Class Name:
*
* 7. Is @Invocable (Yes or No): NoO
*
* 8. Author Name(s):
*    - RafterOne
*    - Manish Joshi 2025.05.28 updated method testCommunitiesLoginController for assert check RWPS-3323
*************************************************************/
@IsTest 
global with sharing class CommunitiesLoginControllerTest {
    @TestSetup
    public static void testData(){
        ECOM_TestUtil.initialStorefrontSetup();
    }

    @isTest
    global static void testCommunitiesLoginController () {
     	CommunitiesLoginController controller = new CommunitiesLoginController();
     	System.assertEquals(new PageReference('https://www.secure.stage.revvity.com/login?ptcms=true'), controller.forwardToAuthPage());//RWPS-3323       
    }    
}