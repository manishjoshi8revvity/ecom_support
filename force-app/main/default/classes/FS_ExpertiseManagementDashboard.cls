/**
 * This class encapsulates all of the Wired Services needed for the Expertise Management Dashboard LWC
 * Created by tony on 4/16/21.
 *
 * Updates:
 * 11/30/2022   tony    ITSVMX-1057 Expertise Management Dashboard Updates - Display more search results
 * CONVERTED to SFS by frankvanloon on 5/22/24.
 */
public with sharing class FS_ExpertiseManagementDashboard {
	@AuraEnabled(Cacheable=true)
	public static List<FS_CustomLookupService.LookupSearchResult> searchTechSkills(String searchTerm, List<String> selectedIds)
	{
		// 11/30/2022 ITSVMX-1057 Expertise Management Dashboard Updates - Display more search results
		final Integer MAX_RESULTS = 25;

		// Prepare query parameters
		String skillSearch = '%' + searchTerm + '%';
		searchTerm += '*';

		// Execute SOSL search query
		List<List<SObject>> searchResults = [
				FIND :searchTerm
				IN ALL FIELDS
				RETURNING
						ServiceResource(Id, Name, Work_Center__c, Plant__c WHERE Id NOT IN :selectedIds),
						//Skill(Id, DeveloperName, Description WHERE Id NOT IN :selectedIds),
						ServiceTerritory(Id, Name, Type__c WHERE Id NOT IN :selectedIds)
				LIMIT :MAX_RESULTS
		];

		// Prepare results
		List<FS_CustomLookupService.LookupSearchResult> results = new List<FS_CustomLookupService.LookupSearchResult>();

		// Extract Technicians
		ServiceResource[] techs = (List<ServiceResource>) searchResults[0];
//        ServiceResource[] techs = (List<ServiceResource>) searchResults[2];
		for (ServiceResource tech : techs) {
			results.add(new FS_CustomLookupService.LookupSearchResult(tech.Id, 'ServiceResource',
					'custom:custom15', tech.Name, 'Technician: ' + tech.Work_Center__c)
			);
		}

		// Extract Skills
		//Skill[] skills = (List<Skill>) searchResults[1];
		System.debug('Skill search: ' + skillSearch);
		List<Skill> skills = [SELECT Id, MasterLabel, Description FROM Skill
			WHERE MasterLabel LIKE :skillSearch LIMIT 10];
		for (Skill skill : skills) {
			results.add(new FS_CustomLookupService.LookupSearchResult(skill.Id, 'Skill',
					'custom:custom19', skill.MasterLabel, 'Skill: ' + skill.Description)
			);
		}

		// Extract Territories & convert them into LookupSearchResult
		ServiceTerritory[] territories = (List<ServiceTerritory>) searchResults[1];
		for (ServiceTerritory territory : territories) {
			results.add(new FS_CustomLookupService.LookupSearchResult(territory.Id, 'ServiceTerritory',
					'custom:custom78', territory.Name, 'Type: ' + territory.Type__c)
			);
		}

		// Optionally sort all results on title
		results.sort();

		return results;
	}

	public class TechSkillHierarchyWrapper {

		@AuraEnabled public String key{get;set;}
		@AuraEnabled public String keyUrl{get;set;}
		@AuraEnabled public String name{get;set;}
		@AuraEnabled public String techName{get;set;}
		@AuraEnabled public String territory{get;set;}
		@AuraEnabled public String expertiseId{get;set;}
		@AuraEnabled public String expertiseUrl{get;set;}
		@AuraEnabled public Integer trainingScore{get;set;}
		@AuraEnabled public String trainingSummary{get;set;}
		//@AuraEnabled public Integer trainingReport{get;set;}
		@AuraEnabled public Integer fieldScore{get;set;}
		@AuraEnabled public String fieldSummary{get;set;}
		//@AuraEnabled public Integer fieldReport{get;set;}
		@AuraEnabled public Integer finalScore{get;set;}
		@AuraEnabled public Integer expertiseScore{get;set;}
		@AuraEnabled public Boolean expertiseExists{get;set;}
		@AuraEnabled public String recommendedAction{get;set;}
		@AuraEnabled public String expertiseActivityType{get;set;}
		@AuraEnabled public String experienceActivityType{get;set;}
		@AuraEnabled public Boolean expanded{get;set;}
		@AuraEnabled public Boolean disableCreate{get;set;}
		@AuraEnabled public Boolean disableRemove{get;set;}
		@AuraEnabled public Boolean disableReport{get;set;}
		@AuraEnabled public String lastModified{get;set;}
		@AuraEnabled public List<TechSkillHierarchyWrapper> items{get;set;}

		public TechSkillHierarchyWrapper(FS_Experience__c experience, Boolean isParent, ServiceResourceSkill expertise) {

			if (isParent) {
				key = experience.Technician__c;
				keyUrl = '/' + experience.Technician__c;
				name = experience.Technician__r.Name;
				territory = experience.Technician__r.Primary_Territory__c; //SVMXC__Service_Territory__r.Name;
				expanded = true;
				disableCreate = true;
				disableRemove = true;
				disableReport = true;
				this.items = new List<TechSkillHierarchyWrapper>();
			} else {
				key = experience.External_Key__c;
				keyUrl = '/' + experience.Id;
				name = experience.Related_Skill_Name__c;
				techName = experience.Technician__r.Name;
				trainingScore = (Integer) experience.Training_Score__c;
				fieldScore = (Integer) experience.Field_Score__c;
				finalScore = (Integer) experience.Final_Score__c;
				recommendedAction = experience.Recommended_Action__c;
				experienceActivityType = experience.Trained_Activity_Types__c;
				trainingSummary = (trainingScore == null ? 0 : trainingScore)
						+ (String.isBlank(experience.Trained_Activity_Types__c)
						? '' : ' [' + experience.Trained_Activity_Types__c + ']');
				fieldSummary = (fieldScore == null ? 0 : fieldScore)
						+ (String.isBlank(experience.Worked_Activity_Types__c)
						? '' : ' [' + experience.Worked_Activity_Types__c + ']');

				expertiseId = experience.Related_Expertise__c;
				if (expertiseId != null) {
					expertiseExists = true;
					expertiseUrl = '/' + expertiseId;

					// TODO: Remove this SOQL by replacing with parameter
					//ServiceResourceSkill expertise = [SELECT Id, SkillLevel, Activity_Type__c, LastModifiedBy.Name, LastModifiedDate
					//	FROM ServiceResourceSkill WHERE Id = :expertiseId];
					expertiseScore = (Integer) expertise.SkillLevel;
					this.lastModified = expertise.LastModifiedBy?.Name + expertise.LastModifiedDate.format(' yyyy-MM-dd h:m a');
					expertiseActivityType = expertise.Activity_Type__c;

				} else {
					expertiseExists = false;
				}

				disableReport = false;
				if (expertiseId == null || expertiseId == '') {
					disableCreate = false;
					disableRemove = true;
				} else {
					disableCreate = true;
					disableRemove = false;
				}
			}
		}
	}

	// Get the tree for the provided list of Ids
	@AuraEnabled(Cacheable=false)
	public static List<TechSkillHierarchyWrapper> buildTechSkillsTableFromSearch(
			List<String> techSkillIds, Decimal rangeMin, Decimal rangeMax, List<String> rangeTypes, List<String> recommendedActions) {

		// Separate Technician and Skill Ids into different Sets
		Set<Id> techIds = new Set<Id>();
		Set<Id> skillIds = new Set<Id>();
		Set<Id> terrIds = new Set<Id>();
		//Set<Id> parentAndChildTerrIds = new Set<Id>();
		Set<String> parentAndChildTerrNames = new Set<String>();
		String techPrefix = ServiceResource.SObjectType.getDescribe().getKeyPrefix();
		String skillPrefix = Skill.SObjectType.getDescribe().getKeyPrefix();
		String terrPrefix = ServiceTerritory.SObjectType.getDescribe().getKeyPrefix();

		for (String techSkillId :techSkillIds) {
			if (techSkillId.startsWith(techPrefix)) {
				techIds.add(techSkillId);
			} else if (techSkillId.startsWith(skillPrefix)) {
				skillIds.add(techSkillId);
			} else if (techSkillId.startsWith(terrPrefix)) {
				terrIds.add(techSkillId);
			}
		}
		System.debug('techSkillIds: ' + techSkillIds);
		System.debug('techIds: ' + techIds);
		System.debug('skillIds: ' + skillIds);
		System.debug('terrIds: ' + terrIds);

		if (!terrIds.isEmpty()) {
			List<ServiceTerritory> parentAndChildTerritories = [SELECT  Id, Name
				FROM ServiceTerritory WHERE Id IN :terrIds
					OR ParentTerritoryId IN :terrIds
					OR ParentTerritory.ParentTerritoryId IN :terrIds
					OR ParentTerritory.ParentTerritory.ParentTerritoryId IN :terrIds
					OR ParentTerritory.ParentTerritory.ParentTerritory.ParentTerritoryId IN :terrIds
			];

			for (ServiceTerritory territory :parentAndChildTerritories) {
				parentAndChildTerrNames.add(territory.Name);
			}
			System.debug('parentAndChildTerrNames: ' + parentAndChildTerrNames);
		}

		// Create WHERE clause that will match what we are searching for
		String whereClause = '';

		if (techIds.size() > 0 || skillIds.size() > 0 || terrIds.size() > 0) {
			whereClause = ' WHERE (';
			// REVIEW: Changed the Territory Id below use the Primary_Territory__c (Name)
			if (techIds.size() > 0 && terrIds.size() > 0) {
				whereClause = whereClause + '(Technician__c IN :techIds OR Technician__r.Primary_Territory__c IN :parentAndChildTerrNames) AND ';
			} else if (techIds.size() > 0 && terrIds.size() == 0) {
				whereClause = whereClause + 'Technician__c IN :techIds AND ';
			}

			if (terrIds.size() > 0 && techIds.size() == 0) {
				whereClause = whereClause + 'Technician__r.Primary_Territory__c IN :parentAndChildTerrNames AND ';
			}

			if (skillIds.size() > 0) {
				whereClause = whereClause + 'Related_Skill__c IN :skillIds AND ';
			}

			// remove the last ending AND
			whereClause = whereClause.substringBeforeLast(' AND ');
			// add ending parenthesis
			whereClause = whereClause + ')';
		}

		// Add the Filtering by Range Types and Values (training, field, expertise)
		System.debug('rangeTypes: ' + rangeTypes.size() + '  :' + rangeTypes);
		String trainingClause = '(Training_Score__c >= :rangeMin AND Training_Score__c <= :rangeMax)';
		String fieldClause = '(Field_Score__c >= :rangeMin AND Field_Score__c <= :rangeMax)';
		// REVIEW: We cannot use Related_Expertise__r .. need to refactor to separate query
		//String expertiseClause = '(Related_Expertise__r.SkillLevel >= :rangeMin AND Related_Expertise__r.SkillLevel <= :rangeMax)';
		String expertiseClause = '(Related_Expertise__c != null)';

		if (rangeTypes.size() > 0) {

			if (whereClause == '') {
				whereClause = ' WHERE (';
			} else {
				whereClause = whereClause + ' AND (';
			}

			for (String rangeType :rangeTypes) {
				if (rangeType == 'training') {
					whereClause = whereClause + trainingClause + ' OR ';
				} else if (rangeType == 'field') {
					whereClause = whereClause + fieldClause + ' OR ';
				} else if (rangeType == 'expertise') {
					whereClause = whereClause + expertiseClause + ' OR ';
				}
			}

			// remove the last ending OR
			whereClause = whereClause.substringBeforeLast(' OR ');
			// add ending parenthesis
			whereClause = whereClause + ')';
		}

		if (recommendedActions.size() > 0) {
			if (whereClause == '') {
				whereClause = ' WHERE (';
			} else {
				whereClause = whereClause + ' AND (';
			}

			whereClause += 'Recommended_Action__c IN :recommendedActions)';
		}

		// REVIEW: Refactored Related_Expertise__r
		String queryString = 'SELECT Id, External_Key__c, Technician__c, Related_Skill__c, Final_Score__c,' +
				'Training_Score__c, Field_Score__c, Related_Expertise__c, Related_Skill_Name__c, ' +
				'Technician__r.Name, Technician__r.Primary_Territory__c, ' +
				'Trained_Activity_Types__c, Worked_Activity_Types__c, Recommended_Action__c ' +
				'FROM FS_Experience__c ' +
				whereClause + ' ORDER BY Technician__c, Related_Skill__c';

		System.debug('whereClause: ' + whereClause);
		System.debug('queryString: ' + queryString);
		List<FS_Experience__c> experienceList = Database.query(queryString);
		System.debug('experienceList: ' + experienceList.size() + '  '  + experienceList);

		// SOQL Query all ServiceResourceSkill by the Related_Expertise__c
		Set<Id> expertiseIds = new Set<Id>();
		for (FS_Experience__c experience : experienceList) {
			if (String.isNotBlank(experience.Related_Expertise__c)) {
				expertiseIds.add(experience.Related_Expertise__c);
			}
		}
		Map<Id, ServiceResourceSkill> expertiseMap = null;
		if (!expertiseIds.isEmpty()) {
			expertiseMap = new Map<Id, ServiceResourceSkill>([SELECT Id, SkillLevel, Activity_Type__c,
					LastModifiedBy.Name, LastModifiedDate
				FROM ServiceResourceSkill WHERE Id IN :expertiseIds]);
		}

		String tempTechId = null;
		TechSkillHierarchyWrapper tempTechSkill;
		List<TechSkillHierarchyWrapper> techSkillList = new List<TechSkillHierarchyWrapper>();
		for (FS_Experience__c experience :experienceList) {
			// Add the ServiceResourceSkill as a param into all 3 Constructor calls
			ServiceResourceSkill expertise = (expertiseMap == null) ? null : expertiseMap.get(experience.Related_Expertise__c);
			// Add a new Parent
			System.debug('tempTechId: ' + tempTechId + '   experience.Technician__c: ' + experience.Technician__c);
			if (tempTechId != experience.Technician__c && experience.External_Key__c != null) {
				System.debug('Creating a new Parent TechSkillHierarchyWrapper');
				tempTechId = experience.Technician__c;

				TechSkillHierarchyWrapper techSkill = new TechSkillHierarchyWrapper(experience, true, null);
				techSkillList.add(techSkill);
				tempTechSkill = techSkill;

				// Also add this as child record of the parent
				TechSkillHierarchyWrapper techSkillChild = new TechSkillHierarchyWrapper(
						experience, false, expertise);
				techSkill.items.add(techSkillChild);

			} else if (experience.External_Key__c != null) {

				// Add this as child record of the current parent
				System.debug('Creating a new Child TechSkillHierarchyWrapper');
				TechSkillHierarchyWrapper techSkillChild = new TechSkillHierarchyWrapper(
						experience, false, expertise);
				tempTechSkill.items.add(techSkillChild);
			}
		}

		System.debug('techSkillList: ' + techSkillList);
		return techSkillList;
	}

	@AuraEnabled
	public static String removeExpertise(String techSkillKey, String expertiseId) {
		FS_Experience__c experience = [
				SELECT Id, Related_Expertise__c, Expertise_Removed__c
				FROM FS_Experience__c
				WHERE External_Key__c = :techSkillKey
				LIMIT 1
		];

		List<ServiceResourceSkill> expertiseList = [
				SELECT Id, SkillNumber, ServiceResourceId, SkillId, SkillLevel
					FROM ServiceResourceSkill WHERE Id = :expertiseId];

		System.debug('About to Delete: ' + expertiseList);
		delete expertiseList;

		experience.Related_Expertise__c = null;
		experience.Expertise_Removed__c = true;
		update experience;

		return 'Deleted the Expertise';
	}

	@AuraEnabled
	public static String createExpertise( String techSkillKey, Integer skillLevel) {

		if (techSkillKey.length() > 30) {

			String techId = techSkillKey.substringBefore('-');
			String skillId = techSkillKey.substringAfter('-');

			// Get Service Group Team as it is a required field for Expertise
//			ServiceResource tech = [SELECT Id FROM ServiceResource WHERE Id = :techId];

			// Check to see if the Expertise record exists already
			List<ServiceResourceSkill> expertiseList = [SELECT Id, SkillLevel, Expertise_External_ID__c
					FROM ServiceResourceSkill WHERE Expertise_External_ID__c = :techSkillKey];
			ServiceResourceSkill expertise = (expertiseList.isEmpty()) ? null : expertiseList[0];
			if (expertise == null) {
				expertise = new ServiceResourceSkill();
				expertise.ServiceResourceId = techId;
				expertise.SkillId = skillId;
				expertise.Expertise_External_ID__c = techSkillKey;
				expertise.EffectiveStartDate = Datetime.now();
			}
			expertise.SkillLevel = skillLevel;
			upsert expertise;

			// Update the Experience record with the new Expertise Id
			FS_Experience__c experience = [SELECT Id, Related_Expertise__c, Expertise_Removed__c
					FROM FS_Experience__c WHERE External_Key__c = :techSkillKey LIMIT 1];
			experience.Related_Expertise__c = expertise.Id;
			experience.Expertise_Removed__c = false;
			update experience;

			return 'Created the Expertise';
		}

		return 'Error: You can only create a new Expertise from a skill line.';
	}

	@AuraEnabled(Cacheable=true)
	public static Id getReportId(String reportType) {

		System.debug(' --  reportType: ' + reportType);

		// return the Training Experience or Field Experience report id
		if (reportType == 'trainingReport') {
			System.debug(' --  querying Expertise_Mgmt_Training_Experience_oWw');
			return [SELECT Id FROM Report WHERE DeveloperName = 'Expertise_Mgmt_Training_Experience_oWw'].Id;
//            System.debug(' --  querying Expertise_Mgmt_Tech_and_Field_Exp_zpU');
//            return [SELECT Id FROM Report WHERE DeveloperName = 'Expertise_Mgmt_Tech_and_Field_Exp_zpU'].Id;
		} else if (reportType == 'fieldReport') {
			System.debug(' --  querying Expertise_Mgmt_Field_Experience_wJw');
			return [SELECT Id FROM Report WHERE DeveloperName = 'Expertise_Mgmt_Field_Experience_wJw'].Id;
		} else {
			return null;
		}
	}

	public class comboBoxResult {
		@AuraEnabled public String label { get; set; }
		@AuraEnabled public String value { get; set; }

		public comboBoxResult(String label, String value) {
			this.label = label;
			this.value = value;
		}
	}

	@AuraEnabled(Cacheable=true)
	public static List<comboBoxResult> getRecommendedActions() {
		List<comboBoxResult> statuses = new List<comboBoxResult>();
		Schema.DescribeFieldResult fieldResult = FS_Experience__c.Recommended_Action__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple){
			statuses.add(new comboBoxResult(pickListVal.getLabel(), pickListVal.getValue()));
		}
		return statuses;
	}
}