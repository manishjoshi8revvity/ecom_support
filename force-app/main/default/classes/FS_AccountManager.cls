/**
 * Created by frankvanloon on 4/8/24.
 */

public with sharing class FS_AccountManager {

	public static Map<String, Account> findAccounts(Set<String> erpCustomerNumbers) {
		Map<String, Account> accountMap = new Map<String, Account>();
		if (!erpCustomerNumbers.isEmpty())
		{
//            for (ERP_Address__c erp : [SELECT Id, Name, Account__r.Id, Account__r.Name, fxCustomerNumber_Target__c
//                FROM ERP_Address__c WHERE Address_Type__c = 'Sold To'
//                    AND ERP_Sales_Org__c IN :salesOrgs
//                    AND fxCustomerNumber_Target__c IN :accountExtIds])
//            {
//                accountMap.put(erp.fxCustomerNumber_Target__c, erp.Account__r);
//            }

			Map<String, ERP_Address__c> masters = new Map<String, ERP_Address__c>();
			Map<Decimal, Account> mdmClusterMap = new Map<Decimal, Account>();
			Map<String, Account> mdmMap = new Map<String, Account>();
			for (ERP_Address__c erp : [SELECT Id, Name, Address_Type__c, ERP_Customer_Number__c, ERP_Account_Group__c,
					MDM_Cluster_Id__c, MDM_ID__c
				FROM ERP_Address__c WHERE Address_Type__c = 'Master'
					AND ERP_Customer_Number__c IN :erpCustomerNumbers])
			{
				masters.put(erp.ERP_Customer_Number__c, erp);
//				if (erp.ERP_Account_Group__c == '0001') {
					mdmClusterMap.put(erp.MDM_Cluster_Id__c, null);
//				} else {
//					mdmMap.put(erp.MDM_ID__c, null);
//				}
			}

			if (!mdmClusterMap.isEmpty()) {
				for (Account acct : [SELECT Id, Name, MDM_Cluster_ID__c
					FROM Account WHERE MDM_Cluster_ID__c IN :mdmClusterMap.keySet()])
				{
					mdmClusterMap.put(acct.MDM_Cluster_ID__c, acct);
				}
			}
			if (!mdmMap.isEmpty()) {
				for (Account acct : [SELECT Id, Name, MDM_ID__c
					FROM Account WHERE MDM_ID__c IN :mdmMap.keySet()])
				{
					mdmMap.put(acct.MDM_ID__c, acct);
				}
			}

			for (String erpNumber : masters.keySet()) {
				ERP_Address__c erp = masters.get(erpNumber);
				Account acct = //(erp.ERP_Account_Group__c == '0001') ?
						mdmClusterMap.get(erp.MDM_Cluster_Id__c);// :
						//mdmMap.get(erp.MDM_ID__c);
				if (acct != null) {
					accountMap.put(erpNumber, acct);
				}
			}
		}
		return accountMap;
	}

	/**
		Finds ERP Relationship junction records between Contact and ERP Address (Sold To).
		@return Map<String, ERP_Relationship__c> String key = {ContactId}_{SoldToId}
	 */
	public static Map<String, ERP_Relationship__c> findContactRelationships(Set<Id> contactIds, Set<Id> soldToIds) {
		Set<Id> masterIds = new Set<Id>();
		for (ERP_Address__c erpAddr : [SELECT Id, Master_Address__c FROM ERP_Address__c WHERE Id IN :soldToIds]) {
			masterIds.add(erpAddr.Master_Address__c);
		}

		Map<String, ERP_Relationship__c> results = new Map<String, ERP_Relationship__c>();
		List<ERP_Relationship__c> relationships = [SELECT Id, Name, Contact__c, ERP_Address__c, ERP_Contact_ID__c
			FROM ERP_Relationship__c WHERE Contact__c IN :contactIds AND ERP_Address__c IN :masterIds];
		for (ERP_Relationship__c relationship : relationships) {
			String key = relationship.Contact__c; // + '_' + relationship.ERP_Address__c;
			results.put(key, relationship);
		}
		return results;
	}

	public static Map<String, Map<String, ERP_Address__c>> findPartnerAccounts(Map<String, String> erpCustomerNumberSalesOrgs)
	{
		Map<String, Map<String, ERP_Address__c>> result = new Map<String, Map<String, ERP_Address__c>>();
		if (!erpCustomerNumberSalesOrgs.isEmpty())
		{
			Set<String> erpCustomerNumbers = erpCustomerNumberSalesOrgs.keySet();
			Set<String> salesOrgs = new Set<String>(erpCustomerNumberSalesOrgs.values());

			for (ERP_Address__c partner : [SELECT Id, Name, ERP_Sales_Org__c, Address_Type__c, fxCustomerNumber_Target__c,
					Master_Address__r.ERP_Customer_Number__c
				FROM ERP_Address__c WHERE ERP_Sales_Org__c IN :salesOrgs
					AND Master_Address__r.Address_Type__c = 'Master'
					AND Master_Address__r.ERP_Customer_Number__c IN :erpCustomerNumbers])
			{
				String erpNum = partner.Master_Address__r.ERP_Customer_Number__c;
				String inputSalesOrg = erpCustomerNumberSalesOrgs.get(erpNum);
				if (inputSalesOrg == partner.ERP_Sales_Org__c) {
					if (!result.containsKey(erpNum)) {
						result.put(erpNum, new Map<String, ERP_Address__c>());
					}
					result.get(erpNum).put(partner.Address_Type__c, partner);
				}
			}
		}
		return result;
	}
}