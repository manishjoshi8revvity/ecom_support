/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *    - ATEAM-887
  *    - ITSFDC-####
  *
  * 2. Description - Put detailed description here of what this class is used for procedurally
  *    This will batch process users and populate/remove PSET User Settings based on the users assignment and
  *    the settings related to the PSET. The L.FLOW_9900 triggers this class.
  *    2021.05.20: Due to new SFDC Boundaries in bulk data (i.e. more than 200K records, the query needs to use selective fields that have been indexed)
  *    To allow for scenario where users have 50+ PSETs, we will size the array and process 30 PSETs at a time for a user to reduce limits
  *
  * 3. Objects referenced
  *    -PermissionSetAssignment 
  *    -PSET_User_Settings__c
  *    -PSETFieldMaster__c
  *    -PSET_Permission_Settings__c  
  *    -User__c
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None
  *   
  *
  * 5. Dependant Class(es):
  *    - None
  *    - L.FLOW_9900: Merge User Permissions
  *
  * 6. Test Class Name: PSET_Refresh_UserSettings_Test
  *
  * 7. Author Name(s): 
  *    - Vishwas Gupta 2021.05.17
  *    - First Last & Updated Date(YYYY.MM.DD)
  *    - First Last & Updated Date(YYYY.MM.DD)
  *
*************************************************************/ 
Public class PSET_Refresh_UserSettings implements Database.Batchable<sObject> {
	public final String varUserId;
	public Database.QueryLocator start(Database.BatchableContext BC){
        system.debug('varUserId'+varUserId);
        string Query;
        if(Test.isRunningTest()){
            Query ='SELECT Id, PermissionSetId, AssigneeId FROM PermissionSetAssignment where AssigneeId =:varUserId LIMIT 1';
      
        }else{
           Query ='SELECT Id, PermissionSetId, AssigneeId FROM PermissionSetAssignment where AssigneeId =:varUserId LIMIT 9999';
       
        }
		return Database.getQueryLocator(Query);
   }
   public void execute(Database.BatchableContext BC, List<PermissionSetAssignment> psaList) {
	   system.debug('psaList'+psaList);
        Set<string> NativePermissionSet = new Set<string>();
	   //We select the native Permission Set ID and Assignee ID
       //We need to split array size >30 to smaller batches of batchsize
        if(!psaList.isEmpty()){
            for(PermissionSetAssignment psa: psaList){
                NativePermissionSet.add(psa.PermissionSetId);
            } 
        }
        
        //this is call ed as part of the Loop for each batch of 30
        List<PSET_Permission_Settings__c>  ppsList = new  List<PSET_Permission_Settings__c>();        
        //Use the list of Permission Sets from above, we select the Settings for each permission set
        ppsList=[SELECT Id, fxPSETNativeID__c, Value__c ,PSETFieldMaster__c, Permission_Set__c FROM PSET_Permission_Settings__c where Value__c =true and fxPSETNativeID__c IN :NativePermissionSet];
        system.debug('ppsList size'+ppsList.size());
        set<string> keystring = new set<string>();
        map<string,PSET_User_Settings__c> keystringmap = new map<string,PSET_User_Settings__c>();
        
        
        //this is call ed as part of the Loop for each batch of 30
        List<PSET_User_Settings__c> pusList = new List<PSET_User_Settings__c>();
        //For each assignee(user), we ....
        pusList=  [SELECT Id, User__c, PSETFieldMaster__c, PSETPermissionSet__c FROM PSET_User_Settings__c where User__c=:varUserId];
        if(!pusList.isEmpty()){
            for(PSET_User_Settings__c pus:pusList){
                string keystr= string.valueof(pus.User__c)+string.valueof(pus.PSETPermissionSet__c)+string.valueof(pus.PSETFieldMaster__c);
                keystring.add(keystr);
                keystringmap.put(keystr,pus);
            }  
        }       
        list<PSET_User_Settings__c> pusListtoinsert = new list<PSET_User_Settings__c>();      
        if(!ppsList.isEmpty()){
            for(PSET_Permission_Settings__c pps:ppsList){
                string str =varUserId+string.valueof(pps.Permission_Set__c)+string.valueof(pps.PSETFieldMaster__c);
                if(!keystring.contains(str)){
                    PSET_User_Settings__c pus = new PSET_User_Settings__c();
                    pus.User__c=varUserId;
                    pus.PSETFieldMaster__c=pps.PSETFieldMaster__c;
                    pus.PSETPermissionSet__c=pps.Permission_Set__c;
                    pusListtoinsert.add(pus); 
                }
            }
        }
       if(!pusListtoinsert.isEmpty())
        insert pusListtoinsert;
        system.debug('pusListtoinsert size'+pusListtoinsert.size());
	   
   }
   public void finish(Database.BatchableContext BC) {
  }	
	Public class FlowInputs {         
        @InvocableVariable public String varUser;         
        @InvocableVariable public integer varBatchSize;     
    }
    public PSET_Refresh_UserSettings(string struserId){
		this.varUserId=struserId;
	}
	
	@InvocableMethod
    public static void flowcalled(List<FlowInputs> requests){
        string struserId;
		integer varBatchSizeUser;
		integer varBatchSizeDefault= 30;
        if(!requests.isEmpty()){
            struserId =requests[0].varUser;
            varBatchSizeUser=requests[0].varBatchSize;			
        }
		if(varBatchSizeUser == null)
			varBatchSizeUser=varBatchSizeDefault;
		//add variable for default size of batch here (i.e. 30)
        // if varBatchSizeUser is provided use varBatchSizeUser , else use varBatchSizeDefault
        if(!system.isBatch())
        Database.executeBatch(new PSET_Refresh_UserSettings(struserId), varBatchSizeUser);
       }
}