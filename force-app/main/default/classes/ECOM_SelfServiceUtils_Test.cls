/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-3225
*
* 2. Description - This class is used as test class for ECOM_SelfServiceUtils
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
public with sharing class ECOM_SelfServiceUtils_Test {
    /**
     * @description This method tests self service get user data success.
     * @author abhishek.joshi@revvity.com | 17 June 2024
     */
    @isTest
    public static void testGetUserDataSuccess() {
        Datetime dt = Datetime.now();
        Long dtEpoch = dt.getTime();

        Map<String, Object> userData = ECOM_SelfServiceUtils.getUserData(
            'abcd' + ECOM_SelfServiceConstants.ENCRYPTION_SEPARATOR + '{"email": "test' + ECOM_SelfServiceConstants.EMAIL_SUFFIX + '", "name": "Test User", "time": "' + String.valueOf(dtEpoch) + '"}' + ECOM_SelfServiceConstants.ENCRYPTION_SEPARATOR + 'wxyz'
        );
        Integer success = (Integer) userData.get('success');
        Assert.isTrue(success == 1, 'Check self service get user data success.');
    }

    /**
     * @description This method tests self service get user data failure
     * @author abhishek.joshi@revvity.com | 17 June 2024
     */
    @isTest
    public static void testGetUserDataFailure() {
        Map<String, Object> userData = ECOM_SelfServiceUtils.getUserData(
            'abcd' + ECOM_SelfServiceConstants.ENCRYPTION_SEPARATOR + '{"email": "test@non-revvity.com", "name": "Test User"}' + ECOM_SelfServiceConstants.ENCRYPTION_SEPARATOR + 'wxyz'
        );
        Object success = userData.get('success');
        Assert.isNull(success, 'Check self service get user data failure.');
    }

    /**
     * @description This method tests self service get user data failure.
     * @author abhishek.joshi@revvity.com | 17 June 2024
     */
    @isTest
    public static void testBlankString() {
        Map<String, Object> userData = ECOM_SelfServiceUtils.getUserData('');
        Object success = userData.get('success');
        Assert.isNull(success, 'Check self service get user data failure.');
    }

    /**
     * @description This method tests self service exceptions getting logged successfully
     * @author abhishek.joshi@revvity.com | 10 October 2024
     */
    @isTest
    public static void testSelfserviceLogException() {
        Test.startTest();

        String methodName = 'testSelfserviceLogException';
        String supportData = 'test support data';
        Map<String, Object> logMap = new Map<String, Object>{
            'className' => (Object) 'ECOM_SelfServiceUtils_Test',
            'methodName' => (Object) methodName,
            'moduleName' => (Object) 'SelfService',
            'supportData' => (Object) supportData
        };

        try {
            Map<String, String> testMap = new Map<String, String>();
            String testString = testMap.get('test').capitalize();
        } catch (Exception e) {
            ECOM_SelfServiceUtils.selfserviceLogException(logMap, e);

            ECOM_Application_Logs__c log = [SELECT SupportData__c FROM ECOM_Application_Logs__c WHERE MethodName__c =: methodName LIMIT 1];

            Assert.areEqual(logMap.get('supportData'), log.SupportData__c, 'Test self service exceptions getting logged successfully');
        }

        Test.stopTest();
    }
}