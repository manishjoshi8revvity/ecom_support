/**************************************************************
  * 1. Jira Ticket(s)
  *    - OM-256 automated Sandbox Refresh Scheduler
  *
  * 2. Description - This apex class is used in SandboxRefreshCalloutTest to generate fake request/response
  * 
  * 3. Objects referenced
  *    
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    
  * 5. Dependant Class(es):
  *    - SandboxRefreshCalloutTest
  *    
  *
  * 6. Test Class Name: SandboxRefreshCalloutMock
  * 
  * 7. Is @Invocable (Yes or No): No
  *
  * 8. Author Name(s): 
  *    - Sumit Kumar Sourav /Avinash Kumar(PWC) & Created Date(02/7/2024)
  *    -
  *    -
*************************************************************/ 
@isTest
public class SandboxRefreshCalloutMock implements HttpCalloutMock {
    protected Integer code;
    protected String status;
    protected String bodyAsString;
    protected Blob bodyAsBlob;
    protected Map<String, String> responseHeaders;
    
    public HTTPResponse respond(HTTPRequest req) {
        String bodystr='{   "size" : 34,   "totalSize" : 34,   "done" : true,   "queryLocator" : null,   "entityTypeName" : "SandboxInfo",   "records" : [ {     "attributes" : {       "type" : "SandboxInfo",       "url" : "/services/data/v58.0/tooling/sobjects/SandboxInfo/0GQ4V000000XasfWAC"     },     "Id" : "0GQ4V000000XasfWAC",     "SandboxName" : "QA"   }]}';
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type','application/json');
        res.setBody(bodystr);
        res.setStatusCode(200);
        return res;
    }
}