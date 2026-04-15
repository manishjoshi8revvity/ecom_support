/**************************************************************

	* 1. Jira Ticket(s) that relates to this class
	*  
	*
	* 2. Description - This is a test class
	*
	* 3. Objects referenced
	*    - User
	*	 

	* 4. Callouts to additional Components (including their methods) or None:
	*    - None
	*
	* 5. Dependant Class(es):
	*    - ECOM_TestUtil
	 
	* 6. Test Class Name:
	*    
	*
	* 7. Is @Invocable : No
	*
	* 8. Author Name(s):
	*    - Sukumar 2023.09.18
	*************************************************************/
@isTest(SeeAllData=false)
public class ECOM_UserRegistrationAddressWrapper_Test {
    @isTest
    public static void testECOM_UserRegistrationAddressWrapper() {
        // Create test data
        Account testAccount = ECOM_TestUtil.createAccount();
        
        ECOM_UserRegistrationAddressWrapper wrapper = new ECOM_UserRegistrationAddressWrapper();
        wrapper.country = testAccount.ShippingCountry;
        wrapper.state = testAccount.ShippingState;
        wrapper.city = testAccount.ShippingCity;
        wrapper.street = testAccount.ShippingStreet;
        wrapper.zipcode = testAccount.ShippingPostalCode;
        
        System.assertEquals(testAccount.ShippingCountry, wrapper.country);
        System.assertEquals(testAccount.ShippingState, wrapper.state);
        System.assertEquals(testAccount.ShippingCity, wrapper.city);
        System.assertEquals(testAccount.ShippingStreet, wrapper.street);
        System.assertEquals(testAccount.ShippingPostalCode, wrapper.zipcode);
    }
}