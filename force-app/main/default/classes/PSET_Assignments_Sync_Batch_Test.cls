/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *    - ATEAM-260
  *    - ITSFDC-####
  *
  * 2. Description -This is test class for PSET_Assignments_Sync_Batch
  * 3. Objects referenced
  *    -None
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None
  *   
  *
  * 5. Dependant Class(es):
  *    - PSET_Assignments_Sync_Batch
  *
  * 6. Class Name: PSET_Assignments_Sync_Batch_Test
  *
  * 7. Author Name(s): 
  *    - Vishwas Gupta 2021.05.24
  *    - First Last & Updated Date(YYYY.MM.DD)
  *    - First Last & Updated Date(YYYY.MM.DD)
  *
*************************************************************/ 
@isTest 
public class PSET_Assignments_Sync_Batch_Test {
    @testSetup static void setup() {
        PermissionSet ps = [SELECT Id,label FROM PermissionSet limit 1];
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
        
               PSET_Permission_set_Assignment__c customPSETAssignment = new PSET_Permission_set_Assignment__c();
                    customPSETAssignment.Permission_Set__c = customPS.Id;
                    customPSETAssignment.Assignee__c = userinfo.getUserId();
                    customPSETAssignment.ExternalId__c =customPS.PermissionSetId_FromStandard__c+userinfo.getUserId();
                        insert customPSETAssignment;
    }
     static testMethod void testMethod1(){
        Test.startTest();
           // SIOP_Create_Data_Fields obj = new SIOP_Create_Data_Fields();
           //  DataBase.executeBatch(obj);
           PermissionSetAssignment psa=[select PermissionSetId,AssigneeId from  PermissionSetAssignment limit 1];
            PermissionSet ps=[select id from PermissionSet limit 1];
            set<string>  setKeypsa=new set<string>();
         setKeypsa.add(string.valueof(psa.PermissionSetId) + string.valueof(psa.AssigneeId));
        set<string> setProvissionps = new set<string>();
         setProvissionps.add(ps.Id);
           PSET_Assignments_Sync_Batch obj = new PSET_Assignments_Sync_Batch(setKeypsa,setProvissionps );
            String sch = '0 0 20 * * ?';
          String jobID = system.schedule('Sync PSET', sch, obj);  
            
        Test.stopTest();
    }
}