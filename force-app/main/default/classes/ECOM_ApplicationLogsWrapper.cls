/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-    
*
* 2. Description - This class is a wrapper class for ECOM_ApplicationLogsController.
*
*
*
* 3. Objects referenced
*    -None
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
*
* 5. Dependant Class(es):
*    - None
*	
* 6. Test Class Name:         
*    - 
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - vramachandran@rafter.one | 05 Dec 2023

*************************************************************/
public class ECOM_ApplicationLogsWrapper {


    @AuraEnabled public String logId;
    @AuraEnabled public String name;
    @AuraEnabled public String methodName;
    @AuraEnabled public String moduleName;
    @AuraEnabled public String className;
    @AuraEnabled public String createdBy;
    @AuraEnabled public DateTime createdDate;
    @AuraEnabled public String currencyIsoCode;
    @AuraEnabled public String logType;
    @AuraEnabled public String errorMessage;
    @AuraEnabled public String exceptionType;
    @AuraEnabled public String stackTrace;
    @AuraEnabled public String supportData;
    @AuraEnabled public String loginUserName;
    @AuraEnabled public String organizationName;
    @AuraEnabled public String status;
}