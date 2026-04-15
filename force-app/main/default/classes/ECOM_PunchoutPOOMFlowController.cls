/**************************************************************
*
* 1. Jira Ticket(s) that relates to this class
*    ECOM-1533
*	 ECOM-1022
*
* 2. Description - This is a controller for handling requests for POOM Cart information for cXML
*
* 3. Objects referenced
*    -None
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - None
*	
* 6. Test Class Name:         
*    - ECOM_PunchoutPOOMFlowController_Test
*
* 7. Is @Invocable (Yes or No): Yes
*
* 8. Author Name(s):
*    -vramachandran@rafter.one | 05 Dec 2024
*    - Manoj 2024.07.03 RWPS-993 Exception Running User field should be populated()
*	 - Sathiya 2024.08.30 ECOM-1480 Added method and module names for the punchout logs
*************************************************************/
public class ECOM_PunchoutPOOMFlowController {
    
    private static final String CLASS_NAME = 'ECOM_PunchoutPOOMFlowController';
    private static final String MODULE = 'POOM: Cart Request';
    
    private static ECOM_ICartService cartService;
    private static ECOM_IUserService userService;

    private static ERP_IAddressService addressService;
    
    public class PunchoutPOOMRequest{
        @invocableVariable public String cartId;
        @invocableVariable public String accountId;
    }
    
    @InvocableMethod(label='Get POOM Model' description='Returns the POOM model response')
    public static List<ECOM_POOMModel> getCartModelForPOOM(List<PunchoutPOOMRequest> poomRequestList){
        List<ECOM_POOMModel> responseModelList = new List<ECOM_POOMModel>();
        ECOM_POOMModel responseModel;
        try{
            if(null != poomRequestList && !poomRequestList.isEmpty()){
                String cartId = poomRequestList[0].cartId;
                String accountId = poomRequestList[0].accountId;
                
                //fetch erp address model for accountid
                //ERP_AddressModel addressModel = getAddressServiceInstance().getERPAddressModelForPunchoutAccountId(accountId);
                ERP_AddressModel addressModel = ERP_AddressUtil.getPunchoutAddressesForAccountId(accountId);
				responseModel = getCartServiceInstance().getPunchoutCartandCartItemsById(cartId, accountId);
                
                
                //insertPOOMLogs(poomRequestList[0],responseModel);
                
                System.debug('responsModel:: '+ responseModel);
                responseModelList.add(responseModel);
            }
            
        }catch(Exception e){
            System.debug('Cause:: '+ e.getMessage()+ ' Stack:: '+ e.getStackTraceString());
            ECOM_ApplicationLogsUtil.logFailure(e, MODULE, CLASS_NAME , 'getCartModelForPOOM', 'Message:: '+ e.getMessage()+ 'stack trace:: ' + e.getStackTraceString());
        }
        
        return responseModelList;
    }

    /**
     * @description This method creates a new POOM Log Request and Response
	 * @author garora@rafter.one | 17 Jan 2024
	 * @param ECOM_POOMModel | ECOM_POOMModel
	 * @param String | boomiResponse
	 * @returns
	 */
    public static void insertBoomiPOOMLogs(Map<String,Object> poomBody, String boomiResponse, Boolean success){
        List<ECOM_Application_Logs__c> newLogList = new List<ECOM_Application_Logs__c>();
        ECOM_POOMModel poomRequest = (ECOM_POOMModel)poomBody.get('poomResponse');
        ECOM_Application_Logs__c requestLog = new ECOM_Application_Logs__c();
        ECOM_Application_Logs__c responseLog = new ECOM_Application_Logs__c();
        if(null != poomRequest && String.isNotBlank(poomRequest.ownerId)){
            requestLog.OwnerId = poomRequest.ownerId;
            responseLog.OwnerId = poomRequest.ownerId;
        }

        // Add Method and Module Name for the Punchout logs
        requestLog.MethodName__c = 'POOM Request';
        requestLog.ModuleName__c = ECOM_Constant.EXCEPTION_TYPE; // punchout
        responseLog.MethodName__c = 'POOM Response';
        responseLog.ModuleName__c = ECOM_Constant.EXCEPTION_TYPE; // punchout
        // Changes End
        requestLog.ClassName__c = CLASS_NAME;
        requestLog.ECOM_Account__c = poomRequest.accountId;
        requestLog.ECOM_Log_Type__c = System.Label.ECOM_LogType_POOM_Request;
        requestLog.SupportData__c = JSON.serialize(poomBody);
        requestLog.ExceptionRunningUser__c = UserInfo.getUserId(); //RWPS-993
        responseLog.ExceptionRunningUser__c = UserInfo.getUserId(); //RWPS-993
        responseLog.ClassName__c = CLASS_NAME;
        responseLog.ECOM_Account__c = poomRequest.accountId;
        responseLog.ECOM_Log_Type__c = System.Label.ECOM_LogType_POOM_Response;
        responseLog.SupportData__c= boomiResponse;
        if(success){
            requestLog.ECOM_Log_Status__c = 'Success';
            responseLog.ECOM_Log_Status__c = 'Success';
        }
        else{
            requestLog.ECOM_Log_Status__c = 'Error';
            responseLog.ECOM_Log_Status__c = 'Error';
        }
        
        newLogList.add(requestLog);
        newLogList.add(responseLog);
        System.debug('newLogList:: '+ newLogList);
        ECOM_ApplicationLogsUtil.insertNewLogs(newLogList);
        
    }

    

    /**
     * @description This method returns the instance for a cart service
     * @author vramachandran@rafter.one | 05 Jan 2024
     * @returns ECOM_ICartService
     */
    @TestVisible
    private static ECOM_ICartService getCartServiceInstance(){
        if(null == cartService){
            Type cartServiceType = Type.forName(ECOM_Constant.CART_SERVICE);
            cartService = (ECOM_ICartService) cartServiceType.newInstance();
        }
        
        return cartService;
    }
    
    /**
     * @description This method returns the instance for a user service
     * @author vramachandran@rafter.one | 05 Jan 2024
     * @returns ECOM_IUserService
     */
    @TestVisible
    private static ECOM_IUserService getUserServiceInstance(){
        if(null == userService){
            Type userServiceType = Type.forName(ECOM_Constant.USER_SERVICE);
            userService = (ECOM_IUserService) userServiceType.newInstance();
        }
        
        return userService;
    }
    
    /**
     * @description This method returns the instance for a address service
     * @author vramachandran@rafter.one | 05 Jan 2024
     * @returns ERP_IAddressService
     */
    @TestVisible
    private static ERP_IAddressService getAddressServiceInstance(){
        if(null == addressService){
            Type addressServiceType = Type.forName(ECOM_Constant.ERP_ADDRESS_SERVICE);
            addressService = (ERP_IAddressService) addressServiceType.newInstance();
        }
        
        return addressService;
    }
    

}