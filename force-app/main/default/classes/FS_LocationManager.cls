/**
 *  Apex Class for Location [Schema.Location] Business Logic.
 *  2017-07-03      Frank VanLoon       Initial creation, for Location Integration.
 *  2017-11-02      Frank VanLoon       Refactored Customer-Master Lookups / Functions to Accounts
 *  CONVERTED to SFS by frankvanloon on 3/22/24.
 */
public with sharing class FS_LocationManager {

    /*
        Used for Inbound Location Integration from SAP.
        Should be called from the BEFORE-INSERT and BEFORE-UPDATE Triggers.
        If Customer lookups are not populated, or if the external ids changed, this code will attempt to lookup and fill them in.
     */
    public static void lookupLocationCustomers(List<Schema.Location> locations, Map<Id, Schema.Location> oldMap) {
        if (!FS_Utility.isActive('LookupLocationCustomers', 'If Customer lookups are not populated, or if the external ids changed, this code will attempt to lookup and fill them in.')) return;

        // STEP 0: Copy the External_ID__c to the SoldToExtID__c if blank
        for (Schema.Location loc : locations) {
            if (loc.IsInventoryLocation == true) {
                // SVMXINT-629 Storage Location - Alternative Customer
                if (loc.AltCustomerNumber__c != null && String.isNotBlank(loc.AltCustomerNumber__c)) {
                    loc.SoldToExtID__c = loc.AltCustomerNumber__c;
                } else {
                    loc.SoldToExtID__c = loc.External_ID__c;
                    // ITSVMX-1084 Hard-Code an 'E' prefix for '1US2' Storage Location Accounts
                    if (loc.SoldToExtID__c != null && loc.SoldToExtID__c.startsWith('1US2')) {
                        loc.SoldToExtID__c = 'E' + loc.SoldToExtID__c;
                    }
                }
            }
        }

        // STEP 1: Collect all External Ids and Locations that need to be looked up (SoldTo, Account, Parent)
        Set<String> accountExtIds = new Set<String>();
        Set<String> contactExtIds = new Set<String>();
        Set<String> salesOrgs = new Set<String>();
        Map<String, String> erpSalesOrgMap = new Map<String, String>();
        List<Schema.Location> updateAcct = new List<Schema.Location>();
        List<Schema.Location> updateContact = new List<Schema.Location>();
        List<Schema.Location> updateInvPartners = new List<Schema.Location>();
        for (Schema.Location loc : locations) {
            Schema.Location old = (oldMap == null) ? null : oldMap.get(loc.Id);

            // Account: SoldToExtID__c --> SVMXC__Account__c
            if (String.isNotEmpty(loc.SoldToExtID__c) && (loc.Account__c == null ||
                    (old != null && loc.SoldToExtID__c != old.SoldToExtID__c))) {
                accountExtIds.add(loc.SoldToExtID__c);
                updateAcct.add(loc);
                salesOrgs.add(loc.SalesOrg__c);
            }

            // Contact : ContactExtId__c --> Contact__c
            if (String.isNotEmpty(loc.ContactExtId__c) && (loc.Contact__c == null ||
                    (old != null && loc.ContactExtId__c != old.ContactExtId__c))) {
                contactExtIds.add(loc.ContactExtId__c);
                updateContact.add(loc);
            }

            // For Storage Locations, fill in Partner Lookups
            if (String.isNotEmpty(loc.SoldToExtID__c) && loc.IsInventoryLocation == true
                    && (loc.SoldTo__c == null || (old != null && loc.SoldToExtID__c != old.SoldToExtID__c))) {
                erpSalesOrgMap.put(loc.SoldToExtID__c, loc.SalesOrg__c);
                updateInvPartners.add(loc);
            }
        }

        // STEP 2: Lookup Accounts, Partner Sites & Contacts by their External Ids
        Map<String, Account> accountMap = FS_AccountManager.findAccounts(accountExtIds);

        Map<String, Contact> contactMap = new Map<String, Contact>();
        if (!contactExtIds.isEmpty()) {
            Map<String, ERP_Relationship__c> erpMap = new Map<String, ERP_Relationship__c>();
            for (ERP_Relationship__c erp : [
                    SELECT Id, Name, External_Id__c,
                            Contact__r.Id, Contact__r.FirstName, Contact__r.LastName
                    FROM ERP_Relationship__c
                    WHERE External_Id__c IN :contactExtIds
            ]) {
                contactMap.put(erp.External_Id__c, erp.Contact__r);
            }
        }

        // STEP 3: Fill in the Account / Contact / Parent lookups if found
        for (Schema.Location loc : updateAcct) {
            Account acct = accountMap.get(loc.SoldToExtID__c);
            loc.Account__c = (acct != null) ? acct.Id : null;
        }

        if (!erpSalesOrgMap.isEmpty()) {
            Map<String, Map<String, ERP_Address__c>> erpPartnerMap = FS_AccountManager.findPartnerAccounts(erpSalesOrgMap);
            for (Schema.Location loc : updateInvPartners) {
                // For Storage Locations, fill in Partner Lookups
                Map<String, ERP_Address__c> partners = erpPartnerMap.get(loc.SoldToExtID__c);
                if (partners == null) {
                    continue;
                }

                ERP_Address__c soldTo = partners.get('Sold To');
                if (soldTo != null) {
                    loc.SoldTo__c = soldTo.Id;
                }
                ERP_Address__c shipTo = partners.get('Ship To');
                if (shipTo != null) {
                    loc.ShipTo__c = shipTo.Id;
                }
                ERP_Address__c payer = partners.get('Payer');
                if (payer != null) {
                    loc.Payer__c = payer.Id;
                }
            }
        }

        for (Schema.Location loc : updateContact) {
            Contact c = contactMap.get(loc.ContactExtId__c);
            loc.Contact__c = (c != null) ? c.Id : null;
        }

        // STEP 4: Collect all External Ids and Locations that need to be looked up (ERP Address)
        Set<String> partnerAcctExtIds = new Set<String>();
        Set<Id> acctIds = new Set<Id>();

        List<Schema.Location> updateSoldTo = new List<Schema.Location>();
        List<Schema.Location> updateBillTo = new List<Schema.Location>();
        List<Schema.Location> updatePayer = new List<Schema.Location>();
        List<Schema.Location> updateShipTo = new List<Schema.Location>();
        List<Schema.Location> updateLocalBillTo = new List<Schema.Location>();
        List<Schema.Location> updateLocalShipTo = new List<Schema.Location>();
        for (Schema.Location loc : locations) {
            Schema.Location old = (oldMap == null) ? null : oldMap.get(loc.Id);

            if (loc.Account__c != null) {
                acctIds.add(loc.Account__c);
                salesOrgs.add(loc.SalesOrg__c);
            } else {
                continue;
            }

            // SoldToExtID__c --> SoldTo__c
            if (String.isNotEmpty(loc.SoldToExtID__c) && (loc.SoldTo__c == null ||
                    (old != null && loc.SoldToExtID__c != old.SoldToExtID__c))) {
                partnerAcctExtIds.add(loc.SoldToExtID__c);
                updateSoldTo.add(loc);
            }

            // BillToExtID__c --> BillTo__c
            if (String.isNotEmpty(loc.BillToExtID__c) && (loc.BillTo__c == null ||
                    (old != null && loc.BillToExtID__c != old.BillToExtID__c))) {
                partnerAcctExtIds.add(loc.BillToExtID__c);
                updateBillTo.add(loc);
            }

            // PayerExtId__c --> Payer__c
            if (String.isNotEmpty(loc.PayerExtId__c) && (loc.Payer__c == null ||
                    (old != null && loc.PayerExtId__c != old.PayerExtId__c))) {
                partnerAcctExtIds.add(loc.PayerExtId__c);
                updatePayer.add(loc);
            }

            // ShipToExtID__c --> ShipTo__c
            if (String.isNotEmpty(loc.ShipToExtID__c) && (loc.ShipTo__c == null ||
                    (old != null && loc.ShipToExtID__c != old.ShipToExtID__c))) {
                partnerAcctExtIds.add(loc.ShipToExtID__c);
                updateShipTo.add(loc);
            }

            // SVMXINT-623 Local Language Partners on Location
            // LL_BillToExtID__c --> LL_BillTo__c
            if (String.isNotEmpty(loc.LL_BillToExtID__c) && (loc.LL_BillTo__c == null ||
                    (old != null && loc.LL_BillToExtID__c != old.LL_BillToExtID__c))) {
                partnerAcctExtIds.add(loc.LL_BillToExtID__c);
                updateLocalBillTo.add(loc);
            }

            // LL_ShipToExtID__c --> LL_ShipTo__c
            if (String.isNotEmpty(loc.LL_ShipToExtID__c) && (loc.LL_ShipTo__c == null ||
                    (old != null && loc.LL_ShipToExtID__c != old.LL_ShipToExtID__c))) {
                partnerAcctExtIds.add(loc.LL_ShipToExtID__c);
                updateLocalShipTo.add(loc);
            }
        }

        // STEP 5: Lookup Partner Accounts by their External Ids
        Map<String, ERP_Address__c> partnerAcctMap = new Map<String, ERP_Address__c>();
        if (!partnerAcctExtIds.isEmpty()) {
            for (ERP_Address__c erp : [
                    SELECT Id, Name, Address_Type__c, ERP_Sales_Org__c, fxCustomerNumber_Target__c
                    FROM ERP_Address__c
                    WHERE Account__c IN :acctIds
                    AND ERP_Sales_Org__c IN :salesOrgs
                    AND fxCustomerNumber_Target__c IN :partnerAcctExtIds
            ]) {
                String erpKey = FS_AssetManager.getErpKey(erp.Address_Type__c, erp.ERP_Sales_Org__c, erp.fxCustomerNumber_Target__c);
                partnerAcctMap.put(erpKey, erp);
            }
        }

        for (Schema.Location loc : updateSoldTo) {
            ERP_Address__c erp = partnerAcctMap.get(FS_AssetManager.getErpKey('Sold To', loc.SalesOrg__c, loc.SoldToExtID__c));
            loc.SoldTo__c = (erp != null) ? erp.Id : null;
        }

        for (Schema.Location loc : updateBillTo) {
            ERP_Address__c erp = partnerAcctMap.get(FS_AssetManager.getErpKey('Payer', loc.SalesOrg__c, loc.BillToExtID__c));
            loc.BillTo__c = (erp != null) ? erp.Id : null;
        }

        for (Schema.Location loc : updatePayer) {
            ERP_Address__c erp = partnerAcctMap.get(FS_AssetManager.getErpKey('Payer', loc.SalesOrg__c, loc.PayerExtId__c));
            loc.Payer__c = (erp != null) ? erp.Id : null;
        }

        for (Schema.Location loc : updateShipTo) {
            ERP_Address__c erp = partnerAcctMap.get(FS_AssetManager.getErpKey('Ship To', loc.SalesOrg__c, loc.ShipToExtID__c));
            loc.ShipTo__c = (erp != null) ? erp.Id : null;
        }

        // SVMXINT-623 Local Language Partners on Location
        for (Schema.Location loc : updateLocalBillTo) {
            ERP_Address__c erp = partnerAcctMap.get(FS_AssetManager.getErpKey('Payer', loc.SalesOrg__c, loc.LL_BillToExtID__c));
            loc.LL_BillTo__c = (erp != null) ? erp.Id : null;
        }

        for (Schema.Location loc : updateLocalShipTo) {
            ERP_Address__c erp = partnerAcctMap.get(FS_AssetManager.getErpKey('Ship To', loc.SalesOrg__c, loc.LL_ShipToExtID__c));
            loc.LL_ShipTo__c = (erp != null) ? erp.Id : null;
        }
    }

    public static void lookupCountryState(List<Schema.Location> locations, Map<Id, Schema.Location> oldMap)
    {
        //Add logic to find the Country only if state not found (by ISO Code)
        Set<String> countryCodes = new Set<String>();
        List<Schema.Location> countryLocs = new List<Schema.Location>();
        for (Schema.Location loc : locations) {
            if (String.isNotBlank(loc.Country__c) && loc.LKUP_Country__c == null) {
                String countryCode = loc.Country__c;
                countryCodes.add(countryCode);
                countryLocs.add(loc);
            }
        }

        if (!countryLocs.isEmpty()) {
            Map<String, Country__c> countryCodeMap = new Map<String, Country__c>();
            for (Country__c cntry : [SELECT Id, Name, Country_ISO_Alpha_2__c
                FROM Country__c WHERE Country_ISO_Alpha_2__c IN :countryCodes])
            {
                countryCodeMap.put(cntry.Country_ISO_Alpha_2__c, cntry);
            }

            for (Schema.Location loc : countryLocs) {
                String countryCode = loc.Country__c;
                Country__c cntry = countryCodeMap.get(countryCode);
                if (cntry != null) {
                    loc.LKUP_Country__c = cntry.Id;
                }
            }
        }

        // 20240423: Adding Country & State Lookups
//        Set<String> isoCodes = new Set<String>();
//        List<Schema.Location> stateCountryLocs = new List<Schema.Location>();
//        for (Schema.Location loc : locations) {
//            if (String.isNotBlank(loc.Country__c) && String.isNotBlank(loc.State__c)
//                && (loc.LKUP_Country__c == null || loc.LKUP_State__c == null)) {
//                String isoCode = loc.Country__c + loc.State__c;
//                isoCodes.add(isoCode);
//                stateCountryLocs.add(loc);
//            }
//        }
//
//        if (!stateCountryLocs.isEmpty()) {
//            Map<String, State__c> isoStateMap = new Map<String, State__c>();
//            for (State__c state : [SELECT Id, Name, SFDC_State_Name__c, ISOCode__c, Country__c,
//                    Country__r.Name, Country__r.SFDC_Country_Name__c, Country__r.Country_ISO_Alpha_2__c
//                FROM State__c WHERE ISOCode__c IN :isoCodes])
//            {
//                isoStateMap.put(state.ISOCode__c, state);
//            }
//
//            for (Schema.Location loc : stateCountryLocs) {
//                String isoCode = loc.Country__c + loc.State__c;
//                State__c state = isoStateMap.get(isoCode);
//                if (state != null) {
//                    loc.LKUP_State__c = state.Id;
//                    loc.LKUP_Country__c = state.Country__c;
//                }
//            }
//        }

        Set<String> stateCodes = new Set<String>();
        Set<Id> countryIds = new Set<Id>();
        List<Schema.Location> stateLocs = new List<Schema.Location>();
        for (Schema.Location loc : locations) {
            if (loc.LKUP_Country__c != null && String.isNotBlank(loc.State__c) && loc.LKUP_State__c == null) {
                stateCodes.add(loc.State__c);
                countryIds.add(loc.LKUP_Country__c);
                stateLocs.add(loc);
            }
        }

        if (!stateCodes.isEmpty()) {
            Map<String, State__c> stateMap = new Map<String, State__c>();
            for (State__c state : [SELECT Id, Name, SFDC_State_Name__c, ERPCode__c, Country__c,
                    Country__r.Country_ISO_Alpha_2__c
                FROM State__c WHERE ERPCode__c IN :stateCodes AND Country__c IN :countryIds])
            {
                String countryState = state.Country__r.Country_ISO_Alpha_2__c + state.ERPCode__c;
                stateMap.put(countryState, state);
            }

            for (Schema.Location loc : stateLocs) {
                String countryState = loc.Country__c + loc.State__c;
                State__c state = stateMap.get(countryState);
                if (state != null) {
                    loc.LKUP_State__c = state.Id;
                }
            }
        }
    }

    /**
     *  SVMXCFG-401 - Set the Address Fields for Storage Location by copying from the ShipTo Account
     *  Must be called in a before insert/update trigger, AFTER the lookupLocationCustomers method.
     */
    public static void lookupInventoryAddress(List<Schema.Location> locations, Map<Id, Schema.Location> oldMap)
    {
        if (!FS_Utility.isActive('Location Inventory Address', 'If Inventory Location, copy the Address fields from the Ship To Location Account.'))    return;

        Set<Id> erpIds = new Set<Id>();
        List<Schema.Location> locsToUpdate = new List<Schema.Location>();
        for (Schema.Location loc : locations)
        {
            Schema.Location old = (oldMap == null) ? null : oldMap.get(loc.Id);
            if (loc.IsInventoryLocation == true && loc.ShipTo__c != null
                    && (old == null || loc.ShipTo__c != old.ShipTo__c || loc.Street__c == null))
            {
                locsToUpdate.add(loc);
                erpIds.add(loc.ShipTo__c);
            }
        }

        // Changed this to lookup ERP Address
        Map<Id, ERP_Address__c> erpMap = new Map<Id, ERP_Address__c>([SELECT Id, Name,
                fxAddress_Street__c, fxAddress_City__c, fxAddress_StateCode__c, fxAddress_Postal__c, fxAddress_CountryCode__c
            FROM ERP_Address__c WHERE Id IN :erpIds]);
        for (Schema.Location loc : locsToUpdate)
        {
            ERP_Address__c erp = erpMap.get(loc.ShipTo__c);
            if (erp != null)
            {
                loc.Street__c = erp.fxAddress_Street__c;
                loc.City__c = erp.fxAddress_City__c;
                loc.State__c = erp.fxAddress_StateCode__c;
                loc.Zip__c = erp.fxAddress_Postal__c;
                loc.Country__c = erp.fxAddress_CountryCode__c;
            }
        }
    }

    /*
        Used for Inbound Location Integration from SAP.
        Should be called from the BEFORE-INSERT and BEFORE-UPDATE Triggers.
        If Geography lookup is not populated, or if the Location Code changed, this code will attempt to lookup and fill it in.
     */
    public static void lookupLocationGeography(List<Schema.Location> locations, Map<Id, Schema.Location> oldMap)
    {
        if (!FS_Utility.isActive('lookupLocationGeography', 'If Geography lookup is not populated, or if the Location Code changed, this code will attempt to lookup and fill it in.')) return;

        // STEP 1: Collect the Location Codes if Geography Lookup is blank
        List<Schema.Location> locsToUpdate = new List<Schema.Location>();
        Set<String> locationCodes = new Set<String>();
        for (Schema.Location loc : locations)
        {
            Schema.Location old = (oldMap == null) ? null : oldMap.get(loc.Id);
            if (loc.LocationCode__c != null && (loc.Geography__c == null
                    || (old != null && loc.LocationCode__c != old.LocationCode__c)))
            {
                locsToUpdate.add(loc);
                locationCodes.add(loc.LocationCode__c);
            }
        }

        if (locationCodes.isEmpty()) return;

        // STEP 2: Lookup Geography by Location Codes
        Map<String, ServiceTerritory> geoMap = new Map<String, ServiceTerritory>();
        for (ServiceTerritory geo : [SELECT Id, LocationCode__c FROM ServiceTerritory
            WHERE LocationCode__c IN :locationCodes])
        {
            geoMap.put(geo.LocationCode__c, geo);
        }

        // STEP 3: Fill in Location->Geography Lookup
        Set<String> newLocCode = new Set<String>();
        List<Schema.Location> locsThatNeedGeos = new List<Schema.Location>();
        for (Schema.Location loc : locsToUpdate)
        {
            String locCode = loc.LocationCode__c;
            if (geoMap.containsKey(locCode))
            {
                ServiceTerritory geo = geoMap.get(locCode);
                loc.Geography__c = geo.Id;
            } else
            {
                // 2/25/21 tony - Don't create a new Geography record for a Storage Location
                if (loc.IsInventoryLocation == false) {
                    // No Geography record exists for this locCode so we will need to create one
                    locsThatNeedGeos.add(loc);
                    newLocCode.add(locCode);
                }
            }
        }

        if (newLocCode.isEmpty()) {
            return;
        }

        // 1/14/21 tony - ITSVMX-220 Geography Data Enhancements
        // STEP 4: Create a new Geography records for each new locCode
        OperatingHours oh= [SELECT Id FROM OperatingHours WHERE Name ='DEFAULT'];
        Map<String, ServiceTerritory> newLocCodeToGeoMap = new Map<String, ServiceTerritory>();
        for (String locCode : newLocCode)
        {
            ServiceTerritory geo = new ServiceTerritory();
            geo.LocationCode__c = locCode;
            geo.Name = 'Geography:' + locCode;
            geo.Type__c = 'Geography';
            geo.OperatingHoursId=oh.Id;
            geo.IsActive=true;
            newLocCodeToGeoMap.put(locCode, geo);
        }
        insert newLocCodeToGeoMap.values();

        // STEP 5: Fill in Location->Geography Lookup for the new Geography records
        for (Schema.Location loc : locsThatNeedGeos)
        {
            ServiceTerritory geo = newLocCodeToGeoMap.get(loc.LocationCode__c);
            loc.Geography__c = geo.Id;
        }
    }

    // Added by Veerendra 2017-08-14
    // Updated by Frank, for SVMXCFG-408
    public static void updateAssetAddressFieldsWhenLocAdrChanged(List<Schema.Location> newLocList, Map<Id, Schema.Location> oldMap)
    {
        if (!FS_Utility.isActive('updateAssetAddress', 'Update Address fields in Asset when the location address is changed.')) {
            return;
        }

        Set<Id> locIds = new Set<Id>();
        Set<Id> stateIds = new Set<Id>();
        Set<Id> countryIds = new Set<Id>();
        List<Schema.Location> locsToUpdate = new List<Schema.Location>();
        for (Schema.Location loc : newLocList)
        {
            Schema.Location old = (oldMap == null) ? null : oldMap.get(loc.Id);
            if (old != null &&
                    (loc.Street__c != old.Street__c
                        || loc.City__c != old.City__c
                        || loc.LKUP_State__c != old.LKUP_State__c
                        || loc.Zip__c != old.Zip__c
                        || loc.LKUP_Country__c != old.LKUP_Country__c))
            {
                locsToUpdate.add(loc);
                locIds.add(loc.Id);
                if (loc.LKUP_State__c != null) {
                    stateIds.add(loc.LKUP_State__c);
                }
                if (loc.LKUP_Country__c != null) {
                    countryIds.add(loc.LKUP_Country__c);
                }
            }
        }

        if (locsToUpdate.isEmpty()) {
            return;
        }

        Map<Id, State__c> stateMap = new Map<Id, State__c>();
        if (!stateIds.isEmpty()) {
            stateMap = new Map<Id, State__c>([SELECT Id, SFDC_State_Name__c FROM State__c WHERE Id IN :stateIds]);
        }

        Map<Id, Country__c> countryMap = new Map<Id, Country__c>();
        if (!countryIds.isEmpty()) {
            countryMap = new Map<Id, Country__c>([SELECT Id, SFDC_Country_Name__c FROM Country__c WHERE Id IN :countryIds]);
        }

        List<Asset> assetListForUpdate = new List<Asset>();
        Map<Id, List<Asset>> assetLocMap = new Map<Id, List<Asset>>();
        List<Asset> assetList = [SELECT Id, Name, LocationId
            FROM Asset WHERE LocationId IN :locIds];
        for (Asset ass : assetList)
        {
            List<Asset> listIP = new List<Asset>();
            if(assetLocMap.containsKey(ass.LocationId))
            {
                listIP = assetLocMap.get(ass.LocationId);
            }
            listIP.add(ass);
            assetLocMap.put(ass.LocationId, listIP);
        }

        for (Schema.Location loc : locsToUpdate)
        {
            if (assetLocMap.containsKey(loc.Id))
            {
                List<Asset> listAsset = assetLocMap.get(loc.Id);
                for (Asset ass : listAsset)
                {
                    ass.Street = loc.Street__c;
                    ass.City = loc.City__c;
                    ass.PostalCode = loc.Zip__c;
                    State__c state = stateMap.get(loc.LKUP_State__c);
                    if (state != null) {
                        ass.State = state.SFDC_State_Name__c;
                    }
                    Country__c country = countryMap.get(loc.LKUP_Country__c);
                    if (country != null) {
                        ass.Country = country.SFDC_Country_Name__c;
                    }
                    assetListForUpdate.add(ass);
                }
            }
        }

        if (!assetListForUpdate.isEmpty()) {
            Database.update(assetListForUpdate, false);
        }
    }

    // ITSFDC-509 Update the Depot Queue Id from the Depot Queue Name
    public static void updateDepotQueues(List<Schema.Location> locList, Map<Id, Schema.Location> oldMap)
    {
        if (!FS_Utility.isActive('Update Depot Queues', 'Update Location Depot Queues'))
        {
            return;
        }

        Set<String> queueNames = new Set<String>();
        List<Schema.Location> locationsToUpdate = new List<Schema.Location>();
        for (Schema.Location loc : locList)
        {
            Schema.Location old = (oldMap == null) ? null : oldMap.get(loc.Id);
            if (loc.Depot_Queue_Name__c != null && (old == null || old.Depot_Queue_Name__c != loc.Depot_Queue_Name__c))
            {
                queueNames.add(loc.Depot_Queue_Name__c);
                locationsToUpdate.add(loc);
            }
        }

        if (queueNames.isEmpty())
        {
            return;
        }

        Map<String, Group> queueMap = new Map<String, Group>();
        List<Group> queues = [SELECT Id, Name, DeveloperName
            FROM Group WHERE Type = 'Queue' AND DeveloperName IN :queueNames];
        for (Group q : queues)
        {
            queueMap.put(q.DeveloperName, q);
        }

        // ITSVMX-35 Only allow this Queue Lookup if one of the valid "Queue" Roles
        for (Schema.Location loc : locationsToUpdate)
        {
            Group q = queueMap.get(loc.Depot_Queue_Name__c);
            if (q != null)
            {
                loc.Depot_Queue_Id__c = q.Id;
            }
            else
            {
                loc.addError('Could not find Queue with name: ' + loc.Depot_Queue_Name__c);
            }
        }
    }

//    public static void afterCompletedStockTransaction(List<Schema.Location> newLocList, Map<Id, Schema.Location> oldMap)
//    {
//        if (!FS_Utility.isActive('Completed Stock Transaction',
//                'Update ProductItems when Location Completed Stock Transaction Number is updated.'))
//            return;
//
//        Set<Id> locIds = new Set<Id>();
//        for (Schema.Location loc : newLocList)
//        {
//            Schema.Location old = (oldMap == null) ? null : oldMap.get(loc.Id);
//            if ( old != null && old.Completed_Stock_TxnNum__c != loc.Completed_Stock_TxnNum__c ) {
//                locIds.add(loc.id);
//            }
//        }
//        if (locIds.isEmpty())
//            return;
//
//        List<ProductItem> allItems = [SELECT Id, ProductItemNumber, LastTxnNum__c, QuantityOnHand
//            FROM ProductItem WHERE LocationId IN :locIds];
//        Map<Id, List<ProductItem>> locItemMap = new Map<Id, List<ProductItem>>();
//        // Fill in Location -> ProductItem map
//        for (ProductItem item : allItems)
//        {
//            if(!locItemMap.containsKey(item.LocationId)) {
//                locItemMap.put(item.LocationId, new List<ProductItem>());
//            }
//            locItemMap.get(item.LocationId).add(item);
//        }
//
//        // Main process
//        List<ProductItem> stockToUpdate = new List<ProductItem>();
//        for (Schema.Location loc : newLocList)
//        {
//            List<ProductItem> itemList = (locItemMap.containsKey(loc.Id)) ? locItemMap.get(loc.Id) : null;
//            if (itemList != null)
//            {
//                for (ProductItem item : itemList)
//                {
//                    if (item.LastTxnNum__c != loc.Completed_Stock_TxnNum__c) {
//                        item.QuantityOnHand = 0;
//                        stockToUpdate.add(item);
//                    }
//                }
//            }
//        }
//
//        // Update ProductItems
//        if (!stockToUpdate.isEmpty())
//            update stockToUpdate;
//    }
}