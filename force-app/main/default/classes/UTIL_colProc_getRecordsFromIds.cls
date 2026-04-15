/**************************************************************
* 1. Jira Ticket(s) that relates to this class 
	 - OM-208
*
* 2. Description - This class is for Pass in a list if IDs  and returns a specified collection of records .
*
*
*
* 3. Objects referenced
* 	 -Generic
*
* 4. Callouts to additional Components (including their methods) or None:- None
*
* 5. Dependant Class(es):
*
* 6. Test Class Name: UTIL_colProc_getRecordsFromIdsTest
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
* 	 - Sumit Sourav & Updated Date(2023.10.11)
*
*************************************************************/
public with sharing class UTIL_colProc_getRecordsFromIds {
   
    @AuraEnabled(cacheable=true)
    public static List<SObject> getRecordCollections(String IdObjectAPI,List<String> inputValueList,String RecordFields) {
       system.debug('Inside Apex ');
       String queryString='Select '+RecordFields+' From '+IdObjectAPI+' Where Id IN :inputValueList';
       system.debug('queryString = '+queryString);
       List<SObject> recordlist = Database.query(queryString);
       system.debug('Exiting Apex ');
       return recordlist;
       
       
    }
}