/**************************************************************

* 1. Jira Ticket(s) that relates to this class
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
*    - ECOM_TestUtil
*    - ECOM_UserFlowServiceWrapper
*
* 6. Test Class Name:
*    -None
*
* 7. Is @Invocable : No
*
* 8. Author Name(s):
*    - Manoj 2023.09.19

*************************************************************/


@isTest(SeeAllData=false)
private class ECOM_UserFlowServiceUtil_Test {

//Test for DataWrapper method
@isTest
static void testGetSuppressedLastName() {
    List<ECOM_UserFlowServiceWrapper.DataWrapper> dataWrapList= new List <ECOM_UserFlowServiceWrapper.DataWrapper>();
    ECOM_UserFlowServiceWrapper.DataWrapper dataWrap=new ECOM_UserFlowServiceWrapper.DataWrapper();
    dataWrap.lastname='testLastName';
    dataWrapList.add(dataWrap);
    
    //Calling the getSuppressedLastName method
    Test.startTest();
    String result = ECOM_UserFlowServiceUtil.getSuppressedLastName(dataWrapList);
    Test.stopTest();
    
    //Validating the result
    System.assertEquals('testL', result,'Ecpected was testL');

}

//Test for generateRandomString method
@isTest
static void testGenerateRandomString() {
    Integer len = 5;
    
    //Calling the generateRandomString method
    Test.startTest();
    String result = ECOM_UserFlowServiceUtil.generateRandomString(len);
    Test.stopTest();
    
    //Validating the result
    System.assertEquals(5, result.length(),'Expected string length 5');

}

}