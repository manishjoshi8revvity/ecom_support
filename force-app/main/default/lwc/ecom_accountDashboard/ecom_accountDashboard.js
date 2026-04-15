import { LightningElement,api,track } from 'lwc';
// Import Ecom_util for validation methods
import { validateAddressByFields } from 'c/ecom_util';
import getUser from '@salesforce/apex/ECOM_UserController.getUser';
import getContactDetails from '@salesforce/apex/ECOM_DashboardController.getUserDetails';
import getEmails from '@salesforce/apex/ECOM_DashboardController.getEmailAddresses';
import checkIfCurrentUserIsPunchoutUser from '@salesforce/apex/ECOM_OrderHistoryController.checkIfCurrentUserIsPunchoutUser'; // RWPS-4196
import ssrc_ECOM_Theme from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import { publish,subscribe,unsubscribe,createMessageContext,releaseMessageContext } from 'lightning/messageService';
import DASHBOARD_NAVIGATE_TO from '@salesforce/messageChannel/Dashboard__c';
import { NavigationMixin } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';

import ECOM_AddressRequired from '@salesforce/label/c.ECOM_AddressRequired';
import ECOM_WelcomeBack from '@salesforce/label/c.ECOM_WelcomeBack';
import Ecom_Profile_Settings from '@salesforce/label/c.Ecom_Profile_Settings';
import ECOM_Profile from '@salesforce/label/c.ECOM_Profile';
import ECOM_EmailAddress from '@salesforce/label/c.ECOM_EmailAddress';
import Ecom_Phone_Number from '@salesforce/label/c.Ecom_Phone_Number';
import ECOM_EmailAddresses from '@salesforce/label/c.ECOM_EmailAddresses';
import ECOM_ShippingInformation from '@salesforce/label/c.ECOM_ShippingInformation';
import ECOM_AttentionRecipient from '@salesforce/label/c.ECOM_AttentionRecipient';
import ECOM_SpecialInstructions from '@salesforce/label/c.ECOM_SpecialInstructions';
import ECOM_SpecialInstructionsToProcessOrder from '@salesforce/label/c.ECOM_SpecialInstructionsToProcessOrder';
import ECOM_Accounts from '@salesforce/label/c.ECOM_Accounts';
import ECOM_Edit from '@salesforce/label/c.ECOM_Edit';
import ECOM_ActiveAccountNumber from '@salesforce/label/c.ECOM_ActiveAccountNumber';
import ECOM_CompanyName from '@salesforce/label/c.ECOM_CompanyName';
import ECOM_ShippingAddress from '@salesforce/label/c.ECOM_ShippingAddress';
import ECOM_BillingAddress from '@salesforce/label/c.ECOM_BillingAddress';
import ECOM_InvoiceMailingAddress from '@salesforce/label/c.ECOM_InvoiceMailingAddress';
//js import 
import {parseJSONWOStringify,getFromSessionStorage, SYSTEM_CONSTANTS, getUserConfigData} from 'c/ecom_punchoutUtil';


export default class Ecom_accountDashboard extends NavigationMixin(LightningElement) {
    labels = {
        ECOM_WelcomeBack,
        Ecom_Profile_Settings,
        ECOM_Profile,
        ECOM_EmailAddress,
        Ecom_Phone_Number,
        ECOM_EmailAddresses,
        ECOM_ShippingInformation,
        ECOM_AttentionRecipient,
        ECOM_SpecialInstructions,
        ECOM_SpecialInstructionsToProcessOrder,
        ECOM_Accounts,
        ECOM_Edit,
        ECOM_ActiveAccountNumber,
        ECOM_CompanyName,
        ECOM_ShippingAddress,
        ECOM_BillingAddress,
        ECOM_InvoiceMailingAddress
    };

    isAccountEdit = false;
    isDashboardView = true;
    userDetails=[];
    userBillingAddress;
    userShippingAddress;
    userSoldToAddress;
    userShippingAddressDetails = {};
    accountInfo = {};
    profileInfo = {};
    activeContactId;
    activeAccountId;
    showSpinner = false;
    otherEmails;
    currentFirstName;
    isAddAddress=false;
    isSelectAddress=false;
    redirectUrl ='';
    message ='';
    type='';
    showError=false;
    showAccountNumber=false;
    showAccountName=false;
    timeSpan=0;
    subscription = null;

    // ECOM -1933 variable additions
    billToFieldValidationJSON;
    billToFieldValidationObj;
    billingErpAddress = {}
    // Changes End
    // ECOM - 1939 variable additions
    userInvoiceMailingAddress;
    isInvoiceMailingAddress = false;
    // Changes End
    context = createMessageContext();
    @api fieldsToShow;
    @api recordsToDisplay;

    @api  
    device = {
        isMobile : FORM_FACTOR==='Small',
        isDesktop : FORM_FACTOR==='Large',
        isTablet :FORM_FACTOR==='Medium'
    }

    sidebarCSS='';
    middleSpaceCSS = '';
    mainSectionCSS = '';


    @track
    images = {
        arrowimg: ssrc_ECOM_Theme + '/img/rightarrow.png',
        rightarrow:ssrc_ECOM_Theme + '/img/rightarrow.svg',
    }

    renderDashboard = false // RWPS-4196

    connectedCallback(){

        // RWPS-4196 - START
        checkIfCurrentUserIsPunchoutUser({
        }).then((userResult) => {

            // RWPS-4196 - Moved the existing logic to run after the checkIfCurrentUserIsPunchoutUser is executed.
            this.loadBasedOnDeviceType();
            let userConfig = getUserConfigData();
            this.isDashboardView = false;
            if((userConfig && userConfig.isPunchoutUser) || userResult){ // RWPS-4196 Added userResult in OR clause so that punchoutUser is redirected to Order page when session storage is filled but user is punchout user.
                this.handleOrderPageNav();
            } else {
                this.isDashboardView = true;
                this.showSpinner = true;
                this.getUserInfo();
                //this.getUserDashboardDetails();
                this.getOtherEmails();
                this.showSpinner = false;
                this.getUrlParams();
                this.subscribeNavigationMC();
                this.editAccount();
                this.renderDashboard = true; // RWPS-4196
            }
        }).catch((error) => {
            console.error(error);
        });
        // RWPS-4196 END
    }

    //Tab UI Fix - Gaurang - 18 July 2024
    loadBasedOnDeviceType(){
        var width = (window.innerWidth > 0) ? window.innerWidth : screen.width;
        if(FORM_FACTOR==='Medium' || (width==1025)){
            this.sidebarCSS = 'slds-size_12-of-12';
            this.middleSpaceCSS = 'doNotDisplay';
            this.mainSectionCSS = 'slds-size_12-of-12';
        }
        else{
            this.sidebarCSS = 'slds-size_3-of-12';
            this.middleSpaceCSS = 'slds-size_1-of-12';
            this.mainSectionCSS = 'slds-size_8-of-12';
        }
    }

    getUserInfo(){
        getUser()
        .then(result=>{
            if(result.Success) {
                var contactId=result.User.ContactId;
                this.getUserDashboardDetails(contactId);
            }
        }).catch(error=>{
            this.showSpinner=false;
        });
    }

    getUserDashboardDetails(contactId){
        getContactDetails({contactId:contactId})
        .then((result) => {
            if(result.success){
                console.log('getUserDashboardDetails:', result);
                // ECOM -1933 for new field validations
                this.billToFieldValidationJSON = result?.billToValidationFields;
                if(this.billToFieldValidationJSON != null){
                    this.billToFieldValidationObj = JSON.parse(this.billToFieldValidationJSON);
                }
                // Changes End
                this.userDetails = result.contact;
                this.userShippingAddress = this.handleAddressFormat(result?.shipToAddress||{}, 'shipping');
                this.userBillingAddress = this.handleAddressFormat(result?.billToAddress||{}, 'billing');
                // ECOM -1939 for invoice mailing address by sathiya
                if(result?.invoiceMailingAddress != null){
                    this.userInvoiceMailingAddress = this.handleAddressFormat(result?.invoiceMailingAddress||{}, 'invoice');
                    this.isInvoiceMailingAddress = result?.invoiceMailingAddress?.isShowAddress;
                }
                // Changes End
                this.userSoldToAddress=result.soldToAddress;
                this.accountInfo.sapAccountNumber ='';
                this.showAccountNumber=false;

                // ECOM -1933 for new field validations by sathiya
                var returnBillingErpAdd = validateAddressByFields(result?.billToAddress, this.billToFieldValidationObj);//RWPS-2372
                this.billingErpAddress = returnBillingErpAdd!==undefined?returnBillingErpAdd:this.billingErpAddress; //RWPS-2372
                // Changes End

                if(result.soldToAddress?.id)
                {
                    this.accountInfo.name = result.soldToAddress?.erpAccountName || '';
                    if(this.accountInfo.name!='')
                        this.showAccountName=true;
                    this.accountInfo.sapAccountNumber = result.soldToAddress?.externalId || '';
                    if(this.accountInfo.sapAccountNumber!='')
                    {
                        this.showAccountNumber=true;
                    }

                }else if(result.shipToAddress?.id)
                {
                    this.accountInfo.name = result.shipToAddress?.erpAccountName || '';
                    if(this.accountInfo.name!='')
                        this.showAccountName=true;
                }
                
                /*if(result.billToAddress?.id)
                {
                    this.userBillingAddress.street = result.billToAddress.street;
                    this.userBillingAddress.city = result.billToAddress.city;
                    //this.userBillingAddress.state = result.billToAddress.state;
                    this.userBillingAddress.zip = result.billToAddress.postalCode;
                    this.userBillingAddress.country = result.billToAddress.country;
                }*/
                
                this.activeContactId = this.userDetails?.Id;
                this.activeAccountId = this.userDetails?.AccountId;
                //this.accountInfo.name = this.userDetails?.Account?.Name;
                //this.accountInfo.sapAccountNumber = this.userDetails?.Account?.SAP_Customer_Number_Formatted__c
                this.currentFirstName = this.userDetails?.FirstName;
                this.profileInfo.name = this.userDetails?.Name//+' '+this.userDetails?.LastName;
                this.profileInfo.email = this.userDetails?.Email;
                this.profileInfo.phone = this.userDetails?.Phone;
                this.profileInfo.ext = this.userDetails?.ECOM_Phone_Extension__c;
                this.profileInfo.receipient = this.userDetails?.ECOM_Attention_Recipient__c;
                this.profileInfo.deliveryInfo = this.userDetails?.ECOM_Delivery_Details__c;
                this.profileInfo.specialInst = this.userDetails?.ECOM_Special_Instructions__c;
            }
        })
        .catch((error) => {
            this.userDetails = undefined;
        });
    }

    handleAddressFormat(address, addressType){
        let val='';
        if(address?.showSapName)
        {
            val=this.handleUndefined(address?.sapName)+'\n';
        }
        val+=this.handleUndefined(address?.street)+'\n' +this.handleUndefined(address?.city)+', '+this.handleUndefined(address?.state)+' '+this.handleUndefined(address?.postalCode)+'\n'+
        this.handleUndefined(address?.country);
        return val;
    }


    handleUndefined(addressPart){
        if(addressPart){
            return addressPart;
        } else {
            return '';
        }
    }

    editAccount(){
        if(window.location.href.includes("?")){
            let params;
            params = window.location.href.split("?")[1];
            if(params.includes('accountEdit')){
                this.handleAccountEdit();
            }
        }
    }

    getOtherEmails(){
        getEmails()
        .then((result) => {
           
            if(result){
                this.otherEmails = result.trim();
            }
        })
        .catch((error) => {
            
        });
    }

    handleAccountEdit(){
        this.isDashboardView = false;
        this.isAccountEdit = true;
    }

    handleAccountEditClick(){
        let url = window.location.href;
        let baseUrl =  url.split('/dashboard');
        let finalUrl = baseUrl[0]+'/dashboard?accountEdit';
        window.location.href = finalUrl;
    }

    handleProfileandSettingEdit(){
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/profile-and-settings'
            },
        });
    }

    handleOrderPageNav(){
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/orderHistory'
            ,}
        });
    }

    getUrlParams(){
        if(window.location.href.includes("?")){
            let params;
            let paramValues = [];
            params = window.location.href.split("?")[1];
            if(params.includes('&')){
                paramValues = params.split('&');  
            }else{
                paramValues.push(params);
            }
            this.redirectUrls(paramValues);
        }
    }

    redirectUrls(paramValues){
        for(let param of paramValues){
            if(param.includes('addressStatus')){
                let value = param.split('addressStatus=')[1];
                if(value == 'addAddress'){
                    this.isAddAddress = true;
                } else if(value == 'selectAddress'){
                    this.isSelectAddress = true;
                }
                this.isDashboardView =false;
            } else if(param.includes('url')){
                let value = param.split('url=')[1];
                this.redirectUrl = value;
            }
        }
    }

    handleAddressEvent(event){
        this.resetError();
        let value = event.detail.nextStep;
        if(value == 'addAddress'){
            this.isDashboardView=false;
            this.isAddAddress = true;
            this.isSelectAddress = false;
            this.isAccountEdit=false;
        } else if(value == 'showAddressTab' && this.redirectUrl==''){
            this.isDashboardView=false;
            this.isAddAddress = false;
            this.isSelectAddress = false;
            this.isAccountEdit=true;
        } else if(value == 'showAddressTab' && this.redirectUrl!=''){
           // this.message = 'Address is required to view and edit your profile';
            this.message = ECOM_AddressRequired;
            this.type ='error';
            this.showError = true;
            return;
        } else if(value == 'addAccountorAddress'){
            this.isSelectAddress = true;
            this.isDashboardView = false;
            this.isAddAddress = false;
            this.isAccountEdit=false;
            let tempRef = this; 
            setTimeout(function() {
                tempRef.template.querySelector('c-ecom_account-addresses').handleAddAccountNumber('');
            }, 30);
            
        }
    }

    resetError(){
        this.message = '';
        this.type = '';
        this.showError = false;
    }

    subscribeNavigationMC() {
        if (this.subscription) {
            return;
        }
        this.subscription = subscribe(this.context, DASHBOARD_NAVIGATE_TO, (message) => {
            if(message && message.navigate === 'dashboard'){
                this.isAddAddress = false;
                this.isSelectAddress = false;
                this.isAccountEdit = false;
                this.isDashboardView=true;
                this.getUserDashboardDetails(this.activeContactId);
            }
            if(message.navigate === 'accountEdit'){
                this.handleAccountEdit();
            }
        });
     }
}