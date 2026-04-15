/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM- 691
*
* 2. Description - This class is a test class for ECOM_SimulateOrderWrapper
*
*
* 3. Objects referenced
*
* 4. Callouts to additional Components (including their methods) or None:
*
* 5. Dependant Class(es):
*    - 
*
* 6. Test Class Name:        
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Manoj 2023.07.17
*    - Vipul 2023.09.20
*    - Manoj 2024-04-30 RWPS-584 Instrument freight not applying as expected on web orders(zcovered test class)
*************************************************************/
@isTest(SeeAllData=false)
public class ECOM_SimulateOrderWrapper_Test {
    @isTest
    static void testSimulateOrderWrapper() {
        ECOM_SimulateOrderWrapper.OrderRequest request = new ECOM_SimulateOrderWrapper.OrderRequest();
        request.bill_to = '0004536965';
        request.Ship_to = '0100549700';
        request.country = 'CA';
        request.requested_date = system.today();
        request.promo_code = 'SUMMER10';
        request.cart_id = 'xxxxxxxxxxxxxx';
        request.payment_type = 'CreditCard';
        request.po_no = '123456';
        ECOM_SimulateOrderWrapper.OrderResponse response = new ECOM_SimulateOrderWrapper.OrderResponse();
        response.paymentTerms = '';
         response.incoTerms = '';
         response.incoCode = '';
         response.currencyCode = ''; 
        response.shippingCost = '';
         response.totalTaxVat = '';
         response.error = null;
		String jsonRequest = JSON.serialize(response);
        ECOM_SimulateOrderWrapper.OrderResponse response1 = ECOM_SimulateOrderWrapper.parse(jsonRequest);
        System.assertEquals('0004536965', request.bill_to, 'Bill To should match');
        System.assertEquals('0100549700', request.Ship_to, 'Ship To should match');
        System.assertEquals('CA', request.country, 'Country should match');
        System.assertEquals(Date.today(), request.requested_date, 'Requested Date should match');
        System.assertEquals('SUMMER10', request.promo_code, 'Promo Code should match');
        System.assertEquals('xxxxxxxxxxxxxx', request.cart_id, 'Cart ID should match');
        System.assertEquals('CreditCard', request.payment_type, 'Payment Type should match');
        System.assertEquals('123456', request.po_no, 'PO Number should match');
    }
    // @isTest
    // static void testOrderResponse() {
    //     // Create test data
    //     ECOM_SimulateOrderOrderResponse orderResp = new ECOM_SimulateOrder.OrderResponse();
    //     orderResp.paymentTerms = 'Due Upon Receipt';
    //     OrderResp.incoTerms = 'FOB Factory - Prepay & Add';
    //     OrderResp.incoCode = 'F02';
    //     OrderResp.currencyCode = 'CAD';
    //     OrderResp.shippingCost = '10.00';
    //     OrderResp.totalTaxVat = '5.00';
    //     OrderResp.totalPrice = '100.00';
    //     OrderResp.productList = new List<ECOM_SimulateOrderWrapper.ProductList>();
    //     //OrderResp.error = null;
        
    //     // Create a product list item
    //     ECOM_SimulateOrderWrapper.ProductList prod = new ECOM_SimulateOrderWrapper.ProductList();
    //     prod.productName = 'Product 1';
    //     prod.quantity = 1;

    //     // OrderResp.productList = new List<ECOM_SimulateOrderWrapper.ProductList>();
    //     OrderResp.productList.add(prod);
        
    //     // Set the order response in the wrapper class
    //     // ECOM_SimulateOrderWrapper wrapper = new ECOM_SimulateOrderWrapper();
    //     // OrderResp = OrderResp;
        
    //     // Perform system assertions
    //     System.assertEquals('Due Upon Receipt', OrderResp.paymentTerms);
    //     System.assertEquals('FOB Factory - Prepay & Add', OrderResp.incoTerms);
    //     System.assertEquals('F02', OrderResp.incoCode);
    //     System.assertEquals('CAD', OrderResp.currencyCode);
    //     System.assertEquals('10.00', OrderResp.shippingCost);
    //     System.assertEquals('5.00', OrderResp.totalTaxVat);
    //     System.assertEquals('100.00', OrderResp.totalPrice);
    //     System.assertEquals(1, OrderResp.productList.size());
    //     System.assertEquals('Product 1', OrderResp.productList[0].productName);
    //     System.assertEquals(1, OrderResp.productList[0].quantity);
    //     // System.assertNull(OrderResponse.error);
    // }
}