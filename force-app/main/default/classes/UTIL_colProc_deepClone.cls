/**************************************************************
* 1. Jira Ticket(s) that relates to this class 
     - OM-198
*
* 2. Description - Class to clone an SObject and it's children.
*
*
*
* 3. Objects referenced
*    -Generic
*
* 4. Callouts to additional Components (including their methods) or None:- None
*
* 5. Dependant Class(es):UTIL_colProc_deepCloneTests
*
* 6. Test Class Name: 
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Avinash Kumar & Updated Date(2023.10.18)
*
*************************************************************/
public class UTIL_colProc_deepClone {
     @AuraEnabled
     public static List<Sobject> deepClone(List<Sobject> currentObj){
     List<Sobject> sObjectList = new List<Sobject>();
     system.debug('call'+currentObj);
     Sobject currObj;
     currObj= currentObj[0].clone(false, true, true, false);
     system.debug('currObj'+currObj);
     sObjectList.add(currObj);
   //system.debug('sObjectList'+sObjectList);
    // insert sObjectList;
     //system.debug('sObjectList'+sObjectList);
     return sObjectList;
     
     }
}