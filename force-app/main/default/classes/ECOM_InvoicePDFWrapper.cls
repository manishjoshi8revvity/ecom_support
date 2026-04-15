/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-1931    
*
* 2. Description - This class is a wrapper class for API call in ECOM_InvoiceService
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
*    - 
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - garora@rafter.one | 12 June 2024

*************************************************************/
public class ECOM_InvoicePDFWrapper {
    public class Request{
        @AuraEnabled public String invoiceId{get;set;}
        @AuraEnabled public String invoiceNumber{get;set;}
        @AuraEnabled public String salesOrg{get;set;}
    }

    public class Response{
        @AuraEnabled public String message{get;set;}
        @AuraEnabled public String url{get;set;}
        @AuraEnabled public String code{get;set;}
    }
}