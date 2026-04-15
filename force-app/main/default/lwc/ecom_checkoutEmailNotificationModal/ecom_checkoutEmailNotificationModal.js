import { LightningElement, api, track, wire } from 'lwc';
import sres_ECOM_CartIcons from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { sendPostMessage } from 'c/ecom_util';
//importing custom labels
import ECOM_ReflectMessage from '@salesforce/label/c.ECOM_ReflectMessage';
import ECOM_EmailAddress from '@salesforce/label/c.ECOM_EmailAddress';
import ECOM_AdditionalEmailMessage from '@salesforce/label/c.ECOM_AdditionalEmailMessage';
import ECOM_Save from '@salesforce/label/c.ECOM_Save';
import ECOM_Cancel  from '@salesforce/label/c.ECOM_Cancel';
import ECOM_InvalidEmailPreferencesError  from '@salesforce/label/c.ECOM_InvalidEmailPreferencesError';
import ECOM_EmailNotifications  from '@salesforce/label/c.ECOM_EmailNotifications';
import ECOM_OrderConfirmation  from '@salesforce/label/c.ECOM_OrderConfirmation';
import ECOM_ShipmentNotification  from '@salesforce/label/c.ECOM_ShipmentNotification';
import ECOM_EmailInvalidErrorMessage  from '@salesforce/label/c.ECOM_EmailInvalidErrorMessage';//RWPS-2722
//const emailUserIndex=0;
export default class Ecom_checkoutEmailNotificationModal extends LightningElement {
    
    labels = {
        ECOM_Cancel,
        ECOM_Save,
        ECOM_EmailAddress,
        ECOM_AdditionalEmailMessage,
        ECOM_ReflectMessage,
        ECOM_InvalidEmailPreferencesError,
        ECOM_EmailNotifications,
        ECOM_OrderConfirmation,
        ECOM_ShipmentNotification,
        ECOM_EmailInvalidErrorMessage //RWPS-2722
    };
    @track showModal = false;
    @api emailPrefUpdate;
    @api isUpdate;
    @api existingEmails;
    isEmailOrPrefNotMarked = false;
    isEmailBlankOrInvalid = false;
    isValidationError = false;
    emailRecord;
    @track emailRowIndex = 0;
    @track isSaveBtnDisabled = false;
    @track emailAddressRows = [];
    @track objectNameToGetFields = 'ECOM_Email_Preferences__c';
    @api     
    images = {
        addmore:sres_ECOM_CartIcons + '/img/addmore.png'
    }

    @api isMobileView = false;
    #escapeKeyCallback; // RWPS-4087
    focusNewEmail = false; //RWPS-5284

    get isFullPageModal(){
        let classString = 'slds-modal slds-fade-in-open slds-modal_small';
        if(this.isMobileView){
            classString = 'slds-modal slds-fade-in-open slds-modal_full'
        }
        return classString;
    }

    get pagePadding(){
        let paddingClass = 'ecom-content-padding';
        if(this.isMobileView){
            paddingClass = 'ecom-padding-mobile';
        }
        return paddingClass;
    }

    get footerPadding(){
        let paddingClass = 'slds-modal__footer ecom-bottom-border-radius-16';
        if(this.isMobileView){
            paddingClass = 'slds-modal__footer ecom-bottom-border-radius-16 ecom-padding-0';
        }
        return paddingClass;
    }

    // RWPS-4087 start
    connectedCallback() {        
        this.#escapeKeyCallback = this.escapeKeyCallback.bind(this);
        document.addEventListener('keydown', this.#escapeKeyCallback);
    }
    disconnectedCallback() {
        document.removeEventListener('keydown', this.#escapeKeyCallback);
    }

    escapeKeyCallback(event) {
        if (event.key === 'Escape' || event.keyCode === 27) {
    
            if (this.showModal) {
                this.closeModal();
            }
        }
    }
    // RWPS-4087 end
    //RWPS-5284 start
    renderedCallback() { 
        if (this.focusNewEmail) {
            this.focusNewEmail = false;
            const inputs = this.template.querySelectorAll('lightning-input.email-input');
            if (inputs.length) {
                const lastLightningInput = inputs[inputs.length - 1];
                const nativeInput = lastLightningInput.focus();
                if (nativeInput) {
                    nativeInput.focus();
                }
            }
        }
    }  //RWPS-5284 end 
    @api
    openModal()
    {
        this.showModal = true;
        this.isValidationError = false;
        this.emailRowIndex = 0;
        this.emailAddressRows = [];
        let newEmailRecord = JSON.parse(this.emailRecord);
        newEmailRecord['index'] = this.emailRowIndex;
        this.emailAddressRows.push(newEmailRecord);
        sendPostMessage('hidden');
    }

    closeModal()
    {
        this.showModal = false;
        sendPostMessage('auto');
        this.dispatchEvent(
            new CustomEvent('emailmodalclosed', {
                detail: {
                    ismodalClosed: true
                }
            })
        );
    }
    
    @wire(getObjectInfo, { objectApiName: '$objectNameToGetFields' })
    getObjectInfo({ error, data }) {
        if (data) {
            //const emailUserIndex=0;
            let emailIndex = this.emailRowIndex;
            //this.globalEmailRecord.indexId = i;
            let newEmailRecord = {index: emailIndex, isEmailInvalid: false, errorMessage:'' };//RWPS-2722
            this.isEmailInvalid = false;//RWPS-2722
            for (let key in data.fields) {

                if (data.fields.hasOwnProperty(key) && data.fields[key].custom ) {
                    if(data.fields[key].dataType == 'Boolean'){
                        //this.emailRecord[key] = false;
                        newEmailRecord[key] = false;
                    }
                    else{
                        //this.emailRecord[key]=''
                        newEmailRecord[key]='';
                    }
                    //add data label dynamically
                }
            }
            
            this.emailRecord = JSON.stringify(newEmailRecord);
            this.emailAddressRows.push(newEmailRecord);
        }
        else if (error) {
            console.log('Error while get fields');
        }
    }


    addNewRow()
    {

        this.emailRowIndex++;
        let emailIndex = this.emailRowIndex;
        let newEmailRecord = JSON.parse(this.emailRecord);
        newEmailRecord.index = emailIndex;
        newEmailRecord.isEmailInvalid = false; //RWPS-2722
        newEmailRecord.errorMessage = '';//RWPS-2722
        this.emailAddressRows = [...this.emailAddressRows, newEmailRecord];//RWPS-5284
        this.focusNewEmail = true;//RWPS-5284
    }
    
    handleEmailChanged(event){
        //RWPS-2722 start
        const index = event.target.dataset.index;
        const label = event.target.dataset.label;
        const value = event.target.value.trim();
    
        this.emailAddressRows[index][label] = value;
        this.emailAddressRows[index].isEmailInvalid = false;
        this.emailAddressRows[index].errorMessage = '';
        //RWPS-2722 end 
        this.isValidationError = false;
        event.target.setCustomValidity('');
        event.target.reportValidity();
        this.validateEmail(event);//RWPS-2722
    }

    //RWPS-2722 start
    validateEmail(event) {
        const index = parseInt(event.target.dataset.index, 10);
        const value = event.target.value.trim();
        const emailPattern = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
    
        let errorMessage = '';
        if (!emailPattern.test(value)) {
            errorMessage = this.labels.ECOM_EmailInvalidErrorMessage;
        } 
    
        if (errorMessage) {
            this.emailAddressRows[index].isEmailInvalid = true;
            this.emailAddressRows[index].errorMessage = errorMessage;   
            event.target.setCustomValidity(errorMessage);
        } else {
            this.emailAddressRows[index].isEmailInvalid = false;
            this.emailAddressRows[index].errorMessage = '';
            event.target.setCustomValidity('');
        }
        event.target.reportValidity();
    }
   //RWPS-2722 end 

    handleCheckboxChanged(event){
        this.emailAddressRows[event.target.dataset.index][event.target.dataset.label] = event.target.checked;
    }

    validateUserInputs(val)
    {
        let isValid  = false;
        for (let email in val)
        {
            let trimmedEmail = email.trim();
            if(trimmedEmail != null && trimmedEmail != '')
            {
                isValid= /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/.test(trimmedEmail);
                if(!isValid)
                    return isValid;
            }

        }
        return isValid;
    }
    handleSaveRows(){
        //check all duplicates first added by manoj
        //RWPS-2722 start
        let hasInvalidEmail = this.emailAddressRows.some(row => row.isEmailInvalid);
        this.isValidationError = hasInvalidEmail;

        if (hasInvalidEmail) {
            return;
        } 
        //RWPS-2722 end
        let emailLookup = this.emailAddressRows.reduce((a, e) => {
            a[e.ECOM_Email__c.toLowerCase()] = ++a[e.ECOM_Email__c.toLowerCase()] || 0;
            return a;
          }, {});

        let emailValid = this.validateUserInputs(emailLookup);
        if(!emailValid)
        {
            this.isValidationError = true;
            return;
        }
        else
        {
            this.isValidationError = false;
        }


        let currentDuplicates = this.emailAddressRows.filter(e => emailLookup[e.ECOM_Email__c.toLowerCase()]);
       
        let duplicateEmails = [];
        for(let key in currentDuplicates){
            if(currentDuplicates[key].ECOM_Email__c.toLowerCase() != null && currentDuplicates[key].ECOM_Email__c.toLowerCase() != '')
                duplicateEmails.push(currentDuplicates[key].ECOM_Email__c.toLowerCase());
        }
       
        for(let i=0;i<this.existingEmails?.length;i++){
            for (let index = 0; index < this.emailAddressRows.length; index++) {
                if(this.emailAddressRows[index]?.ECOM_Email__c?.toLowerCase()===this.existingEmails[i]?.ECOM_Email__c?.toLowerCase() ) {
                    duplicateEmails.push(this.emailAddressRows[index]?.ECOM_Email__c.toLowerCase());
                }
            }
        }


        
        //if(duplicateEmails.length > 0){
            const inputsValid = [
                ...this.template.querySelectorAll('.email-input'),
            ].reduce((validSoFar, inputCmp) => {
                 // Check if the input is a valid email format
                if(duplicateEmails.includes(inputCmp.value.toLowerCase())){
                    inputCmp.setCustomValidity('You already have this email.');
                }
                else
                {
                    inputCmp.setCustomValidity('');
                }
                inputCmp.reportValidity();
                return;
            }, true);
            
        //}
        // duplicate logic ended 
        //check for email required and valid
        this.isValidationError = false;
        this.isEmailOrPrefNotMarked = false;
        this.isEmailBlankOrInvalid = false;
        const allValid = [
            ...this.template.querySelectorAll('lightning-input'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
      
        if (allValid) {
            //alert('All form entries look valid. Ready to submit!');
            for(let key in this.emailAddressRows){
                if((this.emailAddressRows[key].ECOM_Email__c && !this.emailAddressRows[key].ECOM_Order_Confirmation__c
                    && !this.emailAddressRows[key].ECOM_Shipment_Notification__c) ||
                    (!this.emailAddressRows[key].ECOM_Email__c && (this.emailAddressRows[key].ECOM_Order_Confirmation__c
                        || this.emailAddressRows[key].ECOM_Shipment_Notification__c))){
                        this.isEmailOrPrefNotMarked = true;
                        break;
                }
            }
        }else {
            //alert('Please update the invalid form entries and try again.');
            this.isEmailBlankOrInvalid = true;
        }

        if(this.isEmailOrPrefNotMarked){//if(this.isEmailOrPrefNotMarked){
            this.isValidationError = true;
        }else{
            //this.isSaveBtnDisabled = false;
            for(let key in this.emailAddressRows){
                if(!this.emailAddressRows[key].ECOM_Email__c && 
                    !this.emailAddressRows[key].ECOM_Order_Confirmation__c &&
                    !this.emailAddressRows[key].ECOM_Shipment_Notification__c){
                        delete this.emailAddressRows[key];
                }
            }
        }
        
        if(!this.isValidationError && duplicateEmails?.length===0){
            this.isValidationError = false;
            this.closeModal();
            this.dispatchEvent(
                new CustomEvent('emailpreferencesadded', {
                    detail: {
                        emailAddressRows: this.emailAddressRows
                    }
                })
            );
        }

        //need to delete
        if(!this.isValidationError && this.isUpdate){
            this.isValidationError = false;
            this.closeModal();
            this.isUpdate = false;
            this.dispatchEvent(
                new CustomEvent('emailpreferencesupdated', {
                    detail: {
                        emailAddressRows: this.emailAddressRows[0]
                    }
                })
            );
        }
    }
}