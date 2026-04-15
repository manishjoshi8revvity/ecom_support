/**************************************************************
 * 1. Ticket(s) that relates to this class
 * - ECOM - 110
 * - ECOM - 806
 * 
 * 2. Description - It is a wrapper class used in Order Sync flow.
 *					
 *
 * 3. Objects referenced
 * - SAP Order Summary
 * - SAP Order Items
 * - Order
 * - Order Products
 *
 * 4. Callouts to additional Components (including their methods) or None:
 * - None
 *
 * 5. Dependant Class(es):
 *		- ECOM_OrderSyncFlowWrapper
 *
 * 6. Test Class Name: 
 *
 * 7. Is @Invocable (Yes or No): Yes
 *
 * 8. Author Name(s): 
 * - Rani Thumma 2023.09.12
 *
*************************************************************/ 
public class ECOM_OrderSyncFlowWrapper {
    
    public class Request{
        @InvocableVariable
        public String sapOrderSummaryId;
    }
    
    Public class Response{
        @InvocableVariable
        public String orderId;
        @InvocableVariable
        public Boolean success;
    }
    
    public class OrdersAndOrderItems{
        public List<Order> orders;
        public List<OrderItem> orderItems;
    }

}