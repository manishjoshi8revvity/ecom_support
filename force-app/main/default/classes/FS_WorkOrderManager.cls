public with sharing class FS_WorkOrderManager {

	private FS_WorkOrderManager() {
	}

	public static void copyQuoteCurrencyDate(List<WorkOrder> woList, Map<Id, WorkOrder> oldMap)
	{
		Date today = Date.today();
		if (oldMap == null) // INSERT
		{
			for (WorkOrder wo : woList)
			{
				if(wo.Quote_Currency__c == null){
					// wo.SMAX_PS_Quote_Accepted_Date__c = today;
					wo.Quote_Currency__c = wo.CurrencyIsoCode;
				}else{
					// wo.SMAX_PS_Quote_Accepted_Date__c = today;
					wo.Quote_Currency__c = wo.Quote_Currency__c;
				}
			}
		}
		else // UPDATE
		{
			for (WorkOrder wo : woList)
			{
				WorkOrder old = (oldMap == null) ? null : oldMap.get(wo.Id);
				if (old != null && old.Quote_Currency__c == null && wo.Quote_Currency__c == null)
				{
					if(wo.Quote_Currency__c == null){
						// wo.SMAX_PS_Quote_Accepted_Date__c = today;
						wo.Quote_Currency__c = wo.CurrencyIsoCode;
					}else{
						// wo.SMAX_PS_Quote_Accepted_Date__c = today;
						wo.Quote_Currency__c = wo.Quote_Currency__c;
					}
				}
			}
		}
	}

	/**
	* Copy Related Lookups and fields when Work Orders are Created.
	* Should be called in the "before" trigger(s)
	* ADDED support for BEFORE UPDATE.. when the IP Lookup changes for SVMXCFG-682
	*/
	public static void copyRelatedData(List<WorkOrder> woNewList, Map<Id, WorkOrder> oldMap)
	{
		if (!FS_Utility.isActive('Work Order Copy Related Data', 'Copy Related Lookups and fields when Work Orders are Created.'))
			return;

		// SVMXINT-536 WO Load: Do not recalculate Customer Master lookups
		Boolean isIntegration = FS_Utility.isCurrentUserIntegrationProfile();

		// First pass.. IPs and Contacts
		Set<Id> ipIds = new Set<Id>();
		Set<Id> contactIds = new Set<Id>();
		Set<Id> acctIds = new Set<Id>();

		// ITSVMX-539 Also, get the OwnerId before it is changed for use later
		//Set<Id> createdByIds = new Set<Id>();

		for (WorkOrder wo : woNewList)
		{
			//createdByIds.add(wo.OwnerId); // ITSVMX-539

			WorkOrder old = (oldMap == null) ? null : oldMap.get(wo.Id);

			// ITSVMX-606: Changing Scheduled Duration field - Hopefully this won't be needed any longer
			// 7/22/21 Tony - Refactoring this from SMAX_PS_AutoAssignment.confirmScheduling() into SMAX_PS_WorkOrderManager.copyRelatedData()
			// as it is causing problems with ServiceMax managed package code
			// ITSVMX-801 Need to re-add this code to update the new SMAX_PS_Scheduled_Duration_Hours__c field when SVMXC__Service_Duration__c is updated
			if (old != null && wo.Duration != old.Duration)
			{
				Long seconds = wo.Duration.longValue();
				Long minutes = seconds / 60;
				Decimal hours = (minutes / 60.00).setScale(2);
//              wo.SVMXC__SM_Scheduled_Duration__c = hours;
				wo.Scheduled_Duration_Hours__c = hours;
			}

			if (old == null || old.AssetId != wo.AssetId)
			{

				if (old != null)
				{
					// SVMXCFG-682 Wipe out fields to make sure they get replaced from IP / Location..
					wo.LocationId = null;
					wo.AccountId = null;
					wo.SoldTo__c = null;
					wo.ShipTo__c = null;
					wo.BillTo__c = null;
					wo.Payer__c = null;
					wo.Local_Language_Bill_To_Account__c = null;
					wo.Local_Language_Ship_To_Account__c = null;
				}

				// SVMXINT-561 WO Basic Start Date - default to same vlaue
				/* if (wo.Scheduled_Date__c == null)
					 wo.Scheduled_Date__c = wo.Customer_Required_Start_Date__c;
				 if (wo.Scheduled_Date__c == null)
					 wo.Scheduled_Date__c = Date.today();*/
				if (wo.AssetId != null)
					ipIds.add(wo.AssetId);
				if (wo.ContactId != null)
					contactIds.add(wo.ContactId);
				if (wo.AccountId != null && isIntegration)
					acctIds.add(wo.AccountId);

				// SVMXINT-638 WO Local Language Cust Numbers
				if (wo.Local_Language_Bill_To_Account__c != null && isIntegration)
					acctIds.add(wo.Local_Language_Bill_To_Account__c);
				if (wo.Local_Language_Ship_To_Account__c != null && isIntegration)
					acctIds.add(wo.Local_Language_Ship_To_Account__c);

				// SVMXCFG-1057 Country without IP nor Location
				if (wo.AssetId == null && wo.LocationId == null && wo.AccountId != null)
					acctIds.add(wo.AccountId);
			}
		}
		//System.debug('createdByIds: ' + createdByIds);

		if (ipIds.isEmpty() && contactIds.isEmpty() && acctIds.isEmpty())
			return;

		Map<Id, Asset> ipMap = null;
		if (!ipIds.isEmpty())
		{
			// SVMXCFG-794 Copy Payer E-Invoice Fields to WO
			// ITSVMX-218 Copy the IP Geo-Codes to the WO
			// ITSVMX-290 - Added additional selection from Installed Product Classification for populating certain charactaristics on WO
			//ITSVMX-664 - Added new field SMAX_PS_ModelSeries_2__c in select statement
			ipMap = new Map<Id, Asset>([SELECT Id, Name, AccountId, ModelSeries__c, fxModelSeries__c,LocationId,
					Preferred_Technician__c, CatalogProfile__c, ModelNumber__c, fxIsMedicalDevice__c,
					Technical_ID_Number__c, ThirdPartyVendorName__c, Field_Notes__c,
					Product2Id, Product2.Super_Business_Unit__c, Product2.Product_Line__c,
					SoldTo_Account__c, ShipTo_Account__c, BillTo_Account__c, Payer_Account__c,
					SoldTo_Account__r.Address_Street_Line_1__c, SoldTo_Account__r.Address_City__c, SoldTo_Account__r.Address_State__c,
					SoldTo_Account__r.Address_Postal_Code__c, SoldTo_Account__r.Address_Country__c,
					System_ID__c, Asset_Tag__c, Equipment_ID__c,
					LL_BillTo_Account__c, LL_BillTo_Account__r.Name,
					LL_BillTo_Account__r.Address_Street_Line_1__c, LL_BillTo_Account__r.Address_City__c, LL_BillTo_Account__r.Address_State__c,
					LL_BillTo_Account__r.Address_Postal_Code__c, LL_BillTo_Account__r.Address_Country__c,
					LL_ShipTo_Account__c, LL_ShipTo_Account__r.Name,
					LL_ShipTo_Account__r.Address_Street_Line_1__c, LL_ShipTo_Account__r.Address_City__c, LL_ShipTo_Account__r.Address_State__c,
					LL_ShipTo_Account__r.Address_Postal_Code__c, LL_ShipTo_Account__r.Address_Country__c,
			( SELECT Id, Name, Asset__c, Characteristic__c,
					Description__c, Value__c FROM Asset_Classifications__r
			WHERE Characteristic__c = 'EQUIPMENT_CONTRACT_BASE_DATE' OR
			Characteristic__c = 'EQUIPMENT_SCHEDULING_RULE')
			FROM Asset WHERE Id IN :ipIds]);
		}

		Map<Id, Contact> contactMap = null;
		if (!contactIds.isEmpty())
		{
			contactMap = new Map<Id, Contact>([SELECT Id, Name, Phone, Email, MobilePhone
			FROM Contact WHERE Id IN :contactIds]);
		}

		Map<Id, Account> acctMap = new Map<Id, Account>();
		if (!acctIds.isEmpty())
		{
			acctMap = new Map<Id, Account>([SELECT Id, Name,
					ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry
			FROM Account WHERE Id IN :acctIds]);
		}

		// Load the Custom Setting for converting "Catalog Profile" to "Code Family"
		Map<String, String> profileFamilyMap = new Map<String, String>();
		for (C_SET_6850_CATALOG_PROFILE__c catProf : C_SET_6850_CATALOG_PROFILE__c.getall().values())
		{
			profileFamilyMap.put(catProf.Catalog_Profile__c, catProf.Code_Family__c);
		}

		// OBSOLETE Equipment Products for RMA/Loaner..
		Map<Id, Id> woProdMap = new Map<Id, Id>();

		// SVMXINT-516 : Use IP Customer Master Lookups first - SoldTo will be filled in SFM .. can't use basic null logic
		Map<Id, ERP_Address__C> woSoldToMap = new Map<Id, ERP_Address__C>();
		for (WorkOrder wo : woNewList)
		{
			if (wo.AssetId != null)
			{
				Asset ip = (ipMap == null) ? null : ipMap.get(wo.AssetId);
				if (ip != null)
				{
					// begin of ITSVMX-290 populate the classification data
					/*List<FS_AssetClassification__c> ipClassificationList = ip.Installed_Product_Classifications__r;
					for(FS_AssetClassification__c ipClassObj:ipClassificationList){
						system.debug('IP Classification Details:'+ipClassObj);
						if(ipClassObj.Characteristic__c == 'EQUIPMENT_CONTRACT_BASE_DATE'){
							wo.Previous_Requested_Date__c = ipClassObj.Value__c;
						}
						if(ipClassObj.Characteristic__c == 'EQUIPMENT_SCHEDULING_RULE'){
							wo.Scheduling_Date_Rule__c =  ipClassObj.Value__c;
						}

					}*/
					// end of ITSVMX-290 populate the classification data
					if (wo.AccountId == null) {
						wo.AccountId = ip.AccountId;
					}

					wo.Preferred_Technician__c = ip.Preferred_Technician__c;
					// ITSVMX-664 Replace with new model series field
					wo.ModelSeries__c = ip.fxModelSeries__c;
					wo.Model_Number__c = ip.ModelNumber__c;
					wo.IsMedicalDevice__c = ip.fxIsMedicalDevice__c;
					wo.Technical_ID_Number__c = ip.Technical_ID_Number__c;
					wo.Vendor__c = ip.ThirdPartyVendorName__c;

					//SVMXCFG-687 - Add Installed Product System ID to WO
					wo.System_ID__c = ip.System_ID__c;
					// SVMXCFG-763 - System ID, Equipment ID from IP
					wo.Asset_Tag__c = ip.Asset_Tag__c;
					wo.Equipment_ID__c = ip.Equipment_ID__c;

					// ITSVMX-218 Copy the IP Geo-Codes to the WO
					//wo.SVMXC__Longitude__c = ip.SVMXC__Longitude__c;
					//wo.SVMXC__Latitude__c = ip.SVMXC__Latitude__c;

					// Copy Location from IP if blank on WO
					if (wo.LocationId == null)
					{
						wo.LocationId = ip.LocationId;
					}
					// JIRA #395 - Fault Code Debrief
					if (ip.CatalogProfile__c != null)
					{
						wo.Fault_Code_Family__c = profileFamilyMap.get(ip.CatalogProfile__c);
					}
					// JIRA SVMXCFG-357 - Copy Super Business Unit from IP's Product
					if (ip.Product2Id != null)
					{
						if (wo.Product__c == null) {
							wo.Product__c = ip.Product2Id;
						}
						wo.Super_Business_Unit__c = ip.Product2.Super_Business_Unit__c;
						// SVMXCFG-1137 Copy the IP Product Line to the Work Order
						wo.Asset_Product_Line__c = ip.Product2.Product_Line__c;
						// OBSOLETE Equipment Products for RMA/Loaner..
						woProdMap.put(wo.Id, ip.Product2Id);
					}
					// SVMXCFG-610 - Notes fields from IP/Location
					wo.Field_Notes__c = ip.Field_Notes__c;
					System.debug('test: '+isIntegration+ ' '+ ip);
					if (!isIntegration)
					{
						// SVMXINT-516 : Use IP Customer Master Lookups first
						if (ip.SoldTo_Account__c != null)
						{
							woSoldToMap.put(wo.Id, ip.SoldTo_Account__r);
							wo.SoldTo__c = ip.SoldTo_Account__c;
						}
						if (ip.ShipTo_Account__c != null)
						{
							wo.ShipTo__c = ip.ShipTo_Account__c;
						}
						if (ip.BillTo_Account__c != null)
						{
							wo.BillTo__c = ip.BillTo_Account__c;
						}
						if (ip.Payer_Account__c != null)
						{
							wo.Payer__c = ip.Payer_Account__c;
							// SVMXCFG-794 Copy Payer E-Invoice Fields to WO
							// wo.EInvoice_Platform_Id__c = ip.Payer_Account__r.PKI_SAP_EInvoice_Platform_Id__c;
							//wo.EInvoice_Customer_Id__c = ip.Payer_Account__r.PKI_SAP_EInvoice_Customer_Id__c;
						}
						// SVMXCFG-903 Copy Local Language Accounts to WO
						if (ip.LL_BillTo_Account__c != null)
						{
							wo.Local_Language_Bill_To_Account__c = ip.LL_BillTo_Account__c;
							wo.LocalLanguageBillTo__c = ip.LL_BillTo_Account__r.Name;
							// SVMXCFG-993 Copy Local Lang address too
							wo.Local_Language_Bill_To_Street__c = ip.LL_BillTo_Account__r.Address_Street_Line_1__c;
							wo.Local_Lang_Bill_To_Addr_Long__c = ip.LL_BillTo_Account__r.Address_City__c
									+ ' ' + ip.LL_BillTo_Account__r.Address_State__c
									+ ' ' + ip.LL_BillTo_Account__r.Address_Postal_Code__c
									+ ' ' + ip.LL_BillTo_Account__r.Address_Country__c;
						}
						if (ip.LL_ShipTo_Account__c != null)
						{
							wo.Local_Language_Ship_To_Account__c = ip.LL_ShipTo_Account__c;
							wo.LocalLanguageShipTo__c = ip.LL_ShipTo_Account__r.Name;
							// SVMXCFG-993 Copy Local Lang address too
							wo.Local_Language_Ship_To_Street__c = ip.LL_ShipTo_Account__r.Address_Street_Line_1__c;
							wo.Local_Lang_Ship_To_Addr_Long__c = ip.LL_ShipTo_Account__r.Address_City__c
									+ ' ' + ip.LL_ShipTo_Account__r.Address_State__c
									+ ' ' + ip.LL_ShipTo_Account__r.Address_Postal_Code__c
									+ ' ' + ip.LL_ShipTo_Account__r.Address_Country__c;
						}
					}
				}
			}
			if (wo.ContactId != null)
			{
				Contact c = (contactMap == null) ? null : contactMap.get(wo.ContactId);
				if (c != null)
				{
					wo.Contact_Email__c = c.Email;
					wo.ContactName__c = c.Name;
					wo.Contact_Phone__c = c.Phone;
					// ITSVMX-542 Populate contact mobile number
					wo.Mobile_Number__c = c.MobilePhone;
				}
			}

			// SVMXINT-638 WO Local Language Cust Numbers
			if (wo.Local_Language_Bill_To_Account__c != null && isIntegration)
			{
				Account acct = acctMap.get(wo.Local_Language_Bill_To_Account__c);
				if (acct != null)
				{
					wo.LocalLanguageBillTo__c = acct.Name;
					// SVMXCFG-993 Copy Local Lang address too
					wo.Local_Language_Bill_To_Street__c = acct.ShippingStreet;
					wo.Local_Lang_Bill_To_Addr_Long__c = acct.ShippingCity
							+ ' ' + acct.ShippingState
							+ ' ' + acct.ShippingPostalCode
							+ ' ' + acct.ShippingCountry;

				}
			}
			if (wo.Local_Language_Ship_To_Account__c != null && isIntegration)
			{
				Account acct = acctMap.get(wo.Local_Language_Ship_To_Account__c);
				if (acct != null)
				{
					wo.LocalLanguageShipTo__c = acct.Name;
					// SVMXCFG-993 Copy Local Lang address too
					wo.Local_Language_Ship_To_Street__c = acct.ShippingStreet;
					wo.Local_Lang_Ship_To_Addr_Long__c = acct.ShippingCity
							+ ' ' + acct.ShippingState
							+ ' ' + acct.ShippingPostalCode
							+ ' ' + acct.ShippingCountry;
				}
			}

			// SVMXCFG-1057 Country without IP nor Location
			if (wo.AssetId == null && wo.LocationId == null && wo.AccountId != null)
			{
				Account acct = acctMap.get(wo.AccountId);
				if (acct != null)
				{
					//wo.Country = acct.ShippingCountry;
					wo.Account_Street__c = acct.ShippingStreet;
					wo.Account_City__c = acct.ShippingCity;
					wo.Account_State__c = acct.ShippingState;
					wo.Account_Zip_Code__c = acct.ShippingPostalCode;
					wo.Account_Country__c = acct.ShippingCountry;
				}
			}
		}

		// Second pass.. Locations (might have been filled in during first pass)
		Set<Id> locIds = new Set<Id>();
		for (WorkOrder wo : woNewList)
		{
			if (wo.LocationId != null)
				locIds.add(wo.LocationId);
		}

		Map<Id, Schema.Location> locMap = null;
		if (!locIds.isEmpty())
		{
			// 2018-03-16 MAPLES - Added the new fields for Payer address so we can map to WO and then use in creation of Parts Order
			// SVMXCFG-794 Copy Payer E-Invoice Fields to WO
			locMap = new Map<Id, Schema.Location>([SELECT Id, Name, LocationCode__c, Geography__r.Name,
					Account__c, BillTo__c, Payer__c, ShipTo__c, MaintenancePlant__c,
					SalesOrg__c, CurrencyIsoCode, Location_Notes__c,
					Account__r.ShippingStreet, Account__r.ShippingCity, Account__r.ShippingState,
					Account__r.ShippingPostalCode, Account__r.ShippingCountry,
					SoldTo__c, SoldTo__r.Address_Street_Line_1__c, SoldTo__r.Address_City__c, SoldTo__r.Address_State__c,
					SoldTo__r.Address_Postal_Code__c, SoldTo__r.Address_Country__c,
					Street__c, City__c, State__c, Country__c, Zip__c,LL_BillTo__c, LL_BillTo__r.Name,
					LL_BillTo__r.Address_Street_Line_1__c, LL_BillTo__r.Address_City__c, LL_BillTo__r.Address_State__c,
					LL_BillTo__r.Address_Postal_Code__c, LL_BillTo__r.Address_Country__c,
					LL_ShipTo__c, LL_ShipTo__r.Name,
					LL_ShipTo__r.Address_Street_Line_1__c, LL_ShipTo__r.Address_City__c, LL_ShipTo__r.Address_State__c,
					LL_ShipTo__r.Address_Postal_Code__c, LL_ShipTo__r.Address_Country__c,
					LKUP_Country__c, LKUP_Country__r.Country_ISO_Alpha_2__c, LKUP_Country__r.SFDC_Country_Name__c,
					LKUP_State__c, LKUP_State__r.SFDC_State_Name__c
				FROM Location WHERE Id IN:locIds]);
		}

		// OBSOLETE Equipment Products for RMA/Loaner..
		Map<Id, String> woPlantMap = new Map<Id, String>();
		// ITSVMX-253 Sales Orgs for each WO
		Map<Id, String> woSalesMap = new Map<Id, String>();

		Set<String> locExtIds = new Set<String>();
		for (WorkOrder wo : woNewList)
		{
			if (wo.LocationId != null)
			{
				Schema.Location loc = (locMap == null) ? null : locMap.get(wo.LocationId);
				if (loc != null)
				{
					if (!isIntegration)
					{
						if (wo.AccountId == null) {
							wo.AccountId = loc.Account__c;
						}
						// SVMXINT-516 : Use IP Customer Master Lookups first
						if (!woSoldToMap.containsKey(wo.Id))
						{
							woSoldToMap.put(wo.Id, loc.SoldTo__r);
						}
						if (wo.BillTo__c == null)
						{
							wo.BillTo__c = loc.BillTo__c;
						}
						if (wo.Payer__c == null)
						{
							wo.Payer__c = loc.Payer__c;
							// SVMXCFG-794 Copy Payer E-Invoice Fields to WO
							//wo.EInvoice_Platform_Id__c = loc.Payer__r.SAP_EInvoice_Platform_Id__c;
							//wo.EInvoice_Customer_Id__c = loc.Payer__r.SAP_EInvoice_Customer_Id__c;
						}
						if (wo.ShipTo__c == null)
						{
							wo.ShipTo__c = loc.ShipTo__c;
						}
						// SVMXCFG-903 Copy Local Language Accounts to WO
						if (wo.Local_Language_Bill_To_Account__c == null && loc.LL_BillTo__c != null)
						{
							wo.Local_Language_Bill_To_Account__c = loc.LL_BillTo__c;
							wo.LocalLanguageBillTo__c = loc.LL_BillTo__r.Name;
							// SVMXCFG-993 Copy Local Lang address too
							wo.Local_Language_Bill_To_Street__c = loc.LL_BillTo__r.Address_Street_Line_1__c;
							wo.Local_Lang_Bill_To_Addr_Long__c = loc.LL_BillTo__r.Address_City__c
									+ ' ' + loc.LL_BillTo__r.Address_State__c
									+ ' ' + loc.LL_BillTo__r.Address_Postal_Code__c
									+ ' ' + loc.LL_BillTo__r.Address_Country__c;
						}
						if (wo.Local_Language_Ship_To_Account__c == null && loc.LL_ShipTo__c != null)
						{
							wo.Local_Language_Ship_To_Account__c = loc.LL_ShipTo__c;
							wo.LocalLanguageShipTo__c = loc.LL_ShipTo__r.Name;
							// SVMXCFG-993 Copy Local Lang address too
							wo.Local_Language_Ship_To_Street__c = loc.LL_ShipTo__r.Address_Street_Line_1__c;
							wo.Local_Lang_Ship_To_Addr_Long__c = loc.LL_ShipTo__r.Address_City__c
									+ ' ' + loc.LL_ShipTo__r.Address_State__c
									+ ' ' + loc.LL_ShipTo__r.Address_Postal_Code__c
									+ ' ' + loc.LL_ShipTo__r.Address_Country__c;
						}
					}

					// 2018-03-16 MAPLES - added Address mapping for use on create of Parts Order **JIRA 392
					// 2018-05-09 Frank - Refactored for SVMXINT-516 and SVMXINT-536
					ERP_Address__c soldToAccount =  woSoldToMap.get(wo.Id);
					if (soldToAccount != null)
					{
						wo.Account_Street__c = soldToAccount.Address_Street_Line_1__c;
						wo.Account_City__c = soldToAccount.Address_City__c;
						wo.Account_State__c = soldToAccount.Address_State__c;
						wo.Account_Zip_Code__c = soldToAccount.Address_Postal_Code__c;
						wo.Account_Country__c = soldToAccount.Address_Country__c;
					}

					// SVMXCFG-329 - Copy Currency from Payer
					//if (loc.SMAX_PS_Payer__c != null) { wo.CurrencyIsoCode = loc.SMAX_PS_Payer__r.CurrencyIsoCode; }
					// SVMXINT-475 - Copy the Currency Code from the Functional Location instead
					wo.CurrencyIsoCode = loc.CurrencyIsoCode;
					wo.LocationCode__c = loc.LocationCode__c;
					wo.Geography__c = (loc.Geography__r != null) ? loc.Geography__r.Name : null;
					wo.ServiceTerritoryId = loc.Geography__c;
					wo.SalesOrg__c = loc.SalesOrg__c;
					woSalesMap.put(wo.Id, wo.SalesOrg__c);

					// SVMXCFG-483 - Blank "Service Location" on WO
					if (String.isBlank(wo.Street) || String.isBlank(wo.City) || String.isBlank(wo.PostalCode))
					{
						wo.Street = loc.Street__c;
						wo.City = loc.City__c;
						wo.PostalCode = loc.Zip__c;
					}
					if (loc.MaintenancePlant__c != null)
					{
						wo.ExpenseLocationNumber__c = loc.MaintenancePlant__c + 'F000';
						locExtIds.add(wo.ExpenseLocationNumber__c);
						woPlantMap.put(wo.Id, loc.MaintenancePlant__c);
					}
					// SVMXCFG-610 - Notes fields from IP/Location
					wo.Location_Notes__c = loc.Location_Notes__c;

					// Lookup the WO Country and State from the Country__c and State__c objects from Location
					if (loc.LKUP_Country__c != null) {
						wo.LKUP_Country__c = loc.LKUP_Country__c;
						wo.Country = loc.LKUP_Country__r.SFDC_Country_Name__c;
						wo.CountryCode = loc.LKUP_Country__r.Country_ISO_Alpha_2__c;
					}
					if (loc.LKUP_State__c != null) {
						wo.LKUP_State__c = loc.LKUP_State__c;
						wo.State = loc.LKUP_State__r.SFDC_State_Name__c;
					}
				}
			}
		}

		// OBSOLETE Equipment Products for RMA/Loaner..
		Set<String> plants = new Set<String>(woPlantMap.values());
		Set<Id> prodIds = new Set<Id>(woProdMap.values());

		if (!plants.isEmpty() && !prodIds.isEmpty())
		{
			List<FS_ProductPlant__c> allProductPlants = [SELECT Id, Name, Product__c, Plant__c,
					Return_Part__c, Return_Part_Number__c, Credit_Relevant_Part__c,
					Product__r.Partnum__c
			FROM FS_ProductPlant__c WHERE Product__c IN :prodIds AND Plant__c IN :plants];
			Map<String, FS_ProductPlant__c> ppMap = new Map<String, FS_ProductPlant__c>();
			for (FS_ProductPlant__c pp : allProductPlants)
			{
				String key = pp.Product__c + '-' + pp.Plant__c;
				ppMap.put(key, pp);
			}

			for (WorkOrder wo : woNewList)
			{
				Id productId = woProdMap.get(wo.Id);
				String plant = woPlantMap.get(wo.Id);

				String key = productId + '-' + plant;
				FS_ProductPlant__c pp = ppMap.get(key);
				if (pp != null)
				{
					wo.Equipment_Part_Return_Number__c = (pp.Return_Part_Number__c == null) ?
							pp.Product__r.Partnum__c : pp.Return_Part_Number__c;
				}
			}
		}

		// ITSVMX-253 Copy the "Item Category Group" to the WO from the Product Sales
		Set<String> salesOrgs = new Set<String>(woSalesMap.values());
		if (!salesOrgs.isEmpty() && !prodIds.isEmpty())
		{
			List<Product_Sales__c> allProductSales = [SELECT Id, Name, Product__c, Sales_Org__c,
					Item_Category_Group__c, Product__r.Partnum__c
			FROM Product_Sales__c WHERE Product__c IN :prodIds AND Sales_Org__c IN :salesOrgs];
			Map<String, Product_Sales__c> psMap = new Map<String, Product_Sales__c>();
			for (Product_Sales__c ps : allProductSales)
			{
				String key = ps.Product__c + '-' + ps.Sales_Org__c;
				psMap.put(key, ps);
			}

			for (WorkOrder wo : woNewList)
			{
				Id productId = woProdMap.get(wo.Id);
				String salesOrg = woSalesMap.get(wo.Id);

				String key = productId + '-' + salesOrg;
				Product_Sales__c ps = psMap.get(key);
				if (ps != null)
				{
					// Set Item Category
					wo.Item_Category_Group__c = ps.Item_Category_Group__c;
				}
			}
		}
	}

	// Added for [SVMXCFG-777] - Auto-Fill the Translation lookup based ont he WO Country
	// 10/19/20222 ITSVMX-1029 Polaris Translation / Output Documents
	public static void lookupTranslation(List<WorkOrder> woList, Map<Id, WorkOrder> oldMap)
	{
		if (!FS_Utility.isActive('Work Order Lookup Translation',
				'Lookup a Translation record based on the WO Country and Owned By Company.')) {
			return;
		}

		C_META_FS_Service_Document__mdt defaultFS = null;
		C_META_FS_Service_Document__mdt defaultEstimate = null;
		List<C_META_FS_Service_Document__mdt> allDocs = C_META_FS_Service_Document__mdt.getAll().values();
		for (C_META_FS_Service_Document__mdt doc : allDocs) {
			if (doc.Is_Default__c == true) {
				if (doc.Document_Type__c == 'Estimate') {
					defaultEstimate = doc;
				} else {
					defaultFS = doc;
				}
			}
		}

		List<WorkOrder> woToLookup = new List<WorkOrder>();
		Set<String> countryCodes = new Set<String>();
		List<WorkOrder> woToUpdate = new List<WorkOrder>();
		Set<Id> translationIds = new Set<Id>();
		for (WorkOrder wo : woList) {
			WorkOrder old = (oldMap == null) ? null : oldMap.get(wo.Id);
			if (wo.CountryCode != null &&
				(wo.Translation__c == null || (old != null && old.CountryCode != wo.CountryCode))) {
				woToLookup.add(wo);
				countryCodes.add(wo.CountryCode);
			} else if (wo.Translation__c != null && (wo.ServiceReportLanguage == null ||
					(old != null && wo.Translation__c != old.Translation__c))) {
				woToUpdate.add(wo);
				translationIds.add(wo.Translation__c);
			}

			// Auto-fill the "ServiceDocumentTemplate" from the "Is Default" by Record Type..
			/*if (wo.ServiceDocumentTemplate == null) {
				if (wo.Record_Type__c == 'Estimate' && defaultEstimate != null) {
					wo.ServiceDocumentTemplate = defaultEstimate.Service_Document_Id__c;
				} else if (wo.Record_Type__c != 'Estimate' && defaultFS != null) {
					wo.ServiceDocumentTemplate = defaultFS.Service_Document_Id__c;
				}
			}*/
		}

		if (!countryCodes.isEmpty() ) {
			Map<String, FS_Translation__c> translationMap = new Map<String, FS_Translation__c>();
			for (FS_Translation__c translation : [SELECT Id, Name, Country__c, Service_Report_Language__c
				FROM FS_Translation__c WHERE Country__c IN :countryCodes
				ORDER BY Is_Default__c DESC]) // ITSVMX-1337 Added ORDER BY to sort the TRUE values first
			{
				// ITSVMX-1337 Added "containsKey" to ensure the Defaults are not overwritten
				//String key = translation.Country__c + '-' + translation.SMAX_PS_Owned_By_Company__c;
				if (!translationMap.containsKey(translation.Country__c)) {
					translationMap.put(translation.Country__c, translation);
				}
			}

			for (WorkOrder wo : woToLookup)
			{
				//SMAX_PS_Translation__c translation = translationMap.get(wo.SVMXC__Country__c);
				FS_Translation__c translation = translationMap.get(wo.CountryCode);
				if (translation != null)
				{
					wo.Translation__c = translation.Id;
					wo.ServiceReportLanguage = translation.Service_Report_Language__c;
					System.debug('LANGUAGE ASSIGNED: ' + wo.ServiceReportLanguage);
				}
			}
		}

		if (!translationIds.isEmpty() ) {
			Map<Id, FS_Translation__c> translationMap = new Map<Id, FS_Translation__c>([SELECT Id, Name, Country__c,
				Service_Report_Language__c FROM FS_Translation__c WHERE Id IN :translationIds]);
			for (WorkOrder wo : woToUpdate)
			{
				//SMAX_PS_Translation__c translation = translationMap.get(wo.SVMXC__Country__c);
				FS_Translation__c translation = translationMap.get(wo.Translation__c);
				if (translation != null)
				{
					wo.ServiceReportLanguage = translation.Service_Report_Language__c;
				}
			}
		}
	}

	/**
	*  Work Orders must have a Location, Product or Installed Product.
	*  Should be called in the "before" trigger(s)
	*/
	public static void preventInvalidWorkOrders(List<WorkOrder> woNewList)
	{
		if (!FS_Utility.isActive('Work Order Prevent Invalid', 'Work Orders must have a Location, Product or Installed Product.'))
			return;

		//RecordType fsRecType = FS_Utility.getRecordType('WorkOrder', 'Field_Service');

		// JIRA #385 - Prevent Invalid WO
		for (WorkOrder wo : woNewList)
		{
			if (wo.AssetId == null && wo.LocationId == null && wo.Product__c == null
					&& (wo.Record_Type__c == 'Field Service'))
			{
				// If all 3 of these are blank, this is an invalid WO.. add an error
				wo.addError('Work Orders must have a Location, Product or Installed Product.');
			}
		}
	}


	/**
	* Use the AutoFieldMapping Custom Metadata Type to map fields.
	* Should be called in the "before" trigger(s)
	*/
	public static void updateMappedValues(List<WorkOrder> woList, Map<Id, WorkOrder> oldMap)
	{
		if (!FS_Utility.isActive('Work Order Update Mapped Values', 'Use the AutoFieldMapping Custom Metadata Type to map fields.')) {
			return;
		}

		Profile prof = FS_Utility.getCurrentUserProfile();
		if (oldMap == null && prof != null && prof.Name.containsIgnoreCase('Integration'))
		{
			// If created by Integration.. reverse map the values.
			FS_Utility.updateMappedValues('WorkOrder', woList, oldMap, true);
		}
		else
		{
			FS_Utility.updateMappedValues('WorkOrder', woList, oldMap, false);
		}
	}

	/**
	 * Create Work Order Platform Events when Work Orders are Created.
	 * Should be called in the "after" trigger(s)
	 */
	public static void createWorkOrderEvents(List<WorkOrder> woNewList, Map<Id, WorkOrder> woOldMap)
	{
		if (!FS_Utility.isActive('Work Order Create Events', 'Create Work Order Platform Events when Work Orders are Created.')) {
			return;
		}

		List<FS_WorkOrder_Event__e> events = new List<FS_WorkOrder_Event__e>();
		System.debug('woNewList->'+woNewList);

		if (!woNewList.isEmpty()){

			Boolean isIntegrationUser = FS_Utility.isCurrentUserIntegrationProfile();
			for (WorkOrder workOrder : woNewList)
			{
				Boolean existsSAP = String.isNotEmpty(workOrder.External_ID__c);
				WorkOrder old = (woOldMap == null) ? null : woOldMap.get(workOrder.Id);
				FS_WorkOrder_Event__e iEvent = new FS_WorkOrder_Event__e();
				// ITSVMX-231 Added SettlementReceiver to CREATE logic
				if ((!existsSAP) && workOrder.Status == 'Initializing'
						&& (old == null || old.Status != workOrder.Status
						|| old.SettlementReciever__c != workOrder.SettlementReciever__c))
				{
					iEvent.Action__c = 'CREATE';
					iEvent.WorkOrderId__c = workOrder.Id;
					events.add(iEvent);
				}
				else if (existsSAP && old != null
						&& ((workOrder.Status == 'DMR Released' && workOrder.Status != old.Status)
						|| (workOrder.SAP_SystemStatus__c == 'TECO' && workOrder.SAP_SystemStatus__c != old.SAP_SystemStatus__c)) )
				{
					// SVMXINT-499 - Re-Order WO Event Logic - Moved this BEFORE the update below
					if (isBillable(workOrder))
					{
						iEvent.Action__c = 'BILLING REQUEST';
						iEvent.WorkOrderId__c = workOrder.Id;
						events.add(iEvent);
					}
					else
					{
						// No other action needed..
					}
				}
				else if ( existsSAP && old != null
						&& (old.Scheduled_Date_Time__c != workOrder.Scheduled_Date_Time__c ||
						old.ServiceContractId != workOrder.ServiceContractId ||
						old.ContractItem__c != workOrder.ContractItem__c ||
						old.SettlementReciever__c != workOrder.SettlementReciever__c ||
						old.HSI1_Answer__c != workOrder.HSI1_Answer__c ||
						old.HSI2_Answer__c != workOrder.HSI2_Answer__c ||
						old.HSI3_Answer__c != workOrder.HSI3_Answer__c ||
						old.Priority != workOrder.Priority ||
						old.ContactId != workOrder.ContactId ||
						old.CustomerPO__c != workOrder.CustomerPO__c ||
						old.SAP_Activity_Status__c != workOrder.SAP_Activity_Status__c ||
						old.SAP_Order_Status__c != workOrder.SAP_Order_Status__c ||
						old.Problem_Summary__c != workOrder.Problem_Summary__c ||
						old.Description != workOrder.Description ||
						old.Internal_Notes__c != workOrder.Internal_Notes__c ||
						old.Internal_Description__c != workOrder.Internal_Description__c ||
						old.Q1_Response__c != workOrder.Q1_Response__c ||
						old.Q2_Response__c != workOrder.Q2_Response__c ||
						old.Q3_Response__c != workOrder.Q3_Response__c ||
						old.Q4_Response__c != workOrder.Q4_Response__c ||
						old.Q5_Response__c != workOrder.Q5_Response__c ||
						old.Customer_Order_Id__c != workOrder.Customer_Order_Id__c ||
						old.Customer_Required_Start_Date__c != workOrder.Customer_Required_Start_Date__c ||
						old.AccountId != workOrder.AccountId ||
						old.BillTo__c != workOrder.BillTo__c ||
						old.Payer__c != workOrder.Payer__c ||
						old.ShipTo__c != workOrder.ShipTo__c ||
						old.Local_Language_Bill_To_Account__c != workOrder.Local_Language_Bill_To_Account__c ||
						old.Local_Language_Ship_To_Account__c != workOrder.Local_Language_Ship_To_Account__c ||
						old.WorkTypeId != workOrder.WorkTypeId ||
						old.Billing_Type__c != workOrder.Billing_Type__c ||
						old.Override_Malfunction_Start_Date__c != workOrder.Override_Malfunction_Start_Date__c ||
						old.LocationId != workOrder.LocationId ||
						old.Quote_Number__c != workOrder.Quote_Number__c ||
						old.Quote_Accepted_Date__c != workOrder.Quote_Accepted_Date__c ||
						old.Customer_PO_Billable__c != workOrder.Customer_PO_Billable__c)
				)
				{
					// SVMXINT-589 Added Account Lookup fields (above)
					// SVMXINT-615 Added the Order / Billing Types (above)
					// SVMXCFG-896 Added Override Malfunction Start Date (above)
					// SVMXCFG-903 Added Local Language BillTo and ShipTo lookups (above)
					//ITSVMX-665   Added update funcational location at WO level
					//ITSVMX-534   Enterprise Quote fields
					iEvent.Action__c = 'UPDATE';
					iEvent.WorkOrderId__c = workOrder.Id;
					events.add(iEvent);
				}
				else if ( existsSAP && old != null && (
						old.Q1_Answer__c != workOrder.Q1_Answer__c ||
								old.Q2_Answer__c != workOrder.Q2_Answer__c ||
								old.Q3_Answer__c != workOrder.Q3_Answer__c ||
								old.Q4_Answer__c != workOrder.Q4_Answer__c ||
								old.Q5_Answer__c != workOrder.Q5_Answer__c))
				{
					// SVMXINT-651 When the "Guidance" (aka "Additional Info") Answers change, send new event
					iEvent.Action__c = 'GUIDANCE';
					iEvent.WorkOrderId__c = workOrder.Id;
					events.add(iEvent);
				}
				else if (existsSAP && old != null
						&& isIntegrationUser && workOrder.CreatedById == UserInfo.getUserId()
						&& old.SAP_SystemStatus__c == null && workOrder.SAP_SystemStatus__c != null)
				{
					// SVMXINT-605 End of WO Load, send UPDATE even if above logic didnt fire
					iEvent.Action__c = 'UPDATE';
					iEvent.WorkOrderId__c = workOrder.Id;
					events.add(iEvent);
				}
			}
			System.debug('Events->'+events);
		}

		sendWorkOrderEvents(events);
	}

	// JIRA #387 - Dispatch Console - Duplicate WO Platform Events
	private static Set<Id> WO_EVENT_IDS = new Set<Id>();
	// SVMXCFG-648 Changing to public so we can reuse from Debrief Manager
	public static void sendWorkOrderEvents(List<FS_WorkOrder_Event__e> events)
	{
		List<FS_WorkOrder_Event__e> filteredEvents = new List<FS_WorkOrder_Event__e>();
		for (FS_WorkOrder_Event__e evt : events)
		{
			if (!WO_EVENT_IDS.contains(evt.WorkOrderId__c))
			{
				filteredEvents.add(evt);
				// Hold on to WO Ids to make sure only 1 Event sent for each
				WO_EVENT_IDS.add(evt.WorkOrderId__c);
			}
		}

		FS_PlatformEventUtility.publishEvents(filteredEvents, 'WorkOrderId__c', 'Action__c');
	}

	// JIRA #390 - Don't send Billing Request if Total = $0
	public static Boolean isBillable(WorkOrder wo)
	{
		return wo.Is_Billable__c == true &&
			(wo.Total_Line_Price_w_Contract_Discounts__c > 0.00 || wo.Total_Calculated_Amount__c > 0.00);
//				(wo.Total_List_Price__c > 0.00 || wo.Total_Calculated_Amount__c > 0.00);
	}

	/**
	 * Update the WO TechnicianSalesOrg field from the Tech Storage Location.
	 * Should be called in the "before" trigger(s)
	 */
	public static void forceWorkOrderEvents(List<WorkOrder> woNewList)
	{
		if (!FS_Utility.isActive('Work Order Force Events', 'Create Work Order Platform Events when Work Orders are Created.')) {
			return;
		}

		List<FS_WorkOrder_Event__e> events = new List<FS_WorkOrder_Event__e>();

		Datetime twoMinAgo = Datetime.now().addMinutes(-2);
		if (Test.isRunningTest()) {
			twoMinAgo = Datetime.now();
		}
		for (WorkOrder workOrder : woNewList)
		{
			if (workOrder.ForceIntegration__c == false) {
				continue;
			}

			System.debug('FORCE WO Event for WO->'+workOrder);
            System.debug('twoMinAgo->'+twoMinAgo);
			Datetime lastForceDate = (workOrder.LastForceIntegration__c == null)
					? workOrder.CreatedDate : workOrder.LastForceIntegration__c;
             System.debug('lastForceDate->'+lastForceDate);
			if (lastForceDate < twoMinAgo)
			{
				Boolean existsSAP = String.isNotEmpty(workOrder.External_ID__c);
				FS_WorkOrder_Event__e iEvent = new FS_WorkOrder_Event__e();
				if (!existsSAP)
				{
					iEvent.Action__c = 'CREATE';
					iEvent.WorkOrderId__c = workOrder.Id;
					events.add(iEvent);
				}
				else if (existsSAP && workOrder.SAP_SystemStatus__c != 'TECO')
				{
					iEvent.Action__c = 'UPDATE';
					iEvent.WorkOrderId__c = workOrder.Id;
					events.add(iEvent);
				}
				else if (existsSAP && workOrder.SAP_SystemStatus__c == 'TECO')
				{
					iEvent.Action__c = 'BILLING REQUEST';
					iEvent.WorkOrderId__c = workOrder.Id;
					events.add(iEvent);
				}
				workOrder.LastForceIntegration__c = Datetime.now();
			}
			workOrder.ForceIntegration__c = false;
		}
		System.debug('FORCED WO Events->'+events);

		sendWorkOrderEvents(events);
	}

	/**
	 *  SVMXINT-502: Create Int Errors to detect duplicate processing
	 *  Should be called from WO After Update trigger
	 */
	public static void logDuplicateErrors(List<WorkOrder> woList, Map<Id, WorkOrder> oldMap)
	{
		if (!FS_Utility.isActive('Work Order Dulicate Errors', 'Create Integration Errors when SAP Confirmation Numbers are changed.')) {
			return;
		}

		List<FS_IntegrationError__c> errorList = new List<FS_IntegrationError__c>();
		for (WorkOrder wo : woList)
		{
			WorkOrder old = (oldMap == null) ? null : oldMap.get(wo.Id);
			if (old == null) {
				continue;
			}

			if (old.External_ID__c != null && wo.External_ID__c != old.External_ID__c)
			{
				FS_IntegrationError__c ie = new FS_IntegrationError__c();
				ie.RelatedElementType__c = 'WorkOrderId';
				ie.RelatedElementIdentifier__c = wo.Id;
				ie.ErrorMessage__c = 'DUPLICATE PROCESSING: Work Order posted as multiple SAP Service Order Numbers: '
						+ old.External_ID__c + ', ' + wo.External_ID__c;
				errorList.add(ie);
			}
			if (old.SAP_Notification_ID__c != null && wo.SAP_Notification_ID__c != old.SAP_Notification_ID__c)
			{
				FS_IntegrationError__c ie = new FS_IntegrationError__c();
				ie.RelatedElementType__c = 'WorkOrderId';
				ie.RelatedElementIdentifier__c = wo.Id;
				ie.ErrorMessage__c = 'DUPLICATE PROCESSING: Work Order posted as multiple SAP Notification Numbers: '
						+ old.SAP_Notification_ID__c + ', ' + wo.SAP_Notification_ID__c;
				errorList.add(ie);
			}
		}

		if (!errorList.isEmpty()) {
			insert errorList;
		}
	}

	// 2022-04-05 Tony ITSVMX-562 Modify the replenishment parts ordering process
	// NOTE: Should be called on before insert and before update
	public static void refurbishedPartsAllowed(List<WorkOrder> woList, Map<Id, WorkOrder> oldMap)
	{
		if (!FS_Utility.isActive('Work Order Refurbished Parts Allowed', 'If Refurbished Parts are allowed then set the checkbox fields.'))
			return;

		System.debug('Entering SMAX_PS_WorkOrderManager.refurbishedPartsAllowed');

		Set<Id> refurbishIpIds = new Set<Id>();
		Set<Id> allServiceContractIds = new Set<Id>();
		Set<Id> contractEntitlementIds = new Set<Id>();
		List<WorkOrder> refurbishWorkOrders = new List<WorkOrder>();

		// Get the list of work orders that might qualify for Refurbished Parts
		for (WorkOrder wo :woList) {
			WorkOrder old = (oldMap == null) ? null : oldMap.get(wo.Id);

			System.debug('wo.SMAX_PS_ContractItem__c: ' + wo.ContractItem__c);

			if (wo.Refurbished_Parts_Allowed__c == false
					&& ((old == null && wo.Assetid != null && wo.Billing_Type__c == 'Internal')
					|| (old == null && wo.Assetid != null && wo.Billing_Type__c != 'Internal' && wo.ContractItem__c != null)
					|| (old != null && (wo.Assetid != old.Assetid || wo.Billing_Type__c != old.Billing_Type__c || wo.ContractItem__c != old.ContractItem__c)))) {

				System.debug('Found a Work Order that might qualify to use Refurbished Parts: ' + wo);
				refurbishWorkOrders.add(wo);
				refurbishIpIds.add(wo.Assetid);
				allServiceContractIds.add(wo.ContractItem__c);
				contractEntitlementIds.add(wo.ContractEntitlement__c);
			}
		}
		System.debug('allServiceContractIds: ' + allServiceContractIds.size() + ' ' + allServiceContractIds);

		if (refurbishWorkOrders.isEmpty()) return;

		// Get the Service Contract Start and End Dates
		List<ServiceContract> activeServiceContracts = [
				SELECT Id, StartDate, EndDate
				FROM ServiceContract
				WHERE Id IN: allServiceContractIds
				AND StartDate <= :Date.today()
				AND EndDate >= :Date.today()
		];
		System.debug('activeServiceContracts: ' + activeServiceContracts.size() + ' ' + activeServiceContracts);

		// Get a list of active Service Contract Ids
		Set<Id> activeServiceContractIds = new Set<Id>();
		for (ServiceContract activeServiceContract :activeServiceContracts) {

			activeServiceContractIds.add(activeServiceContract.Id);
		}
		System.debug('activeServiceContractIds: ' + activeServiceContractIds.size() + ' ' + activeServiceContractIds);

		// Get Installed Products with their Medical Device checkbox
		List<Asset> installedProductMedDeviceList = [
				SELECT Id, fxIsMedicalDevice__c
				FROM Asset
				WHERE Id IN :refurbishIpIds
		];

		// Create Installed Product Id to Medical Device mapping
		Map<Id, Boolean> IpIdToMedDeviceMap = new Map<Id, Boolean>();
		for (Asset ip :installedProductMedDeviceList) {
			IpIdToMedDeviceMap.put(ip.Id, ip.fxIsMedicalDevice__c);
		}

		// Get the Service Contract services Parts Discount Covered
		List<Entitlement> serviceContractServicesList = [
				SELECT Id, ServiceContractId, Parts_Discount_Covered__c, ServicePartsDiscountCovered__c
				FROM Entitlement
				WHERE ServiceContractID IN :activeServiceContractIds
//              AND SVMXC__Parts_Discount_Covered__c = 100.00 //TODO Which one should we use?
				AND ServicePartsDiscountCovered__c = 100.00
				AND Id IN :contractEntitlementIds
		];
		System.debug('serviceContractServicesList: ' + serviceContractServicesList.size() + ' ' + serviceContractServicesList);

		// Create the Contract Entitlement Id to Service Parts Discount Covered mapping
		Map<Id, Decimal> contractEntitlementIdToPartsDiscountMap = new Map<Id, Decimal>();
		for (Entitlement serviceContractServices :serviceContractServicesList) {
			contractEntitlementIdToPartsDiscountMap.put(serviceContractServices.Id, serviceContractServices.ServicePartsDiscountCovered__c);
		}

		// Update work orders that qualify to use refurbished parts
		for (WorkOrder wo :refurbishWorkOrders) {

			System.debug('wo.SVMXC__Component__c: ' + wo.Assetid);
			System.debug('contractEntitlementIdToPartsDiscountMap: ' + contractEntitlementIdToPartsDiscountMap.get(wo.ContractEntitlement__c));

			if (IpIdToMedDeviceMap.get(wo.Assetid) == false
					&& (wo.Billing_Type__c == 'Internal' || contractEntitlementIdToPartsDiscountMap.get(wo.ContractEntitlement__c) == 100.00)) {

				wo.Refurbished_Parts_Allowed__c = true;
				wo.Use_Refurbished_Parts__c = true;
				System.debug('Updated BD_Refurbished_Parts_Allowed__c and BD_Use_Refurbished_Parts__c to TRUE');
			}
		}
		System.debug('refurbishWorkOrders after updates: ' + refurbishWorkOrders.size() + ' ' + refurbishWorkOrders);

		System.debug('Exiting SMAX_PS_WorkOrderManager.refurbishedPartsAllowed');
	}

	private static Set<String> PRE_OPEN_STATUS = new Set<String> { 'Initializing', 'On Hold - Cost', 'On Hold - Credit' };
	private static Set<String> NON_DISPATCH_STATUS = new Set<String> { 'Ready for Review', 'Closed', 'Canceled',
			'Technician Enroute', 'Technician Onsite', 'Ready to Invoice', 'Work Complete', 'Work Complete - Error',
			'DMR Rejected', 'DMR Released', 'Approved', 'HSI', 'Estimate Approved', 'Estimate Rejected', 'Invoiced', 'Submit WO for Approval' };

	public static void updateRollups(List<WorkOrder> woList, Map<Id, WorkOrder> oldMap)
	{
		if (!FS_Utility.isActive('Work Order Rollups', 'Update the WO header with child counts / details'))
			return;

		Map<Id, WorkOrder> woDetails = new Map<Id, WorkOrder>([SELECT Id,
				//(SELECT Id, Name, BD_Eligible_for_Return__c FROM SVMXC__Service_Order_Line__r WHERE BD_Eligible_for_Return__c = TRUE)
			(SELECT Id, Name, Covered_Until__c FROM Extended_Warranty_Coverages__r
				WHERE Covered_Until__c > TODAY AND Warranty_Work_Order__c = NULL)
			FROM WorkOrder WHERE Id IN :woList]);

		for (WorkOrder wo : woList)
		{
			// Number of Extended Warranty Parts
			WorkOrder woDetail = woDetails.get(wo.Id);
			Integer numEWP = (woDetail == null || woDetail.Extended_Warranty_Coverages__r == null)
					? 0 : woDetail.Extended_Warranty_Coverages__r.size();
			wo.Number_of_Extended_Warranty_Parts__c = numEWP;
		}
	}

	/**
	* Based on updates from SAP, auto-update the WO Order Status.
	* Should be called in the "before" trigger(s)
	*/
	public static void updateWorkOrderStatus(List<WorkOrder> woNewList, Map<Id, WorkOrder> woOldMap)
	{
		if (!FS_Utility.isActive('Work Order Update Status', 'Based on updates from SAP, auto-update the WO Order Status.'))
			return;

		//RecordType depotRT = SMAX_PS_Utility.getRecordType('WorkOrder', 'Depot_Repair');
		List<Id> tecoWoIds = new List<Id>();
		if (!woNewList.isEmpty()) {
			for (WorkOrder workOrder : woNewList)
			{
				//System.debug('!! ' + workOrder.Name + ' DISPATCH STATUS = ' + workOrder.Dispatch_Status__c);
				WorkOrder old = (woOldMap == null) ? null : woOldMap.get(workOrder.id);

				if (old != null
						&& workOrder.Status != old.Status
						&& workOrder.Status == 'Initializing'
						&& workOrder.SAP_SystemStatus__c != null)
				{
					// Don't allow WO to go back to Initializing if they already have a SAP System Status
					workOrder.Status = old.Status;
				}

				//ITSVMX-674 Store the old value of Order type to Original Order type field
				if (old != null && workorder.Order_Type__c != old.Order_Type__c && workorder.Original_Work_Order_Order_Type__c == null){
					workorder.Original_Work_Order_Order_Type__c = old.Order_Type__c;}
				if (old!=null && workorder.Record_Type__c != old.Record_Type__c && workorder.Original_Work_Order_Type__c == null){
					workorder.Original_Work_Order_Type__c = old.Record_Type__c;}


				if ( old != null && (old.CreditHold__c != workOrder.CreditHold__c
						|| old.SAP_SystemStatus__c != workOrder.SAP_SystemStatus__c) )
				{
					// SVMXCFG-409 - Only Update Order Status if NOT past "Open" status
					if (PRE_OPEN_STATUS.contains(workOrder.Status))
					{
						if (workOrder.SAP_SystemStatus__c == 'CRTD')
							workOrder.Status = 'On Hold - Cost';
						if (workOrder.SAP_SystemStatus__c == 'REL' && workOrder.CreditHold__c == true)
							workOrder.Status = 'On Hold - Credit';
						if (workOrder.SAP_SystemStatus__c == 'REL' && workOrder.CreditHold__c == false)
						{
							workOrder.Status = 'Open';
							// SVMXCFG-682 - If Tech already populated, change to 'Assigned' instead
//							if (workOrder.fxPrimary_Tech_Check__c == null)
//							{
//								workOrder.Status = 'Open';
//							}
//							else
//							{
//								workOrder.Status = 'Assigned';
//							}
						}
					}
					if (workOrder.SAP_SystemStatus__c == 'TECO')
					{
						tecoWoIds.add(workOrder.Id);
					}
					if (workOrder.SAP_SystemStatus__c == 'CLSD' && workOrder.Status != 'Canceled')
					{
						workOrder.Status = 'Closed';
					}
				}
				else if (old != null && (old.DMR_Number__c != workOrder.DMR_Number__c))
				{
					workOrder.Status = 'Ready for Review';
				}
				// RE-FACTORED WF Rule: SVMX_PS - Set WO to Assigned
//              else if (old != null && old.SVMXC__Dispatch_Status__c != workOrder.SVMXC__Dispatch_Status__c
//                      && workOrder.SVMXC__Dispatch_Status__c == 'Assigned'
//                      && (!NON_DISPATCH_STATUS.contains(workOrder.Status)))
				// ITSVMX-117 Updated to detect changes to the Technician lookup instead
				else if (old != null && workOrder.fxPrimary_Tech_Check__c != null
						&& old.fxPrimary_Tech_Check__c != workOrder.fxPrimary_Tech_Check__c
						&& (!NON_DISPATCH_STATUS.contains(workOrder.Status)))
				{
					// SVMXCFG-932 - Allow Assignment while "On-Hold - XXX", but do not change to "Assigned"
					if (workOrder.SAP_SystemStatus__c == 'CRTD' || workOrder.CreditHold__c == true)
					{
						// No action.. do not move to "Assigned"
					}
					else if (workOrder.SAP_SystemStatus__c == null && workOrder.Record_Type__c == 'Depot')
					{
						// No action... to not move to "Assigned"
					}
					// 2020-01-28 commented out if clause to make sure estimates change to 'Assigned'
					else //if (workOrder.SMAX_PS_SAP_SystemStatus__c != null)
					{
						//workOrder.Status = 'Assigned';
					}
				}
				// ITSVMX-134 tony - Updated to detect changes to Scheduled Date Time when status = Technician Rejected
				// and set the Order Status back to Assigned
				else if (old != null /*&& workOrder.SVMXC__Group_Member__c != null*/
						&& workOrder.Status == 'Technician Rejected'
						&& old.Scheduled_Date_Time__c != workOrder.Scheduled_Date_Time__c)
				{
					//workOrder.Status = 'Assigned';
				}
			}
		}

		if (!tecoWoIds.isEmpty())
		{
			if (!FS_Utility.isActive('Update IP Last WO Details', 'Update the Last Work Order Details field on the IP when WO Status changes to Work Complete.'))
				return;

			updateInstalledProductDetails(tecoWoIds);
		}
	}

	public static void updateInstalledProductDetails(List<Id> woIds)
	{
		List<WorkOrder> woList = [SELECT Id,WorkOrderNumber, AssetId, /*SVMXC__Group_Member__r.Name,*/ Order_Type__c, Completed_Date_Time__c
		FROM WorkOrder WHERE Id IN :woIds];
		Map<Id, Asset> ipMap = new Map<Id, Asset>();
		for (WorkOrder wo : woList)
		{
			if (wo.Assetid != null)
			{
				Asset ip = new Asset();
				ip.Id = wo.Assetid;
				ip.Last_Work_Order_Details__c = wo.WorkOrderNumber + ', '
						/*+ wo.SVMXC__Group_Member__r.Name + ', '*/
						+ wo.Order_Type__c + ', '
						+ wo.Completed_Date_Time__c;
				if (ip.Last_Work_Order_Details__c.length() > 255)
					ip.Last_Work_Order_Details__c = ip.Last_Work_Order_Details__c.substring(0, 252) + '...';
				ipMap.put(ip.Id, ip);
			}
		}
		if (!ipMap.isEmpty())
			update ipMap.values();
	}

	/**
	 * Should be called from before insert/update triggers
	 * Attempts to fill in the SAP_Contact_Number__c from the ContactId & SoldTo__c join
	 * @param woNewList updated Work Orders
	 * @param woOldMap previous Work Orders
	 */
	public static void updateContactRelationship(List<WorkOrder> woNewList, Map<Id, WorkOrder> woOldMap) {
		Set<Id> contactIds = new Set<Id>();
		Set<Id> soldToIds = new Set<Id>();
		List<WorkOrder> contactWorkOrders = new List<WorkOrder>();
		for (WorkOrder wo : woNewList) {
			WorkOrder old = (woOldMap == null) ? null : woOldMap.get(wo.Id);
			if (wo.ContactId != null && wo.SoldTo__c != null
					&& (wo.SAP_Contact_Number__c == null || (old != null && wo.ContactId != old.ContactId)))
			{
				contactIds.add(wo.ContactId);
				soldToIds.add(wo.SoldTo__c);
				contactWorkOrders.add(wo);
			}
		}

		if (!contactWorkOrders.isEmpty()) {
			Map<String, ERP_Relationship__c> contactRelMap = FS_AccountManager.findContactRelationships(contactIds, soldToIds);
			System.debug('FOUND CONTACT RELATIONSHIPS: ' + contactRelMap);
			for (WorkOrder wo : contactWorkOrders) {
				String key = wo.ContactId; // + '_' + wo.SoldTo__c;
				ERP_Relationship__c contactRel = contactRelMap.get(key);
				System.debug('CONTACT KEY: ' + key + ' -- RESULT: ' + contactRel);
				if (contactRel != null) {
					wo.SAP_Contact_Number__c = contactRel.ERP_Contact_ID__c;
				}
			}
		}
	}

	public static void assignToDepotQueue(List<WorkOrder> woList, Map<Id, WorkOrder> oldMap) {
		if (!FS_Utility.isActive('WO Assign Depot Queue', 'Assign the WO to a Depot Queue based on Depot Plant.')) {
			return;
		}

		Set<Id> depotPlantIds = new Set<Id>();
		List<WorkOrder> depotWOList = new List<WorkOrder>();
		for (WorkOrder wo : woList) {
			WorkOrder old = (oldMap == null) ? null : oldMap.get(wo.Id);
			if (wo.Record_Type__c == 'Depot' && wo.Depot_Plant__c != null
					&& (old == null || wo.Depot_Plant__c != old.Depot_Plant__c)) {
				depotPlantIds.add(wo.Depot_Plant__c);
				depotWOList.add(wo);
			}
		}

		if (depotPlantIds.isEmpty()) {
			return;
		}

		Map<Id, FS_DepotPlant__c> depotPlantMap = new Map<Id, FS_DepotPlant__c>([SELECT Id, Name,
				Depot_Location__c, Depot_Location__r.Depot_Work_Center__c, Depot_Location__r.Depot_Queue_Id__c
		FROM FS_DepotPlant__c WHERE Id IN :depotPlantIds]);
		for (WorkOrder wo: depotWOList) {
			// ITSFDC-509 If assigned to a "Depot Plant", update Owner & WorkCenter
			FS_DepotPlant__c depot = depotPlantMap.get(wo.Depot_Plant__c);
			if (depot.Depot_Location__c != null && depot.Depot_Location__r.Depot_Queue_Id__c != null) {
				wo.OwnerId = depot.Depot_Location__r.Depot_Queue_Id__c;
			}
			if (depot.Depot_Location__c != null && depot.Depot_Location__r.Depot_Work_Center__c != null) {
				wo.SAP_Work_Center__c = depot.Depot_Location__r.Depot_Work_Center__c;
			}
		}
	}

	public static Map<Id, ServiceResource> lookupAssignedResources(Set<Id> woIds) {
		Map<Id, ServiceResource> results = new Map<Id, ServiceResource>();
		List<ServiceAppointment> appts = [SELECT Id, ParentRecordId, Assigned_Resource__c,
				Assigned_Resource__r.Name, Assigned_Resource__r.Plant__c, Assigned_Resource__r.Work_Center__c
			FROM ServiceAppointment WHERE ParentRecordId IN :woIds AND Assigned_Resource__c != NULL
			ORDER BY LastModifiedDate DESC];
		for (ServiceAppointment appt : appts) {
			if (!results.containsKey(appt.ParentRecordId)) {
				results.put(appt.ParentRecordId, appt.Assigned_Resource__r);
			}
		}
		return results;
	}
}