/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-    
*
* 2. Description - This class is a test class for ECOM_CustomMetadataService
*
*
* 3. Objects referenced
*   - ECOM_FormMapping__mdt
*	- ECOM_DummyAccountCountryMapping__mdt
*	- C_META_Storefront_Configuration__mdt
*	- ECOM_OneTrust__mdt
*	- C_META_ECOM_Order_Type_Mapping__mdt
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
*
* 5. Dependant Class(es):
*    - ECOM_TestUtil
*    - ECOM_CustomMetadataService
*    - ECOM_CustomMetadataRepo
* 6. Test Class Name: ECOM_CustomMetadataService_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Base 
*    - Manoj 2024-05-02 RWPS-584 Instrument freight not applying as expected on web orders(Covered fetchOrderTypeByDeveloperName method )
*************************************************************/
@isTest
public class ECOM_CustomMetadataService_Test {
    @TestSetup
    public static void testData() {
		ECOM_TestUtil.testDataIntialSetup();
    }
    
    @isTest
    public static void getSalesOrgTest(){
        Test.startTest();
        	String salesorg = ECOM_CustomMetadataService.getSalesOrg('United States');
        	System.assertEquals(salesorg, 'US10');
        Test.stopTest();
    }
    
    @istest
    public static void getDummyAccountTest(){
        Test.startTest();
        ECOM_DummyAccountCountryMapping__mdt dummyMdt = ECOM_CustomMetadataService.fetchDummyAccountCountryMappingData('United States');
   		Test.stopTest();
    }
    @isTest
    public static void formMappingsTest(){
        Test.startTest();
        	List<ECOM_FormMapping__mdt> formMappings = ECOM_CustomMetadataService.getFormMappingBasedOnStatus('Open');
        Test.stopTest();
    }
    @isTest
    public static void getConfigTest(){
        Test.startTest();
        	Map<String, C_META_Storefront_Configuration__mdt> configMap =  ECOM_CustomMetadataService.fetchSapOrderHistoryDateData();
        Test.stopTest();
    }
    @isTest
    public static void getConfigByModuleTest(){
        Test.startTest();
        	List<C_META_Storefront_Configuration__mdt> configs =  ECOM_CustomMetadataService.fetchStoreConfigMdtBasedOnModuleName('SiteURL');
        Test.stopTest();
    }
    @isTest
    public static void getOneTrustScriptsTest(){
         Test.startTest();
        List<ECOM_OneTrust__mdt> oneTrustconfigs = ECOM_CustomMetadataService.getOneTrustScripts();
         Test.stopTest();
        
    }
    @isTest
    public static void testfetchOrderTypeByDeveloperNameMethod(){
         Test.startTest();
        	C_META_ECOM_Order_Type_Mapping__mdt orderMapping = ECOM_CustomMetadataRepo.fetchOrderTypeByDeveloperName('US1O');
         Test.stopTest();
        
    }
    
    @isTest
    public static void testgetEmailContactDetails(){
        Test.startTest();
        ECOM_CustomMetadataService.getEmailContactDetails('United States');
        ECOM_CustomMetadataService.getCountriesISO(new List<String>{'United States'});
        ECOM_CustomMetadataService.getStoreConfigurationByLabel(ECOM_Constant.BILL_TO_FIELD_VALIDATION);
        ECOM_CustomMetadataService.getCountryToOrgWideEmailMapping();
        Test.stopTest();
    }
}