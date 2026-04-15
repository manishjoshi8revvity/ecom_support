/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-3225
*
* 2. Description - This class is used as test class for ECOM_SelfServiceRepo
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
*	 - Manish Joshi 2024.12.13 Added method getOrgType as test method. Ticket - RWPS-1662
*    - Abhishek Joshi 2025.01.21 - Added testGetNonShippableItems method - RWPS-2227
*    - Abhishek Joshi 2025.05.02 - Added testGetSelfServiceMetadata method - RWPS-3289
*    - Abhishek Joshi 2025.10.27 - Added testGetAddressesFromHierarchyNumber and testSearchOrdersByCustomerDataAndSearchTerm methods - RWPS-3834
*************************************************************/

@isTest(seeAllData=false)
public with sharing class ECOM_SelfServiceRepo_Test {
    /**
     * @description This method tests if we get correct order data from SAP order summary
     * @author abhishek.joshi@revvity.com | 17 June 2024
     */
    @isTest
    public static void testFindSelfServiceOrderDataFromSAPOrderSummary() {
        test.startTest();
        // Test data
        String orderNumber = '123456';
        String poNumber = 'PO-123';
        String zipCode = '12345';

        // Create some sample SAP_Order_Summary__c records
        SAP_Order_Summary__c orderSummary1 = new SAP_Order_Summary__c(
            Contact_Email__c = 'test@example.com',
            Order_Number__c = 123,
            Customer_PO_Number__c = orderNumber,
            Ship_To_Address_Postal_Code__c = zipCode,
            Name = orderNumber
        );

        insert new List<SAP_Order_Summary__c>{orderSummary1};

        List<SAP_Order_Summary__c> result =
            ECOM_SelfServiceRepo.findSelfServiceOrderDataFromSAPOrderSummary(
                orderNumber,
                orderNumber,
                zipCode
            );

        System.assert(
            result[0].Name == orderNumber,
            'Test if we get correct order data from SAP order summary'
        );

        Test.stopTest();
    }

    /**
     * @description This method tests if we get correct order data from Order object
     * @author abhishek.joshi@revvity.com | 17 June 2024
     */
    @isTest
    public static void testFindSelfServiceOrderDataFromOrder() {
        test.startTest();
        // Test data
        String poNumber = 'PO-123';
        String orderNumber = '123456';

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

        List<Order> result =
            ECOM_SelfServiceRepo.findSelfServiceOrderDataFromOrder(
                order.OrderNumber,
                order.OrderNumber,
                poNumber
            );

        System.assert(
            result[0].poNumber == poNumber,
            'Test if we get correct order data from Order object'
        );

        Test.stopTest();
    }

    /**
     * @description This method tests if we get non shippable part numbers correctly
     * @author abhishek.joshi@revvity.com | 2025.01.21
     */
    @isTest
    public static void testGetNonShippableItems() {
        ECOM_SelfServiceController_Test.testGetNonShippableItems();
    }

    //RWPS-1662
    @isTest
    public static void getOrgType(){
        Test.startTest();
        ECOM_SelfServiceRepo.getOrgType();
        Test.stopTest();
    }

    /**
     * @description This method tests if we get self service metadata correctly
     * @author abhishek.joshi@revvity.com | 2025.05.2
     */
    @IsTest
    public static void testGetSelfServiceMetadata() {
        test.startTest();
        // Test data
        String metadataName = ECOM_SelfServiceConstants.TRACKING_MAP_METADATA;

        ECOM_Selfservice_Setting__mdt metadata = ECOM_SelfServiceRepo.getSelfServiceMetadata(
            metadataName
        );

        System.assert(
            metadata != null,
            'Test if we get correct metadata from ECOM_SelfServiceRepo'
        );

        Test.stopTest();
    }

    /**
     * @description This method tests getAddressesFromHierarchyNumber method
     * @author abhishek.joshi@revvity.com | 2025.10.28
     */
    @IsTest
    public static void testGetAddressesFromHierarchyNumber() {
        test.startTest();

        ECOM_SelfServiceRepo.getAddressesFromHierarchyNumberAndSalesOrg('HN12345', 'US10');

        Test.stopTest();
    }

    /**
     * @description This method tests searchOrdersByCustomerDataAndSearchTerm method
     * @author abhishek.joshi@revvity.com | 2025.10.28
     */
    @IsTest
    public static void testSearchOrdersByCustomerDataAndSearchTerm() {
        test.startTest();

        ECOM_SelfServiceRepo.searchOrdersByCustomerDataAndSearchTerm(new Set<String>{'1234'}, 'searchTerm', 1);

        Test.stopTest();
    }
}