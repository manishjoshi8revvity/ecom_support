/**************************************************************

* 1. Jira Ticket(s) that relates to this class
* ECOM-756
*  
*
* 2. Description - This class is a test class for sending emails.
*
* 3. Objects referenced
*    - Email Message
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_TestUtil
*    - ECOM_EmailUtil
*
* 6. Test Class Name:
*    -None
*
* 7. Is @Invocable : No
*
* 8. Author Name(s):
*    - Manoj 2023.09.19

*************************************************************/
@isTest
public with sharing class ECOM_EmailUtil_Test {
    @TestSetup
    static void setup(){
        Map<string,Object> response = ECOM_TestUtil.initialStorefrontSetup();
    }
	@isTest
    static void sendEmailsTestCase1(){
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        ECOM_EmailUtil.EmailFlowInputs input = new ECOM_EmailUtil.EmailFlowInputs();
        input.varFromAddress = 'test@email.com';
        input.varRelatedId = con.Id;
        List<String> multipleEmails = new List<String>();
        multipleEmails.add('test1@email.com');
        input.multiToAddress=multipleEmails;
        input.varSubject='test';
        input.varBody='test';
        List<ECOM_EmailUtil.EmailFlowInputs> testInputs = new List<ECOM_EmailUtil.EmailFlowInputs>();
        testInputs.add(input);
        test.startTest();
        ECOM_EmailUtil.sendEmails(testInputs);
        test.stopTest();
    }
    
    @isTest
    static void sendEmailsTestCase2(){
        EmailTemplate temp = new EmailTemplate (developerName = 'test', FolderId = userInfo.getUserId(), TemplateType= 'Text', Name = 'test');
        insert temp;
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        ECOM_EmailUtil.EmailFlowInputs input = new ECOM_EmailUtil.EmailFlowInputs();
        input.varFromAddress = 'test@email.com';
        input.varRelatedId = con.Id;
        List<String> multipleEmails = new List<String>();
        multipleEmails.add('test1@email.com');
        input.multiToAddress=multipleEmails;
        input.varTemplateId = temp.Id;
        List<ECOM_EmailUtil.EmailFlowInputs> testInputs = new List<ECOM_EmailUtil.EmailFlowInputs>();
        testInputs.add(input);
        test.startTest();
        ECOM_EmailUtil.sendEmails(testInputs);
        test.stopTest();
    }
}