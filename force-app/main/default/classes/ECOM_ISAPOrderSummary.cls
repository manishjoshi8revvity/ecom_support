/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-110  
*
* 2. Description - This class is used for SAP Order Summary transactions .
*
* 3. Objects referenced
*    -SAP Order Summary
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
* 5. Dependant Class(es):
*    - ECOM_SAPOrderSummaryService
* 	 - ECOM_OrderSyncFlowController
*
* 6. Test Class Name: 
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Rani Thumma 2023.09.12
* 	 - vramachandran@rafter.one | 12 Dec 2023
*    - Sidak 2024.06.20 Updated parameter to pass contact email list in fetchSAPOrderByEmailAndSourceType. Ticket - RWPS-313
*************************************************************/
public interface ECOM_ISAPOrderSummary {
    
    List<SAP_Order_Summary__c> fetchSAPOrderSummariesById(Set<String> summaryIds);
    //Set<String> getFrequentlyBoughtProductsForAccountId(String accountId); //VRa - Punchout changes
    //List<ECOM_OrderModel> getSapOrderModel();//VRa - Punchout changes
    List<SAP_Order_Summary__c> fetchSAPOrderByEmailAndSourceType(List<String> contactEmail, List<String> sourceTypes,  Date sapOrderStartDate, Date sapOrderEndDate);//VRa - Punchout changes
    
}