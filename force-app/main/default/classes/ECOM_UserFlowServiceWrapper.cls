/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-71    
*
* 2. Description - This class is a warpper class for nuckname and alias in SUB.FLOW_4494: ECOM - User Registration.
*
*
*
* 3. Objects referenced
*    -None
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
*
* 5. Dependant Class(es):
*    - ECOM_UserFlowService
*	 - ECOM_UserFlowServiceUtil
*	
* 6. Test Class Name:         
*    - ECOM_UserFlowServiceWrapper_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vipul 2023.07.21

*************************************************************/
public class ECOM_UserFlowServiceWrapper {
    
    //This class acts as a datawrapper to get the input from SUB.FLOW_4494: ECOM - User Registration.
    public class DataWrapper{
        @InvocableVariable
        public String lastName;
    }
    
    //This class acts as a datawrapper to return the output to SUB.FLOW_4494: ECOM - User Registration.
    public class ResultWrapper{
        @InvocableVariable
        public String alias;
        @InvocableVariable
        public String communityNickname;
    }

}