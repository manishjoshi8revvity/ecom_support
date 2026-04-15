/**************************************************************
 * 1. Ticket(s) that relates to this class
 * - ECOM-70
 * 
 * 2. Description - It is a controller class used to set password for the user who requested for it.
 *    it is invoked from Flow 'SUB.FLOW_4492: ECOM - Set Password'
 *    which is receiving the request from CMS and calling this class to process the request and send response.
 * 
 * 3. Objects referenced
 * - None
 * 
 * 4. Callouts to additional Components (including their methods) or None:
 * - None
 * 
 * 5. Dependant Class(es):
 * - ECOM_SetPasswordFlowWrapper
 * - ECOM_UserService
 * 
 * 6. Test Class Name: 
 * - ECOM_SetPasswordFlowController_Test
 * 
 * 7. Is @Invocable (Yes or No): Yes
 * 
 * 8. Author Name(s):
 * - Manish Kumar 2023.07.20
 *************************************************************/
global class ECOM_SetPasswordFlowController {

    /**
     * this method is used to get the request from flow 'SUB.FLOW_4492: ECOM - Set Password' and sends it to service class for further processing.
     *
     * @param request <ECOM_SetPasswordFlowWrapper.PasswordRequest>
     *
     * @return List<ECOM_SetPasswordFlowWrapper.PasswordResponse>
     * 
     * @author manish.kumar@rafter.one | 07-20-2023
     */
    @InvocableMethod(Label='Set Password' Category='User Management' Description='It set password of the user')
    public static List<ECOM_SetPasswordFlowWrapper.PasswordResponse> setUserPassword(List<ECOM_SetPasswordFlowWrapper.PasswordRequest> request) {
        List<ECOM_SetPasswordFlowWrapper.PasswordResponse> responseList = new List<ECOM_SetPasswordFlowWrapper.PasswordResponse>();
        Type userService = Type.forName(ECOM_Constant.USER_SERVICE);
		ECOM_IUserService userServiceInstance = (ECOM_IUserService)userService.newInstance();
        responseList = userServiceInstance.setPassword(request);
        return responseList;
        
    }

}