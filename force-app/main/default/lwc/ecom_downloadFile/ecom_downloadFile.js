import { LightningElement } from 'lwc';
import getInvoice from '@salesforce/apex/ECOM_InvoiceController.getInvoice';

export default class Ecom_downloadFile extends LightningElement {
    
    invoiceId;
    downloadUrl;

    connectedCallback(){
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString);
        this.invoiceId = urlParams.get('id');
        console.log('invoiceId: '+this.invoiceId);
        this.fetchDownloadUrl();
    }

    fetchDownloadUrl(){
        console.log('fetchDownladUrl');
        getInvoice({
            invoiceId : this.invoiceId
        })
        .then((result)=>{
            console.log('Reuslt: '+JSON.stringify(result));
            if(result.length>0){
                this.downloadUrl = result[0].ECOM_Download_URL__c;
                window.location.href = this.downloadUrl;
                setTimeout(function() {
                    window.close();
                }, 2000);
            }
        })
        .catch((error)=>{
            console.log('Error: '+JSON.stringify(error));
            console.log('Error: '+error);
        })
    }
}