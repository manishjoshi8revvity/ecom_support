import { LightningElement, api, wire, track } from 'lwc';
// Import Ecom_util for validation methods
import { validateAddressByFields, validateInvoiceMailingAddressByCountry } from 'c/ecom_util';
//import getAccountDetails from '@salesforce/apex/ECOM_DashboardController.getRelatedAccountOfCurrentUser';
// import makeAccountActive  from '@salesforce/apex/ECOM_DashboardController.updateAccountToActive';
import makeAccountActive  from '@salesforce/apex/ECOM_AccountsController.updateContactandCart';
import getContactInfo from '@salesforce/apex/ECOM_ContactController.getContactInfo'; //RWPS-1924
//import updateBillingOnContact from '@salesforce/apex/ECOM_DashboardController.saveDefaultBillingAddress';
//import getBillingOfUser from '@salesforce/apex/ECOM_DashboardController.getCurrentBillingAddresses';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import COUNTRY_CODE from '@salesforce/schema/ContactPointAddress.CountryCode';
import STATE_CODE  from '@salesforce/schema/ContactPointAddress.StateCode';
//import upsertBillingCPA from '@salesforce/apex/ECOM_DashboardController.addOrModifyCPAAddress';
//import getCPAById from '@salesforce/apex/ECOM_DashboardController.getCPAByRecId';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { isCmsResource, resolve } from 'experience/resourceResolver';
import fetchAccountDetails from '@salesforce/apex/ECOM_AccountsController.fetchAccountDetails';
import fetchERPAddressDetails from '@salesforce/apex/ECOM_AccountsController.fetchERPAddressDetails';
import addERPAddresses from '@salesforce/apex/ECOM_AccountsController.addERPAddresses';
import sres_ECOM_CartIcons from '@salesforce/resourceUrl/ssrc_ECOM_Theme';

import ECOM_BillingAddressSavedSuccess from '@salesforce/label/c.ECOM_BillingAddressSavedSuccess';
import ECOM_Account from '@salesforce/label/c.ECOM_Account';
import ECOM_ActivatedSuccessfully from '@salesforce/label/c.ECOM_ActivatedSuccessfully';
import ECOM_Accounts from '@salesforce/label/c.ECOM_Accounts';
import ECOM_Addresses from '@salesforce/label/c.ECOM_Addresses';
import ECOM_AddAccountOrAddress from '@salesforce/label/c.ECOM_AddAccountOrAddress';
import ECOM_AccountNumber from '@salesforce/label/c.ECOM_AccountNumber';
import ECOM_ActiveAccount from '@salesforce/label/c.ECOM_ActiveAccount';
import ECOM_MakeActiveAccount from '@salesforce/label/c.ECOM_MakeActiveAccount';
import ECOM_AccountName from '@salesforce/label/c.ECOM_AccountName';
import ECOM_ShippingAddress from '@salesforce/label/c.ECOM_ShippingAddress';
import ECOM_BillingAddress from '@salesforce/label/c.ECOM_BillingAddress';
import Ecom_Cancel_close from '@salesforce/label/c.Ecom_Cancel_close';
import Ecom_Change from '@salesforce/label/c.Ecom_Change';
import ECOM_AddBillingAddress from '@salesforce/label/c.ECOM_AddBillingAddress';
import ECOM_ModifyAddress from '@salesforce/label/c.ECOM_ModifyAddress';
import ECOM_Cancel from '@salesforce/label/c.ECOM_Cancel';
import ECOM_Save from '@salesforce/label/c.ECOM_Save';
import ECOM_Apply from '@salesforce/label/c.ECOM_Apply';
import ECOM_InvoiceMailingAddress from '@salesforce/label/c.ECOM_InvoiceMailingAddress';
import ECOM_AddInvoiceMailingAddress from '@salesforce/label/c.ECOM_AddInvoiceMailingAddress';
import ECOM_invoiceMailingAddressCountries from '@salesforce/label/c.ECOM_invoiceMailingAddressCountries';
import ECOM_BillingDepartmentError from '@salesforce/label/c.ECOM_BillingDepartmentError'; //RWPS-1924
import ECOM_InputErrorMessage from '@salesforce/label/c.ECOM_InputErrorMessage';//RWPS-4911
import ECOM_ZIPCodeErrorMessage from '@salesforce/label/c.ECOM_ZIPCodeErrorMessage'; //RWPS-3813
import {processAndLogJSError} from 'c/ecom_util'; // RWPS-5153

const DEFAULT_RECORDTYPE_ID='012000000000000AAA';

export default class Ecom_accountDashboardEdit extends LightningElement {
    labels = {
        ECOM_Accounts,
        ECOM_Addresses,
        ECOM_AddAccountOrAddress,
        ECOM_AccountNumber,
        ECOM_ActiveAccount,
        ECOM_MakeActiveAccount,
        ECOM_AccountName,
        ECOM_ShippingAddress,
        ECOM_BillingAddress,
        Ecom_Cancel_close,
        Ecom_Change,
        ECOM_AddBillingAddress,
        ECOM_ModifyAddress,
        ECOM_Cancel,
        ECOM_Save,
        ECOM_Apply,
        ECOM_InvoiceMailingAddress,
        ECOM_AddInvoiceMailingAddress,
        ECOM_invoiceMailingAddressCountries,
        ECOM_BillingDepartmentError, //RWPS-1924
        ECOM_ZIPCodeErrorMessage, //RWPS-3813
        ECOM_InputErrorMessage,//RWPS-4911
    };

    accountDetailsList;
    accountDetailsListToDisplay;
    allAccountDetailsList=[];
    isLaodMoreEnabled = false;
    totalAccountDetails = 0;
    @api isAccountEdit = false;
    //defaultListSize = 2;
    //nextLoadCount = 0;
    //isLoadMore = false;
    isShowBillingAddress = false;
    @api contactId;
    @api accountId;
    @api contactName;
    updatedActiveAccountNumber;
    isAccountUpdated = false;
    currentBillingAddresses;
    selectedBillingAccount;
    isAddAddressClicked = false;
    showSpinner = false;
    billingAddresses;
    addressError='';
    type;
    showAddressError;
    timeSpan;
    contactEmail; //RWPS-1924
    billingEmailErrorShown = false;
    _countries = [];
    _countryToStates = {};
    // hasCPA = false;
    // isModifyCPA = false;
    billingCPA={};
    selectedCountry;
    selectedBillingState;
    enteredAccountNumber;
    // device = {
    //     isMobile : FORM_FACTOR==='Small',
    //     isDesktop : FORM_FACTOR==='Large',
    //     isTablet :FORM_FACTOR==='Medium'
    // }

    // ECOM -1933 variable additions
    billToFieldValidationJSON;
    billToFieldValidationObj;
    // Changes End
    // ECOM -1939 variable additions
    modalAddressLabel;
    modalNewAddressLabel;
    modalAddressType;
    // Changes End
    //RWPS-2372 - Start
    newOrEditERPAddressClone = {}; //RWPS-2372
    isAlreadyModalOpen = false;
    availablesBilTosClone = [];
    shipToAddressWithActivePayerClone = [];
    lastFocusedElement;//RWPS-4087
    //RWPS-2372 - End
    modalScreenClass = 'slds-modal__content ecom-p-left-right-92';

    sidebarCSS='';
    middleSpaceCSS = '';
    mainSectionCSS = '';
    fileName ='ecom_accountDashboardEdit';//RWPS-5153
    moduleName ='Account';//RWPS-5153

    images = {
        radIcon:sres_ECOM_CartIcons + '/img/radIcon.svg'
    }

    get currentModalClass(){
        return this.device.isDesktop ? 'slds-modal__content ecom-p-left-right-92' : 'slds-modal__content ecom-p-left-right-16';
    }

    get currentModalSectionClass(){
        return this.device.isDesktop ? 'slds-modal slds-fade-in-open slds-modal_small' : 'slds-modal slds-fade-in-open slds-modal_full';
    }

    #escapeKeyCallback; // RWPS-4087
    connectedCallback(){
        this.isAccountEdit = false;
        //this.getAccountEditDetails();
       // this.fetchAccountDetail();
       this.fetchContactInfo();
        this.fetchERPAddressDetail();
        this.hideAddressEditEvent();
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
            if(this.showAddBillingModal) {
                this.closeAddBillingModal();
            }
            if(this.isShowBillingAddress) {
                this.hideBillingAddressModal();//RWPS-4087
            }
        }
    } // RWPS-4087 end

    loadBasedOnDeviceType(){
        //Tab UI fix - Gaurang - 17 July 2024
        var width = (window.innerWidth > 0) ? window.innerWidth : screen.width;
        if(FORM_FACTOR==='Medium' || (width==1025)){
            this.sidebarCSS = 'slds-size_12-of-12';
            this.middleSpaceCSS = 'doNotDisplay';
            this.mainSectionCSS = 'slds-size_12-of-12 slds-large-size_12-of-12 slds-medium-size_12-of-12 ecom-mt-64 ';
        }
        else{
            this.sidebarCSS = 'slds-size_12-of-12 slds-large-size_3-of-12 slds-medium-size_3-of-12';
            this.middleSpaceCSS = 'slds-size_1-of-12';
            this.mainSectionCSS = 'slds-size_12-of-12 slds-large-size_8-of-12 slds-medium-size_8-of-12 ecom-mt-64';
        }
    }

    fetchContactInfo(){ /*RWPS-1924*/
        getContactInfo()
        .then(result=>{
            if(result)
            {
                this.contactEmail = result?.Email;
            }
        }).catch(error=>{
             processAndLogJSError(error, this.fileName, this.moduleName, 'fetchContactInfo');//RWPS-5153
        })
    }

    // @api
    // getAccountEditDetails(){
    //     this.showSpinner = true;
    //     getAccountDetails()
    //     .then((result) => {
    //         if(result){
    //             this.accountDetailsList = [];
    //             console.log('result =>', result);
    //             //let accountDetails  = result;
    //             this.allAccountDetailsList = result;
    //             //this.totalAccountDetails = this.allAccountDetailsList.length;
    //             /*this.nextLoadCount = this.defaultListSize;
    //             if(this.defaultListSize > this.totalAccountDetails){
    //                 this.nextLoadCount = this.totalAccountDetails;
    //             }*/
    //             this.billingAddresses = [];
    //             //let isDefaultAccountSet = false;
    //             for(let i=0; i<this.totalAccountDetails; i++){
    //                 let accountDetail = this.allAccountDetailsList[i];
    //                 let billingAddress = accountDetail.billToDetails[0];
    //                 let shippingAddress = accountDetail.shipToDetails[0];
    //                 let accountDetailsListTemp = {};
    //                 accountDetailsListTemp.accountId = accountDetail.accountId;
    //                 accountDetailsListTemp.accountName = accountDetail.accountName;
    //                 accountDetailsListTemp.accountNumber = accountDetail.sapAccountNumber;
    //                 accountDetailsListTemp.billToAddress = '';
    //                 accountDetailsListTemp.shipToAddress = '';
    //                 accountDetailsListTemp.isActive = false;
    //                 accountDetailsListTemp.isCPA = accountDetail.isCPA;
    //                 accountDetailsListTemp.billToId = billingAddress.billToId;
    //                 accountDetailsListTemp.shipToId = shippingAddress.shipToId;
    //                 if(billingAddress){
    //                     accountDetailsListTemp.billToAddress = this.handleAddressFormat(billingAddress, 'billing');
    //                 }
    //                 if(shippingAddress){
    //                     accountDetailsListTemp.shipToAddress = this.handleAddressFormat(shippingAddress, 'shipping');
    //                 }
    //                 this.accountDetailsList.push(accountDetailsListTemp);
    //             }

    //            //move active account to top
    //             this.setActiveAccount();
    //             this.accountDetailsListToDisplay = [];
    //             this.accountDetailsListToDisplay = this.accountDetailsList.slice(0,this.defaultListSize);

    //            /*  //Get items to display on UI
    //             this.accountDetailsListToDisplay = [];
    //             for(let i=0; i<this.nextLoadCount; i++){
    //                 this.accountDetailsListToDisplay.push(this.accountDetailsList[i]);
    //             }
    //             if(this.totalAccountDetails > this.defaultListSize){
    //                  this.isLoadMore = true;
    //             }*/
    //             this.showSpinner = false;
    //         }
    //      })
    //      .catch((error) => {
    //          console.log('error =>'+JSON.stringify(error));
    //          this.accountDetailsList = undefined;
    //          this.showSpinner = false;
    //      });
    // }

    // handlePagination(event){
    //     const start = (event.detail-1)*this.defaultListSize;
    //     const end = this.defaultListSize*event.detail;
    //     this.accountDetailsListToDisplay = this.accountDetailsList.slice(start, end);
    // }

    // setActiveAccount(){
    //     let activeAccountIndex;
    //     let capActiveAccountIndex = this.accountDetailsList.findIndex(e=>(e.isCPA===true));
    //     let nonCPAActiveAccountIndex = this.accountDetailsList.findIndex(e=>(e.accountId==this.accountId));
    //     if(capActiveAccountIndex>-1){
    //         this.accountDetailsList[capActiveAccountIndex].isActive = true;
    //         activeAccountIndex = capActiveAccountIndex;
    //         this.updatedActiveAccountNumber = this.accountDetailsList[capActiveAccountIndex].accountNumber;
    //     } else if(capActiveAccountIndex==-1 && nonCPAActiveAccountIndex>-1){
    //         this.accountDetailsList[nonCPAActiveAccountIndex].isActive = true;
    //         activeAccountIndex = nonCPAActiveAccountIndex;
    //         this.updatedActiveAccountNumber = this.accountDetailsList[nonCPAActiveAccountIndex].accountNumber;
    //     }
    //     //move active account to top
    //     let activeAccountDetails = this.accountDetailsList[activeAccountIndex];
    //     this.accountDetailsList.splice(activeAccountIndex, 1);
    //     this.accountDetailsList.splice(0, 0, activeAccountDetails);
    // }

    handleUndefined(addressPart){
        if(addressPart){
            return addressPart;
        } else {
            return '';
        }
    }

    handleAddressFormat(address, addressType){
    try{//RWPS-5153
        if(addressType === 'billing'){
            return this.handleUndefined(address?.billToStreet)+' '+this.handleUndefined(address?.billToCity)+'\n'+
            this.handleUndefined(address?.billToCountry)+' '+this.handleUndefined(address?.billToPostalCode);
        }
        if(addressType === 'shipping'){
            return this.handleUndefined(address?.shipToStreet)+' '+this.handleUndefined(address?.shipToCity)+'\n' +
            this.handleUndefined(address?.shipToCountry)+' '+this.handleUndefined(address?.shipToPostalCode);
        }
    }catch(error){//RWPS-5153 start
        processAndLogJSError(error, this.fileName, this.moduleName, 'handleAddressFormat');
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
    }catch(error)//RWPS-5153 start
    { 
        processAndLogJSError(error, this.fileName, this.moduleName, 'handleValidation');
    }//RWPS-5153 end
    }

    // prepareBillingAddress(accountDetail){
    //     for(let i=0; i<accountDetail?.billToDetails.length; i++){
    //         let billTo = accountDetail.billToDetails[i];
    //         if(billTo){
    //             this.billingAddresses.push({
    //                 accountId: accountDetail.accountId,
    //                 isCPA: accountDetail.isCPA,
    //                 billToId: billTo?.billToId,//accountDetail.accountId,
    //                 accountName: billTo?.billToName,//accountDetail.accountName,
    //                 billingAddress: billTo?.billToStreet+'\n'+billTo?.billToCity+', '
    //                 +billTo?.billToCountry+' '+billTo?.billToPostalCode
    //             });
    //         }
    //     }
    //     console.log('billingAddress>>>',this.billingAddresses);
    // }

    /*handleLoadMoreAccounts(event){
        if(this.isLoadMore){
            this.nextLoadCount =  this.accountDetailsListToDisplay.length + this.defaultListSize;
            this.accountDetailsListToDisplay = [];
            if(this.nextLoadCount > this.totalAccountDetails){
                this.nextLoadCount = this.totalAccountDetails;
            }
            for(let i=0; i<this.nextLoadCount;i++){
                this.accountDetailsListToDisplay.push(this.accountDetailsList[i]);
            }
        }
        //disable Load More when total Orders are equals to display Order
        if(this.accountDetailsListToDisplay.length === this.totalAccountDetails){
            this.isLoadMore = false;
        }
    }*/

    // handleActiveAccountChange(event){
    //     this.showSpinner = true;
    //     let currentAccountId = event.currentTarget.dataset.id;
    //     let shipToId = event.currentTarget.dataset.ship;
    //     let billToId = event.currentTarget.dataset.bill;
    //     this.accountId = currentAccountId;
    //     console.log('accountId>>>'+ currentAccountId);
    //     this.updatedActiveAccountNumber = '';
    //     makeAccountActive({
    //         accountId: currentAccountId,
    //         shipTo: shipToId,
    //         billTo: billToId
    //     }).then((result) => {
    //         if(result == 'success'){
    //             this.showSpinner = false;
    //             this.accountDetailsList = undefined;
    //             this.getAccountEditDetails();
    //             this.isAccountUpdated = true;
    //             window.scrollTo(0, 0);
    //         } else{
    //             console.log('Something went wrong');
    //         }
    //     }).catch((error) => {
    //         this.showSpinner = false;
    //         console.log('error =>'+JSON.stringify(error));
    //     });
    // }

    closeMessage(){
        this.isAccountUpdated = false;
    }


    // openAddressPopUp(event){
    //     let currentAccountId = event?.currentTarget.dataset.id;
    //     if(event){
    //         this.selectedBillingAccount = event?.currentTarget.dataset.bill;
    //     }
    //     this.isShowBillingAddress = true;
    //     this.currentBillingAddresses = [];
    //     if(!currentAccountId){
    //         currentAccountId = this.accountId;
    //     }

    //     this.billingAddresses = [];
    //     this.hasCPA=false;
    //     this.isModifyCPA=false;
    //     this.showSpinner=true;
    //     getBillingOfUser({conId:this.contactId, accId:this.accountId})
    //     .then((result) => {
    //         if(result){
    //             let billToAddresses = [];
    //             result.forEach((ele) => {
    //                 this.prepareBillingAddress(ele);
    //             });
    //             billToAddresses = this.findBillingAddress(currentAccountId, this.billingAddresses);
    //             if(billToAddresses){
    //                 for(let i=0; i<billToAddresses.length;i++){
    //                     if(billToAddresses[i].billToId == this.selectedBillingAccount){
    //                         this.currentBillingAddresses.push({
    //                         selected: true,
    //                         accountId: billToAddresses[i].billToId,
    //                         accountName: billToAddresses[i].accountName,
    //                         billingAddress: billToAddresses[i].billingAddress,
    //                         isCPA: billToAddresses[i].isCPA
    //                     });
    //                     } else {
    //                         this.currentBillingAddresses.push({
    //                         selected: false,
    //                         accountId: billToAddresses[i].billToId,
    //                         accountName: billToAddresses[i].accountName,
    //                         billingAddress: billToAddresses[i].billingAddress,
    //                         isCPA: billToAddresses[i].isCPA
    //                         });
    //                     }
    //                     if(!this.hasCPA && billToAddresses[i].isCPA){
    //                         this.hasCPA = true;
    //                         if(this.currentBillingAddresses[i].selected){
    //                             this.isModifyCPA = true;
    //                         }
    //                         this.selectedBillingAccount = billToAddresses[i].billToId;
    //                     }
    //                 }
    //             }
    //         }
    //         console.log('hasCPA>>',this.hasCPA);
    //         this.showSpinner = false;
    //     }).catch((error) => {
    //         console.log('error =>'+JSON.stringify(error));
    //         this.showSpinner = false;
    //     });
    //     console.log('BillingAddresses>>> ', this.currentBillingAddresses);
    // }

    findBillingAddress(accId, billingArray){
        let billings = [];
        for (let i=0; i < billingArray.length; i++) {
            if ((billingArray[i].accountId === accId) || (billingArray[i].isCPA)) {
                billings.push(billingArray[i]);
            }
        }
        return billings;
    }



    // radioBillingChanged1(event){
    //     let billingAccount = event.target.value;
    //     this.selectedBillingAccount = billingAccount;
    //     this.isModifyCPA =false;
    //     console.log('Biiling changed>> '+ billingAccount);
    //     let billToAddresses =  this.currentBillingAddresses;
    //     for(let i=0; i<billToAddresses.length; i++){
    //         if(billingAccount == billToAddresses[i].accountId){
    //             billToAddresses[i].selected = true;
    //             if(billToAddresses[i].isCPA && !this.isModifyCPA){
    //                 this.isModifyCPA = true;
    //             }
    //         } else {
    //             billToAddresses[i].selected = false;
    //         }
    //     }
    //     this.currentBillingAddresses = [];
    //     this.currentBillingAddresses = billToAddresses;
    //     console.log('BillingAddresses>>> ', this.currentBillingAddresses);
    // }

    // handleSaveBillingAddress(){
    //     this.showSpinner = true;
    //     console.log('contactId>> '+this.contactId);
    //     console.log('billingAccount>> '+this.selectedBillingAccount );
    //     updateBillingOnContact({
    //         contactId: this.contactId,
    //         billingAccount: this.selectedBillingAccount
    //     }).then((result) => {
    //         if(result == 'success'){
    //             console.log('Success');
    //             this.isShowBillingAddress = false;
    //         }
    //         this.getAccountEditDetails();
    //         this.showSpinner = false;
    //     }).catch((error) => {
    //         this.showSpinner = false;
    //         console.log('error =>'+JSON.stringify(error));
    //     });
    // }

    handleAddAddress(){
        this.isAddAddressClicked = true;
        this.isAccountEdit = false;
    }


    handleAddressEvent(event){

        let value = event.detail.nextStep;
        if(value == 'showAddressTab'){

            this.isAddAddressClicked = false;
            this.isAccountEdit = true;

            //handle ECOM-3262
            //this.fetchERPAddressDetail();
            //this.hideAddressEditEvent();
        }
    }

    handleAddAccountAddress(){
       this.customEvent('addAccountorAddress');
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

    hideAddressEditEvent(){
        this.dispatchEvent(
            new CustomEvent('addressevent', {
                detail: {
                    nextStep: 'showAddressTab'
                }
            })
        );
    }

    @wire(getPicklistValues, { recordTypeId: DEFAULT_RECORDTYPE_ID, fieldApiName: COUNTRY_CODE })
    wiredCountires({ error, data }) {
        if(data){
            this._countries = data?.values;

        }else if(error){
            processAndLogJSError(error, this.fileName, this.moduleName, 'wiredCountires');//RWPS-5153
        }
    }

    @wire(getPicklistValues, { recordTypeId: DEFAULT_RECORDTYPE_ID, fieldApiName: STATE_CODE })
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

    closeAddBillingModal(event){
        this.showAddressError=false;
        this.showAddBillingModal=false;
        //RWPS-5799 Start
        if (this.availablesBilTosClone && this.availablesBilTosClone.length > 0) {
            this.availablesBilTos = JSON.parse(JSON.stringify(this.availablesBilTosClone));
        }
        this.isAlreadyModalOpen = false;
        //RWPS-5799 End
        //RWPS-4087 start
        if (this.lastFocusedElement) {
            this.lastFocusedElement.focus();
            this.lastFocusedElement = null; 
        }//RWPS-4087 end
    }


    //New changes based on ERP Address

    erpAddress = [];
    erpAddressBackup=[];
    shipToAddressWithActivePayer = [];
    allShipToAddressWithActivePayer = [];
    selectedERPAddressForChange ={};
    selectedERPSoldToId;
    availablesBilTos = [];
    selectedBillToMailingAddress = [];
    currentBillTo_ToUpdate = '';
    currentInvoice_ToUpdate = '';
    canCreateNewAddress = false;
    canModifyERPAddress = false;
    @track newOrEditERPAddress ={
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
    currentPageNumber=1;
    _totalErpAddress ;
    defaultListSize = 4;
    isDataLoaded = false;
    accountAddressUpdateMessage ='';
    showAddBillingModal= false;
    showEditButton;
    get showPaginaton(){
        return this.isDataLoaded &&  this.totalErpAddress>this.defaultListSize;
    }
    @api
    device = {
        isMobile : FORM_FACTOR==='Small',
        isDesktop : FORM_FACTOR==='Large',
        isTablet :FORM_FACTOR==='Medium'
    }
    get totalErpAddress(){
        return this._totalErpAddress;
    }
    set totalErpAddress(value){
        this._totalErpAddress =  value;
    }


    fetchERPAddressDetail(){
        this.showSpinner = true;
        this.isDataLoaded = false;
        fetchERPAddressDetails().then((result) => {
            this.showSpinner = false;

            console.log('result fetchERPAddressDetail:', result);
            // ECOM -1933 for new field validations by sathiya
            this.billToFieldValidationJSON = result?.billToValidationFields;
            if(this.billToFieldValidationJSON != null){
                this.billToFieldValidationObj = JSON.parse(this.billToFieldValidationJSON);
            }
            // Changes End
            var accountDetails=result?.accountDetails;

            var showEditButton=false;

            for(var i in accountDetails)
            {
                if(accountDetails[i]?.isSelected)
                {
                    if(accountDetails[i].externalId=='NewAddress' || accountDetails[i].externalId=='New Address')
                    {
                        showEditButton=true;
                    }
                }
            }

            this.showEditButton=showEditButton;
            this.erpAddress  = result?.accountDetails;
            let validErpAddress = [];
            for (let i = 0; i < this.erpAddress.length; i++) {
                if(this.erpAddress[i]?.erpAddresses != null){
                    for (let j = 0; j < this.erpAddress[i]?.erpAddresses.length; j++) {
                        if(this.erpAddress[i].erpAddresses[j]?.addressType == 'Ship To' && this.erpAddress[i].erpAddresses[j]?.isRad){
                            this.erpAddress[i].isRad = true;
                        }
                        if(this.erpAddress[i].erpAddresses[j]?.addressType == 'Payer'){
                            this.erpAddress[i].erpAddresses[j] = validateAddressByFields(this.erpAddress[i].erpAddresses[j], this.billToFieldValidationObj);
                        }
                        if(this.erpAddress[i]?.erpAddresses[j]?.associatedInvoiceAddresses == null){
                            this.erpAddress[i].erpAddresses[j].associatedInvoiceAddresses = [];
                        }
                        // ECOM -1933 for new field validations  by sathiya
                        if(this.erpAddress[i]?.erpAddresses[j]?.associatedAddresses != null){
                            for(let k = 0; k < this.erpAddress[i].erpAddresses[j].associatedAddresses.length; k++){
                                if(this.erpAddress[i].erpAddresses[j].associatedAddresses[k]?.addressType == 'Payer'){
                                    this.erpAddress[i].erpAddresses[j].associatedAddresses[k] = validateAddressByFields(this.erpAddress[i].erpAddresses[j].associatedAddresses[k], this.billToFieldValidationObj);
                                }
                            }
                        }
                        // Changes End
                    }
                    validErpAddress.push(this.erpAddress[i]);
                }
            }
            this.erpAddress = validErpAddress;
            this.selectedBillToMailingAddress = [];
            let isInvoiceMailingAddressSelected = false;
            let shipToAddressWithActivePayer = this.parseAddressStructure();

            /*let shipToAddressWithActivePayer = this.erpAddress.map((account) => {
                return {...account,
                    address:  account?.isSelected ?   account?.erpAddresses[0]?.associatedAddresses?.filter((addr) =>
                        addr.isSelected === true
                    ) : [account?.erpAddresses[0]?.associatedAddresses[0]] ,
                    defaultBillTo: account?.isSelected ? account?.erpAddresses[0]?.associatedAddresses?.filter((addr) =>
                    addr.isSelected === true
                ) :  [account?.erpAddresses[0]?.associatedAddresses[0]],
                    isInvoiceMailingAddress: validateInvoiceMailingAddressByCountry(account?.erpAddresses[0]?.country, this.labels.ECOM_invoiceMailingAddressCountries) && this.selectedBillToMailingAddress.length > 0,
                    invoiceAddress:  account?.isSelected && isInvoiceMailingAddressSelected ?   this.selectedBillToMailingAddress?.filter((addr) =>
                    addr.isSelected === true
                        ) : (this.selectedBillToMailingAddress.length > 0?[this.selectedBillToMailingAddress[0]]:[])  ,
                    defaultInvoice: account?.isSelected && isInvoiceMailingAddressSelected ? this.selectedBillToMailingAddress?.filter((addr) =>
                    addr.isSelected === true
                        ) :  (this.selectedBillToMailingAddress.length > 0?[this.selectedBillToMailingAddress[0]]:[])
                }
            });*/
            console.log('shipToAddressWithActivePayer::', shipToAddressWithActivePayer);
            //pagination logic need to be updated
            this.allShipToAddressWithActivePayer  = shipToAddressWithActivePayer.sort((a, b) => b.isSelected - a.isSelected);
            this.totalErpAddress = this.allShipToAddressWithActivePayer.length;
            //reset page every time when make a server call to get all data
            this.currentPageNumber = 1;
            //reset pagination remcords
            this.shipToAddressWithActivePayer = this.allShipToAddressWithActivePayer.length > 0 ? this.allShipToAddressWithActivePayer.slice(0,this.defaultListSize) : [];

            if(this.showEditButton)
            {
                this.showAddBillingModal=false;
            }


            this.isDataLoaded = true;
        }).catch((error) => {
            this.showSpinner = false;
            processAndLogJSError(error, this.fileName, this.moduleName, 'fetchERPAddressDetail');//RWPS-5153
        });
    }

    parseAddressStructure(){
    try{//RWPS-5153
        let shipToAddressWithActivePayer = [];
        for(let i = 0; i < this.erpAddress.length; i++){
            let currentAddress = this.erpAddress[i];
            if(currentAddress?.erpAddresses != null){
                for(let j = 0; j < currentAddress?.erpAddresses.length; j++){
                    let shipToAddress = currentAddress?.erpAddresses[j];
                    if(shipToAddress?.associatedAddresses != null){ //RWPS-1801
                        if(shipToAddress?.associatedAddresses.length > 0){
                            let defaultBillTo = shipToAddress?.associatedAddresses?.filter((addr) => addr.isSelected === true);
                            currentAddress.defaultBillTo = defaultBillTo.length > 0? defaultBillTo: [shipToAddress?.associatedAddresses[0]];
                            currentAddress.address = defaultBillTo.length > 0? defaultBillTo: [shipToAddress?.associatedAddresses[0]];
                            for(let k = 0; k < shipToAddress?.associatedAddresses.length; k++){
                                if(shipToAddress?.associatedAddresses[k]?.id == currentAddress.defaultBillTo[0]?.id){
                                    let isAddrAvailable = true;
                                    if(shipToAddress?.associatedAddresses[k]?.associatedAddresses != null){
                                        if(shipToAddress?.associatedAddresses[k]?.associatedAddresses.length > 0){
                                            let defaultInvoice = shipToAddress?.associatedAddresses[k]?.associatedAddresses?.filter((addr) => addr.isSelected === true);
                                            currentAddress.defaultInvoice = defaultInvoice.length > 0? defaultInvoice: [shipToAddress?.associatedAddresses[k]?.associatedAddresses[0]];
                                            currentAddress.invoiceAddress = defaultInvoice.length > 0? defaultInvoice: [shipToAddress?.associatedAddresses[k]?.associatedAddresses[0]];
                                            currentAddress.isInvoiceMailingAddress = validateInvoiceMailingAddressByCountry(shipToAddress?.country, this.labels.ECOM_invoiceMailingAddressCountries) && currentAddress.invoiceAddress.length > 0;
                                        } else {
                                            isAddrAvailable = false;
                                        }
                                    } else {
                                        isAddrAvailable = false;
                                    }
                                    if(!isAddrAvailable){
                                        currentAddress.defaultInvoice = [];
                                        currentAddress.invoiceAddress = [];
                                        currentAddress.isInvoiceMailingAddress = false;
                                    }
                                }
                            }
                        } else {
                            currentAddress.defaultBillTo = [];
                            currentAddress.address = [];
                            currentAddress.defaultInvoice = [];
                            currentAddress.invoiceAddress = [];
                            currentAddress.isInvoiceMailingAddress = false;
                        }
                        shipToAddressWithActivePayer.push(currentAddress);
                    }
                }
            }
        }
        return shipToAddressWithActivePayer;
    }catch(error)//RWPS-5153 start
    {
        processAndLogJSError(error, this.fileName, this.moduleName, 'parseAddressStructure');
    }//RWPS-5153 end
    }
    // Method to validate
    fetchAccountDetail(){
        this.showSpinner = true;
        this.isDataLoaded = false;
        fetchAccountDetails().then((result) => {
            this.showSpinner = false;
            this.erpAddress  = result;

            let shipToAddressWithActivePayer = this.parseAddressStructure();

            //pagination logic need to be updated
            this.allShipToAddressWithActivePayer  = shipToAddressWithActivePayer.sort((a, b) => b.isSelected - a.isSelected);
            this.totalErpAddress = this.allShipToAddressWithActivePayer.length;
            //reset page every time when make a server call to get all data
            this.currentPageNumber = 1;
            //reset pagination remcords
            this.shipToAddressWithActivePayer = this.allShipToAddressWithActivePayer.length > 0 ? this.allShipToAddressWithActivePayer.slice(0,this.defaultListSize) : [];

            this.isDataLoaded = true;
        }).catch((error) => {
            this.showSpinner = false;
            processAndLogJSError(error, this.fileName, this.moduleName, 'fetchAccountDetails');//RWPS-5153
        });
    }

    hideBillingAddressModal(event) {
        if(event!='fromModal')
        {
            this.erpAddress=JSON.parse(JSON.stringify(this.erpAddressBackup));
            //RWPS-5799 Start
            if(this.availablesBilTosClone && this.availablesBilTosClone.length > 0) {
                this.availablesBilTos = JSON.parse(JSON.stringify(this.availablesBilTosClone));
            }//RWPS-5799 End
        }
        this.isAlreadyModalOpen = false; //RWPS-2372
        this.isShowBillingAddress = false;
        //RWPS-4087 start
        if (this.lastFocusedElement) {
            this.lastFocusedElement.focus();
            this.lastFocusedElement = null; 
        }//RWPS-4087 end
    }

    openBillToAddressPopUp(event){
     try{//RWPS-5153
        // Change by sathiya for ECOM-1939
        let addressType = event?.currentTarget?.dataset?.addresstype;
        this.modalAddressType = addressType;
        this.modalAddressLabel = addressType == 'invoice'?this.labels.ECOM_InvoiceMailingAddress:this.labels.ECOM_BillingAddress;
        this.modalNewAddressLabel = addressType == 'invoice'?this.labels.ECOM_AddInvoiceMailingAddress:this.labels.ECOM_AddBillingAddress;
        // Change End
        this.erpAddressBackup=JSON.parse(JSON.stringify(this.erpAddress));
        let externalId = event?.currentTarget.dataset.externalid;
        this.isShowBillingAddress = true;
        //RWPS-4087 start
        if(this.isShowBillingAddress)
        {
            requestAnimationFrame(() => {
                const modal = this.template.querySelector(`[data-id="billingAddress"]`);
                if (modal) {
                    modal.focus();
                }
            });
        } //RWPS-4087 end
        this.availablesBilTos = [];
        let canModifyAddress = false;
        let allErpAddresss =  this.erpAddress.filter(
            (addr) =>addr.externalId === externalId
        );
        this.selectedERPAddressForChange = allErpAddresss[0] || {};
        this.contactId = allErpAddresss[0]?.contactId;
        let bilToAddress = allErpAddresss[0]?.erpAddresses[0]?.associatedAddresses || [];
        let defaultBillTo = bilToAddress.filter(function(addr){
            return addr.isSelected === true;
        });
        let invoiceAddress = defaultBillTo.length > 0?defaultBillTo[0]?.associatedAddresses:bilToAddress[0]?.associatedAddresses;
        invoiceAddress = JSON.parse(JSON.stringify(invoiceAddress));
        let defaultBillToInvoice = defaultBillTo.length > 0?defaultBillTo[0]:bilToAddress[0];
        for(let j = 0; j < invoiceAddress.length; j++){
            invoiceAddress[j].associatedAddresses = [defaultBillToInvoice];
        }
        this.availablesBilTos = addressType == 'invoice'? invoiceAddress:bilToAddress;
        var isNewAddressPresent=false;
        for(var i in this.availablesBilTos)
        {
            if(this.availablesBilTos[i].ecomReviewStatus!='Approved')
            {
                isNewAddressPresent=true;
                if(this.availablesBilTos[i].isSelected==true)
                {
                    canModifyAddress = true;
                }
                break;
            }
        }
        this.canModifyERPAddress=canModifyAddress;


        if(isNewAddressPresent)
        {
            this.canCreateNewAddress=false;
        }
        else
        {
            this.canCreateNewAddress=true;
        }

        this.newOrEditERPAddress ={
            accountId: allErpAddresss[0]?.accountId,
            contactId : this.contactId,
            addressType: addressType == 'invoice'?"Bill To":"Payer",
            city:"",
            country:"",
            ecomReviewStatus: "",
            erpAccountName:"",
            externalId: "",
            id: "",
            postalCode: "",
            state: "",
            street: "",
            associatedAddresses:addressType == 'invoice'?[defaultBillToInvoice]:([allErpAddresss[0]?.erpAddresses[0]] || []),
            validationFields: addressType == 'invoice'?[]:allErpAddresss[0]?.validationFields,
            isValidatedFields: addressType == 'invoice'?false:allErpAddresss[0]?.isValidatedFields
    };
    }catch(error){//RWPS-5153 start
        processAndLogJSError(error, this.fileName, this.moduleName, 'openBillToAddressPopUp');
    }//RWPS-5153 end
    }

    // called form Change Billing Address modal
    radioBillingChanged(event){
    try{//RWPS-5153
        let billToERPAddressId = event.target.value;
        let allErpAddress =  this.erpAddress.filter(
            (addr) =>addr.isSelected === true
        );

        if(this.modalAddressType == 'invoice'){
            this.currentInvoice_ToUpdate = billToERPAddressId;
            let billToAddress = allErpAddress[0]?.erpAddresses[0]?.associatedAddresses || [];
            if(billToAddress.length > 0){
                let defaultBillToAddress = billToAddress.filter((address)=>address.isSelected ===true);
                let billToERPId = defaultBillToAddress.length > 0 ? defaultBillToAddress[0].id :billToAddress[0].id;
                this.currentBillTo_ToUpdate = billToERPId;
            }
         } else {
            this.currentBillTo_ToUpdate = billToERPAddressId;
            let billToList = allErpAddress[0]?.erpAddresses[0]?.associatedAddresses || [];
            if(billToList.length > 0){
                for(let i in billToList){
                    if(billToList[i].id == this.currentBillTo_ToUpdate){
                        let invoiceAddress = billToList[i]?.associatedAddresses || [];
                        if(invoiceAddress.length > 0){
                            let defaultInvoiceAddress = invoiceAddress.filter((address)=>address.isSelected ===true);
                            let invoiceErpId = defaultInvoiceAddress.length > 0 ? defaultInvoiceAddress[0].id :invoiceAddress[0].id;
                            this.currentInvoice_ToUpdate = invoiceErpId;
                            break;
                        }
                    }
                }
            }
        }
        let currentSelectedAddress = this.availablesBilTos.filter((address)=>address.id===billToERPAddressId);
        let availablesBilTos=JSON.parse(JSON.stringify(this.availablesBilTos));
        for(var i in availablesBilTos)
        {
            if(availablesBilTos[i].id==billToERPAddressId)
            {
                availablesBilTos[i].isSelected=true;
            }
            else
            {
                availablesBilTos[i].isSelected=false;
            }
        }
        this.availablesBilTos=availablesBilTos;
        if(currentSelectedAddress[0].ecomReviewStatus!='Approved')
        {
            this.canModifyERPAddress=true;
            this.canCreateNewAddress=false;
        }
        else
        {
            this.canModifyERPAddress=false;
        }
    }catch(error){    //RWPS-5153 start
        processAndLogJSError(error, this.fileName, this.moduleName, 'radioBillingChanged');
    }//RWPS-5153 end
    }
    // called from Change Billing Address modal
    handleSaveBilltoERPAddress(){
    try{ //RWPS-5153
        this.showSpinner = true;
        let allErpAddress =  this.erpAddress.filter(
            (addr) =>addr.isSelected === true
        );
        let billToAddress = allErpAddress[0]?.erpAddresses[0]?.associatedAddresses || [];
        if(billToAddress.length > 0){
            let defaultBillToAddress = billToAddress.filter((address)=>address.isSelected ===true);
            let billToERPId = defaultBillToAddress.length > 0 ? defaultBillToAddress[0].id :billToAddress[0].id;
            if(this.currentBillTo_ToUpdate == ''){
                this.currentBillTo_ToUpdate = billToERPId;
            } else {
                defaultBillToAddress = billToAddress.filter((address)=>address.id === this.currentBillTo_ToUpdate);
            }
            let invoiceAddress = defaultBillToAddress.length > 0 ? defaultBillToAddress[0]?.associatedAddresses :billToAddress[0]?.associatedAddresses;
            if(invoiceAddress != null){
                if(invoiceAddress.length > 0){
                    let defaultInvoiceAddress = invoiceAddress.filter((address)=>address.isSelected ===true);
                    let invoiceErpId = defaultInvoiceAddress.length > 0 ? defaultInvoiceAddress[0].id :invoiceAddress[0].id;
                    if(this.currentInvoice_ToUpdate == ''){
                        this.currentInvoice_ToUpdate = invoiceErpId;
                    }
                }
            } else {
                this.currentInvoice_ToUpdate = '';
            }
        }

        if((this.modalAddressType != 'invoice' && !this.currentBillTo_ToUpdate) || (this.modalAddressType == 'invoice' && !this.currentInvoice_ToUpdate)){
            this.showSpinner=false;
            return;
        }
        let soldToId ='';
        //To do update server method name
        this.makeAccountActiveOrupdateAddress(this.selectedERPAddressForChange?.contactId,
            this.selectedERPAddressForChange?.accountId,
            this.selectedERPAddressForChange?.erpAddresses[0]?.id,
            this.currentBillTo_ToUpdate,
            this.currentInvoice_ToUpdate,
            this.selectedERPAddressForChange?.externalId,
            soldToId,
            true,
            false
        );
    }catch(error){ //RWPS-5153 start
        processAndLogJSError(error, this.fileName, this.moduleName, 'handleSaveBilltoERPAddress');
    }//RWPS-5153 end
    }

    // add or edit ERP address
    handleAddAddressEventFromBilling(event){
    try{//RWPS-5153 
        this.selectedCountry = this.erpAddress[0]?.erpAddresses[0]?.country;
        //Changes to add validation to the new Erp Address by Sathiya
        this.newOrEditERPAddress.country = this.selectedCountry;
        if(this.modalAddressType == 'billing'){
            this.newOrEditERPAddress = validateAddressByFields(this.newOrEditERPAddress, this.billToFieldValidationObj);
            this.newOrEditERPAddress.isValidatedFields = this.newOrEditERPAddress.validationFields.length > 0;
        }
        //Changes end
        this.showAddBillingModal = true;
         //RWPS-4087 start
        requestAnimationFrame(() => {
            const modal = this.template.querySelector(`[data-id="billingModal"]`);
            if (modal) {
                modal.focus();
            }
        });
         //RWPS-4087 end
    }catch(error){   //RWPS-5153 start 
        processAndLogJSError(error, this.fileName, this.moduleName, 'handleAddAddressEventFromBilling');
    }//RWPS-5153 end
    }

    handleModifyAddressEventFromBilling(event)
    {
    try{//RWPS-5153
        //RWPS-2372 - Start
        if (this.isAlreadyModalOpen) { //RWPS-2372
            this.showAddBillingModal = true;
             //RWPS-4087 start
            requestAnimationFrame(() => {
                const modal = this.template.querySelector(`[data-id="billingModal"]`);
                if (modal) {
                    modal.focus();
                }
            });//RWPS-4087 end
            return; // Skip the code execution if the modal is already open
        }
        this.availablesBilTosClone = JSON.parse(JSON.stringify(this.availablesBilTos))//RWPS-5393
        //RWPS-2372 - End
        for(var i in this.availablesBilTos)
        {
            if(this.availablesBilTos[i].isSelected)
            {
                this.newOrEditERPAddress = JSON.parse(JSON.stringify(this.availablesBilTos[i])); //RWPS-5799
                this.newOrEditERPAddress.contactId  = this.contactId;
                //RWPS-5933 Start
                const countryMatch = this.countries.find(opt => opt.label === this.newOrEditERPAddress.country || opt.value === this.newOrEditERPAddress.country);
                this.selectedCountry = countryMatch?.value ?? this.newOrEditERPAddress.country;
                if(this.newOrEditERPAddress?.state != null){
                    const stateMatch = this.states.find(opt => opt.label === this.newOrEditERPAddress.state);
                    this.selectedBillingState = stateMatch?.value ?? this.newOrEditERPAddress.state;
                } //RWPS-5933 End
                break;
            }
        }
        var breakFromLoop=false;
        for(var i in this.erpAddress)
        {
            for(var j in this.erpAddress[i].erpAddresses){
                if(this.modalAddressType == 'billing'){
                    for (var k in this.erpAddress[i].erpAddresses[j].associatedAddresses){
                        if(this.erpAddress[i].erpAddresses[j].associatedAddresses[k].id==this.newOrEditERPAddress.id){
                            var temp=[];
                            temp.push(JSON.parse(JSON.stringify(this.erpAddress[i].erpAddresses[j])));
                            this.newOrEditERPAddress.associatedAddresses=temp;
                            this.newOrEditERPAddress = validateAddressByFields(this.newOrEditERPAddress, this.billToFieldValidationObj);
                            this.newOrEditERPAddress.isValidatedFields = this.newOrEditERPAddress.validationFields.length > 0;
                            breakFromLoop=true;
                            break;
                        }
                    }
                } else {
                    let bilToAddress = this.erpAddress[i]?.erpAddresses[j]?.associatedAddresses || [];
                    let defaultBillTo = bilToAddress.filter(function(addr){
                        return addr.isSelected === true;
                    });
                    let defaultBillToInvoice = defaultBillTo.length > 0?defaultBillTo[0]:bilToAddress[0];
                    this.newOrEditERPAddress.associatedAddresses = [defaultBillToInvoice];
                }

                if(breakFromLoop)
                    break;
            }
            if(breakFromLoop)
                break;
        }
        this.isAlreadyModalOpen = true; //RWPS-2372
        this.showAddBillingModal = true;
        //RWPS-4087 start
        requestAnimationFrame(() => {
            const modal = this.template.querySelector(`[data-id="billingModal"]`);
            if (modal) {
                modal.focus();
            }
        }); //RWPS-4087 end
    }catch(error){ //RWPS-5153 start         
        processAndLogJSError(error, this.fileName, this.moduleName, 'handleModifyAddressEventFromBilling');
    }//RWPS-5153 end
}

    handleActiveAccountChange(event){
    try{//RWPS-5153
        this.showSpinner = true;
        let externalId = event?.currentTarget.dataset.externalid;
        let selectedAccountId, billToERPId,shipToERPId,contact, invoiceErpId = '';
        let allErpAddress =  this.erpAddress.filter(
            (addr) =>addr.externalId === externalId
        );
        let billToAddress = allErpAddress[0]?.erpAddresses[0]?.associatedAddresses || []
        , invoiceAddress = [];
        let defaultBillToAddress = billToAddress.filter((address)=>address.isSelected ===false)
        , defaultInvoiceAddress;
        selectedAccountId = allErpAddress[0]?.accountId;
        contact = allErpAddress[0]?.contactId;
        //get default bill to address, if there is no default address then pick first instead sending empty value
        billToERPId = defaultBillToAddress.length > 0 ? defaultBillToAddress[0].id :billToAddress[0].id;
        shipToERPId = allErpAddress[0]?.erpAddresses[0]?.id;
        for(let i in billToAddress){
            if(billToAddress[i].id === billToERPId){
                invoiceAddress = billToAddress[i].associatedAddresses;
            }
        }
        if(invoiceAddress.length > 0){
            defaultInvoiceAddress = invoiceAddress.filter((address)=>address.isSelected ===false);
            invoiceErpId = defaultInvoiceAddress.length > 0 ? defaultInvoiceAddress[0].id :invoiceAddress[0].id;
        }
        this.accountId = selectedAccountId;
       this.selectedERPSoldToId = allErpAddress[0]?.soldToAddress?.id;
       let emptySoldTo = externalId=='NewAddress' ? true : false ;
       this.makeAccountActiveOrupdateAddress(contact,selectedAccountId,shipToERPId,billToERPId,invoiceErpId,externalId, this.selectedERPSoldToId ,false,emptySoldTo);
       }catch(error){  //RWPS-5153 start      
            processAndLogJSError(error, this.fileName, this.moduleName, 'handleActiveAccountChange');
        }//RWPS-5153 end
    }
    makeAccountActiveOrupdateAddress(contactId,accountId,shipToERPId,billToERPId,invoiceErpId,externalId,soldToId, fromModal,emptySoldTo){
        makeAccountActive({
            contactId : contactId,
            accountId: accountId,
            erpShipToId: shipToERPId,
            erpBillToId: billToERPId,
            erpSoldToId : soldToId,
            erpInvoiceId : invoiceErpId,
            emptySoldTo : emptySoldTo
        }).then((result) => {
            if(result == 'Success'){
                this.showSpinner = false;
                this.fetchERPAddressDetail();
                this.isAccountUpdated = true;
                window.scrollTo(0, 0);
            } else{

            }
            if(fromModal){
                this.hideBillingAddressModal('fromModal');
                //this.accountAddressUpdateMessage = 'Billing address saved successfully.';
                this.isAlreadyModalOpen = false; //RWPS-2372
                this.accountAddressUpdateMessage = ECOM_BillingAddressSavedSuccess;
            }else{
                //this.accountAddressUpdateMessage = `Account :#${externalId} activated successfully.`;
                this.accountAddressUpdateMessage = ECOM_Account + externalId + ECOM_ActivatedSuccessfully;
            }
        }).catch((error) => {
            this.showSpinner = false;
            processAndLogJSError(error, this.fileName, this.moduleName, 'makeAccountActiveOrupdateAddress');//RWPS-5153

        });
    }

    pageChanged(event) {
        let pageNumber = JSON.parse(JSON.stringify(event.detail.pageNumber));
        this.currentPageNumber = parseInt(pageNumber);
        const start = (this.currentPageNumber-1)*this.defaultListSize;
        const end = this.defaultListSize*this.currentPageNumber;
        this.shipToAddressWithActivePayer =  this.allShipToAddressWithActivePayer.slice(start,end);
    }
    //RWPS-2372 - Start
    resetValueAfterCancel(){ //RWPS-2372
        if (this.newOrEditERPAddressClone && Object.keys(this.newOrEditERPAddressClone).length !== 0) {
            this.newOrEditERPAddress = JSON.parse(JSON.stringify(this.newOrEditERPAddressClone)); // Create a deep copy
            this.availablesBilTos = this.availablesBilTosClone;
            this.shipToAddressWithActivePayer = JSON.parse(JSON.stringify(this.shipToAddressWithActivePayerClone));
        }
    }
    //RWPS-2372 - End

    handleBillingChange(event) {
    try{//RWPS-5153
        if (event.target.value.length>0 && event.target.value[0]==' ') {
            event.target.value = event.target.value.trim();
        }
         //RWPS-2372 - Start
        if (!this.newOrEditERPAddressClone || Object.keys(this.newOrEditERPAddressClone).length === 0) {
            this.availablesBilTosClone = JSON.parse(JSON.stringify(this.availablesBilTos));
            this.newOrEditERPAddressClone = JSON.parse(JSON.stringify(this.newOrEditERPAddress)); // Clone the address to reset it if canceled.
            this.shipToAddressWithActivePayerClone = JSON.parse(JSON.stringify(this.shipToAddressWithActivePayer));
        }
        //RWPS-2372 - End
        this.newOrEditERPAddress.addressType = this.modalAddressType == 'invoice'?'Bill To':'Payer';
        if(event.target.dataset.id === 'billing-company-name-id'){
            this.newOrEditERPAddress.erpAccountName =  event.target.value;
        }
        if(event.target.dataset.id === 'billing-country-id'){
            this.selectedCountry = event.target.value;
            this.newOrEditERPAddress.country =  this.countries.find(opt => opt.value === event.detail.value).label;
        }
        if(event.target.dataset.id === 'billing-address-line-1'){
            this.newOrEditERPAddress.street =  event.target.value ;
        }
        if(event.target.dataset.id === 'billing-city-id'){
            this.newOrEditERPAddress.city =  event.target.value ;
        }
        if(event.target.dataset.id === 'billing-state-id'){
            this.selectedBillingState = event.target.value;
            this.newOrEditERPAddress.state =  this.states.find(opt => opt.value === event.target.value).label;
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
                this.newOrEditERPAddress.postalCode = event.target.value;
            }
            
            event.target.reportValidity();
            //RWPS-4911 End
        }
        // Changes done by sathiya on 2024/04/29 for ECOM-1933
        if(event?.target?.dataset?.validate != null){
            let fieldId = event?.target?.dataset?.id, fieldValue = event.target.value.trim();
            if(fieldId == 'invoiceCustId'){
                if(this.newOrEditERPAddress?.validationFields){
                    for(let i=0; i<this.newOrEditERPAddress?.validationFields.length; i++){
                        if(this.newOrEditERPAddress?.validationFields[i].fieldName == 'emailToInvoice'){
                            this.newOrEditERPAddress.validationFields[i].isRequired = fieldValue == ''?true:false;
                        }
                    }
                }
            }
            this.newOrEditERPAddress[fieldId] = fieldValue;
        }
        // Changes End
        if(event.target.dataset.id === 'account-number-id'){
            this.enteredAccountNumber = event.target.value;
            if(this.enteredAccountNumber.length>0){
                this.disabledSubmit = false;
            }else{
                this.disabledSubmit = true;
            }
        }
    }catch(error){//RWPS-5153 start
        processAndLogJSError(error, this.fileName, this.moduleName, 'handleBillingChange');
    }  //RWPS-5153 end
    }
    upsertERPAddress(event){
    try{//RWPS-5153 
        if(!this.newOrEditERPAddress.country){
            this.newOrEditERPAddress.country =  this.countries.find(opt => opt.value === this.selectedCountry).label;
        }
        if(!this.checkError()){
            this.showAddressError=false;
            this.showSpinner=true;
            let currentErpAddress = JSON.parse(JSON.stringify(this.newOrEditERPAddress));
            if(currentErpAddress?.addressType == 'Payer'){
                delete currentErpAddress.validationFields;
                delete currentErpAddress.isValidatedFields;
            }
            if(currentErpAddress?.associatedAddresses != null){
                for(let i = 0; i < currentErpAddress?.associatedAddresses.length; i++){
                    if(currentErpAddress?.associatedAddresses[i]?.validationFields != null){
                        delete currentErpAddress?.associatedAddresses[i]?.validationFields;
                        delete currentErpAddress?.associatedAddresses[i]?.isValidatedFields;
                    }
                    if(currentErpAddress?.associatedAddresses[i]?.associatedAddresses != null){
                        for(let j = 0; j < currentErpAddress?.associatedAddresses[i]?.associatedAddresses.length; j++){
                            delete currentErpAddress?.associatedAddresses[i]?.associatedAddresses[j].validationFields;
                            delete currentErpAddress?.associatedAddresses[i]?.associatedAddresses[j].isValidatedFields;
                        }
                    }
                }
            }
            addERPAddresses({
                jsonAddresses : JSON.stringify([currentErpAddress])
            }).then(result=>{
                if(result.success){
                    console.log('addERPAddresses: ', this.newOrEditERPAddress);
                    //RWSP-2372 - Start
                    this.availablesBilTosClone = JSON.parse(JSON.stringify(this.availablesBilTos));
                    this.newOrEditERPAddressClone = JSON.parse(JSON.stringify(this.newOrEditERPAddress));
                    this.shipToAddressWithActivePayerClone = JSON.parse(JSON.stringify(this.shipToAddressWithActivePayer));
                    this.isAlreadyModalOpen = false;
                    //RWSP-2372 - End
                    // write logic to update address in front end
                    if(this.showEditButton)
                    {
                        this.fetchERPAddressDetail();
                    }
                    else
                    {
                        var updatedERP= result.updatedErpAddresses;
                        updatedERP = JSON.parse(JSON.stringify(updatedERP));
                        updatedERP.erpAccountName = this.newOrEditERPAddress?.erpAccountName;
                        var externalId = this.newOrEditERPAddress.associatedAddresses[0]?.externalId || '';
                        var availablesBilTos=JSON.parse(JSON.stringify(this.availablesBilTos));
                        var erps=JSON.parse(JSON.stringify(this.erpAddress));
                        for(var i in erps){
                            for(var j in erps[i].erpAddresses){
                                if(!this.newOrEditERPAddress?.id){
                                    for(var k in availablesBilTos) {
                                        availablesBilTos[k].isSelected=false;
                                    }
                                    updatedERP.isSelected=true;
                                    if(this.modalAddressType == 'billing'){
                                        if(erps[i].erpAddresses[j].externalId==externalId){
                                            for(var l in erps[i].erpAddresses[j].associatedAddresses){
                                                erps[i].erpAddresses[j].associatedAddresses[l].isSelected=false;
                                            }
                                            erps[i].erpAddresses[j].associatedAddresses.push(updatedERP);
                                            availablesBilTos.push(updatedERP);
                                            this.currentBillTo_ToUpdate = updatedERP.id;
                                        }
                                    } else {
                                        for(let l in erps[i].erpAddresses[j].associatedAddresses){
                                            if(erps[i].erpAddresses[j].associatedAddresses[l].id == this.newOrEditERPAddress.associatedAddresses[0].id){
                                                for(let m in erps[i].erpAddresses[j].associatedAddresses[l].associatedAddresses){
                                                    erps[i].erpAddresses[j].associatedAddresses[l].associatedAddresses[m].isSelected=false;
                                                }
                                                erps[i].erpAddresses[j].associatedAddresses[l].associatedAddresses.push(updatedERP);
                                                availablesBilTos.push(updatedERP);
                                                this.currentInvoice_ToUpdate = updatedERP.id;
                                            }
                                        }
                                    }
                                } else {
                                    if(this.modalAddressType == 'billing'){
                                        for(let k in erps[i].erpAddresses[j].associatedAddresses){
                                            if(erps[i].erpAddresses[j].associatedAddresses[k].id==updatedERP.id){
                                                erps[i].erpAddresses[j].associatedAddresses[k]=updatedERP;
                                                this.currentBillTo_ToUpdate = updatedERP.id;
                                            } else {
                                                erps[i].erpAddresses[j].associatedAddresses[k].isSelected=false;
                                            }
                                        }
                                    } else {
                                        for(let k in erps[i].erpAddresses[j].associatedAddresses){
                                            if(erps[i].erpAddresses[j].associatedAddresses[k].id == this.newOrEditERPAddress.associatedAddresses[0].id){
                                                for(let l in erps[i].erpAddresses[j].associatedAddresses[k].associatedAddresses){
                                                    if(erps[i].erpAddresses[j].associatedAddresses[k].associatedAddresses[l].id == updatedERP.id){
                                                        this.currentInvoice_ToUpdate = updatedERP.id;
                                                        erps[i].erpAddresses[j].associatedAddresses[k].associatedAddresses[l]= updatedERP;
                                                    } else {
                                                        erps[i].erpAddresses[j].associatedAddresses[k].associatedAddresses[l].isSelected=false;
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    for(let k in availablesBilTos){
                                        if(availablesBilTos[k].id==updatedERP.id){
                                            availablesBilTos[k]=updatedERP;
                                            availablesBilTos[k].isSelected=true;
                                            break;
                                        }
                                    }
                                }
                            }
                        }

                        this.erpAddress=erps;
                        this.availablesBilTos=availablesBilTos;
                        // Change made for ECOM-1939 by sathiya
                        if(this.modalAddressType == 'billing'){
                            for(let k =0; k < this.availablesBilTos.length; k++){
                                this.availablesBilTos[k] = validateAddressByFields(this.availablesBilTos[k], this.billToFieldValidationObj);
                                this.availablesBilTos[k].isValidatedFields = this.availablesBilTos[k].validationFields.length > 0;
                            }
                        }
                        // Change End
                        this.canCreateNewAddress=false;
                        this.canModifyERPAddress=true;
                        this.showAddBillingModal=false;
                        this.showAddressError=false;
                        this.showSpinner=false;
                    }
                }
                else
                {
                      this.showSpinner=false;
                      this.type="error";
                      this.showAddressError=true;
                      this.messageAddBillingCPA=result.ErrorMessage;
                      this.timeSpan=0;
                      return;
                }
                this.showSpinner=false;
            }).catch(error=>{
                this.showSpinner=false;
                processAndLogJSError(error, this.fileName, this.moduleName, 'addERPAddresses');//RWPS-5153
            });
        } else{
            this.addressError='Please check all the required fields.';
            this.showBAddressError=true;
        }
    }catch(error){ //RWPS-5153 start
        processAndLogJSError(error, this.fileName, this.moduleName, 'upsertERPAddress');
    }//RWPS-5153 end
    }
    checkError(){
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
        }
        else{
            return true;
        }
    }

    openEditBillTo(event){
    try{//RWPS-5153
        let externalId = event?.currentTarget.dataset.externalid;
        this.availablesBilTos = [];
        let allErpAddresss =  this.erpAddress.filter(
            (addr) =>addr.externalId === externalId
        );
        this.selectedERPAddressForChange = allErpAddresss[0] || {};
        this.contactId = allErpAddresss[0]?.contactId;
        let billToAddress = allErpAddresss[0]?.erpAddresses[0]?.associatedAddresses || [];

        let billToAdd={};

        if(billToAddress.length>0)
        {
            billToAdd=billToAddress[0];

            this.newOrEditERPAddress ={
                accountId: billToAdd?.accountId || '',
                contactId : this.contactId,
                addressType: "Payer",
                city: billToAdd?.city || '',
                country: billToAdd?.country || '',
                ecomReviewStatus: billToAdd?.ecomReviewStatus || '',
                erpAccountName: billToAdd?.erpAccountName || '',
                externalId: billToAdd?.externalId || '',
                id: billToAdd?.id || '',
                postalCode: billToAdd?.postalCode || '',
                state: billToAdd?.state || '',
                street: billToAdd?.street || '',
                fxAddress :billToAdd?.fxAddress || '',
            };

            this.selectedCountry = this.countries.find(opt => opt.label === this.newOrEditERPAddress.country).value;
            this.selectedBillingState=this.states.find(opt => opt.label === this.newOrEditERPAddress.state).value;

            this.showAddBillingModal=true;
        }
    }catch(error)//RWPS-5153 start
    {
        processAndLogJSError(error, this.fileName, this.moduleName, 'openEditBillTo');
    }//RWPS-5153 end
    }

    redirectToAddAddress(event)
    {
        this.customEvent('addAddress');
    }

     //New changes based on ERP Address End
     cancelBillingAddressEdit(event){
        this.showAddBillingModal=false;
        this.resetValueAfterCancel(); //RWPS-2372
     }
     //RWPS-3764 start
     handleAccountKeydown(event) {
        if (event.key === 'Enter' || event.keyCode === 13) {
            event.preventDefault();
            this.handleActiveAccountChange(event);
        }
    }
    handleKeyAction(event) {
        if (event.key === 'Enter' || event.keyCode === 13) {
            event.preventDefault();
            this.redirectToAddAddress(event);
        }
    }
    handleKeyActionOpenEditBillTo(event) {
        if (event.key === 'Enter' || event.keyCode === 13) {
            event.preventDefault();
            this.lastFocusedElement = event.currentTarget;//RWPS-4087
            this.openEditBillTo(event);
        }
    }
    handleKeyActionAddressPopUp(event) {
        if (event.key === 'Enter' || event.keyCode === 13) {
            event.preventDefault();
            this.lastFocusedElement = event.currentTarget;//RWPS-4087
            this.openBillToAddressPopUp(event);
        }
    }
    handleKeyActionEventFromBilling(event) {
        if (event.key === 'Enter' || event.keyCode === 13) {
            event.preventDefault();
            this.handleAddAddressEventFromBilling(event);
        }
    }
    
    
    //RWPS-3764 end
    //RWPS-4087 start
    handleModifyAddressKeydown(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            this.handleModifyAddressEventFromBilling(event);
        }
    }
    handleSaveKeyDownAccount(event) {
        if (event.key === 'Enter' || event.keyCode === 13) {
            event.preventDefault();
            if (this.showSpinner) {
                return;
            }
            event.target.click();
        }
    }
    
    handleOpenAddressKeydown(event) {
        if (event.key === 'Enter' || event.keyCode === 13) {
            event.target.click();
            event.preventDefault();
            event.stopPropagation();
        }
    }
    //RWPS-4087 end

}