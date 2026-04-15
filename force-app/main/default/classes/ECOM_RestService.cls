/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-113
*    ECOM-114
*	 ECOM-1020
*	 ECOM-2555
*
* 2. Description - This class is used to make Rest Callouts.
*
*
*
* 3. Objects referenced
*    -None
*
* 4. Callouts to additional Components (including their methods) or None:
*    - Callouts to Dell Boomi
*
* 5. Dependant Class(es):
*    - ECOM_CartService
*    - ECOM_OrderController
*    - ECOM_OrderCreateAPIUtil
* 	 - ECOM_PunchoutUserLoginController
*
* 6. Test Class Name:
*    - ECOM_RestService_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Manoj 2023.08.20
*    - Rani 2023.09.19
*    - Vipul 2023.09.20
* 	 - Vasudev 2023.11.23
* 	 - Vasudev 2024.04.23
*    - Gaurang 2024.05.27 - modified doBasicHttpRequest method for invoicePDF call - ECOM-1931
*    - Sidak 2024.07.03 Updated method doBasicHttpRequest to Get SAP Contact Id Callout. Ticket RWPS-553
*.   - Sathiya 2024.08.29 Updated the changes for ECOM-1480
*    - Sidak 2024.12.10 Updated method doBasicHttpRequest, added logic to fetch org type from custom setting. Ticket RWPS-1662
*    - Abhishek 2025.03.25 Updated method doBasicHttpRequest - RWPS-2858
*    - Sachin V 2025.12.31 Updated method doBasicHttpRequest, Created method getEndpoint - RWPS-5436
*    - Sachin V 2026.02.22 - Updated method : doBasicHttpRequest - RWPS-5938
*************************************************************/
public class ECOM_RestService {

    public static HttpRequest req = new HttpRequest();

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
    * @description // This method will perform a REST Callout using Basic Authentication
    * @author Vipul Goyal | 09-20-2023
    * @author Sidak Singh | 07-03-2024 | RWPS-553
    * @author Sidak Singh | 12-10-2024 | RWPS-1662
    * @author Sachin Vispute | 31-12-2025 | RWPS-5436
    * @param requestMap
    * @return HttpResponse
    **/
    public static HttpResponse doBasicHttpRequest(Map<String, String> requestMap) {
        req = new HttpRequest();
        HTTPResponse res = new HTTPResponse();
        ECOM_Application_Logs__c log=new ECOM_Application_Logs__c();
        try
        {
            //RWPS-1662
            Boolean isSandbox = ECOM_CustomMetadataService.getOrgType();
            String namedCred = getEndpoint(isSandbox); //RWPS-5436 : moved logic to send endpoint to separate method - getEndpoint();

            // Order create call out
            if(requestMap.get(ECOM_Constant.ACTION_TYPE) != null && requestMap.get(ECOM_Constant.ACTION_TYPE) == 'OrderCreate'){
                req.setEndpoint(namedCred+'/order/OrderCreate/');//RWPS-1662
            // Order simulate call out
            } else if(requestMap.get(ECOM_Constant.ACTION_TYPE) != null && requestMap.get(ECOM_Constant.ACTION_TYPE) == 'OrderSimulate'){
                req.setEndpoint(namedCred+'/order/simulate/');//RWPS-1662
            }else if(requestMap.get(ECOM_Constant.ACTION_TYPE) != null && requestMap.get(ECOM_Constant.ACTION_TYPE) == 'CreateCase'){
                req.setEndpoint(namedCred+'/integration/case/');//RWPS-1662
            }
            //ECOM-1931 - garora@rafter.one - callout endpoint for invoice pdf added - 27 May 2024
            else if(requestMap.get(ECOM_Constant.ACTION_TYPE) != null && requestMap.get(ECOM_Constant.ACTION_TYPE) == 'invoicePDF'){
                req.setEndpoint('callout:ECOM_InvoicePDF');
            }else if(requestMap.get(ECOM_Constant.ACTION_TYPE) != null && requestMap.get(ECOM_Constant.ACTION_TYPE) == 'GetSAPContactId'){
                req.setEndpoint(namedCred+'/integration/contact/multiple');//RWPS-1662
            } else if(requestMap.get(ECOM_Constant.ACTION_TYPE) != null && requestMap.get(ECOM_Constant.ACTION_TYPE) == 'ContractPrice'){
                if(isSandbox){
                    namedCred = System.Label.ECOM_ContractPriceNamedCredentialSBX;
                }
                else {
                    namedCred = System.Label.ECOM_ContractPriceNamedCredentialPROD;
                }
                req.setEndpoint(namedCred+'/contractprice');//RWPS-2858
            } else if (requestMap.get(ECOM_Constant.ACTION_TYPE) != null && requestMap.get(ECOM_Constant.ACTION_TYPE) == ECOM_Constant.MAGIC_LINK_ACTION) {
                //RWPS-5938
                req.setEndpoint('callout:ECOM_Shop'+ requestMap.get('tokenEndpoint'));
                req.setHeader(ECOM_Constant.HTTP_CONTENT_TYPE, ECOM_Constant.HTTP_CONTENT_FORM_URLENCODED);
                log.ECOM_Contact__c = requestMap.get('ContactId') != null ? requestMap.get('ContactId') : null;
                log.ECOM_Contact_Email__c = requestMap.get('ContactEmail') != null ? requestMap.get('ContactEmail') : null;
                //RWPS-5938
            }

            log.Endpoint__c = req.getEndpoint();
            log.SupportData__c = requestMap.get(ECOM_Constant.HTTP_REQUEST_BODY);
            // Add Action Type to the Module Name
            log.ModuleName__c = ECOM_Constant.HTTP_API_MODULE + ' - ' + requestMap.get(ECOM_Constant.ACTION_TYPE);
            // Changes End
            log.MethodName__c = 'doBasicHttpRequest';

            String methodType = requestMap.get(ECOM_Constant.HTTP_REQUEST_TYPE);
            req.setMethod(methodType);
            if(methodType.equalsIgnoreCase(ECOM_Constant.HTTP_REQUEST_POST) || methodType.equalsIgnoreCase(ECOM_Constant.HTTP_REQUEST_PUT) || methodType.equalsIgnoreCase(ECOM_Constant.HTTP_REQUEST_PATCH)) {
                req.setBody(requestMap.get(ECOM_Constant.HTTP_REQUEST_BODY));
            }
            //RWPS-5938
            if (requestMap.get(ECOM_Constant.ACTION_TYPE) != null && requestMap.get(ECOM_Constant.ACTION_TYPE) != ECOM_Constant.MAGIC_LINK_ACTION) {
                Blob headerValue = Blob.valueOf('{!$Credential.UserName}' + ':' + '{!$Credential.Password}');
                String authorizationHeader = ECOM_Constant.AUTH_BASIC + ' ' + EncodingUtil.base64Encode(headerValue);
                req.setHeader(ECOM_Constant.HTTP_CONTENT_TYPE, ECOM_Constant.HTTP_CONTENT_APP_JSON);
                req.setHeader(ECOM_Constant.AUTHORIZATION, authorizationHeader);
            }
            //RWPS-5938
            req.setTimeout(120000);
            log.Request_TimeStamp__c = System.now();
            log.Request_TimeStamp_ms__c = log.Request_TimeStamp__c.getTime();
            res = sendRequest(req);
            log.Response_TimeStamp__c = System.now();
            log.Response_TimeStamp_ms__c = log.Response_TimeStamp__c.getTime();
            log.ExceptionRunningUser__c = UserInfo.getUserId();//RWPS-993
            log.ApiResponse__c = 'Response status Code : '+res.getStatusCode()+' . Response Body : '+res.getBody();
            // Add Exception Type for all callouts with response code other than 200
            log.ExceptionType__c = res.getStatusCode() != 200?ECOM_Constant.INTEGRATION_EXCEPTION:null;
            // Changes end
            System.debug(res.getBody());
            System.debug(res.getStatusCode());
        } catch (Exception ex) {
            log.ExceptionRunningUser__c = UserInfo.getUserId();
            log.ExceptionType__c = ex.getTypeName();
            log.ErrorMessage__c = ex.getMessage();
            log.StackTrace__c = ex.getStackTraceString();
        }

        ECOM_ApplicationLogsUtil.insertApplicationLogs(log);

        return res;
    }


    /**
    * @description // This method will perform a REST Callout using Basic Authentication Order Create
    * @author Vipul Goyal | 09-20-2023
    * @param requestMap
    * @return HttpResponse
    **/
    public static HttpResponse doBasicHttpRequestOrderCreate(Map<String, String> requestMap) {
        req = new HttpRequest();
        req.setEndpoint('callout:ECOM_Order_Create');
        String methodType = requestMap.get(ECOM_Constant.HTTP_REQUEST_TYPE);
        req.setMethod(methodType);
        if(methodType.equalsIgnoreCase(ECOM_Constant.HTTP_REQUEST_POST) || methodType.equalsIgnoreCase(ECOM_Constant.HTTP_REQUEST_PUT) || methodType.equalsIgnoreCase(ECOM_Constant.HTTP_REQUEST_PATCH)) {
            req.setBody(requestMap.get(ECOM_Constant.HTTP_REQUEST_BODY));
        }
        req.setHeader(ECOM_Constant.HTTP_CONTENT_TYPE, ECOM_Constant.HTTP_CONTENT_APP_JSON);
        req.setTimeout(120000);
        Blob headerValue = Blob.valueOf('{!$Credential.UserName}' + ':' + '{!$Credential.Password}');
        String authorizationHeader = ECOM_Constant.AUTH_BASIC + ' ' + EncodingUtil.base64Encode(headerValue);
        req.setHeader(ECOM_Constant.AUTHORIZATION, authorizationHeader);
        HTTPResponse res = sendRequest(req);
        System.debug(res.getBody());
        System.debug(res.getStatusCode());

        return res;
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
    * @description Method to perform REST callout based on the Request map
    * @author garora@rafter.one | 15 Jan 2024
    * @param Map<String,String>
    * @return HttpResponse
    **/
    public static HttpResponse punchoutCheckoutRestCall(Map<String,String> requestMap){
        //set header values
        HttpRequest request = mapRequestValues(requestMap);
        request.setTimeout(120000);
        System.debug('Request:: '+ request);

        //send request
		HttpResponse response = sendRequest(request);
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
     * @description This method performs a named credetial callout as BOOMI integration user to site endpoint
     * @author vramachandran@rafter.one | 2024.05.02 VRa ECOM-2302
     * @param requestMap
     * @return HttpResponse
     */
    public static HttpResponse calloutAsIntegrationUser(Map<String,String> requestMap){

        HttpResponse responseObject;
        HttpRequest requestObject = mapRequestValues(requestMap);
        System.debug('calloutAsIntegrationUser:requestObject:: '+requestObject);
        requestObject.setTimeout(120000);

        responseObject = sendRequest(requestObject);
        return responseObject;
    }

    /**
     * @description This method prepares and returns the request map with the callout information
     * @author vramachandran@rafter.one | 2024.05.02 VRa ECOM-2302
     * @param namedCredential | string
     * @param requestEndpoint | String
     * @param body | String
     * @param methodType | String
     * @returns Map<String, String>
     */
    public static Map<String, String> prepareRequestMap(String namedCredential, String requestEndpoint, String body, String methodType, Boolean isFlowBody, Map<String, Object> bodyMap, String contentType){
        Map<String, String> requestMap = new Map<String, String>();

        requestMap.put(ECOM_Constant.HTTP_REQUEST_ENDPOINT, namedCredential + requestEndpoint);
        requestMap.put(ECOM_Constant.REQUEST_METHOD_TYPE, methodType);
        requestMap.put(ECOM_Constant.HTTP_CONTENT_TYPE, ECOM_Constant.HTTP_CONTENT_APP_JSON);
        requestMap.put(ECOM_Constant.AUTHORIZATION, ECOM_Constant.AUTH_BASIC + ' ' + EncodingUtil.base64Encode(Blob.valueOf('{!$Credential.UserName}' + ':' + '{!$Credential.Password}')));
        requestMap.put(ECOM_Constant.HTTP_REQUEST_BODY, (isFlowBody ? getRequestBodyForFlowInput(bodyMap) : (null != bodyMap) ? JSON.serialize(bodyMap) : body));

       	return requestMap;
    }

    @testVisible
    private static String getRequestBodyForFlowInput(Map<String, Object> bodyMap){
        List<Map<String, Object>> listOfBodyMap = new List<Map<String, Object>>();
        listOfBodyMap.add(bodyMap);
        Map<String, List<Map<String, Object>>> inputMap = new Map<String, List<Map<String, Object>>>();
        inputMap.put(ECOM_Constant.PARAM_INPUTS, listOfBodyMap);

        return JSON.serialize(inputMap);
    }

    /**
     * @description This method prepares and returns the endpoint based on org type
     * @author Sachin V | 2025.12.31 - RWPS-5436
     * @param isSandbox | boolean
     * @returns String
     */
    public static string getEndpoint(Boolean isSandbox) {
        if(isSandbox == true) {
            return System.Label.ECOM_OrderSimulationNamedCredentialSBX;
        } else {
            return System.Label.ECOM_OrderSimulationNamedCredentialPROD;
        }
    }
}