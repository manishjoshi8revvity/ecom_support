/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    RWPS-667
*
* 2. Description - This class is used for Punchout Login logic.
*
*
*
* 3. Objects referenced
*    -None
*
* 4. Callouts to additional Components (including their methods) or None:
*    - 
*
* 5. Dependant Class(es):
*    - 
*
* 6. Test Class Name: 
*    - 
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Sidak 2024.05.13
*    - Manish 2024.09.19 RWPS-1256 punchout architecture is changed & new implementation is done using new methods getPunchoutMasterFromCustomerId,
*      getPunchoutAddressFromMaster, gePunchoutAddress, validatePunchoutConfiguration, validatePunchoutPartnerFunctions, updateUserAsPunchoutUserOrContact,
*      getContactRecordForEmail1, getContactForEmail1,getAccount,createPOSRModelForRevvityPunchoutForNewUser1
*    - Sidak 2024.10.29 Removed update statements for Contact & User. RWPS-1671
*    - Manoj 2024.12.17 RWPS-1923 Punchout request from blank user email
*    - Poonam 2025.9.12 Updated method getPunchoutAddressesForERPMasterAddressId, getERPMasterAddressForPunchoutAccountId - RWPS-4363.
*    - Manish Joshi 2026.02.03 Updated method gePunchoutAddress, getPunchoutAddressesForAccountId, validatePunchoutConfiguration , validatePunchoutPartnerFunctions - RWPS-5776
*    - Kushal Shah 2026.03.12 Updated method getPunchoutAddressesForAccountId - RWPS-6851
*    - Kushal Shah 2026.03.13 Updated method getPunchoutAddressesForAccountId - RWPS-6917
*    - Princy Anthony 2026.04.07 Updated method getAddressModel - RWPS-7243
*************************************************************/
public without sharing class ECOM_PunchoutLoginService {
    
    final static String CLASSNAME = 'ECOM_PunchoutLoginService';

    /**
    * @description This method returns the decrypted base64 EncyptedString
    * @author vramachandran@rafter.one | 05 Jan 2024
    * @param plainText | String 
    * @return String
    */
    public static String decryptWithBase64(String encryptedText){
        Blob decryptedBlob;
        String decryptedString = encryptedText;
        
        try{
            decryptedBlob = EncodingUtil.base64Decode(encryptedText);
            if(decryptedBlob != null){
                decryptedString = decryptedBlob.toString();
            }
            System.debug('decryptedString:: '+ decryptedString);
        }catch(Exception e){
            //ECOM_ApplicationLogsUtil.logFailure(e, ECOM_Constant.USER_MODULE_NAME, className, 'encryptWithBase64', 'Message:: '+ e.getMessage()+ 'stack trace:: ' + e.getStackTraceString());
        }
        
        return decryptedString;
    }

    public static ECOM_PunchoutWrapper.PunchoutServiceRequest createPOSRModelForRevvityPunchoutForNewUser(){

        ECOM_PunchoutWrapper.PunchoutServiceRequest requestModel = new ECOM_PunchoutWrapper.PunchoutServiceRequest();

        String testUserConfig = getStoreNavigationConfig(System.Label.ECOM_TestUserConfigMetadata);

        //List<User> userRecords = [SELECT Id, Username, Email FROM USER WHERE ECOM_Is_Punchout_User__c = true ORDER BY CreatedDate DESC LIMIT 1];

        if(String.isNotEmpty(testUserConfig)){
            requestModel = (ECOM_PunchoutWrapper.PunchoutServiceRequest) JSON.deserialize(testUserConfig, ECOM_PunchoutWrapper.PunchoutServiceRequest.class);
            requestModel.fromCredentialDomain = 'RVTYPNCHOUT';
            requestModel.toCredentialDomain = 'RVTYPNCHOUT';
            requestModel.fromCredentialIdentity = 'RVTYPNCHOUT';
            requestModel.firstName = 'NewUser';
            requestModel.lastName = 'Test';
            //if(null == userRecords && userRecords.isEmpty()){
            requestModel.userEmail = String.valueOf(System.now().millisecond()) + '@RevvityPunchout.xyz' ;
            //requestModel.userEmail = 'testpunchout@RevvityPunchout.xyz' ;
            //} else {
            //    requestModel.userEmail = userRecords[0].Email;
            //}

            requestModel.locale = 'en_US';
            requestModel.timezoneSidKey = 'America/New_York';
            requestModel.supplierPartId = '123123';
            requestModel.selectedItem ='123444';

        }

        return requestModel;
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
        ECOM_Store_Punchout_Configuration__mdt  storeConfig = Test.isRunningTest() ? getPunchoutStoreConfig() : [SELECT Id, Value_Rt__c FROM ECOM_Store_Punchout_Configuration__mdt  WHERE MasterLabel =:labelName LIMIT 1 ];
        
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
        ECOM_Store_Punchout_Configuration__mdt  storeConfig = Test.isRunningTest() ? getPunchoutStoreConfig() : [SELECT Id, Value_Rt__c FROM ECOM_Store_Punchout_Configuration__mdt  WHERE MasterLabel =:labelName LIMIT 1 ];
        
        if(null != storeConfig && String.isNotEmpty(storeConfig.Value_Rt__c)){
			configJSON = storeConfig.Value_Rt__c;
        }
        return configJSON;
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
     * @description Fetch Product Sales records, for punchout
     * @author vramachandran@rafter.one | 24 Jan 2024 
     * @param prodIds 
     * @param materialCodes 
     * @return List<Product_Sales__c> 
     **/
    public static List<Product_Sales__c> getProductSales(String materialCode, String salesOrg){
        List<String> validDistributionStatus = System.Label.ECOM_ValidDistributionChainSpecificMaterialStatus.split(',');
        System.debug('validDistributionStatus:: '+ validDistributionStatus + ' salesOrg:: '+ salesOrg);
        List<Product_Sales__c> prodSales = [SELECT Id, Distribution_ChainSpecificMaterialStatus__c, Product__c, Product__r.Part_Number__c  
                                            FROM Product_Sales__c
                                            WHERE Product__r.Part_Number__c =: materialCode 
                                            AND Sales_Org__c = :salesOrg 
                                            AND Distribution_ChainSpecificMaterialStatus__c IN :validDistributionStatus 
                                            LIMIT 1];
        return prodSales ;
    }

    /**
    * @description prepares request header and body for password reset callout
    * @author vramchandran@rafter.one | 07 Jan 2024
    * @param parameterMap | Map<String,String> 
    * @return Map<String,String> 
    **/
    public static Map<String,String> prepareRequestForTestUserPasswordReset(String requestBody){
        Map<String,String> requestHeader = new Map<String,String>();
		
		DomainSite siteDomain = fetchBaseSiteURL(System.Label.ECOM_SiteName);
        String storeLoginUrl = System.Label.ECOM_HTTPS_Prefix  + siteDomain.Domain.domain + System.Label.ECOM_ResetPasswordEndpoint;//'https://revvity--punchout.sandbox.my.site.com' + '/services/apexrest/provisionpouser';
        requestHeader.put(ECOM_Constant.REQUEST_METHOD_TYPE, ECOM_Constant.HTTP_REQUEST_POST);
        requestHeader.put(ECOM_Constant.HTTP_CONTENT_TYPE, ECOM_Constant.HTTP_CONTENT_APP_JSON);
        requestHeader.put(ECOM_Constant.HTTP_REQUEST_ENDPOINT, storeLoginUrl);
        requestHeader.put(ECOM_Constant.HTTP_REQUEST_BODY, requestBody);
        
        System.debug('requestHeader:: '+ JSON.serialize(requestHeader));
        return requestHeader;
    }

    /**
    * @description  get  domain site by name
    * @author Vipul | 09-21-2023 
    * @param siteName 
    * @return DomainSite 
    **/
    public static DomainSite fetchBaseSiteURL(String siteName){
        return Test.isRunningTest()? [SELECT Id, Domain.domain, Site.Name, PathPrefix, CreatedDate FROM DomainSite Where Site.Name = :siteName LIMIT 1]:  [SELECT Id, Domain.domain, Site.Name, PathPrefix, CreatedDate FROM DomainSite Where Site.Name = :siteName AND  Domain.domain=:System.Label.ECOM_CommunityDomainName LIMIT 1] ;
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
     * @description fetch punchout user and related account information for a given userId
     * @author vramachandran@rafter.one | 11 Dec 2023
     * @param userName | String
     * @return List<User>
     */
    public static List<User> getPunchoutUserInformationByUserName(String userName){
        return [SELECT Id, Name, FirstName, Lastname, Phone, Fax, Email, ContactId, Contact.Name, Contact.AccountId, Contact.fxDomain__c, Account.Name, 
                Contact.ECOM_NeedsVerification__c, Contact.ECOM_Is_Mapped__c, Contact.ECOM_CountryProvided__c, Contact.ECOM_AddressRegistration__c, 
                Contact.Phone, Contact.ECOM_Phone_Extension__c, Contact.ECOM_DefaultShipToAccount__c, Contact.FirstName, Contact.LastName,
                Contact.ECOM_Delivery_Details__c, Contact.ECOM_Special_Instructions__c, Contact.ECOM_Attention_Recipient__c,Contact.ECOM_DefaultBillToAccount__c, 
                AccountId, Contact.ECOM_DefaultShipToCPA__c, Contact.ECOM_DefaultBillToCPA__c, Contact.ECOM_Country_Phone_Code__c, UserRole.Name,
                ECOM_Phone_Extension__c, ECOM_Country_Phone_Code__c, 
                Account.SAP_Customer_Number_Formatted__c, Account.RAD_Identifier__c,Account.ShippingCountry,
                Account.ECOM_PO_Display_List_Price__c, Account.ECOM_Is_Punchout_Account__c, Account.ECOM_PO_Product_Catalog_Exclude_Query__c, Account.ECOM_PO_Product_Catalog_Include_Query__c, 
                Account.ECOM_Punchout_Company_Name__c, Account.ECOM_Punchout_Customer_Org_Logo__c, Account.ECOM_Punchout_CXML_Or_OCI__c, Account.ECOM_Punchout_Description__c, 
                Account.ECOM_Punchout_Domain__c, Account.ECOM_Punchout_Platform_Name__c, Account.ECOM_Punchout_UOM__c,
                Contact.Default_Bill_to_ERP_Address__c, Contact.Default_Ship_to_ERP_Address__c,Contact.Default_Sold_to_ERP_Address__c,
                Contact.Default_Bill_to_ERP_Address__r.ERP_Account_Name__c, Contact.Default_Bill_to_ERP_Address__r.Account__c, Contact.Default_Bill_to_ERP_Address__r.Account__r.Name, 
                Contact.Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c,    
                Contact.Default_Bill_to_ERP_Address__r.fxAddress_City__c,
                Contact.Default_Bill_to_ERP_Address__r.fxAddress_CountryCode__c, 
                Contact.Default_Bill_to_ERP_Address__r.fxAddress_Postal__c, 
                Contact.Default_Bill_to_ERP_Address__r.fxAddress_StateName__c, 
                Contact.Default_Bill_to_ERP_Address__r.fxAddress_Street__c,
                Contact.Default_Bill_to_ERP_Address__r.Master_Address__r.External_Id__c,
                Contact.Default_Bill_to_ERP_Address__r.ECOM_Review_Status__c,
                Contact.Default_Ship_to_ERP_Address__r.ERP_Account_Name__c, Contact.Default_Ship_to_ERP_Address__r.Account__c, Contact.Default_Ship_to_ERP_Address__r.Account__r.Name,
                Contact.Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c,    
                Contact.Default_Ship_to_ERP_Address__r.fxAddress_City__c,
                Contact.Default_Ship_to_ERP_Address__r.fxAddress_CountryCode__c, 
                Contact.Default_Ship_to_ERP_Address__r.fxAddress_Postal__c, 
                Contact.Default_Ship_to_ERP_Address__r.fxAddress_StateName__c, 
                Contact.Default_Ship_to_ERP_Address__r.fxAddress_Street__c,
                Contact.Default_Ship_to_ERP_Address__r.Master_Address__r.External_Id__c,
                Contact.Default_Ship_to_ERP_Address__r.ECOM_Review_Status__c,
                Contact.Default_Ship_to_ERP_Address__r.RAD_Identifier__c,
                Contact.Default_Sold_to_ERP_Address__r.ERP_Account_Name__c, Contact.Default_Sold_to_ERP_Address__r.Account__c, Contact.Default_Sold_to_ERP_Address__r.Account__r.Name,
                Contact.Default_Sold_to_ERP_Address__r.Target_Address__r.External_Id__c,    
                Contact.Default_Sold_to_ERP_Address__r.fxAddress_City__c,
                Contact.Default_Sold_to_ERP_Address__r.fxAddress_CountryCode__c, 
                Contact.Default_Sold_to_ERP_Address__r.fxAddress_Postal__c, 
                Contact.Default_Sold_to_ERP_Address__r.fxAddress_StateName__c, 
                Contact.Default_Sold_to_ERP_Address__r.fxAddress_Street__c,
                Contact.Default_Sold_to_ERP_Address__r.Master_Address__r.External_Id__c,
                Country,
            	UserName, ECOM_Is_Punchout_User__c
                FROM User 
                WHERE UserName =:userName
				AND ECOM_Is_Punchout_User__c = true
                LIMIT 1 ];
    }

    public static ECOM_PunchoutWrapper.PunchoutServiceRequest createPOSRModelForRevvityPunchoutForExistingUser(){

        User userRecord = [SELECT Id, FirstName, LastName, Email, UserName
                           FROM User
                           ORDER BY CREATEDDATE DESC
                           LIMIT 1];
        ECOM_PunchoutWrapper.PunchoutServiceRequest requestModel = new ECOM_PunchoutWrapper.PunchoutServiceRequest();

        String testUserConfig = getStoreNavigationConfig(System.Label.ECOM_TestUserConfigMetadata);

        if(String.isNotEmpty(testUserConfig)){
            requestModel = (ECOM_PunchoutWrapper.PunchoutServiceRequest) JSON.deserialize(testUserConfig, ECOM_PunchoutWrapper.PunchoutServiceRequest.class);
            requestModel.fromCredentialDomain = 'RVTYPNCHOUT';
            requestModel.toCredentialDomain = 'RVTYPNCHOUT';
            requestModel.fromCredentialIdentity = 'RVTYPNCHOUT';
            requestModel.firstName = userRecord.FirstName;
            requestModel.lastName = userRecord.LastName;
            requestModel.userEmail = userRecord.Email;

        }

        return requestModel;
    }

    /**
    * @description prepares request header and body for login callout
    * @author vramchandran@rafter.one | 11-22-2023 
    * @param User 
    * @return String 
    **/
    public static Map<String,String> preparePunchoutLoginRequest(Map<String,String> parameterMap){
        Map<String,String> requestHeader = new Map<String,String>();
        
		String parameterString = '?';
        System.debug('preparePunchoutLoginRequest:: '+ parameterMap);
        for(String key : parameterMap.KeySet()){
            if(null != parameterMap.get(key)){
                parameterString += parameterString.endsWith('?') ? (key +'='+ EncodingUtil.urlEncode(String.valueOf(parameterMap.get(key)),'UTF-8')) : 
            	('&' + key +'='+ EncodingUtil.urlEncode(String.valueOf(parameterMap.get(key)),'UTF-8'));
            }
        }
        
        //Prepare header, body and perform rest callout        
        //bodyMap.put(ECOM_Constant.GRANT_TYPE, ECOM_Constant.GRANT_TYPE_CLIENT_CREDENTIALS);
		//bodyMap.putAll(parameterMap);
        String baseUrl = getEcomSiteBaseUrl();
        String storeLoginUrl = baseUrl + System.Label.ECOM_TestUserLoginEndpoint  + parameterString;
        System.debug('storeLoginUrl:: '+ storeLoginUrl);
        requestHeader.put(ECOM_Constant.REQUEST_METHOD_TYPE, ECOM_Constant.HTTP_REQUEST_POST);
        requestHeader.put(ECOM_Constant.HTTP_CONTENT_TYPE, ECOM_Constant.HTTP_CONTENT_FORM_URLENCODED);
        requestHeader.put(ECOM_Constant.HTTP_REQUEST_ENDPOINT, storeLoginUrl);
        requestHeader.put(ECOM_Constant.HTTP_CONTENT_LENGTH, String.valueOf(0));
        
        return requestHeader;
    }

    /**
    * @description prepares request header and body for password reset callout
    * @author vramachandran@rafter.one | 02 Jan 2024 
    * @return String 
    **/
    public static String getEcomSiteBaseUrl(){
        String baseStoreUrl;
        
        DomainSite siteDomain= fetchBaseSiteURL(System.Label.ECOM_SiteName);
        if(null != siteDomain){
            baseStoreUrl= System.Label.ECOM_HTTPS_Prefix  + siteDomain.Domain.domain ;//'https://revvity--punchout.sandbox.my.site.com' + '/services/apexrest/provisionpouser';    
        }
        return baseStoreUrl;
    }

    /**
     * @description This method returns a new Punchout store configuration for different users
     * @author vramachandran@rafter.one | 05 Feb 2024
     * @returns ECOM_Store_Punchout_Configuration__mdt
     */
    public static ECOM_Store_Punchout_Configuration__mdt getPunchoutStoreConfig(){
        ECOM_Store_Punchout_Configuration__mdt punchoutMetadata = new ECOM_Store_Punchout_Configuration__mdt();
        punchoutMetadata.Value_Rt__c = '{"punchoutUser":{"viewProfileSettingPage":false,"viewDashboard":false,"viewAccountPage":false,"viewOrderPage":true,"viewRecentOrders":false,"viewFavourites":true,"viewFrequentlyPurchased":true,"viewQuickOrder":true,"viewLogout":false,"isPunchoutUser":true,"storeForwardingUrl":"/createsession"},"punchoutUserWeb":{"viewProfileSettingPage":false,"viewDashboard":false,"viewAccountPage":false,"viewOrderPage":true,"viewRecentOrders":false,"viewFavourites":true,"viewFrequentlyPurchased":true,"viewQuickOrder":true,"viewLogout":true,"isPunchoutUser":true,"storeForwardingUrl":"/createsession"},"storeTestUser":{"viewProfileSettingPage":false,"viewDashboard":false,"viewAccountPage":false,"viewOrderPage":true,"viewRecentOrders":false,"viewFavourites":true,"viewFrequentlyPurchased":true,"viewQuickOrder":true,"viewLogout":false,"isPunchoutUser":true,"isStoreTestUser":true,"storeForwardingUrl":"/createsession"},"cmsStoreUser":{"viewProfileSettingPage":true,"viewDashboard":true,"viewAccountPage":true,"viewOrderPage":true,"viewRecentOrders":true,"viewFavourites":true,"viewFrequentlyPurchased":false,"viewQuickOrder":true,"viewLogout":true,"storeForwardingUrl":""}}' ;
        return punchoutMetadata;
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

    /* RWPS-5776 - START */
    /**
     * @description This method returns the ERP Address (Ship to, Sold to, Bill To, Payer) and the related target.master address for
     *  a punchout account Id 
     * @author vramachandran@rafter.one | 16 Jan 2024
     * @param poAccountUniqueName | String
     * @returns List<ERP_Address> 
     */
    /*public static ERP_AddressModel getPunchoutAddressesForAccountId(String poAccountId){
        ERP_AddressModel addressModel = new ERP_AddressModel();
        //RWPS-4363 start
        Map<String, ERP_Address__c> addressMap  = new Map<String, ERP_Address__c>();
        List<ERP_Address__c> masterAddressList = new List<ERP_Address__c>();
        masterAddressList= getERPMasterAddressForPunchoutAccountId(poAccountId);
        if(masterAddressList != null && !masterAddressList.isEmpty() && masterAddressList[0].Master_Address__r.ECOM_Punchout_Customer_Id__c != null) {
            ERP_Address__c masterAddress = masterAddressList[0];
            String customerId = masterAddress.Master_Address__r.ECOM_Punchout_Customer_Id__c;
            addressMap = ECOM_PunchoutLoginService.gePunchoutAddress(customerId);
            List<ERP_Address__c> erpMasterAddressList = new List<ERP_Address__c>(addressMap.values());
            addressModel = getAddressModel(erpMasterAddressList);
        }//RWPS-4363 end        
        return addressModel;
    }
    */
    /* RWPS-5776 - END */

    /**
     * @description This method loops through address list to build the addressmodel
     * @author vramachandran@rafter.one | 02 Jan 2024
     * @param erpAddressList | List<ERP_Address__c>
     * @returns ERP_AddressModel
     */

    public static ERP_AddressModel getAddressModel(List<ERP_Address__c> erpAddressList){
        ERP_AddressModel addressModel = new ERP_AddressModel();
        
        Map<String,ERP_AddressModel> addressMap = new Map<String, ERP_AddressModel>();
        String accountId;
        System.debug('erpAddressList:: '+ erpAddressList);
        System.debug('erpAddressListacc:: '+ erpAddressList[0].Account__c);
        
        for(ERP_Address__c erpAddress : erpAddressList){
            ERP_AddressModel currentModel = getAddressModelForRecord(erpAddress);
            System.debug('outside If CurrentModel:: '+ currentModel); 
            if(null != currentModel){
                addressMap.put(currentModel.addressType, currentModel);
            }
        }  
        System.debug('addressMap:: '+ JSON.serialize(addressMap));
        if(null != addressMap && !addressMap.isEmpty()){
            if(addressMap.containsKey(ECOM_Constant.ERP_ADDRESS_TYPE_MASTER)){
                addressModel = addressMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_MASTER);
                
                if(addressModel.addressType == ECOM_Constant.ERP_ADDRESS_TYPE_MASTER){
                    for(String addressType :  addressMap.keySet()){
                        
                        ERP_AddressModel currentModel = addressMap.get(addressType);

                        if(currentModel.addressType == ECOM_Constant.ERP_ADDRESS_TYPE_SHIP_TO){
                            addressModel.po_ShipToAddress = currentModel;
                        }//if soldto assign as po sold to on primary
                        else if(currentModel.addressType.equalsIgnoreCase(ECOM_Constant.ERP_ADDRESS_TYPE_SOLD_TO)){
                            addressModel.po_SoldToAddress = currentModel;
                        }//if payer assign as po payer to on primary
                        else if(currentModel.addressType == ECOM_Constant.ERP_ADDRESS_TYPE_PAYER){
                            addressModel.po_PayerAddress = currentModel;
                        }//if payer assign as po payer to on primary
                        else if(currentModel.addressType == ECOM_Constant.ERP_ADDRESS_TYPE_BILL_TO){
                            addressModel.po_BillToAddress = currentModel;
                        }
                        //check and populate accountid on master
                        if(String.isNotBlank(currentModel.accountId) && addressModel.accountId != currentModel.accountId){
                            addressModel.accountId =  currentModel?.accountId;
                        }
                        //check and populate currency iso code
                        if(String.IsNotBlank(currentModel?.po_CurrencyIsoCode)){
                            addressModel.po_CurrencyIsoCode = currentModel?.po_CurrencyIsoCode;
                        }
                    }
                }
            }
        }
        
        System.debug('addressModel : '+JSON.serialize(addressModel));

        return addressModel;
    }

    /**
     * @description This method maps the primary address fields for ERP_Address__c record
     * @author vramachandran@rafter.one | 23 Dec 2023
     * @param addressRecord | ERP_Address__c
     * @return ERP_AddressModel
     */
    public static ERP_AddressModel getAddressModelForRecord(ERP_Address__c addressRecord){
        ERP_AddressModel addressModel = new ERP_AddressModel();
        
        if(addressRecord != null){
        	
            
            //account information
            addressModel.id = addressRecord?.Id;
            addressModel.accountId = addressRecord?.Account__c;
            addressModel.accountGroup = addressRecord?.ERP_Account_Group__c;
            addressModel.erpAccountName = addressRecord?.ERP_Account_Name__c;
            addressModel.sapName = addressRecord?.ERP_Account_Name__c;
            addressModel.isEcomEnabled = addressRecord?.ECOM_isEnabled__c;
            addressModel.externalId = addressRecord?.ERP_Customer_Number__c;
            addressModel.showAccNumber = true;
            addressModel.ecomReviewStatus = addressRecord?.ECOM_Review_Status__c;
            
            //address information
            addressModel.addressType = addressRecord?.Address_Type__c;
            addressModel.street = addressRecord?.Address_Street_Line_1__c;
            addressModel.street2 = addressRecord?.Address_Street_Line_2__c;
            addressModel.city = addressRecord?.Address_City__c;
            addressModel.state = addressRecord?.Address_State__c;
            addressModel.country = addressRecord?.Address_Country__c;
            addressModel.postalCode = addressRecord?.Address_Postal_Code__c;
            if(String.isNotBlank(addressRecord?.Address_Type__c) && String.isNotBlank(addressRecord?.fxAddress_CountryName__c) && addressRecord?.Address_Type__c == System.Label.ECOM_ERPAddressTypeMaster){
                addressModel.po_CountryName = addressRecord?.fxAddress_CountryName__c;
            }
            
            //punchout config information
            // RWPS-5776 - START
            /*addressModel.po_AccountName = addressRecord?.ECOM_Punchout_Customer_Name__c;
            addressModel.po_AccountUrl = addressRecord?.ECOM_Punchout_Customer_Logo__c;
            addressModel.po_CustomerCode = addressRecord?.ECOM_Punchout_Customer_Id__c;
            addressModel.po_isPunchoutEnabled = addressRecord?.ECOM_Punchout_Is_Enabled__c;
            addressModel.po_ProductExcludeQuery = addressRecord?.ECOM_Punchout_Products_Exclude_Query__c;
            addressModel.po_ProductIncludeQuery = addressRecord?.ECOM_Punchout_Products_Include_Query__c;
            addressModel.po_ShowListPrice = addressRecord?.ECOM_Punchout_Show_List_Price__c;
            addressModel.po_UnitOfMeasure = addressRecord.ECOM_Punchout_Unit_Of_Measurement__c;
            addressModel.po_SenderSharedSecret = addressRecord?.ECOM_POSR_Sender_Shared_Secret__c;
            addressModel.po_SenderSharedIdent = addressRecord?.ECOM_POSR_Sender_Shared_Identity__c;
            addressModel.po_PunchoutResponseFormat = addressRecord?.ECOM_Punchout_Format__c;
            addressModel.po_TimeZone = addressRecord?.ECOM_Punchout_Account_TimeZone_SID__c;
            addressModel.po_Locale = String.isNotBlank(addressRecord?.ECOM_Punchout_Country_Locale__c) ? addressRecord?.ECOM_Punchout_Country_Locale__c  : '';
            */
            // RWPS-5776 - END
            if(String.isNotBlank(addressRecord?.Account__r.CurrencyIsoCode)){
                addressModel.po_CurrencyIsoCode =  addressRecord?.Account__r.CurrencyIsoCode ;
            }
            addressModel.po_CountryCode = addressRecord?.fxAddress_CountryCode__c;
            //addressModel.po_Processors = addressRecord?.ECOM_Punchout_Processors__c; //GAr ECOM-2100 , RWPS-5776
            //addressModel.po_DefaultUNSPSC = addressRecord?.ECOM_Punchout_Default_UNSPSC__c; //GAr RWPS-410 - mapping of new field as per requirement, RWPS-5776
        }

        return addressModel;
    }

    /**
     * @description This method returns the Master ERP Address information
     * @author vramachandran@rafter.one | 15 Jan 2024 //Valid
     * @param accountUniqueName | String 
     * @returns List<ERP_Address>
     */
    public static List<ERP_Address__c> getERPMasterAddressForPunchoutAccountId(String accountId){
        //RWPS-4363 Added ECOM_Punchout_Customer_Id__c in query
        return [SELECT id, Target_Address__c, Master_Address__c, Address_Type__c, fxAddress_CountryName__c, Master_Address__r.ECOM_Punchout_Customer_Id__c
                FROM ERP_Address__c 
                WHERE ERP_Marked_for_Deletion__c = false
                AND ECOM_Review_Status__c = 'Approved'
                AND fxIsECOMenabled__c = true
                //AND (RecordType.DeveloperName = 'Default' OR RecordType.DeveloperName = 'Staging')
                AND Account__c =: accountId
                AND ECOM_Punchout_Is_Enabled__c = true
                LIMIT 1];
    }

    /**
     * @description This method returns the ERP Address (Ship to, Sold to, Bill To, Payer) and the related target.master address for
     *  a punchout master address Id
     * @author vramachandran@rafter.one | 16 Jan 2024
     * @param poAccountUniqueName | String
     * @returns List<ERP_Address> 
     */
    public static List<ERP_Address__c> getPunchoutAddressesForERPMasterAddressId(String masterId){
        return [SELECT Id, ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, Address_Type__c, MDM_Customer_Status__c, 
                Address_Street_Line_1__c, RecordType.Name, Address_Street_Line_2__c, Address_City__c, Address_State__c, Address_Country__c, 
                apiState__c, Address_Postal_Code__c, apiCountry__c, fxAddress_City__c,fxAddress_CountryCode__c, fxAddress_Postal__c, 
                fxAddress_StateName__c, fxAddress_Street__c, fxAddressFull__c, External_Id__c, CurrencyIsoCode,fxAddress_CountryName__c,
                
                //ERP Details
                ERP_Account_Group__c,ERP_Customer_Number__c, ERP_Sales_Org__c,ERP_Account_Name__c, ERP_Marked_for_Deletion__c, ERP_Partner_Code__c,
                
                //AccountFields
                Account__c, Account__r.Name,  Account__r.CurrencyIsoCode,
                
                //ContactFields
                Contact__c,  
                
                //Punchout fields
                ECOM_Punchout_Is_Enabled__c, ECOM_Punchout_Customer_Id__c, ECOM_Punchout_Customer_Logo__c, ECOM_Punchout_Customer_Name__c, 
                ECOM_Punchout_Products_Exclude_Query__c, ECOM_Punchout_Products_Include_Query__c, ECOM_Punchout_Show_List_Price__c, 
                ECOM_Punchout_Unit_Of_Measurement__c, ECOM_POSR_Sender_Shared_Identity__c, ECOM_POSR_Sender_Shared_Secret__c, ECOM_Punchout_Format__c,
                ECOM_Punchout_Account_TimeZone_SID__c, ECOM_Punchout_Processors__c, ECOM_Punchout_Country_Locale__c, 
                ECOM_Punchout_Default_UNSPSC__c //RWPS-410 - 3 April 2024 - garora@rafter.one - querying new field created for requirement
                FROM ERP_Address__c
                WHERE ERP_Marked_for_Deletion__c = false 
                //AND (RecordType.DeveloperName = 'Default' OR RecordType.DeveloperName = 'Staging')
                AND ECOM_Review_Status__c = 'Approved'
                AND fxIsECOMenabled__c = true
                AND ((Target_Address__r.ECOM_Punchout_Is_Enabled__c = true AND ECOM_Punchout_Is_Enabled__c = true AND Target_Address__c =: masterId)
                    OR (Address_Type__c = 'Master' AND Id =: masterId AND ECOM_Punchout_Is_Enabled__c = true)
                    OR (Address_Type__c = 'Payer' AND Master_Address__c =: masterId AND ECOM_Punchout_Is_Enabled__c = true))
                LIMIT 49999 ];
    }

    /**
     * @description This method returns the ERP Address (Ship to, Sold to, Bill To, Payer) and the related target.master address for
     *  a punchout account Unique name defined on the target.master( ECOM Punchout Customer Id field)
     * @author vramachandran@rafter.one | 15 Jan 2024
     * @param poAccountUniqueName | String
     * @returns List<ERP_Address> 
     */
    public static ERP_AddressModel getPunchoutAddressesForERPAddressModel(String poAccountUniqueName){
        
        ERP_AddressModel addressModel = new ERP_AddressModel();
        List<ERP_Address__c> addressList = new List<ERP_Address__c>(); 
        addressList = [SELECT Id, ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, Address_Type__c, MDM_Customer_Status__c, 
                        Address_Street_Line_1__c, RecordType.Name, Address_Street_Line_2__c, Address_City__c, Address_State__c, Address_Country__c, 
                        apiState__c, Address_Postal_Code__c, apiCountry__c, fxAddress_City__c,fxAddress_CountryCode__c, fxAddress_Postal__c, 
                        fxAddress_StateName__c, fxAddress_Street__c, fxAddressFull__c, External_Id__c, CurrencyIsoCode,fxAddress_CountryName__c,            
                        //ERP Details
                        ERP_Account_Group__c,ERP_Customer_Number__c, ERP_Sales_Org__c,ERP_Account_Name__c, ERP_Marked_for_Deletion__c, ERP_Partner_Code__c,                      
                        //AccountFields
                        Account__c, Account__r.Name, Account__r.CurrencyIsoCode,                        
                        //ContactFields
                        Contact__c,       
                        //Punchout fields
                        ECOM_Punchout_Is_Enabled__c, ECOM_Punchout_Customer_Id__c, ECOM_Punchout_Customer_Logo__c, ECOM_Punchout_Customer_Name__c, 
                        ECOM_Punchout_Products_Exclude_Query__c, ECOM_Punchout_Products_Include_Query__c, ECOM_Punchout_Show_List_Price__c, 
                        ECOM_Punchout_Unit_Of_Measurement__c, ECOM_POSR_Sender_Shared_Identity__c, ECOM_POSR_Sender_Shared_Secret__c, ECOM_Punchout_Format__c,
                        ECOM_Punchout_Account_TimeZone_SID__c, ECOM_Punchout_Processors__c, ECOM_Punchout_Country_Locale__c, 
                        ECOM_Punchout_Default_UNSPSC__c //RWPS-410 - 3 April 2024 - garora@rafter.one - querying new field created for requirement

                        FROM ERP_Address__c
                        WHERE ERP_Marked_for_Deletion__c = false 
                        //AND (RecordType.DeveloperName = 'Default' OR RecordType.DeveloperName = 'Staging' OR RecordType.DeveloperName = '')
                        AND ECOM_Review_Status__c = 'Approved'
                        AND fxIsECOMenabled__c = true
                        AND ((Target_Address__r.ECOM_Punchout_Is_Enabled__c = true AND ECOM_Punchout_Is_Enabled__c = true AND Target_Address__r.ECOM_Punchout_Customer_Id__c =: poAccountUniqueName)
                            OR (Master_Address__r.ECOM_Punchout_Is_Enabled__c = true AND ECOM_Punchout_Is_Enabled__c = true AND Address_Type__c = 'Payer' AND Master_Address__r.ECOM_Punchout_Customer_Id__c =: poAccountUniqueName)
                            OR (Address_Type__c = 'Master' AND ECOM_Punchout_Customer_Id__c =: poAccountUniqueName AND ECOM_Punchout_Is_Enabled__c = true))
                        LIMIT 49999 ];      
        System.debug('addressList:: '+ JSON.serialize(addressList));       
        if(null != addressList && !addressList.isEmpty()){
            addressModel = getAddressModel(addressList);
        }  
        System.debug('addressModel:: '+ addressModel);
        return addressModel;
    }

    /**
     * @description This method returns the base store url for the ecom store
     * @author vramachandran@rafter.one | 02 Jan 2024
     * @returns String
     */
    public static String getBaseStoreUrl(){
        return Test.isRunningTest() ? '' : getEcomSiteBaseUrl();
    }

    /**
     * @description This method returns the contact record for a given contact email
     * @author vramachandran@rafter.one | 22 Dec 2023
     * @param contactEmail | String 
     * @returns Contact
     */
    public static Contact getContactRecordForEmail(String contactEmail){
        Contact contactRecord;
        List<Contact> contactRecordList = getContactForEmail(contactEmail);
        
        if(null != contactRecordList && !contactRecordList.isEmpty()){
            contactRecord = contactRecordList[0];
        }
        
        return contactRecord;
    }

    /**
     * @description This method returns a contact record for a given email
     * @author vramachandran@rafter.one | 22 Dec 2023
     * @param contactEmail | String 
     * @returns Contact
     */
    public static List<Contact> getContactForEmail(String contactEmail){
        return [SELECT Id, FirstName, LastName, AccountId, 
                Default_Bill_to_ERP_Address__c,Default_Ship_to_ERP_Address__c,Default_Sold_to_ERP_Address__c,
                ECOM_Is_Punchout_Contact__c
                FROM Contact
                WHERE Email =: contactEmail
                LIMIT 1];
    }

    /**
     * @description This method returns the userRecord for a userName
     * @author vramachandran@rafter.one | 22 Dec 2023
     * @param userName | String
     * @returns User
     */
    public static User getPunchoutUserForUserName(String userName){
        User userRecord;
        
        List<User> userRecordList = getPunchoutUserInformationByUserName(userName);
        if(null != userRecordList && !userRecordList.isEmpty()){
            userRecord = userRecordList[0];
        }
        
        return userRecord;
    }
    
     
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

    /* RWPS-1256 code start*/

    /**
     * @description This method retrieves punchout master erp address record
     * @author manish.joshi@revvity.com | 16 Sept 2024
     * @param customerId | String
     * @returns List<ERP_Address__c>
     */
    public static List<ERP_Address__c> getPunchoutMasterFromCustomerId(String customerId){
        List<ERP_Address__c>  masterAddress = [SELECT Id, ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, Address_Type__c, MDM_Customer_Status__c, 
        Address_Street_Line_1__c, RecordType.Name, Address_Street_Line_2__c, Address_City__c, Address_State__c, Address_Country__c, 
        apiState__c, Address_Postal_Code__c, apiCountry__c, fxAddress_City__c,fxAddress_CountryCode__c, fxAddress_Postal__c, 
        fxAddress_StateName__c, fxAddress_Street__c, fxAddressFull__c, External_Id__c, CurrencyIsoCode,fxAddress_CountryName__c,
        ERP_Account_Group__c,ERP_Customer_Number__c, ERP_Sales_Org__c,ERP_Account_Name__c, ERP_Marked_for_Deletion__c, ERP_Partner_Code__c,
        Account__c, Account__r.Name, Account__r.CurrencyIsoCode,Contact__c,  
        ECOM_Punchout_Is_Enabled__c, ECOM_Punchout_Customer_Id__c, ECOM_Punchout_Customer_Logo__c, ECOM_Punchout_Customer_Name__c, 
        ECOM_Punchout_Products_Exclude_Query__c, ECOM_Punchout_Products_Include_Query__c, ECOM_Punchout_Show_List_Price__c, 
        ECOM_Punchout_Unit_Of_Measurement__c, ECOM_POSR_Sender_Shared_Identity__c, ECOM_POSR_Sender_Shared_Secret__c, ECOM_Punchout_Format__c,
        ECOM_Punchout_Account_TimeZone_SID__c, ECOM_Punchout_Processors__c, ECOM_Punchout_Country_Locale__c, 
        ECOM_Punchout_Default_UNSPSC__c ,ECOM_Punchout_Sales_Org__c,ECOM_Punchout_Default_Payer__c,MDM_Cluster_Id__c,Default_Domain__c//RWPS-1923
        FROM ERP_Address__c
        WHERE ERP_Marked_for_Deletion__c = false 
        AND RecordType.DeveloperName = 'Default'
        AND ECOM_Review_Status__c = 'Approved'
        AND fxIsECOMenabled__c = true
        AND ECOM_Punchout_Customer_Id__c =:customerId
        LIMIT 1 ];
        return masterAddress;
    }

    /**
     * @description This method retrieves punchout master partner fuctions records
     * @author manish.joshi@revvity.com | 16 Sept 2024
     * @param masterAddress | ERP_Address__c
     * @returns List<ERP_Address__c>
     */
    public static List<ERP_Address__c> getPunchoutAddressFromMaster(ERP_Address__c masterAddress){
        List<ERP_Address__c>  punchoutAddresses = [SELECT Id, ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, Address_Type__c, MDM_Customer_Status__c, 
        Address_Street_Line_1__c, RecordType.Name, Address_Street_Line_2__c, Address_City__c, Address_State__c, Address_Country__c, 
        apiState__c, Address_Postal_Code__c, apiCountry__c, fxAddress_City__c,fxAddress_CountryCode__c, fxAddress_Postal__c, 
        fxAddress_StateName__c, fxAddress_Street__c, fxAddressFull__c, External_Id__c, CurrencyIsoCode,fxAddress_CountryName__c,
        ERP_Account_Group__c,ERP_Customer_Number__c, ERP_Sales_Org__c,ERP_Account_Name__c, ERP_Marked_for_Deletion__c, ERP_Partner_Code__c,
        Account__c, Account__r.Name, Account__r.CurrencyIsoCode,Contact__c,  
        ECOM_Punchout_Is_Enabled__c, ECOM_Punchout_Customer_Id__c, ECOM_Punchout_Customer_Logo__c, ECOM_Punchout_Customer_Name__c, 
        ECOM_Punchout_Products_Exclude_Query__c, ECOM_Punchout_Products_Include_Query__c, ECOM_Punchout_Show_List_Price__c, 
        ECOM_Punchout_Unit_Of_Measurement__c, ECOM_POSR_Sender_Shared_Identity__c, ECOM_POSR_Sender_Shared_Secret__c, ECOM_Punchout_Format__c,
        ECOM_Punchout_Account_TimeZone_SID__c, ECOM_Punchout_Processors__c, ECOM_Punchout_Country_Locale__c, 
        ECOM_Punchout_Default_UNSPSC__c ,ECOM_Punchout_Sales_Org__c,ECOM_Punchout_Default_Payer__c
        FROM ERP_Address__c
        WHERE ERP_Marked_for_Deletion__c = false 
        AND RecordType.DeveloperName = 'Default'
        AND ECOM_Review_Status__c = 'Approved'
        AND fxIsECOMenabled__c = true
        AND ((Address_Type__c IN ('Sold To','Ship To') AND Master_Address__r.External_Id__c = :masterAddress.External_Id__c AND Target_Address__r.External_Id__c =: masterAddress.External_Id__c AND ERP_Sales_Org__c = :masterAddress.ECOM_Punchout_Sales_Org__c)
        OR (Address_Type__c IN  ( 'Payer' ) AND Master_Address__r.External_Id__c =:masterAddress.External_Id__c AND Target_Address__r.External_Id__c =  :masterAddress.ECOM_Punchout_Default_Payer__c AND ERP_Sales_Org__c = :masterAddress.ECOM_Punchout_Sales_Org__c))
        LIMIT 49999 ];
        return punchoutAddresses;
    }

    /**
     * @description This method creates a map of punchout erp addresses i.e master, ship to , sold to & payer configured for login 
     * @author manish.joshi@revvity.com | 16 Sept 2024
     * @param customerId | String
     * @returns Map<String,ERP_Address__c>
     */
    public static Map<String,ERP_Address__c> gePunchoutAddress(String customerId){
        //Note : add safe checks
        Map<String,ERP_Address__c> responseMap = new Map<String, ERP_Address__c>();
        List<ERP_Address__c> masterAddresses = getPunchoutMasterFromCustomerId(customerId);
        if(masterAddresses.size()> 0 ){
            ERP_Address__c  masterAddress = masterAddresses[0];// add safe check
            List<ERP_Address__c> erpAddressList = getPunchoutAddressFromMaster(masterAddress);
            responseMap.put(masterAddress.Address_Type__c,masterAddress);
            for(ERP_Address__c erpAddress : erpAddressList){
                responseMap.put(erpAddress.Address_Type__c,erpAddress);
            }
        }
        
        return responseMap;
    }

    /**
     * @description This method update contact & user field data required for a web punchout customer
     * @author manish.joshi@revvity.com | 16 Sept 2024
     * @param addressMap | Map<String,ERP_Address__c> 
     * @param contactRecord | Contact 
     * @param userRecord | User 
     * @returns Map<String,Object>
     */
    public static Map<String,Object> validatePunchoutConfiguration(Map<String,Object> addressMap, Contact contactRecord, User userRecord,ECOM_PunchoutWrapper.PunchoutServiceRequest requestModel){
        Map<String,Object> responseMap = new Map<String, Object>();
        boolean isException = false;
        Boolean isUpdateUser = false;
        Boolean isUpdateContact = false;
        try{
            // update contact if master erp address  configs not matching with contact
            if(addressMap !=null && !addressMap.isEmpty()){
                // RWPS-5776 - START
                ERP_Address__c master = (ERP_Address__c) addressMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_MASTER) ;
                ERP_Address__c shipToRec = (ERP_Address__c) addressMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_SHIP_TO) ;
                ERP_Address__c payerRec = (ERP_Address__c) addressMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_PAYER) ;
                ERP_Address__c soldToRec = (ERP_Address__c) addressMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_SOLD_TO) ;
                // RWPS-5776 - END
                if(shipToRec!=null && shipToRec.Account__c != contactRecord.accountId){
                    contactRecord.AccountId =  shipToRec.Account__c;
                    isUpdateContact = true;
                }
                if(shipToRec!=null && (shipToRec.Id != contactRecord.Default_Ship_to_ERP_Address__c ||contactRecord.Default_Ship_to_ERP_Address__c==null) ){
                    contactRecord.Default_Ship_to_ERP_Address__c = shipToRec.Id;
                    isUpdateContact = true;
                }
                if(soldToRec!=null && (soldToRec.Id != contactRecord.Default_Sold_to_ERP_Address__c ||  contactRecord.Default_Sold_to_ERP_Address__c==null)){
                    contactRecord.Default_Sold_to_ERP_Address__c = soldToRec.Id;
                    isUpdateContact = true;
                }
                if(payerRec!=null && (payerRec.Id != contactRecord.Default_Bill_to_ERP_Address__c || contactRecord.Default_Bill_to_ERP_Address__c==null)){
                    contactRecord.Default_Bill_to_ERP_Address__c =  payerRec.Id;
                    isUpdateContact = true;
                }
                //RWPS-1170 Update country provided on contact
                if(master!=null && master.fxAddress_CountryName__c!=null && contactRecord.ECOM_CountryProvided__c!=master.fxAddress_CountryName__c){
                    contactRecord.ECOM_CountryProvided__c = master.fxAddress_CountryName__c;
                    isUpdateContact = true;
                }
                if(!contactRecord.ECOM_Is_Punchout_Contact__c){
                    contactRecord.ECOM_Is_Punchout_Contact__c = true;
                    isUpdateContact = true;
                }
                if(!contactRecord.ECOM_Is_Mapped__c){
                    contactRecord.ECOM_Is_Mapped__c = true;
                    isUpdateContact = true;
                }
                if(!contactRecord.ECOM_isEnabled__c){
                    contactRecord.ECOM_isEnabled__c = true;
                    isUpdateContact = true;
                }                
                if(contactRecord.ECOM_AddressRegistration__c!=System.Label.ECOM_Completed){
                    contactRecord.ECOM_AddressRegistration__c = System.Label.ECOM_Completed;
                    isUpdateContact = true;
                }
                if(contactRecord.FirstName != requestModel.firstName || contactRecord.LastName != requestModel.lastName){ //RWPS-1671
                    contactRecord.FirstName = requestModel.firstName;
                    contactRecord.LastName = requestModel.lastName;                    
                    isUpdateContact = true;
                }
                if((userRecord != null && (userRecord.FirstName != requestModel.firstName || userRecord.LastName != requestModel.lastName || !userRecord.ECOM_Is_Punchout_User__c)) && !Test.isRunningTest()){ 
                    userRecord.FirstName = requestModel.firstName;
                    userRecord.LastName = requestModel.lastName;
                    userRecord.ECOM_Is_Punchout_User__c = true;
                    isUpdateUser = true;
                }
            }else{
                //send to auth fail
                isException = true;
            }
            if(isUpdateUser){
                updateUserAsPunchoutUserOrContact(JSON.serialize(userRecord),'User');
            }
            if(isUpdateContact){
                updateUserAsPunchoutUserOrContact(JSON.serialize(contactRecord),'Contact');

            }
        }catch(Exception e){
            isException = true;
            responseMap.put(ECOM_Constant.PARAM_PUNCHOUT_EXCEPTION, e.getStackTraceString()+' '+e.getMessage());
        }
        responseMap.put(ECOM_Constant.PARAM_PUNCHOUT_EXCEPTION_FLAG, isException);
        return responseMap;
    }

	/**
     * @description This method update partner functions and correct them as per the configuration
     * @author manish.joshi@revvity.com | 16 Sept 2024
     * @param addressMap | Map<String,ERP_Address__c> 
     * @returns Map<String,Object>
     */
    public static Map<String,Object> validatePunchoutPartnerFunctions(Map<String,Object> addressMap){
        Map<String,Object> responseMap = new Map<String, Object>();
        boolean isException = false;
        Boolean isUpdatePayer = false;
        Boolean isUpdateShipTo = false;
        Boolean isUpdateSoldTo = false;
        try{
            // update contact if master erp address  configs not matching with contact
            if(addressMap !=null && !addressMap.isEmpty()){
                // RWPS-5776 - START
                ERP_Address__c payerRec = (ERP_Address__c) addressMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_PAYER) ;
                ERP_Address__c shipToRec = (ERP_Address__c) addressMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_SHIP_TO) ;
                ERP_Address__c soldToRec = (ERP_Address__c) addressMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_SOLD_TO) ;
                ERP_Address__c master = (ERP_Address__c) addressMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_MASTER) ;
                // RWPS-5776 - END
                Account acc = getAccount(master.MDM_Cluster_ID__c);
                if(payerRec!=null && payerRec.Account__c!=acc.Id){
                    payerRec.Account__c = acc.Id;
                    isUpdatePayer=true;
                }
                if(shipToRec!=null && shipToRec.Account__c!=acc.Id){
                    shipToRec.Account__c = acc.Id;
                    isUpdateShipTo=true;
                }
                if(soldToRec!=null && soldToRec.Account__c!=acc.Id){
                    soldToRec.Account__c = acc.Id;
                    isUpdateSoldTo=true;
                }
                if(isUpdatePayer){
                    update payerRec;
                }
                if(isUpdateShipTo){
                    update shipToRec;
                }
                if(isUpdateSoldTo){
                    update soldToRec;
                }
            }else{
                //send to auth fail
                isException = true;
            }

        }catch(Exception e){
            isException = true;
            responseMap.put(ECOM_Constant.PARAM_PUNCHOUT_EXCEPTION, e.getStackTraceString() +' '+ e.getMessage());
        }
        responseMap.put(ECOM_Constant.PARAM_PUNCHOUT_EXCEPTION_FLAG, isException);
        return responseMap;
    }

    /**
     * @description This method update contact or user record for a given details in data parameter
     * @author manish.joshi@rafter.com | 16 Sept 2024
     * @param data | String 
     * @param objectName | String 
     * @returns void
     */
    @future
    public static void updateUserAsPunchoutUserOrContact(String data,String objectName){
        if(objectName=='User'){
            User user = (User)JSON.deserialize(data, User.Class);
            update user;
        }else if(objectName=='Contact'){
            Contact con = (Contact)JSON.deserialize(data, Contact.Class);
            if(!con.ECOM_Is_Punchout_Contact__c){
                con.ECOM_Is_Punchout_Contact__c = true;
            }
            update con; //RWPS-1671
        }
    }

    /**
     * @description This method returns the contact record for a given contact email
     * @author manish.joshi@rafter.com | 16 Sept 2024
     * @param contactEmail | String 
     * @returns Contact
     */
    public static Contact getContactRecordForEmail1(String contactEmail){
        Contact contactRecord;
        List<Contact> contactRecordList = getContactForEmail1(contactEmail);
        
        if(null != contactRecordList && !contactRecordList.isEmpty()){
            contactRecord = contactRecordList[0];
        }
        
        return contactRecord;
    }

    /**
     * @description This method returns a contact record for a given email
     * @author manish.joshi@revvity.com | 16 Sept 2024
     * @param contactEmail | String 
     * @returns List<Contact>
     */
    public static List<Contact> getContactForEmail1(String contactEmail){
        return [SELECT Id,Email, FirstName, LastName, AccountId,ECOM_CountryProvided__c,ECOM_Is_Mapped__c,ECOM_AddressRegistration__c,ECOM_isEnabled__c,
                Default_Bill_to_ERP_Address__c,Default_Ship_to_ERP_Address__c,Default_Sold_to_ERP_Address__c,
                ECOM_Is_Punchout_Contact__c,ECOM_AccountNameProvided__c,ECOM_NeedsVerification__c,External_ID__c
                FROM Contact
                WHERE Email =: contactEmail OR External_ID__c = :contactEmail
                LIMIT 1];
    }

     /**
     * @description This method returns a Master MDM Account record
     * @author manish.joshi@revvity.com | 16 Sept 2024
     * @param contactEmail | Account 
     * @returns Account record
     */
    public static Account getAccount(Decimal mdmClusterId){
        Account account=null;
        List<Account> accounts =  [SELECT Id, name FROM Account where MDM_Cluster_ID__c =:mdmClusterId
                                     LIMIT 1];
        if(!accounts.isEmpty()){
            account = accounts.get(0);
        }    
        return account;               
    }
    
     /**
     * @description This method returns a request model
     * @author manish.joshi@revvity.com | 16 Sept 2024
     * @returns ECOM_PunchoutWrapper.PunchoutServiceRequest record
     */
    public static ECOM_PunchoutWrapper.PunchoutServiceRequest createPOSRModelForRevvityPunchoutForNewUser1(){

        ECOM_PunchoutWrapper.PunchoutServiceRequest requestModel = new ECOM_PunchoutWrapper.PunchoutServiceRequest();

        String testUserConfig = getStoreNavigationConfig(System.Label.ECOM_TestUserConfigMetadata);

        //List<User> userRecords = [SELECT Id, Username, Email FROM USER WHERE ECOM_Is_Punchout_User__c = true ORDER BY CreatedDate DESC LIMIT 1];

        if(String.isNotEmpty(testUserConfig)){
            requestModel = (ECOM_PunchoutWrapper.PunchoutServiceRequest) JSON.deserialize(testUserConfig, ECOM_PunchoutWrapper.PunchoutServiceRequest.class);
            requestModel.fromCredentialDomain = 'RVTYPNCHOUT';
            requestModel.toCredentialDomain = 'RVTYPNCHOUT';
            requestModel.fromCredentialIdentity = 'RVTYPNCHOUT';
            requestModel.firstName = 'NewUser';
            requestModel.lastName = 'Test';
            //if(null == userRecords && userRecords.isEmpty()){
            //requestModel.userEmail = String.valueOf(System.now().millisecond()) + '@RevvityPunchout.xyz' ;
            requestModel.userEmail = 'testpunchout@RevvityPunchout.xyz' ;
            //} else {
            //    requestModel.userEmail = userRecords[0].Email;
            //}

            requestModel.locale = 'en_US';
            requestModel.timezoneSidKey = 'America/New_York';
            requestModel.supplierPartId = '123123';
            requestModel.selectedItem ='123444';

        }

        return requestModel;
    }

    /* RWPS-1256 code end*/

    /* RWPS-5776 - START*/

    /**
     * @description This method creates a map of punchout erp addresses i.e master, ship to , sold to & payer configured for login 
     * @author manish.joshi@revvity.com | 02 Feb 2026
     * @param masterId | String
     * @param configRec | Punchout_Maintenance__c
     * @returns Map<String,ERP_Address__c>
     */
    public static Map<String,ERP_Address__c> gePunchoutAddress(String masterId, Punchout_Maintenance__c configRec){
        //Note : add safe checks
        Map<String,ERP_Address__c> responseMap = new Map<String, ERP_Address__c>();
        List<ERP_Address__c> masterAddresses = ERP_AddressRepo.getPunchoutMasterFromMasterId(masterId);
        if(masterAddresses.size()> 0 ){
            ERP_Address__c  masterAddress = masterAddresses[0];// add safe check
            List<ERP_Address__c> erpAddressList = ERP_AddressRepo.getPunchoutAddressFromPunchoutConfig(configRec);
            responseMap.put(masterAddress.Address_Type__c,masterAddress);
            for(ERP_Address__c erpAddress : erpAddressList){
                responseMap.put(erpAddress.Address_Type__c,erpAddress);
            }
        }
        return responseMap;
    }  
    
    
    /**
     * @description This method returns the addres model in Map<String,Object> format 
     * @author manish.joshi@revvity.com | 02 Feb 2026
     * @param poAccountId | String
     * @returns Map<String,Object> 
     */
   public static Map<String,Object> getPunchoutAddressesForAccountId(String poAccountId)
   {
        Map<String,Object> responseMap = new Map<String,Object>();
        ERP_AddressModel addressModel = new ERP_AddressModel();
        //RWPS-4363 start
        Map<String, ERP_Address__c> addressMap  = new Map<String, ERP_Address__c>();
        List<ERP_Address__c> masterAddressList = new List<ERP_Address__c>();
        Set<Id> accountIds = new Set<Id>();
        accountIds.add(poAccountId);
        List<Punchout_Maintenance__c> configRecordList = ERP_AddressRepo.getPunchoutConfigs(null,accountIds,null,null);
       //masterAddressList= getERPMasterAddressForPunchoutAccountId(poAccountId);
        if(configRecordList != null && !configRecordList.isEmpty()) {
            responseMap.put(ECOM_Constant.PUNCHOUT_CONFIG_REC,configRecordList[0]);
            String masterId = configRecordList[0].ERP_Address__c;
            addressMap = gePunchoutAddress(masterId, configRecordList[0]);
            responseMap.putAll(addressMap); 
            List<ERP_Address__c> erpMasterAddressList = new List<ERP_Address__c>(addressMap.values());
            addressModel = getAddressModel(erpMasterAddressList);
            addressModel.po_PunchoutResponseFormat = addressModel.po_PunchoutResponseFormat==null && configRecordList[0]!=null
                                                     ?configRecordList[0].ECOM_Punchout_Format__c:addressModel.po_PunchoutResponseFormat;
            //RWPS-6851 Start
            addressModel.po_UnitOfMeasure = addressModel.po_UnitOfMeasure == null && configRecordList[0] != null
                                                    ? configRecordList[0].ECOM_Punchout_Unit_Of_Measurement__c : addressModel.po_UnitOfMeasure;
            addressModel.po_SenderSharedIdent = addressModel.po_SenderSharedIdent == null && configRecordList[0] != null
                                                    ? configRecordList[0].ECOM_POSR_Sender_Shared_Identity__c : addressModel.po_SenderSharedIdent;
            addressModel.po_SenderSharedSecret = addressModel.po_SenderSharedSecret == null && configRecordList[0] != null
                                                    ? configRecordList[0].ECOM_POSR_Sender_Shared_Secret__c : addressModel.po_SenderSharedSecret;
            addressModel.po_Processors = addressModel.po_Processors == null && configRecordList[0] != null
                                                    ? configRecordList[0].ECOM_Punchout_Processors__c : addressModel.po_Processors;   
            addressModel.po_DefaultUNSPSC = addressModel.po_DefaultUNSPSC == null && configRecordList[0] != null
                                                    ? configRecordList[0].ECOM_Punchout_Default_UNSPSC__c : addressModel.po_DefaultUNSPSC;
            addressModel.po_AccountName = addressModel.po_AccountName == null && configRecordList[0] != null
                                                    ? configRecordList[0].ECOM_Punchout_Customer_Name__c : addressModel.po_AccountName; //RWPS-6917
            //RWPS-6851 End 
        }//RWPS-4363 end      
        responseMap.put('AddressModel',addressModel);
        return responseMap;
    }

    /* RWPS-5776 - END*/
}