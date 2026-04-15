/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-3225
*
* 2. Description - This class is used for storing constants for Self-Service Application
*
* 3. Objects referenced
*   -
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    -
*
* 6. Test Class Name:
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Abhishek Joshi 12 July 2024
*    - Abhishek Joshi 2025.05.02 - Added constant TRACKING_MAP_METADATA, EXCLUDED_ORDER_TYPES_METADATA, SAP_RESPONSE_ORDER_TYPE_KEY - RWPS-3289
*
*************************************************************/

public with sharing class ECOM_SelfServiceConstants {
    public static final String METHOD_SUCCESS_KEY = 'success';
    public static final String METHOD_ERROR_KEY = 'error';
    public static final String SAP_RESPONSE_INDICATOR_KEY = 'SAPResponse';
    public static final String ENCRYPTION_SEPARATOR = '-,-,-';
    public static final String EMAIL_SUFFIX = '@revvity.com';
    public static final String TEST_SAP_ORDER_NUMBER = '123456-SAP';
    public static final String LOGGING_SOURCE_TYPE = 'Self Service';
    public static final String TRACKING_MAP_METADATA = 'Tracking_URL_Mapping'; // RWPS-3289
    public static final String EXCLUDED_ORDER_TYPES_METADATA = 'Excluded_Order_Types'; // RWPS-3289

    public static final String HTTP_METHOD_GET = 'GET';
    public static final String HTTP_METHOD_POST = 'POST';

    public static final String SAP_RESPONSE_PO_KEY = 'PONumber';
    public static final String SAP_RESPONSE_POSTAL_CODE_KEY = 'ShippingPostalCode';
    public static final String SAP_RESPONSE_ORDER_TYPE_KEY = 'OrderType'; // RWPS-3289
}