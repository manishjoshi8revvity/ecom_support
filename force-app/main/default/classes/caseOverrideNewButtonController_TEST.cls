/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *    -OM-376 - SFS Project
  *    
  *
  * 2. Description - Put detailed description here of what this class is used for procedurally
  *    We need to override the default "New" Case button on list views. Certain users are allowed to create
  *    Case uing the legacy method, while others are required to use a S.FLOW 2404 method. This is controlled by a user
  *    P.SET "CUSTOM: C.PERM 2410 Create Case using Legacy New Button".  
  *
  *
  * 3. Objects referenced
  *    -Case
  *    
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None
  *
  *
  * 5. Dependant Class(es):
  *    - caseOverrideNewButtonController
  *
  * 6. Test Class Name: caseOverrideNewButtonController_TEST
  *
  * 7. Is @Invocable (Yes or No):  No
  *
  * 8. Author Name(s): 
  *    - Avinash Kumar(PWC)(2024.06.06)
  *
*************************************************************/ 
@isTest
public class caseOverrideNewButtonController_TEST {
    
    public static testmethod void testcheckInfcaseUsrPermisson(){
        
        test.startTest();
      //create test data for user object
       Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='Adminuser@revtestorg.com');
        insert u;
        //Create Mock permissions
        PermissionSet ps = new PermissionSet(Label = 'mockPs', Name = 'mockPs');
        insert ps;

        // Given custom permission associated to the mocked PermissionSet
        SetupEntityAccess sea = new SetupEntityAccess(
                                    ParentId = ps.Id,
                                    SetupEntityId = [SELECT Id FROM CustomPermission
                                    WHERE DeveloperName = 'C_PERM_2410_New_Case_Legacy'][0].Id
                                    );
        insert sea;
        // Given mocked Permission Set assigned to user for test
        PermissionSetAssignment psa = new PermissionSetAssignment(
                                            AssigneeId = u.id,
                                            PermissionSetId = ps.Id
                                            );
        
        insert psa;
        system.runAs(u){
            caseOverrideNewButtonController.checkInfCaseUsrPermisson(); 
            
        }
        test.stopTest();
    }

}