/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-1020
*
* 2. Description - This class is used as wrapper class for handling user model for punchout users.
*
* 3. Objects referenced
*    - User
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
* 5. Dependant Class(es):
*    - ECOM_UserService
*	 - ECOM_UserUtil
*
* 6. Test Class Name: 
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - vramachandran@rafter.one | 22 Dec 2023
*
*************************************************************/
public class ECOM_POUserModel {
    
    @auraEnabled public String userId;
    @auraEnabled public String userName;
    @auraEnabled public String userEmail;
    @auraEnabled public String userFirstName;
    @auraEnabled public String userLastName;
    @auraEnabled public String userAccountId;
    @auraEnabled public String userContactId;
    @auraEnabled public String userPhoneExtension;
    @auraEnabled public String userCountryPhoneCode;
    @auraEnabled public String userPhone;
    @auraEnabled public String userFax;
    
    @AuraEnabled public Boolean isPunchoutUser;
    
    @auraEnabled public UserContact userContactRecord;
    
    @auraEnabled public UserAccount userAccountRecord;
    
    @auraEnabled public ERP_AddressModel userErpAddressModel;
    

    public class UserContact{
        
        @auraEnabled public String contactId;
        @auraEnabled public String contactFirstName;
        @auraEnabled public String contactLastName;
        @auraEnabled public String contactEmail;
        @auraEnabled public String contactAccountId;
        @auraEnabled public String contactCountry;
        
    }    
    
    public Class UserAccount{
        
        @auraEnabled public String accountId;
        @auraEnabled public String accountName;

    }
        

}