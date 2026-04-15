/**************************************************************
  * 1. Ticket(s) that relates to this class
  *    - OM-180
  *    - OM-204
  *
  * 2. Description - This class is used to compare two record collections 
  *    of same SObject type based on the provided field API Name and is used
  *    in reactive component called lwc_colproc_findcommonrecords
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
  * 6. Test Class Name: UTIL_colProc_findCommonRecords_Test
  *
  * 7. Is @Invocable (Yes or No):  No
  *
  * 8. Author Name(s): 
  *    - Aakash Pal 2023.10.23
  *
*************************************************************/ 

public class UTIL_colProc_findCommonRecords {
    
    @AuraEnabled(cacheable=true)
    public static List <Result> compareRecords(List<SObject> sourceRecordCollection, List<SObject> targetRecordCollection, String fieldAPI) {
        system.debug('inside apex');
        List<Result> outputResults =  new List<Result>();
        Result result = new Result();
        result.commonRecordCollection = new List<sObject>();
        result.uncommonRecordCollection = new List<sObject>();
        result.sourceUniqueRecordCollection = new List<sObject>();
        result.targetUniqueRecordCollection = new List<sObject>();
        //make sure we check that both collections are not empty/null
        if (sourceRecordCollection != null && targetRecordCollection != null && 
            !targetRecordCollection.isEmpty() && !sourceRecordCollection.isEmpty()) {
                
                
                //puts the source collection into a map so we can compare with the target collection map
                Map<String, Sobject> sourceMap = new Map<String, Sobject>();
                
                // Loop over the source collection
                for(sObject sourceRecord : sourceRecordCollection){
                    
                    //grab the value of the Unique ID field
                    String sourceCurrentFieldValue = (String)sourceRecord.get(fieldAPI);
                    
                    //as long as the unique value isnt blank, put it in the sourceMap map to be used later
                    if (sourceCurrentFieldValue != null && sourceCurrentFieldValue != '') {
                        sourceMap.put(sourceCurrentFieldValue, sourceRecord);
                    }
                }
                
                //puts the target collection into a map so we can compare with the source collection
                Map<String, sObject> targetMap = new Map<String, sObject>();
                
                for(sObject targetRecord : targetRecordCollection){
                    String targetCurFieldValue = (String)targetRecord.get(fieldAPI);
                    
                    //as long as the unique value isnt blank, put it in the targetMap map to be used later
                    if (targetCurFieldValue != null && targetCurFieldValue != ''){
                        targetMap.put(targetCurFieldValue, targetRecord);
                    }  
                }
                
                if(targetMap != null && !targetMap.isEmpty()) {
                    for(sObject sourceRecord : sourceRecordCollection){
                        /*if targetField's value from the source collection exists in targetMap, add */
                        /*it to the common record collection, else add to the source unique collection*/
                        String sourceFieldValue = sourceRecord.get(fieldAPI).toString();
                        
                        if (targetMap.containsKey(sourceFieldValue)){
                            result.commonRecordCollection.add(sourceRecord);
                        } else {
                            result.sourceUniqueRecordCollection.add(sourceRecord);
                            result.uncommonRecordCollection.add(sourceRecord);
                        }     
                    }
                }
                if(sourceMap != null && !sourceMap.isEmpty()) {
                    for(sObject targetRecord : targetRecordCollection){
                        /*if targetField's value from the target collection exists in sourceMap, add*/  
                        /*it to the common record collection, else add to the target unique collection*/
                        String targetFieldValue = targetRecord.get(fieldAPI).toString();
                        
                        if (sourceMap.containsKey(targetFieldValue)){
                            result.commonRecordCollection.add(targetRecord);
                        } else {
                            result.targetUniqueRecordCollection.add(targetRecord);
                            result.uncommonRecordCollection.add(targetRecord);
                        }
                    }
                }
                
            }
        else if(targetRecordCollection == null) {
            result.sourceUniqueRecordCollection.addAll(sourceRecordCollection);
            result.uncommonRecordCollection.addAll(sourceRecordCollection);
        }
        else if(sourceRecordCollection == null) {
            result.targetUniqueRecordCollection.addAll(targetRecordCollection);
            result.uncommonRecordCollection.addAll(targetRecordCollection);
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
        public List<sObject> targetUniqueRecordCollection;
        
        @AuraEnabled
        public List<sObject> uncommonRecordCollection;            
        
    }
}