@isTest
public class ECOM_EncryptRequestFlowController_Test {
    
    @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
    }
    
    
    
    @isTest
    static void testGetEncryptedRequestParameter() {
        
        ECOM_EncryptRequest testEncryptRequest = new ECOM_EncryptRequest();
        List<ECOM_EncryptRequest> testEncryptRequestList = new List<ECOM_EncryptRequest>{testEncryptRequest};
            
            // Call the method under test
        Test.startTest();
        List<String> result = ECOM_EncryptRequestFlowController.getEncryptedRequestParameter(testEncryptRequestList);
        Test.stopTest();
        
        // Assert the results
        System.assertEquals(1, result.size(), 'Expected a single encrypted string in the list');
        String encryptedString = result[0];
        
        
        System.assertNotEquals('', encryptedString, 'Encrypted string should not be empty');
        
        
    }
}