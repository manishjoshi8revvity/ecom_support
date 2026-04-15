/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM- 70
*    ECOM- 72
*    ECOM- 358
*
* 2. Description - This class is used to encypt user data.
*
* 3. Objects referenced
*    -None
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
* 5. Dependant Class(es):
*    - used in SUB_FLOW_4493_ECOM_Encrypt_Input flow
*	 - ECOM_EncryptUtil
*
* 6. Test Class Name: 
*    - ECOM_EncryptFlowController_Test
*
* 7. Is @Invocable (Yes or No): Yes
*
* 8. Author Name(s):
*    - Vipul 2023.07.19

*************************************************************/

global class ECOM_EncryptFlowController {

    global static String className = 'ECOM_EncryptFlowController';

    /**
     * This method is invoked by the SUB.FLOW_4493: ECOM - Encrypt Input
     *
     * @param request List<ECOM_LoginWrapper.EncryptionRequest>
     *
     * @return List<ECOM_LoginWrapper.EncryptionResponse>
     *
     * @author mkumar@rafter.one | 07-27-2023
     **/
    @InvocableMethod(Label='Encrypt Data' Category='User Management' Description='It Encrypt\'s the Data')
    global static List<ECOM_LoginWrapper.EncryptionResponse> dataEncryption(List<ECOM_LoginWrapper.EncryptionRequest> request) {
        List<ECOM_LoginWrapper.EncryptionResponse> responseList = new List<ECOM_LoginWrapper.EncryptionResponse>();
        String methodName = 'dataEncryption';
        String supportData = '';
        try {
            supportData = JSON.serialize(request);
            System.debug('supportData : ' + supportData);
            for (ECOM_LoginWrapper.EncryptionRequest req : request) {
                ECOM_LoginWrapper.EncryptionResponse encryptionResponse = null;
                if (req.encryptWithManagedIV != null && req.encryptWithManagedIV) {
                    encryptionResponse = ECOM_EncryptUtil.encryptDataWithManagedIV(req);
                } else {
                    encryptionResponse = ECOM_EncryptUtil.encryptData(req);
                }
                responseList.add(encryptionResponse);
            }
        } catch (Exception ex) {
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.USER_MODULE_NAME, className, methodName, supportData);
        }
        return responseList;
    }

}