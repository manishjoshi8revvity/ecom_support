public class UTIL_General_Bypass_Pause_Event {
    @InvocableMethod
    public static void createNewtransaction(List<SObject> sobjList){
        String objJSONStr = Json.serialize(sobjList); 
        updateSobjectList( objJSONStr );
    }
    
    @future
    public static void updateSobjectList( String objstr ) {
        try{
            system.debug('@@objstr'+objstr);
            List<SObject> obj=(List<SObject>) Json.deserialize(objstr, System.Type.forName('List<SObject>'));
           update obj; 
        }
        
        catch(exception ex) {
            system.debug('@@ex'+ex.getLineNumber());
            system.debug('@@ex'+ex.getMessage());
            
        }
    }
}