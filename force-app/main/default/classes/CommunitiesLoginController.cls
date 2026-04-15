/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*
* 2. Description - An apex page controller that exposes the site login functionality
*
* 3. Objects referenced
*    - 
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
*
* 5. Dependant Class(es):
*    - ECOM_CustomMetadataService
*
* 6. Test Class Name: CommunitiesLoginControllerTest
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - RafterOne
*    - Manish Joshi 2025.05.28 Added attribute ptcms=true to login page URL RWPS-3323
*************************************************************/

global with sharing class CommunitiesLoginController {

    global CommunitiesLoginController () {}
    
    // Code we will invoke on page load.
    global PageReference forwardToAuthPage() {
        Boolean isSandbox = ECOM_CustomMetadataService.getOrgType();
        System.debug('isSandbox:: '+isSandbox);
        String startUrl = System.currentPageReference().getParameters().get('startURL');
         System.debug('startUrl '+startUrl);

        String displayType = System.currentPageReference().getParameters().get('display');
        // RWPS-3323 - START
        PageReference returnRef =  Network.forwardToAuthPage(startUrl, displayType);
        if(Test.isRunningTest())
        {
            returnRef = new PageReference('https://www.secure.stage.revvity.com/login');
        }
        if((isSandbox || Test.isRunningTest()) && returnRef!=null) 
        {
            String url = returnRef.getUrl();
            if(!url.contains('ptcms=true'))
                {
                    url = url.replaceAll('login?','login?ptcms=true');
                    returnRef = new PageReference(url);
                }
        }
        if (isSandbox && returnRef.getUrl().contains('www.revvity.com')) {
    throw new AuraHandledException(
        'Sandbox login incorrectly resolved to PROD'
    );
    }
        return returnRef;//RWPS-3323 - ENDS
    }
}