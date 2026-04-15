/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-112
*
* 2. Description - This class acts as an Repository class for Invoice.
*
* 3. Objects referenced
*    - Invoice
* 	 - Invoice Line
*    - Case
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
* 5. Dependant Class(es):
*    - ECOM_InvoiceService
*    - ECOM_InvoiceController
*   
* 6. Test Class Name: 
*    - ECOM_OrderService_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Gaurang 2024.05.09
*    - Gaurang 2024.05.24 - additional fields added in query - ECOM-3271
*    - Gaurang 2024.06.12 - added update method for invoice - ECOM-1931
*    - Gaurang 2024.07.19 - Added additional field
*    - Sathiya 2024.11.12 - Added additional field - RWPS-1990
*************************************************************/

public without sharing class ECOM_InvoiceRepo {

    /**
    * @description This query returns ECOM_Invoice__c and ECOM_InvoiceLine__c records for an id
    * @author Gaurang Arora | 05-10-2024 
    * @param invoiceId 
    * @return List<ECOM_Invoice__c>
    **/
    public static List<ECOM_Invoice__c> getInvoiceById(String invoiceId){
        return [SELECT Id,Name,ECOM_Invoice_Date__c,ECOM_Total_Items__c, ECOM_SubTotal__c, ECOM_Tax__c,ECOM_Total__c, CurrencyIsoCode, ECOM_Download_URL__c,
        ERP_Invoice_Number__c, ECOM_URL_Generated_Time__c, //ECOM-3271,1931 - Gaurang - additional fields added in query - 24 May 2024
        ECOM_SAP_Order_Summary__c, //Gaurang - 18 July 2024 - added field
        ECOM_PDF_Enabled__c , //Sathiya - 12 Nov 2024 - added field
        (SELECT Id, ECOM_Product__c, ECOM_Product__r.Name, ECOM_Product__r.Part_Number__c, ECOM_Product__r.ECOM_Product_Media_URI__c, Part_Number__c, CurrencyIsoCode, ECOM_Quantity__c, ECOM_List_Price__c, ECOM_SubTotal__c, ECOM_Tax__c, ECOM_Total__c
        FROM Invoice_Lines__r WHERE ECOM_Quantity__c>0)  FROM ECOM_Invoice__c WHERE Id = :invoiceId];
    }

    /**
    * @description This method returns Case number after inserting the same
    * @author Gaurang Arora | 05-10-2024 
    * @param invoiceCase 
    * @return Case
    **/
    public static Case insertCase(Case invoiceCase){
        insert invoiceCase;
        invoiceCase = [SELECT Id,CaseNumber FROM Case WHERE Id = :invoiceCase.Id];
        return invoiceCase;
    }

     /**
    * @description This method returns Invoice after updating the same
    * @author Gaurang Arora | 05-28-2024 
    * @param ECOM_Invoice__c 
    * @return ECOM_Invoice__c
    **/
    public static ECOM_Invoice__c updateInvoice(ECOM_Invoice__c invoice){
        update invoice;
        return invoice;
    }
}