/*
 *  Apex Class for Installed Product [SVMXC__Installed_Product__c] Business Logic.
 *  2017-08-11      Veerendra Moodbidri       Initial creation, for IB Outbound Integration.
 *  1. Fetch locaion address from Location object and update in IP when a new IP is created.
 *  2. When a location address is changed, update the new location address in all related IPs of that location.
 */
public with sharing class FS_AssetManager {

    private FS_AssetManager() {
    }

    public static void updateAssetAddressFields(List<Asset> newIPList, Map<Id, Asset> oldMap)
    {
        if (!FS_Utility.isActive('Update Asset Address', 'Get the address from Location and update in Asset.')) {
            return;
        }

        List<Asset> ipList = new List<Asset>();
        Set<Id> locIds = new Set<Id>();
        for (Asset ip : newIPList)
        {
            Asset old = (oldMap == null) ? null : oldMap.get(ip.Id);
            if (ip.LocationId != null && (old == null || ip.LocationId != old.LocationId))
            {
                ipList.add(ip);
                locIds.add(ip.LocationId);
            }
        }

        if (locIds.isEmpty()) {
            return;
        }

        Map<Id, Schema.Location> locMap = new Map<Id, Schema.Location>([SELECT Id, Name,
                Street__c, City__c,State__c, Zip__c, Country__c,
                LKUP_State__c, LKUP_State__r.SFDC_State_Name__c,
                LKUP_Country__c, LKUP_Country__r.SFDC_Country_Name__c
            FROM Location WHERE Id IN :locIds]);

        for (Asset ip : ipList) 
        {
            Schema.Location loc = locMap.get(ip.LocationId);
            if (loc != null)
            {
                ip.Street = loc.Street__c;
                ip.City = loc.City__c;
                ip.PostalCode = loc.Zip__c;
                if (loc.LKUP_State__c != null) {
                    ip.State = loc.LKUP_State__r.SFDC_State_Name__c;
                }
                if (loc.LKUP_Country__c != null) {
                    ip.Country = loc.LKUP_Country__r.SFDC_Country_Name__c;
                }
            }
        }
    }

    public static void updateLookups(List<Asset> newList, Map<Id, Asset> oldMap)
    {
        if (!FS_Utility.isActive('Update Lookups', 'Update Preferred and Secondary Technician in Installed Product from the Technician.')) {
            return;
        }

        Set<String> techIds = new Set<String>();
        List<Asset> preferredIps = new List<Asset>();
        List<Asset> secondaryIps = new List<Asset>();
        Set<String> accountExtIds = new Set<String>();
        Set<String> salesOrgs = new Set<String>();
        for (Asset a : newList) {
            Asset old = (oldMap == null) ? null : oldMap.get(a.Id);
            if (a.SoldTo_ExtId__c != null &&
                    (a.AccountId == null || (old != null && a.SoldTo_ExtId__c != old.SoldTo_ExtId__c))) {
                accountExtIds.add(a.SoldTo_ExtId__c);
                a.AccountId = null;
                salesOrgs.add(a.SalesOrg__c);
            }
        }

        Map<String, Account> accountMap = FS_AccountManager.findAccounts(accountExtIds);

        // SVMXINT-516 - Add Partner Accounts to IP
        Set<Id> acctIds = new Set<Id>();
        Set<String> customerNumbers = new Set<String>();
        List<Asset> acctAssets = new List<Asset>();
        salesOrgs.clear();
        Set<String> contactExtIds = new Set<String>();
        List<Asset> contactAssets = new List<Asset>();
        for (Asset a : newList)
        {
            Asset old = (oldMap == null) ? null : oldMap.get(a.Id);
            if (a.PreferredTechnicianNumber__c != null &&
                (a.Preferred_Technician__c == null ||
                    (old != null && a.PreferredTechnicianNumber__c != old.PreferredTechnicianNumber__c)))
            {
                techIds.add(a.PreferredTechnicianNumber__c);
                preferredIps.add(a);
            }
            // IT-SFDC 578 - Blank out technican name if number is blank
            if (a.PreferredTechnicianNumber__c == null)
            {
                a.Preferred_Technician__c = null;
            }
            if (a.SecondaryTechnicianNumber__c != null &&
                (a.Secondary_Technician__c == null ||
                    (old != null && a.SecondaryTechnicianNumber__c != old.SecondaryTechnicianNumber__c)))
            {
                techIds.add(a.SecondaryTechnicianNumber__c);
                secondaryIps.add(a);
            }
            // IT-SFDC 578 - Blank out technican name if number is blank
            if (a.SecondaryTechnicianNumber__c == null)
            {
                a.Secondary_Technician__c = null;
            }

            if (a.AccountId == null && accountMap.containsKey(a.SoldTo_ExtId__c)) {
                a.AccountId = accountMap.get(a.SoldTo_ExtId__c).Id;
            }
            if (a.AccountId != null) {
                acctIds.add(a.AccountId);
            }

            if (a.SoldTo_ExtId__c != null &&
                (a.SoldTo_Account__c == null || (old != null && a.SoldTo_ExtId__c != old.SoldTo_ExtId__c)))
            {
                customerNumbers.add(a.SoldTo_ExtId__c);
                acctAssets.add(a);
                a.SoldTo_Account__c = null;
            }

            if (a.ShipTo_ExtId__c != null &&
                (a.ShipTo_Account__c == null || (old != null && a.ShipTo_ExtId__c != old.ShipTo_ExtId__c)))
            {
                customerNumbers.add(a.ShipTo_ExtId__c);
                acctAssets.add(a);
                a.ShipTo_Account__c = null;
            }

            if (a.BillTo_ExtId__c != null &&
                (a.BillTo_Account__c == null || (old != null && a.BillTo_ExtId__c != old.BillTo_ExtId__c)))
            {
                customerNumbers.add(a.BillTo_ExtId__c);
                acctAssets.add(a);
                a.BillTo_Account__c = null;
            }

            if (a.Payer_ExtId__c != null &&
                (a.Payer_Account__c == null || (old != null && a.Payer_ExtId__c != old.Payer_ExtId__c)))
            {
                customerNumbers.add(a.Payer_ExtId__c);
                acctAssets.add(a);
                a.Payer_Account__c = null;
            }

            if (String.isNotBlank(a.SalesOrg__c)) {
                salesOrgs.add(a.SalesOrg__c);
            }

            // SVMXINT-624 Local Language Partner on Equipment
            if (a.LL_ShipTo_ExtId__c != null &&
                (a.LL_ShipTo_Account__c == null
                    || (old != null && a.LL_ShipTo_ExtId__c != old.LL_ShipTo_ExtId__c)))
            {
                customerNumbers.add(a.LL_ShipTo_ExtId__c);
                acctAssets.add(a);
                a.LL_ShipTo_Account__c = null;
            }

            if (a.LL_BillTo_ExtId__c != null &&
                (a.LL_BillTo_Account__c == null
                    || (old != null && a.LL_BillTo_ExtId__c != old.LL_BillTo_ExtId__c)))
            {
                customerNumbers.add(a.LL_BillTo_ExtId__c);
                acctAssets.add(a);
                a.LL_BillTo_Account__c = null;
            }

            // SVMXINT-576 Installed Product : Partner (blanks)
            if (a.SoldTo_ExtId__c == null && a.SoldTo_Account__c != null) {
                a.SoldTo_Account__c = null;
            }
            if (a.ShipTo_ExtId__c == null && a.ShipTo_Account__c != null) {
                a.ShipTo_Account__c = null;
            }
            if (a.BillTo_ExtId__c == null && a.BillTo_Account__c != null) {
                a.BillTo_Account__c = null;
            }
            if (a.Payer_ExtId__c == null && a.Payer_Account__c != null) {
                a.Payer_Account__c = null;
            }
            if (a.LL_ShipTo_ExtId__c == null && a.LL_ShipTo_Account__c != null) {
                a.LL_ShipTo_Account__c = null;
            }
            if (a.LL_BillTo_ExtId__c == null && a.LL_BillTo_Account__c != null) {
                a.LL_BillTo_Account__c = null;
            }

            // Contact Lookups
            if (a.Contact_External_ID__c != null &&
                (a.ContactId == null || (old != null && a.Contact_External_ID__c != old.Contact_External_ID__c)))
            {
                contactExtIds.add(a.Contact_External_ID__c);
                contactAssets.add(a);
                a.ContactId = null;
            }

            if (a.LabManager_External_ID__c != null &&
                (a.LabManager__c == null || (old != null && a.LabManager_External_ID__c != old.LabManager_External_ID__c)))
            {
                contactExtIds.add(a.LabManager_External_ID__c);
                contactAssets.add(a);
                a.LabManager__c = null;
            }
        }

        if (!techIds.isEmpty())
        {
            Map<String, ServiceResource> techMap = new Map<String, ServiceResource>();
            for (ServiceResource tech : [SELECT Id, Name, External_ID__c 
                FROM ServiceResource WHERE External_ID__c IN :techIds])
            {
                techMap.put(tech.External_ID__c, tech);
            }

            for (Asset ip : preferredIps)
            {
                if (techMap.containsKey(ip.PreferredTechnicianNumber__c))
                {
                    ip.Preferred_Technician__c = techMap.get(ip.PreferredTechnicianNumber__c).Id;
                }
            }

            for (Asset ip : secondaryIps)
            {
                if (techMap.containsKey(ip.SecondaryTechnicianNumber__c))
                {
                    ip.Secondary_Technician__c = techMap.get(ip.SecondaryTechnicianNumber__c).Id;
                }
            }
        }

        if (!customerNumbers.isEmpty())
        {
            System.debug('*ASSET - Trying to find Customers: ' + customerNumbers + ', Accounts: ' + acctIds + ', SalesOrgs: ' + salesOrgs);
            Map<String, ERP_Address__c> erpMap = new Map<String, ERP_Address__c>();
            for (ERP_Address__c erp : [SELECT Id, Name, Address_Type__c, ERP_Sales_Org__c, fxCustomerNumber_Target__c
                FROM ERP_Address__c WHERE Account__c IN :acctIds
                    AND ERP_Sales_Org__c IN :salesOrgs
                    AND fxCustomerNumber_Target__c IN :customerNumbers])
            {
                String erpKey = getErpKey(erp.Address_Type__c, erp.ERP_Sales_Org__c, erp.fxCustomerNumber_Target__c);
                erpMap.put(erpKey, erp);
            }
            System.debug('*ASSET - Found Customers: ' + erpMap.keySet());

            for (Asset a : acctAssets)
            {
                String soldToKey = getErpKey('Sold To', a.SalesOrg__c, a.SoldTo_ExtId__c);
                if (a.SoldTo_ExtId__c != null && erpMap.containsKey(soldToKey))
                {
                    a.SoldTo_Account__c = erpMap.get(soldToKey).Id;
                }
                String shipToKey = getErpKey('Ship To', a.SalesOrg__c, a.ShipTo_ExtId__c);
                if (a.ShipTo_ExtId__c != null && erpMap.containsKey(shipToKey))
                {
                    a.ShipTo_Account__c = erpMap.get(shipToKey).Id;
                }
                String billToKey = getErpKey('Payer', a.SalesOrg__c, a.BillTo_ExtId__c);
                if (a.BillTo_ExtId__c != null && erpMap.containsKey(billToKey))
                {
                    a.BillTo_Account__c = erpMap.get(billToKey).Id;
                }
                String payerKey = getErpKey('Payer', a.SalesOrg__c, a.Payer_ExtId__c);
                if (a.Payer_ExtId__c != null && erpMap.containsKey(payerKey))
                {
                    a.Payer_Account__c = erpMap.get(payerKey).Id;
                }
                // SVMXINT-624 Local Language Partner on Equipment
                String llShipToKey = getErpKey('Ship To', a.SalesOrg__c, a.LL_ShipTo_ExtId__c);
                if (a.LL_ShipTo_ExtId__c != null && erpMap.containsKey(llShipToKey))
                {
                    a.LL_ShipTo_Account__c = erpMap.get(llShipToKey).Id;
                }
                String llBillToKey = getErpKey('Payer', a.SalesOrg__c, a.LL_BillTo_ExtId__c);
                if (a.LL_BillTo_ExtId__c != null && erpMap.containsKey(llBillToKey))
                {
                    a.LL_BillTo_Account__c = erpMap.get(llBillToKey).Id;
                }
            }
        }

        // Lookup Contacts (ContactId, LabManager__c) -- ERP_Relationship__c.External_Id__c & Contact__c
        if (!contactExtIds.isEmpty()) {
            Map<String, ERP_Relationship__c> erpMap = new Map<String, ERP_Relationship__c>();
            for (ERP_Relationship__c erp : [SELECT Id, Name, External_Id__c, Contact__c
                FROM ERP_Relationship__c WHERE External_Id__c IN :contactExtIds])
            {
                erpMap.put(erp.External_Id__c, erp);
            }

            for (Asset a : contactAssets)
            {
                if (a.Contact_External_ID__c != null && erpMap.containsKey(a.Contact_External_ID__c))
                {
                    a.ContactId = erpMap.get(a.Contact_External_ID__c).Contact__c;
                }
                if (a.LabManager_External_ID__c != null && erpMap.containsKey(a.LabManager_External_ID__c))
                {
                    a.LabManager__c = erpMap.get(a.LabManager_External_ID__c).Contact__c;
                }
            }
        }
    }

    public static String getErpKey(String type, String salesOrg, String extId) {
        return type + '-' + salesOrg + '-' + extId;
    }

/*
    public static void deleteIPclassifications(List<SVMXC__Installed_Product__c> newIpList, Map<Id, SVMXC__Installed_Product__c> oldIpMap)
    {        
        if (!SMAX_PS_Utility.isActive('Delete IP Classifications', 'Deletes the records in IP Classifications.'))
            return;

        List<SMAX_PS_InstalledProductClassification__c> ipcDeleteList = new List<SMAX_PS_InstalledProductClassification__c>();
        Map<id, list<SMAX_PS_InstalledProductClassification__c>> ipcMap = new Map<id, list<SMAX_PS_InstalledProductClassification__c>>();
        Set<Id> ipIds = new Set<Id>();

        if (!newIpList.isEmpty()) {
            for (SVMXC__Installed_Product__c ip : newIpList)
            {
                if ( oldIpMap.get(ip.id) != null && oldIpMap.get(ip.id).SMAX_PS_CompletedTxnNum__c != ip.SMAX_PS_CompletedTxnNum__c )
                    ipIds.add(ip.id);
            }
        }
        if (ipIds.isEmpty())
            return;

        List<SMAX_PS_InstalledProductClassification__c> ipcList = new List<SMAX_PS_InstalledProductClassification__c>([SELECT Id, Name, SMAX_PS_InstalledProduct__c, SMAX_PS_LastTxnNum__c FROM SMAX_PS_InstalledProductClassification__c WHERE SMAX_PS_InstalledProduct__c IN :ipIds]);

        // Fill in Installed Product Classification Map
        if (!ipcList.isEmpty()) {
            for (SMAX_PS_InstalledProductClassification__c ipc : ipcList) {
                List<SMAX_PS_InstalledProductClassification__c> listIPC = new List<SMAX_PS_InstalledProductClassification__c>();                
                if(ipcMap.containskey(ipc.SMAX_PS_InstalledProduct__c)) {
                    listIPC = ipcMap.get(ipc.SMAX_PS_InstalledProduct__c);
                }
                listIPC.add(ipc);
                ipcMap.put(ipc.SMAX_PS_InstalledProduct__c, listIPC);
            }
        }

        // Main process
        if (!newIpList.isEmpty()) {
            for ( SVMXC__Installed_Product__c ip : newIpList ) {
                // create list of records to be deleted in Installed Product Classifications
                List<SMAX_PS_InstalledProductClassification__c> listIPC = new List<SMAX_PS_InstalledProductClassification__c>();
                if ( ipcMap.ContainsKey(ip.Id) ) {
                    listIPC = ipcMap.get(ip.Id);
                    if (!listIPC.isEmpty()) {
                        for (SMAX_PS_InstalledProductClassification__c ipc : listIPC) {
                            if (ipc.SMAX_PS_LastTxnNum__c != ip.SMAX_PS_CompletedTxnNum__c)
                                ipcDeleteList.add(ipc);
                        }
                    }
                }
            }
            if (!ipcDeleteList.isEmpty())
                delete ipcDeleteList;
        }
    }*/

    public static void calibratedToolChangeLog(List<Asset> ipList, Map<Id, Asset> oldMap)
    {
        if (!FS_Utility.isActive('CalibratedTool ChangeLog', 'Creates a change log record every time a Calibrated Tool is changed.')) {
            return;
        }

        List<FS_MTE_ChangeLog__c> changeLogs = new List<FS_MTE_ChangeLog__c>();
        Set<Id> assetIds = new Set<Id>();
        //RecordType calToolRecType = FS_Utility.getRecordType('Asset', 'SMAX_PS_Calibrated_Tools');
        for (Asset ip : ipList)
        {
            //if (ip.RecordTypeId == calToolRecType.Id && ip.SMAX_PS_MTE_Change_Reason__c != null)

            if ( ip.MTE_Change_Reason__c != null)
            {
                // Found one.. create a Change Log and blank out fields.
                FS_MTE_ChangeLog__c log = new FS_MTE_ChangeLog__c();
                log.Asset__c = ip.Id;
                log.MTE_Change_Reason__c = ip.MTE_Change_Reason__c;
                log.MTE_Change_Description__c = ip.MTE_Change_Description__c;

                // Added a future to blank these out so fields can be required in the QuickAction
                assetIds.add(ip.Id);

                String summary = 'Summary of changes made:';
                Asset old = oldMap.get(ip.Id);
                Map<String, Schema.SObjectField> fieldMap = FS_Utility.getFields('Asset');
                for (String fieldName : fieldMap.keySet())
                {
                    Schema.DescribeFieldResult fieldInfo = fieldMap.get(fieldName).getDescribe();
                    if (ip.get(fieldName) != old.get(fieldName))
                    {
                        summary += '\nChanged ' + fieldInfo.getLabel() + ' from ' + old.get(fieldName) + ' to ' + ip.get(fieldName) + '.';
                    }
                }
                log.Summary_of_Changes__c = summary;
                changeLogs.add(log);
            }
        }

        if (!changeLogs.isEmpty()) {
            insert changeLogs;
        }

        if (!assetIds.isEmpty()) {
            resetMTEChangeFieldsFuture(assetIds);
        }
    }

    @Future
    public static void resetMTEChangeFieldsFuture(Set<Id> assetIds) {
        List<Asset> assets = new List<Asset>();
        for (Id assetId : assetIds) {
            Asset ip = new Asset();
            ip.Id = assetId;
            ip.MTE_Change_Reason__c = null;
            ip.MTE_Change_Description__c = null;
            assets.add(ip);
        }
        update assets;
    }
}