/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *    - ATEAM-260
  *    - ITSFDC-####
  *
  * 2. Description -This is test class for PSET_UserSettings_Refresh 
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
  *    - PSET_UserSettings_Refresh
  *
  * 6. Class Name: PSET_UserSettings_Refresh_Test
  *
  * 7. Author Name(s): 
  *    - Vishwas Gupta 2021.05.24
  *    - First Last & Updated Date(YYYY.MM.DD)
  *    - First Last & Updated Date(YYYY.MM.DD)
  *
*************************************************************/ 
@isTest
public class PSET_UserSettings_Refresh_Test {
     @testSetup static void setup() {
         permissionset ps =[SELECT Id FROM PermissionSet WHERE Name ='GENERAL_Default_1000' limit 1];
        PermissionSetAssignment permissionas =[SELECT Id, PermissionSetId, AssigneeId FROM PermissionSetAssignment Where PermissionSetId=:ps.Id AND AssigneeId=:userinfo.getUserId() limit 1];
 PSET_Permission_Set__c customPS = new PSET_Permission_Set__c();
                customPS.PermissionSetId_FromStandard__c = ps.Id;
                customPS.Name = 'GENERAL_Default_1000';
                customPS.Label__c = 'GENERAL_Default_1000';
                customPS.Description__c = 'GENERAL_Default_1000';
                customPS.IsCustom__c = true;
                customPS.IsOwnedByProfile__c = false;
                customPS.CreatedById_FromStandard__c = userinfo.getUserId();
                customPS.CreatedDate_FromStandard__c = date.today();
                customPS.LastModifiedById_FromStandard__c = userinfo.getUserId();
                customPS.LastModifiedDate_FromStandard__c = date.today();
        insert customPS;
                 PSET_User_Settings__c pustoinsert = new PSET_User_Settings__c();
                 pustoinsert.User__c=userinfo.getUserId();
                 pustoinsert.PSETPermissionSet__c=customPS.Id;
         insert pustoinsert;
         
                 PSET_Permission_Settings__c pset = new PSET_Permission_Settings__c();
                 pset.Field__c='test permissionsemailsingle';
                 pset.Permission_Set__c=customPS.Id;
                 pset.RiskLevel__c =null;
                 pset.PSETFieldMaster__c =null;
                 pset.value__c =true;
                 pset.ExternalId__c  ='testingidtestpermissionset';
        insert pset;
        
                 PSET_Permission_set_Assignment__c customPSETAssignment = new PSET_Permission_set_Assignment__c();
                 customPSETAssignment.Permission_Set__c = customPS.Id;
                 customPSETAssignment.Assignee__c = userinfo.getUserId();
                 customPSETAssignment.ExternalId__c =customPS.PermissionSetId_FromStandard__c+userinfo.getUserId();
         insert customPSETAssignment;
    }
    static testMethod void testMethod1(){
       
        Test.startTest();
        
        PermissionSetAssignment  psa =[SELECT Id, PermissionSetId, AssigneeId, PermissionSetGroupId FROM PermissionSetAssignment order by SystemModstamp limit 1];
        system.debug('test psa'+psa);
        PSET_Permission_Set__c custper =[SELECT Id FROM PSET_Permission_Set__c LIMIT 1 ];
        custper.PermissionSetId_FromStandard__c = psa.PermissionSetId;
        Update custper;
        system.debug('test custper'+custper);
        PSET_User_Settings__c pustoinsert = new PSET_User_Settings__c();
                 pustoinsert.User__c=userinfo.getUserId();
                 pustoinsert.PSETPermissionSet__c=custper.Id;
         insert pustoinsert;
        system.debug('test pustoinsert'+pustoinsert);
           PSET_Permission_Settings__c pps = new PSET_Permission_Settings__c();
                    pps.PSETFieldMaster__c=pustoinsert.PSETFieldMaster__c;
                    pps.Value__c=true;
                    pps.Permission_Set__c=custper.Id;
                    pps.ExternalId__c ='test';
        
        insert pps;
        system.debug('test pps'+pps);
        system.debug('pps=='+[select fxPSETNativeID__c,value__c,Permission_Set__c from PSET_Permission_Settings__c ]);
    List<PSET_UserSettings_Refresh.FlowInputs> listRequest =new List<PSET_UserSettings_Refresh.FlowInputs>();
      PSET_UserSettings_Refresh.FlowInputs req = new PSET_UserSettings_Refresh.FlowInputs();
      req.varUser=userinfo.getUserId();
        req.varBatchSize=20;
        listRequest.add(req);
        PSET_UserSettings_Refresh.flowcalled(listRequest);
        Test.stopTest();
    }
    
    
}