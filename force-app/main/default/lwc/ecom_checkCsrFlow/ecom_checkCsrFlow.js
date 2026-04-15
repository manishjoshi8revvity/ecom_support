import { LightningElement, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import Id from '@salesforce/user/Id';
import {getCookieByName,deleteCookieByName} from 'c/ecom_util';
import getRedirectUrl from '@salesforce/apex/Ecom_CsrController.getCSRUrl';
import UserFields from '@salesforce/schema/User.ECOM_Is_Punchout_User__c';

export default class Ecom_checkCsrFlow extends LightningElement {
    csrId='';
    isCSR ='';
    isPunchoutUser = false;
    connectedCallback(){
       
    }

    @wire(getRecord, { recordId: Id, fields: [UserFields] })
    userDetails({ error, data }) {
        if (data) {
            if (data.fields.ECOM_Is_Punchout_User__c.value != null) {
                this.isPunchoutUser = data?.fields?.ECOM_Is_Punchout_User__c?.value || false;
                console.log(' this.isPunchoutUser ==> ', this.isPunchoutUser);
                this.isCSR = getCookieByName('apex__IsCSR');
                this.csrId = getCookieByName('apex__csrId');
                this.getCMSRedirectUrl(this.csrId);
            }
        }
    }

    getCMSRedirectUrl(csrCustomerId){
        getRedirectUrl({csrId : csrCustomerId}).then(result => {
            if(result){
                let poType = 'cmsStoreUser';
                if(this.isPunchoutUser){ //RWPS-2168
                    poType = 'punchoutUser';
                }
                if(this.isCSR && this.csrId){
                    const baseURL = window.location.origin;    
                    const dashBoard = baseURL + '/createsession?potype=' + poType + '&'+result; //RWPS-2168
                    console.log(result);
                    window.location.replace(dashBoard);
                }
            }
        }).catch(error => {
            console.log('result ::', error);//Remove after DEV
        })
    }

}