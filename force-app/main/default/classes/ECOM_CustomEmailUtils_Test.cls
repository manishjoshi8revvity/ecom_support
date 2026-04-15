/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-2555
*
* 2. Description - Test Class for ECOM_EmailUtil
*
* 3. Objects referenced
*    - Messaging
*	 - Contact
*	 - EmailTemplate
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
*
* 5. Dependant Class(es):
*    -
*
* 6. Test Class Name:         
*    - 
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vasudev 2024.07.23
*************************************************************/
@isTest
public class ECOM_CustomEmailUtils_Test {

     @TestSetup
    static void setup(){
        ECOM_TestUtil.initialStorefrontSetup();
    }
    
    @isTest
    static void sendEmailWithTemplateTest(){
        List<user> userRecord = [SELECT Id, ContactId, Contact.Email FROM User WHERE Contactid != null ORDER BY CreatedDate DESC LIMIT 1];
        System.debug('Contact:: '+ JSON.serialize(userRecord));
        test.startTest();
        
        ECOM_CustomEmailUtils.sendEmailWithTemplate(userRecord[0].Contact.Email, System.Label.ECOM_IntegrationUserNamedCredential, System.Label.ECOM_OrgWideEmail);
        test.stopTest();
    }
}