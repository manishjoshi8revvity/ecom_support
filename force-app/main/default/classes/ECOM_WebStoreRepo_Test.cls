/**************************************************************

* 1. Jira Ticket(s) that relates to this class
*  *    ECOM-RWPS-592 - Omni Us & Ca accounts should be able to download document PDF
* 2. Description - This class is a test class.
*
* 3. Objects referenced
*    - WebStore
*    - Network
*    - Site
*    - SiteDetail
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_TestUtil
*    - ECOM_WebStoreRepo
*
* 6. Test Class Name:
*    -None
*
* 7. Is @Invocable : No
*
* 8. Author Name(s):
*    - Manoj 2023.09.19
*    @last modified by  :
*    - manish.joshi@revvity.com | 2024-05-07 added testGetNetworks,testGetSites,testGetSiteDetails for tickedt RWPS-592
*************************************************************/

@isTest(SeeAllData=false)
private with sharing class ECOM_WebStoreRepo_Test {
    
    //Creating test data
    @TestSetup
    static void setupTestData() {
        WebStore testWebStore = new WebStore();
            testWebStore = ECOM_TestUtil.prepareWebStore('revStore');
            insert testWebStore;
        
    }
    //Test for getWebStoreByName method
    @isTest
    static void testprepareWebStore() {
        
        WebStore testWebStore= [SELECT Id, Name FROM WebStore ORDER BY CreatedDate DESC];
        //Calling the getWebStoreByName method
        Test.startTest();
        List<WebStore> store = ECOM_WebStoreRepo.getWebStoreByName(testWebStore.Name);
        Test.stopTest();
        
        //Validating the result
        System.assertEquals(testWebStore.Name,store[0].Name,'Expected value was testWebStore');
        
    }
    
    /**
    * @description test method for ECOM_WebStoreRepo getNetworks method
    * @author manish.joshi@revvity.com | 2024-05-07 
    * @return void 
    **/
    @isTest
    static void testGetNetworks(){
        User u = [SELECT Id FROM USER ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
            Test.startTest();
            List<Network> res = ECOM_WebStoreRepo.getNetworks(Label.ECOM_WebStore_Name);
            Test.stopTest();
            System.AssertNotEquals(null,res,'Wrong Output');
            
        }
    }
    
    /**
    * @description test method for ECOM_WebStoreRepo getSites method
    * @author manish.joshi@revvity.com | 2024-05-07 
    * @return void 
    **/
    @isTest
    static void testGetSites(){
        User u = [SELECT Id FROM USER ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
            List<Network> networks = ECOM_WebStoreRepo.getNetworks(Label.ECOM_WebStore_Name);
            Test.startTest();
            List<Site> res = ECOM_WebStoreRepo.getSites(networks.get(0).UrlPathPrefix);
            Test.stopTest();
            System.AssertNotEquals(null,res,'Wrong Output');
            
        }
    }
    
    /**
    * @description test method for ECOM_WebStoreRepo getSiteDetails method
    * @author manish.joshi@revvity.com | 2024-05-07 
    * @return void 
    **/
    @isTest
    static void testGetSiteDetails(){
        User u = [SELECT Id FROM USER ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
            List<Network> networks = ECOM_WebStoreRepo.getNetworks(Label.ECOM_WebStore_Name);
            List<Site> sites = ECOM_WebStoreRepo.getSites(networks.get(0).UrlPathPrefix);
            Test.startTest();
            List<SiteDetail> res = ECOM_WebStoreRepo.getSiteDetails(sites.get(0).Id);
            Test.stopTest();
            System.AssertNotEquals(null,res,'Wrong Output');
            
        }
    }
}