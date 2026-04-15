/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-71    
*
* 2. Description - This class is a service class to create the alias and nickname for SUB.FLOW_4494: ECOM - User Registration.
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
*    - None
*	
* 6. Test Class Name:         
*    - ECOM_UserFlowController_Test
*
* 7. Is @Invocable (Yes or No): Yes
*
* 8. Author Name(s):
*    - Vipul 2023.07.21

*************************************************************/
public class ECOM_UserFlowController {
    
    
    /**
    * @description Invocable method to create the alias and community nickname for the registering user.
    * @author Vipul Goyal | 07-21-2023 
    * @param dataInformation 
    * @return List<ECOM_UserFlowServiceWrapper.ResultWrapper> 
    **/
    @InvocableMethod(label='Get User Information' category='User Management' description='This method is used to get alias and password for User setup')
    public static List<ECOM_UserFlowServiceWrapper.ResultWrapper> createAlias(List<ECOM_UserFlowServiceWrapper.DataWrapper> dataInformation)
    {
        String suppressedLastName= ECOM_UserUtil.getSuppressedLastName(dataInformation);//will be moved to util class
        String nickname = suppressedLastName + ECOM_UserUtil.generateRandomString(30);//will be moved to util class

        ECOM_UserFlowServiceWrapper.ResultWrapper rw= new ECOM_UserFlowServiceWrapper.ResultWrapper();
        rw.alias = suppressedLastName;
        rw.communityNickName = nickname;
        
        return new List<ECOM_UserFlowServiceWrapper.ResultWrapper>{rw};
    }

}