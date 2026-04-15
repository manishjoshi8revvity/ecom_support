/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-116
*    ECOM-118
*
* 2. Description - This class is used for contact specific transations -SOQL Operations.
					- return C_META_Storefront_Configuration__mdt to get SAP order date data
					- return ECOM_DummyAccountCountryMapping__mdt data to map CPAs.
* 3. Objects referenced
*    - contact
*    - ECOM_SalesOrgMapping__mdt
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_CheckoutController
*    - ECOM_ContactRepo
*    - ECOM_AccountWrapper
* 6. Test Class Name:
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vipul 2023.09.13
*	 - Vipul 2024.02.15 added getEmailContactDetails method
*	 - Vipul 2024.04.23 added getCountriesISO method
*	 - Sathiya 2024.04.29 added getStoreConfigs Method to get fetch store configuration per the label
*	 - Vipul 2024.04.30 added getAllCountryDetails method to all country support details.
*    - Manoj 2024-05-01 RWPS-584 Instrument freight not applying as expected on web orders(Created new method to fetch C_META_ECOM_Order_Type_Mapping__mdt meta data by developer name)
*	 - Sidak 2024.10.23 Updated method getSalesOrgs, getCountriesISO. Added Inactive flag in queries. Ticket - RWPS-1725
*	 - Sidak 2024.12.10 Added method getOrgType, used to fetch org type using custom setting. Ticket - RWPS-1662
*	 - Gaurav 2025.05.05 Added method getAllCountriesMsg to fetch promotion banner message - RWPS-3145
*	 - Prabhat 2025.07.11 Added methods getSiteIdAndTransporationGroupMapping - RWPS-1603
*    - Abhishek 2025.07.15 Replaced method getAllCountriesMsg with getActiveNotificationBannerMsg - RWPS-3651
*    - Abhishek 2025.07.15 Added method getCurrencyCodeFromSalesOrg - RWPS-3697
*    - Abhishek 2025.10.03 Added method getRecommendationsConfig - RWPS-4437

*************************************************************/
public without sharing class ECOM_CustomMetadataRepo {

    /**
    * @description  get sales org metadata information
    * @author mkumar@rafter.one | 09-21-2023
    * @author ssingh@rafter.one | 10-15-2024 | RWPS-1725
    * @param country
    * @return List<C_META_Countries__mdt>
    **/
    public static List<C_META_Countries__mdt> getSalesOrgs(String country)
    {
        List<C_META_Countries__mdt> salesOrgMappings = [SELECT Id, Country__c, SalesOrg__c, CountryISOAlpha2__c, CountryISOAlpha3__c
                                                        FROM C_META_Countries__mdt
                                                        WHERE Country__c = :country AND Inactive__c = false LIMIT 1];

        if(salesOrgMappings.isEmpty())
        {
            salesOrgMappings = [SELECT Id, Country__c, SalesOrg__c, CountryISOAlpha2__c, CountryISOAlpha3__c
                                FROM C_META_Countries__mdt
                                WHERE
                                CountryISOAlpha2__c = :country AND Inactive__c = false LIMIT 1];
        }
        if(salesOrgMappings.isEmpty())
        {
            salesOrgMappings = [SELECT Id, Country__c, SalesOrg__c, CountryISOAlpha2__c, CountryISOAlpha3__c
                                FROM C_META_Countries__mdt
                                WHERE
                                CountryISOAlpha3__c = :country AND Inactive__c = false LIMIT 1];
        }


        return salesOrgMappings;
    }

    /**
    * @description  This method is used to get Site Id and Transporation group mapping
    * @param source
    * @param type
    * @return CartItem
    * JIRA Ticket: RWPS-1603
     **/
    public static String getSiteIdAndTransporationGroupMapping(String source, String type)
    {
        List<ECOM_ShippingPointTransportGroupsMapping__mdt> mapping = [
            SELECT ECOM_Source__c, ECOM_Type__c, ECOM_Value__c
            FROM ECOM_ShippingPointTransportGroupsMapping__mdt
            WHERE ECOM_Source__c = :source AND ECOM_Type__c =: type
            LIMIT 1
        ];

        return (mapping.size() > 0) ? mapping[0].ECOM_Value__c : null;
    }

    /**
    * @description This method is used to fetch ECOM_DummyAccountCountryMapping__mdt data to map CPAs.
    * @author Manish | 2023.09.22
    * @param  dummyCountry
    * @return ECOM_DummyAccountCountryMapping__mdt
    **/
    public static ECOM_DummyAccountCountryMapping__mdt fetchDummyAccountCountryMappingData(String dummyCountry) {
        ECOM_DummyAccountCountryMapping__mdt DummyAcctCountryMdt = [SELECT Id, DeveloperName, Label, Dummy_Account__c,Country__c,Default_Ship_to__c,Default_Bill_To__c
                                                                    FROM ECOM_DummyAccountCountryMapping__mdt WHERE
                                                                    Country__c =: dummyCountry];//ECOM_DummyAccountCountryMapping__mdt.getAll();
        return DummyAcctCountryMdt;
    }

    /**
    * @description //To get Form Mapping based on Status
    * @author Vipul Goyal | 09-22-2023
    * @param status
    * @return List<ECOM_FormMapping__mdt>
    **/
    public static List<ECOM_FormMapping__mdt> getFormMappingBasedOnStatus(String status)
    {
        List<ECOM_FormMapping__mdt> formMappings=[
                                                    SELECT Id, Status__c, Option__c, formType__c FROM ECOM_FormMapping__mdt
                                                    where Status__c=:status
                                                 ];
        return formMappings;
    }

    /**
    * @description This method is used to fetch C_META_Storefront_Configuration__mdt data.
    * @author Manish | 2023.09.25
    * @return Map<String, C_META_Storefront_Configuration__mdt>
    **/
    public static Map<String, C_META_Storefront_Configuration__mdt> fetchSapOrderHistoryDateData() {
        Map<String, C_META_Storefront_Configuration__mdt> storeConfigMdtMap = C_META_Storefront_Configuration__mdt.getAll();
        return storeConfigMdtMap;
    }

    /**
    * @description This method is used to fetch C_META_Storefront_Configuration__mdt data based on module name.
    * @author Manish | 2023.10.14
    * @return List<C_META_Storefront_Configuration__mdt>
    **/
    public static List<C_META_Storefront_Configuration__mdt> fetchStoreConfigMdtBasedOnModuleName(String moduleName) {
        List<C_META_Storefront_Configuration__mdt> storeConfigMdtList = [Select Id, DeveloperName, ModuleName__c, Value__c FROM C_META_Storefront_Configuration__mdt WHERE ModuleName__c =: moduleName];
        return storeConfigMdtList;
    }

    public static String getDomain()
    {
        List<Domain> domains=[SELECT Id, DomainType, Domain, OptionsHstsPreload, CnameTarget, HttpsOption, CreatedDate FROM Domain where HttpsOption='CommunityAlt' Order By CreatedDate asc];
        if(!domains.isEmpty())
        {
            return domains[0].Domain;
        }
        else {
            return '';
        }
    }

    public static List<ECOM_OneTrust__mdt> getOneTrustScripts(String domain)
    {
        List<ECOM_OneTrust__mdt> oneTrustScripts = [SELECT Id, Value__c, Order__c, Key__c, Environment_URL__c
                                                    FROM ECOM_OneTrust__mdt
                                                    where Environment_URL__c=:domain
                                                    Order By Order__c
                                                    ];
        return oneTrustScripts;
    }

	/**
    * @description This method is used to fetch ECOM_CountryBasedContactDetails__mdt data based on country.
    * @author Vipul | 2024.02.15
    * @return List<ECOM_CountryBasedContactDetails__mdt>
    **/
    public static List<ECOM_CountryBasedContactDetails__mdt> getEmailContactDetails(String country)
    {
        List<ECOM_CountryBasedContactDetails__mdt> details=[Select id,CustomerCareEmail__c,CustomerCareNumber__c,SalesOrg__c,
                                                            SupportEmail__c
                                                            from ECOM_CountryBasedContactDetails__mdt
                                                            where MasterLabel=:country
                                                            ];
        return details;
    }

    /**
    * @description This method is used to fetch C_META_ECOM_Order_Type_Mapping__mdt data by developer name
    * @author Manoj | 2024.05.01
    * @return C_META_ECOM_Order_Type_Mapping__mdt
    **/
    public static C_META_ECOM_Order_Type_Mapping__mdt fetchOrderTypeByDeveloperName(String developerName) {
        C_META_ECOM_Order_Type_Mapping__mdt orderType = C_META_ECOM_Order_Type_Mapping__mdt.getInstance(developerName);
        return orderType;
    }


    /**
    * @description Method to retrieve all the country records based on a list of countries.This list can have ISO vallues or Country Names.
    * @author Vipul Goyal | 04-23-2024
    * @author Sidak Singh | 10-23-2024 | RWPS-1725
    * @param countries
    * @return List<C_META_Countries__mdt>
    **/
    public static List<C_META_Countries__mdt> getCountriesISO(List<String> countries)
    {
        List<C_META_Countries__mdt> countryISOs =new List<C_META_Countries__mdt>();
        List<C_META_Countries__mdt> countryISOsCountry = [SELECT Id, Country__c, SalesOrg__c, CountryISOAlpha2__c, CountryISOAlpha3__c
                                                   FROM C_META_Countries__mdt
                                                   WHERE Country__c in :countries AND Inactive__c = false];
        List<C_META_Countries__mdt> countryISOsCountryISOAlpha2 = [SELECT Id, Country__c, SalesOrg__c, CountryISOAlpha2__c, CountryISOAlpha3__c
                                                   FROM C_META_Countries__mdt
                                                   WHERE CountryISOAlpha2__c in:countries AND Inactive__c = false];
        List<C_META_Countries__mdt> countryISOsCountryISOAlpha3 = [SELECT Id, Country__c, SalesOrg__c, CountryISOAlpha2__c, CountryISOAlpha3__c
                                                   FROM C_META_Countries__mdt
                                                   WHERE CountryISOAlpha3__c in:countries AND Inactive__c = false];
        if(!countryISOsCountry.isEmpty())
        {
            countryISOs.addAll(countryISOsCountry);
        }
        if(!countryISOsCountryISOAlpha2.isEmpty())
        {
            countryISOs.addAll(countryISOsCountryISOAlpha2);
        }
        if(!countryISOsCountryISOAlpha3.isEmpty())
        {
            countryISOs.addAll(countryISOsCountryISOAlpha3);
        }
        return countryISOs;
    }

    /**
    * @description This method is used to fetch ECOM_Store_Configuration__mdt data for field validation per usage.
    * @author Sathiya | 2024.04.29
    * @param labelName
    * @return ECOM_Store_Configuration__mdt
    **/
    public static ECOM_Store_Configuration__mdt getStoreConfigs(String labelName){
        ECOM_Store_Configuration__mdt storeConfig = [SELECT Id, Value_RT__c FROM ECOM_Store_Configuration__mdt
                                                     WHERE MasterLabel =:labelName LIMIT 1];
        return storeConfig;
    }


    /**
    * @description Theis method is used to retrieve all the support records per country.
    * @author Vipul Goyal | 04-30-2024
    * @return List<ECOM_CountryBasedContactDetails__mdt>
    **/
    public static List<ECOM_CountryBasedContactDetails__mdt> getAllCountryDetails()
    {
        return [SELECT Id, CustomerCareEmail__c, CustomerCareNumber__c, SalesOrg__c, SupportEmail__c,MasterLabel, DeveloperName FROM ECOM_CountryBasedContactDetails__mdt];
    }

    /**
    * @description This method is used to check if an org is sandbox or not using custom setting
    * @author Sidak | 2024.12.10 | RWPS-1662
    * @param
    * @return Booledn
    **/
    public static Boolean getOrgType()
    {
        C_SET_9999_ORG_SETTINGS__c settings = C_SET_9999_ORG_SETTINGS__c.getInstance();
        return settings.isSBX__c;
    }

    /**
    * @description This method is used to retrieve message per country. RWPS-3145
    * @author Gaurav| 05-05-2025
    * @return List<ECOM_CountryBasedBannerMsg__mdt>
    **/
    public static Map<String,String> getActiveNotificationBannerMsg(String country, String userType, List<String> bannerCodes)
    {
        DateTime currentDateTime = system.now();

        List<ECOM_CountryBasedBannerMsg__mdt> bannerData = [
            SELECT DeveloperName, Banner_Text__c, Banner_Start_Date__c, Banner_Expiry_Date__c, ECOM_Country__c, Allowed_User_Types__c FROM ECOM_CountryBasedBannerMsg__mdt
            WHERE Active__c = true AND DeveloperName IN :bannerCodes
        ];

        Map<String,String> bannerDataMap = new Map<String,String>();
        for(ECOM_CountryBasedBannerMsg__mdt bannerDataObj : bannerData) {
            if(
                (
                    bannerDataObj.ECOM_Country__c == null
                    || bannerDataObj.ECOM_Country__c == ''
                    || bannerDataObj.ECOM_Country__c.containsIgnoreCase(country)
                ) && (
                    bannerDataObj.Allowed_User_Types__c == null
                    || bannerDataObj.Allowed_User_Types__c == ''
                    || bannerDataObj.Allowed_User_Types__c.containsIgnoreCase(userType)
                ) && (
                    bannerDataObj.Banner_Start_Date__c == null || bannerDataObj.Banner_Start_Date__c <= currentDateTime
                ) && (
                    bannerDataObj.Banner_Expiry_Date__c == null || bannerDataObj.Banner_Expiry_Date__c >= currentDateTime
                )
            ) {
                bannerDataMap.put(bannerDataObj.DeveloperName, bannerDataObj.Banner_Text__c);
            }
        }
        return bannerDataMap;
    }

    /**
    * @description This method is used to retrieve message per country
    * @author Abhishek 2025.07.14
    * @param salesOrg | String
    * @return C_META_Countries__mdt
    **/
    public static C_META_Countries__mdt getCurrencyCodeFromSalesOrg(String salesOrg)
    {
        return [SELECT CurrencyISOCode__c FROM C_META_Countries__mdt WHERE Inactive__c = false AND SalesOrg__c = :salesOrg LIMIT 1];
    }

    /**
    * @description This method is used to retrieve product recommendations config - RWPS-4437
    * @author Abhishek 2025.09.16
    * @return ECOM_Product_Recommendation_Config__mdt
    **/
    public static Map<String,String> getRecommendationsConfig()
    {
        List<ECOM_Product_Recommendation_Config__mdt> metadata = [SELECT DeveloperName, Value__c FROM ECOM_Product_Recommendation_Config__mdt];

        Map<String,String> configMap = new Map<String,String>();
        for(ECOM_Product_Recommendation_Config__mdt config : metadata) {
            configMap.put(config.DeveloperName, config.Value__c);
        }
        return configMap;
    }
    
}