@isTest 
public class ECOM_MockHttpResponseGenerator implements HttpCalloutMock {
    protected Integer code;
    protected String status;
    protected String bodyAsString;
    protected Blob bodyAsBlob;
    protected Map<String, String> responseHeaders;
    
    public ECOM_MockHttpResponseGenerator(Integer code, String status, String body,Map<String, String> responseHeaders) {
        this.code = code;
        this.status = status;
        this.bodyAsString = body;
        this.bodyAsBlob = null;
        this.responseHeaders = responseHeaders;
    }
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse resp = new HttpResponse();
        resp.setStatusCode(code);
        resp.setStatus(status);
        
        if (bodyAsBlob != null) {
            resp.setBodyAsBlob(bodyAsBlob);
        } else {
            resp.setBody(bodyAsString);
        }
        
        if (responseHeaders != null) {
            for (String key : responseHeaders.keySet()) {
                resp.setHeader(key, responseHeaders.get(key));
            }
        }
        return resp;
    }
}


//  ECOM_TaxService taxService = new ECOM_TaxService(); 
//        String respBody = '{"error" : {"MESSAGE" : "page not gound"}}';

//         Test.startTest(); 
//         try{
//             Test.setMock(HttpCalloutMock.class, new ECOM_MockHttpResponseGenerator(
//                     404,'The page cannot be found',respBody,null)
//                 );
//             Map<String, ECOM_TaxModel> taxModelsByStrings = taxService.calculateTax(webCart.Id);
//             System.assertNotEquals(null, taxModelsByStrings);
//         }catch(Exception ex) {
//             System.assertNotEquals('Success', ex.getMessage());
//         }
//         Test.stopTest();


//  String responseBodyprocess_payment ='{"id" : "cu_ivnaubjn45" , "amount":100 , "status" : "success" ,'+ 
//             ' "source" : { "last4" : "1111" , "exp_month" : 11 , "exp_year" : 2023 , "brand" : "visa" } ,'+
//             ' "last4" : "1111" , "country" : { "names" : {"en":"Bhutan"}}  , "brand" : "visa" } ';
//         Test.setMock(HttpCalloutMock.class, new ECOM_MockHttpResponseGenerator(200,'OK',responseBodyprocess_payment,null));