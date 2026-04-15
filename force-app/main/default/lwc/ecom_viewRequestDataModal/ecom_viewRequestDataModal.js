import { LightningElement, api } from 'lwc';

import LightningModal from 'lightning/modal';
export default class Ecom_viewRequestDataModal extends LightningModal {

    @api content;
    @api modalHeading;
    @api cxml;

    get updatedContent(){
        return this.content;
    }

    get updatedHeading(){
        return this.modalHeading;
    }

    connectedCallback(){
        console.log('connectedCallback:: ', this.content);//Remove after DEV
        if(this.cxml!=true){
            this.content = JSON.stringify(JSON.parse(this.content), undefined, 2);
        }
        console.log('this.content', this.content);//Remove after DEV
    }
}