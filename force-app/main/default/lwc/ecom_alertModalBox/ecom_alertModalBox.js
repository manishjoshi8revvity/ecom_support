import { LightningElement } from 'lwc';
import Ecom_Cancel_close  from '@salesforce/label/c.Ecom_Cancel_close';
import ECOM_Training_Improper_Setup  from '@salesforce/label/c.ECOM_Training_Improper_Setup';
import ECOM_Training_Confirmation  from '@salesforce/label/c.ECOM_Training_Confirmation';
import ECOM_Cancel  from '@salesforce/label/c.ECOM_Cancel';
import ECOM_Proceed  from '@salesforce/label/c.ECOM_Proceed';

export default class Ecom_alertModalBox extends LightningElement {

    
    labels = {
        Ecom_Cancel_close,
        ECOM_Training_Improper_Setup,
        ECOM_Training_Confirmation,
        ECOM_Cancel,
        ECOM_Proceed
    }


    handleProceed(){
        const message = 'Removed';
        const event = new CustomEvent('removetrainingproduct', {
            detail: message
        });
        this.dispatchEvent(event); // Send event to parent
    }

    handleCancel(){
        const isCancel = true;
        const event = new CustomEvent('cancelremoveitem', {
            detail: isCancel
        });
        this.dispatchEvent(event); // Send event to parent

    }

    handleModalClose(){
        const isCancel = true;
        const event = new CustomEvent('cancelremoveitem', {
            detail: isCancel
        });
        this.dispatchEvent(event); // Send event to parent
    }


}