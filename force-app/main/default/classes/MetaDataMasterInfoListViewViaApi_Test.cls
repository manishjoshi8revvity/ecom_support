/**************************************************************
  * 1. Jira Ticket(s)
  *    - OM-213 APEX to Upsert ListView config to Master_Info__c
  *
  * 2. Description - This is test class for MetaDataMasterInfoListViewViaApi
  * 
  * 3. Objects referenced 
  *    -Master_Info__c
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    MetaDataMasterInfoListViewViaApi
  * 
  * 5. Dependant Class(es):
  *    - MetadataService1
  *    
  * 6. Test Class Name: MetaDataMasterInfoListViewViaApi_Test
  * 
  * 7. Is @Invocable (Yes or No): Yes
  *
  * 8. Author Name(s): 
  *    - Vishwas Kumar Gupta (PWC) & Created Date(10/26/2023)
*************************************************************/ 
@isTest
public class MetaDataMasterInfoListViewViaApi_Test {
	 private class WebServiceMockImpl implements WebServiceMock  {   
      public void doInvoke(
            Object stub, Object request, Map<String, Object> response,
            String endpoint, String soapAction, String requestName,
            String responseNS, String responseName, String responseType) {
                if(request instanceof  MetadataService1.createMetadata_element) {
                     response.put('response_x', new MetadataService1.createMetadataResponse_element());
                }else if(request instanceof  MetadataService1.readMetadata_element) {
                     MetadataService1.Metadata mdInfo = new MetadataService1.Metadata();
                    mdInfo.fullName = 'Contact.RecentlyViewedContacts';
                    MetadataService1.ListView listview =new MetadataService1.ListView();
                    listView.fullName='Contact.RecentlyViewedContacts';
                    listView.label='Recently Viewed';
                    listView.filterScope='Everything';
                    listView.columns=new List<String> { 'NAME' };
                    listview.booleanFilter=null;
                    List<MetadataService1.ListViewFilter> filterlist= new List<MetadataService1.ListViewFilter>();
                    MetadataService1.ListViewFilter var_fltr= new MetadataService1.ListViewFilter();
                    var_fltr.operation='contain';
                    var_fltr.value='test';
                    var_fltr.field='NAME'; 
                    filterlist.add(var_fltr);
                    listView.filters=filterlist;
                   MetadataService1.ReadListViewResult res= new MetadataService1.ReadListViewResult();
                    res.records= new List<MetadataService1.ListView>{listview};
                    MetadataService1.IReadResult readResult = res;     
                 MetadataService1.readListViewResponse_element  finalresult=new  MetadataService1.readListViewResponse_element();
                   finalresult.result=res;  
                    response.put('response_x', finalresult);
                }
            }
     }
    static testMethod void testMethod0(){
          MetadataService1 metaDataService = new MetadataService1();
        Test.setMock(HttpCalloutMock.class, new RestRequestMockResponse());
        System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
         Test.startTest(); 
        MetaDataMasterInfoListViewViaApi.FlowInputs varInputClass= new MetaDataMasterInfoListViewViaApi.FlowInputs();
	varInputClass.ListviewfullName='Contact.RecentlyViewedContacts';
	MetaDataMasterInfoListViewViaApi.flowcalled(new list<MetaDataMasterInfoListViewViaApi.FlowInputs>{varInputClass});
     test.StopTest();
    }
      private class RestRequestMockResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {            
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');        
            res.setBody('{"body" : "dummyAPIResult"}');
            res.setStatusCode(200);
            return res;
        }
        }
}