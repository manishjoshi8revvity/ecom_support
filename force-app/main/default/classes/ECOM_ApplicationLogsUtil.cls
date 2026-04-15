/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-
*
* 2. Description - This class is an utility class for application logs.
*				- This class is used to log exceptions
				- return Application Log ECOM_Application_Logs__c
				- get the Limit of SOQL Query and DML Operations
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
*    - ECOM_EncryptFlowService
*	 - ECOM_LoginController
*	 - ECOM_LoginUtil
*	 - ECOM_AccountsController
*    - ECOM_CartService
*    - ECOM_OrderCreateBatch
*    - ECOM_OrderService
*    - ECOM_UserService
*    - ECOM_OrderSyncFlowController
*    - ECOM_OrderCreateFlowController
*    - ECOM_EncryptUtil
* 6. Test Class Name:
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vipul 2023.07.19
*    - Manoj 2024.07.03 RWPS-993 Exception Running User field should be populated
*	 - Sathiya 2024.08.30 ECOM-1480 Adding overloading methods to add extra information
*    - Poonam 2025.11.25 Added method logJsFailure, storeExceptionLog - RWPS-5153
*	 - Manish Joshi 2026.02.03 Added logApplicationDataWithCustomException method to add exception details RWPS-5770
*    - Abhishek Joshi 2026.02.13 - Created the methods fetchCurrencyValues, fetchCustomerNames, fetchPunchoutLogsByCustomer, fetchPunchoutLogs - RWPS-6082
*    - Poonam Shukla 2026.04.10 - Created the  overloaded methods logFailure and updated storeExceptionlog, setupApplicationRecord - RWPS-6037
*************************************************************/
public without sharing class ECOM_ApplicationLogsUtil {

    public static final String CLASSNAME='ECOM_ApplicationLogsUtil';
    
    /**
    * @description  this method is used to log failure exception logs
    * @author mkumar@rafter.one | 09-20-2023
    * @param excp
    * @param moduleName
    * @param className
    * @param methodName
    * @param supportData
    **/
    public static void logFailure(Exception excp , String moduleName , String className , String methodName,String supportData)
    {
        logFailure(excp,moduleName,className,methodName,supportData, null,'ERROR');//RWPS-6037
    }

    /**
    * @description  this method is used to log failure exception logs
    * @author mkumar@rafter.one | 09-30-2024
    * @param excp
    * @param moduleName
    * @param className
    * @param methodName
    * @param supportData
    * @param username
    **/
    public static void logFailure(Exception excp , String moduleName , String className , String methodName,String supportData, String username){
        storeExceptionLog(excp,moduleName,className,methodName,supportData, username, 'ERROR');//RWPS-6037
    }

     /** RWPS-6037
    * @description  this overloaded logFailure method is used to log failure exception logs with additional input parameters logStatus
    * @author poonam.shukla@revvity.com | 04-10-2024
    * @param excp
    * @param moduleName
    * @param className
    * @param methodName
    * @param supportData
    * @param username
    * @param logStatus
    **/
     public static void logFailure(Exception excp , String moduleName , String className , String methodName,String supportData, String username, String logStatus){
        storeExceptionLog(excp,moduleName,className,methodName,supportData, username, logStatus);//RWPS-6037
    }
    
    /**
    * @description  This method is used to save the exception log. This is only supposed to be called from client side js
    * @author poonam.shukla@revvity.one | 11-25-2025
    * @param fileName  String
    * @param className String
    * @param methodName String
    * @param supportData String
    * @param username String
    **/

 public static void storeExceptionLog(String fileName, String moduleName, String methodName, String supportData, String username){
    try {
        ECOM_Application_Logs__c log = new ECOM_Application_Logs__c();
        log.ModuleName__c = moduleName;
        log.ClassName__c = fileName;
        log.MethodName__c = methodName;
        log.SupportData__c = supportData;
        log.ExceptionRunningUser__c = UserInfo.getUserId();
        log.ECOM_Contact_Email__c = username;
        log.ExceptionType__c = 'UI.Exception';
        log.ECOM_Log_Status__c = 'ERROR';
        Database.insert(log);
    } catch (Exception e) {

    }
}
    /**
    * @description  this method is used to save the exception log
    * @author mkumar@rafter.one | 09-20-2023
    * @param excp  Exception
    * @param moduleName String
    * @param className String
    * @param methodName String
    * @param supportData String
    **/
    public static void storeExceptionLog(Exception excp , String moduleName , String className , String methodName,String supportData, String logStatus){
        storeExceptionLog(excp,moduleName,className,methodName,supportData, null, logStatus);
    }


    /**
    * @description  this method is used to save the exception log
    * @author mkumar@rafter.one | 09-20-2023
    * @param excp  Exception
    * @param moduleName String
    * @param className String
    * @param methodName String
    * @param supportData String
    * @param exceptionType String
    **/
    public static void storeExceptionLog(Exception excp , String moduleName , String className , String methodName,String supportData, String username, String logStatus)
    {
        try
        {
            ECOM_Application_Logs__c  exc = setupApplicationRecord(excp,moduleName,className,methodName,supportData, username, logStatus);
            if ( (exc != null &&
            (ECOM_Logging_Setting__c.getValues(System.UserInfo.getUserId()) != null &&
            ECOM_Logging_Setting__c.getInstance(System.UserInfo.getUserId()).EnableDebugLogs__c) ||
            (ECOM_Logging_Setting__c.getValues(System.UserInfo.getProfileId()) != null &&
                    ECOM_Logging_Setting__c.getInstance(System.UserInfo.getProfileId()).EnableDebugLogs__c)) ||
            UserInfo.getUserType() == 'Guest')
            {
                Database.insert(exc);
            }

        }catch (Exception ex) {
            System.debug('######## Error while saving application logs #######' + ex);
            System.debug('######## Error while saving application logs #######' + ex.getStackTraceString());
            System.debug('######## Error while saving application logs #######' + ex.getMessage());
        }
    }


    /**
    * @description  This method is used to calculate the System Limits during the exception.
    * @author mkumar@rafter.one | 09-20-2023
    * @return List<String>
    **/
    public static List<String> getSystemLimits()
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
    * @description  This method is used to setup log.
    * @author mkumar@rafter.one | 09-20-2023
    * @param excp
    * @param moduleName
    * @param className
    * @param methodName
    * @param supportData
    * @return ECOM_Application_Logs__c
    **/
    public static ECOM_Application_Logs__c setupApplicationRecord(Exception excp , String moduleName , String className , String methodName,String supportData, String logStatus){
        return setupApplicationRecord(excp,moduleName,className,methodName,supportData, null, logStatus);
    }

    /**
    * @description  This method is used to setup log.
    * @author mkumar@rafter.one | 09-20-2023
    * @param excp
    * @param moduleName
    * @param className
    * @param methodName
    * @param supportData
    * @return ECOM_Application_Logs__c
    **/
    public static ECOM_Application_Logs__c setupApplicationRecord(Exception excp , String moduleName , String className , String methodName,String supportData, String username, String logStatus)
    {
        List<String> lstSalesforceLimit = getSystemLimits();
        ECOM_Application_Logs__c  exc = new ECOM_Application_Logs__c ();
        exc.SalesforceLimits__c = String.format('{0}\n{1}\n{2}\n{3}', lstSalesforceLimit);
        exc.ErrorMessage__c = excp.getMessage();
        exc.ExceptionType__c = excp.getTypeName();
        exc.LineNumber__c = String.valueOf(excp.getLineNumber());
        exc.StackTrace__c = excp.getStackTraceString();
        exc.ModuleName__c = moduleName;
        exc.ClassName__c = className;
        exc.MethodName__c = methodName;
        exc.SupportData__c = supportData;
        exc.ExceptionRunningUser__c = UserInfo.getUserId();
        exc.ECOM_Log_Status__c = logStatus;
        // Added Extra logic only in the case of new login and registration module
        exc.ECOM_Contact_Email__c = username;
        if(String.isNotBlank(username)){
            List<User> users = [SELECT Id, ContactId FROM User WHERE username =: username LIMIT 1];
            if(!users.isEmpty()){
                exc.ECOM_Contact__c = users[0]?.ContactId;
            }
        }
        // Changes end
        return exc;
    }

    /**
    * @description  This method is used to log API request and response
    * @author mkumar@rafter.one | 09-20-2023
    * @param moduleName
    * @param className
    * @param methodName
    * @param supportData
    * @param response
    * @return ECOM_Application_Logs__c
    **/
    public static ECOM_Application_Logs__c logApplicationApiData(String moduleName , String className , String methodName,String supportData,String response){
        return logApplicationApiData(moduleName, className, methodName, supportData, response, null);
    }

    /**
    * @description  This method is used to log API request and response
    * @author mkumar@rafter.one | 09-20-2023
    * @param moduleName
    * @param className
    * @param methodName
    * @param supportData
    * @param response
    * @return ECOM_Application_Logs__c
    **/
    public static ECOM_Application_Logs__c logApplicationApiData(String moduleName , String className , String methodName,String supportData,String response, String username)
    {
        List<String> lstSalesforceLimit = getSystemLimits();
        ECOM_Application_Logs__c  exc = new ECOM_Application_Logs__c ();
        exc.SalesforceLimits__c = String.format('{0}\n{1}\n{2}\n{3}', lstSalesforceLimit);
        exc.ModuleName__c = moduleName;
        exc.ClassName__c = className;
        exc.MethodName__c = methodName;
        exc.SupportData__c = supportData;
        exc.ApiResponse__c = response;
        exc.ExceptionRunningUser__c = UserInfo.getUserId();//RWPS-993
        // Added Extra logic only in the case of new login and registration module
        exc.ECOM_Contact_Email__c = username;
        if(String.isNotBlank(username)){
            List<User> users = [SELECT Id, ContactId FROM User WHERE username =: username LIMIT 1];
            if(!users.isEmpty()){
                exc.ECOM_Contact__c = users[0]?.ContactId;
            }
        }
        // Changes end
        return insertApplicationLogs(exc);

    }

/**
    * @description  This method is used to log API request and response
    * @author poonm.shukla@revvity.one | 04-13-2026
    * @param moduleName
    * @param className
    * @param methodName
    * @param supportData
    * @param response
    * @param logStatus
    * @return ECOM_Application_Logs__c
    **/
    public static ECOM_Application_Logs__c logApplicationApiData(String moduleName , String className , String methodName,String supportData,String response, String username, String logStatus )
    {
        List<String> lstSalesforceLimit = getSystemLimits();
        ECOM_Application_Logs__c  exc = new ECOM_Application_Logs__c ();
        exc.SalesforceLimits__c = String.format('{0}\n{1}\n{2}\n{3}', lstSalesforceLimit);
        exc.ModuleName__c = moduleName;
        exc.ClassName__c = className;
        exc.MethodName__c = methodName;
        exc.SupportData__c = supportData;
        exc.ApiResponse__c = response;
        exc.ExceptionRunningUser__c = UserInfo.getUserId();//RWPS-993
        // Added Extra logic only in the case of new login and registration module
        exc.ECOM_Contact_Email__c = username;
        exc.ECOM_Log_Status__c = logStatus;
        if(String.isNotBlank(username)){
            List<User> users = [SELECT Id, ContactId FROM User WHERE username =: username LIMIT 1];
            if(!users.isEmpty()){
                exc.ECOM_Contact__c = users[0]?.ContactId;
            }
        }
        // Changes end
        return insertApplicationLogs(exc);

    }


    /**
    * @description
    * @author Vipul Goyal | 01-22-2024
    * @param moduleName
    * @param className
    * @param methodName
    * @param supportData
    * @param response
    * @param errorMessage
    * @return ECOM_Application_Logs__c
    **/
    public static ECOM_Application_Logs__c logApplicationDataWithCustomException(String moduleName , String className , String methodName,String supportData,String response,String errorMessage)
    {
        List<String> lstSalesforceLimit = getSystemLimits();
        ECOM_Application_Logs__c  exc = new ECOM_Application_Logs__c ();
        exc.SalesforceLimits__c = String.format('{0}\n{1}\n{2}\n{3}', lstSalesforceLimit);
        exc.ModuleName__c = moduleName;
        exc.ClassName__c = className;
        exc.MethodName__c = methodName;
        exc.SupportData__c = supportData;
        exc.ApiResponse__c = response;
        exc.ErrorMessage__c = errorMessage;
        exc.ECOM_Log_Status__c = 'ERROR';//RWPS-6037
        exc.ExceptionRunningUser__c = UserInfo.getUserId();//RWPS-993
        return insertApplicationLogs(exc);

    }

    //RWPS-6037 start
     public static ECOM_Application_Logs__c logApplicationDataWithCustomException(String moduleName , String className , String methodName,String supportData,String response,String errorMessage, String logStatus)
    {
        List<String> lstSalesforceLimit = getSystemLimits();
        ECOM_Application_Logs__c  exc = new ECOM_Application_Logs__c ();
        exc.SalesforceLimits__c = String.format('{0}\n{1}\n{2}\n{3}', lstSalesforceLimit);
        exc.ModuleName__c = moduleName;
        exc.ClassName__c = className;
        exc.MethodName__c = methodName;
        exc.SupportData__c = supportData;
        exc.ApiResponse__c = response;
        exc.ErrorMessage__c = errorMessage;
        exc.ECOM_Log_Status__c = logStatus;
        exc.ExceptionRunningUser__c = UserInfo.getUserId();//RWPS-993
        return insertApplicationLogs(exc);

    } //RWPS-6037 end


    /**
    * @description
    * @author Vipul Goyal | 01-22-2024
    * @param exc
    * @return ECOM_Application_Logs__c
    **/
    public static ECOM_Application_Logs__c insertApplicationLogs(ECOM_Application_Logs__c exc)
    {
        Database.insert(exc);
        return exc;
    }

    /**
    * @description  This method is used to Log API request and Response.
    * @author mkumar@rafter.one | 09-20-2023
    * @param moduleName
    * @param className
    * @param methodName
    * @param supportData
    * @param actionType
    * @return ECOM_Application_Logs__c
    **/
    public static ECOM_Application_Logs__c setupApplicationRecord( String moduleName, String className, String methodName, String supportData, String response, String actionType){
        return setupApplicationRecord(moduleName, className, methodName, supportData, response, actionType, null, 'ERROR');
    }


    /**
    * @description  This method is used to Log API request and Response.
    * @author mkumar@rafter.one | 09-20-2023
    * @param moduleName
    * @param className
    * @param methodName
    * @param supportData
    * @param actionType
    * @param exceptionType
    * @return ECOM_Application_Logs__c
    **/
    public static ECOM_Application_Logs__c setupApplicationRecord( String moduleName, String className, String methodName, String supportData, String response, String actionType, String exceptionType, String logStatus)
    {

        ECOM_Application_Logs__c  exc = new ECOM_Application_Logs__c ();

        try{
            if ( (exc != null &&
                  (ECOM_Logging_Setting__c.getValues(System.UserInfo.getUserId()) != null && ECOM_Logging_Setting__c.getInstance(System.UserInfo.getUserId()).EnableDebugLogs__c && ECOM_Logging_Setting__c.getInstance(System.UserInfo.getUserId()).Action_Type__c != null && ECOM_Logging_Setting__c.getInstance(System.UserInfo.getUserId()).Action_Type__c.contains(actionType)) ||
                  (ECOM_Logging_Setting__c.getValues(System.UserInfo.getProfileId()) != null && ECOM_Logging_Setting__c.getInstance(System.UserInfo.getProfileId()).EnableDebugLogs__c) && ECOM_Logging_Setting__c.getInstance(System.UserInfo.getProfileId()).Action_Type__c != null && ECOM_Logging_Setting__c.getInstance(System.UserInfo.getProfileId()).Action_Type__c.contains(actionType)) ||
                UserInfo.getUserType() == 'Guest'){
                    exc.SupportData__c = supportData;
                    exc.ModuleName__c = moduleName;
                    exc.ClassName__c = className;
                    exc.MethodName__c = methodName;
                    exc.ExceptionRunningUser__c = UserInfo.getUserId();
                    exc.ApiResponse__c = response;
                    exc.ECOM_Log_Status__c = logStatus;
                    exc.ExceptionType__c = exceptionType;
                    Database.insert(exc);
                }
        } catch(Exception ex){
            System.debug('Exception in logging request and response == '+ex.getStackTraceString());
        }
        return exc;
    }

      public static ECOM_Application_Logs__c setupApplicationRecord( String moduleName, String className, String methodName, String supportData, String response, String actionType, String exceptionType)
    {

        ECOM_Application_Logs__c  exc = new ECOM_Application_Logs__c ();

        try{
            if ( (exc != null &&
                  (ECOM_Logging_Setting__c.getValues(System.UserInfo.getUserId()) != null && ECOM_Logging_Setting__c.getInstance(System.UserInfo.getUserId()).EnableDebugLogs__c && ECOM_Logging_Setting__c.getInstance(System.UserInfo.getUserId()).Action_Type__c != null && ECOM_Logging_Setting__c.getInstance(System.UserInfo.getUserId()).Action_Type__c.contains(actionType)) ||
                  (ECOM_Logging_Setting__c.getValues(System.UserInfo.getProfileId()) != null && ECOM_Logging_Setting__c.getInstance(System.UserInfo.getProfileId()).EnableDebugLogs__c) && ECOM_Logging_Setting__c.getInstance(System.UserInfo.getProfileId()).Action_Type__c != null && ECOM_Logging_Setting__c.getInstance(System.UserInfo.getProfileId()).Action_Type__c.contains(actionType)) ||
                UserInfo.getUserType() == 'Guest'){
                    exc.SupportData__c = supportData;
                    exc.ModuleName__c = moduleName;
                    exc.ClassName__c = className;
                    exc.MethodName__c = methodName;
                    exc.ExceptionRunningUser__c = UserInfo.getUserId();
                    exc.ApiResponse__c = response;
                    exc.ECOM_Log_Status__c = 'ERROR';
                    exc.ExceptionType__c = exceptionType;
                    Database.insert(exc);
                }
        } catch(Exception ex){
            System.debug('Exception in logging request and response == '+ex.getStackTraceString());
        }
        return exc;
    }


    /**
     * @description This method maps the column values to wrapper
     * @author vramachandran@rafter.one | 05 Dec 2023
     * @param logsList | List<ECOM_Application_Logs__c>
     * @returns List<ECOM_ApplicationLogsWrapper>
     */
    public static List<ECOM_ApplicationLogsWrapper> getMappedList(List<ECOM_Application_Logs__c> logsList){
        final String METHOD_NAME = 'getMappedList';
        List<ECOM_ApplicationLogsWrapper> wrapperList = new List<ECOM_ApplicationLogsWrapper>();
        List<String> logTypes = System.Label.ECOM_LogTypes.split(',');
        ECOM_ApplicationLogsWrapper wrapper;
        if(logsList != null && !logsList.isEmpty()){
            for(ECOM_Application_Logs__c logRecord : logsList){
                wrapper = new ECOM_ApplicationLogsWrapper();
                wrapper.logId = logRecord?.Id;
                wrapper.logType = logRecord?.ECOM_Log_Type__c;
                wrapper.methodName = logRecord?.MethodName__c;
                wrapper.moduleName = logRecord?.ModuleName__c;
                wrapper.errorMessage = logRecord?.ErrorMessage__c;
                wrapper.createdDate = logRecord?.CreatedDate;
                wrapper.className = logRecord?.ClassName__c;
                wrapper.createdBy = logRecord?.CreatedBy?.Name;
                wrapper.currencyIsoCode = logRecord?.CurrencyIsoCode;
                wrapper.name = logRecord?.Name;
                wrapper.stackTrace = logRecord?.StackTrace__c;
                wrapper.supportData = logRecord?.SupportData__c;
                //GAr - organization and user name directly mapped to fields now
                wrapper.organizationName = logRecord?.ECOM_Account__r.Name;
                wrapper.loginUserName = logRecord?.Owner.Username;
                wrapper.status = logRecord?.ECOM_Log_Status__c;
                wrapperList.add(wrapper);
            }
        }
        return wrapperList;
    }

    /**
    * @description  This method is used to insert new application logs and returns the new list of logs.
    * @author vramachandran@rafter.one | 09 Jan 2024
    * @param logsList | List<ECOM_Application_Logs__c>
    * @return ECOM_Application_Logs__c
    **/
    public static List<ECOM_Application_Logs__c> insertNewLogs(List<ECOM_Application_Logs__c> logsList){
        return ECOM_ApplicationLogsRepo.insertNewLogs(logsList);
    }

  /**
    * @description  This method is used to save the exception log.This is only supposed to be called from client side js
    * @author poonam.shukla@revvity.one | 11-25-2025
    * @param fileName  String
    * @param moduleName String
    * @param methodName String
    * @param supportData String
    **/
    public static void logJsFailure(String fileName, String moduleName, String methodName, String supportData){
       storeExceptionLog(fileName, moduleName, methodName, supportData, UserInfo.getUserName());
    }
        /**
    * @description
    * @author Manish Joshi | 02-03-2026
    * @param moduleName
    * @param className
    * @param methodName
    * @param supportData
    * @param response
    * @param errorMessage
    * @param exceptionType
    * @return ECOM_Application_Logs__c
    **/
    public static ECOM_Application_Logs__c logApplicationWithCustomExceptionType(String moduleName , String className ,
        String methodName,String supportData,String response,String errorMessage, String exceptionType)
    {
        List<String> lstSalesforceLimit = getSystemLimits();
        ECOM_Application_Logs__c  exc = new ECOM_Application_Logs__c ();
        exc.SalesforceLimits__c = String.format('{0}\n{1}\n{2}\n{3}', lstSalesforceLimit);
        exc.ModuleName__c = moduleName;
        exc.ClassName__c = className;
        exc.MethodName__c = methodName;
        exc.SupportData__c = supportData;
        exc.ApiResponse__c = response;
        exc.ErrorMessage__c = errorMessage;
        exc.ExceptionType__c = exceptionType;
        exc.ExceptionRunningUser__c = UserInfo.getUserId();//RWPS-993
        return insertApplicationLogs(exc);

    }

    /**
    * @description get punchout logs
    * @author Abhishek Joshi 2026.02.13 - RWPS-6082
    * @param config | Map<String,Object>
    * @return List<AggregateResult>
    **/
    public static List<AggregateResult> fetchPunchoutLogs(Map<String,Object> config) {
        String fields;
        String groups;
        String order;

        String grouping = (String) config.get('grouping');

        if(grouping == 'day') {
            fields = 'DAY_ONLY(POSR_Timestamp__c) posrDate';
            groups = 'DAY_ONLY(POSR_Timestamp__c)';
        } else if(grouping == 'month') {
            fields = 'CALENDAR_MONTH(POSR_Timestamp__c) posrMonth, CALENDAR_YEAR(POSR_Timestamp__c) posrYear';
            groups = 'CALENDAR_MONTH(POSR_Timestamp__c), CALENDAR_YEAR(POSR_Timestamp__c)';
        } else {
            fields = 'DAY_IN_WEEK(POSR_Timestamp__c) posrWeekday';
            groups = 'DAY_IN_WEEK(POSR_Timestamp__c)';
            order = 'DAY_IN_WEEK(POSR_Timestamp__c) ASC';
        }

        String query = 'SELECT SUM(Order_Total__c) orderTotal, COUNT(POSR_Timestamp__c) posrCount, COUNT(POOM_Timestamp__c) poomCount, AVG(Order_Total__c) avgOrderTotal, CurrencyIsoCode, SUM(Line_Items__c) lineItemsTotal, SUM(Quantity__c) quantityTotal, ' + fields + ' FROM ECOM_Punchout_Log__c';

        query += ' WHERE DAY_ONLY(POSR_Timestamp__c) >= ' + (String) config.get('startDate') + ' AND DAY_ONLY(POSR_Timestamp__c) <= ' + (String) config.get('endDate');

        Boolean includeTest = (Boolean) config.get('test');
        if(!includeTest) {
            query += ' AND Test_Record__c != true';
        }

        List<Object> customerObj = (List<Object>) config.get('customer');
        List<String> customer = new List<String>();
        for(Object c : customerObj) {
            customer.add((String) c);
        }
        if(customer != null && !customer.isEmpty()) {
            query += ' AND Master_ERP_Address__r.ERP_Account_Name__c IN :customer';
        }

        List<Object> totalCurrencyObj = (List<Object>) config.get('currency');
        List<String> totalCurrency = new List<String>();
        for(Object c : totalCurrencyObj) {
            totalCurrency.add((String) c);
        }
        if(totalCurrency != null && !totalCurrency.isEmpty()) {
            query += ' AND CurrencyIsoCode IN :totalCurrency';
        }

        query += ' GROUP BY CurrencyIsoCode, ' + groups;

        if(String.isNotBlank(order)) {
            query += ' ORDER BY ' + order;
        }

        return ECOM_ApplicationLogsRepo.fetchPunchoutLogsByQuery(query, totalCurrency, customer);
    }

    /**
    * @description get punchout logs by customer
    * @author Abhishek Joshi 2026.02.13 - RWPS-6082
    * @param config | Map<String,Object>
    * @return List<AggregateResult>
    **/
    public static List<AggregateResult> fetchPunchoutLogsByCustomer(Map<String,Object> config) {
        String query = 'SELECT SUM(Order_Total__c) orderTotal, COUNT(POSR_Timestamp__c) posrCount, COUNT(POOM_Timestamp__c) poomCount, AVG(Order_Total__c) avgOrderTotal, CurrencyIsoCode, Master_ERP_Address__r.ERP_Account_Name__c, SUM(Line_Items__c) lineItemsTotal, SUM(Quantity__c) quantityTotal FROM ECOM_Punchout_Log__c';

        query += ' WHERE DAY_ONLY(POSR_Timestamp__c) >= ' + (String) config.get('startDate') + ' AND DAY_ONLY(POSR_Timestamp__c) <= ' + (String) config.get('endDate');

        Boolean includeTest = (Boolean) config.get('test');
        if(!includeTest) {
            query += ' AND Test_Record__c != true';
        }

        List<Object> customerObj = (List<Object>) config.get('customer');
        List<String> customer = new List<String>();
        for(Object c : customerObj) {
            customer.add((String) c);
        }
        if(customer != null && !customer.isEmpty()) {
            query += ' AND Master_ERP_Address__r.ERP_Account_Name__c IN :customer';
        }

        List<Object> totalCurrencyObj = (List<Object>) config.get('currency');
        List<String> totalCurrency = new List<String>();
        for(Object c : totalCurrencyObj) {
            totalCurrency.add((String) c);
        }
        if(totalCurrency != null && !totalCurrency.isEmpty()) {
            query += ' AND CurrencyIsoCode IN :totalCurrency';
        }

        query += ' GROUP BY CurrencyIsoCode, Master_ERP_Address__r.ERP_Account_Name__c';

        query += ' ORDER BY Master_ERP_Address__r.ERP_Account_Name__c ASC';

        return ECOM_ApplicationLogsRepo.fetchPunchoutLogsByQuery(query, totalCurrency, customer);
    }

    /**
    * @description get customer values
    * @author Abhishek Joshi 2026.02.13 - RWPS-6082
    * @param includeTest | Boolean
    * @return List<AggregateResult>
    **/
    public static List<AggregateResult> fetchCustomerNames(Boolean includeTest) {
        String query = 'SELECT Master_ERP_Address__r.ERP_Account_Name__c FROM ECOM_Punchout_Log__c WHERE Master_ERP_Address__r.ERP_Account_Name__c != null';

        if(!includeTest) {
            query += ' AND Test_Record__c = false';
        }

        query += ' GROUP BY Master_ERP_Address__r.ERP_Account_Name__c ORDER BY Master_ERP_Address__r.ERP_Account_Name__c ASC';

        return ECOM_ApplicationLogsRepo.fetchPunchoutLogsByQuery(query);
    }

    /**
    * @description get currency values
    * @author Abhishek Joshi 2026.02.13 - RWPS-6082
    * @param includeTest | Boolean
    * @return List<AggregateResult>
    **/
    public static List<AggregateResult> fetchCurrencyValues(Boolean includeTest) {
        String query = 'SELECT CurrencyIsoCode FROM ECOM_Punchout_Log__c WHERE CurrencyIsoCode != null AND fxCartReturned__c = true';

        if(!includeTest) {
            query += ' AND Test_Record__c != true';
        }

        query += ' GROUP BY CurrencyIsoCode ORDER BY CurrencyIsoCode ASC';

        return ECOM_ApplicationLogsRepo.fetchPunchoutLogsByQuery(query);
    }
}