/**************************************************************

* 1. Jira Ticket(s) that relates to this class

*  

*

* 2. Description - This class is a test class.

*

* 3. Objects referenced

*    - Order


* 4. Callouts to additional Components (including their methods) or None:

*    - None

*

* 5. Dependant Class(es):

*    - ECOM_TestUtil

*    - classes called from test class

*

* 6. Test Class Name:

*    -None

*

* 7. Is @Invocable : No

*

* 8. Author Name(s):

*    - Manoj 2023.09.19

*************************************************************/
@isTest
public with sharing class ECOM_OrderSyncToSAPController_Test {
    @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
    }
    @isTest
    static void TestsyncOrderToSAP(){
         User u = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Order order = [Select Id,Status From Order ORDER BY CREATEDDATE DESC LIMIT 1];
        order.ECOM_Order_On_Hold__c =false;
        order.PoNumber = '12333';
        update order;
        
        ECOM_OrderCreateFlowWrapper.Request testRequest = new ECOM_OrderCreateFlowWrapper.Request();
        testRequest.orderId = order.Id;
        
        String body = JSON.serialize(
            new Map<String, Object>{
                'OrderResponse' => new Map<String, Object>{
                    'Error' => new Map<String, Object>{
                        'errorCode' => 'your_error_code_here',
                            'errorMessage' => 'your_error_message_here',
                            'errorDescription' => 'your_error_description_here'
                            },
                                'OrderResponseHeader' => new Map<String, Object>{
                                }
                }
            }
        );
        ECOM_MockHttpResponseGenerator mock = new ECOM_MockHttpResponseGenerator(200, 'OK', body, null);
        Test.setMock(HttpCalloutMock.class, mock);
        
        
        Test.startTest();
        Map<String, Object> result ;
        System.runAs(u){
             result = ECOM_OrderSyncToSAPController.syncOrderToSAP(order.Id);
        }
       
        Test.stopTest();
        
        System.assertnotEquals(null,result,'expected result');
    }
}