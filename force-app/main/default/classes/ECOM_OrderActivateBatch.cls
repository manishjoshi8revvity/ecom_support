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
public class ECOM_OrderActivateBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{
    
    public string className = 'ECOM_OrderActivateBatch';
    private string query = '';
    
    public ECOM_OrderActivateBatch(String queryString){
        this.query = queryString;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Fetch Shipped orders
        System.debug('query == '+query);
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Order> orders){
        String supportData = '';
        List<Order> ordersToUpdate = new List<Order>();
        
        List<ConnectApi.OrderSummaryInputRepresentation> orderSummaryInputs = new List<ConnectApi.OrderSummaryInputRepresentation>();
        try {
        	supportData = JSON.serialize(orders);
            Type orderService = Type.forName(ECOM_Constant.ORDER_SERVICE);
            ECOM_IOrderService orderServiceInstance = (ECOM_IOrderService)orderService.newInstance();
            for(Order order :orders){
                Order od = new Order();
                od.Id = order.Id;
                od.Status = ECOM_Constant.ORDER_STATUS_ACTIVATED;
                ordersToUpdate.add(od);
                
                ConnectApi.OrderSummaryInputRepresentation orderSummaryInput = new ConnectApi.OrderSummaryInputRepresentation();
				orderSummaryInput.businessModel = 'B2B';
                orderSummaryInput.name = od.OrderNumber; 
                orderSummaryInput.orderId = od.Id;
                orderSummaryInput.orderLifeCycleType = 'UNMANAGED';
                orderSummaryInput.status = 'Created';
                orderSummaryInputs.add(orderSummaryInput);
                
            }
            //Activate Order
            if(!ordersToUpdate.isEmpty()){
                orderServiceInstance.updateOrders(ordersToUpdate);
            }
            //Create Order Summaries
            for(ConnectApi.OrderSummaryInputRepresentation odSummary : orderSummaryInputs){
                orderServiceInstance.createOrderSummary(odSummary);
			}
        } catch (Exception ex) {
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.ORDER_MODULE_NAME, className, 'execute', supportData);
        }
    }
    
     //This is finish method of batch job.
    public void finish(Database.BatchableContext bc){
    }

}