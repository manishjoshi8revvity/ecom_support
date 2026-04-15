/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *    - ATEAM-260
  *    - ITSFDC-####
  *
  * 2. Description -This is Scheduler apex class  which will trigger PSET_PermissionSets_Copy_Batch and from there it wil schedule PSET_PermissionSettings_Copy_Batch apex class)
  * 3. Objects referenced
  *    -None
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None
  *   
  *
  * 5. Dependant Class(es):
  *    - PSET_PermissionSets_Copy_Batch
  *
  * 6. Class Name: PSET_PermissionSets_Copy_Batch_Test
  *
  * 7. Author Name(s): 
  *    - Vishwas Gupta 2021.05.24
  *    - First Last & Updated Date(YYYY.MM.DD)
  *    - First Last & Updated Date(YYYY.MM.DD)
  *
*************************************************************/ 
public class PSET_PermissionSets_Copy_Scheduler implements Schedulable{
	public void execute(SchedulableContext sc) {
      PSET_PermissionSets_Copy_Batch batch = new PSET_PermissionSets_Copy_Batch(); 
      database.executebatch(batch);
   }
}