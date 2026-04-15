/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*
*
* 2. Description 
					- - This class is used to retrieve Dashboard records
*					- DMLs on Dashboard
					- return all related account and Contact information for current user
					- return contact record by Owner
*
* 3. Objects referenced
*    - contact
*    - ECOM_SalesECOM_Email_Preferences__cOrgMapping__mdt
*    - ContactPointAddress
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
* 5. Dependant Class(es):
*  - ECOM_CustomMetadataRepo
*  - ECOM_ContactService
*  - ECOM_AccountWrapper
*  - ECOM_AccountService
*  - ECOM_ContactRepo
*  - ECOM_CustomMetadataService
* 
* 6. Test Class Name: 
*  - ECOM_DashboardController_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vipul 2023.09.09
*	 - Sathiya 2024.04.29 - Adding validation config for ECOM-1933 and ECOM -1942
*	 - Sathiya 2024.05.13 - Adding invoiceMailingAddress mapping for ECOM-1939
*    - Manish RWPS-592 - Omni Us & Ca users should be able to see PDF
*    - Poonam RWPS-3306 - Updated method getEmailAddresses removed null erp address records - RWPS-3306
*************************************************************/
public class ECOM_DashboardController {
    private static final String CLASS_NAME = 'ECOM_DashboardController';//RWPS-592
    public ECOM_DashboardController() {

    }

    /**
    * @description  Get user details
    * @author mkumar@rafter.one | 09-21-2023 
    * @param contactId 
    * @return Contact 
    **/
    @AuraEnabled
    public static Map<String,Object> getUserDetails(String contactId){
        Map<String,Object> response=new Map<String,Object>();
        try {
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
            if(String.isNotBlank(con.Default_Sold_to_ERP_Address__c))
            {
                ERP_Address__c soldToERP=erpAddressServiceInstance.fetchERPAddressesById(con.Default_Sold_to_ERP_Address__c)[0];
                response.put('soldToAddress',ERP_AddressUtil.convertERPToAddressModel(soldToERP));
            }
            // Added by sathiya on 2024/05/13 for ECOM-1939
            if(String.isNotBlank(con?.Default_Invoice_ERP_Address__c)){
                ERP_Address__c soldToERP=erpAddressServiceInstance.fetchERPAddressesById(con?.Default_Invoice_ERP_Address__c)[0];
                response.put('invoiceMailingAddress',ERP_AddressUtil.convertERPToAddressModel(soldToERP));
            }
           	// Changes End by sathiya
            // Added by sathiya on 2024/04/29 for ECOM-1933
            response.put('billToValidationFields', ECOM_CustomMetadataService.getStoreConfigurationByLabel(ECOM_Constant.BILL_TO_FIELD_VALIDATION));
            // Changes end by sathiya
            response.put('success',true);
        } catch (Exception e) {
            response.put('success',false);
        }
        return response;
    }

    /**
    * @description  Gte related accounts for current user
    * @author mkumar@rafter.one | 09-21-2023 
    * @return List<ECOM_AccountWrapper.AccountDetails> 
    **/
    /*@AuraEnabled
    public static List<ECOM_AccountWrapper.AccountDetails> getRelatedAccountOfCurrentUser(){
        Contact con = ECOM_ContactService.getAccountContactInfo();
        system.debug('Contact in mainMethod: '+con);
        List<ECOM_AccountWrapper.AccountDetails> accountDetails = ECOM_ContactService.getAllRelatedAccount();
        for(ECOM_AccountWrapper.AccountDetails acr : accountDetails){
            Boolean isCPAAddress = (con.ECOM_DefaultBillToCPA__c==null && con.ECOM_DefaultShipToCPA__c==null) ? false:true;
            Boolean isAccountAddress = (con.ECOM_DefaultBillToAccount__c==null && con.ECOM_DefaultShipToAccount__c==null) ? false:true;
            Boolean isCPABillTo = (con.ECOM_DefaultBillToCPA__c!=null && con.ECOM_DefaultShipToAccount__c!=null) ? true:false;

            if((con.AccountId == acr.accountId) && !isCPAAddress){
                acr = ECOM_ContactService.prepareActiveAccountAddress(acr, con);
            } else if((con.AccountId == acr.accountId) && isCPABillTo){
                acr = ECOM_ContactService.prepareCPABillAndAccountShipAddress(acr, con);
            }
        }
        //Map<String,Object> cpas = ECOM_AccountService.getCPAForContact(con.Id);
        //Map<String, ContactPointAddress> shipToBillToMap = new Map<String, ContactPointAddress>();

        for(ContactPointAddress cpa : ECOM_AccountService.getCPAForContact(con.Id)){
            System.debug('Queried CAP>> '+ cpa);
            if((cpa.AddressType == 'Billing') && (cpa.ECOM_Associated_ShipTo__c !=null) && (cpa.ParentId==con.AccountId)){
                ECOM_AccountWrapper.AccountDetails accountDetail = new ECOM_AccountWrapper.AccountDetails();
                accountDetail.accountId=cpa.Id;
                accountDetail.sapAccountNumber=cpa.Account_Number_Formatted__c;
                ECOM_AccountWrapper.BillingDetails billingDetails= new ECOM_AccountWrapper.BillingDetails ();
                billingDetails.billToId=cpa.Id;
                billingDetails.billToName=cpa.Name;
                billingDetails.billToStreet=cpa.Street;
                billingDetails.billToState=cpa.State;
                billingDetails.billToCity=cpa.City;
                billingDetails.billToCountry=cpa.Country;
                billingDetails.billToPostalCode=cpa.PostalCode;
                accountDetail.billToDetails.add(billingDetails);
                ECOM_AccountWrapper.ShippingDetails shippingDetails= new ECOM_AccountWrapper.ShippingDetails ();
                shippingDetails.shipToId=cpa.ECOM_Associated_ShipTo__c;
                shippingDetails.shipToName=cpa.ECOM_Associated_ShipTo__r.Name;
                shippingDetails.shipToStreet=cpa.ECOM_Associated_ShipTo__r.Street;
                shippingDetails.shipToState=cpa.ECOM_Associated_ShipTo__r.State;
                shippingDetails.shipToCity=cpa.ECOM_Associated_ShipTo__r.City;
                shippingDetails.shipToCountry=cpa.ECOM_Associated_ShipTo__r.Country;
                shippingDetails.shipToPostalCode=cpa.ECOM_Associated_ShipTo__r.PostalCode;
                accountDetail.shipToDetails.add(shippingDetails);
                if(con.ECOM_DefaultBillToCPA__c!= null && con.ECOM_DefaultShipToCPA__c!=null){
                    accountDetail.isCPA = true;
                }
                accountDetails.add(accountDetail);
            }
        }
        //accountDetails.add(accountDetailsWithCPA);
        System.debug('accountDetails>>> '+ accountDetails);
        return accountDetails;
    }*/
    
    /**
    * @description  Make Account active  
    * @author mkumar@rafter.one | 09-21-2023 
    * @param accountId 
    * @param shipTo 
    * @param billTo 
    * @return String 
    **/
    /*@AuraEnabled
    public static String updateAccountToActive(String accountId, String shipTo, String billTo){
        String updateResult = ECOM_ContactService.makeAccountActive(accountId,shipTo,billTo);
        return updateResult;
    }*/

    /**
    * @description  Get Default Billing Address
    * @author mkumar@rafter.one | 09-21-2023 
    * @param accountId 
    * @return Object 
    **/
   /*@AuraEnabled
    public static Object getBillingAddresses(String accountId){
        Contact currentContact = ECOM_ContactRepo.getContactByOwner();
        //Map<String,Object> addressDetails = ECOM_ContactService.getAddressDetails(currentContact.Id); Commented due to changes asked by Raji
        Map<String,Object> addressDetails = ECOM_ContactController.getContactDetails(currentContact.Id);
        if(addressDetails.size()>0 && addressDetails.get('billingAccounts') != null){
            return addressDetails.get('billingAccounts');
        }
        return null;
    }*/

    /**
    * @description Save Default Billing Address
    * @author mkumar@rafter.one | 09-21-2023 
    * @param contactId 
    * @param billingAccount 
    * @return String 
    **/
    /*@AuraEnabled
    public static String saveDefaultBillingAddress (String contactId, String billingAccount){
        try {
            ECOM_ContactService.updateDefaultBillingAddress(contactId, billingAccount);
            Map<String,Object> tempMap=ECOM_CartUtil.updateCartForAccountSwitch(contactId);
            return 'success';
        } catch (DmlException de) {
            return 'error';
        }
    }*/

    /**
    * @description  get email preperences
    * @author mkumar@rafter.one | 09-21-2023 
    * @return String 
    **/
    @AuraEnabled
    public static String getEmailAddresses(){
        User us = new ECOM_UserService().getUserByUserId();
        Contact currentContact = ECOM_ContactService.getContactDetails(us.ContactId);
        ECOM_ContactService conService = new ECOM_ContactService();
        String otherEmails ='';
        Integer i = 0;
        for(ECOM_Email_Preferences__c pref : conService.getEmailPreferencesByUser(String.valueOf(currentContact.Default_Ship_to_ERP_Address__c), String.valueOf(us.ContactId))){
            String erpAddress = String.valueOf(pref.ERP_Address__c);
    
            // Check if ERP_Address__c is not null, empty or just whitespace
            if (String.isNotBlank(erpAddress)) {//RWPS-3306
                otherEmails = otherEmails + pref.ECOM_Email__c + ', ';
            }
        }
        return otherEmails.removeEnd(', '); 
    }

    /**
    * @description get current user billing address
    * @author mkumar@rafter.one | 09-21-2023 
    * @param conId 
    * @param accId 
    * @return List<ECOM_AccountWrapper.AccountDetails> 
    **/
    /*@AuraEnabled
    public static List<ECOM_AccountWrapper.AccountDetails> getCurrentBillingAddresses(String conId, String accId){
        List<ECOM_AccountWrapper.AccountDetails> accountDetails = new List<ECOM_AccountWrapper.AccountDetails>();//ECOM_ContactService.getAllRelatedAccount();
        for(ECOM_AccountWrapper.AccountDetails acr : ECOM_ContactService.getAllRelatedAccount()){
            if((accId == acr.accountId) && acr.billToDetails.size()>0){
                accountDetails.add(acr);
            }
        }
        List<ECOM_AccountWrapper.AccountDetails> accountDetailsWithCPA = ECOM_ContactService.getCPAForCurrentContact(conId, accId);
        if(accountDetailsWithCPA.size()>0){
            accountDetails.addAll(accountDetailsWithCPA);
        }
        System.debug('accountDetails>>> '+ accountDetails);
        return accountDetails;
    }*/

    /**
    * @description  get CPS by Id
    * @author mkumar@rafter.one | 09-21-2023 
    * @param recId 
    * @return ContactPointAddress 
    **/
    /*@AuraEnabled
    public static ContactPointAddress getCPAByRecId(String recId){
        try {
            return ECOM_AccountService.getCPAForCPAId(recId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }*/

    /**
    * @description  Add or modify Contact Point Address
    * @author mkumar@rafter.one | 09-21-2023 
    * @param billingCPA 
    * @param contactID 
    * @return Map<String, Object> 
    **/
    /*@AuraEnabled
    public static Map<String,Object>  addOrModifyCPAAddress(ContactPointAddress billingCPA,String contactID){
        Map<String,Object> returnMap=new Map<String,Object>();
        try {
            if(String.isNotBlank(billingCPA.Id)){
                String status=ECOM_AccountService.getCpaStatus(billingCPA.Id);
                if(String.isNotBlank(status) && !status.equalsIgnoreCase('New')){
                    returnMap.put('Success',true);
                    returnMap.put('Message','Your Address is in review, so it cannot be modified.');
                    return returnMap;
                }
            }
            List<ContactPointAddress> cpas=ECOM_AccountService.upsertCPAs(new List<ContactPointAddress>{billingCPA});
            //Contact con=ECOM_ContactService.upsertBillingCPA(cpas[0],contactID);
            //returnMap.put('Contact',con);
            Map<String,Object> tempMap=ECOM_CartUtil.updateCartForAccountSwitch(contactID);
            returnMap.put('Success',true);
            returnMap.put('cpaId', cpas[0].Id);
        } catch (Exception e) {
            returnMap=ECOM_ContactService.createErrorMap(e);
        }
        return returnMap; 
    }*/
    
    /**
    * @description This method is used to get the map of response containing ContentDocumentLink record
    * @author Manish Joshi| 30-04-2024
    * @reuturns Map<String,Object>
    **/
    @AuraEnabled
    public static Map<String,Object> handlePDFDownload(){
        Map<String,Object> mapParams = new Map<String,Object>();
        String methodName = 'handlePDFDownload';
        try
        {
            Contact currentContact = ECOM_ContactRepo.getContactByOwner();
            String contactId = currentContact.Id;
            Set<String> validContentDocumentId = new Set<String>(); 
            validContentDocumentId.add(Label.ECOM_USContentDocumentId);
            validContentDocumentId.add(Label.ECOM_CAContentDocumentId);
            List<ContentDocumentLink> contentDocuments =
                ECOM_ContentDocumentRepo.fetchContentDocumentLink(contactId,validContentDocumentId);
            if(!contentDocuments.isEmpty())
            {
                mapParams.put('isSuccess',true);
                mapParams.put('contentDocumentId',contentDocuments[0].ContentDocumentId);
                //mapParams.put('orgUrl',URL.getOrgDomainURL().toExternalForm());
                List<String> siteDetails = ECOM_Util.getSiteDetails();
                if(!siteDetails.isEmpty())
                	mapParams.put('orgUrl',siteDetails.get(0));
            } else {
				mapParams.put('isSuccess',false);
				mapParams.put('error','No content document link found');
			}
        }
        catch(Exception ex)
        {
            mapParams.put('isSuccess',false);
            mapParams.put('error',ex);
            ECOM_ApplicationLogsUtil.logFailure(ex, 'Can not find content dodument link record', CLASS_NAME, methodName, UserInfo.getUserId());
        }
        return mapParams;
    }
}