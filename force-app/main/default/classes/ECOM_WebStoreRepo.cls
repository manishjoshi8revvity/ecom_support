/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-RWPS-592 - Omni Us & Ca accounts should be able to download document PDF 
*
* 2. Description - This class is used to retrieve webstore data.
*
*
*
* 3. Objects referenced
*    -WebStore
*    - Network
*    - Site
*    - SiteDetail
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
*
* 5. Dependant Class(es):
*    - ECOM_CartUtil
*	
* 6. Test Class Name: 
*    - ECOM_WebStoreRepo_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vipul 2023.07.19
*    @last modified by  :
*    - manish.joshi@revvity.com | 2024-05-07 added methods getNetworks,getSites,getSiteDetails for ticket RWPS-592

*************************************************************/
public class ECOM_WebStoreRepo {
    
    /**
    * @description  This retrun webstore
    * @author Vipul 2023.07.19
    * @param webStoreName 
    * @return List<WebStore> 
    **/
    public static List<WebStore> getWebStoreByName(String webStoreName)
    {
        List<WebStore> webStores=[SELECT Id, Name, Type FROM WebStore where name=:webStoreName LIMIT 1];
        return webStores;
    }
    
    /**
    * @description  This retrun list of available network on the basis of network name
    * @author manish.joshi@revvity.com 2024.05.07
    * @param networkName 
    * @return List<Network> 
    **/
    public static List<Network> getNetworks(String networkName)
    {
        List<Network> networks=[SELECT id, UrlPathPrefix FROM Network WHERE Name = :networkName];
        return networks;
    }
    
    /**
    * @description  This retrun list of available Site
    * @author manish.joshi@revvity.com 2024.05.07
    * @param urlPathPrefix 
    * @return List<Site> 
    **/
    public static List<Site> getSites(String urlPathPrefix)
    {
        List<Site> sites= [SELECT Id FROM Site WHERE UrlPathPrefix = :urlPathPrefix];
        return sites;
    }
	
     /**
    * @description  This retrun list of available SiteDetail
    * @author manish.joshi@revvity.com 2024.05.07
    * @param durableId 
    * @return List<SiteDetail> 
    **/
    public static List<SiteDetail> getSiteDetails(String durableId)
    {
        List<SiteDetail> siteDetails= [SELECT Id,SecureUrl FROM SiteDetail WHERE DurableId = :durableId];
        return siteDetails;
    }
    

}