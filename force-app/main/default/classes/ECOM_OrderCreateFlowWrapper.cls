/**************************************************************
 * 1. Ticket(s) that relates to this class
 * - ECOM - 125
 * 
 * 2. Description - It is a wrapper class used in Order Create API flow.
 *					
 *
 * 3. Objects referenced
 * - Order
 * - Order Products
 *
 * 4. Callouts to additional Components (including their methods) or None:
 * - None
 *
 * 5. Dependant Class(es):
 * 		- ECOM_OrderCreateFlowController
 * 		- ECOM_OrderCreateAPIUtil
 * 		- ECOM_OrderCreateBatch
 *
 * 6. Test Class Name: 
 *
 * 7. Is @Invocable (Yes or No): Yes
 *
 * 8. Author Name(s): 
 * - Rani Thumma 2023.09.12
*************************************************************/ 
public class ECOM_OrderCreateFlowWrapper {
    
    public class Request{
        @InvocableVariable
        public String orderId;
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