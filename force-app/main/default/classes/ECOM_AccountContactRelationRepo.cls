/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-639    
*	 ECOM-659 
* 2. Description - This class is used to retrieve account contact relation.
*   - return List of Associated Account Ids.
*   - return List of Account Contact Relation Record
*
*
*
* 3. Objects referenced
*    -AccountContactRelation
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
*
* 5. Dependant Class(es):
*    - ECOM_AccountUtil
*    - ECOM_AccountService
*	 - ECOM_ContactController
* 6. Test Class Name: 
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vipul 2023.07.19

*************************************************************/
public class ECOM_AccountContactRelationRepo {
    

    /**
    * @description  This method is used to retrieve accounts from AccountContactRelation based on contact Id
    * @author Vipul 2023.07.19
    * @param contactId 
    * @return List<String> 
    **/
    /*public static List<String> getAssociatedAccounts(String contactId)
    {
        List<AccountContactRelation> lstAccountContactRelations = fetchAccountContactRelations(contactId);
        List<String> accountIds = new List<String>();
        if(lstAccountContactRelations!=null && lstAccountContactRelations.size()>0)
        {
            for (AccountContactRelation accountContactRelationObj : lstAccountContactRelations)
            {
                accountIds.add(accountContactRelationObj.AccountId);
            }
        }
        return accountIds;
    }*/

    /**
    * @description  This method is fetche AccountContactRelation based of contact
    * @author Vipul 2023.07.19
    * @param strContactId
    * @return List<AccountContactRelation>
    **/
    /*public static List<AccountContactRelation> fetchAccountContactRelations(String strContactId)
    {
        List<AccountContactRelation> lstAccountContactRelations = null;
        if(String.isNotBlank(strContactId))
        {
            lstAccountContactRelations = [SELECT Id, ContactId, accountId, IsDirect FROM AccountContactRelation WHERE ContactId = :strContactId];
        }
        return lstAccountContactRelations;
    }*/

    /**
    * @description 
    * @author Vipul Goyal | 11-12-2023 
    * @param contactId 
    * @param accountId 
    * @return Map<String, Object> 
    **/
    public static void deleteTemporaryACR(String contactId,String accountId)
    {
        List<AccountContactRelation> acrs=[
                                            SELECT Id 
                                            FROM 
                                            AccountContactRelation
                                            WHERE 
                                            ContactId=:contactId
                                            AND
                                            accountId =:accountId
                                          ];
        if(!acrs.isEmpty())
        {
            delete acrs;
        }
    }
}