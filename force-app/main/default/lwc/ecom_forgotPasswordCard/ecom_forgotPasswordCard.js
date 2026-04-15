import { LightningElement, wire} from 'lwc';
import { NavigationMixin} from 'lightning/navigation';
//apex
import resetUserPassword from '@salesforce/apex/ECOM_ForgotPasswordController.resetUserPassword';

//util
import {validateEmail} from 'c/ecom_util';

//labels
import ECOM_LBL_FORGOTYOURPASSWORD from '@salesforce/label/c.ECOM_ForgotYourPassword';
import ECOM_LBL_FORGOTPASSWORDINSTRUCTION from '@salesforce/label/c.ECOM_ForgotPasswordInstruction';
import ECOM_LBL_EMAILADDRESS from '@salesforce/label/c.ECOM_EmailAddress';
import ECOM_LBL_FIELDISREQUIRED from '@salesforce/label/c.ECOM_FieldIsRequired';
import ECOM_LBL_EMAILADDRESSISNOTVALID  from '@salesforce/label/c.ECOM_EmailAddressIsNotValid';
import ECOM_LBL_SUBMIT from '@salesforce/label/c.ECOM_Submit';
import ECOM_LBL_BACKTOLOGIN from '@salesforce/label/c.ECOM_BackToLogin';

//static resources
import sres_ECOM_CartIcons from '@salesforce/resourceUrl/ssrc_ECOM_Theme';

export default class Ecom_forgotPasswordCard extends NavigationMixin(LightningElement) {

    //boolean
    isDisplayFieldRequiredValidationError = false;
    isDisplayEmailValidationError = false;
    isDisplayError = false;

    showSpinner = false;

    //string
    fieldRequiredErrorLabel = '';

    //boolean
    displayErrorMessage = false;
    errorMessageText='';

    loginPage = {//RWPS-5367
        loginURL: '/login?ptcms=true'
    }
    
    images ={
        closeIcon: sres_ECOM_CartIcons + '/img/close-icon.svg',
    }
    
    //labels
    labels ={
        ECOM_LBL_FORGOTYOURPASSWORD,
        ECOM_LBL_FORGOTPASSWORDINSTRUCTION,
        ECOM_LBL_EMAILADDRESS,
        ECOM_LBL_FIELDISREQUIRED,
        ECOM_LBL_EMAILADDRESSISNOTVALID,
        ECOM_LBL_SUBMIT,
        ECOM_LBL_BACKTOLOGIN
    }

    get errorMessage(){
        let errorLabel = this.fieldRequiredErrorLabel;
        
        if(this.isDisplayEmailValidationError){
            errorLabel = this.labels.ECOM_LBL_EMAILADDRESSISNOTVALID;
        }

        return errorLabel
    }

    get submitButtonStyling(){
        let submitButtonStyle = 'ecom-submit-button';
        if(this.showSpinner){
            submitButtonStyle = 'ecom-submit-disabled-button'
        } 

        return submitButtonStyle;
    }

    get textOnlyButtonStyling() {
        let textOnlyStyling = 'ecom-text-only-purple-button';
        if(this.showSpinner){
            textOnlyStyling = 'ecom-text-only-purple-button-disabled';
        }

        return textOnlyStyling;
    }

    validateInput(event, name){
        let fieldName = '';

        let returnValue = true;
        let email = this.refs['emailaddress'].value.trim();
        this.refs['emailaddress'].value = email;

        if(event && (event != undefined && event != null)){
            fieldName = event.currentTarget.dataset.id;
        } else {
            fieldName = name;
        }
        console.log('fieldName::', name);//Remove after DEV
        const value = this.refs[fieldName].value;

        if(value == undefined || value == '' || value == null) {
            this.addRemoveErrorStyling(fieldName, true);
            this.isDisplayValidationError = true
            this.displayEmailValidationError(false, true, true);
            returnValue = false;
            return returnValue;

        } else {
            this.displayEmailValidationError(false, false, false);

            if(validateEmail(value)) {
                this.addRemoveErrorStyling(fieldName, false);
                this.isDisplayValidationError = false;

            } else {
                this.displayEmailValidationError(true, true, false);
                returnValue = false;

                return returnValue;
            }
        }

        return returnValue;
    }

    submitUserPasswordResetRequest(){
        this.displayErrorMessage = false;
        this.errorMessageText = '';
        this.showSpinner = true;
        console.log('submitUserPasswordResetRequest: called');//Remove after DEV

        let email = this.refs['emailaddress'].value.trim();
        this.refs['emailaddress'].value = email;


        if(this.validateInput(null,'emailaddress')){

            let value = this.refs['emailaddress'].value;
            console.log('emailaddress:: ', value);//Remove after DEV
            resetUserPassword({
                emailString: value
            }).then(result => {
                console.log('result::', result);//Remove after DEV
                if(result.success){
                    let origin = window.location.origin;
                    //RWPS-1925
                    document.cookie = `customer_email=${result.customerEmail}; path=/; max-age=${7 * 24 * 60 * 60}`;
                    window.location.href = origin + '/forgotPasswordRequested?ptcms=true';
                } else {
                    //RWPS-5938
                    if (result && result.isPunchoutUser == true) {
                        this[NavigationMixin.Navigate]({
                            type: 'standard__webPage',
                            attributes: {
                                url: `/login?ptcms=true&secureAccessLinkEmailAddress=` + result.userRecord.Email
                            }
                        });
                    }
                    //RWPS-5938
                    this.showSpinner = false;
                    this.errorMessageText = result.responseData;
                    this.displayErrorMessage = true;
                    console.log('displayMessage:: ', result.responseData);//Remove after DEV
                }
            }).catch(error => {
                this.showSpinner = false;
                console.log('submitUserPasswordResetRequest:error::', error);//Remove after DEV
            });
        } else {
            this.showSpinner = false;
            return false;
        }

    }

    addRemoveErrorStyling(fieldName, isAdd){
        if(isAdd){  
            this.refs[fieldName].classList.add('ecom-border-styling-red');
        } else {
            this.refs[fieldName].classList.remove('ecom-border-styling-red');
        }
    }

    displayEmailValidationError(isValidationError, isDisplayError, isFieldRequiredError){
        this.isDisplayEmailValidationError = isValidationError;
        this.isDisplayFieldRequiredValidationError = isFieldRequiredError;
        this.isDisplayError = isDisplayError;
    }

    connectedCallback(){
        this.fieldRequiredErrorLabel = this.labels.ECOM_LBL_EMAILADDRESS + ' ' + this.labels.ECOM_LBL_FIELDISREQUIRED;
    }

    backToLogin(){
        let origin = window.location.origin;
        window.location.href = origin + '/login?ptcms=true';
    }

    closePrompt(event){
        this.displayErrorMessage = false;
        this.errorMessage = '';
    }
}