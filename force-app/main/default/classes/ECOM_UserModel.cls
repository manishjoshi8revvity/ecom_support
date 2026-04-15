/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-69  
*
* 2. Description - This class is used to login user into the system.
*
*
*
* 3. Objects referenced
*    -
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
*
* 5. Dependant Class(es):
*    - ECOM_UserService
*
* 6. Test Class Name:         
*    - ECOM_UserModel_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vipul 2023.08.01

*************************************************************/
public class ECOM_UserModel {
       
	public class PasswordRequest{
        @InvocableVariable
        public String userName;
        @InvocableVariable
        public String userId;
        @InvocableVariable
        public String password;
        @InvocableVariable
        public String token;
        @InvocableVariable
        public String code;
        @InvocableVariable
        public String profileId;
    }
    
    public class PasswordResponse
    {
        @InvocableVariable
        public String userName;
        @InvocableVariable
        public Boolean success;
        @InvocableVariable
        public String message;
    } 
    
 /* public String userName;
    public String email;
    public String firstName;
    public String lastName;
    public String password;

    @InvocableVariable
    public String userName;
    @InvocableVariable
    public String userId;
    @InvocableVariable
    public String password;
    @InvocableVariable
    public String token;
    @InvocableVariable
    public String code;
    @AuraEnabled
    public String country;
    @AuraEnabled
    public String state;
    @AuraEnabled
    public String city;
    @AuraEnabled
    public String street;
    @AuraEnabled
    public String zipcode;
*/
    
    
}