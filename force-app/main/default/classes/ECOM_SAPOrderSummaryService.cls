/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-110  
*
* 2. Description - This class is used to process SAP Order Summary and SAP order items and SAP order summary trackings.
*
*
*
* 3. Objects referenced
*    -SAP Order Summary
*   - SAP Order Items
*   - SAP Order Item Tracking
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
*
* 5. Dependant Class(es):
*    - ECOM_SAPOrderSummaryRepo
*
* 6. Test Class Name: ECOM_SAPOrderSummaryService_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Rani Thumma 2023.09.12
*	 - Vasudev Ramachandran | 11 Dec 2023
*    - Sidak 2024.06.20 Updated parameter to pass contact email list in findSapOrderByOrderNumberAndZip, findPunchoutSapOrderByOrderNumberAndZip, fetchSAPOrderSummariesByEmail, fetchSAPOrderByEmailAndSourceType methods. Ticket - RWPS-313
*    - Gaurav 2025.07.25 - fetchSAPOrdersByEmail created to return order based on email RWPS-3741
*    - Prabhat 2025.09.23  Updated method fetchSAPOrdersByEmail to include email type in the parameter - RWPS-4131
*    - Poonam 2025.10.03  Updated method fetchSAPOrdersByEmail to include alternateEmailList in the parameter - RWPS-4082
*    - Poonam 2025.10.07 Updated method fetchSAPOrdersByEmail to include Contact email in parameter - RWPS-4443
*************************************************************/
public with sharing class ECOM_SAPOrderSummaryService implements ECOM_ISAPOrderSummary{
    
    public static List<SAP_Order_Summary__c> fetchSAPOrderSummariesById(Set<String> summaryIds){
        List<SAP_Order_Summary__c> orderSAPSummaries = ECOM_SAPOrderSummaryRepo.fetchSAPOrderSummariesById(summaryIds);
        return orderSAPSummaries;
    }

    public static List<SAP_Order_Summary__c> fetchSAPOrderSummariesByEmail(List<String> contactEmailList, Date sapOrderStartDate, Date sapOrderEndDate){
        List<SAP_Order_Summary__c> orderSAPSummaries = ECOM_SAPOrderSummaryRepo.fetchSAPOrderSummariesByEmail(contactEmailList, sapOrderStartDate, sapOrderEndDate);
        return orderSAPSummaries;
    }

    public static List<SAP_Order_Summary__c> findSapOrderByOrderNumberAndZip(List<String> contactEmailList, String orderNumber, String zipCode) {
        List<SAP_Order_Summary__c> orderSummaryList = ECOM_SAPOrderSummaryRepo.findSapOrderByOrderNumberAndZip(contactEmailList, orderNumber, zipCode);
        return orderSummaryList;
    }
    public static List<SAP_Order_Item_Tracking__c> getSAPOrderItemTrackings(Set<String> itemIds) {
        List<SAP_Order_Item_Tracking__c> orderItemtrackings = ECOM_SAPOrderSummaryRepo.getSAPOrderItemTrackings(itemIds);
        return orderItemtrackings;
    }

    public static List<Product2> getProductsBasedOnPartnumber(Set<String> partNumbers){
        return ECOM_SAPOrderSummaryRepo.getProductsBasedOnPartnumber(partNumbers);
    }
    
    /**
     * @description This method returns the order summary and items based on contact email and order source type
     * @author vramachandran@rafter.one | 14 Dec 2023
     * @param contactEmail | String 
     * @param sourceTypes | List<String>
     * @param sapOrderStartDate | Date
     * @param sapOrderEndDate | Date
     * @return List<SAP_Order_Summary__c>
     */
    public static List<SAP_Order_Summary__c> fetchSAPOrderByEmailAndSourceType(List<String> contactEmailList, List<String> sourceTypes,  Date sapOrderStartDate, Date sapOrderEndDate){
        List<SAP_Order_Summary__c> orderSAPSummaries = ECOM_SAPOrderSummaryRepo.fetchSAPOrderByEmailAndSourceType(contactEmailList, sourceTypes, sapOrderStartDate, sapOrderEndDate);
        return orderSAPSummaries;
    }
    
    /**
     * @description This method returns the order summary and items based on contact email and order source type
     * @author vramachandran@rafter.one | 14 Dec 2023
     * @param contactEmail | String 
     * @param orderNumber | String
     * @param zipCode | String
     * @return List<SAP_Order_Summary__c>
     */
    public static List<SAP_Order_Summary__c> findPunchoutSapOrderByOrderNumberAndZip(List<String> contactEmailList, String orderNumber, String zipCode){
        List<SAP_Order_Summary__c> orderSAPSummaries = ECOM_SAPOrderSummaryRepo.findPunchoutSapOrderByOrderNumberAndZip(contactEmailList, orderNumber, zipCode);
        return orderSAPSummaries;
    }

     /**
     * @description This method returns the order summary and items based on contact email
     * @author Gaurav |  RWPS-3741
     * @param contactEmailList | List<String> 
     * @param selectedEmailType | String 
     * @return List<SAP_Order_Summary__c>
     */
    public static List<SAP_Order_Summary__c> fetchSAPOrdersByEmail(List<String> contactEmailList,String selectedEmailType, List<String> alternateEmailList, String contactEmail){//RWPS-4131 //RWPS-4082 //RWPS-4443
        List<SAP_Order_Summary__c> orderSAPSummaries = ECOM_SAPOrderSummaryRepo.fetchSAPOrdersByEmail(contactEmailList,selectedEmailType, alternateEmailList, contactEmail);//RWPS-4131 //RWPS-4082 //RWPS-4443
        return orderSAPSummaries;
    }
}