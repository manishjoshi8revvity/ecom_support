/**
 * Created by frankvanloon on 7/15/24.
 */
@IsTest
public class FS_WorkOrderEmails_UT {

	@TestSetup
	static void setupTest() {
		FS_TestDataFactory.createDefaultOperatingHours();
		C_SET_6800_WO_EMAIL_DOCUMENTS__c settings = C_SET_6800_WO_EMAIL_DOCUMENTS__c.getOrgDefaults();
		settings.Last_Run_Time__c = Datetime.now().addMinutes(-1);
		settings.Save_Send_Email_as_Activity__c = true;
		settings.Send_To_Default_Email_Address__c = true;
		settings.Default_Email_Address__c = 'default.test@revvity.com.invalid';
		settings.Default_Org_Wide_Address__c = [SELECT Id FROM OrgWideEmailAddress LIMIT 1].Id;
		insert settings;
	}

	@IsTest
	static void testEmailJob() {
		FS_Translation__c t1 = FS_TestDataFactory.createTestTranslation('English (US)', 'US');
		Account acct = FS_TestDataFactory.createTestErpAccount('PkiTest', 999, 'TESTX000000001','US');
		Contact cont = FS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
		Product2 pd = FS_TestDataFactory.createTestProduct('TestProduct', '106018','ZZZ');
		Schema.Location loc = FS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
		loc.Country__c = 'US';
		update loc;

		Asset ip = FS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);
		WorkOrder wo = FS_TestDataFactory.createWO(ip, cont);

		Test.startTest();

		WorkOrder woResult = [SELECT Id, WorkOrderNumber, CountryCode, ServiceDocumentTemplate, Translation__c
			FROM WorkOrder WHERE Id = :wo.Id];
		System.debug('EMAIL WO: ' + woResult);

		System.assertNotEquals(null, woResult.Translation__c);
		System.assertNotEquals(null, woResult.ServiceDocumentTemplate);

		ServiceReport rpt = FS_TestDataFactory.createTestServiceReport(wo.Id, woResult.ServiceDocumentTemplate, 'TESTING_SVC_REPORT');

		// Update the WO Email fields..
		wo.ES_Send_Service_Report_To_Cust__c = true;
		wo.ES_Email_To_Customer__c = 'customer.test@revvity.com.invalid';
		wo.ES_Send_Service_Report_To_Owner__c = true;
		wo.ES_Send_Service_ReportTo_Contact__c = true;
		wo.Contact_Email__c = 'contact.test@revvity.com.invalid';
		wo.ES_Cc_Additional_People__c = true;
		wo.ES_Cc_Email_Additional_People__c = 'additional.test@revvity.com.invalid';
		update wo;

		FS_WorkOrderEmails.scheduleEmailJobs();
		new FS_WorkOrderEmails().execute(null);

		Test.stopTest();

		// Validate the Task/Activity?

		List<Task> results = [SELECT Id, Type, Subject FROM Task WHERE WhatId = :wo.Id AND Type = 'Email'];
		System.assertEquals(1, results.size());
	}
}