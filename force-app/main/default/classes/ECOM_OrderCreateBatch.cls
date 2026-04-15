/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM - 125 
*
* 2. Description - This batch job Syncs Order to SAP via Boomi
*
*
* 3. Objects referenced
*    - Order
*    - OrderItem
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_OrderUtil
*    - ECOM_RestService
*    - ECOM_OrderCreateAPIUtil
*
* 6. Test Class Name: 
*    - ECOM_OrderCreateBatch_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Rani Thumma 2023.08.21
*************************************************************/
public class ECOM_OrderCreateBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{
    
    public string className = 'ECOM_OrderCreateBatch';
    private string query = '';
    
    public ECOM_OrderCreateBatch(String queryString){
        this.query = queryString;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Fetch Approved orders
        System.debug('query == '+query);
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Order> orders){
        String supportData = '';
        List<Order> ordersToUpdate = new List<Order>();
        List<OrderItem> orderItemsToUpdate = new List<OrderItem>();
        String orderId = '';
        try {
            supportData = JSON.serialize(orders);
            Type orderService = Type.forName(ECOM_Constant.ORDER_SERVICE);
            ECOM_IOrderService orderServiceInstance = (ECOM_IOrderService)orderService.newInstance();
            for(Order order :orders){
                
                List<PaymentAuthorization> payments;
                List<CardPaymentMethod> cardPayments;
                String contactSAPNumber = null;
                
                    User us = new ECOM_UserService().getUserByUser(String.valueOf(order.OwnerId));
                    
                
                
                
                // fetch SAP Contact number from ERP relationships
                Type erpAddressService = Type.forName(ECOM_Constant.ERP_ADDRESS_SERVICE);
                ERP_IAddressService erpAddressServiceInstance = (ERP_IAddressService)erpAddressService.newInstance();
                System.debug('us.ContactId'+us.ContactId);
                List<ERP_RelationShip__c> erpRelationships = erpAddressServiceInstance.fetchERPRelationshipsByERPAddress(us.ContactId, String.valueOf(order.Default_Ship_to_ERP_Address__r.Target_Address__c));
                if(erpRelationships != null && erpRelationships.size() > 0){
                    contactSAPNumber = erpRelationships[0].ERP_Contact_ID__c;
                }
                // fetch credit card payment details if PO Number is empty
                if(order.PoNumber == null){
                    payments = orderServiceInstance.getPaymentAuthorizationBasedOnOrder(String.valueOf(order.Id));
                    cardPayments = orderServiceInstance.getCardPaymentBasedOnOrder(String.valueOf(order.Id));
                }
                
                ECOM_OrderSummaryRequestWrapper orderRequest = ECOM_OrderCreateAPIUtil.generateOrderCreateRequest(order, contactSAPNumber, payments, cardPayments, us);
                HttpResponse httpRes = ECOM_OrderCreateAPIUtil.orderCreateAPICallout(orderRequest);
                ECOM_OrderCreateFlowWrapper.OrdersAndOrderItems itemsToUpdate = ECOM_OrderCreateAPIUtil.parseOrderCreateAPIResponse(orderRequest, httpRes, order);
                //Update orders with SAP order number(Success) or Retry count and Error message(Failure)
                if(itemsToUpdate != null){
                    if(itemsToUpdate.orders != null){
                    	ordersToUpdate.addAll(itemsToUpdate.orders);
                	}
                    if(itemsToUpdate.orderItems != null){
                        orderItemsToUpdate.addAll(itemsToUpdate.orderItems);
                    }
                    ECOM_OrderUtil.updateOrders(ordersToUpdate);
            	}
                //Log Request and response
                supportData = order.Id + ' \n'+'Request - '+JSON.serialize(orderRequest);
                ECOM_ApplicationLogsUtil.setupApplicationRecord(ECOM_Constant.ORDER_MODULE_NAME, className, 'execute', supportData,'Response - '+httpRes.getBody(), 'OC');
            }
            
            //Type orderService = Type.forName(ECOM_Constant.ORDER_SERVICE);
            //ECOM_IOrderService orderServiceInstance = (ECOM_IOrderService)orderService.newInstance();
            if(!orderItemsToUpdate.isEmpty()){
                orderServiceInstance.updateOrderItems(orderItemsToUpdate);
            }
            if(!ordersToUpdate.isEmpty()){
                orderServiceInstance.updateOrders(ordersToUpdate);
            }
        } catch (Exception ex) {
            system.debug('error: '+ex.getMessage());
            system.debug('stack: '+ex.getStackTraceString());
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.ORDER_MODULE_NAME, className, 'execute', supportData);
        }
    }
        
    //This is finish method of batch job.
    public void finish(Database.BatchableContext bc){
    }
}