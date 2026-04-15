@isTest
public class Ecom_CsrControllerTest {
    
    @testSetup
    public static void setup(){
    	Map<String,Object> response = ECOM_TestUtil.initialStorefrontSetup();
    }
    
    @isTest
    public static void test(){
        User u = [SELECT Id FROM User ORDER BY CreatedDate DESC LIMIT 1];
        Community c = [SELECT Id FROM Community ORDER BY CreatedDate DESC LIMIT 1];
		test.startTest(); 
        Ecom_CsrController.csrLogin();
        Ecom_CsrController.getCSRUrl(UserInfo.getUserId());
		test.stopTest();
    }
}