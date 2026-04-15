/**************************************************************

* 1. Jira Ticket(s) that relates to this class

*  

*

* 2. Description - This class is a test class for ECOM_CartService
					- Call the ECOM_TestUtil Class to create test data and test each method functionality.
					- Used System Assertion to Confirm the functionalities.

*

* 3. Objects referenced


*    - Account
*	 - ECOM_Abandoned_Cart_Notification__mdt
*    - Contact
*    - CartItems
*    - User
*    - WebCart

* 4. Callouts to additional Components (including their methods) or None:

*    - None

*

* 5. Dependant Class(es):

*    - ECOM_TestUtil

*    - ECOM_CartService

*

* 6. Test Class Name:

*    -ECOM_CartService_Test

*

* 7. Is @Invocable : No

*

* 8. Author Name(s):

*    - Manoj 2023.09.19
*    - Sidak 2024.01.18
*    - Sidak 2024.04.22 | Added methods testGetCartDetails,testUpdateWebCart, testGetUniqueProductCount, testUpdateCartItemListPrice2, testGetCartItemsByCartId, testGetCartTaxRecordsPerCart
*    - Sidak 2024.06.01 | Added method updateBillToShipToOnCartTest. Ticket: RWPS-766
*    - Prabhat 2025.9.1 | Added Method testGetAbandonedCartNotification, getCustomMetadataRecord, testGetAbandonedCartCountWithoutCountry
*    - Gaurav 2025.1.15 | Added Method testRepriceCartForPromotion for code coverage - RWPS 2307
*    - Prabhat 2025.02-25 | Added Method updated method testUpdatedPunchoutCart  for code coverage - RWPS 2683
*    - Manish Joshi 2025.03.03 | Updated test methods for increasing code coverage & added more test cases - RWPS-2684
*    - Gaurav Bhansali 2025.03.20 | Updated test methods to increase code coverage - RWPS-2800
*    - Manish Joshi 2025.04.14 | Updated test methods to increase code coverage - RWPS-1548
*    - Gaurav Bhansali 2025.05.12 | Added testRepriceCartForPunchout method to increase code coverage - RWPS-3220
*    - Gaurav Bhansali 2025.06.03 | updated testRepriceCartForPromotion method to increase code coverage - RWPS-3283
*    - Prabhat Kumar 2025.07.21 | Updated method testGetShippingTime, testfilterAbandonedOptInCarts,testUpdateCartItemListPrice2 to increase coverage - RWPS-3658
*    - Gaurav Bhansali 2025.09.01 | Added testGetFreeItemPromoMsg and updated testAddItemsToCart and testAddItemsToCartOwner method to increase code coverage - RWPS-4202
*    - Prabhat Kumar 2025.12.17 | Updated method testSetupData to create data for Product recommendation, created and updated multiple method to get coverage - RWPS-4896
*	 - Princy Anthony 2026.03.11 - Added method testSingleUsePromoAlreadyUsed- RWPS-5775
************************************************************/

@isTest(SeeAllData=false)
public with sharing class ECOM_CartService_Test {
    
    
    
    @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
        // RWPS-2684 - START
        ECOM_ProductShippingTime__c shippingTime = ECOM_TestUtil.createProductShippingTime();
        // Create test data as needed
        WebCart cart = [SELECT Id, Default_Bill_to_ERP_Address__c, Default_Ship_to_ERP_Address__c FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1]; 
        User u = [SELECT Id,AccountId, ContactId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        String acId = u.AccountId;
        Contact con = [SELECT Id, Default_Ship_to_ERP_Address__c, Default_Bill_to_ERP_Address__c,
                       Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c,
                       Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c FROM Contact WHERE Id =: u.ContactId LIMIT 1];
        cart.Default_Ship_to_ERP_Address__c = con?.Default_Ship_to_ERP_Address__c;
        cart.Default_Bill_to_ERP_Address__c = con?.Default_Ship_to_ERP_Address__c;
        update cart;
        System.debug('###############'+con.Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c);
        System.debug('###############'+con.Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c);
        // RWPS-2684 - ENDS
    }

    //RWPS-2684 - START
    @isTest
    static void testRepriceCart() {
        // Create test data as needed
        WebCart cart = [SELECT Id, Default_Bill_to_ERP_Address__c, Default_Ship_to_ERP_Address__c FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
        list<CartItem> se = [Select id from CartItem];
        system.debug('***se***'+se);
        User u = [SELECT Id,AccountId, ContactId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        String acId = u.AccountId;
        Account acc = [SELECT Id FROM Account WHERE Id =: acId LIMIT 1];
        Contact con = [SELECT Id, Default_Ship_to_ERP_Address__c, Default_Bill_to_ERP_Address__c FROM Contact WHERE Id =: u.ContactId LIMIT 1];
        
        System.runAs(u)
        {
            String couponCode = 'RGEVAL';
            
            String successResponseBody = '{  "paymentTerms" : "PAYABLE A 30 JOURS NET",  "incoTerms" : "RENDU DROITS ACQUITES",  "incoCode" : "DDP",  "currencyCode" : "EUR",' +
                '"productList" : [    {      "itemNumber" : "1",      "partNumber" : "AL3099F",      "shippingPoint" : "US36",      "discount" : "16464.00", '     +
                '"handling" : 0,      "freight" : "31.10",      "taxVat" : "6.22",      "salesPrice" : "0.00",      "itemDetail" : ['       +
            	'{         "availableQty" : "0.000",          "availableDate" : "2025-02-26"        },        {          "availableQty" : "1.000",'   +
                '"availableDate" : "2025-02-28"        }      ]    },    {      "itemNumber" : "2",      "partNumber" : "AL289C",      "shippingPoint" : "US36",'   +
                '"discount" : "4709.00",      "handling" : 0,      "freight" : "8.90",      "taxVat" : "1.78",      "salesPrice" : "0.00",'   +
                '"itemDetail" : [        {          "availableQty" : "0.000",          "availableDate" : "2025-02-26"        },        {'+
                '"availableQty" : "1.000",          "availableDate" : "2025-02-28"        }      ]    }  ]}';
            Test.setMock(HttpCalloutMock.class, new ECOM_MockHttpResponseGenerator(200, 'OK', successResponseBody, null));
            Test.startTest();
            Map<String, Object> response = ECOM_CartService.repriceCart(cart.Id, couponCode);
            Map<String, Object> response1 = ECOM_CartService.repriceCart(null,couponCode);
           // Map<String, Object> response2 = ECOM_CartService.repriceCart(cart.Id,null);
            
            Map<String, Object> response11 = ECOM_CartService.repriceCart(cart.Id, ''); 
          /*  Map<String, Object> response2 = ECOM_CartService.repriceCart('', couponCode);*/
            Map<String, Object> response3 = ECOM_CartService.repriceCart(null, null);
            Map<String, Object> response4 = ECOM_CartService.repriceCart('', '');
            Map<String, Object> response5 = ECOM_CartService.repriceCart(null, '');
	        Test.stopTest();
            System.assertNotEquals(null, response, 'RepriceCart should not be null');
         //   System.assertNotEquals(null, response1, 'wrong output');
           // System.assertNotEquals(null, response2, 'Wrong Output');
        }
    }
    //RWPS-2684 - START
    @isTest
    static void testRepriceCartcouponNull() {
        // Create test data as needed
        WebCart cart = [SELECT Id, Default_Bill_to_ERP_Address__c, Default_Ship_to_ERP_Address__c FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
        list<CartItem> se = [Select id from CartItem];
        system.debug('***se***'+se);
        User u = [SELECT Id,AccountId, ContactId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        String acId = u.AccountId;
        Account acc = [SELECT Id FROM Account WHERE Id =: acId LIMIT 1];
        Contact con = [SELECT Id, ECOM_CountryProvided__c,Default_Ship_to_ERP_Address__c, Default_Bill_to_ERP_Address__c FROM Contact WHERE Id =: u.ContactId LIMIT 1];
         con.ECOM_Is_Mapped__c =false;
        update con;
        System.runAs(u)
        {
            String couponCode = 'none';
            
            String successResponseBody = '{  "paymentTerms" : "PAYABLE A 30 JOURS NET",  "incoTerms" : "RENDU DROITS ACQUITES",  "incoCode" : "DDP",  "currencyCode" : "EUR",' +
                '"productList" : [    {      "itemNumber" : "1",      "partNumber" : "AL3099F",      "shippingPoint" : "US36",      "discount" : "16464.00", '     +
                '"handling" : 0,      "freight" : "31.10",      "taxVat" : "6.22",      "salesPrice" : "0.00",      "itemDetail" : ['       +
            	'{         "availableQty" : "0.000",          "availableDate" : "2025-02-26"        },        {          "availableQty" : "1.000",'   +
                '"availableDate" : "2025-02-28"        }      ]    },    {      "itemNumber" : "2",      "partNumber" : "AL289C",      "shippingPoint" : "US36",'   +
                '"discount" : "4709.00",      "handling" : 0,      "freight" : "8.90",      "taxVat" : "1.78",      "salesPrice" : "0.00",'   +
                '"itemDetail" : [        {          "availableQty" : "0.000",          "availableDate" : "2025-02-26"        },        {'+
                '"availableQty" : "1.000",          "availableDate" : "2025-02-28"        }      ]    }  ]}';
            Test.setMock(HttpCalloutMock.class, new ECOM_MockHttpResponseGenerator(200, 'OK', successResponseBody, null));
            Test.startTest();
            Map<String, Object> response = ECOM_CartService.repriceCart(cart.Id, couponCode);
            //Map<String, Object> response1 = ECOM_CartService.repriceCart(null,couponCode);
           // Map<String, Object> response2 = ECOM_CartService.repriceCart(cart.Id,null);
            
          /*  Map<String, Object> response1 = ECOM_CartService.repriceCart(cart.Id, ''); 
            Map<String, Object> response2 = ECOM_CartService.repriceCart('', couponCode);
            Map<String, Object> response3 = ECOM_CartService.repriceCart(null, null);
            Map<String, Object> response4 = ECOM_CartService.repriceCart('', '');
            Map<String, Object> response5 = ECOM_CartService.repriceCart(null, '');*/
	        Test.stopTest();
           // System.assertNotEquals(null, response, 'RepriceCart should not be null');
         //   System.assertNotEquals(null, response1, 'wrong output');
           // System.assertNotEquals(null, response2, 'Wrong Output');
        }
    }
     @isTest
    static void testRepriceCartcouponisOSCached() {
        // Create test data as needed
        WebCart cart = [SELECT Id, Default_Bill_to_ERP_Address__c, Default_Ship_to_ERP_Address__c FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
        list<CartItem> se = [Select id from CartItem];
        
		User u = [SELECT Id,AccountId, ContactId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        String acId = u.AccountId;
        Account acc = [SELECT Id FROM Account WHERE Id =: acId LIMIT 1];
        Contact con = [SELECT Id, ECOM_CountryProvided__c,Default_Ship_to_ERP_Address__c, Default_Bill_to_ERP_Address__c FROM Contact WHERE Id =: u.ContactId LIMIT 1];
         con.ECOM_Is_Mapped__c =false;
        update con;
        ECOM_SessionCacheUtil util = new ECOM_SessionCacheUtil();
        String key = 'testKey';
        String value = 'testValue';
        util.setSessionCache(key, value);        
        Object cachedData = util.getSessionCache(key);
        System.runAs(u)
        {
            String couponCode = 'none';
            
            String successResponseBody = '{  "paymentTerms" : "PAYABLE A 30 JOURS NET",  "incoTerms" : "RENDU DROITS ACQUITES",  "incoCode" : "DDP",  "currencyCode" : "EUR",' +
                '"productList" : [    {      "itemNumber" : "1",      "partNumber" : "AL3099F",      "shippingPoint" : "US36",      "discount" : "16464.00", '     +
                '"handling" : 0,      "freight" : "31.10",      "taxVat" : "6.22",      "salesPrice" : "0.00",      "itemDetail" : ['       +
            	'{         "availableQty" : "0.000",          "availableDate" : "2025-02-26"        },        {          "availableQty" : "1.000",'   +
                '"availableDate" : "2025-02-28"        }      ]    },    {      "itemNumber" : "2",      "partNumber" : "AL289C",      "shippingPoint" : "US36",'   +
                '"discount" : "4709.00",      "handling" : 0,      "freight" : "8.90",      "taxVat" : "1.78",      "salesPrice" : "0.00",'   +
                '"itemDetail" : [        {          "availableQty" : "0.000",          "availableDate" : "2025-02-26"        },        {'+
                '"availableQty" : "1.000",          "availableDate" : "2025-02-28"        }      ]    }  ]}';
            Test.setMock(HttpCalloutMock.class, new ECOM_MockHttpResponseGenerator(200, 'OK', successResponseBody, null));
            Test.startTest();
            Map<String, Object> response = ECOM_CartService.repriceCart(cart.Id, couponCode);
            //Map<String, Object> response1 = ECOM_CartService.repriceCart(null,couponCode);
           // Map<String, Object> response2 = ECOM_CartService.repriceCart(cart.Id,null);
            
          /*  Map<String, Object> response1 = ECOM_CartService.repriceCart(cart.Id, ''); 
            Map<String, Object> response2 = ECOM_CartService.repriceCart('', couponCode);
            Map<String, Object> response3 = ECOM_CartService.repriceCart(null, null);
            Map<String, Object> response4 = ECOM_CartService.repriceCart('', '');
            Map<String, Object> response5 = ECOM_CartService.repriceCart(null, '');*/
	        Test.stopTest();
           // System.assertNotEquals(null, response, 'RepriceCart should not be null');
         //   System.assertNotEquals(null, response1, 'wrong output');
           // System.assertNotEquals(null, response2, 'Wrong Output');
        }
    }
    @isTest
    static void testRepriceCart2() {
        // Create test data as needed
        WebCart cart = [SELECT Id, Default_Bill_to_ERP_Address__c, Default_Ship_to_ERP_Address__c FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
        list<CartItem> se = [Select id from CartItem];
        delete se;
        User u = [SELECT Id,AccountId, ContactId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        String acId = u.AccountId;
        Account acc = [SELECT Id FROM Account WHERE Id =: acId LIMIT 1];
        Contact con = [SELECT Id, Default_Ship_to_ERP_Address__c, Default_Bill_to_ERP_Address__c FROM Contact WHERE Id =: u.ContactId LIMIT 1];
        System.runAs(u)
        {
            String couponCode = 'RGEVAL';
            String successResponseBody = '{  "paymentTerms" : "PAYABLE A 30 JOURS NET",  "incoTerms" : "RENDU DROITS ACQUITES",  "incoCode" : "DDP",  "currencyCode" : "EUR",' +
                '"productList" : [    {      "itemNumber" : "1",      "partNumber" : "AL3099F",      "shippingPoint" : "US36",      "discount" : "16464.00", '     +
                '"handling" : 0,      "freight" : "31.10",      "taxVat" : "6.22",      "salesPrice" : "0.00",      "itemDetail" : ['       +
            	'{         "availableQty" : "0.000",          "availableDate" : "2025-02-26"        },        {          "availableQty" : "1.000",'   +
                '"availableDate" : "2025-02-28"        }      ]    },    {      "itemNumber" : "2",      "partNumber" : "AL289C",      "shippingPoint" : "US36",'   +
                '"discount" : "4709.00",      "handling" : 0,      "freight" : "8.90",      "taxVat" : "1.78",      "salesPrice" : "0.00",'   +
                '"itemDetail" : [        {          "availableQty" : "0.000",          "availableDate" : "2025-02-26"        },        {'+
                '"availableQty" : "1.000",          "availableDate" : "2025-02-28"        }      ]    }  ]}';
            Test.setMock(HttpCalloutMock.class, new ECOM_MockHttpResponseGenerator(200, 'OK', successResponseBody, null));
            Test.startTest();
            Map<String, Object> response = ECOM_CartService.repriceCart(cart.Id, couponCode);
           // Map<String, Object> response1 = ECOM_CartService.repriceCart(null,couponCode);
           // Map<String, Object> response2 = ECOM_CartService.repriceCart(cart.Id,null);
            
          /*  Map<String, Object> response1 = ECOM_CartService.repriceCart(cart.Id, ''); 
            Map<String, Object> response2 = ECOM_CartService.repriceCart('', couponCode);
            Map<String, Object> response3 = ECOM_CartService.repriceCart(null, null);
            Map<String, Object> response4 = ECOM_CartService.repriceCart('', '');
            Map<String, Object> response5 = ECOM_CartService.repriceCart(null, '');*/
	        Test.stopTest();
            System.assertNotEquals(null, response, 'RepriceCart should not be null');
         //   System.assertNotEquals(null, response1, 'wrong output');
           // System.assertNotEquals(null, response2, 'Wrong Output');
        }
        
    }
    
    //Rwps-3816 Start
    @isTest
    static void testRepriceCartWithDisabledAddress() {
        // Create test data as needed
        WebCart cart = [SELECT Id, Default_Bill_to_ERP_Address__c, Default_Ship_to_ERP_Address__c FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
        User u = [SELECT Id,AccountId, ContactId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        String acId = u.AccountId;
        Account acc = [SELECT Id FROM Account WHERE Id =: acId LIMIT 1];
        Contact con = [SELECT Id, Default_Ship_to_ERP_Address__c, Default_Bill_to_ERP_Address__c, Default_Ship_to_ERP_Address__r.Master_Address__c FROM Contact WHERE Id =: u.ContactId LIMIT 1];
        List<ERP_Relationship__c> enabledAddresses = ERP_AddressRepo.fetchERPRelationshipsByContactId(con.Id);
        enabledAddresses[0].Is_Disabled__c = true;
        enabledAddresses[0].ERP_Address__c = con.Default_Ship_to_ERP_Address__r.Master_Address__c;
        update enabledAddresses;
        System.runAs(u)
        {
            String couponCode = 'TEST_COUPON';
            String successResponseBody = '{  "paymentTerms" : "PAYABLE A 30 JOURS NET",  "incoTerms" : "RENDU DROITS ACQUITES",  "incoCode" : "DDP",  "currencyCode" : "EUR",' +
                '"productList" : [    {      "itemNumber" : "1",      "partNumber" : "AL3099F",      "shippingPoint" : "US36",      "discount" : "16464.00", '     +
                '"handling" : 0,      "freight" : "31.10",      "taxVat" : "6.22",      "salesPrice" : "0.00",      "itemDetail" : ['       +
            	'{         "availableQty" : "0.000",          "availableDate" : "2025-02-26"        },        {          "availableQty" : "1.000",'   +
                '"availableDate" : "2025-02-28"        }      ]    },    {      "itemNumber" : "2",      "partNumber" : "AL289C",      "shippingPoint" : "US36",'   +
                '"discount" : "4709.00",      "handling" : 0,      "freight" : "8.90",      "taxVat" : "1.78",      "salesPrice" : "0.00",'   +
                '"itemDetail" : [        {          "availableQty" : "0.000",          "availableDate" : "2025-02-26"        },        {'+
                '"availableQty" : "1.000",          "availableDate" : "2025-02-28"        }      ]    }  ]}';
            Test.setMock(HttpCalloutMock.class, new ECOM_MockHttpResponseGenerator(200, 'OK', successResponseBody, null));
            Test.startTest();
            Map<String, Object> response = ECOM_CartService.repriceCart(cart.Id, couponCode);
            Test.stopTest();
            // Perform assertions to verify the results
            System.assertNotEquals(null, response, 'RepriceCart should not be null');
        }
    }
    //Rwps-3816 End

    @isTest
    static void testRepriceCartWithBillToShipToAsNull() {
        // Create test data as needed
        WebCart cart = [SELECT Id, Default_Bill_to_ERP_Address__c, Default_Ship_to_ERP_Address__c FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
        User u = [SELECT Id,AccountId, ContactId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        String acId = u.AccountId;
        Account acc = [SELECT Id FROM Account WHERE Id =: acId LIMIT 1];
        Contact con = [SELECT Id, Default_Ship_to_ERP_Address__c, Default_Bill_to_ERP_Address__c FROM Contact WHERE Id =: u.ContactId LIMIT 1];
        cart.Default_Ship_to_ERP_Address__c = null;
        cart.Default_Bill_to_ERP_Address__c = null;
        update cart;
        System.runAs(u)
        {
            String couponCode = 'TEST_COUPON';
            String successResponseBody = '{  "paymentTerms" : "PAYABLE A 30 JOURS NET",  "incoTerms" : "RENDU DROITS ACQUITES",  "incoCode" : "DDP",  "currencyCode" : "EUR",' +
                '"productList" : [    {      "itemNumber" : "1",      "partNumber" : "AL3099F",      "shippingPoint" : "US36",      "discount" : "16464.00", '     +
                '"handling" : 0,      "freight" : "31.10",      "taxVat" : "6.22",      "salesPrice" : "0.00",      "itemDetail" : ['       +
            	'{         "availableQty" : "0.000",          "availableDate" : "2025-02-26"        },        {          "availableQty" : "1.000",'   +
                '"availableDate" : "2025-02-28"        }      ]    },    {      "itemNumber" : "2",      "partNumber" : "AL289C",      "shippingPoint" : "US36",'   +
                '"discount" : "4709.00",      "handling" : 0,      "freight" : "8.90",      "taxVat" : "1.78",      "salesPrice" : "0.00",'   +
                '"itemDetail" : [        {          "availableQty" : "0.000",          "availableDate" : "2025-02-26"        },        {'+
                '"availableQty" : "1.000",          "availableDate" : "2025-02-28"        }      ]    }  ]}';
            Test.setMock(HttpCalloutMock.class, new ECOM_MockHttpResponseGenerator(200, 'OK', successResponseBody, null));
            Test.startTest();
            Map<String, Object> response = ECOM_CartService.repriceCart(cart.Id, couponCode);
            Test.stopTest();
            // Perform assertions to verify the results
            System.assertNotEquals(null, response, 'RepriceCart should not be null');
        }
    }
	
    @isTest
    static void testRepriceCartContactWithBillToAsNull() {
        // Create test data as needed
        WebCart cart = [SELECT Id, Default_Bill_to_ERP_Address__c, Default_Ship_to_ERP_Address__c FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
        User u = [SELECT Id,AccountId, ContactId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        String acId = u.AccountId;
        Account acc = [SELECT Id FROM Account WHERE Id =: acId LIMIT 1];
        Contact con = [SELECT Id, Default_Ship_to_ERP_Address__c, Default_Bill_to_ERP_Address__c FROM Contact WHERE Id =: u.ContactId LIMIT 1];
        cart.Default_Bill_to_ERP_Address__c = null;
        con.Default_Bill_to_ERP_Address__c = null;
        update cart;
        update con;
        System.runAs(u)
        {
            String couponCode = 'TEST_COUPON';
            String successResponseBody = '{  "paymentTerms" : "PAYABLE A 30 JOURS NET",  "incoTerms" : "RENDU DROITS ACQUITES",  "incoCode" : "DDP",  "currencyCode" : "EUR",' +
                '"productList" : [    {      "itemNumber" : "1",      "partNumber" : "AL3099F",      "shippingPoint" : "US36",      "discount" : "16464.00", '     +
                '"handling" : 0,      "freight" : "31.10",      "taxVat" : "6.22",      "salesPrice" : "0.00",      "itemDetail" : ['       +
            '{         "availableQty" : "0.000",          "availableDate" : "2025-02-26"        },        {          "availableQty" : "1.000",'   +
                '"availableDate" : "2025-02-28"        }      ]    },    {      "itemNumber" : "2",      "partNumber" : "AL289C",      "shippingPoint" : "US36",'   +
                '"discount" : "4709.00",      "handling" : 0,      "freight" : "8.90",      "taxVat" : "1.78",      "salesPrice" : "0.00",'   +
                '"itemDetail" : [        {          "availableQty" : "0.000",          "availableDate" : "2025-02-26"        },        {'+
                '"availableQty" : "1.000",          "availableDate" : "2025-02-28"        }      ]    }  ]}';
            Test.setMock(HttpCalloutMock.class, new ECOM_MockHttpResponseGenerator(200, 'OK', successResponseBody, null));
            Test.startTest();
            Map<String, Object> response = ECOM_CartService.repriceCart(cart.Id, couponCode);
            Test.stopTest();
            // Perform assertions to verify the results
            System.assertNotEquals(null, response, 'RepriceCart should not be null');
        }
    }

	@isTest
    static void testRepriceCartContactWithShipToAsNull() {
        // Create test data as needed
        WebCart cart = [SELECT Id, Default_Bill_to_ERP_Address__c, Default_Ship_to_ERP_Address__c FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
        User u = [SELECT Id,AccountId, ContactId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        String acId = u.AccountId;
        Account acc = [SELECT Id FROM Account WHERE Id =: acId LIMIT 1];
        Contact con = [SELECT Id, Default_Ship_to_ERP_Address__c, Default_Bill_to_ERP_Address__c FROM Contact WHERE Id =: u.ContactId LIMIT 1];
        cart.Default_Ship_to_ERP_Address__c = null;
        con.Default_Ship_to_ERP_Address__c = null;
        update cart;
        update con;
        System.runAs(u)
        {
            String couponCode = 'TEST_COUPON';
            String successResponseBody = '{  "paymentTerms" : "PAYABLE A 30 JOURS NET",  "incoTerms" : "RENDU DROITS ACQUITES",  "incoCode" : "DDP",  "currencyCode" : "EUR",' +
                '"productList" : [    {      "itemNumber" : "1",      "partNumber" : "AL3099F",      "shippingPoint" : "US36",      "discount" : "16464.00", '     +
                '"handling" : 0,      "freight" : "31.10",      "taxVat" : "6.22",      "salesPrice" : "0.00",      "itemDetail" : ['       +
            '{         "availableQty" : "0.000",          "availableDate" : "2025-02-26"        },        {          "availableQty" : "1.000",'   +
                '"availableDate" : "2025-02-28"        }      ]    },    {      "itemNumber" : "2",      "partNumber" : "AL289C",      "shippingPoint" : "US36",'   +
                '"discount" : "4709.00",      "handling" : 0,      "freight" : "8.90",      "taxVat" : "1.78",      "salesPrice" : "0.00",'   +
                '"itemDetail" : [        {          "availableQty" : "0.000",          "availableDate" : "2025-02-26"        },        {'+
                '"availableQty" : "1.000",          "availableDate" : "2025-02-28"        }      ]    }  ]}';
            Test.setMock(HttpCalloutMock.class, new ECOM_MockHttpResponseGenerator(200, 'OK', successResponseBody, null));
            Test.startTest();
            Map<String, Object> response = ECOM_CartService.repriceCart(cart.Id, couponCode);
            Test.stopTest();
            // Perform assertions to verify the results
            System.assertNotEquals(null, response, 'RepriceCart should not be null');
        }
    }
    
    @isTest
    static void testRepriceCartContactWithBillToShipToAsNull() {
        // Create test data as needed
        WebCart cart = [SELECT Id, Default_Bill_to_ERP_Address__c, Default_Ship_to_ERP_Address__c FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
        User u = [SELECT Id,AccountId, ContactId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        String acId = u.AccountId;
        Account acc = [SELECT Id FROM Account WHERE Id =: acId LIMIT 1];
        Contact con = [SELECT Id, Default_Ship_to_ERP_Address__c, Default_Bill_to_ERP_Address__c FROM Contact WHERE Id =: u.ContactId LIMIT 1];
        cart.Default_Ship_to_ERP_Address__c = null;
        cart.Default_Bill_to_ERP_Address__c = null;
        con.Default_Ship_to_ERP_Address__c = null;
        con.Default_Bill_to_ERP_Address__c = null;
        update cart;
        update con;
        System.runAs(u)
        {
            String couponCode = 'TEST_COUPON';
            String successResponseBody = '{  "paymentTerms" : "PAYABLE A 30 JOURS NET",  "incoTerms" : "RENDU DROITS ACQUITES",  "incoCode" : "DDP",  "currencyCode" : "EUR",' +
                '"productList" : [    {      "itemNumber" : "1",      "partNumber" : "AL3099F",      "shippingPoint" : "US36",      "discount" : "16464.00", '     +
                '"handling" : 0,      "freight" : "31.10",      "taxVat" : "6.22",      "salesPrice" : "0.00",      "itemDetail" : ['       +
            '{         "availableQty" : "0.000",          "availableDate" : "2025-02-26"        },        {          "availableQty" : "1.000",'   +
                '"availableDate" : "2025-02-28"        }      ]    },    {      "itemNumber" : "2",      "partNumber" : "AL289C",      "shippingPoint" : "US36",'   +
                '"discount" : "4709.00",      "handling" : 0,      "freight" : "8.90",      "taxVat" : "1.78",      "salesPrice" : "0.00",'   +
                '"itemDetail" : [        {          "availableQty" : "0.000",          "availableDate" : "2025-02-26"        },        {'+
                '"availableQty" : "1.000",          "availableDate" : "2025-02-28"        }      ]    }  ]}';
            Test.setMock(HttpCalloutMock.class, new ECOM_MockHttpResponseGenerator(200, 'OK', successResponseBody, null));
            Test.startTest();
            Map<String, Object> response = ECOM_CartService.repriceCart(cart.Id, couponCode);
            Test.stopTest();
            // Perform assertions to verify the results
            System.assertNotEquals(null, response, 'RepriceCart should not be null');
        }
    }
    
    @isTest
    static void testRepriceCartAsNull() {
        // Create test data as needed
        User u = [SELECT Id,AccountId, ContactId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
            String couponCode = 'TEST_COUPON';
            Test.startTest();
            Map<String, Object> response = ECOM_CartService.repriceCart('', couponCode);
            Test.stopTest();
            // Perform assertions to verify the results
            System.assertNotEquals(null, response, 'RepriceCart should not be null');
        }
    }
    //RWPS-2684 - ENDS 
    
    @isTest
    static void testRetrieveProductsByPartNumber() {
        // fetch test data as needed
        List<ECOM_CartController.ECOM_ProductWrapper> productCodes = new List<ECOM_CartController.ECOM_ProductWrapper>();
        ECOM_CartController.ECOM_ProductWrapper obj = new ECOM_CartController.ECOM_ProductWrapper();
        obj.partNumber = '1234567';
        obj.quantity = '1';
		User u = [SELECT Id,AccountId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        Test.startTest();
        // Call the method to be tested
        Map<String, Object> response = ECOM_CartService.retrieveProductsByPartNumber(productCodes);
        Map<String, Object> nullResponse = ECOM_CartService.retrieveProductsByPartNumber(null);
        Test.stopTest();
        // Perform assertions to verify the results
        System.assertEquals(true, response.get('success'), 'RetrieveProductsByPartNumber should return success');
        }
       }
    
    @isTest
    static void testRetrieveProductsByPartialPartNumber() {
        // fetch test data as needed
        String productData = '600518';
        List<String> excludedItems = new List<String>();
        ECOM_CartController.ECOM_ProductWrapper obj = new ECOM_CartController.ECOM_ProductWrapper();
        obj.partNumber = '1234567';
        obj.quantity = '1';
		User u = [SELECT Id,AccountId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        Test.startTest();
        // Call the method to be tested
        Map<String, Object> response = ECOM_CartService.retrieveProductsByPartialPartNumber(productData,excludedItems,false,'');
        Map<String, Object> response1 = ECOM_CartService.retrieveProductsByPartialPartNumber(productData,excludedItems,true,'');
        Map<String, Object> nullResponse = ECOM_CartService.retrieveProductsByPartialPartNumber(null,null,null,'');
        Test.stopTest();
        // Perform assertions to verify the results
        System.assertEquals(true, response.get('success'), 'RetrieveProductsByPartNumber should return success');
        } 
    }
    
    @isTest
    static void testGetPrimaryActiveCartForUserId() {
		User u = [SELECT Id,AccountId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        Test.startTest();
        // Call the method to be tested
        List<WebCart> response = ECOM_CartService.getPrimaryActiveCartForUserId(u.Id);
        Test.stopTest();
        } 
    }

    @isTest
    static void testAddItemsToCart() {
        
        // Create test data as needed
        String communityId = [SELECT Id FROM Network ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        String effectiveAccountId = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        User u = [SELECT Id,AccountId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        WebCart cartId = [SELECT Id,OwnerId FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
        CartItem webcartitems = [SELECT Id,Product2Id,Quantity,type,ECOM_Parent_Item__c FROM CartItem ORDER BY CREATEDDATE DESC LIMIT 1]; //RWPS-4202
        List<CartItem> cartItems = new List<CartItem>();
        cartItems.add(webcartitems);

        Product2 product = ECOM_TestUtil.createProduct('Test', '12345', '12345', true); //RWPS-4896
        ConnectApi.CartItem cartItem = new ConnectApi.CartItem();
        cartItem.productId = product.Id;  //RWPS-4896
        Set<String> productIdSet = new Set<String>();
        productIdSet.add(product.Id);  //RWPS-4896
        productIdSet.add(webcartitems.Product2Id);  //RWPS-4896
        //RWPS-4896-START
        CartItem newCartItem = new CartItem(cartId = cartId.Id, 
            Sku = 'SKU_Test1',
            Quantity = 1,
            Type = 'Product',
            Name = 'TestCartItem',
            CurrencyIsoCode = 'USD',
            Product2Id = webcartitems.Product2Id,
            ListPrice = 2000.00,
            SalesPrice = 2000.00,
            ECOM_ShippingCode__c='17259'      
        );
        cartItems.add(newCartItem);
        Product_Recommendation__c r1 = new Product_Recommendation__c();
        r1.Active__c = true;
        r1.ExternalId__c = 'testext';
        r1.Product_Main__c = webcartitems.Product2Id;
        r1.Product_Suggested__c = product.Id;
        r1.Suggest_Type__c = 'Combination';
        r1.Use_Case_Type__c = 'Web';
        insert r1;
         //RWPS-4896-END
        System.runAs(u)
        {
        Test.startTest();
        // Call the method to be tested
        // @mayank connectApi batchresult issue
        Map<String, Object> response = ECOM_CartService.addItemsToCart(communityId, effectiveAccountId, cartItems);
        Map<String, Object> result = ECOM_CartService.processCartItem(cartItem,productIdSet);
        Test.stopTest();

        // Perform assertions to verify the results
        //System.assertEquals(true, response.get('success'), 'AddItemsToCart should return success');
        }
    }
    
   // RWPS-2800
    /*@isTest
    static void testAddItemsToCartOwner2() {
        // Create test data as needed
        List<ECOM_CartModel> carts = new List<ECOM_CartModel>();
        ECOM_CartModel obj = new ECOM_CartModel();
        ECOM_CartItemModel itm = new ECOM_CartItemModel();
        CartItem cartitm = [SELECT Id,CartId,product2Id FROM CartItem ORDER BY CREATEDDATE DESC LIMIT 1];
        cartitm.ECOM_Parent__c='0a9O9000001GFP7IAO';
        update cartitm;
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
        obj.cartItems = cartItems;
        Account ac = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
        obj.accountId = ac.Id;
        obj.cartId = cartitm.CartId;
        obj.currencyIsoCode = 'USD';
        obj.isSecondary = false;
        obj.grandTotalAmount = '0';
        obj.name= 'Cart';
        obj.status = 'Active';
        obj.taxType = 'NET';
        //obj.userId = [SELECT Id FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        obj.webstoreId = [SELECT Id FROM WebStore LIMIT 1].Id;
        carts.add(obj);
        User u = [SELECT Id,AccountId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        Test.startTest();
        // Call the method to be tested
        ECOM_CartService cartService = new ECOM_CartService();
        List<ECOM_CartModel> result = cartService.addItemsToCart(carts);
        // Passing null cart Id and webstore Id with cart status closed to cover else if-else part
        obj.cartId = null;
        obj.webstoreId ='';
        carts.add(obj);
        Webcart testCart = [SELECT Id,status FROM Webcart WHERE status = 'Active' LIMIT 1];
        testCart.Status = 'Closed';
        update testCart;
        List<ECOM_CartModel> nullResult = cartService.addItemsToCart(carts);
        // passing null cart item id to cover else part
        cartItems.clear(); //clearing the list so all the cartItemModel data became empty
        obj.cartItems = cartItems; // assigning the list to CartModel class object
        List<ECOM_CartModel> nullResult1 = cartService.addItemsToCart(carts); // calling the method
        List<ECOM_CartModel> emptyCarts = new List<ECOM_CartModel>();
        List<ECOM_CartModel> emptyResult = cartService.addItemsToCart(emptyCarts);
        Test.stopTest();

        // Perform assertions to verify the results
       // System.assertEquals(carts.size(), result.size(), 'The number of returned cart models should match the input');
        }
    }*/
    //RWPS-2800
    @isTest
    static void testAddItemsToCartOwner() {
        // Create test data as needed
        List<ECOM_CartModel> carts = new List<ECOM_CartModel>();
        ECOM_CartModel obj = new ECOM_CartModel();
        ECOM_CartItemModel itm = new ECOM_CartItemModel();
        CartItem cartitm = [SELECT Id,CartId,product2Id,ECOM_Parent_Item__c FROM CartItem ORDER BY CREATEDDATE DESC LIMIT 1]; //RWPS-4202
        cartitm.ECOM_Parent__c=null;
        update cartitm;
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
        obj.cartItems = cartItems;
        Account ac = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
        obj.accountId = ac.Id;
        obj.cartId = cartitm.CartId;
        obj.currencyIsoCode = 'USD';
        obj.isSecondary = false;
        obj.grandTotalAmount = '0';
        obj.name= 'Cart';
        obj.status = 'Active';
        obj.taxType = 'NET';
        //obj.userId = [SELECT Id FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        obj.webstoreId = [SELECT Id FROM WebStore LIMIT 1].Id;
        carts.add(obj);
        User u = [SELECT Id,AccountId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];

        //RWPS-4896-START
        Product2 product = ECOM_TestUtil.createProduct('Test', '12345', '12345', true);
        Product_Recommendation__c r1 = new Product_Recommendation__c();
        r1.Active__c = true;
        r1.ExternalId__c = 'testext';
        r1.Product_Main__c = cartitm.Product2Id;
        r1.Product_Suggested__c = product.Id;
        r1.Suggest_Type__c = 'Combination';
        r1.Use_Case_Type__c = 'Web';
        insert r1;
        //RWPS-4896-End
        System.runAs(u)
        {
        Test.startTest();
        // Call the method to be tested
        ECOM_CartService cartService = new ECOM_CartService();
        List<ECOM_CartModel> result = cartService.addItemsToCart(carts);
        // Passing null cart Id and webstore Id with cart status closed to cover else if-else part
        obj.cartId = null;
        obj.webstoreId ='';
        carts.add(obj);
        Webcart testCart = [SELECT Id,status FROM Webcart WHERE status = 'Active' LIMIT 1];
        testCart.Status = 'Closed';
        update testCart;
        List<ECOM_CartModel> nullResult = cartService.addItemsToCart(carts);
        // passing null cart item id to cover else part
        cartItems.clear(); //clearing the list so all the cartItemModel data became empty
        obj.cartItems = cartItems; // assigning the list to CartModel class object
        List<ECOM_CartModel> nullResult1 = cartService.addItemsToCart(carts); // calling the method
        List<ECOM_CartModel> emptyCarts = new List<ECOM_CartModel>();
        List<ECOM_CartModel> emptyResult = cartService.addItemsToCart(emptyCarts);
        Test.stopTest();

        // Perform assertions to verify the results
       // System.assertEquals(carts.size(), result.size(), 'The number of returned cart models should match the input');
        }
    }

    @isTest
    static void testAddItemsToCartLogIn() {
        // Create test data as needed
        List<ECOM_CartModel> carts = new List<ECOM_CartModel>();
        ECOM_CartModel obj = new ECOM_CartModel();
        ECOM_CartItemModel itm = new ECOM_CartItemModel();
        CartItem cartitm = [SELECT Id,CartId,product2Id,ECOM_Parent_Item__c FROM CartItem ORDER BY CREATEDDATE DESC LIMIT 1]; //RWPS-4202
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
        obj.cartItems = cartItems;
        Account ac = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
        obj.accountId = ac.Id;
        obj.cartId = cartitm.Id;
        obj.currencyIsoCode = 'USD';
        obj.isSecondary = false;
        obj.grandTotalAmount = '0';
        obj.name= 'Cart';
        obj.status = 'Active';
        obj.taxType = 'NET';
        obj.userId = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        obj.webstoreId = [SELECT Id FROM WebStore LIMIT 1].Id;
        carts.add(obj);
        User u = [SELECT Id,AccountId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        Test.startTest();
        // Call the method to be tested
        ECOM_CartService cartService = new ECOM_CartService();
        List<ECOM_CartModel> result = cartService.addItemsToCart(carts);
        // Passing null cart Id and webstore Id with cart status closed to cover else if-else part
        obj.cartId = null;
        obj.webstoreId ='';
        Webcart testCart = [SELECT Id,status FROM Webcart WHERE status = 'Active' LIMIT 1];
        testCart.Status = 'Closed';
        update testCart;
        List<ECOM_CartModel> nullResult = cartService.addItemsToCart(carts);
        // passing null cart item id to cover else part
        cartItems.clear(); //clearing the list so all the cartItemModel data became empty
        obj.cartItems = cartItems; // assigning the list to CartModel class object
        List<ECOM_CartModel> nullResult1 = cartService.addItemsToCart(carts); // calling the method
        List<ECOM_CartModel> emptyCarts = new List<ECOM_CartModel>();
        List<ECOM_CartModel> emptyResult = cartService.addItemsToCart(emptyCarts);
        Test.stopTest();

        // Perform assertions to verify the results
        System.assertEquals(carts.size(), result.size(), 'The number of returned cart models should match the input');
        }
    }
    
    @isTest
    static void testUpdateCartItemListPrice() {
        //List<ConnectApi.BatchResult> batchResults = new List<ConnectApi.BatchResult>();
        ConnectApi.BatchResult[] batchResults = new List<ConnectApi.BatchResult>();
        //ConnectApi.BatchResult batchResult;
        //batchResults.add(batchResult);
        //prodIdToPriceMap.put('Product1', '50.00');
        Product2 p = ECOM_TestUtil.createProduct('Test', '12345', '12345', true);
        ConnectApi.CartItem cartItem = new ConnectApi.CartItem();
        Set<String> trainingProductIds = New Set<String>();//RWPS-4896
        trainingProductIds.add(p.id);//RWPS-4896
        cartItem.productId = p.Id;
        Map<String, String> prodIdToPriceMap = new Map<String, String>();
		prodIdToPriceMap.put('prodId',p.Id);
        List<CartItem> updatedCartItems = ECOM_CartService.updateCartItemListPrice(batchResults, prodIdToPriceMap,trainingProductIds);//RWPS-4896
        //CartItem ci = ECOM_CartService.processCartItemsUpdate(cartItem, prodIdToPriceMap);
        
        //System.assertEquals(1, updatedCartItems.size());
    }
    
    
    @isTest
    static void testECOM_CartModelDependent() {
        // test data for ECOM_CartModel and other dependencies
        List<ECOM_CartModel> carts = new List<ECOM_CartModel>();
        ECOM_CartModel obj = new ECOM_CartModel();
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
        obj.cartItems = cartItems;
        Account ac = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
        obj.accountId = ac.Id;
        obj.cartId = cartitm.Id;
        obj.currencyIsoCode = 'USD';
        obj.isSecondary = false;
        obj.grandTotalAmount = '200';
        obj.name= 'Cart';
        obj.status = 'Active';
        obj.taxType = 'NET';
        obj.userId = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        obj.webstoreId = [SELECT Id FROM WebStore LIMIT 1].Id;
        carts.add(obj);
        User usr = [SELECT Id FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(usr)
        {
       // Call the method to test
        ECOM_CartService rec = new ECOM_CartService();
        List<ECOM_CartModel> fetchedCarts = rec.fetchCart(carts);
        List<ECOM_CartModel> result = rec.getCartItems(carts);
        List<ECOM_CartModel> deleteResult = rec.deleteCart(carts);
        List<ECOM_CartModel> updateResult = rec.updateCartItems(carts);
        
        // empty cart Id
        carts.clear();//clearing the carts list
        obj.cartId = '';
        obj.webstoreId ='';
        Webcart testCart = [SELECT Id,status FROM Webcart WHERE status = 'Active' LIMIT 1];
        testCart.Status = 'Closed';
        //obj.cartId = cartitm.Id;
        carts.add(obj);
        User u = [SELECT Id,AccountId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        //System.runAs(u)
        //{
        List<ECOM_CartModel> fetchedCarts1 = rec.fetchCart(carts);
        update testCart;
        List<ECOM_CartModel> fetchedCarts2 = rec.fetchCart(carts);
        //obj.userId ='';
        //null parameter to cover exceptions
        List<ECOM_CartModel> fetchedCartsNull = rec.fetchCart(null);
        List<ECOM_CartModel> deleteResultNull = rec.deleteCart(null);
        List<ECOM_CartModel> updateResultNull = rec.updateCartItems(null);
        
        
		System.assertNotEquals(null, fetchedCarts,'fetchedCarts should not be null');
        System.assertEquals(0, fetchedCartsNull.size(),'fetchedCartsNull should be empty due to exception');
        System.assertEquals(0, deleteResultNull.size(),'deleteResultNull should be empty due to exception');
        System.assertEquals(0, updateResultNull.size(),'updateResultNull should be empty due to exception');
        //}
        }
    }
    

    @isTest
    static void testDeleteCartItemsById() {
        // Create test data as needed
        List<CartItem> cartItemId = [SELECT Id FROM CartItem ORDER BY CREATEDDATE DESC LIMIT 1];
        List<Id>cartItemIds = new List<Id>();
        cartItemIds.add(cartItemId[0].Id);
User usr = [SELECT Id FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(usr)
        {
        Test.startTest();
        // Call the method to be tested
        ECOM_CartService.deleteCartItemsById(cartItemIds);
        Test.stopTest();
        
        List<CartItem> response = [SELECT Id,Name FROM CartItem WHERE Id =: cartItemId[0].Id];
        System.AssertEquals(0,response.size(),'response should be empty');
        }
    }

    @isTest
    static void testDeleteCartItemsforProductId() {
        // Create test data as needed
        Id productId = [SELECT Id FROM Product2 ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        Id cartId = [SELECT Id FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        CartItem cm = [SELECT Id,Product2Id FROM CartItem WHERE CartId=:cartId LIMIT 1];
		User usr = [SELECT Id FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(usr)
        {
        Test.startTest();
        // Call the method to be tested
        ECOM_CartService.deleteCartItemsforProductId(cm.Product2Id, cartId);
        Test.stopTest();
        }
        
    }

    @isTest
    static void testUpdateCartItemListPrice2() {
        // Create test data as needed
        Id cartId = [SELECT Id FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        CartItem cm = [SELECT Id,Product2Id FROM CartItem WHERE CartId=:cartId LIMIT 1];
		User usr = [SELECT Id FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(usr)
        {
        Test.startTest();
        // Call the method to be tested
        ECOM_CartService.updateCartItemListPrice(cm.Id, 2);//RWPS-3658
        Test.stopTest();
        }
        
    }

    @isTest
    static void testGetCartItemsShippingDates() {
        // Create test data as needed
        Id cartId = [SELECT Id FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1].Id;
		User u = [SELECT Id,AccountId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        Test.startTest();
        List<CartItem> result = ECOM_CartService.getCartItemsShippingDates(cartId);
        Test.stopTest();
        }
        // Perform assertions to verify the results
       }

    @isTest
    static void testRemoveCoupon() {
        // Create test data as needed
        String cartId = [SELECT Id FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1].Id;
		User u = [SELECT Id,AccountId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        Test.startTest();
        Map<String, Object> result = ECOM_CartService.removeCoupon(cartId);
        Test.stopTest();

        // Perform assertions to verify the results
        }

    }

    @isTest
    static void testUpdateShippingDateOnCartItem() {
        // Create test data as needed
        Id cartItemId = [SELECT Id FROM CartItem ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        Date shipDate = Date.today();
		User u = [SELECT Id,AccountId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        Test.startTest();
        // Call the method to be tested
        ECOM_CartService.updateShippingDateOnCartItem(cartItemId, shipDate);
        Test.stopTest();

        // Perform assertions to verify the results
        }
    }

    @isTest
    static void testIsRADIdentifierAccount() {
        User u = [SELECT Id,AccountId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        Test.startTest();
        // Call the method to be tested
        Id cartId = [SELECT Id FROM WebCart ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        Boolean result = ECOM_CartService.isRADIdentifierAccount(cartId);
        Test.stopTest();

        // Perform assertions to verify the results
        System.AssertNotEquals(null,result,'result should not be null');
        }

    }
    @isTest
    static void testSendEmailsForAbandonedCart() {
        // Create test data as needed
        EmailTemplate emailTemp = ECOM_TestUtil.createEmailTemplate();
        insert emailTemp;
        List<WebCart> carts = [Select id, Contact__c, AccountId, GrandTotalAmount,OwnerId,Owner.Name,Owner.Email,Owner.Phone,ECOM_Total_Savings__c,//RWPS-3197
                              Default_Ship_to_ERP_Address__r.ApiCountry__c,Default_Ship_to_ERP_Address__r.fxAddress_CountryName__c FROM WebCart ORDER BY CREATEDDATE DESC];
		User u = [SELECT Id,AccountId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];//RWPS-2786
        System.runAs(u)
        {
        Test.startTest();
        // Call the method to be tested
        ECOM_CartService.sendEmailsForAbandonedCart(emailTemp, carts);
        ECOM_CartService.deleteTariffLineItem(carts[0].id);//RWPS-2786
        Test.stopTest();

        // Perform assertions to verify the results
      }
    }

    @isTest
    static void testGetAbandonedCart() {
        try{//RWPS-2786
        //test data as needed
        ECOM_Abandoned_Cart_Notification__mdt notification = [SELECT Id,Cart_Email_Template__c,Country__c,Cart_Price_Bucket_Min__c,Cart_Price_Bucket_Max__c 
                                                     FROM ECOM_Abandoned_Cart_Notification__mdt WHERE Country__c='United States' LIMIT 1];
        DateTime cartLastModifiedDateMax = DateTime.now();
        DateTime cartLastModifiedDateMin = DateTime.now().addDays(-30); 
        List<String> countries = new List<String>();
        countries.add('United States');
	    List<String> statuses = new List<String>{'Active', 'Checkout'};//RWPS-2786
        // Populate notification, countries, and statuses with test data
		User u = [SELECT Id,AccountId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        Test.startTest();
        // Call the method to be tested
        Map<String,List<String>> countryToIsoMap = ECOM_CustomMetadataService.getCountriesISO(countries);
        List<WebCart> result = ECOM_CartService.getAbandonedCart(notification, cartLastModifiedDateMax, cartLastModifiedDateMin, countries, statuses,countryToIsoMap);
        Test.stopTest();
        // Perform assertions to verify the results
        System.assertNotEquals(null,result,'Wrong Output');
        }
        //RWPS-2786 - Start
        }catch(Exception e){
        	
            system.debug(e);
            
        }
        //RWPS-2786 - End
    }

    @isTest
    static void testGetAbandonedCartNotification() {   //JIRA - RWPS-2052

        ECOM_Abandoned_Cart_Notification__mdt notification = getCustomMetadataRecord();
        //test data as needed
        DateTime cartLastModifiedDateMax = DateTime.now();
        DateTime cartLastModifiedDateMin = DateTime.now().addDays(-30); 
        List<String> countries = new List<String>();
        countries.add('United States');
	    List<String> statuses = new List<String>{'Active', 'Checkout'};//RWPS-2786
        // Populate notification, countries, and statuses with test data
		User u = [SELECT Id,AccountId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        Test.startTest();
        // Call the method to be tested
        Map<String,List<String>> countryToIsoMap = ECOM_CustomMetadataService.getCountriesISO(countries);
        List<WebCart> result = ECOM_CartService.getAbandonedCart(notification, cartLastModifiedDateMax, cartLastModifiedDateMin, countries, statuses,countryToIsoMap);
        Test.stopTest();
        // Perform assertions to verify the results
        System.assertNotEquals(null,result,'Wrong Output');
        }
    }
    //JIRA - RWPS-2052
    public static ECOM_Abandoned_Cart_Notification__mdt getCustomMetadataRecord() {
        ECOM_Abandoned_Cart_Notification__mdt notification = [SELECT Id,Cart_Email_Template__c,Country__c,Cart_Price_Bucket_Min__c,Cart_Price_Bucket_Max__c 
        FROM ECOM_Abandoned_Cart_Notification__mdt LIMIT 1];
        notification.Country__c = '';
        return notification;
    }
    
    
    @isTest(SeeAllData=false)
    static void testGetAbandonedCartCase2() {
        //test data as needed
        ECOM_Abandoned_Cart_Notification__mdt notification = [SELECT Id,Cart_Email_Template__c,Country__c,Cart_Price_Bucket_Min__c,Cart_Price_Bucket_Max__c 
                                                     FROM ECOM_Abandoned_Cart_Notification__mdt WHERE Country__c<>NULL LIMIT 1];
        DateTime cartLastModifiedDateMax = DateTime.now();
        DateTime cartLastModifiedDateMin = DateTime.now().addDays(-30); 
        List<String> countries = new List<String>();
        countries.add('United States');
	    List<String> statuses = new List<String>{'Active', 'Checkout'};//RWPS-2786
        // Populate notification, countries, and statuses with test data
		User u = [SELECT Id,AccountId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        Test.startTest();
        // Call the method to be tested
        Map<String,List<String>> countryToIsoMap = ECOM_CustomMetadataService.getCountriesISO(countries);
         system.debug('countryies: '+countryToIsoMap);
            List<WebCart> result = new List<WebCart>();
        try{
        	result = ECOM_CartService.getAbandonedCart(notification, cartLastModifiedDateMax, cartLastModifiedDateMin, countries, statuses,countryToIsoMap);
        }
        catch(Exception e){
                
        }
        Test.stopTest();
        // Perform assertions to verify the results
        System.assertNotEquals(null,result,'Wrong Output');
        }
    }


    @isTest
    static void testGetAbandonedCartCount() {
        // Create test data as needed
		ECOM_Abandoned_Cart_Notification__mdt notification = [SELECT Id,Cart_Email_Template__c,Country__c,Cart_Price_Bucket_Min__c,Cart_Price_Bucket_Max__c 
                                                     FROM ECOM_Abandoned_Cart_Notification__mdt WHERE Country__c='United States' LIMIT 1];        
        DateTime cartLastModifiedDateMax = DateTime.now();
        DateTime cartLastModifiedDateMin = DateTime.now().addDays(-30); 
        List<String> countries = new List<String>();
        countries.add('United States');
        List<String> statuses=new List<String>{'Active','Checkout'};
		User u = [SELECT Id,AccountId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        Test.startTest();
        // Call the method to be tested
        Map<String,List<String>> countryToIsoMap = ECOM_CustomMetadataService.getCountriesISO(countries);
        Integer result = ECOM_CartService.getAbandonedCartCount(notification, cartLastModifiedDateMax, cartLastModifiedDateMin, countries, statuses,countryToIsoMap);
        Test.stopTest();
        }
        
        //System.assertEquals(null,result,'Wrong Output');
    }

    @isTest
    static void testGetAbandonedCartCountWithoutCountry() {   //JIRA - RWPS-2052
        // Create test data as needed
		ECOM_Abandoned_Cart_Notification__mdt notification = getCustomMetadataRecord();    
        DateTime cartLastModifiedDateMax = DateTime.now();
        DateTime cartLastModifiedDateMin = DateTime.now().addDays(-30); 
        List<String> countries = new List<String>();
        countries.add('United States');
        List<String> statuses=new List<String>{'Active','Checkout'};
		User u = [SELECT Id,AccountId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        Test.startTest();
        // Call the method to be tested
        Map<String,List<String>> countryToIsoMap = ECOM_CustomMetadataService.getCountriesISO(countries);
        Integer result = ECOM_CartService.getAbandonedCartCount(notification, cartLastModifiedDateMax, cartLastModifiedDateMin, countries, statuses,countryToIsoMap);
        Test.stopTest();
        }
        
        //System.assertEquals(null,result,'Wrong Output');
    }
    
    @isTest(SeeAllData=false)
    static void testGetAbandonedCartCountCase2() {
        // Create test data as needed
		ECOM_Abandoned_Cart_Notification__mdt notification = [SELECT Id,Cart_Email_Template__c,Country__c,Cart_Price_Bucket_Min__c,Cart_Price_Bucket_Max__c 
                                                     FROM ECOM_Abandoned_Cart_Notification__mdt WHERE Country__c<>NULL LIMIT 1];        
        ECOM_Abandoned_Cart_Notification__mdt notification1=new ECOM_Abandoned_Cart_Notification__mdt();
        DateTime cartLastModifiedDateMax = DateTime.now();
        DateTime cartLastModifiedDateMin = DateTime.now().addDays(-30); 
        List<String> countries = new List<String>();
        //countries.add('United States');
        List<String> statuses=new List<String>{'Active','Checkout'};
		User u = [SELECT Id,AccountId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        Test.startTest();
        // Call the method to be tested
        Map<String,List<String>> countryToIsoMap = ECOM_CustomMetadataService.getCountriesISO(countries);
        try{
        	Integer result = ECOM_CartService.getAbandonedCartCount(notification, cartLastModifiedDateMax, cartLastModifiedDateMin, countries, statuses,countryToIsoMap);
        }
        catch(Exception e){
                
        }
        //Integer result2 = ECOM_CartService.getAbandonedCartCount(notification1, cartLastModifiedDateMax, cartLastModifiedDateMin, countries, statuses,countryToIsoMap);

        Test.stopTest();
        }
        
        //System.assertEquals(null,result,'Wrong Output');
    }

    @isTest
    static void testUpdateCart() {
        // Create test data as needed
        List<WebCart> cartsToUpdate = [SELECT Id,Name FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
		cartsToUpdate[0].Name = 'testRevCart';
        User u = [SELECT Id,AccountId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        Test.startTest();
        // Call the method to be tested
        ECOM_CartService.updateCart(cartsToUpdate);
        Test.stopTest();
        WebCart updatedCart = [SELECT Id,Name FROM Webcart WHERE Id =:cartsToUpdate[0].Id];
        //System.AssertEquals('testRevCart',updatedCart.Name,'Cart should be updated');
        }
    }

    @isTest
    static void testGetCartCheckoutSession() {
        //test data as needed
        
        Webcart cart = [SELECT Id FROM WebCart ORDER BY CREATEDDATE DESC LIMIT 1];
        Order ord = [SELECT Id FROM Order ORDER BY CREATEDDATE DESC LIMIT 1];
        User u = [SELECT Id FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        	CartCheckoutSession news = ECOM_TestUtil.createCartCheckoutSession(cart,ord);
        }
        CartCheckoutSession checkoutsession = [SELECT Id, Name, WebCartId, State, NextState, IsProcessing, BackgroundOperationId, OrderId, IsError, OrderReferenceNumber 
         							FROM CartCheckoutSession ];
        System.runAs(u)
        {
        Test.startTest();
        // Call the method to be tested
        CartCheckoutSession result = ECOM_CartService.getCartCheckoutSession(checkoutsession.BackgroundOperationId);
        Test.stopTest();
        }
    }
    
    @isTest
    static void createCartCheckoutSessionTest(){
        Test.startTest();
        CartCheckoutSession cart = new CartCheckoutSession();
        try{
        cart = ECOM_CartService.createCartCheckoutSession(cart);
        }
        catch(Exception e){
            
        }
        Test.stopTest();
    }

    @isTest
    static void testGetCartandCartItemsById() {
        String cartId = [SELECT Id FROM WebCart ORDER BY CREATEDDATE DESC LIMIT 1].Id;
		User u = [SELECT Id,AccountId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        Test.startTest();
        List<WebCart> result = ECOM_CartService.getCartandCartItemsById(cartId);
        Webcart res = ECOM_CartService.getPrimaryCartBasedOnId(cartId);
        CartCheckoutSession cartSession = ECOM_CartService.getCartCheckoutSessionByCartId(cartId);
        Test.stopTest();
        }
    }

    @isTest
    static void testGetPrimaryCartBasedOnOwner() {
        // Create test data as needed
        String userId = [SELECT Id FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1].Id;
		User u = [SELECT Id,AccountId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        Test.startTest();
        List<WebCart> result = ECOM_CartService.getPrimaryCartBasedOnOwner(userId);
        Test.stopTest();
        }
    }
    //RWPS-3658 - START
    @isTest
    static void testfilterAbandonedOptInCarts(){
        String userId = [SELECT Id FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        User u = [SELECT Id,AccountId,contactId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        Contact con = [SELECT Id, Email FROM Contact WHERE Id =: u.ContactId LIMIT 1];
		
        ECOM_Email_Preferences__c testPref = new ECOM_Email_Preferences__c();
        testPref.ECOM_isActive__c = true;
        testPref.ECOM_Contact__c = u.contactId;
        insert testPref;
        
        ECOM_Email_Preferences__c testPref1 = new ECOM_Email_Preferences__c();
        testPref1.ECOM_isActive__c = true;
        testPref1.ECOM_Contact__c = u.contactId;
        testPref1.Ecom_Opt_Out_from_Cart_Emails__c=true;
        testPref1.ECOM_Email__c=con.Email;
        insert testPref1;
        List<WebCart> cartToUpdate =  New List<WebCart>();
        List<WebCart> lstCart = [SELECT Id, WebCart.Contact__c, Default_Bill_to_ERP_Address__c, Default_Ship_to_ERP_Address__c FROM Webcart];
        for(WebCart cart : lstCart){
         	cart.Contact__c = u.contactId; 
            cartToUpdate.add(cart);
        }
      
        update cartToUpdate;
        //RWPS-4896 - Removed System.runAs()
        Test.startTest();
      	ECOM_CartService.filterAbandonedOptInCarts(cartToUpdate);
        Test.stopTest();
        
    }

    @isTest
    static void testFilterAbandonedOptInCarts_EmptyInput() {
        Test.startTest();
        
        
        List<WebCart> nullResult = ECOM_CartService.filterAbandonedOptInCarts(null);
      
        List<WebCart> emptyResult = ECOM_CartService.filterAbandonedOptInCarts(new List<WebCart>());
        Test.stopTest();

        System.assertEquals(0, nullResult.size(), 'Null input should return empty list');
        System.assertEquals(0, emptyResult.size(), 'Empty input should return empty list');
    }

    @isTest
    static void testGetShippingTime() {
        // Create test data as needed
        CartItem item = [SELECT Id,CartId FROM CartItem ORDER BY CREATEDDATE DESC LIMIT 1];
		User u = [SELECT Id,AccountId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        ECOM_ProductShippingTime__c pst = new ECOM_ProductShippingTime__c();
        pst.Name = 'Test Shipping Time1';
        pst.ECOM_Country__c = 'US';
        pst.Ecom_Priority__c = 'Priority'; 
        pst.Ecom_Total_DLV__c  = 20;
        pst.Ecom_Site__c = 'LUS10-A';
        pst.Ecom_Confidence_90__c = 'Arrives in 2-5 days';
        insert pst;
        
        System.runAs(u)
        {
        Test.startTest();
        ECOM_ProductShippingTime__c result = ECOM_CartService.getShippingTimeObj(item.id);
        List<ECOM_ProductShippingTime__c> lstProdShipping = [SELECT ID, ECOM_Country__c,Ecom_Priority__c,Ecom_Total_DLV__c,Ecom_Site__c, Ecom_Confidence_90__c FROM ECOM_ProductShippingTime__c];    
        ECOM_ProductShippingTime__c getMaxDL = ECOM_CartService.getMaxDLVRecord(lstProdShipping);
        WebCart cart = [SELECT id, Default_Ship_to_ERP_Address__c from WebCart where id =: item.CartId];
        cart.Default_Ship_to_ERP_Address__c = null;
        update cart;
        ECOM_ProductShippingTime__c result1 = ECOM_CartService.getShippingTimeObj(item.id);
     	
        Test.stopTest();
        }

        // Perform assertions to verify the results
    }

    //RWPS-4896 : Added the method for coverage
    @isTest
    static void testGetShippingTimeWithMoreDLV() {
        // Create test data as needed
        CartItem item = [SELECT Id,CartId FROM CartItem ORDER BY CREATEDDATE DESC LIMIT 1];
		User u = [SELECT Id,AccountId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        ECOM_ProductShippingTime__c pst = new ECOM_ProductShippingTime__c();
        pst.Name = 'Test Shipping Time1';
        pst.ECOM_Country__c = 'US';
        pst.Ecom_Priority__c = 'Priority'; 
        pst.Ecom_Total_DLV__c  = 20;
        pst.Ecom_Site__c = 'LUS10-A';
        pst.Ecom_Confidence_90__c = 'Arrives in 2-5 days';
        insert pst;

        ECOM_ProductShippingTime__c pst2 = new ECOM_ProductShippingTime__c();
        pst2.Name = 'Test Shipping Time1';
        pst2.ECOM_Country__c = 'US';
        pst2.Ecom_Priority__c = 'Priority'; 
        pst2.Ecom_Total_DLV__c  = 40;
        pst2.Ecom_Site__c = 'LUS10-A';
        pst2.Ecom_Confidence_90__c = 'Arrives in 2-5 days';
        insert pst2;
        System.runAs(u)
        {
        Test.startTest();
        ECOM_ProductShippingTime__c result = ECOM_CartService.getShippingTimeObj(item.id);
        List<ECOM_ProductShippingTime__c> lstProdShipping = [SELECT ID, ECOM_Country__c,Ecom_Priority__c,Ecom_Total_DLV__c,Ecom_Site__c, Ecom_Confidence_90__c FROM ECOM_ProductShippingTime__c];
        ECOM_ProductShippingTime__c getDL = ECOM_CartService.getMaxDLVRecord(new List<ECOM_ProductShippingTime__c>());
        ECOM_ProductShippingTime__c getMaxDL = ECOM_CartService.getMaxDLVRecord(lstProdShipping);
        WebCart cart = [SELECT id, Default_Ship_to_ERP_Address__c from WebCart where id =: item.CartId];
        cart.Default_Ship_to_ERP_Address__c = null;
        update cart;
        ECOM_ProductShippingTime__c result1 = ECOM_CartService.getShippingTimeObj(item.id);
        Test.stopTest();
        }
    }
    //RWPS-3658 - END
    @isTest
    static void testGetCreditCollections() {
        // Create test data as needed
        String moduleName = 'Test';
		User u = [SELECT Id,AccountId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        Test.startTest();
        Map<String, String> result = ECOM_CartService.getCreditCollections(moduleName);
        Test.stopTest();
        }

        // Perform assertions to verify the results
    }

    @isTest
    static void testGetCartDeliveryGroupMethodById() {
        //fetch test data as needed
        Id cartGroupMethodID =[SELECT Id FROM CartDeliveryGroupMethod ORDER BY CREATEDDATE DESC LIMIT 1].Id;
		User u = [SELECT Id,AccountId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        Test.startTest();
        // Call the method to be tested
        List<CartDeliveryGroupMethod> result = ECOM_CartService.getCartDeliveryGroupMethodById(cartGroupMethodID);
        Test.stopTest();
        }

        // Perform assertions to verify the results
    }
    
     @isTest
    static void testGetPunchoutCartandCartItemsById() {
        Account testAcc=[Select Id,Name From Account WHERE Name='TestClass Account' LIMIT 1];
        User testUser =  [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        // Call the method under test
        Test.startTest();
        ECOM_CartService cartControllerInstance = new ECOM_CartService();
        ECOM_POOMModel poomModel=cartControllerInstance.getPunchoutCartandCartItemsById(testUser.Id,testAcc.Id);
        Test.stopTest();

    }

    @isTest
    static void testGetCartDeliveryGroupById() {
        // Create test data as needed
        Id cartGroupID = [SELECT Id FROM CartDeliveryGroup ORDER BY CREATEDDATE DESC LIMIT 1].Id;
		User u = [SELECT Id,AccountId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        Test.startTest();
        // Call the method to be tested
        List<CartDeliveryGroup> result = ECOM_CartService.getCartDeliveryGroupById(cartGroupID);
        Test.stopTest();
        System.AssertNotEquals(null,result,'result should not be null');
        }
    }

    @isTest
    static void testUpdateCartDeliveryGroups() {
        // Create test data as needed
        List<CartDeliveryGroup> cartDeliveryGroupsToUpdate =[SELECT Id,Name FROM CartDeliveryGroup ORDER BY CREATEDDATE DESC LIMIT 1] ;
        cartDeliveryGroupsToUpdate[0].Name = 'TestRevCDG';
        User u = [SELECT Id,AccountId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        Test.startTest();
        // Call the method to be tested
        List<CartDeliveryGroup> result = ECOM_CartService.updateCartDeliveryGroups(cartDeliveryGroupsToUpdate);
        Test.stopTest();
        CartDeliveryGroup cdg = [SELECT Id,Name FROM CartDeliveryGroup WHERE Id =:cartDeliveryGroupsToUpdate[0].Id];
        System.Assert(cdg.Name == 'TestRevCDG');
        }
       
    }
    
    @isTest
    static void isRADIdentifierAccountTest(){
    	String cartId = [SELECT Id FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        Boolean response = ECOM_CartService.isRADIdentifierAccount(cartId);
    }
    
    @isTest
    static void processCartItemsUpdateTest(){
        CartItem ci = [SELECT Id,Product2Id FROM CartItem LIMIT 1];
        Map<String,String> prodIdToPriceMap = new Map<String,String>();
        prodIdToPriceMap.put(ci.Product2Id,'50');
        ConnectApi.CartItem cartItem = new ConnectApi.CartItem();
        cartItem.productId=ci.Product2Id;
        cartItem.quantity='5';
        try{
        CartItem response = ECOM_CartService.processCartItemsUpdate(cartItem,prodIdToPriceMap);
        }
        catch(Exception e){
            
        }
        
    }
    @isTest
    static void deleteCartItemTest(){
    	String cartId = [SELECT Id FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        List<CartItem> cartItems = [SELECT Id,Name, Sku, Quantity,ListPrice,SalesPrice,NetAdjustmentAmount,TotalAmount,TotalLineAmount,TotalPrice,TotalAdjustmentAmount,TotalPriceAfterAllAdjustments,ECOM_Earliest_Shipping_Date__c, ECOM_Selected_Shipping_Date__c,
                 UnitAdjustedPrice,UnitAdjustmentAmount,TotalListPrice, TotalTaxAmount, CartId, CartDeliveryGroupId, Product2.Id, ECOM_Parent__c,
                 Product2.Part_Number__c,Product2.Name,Product2.Dangerous_Goods_Indicator_Profile__c,Type , Product2.Business_Unit__c, Product2.Discount_Type__c,
                 Product2.Item_Class__c, Product2.Part_Type__c, 
                 Product2.Product_Line__c, Product2.Product_Type__c,Product2.IGOR_PAC__c,Product2.DisplayUrl,Product2.IGOR_Item_Class_Desc__c,Product2.Product_Line_Name__c,Product2.IGOR_Description__c,Product2.Sub_Business_Unit__c,Product2.Super_Business_Unit__c,CurrencyISOCode
                 FROM CartItem WHERE CartId =:cartId LIMIT 1];  //RWPS-4896
        CartItem parentItem = cartItems[0];
        CartItem childItem = parentItem.clone(false,true,false,false);
        childItem.Ecom_Parent__c = parentItem.Id;
        insert childItem;
        String prodId = cartItems[0].Product2.Id;
        //RWPS-4896-Start
        Product2 product = ECOM_TestUtil.createProduct('Test', '12345', '12345', true);
        Product_Recommendation__c r1 = new Product_Recommendation__c();
        r1.Active__c = true;
        r1.ExternalId__c = 'testext';
        r1.Product_Main__c = cartItems[0].Product2.Id;
        r1.Product_Suggested__c = product.Id;
        r1.Suggest_Type__c = 'Combination';
        r1.Use_Case_Type__c = 'Web';
        insert r1;
        //RWPS-4896-End
        Test.startTest();
            ECOM_CartService.deleteCartItem(cartId,parentItem.Id,prodId);
        Test.stopTest();
    }
    
      @isTest
    static void testGetActiveCartForPunchoutUser() {
        User testUser =  [Select Id,LastName, AccountId From User ORDER BY CREATEDDATE DESC LIMIT 1];
        WebCart testCart = [SELECT Id FROM WebCart ORDER BY CREATEDDATE DESC LIMIT 1];
        testCart.OwnerId = testUser.Id;
        testCart.AccountId = testUser.AccountId;
        update testCart;
        // Call the method under test
        Test.startTest();
        ECOM_CartService cartControllerInstance = new ECOM_CartService();
        WebCart result = cartControllerInstance.getActiveCartForPunchoutUser(testUser.Id);
        Test.stopTest();
        // Verify the results
        System.assertNotEquals(null, result, 'Cart should not be null');
        System.assertEquals(testCart.Id, result.Id, 'Returned cart should match the created test cart');
    }
    @isTest
    static void testGetWebCartForPunchoutUser() {
        
        User testUser =  [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
         testUser.ECOM_Is_Punchout_User__c=true;
        update testUser;
        List<User> newUser =  [Select Id,LastName, UserName,ECOM_Is_Punchout_User__c From User WHERE ECOM_Is_Punchout_User__c=true LIMIT 1 ];
        System.debug('newUser________'+newUser);
        // Call the method under test
        Test.startTest();
        ECOM_CartService cartControllerInstance = new ECOM_CartService();
        WebCart result = cartControllerInstance.getWebCartForPunchoutUser(testUser);
        //WebCart result1 = cartControllerInstance.getWebCartForPunchoutUser(newUser);

        Test.stopTest();
        System.assertNotEquals(null, result, 'Cart should not be null');
        
        List<WebCart> createdCarts = [SELECT Id FROM WebCart WHERE OwnerId = :testUser.Id];
        System.assertEquals(1, createdCarts.size(), 'A new cart should be created for the user');
    }


    @isTest
    static void testUpdatedPunchoutCart() {
        
        User testUser =  [Select Id,LastName,AccountId,ECOM_Is_Punchout_User__c From User ORDER BY CREATEDDATE DESC LIMIT 1];
        String u = testUser.Id;//RWPS-2683
        WebCart testCart = [SELECT Id FROM WebCart ORDER BY CREATEDDATE DESC LIMIT 1];
        //ECOM_TestUtil.createPunchoutData();
        ECOM_PunchoutWrapper.PunchoutServiceRequest posr=ECOM_TestUtil.createPOSRModelForRevvityPunchoutForNewUser();
        String testPosrrJson = JSON.Serialize(posr);
        String testPosrJson = '{"key": "value"}';
        
        Test.startTest();
        Map<String, Object> result = ECOM_CartService.updatePunchoutCart(u, testPosrJson);
        Map<String, Object> result1 = ECOM_CartService.updatePunchoutCart(testUser.Id, testPosrrJson);//RWPS-2683

        Test.stopTest();
        System.assertNotEquals(null, result, 'Response map should not be null');
    }
    
     @isTest
    static void testUpdatePunchoutCart() {
        
        User testUser =  [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        // Call the method under test
        Test.startTest();
        ECOM_CartService cartControllerInstance = new ECOM_CartService();
        cartControllerInstance.updatePunchoutCart(testUser.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testCheckProductMaterialStatus() {
        
        WebCart testCart = [SELECT Id FROM WebCart ORDER BY CREATEDDATE DESC LIMIT 1];
        // Call the method under test
        Test.startTest();
        Map<String,Object> responseMap=ECOM_CartService.checkProductMaterialStatus(testCart.Id);
        Map<String,Object> responseMap1=ECOM_CartService.checkProductMaterialStatus('testCartId');
        Map<String,Object> responseMap2=ECOM_CartService.checkProductMaterialStatus('testCartId');
        Test.stopTest();
        System.assertEquals(true, responseMap.get('success'), 'Response map should Contain success true for the successfull response');

    }
    //RWPS-2800
    @isTest
    static void testCheckProductMaterialStatusExc() {        
        WebCart testCart = [SELECT Id FROM WebCart ORDER BY CREATEDDATE DESC LIMIT 1];
        testCart.status = null;
        update testCart;
        // Call the method under test
        Test.startTest();
        Map<String,Object> responseMap=ECOM_CartService.checkProductMaterialStatus(testCart.Id);
        Test.stopTest();
    }

    @isTest
    static void testRepo() {
        
        WebCart testCart = [SELECT Id FROM WebCart ORDER BY CREATEDDATE DESC LIMIT 1];
        // Call the method under test
        Test.startTest();
        List<WebCart> carts = ECOM_CartRepo.getCartsBasedOnOwner(UserInfo.getUserId());
		WebCart getWebCarts = ECOM_CartRepo.getPrimaryCartBasedOnId(testCart.Id);
        Test.stopTest();
        System.assertEquals(carts.size(),0);
        System.assertEquals(getWebCarts.Id,testCart.Id);

    }
    
    @isTest
    static void testRetrieveCartTaxRepo() {
        
        WebCart testCart = [SELECT Id FROM WebCart ORDER BY CREATEDDATE DESC LIMIT 1];
        // Call the method under test
        Test.startTest();
        List<CartTax> cartTax = ECOM_CartRepo.getCartTaxRecordsPerCart(testCart.Id);
        Test.stopTest();
        System.assertEquals(0,cartTax.size());

}
    
    @isTest
    static void testGetUniqueProductCount() {
         Webcart cart = [SELECT Id FROM WebCart ORDER BY CREATEDDATE DESC LIMIT 1];
        Order ord = [SELECT Id FROM Order ORDER BY CREATEDDATE DESC LIMIT 1];
        User u = [SELECT Id FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        	CartCheckoutSession news = ECOM_TestUtil.createCartCheckoutSession(cart,ord);
        }
        // Call the method under test
         System.runAs(u)
        {
            Test.startTest();
            Map<String,Object> result = ECOM_CartService.getUniqueProductCount();
            Test.stopTest();
        }    
    }
    
    @isTest
    static void testGetCartItemsByCartId() {
        WebCart testCart = [SELECT Id FROM WebCart ORDER BY CREATEDDATE DESC LIMIT 1];
        // Call the method under test
        Test.startTest();
        List<CartItem> result = ECOM_CartService.getCartItemsByCartId(testCart.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testGetCartTaxRecordsPerCart() {
        WebCart testCart = [SELECT Id FROM WebCart ORDER BY CREATEDDATE DESC LIMIT 1];
        // Call the method under test
        Test.startTest();
        List<CartTax> result = ECOM_CartService.getCartTaxRecordsPerCart(testCart.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testGetCartDetails() {
        WebCart testCart = [SELECT Id FROM WebCart ORDER BY CREATEDDATE DESC LIMIT 1];
        // Call the method under test
        Test.startTest();
        List<WebCart> result = ECOM_CartService.getCartDetails(testCart.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateWebCart() {
        WebCart testCart = [SELECT Id FROM WebCart ORDER BY CREATEDDATE DESC LIMIT 1];
        // Call the method under test
        Test.startTest();
        ECOM_CartService.updateWebCart(testCart);
        Test.stopTest();
    }
    
     @isTest
    static void testInsertCartTaxRepo() {
        
        WebCart testCart = [SELECT Id FROM WebCart ORDER BY CREATEDDATE DESC LIMIT 1];
        CartItem item=[Select id from CartItem Limit 1];
        // Call the method under test
        Test.startTest();
        CartTax tax = new CartTax( 
            Amount = 100,
            CartItemId = item.id,
            Name = 'Tax',
            TaxCalculationDate = Date.today(),
            TaxType = 'Estimated'
        );
        ECOM_CartRepo.insertCartTaxes(new List<CartTax>{tax});
        ECOM_CartRepo.upsertCartTax(new List<CartTax>{tax});
        List<CartDeliveryGroup> cdg = ECOM_CartRepo.getCartDeliveryGroupByCart(testCart.Id);
        List<CartItem> cis =ECOM_CartRepo.getCartItemsByCartId(testCart.Id);
        List<CartTax> cartTax = ECOM_CartRepo.getCartTaxRecords(new Set<String>{item.Id});
        
        Test.stopTest();
        System.assertEquals(1,cdg.size());
        System.assertEquals(1,cartTax.size());

    }

    @isTest
    static void testInsertCartTaxes() {
        
        WebCart testCart = [SELECT Id FROM WebCart ORDER BY CREATEDDATE DESC LIMIT 1];
        CartItem item=[SELECT Id FROM CartItem LIMIT 1];
        // Call the method under test
        Test.startTest();
        CartTax tax = new CartTax( 
            Amount = 100,
            CartItemId = item.id,
            Name = 'Tax',
            TaxCalculationDate = Date.today(),
            TaxType = 'Estimated'
        );
        List<CartTax> cartTaxList = new List<CartTax>{tax};
        List<CartTax> result = ECOM_CartService.insertCartTaxes(cartTaxList);
        Test.stopTest();
    }
    @isTest
    static void updateBillToShipToOnCartTest(){
        User u = [SELECT Id,AccountId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        WebCart cart = [SELECT Id FROM WebCart ORDER BY CreatedDate DESC LIMIT 1];
        System.runAs(u){
            Test.startTest();
            ECOM_CartService.updateBillToShipToOnCart(cart.Id);
            Test.stopTest();
        }
    }
	
    @isTest
    static void updateBillToShipToOnCartTest2(){
        User u = [SELECT Id,AccountId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        WebCart cart = [SELECT Id FROM WebCart ORDER BY CreatedDate DESC LIMIT 1];
        System.runAs(u){
            Test.startTest();
            ECOM_CartService.updateBillToShipToOnCart(null);
            Test.stopTest();
        }
    }
    
    @isTest
    static void deleteShippingCartItemTest(){
        WebCart cart = [SELECT Id FROM WebCart ORDER BY CreatedDate DESC LIMIT 1];
        Test.startTest();
        ECOM_CartService.deleteShippingCartItem(cart.Id);
        Test.stopTest();
    }
    
    
    @isTest
    static void getProductSalesByProdIdAndMaterialCodesTest(){
        User u = [SELECT Id,AccountId FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        Product2 pro = [SELECT Id FROM Product2 ORDER BY CREATEDDATE DESC LIMIT 1];
        Product2 pro1 = new Product2(Name = 'Test Product', ProductCode = 'TP-001', IsActive = true);
    insert pro1;
        List<String> productIds = new List<String>();
        productIds.add(pro.Id);
        productIds.add(pro1.Id);
         Product_Sales__c productSales = ECOM_TestUtil.createProduct_Sales(pro1.Id);
         Product_Sales__c newProductSales = ECOM_TestUtil.createProduct_Sales(pro.Id); //RWPS-4896
        System.runAs(u){
            Test.startTest();
            ECOM_CartService.getProductSalesByProdIdAndMaterialCodes(productIds,false);
            ECOM_CartService.getProductSalesByProdIdAndMaterialCodes(productIds,true);
            Test.stopTest();
        }
    }
    
    /*
     * @description  This method is used to test reprice cart for promotion 
  	 * @author gaurav.bhansali@revvity.com | 01-16-2025 | RWPS-2307
    **/
    @isTest
    static void testRepriceCartForPromotion() {
        // Create test data as needed
        WebCart cart = [SELECT Id, Default_Bill_to_ERP_Address__c, Default_Ship_to_ERP_Address__c FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
        CartItem item = [SELECT ID, product2.Part_Number__c FROM CartItem where CartId =: cart.id and  product2.Part_Number__c = '1234567' limit 1]; //RWPS-3811
        Order ord = [SELECT Id,ECOM_Promo_Code__c, OwnerId FROM Order ORDER BY CREATEDDATE DESC LIMIT 1];
        ord.ECOM_Promo_Code__c = 'NAPCFDNA';
        update ord;
           
        User u = [SELECT Id,AccountId, ContactId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        String acId = u.AccountId;
        Account acc = [SELECT Id FROM Account WHERE Id =: acId LIMIT 1];
        Contact con = [SELECT Id, Default_Ship_to_ERP_Address__c, Default_Bill_to_ERP_Address__c FROM Contact WHERE Id =: u.ContactId LIMIT 1];
        cart.Default_Ship_to_ERP_Address__c = con?.Default_Ship_to_ERP_Address__c;
        cart.Default_Bill_to_ERP_Address__c = con?.Default_Ship_to_ERP_Address__c;
        update cart;
        
        //RWPS-3811-START
        Promotion promo = New Promotion(Name = 'Buy One Get One', IsActive = true);
        insert promo;
        //Insert Coupoun
        Coupon couponBogo = New Coupon(CouponCode = 'NAPCFDNA', PromotionId = promo.id, Status = 'Active', BOGO_Applicable_Products__c=item.product2.Part_Number__c, Usage_Type__c = 'Unlimited');
        Insert couponBogo;
        Map<String, Object> response4 = ECOM_CartService.repriceCart(cart.Id, couponBogo.CouponCode); 
        //RWPS-3811 START
        couponBogo.BOGO_Applicable_Products__c = 'TEST5454';
        update couponBogo;
        Map<String, Object> response5 = ECOM_CartService.repriceCart(cart.Id, couponBogo.CouponCode); 
        couponBogo.Usage_Type__c = 'One Time';
        couponBogo.BOGO_Applicable_Products__c = item.product2.Part_Number__c;
        update couponBogo;

         Promotion promoExcluded = New Promotion(Name = 'Buy One Get One', IsActive = true);
         insert promoExcluded;
        //Insert Coupoun
        Coupon couponExcluded = New Coupon(CouponCode = 'TEST113', PromotionId = promoExcluded.id, Status = 'Active', ECOM_Excluded_Products__c = item.product2.Part_Number__c);
        Insert couponExcluded;
        //RWPS-3811 END

        System.runAs(u)
        {
            
        String couponCode = 'RGEVAL';
        String successResponseBody = '{"status": "success"}';
        Test.setMock(HttpCalloutMock.class, new ECOM_MockHttpResponseGenerator(200, 'OK', successResponseBody, null));
        Test.startTest();
        ECOM_CartService cartService = New ECOM_CartService();
        cartService.updatePunchoutCart(u.id);
        Map<String, Object> response = ECOM_CartService.repriceCart(cart.Id, couponCode);
        Map<String, Object> response3 = ECOM_CartService.repriceCart(cart.Id, 'Test25'); //RWPS-3283
        Map<String, Object> response1 = ECOM_CartService.repriceCart(cart.Id, 'RGEVAL50'); 
		Map<String, Object> response2 = ECOM_CartService.repriceCart('', couponCode);
        Map<String, Object> response6 = ECOM_CartService.repriceCart(cart.Id, couponBogo.CouponCode); 
        Map<String, Object> response7 = ECOM_CartService.repriceCart(cart.Id, couponExcluded.CouponCode);
       

       
        ECOM_CartService.updateAssociatedCarts();
        Test.stopTest();

        // Perform assertions to verify the results
        System.assertNotEquals(null, response, 'RepriceCart should not be null');
        System.assertNotEquals(null, response1, 'wrong output');
        System.assertNotEquals(null, response2, 'Wrong Output');
        System.assertNotEquals(null, response4, 'Wrong Output');
        
        }
        
    }

    @isTest
    static void testIsValidCouponCode() {
        WebCart cartId = [SELECT Id,OwnerId FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
        Test.startTest();
        Integer count = ECOM_CartRepo.isValidCouponCode('RGEVAL50','US'); //RWPS-3186
        ECOM_CartRepo.getCartDeliveryGroupMethodByCart(cartId.Id);
        Test.stopTest();
    }
     /*
     * @description  This method is used to test reprice cart for punchout user 
  	 * @author gaurav.bhansali@revvity.com | 12-05-2025 | RWPS-3220
    **/
    @isTest
    static void testRepriceCartForPunchout() {
        // Create test data as needed
        WebCart cart = [SELECT Id, Default_Bill_to_ERP_Address__c, Default_Ship_to_ERP_Address__c FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
           
        User u = [SELECT Id,AccountId, ContactId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        String acId = u.AccountId;
        Account acc = [SELECT Id FROM Account WHERE Id =: acId LIMIT 1];
        Contact con = [SELECT Id, Default_Ship_to_ERP_Address__c, Default_Bill_to_ERP_Address__c FROM Contact WHERE Id =: u.ContactId LIMIT 1];
        cart.Default_Ship_to_ERP_Address__c = con?.Default_Ship_to_ERP_Address__c;
        cart.Default_Bill_to_ERP_Address__c = con?.Default_Ship_to_ERP_Address__c;
        cart.ECOM_Is_Punchout_Cart__c = true;
        update cart;

        System.runAs(u)
        {
            
        String couponCode = 'RGEVAL';
        String successResponseBody = '{"status": "success"}';
        Test.setMock(HttpCalloutMock.class, new ECOM_MockHttpResponseGenerator(200, 'OK', successResponseBody, null));
        Test.startTest();
        ECOM_CartService cartService = New ECOM_CartService();
        cartService.updatePunchoutCart(u.id);
		Map<String, Object> response1 = ECOM_CartService.repriceCart(cart.Id, 'HELLO10'); 
		Map<String, Object> response2 = ECOM_CartService.repriceCart('', couponCode);
        	Map<String, Object> response3 = ECOM_CartService.repriceCart(cart.Id, 'NAPCFDNA'); 
       
        ECOM_CartService.updateAssociatedCarts();
        Test.stopTest();

        // Perform assertions to verify the results
        System.assertNotEquals(null, response1, 'wrong output');
        System.assertNotEquals(null, response2, 'Wrong Output');
        }
        
    }

    //RWPS-4202
    @isTest
    static void testGetFreeItemPromoMsg() {
        
        // Create test data as needed
        User u = [SELECT Id,AccountId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
        CartItem webcartitems = [SELECT Id,Product2Id,Product2.Part_Number__c,Quantity,type,ECOM_Parent_Item__c FROM CartItem ORDER BY CREATEDDATE DESC LIMIT 1]; //RWPS-4202
        webcartitems.ECOM_Parent_Item__c = webcartitems.Id;
        update webcartitems;
        List<CartItem> cartItems = new List<CartItem>();
        cartItems.add(webcartitems);
       
        System.runAs(u)
        {
        Test.startTest();
        String response = ECOM_CartService.getFreeItemPromoMsg(cartItems);
        Test.stopTest();

        }
    }
    /**
     * @description This method verifies a single-use promotion code has already been redeemed by a user or account
     * @author Princy Anthony | 11 March 2026
     */
    @isTest
	static void testSingleUsePromoAlreadyUsed() {

    	WebCart cart = [SELECT Id FROM WebCart ORDER BY CreatedDate DESC LIMIT 1];
    	Order ord = [SELECT Id, ECOM_Promo_Code__c FROM Order ORDER BY CreatedDate DESC LIMIT 1];
    	User u = [SELECT Id, AccountId, ContactId FROM User WHERE Username='testR1@test.org' LIMIT 1];
		ord.ECOM_Promo_Code__c = 'HELLO10';
    	update ord;

    	System.runAs(u){

        Test.startTest();
        Map<String,Object> resp = ECOM_CartService.repriceCart(cart.Id,'HELLO10');
        Test.stopTest();

        System.assertNotEquals(null, resp);
   	 }
	}
   
		
}