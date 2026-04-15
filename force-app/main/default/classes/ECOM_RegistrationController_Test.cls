/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    - ECOM-2302
*
* 2. Description - Test class for ECOM_RegistrationController
*
*
* 3. Objects referenced
*    -
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - None
*
* 6. Test Class Name:
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vasudev R 2024-04-02 : Initial creation
*    - Abhishek 2025.05.05 Added method testgetCountriesBannerMsgGuest - RWPS-3651
*************************************************************/
@isTest
public class ECOM_RegistrationController_Test {

    @isTest
    static void registerNewAccountTest() {

        Test.startTest();
        ECOM_RegistrationController.registerNewAccount(new Map<String, String>());
        Test.stopTest();
    }

    @isTest
    static void getCMSUrlsTest() {
        Test.startTest();
        ECOM_RegistrationController.getCMSUrls();
        Test.stopTest();
    }

    @isTest
    public static void testgetCountriesBannerMsgGuest(){
        ECOM_CountryBasedBannerMsg__mdt bannerMsg = [SELECT DeveloperName FROM ECOM_CountryBasedBannerMsg__mdt WHERE DeveloperName != null LIMIT 1];

         Test.startTest();
         Map<String,String> oneTrustconfigs = ECOM_RegistrationController.getCountriesBannerMsgGuest('US', new List<String>{bannerMsg.DeveloperName});
         Test.stopTest();
    }

}