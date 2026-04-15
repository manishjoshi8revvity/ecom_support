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
* 	 - vramachandran@rafer.one | 11 Dec 2023
*    - Sathiya 2024.05.13 for invoice address mapping
*    - Sidak 2024.06.06 Updated methods getMasterERPAddressModelForPunchoutUser,getPunchoutAddressesForERPAddressModel added static keyword
*    - Sidak 2024.06.10 Added method updateERPRelationshipsBasedOnACR. Ticket - RWPS-392
*    - Sidak 2024.06.13 Updated method fetchERPAddresses, added check for soldTo list size. Ticket - RWPS-887
*    - Sidak 2024.06.18 Updated method updateERPRelationshipsBasedOnACR, added Address Type check Master. Ticket - RWPS-392
*    - Sidak 2024.07.02 Updated method updateERPRelationshipsBasedOnACR, added logic to map request to Callout SAP. Ticket - RWPS-553
*    - Sidak 2024.07.24 Updated method updateERPRelationshipsBasedOnACR, Updated logic to exclude placeholder accounts and create ERP Relationships. Ticket - RWPS-1144
*    - Manish Joshi 2025.07.11 - Updated method fetchERPAddresses as per new implementation - RWPS-3657
*    - Mahesh Suthar 2025.10.8 - Updated method fetchERPAddressesBySapNumber, getErpModelBasedOnSoldTo - remove disabledAddresses list - RWPS-4498
*************************************************************/
public class ERP_AddressService implements ERP_IAddressService{

    public static String CLASSNAME = 'ERP_AddressService';
    
    public static List<ECOM_MyAccountModel> fetchERPAddresses(User user){
        //RWPS-3657 - START 
        List<ERP_Relationship__c> disabledAddresses = ERP_AddressRepo.getDisabledERPAddressesFromERPRelationship(user.ContactId);
        Set<String> disabledAddressIds = new Set<String>();
        for (ERP_Relationship__c erp : disabledAddresses) {
            disabledAddressIds.add(erp.ERP_Address__c);
        }
        String salesOrg = ECOM_CustomMetadataService.getSalesOrg(ECOM_Util.getCountryFromUser(user));
        Set<String> erpAddressSet = new Set<String>();
        Set<String> shipToTargetERPs = new Set<String>();
        // fetch all contact history records containing past used mapped addresses
        List<HistoryRecord> contactHistory = new List<HistoryRecord>();
        try 
        {
            String soql = 'SELECT Id, Field, OldValue, NewValue, CreatedDate FROM ContactHistory WHERE ContactId = \'' + user.ContactId + '\' AND (Field=\'Default_Bill_to_ERP_Address__c\' OR Field=\'Default_Ship_to_ERP_Address__c\' OR Field=\'Default_Invoice_ERP_Address__c\') Order by CreatedDate DESC';
            String encodedSOQL = EncodingUtil.urlEncode(soql, 'UTF-8');
            Map<String, String> requestMap = new Map<String, String>();   
            requestMap.put(ECOM_Constant.HTTP_REQUEST_ENDPOINT, System.Label.ECOM_IntegrationUserNamedCredential + System.Label.ECOM_SOQL_REST_URLPath+encodedSOQL);
            requestMap.put(ECOM_Constant.REQUEST_METHOD_TYPE, ECOM_Constant.HTTP_REQUEST_GET);
            requestMap.put(ECOM_Constant.HTTP_CONTENT_TYPE, ECOM_Constant.HTTP_CONTENT_APP_JSON);
            requestMap.put(ECOM_Constant.AUTHORIZATION, ECOM_Constant.AUTH_BASIC + ' ' + EncodingUtil.base64Encode(Blob.valueOf('{!$Credential.UserName}' + ':' + '{!$Credential.Password}')));
            HttpResponse response = ECOM_RestService.calloutAsIntegrationUser(requestMap); 			
            if (response.getStatusCode() == 200)
            {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                List<Object> records = (List<Object>) responseMap.get('records');
                for (Object record : records) 
                {
                    Map<String, Object> row = (Map<String, Object>) record;
                    HistoryRecord h = new HistoryRecord();
                    h.Id = (String) row.get('Id');
                    h.Field = (String) row.get('Field');
                    h.OldValue = String.valueOf(row.get('OldValue'));
                    h.NewValue = String.valueOf(row.get('NewValue'));
                    h.CreatedDate = (String) row.get('CreatedDate');
                    contactHistory.add(h);
                }
            }
            else 
            {
                System.debug('REST Call failed: ' + response.getBody());
                throw new CalloutException('Error in REST call: ' + response.getStatus()+response.getBody());
            }
        } catch (Exception ex) {
            throw new AuraHandledException('Exception: ' + ex.getMessage());
        }
        // Add all ShipToNames & PayerNames from contact history
        Set<String> shipToPayerInvoiceNameSet = new Set<String>();
        for(HistoryRecord rec:contactHistory){
            if(rec.NewValue!=null && rec.NewValue!='Payer--' && rec.NewValue!='ShipTo--')
            {
                shipToPayerInvoiceNameSet.add(rec.NewValue);
            }
        }
        // store all Ship To target Ids & add both payer & ship to to main address set
        List<ERP_Address__c> historyMappedAddresses = ERP_AddressRepo.getERPAddressBasedOnName(shipToPayerInvoiceNameSet,salesOrg);
        for(ERP_Address__c record:historyMappedAddresses){
            if(record.Address_Type__c=='Ship To' && !disabledAddressIds.contains(record.Master_Address__c))
            {
                shipToTargetERPs.add(record.Target_Address__c);
                erpAddressSet.add(record.Id);
            }
            else
                erpAddressSet.add(record.Id);
        }
        // Add all payer, ship to, bill to from past order to main address set if not disabled        
        List<Order> orders = ECOM_OrderService.getMyOrders();
        for(Order rec:orders){
            if(rec.Default_Ship_to_ERP_Address__c!=null && 
                rec.Default_Ship_to_ERP_Address__r.Target_Address__c!=null)
            {
                if(!disabledAddressIds.contains(rec.Default_Ship_to_ERP_Address__r.Master_Address__c))
                {
                    shipToTargetERPs.add(rec.Default_Ship_to_ERP_Address__r.Target_Address__c);
                    if(rec.Default_Bill_to_ERP_Address__c!=null)
                    erpAddressSet.add(rec.Default_Bill_to_ERP_Address__c);
                    if(rec.Default_Invoice_ERP_Address__c!=null)
                    erpAddressSet.add(rec.Default_Invoice_ERP_Address__c);
                    erpAddressSet.add(rec.Default_Ship_to_ERP_Address__c);
                }
            }
        }
        // fetch all the sold to erps linked to all user orders & contact history ship to address target
        if(!shipToTargetERPs.isEmpty())
        {
            List<ERP_Address__c> soldToList = ERP_AddressRepo.getSoldToRelatedToShipTo(shipToTargetERPs,salesOrg);
            if(!soldToList.isEmpty()){
                for(ERP_Address__c rec:soldToList){
                    erpAddressSet.add(rec.Id);
                }
            }
        }
        if(user.Contact.Default_Ship_to_ERP_Address__c!=null && 
        !disabledAddressIds.contains(user.Contact.Default_Ship_to_ERP_Address__r.Master_Address__c))
        {
            if(user.Contact.Default_Sold_to_ERP_Address__c!=null && !erpAddressSet.contains(user.Contact.Default_Sold_to_ERP_Address__c))
                erpAddressSet.add(user.Contact.Default_Sold_to_ERP_Address__c);
            if(user.Contact.Default_Ship_to_ERP_Address__c!=null && !erpAddressSet.contains(user.Contact.Default_Ship_to_ERP_Address__c))
                erpAddressSet.add(user.Contact.Default_Ship_to_ERP_Address__c);
            if(user.Contact.Default_Bill_to_ERP_Address__c!=null && !erpAddressSet.contains(user.Contact.Default_Bill_to_ERP_Address__c))
                erpAddressSet.add(user.Contact.Default_Bill_to_ERP_Address__c);
            if(user.Contact.Default_Invoice_ERP_Address__c!=null && !erpAddressSet.contains(user.Contact.Default_Invoice_ERP_Address__c))
                erpAddressSet.add(user.Contact.Default_Invoice_ERP_Address__c);
        }
        List<ECOM_MyAccountModel> erpAddresses = new List<ECOM_MyAccountModel>();
        if(!erpAddressSet.isEmpty())
        {
            List<ERP_Address__c> addresses = ERP_AddressRepo.fetchERPAddressesByContactId(user.ContactId, erpAddressSet, salesOrg);
            erpAddresses=ERP_AddressUtil.convertERPAddressesToModel(addresses, user);
        }
        //RWPS-3657 - END
        return erpAddresses;
    }

    public static List<ERP_Address__c>  getErpAddressBasedOnContactIdAndAddressType(String contactId,List<String> accountAddresses)
    {
        return ERP_AddressRepo.fetchNewERPAddressesByContactId(contactId,accountAddresses);
    }

    public static List<ERP_Address__c>  getErpAddressBasedOnContactIdAddressTypeAndMasterId(String contactId,List<String> accountAddresses,String masterId)
    {
        return ERP_AddressRepo.fetchErpAddressesByMasterId(contactId,accountAddresses,masterId);
    }

    public static List<ERP_Address__c>  getErpAddressBasedOnContactIdAddressTypeAndMasterIds(String contactId,List<String> accountAddresses, Set<String> masterId)
    {
        return ERP_AddressRepo.fetchErpAddressesByMasterIds(contactId,accountAddresses,masterId);
    }
    
    public static List<ECOM_MyAccountModel> fetchERPAddressesByContact(User user){
        List<ERP_Address__c> addresses = ERP_AddressRepo.fetchNewERPAddressesByContactId(user.ContactId);
        List<ECOM_MyAccountModel> erpAddresses = ERP_AddressUtil.convertERPAddressesToModel(addresses, user);
        return erpAddresses;
    }
    
    public static List<ERP_Address__c> upsertERPAddresses(List<ERP_Address__c> erpAddresses){
        List<ERP_Address__c> erpAddressesModified = new List<ERP_Address__c>();
        ERP_AddressRepo.upsertERPAddress(erpAddresses);
        return erpAddresses;
    }
    public static List<ECOM_MyAccountModel> fetchERPAddressesBySoldTo(User user, String contactId, String soldToSAPNumber, String contactDomain){
        List<ERP_Address__c> addresses = ERP_AddressRepo.fetchERPAddressesBySoldTo(contactId, soldToSAPNumber, contactDomain);
        List<ECOM_MyAccountModel> erpAddresses = ERP_AddressUtil.convertERPAddressesToModel(addresses, user);
        return erpAddresses;
    }
    public static List<ECOM_MyAccountModel> fetchERPAddressesByDomain(User user, String contactDomain, String salesOrg){
        List<ERP_Address__c> addresses = ERP_AddressRepo.fetchERPAddressesByDomain(contactDomain, salesOrg);
        List<ECOM_MyAccountModel> erpAddresses = ERP_AddressUtil.convertERPAddressesToModel(addresses, user);
        return erpAddresses;
    }
    //New method create by Vipul
    public static List<ERP_Address__c> fetchERPAddressesBySapNumber(String contactId, List<String> sapNumbers,List<String> addressTypes, String salesOrg){
        List<ERP_Address__c> addresses = ERP_AddressRepo.fetchERPAddressesBySapNumber(contactId,sapNumbers,addressTypes, salesOrg);
        return addresses;
    }
    //New method create by Vipul
    public static List<ERP_Address__c> fetchERPAddressesBySapNumber(String contactId, List<String> sapNumbers,List<String> addressTypes, String salesOrg,String domain, List<String> disabledAddresses){
        List<ERP_Address__c> addresses = ERP_AddressRepo.fetchERPAddressesBySapNumber(contactId,sapNumbers,addressTypes, salesOrg,domain,disabledAddresses); //RWPS-4498
        return addresses;
    }
    //New method create by Vipul
    public static List<ERP_Address__c> fetchERPAddressesById(String erpId){
        List<ERP_Address__c> addresses = ERP_AddressRepo.fetchERPAddressesById(erpId);
        return addresses;
    }
    public static Map<Id,ERP_Address__c> getTargetId(Set<String> erpIds){
        return ERP_AddressRepo.getTargetId(erpIds);
    }
    //fetch ERP relationships bsaed on selceted ship to on logged in user contact
    public List<ERP_RelationShip__c> fetchERPRelationshipsByERPAddress(String contactId, String erpAddId){
        return ERP_AddressRepo.fetchERPRelationshipsByERPAddress(contactId, erpAddId);
    }

    public static List<ERP_RelationShip__c> fetchERPRelationshipsByContactId(String contactId)
    {
        List<ERP_RelationShip__c> erpRelationships = ERP_AddressRepo.fetchERPRelationshipsByContactId(contactId);
        return erpRelationships;
    }

    public static Integer fetchInProgressAddresses(List<String> erpIds)
    {
        return ERP_AddressRepo.fetchInProgressAddresses(erpIds);
    }

    public static List<ECOM_MyAccountModel> getErpModelBasedOnSoldTo(User user,String soldToId,String salesOrg){
        return getErpModelBasedOnSoldTo(user, soldToId, salesOrg, '',null);// RWPS-4498
    }

    // RWPS-4498
    public static List<ECOM_MyAccountModel> getErpModelBasedOnSoldTo(User user,String soldToId,String salesOrg, String sapNumber, List<String> disabledAddressIds){
        List<ECOM_MyAccountModel> erpAddresses = new List<ECOM_MyAccountModel>();
        List<ERP_Address__c> addresses = new List<ERP_Address__c>();
        List<ERP_Address__c> soldTo = ERP_AddressRepo.fetchERPAddressesById(soldToId);
        List<ERP_Address__c> shipTos = new List<ERP_Address__c>();
        // RWPS-4498
        if(disabledAddressIds == null){
            disabledAddressIds = New List<String>();
        }
        if(String.isNotBlank(sapNumber)){
            shipTos = ERP_AddressRepo.fetchERPAddressesBySapNumber(user.ContactId,new List<String>{sapNumber},new List<String>{'Ship To'}, salesOrg);
        } else {
            shipTos = ERP_AddressRepo.fetchERPAddressesByMaster(new List<String>{soldTo[0].Target_Address__c},new List<String>{'Ship To'},user.ContactId,salesOrg,disabledAddressIds);
        }
        
        List<String> shipToMasters= new List<String>();
        List<String> billToMasters= new List<String>();
        for(ERP_Address__c shipTo:shipTos)
        {
            shipToMasters.add(shipTo.Target_Address__c);
        }
        List<ERP_Address__c> billTos= ERP_AddressRepo.fetchERPAddressesByMaster(shipToMasters,new List<String>{'Payer'},user.ContactId,salesOrg,disabledAddressIds);
        for(ERP_Address__c billTo:billTos){
            if(billTo?.Target_Address__c != null){
                billToMasters.add(billTo.Target_Address__c);
            }
            billToMasters.add(billTo.Id);
        }
        addresses=soldTo;
        addresses.addAll(shipTos);
        addresses.addAll(billTos);
        // Change for ECOM-1939 by sathiya for invoice mailing address
        List<ERP_Address__c> invoiceAddresses = ERP_AddressRepo.fetchERPAddressesByMaster(billToMasters,new List<String>{'Bill To'},user.ContactId,salesOrg);
        addresses.addAll(invoiceAddresses);
        // Changes end 
        erpAddresses=ERP_AddressUtil.convertERPAddressesToModel(addresses, user);
        return erpAddresses;
    }
    
    /**
     * @description This method returns the ERP Master address model for a punchout user
     * @author vramachandran@rafter.one | 02 Jan 2024
     * @author ssinhg@rafter.one | 08 Jun 2024 | Added static keyword
     * @param userRecord
     * @return ERP_AddressModel 
     */
    public static ERP_AddressModel getMasterERPAddressModelForPunchoutUser(User userRecord){
        return ERP_AddressUtil.getMasterERPAddressModelForPunchoutUser(userRecord);
    }
    
    /**
     * @description This method returns the model for ERP address for a punchout account unique name 
     * @author vramachandran@rafter.one | 22 Dec 2023
     * @param accountUniqueName | String
     * @returns ERP_AddressModel
     */
    /**
    public ERP_AddressModel getERPAddressModelForPunchoutAccountId(String accountId){
        ERP_AddressModel addressModel = ERP_AddressUtil.getERPAddressModelForPunchoutAccountId(accountId);
        return addressModel;
    }*/
    
    
    /**
     * @description This method returns the ERP Address (Ship to, Sold to, Bill To, Payer) and the related target.master address for
     *  a punchout account Unique name defined on the target.master( ECOM Punchout Customer Id field)
     * @author vramachandran@rafter.one | 15 Jan 2024
     * @param poAccountUniqueName | String
     * @returns List<ERP_Address> 
     */
    public static ERP_AddressModel getPunchoutAddressesForERPAddressModel(String poAccountUniqueName){
        
        ERP_AddressModel addressModel = ERP_AddressUtil.getPunchoutAddressesForERPAddressModel(poAccountUniqueName);
        return addressModel;
    }
    
    /**
     * @description This method returns the model for ERP address for a punchout accountId //TODO: check and deprecate
     * @author vramachandran@rafter.one | 16 Jan 2024
     * @author ssinhg@rafter.one | 08 Jun 2024 | Added static keyword
     * @param accountId | String
     * @returns ERP_AddressModel
     */
    /**public ERP_AddressModel getERPAddressModelForAccountId(String accountId){
        ERP_AddressModel addressModel = ERP_AddressUtil.getERPAddressModelForPunchoutAccountId(accountId);
        return addressModel;
    }*/
    
    /**
     * @description This method creates ERP Relationships based on ACR
     * @author ssingh@rafter.one | 10 Jun 2024 | RWPS-392
     * @author ssingh@rafter.one | 18 Jun 2024 | RWPS-392 | Added Address Type Master check
     * @param contactId | String
     * @returns void
     */
    @InvocableMethod
    public static void updateERPRelationshipsBasedOnACR(List<String> contactIds){
        String supportData = contactIds[0];
        String methodName = 'updateERPRelationshipsBasedOnACR';
        try {
            HttpResponse httpRes = new HttpResponse();
            List<String> accIds = ERP_AddressRepo.getNonPlaceholderAccountsFromAcrBasedOnContact(contactIds[0]);
            List<ERP_Relationship__c> erpRelations = ERP_AddressRepo.getERPRelationshipsByContactId(contactIds[0]);
            List<String> existingErpIds = new List<String>();
            for (ERP_Relationship__c rel : erpRelations) {
                existingErpIds.add(rel.ERP_Address__c);
            }
    
            List<ERP_Address__c> erpList = ERP_AddressRepo.getMasterERPAddressesBasedOnAccountId(accIds,existingErpIds);
            Set<ERP_Address__c> addressesWihoutERPRelation = new Set<ERP_Address__c>(); 
    
            Contact con = ECOM_ContactRepo.getContactBasedOnId(contactIds[0]);
            ECOM_GetSAPContactIdWrapper sapContactIdWrapper = new ECOM_GetSAPContactIdWrapper();
            sapContactIdWrapper.firstName = con.FirstName;
            sapContactIdWrapper.lastName = con.LastName;
            sapContactIdWrapper.contactId = con.Id;
            sapContactIdWrapper.email = con.Email;
            List<ECOM_GetSAPContactIdWrapper.Addresses> addrList = new List<ECOM_GetSAPContactIdWrapper.Addresses>();
            Map<String,Object> addrMap = new Map<String,Object>();
            for (ERP_Address__c erpAddress : erpList) {
                if(!addrMap.containsKey(erpAddress.Master_Address__c)){
                    addrMap.put(erpAddress.Master_Address__c, erpAddress.Master_Address__r.External_Id__c);
                    ECOM_GetSAPContactIdWrapper.Addresses addr = new ECOM_GetSAPContactIdWrapper.Addresses();
                    addr.addressId = erpAddress.Master_Address__c;
                    addr.shipToNumber = erpAddress.Master_Address__r.External_Id__c;
                    addrList.add(addr);
                }
            }
    
            if(addrList.size() > 0 || Test.isRunningTest()){
                sapContactIdWrapper.address = addrList;
                String requestBody = JSON.serialize(sapContactIdWrapper);
                Map<String, String> requestMap = ECOM_Util.generateRequestMap(requestBody, 'GetSAPContactId');
                httpRes = ECOM_RestService.doBasicHttpRequest(requestMap);
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(httpRes.getBody());
                List<Map<String, Object>> mapList = new List<Map<String, Object>>();
                List<Object> resultList = (List<Object>) responseMap.get('results');
                for (Object obj : resultList) {
                    mapList.add((Map<String, Object>)obj);
                }
    
                List<ERP_Relationship__c> relationsToInsert = new List<ERP_Relationship__c>();
                for (Map<String, Object> m : mapList) {
                    ERP_Relationship__c rel = new ERP_Relationship__c();
                    rel.Contact__c = (String)m.get('contactId');
                    rel.ERP_Address__c = (String)m.get('addressId');
                    rel.ERP_Contact_ID__c = (String)m.get('sapContactNumber');
                    rel.External_Id__c = (String)m.get('sapContactNumber');
        
                    relationsToInsert.add(rel);
                }
                if(!Test.isRunningTest()){
                    ERP_AddressRepo.insertERPRelationships(relationsToInsert);
                }
            }
        } catch (Exception ex) {
            ECOM_ApplicationLogsUtil.logFailure(ex, 'Update ERP Relationships based on ACR', className, methodName, supportData);
        }
    }
    // RWPS-3657 - START
    public class HistoryRecord {
        public String Id;
        public String Field;
        public String OldValue;
        public String NewValue;
        public String CreatedDate;
    }
    // RWPS-3657 - END
}