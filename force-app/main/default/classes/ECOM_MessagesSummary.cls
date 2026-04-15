/**************************************************************
 * 1. Jira Ticket(s) that relates to this class
 *    ECOM-493
 * 
 * 2. Description - This class acts as a data wrapper class.
 * 
 * 3. Objects referenced
 *    - None
 * 
 * 4. Callouts to additional Components (including their methods) or None:
 *    - None
 * 
 * 5. Dependant Class(es):
 *    - ECOM_CartModel
 *    - ECOM_CartService
 *    - ECOM_CartUtil
 * 
 * 6. Test Class Name: ECOM_CartUtil_Test
 * 
 * 7. Is @Invocable (Yes or No): No
 * 
 * 8. Author Name(s):
 *    - mkumar@rafter.one 08-02-2023
 *************************************************************/
public with sharing class ECOM_MessagesSummary {
    @AuraEnabled public boolean hasErrors;
    @AuraEnabled public String message;
    @AuraEnabled public String relatedEntityId;    
}