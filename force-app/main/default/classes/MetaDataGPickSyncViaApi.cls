/**************************************************************
  * 1. Jira Ticket(s)
  *    - OM-146 APEX to modify Metadata via API to for syncing of G.Pick from Flow
  *
  * 2. Description - This apex class is used to sync G.Pick and its values with Provided info from Flow
  * 3. Objects referenced
  *    -Country__c
  *     state__c
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    FetchLARMetadataAPI Class Methods will be  to Update G.Pick and its values
  * 5. Dependant Class(es):
  *    - FetchLARMetadataAPI
  *    
  *
  * 6. Test Class Name: MetaDataGPickSyncViaApi_Test
  * 
  * 7. Is @Invocable (Yes or No): Yes
  *
  * 8. Author Name(s): 
  *    - Vishwas Kumar Gupta (PWC) & Created Date(10/25/2023)
  *
*************************************************************/ 
Public class MetaDataGPickSyncViaApi {
    Public class FlowInputs {             
        @InvocableVariable public String globalpicklistName;  
    }
@InvocableMethod
public static void flowcalled(List<FlowInputs> requests){
    if(requests != null && !requests.isEmpty() && requests[0].globalpicklistName != null){
        Map<string,country__c> Map_countryCode= new Map<string,country__c>();
		Map<string,State__c> Map_stateCode= new Map<string,State__c>();
        if(requests[0].globalpicklistName =='G_PICK_029_State'){
			List<State__c> var_StateList=[SELECT Id, integrationValue__c, Name FROM State__c];
			 if(var_StateList != null && !var_StateList.isEmpty()){
                for(State__c var_State:var_StateList){
                    Map_stateCode.put(var_State.integrationValue__c,var_State);
                }
            }
			 MetadataService1.MetadataPort service = LeadAssignmentRule_Calculations.createService();
            MetadataService1.GlobalValueSet GlobalVal = (MetadataService1.GlobalValueSet) service.readMetadata('GlobalValueSet',new String[] { 'G_PICK_029_State__gvs' }).getRecords()[0];
			for (MetadataService1.CustomValue customValue : GlobalVal.customValue) {
                if(Map_stateCode.containskey(customValue.fullName)){
                    customValue.label=Map_stateCode.get(customValue.fullName).Name;
                  //  customValue.isActive=true;
                    Map_stateCode.remove(customValue.fullName);
                }
            }
			 if(Map_stateCode != null && !Map_stateCode.keySet().isEmpty()){
               for(string var_state:Map_stateCode.keySet()){
                MetadataService1.CustomValue customValue = new MetadataService1.CustomValue();
                    customValue.fullName=var_state;
                    customValue.label=Map_stateCode.get(var_state).Name;
                    customValue.isActive=true;
                    customValue.color=null;
        			customValue.default_x=false;
            		customValue.description=null;
                   GlobalVal.customValue.add(customValue);
                } 
            }
			List<MetadataService1.GlobalValueSet> lst=New List<MetadataService1.GlobalValueSet>{GlobalVal};
                try{
                    List<MetadataService1.SaveResult> results =service.updateMetadata( lst );  
                }catch(exception ex){
                    system.debug(ex.getcause());
                }
			
        }else if(requests[0].globalpicklistName =='G_PICK_028_Country'){
            List<country__c> var_CountryList=[Select id,Name,Country_ISO_Alpha_2__c,Inactive__c  from country__c];
            
            if(var_CountryList != null && !var_CountryList.isEmpty()){
                for(country__c var_country:var_CountryList){
                    Map_countryCode.put(var_country.Country_ISO_Alpha_2__c,var_country);
                }
            }
            MetadataService1.MetadataPort service = LeadAssignmentRule_Calculations.createService();
            MetadataService1.GlobalValueSet GlobalVal = (MetadataService1.GlobalValueSet) service.readMetadata('GlobalValueSet',new String[] { 'G_PICK_028_Country__gvs' }).getRecords()[0];

            for (MetadataService1.CustomValue customValue : GlobalVal.customValue) {
                if(Map_countryCode.containskey(customValue.fullName)){
                    customValue.label=Map_countryCode.get(customValue.fullName).Name;
                 //   customValue.isActive=Map_countryCode.get(customValue.fullName).Inactive__c ? false : true;
                    Map_countryCode.remove(customValue.fullName);
                }
            }
            if(Map_countryCode != null && !Map_countryCode.keySet().isEmpty()){
               for(string var_country:Map_countryCode.keySet()){
                MetadataService1.CustomValue customValue = new MetadataService1.CustomValue();
                    customValue.fullName=var_country;
                    customValue.label=Map_countryCode.get(var_country).Name;
                    customValue.isActive=true;
                    customValue.color=null;
        			customValue.default_x=false;
            		customValue.description=null;
                   GlobalVal.customValue.add(customValue);
                } 
            }
            
            List<MetadataService1.GlobalValueSet> lst=New List<MetadataService1.GlobalValueSet>{GlobalVal};
                try{
                    List<MetadataService1.SaveResult> results =service.updateMetadata( lst );  
                }catch(exception ex){
                    system.debug(ex.getcause());
                }
        }
    }
    }
    Public static void syncGlobalValueSet(string gpickName,List<wrapper> wrapList){
Map<string,wrapper> map_wrapper=new Map<string,wrapper>();
if(wrapList != null && !wrapList.isEmpty()){
  for(wrapper wrap:wrapList){
  map_wrapper.put(wrap.fullName,wrap);
  }
}
 MetadataService1.MetadataPort service = LeadAssignmentRule_Calculations.createService();
            MetadataService1.GlobalValueSet GlobalVal = (MetadataService1.GlobalValueSet) service.readMetadata('GlobalValueSet',new String[] { gpickName+'__gvs' }).getRecords()[0];
			for (MetadataService1.CustomValue customValue : GlobalVal.customValue) {
                if(map_wrapper.containskey(customValue.fullName)){
                    customValue.label=map_wrapper.get(customValue.fullName).label;
                   customValue.isActive=map_wrapper.get(customValue.fullName).isActive;
                    map_wrapper.remove(customValue.fullName);
                }
            }
			 if(map_wrapper != null && !map_wrapper.keySet().isEmpty()){
               for(string var_fullName:map_wrapper.keySet()){
                MetadataService1.CustomValue customValue = new MetadataService1.CustomValue();
                   if(var_fullName != null){
                    customValue.fullName=var_fullName;
                    customValue.label=map_wrapper.get(var_fullName).label;
                    customValue.isActive=map_wrapper.get(var_fullName).isActive;
                    customValue.color=null;
        			customValue.default_x=false;
            		customValue.description=null;
                   GlobalVal.customValue.add(customValue);
                   }
                   
                } 
            }
			List<MetadataService1.GlobalValueSet> lst=New List<MetadataService1.GlobalValueSet>{GlobalVal};
                try{
                    List<MetadataService1.SaveResult> results =service.updateMetadata( lst );  
                }catch(exception ex){
                    system.debug(ex.getcause());
                    system.debug(ex.getMessage());
                    system.debug(ex.getLineNumber());
                    system.debug(ex.getStackTraceString());
                }
}
public class wrapper{
	public string label{get;set;}
	public string fullName{get;set;}
	public boolean isActive{get;set;}
}
  }