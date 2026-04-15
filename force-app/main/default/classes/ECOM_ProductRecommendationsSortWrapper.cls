/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    RWPS-4437
*
* 2. Description - This class is a controller for Product Recommendations
*
* 3. Objects referenced
*
* 4. Callouts to additional Components (including their methods) or None: None
*
* 5. Dependant Class(es):
*
* 6. Test Class Name:
*    - ECOM_ProductRecommendationsSortWrapper_Test
*
* 7. Is @Invocable: No
*
* 8. Author Name(s):
*    - Abhishek Joshi 2025.09.15 - Created the class - RWPS-4437
*************************************************************/

public without sharing class ECOM_ProductRecommendationsSortWrapper implements Comparable {
    public Map<String,Object> record;

    public ECOM_ProductRecommendationsSortWrapper(Map<String,Object> record) {
        this.record = record;
    }

    private Integer compareDecimals(Decimal a, Decimal b, Boolean isAscending) {
        if (a > b) return isAscending ? 1 : -1;
        if (a < b) return isAscending ? -1 : 1;
        return 0;
    }

    public Integer compareTo(Object compareTo) {
        ECOM_ProductRecommendationsSortWrapper compareToMap = (ECOM_ProductRecommendationsSortWrapper)compareTo;

        Integer compareResult = 0;

        compareResult = compareDecimals((Decimal) record.get('score'), (Decimal) compareToMap.record.get('score'), false);
        if (compareResult != 0) { return compareResult; }

        compareResult = compareDecimals((Decimal) record.get('sameOrderCount'), (Decimal) compareToMap.record.get('sameOrderCount'), false);
        if (compareResult != 0) { return compareResult; }

        compareResult = compareDecimals((Decimal) record.get('count'), (Decimal) compareToMap.record.get('count'), false);
        if (compareResult != 0) { return compareResult; }

        compareResult = compareDecimals((Decimal) record.get('recency'), (Decimal) compareToMap.record.get('recency'), true);
        if (compareResult != 0) { return compareResult; }

        String prodId = (String) record.get('prodId');
        String compareToProdId = (String) compareToMap.record.get('prodId');
        return prodId.compareTo(compareToProdId);
    }
}