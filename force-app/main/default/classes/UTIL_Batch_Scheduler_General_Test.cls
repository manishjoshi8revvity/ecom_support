/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *
  * 2. Description -Test class for UTIL_Batch_Scheduler_General Apex class
  * 3. Objects referenced
  *    -None
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None 
  *   
  *
  * 5. Dependant Class(es):
  * 6. Invocable: False
  *
  * 7. Test Class Name: UTIL_Batch_Scheduler_General_Test
  *
  * 8. Author Name(s): 
  *    - Aakash/Vishwas 31-01-2023
  *
*************************************************************/
@isTest
public class UTIL_Batch_Scheduler_General_Test {
	@isTest static void testflowcalled() {
        test.startTest();
        UTIL_Batch_Scheduler_General.FlowInputs varInputClass= new UTIL_Batch_Scheduler_General.FlowInputs();
        varInputClass.BatchclassName='PSET_Filter_Batch';
        UTIL_Batch_Scheduler_General.flowcalled(new list<UTIL_Batch_Scheduler_General.FlowInputs>{varInputClass});
        test.stopTest();
   }
    @isTest static void testflowcalled2() {
        test.startTest();
        UTIL_Batch_Scheduler_General.FlowInputs varInputClass= new UTIL_Batch_Scheduler_General.FlowInputs();
        varInputClass.BatchclassName='PSET_PermissionSets_Copy_Batch';
        UTIL_Batch_Scheduler_General.flowcalled(new list<UTIL_Batch_Scheduler_General.FlowInputs>{varInputClass});
        test.stopTest();
   }
}