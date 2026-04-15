/**************************************************************

* 1. Jira Ticket(s) that relates to this class

*  

*

* 2. Description - This class is a test class.

*

* 3. Objects referenced

*    - Order

*.   - OrderItem

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

*************************************************************/

@isTest
public with sharing class ECOM_OrderConfirmationEmail_Test {
    
    @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
    }
    
    /* @isTest
static void testGetOrderDetails(){


Order testOrder = [SELECT Id ,OrderNumber,ECOM_Promo_Code__c,PoNumber FROM Order ORDER BY CreatedDate DESC LIMIT 1];
testOrder.PoNumber = '22334';
update testOrder;


// Create an instance of the controller
ECOM_OrderConfirmationEmailController controller = new ECOM_OrderConfirmationEmailController();
controller.orderRecordId = testOrder.Id;
Test.startTest();
controller.getOrderItems();
Test.stopTest();
System.assertNotEquals(null, controller,'Error Message for OrderRecords');

}

@isTest
static void testGetOrderItems(){


Order testOrder = [SELECT Id ,OrderNumber,ECOM_Promo_Code__c,PoNumber FROM Order ORDER BY CreatedDate DESC LIMIT 1];
testOrder.PoNumber = '22334';
update testOrder;

OrderItem testOrderItem = [SELECT Id  FROM OrderItem ORDER BY CreatedDate DESC LIMIT 1];
// Create test OrderItem records related to the test Order
List<OrderItem> testOrderItems = new List<OrderItem>();
testOrderItems.add(testOrderItem);


ECOM_OrderConfirmationEmailController controller = new ECOM_OrderConfirmationEmailController();
controller.orderRecordId = testOrder.Id;

Test.startTest();
controller.getOrderItems();
Test.stopTest();
// Perform assertions 
System.assertNotEquals(null, controller,'Error message');

}*/
    
    @isTest
    static void testgetOrderDetails() {
        Order testOrder = [SELECT Id ,OrderNumber,ECOM_Promo_Code__c,PoNumber FROM Order ORDER BY CreatedDate DESC LIMIT 1];
        OrderItem testOrderItem = [SELECT Id  FROM OrderItem ORDER BY CreatedDate DESC LIMIT 1];
        CardPaymentMethod cardPayment = new CardPaymentMethod();
        cardPayment.ECOM_Order__c = testOrder.Id;
        cardPayment.CardLastFour = 8865;
        cardPayment.CardType ='Visa';
        cardPayment.CardCategory = 'CreditCard';
        cardPayment.Status = 'active';
        cardpayment.ProcessingMode = 'External';
        insert cardPayment;
        
        Test.startTest();
        ECOM_OrderConfirmationEmailController result = new ECOM_OrderConfirmationEmailController();
        result.orderRecordId =testOrder.Id;
        result.getOrderDetails();
        Test.stopTest();
    }
    
   
    @isTest
    static void testSetOrderRecordId() {
        // Create test data, such as an Order record, for testing
        Order testOrder =  [SELECT Id ,OrderNumber,ECOM_Promo_Code__c,PoNumber FROM Order ORDER BY CreatedDate DESC LIMIT 1];

        // Instantiate the controller class
        ECOM_OrderConfirmationEmailController controller = new ECOM_OrderConfirmationEmailController();

        // Call the setOrderRecordId method with the test Order Id
        controller.setOrderRecordId(testOrder.Id);

        // Perform assertions to validate the controller's behavior and state
        System.assertEquals(testOrder.Id, controller.orderRecordId, 'orderRecordId should be set correctly');
       
    }


    @isTest
    static void testGetOrderRecordId() {
        // Create test data, such as an Order record, for testing
        Order testOrder =  [SELECT Id ,OrderNumber,ECOM_Promo_Code__c,PoNumber FROM Order ORDER BY CreatedDate DESC LIMIT 1];

        // Instantiate the controller class
        ECOM_OrderConfirmationEmailController controller = new ECOM_OrderConfirmationEmailController();

        // Set the orderRecordId using the setOrderRecordId method
        controller.setOrderRecordId(testOrder.Id);

        // Call the getOrderRecordId method and assert the returned value
        Id orderRecordId = controller.getOrderRecordId();
        System.assertEquals(testOrder.Id, orderRecordId, 'getOrderRecordId should return the expected value');
        
     
    
}

    
}