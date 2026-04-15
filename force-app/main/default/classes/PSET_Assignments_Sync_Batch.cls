/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *    - ATEAM-260
  *    - ATEAM-1782
  *
  * 2. Description:   PSET_Assignments_Sync_Batch    batch class will replace  PSET_SyncAssignmentWithNative
       From this we are to sync with PermissionSetAssignment
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
  *    - Vishwas Gupta 2021.05.24
  *    - First Last & Updated Date(YYYY.MM.DD)
  *
*************************************************************/ 
global class PSET_Assignments_Sync_Batch implements Database.Batchable<sObject>,Schedulable, Database.Stateful {
 global map<string,string> mapKeypsa;
// global set<string> setKeypsaCustom;
  global  set<string> PSA;
    global set<string> PS;
   /* global PSET_Assignments_Sync_Batch(){} */
    global PSET_Assignments_Sync_Batch(set<string> setKeypsa,set<string> setPS){
        if(setKeypsa != null && !setKeypsa.isEmpty()){
            PSA = new set<string>();
           PSA= setKeypsa;
        }
        if(setPS != null && !setPS.isEmpty()){
            PS = new set<string>();
           PS= setPS;
        }
    }
global Database.QueryLocator start(Database.BatchableContext bc) {
    system.debug('PSA size'+PSA.size());
    
   string query = 'SELECT ID,ExternalId__c, Name,fxStatus__c, Permission_Set__c, Assignee__c,CreatedDate,Provisioned_Time__c,Reprovisioned_Time__c,Deprovisioned_Time__c';
                    query +=' FROM PSET_Permission_Set_Assignment__c  WHERE ' ;
                    query +='ExternalId__c !=null';
                    query+=' AND ((ExternalId__c NOT IN:PSA AND fxStatus__c=\'Active\') OR (ExternalId__c IN:PSA AND fxStatus__c=\'Inactive\'))';
                      
                    
           return Database.getQueryLocator(query);
}
global void execute(Database.BatchableContext bc, List<PSET_Permission_Set_Assignment__c> scope){
    list<PSET_Permission_Set_Assignment__c> PSETpsa = new list<PSET_Permission_Set_Assignment__c>();
    list<PermissionSetAssignment> nativePermissionSetAssignmentList = new list<PermissionSetAssignment>();
    set<String> assignIDs= new set<String>(); 
    if(scope != null){
        for(PSET_Permission_Set_Assignment__c CustomPsa: scope){
            if(CustomPsa.Assignee__c != null)
            assignIDs.add(CustomPsa.Assignee__c);
        }
    }
    system.debug('assignIDs=>'+assignIDs);
    Map<string,PermissionSetAssignment> mapPSA = new Map<string,PermissionSetAssignment>();
       nativePermissionSetAssignmentList=[SELECT id,PermissionSetId, AssigneeId,SystemModstamp  FROM PermissionSetAssignment  Where AssigneeId IN:assignIDs];
    if(mapKeypsa == null){
        mapKeypsa = new map<string,string>();
     }
    if(nativePermissionSetAssignmentList != null){
        for(PermissionSetAssignment psa:nativePermissionSetAssignmentList){
            string keyvalue=string.valueof(psa.PermissionSetId) + string.valueof(psa.AssigneeId);
            mapKeypsa.put(keyvalue,string.valueof(psa.PermissionSetId));
            mapPSA.put(keyvalue,psa);
            
        }
    }
    system.debug('mapKeypsa=60>'+mapKeypsa);
    if(scope != null && mapKeypsa != null && mapKeypsa.keySet() != null){
        for(PSET_Permission_Set_Assignment__c CustomPsa: scope){
            if(CustomPsa.provisioned_Time__c ==null){
               CustomPsa.provisioned_Time__c= CustomPsa.CreatedDate;
            }
            if(!mapKeypsa.containsKey(CustomPsa.ExternalId__c) && CustomPsa.fxStatus__c=='Active'){
               // CustomPsa.DeletedTimestamp__c=datetime.now();
                  CustomPsa.Deprovisioned_Time__c=datetime.now(); //This statys as SystemTime Now
                PSETpsa.add(CustomPsa);
            }else if(mapKeypsa.containsKey(CustomPsa.ExternalId__c) && CustomPsa.fxStatus__c=='Inactive'){
                CustomPsa.Reprovisioned_Time__c= mapPSA.get(CustomPsa.ExternalId__c).SystemModstamp ;//This should be SystemModstamp as ET
                PSETpsa.add(CustomPsa);
            }
          /*  if(setKeypsaCustom == null){
               setKeypsaCustom = new set<string>();
                    setKeypsaCustom.add(CustomPsa.ExternalId__c);
                }else{
                    setKeypsaCustom.add(CustomPsa.ExternalId__c);
                } */
                           
        }
    }
    system.debug('PSETpsa'+PSETpsa);
   Database.SaveResult[] drList = Database.Update(PSETpsa, false);
 
// Iterate through each returned result
for(Database.SaveResult dr : drList) {
    if (dr.isSuccess()) {
        // Operation was successful, so get the ID of the record that was processed
        System.debug('Successfully Updated PSET PermissionSet Assignment with ID: ' + dr.getId());
    }
    else {
        // Operation failed, so get all errors                
        for(Database.Error err : dr.getErrors()) {
            System.debug('The following error has occurred.');                    
            System.debug(err.getStatusCode() + ': ' + err.getMessage());
            System.debug('Account fields that affected this error: ' + err.getFields());
        }
    }
} 
}
 global void finish(Database.BatchableContext bc){
     List<string> pSetIdList = new list<string>();
   /*  if(mapKeypsa != null && mapKeypsa.keyset().size()>0){
         for(string nPSA: mapKeypsa.keyset()){
             if(!setKeypsaCustom.contains(nPSA)){
               pSetIdList.add(mapKeypsa.get(nPSA));  
             }
         }  
     } */
     if(PS != null && !PS.isEmpty()){
         pSetIdList.addAll(PS);
     }
     system.debug('pSetIdList===line 129'+pSetIdList);
String pSetIdListQuery = '\''+String.join(pSetIdList,'\',\'')+'\'';
      PSET_Settings__c settings = PSET_Settings__c.getOrgDefaults(); 
     List<string> AllowedLicenseType =settings.AllowedLicenseType__c != null ? settings.AllowedLicenseType__c.split(',') : New List<string>();
String permissionAssignmentQuery = 'Select PermissionSetId, AssigneeId,SystemModstamp From PermissionSetAssignment Where Assignee.License_Type__c IN:AllowedLicenseType AND Assignee.Name !=null AND PermissionSetId IN ('+ pSetIdListQuery +')';
system.debug('pSetIdListQuery=='+pSetIdListQuery+'permissionAssignmentQuery==' +permissionAssignmentQuery +'pSetIdList=='+pSetIdList);
     if(!Test.isRunningTest() && pSetIdListQuery != null && pSetIdListQuery !=''){
         Database.executeBatch(new PSET_PermissionSettings_Copy_Batch(permissionAssignmentQuery, 'PermissionSetAssignment', pSetIdList));
     }

        AsyncApexJob jobs = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email from AsyncApexJob where Id =:BC.getJobId()];
        if(jobs != null){
            //Send mail on success
            String mailBody;
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {jobs.CreatedBy.Email};
            mailBody = '<html><body>The batch Apex job has been processed<br/> No. of batches processed '+jobs.TotalJobItems +'<br/> No. of Errors '+jobs.NumberOfErrors +'</body></html>';
            mail.setToAddresses(toAddresses);
            mail.setSubject('Batch Apex to Sync Permission Set Assignment is ' + jobs.Status);            
            mail.setHtmlBody(mailBody);
            //Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });  
        }
    } 
    global void execute(SchedulableContext SC) {
    PSET_Assignments_Sync_Batch SCDF = new PSET_Assignments_Sync_Batch(PSA,PS);
    Database.ExecuteBatch(SCDF,200);
    }
}