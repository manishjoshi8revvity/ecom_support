/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*
* 2. Description - This class is a test class
*
*
* 3. Objects referenced
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
*
* 5. Dependant Class(es):
*
*
*
* 6. Test Class Name:
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*  - Abhishek Joshi 2025.07.15 - Created the test class - RWPS-4437


*************************************************************/

@isTest(SeeAllData=false)
public without sharing class ECOM_ProductRecommendationsRepo_Test {
    /**
    * @description //To setup test Data
    * @author Abhishek Joshi | 2025.10.06
    **/
    @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
    }

    /**
    * @description //To test product recommendation retrieval
    * @author Abhishek Joshi | 2025.10.06
    **/
    @isTest
    static void testGetCustomersAlsoBought() {
        ECOM_ProductRecommendationsCtrler_Test.testGetCustomersAlsoBought();
    }
}