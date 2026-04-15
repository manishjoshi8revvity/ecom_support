/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-1554
*
* 2. Description - This class is a custom controller for setpassword page
*
* 3. Objects referenced
*    - User
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
* 5. Dependant Class(es):
*    
*
* 6. Test Class Name: 
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
* 	 - vramachandran@rafer.one | 15 May 2024
* 	 - Poonam Shukla | 13 Apr 2026 Updated method logResult RWPS-6037
*************************************************************/
public without sharing class ECOM_SetPasswordController {
    
    
    /**
     * @description This method resets the user password and callsout to login the user and get path to redirect
     * @author vramachandran@rafter.one | 22 May 2024 ECOM-1554
     * @param userEmail | String 
     * @param userPassword | String 
     * @param encryptedToken | String 
     * @returns Map<String, Object>
     */
    @AuraEnabled
    public static Map<String, Object> setNewPasswordAndRedirectUser(String userEmail, String userPassword, String encryptedToken){
        Map<String, Object> responseMap = new Map<String, Object>();
        responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
        
        try{
            
            ECOM_RegistrationWrapper.PasswordRequestWrapper passwordWrapper = new ECOM_RegistrationWrapper.PasswordRequestWrapper();
            passwordWrapper.encryptedUserEmail = userEmail;
            passwordWrapper.encryptedPassword = encryptWithAES256(userPassword);
            passwordWrapper.encryptedToken = String.isNotEmpty(encryptedToken) ? encryptedToken : 'EMPTY_STRING';
            
            
            Map<String, String> requestMap = ECOM_RestService.prepareRequestMap(System.Label.ECOM_IntegrationUserNamedCredential,
                                                                                System.Label.ECOM_PasswordSetEndpoint,
                                                                                '', 
                                                                                ECOM_Constant.HTTP_REQUEST_POST,
                                                                                false, 
                                                                                null,
                                                                                ECOM_Constant.HTTP_CONTENT_APP_JSON
                                                                               );
            requestMap.put(ECOM_Constant.HTTP_REQUEST_BODY, JSON.serialize(passwordWrapper));
            System.debug('preparedMap :: '+ JSON.serialize(requestMap));
            HttpResponse responseObject = ECOM_RestService.calloutAsIntegrationUser(requestMap);
            
            if(null != responseObject && (responseObject.getStatusCode() == 200 || responseObject.getStatusCode() == 201) && null != responseObject.getBody()) {
                
                System.debug('Body map:: ' + responseObject.getBody());
				String bodyValue = responseObject.getBody().replace('\\', '').removeEnd('"').removeStart('"');
                System.debug('bodyValue:: ' + bodyValue);
                ECOM_RegistrationWrapper.ValidationResult validationResult = (ECOM_RegistrationWrapper.ValidationResult) JSON.deserialize(bodyValue, ECOM_RegistrationWrapper.ValidationResult.class);
                
                System.debug('validationResult:: '+ JSON.serialize(validationResult));
                System.debug('userEmail:: '+ userEmail);
                System.debug('userPassword:: '+ userPassword);
                
                if(null != validationResult && validationResult.success) {
                    //set login callout
                    responseMap = loginUser(decryptWithAES256(userEmail), userPassword);
                    responseMap.put(ECOM_Constant.PARAM_SUCCESS, true);
                } else {
                	responseMap.put(ECOM_Constant.PARAM_SUCCESS,  validationResult.success);
                    responseMap.put(ECOM_Constant.PARAM_MESSAGE,  validationResult.message);
                    //logResult(validationResult.message, userEmail);// Added by VRa for logging Sep 16 24
                }
            } else {
                logResult(System.Label.ECOM_SetPasswordLinkExpired, userEmail);// Added by VRa for logging Sep 16 24
                
                responseMap.put(ECOM_Constant.PARAM_MESSAGE, System.Label.ECOM_SetPasswordLinkExpired);
            }
            
        }catch(Exception e){
			logResult(System.Label.ECOM_SetPasswordLinkExpired, userEmail);// Added by VRa for logging Sep 16 24
            responseMap.put(ECOM_Constant.PARAM_MESSAGE, System.Label.ECOM_SetPasswordLinkExpired);
        }
        
        return responseMap;
    }
    
    /**
     * @description This method calls the login controller to login the user and get redirection password
     * @author vramachandran@rafter.one | 22 May 2024 ECOM-1554
     * @param userEmail | String 
     * @param userPassword | String 
     * @returns Map<String, Object>
     */
    @TestVisible
    private static Map<String, Object> loginUser(String userEmail, String userPassword) {
        Map<String, Object> responseMap = new Map<String, Object>();
        responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
        
        //set login callout
        responseMap = ECOM_CustomLoginController.loginUser(userEmail, userPassword, '');
        
        return responseMap;
    }
    
    
    /**
     * This method is used to encrypts data with AES256
     *
     * @param strText String
     *
     * @return String
     *
     * @author Vipul Goyal | 07-27-2023
     **/
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
            //ECOM_ApplicationLogsUtil.logFailure(exceptionObject, ECOM_Constant.USER_MODULE_NAME, className, methodName, supportData);
        }
        return encryptedString;
    }
    
        /**
        * @description This method is used to fetch configuration based on provided key(label).
        * @author Vipul Goyal | 08-02-2023 
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
     * This method is used to decrypt data with AES256
     *
     * @param encryptedText String
     *
     * @return String
     *
     * @author Vipul Goyal | 07-27-2023
     **/
    public static String decryptWithAES256(String encryptedText) {
        String decryptedString = null;
        String methodName = 'decryptWithAES256';
        String supportData = '';
        try {
            String strSecretKey = fetchConfigByValue(ECOM_Constant.SECRET_KEY);
            String strInitializationVector = fetchConfigByValue(ECOM_Constant.INITIALIZATION_VECTOR);
            Blob blobSecretKey = Blob.valueOf(strSecretKey);
            Blob blobInitializationVector = Blob.valueOf(strInitializationVector);
            Blob encryptedDataUpdated = EncodingUtil.base64Decode(encryptedText);
            Blob decryptedTextData = Crypto.decrypt(ECOM_Constant.ALGORITHM_AES_256, blobSecretKey, blobInitializationVector, encryptedDataUpdated);
            decryptedString = decryptedTextData.toString();
        } catch (Exception exceptionObject) {
            //ECOM_ApplicationLogsUtil.logFailure(exceptionObject, ECOM_Constant.USER_MODULE_NAME, className, methodName, supportData);
        }
        return decryptedString;
    }
    
    @TestVisible //Added by VRa for logging Sep 16 24
    private static void logResult(String message, String userEmail) {
        try{
            throw new ECOM_SystemException(message);
        }catch(ECOM_SystemException e){
            String severity = ECOM_Util.getSeverityByMessage(message);//RWPS-6037
            ECOM_ApplicationLogsUtil.logFailure(e , 'Set Password' , 'ECOM_SetPasswordController' , 'setNewPasswordAndRedirectUser', 'UserEmail:: '+ decryptWithAES256(userEmail)  + ' Stack:: '+ e.getStackTraceString(), decryptWithAES256(userEmail),severity);//RWPS-6037
        }
    }
    

}