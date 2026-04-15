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
*    - ECOM_PunchoutLoginController_Test
*
* 7. Is @Invocable (Yes or No): Yes
*
* 8. Author Name(s):
*    -Vasudev Ramachandran 2023/11/24
*    -Vasudev Ramachandran 2024/02/15 - Update to fix empty Org name when new  user is created
*    -Gaurang Arora 2024/03/06 - RWPS-266 - added buyerCookie and payLoadId to decrypt them also
*    -Sidak 2024.05.20 - RWPS-667 - Moved all the method references to ECOM_PunchoutLoginService class
*    -Sidak 2024.05.20 RWPS-667 Added methods  logFailure, storeExceptionLog, setupApplicationRecord, getSystemLimits
*    -Manoj 2024.05.22 RWPS-685 Staging punchout user created with incomplete info(PS not getting assigned)
*    -Sidak 2024.06.18 RWPS-920 Updated method createNewPunchoutUser, added null check for userResponse map
*    -Sidak 2024.06.24 RWPS-920 Updated method createNewPunchoutUser, initialized isNewUserCreated value to false
*    -Sidak 2024.07.09 RWPS-1038 Updated method updateUserAsPunchoutUserOrContact, added logic to update contact as punchout contact
*    -Sidak 2024.07.31 RWPS-1170 Updated method validateAndCreateContact, added logic to update country provided on contact
*    -Sidak 2024.08.02 RWPS-1161 Updated method punchoutLogin, added logic to update firstname, lastname on user from contact record
*    -Sidak 2024.09.02 RWPS-1378 Updated method insertPOSRResponseLog, added logic to populate error message in case user record is null
*    -Manish 2024.09.19 RWPS-1256 punchout architecture is changed & new implementation is 
*	 done using methods punchoutLogin, checkAndProvisionNewContactAndUser1, validateAndCreateContact1, createNewPunchoutUser1,insertPOSRResponseLog1
*    -Manish 2024.09.27 RWPS-1543 Added additional logging to for punchout user failure.
*    -Sidak 2024.10.04 RWPS-1671 Updated method punchoutLogin, added logic to update contact and user record name from posr request
*    -Manoj 2024.10.07 RWPS-1675 Handled the exception when two requests come from the same buyer network
*    - Manish Joshi 2026.02.02 - Updated method validateTestUserForAccountId RWPS-5776
*    -Sachin V 2026.01.29 - Updated method : validateAndCreateContact - RWPS-5938
*    - Princy Anthony 2026.04.07 Updated method checkAndProvisionNewContactAndUser - RWPS-7243
*************************************************************/
public without sharing class ECOM_PunchoutLoginController {
    
    final static String CLASSNAME = 'ECOM_PunchoutLoginController';
    
    private final static String PASSWORD_CHARSET_ALPHABETS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    private final static String PASSWORD_CHARSET_NUMERIC = '0123456789';
    private final static String PASSWORD_CHARSET_ALPHANUMERIC = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
    
    /**
     * description This method returns the encrypted parameters for session creation
     * @author vramachandran@rafter.one | 04 Jan 2024
     * @param userType | String 
     * @param userRecord | User
     * @param forwardingUrl | String 
     * @returns String 
     */
    @TestVisible
    private static String getEncryptedStoreUrl(String userType, User userRecord, String forwardingUrl, ECOM_PunchoutWrapper.PunchoutServiceRequest requestModel, Boolean isTestUser){
        String userTypeParameter;
        String requestModelParameter;
        String urlParameters;
        String cmsParameters;
        String sessionCookieParameters;
        
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
                
            Cookie ck = new Cookie(System.Label.ECOM_CookieName , sessionCookieParameters, null, -1, true, 'Lax');
            if(!Test.isRunningTest()){
                ApexPages.currentPage().setCookies(new Cookie[]{ck});  
            }   
        }
        
        if(String.isNotBlank(urlParameters)) forwardingUrl = forwardingUrl + '?' + urlParameters;
        
       return forwardingUrl;
    }
    
    /**
     * @description This method checks account information and creates, new user and contact
     * @author vramachandran@rafter.one | 22 Dec 2023
     * @param requestModel | ECOM_PunchoutWrapper.PunchoutServiceRequest
     * @returns Map<String,Object>
     */
    public static Map<String,Object> checkAndProvisionNewContactAndUser(ECOM_PunchoutWrapper.PunchoutServiceRequest requestModel){
        Map<String,Object> responseMap = new Map<String,Object>();
        System.debug('requestModel :: '+ JSON.serialize(requestModel));
        //check if ERP Address information is configured for given account
        //start-7243
         ERP_AddressModel addressModel = new ERP_AddressModel();
         Map<String, ERP_Address__c> addressMap  = new Map<String, ERP_Address__c>();
         List<Punchout_Maintenance__c> configRecordList = ERP_AddressRepo.getPunchoutConfigs(null,null,requestModel.fromCredentialIdentity,null);
         if(configRecordList != null && !configRecordList.isEmpty()) {
            responseMap.put(ECOM_Constant.PUNCHOUT_CONFIG_REC,configRecordList[0]);
            String masterId = configRecordList[0].ERP_Address__c;
            addressMap = ECOM_PunchoutLoginService.gePunchoutAddress(masterId, configRecordList[0]);
            responseMap.putAll(addressMap); 
            List<ERP_Address__c> erpMasterAddressList = new List<ERP_Address__c>(addressMap.values());
            addressModel =ECOM_PunchoutLoginService.getAddressModel(erpMasterAddressList);
            addressModel.po_PunchoutResponseFormat = addressModel.po_PunchoutResponseFormat==null && configRecordList[0]!=null
                                                     ?configRecordList[0].ECOM_Punchout_Format__c:addressModel.po_PunchoutResponseFormat;
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
                                                    ? configRecordList[0].ECOM_Punchout_Customer_Name__c : addressModel.po_AccountName;
         }
        //end-7243
       // ERP_AddressModel addressModel = ECOM_PunchoutLoginService.getPunchoutAddressesForERPAddressModel(requestModel.fromCredentialIdentity);// VRa: Punchout changes - updated 15 Jan 2024
        System.debug('addressModel_______'+addressModel);
        //if request is mapped to a valid erp address, proceed to check for contact and user provisioning
        if(null != addressModel && String.isNotBlank(addressModel.accountId)){
            responseMap.put(ECOM_Constant.PARAM_ERP_ACCOUNT_MODEL, addressModel);
            
            //create new contact 
            responseMap.putAll(validateAndCreateContact(requestModel, addressModel));
            
            if(responseMap.containsKey(ECOM_Constant.PARAM_SUCCESS) && (Boolean)responseMap.get(ECOM_Constant.PARAM_SUCCESS) && responseMap.containsKey(ECOM_Constant.PARAM_CONTACT_RECORD) ){
                
                //create new user
                responseMap.putAll(createNewPunchoutUser(requestModel, addressModel, (Contact)responseMap.get(ECOM_Constant.PARAM_CONTACT_RECORD)));
            } 
            
        } else {
            //no erp master found for posr request, mark response for auth fail
            responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
            responseMap.put(ECOM_Constant.PARAM_MESSAGE, System.Label.ECOM_107006);
        }
        
        return responseMap;
    }

    
    /**
     * @description This method checks and creates a new contact if contact does not exist for given email
     * @author vramachandran@rafter.one | 22 Dec 2023
     * @param requestModel | ECOM_PunchoutWrapper.PunchoutServiceRequest 
     * @param addressModel | ERP_AddressModel
     * @return Contact
     */
    public static Map<String,Object> validateAndCreateContact(ECOM_PunchoutWrapper.PunchoutServiceRequest requestModel, ERP_AddressModel addressModel){
        final String METHOD_NAME = 'validateAndCreateContact';
        
        Map<String,Object> responseMap = new Map<String,Object>();
            
            Contact contactRecord = ECOM_PunchoutLoginService.getContactRecordForEmail(requestModel.userEmail);
        
            //contact does not exist, create new contact
            if(null == contactRecord && String.isNotBlank(addressModel.accountId)){
                //create new contact
                Contact newPunchoutContact = new Contact();
                newPunchoutContact.FirstName = requestModel.firstName;
                newPunchoutContact.LastName = requestModel.lastName;
                newPunchoutContact.Email = requestModel.userEmail;
                newPunchoutContact.AccountId = addressModel.accountId;
                newPunchoutContact.ECOM_NeedsVerification__c = true;
                newPunchoutContact.ECOM_AccountNameProvided__c = addressModel.po_AccountName;
                if(null != addressModel?.po_CountryName && String.isNotEmpty(addressModel?.po_CountryName)) newPunchoutContact.ECOM_CountryProvided__c =  addressModel?.po_CountryName;
                newPunchoutContact.ECOM_Is_Punchout_Contact__c = true;
                if(null != addressModel?.po_ShipToAddress && String.isNotEmpty(addressModel?.po_ShipToAddress?.id)) newPunchoutContact.Default_Ship_to_ERP_Address__c = addressModel.po_ShipToAddress.id;
                if(null != addressModel?.po_SoldToAddress && String.isNotEmpty(addressModel?.po_SoldToAddress?.id)) newPunchoutContact.Default_Sold_to_ERP_Address__c = addressModel.po_SoldToAddress.id;
                if(null != addressModel?.po_PayerAddress && String.isNotEmpty(addressModel?.po_PayerAddress?.id)) newPunchoutContact.Default_Bill_to_ERP_Address__c = addressModel.po_PayerAddress.id;
                if(null != addressModel?.po_CurrencyIsoCode && String.isNotEmpty(addressModel?.po_CurrencyIsoCode)) newPunchoutContact.CurrencyIsoCode = addressModel.po_CurrencyIsoCode;
                if(String.isNotEmpty(newPunchoutContact.Default_Bill_to_ERP_Address__c) && String.isNotEmpty(newPunchoutContact.Default_Ship_to_ERP_Address__c)) newPunchoutContact.ECOM_Is_Mapped__c = true;
                newPunchoutContact.ECOM_AddressRegistration__c = System.Label.ECOM_Completed;
                insert newPunchoutContact;
                
                //add new contact record to response
                responseMap.put(ECOM_Constant.PARAM_CONTACT_RECORD, newPunchoutContact);
                responseMap.put(ECOM_Constant.PARAM_SUCCESS, true);
            } else {
                //RWPS-1170 Update country provided on contact
                contactRecord.ECOM_CountryProvided__c = addressModel.po_CountryName;
                //if current contact record is not linked to an account check if an account is available on addressmodel
                if(null!= contactRecord && String.isNotBlank(contactRecord.AccountId)){
                    contactRecord.AccountId = addressModel.accountId;
                    // RWPS-685 combined methods
                    updateUserAsPunchoutUserOrContact(JSON.serialize(contactRecord),'Contact');
                    responseMap.put(ECOM_Constant.PARAM_CONTACT_RECORD, contactRecord);
                    responseMap.put(ECOM_Constant.PARAM_SUCCESS, true);
                } else if(null== contactRecord){
                    //contact was not found
                    responseMap.put(ECOM_Constant.PARAM_CONTACT_RECORD, contactRecord);
                    responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
                } else {
                    if(!contactRecord.ECOM_Is_Punchout_Contact__c){
                        contactRecord.ECOM_Is_Punchout_Contact__c = true;
                        // RWPS-685 combined methods
                        updateUserAsPunchoutUserOrContact(JSON.serialize(contactRecord),'Contact');
                    }

                    //contact record exists
                    responseMap.put(ECOM_Constant.PARAM_CONTACT_RECORD, contactRecord);
                    responseMap.put(ECOM_Constant.PARAM_SUCCESS, true);
                }
            }

        return responseMap;
    }
    

    /**
     * @descripton This method checks if a contact exists and if Default ERP Addresses are populated
     * @author vramachandran@rafter.one | 05 Jan 2024
     * @param userEmail | String
     * @param addressModel | ERP_AddressModel
     * @returns 
     */
    //public static void validateContactAndContactAddress(String userEmail, ERP_AddressModel addressModel){
       //Contact contactRecord =  ECOM_PunchoutLoginService.getContactRecordForEmail(userEmail);
public static void validateContactAndContactAddress(User userRecord, ERP_AddressModel addressModel){
        //Contact contactRecord =  getContactServiceInstance().getContactRecordForEmail(userEmail);
		Contact contactRecord =  getContactForEmail(userRecord.ContactId);
        Boolean isUpdate = false;
        try{
            if(null!= contactRecord){

                //check if contact is not marked as punchout 
                if(!contactRecord.ECOM_Is_Punchout_Contact__c){
                    contactRecord.ECOM_Is_Punchout_Contact__c = true; isUpdate = true;
                }
				//VRa Changes for ECOM 2357: begin
                //check if contact email is different from user email
                if(contactRecord.Email != userRecord.Email) {
                    contactRecord.Email = userRecord.Email; 
                    contactRecord.External_ID__c =userRecord.Email; isUpdate = true;
                }

                //check if contact account is not same as erp address account 
                if(contactRecord.AccountId != addressModel.accountId){
                    contactRecord.AccountId = addressModel.accountId; isUpdate = true;
                }
                
                //check for default payer is linked to contact, else update with payer from master address
                if((null == contactRecord.Default_Bill_to_ERP_Address__c && null != addressModel.po_PayerAddress) ||
                    (null != contactRecord.Default_Bill_to_ERP_Address__c && null != addressModel.po_PayerAddress && contactRecord.Default_Bill_to_ERP_Address__c != addressModel.po_PayerAddress.Id)) {
                    contactRecord.Default_Bill_to_ERP_Address__c = addressModel.po_PayerAddress.Id; isUpdate = true;
                }
                //check if default ship to is assigned to contact, else update with ship to from master address
                if((null == contactRecord.Default_Ship_to_ERP_Address__c && null != addressModel.po_ShipToAddress) ||
                    (null != contactRecord.Default_Ship_to_ERP_Address__c && null != addressModel.po_ShipToAddress && contactRecord.Default_Ship_to_ERP_Address__c != addressModel.po_ShipToAddress.Id)) {
                    contactRecord.Default_Ship_to_ERP_Address__c = addressModel.po_ShipToAddress.id; isUpdate = true;
                }
                //check if default sold to is assigned to contact, else update with sold to from master address
                if((null == contactRecord.Default_Sold_to_ERP_Address__c && null != addressModel.po_SoldToAddress) ||
                    (null != contactRecord.Default_Sold_to_ERP_Address__c && null != addressModel.po_SoldToAddress && contactRecord.Default_Sold_to_ERP_Address__c != addressModel.po_SoldToAddress.Id)) {
                    contactRecord.Default_Sold_to_ERP_Address__c = addressModel.po_SoldToAddress.id; isUpdate = true;
                }

                //check if country provided on account is different from master address, else update from Country Name from ERP Master
                if(String.isBlank(contactRecord.ECOM_CountryProvided__c) ||
                   (String.isNotBlank(contactRecord.ECOM_CountryProvided__c) && contactRecord.ECOM_CountryProvided__c != addressModel.po_CountryName)) {
                    contactRecord.ECOM_CountryProvided__c = addressModel.po_CountryName; isUpdate = true;
                }
                //VRa Changes for ECOM 2357: end

                //System.debug('Updated Contact Record:: ' + JSON.serialize(contactRecord));

                //RWPS-5938
                if (ECOM_CustomLoginController.getMagicLinkImplementationActivationStatus() == true) {
                    contactRecord.ECOM_Punchout_Via_Web__c = false;
                    isUpdate = true;
                }
                //RWPS-5938
                if(isUpdate){
                    // RWPS-685 combined methods
                    updateUserAsPunchoutUserOrContact(JSON.serialize(contactRecord),'Contact');
                }
            }
        }catch(Exception e){
            System.debug('Cause:: '+ e.getMessage() + ' StackTraceString:: '+ e.getStackTraceString());
        }
        
    }
    
    
    /**
     * @description This method creates a new user for a punchout service request
     * @author vramachandran@rafter.one | 22 Dec 2023
     * @param requestModel | ECOM_PunchoutWrapper.PunchoutServiceRequest 
     * @param addressModel | ERP_AddressModel 
     * @returns Map<String,Object>
     */
    public static Map<String,Object> createNewPunchoutUser(ECOM_PunchoutWrapper.PunchoutServiceRequest requestModel, ERP_AddressModel addressModel, Contact contactRecord){
        final String METHOD_NAME = 'createNewPunchoutUser';
        Map<String,Object> responseMap = new Map<String,Object>();
        
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
            newUser.TimeZoneSidKey = addressModel.po_TimeZone!=null?addressModel.po_TimeZone:'America/Los_Angeles';
            newUser.LanguageLocaleKey = requestModel.locale;
            newUser.ECOM_Is_Punchout_User__c = true;
            newUser.IsActive = true;
            // RWPS-685 refactored code
            if(null != addressModel?.po_CurrencyIsoCode && String.isNotEmpty(addressModel?.po_CurrencyIsoCode)){
             	newUser.CurrencyIsoCode = addressModel?.po_CurrencyIsoCode;
            }
            if(null != addressModel?.po_CurrencyIsoCode && String.isNotEmpty(addressModel?.po_CurrencyIsoCode)){
                newUser.DefaultCurrencyIsoCode = addressModel?.po_CurrencyIsoCode;//requestModel.countryCode;
            }
            if(null != addressModel?.po_CountryCode && String.isNotEmpty(addressModel?.po_CountryCode)){
                newUser.CountryCode = addressModel?.po_CountryCode; //requestModel.countryCode;
            } 
            //assign new dml option to suppress welcome email for new user
            Database.DMLOptions dmlOptionsInstance = new Database.DMLOptions();
            dmlOptionsInstance.emailHeader.triggerUserEmail = false;
            // RWPS-685 changed method return type
            Map<String,Object> userResponse = createUserWithDmlOptions(newUser,dmlOptionsInstance);
            Boolean isNewUserCreated = false; //RWPS-920 Initialized value to false
            if(userResponse.containsKey('isUserCreated') && userResponse.get('isUserCreated') != null){ //RWPS-920 Addded null check for userResponse map
                isNewUserCreated = (Boolean)userResponse.get('isUserCreated');
                if(isNewUserCreated){
                    assignPermissionSetToUser((String)userResponse.get('userId') );
                    Contact con = new Contact();
                    con.Id = contactRecord.Id;
                    con.ECOM_isEnabled__c = true;
                    con.fxUserURL__c='/lightning/r/User/'+(String)userResponse.get('userId')+'/view';
                    updateUserAsPunchoutUserOrContact(JSON.serialize(con),'Contact');
                }
            }
            
            responseMap.put(ECOM_Constant.PARAM_USER_RECORD, newUser);
            responseMap.put(ECOM_Constant.PARAM_USER_NAME, newUser.Username);
            responseMap.put(ECOM_Constant.PARAM_SUCCESS, isNewUserCreated);
            responseMap.put(ECOM_Constant.PARAM_IS_NEW_USER, true);
        }catch(Exception e){
            responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
            responseMap.put(ECOM_Constant.PARAM_MESSAGE, System.Label.ECOM_107002);
            logFailure(e , 'Punchout:: User Creation' , CLASSNAME , METHOD_NAME, 'POSR:: '+ JSON.serialize(requestModel)  + ' Stack:: '+ e.getStackTraceString());
        }
        
        return responseMap;
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
        //RWPS-5938
        if (ECOM_CustomLoginController.getMagicLinkImplementationActivationStatus() == true) {
            List<User> userList = [SELECT Id, Name, ContactId FROM User WHERE email =:userName AND ECOM_Is_Punchout_User__c = true LIMIT 1];
            if (userList.isEmpty() == false && userList[0] != null && userList[0].ContactId != null) {
                update new Contact(Id = userList[0].ContactId, ECOM_Punchout_Via_Web__c = false);
            }
        }
        //RWPS-5938
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
     * @description This method inserts the POSR log
     * @author vramachandran@rafter.one | 22 Dec 2023
     * @param requestMap | Map<String,Object>
     */
    public static void insertPOSRRequestLog(Boolean isLoginSuccessful, ECOM_PunchoutWrapper.PunchoutServiceRequest requestModel, User userRecord){//GAr: 2024.02.12 RWPS-73
        Map<String,Object> requestMap = new Map<String,Object>();
        ECOM_PunchoutWrapper.PunchoutServiceRequest posrRequest;
        
        if(null != requestModel){
            //System.debug('posrRequest:: '+ posrRequest);
            
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
                    User user = getPunchoutUserInformationByUserNameForLogin(userRecord.email);
                    if(user!=null){
                       isUserCreated = true;
                        response.put('isUserCreated',isUserCreated);
                        response.put('userId',user.ID);
                        response.put('assignPermissionSets',false);
                    }else{
                        response.put(ECOM_Constant.PARAM_PUNCHOUT_EXCEPTION, err.getStatusCode() + 
                    ': ' + err.getMessage() +' fields '+ err.getFields());
                    }
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
     * @description This method inserts the POSR response based on the user login 
     * @author vramachandran@rafter.one | 04 Jan 2024
     * @param isLoginSuccessful | Boolean
     * @param redirectUrl | String
     * @param userId | String
     * @param userEmail | String
     * @param message | String
     */
    @TestVisible //RWPS-5776
    private static void insertPOSRResponseLog(Boolean isLoginSuccessful, String redirectUrl, User userRecord, String message, String accountId){
        try{
            
            Map<String,Object> responseMap = new Map<String,Object>();
            responseMap.put(ECOM_Constant.PARAM_PUNCHOUT_USER_LOGIN_SUCCESS, isLoginSuccessful);
            responseMap.put(ECOM_Constant.PARAM_STOREFRONT_URL, redirectUrl);
            if(null != userRecord){
                responseMap.put(ECOM_Constant.PARAM_USER_ID, null != userRecord? userRecord.Id : null);
                responseMap.put(ECOM_Constant.PARAM_USER_EMAIL, null != userRecord.Email? userRecord.Email : null);
            }
            responseMap.put(ECOM_Constant.PARAM_PUNCHOUT_ACCOUNT_ID, accountId);
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
            logFailure(e, 'Punchout:: Insert POSR Response - Failed', CLASSNAME, 'insertPOSRResponseLog', 'Message:: '+ e.getMessage()+ ' Stack:: '+ e.getStackTraceString());
        }
    } 
    
    /**
     * @description This method logs in the test user for a punchout account and returns the login URL
     * @author vramachandran@rafter.one | 07 Jan 2024
     * @returns ECOM_PunchoutWrapper.PunchoutServiceRequest
     */
    @TestVisible
    private static ECOM_PunchoutWrapper.PunchoutServiceRequest getRequestModelForTestUser(){
        ECOM_PunchoutWrapper.PunchoutServiceRequest requestModel = new ECOM_PunchoutWrapper.PunchoutServiceRequest();
        
        String testUserConfig = ECOM_PunchoutLoginService.getStoreNavigationConfig(System.Label.ECOM_TestUserConfigMetadata);
        
        if(String.isNotEmpty(testUserConfig)){
            requestModel = (ECOM_PunchoutWrapper.PunchoutServiceRequest) JSON.deserialize(testUserConfig, ECOM_PunchoutWrapper.PunchoutServiceRequest.class);   
        }
        
        return requestModel;
    }
    
    /**
     * @description This method performs callout and resets user password
     * @author vramachandran@rafter.one | 07 Jan 2024
     * @param userId | String
     * @param password | String
     * @returns Map<String,String>
     */
    @TestVisible
    private static Boolean resetPassword(String userId, String password){
        Boolean isSuccess = false;
        Map<String,String> bodyMap = new Map<String,String>();
        bodyMap.put(ECOM_Constant.PARAM_PUNCHOUT_TOKEN, ECOM_PunchoutLoginService.encryptWithAES256(userId));
 		bodyMap.put(ECOM_Constant.PARAM_PUNCHOUT_CODE, ECOM_PunchoutLoginService.encryptWithAES256(password));     
        Map<String,String> requestMap = new Map<String,String>();
        requestMap.put(ECOM_Constant.HTTP_REQUEST_BODY, JSON.serialize(bodyMap));
        
        Map<String,String> requestHeader = ECOM_PunchoutLoginService.prepareRequestForTestUserPasswordReset(JSON.serialize(bodyMap));
        System.debug('requestHeader:: '+ requestHeader);
        //callout for creating contact, user and resetting password
        HttpResponse passwordResetResponse = ECOM_PunchoutLoginService.performRestCallout(requestHeader);
        
        if(null != passwordResetResponse && passwordResetResponse.getStatusCode() == 200){
            isSuccess = true;
        } 
        return isSuccess;
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
                AND IsActive = true
				AND ECOM_Is_Punchout_User__c = true
                LIMIT 1 ];
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
     * @description This method returns the userRecord for a userName
     * @author vramachandran@rafter.one | 22 Dec 2023
     * @param userName | String
     * @returns User
     */
    public static User getPunchoutUserForUserName(String userName){
        User userRecord;
        List<User> userRecordList = ECOM_PunchoutLoginService.getPunchoutUserInformationByUserName(userName);
        if(null != userRecordList && !userRecordList.isEmpty()){
            userRecord = userRecordList[0];
        }
        return userRecord;
    }


	/**
	 * @description This method checks if a test user exists for a given account Id, else creates a new one and resets password
	 * @author vramachandran@rafter.one | 20 Jan 2024
	 * @param accountId | String
	 * @returns Map<String,Object>
	 */
    @AuraEnabled
    public static Map<String,Object> validateTestUserForAccountId(String accountId){
        Map<String,Object> responseMap = new Map<String,Object>();
        Boolean isProceedToLogin = false;
        User userRecord;
        boolean isConfigAvailable =false; // RWPS-5776
        try{
            //create new Custom metadata for test user 
            ECOM_PunchoutWrapper.PunchoutServiceRequest requestModel = Test.isRunningTest() ? ECOM_PunchoutLoginService.createPOSRModelForRevvityPunchoutForExistingUser() : getRequestModelForTestUser();
            requestModel.isTestUser = true;
            System.debug('requestModel:: '+ requestModel);
            //get ERP Account Model for account id
            // ERP_AddressModel addressModel = getAddressServiceInstance().getERPAddressModelForPunchoutAccountId(accountId);
            // RWPS-5776 -  START
            responseMap = ECOM_PunchoutLoginService.getPunchoutAddressesForAccountId(accountId);
            System.debug('---------responseMap'+JSON.serializePretty(responseMap));
            if(responseMap.size()>4){
                isConfigAvailable = true;
            }
            else
            {
                List<String> addressIds = new List<String>();
                addressIds.add(ECOM_Constant.ERP_ADDRESS_TYPE_SHIP_TO +' - '+ (responseMap.containsKey(ECOM_Constant.ERP_ADDRESS_TYPE_SHIP_TO) ?  ((ERP_Address__c) responseMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_SHIP_TO)).Id:null));
                addressIds.add(ECOM_Constant.ERP_ADDRESS_TYPE_SOLD_TO +' - '+ (responseMap.containsKey(ECOM_Constant.ERP_ADDRESS_TYPE_SOLD_TO) ?  ((ERP_Address__c) responseMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_SOLD_TO)).Id : null));
                addressIds.add(ECOM_Constant.ERP_ADDRESS_TYPE_PAYER +' - '+ (responseMap.containsKey(ECOM_Constant.ERP_ADDRESS_TYPE_PAYER)? ((ERP_Address__c) responseMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_PAYER)).Id:null));
                addressIds.add(ECOM_Constant.ERP_ADDRESS_TYPE_MASTER +' - '+ (responseMap.containsKey(ECOM_Constant.ERP_ADDRESS_TYPE_MASTER) ?  ((ERP_Address__c) responseMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_MASTER)).Id:null));
                addressIds.add(ECOM_Constant.PUNCHOUT_CONFIG_REC +' - ' + (responseMap.containsKey(ECOM_Constant.PUNCHOUT_CONFIG_REC) ? ((Punchout_Maintenance__c) responseMap.get(ECOM_Constant.PUNCHOUT_CONFIG_REC)).Id:null));
                responseMap.put(ECOM_Constant.PARAM_PUNCHOUT_ADDRESSES,addressIds);
                            
            }
            // RWPS-5776 -  END
            ERP_AddressModel addressModel = (ERP_AddressModel) responseMap.get('AddressModel');
            System.debug('AddressModel:: '+ JSON.serialize(addressModel));
            if(null != addressModel && isConfigAvailable){
                // RWPS-5776 -  START
                Punchout_Maintenance__c configRec = (Punchout_Maintenance__c) responseMap.get(ECOM_Constant.PUNCHOUT_CONFIG_REC); 
                requestModel.userEmail = Test.isRunningTest() ? requestModel.userEmail : requestModel.firstName+'.'+requestModel.lastName +'@'+configRec.ECOM_Punchout_Customer_Id__c.toLowerCase() + '.com.xyz';
                // RWPS-5776 -  END
                requestModel.timezoneSidKey = UserInfo.getTimeZone().getID();
                requestModel.uniqueName = configRec.ECOM_Punchout_Customer_Id__c; // RWPS-5776 
                requestModel.fromCredentialIdentity = configRec.ECOM_Punchout_Customer_Id__c;// VRa : punchout changes added 11 Jan 2024 // RWPS-5776
                System.debug('requestModel:: '+requestModel);
                userRecord = ECOM_PunchoutLoginService.getPunchoutUserForUserName(requestModel.userEmail);
                if(null == userRecord){
                    //user does not exist, create new contact and user
                    requestModel.isNewUser = true;
                    responseMap = checkAndProvisionNewContactAndUser(requestModel);
                    
                    //check if the contact and user provisioning was successful
                    if(null != responseMap && responseMap.containsKey(ECOM_Constant.PARAM_SUCCESS) && (Boolean)responseMap.get(ECOM_Constant.PARAM_SUCCESS)){
                        
                        //get the user record 
                        if(responseMap.containsKey(ECOM_Constant.PARAM_USER_RECORD)){
                            if(null != (User)responseMap.get(ECOM_Constant.PARAM_USER_RECORD)){
                                userRecord = (User)responseMap.get(ECOM_Constant.PARAM_USER_RECORD);
                                isProceedToLogin = true;
                            }
                        }
                    }
                } else {
                    isProceedToLogin = true;
                }
                
                //check if user has been marked for login
                if(isProceedToLogin){
                    
                    //validateContactAndContactAddress(userRecord.Email, addressModel);
                    validateContactAndContactAddress(userRecord, addressModel);

                    responseMap.put(ECOM_Constant.PARAM_SUCCESS, true);
                    responseMap.put(ECOM_Constant.PARAM_USER_RECORD, JSON.serialize(userRecord));
                    responseMap.put(ECOM_Constant.PARAM_REQUEST_MODEL, JSON.serialize(requestModel));
                } else {
                    responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
                }
            }else {
                responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
            }
        }catch(Exception e){
            responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
            System.debug('Cause:: '+ e.getCause() + 'Exception:: '+ e.getStackTraceString());
            logFailure(e , 'Punchout:: Check Test User - Failed' , CLASSNAME , 'validateTestUserForAccountId', 'Stack:: '+ e.getStackTraceString() +  JSON.serialize(responseMap));
            isConfigAvailable = true; // do not print two logs
        }
        // RWPS-5776
        if(!isConfigAvailable){
            ECOM_ApplicationLogsUtil.logApplicationWithCustomExceptionType('Punchout', 
                CLASSNAME, 'validateTestUserForAccountId', JSON.serialize(responseMap),null,
                'Missing Address and Punchout config records','System.QueryException');
        }
        return responseMap;
    }

    
    /**
     * @description This method callouts to login a user with the given request map data
	 * @author vramachandran@rafter.one | 20 Jan 2024
	 * @param requestMap | Map<String,Object>
	 * @returns Map<String,Object>
	 */
    @AuraEnabled
    public static Map<String,Object> calloutToLoginTestUser(Map<String,Object> requestMap){
        Map<String,Object> responseMap = new Map<String,Object>();
        User userRecord;
        
        System.debug('requestMap:: '+ JSON.serialize(requestMap));
        try{
            Map<String,String> bodyMap = new Map<String,String>();
            if(requestMap.containsKey(ECOM_Constant.PARAM_USER_RECORD) && (String)requestMap.get(ECOM_Constant.PARAM_USER_RECORD)!= null){
                
                
                String userMapString = (String) requestMap.get(ECOM_Constant.PARAM_USER_RECORD);
                userRecord = (User)JSON.deserialize(userMapString, User.class);
                System.debug('userRecord:: '+ JSON.serialize(userRecord));
                
                String parameterMapString = (String) requestMap.get(ECOM_Constant.PARAM_REQUEST_MODEL);
                ECOM_PunchoutWrapper.PunchoutServiceRequest requestModel = (ECOM_PunchoutWrapper.PunchoutServiceRequest) JSON.deserialize(parameterMapString, ECOM_PunchoutWrapper.PunchoutServiceRequest.class);
                System.debug('parameterMap:: '+ JSON.serialize(requestModel));
                
                String resetPassword = getNewPassword();
                Boolean isSuccess = resetPassword(userRecord.Id, resetPassword);
                
                //String resetPassword = (String)requestMap.get(ECOM_Constant.PARAM_RESET_PASS);

                Map<String,Object> storeNavigationConfig = ECOM_PunchoutLoginService.getStoreNavigationConfigMap(ECOM_Constant.PARAM_SITE_NAVIGATION_CONFIG_LABEL, ECOM_Constant.POTYPE_TEST_USER);
                
                System.debug('storeNavigationConfig:: '+ storeNavigationConfig);
                String storeForwardingUrl = (String)storeNavigationConfig.get(ECOM_Constant.PARAM_FORWARDING_URL);
                storeForwardingUrl = getEncryptedStoreUrl(ECOM_Constant.POTYPE_PUNCHOUT_USER, userRecord, storeForwardingUrl, requestModel, true);
                System.debug('storeForwardingUrl:: '+ storeForwardingUrl);
                
                Map<String,String> loginRequestMap = new Map<String,String>();
                loginRequestMap.put(ECOM_Constant.PARAM_PUNCHOUT_TOKEN, ECOM_PunchoutLoginService.encryptWithAES256(userRecord.Username));
                loginRequestMap.put(ECOM_Constant.PARAM_PUNCHOUT_CODE, ECOM_PunchoutLoginService.encryptWithAES256(resetPassword));
                loginRequestMap.put(ECOM_Constant.PARAM_USER_ID, ECOM_PunchoutLoginService.encryptWithAES256(userRecord.Id));
                loginRequestMap.put(ECOM_Constant.PARAM_STOREFRONT_URL, ECOM_PunchoutLoginService.encryptWithAES256(storeForwardingUrl));
                Map<String,String> loginMap = ECOM_PunchoutLoginService.preparePunchoutLoginRequest(loginRequestMap);
                
                //callout for logging in user
                HttpResponse calloutResponse = ECOM_PunchoutLoginService.performRestCallout(loginMap);
                System.debug('Repsonse:: '+ calloutResponse.getBody());
                
                //prepare response
                if(calloutResponse != null && calloutResponse.getStatusCode() == 200){
                    Map<String,String> calloutResponseMap = (Map<String,String>)JSON.deserialize(calloutResponse.getBody(), Map<String,String>.class);
                    System.debug('ReturnMap:: '+ calloutResponseMap);
                    
                    String loginUrl = calloutResponseMap.get(ECOM_Constant.PARAM_STOREFRONT_URL);
                    responseMap.put(ECOM_Constant.PARAM_RESPONSE_DATA, loginUrl); 
                    responseMap.put(ECOM_Constant.PARAM_SUCCESS, true); 
                } else {
                    responseMap.put(ECOM_Constant.PARAM_SUCCESS, false); 
                }   
            }
            
            
        }catch(Exception e){
            responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
            System.debug('Cause:: '+ e.getCause() + 'Exception:: '+ e.getStackTraceString());
            logFailure(e , 'Punchout:: Callout To Test User - Failed' , CLASSNAME , 'calloutToLoginTestUser', 'Stack:: '+ e.getStackTraceString());
        }
        
        return responseMap;
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
    
    // RWPS-685 common method to update user and contact
    @future
    @TestVisible
    private static void updateUserAsPunchoutUserOrContact(String data,String objectName){
        if(objectName=='User'){
            System.debug('updateUserAsPunchoutUser:: '+ data);
            List<User> punchoutUsers = [SELECT Id, ECOM_Is_Punchout_User__c 
                                    FROM User 
                                    WHERE Id =: data 
                                    LIMIT 1];
            if(null != punchoutUsers && !punchoutUsers.isEmpty()){
                for(User userRecord : punchoutUsers){
                    userRecord.ECOM_Is_Punchout_User__c = true;
                }
                if(!Test.isRunningTest()){
                    update punchoutUsers;
                }
            }
        }else if(objectName=='Contact'){
            Contact con = (Contact)JSON.deserialize(data, Contact.Class);
            if(!con.ECOM_Is_Punchout_Contact__c){
                con.ECOM_Is_Punchout_Contact__c = true;
            }
            if(!Test.isRunningTest()){
                update con;
            }
        }
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
    * @description  this method is used to log failure exception logs
    * @author singh@rafter.one | 05-20-2024 
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
    * @author singh@rafter.one | 05-20-2024 
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
    * @author singh@rafter.one | 05-20-2024  
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
    * @author singh@rafter.one | 05-20-2024  
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
    * @author singh@rafter.one | 05-20-2024  
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
    
/**
     * @description returns the contact record for given ContactId 
     * @author vramachandran@rafter.one | Jun 17 2024 | ECOM- 2357
     * @param contactId | String 
     * @returns Contact
     */
    @TestVisible
    private static Contact getContactForEmail(String contactId){
        Contact contactRecord;
        List<Contact> contactList = [SELECT Id, FirstName, LastName, AccountId, 
                Default_Bill_to_ERP_Address__c,Default_Ship_to_ERP_Address__c,Default_Sold_to_ERP_Address__c,
                ECOM_Is_Punchout_Contact__c, ECOM_CountryProvided__c, Email, External_ID__c
                FROM Contact
                WHERE Id =: contactId
                LIMIT 1];
        
        if(null != contactList && !contactList.isEmpty()) {
            contactRecord = contactList[0];
        }
        
        return contactRecord;
    }

    /*RWPS-1256 code start here*/

    /**
     * @description This method logs in the user and redirects to session inititate page
     * @author manish.joshi@revvity.com | 16 Sept 2024
     * @param TBD
     * @return PageReference
     */
    public static PageReference punchoutLogin(){
        Boolean isProceedToLogin = false;
        Boolean isLoginSuccess = false;
        Boolean isException = false;
        //Object variables
        PageReference poPageReference;
        //Get page url parameters
        Map<String, String> pageParametersMap = ApexPages.currentPage().getParameters();
        Map<String,Object> returnMap = new Map<String,Object>();
        //fetch the url parameter map
        String encryptedToken = fetchValueForProperty(pageParametersMap, ECOM_CONSTANT.PARAM_URL_EUI);
        String decrypted = ECOM_PunchoutLoginService.decryptWithBase64(encryptedToken);
        ERP_AddressModel addressModel;
        Map<String,ERP_Address__c> addressMap;
        User userRecord;
        String supportData = '';
        //convert the decrypted data to request model
        ECOM_PunchoutWrapper.PunchoutServiceRequest requestModel = Test.isRunningTest()?ECOM_PunchoutLoginService.createPOSRModelForRevvityPunchoutForNewUser1(): getModelFromString(decrypted);
        requestModel.isTestUser = false;
        //new code
        String calloutResponse = ECOM_PunchoutUserCreation.makeUserCreationCallout(encryptedToken);
		System.debug('User creation callout response '+calloutResponse);
        calloutResponse = calloutResponse.replace('\\','');
        calloutResponse = calloutResponse.replace ('"{','{');
        calloutResponse = calloutResponse.replace ('}"','}');
        returnMap = (Map<String,Object>)JSON.deserializeUntyped(calloutResponse);
		String userName = (String)returnMap.get(ECOM_Constant.PARAM_USERNAME);
		String userPassword = (String)returnMap.get(ECOM_Constant.PARAM_PASSWORD);
		String storeForwardingUrl = (String)returnMap.get(ECOM_Constant.PARAM_FORWARDING_URL);
        if(String.IsNotBlank(userName)&&String.IsNotBlank(userPassword)) {
           	returnMap.putAll(loginUserToSite(userName, userPassword, storeForwardingUrl));
        }
		String sessionCookieParameters = (String)returnMap.get(ECOM_Constant.PARAM_COOKIE);
        
        if(!Test.isRunningTest()){
            Cookie ck = new Cookie(System.Label.ECOM_CookieName , sessionCookieParameters, null, -1, true, 'Lax');
            ApexPages.currentPage().setCookies(new Cookie[]{ck});  
        }   
        poPageReference = Test.isRunningTest() ? new PageReference('TestUrl') : new PageReference((String)returnMap.get(ECOM_Constant.PARAM_STOREFRONT_URL));
        return poPageReference;
	
    }

}