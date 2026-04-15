/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *    - ATEAM-260
  *    - ITSFDC-####
  *
  * 2. Description -From this batch class we are upserting ObjectPermissions,FieldPermissions,PermissionSetAssignment and PermissionSettings
  *                we are also inserting PSET_Permission_Set_History__c for all setting
  * 3. Objects referenced
  *    -PSET_Permission_Set__c
  *    -PermissionSetAssignment
  *    -ObjectPermissions
  *    -FieldPermissions
  *    -PSET_Object_Permissions__c
  *    -PSET_Field_Permissions__c 
  *    -PSET_Permission_set_Assignment__c
  *    -PSET_Permission_Settings__c  
  *    -PSET_Permission_Set_History__c
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None
  *   
  *
  * 5. Dependant Class(es):
  *    - None
  *
  * 6. Test Class Name: PSET_PermissionSets_Copy_Batch_Test
  *
  * 7. Author Name(s): 
  *    - Vishwas Gupta 2021.05.24
  *    - First Last & Updated Date(YYYY.MM.DD)
  *    - First Last & Updated Date(YYYY.MM.DD)
  *
*************************************************************/ 
public class PSET_PermissionSettings_Copy_Batch implements Database.Batchable<SObject>,Database.Stateful {
    
    private String query;
    private  List<string> AllowedLicenseType;
    private String sObjectType;
    private Map<String, Id> pSetMap;
    private List<String> fieldNames;
    private List<Id> pSetIdList;
    private Map<String,Boolean> currentPermissionSettingsMap;
    private set<string> ParentIds;
    
    // Method to get all the standard Permission set IDs and its associated custom permission set ID to map  
    // and store all the related objects using the custom PSET ID.
    private void getAllPermissionSetIds(){
        String permissionSetQuery = 'SELECT Id, PermissionSetId_FromStandard__c FROM PSET_Permission_Set__c Where PermissionSetId_FromStandard__c IN ('+ '\''+String.join(pSetIdList,'\',\'')+'\'' +')';
        List<PSET_Permission_Set__c> pSets = Database.query(permissionSetQuery);
        pSetMap = new Map<String, Id>();
        for (PSET_Permission_Set__c pSet : pSets) {
            pSetMap.put(pSet.PermissionSetId_FromStandard__c, pSet.Id);
        }
    }
    
    public PSET_PermissionSettings_Copy_Batch(String query, String sObjectType, List<Id> pSetIdList) {
        this.query = query;
        this.sObjectType = sObjectType;
        if(sObjectType=='PermissionSetAssignment'){
           PSET_Settings__c settings = PSET_Settings__c.getOrgDefaults(); 
     this.AllowedLicenseType =settings.AllowedLicenseType__c != null ? settings.AllowedLicenseType__c.split(',') : New List<string>(); 
        }
        this.pSetIdList = pSetIdList;
        getAllPermissionSetIds();
    }
    // This constructor has an additional param fieldNames 
    // to get all the permission field names from the permission set.
    public PSET_PermissionSettings_Copy_Batch(String query, String sObjectType, List<Id> pSetIdList, List<String> fieldNames) {
        this.query = query;
        this.sObjectType = sObjectType;
        this.pSetIdList = pSetIdList;
        this.fieldNames = fieldNames;
        getAllPermissionSetIds();
    }
    
    /*
    // Future - To be modified when bringing in permission set history
    // Method to read all the custom permission settings of the modified permission set 
    // to check if the values are updated.
    // This is yet to be coded to include only the modified permission sets(add where clause)
    */
    private void getCurrentPermissionSettings(){
        list<ID> CustomPermisionsetIds = pSetMap.values();
        String pSetIdquery = '\''+String.join(CustomPermisionsetIds,'\',\'')+'\'';
        String currentPermissionSetQuery = 'SELECT ExternalId__c, Value__c,Permission_Set__c FROM PSET_Permission_Settings__c Where Permission_Set__c IN ('+ pSetIdquery +') order by LastModifiedDate asc limit 49999';
        List<PSET_Permission_Settings__c> pSets = Database.query(currentPermissionSetQuery);
        currentPermissionSettingsMap = new Map<String,Boolean>();
        for (PSET_Permission_Settings__c pSet : pSets) {
            currentPermissionSettingsMap.put(pSet.ExternalId__c, pSet.Value__c);
        }
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug('query string'+this.query);
        return  Database.getQueryLocator(this.query);
    }
    
    public void execute(Database.BatchableContext BC, List<SObject> sObjectsFromStart){
        switch on this.sObjectType {
            // Copy the object permissions data
            when 'ObjectPermissions' {
                if(ParentIds ==null){
                parentIds= new set<string>();
                }
                List<PSET_Object_Permissions__c> lstCustomObjPermission = new List<PSET_Object_Permissions__c>();
                for (ObjectPermissions objPermission : (List<ObjectPermissions>)sObjectsFromStart){
                    PSET_Object_Permissions__c customObjPermission = new PSET_Object_Permissions__c();
                    customObjPermission.Permission_Set__c = pSetMap.get(objPermission.ParentId);
                    customObjPermission.Object_Name__c = objPermission.SobjectType;
                    customObjPermission.Create__c = objPermission.PermissionsCreate;
                    customObjPermission.Delete__c = objPermission.PermissionsDelete;
                    customObjPermission.Edit__c = objPermission.PermissionsEdit;
                    customObjPermission.Read__c = objPermission.PermissionsRead;
                    customObjPermission.Modify_All__c = objPermission.PermissionsModifyAllRecords;
                    customObjPermission.View_All__c = objPermission.PermissionsViewAllRecords;
                    if(objPermission.SobjectType != null){
                        try{
                         customObjPermission.ObjectLabel__c =Schema.getGlobalDescribe().get(objPermission.SobjectType).getDescribe().getLabel();
                        }
                       catch (System.NullPointerException e) {
                           customObjPermission.ObjectLabel__c =objPermission.SobjectType;
                       }
                    }
                     customObjPermission.ExternalId__c = pSetMap.get(objPermission.ParentId) + objPermission.SobjectType;
                     parentIds.add(objPermission.ParentId);
                    lstCustomObjPermission.add(customObjPermission);
                }
                
                try{
                    upsert lstCustomObjPermission ExternalId__c;
                }catch (DmlException e) {
                    System.debug(e.getMessage());
                }
            }
            //Copy field permissions data
            when 'FieldPermissions' {
                List<PSET_Field_Permissions__c> lstCustomFldPermission = new List<PSET_Field_Permissions__c>();
                for (FieldPermissions fldPermission : (List<FieldPermissions>)sObjectsFromStart){
                    PSET_Field_Permissions__c customFldPermission = new PSET_Field_Permissions__c();
                    customFldPermission.Permission_Set__c = pSetMap.get(fldPermission.ParentId);
                    customFldPermission.Object_Name__c = fldPermission.SobjectType;
                    customFldPermission.Field_Name__c = fldPermission.Field;
                    customFldPermission.Read__c = fldPermission.PermissionsRead;
                    customFldPermission.Edit__c = fldPermission.PermissionsEdit;
                    if(fldPermission.Field != null && fldPermission.Field.contains('.')){
                        string str=fldPermission.Field.split('\\.')[1];
                        try{
                            customFldPermission.FieldLabel__c  =  Schema.getGlobalDescribe().get(fldPermission.SobjectType).getDescribe().fields.getMap().get(str).getDescribe().getLabel();
                          }
                        catch (System.NullPointerException e) {
                           customFldPermission.FieldLabel__c = str;
                        }
                        }
                    if(fldPermission.SobjectType != null){
                        try{
                            customFldPermission.ObjectLabel__c  =Schema.getGlobalDescribe().get(fldPermission.SobjectType).getDescribe().getLabel();
                        }
                        catch (System.NullPointerException e) {
                            customFldPermission.ObjectLabel__c  =fldPermission.SobjectType;
                        }
                       }
                    customFldPermission.ExternalId__c = pSetMap.get(fldPermission.ParentId) + fldPermission.Field;
                    
                    lstCustomFldPermission.add(customFldPermission);
                }
                try{
                    upsert lstCustomFldPermission ExternalId__c;
                }catch (DmlException e) {
                    System.debug(e.getMessage());
                }
            }
            //Copy permission set assignment
            when 'PermissionSetAssignment' {
               set<string> keyStringSet= new set<string>();
                Map<string,PSET_Permission_set_Assignment__c> customkeyStringSet= new Map<string,PSET_Permission_set_Assignment__c>();
                
                for (PermissionSetAssignment ObjPSETAssignment1 : (List<PermissionSetAssignment>)sObjectsFromStart){
                    keyStringSet.add((string)ObjPSETAssignment1.PermissionSetId + (string)ObjPSETAssignment1.AssigneeId);
                }
                List<PSET_Permission_set_Assignment__c> customPsa=[Select id,externalId__c,fxstatus__c,Assignee__c from PSET_Permission_set_Assignment__c Where externalId__c IN: keyStringSet];
                if(customPsa != null){
                    for(PSET_Permission_set_Assignment__c cpsa: customPsa){
                        customkeyStringSet.put(cpsa.externalId__c,cpsa);
                    }
                }
                
                List<PSET_Permission_set_Assignment__c> lstCustomPSETAssignment = new List<PSET_Permission_set_Assignment__c>();
                for (PermissionSetAssignment ObjPSETAssignment : (List<PermissionSetAssignment>)sObjectsFromStart){
                    PSET_Permission_set_Assignment__c customPSETAssignment = new PSET_Permission_set_Assignment__c();
                    customPSETAssignment.Permission_Set__c = pSetMap.get(ObjPSETAssignment.PermissionSetId);
                    customPSETAssignment.Assignee__c = ObjPSETAssignment.AssigneeId;
                    customPSETAssignment.ExternalId__c = (string)ObjPSETAssignment.PermissionSetId + (string)ObjPSETAssignment.AssigneeId;
                    if(customkeyStringSet != null && customkeyStringSet.containsKey((string)ObjPSETAssignment.PermissionSetId + (string)ObjPSETAssignment.AssigneeId) && customkeyStringSet.get((string)ObjPSETAssignment.PermissionSetId + (string)ObjPSETAssignment.AssigneeId).fxstatus__c=='Inactive'){
                        customPSETAssignment.Reprovisioned_Time__c=ObjPSETAssignment.SystemModstamp;
                    }
                    else if(customkeyStringSet != null && !customkeyStringSet.containsKey((string)ObjPSETAssignment.PermissionSetId + (string)ObjPSETAssignment.AssigneeId)){
                        customPSETAssignment.provisioned_Time__c=ObjPSETAssignment.SystemModstamp;
                    }
                    
                    lstCustomPSETAssignment.add(customPSETAssignment);
                }
                try{
                    upsert lstCustomPSETAssignment ExternalId__c;
                }catch (DmlException e) {
                    System.debug(e.getMessage());
                }
            }
            //Copy all the permissions for the modified permission set
            when 'PermissionSettings' {
                List<PSET_Permission_Settings__c > lstPSettings = new List<PSET_Permission_Settings__c >();
                List<PSET_Permission_Set_History__c > lstPSetHistory = new List<PSET_Permission_Set_History__c >();
                getCurrentPermissionSettings();
                for(PermissionSet pSet : (List<PermissionSet>)sObjectsFromStart){
                    for(String key : fieldNames){
                        if(key.toLowerCase().contains('permissions')) {
                            
                            /*
                            //This is to be done in future. The Custom object does exist already. 
                            //Native Track HIstory was enabled for the PSET Objects to use that for reporting.
                            //If the native track history is not adequate, we will develop a custom tracking history.
                            // Update Permission set history
                            // getCurrentPermissionSettings(); -- This needs to be moved out of loop.
                            */
                            string externalId = (string)pSetMap.get(pSet.Id) + (string)key;
                            if(String.valueOf(currentPermissionSettingsMap.get(externalId)) != String.valueOf(pSet.get(key))){
                            PSET_Permission_Set_History__c pSetHistory = new PSET_Permission_Set_History__c();
                            pSetHistory.PermissionSet__c = pSetMap.get(pSet.Id);
                            pSetHistory.Previous_Value__c = String.valueOf(currentPermissionSettingsMap.get(externalId));
                            pSetHistory.New_Value__c = String.valueOf(pSet.get(key));
                            pSetHistory.Field_Name__c =key;
                            pSetHistory.PermissionChangedBy__c=pSet.LastModifiedById;
                            pSetHistory.Date_Time_Changed__c=pSet.LastModifiedDate;
                            if(lstPSetHistory.size()<9999)    
                            lstPSetHistory.add(pSetHistory); 
                            }
                            
                            // Update permission settings
                            PSET_Permission_Settings__c pSettings  = new PSET_Permission_Settings__c();
                            pSettings.Permission_Set__c = pSetMap.get(pSet.Id);
                            pSettings.Field__c = key;
                            pSettings.Value__c = (pSet.get(key) == null || pSet.get(key) == '') ? false : (Boolean)pSet.get(key);
                            pSettings.ExternalId__c = (string)pSetMap.get(pSet.Id) + (string)key;
                            lstPSettings.add(pSettings);
                        }
                    }
                }
                try{
                    System.debug('Perm Settings Count: '+ lstPSettings.size());
                    upsert lstPSettings ExternalId__c;
                    insert lstPSetHistory;
                }catch (DmlException e) {
                    System.debug(e.getMessage());
                }
            }
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        
        set<string> keyobjpermission = new set<string>();
        if(pSetIdList != null && !pSetIdList.isEmpty()){
                         list<ObjectPermissions> objperms=[Select id,ParentId,SobjectType from ObjectPermissions where ParentId IN:pSetIdList];
                         for(ObjectPermissions objPerm: objperms){
                            keyobjpermission.add(pSetMap.get(objPerm.ParentId) + objPerm.SobjectType);
                         }
                }
        list<PSET_Object_Permissions__c> customobjpermission=[Select id from PSET_Object_Permissions__c Where ExternalId__c NOT IN:keyobjpermission AND Permission_Set__r.PermissionSetId_FromStandard__c IN:pSetIdList limit 10000];
        if(customobjpermission != null && !customobjpermission.isEmpty()){
             delete customobjpermission;
        }     
          
       AsyncApexJob jobs = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email from AsyncApexJob where Id =:BC.getJobId()];
        if(jobs != null){
            //Send mail on success
            String mailBody;
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {jobs.CreatedBy.Email};
            mailBody = '<html><body>The batch Apex job has been processed<br/> No. of batches processed '+jobs.TotalJobItems +'<br/> No. of Errors '+jobs.NumberOfErrors +'</body></html>';
            mail.setToAddresses(toAddresses);
            mail.setSubject('Batch Apex to copy permissions set is ' + jobs.Status);            
            mail.setHtmlBody(mailBody);
            //Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });  
        }
    }
}