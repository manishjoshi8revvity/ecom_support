/**************************************************************
* 1. Jira Ticket(s)
*    - OM-396
*
* 2. Description - This apex trigger is used to perform operation on dml operations.
*
* 3. Objects referenced
*    - Case
*
* 4. Callouts to additional Components (including their methods) or None:
*    
* 5. Dependant Class(es):
*    - EmailMessageTriggerHandler
*    
*
* 6. Test Class Name: EmailMessageTriggerHandlerTest
* 
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s): 
*    - Sumit Kumar Sourav & Created Date(2024.07.13)
*    -
*************************************************************/
Trigger EmailMessageTrigger on EmailMessage (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    if(Trigger.isBefore && Trigger.isInsert) {
        EmailMessageTriggerHandler.executehandler(Trigger.New);
    }
}