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
* 	 - Manoj 2024.06.25 RWPS-553 Sending Contact ID to SAP
*    - Manoj 2024.08.27 RWPS-1287 Need a notification for order types other than ZWCC & ZWEB 
*    - Gaurav 2025.04.24 RWPS-1285 test coverage for large pack order
*    - Manish 2025.08.08 RWPS-3387 Removed ECOM_CustomNotification call & added method testProcessSAPOrderDetails2
*************************************************************/

@isTest
public with sharing class ECOM_OrderCreateFlowController_Test {
    @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
    }
    
    
    @isTest
    static void testProcessSAPOrderDetails() {
        Contact testContact = [Select Id,LastName From Contact ORDER BY CREATEDDATE DESC LIMIT 1];
        Account testAccount  = [Select Id From Account ORDER BY CREATEDDATE DESC LIMIT 1];
        User testUser = [Select Id,LastName,ContactId From User Where ContactId =:testContact.Id ORDER BY CREATEDDATE DESC LIMIT 1];
        Order order = [SELECT Id, ECOM_SAP_Order_Number__c,ECOM_Order_On_Hold__c ,ECOM_Order_Create_Retry__c,OrderNumber FROM Order ORDER BY CreatedDate DESC LIMIT 1];
        order.ECOM_Order_On_Hold__c = false;
        order.SAP_Contact_ID__c='01293645';//RWPS-553
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
        List<ECOM_OrderCreateFlowWrapper.Response> result;
        System.runAs(testUser){
            result = ECOM_OrderCreateFlowController.processSAPOrderDetails(new List<ECOM_OrderCreateFlowWrapper.Request>{testRequest}); 
            /*ECOM_CustomNotification notofication = new ECOM_CustomNotification('Ecom_Large_Pack_Order_Notification');
            notofication.sendNotification(order,'Order');*/
        }
        
        Test.stopTest();
        
        
    }
    
    @isTest
    public static void testProcessSAPOrderDetails2() {
        Contact testContact = [Select Id,LastName From Contact ORDER BY CREATEDDATE DESC LIMIT 1];
        Account testAccount  = [Select Id From Account ORDER BY CREATEDDATE DESC LIMIT 1];
        User testUser = [Select Id,LastName,ContactId From User Where ContactId =:testContact.Id ORDER BY CREATEDDATE DESC LIMIT 1];
        Order order = [SELECT Id, ECOM_SAP_Order_Number__c,ECOM_Order_On_Hold__c ,ECOM_Order_Create_Retry__c,OrderNumber FROM Order ORDER BY CreatedDate DESC LIMIT 1];
        order.ECOM_Order_On_Hold__c = true;
        order.SAP_Contact_ID__c='';//RWPS-1285
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
        List<ECOM_OrderCreateFlowWrapper.Response> result;
        System.runAs(testUser){
            result = ECOM_OrderCreateFlowController.processSAPOrderDetails(new List<ECOM_OrderCreateFlowWrapper.Request>{testRequest}); 
        }
        Test.stopTest();
    }
   
}