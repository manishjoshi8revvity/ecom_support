@IsTest
private class FS_Expertise_UT {
    @IsTest
    static void testExpertiseManagementDashboard() {
        OperatingHours hours = FS_TestDataFactory.createDefaultOperatingHours();
        // create test data
        User user1 = new User(Id = UserInfo.getUserId());
        ServiceResource  tech1 = FS_TestDataFactory.createTestTechnician('Team1', user1, 'Tech1', 'US12', 'LOC123', 'WC123');

        List<Schema.Skill> skills = FS_TestDataFactory.loadTestSkills(2);
        Schema.Skill skill1 = skills[0];
        Schema.Skill skill2 = skills[1];

        ServiceTerritory terr1 = FS_TestDataFactory.createTestTerritory('North America', 'Territory', null, hours);
        ServiceTerritory terr2 = FS_TestDataFactory.createTestTerritory('United States', 'Sub Territory', terr1.Id, hours);

        FS_Experience__c experience1 = FS_TestDataFactory.createTestExperience(tech1.Id, skill1.Id, 1, 5);
        FS_Experience__c experience2 = FS_TestDataFactory.createTestExperience(tech1.Id, skill2.Id, null, 1);

        // since a SOSL query is used by the searchTechSkills method we have to setup a fixed search result
        Id [] fixedSearchResults= new Id[3];
        fixedSearchResults[0] = tech1.Id;
        fixedSearchResults[1] = terr1.Id;
        fixedSearchResults[2] = skill1.Id;
        //Required so SOSL will fire in Unit Tests Properly
        Test.setFixedSearchResults(fixedSearchResults);

        // test dashboard functions
        Test.startTest();
        List<FS_CustomLookupService.LookupSearchResult> searchTechSkills1 = FS_ExpertiseManagementDashboard.searchTechSkills('Tech1', new List<String>{terr1.Id, skill1.Id});
        System.debug('searchTechSkills1: ' + searchTechSkills1);
        System.assertEquals(1, searchTechSkills1.size(), 'Failed to find Tech1 technician');

        List<FS_CustomLookupService.LookupSearchResult> searchTechSkills2 = FS_ExpertiseManagementDashboard.searchTechSkills('North Am', new List<String>{tech1.Id, skill1.Id});
        System.debug('searchTechSkills2: ' + searchTechSkills2);
        System.assertEquals(1, searchTechSkills2.size(), 'Failed to find "North Am" territory');

        List<FS_CustomLookupService.LookupSearchResult> searchTechSkills3 = FS_ExpertiseManagementDashboard.searchTechSkills(skill1.MasterLabel, new List<String>{tech1.Id, terr1.Id});
        System.debug('searchTechSkills3: ' + searchTechSkills3);
        System.assertEquals(false, searchTechSkills3.isEmpty(), 'Failed to find skill');

        List<FS_ExpertiseManagementDashboard.TechSkillHierarchyWrapper> buildTechSkillsTableFromSearch =
                FS_ExpertiseManagementDashboard.buildTechSkillsTableFromSearch(
                new List<String>{tech1.Id, terr1.Id, skill1.Id}, 0.0, 5.0, new List<String>{'training', 'field', 'expertise'}, new List<String>());
        //System.debug('buildTechSkillsTableFromSearch: ' + buildTechSkillsTableFromSearch);
        //System.assertEquals(1, buildTechSkillsTableFromSearch.size(), 'Failed to build the tech skills table');

        String techSkillKey = tech1.Id + '-' + skill1.Id;
        String createExpertise = FS_ExpertiseManagementDashboard.createExpertise(techSkillKey, 4);
        List<ServiceResourceSkill> expertiseList1 = [SELECT Id FROM ServiceResourceSkill];
        //System.debug('expertiseList1: ' + expertiseList1);
        //System.debug('createExpertise: ' + createExpertise);
        //System.assertEquals('Created the Expertise', createExpertise, 'Failed to create expertise record');*/

        String createExpertise2 = FS_ExpertiseManagementDashboard.createExpertise( techSkillKey, 3);
        /*List<ServiceResourceSkill> expertiseList2 = [SELECT Id FROM ServiceResourceSkill];
        System.debug('expertiseList2: ' + expertiseList2);
        System.debug('createExpertise2: ' + createExpertise2);
        System.assertEquals('Created the Expertise', createExpertise2, 'Failed to update expertise record');*/

        List<FS_Experience__c> experienceList1 = [SELECT Id, Final_Score__c FROM FS_Experience__c WHERE Id = :experience1.Id];
        experience1.Field_Score__c = 2;
        //experience1.Related_Expertise__c = expertiseList2[0].Id;
        update experience1;
        List<FS_Experience__c> experienceList2 = [SELECT Id, Final_Score__c FROM FS_Experience__c WHERE Id = :experience1.Id];
        //System.assertNotEquals(experienceList1[0].BD_Final_Score__c, experienceList2[0].BD_Final_Score__c, 'Failed to update experience Final Score');

        String removeExpertise = FS_ExpertiseManagementDashboard.removeExpertise(techSkillKey, expertiseList1[0].Id);
        //System.debug('removeExpertise: ' + removeExpertise);
        //System.assertEquals('Deleted the Expertise', removeExpertise, 'Failed to delete expertise record');

        // added for coverage of trigger handler events that have not code
        delete experience1;

        Test.stopTest();
    }

//    @IsTest(SeeAllData=true)
//    static void testGetReportId() {
//
//        // Need to check these in a separate method with SeeAllData=True to check if the reports actually exist
//        Id getReportId1 = FS_ExpertiseManagementDashboard.getReportId('trainingReport');
//        System.assert(getReportId1 != null, 'Expertise_Mgmt_Tech_and_Field_Exp_zpU report does not exist');
//
//        Id getReportId2 = FS_ExpertiseManagementDashboard.getReportId('fieldReport');
//        System.assert(getReportId1 != null, 'Expertise_Mgmt_Field_Experience_wJw report does not exist');
//    }

    // Test class for SMAX_PS_ExpertiseFieldExperience_Batch
    @IsTest
    static void testExpertiseFieldExperience_Batch() {
         FS_TestDataFactory.createDefaultOperatingHours();
        // create test data
        Account acct = FS_TestDataFactory.createTestAccount('Mystery Machine Inc', 'ACC123');
    
        Contact cont = FS_TestDataFactory.createTestContact('Scooby', 'Doo', acct, 'CON123');
        Product2 pd = FS_TestDataFactory.createTestProduct('Scooby Snacks', 'PRD123','AA');
        Schema.Location loc = FS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
        Asset ip = FS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);
        User user1 = new User(Id = UserInfo.getUserId());
        ServiceResource tech1 = FS_TestDataFactory.createTestTechnician('Team1', user1, 'Tech1', 'US12', 'LOC123', 'WC123');
        Schema.Skill skill1 = FS_TestDataFactory.loadTestSkills(1)[0];

        WorkOrder wo1 = FS_TestDataFactory.createWO(ip,cont);
        wo1.Completed_Date_Time__c = Datetime.now().addMonths(-1);
        //wo1.SVMXC__Group_Member__c = tech1.Id;
        wo1.ModelSeries__c = skill1.Masterlabel;
       // wo1.SVMXC__Skill__c = skill1.Id;
        update wo1;

        WorkOrder wo2 = FS_TestDataFactory.createWO(ip,cont);
        wo2.Completed_Date_Time__c = Datetime.now().addMonths(-11);
       // wo2.SVMXC__Group_Member__c = tech1.Id;
        wo2.ModelSeries__c = skill1.Masterlabel;
        //wo2.SVMXC__Skill__c = skill1.Id;
        update wo2;

        ServiceAppointment appt1 = new ServiceAppointment();
        appt1.Assigned_Resource__c = tech1.Id;
        appt1.ParentRecordId = wo1.Id;
        appt1.SFS_Work_Order__c = wo1.Id;

        ServiceAppointment appt2 = new ServiceAppointment();
        appt2.Assigned_Resource__c = tech1.Id;
        appt2.ParentRecordId = wo2.Id;
        appt2.SFS_Work_Order__c = wo2.Id;
        insert new List<ServiceAppointment> { appt1, appt2 };

        Test.startTest();

        // run batch job
        FS_ExpertiseFieldExperience_Batch batch = new FS_ExpertiseFieldExperience_Batch();
        Database.executeBatch(batch);

        Test.stopTest();

        // assert experience records for field scores were correctly inserted/updated
        List<FS_Experience__c> experienceList = [SELECT Id, External_Key__c, Work_Total__c, Field_Score__c, Training_Score__c, Final_Score__c FROM FS_Experience__c];
        System.debug('experienceList: ' + experienceList);
        System.assertEquals(true, experienceList[0].Work_Total__c > 0, 'Work Total was not updated');
    }

    // Test class for SMAX_PS_ExpertiseTrainExperience_Batch
    @IsTest
    static void testExpertiseTrainExperience_Batch() {

        // create test data
        User user1 = new User(Id = UserInfo.getUserId());
        ServiceResource tech1 = FS_TestDataFactory.createTestTechnician('Team1', user1, 'Tech1', 'US12', 'LOC123', 'WC123');
        FS_TrainingCourse__c trainingCourse1 = FS_TestDataFactory.createTestTrainingCourse('TrainingCourse1', 'ALL');
        FS_CompletedTraining__c completedTraining1 = FS_TestDataFactory.createTestCompletedTraining(tech1.Id, trainingCourse1.Id, Date.today().addMonths(-1));
        Schema.Skill skill1 = FS_TestDataFactory.loadTestSkills(1)[0];
        FS_TrainedSkill__c trainedSkill1 = FS_TestDataFactory.createTestTrainedSkill(skill1.Id, trainingCourse1.Id);


        Test.startTest();

        // run batch job
        FS_ExpertiseTrainExperience_Batch batch = new FS_ExpertiseTrainExperience_Batch();
        Database.executeBatch(batch);

        Test.stopTest();

        // assert experience records for training scores were correctly inserted/updated
        List<FS_Experience__c> experienceList = [SELECT Id, External_Key__c, Work_Total__c, Field_Score__c, Training_Score__c, Final_Score__c
        FROM FS_Experience__c];
        System.debug('experienceList: ' + experienceList);
        System.assertEquals(true, experienceList[0].Training_Score__c > 0, 'Training Score was not updated');
    }

    // 11/30/2022 ITSVMX-1057 Expertise Management Dashboard Updates - Create Experience records for all existing Expertise records
    @IsTest
    static void testExpertiseCleanup_Batch() {

        // create test data
        User user1 = new User(Id = UserInfo.getUserId());
        ServiceResource tech1 = FS_TestDataFactory.createTestTechnician('Team1', user1, 'Tech1', 'US12', 'LOC123', 'WC123');
        List<Schema.Skill> skills = FS_TestDataFactory.loadTestSkills(2);
        Schema.Skill skill1 = skills[0];
        Schema.Skill skill2 = skills[1];

        ServiceResourceSkill exp1 = FS_TestDataFactory.createTestExpertise(tech1, skill1);
        //ServiceResourceSkill exp1a = FS_TestDataFactory.createTestExpertise(tech1, skill1);
        ServiceResourceSkill exp2 = FS_TestDataFactory.createTestExpertise(tech1, skill2);

        FS_Experience__c experience1 = FS_TestDataFactory.createTestExperience(tech1.Id, skill2.Id, 10, 5);

        Test.startTest();

        // run batch job
        new FS_ExpertiseToExperience_Batch().execute(null);

        Test.stopTest();

        // assert experience records for training scores were correctly inserted/updated
        List<ServiceResourceSkill> expertiseList = [SELECT Id, Expertise_External_ID__c FROM ServiceResourceSkill];
        System.debug('expertiseList: ' + expertiseList);
        System.assertEquals(2, expertiseList.size());

        List<FS_Experience__c> experienceList = [SELECT Id, Name, External_Key__c FROM FS_Experience__c];
        System.debug('experienceList: ' + experienceList);
        System.assertEquals(2, experienceList.size());
    }
}