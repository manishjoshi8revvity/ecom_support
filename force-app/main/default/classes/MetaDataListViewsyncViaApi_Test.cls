/**************************************************************
  * 1. Jira Ticket(s) that relates to Apex class "MetadataDeleteViaApi_scheduler"
  *    - OM-146 APEX to modify Metadata via API to for syncing of listview with Master_Info__c Object
  *
  * 2. Description - Test Class for MetaDataListViewsyncViaApi
  * 
  * 3. Objects referenced 
  *    - Master_Info__c
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    FetchLARMetadataAPI Class Methods will be  to Update and Create ListView 
  * 
  * 5. Dependant Class(es):
  *    - FetchLARMetadataAPI
  *
  * 6. Test Class Name: MetaDataListViewsyncViaApi_Test
  *
  * 7. Author Name(s): 
  *    - Vishwas Kumar Gupta (PWC) & Created Date(10/03/2023)
*************************************************************/ 
@isTest
public class MetaDataListViewsyncViaApi_Test {
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
       List<Listview> listViewlist=[SELECT Id, DeveloperName, SobjectType, LastModifiedDate FROM ListView Where SobjectType = 'Account' Order by LastModifiedDate DESC limit 1];
        MetadataService1 metaDataService = new MetadataService1();
        Test.setMock(HttpCalloutMock.class, new RestRequestMockResponse());
        System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        List<FetchLARMetadataAPI.ListviewWrapper> wrapperlist= new List<FetchLARMetadataAPI.ListviewWrapper>();
        FetchLARMetadataAPI.ListviewWrapper wrap=new FetchLARMetadataAPI.ListviewWrapper();
        List<MetadataService1.ListViewFilter> wrapfilter=new List<MetadataService1.ListViewFilter>();
        MetadataService1.ListViewFilter srpflt= new MetadataService1.ListViewFilter();
        wrap.fullName = listViewlist[0].SobjectType+listViewlist[0].DeveloperName;
        wrap.label = 'testing';
        wrap.filterScope = 'Everything';
        wrap.columns=New List<string>{'NAME'};
               srpflt.field='NAME';
        srpflt.operation='contains';
        srpflt.value='AMER';
        wrapfilter.add(srpflt);
        wrap.ListViewFilters= wrapfilter;
        wrapperlist.add(wrap);
        test.startTest();
       // FetchLARMetadataAPI.ReadListView(wrapperlist);
        FetchLARMetadataAPI.updateListView(wrapperlist);
        test.stopTest();
    }
     static testMethod void testMethodsync(){
         MASTER_INFO__c MstrInfo1= new MASTER_INFO__c();
        MstrInfo1.ComponentType__c='L.VIEW';
        MstrInfo1.API__c='Queue__c.donotexist';
        MstrInfo1.Name='Queue__c.donotexist';
        MstrInfo1.Label__c='donotexist';
        mstrInfo1.external_key__c='Queue__c.donotexist';
        MstrInfo1.otherTextArea__c='Mine';
        MstrInfo1.DescriptionLong__c='NAME';
        Insert MstrInfo1;
        MASTER_INFO__c MstrInfo= new MASTER_INFO__c();
        MstrInfo.ComponentType__c='L.VIEW';
        MstrInfo.API__c='Queue__c.testing_dynamic_listview';
        MstrInfo.Name='Queue__c.testing_dynamic_listview';
        MstrInfo.Label__c='testing dynamic listview';
        mstrInfo.external_key__c=null;
        MstrInfo.DescriptionLong__c='NAME';
        MstrInfo.otherTextArea__c='Mine';
        MstrInfo.otherTextLong__c='NAME::contains::AMER';
        Insert MstrInfo;
        MetadataService1 metaDataService = new MetadataService1();
        Test.setMock(HttpCalloutMock.class, new RestRequestMockResponse());
        System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        
        test.startTest();
      //  FetchLARMetadataAPI.ReadListView(wrapperlist);
         FetchLARMetadataAPI.synclistview(New List<master_info__c>{MstrInfo,MstrInfo1});
        test.stopTest();
    }
    static testMethod void testMethod1(){
        MASTER_INFO__c MstrInfo= new MASTER_INFO__c();
        MstrInfo.ComponentType__c='L.VIEW';
        MstrInfo.API__c='Queue__c.testing_dynamic_listview';
        MstrInfo.Name='Queue__c.testing_dynamic_listview';
        MstrInfo.Label__c='testing dynamic listview';
        MstrInfo.DescriptionLong__c='NAME::contains::AMER';
        MstrInfo.otherText__c='Mine';
        MstrInfo.otherTextArea__c='NAME';
        Insert MstrInfo;
        MetadataService1 metaDataService = new MetadataService1();
        Test.setMock(HttpCalloutMock.class, new RestRequestMockResponse());
        System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        List<FetchLARMetadataAPI.ListviewWrapper> wrapperlist= new List<FetchLARMetadataAPI.ListviewWrapper>();
        FetchLARMetadataAPI.ListviewWrapper wrap=new FetchLARMetadataAPI.ListviewWrapper();
        List<MetadataService1.ListViewFilter> wrapfilter=new List<MetadataService1.ListViewFilter>();
        MetadataService1.ListViewFilter srpflt= new MetadataService1.ListViewFilter();
        wrap.fullName = 'Queue__c.testing_dynamic_listview2';
        wrap.label = 'testing_dynamic_listview2';
        wrap.filterScope = 'Everything';
        wrap.columns=New List<string>{'NAME'};
            srpflt.field='NAME';
        srpflt.operation='contains';
        srpflt.value='AMER';
        wrapfilter.add(srpflt);
        wrap.ListViewFilters= wrapfilter;
        wrapperlist.add(wrap);
        test.startTest();
      //  FetchLARMetadataAPI.ReadListView(wrapperlist);
        FetchLARMetadataAPI.createListView(wrapperlist);
        test.stopTest();
    }
     static testMethod void testMethod2(){
        MASTER_INFO__c MstrInfo= new MASTER_INFO__c();
        MstrInfo.ComponentType__c='L.VIEW';
       //  INFO_TYPE__c
        MstrInfo.API__c='Queue__c.testing_dynamic_listview';
        MstrInfo.Name='L.VIEW: Queue__c.testing_dynamic_listview';
        MstrInfo.Label__c='testing dynamic listview';
        MstrInfo.DescriptionLong__c='NAME::contains::AMER';
        MstrInfo.otherText__c='Mine';
        MstrInfo.otherTextArea__c='NAME';
        Insert MstrInfo;
        MetadataService1 metaDataService = new MetadataService1();
        Test.setMock(HttpCalloutMock.class, new RestRequestMockResponse());
        System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
         Test.startTest();
         MetaDataListViewsyncViaApi batchjob= new MetaDataListViewsyncViaApi('MasterInfo_To_LView');
        
        dataBase.executeBatch(batchjob, 10);
        Test.stopTest();
    }
     static testMethod void testMethod3(){
        MASTER_INFO__c MstrInfo= new MASTER_INFO__c();
        MstrInfo.ComponentType__c='L.VIEW';
       //  INFO_TYPE__c
        MstrInfo.API__c='Contact.RecentlyViewedContacts';
        MstrInfo.Name='L.VIEW: Contact.RecentlyViewedContacts';
        MstrInfo.Label__c='RecentlyViewedContacts';
        MstrInfo.DescriptionLong__c='NAME::contains::AMER';
        MstrInfo.otherText__c='Mine';
        MstrInfo.otherTextArea__c='NAME';
        Insert MstrInfo;
          MetadataService1 metaDataService = new MetadataService1();
        Test.setMock(HttpCalloutMock.class, new RestRequestMockResponse());
        System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
         Test.startTest(); 
     	 MetaDataListViewsyncViaApi batchjob= new MetaDataListViewsyncViaApi('LView_To_MasterInfo');
         dataBase.executeBatch(batchjob, 1);
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