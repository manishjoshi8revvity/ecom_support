/**
 * @description       : 
 * @author            : mkumar@rafter.one
 * @group             : 
 * @last modified on  : 12-18-2024
 * @last modified by  : mkumar@rafter.one
 *  Manoj 2024.11.11 RWPS-1543 - Punchout User creation -10-15% of new punchout users fail at first attempt (Fixed if contact doesn't have account)
 *  Manoj 2024.11.27 RWPS-2106 code improvisation for duplcate user creation
 *  Manoj 2024.12.17 RWPS-1923 Punchout request from blank user email
 *  Prabhat 2025.02.21 Added condition duplicate detected to allow the user to login - RWPS-2650
 *  Chirag 2025.07.02 RWPS-3528 Added logic that removes curly brackets from POSR request for payloadID & buyerCookie attributes
 *  Poonam 2025-09-24 RWPS-4418 Upadte method punchoutLogin to remove curly braces for payload and buyerCookie 
 *  Manish Joshi 2026-02-05 Updated method punchoutLogin,checkAndProvisionNewContactAndUser,validateAndCreateContact1,createNewPunchoutUser1 - RWPS-5776
**/

@RestResource(urlMapping='/PunchoutUserCreation/')
global with sharing class ECOM_PunchoutUserCreation {
    final static String CLASSNAME = 'ECOM_PunchoutUserCreation';
    
    private final static String PASSWORD_CHARSET_ALPHABETS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    private final static String PASSWORD_CHARSET_NUMERIC = '0123456789';
    private final static String PASSWORD_CHARSET_ALPHANUMERIC = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
    
     /**
     * @description 
     * @author mkumar@rafter.one | 10-16-2024 
     * @return String 
     **/
    @HttpPost
     global static String validatePunchoutUser() {
        Map<String,Object> response = new Map<String,Object>();
          String accessToken;
          String supportDta= '';
            try {
                Boolean isUserCreated = false;
                String jsonString = RestContext.request.requestBody.toString();
                Map<String,Object> inputData = (Map<String,Object>)JSON.deserializeUntyped(jsonString);
                String  encryptedToken = (String) inputData.get('encryptedToken');
                String decrypted = ECOM_PunchoutLoginService.decryptWithBase64(encryptedToken);
                ECOM_PunchoutWrapper.PunchoutServiceRequest requestModel = Test.isRunningTest()?ECOM_PunchoutLoginService.createPOSRModelForRevvityPunchoutForNewUser1(): getModelFromString(decrypted);
                requestModel.isTestUser = false;
                response = punchoutLogin(requestModel);
                RestContext.response.addHeader(ECOM_Constant.HTTP_CONTENT_TYPE, ECOM_Constant.HTTP_CONTENT_APP_JSON);
            
            } catch (Exception e) {
                ECOM_PunchoutLoginController.logFailure(e , 'Punchout:: User Creation' , 'ECOM_PunchoutUserCreation' , 'getAccessTokenForGuest', 'Data : '+ supportDta  + ' Stack:: '+ e.getStackTraceString());
            }
            return JSON.serialize (response);
     }

    /**
    * @description 
    * @author mkumar@rafter.one | 10-16-2024 
    * @return String 
    **/
    public static String getAccessTokenForGuest(){
    String accessToken;
    String supportDta= '';
    try {
        String certficateName=System.label.ECOM_Punchout_User_Creation_CertificateName;

        String  consumerKey = fetchConfigByValue(ECOM_Constant.GUEST_CONSUMER_KEY);
        String siteBase = System.label.ECOM_AccessToken_Endpoint;
        supportDta+=+'Certs : '+certficateName+'Base Url :'+siteBase+' Integration user'+System.label.ECOM_Integration_User;
        Auth.JWT jwt = new Auth.JWT();
        jwt.setSub(System.label.ECOM_Integration_User);
        jwt.setIss(consumerKey);
        jwt.setAud(siteBase);
        Auth.JWS jws = new Auth.JWS(jwt, certficateName);
        String tokenEndpoint =System.label.ECOM_Token_Endpoint;
        Auth.JWTBearerTokenExchange bearer = new Auth.JWTBearerTokenExchange(tokenEndpoint, jws);
        if(Test.isRunningTest()){
            accessToken='123';
        }else{
            accessToken = bearer.getAccessToken();
        }
    } catch (Exception e) {
        ECOM_PunchoutLoginController.logFailure(e , 'Punchout:: User Creation' , 'ECOM_PunchoutUserCreation' , 'getAccessTokenForGuest', 'Data : '+ supportDta  + ' Stack:: '+ e.getStackTraceString());
    }
        return accessToken;
    }

    public Static String  makeUserCreationCallout( String encryptedToken){
            Map<String,Object> reqData = new Map<String,Object>();
            Map<String,Object> responseData = new Map<String,Object>();
            String calloutResponse ='';
            reqData.put('encryptedToken', encryptedToken);
            try {
                String accessTokenVal = getAccessTokenForGuest();
                if(String.isNotBlank(accessTokenVal)){
                    String baseUrl = System.label.ECOM_OrgUrl;//'https://revvity--uatfull.sandbox.my.salesforce.com';
                    String endPointUrl;
                    if(String.isNotBlank(baseUrl)){
                        endPointUrl = baseUrl + '/services/apexrest/PunchoutUserCreation/';
                    }
                    String auth ='Bearer '+accessTokenVal;
                    System.debug('endPointUrl '+ endPointUrl);
                    Map<String,String> request = new Map<String,String>();
                    request.put(ECOM_Constant.AUTHORIZATION,auth);
                    request.put(ECOM_Constant.HTTP_REQUEST_ENDPOINT,endPointUrl);
                    request.put(ECOM_Constant.HTTP_REQUEST_BODY,JSON.serialize(reqData));
                    request.put(ECOM_Constant.REQUEST_METHOD_TYPE,ECOM_Constant.HTTP_REQUEST_POST);
                    request.put(ECOM_Constant.HTTP_CONTENT_TYPE,ECOM_Constant.HTTP_CONTENT_APP_JSON);
                    HttpResponse response = ECOM_RestService.performRestCallout(request);
                    if(response.getStatusCode()==200){
                        calloutResponse  =response.getBody();
                    }else{
                         String authError = ECOM_PunchoutLoginService.getBaseStoreUrl() + System.Label.ECOM_PunchoutLoginFailedPath;
                        responseData.put(ECOM_Constant.PARAM_STOREFRONT_URL, authError);
                        calloutResponse = JSON.serialize(responseData);
                    }
                }
                
            }
            catch (Exception ex) {
                //update response as well
                ECOM_PunchoutLoginController.logFailure(ex , 'Punchout:: User Creation' , 'ECOM_PunchoutUserCreation' , 'makeUserCreationCallout', 'Data: '+ JSON.serialize(reqData)  + ' Stack:: '+ ex.getStackTraceString());
            }
            return calloutResponse;
    }

    /*RWPS-1256 code start here*/

    /**
     * @description This method logs in the user and redirects to session inititate page
     * @author manish.joshi@revvity.com | 16 Sept 2024
     * @param TBD
     * @return PageReference
     */
    public static Map<String,Object> punchoutLogin(ECOM_PunchoutWrapper.PunchoutServiceRequest requestModel){
        Boolean isProceedToLogin = false;
        Boolean isLoginSuccess = false;
        Boolean isException = false;
        Map<String,Object> returnMap = new Map<String,Object>();
        Map<String,Object> allAddressesMap = new Map<String,Object>(); // RWPS-5776
        ERP_AddressModel addressModel;
        User userRecord;
        String supportData = '';
        requestModel.isTestUser = false;
        // RWPS-5776 - START
        Map<String,ERP_Address__c> addressMap = new Map<String,ERP_Address__c>();
        List<Punchout_Maintenance__c> configRecordList = ERP_AddressRepo.getPunchoutConfigs(null,null,requestModel.fromCredentialIdentity,null);
        if(configRecordList != null && !configRecordList.isEmpty()) {
            allAddressesMap.put(ECOM_Constant.PUNCHOUT_CONFIG_REC,configRecordList[0]);
            String masterId = configRecordList[0].ERP_Address__c;
            addressMap = ECOM_PunchoutLoginService.gePunchoutAddress(masterId,configRecordList[0]);
            allAddressesMap.putAll(addressMap); 
             //RWPS-1923
            if(String.isBlank(requestModel.userEmail)){
                supportData+='Email Not provided in POSR.';
                String domainName = configRecordList[0].Default_Domain__c;
                if(String.isNotBlank(domainName)){
                    requestModel.userEmail = requestModel.firstName.deleteWhitespace()+'.'+requestModel.lastName.deleteWhitespace()+'@'+domainName;
                }else{
                    supportData+=' Punchout domain not configured.';
                }
            }
        }
        // RWPS-5776 - END
        //1. check if primary data required for login is provided
        if(null != requestModel && String.isNotBlank(requestModel.userEmail)){
            try{
                userRecord = getPunchoutUserInformationByUserNameForLogin(requestModel.userEmail);
            }catch(Exception e){
                isException = true;
                returnMap.put(ECOM_Constant.PARAM_PUNCHOUT_EXCEPTION, e.getStackTraceString() +'  '+ e.getMessage());
            }
            if(!isException){
                if(null == userRecord){
                    try{
                        //user does not exist, create new contact and user
                        returnMap = checkAndProvisionNewContactAndUser(requestModel,allAddressesMap); // RWPS-5776
                        //check if the contact and user provisioning was successful
                        if(!isException && null != returnMap && returnMap.containsKey(ECOM_Constant.PARAM_SUCCESS) && (Boolean)returnMap.get(ECOM_Constant.PARAM_SUCCESS)){
                            //get the user record 
                            if(returnMap.containsKey(ECOM_Constant.PARAM_USER_RECORD)){
                                if(null != (User)returnMap.get(ECOM_Constant.PARAM_USER_RECORD)){
                                    userRecord = (User)returnMap.get(ECOM_Constant.PARAM_USER_RECORD);
                                    if(null != returnMap && returnMap.containsKey(ECOM_Constant.PARAM_IS_NEW_USER)){
                                        requestModel.isNewUser = (Boolean) returnMap.get(ECOM_Constant.PARAM_IS_NEW_USER);
                                    } else {
                                        requestModel.isNewUser = false;
                                    }
                                    isProceedToLogin = true;
                                }
                            }
                        }
                    }catch(Exception e){
                        isException = true;
                        returnMap.put(ECOM_Constant.PARAM_PUNCHOUT_EXCEPTION, e.getStackTraceString() +'  '+e.getMessage());
                        ECOM_PunchoutLoginController.logFailure(e , 'Punchout:: Contact Creation' , CLASSNAME , 'checkAndProvisionNewContactAndUser', 'POSR:: '+ JSON.serialize(requestModel)  + ' Stack:: '+ e.getStackTraceString());
                    }
                } else {
                    try{
                        // RWPS-5776 - START
                        if(null != allAddressesMap && !allAddressesMap.isEmpty() && allAddressesMap.size() > 4){
                            returnMap.putAll(validateAndCreateContact1(requestModel,allAddressesMap));
                            Contact contactRecord = (Contact) returnMap.get(ECOM_Constant.PARAM_CONTACT_RECORD);
                            returnMap.putAll(ECOM_PunchoutLoginService.validatePunchoutConfiguration(allAddressesMap,contactRecord,userRecord,requestModel));
                            isException = returnMap.get(ECOM_Constant.PARAM_PUNCHOUT_EXCEPTION_FLAG)!=null?(Boolean)returnMap.get(ECOM_Constant.PARAM_PUNCHOUT_EXCEPTION_FLAG):false;
                            if(!isException)
                                {
                                    returnMap.putAll(ECOM_PunchoutLoginService.validatePunchoutPartnerFunctions(allAddressesMap));
                                    isException = returnMap.get(ECOM_Constant.PARAM_PUNCHOUT_EXCEPTION_FLAG)!=null?(Boolean)returnMap.get(ECOM_Constant.PARAM_PUNCHOUT_EXCEPTION_FLAG):false;
                                }
                            isProceedToLogin = !isException;
                        }
                        else{
                            //no erp master found for posr request, mark response for auth fail
                            returnMap.put(ECOM_Constant.PARAM_SUCCESS, false);
                            returnMap.put(ECOM_Constant.PARAM_MESSAGE, System.Label.ECOM_107006);
                            List<String> addressIds = new List<String>();
                            addressIds.add(ECOM_Constant.ERP_ADDRESS_TYPE_SHIP_TO +' - '+ (allAddressesMap.containsKey(ECOM_Constant.ERP_ADDRESS_TYPE_SHIP_TO) ? ( (ERP_Address__c) allAddressesMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_SHIP_TO)).Id:null));
                            addressIds.add(ECOM_Constant.ERP_ADDRESS_TYPE_SOLD_TO +' - '+ (allAddressesMap.containsKey(ECOM_Constant.ERP_ADDRESS_TYPE_SOLD_TO) ? ( (ERP_Address__c) allAddressesMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_SOLD_TO)).Id : null));
                            addressIds.add(ECOM_Constant.ERP_ADDRESS_TYPE_PAYER +' - '+ (allAddressesMap.containsKey(ECOM_Constant.ERP_ADDRESS_TYPE_PAYER)? ( (ERP_Address__c) allAddressesMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_PAYER)).Id:null));
                            addressIds.add(ECOM_Constant.ERP_ADDRESS_TYPE_MASTER +' - '+ (allAddressesMap.containsKey(ECOM_Constant.ERP_ADDRESS_TYPE_MASTER) ?  ( (ERP_Address__c) allAddressesMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_MASTER)).Id:null));
                            addressIds.add(ECOM_Constant.PUNCHOUT_CONFIG_REC +' - ' + (allAddressesMap.containsKey(ECOM_Constant.PUNCHOUT_CONFIG_REC) ? ((Punchout_Maintenance__c) allAddressesMap.get(ECOM_Constant.PUNCHOUT_CONFIG_REC)).Id:null));
                            returnMap.put(ECOM_Constant.PARAM_PUNCHOUT_ADDRESSES,addressIds);
                            isException = true;
                        }
                        // RWPS-5776 - END
                    }catch(Exception e){
                        isException = true;
                        returnMap.put(ECOM_Constant.PARAM_PUNCHOUT_EXCEPTION, e.getStackTraceString() +'  '+e.getMessage());
                    }
                }
            }
            //check if user has been marked for login
            if(isProceedToLogin && !isException){
                try{
                    //reset user password
                    String password = resetUserPassword(userRecord.Id);
                    Map<String,Object> storeNavigationConfig = ECOM_PunchoutLoginService.getStoreNavigationConfigMap(ECOM_Constant.PARAM_SITE_NAVIGATION_CONFIG_LABEL, ECOM_Constant.PARAM_PUNCHOUT_USER);
                    String storeForwardingUrl = (String)storeNavigationConfig.get(ECOM_Constant.PARAM_FORWARDING_URL);
                     Map<String,String> encURLMap = getEncryptedStoreUrl(ECOM_Constant.POTYPE_PUNCHOUT_USER, userRecord, storeForwardingUrl, requestModel, false);
                    storeForwardingUrl = (String)encURLMap.get(ECOM_Constant.PARAM_FORWARDING_URL);
                     returnMap.put(ECOM_Constant.PARAM_FORWARDING_URL,storeForwardingUrl);
                     returnMap.put(ECOM_Constant.PARAM_COOKIE,encURLMap.get(ECOM_Constant.PARAM_COOKIE));
                    //returnMap.putAll(loginUserToSite(userRecord.Username, password, storeForwardingUrl)); //TODO: update forwarding path
                    //RWPS-4418 start
                    String payloadId = requestModel.payloadId;
                    if (String.isNotBlank(payloadId)) {
                        if (payloadId.startsWith('{') && payloadId.endsWith('}')) {
                            payloadId = payloadId.removeStart('{').removeEnd('}');
                            requestModel.payloadId = payloadId;
                        }
                    }
                    String buyerCookie = requestModel.buyerCookie;
                    if (String.isNotBlank(buyerCookie)) {
                        if (buyerCookie.startsWith('{') && buyerCookie.endsWith('}')) {
                            buyerCookie = buyerCookie.removeStart('{').removeEnd('}');
                            requestModel.buyerCookie = buyerCookie;
                        }
                    }
                    //RWPS-4418 end
                    returnMap.put(ECOM_Constant.PARAM_POSR_REQUEST_MODEL,requestModel);
                    returnMap.put(ECOM_Constant.PARAM_USERNAME,userRecord.Username);
                    returnMap.put(ECOM_Constant.PARAM_PASSWORD,password);
                    returnMap.put(ECOM_Constant.PARAM_FORWARDING_URL,storeForwardingUrl);
                    //returnMap.put(ECOM_Constant.PARAM_POSR_REQUEST_MODEL,requestModel);
                    requestModel.accountId = ((Contact) returnMap.get(ECOM_Constant.PARAM_CONTACT_RECORD)).AccountId; //VRa: 2024.02.15 - Update to fix empty Org name when new  user is created
                    isLoginSuccess = true;
                }catch(Exception e){
                    isException = true;
                    returnMap.put(ECOM_Constant.PARAM_PUNCHOUT_EXCEPTION, e.getStackTraceString()+'  '+e.getMessage());
                }
            } 
        }
        if(!isLoginSuccess || isException){
            String authError = ECOM_PunchoutLoginService.getBaseStoreUrl() + System.Label.ECOM_PunchoutLoginFailedPath;
            returnMap.put(ECOM_Constant.PARAM_STOREFRONT_URL, authError);
        }
        //create new posr request log
        insertPOSRRequestLog(isLoginSuccess,requestModel, userRecord);//GAr: 2024.02.12 RWPS-73
        String storeFrontUrl = Test.isRunningTest() ? 'TestUrl' : (String)returnMap.get(ECOM_Constant.PARAM_STOREFRONT_URL);
        Map<String,Object> loggingMap = new  Map<String,Object>();
        loggingMap.putAll(returnMap);
        insertPOSRResponseLog1(isLoginSuccess, storeFrontUrl , userRecord, (String)returnMap.get(ECOM_Constant.PARAM_MESSAGE), requestModel.accountId, loggingMap);
        return returnMap;
    }

    /**
    * @description This method will check configuration & create contact & user 
    * @author manish.joshi@revvitry.com | 09-16-2024 
    * @param requestModel | ECOM_PunchoutWrapper.PunchoutServiceRequest
    * @return Map<String, Object> 
    **/
    public static Map<String,Object> checkAndProvisionNewContactAndUser(ECOM_PunchoutWrapper.PunchoutServiceRequest requestModel,
       Map<String,Object> addressMap){ // RWPS-5776
        Map<String,Object> responseMap = new Map<String,Object>();
        //check if ERP Address information is configured for given account
        //if request is mapped to a valid erp address, proceed to check for contact and user provisioning
        if(null != addressMap && !addressMap.isEmpty() && addressMap.size() > 4){ // RWPS-5776
            //create new contact 
            responseMap.putAll(validateAndCreateContact1(requestModel, addressMap));
            if(responseMap.containsKey(ECOM_Constant.PARAM_SUCCESS) && (Boolean)responseMap.get(ECOM_Constant.PARAM_SUCCESS) && responseMap.containsKey(ECOM_Constant.PARAM_CONTACT_RECORD) ){
                //create new user
                responseMap.putAll(createNewPunchoutUser1(requestModel, addressMap, (Contact)responseMap.get(ECOM_Constant.PARAM_CONTACT_RECORD)));
            }
        } else {
            //no erp master found for posr request, mark response for auth fail
            responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
            responseMap.put(ECOM_Constant.PARAM_MESSAGE, System.Label.ECOM_107006);
            List<String> addressIds = new List<String>();
            addressIds.add(ECOM_Constant.ERP_ADDRESS_TYPE_SHIP_TO +' - '+ (addressMap.containsKey(ECOM_Constant.ERP_ADDRESS_TYPE_SHIP_TO) ?   ((ERP_Address__c) addressMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_SHIP_TO)).Id:null)); // RWPS-5776
            addressIds.add(ECOM_Constant.ERP_ADDRESS_TYPE_SOLD_TO +' - '+ (addressMap.containsKey(ECOM_Constant.ERP_ADDRESS_TYPE_SOLD_TO) ?   ((ERP_Address__c) addressMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_SOLD_TO)).Id : null)); // RWPS-5776
            addressIds.add(ECOM_Constant.ERP_ADDRESS_TYPE_PAYER +' - '+ (addressMap.containsKey(ECOM_Constant.ERP_ADDRESS_TYPE_PAYER)?  ((ERP_Address__c) addressMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_PAYER)).Id:null)); // RWPS-5776
            addressIds.add(ECOM_Constant.ERP_ADDRESS_TYPE_MASTER +' - '+ (addressMap.containsKey(ECOM_Constant.ERP_ADDRESS_TYPE_MASTER) ?  ((ERP_Address__c) addressMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_MASTER)).Id:null)); // RWPS-5776
            addressIds.add(ECOM_Constant.PUNCHOUT_CONFIG_REC +' - ' + (addressMap.containsKey(ECOM_Constant.PUNCHOUT_CONFIG_REC) ? ((Punchout_Maintenance__c) addressMap.get(ECOM_Constant.PUNCHOUT_CONFIG_REC)):null)); // RWPS-5776
            responseMap.put(ECOM_Constant.PARAM_PUNCHOUT_ADDRESSES,addressIds);
        }
        return responseMap;
    }


    /**
    * @description This method will check for existing 
    * @author mkumar@rafter.one | 09-12-2024 
    * @param requestModel | ECOM_PunchoutWrapper.PunchoutServiceRequest
    * @param addressMap | Map<String,ERP_Address__c>
    * @return Map<String, Object> 
    **/
    public static Map<String,Object> validateAndCreateContact1(ECOM_PunchoutWrapper.PunchoutServiceRequest requestModel, Map<String,Object> addressMap){
        final String METHOD_NAME = 'validateAndCreateContact';
        Map<String,Object> responseMap = new Map<String,Object>();
        try {
            if(addressMap.size() > 4){ // RWPS-5776 - START
                Contact contactRecord = ECOM_PunchoutLoginService.getContactRecordForEmail1(requestModel.userEmail);
                ERP_Address__c masterAddress = (ERP_Address__c) addressMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_MASTER) ;
                ERP_Address__c shipToAddress = (ERP_Address__c) addressMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_SHIP_TO) ;
                ERP_Address__c payerAddress = (ERP_Address__c) addressMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_PAYER) ;
                ERP_Address__c soldToAddress = (ERP_Address__c) addressMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_SOLD_TO) ;
                Punchout_Maintenance__c configRec = ((Punchout_Maintenance__c) addressMap.get(ECOM_Constant.PUNCHOUT_CONFIG_REC));
                //contact does not exist, create new contact
                if(null == contactRecord){
                    //create new contact
                    Contact newPunchoutContact = new Contact();
                    newPunchoutContact.FirstName = requestModel.firstName;
                    newPunchoutContact.LastName = requestModel.lastName;
                    newPunchoutContact.Email = requestModel.userEmail;
                    newPunchoutContact.AccountId = payerAddress.Account__c;// change it  to ship to
                    newPunchoutContact.ECOM_NeedsVerification__c = true;
                    newPunchoutContact.ECOM_AccountNameProvided__c =  configRec.ECOM_Punchout_Customer_Name__c;
                    newPunchoutContact.ECOM_Is_Punchout_Contact__c = true;
                    newPunchoutContact.ECOM_CountryProvided__c =  String.isNotEmpty(masterAddress?.fxAddress_CountryName__c)  ?masterAddress?.fxAddress_CountryName__c : '';
                    newPunchoutContact.Default_Ship_to_ERP_Address__c =  shipToAddress.Id;
                    newPunchoutContact.Default_Sold_to_ERP_Address__c = soldToAddress.Id;
                    newPunchoutContact.Default_Bill_to_ERP_Address__c = payerAddress.Id;
                    newPunchoutContact.CurrencyIsoCode = payerAddress.Account__r.CurrencyIsoCode;
                    // RWPS-5776 - END
                    if(String.isNotEmpty(newPunchoutContact.Default_Bill_to_ERP_Address__c) && String.isNotEmpty(newPunchoutContact.Default_Ship_to_ERP_Address__c)){
                        newPunchoutContact.ECOM_Is_Mapped__c = true;
                    }
                    newPunchoutContact.ECOM_AddressRegistration__c = System.Label.ECOM_Completed;
                    newPunchoutContact.External_ID__c = requestModel.userEmail;
                    newPunchoutContact.ECOM_isEnabled__c = true;
                    if(masterAddress.fxAddress_CountryName__c!=null)
                        newPunchoutContact.ECOM_CountryProvided__c = masterAddress.fxAddress_CountryName__c;
                    insert newPunchoutContact;
                    //add new contact record to response
                    responseMap.put(ECOM_Constant.PARAM_CONTACT_RECORD, newPunchoutContact);
                } else {
                    if(contactRecord.AccountId==null){
                        // As contact doesn't have account , it will fail during user creation. Also we don't want contact update in future
                         ERP_Address__c shipToRec = (ERP_Address__c) addressMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_SHIP_TO); // RWPS-5776
                         contactRecord.AccountId = shipToRec.Account__c;
                         update contactRecord;
                    }
                    responseMap.putAll(ECOM_PunchoutLoginService.validatePunchoutConfiguration(addressMap,contactRecord,null,requestModel));
                    boolean isException = responseMap.get(ECOM_Constant.PARAM_PUNCHOUT_EXCEPTION_FLAG)!=null?(Boolean)responseMap.get(ECOM_Constant.PARAM_PUNCHOUT_EXCEPTION_FLAG):false;
                    responseMap.put(ECOM_Constant.PARAM_CONTACT_RECORD, contactRecord);
                }
            }
            responseMap.put(ECOM_Constant.PARAM_SUCCESS, true);
        }
        catch (Exception ex) {
            //RWPS-1675
            if((ex.getMessage().contains('DUPLICATE_VALUE') && ex.getMessage().contains('External_ID__c')) || ex.getMessage().contains('DUPLICATES_DETECTED')){//RWPS-2650
                Contact contactRecord = ECOM_PunchoutLoginService.getContactRecordForEmail1(requestModel.userEmail);
                if(contactRecord!=null){
                    responseMap.put(ECOM_Constant.PARAM_CONTACT_RECORD, contactRecord);
                    responseMap.put(ECOM_Constant.PARAM_SUCCESS, true);
                }else{
                    responseMap.put(ECOM_Constant.PARAM_CONTACT_RECORD, null);
                    responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
                    responseMap.put(ECOM_Constant.PARAM_PUNCHOUT_EXCEPTION, ex.getStackTraceString() +'  '+ex.getMessage());
                }
                
            }else{
                responseMap.put(ECOM_Constant.PARAM_CONTACT_RECORD, null);
                responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
                responseMap.put(ECOM_Constant.PARAM_PUNCHOUT_EXCEPTION, ex.getStackTraceString() +'  '+ex.getMessage());
            }           
        }
        return responseMap;
    }

    /**
     * @description This method creates a new user for a punchout service request
     * @author manish.joshi@rafter.one | 16 Sept 2024
     * @param requestModel | ECOM_PunchoutWrapper.PunchoutServiceRequest 
     * @param addressModel | ERP_AddressModel 
     * @returns Map<String,Object>
     */
    public static Map<String,Object> createNewPunchoutUser1(ECOM_PunchoutWrapper.PunchoutServiceRequest requestModel, Map<String,Object> addressMap, Contact contactRecord){
        final String METHOD_NAME = 'createNewPunchoutUser1';
        Map<String,Object> responseMap = new Map<String,Object>();
        // RWPS-5776 - START
        ERP_Address__c masterAddress = (ERP_Address__c) addressMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_MASTER);
        ERP_Address__c shiptoAddress = (ERP_Address__c) addressMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_SHIP_TO);
        ERP_Address__c payerAddress = (ERP_Address__c) addressMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_PAYER) ;
        ERP_Address__c soldToAddress = (ERP_Address__c) addressMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_SOLD_TO) ;
        Punchout_Maintenance__c configRec = ((Punchout_Maintenance__c) addressMap.get(ECOM_Constant.PUNCHOUT_CONFIG_REC));
        // RWPS-5776 - END
        try{
            List<Profile> profiles = getProfileRecords(System.Label.ECOM_CommunityProfileName);
            User newUser = new User();
            final String userEmail = requestModel.userEmail;
            final String alias = getSuppressedLastName(requestModel.lastName);
            final String communityNickName = alias + generateRandomString(PASSWORD_CHARSET_ALPHANUMERIC, 30);
            newUser.FirstName = requestModel.firstName;
            newUser.LastName = requestModel.lastName;
            newUser.Alias = alias;
            newUser.CommunityNickname = CommunityNickname;
            newUser.ContactId =   contactRecord.Id;
            newUser.profileId = profiles[0].Id;
            newUser.Email = userEmail;
            newUser.Username = userEmail;
            newUser.LocaleSidKey = requestModel.locale;
            newUser.EmailEncodingKey = 'UTF-8';//TODO:check and assign label requestModel.emailEncodingKey;
            newUser.TimeZoneSidKey = configRec.ECOM_Punchout_Account_TimeZone_SID__c!=null?configRec.ECOM_Punchout_Account_TimeZone_SID__c:'America/Los_Angeles';// RWPS-5776
            newUser.LanguageLocaleKey = requestModel.locale;
            newUser.ECOM_Is_Punchout_User__c = true;
            newUser.IsActive = true;
            newUser.CurrencyIsoCode = shiptoAddress?.Account__r.CurrencyIsoCode;// change it to ship to account currency
            newUser.CountryCode = masterAddress?.fxAddress_CountryCode__c; 
            //assign new dml option to suppress welcome email for new user
            Database.DMLOptions dmlOptionsInstance = new Database.DMLOptions();
            dmlOptionsInstance.emailHeader.triggerUserEmail = false;
            // RWPS-685 changed method return type
            Map<String,Object> userResponse = createUserWithDmlOptions(newUser,dmlOptionsInstance);
            Boolean isNewUserCreated = false; //RWPS-920 Initialized value to false
            if(userResponse.containsKey('isUserCreated') && userResponse.get('isUserCreated') != null){ //RWPS-920 Addded null check for userResponse map
                isNewUserCreated = (Boolean)userResponse.get('isUserCreated');
                //RWPS-1675
                if(userResponse.containsKey('assignPermissionSets') && (Boolean) userResponse.get('assignPermissionSets')==false){
                    newUser.Id = (String)userResponse.get('userId');
                }else{
                    if(isNewUserCreated){
                        assignPermissionSetToUser((String)userResponse.get('userId') );
                        Contact con = new Contact();
                        con.Id = contactRecord.Id;
                        con.ECOM_isEnabled__c = true;
                        con.fxUserURL__c='/lightning/r/User/'+(String)userResponse.get('userId')+'/view';
                        ECOM_PunchoutLoginService.updateUserAsPunchoutUserOrContact(JSON.serialize(con),'Contact');
                    }
                }
            }
            else{
                responseMap.putAll(userResponse);
            }
            responseMap.put(ECOM_Constant.PARAM_USER_RECORD, newUser);
            responseMap.put(ECOM_Constant.PARAM_USER_NAME, newUser.Username);
            responseMap.put(ECOM_Constant.PARAM_SUCCESS, isNewUserCreated);
            responseMap.put(ECOM_Constant.PARAM_IS_NEW_USER, true);
        }catch(Exception e){
            responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
            responseMap.put(ECOM_Constant.PARAM_MESSAGE, System.Label.ECOM_107002);
            responseMap.put(ECOM_Constant.PARAM_PUNCHOUT_EXCEPTION, e.getStackTraceString() +'  '+e.getMessage());
            ECOM_PunchoutLoginController.logFailure(e , 'Punchout:: User Creation' , CLASSNAME , METHOD_NAME, 'POSR:: '+ JSON.serialize(requestModel)  + ' Stack:: '+ e.getStackTraceString());
        }
        
        return responseMap;
    }

     /**
     * @description This method creates a new application log for a punchout login request
     * @author manish.joshi@rafter.one | 16 Sept 2024
     * @param isLoginSuccessful | Boolean
     * @param redirectUrl | String
     * @param userRecord | User
     * @param message | String
     * @param accountId | String
     * @param returnModel | Map<String,Object>
     * @param Map<String,Object>
     */
    private static void insertPOSRResponseLog1(Boolean isLoginSuccessful, String redirectUrl, User userRecord, String message, String accountId, Map<String,Object> returnMap){
        try{
            
            Map<String,Object> responseMap = new Map<String,Object>();
            if(returnMap.containskey(ECOM_Constant.PARAM_PASSWORD)){
               returnMap.remove(ECOM_Constant.PARAM_PASSWORD);
            }
            if(returnMap.containskey(ECOM_Constant.PARAM_COOKIE)){
               returnMap.remove(ECOM_Constant.PARAM_COOKIE);
            }
            if(returnMap.containskey(ECOM_Constant.PARAM_USERNAME)){
               returnMap.remove(ECOM_Constant.PARAM_USERNAME);
            }
           
            responseMap.put(ECOM_Constant.PARAM_PUNCHOUT_USER_LOGIN_SUCCESS, isLoginSuccessful);
            responseMap.put(ECOM_Constant.PARAM_STOREFRONT_URL, redirectUrl);
            if(null != userRecord){
                responseMap.put(ECOM_Constant.PARAM_USER_ID, null != userRecord? userRecord.Id : null);
                responseMap.put(ECOM_Constant.PARAM_USER_EMAIL, null != userRecord.Email? userRecord.Email : null);
            }
            responseMap.put(ECOM_Constant.PARAM_PUNCHOUT_ACCOUNT_ID, accountId);
            responseMap.putAll(returnMap);
            ECOM_Application_Logs__c newApplicationLog = new ECOM_Application_Logs__c();
            newApplicationLog.ECOM_Log_Type__c = System.Label.ECOM_LogType_POSR_Response;
            newApplicationLog.ECOM_Account__c = accountId;
            if(null != userRecord) newApplicationLog.OwnerId = userRecord.Id;
            newApplicationLog.SupportData__c = JSON.serialize(responseMap); 
            //RWPS-993
            newApplicationLog.ExceptionRunningUser__c = UserInfo.getUserId();
            newApplicationLog.ModuleName__c = 'Punchout';
            newApplicationLog.ClassName__c = CLASSNAME;
            newApplicationLog.MethodName__c = 'insertPOSRResponseLog';
            //GAr: 2024.02.12 RWPS-73 - Begin
            if(isLoginSuccessful){
                newApplicationLog.ECOM_Log_Status__c = 'Success';
            }
            else{
                newApplicationLog.ECOM_Log_Status__c = 'Error';
            }
            //GAr: 2024.02.12 RWPS-73 - End

            if(null == userRecord){ //RWPS-1378
                newApplicationLog.ErrorMessage__c = 'Either the user is inactive or not created';
            }
            
            insert newApplicationLog;
        }catch(Exception e){
            ECOM_PunchoutLoginController.logFailure(e, 'Punchout:: Insert POSR Response - Failed', CLASSNAME, 'insertPOSRResponseLog1', 'Message:: '+ e.getMessage()+ ' Stack:: '+ e.getStackTraceString());
        }
    }

    public static User getPunchoutUserInformationByUserNameForLogin(String userName){
        User userRecord;
        List<User> users = [SELECT Id, Name, FirstName, Lastname, Phone, Fax, Email, ContactId, AccountId, 
               ECOM_Phone_Extension__c, ECOM_Country_Phone_Code__c, 
               Country,
               UserName, ECOM_Is_Punchout_User__c,
               Contact.ECOM_CountryProvided__c             
               FROM User 
               WHERE UserName =:userName
               AND IsActive = true             
               LIMIT 1 ];
        
        if(null != users && !users.isEmpty()){
            userRecord = users[0];
        }
        
        return userRecord;
    }
    /**
     * @description This method inserts the POSR log
     * @author vramachandran@rafter.one | 22 Dec 2023
     * @param requestMap | Map<String,Object>
     */
    public static void insertPOSRRequestLog(Boolean isLoginSuccessful, ECOM_PunchoutWrapper.PunchoutServiceRequest requestModel, User userRecord){//GAr: 2024.02.12 RWPS-73
        Map<String,Object> requestMap = new Map<String,Object>();
        ECOM_PunchoutWrapper.PunchoutServiceRequest posrRequest;
        
        if(null != requestModel){
            System.debug('posrRequest:: '+ posrRequest);
            
            ECOM_Application_Logs__c  newApplicationLog = new ECOM_Application_Logs__c();
            newApplicationLog.ECOM_Log_Type__c = System.Label.ECOM_LogType_POSR_Request;
            if(String.isNotBlank(requestModel?.accountId))newApplicationLog.ECOM_Account__c = requestModel.accountId;
            if(null != userRecord) newApplicationLog.ownerId = userRecord.Id;
            newApplicationLog.SupportData__c = JSON.serialize(requestModel);
            //RWPS-993
            newApplicationLog.ExceptionRunningUser__c = UserInfo.getUserId();
            newApplicationLog.ModuleName__c = 'Punchout';
            newApplicationLog.ClassName__c = CLASSNAME;
            newApplicationLog.MethodName__c = 'insertPOSRRequestLog';
            //GAr: 2024.02.12 RWPS-73 - Begin
            if(isLoginSuccessful){
                newApplicationLog.ECOM_Log_Status__c = 'Success';
            }
            else{
                newApplicationLog.ECOM_Log_Status__c = 'Error';
            }
            //GAr: 2024.02.12 RWPS-73 - End
            insert newApplicationLog;
            
        }
    }

    /**
    * @description Method to fetch value from parameterMap
    * @author vramachandran@rafter.one | 24-11-2023 
    * @param parameterMap
    * @return String
    **/
    @TestVisible
    private static String fetchValueForProperty(Map<String,String> propertyMap, String key){
        String value = '';
        if(propertyMap.containsKey(key) && propertyMap.get(key) != null){
            value = propertyMap.get(key).unescapeHtml4();
        }
        return value;
    }

      /**
    * @description Method to reset User Password
    * @author vramachandran@rafter.one | 24-11-2023 
    * @param userId
    * @return Boolean
    **/
    @TestVisible
    private static String resetUserPassword(String userId){
        String password = getNewPassword();
        System.setPassword(userId, password);
        return password;
    }

    /**
     * description This method returns the encrypted parameters for session creation
     * @author vramachandran@rafter.one | 04 Jan 2024
     * @param userType | String 
     * @param userRecord | User
     * @param forwardingUrl | String 
     * @returns String 
     */
    @TestVisible
    private static Map<String,String> getEncryptedStoreUrl(String userType, User userRecord, String forwardingUrl, ECOM_PunchoutWrapper.PunchoutServiceRequest requestModel, Boolean isTestUser){
        String userTypeParameter;
        String requestModelParameter;
        String urlParameters;
        String cmsParameters;
        String sessionCookieParameters;
        Map<String,String> response = new Map<String,String>();
        userTypeParameter = ECOM_Constant.PARAM_PUNCHOUT_USER_TYPE + '=' + userType;
        
        //build url parameters to pass to cms
        cmsParameters = ECOM_Constant.PARAM_EXT_USER_ID + '=' + userRecord.Id;
        cmsParameters = cmsParameters + '&' + ECOM_Constant.PARAM_EXT_EMAIL_ID + '=' + userRecord.Email;
        cmsParameters = cmsParameters + '&' + ECOM_Constant.PARAM_EXT_SESSION_STARTED_TIMESTAMP + '=' + String.valueOf(DateTime.now().getTime());
        cmsParameters = cmsParameters + '&' + ECOM_Constant.PARAM_EXT_IF_SESSION_STARTED_FLAG + '=' + String.valueOf(1);
        if(String.isNotBlank(requestModel?.selectedItem))cmsParameters = cmsParameters + '&' + ECOM_Constant.PARAM_EXT_PART_NUMBER + '=' + requestModel?.selectedItem;  
        
        requestModelParameter = ECOM_Constant.PARAM_PUNCHOUT_POSR_URL_PARAMETER + '=' + EncodingUtil.urlEncode(ECOM_PunchoutLoginService.encryptWithAES256(JSON.serialize(requestModel)), 'UTF-8');
        
        urlParameters = userTypeParameter + '&' + ECOM_Constant.PARAM_EXT_CMS_URL_PARAMETER + '=' +  EncodingUtil.urlEncode(ECOM_PunchoutLoginService.encryptWithAES256(cmsParameters), 'UTF-8');
        urlParameters = urlParameters + '&' + requestModelParameter;

        //check if a part number is provided, if provided, check if item is e sellable and add to url parameter for redirect to PDP page
        if((null != requestModel.selectedItem && String.isNotBlank(requestModel.selectedItem)) || Test.isRunningTest()){
            String salesOrg = Test.isRunningTest() ? 'US10' : getSalesOrgForCountry(String.isNotBlank(userRecord?.Contact.ECOM_CountryProvided__c) ? userRecord?.Contact.ECOM_CountryProvided__c : '');
            List<Product_Sales__c> prodSales = Test.isRunningTest() ? new List<Product_Sales__c>{new Product_Sales__c()} : ECOM_PunchoutLoginService.getProductSales(requestModel.selectedItem, salesOrg);
            if((null != prodSales && !prodSales.isEmpty()) || Test.isRunningTest()){
                urlParameters = urlParameters + '&' + ECOM_Constant.PARAM_PUNCHOUT_PART + '=' + requestModel.selectedItem;
            }   
        }
        
        //mark if a new user was created for POSR request. This url parameter is used in create session to add a delay for post user creation flows to execute and assign required permission sets
        if( Null != requestModel.isNewUser) urlParameters = urlParameters + '&' + ECOM_Constant.PARAM_IS_NEW_USER + '=' + requestModel.isNewUser;
        
        //add a session cookie for current user login. The session created timestamp will be updated once the user session is created
        if(!isTestUser){
            sessionCookieParameters = cmsParameters + '&' + ECOM_Constant.PARAM_EXT_IF_SESSION_STARTED_FLAG + '=' + String.valueOf(1);
            sessionCookieParameters = ECOM_PunchoutLoginService.encryptWithAES256(sessionCookieParameters);
        }
        
        if(String.isNotBlank(urlParameters)) forwardingUrl = forwardingUrl + '?' + urlParameters;
        response.put(ECOM_Constant.PARAM_COOKIE,sessionCookieParameters);
        response.put(ECOM_Constant.PARAM_FORWARDING_URL,forwardingUrl);
       return response;
    }

    /**
    * @description Method to login user
    * @author vramachandran@rafter.one | 24-11-2023 
    * @param userName
    * @param password
    * @param parameter
    * @return String
    **/
    @TestVisible
    private static Map<String,Object> loginUserToSite(String userName, String password, String parameter){
        String returnUrl = '';
        String message ='';
        
        Boolean success = true;
        
        Map<String,Object> returnMap = new Map<String,Object>();
        PageReference pageParams = Site.login(userName, password, parameter);
        
        if(null != pageParams && null != pageParams.getUrl()){
            returnUrl = pageParams.getUrl();
            returnMap.put(ECOM_Constant.PARAM_STOREFRONT_URL, returnUrl);
        } else {
            message = System.Label.ECOM_107003;
            success = false;
        }
        returnMap.put(ECOM_Constant.PARAM_SUCCESS, success);
        returnMap.put(ECOM_Constant.PARAM_MESSAGE, message);
        return returnMap;
    }
    
    /**
     * @description This method inserts a new user with dml options
     * @author vramachandran@rafter.one | 22 Dec 2023
     * @param userRecord | User
     * @param dmlOptions | Database.DMLOptions
     * @returns Boolean
     */
    private static Map<String,Object> createUserWithDmlOptions(User userRecord, Database.DMLOptions dmlOptions){
        Boolean isUserCreated = false;
        Map<String,Object> response  = new Map<String,Object>();
        //Added by manoj to fix punchout user creation
        //String calloutResponse = ECOM_PunchoutUserCreation.makeUserCreationCallout(JSON.serialize(userRecord),JSON.serialize(dmlOptions));
        //response = (Map<String,Object>)JSON.deserializeUntyped(calloutResponse);
        Database.SaveResult result = Database.insert(userRecord, dmlOptions);
        System.debug('ress__'+result);
        //RWPS-1675
        response.put('assignPermissionSets',true);
        if(null != result && result.isSuccess()){
            isUserCreated = true;
            response.put('isUserCreated',isUserCreated);
            response.put('userId',result.getId());
        }else if(null != result && result.getErrors()!=null){ //RWPS-1543 - START   
            for(Database.Error err : result.getErrors()) { 
                if(err.getStatusCode()==StatusCode.DUPLICATE_USERNAME){//RWPS-1675
                    //RWPS-2106 - START
                    List<User> users = [Select Id  FROM User where email=:userRecord.Email];
                    if(users.size() >0){
                        response.put('isUserCreated',true);
                        response.put('userId',users[0].Id);
                        response.put('assignPermissionSets',false);
                    }
                    //RWPS-2106 - END
                    response.put(ECOM_Constant.PARAM_PUNCHOUT_EXCEPTION, err.getStatusCode() + 
                    ': ' + err.getMessage() +' fields '+ err.getFields());  
                }else if(response.get(ECOM_Constant.PARAM_PUNCHOUT_EXCEPTION)==null)
                response.put(ECOM_Constant.PARAM_PUNCHOUT_EXCEPTION, err.getStatusCode() + 
                    ': ' + err.getMessage() +' fields '+ err.getFields());
                else{
                    response.put(ECOM_Constant.PARAM_PUNCHOUT_EXCEPTION,
                    response.get(ECOM_Constant.PARAM_PUNCHOUT_EXCEPTION) + ' '+ err.getStatusCode() + 
                    ': ' + err.getMessage()+' fields :'+ + err.getFields());
                }
        }
    }
    //RWPS-1543 - END
        
        return response;
    }    

    /**
     * @description This method returns the sales Org for a given user record
     * @author vramachandran@rafter.one | 24 Jan 2024
     * @param userCountry | String 
     * @returns String
     */
    @TestVisible
    private static String getSalesOrgForCountry(String country){
        
        String salesOrg;
        
        List<C_META_Countries__mdt> salesOrgMappings = [select Id, Country__c, SalesOrg__c, CountryISOAlpha2__c, CountryISOAlpha3__c 
                                                        FROM C_META_Countries__mdt 
                                                        Where Country__c = :country LIMIT 1];
        
        if(salesOrgMappings.isEmpty()){
            salesOrgMappings = [select Id, Country__c, SalesOrg__c, CountryISOAlpha2__c, CountryISOAlpha3__c 
                                FROM C_META_Countries__mdt 
                                WHERE
                                CountryISOAlpha2__c = :country LIMIT 1];
        }
        if(salesOrgMappings.isEmpty()){
            salesOrgMappings = [select Id, Country__c, SalesOrg__c, CountryISOAlpha2__c, CountryISOAlpha3__c 
                                FROM C_META_Countries__mdt 
                                WHERE
                                CountryISOAlpha3__c = :country LIMIT 1];
        }
        
        if(null != salesOrgMappings && !salesOrgMappings.isEmpty()){
            salesOrg = salesOrgMappings[0].SalesOrg__c;
        }
        
        return salesOrg;
    }

    
     /**
    * @description Fetch Profile Record for ProfileName
    * @author vramachandran@rafter.one | 22 Nov 2023 
    * @param profileName 
    * @return List<Profile> 
    **/
    @TestVisible
    private static List<Profile> getProfileRecords(String profileName){
        return [SELECT Id, Name FROM Profile WHERE Name =: profileName LIMIT 1];
    }
     /**
    * @description Method to generate a new random password
    * @author vramachandran@rafter.one | 24 Nov 2023 
    * @return String
    **/
    @TestVisible
    private static String getNewPassword(){
        
        String newRandomPassword = generateRandomString(PASSWORD_CHARSET_ALPHABETS, 7);
        newRandomPassword = newRandomPassword + '@' + generateRandomString(PASSWORD_CHARSET_NUMERIC, 7);
        
        return newRandomPassword;
    }
     /**
    * @description The method to extract first 5 characters of the user's lastname
    * @author vramachandran@rafter.one | 24 Nov 2023
    * @param dataInformation 
    * @return String 
    **/
    @TestVisible
    private static String getSuppressedLastName(String lastName)
    {
        String ln=lastName;
        return (ln.length()>5?ln.substring(0,5):ln);
    }

     /**
    * @description  - method is used to generate a random String
    * @author Vasudev Ramachandran | 24 Nov 2023 
    * @param chars
    * @param len
    * @return String
    **/
    @TestVisible
    private static String generateRandomString(String chars, Integer len){
        String password='';
        while (password.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            password += chars.substring(idx, idx+1);
        }
        return password;
    }

    /**
     * @description This method assign permission to punchout user  by reading C_META_PSET_Defaults__mdt metadata
     * It is running in future as we cannot update setup and non setup objects in same transaction.
     * @author Manoj Kumar | 22 May 2024
     * @param userId | String
     * @returns NA
     */
    @future
    @TestVisible
    private static void assignPermissionSetToUser(String userId){
         List<C_META_PSET_Defaults__mdt> psets=[Select id,PSET_ID__c from C_META_PSET_Defaults__mdt 
                                                            where User_Profile__c=:System.Label.ECOM_CommunityProfileName];
        List<PermissionSetAssignment> permissionSetAssignments=new List<PermissionSetAssignment>();
        for(C_META_PSET_Defaults__mdt pset :psets ){
            PermissionSetAssignment psa = new PermissionSetAssignment();
            psa.PermissionSetId=pset.PSET_ID__c;
            psa.AssigneeId=userId;
            permissionSetAssignments.add(psa);
        }
        
        if(!permissionSetAssignments.isEmpty()){
            insert permissionSetAssignments;
        }
    }

     /**
     * @description This method returns the request model from the given decrypted string
     * @author vramachandran@rafter.one | 22 Dec 2023
     * @param decryptedRequestString | String
     * @return ECOM_PunchoutWrapper.PunchoutServiceRequest
     */
    public static ECOM_PunchoutWrapper.PunchoutServiceRequest getModelFromString(String decryptedRequestString){
        ECOM_PunchoutWrapper.PunchoutServiceRequest requestModel; 
        Map<String,String> requestMap = new Map<String,String>();
        
        //split the url parameter with delimiter
        List<String> requestKeyValueList = decryptedRequestString.split('&');
        
        //loop through each delimited value and split into key value pair
        for(String keyValue : requestKeyValueList){
            List<String> keyValueList = keyValue.split('=');

            //RWPS-266 - GAr - 6 March 2024 - added buyerCookie and payLoadId to decrypt them also
            if(null != keyValueList && (keyValueList[0]=='browserFormPost' || keyValueList[0]=='buyerCookie' || keyValueList[0]=='payLoadId')){//for decoding the URL


                if(keyValueList[1] != 'EMPTY_STRING' && keyValueList[1] != 'emailEncodingKey'){
                    String decodedUrl = EncodingUtil.urlDecode(keyValueList[1], ECOM_Constant.URL_ENCODING_UTF_8);
                    requestMap.put(keyValueList[0],decodedUrl);
                }
            }
            else if(null != keyValueList && keyValueList[1] != 'EMPTY_STRING' && keyValueList[0] != 'emailEncodingKey') {
                requestMap.put(keyValueList[0] , keyValueList[1]); 
            }
        }       
        //convert the key value map into request model 
        requestModel = (ECOM_PunchoutWrapper.PunchoutServiceRequest) JSON.deserialize(JSON.serialize(requestMap), ECOM_PunchoutWrapper.PunchoutServiceRequest.class);
        return requestModel;
    }

    public static String fetchConfigByValue(String labelName) {
        String value = '';
        C_META_Storefront_Configuration__mdt config = C_META_Storefront_Configuration__mdt.getInstance(labelName);
        if (config != null) {
            value = String.isNotBlank(config.Value__c) ? config.Value__c : '';
        }
        return value;
    }
    /* RWPS-1256 Code end here*/

    /**
    * @description This method will check configuration & create contact & user 
    * @author manish.joshi@revvitry.com | 02-13-2026 
    * @param requestModel | ECOM_PunchoutWrapper.PunchoutServiceRequest
    * @return Map<String, Object> 
    **/
    public static Map<String,Object> checkAndProvisionNewContactAndUser(ECOM_PunchoutWrapper.PunchoutServiceRequest requestModel){
        Map<String,Object> responseMap = new Map<String,Object>();
        //check if ERP Address information is configured for given account
        Map<String,ERP_Address__c> addressMap  = ECOM_PunchoutLoginService.gePunchoutAddress(requestModel.fromCredentialIdentity);
        //if request is mapped to a valid erp address, proceed to check for contact and user provisioning
        if(null != addressMap && !addressMap.isEmpty() && addressMap.size() > 3){
            //create new contact 
            responseMap.putAll(validateAndCreateContact1(requestModel, addressMap));
            if(responseMap.containsKey(ECOM_Constant.PARAM_SUCCESS) && (Boolean)responseMap.get(ECOM_Constant.PARAM_SUCCESS) && responseMap.containsKey(ECOM_Constant.PARAM_CONTACT_RECORD) ){
                //create new user
                responseMap.putAll(createNewPunchoutUser1(requestModel, addressMap, (Contact)responseMap.get(ECOM_Constant.PARAM_CONTACT_RECORD)));
            }
        } else {
            //no erp master found for posr request, mark response for auth fail
            responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
            responseMap.put(ECOM_Constant.PARAM_MESSAGE, System.Label.ECOM_107006);
            List<String> addressIds = new List<String>();
            addressIds.add(ECOM_Constant.ERP_ADDRESS_TYPE_SHIP_TO +' - '+ (addressMap.containsKey(ECOM_Constant.ERP_ADDRESS_TYPE_SHIP_TO) ?  addressMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_SHIP_TO).Id:null));
            addressIds.add(ECOM_Constant.ERP_ADDRESS_TYPE_SOLD_TO +' - '+ (addressMap.containsKey(ECOM_Constant.ERP_ADDRESS_TYPE_SOLD_TO) ?  addressMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_SOLD_TO).Id : null));
            addressIds.add(ECOM_Constant.ERP_ADDRESS_TYPE_PAYER +' - '+ (addressMap.containsKey(ECOM_Constant.ERP_ADDRESS_TYPE_PAYER)?addressMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_PAYER).Id:null));
            addressIds.add(ECOM_Constant.ERP_ADDRESS_TYPE_MASTER +' - '+ (addressMap.containsKey(ECOM_Constant.ERP_ADDRESS_TYPE_MASTER) ?  addressMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_MASTER).Id:null));
            responseMap.put(ECOM_Constant.PARAM_PUNCHOUT_ADDRESSES,addressIds);
        }
        return responseMap;
    }
}