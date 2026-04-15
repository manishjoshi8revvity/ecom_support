/**************************************************************
  * 1. Ticket(s) that relates to this class
  *    - OM-247
  *
  * 2. Description - This class is used to trigger reset password for user,
  * 				 Invoked from S.FLOW_9202: User - Reset Password
  *
  * 3. Objects referenced
  *    - None
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None
  *
  * 5. Dependant Class(es):
  *    - None
  *
  * 6. Test Class Name: UTIL_ResetPasswordUser_Test
  *
  * 7. Is @Invocable (Yes or No):  No
  *
  * 8. Author Name(s): 
  *    - Aakash Pal 2023.11.08
  *
*************************************************************/
public class UTIL_ResetPasswordUser {
    @InvocableMethod(label='ResetPassword' description='Reset User Password' category='User')
    Public static void resetPassWord(List<FlowInputs> Request){
        if(Request != null && Request[0].UserId != null){
            boolean  var_emailSend=Request[0].sendEmail != null ? Request[0].sendEmail : False;
            system.ResetPassword(Request[0].UserId,var_emailSend);   
        }
        
    }
    Public class FlowInputs { 
        @InvocableVariable Public String UserId; 
        @InvocableVariable Public boolean  sendEmail; 
    }
    
    
}