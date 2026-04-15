/**************************************************************
 * 1. Jira Ticket(s) that relates to this class
 *    ECOM- 1554
 * 
 * 2. Description - Test class for ECOM_UserPasswordSetService
 * 
 * 3. Objects referenced
 *    -None
 * 
 * 4. Callouts to additional Components (including their methods) or None:
 *    - None
 * 
 * 5. Dependant Class(es):
 * 
 * 6. Test Class Name: 
 * 
 * 7. Is @Invocable (Yes or No): No
 * 
 * 8. Author Name(s):
 *    - Vasudev R | 2024 May 29
 *************************************************************/
@isTest
public class ECOM_UserPasswordSetService_Test {
    
    @testSetup
    static void testSetup() {
        ECOM_TestUtil.testDataIntialSetup();
        
    }

    @isTest
    static void getLabelForErrorMessageTest() {
        Test.startTest();
        ECOM_UserPasswordSetService.getLabelForErrorMessage('');
        Test.stopTest();
    }
    
    @isTest
    static void validateTokenTest() {
        
        User userRecord = new User(ECOM_Reset_Password_Key__c = '');
       	String tokenValue = String.valueOf(DateTime.now().addHours(-22).getTime());
        String encryptedToken = ECOM_EncryptUtil.encryptWithAES256(tokenValue);
        userRecord.ECOM_Reset_Password_Key__c = encryptedToken;
        String decryptedToken = tokenValue;//String.valueOf(DateTime.now().addHours(-22).getTime());
        Test.startTest();
        ECOM_UserPasswordSetService.validateToken(decryptedToken, userRecord, encryptedToken);
        
        userRecord.ECOM_Reset_Password_Key__c = decryptedToken;
        tokenValue = String.valueOf(DateTime.now().addHours(-26).getTime());
        encryptedToken = ECOM_EncryptUtil.encryptWithAES256(tokenValue);
        userRecord.ECOM_Reset_Password_Key__c = encryptedToken;
        decryptedToken = tokenValue;
        ECOM_UserPasswordSetService.validateToken(decryptedToken, userRecord, encryptedToken);
        Test.stopTest();
    }
    
    @isTest
    static void setNewUserPasswordTest() {
        List<User> userRecords = [SELECT Id, Name, Email FROM User ORDER BY CreatedDate DESC LIMIT 1];
        User userRecord; 
        
        if(null != userRecords && !userRecords.isEmpty()) {
            userRecord = userRecords[0];
        }
        
        Test.startTest();
		String encryptedEmail = ECOM_EncryptUtil.encryptWithAES256(userRecord.Email);
		String encryptedPassword = ECOM_EncryptUtil.encryptWithAES256(userRecord.Email + String.valueOf(DateTime.now()));
        String encryptedToken = ECOM_EncryptUtil.encryptWithAES256(String.valueOf(DateTime.now().addHours(-2).getTime()));
        ECOM_UserPasswordSetService.setNewUserPassword(encryptedEmail, encryptedPassword, encryptedToken);
        ECOM_UserPasswordSetService.setNewUserPassword('test@email.com', encryptedPassword, encryptedToken);
        Test.stopTest();
    }
}