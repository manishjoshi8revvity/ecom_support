/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-69    
*	 ECOM-1020
*
* 2. Description - This class acts as an utility class for user login.
*
*
*
* 3. Objects referenced
*    -User
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
*
* 5. Dependant Class(es):
*    - ECOM_LoginController
*    - ECOM_AccountUtil
*	 - ECOM_PunchoutUserLoginController
*
* 6. Test Class Name:         
*    - ECOM_UserUtil_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vipul 2023.07.19
* 	 - Vasudev 2023.11.23
*	 - Manoj 2024.07.16 RWPS-1096 SF Order To Case - Do not send any role value to Boomi as it is a non-mandatory field
*    - Prabhat 2025.03.20 Updated method getERPAddressDetails to update the logic for billToSapNumber and shipToSapNumber - RWPS-2830
*    - Chirag L 2025.10.01 - Populated mappings for the new attribute related to dealer changes - RWPS-4475
*************************************************************/
public class ECOM_UserUtil {
    
    final static String CLASSNAME = 'ECOM_UserUtil';
    
    /**
    * @description This function is used to create the user login response.
    * @author Vipul Goyal | 07-20-2023 
    * @param userName 
    * @param populateUserInfo 
    * @param pageURL 
    * @return ECOM_LoginWrapper.LoginResponse 
    **/
    public static ECOM_LoginWrapper.LoginResponse getLoginResponse(String userName,Boolean populateUserInfo,String pageURL)
    {
        ECOM_LoginWrapper.LoginResponse response = new ECOM_LoginWrapper.LoginResponse();
        if(populateUserInfo)
        {
           userName = userName.normalizeSpace(); 
            List<User> users= ECOM_UserRepo.getUsersByUsername(username);
            if(!users.isEmpty())
            {
                response=populateUserValues(users[0],response);
            }
        }
        return response;
    }
    

    /**
    * @description This function is used to populate user information in the response.
    * @author Vipul Goyal | 07-20-2023 
    * @param ecomUser 
    * @param response 
    * @return ECOM_LoginWrapper.LoginResponse 
    **/
    public static ECOM_LoginWrapper.LoginResponse populateUserValues(User ecomUser, ECOM_LoginWrapper.LoginResponse response)
    {
        response.userFirstName=ecomUser.FirstName;
        response.userLastName=ecomUser.LastName;
        response.userId=ecomUser.Id;
        response.userEmail=ecomUser.Email;
        response.isMappedAccount=ECOM_ContactService.getIsMapped(ecomUser.ContactId);
        return response;
    }
    
    /**
    * @description The method to extract first 5 letters of the user's lastname
    * @author Vipul Goyal | 07-21-2023 
    * @param dataInformation 
    * @return String 
    **/
    public static String getSuppressedLastName(List<ECOM_UserFlowServiceWrapper.DataWrapper> dataInformation)
    {
        String ln=dataInformation[0].lastName;
        return (ln.length()>5?ln.substring(0,5):ln);
    }
    
    /**
    * @description This is a method to create a random string to be attached with alias to create an unique username.
    * @author Vipul Goyal | 07-27-2023 
    * @param len 
    * @return String 
    **/
    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }

    public static ECOM_FormWrapper.UserInfo setupUserInfo(User us)
    {
        ECOM_FormWrapper.UserInfo userInfo=new ECOM_FormWrapper.UserInfo();
        userInfo.firstName=us.FirstName;
        userInfo.lastName=us.LastName;
        userInfo.email=us.Email;
        userInfo.phone=us.Phone;
        userInfo.role='';//us.UserRole.Name;//RWPS-1096
        return userInfo;
    }

    public static ECOM_FormWrapper.FormWrapper setupFormWrapperFields(ECOM_FormWrapper.FormWrapper formWrapper,String formFactor,String reason,String comment)
    {
        formWrapper.formType=formFactor;
        formWrapper.caseOrigin=ECOM_Constant.CASE_ORIGIN;
        formWrapper.inquiryType=reason;
        formWrapper.userComments=comment;
        return formWrapper;
    }
    
    /**
    * @description  - method is used to prepare ERP Address details for the fetch user details API
    * @author Rani Thumma 2023.10.12 
    * @param contactId
    * @return List<ECOM_AccountWrapper.AccountDetails>
    **/
    public static List<ECOM_AccountWrapper.AccountDetails> getERPAddressDetails(User user, String cartId){ //RWPS-2830
        
        List<ECOM_AccountWrapper.AccountDetails> accountDetails = new List<ECOM_AccountWrapper.AccountDetails>();

        //RWPS-2830 - Start 
        Boolean isMapped = user.Contact.ECOM_Is_Mapped__c;
        String billToSapNumber = '';
        String shipToSapNumber = '';
        ECOM_DummyAccountCountryMapping__mdt defaultmdt;
        if(!user.ECOM_Is_Punchout_User__c ){
            defaultmdt = ECOM_CustomMetadataService.fetchDummyAccountCountryMappingData(ECOM_Util.getCountryFromUser(user));
        }
        List<WebCart> cartList = ECOM_CartRepo.getCartandCartItemsById(cartId);
        WebCart cart = cartList[0];

        if(isMapped == true){
            if(cart.Default_Bill_to_ERP_Address__c != null && cart.Default_Bill_to_ERP_Address__c == user.Contact.Default_Bill_to_ERP_Address__c && cart.Default_Ship_to_ERP_Address__c != null && cart.Default_Ship_to_ERP_Address__c ==  user.Contact.Default_Ship_to_ERP_Address__c){
                billToSapNumber = cart.Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c != null ? cart.Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c :  user.Contact.Default_Bill_to_ERP_Address__c != null ?  user.Contact.Default_Bill_To_ERP_Address__r.Target_Address__r.External_Id__c : null;
                shipToSapNumber = cart.Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c != null ? cart.Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c :  user.Contact.Default_Ship_to_ERP_Address__c != null ?  user.Contact.Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c : null;
            }
            else if ((cart.Default_Bill_to_ERP_Address__c != user.Contact.Default_Bill_to_ERP_Address__c) || (cart.Default_Ship_to_ERP_Address__c != user.Contact.Default_Ship_to_ERP_Address__c)) {
                billToSapNumber =  user.Contact.Default_Bill_To_ERP_Address__r.Target_Address__r.External_Id__c;
                shipToSapNumber = user.Contact.Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c;
            }

            if((cart.Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c == null && user.Contact.Default_Bill_To_ERP_Address__r.Target_Address__r.External_Id__c == null) || (cart.Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c == null &&  user.Contact.Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c == null)){
                if (defaultmdt != null) { 
                    billToSapNumber = defaultmdt.Default_Bill_To__c;
                    shipToSapNumber = defaultmdt.Default_Ship_to__c;
                }
            }
            
            if(user.Contact.Default_Bill_To_ERP_Address__c == null || user.Contact.Default_Ship_to_ERP_Address__c == null && defaultmdt != null){
                billToSapNumber = defaultmdt.Default_Bill_To__c;
                shipToSapNumber = defaultmdt.Default_Ship_to__c;
            }
        }
        else if (isMapped == false && defaultmdt != null){
            billToSapNumber = defaultmdt.Default_Bill_To__c;
            shipToSapNumber = defaultmdt.Default_Ship_to__c;
        }

        //RWPS-2830 - End
        ECOM_AccountWrapper.AccountDetails temp= new ECOM_AccountWrapper.AccountDetails();
        temp.accountId = user.AccountId;
        temp.accountName = user.Account.Name;
        temp.location = user.Account.ShippingCountry;
        temp.sapAccountNumber = user.Account.SAP_Customer_Number_Formatted__c;
        
        // RWPS-4475 START
        if (user.ECOM_Is_Punchout_User__c == false) {
            if (
                user.Contact != null && 
                user.contact.Default_Ship_to_ERP_Address__c != null && 
                user.contact.Default_Ship_to_ERP_Address__r.Master_Address__c != null && 
                user.Contact.Default_Ship_to_ERP_Address__r.Master_Address__r.Dealer_Type__c != null && 
                user.Contact.Default_Ship_to_ERP_Address__r.Master_Address__r.Dealer_Type__c == '10. ECOM'
            ) {
                temp.isDealer = true;
            } else {
                temp.isDealer = false;
            }
        }
        // RWPS-4475 END

        if(user.Contact.Default_Ship_to_ERP_Address__c != null && user.Contact.Default_Ship_to_ERP_Address__r.RAD_Identifier__c == 'RAD'){
            temp.allowRadioaActiveProductsBooking = 'true';
        } else {
            temp.allowRadioaActiveProductsBooking = 'false';
        }
        
        ECOM_AccountWrapper.BillingDetails billingDetails = new ECOM_AccountWrapper.BillingDetails();
        billingDetails.billToId = user.Contact.Default_Bill_to_ERP_Address__c;
        if(user.Contact.Default_Bill_to_ERP_Address__r.Account__c != null){
            billingDetails.billToName = user.Contact.Default_Bill_to_ERP_Address__r.Account__r.Name;
        } else{
            billingDetails.billToName = user.Contact.Default_Bill_to_ERP_Address__r.ERP_Account_Name__c;
        }
        billingDetails.billToStreet = user.Contact.Default_Bill_to_ERP_Address__r.fxAddress_Street__c;
        billingDetails.billToState = user.Contact.Default_Bill_to_ERP_Address__r.fxAddress_StateName__c;
        billingDetails.billToCity = user.Contact.Default_Bill_to_ERP_Address__r.fxAddress_City__c;
        //billingDetails.billToCountry = user.Contact.Default_Bill_to_ERP_Address__r.fxAddress_CountryCode__c;
        billingDetails.billToCountry = user.Contact.Default_Bill_to_ERP_Address__r.fxAddress_CountryName__c;
        billingDetails.billToPostalCode = user.Contact.Default_Bill_to_ERP_Address__r.fxAddress_Postal__c;
        billingDetails.sapAccountNumber = billToSapNumber; //RWPS-2830
        temp.billToDetails.add(billingDetails);
        
        ECOM_AccountWrapper.ShippingDetails shippingDetails= new ECOM_AccountWrapper.ShippingDetails();
        shippingDetails.shipToId = user.Contact.Default_Ship_to_ERP_Address__c;
        if(user.Contact.Default_Ship_to_ERP_Address__r.Account__c != null){
            shippingDetails.shipToName =user.Contact.Default_Ship_to_ERP_Address__r.Account__r.Name;
        } else{
            shippingDetails.shipToName = user.Contact.Default_Ship_to_ERP_Address__r.ERP_Account_Name__c;
        }
        shippingDetails.shipToStreet = user.Contact.Default_Ship_to_ERP_Address__r.fxAddress_Street__c;
        shippingDetails.shipToState = user.Contact.Default_Ship_to_ERP_Address__r.fxAddress_StateName__c;
        shippingDetails.shipToCity = user.Contact.Default_Ship_to_ERP_Address__r.fxAddress_City__c;
        //shippingDetails.shipToCountry = user.Contact.Default_Ship_to_ERP_Address__r.fxAddress_CountryCode__c;
        shippingDetails.shipToCountry = user.Contact.Default_Ship_to_ERP_Address__r.fxAddress_CountryName__c;
        shippingDetails.shipToPostalCode = user.Contact.Default_Ship_to_ERP_Address__r.fxAddress_Postal__c;
        shippingDetails.sapAccountNumber = shipToSapNumber; //RWPS-2830
        temp.shipToDetails.add(shippingDetails);
        
        accountDetails.add(temp);
        return accountDetails;
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
        String baseUrl = ECOM_UserUtil.getEcomSiteBaseUrl();
        String storeLoginUrl = baseUrl + System.Label.ECOM_TestUserLoginEndpoint  + parameterString;
        System.debug('storeLoginUrl:: '+ storeLoginUrl);
        requestHeader.put(ECOM_Constant.REQUEST_METHOD_TYPE, ECOM_Constant.HTTP_REQUEST_POST);
        requestHeader.put(ECOM_Constant.HTTP_CONTENT_TYPE, ECOM_Constant.HTTP_CONTENT_FORM_URLENCODED);
        requestHeader.put(ECOM_Constant.HTTP_REQUEST_ENDPOINT, storeLoginUrl);
        requestHeader.put(ECOM_Constant.HTTP_CONTENT_LENGTH, String.valueOf(0));
        
        return requestHeader;
    }
    
    /**
    * @description create new user, prevent welcome email
    * @author vramchandran@rafter.one | 11-22-2023 
    * @param User 
    * @return String 
    **/
    @TestVisible
    public static Boolean provisionNewUserWithoutWelcomeEmail(User userRecord){
        Boolean isUserCreationSuccess = true;
        final String METHOD_NAME = 'createNewUser';
        try{
            Database.DMLOptions dmlOptions = new Database.DMLOptions();
            dmlOptions.EmailHeader.triggerUserEmail = false;
            Database.SaveResult result;
            if(!Test.isRunningTest()){
                result =  ECOM_UserRepo.createUserWithDmlOptions(userRecord, dmlOptions);
            }
            isUserCreationSuccess = Test.isRunningTest() ? true : result.isSuccess();
        }catch(Exception e){
            //set flags and response message
            isUserCreationSuccess = false;
            ECOM_ApplicationLogsUtil.logFailure(e , 'Punchout User Login' , CLASSNAME , METHOD_NAME, 'EMAIL:: '+ userRecord.Email + ' Stack:: '+ e.getStackTraceString());
        }
        return isUserCreationSuccess;
    }
    
    /**
    * @description prepares request header and body for password reset callout
    * @author vramchandran@rafter.one | 11-24-2023 
    * @param User 
    * @return String 
    **/
    public static Map<String,String> preparePasswordResetRequest(Map<String,String> parameterMap){
        Map<String,String> requestHeader = new Map<String,String>();
        
        Map<String,String> bodyMap = new Map<String,String>();
        bodyMap.put(ECOM_Constant.HTTP_REQUEST_BODY, JSON.serialize(parameterMap));
		
		DomainSite siteDomain= ECOM_Util.fetchBaseSiteURL(System.Label.ECOM_SiteName);
        String storeLoginUrl = System.Label.ECOM_HTTPS_Prefix  + siteDomain.Domain.domain + System.Label.ECOM_ProvisionPOEndpoint ;//'https://revvity--punchout.sandbox.my.site.com' + '/services/apexrest/provisionpouser';
        requestHeader.put(ECOM_Constant.REQUEST_METHOD_TYPE, ECOM_Constant.HTTP_REQUEST_POST);
        requestHeader.put(ECOM_Constant.HTTP_CONTENT_TYPE, ECOM_Constant.HTTP_CONTENT_APP_JSON);
        requestHeader.put(ECOM_Constant.HTTP_REQUEST_ENDPOINT, storeLoginUrl);
        requestHeader.put(ECOM_Constant.HTTP_REQUEST_BODY, JSON.serialize(bodyMap));
        return requestHeader;
    }
    
    /**
    * @description prepares request header and body for password reset callout
    * @author vramchandran@rafter.one | 07 Jan 2024
    * @param parameterMap | Map<String,String> 
    * @return Map<String,String> 
    **/
    public static Map<String,String> prepareRequestForTestUserPasswordReset(String requestBody){
        Map<String,String> requestHeader = new Map<String,String>();
		
		DomainSite siteDomain= ECOM_Util.fetchBaseSiteURL(System.Label.ECOM_SiteName);
        String storeLoginUrl = System.Label.ECOM_HTTPS_Prefix  + siteDomain.Domain.domain + System.Label.ECOM_ResetPasswordEndpoint;//'https://revvity--punchout.sandbox.my.site.com' + '/services/apexrest/provisionpouser';
        requestHeader.put(ECOM_Constant.REQUEST_METHOD_TYPE, ECOM_Constant.HTTP_REQUEST_POST);
        requestHeader.put(ECOM_Constant.HTTP_CONTENT_TYPE, ECOM_Constant.HTTP_CONTENT_APP_JSON);
        requestHeader.put(ECOM_Constant.HTTP_REQUEST_ENDPOINT, storeLoginUrl);
        requestHeader.put(ECOM_Constant.HTTP_REQUEST_BODY, requestBody);
        
        System.debug('requestHeader:: '+ JSON.serialize(requestHeader));
        return requestHeader;
    }
    
    /**
     * @description This method returns the user model for a user record
     * @author vramachandran@rafter.one | 22 Dec 2023
     * @param userRecord | User
     * @return ECOM_POUserModel
     */
    public static ECOM_POUserModel getUserModelForUserRecord(User userRecord){
        ECOM_POUserModel userModel;
        ECOM_POUserModel.UserContact userModelContact = new ECOM_POUserModel.UserContact();
        ECOM_POUserModel.UserAccount userModelAccount =  new ECOM_POUserModel.UserAccount();
        
        //map user information
        if(userRecord != null){
            userModel = new ECOM_POUserModel();
            userModel.userId = userRecord.Id;
            userModel.userName = userRecord.Username;
            userModel.userFirstName = userRecord.FirstName;
            userModel.userLastName = userRecord.LastName;
            userModel.userEmail = userRecord.Email;
            userModel.userContactId = String.isNotBlank(userRecord?.ContactId) ? userRecord.ContactId : '';
            userModel.userAccountId = String.isNotBlank(userRecord?.AccountId) ? userRecord.AccountId : '';
            
            //map contact information
            if(null != userModel.userContactId && String.isNotBlank(userModel.userContactId)){
                userModelContact.contactId = userRecord.ContactId;
                userModelContact.contactEmail = userRecord?.Contact?.Email;
                userModelContact.contactCountry = userRecord?.Contact?.ECOM_CountryProvided__c;
                userModelContact.contactFirstName = userRecord?.Contact?.FirstName;
                userModelContact.contactLastName = userRecord?.Contact?.LastName;
                userModel.userContactRecord = userModelContact;
            }
            
            //map account information
            if(null != userModel.userAccountId && String.isNotBlank(userModel.userAccountId)){
                userModelAccount.accountId = userRecord?.AccountId;
                userModelAccount.accountName = userRecord?.Account?.Name;
                userModel.userAccountRecord = userModelAccount;
            }
            
        }
        return userModel;
    }

    /**
    * @description prepares request header and body for password reset callout
    * @author vramachandran@rafter.one | 02 Jan 2024 
    * @return String 
    **/
    public static String getEcomSiteBaseUrl(){
        String baseStoreUrl;
        
        DomainSite siteDomain= ECOM_Util.fetchBaseSiteURL(System.Label.ECOM_SiteName);
        if(null != siteDomain){
            baseStoreUrl= System.Label.ECOM_HTTPS_Prefix  + siteDomain.Domain.domain ;//'https://revvity--punchout.sandbox.my.site.com' + '/services/apexrest/provisionpouser';    
        }
        return baseStoreUrl;
    }

    /**
     * @description This method returns the user record for a punchout user
     * @author vramachandran@rafter.one | 09 Jan 2024
     * @param userId | String
     * @return User //TODO: VRA: To be deprecated
     */
    public static User getPunchoutUserForUserId(String userId){
        User punchoutUserRecord;
        
        List<User> users = ECOM_UserRepo.getPunchoutUserInformationForErpAddress(userId);
        
        if(null != users && !users.isEmpty()){
            punchoutUserRecord = users[0];
        }
        
        return punchoutUserRecord;
    }
}