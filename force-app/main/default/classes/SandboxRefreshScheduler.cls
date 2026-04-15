/**************************************************************
  * 1. Jira Ticket(s)
  *    - OM-256 automated Sandbox Refresh Scheduler
  *
  * 2. Description - This apex class is used to automated Sandbox Refresh Scheduler
  *
  * 3. Objects referenced
  *    -
  *
  * 4. Callouts to additional Components (including their methods) or None: 
  *    - SandboxRefreshCallout
  *    - SandboxRefreshFlowCallout
  *    
  * 5. Dependant Class(es):
  *    - SandboxRefreshFlowCallout
  *    - SandboxRefreshCallout
  *    
  *
  * 6. Test Class Name: SandboxRefreshCalloutTest
  * 
  * 7. Is @Invocable (Yes or No): No
  *
  * 8. Author Name(s): 
  *    - Sumit Kumar Sourav(PWC) & Avinash Kumar (PWC) Created Date(02/06/2024)
  *    -
  *    -
*************************************************************/ 
public class SandboxRefreshScheduler implements Schedulable {
    SandboxRefreshFlowCallout.userInputWrapper inp=new SandboxRefreshFlowCallout.userInputWrapper();
    public SandboxRefreshScheduler(SandboxRefreshFlowCallout.userInputWrapper uiwrapr) {
        inp=uiwrapr;
    }
  
    public void execute(SchedulableContext sc) {  
       string strinpJson = Json.serialize(inp);
       SandboxRefreshCallout.getSandboxDetails(strinpJson);
    }    
    
    
}