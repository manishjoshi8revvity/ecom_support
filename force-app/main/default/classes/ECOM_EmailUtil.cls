/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-756
*
* 2. Description - This class is used to send out emails.
* - class is used only when Flow email action is not an option
* - Flow eamil action limits to 5 emails in to address, then class is used to send out emails
*
* 3. Objects referenced
*    - Messaging
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
*
* 5. Dependant Class(es):
*    -
*
* 6. Test Class Name:         
*    - ECOM_EmailUtil_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Rani 2023.08.11
*************************************************************/
public with sharing class ECOM_EmailUtil {
    
    @InvocableMethod(Label='Send Emails custom apex action' Category='Emails' Description='This is to send emails to reciepients above 5')
    public static void sendEmails(List<EmailFlowInputs> requests){
        String supportData = '';
        try{
            supportData = JSON.serialize(requests);
            if(requests != null && !requests.isEmpty())
            { 
                //Creating SingleEmailMessage instance to send email
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage(); 
                List<OrgWideEmailAddress> orgwideaddreslist= [select Id,Address from OrgWideEmailAddress where Address=:requests[0].varFromAddress AND IsVerified = true limit 1];
                if(orgwideaddreslist != null && !orgwideaddreslist.isEmpty())
                {
                    message.setOrgWideEmailAddressId(orgwideaddreslist[0].Id); //sender email address
                }
                //relatedToType
                message.setTargetObjectId(requests[0].varRelatedId !=null ? requests[0].varRelatedId :null);
                //recipientType
                message.setWhatId(requests[0].varWhatId !=null ? requests[0].varWhatId : null);
                //to address
                message.setToAddresses(requests[0].multiToAddress !=null ? requests[0].multiToAddress : New List<string>()); 
                message.setCcAddresses(requests[0].multiCcAddress !=null ? requests[0].multiCcAddress : New List<string>());
                System.debug(requests[0].varTemplateId);
               
                if(requests[0].varTemplateId != null)
                {
                    EmailTemplate templateDetails = [ SELECT Id,Subject,Description,HtmlValue,DeveloperName,Body FROM EmailTemplate WHERE Id = :requests[0].varTemplateId]; 
                    message.setTemplateID(requests[0].varTemplateId);
                } 
                else 
                {
                    message.subject = requests[0].varSubject !=null ? requests[0].varSubject : ' ';
                    message.setHtmlBody(requests[0].varBody !=null ? requests[0].varBody : ' ');
                }
                
                message.setSaveAsActivity(requests[0].varLogEmailOnSend);
                //message.setTreatTargetObjectAsRecipient(treatAsRecipient);
    
                Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
                System.debug('message == '+message);
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                if (results[0].success) {
                    System.debug('The email was sent successfully.' + results);
                } else {
                    System.debug('The email failed to send: '+ results[0].errors[0].message);
                }
                
            }
        } catch(Exception ex){
            system.debug('message:: ' + ex.getMessage());
            system.debug('String:: ' + ex.getStackTraceString());
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.ORDER_MODULE_NAME, 'ECOM_EmailUtil', 'sendEmails', supportData);
        }

    }
    
    Public class EmailFlowInputs {
        @InvocableVariable public String varFromAddress;//sender email
        @InvocableVariable public List<String> multiToAddress;
        @InvocableVariable public List<String> multiCcAddress;
        @InvocableVariable public String varSubject;
        @InvocableVariable public String varBody; 
        @InvocableVariable public String varTemplateId; 
        @InvocableVariable public String varWhatId; 
        @InvocableVariable public String varRelatedId;//Lead or User or Contact
        @InvocableVariable public Boolean varLogEmailOnSend; // save under activity 
        @InvocableVariable public Boolean treatAsRecipient;// receive 
    } 
}