/**************************************************************
 * 1. JIRA Ticket:RWPS-2271
 * 2. This class is Test class for ECOM_GuestUserController class.
 * 
 * 4. Callouts to additional Components (including their methods) or None:
 * 
 * 
 * 
 * 5. Dependant Class(es):
 * 
 * 
 * 6. Test Class Name: 
 * 
 * 
 * 7. Is @Invocable (Yes or No): No
 * 
 * 
 * 8. Author Name(s):
 * -Prabhat Kumar - 01.16.2025
 * 
*************************************************************/
@isTest
public with sharing class ECOM_GuestUserControllerTest {

    /**
    * @description - Test method to test non-guest user.
    * @author prabhat.kumar4@zensar.com | 01.16.2025
    * @param null
    * @return Boolean
    **/
    @isTest
    static void testIsGuestUser_WithSessionId() {
        Test.startTest();
        Boolean result = ECOM_GuestUserController.isGuestUser();
        // Assert
        System.assertEquals(false, result, 'Expected non-guest user when session ID is present');  
        Test.stopTest();
    }

    /**
    * @description - Test method to test check if exceptions are thrown.
    * @author prabhat.kumar4@zensar.com | 01.16.2025
    * @param null
    * @return Boolean
    **/
    @isTest
    static void testIsGuestUserWithException() {
        Boolean result = ECOM_GuestUserController.isGuestUser();
        System.assertEquals(false, result, 'Expected false when an exception is thrown');
    }
}