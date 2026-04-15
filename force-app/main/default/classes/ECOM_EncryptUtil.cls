/**************************************************************
 * 1. Jira Ticket(s) that relates to this class
 *    ECOM- 70
 *    ECOM- 72
 *    ECOM- 358
 * 
 * 2. Description - This class acts as the utility class for login encryption and decryption.
 * 
 * 3. Objects referenced
 *    -None
 * 
 * 4. Callouts to additional Components (including their methods) or None:
 *    - None
 * 
 * 5. Dependant Class(es):
 *    - ECOM_LoginController
 *    - ECOM_EncryptFlowController
 * 	  - ECOM_UserService
 * 	  - ECOM_Constant
 * 	  - ECOM_Util
 * 
 * 6. Test Class Name: ECOM_EncryptFlowController_Test
 * 
 * 7. Is @Invocable (Yes or No): No
 * 
 * 8. Author Name(s):
 *    - Vipul 2023.07.19
 * 	  - vramachandran@rafter.one | 11 Dec 2023
 *************************************************************/
public class ECOM_EncryptUtil {

    public static String className = 'ECOM_EncryptUtil';
    /**
     * This method is used to encypt data.
     *
     * @param requestBody ECOM_LoginWrapper.EncryptionRequest
     *
     * @return ECOM_LoginWrapper.EncryptionResponse
     *
     * @author Vipul Goyal | 07-20-2023
     **/
    public static ECOM_LoginWrapper.EncryptionResponse encryptData(ECOM_LoginWrapper.EncryptionRequest requestBody) {
        ECOM_LoginWrapper.EncryptionResponse response = new ECOM_LoginWrapper.EncryptionResponse();
        Boolean isSuccess = false;
        if (String.isNotBlank(requestBody.username) && String.isNotBlank(requestBody.password)) {
            response.encryptedToken = encryptWithAES256(requestBody.username);
            response.encryptedCode = encryptWithAES256(requestBody.password);
            isSuccess = true;
        }
        response.success = isSuccess;
        return response;
    }

    /**
     * This method is used to encypt data.
     *
     * @param requestBody ECOM_LoginWrapper.EncryptionRequest
     *
     * @return ECOM_LoginWrapper.EncryptionResponse
     *
     * @author Vipul Goyal | 07-20-2023
     **/
    public static ECOM_LoginWrapper.EncryptionResponse encryptDataWithManagedIV(ECOM_LoginWrapper.EncryptionRequest requestBody) {
        ECOM_LoginWrapper.EncryptionResponse response = new ECOM_LoginWrapper.EncryptionResponse();
        Boolean isSuccess = false;
        if (String.isNotBlank(requestBody.username)) {
            Map<String, Blob> mapEncryptedData = encryptWithManagedIV(requestBody.username);
            if (mapEncryptedData != null && mapEncryptedData.containsKey(ECOM_Constant.ENCRYPTED_TOKEN) &&
                    mapEncryptedData.get(ECOM_Constant.ENCRYPTED_TOKEN) != null &&
                    mapEncryptedData.containsKey(ECOM_Constant.ENCRYPTED_CODE) &&
                    mapEncryptedData.get(ECOM_Constant.ENCRYPTED_CODE) != null) {
                    response.encryptedToken = EncodingUtil.urlEncode(EncodingUtil.base64Encode(mapEncryptedData.get(ECOM_Constant.ENCRYPTED_TOKEN)), 'UTF-8');
                    response.encryptedCode = EncodingUtil.urlEncode(EncodingUtil.base64Encode(mapEncryptedData.get(ECOM_Constant.ENCRYPTED_CODE)), 'UTF-8');
                isSuccess = true;
            }
        }
        response.success = isSuccess;
        return response;
    }

    /**
     * This method is used to encrypt data.
     *
     * @param textToEncrypt String
     *
     * @return Blob
     *
     * @author Vipul Goyal | 07-27-2023
     **/
    public static Map<String, Blob> encryptWithManagedIV(String textToEncrypt) {
        Map<String, Blob> mapResult = new Map<String, Blob>();
        Blob blobSecretKey = Crypto.generateAesKey(256);
        Blob blobClearData = Blob.valueOf(textToEncrypt);
        Blob blobEncryptedData = Crypto.encryptWithManagedIV(ECOM_Constant.ALGORITHM_AES_256, blobSecretKey, blobClearData);
        mapResult.put(ECOM_Constant.ENCRYPTED_TOKEN, blobEncryptedData);
        mapResult.put(ECOM_Constant.ENCRYPTED_CODE, blobSecretKey);
        return mapResult;
    }

    /**
     * This method is used to decrypt data.
     *
     * @param encryptedToken String
     * @param encryptedCode String
     *
     * @return String
     *
     * @author Vipul Goyal | 07-27-2023
     **/
    public static String decryptWithManagedIV(String encryptedToken, String encryptedCode) {
        Blob textEncrypted = EncodingUtil.base64Decode(encryptedToken);
        Blob textEncryptedKey = EncodingUtil.base64Decode(encryptedCode);
        Blob decrypted = Crypto.decryptWithManagedIV(ECOM_Constant.ALGORITHM_AES_256, textEncryptedKey, textEncrypted);
        String decryptedString = decrypted.toString();
        return decryptedString;
    }

    /**
     * This method is used to encrypts data with AES256
     *
     * @param strText String
     *
     * @return String
     *
     * @author Vipul Goyal | 07-27-2023
     **/
    public static String encryptWithAES256(String strText) {
        String encryptedString = null;
        String methodName = 'encryptWithAES256';
        String supportData = '';
        try {
            String strSecretKey = ECOM_Util.fetchConfigByValue(ECOM_Constant.SECRET_KEY);
            String strInitializationVector = ECOM_Util.fetchConfigByValue(ECOM_Constant.INITIALIZATION_VECTOR);
            Blob blobSecretKey = Blob.valueOf(strSecretKey);
            Blob blobInitializationVector = Blob.valueOf(strInitializationVector);
            Blob blobClearData = Blob.valueOf(strText);
            Blob blobEncryptedTextData = Crypto.encrypt(ECOM_Constant.ALGORITHM_AES_256, blobSecretKey, blobInitializationVector, blobClearData);
            encryptedString = EncodingUtil.base64Encode(blobEncryptedTextData);
        } catch (Exception exceptionObject) {
            System.debug(exceptionObject.getStackTraceString());
            ECOM_ApplicationLogsUtil.logFailure(exceptionObject, ECOM_Constant.USER_MODULE_NAME, className, methodName, supportData);
        }
        return encryptedString;
    }

    /**
     * This method is used to decrypt data with AES256
     *
     * @param encryptedText String
     *
     * @return String
     *
     * @author Vipul Goyal | 07-27-2023
     **/
    public static String decryptWithAES256(String encryptedText) {
        String decryptedString = null;
        String methodName = 'decryptWithAES256';
        String supportData = '';
        try {
            String strSecretKey = ECOM_Util.fetchConfigByValue(ECOM_Constant.SECRET_KEY);
            String strInitializationVector = ECOM_Util.fetchConfigByValue(ECOM_Constant.INITIALIZATION_VECTOR);
            Blob blobSecretKey = Blob.valueOf(strSecretKey);
            Blob blobInitializationVector = Blob.valueOf(strInitializationVector);
            Blob encryptedDataUpdated = EncodingUtil.base64Decode(encryptedText);
            Blob decryptedTextData = Crypto.decrypt(ECOM_Constant.ALGORITHM_AES_256, blobSecretKey, blobInitializationVector, encryptedDataUpdated);
            decryptedString = decryptedTextData.toString();
        } catch (Exception exceptionObject) {
            ECOM_ApplicationLogsUtil.logFailure(exceptionObject, ECOM_Constant.USER_MODULE_NAME, className, methodName, supportData);
        }
        return decryptedString;
    }
    
    /**
     * @description This method returns the string with base64 encryption
     * @author vramachandran@rafter.one | 05 Jan 2024
     * @param plainText | String 
     * @return String
     */
    public static String encryptWithBase64(String plainText){
        
        String encryptedString = plainText;
        
        try{
            encryptedString = EncodingUtil.base64Encode(Blob.valueOf(plainText));
            
        }catch(Exception e){
            ECOM_ApplicationLogsUtil.logFailure(e, ECOM_Constant.USER_MODULE_NAME, className, 'encryptWithBase64', 'Message:: '+ e.getMessage()+ 'stack trace:: ' + e.getStackTraceString());
        }
        
        return encryptedString;
    }
    
    /**
     * @description This method returns the decrypted base64 EncyptedString
     * @author vramachandran@rafter.one | 05 Jan 2024
     * @param plainText | String 
     * @return String
     */
    public static String decryptWithBase64(String encryptedText){
        Blob decryptedBlob;
        String decryptedString = encryptedText;
        
        try{
            decryptedBlob = EncodingUtil.base64Decode(encryptedText);
            if(decryptedBlob != null){
                decryptedString = decryptedBlob.toString();
            }
            System.debug('decryptedString:: '+ decryptedString);
        }catch(Exception e){
            ECOM_ApplicationLogsUtil.logFailure(e, ECOM_Constant.USER_MODULE_NAME, className, 'encryptWithBase64', 'Message:: '+ e.getMessage()+ 'stack trace:: ' + e.getStackTraceString());
        }
        
        return decryptedString;
    }
    
}