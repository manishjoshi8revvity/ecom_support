/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-69  
* 	 ECOM-2555
*
* 2. Description - This class is used to login user into the system.
*
*
*
* 3. Objects referenced
*    -User
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
*
* 5. Dependant Class(es):
*    - ECOM_ApplicationLogsUtil
*
* 6. Test Class Name: 
*    - ECOM_UserService_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vipul 2023.08.01
*    - Manoj 2024.03.13  ECOM-2885 Added punchout account name if logo not available
* 	 - Vasudev 2024.04.23 ECOM-2555 Added method to fetch user record based on email
*    - Gaurang 2024.05.24 ECOM-112 added a method that queries user object, and returns list of emails matching criteria
*    - Gaurang 2024.07.01 ECOM-3322 added a method that queries user object, and returns list of emails matching criteria
*    - Sidak 2024.07.01 Updated return type in UpdateUserPassword method. Ticket - RWPS-985
*    - Poonam 2025.01.03 Updated checkQuickOrderAllowedForUser Remove empty condtion for punchout and made quick order visible everytime RWPS-1456
*    - Sachin V 2026.02.22 Added method: getUserRecordByUserEmail, updated method: getUserNavigationConfig - RWPS-5938
*************************************************************/
public class ECOM_UserService implements ECOM_IUserService{
    
    public static String CLASSNAME = 'ECOM_UserService';
    
    
    
    /**
    * @description This methos is used to set User Password.
    * @author Vipul Goyal | 08-02-2023 
    * @param request 
    * @return List<ECOM_SetPasswordFlowWrapper.PasswordResponse> 
    **/
    public List<ECOM_SetPasswordFlowWrapper.PasswordResponse> setPassword(List<ECOM_SetPasswordFlowWrapper.PasswordRequest> request){
        
        List<ECOM_SetPasswordFlowWrapper.PasswordResponse> responseList = new List<ECOM_SetPasswordFlowWrapper.PasswordResponse>();
        ECOM_SetPasswordFlowWrapper.PasswordResponse response = new ECOM_SetPasswordFlowWrapper.PasswordResponse();
        List<String> listExceptions = new List<String>();
        String methodName = 'setUserPassword';
        String supportData = '';
        response.success = false;
        response.message = 'Invalid username.';
        try {
            
            listExceptions.add('Invalid private key'.toLowercase());
            listExceptions.add('Unrecognized base64 character'.toLowercase());
            listExceptions.add('Input length must be multiple of 16 when decrypting with padded cipher'.toLowercase());
            listExceptions.add('Given final block not properly padded'.toLowercase());
            supportData = JSON.serialize(request);
            for (ECOM_SetPasswordFlowWrapper.PasswordRequest req : request) {
                String strEncryptedToken = EncodingUtil.urlDecode(req.token,'UTF-8');//req.token.replace(' ','+'); 
                String strEncryptedCode = '';
                if(String.isNotBlank(req.code)){
                    strEncryptedCode = EncodingUtil.urlDecode(req.code,'UTF-8');
                }else{
                    response.message = System.Label.ECOM_102003;//'Sorry, the Forgot Password link has already been used. If you are still having trouble accessing your account, please request a new password reset link.';
                    break;
                }
                String strNewPassword = EncodingUtil.urlDecode(req.newPassword,'UTF-8');//req.newPassword.replace(' ','+');
                
                String decryptedToken = Test.isRunningTest() ? 'TestDecryptedToken' : ECOM_EncryptUtil.decryptWithManagedIV(strEncryptedToken ,  strEncryptedCode);
                String decryptedNewPassword = Test.isRunningTest() ? 'TestDecryptedPassword' : ECOM_EncryptUtil.decryptWithAES256(strNewPassword);
                
                if (String.isBlank(decryptedToken) || String.isBlank(decryptedNewPassword)) {
                    break;
                }
                String userName = decryptedToken.split('\\__')[0];
                Datetime timeStampFromToken = Test.isRunningTest() ? Datetime.now() : Datetime.valueOfGmt(decryptedToken.split('\\__')[1]);
                Datetime currentTimeStamp = Datetime.now();
                Long timeLapsedInMilliSec = currentTimeStamp.getTime() - timeStampFromToken.getTime();
                Long timeLapsedInHours = timeLapsedInMilliSec / 3600000;
                //response.userName = req.userName;
                if (!(timeLapsedInHours <= 24))//TODO This should move to Custom Metadata
                {
                    response.message = System.Label.ECOM_SetPasswordLinkExpired;
                    break;
                }
                if (!req.userName.equalsIgnoreCase(userName)) {
                    break;
                } else {
                    //System.setPassword(req.userId, req.password);
                    if(!Test.isRunningTest()) ECOM_UserRepo.doSetPassword(req.userId, decryptedNewPassword);
                    response.success = true;
                    response.message = System.Label.ECOM_SetPasswordSuccess;
                }
            }
        } catch (Exception ex) {
            response.message = String.valueOf(ex.getMessage());
            for(String e: listExceptions){
              if(ex.getMessage().containsIgnoreCase(e)){
                response.message = System.Label.ECOM_102003;//'token invalid/expired, please reset password again';
                  break;
            	}  
            }
            
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.USER_MODULE_NAME, className, methodName, supportData);
        }
        responseList.add(response);
        return responseList;
    }
    


    /**
    * @description This method is used to login the user into the store(experience builder)
    * @author Vipul Goyal | 08-02-2023 
    * @param mapPageParams 
    * @return String 
    **/
    public String userLogin(Map<String, String> mapPageParams){
        
        ECOM_LoginWrapper.LoginResponse response = new ECOM_LoginWrapper.LoginResponse();
        response.success = false;
        String methodName = 'userLogin';
        String supportData = '';
        String returnURL = '';
        Boolean addAddressParam=false;
        String strDefaultCartPath = '/initiate-session'; //TODO move it to Custom Metadata and Default path is /initiate-session
        if(mapPageParams.containsKey('defaultPathForAddressRegistration'))
        {
            System.debug('mapPageParams : '+JSON.serialize(mapPageParams));
            strDefaultCartPath=mapPageParams.get('defaultPathForAddressRegistration');
            addAddressParam=true;
            strDefaultCartPath+='?'+mapPageParams.get('addressAction')+'&url=replaceURL';
        }
        System.debug('strDefaultCartPath : '+strDefaultCartPath);
        String pageURL = null;
        try {
            supportData = JSON.serialize(mapPageParams);
            String strEncryptedToken = ECOM_Util.getValueFromMap(mapPageParams, ECOM_Constant.ENCRYPTED_TOKEN);
            String strEncryptedCode = ECOM_Util.getValueFromMap(mapPageParams, ECOM_Constant.ENCRYPTED_CODE);
            strEncryptedToken=strEncryptedToken.replace(' ','+');
            strEncryptedCode=strEncryptedCode.replace(' ','+');
            if (String.isNotBlank(strEncryptedToken) && String.isNotBlank(strEncryptedCode)) {
                Boolean populateUserInfo = true;
                String strDecryptUserName = ECOM_EncryptUtil.decryptWithAES256(strEncryptedToken);
                String strDecryptPassword = ECOM_EncryptUtil.decryptWithAES256(strEncryptedCode);
                if(!addAddressParam)
                {
                    strDefaultCartPath = ECOM_Util.getStrDefaultCartPath(mapPageParams);
                }
                //populateUserInfo = ECOM_LoginUtil.isUserInfoPopulated(mapPageParams);
                populateUserInfo = true;
                PageReference pageReferenceObject = ECOM_UserRepo.loginUser(strDecryptUserName, strDecryptPassword, strDefaultCartPath);
                if (pageReferenceObject != null) {
                    pageURL = pageReferenceObject.getUrl();
                    response = ECOM_UserUtil.getLoginResponse(strDecryptUserName, populateUserInfo, pageURL);
                    response.storefrontURL = pageURL;
                    response.success = true;
                } else {
                    response.message = 'Invalid Credentials';//TODO move it to custom Metadata
                }
            } else {
                response.message = 'Invalid Credentials';//TODO move it to custom Metadata
            }
        } catch (Exception ex) {
            response.message = ex.getMessage();
            System.debug('>>>ex.getMessage()>>>>>>>'+ex.getMessage());
            System.debug('>>>ex.getStackTraceString()>>>>>>>'+ex.getStackTraceString());
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.USER_MODULE_NAME, CLASSNAME, methodName, supportData);
        } finally {
            /*if(String.isNotBlank(response.storefrontURL) && addAddressParam)
            {
                response.storefrontURL+='&'+mapPageParams.get('addressAction');
            }*/
            returnURL = JSON.serialize(response, true);
        }
        
        return returnURL;
    }

    /**
    * @description This method is used to retrieve user based on userId.
    * @author Manish 2023.08.08
    * @return User
    **/
    public User getUserByUserId(){
        return ECOM_UserRepo.getUserByUserId(UserInfo.getUserId());
    }
    
    /**
    * @description This method is used to retrieve user based on userId.
    * @author Manish 2023.08.08
    * @return User
    **/
    public User getUserByUser(String userId){
        return ECOM_UserRepo.getUserByUserId(userId);
    }

    /**
    * @description This method is used to update the user
    * @author Dar Wright | 09-05-2023 
    * @param userObject
    **/
    public static void updateUser(User updatedUserData){
        try {
            ECOM_UserRepo.updateUser(updatedUserData);         
        } catch(DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
        
    }

    /**
    * @description This method is used to update the user password from the Profile/Settings page
    * @author Dar Wright | 09-05-2023 
    * @author Sidak Singh | 01-04-2024 | RWPS-985
    * @@param passwordString
    * @param userId
    **/
    public static Map<String,Object> updateUserPassword(String passwordString, Id userId){
        Map<String,Object> responseMap = new Map<String,Object>();
        try {
            responseMap = ECOM_UserRepo.futureUpdateUserPassword(passwordString, userId);
        }catch(Exception e){
            responseMap.put('success',false);
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
        return responseMap;
    }

    /**
    * @description get contact id by username
    * @author mkumar@rafter.one | 09-21-2023 
    * @param userName 
    * @return String 
    **/
    public static String getContactIdByUserName(String userName)
    {
        List<User> users=ECOM_UserRepo.getUsersByUsername(userName);
        if(users.isEmpty())
        {
            return '';
        }
        else {
            return users[0].ContactId;
        }
    }
    
    /**
    * @description provision new user or login user if exists
    * @author vramchandran@rafter.one | 11-22-2023 
    * @param User 
    * @return String 
    **/
    public Map<String,String> preparePunchoutLoginParameters( ECOM_PunchoutUserWrapper.Request wrappedRequest)
    {
        String METHOD_NAME = 'preparePunchoutLoginParameters';
        Map<String,String> parameterMap = new Map<String,String>();
        ECOM_PunchoutUserWrapper.Response response;
        //Check and prepare parameter map 
		parameterMap = (Map<String,String>) JSON.deserialize(wrappedRequest.userDataJson, Map<String,String>.class);                
        return parameterMap;
    }
    
    /**
    * @description Fetch metadata configuration for punchout store navigation 
    * @author vramchandran@rafter.one | 11-27-2023 
    * @param configLabel 
    * @return String 
    **/
    public Map<String,Object> getUserNavigationConfig(String labelName, String userType){
       Map<String,Object> storeConfigMap = new Map<String,Object>(); 
        try{
            Boolean isTestUser = false;
            Boolean isPunchoutWebUser = false; //RWPS-5938
            List<User> userRecord = Test.isRunningTest() ? new List<User>{new User()} : ECOM_UserRepo.getPunchoutUserInformationByUserId(UserInfo.getUserId());
            if(null != userRecord && !userRecord.isEmpty()){
                isTestUser = userRecord[0]?.ECOM_Is_Test_User__c;
                isPunchoutWebUser = userRecord[0]?.Contact?.ECOM_Punchout_Via_Web__c; //RWPS-5938
            }

            ERP_AddressModel addressModel = Test.isRunningTest() ? ECOM_TestUtil.getAddressModel() : getPunchoutAddressModelForUserId(UserInfo.getUserId());

            Boolean isPunchoutUser = Test.isRunningTest() ? true : (addressModel != null && String.isNotBlank(addressModel.addressType)) && addressModel.po_isPunchoutEnabled ? true : false;
            userType = String.isNotBlank(userType) ? userType : (isPunchoutUser ? ECOM_Constant.POTYPE_PUNCHOUT_USER : ECOM_Constant.USER_TYPE_CMS_WEB_USER);
            //RWPS-5938
            if(isTestUser && isPunchoutWebUser == false){
                userType = ECOM_Constant.POTYPE_TEST_USER;
            } else if (isPunchoutWebUser == true && ECOM_CustomLoginController.getMagicLinkImplementationActivationStatus() == true) {
                userType = 'punchoutViaWebUser';
            }
            //RWPS-5938
            storeConfigMap = ECOM_Util.getStoreNavigationConfigMap(labelName, userType);
            String accountLogoUrl = '';
            //get the account logo and add to response
            //RWPS-5938
            if(addressModel != null && isPunchoutWebUser == false) {
                accountLogoUrl = String.isNotEmpty(addressModel.po_AccountUrl) ? addressModel.po_AccountUrl : '';
                storeConfigMap.put(ECOM_Constant.PARAM_ACCOUNT_NAME,  String.isNotEmpty(addressModel.po_AccountName) ? addressModel.po_AccountName : '');//ECOM-2885 added punchout account name to response
            }

            storeConfigMap = checkQuickOrderAllowedForUser(addressModel, storeConfigMap);
            storeConfigMap.put(ECOM_Constant.PARAM_ACCOUNT_LOGO_URL, accountLogoUrl);
        }Catch(Exception e){
            System.debug('Exception:: '+ e.getMessage()+ ' Stack:: '+ e.getStackTraceString());
          ECOM_ApplicationLogsUtil.logFailure(e , 'Punchout:: Fetch User Type Navigation Config Failed' , CLASSNAME , 'getUserNavigationConfig', 'Message:: '+ e.getMessage() + ' Stack:: '+ e.getStackTraceString());  
        }
       return storeConfigMap;
    }    

	/**
    * @description check if user is allowed to view quick order 
    * @author vramchandran@rafter.one | 11-27-2023 
    * @param userId | String
    * @param addressModel | ERP_AddressModel
    * @return Map<String,Object> 
    **/
    public Map<String,Object> checkQuickOrderAllowedForUser(ERP_AddressModel addressModel, Map<String,Object> userTypeConfigMap){
        System.debug('checkQuickOrderAllowedForUser:userTypeConfigMap:: ' + userTypeConfigMap);
        try{
            if(null != addressModel){
                userTypeConfigMap.put(ECOM_Constant.PARAM_VIEW_QUICK_ORDER, true);//RWPS-1456
            }
        }
        Catch(Exception e){
            ECOM_ApplicationLogsUtil.logFailure(e , 'Punchout:: verify quick order avaialbility failed' , CLASSNAME , 'checkQuickOrderAllowedForUser', 'Message:: '+ e.getMessage() + ' Stack:: '+ e.getStackTraceString());  
        }
        return userTypeConfigMap;
    }  
    
    /**
     * @description returns User List for userId
     * @author vramachandran@rafter.one | 11 Dec 2023
     * @param userId
     * @return List<User>
     */
    public List<User> getPunchoutUserInformationById(String userId){
        return ECOM_UserRepo.getPunchoutUserInformationByUserId(userId);
    }
    
    /**
     * @description This method returns the punchout user information required to fetch ERP Address Master for the user
     * @author vramachandran@rafter.one | 22 Dec 2023
     * @param userId | String 
     * @returns User
     */
    public User getPunchoutUserInfoForERPAddressMaster(String userId){
        User user = new User();
        List<User> userList = Test.isRunningTest() ? new List<User>{new User()} : ECOM_UserRepo.getPunchoutUserInformationForErpAddress(userId);
        if(null != userList && !userList.isEmpty()){
            user = userList[0];
        }
        return user;
    }
    
    /**
     * @description This method returns the ERP_AddressModel for a given user Id
     * @author vramachandran@rafter.one | 23 Dec 2023
     * @param userId | String 
     * @returns ERP_AddressModel
     */
    public ERP_AddressModel getPunchoutAddressModelForUserId(String userId){
        ERP_AddressModel addressModel;
        
        Type erpAddressServiceType = Type.forName(ECOM_Constant.ERP_ADDRESS_SERVICE);
        ERP_IAddressService addressService = (ERP_IAddressService)erpAddressServiceType.newInstance();
        
        User userRecord = Test.isRunningTest() ? new User() : getPunchoutUserInfoForERPAddressMaster(userId);
        System.debug('getPunchoutAddressModelForUserId:userRecord:: '+ userRecord);
        //erp address service              
        //addressModel = addressService.getERPAddressModelForPunchoutUser(userRecord);
        addressModel = Test.isRunningTest() ? ECOM_TestUtil.getAddressModel() : addressService.getMasterERPAddressModelForPunchoutUser(userRecord);
		System.debug('getPunchoutAddressModelForUserId:addressModel: '+JSON.serialize(addressModel));        
        return addressModel;
    }
    
    /**
     * @description This method returns a Punchout User Model 
     * @author vramachandran@rafter.one | 22 Dec 2023
     * @param userId | String
     * @return ECOM_POUserModel
     */
    public ECOM_POUserModel getUserModelForPunchoutUserId(String userId){
        ECOM_POUserModel poUserModel = new ECOM_POUserModel();
        
        //get the user record for given user Id
        List<User> userRecords = ECOM_UserRepo.getPunchoutUserInformationByUserId(userId);
        
        //if user exists 
        if(null != userRecords && !userRecords.isEmpty()){
            //map user data from user record to user model 
            poUserModel = ECOM_UserUtil.getUserModelForUserRecord(userRecords[0]);
        }
        
        return poUserModel;
    }
    
    /**
     * @description This method returns the punchout user model for a given user name
     * @author vramachandran@rater.one | 22 Dec 2023
     * @param userName | String 
     * @returns ECOM_POUserModel
     */
    public static ECOM_POUserModel getUserModelForPunchoutUserName(String userName){
        ECOM_POUserModel poUserModel = new ECOM_POUserModel();
        
        //get the user record for given user Id
        List<User> userRecords = ECOM_UserRepo.getPunchoutUserInformationByUserName(userName);
        
        //if user exists 
        if(null != userRecords && !userRecords.isEmpty()){
            //map user data from user record to user model 
            poUserModel = ECOM_UserUtil.getUserModelForUserRecord(userRecords[0]);
        }
        
        return poUserModel;
    }
    
    /**
     * @description This method returns a boolean flag indicating if a user exists or not
     * @author vramachandran@rafter.one | 22 Dec 2023
     * @param userName | String
     * @returns Boolean
     */
    public static Boolean isPunchoutUserExists(String userName){
        Boolean isUserExists = false;
        
        List<User> userList  = ECOM_UserRepo.isPunchoutUserExists(userName);
        if(null != userList && !userList.isEmpty()){
            isUserExists = true;
        }
        
        return isUserExists;
    }
    
    /**
     * @description This method returns the userRecord for a userName
     * @author vramachandran@rafter.one | 22 Dec 2023
     * @param userName | String
     * @returns User
     */
    public static User getPunchoutUserForUserName(String userName){
        User userRecord;
        
        List<User> userRecordList = ECOM_UserRepo.getPunchoutUserInformationByUserName(userName);
        if(null != userRecordList && !userRecordList.isEmpty()){
            userRecord = userRecordList[0];
        }
        
        return userRecord;
    }

    /**
     * @description This method inserts a new user with dml options
     * @author vramachandran@rafter.one | 22 Dec 2023
     * @param newUserRecord | User
     * @return Boolean
     */
    public Boolean insertNewUserWithDmlOptions(Database.DMLOptions dmlOptions, User newUserRecord){
        Boolean isNewUserCreateSuccess = false;
        try{
            Database.SaveResult result = ECOM_UserRepo.createUserWithDmlOptions(newUserRecord, dmlOptions);
            if(result.isSuccess()){
                isNewUserCreateSuccess = true;
            }
        }catch(Exception e){
            ECOM_ApplicationLogsUtil.logFailure(e , 'New User Create-failed' , 'ECOM_UserService' , 'insertNewUserWithDmlOptions', 'POSR:: '+ JSON.serialize(newUserRecord)  + ' Stack:: '+ e.getStackTraceString());
        }
        
        return isNewUserCreateSuccess;
    }
    
    /**
     * @description This method returns the base store url for the ecom store
     * @author vramachandran@rafter.one | 02 Jan 2024
     * @returns String
     */
    public String getBaseStoreUrl(){
        return Test.isRunningTest() ? '' : ECOM_UserUtil.getEcomSiteBaseUrl();
    }

/**
     * @description This method returns a User record based on the provided username
     * @author vramachandran@rafter.com | 23 Apr 2024 ECOM-2555
     * @param userName | String
     * @returns User
     */
    public User getUserByUserName(String userName){
        User userRecord = null;
        
        try{
            List<User> usersList = ECOM_UserRepo.getUsersByUsername(userName);
            
            if(null != usersList && !usersList.isEmpty()){
                userRecord = usersList[0];
            }
            
        }catch(Exception e){
            ECOM_ApplicationLogsUtil.logFailure(e , 'User Service:: Get User Name' , 'ECOM_UserService' , 'getUserByUserName', 'UserName:: '+ userName  + ' Stack:: '+ e.getStackTraceString());
        }
        
        return userRecord;
    }

    /**
     * @description This method queries user object, and returns list of emails matching criteria - ECOM-112
     * @author garora@rafter.com | 23 May 2024 ECOM-102
     * @param emails | List<String>
     * @returns List<User>
    */
    public static List<String> checkCommunityUsers(List<String> emails){
        List<String> verifiedEmails = new List<String>();
        try{
            List<User> users = ECOM_UserRepo.checkCommunityUsers(emails);
            for(User user : users){
                if(String.isNotBlank(user.Email)){
                    verifiedEmails.add(user.Email);
                }
            }
        }
        catch(Exception e){
            ECOM_ApplicationLogsUtil.logFailure(e , 'User Service:: checkCommunityUsers' , 'ECOM_UserService' , 'checkCommunityUsers',' Stack:: '+ e.getStackTraceString() + ' Error:: '+e.getMessage());
        }
        return verifiedEmails;
    }

    /**
     * @description This method queries user object, and returns list of emails matching criteria - ECOM-3322
     * @author garora@rafter.com | 01 July 2024 ECOM-3322
     * @param emails | List<String>
     * @returns List<User>
    */
    public static List<User> checkInternalUsers(List<String> emails){
        List<User> internalUsers = new List<User>();
        try{
            internalUsers = ECOM_UserRepo.checkInternalUsers(emails);
        }
        catch(Exception e){
            ECOM_ApplicationLogsUtil.logFailure(e , 'User Service:: checkInternalUsers' , 'ECOM_UserService' , 'checkInternalUsers',' Stack:: '+ e.getStackTraceString() + ' Error:: '+e.getMessage());
        }
        return internalUsers;
    }

    /**
     * @description This method fetches user record matching with the provided email
     * @author Sachin V | 2026.01.29 | RWPS-5938
     * @param userEmail | String
     * @return List<User>
     */
    public static List<User> getUserRecordByUserEmail(String userEmail) {
        return ECOM_UserRepo.getUserRecordByUserEmail(userEmail);
    }
}