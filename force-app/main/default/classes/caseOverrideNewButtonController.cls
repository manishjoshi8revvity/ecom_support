/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    - OM-376 - SFS Project
*
* 2. Description - Put detailed description here of what this class is used for procedurally
*    We need to override the default "New" Case button on list views. Certain users are allowed to create
*    Case uing the legacy method, while others are required to use a S.FLOW 2404 method. This is controlled by a user
*    P.SET "CUSTOM: C.PERM 2410 Create Case using Legacy New Button".  
*
*
* 3. Objects referenced
*    - None
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - None
*
* 6. Test Class Name: caseOverrideNewButtonController_TEST
*
* 7. Is @Invocable (Yes or No):  No
*
* 8. Author Name(s):
*    - (PwC Avinash Kumar) (2024.05.25)
*    - 
*
*************************************************************/
public class caseOverrideNewButtonController {
   
    /*
* ─────────────────────────────────────────────────────────────────────────────────────────────────────────────-------
* @description      Returns true when User is assigned custom permission as 'C_PERM_2410_New_Case_Legacy'
* @parameter        None
* @returnValue      Boolean
* @example          FeatureManagement.checkPermission('C_PERM_2410_New_Case_Legacy');(this will check custom permission)
* ──────────────────────────────────────────────────────────────────────────────────────────────────────────────--------
*/
    // to be used in aura component
    @AuraEnabled
    public static boolean checkInfCaseUsrPermisson(){
       
       
            // to check the custom permission
            Boolean checkBool = FeatureManagement.checkPermission('C_PERM_2410_New_Case_Legacy');
           
            // return boolean if custom permission is assigned
            return checkBool;
       
    }
   
}