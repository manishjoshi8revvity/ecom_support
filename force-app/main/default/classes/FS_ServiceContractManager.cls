/*
 *  Apex Class for Service Contract [SVMXC__Service_Contract__c] Business Logic.
 *  2017-09-01      Veerendra Moodbidri         Initial creation, for Service Contract Outbound Integration.
 *  2017-10-11                                  Added the method "updateRenewedFrom"            
 *  1. Update "Is Deleted" to true in Service Contracts if "Completed Transaction number" is changed in the Parent Service Contract and it does not match with
    the Last Transaction NUmber in the Child Service Contract
 *  2. Update "Is Deleted" to true in all the Covered products related to the above Service Contracts if same conditions are met
 *  3. Update "Is Deleted" to true in all the Included Services related to the above Service Contracts if same conditions are met 
 *  4. Update "Is Deleted" to true in all the Entitlement Dates related to the above Included Services if same conditions are met
 *  Important note: The "Completed Transaction number" update happens only in the Parent Service Contract
 *  5. Update Renewed From/To Service Contract Number using Previous Contract Number and Renewal Contract Number
 */
public with sharing class FS_ServiceContractManager {

	private FS_ServiceContractManager() {
	}

	public static void updateLookups(List<ServiceContract> newContractList, Map<Id, ServiceContract> oldContractMap)
	{
		Set<String> salesOrgs = new Set<String>();
		List<ServiceContract> pbContracts = new List<ServiceContract>();
		List<ServiceContract> acctContracts = new List<ServiceContract>();
		Set<String> soldToExtIds = new Set<String>();
		List<ServiceContract> contactContracts = new List<ServiceContract>();
		Set<String> contactExtIds = new Set<String>();
		for (ServiceContract cont : newContractList)
		{
			ServiceContract old = (oldContractMap == null) ? null : oldContractMap.get(cont.Id);
			if (cont.Pricebook2Id == null && cont.SalesOrg__c != null) {
				pbContracts.add(cont);
				salesOrgs.add(cont.SalesOrg__c);
			}
			if (cont.SoldToNumber__c != null && cont.ParentServiceContractId == null
				&& (old == null || cont.AccountId == null || old.SoldToNumber__c != cont.SoldToNumber__c))
			{
				acctContracts.add(cont);
				soldToExtIds.add(cont.SoldToNumber__c);
			}

			if (cont.Contact_External_ID__c != null
				&& (old == null || cont.ContactId == null || old.Contact_External_ID__c != cont.Contact_External_ID__c))
			{
				contactContracts.add(cont);
				contactExtIds.add(cont.Contact_External_ID__c);
			}
		}

		if (!pbContracts.isEmpty()) {
			Map<String, Pricebook2> pbMap = new Map<String, Pricebook2>();
			for (Pricebook2 pb : [SELECT Id, Name, External_Id__c, IsStandard
				FROM Pricebook2 WHERE IsStandard = TRUE OR External_Id__c IN :salesOrgs]) {
				String pbKey = (pb.IsStandard) ? 'STANDARD' : pb.External_Id__c;
				pbMap.put(pbKey, pb);
			}
			if (Test.isRunningTest() && !pbMap.containsKey('STANDARD')) {
				pbMap.put('STANDARD', new Pricebook2(Id=Test.getStandardPricebookId()));
			}

			for (ServiceContract cont : pbContracts) {
				Pricebook2 pb = pbMap.get(cont.SalesOrg__c);
				if (pb == null) {
					pb = pbMap.get('STANDARD');
				}
				cont.Pricebook2Id = pb.Id;
			}
		}

		if (!acctContracts.isEmpty()) {
			Map<String, Account> accountMap = FS_AccountManager.findAccounts(soldToExtIds);
			for (ServiceContract cont : acctContracts) {
				Account acct = accountMap.get(cont.SoldToNumber__c);
				if (acct != null) {
					cont.AccountId = acct.Id;
				}
			}
		}

		if (!contactExtIds.isEmpty()) {
			Map<String, ERP_Relationship__c> erpMap = new Map<String, ERP_Relationship__c>();
			for (ERP_Relationship__c erp : [SELECT Id, Name, External_Id__c, Contact__c
				FROM ERP_Relationship__c WHERE External_Id__c IN :contactExtIds])
			{
				erpMap.put(erp.External_Id__c, erp);
			}

			for (ServiceContract sc : contactContracts)
			{
				if (sc.Contact_External_ID__c != null && erpMap.containsKey(sc.Contact_External_ID__c))
				{
					sc.ContactId = erpMap.get(sc.Contact_External_ID__c).Contact__c;
				}
			}
		}
	}

	public static void updateLineItemLookups(List<ContractLineItem> newList, Map<Id, ContractLineItem> oldMap) {
		List<ContractLineItem> pbeItems = new List<ContractLineItem>();
		Set<Id> contractIds = new Set<Id>();
		for (ContractLineItem item : newList) {
			if (item.PricebookEntryId == null) {
				contractIds.add(item.ServiceContractId);
				pbeItems.add(item);
			}
		}

		if (!pbeItems.isEmpty()) {
			Map<Id, ServiceContract> contractMap = new Map<Id, ServiceContract>([SELECT Id, Pricebook2Id, CurrencyIsoCode, Contract_Material__c
				FROM ServiceContract WHERE Id IN :contractIds]);
			Set<Id> pbIds = new Set<Id>();
			Set<Id> prodIds = new Set<Id>();
			Set<String> currencyCodes = new Set<String>();
			for (ServiceContract cont : contractMap.values()) {
				if (cont.Pricebook2Id != null && cont.Contract_Material__c != null) {
					pbIds.add(cont.Pricebook2Id);
					prodIds.add(cont.Contract_Material__c);
					currencyCodes.add(cont.CurrencyIsoCode);
				}
			}

			Id stdPricebookId = (Test.isRunningTest()) ? Test.getStandardPricebookId() :
					[SELECT Id, Name FROM Pricebook2 WHERE IsStandard = TRUE LIMIT 1].Id;
			pbIds.add(stdPricebookId);
			Map<String, PricebookEntry> pbeMap = new Map<String, PricebookEntry>();
			for (PricebookEntry pbe : [SELECT Id, Pricebook2Id, Product2Id, CurrencyIsoCode
				FROM PricebookEntry WHERE Pricebook2Id IN :pbIds AND Product2Id IN :prodIds AND CurrencyIsoCode IN :currencyCodes])
			{
				pbeMap.put(pbe.Pricebook2Id + '-' + pbe.Product2Id + '-' + pbe.CurrencyIsoCode, pbe);
			}

			Map<String, PricebookEntry> newPbeMap = new Map<String, PricebookEntry>();
			Map<String, PricebookEntry> newStdPbeMap = new Map<String, PricebookEntry>();
			for (ContractLineItem item : pbeItems) {
				ServiceContract cont = contractMap.get(item.ServiceContractId);
				String pbeKey = cont.Pricebook2Id + '-' + cont.Contract_Material__c + '-' + cont.CurrencyIsoCode;
				PricebookEntry pbe = pbeMap.get(pbeKey);
				if (pbe != null) {
					item.PricebookEntryId = pbe.Id;
				} else if (!newPbeMap.containsKey(pbeKey) && cont.Pricebook2Id != null && cont.Contract_Material__c != null) {
					// Need to create an entry.. but first, is there even a std entry?
					String stdPbeKey = stdPricebookId + '-' + cont.Contract_Material__c + '-' + cont.CurrencyIsoCode;
					PricebookEntry stdPbe = pbeMap.get(stdPbeKey);
					if (stdPbe == null && !newStdPbeMap.containsKey(stdPbeKey) && stdPricebookId != cont.Pricebook2Id) {
						stdPbe = new PricebookEntry();
						stdPbe.Pricebook2Id = stdPricebookId;
						stdPbe.Product2Id = cont.Contract_Material__c;
						stdPbe.UnitPrice = 0;
						stdPbe.CurrencyIsoCode = cont.CurrencyIsoCode;
						stdPbe.IsActive = true;
						newStdPbeMap.put(stdPbeKey, stdPbe);
					}

					pbe = new PricebookEntry();
					pbe.Pricebook2Id = cont.Pricebook2Id;
					pbe.Product2Id = cont.Contract_Material__c;
					pbe.UnitPrice = 0;
					pbe.CurrencyIsoCode = cont.CurrencyIsoCode;
					pbe.IsActive = true;
					newPbeMap.put(pbeKey, pbe);
				}
			}

			if (!newStdPbeMap.isEmpty()) {
				insert newStdPbeMap.values();
			}

			if (!newPbeMap.isEmpty()) {
				insert newPbeMap.values();

				for (ContractLineItem item : pbeItems) {
					if (item.PricebookEntryId == null) {
						ServiceContract cont = contractMap.get(item.ServiceContractId);
						String pbeKey = cont.Pricebook2Id + '-' + cont.Contract_Material__c + '-' + cont.CurrencyIsoCode;
						PricebookEntry pbe = newPbeMap.get(pbeKey);
						if (pbe != null) {
							item.PricebookEntryId = pbe.Id;
						}
					}
				}
			}
		}
	}

	// SVMXINT-602 - Treat "Cancelation Notes" as "Is Deleted"
	public static void updateIsDeletedByCancelNotes(List<ServiceContract> newContractList, Map<Id, ServiceContract> oldContractMap)
	{
		for (ServiceContract cont : newContractList)
		{
			//SVMXC__Service_Contract__c old = (oldContractMap == null) ? null : oldContractMap.get(cont.Id);
			if (cont.Cancelation_Notes__c != null && String.isNotBlank(cont.Cancelation_Notes__c))
			{
				cont.IsDeleted__c = true;
			}
		}
	}

	public static void updateIsDeleted(List<ServiceContract> newContractList, Map<Id, ServiceContract> oldContractMap)
	{
		if (!FS_Utility.isActive('Update Is Deleted Flag', 'Update Contract Items, Covered Products, Included Services and Entitlement Dates.'))
		{
			return;
		}

		Map<Id, ServiceContract> parentScMap = new Map<Id, ServiceContract>();
		Set<Id> contractIds = new Set<Id>();
		Set<String> completedTxns = new Set<String>();

		if (!newContractList.isEmpty()) {
			for (ServiceContract cont : newContractList)
			{
				ServiceContract old = (oldContractMap == null) ? null : oldContractMap.get(cont.Id);
				if (old != null && old.CompletedTxnNum__c != cont.CompletedTxnNum__c)
				{
					contractIds.add(cont.Id);
					parentScMap.put(cont.Id, cont);
					completedTxns.add(cont.CompletedTxnNum__c);
				}
			}
		}

		// Exit if no records are qualified
		if (contractIds.isEmpty())
		{
			return;
		}

		/*
		  Refactored this method as part of SVMXINT-571 "Create SFDC->SAP Service Contract Integration"
		  1) Filtered the queries by the Parent Contract, inside of each record's direct parent.
		  2) Only loaded records that might need to change..
			A) LastTxnNum doesnt match CompletedTxnNum
			B) IsDeleted = TRUE (might need to change back to FALSE)
		*/
		List<ServiceContract> scUpdateList = new List<ServiceContract>();
		List<ContractLineItem> cpUpdateList = new List<ContractLineItem>();
		List<Entitlement    > isUpdateList = new List<Entitlement   >();
		List<FS_EntitlementDate__c> edatesDeleteList = new List<FS_EntitlementDate__c>();
		List<FS_EntitlementDate__c> edatesUpdateList = new List<FS_EntitlementDate__c>();

		List<ServiceContract> itemList = [SELECT Id, Name, ParentServiceContractId, LastTxnNum__c, IsDeleted__c, Cancelation_Notes__c FROM ServiceContract WHERE ParentServiceContractId IN :contractIds AND (LastTxnNum__c NOT IN :completedTxns OR IsDeleted__c = TRUE)];
		System.debug('SVC-CONTRACT Checking Items: ' + itemList.size());

		for ( ServiceContract item : itemList )
		{
			ServiceContract parentSc = parentScMap.get(item.ParentServiceContractId);
			if ( parentSc.CompletedTxnNum__c != item.LastTxnNum__c && item.IsDeleted__c == false)
			{
				item.IsDeleted__c = true;
				scUpdateList.add(item);
			}
			else if (parentSc.CompletedTxnNum__c == item.LastTxnNum__c && item.IsDeleted__c == true && String.isBlank(item.Cancelation_Notes__c))
			{
				item.IsDeleted__c = false;
				scUpdateList.add(item);
			}
		}

		List<ContractLineItem> cpList = [SELECT Id, Parent_Contract__c, LastTxnNum__c, IsDeleted__c FROM ContractLineItem WHERE Parent_Contract__c IN :contractIds AND (LastTxnNum__c NOT IN :completedTxns OR IsDeleted__c = TRUE)];
		System.debug('SVC-CONTRACT Checking CPs: ' + cpList.size());

		for (ContractLineItem cp : cpList)
		{
			ServiceContract parentSc = parentScMap.get(cp.Parent_Contract__c);
			if (cp.LastTxnNum__c != parentSc.CompletedTxnNum__c && cp.IsDeleted__c == false)
			{
				cp.IsDeleted__c = true;
				cpUpdateList.add(cp);
			}
			else if (cp.LastTxnNum__c == parentSc.CompletedTxnNum__c && cp.IsDeleted__c == true)
			{
				cp.IsDeleted__c = false;
				cpUpdateList.add(cp);
			}
		}

		List<Entitlement> isList = [SELECT Id, Name, ServiceContract.ParentServiceContractId, LastTxnNum__c, IsDeleted__c FROM Entitlement WHERE ServiceContract.ParentServiceContractId IN :contractIds AND (LastTxnNum__c NOT IN :completedTxns OR IsDeleted__c = TRUE)];
		System.debug('SVC-CONTRACT Checking Entitlements: ' + isList.size());

		for (Entitlement is : isList)
		{
			ServiceContract parentSc = parentScMap.get(is.ServiceContract.ParentServiceContractId);
			if (is.LastTxnNum__c != parentSc.CompletedTxnNum__c && is.IsDeleted__c == false)
			{
				is.IsDeleted__c = true;
				isUpdateList.add(is);
			}
			else if (is.LastTxnNum__c == parentSc.CompletedTxnNum__c && is.IsDeleted__c == true)
			{
				is.IsDeleted__c = false;
				isUpdateList.add(is);
			}
		}

		List<FS_EntitlementDate__c> eDatesList = [SELECT Id, Name, ContractItem__r.ParentServiceContractId, LastTxnNum__c, WorkOrder__c, IsDeleted__c FROM FS_EntitlementDate__c WHERE ContractItem__r.ParentServiceContractId IN :contractIds AND (LastTxnNum__c NOT IN :completedTxns OR IsDeleted__c = TRUE)];
		System.debug('SVC-CONTRACT Checking EntDates: ' + eDatesList.size());

		for (FS_EntitlementDate__c eDate : eDatesList)
		{
			ServiceContract parentSc = parentScMap.get(eDate.ContractItem__r.ParentServiceContractId);
			if (eDate.LastTxnNum__c != parentSc.CompletedTxnNum__c && eDate.IsDeleted__c == false)
			{
				// SVMXCFG-455: Don't delete EntDate if WorkOrder lookup populated
				if (eDate.WorkOrder__c != null)
				{
					eDate.IsDeleted__c = true;
					edatesUpdateList.add(eDate);
				}
				else
				{
					edatesDeleteList.add(eDate);
				}
			}
			else if (eDate.LastTxnNum__c == parentSc.CompletedTxnNum__c && eDate.IsDeleted__c == true)
			{
				eDate.IsDeleted__c = false;
				edatesUpdateList.add(eDate);
			}
		}

		// Update Contract Items, Covered Products, Included Services and Entitlement Dates
		if (!scUpdateList.isEmpty())
		{
			update scUpdateList;
		}
		if (!cpUpdateList.isEmpty())
		{
			update cpUpdateList;
		}
		if (!isUpdateList.isEmpty())
		{
			update isUpdateList;
		}
		if (!edatesUpdateList.isEmpty())
		{
			update edatesUpdateList;
		}
		if (!edatesDeleteList.isEmpty())
		{
			delete edatesDeleteList;
		}

		createServiceContractEvents(parentScMap);
	}

	/**
	 *  SVMXINT-571 "Create SFDC->SAP Service Contract Integration"
	 */
	public static void createServiceContractEvents(Map<Id, ServiceContract> parentScMap)
	{
		if (!FS_Utility.isActive('Create ServiceContract Events', 'Create Service Contract Events to send to SAP when a Service Contract Txn is Completed.')) {
			return;
		}

		//Map<Id, SVMXC__Service_Contract__c> parentScMap = new Map<Id, SVMXC__Service_Contract__c>([SELECT Id, Name,
		//  SMAX_PS_CompletedTxnNum__c, SVMXC__Active__c, SVMX_PS_External_ID__c
		//  FROM SVMXC__Service_Contract__c WHERE Id IN :contractIds]);

		Map<Id, FS_ServiceContract_Event__e> eventMap = new Map<Id, FS_ServiceContract_Event__e>();
		for (ServiceContract sc : parentScMap.values())
		{
			FS_ServiceContract_Event__e sce = new FS_ServiceContract_Event__e();
			sce.ServiceContractId__c = sc.Id;
			sce.Action__c = 'STATUS';
			sce.SAP_ServiceContractNumber__c = sc.External_ID__c;
			sce.CreditOkay__c = sc.Active__c;
			//sce.timestamp = Datetime.now();
			eventMap.put(sc.Id, sce);
		}

		AggregateResult[] itemCounts = [SELECT ParentServiceContractId, IsDeleted__c, COUNT(Id) numItems
			FROM ServiceContract
			WHERE ParentServiceContractId IN :parentScMap.keySet()
			GROUP BY ParentServiceContractId, IsDeleted__c];
		for (AggregateResult result : itemCounts)
		{
			Id contractId = (Id) result.get('ParentServiceContractId');
			FS_ServiceContract_Event__e sce = eventMap.get(contractId);
			if (sce != null)
			{
				Integer count = (Integer) result.get('numItems');
				Boolean isDeleted = (Boolean) result.get('IsDeleted__c');
				if (isDeleted) {
					sce.Count_InactiveItems__c = count;
				} else {
					sce.Count_ActiveItems__c = count;
				}
			}
		}

		AggregateResult[] cpCounts = [SELECT Parent_Contract__c, IsDeleted__c, COUNT(Id) numCPs
			FROM ContractLineItem
			WHERE Parent_Contract__c IN :parentScMap.keySet()
				AND AssetId != NULL
			GROUP BY Parent_Contract__c, IsDeleted__c];
		for (AggregateResult result : cpCounts)
		{
			Id contractId = (Id) result.get('Parent_Contract__c');
			FS_ServiceContract_Event__e sce = eventMap.get(contractId);
			if (sce != null)
			{
				Integer count = (Integer) result.get('numCPs');
				Boolean isDeleted = (Boolean) result.get('IsDeleted__c');
				if (isDeleted) {
					sce.Count_InactiveCPs__c = count;
				} else {
					sce.Count_ActiveCPs__c = count;
				}
			}
		}

		AggregateResult[] edCounts = [SELECT ContractItem__r.ParentServiceContractId contractId, fxIs_Open__c,
				IsDeleted__c, COUNT(Id) numDates
			FROM FS_EntitlementDate__c
			WHERE ContractItem__r.ParentServiceContractId IN :parentScMap.keySet()
				AND PlannedDate__c != NULL
			GROUP BY ContractItem__r.ParentServiceContractId, fxIs_Open__c, IsDeleted__c];
		for (AggregateResult result : edCounts)
		{
			Id contractId = (Id) result.get('contractId');
			FS_ServiceContract_Event__e sce = eventMap.get(contractId);
			if (sce != null)
			{
				Integer count = (Integer) result.get('numDates');
				Boolean isOpen = (Boolean) result.get('fxIs_Open__c');
				Boolean isDeleted = (Boolean) result.get('IsDeleted__c');
				if (isOpen) {
					if (isDeleted) {
						sce.Count_InactiveOpenEntDates__c = count;
					} else {
						sce.Count_ActiveOpenEntDates__c = count;
					}
				}
				else if (isDeleted) {
					sce.Count_InactiveUsedEntDates__c = count;
				} else {
					sce.Count_ActiveUsedEntDates__c = count;
				}
			}
		}

		System.debug('SVC CONTRACT EVENTS = ' + eventMap.values());
		FS_PlatformEventUtility.publishEvents(eventMap.values(), 'ServiceContractId__c', 'Action__c');
	}

	public static void updateRenewedFromAndRenewedTo(List<ServiceContract> newContractList, Map<Id, ServiceContract> oldContractMap) {

		if (!FS_Utility.isActive('Update RenewedFrom And RenewedTo', 'Update RenewedFrom from the previous Contract number and Renewal date.')) {
			return;
		}

		if (!newContractList.isEmpty()) {
			Set<String> contractNumbers = new Set<String>();
			List<ServiceContract> renewedFroms = new List<ServiceContract>();
			List<ServiceContract> renewedTos = new List<ServiceContract>();
			for (ServiceContract cont : newContractList) {
				ServiceContract old = (oldContractMap == null) ? null : oldContractMap.get(cont.Id);
				if (cont.PreviousContractNumber__c != null &&
						(cont.Renewed_From__c == null || (old != null && old.PreviousContractNumber__c != cont.PreviousContractNumber__c)))
				{
					renewedFroms.add(cont);
					contractNumbers.add(cont.PreviousContractNumber__c);
				}

				if (cont.RenewalContractNumber__c != null &&
						(cont.Renewed_To__c == null || (old != null && old.RenewalContractNumber__c != cont.RenewalContractNumber__c)))
				{
					renewedTos.add(cont);
					contractNumbers.add(cont.RenewalContractNumber__c);
				}
			}

			if (contractNumbers.isEmpty()) {
				return;
			}

			Map<String, ServiceContract> contractMap = new Map<String, ServiceContract>();
			for (ServiceContract contract : [SELECT Id, Name, External_ID__c FROM ServiceContract WHERE External_ID__c IN :contractNumbers])
			{
				contractMap.put(contract.External_ID__c, contract);
			}


			for (ServiceContract cont : renewedFroms)
			{
				if (contractMap.containsKey(cont.PreviousContractNumber__c)) {
					ServiceContract other = contractMap.get(cont.PreviousContractNumber__c);
					cont.Renewed_From__c = (other == null) ? null : other.Id;
				}
			}

			for (ServiceContract cont : renewedTos)
			{
				if (contractMap.containsKey(cont.RenewalContractNumber__c)) {
					ServiceContract other = contractMap.get(cont.RenewalContractNumber__c);
					cont.Renewed_To__c = (other == null) ? null : other.Id;
					cont.Renewal_Date__c = Date.today();
				}
			}
		}
	}

	/**
	 *  Try to fill in the WO# from the ServiceOrder#
	 *  Should be called from the BEFORE insert/update triggers
	 */
	public static void lookupWorkOrders(List<FS_EntitlementDate__c> newList, Map<Id, FS_EntitlementDate__c> oldMap)
	{
		if (!FS_Utility.isActive('EntitlementDate Lookup WO', 'When EntitlementDates are created or updated, try to lookup their WO from the ServiceOrder number.')) {
			return;
		}

		Set<String> svcOrderNums = new Set<String>();
		for (FS_EntitlementDate__c eDate : newList)
		{
			if (String.isNotBlank(eDate.ServiceOrderNumber__c) && eDate.WorkOrder__c == null)
			{
				svcOrderNums.add(eDate.ServiceOrderNumber__c);
			}
		}

		if (svcOrderNums.isEmpty()) {
			return;
		}

		Map<String, WorkOrder> woMap = new Map<String, WorkOrder>();
		for (WorkOrder wo : [SELECT Id, External_ID__c FROM WorkOrder WHERE External_ID__c IN :svcOrderNums])
		{
			woMap.put(wo.External_ID__c, wo);
		}

		for (FS_EntitlementDate__c eDate : newList)
		{
			if (String.isNotBlank(eDate.ServiceOrderNumber__c) && eDate.WorkOrder__c == null)
			{
				WorkOrder wo = woMap.get(eDate.ServiceOrderNumber__c);
				if (wo != null)
				{
					eDate.WorkOrder__c = wo.Id;
				}
			}
		}
	}

	// ITSFDC-1047 Auto-Populate the "Remote Hours Remaining" on insert only.. this field is controlled by SMAX now
	/*public static void copyRemoteHoursRemaining(List<SVMXC__Service_Contract__c> newList)
	{
	  for (SVMXC__Service_Contract__c contract : newList)
	  {
		if (contract.BD_Item_Qty_Remaining__c != null && contract.BD_Item_Qty_Remaining__c != 0
			&& contract.BD_Remote_Hours_Remaining__c == null)
		{
		  contract.BD_Remote_Hours_Remaining__c = contract.BD_Item_Qty_Remaining__c;
		}
	  }
	}*/

	// ITSVMX-228 Map contract type from Parent contract (header) to line items (create a new field on the page layout)
	// Should be called from the BeforeInsert trigger event
	public static void updateContractItemFromParent(List<ServiceContract> newList) {
		// Get list of parent Service Contract Ids
		Set<Id> parentIds = new Set<Id>();
		for (ServiceContract contract :newList) {
			// Get parent Service Contract Id
			Id parentId = contract.ParentServiceContractId;
			if (parentId != null) {
				parentIds.add(parentId);
			}
		}
		System.debug('parentIds: ' + parentIds);

		if (parentIds.size() <= 0) return;

		// Get list of parent Service Contract records
		Map<Id, ServiceContract> parentServiceContracts = new Map<Id, ServiceContract>([ SELECT Id, ContractType__c, AccountId
			FROM ServiceContract WHERE Id IN :parentIds]);
		System.debug('parentServiceContracts: ' + parentServiceContracts);

		for (ServiceContract contract :newList) {
			// Set Contract Type to parent Contract Type
			Id parentId = contract.ParentServiceContractId;
			if (parentId != null) {
				ServiceContract parent = parentServiceContracts.get(parentId);
				contract.AccountId = parent.AccountId;
				contract.ContractType__c = parent.ContractType__c;
			}
		}
		System.debug('Updated Contract Item Records: ' + newList);
	}

	// Copy AccountId from ServiceContract to Entitlement
	public static void updateEntitlementLookups(List<Entitlement> newList, Map<Id, Entitlement> oldMap) {
		Set<Id> contractIds = new Set<Id>();
		for (Entitlement ent : newList) {
			if (ent.ServiceContractId != null) {
				contractIds.add(ent.ServiceContractId);
			}
		}

		if (!contractIds.isEmpty()) {
			Map<Id, ServiceContract> contractMap = new Map<Id, ServiceContract>([SELECT Id, Name, AccountId
				FROM ServiceContract WHERE Id IN :contractIds]);
			for (Entitlement ent : newList) {
				if (ent.ServiceContractId != null) {
					ServiceContract contract = contractMap.get(ent.ServiceContractId);
					if (contract != null) {
						ent.AccountId = contract.AccountId;
					}
				}
			}
		}
	}

	public class EntitlementCoverage {
		//@AuraEnabled public Boolean remoteHourBlock {get;set;}
		//@AuraEnabled public String remoteHoursRemaining {get;set;}
		@AuraEnabled public Boolean selectedCoveredProduct {get;set;}
		@AuraEnabled public String installedProduct {get;set;}
		@AuraEnabled public String slaTermsNotes {get;set;}
		@AuraEnabled public Boolean itemQtyBlock {get;set;}
		@AuraEnabled public String itemQty {get;set;}
		@AuraEnabled public String itemQtyRemaining {get;set;}
		@AuraEnabled public Date startDate {get;set;}
		@AuraEnabled public Date endDate {get;set;}
		@AuraEnabled public String coveredProduct {get;set;}
		@AuraEnabled public String serviceMaintenanceContract {get;set;}
		@AuraEnabled public String installedProductId {get;set;}
		@AuraEnabled public String coveredProductId {get;set;}
		@AuraEnabled public String serviceMaintenanceContractId {get;set;}
		// 10/5/21 ITSVMX-620 CONTRACTS ENTITLEMENT IMPROVEMENTS
		@AuraEnabled public String salesOrg {get;set;}
		// 4/6/22 ITSVMX-710 Contract Description
		@AuraEnabled public String description {get;set;}
	}

	// 9/13/21 Tony ITSVMX-408 Added so we can show indicator for the entitlement that is selected on the WO
	@AuraEnabled(Cacheable=true)
	public static List<EntitlementCoverage> getEntitlementCoverage(Id recordId) {
		return getEntitlementCoverage(recordId, null);
	}

	// ITSVMX-408 Used by the SmaxRemoteHourBlocks LWC
	public static List<EntitlementCoverage> getEntitlementCoverage(Id recordId, Id selectedEntitlementId) {
		List<EntitlementCoverage> result = new List<EntitlementCoverage>();

		// Determine what object we are dealing with from the recordId
		SObjectType workOrderType = Schema.WorkOrder.SObjectType;
		SObjectType caseType = Schema.Case.SObjectType;
		SObjectType assetType = Schema.Asset.SObjectType;
		SObjectType objectType = recordId.getSobjectType();
		if (objectType == workOrderType) {
			System.debug('Work Order Object Type: ' + recordId);
			List<WorkOrder> wos = [SELECT  Id, WorkOrderNumber, ServiceContractId, ContractItem__c, CoveredProduct__c, AssetId
					FROM WorkOrder WHERE Id = :recordId];
			System.debug('wos: ' + wos);
			if (wos.size() > 0) {
				Id ipId = wos[0].AssetId;
				System.debug('Work Order Found.  Asset for WO: ' + ipId);
				if (ipId != null) {
					// 9/13/21 Tony - Updated so we can send the selected entitlement
					return getEntitlementCoverage(ipId, wos[0]?.CoveredProduct__c);
				}
			} else {
				System.debug('Work Order not found.  Stop Entitlement Coverage processing.');
				return null;
			}
		}  else if (objectType == caseType) {
			System.debug('Case Object Type: ' + recordId);
			List<Case> caseRecords = [SELECT  Id, AssetId, RecordTypeId FROM Case WHERE Id = :recordId];
			System.debug('caseRecords: ' + caseRecords);
			if (caseRecords.size() > 0) {
				Id ipId = caseRecords[0].AssetId;
				System.debug('Case Found.  Installed Product for Case: ' + ipId);
				if (ipId != null) {
					return getEntitlementCoverage(ipId);
				}
			} else {
				System.debug('Case not found.  Stop Remote Hour Block processing.');
				return null;
			}
		} else if (objectType == assetType) {
			System.debug('Installed Product Object Type: ' + recordId);
			// Use the Contract Products to get the Contract Item info associated to this Installed Product
			List<ContractLineItem> contractProducts = [
					SELECT Id, LineItemNumber, SLA_Terms_Notes__c, IsDeleted__c, ServiceContractId, fxContract_Active__c,
							AssetId, Asset.Name,
							ServiceContract.Item_Qty__c, ServiceContract.Item_Qty_Remaining__c,
							ServiceContract.StartDate, ServiceContract.EndDate, ServiceContract.Name,
							Parent_Contract__r.SalesOrg__c, Parent_Contract__r.Description__c
					FROM ContractLineItem
					WHERE AssetId = :recordId
			];
			System.debug('contractProducts: ' + contractProducts);

			// Fill out the result list from the contract products
			Date today = Date.today();
			for (ContractLineItem contractProduct :contractProducts) {

				// Only do this for Remote Support Hours and current date is in the active range
				if (contractProduct.SLA_Terms_Notes__c != null
						&& contractProduct.IsDeleted__c == false
						&& contractProduct.ServiceContract.StartDate <= today
						&& contractProduct.ServiceContract.EndDate >= today) {

					EntitlementCoverage rhb = new EntitlementCoverage();
					// 9/13/21 Tony - Added to support the highlighting of the selected entitlement
					if (contractProduct.Id == selectedEntitlementId) {
						rhb.selectedCoveredProduct = true;
					} else {
						rhb.selectedCoveredProduct = false;
					}

					rhb.installedProductId = contractProduct.AssetId;
					rhb.installedProduct = contractProduct.Asset.Name;
					rhb.slaTermsNotes = contractProduct.SLA_Terms_Notes__c;
					if (contractProduct.ServiceContract.Item_Qty__c > 0) {
						rhb.itemQtyBlock = true;
						rhb.itemQty = String.valueOf(contractProduct.ServiceContract.Item_Qty__c);
						rhb.itemQtyRemaining = String.valueOf(contractProduct.ServiceContract.Item_Qty_Remaining__c);
					}
					//rhb.remoteHourBlock = (contractProduct.SLA_Terms_Notes__c.contains('ZHRS-Remote Support Hours'));
					//rhb.remoteHoursRemaining = String.valueOf(contractProduct.ServiceContract.Remote_Hours_Remaining__c);
					rhb.startDate = contractProduct.ServiceContract.StartDate;
					rhb.endDate = contractProduct.ServiceContract.EndDate;
					rhb.coveredProductId = contractProduct.Id;
					rhb.coveredProduct = contractProduct.LineItemNumber;
					rhb.serviceMaintenanceContractId = contractProduct.ServiceContractId;
					rhb.serviceMaintenanceContract = contractProduct.ServiceContract.Name;
					rhb.salesOrg = contractProduct.Parent_Contract__r.SalesOrg__c;
					rhb.description = contractProduct.Parent_Contract__r.Description__c;

					result.add(rhb);
				}
			}
			System.debug('result: ' + result);

		} else {
			System.debug('Error: The Contract Entitlement LWC only works for Case, Work Order and Asset object types.');
			return null;
		}

		return result;
	}
}