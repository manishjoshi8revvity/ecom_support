/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM -  566
*
* 2. Description -This class used in Cart Operation Flow
* 				- used to get the request from flow 'SUB.FLOW_4496: ECOM - Cart Operations
* 				- Parse ECOM_CartFlowWrapper to ECOM_CartModel object
*
* 3. Objects referenced
*    - Cart
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
* 5. Dependant Class(es):
*    - called from SUB_FLOW_4496_ECOM_Cart_Operations flow
*
* 6. Test Class Name: 
*    - ECOM_CartOperationsFlowController_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Manish kumar 2023.08.07
*	 - Vasudev R 2023.12.08
*************************************************************/

public with sharing class ECOM_CartOperationsFlowController {
    
    /**
     * this method is used to get the request from flow 'SUB.FLOW_4496: ECOM - Cart Operations' and calls specific service class method based on operation type to get response.
     *
     * @param requestList List<ECOM_CartFlowWrapper>
     *
     * @return List<ECOM_CartFlowWrapper>
     * 
     * @author manish.kumar@rafter.one | 07-08-2023
     */
    @InvocableMethod(Label='Cart Operation' Category='Cart management' Description='It Performs all the cart related operations')
    public static List<ECOM_CartFlowWrapper> handleCartOperation(List<ECOM_CartFlowWrapper> requestList) {
        
        List<ECOM_CartFlowWrapper> cartFlowResponseList = new List<ECOM_CartFlowWrapper>();
        ECOM_CartFlowWrapper cartFlowResponse = new ECOM_CartFlowWrapper();
        List<ECOM_CartModel> cartModelsResponse = new List<ECOM_CartModel>();
        Map<String,Object> responseMap = new  Map<String,Object>();
        Type cartService = Type.forName('ECOM_CartService');
		ECOM_ICartService cartServiceInstance = (ECOM_ICartService)cartService.newInstance();
        Map<String, ECOM_CartModel> operationVsRequestMap = getCartModelObj(requestList[0]);
        
        //Based on Operation type call operation specific method
        if(operationVsRequestMap.containsKey(requestList[0].operationType) && operationVsRequestMap.get(requestList[0].operationType) != null){
            ECOM_CartModel cartModel = operationVsRequestMap.get(requestList[0].operationType);
           if(operationVsRequestMap.containsKey(System.Label.ECOM_CartOperation_FetchCurrentCart)){
                cartModelsResponse = cartServiceInstance.fetchCart(new List<ECOM_CartModel>{cartModel});
            }else if(operationVsRequestMap.containsKey(System.Label.ECOM_CartOperation_AddCartItems)){
                cartModelsResponse = cartServiceInstance.addItemsToCart(new List<ECOM_CartModel>{cartModel});
            }else if(operationVsRequestMap.containsKey(System.Label.ECOM_CartOperation_GetCartItems)){
                cartModelsResponse = cartServiceInstance.getCartItems(new List<ECOM_CartModel>{cartModel});
            }else if(operationVsRequestMap.containsKey(System.Label.ECOM_CartOperation_UpdateCartItems)){
                cartModelsResponse = cartServiceInstance.updateCartItems(new List<ECOM_CartModel>{cartModel});
            }
        }
        
        if(cartModelsResponse != null && cartModelsResponse.size() > 0){
            cartFlowResponse.cartModel = cartModelsResponse[0];
            //cartFlowResponse = ECOM_CartUtil.updatePunchoutData(requestList[0], cartFlowResponse);//VRa-Punchout Changes
        }
        System.debug('cartFlowResponse =>'+cartFlowResponse);
        cartFlowResponseList.add(cartFlowResponse);
        
        return cartFlowResponseList;
    }
	
    //Parse ECOM_CartFlowWrapper to ECOM_CartModel object
    public static Map<String, ECOM_CartModel> getCartModelObj(ECOM_CartFlowWrapper request){
        system.debug('request' +request);
        Map<String, ECOM_CartModel> operationVsRequestMap = new Map<String, ECOM_CartModel>();
        ECOM_CartModel cartModel = new ECOM_CartModel();
        cartModel.webstoreId = request.webstoreId;
        cartModel.currencyIsoCode = request.currencyIsoCode;
        cartModel.accountId = request.accountId;
        cartModel.userId = request.userId;
        if(String.isNotBlank(request.cartId)){
            cartModel.cartId = request.cartId;
        }
        //Set CartItems
        if(request.cartItems != null && !request.cartItems.isEmpty()){
            cartModel.cartItems = request.cartItems;
        }

        operationVsRequestMap.put(request.operationType, cartModel);
        return operationVsRequestMap;

    }
}