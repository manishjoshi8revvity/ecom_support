import { LightningElement, track, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import CONTACT_OBJECT from '@salesforce/schema/Contact';
import SPECIALINSTRUCTIONS_FIELD from '@salesforce/schema/Contact.ECOM_Special_Instructions__c';
import getAddressInfo from '@salesforce/apex/ECOM_CheckoutController.getAddressInfo';
import ssrc_ECOM_Theme from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import FORM_FACTOR from '@salesforce/client/formFactor';
import ECOM_DATALAYERCHANNEL from '@salesforce/messageChannel/ecom_DataLayer__c';
import { subscribe, MessageContext } from 'lightning/messageService';
import saveAdditionalShippingInfo from '@salesforce/apex/ECOM_CheckoutController.saveAdditionalShippingInfo';
import ECOM_DeliveryInstruction  from '@salesforce/label/c.ECOM_DeliveryInstruction';
import ECOM_EuropeVAT  from '@salesforce/label/c.ECOM_EuropeVAT';
import ECOM_invoiceMailingAddressCountries from '@salesforce/label/c.ECOM_invoiceMailingAddressCountries';
import ECOM_InvoiceMailingAddress from '@salesforce/label/c.ECOM_InvoiceMailingAddress';
//RWPS-1285 start
import ECOM_EndUserForTrade from '@salesforce/label/c.ECOM_EndUserForTrade';
import ECOM_CustomerAcceptDate from '@salesforce/label/c.ECOM_CustomerAcceptDate';
import ECOM_Acceptance_Error  from '@salesforce/label/c.ECOM_Acceptance_Error';
import ECOM_EndUserPlaceHolder from '@salesforce/label/c.ECOM_EndUserPlaceHolder';
import ECOM_EndUserOption  from '@salesforce/label/c.ECOM_EndUserOption';
import ECOM_ShippingNote from '@salesforce/label/c.ECOM_ShippingNote';//RWPS-3156
import ECOM_SpecialCharacters from '@salesforce/label/c.ECOM_SpecialCharacters';//RWPS-3087
import ECOM_CheckoutDeliveryError from '@salesforce/label/c.ECOM_CheckoutDeliveryError';//RWPS-3087
import ECOM_EmailToInvoice from '@salesforce/label/c.ECOM_EmailToInvoice';//RWPS-1882
import ECOM_EmailInvalidErrorMessage  from '@salesforce/label/c.ECOM_EmailInvalidErrorMessage';//RWPS-1822
import recipientTitle from '@salesforce/label/c.ecom_Attention_Recipient_Title';//RWPS-4824
import recipientSubTitle from '@salesforce/label/c.ecom_Attention_Recipient_Subtitle';//RWPS-4824
import specialRequestTitle from '@salesforce/label/c.ECOM_Special_Request_Title';//RWPS-4825
import ECOM_Invoice_CustId from '@salesforce/label/c.ECOM_Invoice_CustId';//RWPS-6394
//RWPS-5436
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import ECOM_Is_Test_User__c from '@salesforce/schema/User.ECOM_Is_Test_User__c';
//RWPS-5436

// Import Ecom_util for validation methods
import { validateAddressByFields, validateInvoiceMailingAddressByCountry,sendPostMessage, processAndLogJSError } from 'c/ecom_util';//RWPS-5153

//RWPS-1285 end

export default class Ecom_checkout_shippingDetails extends NavigationMixin(LightningElement) {

    @api effectiveAccountId;
    @api cartId;
    message;
    type;
    show;
    contactInfo;
    shippingAddress={};
    billingAddress={};
    deliveryDetails;
    attentionRecipient;
    contactRecTypeId;
    spInstructionsPicklist = [];
    specialInstructions;
    showPicklist = false;
    isFieldsUpdated = false;
    dataLayerSubscription = null;
    @wire(MessageContext)
    messageContext;
    showSpinner = false;

    // ECOM -1933 variable additions
    billToFieldValidationJSON;
    billToFieldValidationObj;
    validationFields = [];
    isValidatedFields = false;
    // Changes End
    // ECOM - 1939 variable additions
    invoiceAddress = {};
    isInvoiceMailingAddress = false;
    // Changes End
    isDeliveryError = false;
    isCommentError = false; // RWPS-3159
    fileName='ecom_checkout_shippingDetails';//RWPS-5153
    moduleName='Checkout Management';//RWPS-5153

    @api isAccontReadMode;
    @api isAccountEditMode;

    images = {
        helpimg: ssrc_ECOM_Theme + '/img/checkouttooltip.png',
    }

    label = {
        ECOM_DeliveryInstruction,
        ECOM_EuropeVAT,
        ECOM_invoiceMailingAddressCountries,
        ECOM_InvoiceMailingAddress,
        ECOM_EndUserForTrade, // RWPS-1285 start
        ECOM_CustomerAcceptDate,
        ECOM_Acceptance_Error,
        ECOM_EndUserOption,
        ECOM_ShippingNote,//RWPS-3156
        ECOM_EndUserPlaceHolder, // RWPS-1285 end
        ECOM_SpecialCharacters, // RWPS-3087
        ECOM_CheckoutDeliveryError, // RWPS-3087
        ECOM_EmailToInvoice,//RWPS-1882
        ECOM_EmailInvalidErrorMessage, //RWPS-1822
        recipientTitle,//RWPS-4824
        specialRequestTitle, //RWPS-4825
        recipientSubTitle,//RWPS-4824
        ECOM_Invoice_CustId //RWPS-6394
    }

    @track popoverClass = 'slds-popover slds-popover_tooltip slds-nubbin_bottom slds-fall-into-ground ecom-popover';
    @track showTooltip = false;
    //@track isSaveAndContinueDisabled = false;

    device = {
        isMobile : FORM_FACTOR==='Small',
        isDesktop : FORM_FACTOR==='Large',
        isTablet :FORM_FACTOR==='Medium'
    }

    //RWPS-5436
    @api
    isTestingUser;

    @api
    orgDetails;

    @api
    configurationDetails;
    //RWPS-5436


    showPopover(evt){
      this.showTooltip = true;
      this.popoverClass = 'slds-popover slds-popover_tooltip slds-nubbin_bottom slds-rise-from-ground ecom-popover';
    }

    hidePopover(){
        this.showTooltip = false;
        this.popoverClass ='slds-popover slds-popover_tooltip slds-nubbin_bottom-left slds-fall-into-ground ecom-popover'
    }

    handleChange(evt) {
        if(evt.target.dataset.id === 'attention-recipient-id' ){
            this.attentionRecipient = evt.target.value;
        }
        if(evt.target.dataset.id === 'special-instructions-id' ){
            this.specialInstructions = evt.target.value;
        }
        if(evt.target.dataset.id === 'delivery-details-id' ){
            this.deliveryDetails = evt.target.value;
        }
        //RWPS-1285
        if(evt.target.dataset.id === 'enduser-trade-id' ){
            this.endUserDetails = evt.target.value;
        }
        //RWPS-1882
        if(evt.target.dataset.id === 'invoice-email-id'){
            const value = evt.target.value.trim();
            this.invoiceEmailId = value;
            evt.target.setCustomValidity('');
            evt.target.reportValidity();
            this.validateEmail(evt);
        }
         //RWPS-6394 start
        if(evt.target.dataset.id === 'invoice-cust-id'){
            const value = evt.target.value.trim();
            this.invoiceCustId = value;
            evt.target.setCustomValidity('');
            evt.target.reportValidity();
            this.validateInvoiceCustId(evt);
        } //RWPS-6394 end
    }
    // RWPS-1882 start
    validateEmail(event) {
        const value = event.target.value.trim();
        const emailPattern = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;

        let errorMessage = '';
        if (!emailPattern.test(value)) {
            errorMessage = this.label.ECOM_EmailInvalidErrorMessage;
        }
        if (errorMessage) {
            event.target.setCustomValidity(errorMessage);
        } else {
            event.target.setCustomValidity('');
        }
        event.target.reportValidity();
    } // RWPS-1882 start

    //RWPS-6394 start
    validateInvoiceCustId(event) {
        const value = event.target.value.trim();

        const regex = /^[0-9]{4}:[a-zA-Z0-9]{1,20}$/;
        const minLength = 6;
        const maxLength = 25;
        const errorMessage = 'Invalid PEPPOL ID format. Please enter a valid PEPPOL ID (e.g., 9925:BE0887290276).';
        event.target.setCustomValidity('');

        if (value) {

            if (value.length < minLength || value.length > maxLength) {
                event.target.setCustomValidity(errorMessage);
            }
            else if (!regex.test(value)) {
                event.target.setCustomValidity(errorMessage);
            }

        }

        event.target.reportValidity();
    }//RWPS-6394 end

    //RWPS-3087 Start
    handleBlur(event) {
        this.validateDeliveryInput();
    }
    validateDeliveryInput(){
        try {//RWPS-5153
        const forbiddenCharsList = this.label.ECOM_SpecialCharacters.split(',').map(char => char.trim()).join('');
        const forbiddenCharsRegex = new RegExp('[' + forbiddenCharsList + ']');

        if (forbiddenCharsRegex.test(this.deliveryDetails)) {
            this.isDeliveryError = true;
            this.showMessage(this.label.ECOM_CheckoutDeliveryError,'error',true);
            window.scroll(0, 0);
        }
        else
        {
            this.isDeliveryError = false;
            this.handleUpdateMessage();
        }
    }
    catch (error) { //RWPS-5153 start
        processAndLogJSError(error, this.fileName, this.moduleName, 'validateDeliveryInput');//RWPS-5153
    }//RWPS-5153 start
    } //RWPS-3087 end

    // RWPS-3159 start
    handleBlurForEndUserTrade(event) {
        this.validateCommentInput();
    }

    validateCommentInput(){
        try {//RWPS-5153
        const forbiddenCharsList = this.label.ECOM_SpecialCharacters.split(',').map(char => char.trim()).join('');
        const forbiddenCharsRegex = new RegExp('[' + forbiddenCharsList + ']');

        if (forbiddenCharsRegex.test(this.endUserDetails)) {
            this.isCommentError = true;
            this.showMessage(this.label.ECOM_CheckoutDeliveryError,'error',true);
            window.scroll(0, 0);
        }
        else
        {
            this.isCommentError = false;
            this.handleUpdateMessage();
        }
        } catch (error) {//RWPS-5153 start
            processAndLogJSError(error, this.fileName, this.moduleName, 'validateCommentInput')
        }//RWPS-5153 end
    }
    //RWPS-3159 end

    // RWPS-1285 start
    @track isLargePackExist;
    @track isDateSelectorOpen = false;
    @api _selectedDate;
    @track endUserForTradeChecked = true;
    @track endUserDetails;
    @track isInvoiceEmailExist;//RWPS-1882
    @track invoiceEmailId;//RWPS-1882
    @track isInvoiceCustIdExist;//RWPS-6394
    @track invoiceCustId;//RWPS-6394
    @track enableInvoiceCustId;//RWPS-6394
    userRadioSelected = false;
    today = new Date().toISOString().split('T')[0]; //RWPS-7332

    get selectedDate(){
        return this._selectedDate;
    }
    set selectedDate(dateValue){
        this._selectedDate = dateValue;
    }

    //RWPS-5436
    get isTestingMode() {
        return (this.orgDetails && this.orgDetails[0] && this.orgDetails[0].IsSandbox && this.orgDetails[0].IsSandbox == true && this.isTestingUser == true) || (this.isTestingUser == true) ? true : false;
    }

    handleEndUserTradeChange(event){
        this.endUserForTradeChecked =  this.refs.endUsrRadio.checked;
        this.userRadioSelected = true;
    }

    handleDateSelected(event){
        this.selectedDate = event.target.value;
    }

    renderedCallback(){
        if(this.userRadioSelected) {
            if(this.endUserForTradeChecked) {
                this.refs['endUsrRadio'].checked = true;
            } else {
                this.refs['endUsrRadio2'].checked = true;
            }
        }
    }
    handleLPDate() {
     this.refs.acceptanceDate.focus();
    }
    // RWPS-1285 end

    @wire(getObjectInfo, { objectApiName: CONTACT_OBJECT })
    contactObjInfo({ error, data }) {
        if (data) {
            this.contactRecTypeId = data.defaultRecordTypeId ? data.defaultRecordTypeId : '';
        } else if (error) {
           processAndLogJSError(error, this.fileName, this.moduleName, 'contactObjInfo');//RWPS-5153
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$contactRecTypeId', fieldApiName: SPECIALINSTRUCTIONS_FIELD })
    spInstructionsPicklistValues({ error, data }) {
        if (data) {
            this.spInstructionsPicklist.push({label: '--None--', value: ''});
            for(var i=0;i<data.values.length;i++){
                this.spInstructionsPicklist.push({"label" : data.values[i].label, "value" : data.values[i].value});
            }
            this.showPicklist = this.spInstructionsPicklist.length? true:false;
            //this.spInstructionsPicklist = data.values;
        } else if (error) {
            console.log('error ' + JSON.stringify(error));
            processAndLogJSError(error, this.fileName, this.moduleName, 'spInstructionsPicklistValues');//RWPS-5153
        }
    }

    connectedCallback(){
        this.subscribeDataLayerEvent();
        getAddressInfo({
            cartId : this.cartId
        }).then((result) => {
                if(result.Status == 'Success') {
                    this.contactInfo = result.contact;
                    //RWPS-5436 - Start
                    if (this.isTestingMode == true) {
                        this.deliveryDetails = this.configurationDetails?.specialInstructionsForTestUser || '';
                        this.invoiceEmailId = this.configurationDetails?.orderEmailIDsForTestUser || '';
                        this.attentionRecipient = this.configurationDetails?.attentionForTestUser || '';
                    } else {
                        this.deliveryDetails = this.contactInfo?.ECOM_Delivery_Details__c || '';
                        this.attentionRecipient = this.contactInfo?.ECOM_Attention_Recipient__c || '';
                    }
                    //RWPS-5436 - End
                    this.specialInstructions = this.contactInfo?.ECOM_Special_Instructions__c || '';
                    this.shipToModel = result?.shipToModel;
                    this.shippingAddress.street = this.shipToModel?.street;
                    this.shippingAddress.city = this.shipToModel?.city;
                    this.shippingAddress.state = this.shipToModel?.state;
                    this.shippingAddress.zip = this.shipToModel?.postalCode;
                    this.shippingAddress.country = this.shipToModel?.country;
                    this.shippingAddress.externalId = this.shipToModel?.externalId || '';

                    this.billingAddress.street = this.shipToModel?.associatedAddresses?.[0]?.street;
                    this.billingAddress.city = this.shipToModel?.associatedAddresses?.[0]?.city;
                    this.billingAddress.state = this.shipToModel?.associatedAddresses?.[0]?.state;
                    this.billingAddress.zip = this.shipToModel?.associatedAddresses?.[0]?.postalCode;
                    this.billingAddress.country = this.shipToModel?.associatedAddresses?.[0]?.country;
                    this.billingAddress.countryCode = this.shipToModel?.associatedAddresses?.[0]?.countryCode || '';
                    this.billingAddress.externalId = this.shipToModel?.externalId || '';

                    // Changes for ECOM -1939 by sathiya
                    this.invoiceAddress.street = this.shipToModel?.associatedInvoiceAddresses?.[0]?.street;
                    this.invoiceAddress.city = this.shipToModel?.associatedInvoiceAddresses?.[0]?.city;
                    this.invoiceAddress.state = this.shipToModel?.associatedInvoiceAddresses?.[0]?.state;
                    this.invoiceAddress.zip = this.shipToModel?.associatedInvoiceAddresses?.[0]?.postalCode;
                    this.invoiceAddress.country = this.shipToModel?.associatedInvoiceAddresses?.[0]?.country;
                    this.invoiceAddress.countryCode = this.shipToModel?.associatedInvoiceAddresses?.[0]?.countryCode || '';
                    this.invoiceAddress.externalId = this.shipToModel?.externalId || '';

                    this.isInvoiceMailingAddress = validateInvoiceMailingAddressByCountry(this?.shippingAddress?.country, this.label.ECOM_invoiceMailingAddressCountries) && this.invoiceAddress?.country != null && this.invoiceAddress?.country != '';
                    this.isInvoiceMailingAddress = this.shipToModel?.associatedInvoiceAddresses?.[0]?.isShowAddress;
                    // Changes End
                    // ECOM -1933 for new field validations
                    this.billToFieldValidationJSON = result?.billToValidationFields;
                    if(this.billToFieldValidationJSON != null){
                        this.billToFieldValidationObj = JSON.parse(this.billToFieldValidationJSON);
                    }
                    let validatedBillTo = validateAddressByFields(this.shipToModel?.associatedAddresses?.[0], this.billToFieldValidationObj);
                    this.validationFields = validatedBillTo?.validationFields;
                    this.isValidatedFields = validatedBillTo?.isValidatedFields;
                    this.isLargePackExist = result.isLargePackExist; //RWPS-1285
                    this.isInvoiceEmailExist = result.isEmailInvoiceExist;//RWPS-1882
                    this.isInvoiceCustIdExist = result.isInvoiceCustIdExist;//RWPS-6394
                    this.enableInvoiceCustId = result.enableInvoiceCustId;//RWPS-6394

                    // Changes End

                    //////24th-Nov start/////
                    // console.log('this.shippingAddress: '+JSON.stringify(this.shippingAddress));
                    // console.log('this.billingAddress: '+JSON.stringify(this.billingAddress));
                    // console.log('this.billingAddress.countryCode: '+ this.billingAddress.countryCode);
                    // if(this.shippingAddress === null && (this.billingAddress != null && this.billingAddress.countryCode != '')){
                    //     this.isSaveAndContinueDisabled = true;
                    //     this.showMessage(
                    //         'Shipping address should not be blank',
                    //         'error',
                    //         true
                    //         );
                    // }else if(this.shippingAddress != null && (this.billingAddress === null || this.billingAddress.countryCode === '')){
                    //     this.isSaveAndContinueDisabled = true;
                    //     this.showMessage(
                    //         'Billing address should not be blank',
                    //         'error',
                    //         true
                    //         );
                    // }else if(this.shippingAddress === null && (this.billingAddress === null || this.billingAddress.countryCode === '')){
                    //     this.isSaveAndContinueDisabled = true;
                    //     this.showMessage(
                    //         'Shipping & Billing address should not be blank',
                    //         'error',
                    //         true
                    //         );
                    // }else{
                    //     this.isSaveAndContinueDisabled = false;
                    // }
                    // console.log('isSaveAndContinueDisabled: '+ this.isSaveAndContinueDisabled);
                    //////24th-Nov end/////
                    this.dispatchEvent(
                        new CustomEvent('billingaddress', {
                            detail: {
                                address: this.billingAddress,
                                contactInfo: this.contactInfo
                            }
                        }, {
                            bubbles: true,
                          })
                    );

                }
            })
            .catch((error) => {
                this.showMessage(
                    result.ErrorMessage,
                    'error',
                    true
                    );
                processAndLogJSError(error, this.fileName, this.moduleName, 'getAddressInfo');//RWPS-5153
            });
    }

    handleSaveAndContinueToOrderReview(){
         //RWPS-4000 Start
         try {//RWPS-5153
         if (!this.isInvoiceEmailExist) {
            const invoiceEmailInput = this.refs.invoiceEmailInput;
            if (invoiceEmailInput && (!this.invoiceEmailId || !this.invoiceEmailId.trim())) {
                invoiceEmailInput.scrollIntoView({
                    behavior: 'auto',
                    block: 'center'
                });
                invoiceEmailInput.focus();
                invoiceEmailInput.reportValidity();
                return;
            }
        }
        //RWPS-4000 End

        // RWPS-6394 Start - PEPPOL ID Required Validation
        if (this.enableInvoiceCustId) {
            const invoiceCustIdInput = this.refs.invoiceCustIdInput;

            if (invoiceCustIdInput && !invoiceCustIdInput.checkValidity()) {
                invoiceCustIdInput.scrollIntoView({
                    behavior: 'auto',
                    block: 'center'
                });
                invoiceCustIdInput.focus();
                invoiceCustIdInput.reportValidity();
                return;
            }
        }
        // RWPS-6394 End
        
        //RWPS-1882 start
        const allValid = [
            ...this.template.querySelectorAll('lightning-input')
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        if(allValid) {//RWPS-1882 End
        this.showSpinner = true;
        //RWPS-1285 start
        if(this.isLargePackExist) {
            let isError = false;//RWPS-1882
            if(this.selectedDate ==undefined) {
                isError = true;
                this.refs['acceptanceDate'].classList.add('slds-has-error');
            }
            if(!this.userRadioSelected) {
                isError=true;
                this.refs['endUsrOpt'].classList.remove('slds-box-border');
                this.refs['endUsrOpt'].classList.add('slds-box-border-error');
                this.refs['endUsrOpt2'].classList.remove('slds-box-border');
                this.refs['endUsrOpt2'].classList.add('slds-box-border-error');
            }
            if(this.endUserForTradeChecked !=true && (this.endUserDetails =='' || this.endUserDetails==undefined)) {
                this.refs['enduserTrade'].classList.add('slds-has-error');
                isError = true;
            }
            //RWPS-1882 start
            if(!this.isInvoiceEmailExist) {
                if(this.invoiceEmailId == undefined || !this.invoiceEmailId.trim()) {
                    isError = true;
                    const emailContainer = this.template.querySelector('[data-id="invoice-container"]');
                    if (emailContainer) {
                        emailContainer.classList.add('slds-has-error');
                    }
                }
            }//RWPS-1882 end
            if(isError) {
                this.showMessage(this.label.ECOM_Acceptance_Error,'error',true);
                this.showSpinner = false;
                return;
            }
        }
        //RWPS-3087 start
        this.validateDeliveryInput();
        if (this.isDeliveryError) {
            this.showSpinner = false;
            return;
        }//RWPS-3087 end
        //RWPS-3159 start
        this.validateCommentInput();
        if (this.isCommentError) {
            this.showSpinner = false;
            return;
        }//RWPS-3159 end
        if(this.isLargePackExist) {
            if(this.endUserForTradeChecked ==true ) {
                this.endUserDetails = '';
            }
            this.dispatchEvent(
                new CustomEvent('largepackpropertyevent', {
                    detail: {
                        selectedDate: this.selectedDate,
                        endUserForTradeChecked: this.endUserForTradeChecked,
                        endUserDetails:this.endUserDetails
                    }
                }, {
                    bubbles: true,
                  })
            );
        } //RWPS-1285 end
        //RWPS-1882 start
        if(!this.isInvoiceEmailExist) {
            let isError = false;//RWPS-1882
            if(this.invoiceEmailId == undefined || !this.invoiceEmailId.trim()) {
                isError = true;
                const emailContainer = this.template.querySelector('[data-id="invoice-container"]');
                if (emailContainer) {
                    emailContainer.classList.add('slds-has-error');
                }
            }
            if(isError) {
                this.showMessage(this.label.ECOM_Acceptance_Error,'error',true);
                this.showSpinner = false;
                return;
            }
            this.dispatchEvent(
                new CustomEvent('setinvoiceemailevent', {
                    detail: {
                        invoiceEmailId : this.invoiceEmailId
                    }
                }, {
                    bubbles: true,
                  })
            );
        }//RWSP-1882 end
         //RWPS-6394 start
        if(!this.isInvoiceCustIdExist) {
             this.dispatchEvent(
                new CustomEvent('setinvoicecustidevent', {
                    detail: {
                        invoiceCustId : this.invoiceCustId
                    }
                }, {
                    bubbles: true,
                  })
            );
        }//RWPS-6394 end

        if(this.deliveryDetails != this.contactInfo.ECOM_Delivery_Details__c
            ||this.attentionRecipient != this.contactInfo.ECOM_Attention_Recipient__c
            || this.specialInstructions != this.contactInfo.ECOM_Special_Instructions__c){
            this.isFieldsUpdated = true;
        }
        if(this.isFieldsUpdated){
            saveAdditionalShippingInfo({
                deliveryDetails: this.deliveryDetails,
                attentionRecipient: this.attentionRecipient,
                specialInstructions: this.specialInstructions
            }).then((result) => {
                if(result){
                    this.isFieldsUpdated = false;
                    if(result.Status == 'Success'){
                        this.contactInfo = result.Contact;
                        this.moveToNextSection();
                        this.showMessage(
                            'Contact info updated successfully.',
                            'success',
                            true
                            );
                    }
                    else{
                        this.showMessage(
                            result.ErrorMessage,
                            'error',
                            true
                            );
                    }

                }
                })
                 .catch((error) => {
                    this.showSpinner = false;
                    processAndLogJSError(error, this.fileName, this.moduleName, 'handleSaveAndContinueToOrderReview');//RWPS-5153
                       this.showMessage(
                            result.ErrorMessage,
                            'error',
                            true
                            );
                })
                .finally(() => {//RWPS-5153 start
                    this.showSpinner = false;
                });//RWPS-5153 end
        }else{
                this.moveToNextSection();
                this.showSpinner = false; //RWPS-5436
            }
        }
    } catch (error) {//RWPS-5153 
        processAndLogJSError(error, this.fileName, this.moduleName, 'handleSaveAndContinueToOrderReview');//RWPS-5153 
        this.showSpinner = false;
    }
}

    moveToNextSection(){
        this.dispatchEvent(
            new CustomEvent('showreviewsection', {
                detail: {
                    moveToNextSection: true,
                    // poNumber: '',
                    // quoteNumber: '',
                    // promoCode: ''
                }
            })
        );

    }

    showMessage(message,type,show){
        this.message = message;
        this.type = type;
        this.show = show;
    }
    handleUpdateMessage(){
        this.message = '';
        this.type = '';
        this.show = false;
    }

    navigateToAccounts(){
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
                    attributes: {
                    url: '/dashboard?accountEdit'
                }
            });
    }
    subscribeDataLayerEvent() {
        try{    //RWPS-5153
        if (this.dataLayerSubscription) {
            return;
        }
        this.dataLayerSubscription = subscribe(this.messageContext, ECOM_DATALAYERCHANNEL, (message) => {
            if(message?.type === 'CheckoutStep1DataLayer'){
                revvityGTM.pushData(message.data);
            }
        });
    }catch (error) {//RWPS-5153 start 
        processAndLogJSError(error, this.fileName, this.moduleName, 'subscribeDataLayerEvent')
    }//RWPS-5153 end
    }
}