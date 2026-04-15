/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    RWPS-4437
*
* 2. Description - This class contains the repository layer for Product Recommendations
*
* 3. Objects referenced
*
* 4. Callouts to additional Components (including their methods) or None:
*    None
*
* 5. Dependant Class(es):
*
* 6. Test Class Name:
*    - ECOM_ProductRecommendationsUtil_Test
*
* 7. Is @Invocable: No
*
* 8. Author Name(s):
*    - Abhishek Joshi 2025.09.15 - Created the class - RWPS-4437
*    - Abhishek Joshi 2025.11.13 - Added methods getProductsByIdsAndFilter and getProductsForPartNumbersAndFilter - RWPS-5223
*    - Prabhat Kumar 2025.12.03 -Created method getRecommendationsTrainingProducts  - RWPS-4896
*    - Prabhat Kumar 2025.12.16 - Modified method getRecommendationsTrainingProducts  - RWPS-4896

*************************************************************/

public without sharing class ECOM_ProductRecommendationsRepo {


    /**
    * @description get Recommendations
    * @author Prabhat Kumar
    * @param recommendationType | String
    * @param productIds | Set<String>
    * @return List<Product_Recommendation__c>
    **/
    public static List<Product_Recommendation__c> getRecommendationsTrainingProducts(String recommendationType, Set<String> productIds) {
        if (productIds.isEmpty() == false) {
            return [
                SELECT
                    Product_Main__c, Product_Suggested__c, Rank__c, Suggest_Type__c, Use_Case_Type__c,Product_Suggested__r.Part_Number__c
                FROM Product_Recommendation__c
                WHERE
                    (Product_Main__c IN :productIds OR Product_Suggested__c IN :productIds) AND
                    Suggest_Type__c = :recommendationType AND Active__c = TRUE
            ];
        //RWPS-4896 - Start
        } else {
            return [
                SELECT
                    Product_Main__c, Product_Suggested__c, Rank__c, Suggest_Type__c, Use_Case_Type__c,Product_Suggested__r.Part_Number__c
                FROM Product_Recommendation__c
                WHERE
                    Product_Main__c != null AND Product_Suggested__c != null AND
                    Suggest_Type__c = :recommendationType AND Active__c = TRUE
            ];
        }
        //RWPS-4896 - End
    }


    /**
    * @description get cached Recommendations
    * @author Abhishek Joshi
    * @param recommendationType | String
    * @param productIds | List<String>
    * @return List<Product_Recommendation__c>
    **/
    public static List<Product_Recommendation__c> getCachedECOMRecommendation(String recommendationType, List<String> productIds, List<String> excludedProductIds) {
        return [
            SELECT
                Active__c, LastModifiedDate, ExternalId__c, Group__c, Product_Main__c, Product_Suggested__c, Rank__c, Suggest_Type__c, Use_Case_Type__c,
                Product_Suggested__r.Id, Product_Suggested__r.Name, Product_Suggested__r.Part_Number__c, Product_Suggested__r.Dangerous_Goods_Indicator_Profile__c, Product_Suggested__r.Product_Model_Identifier__c, Product_Suggested__r.Product_Model_Name__c, Product_Suggested__r.DisplayUrl, Product_Suggested__r.ECOM_Product_Media_URI__c, Product_Suggested__r.Product_Display_Name__c
            FROM Product_Recommendation__c
            WHERE
                Product_Main__c IN :productIds AND
                Suggest_Type__c = :recommendationType AND
                Use_Case_Type__c = 'Web' AND
                Product_Suggested__c NOT IN :excludedProductIds
            ORDER BY Rank__c DESC
            LIMIT 300
        ];
    }

    /**
     * @description This method returns the order items in a particular time period which belong to a list of part numbers
     * @author Abhishek Joshi 2025.09.15
     * @param partNumbers | List<String>
     * @param startDate | Date
     * @param endDate | Date
     * @return List<SAP_Order_Items__c>
     */
    public static List<SAP_Order_Items__c> fetchSAPOrderItemsByDateAndPartNumber(List<String> partNumbers, Date startDate, Date endDate){
        return [
            SELECT PKI_Order_Summary__r.Sold_To_Customer_Id__c, PKI_Order_Summary__r.Bill_To_Customer_Id__c, PKI_Order_Summary__r.Contact_Email__c, PKI_Order_Summary__r.ShipTo_Email__c, PKI_Order_Summary__r.Name, Material_Number__c
            FROM SAP_Order_Items__c
            WHERE
                Material_Number__c IN :partNumbers AND
                PKI_Order_Summary__r.Sold_To_Customer_Id__c != null AND
                PKI_Order_Summary__r.fxStatusB2B__c != 'Cancelled' AND
                (
                    (
                        PKI_Order_Summary__r.Actual_Order_Date__c >= :startDate AND
                        PKI_Order_Summary__r.Actual_Order_Date__c <= :endDate
                    )
                    OR
                    (
                        PKI_Order_Summary__r.Actual_Order_Date__c = null AND
                        DAY_ONLY(PKI_Order_Summary__r.CreatedDate) >= :startDate AND
                        DAY_ONLY(PKI_Order_Summary__r.CreatedDate) <= :endDate
                    )
                )
            ORDER BY PKI_Order_Summary__r.Actual_Order_Date__c DESC, PKI_Order_Summary__r.CreatedDate DESC
            LIMIT 50000
        ];
    }

    /**
    * @description Fetch Products by Ids and filter
    * @author Abhishek Joshi | 2025.11.13 | RWPS-5223
    * @param ids | List<String>
    * @param filter | String
    * @return List<Product2>
    **/
    public static List<Product2> getProductsByIdsAndFilter(List<String> ids, String filter){
        String query = 'SELECT Id, Name,Part_Number__c,IGOR_Item_Class_Desc__c,IGOR_Description__c,Product_Line_Name__c, StockKeepingUnit,Dangerous_Goods_Indicator_Profile__c,Type ,Business_Unit__c, Discount_Type__c, Item_Class__c, Part_Type__c, Product_Line__c, Product_Type__c,IGOR_PAC__c,Sub_Business_Unit__c,Super_Business_Unit__c, Product_Model_Identifier__c FROM Product2 WHERE Id IN :ids';
        if(String.isNotBlank(filter)) {
            query += ' AND ' + filter;
        }
        return Database.query(query);
    }

    /**
    * @description Fetch Products by part numbers and filter
    * @author Abhishek Joshi | 2025.11.13 | RWPS-5223
    * @param partNumbers | Set<String>
    * @param filter | String
    * @return List<Product2>
    **/
    public static List<Product2> getProductsForPartNumbersAndFilter(Set<String> partNumbers, String filter){
        String query = 'SELECT Id, Name, Part_Number__c, DisplayUrl, Dangerous_Goods_Indicator_Profile__c, ECOM_Product_Media_URI__c, Product_Display_Name__c, Product_Model_Identifier__c, Product_Model_Name__c FROM Product2 WHERE Part_Number__c IN : partNumbers';
        if(String.isNotBlank(filter)) {
            query += ' AND ' + filter;
        }
        return Database.query(query);
    }
}