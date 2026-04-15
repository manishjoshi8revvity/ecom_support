/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-109
*
* 2. Description - This class is used for Order specific transactions.
*
* 3. Objects referenced
*    - Order
* 	 - Order Item
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
* 5. Dependant Class(es):
*    - ECOM_OrderRepo
*	 - ECOM_OrderUtil
*
* 6. Test Class Name: 
*    - ECOM_OrderService_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Rani 2023.08.16
*    - Vipul Goyal 2024.05.06 - Added getOrdersForApproval,getOrdersForApprovalCount.(ECOM-103)
*    - Sachin Vispute 2025.10.28 Added method getOnlineOrders - RWPS-4881
*    - Sachin Vispute 2025.11.26 Modified method getOnlineOrders - RWPS-5094
*************************************************************/
public with sharing class ECOM_OrderService implements ECOM_IOrderService {
    
    public static String CLASSNAME = 'ECOM_OrderService';
    
    /**
    * this method is used to get Orders by order id
    * @param orderIds
    * @return  List<Order>
    * @author Rani Thumma | 2023-09-09
    */
    public static List<Order> getOrdersById(Set<String> orderIds){
         List<Order> orders = new List<Order>();
        if(orderIds != null && orderIds.size() > 0){
            orders = ECOM_OrderRepo.getOrdersById(orderIds);
        }
        return orders;
    }
    
    /**
    * this method is get order for the logged in user
    * @param 
    * @return  List<Order> 
    * @author Rani Thumma | 2023-09-09
    */
    public static List<Order> getMyOrders() {
        List<Order> orderList = ECOM_OrderRepo.getMyOrders();
        return orderList;
    }

    /**
    * this method fecthes online/Salesforce orders for the logged in user
    * RWPS-4881
    * @param seachString
    * @return  List<Order>
    * @author Sachin V | 2025-10-28
    */
    public static List<Order> getOnlineOrders(String seachString, User user, Boolean isPunchoutUser, List<String> orderTypesList, List<String> poTypesList) {
        List<Order> orderList = ECOM_OrderRepo.getOnlineOrders(seachString, user, isPunchoutUser, orderTypesList, poTypesList); //RWPS-5094
        return orderList;
    }

    /**
    * this method is to prepare Order Model from order SObject record
    * @param orderId
    * @return  ECOM_OrderModel
    * @author Rani Thumma | 2023-09-09
    */
    public static ECOM_OrderModel getOrderDetails(Id orderId) {
        List<Order> orderList = ECOM_OrderRepo.getOrderDetails(orderId);
        ECOM_OrderModel order = ECOM_OrderUtil.getOrderDetails(orderList);
        return order;
    }
    /**
    * this method is used to get Orders by sap Order Ids
    * @param sapOrderIds
    * @return  List<Order>
    * @author Rani Thumma | 2023-09-09
    */
    public static List<Order> getOrdersBySAPOrderId(Set<String> sapOrderIds){
        List<Order> orders = ECOM_OrderRepo.fetchOrdersBySAPOrderId(sapOrderIds);
        return orders;
    }
    
    /**
    * this method is used to update orders
    * @param orders
    * @return  
    * @author Rani Thumma | 2023-09-09
    */
    public static void updateOrders(List<Order> orders){
        ECOM_OrderRepo.updateOrders(orders);
    }
    
    /**
    * this method is used to update order Items
    * @param orderItems
    * @return  
    * @author Rani Thumma | 2023-09-09
    */
    public static void updateOrderItems(List<OrderItem> orderItems){
        ECOM_OrderRepo.updateOrderItems(orderItems);
    }

    /**
    * this method is search for ORder based on order number and Zipcode
    * @param orderNumber,zipCode
    * @return  List<OrderSummary>
    * @author Rani Thumma | 2023-09-09
    */
    public static List<Order> findOrderByOrderNumberAndZip(String orderNumber, String zipCode) {
        List<Order> orderSummaryList = ECOM_OrderRepo.findOrderByOrderNumberAndZip(orderNumber, zipCode);
        return orderSummaryList;
    }

    /**
    * this method is used to validate if the PO is previously used based on account id and PO Number
    * @param effectiveAccountId,poNumber
    * @return  List<Order>
    * @author Manish  | 2023-08-10
    */
    public static List<Order> checkIfPoUsed(String effectiveAccountId, String poNumber){
        return ECOM_OrderRepo.checkIfPoUsed(effectiveAccountId, poNumber);
    }
    
    /**
    * this method is used to fetch OrderDeliveryMethod by name
    * @param methodName
    * @return  List<OrderDeliveryMethod>
    * @author Rani Thumma | 2023-09-09
    */
    public static List<OrderDeliveryMethod> getOrderDeliveryMethods(String methodName){
        return ECOM_OrderRepo.getOrderDeliveryMethods(methodName);
    }
    
    /**
    * this method is used to fetch OrderDeliveryMethod by Id
    * @param methodId
    * @return  List<OrderDeliveryMethod>
    * @author Rani Thumma | 2023-09-09
    */
    public static List<OrderDeliveryMethod> getOrderDeliveryMethodsById(String methodId){
       return ECOM_OrderRepo.getOrderDeliveryMethodsById(methodId);
    }
	/**
    * this method is used to prepare order and Order item details
    * @param formWrapper,orderItemId
    * @return  ECOM_FormWrapper.FormWrapper
    * @author Vipul | 2023-09-20
    */
    public static ECOM_FormWrapper.FormWrapper setupOrderItemDetails(ECOM_FormWrapper.FormWrapper formWrapper,String orderItemId)
    {
        OrderItem orderItem= ECOM_OrderRepo.getOrderItemBasedOnId(orderItemId);


        if(String.isNotBlank(orderItem.Order.Default_Ship_to_ERP_Address__c) && String.isNotBlank(orderItem.Order.Default_Ship_to_ERP_Address__r.Account__c) 
        && String.isNotBlank(orderItem.Order.Default_Ship_to_ERP_Address__r.Account__r.Name))
        {
            formWrapper.companyName=orderItem.Order.Default_Ship_to_ERP_Address__r.Account__r.Name;
        }

        formWrapper.Address=ECOM_OrderUtil.setupAddressData(orderItem);
        formWrapper.Order=ECOM_OrderUtil.setupOrderData(orderItem);
        return formWrapper;
    }
	/**
    * this method is used to fetch Order Items by Id
    * @param orderItemId
    * @return  OrderItem
    * @author Rani Thumma | 2023-09-09
    */
    public static OrderItem getOrderItemBasedOnId(String orderItemId)
    {
        OrderItem orderItem= ECOM_OrderRepo.getOrderItemBasedOnId(orderItemId);
        return  orderItem;
    }

    

    public static Boolean anyOrderWithBillingCPA(String cpaId)
    {
        List<Order> orders=ECOM_OrderRepo.getOrderBasedOnOwnerAndCpa(cpaId);
        return orders.isEmpty()?false:true;
    }
	// Changes done by sathiya for ECOM-1939 on 05/16/2024
    public static Boolean checkOrders( List<String> shipToErpIds,List<String> billToErpIds, List<String> invoiceErpIds){
        Boolean orders=false;
        if(!shipToErpIds.isEmpty() || !billToErpIds.isEmpty() || !invoiceErpIds.isEmpty()){
            orders = (ECOM_OrderRepo.getOrderBasedOnOwnerByErpAddressTypes(shipToErpIds, billToErpIds, invoiceErpIds, userInfo.getUserId())).isEmpty()?false:true;
        }
        // Commenting out the redundant calls
        /*
        if(!shipToErpIds.isEmpty() && !billToErpIds.isEmpty())
        {
            orders=(ECOM_OrderRepo.getOrderBasedOnOwnerShipToAndBillTo(shipToErpIds,billToErpIds)).size()>0?true:false;
        }
        else if(!shipToErpIds.isEmpty())
        {
            orders=(ECOM_OrderRepo.getOrderBasedOnOwnerAndShipTo(shipToErpIds)).size()>0?true:false;
        }
        else if(!billToErpIds.isEmpty())
        {
            orders=(ECOM_OrderRepo.getOrderBasedOnOwnerAndBillTo(billToErpIds)).size()>0?true:false;
        }
		*/
        return orders;
    }
    // changes End

    /**
    * @description This method is used to get Card Payment Method records related to the Order Id, which was created during checkout.
    * @author Manish Kumar | 10-20-2023 
    * @param orderId 
    * @return List<CardPaymentMethod>
    **/
    public static List<CardPaymentMethod> getCardPaymentBasedOnOrder(String orderId)
    {
        return ECOM_OrderRepo.getCardPaymentBasedOnOrder(orderId);
    }
    
    /**
    * @description This method is used to get PaymentAuthorization records related to the Order Id, which was created during checkout.
    * @author Manish Kumar | 10-20-2023 
    * @param orderId 
    * @return List<PaymentAuthorization>
    **/
    public static List<PaymentAuthorization> getPaymentAuthorizationBasedOnOrder(String orderId)
    {
        return ECOM_OrderRepo.getPaymentAuthorizationBasedOnOrder(orderId);
    }

    /**
    * @description This method is used to create Card Payment Method record during checkout.
    * @author Manish Kumar | 10-20-2023 
    * @param cpm 
    **/
    public static void createCardPaymentForOrder(CardPaymentMethod cpm)
    {
        ECOM_OrderRepo.createCardPaymentForOrder(cpm);
    }

    /**
    * @description This method is used to update Card Payment Method record during checkout.
    * @author Manish Kumar | 11-08-2023 
    * @param cpm 
    **/
    public static void updateCardPaymentForOrder(CardPaymentMethod cpm)
    {
        ECOM_OrderRepo.updateCardPaymentForOrder(cpm);
    }

    /**
    * @description This method is used to create Payment Authorization record during checkout.
    * @author Manish Kumar | 10-20-2023 
    * @param pa
    **/
    public static void createPaymentAuthorizationForOrder(PaymentAuthorization pa)
    {
        ECOM_OrderRepo.createPaymentAuthorizationForOrder(pa);
    }

    /**
    * @description This method is used to update Payment Authorization record during checkout.
    * @author Manish Kumar | 11-08-2023 
    * @param pa
    **/
    public static void updatePaymentAuthorizationForOrder(PaymentAuthorization pa)
    {
        ECOM_OrderRepo.updatePaymentAuthorizationForOrder(pa);
    }
    
    /**
    * @description This method is used to create order summary
    * @author Rani Thumma | 11-09-2023 
    * @param orderSummaryInput
    * @retrun ConnectApi.OrderSummaryOutputRepresentation
    **/
    public static ConnectApi.OrderSummaryOutputRepresentation createOrderSummary(ConnectApi.OrderSummaryInputRepresentation orderSummaryInput)
    {
        return ECOM_OrderRepo.createOrderSummary(orderSummaryInput);
    }
    
    /**
    * @description This Method returns the List of orders mapped to model object
    * @author vramachandran@rafter.one | 12 Dec 2023
    * @return List<Order> 
    */
    public List<ECOM_OrderModel> getMyOrdersModel() {
        List<Order> orderList = ECOM_OrderRepo.getMyOrders();
        List<ECOM_OrderModel> orderModelList = ECOM_OrderUtil.getOrderModelList(orderList);
        
        return orderModelList;
    }


    /**
    * @description Method to retrieve orders that are approved or pending for approval.
    * @author Vipul Goyal | 05-06-2024 
    * @param userId 
    * @param userEmail 
    * @return List<Order> 
    **/
    public static List<Order> getOrdersForApproval(String userId,String userEmail)
    {
        return ECOM_OrderRepo.getOrdersForApproval(userId,userEmail);
    }

     /**
    * @description Method to retrieves the order count that are approved,rejected or pending for approval.
    * @author Vipul Goyal | 05-06-2024 
    * @param userId 
    * @param userEmail 
    * @return Integer 
    **/
    public static Integer getOrdersForApprovalCount(String userId,String userEmail)
    {
        return ECOM_OrderRepo.getOrdersForApprovalCount(userId,userEmail);
    }

}