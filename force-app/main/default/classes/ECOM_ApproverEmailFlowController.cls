/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-102    
*
* 2. Description - This class is used to split user entered emails and comapre with community users for S.FLOW_1903: ERP Address - Set Cart Approvers.
*
* 3. Objects referenced
*    -User
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None  
*
* 5. Dependant Class(es):
*    - None
*	
* 6. Test Class Name:         
*    - ECOM_ApproverEmailFlowController_Test
*
* 7. Is @Invocable (Yes or No): Yes
*
* 8. Author Name(s):
*    - Gaurang 2024.05.23

*************************************************************/
global class ECOM_ApproverEmailFlowController {
    /**
    * @description Invocable method to create the alias and community nickname for the registering user.
    * @author Gaurang Arora | 2024.05.23
    * @param requests 
    * @return List<Result>
    **/
    @InvocableMethod(label='Check emails' category='Util' description='This method is used to check emails against community users in org')
    global static List<Result> checkEmails(List<Request> requests){
        List<Result> results = new List<Result>();
        try{
            for(Request request : requests){
                Result result = new Result();
                result.limitExceeded = false;
                List<String> invalid = new List<String>();
                List<String> emails = request.emails.split(';');
                if(emails.size() > Integer.valueOf(System.Label.ECOM_MaxEmailsApproverFlow)){
                    result.limitExceeded = true;
                }
                else{
                    List<String> fetchedEmails = ECOM_UserService.checkCommunityUsers(emails);
                    for(String email : emails){
                        if(!fetchedEmails.contains(email)){
                            invalid.add(email);
                        }
                    }
                }
                result.invalidEmails = !invalid.isEmpty() ? String.join(invalid,'\n') : '';
                results.add(result);
            }
        }
        catch(Exception e){
            ECOM_ApplicationLogsUtil.logFailure(e , 'ECOM_ApproverEmailFlowController :: checkEmails' , 'ECOM_ApproverEmailFlowController' , 'checkEmails',' Stack:: '+ e.getStackTraceString() + ' Error:: '+e.getMessage());
        }
        return results;
    }

    global class Request {
        @InvocableVariable(description='Semi-colon seperated emails' required=true)
        global String emails;
    }
    
    global class Result {
        @InvocableVariable(description='Consists of invalid emails')
        global String invalidEmails;
        @InvocableVariable(description='Marked as true if emails are more than the limit specified')
        global Boolean limitExceeded;
    }

}