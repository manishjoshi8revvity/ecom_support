public with sharing class UTIL_colProc_getLookupCollections {
  
    @AuraEnabled(cacheable=true)
    public static List<SObject> fetchSobject(List<String> parentrecordsid,string commaseparatedfield,string objectapi){
       List<sobject> objectlist;
        system.debug(parentrecordsid + commaseparatedfield+objectapi);
        Try{
          objectlist= database.query('SELECT '+String.escapeSingleQuotes(commaseparatedfield)+ ' FROM '+ String.escapeSingleQuotes(objectapi)+ ' WHERE ID IN:parentrecordsid');
          system.debug(objectlist);
        }catch(exception ex){
           system.debug(ex.getCause()); 
        } 
        return objectlist;
    } 
}