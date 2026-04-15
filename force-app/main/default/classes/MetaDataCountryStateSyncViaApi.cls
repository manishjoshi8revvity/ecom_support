/**************************************************************
* 1. Jira Ticket(s)
*    - OM-165 APEX to modify Metadata via API to for sync Address Setting  with Country__c and State__c Objects
*
* 2. Description - This apex class is used to sync Address Setting  with Country__c and State__c Objects
* 3. Objects referenced
*    -Country__c
*     state__c
*
* 4. Callouts to additional Components (including their methods) or None:
*    FetchLARMetadataAPI Class Methods will be  to Update and Create ListView 
* 5. Dependant Class(es):
*    - FetchLARMetadataAPI
*    
*
* 6. Test Class Name: MetaDataCountryStateSyncViaApi_Test
*
* 7. Author Name(s): 
*    - Vishwas Kumar Gupta (PWC) & Created Date(18/03/2023)
*    -Vishwas Kumar Gupta (PWC) Added logic for State ISOCode Concanate Country ISOCode with StateISO Code 
*
*************************************************************/ 
global class MetaDataCountryStateSyncViaApi implements Database.Batchable<sObject>, Database.AllowsCallouts{
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        String queryString ='SELECT Id, Name, Country_ISO_Alpha_2__c,integrationValue__c, SFDC_Country_Name__c FROM Country__c';
        return Database.getQueryLocator(queryString);
    }
    // Execute Method -- perfoem all operation on each batch of records...
    public void execute(Database.BatchableContext BC, List<Country__c> Scope){
        Map<string,country__c> countryisoMap= New Map<string,country__c>();
		set<Id> var_Ids= new set<Id>();
        for(country__c var_Country:Scope){
            countryisoMap.put(var_Country.Country_ISO_Alpha_2__c,var_Country);
			var_Ids.add(var_Country.Id);
        }
		Map<String,State__c> mapstate = new Map<String,State__c>();
		List<State__c> var_StateListCompare=[SELECT Id, Name, SFDC_State_Name__c, ISOCode__c, integrationValue__c, Country__r.Country_ISO_Alpha_2__c FROM State__c WHERE Country__r.Id IN:var_Ids];
		for(State__c var_state:var_StateListCompare){
			String Key_String=var_state.ISOCode__c;
			mapstate.put(Key_String,var_state);
		}
        List<country__c> var_countrylist=new list<country__c>();
        List<state__c> var_statelistInsert=new list<state__c>();
		List<state__c> var_statelistUpdate=new list<state__c>();
        MetadataService1.MetadataPort service = LeadAssignmentRule_Calculations.createService();
        MetadataService1.AddressSettings addressSettings = (MetadataService1.AddressSettings) service.readMetadata('AddressSettings',new String[] { 'Address' }).getRecords()[0];
        if(addressSettings.countriesAndStates != null && addressSettings.countriesAndStates.countries != null){
                for(MetadataService1.Country var_Country:addressSettings.countriesAndStates.countries){
                    // string recordtypecomma =cntry.label+','+cntry.integrationValue+','+cntry.isoCode+','+'\n';  
                    if(countryisoMap.containskey(var_Country.isocode)){
                        countryisoMap.get(var_Country.isocode).SFDC_Country_Name__c=var_Country.label;
                        countryisoMap.get(var_Country.isocode).integrationValue__c=var_Country.integrationValue;
                        var_countrylist.add(countryisoMap.get(var_Country.isocode));
                    }	
                    if(var_Country.states != null && !var_Country.states.isEmpty() && countryisoMap.containskey(var_Country.isocode)){	  
                        for(MetadataService1.State var_State: var_Country.states){
							String Key_String=var_Country.isocode+var_State.isocode;
							if(mapstate.containsKey(Key_String)){
							mapstate.get(Key_String).SFDC_State_Name__c=var_State.label;
                            mapstate.get(Key_String).ISOCode__c=Key_String;                       //var_State.isocode;
                            mapstate.get(Key_String).integrationValue__c=var_State.integrationValue;
                            mapstate.get(Key_String).Country__c=countryisoMap.get(var_Country.isocode).Id;
							var_statelistUpdate.add(mapstate.get(Key_String));	
							}else{
                            state__c int_state= new state__c();
                            int_state.Name=var_State.label;
                            int_state.SFDC_State_Name__c=var_State.label;
                            int_state.ISOCode__c=Key_String; //var_State.isocode;
                            int_state.integrationValue__c=var_State.integrationValue;
                            int_state.Country__c=countryisoMap.get(var_Country.isocode).Id;
                            var_statelistInsert.add(int_state);
							}
                        }
                    }
                }
                if(var_countrylist !=null && !var_countrylist.isEmpty()){
                    Update var_countrylist;
                }
                if(var_statelistInsert !=null && !var_statelistInsert.isEmpty()){
                    Insert var_statelistInsert;
                }
				if(var_statelistUpdate !=null && !var_statelistUpdate.isEmpty()){
                    Update var_statelistUpdate;
                }
            }
    }
    // Finish method just to delete next schedule job using CronTrigger object.......
    public void finish(Database.BatchableContext BC){
        system.debug('finish');
    }	
}