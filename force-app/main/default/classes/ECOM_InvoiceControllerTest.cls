/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-112
*
* 2. Description - This is the test class for ECOM_InvoiceController
*
* 3. Objects referenced
*    - Invoice
*	 - Case
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
* 5. Dependant Class(es):
* 	 - ECOM_InvoiceController
*	
* 6. Test Class Name: 
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Gaurang 2024.12.05
*************************************************************/
@isTest
public class ECOM_InvoiceControllerTest {
    
    @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
    }
    
    @isTest
    static void getInvoiceAndOrderDetailsTest(){
        Order testOrder = [SELECT Id,ECOM_SAP_Order_Number__c,Status  FROM Order ORDER BY CreatedDate DESC LIMIT 1];
        testOrder.ECOM_SAP_Order_Number__c = '2243';
        testOrder.Status = 'Shipped';
        //testOrder.Status = 'Order Confirmed';
        update testOrder;
        ECOM_Invoice__c testInvoice = new ECOM_Invoice__c();
        testInvoice.ECOM_Order__c = testOrder.Id;
        insert testInvoice;
        
        ECOM_InvoiceLine__c testInvoiceLine = new ECOM_InvoiceLine__c();
        testInvoiceLine.ECOM_Invoice__c = testInvoice.Id;
        testInvoiceLine.ECOM_Quantity__c = 1;
        insert testInvoiceLine;
        
        ECOM_OrderModel ordmodel = new ECOM_OrderModel();
        Test.startTest();
        Map<String, Object> orderDetailsMap = ECOM_InvoiceController.getInvoiceAndOrderDetails(testOrder.Id,testInvoice.Id);
        ordmodel = (ECOM_OrderModel) orderDetailsMap.get('orderModel');
        Test.stopTest();
        System.assertnotEquals(null,ordmodel,'expected order should not be null');
    }
    
    @isTest
    static void getInvoiceAndOrderDetailsTestCase2(){
        Order testOrder = [SELECT Id,ECOM_SAP_Order_Number__c,Status  FROM Order ORDER BY CreatedDate DESC LIMIT 1];
        testOrder.ECOM_SAP_Order_Number__c = '2243';
        testOrder.Status = 'Shipped';
        //testOrder.Status = 'Order Confirmed';
        update testOrder;
		SAP_Order_Summary__c order = new SAP_Order_Summary__c();
        insert order;
        SAP_Order_Items__c testItem = new SAP_Order_Items__c();
        testItem.PKI_Order_Summary__c = order.Id;
        testItem.Net_Price__c=10;
        testItem.Quantity_Ordered__c=10;
        insert testItem;
        ECOM_Invoice__c testInvoice = new ECOM_Invoice__c();
        testInvoice.ECOM_SAP_Order_Summary__c = order.Id;
        insert testInvoice;
        
        ECOM_InvoiceLine__c testInvoiceLine = new ECOM_InvoiceLine__c();
        testInvoiceLine.ECOM_Invoice__c = testInvoice.Id;
        insert testInvoiceLine;
        
        ECOM_OrderModel ordmodel = new ECOM_OrderModel();
        Test.startTest();
        Map<String, Object> orderDetailsMap = ECOM_InvoiceController.getInvoiceAndOrderDetails(testOrder.Id,testInvoice.Id);
        ordmodel = (ECOM_OrderModel) orderDetailsMap.get('orderModel');
        Test.stopTest();
        System.assertnotEquals(null,ordmodel,'expected order should not be null');
    }
    
    @isTest
    static void submitCaseTest(){
        Map<String,Object> response  = new Map<String,Object>();
        response.put('salesOrg','test');
        response.put('subject','Need Help');
        response.put('notes','test');
        response.put('InvoiceNumber','test');
        Map<String,Object> response1  = new Map<String,Object>();
        response1.put('salesOrg','test');
        response1.put('subject','test');
        response1.put('notes','test');
        response1.put('InvoiceNumber','test');
        test.startTest();
        response = ECOM_InvoiceController.submitCase(response);
        response1 = ECOM_InvoiceController.submitCase(response1);
        ECOM_InvoiceController.submitCase(new Map<String, Object>());
        test.stopTest();
        system.assertEquals('Success',response.get('Status'),'Unexpected status');
    }
    
    @isTest
    static void getInvoiceTest(){
        ECOM_Invoice__c testInvoice = new ECOM_Invoice__c();
        insert testInvoice;
        
        List<ECOM_Invoice__c> response  = new List<ECOM_Invoice__c>();
        test.startTest();
        response = ECOM_InvoiceController.getInvoice(testInvoice.Id);
        test.stopTest();
        system.assertEquals(testInvoice.Id,response[0].Id,'Unexpected Id');
    }
    
    @isTest
    static void invoicePDFCallTest(){
        ECOM_Invoice__c testInvoice = new ECOM_Invoice__c();
        testInvoice.ECOM_URL_Generated_Time__c = Datetime.now()-5;
        testInvoice.ECOM_Download_URL__c = 'test';
        testInvoice.ERP_Invoice_Number__c = 'test121';
        insert testInvoice;
        ECOM_InvoicePDFWrapper.Request invoiceMap = new ECOM_InvoicePDFWrapper.Request();
        invoiceMap.invoiceId = testInvoice.Id;
        invoiceMap.salesOrg = 'US10';
        invoiceMap.invoiceNumber = 'test121';
        Map<String,Object> response = new Map<String,Object>();
        ECOM_InvoicePDFWrapper.Response responseMock = new ECOM_InvoicePDFWrapper.Response();
        responseMock.message = 'Success';
        responseMock.url='testurl';
        responseMock.code='200';
        Test.setMock(HttpCalloutMock.class, new ECOM_MockHttpResponseGenerator(200, 'OK', JSON.serialize(responseMock), null));
        test.startTest();
        response = ECOM_InvoiceController.invoicePDFCall(invoiceMap);
        response = ECOM_InvoiceController.invoicePDFCall(null);
        test.stopTest();
        //system.assertEquals('Success',response.get('Status'),'Unexpected result');
    }

}