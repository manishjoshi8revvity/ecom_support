/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-3225
*
* 2. Description - This class is used as test class for ECOM_SelfServiceController
*
* 3. Objects referenced
*   - SAP_Order_Summary__c
*   - Account
*   - Contact
*   - User
*   - Order
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_TestUtil
*
* 6. Is @Invocable (Yes or No): No
*
* 7. Author Name(s):
*    - Abhishek Joshi 2024.06.17
*    - Abhishek Joshi 2025.01.21 - Added testGetNonShippableItems method - RWPS-2227
*    - Abhishek Joshi 2025.05.02 - Added testgetOrdersFromHierarchyNumber method - RWPS-3834
*
*************************************************************/

@isTest(seeAllData=false)
public with sharing class ECOM_SelfServiceController_Test {

    /**
     * @description This method tests if we get correct order data from SAP order summary
     * @author abhishek.joshi@revvity.com | 17 June 2024
     */
    @isTest
    public static void testOrderFoundInSAPOrderSummary() {
        test.startTest();
        // Test data
        String orderNumber = ECOM_SelfServiceConstants.TEST_SAP_ORDER_NUMBER;
        String poNumber = 'PO-123';
        String zipCode = '12345';

        // Create some sample SAP_Order_Summary__c records
        SAP_Order_Summary__c orderSummary1 = new SAP_Order_Summary__c(
            Contact_Email__c = 'test@example.com',
            Order_Number__c = 123,
            Customer_PO_Number__c = poNumber,
            Ship_To_Address_Postal_Code__c = zipCode,
            Name = orderNumber
        );

        insert new List<SAP_Order_Summary__c>{orderSummary1};

        Map<String, Object> result = ECOM_SelfServiceController.getOrderDetails(
            new Map<String, Object> {
                'orderNumber' => (Object) orderNumber,
                'poNumberOrPostalCode' => (Object) zipCode
            }
        );

        Map<String, Object> resultData = (Map<String, Object>) result.get('sapOrder');

        System.assert(
            ((String) resultData.get('PONumber')) == poNumber,
            'Test if we get correct order data from SAP order summary'
        );

        Test.stopTest();
    }

    /**
     * @description This method tests if we get correct order data from Order object
     * @author abhishek.joshi@revvity.com | 17 June 2024
     */
    @isTest
    public static void testOrderFoundInOrders() {
        test.startTest();
        // Test data
        String poNumber = 'PO-123';
        String orderNumber = '456789';

        Account acc = new Account();
        Contact con = new Contact();
        acc = ECOM_TestUtil.createAccount();
        con = ECOM_TestUtil.createContact(acc);

        User portalUser = ECOM_TestUtil.createPortalUser(con);

        Order order = new Order();
        order.AccountId = acc.Id;
        order.OwnerId = portalUser.Id;
        order.EffectiveDate = system.today();
        order.Status = 'Draft';
        order.PoNumber = poNumber;
        insert order;

        Order testOrder = [SELECT PoNumber, OrderNumber FROM Order WHERE PoNumber =: poNumber LIMIT 1];

        Map<String, Object> result = ECOM_SelfServiceController.getOrderDetails(
            new Map<String, Object> {
                'orderNumber' => (Object) testOrder.OrderNumber,
                'poNumberOrPostalCode' => (Object) poNumber,
                'orderNumberPadded' => (Object) testOrder.OrderNumber
            }
        );

        System.assert(
            ((Order) result.get('orderData')).poNumber == poNumber,
            'Test if we get correct order data from Order object'
        );

        Test.stopTest();
    }

    /**
     * @description This method tests if invalid entra auth gives empty object
     * @author abhishek.joshi@revvity.com | 17 June 2024
     */
    @isTest
    public static void testGetOrderDetailsEntraAuthFailure() {
        test.startTest();

        Map<String, Object> result = ECOM_SelfServiceController.getOrderDetails(
            new Map<String, Object> {
                'orderNumber' => (Object) '',
                'poNumberOrPostalCode' => (Object) '',
                'encryptedSession' => (Object) 'abc'
            }
        );

        Assert.isTrue(
            ((Boolean) result.get('loginError')),
            'Test if invalid entra auth gives empty object'
        );

        Test.stopTest();
    }

    /**
     * @description This method tests order not found scenario
     * @author abhishek.joshi@revvity.com | 17 June 2024
     */
    @isTest
    public static void testGetOrderDetailsDataNotFound() {
        test.startTest();

        Map<String, Object> result = ECOM_SelfServiceController.getOrderDetails(
            new Map<String, Object> {
                'orderNumber' => (Object) '123',
                'poNumberOrPostalCode' => (Object) '456'
            }
        );

        Assert.isTrue(
            result.isEmpty(),
            'Test if order not found'
        );

        Test.stopTest();
    }

    /**
     * @description This method checks self service user auth failure.
     * @author abhishek.joshi@revvity.com | 17 June 2024
     */
    @isTest
    public static void testAuthWithEntra() {
        test.startTest();

        Map<String, String> authData = ECOM_SelfServiceController.authWithEntra(
            'accessToken',
            'test@non-revvity.com',
            'sub'
        );
        String success = authData.get('success');
        Assert.isNull(success, 'Check self service user auth failure.');

        Test.stopTest();
    }

    /**
     * @description This method checks self service get user data failure.
     * @author abhishek.joshi@revvity.com | 17 June 2024
     */
    @isTest
    public static void testGetUserData() {
        test.startTest();

        Map<String, Object> userData = ECOM_SelfServiceController.getUserData('');
        Object success = userData.get('success');
        Assert.isNull(success, 'Check self service get user data failure.');

        Test.stopTest();
    }

    /**
     * @description This method tests if we get non shippable part numbers correctly
     * @author abhishek.joshi@revvity.com | 2025.01.21
     */
    @isTest
    public static void testGetNonShippableItems() {
        test.startTest();

        String nonShippableItemClass =
            (System.Label.ECOM_Self_Service_Non_Shippable_Products_Item_Classes.split(','))[0];
        String testPn = 'testPnNonShippable';

        Product2 p1 = ECOM_TestUtil.createProduct('Test', testPn, testPn, true);
        p1.Item_Class__c = nonShippableItemClass;
        update p1;

        List<String> listPn = new List<String>{testPn};

        System.assert(
            testPn == ECOM_SelfServiceController.getNonShippableItems(listPn)[0].Part_Number__c,
            'Test if we get non shippable part numbers correctly'
        );

        Test.stopTest();
    }

    /**
     * @description This method tests getOrdersFromHierarchyNumber method
     * @author abhishek.joshi@revvity.com | 2025.08.22
     */
    @isTest
    public static void testgetOrdersFromHierarchyNumber() {
        Test.startTest();
        // Arrange: create ERP address hierarchy and related SAP order data
        String hierarchyNumber = 'HIER-001';
        String soldToCustomerId = 'CUST-0001';
        String salesOrg = 'US10';
        String searchToken = 'ABC123'; // will be used in OrderNumber/PO/Material search

        // Master and Sold To ERP Addresses
        ERP_Address__c masterAddr = new ERP_Address__c(
            Name = 'Master Addr',
            Address_Type__c = 'Master',
            ERP_Customer_Base_Number__c = hierarchyNumber,
            ERP_Customer_Number__c = soldToCustomerId
        );
        insert masterAddr;

        ERP_Address__c soldToAddr = new ERP_Address__c(
            Name = 'SoldTo Addr',
            Address_Type__c = 'Sold To',
            ERP_Customer_Base_Number__c = hierarchyNumber,
            Master_Address__c = masterAddr.Id,
            ERP_Sales_Org__c = salesOrg
        );
        insert soldToAddr;

        // Create an SAP Order Summary and a line item (SAP_Order_Items__c) that will match the search
        // Populate fields referenced by the repo SOQL and controller mapping
        SAP_Order_Summary__c sos = new SAP_Order_Summary__c(
            Name = 'ORD-' + searchToken, // OrderNumber match
            Customer_PO_Number__c = 'PO-' + searchToken, // PO match
            Actual_Order_Date__c = Date.today(), // within date window
            Ship_To_Address_Postal_Code__c = '94107',
            Sold_To_Customer_Id__c = soldToCustomerId,
            Sold_To_ERP_Address__c = soldToAddr.Id
        );
        insert sos;

        SAP_Order_Items__c soi = new SAP_Order_Items__c(
            Name = 'Item 1',
            PKI_Order_Summary__c = sos.Id,
            Material_Number__c = searchToken
        );
        insert soi;

        String encHierarchy = ECOM_EncryptUtil.encryptWithAES256(hierarchyNumber);
        String encSearch = ECOM_EncryptUtil.encryptWithAES256(searchToken);
        String encSalesOrg = ECOM_EncryptUtil.encryptWithAES256(salesOrg);

        List<Map<String,Object>> results =
            ECOM_SelfServiceController.getOrdersFromHierarchyNumber(
                new Map<String, Object>{
                    'hierarchyNumber' => (Object) encHierarchy,
                    'searchString' => (Object) encSearch,
                    'salesOrg' => (Object) encSalesOrg,
                    'startDateMonthOffset' => (Object) -12
                }
            );

        // Assert
        System.assertNotEquals(0, results.size(), 'Expected at least one matching order row');
        Map<String,Object> row = results[0];
        System.assertEquals(sos.Name, (String) row.get('OrderNumber'), 'OrderNumber should match SAP summary Name');
        System.assertEquals(sos.Customer_PO_Number__c, (String) row.get('CustomerPONumber'), 'PO Number should match');
        System.assertEquals(sos.Ship_To_Address_Postal_Code__c, (String) row.get('PostalCode'), 'Postal code should match');
        System.assertEquals(sos.Actual_Order_Date__c, (Date) row.get('OrderDate'), 'Order date should match Actual_Order_Date__c');

        Test.stopTest();
    }
}