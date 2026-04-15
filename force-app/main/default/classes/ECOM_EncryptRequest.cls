/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*	  - ECOM-1020
*
*
* 2. Description - This is a model class for POSR request to be encrypted
*				 - This class provides a model for POSR Request values to be mapped
*
*
* 3. Objects referenced
*	 - None ( Used for mapping POSR values)
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_EncryptRequestFlowController
*
* 6. Test Class Name: 
*    - ECOM_EncryptRequestFlowController_Test
*
* 7. Is @Invocable: No
*
* 8. Author Name(s):
*    - Vasudev Ramachandran 18 Dec 2023
*************************************************************/
public class ECOM_EncryptRequest {

   //@InvocableVariable @auraEnabled public String payLoadId;
	//@auraEnabled public String 
    @InvocableVariable @auraEnabled public String payLoadId;
    @InvocableVariable @auraEnabled public String version;
    @InvocableVariable @auraEnabled public String timeStamp;
    @InvocableVariable @auraEnabled public String lang;
    @InvocableVariable @auraEnabled public String fromCredentialDomain;
    @InvocableVariable @auraEnabled public String fromCredentialIdentity;
    @InvocableVariable @auraEnabled public String toIdentity;
    @InvocableVariable @auraEnabled public String toDomain;
    @InvocableVariable @auraEnabled public String senderCredentialDomain;
    @InvocableVariable @auraEnabled public String senderIdentity;
    @InvocableVariable @auraEnabled public String senderSharedSecret;
    @InvocableVariable @auraEnabled public String buyerCookie;
    @InvocableVariable @auraEnabled public String firstName;
    @InvocableVariable @auraEnabled public String lastName;
    @InvocableVariable @auraEnabled public String uniqueName;
    @InvocableVariable @auraEnabled public String userEmail;
    @InvocableVariable @auraEnabled public String browserFormPost;
    @InvocableVariable @auraEnabled public String selectedItem;
    @InvocableVariable @auraEnabled public String supplierPartId;
    @InvocableVariable @auraEnabled public String locale;
    @InvocableVariable @auraEnabled public String currencyCode;
    @InvocableVariable @auraEnabled public String countryCode;
    @InvocableVariable @auraEnabled public String emailEncodingKey;
    @InvocableVariable @auraEnabled public String timezoneSidKey;
    
        
    
}