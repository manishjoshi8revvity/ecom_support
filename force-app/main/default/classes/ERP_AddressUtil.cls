/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-928
*
* 2. Description - This class is used used as a helper class to map ERP_Address__c records to ERP_AddressModel class 
*                  and/or ERP_AddressModel class to ERP_Address sObject records
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
*    - Vipul Goyal 2024.01.31 Ticket - RWPS-100
*    - vramachandran@rafter.one 2024.02.09 : Added logic to get Master Address Id from Payer if only payer record is returned
*    - Sidak 2024.02.13 Added Boolean isRad - RWPS-140
*    - Gaurang Arora 2024.04.03 mapping of new field (ECOM_Punchout_Default_UNSPSC__c) as per requirement - RWPS-410
*    - Gaurang Arora 2024.04.18 mapping changes from erpadd.ERP_Account_Name__c to erpAdd.Target_Address__r.SAP_Name_1__c - RWPS-470
*	 - Sathiya 2024.04.29 mapping changes for ECOM-1933 and ECOM-1942 have been added as part of the change.
*    - Sidak 2024.04.30 Updated methods convertNewERPAddressesToShipToList, convertERPAddressesToModel to add logic to show Account name provided from contact - RWPS-564
*    - Sidak 2024.05.02 Added showAccNumber in convertERPAddressesToModel, convertERPAddressesToModel, convertNewERPAddressesToShipToList, convertERPToAddressModel, getAddressModelForRecord - RWPS-564
*    - Sidak 2024.05.16 Updated method convertNewERPAddressesToShipToList- Added erpAccountName - RWPS-677
*	 - Sathiya 2024.06.21 Updated new address mapping for bug fix ECOM - 3298
*	 - Sathiya 2024.06.27 Added emailToInvoice field for ECOM-3389
*    - Sidak 2024.09.17 Updated methods convertERPAddressesToModel, convertERPToAddressModel- Added logic to fetch erpAccountName from ERP_Account_Name__c - RWPS-1503
*    - Sidak 2024.11.11 Updated method getPunchoutAccountIdList - Returned map of account Id and country - RWPS-1809
*    - Manish Joshi 2026.01.30 Updated method getPunchoutAccountIdList - RWPS-5776
*    - Princy Anthony 2026.04.02 Updated method getAddressModelForRecord - RWPS-7241
*************************************************************/
public without sharing  class ERP_AddressUtil {
    
    public static List<ECOM_MyAccountModel> convertERPAddressesToModel(List<ERP_Address__c> erpAddresses, User user){
        
        List<ECOM_MyAccountModel> accountModels = new List<ECOM_MyAccountModel>();
        Map<String, List<ERP_AddressModel>> soldToShipTosMap = new Map<String, List<ERP_AddressModel>>();
        Map<String, List<ERP_AddressModel>> shipToBillTosMap = new Map<String, List<ERP_AddressModel>>();
        Map<String, List<ERP_AddressModel>> billToInvoicesMap = new Map<String, List<ERP_AddressModel>>();
        Map<String, List<ERP_AddressModel>> payerToInvoicesMap = new Map<String, List<ERP_AddressModel>>();
        Map<String, Boolean> addNewAddressShipToMap = new Map<String, Boolean>();
        Map<String, Boolean> addNewAddressBillToMap = new Map<String, Boolean>();
        List<ERP_AddressModel> billToErpAddressModels;
        List<ERP_AddressModel> shipToErpAddressModels;
        List<ERP_AddressModel> invoiceErpAddressModels;
        
        for(ERP_Address__c erpAdd :erpAddresses){
            Boolean isAddNewAddress = true;
            if(erpAdd.Address_Type__c == 'Bill To'){
                ERP_AddressModel invoice = new ERP_AddressModel();
                invoice.id = erpAdd.Id;
                invoice.externalId = erpAdd.Target_Address__r.External_Id__c;
                invoice.accountId = erpAdd.Account__c;
                // Adding this due to a bug seen when editing the address (Empty Company Name) By Sathiya
                invoice.erpAccountName = erpAdd?.ERP_Account_Name__c;
                // Change End
                if(erpAdd.Contact__c != null){
                    invoice.contactId = erpAdd.Contact__c;
                } else{
                    invoice.contactId = user.ContactId;
                }
                invoice.isEcomEnabled = erpAdd.fxIsECOMenabled__c;
                invoice.ecomReviewStatus = erpAdd.ECOM_Review_Status__c;
                invoice.accountGroup = erpAdd.ERP_Account_Group__c;// 0001, 0003
                invoice.customerNumber = erpAdd.ERP_Customer_Number__c;// -- Account related
                invoice.addressType = erpAdd.Address_Type__c;//Sold To, Ship To, Payer, Bill To, Master
                invoice.countryCode = erpAdd.fxAddress_CountryCode__c;
                if(String.isNotBlank(erpAdd.Target_Address__c) && String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_1__c))
                {
                    invoice.sapName=(String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_1__c)?erpAdd.Target_Address__r.SAP_Name_1__c:'')+(String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_2__c)?(', '+erpAdd.Target_Address__r.SAP_Name_2__c):'');
                    invoice.sapName+=(String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_3__c)?(', '+erpAdd.Target_Address__r.SAP_Name_3__c):'')+(String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_4__c)?(', '+erpAdd.Target_Address__r.SAP_Name_4__c):'');
                    invoice.showSapName=true;
                }
                else
                {
                    invoice.showSapName=false;
                }

                // if user already selected a default bill to
                if(user.Contact.Default_Invoice_ERP_Address__c != null && user.Contact.Default_Invoice_ERP_Address__c == erpAdd.Id){
                    invoice.isSelected = true;
                } else {
                    invoice.isSelected = false;
                }
                //RWPS-470 - GAr - 12 April 2024 - Change of account name mapping - starts
                if(String.isNotBlank(erpAdd.Target_Address__c) && String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_1__c)){
                    invoice.erpAccountName = erpAdd.Target_Address__r.SAP_Name_1__c;
                }
                //RWPS-470 - GAr - 12 April 2024 - Change of account name mapping - ends
                if(erpAdd.ECOM_Review_Status__c != 'Approved'){
                    invoice.street = erpAdd.Address_Street_Line_1__c;    
                    invoice.city = erpAdd.Address_City__c;   
                    invoice.state = erpAdd.apiState__c;  
                    invoice.postalCode = erpAdd.Address_Postal_Code__c;  
                    invoice.country = erpAdd.apiCountry__c;                  
                    invoice.isAddNewAddress = false;
                } else { //formula fields values - if target is not empty(master or new) they represent address fields on ERP address else Target Address 
                    invoice.street = erpAdd.fxAddress_Street__c; 
                    invoice.city = erpAdd.fxAddress_City__c; 
                    invoice.state = erpAdd.fxAddress_StateName__c;   
                    invoice.postalCode = erpAdd.fxAddress_Postal__c; 
                    invoice.country = erpAdd.fxAddress_CountryCode__c;
                    invoice.fxAddress = erpAdd.fxAddressFull__c;
                    invoice.isAddNewAddress = true; //falg to show add new address option
                    isAddNewAddress = true;
                }
                // Add logic for showing invoice address
                invoice.isShowAddress = ((erpAdd.Master_Address__c != null && erpAdd.Target_Address__c == null) ||
                    (erpAdd.Master_Address__c != null && erpAdd.Target_Address__c != null 
                     && erpAdd.Target_Address__c != erpAdd.Master_Address__c));
                // Change end
                // by external id
                if(erpAdd.Master_Address__c != null && erpAdd.Master_Address__r.External_Id__c != null){
                    if(billToInvoicesMap.get(erpAdd.Master_Address__r.External_Id__c) == null){
                        invoiceErpAddressModels = new List<ERP_AddressModel>();
                        billToInvoicesMap.put(erpAdd.Master_Address__r.External_Id__c, invoiceErpAddressModels);
                    }
                    billToInvoicesMap.get(erpAdd.Master_Address__r.External_Id__c).add(invoice);
                    addNewAddressShipToMap.put(erpAdd.Master_Address__r.External_Id__c, isAddNewAddress);
                // by SF Id    
                } else if(erpAdd.Master_Address__c != null){
                    if(billToInvoicesMap.get(erpAdd.Master_Address__c) == null){
                        invoiceErpAddressModels = new List<ERP_AddressModel>();
                        billToInvoicesMap.put(erpAdd.Master_Address__c, invoiceErpAddressModels);
                    }
                    billToInvoicesMap.get(erpAdd.Master_Address__c).add(invoice);
                    addNewAddressShipToMap.put(erpAdd.Master_Address__c, isAddNewAddress);
                }
                // Changes by sathiya for new invoice mailing address
				if(erpAdd.Master_Address__c != null){
                    if(payerToInvoicesMap.get(erpAdd.Master_Address__c) == null){
                        invoiceErpAddressModels = new List<ERP_AddressModel>();
                        payerToInvoicesMap.put(erpAdd.Master_Address__c, invoiceErpAddressModels);
                    }
                    payerToInvoicesMap.get(erpAdd.Master_Address__c).add(invoice);
                    if(!addNewAddressBillToMap.containsKey(erpAdd.Master_Address__c)){
                        addNewAddressBillToMap.put(erpAdd.Master_Address__c, true);
                    }
                    if(addNewAddressBillToMap.get(erpAdd.Master_Address__c)){
                        addNewAddressBillToMap.put(erpAdd.Master_Address__c, erpAdd?.Target_Address__c != null);
                    }
                }
                // Changes end
            } else if(erpAdd.Address_Type__c == 'Payer'){
                ERP_AddressModel billTo = new ERP_AddressModel();
                billTo.id = erpAdd.Id;
                billTo.externalId = erpAdd.Target_Address__r.External_Id__c;
                billTo.targetId = erpAdd.Target_Address__c;
                billTo.accountId = erpAdd.Account__c;
                billTo.showAccNumber = true;
                // Adding this due to a bug seen when editing the address (Empty Company Name) By Sathiya
                billTo.erpAccountName = erpAdd?.ERP_Account_Name__c;
                // Change End
                if(erpAdd.Contact__c != null){
                    billTo.contactId = erpAdd.Contact__c;
                } else{
                    billTo.contactId = user.ContactId;
                }
                if(erpAdd?.Target_Address__c != null){
                    billTo.eanDoNotUse = erpAdd?.Target_Address__r?.ECOM_EAN_Do_Not_Use__c;
                    billTo.vatNumber = erpAdd?.Target_Address__r?.ECOM_VAT_Number__c;
                    billTo.invoiceCustId = erpAdd?.Target_Address__r?.ECOM_E_Invoice_Cust_Id__c;
                    billTo.puCustEInvoice = erpAdd?.Target_Address__r?.ECOM_PU_Cust_E_Invoice__c;
                    billTo.emailToInvoice = erpAdd?.Target_Address__r?.ECOM_Email_To_Invoice__c;
                } else {
                    // Changes for mapping done as part of ECOM-1933 and ECOM-1942 by Sathiya
                    billTo.eanDoNotUse = erpAdd?.ECOM_EAN_Do_Not_Use__c;
                    billTo.vatNumber = erpAdd?.ECOM_VAT_Number__c;
                    billTo.invoiceCustId = erpAdd?.ECOM_E_Invoice_Cust_Id__c;
                    billTo.puCustEInvoice = erpAdd?.ECOM_PU_Cust_E_Invoice__c;
                    // Changes end
                    // Changes for mapping done as part of ECOM-3389 by Sathiya
                    billTo.emailToInvoice = erpAdd?.ECOM_Email_To_Invoice__c;
                    // Changes End
                }                
                billTo.isEcomEnabled = erpAdd.fxIsECOMenabled__c;
                billTo.ecomReviewStatus = erpAdd.ECOM_Review_Status__c;
                billTo.accountGroup = erpAdd.ERP_Account_Group__c;// 0001, 0003
                billTo.customerNumber = erpAdd.ERP_Customer_Number__c;// -- Account related
                billTo.addressType = erpAdd.Address_Type__c;//Sold To, Ship To, Payer, Bill To, Master
                billTo.countryCode = erpAdd.fxAddress_CountryCode__c;
                if(String.isNotBlank(erpAdd.Target_Address__c) && String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_1__c))
                {
                    billTo.sapName=(String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_1__c)?erpAdd.Target_Address__r.SAP_Name_1__c:'')+(String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_2__c)?(', '+erpAdd.Target_Address__r.SAP_Name_2__c):'');
                    billTo.sapName+=(String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_3__c)?(', '+erpAdd.Target_Address__r.SAP_Name_3__c):'')+(String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_4__c)?(', '+erpAdd.Target_Address__r.SAP_Name_4__c):'');
                    billTo.showSapName=true;
                }
                //RWPS-564 - Sidak - 30 April 2024 - Added logic to populate account name provided from contact
                else if(erpAdd.ECOM_Review_Status__c.equalsIgnoreCase('New') && String.isNotBlank(user.ContactId) && String.isNotBlank(user.Contact.ECOM_AccountNameProvided__c)){
                    billTo.sapName = user.Contact.ECOM_AccountNameProvided__c;
                    billTo.showSapName = true;
                }   
                else
                {
                    billTo.showSapName=false;
                }

                // if user already selected a default bill to
                if(user.Contact.Default_Bill_to_ERP_Address__c != null && user.Contact.Default_Bill_to_ERP_Address__c == erpAdd.Id){
                    billTo.isSelected = true;
                } else {
                    billTo.isSelected = false;
                }
                //RWPS-470 - GAr - 12 April 2024 - Change of account name mapping - starts
                if(String.isNotBlank(erpAdd.Target_Address__c) && String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_1__c)){
                    billTo.erpAccountName = erpAdd.Target_Address__r.SAP_Name_1__c;
                }
                else if(String.isBlank(erpAdd.Target_Address__c)){ //RWPS-1503
                    billTo.erpAccountName = erpAdd.ERP_Account_Name__c;
                }
                //RWPS-470 - GAr - 12 April 2024 - Change of account name mapping - ends
                if(erpAdd.ECOM_Review_Status__c != 'Approved'){
                    billTo.street = erpAdd.Address_Street_Line_1__c;    
                    billTo.city = erpAdd.Address_City__c;   
                    billTo.state = erpAdd.apiState__c;  
                    billTo.postalCode = erpAdd.Address_Postal_Code__c;  
                    billTo.country = erpAdd.apiCountry__c;                  
                    billTo.isAddNewAddress = false;
                } else { //formula fields values - if target is not empty(master or new) they represent address fields on ERP address else Target Address 
                    billTo.street = erpAdd.fxAddress_Street__c; 
                    billTo.city = erpAdd.fxAddress_City__c; 
                    billTo.state = erpAdd.fxAddress_StateName__c;   
                    billTo.postalCode = erpAdd.fxAddress_Postal__c; 
                    billTo.country = erpAdd.fxAddress_CountryCode__c;
                    billTo.fxAddress = erpAdd.fxAddressFull__c;
                    billTo.isAddNewAddress = true; //falg to show add new address option
                    isAddNewAddress = true;
                }
                // by external id
                if(erpAdd.Master_Address__c != null && erpAdd.Master_Address__r.External_Id__c != null){
                    if(shipToBillTosMap.get(erpAdd.Master_Address__r.External_Id__c) == null){
                        billToErpAddressModels = new List<ERP_AddressModel>();
                        shipToBillTosMap.put(erpAdd.Master_Address__r.External_Id__c, billToErpAddressModels);
                    }
                    shipToBillTosMap.get(erpAdd.Master_Address__r.External_Id__c).add(billTo);
                    addNewAddressShipToMap.put(erpAdd.Master_Address__r.External_Id__c, isAddNewAddress);
                // by SF Id    
                } else if(erpAdd.Master_Address__c != null){
                    if(shipToBillTosMap.get(erpAdd.Master_Address__c) == null){
                        billToErpAddressModels = new List<ERP_AddressModel>();
                        shipToBillTosMap.put(erpAdd.Master_Address__c, billToErpAddressModels);
                    }
                    shipToBillTosMap.get(erpAdd.Master_Address__c).add(billTo);
                    addNewAddressShipToMap.put(erpAdd.Master_Address__c, isAddNewAddress);
                }
            } else if(erpAdd.Address_Type__c == 'Ship To'){
                ERP_AddressModel shipTo = new ERP_AddressModel();
                shipTo.id = erpAdd.Id;
                shipTo.externalId = erpAdd.Target_Address__r.External_Id__c;
                shipTo.showAccNumber = true;
                // Adding this due to a bug seen when editing the address (Empty Company Name) By Sathiya
                shipTo.erpAccountName = erpAdd?.ERP_Account_Name__c;
                // Change End
                shipTo.isNew = false;
                if(String.isNotBlank(erpAdd.RAD_Identifier__c) && (erpAdd.RAD_Identifier__c.equalsIgnoreCase('rad') || erpAdd.RAD_Identifier__c.equalsIgnoreCase('yes'))){
                    shipTo.isRad = true;
                }
                else{
                    shipTo.isRad = false;
                }  
                // if user already selected a default ship to
                if(user.Contact.Default_Ship_to_ERP_Address__c != null && user.Contact.Default_Ship_to_ERP_Address__c == erpAdd.Id){
                    shipTo.isSelected = true;
                } else {
                    shipTo.isSelected = false;
                }
                shipTo.accountId = erpAdd.Account__c;
                if(erpAdd.Contact__c != null){
                    shipTo.contactId = erpAdd.Contact__c;
                } else{
                    shipTo.contactId = user.ContactId;
                }
                shipTo.isEcomEnabled = erpAdd.fxIsECOMenabled__c;
                shipTo.ecomReviewStatus = erpAdd.ECOM_Review_Status__c;
                shipTo.accountGroup = erpAdd.ERP_Account_Group__c;// 0001, 0003
                shipTo.customerNumber = erpAdd.ERP_Customer_Number__c;// -- Account related

                //RWPS-470 - GAr - 12 April 2024 - Change of account name mapping - starts
                if(String.isNotBlank(erpAdd.Target_Address__c) && String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_1__c)){
                    shipTo.erpAccountName = erpAdd.Target_Address__r.SAP_Name_1__c;
                }
                //RWPS-470 - GAr - 12 April 2024 - Change of account name mapping - ends

                if(String.isNotBlank(erpAdd.Target_Address__c) && String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_1__c))
                {
                    shipTo.sapName=(String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_1__c)?erpAdd.Target_Address__r.SAP_Name_1__c:'')+(String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_2__c)?(', ' +erpAdd.Target_Address__r.SAP_Name_2__c):'');
                    shipTo.sapName+=(String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_3__c)?(', '+erpAdd.Target_Address__r.SAP_Name_3__c):'')+(String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_4__c)?(', '+erpAdd.Target_Address__r.SAP_Name_4__c):'');
                    shipTo.showSapName=true;
                }
                //RWPS-564 - Sidak - 30 April 2024 - Added logic to populate account name provided from contact
                else if(erpAdd.ECOM_Review_Status__c.equalsIgnoreCase('New') && String.isNotBlank(user.ContactId) && String.isNotBlank(user.Contact.ECOM_AccountNameProvided__c)){
                    shipTo.sapName = user.Contact.ECOM_AccountNameProvided__c;
                    shipTo.showSapName = true;
                }  
                else
                {
                    shipTo.showSapName=false;
                }

                //shipTo.salesOrg = erpAdd.ERP_Sales_Org__c;
                shipTo.addressType = erpAdd.Address_Type__c;//Sold To, Ship To, Payer, Bill To, Master
                if(erpAdd.ECOM_Review_Status__c != 'Approved'){
                    shipTo.street = erpAdd.Address_Street_Line_1__c;    
                    shipTo.city = erpAdd.Address_City__c;   
                    shipTo.state = erpAdd.apiState__c;  
                    shipTo.postalCode = erpAdd.Address_Postal_Code__c;  
                    shipTo.country = erpAdd.apiCountry__c;
                    shipTo.isAddNewAddress = false;
                } else { 
                    shipTo.street = erpAdd.fxAddress_Street__c; 
                    shipTo.city = erpAdd.fxAddress_City__c; 
                    shipTo.state = erpAdd.fxAddress_StateName__c;   
                    shipTo.postalCode = erpAdd.fxAddress_Postal__c; 
                    shipTo.country = erpAdd.fxAddress_CountryCode__c;
                    shipTo.fxAddress = erpAdd.fxAddressFull__c;
                    shipTo.isAddNewAddress = true;
                }
                if(erpAdd.Master_Address__c != null && erpAdd.Master_Address__r.External_Id__c != null){
                    if(soldToShipTosMap.get(erpAdd.Master_Address__r.External_Id__c) == null){
                        shipToErpAddressModels = new List<ERP_AddressModel>();
                        soldToShipTosMap.put(erpAdd.Master_Address__r.External_Id__c, shipToErpAddressModels);
                    }
                    soldToShipTosMap.get(erpAdd.Master_Address__r.External_Id__c).add(shipTo);
                } else if(erpAdd.Master_Address__c != null){
                    if(soldToShipTosMap.get(erpAdd.Master_Address__c) == null){
                        shipToErpAddressModels = new List<ERP_AddressModel>();
                        soldToShipTosMap.put(erpAdd.Master_Address__c, shipToErpAddressModels);
                    }
                    soldToShipTosMap.get(erpAdd.Master_Address__c).add(shipTo);
                }
            } else if (erpAdd.Address_Type__c == 'Sold To'){
                ECOM_MyAccountModel myAdd = new ECOM_MyAccountModel();
                myAdd.accountId = erpAdd.Account__c;
                myAdd.externalId = erpAdd.Target_Address__r.External_Id__c;
                myAdd.customerNumber = erpAdd.ERP_Customer_Number__c;
                myAdd.showAccNumber = true;
                // Adding this due to a bug seen when editing the address (Empty Company Name) By Sathiya
                myAdd.erpAccountName = erpAdd?.ERP_Account_Name__c;
                // Change End
                myAdd.contactId = user.ContactId;
                //Added by Vipul
                ERP_AddressModel soldTo=new ERP_AddressModel();
                if(erpAdd.ECOM_Review_Status__c=='Approved')
                {
                    soldto.Id=erpAdd.Id;
                    soldTo.street = erpAdd.fxAddress_Street__c; 
                    soldTo.city = erpAdd.fxAddress_City__c; 
                    soldTo.state = erpAdd.fxAddress_StateName__c;   
                    soldTo.postalCode = erpAdd.fxAddress_Postal__c; 
                    soldTo.country = erpAdd.fxAddress_CountryCode__c;
                    soldTo.fxAddress = erpAdd.fxAddressFull__c;

                    if(String.isNOtBlank(erpAdd.Target_Address__c) && String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_1__c))
                    {
                        soldTo.sapName=(String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_1__c)?erpAdd.Target_Address__r.SAP_Name_1__c:'')+(String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_2__c)?(', '+erpAdd.Target_Address__r.SAP_Name_2__c):'');
                        soldTo.sapName+=(String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_3__c)?(', '+erpAdd.Target_Address__r.SAP_Name_3__c):'')+(String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_4__c)?(',' +erpAdd.Target_Address__r.SAP_Name_4__c):'');
                        soldTo.showSapName=true;
                    }
                    //RWPS-564 - Sidak - 30 April 2024 - Added logic to populate account name provided from contact
                    else if(erpAdd.ECOM_Review_Status__c.equalsIgnoreCase('New') && String.isNotBlank(user.ContactId) && String.isNotBlank(user.Contact.ECOM_AccountNameProvided__c)){
                        soldTo.sapName = user.Contact.ECOM_AccountNameProvided__c;
                        soldTo.showSapName = true;
                    } 
                    else
                    {
                        soldTo.showSapName=false;
                    }

                    if(String.isNotBlank(user.Contact.Default_Sold_to_ERP_Address__c) && user.Contact.Default_Sold_to_ERP_Address__c==soldto.Id)
                    {
                        soldTo.isSelected=true;
                        myAdd.isSelected=true;
                    }
                    else {
                        soldTo.isSelected=false;
                    }
                }
                myAdd.soldToAddress=soldTo;
                //To ASK : This logic assumes that ship to will always be equal to sold to?
                if(user.Contact.Default_Sold_to_ERP_Address__c != null && user.Contact.Default_Sold_to_ERP_Address__r.Target_Address__c != null &&
                   user.Contact.Default_Sold_to_ERP_Address__r.Target_Address__r.External_Id__c == myAdd.externalId){
                    myAdd.isSelected = true;
                } else {
                    myAdd.isSelected = false;
                }
                //RWPS-470 - GAr - 18 April 2024 - mapping change from erpadd.ERP_Account_Name__c to erpAdd.Target_Address__r.SAP_Name_1__c
                if(String.isNotBlank(erpAdd.Target_Address__c) && String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_1__c)){
                    myAdd.erpAccountName = erpAdd.Target_Address__r.SAP_Name_1__c;
                }
                accountModels.add(myAdd);
            }
        }
        system.debug('payerToInvoicesMap:: ' + payerToInvoicesMap.keySet().size());
        system.debug('payerToInvoicesMap:: ' + payerToInvoicesMap.keySet());
        //assign bill tos to ship to
        for(String key :soldToShipTosMap.keySet()){
            for(ERP_AddressModel sTo :soldToShipTosMap.get(key)){
                if(shipToBillTosMap.get(sTo.externalId) != null){
                    sTo.associatedAddresses = shipToBillTosMap.get(sTo.externalId);
                } else if(shipToBillTosMap.get(sTo.Id) != null){ // new ERP addresses where external id is not yet created
                    sTo.associatedAddresses = shipToBillTosMap.get(sTo.id);
                }
                if(sTo?.associatedAddresses != null){
                    system.debug('sTo.associatedAddresses:: ' + sTo.associatedAddresses.size());
                    for(ERP_AddressModel billToModel: sTo.associatedAddresses){
                        billToModel.associatedAddresses = new List<ERP_AddressModel>();
                        system.debug('billToModel Id:: ' + billToModel.Id + ' :: ' + billToModel.targetId);
                        if(payerToInvoicesMap.containsKey(billToModel.id)){
                            system.debug('containsById:: ');
                            billToModel.associatedAddresses.addAll(payerToInvoicesMap.get(billToModel.id));
                        } 
                        if(payerToInvoicesMap.containsKey(billToModel.targetId)){
                            system.debug('containsByTarget:: ');
                            billToModel.associatedAddresses.addAll(payerToInvoicesMap.get(billToModel.targetId));
                        }
                    }
                    for(ERP_AddressModel billToModel: sTo.associatedAddresses){
                        for(ERP_AddressModel invModel: billToModel.associatedAddresses){
                            if(payerToInvoicesMap.containsKey(billToModel.id)){
                                invModel.isAddNewAddress = addNewAddressBillToMap.get(billToModel.id);
                            } else if(payerToInvoicesMap.containsKey(billToModel.targetId)){
                                invModel.isAddNewAddress = addNewAddressBillToMap.get(billToModel.targetId);
                            } 
                        }
                    }
                }
            }
        }
        system.debug('invoices:: ' + billToInvoicesMap.keySet().size());
        system.debug('soldToShipTosMap:: ' + soldToShipTosMap.keySet().size());
        // assign Invoice Address to Ship Tos
        for(String key :soldToShipTosMap.keySet()){
            for(ERP_AddressModel sTo :soldToShipTosMap.get(key)){
                if(billToInvoicesMap.get(sTo.externalId) != null){
                    sTo.associatedInvoiceAddresses = billToInvoicesMap.get(sTo.externalId);
                } else if(shipToBillTosMap.get(sTo.Id) != null){ // new ERP addresses where external id is not yet created
                    sTo.associatedInvoiceAddresses = billToInvoicesMap.get(sTo.id);
                }
            }
        }
        // assign shiptos to soldto 
        for(ECOM_MyAccountModel soldTo : accountModels){
            if(soldToShipTosMap.get(soldTo.externalId) != null){
                soldTo.erpAddresses = soldToShipTosMap.get(soldTo.externalId);
            } 
            if(addNewAddressShipToMap.get(soldTo.externalId) != null){// assumtion is soldto and shipto external ids are same
                soldTo.isAddNewAddress = addNewAddressShipToMap.get(soldTo.externalId);//add new address at ship to levels
            }
        }
        
        return accountModels;
    }
    
    public static List<ERP_Address__c> mapErpRequestToSObject(List<ERP_AddressModel> newErpAddresses){
        List<ERP_Address__c> erpReocrdsToUpsert = new List<ERP_Address__c>();
        Set<String> erpIds = new Set<String>();
        RecordType rt = ERP_AddressRepo.getDefautlRecordType();
        Map<Id,ERP_Address__c> erpAddressMap;
        
        for(ERP_AddressModel newERPst :newErpAddresses){
            System.debug('newErpAddresses === '+newErpAddresses);
            if(newERPst.associatedAddresses != null && newERPst.associatedAddresses.size() > 0){
                erpIds.add(newERPst.associatedAddresses[0].id);
            }
        }
        if(erpIds.size() > 0){
            erpAddressMap = ERP_AddressRepo.getTargetId(erpIds);
        }
        for(ERP_AddressModel newERP :newErpAddresses){
            ERP_Address__c erpAdd = new ERP_Address__c();
            if(String.isNotBlank( newERP.Id)){
                erpAdd.Id = newERP.Id;
            }
            System.debug('newERP.externalId = '+newERP.externalId);
            if(String.isBlank(newERP.externalId)){
                //erpAdd.External_Id__c = newERP.addressType + System.now(); Commented by VRa for ECOM-3333
				erpAdd.External_Id__c = newERP.addressType + UUID.randomUUID();//DateTime.now().getTime(); //Added By VRa for ECOM-3333
                System.debug('erpAdd.External_Id__c = '+erpAdd.External_Id__c);
            }            
            erpAdd.RecordTypeId = rt.Id;
            if(String.isNotBlank(newERP.accountId)){
                erpAdd.Account__c = newERP.accountId;
            }
            erpAdd.Contact__c = newERP.contactId;
            erpAdd.ERP_Account_Name__c = newERP.erpAccountName;
            erpAdd.Address_Type__c  = newERP.addressType;
            erpAdd.Address_Street_Line_1__c = newERP.street;
            erpAdd.Address_City__c = newERP.city;
            erpAdd.apiState__c = newERP.state;
            erpAdd.Address_Postal_Code__c = newERP.postalCode;
            erpAdd.apiCountry__c = newERP.country;
            erpAdd.ECOM_isEnabled__c = true;
            erpAdd.ECOM_Review_Status__c = 'New';// do not update when the status = In progress
            if(newERP.associatedAddresses != null && newERP.associatedAddresses.size() > 0 && erpAddressMap.get(newERP.associatedAddresses[0].id) != null){
                erpAdd.Master_Address__c = erpAddressMap.get(newERP.associatedAddresses[0].id)?.Target_Address__c == null?newERP.associatedAddresses[0].id:erpAddressMap.get(newERP.associatedAddresses[0].id).Target_Address__c;
            }
            // Changes for mapping done as part of ECOM-1933 and ECOM-1942 by Sathiya
            erpAdd.ECOM_E_Invoice_Cust_Id__c = newERP?.invoiceCustId == null?'': newERP?.invoiceCustId;
            erpAdd.ECOM_VAT_Number__c = newERP?.vatNumber == null?'': newERP?.vatNumber;
            erpAdd.ECOM_EAN_Do_Not_Use__c = newERP?.eanDoNotUse == null?'': newERP?.eanDoNotUse;
            erpAdd.ECOM_PU_Cust_E_Invoice__c = newERP?.puCustEInvoice == null?'': newERP?.puCustEInvoice;
            // Changes End
            // Changes for mapping done as part of ECOM-3389 by Sathiya
            erpAdd.ECOM_Email_To_Invoice__c = newErp?.emailToInvoice == null?'':newErp?.emailToInvoice;
            // Changes End
            erpReocrdsToUpsert.add(erpAdd);
        }
        return erpReocrdsToUpsert;
    }

    public static ERP_AddressModel convertERPAddressesToModel(List<ERP_Address__c> erpAddresses){
        
        ERP_AddressModel billTo = new ERP_AddressModel();
        ERP_AddressModel shipTo = new ERP_AddressModel();
        ERP_AddressModel invoice = new ERP_AddressModel();
        for(ERP_Address__c erpAdd :erpAddresses){
            Boolean isAddNewAddress = true;
            if(erpAdd.Address_Type__c == 'Bill To'){
                invoice.id = erpAdd.Id;
                invoice.externalId = erpAdd.Target_Address__r.External_Id__c;
                invoice.accountId = erpAdd.Account__c;
                // Adding this due to a bug seen when editing the address (Empty Company Name) By Sathiya
                invoice.erpAccountName = erpAdd?.ERP_Account_Name__c;
                // Change End
                if(erpAdd.Contact__c != null){
                    invoice.contactId = erpAdd.Contact__c;
                }
                invoice.isEcomEnabled = erpAdd.fxIsECOMenabled__c;
                invoice.ecomReviewStatus = erpAdd.ECOM_Review_Status__c;
                invoice.accountGroup = erpAdd.ERP_Account_Group__c;// 0001, 0003
                invoice.customerNumber = erpAdd.ERP_Customer_Number__c;// -- Account related
                invoice.addressType = erpAdd.Address_Type__c;//Sold To, Ship To, Payer, Bill To, Master
                invoice.countryCode = erpAdd.fxAddress_CountryCode__c;


                if(String.isNotBlank(erpAdd.Target_Address__c) && String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_1__c))
                {
                    invoice.sapName=(String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_1__c)?erpAdd.Target_Address__r.SAP_Name_1__c:'')+(String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_2__c)?(', '+erpAdd.Target_Address__r.SAP_Name_2__c):'');
                    invoice.sapName+=(String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_3__c)?(', '+erpAdd.Target_Address__r.SAP_Name_3__c):'')+(String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_4__c)?(', '+erpAdd.Target_Address__r.SAP_Name_4__c):'');
                    invoice.showSapName=true;
                }
                else
                {
                    invoice.showSapName=false;
                }
                
                //RWPS-470 - GAr - 18 April 2024 - mapping change from erpadd.ERP_Account_Name__c to erpAdd.Target_Address__r.SAP_Name_1__c
                if(String.isNotBlank(erpAdd.Target_Address__c) && String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_1__c)){
                    invoice.erpAccountName = erpAdd.Target_Address__r.SAP_Name_1__c;
                }
                if(erpAdd.ECOM_Review_Status__c != 'Approved'){
                    invoice.street = erpAdd.Address_Street_Line_1__c;    
                    invoice.city = erpAdd.Address_City__c;   
                    invoice.state = erpAdd.apiState__c;  
                    invoice.postalCode = erpAdd.Address_Postal_Code__c;  
                    invoice.country = erpAdd.apiCountry__c;                    
                    invoice.isAddNewAddress = false;
                } else { //formula fields values - if target is not empty(master or new) they represent address fields on ERP address else Target Address 
                    invoice.street = erpAdd.fxAddress_Street__c; 
                    invoice.city = erpAdd.fxAddress_City__c; 
                    invoice.state = erpAdd.fxAddress_StateName__c;   
                    invoice.postalCode = erpAdd.fxAddress_Postal__c; 
                    invoice.country = erpAdd.fxAddress_CountryCode__c;
                    invoice.fxAddress = erpAdd.fxAddressFull__c;
                    invoice.isAddNewAddress = true; //falg to show add new address option
                    isAddNewAddress = true;
                }
                // Add logic for showing invoice address
                invoice.isShowAddress = ((erpAdd.Master_Address__c != null && erpAdd.Target_Address__c == null) ||
                    (erpAdd.Master_Address__c != null && erpAdd.Target_Address__c != null 
                     && erpAdd.Target_Address__c != erpAdd.Master_Address__c));
                // Change end
            } else if(erpAdd.Address_Type__c == 'Payer'){
                //ERP_AddressModel billTo = new ERP_AddressModel();
                billTo.id = erpAdd.Id;
                billTo.externalId = erpAdd.Target_Address__r.External_Id__c;
                billTo.accountId = erpAdd.Account__c;
                billTo.showAccNumber = true;
                // Adding this due to a bug seen when editing the address (Empty Company Name) By Sathiya
                billTo.erpAccountName = erpAdd?.ERP_Account_Name__c;
                // Change End
                if(erpAdd.Contact__c != null){
                    billTo.contactId = erpAdd.Contact__c;
                }
                if(erpAdd?.Target_Address__c != null){
                    billTo.eanDoNotUse = erpAdd?.Target_Address__r?.ECOM_EAN_Do_Not_Use__c;
                    billTo.vatNumber = erpAdd?.Target_Address__r?.ECOM_VAT_Number__c;
                    billTo.invoiceCustId = erpAdd?.Target_Address__r?.ECOM_E_Invoice_Cust_Id__c;
                    billTo.puCustEInvoice = erpAdd?.Target_Address__r?.ECOM_PU_Cust_E_Invoice__c;
                    billTo.emailToInvoice = erpAdd?.Target_Address__r?.ECOM_Email_To_Invoice__c;
                } else {
                    // Changes for mapping done as part of ECOM-1933 and ECOM-1942 by Sathiya
                    billTo.eanDoNotUse = erpAdd?.ECOM_EAN_Do_Not_Use__c;
                    billTo.vatNumber = erpAdd?.ECOM_VAT_Number__c;
                    billTo.invoiceCustId = erpAdd?.ECOM_E_Invoice_Cust_Id__c;
                    billTo.puCustEInvoice = erpAdd?.ECOM_PU_Cust_E_Invoice__c;
                    // Changes end
                    // Changes for mapping done as part of ECOM-3389 by Sathiya
                    billTo.emailToInvoice = erpAdd?.ECOM_Email_To_Invoice__c;
                    // Changes End
                }
                billTo.isEcomEnabled = erpAdd.fxIsECOMenabled__c;
                billTo.ecomReviewStatus = erpAdd.ECOM_Review_Status__c;
                billTo.accountGroup = erpAdd.ERP_Account_Group__c;// 0001, 0003
                billTo.customerNumber = erpAdd.ERP_Customer_Number__c;// -- Account related
                billTo.addressType = erpAdd.Address_Type__c;//Sold To, Ship To, Payer, Bill To, Master
                billTo.countryCode = erpAdd.fxAddress_CountryCode__c;


                if(String.isNotBlank(erpAdd.Target_Address__c) && String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_1__c))
                {
                    billTo.sapName=(String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_1__c)?erpAdd.Target_Address__r.SAP_Name_1__c:'')+(String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_2__c)?(', '+erpAdd.Target_Address__r.SAP_Name_2__c):'');
                    billTo.sapName+=(String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_3__c)?(', '+erpAdd.Target_Address__r.SAP_Name_3__c):'')+(String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_4__c)?(', '+erpAdd.Target_Address__r.SAP_Name_4__c):'');
                    billTo.showSapName=true;
                }
                else
                {
                    billTo.showSapName=false;
                }
                
                //RWPS-470 - GAr - 18 April 2024 - mapping change from erpadd.ERP_Account_Name__c to erpAdd.Target_Address__r.SAP_Name_1__c
                if(String.isNotBlank(erpAdd.Target_Address__c) && String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_1__c)){
                    billTo.erpAccountName = erpAdd.Target_Address__r.SAP_Name_1__c;
                }
                if(erpAdd.ECOM_Review_Status__c != 'Approved'){
                    billTo.street = erpAdd.Address_Street_Line_1__c;    
                    billTo.city = erpAdd.Address_City__c;   
                    billTo.state = erpAdd.apiState__c;  
                    billTo.postalCode = erpAdd.Address_Postal_Code__c;  
                    billTo.country = erpAdd.apiCountry__c;                    
                    billTo.isAddNewAddress = false;
                } else { //formula fields values - if target is not empty(master or new) they represent address fields on ERP address else Target Address 
                    billTo.street = erpAdd.fxAddress_Street__c; 
                    billTo.city = erpAdd.fxAddress_City__c; 
                    billTo.state = erpAdd.fxAddress_StateName__c;   
                    billTo.postalCode = erpAdd.fxAddress_Postal__c; 
                    billTo.country = erpAdd.fxAddress_CountryCode__c;
                    billTo.fxAddress = erpAdd.fxAddressFull__c;
                    billTo.isAddNewAddress = true; //falg to show add new address option
                    isAddNewAddress = true;
                }
            } else if(erpAdd.Address_Type__c == 'Ship To'){
                //ERP_AddressModel shipTo = new ERP_AddressModel();
                shipTo.id = erpAdd.Id;
                shipTo.externalId = erpAdd.Target_Address__r.External_Id__c;
                shipTo.isNew = false;
                if(String.isNotBlank(erpAdd.RAD_Identifier__c) && (erpAdd.RAD_Identifier__c.equalsIgnoreCase('rad') || erpAdd.RAD_Identifier__c.equalsIgnoreCase('yes'))){
                    shipTo.isRad = true;
                }
                else{
                    shipTo.isRad = false;
                } 
                shipTo.showAccNumber = true;
                // Adding this due to a bug seen when editing the address (Empty Company Name) By Sathiya
                shipTo.erpAccountName = erpAdd?.ERP_Account_Name__c;
                // Change End
                shipTo.accountId = erpAdd.Account__c;
                if(erpAdd.Contact__c != null){
                    shipTo.contactId = erpAdd.Contact__c;
                }
                shipTo.isEcomEnabled = erpAdd.fxIsECOMenabled__c;
                shipTo.ecomReviewStatus = erpAdd.ECOM_Review_Status__c;
                shipTo.accountGroup = erpAdd.ERP_Account_Group__c;// 0001, 0003
                shipTo.customerNumber = erpAdd.ERP_Customer_Number__c;// -- Account related

                //RWPS-470 - GAr - 18 April 2024 - mapping change from erpadd.ERP_Account_Name__c to erpAdd.Target_Address__r.SAP_Name_1__c
                if(String.isNotBlank(erpAdd.Target_Address__c) && String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_1__c)){
                    shipTo.erpAccountName = erpAdd.Target_Address__r.SAP_Name_1__c;
                }


                if(String.isNOtBlank(erpAdd.Target_Address__c) && String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_1__c))
                {
                    shipTo.sapName=(String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_1__c)?erpAdd.Target_Address__r.SAP_Name_1__c:'')+(String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_2__c)?(', '+erpAdd.Target_Address__r.SAP_Name_2__c):'');
                    shipTo.sapName+=(String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_3__c)?(', '+erpAdd.Target_Address__r.SAP_Name_3__c):'')+(String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_4__c)?(', '+erpAdd.Target_Address__r.SAP_Name_4__c):'');
                    shipTo.showSapName=true;
                }
                else
                {
                    shipTo.showSapName=false;
                }

                //shipTo.salesOrg = erpAdd.ERP_Sales_Org__c;
                shipTo.addressType = erpAdd.Address_Type__c;//Sold To, Ship To, Payer, Bill To, Master
                if(erpAdd.ECOM_Review_Status__c != 'Approved'){
                    shipTo.street = erpAdd.Address_Street_Line_1__c;    
                    shipTo.city = erpAdd.Address_City__c;   
                    shipTo.state = erpAdd.apiState__c;  
                    shipTo.postalCode = erpAdd.Address_Postal_Code__c;  
                    shipTo.country = erpAdd.apiCountry__c;
                    shipTo.isAddNewAddress = false;
                } else { 
                    shipTo.street = erpAdd.fxAddress_Street__c; 
                    shipTo.city = erpAdd.fxAddress_City__c; 
                    shipTo.state = erpAdd.fxAddress_StateName__c;   
                    shipTo.postalCode = erpAdd.fxAddress_Postal__c; 
                    shipTo.country = erpAdd.fxAddress_CountryCode__c;
                    shipTo.fxAddress = erpAdd.fxAddressFull__c;
                    shipTo.isAddNewAddress = true;
                }
                // if(soldToShipTosMap.get(erpAdd.Master_Address__r.External_Id__c) == null){
                //     shipToErpAddressModels = new List<ERP_AddressModel>();
                //     soldToShipTosMap.put(erpAdd.Master_Address__r.External_Id__c, shipToErpAddressModels);
                // }
                // soldToShipTosMap.get(erpAdd.Master_Address__r.External_Id__c).add(shipTo);
                
            }
        }
        
        shipTo.associatedAddresses = new List<ERP_AddressModel>{billTo};
        shipTo.associatedInvoiceAddresses = new List<ERP_AddressModel>{invoice};
        return shipTo;
    }
	//RWPS-564 - Sidak - 1 May 2024 - Added parameter user in convertNewERPAddressesToShipToList method
    public static ERP_AddressModel convertNewERPAddressesToShipToList(List<ERP_Address__c> erpAddresses, User user)
    {
        User us=new ECOM_UserService().getUserByUserId();
        ERP_AddressModel shipToAddressModel=new ERP_AddressModel();
        List<ERP_AddressModel> associatedPayers=new List<ERP_AddressModel>();
        List<ERP_AddressModel> associatedInvoices=new List<ERP_AddressModel>();
        for(ERP_Address__c erpAdd:erpAddresses)
        {
            ERP_AddressModel temp=new ERP_AddressModel();
            temp.id = erpAdd.Id;
            // Adding this due to a bug seen when editing the address (Empty Company Name) By Sathiya
            temp.erpAccountName = erpAdd?.ERP_Account_Name__c;
            // Change End
            temp.accountId = erpAdd.Account__c;
            temp.contactId = erpAdd.Contact__c;
            temp.isEcomEnabled = erpAdd.fxIsECOMenabled__c;
            temp.ecomReviewStatus = erpAdd.ECOM_Review_Status__c;
            temp.accountGroup = erpAdd.ERP_Account_Group__c;// 0001, 0003
            temp.customerNumber = erpAdd.ERP_Customer_Number__c;// -- Account related
            temp.erpAccountName = erpAdd.ERP_Account_Name__c; //RWPS-677 - Sidak - 16 May 2024 - Added erp account name
            temp.addressType = erpAdd.Address_Type__c;//Sold To, Ship To, Payer, Bill To, Master
            if(erpAdd?.Target_Address__c != null){
                temp.eanDoNotUse = erpAdd?.Target_Address__r?.ECOM_EAN_Do_Not_Use__c;
                temp.vatNumber = erpAdd?.Target_Address__r?.ECOM_VAT_Number__c;
                temp.invoiceCustId = erpAdd?.Target_Address__r?.ECOM_E_Invoice_Cust_Id__c;
                temp.puCustEInvoice = erpAdd?.Target_Address__r?.ECOM_PU_Cust_E_Invoice__c;
                temp.emailToInvoice = erpAdd?.Target_Address__r?.ECOM_Email_To_Invoice__c;
            } else {
                // Changes for mapping done as part of ECOM-1933 and ECOM-1942 by Sathiya
                temp.eanDoNotUse = erpAdd?.ECOM_EAN_Do_Not_Use__c;
                temp.vatNumber = erpAdd?.ECOM_VAT_Number__c;
                temp.invoiceCustId = erpAdd?.ECOM_E_Invoice_Cust_Id__c;
                temp.puCustEInvoice = erpAdd?.ECOM_PU_Cust_E_Invoice__c;
                // Changes end
                // Changes for mapping done as part of ECOM-3389 by Sathiya
                temp.emailToInvoice = erpAdd?.ECOM_Email_To_Invoice__c;
                // Changes End
            }
            //RWPS-470 - GAr - 18 April 2024 - mapping change from erpadd.ERP_Account_Name__c to erpAdd.Target_Address__r.SAP_Name_1__c
            if(String.isNotBlank(erpAdd.Target_Address__c) && String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_1__c)){
                temp.erpAccountName = erpAdd.Target_Address__r.SAP_Name_1__c;
            }

            if(String.isNotBlank(erpAdd.ECOM_Review_Status__c) && (erpAdd.ECOM_Review_Status__c.equalsIgnoreCase('New') || erpAdd.ECOM_Review_Status__c.equalsIgnoreCase('In Progress')))
            {
                temp.street = erpAdd.Address_Street_Line_1__c;  
                temp.city = erpAdd.Address_City__c; 
                temp.state = erpAdd.apiState__c;    
                temp.postalCode = erpAdd.Address_Postal_Code__c;    
                temp.country = erpAdd.apiCountry__c; 
            }else{
                temp.street = erpAdd.fxAddress_Street__c;   
                temp.city = erpAdd.fxAddress_City__c;   
                temp.state = erpAdd.fxAddress_StateName__c; 
                temp.postalCode = erpAdd.fxAddress_Postal__c;   
                temp.country = erpAdd.fxAddress_CountryCode__c;
                temp.fxAddress = erpAdd.fxAddressFull__c;
            }  
            
            if(String.isNOtBlank(erpAdd.Target_Address__c) && String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_1__c))
            {
                temp.sapName=(String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_1__c)?erpAdd.Target_Address__r.SAP_Name_1__c:'')+(String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_2__c)?(', '+erpAdd.Target_Address__r.SAP_Name_2__c):'');
                temp.sapName+=(String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_3__c)?(', '+erpAdd.Target_Address__r.SAP_Name_3__c):'')+(String.isNotBlank(erpAdd.Target_Address__r.SAP_Name_4__c)?(', '+erpAdd.Target_Address__r.SAP_Name_4__c):'');
                temp.showSapName=true;
            }
            //RWPS-564 - Sidak - 1 May 2024 - Added logic to populate account name provided from contact
            else if(erpAdd.ECOM_Review_Status__c.equalsIgnoreCase('New') && String.isNotBlank(user.ContactId) && String.isNotBlank(user.Contact.ECOM_AccountNameProvided__c)){
                temp.sapName = user.Contact.ECOM_AccountNameProvided__c;
                temp.showSapName = true;
            }  
            else
            {
                temp.showSapName=false;
            }

            temp.fxAddress = erpAdd.fxAddressFull__c;
            temp.externalId = erpAdd.External_Id__c;
            temp.showAccNumber = true;
            temp.isAddNewAddress = false;
            if(erpAdd.Address_Type__c == 'Payer'){
                if(String.isNotBlank(us.Contact.Default_Bill_to_ERP_Address__c) && us.Contact.Default_Bill_to_ERP_Address__c == erpAdd.Id)
                {
                    temp.isSelected=true;
                }
                associatedPayers.add(temp);
            }
            if(erpAdd.Address_Type__c == 'Bill To'){
                if(String.isNotBlank(us.Contact.Default_Invoice_ERP_Address__c) && us.Contact.Default_Invoice_ERP_Address__c == erpAdd.Id)
                {
                    temp.isSelected=true;
                }
                associatedInvoices.add(temp);
            }
            else if(erpAdd.Address_Type__c == 'Ship To'){
                if(String.isNotBlank(us.Contact.Default_Ship_to_ERP_Address__c) && us.Contact.Default_Ship_to_ERP_Address__c == erpAdd.Id)
                {
                    temp.isSelected=true; 
                }
                if(String.isNotBlank(erpAdd.RAD_Identifier__c) && (erpAdd.RAD_Identifier__c.equalsIgnoreCase('rad') || erpAdd.RAD_Identifier__c.equalsIgnoreCase('yes'))){
                    temp.isRad = true;
                }
                else{
                    temp.isRad = false;
                } 
                shipToAddressModel=temp;
            }
        }
        shipToAddressModel.associatedAddresses=associatedPayers;
        shipToAddressModel.associatedInvoiceAddresses = associatedInvoices;
        if(!shipToAddressModel.associatedAddresses.isEmpty()){ //temp fix added to prevent List Index error
            shipToAddressModel.associatedAddresses[0].associatedAddresses=associatedInvoices;
        }
        return shipToAddressModel;
    }

    public static ERP_AddressModel convertERPToAddressModel(ERP_Address__c erpAddress)
    {
        ERP_AddressModel erpAddresssModel=new ERP_AddressModel();
        erpAddresssModel.id = erpAddress.Id;
        erpAddresssModel.accountId = erpAddress.Account__c;
        erpAddresssModel.contactId = erpAddress.Contact__c;
        erpAddresssModel.isEcomEnabled = erpAddress.fxIsECOMenabled__c;
        erpAddresssModel.ecomReviewStatus = erpAddress.ECOM_Review_Status__c;
        erpAddresssModel.accountGroup = erpAddress.ERP_Account_Group__c;// 0001, 0003
        erpAddresssModel.customerNumber = erpAddress.ERP_Customer_Number__c;// -- Account related
        erpAddresssModel.addressType = erpAddress.Address_Type__c;//Sold To, Ship To, Payer, Bill To, Master
        if(erpAddress?.Target_Address__c != null){
            erpAddresssModel.eanDoNotUse = erpAddress?.Target_Address__r?.ECOM_EAN_Do_Not_Use__c;
            erpAddresssModel.vatNumber = erpAddress?.Target_Address__r?.ECOM_VAT_Number__c;
            erpAddresssModel.invoiceCustId = erpAddress?.Target_Address__r?.ECOM_E_Invoice_Cust_Id__c;
            erpAddresssModel.puCustEInvoice = erpAddress?.Target_Address__r?.ECOM_PU_Cust_E_Invoice__c;
            erpAddresssModel.emailToInvoice = erpAddress?.Target_Address__r?.ECOM_Email_To_Invoice__c;
        } else {
            // Changes for mapping done as part of ECOM-1933 and ECOM-1942 by Sathiya
            erpAddresssModel.eanDoNotUse = erpAddress?.ECOM_EAN_Do_Not_Use__c;
            erpAddresssModel.vatNumber = erpAddress?.ECOM_VAT_Number__c;
            erpAddresssModel.invoiceCustId = erpAddress?.ECOM_E_Invoice_Cust_Id__c;
            erpAddresssModel.puCustEInvoice = erpAddress?.ECOM_PU_Cust_E_Invoice__c;
            // Changes end
            // Changes for mapping done as part of ECOM-3389 by Sathiya
            erpAddresssModel.emailToInvoice = erpAddress?.ECOM_Email_To_Invoice__c;
            // Changes End
        }
        if(String.isNotBlank(erpAddress.ECOM_Review_Status__c) && (erpAddress.ECOM_Review_Status__c.equalsIgnoreCase('New') || erpAddress.ECOM_Review_Status__c.equalsIgnoreCase('In Progress')))
        {
            erpAddresssModel.street = erpAddress.Address_Street_Line_1__c;  
            erpAddresssModel.city = erpAddress.Address_City__c; 
            erpAddresssModel.state = erpAddress.apiState__c;    
            erpAddresssModel.postalCode = erpAddress.Address_Postal_Code__c;    
            erpAddresssModel.country = erpAddress.apiCountry__c; 
        }else{
            erpAddresssModel.street = erpAddress.fxAddress_Street__c;   
            erpAddresssModel.city = erpAddress.fxAddress_City__c;   
            erpAddresssModel.state = erpAddress.fxAddress_StateName__c; 
            erpAddresssModel.postalCode = erpAddress.fxAddress_Postal__c;   
            erpAddresssModel.country = erpAddress.fxAddress_CountryCode__c;
        }   
        erpAddresssModel.fxAddress = erpAddress.fxAddressFull__c;
        erpAddresssModel.externalId = erpAddress.External_Id__c;
		erpAddresssModel.showAccNumber = true;
        if(String.isNotBlank(erpAddress.Target_Address__c) && String.isNotBlank(erpAddress.Target_Address__r.SAP_Name_1__c) || Test.isRunningTest())
        {
            erpAddresssModel.sapName=(String.isNotBlank(erpAddress.Target_Address__r.SAP_Name_1__c)?erpAddress.Target_Address__r.SAP_Name_1__c:'')+(String.isNotBlank(erpAddress.Target_Address__r.SAP_Name_2__c)?(', '+erpAddress.Target_Address__r.SAP_Name_2__c):'');
            erpAddresssModel.sapName+=(String.isNotBlank(erpAddress.Target_Address__r.SAP_Name_3__c)?(', '+erpAddress.Target_Address__r.SAP_Name_3__c):'')+(String.isNotBlank(erpAddress.Target_Address__r.SAP_Name_4__c)?(', '+erpAddress.Target_Address__r.SAP_Name_4__c):'');
            erpAddresssModel.showSapName=true;
        }
        else
        {
            erpAddresssModel.showSapName=false;
        }

		//Changes for the mailing address logic
        erpAddresssModel.isShowAddress = ((erpAddress.Master_Address__c != null && erpAddress.Target_Address__c == null) ||
                                          (erpAddress.Master_Address__c != null && erpAddress.Target_Address__c != null 
                                           && erpAddress.Target_Address__c != erpAddress.Master_Address__c));
		//Changes end
        //RWPS-470 - GAr - 18 April 2024 - mapping change from erpadd.ERP_Account_Name__c to erpAdd.Target_Address__r.SAP_Name_1__c
        if(String.isNotBlank(erpAddress.Target_Address__c) && String.isNotBlank(erpAddress.Target_Address__r.SAP_Name_1__c)){
            erpAddresssModel.erpAccountName = erpAddress.Target_Address__r.SAP_Name_1__c;
        }
        else if(String.isBlank(erpAddress.Target_Address__c)){ //RWPS-1503
            erpAddresssModel.erpAccountName = erpAddress.ERP_Account_Name__c;
        }

        if(String.isNotBlank(erpAddress.Target_Address__c) && String.isNotBlank(erpAddress.Target_Address__r.External_Id__c))
        {
            erpAddresssModel.externalId = erpAddress.Target_Address__r.External_Id__c;
            erpAddresssModel.showAccNumber = true;
        }

        return erpAddresssModel;

        
    }

    public static  ECOM_MyAccountModel createDummySoldTo(){
        ECOM_MyAccountModel accountModel = new ECOM_MyAccountModel();
        
        return accountModel;
    }
    
    /**
     * @description This method maps the primary address fields for ERP_Address__c record
     * @author vramachandran@rafter.one | 23 Dec 2023
     * @param addressRecord | ERP_Address__c
     * @return ERP_AddressModel
     */
    public static ERP_AddressModel getAddressModelForRecord(ERP_Address__c addressRecord){
        ERP_AddressModel addressModel = new ERP_AddressModel();
        
        if(addressRecord != null){
        	
            
            //account information
            addressModel.id = addressRecord?.Id;
            addressModel.accountId = addressRecord?.Account__c;
            addressModel.accountGroup = addressRecord?.ERP_Account_Group__c;
            addressModel.erpAccountName = addressRecord?.ERP_Account_Name__c;
            addressModel.sapName = addressRecord?.ERP_Account_Name__c;
            addressModel.isEcomEnabled = addressRecord?.ECOM_isEnabled__c;
            addressModel.externalId = addressRecord?.ERP_Customer_Number__c;
            addressModel.showAccNumber = true;
            addressModel.ecomReviewStatus = addressRecord?.ECOM_Review_Status__c;
            
            //address information
            addressModel.addressType = addressRecord?.Address_Type__c;
            addressModel.street = addressRecord?.Address_Street_Line_1__c;
            addressModel.street2 = addressRecord?.Address_Street_Line_2__c;
            addressModel.city = addressRecord?.Address_City__c;
            addressModel.state = addressRecord?.Address_State__c;
            addressModel.country = addressRecord?.Address_Country__c;
            addressModel.postalCode = addressRecord?.Address_Postal_Code__c;
            if(String.isNotBlank(addressRecord?.Address_Type__c) && String.isNotBlank(addressRecord?.fxAddress_CountryName__c) && addressRecord?.Address_Type__c == System.Label.ECOM_ERPAddressTypeMaster){
                addressModel.po_CountryName = addressRecord?.fxAddress_CountryName__c;
            }
            
            if(addressRecord?.Target_Address__c != null){
                addressModel.eanDoNotUse = addressRecord?.Target_Address__r?.ECOM_EAN_Do_Not_Use__c;
                addressModel.vatNumber = addressRecord?.Target_Address__r?.ECOM_VAT_Number__c;
                addressModel.invoiceCustId = addressRecord?.Target_Address__r?.ECOM_E_Invoice_Cust_Id__c;
                addressModel.puCustEInvoice = addressRecord?.Target_Address__r?.ECOM_PU_Cust_E_Invoice__c;
                addressModel.emailToInvoice = addressRecord?.Target_Address__r?.ECOM_Email_To_Invoice__c;
            } else {
                // Changes for mapping done as part of ECOM-1933 and ECOM-1942 by Sathiya
                addressModel.eanDoNotUse = addressRecord?.ECOM_EAN_Do_Not_Use__c;
                addressModel.vatNumber = addressRecord?.ECOM_VAT_Number__c;
                addressModel.invoiceCustId = addressRecord?.ECOM_E_Invoice_Cust_Id__c;
                addressModel.puCustEInvoice = addressRecord?.ECOM_PU_Cust_E_Invoice__c;
                // Changes end
                // Changes for mapping done as part of ECOM-3389 by Sathiya
                addressModel.emailToInvoice = addressRecord?.ECOM_Email_To_Invoice__c;
                // Changes End
            }
            //punchout config information
            //RWPS-7241-Start
            if(addressRecord.ECOM_Punchout_Is_Enabled__c && addressRecord?.Address_Type__c == System.Label.ECOM_ERPAddressTypeMaster){
                List<Punchout_Maintenance__c> configRecordList = ERP_AddressRepo.getPunchoutConfigs(null,null,null,addressRecord?.Id);
                if(configRecordList != null && !configRecordList.isEmpty()){
                    Punchout_Maintenance__c configRecord = configRecordList[0];
                     addressModel.po_AccountName = configRecord?.ECOM_Punchout_Customer_Name__c;
                     addressModel.po_AccountUrl = configRecord?.ECOM_Punchout_Customer_Logo__c;
                     addressModel.po_CustomerCode = configRecord?.ECOM_Punchout_Customer_Id__c;
                     addressModel.po_isPunchoutEnabled = configRecord?.ECOM_Punchout_Is_Enabled__c;
                     addressModel.po_ProductExcludeQuery = configRecord?.ECOM_Punchout_Products_Exclude_Query__c;
                     addressModel.po_ProductIncludeQuery = configRecord?.ECOM_Punchout_Products_Include_Query__c;
                     addressModel.po_ShowListPrice = configRecord?.ECOM_Punchout_Show_List_Price__c;
                     addressModel.po_UnitOfMeasure = configRecord.ECOM_Punchout_Unit_Of_Measurement__c;
                     addressModel.po_SenderSharedSecret = configRecord?.ECOM_POSR_Sender_Shared_Secret__c;
                     addressModel.po_SenderSharedIdent = configRecord?.ECOM_POSR_Sender_Shared_Identity__c;
                     addressModel.po_PunchoutResponseFormat = configRecord?.ECOM_Punchout_Format__c;
                     addressModel.po_TimeZone = configRecord?.ECOM_Punchout_Account_TimeZone_SID__c;
                     addressModel.po_Locale = String.isNotBlank(addressRecord?.ECOM_Punchout_Country_Locale__c) ? addressRecord?.ECOM_Punchout_Country_Locale__c  : '';
                     if(String.isNotBlank(addressRecord?.Account__r.CurrencyIsoCode)){
                        addressModel.po_CurrencyIsoCode =  addressRecord?.Account__r.CurrencyIsoCode ;
                     }
                     addressModel.po_CountryCode = addressRecord?.fxAddress_CountryCode__c;
                     addressModel.po_Processors = configRecord?.ECOM_Punchout_Processors__c; //GAr ECOM-2100
                     addressModel.po_DefaultUNSPSC = configRecord?.ECOM_Punchout_Default_UNSPSC__c; //GAr RWPS-410 - mapping of new field as per requirement
                    //RWPS-7241-End
                }
              } 
            }

        return addressModel;
    }
    
    
    /**
     * @description This method loops through address list to build the addressmodel
     * @author vramachandran@rafter.one | 02 Jan 2024
     * @param erpAddressList | List<ERP_Address__c>
     * @returns ERP_AddressModel
     */
    @TestVisible
    private static ERP_AddressModel getAddressModel(List<ERP_Address__c> erpAddressList){
        ERP_AddressModel addressModel = new ERP_AddressModel();
        
        Map<String,ERP_AddressModel> addressMap = new Map<String, ERP_AddressModel>();
        String accountId;
        System.debug('erpAddressList:: '+ erpAddressList);
        System.debug('erpAddressListacc:: '+ erpAddressList[0].Account__c);
        
        for(ERP_Address__c erpAddress : erpAddressList){
            ERP_AddressModel currentModel = getAddressModelForRecord(erpAddress);
            System.debug('outside If CurrentModel:: '+ currentModel); 
            if(null != currentModel){
                addressMap.put(currentModel.addressType, currentModel);
            }
        }  
        System.debug('addressMap:: '+ JSON.serialize(addressMap));
        if(null != addressMap && !addressMap.isEmpty()){
            if(addressMap.containsKey(ECOM_Constant.ERP_ADDRESS_TYPE_MASTER)){
                addressModel = addressMap.get(ECOM_Constant.ERP_ADDRESS_TYPE_MASTER);
                
                if(addressModel.addressType == ECOM_Constant.ERP_ADDRESS_TYPE_MASTER){
                    for(String addressType :  addressMap.keySet()){
                        
                        ERP_AddressModel currentModel = addressMap.get(addressType);

                        if(currentModel.addressType == ECOM_Constant.ERP_ADDRESS_TYPE_SHIP_TO){
                            addressModel.po_ShipToAddress = currentModel;
                        }//if soldto assign as po sold to on primary
                        else if(currentModel.addressType.equalsIgnoreCase(ECOM_Constant.ERP_ADDRESS_TYPE_SOLD_TO)){
                            addressModel.po_SoldToAddress = currentModel;
                        }//if payer assign as po payer to on primary
                        else if(currentModel.addressType == ECOM_Constant.ERP_ADDRESS_TYPE_PAYER){
                            addressModel.po_PayerAddress = currentModel;
                        }//if payer assign as po payer to on primary
                        else if(currentModel.addressType == ECOM_Constant.ERP_ADDRESS_TYPE_BILL_TO){
                            addressModel.po_BillToAddress = currentModel;
                        }
                        //check and populate accountid on master
                        if(String.isNotBlank(currentModel.accountId) && addressModel.accountId != currentModel.accountId){
                            addressModel.accountId =  currentModel?.accountId;
                        }
                        //check and populate currency iso code
                        if(String.IsNotBlank(currentModel?.po_CurrencyIsoCode)){
                            addressModel.po_CurrencyIsoCode = currentModel?.po_CurrencyIsoCode;
                        }
                    }
                }
            }
        }
        
        System.debug('addressModel : '+JSON.serialize(addressModel));

        return addressModel;
    }
    
	/**
	 * @description This method returns the ERP_AddressModel for an punchout account id //TODO : deprecate method
	 * @author vramachandran@rafter.one | 02 Jan 2023
	 * @param accountId | String
	 * @returns ERP_AddressModel
	 */
    public static ERP_AddressModel getERPAddressModelForPunchoutAccountId(String accountId){
        ERP_AddressModel addressModel  = new ERP_AddressModel();
        //get Master, Sold To, Ship To and Payer address information for current user and salesorg combo
        List<ERP_Address__c> addressList = ERP_AddressRepo.getMasterAndLinkedAddressForPunchoutAccountId(accountId);
        
        //if address Exists iterate and build addressModel
        if(null != addressList && !addressList.isEmpty()){
            addressModel = getAddressModel(addressList);
        }
        return addressModel;
        
    }
    
    /**
     * @description This method returns the Master ERP Address model for a punchout user
     * @author vramachandran@rafter.one | 02 Jan 2024
     * @param userRecord | User
     * @returns ERP_AddressModel 
     */
    public static ERP_AddressModel getMasterERPAddressModelForPunchoutUser(User userRecord){
        ERP_AddressModel addressModel  = new ERP_AddressModel();
		
        List<ERP_Address__c> addressList = ERP_AddressRepo.getERPMasterAddressForPunchoutAccountId(userRecord.AccountId);
        
        if(null != addressList && !addressList.isEmpty()){
            String masterAddressId = addressList[0]?.Target_Address__c;
            
            List<ERP_Address__c> erpMasterAddressList = ERP_AddressRepo.getERPMasterAddressForPunchoutMasterId(masterAddressId);
            
            
            if(null != erpMasterAddressList && !erpMasterAddressList.isEmpty()){
                addressModel = getAddressModel(erpMasterAddressList);
            }
        }
        return addressModel;
    }
    
    /**
     * @description This method returns the list of Account Id's for ERP Addresses marked for punchout
     * @author vramachandran@rafter.one | 07 Jan 2024
     * @author ssingh@rafter.one | 11 Nov 2024 | RWPS-1809
     * @returns Map<String,String>
     */
    public static Map<String,String> getPunchoutAccountIdList(){
        Map<String,String> accountIdToCountryMap = new Map<String,String>();
        List<Account> accountList = new List<Account>();
        // RWPS-5776 - START
        List<Punchout_Maintenance__c> punchoutConfigList = ERP_AddressRepo.getPunchoutConfigs(null,null,null,null);
        Set<Id> punchoutMasterId = new Set<Id>();
        for(Punchout_Maintenance__c record:punchoutConfigList){
            punchoutMasterId.add(record.ERP_Address__c);            
        }
        List<ERP_Address__c> addressList = ERP_AddressRepo.getPunchoutERPAddresses(punchoutMasterId);
        // RWPS-5776 - END
        if(null != addressList && !addressList.isEmpty()){
            for(ERP_Address__c address :addressList){
                accountIdToCountryMap.put(address.Account__c, address.fxAddress_CountryName__c);
            }
        }
        return accountIdToCountryMap;
    }
    
    
    /**
     * @description This method returns the ERP Address (Ship to, Sold to, Bill To, Payer) and the related target.master address for
     *  a punchout account Unique name defined on the target.master( ECOM Punchout Customer Id field)
     * @author vramachandran@rafter.one | 15 Jan 2024
     * @param poAccountUniqueName | String
     * @returns List<ERP_Address> 
     */
    public static ERP_AddressModel getPunchoutAddressesForERPAddressModel(String poAccountUniqueName){
        ERP_AddressModel addressModel = new ERP_AddressModel();
        List<ERP_Address__c> addressList = new List<ERP_Address__c>(); 
        
        addressList = ERP_AddressRepo.getPunchoutAddressesForERPAddressModel(poAccountUniqueName);
        
        System.debug('addressList:: '+ JSON.serialize(addressList));
        
        if(null != addressList && !addressList.isEmpty()){
            addressModel = getAddressModel(addressList);
        }
        
        System.debug('addressModel:: '+ addressModel);
        
        return addressModel;
    }
    
    /**
     * @description This method returns the ERP Address (Ship to, Sold to, Bill To, Payer) and the related target.master address for
     *  a punchout account Id 
     * @author vramachandran@rafter.one | 16 Jan 2024
     * @param poAccountUniqueName | String
     * @returns List<ERP_Address> 
     */
    public static ERP_AddressModel getPunchoutAddressesForAccountId(String poAccountId){
        ERP_AddressModel addressModel = new ERP_AddressModel();
        List<ERP_Address__c> addressList = new List<ERP_Address__c>(); 
        
        addressList = ERP_AddressRepo.getERPMasterAddressForPunchoutAccountId(poAccountId);
        System.debug('getPunchoutAddressesForAccountId.addressList:: '+ JSON.serialize(addressList));
        
        if(null != addressList && !addressList.isEmpty()){
            String masterAddressId;
            for(ERP_Address__c address : addressList){
                if(null != address && String.isNotBlank(address.Target_Address__c) && (address.Address_Type__c == 'Ship To' || address.Address_Type__c == 'Sold To')){
                    masterAddressId = address.Target_Address__c;
                    break;
                } else if(null != address && String.isNotBlank(address.Master_Address__c) && (address.Address_Type__c == 'Payer')){		
	                    masterAddressId = address.Master_Address__c;		
                    	break;		
                }
            }
            
            System.debug('getMasterERPAddressModelForPunchoutUser:masterAddressId:: '+ masterAddressId  );     
            
            List<ERP_Address__c> erpMasterAddressList = ERP_AddressRepo.getPunchoutAddressesForERPMasterAddressId(masterAddressId);
            System.debug('erpMasterAddressList:: '+ JSON.serialize(erpMasterAddressList));
            
            if(null != erpMasterAddressList && !erpMasterAddressList.isEmpty()){
                addressModel = getAddressModel(erpMasterAddressList);
            }
            System.debug('getPunchoutAddressesForAccountId.addressModel:: '+ JSON.serialize(addressModel));
        }
        System.debug('addressModel:: '+ addressModel);
        
        return addressModel;
    }

}