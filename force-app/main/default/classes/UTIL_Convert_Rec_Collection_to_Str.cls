/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *
  * 2. Description -Utillity class for conversion of collection to String
  * 3. Objects referenced
  *    -None
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None
  *   
  *
  * 5. Dependant Class(es):
  * 6. Invocable: True
  *
  * 7. Test Class Name: UTIL_Convert_Rec_Collection_to_Str_Test
  *
  * 8. Author Name(s): 
  *    - Vishwas 25-08-2023
  *    - Vishwas & Shubham Modified(03-10-2024): Optimised it to handle bulk operation
  *
*************************************************************/ 
public class UTIL_Convert_Rec_Collection_to_Str {
   @InvocableMethod
    public static list<FlowOutputs> flowcalled(List<FlowInputs> requests){
       list<FlowOutputs> fOutlist = new list<FlowOutputs>();
        if(requests != null && !requests.isEmpty()){
            for(FlowInputs req:requests){
            string  outputString ;
            list<string> collectionstring=new list<string>();
                FlowOutputs fout = new FlowOutputs();
                    if(req.sobjectList != null && !req.sobjectList.isEmpty()){
                        for(sObject Obj: req.sobjectList){
                           collectionstring.add(string.valueof(Obj.get(req.fieldApi) != null ? Obj.get(req.fieldApi) : '')); 
                        }
                    }
                fout.varString= string.join( collectionstring,',');
                fOutlist.add(fout);    
                 
            }
            
        }
     return fOutlist;
    }
     Public class FlowInputs { 
           @InvocableVariable public List<Sobject> sobjectList; 
           @InvocableVariable public string fieldApi; 
         
                
    }
    Public class FlowOutputs {         
       @InvocableVariable public String varString;         
    }
}