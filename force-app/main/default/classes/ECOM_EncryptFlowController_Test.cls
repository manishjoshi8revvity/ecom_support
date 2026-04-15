/**************************************************************

	* 1. Jira Ticket(s) that relates to this class
	*  
	*
	* 2. Description - This class is a test class
	*
	* 3. Objects referenced
	* 4. Callouts to additional Components (including their methods) or None:
	*    - None
	*
	* 5. Dependant Class(es):
	*    - ECOM_LoginWrapper
	
	 
	* 6. Test Class Name:
	*
	* 7. Is @Invocable : No
	*
	* 8. Author Name(s):
	*    - Mayank 2023.09.15
*************************************************************/
@isTest(seeAllData=false)
public class ECOM_EncryptFlowController_Test {

    @isTest
    static void testDataEncryption() {
        List<ECOM_LoginWrapper.EncryptionRequest> requestList = new List<ECOM_LoginWrapper.EncryptionRequest>();
        ECOM_LoginWrapper.EncryptionRequest request = new ECOM_LoginWrapper.EncryptionRequest();
        // Add the request object to the list
        requestList.add(request);

        // Call the dataEncryption method
        Test.startTest();
        User usr = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(usr)
        {
        List<ECOM_LoginWrapper.EncryptionResponse> responseList = ECOM_EncryptFlowController.dataEncryption(requestList);
        List<ECOM_LoginWrapper.EncryptionResponse> nullResponseList = ECOM_EncryptFlowController.dataEncryption(null);
            
        ECOM_LoginWrapper.EncryptionRequest requestBody = new ECOM_LoginWrapper.EncryptionRequest();
        requestBody.username = 'test@test.com';
        requestBody.password = 'password';
        ECOM_LoginWrapper.EncryptionResponse res = ECOM_EncryptUtil.encryptDataWithManagedIV(requestBody);
        
		Test.stopTest();
        // Perform assertions on the responseList to ensure it contains the expected data
        System.assertEquals(1, responseList.size(),'Assertion Failed');
        }
    }
    
    @isTest
    static void testDataEncryptiontest() {
        Test.startTest();
        ECOM_LoginWrapper.EncryptionRequest requestBody = new ECOM_LoginWrapper.EncryptionRequest();
        requestBody.username = 'test@test.com';
        requestBody.password = 'password';
        ECOM_LoginWrapper.EncryptionResponse res = ECOM_EncryptUtil.encryptData(requestBody);
        String excryptcode = ECOM_EncryptUtil.encryptWithAES256('test@test.com');
		Test.stopTest();
        
    }
    @isTest
    static void testDataDecryptiontest() {
        ECOM_LoginWrapper.EncryptionRequest requestBody = new ECOM_LoginWrapper.EncryptionRequest();
        requestBody.username = 'test@test.com';
        requestBody.password = 'password';
        ECOM_LoginWrapper.EncryptionResponse res = ECOM_EncryptUtil.encryptDataWithManagedIV(requestBody);
        Map<String, Blob> encryptmap = ECOM_EncryptUtil.encryptWithManagedIV('sometext') ;
        Test.startTest();
        //String decryptedcodeiv = ECOM_EncryptUtil.decryptWithManagedIV(res.encryptedToken, res.encryptedCode);
        //String decryptedcodeiv = ECOM_EncryptUtil.decryptWithManagedIV(String.valueOf(encryptmap.get(ECOM_Constant.ENCRYPTED_TOKEN)), 
                                                                       //String.valueOf(encryptmap.get(ECOM_Constant.ENCRYPTED_CODE)));
        
        String excryptcode = ECOM_EncryptUtil.encryptWithAES256('test@test.com');
        String decrytedcode = ECOM_EncryptUtil.decryptWithAES256(excryptcode);
        Test.stopTest();
    }
}