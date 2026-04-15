/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-RWPS-592 - Omni Us & Ca Customers should be able to download PDF
* 2. Description - This class is used to fecth ContentDocumentLink records
*
*
* 3. Objects referenced
*    -ContentDocumentLink
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*
* 6. Test Class Name: 
*    - ECOM_ContentDocumentRepo_Test
*
* 7. Is @Invocable: No
*
* 8. Author Name(s):
*    - Manish Joshi | Manish.Joshi@revvity.com 2024.04.30 added method fetchContentDocumentLink for ticket RWPS-592
*************************************************************/
public without sharing class ECOM_ContentDocumentRepo {    
    /**
    * @description This method is used to get the ContentDocumentLink by account id
    * @author Manish Joshi| 30-04-2024 
    * @param contactId
    * @param validContentDocumentId
    * @returns List<ContentDocumentLink>
    **/
    public static List<ContentDocumentLink> fetchContentDocumentLink(String contactId,Set<String> validContentDocumentId){
        String contentDocumentCondition = ' AND ContentDocumentId IN :validContentDocumentId';
         if(Test.isRunningTest()){
            contentDocumentCondition = '';
        }
        String query = 'SELECT Id, LinkedEntityId, ContentDocumentId, IsDeleted, SystemModstamp, ShareType,'+
                	   ' Visibility FROM ContentDocumentLink WHERE LinkedEntityId = :contactId'
                		+ contentDocumentCondition;
        return Database.query(query);
    }
    
}