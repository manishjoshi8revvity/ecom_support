/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM- 69   
*    ECOM-116
*    ECOM-118
*
* 2. Description - This class acts as a selector class for Contacts.
				- perform DML Operations
				- return List of Contact, ContactPointAddress
				- update, upsert Records
*
* 3. Objects referenced
*    -Contact
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
* 5. Dependant Class(es):
*    - ECOM_AccountUtil
*
* 6. Test Class Name: 
*    - ECOM_ContactRepo_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vipul 2023.07.25
*    - Manish 2023.08.17
*	 - Sathiya 2024.05.13 added fields for getContactBasedOnId
*    - Gaurang 2024.06.03 - Added method for creating task- ECOM-128
* 	 - Vasuedv 2024.06.05 - Added a new field on getContactForEmail method ECOM-2357
*    - Sidak 2024.05.27 Updated method getContactBasedOnId, added Default_Bill_To_ERP_Address__r.Target_Address__r.External_Id__c, Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c. Ticket RWPS-766
*    - Sidak 2024.07.30 Updated method getContactBasedOnId, added ECOM_Registration_Info__c, Default_Bill_to_ERP_Address__r.fxAddressFull__c, Default_Ship_to_ERP_Address__r.fxAddressFull__c. Ticket RWPS-1123
*    - Manoj 2024.08.16 - Change datatype for ECOM_Registration_Info__c Ticket - RWPS-1324
*    - Sidak 2024.11.11 Added ECOM_Is_Punchout_Contact__c, ECOM_isEnabled__c fields in query in getContactBasedOnId method. Ticket RWPS-1671
*    - Poonam 2025.07.18 Updated method getEmailPreferencesForCurrentUser - RWPS-3306
*************************************************************/
public class ECOM_ContactRepo {
    

    /**
    * @description  Method to get the contact information based on Id.
    * @author Vipul 2023.07.25
    * @author Sidak 2024.11.11
    * @author Sidak 2024.11.21 | RWPS-1773
    * @param contactId  String
    * @return Contact 
    **/
    public static Contact getContactBasedOnId(String contactId)
    {
        return [SELECT id,Name,Email,AccountId,Account.Name,Account.AccountNumber, ECOM_Attention_Recipient__c, ECOM_Delivery_Details__c, 
                ECOM_Special_Instructions__c,SAP_Contact_ID__c, Account.SAP_Customer_Number_Formatted__c, FirstName, LastName,
                ECOM_DefaultBillToAccount__c,
                ECOM_DefaultBillToAccount__r.Name,
                ECOM_DefaultBillToAccount__r.BillingStreet,ECOM_DefaultBillToAccount__r.BillingCity, 
                ECOM_DefaultBillToAccount__r.BillingState,ECOM_DefaultBillToAccount__r.BillingPostalCode,
                ECOM_DefaultBillToAccount__r.BillingCountry,ECOM_DefaultBillToAccount__r.ShippingStreet, ECOM_DefaultBillToAccount__r.ShippingCity, 
                ECOM_DefaultBillToAccount__r.ShippingState, ECOM_DefaultBillToAccount__r.ShippingPostalCode,
                ECOM_DefaultBillToAccount__r.ShippingCountry,ECOM_DefaultBillToAccount__r.AccountNumber, 
                ECOM_DefaultShipToAccount__c,ECOM_DefaultShipToAccount__r.Name,
                ECOM_DefaultShipToAccount__r.BillingStreet,ECOM_DefaultShipToAccount__r.BillingCity, 
                ECOM_DefaultShipToAccount__r.BillingState,ECOM_DefaultShipToAccount__r.BillingPostalCode,
                ECOM_DefaultShipToAccount__r.BillingCountry,ECOM_DefaultShipToAccount__r.ShippingStreet, ECOM_DefaultShipToAccount__r.ShippingCity, 
                ECOM_DefaultShipToAccount__r.ShippingState, ECOM_DefaultShipToAccount__r.ShippingPostalCode,
                ECOM_DefaultShipToAccount__r.ShippingCountry,ECOM_DefaultShipToAccount__r.AccountNumber,
                ECOM_AccountNameProvided__c, ECOM_NeedsVerification__c, ECOM_AccountNumberProvided__c, ECOM_AddressRegistration__c,
                fxDomain__c,ECOM_DefaultShipToAccount__r.SAP_Customer_Number_Formatted__c, ECOM_DefaultBillToAccount__r.SAP_Customer_Number_Formatted__c,
                ECOM_DefaultInvoiceToAccount__c,
                ECOM_DefaultInvoiceToAccount__r.Name,
                ECOM_DefaultInvoiceToAccount__r.BillingStreet,ECOM_DefaultInvoiceToAccount__r.BillingCity, 
                ECOM_DefaultInvoiceToAccount__r.BillingState,ECOM_DefaultInvoiceToAccount__r.BillingPostalCode,
                ECOM_DefaultInvoiceToAccount__r.BillingCountry,ECOM_DefaultInvoiceToAccount__r.ShippingStreet, ECOM_DefaultInvoiceToAccount__r.ShippingCity, 
                ECOM_DefaultInvoiceToAccount__r.ShippingState, ECOM_DefaultInvoiceToAccount__r.ShippingPostalCode,
                ECOM_DefaultInvoiceToAccount__r.ShippingCountry,ECOM_DefaultInvoiceToAccount__r.AccountNumber,
                ECOM_DefaultBillToCPA__c,ECOM_DefaultBillToCPA__r.Id,ECOM_DefaultBillToCPA__r.Name,
                ECOM_DefaultBillToCPA__r.CompanyName,
                ECOM_DefaultBillToCPA__r.City,ECOM_DefaultBillToCPA__r.Street,
                ECOM_DefaultBillToCPA__r.State,ECOM_DefaultBillToCPA__r.PostalCode,
                ECOM_DefaultBillToCPA__r.PhoneNumber,ECOM_DefaultBillToCPA__r.ECOM_Extn__c,
                ECOM_DefaultBillToCPA__r.Country,
                ECOM_DefaultShipToCPA__c,ECOM_DefaultShipToCPA__r.Id,ECOM_DefaultShipToCPA__r.Name,
                ECOM_DefaultShipToCPA__r.City,ECOM_DefaultShipToCPA__r.Street,
                ECOM_DefaultShipToCPA__r.State,ECOM_DefaultShipToCPA__r.PostalCode,
                ECOM_DefaultShipToCPA__r.PhoneNumber,ECOM_DefaultShipToCPA__r.ECOM_Extn__c,
                ECOM_DefaultShipToCPA__r.Country,
                ECOM_DefaultShipToCPA__r.CompanyName,
                ECOM_Is_Mapped__c,ECOM_CountryProvided__c,
                ECOM_Phone_Extension__c,
                Phone, 
                Default_Invoice_ERP_Address__c,
                Default_Invoice_ERP_Address__r.fxAddressFull__c,
                Default_Bill_to_ERP_Address__c,
                Default_Bill_to_ERP_Address__r.fxAddressFull__c,
                Default_Bill_to_ERP_Address__r.Master_Address__c,
                Default_Bill_to_ERP_Address__r.Master_Address__r.External_Id__c,
                Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c,
                Default_Bill_To_ERP_Address__r.fxAddress_CountryCode__c,
                Default_Ship_to_ERP_Address__c,
                Default_Ship_to_ERP_Address__r.fxAddressFull__c,
                Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c,
                Default_Ship_to_ERP_Address__r.Master_Address__c,
                Default_Ship_to_ERP_Address__r.Master_Address__r.External_Id__c,
                Default_Sold_to_ERP_Address__c,
                Default_Sold_to_ERP_Address__r.Master_Address__c,
                Default_Sold_to_ERP_Address__r.Master_Address__r.External_Id__c,
                ECOM_RegistrationPattern__c,ECOM_Registration_Info__c,ECOM_Is_Punchout_Contact__c,ECOM_isEnabled__c
                FROM Contact WHERE id=:contactId LIMIT 1];
    }


    /**
    * @description  Method to save Additional Shipping Information on Contact object.
    * @author Manish 2023.08.17
    * @param user
    * @param deliveryDetails
    * @param attentionRecipient
    * @param specialInstructions
    * @return Map<String,Object>
    **/
    public static void updateAdditionalShippingInfo(Contact contact){
        update contact;
    }
    
    /**
    * @description  Method to retrieve ContactPointAddress.
    * @author Rani 2023.08.17
    * @param contactId
    * @param AddressType
    * @return List<ContactPointAddress>
    **/
    public static List<ContactPointAddress> fetchContactPointAddresses(String contactId, String addressType){
        List<ContactPointAddress> lstContactPointAddresses = [SELECT Id, ParentId, Parent.Name, AddressFirstName, AddressLastName, AddressMiddleName, AddressType,
                                                              IsDefault, IsPrimary, Name, Street, City, State, Country, PostalCode 
                                                              FROM ContactPointAddress WHERE ParentId IN (SELECT AccountId FROM AccountContactRelation
                                                                                                          WHERE Contact.Id = :contactId) AND AddressType = :addressType
                                                              WITH SYSTEM_MODE ORDER BY Parent.Name ASC];
        return lstContactPointAddresses;
    }
    
    /**
    * @description  Method to save or update email preferences.
    * @author Manish 2023.08.24
    * @param List<ECOM_Email_Preferences__c>
    **/
    public static void upsertEmailPreferences(List<ECOM_Email_Preferences__c> listEP){
        upsert listEP;
    }
    
    /**
    * @description  Method to get all email preferences.
    * @author Manish 2023.08.24
    * @param erpAddressId
    * @return List<ECOM_Email_Preferences__c
    **/
    public static List<ECOM_Email_Preferences__c> getEmailPreferences(String erpAddressId){
        return [SELECT Id, Name, ERP_Address__c, ECOM_Account__c, ECOM_Contact__c, ECOM_Order_Confirmation__c, ECOM_Shipment_Notification__c, ECOM_Send_Invoice__c, ECOM_Email__c, ECOM_isActive__c 
                                                                     FROM ECOM_Email_Preferences__c 
                                                                     WHERE ERP_Address__c =: erpAddressId AND ECOM_isActive__c = true];
    }

    /**
    * @description  Method to get all email preferences.
    * @author Manish 2023.10.27
    * @param erpAddressId
    * @param conId
    * @return List<ECOM_Email_Preferences__c>
    **/
    public static List<ECOM_Email_Preferences__c> getEmailPreferencesForCurrentUser(String erpAddressId, String conId){
        return [SELECT Id, Name, ERP_Address__c, ECOM_Account__c, ECOM_Contact__c, ECOM_Order_Confirmation__c, ECOM_Shipment_Notification__c, ECOM_Send_Invoice__c, ECOM_Email__c, ECOM_isActive__c , Ecom_Opt_Out_from_Cart_Emails__c//RWPS-3306
                                                                     FROM ECOM_Email_Preferences__c
                                                                     WHERE (ERP_Address__c =: erpAddressId OR ERP_Address__c =: null) // RWPS-3306
                													 AND ECOM_Contact__c =: conId AND ECOM_isActive__c = true];
    }

    /**
    * @description 
    * @author mkumar@rafter.one | 09-21-2023 
    * @param con 
    * @return Contact 
    **/
    public static Contact updateContact(Contact con)
    {
        update con;
        return con;
    }
    
    /**
    * @description This method returns Account and Contact information for current user.
    * @author Vickal 2023.08.30
    * @param  
    * @return
    **/
    public static Contact getContactByOwner(){
        List<User> currentUser = [SELECT Id, ContactId FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        if(currentUser.size() > 0){
            List<Contact> contacts = [SELECT Id, FirstName, LastName, Email, AccountId, Account.Name, Account.AccountNumber,
            Phone, ECOM_Phone_Extension__c, ECOM_Attention_Recipient__c, ECOM_DefaultBillToAccount__c, ECOM_Delivery_Details__c,
            ECOM_CountryProvided__c,
            Account.SAP_Customer_Number_Formatted__c,ECOM_DefaultBillToAccount__r.Name, ECOM_DefaultShipToCPA__c,
            ECOM_DefaultBillToAccount__r.BillingStreet,ECOM_DefaultBillToAccount__r.BillingCity, 
            ECOM_DefaultBillToAccount__r.BillingState,ECOM_DefaultBillToAccount__r.BillingPostalCode,
            ECOM_DefaultBillToAccount__r.BillingCountry, ECOM_DefaultBillToAccount__r.SAP_Customer_Number_Formatted__c, 
            ECOM_DefaultShipToAccount__c,ECOM_DefaultShipToAccount__r.Name,
            ECOM_DefaultShipToAccount__r.ShippingStreet, ECOM_DefaultShipToAccount__r.ShippingCity, 
            ECOM_DefaultShipToAccount__r.ShippingState, ECOM_DefaultShipToAccount__r.ShippingPostalCode,
            ECOM_DefaultShipToAccount__r.ShippingCountry,ECOM_DefaultShipToAccount__r.AccountNumber,
            ECOM_DefaultBillToCPA__c,ECOM_DefaultBillToCPA__r.Id,ECOM_DefaultBillToCPA__r.Name,
            ECOM_DefaultBillToCPA__r.CompanyName, ECOM_DefaultBillToCPA__r.Country,
            ECOM_DefaultBillToCPA__r.City,ECOM_DefaultBillToCPA__r.Street,
            ECOM_DefaultBillToCPA__r.State,ECOM_DefaultBillToCPA__r.PostalCode
            FROM Contact 
            WHERE Id =: currentUser[0].ContactId
            ];
            return contacts[0];
        }
        return null;
    }
    
    public static String updateContactAccount(Contact contact){
        try{
        	update contact;
            return 'success'; 
        } catch(Exception ex){
            return 'error';
        }
    }

    /*public static String updateContactAccount(String recordId, String shipToId, String billToId){
        User currentUser = [SELECT Id, ContactId FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        //List<ECOM_AccountWrapper.AccountDetails> accWrapper = ECOM_AccountUtil.getAccountDetails(currentUser.ContactId, accId, true);
        Id accId = (Id)recordId;
        Contact con = new Contact(Id=currentUser.ContactId);
        if(accId.getSObjectType().getDescribe().getName() == 'Account'){
            con.ECOM_DefaultBillToCPA__c = null;
            con.ECOM_DefaultShipToCPA__c = null;
            con.ECOM_DefaultBillToAccount__c = billToId;
            con.ECOM_DefaultShipToAccount__c = shipToId;
            con.AccountId = accId;
        } else if(accId.getSObjectType().getDescribe().getName() == 'ContactPointAddress'){
            ContactPointAddress cpa = ECOM_AccountService.getCPAForCPAId(accId);
            if(cpa != null){
                con.ECOM_DefaultBillToAccount__c= null;
                con.ECOM_DefaultShipToAccount__c = null;
                con.ECOM_DefaultBillToCPA__c = cpa.Id;
                con.ECOM_DefaultShipToCPA__c = cpa.ECOM_Associated_ShipTo__c;
                con.AccountId = accId;
            }
        }
        try{
            update con;
            Map<String,Object> tempMap=ECOM_CartUtil.updateCartForAccountSwitch(con.Id);
            return 'success';
        } catch(DmlException de){
            return 'error';
        }
    }*/

   /* public static String updateBillingAccountOnContact(String contactId, String billingAccount){
        Contact con = new Contact(Id=contactId);
        Id recordId = (Id)billingAccount;
        if(recordId.getSObjectType().getDescribe().getName() == 'Account'){
            con.ECOM_DefaultBillToAccount__c = billingAccount;
        }
        else if(recordId.getSObjectType().getDescribe().getName() == 'ContactPointAddress'){
            con.ECOM_DefaultBillToCPA__c = billingAccount;
        }
        try {
            update con;
            return 'success';
        } catch (DmlException de) {
            return 'error';
        }
    }*/

    /**
    * @description update default BT account
    * @author mkumar@rafter.one | 09-21-2023 
    * @param contactId 
    * @param billingAccount 
    **/
    public static void updateDefaultBillingAccount(String contactId, String billingAccount){
        Contact con = new Contact(Id=contactId);
        Id recordId = (Id)billingAccount;
        if(recordId.getSObjectType().getDescribe().getName() == 'Account'){
            con.ECOM_DefaultBillToCPA__c = null;
            con.ECOM_DefaultBillToAccount__c = billingAccount;
        } else if(recordId.getSObjectType().getDescribe().getName() == 'ContactPointAddress'){
            con.ECOM_DefaultBillToAccount__c = null;
            con.ECOM_DefaultBillToCPA__c = billingAccount;
        }
        update con;
    }

    /**
    * @description  update cart BT 
    * @author mkumar@rafter.one | 09-21-2023 
    * @param billingAccountId 
    **/
    public static void updateCartDefaultAddress(String billingAccountId){
        List<WebCart> carts = ECOM_CartRepo.getPrimaryCartBasedOnOwner(UserInfo.getUserId());
        Id recordId = (Id)billingAccountId;
        if(carts.size()>0 && recordId.getSObjectType().getDescribe().getName() == 'Account'){
            WebCart cart = new WebCart(Id=carts[0].Id);
            cart.ECOM_BillToAccount__c = billingAccountId;
            update cart;
        } //else if(recordId.getSObjectType().getDescribe().getName() == 'ContactPointAddress'){
        //     cart.ECOM_DefaultBillToCPA__c = billingAccountId;
        //     cart.ECOM_BillToAccount__c = null;
        // }
    }
    
    /**
     * @description This method returns a contact record for a given email
     * @author vramachandran@rafter.one | 22 Dec 2023
     * @param contactEmail | String 
     * @returns Contact
     */
    public static List<Contact> getContactForEmail(String contactEmail){
        return [SELECT Id, FirstName, LastName, AccountId, 
                Default_Bill_to_ERP_Address__c,Default_Ship_to_ERP_Address__c,Default_Sold_to_ERP_Address__c,
                ECOM_Is_Punchout_Contact__c, ECOM_CountryProvided__c
                FROM Contact
                WHERE Email =: contactEmail
                LIMIT 1];
    }
    
    /**
     * @description This method returns fields for user redirection
     * @author vramachandran@rafter.one | 23 May 2024
     * @param contactEmail | Contact
     * @returns Contact
     */
    public static Contact getContactFieldsForRedirection(String contactEmail) {
        Contact contactRecord;
        List<Contact> contactsList = [SELECT Id, Email, ECOM_RegistrationPattern__c, ECOM_AddressRegistration__c,
                                      ECOM_AccountNumberProvided__c
                                      FROM Contact 
                                      WHERE Email =: contactEmail LIMIT 1];
        
        if(null != contactsList && !contactsList.isEmpty()) {
            
            contactRecord = contactsList[0];
        }
        
        return contactRecord;
    }

    /**
     * @description This method inserts task
     * @author garora@rafter.one | 23 May 2024
     * @param task | Task
     */
    public static void insertTask(Task task){
        insert task;
    }

}