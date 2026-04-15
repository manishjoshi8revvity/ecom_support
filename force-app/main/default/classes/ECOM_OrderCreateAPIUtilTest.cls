/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM - 125 
*
* 2. Description - This class is a test class for ECOM_OrderCreateAPIUtil.
*
*
* 3. Objects referenced
*    - Order
*    - Order Item
*
*
*    
*
* 5. Dependant Class(es):
*    - ECOM_TestUtil
*    - ECOM_OrderSummaryRequestWrapper
*
* 6. Test Class Name: ECOM_OrderCreateAPIUtil_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - ManojKumar 2023.11.13
*	 - Sathiya 2024.06.11 Changes done based on structure change
*    - Poonam Shukla 2025.06.13 Added InvoiceEmail Address in Order object - RWPS-1882
*	 - Prabhat Kumar 2025.09.15 Updated methods parseOrdeItemResponseDetailsTest, parseOrdeItemResponseDetailsTest2 to increase the coverage - RWPS-3811 
*************************************************************/
@isTest
public with sharing class ECOM_OrderCreateAPIUtilTest {
	@testSetup
    static void setup(){
        Map<String,Object> result = ECOM_TestUtil.initialStorefrontSetup();
    }
    
    @isTest
    static void parseOrdeItemResponseDetailsTest(){
        List<OrderItem> orderItems = [SELECT Id,OrderId,ECOM_SAP_Line_Number__c,ECOM_Earliest_Shipping_Date__c,LineNumber, Order.Invoice_Email__c FROM OrderItem LIMIT 10];//RWPS-1882 RWPS-3811
        Order objOrder = [SELECT Id, Invoice_Email__c FROM Order WHERE Id = :orderItems[0].OrderId LIMIT 1];//RWPS-1882 start
        objOrder.Invoice_Email__c = 'abc@example.com';
        update objOrder; //RWPS-1882 end
        
        orderItems[0].ECOM_Earliest_Shipping_Date__c=Date.newInstance(2024, 01, 01);
        String orderId = orderItems[0].OrderId;
        orderItems[0].ECOM_SAP_Line_Number__c = 1.00;//RWPS-3811
        update orderItems[0];
    
        //orderItems=[SELECT Id,ECOM_Earliest_Shipping_Date__c,LineNumber FROM OrderItem LIMIT 10];
        ECOM_OrderSummaryResponseWrapper.OrderResponseDetail request = new ECOM_OrderSummaryResponseWrapper.OrderResponseDetail();
        request.OrderLineNumber='/'+orderItems[0].LineNumber;
        ECOM_OrderSummaryResponseWrapper.ItemDetail resItemDetail = new ECOM_OrderSummaryResponseWrapper.ItemDetail();
        resItemDetail.AvailableQty='10';
        resItemDetail.AvailableDate='2023-12-31';
        request.itemDetail=resItemDetail;
        List<ECOM_OrderSummaryResponseWrapper.OrderResponseDetail> requests = new List<ECOM_OrderSummaryResponseWrapper.OrderResponseDetail>();
        requests.add(request);
        List<Order> orders = ECOM_OrderService.getOrdersById(new set<String>{orderId});
        String contactSAPNumber = 'contactSAPNumber';
        // Changes done by sathiya on 2024.06.11
        User us = new ECOM_UserService().getUserByUser(UserInfo.getUserId()); 
        // Changes End
        
         	List<PaymentAuthorization> payments= ECOM_OrderService.getPaymentAuthorizationBasedOnOrder(orderId);
            List<CardPaymentMethod> cardPayments= ECOM_OrderService.getCardPaymentBasedOnOrder(orderId);
        	// Changes done by sathiya on 2024.06.11
        	ECOM_OrderSummaryRequestWrapper summaryResponse =  ECOM_OrderCreateAPIUtil.generateOrderCreateRequest(orders[0],contactSAPNumber,payments,cardPayments, us);
        	// Changes End
            String body = '{"OrderResponse":{"Error":{"ErrorDetails":[{"errorMessage":"Pleaseentersold-topartyorship-toparty"},{"errorMessage":"Salesdocumentwasnotchanged"}]}}}';
        
            ECOM_MockHttpResponseGenerator mock = new ECOM_MockHttpResponseGenerator(200, 'OK', body, null);
           	Test.setMock(HttpCalloutMock.class, mock);
            Test.startTest();
                HttpResponse response = ECOM_OrderCreateAPIUtil.orderCreateAPICallout(summaryResponse);
                ECOM_OrderSummaryResponseWrapper orderCreateResWrapper = ECOM_OrderCreateAPIUtil.parseOrderCreateResponse(response.getBody());
                ECOM_OrderCreateFlowWrapper.OrdersAndOrderItems orderItemsResponse = ECOM_OrderCreateAPIUtil.parseOrderCreateAPIResponse(summaryResponse, response, orders[0]);
                List<OrderItem> result = ECOM_OrderCreateAPIUtil.parseOrdeItemResponseDetails(orderItems,requests);
        	Test.stopTest();
        
    }
    
    @isTest
    static void testParseOrdeItemResponseDetails() {
        OrderItem orderItem = [SELECT Id,OrderId,ECOM_SAP_Line_Number__c,ECOM_Earliest_Shipping_Date__c,LineNumber FROM OrderItem LIMIT 1];//RWPS-3811
        orderItem.ECOM_SAP_Line_Number__c = 1.00;//RWPS-3811
        update orderItem;
        // Create a mock OrderResponseDetail matching the LineNumber of the OrderItem
        ECOM_OrderSummaryResponseWrapper.OrderResponseDetail orderResponseDetail = new ECOM_OrderSummaryResponseWrapper.OrderResponseDetail();
        orderResponseDetail.OrderLineNumber = '00000207/1';
        ECOM_OrderSummaryResponseWrapper.ItemDetail itemDetail = new ECOM_OrderSummaryResponseWrapper.ItemDetail();
        itemDetail.AvailableDate = '2024-02-01';
        orderResponseDetail.ItemDetail = itemDetail;
        orderResponseDetail.SAPOrderLineNumber = 'SAP12345';
    
        // Prepare input lists
        List<OrderItem> orderItems = new List<OrderItem>{ orderItem };
        List<ECOM_OrderSummaryResponseWrapper.OrderResponseDetail> orderResponseDetails = new List<ECOM_OrderSummaryResponseWrapper.OrderResponseDetail>{ orderResponseDetail };
    
        Test.startTest();
            // Invoke the method
            List<OrderItem> result = ECOM_OrderCreateAPIUtil.parseOrdeItemResponseDetails(orderItems, orderResponseDetails);
        Test.stopTest();
    
        // Assert the results
        System.assertEquals(1, result.size(), 'Expected one OrderItem to be updated');
        OrderItem updatedOrderItem = result[0];
        System.assertEquals(Date.newInstance(2024, 02, 01), updatedOrderItem.ECOM_Earliest_Shipping_Date__c, 'Earliest Shipping Date should be updated');
        System.assertEquals('SAP12345', updatedOrderItem.Line_Item_Number_ERP__c, 'SAP Order Line Number should match');
    }    

    //RWPS-1285
    @isTest
    static void parseOrdeItemResponseDetailsTest2(){
        List<OrderItem> orderItems = [SELECT Id,OrderId,ECOM_SAP_Line_Number__c,ECOM_Earliest_Shipping_Date__c,ECOM_Selected_Shipping_Date__c,LineNumber FROM OrderItem LIMIT 10];//RWPS-3811
        orderItems[0].ECOM_Earliest_Shipping_Date__c=Date.newInstance(2024, 01, 01);
        orderItems[0].ECOM_Selected_Shipping_Date__c=Date.newInstance(2024, 01, 01);
        String orderId = orderItems[0].OrderId;
        orderItems[0].ECOM_SAP_Line_Number__c = 1.00;//RWPS-3811
        update orderItems[0];
    
        //orderItems=[SELECT Id,ECOM_Earliest_Shipping_Date__c,LineNumber FROM OrderItem LIMIT 10];
        ECOM_OrderSummaryResponseWrapper.OrderResponseDetail request = new ECOM_OrderSummaryResponseWrapper.OrderResponseDetail();
        request.OrderLineNumber='/'+orderItems[0].LineNumber;
        ECOM_OrderSummaryResponseWrapper.ItemDetail resItemDetail = new ECOM_OrderSummaryResponseWrapper.ItemDetail();
        resItemDetail.AvailableQty='10';
        resItemDetail.AvailableDate='2023-12-31';
        request.itemDetail=resItemDetail;
        List<ECOM_OrderSummaryResponseWrapper.OrderResponseDetail> requests = new List<ECOM_OrderSummaryResponseWrapper.OrderResponseDetail>();
        requests.add(request);
        List<Order> orders = ECOM_OrderService.getOrdersById(new set<String>{orderId});
        orders[0].PoNumber = 'TestPO';
        update orders[0];
        String contactSAPNumber = 'contactSAPNumber';
        // Changes done by sathiya on 2024.06.11
        User us = new ECOM_UserService().getUserByUser(UserInfo.getUserId()); 
        // Changes End
        
         	List<PaymentAuthorization> payments= ECOM_OrderService.getPaymentAuthorizationBasedOnOrder(orderId);
             payments[0].ECOM_Authorization_Number__c='2432';
             payments[0].ECOM_PG_Transaction_Id__c='2432';
             payments[0].ECOM_Authorization_Type__c='cc';
             payments[0].ECOM_PG_Return_Description__c='sf';
             payments[0].ECOM_Merchant_Id__c='24342332';
             payments[0].ECOM_Payment_Method_Token__c='tesdtt';
             update payments[0];
            List<CardPaymentMethod> cardPayments= ECOM_OrderService.getCardPaymentBasedOnOrder(orderId);
        	// Changes done by sathiya on 2024.06.11
        	ECOM_OrderSummaryRequestWrapper summaryResponse =  ECOM_OrderCreateAPIUtil.generateOrderCreateRequest(orders[0],contactSAPNumber,payments,cardPayments, us);
        	// Changes End
            String body = '{"OrderResponse":{"Error":{"ErrorDetails":[{"errorMessage":"Pleaseentersold-topartyorship-toparty"},{"errorMessage":"Salesdocumentwasnotchanged"}]}}}';
        
            ECOM_MockHttpResponseGenerator mock = new ECOM_MockHttpResponseGenerator(200, 'OK', body, null);
           	Test.setMock(HttpCalloutMock.class, mock);
            Test.startTest();
                HttpResponse response = ECOM_OrderCreateAPIUtil.orderCreateAPICallout(summaryResponse);
                ECOM_OrderSummaryResponseWrapper orderCreateResWrapper = ECOM_OrderCreateAPIUtil.parseOrderCreateResponse(response.getBody());
                ECOM_OrderCreateFlowWrapper.OrdersAndOrderItems orderItemsResponse = ECOM_OrderCreateAPIUtil.parseOrderCreateAPIResponse(summaryResponse, response, orders[0]);
                List<OrderItem> result = ECOM_OrderCreateAPIUtil.parseOrdeItemResponseDetails(orderItems,requests);
        	Test.stopTest();
        
    }
    
}