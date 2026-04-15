/**************************************************************

* 1. Jira Ticket(s) that relates to this class

*  

*

* 2. Description - This class is a test class.

*

* 3. Objects referenced

*    - Order


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
public with sharing class ECOM_OrderCreateBatch_Test {
    @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
        
    }
    
    @isTest
    static void testBatchExecution() {
        Contact testContact = [Select Id,LastName From Contact ORDER BY CREATEDDATE DESC LIMIT 1];
        Account testAccount  = [Select Id From Account ORDER BY CREATEDDATE DESC LIMIT 1];
        User testUser = [Select Id,LastName,ContactId From User Where ContactId =:testContact.Id ORDER BY CREATEDDATE DESC LIMIT 1];
        Order order = [SELECT Id ,OrderNumber,ECOM_Promo_Code__c,PoNumber,OwnerId FROM Order ORDER BY CreatedDate DESC LIMIT 1];
        System.debug('order'+order.OwnerId);
        order.ECOM_Promo_Code__c = 'testpromo';
        //order.PoNumber = '22334';
        update order;
        ERP_Address__c erpAddress = [Select Id  From ERP_Address__c ORDER BY CreatedDate DESC LIMIT 1];
        
        ERP_Relationship__c erpRelation = [Select Id ,Name From ERP_Relationship__c  ORDER BY CreatedDate DESC LIMIT 1];
        List<ERP_RelationShip__c> erpRelationships = new List<ERP_RelationShip__c>();
        erpRelationships.add(erpRelation);
        
        PaymentAuthorization paymentAuthorization = [Select Id ,AccountId From PaymentAuthorization Where AccountId =:testAccount.Id ORDER BY CREATEDDATE DESC LIMIT 1 ];
        List<PaymentAuthorization> paymentAuthorizationlist = new  List<PaymentAuthorization>();
        paymentAuthorizationlist.add(paymentAuthorization);
        
        CardPaymentMethod cardPayment = [Select Id,CardType From CardPaymentMethod ORDER BY CREATEDDATE DESC LIMIT 1 ];
        List<CardPaymentMethod> CardPaymentMethodlist = new List<CardPaymentMethod>();
        CardPaymentMethodlist.add(cardPayment);
        
        
        List<Order> testOrderlist = new List<Order>();
        testOrderlist.add(order);
        
        List<OrderItem> ordItem = [Select Id,OrderId,Product2.Name From OrderItem  where OrderId =:order.Id ORDER BY CreatedDate DESC Limit 1];
        System.debug('ordItem'+ordItem);
        List<Map<String, Object>> orderItemsJSON = new List<Map<String, Object>>();
        
        // Convert each OrderItem__c record to a JSON-compatible map
        for (OrderItem orderItem : ordItem) {
            Map<String, Object> orderItemMap = new Map<String, Object>();
            orderItemMap.put('Id', orderItem.Id);
            orderItemMap.put('Name', orderItem.Product2.Name);
            
            
            orderItemsJSON.add(orderItemMap);
        }
        
        // Create a Set<String> to store order IDs
        Set<String> orderIds = new Set<String>();
        orderIds.add(order.Id); 
        
        List<Order> ord = new List<Order>();
        
        for (String orderId : orderIds) {
            Order newOrder = new Order();
            newOrder.Id = orderId;
            ord.add(newOrder);
        }
        
        ECOM_OrderCreateFlowWrapper.Request testRequest = new ECOM_OrderCreateFlowWrapper.Request();
        testRequest.orderId = ord[0].Id;
        // ECOM_OrderSummaryResponseWrapper.OrderResponseHeader odRespHeader = testRequest.OrderResponse.OrderResponseHeader;
        
        String body = JSON.serialize(
            new Map<String, Object>{
                'OrderResponse' => new Map<String, Object>{
                    'Error' => new Map<String, Object>{
                        'errorCode' => 'your_error_code_here',
                            'errorMessage' => 'your_error_message_here',
                            'errorDescription' => 'your_error_description_here'
                            },
                                'OrderResponseHeader' => new Map<String, Object>{
                                    //'headerProperty1' => odRespHeader.headerProperty1,
                                    //'headerProperty2' => odRespHeader.headerProperty2
                                },
                                    'orderItems' => orderItemsJSON
                                    }
            }
        );
        
        
        ECOM_MockHttpResponseGenerator mock = new ECOM_MockHttpResponseGenerator(200, 'OK', body, null);
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        String query = ECOM_OrderRepo.getQueryStringForBatch(order.Id); 
        ECOM_OrderCreateBatch batch = new ECOM_OrderCreateBatch(query);
        Database.executeBatch(batch);
        
        // Stop the test context
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testerrorBatchExecution() {
        Order order = [SELECT Id ,OrderNumber,ECOM_Promo_Code__c,PoNumber, OwnerId FROM Order ORDER BY CreatedDate DESC LIMIT 1];
        order.ECOM_Promo_Code__c = 'testpromo';
        order.PoNumber = '22334';
        update order;
        
        String body = '{'+
            '"OrderResponse": {'+
            '"OrderResponseHeader": {'+
            '"PurchaseOrderID": "",'+
            '"SellerOrderID": "1223",'+
            '"ShippingCost": "",'+
            '"CreditCardNumber": "",'+
            '"CreditCardType": "",'+
            '"TelephoneNumber": "",'+
            '"AdditionalInfo": "",'+
            '"SpecialHandlingInstructions": "",'+
            '"Datetime": {'+
            '"Year": "",'+
            '"Month": "",'+
            '"Day": "",'+
            '"Hour": "",'+
            '"Minute": "",'+
            '"Second": "",'+
            '"Subsecond": "",'+
            '"Timezone": "EST"'+
            '},'+
            '"OrderResponseDetail": ['+
            '{'+
            '"ShippingPoint": "US36",'+
            '"OrderLineNumber": "100",'+
            '"ProductID": "BLU502Z250UC",'+
            '"Description": "EASYTIDES ATP,[g-32P]-",'+
            '"AdjustedPrice": "453.50",'+
            '"Discount": "",'+
            '"TaxVAT": "0.00",'+
            '"ItemDetail": {'+
            '"AvailableQty": "0.000",'+
            '"AvailableDate": "2022-12-15"'+
            '}'+
            '},'+
            '{'+
            '"ShippingPoint": "US36",'+
            '"OrderLineNumber": "1",'+
            '"ProductID": "BLU502A100UC",'+
            '"Description": "EASYTIDES ATP,[g-32P]-",'+
            '"AdjustedPrice": "318.50",'+
            '"Discount": "",'+
            '"TaxVAT": "0.00",'+
            '"ItemDetail": {'+
            '"AvailableQty": "0.000",'+
            '"AvailableDate": "2022-12-15"'+
            '}'+
            '},'+
            '{'+
            '"ShippingPoint": "US36",'+
            '"OrderLineNumber": "2",'+
            '"ProductID": "BLU002A500UC",'+
            '"Description": "ATP,[g-32P]-",'+
            '"AdjustedPrice": "556.00",'+
            '"Discount": "",'+
            '"TaxVAT": "0.00",'+
            '"ItemDetail": {'+
            '"AvailableQty": "0.000",'+
            '"AvailableDate": "2022-12-15"'+
            '}'+
            '}'+
            ']'+
            '},'+
            '"Error": {'+
            '"ErrorDetails": ['+
            '{'+
            '"errorMessage": "",'+
            '"errorCode": ""'+
            '}'+
            ']'+
            '}'+
            '}'+
            '}';
        
        
        ECOM_MockHttpResponseGenerator mock = new ECOM_MockHttpResponseGenerator(200, 'OK', body, null);
Test.setMock(HttpCalloutMock.class, mock);

Test.startTest();
String query = 'SELECT Id ,OrderNumber,ECOM_Promo_Code__c,PoNumber, OwnerId FROM Order'; 
ECOM_OrderCreateBatch batch = new ECOM_OrderCreateBatch(query);
Database.executeBatch(batch);

Test.stopTest();

        
    }
}