/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-    
*
* 2. Description - This class is a wrapper class for SUB.FLOW_4494: ECOM - User Registration and SUB.FLOW_4495: ECOM - User Registration Account.
*
*
*
* 3. Objects referenced
*    -None
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
*
* 5. Dependant Class(es):
*    - None
*	
* 6. Test Class Name:         
*    - ECOM_UserRegistrationAddressWrapper_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vipul 2023.07.19

*************************************************************/
global class ECOM_UserRegistrationAddressWrapper {
 
    @AuraEnabled
    global String country;
    @AuraEnabled
    global String state;
    @AuraEnabled
    global String city;
    @AuraEnabled
    global String street;
    @AuraEnabled
    global String zipcode;

}