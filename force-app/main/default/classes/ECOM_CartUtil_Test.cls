/**************************************************************
 * 1. Jira Ticket(s) that relates to this class
 *    ECOM-
 *
 * 2. Description - This class is a test class for ECOM_CartUtil
 *					- Call the ECOM_TestUtil Class to create test data and test each methods.
- Used System Assertion to Confirm the functionalities.
     *
 *
 * 3. Objects referenced
 *   - WebCart
 *	- CartItem
 *
 * 4. Callouts to additional Components (including their methods) or None:
 *    - None
 *
 *
 * 5. Dependant Class(es):
 *    - ECOM_TestUtil
 *    - ECOM_CartUtil
 *
 * 6. Test Class Name: ECOM_CartUtil_Test
 *
 * 7. Is @Invocable (Yes or No): No
 *
 * 8. Author Name(s):
 *    - Vipul 2023.07.19
 *    - Manoj 2023.07.19
 *    - Dar Sept 13th 2023 ECOM-493
 *    - Sidak 2024.04.08 RWPS-415 Updated generateOrderSimulationRequest method with User & Contact parameters.
 *    - Manoj 2024-05-01 RWPS-584 Instrument freight not applying as expected on web orders(Cob=verd test coverage for new method)
 *    - Manoj 2024.05.28 - RWPS-741 SFB2B - Technical - Trim down the Fetch User API - Remove Cart Items(Covered Test class)
 *    - Manoj 2024.09.09 RWPS-1387 read image from Product2.ECOM_Product_Media_URI__c(DAM) instead product media
 *    - Prabhat 2025.03.21 Updated methods testValidateProductMaterialException to increase test coverage -RWPS-2683
 *    - Abhishek 2025.04.03 Added method testGetAddressesForCalloutMapped, testGetAddressesForCalloutUnmapped, testPopulateCartDetailsWithCartItems. Ticket - RWPS-2858
 *    - Gaurav Bhansali 2025.04.18 Added testIsLargePackItemExist to check if large pack item exist in cart or not - RWPS-1285
 *    - Manish Joshi 2025.04.28 Updated method testUpdateCartItems for code coverage - RWPS-3026
 *    - Poonam 2025.06.11 Added method testIsInvoiceEmailExistCase1, testIsInvoiceEmailExistCase2 for code coverage - RWPS-1882
 *    - Prabhat 2025.07.24 Added method testUpdateDiscontinuedCartItem for code coverage - RWPS-1603
 * 	 - Gaurav 2025.08.29  Added testGetCartsBasedOnOwnerAndAccount, testGetCartItemDetailsMap for code coverage logic - RWPS-4202
 *    - Prabhat 2025.09.15 Updated method testupdateCouponAndDiscountAndgenerateOrderSimulationRequest to increase the coverage - RWPS-3811
 *    - Aryan 2026.03.12 Created methods testUpdatePunchoutLogWithPOOMvalues_MainFlow, testpopulateDefaultCartDeliveryGroupMethod_InsertBranch, testValidateProductMaterialStatus_NonSellableBlock, testValidateProductMaterialStatus_ProductSalesMismatch, testGetInActiveProducts - RWPS 6095
 *    - Poonam Shukla 2026.03.18 Updated method testupdateCouponAndDiscountAndgenerateOrderSimulationRequest- RWPS-6394
 *************************************************************/


@isTest(seeAllData=false)
public with sharing class ECOM_CartUtil_Test {
    @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
    }
    @isTest
    static void testFetchCartDetails() {
        // test cases for the fetchCartDetails method here
        User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        Account ac = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
        Boolean createNewCart = false;
        Webcart result = ECOM_CartUtil.fetchCartDetails('testUserId', 'effectiveAccountId', 'TestShip', false);
        createNewCart = true;
        //@mayank ConnectApi.CartSummary cartSummaryObject issue
        ECOM_CartUtil.createNewCart(u.Id, ac.Id, ac.Id);
        User usr = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(usr)
        {
            Webcart result1 = ECOM_CartUtil.fetchCartDetails(u.Id, ac.Id, ac.Id, createNewCart);
            System.assertEquals(null,result,'Wrong Output');
        }
        
        
    }
    
    //    @isTest
    //  static void testCreateNewCart() {
        // Write test cases for the createNewCart method here
        
    //}
    
    @isTest
    static void testResolveCommunityIdToWebstoreId() {
        //  test cases for the resolveCommunityIdToWebstoreId method here
        Network comm = [SELECT Id FROM Network ORDER BY CREATEDDATE DESC LIMIT 1];
        User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
            Test.startTest();
            String result = ECOM_Util.resolveCommunityIdToWebstoreId(comm.Id);
            Test.stopTest();
            System.AssertNotEquals(null,result,'Wrong Output');
        }
    }
    
    @isTest
    static void testResolveSortParam() {
        //  test cases for the resolveSortParam method here
        String sortParam = 'CreatedDateAsc';
        User usr = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(usr)
        {
            ConnectApi.CartItemSortOrder result = ECOM_CartUtil.resolveSortParam(sortParam);
            System.AssertNotEquals(null,result,'Wrong Output');
        }
        
    }
    
    @isTest
    static void testParseCartSummary() {
        //  test cases for the parseCartSummary method here
        String webstoreId = [SELECT Id FROM WebStore ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        Webcart cart = [SELECT Id,Name FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
        String accountId = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
            ConnectApi.CartSummary cartSummary = new ConnectApi.CartSummary();
            ECOM_CartModel result = ECOM_CartUtil.parseCartSummary(cartSummary);
            System.AssertNotEquals(null,result,'Wrong Output');
        }
    }
    
    @isTest
    static void testParseWebCarts() {
        //  test cases for the parseWebCarts method here
        List<WebCart> webCarts = [SELECT Id, AccountId, CurrencyIsoCode, GrandTotalAmount, IsSecondary, Name, OwnerId, PoNumber, Status, TaxType, TotalProductAmount,ECOM_Total_Savings__c,
                             TotalListAmount, TotalChargeAmount, TotalAdjustmentAmount, TotalProductCount, TotalPromoAdjustmentAmount, TotalTaxAmount, Type, UniqueProductCount,
                             WebStoreId, ECOM_Is_Punchout_Cart__c, (SELECT Id, Sku, Quantity,ListPrice,SalesPrice,NetAdjustmentAmount,TotalAmount,TotalLineAmount,TotalPrice,TotalAdjustmentAmount,TotalPriceAfterAllAdjustments,ECOM_Earliest_Shipping_Date__c, ECOM_Selected_Shipping_Date__c,
                             UnitAdjustedPrice,UnitAdjustmentAmount,TotalListPrice, TotalTaxAmount, CartId, CartDeliveryGroupId, Product2.Id, ECOM_Parent__c,
                             Product2.Part_Number__c,Product2.Name,Product2.Dangerous_Goods_Indicator_Profile__c,Type , Product2.Business_Unit__c, Product2.Discount_Type__c,
                             Product2.Item_Class__c, Product2.Part_Type__c, Product2.ECOM_Product_Media_URI__c,
                             Product2.Product_Line__c, Product2.Product_Type__c,Product2.IGOR_PAC__c,Product2.DisplayUrl,Product2.IGOR_Item_Class_Desc__c,Product2.Product_Line_Name__c,Product2.IGOR_Description__c,Product2.Sub_Business_Unit__c,Product2.Super_Business_Unit__c,CurrencyISOCode
                             FROM CartItems ORDER BY Sku ASC, ECOM_Earliest_Shipping_Date__c ASC)
                             FROM WebCart ORDER BY CreatedDate DESC LIMIT 1];
        
        //test call to parseWebCarts method
        User u = [SELECT Id,AccountId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
            List<ECOM_CartModel> result = ECOM_CartUtil.parseWebCarts(webCarts);
            System.AssertNotEquals(null,result,'Wrong Output');
        }
        
    }
    
    @isTest
    static void testParseCartItem() {
        //  test cases for the parseCartItem method here
        ConnectApi.CartItemCollection cItems;
        test.startTest();
        //List<ECOM_CartItemModel> result = ECOM_CartUtil.parseCartItems(cItems);
        
        //List<ECOM_CartItemModel> response = ECOM_CartUtil.parseCartItems(cItems);
        test.stopTest();
        
        
    }
    
    @isTest
    static void testParseCartItems() {
        // Write test cases for the parseCartItems method here
    }
    
    @isTest
    static void testParseCartItemsBatchResults() {
        // Write test cases for the parseCartItemsBatchResults method here
        // RWPS-6095 - START
        List<ConnectApi.BatchResult> batchResults = new List<ConnectApi.BatchResult>();
        List<ECOM_CartItemModel> items = ECOM_CartUtil.parseCartItemsBatchResults(batchResults);
        System.assertEquals(0, items.size());
        // RWPS-6095 - ENDS
    }
    //RWPS-1603 - START
    @isTest
    static void testUpdateDiscontinuedCartItem(){
        List<CartItem> testCartItems = [SELECT Id,CartId,CartDeliveryGroupId,Type,ECOM_Parent__c,Product2.Id,Product2.Part_Number__c
                                        FROM CartItem ORDER BY CREATEDDATE DESC LIMIT 1];
        List<CartItem> items = ECOM_CartUtil.updateDiscontinuedCartItem(testCartItems[0]);
    }
    //RWPS-1603 - END
    
    @isTest
    static void testUpdateCartItems() {
        //FETCH test data
        List<CartItem> testCartItems = [SELECT Id,CartId,CartDeliveryGroupId,Type,ECOM_Parent__c,Product2.Id,Product2.Part_Number__c,ECOM_Parent_Item__c
                                        FROM CartItem ORDER BY CREATEDDATE DESC LIMIT 1];
        testCartItems[0].ECOM_Parent__c=null;
        testCartItems[0].Type='';
        testCartItems[0].ECOM_Parent_Item__c='';
        update testCartItems[0];
        List<WebCart> cartList = ECOM_CartRepo.getCartandCartItemsById(testCartItems[0].CartId);
        
        Product2 prod = [SELECT Id,Part_Number__c FROM Product2 WHERE Id=:testCartItems[0].Product2.Id LIMIT 1];
        prod.Part_Number__c='NEC100X050UC';
        update prod;
        testCartItems = [SELECT Id,CartId,Quantity,CartDeliveryGroupId,Type,ECOM_Parent__c,Product2.Id,Product2.Part_Number__c,ECOM_Parent_Item__c
                                        FROM CartItem ORDER BY CREATEDDATE DESC LIMIT 1];
        ECOM_SimulateOrderWrapper.OrderRequest orderRequest = new ECOM_SimulateOrderWrapper.OrderRequest();
        ECOM_SimulateOrderWrapper.OrderResponse orderSimulateResponse = new ECOM_SimulateOrderWrapper.OrderResponse();
        orderSimulateResponse.paymentTerms = 'Due Upon Receipt';
        orderSimulateResponse.incoTerms = 'FOB Factory - Prepay &amp; Add';
        orderSimulateResponse.incoCode = 'F02';
        orderSimulateResponse.currencyCode = 'CAD';
        orderSimulateResponse.shippingCost = '27';
        orderSimulateResponse.totalPrice = '500';
        orderSimulateResponse.totalTaxVat = '10';
        List<ECOM_SimulateOrderWrapper.ProductList> prl = new List<ECOM_SimulateOrderWrapper.ProductList>();
        ECOM_SimulateOrderWrapper.ProductList product = new ECOM_SimulateOrderWrapper.ProductList();
        ECOM_SimulateOrderWrapper.ItemDetail itemDetail = new ECOM_SimulateOrderWrapper.ItemDetail();
        List<ECOM_SimulateOrderWrapper.ItemDetail> details = new List<ECOM_SimulateOrderWrapper.ItemDetail>();
        
        product.itemNumber = '1';
        product.partNumber = 'NEC100X050UC';
        product.shippingPoint = 'US36';
        product.linePrice = '10000';
        product.discount = 5;
        product.handling = 10; // Assuming handling should be an integer
        product.freight = 2;
        product.taxVat = '150.00';
        product.salesPrice = '16495.00';
        product.listPrice = '16495.00';
        itemDetail.availableDate = '2024-01-01';
        itemDetail.availableQty='0';
        details.add(itemDetail);
        product.itemDetail = details;
        prl.add(product);
        orderSimulateResponse.productList = prl;
        
        
        prl = new List<ECOM_SimulateOrderWrapper.ProductList>();
        product = new ECOM_SimulateOrderWrapper.ProductList();
        details = new List<ECOM_SimulateOrderWrapper.ItemDetail>();
        
        product.itemNumber = '2';
        product.partNumber = 'NEC100X050UC';
        product.shippingPoint = 'US36';
        product.linePrice = '10000';
        product.discount = 5;
        product.handling = 10; // Assuming handling should be an integer
        product.freight = 2;
        product.taxVat = '150.00';
        product.salesPrice = '16495.00';
        product.listPrice = '16495.00';
        itemDetail.availableDate = '2024-01-02';
        itemDetail.availableQty='1.33';
        details.add(itemDetail);
        product.itemDetail = details;
        product.tariff_surcharge = 10;//RWPS-3026
        prl.add(product);
        orderSimulateResponse.productList = prl;
        // Populate orderSimulateResponse with test data as needed
        try{
            Test.startTest();
            // Call the method to be tested
            User usr = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
            System.runAs(usr)
            {
                List<CartItem> updatedCartItems = ECOM_CartUtil.updateCartItems(cartList[0],testCartItems, orderRequest, orderSimulateResponse);
                Boolean output = ECOM_CartUtil.upsertCartItems(testCartItems);
                System.assertEquals(true,output,'WrongOutput -testUpdateCartItems ');
                Test.stopTest();
            }
        }catch(Exception e){
            
            
        }
        
    }
    
    @isTest
    static void testMessageSummaryWrapper() {
        ECOM_MessagesSummary messageSummary = new ECOM_MessagesSummary();
        messageSummary.hasErrors = true;
        messageSummary.message = 'Some error message';
        messageSummary.relatedEntityId = 'relatedEntityId';
    }
    @isTest
    static void testCreateCartDeliveryChargeItem() {
        // Call the method to be tested
        Decimal shippingAmount = 10.0; // Replace with your desired shipping amount
        String cartId = [SELECT Id FROM WebCart ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        Id cartDeliveryGroupId = [SELECT Id FROM CartDeliveryGroup ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        
        Test.startTest();
        CartItem deliveryCharge = ECOM_CartUtil.createCartDeliveryChargeItem(shippingAmount, cartId, cartDeliveryGroupId, null);
        Test.stopTest();
        
        // Perform assertions to verify the results
        System.assertEquals('Charge', deliveryCharge.Type, 'Type should be "Charge"');
        System.assertEquals('Shipping Cost', deliveryCharge.Name, 'Name should be "Shipping Cost"');
        
    }
@isTest
public static void testupdateCouponAndDiscountAndgenerateOrderSimulationRequest() {
    try {
        User u = [SELECT Id, AccountId, ContactId, Contact.Id, Contact.AccountId, Contact.ECOM_CountryProvided__c, Contact.MailingCountry FROM User WHERE Username = 'testR1@test.org' ORDER BY CreatedDate DESC LIMIT 1];//RWPS-6394

        Contact con = [SELECT Id, Default_Ship_to_ERP_Address__c, Default_Bill_to_ERP_Address__c, ECOM_Is_Mapped__c, Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c, Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c, Default_Ship_to_ERP_Address__r.Target_Address__r.fxAddress_CountryCode__c FROM Contact WHERE Id = :u.ContactId LIMIT 1];
        Webcart cart = [SELECT Id, TotalProductAmount, Default_Ship_to_ERP_Address__r.Target_Address__c, Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c, Default_Ship_to_ERP_Address__r.Target_Address__r.fxAddress_CountryCode__c, Default_Bill_to_ERP_Address__r.Target_Address__c, Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c, BillingCountryCode, Default_Bill_to_ERP_Address__c, Default_Ship_to_ERP_Address__c, PoNumber, PaymentMethodId FROM Webcart ORDER BY CreatedDate DESC LIMIT 1];
        cart.Default_Ship_to_ERP_Address__c = con.Default_Ship_to_ERP_Address__c;
        cart.Default_Bill_to_ERP_Address__c = con.Default_Bill_to_ERP_Address__c;
        update cart;//RWPS-6394 start

        List<CartItem> testCartItems = [SELECT Id, CartId, Type, ECOM_Parent__c, ECOM_Parent_Item__c, Product2Id FROM CartItem ORDER BY CreatedDate DESC LIMIT 1];
        testCartItems[0].ECOM_Parent__c = null;
        testCartItems[0].Type = '';
        testCartItems[0].ECOM_Parent_Item__c = '';
        update testCartItems[0];

        List<WebCart> cartList = ECOM_CartRepo.getCartandCartItemsById(cart.Id);
        //RWPS-6394 end
        ECOM_SimulateOrderWrapper.OrderResponse orderSimulateResponse = new ECOM_SimulateOrderWrapper.OrderResponse();
        orderSimulateResponse.paymentTerms = 'Due Upon Receipt';
        orderSimulateResponse.incoTerms = 'FOB Factory - Prepay &amp; Add';
        orderSimulateResponse.incoCode = 'F02';
        orderSimulateResponse.currencyCode = 'CAD';
        orderSimulateResponse.shippingCost = '27';
        orderSimulateResponse.totalPrice = '500';
        orderSimulateResponse.totalTaxVat = '10';
        List<ECOM_SimulateOrderWrapper.ProductList> prl = new List<ECOM_SimulateOrderWrapper.ProductList>();
        ECOM_SimulateOrderWrapper.ProductList product = new ECOM_SimulateOrderWrapper.ProductList();
        product.itemNumber = '1';
        product.partNumber = 'NEC100X050UC';
        product.shippingPoint = 'US36';
        product.linePrice = '10000';
        product.discount = 5;
        product.handling = 10; // Assuming handling should be an integer
        product.freight = 2;
        product.taxVat = '150.00';
        product.salesPrice = '16495.00';
        product.listPrice = '16495.00';
        prl.add(product);
        orderSimulateResponse.productList = prl;
        String couponCode = 'TESTCOUPON';

       Webcart result = ECOM_CartUtil.updateCouponAndDiscount(cartList[0].cartItems, couponCode, orderSimulateResponse);
       System.assertNotEquals(null, result, 'wrong output');

        Set<String> productIds = new Set<String>();
        for (CartItem item : cartList[0].cartItems) {
            productIds.add(item.Product2Id);
        }
            Map<String, Boolean> bogoApplicableProudctsMap = New Map<String, Boolean>();
            bogoApplicableProudctsMap.put(cartList[0].cartItems[0].id, true);
            Map<String, Object> requestData = new  Map<String, Object>();
            requestData.put('cart',cartList[0]);
            requestData.put('couponCode',couponCode);
            requestData.put('user',u);
            requestData.put('contact', con);
            requestData.put('bogoApplicableProudctsMap', bogoApplicableProudctsMap);
            requestData.put('productIds',productIds);
            //RWPS-3811-END
            ECOM_SimulateOrderWrapper.OrderRequest orderRequest = new ECOM_SimulateOrderWrapper.OrderRequest();//RWPS-2683
            ECOM_SimulateOrderWrapper.OrderRequest billToShipTo = ECOM_CartUtil.populateBillToShipTo(orderRequest, cart);//RWPS-2683
         
            //Updated generateOrderSimulationRequest method with User & Contact parameters. Ticket RWPS-415
            ECOM_SimulateOrderWrapper.OrderRequest response = ECOM_CartUtil.generateOrderSimulationRequest(requestData);//RWPS-3811
            ECOM_CartModel res = ECOM_CartUtil.populateCartDetails(cart.Id);
            cart.BillingCountryCode = null;
            update cart;
            //Updated generateOrderSimulationRequest method with User & Contact parameters. Ticket RWPS-415
            ECOM_SimulateOrderWrapper.OrderRequest response1 = ECOM_CartUtil.generateOrderSimulationRequest(requestData);//RWPS-3811
            System.AssertNotEquals(null,response,'Wrong Output 1 - testupdateCouponAndDiscount');
            System.AssertNotEquals(null,res,'Wrong Output 2 - testupdateCouponAndDiscount');
        }catch(Exception e){
    	}
    }
        
        @isTest
        public static void testgetCreditBlockExampleData()
        {
            User usr = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
            System.runAs(usr)
            {
                ECOM_SimulateOrderWrapper.OrderRequest response = new ECOM_SimulateOrderWrapper.OrderRequest();
                response = ECOM_CartUtil.getCreditBlockExampleData();
                
                System.AssertNotEquals(null,response,'Wrong Output');
            }
        }
        
        @isTest
        public static void testgenerateRequestMap()
        {
            String json=		'{'+
                '	"paymentTerms": "Due Upon Receipt",'+
                '	"incoTerms": "FOB Factory - Prepay &amp; Add",'+
                '	"incoCode": "F02 ",'+
                '	"currencyCode": "CAD",'+
                '	"shippingCost": "",'+
                '	"totalTaxVat": "",'+
                '	"totalPrice": "",'+
                '	"productList": [{'+
                '		"itemNumber": "1",'+
                '		"partNumber": "NEC100X050UC",'+
                '		"shippingPoint": "US36",'+
                '		"linePrice": "",'+
                '		"discount": null,'+
                '		"handling": 10.0,'+
                '		"freight": null,'+
                '		"taxVat": "150.00",'+
                '		"adjustedPrice": "16495.00", '+
                '		"itemDetail": [{'+
                '				"availableQty": "100.00",'+
                '				"availableDate": "20220911"'+
                '			},'+
                '			{'+
                '				"availableQty": "150.00",'+
                '				"availableDate": "20220911"'+
                '			}'+
                '		]'+
                '	}, {'+
                '		"itemNumber": "2",'+
                '		"partNumber": "6005182",'+
                '		"shippingPoint": "US36",'+
                '		"linePrice": "",'+
                '		"discount": null,'+
                '		"handling": 10.0,'+
                '		"freight": null,'+
                '		"taxVat": "150.00",'+
                '		"adjustedPrice": "16495.00",'+
                '		"itemDetail": [{'+
                '				"availableQty": "100.00",'+
                '				"availableDate": "20220911"'+
                '			},'+
                '			{'+
                '				"availableQty": "150.00",'+
                '				"availableDate": "20220911"'+
                '			}'+
                '		]'+
                '	}],'+
                ''+
                '	"Error": {'+
                '		"ErrorDetails": [{'+
                '			"errorMessage": "Ship-to party is not assigned to a sold-to party",'+
                '			"errorCode": ""'+
                '		}]'+
                '	}'+
                '}';
            User usr = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
            System.runAs(usr)
            {
                Map<String, String> result = ECOM_CartUtil.generateRequestMap(json);
                
                System.AssertNotEquals(null,result,'Wrong Output');
            }
        }
        
        @isTest
        public static void testgetPartNumbers()
        {
            List<String> result = new List<String>();
            ECOM_CartController.ECOM_ProductWrapper obj = new ECOM_CartController.ECOM_ProductWrapper();
            obj.partNumber = '1234567';
            obj.quantity  ='2';
            User usr = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
            System.runAs(usr)
            {
                List<ECOM_CartController.ECOM_ProductWrapper> productCodes =  new List<ECOM_CartController.ECOM_ProductWrapper>();
                productCodes.add(obj);
                
                result = ECOM_CartUtil.getPartNumbers(productCodes);
                
                System.AssertEquals('1234567',result[0]);
            }
        }
        @isTest
        public static void testpopulateDefaultCartDeliveryGroupMethod()
        {
            String cartDeliveryGroupId = [SELECT Id FROM CartDeliveryGroup ORDER BY CREATEDDATE DESC LIMIT 1].Id;
            String deliveryMethodId = [SELECT Id,CartDeliveryGroupId FROM CartItem ORDER BY CREATEDDATE DESC LIMIT 1].CartDeliveryGroupId;
            Webcart webCartObject= [SELECT Id,CurrencyIsoCode FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
            Decimal amount = 100;
            Test.startTest();
            User usr = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
            //System.runAs(usr)
            //{
                Id res = ECOM_CartUtil.populateDefaultCartDeliveryGroupMethod(cartDeliveryGroupId, deliveryMethodId, webCartObject, amount);
                Id newres = ECOM_CartUtil.populateDefaultCartDeliveryGroupMethod(cartDeliveryGroupId, res, webCartObject, amount);
                Id orderres = ECOM_CartUtil.getDefaultOrderDeliveryMethod();
                Id response = ECOM_CartUtil.addOrderDeliveryMethodToCartDeliveryGroup(webCartObject.Id, orderres);
                Account ac = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
                Webstore store = [SELECT Id FROM WebStore ORDER BY CREATEDDATE DESC LIMIT 1];
                Webcart newCart = [SELECT Id,BillingCountryCode,Default_Bill_to_ERP_Address__c,PoNumber,PaymentMethodId FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
                //insert newCart;
                //passing brand new cart without any association with DeliveryGroups
                //Id newRescart = ECOM_CartUtil.populateDefaultCartDeliveryGroupMethod(cartDeliveryGroupId, deliveryMethodId, newCart, amount);
                Id response1 = ECOM_CartUtil.addOrderDeliveryMethodToCartDeliveryGroup(newCart.Id, orderres);
                Test.stopTest();
                System.AssertNotEquals(null,res,'Wrong Output - populateDefaultCartDeliveryGroupMethod');
                System.AssertNotEquals(null,orderres,'Wrong Output - getDefaultOrderDeliveryMethod');
                System.assertNotEquals(null,response, 'Wrong Output - addOrderDeliveryMethodToCartDeliveryGroup');
            //}
        }
        
        @isTest
        private static void testValidateProductMaterialStatus(){
            ECOM_CartItemModel itm = new ECOM_CartItemModel();
            CartItem cartitm = [SELECT Id,CartId,product2Id FROM CartItem ORDER BY CREATEDDATE DESC LIMIT 1];
            itm.cartItemId = cartitm.Id;
            itm.cartItemName = 'TestCart';
            itm.productId = cartitm.Product2Id;
            itm.quantity = '1';
            itm.type = '';
            itm.salesPrice ='200';
            itm.listPrice ='200';
            itm.itemizedAdjustmentAmount= '10';
            itm.currencyIsoCode ='CAD';
            itm.totalListPrice = '200';
            itm.totalAmount= '200';
            itm.totalAdjustmentAmount = '10';
            itm.unitAdjustedPrice = '10';
            itm.totalTax = '10';
            itm.totalPrice ='200';
            itm.thumbnailImageURL ='testurl.in.inavalid';
            itm.unitAdjustmentAmount = '100';
            List<ECOM_CartItemModel> cartItems = new List<ECOM_CartItemModel>();
            cartItems.add(itm);
            
            List<CartItem> testres = ECOM_CartUtil.upsertCartItems(cartItems, cartitm.CartId);
            //RWPS-2683 - Start
            ECOM_CartModel cartModel = new ECOM_CartModel();
            cartModel.cartItems = cartItems;
            Account accountObj = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
            cartModel.accountId = accountObj.Id;
            cartModel.cartId = cartitm.Id;
            cartModel.currencyIsoCode = 'USD';
            cartModel.isSecondary = false;
            cartModel.grandTotalAmount = '0';
            cartModel.name= 'Cart';
            cartModel.status = 'Active';
            cartModel.taxType = 'NET';
            Product2 pr = [SELECT Id FROM Product2 ORDER BY CREATEDDATE DESC LIMIT 1];
            Product_Sales__c testdata = ECOM_TestUtil.createProduct_Sales(cartitm.Product2Id);
            insert testdata;
            User usr = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
            System.runAs(usr)
            {
                ECOM_CartModel res = ECOM_CartUtil.validateProductMaterialStatus(cartModel,'Order');
                //RWPS-2683 - End
                System.AssertNotEquals(null,res,'Wrong Output - testvalidateProductMaterialStatus');
            }
        }
        
        
        @isTest
        public static void testgetParentCartItems()
        {
            Webcart cart = [SELECT Id FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
            Map<String, CartItem> res = ECOM_CartUtil.getParentCartItems(cart.Id);
            
            System.assertNotEquals(null,res,'Wrong Output-testgetParentCartItems');
        }
        
        //test method for UpdateCartForAccountSwitch
        @isTest
        public static void testUpdateCartForAccountSwitch() {
            Contact testContact = [SELECT Id,FirstName,LastName,AccountId,ECOM_DefaultBillToAccount__c,ECOM_DefaultShipToAccount__c,ECOM_DefaultBillToCPA__c
                              FROM Contact ORDER BY CREATEDDATE DESC LIMIT 1];
            
            WebCart testCart = [SELECT Id FROM WebCart ORDER BY CREATEDDATE DESC LIMIT 1];
            User u= [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
            Test.startTest();
            System.runAs(u)
            {
                Map<String, Object> responseMap = ECOM_CartUtil.updateCartForAccountSwitch(testContact.Id);
                List<WebCart> updatedCarts = [SELECT Id, AccountId, ECOM_BillToAccount__c, ECOM_ShipToAccount__c, ECOM_DefaultBillToCPA__c, ECOM_DefaultShipToCPA__c FROM WebCart WHERE Id = :testCart.Id];
                // Assertions
                System.assertEquals(true, responseMap.get('Success'), 'Expected Success');
                System.assertEquals(null, responseMap.get('ErrorMessage'), 'Expected no error message');
                
                //null param
                Map<String, Object> nullResponseMap = ECOM_CartUtil.updateCartForAccountSwitch(null);
                System.assertEquals(false, nullResponseMap.get('Success'), 'Expected Success');
            }
            Test.stopTest();
            
            
        }
        @isTest
        static void test_ParseCartItems1() {
            // Create test data for ConnectApi.CartItemCollection
            ConnectApi.CartItemCollection testCartCollection = ECOM_TestUtil.testConnectApiCartItemCollection();
            List<ConnectApi.CartItemResult> cartItemResults = new List<ConnectApi.CartItemResult>();
            
            // Add some test cart items to the collection
            ConnectApi.CartItem testCartItem = new ConnectApi.CartItem();
            testCartItem.productId = 'Product1';
            testCartItem.quantity = '2';
            testCartItem.cartItemId = '123';
            testCartItem.name = 'ItemName1';
            //testCartItem.productDetails.thumbnailImage.url ='testurl.in.inavalid';
            ConnectApi.CartItemResult testCartItemResult = new ConnectApi.CartItemResult();
            testCartItemResult.cartItem = testCartItem;
            cartItemResults.add(testCartItemResult);
            testCartCollection.cartItems = cartItemResults;
            Test.startTest();
            List<ECOM_CartItemModel> resultItems = ECOM_CartUtil.parseCartItems(testCartCollection);
            ConnectApi.CartItem cartItemData = ECOM_TestUtil.getCartItemData();
            ECOM_CartItemModel resp = ECOM_CartUtil.parseCartItem(cartItemData);
            System.assertEquals(1, resultItems.size()); // Check the size of the resulting list
            ECOM_CartItemModel firstResultItem = resultItems[0];
            System.assertEquals('Product1', firstResultItem.productId);
            System.assertEquals('2', firstResultItem.quantity);
            Test.stopTest();
        }
        
        @isTest
        static void testGetWebCartForPunchoutUser(){
            WebStore webStr = [SELECT Id FROM WebStore LIMIT 1];
            Contact con = [SELECT Id,OwnerId FROM Contact LIMIT 1];
            Product2 product = [SELECT Id,ProductCode FROM Product2 LIMIT 1];
            Account acc = [SELECT Id,IsBuyer FROM Account WHERE Name='TestClass Account' LIMIT 1];
            system.debug('Account: '+acc);
            Order ord = [SELECT Id FROM Order LIMIT 1];
            Contact custcon = new Contact(Email='test@yopmail.com',LastName='ECOM',AccountId=acc.Id,ECOM_CountryProvided__c ='USA');
            insert custcon;
            User custUser = ECOM_TestUtil.createPortalUser(custcon);
            system.debug('User soql: '+[SELECT Id,Name,IsPortalEnabled FROM User WHERE Email LIKE '%test123@noemail.com' LIMIT 1]);
            List<PermissionSet> ps1 = [SELECT Id FROM PermissionSet WHERE Name = 'Buyer'];
            if(ps1 != NULL && ps1.size()>0){
                insert new PermissionSetAssignment(AssigneeId = custUser.Id, PermissionSetId = ps1[0].Id);
            }
            WebCart cart;
            System.runAs(custUser){
                cart = ECOM_TestUtil.createCart(acc,webStr,custUser);
                cart.ECOM_Is_Punchout_Cart__c = true;
                insert cart;
                
                Test.startTest();
                cart = ECOM_CartUtil.getWebCartForPunchoutUser(custUser);
                Test.stopTest();
                Assert.isNotNull(cart, 'Expected a non-null cart value');
            }
            
        }
        
        @isTest
        static void testGetWebCartForPunchoutUserNewCartCreation(){
            WebStore webStr = [SELECT Id FROM WebStore LIMIT 1];
            Contact con = [SELECT Id,OwnerId FROM Contact LIMIT 1];
            Product2 product = [SELECT Id,ProductCode FROM Product2 LIMIT 1];
            Account acc = [SELECT Id,IsBuyer FROM Account WHERE Name='TestClass Account' LIMIT 1];
            system.debug('Account: '+acc);
            Order ord = [SELECT Id FROM Order LIMIT 1];
            Contact custcon = new Contact(Email='test@yopmail.com',LastName='ECOM',AccountId=acc.Id,ECOM_CountryProvided__c ='USA');
            insert custcon;
            User custUser = ECOM_TestUtil.createPortalUser(custcon);
            system.debug('User soql: '+[SELECT Id,Name,IsPortalEnabled FROM User WHERE Email LIKE '%test123@noemail.com' LIMIT 1]);
            List<PermissionSet> ps1 = [SELECT Id FROM PermissionSet WHERE Name = 'Buyer'];
            if(ps1 != NULL && ps1.size()>0){
                insert new PermissionSetAssignment(AssigneeId = custUser.Id, PermissionSetId = ps1[0].Id);
            }
            WebCart cart;
            System.runAs(custUser){
                Test.startTest();
                cart = ECOM_CartUtil.getWebCartForPunchoutUser(custUser);
                Test.stopTest();
            }
        }
        
        @isTest
        static void testUpdateCartWithPOSRValues(){
            Account newAccount = ECOM_TestUtil.createAccount();
            ECOM_PunchoutWrapper.PunchoutServiceRequest request = ECOM_TestUtil.createPunchoutServiceRequest();
            
            User userRecord = new User();
            ERP_AddressModel newModel = new ERP_AddressModel();
            
            Test.startTest();
            ECOM_CartUtil.updateCartWithPOSRValues(request, userRecord, newModel);
            Test.stopTest();
            
        }
        
        @isTest
        static void testCheckIfPunchoutCart(){
            Test.startTest();
            ECOM_CartUtil.checkIfPunchoutCart(null, new ECOM_CartModel());
            Test.stopTest();
        }
        
        @isTest
        static void testGetPoomModel(){
            ECOM_POOMModel poomModel = new ECOM_POOMModel();
            
            ERP_AddressModel addressModel = new ERP_AddressModel();
            addressModel.po_PunchoutResponseFormat = 'cXML';
            addressModel.po_Processors = 'test';
            addressModel.po_UnitOfMeasure = 'EA';
            
            List<WebCart> cartList = [SELECT Id FROM WebCart ORDER BY CreatedDate DESC LIMIT 1];
            if(null != cartList && !cartList.isEmpty()){
                String cartId = cartList[0].Id;
                List<WebCart> carts = ECOM_CartRepo.getPunchoutCartandCartItemsById(cartId);
                
                Test.startTest();
                poomModel = ECOM_CartUtil.getPoomModel(carts[0], addressModel);
                Test.stopTest();
            }
        }
        
        
        @isTest
        static void testCreateNewPunchoutCart(){
            Account newAccount = ECOM_TestUtil.createAccount();
            Contact newContact = ECOM_TestUtil.createContact(newAccount);
            User newUser = ECOM_TestUtil.createUser(newContact, newAccount.Id);
            Test.startTest();
            ECOM_CartUtil.createNewPunchoutCart(newAccount.Id, newUser.Id);
            Test.stopTest();
        }
        
        @isTest
        static void testUpdatePunchoutData(){
            ECOM_CartFlowWrapper wrapper = new ECOM_CartFlowWrapper();
            wrapper.accountName = 'Test Account Name';
            wrapper.accountNumber = '11223344';
            wrapper.userName = 'Test User Name';
            wrapper.operationType = System.Label.ECOM_CartOperation_GetCartItems;
            wrapper.isPunchoutUser = true;
            wrapper.cartModel = new ECOM_CartModel();
            
            Test.startTest();
            ECOM_CartUtil.updatePunchoutData(wrapper,wrapper);
            Test.stopTest();
        }
        
        @isTest
        static void getPopulateCartDetails(){
            List<WebCart> cartList = [SELECT Id FROM WebCart ORDER BY CreatedDate DESC LIMIT 1];
            if(null != cartList && !cartList.isEmpty()){
                String cartId = cartList[0].Id;
                List<WebCart> carts = ECOM_CartRepo.getPunchoutCartandCartItemsById(cartId);
                
                Test.startTest();
                ECOM_CartUtil.populateCartDetails(carts[0].Id);
                ECOM_CartUtil.populateCartDetailsWithoutCartItem(carts[0].Id);
                Test.stopTest();
            }
        }
        
        
        @isTest
        static void testRepoMethods(){
            Test.startTest();
            ECOM_CartRepo.getPayerTargetAccountNumber('');
            ECOM_CartRepo.getShipToSourceAccountNumber('');
            ECOM_CartRepo.getCartDeliveryGroupByCart(null);
            ECOM_Abandoned_Cart_Notification__mdt cartNotification = new ECOM_Abandoned_Cart_Notification__mdt();
            cartNotification.Cart_Price_Bucket_Min__c = 0.0;cartNotification.Cart_Price_Bucket_Max__c = 0.0;
            ECOM_CartRepo.getCartsBasedOnEmailNotificationForLeftOverCountries(cartNotification, DateTime.now(), DateTime.now(), new List<String>(), new List<String>());
            ECOM_CartRepo.getCartTaxRecordsPerCart('');
            ECOM_CartRepo.getPrimayActivePunchoutCartsForOwnerId('');
            //ECOM_CartRepo.getShippingTime('');
            //ECOM_CartRepo.getCartCheckoutSession('');
            //ECOM_CartRepo.getCartsBasedOnEmailNotificationForSpecificCountry(cartNotification, DateTime.now(), DateTime.now(), new List<String>());
            ECOM_CartRepo.getCartDeliveryGroupMethodById(null);
            ECOM_CartRepo.getCartDeliveryGroupById(null);
            ECOM_CartRepo.getCartItemsShippingDates(null);
            ECOM_CartRepo.checkRADIdentifierAccount('');
            ECOM_CartRepo.getCartItemsByProductandCartId('','');
            Test.stopTest();
        }
        
        @isTest
        static void testOrderTypeMethod(){
            Test.startTest();
            String ordertype1 =ECOM_CartUtil.getOrderType(false, '', ECOM_Constant.ORDER_SIMULATE, 'US10');
            String ordertype2 =ECOM_CartUtil.getOrderType(true, '', ECOM_Constant.ORDER_SIMULATE, 'US10');
            String ordertype3 =ECOM_CartUtil.getOrderType(true, ECOM_Constant.PAYMENT_TYPE_CREDITCARD, ECOM_Constant.ORDER_CREATE, 'US10');
            String ordertype4 =ECOM_CartUtil.getOrderType(true, ECOM_Constant.PAYMENT_TYPE_PO, ECOM_Constant.ORDER_CREATE, 'US10');
            
            System.assertEquals('ZWEB',ordertype1);
            System.assertEquals('ZGNA',ordertype2);
            System.assertEquals('ZGNC',ordertype3);
            System.assertEquals('ZGNA',ordertype4);
            Test.stopTest();
        }
        
        //RWPS-2683 - Start
        @isTest
        private static void testValidateProductMaterialException(){
            ECOM_CartItemModel itm = new ECOM_CartItemModel();
            CartItem cartitm = [SELECT Id,CartId,product2Id FROM CartItem ORDER BY CREATEDDATE DESC LIMIT 1];
            itm.cartItemId = cartitm.Id;
            itm.cartItemName = 'TestCart';
            itm.productId = cartitm.Product2Id;
            itm.quantity = '1';
            itm.type = '';
            itm.salesPrice ='200';
            itm.listPrice ='200';
            itm.itemizedAdjustmentAmount= '10';
            itm.currencyIsoCode ='CAD';
            itm.totalListPrice = '200';
            itm.totalAmount= '200';
            itm.totalAdjustmentAmount = '10';
            itm.unitAdjustedPrice = '10';
            itm.totalTax = '10';
            itm.totalPrice ='200';
            itm.thumbnailImageURL ='testurl.in.inavalid';
            itm.unitAdjustmentAmount = '100';
            List<ECOM_CartItemModel> cartItems = new List<ECOM_CartItemModel>();
            cartItems.add(itm);
            
            List<CartItem> testres = ECOM_CartUtil.upsertCartItems(cartItems, cartitm.CartId);
            
            ECOM_CartModel cartModel = new ECOM_CartModel();
            cartModel.cartItems = cartItems;
            Account accountObj = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
            cartModel.accountId = accountObj.Id;
            cartModel.cartId = cartitm.Id;
            cartModel.currencyIsoCode = 'USD';
            cartModel.isSecondary = false;
            cartModel.grandTotalAmount = '0';
            cartModel.name= 'Cart';
            cartModel.status = 'Active';
            cartModel.taxType = 'NET';
            cartModel.isPunchoutCart = false;
            Product2 pr = [SELECT Id FROM Product2 ORDER BY CREATEDDATE DESC LIMIT 1];
            Product_Sales__c testdata = ECOM_TestUtil.createProduct_Sales(cartitm.Product2Id);
            insert testdata;
            User usr = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
            System.runAs(usr)
            {
                ECOM_CartModel res = ECOM_CartUtil.validateProductMaterialStatus(null,'test');
            }
        }
        //RWPS-2683 - End
        
        // RWPS-2858 start
        /**
         * @description Test case Addresses for unmapped user
         * @author Abhishek Joshi
         * @date 02-04-2025
         */
        @isTest
        static void testGetAddressesForCalloutUnmapped() {
            User u = [SELECT Id, ContactId, Contact.ECOM_CountryProvided__c, Contact.Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
            Contact c = u.Contact;
            c.Default_Ship_to_ERP_Address__c = null;
            update c;
            
            ECOM_DummyAccountCountryMapping__mdt defaultmdt;
            defaultmdt = ECOM_CustomMetadataService.fetchDummyAccountCountryMappingData(ECOM_Util.getCountryFromUser(u));
            
            System.runAs(u) {
                Test.startTest();
                
                Map<String,String> addressMap = ECOM_CartUtil.getAddressesForCallout();
                System.assertEquals(defaultmdt.Default_Bill_To__c, addressMap.get('billTo'), 'Test bill to matches the default dummy bill to');
                
                Test.stopTest();
            }
        }
        // RWPS-2858 end
        
        @isTest
        static void testPopulateCartDetailsWithCartItems() {
            List<WebCart> cartList = [SELECT Id FROM WebCart ORDER BY CreatedDate DESC LIMIT 1];
            if(null != cartList && !cartList.isEmpty()){
                String cartId = cartList[0].Id;
                List<WebCart> carts = ECOM_CartRepo.getPunchoutCartandCartItemsById(cartId);
                
                Test.startTest();
                ECOM_CartUtil.populateCartDetailsWithCartItems(carts[0].Id);
                Test.stopTest();
            }
        }
        
        @isTest
        static void testIsLargePackItemExist() {
            List<WebCart> cartList = [SELECT Id FROM WebCart ORDER BY CreatedDate DESC LIMIT 1];
            if(null != cartList && !cartList.isEmpty()){
                String cartId = cartList[0].Id;
                List<WebCart> carts = ECOM_CartRepo.getPunchoutCartandCartItemsById(cartId);
                
                Test.startTest();
                ECOM_CartUtil.isLargePackItemExist(carts[0].Id);
                Test.stopTest();
            }
        }
        
        //RWPS-1882 start
        @isTest
        static void testIsInvoiceEmailExistCase1() {
            User u = [SELECT Id, ContactId, Contact.ECOM_CountryProvided__c, Contact.Default_Bill_to_ERP_Address__r.ECOM_Email_to_invoice__c, Contact.Default_Bill_to_ERP_Address__r.ECOM_E_Invoice_Cust_Id__c  FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
            Contact c = u.Contact;
            ERP_Address__c testAdd = new ERP_Address__c();
            testAdd.ECOM_Email_to_invoice__c = 'abc@example.com';
            insert testAdd;
            c.Default_Bill_to_ERP_Address__c = testAdd.Id;
            update c;
            System.runAs(u) {
                Test.startTest();
                ECOM_CartUtil.isInvoiceEmailExist();
                Test.stopTest();
            }
        }
        
        @isTest
        static void testIsInvoiceEmailExistCase2() {
            User u = [SELECT Id, ContactId, Contact.ECOM_CountryProvided__c, Contact.Default_Bill_to_ERP_Address__r.ECOM_Email_to_invoice__c, Contact.Default_Bill_to_ERP_Address__r.ECOM_E_Invoice_Cust_Id__c  FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
            System.runAs(u) {
                Test.startTest();
                ECOM_CartUtil.isInvoiceEmailExist();
                Test.stopTest();
            }
        }
        //RWPS-1882 end
        
        //RWPS-2786
    @isTest
    static void testGetInActiveProducts() {
        List<WebCart> cartList = [SELECT Id, ownerId, AccountId FROM WebCart ORDER BY CreatedDate DESC LIMIT 1];
        if(null != cartList && !cartList.isEmpty()){
            Set<String> productIdSet = new Set<String>();
           for(CartItem cItem:cartList[0].cartItems)
            {
                if(String.isNotBlank(cItem.Product2.Part_Number__c))
                {
                    productIdSet.add(cItem.product2Id);
                }
            }        
            Test.startTest();
            ECOM_CartUtil.getInActiveProducts(cartList[0], productIdSet);
            Ecom_CartRepo.isFirstTimePromoActive();
            Ecom_CartRepo.getAccountCountryCode(cartList[0].AccountId);
            Test.stopTest();
        }
    }
        //RWPS-3811
        @isTest
        static void testGetCartsBasedOnOwnerAndAccount() {
            User u = [SELECT Id, ContactId, Contact.ECOM_CountryProvided__c, Contact.Default_Bill_to_ERP_Address__r.ECOM_Email_to_invoice__c, Contact.Default_Bill_to_ERP_Address__r.ECOM_E_Invoice_Cust_Id__c  FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
            WebCart cart = [SELECT Id, ownerId, AccountId FROM WebCart ORDER BY CreatedDate DESC LIMIT 1];
            CartDeliveryGroupMethod cartDG = [SELECT Id, WebCartId from CartDeliveryGroupMethod ORDER BY CreatedDate DESC LIMIT 1];
            System.runAs(u) {
                Test.startTest();
                ECOM_CartRepo.getCartsBasedOnOwnerAndAccount(cart.ownerId,cart.AccountId);
                ECOM_CartRepo.getCartDeliveryGroupMethodByCart(cartDG.WebCartId);
                Test.stopTest();
            }
        }
        //RWPS-4202
        @isTest
        static void testGetCartItemDetailsMap() {
            //FETCH test data
            List<CartItem> testCartItems = [SELECT Id,CartId,CartDeliveryGroupId,Type,ECOM_Parent__c,Product2.Id,Product2.Part_Number__c,ECOM_Parent_Item__c
                                        FROM CartItem ORDER BY CREATEDDATE DESC LIMIT 1];
            User u = [SELECT Id, ContactId, Contact.ECOM_CountryProvided__c, Contact.Default_Bill_to_ERP_Address__r.ECOM_Email_to_invoice__c, Contact.Default_Bill_to_ERP_Address__r.ECOM_E_Invoice_Cust_Id__c  FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
            System.runAs(u) {
                Test.startTest();
                ECOM_CartUtil.getCartItemDetailsMap(testCartItems);
                Test.stopTest();
            }
        }
        
}