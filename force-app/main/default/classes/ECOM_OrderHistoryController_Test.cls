/**************************************************************

* 1. Jira Ticket(s) that relates to this class

*  

*

* 2. Description - This class is a test class.

*

* 3. Objects referenced

*    - Account

*    - Order

*    - Network

*    - Product2

*    - CartItem

*    - WebStore

*    - Wishlist

*    - WishlistItem

*.   -User

* 4. Callouts to additional Components (including their methods) or None:

*    - None

*

* 5. Dependant Class(es):

*    - ECOM_TestUtil

*    - classes called from test class

*

* 6. Test Class Name:

*    -None

*

* 7. Is @Invocable : No

*

* 8. Author Name(s):

*    - Manoj 2023.09.19
*    - Vinay 2025.04.29 Added method testGetOrderDetailsGetERPAddress to increase the coverage - RWPS-3026
*    - Gaurav 2025.07.29 Added testgetAllPunchoutSapOrders to increase coverage - RWPS-3741
*    - Sachin Vispute 2025.10.07 : Added methods : testFetchProductUnavailabilityWithDiscontinuedProducts, testGetorderDetailsAndReplacement, testGetorderDetailsAndReplacementWithExceptionTest, testCheckIfCurrentUserIsPunchoutUserTest
*    - Sachin Vispute 2025.10.28 : Added methods : testGetOnlineOrders, testGetOfflineOrders, testGetEncodedValues - RWPS-4881
*    - Sachin Vispute 2025.11.06 : updated methods : testGetOnlineOrders, testGetOfflineOrders, testGetEncodedValues, Created : testGetOfflineOrdersPunchout, testFetchSalesOrg - RWPS-4881
*    - Sachin Vispute 2025.11.05 : Created : testGetOfflineOrdersWithSearchForPunchout - RWPS-5094
*    - Poonam Shukla 2026.03.02 : Updated method testgetAllMySapOrders, added method testgetAllMySapOrdersCase1, testGetOnlineOrdersCase1 - RWPS-5777
*************************************************************/


@isTest
public with sharing class ECOM_OrderHistoryController_Test {
    @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
    }
    @isTest
    static void getMyOrdersTest(){
        Order order = [Select Id From Order ORDER BY CREATEDDATE DESC LIMIT 1];
        User u = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        
        Test.startTest();
        List<Order> ord;
        System.runAs(u){
            ord =  ECOM_OrderHistoryController.getMyOrders();
        }
        
        Test.stopTest();
        System.debug('ord'+ord);        
        //System.assertEquals(ord.size(),1,'expected order details error');
        //System.assert(ord.size()>0,'expectedorderdetails error');
    }  
    @isTest
    static void getOrderDetailsTest(){
  		Order testOrder = [SELECT Id,ECOM_SAP_Order_Number__c,Status  FROM Order ORDER BY CreatedDate DESC LIMIT 1];
        testOrder.ECOM_SAP_Order_Number__c = '2243';
        testOrder.Status = 'Shipped';
        //testOrder.Status = 'Order Confirmed';
        update testOrder;
        List <Order> order = new List<Order>();
        order.add(testOrder);
        
        OrderItem orderItem = [Select Id From OrderItem ORDER BY CreatedDate DESC LIMIT 1];
        //orderItem.LineNumber = 1123;
        // orderItem.OrderId = testOrder.Id;
        //update orderItem;
        
        SAP_Order_Summary__c ordersummary = new SAP_Order_Summary__c();
        ordersummary.Order_Number__c= 2243;
        ordersummary.typeOrder__c = 'SP';
        //ordersummary.fxItemsToShip__c = 4.00;
        //ordersummary.Count_of_Items__c = 5.00;
        //ordersummary.Count_of_rejected_items__c = ;
        // ordersummary.fxStatusB2B__c = 'Shipped';
        // ordersummary.fxItemsToShip__c = 5.00;
        insert ordersummary;
        
        SAP_Order_Items__c sapordItems = new SAP_Order_Items__c();
        
        sapordItems.Line_Item_Number_Web__c = '1';
        sapordItems.PKI_Order_Summary__c = ordersummary.Id;
        sapordItems.isRemoved__c = false;
        //sapordItems.Quantity_Shipped__c = 10.00;
        sapordItems.Quantity_Ordered__c = 10.00;
        insert sapordItems;
        System.debug('sapordItems'+sapordItems);
        
        SAP_Order_Item_Tracking__c orditemTracking = new SAP_Order_Item_Tracking__c();
        orditemTracking.PKIOrderItems__c = sapordItems.Id;
        orditemTracking.Quantity_Shipped__c = 10.00;
        orditemTracking.ExternalID__c = 'aabbcc11';
        insert orditemTracking;
        
        List<SAP_Order_Summary__c> ordsummary = new List<SAP_Order_Summary__c>();
        ordsummary.add(ordersummary);
        Set<String> str = new Set<String>();
        str.add(ordersummary.Id);
        List<SAP_Order_Summary__c> ordtest =  ECOM_SAPOrderSummaryRepo.fetchSAPOrderSummariesById(str);
        System.debug('ordersummary'+ordtest[0].fxStatusB2B__c);        
        ECOM_OrderModel ordmodel = new ECOM_OrderModel();
        Test.startTest();
        Map<String, Object> orderDetailsMap = ECOM_OrderHistoryController.getOrderDetails(testOrder.Id);
        ordmodel = (ECOM_OrderModel) orderDetailsMap.get('orderModel');
        Test.stopTest();
        System.assertnotEquals(null,ordmodel,'expected order should not be null');
    } 
    @isTest
    static void findOrderByOrderNumberAndZipTest(){
        Order order = [Select Id,OrderNumber,BillingPostalCode From Order ORDER BY CREATEDDATE DESC LIMIT 1];
        List<Order> result = new List<Order>();
        Test.startTest();
        result =  ECOM_OrderHistoryController.findOrderByOrderNumberAndZip(order.OrderNumber,order.BillingPostalCode);
        Test.stopTest();
        System.assertnotEquals(null,result,'expected order should not be null');
    } 
    @isTest
    static void getProdImagestest(){
        
        List<Product2> productList = [Select Id From Product2 ORDER BY CREATEDDATE DESC LIMIT 1];
        Network network = [SELECT id, name FROM Network limit 1];
        //List<Id> resultIds = (new Map<Id,Product2>(productList)).keySet();
        List<Id> prodIds = new List<Id> { ProductList[0].Id };
        Map<String, Object> result = new Map<String, Object>();
        Test.startTest();
        result =  ECOM_OrderHistoryController.getProdImages(prodIds,network.Id);
        Test.stopTest();
        System.assertnotEquals(null,result,'expected productidswith images');
    }
    @isTest
    static void addItemsToCarttest(){
        List<CartItem> cartitems = [Select Id,Product2Id,Quantity From CartItem ORDER BY CREATEDDATE DESC LIMIT 1];
        Account ac = [SELECT Id FROM Account WHERE Name = 'TestClass Account'];
        Network network = [SELECT id, name FROM Network limit 1];
        
        Test.startTest();
        Map<String,Object> response = ECOM_OrderHistoryController.addItemsToCart(network.Id,ac.Id,cartitems);
        Test.stopTest();
        
        System.assertnotEquals(null,response,'expected response');
    }
    
    @isTest 
    static void getWishlistDetailsTest(){
        Account ac = [SELECT Id FROM Account WHERE Name = 'TestClass Account'];
        User u = [Select Id From User  ORDER BY CREATEDDATE DESC LIMIT 1];
        WebStore webStr = [Select Id,Name from WebStore ORDER BY CREATEDDATE DESC LIMIT 1];
        Wishlist wishlist =  [Select Id,Name from Wishlist ORDER BY CREATEDDATE DESC LIMIT 1];
        
        
        Test.startTest();
        List<ECOM_AccountWrapper.WishlistDetails> wishListDetails =  ECOM_OrderHistoryController.getWishlistDetails();
        Test.stopTest();
        System.assertnotEquals(null,wishListDetails,'expected wishListDetails');
    }
    
   /* @isTest
    static void removeWishlistItemtest(){
        
        Account ac = [SELECT Id FROM Account WHERE Name = 'TestClass Account'];
        Network network = [SELECT id, name FROM Network limit 1];
        Wishlist wishlist =  [Select Id,Name from Wishlist ORDER BY CREATEDDATE DESC LIMIT 1];
        Product2 prd = [Select Id,Name from Product2 ORDER BY CREATEDDATE DESC LIMIT 1];
        WishlistItem wishlistitem =  [Select Id,Name from WishlistItem ORDER BY CREATEDDATE DESC LIMIT 1];
        
        Test.startTest();
        ECOM_OrderHistoryController.removeWishlistItem(network.Id,ac.Id,wishlist.Id,wishlistitem.Id);
        Test.stopTest();
        
        //we dont need assertion for void methods
    }*/
    @isTest
    static void createAndAddToListTest(){
        Account ac = [SELECT Id FROM Account WHERE Name = 'TestClass Account'];
        Network network = [SELECT id, name FROM Network limit 1];
        User u = [Select Id From User  ORDER BY CREATEDDATE DESC LIMIT 1];
        WebStore webStr = [Select Id,Name from WebStore ORDER BY CREATEDDATE DESC LIMIT 1];
        Wishlist wishlist =  [Select Id,Name from Wishlist ORDER BY CREATEDDATE DESC LIMIT 1];
        Product2 prd = [Select Id,Name from Product2 ORDER BY CREATEDDATE DESC LIMIT 1];
        WishlistItem wishlistitem =  [Select Id,Name from WishlistItem ORDER BY CREATEDDATE DESC LIMIT 1];
        
        Test.startTest();
        ConnectApi.WishlistItem wishListItemresult =  ECOM_OrderHistoryController.createAndAddToList(network.Id,ac.Id,wishlist.Id,wishlistitem.Id);
        Test.stopTest();
        System.assertnotEquals(null,wishListItemresult,'expected wishListDetails');
        
    }
    @isTest
    static void errorcreateAndAddToListTest(){
        Account ac = [SELECT Id FROM Account WHERE Name = 'TestClass Account'];
        Network network = [SELECT id, name FROM Network limit 1];
        User u = [Select Id From User  ORDER BY CREATEDDATE DESC LIMIT 1];
        WebStore webStr = [Select Id,Name from WebStore ORDER BY CREATEDDATE DESC LIMIT 1];
        //Wishlist wishlist = null;
        Product2 prd = [Select Id,Name from Product2 ORDER BY CREATEDDATE DESC LIMIT 1];
        WishlistItem wishlistitem =  [Select Id,Name from WishlistItem ORDER BY CREATEDDATE DESC LIMIT 1];
        
        Test.startTest();
        ConnectApi.WishlistItem wishListItemerrorresult = ECOM_OrderHistoryController.createAndAddToList(network.Id,ac.Id,null,wishlistitem.Id);
        System.assertEquals(wishListItemerrorresult.wishlistItemId,'xxxx','expected wishListDetails');
        Test.stopTest();
        
    }

    @isTest
    static void testfindSapOrderByOrderNumberAndZip(){
         String orderNumber = '123.00';
        String zipCode = '90210';
        
        SAP_Order_Summary__c ordsapSummary = new SAP_Order_Summary__c();
        ordsapSummary.Order_Number__c = 2334.00;
        ordsapSummary.Order_Number__c = Integer.valueOf(orderNumber);
        ordsapSummary.Ship_To_Address_Postal_Code__c = zipCode;
        insert ordsapSummary;
        
        Test.startTest();
       List<SAP_Order_Summary__c> orderSummaryList =  ECOM_OrderHistoryController.findSapOrderByOrderNumberAndZip(orderNumber,zipCode);
         System.assertnotEquals(null,orderSummaryList,'expected wishListDetails');        Test.stopTest();
    }
    
     @isTest
    static void testgetAllMySapOrders(){
        String email = 'test@yopmail.com';
        SAP_Order_Summary__c ordsapSummary = new SAP_Order_Summary__c();
        ordsapSummary.Contact_Email__c =  email ;
        insert ordsapSummary;
        
        Test.startTest();
       Map<String,Object> orderSummaryList =  ECOM_OrderHistoryController.getAllMySapOrders();
        Test.stopTest();
         System.assertnotEquals(null,orderSummaryList,'expected wishListDetails');        
    }

    //RWPS-5777 start
    @isTest
    static void testgetAllMySapOrdersCase1(){
        User testUser = [Select Id, Email, LastName, contactId, AccountId, ECOM_Is_Punchout_User__c From User ORDER BY CREATEDDATE DESC LIMIT 1];
        testUser.ECOM_Is_Punchout_User__c = true;
        update testUser;
        System.runAs(new User(Id=UserInfo.getUserId())) {
            List<Contact> contactList = [SELECT Id, Default_Ship_to_ERP_Address__r.Master_Address__c FROM Contact WHERE Id =: testUser.ContactId LIMIT 1];
            if (contactList.isEmpty() == false) {
                 string erpAddressId = contactList[0].Default_Ship_to_ERP_Address__r.Master_Address__c;
                 List<ERP_Address__c> addressList = [ SELECT Id, External_Id__c FROM ERP_Address__c WHERE Id = :erpAddressId LIMIT 1];
                if (!addressList.isEmpty()) {
                    Punchout_Maintenance__c pmRec = new Punchout_Maintenance__c(
                    ERP_Address__c = addressList[0].Id
                );
                insert pmRec;
                List<Punchout_Maintenance__c> pmList = [SELECT Id, ERP_Address__c, ECOM_Punchout_Format__c, Ecom_Punchout_Additional_Email_Address__c,ECOM_Punchout_User_Email__c FROM Punchout_Maintenance__c WHERE ERP_Address__c = :addressList[0].Id LIMIT 1];
                if (!pmList.isEmpty()) {
                    pmList[0].ECOM_Punchout_User_Email__c = ECOM_Constant.SHIP_TO_CONTACT_EMAIL_BOTH;
                    pmList[0].Ecom_Punchout_Additional_Email_Address__c = testUser.Email + ', email1@example.com, email2@example.com';
                    update pmList[0];
                }
                }
            }
        }
        System.runAs(testUser) {
            SAP_Order_Summary__c orderSummary = new SAP_Order_Summary__c();
            orderSummary.Order_Number__c= 2243;
            orderSummary.typeOrder__c = 'SP';
            orderSummary.ShipTo_Email__c = testUser.Email;
            orderSummary.Contact_Email__c = testUser.Email;
            orderSummary.Source_Type__c = 'ZEDI';
            orderSummary.PO_Type__c = 'INET';
            insert orderSummary;
            SAP_Order_Items__c orderItem = new SAP_Order_Items__c();
            orderItem.Line_Item_Number_Web__c = '1';
            orderItem.PKI_Order_Summary__c = orderSummary.Id;
            orderItem.isRemoved__c = false;
            orderItem.Quantity_Ordered__c = 10.00;
        	insert orderItem;
            Test.startTest();
            Map<String,Object> orderSummaryList =  ECOM_OrderHistoryController.getAllMySapOrders();
            Test.stopTest();
            
            System.assertnotEquals(null,orderSummaryList,'expected wishListDetails'); 
        }       
    }//RWPS-5777 end
    
    @isTest
    static  void testCreateOrderModel() {
        Account ac = [SELECT Id FROM Account WHERE Name = 'TestClass Account'];
        // Create test data for SAP_Order_Summary__c and related objects
        SAP_Order_Summary__c sapOrder = new SAP_Order_Summary__c(
            Account__c = ac.Id,
            Bill_To_Address_Street__c = '123 Main St',
            Bill_To_Address_City__c = 'City',
            Bill_To_Address_Region__c = 'State',
            Bill_To_Address_Postal_Code__c = '12345',
            Bill_To_Address_Country__c = 'Country',
            CreatedById = UserInfo.getUserId(),
            CreatedDate = Date.today(),
            Quote_Number__c = 'Q123',
            Order_Total_Price__c = 100.00
        );
        insert sapOrder;
        List<SAP_Order_Summary__c> orderList = new List<SAP_Order_Summary__c>();
        orderList.add(sapOrder);
        // Create related SAP_Order_Items__c records
        SAP_Order_Items__c sapOrderItem = new SAP_Order_Items__c();
        sapOrderItem.Material_Description__c = 'Product Description';
        sapOrderItem.PKI_Order_Summary__c = sapOrder.Id;
        // PKI_Order_Summary__c = sapOrder,
        sapOrderItem.Expected_Ship_Date__c = Date.today();
        sapOrderItem.Scheduled_Delivery_Date__c = Date.today();
        sapOrderItem.Extended_Price__c = 50.00;
        sapOrderItem.PKI_Order_Summary__c = sapOrder.Id;
        sapOrderItem.Material_Number__c = '1234567';
        sapOrderItem.Quantity_Ordered__c = 2;
        sapOrderItem.Customer_Specific_Price__c = 45.00;
        sapOrderItem.Net_Price__c = 40.00;
        sapOrderItem.Adjusted_Unit_Price__c = 42.00;
        insert sapOrderItem;
        // Create related SAP_Order_Item_Tracking__c records
        SAP_Order_Item_Tracking__c tracking = new SAP_Order_Item_Tracking__c(
            CarrierName__c = 'Carrier',
            PKIOrderItems__c = sapOrderItem.Id,
            PKIOrderSummary__c = sapOrder.Id,
            Quantity_Shipped__c = 2,
            ExternalID__c = '112234',
            Tracking_Date__c = Date.today(),
            TrackingNumber__c = 'Tracking123',
            TrackingURL__c = 'https://example.com/tracking'
        );
        insert tracking;
                Map<String, Product2> partNoVsProductMap = new Map<String, Product2>();
        Test.startTest();
        ECOM_OrderModel result = ECOM_OrderHistoryController.createOrderModel(orderList,partNoVsProductMap);
        Test.stopTest();
        // Verify the expected outcomes
        System.assertNotEquals(null, result, 'ECOM_OrderModel should not be null');
        
    }

    @isTest
    static void testGetOrderDetails_SAP_Order_Summary_Id() {
        Account ac = [SELECT Id FROM Account WHERE Name = 'TestClass Account'];
        Order order = [SELECT Id, ECOM_SAP_Order_Number__c,ECOM_Order_On_Hold__c ,ECOM_Order_Create_Retry__c FROM Order ORDER BY CreatedDate DESC LIMIT 1];
        order.ECOM_SAP_Order_Number__c = '2233';
        update order;
        OrderItem ordItem = [Select Id,OrderId,Product2.Name From OrderItem  where OrderId =:order.Id ORDER BY CreatedDate DESC Limit 1];
        // Create a test SAP_Order_Summary__c record for order detail retrieval
         SAP_Order_Summary__c testSapOrder = new SAP_Order_Summary__c(
            Account__c = ac.Id,   
            Bill_To_Address_Street__c = '123 Main St',
            Bill_To_Address_City__c = 'City',
            Bill_To_Address_Region__c = 'State',
            Bill_To_Address_Postal_Code__c = '12345',
            Bill_To_Address_Country__c = 'Country',
            CreatedById = UserInfo.getUserId(),
            CreatedDate = Date.today(),
            Quote_Number__c = 'Q123',
            Order_Total_Price__c = 100.00
        );
        insert testSapOrder;
        SAP_Order_Items__c sapOrderItem = new SAP_Order_Items__c();
        sapOrderItem.Material_Description__c = 'Product Description';
        sapOrderItem.PKI_Order_Summary__c = testSapOrder.Id;
        // PKI_Order_Summary__c = sapOrder,
        sapOrderItem.Expected_Ship_Date__c = Date.today();
        sapOrderItem.Scheduled_Delivery_Date__c = Date.today();
        sapOrderItem.Extended_Price__c = 50.00;
        sapOrderItem.Material_Number__c = '1234567';
        sapOrderItem.Quantity_Ordered__c = 2;
        sapOrderItem.Customer_Specific_Price__c = 45.00;
        sapOrderItem.Net_Price__c = 40.00;
        sapOrderItem.Adjusted_Unit_Price__c = 42.00;
        insert sapOrderItem;
        SAP_Order_Item_Tracking__c tracking = new SAP_Order_Item_Tracking__c(
            CarrierName__c = 'Carrier',
            PKIOrderItems__c = sapOrderItem.Id,
            PKIOrderSummary__c = testSapOrder.Id,
            Quantity_Shipped__c = 2,
            ExternalID__c = '112234',
            Tracking_Date__c = Date.today(),
            TrackingNumber__c = 'Tracking123',
            TrackingURL__c = 'https://example.com/tracking'
        );
        insert tracking;
        // Call the getOrderDetails method with the test SAP_Order_Summary__c Id
        //ECOM_OrderModel result = ECOM_OrderHistoryController.getOrderDetails(testSapOrder.Id);
		Map<String, Object> orderDetailsMap = ECOM_OrderHistoryController.getOrderDetails(testSapOrder.Id);
        ECOM_OrderModel result = (ECOM_OrderModel) orderDetailsMap.get('orderModel');
        // Perform assertions to validate the result
        System.assertNotEquals(null, result, 'Expected result not null');
        Map<String, Object> responseMap =  ECOM_OrderHistoryController.removeWishlistItem('id');//RWPS-3026
    }

	//RWPS-3026 - Start
    // @isTest
    // static void testGetOrderDetailsGetERPAddress() {
        
    //     Account account = [SELECT id, name FROM Account LIMIT 1];
    //     Contact contact = [SELECT id FROM Contact WHERE accountId =: account.id LIMIT 1];
    //     ERP_Address__c erpaddressMaster = ECOM_TestUtil.createMasterErpaddress();
    //     insert erpaddressMaster;
    //     ERP_Address__c erpaddress = ECOM_TestUtil.createErpaddress(account,contact, erpaddressMaster );
    //     insert erpaddress;
    //     ERP_Address__c erpaddressPayer = ECOM_TestUtil.createPayerErpaddress(account, contact, erpaddress, erpaddressMaster);
    //     insert erpaddressPayer;
    // 	Map<String, Object> responseMap =  ECOM_OrderHistoryController.getERPAddress(string.valueOf(erpaddress.id),string.valueOf(erpaddressPayer.id) );
    //     List<Account> accountList = ECOM_OrderHistoryController.getAccountBasedOnIds(new List<String>{string.valueOf(account.id)});
    // }
    //RWPS-3026 - End

    //RWPS-3741
     /* @isTest
    static void testgetAllPunchoutSapOrders(){
        User u = [Select Id,LastName From User where ECOM_Is_Punchout_User__c=true ORDER BY CREATEDDATE DESC LIMIT 1];
        
        Test.startTest();
        List<Order> ord;
        System.runAs(u){
          Map<String,Object> orderSummaryList =  ECOM_OrderHistoryController.getAllMySapOrders();
        }        
    } */

    /**
     * RWPS-3772
    * @description Test method to verify the method 'fetchProductUnavailability' from 'ECOM_OrderHistoryController'
    * @author Sachin Vispute 2025.10.07
    */
    @isTest
    private static void testFetchProductUnavailabilityWithDiscontinuedProducts() {
        Product2 sellableProduct = ECOM_TestUtil.createProduct('Test Sellable Product', 'TEST-0000', 'TEST-PC-0000', true);
        Product2 sellableAlternativeProduct = ECOM_TestUtil.createProduct('Test Sellable Alternate Product', 'TEST-0001', 'TEST-PC-0001', true);
        Product2 discontinuedProduct = ECOM_TestUtil.createProduct('Test Discontinued Product', 'TEST-0002', 'TEST-PC-0002', true);
        Product2 nonSellableProduct = ECOM_TestUtil.createProduct('Test NonSellableProduct Product', 'TEST-0003', 'TEST-PC-0003', true);
        Product2 discontinuedDirectReplacementProduct = ECOM_TestUtil.createProduct('Test DirectReplacementProduct Product', 'TEST-0004', 'TEST-PC-0004', true);
        Product2 discontinuedDirectReplacementDisabledProduct = ECOM_TestUtil.createProduct('Test DirectReplacementProduct Product', 'TEST-0005', 'TEST-PC-0005', true);
        Product2 discontinuedIndirectReplacementProduct = ECOM_TestUtil.createProduct('Test IndirectReplacementProduct Product', 'TEST-0006', 'TEST-PC-0006', true);
        Product2 discontinuedIndirectReplacementDisabledProduct = ECOM_TestUtil.createProduct('Test IndirectReplacementProduct Product', 'TEST-0007', 'TEST-PC-0007', true);
        Product2 discontinuedWithReplacementDiscontinuedProduct = ECOM_TestUtil.createProduct('Test DicontinuedReplacement Product', 'TEST-0008', 'TEST-PC-0008', true);
        List<Product2> productUpdateList = new List<Product2>();
        discontinuedDirectReplacementProduct.Replacement_Product__c = sellableProduct.Id;
        discontinuedIndirectReplacementProduct.Replacement_Alternatives__c = sellableProduct.Part_Number__c +','+ sellableProduct.Part_Number__c;
        discontinuedDirectReplacementDisabledProduct.Replacement_Product__c = sellableAlternativeProduct.Id;
        discontinuedIndirectReplacementDisabledProduct.Replacement_Alternatives__c = sellableAlternativeProduct.Part_Number__c +','+ sellableProduct.Part_Number__c;
        productUpdateList.add(discontinuedDirectReplacementProduct);
        productUpdateList.add(discontinuedIndirectReplacementProduct);
        productUpdateList.add(discontinuedDirectReplacementDisabledProduct);
        productUpdateList.add(discontinuedIndirectReplacementDisabledProduct);
        update productUpdateList;

        Product_Sales__c sellableProductSales = ECOM_TestUtil.createProduct_Sales(String.valueOf(sellableProduct.Id));
        Product_Sales__c sellableAlternativeProductSales = ECOM_TestUtil.createProduct_Sales(String.valueOf(sellableAlternativeProduct.Id));
        Product_Sales__c discontinuedProductSales = ECOM_TestUtil.createProduct_Sales(String.valueOf(discontinuedProduct.Id));
        Product_Sales__c nonSellableProductSales = ECOM_TestUtil.createProduct_Sales(String.valueOf(nonSellableProduct.Id));
        Product_Sales__c discontinuedDirectReplacementProductSales = ECOM_TestUtil.createProduct_Sales(String.valueOf(discontinuedDirectReplacementProduct.Id));
        Product_Sales__c discontinuedDirectReplacementAlternativeProductSales = ECOM_TestUtil.createProduct_Sales(String.valueOf(discontinuedDirectReplacementDisabledProduct.Id));
        Product_Sales__c discontinuedIndirectReplacementProductSales = ECOM_TestUtil.createProduct_Sales(String.valueOf(discontinuedIndirectReplacementProduct.Id));
        Product_Sales__c discontinuedWithReplacementDiscontinuedProductSales = ECOM_TestUtil.createProduct_Sales(String.valueOf(discontinuedIndirectReplacementDisabledProduct.Id));
        List<Product_Sales__c> productSalesUpdateList = new List<Product_Sales__c>();

        sellableProductSales.Distribution_ChainSpecificMaterialStatus__c = 'ZW';
        sellableProductSales.Sales_Org__c = 'EEU2';
        sellableAlternativeProductSales.Distribution_ChainSpecificMaterialStatus__c = 'ZS';
        sellableAlternativeProductSales.Sales_Org__c = 'EEU2';
        discontinuedProductSales.Distribution_ChainSpecificMaterialStatus__c = '02';
        discontinuedProductSales.Sales_Org__c = 'EEU2';
        nonSellableProductSales.Distribution_ChainSpecificMaterialStatus__c = 'ZS';
        nonSellableProductSales.Sales_Org__c = 'EEU2';
        discontinuedDirectReplacementProductSales.Distribution_ChainSpecificMaterialStatus__c = '02';
        discontinuedDirectReplacementProductSales.Sales_Org__c = 'EEU2';
        discontinuedDirectReplacementAlternativeProductSales.Distribution_ChainSpecificMaterialStatus__c = '02';
        discontinuedDirectReplacementAlternativeProductSales.Sales_Org__c = 'EEU2';
        discontinuedIndirectReplacementProductSales.Distribution_ChainSpecificMaterialStatus__c = '02';
        discontinuedIndirectReplacementProductSales.Sales_Org__c = 'EEU2';
        discontinuedWithReplacementDiscontinuedProductSales.Distribution_ChainSpecificMaterialStatus__c = '02';
        discontinuedWithReplacementDiscontinuedProductSales.Sales_Org__c = 'EEU2';

        productSalesUpdateList.add(sellableProductSales);
        productSalesUpdateList.add(sellableAlternativeProductSales);
        productSalesUpdateList.add(discontinuedProductSales);
        productSalesUpdateList.add(nonSellableProductSales);
        productSalesUpdateList.add(discontinuedDirectReplacementProductSales);
        productSalesUpdateList.add(discontinuedDirectReplacementAlternativeProductSales);
        productSalesUpdateList.add(discontinuedIndirectReplacementProductSales);
        productSalesUpdateList.add(discontinuedWithReplacementDiscontinuedProductSales);
        insert productSalesUpdateList;

        Map<String,Object> productDetailsMap = ECOM_OrderHistoryController.fetchProductUnavailability(new List<String>{
            sellableProduct.Id,
            discontinuedProduct.Id,
            nonSellableProduct.Id,
            discontinuedDirectReplacementProduct.Id,
            discontinuedDirectReplacementDisabledProduct.Id,
            discontinuedIndirectReplacementProduct.Id,
            discontinuedIndirectReplacementDisabledProduct.Id});
        Assert.areEqual(false, productDetailsMap.isEmpty(), 'ProductDetails Must be received');
    }

    /**
     * RWPS-3772
    * @description Test method to verify the method 'getorderDetailsAndReplacement' from 'ECOM_OrderHistoryController'
    * @author Sachin Vispute 2025.10.07
    */
    @isTest
    private static void testGetorderDetailsAndReplacement() {
        List<Order> orderList = [SELECT Id, OrderNumber FROM Order LIMIT 1];
        List<Network> networkList = [SELECT id, name FROM Network LIMIT 1];
        if (orderList.isEmpty() == false && networkList.isEmpty() == false) {
            Map<String,Object> replacementMap = new Map<String,Object>();
            Test.startTest();
            replacementMap =  ECOM_OrderHistoryController.getorderDetailsAndReplacement(orderList[0].Id, networkList[0].Id);
            Test.stopTest();
            Assert.areEqual(false, replacementMap.isEmpty(), 'replacementMap Must be received');
        }
    }

    /**
     * RWPS-3772
    * @description Test method to verify the method 'getorderDetailsAndReplacementWithException' from 'ECOM_OrderHistoryController'
    * @author Sachin Vispute 2025.10.07
    */
    @isTest
    private static void testGetorderDetailsAndReplacementWithExceptionTest() {
        List<Order> orderList = [SELECT Id, OrderNumber FROM Order LIMIT 1];
        List<Network> networkList = [SELECT id, name FROM Network LIMIT 1];
        if (orderList.isEmpty() == false && networkList.isEmpty() == false) {
            Map<String,Object> replacementMap = new Map<String,Object>();
            Test.startTest();
            delete orderList[0];
            replacementMap =  ECOM_OrderHistoryController.getorderDetailsAndReplacement(orderList[0].Id, networkList[0].Id);
            Test.stopTest();
            Assert.areEqual(false, replacementMap.isEmpty(), 'replacementMap Must be received');
        }
    }

    /**
     * RWPS-3772
    * @description Test method to verify the method 'checkIfCurrentUserIsPunchoutUser' from 'ECOM_OrderHistoryController'
    * @author Sachin Vispute 2025.10.07
    */
    @isTest
    private static void testCheckIfCurrentUserIsPunchoutUserTest() {
        Boolean isPunchoutUser;
        Test.startTest();
        isPunchoutUser =  ECOM_OrderHistoryController.checkIfCurrentUserIsPunchoutUser();
        Test.stopTest();
        Assert.areEqual(false, isPunchoutUser == null, 'User punchout information should be fetched');
    }

    /**
     * RWPS-4881
     * @description Test method to verify the method 'getOnlineOrders' from 'ECOM_OrderHistoryController'
     * @author Sachin Vispute 2025.10.28
     */
    @isTest
    static void testGetOnlineOrders() {
        List<Order> ordersList = [Select Id From Order ORDER BY CREATEDDATE DESC LIMIT 1];
        List<User> userList = [Select Id, LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Test.startTest();
        Map<String, Object> responseMap = new Map<String, Object>();
        System.runAs(userList[0]) {
            String searchString = 't';
            responseMap =  ECOM_OrderHistoryController.getOnlineOrders(searchString);
        }
        Test.stopTest();
        System.assertNotEquals(null, responseMap,'expected Order Details');
    }

    //RWPS-5777 start
    @isTest
    static void testGetOnlineOrdersCase1() {
        List<Order> ordersList = [Select Id From Order ORDER BY CREATEDDATE DESC LIMIT 1];
      User testUser = [Select Id, Email, LastName, contactId, AccountId, ECOM_Is_Punchout_User__c From User ORDER BY CREATEDDATE DESC LIMIT 1];
        testUser.ECOM_Is_Punchout_User__c = false;
        update testUser;
        Test.startTest();
        Map<String, Object> responseMap = new Map<String, Object>();
        System.runAs(testUser) {
            String searchString = 't';
            responseMap =  ECOM_OrderHistoryController.getOnlineOrders(searchString);
        }
        Test.stopTest();
        System.assertNotEquals(null, responseMap,'expected Order Details');
    }//RWPS-5777 end

    /**
     * RWPS-4881
     * @description Test method to verify the method 'getOfflineOrders' from 'ECOM_OrderHistoryController'
     * @author Sachin Vispute 2025.10.28
     */
    @isTest
    static void testGetOfflineOrders(){
        String email = 'test@yopmail.com';
        SAP_Order_Summary__c SAPOrderSummary = new SAP_Order_Summary__c();
        SAPOrderSummary.Contact_Email__c =  email ;
        insert SAPOrderSummary;
        Test.startTest();
        Map<String,Object> orderSummaryList =  ECOM_OrderHistoryController.getOfflineOrders(null, false);
        Test.stopTest();
        System.assertNotEquals(null, orderSummaryList,'Expected Order Details');
    }

    /**
     * RWPS-4881
     * @description Test method to verify the method 'getOfflineOrders' from 'ECOM_OrderHistoryController'
     * @author Sachin Vispute 2025.11.06
     */
    @isTest
    static void testGetOfflineOrdersPunchout(){
        String email = 'test@yopmail.com';
        SAP_Order_Summary__c SAPOrderSummary = new SAP_Order_Summary__c();
        SAPOrderSummary.Contact_Email__c =  email ;
        insert SAPOrderSummary;
        Test.startTest();
        Map<String,Object> orderSummaryList =  ECOM_OrderHistoryController.getOfflineOrders(null, true);
        Test.stopTest();
        System.assertNotEquals(null, orderSummaryList,'Expected Order Details');
    }

    /**
     * RWPS-5094
     * @description Test method to verify the method 'getOfflineOrders' from 'ECOM_OrderHistoryController'
     * @author Sachin Vispute 2025.11.06
     */
    @isTest
    static void testGetOfflineOrdersWithSearchForPunchout(){
        String email = 'test@yopmail.com';
        SAP_Order_Summary__c SAPOrderSummary = new SAP_Order_Summary__c();
        SAPOrderSummary.Contact_Email__c =  email ;
        insert SAPOrderSummary;
        Test.startTest();
        Map<String,Object> orderSummaryList =  ECOM_OrderHistoryController.getOfflineOrders('t', true);
        Test.stopTest();
        System.assertNotEquals(null, orderSummaryList,'Expected Order Details');
    }

    /**
     * RWPS-4881
     * @description Test method to verify the method 'getEncodedValues' from 'ECOM_OrderHistoryController'
     * @author Sachin Vispute 2025.10.28
     */
    @isTest
    static void testGetEncodedValues() {
        Map<String, String> urlParamtersMap = new Map<String,String> {'hierarchyNumber' => 'test123' , 'searchData' => 'test890'};
        Test.startTest();
        Map<String, String> urlParamtersEncodedMap =  ECOM_OrderHistoryController.getEncodedValues(urlParamtersMap);
        Test.stopTest();
        System.assertNotEquals(urlParamtersMap.get('hierarchyNumber'), null,'Expected EncodedmValue');
    }
    /**
     * RWPS-4881
     * @description Test method to verify the method 'fetchSalesOrg' from 'ECOM_OrderHistoryController'
     * @author Sachin Vispute 2025.11.06
     */
    @isTest
    static void testFetchSalesOrg() {
        String salesOrg = null;
        Test.startTest();
        salesOrg =  ECOM_OrderHistoryController.fetchSalesOrg();
        Test.stopTest();
        System.assertNotEquals(salesOrg, null,'Expected salesOrg');
    }
}