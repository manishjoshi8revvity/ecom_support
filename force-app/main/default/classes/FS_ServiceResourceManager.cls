/**
 * Manager Class to handle all ServiceResource (aka Technician) logic
 * CONVERTED to SFS by frankvanloon on 3/25/24.
 */
public with sharing class FS_ServiceResourceManager {

	public static void updateTechnicianLocations(List<ServiceResource> techList, Map<Id, ServiceResource> oldMap)
	{
		if (!FS_Utility.isActive('Update Technician Locations', 'Update Technicians Inventory Location.'))
		{
			return;
		}

		Set<String> locExtIds = new Set<String>();
		List<ServiceResource> techsToUpdate = new List<ServiceResource>();
		for (ServiceResource tech : techList)
		{
			ServiceResource old = (oldMap == null) ? null : oldMap.get(tech.Id);
			if (String.isNotEmpty(tech.Plant__c) && String.isNotEmpty(tech.LocationCode__c)
					&& (old == null || tech.LocationId == null
					|| tech.RelatedRecordId != old.RelatedRecordId
					|| tech.Plant__c != old.Plant__c
					|| tech.LocationCode__c != old.LocationCode__c))
			{
				techsToUpdate.add(tech);
				locExtIds.add(getLocExtId(tech));
			}
		}

		if (locExtIds.isEmpty())
		{
			return;
		}

		// Lookup Locations (do we need to filter by RecordType?)
		Map<String, Schema.Location> locMap = new Map<String, Schema.Location>();
		for (Schema.Location loc : [SELECT Id, Name, External_ID__c, Service_Engineer__c
			FROM Location WHERE External_ID__c IN :locExtIds])
		{
			locMap.put(loc.External_ID__c, loc);
		}

		// Match Techs to Locations, update both objects
		Map<Id, Schema.Location> locsToUpdate = new Map<Id, Schema.Location>();
		for (ServiceResource tech : techsToUpdate)
		{
			String locExtId = getLocExtId(tech);
			if (locMap.containsKey(locExtId))
			{
				Schema.Location loc = locMap.get(locExtId);
				loc.Service_Engineer__c = tech.RelatedRecordId;
				locsToUpdate.put(loc.Id, loc);

				tech.LocationId = loc.Id;
			}
		}

		if (!locsToUpdate.isEmpty())
		{
			update locsToUpdate.values();
		}
	}

	private static String getLocExtId(ServiceResource tech)
	{
		return tech.Plant__c + tech.LocationCode__c;
	}

	// NOTE: I don't believe the following is needed. It is all about sync'ing the Tech-Geographies (aka ServiceMemberTerritory)
	// onto the Technician record as a work-around to the dispatch console.  This should not be needed in SFS.

//	public static void onTechnicianGeographies(List<ServiceTerritoryMember> geoTechList)
//	{
//		Set<Id> techIds = new Set<Id>();
//		for (ServiceTerritoryMember geoTech : geoTechList)
//		{
//			techIds.add(geoTech.ServiceResourceId);
//		}
//
//		List<ServiceResource> techs = [SELECT Id, Name, Technician_Geographies__c
//		FROM ServiceResource WHERE Id IN :techIds];
//
//		updateTechnicianGeographies(techs);
//		update techs;
//	}

	// Added for JIRA: SVMXCFG-403
//	public static void updateTechnicianGeographies(List<ServiceResource> techList)
//	{
//		if (!FS_Utility.isActive('Update Technician Geographies', 'Update Technician Geographies list.'))
//		{
//			return;
//		}
//
//		Set<Id> techIds = new Set<Id>();
//		for (ServiceResource tech : techList)
//		{
//			techIds.add(tech.Id);
//		}
//
//		Map<Id, List<String>> techGeoMap = new Map<Id, List<String>>();
//		for (ServiceTerritoryMember geoTech : [SELECT Id, ServiceResourceId, Location__c
//		FROM ServiceTerritoryMember WHERE ServiceResourceId IN :techIds])
//		{
//			System.debug('geoTech: [' + geoTech + ']'); //TODO Remove after testing
//			Id techId = geoTech.ServiceResourceId;
//			if (!techGeoMap.containsKey(techId))
//			{
//				techGeoMap.put(techId, new List<String>());
//			}
//			techGeoMap.get(techId).add(geoTech.Location__c);
//		}
//
//		List<String> geoTechFields = new List<String> {
//				'Technician_Geographies__c', 'Technician_Geographies_2__c',
//				'Technician_Geographies_3__c', 'Technician_Geographies_4__c' };
//		String lastField = geoTechFields.get(geoTechFields.size()-1);
//		for (ServiceResource tech : techList)
//		{
//			for (String geoTechField : geoTechFields) {
//				tech.put(geoTechField, '');
//			}
////			tech.Technician_Geographies__c = '';
////			tech.Technician_Geographies_2__c = '';
//
//			List<String> geoList = techGeoMap.get(tech.Id);
//			if (geoList != null && !geoList.isEmpty())
//			{
//				System.debug('geoList: [' + geoList + ']'); //TODO Remove after testing
//				// SVMXCFG-1136 additional logic for "Tech Geo 2" field
//				//tech.Technician_Geographies__c = ('' + geoList).replace('(', '').replace(')', '');
//				for (String geo : geoList)
//				{
//					for (String geoTechField : geoTechFields) {
//						String geoTechValue = (String) tech.get(geoTechField);
//						System.debug('geo: [' + geo + ']  geoTechField: [' + geoTechField + ']  geoTechValue: ['  + geoTechValue + ']');  //TODO Remove after testing
//						if (String.isBlank(geoTechValue))
//						{
//							tech.put(geoTechField, geo);
//							break;
//						}
//						else if (geoTechValue.length() + 2 + geo.length() < 255)
//						{
//							tech.put(geoTechField, geoTechValue + ', ' + geo);
//							break;
//						}
//						else if (geoTechField == lastField) {
//							// Overflow...
//							geoTechValue += geoTechValue + ', ' + geo;
//							tech.put(geoTechField, geoTechValue.abbreviate(255));
//						}
//					}
//				}
//			}
//		}
//	}

	// ITSVMX-220 Validate change to Geographies using Territory lookup(s)
//	public static void validateTechnicianGeographies(List<ServiceResource> techList, Map<Id, ServiceResource> oldMap) {
//		if (!FS_Utility.isActive('TechValidateTerritoryGeos', 'Validate Technician Geographies to the Territory.')) {
//			return;
//		}
//
//		Map<Id, ServiceResource> techMap = new Map<Id, ServiceResource>();
//		for (ServiceResource tech : techList) {
//			ServiceResource old = (oldMap == null) ? null : oldMap.get(tech.Id);
//			// ITSVMX-547 Do not try to validate Geographies if th eTerritory is NOT set
//			if (tech.SVMXC__Service_Territory__c == null) {
//				continue;
//			}
//
//			if (tech.SVMXC__Service_Territory__c != old.SVMXC__Service_Territory__c
//					|| tech.Technician_Geographies__c != old.Technician_Geographies__c
//					|| tech.Technician_Geographies_2__c != old.Technician_Geographies_2__c
//					|| tech.Technician_Geographies_3__c != old.Technician_Geographies_3__c
//					|| tech.Technician_Geographies_4__c != old.Technician_Geographies_4__c)
//			{
//				techMap.put(tech.Id, tech);
//			}
//		}
//
//		if (techMap.isEmpty()) {
//			return;
//		}
//
//		for (ServiceTerritoryMember geoTech : [
//				SELECT Id, ServiceResourceId, Location__c,
//						ServiceTerritory,
//						ServiceTerritory.ParentTerritoryId,
//						ServiceTerritory.ParentTerritory.SVMXC__Parent_Territory__c,
//						ServiceTerritory.ParentTerritory.ParentTerritory.SVMXC__Parent_Territory__c
//				FROM ServiceTerritoryMember
//				WHERE ServiceResourceId IN :techMap.keySet()])
//		{
//			Id techId = geoTech.ServiceResourceId;
//
//			// ITSVMX-220 Validate change to Geographies using Territory lookup(s)
//			ServiceResource tech = techMap.get(techId);
//			Id techTerritoryId = tech.Ter;
//			Id geoTerritoryId = geoTech.SMAX_PS_Geography__r?.BD_Territory__c;
//			if (techTerritoryId != null && geoTerritoryId != null) {
//				// Both are populated.. must match or inherit
//				Id geoTerritory2 = geoTech.SMAX_PS_Geography__r?.BD_Territory__r?.SVMXC__Parent_Territory__c;
//				Id geoTerritory3 = geoTech.SMAX_PS_Geography__r?.BD_Territory__r?.SVMXC__Parent_Territory__r?.SVMXC__Parent_Territory__c;
//				Id geoTerritory4 = geoTech.SMAX_PS_Geography__r?.BD_Territory__r?.SVMXC__Parent_Territory__r?.SVMXC__Parent_Territory__r?.SVMXC__Parent_Territory__c;
//				if (techTerritoryId != geoTerritoryId && techTerritoryId != geoTerritory2
//						&& techTerritoryId != geoTerritory3 && techTerritoryId != geoTerritory4) {
//					String errorMsg = 'Illegal Territory / Geography Assignment: ' + geoTech.SMAX_PS_Location__c;
//					System.debug(errorMsg);
//					tech.addError(errorMsg);
//					continue;
//				}
//			}
//		}
//	}

	/**
	 * Based on the Technician-Geography records, find the best fit Territory (lowest in the Tree)
	 * @param tech Technician
	 * @return Territory Id of the best-fit Territory for the Technician's Geographies
	 */
//	public static Id recommendTerritory(ServiceResource tech) {
//		Set<Id> level1 = new Set<Id>();
//		Set<Id> level2 = new Set<Id>();
//		Set<Id> level3 = new Set<Id>();
//		Set<Id> level4 = new Set<Id>();
//		for (SMAX_PS_Geography_Technician__c geoTech : [
//				SELECT Id, Name, SMAX_PS_Technician__c, SMAX_PS_Location__c,
//						SMAX_PS_Geography__r.BD_Territory__c,
//						SMAX_PS_Geography__r.BD_Territory__r.SVMXC__Parent_Territory__c,
//						SMAX_PS_Geography__r.BD_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__c,
//						SMAX_PS_Geography__r.BD_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__c
//				FROM SMAX_PS_Geography_Technician__c
//				WHERE SMAX_PS_Technician__c = :tech.Id])
//		{
//			Id geoTerritory1 = geoTech.SMAX_PS_Geography__r?.BD_Territory__c;
//			if (geoTerritory1 != null) {
//				level1.add(geoTerritory1);
//			}
//			Id geoTerritory2 = geoTech.SMAX_PS_Geography__r?.BD_Territory__r?.SVMXC__Parent_Territory__c;
//			if (geoTerritory2 != null) {
//				level2.add(geoTerritory2);
//			}
//			Id geoTerritory3 = geoTech.SMAX_PS_Geography__r?.BD_Territory__r?.SVMXC__Parent_Territory__r?.SVMXC__Parent_Territory__c;
//			if (geoTerritory3 != null) {
//				level3.add(geoTerritory3);
//			}
//			Id geoTerritory4 = geoTech.SMAX_PS_Geography__r?.BD_Territory__r?.SVMXC__Parent_Territory__r?.SVMXC__Parent_Territory__r?.SVMXC__Parent_Territory__c;
//			if (geoTerritory4 != null) {
//				level4.add(geoTerritory4);
//			}
//		}
//
//		Id result = null;
//		if (level1.size() == 1) {
//			result = (Id) level1.iterator().next();
//		} else if (level2.size() == 1) {
//			result = (Id) level2.iterator().next();
//		} else if (level3.size() == 1) {
//			result = (Id) level3.iterator().next();
//		} else if (level4.size() == 1) {
//			result = (Id) level4.iterator().next();
//		}
//		return result;
//	}
}