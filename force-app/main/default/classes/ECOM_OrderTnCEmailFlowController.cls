/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-3322
*
* 2. Description - This class is used for Order specific transactions.
*
* 3. Objects referenced
*    - Order
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
* 5. Dependant Class(es):
*    - ECOM_OrderRepo
*    - ECOM_CustomMetadataService
*
* 6. Test Class Name: 
*    - ECOM_OrderTnCEmailFlowController_Test
*
* 7. Is @Invocable (Yes or No): Yes
*
* 8. Author Name(s):
*    - Gaurang 2024.07.01
*************************************************************/
public with sharing class ECOM_OrderTnCEmailFlowController {
    @InvocableMethod(Label='Send TnC Emails' Category='Emails' Description='This is to send emails to internal users for TnC')
    public static void sendEmails(List<EmailFlowInputs> requests){
        String supportData = '';
        try{
            supportData = JSON.serialize(requests);
            if(requests != null && !requests.isEmpty()){
                if(requests[0]?.EmailAddresses == null){
                    ECOM_ApplicationLogsUtil.logApplicationDataWithCustomException(ECOM_Constant.ORDER_MODULE_NAME, 'ECOM_OrderTnCEmailFlowController', 'sendEmails', supportData, '', 'Email for the product terms and conditions are missing');
                } else {
                    if(!requests[0].EmailAddresses.isEmpty()){
                        List<String> finalEmails = new List<String>();
                        String targetObjectId = '';
                        for(String emails: requests[0].EmailAddresses){
                            List<String> tempEmails = emails.split(',');
                            finalEmails.addAll(tempEmails);
                        }
                        
                        for(User user : ECOM_UserService.checkInternalUsers(finalEmails)){
                            targetObjectId = user.Id;
                            Integer emailIndex = finalEmails.indexOf(user.Email);
                            if(emailIndex>-1){
                                finalEmails.remove(emailIndex);
                            }
                            break;
                        }
                        
                        if(String.isNotBlank(targetObjectId)){
                            List<Order> orders = ECOM_OrderRepo.getOrderDetails(requests[0].varWhatId);
                            Map<String,String> countryMapping = ECOM_CustomMetadataService.getCountryToOrgWideEmailMapping();
                            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage(); 
                            if(String.isNotBlank(orders[0].Default_Ship_to_ERP_Address__r.ApiCountry__c) && countryMapping.containsKey(orders[0].Default_Ship_to_ERP_Address__r.ApiCountry__c))
                            {
                                message.setOrgWideEmailAddressId(countryMapping.get(orders[0].Default_Ship_to_ERP_Address__r.ApiCountry__c));
                            }
                            else if(String.isNotBlank(orders[0].Default_Ship_to_ERP_Address__r.fxAddress_CountryName__c) && countryMapping.containsKey(orders[0].Default_Ship_to_ERP_Address__r.fxAddress_CountryName__c))
                            {
                                message.setOrgWideEmailAddressId(countryMapping.get(orders[0].Default_Ship_to_ERP_Address__r.fxAddress_CountryName__c));
                            }
                            message.setTargetObjectId(targetObjectId);
                            message.setWhatId(requests[0].varWhatId !=null ? requests[0].varWhatId : null);
                            message.setToAddresses(finalEmails.isEmpty() ?  New List<string>() : finalEmails);
                            message.setTemplateID(requests[0].varTemplateId);
                            message.setSaveAsActivity(requests[0].varLogEmailOnSend);
                            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
                                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                        }
                    }
                }	
            }
        }
        catch(Exception ex){
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.ORDER_MODULE_NAME, 'ECOM_OrderTnCEmailFlowController', 'sendEmails', supportData);
        }
    }

    Public class EmailFlowInputs {
        @InvocableVariable public String varTemplateId; 
        @InvocableVariable public String varWhatId; 
        @InvocableVariable public Boolean varLogEmailOnSend; // save under activity 
        @InvocableVariable public List<String> EmailAddresses;// receive 
    }
}