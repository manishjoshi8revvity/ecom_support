/**************************************************************
 * 1. Ticket(s) that relates to this class
 *	 -
 * 2. Description - This is a wrapper class used in SUB_FLOW_4497_ECOM_Fetch_Account_Details flow to 
 * 					create apex varaible for response of fetch Account details.
 *					
 *
 * 3. Objects referenced
 * - Account
 * 
 *
 * 4. Callouts to additional Components (including their methods) or None:
 * - None
 *
 * 5. Dependant Class(es):
 * - ECOM_AccountDetailsController
 * - ECOM_AccountWrapper
 *
 * 6. Test Class Name: Test_Class_Name
 *
 * 7. Is @Invocable (Yes or No): No
 *
 * 8. Author Name(s): 
 * - vramachandran@rafter.one | 11 Dec 2023
 *
*************************************************************/ 
public class ECOM_PunchoutAccountModel {
    @AuraEnabled
    public String accountName;
    @AuraEnabled
    public String accountLogo;
    @AuraEnabled
    public String productCatalogIncludeQuery;
    @AuraEnabled
    public String productCatalogExcludeQuery;
    @AuraEnabled
    public Boolean displayListPrice;
}