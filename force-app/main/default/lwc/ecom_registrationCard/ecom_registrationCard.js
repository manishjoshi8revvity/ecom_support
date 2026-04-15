import { LightningElement, api, track, wire} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

//Object
import CONTACT_OBJECT from '@salesforce/schema/Contact';

import LOCALE from '@salesforce/i18n/locale';
import CURRENCYCODE from '@salesforce/i18n/currency';
import TIMEZONE from '@salesforce/i18n/timeZone';
import COUNTRY_PHONE_CODE_FIELD from '@salesforce/schema/Contact.ECOM_Country_Phone_Code__c';

//message channel
import ECOM_MESSAGE from '@salesforce/messageChannel/ecom_MessagingChannel__c';
import { MessageContext, subscribe, publish } from 'lightning/messageService';

//static resources
import sres_ECOM_CartIcons from '@salesforce/resourceUrl/ssrc_ECOM_Theme';

//labels
import ECOM_LBL_CONTACTINFORMATION from '@salesforce/label/c.Ecom_Contact_Information';
import ECOM_LBL_FIRSTNAME from '@salesforce/label/c.Ecom_First_Name';
import ECOM_LBL_LASTNAME from '@salesforce/label/c.Ecom_Last_Name';
import ECOM_LBL_COMPANYNAME from '@salesforce/label/c.ECOM_CompanyNameFieldLabel';
import ECOM_LBL_BUSINESSEMAILADDRESS from '@salesforce/label/c.ECOM_BusinessEmailAddress';
import ECOM_LBL_COUNTRY from '@salesforce/label/c.ECOM_CountryText';
import ECOM_LBL_ACCOUNTNUMBEROPTIONAL from '@salesforce/label/c.ECOM_AccountNumberOptional';
import ECOM_LBL_THISMUSTBEYOURBUSINESSEMAIL from '@salesforce/label/c.ECOM_ThisMustBeYourBusinessEmailAddress';
import ECOM_LBL_ACCOUNTNUMBERISANUMERICVALUE from '@salesforce/label/c.ECOM_AccountNumberIsANumericValue';
import ECOM_LBL_REGISTRATIONTERMSANDCONDITIONS from '@salesforce/label/c.ECOM_RegistrationTermsAndCondition';
import ECOM_LBL_REVVITYBASEURL from '@salesforce/label/c.ECOM_RevvityBaseUrl';
import ECOM_LBL_PRIVACYNOTICEURL from '@salesforce/label/c.ECOM_PrivacyNoticeUrl';
import ECOM_LBL_AVAILABLEHERE from '@salesforce/label/c.ECOM_AvailableHere';
import ECOM_LBL_IAGREETOREVVITY from '@salesforce/label/c.ECOM_IAgreeToRevvitys';
import ECOM_LBL_TERMSANDCONDITIONS from '@salesforce/label/c.ECOM_TermsAndConditions';
import ECOM_LBL_IAGREETOTERMSANDCONDITIONSREQUIRED from '@salesforce/label/c.ECOM_IAgreeToTermsAndConditionsRequiredField';
import ECOM_LBL_REQUIREDFIELDS from '@salesforce/label/c.ECOM_RequiredFields';
import ECOM_LBL_ALREADYHAVEANACCOUNT from '@salesforce/label/c.ECOM_AlreadyHaveAnAccount';
import ECOM_LBL_LOGIN from '@salesforce/label/c.ECOM_Login';
import ECOM_LBL_REGISTER from '@salesforce/label/c.ECOM_Register';
import ECOM_LBL_TERMSANDCONDITIONSSITEPATH from '@salesforce/label/c.ECOM_TermsAndConditionsSitePath';
import ECOM_LBL_FIELDISREQUIRED from '@salesforce/label/c.ECOM_FieldIsRequired';
import ECOM_LBL_ACCOUNTEMAILTOOLTIPTEXT from '@salesforce/label/c.ECOM_AccountEmailToolTipText';
import ECOM_LBL_ACCOUNTNUMBERTOOLTIPTEXT from '@salesforce/label/c.ECOM_RegistrationAccountNumberToolTipText';
import ECOM_LBL_EMAILADDRESSISNOTVALID  from '@salesforce/label/c.ECOM_EmailAddressIsNotValid';
import ECOM_LBL_REGISTRATIONSUCCESSPATH from '@salesforce/label/c.ECOM_RegistrationSuccessPath';
import ECOM_LBL_PHONENUMBER from '@salesforce/label/c.Ecom_Phone_Number';
import ECOM_LBL_PHONENUMBERLENGTHERROR from '@salesforce/label/c.ECOM_PhoneNumberLengthError';
import ECOM_LBL_COUNTRYTOOLTIP from '@salesforce/label/c.ECOM_LBL_COUNTRYTOOLTIP'; //RWPS-3660

//Apex
import registerAccount from '@salesforce/apex/ECOM_RegistrationController.registerNewAccount';
import getUserDetails from '@salesforce/apex/ECOM_RegistrationController.getUserDetails'; //RWPS-5938

const MESSAGE_TYPE_COUNTRY_SWITCH = 'countrySwitch';
export default class Ecom_registrationCard extends NavigationMixin(LightningElement) {

    //Wire
    @wire(MessageContext)
    messageContext;

    //apis
    @api loginPagePath;
    @api registrationSuccessPath;

    //boolean values
    displayErrorMessage = false;
    usernameError = false;
    isHidePassword = false;
    isTermsAndConditionsError = false;
    isTermsAndConditionsChecked = false;
    showSpinner = false;

    //text values
    errorMessageText='';
    maxWidthClass = 'ecom-card';
    usernameErrorMessage = '';
    locale = '';
    contactRecTypeId='';
    currentLocaleValue = 'en-US';
    currentCountryCode = 'US';
    currentTimezone = 'America/New_York';
    currentPhoneCode = '+1';
    currentCurrencyCode = 'USD';

    //array values
    countryPhoneCode=[];

    //object declarations
    @track validationMap = {
        firstname : {
            isValidated : false,
            isEmailValidation: false,
            isError : false,
        },
        lastname : {
            isValidated : false,
            isEmailValidation: false,
            isError : false,
        },
        companyname : {
            isValidated : false,
            isEmailValidation: false,
            isError : false,
        },
        businessemailaddress : {
            isValidated : false,
            validateEmail : true,
            isEmailValidationFailed : false,
            isError : false,
        },
        country : {
            isValidated : false,
            isEmailValidation: false,
            isError : false,   
        },
        phonenumber: {
            isValidated : false,
            isEmailValidation : false,
            validatePhoneNumber : true,
            isError : false,
        },
    };

    //labels
    labels = {
        ECOM_LBL_CONTACTINFORMATION,
        ECOM_LBL_FIRSTNAME,
        ECOM_LBL_LASTNAME,
        ECOM_LBL_COMPANYNAME,
        ECOM_LBL_BUSINESSEMAILADDRESS,
        ECOM_LBL_COUNTRY,
        ECOM_LBL_ACCOUNTNUMBEROPTIONAL,
        ECOM_LBL_THISMUSTBEYOURBUSINESSEMAIL,
        ECOM_LBL_ACCOUNTNUMBERISANUMERICVALUE,
        ECOM_LBL_REGISTRATIONTERMSANDCONDITIONS,
        ECOM_LBL_REVVITYBASEURL,
        ECOM_LBL_PRIVACYNOTICEURL,
        ECOM_LBL_AVAILABLEHERE,
        ECOM_LBL_IAGREETOREVVITY,
        ECOM_LBL_TERMSANDCONDITIONS,
        ECOM_LBL_IAGREETOTERMSANDCONDITIONSREQUIRED,
        ECOM_LBL_REQUIREDFIELDS,
        ECOM_LBL_ALREADYHAVEANACCOUNT,
        ECOM_LBL_LOGIN,
        ECOM_LBL_REGISTER,
        ECOM_LBL_TERMSANDCONDITIONSSITEPATH,
        ECOM_LBL_FIELDISREQUIRED,
        ECOM_LBL_ACCOUNTEMAILTOOLTIPTEXT,
        ECOM_LBL_ACCOUNTNUMBERTOOLTIPTEXT,
        ECOM_LBL_EMAILADDRESSISNOTVALID,
        ECOM_LBL_REGISTRATIONSUCCESSPATH,
        ECOM_LBL_PHONENUMBER,
        ECOM_LBL_PHONENUMBERLENGTHERROR,
        ECOM_LBL_COUNTRYTOOLTIP //RWPS-3660
    }

    // //Wired methods
    // // Get Picklist Values for Country Phone Code
    // @wire(getPicklistValues, { recordTypeId: '$contactRecTypeId', fieldApiName: COUNTRY_PHONE_CODE_FIELD })
    // countryCodePicklistValues({ error, data }) {
    //     if (data) {
    //         this.countryPhoneCode = data.values;
    //         //console.log('countryPhoneCode:;' , this.countryPhoneCode);//Remove after DEV
    //     } else if (error) {
    //     }
    // }

    // // Get the Contact Record Type
    // @wire(getObjectInfo, { objectApiName: CONTACT_OBJECT })
    // contactObjInfo({ error, data }) {
    //     if (data) {
    //         this.contactRecTypeId = data.defaultRecordTypeId ? data.defaultRecordTypeId : '';
    //         //console.log('this.contactRecTypeId: ' + this.contactRecTypeId);
    //     } else if (error) {
    //     }
    // }

    loginPage = {//RWPS-5367
        loginURL: '/login?ptcms=true'
    }
    //images
    images = {
        question : sres_ECOM_CartIcons + '/img/tooltip-image.svg',
        closeIcon: sres_ECOM_CartIcons + '/img/close-icon.svg',
    }

    //getters
    get privacyNotice() {
        return this.locale && this.locale != '' ? this.labels.ECOM_LBL_REVVITYBASEURL + this.locale + this.labels.ECOM_LBL_PRIVACYNOTICEURL 
        : this.labels.ECOM_LBL_REVVITYBASEURL + this.labels.ECOM_LBL_PRIVACYNOTICEURL;
    }

    get termsAndConditionsLink(){
        console.log('1');
        return this.locale && this.locale != '' ? this.labels.ECOM_LBL_REVVITYBASEURL + this.locale + this.labels.ECOM_LBL_TERMSANDCONDITIONSSITEPATH 
        : this.labels.ECOM_LBL_REVVITYBASEURL + this.labels.ECOM_LBL_TERMSANDCONDITIONSSITEPATH;
    }

    get updatedValidationMap() {
        //console.log('updatedValidationMap:: ', this.validationMap);//Remove after DEV
        return this.validationMap;
    }

    get updateShowSpinner(){
        let currentSpinnerView = this.showSpinner;
        const selectEvent = new CustomEvent('switchspinner', {
            detail: currentSpinnerView
        });
        //console.log('currentSpinnerView', currentSpinnerView);//Remove after DEV
        this.dispatchEvent(selectEvent);
    }

    //RWPS-5361 start
    renderedCallback() {
        setTimeout(() => {
            this.validateAutofilledFields();
        }, 50);
    }
    //RWPS-5361 end
    //lifecycle hooks
    connectedCallback(){
        //console.log('LOCALE::', LOCALE);//Remove after DEV
        //console.log('Navigator:: ', navigator.language);//Remove after DEV
        //console.log('CURRENCYCODE:: ', CURRENCYCODE);
        //console.log('Navigator.systemlanguage:: ', navigator.systemlanguage);//Remove after DEV
        
        this.validationMap = {
            firstname : {
                isValidated : false,
                isError : false,
                errorMessage : this.getErrorLabels(this.labels.ECOM_LBL_FIRSTNAME)
            },
            lastname : {
                isValidated : false,
                isError : false,
                errorMessage : this.getErrorLabels(this.labels.ECOM_LBL_LASTNAME)
            },
            companyname : {
                isValidated : false,
                isError : false,
                errorMessage : this.getErrorLabels(this.labels.ECOM_LBL_COMPANYNAME)
            },
            businessemailaddress : {
                isValidated : false,
                isError : false,
                validateEmail: true,
                isEmailValidationFailed: false,
                errorMessage : this.getErrorLabels(this.labels.ECOM_LBL_BUSINESSEMAILADDRESS)
            },
            country : {
                isValidated : true,
                isError : false,
                errorMessage  :this.getErrorLabels(this.labels.ECOM_LBL_COUNTRY)
            },
            phonenumber : {
                isValidated : false,
                isError : false,
                validatePhoneNumber : true,
                errorMessage : this.getErrorLabels(this.labels.ECOM_LBL_PHONENUMBER),
            }
        };

        //handle subscription
        this.handleMessageChannelSubscription();
    }

    //RWPS-5361 start
    validateAutofilledFields() {
        Object.keys(this.validationMap).forEach(name => {
            const field = this.template.querySelector(`[data-id="${name}"]`);
            if (field && field.value && field.value.trim() !== "") {
                this.validateInput({
                    currentTarget: field,
                    isTrusted: false // indicates autofill
                });
            }
        });
    }//RWPS-5361 end

    getCurrentLocation(){
        // Configure options for location request
        const locationOptions = {
            enableHighAccuracy: true
        }

        // Make the request
        // Uses anonymous function to handle results or errors
        this.myLocationService
            .getCurrentPosition(locationOptions)
            .then((result)  => {
                // this.currentLocation = result;

                // result is a Location object
                //console.log(JSON.stringify(result));
            })
            .catch((error) => {
                // Handle errors here
                console.error(error);
            })
    }

    validateProceedToRegistration(){
        let validationComplete = true;
        let isTermsAndConditionsChecked = true;

        let validationList = [];

        for (const [key, value] of Object.entries(this.validationMap)){
            //console.log('key:: ', key, ' value:: ', value);//Remove after DEV
            if((value && value.isError  ) || (value && value.isEmailValidationFailed ) || (value && value.isValidated == false)){
                if(value.isValidated == false ){
                    value.isError = true;
                }

                if(value.isEmailValidationFailed &&  value.isEmailValidationFailed == true){
                    value.isError = false;
                }

                value.isValidated = false;
                validationComplete = false;
                //const fieldToFocus = this.template.querySelector('[data-id="' + key + '"]');

                const currentField = this.refs[key];
                if(value.isError) {
                    currentField.classList.add('ecom-error')
                } else {
                    if(currentField.classList.contains('ecom-error')) {
                        currentField.classList.remove('ecom-error')
                    }
                }
                
                validationList.push('key');
            } 

            //VRa 24 Jun 2024 - ECOM - 3362: Begin
            if(validationList.length > 0) {
                validationComplete = false;

            }
            //VRa 24 Jun 2024 - ECOM - 3362: End
        }

        if(!this.isTermsAndConditionsChecked){
            isTermsAndConditionsChecked = false;
            this.isTermsAndConditionsError = true;
        }

        return validationComplete && isTermsAndConditionsChecked;

    }


    //VRa 24 Jun 2024 - ECOM - 3362: Begin
    scrollToPageTop(){
        const scrollOptions = {
            left: 0,
            top: 350,
            behavior: 'smooth'
        }
        window.scrollTo(scrollOptions);
    }
    //VRa 24 Jun 2024 - ECOM - 3362: End

    validateInput(event){

        const targetName = event.currentTarget.dataset.id;
        //console.log('target:: ', targetName);//Remove after DEV
        let currentValidation = this.validationMap[targetName];
        //console.log('currentValidation:: ', JSON.parse(JSON.stringify(currentValidation)));//Remove after DEV

        if(currentValidation && targetName ){
            let value = this.refs[targetName].value;
            let targetField = this.refs[targetName];
            value = value != undefined && value != null && value != '' ? value.trim() : ''; 
            this.refs[targetName].value = value;
            
                if(value == '' || value == undefined || value == null ) {
                    this.validationMap[targetName].isError = true;
                    this.validationMap[targetName].isValidated = false;
                    targetField.classList.add('ecom-error');
                } else {

                    this.refs[targetName].value = value.trim();

                    this.validationMap[targetName].isError = false;
                    this.validationMap[targetName].isValidated = true;
                    if(targetField.classList.contains('ecom-error')){
                        targetField.classList.remove('ecom-error')
                    }
                }

                if(currentValidation.validateEmail ){
                    try{
                        value = value.replace(/\s/g,'');
                        this.refs[targetName].value = value;
                        const emailValidated = this.validateEmail(value);
                        //console.log('emailValidated', emailValidated);//Remove after DEV
                        this.validationMap[targetName].isEmailValidationFailed = emailValidated == false && !this.validationMap[targetName].isError ? true : false;
                        this.validationMap[targetName].isValidated = emailValidated == false ? false : true;
                    }catch(error){
                        //console.log('error::', error);//Remove after DEV
                    }
                    
                }

                //validate phone number
                if(currentValidation.validatePhoneNumber){
                    this.validationMap[targetName].errorMessage = this.getErrorLabels(this.labels.ECOM_LBL_PHONENUMBER);
                    value = value.replace(/\D/g,'');
                    //console.log('phoneNumber::', value);//Remove after DEV
                    if(value == '' || value == undefined || value == null  ){
                        this.validationMap[targetName].isValidated=false;
                        this.validationMap[targetName].isError = true;
                        this.refs[targetName].value = value;
                    } 
                    // else if (value && value.length < 10) {
                    //     this.validationMap[targetName].isValidated=false;
                    //     this.validationMap[targetName].isError = true;
                    //     this.validationMap[targetName].errorMessage = this.labels.ECOM_LBL_PHONENUMBERLENGTHERROR;
                    //     this.refs[targetName].value = value;
                    // }
                    else {
                        // value = value.substring(0,10);
                        // value = value.replace(/\D+/g, '')
                        //     .replace(/(\d{3})(\d{3})(\d{4})/, '($1) $2-$3');
                        this.refs[targetName].value = value;
                        this.validationMap[targetName].isValidated=true;
                        this.validationMap[targetName].isError = false;
                    }
                }
        }
        //console.log('validationMap: ', JSON.parse(JSON.stringify(this.validationMap)));//Remove after DEV
    }

    /**
     *  Validate email format
     * @param {*} userName 
     */
    validateEmail(email){

        let isValidEmail = false;

        //const mailFormat = /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/;
        const mailFormat = '[a-zA-Z0-9._%+\\-]+@[a-zA-Z0-9.\\-]+\\.[a-zA-Z]{2,}$';
        //const mailFormat = String(this.labels.ECOM_LBL_EMAILVALIDATIONREGEX);

        if(email.match(mailFormat)){
            isValidEmail = true;
        } else {
            isValidEmail = false;
        }
        //console.log('isValidEmail::', isValidEmail);//Remove after DEV

        return isValidEmail;
    }

    //handlers
    /**
     * This method validates the form data and calls method to register the user
     * @param {*} event 
     */
    validateFormAndHandleRegistration(event){
        this.showSpinner = true;

        try{
            if(this.validateProceedToRegistration()) {
                let registrationValueMap = {
                    varFirstName : this.refs['firstname'].value,
                    varLastName : this.refs['lastname'].value,
                    varAccountNumber : this.refs['accountnumber'].value,
                    varUserEmail : this.refs['businessemailaddress'].value,
                    varUserCompany : this.refs['companyname'].value,
                    varLocale : this.currentLocaleValue.replace('-', '_'),
                    //VRa - ECOM-3447 : begin jul 10
                    varPhoneCountryCode: this.refs['country'].value +  ' (' + this.currentPhoneCode + ')',
                    //varPhoneNumber: this.currentPhoneCode + this.refs['phonenumber'].value,
                    varPhoneNumber: this.refs['phonenumber'].value,
                    //VRa - ECOM-3447 : end jul 10
                    //varLanguage: 'en_US',
                    varCurrencyCode : this.currentCurrencyCode,
                    varCountryCode : this.currentCountryCode,
                    varEmailEncodingKey : 'UTF-8',
                    varTimezoneSIDKey : this.currentTimezone,//TIMEZONE,
                    varCountry: this.refs['country'].value ,//'United States'
                }

                this.scrollToPageTop();
                //console.log('registrationValueMap:: ', registrationValueMap);//Remove after DEV
                // Fix for RWPS-2037
                this.refs['registerBtn'].disabled = true;
                // Fix End

                //RWPS-5938
                getUserDetails({ userEmail: registrationValueMap.varUserEmail })
                .then(result => {
                    console.log('Final Result -->'+result)
                    if (result) {
                        if (result && result[0] && result[0].ECOM_Is_Punchout_User__c == true) {
                            this[NavigationMixin.Navigate]({
                                type: 'standard__webPage',
                                attributes: {
                                    url: '/ForgotPassword?ptcms=true' + '&' + 'userEmail=' + registrationValueMap.varUserEmail,
                                },
                                state: {
                                    userEmail: registrationValueMap.varUserEmail
                                }
                            });
                        } else {
                            this.registerNewAccount(registrationValueMap);
                        }
                    } else {
                        this.registerNewAccount(registrationValueMap);
                    }
                })
                .catch(error => {
                    this.registerNewAccount(registrationValueMap);
                    console.error('Error in fetching user details: ', error);
                });
                //RWPS-5938
            } else {
                this.showSpinner = false;
                this.scrollToPageTop();
            }
        } catch(error){
            this.showSpinner = false;
            //console.log('validateFormAndHandleRegistration: failed:: ', error);//Remove after DEV
            // Fix for RWPS-2037
            this.refs['registerBtn'].disabled = false;
            // Fix End
        }
    }

    //RWPS-5938
    registerNewAccount(registrationValueMap) {
        registerAccount({
            registrationDataMap: registrationValueMap
        }).then( result => {
            //console.log('result::', result);//Remove after DEV
            if(result && result.success){
                this.showSpinner = false;
                //check if result was successful
                if(result.responseData && result.responseData.resultSuccess ){
                    // Response message needs to be displayed
                    this.navigateToRegistrationSuccess();
                } else {
                    //failed 
                    this.errorMessageText = result.responseData.varResponseMessage;
                    this.displayErrorMessage = true;
                    // Fix for RWPS-2037
                    this.refs['registerBtn'].disabled = false;
                    // Fix End
                    //this.template.querySelector('errormessageblock').scrollIntoView();
                    //this.refs.errormessage.scrollIntoView();
                }
            } else {
                // Fix for RWPS-2037
                this.refs['registerBtn'].disabled = false;
                // Fix End
                this.showSpinner = false;
                //registration flow failed
                this.errorMessageText = '' //TODO: this needs to be updtaed
                this.displayErrorMessage = true;
            }
        }).catch(error => {
            //console.log('Error:: ', error);//Remove after DEV
            // Fix for RWPS-2037
            this.refs['registerBtn'].disabled = false;
            // Fix End
            //registration flow failed
            this.errorMessageText = '' //TODO: this needs to be updtaed
            this.displayErrorMessage = true;
            this.showSpinner = false;
        });
    }

    navigateToLoginPage(){
        //this.navigateToStorePage(this.loginPagePath);
        let redirectUrl = window.location.origin +'/login?ptcms=true';
        window.location.href = redirectUrl;
    }

    navigateToRegistrationSuccess(){
        if(this.registrationSuccessPath == undefined || this.registrationSuccessPath == '' ){
            this.registrationSuccessPath = 'registersuccess';
        }
        //console.log('his.registrationSuccessPagePath:: ', this.registrationSuccessPath);//Remove after DEV


        let baseUrl = window.location.origin;
        //console.log('baseUrl', baseUrl);//Remove after DEV
        let redirectUrl = baseUrl + '/' + this.registrationSuccessPath;
        let urlWithParam =  redirectUrl + '?userEmail=' + this.refs['businessemailaddress'].value + '&ptcms=true';
        //console.log('urlWithParam:: ', urlWithParam);//Remove after DEV
        window.location.replace(urlWithParam);
    }

    //VRa Changes for ECOM-2302 - begin
    navigateToStorePage(storePageName) {
        
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: storePageName 
            }
        });
    }

    getErrorLabels(fieldName){
        return fieldName + ' ' + this.labels.ECOM_LBL_FIELDISREQUIRED;
    }

    /**
     * This method closes the error message block and resets the error message
     * @param {*} event 
     */
    closePrompt(event){
        this.errorMessageText = '';
        this.displayErrorMessage = false;
    }

    handleAcceptTermsAndConditions(event){
        this.isTermsAndConditionsChecked = event.currentTarget.checked;
        if(this.isTermsAndConditionsChecked){
            this.isTermsAndConditionsError = false;
        } else {
            this.isTermsAndConditionsError = true;
        }
        //console.log('isTermsAndConditionsChecked:: ', this.isTermsAndConditionsChecked);//Remove after DEV
    }


    //message channel subscription
    handleMessageChannelSubscription(){
        this.subscription = subscribe(this.messageContext, ECOM_MESSAGE, (message) => this.handleReceivedMessage(message));
    }

    //process message
    handleReceivedMessage(payload){
        console.log('payload::', payload);//Remove after DEV
    
        console.log('boolen:: ', payload && payload.type && payload.type != '' && payload.type != null && payload.type != undefined && payload.type == MESSAGE_TYPE_COUNTRY_SWITCH);//Remove after DEV
        if(payload && payload.type && payload.type != '' && payload.type != null && payload.type != undefined && payload.type == MESSAGE_TYPE_COUNTRY_SWITCH) {
            const item = payload.localeData;
            console.log('handleReceivedMessage.item::', item);//Remove after DEV
            if(item){
                this.currentCountryCode = item.countryCode;
                this.currentLocaleValue = item.locale;
                this.currentTimezone = item.defaultTimeZone;
                this.refs['country'].value = item.country;
                this.currentPhoneCode = item.countryPhoneExtension;
                this.currentCurrencyCode = item.currencyCode;
            }
        }
    }

    //check phone number characters
    validatePhoneNumber(event){
        let isValidCharacter = false;
        let content = this.refs.phonenumber.value;

        const numberFormat = '([0-9])';

        if(content && content != '' && content != undefined && content != null && content.match(numberFormat)){
            isValidCharacter = true;
        } else {
            isValidCharacter = false;
        }
        
        this.refs.phonenumber.value = isValidCharacter ? content : '';

    }

}