@isTest
public with sharing class ECOM_DataLayerController_Test {
    
    @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
    }
    /*@isTest
    static void testGetProductBasedOnId() {
         User testUser=[SELECT Id,Name,Email FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        String productId = '';
        
        System.runAs(testUser){
             Test.startTest();
        ECOM_DataLayerModel result = ECOM_DataLayerController.getProductBasedOnId(productId);
             Test.stopTest();
         
        System.assertEquals(null, result, 'Expected result to be null');
        }
        
    }*/
      /* @isTest
    static void testGetProductsBasedOnPartNumber() {
         User testUser=[SELECT Id,Name,Email FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        // Create a sample dataLayerArray
        ECOM_DataLayerModel.ECOM_DataLayerArray[] dataLayerArray = new List<ECOM_DataLayerModel.ECOM_DataLayerArray>{
        };

          System.runAs(testUser){
            Test.startTest();
           List<ECOM_DataLayerModel> result = ECOM_DataLayerController.getProductsBasedOnPartNumber(dataLayerArray);
            Test.stopTest();
               System.assertEquals(null, result, 'Expected result to be null');
        }

    }*/
    /*@isTest
    static void testGetProductsBasedOnId() {
         User testUser=[SELECT Id,Name,Email FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        // Create a sample dataLayerArray
        ECOM_DataLayerModel.ECOM_DataLayerArray[] dataLayerArray = new List<ECOM_DataLayerModel.ECOM_DataLayerArray>{
        };

        // Call the getProductsBasedOnId method
         System.runAs(testUser){
            Test.startTest();
           List<ECOM_DataLayerModel> result = ECOM_DataLayerController.getProductsBasedOnId(dataLayerArray);
            Test.stopTest();
      
             System.assertEquals(null, result, 'Expected result to be null');
         }
    }*/
    @isTest
    static void testgetDataLayerDataByCarts(){
        Webcart cart = [SELECT Id FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
        User testUser=[SELECT Id,Name,Email FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(testUser){
            Test.startTest();
            Map<String,Object> resultMap = ECOM_DataLayerController.getDataLayerDataByCart(cart.Id);
            Test.stopTest();
        }
    }
    
    @isTest
    static void getDataLayerDataByOrderTest(){
        User testUser=[SELECT Id,Name,Email FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        Order ord = [SELECT Id FROM Order LIMIT 1];
        System.runAs(testUser){
            Map<String,Object> response;
            Test.startTest();
            response = ECOM_DataLayerController.getDataLayerDataByOrder(ord.Id);
            Test.stopTest();
        }
    }
}