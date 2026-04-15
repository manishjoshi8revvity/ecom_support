@IsTest
public with sharing class ECOM_OrderActivateBatchTest {
	@TestSetup
    static void setup(){
        Map<string,Object> response = ECOM_TestUtil.initialStorefrontSetup();
    }
    
    @isTest
    static void batchTest(){
        Test.startTest();
        Database.executeBatch(new ECOM_OrderActivateBatch('SELECT Id,Status FROM Order'));
        Test.stopTest();
    }
}