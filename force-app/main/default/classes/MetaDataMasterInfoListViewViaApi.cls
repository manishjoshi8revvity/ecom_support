/**************************************************************
* 1. Jira Ticket(s)
*    - OM-213 APEX to Upsert ListView config to Master_Info__c
*
* 2. Description - This apex class is used to Upsert ListView config to Master_Info__c
* 3. Objects referenced
*    -Master_Info__c
*
* 4. Callouts to additional Components (including their methods) or None:
*    MetaDataMasterInfoListViewViaApi
* 5. Dependant Class(es):
*    - MetadataService1
*    
*
* 6. Test Class Name: MetaDataMasterInfoListViewViaApi_Test
* 
* 7. Is @Invocable (Yes or No): Yes
*
* 8. Author Name(s): 
*    - Vishwas Kumar Gupta (PWC) & Created Date(10/26/2023)
*    - Brad Durbin 2023.11.11 - changed INFO_TYPE to ComponentType picklist
*    -Vishwas 2024.02.12 changed input paramter to Handle Push/Pull for listView from Master Info
*************************************************************/ 
public class MetaDataMasterInfoListViewViaApi {
    Public class FlowInputs { 
        @InvocableVariable( description='Pass "full Name" of ListView , LIKE "sobjectType.developerName"')
        public String ListviewfullName;
        @InvocableVariable( description='Pass "push" as string, if looking to push master info to listview')
        public String PushToListView;
        @InvocableVariable( description='Pass "Master Info" sobject, if looking to push master info to listview')
        public Sobject MasterInfo; 
    }
    
    @InvocableMethod
    public static void flowcalled(List<FlowInputs> requests){
        
        if(requests != null && !requests.isEmpty()){
            List<string> fullNameList= New List<string>();
            List<sobject> var_MasterInfo= new List<sobject>();
               /* creating Parameters for push/pull from Master info to listview
                */
            for(FlowInputs var_input:requests){
                if(var_input != null && var_input.PushToListView != null && var_input.PushToListView.toLowerCase()=='push' && var_input.MasterInfo != null){
                    var_MasterInfo.add(var_input.MasterInfo);
                    
                }else if(var_input != null && var_input.ListviewfullName != null){ 
                    fullNameList.add(var_input.ListviewfullName);
                }
                
            }
            /* this will call Batch class to push Changes from Master info to listview
             * parameter as list<Master_info__c>
             */ 
            if(var_MasterInfo != null && !var_MasterInfo.isEmpty()){
                FetchLARMetadataAPI.synclistview((list<Master_info__c>)var_MasterInfo);  
            }
            /* Below block of code will Pull changes/Create Master info of ListView
             * parameter as List<string> // collection of fullName(Sobject.developerName) of ListView
             */
            if(fullNameList != null && !fullNameList.isEmpty()){
                MetadataService1.MetadataPort service = LeadAssignmentRule_Calculations.createService(); 
                List<MetadataService1.ListView> listViewList;
                listViewList =(List<MetadataService1.ListView>) service.readMetadata('ListView',fullNameList).getRecords();
                List<MASTER_INFO__c> var_mstinfoList= new List<MASTER_INFO__c>();
                if(listViewList != null && !listViewList.isEmpty() ){
                    for(MetadataService1.ListView listView: listViewList){
                        if(listView != null && listView.fullName != null){
                            MASTER_INFO__c var_mstinf= new MASTER_INFO__c();
                            var_mstinf.ComponentType__c='L.VIEW';
                            var_mstinf.API__c=listView.fullName;  // 'Queue__c.ARQ_Americas_INF_All';
                            var_mstinf.External_Key__c=listView.fullName;
                            var_mstinf.Label__c=listView.label; // 'ARQ: test queue';
                            var_mstinf.otherTextArea__c=listView.filterScope; // 'Everything';
                            if(listView.filterScope=='Queue'){
                                var_mstinf.otherTextArea__c= 'Queue__c:'+listView.Queue;
                            }
                            if(listView.columns != null && !listView.columns.isEmpty())
                            var_mstinf.DescriptionLong__c=String.join(listView.columns,','); // new List<String> { 'NAME' };
                            else
                              var_mstinf.DescriptionLong__c='NAME';  
                            var_mstinf.Description__c=listview.booleanFilter;
                            List<string> var_filterList= new List<string>();
                            if(listView.filters != null && !listView.filters.isEmpty()){
                                for(MetadataService1.ListViewFilter var_filter: listView.filters){
                                    var_filterList.add(var_filter.field + '::' + var_filter.operation + '::' + var_filter.value);
                                }            
                            }
                            var_mstinf.otherTextLong__c=String.join(var_filterList,'##');
                            var_mstinfoList.add(var_mstinf);
                        }
                    }
                    if(var_mstinfoList != null && !var_mstinfoList.isEmpty())
                        Upsert var_mstinfoList external_key__c;
                }
            }
        }
    }
}