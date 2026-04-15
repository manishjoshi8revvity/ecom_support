/**************************************************************
 * 1. Ticket(s) that relates to this class
 * - RWPS - 6100
 *
 * 2. Description - It is a wrapper class used in SUB.FLOW_4478: ECOM - Fetch Latest Order Details
 *
 * 3. Objects referenced
 * - None
 *
 * 4. Callouts to additional Components (including their methods) or None:
 * - None
 *
 * 5. Dependant Class(es):
 * - None
 *
 * 6. Test Class Name:
 * - ECOM_OrderAndSAPOrderWrapperUtility_Test
 *
 * 7. Is @Invocable (Yes or No): Yes
 *
 * 8. Author Name(s):
 * - Sachin Vispute 2026.02.12 Created the class consisting of Input, Output Wrapper along with invocable method - RWPS-6100
*************************************************************/
public class ECOM_OrderAndSAPOrderWrapperUtility {

    // Input wrapper that contains SF orders and SAP orders
    public class FlowInputs {
        @InvocableVariable(label='Order Records' required=false)
        public List<Order> orderRecords;

        @InvocableVariable(label='SAP Order Records' required=false)
        public List<SAP_Order_Summary__c> sapOrderRecords;
        //public List<ECOM_OrderModel> sapOrderRecords;
    }

    // Output wrapper that contains combined SF and SAP orders
    public class FlowOutputs {
        @InvocableVariable(label='Combined Order Records')
        public List<SAP_Order_Summary__c> combinedOrders;
    }

    /**
    * @description This method accepts SF & SAP Orders and returns Combined SF Order + SAP Order records into a single collection with upto 5 orders sorted by date
    * @author Sachin Vispute | 2026.02.12 | RWPS-6100
    * @params inputs | List<FlowInputs>
    * @return List<FlowOutputs>
    **/
    @InvocableMethod(label='Combine Order Records' description='Combines SF Order and SAP Order records into a single collection')
    public static List<FlowOutputs> parseOrderAndSAPOrders(List<FlowInputs> inputs) {

        //List<ECOM_OrderModel> combinedOrdersList = new List<ECOM_OrderModel>();

        List<SAP_Order_Summary__c> combinedOrdersList = new List<SAP_Order_Summary__c>();

        FlowInputs input = inputs[0];
        // Process Order records

        if (input.orderRecords != null && !input.orderRecords.isEmpty()) {
            for (Order order : input.orderRecords) {
                /* ECOM_OrderModel orderModel = new ECOM_OrderModel();
                orderModel.id = order.Id != null ? order.Id : null;
                orderModel.orderNumber = order.OrderNumber != null ? order.OrderNumber : null;
                orderModel.effectiveDate = order.EffectiveDate != null ? order.EffectiveDate : null;
                orderModel.orderedDate = order.CreatedDate != null ? order.CreatedDate : null;
                orderModel.status = order.ECOM_Order_Summary_Status__c  != null ? order.ECOM_Order_Summary_Status__c  : null;
                orderModel.poNumber = order.ECOM_SAP_Order_Summary__r.Customer_PO_Number__c != null ? order.ECOM_SAP_Order_Summary__r.Customer_PO_Number__c : null;
                combinedOrdersList.add(orderModel); */

                SAP_Order_Summary__c sfOrder = new SAP_Order_Summary__c();
                sfOrder.ext_order_id__c = order.Id != null ? order.Id : null;
                sfOrder.Order_Number__c = order.OrderNumber != null ? Double.valueOf(order.OrderNumber) : null;
                sfOrder.Actual_Order_Date__c = order.EffectiveDate != null ? order.EffectiveDate : null;
                sfOrder.Order_Status_Name__c = order.ECOM_Order_Summary_Status__c  != null ? order.ECOM_Order_Summary_Status__c  : null;
                sfOrder.Customer_PO_Number__c = order.ECOM_SAP_Order_Summary__r.Customer_PO_Number__c != null ? order.ECOM_SAP_Order_Summary__r.Customer_PO_Number__c : null;
                sfOrder.Order__r = null;
                combinedOrdersList.add(sfOrder);
            }
        }

        // Process SAP_Order__c records
        if (input.sapOrderRecords != null && !input.sapOrderRecords.isEmpty()) {
            for (SAP_Order_Summary__c sapOrder : input.sapOrderRecords) {
                /* ECOM_OrderModel orderModel = new ECOM_OrderModel();
                orderModel.id = sapOrder.Id;
                orderModel.orderNumber = sapOrder.Order_Number__c != null ? String.valueOf(sapOrder.Order_Number__c) : null;
                orderModel.effectiveDate = sapOrder.Actual_Order_Date__c != null ? sapOrder.Actual_Order_Date__c : null;
                orderModel.orderedDate = sapOrder.CreatedDate != null ? sapOrder.CreatedDate : null;
                orderModel.status = sapOrder.fxStatusB2B__c != null ? sapOrder.fxStatusB2B__c : null;
                orderModel.poNumber = sapOrder.Customer_PO_Number__c != null ? sapOrder.Customer_PO_Number__c : null;
                combinedOrdersList.add(orderModel); */

                SAP_Order_Summary__c order = new SAP_Order_Summary__c();
                order.ext_order_id__c = sapOrder.Id != null ? sapOrder.Id : null;
                order.Order_Number__c = sapOrder.Order_Number__c != null ? sapOrder.Order_Number__c : null;
                order.Actual_Order_Date__c = sapOrder.Actual_Order_Date__c != null ? sapOrder.Actual_Order_Date__c : null;
                order.Order_Status_Name__c = sapOrder.fxStatusB2B__c != null ? sapOrder.fxStatusB2B__c : null;
                order.Customer_PO_Number__c = sapOrder.Customer_PO_Number__c != null ? sapOrder.Customer_PO_Number__c : null;
                order.Order__r = sapOrder.Order__r != null ? sapOrder.Order__r : null;
                combinedOrdersList.add(order);
            }
        }

        //Sorting via date in descending manner & then Order Number if date is same
        Integer n = combinedOrdersList.size();
        for (Integer currentIndex = 0; currentIndex < combinedOrdersList.size() - 1; currentIndex++) {
            for (Integer nextIndex = 0; nextIndex < combinedOrdersList.size() - currentIndex - 1; nextIndex++) {
                SAP_Order_Summary__c current = combinedOrdersList[nextIndex];
                SAP_Order_Summary__c next = combinedOrdersList[nextIndex + 1];

                Boolean swap = false;
                if (current.Actual_Order_Date__c != next.Actual_Order_Date__c) {
                    // Primary Sort: Latest Date First
                    if (current.Actual_Order_Date__c == null && next.Actual_Order_Date__c != null) {
                        swap = true;
                    } else if (current.Actual_Order_Date__c != null && next.Actual_Order_Date__c != null) {
                        if (next.Actual_Order_Date__c > current.Actual_Order_Date__c) {
                            swap = true;
                        }
                    }
                } else {
                    //If dates are equal, sort by Order Number
                    if (current.Order_Number__c == null && next.Order_Number__c != null) {
                        swap = true;
                    } else if (current.Order_Number__c != null && next.Order_Number__c != null) {
                        if (String.valueOf(next.Order_Number__c).compareTo(String.valueOf(current.Order_Number__c)) > 0) {
                            swap = true;
                        }
                    }
                }

                if (swap) {
                    combinedOrdersList[nextIndex] = next;
                    combinedOrdersList[nextIndex + 1] = current;
                }
            }
        }

        //limiting the orders upto 5 records
        while (combinedOrdersList.size() > 5) {
            combinedOrdersList.remove(combinedOrdersList.size() - 1);
        }

        FlowOutputs output = new FlowOutputs();
        output.combinedOrders = combinedOrdersList;
        return new List<FlowOutputs>{output};
    }
}