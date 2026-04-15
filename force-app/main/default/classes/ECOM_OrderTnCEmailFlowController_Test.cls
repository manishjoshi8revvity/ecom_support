/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-3322    
*
* 2. Description - This class is a test class for ECOM_OrderTnCEmailFlowController
*
*
* 3. Objects referenced
*   - Order
*	- User
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
*
* 5. Dependant Class(es):
*    - ECOM_OrderTnCEmailFlowController_Test
*   
* 6. Test Class Name: ECOM_OrderTnCEmailFlowController_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Gaurang 2024.07.01
*************************************************************/
@isTest
public class ECOM_OrderTnCEmailFlowController_Test {
    @TestSetup
    static void setup(){
    	Map<String,Object> respponse = ECOM_TestUtil.initialStorefrontSetup();
    }
	@isTest
    static void sendEmailsTest(){
        List<ECOM_OrderTnCEmailFlowController.EmailFlowInputs> requests = new List<ECOM_OrderTnCEmailFlowController.EmailFlowInputs>();
        ECOM_OrderTnCEmailFlowController.EmailFlowInputs input = new ECOM_OrderTnCEmailFlowController.EmailFlowInputs();
        User u =[SELECT Id,Email FROM User ORDER BY CreatedDate DESC LIMIT 1];
        Order ord = [SELECT Id FROM Order ORDER BY CreatedDate DESC LIMIT 1];
        List<String> emails = new List<String>();
        emails.add(u.Email);
        input.EmailAddresses = emails;
        input.varLogEmailOnSend = false;
        input.varWhatId=ord.Id;
        input.varTemplateId = 'test';
        requests.add(input);
        Test.startTest();
        ECOM_OrderTnCEmailFlowController.sendEmails(requests);
        Test.stopTest();
    }
}