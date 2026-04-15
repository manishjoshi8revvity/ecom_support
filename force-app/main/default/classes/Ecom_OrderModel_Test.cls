/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-109
*
* 2. Description - This class is used for creating Order & Order Items model
*
* 3. Objects referenced
*    - Order
*    - OrderItem
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
* 5. Dependant Class(es):
* 6. Main Class Name: Ecom_OrderModel
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Manoj 2023.11.07
*    - Sidak 2024.12.12 Added method testModel
*************************************************************/
@isTest
private class Ecom_OrderModel_Test {

    // Create a test method to test the parse method
    static testMethod void testParse() {
        // Create a sample JSON string
        String json = '{"status": "Pending", "accountId": "001XXXXXXXXXXXXXXX", "accountName": "Test Account", ' +
                     '"accountNumber": "ACC123","approvalRejectionComment":"Test", "poNumber": "PO123", "orderNumber": "ORD123", ' +
                     '"totalAmount": 100.0, "grandTotalAmount": 105.0, "totalProdAmount": 90.0, ' +
                     '"totalShippingAmount": 15.0, "ownerId": "005XXXXXXXXXXXXXXX", "createdById": "005YYYYYYYYYYYYYYY", ' +
                     '"totalTaxAmount": 5.0, "totalSavings": 10.0, "id": "006ZZZZZZZZZZZZZZZZ", ' +
                     '"currencyIsoCode": "USD", "isSapOrder": false, "shippingInstructions": "Handle with care", ' +
                     '"attentionRecipient": "John Doe", "quoteNumber": "QUO456", ' +
                     '"salesStoreId": "STORE123", "sapOrderNumber": "SAPORD123", ' +
                     '"createdDate": "2023-11-07T10:00:00Z", ' +
                     '"billingAddress": {"street": "123 Main St", "city": "Anytown", ' +
                     '"state": "CA", "postalCode": "12345", "country": "USA"}, ' +
                     '"shippingAddress": {"street": "456 Elm St", "city": "Othertown", ' +
                     '"state": "NY", "postalCode": "54321", "country": "USA"}, ' +
                     '"orderItems": [{"unitPrice": 20.0, "type": "Product", "product2Id": "02iXXXXXXXXXXXXXXX", ' +
                     '"description": "Product Description", "totalPrice": 40.0, "totalLineAmount": 40.0, ' +
                     '"quantity": 2.0, "id": "01XXXXXXXXXXXXXXX", "orderId": "06XXXXXXXXXXXXXXX", ' +
                     '"listPrice": 25.0, "earliestShippingDate": "2023-11-10", ' +
                     '"selectedShippingDate": "2023-11-12", "status": "Shipped", ' +
                     '"itemTrackings": [{"OrderItemId": "01XXXXXXXXXXXXXXX", "OrderSummaryId": "06XXXXXXXXXXXXXXX", ' +
                     '"carrierName": "UPS", "trackingDate": "2023-11-11", ' +
                     '"trackingNumber": "1234567890", "trackingURL": "https://example.com/tracking", ' +
                     '"quantityShipped": 1.0, "partNumber": "PART123", ' +
                     '"productName": "Product Name", "quantityOrdered": 2.0}]}]}';

        Test.startTest();
        ECOM_OrderModel result = ECOM_OrderModel.parse(json);
        Test.stopTest();

        // Assert the expected result
        System.assertEquals('Pending', result.status);
        System.assertEquals('001XXXXXXXXXXXXXXX', result.accountId);
        System.assertEquals('Test Account', result.accountName);
        
    }
    
    /**
    * @description This method is used to cover ECOM_OrderModel.Invoice & ECOM_OrderModel.OrderItemTracking
    * @author Sidak | 2024.12.12 
    **/
    static testMethod void testModel(){
        ECOM_OrderModel.Invoice inv = new ECOM_OrderModel.Invoice();
        inv.Id = '0a1xxxxxxxxxxx';
        inv.name = 'Test Invoice';
        inv.invoiceDate = System.today();
        inv.totalItems = 1.0;
        inv.currencyIsoCode = 'USD';
        inv.subtotal = 10.0;
        inv.tax = 1.0;
        inv.total = 11.0;
        inv.downloadUrl = 'www.testinvoice.com';
        inv.invoiceNumber = '12345';
        inv.isPDFEnabled = false;
        
        ECOM_OrderModel.OrderItemTracking oit = new ECOM_OrderModel.OrderItemTracking();
		oit.OrderItemId = '0a1xxxxxxxxxxx';
        oit.OrderSummaryId = '0a1xxxxxxxxxxx';
        oit.carrierName = 'Test carrier';
        oit.trackingDate = System.today();
        oit.trackingNumber = '123456789';
        oit.trackingURL = 'www.testtracking.com';
        oit.quantityShipped = 1.0;
        oit.partNumber = '12345';
        oit.productName = 'Test product';
        oit.productMediaURI = '/test-product';
		oit.quantityOrdered = 1.0;
        oit.orderItem = 'Test product';

    }	
}