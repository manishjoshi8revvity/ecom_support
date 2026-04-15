/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-
*
* 2. Description - This class is used to retrieve user records.
*
*
*
* 3. Objects referenced
*    -ECOM_Application_Logs__c
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
*
* 5. Dependant Class(es):
*    -
*
* 6. Test Class Name:
*    -
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - vramachandran@rafter.one | 05 Dec 2023
*    - garora@rafter.one | 1 Apr 2024 - RWPS-421 - to prevent heap size error and get upto next date's 00:00 time
*    - Prabhat k 2026.02.05 - Created method getPunchoutLogs - RWPS-6095
*    - Abhishek Joshi 2026.02.13 - Created the method fetchPunchoutLogsByQuery - RWPS-6082

*************************************************************/
public class ECOM_ApplicationLogsRepo {


    /**
     * @description This method returns list of latest(recent 500) POOM And POSR logs
     * @author Prabhat | 03 Feb 2026
     * @param payloadId : String
     * @return List<ECOM_Punchout_Log__c>
     * JIRA-RWPS-6081
     */
    public static List<ECOM_Punchout_Log__c> getPunchoutLogs(String payloadId) {
        return [SELECT Id, Buyer_Cookie__c, Contact__c, CurrencyIsoCode, Master_ERP_Address__r.ERP_Customer_Base_Name__c, Name,
                Line_Items__c, Master_ERP_Address__c, Order_Total__c, OwnerId, Parser__c,
                Payload_ID__c, POOM_cXML__c, POOM_request__c, POOM_Timestamp__c,
                POSR_cXML__c, POSR_response__c, POSR_Timestamp__c, POSR_URL_params__c,
                Post_Form__c, Quantity__c, Test_Record__c
                FROM ECOM_Punchout_Log__c
                WHERE Payload_ID__c = :payloadId
                LIMIT 1];
    }
     /**
     * @description This method returns punchout log record
     * @author vramachandran@rafter.one | 05 Dec 2023
     * @param logTypes : List<String>
     * @return List<ECOM_ApplicationLogs__c>
     */
    public static List<ECOM_Application_Logs__c> getLatestApplicationLogsForLogTypes(List<String> logTypes){
        return [SELECT Id, Name, Owner.Username, ECOM_Account__r.Name, MethodName__c, ModuleName__c, ClassName__c, CreatedBy.Name, FORMAT(CreatedDate), CurrencyIsoCode, ECOM_Log_Type__c, ErrorMessage__c, ExceptionType__c, IsDeleted, LastModifiedDate, LineNumber__c, Owner.Name, StackTrace__c, SupportData__c, ECOM_Log_Status__c
                FROM ECOM_Application_Logs__c
               	WHERE ECOM_Log_Type__c IN :logTypes
                //RWPS-421 - garora@rafter.one - 1 April 2024 - to prevent heap size error
                ORDER BY CreatedDate DESC
                LIMIT 10000];
    }

    /**
     * @description This method returns list of latest(recent 500) POOM And POSR logs
     * @author vramachandran@rafter.one | 05 Dec 2023
     * @param logTypes : List<String>
     * @return List<ECOM_ApplicationLogs__c>
     */
    public static List<ECOM_Application_Logs__c> getApplicationLogsBetweenDates(List<String> logTypes, DateTime fromDate, DateTime toDate){
        return [SELECT Id, Name, Owner.Username, ECOM_Account__r.Name, MethodName__c, ModuleName__c, ClassName__c, CreatedBy.Name, FORMAT(CreatedDate), CurrencyIsoCode, ECOM_Log_Type__c, ErrorMessage__c, ExceptionType__c, IsDeleted, LastModifiedDate, LineNumber__c, Owner.Name, StackTrace__c, SupportData__c, ECOM_Log_Status__c
                FROM ECOM_Application_Logs__c
               	WHERE ECOM_Log_Type__c IN :logTypes
                AND CreatedDate >= :fromDate
                //RWPS-421 - garora@rafter.one - 1 April 2024 - get upto next date's 00:00 time
                AND CreatedDate < :toDate.addDays(1)
                ORDER BY CreatedDate DESC
                LIMIT 49999];
    }

    /**
     * @description This method inserts new list of logs and returns
     * @author vramachandran@rafter.one | 09 Jan 2024
     * @param logsList | List<ECOM_Application_Logs__c>
     * @returns List<ECOM_Application_Logs__c>
     */
    public static List<ECOM_Application_Logs__c> insertNewLogs(List<ECOM_Application_Logs__c> logsList){
        insert logsList;
        return logsList;
    }

    /**
    * @description get punchout logs by query
    * @author Abhishek Joshi 2026.02.13 - RWPS-6082
    * @param query | String
    * @return List<AggregateResult>
    **/
    public static List<AggregateResult> fetchPunchoutLogsByQuery(String query) {
        return Database.query(query);
    }

    /**
    * @description get punchout logs by query
    * @author Abhishek Joshi 2026.02.13 - RWPS-6082
    * @param query | String
    * @return List<AggregateResult>
    **/
    public static List<AggregateResult> fetchPunchoutLogsByQuery(String query, List<String> totalCurrency, List<String> customer) {
        return Database.query(query);
    }
}