/**************************************************************
 * 1. Ticket(s) that relates to this class
 * - ECOM - 125
 * 
 * 2. Description - It is a Controller class used in Order Create API flow.
 *					
 *
 * 3. Objects referenced
 * 		- Order
 * 		- Order Products
 *
 * 4. Callouts to additional Components (including their methods) or None:
 * 		- None
 *
 * 5. Dependant Class(es):
 * 		- ECOM_OrderCreateFlowWrapper
 * 		- ECOM_OrderCreateAPIUtil
 *
 * 6. Test Class Name: 
 *      - ECOM_OrderCreateFlowController_Test
 *
 * 7. Is @Invocable (Yes or No): Yes
 *
 * 8. Author Name(s): 
 * - Rani Thumma 2023.09.12
 * - Manoj 2024.05.03 RWPS-553 Sending Contact ID to SAP
 * - Manoj 2024-05-06 RWPS-622 Hide Availability date when the Order contains an Instrument(Updated Order type logic)
 * - Sathiya 2024.06.11 changes done per the dependent method structure change generateOrderCreateRequest
 * - Manoj 2024.06.25 RWPS-553 Sending Contact ID to SAP
 * - Manoj 2024.07.25 RWPS-1146 If No SAP contact id available order on hold flag bnot setting to true
 * - Manoj 2024.08.27 RWPS-1287 Need a notification for order types other than ZWCC & ZWEB 
 * - Sidak 2024.12.18 Added check for DML statements before callout. RWPS-2185
 * - Mahesh 2025.06.16 RWPS-3387 Removed sendNotification logic with flow
*************************************************************/ 
public class ECOM_OrderCreateFlowController {

    public static String CLASSNAME = 'ECOM_OrderCreateFlowController';
    /**
    * this method is used to get the request from flow 'SUB.FLOW_4452: ECOM - ' and sends it to service class for further processing.
    * @param request List<ECOM_OrderCreateFlowWrapper.Request>
    * @return List<ECOM_OrderCreateFlowWrapper.Response>
    * @author Rani Thumma | 2023-09-13
    */
    @InvocableMethod(Label='Order Create API' Category='Order Create' Description='This is to Create Order in SAP')
    public static List<ECOM_OrderCreateFlowWrapper.Response> processSAPOrderDetails(List<ECOM_OrderCreateFlowWrapper.Request> oderRequest) {
        Set<String> orderIds = new Set<String>();
        String supportData = '';
        List<Order> ordersToUpdate = new List<Order>();
        List<OrderItem> orderItemsToUpdate = new List<OrderItem>();
        List<ECOM_OrderCreateFlowWrapper.Response> response = new List<ECOM_OrderCreateFlowWrapper.Response>();
        try {
            supportData = JSON.serialize(oderRequest);
            
            Type orderService = Type.forName(ECOM_Constant.ORDER_SERVICE);
            ECOM_IOrderService orderServiceInstance = (ECOM_IOrderService)orderService.newInstance();
            orderIds.add(oderRequest[0].orderId);
            List<Order> orders = orderServiceInstance.getOrdersById(orderIds);
            List<PaymentAuthorization> payments;
            List<CardPaymentMethod> cardPayments;
            
            if(orders != null && orders.size() > 0){
                //RWPS-553 added condition of SAP_Contact_ID__c
                String contactSAPNumber = orders[0].SAP_Contact_ID__c;
                // fetch SAP Contact number from ERP relationships
                Type erpAddressService = Type.forName(ECOM_Constant.ERP_ADDRESS_SERVICE);
                User us = new ECOM_UserService().getUserByUser(String.valueOf(orders[0].OwnerId)); 
                //RWPS-553 commented code
                ERP_IAddressService erpAddressServiceInstance = (ERP_IAddressService)erpAddressService.newInstance();
                List<ERP_RelationShip__c> erpRelationships = erpAddressServiceInstance.fetchERPRelationshipsByERPAddress(us.ContactId, String.valueOf(orders[0].Default_Ship_to_ERP_Address__r.Target_Address__c));
                if(erpRelationships != null && erpRelationships.size() > 0 && String.IsBlank(contactSAPNumber)){
                    contactSAPNumber = erpRelationships[0].ERP_Contact_ID__c;
                }
                // Put order on hold if contactSAPNumber is null
                if(orders[0].ECOM_SAP_Order_Number__c == null && String.IsNotBlank(contactSAPNumber) && (orders[0].Status == 'Draft' || orders[0].Status == 'Approved') && orders[0].ECOM_Order_On_Hold__c == false &&(orders[0].ECOM_Order_Create_Retry__c == null || orders[0].ECOM_Order_Create_Retry__c < 5 )){
                    // fetch credit card payment details if PO Number is empty
                    if(orders[0].PoNumber == null){
                        payments = orderServiceInstance.getPaymentAuthorizationBasedOnOrder(String.valueOf(orders[0].Id));
                        cardPayments = orderServiceInstance.getCardPaymentBasedOnOrder(String.valueOf(orders[0].Id));
                    }
                    // Changes done by sathiya on 2024.06.11
                    ECOM_OrderSummaryRequestWrapper orderRequest = ECOM_OrderCreateAPIUtil.generateOrderCreateRequest(orders[0], contactSAPNumber, payments, cardPayments, us);
                    // Changes End
                    
                    if(Limits.getDMLStatements() == 0 || Test.isRunningTest()){ //RWPS-2185
                        //Do Order Create callout
                        HttpResponse httpRes = ECOM_OrderCreateAPIUtil.orderCreateAPICallout(orderRequest);
                        ECOM_OrderCreateFlowWrapper.OrdersAndOrderItems itemsToUpdate = ECOM_OrderCreateAPIUtil.parseOrderCreateAPIResponse(orderRequest, httpRes, orders[0]);
                        String orderType = orderRequest.OrderRequest.Header.Sender.Component;
                        //Update orders with SAP order number(Success) or Retry count and Error message(Failure)
                        if(itemsToUpdate != null){
                            if(itemsToUpdate.orders != null){
                                //RWPS-622 Update order type on order
                                List<Order> updatedOrders = itemsToUpdate.orders;
                                for(Order ord : updatedOrders){
                                    ord.Type = orderType;
                                }
                                ordersToUpdate.addAll(updatedOrders);
                            }
                            if(itemsToUpdate.orderItems != null){
                                orderItemsToUpdate.addAll(itemsToUpdate.orderItems);
                            }
                            ECOM_OrderUtil.updateOrders(ordersToUpdate);
                        }

                        //Log Request and response
                        supportData = orders[0].Id + ' \n'+'Request - '+JSON.serialize(orderRequest);
                        ECOM_ApplicationLogsUtil.setupApplicationRecord(ECOM_Constant.ORDER_MODULE_NAME, className, 'processSAPOrderDetails', supportData,'Response - '+httpRes.getBody(), 'OC');
                        // Update Order and Order Items
                        if(!orderItemsToUpdate.isEmpty()){
                            orderServiceInstance.updateOrderItems(orderItemsToUpdate);
                        }
                        if(!ordersToUpdate.isEmpty()){
                            orderServiceInstance.updateOrders(ordersToUpdate);
                        }
                        ECOM_OrderCreateFlowWrapper.Response res = new ECOM_OrderCreateFlowWrapper.Response();
                        res.success = true;
                        response.add(res);
                    }
                }else{
                    System.debug('SAP Contact Id : '+orders[0].SAP_Contact_ID__c);
                    System.debug('Order on hold : '+orders[0].ECOM_Order_On_Hold__c);
                    //RWPS-1146
					if(String.IsBlank(contactSAPNumber)) {
                        orders[0].ECOM_Order_On_Hold__c = true;
                        ECOM_OrderUtil.updateOrders(orders);
                    }
                    ECOM_OrderCreateFlowWrapper.Response res = new ECOM_OrderCreateFlowWrapper.Response();
                    res.success = false;
                    response.add(res);
                }
            }
        } catch (Exception ex) {
            ECOM_OrderCreateFlowWrapper.Response res = new ECOM_OrderCreateFlowWrapper.Response();
            res.success = false;
            response.add(res);
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.ORDER_MODULE_NAME, className, 'processSAPOrderDetails', supportData);
        }
        return response;
    }
}