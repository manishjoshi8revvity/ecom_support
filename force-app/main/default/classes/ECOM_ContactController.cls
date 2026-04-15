/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*
* 2. Description - This class acts as a controller for Contact page.
*				- return and save the Account Records
				- Update Contact Point Address Record on Contact
				- save and return Contact Records
* 3. Objects referenced
*    - Contact
*
* 4. Callouts to additional Components (including their methods) or None: 
*    - None
*    
* 5. Dependant Class(es):
*    - ECOM_ContactService
*    - ECOM_AccountService
*    - ECOM_CustomMetadataService
*    - ECOM_CartUtil
*    - ECOM_AccountService
*    - ECOM_CustomMetadataService
*
* 6. Test Class Name: 
*    - ECOM_ContactController_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vipul 2023.09.21
*    - Sidak 2024.02.06 Added logs in saveSoldToERPAddress, getAddressDetails, updateShiptToAndBillTo methods. Ticket - RWPS-95
*	 - sathiya 2024.04.29, added a new response variable for method fetchERPAddressDetails. ECOM - 1933
*    - Gaurang 2024.06.03 - Added method for creating login activity - ECOM-128
*    - Sidak 2024.05.01 Updated method fetchNewERPAddresses - Added parameter us in convertNewERPAddressesToShipToList method. Ticket - RWPS-564
*    - Sidak 2024.05.07 Updated method getAddressDetails - Added a null check for ECOM_AddressRegistration__c field. Ticket - RWPS-634
*    - Sidak 2024.05.15 Added method getContactInfo - To fetch the Contact details. Ticket - RWPS-677
*    - Sidak 2024.07.29 Updated methods updateShiptToAndBillTo, createERPAddresses - To save the registration info. Ticket - RWPS-1123
*    - Poonam 2025.04.18 Updated method fetchNewERPAddresses- Retrieves account company name from contact - RWPS-1506
*    - Gaurav 2025.09.09 Updated method createERPAddresses- added exception handling- RWPS-3813
*    - Gaurav 2025.09.19 Updated method getChangeAccountData- added changes to return payer address - RWPS-3773
*    - Mahesh 2025.10.8 Updated method checkSoldToERPAddress - added disabledAddresses list - RWPS-4498
*    - Mahesh 2025.10.29 Updated method checkSoldToERPAddress - added isAccountDisabled - RWPS-4776
*    - Mahesh 2025.1.03 Updated method createERPAddresses - replace the hardcoded message with label - RWPS-5118
*************************************************************/
public without sharing class ECOM_ContactController {

    public static String CLASSNAME = 'ECOM_ContactController';

    /*@AuraEnabled
    public static Map<String,Object> getContactDetails(String contactId)
    {
        Map<String,Object> returnMap=new Map<String,Object>();
        try { 
            returnMap=ECOM_ContactService.getAddressDetails(contactId);
            Contact con=(Contact)returnMap.get('contact');
            if(con.ECOM_AddressRegistration__c.equalsIgnoreCase('Select BT') || con.ECOM_AddressRegistration__c.equalsIgnoreCase('Completed'))
            {
                List<Account> accs=ECOM_AccountService.getAccountBasedOnIds(new List<String>{con.AccountId});
                String shippingCountry=accs[0].ShippingCountry;
                String salesOrg=ECOM_CustomMetadataService.getSalesOrg(shippingCountry);
                returnMap=ECOM_AccountService.getAccountFunctions(returnMap,con.AccountId,salesOrg);
                returnMap= ECOM_AccountService.getCpaBasedOnContactAccountAndType(returnMap,con.AccountId,con.Id);
            }
            returnMap.put('Success',true);
        } catch (Exception e) {
            returnMap=ECOM_ContactService.createErrorMap(e);
        }
        return returnMap;
    }*/

    /**
    * @description 
    * @author mkumar@rafter.one | 09-21-2023 
    * @param contactId 
    * @return Contact 
    **/
    @AuraEnabled
    public static Map<String,Object> getContactBasedOnId(String contactId)
    {
        Map<String,Object> response=new Map<String,Object>();
        response.put('success',false);
        Contact con= ECOM_ContactService.getContactDetails(contactId);
        response.put('contact',con);
        Type erpAddressService = Type.forName(ECOM_Constant.ERP_ADDRESS_SERVICE);
        ERP_IAddressService erpAddressServiceInstance = (ERP_IAddressService)erpAddressService.newInstance();
        ERP_AddressModel shiptToModel = new ERP_AddressModel();
        ERP_AddressModel billToModel = new ERP_AddressModel();
        if(String.isNotBlank(con.Default_Bill_to_ERP_Address__c))
        {
            ERP_Address__c billToERP=erpAddressServiceInstance.fetchERPAddressesById(con.Default_Bill_to_ERP_Address__c)[0];
            response.put('billToAddress',ERP_AddressUtil.convertERPToAddressModel(billToERP));
        }
        if(String.isNotBlank(con.Default_Ship_to_ERP_Address__c))
        {
            ERP_Address__c shipToERP=erpAddressServiceInstance.fetchERPAddressesById(con.Default_Ship_to_ERP_Address__c)[0];
            response.put('shipToAddress',ERP_AddressUtil.convertERPToAddressModel(shipToERP));
        }
        response.put('success',true);
        return response;
    }

    /**
    * @description 
    * @author mkumar@rafter.one | 09-21-2023 
    * @param accountId 
    * @param con 
    * @return Map<String, Object> 
    **/
    /*@AuraEnabled
    public static Map<String,Object> saveAccountAndGetDetails(String accountId,Contact con){
        Map<String,Object> returnMap=new Map<String,Object>();
        try {
            returnMap=ECOM_ContactService.saveAccountAndGetDetails(accountId,con);
            Contact contact=(Contact)returnMap.get('contact');
            if(contact.ECOM_AddressRegistration__c.equalsIgnoreCase('Select BT') || contact.ECOM_AddressRegistration__c.equalsIgnoreCase('Completed'))
            {
                List<Account> accs=ECOM_AccountService.getAccountBasedOnIds(new List<String>{accountId});
                String shippingCountry=accs[0].ShippingCountry;
                String salesOrg=ECOM_CustomMetadataService.getSalesOrg(shippingCountry);
                returnMap=ECOM_AccountService.getAccountFunctions(returnMap,contact.AccountId,salesOrg);
                returnMap= ECOM_AccountService.getCpaBasedOnContactAccountAndType(returnMap,contact.AccountId,contact.Id);
            }
            Map<String,Object> tempMap=ECOM_CartUtil.updateCartForAccountSwitch(contact.Id);
            if((Boolean)tempMap.get('Success')==false)
            {
                returnMap.put('Success',false);
                returnMap.put('ErrorMessage',(String)tempMap.get('ErrorMessage'));
                return returnMap;
            }
            returnMap.put('Success',true);
        } catch (Exception e) {
           returnMap=ECOM_ContactService.createErrorMap(e);
        }
        return returnMap;
    }*/

    /**
    * @description 
    * @author mkumar@rafter.one | 09-21-2023 
    * @param con 
    * @return Map<String, Object> 
    **/
    /*@AuraEnabled
    public static Map<String,Object> getMainAccountDetails(Contact con){
        Map<String,Object> returnMap=new Map<String,Object>();
        try 
        {
            List<Account> accs=new List<Account>();
            if(con.ECOM_AddressRegistration__c.equalsIgnoreCase('Select ST & BT'))
            {
                accs=ECOM_AccountService.getAccountBasedOnDomainsAndCountry(con.fxDomain__c,con.ECOM_CountryProvided__c);
            }
            else {
                List<String> accIds=ECOM_AccountService.getAssociatedAccounts(con.Id);
                accs=ECOM_AccountService.getAccountBasedOnIds(accIds);
            }
            returnMap.put('topHierarchyAccounts',accs);
            returnMap.put('Success',true);
            returnMap.put('contact',con);
        } 
        catch (Exception e) 
        {
            returnMap=ECOM_ContactService.createErrorMap(e);
        }
        return returnMap;
    }*/

    @AuraEnabled
    public static Map<String,Object> saveContact(Contact con){
        Map<String,Object> returnMap= new Map<String,Object> ();
        try 
        {
            returnMap= ECOM_ContactService.saveContact(con);
            if(!String.isBlank(con.Phone))
            {
                User us=new User();
                us.Id=UserInfo.getUserId();
                us.Phone=con.Phone;
                ECOM_UserService.updateUser(us);
            }
            String contactId=((Contact)returnMap.get('Contact')).Id;
            Map<String,Object> tempMap=ECOM_CartUtil.updateCartForAccountSwitch(contactId);
            if((Boolean)tempMap.get('Success')==false)
            {
                returnMap.put('Success',false);
                returnMap.put('ErrorMessage',(String)tempMap.get('ErrorMessage'));
                return returnMap;
            }
        } catch (Exception e) {
            returnMap=ECOM_ContactService.createErrorMap(e);
        }
        return returnMap;

    }

    /**
    * @description 
    * @author mkumar@rafter.one | 09-21-2023 
    * @param billingCPA 
    * @param contactID 
    * @return Map<String, Object> 
    **/
    /*@AuraEnabled
    public static Map<String,Object> upsertBillingCPA(ContactPointAddress billingCPA,String contactID){
        Map<String,Object> returnMap=new Map<String,Object>();
        try {
            if(String.isNotBlank(billingCPA.Id))
            {
                String status=ECOM_AccountService.getCpaStatus(billingCPA.Id);
                if(String.isNotBlank(status) && !status.equalsIgnoreCase('New'))
                {
                    returnMap.put('Success',true);
                    returnMap.put('Message','Your Address is in review, so it cannot be modified.');
                    return returnMap;
                }
                Boolean anyOrders=ECOM_OrderService.anyOrderWithBillingCPA(billingCPA.Id);
                if(anyOrders)
                {
                    returnMap.put('Success',true);
                    returnMap.put('Message','You have already placed an order with this address,so it can not be modified.');
                    return returnMap;
                }
            }
            List<ContactPointAddress> cpas=ECOM_AccountService.upsertCPAs(new List<ContactPointAddress>{billingCPA});
            Contact con=ECOM_ContactService.upsertBillingCPA(cpas[0],contactID);
            returnMap.put('Contact',con);
            returnMap.put('Success',true);
        } catch (Exception e) {
            returnMap=ECOM_ContactService.createErrorMap(e);
        }
        return returnMap;
    }*/


    @AuraEnabled
    public static Map<String,Object>  getAddressDetails()
    {
        Map<String,Object> response = new Map<String,Object>();
        String supportData = '';
        try {
            List<ECOM_MyAccountModel> myAccountModels = new List<ECOM_MyAccountModel>();
            response.put('success',false);
            User us = new ECOM_UserService().getUserByUserId();
            String salesOrg = ECOM_CustomMetadataService.getSalesOrg(ECOM_Util.getCountryFromUser(us));
            Type erpAddressService = Type.forName(ECOM_Constant.ERP_ADDRESS_SERVICE);
            ERP_IAddressService erpAddressServiceInstance = (ERP_IAddressService)erpAddressService.newInstance();
            //ssingh@rafter.one | 2024.05.07 | Added a null check for ECOM_AddressRegistration__c field. Ticket - RWPS-634
            if(String.isNotBlank(us.Contact.ECOM_AddressRegistration__c) && us.Contact.ECOM_AddressRegistration__c.equalsIgnoreCase('Select ST & BT'))
            {
                //Get the top 5 sold to erp based on Domain
                //based on contact.fxDomain__c get all the ERP Addresses of type Sold to - Account.Domain
                myAccountModels = erpAddressServiceInstance.fetchERPAddressesByDomain(us, us.Contact.fxDomain__c, salesOrg);
                response.put('isAccountSelected',false);
                response.put('address',myAccountModels);
            }
            else 
            {
                response=ECOM_ContactService.getERPData(us);
            }
            response.put('addressRegistration',us.Contact.ECOM_AddressRegistration__c);
            // Added by sathiya on 2024/04/29 for ECOM-1933
            response.put('billToValidationFields', ECOM_CustomMetadataService.getStoreConfigurationByLabel(ECOM_Constant.BILL_TO_FIELD_VALIDATION));
            // Changes end by sathiya
            // Added by sathiya on 2024/05/13 for ECOM-1939
            response.put('invoiceValidationFields', ECOM_CustomMetadataService.getStoreConfigurationByLabel(ECOM_Constant.INVOICE_FIELD_VALIDATION));
            // Changes end by sathiya
            response.put('success',true);
        } catch (Exception ex) {
            response.put('responseCatch ', ex.getMessage()+ex.getStackTraceString());
            ECOM_ApplicationLogsUtil.logFailure(ex, 'Address Details', className, 'getAddressDetails', supportData);
        }
        return response;
    }

    @AuraEnabled
    public static Map<String,Object>  saveSoldToERPAddress(String soldToId,String accountId,String addressRegistration){
        
        Map<String,Object> response = new Map<String,Object>();
        String supportData = JSON.serialize(addressRegistration);
        try {
            Boolean deleteACR = false;
            String oldAccountId = '';
            Type erpAddressService = Type.forName(ECOM_Constant.ERP_ADDRESS_SERVICE);
            ERP_IAddressService erpAddressServiceInstance = (ERP_IAddressService)erpAddressService.newInstance();
            response.put('success',false);
            User us = new ECOM_UserService().getUserByUserId();
            String salesOrg = ECOM_CustomMetadataService.getSalesOrg(ECOM_Util.getCountryFromUser(us));
            Contact con=new Contact();
            con.Id=us.ContactId;
            if(String.isNotBlank(addressRegistration) && (addressRegistration.equalsIgnoreCase('Select ST & BT') || addressRegistration.equalsIgnoreCase('Select BT')))
            {
                addressRegistration='Select BT';
                if(String.isNotBlank(accountId) && !accountId.equalsIgnoreCase(us.Contact.AccountId))
                {
                    deleteACR=true;
                    oldAccountId = us.Contact.AccountId;
                }
            }
            String result=ECOM_ContactService.makeAccountActive(con,accountId,soldToId,null,null,null,addressRegistration,null);
    
            if(deleteACR)
            {
                Map<String,Object> temp = ECOM_AccountService.deleteTemporaryACR(us.ContactId,oldAccountId);
                if(!(Boolean)temp.get('Success'))
                {
                    response.put('ErrorMessage',(String)temp.get('ErrorMessage'));
                }
            }
    
            List<ECOM_MyAccountModel> myAccountModels = new List<ECOM_MyAccountModel>();
            response.put('address',myAccountModels);
            response.put('isAccountSelected',false);
            us = new ECOM_UserService().getUserByUserId();
            if(result.equalsIgnoreCase('success'))
            {
                response=ECOM_ContactService.getERPData(us);
                response.put('addressRegistration',us.Contact.ECOM_AddressRegistration__c);
                response.put('success',true);
            }
        } catch (Exception ex) {
            response.put('responseCatch ', ex.getMessage()+ex.getStackTraceString());
            ECOM_ApplicationLogsUtil.logFailure(ex, 'Save Sold To ERP Address', className, 'saveSoldToERPAddress', supportData);
        }
        return response;
    }

    @AuraEnabled
    public static Map<String,Object>  updateShiptToAndBillTo(String contactId,String soldToId,String shiptToId,String billToId, String invoiceErpId,String addressRegistration,String attentionRecipient){

        Map<String,Object> response = new Map<String,Object>();
        String supportData = JSON.serialize(addressRegistration);
        try {
            if(String.isNotBlank(addressRegistration) && !addressRegistration.equalsIgnoreCase('Completed'))
            {
                addressRegistration='Completed';
            } 
            String accId=null;
            if(String.isNotBlank(soldToId))
            {   
                List<ERP_Address__c> addresses = ERP_AddressService.fetchERPAddressesById(soldToId);
                if(!addresses.isEmpty())
                    accId=addresses[0].Account__c;
            }
            String result=ECOM_ContactService.makeAccountActive(new contact(Id=contactId),accId,soldToId,shiptToId,billToId, invoiceErpId,addressRegistration,attentionRecipient);
    
            Contact contactToUpdate=new Contact();
            contactToUpdate.Id=contactId;
            contactToUpdate.ECOM_Is_Mapped__c=true;
            ECOM_ContactService.updateContact(contactToUpdate);
    
            //ECOM_CartService.updateAssociatedCarts(); RWPS-164
            ECOM_ContactService.saveRegistrationInfo(contactId,shiptToId,billToId,attentionRecipient);//RWPS-1123
    
            if(result.equalsIgnoreCase('success'))
            {
                response.put('success',true);
            }
            else {
                response.put('success',false);
            }
        } catch (Exception ex) {
            response.put('responseCatch ', ex.getMessage()+ex.getStackTraceString());
            ECOM_ApplicationLogsUtil.logFailure(ex, 'Update Ship To and Bill To', className, 'updateShiptToAndBillTo', supportData);
        }
        return response;
    }

    @AuraEnabled
    public static Map<String,Object> getChangeAccountData()
    {
        Map<String,Object> response = new Map<String,Object>();
        List<ECOM_MyAccountModel> myAccountModels = new List<ECOM_MyAccountModel>();
        Type erpAddressService = Type.forName(ECOM_Constant.ERP_ADDRESS_SERVICE);
        ERP_IAddressService erpAddressServiceInstance = (ERP_IAddressService)erpAddressService.newInstance();
        response.put('success',false);
        User us = new ECOM_UserService().getUserByUserId();
        String salesOrg = ECOM_CustomMetadataService.getSalesOrg(ECOM_Util.getCountryFromUser(us));
        Contact con=ECOM_ContactService.getAccountContactInfoById(us.ContactId);
        if(con.ECOM_AddressRegistration__c.equalsIgnoreCase('Select BT') && con.ECOM_RegistrationPattern__c.equalsIgnoreCase('Domain Match'))
        {
            myAccountModels = erpAddressServiceInstance.fetchERPAddressesByDomain(us, us.Contact.fxDomain__c, salesOrg);
        }
        else {
            myAccountModels=erpAddressServiceInstance.fetchERPAddresses(us);
            if(myAccountModels.isEmpty() && String.isNotBlank(con.Default_Sold_to_ERP_Address__c))
            {
                List<ERP_Address__c> addresses = erpAddressServiceInstance.fetchERPAddressesById(con.Default_Sold_to_ERP_Address__c); 
                myAccountModels=ERP_AddressUtil.convertERPAddressesToModel(addresses, us);
            }
        }
        List<ERP_AddressModel> billAddressList = new List<ERP_AddressModel>(); //RWPS-3773 start
        if(!myAccountModels.isEmpty())
        {
            for(ECOM_MyAccountModel model:myAccountModels)
            {
                if(model.erpAddresses!= null) {
                    for(ERP_AddressModel shipToAddress:model.erpAddresses)  {
                        if(shipToAddress.associatedAddresses!= null) {
                            for(ERP_AddressModel address:shipToAddress.associatedAddresses) {
                                if(ECOM_Constant.ERP_ADDRESS_TYPE_PAYER.equalsIgnoreCase(address.addressType) && ECOM_Constant.ORDER_APPROVED.equalsIgnoreCase(address.ecomReviewStatus))
                                {
                                    billAddressList.add(address);
                                }
                            }
                        }    
                    }  
                }
            }
        }
        response.put('billAddressList',billAddressList); //RWPS-3773 end              
        response.put('address',myAccountModels);
        response.put('addressRegistration',us.Contact.ECOM_AddressRegistration__c);
        response.put('isAccountSelected',false);
        response.put('success',true);
        return response;
    }

    @AuraEnabled
    public static Map<String,Object> checkSoldToERPAddress(String soldToSapNumber,String addressRegistration)
    {
        Map<String,Object> response = new Map<String,Object>();
        List<ECOM_MyAccountModel> myAccountModels = new List<ECOM_MyAccountModel>();
        Type erpAddressService = Type.forName(ECOM_Constant.ERP_ADDRESS_SERVICE);
        ERP_IAddressService erpAddressServiceInstance = (ERP_IAddressService)erpAddressService.newInstance();
        response.put('success',false);
        User us = new ECOM_UserService().getUserByUserId();
        String salesOrg = ECOM_CustomMetadataService.getSalesOrg(ECOM_Util.getCountryFromUser(us));
        if(soldToSapNumber.length()==9)
        {
            soldToSapNumber='0'+soldToSapNumber;
        }
        // RWPS-4498 - START
        List<ERP_Relationship__c> disabledAddresses = ERP_AddressRepo.getDisabledERPAddressesFromERPRelationship(us.ContactId);

        List<String> disabledAddressIds = new List<String>();
        Set<String> externalIds = new Set<String>();//RWPS-4776
        Boolean isAccountDisabled = false;////RWPS-4776
        for (ERP_Relationship__c erp : disabledAddresses) {
            disabledAddressIds.add(erp.ERP_Address__c); // RWPS-4498
            externalIds.add(erp.ERP_Address__r.External_Id__c);//RWPS-4776
        }
        
        if (externalIds.contains(soldToSapNumber)) {//RWPS-4776
            isAccountDisabled = true;
        }     
        
        // RWPS-4498 - END
        List<String> sapNumbers=new List<String>{soldToSapNumber};
        List<String> addressType=new List<String>{'Sold To'};
        List<ERP_Address__c> addresses = erpAddressServiceInstance.fetchERPAddressesBySapNumber(us.ContactId,sapNumbers, addressType, salesOrg,us.Contact.fxDomain__c,disabledAddressIds); // RWPS-4498
        if(addresses.isEmpty())
        {
            //RWPS-4776 Start
            if (isAccountDisabled) {
                // RWPS-4498: Handle disabled account case
                response.put('success', false);
                response.put('errorMessage', 'This account is disabled and cannot be used.');
                response.put('isDisabledAccount', true); // Pass disabled account flag
            } else {
                // Handle invalid account number case
                response.put('success', false);
                response.put('errorMessage', 'This account number doesn\'t exist.');
                response.put('isDisabledAccount', false); // No disabled account
            }
            //RWPS-4776 END
            String supportData = UserInfo.getName()+' ('+UserInfo.getUserId()+ ') entered the account Number : '+soldToSapNumber+' which was not found in the system.';
            String severity = ECOM_Util.getSeverityByMessage(supportData);//RWPS-6037
            ECOM_ApplicationLogsUtil.logApplicationDataWithCustomException('User Management','ECOM_ContactController','checkSoldToERPAddress',soldToSapNumber,'Account not found',supportData, severity);//RWPS-6037
        }
        else 
        {
            /*if(String.isNotBlank(addressRegistration) && addressRegistration.equalsIgnoreCase('Select ST & BT'))
            {
                addressRegistration='Select BT';
            } 
            String result=ECOM_ContactService.makeAccountActive(new contact(Id=us.ContactId),addresses[0].Account__c,addresses[0].Id,null,null,addressRegistration,null);
            us = new ECOM_UserService().getUserByUserId();
            response=ECOM_ContactService.getERPData(us);
            response.put('addressRegistration',us.Contact.ECOM_AddressRegistration__c);*/
            List<ECOM_MyAccountModel> addressModel=ERP_AddressService.getErpModelBasedOnSoldTo(us,addresses[0].Id,salesOrg, soldToSapNumber,disabledAddressIds);// RWPS-4498
            response.put('success',true);
            response.put('addressRegistration',us.Contact.ECOM_AddressRegistration__c);
            response.put('attentionRecipient', us.Contact.ECOM_Attention_Recipient__c);
            response.put('soldToId',addresses[0].Id);
            response.put('countryProvided',us.Contact.ECOM_CountryProvided__c);
            response.put('address',addressModel);
        }
        ECOM_ContactService.saveAccountNumber(soldToSapNumber, us.ContactId); //RWPS-1520
        // Added by sathiya on 2024/04/29 for ECOM-1933
        response.put('billToValidationFields', ECOM_CustomMetadataService.getStoreConfigurationByLabel(ECOM_Constant.BILL_TO_FIELD_VALIDATION));
        // Changes end by sathiya
        // Added by sathiya on 2024/05/13 for ECOM-1939
        response.put('invoiceValidationFields', ECOM_CustomMetadataService.getStoreConfigurationByLabel(ECOM_Constant.INVOICE_FIELD_VALIDATION));
        // Changes end by sathiya
        return response;
    }
	@AuraEnabled
    public static Map<String,Object> createERPAddresses(String newErpAddressString, String attentionRecipient){
        Map<String,Object> response=new Map<String,Object>();
        String oldAccountId='';
        Boolean deleteACR=false;
        response.put('success',false);
        User us=new ECOM_UserService().getUserByUserId();
        ECOM_DummyAccountCountryMapping__mdt dummyCountry=ECOM_CustomMetadataService.fetchDummyAccountCountryMappingData(ECOM_Util.getCountryFromUser(us));
        Account acc=ECOM_AccountService.getDummyAccountByName(dummyCountry.Dummy_Account__c);
        List<ERP_AddressModel> newErpAddresses = (List<ERP_AddressModel>)JSON.deserialize(newErpAddressString,List<ERP_AddressModel>.class);

        response.putAll(ECOM_UserController.getCmsRedirectMapForWebUser());
        
        //Logic to check if any order is already placed
        List<String> shipToErpIds=new List<String>();
        List<String> billToErpIds=new List<String>();
        
        // Changes done by sathiya for ECOM-1939
		List<String> invoiceErpIds=new List<String>();
        // Changes End
        if(String.isNOtBlank(us.Contact.ECOM_AddressRegistration__c) && !us.Contact.ECOM_AddressRegistration__c.equalsIgnoreCase('Completed') && 
           String.isNotBlank(us.Contact.AccountId) && us.Contact.AccountId!=acc.Id)
        {
            deleteACR=true;
            oldAccountId=us.Contact.AccountId;
        }

        for(ERP_AddressModel erp:newErpAddresses)
        {
            if(String.isNotBlank(erp.id))
            {
                if(String.isNOtBlank(erp.addressType) && erp.ecomReviewStatus.equalsIgnoreCase('New')) 
                {
                    if(erp.addressType.equalsIgnoreCase('Ship To'))
                    {
                        shipToErpIds.add(erp.Id);
                    }
                    else if(erp.addressType.equalsIgnoreCase('Payer'))
                    {
                        billToErpIds.add(erp.Id);
                    // Changes done by sathiya for ECOM-1939
                    } else if(erp.addressType.equalsIgnoreCase('Bill To')){
                        invoiceErpIds.add(erp.Id);
                    }
                    // Changes Done
                }
            }
            if(String.isBlank(erp.accountId))
            {
                erp.accountId=acc.Id;
            }
            if(String.isBlank(erp.ecomReviewStatus) || erp.ecomReviewStatus.equalsIgnoreCase('New') && String.isBlank(erp.contactId))
            {
                erp.contactId=us.ContactId;
            }
        }

        if(!shipToErpIds.isEmpty() || !billToErpIds.isEmpty() || !invoiceErpIds.isEmpty())
        {
            Boolean alreadyOrdered = ECOM_OrderService.checkOrders(shipToErpIds,billToErpIds, invoiceErpIds);
            if(alreadyOrdered)
            {
                response.put('success',false);
                response.put('ErrorMessage', label.ECOM_AddressOrderAlreadyPlacedError);//RWPS-5118
                return response;
            }
        }

        try {
            Map<String, ERP_Address__c> erpAddressMap = new Map<String, ERP_Address__c>();
            List<ERP_Address__c> erpAddToUpdate = new List<ERP_Address__c>();
            Type erpAddressService = Type.forName(ECOM_Constant.ERP_ADDRESS_SERVICE);
            ERP_IAddressService erpAddressServiceInstance = (ERP_IAddressService)erpAddressService.newInstance();
            List<ERP_Address__c> erpAddresses = ERP_AddressUtil.mapErpRequestToSObject(newErpAddresses);
            List<ERP_Address__c> erpAddressesModified = erpAddressServiceInstance.upsertERPAddresses(erpAddresses);

            String payerId='';
            String shipToId='', invoiceErpId = '';
            for(ERP_Address__c eadd :erpAddressesModified){
                System.debug('erpAddressesModified after insert === '+eadd.Id);
                erpAddressMap.put(eadd.Address_Type__c, eadd);
                if(eadd.Address_Type__c == 'Payer'){
                    payerId=eadd.id;
                } else if(eadd.Address_Type__c == 'Ship To') {
                    shipToId=eadd.id;
                } else if(eadd.Address_Type__c == 'Bill To') {
                    invoiceErpId = eadd.id;
                }

            }
            // update ship to on Payer record
            for(ERP_Address__c eadd :erpAddressesModified){
                if(eadd.Address_Type__c == 'Payer'){
                    if(erpAddressMap.get('Ship To') != null && erpAddressMap.get('Ship To').Contact__c == eadd.Contact__c){
                        eadd.Master_Address__c = erpAddressMap.get('Ship To').Id;
                        erpAddToUpdate.add(eadd);
                    }
                } else if(eadd.Address_Type__c == 'Bill To'){
                    if(erpAddressMap.get('Payer') != null && erpAddressMap.get('Payer').Contact__c == eadd.Contact__c){
                        eadd.Master_Address__c = erpAddressMap.get('Payer').Id;
                        erpAddToUpdate.add(eadd);
                    }
                }
            }
            //update Contact with selected ship to and Payer 
            if(!erpAddToUpdate.isEmpty()){
                System.debug('erpAddToUpdate=====> '+erpAddToUpdate);
                List<ERP_Address__c> erpAddModified = erpAddressServiceInstance.upsertERPAddresses(erpAddToUpdate);
                if(String.isNotBlank(payerId) && String.isNotBlank(shipToId))
                {
                    String addressRegistration=null;
                    if(!us.Contact.ECOM_AddressRegistration__c.equalsIgnoreCase('Completed'))
                    {
                        addressRegistration = 'Completed';
                    }
                    String result = ECOM_ContactService.makeAccountActive(new contact(Id=us.ContactId),acc.Id,shipToId,payerId,invoiceErpId,addressRegistration,attentionRecipient);
                    System.debug('result === >'+result);
                    //update Cart with selected Ship to and Payer
                    if(result.equalsIgnoreCase('success')){
                        Contact contactToUpdate=new Contact();
                        contactToUpdate.Id=us.ContactId;
                        contactToUpdate.ECOM_Is_Mapped__c=false;
                        ECOM_ContactService.updateContact(contactToUpdate);

                        //ECOM_CartService.updateAssociatedCarts(); RWPS-164
                        Map<String,Object> temp = new Map<String,Object>();
                        if(deleteACR)
                        {
                            temp = ECOM_AccountService.deleteTemporaryACR(us.ContactId,oldAccountId);
                        }
                        if(temp.containsKey('Success'))
                        {
                            if((Boolean)temp.get('Success'))
                            {
                                response.put('success',true);
                                response.put('shipToId',shipToId);
                                response.put('payerId',payerId);
                                response.put('invoiceAddressId', invoiceErpId);
                            }
                        }
                        else
                        {
                            response.put('success',true);
                            response.put('shipToId',shipToId);
                            response.put('payerId',payerId);
                            response.put('invoiceAddressId', invoiceErpId);
                        }
                    }
                    ECOM_ContactService.saveRegistrationInfo(us.ContactId,shipToId,payerId,attentionRecipient);//RWPS-1123
                }
            }
        } catch (Exception e) { //RWPS-3813
            ECOM_ApplicationLogsUtil.logFailure(e, 'createERPAddresses', className, 'createERPAddresses', newErpAddressString);
            response.put('success',true);
        }    
        return response;
        
    }
    
    @AuraEnabled
    public static Map<String,Object> fetchNewERPAddresses(){
        
        Map<String,Object> response = new Map<String,Object>();
        ERP_AddressModel accountDetails = new ERP_AddressModel();
        
        response.put('success',false);
        
        User us = new ECOM_UserService().getUserByUserId();
        response.put('attentionRecipient', us.Contact.ECOM_Attention_Recipient__c);
        response.put('country',ECOM_Util.getCountryFromUser(us));
        
        //List<ERP_Address__c> erpAddresses=ECOM_ContactService.getNewErpData(us);

        Type erpAddressService = Type.forName(ECOM_Constant.ERP_ADDRESS_SERVICE);
        ERP_IAddressService erpAddressServiceInstance = (ERP_IAddressService)erpAddressService.newInstance();
        List<ERP_Address__c> erpAddresses=new List<ERP_Address__c>();
        erpAddresses=erpAddressServiceInstance.getErpAddressBasedOnContactIdAndAddressType(us.ContactId,new List<String>{'Ship To'});
        if(erpAddresses.size()>0){
            List<ERP_Address__c> payerAddresses = erpAddressServiceInstance.getErpAddressBasedOnContactIdAddressTypeAndMasterId(us.ContactId,new List<String>{'Payer'},erpAddresses[0].Id);
            erpAddresses.addAll(payerAddresses); 
            if(!payerAddresses.isEmpty()){
                Set<String> payerIds = new Set<String>();
                for(ERP_Address__c payer: payerAddresses){
                    payerIds.add(payer?.Id);
                    if(payer?.Target_Address__c != null){
                        payerIds.add(payer?.Target_Address__c);
                    }
                }
                erpAddresses.addAll(erpAddressServiceInstance.getErpAddressBasedOnContactIdAddressTypeAndMasterIds(us.ContactId,new List<String>{'Bill To'}, payerIds));
            }
        }

        accountDetails=ERP_AddressUtil.convertNewERPAddressesToShipToList(erpAddresses,us);

        response.put('success', true);
        response.put('erpAddresses', accountDetails);
        // Added by sathiya on 2024/04/29 for ECOM-1933
        response.put('billToValidationFields', ECOM_CustomMetadataService.getStoreConfigurationByLabel(ECOM_Constant.BILL_TO_FIELD_VALIDATION));
        // Changes end by sathiya
        response.put('defaultAccountName', us.Contact.ECOM_AccountNameProvided__c);//RWPS-1506 fetch CompanyName from Contact
        return response;
    }

    /**
    * @description 
    * @author garora@rafter.one | 03-06-2024 
    * @param requestMap 
    * @return Map<String,String> 
    **/
    @AuraEnabled
    public static Map<String,String> createLoginActivity(Map<String,String> requestMap){
        String supportData = '';
        try {
            requestMap = ECOM_ContactService.createLoginActivity(requestMap);
            requestMap.put('Status','Success');
        } catch (Exception e) {
            ECOM_ApplicationLogsUtil.logFailure(e, 'createLoginActivity', className, 'createLoginActivity', supportData);
            requestMap.put('Status','Success');
        }
        return requestMap;
    }
    /**
    * @description  Method to get Contact details
    * @author Sidak 2024.05.15 | RWPS-677
    * @return Contact 
    **/
    @AuraEnabled
    public static Contact getContactInfo(){
        Type userService = Type.forName(ECOM_Constant.USER_Service);
        ECOM_IUserService userServiceInstance = (ECOM_IUserService)userService.newInstance();
        User user = userServiceInstance.getUserByUserId();
        
        Type contactService = Type.forName(ECOM_Constant.CONTACT_Service);
        ECOM_IContactService contactServiceInstance = (ECOM_IContactService)contactService.newInstance();
        Contact contact = contactServiceInstance.getContactDetails(user.ContactId);
        return contact;
    }
    
}