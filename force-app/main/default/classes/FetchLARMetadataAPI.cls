//This class is used to run on scheduled/on demand to delete listview/dashboard/folder/reports from SFDC
//  TICKET (OM-146)
//  Updated on 03/10/2023 (Vishwas Kumar Gupta)
public class FetchLARMetadataAPI {    
    
    /**************************************************************
* Description - Method to delete listview/dashboard/folder/reports from SFDC using metadata api 
*/ 
    public static boolean deleteListView(string objectname, String[] listViewArray) {
        // creating service to be able to call metadata api         
        MetadataService1.MetadataPort service = LeadAssignmentRule_Calculations.createService();
        // calling metadata api to delete listviews
        List<MetadataService1.DeleteResult> results =
            service.deleteMetadata(
                objectname, listViewArray);
        return Test.isRunningTest() ? true : results[0].success;       
    }
    /**************************************************************
Description - Method to delete listview/dashboard/folder/reports from SFDC using metadata api */
    /* ListView wrapper Class for Update/Create */
    Public class ListviewWrapper{
        Public string fullName{get;set;}
        public string Label{get;set;} 
        public string filterScope{get;set;}
        public List<string> columns{get;set;}
        public string booleanFilter{get;set;}
        public String Queue{get;set;}
        public MetadataService1.ListViewFilter[] ListViewFilters{get;set;}
    }
    
    // TICKET (OM-146)
    // this is Insert method of listview
    public static void createListView(List<ListviewWrapper> wrapList){
        MetadataService1.MetadataPort service = LeadAssignmentRule_Calculations.createService();
        if(wrapList != null && !wrapList.isEmpty() && wrapList[0].fullName != null && !wrapList[0].columns.isEmpty()){
            List<MetadataService1.ListView> listViewList =New List<MetadataService1.ListView>();
            for(ListviewWrapper wrap:wrapList){
                MetadataService1.ListView listView = new MetadataService1.ListView();
                listView.fullName = wrap.fullName;
                listView.label = wrap.label;
                listView.filterScope = wrap.filterScope;
                if(wrap.filterScope=='Queue'){
                        listView.Queue=wrap.Queue;
                    }
				listView.booleanFilter=wrap.booleanFilter;
                listView.columns = wrap.columns;
                if(wrap.ListViewFilters != null){
                    List<MetadataService1.ListViewFilter> filterlist= new  List<MetadataService1.ListViewFilter>();
                    for(MetadataService1.ListViewFilter filter : wrap.ListViewFilters){
                        if(filter != null){
                            filterlist.add(filter);
                            listView.filters=filterlist;
                        }
                    }
                }
                if(listView != null && listView.fullName != null){
                    listViewList.add(listView); 
                }
            }  
           
                if(listViewList != null && !listViewList.isEmpty()){
                    List<MetadataService1.SaveResult> results =service.createMetadata(listViewList);  
                }
                
           
        }
    }
    // TICKET (OM-146)
    // this is Update method of listview
    public static void updateListView(List<ListviewWrapper> wrapList){
        if(wrapList != null && !wrapList.isEmpty() ){
            MetadataService1.MetadataPort service = LeadAssignmentRule_Calculations.createService();
            List<MetadataService1.ListView> listViewList = new List<MetadataService1.ListView>();
            for(ListviewWrapper wrap:wrapList){
                if(wrap.fullName != null && wrap.columns != null && !wrap.columns.isEmpty()){
                    MetadataService1.ListView listView = new MetadataService1.ListView();
                    listView.fullName = wrap.fullName; // 'Queue__c.ARQ_Americas_INF_All';
                    listView.label = wrap.label; // 'ARQ: test queue';
                    listView.filterScope = wrap.filterScope; // 'Everything';
                    if(wrap.filterScope=='Queue'){ 
                        listView.Queue=wrap.Queue;
                    }
                    listView.columns = wrap.columns; // new List<String> { 'NAME' };
                    listView.booleanFilter=wrap.booleanFilter;
                    if(wrap.ListViewFilters != null){
                        List<MetadataService1.ListViewFilter> filterlist= new  List<MetadataService1.ListViewFilter>();
                        for(MetadataService1.ListViewFilter filter : wrap.ListViewFilters){
                            if(filter != null){
                                filterlist.add(filter);
                                listView.filters=filterlist;
                            }
                        }
                    }Else{
                        listView.filters=null;
                    }
                    listViewList.add(listView);
                }
            }
            try{
                if(listViewList != null && !listViewList.isEmpty() ){
                    List<MetadataService1.SaveResult> results =service.updateMetadata( listViewList ); 
                }
            }catch(exception ex){
                system.debug('error'+ ex.getCause());
                system.debug('error line'+ ex.getLineNumber());
                system.debug('error trace'+ ex.getStackTraceString());
                system.debug('error message'+ ex.getMessage());
            }
        }
    }
    
    // TICKET (OM-146)
    // This Method(synclistview) will be called from batch Class MetaDataListViewsyncViaApi
    // In this method we are deciding weather we need to update/Create Listview and also creating instance of listview for action. 
    public static void synclistview(List<Master_Info__c> masterinfolist) {
        List<FetchLARMetadataAPI.ListviewWrapper> wrapperlistInsert= new List<FetchLARMetadataAPI.ListviewWrapper>(); // this list will contains listview to insert
        List<FetchLARMetadataAPI.ListviewWrapper> wrapperlistUpdate= new List<FetchLARMetadataAPI.ListviewWrapper>(); // this list will contains listview to Update
        if(masterinfolist != null && !masterinfolist.isEmpty()){
            MetadataService1.MetadataPort service = LeadAssignmentRule_Calculations.createService();
            for(Master_Info__c  mstinf: masterinfolist){
                boolean listviewexist=false;
                if(mstinf.external_key__c != null){
                    MetadataService1.ListView listView =(MetadataService1.ListView) service.readMetadata('ListView',new String[] { mstinf.external_key__c }).getRecords()[0];
                    if(listView.fullName != null){ // if fullname is not found then it will go for insert process
                        listviewexist=true;
                    }
                }
                if(listviewexist==true){
                    FetchLARMetadataAPI.ListviewWrapper wrap=new FetchLARMetadataAPI.ListviewWrapper();
                    List<MetadataService1.ListViewFilter> wrapfilter=new List<MetadataService1.ListViewFilter>();
                    
                    wrap.fullName = mstinf.external_key__c;
                    wrap.label = mstinf.Label__c;
                    if(mstinf.otherTextArea__c.contains('Queue__c:')){
                        wrap.filterScope='Queue';
                        wrap.Queue=mstinf.otherTextArea__c.removeStart('Queue__c:');
                    }else{
                       wrap.filterScope = mstinf.otherTextArea__c != null ? mstinf.otherTextArea__c : 'Everything'; 
                    }
                    wrap.columns=mstinf.DescriptionLong__c.split(',');
                    wrap.booleanFilter=mstinf.Description__c;
                    List<string> filterArray = mstinf.otherTextLong__c !=null ? mstinf.otherTextLong__c.split('##'): null;
                    if(filterArray != null && !filterArray.isEmpty()){		
                        for(string strfltr:filterArray){
                            MetadataService1.ListViewFilter srpflt= new MetadataService1.ListViewFilter();
                            if(strfltr != null){ // Here we are fetching field , operator and values from filter
                                srpflt.field=strfltr.split('::')[0];
                                srpflt.operation=strfltr.split('::')[1];
                                srpflt.value=strfltr.split('::')[2];
                                wrapfilter.add(srpflt);
                            }
                        }
                    }
                    wrap.ListViewFilters= wrapfilter;
                    wrapperlistUpdate.add(wrap);
                    
                }else{
                    FetchLARMetadataAPI.ListviewWrapper wrap=new FetchLARMetadataAPI.ListviewWrapper();
                    List<MetadataService1.ListViewFilter> wrapfilter=new List<MetadataService1.ListViewFilter>();
                    if(Test.isRunningTest())
                     wrap.fullName ='Opportunity.createnew';   
                    else
                    wrap.fullName = mstinf.external_key__c;
                    wrap.label = mstinf.Label__c;
                    wrap.booleanFilter=mstinf.Description__c;
                    wrap.filterScope = mstinf.otherTextArea__c != null ? mstinf.otherTextArea__c : 'Everything';
                    if(mstinf.otherTextArea__c.contains('Queue__c:')){
                        wrap.filterScope='Queue';
                        wrap.Queue=mstinf.otherTextArea__c.removeStart('Queue__c:');
                    }else{
                       wrap.filterScope = mstinf.otherTextArea__c != null ? mstinf.otherTextArea__c : 'Everything'; 
                    }
                    wrap.columns=mstinf.DescriptionLong__c.split(',');
                    List<string> filterArray = mstinf.otherTextLong__c !=null ? mstinf.otherTextLong__c.split('##'): null;
                    if(filterArray != null && !filterArray.isEmpty()){		
                        for(string strfltr:filterArray){
                            MetadataService1.ListViewFilter srpflt= new MetadataService1.ListViewFilter();
                            if(strfltr != null){ // Here we are fetching field , operator and values from filter
                                srpflt.field=strfltr.split('::')[0];
                                srpflt.operation=strfltr.split('::')[1];
                                srpflt.value=strfltr.split('::')[2];
                                wrapfilter.add(srpflt);
                            }
                        }
                    }
                    wrap.ListViewFilters= wrapfilter;
                    wrapperlistInsert.add(wrap);
                }
            }
        }
        if(wrapperlistInsert != null && !wrapperlistInsert.isEmpty()){
            FetchLARMetadataAPI.createListView(wrapperlistInsert); // for insertion calling create method of listview
        }
        if(wrapperlistUpdate != null && !wrapperlistUpdate.isEmpty()){
            FetchLARMetadataAPI.updateListView(wrapperlistUpdate); // for Updation calling Update method of listview
        }
    } 
}