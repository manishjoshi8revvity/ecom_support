/**************************************************************

* 1. Jira Ticket(s) that relates to this class
    - RWPS-5611
*
* 2. Description - This class is a test class.
*
* 3. Objects referenced
*    - None
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_TextFlowWrapper
*
* 6. Test Class Name:
*    -None
*
* 7. Is @Invocable : No
*
* 8. Author Name(s):
*    - Sachin V 2026.01.07 Created the class and method testSplitText - RWPS-5611

*************************************************************/


@isTest(SeeAllData=false)
private with sharing class ECOM_TextFlowWrapper_Test {

    /**
     * @description This test method is to test splitText method in ECOM_Util class.
     * @author Sachin V | 2026.01.06 | RWPS-5611
     */
    @isTest
    static void testSplitText() {
        ECOM_TextFlowWrapper.RequestWrapper input = new ECOM_TextFlowWrapper.RequestWrapper();
        List<ECOM_TextFlowWrapper.ResponseWrapper> outputList = new List<ECOM_TextFlowWrapper.ResponseWrapper>();
        input.inputText = '(Value1, Value2, Value3)';
        input.separator = ',';
        Test.startTest();
        outputList = ECOM_TextFlowWrapper.splitText(new List<ECOM_TextFlowWrapper.RequestWrapper>{ input });
        Test.stopTest();
        Assert.areEqual(false, outputList.isEmpty() && outputList[0].splitValues.isEmpty(), 'The splitValues list should contain splitted elements.');
        Assert.areEqual(false, outputList.isEmpty() && String.isNotBlank(outputList[0].formattedValues), 'The formattedValues should not be blank.');
    }
}