/**************************************************************

* 1. Jira Ticket(s) that relates to this class
*  
*
* 2. Description - This is a test class
*
* 3. Objects referenced
*    - 
*	 

* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_TestUtil
*    

* 6. Test Class Name:
*
* 7. Is @Invocable : No
*
* 8. Author Name(s):
*    - Sukumar 2023.09.19
*************************************************************/
@isTest
private class ECOM_SiteURL_Test {
    @isTest
    static void testGetValues() {       
        User u = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Test.startTest();
        ECOM_SiteURL dynamicPickList = new ECOM_SiteURL();
        VisualEditor.DynamicPickListRows result;
        System.runAs(u){
            result = dynamicPickList.getValues();
        }
        
        Test.stopTest();
        
    }
    
    @isTest
    static void testGetDefaultValue() {
        User u = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        Test.startTest();
        ECOM_SiteURL dynamicPickList = new ECOM_SiteURL();
        VisualEditor.DataRow result;
        System.runAs(u){
            result = dynamicPickList.getDefaultValue();  
        }
        
        Test.stopTest();
    }
}