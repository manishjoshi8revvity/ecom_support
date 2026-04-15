/**************************************************************
  * 1. Jira Ticket(s) that relates to Apex class "MetadataDeleteViaApi_scheduler"
  *    - OM-146 APEX to modify Metadata via API to for syncing of listview with Master_Info__c Object
  *
  * 2. Description - This apex class is used to sync Listview view with Master_Info__c Object
  * 3. Objects referenced
  *    -Master_Info__c
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    FetchLARMetadataAPI Class Methods will be  to Update and Create ListView 
  * 5. Dependant Class(es):
  *    - FetchLARMetadataAPI
  *    
  *
  * 6. Test Class Name: MetaDataListViewsyncViaApi_Test
  *
  * 7. Author Name(s): 
  *    - Vishwas Kumar Gupta (PWC) & Created Date(10/03/2023)
  *    - Vishwas & Aakash 2024.02.06 - changed INFO_TYPE to ComponentType picklist
*************************************************************/ 
global class MetaDataListViewsyncViaApi implements Database.Batchable<sObject>, database.stateful, Database.AllowsCallouts{
    public string callfor='masterinfo_to_lview';
    /*Created parameterized constructor to pass value and based on parameter masterinfo_to_lview/lview_to_masterinfo
     * parameter MasterInfo_To_LView for push operation
     * parameter lview_to_masterinfo for pull operation
     */
    public MetaDataListViewsyncViaApi(string inputparameter){
        callfor=inputparameter;
    }
    public Database.QueryLocator start(Database.BatchableContext BC){
        String queryString;
        if(callfor.toLowerCase()=='masterinfo_to_lview')
        queryString ='SELECT Id, ComponentType__c,DescriptionLong__c, API__c,external_key__c,Description__c, Name, Label__c, otherText__c, otherTextArea__c, otherTextLong__c, otherTextRich__c FROM MASTER_INFO__c where status__c=\'Master\' AND ComponentType__c=\'L.VIEW\'';
        else if(callfor.toLowerCase()=='lview_to_masterinfo' && !Test.isRunningTest())
        queryString ='SELECT Id,SobjectType, developerName from ListView Order by createddate DESC';
           else if(Test.isRunningTest() && callfor.toLowerCase()=='lview_to_masterinfo')
         queryString ='SELECT Id,SobjectType, developerName from ListView where SobjectType=\'Contact\' Order by createddate DESC limit 1';      
        return Database.getQueryLocator(queryString);
    }
    // Execute Method -- perfoem all operation on each batch of records...
	public void execute(Database.BatchableContext BC, List<Sobject> Scope){
        /* parameter masterinfo_to_lview decide push operation
         * parameter lview_to_masterinfo decide pull operation
         */
        if(callfor.toLowerCase()=='masterinfo_to_lview'){
        	FetchLARMetadataAPI.synclistview(Scope);
        }
        else if(callfor.toLowerCase()=='lview_to_masterinfo'){
            list<MetaDataMasterInfoListViewViaApi.FlowInputs> varinputlist= new list<MetaDataMasterInfoListViewViaApi.FlowInputs>();
            for(Sobject obj: Scope){
                MetaDataMasterInfoListViewViaApi.FlowInputs varInputClass= new MetaDataMasterInfoListViewViaApi.FlowInputs();
                varInputClass.ListviewfullName=obj.get('SobjectType')+'.'+obj.get('DeveloperName');
				varinputlist.add(varInputClass);
            }
             if(varinputlist != null && !varinputlist.isEmpty()){
                 MetaDataMasterInfoListViewViaApi.flowcalled(varinputlist);
            }
            
          }
            
    }
   public void finish(Database.BatchableContext BC){
        system.debug('finish');
    }	
}