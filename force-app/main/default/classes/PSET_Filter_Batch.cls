/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *    -  ATEAM-1782
  *
  * 2. Description:   PSET_Filter_Batch
       From this we are providing list of native permissionsetAssignment and list of permissionset for which provission is required(going to insert)
       and from there onward it will take changes and process rest of permission changes
  * 3. Objects referenced
  *    -PermissionSetAssignment
  *    -PSET_Permission_set_Assignment__c
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None
  *
  * 5. Dependant Class(es):
  *    - PSET_PermissionSettings_Copy_Batch
  *
  * 6. Test Class Name: PSET_Assignments_Sync_Batch_Test
  *
  * 7. Author Name(s): 
  *    - Vishwas Gupta 2022.09.01
  *
*************************************************************/ 
Global class PSET_Filter_Batch implements Database.Batchable<sObject>,Schedulable, Database.Stateful {
     Global set<string> setKeypsa; 
     Global set<string> setProvissionps; 
    Global Database.QueryLocator start(Database.BatchableContext bc) {
        string userIdstr=userinfo.getUserId();
        String query; 
        if(!test.isRunningTest())
         query='SELECT PermissionSetId, AssigneeId, Id FROM PermissionSetAssignment Order by AssigneeId';
        else
           query='SELECT PermissionSetId, AssigneeId, Id FROM PermissionSetAssignment Where AssigneeId =:userIdstr Order by SystemModstamp DESC limit 200';   
      return Database.getQueryLocator(query); 
    }
    
    Global void execute(Database.BatchableContext bc, List<PermissionSetAssignment> scope){
        system.debug('scope=='+scope);
        map<string,string> keystringsPS= new  map<string,string>();
        if(setKeypsa ==null){
            setKeypsa= new set<string>();
        }
        if(setProvissionps ==null){
            setProvissionps= new set<string>();
        }
        if(scope != null && !scope.isEMpty()){
            for(PermissionSetAssignment psa: scope){
                string keyvalue=string.valueof(psa.PermissionSetId) + string.valueof(psa.AssigneeId);
                setKeypsa.add(keyvalue); // preparing list of assignment key
                keystringsPS.put(keyvalue,psa.PermissionSetId);
            }
        }
    list<PSET_Permission_Set_Assignment__c> cPSAList=    [Select id,Permission_Set__c, Assignee__c,ExternalId__c from PSET_Permission_Set_Assignment__c Where ExternalId__c IN:keystringsPS.keySet()];
       
        for(PSET_Permission_Set_Assignment__c cpa:cPSAList){
            if(keystringsPS.containsKey(cpa.ExternalId__c)){
                keystringsPS.remove(cpa.ExternalId__c);   
            }
        }
        if(keystringsPS != null && !keystringsPS.keyset().isEmpty()){
           setProvissionps.addAll(keystringsPS.values()); // creating list of permissionset , for which permissionsetassingment going to create (provission)
        } 
    }
    Global void finish(Database.BatchableContext bc){
        if(!test.isRunningTest())
     Database.executeBatch(new PSET_Assignments_Sync_Batch(setKeypsa,setProvissionps) ,50); // calling PSET_Assignments_Sync_Batch with assignment key and list of permissionset for which provission is going to happen(Provission)
     }
    global void execute(SchedulableContext SC) {
    PSET_Filter_Batch SCDF = new PSET_Filter_Batch();
    Database.ExecuteBatch(SCDF,200);
    }
}