/**************************************************************

* 1. Jira Ticket(s) that relates to this class
*  
*
* 2. Description - This is a test class.
*
* 3. Objects referenced
*    - WebCart
*	 - Network
*	 - Account
*    - Product
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_TestUtil
*    - classes called from test class
*	 - used in ecom_favorites lwc
*
* 6. Test Class Name:
*    
*
* 7. Is @Invocable : No
*
* 8. Author Name(s):
*    - Sukumar 2023.09.19
*    - Poonam 2024.02.10 Updated testGetWishlistSummaries - RWPS- 2390
*    - Poonam 2024.03.10 Updated testGetWishlistSummaries for punchout user and added testGetWishlistSummariesFav for favorites Page to increase test coverage
*    - Prabhat 2025.10.09 - Updated method testRemoveWishlistItem to increase code coverage -RWPS-3740 
*************************************************************/
@isTest(SeeAllData=false)
public with sharing class ECOM_FavoritesController_Test {
    
    //Creating Test Data
     @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
    }
    
    //Test for getWishlistSummaries Method
    @isTest
    static void testGetWishlistSummaries() {
        
        Network comm = [SELECT id, name FROM Network ORDER BY CREATEDDATE DESC limit 1]; 
        Account ac = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
        Webcart cart = [SELECT Id FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
		List<String> pfields = new List<String>();
        pfields.add('Name');
        //Calling the getWishlistSummaries method
        User usr = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        usr.ECOM_Is_Punchout_User__c=true;//RWPS-2740
        update usr;//RWPS-2740
        Map<String,Object> result;
        System.runAs(usr)
        {
        Test.startTest();
            try{       
               result = ECOM_FavoritesController.getWishlistSummaries(comm.Id, ac.Id, pfields, 'Product2');  
            }
            catch(Exception e){
                
            }
        Test.stopTest();
        }

    }
      /**
    * @description Test case favorites Page.
    * @author Poonam Shukla
    * @date 03-10-2025
    */
     @isTest
    static void testGetWishlistSummariesFav() {
         User usr = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        usr.ECOM_Is_Punchout_User__c=true;
        update usr;
        Network comm = [SELECT id, name FROM Network ORDER BY CREATEDDATE DESC limit 1]; 
        Account ac = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
        Webcart cart = [SELECT Id FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
        List<String> pfields = new List<String>();
        pfields.add('fName');
        Map<String,Object> result;
        System.runAs(usr){
        WebStore webStr = ECOM_TestUtil.prepareWebStore('Revvity-eCom');
        insert webStr;
        Wishlist wishlist = ECOM_TestUtil.createWishlist(ac,usr,webStr);
        insert wishlist;
        Test.startTest();
        result = ECOM_FavoritesController.getWishlistSummaries(comm.Id, ac.Id, pfields, 'Product2');  
        Test.stopTest();
        }
	}
    
    @isTest
    static void testGetWishlistSummariesCase2() {
        
        Network comm = [SELECT id, name FROM Network ORDER BY CREATEDDATE DESC limit 1]; 
        Account ac = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
        Webcart cart = [SELECT Id FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
		List<String> pfields = new List<String>();
        pfields.add('Name');
        //Calling the getWishlistSummaries method
        User usr = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        Map<String,Object> result;
        Test.startTest();
            try{
        result = ECOM_FavoritesController.getWishlistSummaries(comm.Id, ac.Id, pfields, 'Product2');  
            }
            catch(Exception e){
                
            }
        Test.stopTest();
    }
    
    @isTest
    static void getCMSBaseUrlTest(){
        Test.startTest();
        Map<String,String> response = ECOM_FavoritesController.getCMSBaseUrl('test1234');
        Test.stopTest();
        system.assertEquals(0,response.size(),'returned map is not null');
    }
    //Test method for getFieldsByObjectName Method
    @isTest
    static void testGetFieldsByObjectName() {
        String objectName = 'WishListItem';        
        
        // Calling  the getFieldsByObjectName method
        User usr = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(usr)
	{
        Test.startTest();
        Map<String, String> fieldsMap = ECOM_FavoritesController.getFieldsByObjectName(objectName);
        Test.stopTest();
       
        // Assert the results
        System.assertEquals('Name', fieldsMap.get('Name'));
    }
        
    }
    
    //Test Method for addItemsToCart
    @isTest
    static void testAddItemsToCart() {
        String effectiveAccountId = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        String communityId =[SELECT Id, name FROM Network ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        //No quantity field is available on quantity
        Product2 prd = [Select Id,Name from Product2 ORDER BY CREATEDDATE DESC LIMIT 1];
       String qty = 'test qty';
        ConnectApi.CartItem result = new  ConnectApi.CartItem();
        
        //Calling the addItemsToCart Method
        User usr = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(usr)
	{
        Test.startTest();
        Map<String,Object> resultMap = ECOM_FavoritesController.addItemsToCart(communityId,effectiveAccountId, prd.Id, qty);
        Test.stopTest();

        //Validating the result
        System.assertNotEquals('1000', resultMap.get('listprice'),'Expected was 1000 usd');
    }
    }
    //Test for CartInputWrapper class
     @isTest
     static void testWrapper() {
        User usr = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(usr)
		{
        Test.startTest();
        ECOM_FavoritesController.CartInputWrapper instance = new ECOM_FavoritesController.CartInputWrapper();
        instance.productId='1234abcd';
        instance.quantity='12';
        Test.stopTest();
        }

        
    }
    //Test for removeWishlistItem method
    @isTest
    static void testRemoveWishlistItem() {
        Network comm = [SELECT id, name FROM Network ORDER BY CREATEDDATE DESC limit 1]; 
        Account ac = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
        WebStore testStore=[SELECT Id FROM WebStore WHERE Name=:ECOM_TestUtil.STORE_NAME LIMIT 1];//RWPS-3740
        User testUser=[SELECT Id,AccountId FROM User WHERE AccountId=:ac.Id limit 1];//RWPS-3740
        WishList testWishList= ECOM_TestUtil.createWishlist(ac.Id,testStore.Id,testUser.Id);
        Product2 prod=[SELECT Id,Name FROM Product2 LIMIT 1];
        WishListItem testItems=ECOM_TestUtil.createWishlistItem(prod.Id,testWishList.Id);
        
        //Calling the removeWishlistItem method
        User usr = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(usr)
		{
        Test.startTest();
        Map<String,Object> resultMap = ECOM_FavoritesController.removeWishlistItem(testItems.Id);
        Test.stopTest();
        
        //Validating results
        System.assertEquals('Success',resultMap.get('Status'),'Expected is Success');
        } 
    }
        
        @isTest
    	static void testRemoveWishlistItemExceptionCase() {        
            User usr = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
            System.runAs(usr)
            {
            Test.startTest();
            Map<String,Object> resultMap = ECOM_FavoritesController.removeWishlistItem('');
            Test.stopTest();
            
            //Validating results
            } 
    	}
}