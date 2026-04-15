/**************************************************************
 * 1. Jira Ticket(s) that relates to this class
 *    ECOM-113
 * 	  ECOM-114
 *
 * 2. Description - This class acts as a controller class which makes call out to create a case in other system.
 *
 * 3. Objects referenced
 *    - None
 *
 * 4. Callouts to additional Components (including their methods) or None:
 *    - None
 *
 * 5. Dependant Class(es):
 *    - ECOM_FormWrapper
 * 	  - ECOM_UserUtil
 * 	  - ECOM_OrderService
 * 	  - ECOM_Constant
 *
 * 6. Test Class Name:
 *
 * 7. Is @Invocable (Yes or No): No
 *
 * 8. Author Name(s):
 *    - Vipul Goyal 09-20-2023
 *    - Vipul Goyal 2024.05.06 Added method getOrderApprovalDetails,getApprovalCount for ECOM-103
*     - Prabhat Kumar 2025.04.01 Added method getRecentlyPurchasedProducts - RWPS-2855
*     - Manish Joshi 2025.04.16 Updated method getRecentlyPurchasedProducts - RWPS-3023
 *************************************************************/
public without sharing class ECOM_OrderController {

    public static final String CLASSNAME='ECOM_OrderController';

    /**
    * @description //Callout for case creation
    * @author Vipul Goyal | 09-22-2023
    * @param orderItemId
    * @param formFactor
    * @param reason
    * @param comment
    * @return Map<String, Object>
    **/
    @AuraEnabled
    public static Map<String,Object> makeCallout(String orderItemId,String formFactor,String reason,String comment){
        Map<String,Object> responseMap=new Map<String,Object>();
        String supportData='';
        try {

            Map<String,String> requestMap=new Map<String,String>();

            ECOM_FormWrapper.FormWrapper formWrapper=new ECOM_FormWrapper.FormWrapper();

            Type userService = Type.forName(ECOM_Constant.USER_Service);
            ECOM_IUserService userServiceInstance = (ECOM_IUserService)userService.newInstance();
            User us = userServiceInstance.getUserByUserId();

            formWrapper=ECOM_UserUtil.setupFormWrapperFields(formWrapper,formFactor,reason,comment);
            formWrapper.user=ECOM_UserUtil.setupUserInfo(us);
            formWrapper=ECOM_OrderService.setupOrderItemDetails(formWrapper,orderItemId);
            String requestBody=JSON.serialize(formWrapper);
            requestBody=requestBody.replace('_replace','');
            supportData=requestBody;

            System.debug('requestBody ==> '+requestBody);

            requestMap.put(ECOM_Constant.ACTION_TYPE,'CreateCase');
            requestMap.put(ECOM_Constant.HTTP_REQUEST_TYPE,ECOM_Constant.HTTP_REQUEST_POST);
            requestMap.put(ECOM_Constant.HTTP_REQUEST_BODY,requestBody);

            HTTPResponse res=ECOM_RestService.doBasicHttpRequest(requestMap);

            if(res.getStatusCode()==200 || res.getStatusCode()==201)
            {
                responseMap.put('Success',true);
                responseMap.put('SuccessMessage','Request Submitted Successfully!');
            }
            else
            {
                responseMap.put('Success',false);
                responseMap.put('Message','Error while processing your request.');
            }
            String responseData='Response status Code : '+res.getStatusCode()+' . Response Body : '+res.getBody();
            ECOM_ApplicationLogsUtil.logApplicationApiData(ECOM_Constant.ORDER_MODULE_NAME, CLASSNAME, 'orderSupport', supportData,responseData);
        } catch (Exception e) {
            responseMap.put('Success',false);
            responseMap.put('Message','Error while processing your request.');
            responseMap.put('ErrorMessage',e.getStackTraceString());
            ECOM_ApplicationLogsUtil.logFailure(e, ECOM_Constant.ORDER_MODULE_NAME, CLASSNAME, 'orderSupport', supportData);
        }
        return responseMap;
    }


    /**
    * @description //Get form factor for particular order Item.
    * @author Vipul Goyal | 09-22-2023
    * @param orderItemId
    * @return Map<String, Object>
    **/
    @AuraEnabled
    public static Map<String,Object> getAssociatedReasons(String orderItemId)
    {
        Map<String,Object> responseMap=new Map<String,Object>();
        try
        {
            OrderItem item=ECOM_OrderService.getOrderItemBasedOnId(orderItemId);
            List<ECOM_FormMapping__mdt> formMappings=ECOM_CustomMetadataService.getFormMappingBasedOnStatus(item.ECOM_Order_Item_Status__c);
            responseMap.put('Success',true);
            responseMap.put('FormMapping',formMappings);
        }catch(Exception ex)
        {
            responseMap.put('Success',false);
            responseMap.put('ErrorMessage',ex.getStackTraceString());
        }
        return responseMap;

    }



    /**
    * @description This method is used to retrieve Orders for Approval.
    * @author Vipul Goyal | 05-06-2024
    * @return Map<String, Object>
    **/
    @AuraEnabled
    public static Map<String,Object> getOrderApprovalDetails()
    {
        Map<String,Object> responseMap=new Map<String,Object>();
        responseMap.put('Success',true);
        try
        {
            Type userService = Type.forName(ECOM_Constant.USER_Service);
            ECOM_IUserService userServiceInstance = (ECOM_IUserService)userService.newInstance();
            User user = userServiceInstance.getUserByUserId();

            String userId = user.Id;
            String email = '';

            if(String.isNotBlank(user.ContactId) && String.isNotBlank(user.Contact.Email))
            {
                email = user.Contact.Email;
            }
            else
            {
                email = user.Email;
            }

            List<Order> orders= ECOM_OrderService.getOrdersForApproval(userId,email);

            //List<Order> approvedOrders = new List<Order>();
            //List<Order> rejectedOrders = new List<Order>();

            List<OrderApproval> orderApprovals = new List<OrderApproval>();
            List<OrderApproval> approvedOrders = new List<OrderApproval>();
            List<OrderApproval> rejectedOrders = new List<OrderApproval>();

            if(!orders.isEmpty())
            {
                for(Order ord:orders)
                {
                    if(ord.Status.equalsIgnoreCase(ECOM_Constant.ORDER_PENDING_APPROVAL))
                    {
                        OrderApproval temp = new OrderApproval();
                        temp.order = ord;
                        temp.orderLink = '/orderDetails?id='+ord.Id;
                        temp.isApprovalDetails = ord?.ECOM_ApprovedRejectedBy__c != null;
                        temp.submitterName = ord?.Owner?.Email; //ord?.Owner?.FirstName + ' ' + ord?.Owner?.LastName;
                        if((ord.ECOM_Designated_Approver__c).containsIgnoreCase(email))
                        {
                            temp.showApprovalButton = true;
                        }
                        else
                        {
                            temp.showApprovalButton = false;
                        }
                        orderApprovals.add(temp);
                    }else if(ord.Status.equalsIgnoreCase(ECOM_Constant.ORDER_REJECTED)){
                        OrderApproval temp = new OrderApproval();
                        temp.order = ord;
                        temp.orderLink = '/orderDetails?id='+ord.Id;
                        temp.isApprovalDetails = ord?.ECOM_ApprovedRejectedBy__c != null;
                        rejectedOrders.add(temp);
                    }else {
                        OrderApproval temp = new OrderApproval();
                        temp.order = ord;
                        temp.orderLink = '/orderDetails?id='+ord.Id;
                        temp.isApprovalDetails = ord?.ECOM_ApprovedRejectedBy__c != null;
                        approvedOrders.add(temp);
                    }
                }
            }

            responseMap.put('orderPendingForApproval',orderApprovals);
            responseMap.put('approvedOrders',approvedOrders);
            responseMap.put('rejectedOrders',rejectedOrders);

        }catch(Exception e)
        {
            responseMap.put('Success',false);
            String supportData = UserInfo.getUserName()+' ran getOrderApprovalDetails but failed execution';
            ECOM_ApplicationLogsUtil.logFailure(e, ECOM_Constant.ORDER_MODULE_NAME, CLASSNAME, 'orderSupport', supportData);
        }


        return responseMap;
    }

    @AuraEnabled
    public static Map<String,Object> updateOrderStatus(String orderId,String status,String comments)
    {
        Map<String,Object> responseMap=new Map<String,Object>();
        responseMap.put('Success',true);
        try{
            Type userService = Type.forName(ECOM_Constant.USER_Service);
            ECOM_IUserService userServiceInstance = (ECOM_IUserService)userService.newInstance();
            User user = userServiceInstance.getUserByUserId();
            List<Order> orderList = ECOM_OrderRepo.getOrderById(orderId);
            if(!orderList.isEmpty()){
                if(orderList[0]?.status == status){
                    responseMap.put('Success',false);
                    responseMap.put('showError', true);
                	responseMap.put('message', status == 'Approved'?'Order is already Approved':'Order is already Rejected');
                } else {
                    Order ord=new Order();
                    ord.Id = orderId;
                    ord.status = status;
                    ord.ECOM_ApprovalRejection_Comment__c = comments;
                    ord.ECOM_ApprovedRejectedBy__C = user.ContactId;
                    ECOM_OrderService.updateOrders(new List<Order>{ord});
                }
            } else {
                responseMap.put('Success',false);
                responseMap.put('showError', true);
                responseMap.put('message', 'Error Updating order, please contact administrator for help!');
            }
        } catch(Exception e) {
            responseMap.put('Success',false);
            responseMap.put('showError', false);
            responseMap.put('message', 'Error Updating order, please contact administrator for help!');
            String supportData = UserInfo.getUserName()+' ran updateOrderStatus but it failed execution';
            ECOM_ApplicationLogsUtil.logFailure(e, ECOM_Constant.ORDER_MODULE_NAME, CLASSNAME, 'orderSupport', supportData);
        }
        return responseMap;
    }

    /**
    * @description This emthod is used to get the order count.
    * @author Vipul Goyal | 05-08-2024
    * @return Map<String, Object>
    **/
    @AuraEnabled
    public static Map<String,Object> getApprovalCount(){
        Map<String,Object> responseMap=new Map<String,Object>();
        responseMap.put('Success',true);
        try {
            Type userService = Type.forName(ECOM_Constant.USER_Service);
            ECOM_IUserService userServiceInstance = (ECOM_IUserService)userService.newInstance();
            User user = userServiceInstance.getUserByUserId();

            String userId = user.Id;
            String email = '';

            if(String.isNotBlank(user.ContactId) && String.isNotBlank(user.Contact.Email))
            {
                email = user.Contact.Email;
            }
            else
            {
                email = user.Email;
            }

            Integer orderCount= ECOM_OrderService.getOrdersForApprovalCount(userId,email);
            responseMap.put('orderCount',orderCount);
        } catch (Exception e) {
            responseMap.put('Success',false);
            String supportData = UserInfo.getUserName()+' ran updateOrderStatus but it failed execution';
            ECOM_ApplicationLogsUtil.logFailure(e, ECOM_Constant.ORDER_MODULE_NAME, CLASSNAME, 'orderSupport', supportData);
        }
        return responseMap;

    }

     /**
    * @description This method returns recently purchased Products
    * @author Prabhat Kumar | 04-01-2025
    * @params communityId | String
    * @return List<String>
    **/
    @AuraEnabled
    public static Map<String,Object> getRecentlyPurchasedProducts(String communityId) {
        Map<String,Object> response = ECOM_ProductService.getRecentlyPurchasedProducts(communityId,UserInfo.getUserId());//RWPS-3023
        return response;
    }

    class OrderApproval{
        @AuraEnabled
        public Boolean showApprovalButton;
        @AuraEnabled
        public Order order;
        @AuraEnabled
        public String orderLink;
        @AuraEnabled
        public String submitterName;
        @AuraEnabled
        public Boolean isApprovalDetails;
    }

    /**
    * @description This method checks if product has been purchased before cut off date (POC)
    * @author Abhishek Joshi | 2025.07.15
    * @params productIds | List<String>
    * @params cutoffDate | String
    * @return List<OrderItem>
    **/
    @AuraEnabled
    public static List<AggregateResult> checkProductsHavingOrder(List<String> productIds, String cutoffDate) {
        Datetime cutoffDatetime = DateTime.newInstance(Long.valueOf(cutoffDate));

        // return ECOM_OrderRepo.checkProductsHavingOrder(
        //     productIds,
        //     cutoffDatetime
        // );
        return null;
    }
}