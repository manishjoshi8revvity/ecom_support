@isTest
public class ECOM_FrequentlyPurchasedUtil_Test {
    
    @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
    }
    
    /*@isTest
    static void testGetPartNumberProductMap(){
        Order testOrder = [SELECT Id,ECOM_SAP_Order_Number__c,Status  FROM Order ORDER BY CreatedDate DESC LIMIT 1];
        OrderItem orderItem = [Select Id From OrderItem ORDER BY CreatedDate DESC LIMIT 1];
        
        SAP_Order_Summary__c ordersummary = new SAP_Order_Summary__c();
        ordersummary.Order_Number__c= 2243;
        ordersummary.typeOrder__c = 'SP';
        insert ordersummary;
        
        List<SAP_Order_Summary__c> ordersummarylist = new List<SAP_Order_Summary__c>();
        ordersummarylist.add(ordersummary);
        
        SAP_Order_Items__c sapordItems = new SAP_Order_Items__c();
        sapordItems.Line_Item_Number_Web__c = '1';
        sapordItems.PKI_Order_Summary__c = ordersummary.Id;
        sapordItems.isRemoved__c = false;
        //sapordItems.Quantity_Shipped__c = 10.00;
        sapordItems.Quantity_Ordered__c = 10.00;
        insert sapordItems;
        
        List<SAP_Order_Items__c> orderitemslist = new List<SAP_Order_Items__c>();
        orderitemslist.add(sapordItems);
        
        Test.startTest();
        Map<String, Product2> result = ECOM_FrequentlyPurchasedUtil.getPartNumberProductMap(ordersummarylist);
        Test.stopTest();
        System.assertnotEquals(null,result,'expected order should not be null');
    }*/
    
    
    
    @isTest
    static void testGetMappedList() {
        Product2 prd = [SELECT Id,Name,ProductClass,Part_Number__c,Business_Unit__c,DisplayUrl,CurrencyIsoCode,Product_Line__c,ECOM_Product_Media_URI__c FROM Product2 ORDER BY CREATEDDATE DESC LIMIT 1];
        List<Product2> productsList = new List<Product2>();
        productsList.add(prd);
        
        Map<String, Integer> productOrderCountMap = new Map<String, Integer>();
        Map<String,String> productImageMap = new Map<String,String>();
        
        Test.startTest();
        
        // Call the method to be tested
        List<ECOM_FrequentlyPurchasedWrapper.Product> result = ECOM_FrequentlyPurchasedUtil.getMappedList(productsList, productOrderCountMap,productImageMap);
        
        Test.stopTest();
        
        // Add assertions based on your expected outcomes
        System.assertEquals(productsList.size(), result.size());
        
        // Example: Check if the properties are populated correctly for the first product
        ECOM_FrequentlyPurchasedWrapper.Product firstProduct = result[0];
        System.assertEquals(productsList[0].Id, firstProduct.productId);
        System.assertEquals(productsList[0].Name, firstProduct.productName);
        
    }
    
    
    
    @isTest
    static void testGetWishlistItemsForUserId() {
        Account ac = [SELECT Id FROM Account WHERE Name = 'TestClass Account'];
        User testUser = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        
        Wishlist testWishlist = [ SELECT Id, AccountId, Account.Name, WishlistProductCount, WebStoreId, Name, OwnerId, ECOM_Default__c FROM Wishlist ORDER BY CreatedDate DESC LIMIT 1];
        testWishlist.OwnerId = testUser.Id;
        testWishlist.AccountId = ac.Id;
        update testWishlist;
        
        List<Wishlist> wishlistlist = new List<Wishlist>();
        wishlistlist.add(testWishlist);
        
        
        WishListItem testWishItem = [SELECT Id FROM WishListItem ORDER BY CreatedDate DESC LIMIT 1];
        
        List<WishListItem> testWishlistItem = new List<WishListItem>();
        testWishlistItem.add(testWishItem);
        System.runAs(testUser){
        Test.startTest();
        // Call the method to be tested
        	List<WishlistItem> result = ECOM_FrequentlyPurchasedUtil.getWishlistItemsForUserId();
        }
        Test.stopTest();        
    }
    
    
    
    
    /*@isTest
    static void testGetSapOrderSummaryModel() {
        // Set up test data
        User testUser = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        
        // Create a test account for order
        Account testAccount =  [SELECT Id FROM Account WHERE Name = 'TestClass Account'];
        
        // Create a test product
        Product2 testProduct = [SELECT Id,Name,ProductClass,Part_Number__c,Business_Unit__c,DisplayUrl,CurrencyIsoCode,Product_Line__c FROM Product2 ORDER BY CREATEDDATE DESC LIMIT 1];
        
        SAP_Order_Summary__c testOrderSummary = new SAP_Order_Summary__c();
        testOrderSummary.Account_Ship_To__c = testAccount.Id;
        testOrderSummary.Order_Number__c= 2243;
        testOrderSummary.typeOrder__c = 'SP';
       //testOrderSummary.o = 
        insert testOrderSummary;
        
        
        SAP_Order_Items__c testOrderItem = new SAP_Order_Items__c();
        testOrderItem.Material_Number__c = testProduct.Part_Number__c;
        testOrderItem.Line_Item_Number_Web__c = '1';
        testOrderItem.PKI_Order_Summary__c = testOrderSummary.Id;
        
        testOrderItem.isRemoved__c = false;
        //sapordItems.Quantity_Shipped__c = 10.00;
        testOrderItem.Quantity_Ordered__c = 10.00;
        insert testOrderItem;
        
        List<SAP_Order_Summary__c> testOrderSummaryList = [SELECT Id,Order_Number__c,OwnerId,Customer_PO_Number__c,fxStatusB2B__c,
                                                           Order_Level_Tax__c,Handling_Charges__c,
                                                           Account_Ship_To__c,Account_Ship_To__r.Name,
                                                          Account_Ship_To__r.SAP_Customer_Number_Formatted__c,Bill_To_Address_Street__c,
                                                          Bill_To_Address_City__c,Bill_To_Address_Region__c,Ship_To_Address_Postal_Code__c,
                                                          Bill_To_Address_Postal_Code__c,
                                                          Bill_To_Address_Country__c,Ship_To_Address_Street__c,
                                                          Ship_To_Address_City__c,Ship_To_Address_Region__c,
                                                          Ship_To_Address_Country__c,Actual_Order_Date__c,Quote_Number__c,
                                                          Order_Total_Price__c,Order_Net_Currency__c,Special_Handling_Instructions__c,
                                                          Ship_To_Attention__c,(SELECT Id,Expected_Ship_Date__c,Scheduled_Delivery_Date__c,
                                                          PKI_Order_Summary__c,Material_Number__c,Material_Description__c,
                                                          Quantity_Ordered__c,Customer_Specific_Price__c,Net_Price__c,Extended_Price__c,
                                                          Adjusted_Unit_Price__c FROM SAP_Order_Items__r) FROM SAP_Order_Summary__c];
        
        Test.startTest();
        
        // Call the method to be tested
        Map<String, Product2> partNumberProductMap = new Map<String, Product2>{testProduct.Part_Number__c => testProduct};
            List<ECOM_OrderModel> result = ECOM_FrequentlyPurchasedUtil.getSapOrderSummaryModel(testOrderSummaryList, partNumberProductMap);
        
        Test.stopTest();
        
        // Add assertions based on your expected outcomes
        System.assertNotEquals(null, result,'Expected result'); 
        
    }*/
    
    
    
    @isTest
    static void testGetFrequentlyPurchasedProductInfo() {
       
        User testUser =[Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        
        Account testAccount =  [SELECT Id FROM Account WHERE Name = 'TestClass Account'];
        String accountId = 'testAccount.Id';
        
        Product2 testProduct = [SELECT Id,Name,ProductClass,Part_Number__c,Business_Unit__c,DisplayUrl,CurrencyIsoCode,Product_Line__c FROM Product2 ORDER BY CREATEDDATE DESC LIMIT 1];
        testProduct.Part_Number__c = '12234';
        update testProduct;
        
        // Create a test SAP Order Summary
        SAP_Order_Summary__c testOrderSummary = new SAP_Order_Summary__c();
        testOrderSummary.Account_Ship_To__c = testAccount.Id;
        testOrderSummary.Order_Number__c= 2243;
        testOrderSummary.typeOrder__c = 'SP';
        insert testOrderSummary;
        
        SAP_Order_Items__c testOrderItem = new SAP_Order_Items__c();
        testOrderItem.Material_Number__c = '12234';
        testOrderItem.Line_Item_Number_Web__c = '1';
        testOrderItem.PKI_Order_Summary__c = testOrderSummary.Id;
        testOrderItem.isRemoved__c = false;
        //sapordItems.Quantity_Shipped__c = 10.00;
        testOrderItem.Quantity_Ordered__c = 10.00;
        insert testOrderItem;
        
        List<SAP_Order_Summary__c> orderSummaryList = [SELECT Id,(SELECT Material_Number__c from SAP_Order_Items__r) FROM SAP_Order_Summary__c];
        Test.startTest();
        
        // Call the method to be tested
        ECOM_FrequentlyPurchasedWrapper result = ECOM_FrequentlyPurchasedUtil.getFrequentlyPurchasedProductInfo(orderSummaryList,accountId);
        
        Test.stopTest();
        System.assertNotEquals(null, result,'expected result'); 
        
        
        
    }
    
    /*
     @isTest
    static void testGetProductImageMap() {
        // Test data
        Account testAccount =  [SELECT Id FROM Account WHERE Name = 'TestClass Account'];
       WebStore webstore = [SELECT Id FROM WebStore LIMIT 1];
        
        String webStoreId = 'webstore.Id';
        String accountId = 'testAccount.Id';
        Product2 prd = [SELECT Id,Name,ProductClass,Part_Number__c,Business_Unit__c,DisplayUrl,CurrencyIsoCode,Product_Line__c FROM Product2 ORDER BY CREATEDDATE DESC LIMIT 1];

        List<String> productIds = new List<String>{'productId1', 'productId2'};
        Boolean excludeMedia = false;

        // Mocking the ECOM_ProductService.getProducts method
        //Test.setMock(ConnectApiMock.class, new ECOM_ProductServiceMock());

        // Call the method to test
        Map<String, String> result = ECOM_FrequentlyPurchasedUtil.getProductImageMap(webStoreId, accountId, productIds, excludeMedia);

        // Assert the results
        System.assertEquals(2, result.size()); // Adjust based on your test data
        System.assertEquals('imageUrl1', result.get('productId1')); // Adjust based on your test data
        System.assertEquals('imageUrl2', result.get('productId2')); // Adjust based on your test data
    }*/
    
}