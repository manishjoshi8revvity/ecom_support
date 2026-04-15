/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*
*
* 2. Description - This is a test class for ECOM_ApplicationLogsUtil
*
* 3. Objects referenced
*    - ECOM_ApplicationUtil

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
*    - Vipul Goyal 22 Jan 2024
*    - Poonam Shukla - 2025.01.14 Added testLogJsFailure, testSetupApplicationRecord2, teststoreExceptionLog - RWPS-5153
*    - Abhishek Joshi 2026.02.13 - Created the methods testInsertNewLogs_HappyPath, testSetupApplicationRecordN, fetchPunchoutLogsTest, fetchPunchoutLogsByCustomerTest, fetchCustomerNamesAndCurrenciesTest - RWPS-6082
*************************************************************/
@isTest
public class ECOM_ApplicationLogsUtil_Test {

    //custom exception class, since native exception cannot be thrown
    public class ECOM_ApplicationLogsUtilException extends Exception{}

    //Reused static String values
    private static final String CLASS_NAME = 'ECOM_ApplicationLogsUtil_Test';
    private static final String METHOD_NAME = 'TestAllMethods';
    private static final String MODULE_NAME = 'Test ECOM_ApplicationLogs';
    private static final String RESPONSE = 'RESPONSE';
    private static final String SUPPORT_DATA = 'suppport data';
    private static final String ACTION_TYPE = 'action';
    private static final String FILE_NAME = 'ecom_test';//RWPS-5153


    //Setup data. insert new exception logs
    @testSetup
    static void testSetup(){
        ECOM_TestUtil.createPOSRPOOMData();
    }


    //test method for logFailure() method
    @isTest
    static void testLogFailure(){
        Test.startTest();
        try{
            throw new ECOM_ApplicationLogsUtilException();
        }catch(Exception e){
            ECOM_ApplicationLogsUtil.logFailure(e, MODULE_NAME, CLASS_NAME, METHOD_NAME, SUPPORT_DATA);
        }

        ECOM_ApplicationLogsUtil.logFailure(null, MODULE_NAME, CLASS_NAME, METHOD_NAME, SUPPORT_DATA);

        Test.stopTest();

    }


    //test method for setupApplicationRecord() method
    @isTest
    static void testSetupApplicationRecord(){
        ECOM_Application_Logs__c exc;
        Test.startTest();
        try{
            throw new ECOM_ApplicationLogsUtilException();
        }catch(Exception e){
            exc= ECOM_ApplicationLogsUtil.setupApplicationRecord(MODULE_NAME , CLASS_NAME , METHOD_NAME,SUPPORT_DATA,RESPONSE, ACTION_TYPE);
        }
        Test.stopTest();
        Assert.isInstanceOfType(exc, ECOM_Application_Logs__c.class);
    }

    //test method for getMappedList() method
    @isTest
    static void testGetMappedList(){
        List<String> logTypes = System.Label.ECOM_LogTypes.split(',');
		List<ECOM_Application_Logs__c> logs = ECOM_ApplicationLogsRepo.getLatestApplicationLogsForLogTypes(logTypes);
        Test.startTest();
        List<ECOM_ApplicationLogsWrapper> wrapperList = ECOM_ApplicationLogsUtil.getMappedList(logs);
        Test.stopTest();
        Assert.isNotNull(wrapperList,'Expected a non-empty/not null list');

    }

    @isTest
    static void testLogFailureWithCustomError() {
        Test.startTest();
        ECOM_ApplicationLogsUtil.logApplicationDataWithCustomException('Test','ECOM_ApplicationLogsUtil_Test','testLogFailureWithCustomError','Support Data','Test','Test Error');
        Test.stopTest();


        ECOM_Application_Logs__c[] logRecords = [SELECT Id,ModuleName__c FROM ECOM_Application_Logs__c WHERE ModuleName__c='Test' ORDER BY CreatedDate DESC LIMIT 1];
        System.assertEquals(1, logRecords.size());
    }

    @isTest
    static void testLogApplicationApiData() {
        Test.startTest();
        ECOM_ApplicationLogsUtil.logApplicationApiData('Test','ECOM_ApplicationLogsUtil_Test','logApplicationApiData','Support Data','Test');
        Test.stopTest();

        ECOM_Application_Logs__c[] logRecords = [SELECT Id,ModuleName__c FROM ECOM_Application_Logs__c WHERE ModuleName__c='Test' ORDER BY CreatedDate DESC LIMIT 1];
        System.assertEquals(1, logRecords.size());
    }

    @isTest
    static void testSetupApplicationRecord1() {
        Test.startTest();
        ECOM_ApplicationLogsUtil.setupApplicationRecord('Test','ECOM_ApplicationLogsUtil_Test','setupApplicationRecord','Support Data','Test','Test Error');
        Test.stopTest();

        ECOM_Application_Logs__c[] logRecords = [SELECT Id FROM ECOM_Application_Logs__c];
    }

    //RWPS-5153 start
    @isTest
    static void testLogJsFailure(){
        Test.startTest();
        try{
            throw new ECOM_ApplicationLogsUtilException();
        }catch(Exception e){
            ECOM_ApplicationLogsUtil.logJsFailure(FILE_NAME, MODULE_NAME, METHOD_NAME, SUPPORT_DATA);
        }

        ECOM_ApplicationLogsUtil.logJsFailure(FILE_NAME, MODULE_NAME, METHOD_NAME, SUPPORT_DATA);

        Test.stopTest();

    }

    @isTest
    static void testSetupApplicationRecord2(){
        ECOM_Application_Logs__c exc;
        Test.startTest();
        try{
            throw new ECOM_ApplicationLogsUtilException();
        }catch(Exception e){
            exc = ECOM_ApplicationLogsUtil.setupApplicationRecord(e, MODULE_NAME, CLASS_NAME, METHOD_NAME, SUPPORT_DATA,'ERROR');
        }
        Test.stopTest();
        Assert.isInstanceOfType(exc, ECOM_Application_Logs__c.class);
    }

    @isTest
    static void teststoreExceptionLog(){
        Test.startTest();
        try{
            throw new ECOM_ApplicationLogsUtilException();
        }catch(Exception e){
            ECOM_ApplicationLogsUtil.storeExceptionLog(e, MODULE_NAME, CLASS_NAME, METHOD_NAME, SUPPORT_DATA,'TESt');
        }
        Test.stopTest();
    }
    //RWPS-5153 end

    /**
    * @description test class to test insert punchout logs
    * @author Abhishek Joshi 2026.02.13 - RWPS-6082
    **/
    @isTest
    static void testInsertNewLogs_HappyPath() {
        List<ECOM_Application_Logs__c> toInsert = new List<ECOM_Application_Logs__c>{
            new ECOM_Application_Logs__c(
                ModuleName__c = MODULE_NAME,
                ClassName__c = CLASS_NAME,
                MethodName__c = METHOD_NAME,
                SupportData__c = SUPPORT_DATA
            ),
            new ECOM_Application_Logs__c(
                ModuleName__c = MODULE_NAME,
                ClassName__c = CLASS_NAME,
                MethodName__c = METHOD_NAME,
                SupportData__c = SUPPORT_DATA
            )
        };

        Test.startTest();
        List<ECOM_Application_Logs__c> inserted = ECOM_ApplicationLogsUtil.insertNewLogs(toInsert);
        Test.stopTest();

        System.assertNotEquals(null, inserted, 'Result should not be null');
    }

    /**
    * @description test class to gsetup application records
    * @author Abhishek Joshi 2026.02.13 - RWPS-6082
    **/
    @isTest
    static void testSetupApplicationRecordN(){
        ECOM_Application_Logs__c exc;
        Test.startTest();
        try{
            throw new ECOM_ApplicationLogsUtilException();
        }catch(Exception e){
            List<User> users = [SELECT Id, username FROM User LIMIT 1];
            exc = ECOM_ApplicationLogsUtil.setupApplicationRecord(e, MODULE_NAME, CLASS_NAME, METHOD_NAME, SUPPORT_DATA, users[0].username);
            ECOM_ApplicationLogsUtil.logApplicationApiData('Test','ECOM_ApplicationLogsUtil_Test','logApplicationApiData','Support Data','Test', users[0].username);
            ECOM_ApplicationLogsUtil.logApplicationWithCustomExceptionType('Test','ECOM_ApplicationLogsUtil_Test','logApplicationWithCustomExceptionType','Support Data','Test', 'Custom Exception', 'test');
        }
        Test.stopTest();
        Assert.isInstanceOfType(exc, ECOM_Application_Logs__c.class);
    }

    /**
    * @description test class to get punchout logs
    * @author Abhishek Joshi 2026.02.13 - RWPS-6082
    **/
     @isTest
    static void fetchPunchoutLogsTest(){
        ECOM_Application_Logs__c exc;
        Test.startTest();
        ECOM_ApplicationLogsController.getPunchoutLogs(
            new Map<String,Object> {
                'grouping' => 'day',
                'test' => false,
                'customer' => new List<Object>{'Customer1','Customer2'},
                'currency' => new List<Object>{'USD','EUR'},
                'startDate' => '2024-01-01',
                'endDate' => '2024-01-31'
            }
        );
        ECOM_ApplicationLogsController.getPunchoutLogs(
            new Map<String,Object> {
                'grouping' => '',
                'test' => false,
                'customer' => new List<Object>{'Customer1','Customer2'},
                'currency' => new List<Object>{'USD','EUR'},
                'startDate' => '2024-01-01',
                'endDate' => '2024-01-31'
            }
        );
        Test.stopTest();
    }

    /**
    * @description test class to get punchout logs
    * @author Abhishek Joshi 2026.02.13 - RWPS-6082
    **/
    @isTest
    static void fetchPunchoutLogsByCustomerTest(){
        ECOM_Application_Logs__c exc;
        Test.startTest();
        ECOM_ApplicationLogsController.getPunchoutLogsByCustomer(
            new Map<String,Object> {
                'grouping' => 'day',
                'test' => false,
                'customer' => new List<Object>{'Customer1','Customer2'},
                'currency' => new List<Object>{'USD','EUR'},
                'startDate' => '2024-01-01',
                'endDate' => '2024-01-31'
            }
        );
        ECOM_ApplicationLogsController.getPunchoutLogsByCustomer(
            new Map<String,Object> {
                'grouping' => '',
                'test' => false,
                'customer' => new List<Object>{'Customer1','Customer2'},
                'currency' => new List<Object>{'USD','EUR'},
                'startDate' => '2024-01-01',
                'endDate' => '2024-01-31'
            }
        );
        Test.stopTest();
    }

    /**
    * @description test class to get punchout customer names and currencies
    * @author Abhishek Joshi 2026.02.13 - RWPS-6082
    **/
    @isTest
    static void fetchCustomerNamesAndCurrenciesTest(){
        ECOM_Application_Logs__c exc;
        Test.startTest();
        ECOM_ApplicationLogsController.getCustomerNames(false);
        ECOM_ApplicationLogsController.getCurrencyValues(false);
        Test.stopTest();
    }
}