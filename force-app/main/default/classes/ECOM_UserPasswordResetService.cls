/**************************************************************
*
* 1. Jira Ticket(s) that relates to this class
*    ECOM-2302
*
* 2. Description - This class is a controller class to reset newly registered user password.
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
*    - 
*
* 7. Is @Invocable (Yes or No): Yes
*
* 8. Author Name(s):
*    - vramachandran@rafter.one | 09 May 2024
* 	 - Sathiya 2024.08.30 Adding username as parameter for all logging for more info update
* 	 - Sathiya 2024.11.15 Adding log fix for RWPS-1925
*************************************************************/
@RestResource(urlMapping='/resetuserpassword/*')
global without sharing class ECOM_UserPasswordResetService {

    private static String CLASS_NAME = 'ECOM_UserPasswordResetService';
    
    @HttpPost
    global static String resetUserPassword(String userEmail, String emailTemplate){
        
        Map<String, Object> responseMap = new Map<String, Object>();
        responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
        
        try{
            System.debug('resetUserPassword: userEmail:: '+ userEmail);
            
            if(String.isNotBlank(userEmail)) {
                
                //fetch the user registered with current email
                List<User> usersList = [SELECT Id, FirstName, ECOM_Reset_Password_Site_URL__c, ECOM_Reset_Password_Key__c, ECOM_Is_Punchout_User__c, ContactId, Contact.Email, Contact.ECOM_CountryProvided__c FROM User WHERE email =: userEmail LIMIT 1];
                
                String encryptedUserEmail =  encryptString(userEmail);
                String encryptedTimestamp = encryptString(String.valueOf(DateTime.now().getTime()));
				String baseUrl = getSiteUrl(emailTemplate) + '?token=' + EncodingUtil.urlEncode(encryptedUserEmail, 'UTF-8') + '&sess=' + EncodingUtil.urlEncode(encryptedTimestamp, 'UTF-8') + '&ptcms=true';
                
                System.debug('usersList:: '+ JSON.serialize(usersList));
                if(null != usersList && !usersList.isEmpty() ) {
                    
                    User registeredUser = usersList[0];
                    System.debug('USERDATA:: '+ JSON.serialize(registeredUser));
                    if(!registeredUser.ECOM_Is_Punchout_User__c) {
                        registeredUser.ECOM_Reset_Password_Site_URL__c = baseUrl;
                        registeredUser.ECOM_Reset_Password_Key__c = encryptedTimestamp;
                        update registeredUser;
                        
                        if(registeredUser?.Contact?.ECOM_CountryProvided__c != null){
                            Map<String,String> countryMdt = ECOM_CustomMetadataService.getEmailContactDetails(registeredUser?.Contact?.ECOM_CountryProvided__c);
                            if(countryMdt.containsKey('CustomerCareEmailAddress')){
                                ECOM_CustomEmailUtils.sendEmailWithTemplate(registeredUser.Contact.Email, emailTemplate, (String)countryMdt.get('CustomerCareEmailAddress'));
                                System.debug('registeredUser:: '+ JSON.serialize(registeredUser));
                                responseMap.put(ECOM_Constant.PARAM_SUCCESS, true);
                                responseMap.put('customerEmail', (String)countryMdt.get('CustomerCareEmailAddress'));
                            } else {
                                ECOM_CustomEmailUtils.sendEmailWithTemplate(registeredUser.Contact.Email, emailTemplate, System.Label.ECOM_OrgWideEmail);
                                System.debug('registeredUser:: '+ JSON.serialize(registeredUser));
                                responseMap.put(ECOM_Constant.PARAM_SUCCESS, true);
                                responseMap.put('customerEmail', System.Label.ECOM_OrgWideEmail);
                            }
                        } else {
                            responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
                            // Fix for RWPS-1925
                            responseMap.put(ECOM_Constant.PARAM_MESSAGE, System.Label.ECOM_101001);
                            // Fix End
                        }
                        // Fix for RWPS-1925
                        if((Boolean)responseMap.get(ECOM_Constant.PARAM_SUCCESS)){
                            ECOM_ApplicationLogsUtil.logApplicationApiData('Forgot Password', 'ECOM_UserPasswordResetService', 'resetUserPassword', 'Email:: '+ userEmail +  ' Message:: Forgot Password Email sent', 'Email:: '+ userEmail +  ' Message:: Forgot Password Email sent', userEmail);
                        }
                        // Fix End
                        //reset the user password with newly registered user email template
                        //System.resetPasswordWithEmailTemplate(registeredUser.Id, true, System.Label.ECOM_NewRegistrationEmailTemplateName);     
                        //System.resetPasswordWithEmailTemplate(registeredUser.Id, true, emailTemplate);//'ECOM_PasswordResetTemplateNew');//);
                    } else {
                        //log message
                        responseMap.put(ECOM_Constant.PARAM_MESSAGE, System.Label.ECOM_101004);
                        
                    }
                } else {
                    //User does not exist
                    //ECOM_ApplicationLogsUtil.logApplicationApiData('Forgot Password', 'ECOM_UserPasswordResetService', 'resetUserPassword', 'Email:: '+ userEmail +  ' Message:: '+ System.Label.ECOM_101004, 'Email:: '+ userEmail +  ' Message:: '+ System.Label.ECOM_101004, userEmail);
                    responseMap.put(ECOM_Constant.PARAM_MESSAGE, System.Label.ECOM_101001);
                }
            }
        }catch(Exception e ){
            System.debug('Exception:: ' + e.getStackTraceString());
            ECOM_ApplicationLogsUtil.logFailure(e, 'Forgot Password', 'ECOM_UserPasswordResetService', 'resetUserPassword', 'Email:: '+ userEmail + ' StackTrace:: '+ e.getStackTraceString(), userEmail);
        }    
        
        return JSON.serialize(responseMap);
    }
    
    @TestVisible
    private static String getSiteUrl(String emailTemplate){
        Boolean isUseBaseUrl = Boolean.valueOf(System.Label.ECOM_IsUseBaseUrl);

        String sfBaseUrl = System.Label.ECOM_SFBaseUrl;
        String storeBaseUrl;
        
        DomainSite siteDomain= fetchBaseSiteURL(System.Label.ECOM_SiteName);
        
        //String endpoint = (emailTemplate == System.Label.ECOM_NewRegistrationEmailTemplateName) ? System.Label.ECOM_CustomerPasswordSetPage : System.Label.ECOM_CustomeUserPasswordResetPage;
        String endpoint = (emailTemplate == System.Label.ECOM_CustomNewAccountCreationEmailTemplate) ? System.Label.ECOM_CustomerPasswordSetPage : System.Label.ECOM_CustomeUserPasswordResetPage;
        
        storeBaseUrl = System.Label.ECOM_HTTPS_Prefix  + (isUseBaseUrl ? sfBaseUrl : siteDomain.Domain.domain) + endpoint;//System.Label.ECOM_CustomeUserPasswordResetPage;
        
        return storeBaseUrl;
    }
    
    /**
    * @description  get  domain site by name
    * @author Vipul | 09-21-2023 
    * @param siteName 
    * @return DomainSite 
    **/
    @TestVisible
    private static DomainSite fetchBaseSiteURL(String siteName){
        return Test.isRunningTest() ? [SELECT Id, Domain.domain, Site.Name, PathPrefix, CreatedDate FROM DomainSite Where Site.Name = :siteName  LIMIT 1]:  [SELECT Id, Domain.domain, Site.Name, PathPrefix, CreatedDate FROM DomainSite Where Site.Name = :siteName AND  Domain.domain=:System.Label.ECOM_CommunityDomainName LIMIT 1] ;
    }
    
    @TestVisible
    private static String encryptString(String textToEncrypt) {
        String encryptedString = null;
        String methodName = 'encryptWithAES256';
        String supportData = '';
        try {
            String strSecretKey = fetchConfigByValue(ECOM_Constant.SECRET_KEY);
            String strInitializationVector = fetchConfigByValue(ECOM_Constant.INITIALIZATION_VECTOR);
            Blob blobSecretKey = Blob.valueOf(strSecretKey);
            Blob blobInitializationVector = Blob.valueOf(strInitializationVector);
            Blob blobClearData = Blob.valueOf(textToEncrypt);
            Blob blobEncryptedTextData = Crypto.encrypt(ECOM_Constant.ALGORITHM_AES_256, blobSecretKey, blobInitializationVector, blobClearData);
            encryptedString = EncodingUtil.base64Encode(blobEncryptedTextData);
        } catch (Exception exceptionObject) {
            System.debug(exceptionObject.getStackTraceString());
            ECOM_ApplicationLogsUtil.logFailure(exceptionObject, ECOM_Constant.USER_MODULE_NAME, CLASS_NAME, methodName, supportData);
        }
        return encryptedString;
    }
    
    /**
    * @description 
    * @author mkumar@rafter.one | 09-18-2023 
    * @param labelName 
    * @return String 
    **/
    @TestVisible
    private static String fetchConfigByValue(String labelName) {
        String value = '';
        C_META_Storefront_Configuration__mdt config = C_META_Storefront_Configuration__mdt.getInstance(labelName);
        if (config != null) {
            value = String.isNotBlank(config.Value__c) ? config.Value__c : '';
        }
        return value;
    }
}