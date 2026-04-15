/**************************************************************
 * Note :  As Login having issue due to dependency in other classes , We(R1) decided to 
 *  move all logic to controller to  fix the issue.(Asked by Salesforce Inc)
* 1. Jira Ticket(s) that relates to this class
*    ECOM-69  
*
* 2. Description - This class is used to login user into the system.
*
*
*
* 3. Objects referenced
*    - ECOM_Application_logs__c
* 	 - Contact
* 	 - C_META_Storefront_Configuration__mdt
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
*
* 5. Dependant Class(es):
*    - None
*
* 6. Test Class Name: 
*    - ECOM_LoginController_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vipul 2023.07.19

*************************************************************/

public without sharing class ECOM_LoginController {

    public static final String CLASSNAME = 'ECOM_LoginController';
	public static final String ENCRYPTED_TOKEN = 'encryptedToken';
    public static final String ENCRYPTED_CODE = 'encryptedCode';
    public static final String ALGORITHM_AES_256 = 'AES256';
    public static final String INITIALIZATION_VECTOR = 'InitializationVector';
    public static final String MODULE_SECURITY = 'Security';
    public static final String SECRET_KEY = 'SecretKey';
    public static final String USER_MODULE_NAME = 'User Management';
    public static  Boolean isMappedContact = false;

    /**
     * This method logins the user to the Store ,in case of invalid credentials it passes invalid credentials as the response.
     *
     * @return String
     *
     * @author Vipul Goyal | 07-20-2023
     **/
    public String getReturnURL() {
        
        String returnURL = '';
        try{
            Map<String, String> mapPageParams = ApexPages.currentPage().getParameters();
            String strEncryptedToken = Test.isRunningTest()? 'dEdBYlHUmhEZcgaCePXxNbAC6fKJfq4G8DH4AiSzCwc=' : getValueFromMap(mapPageParams,ENCRYPTED_TOKEN);
            if(String.isNotBlank(strEncryptedToken))
            {
                String strDecryptUserName = decryptWithAES256(strEncryptedToken);
                List<User> users = getUsersByUsername(strDecryptUserName);

                if(users.isEmpty() || String.isBlank(users[0].ContactId))
                {
                    ECOM_LoginWrapper.LoginResponse response = new ECOM_LoginWrapper.LoginResponse();
                    response.success = false;
                    response.message= System.label.ECOM_102002;
                    return JSON.serialize(response,true);
                }

                String contactId = users[0].ContactId;
                
                if(String.isNotBlank(contactId))
                {
                    Contact con = getContactBasedOnId(contactId);
                    isMappedContact = con.ECOM_Is_Mapped__c !=null? con.ECOM_Is_Mapped__c : false;
                    Map<String,Object> addressMap= getDefaultStoreFrontPath(con);
                    if(!addressMap.isEmpty())
                    {
                        mapPageParams.put('defaultPathForAddressRegistration',(String)addressMap.get('defaultPathForAddressRegistration'));
                        mapPageParams.put('addressAction',(String)addressMap.get('addressAction'));
                    }
                }
            }
            returnURL = userLogin(mapPageParams);
        }catch(Exception e)
        {
            returnURL=JSON.serialize(e.getStackTraceString());
        }
        return returnURL;
    }
    
    /**
    * @description  read parameters from URL
    * @author mkumar@rafter.one | 09-18-2023 
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
     * @description 
     * @author mkumar@rafter.one | 09-18-2023 
     * @param encryptedText 
     * @return String 
     **/
     public static String decryptWithAES256(String encryptedText) {
        String decryptedString = null;
        String methodName = 'decryptWithAES256';
        String supportData = '';
        try {
            String strSecretKey = fetchConfigByValue(SECRET_KEY);
            String strInitializationVector = fetchConfigByValue(INITIALIZATION_VECTOR);
            Blob blobSecretKey = Blob.valueOf(strSecretKey);
            Blob blobInitializationVector = Blob.valueOf(strInitializationVector);
            Blob encryptedDataUpdated = EncodingUtil.base64Decode(encryptedText);
            Blob decryptedTextData = Crypto.decrypt(ALGORITHM_AES_256, blobSecretKey, blobInitializationVector, encryptedDataUpdated);
            decryptedString = decryptedTextData.toString();
        } catch (Exception exceptionObject) {
            // ECOM_ApplicationLogsUtil.logFailure(exceptionObject, USER_MODULE_NAME, className, methodName, supportData);
        }
        return decryptedString;
    }
    
    /**
    * @description 
    * @author mkumar@rafter.one | 09-18-2023 
    * @param contactId 
    * @return Contact 
    **/
    public static Contact getContactBasedOnId(String contactId)
    {
        return [SELECT id,Name,Email,AccountId,Account.Name,Account.AccountNumber, ECOM_Attention_Recipient__c, ECOM_Delivery_Details__c, 
                ECOM_Special_Instructions__c,SAP_Contact_ID__c, Account.SAP_Customer_Number_Formatted__c, FirstName, LastName,
                ECOM_DefaultBillToAccount__c,
                ECOM_DefaultBillToAccount__r.Name,
                ECOM_DefaultBillToAccount__r.BillingStreet,ECOM_DefaultBillToAccount__r.BillingCity, 
                ECOM_DefaultBillToAccount__r.BillingState,ECOM_DefaultBillToAccount__r.BillingPostalCode,
                ECOM_DefaultBillToAccount__r.BillingCountry,ECOM_DefaultBillToAccount__r.ShippingStreet, ECOM_DefaultBillToAccount__r.ShippingCity, 
                ECOM_DefaultBillToAccount__r.ShippingState, ECOM_DefaultBillToAccount__r.ShippingPostalCode,
                ECOM_DefaultBillToAccount__r.ShippingCountry,ECOM_DefaultBillToAccount__r.AccountNumber, 
                ECOM_DefaultShipToAccount__c,ECOM_DefaultShipToAccount__r.Name,
                ECOM_DefaultShipToAccount__r.BillingStreet,ECOM_DefaultShipToAccount__r.BillingCity, 
                ECOM_DefaultShipToAccount__r.BillingState,ECOM_DefaultShipToAccount__r.BillingPostalCode,
                ECOM_DefaultShipToAccount__r.BillingCountry,ECOM_DefaultShipToAccount__r.ShippingStreet, ECOM_DefaultShipToAccount__r.ShippingCity, 
                ECOM_DefaultShipToAccount__r.ShippingState, ECOM_DefaultShipToAccount__r.ShippingPostalCode,
                ECOM_DefaultShipToAccount__r.ShippingCountry,ECOM_DefaultShipToAccount__r.AccountNumber,
                ECOM_AccountNameProvided__c, ECOM_NeedsVerification__c, ECOM_AccountNumberProvided__c, ECOM_AddressRegistration__c,
                fxDomain__c,ECOM_DefaultShipToAccount__r.SAP_Customer_Number_Formatted__c, ECOM_DefaultBillToAccount__r.SAP_Customer_Number_Formatted__c,
                ECOM_DefaultInvoiceToAccount__c,
                ECOM_DefaultInvoiceToAccount__r.Name,
                ECOM_DefaultInvoiceToAccount__r.BillingStreet,ECOM_DefaultInvoiceToAccount__r.BillingCity, 
                ECOM_DefaultInvoiceToAccount__r.BillingState,ECOM_DefaultInvoiceToAccount__r.BillingPostalCode,
                ECOM_DefaultInvoiceToAccount__r.BillingCountry,ECOM_DefaultInvoiceToAccount__r.ShippingStreet, ECOM_DefaultInvoiceToAccount__r.ShippingCity, 
                ECOM_DefaultInvoiceToAccount__r.ShippingState, ECOM_DefaultInvoiceToAccount__r.ShippingPostalCode,
                ECOM_DefaultInvoiceToAccount__r.ShippingCountry,ECOM_DefaultInvoiceToAccount__r.AccountNumber,
                ECOM_DefaultBillToCPA__c,ECOM_DefaultBillToCPA__r.Id,ECOM_DefaultBillToCPA__r.Name,
                ECOM_DefaultBillToCPA__r.CompanyName,
                ECOM_DefaultBillToCPA__r.City,ECOM_DefaultBillToCPA__r.Street,
                ECOM_DefaultBillToCPA__r.State,ECOM_DefaultBillToCPA__r.PostalCode,
                ECOM_DefaultBillToCPA__r.PhoneNumber,ECOM_DefaultBillToCPA__r.ECOM_Extn__c,
                ECOM_DefaultBillToCPA__r.Country,
                ECOM_DefaultShipToCPA__c,ECOM_DefaultShipToCPA__r.Id,ECOM_DefaultShipToCPA__r.Name,
                ECOM_DefaultShipToCPA__r.City,ECOM_DefaultShipToCPA__r.Street,
                ECOM_DefaultShipToCPA__r.State,ECOM_DefaultShipToCPA__r.PostalCode,
                ECOM_DefaultShipToCPA__r.PhoneNumber,ECOM_DefaultShipToCPA__r.ECOM_Extn__c,
                ECOM_DefaultShipToCPA__r.Country,
                ECOM_DefaultShipToCPA__r.CompanyName,
                ECOM_Is_Mapped__c,ECOM_CountryProvided__c,
                ECOM_Phone_Extension__c,
                Phone
                FROM Contact WHERE id=:contactId LIMIT 1];
    }
    
    /**
    * @description 
    * @author mkumar@rafter.one | 09-18-2023 
    * @param con 
    * @return Map<String, Object> 
    **/
    public static Map<String,Object> getDefaultStoreFrontPath(Contact con)
    {
        Map<String,Object> returnMap=new Map<String,Object>();
        if(String.isNotBlank(con.ECOM_AddressRegistration__c) && !con.ECOM_AddressRegistration__c.equalsIgnoreCase('Completed'))
        {
            returnMap.put('defaultPathForAddressRegistration','/dashboard');
            if(con.ECOM_AddressRegistration__c.equalsIgnoreCase('Populate ST & BT'))
            {
                returnMap.put('addressAction','addressStatus=addAddress');
            }
            else if(con.ECOM_AddressRegistration__c.equalsIgnoreCase('Select ST & BT') || con.ECOM_AddressRegistration__c.equalsIgnoreCase('Select BT'))
            {
                returnMap.put('addressAction','addressStatus=selectAddress');
            }
        }
        return returnMap;
    }
    
    /**
    * @description 
    * @author mkumar@rafter.one | 09-18-2023 
    * @param mapPageParams 
    * @return String 
    **/
    public String userLogin(Map<String, String> mapPageParams){
        
        ECOM_LoginWrapper.LoginResponse response = new ECOM_LoginWrapper.LoginResponse();
        response.success = false;
        String methodName = 'userLogin';
        String supportData = '';
        String returnURL = '';
        Boolean addAddressParam=false;
        String strDefaultCartPath = '/initiate-session'; //TODO move it to Custom Metadata and Default path is /initiate-session
        if(mapPageParams.containsKey('defaultPathForAddressRegistration'))
        {
            strDefaultCartPath=mapPageParams.get('defaultPathForAddressRegistration');
            addAddressParam=true;
            strDefaultCartPath+='?'+mapPageParams.get('addressAction')+'&url=replaceURL';
        }
        String pageURL = null;
        try {
            supportData = JSON.serialize(mapPageParams);
            String strEncryptedToken = getValueFromMap(mapPageParams, ENCRYPTED_TOKEN);
            String strEncryptedCode = getValueFromMap(mapPageParams, ENCRYPTED_CODE);
            if (String.isNotBlank(strEncryptedToken) && String.isNotBlank(strEncryptedCode)) {
                Boolean populateUserInfo = true;
                String strDecryptUserName = decryptWithAES256(strEncryptedToken);
                String strDecryptPassword = decryptWithAES256(strEncryptedCode);
                if(!addAddressParam)
                {
                    strDefaultCartPath=ECOM_Constant.DEFAULT_STOREFRONT;
                    //strDefaultCartPath = getStrDefaultCartPath(mapPageParams);
                }
                //populateUserInfo = ECOM_LoginUtil.isUserInfoPopulated(mapPageParams);
                populateUserInfo = true;
                PageReference pageReferenceObject = Site.login(strDecryptUserName, strDecryptPassword, strDefaultCartPath);
                if (pageReferenceObject != null) {
                    pageURL = pageReferenceObject.getUrl();
                    response = getLoginResponse(strDecryptUserName, populateUserInfo, pageURL);
                    response.storefrontURL = pageURL;
                    response.success = true;
                } else {
                    response.message = System.Label.ECOM_103001;//'Invalid Credentials';//TODO move it to custom Metadata
                }
            } else {
                response.message = System.Label.ECOM_103001;//'Invalid Credentials';//TODO move it to custom Metadata
            }
        } catch (Exception ex) {
            response.message = ex.getMessage();
        } finally {
            returnURL = JSON.serialize(response, true);
        }
        
        return returnURL;
    }

    /**
    * @description 
    * @author mkumar@rafter.one | 09-18-2023 
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
    * @description 
    * @author mkumar@rafter.one | 09-18-2023 
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

    public static ECOM_LoginWrapper.LoginResponse getLoginResponse(String userName,Boolean populateUserInfo,String pageURL)
    {
        ECOM_LoginWrapper.LoginResponse response = new ECOM_LoginWrapper.LoginResponse();
        if(populateUserInfo)
        {
           userName = userName.normalizeSpace(); 
            List<User> users= getUsersByUsername(username);
            if(!users.isEmpty())
            {
                response=populateUserValues(users[0],response);
                /*response.accountDetails= ECOM_AccountUtil.getAccountDetails(users[0].ContactId,users[0].Contact.AccountId,true);
                String strDefaultShipToAddress='';//Need to get the default ship to address from account functions
                response.cartDetails= ECOM_CartUtil.fetchCartDetails(users[0].Id, users[0].Contact.AccountId, strDefaultShipToAddress, false);*/
            }
        }
        return response;
    }

    public static List<User> getUsersByUsername(String username)
    {
        return [
            	Select Id,FirstName,LastName,Email,ContactId,
                Contact.AccountId, Contact.Account.Name
                from User 
                where username=:username LIMIT 1
               ];
    }
    public static ECOM_LoginWrapper.LoginResponse populateUserValues(User ecomUser, ECOM_LoginWrapper.LoginResponse response)
    {
        response.userFirstName=ecomUser.FirstName;
        response.userLastName=ecomUser.LastName;
        response.userId=ecomUser.Id;
        response.userEmail=ecomUser.Email;
        response.isMappedAccount=isMappedContact ;
        return response;
    }
}