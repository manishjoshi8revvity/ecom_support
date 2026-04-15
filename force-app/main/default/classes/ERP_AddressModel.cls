/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-928
*
* 2. Description - This class is used as ERP Address model
*
* 3. Objects referenced
*    - ERP Address
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
*    - Rani Thumma 2023.10.10
*    - Sidak 2024.02.13 Added isRad - RWPS-140
*    - Gaurang 2024.04.03 Added new field po_DefaultUNSPSC(ECOM_Punchout_Default_UNSPSC__c) in wrapper class - RWPS-410
*	 - Sathiya 2024.04.29 Added new fields invoiceCustId, eanDoNotUse and vatNumber for ECOM-1933 & ECOM-1942
*	 - Sathiya 2024.05.13 Added new fields associatedInvoiceAddress for ECOM-1939
*	 - Sathiya 2024.06.02 Added for new invoice address logic
*    - Sidak 2024.05.02 Added showAccNumber to show/hide account number. Ticket RWPS-564
*	 - Sathiya 2024.06.27 Added emailToInvoice field for ECOM-3389
*************************************************************/
public class ERP_AddressModel {
    
    @AuraEnabled public String id;
    //@AuraEnabled public String type; //bill to or ship to or sold to
    @AuraEnabled public String externalId;//SAP customer id -004
    @AuraEnabled public Boolean isNew;
    @AuraEnabled public Boolean isSelected;
    @AuraEnabled public Boolean isAddNewAddress;// to show add address button or not
    @AuraEnabled public String accountId;
    @AuraEnabled public String customerNumber;//Account related
    @AuraEnabled public String erpAccountName;//text field
    @AuraEnabled public String accountGroup;// 0001, 0003
    @AuraEnabled public String contactId;
    @AuraEnabled public Boolean isEcomEnabled;
    @AuraEnabled public String ecomReviewStatus;
    // Fields Added for ECOM-1933 & ECOM-1942 on 2024-04-29 by sathiya
    @AuraEnabled public String invoiceCustId;
    @AuraEnabled public String eanDoNotUse;
    @AuraEnabled public String vatNumber;
    @AuraEnabled public String targetId; // Added for new invoice address logic
    @AuraEnabled public Boolean isShowAddress;
    // End of field addition
    //Fields Added for ECOM-3389 on 2024-06-27 by sathiya
    @AuraEnabled public String emailToInvoice;
    //End of field addition
    @AuraEnabled public String addressType;//Sold To, Ship To, Payer, Bill To, Master
    @AuraEnabled public String street;	
    @AuraEnabled public String street2;//VRa-Punchout changes
    @AuraEnabled public String city;	
    @AuraEnabled public String state;	
    @AuraEnabled public String postalCode;	
    @AuraEnabled public String country;
    @AuraEnabled public String countryCode;
    @AuraEnabled public String fxAddress;
    @AuraEnabled public String sapName;
    @AuraEnabled public Boolean showSapName;
    @AuraEnabled public Boolean showAccNumber; // Sidak 2024.05.02 to show/hide account number. Ticket RWPS-564
    @AuraEnabled public Boolean isRad;
    @AuraEnabled public List<ERP_AddressModel> associatedAddresses;
    // Fields Added for ECOM-1933 & ECOM-1942 on 2024-04-29 by sathiya
    @AuraEnabled public List<Object> validationFields;
    @AuraEnabled public Boolean isValidatedFields;
    // Changes End
    // Fields Added for ECOM-1939 on 2024-05-13 by sathiya
    @AuraEnabled public String puCustEInvoice;
    @AuraEnabled public List<ERP_AddressModel> associatedInvoiceAddresses;
    // Changes End
    /**VRa - Punchout changes - 22 Dec 2023 - Begin*/
    @AuraEnabled public String po_AccountName;
    @AuraEnabled public String po_AccountUrl;
    @AuraEnabled public String po_ProductIncludeQuery;
    @AuraEnabled public String po_ProductExcludeQuery;
    @AuraEnabled public String po_CustomerCode;
    @AuraEnabled public String po_UnitOfMeasure;
    @AuraEnabled public String po_SenderSharedSecret;
    @AuraEnabled public String po_SenderSharedIdent;
    @AuraEnabled public String po_PunchoutResponseFormat;
    @AuraEnabled public String po_TimeZone;
    @AuraEnabled public String po_CurrencyIsoCode;
    @AuraEnabled public String po_CountryCode;
    @AuraEnabled public String po_CountryName;
    @AuraEnabled public String po_Locale;
    
    @AuraEnabled public Boolean po_ShowListPrice; 
    @AuraEnabled public Boolean po_isPunchoutEnabled;
    
    @AuraEnabled public String po_Processors; //GAr ECOM-2100
    @AuraEnabled public Boolean po_DefaultUNSPSC; //GAr - RWPS-410 - Added new field po_DefaultUNSPSC in wrapper class
    
    @AuraEnabled public ERP_AddressModel po_ShipToAddress;
    @AuraEnabled public ERP_AddressModel po_SoldToAddress;
    @AuraEnabled public ERP_AddressModel po_PayerAddress;
    @AuraEnabled public ERP_AddressModel po_BillToAddress;
    
       /**VRa - Punchout changes - End*/    
}