/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    - RWPS-678
* 2. Description 
*    - This Class is use to test UTIL_CustomMerge
*    
* 3. Objects referenced 
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
* 5. Dependant Class(es):UTIL_CustomMerge
* 6. Invocable: True
*
* 7. Test Class Name:
*
* 8. Author Name(s): 
*      
*    - 2024.05.21 / RWPS-678 / Sumit Sourav   BASE  
*************************************************************/
@isTest
public class UTIL_CustomMergeTest {
    private static testMethod void doMerge() {
        
        Test.startTest();
            Account m = new Account(Name = 'Master');
            Account d = new Account(Name = 'Duplicate');
            Account o=new Account(Name='Other');
            List<Account> acclist=new List<Account>{m,d,o};
            Insert acclist;
            Contact c1=new Contact(LastName='C1',AccountId=m.Id);
            Contact c2=new Contact(LastName='C2',AccountId=d.Id);
            Contact c3=new Contact(LastName='C3',AccountId=o.Id);
        	List<Contact> clist=new List<Contact>{c1,c2,c3};
            insert clist;
            AccountContactRelation acr1=new AccountContactRelation(ContactId=c3.Id,AccountId=d.Id);
            //insert acr1;
            UTIL_CustomMerge.Request req=new UTIL_CustomMerge.Request();
            req.masterRecord=m;
            req.duplicateRecord=d;
            List<UTIL_CustomMerge.Request> reqlist=new List<UTIL_CustomMerge.Request>();
            reqlist.add(req);
            UTIL_CustomMerge.execute(reqlist);
            UTIL_CustomMerge.Request req2=new UTIL_CustomMerge.Request();
            req2.masterRecord=m;
            req2.duplicateRecord=m;
            List<UTIL_CustomMerge.Request> reqlist2=new List<UTIL_CustomMerge.Request>();
            reqlist2.add(req2);
            UTIL_CustomMerge.execute(reqlist2);
            UTIL_CustomMerge.handleACRs(m,d);
        Test.stopTest();
        
    }
}