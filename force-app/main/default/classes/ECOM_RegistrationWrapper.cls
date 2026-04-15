/**************************************************************
* 1. Jira Ticket(s) that relates to this class 
*    - ECOM-2302
*
* 2. Description - This class is a wrapper class for registration requests and response  
*
*
* 3. Objects referenced
*    -
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - None
*
* 6. Test Class Name: 
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vasudev R 2024-05-08 : Initial creation
*************************************************************/
public class ECOM_RegistrationWrapper {
    
    public class RegistrationRequest {
        
    }
    
    public class RegistrationResponse {
		
        @auraEnabled public String actionName;
        @auraEnabled public String errors;//TODO: may need to get updated 
        @auraEnabled public OutputValue outputValues;
        @auraEnabled public Boolean isSuccess; 
        @auraEnabled public Integer version;
    }
    
    public class OutputValue {
        
        @auraEnabled public String varResponseMessage;
        //@auraEnabled public String Flow__InterviewGuid;
        @auraEnabled public Boolean varUserRegistered;
        @auraEnabled public Boolean varIsMapped;
        @auraEnabled public Boolean resultSuccess;
    }

    public class UserEmailWrapper {
        @auraEnabled public String userEmail;
        @auraEnabled public String emailTemplate;
    }
    
    public class PasswordRequestWrapper {
        @auraEnabled public String encryptedUserEmail;
        @auraEnabled public String encryptedPassword;
        @auraEnabled public String encryptedToken;
    }
    
    public class ValidationResult {
        @auraEnabled public Boolean success{get;set;}
        @auraEnabled public String message {get;set;}
    }
    
}