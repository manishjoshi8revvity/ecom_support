/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-3225
*
* 2. Description - This class is used as test class for ECOM_SelfServiceService
*
* 3. Objects referenced
*   -
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    -
*
* 6. Is @Invocable (Yes or No): No
*
* 7. Author Name(s):
*    - Abhishek Joshi 17 June 2024
*
*************************************************************/

@isTest(seeAllData=false)
public with sharing class ECOM_SelfServiceService_Test {
    /**
     * @description This method tests self service user auth success.
     * @author abhishek.joshi@revvity.com | 17 June 2024
     */
    @isTest
    public static void testAuthWithEntraSuccess() {
        Map<String, String> authData = ECOM_SelfServiceService.authWithEntra(
            'accessToken',
            'test@revvity.com',
            'sub'
        );
        String success = authData.get('success');
        Assert.isTrue(success == '1', 'Check self service user auth success.');
    }

    /**
     * @description This method tests self service user auth failure.
     * @author abhishek.joshi@revvity.com | 17 June 2024
     */
    @isTest
    public static void testAuthWithEntraFailure() {
        Map<String, String> authData = ECOM_SelfServiceService.authWithEntra(
            'accessToken',
            'test@non-revvity.com',
            'sub'
        );
        String success = authData.get('success');
        Assert.isNull(success, 'Check self service user auth failure.');
    }

    /**
     * @description This method tests API call fto get order data.
     * @author abhishek.joshi@revvity.com | 17 June 2024
     */
    @isTest
    public static void testGetOrderFromSAP() {
        Map<String, Object> sapData = ECOM_SelfServiceService.getOrderFromSAP(ECOM_SelfServiceConstants.TEST_SAP_ORDER_NUMBER);
        Boolean success = (Boolean) sapData.get(ECOM_SelfServiceConstants.SAP_RESPONSE_INDICATOR_KEY);
        Assert.isTrue(success, 'Check API call fto get order data.');
    }
}