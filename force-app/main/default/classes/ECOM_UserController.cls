/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-
*
* 2. Description -
*
*
* 3. Objects referenced
*    - User
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
*
* 5. Dependant Class(es):
*    - ECOM_UserService
*
* 6. Test Class Name:
*    - ECOM_UserController_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vipul 2023.07.19
* 	 - vramachandran@rafter.one | 15 Dec 2023
*    - Sidak 2024.07.01 Added try catch block in updateUserPassword method. Ticket - RWPS-985
*    - Abhishek 2025.07.15 Added method getCountriesBannerMsgLoggedin - RWPS-3651
*    - Sachin V 2025.12.26 Created method getOrganizationDetails, getTestUserConfigurations and updated without sharing - RWPS-5436
*************************************************************/

public without sharing class ECOM_UserController {

    final static String CLASSNAME = 'ECOM_UserController';

    /**
    * @description
    * @author Vipul | 2023.07.19
    * @return Map<String, Object>
    **/
    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getUser()
    {
        Map<String,Object> returnMap=new Map<String,Object>();
        returnMap.put('Success',false);
        try {
            User us=new ECOM_UserService().getUserByUserId();
            returnMap.put('Success',true);
            returnMap.put('User',us);

        } catch (Exception e) {
            returnMap.put('ErrorMessage',e.getStackTraceString());
        }
        return returnMap;
    }

    /**
    * @description This method is used to update the user
    * @author Dar Wright | 09-05-2023
    * @param userObject
    **/
    @AuraEnabled
    public static void updateUser(User updatedUserData){
        ECOM_UserService.updateUser(updatedUserData);
    }

    /**
    * @description This method is used to update the user password from the Profile/Settings page
    * @author Dar Wright | 09-05-2023
    * @author Sidak Singh | 01-04-2024 | RWPS-985
    * @param passwordString
    **/
    @AuraEnabled
    public static Map<String,Object> updateUserPassword(String passwordString) {
        Map<String,Object> responseMap = new Map<String,Object>();
        try {
            Id userId = UserInfo.getUserId();
            responseMap = ECOM_UserService.updateUserPassword(passwordString, userId);
        }catch(Exception e){
            responseMap.put('success',false);
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
        return responseMap;
    }

    /**
    * @description This method is used to fetch users navigation config metadata
    * @author Vasudev R | 11-28-2023
    * @param userType
    * @return Map<String,Object>
    **/
    @AuraEnabled
    public static Map<String,Object> getUserNavigationConfig(String userType){
        final String METHOD_NAME = 'getUserNavigationConfig';
        Map<String,Object> responseMap = new Map<String,Object>();
        responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
        try{

            //add changes to check user and if punchout.
            ECOM_IUserService userServiceInstance = (ECOM_IUserService) Type.forName(ECOM_Constant.USER_SERVICE).newInstance();
            Map<String,Object> userNavigationConfiguration =  userServiceInstance.getUserNavigationConfig(ECOM_Constant.PARAM_SITE_NAVIGATION_CONFIG_LABEL, userType);

            responseMap.put(ECOM_CONSTANT.PARAM_RESPONSE_DATA,userNavigationConfiguration);
            responseMap.put(ECOM_Constant.PARAM_SUCCESS, true);
        }catch(Exception e){
            responseMap.put(ECOM_Constant.PARAM_MESSAGE, e.getMessage()+e.getStackTraceString());
            ECOM_ApplicationLogsUtil.logFailure(e , 'User:: Fetch User Navigation Config Failed' , CLASSNAME , METHOD_NAME, 'Message:: '+ e.getMessage() + ' Stack:: '+ e.getStackTraceString());
        }
        return responseMap;
    }

    /**
     * @description This method returns the encrypted url paramaters for cms
     * @author vramachandran@rafter.one | 08 Jan 2024
     * @param params | String
     * @returns String
     */
    @AuraEnabled
    public static Map<String,Object> getEncryptedParmeters(String urlParams){
        final String METHOD_NAME = 'getEncryptedParmeters';
        Map<String,Object> responseMap = new Map<String,Object>();
        responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
        try{
            String decryptedString = ECOM_EncryptUtil.decryptWithAES256(urlParams);
            String sessionStartTimeStamp = String.valueOf(DateTime.now().millisecond());

            decryptedString = decryptedString + '&' + ECOM_Constant.PARAM_EXT_SESSION_STARTED_TIMESTAMP + '=' + sessionStartTimeStamp;
            decryptedString = decryptedString + '&' + ECOM_Constant.PARAM_EXT_IF_SESSION_STARTED_FLAG + '=' + String.valueOf(1);
            System.debug('decryptedString:: '+ decryptedString);

            responseMap.put(ECOM_Constant.PARAM_RESPONSE_DATA, decryptedString);
            responseMap.put(ECOM_Constant.PARAM_SUCCESS, true);
        }catch(Exception e){
            ECOM_ApplicationLogsUtil.logFailure(e , 'User:: get encrypted params failed' , CLASSNAME , METHOD_NAME, 'Message:: '+ e.getMessage() + ' Stack:: '+ e.getStackTraceString());
        }

        return responseMap;
    }

    /**
     * @description This method builds a new encrypted parameter to redirect to CMS page
     * @author vramachandran@rafter.one | 17 Jan 2024
     * @returns String
     */
    @AuraEnabled
    public static Map<String,Object> getEncyrptedSessionParametersForCMS(){
        final String METHOD_NAME = 'getEncyrptedSessionParametersForCMS';

        Map<String,Object> responseMap = new Map<String,Object>();
        responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
        String urlParameters;
        try{
            User userRecord = Test.isRunningTest() ? ECOM_TestUtil.getPunchoutUser() : ECOM_UserUtil.getPunchoutUserForUserId(UserInfo.getUserId());
            ERP_AddressModel addressModel = ERP_AddressUtil.getPunchoutAddressesForAccountId(userRecord.AccountId);
            responseMap.put(ECOM_Constant.PARAM_LOCALE, (null != addressModel && String.isNotEmpty(addressModel.po_Locale)) ? addressModel.po_Locale : '' );
            //Get unix timestamp
            //String timeStamp =

            //build url parameter for current timestamp
            urlParameters = ECOM_Constant.PARAM_EXT_USER_ID + '=' + UserInfo.getUserId();
            urlParameters = urlParameters + '&' + ECOM_Constant.PARAM_EXT_EMAIL_ID + '=' + UserInfo.getUserEmail();
            urlParameters = urlParameters + '&' + ECOM_Constant.PARAM_EXT_SESSION_STARTED_TIMESTAMP + '=' + String.valueOf(DateTime.now().getTime());
        	urlParameters = urlParameters + '&' + ECOM_Constant.PARAM_EXT_IF_SESSION_STARTED_FLAG + '=' + String.valueOf(1);

            System.debug('urlParameters:: '+ urlParameters);

            responseMap.put(ECOM_Constant.PARAM_RESPONSE_DATA, EncodingUtil.urlEncode(ECOM_EncryptUtil.encryptWithAES256(urlParameters), ECOM_Constant.URL_ENCODING_UTF_8) );
            responseMap.putAll(ECOM_CartRepo.getStorefrontFrontConfigByModule(System.Label.ECOM_CMSSiteUrl));
            responseMap.put(ECOM_Constant.PARAM_SUCCESS, true);
        }catch(Exception e){
            ECOM_ApplicationLogsUtil.logFailure(e , 'User:: Build Encyrpted URL Parameter - failed' , CLASSNAME , METHOD_NAME, 'Message:: '+ e.getMessage() + ' Stack:: '+ e.getStackTraceString());
        }
        return responseMap;
    }

    /**
     * @description This method is used to get all cms parameters for a cms store user
     * @author vramachandran@rafter.one | 23 May 2024 ECOM-1554
     * @returns Map<String, Object>
     */
    @AuraEnabled
    public static Map<String, Object> getCmsRedirectMapForWebUser(){
        final String METHOD_NAME = 'getEncyrptedSessionParametersForCMS';

        Map<String,Object> responseMap = new Map<String,Object>();
        responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
        String urlParameters;
        try{
            //build url parameter for current timestamp
            urlParameters = ECOM_Constant.PARAM_EXT_USER_ID + '=' + UserInfo.getUserId();
            urlParameters = urlParameters + '&' + ECOM_Constant.PARAM_EXT_EMAIL_ID + '=' + UserInfo.getUserEmail();
            urlParameters = urlParameters + '&' + ECOM_Constant.PARAM_EXT_SESSION_STARTED_TIMESTAMP + '=' + String.valueOf(DateTime.now().getTime());
        	urlParameters = urlParameters + '&' + ECOM_Constant.PARAM_EXT_IF_SESSION_STARTED_FLAG + '=' + String.valueOf(1);

            System.debug('urlParameters:: '+ urlParameters);

            responseMap.put(ECOM_Constant.PARAM_RESPONSE_DATA, EncodingUtil.urlEncode(ECOM_EncryptUtil.encryptWithAES256(urlParameters), ECOM_Constant.URL_ENCODING_UTF_8) );
            responseMap.putAll(fetchStorefrontFrontConfigByModule(System.Label.ECOM_CMSSiteUrl));
            responseMap.put(ECOM_Constant.PARAM_SUCCESS, true);
        }catch(Exception e){
            ECOM_ApplicationLogsUtil.logFailure(e , 'User:: Build Encyrpted URL Parameter - failed' , CLASSNAME , METHOD_NAME, 'Message:: '+ e.getMessage() + ' Stack:: '+ e.getStackTraceString());
        }
        return responseMap;
    }

    /**
     * @description This method returns required information for CMS redirection post login
     * @author vramachandran@rafter.one | 2024.04.24 ECOM-2555
     * @param cmsParams | String
     * @param cmsLabel | String
     * @param cmsLocale | String
     */
    @AuraEnabled
    public static Map<String, Object> getCMSRedirectDataMap(String cmsParams, String cmsLocale, String redirectTo){
		String METHOD_NAME = 'getCMSRedirectDataMap';

        Map<String, Object> responseMap = new Map<String, Object>();
        responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);

        System.debug('cmsParams:: '+ cmsParams + ' cmsLocale:: '+ cmsLocale + ' redirectTo:: '+ redirectTo);

        try{
            if(String.isEmpty(cmsParams)){
                Map<String, Object> methodDataMap = getCmsRedirectMapForWebUser();
                System.debug('generated cmsParams:: '+ JSON.serialize(methodDataMap.get(ECOM_Constant.PARAM_RESPONSE_DATA)));
                cmsParams = (String)methodDataMap.get(ECOM_Constant.PARAM_RESPONSE_DATA);
            }

            //String decryptedParameters = ECOM_EncryptUtil.decryptWithAES256(cmsParams);
            //String encrypted = EncodingUtil.urlEncode(ECOM_EncryptUtil.encryptWithAES256(decryptedParameters), 'UTF-8');

			responseMap.putAll(ECOM_CartController.getCMSBaseUrl(System.Label.ECOM_CMSSiteUrl));
			responseMap.put(ECOM_Constant.PARAM_RESPONSE_DATA, cmsParams);

            String profileRedirectionEndpoint = ECOM_ContactService.getRedirectionEndpointForContact(UserInfo.getUserEmail());
            if(String.isNotBlank(profileRedirectionEndpoint)) {

                responseMap.put(ECOM_Constant.PARAM_PROFILE_REDIRECT, profileRedirectionEndpoint);
            }

            //get user locale and compare with metadata
            String userCmsLocale = getCMSLocale();
            if(String.isNotBlank(userCmsLocale)) {
                responseMap.put(ECOM_Constant.PARAM_LOCALE, userCmsLocale);
            }

			System.debug('redirectTo:: '+ redirectTo);
            if(String.isNotBlank(redirectTo)){
                responseMap.put(ECOM_Constant.PARAM_REDIRECT_TO , EncodingUtil.urlDecode(ECOM_EncryptUtil.decryptWithAES256(redirectTo), 'UTF-8'));
            }

            System.debug('responseMap:: ' + JSON.serialize(responseMap));
            responseMap.put(
                ECOM_Constant.PARAM_SUCCESS, true
            );
        }catch(Exception e){
            System.debug('Exception:: User Create Session:: '+ e.getStackTraceString());
            ECOM_ApplicationLogsUtil.logFailure(e , 'User:: Web User Create Session - failed' , CLASSNAME , METHOD_NAME, 'Message:: '+ e.getMessage() + ' Stack:: '+ e.getStackTraceString());
        }
        System.debug('responseMap:: '+ JSON.serialize(responseMap));

        return responseMap;
    }

    @AuraEnabled
    public static Map<String, String> fetchStorefrontFrontConfigByModule(String moduleName) {
        Map<String, String> mapModuleConstants = new Map<String, String>();
        List<C_META_Storefront_Configuration__mdt> b2BStorefrontConfigurations = [
            SELECT Id, DeveloperName, MasterLabel, ModuleName__c, Value__c
            FROM C_META_Storefront_Configuration__mdt
            WHERE ModuleName__c = :moduleName
        ];
        if (b2BStorefrontConfigurations != null && b2BStorefrontConfigurations.size() > 0) {
            for (C_META_Storefront_Configuration__mdt b2BStorefrontConfiguration : b2BStorefrontConfigurations) {
                mapModuleConstants.put(
                    b2BStorefrontConfiguration.MasterLabel, b2BStorefrontConfiguration.Value__c
                );
            }
        }
        return mapModuleConstants;
    }


    private static String getCMSLocale() {
        Map<String, Object> cmsLocaleConfig = ECOM_CustomLoginController.fetchStorefrontConfigByModule(ECOM_Constant.PARAM_LOCALE_CONFIGURATION);

        String locale = '';

		System.debug('cmsLocaleConfig:: '+ JSON.serialize(cmsLocaleConfig));
        if( null != cmsLocaleConfig && cmsLocaleConfig.containsKey(UserInfo.getLocale())){
        	Map<String, Object> localeItem =  (Map<String, Object>) JSON.deserializeUntyped((String)cmsLocaleConfig.get(UserInfo.getLocale()));
            locale = (String)localeItem.get('cmsLocale');
        }

           return locale;
    }

    /**
     * @description This method returns required information for CMS redirection post login
     * @author abhishek.joshi@revvity.com | 2025.07.10 | RWPS-3651
     * @param bannerCodes | List<String>
     * @return cmsLocale | String
     */
    @AuraEnabled
    public static Map<String,String> getCountriesBannerMsgLoggedin(List<String> bannerCodes) {
        String userId =
            UserInfo.getUserId();
        User u =
            ECOM_UserRepo.getUserByUserId(
                userId
            );
        Boolean isPunchoutUser =
            u?.ECOM_Is_Punchout_User__c;

        String userType =
            'loggedin';
        if(
            isPunchoutUser) { userType = 'punchout'; }

        String country =
            u.CountryCode;
        return (
            ECOM_CustomMetadataRepo.getActiveNotificationBannerMsg(
                country,
                userType,
                bannerCodes
            )
        );
    }

    /**
     * @description This method fetches organization details for current user
     * @author Sachin V | 2025.12.28 | RWPS-5436
     * @return List<Organization>
     */
    @AuraEnabled(cacheable=true)
    public static List<Organization> getOrganizationDetails() {
        Id organizationId = UserInfo.getOrganizationId();
        List<Organization> organizationDetailsList = new List<Organization>();
        if (organizationId != null) {
            return ECOM_UserRepo.getOrganizationDetails(new List<String>{String.valueOf(organizationId)});
        } else {
            return organizationDetailsList;
        }
    }

    /**
     * @description This method fetches configuration values for test user
     * @author Sachin V | 2025.01.02 | RWPS-5436
     * @return Map<Object, Object>
     */
    @AuraEnabled(cacheable=true)
    public static Map<Object, Object> getTestUserConfigurations() {
        Map<Object, Object> testUserConfigurationsMap = new Map<Object, Object>();
        List<C_META_Storefront_Configuration__mdt> storeFrontConfigurations = ECOM_CustomMetadataRepo.fetchStoreConfigMdtBasedOnModuleName('ECOM_Special_Instructions_For_TestUser');
        storeFrontConfigurations.add(ECOM_CustomMetadataRepo.fetchStoreConfigMdtBasedOnModuleName('ECOM_Order_Email_IDs_For_TestUser')[0]);
        storeFrontConfigurations.add(ECOM_CustomMetadataRepo.fetchStoreConfigMdtBasedOnModuleName('ECOM_Order_PO_Number_For_TestUser')[0]);
        storeFrontConfigurations.add(ECOM_CustomMetadataRepo.fetchStoreConfigMdtBasedOnModuleName('ECOM_Attention_For_TestUser')[0]);
        testUserConfigurationsMap.put('specialInstructionsForTestUser', storeFrontConfigurations[0].Value__c);
        testUserConfigurationsMap.put('orderEmailIDsForTestUser', storeFrontConfigurations[1].Value__c);
        testUserConfigurationsMap.put('orderPONumberForTestUser', storeFrontConfigurations[2].Value__c);
        testUserConfigurationsMap.put('attentionForTestUser', storeFrontConfigurations[3].Value__c);
        return testUserConfigurationsMap;
    }
}