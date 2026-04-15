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
* 	 - ECOM_InvoiceService
*    - ECOM_InvoiceRepo
*	
* 6. Test Class Name: 
*    - ECOM_InvoiceController_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Gaurang 2024.10.05
*    - Gaurang 2024.05.24 additional fields added for mapping - ECOM-3217
*    - Gaurang 2024.05.28 invoicePDF method added for fetching an updating download url - ECOM-1931
*    - Gaurang 2024.06.24 changes to submitCase method as per ECOM-3304
*    - Gaurang 2024.07.18 modified getInvoiceAndOrderDetails method
*	 - Sathiya 2024.11.12 Adding new field for invoice field PDF fix RWPS-1990
*	 - Manish Joshi 2025.04.28 Updated method getInvoiceAndOrderDetails & added tarrif data RWPS-3026

*************************************************************/

public without sharing class ECOM_InvoiceController {
    
    /**
    * @description  to fetch invoice details
    * @author garora@rafter.one | 28-05-2024 
    * @param Id 
    * @return List<ECOM_Invoice__c>
    **/

    @AuraEnabled
    public static List<ECOM_Invoice__c> getInvoice(String invoiceId){
      List<ECOM_Invoice__c> invoices = new List<ECOM_Invoice__c>();
      try {
        invoices =  ECOM_InvoiceService.getInvoiceById(invoiceId);
      } catch (Exception e) {
        ECOM_ApplicationLogsUtil.logFailure(e , 'ECOM_InvoiceController :: getInvoice' , 'ECOM_InvoiceController' , 'getInvoice',' Stack:: '+ e.getStackTraceString() + ' Error:: '+e.getMessage());
      }
      return invoices;
    }


    /**
    * @description  to prepare order model with invoice and invoice lines
    * @author garora@rafter.one | 09-05-2024 
    * @param Id,Id 
    * @return Map<String,Object> 
    **/
    @AuraEnabled
    public static Map<String,Object> getInvoiceAndOrderDetails(Id orderId, Id invoiceId) {
      Map<String,Object> responseMap = ECOM_OrderHistoryController.getOrderDetails(orderId);
      Map<String,Double> productToTarrifMap = new Map<String,Double>();
      try{
        if(responseMap.get('orderModel')!=null){
          List<ECOM_Invoice__c> invoices = ECOM_InvoiceService.getInvoiceById(invoiceId);
          ECOM_OrderModel orderModel = (ECOM_OrderModel) responseMap.get('orderModel');
          //RWPS-3026 - START
          for(ECOM_OrderModel.OrderItems rec:orderModel.orderItems){
              if(rec.tariffSurcharge!=null && rec.tariffSurcharge>0){
              	productToTarrifMap.put(rec.product2Id+String.valueOf(Integer.valueOf(rec.quantity)),rec.tariffSurcharge);
              }
        
          }
          //RWPS-3026 - ENDS
          ECOM_OrderModel.Invoice invoice = new ECOM_OrderModel.Invoice();
          invoice.Id = invoices[0].Id;
          invoice.name = invoices[0].Name;
          invoice.invoiceDate = invoices[0].ECOM_Invoice_Date__c;
          invoice.totalItems = invoices[0].ECOM_Total_Items__c;
          invoice.currencyIsoCode = invoices[0].CurrencyIsoCode;
          invoice.subtotal = invoices[0].ECOM_SubTotal__c;
          invoice.tax = invoices[0].ECOM_Tax__c;
          invoice.total = invoices[0].ECOM_Total__c;
          //ECOM-3217 - Gaurang - additional fields added for mapping - 24 May 2024 - starts
          invoice.downloadUrl = invoices[0].ECOM_Download_URL__c;
          invoice.invoiceNumber = invoices[0].ERP_Invoice_Number__c;
          //ECOM-3217 - Gaurang - additional fields added for mapping - 24 May 2024 - ends
          //RWPS-1990 - Sathiya - enable pdf when the flag is set to true - 12 Nov 2024 - starts
          invoice.isPDFEnabled = invoices[0].ECOM_PDF_Enabled__c;
          //RWPS-1990 - Sathiya - enable pdf when the flag is set to true - 12 Nov 2024 - starts
          List<ECOM_OrderModel.InvoiceLine> invoiceLines = new List<ECOM_OrderModel.InvoiceLine>();
          system.debug('invoicelines:: ' + invoices);
          system.debug('invoicelines:: ' + invoices[0].Invoice_Lines__r);
          for(ECOM_InvoiceLine__c line: invoices[0].Invoice_Lines__r){
            ECOM_OrderModel.InvoiceLine invoiceLine = new ECOM_OrderModel.InvoiceLine();
            invoiceLine.Id = line.Id;
            invoiceLine.productId = line?.ECOM_Product__c;
            invoiceLine.name = line?.ECOM_Product__r?.Name;
            invoiceLine.partNumber = line?.Part_Number__c == null?line.ECOM_Product__r.Part_Number__c:line?.Part_Number__c;
            invoiceLine.currencyIsoCode = invoices[0]?.CurrencyIsoCode;
            invoiceLine.listPrice = line?.ECOM_SubTotal__c!=null && line?.ECOM_SubTotal__c>0 && 
                                    line?.ECOM_Quantity__c!=null && line?.ECOM_Quantity__c>0 ? line?.ECOM_SubTotal__c / line?.ECOM_Quantity__c : null;
            invoiceLine.quantity = line?.ECOM_Quantity__c;
            invoiceLine.subtotal = line?.ECOM_SubTotal__c;
            invoiceLine.tax = line?.ECOM_Tax__c;
            invoiceLine.total = line?.ECOM_Total__c;
            invoiceLine.displayUrl = line?.ECOM_Product__r?.ECOM_Product_Media_URI__c ;
            invoiceLine.imgUrl = line.ECOM_Product__r?.ECOM_Product_Media_URI__c ;
            if(productToTarrifMap.get(invoiceLine.productId+String.valueOf(invoiceLine.quantity))!=null){
               invoiceLine.tariffSurcharge = productToTarrifMap.get(invoiceLine.productId+String.valueOf(Integer.valueOf(invoiceLine.quantity)));//RWPS-3026
            }
            invoiceLines.add(invoiceLine);
          }
          invoice.invoiceLines = invoiceLines;
          orderModel.invoice = invoice;
          responseMap.put('orderModel',orderModel);
        }
      }
      catch(Exception e){
        ECOM_ApplicationLogsUtil.logFailure(e , 'ECOM_InvoiceController :: getInvoiceAndOrderDetails' , 'ECOM_InvoiceController' , 'getInvoiceAndOrderDetails',' Stack:: '+ e.getStackTraceString() + ' Error:: '+e.getMessage());
      }
      return responseMap;
    }

    /**
    * @description  to prepare order model with invoice and invoice lines
    * @author garora@rafter.one | 05-10-2024 
    * @param String,String,String
    * @return Map<String,Object> 
    **/
    @AuraEnabled
    public static Map<String,Object> submitCase(Map<String,Object> caseMap){
      try {
        Map<String,Object> mappingJSON = (Map<String,Object>) JSON.deserializeUntyped(ECOM_CustomMetadataService.getStoreConfigurationByLabel('ECOMInvoiceCase'));
        Map<String,Object> layoutMapping = (Map<String,Object>)mappingJSON.get('layoutMapping');
        Case invoiceCase = new Case();
        invoiceCase.AccountId = null;
        invoiceCase.ContactId = null;
        invoiceCase.Origin = 'Web';
        invoiceCase.Priority = 'Medium';
        invoiceCase.ERP_Sales_Org__c = (String) caseMap.get('salesOrg');
        // Added this to accomodate the case object new field change without default value
        invoiceCase.Case_Path_Status__c = 'Open';
        if(((String)caseMap.get('subject')).equalsIgnoreCase('Need help')){
          invoiceCase.Subject = (String)caseMap.get('subject');
          invoiceCase.Case_Layout_Type__c = (String)layoutMapping.get(invoiceCase.Subject);
          Map<String,Object> descriptionLabels = (Map<String,Object>) mappingJSON.get('descriptionLabels');
          invoiceCase.Description = (String)descriptionLabels.get('type') + ': Invoice' + '\n' +
                                    (String)descriptionLabels.get('number') + ': ' + (String)caseMap.get('InvoiceNumber') + '\n' +
                                    (String)descriptionLabels.get('notes') + ': ' + (String)caseMap.get('notes');
        }
        else{
          invoiceCase.Subject = (String)caseMap.get('subject');
          invoiceCase.Case_Layout_Type__c = (String)layoutMapping.get(invoiceCase.Subject);
          invoiceCase.Ref_Txn_Type__c = 'Invoice';
          invoiceCase.Ref_Txn_Number__c = (String)caseMap.get('InvoiceNumber');
          invoiceCase.Description = (String)caseMap.get('notes');
        }
        invoiceCase = ECOM_InvoiceService.insertCase(invoiceCase);
        caseMap.put('CaseNumber',invoiceCase.CaseNumber);
        caseMap.put('Status','Success');
      } catch (Exception e) {
        caseMap.put('Status','Error');
        caseMap.put('ErrorMessage',e.getMessage()+' || '+e.getStackTraceString());
        ECOM_ApplicationLogsUtil.logFailure(e , 'ECOM_InvoiceController :: submitCase' , 'ECOM_InvoiceController' , 'submitCase',' Stack:: '+ e.getStackTraceString() + ' Error:: '+e.getMessage());

      }
      return caseMap;
    }

    /**
    * @description  to get invoice pdf url
    * @author garora@rafter.one | 05-27-2024 
    * @param ECOM_OrderModel.Invoice
    * @return Map<String,Object> 
    **/
    @AuraEnabled
    public static Map<String,Object> invoicePDFCall(ECOM_InvoicePDFWrapper.Request invoice){
      Map<String,Object> responseMap = new Map<String,Object>();
      try {
          responseMap = ECOM_InvoiceService.invoicePDFCall(invoice);
      } catch (Exception e) {
        responseMap.put('Status','Error');
        ECOM_ApplicationLogsUtil.logFailure(e , 'ECOM_InvoiceController :: invoicePDFCall' , 'ECOM_InvoiceController' , 'invoicePDFCall',' Stack:: '+ e.getStackTraceString() + ' Error:: '+e.getMessage());
      }
      return responseMap;
    }
    
}