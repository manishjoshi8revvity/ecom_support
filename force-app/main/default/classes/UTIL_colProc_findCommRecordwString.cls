/**************************************************************
  * 1. Ticket(s) that relates to this class
  *    - OM-180
  *    - OM-215
  *
  * 2. Description - This class is used to compare a record collection with  
  *    a collection of Strings based on the provided field API Name and is used
  *    in reactive component called lwc_colproc_findcommrecordwstring
  *
  * 3. Objects referenced
  *    - None
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None
  *
  * 5. Dependant Class(es):
  *    - None
  *
  * 6. Test Class Name: UTIL_colProc_findCommRecordwString_Test
  *
  * 7. Is @Invocable (Yes or No):  No
  *
  * 8. Author Name(s): 
  *    - Aakash Pal 2023.10.25
  *
*************************************************************/
public class UTIL_colProc_findCommRecordwString {
    @AuraEnabled(cacheable=true)
    public static List <Result> compareRecordsWithStrings(List<SObject> sourceRecordCollection, List<String> targetStringCollection, String fieldAPI) {
        system.debug('inside apex ' + targetStringCollection);
        List<Result> outputResults =  new List<Result>();
        Result result = new Result();
        result.commonRecordCollection = new List<sObject>();
        
        result.sourceUniqueRecordCollection = new List<sObject>();
        result.targetUniqueStringCollection = new List<String>();
        Set<String> uniqueStrings = new Set<String>();
        Set<String> commonStrings = new Set<String>();
        
        //make sure we check that both collections are not empty/null
        if (sourceRecordCollection != null && targetStringCollection != null && 
            !targetStringCollection.isEmpty() && !sourceRecordCollection.isEmpty()) {
                
                //make input strings unique
                uniqueStrings.addAll(targetStringCollection);
                
                for(sObject sourceRecord : sourceRecordCollection){
                    //if the Input stings set contains target field's value, then mark it as common, else unique 
                    String sourceFieldValue = sourceRecord.get(fieldAPI).toString();
                    if (uniqueStrings.contains(sourceFieldValue)){
                        result.commonRecordCollection.add(sourceRecord);
                        commonStrings.add(sourceFieldValue);
                    } else {
                        result.sourceUniqueRecordCollection.add(sourceRecord);
                    }     
                }
                
                //if common strings are found, then remove them from original set to make it unique
                if(commonStrings.size() > 0) {
                    uniqueStrings.removeAll(commonStrings);
                    
                }
                result.targetUniqueStringCollection.addAll(uniqueStrings);
                
            }
        else if(targetStringCollection.isEmpty()) {
            
            result.sourceUniqueRecordCollection.addAll(sourceRecordCollection);
        }
        else if(sourceRecordCollection == null) {
            
            result.targetUniqueStringCollection.addAll(targetStringCollection);
        }
        outputResults.add(result);
        return outputResults;
    }
    
    public class Result {
        @AuraEnabled
        public List<sObject> sourceUniqueRecordCollection;
        
        @AuraEnabled
        public List<sObject> commonRecordCollection;
        
        @AuraEnabled
        public List<String> targetUniqueStringCollection;
        
    }
}