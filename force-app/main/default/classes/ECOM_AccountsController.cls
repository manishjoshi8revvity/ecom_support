/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*	 -ECOM-659
*	 -ECOM-638
* 	 -ECOM-1028
* 2. Description - this class is invoked from My Account(Dashboard)
*				- fetch the current user record
				- get/delete and upsert Email Preferences
				- Save Contact Point Address Record
				- Search punchout accounts
*
*
* 3. Objects referenced
*    - ContactPointAddress
*    - Contact
*    - ECOM_Email_Preferences__c
*    - 
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
*
* 5. Dependant Class(es):
*    - ECOM_IUserService
*    - ECOM_Constant
*	 - ECOM_UserService
*	 - ECOM_AccountService
*	 - ECOM_ApplicationLogsUtil
*
* 6. Test Class Name: 
*	- ECOM_AccountsController_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vipul 2023.08.09
*    - Rani Thumma 2023.08.19
*	 - Manoj 2023.09.20
*	 - Vasudev 2023.12.01
*	 - sathiya 2024.04.29, added a new response variable for method fetchERPAddressDetails
*    - Sidak 2024.05.02 Updated method fetchERPAddressDetails, added showAccNumber. Ticket RWPS-564
*    - Sidak 2024.11.11 Updated method getPunchoutAccounts - Added map of account Id and country - RWPS-1809
*/
public  without sharing class ECOM_AccountsController {

    public static final String className = 'ECOM_AccountsController';

    /**
    * @description This method is used to get the Email Preferences
    * @author Dar Wright | 09-05-2023 
    * @param acctId
    **/
    @AuraEnabled(cacheable=false)
    public static List<ECOM_Email_Preferences__c> getEmailPreferences(String acctId) { 
        String supportData = '';
        String methodName = 'getEmailPreferences';
        List<ECOM_Email_Preferences__c> listEmailPreferences = new List<ECOM_Email_Preferences__c>();
        try{
            supportData = 'acctId = '+acctId;
            Type userService = Type.forName(ECOM_Constant.USER_Service);
            ECOM_IUserService userServiceInstance = (ECOM_IUserService)userService.newInstance();
            User user = userServiceInstance.getUserByUserId();
            
            ECOM_ContactService conService = new ECOM_ContactService();
            listEmailPreferences = conService.getEmailPreferencesByUser(String.valueOf(user.Contact.Default_Ship_to_ERP_Address__c), String.valueOf(user.ContactId));

        }catch(Exception ex){
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.PROFILE_AND_SETTING_MODULE_NAME, className, methodName, supportData);
        }
        return listEmailPreferences; 
    }

    /**
    * @description This method is used to upsert the Email Preferences
    * @author Dar Wright | 09-05-2023 
    * @param changesList
    **/
    @AuraEnabled
    public static void upsertEmailPreferences(String changesList) { 
        ECOM_AccountService.upsertEmailPreferences(changesList);
    }

    /**
    * @description This method is used to delete the Email Preference Record(s)
    * @author Dar Wright | 09-05-2023 
    * @param deleteList
    **/
    @AuraEnabled
    public static void deleteEmailPreferences(String deleteList) { 
        ECOM_AccountService.deleteEmailPreferences(deleteList);
    }
    
    /**
    * @description This method is used to get user specfic Account details which includes ERP Addresses(Ship tos, Payers).
    * @author Rani Thumma | 12-10-2023 
    * @param 
    * @return List<ECOM_MyAccountModel>
    **/
    @AuraEnabled
    public static List<ECOM_MyAccountModel> fetchAccountDetails(){
        String supportData = 'My Account Details';
        String methodName = 'fetchAccountDetails';
        List<ECOM_MyAccountModel> accountDetails = new List<ECOM_MyAccountModel>();
        try {
            Type userService = Type.forName(ECOM_Constant.USER_Service);
            ECOM_IUserService userServiceInstance = (ECOM_IUserService)userService.newInstance();
            User user = userServiceInstance.getUserByUserId();
            Type erpAddressService = Type.forName(ECOM_Constant.ERP_ADDRESS_SERVICE);
            ERP_IAddressService erpAddressServiceInstance = (ERP_IAddressService)erpAddressService.newInstance();
            accountDetails = erpAddressServiceInstance.fetchERPAddresses(user);
        } catch (Exception ex) {
            System.debug('Exception '+ex);
            ECOM_ApplicationLogsUtil.logFailure(ex, 'MyAccount Details', className, methodName, supportData);
        }
        return accountDetails;
    }

    @AuraEnabled
    public static Map<String,Object> fetchERPAddressDetails(){

        Map<String,Object> response = new Map<String,Object>();
        String supportData = 'My Account Details';
        String methodName = 'fetchERPAddressDetails';
        List<ECOM_MyAccountModel> accountDetails = new List<ECOM_MyAccountModel>();
        response.put('success', false);
        try {
            Type userService = Type.forName(ECOM_Constant.USER_Service);
            ECOM_IUserService userServiceInstance = (ECOM_IUserService)userService.newInstance();
            User user = userServiceInstance.getUserByUserId();
            Contact con=ECOM_ContactService.getAccountContactInfoById(user.ContactId);
            System.debug('con'+con);
            Type erpAddressService = Type.forName(ECOM_Constant.ERP_ADDRESS_SERVICE);
            System.debug('erpAddressService'+erpAddressService);
            ERP_IAddressService erpAddressServiceInstance = (ERP_IAddressService)erpAddressService.newInstance();
            accountDetails = erpAddressServiceInstance.fetchERPAddresses(user);
            ECOM_MyAccountModel dummySoldTo = ERP_AddressUtil.createDummySoldTo();
            
            Map<String,Object> erpAddresses = ECOM_ContactController.fetchNewERPAddresses();
            dummySoldTo.erpAddresses = new List<ERP_AddressModel>{(ERP_AddressModel)erpAddresses.get('erpAddresses')};
            if( String.isNotBlank(dummySoldTo.erpAddresses[0].id)){
                dummySoldTo.contactId = dummySoldTo.erpAddresses[0].contactId;
                dummySoldTo.accountId = dummySoldTo.erpAddresses[0].accountId;
                dummySoldTo.erpAccountName = dummySoldTo.erpAddresses[0].erpAccountName;
                dummySoldTo.externalId = 'NewAddress';
                dummySoldTo.showAccNumber = false;   //Sidak 2024.05.02 | RWPS-564
                dummySoldTo.isSelected  = dummySoldTo.erpAddresses[0].id ==con.Default_Ship_to_ERP_Address__c? true: false;
                accountDetails.add(dummySoldTo);
            }
            response.put('accountDetails', accountDetails);
            // Added by sathiya on 2024/04/29 for ECOM-1933
            response.put('billToValidationFields', ECOM_CustomMetadataService.getStoreConfigurationByLabel(ECOM_Constant.BILL_TO_FIELD_VALIDATION));
			// Changes end by sathiya
            response.put('success', true);
        } catch (Exception ex) {
            System.debug('Exception '+ex);
            ECOM_ApplicationLogsUtil.logFailure(ex, 'MyAccount Details', className, methodName, supportData);
        }
        return response;
    }
    
    /**
    * @description This method is used to update Account, default Bill to and deafult ship to on the Contact and also on Cart, during Account Switch or Bill to update
    * @author Rani Thumma | 13-10-2023 
    * @param String contactId, String accountId, String erpShipToId, String erpBillToId, Boolean isInvoiceAddress
    * @return 
    **/
    @AuraEnabled
    public static String updateContactandCart( String contactId, String accountId, String erpShipToId, String erpBillToId, String erpSoldToId, String erpInvoiceId, boolean emptySoldTo){
        String supportData = 'ContactId='+contactId+ ' accountId='+accountId+' erpShipToId='+erpShipToId+' erpBillToId='+erpBillToId ;
        String methodName = 'updateContactandCart';
        try{
            // update Account, default billto, default ship to on Contact
            Type contactService = Type.forName(ECOM_Constant.CONTACT_Service);
            ECOM_IContactService contactServiceInstance = (ECOM_IContactService)contactService.newInstance();
            Contact con = contactServiceInstance.getContactDetails(contactId);
            String result = emptySoldTo==true?contactServiceInstance.makeAccountActive(con, accountId, erpShipToId, erpBillToId, erpInvoiceId,'','') : contactServiceInstance.makeAccountActive(con, accountId,erpSoldToId, erpShipToId, erpBillToId, erpInvoiceId,'','');
            // update Account on active cart for the user
            if(result.equalsIgnoreCase('Success')){
                //RWPS-164
                //ECOM_CartService.updateAssociatedCarts();

                Contact contactToUpdate=new Contact();
                contactToUpdate.Id=contactId;
                if(emptySoldTo)
                    contactToUpdate.ECOM_Is_Mapped__c=false;
                else
                    contactToUpdate.ECOM_Is_Mapped__c=true;
                ECOM_ContactService.updateContact(contactToUpdate);
            }
            return 'Success';
        } catch(Exception ex){
            System.debug('Exception '+ex);
            ECOM_ApplicationLogsUtil.logFailure(ex, 'MyAccount Details', className, methodName, supportData);
            return 'error'+ex.getStackTraceString();
        }
    }
    
    
    /**
    * @description This method is used to insert or update Bill to and ship to ERP Addresses
    * @author Rani Thumma | 14-10-2023 
    * @param jsonErpRequest
    * @return Boolean
    **/
    @AuraEnabled
    public static Map<String,Object> addERPAddresses(String jsonAddresses){
        Map<String,Object> response=new Map<String,Object>();
        response.put('success',false);
        String supportData = jsonAddresses;
        String methodName = 'addERPAddresses';
        Set<String> erpIds = new Set<String>();
        List<ECOM_MyAccountModel> updatedErpAddresses = new List<ECOM_MyAccountModel>();
        
        try{
            System.debug('jsonAddresses === '+jsonAddresses);
            List<ERP_AddressModel> newErpAddresses = (List<ERP_AddressModel>)JSON.deserializeStrict(jsonAddresses,List<ERP_AddressModel>.class);

            String contactID = ECOM_UserService.getContactIdByUserName(UserInfo.getUserName());

            for(ERP_AddressModel nea:newErpAddresses)
            {
                if(String.isBlank(nea.contactId))
                {
                    nea.contactId = contactID;
                }
            }
            
            Type erpAddressService = Type.forName(ECOM_Constant.ERP_ADDRESS_SERVICE);
            ERP_IAddressService erpAddressServiceInstance = (ERP_IAddressService)erpAddressService.newInstance();
            List<ERP_Address__c> erpAddresses = ERP_AddressUtil.mapErpRequestToSObject(newErpAddresses);

            List<String> billToIds=new List<String>();
            List<String> shipToIds=new List<String>();
            // Changes done by sathiya for ECOM-1939
            List<String> invoiceErpIds=new List<String>();
            // Changes End
            List<String> allIds=new List<String> ();

            for(ERP_Address__c ea:erpAddresses)
            {
                if(String.isNotBlank(ea.Id) && ea.ECOM_Review_Status__c.equalsIgnoreCase('New'))
                {
                    if(ea.Address_Type__c.equalsIgnoreCase('Ship To'))
                    {
                        shipToIds.add(ea.Id);
                    }
                    else if(ea.Address_Type__c.equalsIgnoreCase('Payer'))
                    {
                        billToIds.add(ea.Id);
                    // Changes done by sathiya for ECOM-1939
                    } else if(ea.Address_Type__c.equalsIgnoreCase('Bill To')) {
                        invoiceErpIds.add(ea.Id);
                    }
                    // Changes End
                }
                if(String.isNotBlank(ea.Id))
                {
                    allIds.add(ea.Id);
                }

            }

            if(!shipToIds.isEmpty() || !billToIds.isEmpty() || !invoiceErpIds.isEmpty())
            {
                if(!allIds.isEmpty())
                {
                    Integer inProgressAddresses=ERP_AddressService.fetchInProgressAddresses(allIds);
                    if(inProgressAddresses>0)
                    {
                        response.put('success',false);
                        response.put('ErrorMessage','Your address is under review and cannot be modified.');
                        return response;
                    }
                }

                Boolean alreadyOrdered = ECOM_OrderService.checkOrders(shipToIds, billToIds, invoiceErpIds);
                if(alreadyOrdered)
                {
                    response.put('success',false);
                    response.put('ErrorMessage','You have already placed an order for this address, so you cannot modify it. If you have any concerns, please reach out to the customer care team.');
                    return response;
                }
            }

            System.debug('erpAddresses === '+erpAddresses);
            List<ERP_Address__c> erpAddressesModified = erpAddressServiceInstance.upsertERPAddresses(erpAddresses);
            System.debug('erpAddressesModified === '+erpAddressesModified);
            response.put('success',true);
            response.put('updatedErpAddresses',ERP_AddressUtil.convertERPToAddressModel(erpAddressesModified[0]));
        } catch(Exception ex){
            response.put('success',false);
            System.debug('Exception '+ex);
            ECOM_ApplicationLogsUtil.logFailure(ex, 'MyAccount Details', className, methodName, supportData);            
        }
        return response;
    }
    
    /**
     * @description Method to return list of Accounts that are flagged as punchout accounts
     * @author vramachandran@rafter.one | 2023-12-01
     * @author ssingh@rafter.one | 11 Nov 2024 | RWPS-1809
     * @param searchParam
     * @return Map<String,Object>
     * */
    @AuraEnabled
    public static Map<String,Object> getPunchoutAccounts(){
        Map<String,Object> responseMap = new Map<String,Object>();
        //List<String> accountIds = new List<String>();
        Map<String,String> accountIdToCountryMap = new Map<String,String>();
        
        try{
            //accountIds = ERP_AddressUtil.getPunchoutAccountIdList();
            accountIdToCountryMap = ERP_AddressUtil.getPunchoutAccountIdList();
            List<Account> accountsList = new List<Account>();
            accountsList= ECOM_AccountRepo.getPunchoutAccountsForAccountIds(accountIdToCountryMap.keySet());
            System.debug('controller:accountsList:: '+ accountsList);
            
            responseMap.put(ECOM_Constant.PARAM_RESPONSE_DATA, ECOM_AccountUtil.getAccountNameMap(accountsList, accountIdToCountryMap));
            responseMap.put(ECOM_Constant.PARAM_SUCCESS, true);
        }catch(Exception e){
            responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
            ECOM_ApplicationLogsUtil.logFailure(e, 'Punchout:: Fetch Account - failed', className, 'getSearchedPunchoutAccounts', 'Message:: '+ e.getMessage()+ ' Stack:: '+ e.getStackTraceString());
        }
        return responseMap;
    }
    
}