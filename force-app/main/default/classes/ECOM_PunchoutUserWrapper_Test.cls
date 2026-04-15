/**************************************************************
 * 1. Ticket(s) that relates to this class
 * - ECOM-1020
 * 
 * 2. Description - This is a test class for ECOM_PunchoutUserWrapper
 * 				  - Test method for StoreNavigationWrapper inner class
 *					
 *
 * 3. Objects referenced
 * - User
 *
 * 4. Callouts to additional Components (including their methods) or None:
 * - None
 *
 * 5. Dependant Class(es):
 * - ECOM_PunchoutUserWrapper
 *
 * 6. Test Class Name: ECOM_PunchoutUserWrapper_Test
 *
 * 7. Is @Invocable (Yes or No): No
 *
 * 8. Author Name(s): 
 * - Vasudev Ramachandran 2024.02.05
 *
*************************************************************/ 
@isTest
public class ECOM_PunchoutUserWrapper_Test {

    @isTest
    static void storeNavigationWrapperTest(){
        Test.startTest();
        ECOM_PunchoutUserWrapper.StoreNavigationWrapper wrapper = new ECOM_PunchoutUserWrapper.StoreNavigationWrapper();
        wrapper.viewProfileSettingPage = false;
        wrapper.viewAccountPage = false;
        wrapper.viewOrderPage = false;
        wrapper.viewRecentOrders = false;
        wrapper.viewFavourites = false;
        wrapper.viewFrequentlyPurchased = false;
        wrapper.viewQuickOrder = false;
        wrapper.viewLogout = false;
        wrapper.storeForwardUrl = 'TestUrl';
        Test.stopTest();
    }
}