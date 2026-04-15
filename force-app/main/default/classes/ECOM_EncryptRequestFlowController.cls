/**************************************************************
* Note :  As Login having issue due to dependency in other classes , We(R1) decided to 
*  move all punchout logic to controller to  fix the issue.(Asked by Salesforce Inc)
* 1. Jira Ticket(s) that relates to this class
*    ECOM-1020
*	 ECOM-1022
*
* 2. Description - This class is a controller class encrypt the url parameters for punchout login.
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
*    - ECOM_EncryptRequestFlowController_Test
*
* 7. Is @Invocable (Yes or No): Yes
*
* 8. Author Name(s):
*    - vramachandran@rafter.one | 01 Jan 2024

*************************************************************/
public class ECOM_EncryptRequestFlowController {
    
    private static ECOM_IUserService userService;
    
    @InvocableMethod(label='ECOM Encrypt Request' Description='Encrypt Data')
    public static List<String> getEncryptedRequestParameter(List<ECOM_EncryptRequest> encryptRequest){
        List<String> encryptedString; 
        System.debug('encryptRequest:: '+ encryptRequest);
        Map<String,Object> requestMap = (Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(encryptRequest[0]));
        
        String encrypted = '';
        
        for(String key : requestMap.keySet()){
            
            if(requestMap.containsKey(key)){
                String  currValue = (String) requestMap.get(key);
                if(String.isBlank(encrypted)){
                    encrypted = key + '=' + (String.isNotEmpty(currValue) ? currValue : 'EMPTY_STRING' );
                } else {
                    encrypted = encrypted + '&' + key + '=' + (String.isNotEmpty(currValue) ? currValue : 'EMPTY_STRING' );
                }
            }
            
        }
        System.debug('Encrypted:: '+ encrypted);
        
        //get base url for store 
        String baseUrl = getUserServiceInstance().getBaseStoreUrl();
        
        
        //encrypted = ECOM_EncryptUtil.encryptWithAES256(encrypted);
        encrypted = ECOM_EncryptUtil.encryptWithBase64(encrypted);
        encrypted = EncodingUtil.urlEncode(encrypted, 'UTF-8');
        
        System.debug('baseUrl:: '+ baseUrl);
        System.debug('responseMap:: '+ JSON.serialize(requestMap)); 
        encrypted = baseUrl + System.Label.ECOM_PunchoutStoreLoginEndpoint  + encrypted;
        
        encryptedString = new List<String>{encrypted};
        return encryptedString;
    }
    
    /**
     * @description This method returns an instance of userservice
     * @author vramachandran@rafter.one | 02 Jan 2024
     * @returns ECOM_IUserService
     */
    private static ECOM_IUserService getUserServiceInstance(){
        if(null == userService){
            Type userServiceType = Type.forName(ECOM_Constant.USER_SERVICE);
            userService = (ECOM_IUserService)userServiceType.newInstance();
        }
        return userService;
    }

}