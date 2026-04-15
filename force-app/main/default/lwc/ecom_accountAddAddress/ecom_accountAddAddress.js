import { LightningElement, track, wire, api } from 'lwc';
// Import Ecom_util for validation methods
import { validateAddressByFields, validateInvoiceMailingAddressByCountry } from 'c/ecom_util';
// Changes End
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import ssrc_ECOM_Theme from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import COUNTRY_CODE from '@salesforce/schema/ContactPointAddress.CountryCode';
import STATE_CODE  from '@salesforce/schema/ContactPointAddress.StateCode';
import createERPAddresses from '@salesforce/apex/ECOM_ContactController.createERPAddresses';
import fetchNewERPAddresses from '@salesforce/apex/ECOM_ContactController.fetchNewERPAddresses';
import getContactInfo from '@salesforce/apex/ECOM_ContactController.getContactInfo'; //RWPS-1924
import redirectionMap from '@salesforce/apex/ECOM_UserController.getCmsRedirectMapForWebUser';
import FORM_FACTOR from '@salesforce/client/formFactor';

//custom Labels
import ECOM_AddAddress from '@salesforce/label/c.ECOM_AddAddress';
import ECOM_ShippingInformation from '@salesforce/label/c.ECOM_ShippingInformation';
import ECOM_BillingInformation from '@salesforce/label/c.ECOM_BillingInformation';
import ECOM_SameBillingAndShipping from '@salesforce/label/c.ECOM_SameBillingAndShipping';
import ECOM_AddShippingInformation from '@salesforce/label/c.ECOM_AddShippingInformation';
import ECOM_ShippingDisplayNote from '@salesforce/label/c.ECOM_ShippingDisplayNote';
import ECOM_RequiredField from '@salesforce/label/c.ECOM_RequiredField';
import ECOM_BackToAccountList from '@salesforce/label/c.ECOM_BackToAccountList';
import ECOM_EuropeVAT  from '@salesforce/label/c.ECOM_EuropeVAT';
import ECOM_InvoiceMailingInformation from '@salesforce/label/c.ECOM_InvoiceMailingInformation';
import ECOM_SameInvoiceAddressAsBilling from '@salesforce/label/c.ECOM_SameInvoiceAddressAsBilling';
import ECOM_invoiceMailingAddressCountries from '@salesforce/label/c.ECOM_invoiceMailingAddressCountries';
import LBL_CMS_USER_LOGIN_PARAMETER from '@salesforce/label/c.ECOM_CMSUserLoginParameter';//VRa ECOM-1554
import LBL_CMS_BUY_PAGE  from '@salesforce/label/c.ECOM_CMSBuyPage';//VRa ECOM-1554
import LBL_CMS_SHOP_PAGE from '@salesforce/label/c.ECOM_CMSShopPage';//VRa ECOM-3445 Jul 5 2024
import ECOM_BillingDepartmentError from '@salesforce/label/c.ECOM_BillingDepartmentError'; //RWPS-1924
import ECOM_InputErrorMessage from '@salesforce/label/c.ECOM_InputErrorMessage'; //RWPS-2722
import ECOM_ZIPCodeErrorMessage from '@salesforce/label/c.ECOM_ZIPCodeErrorMessage'; //RWPS-3813


import getChangeAccountData from '@salesforce/apex/ECOM_ContactController.getChangeAccountData'; //RWPS-3733
import ECOM_ExistingBillingAddress from '@salesforce/label/c.ECOM_ExistingBillingAddress'; //RWPS-3733
import recipientTitle from '@salesforce/label/c.ecom_Attention_Recipient_Title';//RWPS-4824
import {processAndLogJSError} from 'c/ecom_util'; // RWPS-5153
const DEFAULT_RECORDTYPE_ID='012000000000000AAA';



export default class Ecom_accountAddAddress extends LightningElement {

    labels ={
        ECOM_AddAddress,
        ECOM_ShippingInformation,
        ECOM_BillingInformation,
        ECOM_SameBillingAndShipping,
        ECOM_AddShippingInformation,
        ECOM_ShippingDisplayNote,
        ECOM_RequiredField,
        ECOM_BackToAccountList,
        ECOM_EuropeVAT,
        ECOM_InvoiceMailingInformation,
        ECOM_SameInvoiceAddressAsBilling,
        ECOM_invoiceMailingAddressCountries,
        LBL_CMS_USER_LOGIN_PARAMETER,
        LBL_CMS_BUY_PAGE,
        LBL_CMS_SHOP_PAGE,
        ECOM_BillingDepartmentError, //RWPS-1924,
        ECOM_InputErrorMessage, //RWPS-2722
        ECOM_ZIPCodeErrorMessage, //RWPS-3813
        ECOM_ExistingBillingAddress, //RWPS-3773
        recipientTitle,//RWPS-4824
    };
    @api isEditAddress = false;
    @api redirectURL='';
    device = {
        isMobile : FORM_FACTOR==='Small',
        isDesktop : FORM_FACTOR==='Large' || FORM_FACTOR==='Medium'
        }
    @track
    images = {
        dashboard: ssrc_ECOM_Theme + '/img/dashboard.png',
        logout: ssrc_ECOM_Theme + '/img/logout.png',
        back: ssrc_ECOM_Theme+'/img/back.png'
    }

    _countries = [];
    _countryToStates = {};
    listCPAs = [];
    //contact;
    selectedCountry='';
    countryProvided;
    selectedShippingState;
    selectedBillingState;
    accNameProvided;
    defaultAccName;//RWPS-1506
    contactEmail; //RWPS-1924
    billingEmailErrorShown = false;
    message;
    type;
    show;
    timeSpan=0;
    showLoader=false;
    erpAddressStatus='New';

    // ECOM -1933 variable additions
    billToFieldValidationJSON;
    billToFieldValidationObj;
    // Changes End
    // ECOM - 1947 variable additions
    selectedInvoiceState;
    isInvoiceMailingAddress = false;
    invoiceERPAddress = {};
    defaultERPAddress = {};
    existingBillingAddress; //RWPS-3773
    zipCodeRegex =/^[a-zA-Z0-9 -]+$/; //RWPS-3813 //RWPS-4911
    isFetchBillingAddressSelected = false; //RWPS-3773
    fileName ='ecom_accountAddAddress';//RWPS-5153
    moduleName ='Add Address';//RWPS-5153
    
    @track
    zipCodeErrorMsg; //RWPS-3813
    // Changes End
    //RWPS-2722  START
    @track formFields = {
        'shipping-address-line-1': '',
        'shipping-city-id': '',
        'shipping-zip-id': '',
        'billing-company-name-id':'',
        'billing-address-line-1':'',
        'billing-city-id':'',
        'billing-zip-id':'',
        'street':'',
        'city':'',
        'erpAccountName':'',
        'postalCode':''
    };

    @track fieldErrors = {
        'shipping-address-line-1': false,
        'shipping-city-id': false,
        'shipping-zip-id': false,
        'billing-company-name-id':false,
        'billing-address-line-1':false,
        'billing-city-id':false,
        'billing-zip-id':false,
        'street':false,
        'city':false,
        'erpAccountName':false,
        'postalCode':false
    };

    getInputClass(fieldId) {
        return this.fieldErrors[fieldId] ? 'custom-input custom-input-error' : 'custom-input';
    }

    get fieldValues() {
        return this.formFields;
    }

    get fieldErrorsMap() {
        return this.fieldErrors;
    }
    //RWPS-2722 start
    getLabelWithAsterisk(field) {
        return field.isRequired ? `${field.label} *` : field.label;
    }//RWPS-2722 End

    validateForm() {
        Object.keys(this.formFields).forEach(fieldId => {
            this.fieldErrors[fieldId] = !this.formFields[fieldId]?.trim();
        });
    }
     //RWPS-2722 END
    @track attentionRecipient;
    @wire(getPicklistValues, { recordTypeId: DEFAULT_RECORDTYPE_ID , fieldApiName: COUNTRY_CODE })
    wiredCountires({ error, data }) {
        if(data){
            this._countries = data?.values;
        }else if(error){
            processAndLogJSError(error, this.fileName, this.moduleName, 'wiredCountries');//RWPS-5153
        }
    }

    @wire(getPicklistValues, { recordTypeId: DEFAULT_RECORDTYPE_ID , fieldApiName: STATE_CODE })
    wiredStates({ error, data }) {
        if(data){

            const validForNumberToCountry = Object.fromEntries(Object.entries(data.controllerValues).map(([key, value]) => [value, key]));
            this._countryToStates = data.values.reduce((accumulatedStates, state) => {
                const countryIsoCode = validForNumberToCountry[state.validFor[0]];

                return { ...accumulatedStates, [countryIsoCode]: [...(accumulatedStates?.[countryIsoCode] || []), state] };
            }, {});

            //this.getUserInfoNow();
            this.fetchAccounts();
        }else if (error){
            this.fetchAccounts();
            processAndLogJSError(error, this.fileName, this.moduleName, 'wiredStates');//RWPS-5153
        }
    }

    get countries() {
        return this._countries;
    }

    get states() {
        return this._countryToStates[this.selectedCountry] || [];
    }

    allAddressToSave=[];
    // New ERP Address changes start
     shippingERPAddress ={
        accountId: '',
        contactId : '',
        addressType: "Ship To",
        city:"",
        country:"",
        ecomReviewStatus: "New",
        erpAccountName:"",
        externalId: "",
        id: "",
        postalCode: "",
        state: "",
        street: "",
        associatedAddresses:[]
    };
    @track billingERPAddress ={
        accountId: '',
        contactId : '',
        addressType: "Payer",
        city:"",
        country:"",
        ecomReviewStatus: "New",
        erpAccountName:"",
        externalId: "",
        id: "",
        postalCode: "",
        state: "",
        street: "",
        associatedAddresses:[]
        };

        showMessage(message,type,show){
            this.message = message;
            this.type = type;
            this.show = show;
        }

        sidebarCSS='';
        middleSpaceCSS='';
        mainSectionCSS='';


     connectedCallback(){
        this.fetchContactInfo(); //RWPS-1924
        this.loadBasedOnDeviceType();
        this.fetchBillAddresses(); //RWPS-3773
     }

     loadBasedOnDeviceType(){
        //Tab UI fix - Gaurang - 18 July 2024
        var width = (window.innerWidth > 0) ? window.innerWidth : screen.width;
        if(FORM_FACTOR==='Medium' || (width==1025)){
            this.sidebarCSS = 'slds-col slds-size_12-of-12 slds-large-size_12-of-12 slds-medium-size_12-of-12';
            this.middleSpaceCSS = 'doNotDisplay';
            this.mainSectionCSS = 'slds-col slds-size_12-of-12 slds-large-size_12-of-12 slds-medium-size_12-of-12 ecom-mt-64';
        }
        else{
            this.sidebarCSS = 'slds-col slds-size_12-of-12 slds-large-size_3-of-12 slds-medium-size_3-of-12';
            this.middleSpaceCSS = 'slds-col slds-large-size_1-of-12 slds-medium-size_1-of-12';
            this.mainSectionCSS = 'slds-col slds-size_12-of-12 slds-large-size_8-of-12 slds-medium-size_8-of-12 ecom-mt-64';
        }
    }

     fetchContactInfo(){ /*RWPS-1924*/
        getContactInfo()
        .then(result=>{
            if(result)
            {
                this.defaultAccName = result?.ECOM_AccountNameProvided__c;//RWPS-1506
                this.contactEmail = result?.Email;
            }
        }).catch(error=>{
            processAndLogJSError(error, this.fileName, this.moduleName, 'getContactInfo');//RWPS-5153
        })
     }

     fetchAccounts()
     {
        fetchNewERPAddresses()
        .then(result=>{
            if(result.success)
            {
                // ECOM -1933 for new field validations by sathiya
                this.billToFieldValidationJSON = result?.billToValidationFields;
                if(this.billToFieldValidationJSON != null){
                    this.billToFieldValidationObj = JSON.parse(this.billToFieldValidationJSON);
                }
                // Changes End
                var erps=result.erpAddresses;
                if(erps?.id){
                    this.defaultERPAddress = JSON.parse(JSON.stringify(this.billingERPAddress));
                    this.shippingERPAddress=erps;
                    this.accNameProvided = this.shippingERPAddress?.erpAccountName?.trim() ? this.shippingERPAddress.erpAccountName: this.defaultAccName;//RWPS-1506
                    //RWPS-2722 START
                    this.formFields['shipping-address-line-1'] = this.shippingERPAddress.street || '';
                    this.formFields['shipping-city-id'] = this.shippingERPAddress.city || '';
                    this.formFields['shipping-zip-id'] = this.shippingERPAddress.postalCode || '';
                    //RWPS-2722 END

                    //RWPS-5437 Start
                    const hasBillingAddress = erps.associatedAddresses != null &&
                            Array.isArray(erps.associatedAddresses) &&
                            erps.associatedAddresses.length > 0 &&
                            erps.associatedAddresses[0] !== undefined &&
                            erps.associatedAddresses[0] !== null &&
                            erps.associatedAddresses[0].id != null;
                    
                    if (!hasBillingAddress) {
                        //Billing address is MISSING - initialize empty fields
                        this.billingERPAddress = {
                            accountId: '',
                            contactId : '',
                            addressType: "Payer",
                            ecomReviewStatus: "New",                            
                            city: "",
                            country: this.shippingERPAddress.country,
                            erpAccountName: this.accNameProvided || "",
                            externalId: "",
                            id: "",
                            postalCode: "",
                            state: "",
                            street: "",
                            associatedAddresses: [],
                            emailToInvoice: "",
                            vatNumber: "",           // VAT field
                            invoiceCustId: "",       // IPA field
                            eanDoNotUse: ""         // Codice Commessa field
                        };
                        this.formFields['billing-company-name-id'] = this.accNameProvided || '';
                        this.formFields['billing-address-line-1'] = '';
                        this.formFields['billing-city-id'] = '';
                        this.formFields['billing-zip-id'] = '';

                    }
                    else {
                        // Billing address EXISTS - use it
                        this.billingERPAddress = erps.associatedAddresses[0];
                        
                        //RWPS-2722 START
                        this.formFields['billing-company-name-id'] = this.billingERPAddress.erpAccountName || '';
                        this.formFields['billing-address-line-1'] = this.billingERPAddress.street || '';
                        this.formFields['billing-city-id'] = this.billingERPAddress.city || '';
                        this.formFields['billing-zip-id'] = this.billingERPAddress.postalCode || '';
                        //RWPS-2722 END
                    }
                    //RWPS-5437 END

                    this.selectedCountry = this.countries.find(opt => opt.label === this.shippingERPAddress.country).value;
                    // Changes for ECOM -1939 by sathiya
                    this.isInvoiceMailingAddress = validateInvoiceMailingAddressByCountry(this?.shippingERPAddress?.country, this.labels.ECOM_invoiceMailingAddressCountries);
                    this.defaultERPAddress.country = this?.shippingERPAddress?.country;
                    this.selectedShippingState=this.states.find(opt => opt.label === this.shippingERPAddress.state).value;
                    //RWPS-5437 Start
                    if (this.billingERPAddress.state) {
                        this.selectedBillingState = this.states.find(opt => 
                            opt.label === this.billingERPAddress.state || 
                            opt.value === this.billingERPAddress.state
                        )?.value || '';
                    } else {
                        this.selectedBillingState = '';
                    }
                    //RWPS-5437 End
                    if(this.isInvoiceMailingAddress && this.billingERPAddress != null && erps?.associatedAddresses[0]?.associatedAddresses != null && erps?.associatedAddresses[0]?.associatedAddresses.length > 0){
                        this.invoiceERPAddress= erps?.associatedAddresses[0]?.associatedAddresses[0];
                        //RWPS-2722 start
                        this.formFields['street'] = this.invoiceERPAddress.street;
                        this.formFields['city'] = this.invoiceERPAddress.city;
                        this.formFields['postalCode'] = this.invoiceERPAddress.postalCode;
                        this.formFields['erpAccountName'] = this.invoiceERPAddress.erpAccountName;
                        //RWPS-2722 end
                        if(this.invoiceERPAddress?.state != null){
                            this.selectedInvoiceState=this.states.find(opt => (opt.label === this.invoiceERPAddress.state || opt.value === this.invoiceERPAddress.state)).value;
                        }
                    } else {
                        this.invoiceERPAddress = JSON.parse(JSON.stringify(this.defaultERPAddress));
                        //RWPS-2722 start
                        this.formFields['street'] = this.invoiceERPAddress.street;
                        this.formFields['city'] = this.invoiceERPAddress.city;
                        this.formFields['postalCode'] = this.invoiceERPAddress.postalCode;
                        this.formFields['erpAccountName'] = this.invoiceERPAddress.erpAccountName;
                        //RWPS-2722 end
                        this.invoiceERPAddress.addressType = 'Bill To';
                    }
                    // Changes End
                } else {
                    var country;
                    this.accNameProvided = this.defaultAccName ? this.defaultAccName : result.defaultAccountName;//RWPS-1506 fixed intermittent blank company name issue
                    this.shippingERPAddress.erpAccountName=this.accNameProvided;//RWPS-1506
                    if(result?.country){
                        country=result.country;
                    } else {
                        country='United States';
                    }
                    this.selectedCountry = this.countries.find(opt => opt.label === country || opt.value === country).value;
                    this.shippingERPAddress.country=country;
                    this.billingERPAddress.country=country;
                    this.defaultERPAddress = JSON.parse(JSON.stringify(this.billingERPAddress));
                    //RWPS-2722 START
                    this.formFields['billing-company-name-id'] = this.defaultERPAddress.erpAccountName || '';
                    this.formFields['billing-address-line-1'] = this.defaultERPAddress.street || '';
                    this.formFields['billing-city-id'] = this.defaultERPAddress.city || '';
                    this.formFields['billing-zip-id'] = this.defaultERPAddress.postalCode || '';
                    //RWPS-2722 END
                    // Changes for ECOM -1939 by sathiya
                    this.isInvoiceMailingAddress = validateInvoiceMailingAddressByCountry(country, this.labels.ECOM_invoiceMailingAddressCountries);
                    this.invoiceERPAddress = JSON.parse(JSON.stringify(this.billingERPAddress));
                    this.invoiceERPAddress.addressType = 'Bill To';
                    // Change End
                }

                // ECOM -1933 for new field validations by Sathiya
                this.billingERPAddress = validateAddressByFields(this.billingERPAddress, this.billToFieldValidationObj);
                //RWPS-2722 start
                this.billingERPAddress.validationFields = this.billingERPAddress.validationFields.map(field => ({
                    ...field,
                    labelWithAsterisk: field.isRequired ? `${field.label} *` : field.label
                }));//RWPS-2722 end
                this.billingERPAddress.isValidatedFields = this.billingERPAddress.validationFields.length > 0;
                // Changes End
                this.attentionRecipient=result.attentionRecipient;
            }
            else
            {
                this.accNameProvided = this.defaultAccName ? this.defaultAccName : result.defaultAccountName;//RWPS-1506
                this.shippingERPAddress.erpAccountName = this.accNameProvided;//RWPS-1506
            }
        }).catch(error=>{
            console.log("fetchAccounts error ");//RWPS-1506
            processAndLogJSError(error, this.fileName, this.moduleName,'fetchAccounts');//RWPS-5153
        })
     }
     //RWPS-2722 START
    handleShippingInputChange(event) {
        const { name, value, isValid } = event.detail;
        this.formFields[name] = value;
        this.fieldErrors[name] = !isValid;
        if(name === 'shipping-city-id') {
            this.shippingERPAddress.city = value;
        }
        else if (name === 'shipping-zip-id') { //RWPS-3813
            if(value == null || value== '') {
                this.zipCodeErrorMsg = this.labels.ECOM_InputErrorMessage;
            }
            else if(value.match(this.zipCodeRegex) != null) {
                this.shippingERPAddress.postalCode = value;
            } else {
                this.fieldErrors[name] = true;
                this.zipCodeErrorMsg = this.labels.ECOM_ZIPCodeErrorMessage;
            }                
        }
        else if (name === 'shipping-address-line-1') {
            this.shippingERPAddress.street = value;
        }
    } //RWPS-2722 END

     handleShippingChange(event) {
        if (event.target.value.length>0 && event.target.value[0]==' ') {
            event.target.value = event.target.value.trim();
        }
        if(event.target.dataset.id === 'shipping-company-name-id'){
            this.shippingERPAddress.erpAccountName = event.target.value;

        }
        if(event.target.dataset.id === 'shipping-country-id'){
            this.selectedCountry = event.detail.value;
            this.shippingERPAddress.country = this.countries.find(opt => opt.value === event.detail.value).label;
        }
        // if(event.target.dataset.id === 'shipping-address-line-2'){
        //     this.shippingAddressInfo.Address2 = event.target.value;
        // }
        if(event.target.dataset.id === 'shipping-state-id'){
            this.selectedShippingState = event.detail.value;
            this.shippingERPAddress.state = this.states.find(opt => opt.value === event.detail.value).label;
        }
        if(event.target.dataset.id === 'shipping-phone-id'){
            //this.shippingERPAddress.phone = event.target.value;
        }
        if(event.target.dataset.id === 'shipping-extn-id'){
            //this.shippingERPAddress.extn = event.target.value;
        }
    }
    // Method to validate the change on invoice mailing address fields
    handleInvoiceChange(event){
    try{//RWPS-5153
        let value = event.target.value, addressType = event.target.dataset.addresstype, id = event.target.dataset.id;
        if(addressType == 'invoice'){
            if (event.target.value.length>0 && event.target.value[0]==' ') {
                event.target.value = event.target.value.trim();
            }
            this.invoiceERPAddress[id] = value;
            if(id == "state"){
                this.selectedInvoiceState = value;
                this.invoiceERPAddress.state = this.states.find(opt => opt.value === event.detail.value).label;
            }
        }
    }catch(error){//RWPS-5153 start
        processAndLogJSError(error, this.fileName, this.moduleName,'handleInvoiceChange');
    }//RWPS-5153 end
    }
     //RWPS-2722 START
    handleInvoiceInputChange(event) {
    try{//RWPS-5153
        const { name, value, isValid } = event.detail;
        this.formFields[name] = value;
        this.fieldErrors[name] = !isValid;
        if (name === 'erpAccountName') {
            this.invoiceERPAddress.erpAccountName = value;
        }
        else if (name === 'postalCode') { //RWPS-3813
            if(value == null || value== '') {
                this.zipCodeErrorMsg = this.labels.ECOM_InputErrorMessage;
            }
            else if(value.match(this.zipCodeRegex) != null) {
                this.invoiceERPAddress.postalCode = value;
            } else {
                this.fieldErrors[name] = true;
                this.zipCodeErrorMsg = this.labels.ECOM_ZIPCodeErrorMessage;
            }                
        }
        else if (name === 'street') {
            this.invoiceERPAddress.street = value;
        }
        else if (name === 'city') {
            this.invoiceERPAddress.city = value;
        }
    }catch(error){//RWPS-5153 start
         processAndLogJSError(error, this.fileName, this.moduleName,'handleInvoiceInputChange');
    }//RWPS-5153 end
    }
    //RWPS - 2722 start
    handleComboBlur(event)
    {
        try{//RWPS-5153 start
        const field = event.target;
        const fieldId = field.dataset.id;
        const value = field.value;
        if (!value) {
            field.setCustomValidity(this.labels.ECOM_InputErrorMessage);
        } else {
            field.setCustomValidity('');
        }
        field.reportValidity();
    }catch(error)//RWPS-5153 start
    {
        processAndLogJSError(error, this.fileName, this.moduleName,'handleComboBlur');
    }//RWPS-5153 end
    }//RWPS - 2722 end

    handleBlur(event) {
    try{//RWPS-5153
        const blurredField = event.target.name;
        const value = this.formFields[blurredField];
        const isValid = value?.trim().length > 0;
        this.fieldErrors[blurredField] = !isValid;
    }catch(error)//RWPS-5153 start
    {
        processAndLogJSError(error, this.fileName, this.moduleName,'handleBlur');
    }//RWPS-5153 end
    }
    //RWPS-2722 end

    handleValidation(event){ /*RWPS-1924*/
    try{//RWPS-5153
        if(event.target.dataset.id === 'emailToInvoice'){
            let emailCmp = this.template.querySelector(`[data-id="emailToInvoice"]`);

            if(emailCmp.value.toLowerCase() == this.contactEmail.toLowerCase()) {
                emailCmp.setCustomValidity(this.labels.ECOM_BillingDepartmentError);
                this.billingEmailErrorShown = true;
            }
            else{
                emailCmp.setCustomValidity('');
                this.billingEmailErrorShown = false;
            }
            emailCmp.reportValidity();
        }
        //RWPS-2722 START
        const input = event.target;
        const value = input.value?.trim();
        const isRequired = input.dataset.required === 'true';
        input.setCustomValidity('');

        if (isRequired && !value) {
            input.setCustomValidity(this.labels.ECOM_InputErrorMessage);
        } else {
            input.setCustomValidity('');
        }

        input.reportValidity();
        //RWPS-2722 END
    }catch(error)//RWPS-5153 start
    {
        processAndLogJSError(error, this.fileName, this.moduleName,'handleInvoiceChange');
    }//RWPS-5153 end
    }
     //RWPS-2722 START
    handleBillingInputChange(event) {
    try{//RWPS-5153
        const { name, value, isValid } = event.detail;
        this.formFields[name] = value;
        this.fieldErrors[name] = !isValid;
        if (name === 'billing-company-name-id') {
            this.billingERPAddress.erpAccountName = value;
        }
        else if (name === 'billing-zip-id') { //RWPS-3813
            if(value == null || value== '') {
                this.zipCodeErrorMsg = this.labels.ECOM_InputErrorMessage;
            }
            else if(value.match(this.zipCodeRegex) != null) {
                this.billingERPAddress.postalCode = value;
            } else {
                this.fieldErrors[name] = true;
                this.zipCodeErrorMsg = this.labels.ECOM_ZIPCodeErrorMessage;
            }                
        }
        else if (name === 'billing-address-line-1') {
            this.billingERPAddress.street = value;
        }
        else if (name === 'billing-city-id') {
            this.billingERPAddress.city = value;
        }
    }catch(error){//RWPS-5153 start
         processAndLogJSError(error, this.fileName, this.moduleName,'handleBillingInputChange');
    }//RWPS-5153 end
    }
     //RWPS-2722 END
    handleBillingChange(event) {
    try{//RWPS-5153
        if (event.target.value.length>0 && event.target.value[0]==' ') {
            event.target.value = event.target.value.trim();
        }
        if(event.target.dataset.id === 'billing-country-id'){
            this.selectedCountry = event.target.value;
            this.billingERPAddress.country = this.countries.find(opt => opt.value === event.detail.value).label;
        }
        // if(event.target.dataset.id === 'billing-address-line-2'){
        //     this.billingAddressInfo.Address2 = event.target.value;
        // }
        if(event.target.dataset.id === 'billing-state-id'){
            this.selectedBillingState = event.detail.value;
            this.billingERPAddress.state = this.states.find(opt => opt.value === event.detail.value).label;
        }
        // Changes done by sathiya on 2024/04/29 for ECOM-1933
        if(event?.target?.dataset?.validate != null){
            let fieldId = event?.target?.dataset?.id, fieldValue = event.target.value.trim();
            if(fieldId == 'invoiceCustId'){
                if(this.billingERPAddress?.validationFields){
                    for(let i=0; i<this.billingERPAddress?.validationFields.length; i++){
                        if(this.billingERPAddress?.validationFields[i].fieldName == 'emailToInvoice'){
                            this.billingERPAddress.validationFields[i].isRequired = fieldValue == ''?true:false;
                        }
                    }
                }
            }
            this.billingERPAddress[fieldId] = fieldValue;
        }
        if(this.isInvoiceMailingAddress && this.refs['invoiceCheck'].checked){
            this.refs['invoiceCheck'].checked = false;
            var invoiceAddressId=JSON.parse(JSON.stringify(this.invoiceERPAddress)).id;
            this.invoiceERPAddress = JSON.parse(JSON.stringify(this.defaultERPAddress));
            this.invoiceERPAddress.id=invoiceAddressId;
            this.invoiceERPAddress.addressType = 'Bill To';
            this.selectedInvoiceState= '';
            this.handleDisableTaggle(false);
        }
        // Changes End
        // if(event.target.dataset.id === 'billing-phone-id'){
        //     this.billingERPAddress.phone = event.target.value;
        // }
        // if(event.target.dataset.id === 'billing-extn-id'){
        //     this.billingERPAddress.extn = event.target.value;
        // }
    }catch(error){//RWPS-5153 start
        processAndLogJSError(error, this.fileName, this.moduleName,'handleBillingChange');
    }//RWPS-5153 end
    }

    handleRecipientChange(event){
        if(event.target.dataset.id === 'attention-recipient-id'){
            this.attentionRecipient = event.target.value;
        }

    }
    // Method to map and unmap changes from billing to invoice mailing address
    handleInvoiceCheckboxChange(event){
    try{//RWPS-5153
        if(event.target.checked){
            let tempInvoiceAddress = JSON.parse(JSON.stringify(this.billingERPAddress));
            tempInvoiceAddress.id = (this.invoiceERPAddress?.id != null&& this.invoiceERPAddress?.id != '')?this.invoiceERPAddress?.id:tempInvoiceAddress.Id;
            tempInvoiceAddress.addressType = 'Bill To';
            this.selectedInvoiceState = this.billingERPAddress.state;//RWPS-RWPS-3773
            if(tempInvoiceAddress?.isValidatedFields){
                delete tempInvoiceAddress.isValidatedFields;
                delete tempInvoiceAddress.validationFields;
            }
            this.invoiceERPAddress = tempInvoiceAddress;
            this.invoiceERPAddress.associatedAddresses = [];
             //RWPS-2722 START
            this.formFields['street'] = this.invoiceERPAddress.street;
            this.formFields['city'] = this.invoiceERPAddress.city;
            this.formFields['postalCode'] = this.invoiceERPAddress.postalCode;
            this.formFields['erpAccountName'] = this.invoiceERPAddress.erpAccountName;
            this.fieldErrors['street'] = false;
            this.fieldErrors['city'] = false;
            this.fieldErrors['postalCode'] = false;
            this.fieldErrors['erpAccountName'] = false;
             //RWPS-2722 END
            //RWPS-2722 start
            const invoiceStateInput = this.template.querySelector('[data-id="state"]');

            if (!this.selectedInvoiceState || this.selectedInvoiceState.trim() === "") {//RWPS-RWPS-3773
                invoiceStateInput?.setCustomValidity(this.labels.ECOM_InputErrorMessage);
                invoiceStateInput?.reportValidity();
            } else {
                invoiceStateInput?.setCustomValidity('');
                invoiceStateInput?.reportValidity();
            }//RWPS-2722 end
            this.handleDisableTaggle(true);
        } else {
            var invoiceAddressId=JSON.parse(JSON.stringify(this.invoiceERPAddress)).id;
            this.invoiceERPAddress = JSON.parse(JSON.stringify(this.defaultERPAddress));
            this.invoiceERPAddress.id=invoiceAddressId;
            this.invoiceERPAddress.addressType = 'Bill To';
            this.selectedInvoiceState= '';
             //RWPS-2722 START
            //Clear formFields
            this.formFields['street'] = '';
            this.formFields['city'] = '';
            this.formFields['postalCode'] = '';
            this.formFields['erpAccountName'] = '';
            this.fieldErrors['street'] = false;
            this.fieldErrors['city'] = false;
            this.fieldErrors['postalCode'] = false;
            this.fieldErrors['erpAccountName'] = false;
             //RWPS-2722 END
            this.handleDisableTaggle(false);
        }
    }catch(error)//RWPS-5153 start
    {
        processAndLogJSError(error, this.fileName, this.moduleName,'handleInvoiceCheckboxChange');
    }//RWPS-5153 end
    }

    handleDisableTaggle(toggleFlag){
    try{//RWPS-5153 
        let fields = this.template.querySelectorAll('[data-addresstype="invoice"]');
        if(fields != null && fields.length > 0){
            for(let i = 0; i < fields.length; i++){
                fields[i].style.display = toggleFlag?'none':'block';
            }
        }
        //RWPS-2722 Start
        let allCustomInputs = this.template.querySelectorAll('c-ecom_custom-input');
        allCustomInputs.forEach(inputCmp => {
            const input = inputCmp.shadowRoot.querySelector('[data-addresstype="invoice"]');
            if (input) {
                const wrapperDiv = input.closest('div');
                if (wrapperDiv) {
                    wrapperDiv.style.display = toggleFlag ? 'none' : 'block';
                }
            }
        });//RWPS-2722 end
    }catch(error){//RWPS-5153 start
        processAndLogJSError(error, this.fileName, this.moduleName,'handleDisableTaggle');
    }//RWPS-5153 end
    }

    handleCheckboxChange(event){
    try{//RWPS-5153
        if(event.target.checked){
            //RWPS-4223 Start
            // Preserve billing-only fields before copying
            const preservedEmail = this.billingERPAddress?.emailToInvoice;
            const preservedValidationFields = this.billingERPAddress?.validationFields;
            const preservedId = this.billingERPAddress?.id;

            // Copy only address fields
            this.billingERPAddress.street = this.shippingERPAddress.street;
            this.billingERPAddress.city = this.shippingERPAddress.city;
            this.billingERPAddress.state = this.shippingERPAddress.state;
            this.billingERPAddress.postalCode = this.shippingERPAddress.postalCode;
            this.billingERPAddress.country = this.shippingERPAddress.country;
            this.billingERPAddress.erpAccountName = this.shippingERPAddress.erpAccountName;

            // Restore billing-only fields
            if (preservedEmail) this.billingERPAddress.emailToInvoice = preservedEmail;
            if (preservedValidationFields) this.billingERPAddress.validationFields = preservedValidationFields;
            if (preservedId) this.billingERPAddress.id = preservedId;

            this.billingERPAddress.addressType = 'Payer';
            this.billingERPAddress.associatedAddresses = [];
            //RWPS-4223 End

            this.selectedBillingState = this.selectedShippingState;
            //RWPS-2722 start
            const billingStateInput = this.template.querySelector('[data-id="billing-state-id"]');

            if (!this.selectedShippingState || this.selectedShippingState.trim() === '') {
                billingStateInput?.setCustomValidity(this.labels.ECOM_InputErrorMessage);
                billingStateInput?.reportValidity();
            } else {
                billingStateInput?.setCustomValidity('');
                billingStateInput?.reportValidity();
            }//RWPS-2722 end
            this.billingERPAddress.erpAccountName = this.shippingERPAddress.erpAccountName == ""? this.accNameProvided : this.shippingERPAddress.erpAccountName ;//RWPS-1506
            //RWPS-2722 START
            this.formFields['billing-address-line-1'] = this.billingERPAddress.street;
            this.formFields['billing-city-id'] = this.billingERPAddress.city;
            this.formFields['billing-zip-id'] = this.billingERPAddress.postalCode;
            this.formFields['billing-company-name-id'] = this.billingERPAddress.erpAccountName;
            // Reset field errors
            this.fieldErrors['billing-address-line-1'] = false;
            this.fieldErrors['billing-city-id'] = false;
            this.fieldErrors['billing-zip-id'] = false;
            this.fieldErrors['billing-company-name-id'] = false
             //RWPS-2722 END
        }else{
            const preservedEmail = this.billingERPAddress?.emailToInvoice;//RWPS-4223
            var billingId=JSON.parse(JSON.stringify(this.billingERPAddress)).id;
            this.billingERPAddress ={
                accountId: '',
                contactId : '',
                addressType: "Payer",
                city:"",
                country: this.countries.find(opt => opt.label === this.selectedCountry || opt.value === this.selectedCountry).label, //RWPS-1773
                ecomReviewStatus: "New",
                erpAccountName:"",
                externalId: "",
                postalCode: "",
                state: "",
                street: "",
                associatedAddresses:[],
                emailToInvoice: preservedEmail || "" //RWPS-4223
                };
            this.billingERPAddress.id = billingId;//RWPS-3187 fixed uncheck and check Address save issue
            this.selectedBillingState = '';
            //RWPS-2722 START
            this.formFields['billing-address-line-1'] = '';
            this.formFields['billing-city-id'] = '';
            this.formFields['billing-zip-id'] = '';
            this.formFields['billing-company-name-id'] = '';

            // Reset field errors
            this.fieldErrors['billing-address-line-1'] = false;
            this.fieldErrors['billing-city-id'] = false;
            this.fieldErrors['billing-zip-id'] = false;
            this.formFields['billing-company-name-id'] = false;
            //RWPS-2722 END
        }
        // ECOM -1933 for new field validations by Sathiya
        this.billingERPAddress = validateAddressByFields(this.billingERPAddress, this.billToFieldValidationObj);
        //RWPS-2722 start
        this.billingERPAddress.validationFields = this.billingERPAddress.validationFields.map(field => ({
            ...field,
            labelWithAsterisk: field.isRequired ? `${field.label} *` : field.label
        }));//RWPS-2722 end
        this.billingERPAddress.isValidatedFields = this.billingERPAddress.validationFields.length > 0;
        if(this.isInvoiceMailingAddress){
            this.refs['invoiceCheck'].checked = false;
            var invoiceAddressId=JSON.parse(JSON.stringify(this.invoiceERPAddress)).id;
            this.invoiceERPAddress = JSON.parse(JSON.stringify(this.defaultERPAddress));
            this.formFields['street'] = this.invoiceERPAddress.street;
            this.formFields['city'] = this.invoiceERPAddress.city;
            this.formFields['postalCode'] = this.invoiceERPAddress.postalCode;
            this.formFields['erpAccountName'] = this.invoiceERPAddress.erpAccountName;
            this.invoiceERPAddress.id=invoiceAddressId;
            this.invoiceERPAddress.addressType = 'Bill To';
            this.selectedInvoiceState= '';
            this.handleDisableTaggle(false);
        }
        // Changes End
    }catch(error){//RWPS-5153 start
       processAndLogJSError (error, this.fileName, this.moduleName, 'handleCheckboxChange'); 
    }//RWPS-5153 end
    }

    goBackToAccounts(event){
        this.customEvent('showAddressTab');
    }

    customEvent(nextStep){
        this.dispatchEvent(
            new CustomEvent('addressevent', {
                detail: {
                    nextStep: nextStep
                }
            })
        );
    }

    handleUpdateMessage(){
        this.message = '';
        this.type = '';
        this.show = false;
    }
    //RWPS-2722 START
    handleShippingCompValidation(event) {
    try{//RWPS-5153
        const input = event.target;
        const value = input.value?.trim();
        const dataId = input.dataset.id;

        if (dataId === 'shipping-company-name-id') {
            if (!value) {
                input.setCustomValidity(this.labels.ECOM_InputErrorMessage);
            } else {
                input.setCustomValidity('');
            }
            input.reportValidity();
        }
    }catch(error){//RWPS-5153 start
        processAndLogJSError(error, this.fileName, this.moduleName,'handleShippingCompValidation');
    }//RWPS-5153 start   
    }//RWPS-2722 END

    handleSaveAddress(){
    try{//RWPS-5153
        this.show=false;
        if(this.shippingERPAddress.ecomReviewStatus == 'New' && this.billingERPAddress.ecomReviewStatus == 'New'){
            let emailCmp = this.template.querySelector('.billing-input');
            if(this.billingEmailErrorShown){
                emailCmp.setCustomValidity('');
                emailCmp.reportValidity();
            }
            const allValid = [
                ...this.template.querySelectorAll('lightning-input'),
                ...this.template.querySelectorAll('lightning-combobox')
            ].reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);
            //RWPS-2722 START
            const customInputs = this.template.querySelectorAll('c-ecom_custom-input');
            customInputs.forEach(inputCmp => {
                const name = inputCmp.name;
                const value = this.formFields[name];
                const isValid = value && value.length > 0;
                this.fieldErrors[name] = !isValid;
                // Only add the class if the field is empty
                if (!isValid && !inputCmp.classList.contains('input-error')) {
                    inputCmp.classList.add('input-error');
                }
                //RWPS-3813
                if(name==='shipping-zip-id' || name ==='billing-zip-id'){
                    if(value && value.match(this.zipCodeRegex) == null) {
                        inputCmp.classList.add('input-error');
                        this.fieldErrors[name] = true;
                    }
                }
            });
            let isValid = true;

            this.template.querySelectorAll('[data-validate="true"]').forEach(input => {
                const value = input.value?.trim();
                const isRequired =input.dataset.required === 'true';
                input.setCustomValidity('');
                if (isRequired && !value) {
                    input.setCustomValidity(this.labels.ECOM_InputErrorMessage);
                    isValid = false;
                    input.reportValidity();
                } else {
                    input.setCustomValidity('');
                }
            });
            //RWPS-2722 start
            let isCompanyValid = true;
            const companyInput = this.template.querySelector('[data-id="shipping-company-name-id"]');
            if (companyInput && !companyInput.value?.trim()) {
                companyInput.setCustomValidity(this.labels.ECOM_InputErrorMessage);
                isCompanyValid = false
                companyInput.reportValidity();
            } else {
                companyInput.setCustomValidity('');
            }
            const stateShippingCombobox = this.template.querySelector('[data-id="shipping-state-id"]');
            const stateBillingCombobox = this.template.querySelector('[data-id="billing-state-id"]');
            const stateInvoiceCombobox = this.template.querySelector('[data-id="state"]');

            const isShippingStateValid = this.validateRequiredInput(stateShippingCombobox, this.labels.ECOM_InputErrorMessage);

            // RWPS-3773 START
            let isBillingStateValid = false;
            if (this.isFetchBillingAddressSelected) {
                isBillingStateValid = true;
            } else {
                isBillingStateValid = this.validateRequiredInput(stateBillingCombobox, this.labels.ECOM_InputErrorMessage);
            }
            // RWPS-3773 END

            let temp = false;
            if(stateInvoiceCombobox)
            {
            const isInvoiceStateValid = this.validateRequiredInput(stateInvoiceCombobox, this.labels.ECOM_InputErrorMessage);
                temp = isShippingStateValid && isBillingStateValid && isInvoiceStateValid;
            }else{
                temp = isShippingStateValid && isBillingStateValid;
            }
            const hasErrors = Object.values(this.fieldErrors).includes(true);
            if (allValid && isValid && !hasErrors && temp && isCompanyValid) { //RWPS-2722 END
                //alert('All form entries look valid. Ready to submit!');
                this.saveAddresses();
            }
            else{
                //alert('Please update the invalid form entries and try again.');
                this.showMessage(
                    'Please check your fields for any error',
                    'error',
                    true
                );
            }
        } else{
            this.showMessage(
            'Your request to add address is already in Progress and can not be updated for now',
            'error',
            true
            );
        }
    }catch(error)//RWPS-5153 start
    {
        processAndLogJSError(error,this.fileName,this.moduleName,'handleFormSubmit')
    }//RWPS-5153 end
    }
    //RWPS-2722 start
    validateRequiredInput(inputCmp, errorMessage) {
    try{//RWPS-5153
        if (inputCmp && (!inputCmp.value || inputCmp.value.trim() === '')) {
            inputCmp.setCustomValidity(errorMessage);
            inputCmp.reportValidity();
            return false;
        } else {
            inputCmp.setCustomValidity('');
            return true;
        }
    }catch(error)//RWPS-5153 start
    {
        processAndLogJSError(error,this.fileName,this.moduleName,'validateRequiredInput')
    }//RWPS-5153 end
    }//RWPS-2722 end
    saveAddresses(){
    try{//RWPS-5153
        this.allAddressToSave = [];

        // Changes done by sathiya on 2024/04/29 for ECOM-1933
        let shippingAddress = JSON.parse(JSON.stringify(this.shippingERPAddress))
        , billingAddress = JSON.parse(JSON.stringify(this.billingERPAddress))
        , invoiceAddress = this.isInvoiceMailingAddress?JSON.parse(JSON.stringify(this.invoiceERPAddress)):{};
        if(billingAddress?.validationFields != null){
            delete billingAddress.validationFields;
            delete billingAddress.isValidatedFields;
        }
        if(shippingAddress?.associatedAddresses != null && shippingAddress?.associatedAddresses != [] && shippingAddress?.associatedAddresses?.length ){
            for(let i = 0; i < shippingAddress?.associatedAddresses.length; i++){
                if(shippingAddress?.associatedAddresses[i]?.validationFields != null){
                    if(shippingAddress?.associatedAddresses[i]?.addressType == 'Payer'){
                        delete shippingAddress?.associatedAddresses[i]?.validationFields;
                        delete shippingAddress?.associatedAddresses[i]?.isValidatedFields;
                    }
                }
            }
        }
        let isInvoiceAssociatedAddr = true;
        if(invoiceAddress?.associatedAddresses == null && billingAddress?.id != null && billingAddress?.id != ''){
            isInvoiceAssociatedAddr = false;
        } else if(invoiceAddress?.associatedAddresses?.length && invoiceAddress?.associatedAddresses.length == 0 && billingAddress?.id != null && billingAddress?.id != ''){
            isInvoiceAssociatedAddr = false;
        }
        shippingAddress.associatedAddresses = [];
        if(shippingAddress?.id != ''){
            billingAddress.associatedAddresses = [shippingAddress];
        }
        if(!isInvoiceAssociatedAddr){
            invoiceAddress.associatedAddresses = [billingAddress];
        }
        this.allAddressToSave.push(shippingAddress);
        this.allAddressToSave.push(billingAddress);
        if(this.isInvoiceMailingAddress){
            this.allAddressToSave.push(invoiceAddress);
        }
        // Changes End
        this.showLoader=true;

        createERPAddresses({
            newErpAddressString : JSON.stringify(this.allAddressToSave),
            attentionRecipient : this.attentionRecipient
        }).then((result) => {
            if(result.success){

                this.billingERPAddress.id=result.payerId;
                this.shippingERPAddress.id=result.shipToId;
                this.invoiceERPAddress.id=result.invoiceAddressId;
                /** Changes by VRa ECOM-1554: Begin */
                // if(this.redirectURL!=''){
                //     window.location.replace(this.redirectURL);
                // }
                const queryParameters = window.location.search;
                const urlParams = new URLSearchParams(queryParameters);
                if(urlParams && urlParams.get('redirectTo') && urlParams.get('redirectTo') != '' && urlParams.get('redirectTo') == 'shop'){
                    this.redirectToCMS();
                }
                /** Changes by VRa ECOM-1554: End */

                this.showMessage(
                    'Your address updated successfully.',
                    'success',
                    true
                );
                window.scrollTo(0, 0);
            }else{
                var message='Faced some issue while registering your address';
                if(result?.ErrorMessage)
                {
                    message=result.ErrorMessage;
                }
                this.showMessage(
                    message,
                    'error',
                    true
                    );
                window.scrollTo(0, 0);
            }
            this.showLoader=false;
        }).catch((error) => {

            this.showLoader=false;
            this.showMessage(
                'Faced an issue while modifying the address.',
                'error',
                true
                );
            window.scrollTo(0, 0);
            processAndLogJSError(error,this.fileName,this.moduleName,'createERPAddresses');//RWPS-5153
        })
    }catch(error){//RWPS-5153 start
        processAndLogJSError(error,this.fileName,this.moduleName,'saveAddresses');
    }//RWPS-5153 end
    }

    // New ERP Address changes end


    //VRa ECOM-1554 Changes Begin
    //Redirect to CMS
    redirectToCMS(){
    try{//RWPS-5153 
        redirectionMap().then(response => {
            if(response && response.success && response.responseData && response.Home && response.responseData != ''){
                let baseUrl = response.Home;
                let redirectUrl = baseUrl;
                redirectUrl = redirectUrl + this.labels.LBL_CMS_SHOP_PAGE + this.labels.LBL_CMS_USER_LOGIN_PARAMETER + response.responseData;
                window.location.replace(redirectUrl);
            }
        })
    }catch(error){//RWPS-5153 start
        processAndLogJSError(error, this.fileName, this.moduleName, 'redirectToCMS');
    } //RWPS-5153 end
    }
    //VRa ECOM-1554 Changes End
//RWPS-3764 start
    handleInvoiceCheckboxKeydown(event) {
    try{//RWPS-5153
        if (event.key === 'Enter' || event.keyCode === 13) {
            event.preventDefault();
            event.target.checked = !event.target.checked;
            this.handleInvoiceCheckboxChange(event);
        }
    }catch(error){//RWPS-5153 start
        processAndLogJSError(error, this.fileName, this.moduleName,'handleInvoiceCheckboxKeydown');
    }//RWPS-5153 end
    }
    handleBillingCheckboxKeydown(event) {
        if (event.key === 'Enter' || event.keyCode === 13) {
            event.preventDefault();
            event.target.checked = !event.target.checked;
            this.handleCheckboxChange(event);
        }
    }//RWPS-3764 end
    //RWPS-3773 start
    handleFetchBillingCheckboxKeydown(event) {
        if (event.key === 'Enter' || event.keyCode === 13) {
            event.preventDefault();
            event.target.checked = !event.target.checked;
            this.handleFetchBillingAddress(event);
        }
    }
    handleFetchBillingAddress(event) {
        this.isFetchBillingAddressSelected = event.target.checked;
    }
    fetchBillAddresses() {
        getChangeAccountData().then(result=>{
            if(result.success){
                this.existingBillingAddress = result?.billAddressList;
                if(this.existingBillingAddress && this.existingBillingAddress.length > 0) {
                    this.billingERPAddress.street = this.existingBillingAddress[0].street;
                    this.billingERPAddress.city = this.existingBillingAddress[0].city;
                    this.billingERPAddress.state = this.existingBillingAddress[0].state;
                    this.billingERPAddress.postalCode = this.existingBillingAddress[0].postalCode;
                    this.billingERPAddress.country = this.existingBillingAddress[0].country;
                    this.billingERPAddress.emailToInvoice = this.existingBillingAddress[0].emailToInvoice;
                    this.billingERPAddress.addressType = 'Payer';
                    this.billingERPAddress.ecomReviewStatus = 'New';
                    this.billingERPAddress.erpAccountName = this.existingBillingAddress[0].erpAccountName;
                    this.billingERPAddress.associatedAddresses = [];
                    this.existingBillingAddress[0].isSelected=true;
                }
                
            }
        }).catch(error=>{
            this.showSpinner=false;
            processAndLogJSError(error, this.fileName, this.moduleName,'getChangeAccountData'); //RWPS-5153
        });
    }
    get isBillAddrExist() {
        return this.existingBillingAddress && this.existingBillingAddress.length > 0;
    }

    handleBillingERPAddress(event) {
    try{//RWPS-5153
        let selectBillId = event.target.value;
        this.existingBillingAddress.forEach(address => {
            if(address.id == selectBillId) {
                this.billingERPAddress.street = address.street;
                this.billingERPAddress.city = address.city;
                this.billingERPAddress.state = address.state;
                this.billingERPAddress.postalCode = address.postalCode;
                this.billingERPAddress.country = address.country;
                this.billingERPAddress.emailToInvoice = address.emailToInvoice;
                this.billingERPAddress.addressType = 'Payer';
                this.billingERPAddress.ecomReviewStatus = 'New'
                this.billingERPAddress.erpAccountName = address.erpAccountName;
                this.billingERPAddress.associatedAddresses = [];
                address.isSelected = true;
            }
            else
                address.isSelected = false;
        });
    }catch(error){//RWPS-5153 start
        processAndLogJSError(error, this.fileName, this.moduleName,'handleBillingERPAddress');
    }//RWPS-5153 end
}
    //RWPS-3773 end
    //RWPS-4087 start
    handleAddressKeyDown(event) {
        if (event.key === 'Enter' || event.keyCode === 13) {
            event.preventDefault();
            if (this.showLoader) {
                return;
            } 
            this.handleSaveAddress();
        }
    }//RWPS-4087 end

}