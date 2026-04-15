/**************************************************************
* 1. Jira Ticket(s) that relates to this class 
*    - ECOM-2302
*
* 2. Description - This class is the Service class for ecom_registrationCard LWC component
*				 - Method <TBD>: handles the requests to register a new user   
*
*
* 3. Objects referenced
*    -
*
* 4. Callouts to additional Components (including their methods) or None:
*    - FLOW: SUB_FLOW_4494_ECOM_User_Registration
*
* 5. Dependant Class(es):
*    - ECOM_RegistrationWrapper
*
* 6. Test Class Name: 
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vasudev R 2024-04-02 : Initial creation
*************************************************************/
public inherited sharing class ECOM_RegistrationService  implements ECOM_IRegistrationService {
    
    public Map<String, Object> registerNewAccount(Map<String, Object> registrationDataMap) {
        Map<String, Object> responseMap = new Map<String, Object>();
        responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
        try{
            
            //Flow.Interview.GetAccountName AcName = new Flow.Interview.GetAccountName (Params);
            
            Map<String, String> requestMap = new Map<String, String>();
            
            //prepare the requestMap from the values provided
            requestMap = ECOM_RestService.prepareRequestMap(System.Label.ECOM_IntegrationUserNamedCredential,
                                                            System.Label.ECOM_RegistrationFlowEndpoint,
                                                            '', 
                                                            ECOM_Constant.HTTP_REQUEST_POST,
                                                            true, 
                                                            registrationDataMap,
                                                            ECOM_Constant.HTTP_CONTENT_APP_JSON
                                                           );
            System.debug('registerNewAccount:requestMap:; '+ JSON.serialize(requestMap));
            
            //callout to registration flow endpoint from Custom label ECOM_IntegrationUserNamedCredential 
            HttpResponse response = ECOM_RestService.calloutAsIntegrationUser(requestMap);
            System.debug('Response:: '+ response + ' Response result:: '+ response.getBody());
            
            //check HttpResponse and prepare response map
            if(response != null && (response.getStatusCode() == 200 || response.getStatusCode() == 201)){
               
                //parse the response and add to map 
                responseMap.putAll(parseRegistrationResult(response)); 

                //VRa- ECOM-3348 Jun 24 : Begin
                Map<String,Object> registrationResponse =  (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(responseMap.get('responseData'))); 
                System.debug('ResponseMap:: '+ JSON.serialize(registrationResponse));
                
                //check if registration is successfull and send reset password email
                if(responseMap.containsKey(ECOM_Constant.PARAM_SUCCESS) && (Boolean) responseMap.get(ECOM_Constant.PARAM_SUCCESS) && 
                   registrationResponse.containsKey('varUserRegistered') && registrationResponse.containsKey('resultSuccess') && (Boolean) registrationResponse.get('varUserRegistered')
                  && (Boolean) registrationResponse.get('resultSuccess')){
                //VRa- ECOM-3348 Jun 24 : End
                    resetRegisteredUserPassword((String)registrationDataMap.get('varUserEmail'));
                }
            } else {
                
                responseMap.put(ECOM_Constant.PARAM_MESSAGE, 'Error message for callout failed');
            }
            
        }catch(Exception e) {
            System.debug('Exception:: '+ e.getStackTraceString());
            //TODO:: add Application Util to guest user and also provide access to the object
        }

        return responseMap;
    }

    
    /**
     * @description This method checks the HttpResponse object returned from registration callback and parses the result
     * @author vramachandran@rafter.one | 2024 May 08 ECOM-2302
     * @param response | HttpResponse 
     * @returns Map<String, Object>
     */
    @TestVisible
    private static Map<String, Object> parseRegistrationResult(HttpResponse responseObject) {
        Map<String, Object> responseMap = new Map<String, Object>();
        responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
        
        String responseBody = responseObject.getBody();
        List<ECOM_RegistrationWrapper.RegistrationResponse> registrationResponseList = 
            (List<ECOM_RegistrationWrapper.RegistrationResponse>) JSON.deserialize(responseBody, List<ECOM_RegistrationWrapper.RegistrationResponse>.class);
        
        System.debug('registrationResponseList:: '+ JSON.serialize(registrationResponseList));
        
        if(null != registrationResponseList && !registrationResponseList.isEmpty()) {
		
            ECOM_RegistrationWrapper.RegistrationResponse registrationResponse = registrationResponseList[0];
            if(null != registrationResponse && null != registrationResponse.outputValues && null == registrationResponse.errors && registrationResponse.isSuccess) {
                
                ECOM_RegistrationWrapper.OutputValue outputValue = registrationResponse.outputValues;
                
                responseMap.put(ECOM_Constant.PARAM_RESPONSE_DATA, outputValue);
                responseMap.put(ECOM_Constant.PARAM_SUCCESS, true);
            } else {
                responseMap.put(ECOM_Constant.PARAM_RESPONSE_DATA, registrationResponse);
                
                //Errors were not null
               	responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
                responseMap.put(ECOM_Constant.PARAM_MESSAGE, 'WIll be updated');
            }
        } else {
            
            //TODO: registration response was null
            responseMap.put(ECOM_Constant.PARAM_MESSAGE, 'Registration response was null');
        }
        
        return responseMap;
    }
    
    /**
     * @description This method calls out to reset user password
     * @author vramachandran@rafter.one | 2024 May 9 ECOM-2302
     * @param userEmailId | String
     * @returns void
     */
    @TestVisible
    private static void resetRegisteredUserPassword(String userEmailId) {
        
        Map<String, Object> requestBody = new Map<String, Object>();
        
       	ECOM_RegistrationWrapper.UserEmailWrapper emailWrapper = new ECOM_RegistrationWrapper.UserEmailWrapper();
        emailWrapper.userEmail = userEmailId;
        emailWrapper.emailTemplate = System.Label.ECOM_CustomNewAccountCreationEmailTemplate ;
        
        Map<String, String> requestMap = ECOM_RestService.prepareRequestMap(System.Label.ECOM_IntegrationUserNamedCredential,
                                                                            System.Label.ECOM_RegisteredUserPasswordResetEndpoint,
                                                                            '', 
                                                                            ECOM_Constant.HTTP_REQUEST_POST,
                                                                            false, 
                                                                            null,
                                                                            ECOM_Constant.HTTP_CONTENT_APP_JSON
                                                                           );
        requestMap.put(ECOM_Constant.HTTP_REQUEST_BODY, JSON.serialize(emailWrapper));
        
        System.debug('preparedMap :: '+ JSON.serialize(requestMap));
         HttpResponse response = ECOM_RestService.calloutAsIntegrationUser(requestMap);
        
    }
    
    
}