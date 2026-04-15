/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-1020
*
* 2. Description - This class is used as a model for Punchout requests and Poom responses
*
* 3. Objects referenced
*    - NA
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
* 5. Dependant Class(es):
*    
*
* 6. Test Class Name: 
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - vramachandran@rafter.one | 22 Dec 2023
*************************************************************/
public class ECOM_PunchoutWrapper {
    
    
    //posr request
    public class PunchoutServiceRequest{
        @auraEnabled public String payLoadId;
        @auraEnabled public String version;
        @auraEnabled public String timeStamp;
        @auraEnabled public String lang;
        @auraEnabled public String fromCredentialDomain;
        @auraEnabled public String fromCredentialIdentity;
        @auraEnabled public String toCredentialDomain;
        @auraEnabled public String toCredentialIdentity;
        @auraEnabled public String toDomain;
        @auraEnabled public String toIdentity;
        @auraEnabled public String senderCredentialDomain;
        @auraEnabled public String senderIdentity;
        @auraEnabled public String senderSharedSecret;
        @auraEnabled public String buyerCookie;
        @auraEnabled public String firstName;
        @auraEnabled public String lastName;
        @auraEnabled public String uniqueName;
        @auraEnabled public String userEmail;
        @auraEnabled public String browserFormPost;
        @auraEnabled public String selectedItem;
        @auraEnabled public String supplierPartId;
        @auraEnabled public String locale;
        @auraEnabled public String currencyCode;
        @auraEnabled public String countryCode;
        @auraEnabled public String emailEncodingKey;
        @auraEnabled public String timezoneSidKey;
        @auraEnabled public String country;
        @auraEnabled public String punchoutFormat;
        @auraEnabled public String accountId;

        @auraEnabled public Boolean isTestUser;
        @auraEnabled public Boolean isNewUser;
    }
    
    //poom requests
    public class PunchoutOrder{
        
    }

}