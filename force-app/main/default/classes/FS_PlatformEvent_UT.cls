/**
 * Created by frankvanloon on 7/12/24.
 */
@IsTest
public class FS_PlatformEvent_UT {

	@IsTest
	static void testEventUtility() {

		FS_TestDataFactory.createDefaultOperatingHours();
		
		Account acct = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
		Contact c = FS_TestDataFactory.createTestContact('Testie', 'Testerson', acct, 'TEST000000101');
		Schema.Location loc = FS_TestDataFactory.createTestLocation(acct, 'Test Location', 'TESTLOC001', 'LOC123');
		Asset ip = FS_TestDataFactory.createIP('TESTX0000234001', acct, loc, 'TSTM001');
		WorkOrder wo = FS_TestDataFactory.createWO(ip, c);

		List<FS_WorkOrder_Event__e> events = new List<FS_WorkOrder_Event__e>();

		FS_WorkOrder_Event__e e1 = new FS_WorkOrder_Event__e();
		e1.Action__c = 'TEST';
		e1.WorkOrderId__c = wo.Id;
		events.add(e1);

		FS_WorkOrder_Event__e e2 = new FS_WorkOrder_Event__e();
		e2.Action__c = 'TEST';
		e2.WorkOrderId__c = wo.Id;
		e2.SAP_DMR_Number__c = 'This value is too long and it should throw an exception.';
		events.add(e2);

		Test.startTest();

		FS_PlatformEventUtility.publishEvents(events, 'WorkOrderId__c', 'Action__c');

		List<FS_PlatformEventAction.PlatformEventRequest> getRQs = new List<FS_PlatformEventAction.PlatformEventRequest>();
		FS_PlatformEventAction.PlatformEventRequest rq1 = new FS_PlatformEventAction.PlatformEventRequest();
		rq1.evt = e1;
		getRQs.add(rq1);

		List<FS_PlatformEventAction.PlatformEventResult> getRSs =
				FS_PlatformEventAction.getPlatformEventDetails(getRQs);
		System.assertEquals(1, getRSs.size());
		System.assertEquals(false, String.isBlank(getRSs[0].eventJSON));

		Test.stopTest();

		List<FS_PlatformEventLog__c> logs = [SELECT Id, Name, Error_Message__c, Event_JSON__c,
				Platform_Event_Type__c, Related_Element_Id__c, Action__c
			FROM FS_PlatformEventLog__c WHERE Action__c = 'TEST'];

		System.debug('Found Event Logs: ' + logs);
		System.assertEquals(true, logs.size() > 0);

		FS_PlatformEventResendAction.PlatformEventResendRequest resendRQ =
				new FS_PlatformEventResendAction.PlatformEventResendRequest();
		resendRQ.eventLogId = logs[0].Id;

		FS_PlatformEventResendAction.resendPlatformEvent(new List<FS_PlatformEventResendAction.PlatformEventResendRequest> { resendRQ });

		FS_PlatformEventUtility.resendEvent(logs[0].Name);
	}
}