/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM- 719    
*
* 2. Description - This queueable job is triggered when the email is invoked for order.
*
*
* 3. Objects referenced
*    - Order
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*
* 6. Test Class Name: 
*    - ECOM_Invoke_Email_Queueable_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*   - Sathiya 2024.06.13 This queueable job is triggered when the email is invoked for order.
*************************************************************/
public class ECOM_Invoke_Email_Queueable implements Queueable, Database.AllowsCallouts {
    
    Order order;
    String emailFlowType; // Possible values Approval, Order
    

    /**
    * @description Non-parameterized Constructor
    * @author Sathiya | 2024.06.13
    **/
    public ECOM_Invoke_Email_Queueable(){   
    }
        
    /**
    * @description  Constructor to accept the values essential to invoke email.
    * @author Sathiya | 2024.06.13
    * @param order 
    * @param emailFlowType 
    **/
    public ECOM_Invoke_Email_Queueable(Order order, String emailFlowType){
        this.order = order;
        this.emailFlowType = emailFlowType;
    }
    /**
    * @description  Queueable Execute method
    * @author Sathiya | 2024.06.13
    **/
    public void execute(QueueableContext qc){
        Map<String, Object> params = new Map<String, Object>();
        Map<String, String> requestMap = new Map<String, String>();
        String endPoint = '';
        //This method invokes a email notification flow for downstream process
        if(emailFlowType == 'Approval'){
            endPoint = System.Label.ECOM_ET_ApprovalEmailRestEndpoint;
            params.put('orderRecord', order);
        } else {
            params.put('varOrderRecord', order);
            endPoint = System.Label.ECOm_ET_OrderEmailEndpoint;
        }
        
        //prepare the requestMap from the values provided
        requestMap = ECOM_RestService.prepareRequestMap(System.Label.ECOM_IntegrationUserNamedCredential,
                                                        endPoint,
                                                        '', 
                                                        ECOM_Constant.HTTP_REQUEST_POST,
                                                        true, 
                                                        params,
                                                        ECOM_Constant.HTTP_CONTENT_APP_JSON
                                                       );
        //callout to Email Approval/ Order endpoint 
        if(!Test.isRunningTest()){
            HttpResponse response = ECOM_RestService.calloutAsIntegrationUser(requestMap);
            //System.debug('Response:: '+ response + ' Response result:: '+ response.getBody());
        }
    }
}