/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-3225
*
* 2. Description - This class is used for services to be used in Self-Service Application. Services include authentication with Microsoft Entra by sending http request and confirming user identity. It also provides service to get data from SAP
*
* 3. Objects referenced
*   -
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_EncryptUtil
*    - ECOM_ApplicationLogsUtil
*    - ECOM_SelfServiceConstants
*
* 6. Test Class Name: ECOM_SelfServiceService_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Abhishek Joshi 19 June 2024
*    - Manish Joshi 2024.12.13 updated method getOrderFromSAP for env specific order end points. Ticket - RWPS-1662
*    - Abhishek Joshi 2025.05.23 updated getOrderFromSAP method - RWPS-3289
*
*************************************************************/

public without sharing class ECOM_SelfServiceService {
    private static final String CLASS_NAME = 'ECOM_SelfServiceService';
    private static final String MICROSOFT_GRAPH_ENDPOINT = 'https://graph.microsoft.com/oidc/userinfo';
    private static final String MICROSOFT_GRAPH_HOST = 'graph.microsoft.com';

    /**
     * @description This method returns the encrypted user data after receiving data from Entra using access token
     * @author abhishek.joshi@revvity.com | 17 June 2024
     * @param accessToken | String
     * @param email | String
     * @param sub | String
     * @return Map<String, String>
     */
    public static Map<String, String> authWithEntra(String accessToken, String email, String sub) {
        Datetime requestTimestamp;
        Datetime responseTimestamp;
        String apiResponse;

        try {
            // Ensure data is valid
            if(
                String.isBlank(accessToken)
            ) {
                return new Map<String, String>{ECOM_SelfServiceConstants.METHOD_SUCCESS_KEY => null};
            }

            if(
                !email.endsWith(ECOM_SelfServiceConstants.EMAIL_SUFFIX)
            ) {
                throw new RequiredFeatureMissingException();
            }

            // Instantiate a new Http object
            Http h = new Http();

            // Instantiate a new HTTP request (to verify token), specify the method (GET) as well as the endpoint
            HttpRequest req = new HttpRequest();
            req.setEndpoint(MICROSOFT_GRAPH_ENDPOINT);
            req.setMethod(ECOM_SelfServiceConstants.HTTP_METHOD_GET);
            req.setHeader(
                ECOM_Constant.AUTHORIZATION,
                'Bearer ' + accessToken
            );
            req.setHeader('Host', MICROSOFT_GRAPH_HOST);

            Map<String, Object> resJSON;

            if (Test.isRunningTest()) {
                resJSON = new Map<String, Object>();
                resJSON.put('email', email);
                resJSON.put('sub', sub);
            } else {
                requestTimestamp = Datetime.now();
                HttpResponse res = h.send(req);
                responseTimestamp = Datetime.now(); apiResponse = res.getBody();
                resJSON = (Map<String, Object>) JSON.deserializeUntyped(apiResponse);
            }

            String name = (String) resJSON.get('given_name');
            String fullName = (String) resJSON.get('name');

            // Verify received user data with the data in id received during OIDC
            String resEmail = (String) resJSON.get('email');
            String resSub = (String) resJSON.get('sub');
            if(resEmail != email || resSub != sub) {
                return new Map<String, String>{ ECOM_SelfServiceConstants.METHOD_SUCCESS_KEY => null };
            }

            // Encrypt data to store it in cookie
            String encryptionSeparator = ECOM_SelfServiceConstants.ENCRYPTION_SEPARATOR;
            String randomString1 = String.valueOf(Math.floor(Math.random()*1000000).intValue()) + encryptionSeparator;
            String randomString2 = encryptionSeparator + String.valueOf(Math.floor(Math.random()*1000000).intValue());

            Datetime dt = Datetime.now();
            Long dtEpoch = dt.getTime();

            String actualEncryptionData =
                JSON.serialize(
                    new Map<String, String> {
                        'name' => name,
                        'email' => email,
                        'fullName' => fullName,
                        'time'=> String.valueOf(dtEpoch)
                    }
                );

            String encryptedString =
                ECOM_EncryptUtil.encryptWithAES256(
                    randomString1 + actualEncryptionData + randomString2
                );

            return new Map<String, String>{ECOM_SelfServiceConstants.METHOD_SUCCESS_KEY => '1', 'name' => name, 'enc'=>encryptedString};
        } catch (Exception e) {
            ECOM_SelfServiceUtils.selfserviceLogException(new Map<String, Object> {'className' => (Object) CLASS_NAME, 'methodName' => (Object) 'authWithEntra', 'moduleName' => (Object) 'SelfServiceAuthWithEntra', 'supportData' => (Object) ('Attempting User: ' + email + ' || Cause: ' + e.getCause()), 'requestTimestamp' => (Object) requestTimestamp, 'responseTimestamp' => (Object) responseTimestamp, 'apiResponse' => (Object) apiResponse}, e);
            return new Map<String, String>{ECOM_SelfServiceConstants.METHOD_SUCCESS_KEY => null};
        }
    }

    /**
     * @description This method returns the order details reveived from SAP via Boomi API
     * @author abhishek.joshi@revvity.com | 8 October 2024
     * @param orderNumber | String
     * @return Map<String, Object>
     */
    public static Map<String, Object> getOrderFromSAP(String orderNumber) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        HTTPResponse res = new HTTPResponse();

        Datetime requestTimestamp;
        Datetime responseTimestamp;
        String apiResponse;

        try {
            req.setEndpoint(
                'callout:ECOM_Selfservice_Trackmate_API' // RWPS-3289
            );
            req.setMethod(
                ECOM_SelfServiceConstants.HTTP_METHOD_POST
            );
            req.setHeader(
                ECOM_Constant.HTTP_CONTENT_TYPE, ECOM_Constant.HTTP_CONTENT_APP_JSON
            );
            req.setTimeout(120000);

            Map <String, String> reqBody =
                new Map<String,String>{'orderId' => orderNumber}; // RWPS-3289

            req.setBody(
                JSON.serialize((Object) reqBody)
            );

            Map<String, Object> resJSON;

            if(Test.isRunningTest()) {
                resJSON = new Map<String, Object>();
                if(
                    orderNumber == ECOM_SelfServiceConstants.TEST_SAP_ORDER_NUMBER
                ) {
                    resJSON.put(
                        ECOM_SelfServiceConstants.SAP_RESPONSE_PO_KEY, 'PO-123'
                    );
                    resJSON.put(
                        ECOM_SelfServiceConstants.SAP_RESPONSE_POSTAL_CODE_KEY, '12345'
                    );
                    resJSON.put(
                        ECOM_SelfServiceConstants.SAP_RESPONSE_INDICATOR_KEY,
                        (Object) true
                    );
                    // RWPS-3289 start
                    resJSON.put(
                        ECOM_SelfServiceConstants.SAP_RESPONSE_ORDER_TYPE_KEY,
                        'test-type'
                    );
                    // RWPS-3289 end
                }
            } else {
                requestTimestamp = Datetime.now();
                res = http.send(req);
                responseTimestamp = Datetime.now(); apiResponse = res.getBody();

                resJSON = (Map<String, Object>) JSON.deserializeUntyped(apiResponse);

                if(res.getStatusCode()==200 && resJSON.containsKey('SalesOrg')) { // RWPS-3289

                    resJSON.put(ECOM_SelfServiceConstants.SAP_RESPONSE_INDICATOR_KEY, (Object) true);

                } else { resJSON.put(ECOM_SelfServiceConstants.SAP_RESPONSE_INDICATOR_KEY, (Object) false); }
            }

             // RWPS-3289
            ECOM_Application_Logs__c log = new ECOM_Application_Logs__c();
            log.Source_Type__c = ECOM_SelfServiceConstants.LOGGING_SOURCE_TYPE;
            log.Endpoint__c = req.getEndpoint();
            log.SupportData__c = req.getBody();
            log.ModuleName__c = 'ECOM_Selfservice_Trackmate_API';
            log.MethodName__c = 'getOrderFromSAP';
            log.Request_TimeStamp__c = requestTimestamp;
            log.Request_TimeStamp_ms__c = log.Request_TimeStamp__c?.getTime();
            log.Response_TimeStamp__c = responseTimestamp;
            log.Response_TimeStamp_ms__c = log.Response_TimeStamp__c?.getTime();
            log.ExceptionRunningUser__c = UserInfo.getUserId();//RWPS-993
            log.ApiResponse__c = 'Response status Code : '+res.getStatusCode()+' . Response Body : '+res.getBody();
            Database.insert(log);

            return resJSON;
        } catch (Exception e) {
            String message = 'Unknown error occurred while getting data';ECOM_SelfServiceUtils.selfserviceLogException(new Map<String, Object> {'className' => (Object) CLASS_NAME, 'methodName' => (Object) 'getOrderDetails', 'moduleName' => (Object) 'SelfServiceServiceOrderDetails', 'supportData' => (Object) ('Cause: ' + e.getCause()), 'requestTimestamp' => (Object) requestTimestamp, 'responseTimestamp' => (Object) responseTimestamp, 'apiResponse' => (Object) apiResponse}, e);
            return new Map<String, Object>{ECOM_SelfServiceConstants.METHOD_ERROR_KEY => (Object) message, ECOM_SelfServiceConstants.SAP_RESPONSE_INDICATOR_KEY => (Object) false};
        }
    }
}