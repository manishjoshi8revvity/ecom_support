import { LightningElement,api,wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import ID_FIELD from '@salesforce/schema/Contact.Id';
import Id from '@salesforce/user/Id';

import FIRSTNAME_FIELD from '@salesforce/schema/Contact.FirstName';
import LASTNAME_FIELD from '@salesforce/schema/Contact.LastName';
import httpPrefix  from '@salesforce/label/c.ECOM_HTTPS_Prefix';
import siteBaseUrl  from '@salesforce/label/c.ECOM_SFBaseUrl';
import createLoginActivity from '@salesforce/apex/ECOM_ContactController.createLoginActivity';
export default class Ecom_csr extends LightningElement {

    @api recordId;
    @api objectApiName;
    userId = Id;
    contactName
    @wire(getRecord, {
        recordId: '$recordId',
        fields: [FIRSTNAME_FIELD, LASTNAME_FIELD]
    }) contact({ error, data }) {
        if(data){
            console.log('recordId '+this.recordId);
            //window.location.href = httpPrefix+siteBaseUrl+'?contactId='+this.recordId+'&csrId='+
            console.log('window.location.origin'+window.location.origin);
            let loginMap = {
                'firstName' : data.fields.FirstName.value,
                'lastName' : data.fields.LastName.value,
                'loggedInContactId' : this.recordId          
            };
            createLoginActivity({
                requestMap : loginMap
            })
            .then((result)=>{
                if(result.Status == 'Success'){
                    let url = httpPrefix+siteBaseUrl+'/vforcesite/ECOM_csr?contactId='+this.recordId+'&csrId='+this.userId+'&baseUrl='+window.location.origin;
                    console.log('url',url);
                    this.closeAction(); //to close the quick action popup
                    window.open(url,'_blank'); //opening in new page
                }
            })
            .catch((error)=>{
                console.error(error);
            })
        }else if(error){
            
        }
    }

    closeAction(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

}