public with sharing class FS_ExperienceManager {

    public static void syncSkills(List<FS_Experience__c> newList, Map<Id, FS_Experience__c> oldMap) {
        Set<Id> skillIds = new Set<Id>();
        Set<String> skillNames = new Set<String>();
        for (FS_Experience__c exp : newList) {
            if (String.isNotBlank(exp.Related_Skill__c) && String.isBlank(exp.Related_Skill_Name__c)) {
                skillIds.add(exp.Related_Skill__c);
            } else if (String.isBlank(exp.Related_Skill__c) && String.isNotBlank(exp.Related_Skill_Name__c)) {
                skillNames.add(exp.Related_Skill_Name__c);
            }
        }

        if (!skillIds.isEmpty()) {
            Map<Id, Skill> skillMap = new Map<Id, Skill>([SELECT Id, MasterLabel FROM Skill WHERE Id IN :skillIds]);
            for (FS_Experience__c exp : newList) {
                if (String.isNotBlank(exp.Related_Skill__c) && String.isBlank(exp.Related_Skill_Name__c)) {
                    Skill s = skillMap.get(exp.Related_Skill__c);
                    if (s != null) {
                        exp.Related_Skill_Name__c = s.MasterLabel;
                    }
                }
            }
        }

        if (!skillNames.isEmpty()) {
            Map<String, Skill> skillMap = new Map<String, Skill>();
            for (Skill s : [SELECT Id, MasterLabel FROM Skill WHERE MasterLabel IN :skillNames]) {
                skillMap.put(s.MasterLabel, s);
            }
            for (FS_Experience__c exp : newList) {
                if (String.isBlank(exp.Related_Skill__c) && String.isNotBlank(exp.Related_Skill_Name__c)) {
                    Skill s = skillMap.get(exp.Related_Skill_Name__c);
                    if (s != null) {
                        exp.Related_Skill__c = s.Id;
                    }
                }
            }
        }
    }

    // Called from beforeInsert and beforeUpdate
    public static void updateFinalScore(List<FS_Experience__c> newList, Map<Id, FS_Experience__c> oldMap)
    {
        if (!FS_Utility.isActive('Update Final Score', 'Update the Final Score in Experience.')) {
            return;
        }

        Map<String, Integer> scoresToFinalMap = new Map<String, Integer>();

        Map<String, C_META_FS_Experience_Setting__mdt> experienceMdtMap = C_META_FS_Experience_Setting__mdt.getAll();
        for(String experienceMdtKey : experienceMdtMap.keySet()) {

            //System.debug('Experience MDT: ' + experienceMdtMap.get(experienceMdt));
            C_META_FS_Experience_Setting__mdt experienceSetting = experienceMdtMap.get(experienceMdtKey);

            if (experienceSetting.Type__c == 'Final') {

                scoresToFinalMap.put((Integer) experienceSetting.Field_Score__c + '-' + (Integer) experienceSetting.Training_Score__c,
                        (Integer) experienceSetting.Score__c);
            }
        }
        System.debug('scoresToFinalMap: ' + scoresToFinalMap);

        if (scoresToFinalMap.size() == 0) {
            System.debug('No Experience Setting Custom Metadata Types have been set up for the "Final" type.');
            return;
        }

        Map<Id, ServiceResourceSkill> allExpertise = new Map<Id, ServiceResourceSkill>();
        Map<Id, FS_Experience__c> expertiseExperienceMap = new Map<Id, FS_Experience__c>();
        Map<String, FS_Experience__c> expExtIdMap = new Map<String, FS_Experience__c>();

        for (FS_Experience__c exp : newList) {

            Integer fieldScore = (exp.Field_Score__c == null) ? 0 : (Integer) exp.Field_Score__c;
            Integer trainingScore = (exp.Training_Score__c == null) ? 0 : (Integer) exp.Training_Score__c;

            System.debug('exp.BD_Field_Score__c: [' + exp.Field_Score__c
                    + ']  exp.BD_Training_Score__c: [' + exp.Training_Score__c + ']');
            FS_Experience__c old = (oldMap == null) ? null : oldMap.get(exp.Id);
            if (old == null || exp.Related_Expertise__c == null ||
                (old.Field_Score__c != exp.Field_Score__c
                    || old.Training_Score__c != exp.Training_Score__c
                    || old.Trained_Activity_Types__c != exp.Trained_Activity_Types__c
                    || old.Worked_Activity_Types__c != exp.Worked_Activity_Types__c
                    || old.Related_Expertise__c != exp.Related_Expertise__c))
            {
                exp.Final_Score__c = scoresToFinalMap.get(fieldScore + '-' + trainingScore);
                System.debug('exp.BD_Final_Score__c: ' + exp.Final_Score__c);
                if (exp.Related_Expertise__c != null) {
                    expertiseExperienceMap.put(exp.Related_Expertise__c, exp);
                } else {
                    // ITSVMX-531: Try to link the Expertise (if it exists)...
                    expExtIdMap.put(exp.External_Key__c, exp);
                }
            }
        }

        // Try to link existing Expertise records when not already linked...
        if (!expExtIdMap.isEmpty()) {
            List<ServiceResourceSkill> existingExpertiseList = [
                    SELECT Id, SkillLevel, Activity_Type__c, Expertise_External_ID__c
                    FROM ServiceResourceSkill
                    WHERE Expertise_External_ID__c IN :expExtIdMap.keySet()
            ];
            System.debug('existingExpertiseList: ' + existingExpertiseList.size() + '  :' + existingExpertiseList);

            if (!existingExpertiseList.isEmpty()) {
                for (ServiceResourceSkill expertise : existingExpertiseList) {
                    FS_Experience__c exp = expExtIdMap.get(expertise.Expertise_External_ID__c);
                    exp.Related_Expertise__c = expertise.Id;
                    mapExperienceToExpertise(exp, expertise);

                    allExpertise.put(expertise.Id, expertise);
                }
                update existingExpertiseList;
            }

            // Should we auto-create the Expertise?
            Map<String, FS_Experience__c> expToCreateMap = new Map<String, FS_Experience__c>();
            Set<Id> techIds = new Set<Id>();
            for (FS_Experience__c exp : expExtIdMap.values()) {
                if (exp.Related_Expertise__c == null && exp.Training_Score__c != null && exp.Training_Score__c > 0
                        && exp.Expertise_Removed__c == false) {
                    expToCreateMap.put(exp.External_Key__c, exp);
                    techIds.add(exp.Technician__c);
                }
            }

            // ITSVMX-531: Auto-Create Expertise...
            if (!expToCreateMap.isEmpty()) {
                Map<Id, ServiceResource> techMap = new Map<Id, ServiceResource>(
                    [SELECT Id, Name, ServiceCrewId
                        FROM ServiceResource WHERE Id IN :techIds]);

                List<ServiceResourceSkill> newExpertise = new List<ServiceResourceSkill>();
                for (FS_Experience__c exp : expToCreateMap.values()) {
                    ServiceResourceSkill expertise = new ServiceResourceSkill();
                    expertise.ServiceResourceId = exp.Technician__c;
                    ServiceResource tech = techMap.get(exp.Technician__c);
                    if (tech != null) {
                        expertise.ServiceResourceId = tech.id;
                    }
                    expertise.SkillId = exp.Related_Skill__c;
                    expertise.Expertise_External_ID__c = exp.External_Key__c;
                    expertise.EffectiveStartDate = Datetime.now();
                    mapExperienceToExpertise(exp, expertise);
                    newExpertise.add(expertise);
                }

                insert newExpertise;

                for (ServiceResourceSkill expertise : newExpertise) {
                    FS_Experience__c exp = expToCreateMap.get(expertise.Expertise_External_ID__c);
                    exp.Related_Expertise__c = expertise.Id;

                    allExpertise.put(expertise.Id, expertise);
                }
            }
        }

        // Update any pre-associated Expertise records Skill Level values with the Final Score
        if (!expertiseExperienceMap.isEmpty()) {
            List<ServiceResourceSkill> updateExpertiseList = [
                    SELECT Id, SkillLevel, Activity_Type__c
                    FROM ServiceResourceSkill
                    WHERE Id IN: expertiseExperienceMap.keySet()
            ];
            System.debug('updateExpertiseList: ' + updateExpertiseList.size() + '  :' + updateExpertiseList);

            for (ServiceResourceSkill expertise :updateExpertiseList) {
                FS_Experience__c exp  = expertiseExperienceMap.get(expertise.Id);
                mapExperienceToExpertise(exp, expertise);

                allExpertise.put(expertise.Id, expertise);
            }
            update updateExpertiseList;
        }

        // Update Recommendations (always)...
        for (FS_Experience__c exp : newList) {
            ServiceResourceSkill expertise = (exp.Related_Expertise__c == null)
                    ? null : allExpertise.get(exp.Related_Expertise__c);
            exp.Recommended_Action__c = recommendAction(exp, expertise);
        }
    }

    private static void mapExperienceToExpertise(FS_Experience__c exp, ServiceResourceSkill expertise) {
        expertise.SkillLevel = exp.Final_Score__c;

        String trainedActTypes = (exp.Trained_Activity_Types__c == null) ? '' : exp.Trained_Activity_Types__c;
        Set<String> trainedActivityTypeList = new Set<String>(trainedActTypes.split(';'));
        String workedActTypes = (exp.Worked_Activity_Types__c == null) ? '' : exp.Worked_Activity_Types__c;
        Set<String> workedActivityTypeList = new Set<String>(workedActTypes.split(';'));
        expertise.Activity_Type__c = combineActivityTypes(trainedActivityTypeList, workedActivityTypeList);
    }

    private static String recommendAction(FS_Experience__c exp, ServiceResourceSkill expertise) {
        if (exp.Final_Score__c >= 3 && exp.Related_Expertise__c == null) {
            return 'Create Expertise';
        } else if (exp.Final_Score__c <= 1 && exp.Related_Expertise__c != null) {
            return 'Remove Expertise';
        } else if (expertise != null) {
            // Determine if Activity Types need to be synced.. if so, set to: 'Update Activity Types'
        }
        return 'None';
    }

    private static Map<String, List<String>> actTypeMap = new Map<String, List<String>>();

    /*
        Lookup the "Skill Activity Type" (PM, OQ, REP) from the WO Order Type
        NOTE: It is very possible that this will return null, as there are many values that do not map
        ITSVMX-531 Needed for the "Worked Activity Types"
     */
    public static String lookupSkillActivityType(String orderType) {

        if (actTypeMap.isEmpty()) {
            Map<String, C_META_FS_Experience_Setting__mdt> experienceMdtMap = C_META_FS_Experience_Setting__mdt.getAll();
            for(String key : experienceMdtMap.keySet()) {
                C_META_FS_Experience_Setting__mdt expMeta = experienceMdtMap.get(key);
                if (expMeta.Type__c == 'ActivityType') {
                    String actType = expMeta.DeveloperName.replace('ActivityType_', ''); // REP, PM, OQ
                    List<String> lstOrderTypes = new List<String>();
                    for (String ordType : expMeta?.Order_Types__c.split(',')) {
                        lstOrderTypes.add(ordType.trim());
                    }
                    actTypeMap.put(actType, lstOrderTypes);
                }
            }
        }

        for (String actType : actTypeMap.keySet()) {
            List<String> orderTypes = actTypeMap.get(actType);
            if (orderTypes.contains(orderType)) {
                return actType;
            }
        }

        return null;
    }

    public static String combineActivityTypes(Set<String> set1, Set<String> set2) {
        Set<String> combinedSet = new Set<String>(set1);

        // 9/21/21 Tony - fixed production issue where set2 is returned with a null value but not handled
        if (set2 != null) {
            combinedSet.addAll(set2);
        }

        String result = '';
        for (String activityType : combinedSet) {
            result = result + activityType + ';';
        }
        if (result.contains(';')) {
            result = result.substringBeforeLast(';');
        }
        return result;
    }

    public static Set<String> splitValues(String val)
    {
        return (val == null) ? new Set<String>() : new Set<String>(val.split(';'));
    }
}