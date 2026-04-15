/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*
*
* 2. Description - This class is used for contact specific transations.
					- return C_META_Storefront_Configuration__mdt to get SAP order date data
					- return ECOM_DummyAccountCountryMapping__mdt data to map CPAs.
*
* 3. Objects referenced
*    - contact
*    - ECOM_SalesOrgMapping__mdt
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
* 5. Dependant Class(es):
*  - ECOM_CustomMetadataRepo
* 6. Test Class Name: ECOM_CustomMetadataService_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vipul 2023.09.13
*	 - Vipul 2024.02.15 added getEmailContactDetails method
*	 - Vipul 2024.04.23 added getCountriesISO method
*	 - Sathiya 2024.04.29 added getStoreConfigurationByLabel Method to get fetch store configuration per the label
*	 - Vipul 2024.04.30 added getCountryToOrgWideEmailMapping Method to map country with OrgwideEmailId.
*	 - Sidak 2024.10.15 Updated method getEmailContactDetails. Added size check for salesOrgMapping. Ticket - RWPS-1725
*	 - Sidak 2024.12.10 Added method getOrgType, used to fetch org type using custom setting. Ticket - RWPS-1662
*************************************************************/
public without sharing class ECOM_CustomMetadataService {
    
    /**
    * @description 
    * @author Vipul | 2023.09.13
    * @param country 
    * @return String 
    **/
    public static String getSalesOrg(String country)
    {
        List<C_META_Countries__mdt> salesOrgs = ECOM_CustomMetadataRepo.getSalesOrgs(country);
        return salesOrgs[0].SalesOrg__c;
    }

    /**
    * @description This method is used to fetch ECOM_DummyAccountCountryMapping__mdt data to map CPAs.
    * @author Manish | 2023.09.22
    * @param dummyCountry
    * @return ECOM_DummyAccountCountryMapping__mdt 
    **/
    public static ECOM_DummyAccountCountryMapping__mdt fetchDummyAccountCountryMappingData(String dummyCountry) {
        return ECOM_CustomMetadataRepo.fetchDummyAccountCountryMappingData(dummyCountry);
    }

    public static List<ECOM_FormMapping__mdt> getFormMappingBasedOnStatus(String status)
    {
        return ECOM_CustomMetadataRepo.getFormMappingBasedOnStatus(status);
    }

    /**
    * @description This method is used to fetch C_META_Storefront_Configuration__mdt to get SAP order date data.
    * @author Manish | 2023.09.25
    * @return Map<String, C_META_Storefront_Configuration__mdt> 
    **/
    public static Map<String, C_META_Storefront_Configuration__mdt> fetchSapOrderHistoryDateData() {
        return ECOM_CustomMetadataRepo.fetchSapOrderHistoryDateData();
    }

    /**
    * @description This method is used to fetch C_META_Storefront_Configuration__mdt data based on module name.
    * @author Manish | 2023.10.14
    * @return List<C_META_Storefront_Configuration__mdt> 
    **/
    public static List<C_META_Storefront_Configuration__mdt> fetchStoreConfigMdtBasedOnModuleName(String moduleName) {
        return ECOM_CustomMetadataRepo.fetchStoreConfigMdtBasedOnModuleName(moduleName);
    }

    public static List<ECOM_OneTrust__mdt> getOneTrustScripts()
    {
        String domain = ECOM_CustomMetadataRepo.getDomain();
        if(String.isNotBlank(domain))
        {
            return ECOM_CustomMetadataRepo.getOneTrustScripts(domain);
        }
        return new List<ECOM_OneTrust__mdt>();
    }

    /**
    * @description This method is used to fetch ECOM_CountryBasedContactDetails__mdt data based on country.
    * @author Vipul | 2024.02.15
    * @author Sidak | 2024.10.15 | RWPS-1725
    * @author Sathiya | 2024.11.06 | UAT Fix
    * @return Map<String,String>
    **/
    public static Map<String,String> getEmailContactDetails(String country)
    {
        Map<String,String> returnMap = new Map<String,String>();
        String fullCountryName='';
        if(String.isNotBlank(country))
        {
            List<C_META_Countries__mdt> salesOrgMapping=ECOM_CustomMetadataRepo.getSalesOrgs(country);
            if(salesOrgMapping.size() > 0){ //RWPS-1725
                fullCountryName = salesOrgMapping[0].Country__c;
                List<ECOM_CountryBasedContactDetails__mdt> mapping=ECOM_CustomMetadataRepo.getEmailContactDetails(fullCountryName);
                if(!mapping.isEmpty())
                {
                    returnMap.put('CustomerCareNumber',mapping[0].CustomerCareNumber__c);
                    returnMap.put('CustomerCareEmail',mapping[0].SupportEmail__c);
                    returnMap.put('CustomerCareEmailAddress',mapping[0]?.CustomerCareEmail__c);
                    returnMap.put('salesOrg',mapping[0].SalesOrg__c);
                }
            }
        }
        return returnMap;
    }
    
    

    /**
    * @description This method is used to get a List of country names that can be asscoiated to a particular county i.e. ISO codes.
    * @author Vipul Goyal | 04-23-2024 
    * @param countries 
    * @return Map<String, List<String>> 
    **/
    public static Map<String,List<String>> getCountriesISO(List<String> countries)
    {
        Map<String,List<String>> countriesISOs = new Map<String,List<String>>();
        List<C_META_Countries__mdt> countriesIsoRecords = ECOM_CustomMetadataRepo.getCountriesISO(countries);
        for(C_META_Countries__mdt cISO:countriesIsoRecords)
        {
            List<String> currentCountries=new List<String>{cISO.Country__c,cISO.CountryISOAlpha2__c,cISO.CountryISOAlpha3__c};
            if(countries.contains(cISO.Country__c))
            {
                countriesISOs.put(cISO.Country__c,currentCountries);
            }
            else if(countries.contains(cISO.CountryISOAlpha2__c))
            {
                countriesISOs.put(cISO.CountryISOAlpha2__c,currentCountries);
            }
            else if(countries.contains(cISO.CountryISOAlpha3__c))
            {
                countriesISOs.put(cISO.CountryISOAlpha3__c,currentCountries);
            }
        }
        return countriesISOs;
    }
    
    /**
    * @description This method is used to fetch JSON string based on the label through the store configuration.
    * @author Sathiya | 2023.09.29
    * @param labelName
    * @return String 
    **/
    public static String getStoreConfigurationByLabel(String labelName) {
        String configJSON;
        ECOM_Store_Configuration__mdt storeConfig = ECOM_CustomMetadataRepo.getStoreConfigs(labelName);
        if(null != storeConfig && String.isNotEmpty(storeConfig.Value_RT__c)){
            configJSON = storeConfig.Value_RT__c;
        }
        return configJSON;
    }
   
    
    /**
    * @description Method to get the country mapping with OrgWideEmailAddresses
    * @author Vipul Goyal | 04-30-2024 
    * @return Map<String, String> 
    **/
    public static Map<String,String> getCountryToOrgWideEmailMapping()
    {
        Map<String,String> countryToOrgWideEmailMap = new Map<String,String>();
        List<ECOM_CountryBasedContactDetails__mdt> countryMapping=  ECOM_CustomMetadataRepo.getAllCountryDetails();
        
        List<String> countries= new List<String>();
        List<String> fromEmails = new List<String>();
        
        for(ECOM_CountryBasedContactDetails__mdt cbc:countryMapping)
        {
            if(String.IsNotBlank(cbc.SupportEmail__c))
            {
                countries.add(cbc.MasterLabel);
                fromEmails.add(cbc.CustomerCareEmail__c);
            }
        }
        
        if(!fromEmails.isEmpty())
        {
            List<OrgWideEmailAddress> emailAddresses = [SELECT Id, Address FROM OrgWideEmailAddress where Address in :fromEmails];
            
            Map<String,String> addressToIdMap = new Map<String,String>();
            
            for(OrgWideEmailAddress owe:emailAddresses)
            {
                addressToIdMap.put(owe.Address,owe.Id);
            }           
            
            List<C_META_Countries__mdt> countriesIsoRecords = ECOM_CustomMetadataRepo.getCountriesISO(countries);
            Map<String,List<String>> countryIsoMapping = new Map<String,List<String>>();
            
            for(C_META_Countries__mdt cir : countriesIsoRecords)
            {
                countryIsoMapping.put(cir.Country__c,new List<String>{cir.Country__c,cir.CountryISOAlpha2__c,cir.CountryISOAlpha3__c});
            }
            
            System.debug('countryIsoMapping : '+JSOn.serialize(countryIsoMapping));
            System.debug('addressToIdMap : '+JSOn.serialize(addressToIdMap));
            
            for(ECOM_CountryBasedContactDetails__mdt cm: countryMapping)
            {
                List<String> tempIso = countryIsoMapping.get(cm.MasterLabel);
                String orgWideId = addressToIdMap.get(cm.CustomerCareEmail__c);
                if(String.isNotBlank(orgWideId))
                {
                    for(String temp:tempIso)
                    {
                        countryToOrgWideEmailMap.put(temp,orgWideId);
                    }
                }
            }
            
        }
        
        return countryToOrgWideEmailMap;
    }

    /**
    * @description This method is used to check if an org is sandbox or not using custom setting
    * @author Sidak | 2024.12.10 | RWPS-1662
    * @param  
    * @return Booledn 
    **/
    public static Boolean getOrgType()
    {
        Boolean isSandbox = ECOM_CustomMetadataRepo.getOrgType();
        return isSandbox;
    }

}