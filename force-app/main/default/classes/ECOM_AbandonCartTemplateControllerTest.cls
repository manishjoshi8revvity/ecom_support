/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM- 91     
*
* 2. Description - This class is used to test : Abandoned Cart Email Template 
*
*
* 3. Objects referenced
*    - WebCart
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_AbandonCartTemplateController
*
* 6. Test Class Name: 
*    - NA
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vipul Goyal 2024.04.29 Abandoned Cart Email Template Test.
*************************************************************/
@isTest
public class ECOM_AbandonCartTemplateControllerTest {
    
    @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
    }
    
    @IsTest
    public static void testAbandonCart()
    {
         List<WebCart> carts = [SELECT Id FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
        Test.startTest();
        ECOM_AbandonCartTemplateController atc = new ECOM_AbandonCartTemplateController();
        atc.setCartRecordId(carts[0].Id);
        Test.stopTest();
    }

}