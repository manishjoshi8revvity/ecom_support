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
* 5. Dependant Class(es):UTIL_colProc_getRecordsFromIds
*
* 6. Test Class Name: 
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
* 	 - Sumit Sourav & Updated Date(2023.10.11)
*
*************************************************************/
@isTest
public class UTIL_colProc_getRecordsFromIds_Test {
    private static testMethod void getRecordCollections() {
        String IdObjectAPI='Account';
        List<String> inputValueList=new List<String>();
        String RecordFields='Id,Name';
        Account acc1 = new Account();
                acc1.Name = 'test-1';
                insert acc1;
        Account acc2 = new Account();
                acc2.Name = 'test-2';
                insert acc2;
        inputValueList.add(acc1.Id);
        inputValueList.add(acc2.Id);
        List<SObject> childrecrdList=new List<SObject>();
        childrecrdList=UTIL_colProc_getRecordsFromIds.getRecordCollections(IdObjectAPI,inputValueList,RecordFields);
    }

}