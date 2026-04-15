import { LightningElement,api,track,wire } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import getUser from '@salesforce/apex/ECOM_UserController.getUser';
// Import Ecom_util for validation methods
import { validateAddressByFields, validateInvoiceMailingAddressByCountry } from 'c/ecom_util';
import getContactInfo from '@salesforce/apex/ECOM_ContactController.getContactInfo';//RWPS-1924
//import getContactDetails from '@salesforce/apex/ECOM_ContactController.getContactDetails';
//import saveAccountAndGetDetails from '@salesforce/apex/ECOM_ContactController.saveAccountAndGetDetails';
//import getMainAccountDetails from '@salesforce/apex/ECOM_ContactController.getMainAccountDetails'
//import saveContact from '@salesforce/apex/ECOM_ContactController.saveContact'
import COUNTRY_CODE from '@salesforce/schema/ContactPointAddress.CountryCode';
import STATE_CODE  from '@salesforce/schema/ContactPointAddress.StateCode';
//import upsertBillingCPA from '@salesforce/apex/ECOM_ContactController.upsertBillingCPA';
//import checkAccountNumber from '@salesforce/apex/ECOM_AccountDetailsController.checkAccountNumber';
import ssrc_ECOM_Theme from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import FORM_FACTOR from '@salesforce/client/formFactor';

import redirectionMap from '@salesforce/apex/ECOM_UserController.getCmsRedirectMapForWebUser';

import getAddressDetails from '@salesforce/apex/ECOM_ContactController.getAddressDetails';
import saveSoldToERPAddress from '@salesforce/apex/ECOM_ContactController.saveSoldToERPAddress';
import addERPAddresses from '@salesforce/apex/ECOM_AccountsController.addERPAddresses';
import updateShiptToAndBillTo from '@salesforce/apex/ECOM_ContactController.updateShiptToAndBillTo';
import getChangeAccountData from '@salesforce/apex/ECOM_ContactController.getChangeAccountData';
import checkSoldToERPAddress from '@salesforce/apex/ECOM_ContactController.checkSoldToERPAddress';

import ECOM_AddAccountNumber from '@salesforce/label/c.ECOM_AddAccountNumber';
import ECOM_ModifyEnteredAddress from '@salesforce/label/c.ECOM_ModifyEnteredAddress';
import ECOM_AddAddress from '@salesforce/label/c.ECOM_AddAddress';
import ECOM_ModifyEnteredAddressUnderReview from '@salesforce/label/c.ECOM_ModifyEnteredAddressUnderReview';
import ECOM_SelectShippingAddress from '@salesforce/label/c.ECOM_SelectShippingAddress';
import ECOM_SelectBillingAddress from '@salesforce/label/c.ECOM_SelectBillingAddress';
import ECOM_ChangesSavedSuccessfully from '@salesforce/label/c.ECOM_ChangesSavedSuccessfully';
import ECOM_EnterAccountNumber from '@salesforce/label/c.ECOM_EnterAccountNumber';
import LBL_CMS_USER_LOGIN_PARAMETER from '@salesforce/label/c.ECOM_CMSUserLoginParameter';//VRa ECOM-2555
import LBL_CMS_BUY_PAGE  from '@salesforce/label/c.ECOM_CMSBuyPage';//VRa ECOM-1554
import LBL_CMS_SHOP_PAGE from '@salesforce/label/c.ECOM_CMSShopPage';//VRa ECOM-3445 Jul 5 2024

import ECOM_BackToAccountList from '@salesforce/label/c.ECOM_BackToAccountList';
import ECOM_AccountNumber from '@salesforce/label/c.ECOM_AccountNumber';
import ECOM_AccountNumberExist from '@salesforce/label/c.ECOM_AccountNumberExist';
import ECOM_ChangeAccountNumber from '@salesforce/label/c.ECOM_ChangeAccountNumber';
import ECOM_ChooseShippingAddress from '@salesforce/label/c.ECOM_ChooseShippingAddress';
import ECOM_AccountNumberStart from '@salesforce/label/c.ECOM_AccountNumberStart';
import ECOM_AccountNumberInfo from '@salesforce/label/c.ECOM_AccountNumberInfo';
import ECOM_Back from '@salesforce/label/c.ECOM_Back';
import ECOM_Submit from '@salesforce/label/c.ECOM_Submit';
import ECOM_RequiredField from '@salesforce/label/c.ECOM_RequiredField';
import ECOM_AccountNotExist from '@salesforce/label/c.ECOM_AccountNotExist';
import ECOM_AddYourAddress from '@salesforce/label/c.ECOM_AddYourAddress';
import ECOM_Addresses from '@salesforce/label/c.ECOM_Addresses';
import ECOM_SelectActiveShippingBillingAddress from '@salesforce/label/c.ECOM_SelectActiveShippingBillingAddress';
import ECOM_ShippingAddress from '@salesforce/label/c.ECOM_ShippingAddress';
import ECOM_BillingAddress from '@salesforce/label/c.ECOM_BillingAddress';
import ECOM_AddShippingInformation from '@salesforce/label/c.ECOM_AddShippingInformation';
import ECOM_ShippingDisplayNote from '@salesforce/label/c.ECOM_ShippingDisplayNote';
import ECOM_Save from '@salesforce/label/c.ECOM_Save';
import ECOM_Close from '@salesforce/label/c.ECOM_Close';
import ECOM_ProvideAddressError1 from '@salesforce/label/c.ECOM_ProvideAddressError1';
import ECOM_ProvideAddressError2 from '@salesforce/label/c.ECOM_ProvideAddressError2';
import ECOM_ProvideAddressError3 from '@salesforce/label/c.ECOM_ProvideAddressError3';
import Ecom_ProvideAccountAddressError from '@salesforce/label/c.Ecom_ProvideAccountAddressError';//RWPS-4776
import ECOM_EuropeVAT  from '@salesforce/label/c.ECOM_EuropeVAT';
// Changes made for ECOM-1939 by sathiya
import ECOM_SelectActiveShippingBillingInvoiceAddress from '@salesforce/label/c.ECOM_SelectActiveShippingBillingInvoiceAddress';
import ECOM_invoiceMailingAddressCountries from '@salesforce/label/c.ECOM_invoiceMailingAddressCountries';
import ECOM_InvoiceMailingAddress from '@salesforce/label/c.ECOM_InvoiceMailingAddress';
// Changes End
import ECOM_BillingDepartmentError from '@salesforce/label/c.ECOM_BillingDepartmentError';//RWPS-1924
import recipientTitle from '@salesforce/label/c.ecom_Attention_Recipient_Title';//RWPS-4824
import ECOM_InputErrorMessage from '@salesforce/label/c.ECOM_InputErrorMessage';//RWPS-4911
import ECOM_ZIPCodeErrorMessage from '@salesforce/label/c.ECOM_ZIPCodeErrorMessage';//RWPS-4911
import LBL_CMS_CART_PAGE from '@salesforce/label/c.ECOM_CartPage';//RWPS-5617,5618

const DEFAULT_RECORDTYPE_ID='012000000000000AAA';


export default class Ecom_accountAddresses extends LightningElement {

    labels = {
        ECOM_BackToAccountList,
        ECOM_AccountNumber,
        ECOM_AccountNumberExist,
        ECOM_ChangeAccountNumber,
        ECOM_ChooseShippingAddress,
        ECOM_AccountNumberStart,
        ECOM_AccountNumberInfo,
        ECOM_Back,
        ECOM_Submit,
        ECOM_RequiredField,
        ECOM_AccountNotExist,
        ECOM_AddYourAddress,
        ECOM_Addresses,
        ECOM_SelectActiveShippingBillingAddress,
        ECOM_ShippingAddress,
        ECOM_BillingAddress,
        ECOM_AddShippingInformation,
        ECOM_ShippingDisplayNote,
        ECOM_Save,
        ECOM_Close,
        ECOM_ProvideAddressError1,
        ECOM_ProvideAddressError2,
        ECOM_ProvideAddressError3,
        Ecom_ProvideAccountAddressError,//RWPS-4776
        ECOM_EuropeVAT,
        ECOM_SelectActiveShippingBillingInvoiceAddress,
        ECOM_invoiceMailingAddressCountries,
        ECOM_InvoiceMailingAddress,
        LBL_CMS_USER_LOGIN_PARAMETER,
        LBL_CMS_BUY_PAGE,
        LBL_CMS_SHOP_PAGE, //VRa ECOM-3445 Jul 5 2024
        ECOM_BillingDepartmentError,//RWPS-1924
        recipientTitle,//RWPS-4824
        ECOM_InputErrorMessage, //RWPS-4911
        ECOM_ZIPCodeErrorMessage,//RWPS-4911
        LBL_CMS_CART_PAGE //RWPS-5617,5618
    };

    //New ERP address changes Started
    @api
    redirectURL='';
    allAddress = [];
    isAccountSelected = false;
   // addAccountNumber='Add new Account Number';
    addAccountNumber=ECOM_AddAccountNumber;
    addressRegistration;
    //when contact registartion is poupulate ST & BT
    // ECOM -1933 variable additions
    billToFieldValidationJSON;
    billToFieldValidationObj;
    // Changes End
    // Changes for ECOM -1939 by sathiya
    @track isInvoiceMailingAddress = false; 
    selectedInvoiceERPAddress;
    selectedInvoiceERPId;
    isInvoiceERPStatusInProgress = false;
    showInvoiceAddModifyText = false;
    invoiceMailingAddress;
    addInvoiceText;
    messageInvoice;
    isInvoiceError = false;
    invoiceErrorType;
    modalAddressType;
    modalAddressLabel;
    // Changes End
    selectedSoldToId;
    addAccountSoldTo=false;
    selectedShipERPId;
    selectedBillToERPId
    selectedAccountId;
    selectedContactId;
    showSelectAccounts=true;
    selectedAccountNumber='';
    showAllAccounts=false;
    isShippingERPAddressSelected = false;
    isERPStatusInProgress=false;
    showAddModifyText=false;
    billingEmailErrorShown = false;//RWPS-1924
    shippingAddress=[];
    _countries = [];
    _countryToStates = {};
    selectedCountry;
    selectedBillingState;
    contactEmail;//RWPS-1924
    showAddAccountNumber=false;
    messageAddBillingCPA='';
    defaultNewERPAddress={
        accountId: "",
        contactId : this.contactId,
        addressType: "Payer",
        city:"",
        country:"",
        ecomReviewStatus: "",
        erpAccountName:"",
        externalId: "",
        id: "",
        postalCode: "",
        state: "",
        street: "",
        fxAddress :''
    }
    @track newBillingERPAddress={};
    makeNewBillToDefault=false;
    selectedShippingERPAddress;
    shippingError=false;
    billingError=false;
    showSpinner=false;
    showBack=true;
    calledFromParent=false;
    showModal=false;
    messageShipping='';
    messageBilling='';
    type="error";
    timeSpan=0;
    disabledSubmit=true;
    enteredAccountNumber='';
    addAccountNumberMessage='';
    showAddAccountNumberError=false;
    @track showProvideAddressError = false; //RWPS-4776
    @track isDisabledAccountError = false;//RWPS-4776
    colsize;
    btnCloseSize;
    billingAddress=[];
    selectedBillingERPAddress= {
        accountId: "",
        contactId : this.contactId,
        addressType: "Payer",
        city:"",
        country:"",
        ecomReviewStatus: "",
        erpAccountName:"",
        externalId: "",
        id: "",
        postalCode: "",
        state: "",
        street: "",
        fxAddress :'',
    };
    images = {
        dashboard:ssrc_ECOM_Theme + '/img/dashboard.png',
        logout:ssrc_ECOM_Theme + '/img/logout.png',
        back:ssrc_ECOM_Theme+'/img/back.png',
        helpimg: ssrc_ECOM_Theme + '/img/checkouttooltip.png',
    }  
    
    device = {
        isMobile : FORM_FACTOR==='Small',
        isDesktop : FORM_FACTOR==='Large' || FORM_FACTOR==='Medium'
    }

    isHidden = false;
    isLoaded = false;

    sidebarCSS='';
    middleSpaceCSS = '';
    mainSectionCSS = '';
    #escapeKeyCallback; // RWPS-4087
    fileName ='ecom_accountAddresses';//RWPS-5153
    moduleName ='Account';//RWPS-5153
    quoteNumber = ''; //RWPS-5618  

    connectedCallback(){
        this.showSpinner=true;
        this.isLoaded = true;

        //RWPS-5618 :Start
        const params = new URLSearchParams(window.location.search);
        const rawQuote = params.get('c__quoteNumber') || params.get('quoteNumber') || '';
        this.quoteNumber = rawQuote ? decodeURIComponent(rawQuote).trim() : '';
        //RWPS-5618 :End

        this.fetchContactInfo();//RWPS-1924
        this.getAddressDetail();
        this.loadBasedOnDeviceType();
        // RWPS-4087 start
        this.#escapeKeyCallback = this.escapeKeyCallback.bind(this);
        document.addEventListener('keydown', this.#escapeKeyCallback);
        
    }
    disconnectedCallback() {
        document.removeEventListener('keydown', this.#escapeKeyCallback);
    }
 
    escapeKeyCallback(event) {
        if (event.key === 'Escape' || event.keyCode === 27) {
            if(this.showModal) {
                this.closeModal(event);
            }
        }
    }// RWPS-4087 end

    @api
    handleAddAccountNumber(event){
        this.showSelectAccounts=false;
        this.showAddAccountNumber=true;
        this.showAllAccounts=false;
        this.isAccountSelected = false;
        if(event=='')
        {
            this.calledFromParent = true;
            this.showBack=false;
        }
        else
        {
            this.showBack=true;     
        }   
    }

    @track popoverClass = 'slds-popover slds-popover_tooltip slds-nubbin_bottom slds-fall-into-ground ecom-popover';
    @track showTooltip = false;

    showPopover(evt){
        
        this.showTooltip = true;
        this.popoverClass = 'slds-popover slds-popover_tooltip slds-nubbin_bottom-left slds-rise-from-ground ecom-popover';
        let buttonOffset = this.template.querySelector(`[data-id="helptextparent"]`);
        //let helpText = this.template.querySelector(`[data-id="helptext"]`);
        this.template.querySelector(`[data-id="helptext"]`).style.top = buttonOffset.getBoundingClientRect().top-1+' px';
        this.template.querySelector(`[data-id="helptext"]`).style.left = buttonOffset.getBoundingClientRect().left+1+' px';

    }
            
    hidePopover(){
           
            this.showTooltip = false;
            this.popoverClass ='slds-popover slds-popover_tooltip slds-nubbin_bottom-left slds-fall-into-ground ecom-popover'
    }
    
    fetchContactInfo(){ /*RWPS-1924*/
        getContactInfo()
        .then(result=>{
            if(result)
            {
                this.contactEmail = result?.Email;
            }
        }).catch(error=>{
             processAndLogJSError(error, this.fileName, this.moduleName, 'getContactInfo');//RWPS-5153
        })
     }

    getAddressDetail(){
        getAddressDetails().then(result=>{
            console.log('getAddressDetail:', result);
            if(result.success){
                this.defaultNewERPAddress.country = result?.countryProvided||'';
                this.newBillingERPAddress = JSON.parse(JSON.stringify(this.defaultNewERPAddress));
                 //move logic to common place
                this.allAddress = result?.address;
                // Changes for ECOM -1939 by sathiya
                this.isInvoiceMailingAddress = validateInvoiceMailingAddressByCountry(this.newBillingERPAddress?.country, this.labels.ECOM_invoiceMailingAddressCountries);
                console.log('isInvoiceMailingAddress::', this.isInvoiceMailingAddress);
                // Changes End
                // ECOM -1933 for new field validations by sathiya
                this.billToFieldValidationJSON = result?.billToValidationFields;
                if(this.billToFieldValidationJSON != null){
                    this.billToFieldValidationObj = JSON.parse(this.billToFieldValidationJSON);
                }
                // Changes End
                this.handleInitialization(true);

                this.attentionRecipient = result?.attentionRecipient;
                this.addressRegistration = result?.addressRegistration;
                if(!this.showAddAccountNumber)
                {
                    this.isAccountSelected = result?.isAccountSelected;
                    this.showAllAccounts = this.isAccountSelected;
                }
                this.showSpinner=false;
            }
        }).catch(error=>{
          
            this.showSpinner=false;
             processAndLogJSError(error, this.fileName, this.moduleName,'getAddressDetails');//RWPS-5153
        });
    }

    setDefaultValues()
    {
        this.selectedShippingERPAddress={};
        this.selectedShipERPId='';
        this.shippingAddress=[];
        this.billingAddress=[];
        this.isShippingERPAddressSelected = false;
        this.selectedBillingERPAddress={};
    }

    saveSoldToAddress(){
        if(this.selectedSoldToId){
            this.showSpinner=true;
            saveSoldToERPAddress({
                accountId : this.selectedAccountId,
                soldToId : this.selectedSoldToId,
                addressRegistration : this.addressRegistration
            }).then(result=>{
                if(result.success){
                    // find next step
                    //move logic to common place
                    if(this.enteredAccountNumber == null || this.enteredAccountNumber == ''){
                        this.setDefaultValues();
                        this.defaultNewERPAddress.country = result?.countryProvided||'';
                        this.newBillingERPAddress = JSON.parse(JSON.stringify(this.defaultNewERPAddress));
                        this.isInvoiceMailingAddress = validateInvoiceMailingAddressByCountry(this.defaultNewERPAddress?.country, this.labels.ECOM_invoiceMailingAddressCountries);
                        this.allAddress = result?.address;
                        for(let i=0;i<this.allAddress?.length;i++){
                            if(this.allAddress[i]?.soldToAddress?.isSelected){
                                this.selectedSoldToId = this.allAddress[i]?.soldToAddress?.id;
                                this.selectedAccountNumber = this.allAddress[i]?.externalId;
                                this.selectedAccountId = this.allAddress[i]?.accountId;
                                this.shippingAddress=this.allAddress[i]?.erpAddresses || [];
                                //RWPS-7270 Start
                                this.handleShippingERPAddress({
                                    target: { value: this.shippingAddress[0].id }
                                });
                                //RWPS-7270 End
                            }
                        }
                        this.addressRegistration = result?.addressRegistration;
                        this.attentionRecipient=result?.attentionRecipient ||'';
                        this.isAccountSelected=true;
                        this.showAllAccounts=true;
                    } else {
                        this.initiateERPAddress(true);
                    }
                    
                    //this.setDefaultValues();
                    //this.getAddressDetail();

                }
                this.showSpinner=false;
            }).catch(error=>{
                this.showSpinner=false;
                processAndLogJSError(error, this.fileName, this.moduleName,'saveSoldToAddress');//RWPS-5153
            })
        }
    }

    handleSoldToChange(event){
        let soldToId =  event.target.dataset.soldToId;
        let accountId = event.target.dataset.accountId;
        var allAddress=JSON.parse(JSON.stringify(this.allAddress))
        for(var i in allAddress)
        {
            if(allAddress[i].soldToAddress.id==soldToId)
            {
                allAddress[i].soldToAddress.isSelected=true;
            }
            else
            {
                allAddress[i].soldToAddress.isSelected=false;
            }
        }
        this.allAddress=allAddress;
        this.selectedSoldToId = soldToId;
        this.selectedAccountId = accountId;
    }

    handleChangeAccountNumber(event){
        // this.showMessage=false;
        // this.accountSelected=false;
        // this.showAllAccounts=false;
        this.showMessage=false;
        this.shippingError=false;
        this.billingError=false;
        this.showSpinner=true;
        getChangeAccountData().then(result=>{
           
            if(result.success){
                //move logic to common place
                this.allAddress = result?.address;
                for(let i=0;i<this.allAddress?.length;i++){
                    if(this.allAddress[i]?.soldToAddress?.isSelected){
                        this.selectedSoldToId = this.allAddress[i]?.soldToAddress?.id;
                        this.selectedAccountNumber = this.allAddress[i]?.externalId;
                        this.selectedAccountId = this.allAddress[i]?.accountId;
                    }
                }
                //this.attentionRecipient = result?.attentionRecipient;
                this.addressRegistration = result?.addressRegistration;
                this.isAccountSelected = false
                this.showAllAccounts = false;
                this.setDefaultValues();
                this.showSpinner=false;
            }
        }).catch(error=>{
            this.showSpinner=false;
             processAndLogJSError(error, this.fileName, this.moduleName,'getChnageAccountData');//RWPS-5153
           
        });
    }
    handleShippingERPAddress(event){
        try{//RWPS-5153
        this.showMessage=false;
        this.shippingError=false;
        let shipErpId = event.target.value;
        var shippingAddress = JSON.parse(JSON.stringify(this.shippingAddress));
        for(var i in shippingAddress){
            if(shippingAddress[i].id==shipErpId){
                shippingAddress[i].isSelected=true;
            } else {
                shippingAddress[i].isSelected=false;
            }
        }
       
        this.shippingAddress=shippingAddress;
        this.selectedShipERPId = shipErpId;
        let shipToAddress = this.allAddress[0]?.erpAddresses.filter((address)=>address.id===shipErpId);
        this.selectedShippingERPAddress=shipToAddress[0];
        this.selectedBillToERPId=null;
        let billToAddress = shipToAddress[0]?.associatedAddresses || [];
        this.billingAddress = billToAddress;
        var isNewPresent=false;
        for(var i=0;i<this.billingAddress?.length;i++){
            // ECOM -1933 for new field validations
            this.billingAddress[i] = validateAddressByFields(this.billingAddress[i], this.billToFieldValidationObj);
            // Changes End
            if(this.billingAddress[i]?.ecomReviewStatus!=='Approved'){
                isNewPresent=true;
              //  this.addBillingText="Modify the entered Address";
                this.addBillingText = ECOM_ModifyEnteredAddress;
                if(this.billingAddress[i]?.isSelected){
                    this.showAddModifyText = true;
                }
                if(this.billingAddress[i]?.ecomReviewStatus==='In Progress'){
                    this.isERPStatusInProgress=true;
                }
                break;                
            }
        }
        if(!isNewPresent){
            this.addBillingText = ECOM_AddAddress;
            this.showAddModifyText = true;
        }
        this.selectedInvoiceERPId=null;
        this.parseMailingAddress();
        /*let invoiceAddress = shipToAddress[0]?.associatedInvoiceAddresses || [];
        this.invoiceMailingAddress = invoiceAddress;
        var isInvoiceNewPresent=false;
        for(var i=0;i<this.invoiceMailingAddress?.length;i++){
            if(this.invoiceMailingAddress[i]?.ecomReviewStatus!=='Approved'){
                isInvoiceNewPresent=true;
                this.addInvoiceText = ECOM_ModifyEnteredAddress;
                if(this.invoiceMailingAddress[i]?.isSelected){
                    this.showInvoiceAddModifyText = true;
                }
                if(this.invoiceMailingAddress[i]?.ecomReviewStatus==='In Progress'){
                    this.isInvoiceERPStatusInProgress=true;
                }
                break;                
            }
        }
        if(!isInvoiceNewPresent){
            this.addInvoiceText = ECOM_AddAddress;
            this.showInvoiceAddModifyText = true;
        }
        */
        this.isShippingERPAddressSelected = true;
    }catch(error){//RWPS-5153 start
         processAndLogJSError(error, this.fileName, this.moduleName,'handleShippingERPAddress');
    }//RWPS-5153 end
        
    }

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
    }catch(error){//RWPS-5153 start
         processAndLogJSError(error, this.fileName, this.moduleName,'handleValidation');
    }//RWPS-5153 end
    }

    handleBillingERPAddress(event){
    try{//RWPS-5153
        this.makeNewBillToDefault=false;
        this.showMessage=false;
        this.billingError=false;
        let billToErpId = event.target.value, addressType = event.currentTarget.dataset.addresstype;
        console.log('addressType::', addressType);
        if(addressType == 'billing'){
            var billingAddress=JSON.parse(JSON.stringify(this.billingAddress));
            for(var i in billingAddress){
                if(billingAddress[i].id==billToErpId){
                    billingAddress[i].isSelected=true;
                } else {
                    billingAddress[i].isSelected=false;
                }
            }
        
            this.billingAddress=billingAddress;

            this.selectedBillToERPId = billToErpId;
            let shipToAddress = this.allAddress[0]?.erpAddresses.filter((address)=>address.id=== this.selectedShipERPId);
            let billToAddress = shipToAddress[0]?.associatedAddresses?.filter((address)=>address.id===billToErpId);
            this.selectedBillingERPAddress = billToAddress[0];
            this.selectedBillingERPAddress.isSelected=true;
            if(billToAddress && billToAddress[0]?.ecomReviewStatus!=='Approved') {
                if(billToAddress[0]?.ecomReviewStatus==='In Progress'){
                    this.isERPStatusInProgress=true;
                }
                this.newBillingERPAddress=this.selectedBillingERPAddress;
                this.addBillingText = ECOM_ModifyEnteredAddress;
                this.showAddModifyText = true;
            }else{
                if(this.addBillingText == ECOM_ModifyEnteredAddress){
                    this.showAddModifyText = false;
                }   
            } 
            this.parseMailingAddress();
        } else {
            let invoiceAddress=JSON.parse(JSON.stringify(this.invoiceMailingAddress));
            for(var i in invoiceAddress){
                if(invoiceAddress[i].id==billToErpId){
                    invoiceAddress[i].isSelected=true;
                } else {
                    invoiceAddress[i].isSelected=false;
                }
            }
        
            this.invoiceMailingAddress=invoiceAddress;

            this.selectedInvoiceERPId = billToErpId;
            let shipToAddress = this.allAddress[0]?.erpAddresses.filter((address)=>address.id=== this.selectedShipERPId);
            let billToAddress = shipToAddress[0].associatedAddresses?.filter((address)=> address.id === this.selectedBillToERPId);
            let invoiceAddresses = billToAddress[0]?.associatedAddresses?.filter((address)=>address.id===billToErpId);
            this.selectedInvoiceERPAddress = invoiceAddresses[0];
            this.selectedInvoiceERPAddress.isSelected=true;
            if(invoiceAddresses && invoiceAddresses[0]?.ecomReviewStatus!=='Approved'){
                if(invoiceAddresses[0]?.ecomReviewStatus==='In Progress'){
                    this.isInvoiceERPStatusInProgress=true;
                }
                this.newBillingERPAddress=this.selectedBillingERPAddress;
                this.addInvoiceText = ECOM_ModifyEnteredAddress;
                this.showInvoiceAddModifyText = true;
            }else{
                if(this.addInvoiceText == ECOM_ModifyEnteredAddress){
                    this.showInvoiceAddModifyText = false;
                }     
            }
        }
    }catch(error){ //RWPS-5153 start
        processAndLogJSError(error,this.fileName, this.moduleName, 'handleBillingERPAddress');
    }//RWPS-5153 end
    }

    addNewBillingERPAddress(event){
    try{//RWPS-5153
        this.invoiceErrorType = '';
        this.messageInvoice = '';
        this.isInvoiceError = false;
        this.timeSpan = 0;
        this.modalAddressType = event?.currentTarget?.dataset?.addresstype;
        this.modalAddressLabel = this.modalAddressType == 'invoice'?this.labels.ECOM_InvoiceMailingAddress:this.labels.ECOM_BillingAddress;
        if(this.shippingAddress != null && this.shippingAddress.length > 0){
            if(this.shippingAddress?.country != null){
                this.defaultNewERPAddress.country = this.shippingAddress?.country;
            }
        }
        this.newBillingERPAddress = JSON.parse(JSON.stringify(this.defaultNewERPAddress));
        if(this.newBillingERPAddress?.country){
            this.selectedCountry = this.countries.find(opt => opt.label === this.newBillingERPAddress.country || opt.value === this.newBillingERPAddress.country).value;
        }
        
        this.newBillingERPAddress.addressType = this.modalAddressType == 'invoice'?'Bill To':'Payer';
        console.log('addressType:: ', this.modalAddressType);
        let isShowAddrModal = true;
        //Changes to add validation to the new Erp Address by Sathiya ECOM-1939
        if(this.modalAddressType == 'billing'){
            for(let i =0; i < this.billingAddress.length; i++){
                if(this.billingAddress[i]?.ecomReviewStatus!=='Approved'){
                    this.newBillingERPAddress = this.billingAddress[i];
                }
            }
            if(this.newBillingERPAddress?.country != null){
                this.newBillingERPAddress = validateAddressByFields(this.newBillingERPAddress, this.billToFieldValidationObj);
                this.newBillingERPAddress.isValidatedFields = this.newBillingERPAddress?.validationFields.length > 0;
            }
        } else {
            if(this.invoiceMailingAddress == null){
                isShowAddrModal = false;
                this.invoiceErrorType = 'error';
                this.messageInvoice = 'Select Bill To before adding or modifying an Invoice Mailing Address';
                this.isInvoiceError = true;
                this.timeSpan = 3000;
            } else {
                for(let i =0; i < this.invoiceMailingAddress.length; i++){
                    if(this.invoiceMailingAddress[i]?.ecomReviewStatus!=='Approved'){
                        this.newBillingERPAddress = this.invoiceMailingAddress[i];
                    }
                }
            }
        }
        if(this.newBillingERPAddress.state!=undefined && this.newBillingERPAddress.state!=''){
            this.selectedBillingState = this.states.find(opt => opt.label === this.newBillingERPAddress.state).value;
        }
        //Changes end
        this.showModal= isShowAddrModal;
    }catch(error)//RWPS-5153 strat
    {
         processAndLogJSError(error, this.fileName, this.moduleName,'addNewBillingERPAddress');
    }//RWPS-5153 end
    }
    saveNewBillingERPAddress(event){
    try{//RWPS-5153
        if(this.isERPStatusInProgress)
        {
            this.showAddressError=true;
            //this.messageAddBillingCPA='You cannot modify your address, as your address is under review.';
            this.messageAddBillingCPA = ECOM_ModifyEnteredAddressUnderReview;
            return;
        }
        if(!this.checkError()){
            this.showAddressError=false;
            this.showSpinner=true;
            //need to check the logic to populate country and state
            if(!this.newBillingERPAddress.country){
                this.newBillingERPAddress.country = this.countries.find(opt => opt.value === this.selectedCountry).label;
            }
            if(!this.newBillingERPAddress.state ){
                this.newBillingERPAddress.state =  this.states.find(opt => opt.value === this.selectedBillingState).label;
            }
            this.newBillingERPAddress.accountId=this.selectedAccountId;
            this.newBillingERPAddress.contactId=this.selectedContactId;
            let currentErpAddress = JSON.parse(JSON.stringify(this.newBillingERPAddress));
            if(currentErpAddress.id==undefined || currentErpAddress.id==''){
                if(currentErpAddress?.addressType == 'Payer'){
                    currentErpAddress.associatedAddresses=[this.selectedShippingERPAddress];
                } else if(currentErpAddress?.addressType == 'Bill To'){
                    let defaultBillingAddress = JSON.parse(JSON.stringify(this.selectedBillingERPAddress));
                    delete defaultBillingAddress.validationFields;
                    delete defaultBillingAddress.isValidatedFields;
                    currentErpAddress.associatedAddresses=[defaultBillingAddress];
                }
                
            }
            // Changes done by sathiya on 2024/04/29 for ECOM-1933
            if(currentErpAddress?.addressType == 'Payer'){
                delete currentErpAddress.validationFields;
                delete currentErpAddress.isValidatedFields;
            }
            if(currentErpAddress?.associatedAddresses != null){
                for(let i = 0; i < currentErpAddress?.associatedAddresses.length; i++){
                    if(currentErpAddress?.associatedAddresses[i]?.associatedAddresses != null){
                        for(let j = 0; j < currentErpAddress?.associatedAddresses[i]?.associatedAddresses.length; j++){
                            delete currentErpAddress?.associatedAddresses[i]?.associatedAddresses[j].validationFields;
                            delete currentErpAddress?.associatedAddresses[i]?.associatedAddresses[j].isValidatedFields;
                        }
                    }
                }
            }
            // Changes End
            addERPAddresses({
                jsonAddresses : JSON.stringify([currentErpAddress])
            }).then(result=>{
                console.log('addERPAddresses:: ', result);
                if(result.success){
                    this.showModal=false;
                    this.makeNewBillToDefault=true;
                    //this.setDefaultValues();
                    //this.getAddressDetail();
                    if(!this.enteredAccountNumber){
                        this.enteredAccountNumber = this.selectedShippingERPAddress?.externalId;
                    }
                    this.initiateERPAddress(false);
                    this.showAddressError=false;
                }
                else{
                    this.showAddressError=true;
                    this.messageAddBillingCPA=result.ErrorMessage;
                    this.showSpinner=false;
                }
            }).catch(error=>{
                this.showSpinner=false;
                processAndLogJSError(error, this.fileName, this.moduleName,'addERPAddresses');//RWPS-5153
               
            });
        } else{
            this.addressError='Please check all the required fields.';
            this.showAddressError=true;
        }
    }catch(error)//RWPS-5153 start
    {
         processAndLogJSError(error, this.fileName, this.moduleName,'saveNewBillingERPAddress');
    }//RWPS-5153 end
        //this.billingCPA.Street=this.billingAddress1+' '+this.billingAddress2;
    }

    checkError(){
    try{//RWPS-5153
        //RWPS-1924
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

        if (allValid) {
            return false;
        }else{
            return true;
        }
    }catch(error)//RWPS-5153 start
    {   processAndLogJSError(error, this.fileName, this.moduleName,'checkError');
    }    //RWPS-5153 end
    }
    handleBillingChange(event) {
        if (event.target.value.length>0 && event.target.value[0]==' ') {
            event.target.value = event.target.value.trim();
        }
        this.newBillingERPAddress.addressType = this.modalAddressType == 'billing'?'Payer':'Bill To';
        if(event.target.dataset.id === 'billing-company-name-id'){
            this.newBillingERPAddress.erpAccountName =  event.target.value;
        }
        if(event.target.dataset.id === 'billing-country-id'){
            this.selectedCountry = event.target.value;
            this.newBillingERPAddress.country =  this.countries.find(opt => opt.value === event.detail.value).label;
        }
        if(event.target.dataset.id === 'billing-address-line-1'){
            this.newBillingERPAddress.street =  event.target.value ;
        }
        if(event.target.dataset.id === 'billing-city-id'){
            this.newBillingERPAddress.city =  event.target.value ;
        }
        if(event.target.dataset.id === 'billing-state-id'){
            this.selectedBillingState = event.target.value;
            this.newBillingERPAddress.state =  this.states.find(opt => opt.value === event.target.value).label;
        }
        if(event.target.dataset.id === 'billing-zip-id'){
            //RWPS-4911 Start
            const value = event.target.value.trim();
            const zipCodeRegex = /^[a-zA-Z0-9 -]+$/;

            if (!value) {
                event.target.setCustomValidity(this.labels.ECOM_InputErrorMessage);
            } else if (!zipCodeRegex.test(value)) {
                event.target.setCustomValidity(this.labels.ECOM_ZIPCodeErrorMessage);
            } else {
                event.target.setCustomValidity('');
                this.newBillingERPAddress.postalCode = event.target.value;
            }
            
            event.target.reportValidity();
            //RWPS-4911 End
        }
        if(event.target.dataset.id === 'billing-phone-id'){
            //this.selectedBillingERPAddress.phoneNumber =  event.target.value;
        }
        //if(event.target.dataset.id === 'billing-extn-id'){
            //this.selectedBillingERPAddress.extn =  event.target.value;
        //}
        if(event.target.dataset.id === 'account-number-id'){
            this.enteredAccountNumber = event.target.value;
            if(this.enteredAccountNumber.length>0){
                this.disabledSubmit = false;
            }else{
                this.disabledSubmit = true;
            }
        }
        // Changes done by sathiya on 2024/04/29 for ECOM-1933
        if(event?.target?.dataset?.validate != null){
            let fieldId = event?.target?.dataset?.id, fieldValue = event.target.value.trim();
            if(fieldId == 'invoiceCustId'){
                if(this.newBillingERPAddress?.validationFields){
                    for(let i=0; i<this.newBillingERPAddress?.validationFields.length; i++){
                        if(this.newBillingERPAddress?.validationFields[i].fieldName == 'emailToInvoice'){
                            this.newBillingERPAddress.validationFields[i].isRequired = fieldValue == ''?true:false;
                        }
                    }
                }
            }
            this.newBillingERPAddress[fieldId] = fieldValue;
        }
        // Changes End
    }
    //call server method to update data on contact
    handleUpdateShippingAndBillingAddress(event){
    try{//RWPS-5153
        if(!this.selectedShipERPId){
            this.shippingError=true;
            //this.messageShipping="Please select a shipping address.";
            this.messageShipping = ECOM_SelectShippingAddress;
            return;
        }else{
            this.shippingError=false;
            this.messageShipping='';
        }
        if(!this.selectedBillToERPId){
            this.billingError=true;
           // this.messageBilling="Please select a billing address.";
            this.messageBilling = ECOM_SelectBillingAddress;
            return;
        }else{
            this.billingError=false;
            this.messageBilling='';
        }

        // if(this.shippingError || this.billingError){
        //     this.messageAccount='';
        //     this.showMessage=false;
        //     return;
        // }

        if(this.attentionRecipient!=undefined && this.attentionRecipient!=''){
            this.attentionRecipient = this.attentionRecipient.trim();
        }else{
            this.attentionRecipient ='';
        }
        this.showSpinner=true;
        
        updateShiptToAndBillTo({
            contactId : this.selectedBillingERPAddress.contactId, 
            soldToId : this.selectedSoldToId,
            shiptToId:this.selectedShipERPId,
            billToId:this.selectedBillToERPId,
            invoiceErpId: this.selectedInvoiceERPId,
            addressRegistration:this.addressRegistration,
            attentionRecipient:this.attentionRecipient
        }).then(result=>{
            /** VRa changes for ECOM-1554: begin */
            const queryParameters = window.location.search;
            const urlParams = new URLSearchParams(queryParameters);
            if(urlParams && urlParams.get('redirectTo') && urlParams.get('redirectTo') != '' && urlParams.get('redirectTo') == 'shop'){
                    this.redirectToCMS();
            //     }
            // if(this.redirectURL!=''){
            //     window.location.replace(this.redirectURL);
            /** VRa changes for ECOM-1554: End */            
            } else{
                //this.messageAccount='Changes successfully saved';
                this.messageAccount = ECOM_ChangesSavedSuccessfully;
                this.showMessage=true;
                if(window.location.href.includes('/dashboard?accountEdit'))
                {
                    window.location.reload();
                }
                else
                {
                    window.location.replace('/dashboard?accountEdit');
                }

                //this.getAddressDetail();
            }
        }).catch(error=>{
            this.showSpinner=false;
             processAndLogJSError(error, this.fileName, this.moduleName,'updateShiptToAndBillTo');//RWPS-5153
        });
    }catch(error)//RWPS-5153 start
    {
        processAndLogJSError(error, this.fileName, this.moduleName,'handleUpdateShippingAndBillingAddress');
    }//RWPS-5153 end
    }

    navigateToAddAddressPage(event){
        this.customEvent('addAddress');
    }

    goBackToAccounts(event){
    try{
        const queryParameters = window.location.search;
        const urlParams = new URLSearchParams(queryParameters);
        const addressStatus = urlParams.get('addressStatus');
        const redirectTo = urlParams.get('redirectTo');
        console.log('queryParameters:: ', queryParameters, 'urlParams::', urlParams, 'addressStatus::', addressStatus, 'redirectTo::', redirectTo);//Remove after DEV
        // if(redirectTo && redirectTo == 'shop' ){
        //     this.handleAddAccountNumber();
        // } else {
            this.customEvent('showAddressTab');
        //}
    }catch(error){ //RWPS-5153 start
         processAndLogJSError(error, this.fileName, this.moduleName, 'goBackToAccounts');
    }//RWPS-5153 end
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
           
        }else if (error){
            processAndLogJSError(error, this.fileName, this.moduleName, 'wiredStates');//RWPS-5153
        }
    }

    get countries() {
        return this._countries;
    }

    get states() {
        return this._countryToStates[this.selectedCountry] || [];
    }

    handleAddAddressSubmit(event) {
        this.showAddAccountNumberError=false;
        if(this.enteredAccountNumber==''){
            this.showAddAccountNumberError=true;
            //this.addAccountNumberMessage='Please enter Account Number';
            this.addAccountNumberMessage = ECOM_EnterAccountNumber;
            return;
        }
        this.makeNewBillToDefault=false;
        this.showSpinner=true;
        this.initiateERPAddress(true);
    }

    initiateERPAddress(isNew){
        checkSoldToERPAddress({
            soldToSapNumber : this.enteredAccountNumber,
            addressRegistration : this.addressRegistration
        }).then(result=>{
            console.log('acc new result:', result);
            if(result.success){
                if(this.calledFromParent){
                    this.calledFromParent=false;
                }
                /*this.allAddress = result?.address;
                this.handleInitialization();

                this.addressRegistration = result?.addressRegistration;
                this.attentionRecipient=result?.attentionRecipient ||'';
                this.showAddAccountNumber=false;
                this.isAccountSelected=true;
                this.showAllAccounts=true;
                this.showSelectAccounts=true;
                this.enteredAccountNumber='';*/
                if(isNew){
                    this.showAddAccountNumber=false;
                    this.isAccountSelected=true;
                    this.showAllAccounts=true;
                    this.showSelectAccounts=true;              
                    this.setDefaultValues();
                }

                this.defaultNewERPAddress.country = result?.countryProvided||'';
                this.newBillingERPAddress = JSON.parse(JSON.stringify(this.defaultNewERPAddress));
                this.allAddress = result?.address;
                this.selectedSoldToId=result?.soldToId;
                this.addAccountSoldTo=true;
                // Changes for ECOM -1939 by sathiya
                this.isInvoiceMailingAddress = validateInvoiceMailingAddressByCountry(this.newBillingERPAddress?.country, this.labels.ECOM_invoiceMailingAddressCountries);
                console.log('isInvoiceMailingAddress::', this.isInvoiceMailingAddress);
                // Changes End
                // ECOM -1933 for new field validations by sathiya
                this.billToFieldValidationJSON = result?.billToValidationFields;
                if(this.billToFieldValidationJSON != null){
                    this.billToFieldValidationObj = JSON.parse(this.billToFieldValidationJSON);
                }
                // Changes End
                this.handleInitialization(isNew);

                this.attentionRecipient = result?.attentionRecipient;
                this.addressRegistration = result?.addressRegistration;
                this.showSpinner=false;
            }else{
                this.showProvideAddressError=true;
                //RWPS-4776 Start
                if (result.isDisabledAccount) {
                    this.isDisabledAccountError = true; 
                }
                else{
                    this.isDisabledAccountError = false;
                }
                //RWPS-4776 END
                this.showSpinner=false;
            }
        }).catch(error=>{
            this.showSpinner=false;
            processAndLogJSError(error, this.fileName, this.moduleName, 'initateERPAddress');//RWPS-5153
        });
    }

    closeMessageBox(){
        this.showProvideAddressError = false;
    }

    handleInitialization(isNew)
    {
        for(let i=0;i<this.allAddress?.length;i++){
            if(this.allAddress[i]?.soldToAddress?.isSelected || (this.addAccountSoldTo && this.selectedSoldToId==this.allAddress[i]?.soldToAddress?.id)){
                this.selectedSoldToId = this.allAddress[i]?.soldToAddress?.id;
                this.selectedAccountNumber = this.allAddress[i]?.externalId;
                this.selectedAccountId = this.allAddress[i]?.accountId;
                this.selectedContactId= this.allAddress[i]?.contactId;

                this.shippingAddress=this.allAddress[i]?.erpAddresses || [];
                let isNewPresent=false;
                for(let j=0;j<this.shippingAddress?.length;j++){
                    if(this.makeNewBillToDefault){
                        if(this.selectedShippingERPAddress?.id==this.shippingAddress[j]?.id){
                            this.shippingAddress[j].isSelected=true;
                        }
                    }
                    if(this.shippingAddress[j]?.isSelected){
                        this.selectedShipERPId = this.shippingAddress[j]?.id;
                        this.selectedShippingERPAddress=this.shippingAddress[j];
                        let billToAddress = this.shippingAddress[j]?.associatedAddresses || [];
                        let defaultBillToAddress = billToAddress.filter(function(addr){
                            return addr.isSelected === true;
                        });
                        let defaultBillTo = defaultBillToAddress.length > 0?[defaultBillToAddress[0]]:billToAddress.length > 0?[billToAddress[0]]:[];
                        for(let k=0;k<billToAddress?.length;k++){
                            billToAddress[k] = validateAddressByFields(billToAddress[k], this.billToFieldValidationObj);
                            billToAddress[k].isValidatedFields = billToAddress[k].validationFields.length > 0;
                            if(this.makeNewBillToDefault && this.modalAddressType == 'billing'){
                                if(billToAddress[k]?.ecomReviewStatus!='Approved'){
                                    billToAddress[k].isSelected = true;
                                } else {
                                    billToAddress[k].isSelected = false;
                                }
                            } else {
                                if(this.selectedBillToERPId != null && this.selectedBillToERPId != ''){
                                    if(billToAddress[k]?.id == this.selectedBillToERPId){
                                        billToAddress[k].isSelected = true;
                                    } else {
                                        billToAddress[k].isSelected = false;
                                    }
                                } else {
                                    if(defaultBillTo.length > 0){
                                        if(defaultBillTo[0].id == billToAddress[k]?.id){
                                            billToAddress[k].isSelected = true;
                                        } else {
                                            billToAddress[k].isSelected = false;
                                        }
                                    }
                                }
                            }
                            if(billToAddress[k]?.isSelected){
                                this.selectedBillingERPAddress = billToAddress[k];
                                this.selectedBillToERPId= billToAddress[k]?.id||'';
                            }
                            
                            if(billToAddress[k]?.ecomReviewStatus!=='Approved'){
                                if(billToAddress[k]?.ecomReviewStatus==='In Progress'){
                                    this.isERPStatusInProgress=true;
                                }
                                if(billToAddress[k]?.isSelected){
                                    this.showAddModifyText = true;
                                }
                                this.newBillingERPAddress=billToAddress[k];
                                isNewPresent=true;
                            }
                        }
                        this.billingAddress = billToAddress;
                        // Parse Invoice Mailing Address
                        this.parseMailingAddress();
                        this.isShippingERPAddressSelected = true;
                    }
                }
                if(isNewPresent){
                    this.addBillingText = ECOM_ModifyEnteredAddress;
                } else {
                    this.addBillingText = ECOM_AddAddress;
                    this.showAddModifyText = true;
                }
                this.addAccountSoldTo=false;
                this.makeNewBillToDefault = false;
            }
        }
    }
    // Changes done for ECOM-1939 by sathiya 
    parseMailingAddress(){
        let isNewInvoicePresent = false;
        if(this.isInvoiceMailingAddress){
            for(let k = 0; k < this.billingAddress.length; k++){
                if(this.selectedBillToERPId != null && this.selectedBillToERPId != '' && 
                this.selectedBillToERPId == this.billingAddress[k].id){
                    let invoiceAddress = this.billingAddress[k]?.associatedAddresses || [];
                    let defaultInvoiceAddress = invoiceAddress.filter(function(addr){
                        return addr.isSelected === true;
                    });
                    let defaulInvoiceAddr = defaultInvoiceAddress.length > 0?[defaultInvoiceAddress[0]]:invoiceAddress.length > 0?[invoiceAddress[0]]:[];
                    for(let l=0;l<invoiceAddress?.length;l++){
                        if(this.makeNewBillToDefault && this.modalAddressType == 'invoice'){
                            if(invoiceAddress[l]?.ecomReviewStatus!=='Approved'){
                                invoiceAddress[l].isSelected = true;
                            } else {
                                invoiceAddress[l].isSelected = false;
                            }
                        } else {
                            if(this.selectedInvoiceERPAddress?.id != null && this.selectedInvoiceERPAddress?.id != ''){
                                if(invoiceAddress[l]?.id == this.selectedInvoiceERPAddress?.id){
                                    invoiceAddress[l].isSelected = true;
                                } else {
                                    invoiceAddress[l].isSelected = false;
                                }
                            } else {
                                if(defaulInvoiceAddr.length > 0){
                                    if(defaulInvoiceAddr[0].id == invoiceAddress[l]?.id){
                                        invoiceAddress[l].isSelected = true;
                                    } else {
                                        invoiceAddress[l].isSelected = false;
                                    }
                                }
                            }
                        }
                        /*if(this.makeNewBillToDefault){
                            if(invoiceAddress[l]?.ecomReviewStatus!=='Approved'){
                                invoiceAddress[l].isSelected=true;
                            } else {
                                invoiceAddress[l].isSelected=false;
                            }
                        }*/
                        if(this.billingAddress[k]?.isSelected && invoiceAddress[l]?.isSelected){
                            this.selectedInvoiceERPAddress = invoiceAddress[l];
                            this.selectedInvoiceERPId= invoiceAddress[l]?.id||'';
                        }
                        if(invoiceAddress[l]?.id == this.selectedInvoiceERPId){
                            if(invoiceAddress[l]?.ecomReviewStatus!=='Approved'){
                                if(invoiceAddress[l]?.ecomReviewStatus==='In Progress'){
                                    this.isInvoiceERPStatusInProgress=true;
                                }
                                if(invoiceAddress[l]?.isSelected){
                                    this.showInvoiceAddModifyText = true;
                                } else {
                                    this.showInvoiceAddModifyText = false;
                                }
                            }
                        }
                        if(invoiceAddress[l]?.ecomReviewStatus!=='Approved'){
                            this.newBillingERPAddress=invoiceAddress[l];
                            isNewInvoicePresent=true;
                        }
                    }
                    this.invoiceMailingAddress = invoiceAddress;
                }
            }
            if(isNewInvoicePresent){
                this.addInvoiceText = ECOM_ModifyEnteredAddress;
            } else {
                this.addInvoiceText = ECOM_AddAddress;
                this.showInvoiceAddModifyText = true;
            }
        }
    }
    // Changes End
    closeModal(event)
    {
        this.showModal=false; 
    }

    handleAddAddressBack(event)
    {
        this.showSelectAccounts=true;
        this.showAddAccountNumber=false;
        this.enteredAccountNumber='';
        this.showAddAccountNumberError=false;
        this.showProvideAddressError=false;
    }

    handleRecipientValue(event)
    {
        this.showMessage=false;
        if(event.target.value!=null && event.target.value!=undefined)
        {
            this.attentionRecipient=event.target.value;
        }
        else
        {
            this.attentionRecipient='';
        }
        
    }

    popoverClass = 'slds-popover slds-popover_tooltip slds-nubbin_bottom slds-fall-into-ground ecom-popover';
    showPopover(){
          this.showTooltip = true;
          this.popoverClass = 'slds-popover slds-popover_tooltip slds-nubbin_bottom slds-rise-from-ground ecom-popover';
        }
            
    hidePopover(){
        this.showTooltip = false;
        this.popoverClass ='slds-popover slds-popover_tooltip slds-nubbin_bottom-left slds-fall-into-ground ecom-popover'
    }

    loadBasedOnDeviceType() {
        if (this.device.isMobile) {
            this.colsize = "slds-col slds-large-size_6-of-12 slds-medium-size_6-of-12 slds-small-size_6-of-12 slds-size_6-of-12";
            this.btnCloseSize= "slds-button slds-button_icon ecom-msgbox-closebtn-mobile close-btn";
        } else {
            //Tab UI fix - Gaurang - 17 July 2024
            var width = (window.innerWidth > 0) ? window.innerWidth : screen.width;
            if(FORM_FACTOR==='Medium' || (width==1025)){
                this.sidebarCSS = 'slds-col slds-large-size_12-of-12 slds-medium-size_12-of-12 slds-small-size_1-of-1 slds-size_1-of-1';
                this.middleSpaceCSS = 'doNotDisplay';
                this.mainSectionCSS = 'slds-col slds-large-size_12-of-12 slds-medium-size_12-of-12 slds-small-size_1-of-1 slds-size_12-of-12';
            }
            else{
                this.sidebarCSS = 'slds-col slds-large-size_3-of-12 slds-medium-size_3-of-12 slds-small-size_1-of-1 slds-size_1-of-1';
                this.middleSpaceCSS = 'slds-large-size_1-of-12 slds-medium-size_1-of-12';
                this.mainSectionCSS = 'slds-col slds-large-size_8-of-12 slds-medium-size_8-of-12 slds-small-size_1-of-1 slds-size_12-of-12';
            }
            this.colsize = "slds-col slds-large-size_11-of-12 slds-medium-size_7-of-12 slds-small-size_1-of-1 slds-size_1-of-1";
            this.btnCloseSize= "slds-button slds-button_icon ecom-msgbox-closebtn close-btn";
        }
    }

    //New ERP address changes Started

    accountSelected=false;
    contact={};
    mainSelectedAccount='';
    selectedShipping='';
    selectedBilling='';
    selectedInvoicing='';
    showShipping=false;
    showBilling=false;
    showInvoicing=false;
    availableMainAccounts=[];
    availableShippingAccounts=[];
    availableBillingAccounts=[];
    availableInvoicingAccounts=[];
    mainType='success';
    messageAccount='';
    showMessage=false;
    billingCpaPresent=false;
    shippingCpaPresent=false;
    addBillingText='';
    billingCPA={};
    billingAddress1='';
    billingAddress2='';
    showBillingCpaError=false;
    billingCpaList=[];
    shippingCpaList=[];
    isCpaStatusNew=true;


    //VRa ECOM-1554 Changes Begin
    //Redirect to CMS
    redirectToCMS(){
        redirectionMap().then(response => {
            console.log('redirectionMap.response:: ', response);//Remove after DEV
            if(response && response.success && response.responseData && response.Home && response.responseData != ''){
                let baseUrl = response.Home;
                let redirectUrl = baseUrl;

                // RWPS-5618 START
                if(this.quoteNumber) {
                    const basePath = `/${this.labels.LBL_CMS_CART_PAGE.replace(/^\/+/, '')}`;
                    const cartUrl = `${basePath}?quoteAction=apply`+ `&quoteNumber=${encodeURIComponent(String(this.quoteNumber))}`;
                    redirectUrl = `${window.location.origin}${cartUrl}`; // RWPS-5618 END
                } else {
                    redirectUrl = redirectUrl + this.labels.LBL_CMS_SHOP_PAGE + this.labels.LBL_CMS_USER_LOGIN_PARAMETER + response.responseData;//VRa ECOM-3445 Jul 5 2024
                }

                // redirectUrl = redirectUrl + this.labels.LBL_CMS_BUY_PAGE + this.labels.LBL_CMS_USER_LOGIN_PARAMETER + response.responseData; //VRa ECOM-3445 Jul 5 2024
                window.location.replace(redirectUrl);
            } 
        }).catch(error=>{//RWPS-5153 start
            processAndLogJSError(error, this.fileName, this.moduleName, 'redirectionMap');//RWPS-5153
        });//RWPS-5153 end
    }
    //VRa ECOM-1554 Changes End
    //RWPS-3764 start
    handleAddAccountNumberKeydown(event) {
        if (event.key === 'Enter' || event.keyCode === 13) {
          event.preventDefault(); 
          if(this.showSpinner)//RWPS-4087 start
          {
            return;
          }//RWPS-4087 end
          this.handleAddAccountNumber(event); 
        }
      }
      handleAddAddressKeydown(event) {
        if (event.key === 'Enter' || event.keyCode === 13) {
          event.preventDefault(); 
          if(this.showSpinner)//RWPS-4087 start
          {
              return;
          }//RWPS-4087 end
          this.addNewBillingERPAddress(event); 
        }
      }
      
    //RWPS-3764 end

}