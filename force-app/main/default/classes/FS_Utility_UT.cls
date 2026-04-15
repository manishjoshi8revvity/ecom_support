/**
 * Created by frankvanloon on 7/15/24.
 */
@IsTest
public class FS_Utility_UT {

	@IsTest
	static void test_isFirstRun() {

		Boolean result1 = FS_Utility.isFirstRun('WO1');
		System.assertEquals(true, result1);

		Boolean result2 = FS_Utility.isFirstRun('WO1');
		System.assertEquals(false, result2);

		FS_Utility.clearCache();

		Boolean result3 = FS_Utility.isFirstRun('WO1');
		System.assertEquals(true, result3);

		FS_Utility.reset('WO1');

		Boolean result4 = FS_Utility.isFirstRun('WO1');
		System.assertEquals(true, result4);
	}

	@IsTest
	static void test_MultiSelectController() {

		FS_TestDataFactory.createDefaultOperatingHours();
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

		PageReference pageRef = Page.FS_cancelAppointmentAction;
		Test.setCurrentPage(pageRef);

		// put the lead id as a parameter
		String apptIds = appt1.Id + ',' + appt2.Id;
		ApexPages.currentPage().getParameters().put('services', apptIds);

		FS_MultiSelectController ctrl = new FS_MultiSelectController(null);

		Test.stopTest();
	}
}