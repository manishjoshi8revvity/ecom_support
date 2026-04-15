/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-71    
*
* 2. Description - This class is a util class to create the alias and nickname for the class ECOM_UserFlowService used in SUB.FLOW_4494: ECOM - User Registration.
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
*	
* 6. Test Class Name: 
*    - ECOM_UserFlowServiceUtil_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vipul 2023.07.21

*************************************************************/
public class ECOM_UserFlowServiceUtil {
    
    /**
    * @description The method to extract first 5 letters of the user's lastname
    * @author Vipul Goyal | 07-21-2023 
    * @param dataInformation 
    * @return String 
    **/
    public static String getSuppressedLastName(List<ECOM_UserFlowServiceWrapper.DataWrapper> dataInformation)
    {
        String ln=dataInformation[0].lastName;
        return (ln.length()>5?ln.substring(0,5):ln);
    }
    
    /**
    * @description This is a method to create a random string to be attached with alias to create an unique username.
    * @author Vipul Goyal | 07-27-2023 
    * @param len 
    * @return String 
    **/
    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }
}