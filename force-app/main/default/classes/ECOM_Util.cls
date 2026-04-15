/**************************************************************
 * 1. Jira Ticket(s) that relates to this class
 *    RWPS-592
 * 
 * 1. Description - This class has general util methods used acreoss multiple classes  
 * 
 * 
 * 1. Objects referenced
 *    -C_META_Storefront_Configuration__mdt
 * 
 * 1. Callouts to additional Components:
 *    - None
 * 
 * 1. Dependant Class(es):
 *    - ECOM_UserService
 * 
 * 1. Test Class Name:         
 *    - ECOM_Util_Test
 * 
 * 1. Is @Invocable : No
 * 
 * 1. Author Name(s):
 *    - Vipul Goyal 2023.07.20
 * 	  - vramachandran@rafter.one | 12 Dec 2023
 *    - Vipul Goyal 2024.04.23 Added method convertListToQueryString to convet a list into comma seperated string.
 *    - manish.joshi@revvity.com | 07-May-2024 added method getSiteDetails for ticket RWPS-592
 *    - Gaurav | 22-08-2025 Updated parseDataLayerModel and parseOrderDataLayerModel for BOGO implementation RWPS-3811
 *    - Gaurav | 02-09-2025 Updated parseDataLayerModel for BOGO implementation RWPS-4194
 *    - Poonam | 2025.11.25 Added method logFieldError, logJsFailure - RWPS-5153
 *    - Poonam | 2026.02.27 Added method getPunchoutEmailDetails to fetch Punchout additional emails and selected email type - RWPS-5777
 *    - Poonam | 2026.03.31 Added method getExcludedPartNumberSet to fetch excluded part numbers for Punchout users - RWPS-6880

*************************************************************/
public with sharing class ECOM_Util {
    
    private static Map<String, String> communityIdToWebStoreIdCache = new Map<String, String>();
    
    /**
* @description This method is used to fetch Store Configuration
* @author Vipul Goyal | 08-02-2023 
* @param moduleName 
* @return Map<String, String> 
**/
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
* @description This method is used to fetch field labels by object name.
* @author mkumar@rafter.one | 07-28-2023 
* @param objectName 
* @return Map<String, String> 
**/
    public static Map<String,String> getFieldsByObjectName(String objectName)
    {
        Map<String, Schema.SObjectType> objMap = Schema.getGlobalDescribe();
        Map<String,String> fieldsMap = new Map<String,String>();
        for(Schema.SObjectField fields :objMap.get(objectName).getDescribe().fields.getMap().Values()) {
            fieldsMap.put(fields.getDescribe().getName(), fields.getDescribe().getLabel());
        }
        return fieldsMap;
    }
    
    /**
* @description This method is used to get a value from the map (provided as the parameter).
* @author Vipul Goyal | 07-20-2023 
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
    
    /**
* @description This method is used to set the Store's cart path
* @author Vipul Goyal | 07-20-2023 
* @param valueMap 
* @return String 
**/
    public static String getStrDefaultCartPath(Map<String,String> valueMap)
    {
        String returnVal='';
        if(valueMap.containsKey('sourceURL') && String.isNotBlank(valueMap.get('sourceURL')))
        {
            returnVal = '/demo/po-redirection?sourceURL='+valueMap.get('sourceURL').unescapeHtml4();
        }else if(valueMap.containsKey('storefrontPath') && String.isNotBlank(valueMap.get('storefrontPath')))
        {
            returnVal = valueMap.get('storefrontPath').unescapeHtml4();
        }
        return returnVal;
    }
    
    //Retrieves Web Store record based on the Name from custom label
    public static String getWebStoreIdByName(){
        String webstoreId = '';
        List<WebStore> webStores= ECOM_WebStoreRepo.getWebStoreByName(Label.ECOM_WebStore_Name);   
        if(!webStores.isEmpty())
        {
            webstoreId = webStores[0].Id;
        }
        return webstoreId;
    }
    
    /**
* @description Given a community ID, returns the relavent webstore ID for use in B2B Commerce on lightning
* @param  communityId The Id of the community from which the call originated
* @return weStoreId The webStoreId corresponding to the community Id.
* @example
* String webStoreId = B2BUtils.resolveCommunityIdToWebstoreId('0DB2D0000004Xz7');
*/
    public static String resolveCommunityIdToWebstoreId(String communityId) {
        if (communityIdToWebStoreIdCache.containsKey(communityId)) {
            return communityIdToWebStoreIdCache.get(communityId);
        } else {
            // String webStoreId = [
            //     SELECT WebStoreId
            //     FROM WebStoreNetwork
            //     WHERE NetworkId = :communityId
            //     WITH SECURITY_ENFORCED
            //     LIMIT 1
            // ]
            // .WebStoreId;
            String webStoreId;
            if(!Test.isRunningTest())
            {
                webStoreId = [
                    SELECT WebStoreId
                    FROM WebStoreNetwork
                    WHERE NetworkId = :communityId
                    WITH SECURITY_ENFORCED
                    LIMIT 1
                ]
                    .WebStoreId;
            }
            else if(Test.isRunningTest())
            {
                webStoreId = [
                    SELECT Id
                    FROM WebStore
                    ORDER BY CREATEDDATE DESC 
                    LIMIT 1
                ].Id;
            }
            communityIdToWebStoreIdCache.put(communityId, webStoreId);
            return webStoreId;
        }
    }
    /**
* @description  get  domain site by name
* @author Vipul | 09-21-2023 
* @param siteName 
* @return DomainSite 
**/
    public static DomainSite fetchBaseSiteURL(String siteName){
        return Test.isRunningTest() ?  [SELECT Id, Domain.domain, Site.Name, PathPrefix, CreatedDate FROM DomainSite Where Site.Name = :siteName LIMIT 1]  :  [SELECT Id, Domain.domain, Site.Name, PathPrefix, CreatedDate FROM DomainSite Where Site.Name = :siteName AND  Domain.domain=:System.Label.ECOM_CommunityDomainName LIMIT 1] ;
    }
    
    /** 
* @description  This method is used to generate request map for REST Service callout.
* @author mkumar@rafter.one | 07-28-2023 
* @param requestBody 
* @return Map<String, String> 
**/
    public static Map<String, String> generateRequestMap(String requestBody, String actionType){
        
        Map<String, String> requestMap = new Map<String, String>();
        requestMap.put(ECOM_Constant.HTTP_REQUEST_TYPE, ECOM_Constant.HTTP_REQUEST_POST);
        requestMap.put(ECOM_Constant.HTTP_REQUEST_BODY, requestBody);
        requestMap.put(ECOM_Constant.ACTION_TYPE, actionType);
        
        return requestMap;
    }
    
    /**
* @description //Method to get user's country 
* @author Vipul Goyal | 10-21-2023 
* @param us 
* @return String 
**/
    public static String getCountryFromUser(User us)
    {
        return us.Contact.ECOM_CountryProvided__c;
    }
    
    /**
* @description  Parse ConnectApi.CartSummary data from Connect API to ECOM_DataLayerModel 
* @author mkumar@rafter.one | 09-21-2023 
* @param activeCarts 
* @return Map<String,Object> 
**/
    
    public static Map<String,Object> parseDataLayerModel(List<WebCart> activeCarts){
        Map<String,Object> resultMap = new Map<String,Object>(); //RWPS-3811
        Map<String,String> freeItemMap = new Map<String,String>(); //RWPS-3811
        Map<String,ECOM_DataLayerModel> productToDataLayerMap =  new Map<String,ECOM_DataLayerModel>();
        if(activeCarts.size() ==0){
            return productToDataLayerMap;
        }
        WebCart cart = activeCarts.get(0);
        for(CartItem item : cart.CartItems){
            ECOM_DataLayerModel dataLayerModel = new ECOM_DataLayerModel();
            dataLayerModel.id = item.Product2Id;
            dataLayerModel.name = item.Product2.Name;
            dataLayerModel.currencyCode = cart.currencyIsoCode;
            dataLayerModel.partNumber = item.Product2.Part_Number__c;
            dataLayerModel.type = item.Product2.Product_Type__c;
            dataLayerModel.productClass = item.Product2.IGOR_Item_Class_Desc__c;
            dataLayerModel.bussinessUnit = item.Product2.Business_Unit__c;
            dataLayerModel.subBussinessUnit = item.Product2.Sub_Business_Unit__c;
            dataLayerModel.superBussinessUnit = item.Product2.Super_Business_Unit__c;
            dataLayerModel.discountType = item.Product2.Discount_Type__c;
            dataLayerModel.productLine = item.Product2.Product_Line__c;
            dataLayerModel.productLineName = item.Product2.Product_Line_Name__c;
            dataLayerModel.quantity =  Integer.valueOf(item.quantity);
            dataLayerModel.price =  item.salesPrice;
            dataLayerModel.listPrice =  item.listPrice;
            dataLayerModel.partType =  item.Product2.Part_Type__c;
            dataLayerModel.paccode = item.Product2.IGOR_PAC__c;
            dataLayerModel.igorDescription = item.Product2.IGOR_Description__c;
            dataLayerModel.freeItemParent = item.ecom_parent_item__c; //RWPS-3811
            productToDataLayerMap.put(item.Product2Id, dataLayerModel);
            if(String.isNotEmpty(item.ecom_parent_item__c)) {
                freeItemMap.put(item.id, item.Product2.Part_Number__c); //RWPS-4194
            }
        }
        resultMap.put('productToDataLayerMap', productToDataLayerMap);// RWPS-3811
        if(!freeItemMap.isEmpty()) {
            resultMap.put('freeItemMap', freeItemMap);
        }
        return resultMap;
    }
    
    /**
* @description  Parse products data to ECOM_DataLayerModel 
* @author mkumar@rafter.one | 11-08-2023 
* @param products 
* @return Map<String,ECOM_DataLayerModel> 
**/
    public static Map<String,ECOM_DataLayerModel> parseProductDataLayerModel(List<Product2> products){
        Map<String,ECOM_DataLayerModel> productToDataLayerMap =  new Map<String,ECOM_DataLayerModel>();
        if( products==null && products.isEmpty()){
            return productToDataLayerMap;
        }
        for(Product2 product : products){
            ECOM_DataLayerModel dataLayerModel = new ECOM_DataLayerModel();
            dataLayerModel.id = product.Id;
            dataLayerModel.name = product.Name;
            dataLayerModel.partNumber = product.Part_Number__c;
            dataLayerModel.type = product.Product_Type__c;
            dataLayerModel.productClass = product.IGOR_Item_Class_Desc__c;
            dataLayerModel.bussinessUnit = product.Business_Unit__c;
            dataLayerModel.subBussinessUnit = product.Sub_Business_Unit__c;
            dataLayerModel.superBussinessUnit = product.Super_Business_Unit__c;
            dataLayerModel.discountType = product.Discount_Type__c;
            dataLayerModel.productLine = product.Product_Line__c;
            dataLayerModel.productLineName = product.Product_Line_Name__c;
            dataLayerModel.partType =  product.Part_Type__c;
            dataLayerModel.paccode = product.IGOR_PAC__c;
            dataLayerModel.igorDescription = product.IGOR_Description__c;
            productToDataLayerMap.put(product.id, dataLayerModel);
        }
        return productToDataLayerMap;
    }
    
    /**
* @description  Parse orders data  to ECOM_DataLayerModel 
* @author mkumar@rafter.one | 09-21-2023 
* @param orders 
* @return ECOM_DataLayerModel 
**/
    
    public static Map<String,ECOM_DataLayerModel> parseOrderDataLayerModel(List<Order> orders){
        Map<String,ECOM_DataLayerModel> productToDataLayerMap =  new Map<String,ECOM_DataLayerModel>();
        if(orders.size() ==0){
            return productToDataLayerMap;
        }
        Order fetchedOrder = orders.get(0);
        for(OrderItem item : fetchedOrder.OrderItems){
            ECOM_DataLayerModel dataLayerModel = new ECOM_DataLayerModel();
            dataLayerModel.id = item.Product2Id;
            dataLayerModel.name = item.Product2.Name;
            dataLayerModel.currencyCode = fetchedOrder.currencyIsoCode;
            dataLayerModel.partNumber = item.Product2.Part_Number__c;
            dataLayerModel.type = item.Product2.Product_Type__c;
            dataLayerModel.productClass = item.Product2.IGOR_Item_Class_Desc__c;
            dataLayerModel.bussinessUnit = item.Product2.Business_Unit__c;
            dataLayerModel.subBussinessUnit = item.Product2.Sub_Business_Unit__c;
            dataLayerModel.superBussinessUnit = item.Product2.Super_Business_Unit__c;
            dataLayerModel.discountType = item.Product2.Discount_Type__c;
            dataLayerModel.productLine = item.Product2.Product_Line__c;
            dataLayerModel.productLineName = item.Product2.Product_Line_Name__c;
            dataLayerModel.quantity =  Integer.valueOf(item.quantity);
            dataLayerModel.price =  item.UnitPrice;
            dataLayerModel.listPrice =  item.ListPrice;
            dataLayerModel.totalPrice =  item.TotalPrice;
            dataLayerModel.partType =  item.Product2.Part_Type__c;
            dataLayerModel.paccode = item.Product2.IGOR_PAC__c;
            dataLayerModel.igorDescription = item.Product2.IGOR_Description__c;
            dataLayerModel.freeItemParent = item.ecom_parent_item__c; //RWPS-3811
            productToDataLayerMap.put(item.Product2Id, dataLayerModel);
        }
        return productToDataLayerMap;
    }
    
    @AuraEnabled
    public static Map<String,Object> getOneTrustInfo(Boolean isGuest){
        Map<String,Object> response=new Map<String,Object>();
        response.put('isSuccess',false);
        response.put('isAnonymous',true);
        String guId = '';
        if(!isGuest)
        {
            guId=ECOM_EncryptUtil.encryptWithAES256(UserInfo.getUserId());
            response.put('isAnonymous',false);
        }
        response.put('guid',guId);
        response.put('token',createJwtToken(isGuest));
        
        List<ECOM_OneTrust__mdt> oneTrustScripts = ECOM_CustomMetadataService.getOneTrustScripts();
        Map<Integer,Map<String,String>> oneTrustMap=new Map<Integer,Map<String,String>>();
        
        for(ECOM_OneTrust__mdt ot : oneTrustScripts)
        {
            Map<String,String> tempMap = new Map<String,String>();
            if(oneTrustMap.containsKey(Integer.valueOf(ot.Order__c)))
            {
                tempMap = oneTrustMap.get(Integer.valueOf(ot.Order__c));
            }
            tempMap.put(ot.Key__c,ot.Value__c);
            oneTrustMap.put(Integer.valueOf(ot.Order__c),tempMap);
        }
        
        response.put('otScripts',oneTrustMap);
        response.put('isSuccess',true);
        return response;
    }
    
    public static String createJwtToken(Boolean isGuest)
    {
        Map<String,String> headerMap=new Map<String,String>();
        headerMap.put('alg','HS256');
        headerMap.put('typ','JWT');
        
        Map<String,Object> payloadMap=new Map<String,Object>();
        if(!isGuest)
        {
            payloadMap.put('sub',ECOM_EncryptUtil.encryptWithAES256(UserInfo.getUserId()));
        }
        else {
            payloadMap.put('sub','');
        }
        payloadMap.put('iat',DateTime.now());
        
        return getJwtToken(JSON.serialize(headerMap),JSON.serialize(payloadMap));
        
    }
    
    public static String getJwtToken(String header,String payload)
    {
        string jwt = base64URLencode(blob.valueof(header)) + '.' +base64URLencode(blob.valueof(payload));
        List <C_META_Storefront_Configuration__mdt> oneTrust = new List <C_META_Storefront_Configuration__mdt>();
        if(!Test.isRunningTest()){
            oneTrust=[Select Id,masterlabel,DeveloperName,Value__c 
                      from C_META_Storefront_Configuration__mdt 
                      where DeveloperName='OneTrust_PrivateKey' and ModuleName__c='Cookie'];
        }
        else{
            C_META_Storefront_Configuration__mdt item = new C_META_Storefront_Configuration__mdt();
            item.Value__c='TestClassValue';
            oneTrust.add(item);
        }
        
        
        Blob key = blob.valueof(oneTrust[0].Value__c);
        Blob signature = Crypto.generateMac('hmacSHA256',Blob.valueof(jwt),key);
        
        return jwt +'.'+base64URLencode(signature);
        
    }
    
    public static String base64URLencode(Blob input){ 
        String output = encodingUtil.base64Encode(input);
        output = output.replace('+', '-');
        output = output.replace('/', '_');
        while ( output.endsWith('=')){
            output = output.subString(0,output.length()-1);
        }
        return output;
    }

    /**
    * @description Get CMS Base Url for pdp url
    * @author vramachandran@rafter.one | 09-21-2023 
    * @param moduleName 
    * @return String 
    **/
    public static String getCmsBaseUrl(String moduleName, String userLocale){
        String cmsPdpUrl = '';
        Map<String, String> storeConfigMap = fetchStorefrontFrontConfigByModule(moduleName);
        if(null != storeConfigMap){
            cmsPdpUrl = storeConfigMap.get('Home_'+ userLocale.replace('-','_'));
        }
        return cmsPdpUrl;
    }
    
    /**
    * @description Get store navigation metadata
    * @author vramachandran@rafter.one | 09-21-2023 
    * @param moduleName 
    * @return ECOM_Store_Punchout_Configuration__mdt  
    **/
    public static Map<String,Object>  getStoreNavigationConfigMap(String labelName, String userType){
        Map<String,Object> configMap = new Map<String,Object>();
        System.debug('labelName:: '+ labelName);
        ECOM_Store_Punchout_Configuration__mdt  storeConfig = Test.isRunningTest() ? ECOM_TestUtil.getPunchoutStoreConfig() : [SELECT Id, Value_Rt__c FROM ECOM_Store_Punchout_Configuration__mdt  WHERE MasterLabel =:labelName LIMIT 1 ];
        
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
    * @description Get store navigation metadata String
    * @author vramachandran@rafter.one | 09-21-2023 
    * @param moduleName 
    * @return ECOM_Store_Punchout_Configuration__mdt  
    **/
    public static String  getStoreNavigationConfig(String labelName){
        String configJSON;
        System.debug('labelName:: '+ labelName);
        ECOM_Store_Punchout_Configuration__mdt  storeConfig = Test.isRunningTest() ? ECOM_TestUtil.getPunchoutStoreConfig() : [SELECT Id, Value_Rt__c FROM ECOM_Store_Punchout_Configuration__mdt  WHERE MasterLabel =:labelName LIMIT 1 ];
        
        if(null != storeConfig && String.isNotEmpty(storeConfig.Value_Rt__c)){
			configJSON = storeConfig.Value_Rt__c;
        }
        return configJSON;
    }
    
    
    /**
    * @description This method is used to convert a list into comma-separated string that can be used in queries.
    * @author Vipul Goyal | 04-23-2024 
    * @param values 
    * @param valueString 
    * @return String 
    **/
    public static String convertListToQueryString(List<String> values,String valueString)
    {
        for(String value:values)
        {
            if(String.isNotBlank(valueString))
            {
                valueString+=',';
            }
            valueString+='\''+value+'\'';  
        }
        return valueString;
    }
    
    /**
    * @description Get store site Url List<String>
    * @author manish.joshi@revvity.com | 2024-05-07 
    * @param  
    * @return List<String>  
    **/
    public static List<String> getSiteDetails() {
     List<String> siteData = new List<String>();
     List<Network> networks = ECOM_WebStoreRepo.getNetworks(Label.ECOM_WebStore_Name);
        if (!networks.isEmpty()) {
            List<Site> sites =  ECOM_WebStoreRepo.getSites(networks.get(0).UrlPathPrefix);
            if (!sites.isEmpty()) {
                List<SiteDetail> siteDetails = ECOM_WebStoreRepo.getSiteDetails(sites.get(0).Id);
                if (!siteDetails.isEmpty()) {
                    String url = siteDetails.get(0).SecureURL;
                    if(!String.isBlank(url))
                    {
                        List<String> urlSplit = url.split('/vforcesite');
                        url = urlSplit.get(0);
                        siteData.add(url);
                    }
                }
            }
        }
        return siteData;
    }

/**
     * @description This method check required field and log error on server side
    * @author Poonam Shukla | 2025.11.25
    * @params componentName | String
    * @params moduleName | String
    * @params methodName | String
    * @params fieldName | String
    * @params fieldValue | Object
    * @params supportData | String
    * @return void
    **/
    @AuraEnabled
    public static void logFieldError(String componentName, String moduleName, String methodName, String fieldName, Object fieldValue, String supportData) {
        Boolean isValid = true;
        
        if (fieldValue == null || fieldValue instanceof String && String.isBlank((String)fieldValue)) {
            isValid = false;
        } 
        if (!isValid) {
            String errorMessage = System.Label.ECOM_RequiredFieldLogStart + ' ' + fieldName + ' ' + System.Label.ECOM_RequiredFieldLogEnd;
            ECOM_ApplicationLogsUtil.logApplicationApiData( moduleName, componentName, methodName, supportData, errorMessage);
        }
    }

    /**
     * @description This method store js error in Ecom Application log
    * @author Poonam Shukla | 2025.11.25
    * @params fileName | String
    * @params moduleName | String
    * @params methodName | String
    * @params supportData | String
    * @return void
    **/
    @AuraEnabled
    public static void logJsFailure( String fileName, String moduleName, String methodName, String supportData) {
        ECOM_ApplicationLogsUtil.logJsFailure(fileName, moduleName, methodName, supportData);
    }

    /*
    * @description This method retrieves Punchout email configuration details based on the provided ERP Master Address Id. 
    * @author Poonam Shukla | 2026.02.27
    * @params masterId | String | 
    * @return Map<String, String> 
    **/
    public static Map<String, String> getPunchoutEmailDetails(String masterId) {
        
        Map<String, String> emailDetails = new Map<String, String>();
        if (String.isBlank(masterId)) {
            return emailDetails;
        }
        List<Punchout_Maintenance__c> punchoutRec = ERP_AddressRepo.getPunchoutConfigBasedOnMaster(masterId);
        if (punchoutRec != null && !punchoutRec.isEmpty()) {
            emailDetails.put('additionalEmails', punchoutRec[0].Ecom_Punchout_Additional_Email_Address__c);
            emailDetails.put('selectedEmailType', punchoutRec[0].ECOM_Punchout_User_Email__c);
        }
        return emailDetails;
    }

 /**
 * @description Retrieves excluded part numbers for Punchout users based on input part numbers.
 * @author Poonam Shukla | 2026.02.27
 * @param partNumbers Set<String>
 * @return Set<String>
 **/
public static Set<String> getExcludedPartNumbersForPunchout(Set<String> partNumbers) {

    Set<String> excludedPartNumbersSet = new Set<String>();
    if (partNumbers == null || partNumbers.isEmpty()) {
        return excludedPartNumbersSet;
    }
    List<Network> networks = ECOM_WebStoreRepo.getNetworks(Label.ECOM_WebStore_Name);
    if (!networks.isEmpty()) {
        List<String> excludedList = ECOM_ProductService.getExcludedPartNumbers(networks[0].Id, new List<String>(partNumbers));
        excludedPartNumbersSet.addAll(excludedList);
    }

    return excludedPartNumbersSet;
}


/**RWPS-6037
* @description Checks whether a configured validation message from Custom Metadata
*              exists within the input message and returns INFO if found,
*              otherwise returns ERROR by default.
 * @author Poonam Shukla | 2026.04.10
 * @param message String
 * @return String
 **/
public static String getSeverityByMessage(String message) {

    // Default severity
    String severity = 'ERROR';

    if (String.isBlank(message)) {
        return severity;
    }

    String jsonConfig =ECOM_CustomMetadataService.getStoreConfigurationByLabel(ECOM_Constant.ECOM_LOG_INFO_MESSAGES);

    if (String.isBlank(jsonConfig)) {
        return severity;
    }

    Map<String, Object> parsedJson = (Map<String, Object>) JSON.deserializeUntyped(jsonConfig);

    if (!parsedJson.containsKey('messages')) {
        return severity;
    }

    List<Object> configuredMessages = (List<Object>) parsedJson.get('messages');

    for (Object msg : configuredMessages) {
        if (msg != null &&message.toLowerCase().contains(String.valueOf(msg).toLowerCase())) {
            return 'INFO';
        }
    }
    return severity;
}
}