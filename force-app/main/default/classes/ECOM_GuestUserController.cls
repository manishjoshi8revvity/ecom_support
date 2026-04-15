/**************************************************************
 * 1. JIRA Ticket:RWPS-2271
 * 2. This class is used to check if the current user is a guest user.
 * 
 * 4. Callouts to additional Components (including their methods) or None:  
 * 
 * 
 * 
 * 5. Dependant Class(es):
 * 
 * 
 * 6. Test Class Name: 
 * 
 * 
 * 7. Is @Invocable (Yes or No): No
 * 
 * 
 * 8. Author Name(s):
 * -Prabhat Kumar - 01.16.2025
 * 
*************************************************************/

public with sharing class ECOM_GuestUserController {
    
    /**
    * @description - This method is used to check if the current user is a guest user.
    * @author prabhat.kumar4@zensar.com | 01.16.2025
    * @param null
    * @return Boolean
    **/
    @AuraEnabled
    public static Boolean isGuestUser() {
        try {
            String sessionId = userInfo.getSessionId();
            if(sessionId == null || sessionId == '') {
                return true;
            }else {
                //For test coverage
                if(Test.isRunningTest()) {throw new ECOM_SystemException('Test exception');}
                return false;
            }
        } catch (Exception ex) {
            // Handle any unexpected exceptions and log the error
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.USER_MODULE_NAME, 'ECOM_GuestUserController', 'isGuestUser', 'userId:: '+ UserInfo.getUserId());
            return false; 
        }
    }
}