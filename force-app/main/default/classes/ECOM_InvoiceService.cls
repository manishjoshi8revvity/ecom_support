/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-112
*
* 2. Description - This class is used to fetch Order Summary/Order Items/SAP Order Summary details.
*
* 3. Objects referenced
*    - Invoice
*	 - Case
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
* 5. Dependant Class(es):
* 	 - ECOM_InvoiceController
*	
* 6. Test Class Name: 
*    - ECOM_InvoiceController_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Gaurang 2024.10.05
*    - Gaurang 2024.11.06 - added invoicePDFCall for updating and calling API for invoice pdf - ECOM-1831
*************************************************************/
public without sharing class ECOM_InvoiceService {

    /**
    * @description This method is used to get ECOM_Invoice__c and ECOM_InvoiceLine__c records for an id
    * @author Gaurang ARora | 05-10-2024
    * @param orderId 
    * @return List<ECOM_Invoice__c>
    **/
    public static List<ECOM_Invoice__c> getInvoiceById(String invoiceId)
    {
        return ECOM_InvoiceRepo.getInvoiceById(invoiceId);
    }

    /**
    * @description This method returns calls repo method for case insertion
    * @author Gaurang Arora | 05-10-2024 
    * @param invoiceCase 
    * @return Case
    **/
    public static Case insertCase(Case invoiceCase){
        return ECOM_InvoiceRepo.insertCase(invoiceCase);
    }

    /**
    * @description This method returns Invoice after updating the same
    * @author Gaurang Arora | 05-28-2024 
    * @param ECOM_Invoice__c 
    * @return ECOM_Invoice__c
    **/
    public static ECOM_Invoice__c updateInvoice(ECOM_Invoice__c invoice){
        return ECOM_InvoiceRepo.updateInvoice(invoice);
    }

    /**
    * @description This method returns Invoice after updating the same
    * @author Gaurang Arora | 06-06-2024 
    * @param ECOM_InvoicePDFWrapper.Request | invoice
    * @return Map<String,Object>
    **/
    public static Map<String,Object> invoicePDFCall(ECOM_InvoicePDFWrapper.Request invoiceRequest){
        Map<String,String> requestMap = new Map<String,String>();
        ECOM_InvoicePDFWrapper.Response apiResponse = new ECOM_InvoicePDFWrapper.Response();
        Map<String,Object> returnMap = new Map<String,Object>();
        requestMap.put(ECOM_Constant.ACTION_TYPE, 'invoicePDF');
        requestMap.put(ECOM_Constant.HTTP_REQUEST_TYPE, ECOM_Constant.HTTP_REQUEST_POST);
        requestMap.put(ECOM_Constant.HTTP_REQUEST_BODY,JSON.serialize(invoiceRequest));
        HttpResponse response = ECOM_RestService.doBasicHttpRequest(requestMap);
        if(response.getStatusCode() == 200){
            apiResponse = (ECOM_InvoicePDFWrapper.Response)JSON.deserialize(response.getBody(), ECOM_InvoicePDFWrapper.Response.class);
            if(apiResponse.message.equalsIgnoreCase('success') && String.isNotBlank(apiResponse.url)){
                ECOM_Invoice__c invoice = new ECOM_Invoice__c();
                invoice.Id = invoiceRequest.invoiceId;
                invoice.ECOM_URL_Generated_Time__c = Datetime.now();
                invoice.ECOM_Download_URL__c = apiResponse.url;
                updateInvoice(invoice);
                returnMap.put('Status','Success');
                returnMap.put('downloadUrl',invoice.ECOM_Download_URL__c);
            }
            else{
                returnMap.put('Status','Error');
            }
        }
        else{
            returnMap.put('Status','Error');
        }
        return returnMap;
    }

}