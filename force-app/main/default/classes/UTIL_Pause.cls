/**************************************************************
* 1. Jira Ticket(s)
*    - OM-337
*
* 2. Description - This allows S.FLOW to pause between Mixed DML updates. (For L.FLOW/SUB.FLOW use the Wait For Condidtions Pause set to 0 Hours Resume)
*
* 3. Objects referenced
*    -C_SET_9998_SFDC_Log_Settings__c.PauseTimestamp__c
*
* 4. Callouts to additional Components (including their methods) or None: NO
*    

* 5. Dependant Class(es):
*    
*
* 6. Test Class Name: UTIL_PauseTest
* 
* 7. Is @Invocable (Yes or No): Yes
*
* 8. Author Name(s): 
*    - 2024.03.12 SS Base
*    -
*    -
*************************************************************/ 
public class UTIL_Pause {
    @InvocableMethod
    public static void createNewtransaction(List<String> LeaveToggleOff_SelectStartNewTransaction){
        C_SET_9998_SFDC_Log_Settings__c mc = C_SET_9998_SFDC_Log_Settings__c.getOrgDefaults();
        mc.PauseTimestamp__c=system.now();
        String objJSONStr = Json.serialize(mc); 
        updateSobjectList( objJSONStr );
    }
    
    @future
    public static void updateSobjectList( String objstr ) {
        try{
            system.debug('@@objstr'+objstr);
            C_SET_9998_SFDC_Log_Settings__c obj=(C_SET_9998_SFDC_Log_Settings__c) Json.deserialize(objstr, System.Type.forName('C_SET_9998_SFDC_Log_Settings__c'));
            update obj; 
        }
        
        catch(exception ex) {
            system.debug('@@ex'+ex.getLineNumber());
            system.debug('@@ex'+ex.getMessage());
            
        }
    }
}