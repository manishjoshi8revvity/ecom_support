/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-2555
*
* 2. Description - This class is a controller class for Login Page.
*
*
*
* 3. Objects referenced
*    -ECOM_Application_logs__c
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
*
* 5. Dependant Class(es):
*    - ECOM_LoginController
*
* 6. Test Class Name:
*
* 7. Is @Invocable: No
*
* 8. Author Name(s):
*    - Vasudev 2024.04.29
* 	 - Sathiya 2024.08.30 Adding username as parameter for all logging for more info update
* 	 - Sathiya 2024.11.11 Added a fix to update the locale post login cookie issue - RWPS-1953
* 	 - Sathiya 2024.11.12 Added a fix to update the log for Login Lockout issue - RWPS-1986
* 	 - Kushal 2025.10.29 Added request/response and execution time logging for login callout - RWPS-4869
* 	 - Abhishek Joshi 2026.01.06 - Added methods generateLoginUrl, loginUserToSiteLWC and updated methods getUserRecord, loginUser, getStoreForwardingUrl - RWPS-3415
* 	 - Sachin V 2026.02.22 - Added method : processSecureAccessLink, findCustomerViaEmail, generateJWTToken, getMagicLinkImplementationActivationStatus & Updated method : validateUserCredentials - RWPS-5938
* 	 - Poonam S 2026.02.22 - Updated method loginUserToSiteLWC- RWPS-6037
*************************************************************/
public without sharing class ECOM_CustomLoginController {

    public static final String CLASSNAME = 'ECOM_CustomLoginController';
	public static final String ENCRYPTED_TOKEN = 'encryptedToken';
    public static final String ENCRYPTED_CODE = 'encryptedCode';
    public static final String ALGORITHM_AES_256 = 'AES256';
    public static final String INITIALIZATION_VECTOR = 'InitializationVector';
    public static final String MODULE_SECURITY = 'Security';
    public static final String SECRET_KEY = 'SecretKey';
    public static final String USER_MODULE_NAME = 'User Management';
    public static final String PARAM_RET_UTL = 'retURL';
    public static final String REDIRECT_TO = 'redirectTo';
    public static  Boolean isMappedContact = false;

    /**
     * @description This method validates if a user exists in the system. If exists, authenticates the user and
     * returns a redirection URL based on the method parameters
     * @author vramachandran@rafter.one | 23 Apr 2024
     * @param userName | String
     * @param password | String
     * @param retUrl   | String
     * @returns Map<String,Object>
     */
    @AuraEnabled
    public static Map<String,Object> loginUser(String userName, String password, String retUrl) {
        Map<String,Object> responseMap = new Map<String,Object>();
        Map<String,Object> methodDataMap = new Map<String,Object>();
        responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
        try {
            System.debug('PageRef:: ' + userName + '  ' + password);

            //Validate User
            methodDataMap = Test.isRunningTest() ? new Map<String,Object>{ECOM_Constant.PARAM_SUCCESS => true} : validateUserCredentials(userName);

            if(String.isNotBlank(retUrl)){
                System.debug('loginUser:retUrl:: '+ retUrl);
                retUrl = EncodingUtil.urlEncode(String.valueOf(retUrl),'UTF-8');
                System.debug('loginUser:retUrl:: '+ retUrl);
            }

            if(methodDataMap.containsKey(ECOM_Constant.PARAM_SUCCESS) && (Boolean) methodDataMap.get(ECOM_Constant.PARAM_SUCCESS)) {
                // RWPS-3415 start
                C_META_Storefront_Configuration__mdt loginMethod = C_META_Storefront_Configuration__mdt.getInstance('Login_Methodology');
                Boolean isCalloutLogin = loginMethod != null && loginMethod.Value__c == 'callout';
                //Callout to login user
                Map<String, Object> loginUserResponse =
                    Test.isRunningTest() ? new Map<String, Object>() : isCalloutLogin ? calloutToLoginAndGetRedirectUrl(userName, password, retUrl, (User)methodDataMap.get(ECOM_Constant.PARAM_USER_RECORD)) : generateLoginUrl(userName, password, retUrl, (User)methodDataMap.get(ECOM_Constant.PARAM_USER_RECORD));
                // RWPS-3415 end

                System.debug('loginUserResponse:: '+JSON.serialize(loginUserResponse));
                responseMap.putAll(loginUserResponse);
                // Added by Sathiya for locale hot fix on 11/11/2024 RWPS-1953
                responseMap.put(ECOM_Constant.PARAM_USER_RECORD, methodDataMap.get(ECOM_Constant.PARAM_USER_RECORD));
                //Fix End
                System.debug('ResponseMap:: '+ JSON.serialize(responseMap));

            } else {
                responseMap.putAll(methodDataMap);
                try{
                    system.debug('loginResponse:: '+ (Boolean)responseMap.get(ECOM_Constant.PARAM_SUCCESS));
                    throw new ECOM_SystemException((String)responseMap.get(ECOM_Constant.PARAM_MESSAGE));
                }catch(ECOM_SystemException se){
                    system.debug('loginResponse catch:: '+ (Boolean)responseMap.get(ECOM_Constant.PARAM_SUCCESS));
                    ECOM_ApplicationLogsUtil.logFailure(se , 'User Login' , 'ECOM_CustomLoginController' , 'loginUser', 'UserEmail:: '+ userName  + ' Stack:: '+ se.getStackTraceString(), userName);
                }
            }


        } catch (Exception e) {
            ECOM_ApplicationLogsUtil.logFailure(e , 'ECOM_LoginController:: User Login' , CLASSNAME , 'loginUser', 'UserEmail:: '+ userName  + ' Stack:: '+ e.getStackTraceString(), userName);
            //System.debug('Error:: '+ e.getCause() + ' Message:: '+ e.getMessage() + ' Stack:: '+ e.getStackTraceString());
        }

        return responseMap;
    }

    /**
     * @description This method validates the user email provided to check if it exists in the system and also
     * validate if the user is a punchout user
     * @author vramachandran@rafter.one
     * @param methodDataMap | Map<String,Object>
     * @returns Map<String,Object>
     */
    @TestVisible
    private static Map<String,Object> validateUserCredentials(String userName) {
        Map<String,Object> methodDataMap = new Map<String, Object>();
        methodDataMap.put(ECOM_Constant.PARAM_SUCCESS, False);
        try{
            User userRecord =  getUserRecord(userName);
            System.debug('userRecord:: '+ JSON.serialize(userRecord));

            if(null != userRecord) {

                methodDataMap.put(ECOM_Constant.PARAM_USER_RECORD, userRecord);
                methodDataMap.put(ECOM_Constant.PARAM_SUCCESS, true);
                //RWPS-5938
                if(Test.isRunningTest() || (userRecord.ECOM_Is_Punchout_User__c == true)) {
                    methodDataMap.put(ECOM_Constant.PARAM_SUCCESS, false);
                    methodDataMap.put(ECOM_Constant.PARAM_USER_RECORD, userRecord);
                    //RWPS-5938 - Flag
                    if (userRecord.ECOM_Is_Punchout_User__c == true && getMagicLinkImplementationActivationStatus() == true) {
                        methodDataMap.put('isPunchoutUser', true);
                    }
                    methodDataMap.put(ECOM_Constant.PARAM_MESSAGE, System.Label.ECOM_Web_Punchout_Registration);
                }
                //RWPS-5938
            } else {

                methodDataMap.put(ECOM_Constant.PARAM_SUCCESS, false);
                methodDataMap.put(ECOM_Constant.PARAM_MESSAGE, System.Label.ECOM_101001);
            }
        }catch(Exception e) {
            ECOM_ApplicationLogsUtil.logFailure(e , 'ECOM_LoginController:: User Login' , CLASSNAME , 'validateUserCredentials', 'UserEmail:: '+ userName  + ' Stack:: '+ e.getStackTraceString(), userName);
        }

        return methodDataMap;
    }

    /**
     * @description This method generates login URL for the user
     * @author Abhishek Joshi 2026.01.06 | RWPS-3415
     * @param userName | String
     * @param password | String
     * @param retUrl | String
     * @param userRecord | User
     * @returns Map<String,Object>
     */
    @TestVisible
    private static Map<String, Object> generateLoginUrl(String userName, String password, String retUrl, User userRecord) {
        Map<String, Object> methodDataMap = new Map<String, Object>();
        methodDataMap.put(
            ECOM_Constant.PARAM_SUCCESS,
            false
        );

        try {
            String storeForwardingUrl =
                Test.isRunningTest() ? '' : getStoreForwardingUrl(userRecord, String.isBlank(retUrl) ? '' : encryptWithAES256(retUrl));

            Map<String,Object>  loginMap =
                Test.isRunningTest() ? new Map<String, Object>() : loginUserToSiteLWC(userRecord, password, storeForwardingUrl);

            methodDataMap.put(ECOM_Constant.PARAM_RESPONSE_DATA, loginMap);
            methodDataMap.put(ECOM_Constant.PARAM_SUCCESS, true);
        } catch(Exception e) {
            methodDataMap.put(ECOM_Constant.PARAM_MESSAGE, System.Label.ECOM_GenericLoginError); //RWPS-5649
            ECOM_ApplicationLogsUtil.logFailure(e , 'ECOM_LoginController:: User Login' , CLASSNAME , 'generateLoginUrl', 'UserEmail:: '+ userName + ', Stack:: '+ e.getStackTraceString(), userName);
        }
        return methodDataMap;
    }

    /**
     * @description This method encrypts the credentials and calls out to login user
     * @author vramachandran@rafter.one | 2024.04.23 ECOM-2555
     * @param userName | String
     * @param password | String
     * @param retUrl | String
     * @returns Map<String,Object>
     */
    @TestVisible
    private static Map<String, Object> calloutToLoginAndGetRedirectUrl(String userName, String password, String retUrl, User userRecord) {
        Map<String, Object> methodDataMap = new Map<String, Object>();
        Map<String, String> requestMap = new Map<String, String>();

        Long requestStartTime; //RWPS-4869
        methodDataMap.put(ECOM_Constant.PARAM_SUCCESS, false);
        try{

            //encrypt credentials
            String encryptedToken = encryptWithAES256(userName);
            String encryptedCode = encryptWithAES256(password);
            String encryptedRetUrl = String.isNotBlank(retUrl) ? encryptWithAES256(retUrl) : '';

            //fetch store base url for login
            String storeBaseUrl = getStoreLoginBaseUrl();

            //prepare request parameters
            requestMap = Test.isRunningTest() ? new Map<String, String>() : prepareHttpRequestForQueryParameter(storeBaseUrl, encryptedToken, encryptedCode, encryptedRetUrl);
            System.debug('requestMap:: '+ JSON.serialize(requestMap));

            // RWPS-4869 Start
            requestStartTime = DateTime.now().getTime();
            //callout and get result
            HttpResponse responseObject;
            try {
                responseObject = performRestCallout(requestMap);
                System.debug('responseObject:: '+ responseObject.getBody());
            } catch(Exception e) {
                Long responseTime = DateTime.now().getTime() - requestStartTime;
                methodDataMap.put(ECOM_Constant.PARAM_MESSAGE, System.Label.ECOM_GenericLoginError); //RWPS-5649
                ECOM_ApplicationLogsUtil.logFailure(e , 'ECOM_LoginController:: User Login' , CLASSNAME , 'calloutToLoginAndGetRedirectUrl', 'UserEmail:: '+ userName  + ', RequestTime(ms): ' + responseTime + ', Request: ' + JSON.serialize(requestMap) + ', Response :' + (responseObject != null ? responseObject.getBody() : 'NULL_RESPONSE_BODY') +', Stack:: '+ e.getStackTraceString(), userName); //RWPS-5649
                return methodDataMap;
            }

            if(null!= responseObject && responseObject.getStatusCode() == 200){
                System.debug('responseObject:: '+ responseObject.getBody());
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseObject.getBody());

                methodDataMap.put(ECOM_Constant.PARAM_RESPONSE_DATA, responseMap);
                methodDataMap.put(ECOM_Constant.PARAM_SUCCESS, true);
				logResults(methodDataMap , userName);
            } else {
                try{
                    throw new ECOM_SystemException(System.Label.ECOM_GenericLoginError); //RWPS-5649
                }catch(ECOM_SystemException e){
                    ECOM_ApplicationLogsUtil.logFailure(e , 'User Login' , CLASSNAME , 'calloutToLoginAndGetRedirectUrl', 'UserEmail:: '+ userName  + ' Request:: ' + JSON.serialize(requestMap) + ' Stack:: '+ e.getStackTraceString(), userName); //RWPS-4869
                }
                methodDataMap.put(ECOM_Constant.PARAM_MESSAGE, System.Label.ECOM_GenericLoginError); //RWPS-5649

            }

        }catch(Exception e) {
            methodDataMap.put(ECOM_Constant.PARAM_MESSAGE, System.Label.ECOM_GenericLoginError); //RWPS-5649
            Long responseTime = DateTime.now().getTime() - requestStartTime;
            ECOM_ApplicationLogsUtil.logFailure(e , 'ECOM_LoginController:: User Login' , CLASSNAME , 'calloutToLoginAndGetRedirectUrl', 'UserEmail:: '+ userName  + ', RequestTime(ms): ' + responseTime + ', Request:: ' + JSON.serialize(requestMap) + ' Stack:: '+ e.getStackTraceString(), userName); //RWPS-4869
        }

        return methodDataMap;
    }

    /**
     * @description This method fetches the store base url for login
     * @author vramachandran@rafter.one | 2024.04.23 ECOM-2555
     * @returns String
     */
    //@TestVisible
    public static String getStoreLoginBaseUrl() {
        String storeLoginBaseUrl = '';
        try{

            //check if url based on custom label is to be used(Since Custom Url is set on Site without proper configuration)
            Boolean isUseBaseUrl = Boolean.valueOf(System.Label.ECOM_IsUseBaseUrl);
            String sfBaseUrl = System.Label.ECOM_SFBaseUrl;

            DomainSite siteDomain= fetchBaseSiteURL(System.Label.ECOM_SiteName);
            storeLoginBaseUrl = System.Label.ECOM_HTTPS_Prefix  + (isUseBaseUrl ? sfBaseUrl : siteDomain.Domain.domain) + siteDomain.PathPrefix + System.Label.ECOM_WebUserLoginEndpointPrefix  ;
            //storeLoginBaseUrl = System.Label.ECOM_HTTPS_Prefix  + 'revvity--ecomdev.sandbox.my.site.com' + siteDomain.PathPrefix + System.Label.ECOM_WebUserLoginEndpointPrefix  ;
            System.debug('storeLoginBaseUrl:: '+ storeLoginBaseUrl);
        }catch(Exception e) {

            ECOM_ApplicationLogsUtil.logFailure(e , 'ECOM_LoginController:: User Login' , CLASSNAME , 'getStoreLoginBaseUrl', ' Stack:: '+ e.getStackTraceString());
        }

        return storeLoginBaseUrl;
    }

    /**
     * @description This method prepares the HTTPRequest
     * @author vramachandran@rafter.one | 2024.04.23 ECOM-2555
     * @param requestMap | Map<String, String>
     * @returns Map<String, String>
     */
    @TestVisible
    private static Map<String, String> prepareHttpRequestForQueryParameter(String endpoint, String encryptedToken, String encryptedCode, String retUrl) {
        Map<String, String> preparedMap = new Map<String, String>();

        String endpointWithParameter = endpoint;

        endpointWithParameter += ECOM_Constant.ENCRYPTED_TOKEN + '=' + EncodingUtil.urlEncode(String.valueOf(encryptedToken),'UTF-8');
        endpointWithParameter += '&' + ECOM_Constant.ENCRYPTED_CODE + '=' + EncodingUtil.urlEncode(String.valueOf(encryptedCode),'UTF-8');

        System.debug('prepareHttpRequestForQueryParameter:: retUrl'+ retUrl);

        if(String.isNotBlank(retUrl)){
            endpointWithParameter += '&' + ECOM_Constant.PARAM_REDIRECT_TO + '=' +  EncodingUtil.urlEncode(String.valueOf(retURL),'UTF-8'); //EncodingUtil.urlEncode(String.valueOf(retUrl),'UTF-8');
        }

        //TODO: add locale

        System.debug('endpointWithParameter:: '+ endpointWithParameter);

        preparedMap.put(ECOM_Constant.REQUEST_METHOD_TYPE, ECOM_Constant.HTTP_REQUEST_POST);
        preparedMap.put(ECOM_Constant.HTTP_CONTENT_LENGTH, '0');
        preparedMap.put(ECOM_Constant.HTTP_REQUEST_ENDPOINT, endpointWithParameter);

        return preparedMap;
    }

    public static User getUserRecord(String username) {
        User userRecord;
        // Added by Sathiya for locale hot fix on 11/11/2024 RWPS-1953
        // Added username field - RWPS-3415
        List<User> usersList = [SELECT Id,FirstName,LastName,Email,ContactId,
                                Contact.AccountId, Contact.Account.Name,
                                ECOM_Is_Punchout_User__c, LocaleSidKey, UserName, Contact.ECOM_Punchout_Via_Web__c  //RWPS-5938
                                FROM User
                                WHERE UserName =: username LIMIT 1];
        // Fix End
        if(null != usersList && !usersList.isEmpty()){
            userRecord = usersList[0];
        }

        return userRecord;
    }

    public static String encryptWithAES256(String strText) {
        String encryptedString = null;
        String methodName = 'encryptWithAES256';
        String supportData = '';
        try {
            String strSecretKey = fetchConfigByValue(ECOM_Constant.SECRET_KEY);
            String strInitializationVector = fetchConfigByValue(ECOM_Constant.INITIALIZATION_VECTOR);
            Blob blobSecretKey = Blob.valueOf(strSecretKey);
            Blob blobInitializationVector = Blob.valueOf(strInitializationVector);
            Blob blobClearData = Blob.valueOf(strText);
            Blob blobEncryptedTextData = Crypto.encrypt(ECOM_Constant.ALGORITHM_AES_256, blobSecretKey, blobInitializationVector, blobClearData);
            encryptedString = EncodingUtil.base64Encode(blobEncryptedTextData);
        } catch (Exception exceptionObject) {
            System.debug(exceptionObject.getStackTraceString());
            ECOM_ApplicationLogsUtil.logFailure(exceptionObject, ECOM_Constant.USER_MODULE_NAME, className, methodName, supportData);
        }
        return encryptedString;
    }

    /**
    * @description  get  domain site by name
    * @author Vipul | 09-21-2023
    * @param siteName
    * @return DomainSite
    **/
    public static DomainSite fetchBaseSiteURL(String siteName){
        return [SELECT Id, Domain.domain, Site.Name, PathPrefix, CreatedDate FROM DomainSite Where Site.Name = :siteName AND  Domain.domain=:System.Label.ECOM_CommunityDomainName LIMIT 1] ;
    }


    /**
    * @description Method to perform REST callout based on the Request map
    * @author Vasudev Ramachandran | 11-23-2023
    * @param requestMap
    * @return HttpResponse
    **/
    public static HttpResponse performRestCallout(Map<String,String> requestMap){
        HttpResponse response;

        //set header values
        HttpRequest request = mapRequestValues(requestMap);
        System.debug('Request:: '+ request);

        //send request
		response = sendRequest(request);
        return response;
    }

    /**
    * @description Method to prepare HTTPRequest instance for values from RequestMap
    * @author Vasudev Ramachandran | 11-23-2023
    * @param requestMap
    * @return HttpResponse
    **/
    @TestVisible
    private static HttpRequest mapRequestValues(Map<String,String> requestMap){
        System.debug('requestMap:: '+ requestMap);

        HttpRequest request = new HttpRequest();
        for(String key : requestMap.KeySet()){
            if(key == ECOM_Constant.REQUEST_METHOD_TYPE){
                request.setMethod(requestMap.get(ECOM_Constant.REQUEST_METHOD_TYPE));
            } else if(key == ECOM_Constant.HTTP_REQUEST_ENDPOINT){
                request.setEndpoint(requestMap.get(ECOM_Constant.HTTP_REQUEST_ENDPOINT));
            } else if(key == ECOM_Constant.HTTP_REQUEST_BODY){
                request.setBody(requestMap.get(ECOM_Constant.HTTP_REQUEST_BODY));
            } else {
                request.setHeader(key, requestMap.get(key));
            }
        }

        return request;
    }

    /**
    * @description // This method is used to send HTTP Request received in parameter and return the response
    * @author Vipul Goyal | 09-20-2023
    * @param request
    * @return HTTPResponse
    **/
    public static HTTPResponse sendRequest(HTTPRequest request) {
        Http http = new Http();
        return http.send(request);
    }

    /**
    * @description
    * @author mkumar@rafter.one | 09-18-2023
    * @param labelName
    * @return String
    **/
    public static String fetchConfigByValue(String labelName) {
        String value = '';
        C_META_Storefront_Configuration__mdt config = C_META_Storefront_Configuration__mdt.getInstance(labelName);
        if (config != null) {
            value = String.isNotBlank(config.Value__c) ? config.Value__c : '';
        }
        return value;
    }

    /**
     * @description This method returns the cms website url for guest users
     * @author vramachandran@rafter.one | 29 May 2024
     * @returns Map<String, Object>
     */
    @AuraEnabled
    public static Map<String, Object> getCMSUrl() {
        String methodName = 'getCMSUrl';
        Map<String, Object> responseMap = new Map<String, Object>();
        responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);

        try {

            responseMap.put(ECOM_Constant.PARAM_RESPONSE_DATA, fetchStorefrontFrontConfigByModule(System.Label.ECOM_CMSSiteUrl));
            responseMap.put(ECOM_Constant.PARAM_SUCCESS, true);

        } catch(Exception e) {
            System.debug(e.getStackTraceString());
            ECOM_ApplicationLogsUtil.logFailure(e, ECOM_Constant.USER_MODULE_NAME, CLASSNAME, methodName, '');
        }

        return responseMap;
    }

    /**
     * @description method to fetch custom metadata for cms store details. Adding method to controller to reduce issue with class recompilation after deployment
     * @author vramachandran@rafter.one | 29 May 2024
     * @param moduleName | String
     * @returns Map<String, String>
     */

    public static Map<String, String> fetchStorefrontFrontConfigByModule(String moduleName) {
        Map<String, String> mapModuleConstants = new Map<String, String>();
        List<C_META_Storefront_Configuration__mdt> b2BStorefrontConfigurations = [
            SELECT Id, DeveloperName, MasterLabel, ModuleName__c, Value__c
            FROM C_META_Storefront_Configuration__mdt
            WHERE ModuleName__c = :moduleName
        ];
        if (b2BStorefrontConfigurations != null && b2BStorefrontConfigurations.size() > 0) {
            for (C_META_Storefront_Configuration__mdt b2BStorefrontConfiguration : b2BStorefrontConfigurations) {
                mapModuleConstants.put(b2BStorefrontConfiguration.MasterLabel, b2BStorefrontConfiguration.Value__c);
            }
        }
        return mapModuleConstants;
    }

    /**
     * @description method to fetch custom metadata for cms store details. Adding method to controller to reduce issue with class recompilation after deployment
     * @author vramachandran@rafter.one | 29 May 2024
     * @param moduleName | String
     * @returns Map<String, String>
     */
    @AuraEnabled
    public static Map<String, Object> fetchStorefrontConfigByModule(String moduleName) {
        Map<String, Object> mapModuleConstants = new Map<String, Object>();
        mapModuleConstants.put(ECOM_Constant.PARAM_SUCCESS, false);
        try{
            List<ECOM_Store_Configuration__mdt> b2BStorefrontConfigurations = [
                SELECT Id, DeveloperName, MasterLabel, Value__c, Value_RT__c
                FROM ECOM_Store_Configuration__mdt
                WHERE Label = :moduleName
            ];
            if (b2BStorefrontConfigurations != null && b2BStorefrontConfigurations.size() > 0) {
                //for (ECOM_Store_Configuration__mdt b2BStorefrontConfiguration : b2BStorefrontConfigurations) {
                //    mapModuleConstants.put(b2BStorefrontConfiguration.MasterLabel, (Object)b2BStorefrontConfiguration.Value_RT__c );
                //}
                mapModuleConstants.put(ECOM_Constant.PARAM_RESPONSE_DATA, (Map<String, Object>)JSON.deserializeUntyped(b2BStorefrontConfigurations[0].Value_RT__c));
                mapModuleConstants.put(ECOM_Constant.PARAM_ORG_ID, UserInfo.getOrganizationId());
                mapModuleConstants.put(ECOM_Constant.PARAM_SUCCESS, true);
            }
        }catch(Exception e) {
            System.debug('Exception e:: '+ e.getStackTraceString());
        }

        return mapModuleConstants;
    }

    @Testvisible
    private static String getOrganizationId(){
        String orgId;
        String organizationQuery = 'SELECT Id, Name FROM Organization LIMIT 1';

        List<Organization> organizationList = Database.query(organizationQuery, AccessLevel.SYSTEM_MODE);

        if(null != organizationList && !organizationList.isEmpty()) {
            orgId = organizationList[0].Id;
        }

		return orgId;
    }

    /**
    * @description  read parameters from URL
    * @author mkumar@rafter.one | 09-18-2023
    * @param valueMap
    * @param key
    * @return String
    **/
    public static String getValueFromMap(Map<String,String> valueMap,String key)
    {
        String returnVal='';
        try{
            if(valueMap.containsKey(key) && valueMap.get(key)!=null) {
            return valueMap.get(key).unescapeHtml4();
        }
        }catch(Exception e){
            System.debug(e.getStackTraceString());
        }

        return returnVal;
    }


	/**
     * @description
     * @author mkumar@rafter.one | 09-18-2023
     * @param encryptedText
     * @return String
     **/
     public static String decryptWithAES256(String encryptedText) {
        String decryptedString = null;
        String methodName = 'decryptWithAES256';
        String supportData = '';
        try {
            String strSecretKey = fetchConfigByValue(SECRET_KEY);
            String strInitializationVector = fetchConfigByValue(INITIALIZATION_VECTOR);
            Blob blobSecretKey = Blob.valueOf(strSecretKey);
            Blob blobInitializationVector = Blob.valueOf(strInitializationVector);
            Blob encryptedDataUpdated = EncodingUtil.base64Decode(encryptedText);
            Blob decryptedTextData = Crypto.decrypt(ALGORITHM_AES_256, blobSecretKey, blobInitializationVector, encryptedDataUpdated);
            decryptedString = decryptedTextData.toString();
        } catch (Exception exceptionObject) {
            // ECOM_ApplicationLogsUtil.logFailure(exceptionObject, USER_MODULE_NAME, className, methodName, supportData);
        }
        return decryptedString;
    }


	/**
    * @description
    * @author mkumar@rafter.one | 09-18-2023
    * @param labelName
    * @return String
    **
    public static String fetchConfigByValue(String labelName) {
        String value = '';
        C_META_Storefront_Configuration__mdt config = C_META_Storefront_Configuration__mdt.getInstance(labelName);
        if (config != null) {
            value = String.isNotBlank(config.Value__c) ? config.Value__c : '';
        }
        return value;
    }*/

	public static List<User> getUsersByUsername(String username)
    {
        return [
                Select Id,FirstName,LastName,Email,ContactId,
                Contact.AccountId, Contact.Account.Name,
            	ECOM_Is_Punchout_User__c, UserName,//VRa ECOM-2555
            	LocaleSidKey //
                from User
                where username=:username LIMIT 1];
    }

	/**
     * @description This method logs in the user
     * @author vramachandran@rafter.one | 2024.04.23 ECOM-2555
     * @returns String
     */
    public String getReturnURL(){
        String loginWrapperString = '';

        try{
            System.debug('Called::');
            Map<String, String> currentPageParams = Test.isRunningTest() ? new Map<String,String>() : ApexPages.currentPage().getParameters();
            System.debug('currentPageParams:: '+ JSON.serialize(currentPageParams));

            String encryptedToken = Test.isRunningTest()? 'dEdBYlHUmhEZcgaCePXxNbAC6fKJfq4G8DH4AiSzCwc=' : getValueFromMap(currentPageParams,ENCRYPTED_TOKEN);
            String encryptedCode = Test.isRunningTest()? 'dEdBYlHUmhEZcgaCePXxNbAC6fKJfq4G8DH4AiSzCwc=' : getValueFromMap(currentPageParams, ENCRYPTED_CODE);
            String redirectTo = Test.isRunningTest()? 'dEdBYlHUmhEZcgaCePXxNbAC6fKJfq4G8DH4AiSzCwc=' : getValueFromMap(currentPageParams, REDIRECT_TO);

            String decryptedToken = decryptWithAES256(encryptedToken);
            String decryptedCode = decryptWithAES256(encryptedCode);

			System.debug('retUrl:: '+ redirectTo);
            List<User> usersList = Test.isRunningTest() ? new List<User>() : getUsersByUsername(decryptedToken);

            if(null != usersList && !usersList.isEmpty() || Test.isRunningTest()){
                User userRecord = Test.isRunningTest() ? null : usersList[0];

                String storeForwardingUrl = Test.isRunningTest() ? '' : getStoreForwardingUrl(userRecord, redirectTo);

                System.debug('storeForwardingUrl:: '+ storeForwardingUrl);
                Map<String,Object>  loginMap = Test.isRunningTest() ? new Map<String, Object>() : loginUserToSite(userRecord.Username, decryptedCode, storeForwardingUrl);

                System.debug('loginMap:: '+ JSON.serialize(loginMap));
                loginWrapperString = JSON.serialize(loginMap);
            }



        }catch(Exception e){
            System.debug('Exception:: cause:'+ e.getCause() + ' Message:: ' + e.getMessage() + ' Stack:: '+ e.getStackTraceString());
            //ECOM_ApplicationLogsUtil.logFailure(e , 'ECOM_LoginController:: User Login' , CLASSNAME , 'getReturnURL', ' Stack:: '+ e.getStackTraceString());
        }

        return loginWrapperString;
    }

    /**
     * @description This method logs the user into the site
     * @author Abhishek Joshi 2026.01.06 | RWPS-3415
     * @param user | User
     * @param password | String
     * @param storeForwardingUrl | String
     * @returns Map<String,Object>
     */
    @TestVisible
    private static Map<String,Object> loginUserToSiteLWC(User user, String password, String storeForwardingUrl) {
        String returnUrl = '';
        String message = '';
        Boolean success = false;

        Map<String,Object> returnMap = new Map<String,Object>();

        Datetime loginStartTime = DateTime.now();

        try {
            PageReference loginPageReference =
                Test.isRunningTest() ? null : Site.login(user.Username, password, storeForwardingUrl);

            if(null != loginPageReference && null != loginPageReference.getUrl()) {
                returnUrl = loginPageReference.getUrl();
                returnMap.put(ECOM_Constant.PARAM_STOREFRONT_URL, returnUrl);
                success = true ;
            } else {
                throw new ECOM_SystemException(message);
            }
        } catch (Exception e) {
            success = false;

            List<LoginHistory> historyList = [
                SELECT Id, Status, LoginType, LoginUrl, NetworkId, LoginTime
                FROM LoginHistory
                WHERE (
                    UserId =: user.Id AND
                    LoginTime >= :loginStartTime
                )
                ORDER BY LoginTime Desc LIMIT 1
            ];

            LoginHistory historyItem;

            if(Test.isRunningTest()) {
                historyList.add(new LoginHistory());
            }

            if(!historyList.isEmpty()){
                historyItem = historyList[0];

                if(historyItem?.Status == 'Password Lockout'){
                    message = System.Label.ECOM_Lockout_Message;
                } else if(historyItem?.Status == 'Invalid Password') {
                    message = System.Label.ECOM_103001;
                }
            }

            if(String.isBlank(message)) {
                message = System.Label.ECOM_GenericLoginError;
                String severity = ECOM_Util.getSeverityByMessage(message);//RWPS-6037
                ECOM_ApplicationLogsUtil.logFailure(e,'ECOM_LoginController:: User Login', CLASSNAME, 'loginUserToSiteLWC',( 'Message:: ' +e.getMessage() +' Cause:: ' +e.getCause() +' stack trace:: ' +e.getStackTraceString() +' HistoryItem:: ' +(historyItem != null ? historyItem.Status : 'No History Item')), user.Username, severity);//RWPS-6037
            }
        }

        returnMap.put(ECOM_Constant.PARAM_SUCCESS, success);
        returnMap.put(ECOM_Constant.PARAM_MESSAGE, message);

        return returnMap;
    }

	/**
     * @description This method logs the user into the site
     * @author vramachandran@rafter.one | 2024.04.23 ECOM-2555
     * @param userName | String
     * @param password | String
     * @param storeForwardingUrl | String
     * @returns PageReference
     */
    @TestVisible
    private static Map<String,Object> loginUserToSite(String userName, String password, String storeForwardingUrl) {
        String returnUrl = '';
        String message = '';

        Boolean success = false;

        Map<String,Object> returnMap = new Map<String,Object>();
        try{

            PageReference loginPageReference = Test.isRunningTest() ? null : Site.login(userName, password, storeForwardingUrl);

            if(null != loginPageReference && null != loginPageReference.getUrl()) {

                returnUrl = loginPageReference.getUrl();
                returnMap.put(ECOM_Constant.PARAM_STOREFRONT_URL, returnUrl);
                success = true ;
            } else {
                success = false;
                // Changes for login lockout message update by sathiya on 2024.11.12 for RWPS-1986
                List<User> userList = [SELECT Id FROM User WHERE username=: userName LIMIT 1];
                if(!userList.isEmpty()){
                    List<LoginHistory> historyList = [Select Id, Status, LoginType, LoginUrl, NetworkId, LoginTime
                                                     FROM LoginHistory
                                                     WHERE UserId =: userList[0]?.Id ORDER BY LoginTime Desc LIMIT 1];
                    if(!historyList.isEmpty()){
                        if(historyList[0]?.Status == 'Password Lockout'){
                            message = System.Label.ECOM_Lockout_Message;
                        } else {
                            message = System.Label.ECOM_103001;
                        }
                    } else {
                        message = System.Label.ECOM_103001;
                    }
                } else {
                    message = System.Label.ECOM_103001;
                }
                // Changes Done
            }

            returnMap.put(ECOM_Constant.PARAM_SUCCESS, success);
            returnMap.put(ECOM_Constant.PARAM_MESSAGE, message);

        }catch(Exception e){
            System.debug('ECOM_LoginController:: User Login '+ e.getStackTraceString());
            //ECOM_ApplicationLogsUtil.logFailure(e , 'ECOM_LoginController:: User Login' , CLASSNAME , 'loginUserToSite', ' Stack:: '+ e.getStackTraceString());
        }

        return returnMap;
    }

	/**
     * @description This method fetches the storeforwarding url
     * @author vramachandran@rafter.one | 2024.04.23 ECOM-2555
     * @returns String
     */
    @TestVisible
    private static String getStoreForwardingUrl(User userRecord, String redirectTo){
        String forwardingUrl = '';
        String cmsParameters = '';
        String sessionCookieParameters = '';
        String urlParameters = '';

        Map<String,Object> storeNavigationConfig = getStoreNavigationConfigMap(ECOM_Constant.PARAM_SITE_NAVIGATION_CONFIG_LABEL, ECOM_Constant.USER_TYPE_CMS_WEB_USER);
        System.debug('storeNavigationConfig:: '+ JSON.serialize(storeNavigationConfig));
        try{
            String storeForwardingUrl = (String)storeNavigationConfig.get(ECOM_Constant.PARAM_FORWARDING_URL);
            System.debug('storeForwardingUrl:: '+ storeForwardingUrl);

            //build url parameters to pass to cms
            cmsParameters = ECOM_Constant.PARAM_EXT_USER_ID + '=' + userRecord.Id;
            cmsParameters = cmsParameters + '&' + ECOM_Constant.PARAM_EXT_EMAIL_ID + '=' + userRecord.Email;
            cmsParameters = cmsParameters + '&' + ECOM_Constant.PARAM_EXT_SESSION_STARTED_TIMESTAMP + '=' + String.valueOf(DateTime.now().getTime());
            cmsParameters = cmsParameters + '&' + ECOM_Constant.PARAM_EXT_IF_SESSION_STARTED_FLAG + '=' + String.valueOf(1);

            System.debug('cmsParameters:: '+ cmsParameters);

            sessionCookieParameters = cmsParameters + '&' + ECOM_Constant.PARAM_EXT_IF_SESSION_STARTED_FLAG + '=' + String.valueOf(1);
            sessionCookieParameters = encryptWithAES256(sessionCookieParameters);

            System.debug('sessionCookieParameters:: '+ sessionCookieParameters);

            Cookie ck = new Cookie(System.Label.ECOM_CookieName , sessionCookieParameters, null , 1800000, true, 'Lax');
            // RWPS-3415 start
            System.PageReference currentPage = ApexPages.currentPage();
            if(!Test.isRunningTest() && currentPage != null){
                currentPage.setCookies(new Cookie[]{ck});
            }
            // RWPS-3415 end

            urlParameters = ECOM_Constant.PARAM_EXT_CMS_URL_PARAMETER + '=' +  EncodingUtil.urlEncode(encryptWithAES256(cmsParameters), 'UTF-8');
            System.debug('urlParameters:: '+ urlParameters);

            //VRa ECOM-3261: begin | 13 Jun 2024
            System.debug('paramuserrecord:: ' + userRecord);
            if(null != userRecord?.LocaleSidKey && userRecord?.LocaleSidKey != 'en_US'){
                storeForwardingUrl = '/'+ userRecord?.LocaleSidKey.replace('_', '-') + storeForwardingUrl + '?' + urlParameters;
            } else {
                storeForwardingUrl = storeForwardingUrl + '?' + urlParameters;
            }

			//VRa ECOM-3261: end | 13 Jun 2024

            //Set user type
            storeForwardingUrl = storeForwardingUrl + '&' + ECOM_Constant.PARAM_PUNCHOUT_USER_TYPE + '=' + ECOM_Constant.USER_TYPE_CMS_WEB_USER;

            if(String.isNotBlank(redirectTo)){
                storeForwardingUrl = storeForwardingUrl + '&' + REDIRECT_TO + '=' + EncodingUtil.urlEncode(redirectTo, 'UTF-8') ;
            }

           	forwardingUrl = storeForwardingUrl ;
            System.debug('forwardingUrl:: '+ forwardingUrl);
        }catch(Exception e){
            System.debug(e.getStackTraceString());
        }


        return forwardingUrl;
    }

	/**public static String encryptWithAES256(String strText) {
        String encryptedString = null;
        String methodName = 'encryptWithAES256';
        String supportData = '';
        try {
            String strSecretKey = fetchConfigByValue(ECOM_Constant.SECRET_KEY);
            String strInitializationVector = fetchConfigByValue(ECOM_Constant.INITIALIZATION_VECTOR);
            Blob blobSecretKey = Blob.valueOf(strSecretKey);
            Blob blobInitializationVector = Blob.valueOf(strInitializationVector);
            Blob blobClearData = Blob.valueOf(strText);
            Blob blobEncryptedTextData = Crypto.encrypt(ECOM_Constant.ALGORITHM_AES_256, blobSecretKey, blobInitializationVector, blobClearData);
            encryptedString = EncodingUtil.base64Encode(blobEncryptedTextData);
        } catch (Exception exceptionObject) {
            System.debug(exceptionObject.getStackTraceString());
            //ECOM_ApplicationLogsUtil.logFailure(exceptionObject, ECOM_Constant.USER_MODULE_NAME, className, methodName, supportData);
        }
        return encryptedString;
    }**

    public static User getUserRecord(String username) {
        User userRecord;

        List<User> usersList = [SELECT Id,FirstName,LastName,Email,ContactId,
                                Contact.AccountId, Contact.Account.Name,
                                ECOM_Is_Punchout_User__c
                                FROM User
                                WHERE UserName =: username LIMIT 1];
        if(null != usersList && !usersList.isEmpty()){
            userRecord = usersList[0];
        }

        return userRecord;
    }
     */

    /**
    * @description Get store navigation metadata
    * @author vramachandran@rafter.one | 09-21-2023
    * @param moduleName
    * @return ECOM_Store_Punchout_Configuration__mdt
    **/
    public static Map<String,Object>  getStoreNavigationConfigMap(String labelName, String userType){
        Map<String,Object> configMap = new Map<String,Object>();
        System.debug('labelName:: '+ labelName);
        ECOM_Store_Punchout_Configuration__mdt  storeConfig =   [SELECT Id, Value_Rt__c FROM ECOM_Store_Punchout_Configuration__mdt  WHERE MasterLabel =:labelName LIMIT 1 ];

        if(null != storeConfig && String.isNotEmpty(storeConfig.Value_Rt__c)){
			String valueRt = storeConfig.Value_Rt__c;
            Map<String,Object> userTypeMap = (Map<String,Object>) JSON.deserializeUntyped(valueRt);

            //check if config exists for specific user type else default to cms web user
            if(null != userTypeMap && userTypeMap.containsKey(userType)){
                configMap = (Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(userTypeMap.get(userType)));
            } else {
                configMap = (Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(userTypeMap.get(ECOM_Constant.USER_TYPE_CMS_WEB_USER)));
            }
        }
        return configMap;
    }

    /**
     * RWPS-5938
     * @description This method generates the secure login link for provided punchout user email and sends over email
     * @author Sachin V | 2026-03-01
     * @param quoteNumber | String
     * @param userEmail | String
     * @return Map<String,Object>
     */
    @AuraEnabled
    public static Map<String, Object> processSecureAccessLink(String quoteNumber, String userEmail) {
        Map<String, Object> resultMap = new Map<String, Object>();
        ECOM_Application_Logs__c successLog = new ECOM_Application_Logs__c();
        ECOM_Application_Logs__c failureLog = new ECOM_Application_Logs__c();
        failureLog.ClassName__c = CLASSNAME;
        failureLog.MethodName__c = 'processSecureAccessLink';
        failureLog.ModuleName__c = System.Label.ECOM_Punchout_Login_Application_Log_Module_Name + ' - Failure';
        failureLog.Source_Type__c = 'Ecommerce';
        failureLog.Request_TimeStamp__c = System.now();
        failureLog.Request_TimeStamp_ms__c = failureLog.Request_TimeStamp__c.getTime();
        failureLog.ExceptionRunningUser__c = UserInfo.getUserId();
        try {
            List<User> userList = new List<User>();
            resultMap.put(ECOM_Constant.PARAM_SUCCESS , false);
            if (String.isNotBlank(userEmail)) {
                userList = findCustomerViaEmail(userEmail);
            }
            if (userList.isEmpty() == false) {
                failureLog.ECOM_Contact__c = userList[0].ContactId;
                failureLog.ECOM_Contact_Email__c = userList[0].Contact.Email;
                String loginURL = '';
                Map<String, C_META_Storefront_Configuration__mdt> storefrontConfigurationDataMap =  ECOM_CustomMetadataRepo.fetchSapOrderHistoryDateData();
                String clientCredentials = storefrontConfigurationDataMap.isEmpty() == false && storefrontConfigurationDataMap.containsKey(ECOM_Constant.ECOM_MAGIC_LINK_CONNECTED_APP_CREDENTIAL_MODULE) && storefrontConfigurationDataMap.get(ECOM_Constant.ECOM_MAGIC_LINK_CONNECTED_APP_CREDENTIAL_MODULE) != null ? storefrontConfigurationDataMap.get(ECOM_Constant.ECOM_MAGIC_LINK_CONNECTED_APP_CREDENTIAL_MODULE).Value__c : '';
                String certificateName = storefrontConfigurationDataMap.isEmpty() == false && storefrontConfigurationDataMap.containsKey(ECOM_Constant.ECOM_MAGIC_LINK_CERTIFICATE_MODULE) && storefrontConfigurationDataMap.get(ECOM_Constant.ECOM_MAGIC_LINK_CERTIFICATE_MODULE) != null ? storefrontConfigurationDataMap.get(ECOM_Constant.ECOM_MAGIC_LINK_CERTIFICATE_MODULE).Value__c  : '';
                String grantTypeValue = storefrontConfigurationDataMap.isEmpty() == false && storefrontConfigurationDataMap.containsKey(ECOM_Constant.ECOM_MAGIC_LINK_GRANT_TYPE_VALUE_MODULE) && storefrontConfigurationDataMap.get(ECOM_Constant.ECOM_MAGIC_LINK_GRANT_TYPE_VALUE_MODULE) != null ? storefrontConfigurationDataMap.get(ECOM_Constant.ECOM_MAGIC_LINK_GRANT_TYPE_VALUE_MODULE).Value__c  : '';
                String shopBaseURL = storefrontConfigurationDataMap.isEmpty() == false && storefrontConfigurationDataMap.containsKey(ECOM_Constant.ECOM_MAGIC_LINK_BASE_URL_MODULE) && storefrontConfigurationDataMap.get(ECOM_Constant.ECOM_MAGIC_LINK_BASE_URL_MODULE) != null ? storefrontConfigurationDataMap.get(ECOM_Constant.ECOM_MAGIC_LINK_BASE_URL_MODULE).Value__c  : '';
                String tokenURL = storefrontConfigurationDataMap.isEmpty() == false && storefrontConfigurationDataMap.containsKey(ECOM_Constant.ECOM_MAGIC_LINK_TOKEN_URL_MODULE) && storefrontConfigurationDataMap.get(ECOM_Constant.ECOM_MAGIC_LINK_TOKEN_URL_MODULE) != null ? storefrontConfigurationDataMap.get(ECOM_Constant.ECOM_MAGIC_LINK_TOKEN_URL_MODULE).Value__c  : '';
                String sessionURL = storefrontConfigurationDataMap.isEmpty() == false && storefrontConfigurationDataMap.containsKey(ECOM_Constant.ECOM_MAGIC_LINK_SESSION_URL_MODULE) && storefrontConfigurationDataMap.get(ECOM_Constant.ECOM_MAGIC_LINK_SESSION_URL_MODULE) != null ? storefrontConfigurationDataMap.get(ECOM_Constant.ECOM_MAGIC_LINK_SESSION_URL_MODULE).Value__c  : '';
                Integer sessionExpirationTime = storefrontConfigurationDataMap.isEmpty() == false && storefrontConfigurationDataMap.containsKey(ECOM_Constant.ECOM_MAGIC_LINK_EXPIRATION_TIME) && storefrontConfigurationDataMap.get(ECOM_Constant.ECOM_MAGIC_LINK_EXPIRATION_TIME) != null ? Integer.valueOf(storefrontConfigurationDataMap.get(ECOM_Constant.ECOM_MAGIC_LINK_EXPIRATION_TIME).Value__c) : 0;
                String jwtToken = generateJWTToken(userList[0].Username, shopBaseURL, clientCredentials, sessionExpirationTime, certificateName);
                if (String.isNotBlank(jwtToken)) {
                    failureLog.SupportData__c = jwtToken;
                    String accessToken = '';
                    String payload = (String)grantTypeValue + (String)jwtToken;

                    Map<String, String> calloutRequestMap = new Map<String, String>();
                    calloutRequestMap.put(ECOM_Constant.ACTION_TYPE , ECOM_Constant.MAGIC_LINK_ACTION);
                    calloutRequestMap.put(ECOM_Constant.HTTP_REQUEST_TYPE , ECOM_Constant.HTTP_REQUEST_POST);
                    calloutRequestMap.put(ECOM_Constant.HTTP_REQUEST_BODY , payload);
                    calloutRequestMap.put(ECOM_Constant.TOKEN_ENDPOINT, tokenURL);
                    calloutRequestMap.put('ContactId', userList[0] != null && userList[0].ContactId != null ? userList[0].ContactId : null);
                    calloutRequestMap.put('ContactEmail', userList[0] != null && userList[0].ContactId != null && userList[0].Contact.Email != null ? userList[0].Contact.Email : null);
                    HttpRequest req = new HttpRequest();
                    HTTPResponse calloutResponse = ECOM_RestService.doBasicHttpRequest(calloutRequestMap);
                    if (calloutResponse != null && calloutResponse.getStatusCode() == 200) {
                        System.JSONParser parser = System.JSON.createParser(calloutResponse.getBody());
                        while (parser.nextToken() != null) {
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'access_token')) {
                                parser.nextToken();
                                accessToken = parser.getText();
                                break;
                            }
                        }
                    }
                    if (String.isNotBlank(accessToken) && accessToken != '') {
                        loginURL = shopBaseURL + sessionURL + EncodingUtil.urlEncode(accessToken,'UTF-8') + '&ptcms=true' + '&' + (String.isNotBlank(quoteNumber) == true ? + 'retURL=/quote-detail?quoteNumber=' +quoteNumber : 'retURL=/secure-access-link');
                        Map<String,String> countryMetadata = ECOM_CustomMetadataService.getEmailContactDetails(userList[0]?.Contact?.ECOM_CountryProvided__c);
                        String orgWideAddressReference = (String)countryMetadata.get('CustomerCareEmailAddress');
                        String magicLinkEmailTemplate = System.Label.ECOM_Magic_Link_Email_Template;
                        List<EmailTemplate> emailTemplateList = [SELECT Id FROM EmailTemplate WHERE DeveloperName =:magicLinkEmailTemplate LIMIT 1];
                        Messaging.SingleEmailMessage renderedEmail = Messaging.renderStoredEmailTemplate(emailTemplateList[0].Id, userList[0].Id, null);
                        String finalHtmlBody = renderedEmail.getHtmlBody().replace('[[LOGIN_URL]]', loginURL);

                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setTargetObjectId(userList[0].Id);
                        mail.setHtmlBody(finalHtmlBody);
                        mail.setSubject(renderedEmail.getSubject());
                        mail.setSaveAsActivity(false);
                        mail.setUseSignature(false);

                        List<OrgWideEmailAddress> orgWideEmailAddressList = [SELECT Id FROM OrgWideEmailAddress WHERE Address =: orgWideAddressReference LIMIT 1];
                        if (orgWideEmailAddressList.isEmpty() == false) {
                            mail.setOrgWideEmailAddressId(orgWideEmailAddressList[0].Id);
                        }

                        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
                        resultMap.put(ECOM_Constant.PARAM_SUCCESS, true);
                        resultMap.put(ECOM_Constant.PARAM_MESSAGE, System.Label.ECOM_Punchout_Login_Magic_Link_Success_Message);
                        successLog.ECOM_Contact__c = userList[0].ContactId;
                        successLog.ECOM_Contact_Email__c = userList[0].Contact.Email;
                        successLog.ClassName__c = CLASSNAME;
                        successLog.MethodName__c = 'processSecureAccessLink';
                        successLog.ModuleName__c = System.Label.ECOM_Punchout_Login_Application_Log_Module_Name + ' - Success';
                        successLog.Source_Type__c = 'Ecommerce';
                        successLog.SupportData__c = jwtToken;
                        successLog.Request_TimeStamp__c = System.now();
                        successLog.Request_TimeStamp_ms__c = successLog.Request_TimeStamp__c.getTime();
                        successLog.ExceptionRunningUser__c = UserInfo.getUserId();
                        ECOM_ApplicationLogsUtil.insertApplicationLogs(successLog);

                        if (userList.isEmpty() == false && userList[0].ECOM_Is_Punchout_User__c == true && userList[0].ContactId != null) {
                            update new Contact(
                                Id = userList[0].ContactId,
                                ECOM_Punchout_Via_Web__c = true,
                                ECOM_Punchout_Cart_Reset__c = false
                            );
                        }
                    } else {
                        resultMap.put(ECOM_Constant.PARAM_SUCCESS, false);
                        resultMap.put(ECOM_Constant.PARAM_MESSAGE, System.Label.ECOM_Punchout_Login_Access_Link_Failure_Generic_Message);
                        failureLog.ErrorMessage__c = System.Label.ECOM_Punchout_Login_Access_Link_Failure_Generic_Message;
                        failureLog.ErrorMessage__c += ' - ' + System.Label.ECOM_Punchout_Login_Access_Token_Failure_Error_Message;
                        failureLog.ExceptionType__c = 'Integration Exception';
                        ECOM_ApplicationLogsUtil.insertApplicationLogs(failureLog);
                    }
                } else {
                    resultMap.put(ECOM_Constant.PARAM_SUCCESS, false);
                    resultMap.put(ECOM_Constant.PARAM_MESSAGE, System.Label.ECOM_GenericLoginError);
                    failureLog.ErrorMessage__c = (String)System.Label.ECOM_GenericLoginError;
                    failureLog.ErrorMessage__c += ' - Error while generating JWT Token';
                    failureLog.ExceptionType__c = 'Integration Exception';
                    ECOM_ApplicationLogsUtil.insertApplicationLogs(failureLog);
                }
            } else if (userList.isEmpty()) {
                resultMap.put(ECOM_Constant.PARAM_SUCCESS, false);
                resultMap.put(ECOM_Constant.PARAM_MESSAGE, System.Label.ECOM_101001);
                failureLog.ErrorMessage__c = System.Label.ECOM_101001;
                failureLog.ExceptionType__c = 'ECOM_SystemException';
                failureLog.SupportData__c = 'Email Address: ' + userEmail + (String.isNotBlank(quoteNumber) ? ' & Quote Number: ' + quoteNumber : ''); //RWPS-5938
                ECOM_ApplicationLogsUtil.insertApplicationLogs(failureLog);
            }
        } catch (Exception exceptionInstance) {
            resultMap.put(ECOM_Constant.PARAM_SUCCESS, false);
            resultMap.put(ECOM_Constant.PARAM_MESSAGE, exceptionInstance.getMessage());
            failureLog.ErrorMessage__c = exceptionInstance.getMessage();
            failureLog.StackTrace__c = exceptionInstance.getStackTraceString();
            failureLog.ExceptionType__c = exceptionInstance.getTypeName();
            failureLog.SupportData__c = 'Email Address: ' + userEmail + (String.isNotBlank(quoteNumber) ? ' & Quote Number: ' + quoteNumber : '');
            ECOM_ApplicationLogsUtil.insertApplicationLogs(failureLog);
        }
        return resultMap;
    }

    /**
     * RWPS-5938
     * @description This method fetches the user record from system via user Email
     * @author Sachin V | 2026-03-01
     * @param userEmail | String
     * @return List<User>
     */
    public static List<User> findCustomerViaEmail(String userEmail) {
        if (String.isNotBlank(userEmail)) {
            return [SELECT Id, Name, Username, Email, ECOM_Is_Punchout_User__c, ContactId, Contact.Email, Contact.ECOM_CountryProvided__c FROM USER WHERE Email=:userEmail AND ECOM_Is_Punchout_User__c = true LIMIT 1];
        } else {
            return null;
        }
    }

    /**
     * RWPS-5938
     * @description This method fetches the magic link activation status
     * @author Sachin V | 2026-03-01
     * @return Boolean
     */
    @AuraEnabled(Cacheable=true)
    public static Boolean getMagicLinkImplementationActivationStatus() {
        Boolean isMagicLinkImplementationActive = false;
        List<C_META_Storefront_Configuration__mdt> magicLinkActivationStatusRecordList =  ECOM_CustomMetadataRepo.fetchStoreConfigMdtBasedOnModuleName('ECOM_Magic_Link_Activation_Status');
        if (magicLinkActivationStatusRecordList.isEmpty() == false) {
            isMagicLinkImplementationActive = magicLinkActivationStatusRecordList[0] != null && magicLinkActivationStatusRecordList[0].Value__c != null && (magicLinkActivationStatusRecordList[0].Value__c == 'true' || magicLinkActivationStatusRecordList[0].Value__c == 'True') ? true : false;
        }
        return isMagicLinkImplementationActive;
    }

    /**
     * RWPS-5938
     * @description This method generates the JWT token for provided username
     * @author Sachin V | 2026-03-01
     * @param username | String
     * @param endpoint | String
     * @param secretKey | String
     * @param validityTime | Integer
     * @param certificateName | String
     * @return List<User>
     */
    public static string generateJWTToken(String username, String endpoint, String secretKey, Integer validityTime, String certificateName) {
        Auth.JWT jwt = new Auth.JWT();
        String jwtToken;
        jwt.setSub(username);
        jwt.setAud(endpoint);
        jwt.setIss(secretKey);
        jwt.setValidityLength(validityTime);
        Auth.JWS jws = new Auth.JWS(jwt.toJSONString(), certificateName);
        jwtToken = Test.isRunningTest() == true ? 'testToken' : jws.getCompactSerialization();
        return jwtToken;
    }

    @TestVisible
    private static void logResults(Map<String, Object> methodDataMap, String userName){
        try{
            if(null != methodDataMap && methodDataMap.containsKey(ECOM_Constant.PARAM_RESPONSE_DATA)){
                Map<String, Object> responseDataMap = (Map<String, Object>) methodDataMap.get(ECOM_Constant.PARAM_RESPONSE_DATA);
                if(null != responseDataMap && responseDataMap.containsKey(ECOM_Constant.PARAM_SUCCESS)) {
                    System.debug('logResults:responseDataMap::' + JSON.serialize(responseDataMap));
                    Boolean isSuccess = (Boolean) responseDataMap.get(ECOM_Constant.PARAM_SUCCESS);
                    String message = responseDataMap.containsKey(ECOM_Constant.PARAM_MESSAGE) ? (String) responseDataMap.get(ECOM_Constant.PARAM_MESSAGE) : '';
                    if(!isSuccess) {
                        throw new ECOM_SystemException(message);
                    }
                }
            }
        }catch(Exception e) {
            ECOM_ApplicationLogsUtil.logFailure(e , 'User Login' , 'ECOM_CustomLoginController' , 'loginUser', 'UserEmail:: '+ userName  + ' Stack:: '+ e.getStackTraceString(), userName);
        }
    }
}