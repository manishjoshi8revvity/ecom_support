/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-
*
* 2. Description - This class is a controller class to handle requests for ECOM_ApplicationLogs object
*
*
* 3. Objects referenced
*    - ECOM_Logging_Setting__c
*    - ECOM_Application_Logs__c
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
*
* 5. Dependant Class(es):
*
* 6. Test Class Name:
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - vramachandran@rafter.one | 05 Dec 2023
*    - Abhishek Joshi 2026.02.13 - Created the methods getCurrencyValues, getCustomerNames, getPunchoutLogsByCustomer, getPunchoutLogs - RWPS-6082

*************************************************************/
public class ECOM_ApplicationLogsController {

    private final static String CLASSNAME = 'ECOM_ApplicationLogsController';

    /**
     * @description This method returns the latest 500 POSR and POOM logs
     * @author vramachandran@rafter.one | 05 Dec 2023
     * @returns Map<String,Object>
     */
    @AuraEnabled
    public static Map<String,Object> getLatestPosrPoomLogs(){
        final String METHOD_NAME = 'getLatestPosrPoomLogs';
        Map<String,Object> responseMap = new Map<String,Object>();
        try{
            List<String> logTypes = System.Label.ECOM_LogTypes.split(',');
            System.debug('logTypes:: '+ logTypes);
            List<ECOM_Application_Logs__c> fetchedLogs = ECOM_ApplicationLogsRepo.getLatestApplicationLogsForLogTypes(logTypes);
            List<ECOM_ApplicationLogsWrapper> wrapperList = ECOM_ApplicationLogsUtil.getMappedList(fetchedLogs);
            responseMap.put(ECOM_Constant.PARAM_RESPONSE_DATA, wrapperList);
            responseMap.put(ECOM_Constant.PARAM_SUCCESS, true);
        }catch(Exception e){
            responseMap.put(ECOM_Constant.PARAM_MESSAGE, System.Label.ECOM_130001 + 'Message:: '+ e.getMessage() + ' Stack:: '+ e.getStackTraceString());responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
            ECOM_ApplicationLogsUtil.logFailure(e , 'DML-Fetch Logs failed' , CLASSNAME ,METHOD_NAME , 'Message:: '+ e.getMessage() + ' Stack:: '+ e.getStackTraceString());
        }
        return responseMap;
    }

    /**
     * @description This method returns POSR and POOM logs for given dates
     * @author vramachandran@rafter.one | 05 Dec 2023
     * @returns Map<String,Object>
     */
    @AuraEnabled
    public static Map<String,Object> getLogsForDates(String fromDate, String toDate){
        final String METHOD_NAME = 'getLatestPosrPoomLogs';
        Map<String,Object> responseMap = new Map<String,Object>();
        try{
            List<String> logTypes = System.Label.ECOM_LogTypes.split(',');
            System.debug('logTypes:: '+ logTypes);

            DateTime fromDateDT = (DateTime) JSON.deserialize('"'+fromDate + 'T00:00:00Z' +'"', DateTime.class);
            DateTime toDateDT = (DateTime) JSON.deserialize('"'+toDate + 'T00:00:00Z'+'"', DateTime.class);
            System.debug('FromDate:: '+ fromDateDT + '  '+ toDateDT);
            List<ECOM_Application_Logs__c> fetchedLogs = ECOM_ApplicationLogsRepo.getApplicationLogsBetweenDates(logTypes, fromDateDT, toDateDT);
            List<ECOM_ApplicationLogsWrapper> wrapperList = ECOM_ApplicationLogsUtil.getMappedList(fetchedLogs);
            responseMap.put(ECOM_Constant.PARAM_RESPONSE_DATA, wrapperList);
            responseMap.put(ECOM_Constant.PARAM_SUCCESS, true);
        }catch(Exception e){
            responseMap.put(ECOM_Constant.PARAM_MESSAGE, System.Label.ECOM_130001 + 'Message:: '+ e.getMessage() + ' Stack:: '+ e.getStackTraceString());responseMap.put(ECOM_Constant.PARAM_SUCCESS, false);
            ECOM_ApplicationLogsUtil.logFailure(e , 'DML-Fetch Logs failed' , CLASSNAME ,METHOD_NAME , 'Message:: '+ e.getMessage() + ' Stack:: '+ e.getStackTraceString());
        }
        return responseMap;
    }

    /**
    * @description get punchout logs
    * @author Abhishek Joshi 2026.02.13 - RWPS-6082
    * @param config | Map<String,Object>
    * @return List<AggregateResult>
    **/
    @AuraEnabled
    public static List<AggregateResult> getPunchoutLogs(Map<String,Object> config) {
        return ECOM_ApplicationLogsUtil.fetchPunchoutLogs(config);
    }

    /**
    * @description get punchout logs by customer
    * @author Abhishek Joshi 2026.02.13 - RWPS-6082
    * @param config | Map<String,Object>
    * @return List<AggregateResult>
    **/
    @AuraEnabled
    public static List<AggregateResult> getPunchoutLogsByCustomer(Map<String,Object> config) {
        return ECOM_ApplicationLogsUtil.fetchPunchoutLogsByCustomer(config);
    }

    /**
    * @description get customer values
    * @author Abhishek Joshi 2026.02.13 - RWPS-6082
    * @param includeTest | Boolean
    * @return List<AggregateResult>
    **/
    @AuraEnabled(cacheable=true)
    public static List<AggregateResult> getCustomerNames(Boolean includeTest) {
        return ECOM_ApplicationLogsUtil.fetchCustomerNames(includeTest);
    }

    /**
    * @description get currency values
    * @author Abhishek Joshi 2026.02.13 - RWPS-6082
    * @param includeTest | Boolean
    * @return List<AggregateResult>
    **/
    @AuraEnabled(cacheable=true)
    public static List<AggregateResult> getCurrencyValues(Boolean includeTest) {
        return ECOM_ApplicationLogsUtil.fetchCurrencyValues(includeTest);
    }
}