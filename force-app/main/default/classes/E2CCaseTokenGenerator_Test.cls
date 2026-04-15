/**************************************************************
* 1. Jira Ticket(s)
*    - OM-395
*
* 2. Description - This apex class is used to test E2CCaseTokenGenerator.
*
* 3. Objects referenced
*    - Case
*
* 4. Callouts to additional Components (including their methods) or None:None
*    
* 5. Dependant Class(es):
*    - E2CCaseTokenGenerator
*    
*
* 6. Test Class Name:
* 
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s): 
*    - Sumit Kumar Sourav & Created Date(2024.07.03)
*    -
*************************************************************/
@istest
Public class E2CCaseTokenGenerator_Test {
    
    Public static testMethod void testE2CCaseTokenGeneration() {
        
        Test.startTest();
        
        case c1=new case();
        c1.subject='Test subject for c1';
        c1.Priority='Medium';
        c1.Origin='Email';
        c1.Case_Layout_Type__c ='Address Review';
        insert c1;
        
        E2CCaseTokenGenerator.Request req=new E2CCaseTokenGenerator.Request();
        List<E2CCaseTokenGenerator.Request> reqlist=new List<E2CCaseTokenGenerator.Request>();
        req.CaseId=c1.Id; 
        reqlist.add(req);
        E2CCaseTokenGenerator.generateE2CCaseToken(reqlist);
        
        Test.stopTest();
        
    }

}