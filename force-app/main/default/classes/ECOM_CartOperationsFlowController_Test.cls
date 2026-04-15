/**************************************************************

* 1. Jira Ticket(s) that relates to this class
*  
*
* 2. Description - This is a test class for ECOM_CartOperationsFlowController
- Call the ECOM_TestUtilClass to create test data and test each methods.
- Used System Assertion to Confirm the functionalities.
*
* 3. Objects referenced
*    - WebCart
*	 - WebStore
*    - Account
*	 - User
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_TestUtil
*    - ECOM_CartFlowWrapper
*	 - ECOM_CartFlowWrapper

* 6. Test Class Name:
*    
*
* 7. Is @Invocable : No
*
* 8. Author Name(s):
*    - Sukumar 2023.09.17
*************************************************************/
@isTest
public class ECOM_CartOperationsFlowController_Test {
    // Set up test data
    @TestSetup
    static void setupTestData() {
        Map<String,Object> respponse = ECOM_TestUtil.initialStorefrontSetup();
    }
    
    //Test for HandleCartOperation
    @isTest
    static void testHandleCartOperation() {
        Account testAccount = [SELECT Id, Name FROM Account ORDER BY CREATEDDATE DESC LIMIT 1 ];       
        User testUser=[SELECT Id, Name FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        WebCart testCart = [SELECT Id, Name FROM WebCart ORDER BY CREATEDDATE DESC limit 1]; 
        WebStore testWebStore= [SELECT Id, Name FROM WebStore ORDER BY CreatedDate DESC];
        
        List<ECOM_CartFlowWrapper> reqList= new List<ECOM_CartFlowWrapper>();
        ECOM_CartFlowWrapper cardRequest=new ECOM_CartFlowWrapper();
        cardRequest.userId=testUser.Id;
        cardRequest.accountId=testAccount.Id;
        cardRequest.webstoreId=testWebStore.Id;
        cardRequest.currencyIsoCode='USD';
        cardRequest.cartId=testCart.Id;
        cardRequest.operationType='FetchCurrentCart';
        reqList.add(cardRequest);
        //Running test as testUser
        System.runAs(testUser){
            
            Test.startTest();
            // Calling  the getOrderConfirmationDetails method with scenario operation type as FetchCurrentCart
            List<ECOM_CartFlowWrapper> resultList1 = ECOM_CartOperationsFlowController.handleCartOperation(reqList);
            cardRequest.operationType='AddCartItems';
            
            // Calling  the getOrderConfirmationDetails method with scenario operation type as AddCartItems
            List<ECOM_CartFlowWrapper> resultList2 = ECOM_CartOperationsFlowController.handleCartOperation(reqList);
            cardRequest.operationType='UpdateCartItems';
            
            // Calling  the getOrderConfirmationDetails method with scenario operation type as UpdateCartItems
            List<ECOM_CartFlowWrapper> resultList3 = ECOM_CartOperationsFlowController.handleCartOperation(reqList);
            cardRequest.operationType='GetCartItems';
            
            // Calling  the getOrderConfirmationDetails method with scenario operation type as GetCartItems
            List<ECOM_CartFlowWrapper> resultList4 = ECOM_CartOperationsFlowController.handleCartOperation(reqList);
            Test.stopTest();
            
            // Validating the results
            System.assertEquals(true, resultList1.size()>0,'Expected a list');
            System.assertEquals(true, resultList2.size()>0,'Expected a list');
            System.assertEquals(true, resultList3.size()>0,'Expected a list');
            System.assertEquals(true, resultList4.size()>0,'Expected a list');
            
            
        }
    }
}