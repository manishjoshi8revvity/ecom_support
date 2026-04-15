/**************************************************************
 * 1. Jira Ticket(s) that relates to this class
 *    ECOM- 1554
 * 
 * 2. Description - This class acts as the utility class for login encryption and decryption.
 * 
 * 3. Objects referenced
 *    -None
 * 
 * 4. Callouts to additional Components (including their methods) or None:
 *    - None
 * 
 * 5. Dependant Class(es):
 * 
 * 6. Test Class Name: 
 * 
 * 7. Is @Invocable (Yes or No): No
 * 
 * 8. Author Name(s):
 *    - Vasudev R | 2024 May 21
 *    - Sachin V 2026.01.29 - Updated method : setNewUserPassword - RWPS-5938
 *    - Poonam S 2026.04.13 - Updated method : logResult - RWPS-6037
 *************************************************************/
@RestResource(urlMapping = '/setnewuserpassword/*')
global inherited sharing class ECOM_UserPasswordSetService {
    
    private static String userEmailForLog; //VRa added for logging Sep 16 24

    @HttpPost
    global static String setNewUserPassword(String encryptedUserEmail, String encryptedPassword, String encryptedToken){
        
        //Map<String, Object> responseMap = new Map<String, Object>();
        //responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
        ECOM_RegistrationWrapper.ValidationResult  validationResult= new ECOM_RegistrationWrapper.ValidationResult();
        validationResult.success = false;
         String userEmail;
        try{
            
            //TODO encryptedToken check 
            userEmail = ECOM_EncryptUtil.decryptWithAES256(encryptedUserEmail);
            String userPassword = ECOM_EncryptUtil.decryptWithAES256(encryptedPassword);
            String decryptedToken = ECOM_EncryptUtil.decryptWithAES256(encryptedToken);
            
            System.debug('userEmail:: '+ userEmail + ' userPassword:: '+ userPassword + ' decryptedToken::' + decryptedToken);
            userEmailForLog = userEmail; //VRa added for logging Sep 16 24
            
            List<User> userRecordsList = [SELECT Id, ECOM_Reset_Password_Key__c, ECOM_Reset_Password_Site_URL__c, ContactId, ECOM_Is_Punchout_User__c FROM User WHERE Email =: userEmail LIMIT 1]; //RWPS-5938
            
                System.debug('FINAL userRecordsList to RESET-->'+userRecordsList);
                if(null != userRecordsList && !userRecordsList.isEmpty()){
                    User userRecord = userRecordsList[0];
                    
                    validationResult = validateToken(decryptedToken, userRecord, encryptedToken);

                    System.debug('FINAL validationResult-->'+JSON.serialize(validationResult));
                    
                    if((null != validationResult && validationResult.success ) || Test.isRunningTest()){
                        //validation paassed reset password
                        if(! Test.isRunningTest()) System.setPassword(userRecord.Id, userPassword);
                        System.debug('FINAL PASSWORD RESET-->');
						userRecord.ECOM_Reset_Password_Key__c = null;
                        userRecord.ECOM_Reset_Password_Site_URL__c = null; 
                        update userRecord;
                        
                        //RWPS-5938
                        if (userRecord.ECOM_Is_Punchout_User__c == true && userRecord.ContactId != null) {
                            update new Contact(Id = userRecord.ContactId, ECOM_Punchout_Via_Web__c = true);
                        }
                        //RWPS-5938

                        validationResult.success = true;
                    } 

                } else {
                    //user email does not exist
                    logResult(System.Label.ECOM_102002); //VRa added for logging Sep 16 24
                    validationResult.message  = System.Label.ECOM_102002;
                }

        }catch(Exception e){
           validationResult.message =  getLabelForErrorMessage(e.getMessage()); validationResult.success = false;
            logResult(validationResult.message); //VRa added for logging Sep 16 24
        }
        
		System.debug('response:: '+ JSON.serialize(validationResult));        
        return JSON.serialize(validationResult);
    } 
    
    
    @TestVisible
    private static String getLabelForErrorMessage(String errorMessage){
        String labelString = System.Label.ECOM_102003;
        if(errorMessage.equalsIgnoreCase('UNKNOWN_EXCEPTION: invalid repeated password')) labelString = System.Label.ECOM_102004;
        if(errorMessage.equalsIgnoreCase('INVALID_NEW_PASSWORD: Your Password cannot equal or contain your user name.')) labelString = System.Label.ECOM_102005;
        if(errorMessage.equalsIgnoreCase('INVALID_NEW_PASSWORD: Your password must be at least 12 characters long.')) labelString = System.Label.ECOM_102006;
        if(errorMessage.equalsIgnoreCase('INVALID_NEW_PASSWORD: Your password must include letters and numbers')) labelString = System.Label.ECOM_102007;
        
        return labelString;
    }
    
    @TestVisible
    private static ECOM_RegistrationWrapper.ValidationResult validateToken(String decryptedToken, User userRecord, String encryptedToken) {
       ECOM_RegistrationWrapper.ValidationResult validationInstance = new ECOM_RegistrationWrapper.ValidationResult();
        
        validationInstance.success = true; String message; Boolean success = true;
        
       	Long timeDiff = ((DateTime.now().getTime() - Long.valueOf(decryptedToken))/1000/60/60); //get hours from milliseconds
        System.debug('timeDiff:: ' + timeDiff);
       
        if(String.isNotBlank(userRecord?.ECOM_Reset_Password_Key__c) && userRecord?.ECOM_Reset_Password_Key__c == encryptedToken){	
            if(timeDiff <= 24 && String.isBlank(userRecord.ECOM_Reset_Password_Key__c) ) {
                
                validationInstance.success = false; validationInstance.message = System.Label.ECOM_102003;
            } else if(timeDiff > 24 ) {
                
                validationInstance.success = false; validationInstance.message = System.Label.ECOM_SetPasswordLinkExpired;
            }
        } else {
            validationInstance.success = false; validationInstance.message = System.Label.ECOM_SetPasswordLinkExpired;
        }
        
        if(!validationInstance.success) { //VRa added for logging Sep 16 24
            logResult(validationInstance.message);
        }
        
        System.debug('sucess:: '+ success + ' message:: '+ message);
       return validationInstance;
    }
    
    //VRa added for logging Sep 16 24
    private static void logResult(String errorMessage) {
        System.debug('logResult:: '+ errorMessage);
        try{
            throw new ECOM_SystemException(errorMessage);
        }catch(ECOM_SystemException e) {
            String severity = ECOM_Util.getSeverityByMessage(errorMessage);//RWPS-6037
            ECOM_ApplicationLogsUtil.logFailure(e , 'Set Password' , 'ECOM_UserPasswordSetService' , 'setNewUserPassword', 'UserEmail:: '+ userEmailForLog  + ' Stack:: '+ e.getStackTraceString(), severity);//RWPS-6037
        }
    }
    
   
}