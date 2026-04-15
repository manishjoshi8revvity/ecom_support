/**
 * Calculates Experience Scores based on Completed Training.
 * Created by tony on 4/12/21.
 * CONVERTED to SFS by frankvanloon on 5/22/24.
 */
public with sharing class FS_ExpertiseTrainExperience_Batch implements Database.Batchable<SObject>, Schedulable, Database.Stateful {
	public class TrainingScoreRange {
		public Integer trainingScore { get; set; }
		public Integer minMonths { get; set; }
		public Integer maxMonths { get; set; }

		public TrainingScoreRange(Integer score, Integer min, Integer max) {
			this.trainingScore = score;
			this.minMonths = min;
			this.maxMonths = max;
		}
	}

	public class CompletedTrainingWithTrainedSkills {
		public String trainingCourseId { get; set; }
		public String trainingCourseName { get; set; }
		public String technicianId { get; set; }
		public String technicianName { get; set; }
		public Date completionDate { get; set; }
		public String skillId { get; set; }
		public String skillName { get; set; }
		public String activityType { get; set; }

		public CompletedTrainingWithTrainedSkills(String trainingCourseId, String trainingCourseName, String technicianId,
				String technicianName, Date completionDate, String skillId, String skillName, String activityType) {

			this.trainingCourseId = trainingCourseId;
			this.trainingCourseName = trainingCourseName;
			this.technicianId = technicianId;
			this.technicianName = technicianName;
			this.completionDate = completionDate;
			this.skillId = skillId;
			this.skillName = skillName;
			this.activityType = activityType;
		}
	}

	public List<TrainingScoreRange> trainingScoreRangeList = new List<TrainingScoreRange>();
	public Date startDate;
	public Date endDate;

	// For scheduling only
	public FS_ExpertiseTrainExperience_Batch() {
	}

	public void execute(SchedulableContext ctx) {

		FS_ExpertiseTrainExperience_Batch batch = new FS_ExpertiseTrainExperience_Batch();
		Database.executeBatch(batch, 10);
	}

	// Database.Batchable methods

	public Database.QueryLocator start(Database.BatchableContext ctx) {

		System.debug('Starting: ExpertiseTrainExperience_Batch');

		Map<String, C_META_FS_Experience_Setting__mdt> experienceMdtMap = C_META_FS_Experience_Setting__mdt.getAll();
		for(String experienceMdtKey : experienceMdtMap.keySet()) {
			C_META_FS_Experience_Setting__mdt experienceSetting = experienceMdtMap.get(experienceMdtKey);
			if (experienceSetting.Type__c == 'Training') {

				TrainingScoreRange trainingScoreRange = new TrainingScoreRange((Integer) experienceSetting?.Score__c,
						(Integer) experienceSetting?.Minimum_Months__c, (Integer) experienceSetting?.Maximum_Months__c);
				trainingScoreRangeList.add(trainingScoreRange);
			}
		}
		System.debug('trainingScoreRangeList: ' + trainingScoreRangeList);

		// Build Completed Training List query locator
		for (TrainingScoreRange tsr :trainingScoreRangeList) {
			Date startDT = Date.today().addMonths(-tsr.maxMonths);
			Date endDT = Date.today().addMonths(-tsr.minMonths);
			System.debug('startDT: ' + startDT + '  endDT: ' + endDT + '  tsr.trainingScore: ' + tsr.trainingScore);
			if (this.startDate == null || this.startDate > startDT) {
				this.startDate = startDT;
			}
			if (this.endDate == null || this.endDate < endDT) {
				this.endDate = endDT;
			}
		}
		System.debug('Found Start Date = ' + this.startDate + ', and End Date = ' + this.endDate);

		// Query Technicians
		return Database.getQueryLocator([SELECT Id, Name FROM ServiceResource]);
	}

	public void execute(Database.BatchableContext ctx, List<ServiceResource> techs) {

		// Get the list of tech Ids
		Set<Id> techIds = new Set<Id>();
		for (ServiceResource tech :techs) {
			techIds.add(tech.Id);
		}
		System.debug('techIds: ' + techIds.size() + '  :' + techIds);

		// Find Completed Training for these Technicians...
		List<FS_CompletedTraining__c> completedTrainingList = [SELECT Id, Name, Completion_Date__c,
				Training_Course__c, Training_Course__r.Name, Training_Course__r.Activity_Type__c,
				Related_Technician__c, Related_Technician__r.Name
		FROM FS_CompletedTraining__c
		WHERE Related_Technician__c IN :techIds
		AND Completion_Date__c >= :startDate AND Completion_Date__c <= :endDate
		ORDER BY Related_Technician__c, Training_Course__c, Completion_Date__c DESC];

		System.debug('Executing: ExpertiseTrainExperience_Batch');
		System.debug('completedTrainingList: ' + completedTrainingList);

		// Iterate through completedTrainingList to get the set of Training Course Ids
		Set<Id> trainingCourseIds = new Set<Id>();
		for (FS_CompletedTraining__c completedTraining :completedTrainingList) {
			trainingCourseIds.add(completedTraining.Training_Course__c);
		}

		// Retrieve the list of trained skills filtered by valid training course Ids
		List<FS_TrainedSkill__c> trainedSKillList = new List<FS_TrainedSkill__c>([
				SELECT Skill__c, Skill_Name__c, Related_Training_Course__c, Related_Training_Course__r.Name
				FROM FS_TrainedSkill__c
				WHERE Related_Training_Course__c IN :trainingCourseIds
		]);
		System.debug('trainedSKillList: ' + trainedSKillList);

		// Lookup the Skill Ids if not populated yet
		Set<String> skillNames = new Set<String>();
		for (FS_TrainedSkill__c tskill : trainedSKillList) {
			if (tskill.Skill_Name__c != null && tskill.Skill__c == null) {
				skillNames.add(tskill.Skill_Name__c);
			}
		}

		if (!skillNames.isEmpty()) {
			Map<String, Skill> skillMap = new Map<String, Skill>();
			for (Skill s : [SELECT Id, MasterLabel FROM Skill WHERE MasterLabel IN :skillNames]) {
				skillMap.put(s.MasterLabel, s);
			}
			for (FS_TrainedSkill__c tskill : trainedSKillList) {
				if (tskill.Skill_Name__c != null && tskill.Skill__c == null) {
					Skill s = skillMap.get(tskill.Skill_Name__c);
					if (s != null) {
						tskill.Skill__c = s.Id;
					}
				}
			}
			update trainedSKillList;
		}

		// Build the list of completed training with the trained skills
		List<CompletedTrainingWithTrainedSkills> completedTrainingWithTrainedSkillsList = new List<CompletedTrainingWithTrainedSkills>();
		Map<String, Boolean> newerCompletedTrainingExists = new Map<String, Boolean>();
		for (FS_CompletedTraining__c completedTraining :completedTrainingList) {
			for (FS_TrainedSkill__c trainedSkill :trainedSKillList) {
				if (completedTraining.Training_Course__c == trainedSkill.Related_Training_Course__c) {
					String extId = completedTraining.Related_Technician__c + '-' + trainedSkill.Skill__c;
					if (newerCompletedTrainingExists.get(extId) != true) {
						newerCompletedTrainingExists.put(extId, true);

						System.debug('Adding CompletedTrainingWithTrainedSkills');
						CompletedTrainingWithTrainedSkills completedTrainingWithSkills = new CompletedTrainingWithTrainedSkills(
								completedTraining.Training_Course__c, completedTraining.Training_Course__r.Name,
								completedTraining.Related_Technician__c, completedTraining.Related_Technician__r.Name,
								completedTraining.Completion_Date__c, trainedSkill.Skill__c, trainedSkill.Skill_Name__c,
								completedTraining.Training_Course__r.Activity_Type__c);

						completedTrainingWithTrainedSkillsList.add(completedTrainingWithSkills);
					} else {
						System.debug('A newer Trained Skill for this Technician was already found');
					}
				}
			}
		}

		System.debug('completedTrainingWithTrainedSkillsList: ' + completedTrainingWithTrainedSkillsList);

		// Get the list of Exteral Ids for the the Experience records
		Set<String> experienceExtIds = new Set<String>();
		for (CompletedTrainingWithTrainedSkills compTrainWithTrainSkills :completedTrainingWithTrainedSkillsList) {
			experienceExtIds.add(compTrainWithTrainSkills.technicianId + '-' + compTrainWithTrainSkills.skillId);
		}
		System.debug('experienceExtIds: ' + experienceExtIds);

		// Query any existing Experience records where External Id matches the tech-skill values of the completedTrainingWithTrainedSkillsList
		List<FS_Experience__c> existingExperienceList = [
				SELECT Id, External_Key__c, Trained_Activity_Types__c
				FROM FS_Experience__c
				WHERE External_Key__c IN :experienceExtIds
		];

		// Create a Map of Experience Ext Ids to Activity Type so we can use it for comparison later
		Map<String, String> expExtIdToActivityTypeMap = new Map<String, String>();
		for (FS_Experience__c exp :existingExperienceList) {
			expExtIdToActivityTypeMap.put(exp.External_Key__c, exp.Trained_Activity_Types__c);
		}
		System.debug('expExtIdToActivityTypeMap: ' + expExtIdToActivityTypeMap);

		// Create the list of Experience records that will need to be inserted/updated
		List<FS_Experience__c> experienceList = new List<FS_Experience__c>();
		for (CompletedTrainingWithTrainedSkills completedTrainingWithTrainedSkills :completedTrainingWithTrainedSkillsList) {
			FS_Experience__c experience = new FS_Experience__c();
			String extId = completedTrainingWithTrainedSkills.technicianId + '-' + completedTrainingWithTrainedSkills.skillId;
			experience.External_Key__c = extId;
			experience.Related_Skill__c = completedTrainingWithTrainedSkills.skillId;
			experience.Technician__c = completedTrainingWithTrainedSkills.technicianId;

			// Get the Union of the Training Activity Types and the Experience Activity Types
			Set<String> previousActivityTypeList = FS_ExperienceManager.splitValues(expExtIdToActivityTypeMap.get(extId));
			Set<String> trainedActivityTypeList = FS_ExperienceManager.splitValues(completedTrainingWithTrainedSkills.activityType);
			System.debug('previousActivityTypeList: ' + previousActivityTypeList);
			System.debug('trainedActivityTypeList: ' + trainedActivityTypeList);

			String combinedActivityTypeString =
					FS_ExperienceManager.combineActivityTypes(previousActivityTypeList, trainedActivityTypeList);
			System.debug('combinedActivityTypeString: ' + combinedActivityTypeString);
			experience.Trained_Activity_Types__c = combinedActivityTypeString;

			System.debug('experience technician ID: ' + experience.Technician__c);

			// Find the Training Score Range for these Completed Trainings
			for (TrainingScoreRange trainingScoreRange :trainingScoreRangeList) {
				Date startDT = Date.today().addMonths(-trainingScoreRange?.maxMonths);
				Date endDT = Date.today().addMonths(-trainingScoreRange?.minMonths);

				if (completedTrainingWithTrainedSkills.completionDate < endDT &&
						(startDT == null || completedTrainingWithTrainedSkills.completionDate > startDT)) {
					experience.Training_Score__c = trainingScoreRange.trainingScore;
					System.debug('Found a Match for the trainingScoreRange: ' + trainingScoreRange.trainingScore);
					break; // We found the match so break out of the loop
				}
			}

			experienceList.add(experience);
		}
		System.debug('experienceList: ' + experienceList.size() + '  :' + experienceList);

		// Create the new or update the old Experience records
		if (!experienceList.isEmpty())
		{
			System.debug('Upserting Experience records: ' + experienceList + '  size: ' + experienceList.size());
			upsert experienceList External_Key__c;
		}

		// Zero out the expired Experience records for these Technicians (ones without recent Work scores)
		List<FS_Experience__c> expired = [SELECT Id, Training_Score__c
			FROM FS_Experience__c WHERE Technician__c IN :techIds
				AND External_Key__c NOT IN :experienceExtIds];
		if (expired.isEmpty()) {
			return;
		}

		for (FS_Experience__c e : expired) {
			e.Training_Score__c = 0;
		}
		update expired;
	}

	public void finish(Database.BatchableContext ctx) {
		System.debug('Finishing: ExpertiseTrainExperience_Batch');
		if (!Test.isRunningTest()) {
			FS_ExpertiseFieldExperience_Batch next = new FS_ExpertiseFieldExperience_Batch();
			next.execute(null); // mimic the Schedulable method
		}
	}
}