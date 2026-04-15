/**************************************************************

* 1. Jira Ticket(s) that relates to this class
*  
* 2. Description 
*    - This class is the test class for ECOM_ApplicationLogsController.
*
* 3. Objects referenced
*    - ECOM_Application_Logs__c
* 
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_TestUtil
*    - ECOM_ApplicationLogsController
*
* 6. Test Class Name:
*    -None
*
* 7. Is @Invocable : No
*
* 8. Author Name(s):
*    - Vasudev 08 Dec 2023
*************************************************************/
@isTest
public class ECOM_ApplicationLogsController_Test {
    
   
    //test method for getLatestPosrPoomLogs()
	@isTest
    static void testGetLatestPosrPoomLogsSuccess(){
        //create test data
        ECOM_TestUtil.createPOSRPOOMData();
        Test.startTest();
        Map<String,Object> responseMap = ECOM_ApplicationLogsController.getLatestPosrPoomLogs();
        Test.stopTest();
        Assert.isTrue(responseMap.containsKey(ECOM_Constant.PARAM_SUCCESS) ? (Boolean)responseMap.get(ECOM_Constant.PARAM_SUCCESS) : false, 'Expected a successful response');
    }
    
    //test method for getLatestPosrPoomLogs()
	@isTest
    static void testGetLatestPosrPoomLogsFail(){
        //create test data
        Test.startTest();
        Map<String,Object> responseMap = ECOM_ApplicationLogsController.getLatestPosrPoomLogs();
        Test.stopTest();
        Assert.isTrue(responseMap.containsKey(ECOM_Constant.PARAM_SUCCESS) ? (Boolean)responseMap.get(ECOM_Constant.PARAM_SUCCESS) : false, 'Expected a successful response');
    }
    
    //test method for getLogsForDates()
	@isTest
    static void testGetLogsForDates(){
        //create test data
        ECOM_TestUtil.createPOSRPOOMData();
        Test.startTest();
        Map<String,Object> responseMap = ECOM_ApplicationLogsController.getLogsForDates(String.valueOf(Date.today()), String.valueOf(Date.today().addDays(1)));
        Test.stopTest();
        Assert.isTrue(responseMap.containsKey(ECOM_Constant.PARAM_SUCCESS) ? (Boolean)responseMap.get(ECOM_Constant.PARAM_SUCCESS) : false, 'Expected a successful response');
    }
    
    @isTest
    static void testGetLogsForDatesException(){
        //create test data
        ECOM_TestUtil.createPOSRPOOMData();
        Test.startTest();
        Map<String,Object> responseMap = ECOM_ApplicationLogsController.getLogsForDates('error', 'error');
        Test.stopTest();
    }
}