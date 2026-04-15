/**************************************************************
* 1. Jira Ticket(s) that relates to this class 
*    - ECOM-2302
*
* 2. Description - Interface for ECOM_RegistrationService   
*
*
* 3. Objects referenced
*    -
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - None
*
* 6. Test Class Name: 
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vasudev R 2024-04-02 : Initial creation
*************************************************************/
public Interface ECOM_IRegistrationService {

    Map<String, Object> registerNewAccount(Map<String, Object> registrationDataMap);
}