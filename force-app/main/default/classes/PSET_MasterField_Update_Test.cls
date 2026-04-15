@isTest
public class PSET_MasterField_Update_Test {

    @testSetup static void setup() {
        PSET_Permission_Set__c customPS = new PSET_Permission_Set__c();
                customPS.PermissionSetId_FromStandard__c = 'test';
                customPS.Name = 'test';
                customPS.Label__c = 'test';
                customPS.Description__c = 'test';
                customPS.IsCustom__c = true;
                customPS.IsOwnedByProfile__c = false;
                customPS.CreatedById_FromStandard__c = userinfo.getUserId();
                customPS.CreatedDate_FromStandard__c = date.today();
                customPS.LastModifiedById_FromStandard__c = userinfo.getUserId();
                customPS.LastModifiedDate_FromStandard__c = date.today();
        insert customPS;
        PSET_Field_Master__c PFM = new PSET_Field_Master__c();
        PFM.PSETPermissionSet__c=customPS.Id;
        PFM.Name='test';
        PFM.SettingName__c='test';
        PFM.SettingLocation__c='system';
        PFM.SettingLabel__c  ='test';
        insert PFM;
        PSET_Permission_Settings__c pset = new PSET_Permission_Settings__c();
                 pset.Field__c='test';
                 pset.Permission_Set__c=customPS.Id;
                 pset.RiskLevel__c =null;
                 pset.PSETFieldMaster__c =null;
                 pset.value__c =true;
                 pset.ExternalId__c  ='testingidtestpermissionset';
        insert pset;
        PSET_Permission_Set_History__c PPSH = new PSET_Permission_Set_History__c();
            PPSH.Field_Name__c='test'; 
            PPSH.PSETFieldMaster__c=null; 
            PPSH.PermissionSet__c=customPS.Id; 
        insert PPSH;
        
    }
     static testMethod void testMethod1(){
        list<string> Liststring = new list<string>();
        Liststring.add('test');
        PSET_MasterField_Update.flowcalledforMasterField(Liststring);
    }
}