/**************************************************************

* 1. Jira Ticket(s) that relates to this class
*
*
* 2. Description - This is a test class
*
* 3. Objects referenced
*    - Object Name

* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_TestUtil
*    - ECOM_Constant
*	 - ECOM_MockHttpResponseGenerator
*
*
* 6. Test Class Name:
*
* 7. Is @Invocable : No
*
* 8. Author Name(s):
*    - Sukumar 2023.09.18
*    - Abhishek 2025.04.03 Added method testPerformRestCallout, testPrepareRequestMap, testGetRequestBodyForFlowInput, testDoBasicHttpRequestCalloutAsIntegrationUser, testDoBasicHttpRequestContractPrice. Ticket - RWPS-2858
*    - Sachin V 2025.12.31 Added method testGetEndpointForSandbox, testGetEndpointForProduction - RWPS-5436
*************************************************************/
@isTest(SeeAllData=false)
public class ECOM_RestService_Test {

    /*"testDoBasicHttpRequest" tests the "doBasicHttpRequest" method. Creating a mock HTTP response using the "ECOM_MockHttpResponseGenerator" class
    and set it as the mock response for the HTTP callout using Test.setMock(HttpCalloutMock.class, mockResponse) */

        @isTest
        static void testDoBasicHttpRequest() {
            User u = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
            // Create mock response headers
            Map<String, String> responseHeaders = new Map<String, String>();
            responseHeaders.put('Content-Type', 'application/json');

            // Create mock HTTP response using Generic mock class ECOM_MockHttpResponseGenerator
            ECOM_MockHttpResponseGenerator mockResponse = new ECOM_MockHttpResponseGenerator(200, 'OK', '{"result": "success"}', responseHeaders);

            // Set the mock response for the HTTP callout
            Test.setMock(HttpCalloutMock.class, mockResponse);

            // Create a test request map
            Map<String, String> requestMap = new Map<String, String>();
            requestMap.put(ECOM_Constant.HTTP_REQUEST_TYPE, 'GET');

            Test.startTest();
            HttpResponse res;
            System.runAs(u){
                res = ECOM_RestService.doBasicHttpRequest(requestMap);
            }

            Test.stopTest();

            // Assert the response
            System.assertEquals(200, res.getStatusCode());
            System.assertEquals('OK', res.getStatus());
            System.assertEquals('{"result": "success"}', res.getBody());
        }
        @isTest
    static void testDoBasicHttpRequestOrderCreate() {
        // Order order = [Select Id From Order ORDER BY CREATEDDATE DESC LIMIT 1];
        // Create mock response headers
        Map<String, String> responseHeaders = new Map<String, String>();
        responseHeaders.put('Content-Type', 'application/json');

       // Create mock HTTP response using Generic mock class ECOM_MockHttpResponseGenerator
        ECOM_MockHttpResponseGenerator mockResponse = new ECOM_MockHttpResponseGenerator(201, 'Created', '{"orderId": "12345"}', responseHeaders);

        // Set the mock response for the HTTP callout
        Test.setMock(HttpCalloutMock.class, mockResponse);

        // Create a test request map
        Map<String, String> requestMap = new Map<String, String>();
        requestMap.put(ECOM_Constant.HTTP_REQUEST_TYPE, 'POST');
        requestMap.put(ECOM_Constant.HTTP_REQUEST_BODY, '{"orderName": "Test Order"}');

        // Call the method under test
        HttpResponse res = ECOM_RestService.doBasicHttpRequestOrderCreate(requestMap);

        // Assert the response
        System.assertEquals(201, res.getStatusCode());
        System.assertEquals('Created', res.getStatus());
        System.assertEquals('{"orderId": "12345"}', res.getBody());
    }

    @isTest
        static void punchoutCheckoutRestCallTest() {
            User u = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
            // Create mock response headers
            Map<String,String> requestHeader = new Map<String,String>();
            requestHeader.put(ECOM_Constant.REQUEST_METHOD_TYPE,'POST');
            requestHeader.put(ECOM_Constant.HTTP_REQUEST_ENDPOINT,'testUrl');
            requestHeader.put(ECOM_Constant.HTTP_REQUEST_BODY,'testBody');
            requestHeader.put('RandomKey','testValue');

            // Create mock HTTP response using Generic mock class ECOM_MockHttpResponseGenerator
            ECOM_MockHttpResponseGenerator mockResponse = new ECOM_MockHttpResponseGenerator(200, 'OK', '{"result": "success"}', requestHeader);

            // Set the mock response for the HTTP callout
            Test.setMock(HttpCalloutMock.class, mockResponse);

            // Create a test request map
            Map<String, String> requestMap = new Map<String, String>();
            requestMap.put(ECOM_Constant.HTTP_REQUEST_TYPE, 'GET');

            Test.startTest();
            HttpResponse res;
            System.runAs(u){
                res = ECOM_RestService.punchoutCheckoutRestCall(requestHeader);
            }

            Test.stopTest();

            // Assert the response
            System.assertEquals(200, res.getStatusCode());
            System.assertEquals('OK', res.getStatus());
            System.assertEquals('{"result": "success"}', res.getBody());
        }

    @isTest
    static void mapRequestValuesTest(){
        Map<String,String> requestHeader = new Map<String,String>();
        requestHeader.put(ECOM_Constant.REQUEST_METHOD_TYPE,'POST');
        requestHeader.put(ECOM_Constant.HTTP_REQUEST_ENDPOINT,'testUrl');
        requestHeader.put(ECOM_Constant.HTTP_REQUEST_BODY,'testBody');
		requestHeader.put('RandomKey','testValue');
        Test.startTest();
        HttpRequest response = ECOM_RestService.mapRequestValues(requestHeader);
        Test.stopTest();
        system.assertEquals('POST',response.getMethod(),'Unexpected response');
    }

    /**
      * @description Test case http request to get contract price
      * @author Abhishek Joshi
      * @date 02-04-2025
     */
    @isTest
    static void testDoBasicHttpRequestContractPrice() {
        User u = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        // Create mock response headers
        Map<String, String> responseHeaders = new Map<String, String>();
        responseHeaders.put('Content-Type', 'application/json');

        // Create mock HTTP response using Generic mock class ECOM_MockHttpResponseGenerator
        ECOM_MockHttpResponseGenerator mockResponse = new ECOM_MockHttpResponseGenerator(200, 'OK', '{"result": "success"}', responseHeaders);

        // Set the mock response for the HTTP callout
        Test.setMock(HttpCalloutMock.class, mockResponse);

        // Create a test request map
        Map<String, String> requestMap = new Map<String, String>();
        requestMap.put(ECOM_Constant.HTTP_REQUEST_TYPE, 'GET');
        requestMap.put(ECOM_Constant.ACTION_TYPE, 'ContractPrice');

        Test.startTest();
        HttpResponse res;
        System.runAs(u){
            res = ECOM_RestService.doBasicHttpRequest(requestMap);
        }

        Test.stopTest();

        // Assert the response
        System.assertEquals(200, res.getStatusCode());
        System.assertEquals('OK', res.getStatus());
        System.assertEquals('{"result": "success"}', res.getBody());
    }

    @isTest
    static void testDoBasicHttpRequestCalloutAsIntegrationUser() {
        User u = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        // Create mock response headers
        Map<String, String> responseHeaders = new Map<String, String>();
        responseHeaders.put('Content-Type', 'application/json');

        // Create mock HTTP response using Generic mock class ECOM_MockHttpResponseGenerator
        ECOM_MockHttpResponseGenerator mockResponse = new ECOM_MockHttpResponseGenerator(200, 'OK', '{"result": "success"}', responseHeaders);

        // Set the mock response for the HTTP callout
        Test.setMock(HttpCalloutMock.class, mockResponse);

        // Create a test request map
        Map<String, String> requestMap = new Map<String, String>();
        requestMap.put(ECOM_Constant.HTTP_REQUEST_TYPE, 'GET');
        requestMap.put(ECOM_Constant.ACTION_TYPE, 'ContractPrice');

        Test.startTest();
        HttpResponse res;
        System.runAs(u){
            res = ECOM_RestService.calloutAsIntegrationUser(requestMap);
        }

        Test.stopTest();

        // Assert the response
        System.assertEquals(200, res.getStatusCode());
        System.assertEquals('OK', res.getStatus());
        System.assertEquals('{"result": "success"}', res.getBody());
    }

    @isTest
    static void testGetRequestBodyForFlowInput() {

        Map<String, Object> reqMap = new Map<String, Object>();

        Test.startTest();
        String res;
        res = ECOM_RestService.getRequestBodyForFlowInput(reqMap);

        Test.stopTest();

        // Assert the response
        System.assertEquals('{"inputs":[{}]}', res);
    }

    @isTest
    static void testPrepareRequestMap() {

        Test.startTest();
        Map<String, String> res;
        res = ECOM_RestService.prepareRequestMap('testCreds', '/test', '{}', 'GET', false, new Map<String, Object>(), '');

        Test.stopTest();

        // Assert the response
        System.assertEquals(res.get(ECOM_Constant.REQUEST_METHOD_TYPE), 'GET');
    }

    @isTest
    static void testPerformRestCallout() {
        User u = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        // Create mock response headers
        Map<String, String> responseHeaders = new Map<String, String>();
        responseHeaders.put('Content-Type', 'application/json');

        // Create mock HTTP response using Generic mock class ECOM_MockHttpResponseGenerator
        ECOM_MockHttpResponseGenerator mockResponse = new ECOM_MockHttpResponseGenerator(200, 'OK', '{"result": "success"}', responseHeaders);

        // Set the mock response for the HTTP callout
        Test.setMock(HttpCalloutMock.class, mockResponse);

        // Create a test request map
        Map<String, String> requestMap = new Map<String, String>();
        requestMap.put(ECOM_Constant.HTTP_REQUEST_TYPE, 'GET');
        requestMap.put(ECOM_Constant.ACTION_TYPE, 'ContractPrice');

        Test.startTest();
        HttpResponse res;
        System.runAs(u){
            res = ECOM_RestService.performRestCallout(requestMap);
        }

        Test.stopTest();

        // Assert the response
        System.assertEquals(200, res.getStatusCode());
        System.assertEquals('OK', res.getStatus());
        System.assertEquals('{"result": "success"}', res.getBody());
    }

    //RWPS-5436
    @isTest
    static void testGetEndpointForSandbox() {
        Boolean isSandbox = true;
        String namedCredentialName;
        Test.startTest();
        namedCredentialName = ECOM_RestService.getEndpoint(isSandbox);
        Test.stopTest();
        System.assertEquals(System.Label.ECOM_OrderSimulationNamedCredentialSBX, namedCredentialName);
    }

    //RWPS-5436
    @isTest
    static void testGetEndpointForProduction() {
        Boolean isSandbox = false;
        String namedCredentialName;
        Test.startTest();
        namedCredentialName = ECOM_RestService.getEndpoint(isSandbox);
        Test.stopTest();
        System.assertEquals(System.Label.ECOM_OrderSimulationNamedCredentialPROD, namedCredentialName);
    }
}