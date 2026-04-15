/**************************************************************
* 1. Jira Ticket(s) that relates to this class 
   - OM-197
*
* 2. Description - This class is for the test coverage of UTIL_colProc_deepClone.
*
*
*
* 3. Objects referenced
*    -Generic
*
* 4. Callouts to additional Components (including their methods) or None:- None
*
* 5. Dependant Class(es):UTIL_colProc_deepClone
*
* 6. Test Class Name: UTIL_colProc_deepCloneTest
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Avinash Kumar & Updated Date(2023.10.18)
*
*************************************************************/
@isTest
public class UTIL_colProc_deepClone_Test {
    
    private static testMethod void deepClone() {
    
    List<Account> acc = new List<Account>();
    Account testAccount = new Account();
    testAccount.Name='Test Account' ;
    acc.add(testAccount);  
    insert acc;
    UTIL_colProc_deepClone.deepClone(acc);
    
    
    }

}