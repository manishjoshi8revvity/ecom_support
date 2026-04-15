/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-928
*
* 2. Description - This class is used as to represent ECOM My Account model used on My account UI
*
* 3. Objects referenced
*   - ERP Address
* 	- Account
* 	- Contact
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
*    - Rani Thumma 2023.10.11
*    - Sidak Singh 2024.05.02 Added showAccNumber. Ticket RWPS-564
*************************************************************/
public class ECOM_MyAccountModel {
    
    //Sold To details
    @AuraEnabled public String externalId;//SAP customer id -001
    @AuraEnabled public String accountId;
    @AuraEnabled public String customerNumber;
    @AuraEnabled public String erpAccountName;
    @AuraEnabled public Boolean isSelected;
    @AuraEnabled public Boolean isAddNewAddress;// to show add address button or not
    @AuraEnabled public Boolean showAccNumber;// to show add account number or not
    @AuraEnabled public String contactId;
    //Added by Vipul
    @AuraEnabled public ERP_AddressModel soldToAddress;
    @AuraEnabled public List<ERP_AddressModel> erpAddresses;
   

}