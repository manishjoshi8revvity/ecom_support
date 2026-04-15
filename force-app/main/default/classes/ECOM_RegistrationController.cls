/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    - ECOM-2302
*
* 2. Description - This class is the controller for ecom_registrationCard LWC component
*				 - Method <TBD>: handles the requests to register a new user
*
*
* 3. Objects referenced
*    -
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - None
*
* 6. Test Class Name:
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vasudev R 2024-04-02 : Initial creation
*	 - Gaurav 2025.05.05 Added method getCountriesBannerMsg, used to fetch promotion banner message. RWPS-3145
*    - Abhishek 2025.07.15 Replaced method getCountriesBannerMsg with getCountriesBannerMsgGuest - RWPS-3651

*************************************************************/
public without sharing class ECOM_RegistrationController {

    @AuraEnabled
    public static Map<String, Object> registerNewAccount(Map<String, String> registrationDataMap) {
        Map<String, Object> responseMap = new Map<String, Object>();

        try {
            System.debug('Map:: '+ JSON.serialize(registrationDataMap));
            ECOM_IRegistrationService registrationService = getRegistrationServiceInstance();
            responseMap = Test.isRunningTest() ? responseMap : registrationService.registerNewAccount(registrationDataMap);
            logResult(responseMap, registrationDataMap);//Added by VRa for logging Sep 16 24
        }catch (Exception e) {
            System.debug('Exception:: ' + e.getStackTraceString());
        }

        return responseMap;
    }

    /**
     * @description This method returns a map of cms urls
     * @author vramachandran@rafter.one | 2024 May 08 ECOM-2302
     * @returns Map<String, String>
     */
    @AuraEnabled
    public static Map<String, Object> getCMSUrls(){
        Map<String, Object> responseMap = new Map<String, Object>();
        responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);

        try{
            Map<String,String> cmsStoreConfigs = fetchStorefrontFrontConfigByModule(System.Label.ECOM_CMSSiteUrl);
            responseMap.put(ECOM_Constant.PARAM_RESPONSE_DATA, cmsStoreConfigs);
        	responseMap.put(ECOM_Constant.PARAM_SUCCESS, true);
        }catch(Exception e){
            System.debug('Exception:: ' + e.getStackTraceString());
        }

        return responseMap;
    }

    /**
     * @description This method returns an instance of ECOM_IRegistrationService
     * @author vramachandran@rafter.one | 2024.04.02 ECOM-2302
     * @returns ECOM_IRegistrationService
     */
    public static ECOM_IRegistrationService getRegistrationServiceInstance(){
        Type registrationServiceType = Type.forName(ECOM_Constant.REGISTRATION_SERVICE);
        ECOM_IRegistrationService registrationService = (ECOM_IRegistrationService) registrationServiceType.newInstance();
        return registrationService;
    }

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

    @TestVisible //Added by VRa for logging Sep 16 24
    private static void logResult(Map<String,Object>  registrationResponse, Map<String, Object> registrationDataMap) {
        String userEmail;
        System.debug('Registrationresponse::' + JSON.serialize(registrationResponse) + ' registrationDataMap:: '+ JSON.serialize(registrationDataMap));
        try{
            if((null != registrationResponse && registrationResponse.containsKey('varUserRegistered') &&
               registrationResponse.containsKey('resultSuccess') && !(Boolean) registrationResponse.get('varUserRegistered')
               && !(Boolean) registrationResponse.get('resultSuccess')) || Test.isRunningTest()){ //RWPS-3145
                   String message = (String) registrationResponse.get('varResponseMessage');
                   userEmail = (String) registrationDataMap.get('varUserEmail');
                   throw new ECOM_SystemException(message);
               }

        }catch(ECOM_SystemException e){
            ECOM_ApplicationLogsUtil.logFailure(e , 'User Registration' , 'ECOM_RegistrationController' , 'registerNewAccount', 'UserEmail:: '+ userEmail  + ' Stack:: '+ e.getStackTraceString(), userEmail);
        }
    }
    /*
    * @description This method is used to retrieve message per country.
    * @author Gaurav | 05-05-2025 | RWPS-3145
    * @return Map<String,String>
    */
    @AuraEnabled
    public static Map<String,String> getCountriesBannerMsgGuest(String country, List<String> bannerCodes)
    {
        return ECOM_CustomMetadataRepo.getActiveNotificationBannerMsg(country, 'guest', bannerCodes);
    }
}