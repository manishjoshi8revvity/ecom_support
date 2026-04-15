/**************************************************************

* 1. Jira Ticket(s) that relates to this class
    - RWPS-6100
*
* 2. Description - This class is a test class.
*
* 3. Objects referenced
*    - None
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_OrderAndSAPOrderWrapperUtility
*
* 6. Test Class Name:
*    -None
*
* 7. Is @Invocable : No
*
* 8. Author Name(s):
*    - Sachin V 2026.02.12 Created the class and method parseOrderAndSAPOrdersTest - RWPS-6100

*************************************************************/

@isTest(SeeAllData=false)
private with sharing class ECOM_OrderAndSAPOrderWrapperUtility_Test {

    @TestSetup
    static void testSetupData() {
        ECOM_TestUtil.initialStorefrontSetup();

        //Inserting SAP Order Summary records with different dates and order numbers
        insert new List<SAP_Order_Summary__c>{
            new SAP_Order_Summary__c(
                Contact_Email__c = 'test@example.com',
                Order_Number__c = 123,
                Customer_PO_Number__c = '123ABC',
                Ship_To_Address_Postal_Code__c = '12345',
                Actual_Order_Date__c = Date.today()
            ),
            new SAP_Order_Summary__c(
                Contact_Email__c = 'test@example.com',
                Order_Number__c = 1234,
                Customer_PO_Number__c = '1234ABCD',
                Ship_To_Address_Postal_Code__c = '123456',
                Actual_Order_Date__c = Date.today().addDays(-1)
            ),
            new SAP_Order_Summary__c(
                Contact_Email__c = 'test@example.com',
                Customer_PO_Number__c = '1234ABCD',
                Ship_To_Address_Postal_Code__c = '123456'
            ),
            new SAP_Order_Summary__c(
                Contact_Email__c = 'test@example.com',
                Order_Number__c = 1234,
                Customer_PO_Number__c = '1234ABCD',
                Ship_To_Address_Postal_Code__c = '123456',
                Actual_Order_Date__c = Date.today().addDays(1)
            )
        };

        //Inserting Order records
        List<Account> accountList = [SELECT Id FROM Account LIMIT 1];
        if (accountList.isEmpty() == false && accountList[0].Id != null) {
            List<Order> orderList = new List<Order>();
            for (Integer i = 0; i < 6; i++) {
                orderList.add(ECOM_TestUtil.createOrder(accountList[0]));
            }
            if (orderList.isEmpty() == false) {
                insert orderList;
            }
        }
    }

    /**
     * @description This test method is to test the functionality of parseOrderAndSAPOrders method which combines and sorts the SF and SAP orders based on date and order number
     * @author Sachin V | 2026.02.12 | RWPS-6100
     */
    @isTest
    static void parseOrderAndSAPOrdersTest() {
        ECOM_OrderAndSAPOrderWrapperUtility.FlowInputs input = new ECOM_OrderAndSAPOrderWrapperUtility.FlowInputs();
        List<ECOM_OrderAndSAPOrderWrapperUtility.FlowOutputs> outputList = new List<ECOM_OrderAndSAPOrderWrapperUtility.FlowOutputs>();

        List<Order> orderList = [SELECT Id, OrderNumber, EffectiveDate, CreatedDate, ECOM_Order_Summary_Status__c, ECOM_SAP_Order_Summary__r.Customer_PO_Number__c  FROM Order];
        List<SAP_Order_Summary__c> orderSummaryList = [SELECT Id, Order_Number__c, Actual_Order_Date__c, CreatedDate, fxStatusB2B__c, Customer_PO_Number__c FROM SAP_Order_Summary__c];

        input.orderRecords = orderList;
        input.sapOrderRecords = orderSummaryList;
        Test.startTest();
        outputList = ECOM_OrderAndSAPOrderWrapperUtility.parseOrderAndSAPOrders(new List<ECOM_OrderAndSAPOrderWrapperUtility.FlowInputs>{ input });
        Test.stopTest();
        Assert.areEqual(false, outputList.isEmpty() && outputList.size() == 0, 'Combined order collection should be returned');
    }
}