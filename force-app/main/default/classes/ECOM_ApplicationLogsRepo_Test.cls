/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*
*
* 2. Description - This is a test class for ECOM_ApplicationLogsRepo
*
* 3. Objects referenced
*    - ECOM_Application_Log

* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
* 	 - ECOM_TestUtil
*
* 6. Test Class Name:
*
* 7. Is @Invocable : No
*
* 8. Author Name(s):
*    - Vasudev R 08 Dec 2023
*    - Abhishek Joshi 2026.02.13 - Created the methods fetchPunchoutLogsByQueryTest, fetchPunchoutLogTest - RWPS-6082
*************************************************************/
@isTest
public class ECOM_ApplicationLogsRepo_Test {
    @TestSetup
    static void setup(){
    	ECOM_TestUtil.createPOSRPOOMData();
    }

    @isTest
    static void getLatestApplicationLogsForLogTypesTest(){
        String type = 'POOM Request';
        List<String> types = new List<String>();
        types.add(type);
        Test.startTest();
        List<ECOM_Application_Logs__c> response = ECOM_ApplicationLogsRepo.getLatestApplicationLogsForLogTypes(types);
        Test.stopTest();
    }

   	@isTest
    static void getApplicationLogsBetweenDatesTest(){
        Datetime dt = Datetime.now();
        String type = 'POOM Request';
        List<String> types = new List<String>();
        types.add(type);
        Test.startTest();
        List<ECOM_Application_Logs__c> response = ECOM_ApplicationLogsRepo.getApplicationLogsBetweenDates(types,dt,dt+1);
        Test.stopTest();
    }

    @isTest
    static void insertNewLogsTest(){
        ECOM_Application_Logs__c log = new ECOM_Application_Logs__c();
        log.ErrorMessage__c='test';
        List<ECOM_Application_Logs__c> logs = new List<ECOM_Application_Logs__c>();
        logs.add(log);
        Test.startTest();
        List<ECOM_Application_Logs__c> response = ECOM_ApplicationLogsRepo.insertNewLogs(logs);
        Test.stopTest();
        system.assertEquals(log.ErrorMessage__c,response[0].ErrorMessage__c,'Log is not same');
    }

    /**
    * @description test class to get punchout logs
    * @author Abhishek Joshi 2026.02.13 - RWPS-6082
    **/
    @isTest
    static void getPunchoutLogsTest(){
        Test.startTest();
        ECOM_ApplicationLogsRepo.getPunchoutLogs('test');
        Test.stopTest();
    }

    /**
    * @description test class to get punchout logs
    * @author Abhishek Joshi 2026.02.13 - RWPS-6082
    **/
    @isTest
    static void fetchPunchoutLogsByQueryTest(){
        Test.startTest();
        ECOM_ApplicationLogsRepo.fetchPunchoutLogsByQuery('SELECT Id FROM ECOM_Punchout_Log__c LIMIT 1');
        ECOM_ApplicationLogsRepo.fetchPunchoutLogsByQuery('SELECT Id FROM ECOM_Punchout_Log__c LIMIT 1', new List<String>{'test'}, new List<String>{'test'});
        Test.stopTest();
    }
}