/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-2555
*
* 2. Description - This class contains util methods to send out emails
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
*    - ECOM_CustomEmailUtil_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vasudev 2024.07.23
*************************************************************/
public without sharing class ECOM_CustomEmailUtils {

    public static Boolean sendEmailWithTemplate(String contactEmail, String emailTemplateName, String orgWideEmailId){
        Boolean isSuccess = true;
        
        try{
            OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address =: orgWideEmailId LIMIT 1];
            
            //String emailTemplateName = System.Label.ECOM_NewRegistrationEmailTemplateName;
            List<EmailTemplate> et = [SELECT Id, Subject FROM EmailTemplate WHERE DeveloperName =:emailTemplateName LIMIT 1];
            
            System.debug('Et:: '+ et);
            List<Contact> contactList = [SELECT Id, Email, Name FROM Contact WHERE EMail =: contactEmail  LIMIT 1 ];
            System.debug('contactList:: '+ JSON.serialize(contactList));
            if((et != null && !et.isEmpty() && contactList != null && !contactList.isEmpty()) || Test.isRunningtest()){
                System.debug('Template:: ' + JSON.serialize(et));
                
                Messaging.SingleEmailMessage resetPasswordEmail = new Messaging.SingleEmailMessage();
                resetPasswordEmail.setTargetObjectId(contactList[0].Id);
                if(!Test.isRunningTest())resetPasswordEmail.setTemplateID(et[0].Id);
                resetPasswordEmail.toAddresses = new String[] { contactList[0].email};
                resetPasswordEmail.setSaveAsActivity(false);
                resetPasswordEmail.setUseSignature(false);
                if(!Test.isRunningTest()) resetPasswordEmail.setOrgWideEmailAddressId(owea.get(0).Id);
                
                List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
                allmsg.add(resetPasswordEmail);
                
                Messaging.sendEmail(allmsg,false);
            }
            
        }catch(Exception e){
            isSuccess = false;
            ECOM_ApplicationLogsUtil.logFailure(e, 'PasswordRestEmailUtil', 'ECOM_CustomEmailUtil', 'sendEmailWithTemplate', 'Contact::Email' + contactEmail + ', emailTemplateName:: ' +  emailTemplateName + ', orgWideEmailId:: ' + orgWideEmailId + ', exception:: ' + e);
        }
        return isSuccess;
    }
}