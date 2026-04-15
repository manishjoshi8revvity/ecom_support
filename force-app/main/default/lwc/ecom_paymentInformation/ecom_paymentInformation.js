import { LightningElement,track,api,wire } from 'lwc';
import ssrc_ECOM_Theme from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import checkIfPoUsed from '@salesforce/apex/ECOM_CheckoutController.checkIfPoUsed';
import repriceCart from '@salesforce/apex/ECOM_CartController.repriceCart';
import placeOrder from '@salesforce/apex/ECOM_CheckoutController.placeOrder';
import createCreditCardPayment from '@salesforce/apex/ECOM_CheckoutController.createCreditCardPayment';
import createPaymentLogs from '@salesforce/apex/ECOM_CheckoutController.createPaymentLogs';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import { getRecord } from 'lightning/uiRecordApi';
import UserFirstName from '@salesforce/schema/User.FirstName';
import UserEmail from '@salesforce/schema/User.Email';
import UserLastName from '@salesforce/schema/User.LastName';
import UserPhone from '@salesforce/schema/User.Phone';
import ECOM_DATALAYERCHANNEL from '@salesforce/messageChannel/ecom_DataLayer__c';
import {publish, MessageContext} from 'lightning/messageService'
import { NavigationMixin } from 'lightning/navigation';
import Id from '@salesforce/user/Id';
import ECOM_MESSAGE from '@salesforce/messageChannel/ecom_MessagingChannel__c';
import ECOM_100101 from '@salesforce/label/c.ECOM_100101';
import ECOM_106002 from '@salesforce/label/c.ECOM_106002';
import SubmitForApproval from '@salesforce/label/c.ECOM_SubmitForApproval';
//Gaurang - ECOM-128 - 3 June 2024 - added checks for customer impersonation - starts
import ECOM_CSR_Checkout_Message from '@salesforce/label/c.ECOM_CSR_Checkout_Message';
import {getCookieByName} from 'c/ecom_util';
//Gaurang - ECOM-128 - 3 June 2024 - added checks for customer impersonation - ends
// Labels added for product tnc  ECOM-123 by sathiya
import ECOM_agreeTo from '@salesforce/label/c.ECOM_I_Agree_To';
import ECOM_termsNConditions from '@salesforce/label/c.ECOM_Terms_And_Conditions';
import ECOM_productTermsLink from '@salesforce/label/c.ECOM_Product_Terms_Link';
import ECOM_productTermsRUO from '@salesforce/label/c.ECOM_Product_Terms_ROU';
// changes End
import ECOM_productTermsRUOCheckbox from '@salesforce/label/c.ECOM_Product_Terms_ROU_Checkbox'; //RWPS-1911
import ECOM_Purchase_Order_Value from '@salesforce/label/c.ECOM_Purchase_Order_Value'; //RWPS-4823
import ECOM_Purchase_Order_Sub_Title from '@salesforce/label/c.ECOM_Purchase_Order_Sub_Title'; //RWPS-4823

const SNAPPAY_ENVIRONMENT = 'SnapPay_Environment';
const SNAPPAY_AUTHCODE = 'Api_Auth_Code';
const SNAPPAY_ACCOUNTID = 'SnapPay_AccountId';
const SNAPPAY_CUSTOMERID = 'SnapPay_CustomerId';
const SNAPPAY_MERCHANTID = 'SnapPay_MerchantId';
const SF_ENVIRONMENT = 'Stage';
const ZERO_AMOUNT = 0;
const NAVIGATE_TO_TERMCONDITION= 'Terms & Conditions';
const CMS_NAVIGATION = 'CMSNavigation';

export default class Ecom_paymentInformation extends  NavigationMixin(LightningElement) {

    @api effectiveAccountId;
    @api cartId;
    @api isPaymentReadMode;
    @api isPaymentEditMode;
    @api cartSummary;
    @api cartItems;
    @api totalSaving;
    @api billingAddress;
    @api contactInfo;
    @api paymentDataMap ={};
    @api defaultShipToSAPNumber;
    @track showModal=false;
    @track isCreditCardChecked = false;
    @track isPurchaseOrderChecked=false;
    creditCardDetailsAvailable = true;
    @api promoCode;
    @track quoteNumber;
    poNumber;
    @api
    showCreditCard = false;
    @api
    approvalNeeded = false;
    // Variables added for product tnc  ECOM-123 by sathiya
    @api isProductTnc = false;
    @api productTnc;
    @api isProductTnc_RUO = false;
    @api productTnc_RUO;
    isProductPoTcChecked = false;
    isProductCcTcChecked = false;
    isProductPoTcRUOChecked = false;
    isProductCcTcRUOChecked = false;
    // Changes End by sathiya
    @track poAlreadyExist = false;
    @track
    images = {
        visaimg: ssrc_ECOM_Theme + '/img/visa.png',
    }
     hppFormPath = ssrc_ECOM_Theme+'/js/HPPForm.js';
     globalHppFormPath = ssrc_ECOM_Theme+'/js/globalHPPForm.js';
     interopForm = ssrc_ECOM_Theme + '/js/InteropForm.js';
     firstName;
     lastName;
     email;
     phone;
    paymentScriptLoaded = false;
    paymentMethod='';
    isMakePaymentBtnDisabled = true;
    isSubmitOrderBtnDisabled = true;
    @track paymentCard = 'ecom-c-card-unchecked';
    @track POCard = 'ecom-c-card-unchecked ecom-mt-16';
    @track poClass = 'slds-size_1-of-12';
    @track shippingLabelClass = 'ecom-shipping-label';
    @track headerMargin16 = 'ecom-mt-16';
    @track headerMargin32 = 'ecom-mt-32'

      // RWPS-1285
      @api selectedDate;
      @api endUserForTradeChecked;
      @api endUserDetails;
      @api invoiceEmailId;//RWPS-1882

    @api paymentMdtMap;
    showSpinner = false;
    message;
    type;
    show;
    timeSpan = 3000;
    showCSRMsg = false;//Gaurang - ECOM-128 - 3 June 2024 - added checks for customer impersonation

    @api
    isTestingUser; //RWPS-5436

    @api
    orgDetails //RWPS-5436

    @api
    configurationDetails; //RWPS-5436

    labels={
        SubmitForApproval,
        ECOM_CSR_Checkout_Message, //Gaurang - ECOM-128 - 3 June 2024 - added checks for customer impersonation
        ECOM_agreeTo,   // sathiya - ECOM-123 - Added for Product T & C
        ECOM_termsNConditions, // sathiya - ECOM-123 - Added for Product T & C
        ECOM_productTermsLink, // sathiya - ECOM-123 - Added for Product T & C
        ECOM_productTermsRUO, // sathiya - ECOM-123 - Added terms for ROU
        ECOM_productTermsRUOCheckbox, //RWPS-1911
        ECOM_Purchase_Order_Value, //RWPS-4823
        ECOM_Purchase_Order_Sub_Title //RWPS-4823
    };

    get getTermsLabelRUO(){
        let tncRUOLabel = this.labels.ECOM_productTermsRUO;
        tncRUOLabel = tncRUOLabel.replace('{0}', this.productTnc_RUO);
        return tncRUOLabel;
    }

    //RWPS-5436
    get isTestingMode() {
        return (this.orgDetails && this.orgDetails[0] && this.orgDetails[0].IsSandbox && this.orgDetails[0].IsSandbox == true && this.isTestingUser == true) || (this.isTestingUser == true) ? true : false;
    }

    //Gaurang - ECOM-128 - 3 June 2024 - added checks for customer impersonation - starts
    connectedCallback(){
        let isCSR = getCookieByName('apex__IsCSR');
        //RWPS-5436
        if (this.isTestingMode == true) {
            this.poNumber = this.configurationDetails?.orderPONumberForTestUser || '';
        }
        //RWPS-5436
        if(isCSR){
            this.isSubmitOrderBtnDisabled = true;
            this.isMakePaymentBtnDisabled = true;
            this.showCSRMsg = true;//Gaurang - ECOM-128 - 3 June 2024 - added checks for customer impersonation
            this.handleRepirceCart(this.cartId, this.promoCode);//RWPS-3812
        }
    }
    //Gaurang - ECOM-128 - 3 June 2024 - added checks for customer impersonation - end

    @wire(MessageContext)
    messageContext;
    @wire(getRecord, { recordId: Id, fields: [UserFirstName, UserLastName, UserEmail,UserPhone ]})
    currentUserInfo({error, data}) {
        if (data) {
            this.firstName = data.fields.FirstName.value;
            this.email = data.fields.Email.value;
            this.lastName = data.fields.LastName.value;
            this.phone = data.fields.Phone.value;
        } else if (error) {
         console.log('error',error)
        }
    }
    renderedCallback() {
        if(!this.paymentScriptLoaded){
            Promise.all([
                loadScript(this, ssrc_ECOM_Theme + '/js/payment.js'),
                loadScript(this, this.paymentMdtMap.get(SNAPPAY_ENVIRONMENT) == SF_ENVIRONMENT ? this.hppFormPath : this.globalHppFormPath),
                loadScript(this, ssrc_ECOM_Theme + '/js/InteropForm.js'),
            ]).then(() => {
                this.paymentScriptLoaded = true;
            });
        }
        if(!this.showCreditCard){
            this.isPurchaseOrderChecked = true;
            this.isCreditCardChecked = false
            this.isCcTcChecked = false;
            this.isMakePaymentBtnDisabled = true;
            this.paymentMethod = 'po';
            this.paymentCard = 'ecom-c-card-unchecked';
            this.POCard = 'ecom-mt-16';
            this.poClass = 'slds-size_1-of-12 ecom-hide';
            this.shippingLabelClass = 'ecom-shipping-label ecom-hide';
            this.headerMargin16 = '';
            this.headerMargin32 = 'ecom-mt-16'
        }
    }

    handleCardDetailsChange(event) {
        this.isCreditCardChecked = event.target.checked;
        this.isPurchaseOrderChecked = false
        this.poNumber = '';
        this.isPoTcChecked = false;
        this.isSubmitOrderBtnDisabled = true;
        this.paymentMethod = 'cc';
        /*14th Nov start*/
        this.paymentCard = 'ecom-c-card-checked';
        this.POCard = 'ecom-c-card-unchecked ecom-mt-16';
        /*14th Nov end*/
    }

    handlePurchaseOrderChange(event){
        this.isPurchaseOrderChecked = event.target.checked;
        this.isCreditCardChecked = false
        this.isCcTcChecked = false;
        this.isMakePaymentBtnDisabled = true;
        this.paymentMethod = 'po';
         /*14th Nov start*/
         this.paymentCard = 'ecom-c-card-unchecked';
         this.POCard = 'ecom-c-card-checked ecom-mt-16';
         /*14th Nov end*/

    }

    handleMakePayment(){
        this.showSpinner = true;
        let defaultShipToSAPNumber =  (this.contactInfo?.ECOM_NeedsVerification__c &&  this.defaultShipToSAPNumber) ? this.defaultShipToSAPNumber :  (!this.contactInfo?.ECOM_NeedsVerification__c && this.billingAddress?.externalId )? this.billingAddress?.externalId :  this.paymentMdtMap.get(SNAPPAY_CUSTOMERID) ;
        let data = {
            street : this.billingAddress?.street?.length > 40 ? '' : this.billingAddress?.street || '',//RWPS-3005
            city : this.billingAddress?.city || '',//'Boston',
            state : this.billingAddress?.state || '',//'Massachusetts',
            zip : this.billingAddress?.zip || '',//'10001',
            country :this.billingAddress?.countryCode || '',//'United States',
            amount : this.contactInfo?.ECOM_NeedsVerification__c|| this.approvalNeeded? ZERO_AMOUNT : this.cartSummary?.grandTotalAmount,// > 1000?1000 :this.cartSummary?.grandTotalAmount || 0,
            hppUrl: this.paymentMdtMap.get(SNAPPAY_ENVIRONMENT) == SF_ENVIRONMENT ? this.hppFormPath : this.globalHppFormPath,
            interopForm : this.interopForm,
            firstName :  this.firstName.length > 20 ? '' : this.firstName || '',//RWPS-3005
            lastName :  this.lastName.length > 20 ? '' : this.lastName || '',//RWPS-3005
            currencycode : this.cartSummary?.currencyIsoCode ||'USD',
            email : this.email||'',
            phone : this.phone || '',
            authCode: this.paymentMdtMap.get(SNAPPAY_AUTHCODE),
            accountId : this.paymentMdtMap.get(SNAPPAY_ACCOUNTID),
            customerId : defaultShipToSAPNumber, //this.paymentMdtMap.get(SNAPPAY_CUSTOMERID),
            merchantId : this.paymentMdtMap.get(SNAPPAY_MERCHANTID+'_'+this.cartSummary?.currencyIsoCode),
            environment : this.paymentMdtMap.get(SNAPPAY_ENVIRONMENT)
        }
        payment.init(data,this);
    }

    handleChange(event){
        if(!(event.target.value)){
            this.isSubmitOrderBtnDisabled = true;
        }
    }

    handlePoChange(event){
        this.poNumber = event.target.value.trim();
        //fire a method to get the data from salesforce if this PO exist
        if(this.poNumber){
            checkIfPoUsed({
                effectiveAccountId: this.effectiveAccountId,
                poNumber: this.poNumber
            }).then((result) => {
                    this.poAlreadyExist = result;
                    if(this.isPoTcChecked && !this.showCSRMsg && ((this.isProductTnc && this.isProductPoTcChecked) || !this.isProductTnc) && ((this.isProductTnc_RUO && this.isProductPoTcRUOChecked) || !this.isProductTnc_RUO)){//Gaurang - ECOM-128 - 3 June 2024 - added checks for customer impersonation
                        this.isSubmitOrderBtnDisabled = false;
                    }
            })
            .catch((error) => {
                this.showMessage(
                    result.ErrorMessage,
                    'error',
                    true
                    );
            });
        }else{
            this.isSubmitOrderBtnDisabled = true;
        }
    }

    openPromoCodeModal(){
        this.template.querySelector('c-ecom_add-promo-code')?.openModal();
    }

    openQuoteModal(){
        this.template.querySelector('c-ecom_quote-number')?.openModal();
    }

    //RWPS-3812 - START
    handleRepirceCart(){

        repriceCart({
            cartId: this.cartId,
            couponCode : this.promoCode
        }).then((result) => {
            if(result?.success){
                if(result?.isPromoApplied){
                    if(!result?.isValidPromo){
                        this.promoCode = '';
                    }
                    //ECOM-1923 - Removed following line - 'saving:result?.salesStatus?.totalSaving,' from the event
                    this.dispatchEvent(
                        new CustomEvent("updatecartsummary",{
                            detail: {
                                isPromoApplied: result?.isPromoApplied,
                                promoCode: result?.osRequest?.promo_code,
                                promoMessage: result?.promoMessage,
                                isValidPromo: result?.isValidPromo ? 'success' :'error',
                            }
                        })
                    );

                }
                this.showSpinner = false;
            }

            }).catch((error) => {
                console.log(' error',error);
        });

    }
    //RWPS-3812 - END

    handlePromoCodeUpdated(event){
        this.promoCode = event.detail.updatedPromoCode;
        this.showSpinner = true;

        repriceCart({
            cartId: this.cartId,
            couponCode : this.promoCode
        }).then((result) => {
            if(result?.success){
                if(result?.isPromoApplied){
                    if(!result?.isValidPromo){
                        this.promoCode = '';
                    }
                    //ECOM-1923 - Removed following line - 'saving:result?.salesStatus?.totalSaving,' from the event
                    this.dispatchEvent(
                        new CustomEvent("updatecartsummary",{
                            detail: {
                                isPromoApplied: result?.isPromoApplied,
                                promoCode: result?.osRequest?.promo_code,
                                promoMessage: result?.promoMessage,
                                isValidPromo: result?.isValidPromo ? 'success' :'error',
                            }
                        })
                    );

                }
                this.showSpinner = false;
            }

            }).catch((error) => {
                console.log(' error',error);
        });
    }

    handleQuoteNumberUpdated(event){
        this.quoteNumber = event.detail.updatedQuoteNumber;
        this.paymentDataMap.quoteNumber = this.quoteNumber ;
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

    handlePublishMsg(data) {

        let payLoad = {
            data: data,
            type: 'DataLayer'
        };
        publish(this.messageContext, ECOM_DATALAYERCHANNEL, payLoad);
    }

    creditCardPaymentResponse(error,message){
        this.createPaymentApplicationLogs(error,message);
        let paymentError = error;
        let paymentDataMap = {};
        let paymentResponse = JSON.parse(message.response);
        if(error==null && paymentResponse?.paymenttransactionid!=null && paymentResponse?.transactionstatus==='Y'){
            paymentDataMap.paymenttransactionid =  (paymentResponse?.paymenttransactionid).toString();
            paymentDataMap.pgtransactionid = paymentResponse?.pgtransactionid;
            paymentDataMap.paymentmode = paymentResponse?.paymentmode;
            paymentDataMap.totaltransactionamount = paymentResponse?.totaltransactionamount;
            paymentDataMap.transactionamount = paymentResponse?.transactionamount;
            paymentDataMap.paymentmethodtype = paymentResponse?.paymentmethodtype;
            paymentDataMap.paymentmethodtoken= paymentResponse?.paymentmethodtoken;
            paymentDataMap.authorizationnumber= paymentResponse?.authorizationnumber;
            paymentDataMap.paymentmethodlast4= paymentResponse?.paymentmethodlast4;
            paymentDataMap.paymentmethodexpirationmonth = paymentResponse?.paymentmethodexpirationmonth;
            paymentDataMap.paymentmethodexpirationyear = paymentResponse?.paymentmethodexpirationyear;
            paymentDataMap.currencycode = paymentResponse?.currencycode;
            paymentDataMap.merchantid = paymentResponse?.merchantid;
            paymentDataMap.pgreturndescription = paymentResponse?.pgreturndescription;
            paymentDataMap.pgtext = paymentResponse?.pgtext;
            paymentDataMap.transactiondate = paymentResponse?.transactiondate;
            paymentDataMap.paymentmethodfirstname = paymentResponse?.paymentmethodfirstname;
            paymentDataMap.paymentmethodlastname = paymentResponse?.paymentmethodlastname;
            paymentDataMap.paymentmethodemail = paymentResponse?.paymentmethodemail;
            paymentDataMap.paymentmethodstreet = paymentResponse?.paymentmethodaddressline1;
            paymentDataMap.paymentmethodcity = paymentResponse?.paymentmethodcity;
            paymentDataMap.paymentmethodstate = paymentResponse?.paymentmethodstate;
            paymentDataMap.paymentmethodcountry = paymentResponse?.paymentmethodcountry;
            paymentDataMap.paymentmethodzip = paymentResponse?.paymentmethodzip;
            paymentDataMap.transactiontype = paymentResponse?.transactiontype;
            paymentDataMap.transactionstatus = paymentResponse?.transactionstatus;
            paymentDataMap.paymentMethod = this.paymentMethod;
            paymentDataMap.quoteNumber= this.quoteNumber;
            paymentDataMap.promoCode= this.promoCode;
            this.createCCPayment(paymentDataMap);
        }else{
            this.showSpinner = false;
            this.dispatchEvent(
                new CustomEvent('paymenterror', {
                    detail: {
                        message: paymentResponse?.returnmessage
                    }
                }, {
                    bubbles: true,
                  })
            );
            window.scroll(0,0);
        }
    }

    createPaymentApplicationLogs(error,message){
        createPaymentLogs({
            error: error,
            response: message.response
        }).then((result) => {
                //console.log(result);
            })
            .catch((error) => {
                console.log(' error',error);
            });
    }

    createCCPayment(paymentDataMap){
        this.showSpinner = true;
        createCreditCardPayment({
            effectiveAccountId: this.effectiveAccountId,
            cartId: this.cartId,
            paymentDataMap: paymentDataMap
        }).then((result) => {
                if(result){
                    if(result.Status == 'Success' && result?.paymentId && result?.paymentAuthorization){
                        paymentDataMap.paymentId = result?.paymentId;
                        paymentDataMap.paymentAuthorization = result?.paymentAuthorization;
                        this.handlePlaceOrder(paymentDataMap);
                    }else{
                        // error in creating payment
                        this.showSpinner = false;
                        this.dispatchEvent(
                            new CustomEvent('paymenterror', {
                                detail: {
                                    message: ECOM_106002
                                }
                            }, {
                                bubbles: true,
                              })
                        );
                        window.scroll(0,0);
                    }
                }
            })
            .catch((error) => {
                this.showSpinner = true;
            });
    }

    handleSubmitOrder(){
        this.showSpinner = true;
        let paymentDataMap = {};
        paymentDataMap.poNumber= this.poNumber;
        paymentDataMap.quoteNumber= this.quoteNumber;
        paymentDataMap.promoCode= this.promoCode;
        paymentDataMap.paymentMethod = this.paymentMethod;
        this.handlePlaceOrder(paymentDataMap);
    }
    handlePlaceOrder(paymentDataMap){
        this.showSpinner = true;
        this.isSubmitOrderBtnDisabled = true;
        // do data validation as well
        placeOrder({
            effectiveAccountId: this.effectiveAccountId,
            cartId: this.cartId,
            paymentDataMap: paymentDataMap,
            acceptedDate: this.selectedDate, //RWPS-1285
            endUserForTrade:this.endUserForTradeChecked, //RWPS-1285
            endUserAddress:this.endUserDetails, //RWPS-1285
            invoiceEmailAddress: this.invoiceEmailId//RWPS-1882
        }).then((result) => {
            this.showSpinner = false;
                if(result){
                    if(result.Status == 'Success' && result.OrderId){
                        this.showSpinner = false;
                        this[NavigationMixin.Navigate]({
                            type: 'standard__webPage',
                                attributes: {
                                url: '/order?recordId='+ result.OrderId
                                }
                            });
                    }
                    else if(result.Status == 'Error'){
                        this.showMessage(
                            ECOM_100101,
                            'error',
                            true
                        );
                        this.isSubmitOrderBtnDisabled = false;
                    }
                }
            })
            .catch((error) => {
                this.isSubmitOrderBtnDisabled = false;
                this.showSpinner = true;
            });
    }

    handleCcTcChange(event){
        this.isCcTcChecked = event.target.checked;
        this.isPoTcChecked =false;
        this.isMakePaymentBtnDisabled = true;
        if(this.isCcTcChecked && !this.showCSRMsg && ((this.isProductTnc && this.isProductCcTcChecked) || !this.isProductTnc) && ((this.isProductTnc_RUO && this.isProductCcTcRUOChecked) || !this.isProductTnc_RUO)){
            this.isMakePaymentBtnDisabled = false;
        }
    }

    handlePoTcChange(event){
        this.isPoTcChecked= event.target.checked;
        this.isCcTcChecked =false;
        this.isSubmitOrderBtnDisabled = true;
        if(this.isPoTcChecked && this.poNumber && !this.showCSRMsg && ((this.isProductTnc && this.isProductPoTcChecked) || !this.isProductTnc) && ((this.isProductTnc_RUO && this.isProductPoTcRUOChecked) || !this.isProductTnc_RUO)){//Gaurang - ECOM-128 - 3 June 2024 - added checks for customer impersonation
            this.isSubmitOrderBtnDisabled = false;
        }
    }
    handleTermAndConditionClick(event){
        event.preventDefault()
        let payLoad = {message: NAVIGATE_TO_TERMCONDITION,
            type: CMS_NAVIGATION,
            partNumber: '',
            url: ''
        };
        publish(this.messageContext, ECOM_MESSAGE, payLoad);
    }
    // RWPS-3826 start
    handleTermAndConditionEnter(event){
        if(event.key === 'Enter' || event.keyCode === 13 || event.key === 'Space' || event.keyCode === 32) { // RWPS-4086
            event.target.click();
        }
    }
    // RWPS-3826 end
    // Changes by sathiya for ECOM-123
    handleProductTncClick(event){
        event.preventDefault();
        window.open(this.labels.ECOM_productTermsLink, '_blank');
    }
    handleProductTcChange(event){
        let isChecked = event.target.checked;
        if(event.currentTarget.dataset.type == 'po'){
            this.isProductPoTcChecked = isChecked;
        } else if(event.currentTarget.dataset.type == 'cc') {
            this.isProductCcTcChecked = isChecked;
        }
        if(event.currentTarget.dataset.type == 'po_RUO'){
            this.isProductPoTcRUOChecked = isChecked;
        } else if(event.currentTarget.dataset.type == 'cc_RUO') {
            this.isProductCcTcRUOChecked = isChecked;
        }
        this.isMakePaymentBtnDisabled = true;
        this.isSubmitOrderBtnDisabled = true;
        if((event.currentTarget.dataset.type == 'po' || event.currentTarget.dataset.type == 'po_RUO') && this.isPoTcChecked && ((this.isProductPoTcChecked && this.isProductTnc) || !this.isProductTnc) && ((this.isProductPoTcRUOChecked && this.isProductTnc_RUO) || !this.isProductTnc_RUO) && this.poNumber && !this.showCSRMsg){
            this.isSubmitOrderBtnDisabled = false;
        } else if((event.currentTarget.dataset.type == 'cc' || event.currentTarget.dataset.type == 'cc_RUO') && this.isCcTcChecked && ((this.isProductCcTcChecked && this.isProductTnc) || !this.isProductTnc) && ((this.isProductCcTcRUOChecked && this.isProductTnc_RUO) || !this.isProductTnc_RUO) && !this.showCSRMsg){
            this.isMakePaymentBtnDisabled = false;
        }
    }
    // Changes End
}