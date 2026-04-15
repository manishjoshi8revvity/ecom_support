/**
 * This class encapsulates all of the Wired Services needed for the Inventory Count LWC
 * Created by frankvanloon & Seth on 5/5/20.
 * Updated by frankvanloon on 11/16/2021: Preventing updates to Inventory Count if already Approved
 * CONVERTED to SFS by frankvanloon on 4/11/24.
 */
public with sharing class FS_Inventory_Count_Approval {

	public class FS_Inventory_Count_Exception extends Exception { }

	// Results for the Single or Multi Select Picklists
	public class LabelValue
	{
		@AuraEnabled public String label { get; set; }
		@AuraEnabled public String value { get; set; }

		public LabelValue(String l, String v)
		{
			this.label = l;
			this.value = v;
		}
	}

	// Used to initialize the filters on the LWC
	public class InventoryCountFilterData
	{
		@AuraEnabled public List<LabelValue> allPlants { get; set; }
		@AuraEnabled public List<LabelValue> allStatuses { get; set; }
		@AuraEnabled public List<LabelValue> allTechnicians { get; set;}
		@AuraEnabled public String location { get; set; }
		@AuraEnabled public FS_InventoryCount__c countTemplate { get; set; }

		public InventoryCountFilterData()
		{
		}
	}

	// Filter parameters passed from the LWC
	public class InventoryCountFilter
	{
		@AuraEnabled public List<String> selectedPlants { get; set; }
		@AuraEnabled public List<String> selectedStatuses { get; set; }
		@AuraEnabled public String selectedLocation { get; set; }
		@AuraEnabled public String selectedTechnician { get; set;}
		@AuraEnabled public List<FS_CustomLookupService.LookupSearchResult> selectedTechnicians { get; set; }

		public InventoryCountFilter()
		{
		}
	}

	// Parameters passed in to update a set of Inventory Count Line records
	public class InventoryUpdateList
	{
		@AuraEnabled public List<String> selectedLines { get; set; }
		@AuraEnabled public String selectedReviewStatus { get; set; }
		@AuraEnabled public String selectedRejectReason { get; set;}

		public InventoryUpdateList()
		{
		}
	}

	// 8/17/20 tony - Parameters passed in to update Inventory Count Lines for a single selected Inventory Count header
	public class InventoryHeaderUpdateData
	{
		@AuraEnabled public String selectedHeaderLine { get; set; }
		@AuraEnabled public String selectedReviewStatus { get; set; }
		@AuraEnabled public String selectedRejectReason { get; set;}

		public InventoryHeaderUpdateData()
		{
		}
	}

	@AuraEnabled(Cacheable=true)
	public static InventoryCountFilterData lookupFilters()
	{
		InventoryCountFilterData result = new InventoryCountFilterData();
		result.allPlants = loadPlants();
		result.allStatuses = new List<LabelValue>();
		Schema.DescribeFieldResult fieldResult = FS_InventoryCount__c.Status__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple){
			result.allStatuses.add(new LabelValue(pickListVal.getLabel(),pickListVal.getLabel()));
		}

		result.countTemplate = new FS_InventoryCount__c();
		return result;
	}

	public static List<LabelValue> loadPlants()
	{
		List<LabelValue> plants=new List<LabelValue>();
		for(AggregateResult s:[SELECT Plant__c FROM ServiceResource
			WHERE Plant__c!=NULL GROUP BY Plant__c])
		{
			String p=(String) s.get('Plant__c');
			plants.add(new LabelValue(p,p));
		}
		return plants;
	}

	@AuraEnabled(Cacheable=false)
	public static List<FS_InventoryCount__c> filterInventory(InventoryCountFilter filter) {
		System.debug('filter:'+filter);
		List<FS_InventoryCount__c> inventoryList=new List<FS_InventoryCount__c>();

		String filterError=null;
		if((filter.selectedPlants!=null || filter.selectedTechnicians!=null))
		{
			String whereClause = '';
			List<String> statuses=filter.selectedStatuses;
			if(filter.selectedStatuses==null || filter.selectedStatuses.isEmpty()) {
				statuses.add('Submitted');
			}
			whereClause+=('Status__c IN :statuses');

			//List<String> whereClauses = new List<String>();
			//whereClauses.add('Status__c IN :filter.selectedStatuses ');

			Set<Id> technicianIds=new Set<Id>();
			Set<Id> locationIds=new Set<Id>();

			Set<String> plants= new Set<String>();
			if (filter.selectedPlants != null) {
				plants.addAll(filter.selectedPlants);
			}

			whereClause += ' AND (';
			System.debug('Selected Technicians/Locations: ' + filter.selectedTechnicians);
			if (filter.selectedTechnicians != null)
			{
				for (FS_CustomLookupService.LookupSearchResult searchResult : filter.selectedTechnicians)
				{
					if (searchResult.sObjectType == 'ServiceResource') {
						System.debug('TECHNICIAN for filter: ' + searchResult.id);
						technicianIds.add(searchResult.id);
					}
					if (searchResult.sObjectType == 'Location') {
						System.debug('LOCATION for filter: ' + searchResult.id);
						locationIds.add(searchResult.id);
					}
					if (searchResult.sObjectType == 'PLANT') {
						System.debug('PLANT for filter: ' + searchResult.id);
						plants.add(searchResult.id);
					}
				}
				if (!technicianIds.isEmpty()) {
					//whereClauses.add('RequestedTechnician__c IN :technicianIds');
					whereClause+=(' RequestedTechnician__c IN  :technicianIds OR');
				}
				if (!locationIds.isEmpty()) {
					//whereClauses.add('RequestedTechnician__r.SVMXC__Inventory_Location__c IN :locationIds ');
					// ITSVMX-392 Find Inv Counts without Technician
					//whereClause+=(' RequestedTechnician__r.SVMXC__Inventory_Location__c IN :locationIds OR');
					whereClause+=(' RequestedFrom__c IN :locationIds OR');
				}
			}

			if (plants != null && !plants.isEmpty()) {
				// ITSVMX-392 Find Inv Counts without Technician
				//whereClause+=(' RequestedTechnician__r.Plant__c IN :plants OR');
				whereClause+=(' fxMaintenance_Plant__c IN :plants OR');
			}
			whereClause = whereClause.removeEnd('OR') + ')';
			System.debug('whereclause: ' + whereClause);

			String fullQuery = 'SELECT Id, Name, Status__c, LastModifiedDate, ' +
					'RequestedTechnician__r.Name, ' +
					'fxMaintenance_Plant__c, RequestedFrom__c, ' +
					'RequestedFrom__r.LocationCode__c, RequestedFrom__r.Name, ' +
					// 8/6/20 tony - added new rollup fields for header lines
					'Booked_Qty_Total__c, Counted_Qty_Total__c, Entry_Qty_Total__c, Lines_Count__c, ' +
					'Is_Found_Item_True_Count__c, CurrencyIsoCode, Is_Found_Item_True_Qty__c, Difference_Value_Total__c ' +
					'FROM FS_InventoryCount__c WHERE '
					+ whereClause + ' ORDER BY ' +  'Name' + ' LIMIT 1000';

			inventoryList = Database.query(fullQuery);
			if (inventoryList.size() > 500) {
				filterError='Stock list update size limited to 500 records. Current Size: '+inventoryList.size()+'. Please apply additional filters.';
				inventoryList=new List<FS_InventoryCount__c>();
				// ITSVMX-1327 Throw error to show to user in LWC
				throw new FS_Inventory_Count_Exception(filterError);
			}
		}

		// 8/6/20 tony - Added for the Summary of the Difference Values
		// Query the Lines and then iterate over them to update the inventoryList with the Difference values
		Set<Id> inventoryCountIds = new Set<Id>();
		Set<String> currencyCodes = new Set<String>();
		for (FS_InventoryCount__c inventoryCount :inventoryList) {
			inventoryCountIds.add(inventoryCount.Id);
			currencyCodes.add(inventoryCount.CurrencyIsoCode);
		}

		Map<String, CurrencyType> currencyMap = new Map<String, CurrencyType>();
		for(CurrencyType cType : [SELECT IsoCode, ConversionRate
			FROM CurrencyType WHERE IsoCode IN :currencyCodes]) {
			currencyMap.put(cType.IsoCode, cType);
		}

		List<AggregateResult> aggregateResults = [
			SELECT InventoryCount__c, SUM(fxDifferenceValue__c) DifferenceSum
				FROM FS_InventoryCountLine__c
				WHERE InventoryCount__c IN :inventoryCountIds
				GROUP BY InventoryCount__c
		];
		System.debug('inventoryCountLines with Difference Value: ' + aggregateResults);

		Map<Id, Decimal> inventoryCountIdToDifferenceValue = new Map<Id, Decimal>();
		for (AggregateResult aggregateResult :aggregateResults) {
			Id inventoryCountId = (Id) aggregateResult.get('InventoryCount__c');
			Decimal differenceSum = (Decimal) aggregateResult.get('DifferenceSum');
			inventoryCountIdToDifferenceValue.put(inventoryCountId, differenceSum);
		}
		System.debug('inventoryCountIdToDifferenceValue: ' + inventoryCountIdToDifferenceValue);

		List<FS_InventoryCount__c> invToUpdate = new List<FS_InventoryCount__c>();
		for (FS_InventoryCount__c inventoryCount :inventoryList) {
			Decimal diffSum = inventoryCountIdToDifferenceValue.get(inventoryCount.Id);
			CurrencyType currencyType = currencyMap.get(inventoryCount.CurrencyIsoCode);
			if (diffSum != null && currencyType != null) {
				Decimal updatedValue = diffSum * currencyType.ConversionRate;
				// 20211116: FRANK - Do not update if the count is already 'Approved'
				if (updatedValue != inventoryCount.Difference_Value_Total__c
						&& inventoryCount.Status__c != 'Approved') {
					inventoryCount.Difference_Value_Total__c = updatedValue;
					invToUpdate.add(inventoryCount);
				}
			}
		}
		if (!invToUpdate.isEmpty()) {
			update invToUpdate;
		}

		System.debug('Inventory Counts found:' + inventoryList.size());
		return inventoryList;
	}

	@AuraEnabled(Cacheable=false)
	public static List<FS_InventoryCountLine__c> getLines(Id inventoryCountId)
	{
		System.debug('Getting Lines for Inventory Count: ' + inventoryCountId);
		List<FS_InventoryCountLine__c> result = [SELECT Id, LastModifiedDate, Name, InvCnt_Status__c,
				BookedQty__c, CountedQty__c, Difference_In_Qty__c, InventoryCount__c,
				Reason_for_Difference__c, fxSAP_Calcualted_Stock_Cost__c,
				fxDifference_in_Cost__c, fxCounted_Product_Cost__c, fxProductCost__c,
				Value_of_PhysicalInventoryCount__c, ValueofBookedQty__c, fxDifferenceValue__c,
				Selected__c, Product__c, Product__r.Part_Number__c, Product__r.Name,
				Why_Recount_Needed__c, Found_Item__c, EntryQty__c, CurrencyIsoCode
			FROM FS_InventoryCountLine__c WHERE InventoryCount__c = :inventoryCountId];
		return result;
	}

	@AuraEnabled(Cacheable=false)
	public static String updateInventory(InventoryUpdateList iList)
	{
		System.debug('updateInventory method');
		Set<Id> lineIds=new Set<Id>();
		for(String st : iList.selectedLines){
			lineIds.add(Id.valueOf(st));
		}

		List<FS_InventoryCountLine__c> lines = [SELECT Id, InvCnt_Status__c, Why_Recount_Needed__c,
				Confirmed_Date__c, Confirmed_By__c, Recount_Requested_Date__c, Recount_Requested_By__c
		FROM FS_InventoryCountLine__c WHERE Id IN :lineIds];
		List<FS_InventoryCountLine__c> updates = new List<FS_InventoryCountLine__c>();
		for (FS_InventoryCountLine__c i : lines)
		{
			if (i.InvCnt_Status__c == 'Submitted')
			{
				i.InvCnt_Status__c = iList.selectedReviewStatus;
				if (iList.selectedReviewStatus == 'Confirmed') {
					i.Confirmed_Date__c = Datetime.now();
					i.Confirmed_By__c = UserInfo.getName();
				}
				else if (iList.selectedReviewStatus == 'Recount') {
					i.Recount_Requested_Date__c = Datetime.now();
					i.Recount_Requested_By__c = UserInfo.getName();
					i.Why_Recount_Needed__c = iList.selectedRejectReason;
				}
				updates.add(i);
			}
			else if (i.InvCnt_Status__c == 'Confirmed')
			{
				i.InvCnt_Status__c = iList.selectedReviewStatus;
				if (iList.selectedReviewStatus == 'Approved') {
					i.Approved_Date__c = Datetime.now();
					i.Approved_By__c = UserInfo.getName();
				}
				updates.add(i);
			}
		}

		String result=null;
		if (updates.isEmpty()) {
			result = 'No lines to update found';
		} else {
			try {
				update updates;
				result= updates.size()+ ' records updated.';
			} catch (Exception e) {
				result= 'Error while trying to update lines: ' + e;
			}
		}

		System.debug('result '+result);
		return result;
	}

	// 8/17/20 tony - Added to allow Inventory Counts Lines to be updated when a Header is checked
	@AuraEnabled(Cacheable=false)
	public static String updateInventoryFromHeader(InventoryHeaderUpdateData headerData)
	{
		System.debug('updateInventoryFromHeader method');
		Id headerId = Id.valueOf(headerData.selectedHeaderLine);

		List<FS_InventoryCountLine__c> lines = [SELECT Id, InvCnt_Status__c, Why_Recount_Needed__c,
				Confirmed_Date__c, Confirmed_By__c, Recount_Requested_Date__c, Recount_Requested_By__c
			FROM FS_InventoryCountLine__c WHERE InventoryCount__c = :headerId];
		List<FS_InventoryCountLine__c> updates = new List<FS_InventoryCountLine__c>();
		for (FS_InventoryCountLine__c i : lines)
		{
			if (i.InvCnt_Status__c == 'Submitted')
			{
				i.InvCnt_Status__c = headerData.selectedReviewStatus;
				if (headerData.selectedReviewStatus == 'Confirmed') {
					i.Confirmed_Date__c = Datetime.now();
					i.Confirmed_By__c = UserInfo.getName();
				}
				else if (headerData.selectedReviewStatus == 'Recount') {
					i.Recount_Requested_Date__c = Datetime.now();
					i.Recount_Requested_By__c = UserInfo.getName();
					i.Why_Recount_Needed__c = headerData.selectedRejectReason;
				}
				updates.add(i);
			}
			else if (i.InvCnt_Status__c == 'Confirmed')
			{
				i.InvCnt_Status__c = headerData.selectedReviewStatus;
				if (headerData.selectedReviewStatus == 'Approved') {
					i.Approved_Date__c = Datetime.now();
					i.Approved_By__c = UserInfo.getName();
				}
				updates.add(i);
			}
		}

		String result=null;
		if (updates.isEmpty()) {
			result = 'No lines to update found for headers';
		} else {
			try {
				update updates;
				result= updates.size()+ ' records updated.';
			} catch (Exception e) {
				result= 'Error while trying to update lines: ' + e;
			}
		}

		System.debug('result '+result);
		return result;
	}
	
}