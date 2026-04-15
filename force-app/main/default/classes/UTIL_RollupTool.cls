/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *     - ATEAM-1615,OM-107
  * 2. Description - This Class invoked from Mass action to aggregate records based on field using C.Meta (Rollup_Counter_Mapping__mdt)
  * 3. Objects referenced
  *    -Rollup_Counter_Mapping__mdt
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None
  *   
  *
  * 5. Dependant Class(es):
  * 6. Invocable: True
  *
  * 7. Test Class Name: UTIL_RollupTool_Test
  *
  * 8. Author Name(s): 
  *    - Gowsik/Vishwas 29-12-2022
  * -    Vishwas 11-09-2023
*************************************************************/
public class UTIL_RollupTool {
	@InvocableMethod
    public static void flowcalled(List<FlowInputs> requests){                
        map<string,List<String>> mappingForParentIds=new map<string,List<string>>();
        List<string> MultisourceIds;
		set<string> MultisourceIdsset=new set<string>();
        set<string> tobeRemoveIds= new Set<string>();
        List<Sobject> objlist = new List<SObject>();		
        Map<String,Sobject> updateMap = new Map<String,SObject>();
        Map<String, Rollup_Counter_Mapping__mdt> mapEd = Rollup_Counter_Mapping__mdt.getAll();
        if(requests != null && !requests.isEmpty() && mapEd != null && !mapEd.KeySet().isEmpty()){
            for(FlowInputs fi: requests){
              string  varMappingFor =fi.varMappingFor;
                MultisourceIds=(fi.multiSourceRecordIds).split(',');
				MultisourceIdsset.addAll(MultisourceIds);
				mappingForParentIds.put(varMappingFor,MultisourceIds); // creating map of "map for" with parent Ids
				
			}
 			Map<Id,Sobject> myMap = new Map<Id,Sobject>();
            Map<string,Decimal> aggregateFieldresult=new Map<string,Decimal>();
			for(String mtn : mapEd.keyset()){
			string filterCriteria;
            		Rollup_Counter_Mapping__mdt recData=mapEd.get(mtn);
              //  system.debug('recData=='+recData);
					if(mappingForParentIds.containsKey(recData.Mapping_For__c)){
					filterCriteria =mergeObjectToString(mappingForParentIds.get(recData.Mapping_For__c),recData.Filter_Criteria__c);	
					// Creating Query string from custom Meta data
                        String query = 'SELECT '+recData.Aggregate_Operation__c+' ('+recData.Aggregate_Column__c+')recCount ,' + recData.Target_Object_Field__c +' From '+recData.Target_Object_API__c+' WHERE '+filterCriteria +' group by '+recData.Target_Object_Field__c;                     
                     AggregateResult[] groupedResults = Database.query(query);   // querying using created query string
						// Creating map of key(parentId+aggregated field API) with aggregate Result.	
                        for(AggregateResult result :groupedResults){
							aggregateFieldresult.put((Id)result.get(recData.Target_Object_Field__c)+':'+recData.RollUp_field__c,'Count'.equals(recData.Aggregate_Operation__c)? (Integer)result.get('recCount'): (Decimal)result.get('recCount'));
                            tobeRemoveIds.add((Id)result.get(recData.Target_Object_Field__c));  
                        }
                       //  system.debug('tobeRemoveIds'+tobeRemoveIds);
                        boolean removeproccesed= MultisourceIdsset.removeAll(tobeRemoveIds);
                       // system.debug('removeproccesed'+removeproccesed);
                        for(string var_ParentId:MultisourceIdsset){
                           aggregateFieldresult.put((Id)var_ParentId+':'+recData.RollUp_field__c,'Count'.equals(recData.Aggregate_Operation__c)? (Integer)0: (Decimal)0);
                           }						   
					}
			}
            // Below code Logic will create sobject and all its aggregated field with their result with respect to Created key(key in aggregateFieldresult) 
			if(aggregateFieldresult != null && !aggregateFieldresult.KeySet().isEmpty()){                            
						for(string prntRecordKey: aggregateFieldresult.KeySet()){
                          if(prntRecordKey != null && prntRecordKey.contains(':')){
                              if(myMap.containsKey(prntRecordKey.split(':')[0]) && prntRecordKey.split(':')[1] != null && prntRecordKey.split(':')[1] != 'null'){
                                 myMap.get(prntRecordKey.split(':')[0]).put(prntRecordKey.split(':')[1],aggregateFieldresult.get(prntRecordKey));
                              }
                              else if(prntRecordKey.split(':')[0] != null && prntRecordKey.split(':')[1] != null && prntRecordKey.split(':')[1] != 'null'){
                                SObject sObjectObj = Id.valueof(prntRecordKey.split(':')[0]).getSObjectType().newSObject(Id.valueof(prntRecordKey.split(':')[0]));
                                 sObjectObj.put(prntRecordKey.split(':')[1],aggregateFieldresult.get(prntRecordKey));
                                 myMap.put(prntRecordKey.split(':')[0],sObjectObj);
                               }
 							}                              
                                
                          }
                        } 
            // update Sobject which is values of myMap Map.
            Update myMap.values() ;
		}
           
    }
    
    // method to merge filter criteria and make it compatible for multiple parent ids
    private static String mergeObjectToString(List<String> MultisourceIds, String mergeString) {    
        mergeString = mergeString.toLowerCase();
        String finalMergeText ='';
        if(mergeString.contains('{{')) {
            string fld = mergeString.substringBetween('{{','}}').toLowerCase();
            string splitstr='\\{\\{'+fld+'\\}\\}';
            list<string> filterlist=mergeString.split(splitstr);
            mergeString =filterlist[0].trim()+'{{'+fld+'}}'; 
            mergeString = mergeString.replace('={{'+fld+'}}', 'IN :MultisourceIds'); 
            finalMergeText += mergeString ;
            finalMergeText += filterlist != null && filterlist.size() >1 ? filterlist[1] : '';
        }
        return finalMergeText;        
    }
   
        
	
	Public class FlowInputs {         
        @InvocableVariable public String varMappingFor;         
        @InvocableVariable public string multiSourceRecordIds;     
    }
    
}