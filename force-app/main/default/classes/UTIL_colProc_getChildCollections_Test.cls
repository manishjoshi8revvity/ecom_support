/**************************************************************
* 1. Jira Ticket(s) that relates to this class 
	 - OM-197
*
* 2. Description - This class is for the test coverage of UTIL_colProc_getChildCollections.
*
*
*
* 3. Objects referenced
* 	 -Generic
*
* 4. Callouts to additional Components (including their methods) or None:- None
*
* 5. Dependant Class(es):UTIL_colProc_getChildCollections
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
public class UTIL_colProc_getChildCollections_Test {
    
    private static testMethod void getChildCollections() {
        String ChildObjectType='Contact';
        String Parentfieldapi='Accountid';
        String FilterCriteria1='ID!=NULL';
        String FilterCriteria='';
        String ChildFields='Id,FirstName';
        String ParentrecordId='';
        Account acc1 = new Account();
                acc1.Name = 'test-1';
                insert acc1;
        ParentrecordId=acc1.Id;
        List<SObject> childrecrdList=new List<SObject>();
        childrecrdList=UTIL_colProc_getChildCollections.getChildCollections(ChildObjectType,	Parentfieldapi,FilterCriteria,ChildFields,ParentrecordId);
        childrecrdList=UTIL_colProc_getChildCollections.getChildCollections(ChildObjectType,	Parentfieldapi,FilterCriteria1,ChildFields,ParentrecordId);
    }

}