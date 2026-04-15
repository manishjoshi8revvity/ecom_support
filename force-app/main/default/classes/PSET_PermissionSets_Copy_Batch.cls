/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *    - ATEAM-260
  *    - ITSFDC-####
  *
  * 2. Description -Batch class to copy from PermissionSet metadata to custom created object - PSET_Permission_Set__c.
  *                 In the finish method, we invoke another batch class which copies the related objects of permission set to custom objects.
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
  *    - PSET_PermissionSettings_Copy_Batch
  *
  * 6. Test Class Name: PSET_PermissionSets_Copy_Batch_Test
  *
  * 7. Author Name(s): 
  *    - Vishwas Gupta 2021.05.24
  *    - First Last & Updated Date(YYYY.MM.DD)
  *    - First Last & Updated Date(YYYY.MM.DD)
  *
*************************************************************/ 

public class PSET_PermissionSets_Copy_Batch implements Database.Batchable<SObject>,Database.Stateful {
    public DateTime batchStartTime = DateTime.now();
    public List<Id> pSetIdList = new List<Id>();
    public Database.QueryLocator start(Database.BatchableContext BC) {
        
        // Read values from custom settings. PSET_TimeLastRun__c will have the latest date and time when the batch is run.
        // PSET_IsCopyFullLoad__c can be changed to true, to copy the full data load.
        PSET_Settings__c pSetSettings = PSET_Settings__c.getOrgDefaults();
        DateTime timeLastRun = pSetSettings.PSET_TimeLastRun__c;
        //Adding a default value so when pushing to new orgs, the test class can run. 
        if(timeLastRun == null) timeLastRun = DateTime.now()- (24 * 60)/1440;        
        Boolean isCopyFullLoad = pSetSettings.PSET_IsCopyFullLoad__c;
        
        String query = 'Select Id, Name, Label, Description, IsCustom, IsOwnedByProfile, CreatedById, CreatedDate, LastModifiedById, LastModifiedDate, Profile.Name From PermissionSet ';
        if(!isCopyFullLoad && !Test.isRunningTest()){
            String formattedDate = timeLastRun.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
            query += ' Where LastModifiedDate >=' + formattedDate;
        }
        if(Test.isRunningTest()){
           query += '  order by lastmodifieddate  desc Limit 10';
        }
        return  Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<PermissionSet> sObjectsFromStart){
        
        //Update PSET_TimeLastRun__c in the custom settings to current time when the process starts.
        PSET_Settings__c settings = PSET_Settings__c.getOrgDefaults();
        settings.PSET_TimeLastRun__c = DateTime.now();
        try{
            update settings;
        }catch(DmlException e){
            System.debug(e.getMessage());
        }
        
        // Copies the data from standard PermissionSet to custom created object PSET_Permission_Set__c
        List<PSET_Permission_Set__c> lstCustomPSet = new List<PSET_Permission_Set__c>();
        if(sObjectsFromStart != null){
            for (PermissionSet PS : sObjectsFromStart){
                PSET_Permission_Set__c customPS = new PSET_Permission_Set__c();
                customPS.PermissionSetId_FromStandard__c = PS.Id;
                customPS.Name = (PS.IsOwnedByProfile) ? PS.Profile.Name : PS.Name;
                customPS.Label__c = (PS.IsOwnedByProfile) ? PS.Profile.Name : PS.Label;
                customPS.Description__c = PS.Description;
                customPS.IsCustom__c = PS.IsCustom;
                customPS.IsOwnedByProfile__c = PS.IsOwnedByProfile;
                customPS.CreatedById_FromStandard__c = PS.CreatedById;
                customPS.CreatedDate_FromStandard__c = PS.CreatedDate;
                customPS.LastModifiedById_FromStandard__c = PS.LastModifiedById;
                customPS.LastModifiedDate_FromStandard__c = PS.LastModifiedDate;
                lstCustomPSet.add(customPS);
                pSetIdList.add(PS.Id);
            }
        }
        try{
            upsert lstCustomPSet PermissionSetId_FromStandard__c;
        }catch (DmlException e) {
            System.debug(e.getMessage());
        }
    }
    
    public void finish(Database.BatchableContext BC) {
         PSET_Settings__c settings = PSET_Settings__c.getOrgDefaults();
        String pSetIdListQuery = '\''+String.join(pSetIdList,'\',\'')+'\'';
        String objPermissionsQuery ='Select ParentId, SobjectType, PermissionsCreate,PermissionsDelete, PermissionsEdit, PermissionsRead, PermissionsModifyAllRecords, PermissionsViewAllRecords From ObjectPermissions Where ParentId IN ('+ pSetIdListQuery +')';
        String fldPermissionsQuery = 'Select ParentId, SobjectType, Field, PermissionsRead, PermissionsEdit From FieldPermissions Where ParentId IN ('+ pSetIdListQuery +')';
        List<string> AllowedLicenseType =settings.AllowedLicenseType__c != null ? settings.AllowedLicenseType__c.split(',') : New List<string>();
        String permissionAssignmentQuery = 'Select PermissionSetId, AssigneeId,SystemModstamp From PermissionSetAssignment Where Assignee.License_Type__c IN:AllowedLicenseType AND PermissionSetId IN ('+ pSetIdListQuery +')';
        
        DescribeSObjectResult describeResult = PermissionSet.getSObjectType().getDescribe();    
        List<String> fieldNames = new List<String>( describeResult.fields.getMap().keySet() );  
        String permissionSettingsQuery = ' SELECT ' +   String.join( fieldNames, ',' ) + ' FROM ' + describeResult.getName() + ' Where Id IN ('+ pSetIdListQuery +')';
        
        if(Test.isRunningTest()){
            objPermissionsQuery += ' Limit 10';
            fldPermissionsQuery += ' Limit 5';
            permissionAssignmentQuery += ' Limit 5';
            permissionSettingsQuery += ' Limit 2';
        } 
        
        Database.executeBatch(new PSET_PermissionSettings_Copy_Batch(objPermissionsQuery, 'ObjectPermissions', pSetIdList));
        Database.executeBatch(new PSET_PermissionSettings_Copy_Batch(fldPermissionsQuery, 'FieldPermissions', pSetIdList));
        Database.executeBatch(new PSET_PermissionSettings_Copy_Batch(permissionAssignmentQuery, 'PermissionSetAssignment', pSetIdList));
        Database.executeBatch(new PSET_PermissionSettings_Copy_Batch(permissionSettingsQuery, 'PermissionSettings', pSetIdList, fieldNames),10);
     
        AsyncApexJob jobs = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email from AsyncApexJob where Id =:BC.getJobId()];
        if(jobs != null){
            //Update PSET_IsCopyFullLoad__c in the custom settings to false once the full load is complete.
           
            if(settings.PSET_IsCopyFullLoad__c){
                settings.PSET_IsCopyFullLoad__c = false;
                settings.PSET_TimeLastRun__c = batchStartTime; 
                try{
                    update settings;
                }catch(DmlException e){
                    System.debug(e.getMessage());
                }
            }
                        
            String mailBody;
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {jobs.CreatedBy.Email};
            mailBody = '<html><body>The batch Apex job has been processed<br/> No. of batches processed '+jobs.TotalJobItems +'<br/> No. of Errors '+jobs.NumberOfErrors +'</body></html>';
            mail.setToAddresses(toAddresses);
            mail.setSubject('Batch Apex to copy permissions is ' + jobs.Status);            
            mail.setHtmlBody(mailBody);
            //Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });  
        } 
    }
}