/**
 * Created by frankvanloon on 6/24/24.
 */

public with sharing class FS_ExpertiseToExperience_Batch implements Database.Batchable<SObject>, Schedulable, Database.Stateful {

	public void execute(SchedulableContext ctx) {
		FS_ExpertiseToExperience_Batch batch = new FS_ExpertiseToExperience_Batch();
		Database.executeBatch(batch, 10);
	}

	public Database.QueryLocator start(Database.BatchableContext ctx) {
		// Query Technicians
		return Database.getQueryLocator([SELECT Id, Name FROM ServiceResource]);
	}

	public void execute(Database.BatchableContext ctx, List<ServiceResource> techs) {

		List<ServiceResourceSkill> expertiseList = [SELECT Id, SkillNumber, Expertise_External_ID__c,
				SkillId, fxSkill_Name__c, ServiceResourceId
			FROM ServiceResourceSkill
			WHERE ServiceResourceId IN :techs];
		Map<String, ServiceResourceSkill> expertiseMap = new Map<String, ServiceResourceSkill>();
		for (ServiceResourceSkill expertise : expertiseList) {
			if (String.isBlank(expertise.Expertise_External_ID__c)) {
				expertise.Expertise_External_ID__c = expertise.ServiceResourceId + '-' + expertise.SkillId;
			}
			expertiseMap.put(expertise.Expertise_External_ID__c, expertise);
		}
		Database.update(expertiseList, false);

		List<FS_Experience__c> experienceList = [SELECT Id, Name, External_Key__c,
				Related_Skill__c, Related_Skill_Name__c, Technician__c, Related_Expertise__c
			FROM FS_Experience__c
			WHERE Technician__c IN :techs];
		Map<String, FS_Experience__c> experienceMap = new Map<String, FS_Experience__c>();
		for (FS_Experience__c experience : experienceList) {
			experienceMap.put(experience.External_Key__c, experience);
		}

		for (String expKey : expertiseMap.keySet()) {
			ServiceResourceSkill expertise = expertiseMap.get(expKey);
			FS_Experience__c experience = experienceMap.get(expKey);
			if (experience == null) {
				experience = new FS_Experience__c();
				experience.External_Key__c = expKey;
				experience.Related_Skill__c = expertise.SkillId;
				experience.Related_Skill_Name__c = expertise.fxSkill_Name__c;
				experience.Technician__c = expertise.ServiceResourceId;
				experienceMap.put(expKey, experience);
			}
			experience.Related_Expertise__c = expertise.Id;
		}

		Database.upsert(experienceMap.values(), FS_Experience__c.Fields.External_Key__c, false);
	}

	public void finish(Database.BatchableContext ctx) {
	}

}