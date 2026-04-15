/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM - 116
*
* 2. Description - This is a interface for Contact specific transactions.
*
* 3. Objects referenced
*    -Contact
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
* 5. Dependant Class(es):
*    - ECOM_ContactService
*
* 6. Test Class Name: ECOM_ContactService_Test
*
* 7. Is @Invocable: No
*
* 8. Author Name(s):
*    - Manish 2023.08.17
*	 - vramachandran@rafter.one | 11 Dec 2023
*	 - sathiya 2024.05.13 for ECOM-1939 added overload methods
*************************************************************/
public interface ECOM_IContactService {
    
    Contact getContactDetails(String contactId);
    void saveAdditionalShippingInfo(Contact contact);
    void saveOrUpdate(List<ECOM_Email_Preferences__c> listEP);
	List<ECOM_Email_Preferences__c> getEmailPreferences(String effectiveAccountId);
    String makeAccountActive(Contact con, String accId, String shipToId, String billToId, String invoiceErpId);
    String makeAccountActive(Contact contact, String accId, String shipToId, String billToId, String invoiceErpId, String addressRegistration, String attentionRecipient);
    String makeAccountActive(Contact contact, String accId, String soldToId, String shipToId, String billToId, String invoiceErpId, String addressRegistration, String attentionRecipient);
    Contact getContactRecordForEmail(String contactEmail);//VRa: Punchout changes

}