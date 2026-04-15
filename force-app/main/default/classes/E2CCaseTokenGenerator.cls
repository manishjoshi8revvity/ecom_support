/**************************************************************
* 1. Jira Ticket(s)
*    - OM-395
*
* 2. Description - This apex class is used to generate E2C Case Token.
*
* 3. Objects referenced
*    - Case
*
* 4. Callouts to additional Components (including their methods) or None:None
*    
* 5. Dependant Class(es):
*    - 
*    
*
* 6. Test Class Name: E2CCaseTokenGenerator_Test
* 
* 7. Is @Invocable (Yes or No): Yes
*
* 8. Author Name(s): 
*    - Sumit Kumar Sourav & Created Date(2024.07.02)
*    -
*************************************************************/
Public Class E2CCaseTokenGenerator{
    
    Public class Request {
        @InvocableVariable(
            label = 'Case Id'
            description = 'CaseId will be used to generate token.'
            required = true
        )
        public String CaseId;
        
    }
    
    @InvocableMethod(
        label = 'E2CCaseTokenGenerator'
        description = 'CaseId will be used to generate token.'
    )
    Public static List<String> generateE2CCaseToken (List<Request> requests){
        String formattedToken;
        List<String> formattedTokenlist=new List<String>();
        If(requests.Size()>0 && requests!=null){
            for(Request rq:requests) {
                ID cId = Id.valueOf(rq.CaseId); // Get the formatted threading token. 
                formattedToken = EmailMessages.getFormattedThreadingToken(cId);  
                If(formattedToken!=null){
                    formattedTokenlist.add(formattedToken);  
                }
                
            }
            
        }
        
        return formattedTokenlist;
    }
    
}