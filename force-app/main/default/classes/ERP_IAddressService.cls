/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM- 928
*	 ECOM- 950
*
* 2. Description - This class is used for ERP Address specific transactions like fetch, insert and update.
*
* 3. Objects referenced
*    - ERP Address
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
* 5. Dependant Class(es):
*    - ECOM_AccounstsController
*
* 6. Test Class Name: 
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Rani Thumma 2023.10.12
*    - Mahesh 2025.10.8 Updated method fetchERPAddressesBySapNumber - added disabledAddresses in parameter- RWPS-4498
*************************************************************/
public interface ERP_IAddressService {
    
    List<ECOM_MyAccountModel> fetchERPAddresses(User user);
    Map<Id,ERP_Address__c> getTargetId(Set<String> erpIds);
    List<ERP_Address__c> upsertERPAddresses(List<ERP_Address__c> erpAddresses);
    List<ECOM_MyAccountModel> fetchERPAddressesByDomain(User user, String contactDomain, String salesOrg);
    List<ECOM_MyAccountModel> fetchERPAddressesBySoldTo(User user, String contactId, String soldToSAPNumber, String contactDomain);
    List<ERP_Address__c> fetchERPAddressesBySapNumber(String contactId, List<String> sapNumbers,List<String> addressTypes, String salesOrg);
    List<ERP_Address__c> fetchERPAddressesBySapNumber(String contactId, List<String> sapNumbers,List<String> addressTypes, String salesOrg,
    String domain, List<String> disabledAddresses); // RWPS-4498
    List<ERP_Address__c> fetchERPAddressesById(String erpId);
    List<ECOM_MyAccountModel> fetchERPAddressesByContact(User user);
    List<ERP_Address__c>  getErpAddressBasedOnContactIdAndAddressType(String contactId,List<String> accountAddresses);
    List<ERP_Address__c>  getErpAddressBasedOnContactIdAddressTypeAndMasterId(String contactId,List<String> accountAddresses,String masterId);
    List<ERP_Address__c>  getErpAddressBasedOnContactIdAddressTypeAndMasterIds(String contactId,List<String> accountAddresses,Set<String> masterId);
    List<ERP_RelationShip__c> fetchERPRelationshipsByERPAddress(String contactId, String erpAddId);
    
    //ERP_AddressModel getERPAddressModelForPunchoutUser(User userRecord);//VRa-punchout changes
    //Boolean isPunchoutMasterERPAddressExists(String accountUniqueName);//VRa-punchout changes
    //ERP_AddressModel getERPAddressModelForPunchoutAccountUniqueName(String accountUniqueName, String countryName);//VRa-Punchout changes
    //ERP_AddressModel getERPAddressModelForPunchoutAccountId(String accountId);//VRa-Punchout changes @deprecated
    
    ERP_AddressModel getMasterERPAddressModelForPunchoutUser(User userRecord);//VRa-punchout changes
    ERP_AddressModel getPunchoutAddressesForERPAddressModel(String poAccountUniqueName);//VRa-punchout changes - 15 Jan 2024

   //  ERP_AddressModel getERPAddressModelForAccountId(String accountId);//VRa-punchout changes - 16 Jan 2024
}