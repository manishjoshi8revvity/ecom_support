/**
 * Calculates Experience Scores based on Field Service Work.
 * Created by tony on 4/6/21.
 * CONVERTED to SFS by frankvanloon on 5/22/24.
 */
public without sharing class FS_ExpertiseFieldExperience_Batch implements Database.Batchable<SObject>, Schedulable, Database.Stateful {

	public class FieldScoreRange {
		public Integer fieldScore { get; set; }
		public Integer workMin { get; set; }
		public Integer workMax { get; set; }

		public FieldScoreRange(Integer score, Integer min, Integer max)
		{
			this.fieldScore = score;
			this.workMin = min;
			this.workMax = max;
		}
	}

	public class WorkScore {
		public Integer workScore { get; set; }
		public Integer minMonths { get; set; }
		public Integer maxMonths { get; set; }
		public List<String> orderTypes { get; set;}

		public WorkScore(Integer score, Integer min, Integer max, List<String> orderTypes)
		{
			this.workScore = score;
			this.minMonths = min;
			this.maxMonths = max;
			this.orderTypes = orderTypes;
		}
	}

	// Used across all batches
	public List<WorkScore> workScoreList = new List<WorkScore>();
	public List<FieldScoreRange> fieldScoreRangeList = new List<FieldScoreRange>();
	public Map<String, String> skillNameToIdMap = new Map<String, String>();
	Datetime oldestDateTime = Datetime.now();

	// For scheduling only
	public FS_ExpertiseFieldExperience_Batch() {
	}

	public void execute(SchedulableContext ctx) {
		FS_ExpertiseFieldExperience_Batch batch = new FS_ExpertiseFieldExperience_Batch();
		Database.executeBatch(batch, 10);
	}

	// Database.Batchable methods

	public Database.QueryLocator start(Database.BatchableContext ctx) {
		System.debug('Starting: ExpertiseFieldExperience_Batch');

		//Datetime dt = (Test.isRunningTest()) ? Datetime.now() : Datetime.now().addYears(-previousYears);
		Map<String, C_META_FS_Experience_Setting__mdt> experienceMdtMap = C_META_FS_Experience_Setting__mdt.getAll();
		for(String experienceMdtKey : experienceMdtMap.keySet()) {

			//System.debug('Experience MDT: ' + experienceMdtMap.get(experienceMdt));
			C_META_FS_Experience_Setting__mdt experienceSetting = experienceMdtMap.get(experienceMdtKey);

			if (experienceSetting.Type__c == 'Field') {
				FieldScoreRange fieldScoreRange = new FieldScoreRange((Integer) experienceSetting?.Score__c,
						(Integer) experienceSetting?.Work_Minimum__c, (Integer) experienceSetting?.Work_Maximum__c);
				fieldScoreRangeList.add(fieldScoreRange);

			} else if (experienceSetting.Type__c == 'Work') {

				List<String> lstOrderTypes = new List<String>();
				for (String orderType : experienceSetting?.Order_Types__c.split(',')) {
					lstOrderTypes.add(orderType.trim());
				}
				System.debug('lstOrderTypes: ' + lstOrderTypes);

				WorkScore workScore = new WorkScore(
						(Integer) experienceSetting?.Score__c,
						(Integer) experienceSetting?.Minimum_Months__c,
						(Integer) experienceSetting?.Maximum_Months__c,
						lstOrderTypes);
				workScoreList.add(workScore);
			}
		}
		System.debug('fieldScoreRangeList: ' + fieldScoreRangeList);
		System.debug('workScoreList: ' + workScoreList);

		// Get the oldest work score date to use later
		for (WorkScore ws :workScoreList) {
			Datetime wsMaxMonthsDateTime = Datetime.now().addMonths(-ws.maxMonths);
			if (oldestDateTime > wsMaxMonthsDateTime ) {
				oldestDateTime = wsMaxMonthsDateTime;
			}
		}

		// Query Technicians
		return Database.getQueryLocator([SELECT Id, Name FROM ServiceResource]);
	}

	public void execute(Database.BatchableContext ctx, List<ServiceResource> techs) {
		System.debug('Executing: ExpertiseFieldExperience_Batch');

		// Get the list of tech Ids
		Set<Id> techIds = new Set<Id>();
		for (ServiceResource tech :techs) {
			techIds.add(tech.Id);
		}
		System.debug('techIds: ' + techIds.size() + '  :' + techIds);

		// Query Work Orders for these Technicians
		List<ServiceAppointment> apptList = [SELECT Id, Assigned_Resource__c,
				SFS_Work_Order__r.WorkOrderNumber, SFS_Work_Order__r.Completed_Date_Time__c,
				SFS_Work_Order__r.ModelSeries__c, SFS_Work_Order__r.Order_Type__c
			FROM ServiceAppointment
			WHERE Assigned_Resource__c IN :techIds
				AND SFS_Work_Order__r.ModelSeries__c != NULL
				AND SFS_Work_Order__r.Completed_Date_Time__c >= :oldestDateTime
			ORDER BY Assigned_Resource__c, SFS_Work_Order__r.ModelSeries__c, SFS_Work_Order__r.Order_Type__c];
		System.debug('apptList.size(): ' + apptList.size());

		// Create a map of Skill Name to Ids
		Set<String> skillNames = new Set<String>();
		for (ServiceAppointment appt : apptList) {
			WorkOrder wo = appt.SFS_Work_Order__r;
			if (wo != null && String.isNotBlank(wo.ModelSeries__c)) {
				skillNames.add(wo.ModelSeries__c);
			}
			System.debug('Adding ' + wo.WorkOrderNumber + ' wo.ModelSeries__c: ' + wo.ModelSeries__c);
		}
		System.debug('skillNames: ' + skillNames);

		List<Schema.Skill> skills = [SELECT Id, MasterLabel FROM Skill WHERE MasterLabel IN :skillNames];
		System.debug('skills: ' + skills.size() + '  ' + skills);

		for (Schema.Skill skill :skills) {
			skillNameToIdMap.put(skill.MasterLabel, skill.Id);
		}
		System.debug('skillNameToIdMap: ' + skillNameToIdMap.size() + '  ' + skillNameToIdMap);

		List<FS_Experience__c> experienceList = new List<FS_Experience__c>();
		Map<String, Integer> techSkillWorkTotalMap = new Map<String, Integer>();

		// Collect the "Skill Activity Types" worked for each key
		Map<String, Set<String>> techSkillActivityTypes = new Map<String, Set<String>>();

		for (ServiceAppointment appt : apptList)
		{
			WorkOrder wo = appt.SFS_Work_Order__r;
			// Create a Tech+Skill Map from each Work Order with a running total score
			if (appt.Assigned_Resource__c != null && wo.ModelSeries__c != null && skillNameToIdMap.get(wo.ModelSeries__c) != null) {
				String externalId = appt.Assigned_Resource__c + '-' + skillNameToIdMap.get(wo.ModelSeries__c);
				System.debug('Tech-Skill: ' + externalId + '  Order Type: ' + wo.Order_Type__c);

				for (WorkScore ws :workScoreList) {
					Datetime startDT = Datetime.now().addMonths(-ws.maxMonths);
					Datetime endDT = Datetime.now().addMonths(-ws.minMonths);

					if (wo.Completed_Date_Time__c >= startDT && wo.Completed_Date_Time__c <= endDT
							&& ws.orderTypes.contains(wo.Order_Type__c)) {
						System.debug('workScore: ' + ws.workScore);

						// Convert each WO Order Type into a Skill Activity Type.. add to techSkillActivityTypes
						String actType = FS_ExperienceManager.lookupSkillActivityType(wo.Order_Type__c);
						if (actType != null) {
							if (!techSkillActivityTypes.containsKey(externalId)) {
								techSkillActivityTypes.put(externalId, new Set<String>());
							}
							techSkillActivityTypes.get(externalId).add(actType);
						}

						if (techSkillWorkTotalMap.get(externalId) == null) {
							techSkillWorkTotalMap.put(externalId, ws.workScore);
							System.debug('Added NEW entry to techSkillWorkTotalMap');
						} else {
							techSkillWorkTotalMap.put(externalId, techSkillWorkTotalMap.get(externalId) + ws.workScore);
							System.debug('Updated EXISTING entry to techSkillWorkTotalMap');
						}
					}
				}
			}
		}

		// Query any existing Experience records where External Id matches the tech-skill values of the completedTrainingWithTrainedSkillsList
		Set<String> experienceExtIds = techSkillWorkTotalMap.keySet();
		List<FS_Experience__c> existingExperienceList = [SELECT Id, External_Key__c, Worked_Activity_Types__c
				FROM FS_Experience__c WHERE External_Key__c IN :experienceExtIds];

		// Create a Map of Experience Ext Ids to Activity Type so we can use it for comparison later
		Map<String, String> expExtIdToActivityTypeMap = new Map<String, String>();
		for (FS_Experience__c exp :existingExperienceList) {
			expExtIdToActivityTypeMap.put(exp.External_Key__c, exp.Worked_Activity_Types__c);
		}
		System.debug('expExtIdToActivityTypeMap: ' + expExtIdToActivityTypeMap);

		for (String extId :techSkillWorkTotalMap.keySet()) {
			FS_Experience__c experience = new FS_Experience__c();
			experience.External_Key__c = extId;
			experience.Work_Total__c = techSkillWorkTotalMap.get(extId);
			experience.Technician__c = extId.substringBefore('-');
			experience.Related_Skill__c = extId.substringAfter('-');
			// Set the Worked Activity Types (additive with previous values)
			Set<String> previousActivityTypeList = FS_ExperienceManager.splitValues(expExtIdToActivityTypeMap.get(extId));
			Set<String> trainedActivityTypeList = techSkillActivityTypes.get(extId);
			String combinedActivityTypeString =
					FS_ExperienceManager.combineActivityTypes(previousActivityTypeList, trainedActivityTypeList);
			System.debug('combinedActivityTypeString: ' + combinedActivityTypeString);
			experience.Worked_Activity_Types__c = combinedActivityTypeString;

			System.debug('experience.Technician__c: ' + experience.Technician__c);

			// Find the Field Score Range for this Work Total
			for (FieldScoreRange fieldScoreRange :fieldScoreRangeList) {

				if (experience.Work_Total__c >= fieldScoreRange?.workMin &&
						(fieldScoreRange.workMax == null || experience.Work_Total__c < fieldScoreRange.workMax)) {
					experience.Field_Score__c = fieldScoreRange.fieldScore;
					System.debug('Found a Match for the fieldScoreRange: ' + fieldScoreRange.fieldScore);
					break; // We found the match so break out of the loop
				}
			}

			experienceList.add(experience);
		}

		System.debug('techSkillWorkTotalMap: ' + techSkillWorkTotalMap + '  size: ' + techSkillWorkTotalMap.size());

		// Create the new or update the old Experience records
		if (!experienceList.isEmpty())
		{
			System.debug('Upserting Experience records: ' + experienceList + '  size: ' + experienceList.size());
			upsert experienceList External_Key__c;
		}

		// Zero out the expired Experience records for these Technicians (ones without recent Work scores)
		List<FS_Experience__c> expired = [SELECT Id, Work_Total__c, Field_Score__c
			FROM FS_Experience__c WHERE Technician__c IN :techIds
				AND External_Key__c NOT IN :techSkillWorkTotalMap.keySet()];
		if (expired.isEmpty()) {
			return;
		}

		for (FS_Experience__c e : expired) {
			e.Work_Total__c = 0;
			e.Field_Score__c = 0;
		}
		update expired;
	}

	public void finish(Database.BatchableContext ctx) {
		System.debug('Finishing: ExpertiseTrainExperience_Batch');
		if (!Test.isRunningTest()) {
			FS_ExpertiseToExperience_Batch next = new FS_ExpertiseToExperience_Batch();
			next.execute(null); // mimic the Schedulable method
		}
	}

}