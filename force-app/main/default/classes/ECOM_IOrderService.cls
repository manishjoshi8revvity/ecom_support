/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM- 125
*	 ECOM- 116
*    ECOM- 118
*
* 2. Description - This class is used for Order specific transactions.
*
* 3. Objects referenced
*    - Order 
*    - Order Item
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
* 5. Dependant Class(es):
*    - ECOM_OrderSyncFlowController
*
* 6. Test Class Name: ECOM_OrderService_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Rani 2023.08.16
* 	 - vramachandran@rafter.one | 11 Dec 2023
*************************************************************/
public interface ECOM_IOrderService {
    
    List<Order> getOrdersById(Set<String> orderIds);
    //Map<String, String> orderHold(List<String> orderIds);
    List<Order> getOrdersBySAPOrderId(Set<String> sapOrderIds);
    void updateOrders(List<Order> orders);
    void updateOrderItems(List<OrderItem> orderItems);
    List<OrderDeliveryMethod> getOrderDeliveryMethods(String methodName);
    List<OrderDeliveryMethod> getOrderDeliveryMethodsById(String methodId);
    List<CardPaymentMethod> getCardPaymentBasedOnOrder(String orderId);
    List<PaymentAuthorization> getPaymentAuthorizationBasedOnOrder(String orderId);
    ConnectApi.OrderSummaryOutputRepresentation createOrderSummary(ConnectApi.OrderSummaryInputRepresentation orderSummaryInput);
    List<ECOM_OrderModel> getMyOrdersModel();//VRa-punchout changes

}