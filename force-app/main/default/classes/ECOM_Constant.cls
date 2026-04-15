/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    -
*	 ECOM-2555
*
* 2. Description - This class is used to store all the constants/static values used across mutliple classes
*				 - If there is change to the variable vlaue update this class and it will reflect in all classes where this varaible is used
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
*    - Rani Thumma 2023-08-12
*    - Manoj 2023-08-15
*	 - Vasudev 2023-11-23
* 	 - Vasudev 2024.04.23
* 	 - Vipul Goyal 2024.04.24 - Added Variable ABANDONED_CART_MODULE_NAME
* 	 - Sathiya 2024.04.29 - Added new constant BILL_TO_FIELD_VALIDATION for ECOM-1933
*    - Manoj 2024-04-30 RWPS-584 Instrument freight not applying as expected on web orders(Added two constant ORDER_COMPONENT_ZGNA & ORDER_COMPONENT_ZWCC)
*    - Manoj 2024-05-01 RWPS-584 Instrument freight not applying as expected on web orders(Added two constant ORDER_CREATE & ORDER_SIMULATE)
* 	 - Vasudev 2024.05.02 - Added constant REGISTRATION_SERVICE for ECOM-2302
*    - Vipul Goyal 2024.05.06 - Added constant ORDER_PENDING_APPROVAL,ORDER_REJECTED,ORDER_APPROVED for ECOM-103
*	 - Sathiya 2024.05.24 - Added labels for email template validations
*    - Sidak 2024-05-17 RWPS-723 Added constant CART_ID
*    - Sidak 2024-05-17 RWPS-554 Added constants SHIP_TO_NUMBER, FIRST_NAME, LAST_NAME, EMAIL
*    - Sidak 2024-07-10 RWPS-949 Added constant MATERIAL_STATUS_CODES_PUNCHOUT
*    - Manoj 2024.07.19 SF: Pass the punchout domain in punchout_data Ticket - RWPS-1115
*    - Manish 2024.09.16 RWPS-1256 Adding some constants for address map & punchout exception
*    - Poonam 2024.02.07 Added constant PUNCHOUT_CUSTOM_MATERIAL_CODE - RWPS-1456
*    - Manish 2025.02.21 - Added constant for country provided contact validation rule - RWPS-2648
*    - Prabhat 2025.04.25 - Added constant TARIFF_CHARGE_PRODUCT - RWPS-3026
*    - Gaurav 2025.06.03 - Added constant WEB_PROMOTION and PUNCHOUT_PROMOTION RWPS-3283
*    - Prabhat 2025.06.19 - Added constant MATERIAL_STATUS_ERROR_MSG, NON_SELLABLE_PRODUCTS, DISCONTINUED_PRODUCTS for RWPS-2786
*    - Prabhat 2025.09.23 - Added constant SHIP_TO_CONTACT_EMAIL_BOTH, CONTACT_EMAIL , SHIP_TO_EMAIL for RWPS-4131
*    - Sachin 2025.10.04 - Added constant DISCONTINUED_PRODUCT, ECOM_NON_SELLABLE_PRODUCT for RWPS-3740/RWPS-4621
*    - Sachin 2025.10.13 - Added constant DEALER_IDENTIFICATION_VALUE for RWPS-4759
*    - Sachin 2025.10.29 - Added constant ORDER_PRODUCT_TYPE for RWPS-4881
*    - Sachin 2025.11.20 - Added constant NOT_SHIPPED for RWPS-5181
*    - Sachin 2025.12.15 - Added constant RECENTLY_PURCHASED_PRODUCTS, FREQUENTLY_PURCHASED_PRODUCTS for RWPS-5507
*    - Poonam 2025.11.25 - Added constant ERROR_LOG_FIELD for RWPS-5153
*    - Poonam 2026.02.03 - Added constant PUNCHOUT_CONFIG_REC for RWPS-5776
*    - Manish 2026.03.09 - Added constant PARAM_TIMEOUT_LIMIT - RWPS-6684
*    - Sachin 2026.03.16 - Added constant for RWPS-5938
* 	 - Poonam 2026.04.29 - Added new constant ECOM_LOG_INFO_MESSAGES for RWPS-6037

*************************************************************/
public with sharing class ECOM_Constant {

    //Contact Constants
    public static final String CONTACT_NAME = 'TestFirst Contact';
    //User Constants
    public static final String USER_MODULE_NAME = 'User Management';
    public static final String USER_SERVICE = 'ECOM_UserService';
    public static final String REVVITY_ACCOUNT =  'Test Revvity Account';

    //public static final String USER_EXISTS_SUCCESS = 'Email ID exists';
    //public static final String USER_EXISTS_FAILURE = 'Email ID does not exist';

    //Session Management
    public static final String MODULE_SITE_URL = 'SiteURL';
    public static final String SITE_SESSION_EXPIRE = 'SessionExpire';
    public static final String SITE_NAME = 'Revvity_eCom1';
    public static final String SESSION_STATE_START = 'Start';
    public static final String SESSION_STATE_DELIVERY = 'Delivery';

    //Call out Constants
    public static final String HTTP_REQUEST_POST = 'POST';
    public static final String HTTP_REQUEST_GET = 'GET';
    public static final String HTTP_REQUEST_PUT = 'PUT';
    public static final String HTTP_REQUEST_PATCH = 'PATCH';
    public static final String HTTP_API_MODULE = 'CALLOUT';
    public static final String ACTION_TYPE = 'ActionType';
    public static final String INTEGRATION_EXCEPTION = 'Integration Exception';

    public static final String HTTP_CONTENT_TYPE = 'Content-Type';
    public static final String HTTP_CONTENT_APP_JSON = 'application/json';
    public static final String HTTP_CONTENT_FORM_URLENCODED = 'application/x-www-form-urlencoded';
    public static final String HTTP_REQUEST_TYPE = 'requestType';
    public static final String HTTP_REQUEST_BODY = 'requestBody';
    public static final String HTTP_REQUEST_ENDPOINT = 'requestEndPoint';
    public static final String HTTP_CONTENT_LENGTH = 'Content-Length';

    public static final String AUTH_BASIC = 'BASIC';
    public static final String AUTHORIZATION = 'Authorization';


    public static final String GRANT_TYPE = 'grant_type';
    public static final String GRANT_TYPE_CLIENT_CREDENTIALS = 'client_credentials';
    public static final String REQUEST_METHOD_TYPE = 'Method Type';

    public static final String HTTP_REQUEST_STATUS_CODE = 'statusCode';

    //Account Constants
    public static final String ACCOUNT_SERVICE = 'ECOM_AccountService';

    //Wishlist Constants
    public static final String WISHLIST_ACTION_ADD = 'add';
    public static final String WISHLIST_ACTION_REMOVE = 'remove';

    //Contact Constants
    public static final String CONTACT_SERVICE = 'ECOM_ContactService';

    //Cart constants
    public static final String CART_SERVICE = 'ECOM_CartService';
    public static final String CART_STATUS_ACTIVE = 'ACTIVE';
    public static final String CART_STATUS_CHECKOUT= 'Checkout';
    public static final String CART_STATUS_CURRENT = 'Current';
    public static final String CARTITEM_TYPE_PRODUCT = 'Product';
    public static final String MATERIAL_STATUS_CODES = 'MaterialStatusCodes';
    public static final String MATERIAL_STATUS_CODES_PUNCHOUT = 'MaterialStatusCodesPunchout';
    public static final String MATERIAL_STATUS_ERROR_MSG = 'has been removed from your cart because it is no longer available. Please contact Customer Care for assistance.';//RWPS-2786
    public static final String CARTITEM_TYPE_CHARGE = 'Charge';//VRa - Punchout changes
	public static final String CART_ID= 'CartId'; //ssingh@rafter.one | RWPS-723
    public static final String NON_SELLABLE_PRODUCTS = 'Non Sellable Products'; //RWPS-2786
    public static final String DISCONTINUED_PRODUCTS = 'Discontinued Products'; //RWPS-2786
    public static final String DIRECT_REPLACEMENT_PRODUCTS = 'Direct Replacement Status';
    public static final String ALTERNATIVE_REPLACEMENT_PRODUCTS = 'Alternative Replacement Status';
    //RWPS-4231 - START
    public static final String SHIP_TO_EMAIL = 'Ship To Email';
    public static final String CONTACT_EMAIL = 'Contact Email';
    public static final String SHIP_TO_CONTACT_EMAIL_BOTH = 'Both';
    //RWPS-4231 - START



    //Order Constants
    public static final String ORDER_MODULE_NAME = 'Order Management';
    public static final String ORDER_SERVICE = 'ECOM_OrderService';
    public static final String DEFAULT_DELIVERY_METHOD = 'Default Delivery Method';
    public static final String ORDER_COMPONENT = 'ZWEB';
    public static final String ORDER_COMPONENT_ZGNA = 'ZGNA';//RWPS-584
	public static final String ORDER_COMPONENT_ZWCC = 'ZWCC';//RWPS-584
    public static final String ORDER_CREATE_TASK = 'OrderEntryRequest';
    public static final String PAYMENT_TYPE_PO = 'PO';
    public static final string PAYMENT_TYPE_CREDITCARD = 'CreditCard';
    public static final string ORDER_STATUS_ACTIVATED = 'Shipped';
    public static final string ORDER_STATUS_ORDER_CONFIRMED = 'OrderConfirmed';
    public static final string CHECKOUT_MODULE_NAME = 'Checkout Management';
    public static final string PAYMENT_MODULE_NAME = 'Payment';
    public static final string FAVORITES_MODULE_NAME = 'Favorites';
    public static final string DRAFT_ORDER= 'Order Acknowledged';
    public static final String ABANDONED_CART_MODULE_NAME = 'Abandoned Cart';
    public static final String ABANDONED_CART_ORGWIDEADDRESS_NAME = 'RVTY E-Commerce Support';
    public static final string ORDER_CREATE= 'OrderCreate';//RWPS-584
    public static final string ORDER_SIMULATE= 'OrderSimulate';//RWPS-584

    public static final string SHIP_TO_NUMBER= 'shipToNumber';//RWPS-554
    public static final string FIRST_NAME= 'firstName';//RWPS-554
    public static final string LAST_NAME= 'lastName';//RWPS-554
    public static final string EMAIL= 'email';//RWPS-554

    //Product Constants
    public static final String SHIPPING_CHARGE_PRODUCT = 'Shipping Charge for this delivery method';
    public static final String TARIFF_CHARGE_PRODUCT = 'Tariff Surcharge'; //RWPS-3026

    //Email ConstantsSHIPPING_CHARGE_PRODUCT
    public static final string CUSTOMER_CARE_NUMBER= 'CustomerCareNumber';
    public static final string CUSTOMER_CARE_EMAIL= 'CustomerCareEmail';


    //ERP Address
    public static final String ERP_ADDRESS_SERVICE = 'ERP_AddressService';
    public static final String ERP_DEFAULT_RECORD_TYPE = 'Default';

    public static final String ERP_ADDRESS_TYPE_SOLD_TO = 'Sold To';
    public static final String ERP_ADDRESS_TYPE_SHIP_TO = 'Ship To';
    public static final String ERP_ADDRESS_TYPE_BILL_TO = 'Bill To';
    public static final String ERP_ADDRESS_TYPE_PAYER = 'Payer';
    public static final String ERP_ADDRESS_TYPE_MASTER = 'Master';

    //Redirect urls
    public static final String SELECT_ADDRESS = 'dashboard?addressStatus=selectAddress&url=replaceURL';
    public static final String ADD_ADDRESS = 'dashboard?addressStatus=addAddress&url=replaceURL';
    public static final String DEFAULT_STOREFRONT='/initiate-session?redirectURL=replaceURL';

    public static final String HTTP_AUTHORIZATION_HEADER = 'Authorization';

    public static final String CHAR_AMP_PERCENT = '&';
    public static final String CHAR_EQUAL_TO = '=';

    public static final String ALGORITHM_AES_256 = 'AES256';
    public static final String INITIALIZATION_VECTOR = 'InitializationVector';
    public static final String MODULE_SECURITY = 'Security';
    public static final String SECRET_KEY = 'SecretKey';
    public static final String URL_ENCODING_UTF_8 = 'UTF-8';

    public static final String ENCRYPTED_TOKEN = 'encryptedToken';
    public static final String ENCRYPTED_CODE = 'encryptedCode';

    public static final String CASE_ORIGIN='Web';
    public static final string PROFILE_AND_SETTING_MODULE_NAME = 'Profile And Settings';
    public static final string PROFILE_NAME = 'PROFILE: ECOM Community User';

    //punchout login
    public static final String PARAM_USER_EMAIL = 'userEmail';
    public static final String PARAM_FIRST_NAME = 'firstName';
    public static final String PARAM_LAST_NAME = 'lastName';
    public static final String PARAM_ACCOUNT_NUMBER = 'accountNumber';
    public static final String PARAM_USER_COMPANY = 'userCompany';
    public static final String PARAM_LOCALE = 'locale';
    public static final String PARAM_CURRENCY_CODE = 'currencyCode';
    public static final String PARAM_COUNTRY_CODE = 'countryCode';
    public static final String PARAM_EMAIL_ENCODING_KEY = 'emailEncodingKey';
    public static final String PARAM_TIMEZONE_SID_KEY = 'timezoneSidKey';
    public static final String PARAM_COUNTRY = 'country';
	public static final String PARAM_IS_NEW_USER = 'isNewUser';
    public static final String PARAM_LOGIN_USER_TYPE = 'loginUserType';
    public static final String PARAM_SUCCESS = 'success';
    public static final String PARAM_MESSAGE = 'message';
    public static final String PARAM_CONTACT_ID = 'contactId';
    public static final String PARAM_FORWARDING_URL = 'storeForwardingUrl';
    public static final String PARAM_USER_ID = 'userId';
    public static final String PARAM_STOREFRONT_URL = 'storefrontURL';
    public static final String PARAM_PART_NUMBER = 'partNumber';
    public static final String PARAM_SITE_NAVIGATION_CONFIG_LABEL = 'UserTypeNavConfiguration';
    public static final String PARAM_SITE_CHECKOUT_NAVIGATION_CONFIG_LABEL = 'ECOMBoomiPoomEndpoint';
    public static final String PARAM_RESPONSE_DATA = 'responseData';
    public static final String PARAM_VIEW_QUICK_ORDER = 'viewQuickOrder';
    public static final String PARAM_PARANTHESIS = '&';
    public static final String PARAM_EQUALS = '=';
    public static final String PARAM_ERP_ACCOUNT_MODEL = 'erpAccountModel';
    public static final String PARAM_ACCOUNT_NAME = 'accountName';
    public static final String PARAM_ACCOUNT_LOGO_URL = 'accountLogoUrl';
    public static final String PARAM_PUNCHOUT_ORG_NAME = 'punchout_org_name';
    public static final String PARAM_PUNCHOUT_ORG_LOGO = 'punchout_org_logo';
    public static final String PARAM_PUNCHOUT_ACCOUNT = 'punchoutAccount';
    public static final String PARAM_USER_NAME = 'userName';
    public static final String PARAM_VAR_USER_NAME = 'varUserName';
    public static final String PARAM_VAR_ACCOUNT_NAME = 'varAccountName';
	public static final String PARAM_URL_EUI = 'eui';
    public static final String PARAM_CONTACT_RECORD = 'contactRecord';
    public static final String PARAM_USER_RECORD = 'userRecord';
    public static final String PARAM_POSR_REQUEST_MODEL = 'posrRequestModel';
    public static final String PARAM_PUNCHOUT_USER_LOGIN_SUCCESS = 'punchoutLoginSuccess';
    public static final String PARAM_PUNCHOUT_ACCOUNT_ID = 'accountId';
    public static final String PARAM_PUNCHOUT_USER = 'punchoutUser';
    public static final String PARAM_PUNCHOUT_USER_TYPE = 'potype';
    public static final String PARAM_PUNCHOUT_PART = 'popart';
    public static final String PARAM_PUNCHOUT_POSR_URL_PARAMETER = 'posr';
    public static final String PARAM_PUNCHOUT_TOKEN = 'punchoutToken';
    public static final String PARAM_PUNCHOUT_CODE = 'punchoutCode';
    public static final String PARAM_CART_ITEMS = 'cartItems';
    public static final String PARAM_TOTAL_SHIPPING = 'shippingTotal';
    public static final String PARAM_RESET_PASS = 'resetPass';
    public static final String PARAM_REQUEST_MODEL = 'requestModel';
    public static final String PARAM_EXT_USER_ID = 'UserID';
    public static final String PARAM_EXT_EMAIL_ID = 'EmailId';
    public static final String PARAM_EXT_SESSION_STARTED_TIMESTAMP = 'SessionStartedTimestamp';
    public static final String PARAM_EXT_IF_SESSION_STARTED_FLAG = 'IfSessionStartedFlag';
    public static final String PARAM_EXT_PART_NUMBER = 'PartNumber';
    public static final String PARAM_EXT_CMS_URL_PARAMETER = 'cmsParams';
    public static final String PARAM_EXT_PRODUCT_URL = 'productUrl';
    public static final String PARAM_EXT_PUNCHOUT_DOMAIN = 'punchout_domain';//RWPS-1115
    public static final String PARAM_RET_UTL = 'retURL'; //VRa ECOM-2555
    public static final String PARAM_REDIRECT_TO = 'redirectTo'; //VRa ECOM-2555
    public static final String PARAM_INPUTS = 'inputs'; //VRa 2024.05.02 ECOM-2302
    public static final String PARAM_PROFILE_REDIRECT = 'profileRedirect'; //VRA 2024.05.23 ECOM-1554
    public static final String PARAM_ORG_ID = 'orgId';// VRa 2024.06.09 ECOM-3261
    public static final String PARAM_LOCALE_CONFIGURATION = 'ECOM_COUNTRY_SWITCHER_CONFIGURATION';//VRa 2024.06.12 ECOM-3261
    public static final String PARAM_USERNAME = 'USERNAME';//Manoj 2024.10.22 RWPS-1543
    public static final String PARAM_COOKIE = 'COOKIE';//Manoj 2024.10.22 RWPS-1543
    public static final String PARAM_PASSWORD = 'PASSWORD';//Manoj 2024.10.22 RWPS-1543
    public static final String GUEST_CONSUMER_KEY = 'GuestConsumerKey';//Manoj 2024.10.22 RWPS-1543

    //punchout checkout
    public static final String POST_URL = 'postFormUrl';

    //punchout user types
    public static final String POTYPE_PUNCHOUT_USER = 'punchoutUser';
    public static final String POTYPE_WEB_USER = 'punchoutUserWeb';
    public static final String POTYPE_TEST_USER = 'storeTestUser';
    public static final String PARTNER_TEST_USER = 'storeTestUser';
    public static final String PUNCHOUT_USER = 'PunchoutUser';
    public static final String PUNCHOUT_WEB_USER = 'PunchoutUserWeb';
    public static final String USER_TYPE_CMS_WEB_USER = 'cmsStoreUser';

    public static final String SITE_MODULE_NAME_FOR_BASE_URL = 'SiteURL';

    //SAP Order Summary
    public static final String SAP_ORDER_SUMMARY_SERIVCE = 'ECOM_SAPOrderSummaryService';


    //Application logs punchout
    public static final String EXCEPTION_TYPE = 'Punchout';
    public static final String POOM_REQUEST = 'POOM Request';
    public static final String POOM_RESPONSE = 'POOM Response';

    //RWPS-1256 - START
    public static final String PARAM_PUNCHOUT_ADDRESSES = 'Punchout Address Map';
    public static final String PARAM_PUNCHOUT_EXCEPTION = 'Punchout Exception';
    public static final String PARAM_PUNCHOUT_EXCEPTION_FLAG = 'Punchout Exception Flag';
    //RWPS-1256 - END

    // Labels for ECOM-1933, ECOM-1942, ECOM-1939, ECOM-1947
    public static final String BILL_TO_FIELD_VALIDATION = 'ECOM_BILL_TO_FIELD_VALIDATIONS';
    public static final String INVOICE_FIELD_VALIDATION = 'ECOM_E_INVOICE_FIELD_VALIDATIONS';

    // Labels for Email Template changes on 2024.05.24
    public static final String API_LABEL = 'label';
    public static final String API_VALUE = 'value';
    public static final String API_DISPLABEL = 'displayLabel';
    public static final String API_FIELDNAME = 'fieldName';
    public static final String API_VALIDATION = 'validation';

    //Registration Labels VRa 2024.05.02 ECOM-2302
    public static final String REGISTRATION_SERVICE = 'ECOM_RegistrationService';

    //Pending For Approval Status
    public static final String ORDER_PENDING_APPROVAL = 'Pending Review';

    //Order Rejected
    public static final String ORDER_REJECTED = 'Rejected';

    //Order Approved
    public static final String ORDER_APPROVED = 'Approved';

    //Label for RWPS-1456
    public static final String PUNCHOUT_CUSTOM_MATERIAL_CODE = 'ECOM_Punchout_Custom';
    // RWPS-2648 - START
    public static final String PARAM_CONTACT_RULE_VII = 'V.RULE_CONTACT_007';
    // RWPS-2648 - END
    // RWPS-3283
    public static final String WEB_PROMOTION = 'Web Promotion';
    public static final String PUNCHOUT_PROMOTION = 'Punchout Promotion';

    public static final String DISCONTINUED_PRODUCT = 'DiscontinuedProduct'; //RWPS-4621
    public static final String ECOM_NON_SELLABLE_PRODUCT = 'ECOM_Non_Sellable_Products';//RWPS-4621
    public static final String DEALER_IDENTIFICATION_VALUE = '10. ECOM';//RWPS-4759
    public static final String ORDER_PRODUCT_TYPE = 'Order Product';//RWPS-4881
    public static final String NOT_SHIPPED = 'Not Shipped';//RWPS-5181
    public static final String RECENTLY_PURCHASED_PRODUCTS = 'RecentlyPurchasedProducts'; //RWPS-5507
    public static final String FREQUENTLY_PURCHASED_PRODUCTS = 'FrequentlyPurchasedProducts'; //RWPS-5507
    public static final String ERROR_LOG_FIELD = 'Error Log Field'; //RWPS-5153

    public static final String PUNCHOUT_CONFIG_REC = 'PunchoutConfigRecord'; // RWPS-5776
 
    public static final String PARAM_TIMEOUT_LIMIT = 'timeoutLimit'; //RWPS-6684
    public static final String ECOM_ENABLE_INVOICECUSTID = 'ECOM_Enable_InvoiceCustId'; //RWPS-6394
    public static final String ECOM_INVOICE_CUSTID_COUNTRIES = 'ECOM_InvoiceCustId_Countries'; //RWPS-6394

    //RWPS-5938
    public static final String ECOM_MAGIC_LINK_CONNECTED_APP_CREDENTIAL_MODULE = 'ECOM_Magic_Link_Connected_App_Credential';
    public static final String ECOM_MAGIC_LINK_CERTIFICATE_MODULE = 'ECOM_Magic_Link_Certificate';
    public static final String ECOM_MAGIC_LINK_GRANT_TYPE_VALUE_MODULE = 'ECOM_Magic_Link_Grant_Type_Value';
    public static final String ECOM_MAGIC_LINK_BASE_URL_MODULE = 'ECOM_Shop_Magic_Link_Base_URL';
    public static final String ECOM_MAGIC_LINK_TOKEN_URL_MODULE = 'ECOM_Magic_Link_Token_URL';
    public static final String ECOM_MAGIC_LINK_SESSION_URL_MODULE = 'ECOM_Magic_Link_Session_URL';
    public static final String ECOM_MAGIC_LINK_EXPIRATION_TIME = 'ECOM_Magic_Link_Expiration_Time';
    public static final String MAGIC_LINK_ACTION = 'Magic Link';
    public static final String TOKEN_ENDPOINT = 'tokenEndpoint';
    //RWPS-5938
    public static final String ECOM_LOG_INFO_MESSAGES = 'ECOM_LOG_INFO_MESSAGES'; //RWPS-6037

}