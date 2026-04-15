/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *    - ATEAM-1782
  *
  * 2. Description -This is test class for PSET_Filter_Batch_Test
  * 3. Objects referenced
  *    -None
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None
  *   
  *
  * 5. Dependant Class(es):
  *    - PSET_Filter_Batch
  *
  * 6. Class Name: PSET_Filter_Batch_Test
  *
  * 7. Author Name(s): 
  *    - Vishwas Gupta 2021.05.24
  *    - First Last & Updated Date(YYYY.MM.DD)
  *    - First Last & Updated Date(YYYY.MM.DD)
  *
*************************************************************/ 
@isTest(SeeAllData=false)
public class PSET_Filter_Batch_Test {
    @testSetup static void setup() {
        
        string userIdstr=userinfo.getUserId();
PermissionSetAssignment psa= [Select id,PermissionSetId From PermissionSetAssignment Where AssigneeId  =:userIdstr limit 1];
     PermissionSet ps = [SELECT Id,label FROM PermissionSet Where Id=:psa.PermissionSetId  limit 1];
        
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
                    customPSETAssignment.ExternalId__c =ps.Id+userinfo.getUserId();
                        insert customPSETAssignment; 
    }
     static testMethod void testMethod1(){
         string userIdstr=userinfo.getUserId();
         PermissionSetAssignment psa= [Select id,PermissionSetId,AssigneeId From PermissionSetAssignment Where AssigneeId  =:userIdstr limit 1];
         system.debug('PermissionSetAssignment='+psa);
         system.debug('PermissionSet=='+[SELECT Id,label FROM PermissionSet Where Id=:psa.PermissionSetId  limit 1]);
         system.debug('customPSETAssignment=='+[select id,ExternalId__c from PSET_Permission_set_Assignment__c]);
        Test.startTest();
          PSET_Filter_Batch obj = new PSET_Filter_Batch();
            String sch = '0 0 20 * * ?';
         String jobID = system.schedule('Sync PSET', sch, obj);  
            
        Test.stopTest();
    }
}