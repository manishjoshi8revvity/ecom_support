import { LightningElement, api, track } from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';//9th Nov
import ECOM_Punchout_Checkout_Unavailable_Message from '@salesforce/label/c.ECOM_Punchout_Checkout_Unavailable_Message'; //RWPS-5938

export default class Ecom_inlineMessage extends LightningElement {
@track
colsize = "slds-col slds-size_11-of-12";
@track 
btnCloseSize = "slds-button slds-button_icon ecom-msgbox-closebtn";
device = {
    isMobile : FORM_FACTOR==='Small',
    isDesktop : FORM_FACTOR==='Large',
    isTablet :FORM_FACTOR==='Medium'
}
/*9th Nov End */   
_message;
    _type;
    _show;
    _timeSpan = 3000;
    @api
    get timespan(){
        return this._timeSpan;
    }
    set timespan(value){
        this._timeSpan =  this.type!=='error'? 3000: 0;
    }
    @api
    get message(){
        return this._message;
    }
    set message(value){
        this._message = value;
    }
    @api
    get show(){
        return this._show;
    }
    set show(value){
        this._show = value;
    }
    @api
    get type(){
        return this._type;
    }
    set type(value){
        this._type = value;
    }
    get containerClass(){
        let className= '';
        switch(this.type){
            case 'success':
                className = 'slds-is-relative ecom-notify_container_success';
                break;
            case 'error':
                className = 'slds-is-relative ecom-notify_container_error';
                break;
            case 'warning':
                className = 'slds-is-relative ecom-notify_container_warning';
                break;
            default : 
                className = 'slds-is-relative ecom-notify_container_info';
        }
        return className;
    }

    get hasMessageText() {
        return typeof this.message === 'string' && this.message.trim().length > 0;
    }

    hideMessage(){
        let comReference = this;
        if(this.type!=='error')
        {
            setTimeout(() => {
                comReference._show = false;
                this.message =''; //RWPS-2734
                comReference.dispatchEvent(
                    new CustomEvent('messageaction', {
                        detail: {
                        }
                    })
                );
            }, 3000);
        }
    }

    //Close Mossage box-8th Nov
    closeMessageBox(){
        this._show=false;
        this.dispatchEvent(
            new CustomEvent('messageaction', {
                bubbles: true,
                composed: true,
                detail: {
                    show: false
                }
            })
        );
     }

    //9th Nov start
    connectedCallback() {
        this.loadBasedOnDeviceType();
    }

    //RWPS-4502 Start
    renderedCallback() {
        if (this._show || this.hasMessageText) {
            //RWPS-5938 - Added condition to not auto-hide message if it's a punchout user with checkout unavailable message
            if (this.message && !this.message.includes(ECOM_Punchout_Checkout_Unavailable_Message)) {
                this.hideMessage();
            }
        }
    }
    //RWPS-4502 End

    loadBasedOnDeviceType() {
        if (this.device.isMobile) {
            this.colsize = "slds-col slds-size_10-of-12";
            this.btnCloseSize= "slds-button slds-button_icon ecom-msgbox-closebtn-mobile";
        } else {
            this.colsize = "slds-col slds-size_11-of-12";
            this.btnCloseSize= "slds-button slds-button_icon ecom-msgbox-closebtn";
        }
    }
     //9th Nov end
}