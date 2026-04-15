/**************************************************************
* 1. Jira Ticket(s) that relates to this class 
	 - OM-197
*
* 2. Description - This class is for Pass in a recordID (as a string), and returns a specified collection of child records related to the input record.
*
*
*
* 3. Objects referenced
* 	 -Generic
*
* 4. Callouts to additional Components (including their methods) or None:- None
*
* 5. Dependant Class(es):UTIL_colProc_getChildCollectionsTest
*
* 6. Test Class Name: 
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
* 	 - Sumit Sourav & Updated Date(2023.10.11)
*
*************************************************************/
public with sharing class UTIL_colProc_getChildCollections {
    @AuraEnabled(cacheable=true)
    
    public static List<SObject> getChildCollections(String ChildObjectType,String Parentfieldapi,String FilterCriteria,String ChildFields, String ParentrecordId ) {
        system.debug('Inside Apex ');
        String filter='';
        system.debug('FilterCriteria = '+FilterCriteria);
        If(FilterCriteria!=null && FilterCriteria!=''){
        filter=' Where '+Parentfieldapi+' = \''+ParentrecordId+'\' AND '+FilterCriteria;
       }
       else{
        filter=' Where '+Parentfieldapi+' = \''+ParentrecordId+'\'';
       }
       String queryString='Select '+ChildFields+' From '+ChildObjectType+filter;
       system.debug('queryString = '+queryString);
       List<SObject> childobjectlist = Database.query(queryString);
       system.debug('Exiting Apex ');
       return childobjectlist;
       
       
    }
}