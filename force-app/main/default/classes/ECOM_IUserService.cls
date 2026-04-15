/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-69  
* 	 ECOM-2555
*
* 2. Description - This class is used to login user into the system.
*
* 3. Objects referenced
*    - User
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
* 5. Dependant Class(es):
*    - ECOM_UserService
*
* 6. Test Class Name: 
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vipul 2023.08.01
* 	 - Vasudev R 2023.11.27
*	 - Vasuedv R 2024.04.23 - ECOM-2555 Added new method to fetch user record based on username
*************************************************************/
public interface ECOM_IUserService {
    
    List<ECOM_SetPasswordFlowWrapper.PasswordResponse> setPassword(List<ECOM_SetPasswordFlowWrapper.PasswordRequest> request);
    User getUserByUserId();
    User getUserByUser(String userId);
    String userLogin(Map<String, String> mapPageParams); 
    Map<String,String> preparePunchoutLoginParameters(ECOM_PunchoutUserWrapper.Request wrappedRequest);//VRa - Punchout changes
    Map<String,Object>getUserNavigationConfig(String labelName, String userType);//VRa - Punchout changes
    Map<String,Object> checkQuickOrderAllowedForUser(ERP_AddressModel addressModel, Map<String,Object> userTypeConfigMap);//VRa - Punchout changes
    ERP_AddressModel getPunchoutAddressModelForUserId(String userId); //VRa - Punchout changes
    ECOM_POUserModel getUserModelForPunchoutUserName(String userName); //VRa - Punchout changes
    User getPunchoutUserForUserName(String userName);//VRa - Punchout changes
    Boolean isPunchoutUserExists(String userName);//VRa - Punchout changes
    Boolean insertNewUserWithDmlOptions(Database.DMLOptions dmlOptions, User newUserRecord);//VRa - Punchout changes
    String getBaseStoreUrl();//VRa - Punchout changes
    User getUserByUserName(String userName);//VRa - ECOM-2555 changes
}