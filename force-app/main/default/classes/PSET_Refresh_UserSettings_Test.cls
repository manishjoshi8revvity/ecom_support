/* Apex Test Class : PSET_Refresh_UserSettings_Test
 * Description: This test class will be used for Apex class "PSET_Refresh_UserSettings"  
 * Author: Vishwas Gupta(PWC)   Created Date(2021/05/17)
 */
@isTest
public class PSET_Refresh_UserSettings_Test {
     @testSetup static void setup() {
         permissionset ps =[SELECT Id FROM PermissionSet WHERE Name ='GENERAL_Default_1000' limit 1];
         string userId=userInfo.getUserId();
        PermissionSetAssignment  psa =[SELECT Id, PermissionSetId, AssigneeId, PermissionSetGroupId FROM PermissionSetAssignment Where AssigneeId =:userId AND PermissionSetId =:ps.Id];
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
        
        PermissionSetAssignment  psa =[SELECT Id, PermissionSetId, AssigneeId, PermissionSetGroupId FROM PermissionSetAssignment Limit 1];
        PSET_Permission_Set__c custper =[SELECT Id FROM PSET_Permission_Set__c LIMIT 1 ];
        custper.PermissionSetId_FromStandard__c = psa.PermissionSetId;
        Update custper;
        PSET_User_Settings__c pustoinsert = new PSET_User_Settings__c();
                 pustoinsert.User__c=userinfo.getUserId();
                 pustoinsert.PSETPermissionSet__c=custper.Id;
         insert pustoinsert;
        
    List<PSET_Refresh_UserSettings.FlowInputs> listRequest =new List<PSET_Refresh_UserSettings.FlowInputs>();
      PSET_Refresh_UserSettings.FlowInputs req = new PSET_Refresh_UserSettings.FlowInputs();
      req.varUser=userinfo.getUserId();
        req.varBatchSize=20;
        listRequest.add(req);
        PSET_Refresh_UserSettings.flowcalled(listRequest);
        Test.stopTest();
    }
    
    
}