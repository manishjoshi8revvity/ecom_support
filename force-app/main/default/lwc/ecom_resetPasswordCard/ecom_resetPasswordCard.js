import { LightningElement } from 'lwc';

//apex
import setNewPassword from '@salesforce/apex/ECOM_SetPasswordController.setNewPasswordAndRedirectUser';

//labels
import ECOM_LBL_SHOW_PASSWORD from '@salesforce/label/c.Ecom_Show_Password';
import ECOM_LBL_HIDE_PASSWORD from '@salesforce/label/c.Ecom_Hide_Password';
import ECOM_LBL_PASSWORD_BLANK from '@salesforce/label/c.Ecom_Password_Blank';
import ECOM_LBL_PASSWORDREQUIREMENTINSTRUCTIONS from '@salesforce/label/c.ECOM_PasswordRequirementInstructions';
import ECOM_LBL_CONFIRMPASSWORD from '@salesforce/label/c.Ecom_Confirm_Password';
import ECOM_LBL_PASSWORDMATCH from '@salesforce/label/c.Ecom_Password_Match';
import ECOM_LBL_PASSWORDBLANK from '@salesforce/label/c.Ecom_Password_Blank';
import ECOM_LBL_SUBMIT from '@salesforce/label/c.ECOM_Submit';
import ECOM_LBL_PASSWORD from '@salesforce/label/c.Ecom_Password';
import ECOM_LBL_FIELDISREQUIRED from '@salesforce/label/c.ECOM_FieldIsRequired';

//static resources
import sres_ECOM_CartIcons from '@salesforce/resourceUrl/ssrc_ECOM_Theme';

export default class Ecom_resetPasswordCard extends LightningElement {

    //image
    images = {
        question : sres_ECOM_CartIcons + '/img/tooltip-image.svg',
        closeIcon: sres_ECOM_CartIcons + '/img/close-icon.svg',
    }

    //labels
    labels = {
        ECOM_LBL_SHOW_PASSWORD,
        ECOM_LBL_HIDE_PASSWORD,
        ECOM_LBL_PASSWORD_BLANK,
        ECOM_LBL_PASSWORDREQUIREMENTINSTRUCTIONS,
        ECOM_LBL_CONFIRMPASSWORD,
        ECOM_LBL_PASSWORDMATCH,
        ECOM_LBL_PASSWORDBLANK,
        ECOM_LBL_SUBMIT,
        ECOM_LBL_PASSWORD,
        ECOM_LBL_FIELDISREQUIRED
    }

    //boolean
    isDisplayMaskedPassword = true;
    isDisplayConfirmMaskedPassword = true;

    isPasswordEmptyError = false;
    isConfirmPasswordEmptyError = false;
    isPasswordMatchError = false;
    isPasswordMasked = true;
    isConfirmPasswordMasked = true;
    isMaskedPassword = true;
    isMaskedConfirmPassword = true;

    isSubmitButtonEnabled = false;

    displayErrorMessage = false
    showSpinner = false;

    //text
    password='';
    confirmPassword='';
    passwordInputStyling = 'slds-input ecom-masked-password';
    svgPasswordClass = 'ecom-display';
    errorMessageText;
    strengthLabel='Weak';
    confirmPasswordIsRequiredErrorMessage= '';
    passwordIsRequiredErrorMessage = '';

    //validation array
    validationArray=[];

    //url params
    userEmail = '';
    encryptedToken = '';

    //object
    strengthText = {
        weak : 'Weak',
        medium : 'Medium',
        strong: 'Strong'
    }

    //GETTERS
    get passwordInputStyling() {
        let currentStyling = this.passwordInputStyling;
        if(this.isPasswordEmptyError){
            currentStyling = currentStyling + ' ' + 'ecom-border-color-red';
        } else {
            currentStyling = currentStyling;
        }
        //console.log('currentStyling:: ', currentStyling);//Remove after DEV
        return currentStyling;
    }

    get confirmPasswordInputStyling() {
        let confirmInputStyling = this.confirmPasswordInputStyling;

        if(this.isConfirmPasswordEmptyError) {
            confirmInputStyling  = confirmInputStyling + ' ' + 'ecom-border-color-red';
        }

        return confirmInputStyling;
    }

    get displayPasswordMasked() {
        let currentStyling = 'slds-input ';

        if(this.isPasswordMasked){
            currentStyling = currentStyling + ' ecom-unmasked-password';
        } else {
            currentStyling = currentStyling + ' ecom-masked-password';
        }
        return currentStyling;
    }

    get submitButtonStyling() {
        // RWPS-3826 start
        let buttonStyling = {class: 'ecom-submit-disabled-button', disabled: true};
        //console.log('submitButtonStyling.this.validationArray.length:: ', this.validationArray.length);//Remove after DEV
        if(this.showSpinner){
            buttonStyling = {class: 'ecom-submit-disabled-button', disabled: true};
        } else if(this.isSubmitButtonEnabled){
            buttonStyling = {class: 'ecom-submit-button', disabled: false};
        }
        // RWPS-3826 end

        //console.log('buttonStyling::', buttonStyling);//Remove after DEV
        return buttonStyling;
    }

    connectedCallback() {
        const queryParameters = window.location.search;
        const urlParams = new URLSearchParams(queryParameters);
        //console.log('urlParams:: ', urlParams);//Remove after DEV
        //console.log('token' , urlParams.get('token'));//Remove after DEV
        //console.log('sess' , urlParams.get('sess'));//Remove after DEV
        this.userEmail =  urlParams.get('token');
        this.encryptedToken = urlParams.get('sess');
    }


    /**
     *
     * @param {*} event
     */
    switchPasswordView(event){
        let currentID = event.currentTarget.dataset.id;

        currentID = currentID.replace('button', 'input');
        const value = this.refs[currentID].value;
        //console.log('isMaskedPassword:: ', this.isMaskedPassword, 'this.isMaskedConfirmPassword:: ', this.isMaskedConfirmPassword, this.refs[currentID].value);//Remove after DEV

        //console.log('currentID:: ', currentID);//Remove after DEV
        if(this.refs[currentID].classList.contains('ecom-masked-password')){

            this.updateCurrentStyling(currentID, 'ecom-masked-password', 'ecom-unmasked-password', 'ecom-display', 'ecom-hide', value);
        } else {
            this.updateCurrentStyling(currentID,'ecom-unmasked-password', 'ecom-masked-password', 'ecom-hide',  'ecom-display', value);
        }
        //console.log('password:' , this.password);//Remove after DEV
    }

    updateCurrentStyling(currentID, removeClass, addClass , svgRemove, svgAdd, value){
        //console.log('currentID', currentID, removeClass, addClass, svgAdd, svgRemove);//Remove after DEV
        this.refs[currentID].classList.remove(removeClass);
        this.refs[currentID].classList.add(addClass);

        if(currentID.includes('confirm')){
            //this.confirmPassword = value;
            this.isMaskedConfirmPassword = !this.isMaskedConfirmPassword;
        } else {
            //this.password = value;
            this.isMaskedPassword = !this.isMaskedPassword;
        }
    }

    submitNewPassword(event) {

        const password = this.refs['maskedpasswordinput'].value.trim();
        const confirmPassword = this.refs['maskedconfirmpasswordinput'].value.trim();
        //console.log('password:: ', password);//Remove after DEV
        this.refs['maskedpasswordinput'].value = password;
        this.refs['maskedconfirmpasswordinput'].value = confirmPassword;

        if(password != '' && password != undefined && password != null &&
        confirmPassword != '' && confirmPassword != undefined && confirmPassword != null && password == confirmPassword) {
            this.showSpinner = true;
            setNewPassword({
                userEmail: this.userEmail,
                userPassword: password,
                encryptedToken: this.encryptedToken
            }).then(result => {
                //console.log('result:: ', result);//Remove after DEV
                if(result && result.success){
                    //forward to create session
                    if(result.responseData && result.responseData.success){
                        let updatedUrl = result.responseData.storefrontURL;

                        // if(userLocale){
                        //     updatedUrl = updatedUrl + '&locale=' + userLocale;
                        // }
                        // if(retUrl){
                        //     updatedUrl = updatedUrl + '&retURL=' + result.retURL;
                        // }
                        window.location.replace(updatedUrl);
                    } else {
                        this.showSpinner = false;
                        //this.setErrorData(true, result.responseData.message);
                    }
                } else {
                    this.showSpinner = false;
                    this.displayErrorMessage = true;
                    this.errorMessageText = result.message;
                }

            }).catch(error =>{
                this.showSpinner = false;
                //console.log('error::', error);//Remove after DEV
            });
        } else {
            this.showSpinner = false;
            if(password == '') {
                this.isPasswordEmptyError = true;
                this.passwordIsRequiredErrorMessage = this.labels.ECOM_LBL_PASSWORD.replace('*', '') +  ' ' + this.labels.ECOM_LBL_FIELDISREQUIRED;
            } else {
                this.isPasswordEmptyError = false;
            }
            if(confirmPassword == '') {
                this.isConfirmPasswordEmptyError = true;
                this.confirmPasswordIsRequiredErrorMessage = this.labels.ECOM_LBL_CONFIRMPASSWORD.replace('*','') +  ' ' + this.labels.ECOM_LBL_FIELDISREQUIRED;
            } else {
                this.isConfirmPasswordEmptyError = false;
            }
            if(confirmPassword != password){
                this.isPasswordMatchError = true;
            } else {
                this.isPasswordEmptyError = false;
            }

            return;
        }
    }

    handleInputValidation(event){
        const currentID = event.currentTarget.dataset.id;

        //console.log('currentID:: ', currentID, ' value::');//Remove after DEV
        //console.log('currentIDref:: ', this.refs[currentID], ' value::');//Remove after DEV
        const value = this.refs[currentID].value.trim();
        this.refs[currentID].value = value;
        //console.log('currentID:: ', currentID, ' value::', value);//Remove after DEV
        if(value == '' || value == undefined || value == null ){
            this.refs[currentID].classList.add('ecom-border-color-red');

            if(currentID.includes('confirm')){
                this.isConfirmPasswordEmptyError = true
                this.confirmPasswordIsRequiredErrorMessage = this.labels.ECOM_LBL_CONFIRMPASSWORD.replace('*','') +  ' ' + this.labels.ECOM_LBL_FIELDISREQUIRED;
            } else {
                this.isPasswordEmptyError = true;
                this.passwordIsRequiredErrorMessage = this.labels.ECOM_LBL_PASSWORD.replace('*', '') +  ' ' + this.labels.ECOM_LBL_FIELDISREQUIRED;
            }
        } else {

            if(currentID.includes('confirm')){
                const originalID = currentID.replace('confirm', '');
                const originalValue = this.refs[originalID].value;
                //check for password match
                if(value != originalValue){
                    this.isPasswordMatchError = true;
                } else {
                    this.isPasswordMatchError = false;
                }
                this.isConfirmPasswordEmptyError = false
            } else {
                this.isPasswordEmptyError = false;
            }

            if(!this.isPasswordEmptyError && !this.isConfirmPasswordEmptyError && !this.isPasswordMatchError) {
                this.refs[currentID].classList.remove('ecom-border-color-red');
            }
        }
    }


    /**
     * Handle validating password strength
     * @param {*} event
     */
    validatePasswordStrength(event){
        const currentID = event.currentTarget.dataset.id;
        const validationString = this.refs[currentID].value;
        //console.log('validationString:: ', validationString);//Remove after DEV

        //console.log('test::', /\d/.test(validationString));//Remove after DEV

        if(/\d/.test(validationString) && !this.validationArray.includes('digitMatched')){
            //console.log('test1:: ', true);//Remove after DEV
            this.validationArray.push('digitMatched');
        } else {
            if(!/\d/.test(validationString) && this.validationArray.includes('digitMatched')){
                this.validationArray = this.validationArray.filter(element => element !== 'digitMatched');
            }
        }

        if(/[A-Z]/.test(validationString)  && !this.validationArray.includes('capsCharacterMatched')){
            this.validationArray.push('capsCharacterMatched')
        } else {
            if(!/[A-Z]/.test(validationString) && this.validationArray.includes('capsCharacterMatched')){
                this.validationArray = this.validationArray.filter(element => element !== 'capsCharacterMatched');
            }
        }

        if(/[a-z]/.test(validationString) && !this.validationArray.includes('smallCharacterMatched')){
            this.validationArray.push('smallCharacterMatched');
        } else {
            if(!/[a-z]/.test(validationString) && this.validationArray.includes('smallCharacterMatched')){
                this.validationArray = this.validationArray.filter(element => element !== 'smallCharacterMatched');
            }
        }

        const specials = /[!@#$%^&*()\-+={}[\]:;"'<>,.?\/|\\]/;
        if(specials.test(validationString) && !this.validationArray.includes('specialCharacterMatched')){
            this.validationArray.push('specialCharacterMatched');
        } else {
            if(!specials.test(validationString) && this.validationArray.includes('specialCharacterMatched')){
                this.validationArray = this.validationArray.filter(element => element !== 'specialCharacterMatched');
            }
        }

        //console.log('this.validationArray.length::', validationString.length , validationString.length >= 12 && !this.validationArray.includes('lengthMatched'));//Remove after DEV
        if(validationString.length >= 12 && (!this.validationArray.includes('matchRequiredLength') &&  !this.validationArray.includes('matchRequiredLength1')) ){
            this.validationArray.push('matchRequiredLength');
            this.validationArray.push('matchRequiredLength1');
        }  else {
            if(validationString.length < 12 && (this.validationArray.includes('matchRequiredLength') || this.validationArray.includes('matchRequiredLength1'))){
                this.validationArray = this.validationArray.filter(element => {
                    if(element != 'matchRequiredLength' && element != 'matchRequiredLength1' ){
                        return element;
                    }
                });
            }
        }

        this.isSubmitButtonEnabled = this.validationArray && this.validationArray.length == 6 ? true : false;
        this.passwordStrengthStyling();
    }

    passwordStrengthStyling() {
        const arrayLength = this.validationArray.length;

        //console.log('arrayLength::' , this.validationArray);//Remove after DEV
        //console.log('arrayLength::', this.validationArray.length);//Remove after DEV
        if(arrayLength > -1){

            for(let i = 1; i <= 6 ; i++ ){
                let currMeter = 'meter'+i;

                if(this.refs[currMeter]){
                    this.refs[currMeter].classList.remove('ecom-password-meter-color');
                }

            }

            for(let i=1 ; (i <= arrayLength && i <= 6) ; i ++) {
                let currMeter = 'meter'+i;
                if(this.refs[currMeter]){
                    this.refs[currMeter].classList.add('ecom-password-meter-color');
                }
            }

            this.strengthLabel = arrayLength < 3 ? this.strengthText.weak : arrayLength > 2 && arrayLength < 5 ? this.strengthText.medium : arrayLength > 4 ? this.strengthText.strong : '';
        }

        return arrayLength;
    }

    /* This method closes the error message block and resets the error message
     * @param {*} event
     */
    closePrompt(event){
        this.errorMessageText = '';
        this.displayErrorMessage = false;
    }

}