@isTest
public class MetaDataCountryStateSyncViaApi_Test {
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
                    MetadataService1.State st= new MetadataService1.state();
                    st.active=true;
                    st.isoCode='AL';
                    st.integrationValue='AL';
                    st.label='Alabama';
                     MetadataService1.State st2=New  MetadataService1.State();
                    st2.active=true;
                    st2.isoCode='NY';
                    st2.integrationValue='NY';
                    st2.label='New York';
                    MetadataService1.Country cnt= new MetadataService1.Country();
                    cnt.active=true;
                    cnt.isoCode='US';
                    cnt.integrationValue='US';
                    cnt.label='United state';
                    cnt.states=New List<MetaDataService1.State>{st,st2};
                    MetadataService1.CountriesAndStates cntr=new MetadataService1.CountriesAndStates();
                    cntr.countries=New List<MetadataService1.Country>{cnt};
                   MetadataService1.AddressSettings addr= new  MetadataService1.AddressSettings();
                    addr.type='AddressSettings';
                    addr.fullName='Address';
                    addr.countriesAndStates=cntr;
                 MetadataService1.ReadAddressSettingsResult res= new MetadataService1.ReadAddressSettingsResult();
                    res.records= new List<MetadataService1.AddressSettings>{addr};
                    MetadataService1.IReadResult readResult = res;     
                 MetadataService1.readAddressSettingsResponse_element  finalresult=new  MetadataService1.readAddressSettingsResponse_element();
                    finalresult.result=res; 
                    response.put('response_x', finalresult);
                
                }                                 
            }        
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
        MetaDataCountryStateSyncViaApi batchjob= new MetaDataCountryStateSyncViaApi();
        dataBase.executeBatch(batchjob, 10);
         Test.stopTest();
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