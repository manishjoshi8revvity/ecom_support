// General Section
import { LightningElement,track,api } from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';

// Apex Callout Section
import saveEInvoiceDetails from '@salesforce/apex/ECOM_CheckoutController.saveEInvoiceDetails';

// Label Section
import ECOM_SaveAndContinue from '@salesforce/label/c.ECOM_SaveAndContinue';

export default class Ecom_checkout_einvoiceDetails extends LightningElement {
    // Labels Section
    labels = {
        ECOM_SaveAndContinue
    };
    // Variable Section
    @api effectiveAccountId;
    @api isInvoiceReadMode;
    @api isInvoiceEditMode;
    @api isInvoiceOrderMode = false;
    @api paymetDataMap;
    @api cartId;
    @api validateFields;
    showSpinner = false;
    cartDetails = {};
    message;
    type;
    show = false;
    timeSpan= 0;
    device = {
        isMobile : FORM_FACTOR==='Small',
        isDesktop : FORM_FACTOR==='Large',
        isTablet :FORM_FACTOR==='Medium'
    }
    // Variable Section End
    // Method to show message in the component on edit mode
    showMessage(message,type,show){
        this.message = message;
        this.type = type;
        this.show = show;
    }
    // Method to close the message 
    handleUpdateMessage(){
        this.message = '';
        this.type = '';
        this.show = false;
    }
    // Method to save the E-Invoice fields to cart
    handleInvoiceFieldsSave(){
        const allValid = [
            ...this.template.querySelectorAll('lightning-input')
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        if (allValid) {
            this.handleUpdateMessage(); // Nullify message if any
            this.showSpinner = true;
            this.validateFields = JSON.parse(JSON.stringify(this.validateFields));
            for(let i =0; i < this.validateFields.length; i++){ 
                if(this.cartDetails?.[this.validateFields[i].fieldAPIName] == null){
                    this.cartDetails[this.validateFields[i].fieldAPIName] = this.validateFields[i]?.value == null?'':this.validateFields[i]?.value;
                } else {
                    this.cartDetails[this.validateFields[i].fieldAPIName] = this.cartDetails[this.validateFields[i].fieldAPIName].trim();
                }
                this.validateFields[i].value = this.cartDetails[this.validateFields[i].fieldAPIName];
                this.validateFields[i].isReadOnly = this.validateFields[i].value != null && this.validateFields[i].value != '';
            }
            this.cartDetails.Id = this.cartId;
            // Call the 'saveEInvoiceDetails' apex method imperatively
            saveEInvoiceDetails({
                cartDetails: this.cartDetails
            }).then((results) => {
                    if(results.Status == 'Success'){
                        console.log('result::', results);
                        this.moveToNextSection();
                        
                    } else {
                        console.log('Error::', results);
                    }
                    this.showSpinner = false;
            })
            .catch((error) => {
                this.showSpinner = false;
                console.log('Error::', error);
            });
        }else{
            this.showMessage(
                'Please check your fields for any error',
                'error',
                true
            );
        }
    }
    // Method to handle any value change during the edit mode for the input fields
    handleValueChange(event){
        if(event?.target?.dataset?.validate != null){
            let fieldId = event?.target?.dataset?.id;
            this.cartDetails[fieldId] = event.target.value.trim();
        }
    }
    // Method to handle keypress to stop allowing spaces
    handleKeyPress(event) {
        if (event.keyCode == 32) {
            event.preventDefault();
        }
    }
    // Method to move to next section 
    moveToNextSection(){
        this.showSpinner = false;
        this.dispatchEvent(
            new CustomEvent('showpaymentsection', {
                detail: {
                    moveToNextSection: true
                }
            })
        );   
    }
    // Method to get main invoice container class
    get containerClass() { 
        return this.isInvoiceEditMode?'ecom-co-rev-card':'';
    }
    // Method to get main invoice container class
    get containerDataClass() { 
        return (this.isInvoiceOrderMode && !this.device.isMobile)?'ecom-mt-32':'';
    }
}