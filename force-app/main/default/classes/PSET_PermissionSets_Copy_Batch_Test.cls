/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    - ATEAM-260
*    - ITSFDC-####
*
* 2. Description -This is test class for PSET_PermissionSets_Copy_Scheduler which will cover rest 2 apex class (PSET_PermissionSets_Copy_Batch and PSET_PermissionSettings_Copy_Batch)
* 3. Objects referenced
*    -None
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*   
*
* 5. Dependant Class(es):
*    - PSET_PermissionSets_Copy_Scheduler
*
* 6. Class Name: PSET_PermissionSets_Copy_Batch_Test
*
* 7. Author Name(s): 
*    - Vishwas Gupta 2021.05.24
*    - First Last & Updated Date(YYYY.MM.DD)
*    - First Last & Updated Date(YYYY.MM.DD)
*
*************************************************************/ 
@isTest
public class PSET_PermissionSets_Copy_Batch_Test { 
    @testSetup static void setup() {
        PermissionSet ps = [SELECT Id,label FROM PermissionSet where  Label like '%General%' limit 1];
        PermissionSetAssignment psa= new PermissionSetAssignment(AssigneeId = userinfo.getUserId(), PermissionSetId = ps.Id);
        
        
        PSET_Permission_Set__c customPS = new PSET_Permission_Set__c();
        customPS.PermissionSetId_FromStandard__c = string.valueof(ps.Id);
        customPS.Name = 'testnativePermisionName';
        customPS.Label__c = 'testnativePermisionLabel';
        customPS.Description__c = 'testnativePermisionDescription';
        customPS.IsCustom__c = true;
        customPS.IsOwnedByProfile__c = false;
        customPS.CreatedById_FromStandard__c = userinfo.getUserId();
        customPS.CreatedDate_FromStandard__c = date.today();
        customPS.LastModifiedById_FromStandard__c = userinfo.getUserId();
        customPS.LastModifiedDate_FromStandard__c = date.today();
        insert customPS;
        
        PSET_Permission_Settings__c pset = new PSET_Permission_Settings__c();
        pset.Field__c='test permissionsemailsingle';
        pset.Permission_Set__c=customPS.Id;
        pset.RiskLevel__c =null;
        pset.ExternalId__c  ='testingidtestpermissionset';
        insert pset;
        
        PSET_Object_Permissions__c objper = new PSET_Object_Permissions__c();
        objper.Object_Name__c='PSET_Object_Permissions__c';
        objper.Create__c=false;
        objper.Delete__c=false;
        objper.Edit__c=false;
        objper.ExternalId__c='testingidtestpermissionset';
        objper.Modify_All__c=false; //Modify_All__c
        objper.Read__c=false;
        objper.Permission_Set__c=customPS.Id;
        insert objper;
        
        PSET_Field_Permissions__c fldper = new PSET_Field_Permissions__c();
        fldper.Object_Name__c='PSET_Field_Permissions__c';
        fldper.Edit__c=false;
        fldper.Field_Name__c ='Edit__c';
        fldper.ExternalId__c='testingidtestpermissionset';
        fldper.Permission_Set__c=customPS.Id;
        fldper.Read__c=false;
        insert fldper;
        
        PSET_Permission_Set_Assignment__c psa1 = new PSET_Permission_Set_Assignment__c();
        psa1.Permission_Set__c =customPS.Id;
        psa1.Assignee__c=userinfo.getUserId();
        psa1.ExternalId__c='testingidtestpermissionset';
        insert psa1;
        
        PSET_Permission_set_Assignment__c customPSETAssignment = new PSET_Permission_set_Assignment__c();
        customPSETAssignment.Permission_Set__c = customPS.Id;
        customPSETAssignment.Assignee__c = userinfo.getUserId();
        customPSETAssignment.ExternalId__c =customPS.PermissionSetId_FromStandard__c+userinfo.getUserId();
        insert customPSETAssignment;
    }
    public static testMethod void copyPermissionSetsversion(){
        Test.startTest();
        PSET_PermissionSets_Copy_Batch batch = new PSET_PermissionSets_Copy_Batch();
        Database.Executebatch(batch);
        Test.stopTest();
    }
    public static testMethod void testScheduler(){
        Test.startTest();
        PSET_PermissionSets_Copy_Scheduler myScheduler = new PSET_PermissionSets_Copy_Scheduler();
        String sch = '0 59 * * * ?';
        System.Schedule('Test PSET Hourly Schedule', sch, myScheduler);
        Test.stopTest();
    } 
}