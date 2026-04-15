/**************************************************************
*
* 1. Jira Ticket(s) that relates to this class
*    ECOM-2302
*
* 2. Description - This is a test class for ECOM_PasswordResetEmailController
*
*
*
* 3. Objects referenced
*    -None
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
*
* 5. Dependant Class(es):
*    - None
*	
* 6. Test Class Name:         
*    - 
*
* 7. Is @Invocable (Yes or No): Yes
*
* 8. Author Name(s):
*    - vramachandran@rafter.one | 09 May 2024
*    - Kushal 2026.01.14 Updated the copyright year to be dynamic - RWPS-5616
*************************************************************/
@isTest
public class ECOM_PasswordResetEmailController_Test {
    
    @testSetup
    static void testSetup() {
        ECOM_TestUtil.testDataIntialSetup();
        
    }

    @isTest
    static void getUserRecordTest() {
        ECOM_PasswordResetEmailController controller = new ECOM_PasswordResetEmailController();
        List<User> userRecords = [SELECT Id, Name, Email FROM User ORDER BY CreatedDate DESC LIMIT 1];
        User userRecord; 
        
        if(null != userRecords && !userRecords.isEmpty()) {
            userRecord = userRecords[0];
        }
        
        
        controller.contactIdFromEmail = userRecord.Id;
        
        Test.startTest();
        controller.getUserRecord();
        Test.stopTest();
    }

    @isTest
    static void copyright2016Text_ReturnsCurrentYearInLabelFormat() {
        ECOM_PasswordResetEmailController controller = new ECOM_PasswordResetEmailController();
        String actual = controller.copyright2016Text;
        Integer currentYear = Date.today().year();
        String expected = String.format(Label.ECOM_ET_Copyright_2016, new Object[] { currentYear });
        System.assertEquals(expected, actual, 'copyright2016Text should reflect the current year formatted per the label');
    }
}