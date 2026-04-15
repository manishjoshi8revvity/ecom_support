/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-116
*    ECOM-118
*
* 2. Description - This class is used for contact specific transations.
				- get/save Shipping & Billing Information from Contact.
				- return and Save account and account details
				- convert the String/Json to contact Object, then update the Contact Object
                - compare the account and cart currencies, if they are different then delete the Cart
*
* 3. Objects referenced
*    - contact
*    - ECOM_Email_Preferences__c
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
* 5. Dependant Class(es):
*    - ECOM_CheckoutController
*    - ECOM_ContactRepo
*    - ECOM_AccountWrapper
* 6. Test Class Name:
*    - ECOM_ContactService_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Manish 2023.08.17
*    - vramachandran@rafter.one | 11 Dec 2023
*    - Sidak 2024.04.05 - Added logic to compare Account & Cart currency in makeAccountActive methods - RWPS-419
*    - Sidak 2024.04.09 - Updated logic to compare Account & Cart currency in makeAccountActive methods - RWPS-419
*	 - sathiya 2024.05.16 - Added changes to makeAccountActive methods and related methods to accomodate Invoice Mailing Address - ECOM-1939
*    - Gaurang 2024.06.03 - Added method for creating login activity - ECOM-128
*    - Sidak 2024.06.27 - Updated logic to delete existing carts for the account which is selected in makeAccountActive methods - RWPS-310
*    - Sidak 2024.07.03 - Updated logic to fetch Contact in makeAccountActive methods
*    - Sidak 2024.07.30 - Added method saveRegistrationInfo - To save the registration info. Ticket - RWPS-1123
*    - Sidak 2024.08.05 - Updated logic to update Address registration on Contact in makeAccountActive methods. Ticket - ECOM-3528
*    - Manoj 2024.08.16 - Change datatype for ECOM_Registration_Info__c Ticket - RWPS-1324
*    - Sidak 2024.11.07 - Added method saveAccountNumber - To save the account number. Ticket - RWPS-1520
*************************************************************/
public without sharing class ECOM_ContactService implements ECOM_IContactService {

    /**
    * @description  Method to get Shipping & Billing Information from Contact.
    * @author Manish 2023.08.17
    * @return Contact 
    **/
    public static Contact getContactDetails(String contactId){
        Contact contact = ECOM_ContactRepo.getContactBasedOnId(contactId);
        return contact;
    }

    /**
    * @description  Method to save Additional Shipping Information.
    * @author Manish 2023.08.17
    * @param deliveryDetails
    * @param attentionRecipient
    * @param specialInstructions
    * @return Map<String,Object>
    **/
    public void saveAdditionalShippingInfo(Contact contact){
        //Map<String,Object> responseMap = new  Map<String,Object>();
        //Contact updatedContact = ECOM_ContactRepo.updateAdditionalShippingInfo(contact);
        //return updatedContact;
        ECOM_ContactRepo.updateAdditionalShippingInfo(contact);
    }
    
    /**
    * @description  Method to save or update email preferences.
    * @author Manish 2023.08.24
    * @param List<ECOM_Email_Preferences__c>
    **/
    public void saveOrUpdate(List<ECOM_Email_Preferences__c> listEP){
        ECOM_ContactRepo.upsertEmailPreferences(listEP);
    }
    
    /**
    * @description  Method to save or update email preferences.
    * @author Manish 2023.08.24
    * @param erpAddressId
    * @return List<ECOM_Email_Preferences__c>
    **/
    public List<ECOM_Email_Preferences__c> getEmailPreferences(String erpAddressId){
        List<ECOM_Email_Preferences__c> listEmailPreferences = ECOM_ContactRepo.getEmailPreferences(erpAddressId);
        return listEmailPreferences;
    }

    /**
    * @description  Method to get all email preferences.
    * @author Manish 2023.10.27
    * @param erpAddressId
    * @param conId
    * @return List<ECOM_Email_Preferences__c
    **/
    public List<ECOM_Email_Preferences__c> getEmailPreferencesByUser(String erpAddressId, String conId){
        List<ECOM_Email_Preferences__c> listEmailPreferences = ECOM_ContactRepo.getEmailPreferencesForCurrentUser(erpAddressId, conId);
        return listEmailPreferences;
    }

    /**
    * @description  get address details
    * @author mkumar@rafter.one | 09-21-2023 
    * @param contactId 
    * @return Map<String, Object> 
    **/
    /*public static Map<String,Object> getAddressDetails(String contactId)
    {
        Map<String,Object> returnMap=new Map<String,Object>();
        try 
        {
            Contact con=ECOM_ContactRepo.getContactBasedOnId(contactId);
            returnMap.put('contact',con);
            returnMap.put('accountSelected',true);
            if(String.isNotBlank(con.ECOM_AddressRegistration__c))
            {
                if(con.ECOM_AddressRegistration__c.equalsIgnoreCase('Select ST & BT'))
                {
                    returnMap.put('accountSelected',false);
                    List<Account> accs=ECOM_AccountRepo.getAccountBasedOnDomainsAndCountry(con.fxDomain__c,con.ECOM_CountryProvided__c);
                    returnMap.put('topHierarchyAccounts',accs);
                }
                returnMap.put('selectedAccountNumber',con.Account.SAP_Customer_Number_Formatted__c);
            }
        }catch (Exception e) {
            returnMap.put('Success',false);
            returnMap.put('ErrorMessage',e.getStackTraceString());
        }
        
        return returnMap;
    }*/


    /**
    * @description  Save account and get account details
    * @author mkumar@rafter.one | 09-21-2023 
    * @param accountId 
    * @param con 
    * @return Map<String, Object> 
    **/
    @AuraEnabled
    public static Map<String,Object> saveAccountAndGetDetails(String accountId,Contact con){
        Map<String,Object> returnMap=new Map<String,Object>();
        if(con.AccountId!=accountId)
        {
            con.AccountId=accountId;
            con.ECOM_DefaultShipToAccount__c=accountId;
            con.ECOM_DefaultBillToAccount__c=null;
            con.ECOM_DefaultInvoiceToAccount__c=null;
            con.ECOM_Attention_Recipient__c='';
            con.ECOM_DefaultShipToCPA__c=null;
            con.ECOM_DefaultBillToCPA__c=null;
        }
        if(con.ECOM_AddressRegistration__c.equalsIgnoreCase('Select ST & BT'))
            con.ECOM_AddressRegistration__c='Select BT';
        ECOM_ContactRepo.updateContact(con);
        con = ECOM_ContactRepo.getContactBasedOnId(con.Id);
        returnMap.put('contact',con);
        return returnMap;
    }

    /**
    * @description  check is contcat is mapped 
    * @author mkumar@rafter.one | 09-21-2023 
    * @param contactId 
    * @return Boolean 
    **/
    public Static Boolean getIsMapped(String contactId)
    {
        Contact con = ECOM_ContactRepo.getContactBasedOnId(contactId);
        return con.ECOM_Is_Mapped__c;
    }

    /**
    * @description  get with related accounts
    * @author mkumar@rafter.one | 09-21-2023 
    * @return List<ECOM_AccountWrapper.AccountDetails> 
    **/
    /*public static List<ECOM_AccountWrapper.AccountDetails> getAllRelatedAccount(){
        List<ECOM_AccountWrapper.AccountDetails> accountWrappers = new List<ECOM_AccountWrapper.AccountDetails>();
        Contact currentContact = ECOM_ContactRepo.getContactByOwner();
        accountWrappers = ECOM_AccountUtil.getAccountDetails(currentContact.Id, currentContact.AccountId, false);
        system.debug('getAllRelatedAccount debug: '+accountWrappers);
        return accountWrappers;
    }*/


    /**
    * @description 
    * @author mkumar@rafter.one | 09-21-2023 
    * @return Contact 
    **/
    public static Contact getAccountContactInfo(){
        Contact currentContact = ECOM_ContactRepo.getContactByOwner();
        return currentContact;
    }

    /**
    * @description 
    * @author mkumar@rafter.one | 09-21-2023 
    * @param conId 
    * @return Contact 
    **/
    public static Contact getAccountContactInfoById(String conId){
        Contact currentContact = ECOM_ContactRepo.getContactBasedOnId(conId);
        return currentContact;
    }



    

    /**
    * @description  update cart default erp address and account
    * @author mkumar@rafter.one | 02-21-2024 
    * @param webcarts 
    * @param accountId 
    * @param billTo 
    * @param shipTo 
* @param invoiceErpId
    * @return List<WebCart> 
    **/
    public static List<WebCart> updateAssociatedCarts(List<WebCart> webcarts,String accountId, String billTo, String shipTo, String invoiceErpId){
        for(WebCart webcart:webcarts)
        {
            webcart.AccountId = accountId;
// Change by sathiya to check for address type to do update on contact
            webcart.Default_Invoice_ERP_Address__c = invoiceErpId;
            // Changes End
            webcart.Default_Bill_To_ERP_Address__c=billTo;
            webcart.Default_Ship_To_ERP_Address__c=shipTo;
        }
        if(!webcarts.isEmpty())
        {
            ECOM_CartRepo.updateCart(webcarts);
        }
        return webcarts;
    }


    /**
    * @description  Make account active or switch account
    *               Updated logic to compare cart & account currencies
    * @author mkumar@rafter.one | 09-21-2023 
    *         ssingh@rafter.one | 04-05-2024 | Ticket: RWPS-419
    *         ssingh@rafter.one | 04-09-2024 | Ticket: RWPS-419
    *         ssingh@rafter.one | 06-27-2024 | Ticket: RWPS-310
    *         ssingh@rafter.one | 08-05-2024 | Ticket: ECOM-3528
    * @param accId 
    * @param shipToId 
    * @param billToId 
    * @return String 
    **/
    public static String makeAccountActive(Contact contact, String accId, String shipToId, String billToId, String invoiceErpId){
        List<String> accIdList = new List<String>();
        accIdList.add(accId);
        String result;
        List<Account> accList = ECOM_AccountRepo.getAccountBasedOnIds(accIdList);
        String accCurrency = accList[0].CurrencyIsoCode;
        List<WebCart> webcarts = ECOM_CartRepo.getPrimaryCartBasedOnOwner(UserInfo.getUserId());
        Contact con = ECOM_ContactRepo.getContactBasedOnId(contact.Id);

        if(accId != null && con.AccountId != accId){
            con.AccountId = accId;
            List<WebCart> existingCarts = ECOM_CartRepo.getCartsBasedOnOwnerAndAccount(UserInfo.getUserId(), accId);
            ECOM_CartRepo.deleteCart(existingCarts);
        }
        //Ship to changes when account is switched
        billToId = String.isBlank(billToId.trim())?null:billToId;
        invoiceErpId = String.isBlank(invoiceErpId.trim())?null:invoiceErpId;
        con.Default_Invoice_ERP_Address__c = invoiceErpId;
        if(String.isNotBlank(shipToId) && String.isNotBlank(billToId)){ //ECOM-3528
            con.Default_Ship_to_ERP_Address__c = shipToId;
            con.Default_Bill_to_ERP_Address__c = billToId;
            con.ECOM_AddressRegistration__c = 'Completed';
        }
        con.ECOM_NeedsVerification__c = true;

        //con.ECOM_Is_Mapped__c = true;
        result = ECOM_ContactRepo.updateContactAccount(con);
        String cartCurrency =  webcarts.size() > 0 ? webCarts[0].CurrencyIsoCode : '';// setting default value empty if no cart available
        if(accCurrency != cartCurrency){// don't perform delete if cartCurrency is blank
            ECOM_CartRepo.deleteCart(webcarts);
        }else if(String.isNotBlank(cartCurrency)){
            updateAssociatedCarts(webcarts,accId,billToId,shipToId, invoiceErpId);
        }
        return result;
    }

    /**
    * @description  Make account active or switch account
    *               Updated logic to compare cart & account currencies
    * @author mkumar@rafter.one | 09-21-2023 
    *         ssingh@rafter.one | 04-05-2024 | Ticket: RWPS-419
    *         ssingh@rafter.one | 04-09-2024 | Ticket: RWPS-419
    *         ssingh@rafter.one | 06-27-2024 | Ticket: RWPS-310
* @param contact
    * @param accId 
* @param soldToId 
    * @param shipToId 
    * @param billToId 
* @param invoiceErpId
    * @param addressRegistration 
    * @param attentionRecipient
    * @return String 
    **/
    public static String makeAccountActive(Contact contact, String accId, String soldToId, String shipToId, String billToId, String invoiceErpId, String addressRegistration, String attentionRecipient){
        List<String> accIdList = new List<String>();
        accIdList.add(accId);
        String result;
        List<Account> accList = ECOM_AccountRepo.getAccountBasedOnIds(accIdList);
        String accCurrency = accList[0].CurrencyIsoCode;
        List<WebCart> webcarts = ECOM_CartRepo.getPrimaryCartBasedOnOwner(UserInfo.getUserId());
        Contact con = ECOM_ContactRepo.getContactBasedOnId(contact.Id);

        if(accId != null && con.AccountId != accId){
            con.AccountId = accId;
            List<WebCart> existingCarts = ECOM_CartRepo.getCartsBasedOnOwnerAndAccount(UserInfo.getUserId(), accId);
            ECOM_CartRepo.deleteCart(existingCarts);
        }
        if(String.isNotBlank(addressRegistration))
        {
            con.ECOM_AddressRegistration__c=addressRegistration;
        }
        if(String.isNotBlank(attentionRecipient))
        {
            con.ECOM_Attention_Recipient__c=attentionRecipient;
        }
        //Ship to changes when account is switched
        if(String.isNotBlank(soldToId))
        {
            con.Default_Sold_to_ERP_Address__c=soldToId;
        }
        // Change by sathiya to check for address type to do update on contact
        //billToId = String.isBlank(billToId.trim())?null:billToId; //VRa Change to fix null issue( isBlank checks for whitespace, removing .trim() as it will throw null pointer if id is empty)
        billToId = String.isBlank(billToId)?null:billToId;
        //invoiceErpId = String.isBlank(invoiceErpId.trim())?null:invoiceErpId;//VRa Change to fix null issue( isBlank checks for whitespace, removing .trim() as it will throw null pointer if id is empty)
        invoiceErpId = String.isBlank(invoiceErpId)?null:invoiceErpId;
        con.Default_Invoice_ERP_Address__c = invoiceErpId;
        // Change End
        if(String.isNotBlank(shipToId) && String.isNotBlank(billToId)){ //ECOM-3528
            con.Default_Ship_to_ERP_Address__c = shipToId;
            con.Default_Bill_to_ERP_Address__c = billToId;
            con.ECOM_AddressRegistration__c = 'Completed';
        }
        con.ECOM_NeedsVerification__c = true; //Doubt : it might not be true always.
        //con.ECOM_AddressRegistration__c = 'Complete';
        //con.ECOM_Is_Mapped__c = true;
        result = ECOM_ContactRepo.updateContactAccount(con);
        String cartCurrency =  webcarts.size() > 0 ? webCarts[0].CurrencyIsoCode : '';// setting default value empty if no cart available
        if(accCurrency != cartCurrency){// don't perform delete if cartCurrency is blank
            ECOM_CartRepo.deleteCart(webcarts);
        }else if(String.isNotBlank(cartCurrency)){
            updateAssociatedCarts(webcarts,accId,billToId,shipToId, invoiceErpId);
        }
        return result;
    }
    
        /**
        * @description Make account active or switch account
        *               Updated logic to compare cart & account currencies
        * @author mkumar@rafter.one | 02-21-2024 
        *         ssingh@rafter.one | 04-05-2024 | Ticket: RWPS-419
        *         ssingh@rafter.one | 04-09-2024 | Ticket: RWPS-419
        *         ssingh@rafter.one | 06-27-2024 | Ticket: RWPS-310
        *         ssingh@rafter.one | 07-03-2024
        *         ssingh@rafter.one | 08-05-2024 | Ticket: ECOM-3528
        * @param contact 
        * @param accId 
        * @param shipToId 
        * @param billToId 
* @param invoiceErpId
        * @param addressRegistration 
        * @param attentionRecipient 
        * @return String 
        **/
        public static String makeAccountActive(Contact contact, String accId, String shipToId, String billToId, String invoiceErpId, String addressRegistration, String attentionRecipient){
            List<String> accIdList = new List<String>();
            accIdList.add(accId);
            String result;
            List<Account> accList = ECOM_AccountRepo.getAccountBasedOnIds(accIdList);
            String accCurrency = accList[0].CurrencyIsoCode;
            List<WebCart> webcarts = ECOM_CartRepo.getPrimaryCartBasedOnOwner(UserInfo.getUserId());
            Contact con = ECOM_ContactRepo.getContactBasedOnId(contact.Id);

            if(accId != null && con.AccountId != accId){
                con.AccountId = accId;
                List<WebCart> existingCarts = ECOM_CartRepo.getCartsBasedOnOwnerAndAccount(UserInfo.getUserId(), accId);
                ECOM_CartRepo.deleteCart(existingCarts);
            }
            if(String.isNotBlank(addressRegistration))
            {
                con.ECOM_AddressRegistration__c = addressRegistration;
            }
            if(String.isNotBlank(attentionRecipient))
            {
                con.ECOM_Attention_Recipient__c = attentionRecipient;
            }
            con.Default_Sold_to_ERP_Address__c = null;
            // Change by sathiya to check for address type to do update on contact
            billToId = String.isBlank(billToId.trim())?null:billToId;
            invoiceErpId = String.isBlank(invoiceErpId.trim())?null:invoiceErpId;
            con.Default_Invoice_ERP_Address__c = invoiceErpId;
            // Change End
            if(String.isNotBlank(shipToId) && String.isNotBlank(billToId)){ //ECOM-3528
                con.Default_Ship_to_ERP_Address__c = shipToId;
                con.Default_Bill_to_ERP_Address__c = billToId;
                con.ECOM_AddressRegistration__c = 'Completed';
            }
            con.ECOM_NeedsVerification__c = true; 
            result = ECOM_ContactRepo.updateContactAccount(con);
            String cartCurrency =  webcarts.size() > 0 ? webCarts[0].CurrencyIsoCode : '';// setting default value empty if no cart available
            if(accCurrency != cartCurrency){// don't perform delete if cartCurrency is blank
                ECOM_CartRepo.deleteCart(webcarts);
            }else if(String.isNotBlank(cartCurrency)){
                updateAssociatedCarts(webcarts,accId,billToId,shipToId, invoiceErpId);
            }
            return result;
    }

    /**
    * @description  save contact data
    * @author mkumar@rafter.one | 09-21-2023 
    * @param con 
    * @return Map<String, Object> 
    **/
    @AuraEnabled
    public static Map<String,Object> saveContact(Contact con){
        Map<String,Object> returnMap=new Map<String,Object>();
        Contact contact = ECOM_ContactRepo.updateContact(con);
        contact=ECOM_ContactRepo.getContactBasedOnId(con.Id);
        returnMap.put('Success',true);
        returnMap.put('Contact',contact);
        return returnMap;
    }
    
    /*public static String saveBillingAddress(String contactId, String billingAccount){
        String result = ECOM_ContactRepo.updateBillingAccountOnContact(contactId, billingAccount);
        return result;
    }*/

    /**
    * @description  update default billing address
    * @author mkumar@rafter.one | 09-21-2023 
    * @param contactId 
    * @param billingAccount 
    **/
    /*public static void updateDefaultBillingAddress(String contactId, String billingAccount){
        ECOM_ContactRepo.updateDefaultBillingAccount(contactId, billingAccount);
        ECOM_ContactRepo.updateCartDefaultAddress(billingAccount);
    }*/

    /**
    * @description  upsert billing CPA 
    * @author mkumar@rafter.one | 09-21-2023 
    * @param cpas 
    * @param contactId 
    * @return Contact 
    **/
    /*public static Contact upsertBillingCPA(ContactPointAddress cpas,String contactId){
        Contact con=new Contact();
        con.Id=contactID;
        con.ECOM_DefaultBillToAccount__c=null;
        con.ECOM_DefaultBillToCPA__c=cpas.Id;
        con.ECOM_NeedsVerification__c=true;
        ECOM_ContactRepo.updateContact(con);
        con = ECOM_ContactRepo.getContactBasedOnId(con.Id);
        return con;
    }*/

    /**
    * @description 
    * @author mkumar@rafter.one | 09-21-2023 
    * @param ex 
    * @return Map<String, Object> 
    **/
    public static Map<String,Object> createErrorMap(Exception ex){
        Map<String,Object> returnMap=new Map<String,Object>();
        returnMap.put('Success',false);
        returnMap.put('ErrorMessage',ex.getStackTraceString());
        System.debug('exception ==> '+ex.getStackTraceString());
        return returnMap;
    }

    // public static Contact saveContact(Contact con){
    //     Contact contact = ECOM_ContactRepo.updateContact(con);
    //     return contact;
    // }

    /**
    * @description This method is used to convert the String/Json to contact Object, then update the Contact Object
    * @author Dar Wright | 09-05-2023 
    * @param changesList
    **/
    @AuraEnabled
    public static void changeStringToContact(String conList) { 

        List<Object> conUpdates = (List<Object>)JSON.deserializeUntyped(conList);
        Contact con = new Contact();
        for(Object cObj : conUpdates ){
            Map<String, Object> conData = (Map<String, Object>)cObj;
            con.Id = (Id)conData.get('Id');
            con.Phone = (String)conData.get('Phone');
            con.ECOM_Phone_Extension__c= (Decimal)conData.get('ECOM_Phone_Extension__c');
            con.ECOM_Attention_Recipient__c = (String)conData.get('ECOM_Attention_Recipient__c');
            con.ECOM_Special_Instructions__c = (String)conData.get('ECOM_Special_Instructions__c');
            con.ECOM_Delivery_Details__c = (String)conData.get('ECOM_Delivery_Details__c');
        }    

        try{
            ECOM_ContactRepo.updateContact(con);
        } catch(DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }


    }

    /**
    * @description get default store  path
    * @author mkumar@rafter.one | 09-21-2023 
    * @param con 
    * @return Map<String, Object> 
    **/
    public static Map<String,Object> getDefaultStoreFrontPath(Contact con)
    {
        Map<String,Object> returnMap=new Map<String,Object>();
        if(String.isNotBlank(con.ECOM_AddressRegistration__c) && !con.ECOM_AddressRegistration__c.equalsIgnoreCase('Completed'))
        {
            returnMap.put('defaultPathForAddressRegistration','/dashboard');
            if(con.ECOM_AddressRegistration__c.equalsIgnoreCase('Populate ST & BT'))
            {
                returnMap.put('addressAction','addressStatus=addAddress');
            }
            else if(con.ECOM_AddressRegistration__c.equalsIgnoreCase('Select ST & BT') || con.ECOM_AddressRegistration__c.equalsIgnoreCase('Select BT'))
            {
                returnMap.put('addressAction','addressStatus=selectAddress');
            }
        }
        return returnMap;
    }

    /**
    * @description  get current contact CPA 
    * @author mkumar@rafter.one | 09-21-2023 
    * @param contactId 
    * @param accId 
    * @return List<ECOM_AccountWrapper.AccountDetails> 
    **/
    /*public static List<ECOM_AccountWrapper.AccountDetails> getCPAForCurrentContact(String contactId, String accId){
        //Contact userContact=ECOM_ContactRepo.getContactBasedOnId(contactId);
        List<ECOM_AccountWrapper.AccountDetails> accountDetails=new List<ECOM_AccountWrapper.AccountDetails>();
        //accountDetails=ECOM_AccountUtil.getCPA(userContact);
        //return accountDetails;
        for(ContactPointAddress cpa : ECOM_AccountService.getCPAForContact(contactId)){
            if(cpa.AddressType == 'Billing' && accId == cpa.ParentId){
                ECOM_AccountWrapper.AccountDetails accountDetail = new ECOM_AccountWrapper.AccountDetails();
                accountDetail.accountId=cpa.Id;
                accountDetail.sapAccountNumber=cpa.Account_Number_Formatted__c;
                ECOM_AccountWrapper.BillingDetails billingDetails= new ECOM_AccountWrapper.BillingDetails ();
                billingDetails.billToId=cpa.Id;
                billingDetails.billToName=cpa.CompanyName;
                billingDetails.billToStreet=cpa.Street;
                billingDetails.billToState=cpa.State;
                billingDetails.billToCity=cpa.City;
                billingDetails.billToCountry=cpa.Country;
                billingDetails.billToPostalCode=cpa.PostalCode;
                accountDetail.billToDetails.add(billingDetails);
                accountDetail.isCPA = true;
                accountDetails.add(accountDetail);
            }
        }
        return accountDetails;
    }*/

    /**
    * @description  Prepare account Billing and Shipping address
    * @author mkumar@rafter.one | 09-21-2023 
    * @param acr 
    * @param con 
    * @return ECOM_AccountWrapper.AccountDetails 
    **/
    /*public static ECOM_AccountWrapper.AccountDetails prepareActiveAccountAddress(ECOM_AccountWrapper.AccountDetails acr, Contact con){
        //Billing Address
        acr.billToDetails[0].billToId = con.ECOM_DefaultBillToAccount__c;
        acr.billToDetails[0].billToName = con.ECOM_DefaultBillToAccount__r.Name;
        acr.billToDetails[0].billToStreet = con.ECOM_DefaultBillToAccount__r.BillingStreet;
        acr.billToDetails[0].billToState = con.ECOM_DefaultBillToAccount__r.BillingState;
        acr.billToDetails[0].billToCity = con.ECOM_DefaultBillToAccount__r.BillingCity;
        acr.billToDetails[0].billToCountry = con.ECOM_DefaultBillToAccount__r.BillingCountry;
        acr.billToDetails[0].billToPostalCode = con.ECOM_DefaultBillToAccount__r.BillingPostalCode;
        //Shipping Address
        acr.shipToDetails[0].shipToId = con.ECOM_DefaultShipToAccount__c;
        acr.shipToDetails[0].shipToName = con.ECOM_DefaultShipToAccount__r.Name;
        acr.shipToDetails[0].shipToStreet = con.ECOM_DefaultShipToAccount__r.ShippingStreet;
        acr.shipToDetails[0].shipToState = con.ECOM_DefaultShipToAccount__r.ShippingState;
        acr.shipToDetails[0].shipToCity = con.ECOM_DefaultShipToAccount__r.ShippingCity;
        acr.shipToDetails[0].shipToCountry = con.ECOM_DefaultShipToAccount__r.ShippingCountry;
        acr.shipToDetails[0].shipToPostalCode = con.ECOM_DefaultShipToAccount__r.ShippingPostalCode;
        return acr;
    }*/

    /**
    * @description  Prepare Contact Point Billing and Shipping address
    * @author mkumar@rafter.one | 09-21-2023 
    * @param acr 
    * @param con 
    * @return ECOM_AccountWrapper.AccountDetails 
    **/
    /*public static ECOM_AccountWrapper.AccountDetails prepareCPABillAndAccountShipAddress(ECOM_AccountWrapper.AccountDetails acr, Contact con){
        //Billing Address
        acr.billToDetails[0].billToId = con.ECOM_DefaultBillToCPA__c;
        acr.billToDetails[0].billToName = con.ECOM_DefaultBillToCPA__r.Name;
        acr.billToDetails[0].billToStreet = con.ECOM_DefaultBillToCPA__r.Street;
        acr.billToDetails[0].billToState = con.ECOM_DefaultBillToCPA__r.State;
        acr.billToDetails[0].billToCity = con.ECOM_DefaultBillToCPA__r.City;
        acr.billToDetails[0].billToCountry = con.ECOM_DefaultBillToCPA__r.Country;
        acr.billToDetails[0].billToPostalCode = con.ECOM_DefaultBillToCPA__r.PostalCode;
        //Shipping Address
        acr.shipToDetails[0].shipToId = con.ECOM_DefaultShipToAccount__c;
        acr.shipToDetails[0].shipToName = con.ECOM_DefaultShipToAccount__r.Name;
        acr.shipToDetails[0].shipToStreet = con.ECOM_DefaultShipToAccount__r.ShippingStreet;
        acr.shipToDetails[0].shipToState = con.ECOM_DefaultShipToAccount__r.ShippingState;
        acr.shipToDetails[0].shipToCity = con.ECOM_DefaultShipToAccount__r.ShippingCity;
        acr.shipToDetails[0].shipToCountry = con.ECOM_DefaultShipToAccount__r.ShippingCountry;
        acr.shipToDetails[0].shipToPostalCode = con.ECOM_DefaultShipToAccount__r.ShippingPostalCode;

        return acr;
    }*/


    public static Map<String,Object> getERPData(User us)
    {
        Map<String,Object> response = new Map<String,Object>();
        Type erpAddressService = Type.forName(ECOM_Constant.ERP_ADDRESS_SERVICE);
        ERP_IAddressService erpAddressServiceInstance = (ERP_IAddressService)erpAddressService.newInstance();
        List<ECOM_MyAccountModel> myAccountModels = new List<ECOM_MyAccountModel>();
        response.put('success',false);

        //Get all the data related to the selected sold to 
        Contact con=ECOM_ContactService.getAccountContactInfoById(us.ContactId);
        String salesOrg = ECOM_CustomMetadataService.getSalesOrg(us.Contact.ECOM_CountryProvided__c);
        List<ERP_Address__c> addresses = erpAddressServiceInstance.fetchERPAddressesById(con.Default_Sold_to_ERP_Address__c); 
        List<String> addressType=new List<String>{'Ship To'};
        List<String> sapNumbers=new List<String>{us.Contact.Default_Sold_to_ERP_Address__r.Master_Address__r.External_Id__c};
        addresses.addAll(erpAddressServiceInstance.fetchERPAddressesBySapNumber(String.valueOf(us.ContactId),sapNumbers, addressType, salesOrg)); 
        sapNumbers=new List<String>();
        for(ERP_Address__c add:addresses)
        {
            if(String.isNotBlank(add.Address_Type__c) && add.Address_Type__c.equalsIgnoreCase('Ship To') && String.isNotBlank(add.Target_Address__c))
            {
                sapNumbers.add(add.Target_Address__r.External_Id__c);
            }
        }
        if(!sapNumbers.isEmpty()){
            addressType = new List<String>{'Payer'};
            List<ERP_Address__c> payerAddresses = erpAddressServiceInstance.fetchERPAddressesBySapNumber(String.valueOf(us.ContactId),sapNumbers, addressType, salesOrg);
            if(!payerAddresses.isEmpty()){
                addresses.addAll(payerAddresses);
                List<String> billToMasters = new List<String>();
                for(ERP_Address__c payer: payerAddresses){
                    billToMasters.add(payer?.Id);
                    if(payer?.Target_Address__c != null){
                        billToMasters.add(payer?.Target_Address__c);
                    }
                }
                List<ERP_Address__c> invoiceAddresses = ERP_AddressRepo.fetchERPAddressesByMaster(billToMasters,new List<String>{'Bill To'},us.ContactId,salesOrg);
                addresses.addAll(invoiceAddresses);
            }
        }
        myAccountModels=ERP_AddressUtil.convertERPAddressesToModel(addresses, us);
        response.put('countryProvided',con.ECOM_CountryProvided__c);
        response.put('isAccountSelected',true);
        response.put('address',myAccountModels);
        response.put('attentionRecipient',con.ECOM_Attention_Recipient__c);
        response.put('countryProvided',con.ECOM_CountryProvided__c);
        response.put('success',true);

        return response;
    }

    public static List<ERP_Address__c> getNewErpData(User us){
        Type erpAddressService = Type.forName(ECOM_Constant.ERP_ADDRESS_SERVICE);
        ERP_IAddressService erpAddressServiceInstance = (ERP_IAddressService)erpAddressService.newInstance();
        List<ERP_Address__c> erpAddresses=new List<ERP_Address__c>();
        erpAddresses=erpAddressServiceInstance.getErpAddressBasedOnContactIdAndAddressType(us.ContactId,new List<String>{'Ship To'});
        if(erpAddresses.size()>0)
        {
            erpAddresses.addAll(erpAddressServiceInstance.getErpAddressBasedOnContactIdAddressTypeAndMasterId(us.ContactId,new List<String>{'Payer'},erpAddresses[0].Id));
        }
        return erpAddresses;
    }

    public static void updateContact(Contact con)
    {
        try
        {
            ECOM_ContactRepo.updateContact(con);
        }catch(Exception e)
        {
            String supportData=JSON.serialize(con);
            ECOM_ApplicationLogsUtil.logFailure(e, ECOM_Constant.USER_MODULE_NAME, 'ECOM_ContactController', 'updateContact', supportData);
            throw e;
        }
    }

    public class DashboardWrapper{
        @AuraEnabled
        public Contact contact;
        @AuraEnabled
        public List<ECOM_AccountWrapper.AccountDetails> accountDetails;
    }
    
    
    /**
     * @description This method returns the contact record for a given contact email
     * @author vramachandran@rafter.one | 22 Dec 2023
     * @param contactEmail | String 
     * @returns Contact
     */
    public static Contact getContactRecordForEmail(String contactEmail){
        Contact contactRecord;
        List<Contact> contactRecordList = ECOM_ContactRepo.getContactForEmail(contactEmail);
        
        if(null != contactRecordList && !contactRecordList.isEmpty()){
            contactRecord = contactRecordList[0];
        }
        
        return contactRecord;
    }
    
    /**
     * @description This method returns a boolean flag to indicate if contact creation was successful
     * @author vramachandran@rafter.one | 22 Dec 2023
     * @param contactsList | List<Contact> 
     * @returns Boolean
     */
    public static Boolean insertNewContacts(List<Contact> newContactRecords){
       	Boolean isInsertSuccess = true;
        
       
        
        return isInsertSuccess;
    }

    /**
    * @description This method updated the registration info on Contact
    * @author ssingh@rafter.one | 29 Jul 2024 | RWPS-1123
    * @param contactId | String 
    * @returns void
    */
   public static void saveRegistrationInfo(String contactId,String shiptToId,String billToId,String attentionRecipient){
        Contact con = ECOM_ContactRepo.getContactBasedOnId(contactId);
        String regInfo = 'Account Name: ' + con.ECOM_AccountNameProvided__c + ', Ship To Id: ' + shiptToId + ', Ship To Address: ' + con.Default_Ship_to_ERP_Address__r.fxAddressFull__c  + ', Payer Id: ' + billToId + ', Payer Address: ' + con.Default_Bill_to_ERP_Address__r.fxAddressFull__c + ', Attention Line: ' + attentionRecipient;

        if(String.isBlank(con.ECOM_Registration_Info__c) && String.isNotBlank(shiptToId) && String.isNotBlank(billToId)){
        con.ECOM_Registration_Info__c = regInfo;
        ECOM_ContactRepo.updateContact(con);
        }
    }

    /**
    * @description This method updates the Account number on Contact
    * @author ssingh@rafter.one | 07 Nov 2024 | RWPS-1520
    * @param soldToSapNumber | String 
    * @param contactId | String 
    * @returns void
    */
   public static void saveAccountNumber(String soldToSapNumber, String contactId){
    Contact con = ECOM_ContactRepo.getContactBasedOnId(contactId);

    if(String.isNotBlank(soldToSapNumber)){
        con.ECOM_AccountNumberProvided__c = soldToSapNumber;
        ECOM_ContactRepo.updateContact(con);
    }
}


    /**
     * @description This method returns the contact fields to base user redirection
     * @author vramachandran@rafter.one | 23 May 2024 ECOM-1554
     * @param contactEmail | String
     * @returns Contact
     */
    public static String getRedirectionEndpointForContact(String contactEmail){
        String endPoint = '';
        
        Contact contactRecord = ECOM_ContactRepo.getContactFieldsForRedirection(contactEmail);
        System.debug('ContactRecord:: '+ contactRecord);
            
        if(null != contactRecord && String.isNotBlank(contactRecord?.ECOM_RegistrationPattern__c) ) {

            if(contactRecord?.ECOM_RegistrationPattern__c  == 'No Match' && contactRecord?.ECOM_AddressRegistration__c == 'Populate ST & BT') {
                endPoint = System.Label.ECOM_AddAddressPageEndpoint; //'dashboard?addressStatus=addAddress';
            } else if((contactRecord?.ECOM_RegistrationPattern__c  == 'Domain Match' || contactRecord?.ECOM_RegistrationPattern__c  == 'Complete Match') && contactRecord?.ECOM_AddressRegistration__c  != 'Completed' )  {
                endPoint = System.Label.ECOM_SelectAddressEndpoint;
            }
        }
        
		return endPoint;
    }

    /**
     * @description This method returns the contact fields to base user redirection
     * @author garora@rafter.one | 3 June 2024 ECOM-128
     * @param requestMap | Map<String,String>
     * @returns Map<String,String>
     */
    public static Map<String,String> createLoginActivity(Map<String,String> requestMap){
        Task loginActivity = new Task();
        loginActivity.Subject = UserInfo.getFirstName() + ' ' + UserInfo.getLastName()+ ' logged in as '+ requestMap.get('firstName') + ' ' + requestMap.get('lastName');
        loginActivity.Status = 'Completed';
        loginActivity.WhoId = requestMap.get('loggedInContactId');
        loginActivity.Type = 'Other';
        ECOM_ContactRepo.insertTask(loginActivity);
        return requestMap;
    }
}