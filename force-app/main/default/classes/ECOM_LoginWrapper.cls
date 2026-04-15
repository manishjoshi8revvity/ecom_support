/**************************************************************
 * 1. Jira Ticket(s) that relates to this class
 *    ECOM-69
 * 
 * 2. Description - This class acts as a wrapper for login data.
 * 
 * 3. Objects referenced
 *    - User
 * 
 * 4. Callouts to additional Components (including their methods) or None:
 *    - None
 * 
 * 5. Dependant Class(es):
 *    - ECOM_EncryptFlowService
 *    - ECOM_LoginController
 *    - ECOM_EncryptUtil
 *    - ECOM_LoginUtil
 * 
 * 6. Test Class Name: ECOM_LoginController_Test
 * 
 * 7. Is @Invocable (Yes or No): Yes
 * 
 * 8. Author Name(s):
 *    - Vipul 2023.07.19
 *************************************************************/
global class ECOM_LoginWrapper {

    //class to wrap data received from Flow input.
    global class EncryptionRequest {
        @InvocableVariable
        global String username;
        @InvocableVariable
        global String password;
        @InvocableVariable
        global Boolean isPunchOutUser;
        @InvocableVariable
        global Boolean encryptWithManagedIV;
    }

    //class to wrap data sent to Flow service.
    global class EncryptionResponse {
        @InvocableVariable
        global String encryptedToken;
        @InvocableVariable
        global String encryptedCode;
        @InvocableVariable
        global Boolean success;
    }

    //class to create the login response
    global class LoginResponse {
        @AuraEnabled
        global String storefrontURL;
        @AuraEnabled
        global String message;
        @AuraEnabled
        global Boolean success;
        @AuraEnabled
        global String userFirstName;
        @AuraEnabled
        global String userLastName;
        @AuraEnabled
        global String userEmail;
        @AuraEnabled
        global String userId;
        @AuraEnabled 
        public Boolean isMappedAccount;
        /*@AuraEnabled
        global List<ECOM_AccountWrapper.AccountDetails> accountDetails;
        @AuraEnabled
        global WebCart cartDetails;*/
    }

}