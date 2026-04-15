/**************************************************************
 * 1. Ticket(s) that relates to this class
 * - ECOM-70
 * 
 * 2. Description - It is a wrapper class used to store request and response wrapper object for Set Password Request.
 *					It is referenced in 'ECOM_SetPasswordFlowService' class.
 *    				request comes from FLOW 'SUB.FLOW_4492: ECOM - Set Password' and response is returend from apex class 'ECOM_SetPasswordFlowService'.
 *
 * 3. Objects referenced
 * - None
 *
 * 4. Callouts to additional Components (including their methods) or None:
 * - None
 *
 * 5. Dependant Class(es):
 * - ECOM_SetPasswordFlowController
 * - ECOM_UserService
 *
 * 6. Test Class Name: NA
 *
 * 7. Is @Invocable (Yes or No): No
 *
 * 8. Author Name(s): 
 * - Manish Kumar 2023.07.20
 *
*************************************************************/ 
global with sharing class ECOM_SetPasswordFlowWrapper {

    //This class acts as a wrapper for password request.
    global class PasswordRequest{
        @InvocableVariable
        global String userName;
        @InvocableVariable
        global String userId;
        @InvocableVariable
        global String newPassword;
        @InvocableVariable
        global String token;
        @InvocableVariable
        global String code;
    }

    //This class acts as a wrapper for password response.
    global class PasswordResponse
    {
        @InvocableVariable
        global Boolean success;
        @InvocableVariable
        global String message;
    }

}