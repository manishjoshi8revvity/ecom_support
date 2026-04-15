/**************************************************************
* Note :  As Login having issue due to dependency in other classes , We(R1) decided to 
*  move all punchout logic to controller to  fix the issue.(Asked by Salesforce Inc)
* 1. Jira Ticket(s) that relates to this class
*    ECOM-1020
*	 ECOM-1022
*
* 2. Description - This class is a controller class to login punchout users.
*
*
*
* 3. Objects referenced
*    -None
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
*
* 5. Dependant Class(es):
*    - None
*	
* 6. Test Class Name:         
*    - ECOM_PunchoutTestUserLoginController_Test
*
* 7. Is @Invocable (Yes or No): Yes
*
* 8. Author Name(s):
*    - vramachandran@rafter.one | 07 Jan 2024
*    - ssingh@rafter.one | Added methods  logFailure, storeExceptionLog, setupApplicationRecord, getSystemLimits| 15 May 2024 | RWPS-667
*    - ssingh@rafter.one | Added method getParamsMap| 17 May 2024
*************************************************************/
@RestResource(urlMapping='/resetpassword/*')
global without sharing class ECOM_PunchoutTestUserLoginController {
    
    public static String className = 'ECOM_PunchoutTestUserLoginController';
    public static final String ENCRYPTED_TOKEN = 'encryptedToken';
    public static final String ENCRYPTED_CODE = 'encryptedCode';
    public static final String ALGORITHM_AES_256 = 'AES256';
    public static final String INITIALIZATION_VECTOR = 'InitializationVector';
    public static final String MODULE_SECURITY = 'Security';
    public static final String SECRET_KEY = 'SecretKey';

    /**
     * @description This method returns the login url for the given user
     * @author vramachandran@rafter.one | 07 Jan 2024
     * @returns String
     */
    public String getReturnURL() {
        Map<String,Object> responseMap = new Map<String,Object>();

        //Map<String, String> mapPageParams = ApexPages.currentPage().getParameters();
        Map<String, String> mapPageParams = Test.isRunningTest()?getParamsMap():ApexPages.currentPage().getParameters();

        try{
            String poToken = getValueFromMap(mapPageParams,ECOM_Constant.PARAM_PUNCHOUT_TOKEN);
            String poCode = getValueFromMap(mapPageParams,ECOM_Constant.PARAM_PUNCHOUT_CODE);
            String storeUrl = getValueFromMap(mapPageParams,ECOM_Constant.PARAM_STOREFRONT_URL);
            String poUserId = getValueFromMap(mapPageParams,ECOM_Constant.PARAM_USER_ID);
            String returnUrl = '';
            
            if(String.isNotEmpty(poToken) && String.isNotEmpty(poCode) && String.isNotEmpty(storeUrl)){
                String decryptedUserName = decryptWithAES256(poToken);
                String decryptedPassword = decryptWithAES256(poCode);
                String decryptedUserId = decryptWithAES256(poUserId);
                String decryptedStoreFrontUrl = decryptWithAES256(storeUrl);
                
               // System.setPassword(decryptedUserId, decryptedPassword);
                
                
                PageReference pageReferenceObject = Site.login(decryptedUserName, decryptedPassword, decryptedStoreFrontUrl);
                if (pageReferenceObject != null) {
                    
                    System.debug('decryptedUserId:: '+ decryptedUserId);
                    
                    
                    //fetch current punchout user record
                    User  userRecord = getPunchoutUserInformationForUserId(decryptedUserId);
                    
                    System.debug('userRecord:: '+ JSON.serialize(userRecord));
                        
                    String pageURL = pageReferenceObject.getUrl();
                    
                    //create session cookie
                    createNewSessionCookie(userRecord);
                    responseMap.put(ECOM_Constant.PARAM_STOREFRONT_URL,pageURL);
                    responseMap.put(ECOM_Constant.PARAM_SUCCESS, true);
                } else {
                    responseMap.put(ECOM_Constant.PARAM_MESSAGE, 'Invalid Credentials');
                    responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
                }   
            }
        }catch(Exception e ){
            System.debug('Cause:: '+ e.getMessage() + ' ' + e.getStackTraceString());
        }
        
        
        return JSON.serialize(responseMap);
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
            logFailure(exceptionObject, ECOM_Constant.USER_MODULE_NAME, className, methodName, supportData);
        }
        return decryptedString;
    }
    
    /**
    * @description This method returns the string of configuration value
    * @author vramachandran@rafter.one | 07 Jan 2024 
    * @param labelName | String
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
    * @description This method returns the values from params
    * @author vramachandran@rafter.one | 07 Feb 2024
    * @param valueMap 
    * @param key 
    * @return String 
    **/
    public static String getValueFromMap(Map<String,String> valueMap,String key)
    {
        String returnVal='';
        if(valueMap.containsKey(key) && valueMap.get(key)!=null) {
            return valueMap.get(key).unescapeHtml4();
        }
        return returnVal;
    }

    @HttpPost
    global static String getPassword(String punchoutCode , String punchoutToken){
        String userId = decryptWithAES256(punchoutToken);
        String password = decryptWithAES256(punchoutCode);
		System.setPassword(userId, password);
        System.debug('Password Reset Success:: ' + userId + ' ' + password);
        return 'success';
    }
    
    global class PunchoutLoginWrapper{
        @auraEnabled global String storeFrontUrl;
    }
    
    /**
     * @description This method creates a session cookie for the punchout user
     * @author vramachandran@rafter.one | 09 Jan 2024
     * @param userRecord | User
     */
    @TestVisible
    private static void createNewSessionCookie(User userRecord){
        String cmsParameters;
        String sessionCookieParameters;
        System.debug('createNewSessionCookie.userRecord:: '+ JSON.serialize(userRecord));
        
        cmsParameters = ECOM_Constant.PARAM_EXT_USER_ID + '=' + userRecord.Id;
        cmsParameters = cmsParameters + '&' + ECOM_Constant.PARAM_EXT_EMAIL_ID + '=' + userRecord.Email;
        sessionCookieParameters = cmsParameters + '&' + ECOM_Constant.PARAM_EXT_SESSION_STARTED_TIMESTAMP + '=' + String.valueOf(DateTime.now().getTime());
        sessionCookieParameters = sessionCookieParameters + '&' + ECOM_Constant.PARAM_EXT_IF_SESSION_STARTED_FLAG + '=' + String.valueOf(1);
        sessionCookieParameters = encryptWithAES256(sessionCookieParameters);
        
        Cookie ck = new Cookie('SESS_SF_SESSION', sessionCookieParameters, null, -1, true, 'Lax');
        ApexPages.currentPage().setCookies(new Cookie[]{ck});  
    }
    
    
    /**
     * @description This method returns the user record for a given user id
     * @author vramachandran@rafter.one | 20 Jan 2024
     * @param userId | String 
     * @returns User
     */
    @TestVisible
    private static User getPunchoutUserInformationForUserId(String userId){
        User userRecord;
        List<User> usersList = new List<User>();
        usersList = [SELECT Id, Name, FirstName, Lastname, Phone, Fax, Email, ContactId, Contact.Name, Contact.AccountId, 
                Contact.fxDomain__c, Account.Name, Contact.ECOM_CountryProvided__c,
                Contact.Default_Ship_to_ERP_Address__c, Contact.Default_Bill_to_ERP_Address__c,
                Country, UserName, ECOM_Is_Punchout_User__c, AccountId
                FROM User 
                WHERE Id =:userId
				AND ECOM_Is_Punchout_User__c = true
                LIMIT 1 ];
        
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
            logFailure(exceptionObject, ECOM_Constant.USER_MODULE_NAME, className, methodName, supportData);
        }
        return encryptedString;
    }

    /**
    * @description  this method is used to log failure exception logs
    * @author singh@rafter.one | 05-15-2024 
    * @param excp 
    * @param moduleName 
    * @param className 
    * @param methodName 
    * @param supportData 
    **/
    public static void logFailure(Exception excp , String moduleName , String className , String methodName,String supportData)
    {
        storeExceptionLog(excp,moduleName,className,methodName,supportData);
    }


    /**
    * @description  this method is used to save the exception log
    * @author singh@rafter.one | 05-15-2024 
    * @param excp  Exception
    * @param moduleName String
    * @param className String
    * @param methodName String
    * @param supportData String
    **/
    public static void storeExceptionLog(Exception excp , String moduleName , String className , String methodName,String supportData)
    {
        try 
        {
            ECOM_Application_Logs__c  exc = setupApplicationRecord(excp,moduleName,className,methodName,supportData);
            if ( (exc != null &&
            (ECOM_Logging_Setting__c.getValues(System.UserInfo.getUserId()) != null &&
            ECOM_Logging_Setting__c.getInstance(System.UserInfo.getUserId()).EnableDebugLogs__c) ||
            (ECOM_Logging_Setting__c.getValues(System.UserInfo.getProfileId()) != null &&
                    ECOM_Logging_Setting__c.getInstance(System.UserInfo.getProfileId()).EnableDebugLogs__c)) ||
            UserInfo.getUserType() == 'Guest')
            {
                Database.insert(exc);
            }
            
        }catch (Exception ex) {
            System.debug('######## Error while saving application logs #######' + ex);
            System.debug('######## Error while saving application logs #######' + ex.getStackTraceString());
            System.debug('######## Error while saving application logs #######' + ex.getMessage());
        }
    }

    /**
    * @description  This method is used to setup log.
    * @author singh@rafter.one | 05-15-2024  
    * @param excp 
    * @param moduleName 
    * @param className 
    * @param methodName 
    * @param supportData 
    * @return ECOM_Application_Logs__c 
    **/
    public static ECOM_Application_Logs__c setupApplicationRecord(Exception excp , String moduleName , String className , String methodName,String supportData)
    {
        List<String> lstSalesforceLimit = getSystemLimits();
        ECOM_Application_Logs__c  exc = new ECOM_Application_Logs__c ();
        exc.SalesforceLimits__c = String.format('{0}\n{1}\n{2}\n{3}', lstSalesforceLimit);
        exc.ErrorMessage__c = excp.getMessage();
        exc.ExceptionType__c = excp.getTypeName();
        exc.LineNumber__c = String.valueOf(excp.getLineNumber());
        exc.StackTrace__c = excp.getStackTraceString();
        exc.ModuleName__c = moduleName;
        exc.ClassName__c = className;
        exc.MethodName__c = methodName;
        exc.SupportData__c = supportData;
        exc.ExceptionRunningUser__c = UserInfo.getUserId();
        return exc;
    }

    /**
    * @description  This method is used to calculate the System Limits during the exception.
    * @author singh@rafter.one | 05-15-2024  
    * @return List<String> 
    **/
    public static List<String> getSystemLimits()
    {
        String queryLimit = '1. SOQL Queries used / SOQL Queries allowed: ' + Limits.getQueries() + '/' + Limits.getLimitQueries();
        String dmlLimit = '2. Number of records queried so far /  Number allowed: ' + Limits.getDmlRows() + '/' + Limits.getLimitDmlRows();
        String dmlStat = '3. Number of DML statements used so far / Number allowed: ' + Limits.getDmlStatements() + '/' + Limits.getLimitDmlStatements();
        String cpuUsage = '4. Amount of CPU time (in ms) used so far / CPU usage time (in ms) allowed: ' + Limits.getCpuTime() + '/' + Limits.getLimitCpuTime();
        
        List<String> lstSalesforceLimit = new List<String>();
        lstSalesforceLimit.add(queryLimit);
        lstSalesforceLimit.add(dmlLimit);
        lstSalesforceLimit.add(dmlStat);
        lstSalesforceLimit.add(cpuUsage);
        return lstSalesforceLimit;
    }

    /**
    * @description  This method is used to get paramsMap for getReturnURL() Method for test class
    * @author singh@rafter.one | 05-17-2024  
    * @return List<String> 
    **/    
    public static Map<String,String> getParamsMap() {
        Map<String,String> paramsMap = new Map<String,String>();
        paramsMap.put('poToken', 'Test Token');
        paramsMap.put('poCode', 'Test PO');
        paramsMap.put('storeUrl', 'www.revvity.com');
        paramsMap.put('poUserId', 'Test User Id');
        
        return paramsMap;
    }
    
}