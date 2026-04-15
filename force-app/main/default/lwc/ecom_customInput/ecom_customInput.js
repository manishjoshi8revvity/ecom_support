import { LightningElement, api } from 'lwc';
import ECOM_InputErrorMessage from '@salesforce/label/c.ECOM_InputErrorMessage';

export default class Ecom_customInput extends LightningElement {
    @api label;
    @api name;
    @api maxLength;
    @api required; 

    @api formFields = {};
    @api fieldErrors = {};
    @api addressType='';
    @api uniqueIdentifier='';
    @api errorMsg; //RWSP-3813
    labels = {
        ECOM_InputErrorMessage
    }
    
    get errorMsgFinal() {
        return this.errorMsg?this.errorMsg : this.labels.ECOM_InputErrorMessage; //RWPS-3813
    }
    get computedValue() {
        return this.formFields[this.name] || '';
    }

    get computedError() {
        return this.fieldErrors[this.name] || false;
    }

    get computedClass() {
        const hasError = this.computedError;
        return this.computedError ? 'custom-input input-error' : 'custom-input';
    }

    handleInputChange(event) {
        this.fireValueChange(event);
    }
    
    handleInputBlur(event) {
        this.fireValueChange(event);
    
        this.dispatchEvent(new CustomEvent('blur', {
            bubbles: true,
            composed: true
        }));
    }
    
    fireValueChange(event) {
        const updatedValue = event.target.value;
        const isValid = updatedValue.trim().length > 0;
    
        this.dispatchEvent(
            new CustomEvent('valuechange', {
                detail: {
                    name: this.name,
                    value: updatedValue,
                    isValid: isValid
                }
            })
        );
    }

   
    @api toggleVisibility(show) {
        this.template.querySelector('input').style.display = show ? 'block' : 'none';
    }

   }