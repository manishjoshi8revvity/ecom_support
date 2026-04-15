/**************************************************************
* 1. Ticket(s) that relates to this class
* - ECOM - 110
* - ECOM - 806
* 
* 2. Description - It is a controller class used in Order Sync flow.
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
*	 - ECOM_OrderSyncFlowWrapper
*
* 6. Test Class Name: 
*
* 7. Is @Invocable (Yes or No): Yes
*
* 8. Author Name(s): 
* - Rani Thumma 2023.09.12
*
*************************************************************/ 
public class ECOM_OrderSyncFlowController {
    
    public static String CLASSNAME = 'ECOM_OrderSyncFlowController';
    /**
    * this method is used to get the request from flow 'SUB.FLOW_4451: ECOM - ' and sends it to service class for further processing.
    * @param request List<ECOM_OrderSyncFlowWrapper.Request>
    * @return  List<ECOM_OrderSyncFlowWrapper.Response>
    * @author Rani Thumma | 2023-09-09
    */
    @InvocableMethod(Label='Order Sync from SAP' Category='Order Sync' Description='This is to sync SAP Order updates to Order records')
    public static List<ECOM_OrderSyncFlowWrapper.Response> processSAPOrderDetails(List<ECOM_OrderSyncFlowWrapper.Request> ordersFromSAP) {
        
        String supportData = JSON.serialize(ordersFromSAP);
        List<ECOM_OrderSyncFlowWrapper.Response> response = new List<ECOM_OrderSyncFlowWrapper.Response>();
        Set<String> summaryIds = new Set<String>();
        Set<String> sapOrderIds = new Set<String>();
        /*try{
            for(ECOM_OrderSyncFlowWrapper.Request req :ordersFromSAP){
                summaryIds.add(req.sapOrderSummaryId);
            }
            // fetch SAP order summaries by SAP Order Summary Id
            Type sapOrderSummaryService = Type.forName('ECOM_SAPOrderSummaryService');
            ECOM_ISAPOrderSummary sapOrderInstance = (ECOM_ISAPOrderSummary)sapOrderSummaryService.newInstance();
            List<SAP_Order_Summary__c> sapOrderSummaries = sapOrderInstance.fetchSAPOrderSummariesById(summaryIds);
            System.debug('sapOrderSummaries'+sapOrderSummaries);
            for(SAP_Order_Summary__c oss :sapOrderSummaries){            
                if(oss.ext_order_id__c != null){
                    sapOrderIds.add(String.valueOf(oss.ext_order_id__c));
                }
            }
            // fetch orders by SAP order number 
            Type orderService = Type.forName(ECOM_Constant.ORDER_SERVICE);
            ECOM_IOrderService orderServiceInstance = (ECOM_IOrderService)orderService.newInstance();
            List<Order> orders = orderServiceInstance.getOrdersBySAPOrderId(sapOrderIds);
            // call utils to map order and order items Statuses with SAP statuses 
            ECOM_OrderSyncFlowWrapper.OrdersAndOrderItems  itemsToUpdate = ECOM_OrderUtil.mapUpdatedOrders(orders, sapOrderSummaries);
            
            if(itemsToUpdate.orders != null && itemsToUpdate.orders.size() > 0){
                // Update orders
                orderServiceInstance.updateOrders(itemsToUpdate.orders);
            }
            if(itemsToUpdate.orderItems != null && itemsToUpdate.orderItems.size() > 0){
                // Update order items 
                orderServiceInstance.updateOrderItems(itemsToUpdate.orderItems);
            }
            ECOM_OrderSyncFlowWrapper.Response res = new ECOM_OrderSyncFlowWrapper.Response();
            res.success = true;
            response.add(res);
        } catch(Exception ex) {
            ECOM_OrderSyncFlowWrapper.Response res = new ECOM_OrderSyncFlowWrapper.Response();
            res.success = false;
            response.add(res);
            ECOM_ApplicationLogsUtil.logFailure(ex, 'Order SAP Status', className, 'processSAPOrderDetails', supportData);
        }
*/        
        return response;
    }
    
}