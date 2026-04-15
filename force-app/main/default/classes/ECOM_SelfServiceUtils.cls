/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-3225
*
* 2. Description - This class is used for utility methods to be used in Self-Service Application. The methods in the scope of this class includes verifying the validity of the SSO user's session and logging.
*
* 3. Objects referenced
*   - ECOM_Application_Logs__c
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_EncryptUtil
*    - ECOM_ApplicationLogsUtil
*    - ECOM_SelfServiceConstants
*
* 6. Test Class Name: ECOM_SelfServiceUtils_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Abhishek Joshi 19 June 2024
*
*************************************************************/

public without sharing class ECOM_SelfServiceUtils {
    private static final String CLASS_NAME = 'ECOM_SelfServiceUtils';
    private static final Long SESSION_VALIDITY_PERIOD = 24 * 60 * 60 * 1000;

    /**
     * @description This method returns the decrypted user data after receiving session data from LWC
     * @author abhishek.joshi@revvity.com | 17 June 2024
     * @param encryptedData | String
     * @return Map<String, Object>
     */
    public static Map<String,Object> getUserData(String encryptedData) {
        try {
            if(String.isBlank(encryptedData)) {
                throw new NoDataFoundException();
            }

            String decryptedTextData;

            if(Test.isRunningTest()) {
                decryptedTextData = encryptedData;
            } else {
                decryptedTextData = ECOM_EncryptUtil.decryptWithAES256(encryptedData);
            }

            // Decrypt cookie value
            Map<String,Object> decryptedMap = (Map<String,Object>) JSON.deserializeUntyped(
                decryptedTextData.split(ECOM_SelfServiceConstants.ENCRYPTION_SEPARATOR)[1]
            );

            Datetime dt = Datetime.now();
            Long dtEpoch = dt.getTime();

            // Verify cookie value
            String email = (String) decryptedMap.get('email');
            Long sessionTime = Long.valueOf((String) decryptedMap.get('time'));
            if(email.endsWith(ECOM_SelfServiceConstants.EMAIL_SUFFIX) && (dtEpoch - sessionTime) < SESSION_VALIDITY_PERIOD) {
                decryptedMap.put(ECOM_SelfServiceConstants.METHOD_SUCCESS_KEY, (Object) 1);
            } else {
                decryptedMap.clear();
            }
            return decryptedMap;
        } catch (Exception e) {
            String message =
                'Message:: ' + e.getCause() + ' // ' + e.getMessage() + ' // stack trace:: ' + e.getStackTraceString();
            return new Map<String, Object>{'error' => (Object) message};
        }
    }

    /**
    * @description  This method is used to calculate the System Limits during the exception.
    * @author abhishek.joshi@revvity.com | 10 October 2024
    * @return List<String>
    **/
    private static List<String> getSystemLimits()
    {
        String queryLimit = '1. SOQL Queries used / SOQL Queries allowed: ' + Limits.getQueries() + '/' + Limits.getLimitQueries();
        String dmlLimit = '2. Number of records queried so far /  Number allowed: ' + Limits.getDmlRows() + '/' + Limits.getLimitDmlRows();
        String dmlStat = '3. Number of DML statements used so far / Number allowed: ' + Limits.getDmlStatements() + '/' + Limits.getLimitDmlStatements();
        String cpuUsage = '4. Amount of CPU time (in ms) used so far / CPU usage time (in ms) allowed: ' + Limits.getCpuTime() + '/' + Limits.getLimitCpuTime();

        List<String> lstSalesforceLimit = new List<String>();
        lstSalesforceLimit.add(queryLimit);
        lstSalesforceLimit.add(dmlLimit);
        lstSalesforceLimit.add(dmlStat);
        lstSalesforceLimit.add(cpuUsage);
        return lstSalesforceLimit;
    }

    /**
     * @description This method returns the decrypted user data after receiving session data from LWC
     * @author abhishek.joshi@revvity.com | 10 October 2024
     * @param logMap | Map<String, Object>
     * @param excp | Exception
     * @return void
     */
    public static void selfserviceLogException(Map<String, Object> logMap, Exception excp) {
        Datetime requestTs = (Datetime) logMap.get('requestTimestamp');
        Long requestEpoch;

        if(requestTs != null) {
            requestEpoch = requestTs.getTime();
        }

        Datetime responseTs = (Datetime) logMap.get('responseTimestamp');
        Long responseEpoch;

        if(responseTs != null) {
            responseEpoch = responseTs.getTime();
        }

        ECOM_Application_Logs__c exc = new ECOM_Application_Logs__c();
        exc.ClassName__c = (String) logMap.get('className');
        exc.MethodName__c = (String) logMap.get('methodName');
        exc.ModuleName__c = (String) logMap.get('moduleName');
        exc.SupportData__c = (String) logMap.get('supportData');

        exc.ApiResponse__c = (String) logMap.get('apiResponse');
        exc.Request_TimeStamp__c = requestTs;
        exc.Request_TimeStamp_ms__c = requestEpoch;
        exc.Response_TimeStamp__c = responseTs;
        exc.Response_TimeStamp_ms__c = responseEpoch;

        exc.ErrorMessage__c = excp.getMessage();
        exc.ExceptionType__c = excp.getTypeName();
        exc.StackTrace__c = excp.getStackTraceString();
        exc.LineNumber__c = String.valueOf(excp.getLineNumber());
        exc.ExceptionRunningUser__c = UserInfo.getUserId();

        List<String> lstSalesforceLimit = getSystemLimits();
        exc.SalesforceLimits__c = String.format('{0}\n{1}\n{2}\n{3}', lstSalesforceLimit);

        exc.Source_Type__c = ECOM_SelfServiceConstants.LOGGING_SOURCE_TYPE;

        Database.insert(exc);
    }
}