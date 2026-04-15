@isTest
public class MetaDataGPickSyncViaApi_Test {
        private class WebServiceMockImpl implements WebServiceMock  {   
      public void doInvoke(
            Object stub, Object request, Map<String, Object> response,
            String endpoint, String soapAction, String requestName,
            String responseNS, String responseName, String responseType) {
                if(request instanceof  MetadataService1.createMetadata_element) {
                     response.put('response_x', new MetadataService1.createMetadataResponse_element());
                }else if(request instanceof  MetadataService1.readMetadata_element) {
                     MetadataService1.Metadata mdInfo = new MetadataService1.Metadata();
                    mdInfo.fullName = 'Test'; 
                  MetadataService1.CustomValue var_cnt =new MetadataService1.CustomValue();
                    var_cnt.fullName='test';
                    var_cnt.label='test United State';
                    var_cnt.isActive=true;
                    var_cnt.color=null;
        			var_cnt.default_x=false;
            		var_cnt.description=null;
				MetadataService1.CustomValue var_cnt1 =new MetadataService1.CustomValue();
                    var_cnt1.fullName='test2';
                    var_cnt1.label='test2 United State';
                    var_cnt1.isActive=true;
                    var_cnt1.color=null;
        			var_cnt1.default_x=false;
            		var_cnt1.description=null;					
                   MetadataService1.GlobalValueSet var_GlobalValueSet= new  MetadataService1.GlobalValueSet();
                    var_GlobalValueSet.type='GlobalValueSet';
                    var_GlobalValueSet.fullName='G_PICK_028_Country__gvs';
                    var_GlobalValueSet.customValue=new List<MetadataService1.CustomValue>{var_cnt,var_cnt1};
                 MetadataService1.ReadGlobalValueSetResult res= new MetadataService1.ReadGlobalValueSetResult();
                    res.records= new List<MetadataService1.GlobalValueSet>{var_GlobalValueSet};
                    MetadataService1.IReadResult readResult = res;     
                 MetadataService1.readGlobalValueSetResponse_element  finalresult=new  MetadataService1.readGlobalValueSetResponse_element();
                   finalresult.result=res;  
                    response.put('response_x', finalresult);
                }                                 
            } 
        }
            static testMethod void testMethod2(){
            Country__c cntr= new Country__c();
            cntr.Name='United State';
            cntr.Country_ISO_Alpha_2__c='US';
            cntr.SFDC_Country_Name__c='United State';
            cntr.Global_Territory__c='AMERICAS';
            cntr.Sub_Territory__c='CARIBBEAN';
            cntr.Super_Territory__c='AMERICAS';
            cntr.Territory__c='NORTH AMERICA';
            insert cntr;
            state__c st=New State__c();
            st.name='New York';
            st.Country__c=cntr.Id;
            st.integrationValue__c='NY';
            st.ISOCode__c='NY';
            st.SFDC_State_Name__c='New York';
            insert st;
             MetadataService1 metaDataService = new MetadataService1();
        Test.setMock(HttpCalloutMock.class, new RestRequestMockResponse());
        System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
         Test.startTest(); 
                string gpickName='G_PICK_028_Country';
                List<MetaDataGPickSyncViaApi.wrapper> wraplist= new List<MetaDataGPickSyncViaApi.wrapper>();
                MetaDataGPickSyncViaApi.wrapper wrap= new MetaDataGPickSyncViaApi.wrapper();
                wrap.label='United Sates';
                wrap.fullName='US';
                wrap.isActive=true;
                wraplist.add(wrap);
		MetaDataGPickSyncViaApi.syncGlobalValueSet(gpickName,wraplist);
		Test.StopTest();
        
        }
     static testMethod void testMethod1(){
            Country__c cntr= new Country__c();
            cntr.Name='United State';
            cntr.Country_ISO_Alpha_2__c='US';
            cntr.SFDC_Country_Name__c='United State';
            cntr.Global_Territory__c='AMERICAS';
            cntr.Sub_Territory__c='CARIBBEAN';
            cntr.Super_Territory__c='AMERICAS';
            cntr.Territory__c='NORTH AMERICA';
            insert cntr;
            state__c st=New State__c();
            st.name='New York';
            st.Country__c=cntr.Id;
            st.integrationValue__c='NY';
            st.ISOCode__c='NY';
            st.SFDC_State_Name__c='New York';
            insert st;
             MetadataService1 metaDataService = new MetadataService1();
        Test.setMock(HttpCalloutMock.class, new RestRequestMockResponse());
        System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
         Test.startTest(); 
     MetaDataGPickSyncViaApi.FlowInputs varInputClass= new MetaDataGPickSyncViaApi.FlowInputs();
     varInputClass.globalpicklistName='G_PICK_029_state';
     MetaDataGPickSyncViaApi.flowcalled(new list<MetaDataGPickSyncViaApi.FlowInputs>{varInputClass});
		Test.StopTest();
        
        }
        static testMethod void testMethod0(){
            Country__c cntr= new Country__c();
            cntr.Name='United State';
            cntr.Country_ISO_Alpha_2__c='US';
            cntr.SFDC_Country_Name__c='United State';
            cntr.Global_Territory__c='AMERICAS';
            cntr.Sub_Territory__c='CARIBBEAN';
            cntr.Super_Territory__c='AMERICAS';
            cntr.Territory__c='NORTH AMERICA';
            insert cntr;
            state__c st=New State__c();
            st.name='New York';
            st.Country__c=cntr.Id;
            st.integrationValue__c='NY';
            st.ISOCode__c='NY';
            st.SFDC_State_Name__c='New York';
            insert st;
             MetadataService1 metaDataService = new MetadataService1();
        Test.setMock(HttpCalloutMock.class, new RestRequestMockResponse());
        System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
         Test.startTest(); 
     MetaDataGPickSyncViaApi.FlowInputs varInputClass= new MetaDataGPickSyncViaApi.FlowInputs();
     varInputClass.globalpicklistName='G_PICK_028_Country';
     MetaDataGPickSyncViaApi.flowcalled(new list<MetaDataGPickSyncViaApi.FlowInputs>{varInputClass});
		Test.StopTest();
        
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