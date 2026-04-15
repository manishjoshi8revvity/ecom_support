/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    RWPS-4437
*
* 2. Description - This class is a controller for Product Recommendations
*
* 3. Objects referenced
*
* 4. Callouts to additional Components (including their methods) or None:
*    - ECOM_ProductRecommendationsService.getCustomersAlsoBought
*
* 5. Dependant Class(es):
*
* 6. Test Class Name:
*    - ECOM_ProductRecommendationsController_Test
*
* 7. Is @Invocable: No
*
* 8. Author Name(s):
*    - Abhishek Joshi 2025.09.15 - Created the class and added method getCustomersAlsoBought - RWPS-4437
*    - Abhishek Joshi 2025.10.29 - Added method getRecommendationsInvocable, wrapper classes ECOM_ProductRecommendationsReqWrapper and ECOM_ProductRecommendationsResWrapper - RWPS-5046
*************************************************************/

public with sharing class ECOM_ProductRecommendationsController {
    public static final String CLASS_NAME = 'ECOM_ProductRecommendationsController';

    /**
     * @description This method fetches "Customers also bought" product recommendations for given productIds.
     * @author Abhishek Joshi 2025.09.15
     * @param productIds
     * @param communityId
     * @param configuration
     * @return Map<String, Object>
     */
    @AuraEnabled
    public static Map<String, Object> getCustomersAlsoBought(List<String> productIds, String communityId, Map<String, Object> configuration) {
        Boolean guestUser = Auth.CommunitiesUtil.isGuestUser();

        Map<String,Object> userData = new Map<String,Object>();

        if(guestUser && configuration.containsKey('salesOrg')) {
            userData.put('salesOrg', configuration.get('salesOrg'));
        } else {
            userData.put(
                'userId',
                UserInfo.getUserId()
            );
        }

        return ECOM_ProductRecommendationsUtil.getRecommendations(productIds, userData, communityId, configuration);
    }

    /**
     * @description Product recommendations request wrapper for invocable method
     * @author Abhishek Joshi 2025.10.29 | RWPS-5046
     */
    public class ECOM_ProductRecommendationsReqWrapper {
        @InvocableVariable(label='Product IDs')
        public List<String> productIds;

        @InvocableVariable(label='User ID')
        public String userId;

        @InvocableVariable(label='Sales Organization')
        public String salesOrg;
    }

    /**
     * @description Product recommendations response wrapper for invocable method
     * @author Abhishek Joshi 2025.10.29 | RWPS-5046
     */
    public class ECOM_ProductRecommendationsResWrapper {
        @InvocableVariable(label='Recommended Part Numbers')
        public List<String> partNumbers;

        @InvocableVariable(label='Error String')
        public String error;
    }

    /**
     * @description This invocable method fetches product recommendations for given productIds.
     * @author Abhishek Joshi 2025.10.29 | RWPS-5046
     * @param requestList
     * @return List<ECOM_ProductRecommendationsResWrapper>
     */
    @InvocableMethod
    public static List<ECOM_ProductRecommendationsResWrapper> getRecommendationsInvocable(List<ECOM_ProductRecommendationsReqWrapper> requestList) {
        List<ECOM_ProductRecommendationsResWrapper> responseList = new List<ECOM_ProductRecommendationsResWrapper>();
        ECOM_ProductRecommendationsResWrapper response = new ECOM_ProductRecommendationsResWrapper();
        response.partNumbers = new List<String>();
        responseList.add(response);

        if(requestList == null || requestList.isEmpty()) {
            return responseList;
        }

        List<String> productIds = requestList[0].productIds;
        String userId = requestList[0].userId;
        String salesOrg = requestList[0].salesOrg;

        List<Network> networks;
        Integer maxRecs;

        try {
            networks = ECOM_WebStoreRepo.getNetworks(Label.ECOM_WebStore_Name);

            String maxRecsLabel = Label.ECOM_Product_Recommendations_Invocable_Default_Max_Recs;
            if(!String.isBlank(maxRecsLabel)) {
                maxRecs = Integer.valueOf(maxRecsLabel);
            } else {
                maxRecs = 18;
            }

            if(networks.isEmpty() || (String.isBlank(userId) && String.isBlank(salesOrg)) || productIds == null || productIds.isEmpty()) {
                throw new InvocableActionException('Invalid input parameters');
            }

            String communityId = networks[0].Id;
            Map<String, Object> configuration = new Map<String, Object>{
                'maxRecs' => maxRecs
            };

            Map<String,Object> userData = new Map<String,Object>();
            if(!String.isBlank(userId)) {
                userData.put('userId', userId);
            } else {
                userData.put('salesOrg', salesOrg);
            }
            Map<String, Object> recommendationsMap = ECOM_ProductRecommendationsUtil.getRecommendations(productIds, userData, communityId, configuration);

            List<String> sellableProductIds = (List<String>)recommendationsMap.get(ECOM_ProductRecommendationsUtil.sellableRecommendationsKey);
            Map<String,Product2> productIdMap = (Map<String,Product2>)recommendationsMap.get(ECOM_ProductRecommendationsUtil.productIdMapKey);

            List<String> partNumbers = new List<String>();
            for(String prodId : sellableProductIds) {
                if(productIdMap.containsKey(prodId)) {
                    partNumbers.add(productIdMap.get(prodId).Part_Number__c);
                }
            }
            responseList[0].partNumbers = partNumbers;
        } catch (Exception ex) {
            String message = ex.getMessage();
            ECOM_ApplicationLogsUtil.logFailure(
                ex,
                'ProductRecommendationsInvocable',
                CLASS_NAME,
                'getRecommendationsInvocable',
                message + ' | ' + ex.getStackTraceString() + ' | productIds: ' + String.join(productIds, ',') + ' | userId: ' + userId + ' | salesOrg: ' + salesOrg + ' | networks: ' + networks.toString()
            );
            responseList[0].error = message;
        }

        return responseList;
    }

    public class InvocableActionException extends Exception{}
}