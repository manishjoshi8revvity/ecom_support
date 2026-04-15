import { LightningElement,api,track,wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { validateAddressForOrder } from 'c/ecom_util';
import {publish, MessageContext} from 'lightning/messageService';
import contextApi from 'commerce/contextApi';
import communityId from '@salesforce/community/Id';
import ECOM_MESSAGE from '@salesforce/messageChannel/ecom_MessagingChannel__c';
import getInvoiceAndOrderDetails from '@salesforce/apex/ECOM_InvoiceController.getInvoiceAndOrderDetails';
import invoicePDFCall from '@salesforce/apex/ECOM_InvoiceController.invoicePDFCall';
import submitCase from '@salesforce/apex/ECOM_InvoiceController.submitCase';
import getProdImages from '@salesforce/apex/ECOM_OrderHistoryController.getProdImages';
import ssrc_ECOM_Theme from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import sres_ECOM_CartIcons from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import FORM_FACTOR from '@salesforce/client/formFactor';
import ECOM_InvoiceNeedHelp from '@salesforce/label/c.ECOM_InvoiceNeedHelp';
import ECOM_InvoiceNeedHelpSubline from '@salesforce/label/c.ECOM_InvoiceNeedHelpSubline';
import ECOM_InvoiceHelpRequestSuccess from '@salesforce/label/c.ECOM_InvoiceHelpRequestSuccess';
import ECOM_E_Invoice_Requirements from '@salesforce/label/c.ECOM_E_Invoice_Requirements';
import ECOM_InvoiceMailingAddress from '@salesforce/label/c.ECOM_InvoiceMailingAddress';
import ECOM_PaymentInformation from '@salesforce/label/c.ECOM_PaymentInformation';
import ECOM_InvoicePOHeading from '@salesforce/label/c.ECOM_InvoicePOHeading';
import ECOM_InvoiceDownload from '@salesforce/label/c.ECOM_InvoiceDownload';
import ECOM_InvoiceDownloadFailureMessage from '@salesforce/label/c.ECOM_InvoiceDownloadFailureMessage';
import ECOM_InvoiceDownloadPopupFailureMessage from '@salesforce/label/c.ECOM_InvoiceDownloadPopupFailureMessage';
import LBL_URL_PATH_SEPARATOR from '@salesforce/label/c.ECOM_UrlPathSeparator';
import LBL_CMS_PARAM_PREFIX  from '@salesforce/label/c.ECOM_CMSPunchoutLoginParameter';
import LBL_CMS_BUY_PAGE  from '@salesforce/label/c.ECOM_CMSBuyPage';
import ECOM_Tariff_Surcharge  from '@salesforce/label/c.ECOM_Tariff_Surcharge';//RWPS-3026
import recipientTitle from '@salesforce/label/c.ecom_Attention_Recipient_Title';//RWPS-4824
import deliveryInstructionNew from '@salesforce/label/c.ECOM_DeliveryInstructionNew';//RWPS-4825
import ECOM_Subtotal_IncludingShipping from '@salesforce/label/c.ECOM_Subtotal_IncludingShipping';//RWPS-5283

const CARDTYPE_IMAGE_MAP = {
    Visa : 'visaimg',
    AMEX : 'ameximg',
    MC : 'mastercardimg'
}

const NAVIGATE_TO_PDP = 'PDP';
const CMS_NAVIGATION = 'CMSNavigation';

export default class Ecom_invoiceDetails extends NavigationMixin(LightningElement) {

    @wire(MessageContext)
    messageContext;

    labels={
        ECOM_InvoiceNeedHelp,
        ECOM_InvoiceNeedHelpSubline,
        ECOM_InvoiceHelpRequestSuccess,
        ECOM_E_Invoice_Requirements,
        ECOM_InvoiceMailingAddress,
        ECOM_PaymentInformation,
        ECOM_InvoicePOHeading,
        ECOM_InvoiceDownload,
        ECOM_InvoiceDownloadFailureMessage,
        LBL_URL_PATH_SEPARATOR,
        LBL_CMS_PARAM_PREFIX,
        LBL_CMS_BUY_PAGE,
        ECOM_Tariff_Surcharge,//RWPS-3026
        recipientTitle,//RWPS-4824
        deliveryInstructionNew,//RWPS-4824
        ECOM_Subtotal_IncludingShipping//RWPS-5283
    };

    showSpinner = false;
    invoiceCall = false;
    invoiceFailure = false;
    invoiceId = '';
    orderId='';
    showDisputeForm = false;
    isSubmitDisputeDisabled = true;
    reasonValue='';
    reasonDesc = '';
    descEmpty = false;
    showSuccessModal = false;
    // ECOM -1933 variable additions
    billToFieldValidationJSON;
    billToFieldValidationObj;
    validationFields = [];
    isValidatedFields = false;
    // Changes End
    currencyDisplayAs='code';
    originalOrderId;
    orderNumber;
    sapOrderNumber;
    billingAddress = {};
    shippingAddress = {};
    mailingAddress = {};
    promoCode;
    isPromoApplied = false;
    quoteNumber;
    cardPayment;
    invoiceNumber;
    poNumber;
    invoiceDate;
    totalItems;
    subtotal;
    tax;
    total;
    currencyCode;
    //ECOM-1931 - Gaurang - variables declared for invoice url - 24 May 2024 - starts
    downloadUrl;
    //RWPS-1990 - Sathiya - changes for enabling download invoice button - start
    isPDFEnabled = false;
    //RWPS-1990 - Sathiya - changes for enabling download invoice button - end
    externalInvoiceNumber;
    invoiceSalesOrg;
    //ECOM-1931 - Gaurang - variables declared for invoice url - 24 May 2024 - ends
    @track invoiceLines=[];

    productImages=[];

    caseNumber='';

    // variables declaired for ECOM-1947 by sathiya
    @track isEInvoiceAvailable = false;
    invoiceValidationFields = [];
    invoiceFieldValidationJSON;
    invoiceFieldValidationObj;
    @track isInvoiceEditMode = false;
    @track isInvoiceReadMode = false;
    @track isInvoiceOrderMode = true;

    accNumber;
    accName;

    isInvoiceMailingAddress;
    invoiceFailureMessage;

    sidebarCSS='';
    middleSpaceCSS = '';
    mainSectionCSS = '';

    totalTarrifSurcharge;//RWPS-3026
    showTariffSurcharge = false; // RWPS-3026
    #escapeKeyCallback; // RWPS-4087
    lastFocusedElement;//RWPS-4087

    get showCardImg(){
        return this.cardPayment?.CardType ? true : false;
    }

    //ECOM-112 - garora@rafter.one - 17 May 2024 - added conditional variables to hide/show on UI - starts
    get showMailingAddress(){
        return (this.isInvoiceMailingAddress) && (this.mailingAddress.companyName || this.mailingAddress.street || 
            this.mailingAddress.city || this.mailingAddress.state || 
            this.mailingAddress.postalCode || this.mailingAddress.country) ? true : false;
    }

    get showPaymentInformation(){
        return (this.cardPayment || this.poNumber || this.quoteNumber) ? true : false;
    }

    get showActiveAccount(){
        return (this.accName || this.accNumber) ? true : false;
    }
    //ECOM-112 - garora@rafter.one - 17 May 2024 - added conditional variables to hide/show on UI - ends

    get cardTypeImg(){
        return this.images[CARDTYPE_IMAGE_MAP[this.cardPayment?.CardType]];
    }

    get showRecipientSection(){
        return (this.recipient || this.specialInstructions) ? true:false;
    }

    images = {
        dashboard:ssrc_ECOM_Theme + '/img/dashboard.png',
        logout:ssrc_ECOM_Theme + '/img/logout.png',
        back:ssrc_ECOM_Theme+'/img/back.png',
        orderagain:ssrc_ECOM_Theme + '/img/orderagainpurple.svg',
        backicon:ssrc_ECOM_Theme + '/img/backicon.svg',
        visaimg: ssrc_ECOM_Theme + '/img/visa.png',
        ameximg: ssrc_ECOM_Theme + '/img/amex.svg',
        mastercardimg: ssrc_ECOM_Theme + '/img/mastercard.svg',
        needhelpicon: ssrc_ECOM_Theme + '/img/needhelpicon.svg',
        //invoiceSpinner: ssrc_ECOM_Theme + '/img/invoiceDownloadSpinner.svg',
        //successIcon: ssrc_ECOM_Theme + '/img/green-check.svg',
        placeholderimg:sres_ECOM_CartIcons + '/img/placeholder.png',
    }

    options = [
        { label:'Complaint', value:'Complaint'},
        { label:'Need help', value:'Need help'}
    ]

    @api  
    device = {
        isMobile : FORM_FACTOR==='Small',
        isDesktop : FORM_FACTOR==='Large' || FORM_FACTOR==='Medium'    
    }

    connectedCallback(){
        this.loadBasedOnDeviceType();
        this.showSpinner = true;
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString);
        this.invoiceId = urlParams.get('invoiceid');
        this.orderId = urlParams.get('orderid');
        const result = contextApi.getSessionContext();
        result.then((response) => {
            this.effectiveAccountId = response.effectiveAccountId;
        }).catch((error) => {

        });
        if(this.invoiceId!=undefined && this.invoiceId!=''){
            this.getInvoice();
        }
        // RWPS-4087 start
        this.#escapeKeyCallback = this.escapeKeyCallback.bind(this);
        document.addEventListener('keydown', this.#escapeKeyCallback);
    
    }
    disconnectedCallback() {
        document.removeEventListener('keydown', this.#escapeKeyCallback);
    }

    escapeKeyCallback(event) {
        if (event.key === 'Escape' || event.keyCode === 27) {
            if(this.showSuccessModal) {
                this.closeSuccessModal();
            }
            if(this.showDisputeForm) {
                this.handleDisputeScreenClose();
            }
        }
    }// RWPS-4087 end

    loadBasedOnDeviceType() {
        var width = (window.innerWidth > 0) ? window.innerWidth : screen.width;
        //Tab UI fix - Gaurang - 17 July 2024
        if(FORM_FACTOR==='Medium' || (width==1025)){
            this.sidebarCSS = 'slds-large-size_12-of-12 slds-small-size_12-of-12 slds-medium-size_12-of-12 slds-size_12-of-12';
            this.middleSpaceCSS = 'doNotDisplay';
            this.mainSectionCSS = 'slds-large-size_12-of-12 slds-small-size_12-of-12 slds-medium-size_12-of-12 slds-size_12-of-12'
        }
        else{
            this.sidebarCSS = 'slds-large-size_3-of-12 slds-small-size_3-of-12 slds-medium-size_7-of-12 slds-size_3-of-12';
            this.middleSpaceCSS = 'slds-large-size_1-of-12 slds-small-size_1-of-12 slds-medium-size_1-of-12 slds-size_1-of-12';
            this.mainSectionCSS = 'slds-large-size_8-of-12 slds-small-size_12-of-12 slds-medium-size_8-of-12 slds-size_8-of-12';
        }
    }

    get resolvedEffectiveAccountId() {
        const effectiveAccountId = this.effectiveAccountId || '';
        let resolved = null;
        if (
            effectiveAccountId.length > 0 &&
            effectiveAccountId !== '000000000000000'
        ) {
            resolved = effectiveAccountId;
        }
        return resolved;
    }

    getInvoice(){
        getInvoiceAndOrderDetails({
            orderId: this.orderId,
            invoiceId: this.invoiceId
        })
        .then((result)=>{
            if(result.Status === 'Success'){
                let orderModel = result?.orderModel;
                this.billToFieldValidationJSON = result?.billToValidationFields;
                if(this.billToFieldValidationJSON != null){
                    this.billToFieldValidationObj = JSON.parse(this.billToFieldValidationJSON);
                }
                orderModel = validateAddressForOrder(orderModel, this.billToFieldValidationObj);
                this.validationFields = orderModel?.validationFields;
                this.isValidatedFields = orderModel?.isValidatedFields;
                // ECOM -1947 for new field validations by sathiya
                let invoiceModel = JSON.parse(JSON.stringify(orderModel));
                this.invoiceFieldValidationJSON = result?.invoiceValidationFields;
                if(this.invoiceFieldValidationJSON != null){
                    this.invoiceFieldValidationObj = JSON.parse(this.invoiceFieldValidationJSON);
                }
                let validationCountry = '';
                if(result?.orderModel?.billingAddress?.country != null){
                    validationCountry = result?.orderModel?.billingAddress?.country.toLowerCase();
                }
                if(validationCountry != null && validationCountry != undefined){
                    invoiceModel = validateAddressForOrder(invoiceModel, this.invoiceFieldValidationObj);
                    this.invoiceValidationFields = invoiceModel?.validationFields;
                    this.isEInvoiceAvailable = invoiceModel.isValidatedFields;
                }
                // Changes End
                this.originalOrderId = result?.orderModel?.id;
                this.orderNumber = result?.orderModel?.orderNumber;
                this.sapOrderNumber = result?.orderModel?.sapOrderNumber;
                this.orderDate =new Date(result?.orderModel?.createdDate);
                this.shippingAddress = result?.orderModel?.shippingAddress;
                this.billingAddress = result?.orderModel?.billingAddress;
                this.mailingAddress = result?.orderModel?.mailingAddress;
                this.promoCode = result?.orderModel?.promoCode;
                this.accName = result?.orderModel?.accountName;
                this.accNumber = result?.orderModel?.accountNumber;
                if(this.promoCode){
                    this.isPromoApplied = true;
                }
                this.quoteNumber = result?.orderModel?.quoteNumber;
                this.invoiceNumber = result?.orderModel?.invoice.name;
                this.poNumber = result?.orderModel?.poNumber;
                this.invoiceDate = result?.orderModel?.invoice.invoiceDate;
                this.totalItems = result?.orderModel?.invoice.totalItems;
                this.subtotal = result?.orderModel?.invoice.subtotal;
                this.tax = result?.orderModel?.invoice.tax;
                this.total = result?.orderModel?.invoice.total;
                this.currencyCode = result?.orderModel?.invoice.currencyIsoCode;
                this.invoiceLines = result?.orderModel?.invoice.invoiceLines;
                //ECOM-1931 - Gaurang - changes for download invoice - starts
                this.externalInvoiceNumber = result?.orderModel?.invoice.invoiceNumber;
                this.invoiceSalesOrg = result?.orderModel?.salesOrg;
                this.downloadUrl = result?.orderModel?.invoice.downloadUrl;
                //ECOM-1931 - Gaurang - changes for download invoice - ends
                //RWPS-1990 - Sathiya - changes for enabling download invoice button - start
                this.isPDFEnabled = result?.orderModel?.invoice?.isPDFEnabled;
                //RWPS-1990 - Sathiya - changes for enabling download invoice button - ends
                this.cardPayment = result?.CardPaymentMethod;
                this.recipient = result?.orderModel?.attentionRecipient;
                this.specialInstructions = result?.orderModel?.deliveryDetails;
                this.isInvoiceMailingAddress = result?.orderModel?.isInvoiceMailingAddress;
                this.showSpinner = false;
                //this.getProductImages();
                console.log('Invoices ::', JSON.stringify(this.invoiceLines));
                // RWPS-3026 START
                let totalSurcharge = 0;
                for(let i in this.invoiceLines){
                    if (this.invoiceLines[i].tariffSurcharge != null && this.invoiceLines[i].tariffSurcharge != 0) {
                        totalSurcharge += this.invoiceLines[i].tariffSurcharge;
                        this.invoiceLines[i].showTariffSurcharge = true;
                    } else {
                        this.invoiceLines[i].showTariffSurcharge = false;
                    }
                } 
                if(totalSurcharge > 0){
                    this.totalTarrifSurcharge = totalSurcharge;
                    // RWPS-3026 Added below logic as SAP is sending tariff in the invoice line in sub total field
                    if (this.subtotal != null && this.subtotal > 0) {
                        this.subtotal = this.subtotal - totalSurcharge;
                    }
                }
                // RWPS-3026 END
            }

        })
        .catch((error)=>{
            console.log('Error in fetching invoice: '+JSON.stringify(error));
        })
    }

        // Fetch product images from Apex.
        getProductImages() {
            let partIds = []
            for (let i = 0; i < this.invoiceLines.length; i++) {
                if(this.invoiceLines[i].productId!=undefined && this.invoiceLines[i].productId!=null && this.invoiceLines[i].productId!=''){
                    partIds.push(this.invoiceLines[i].productId);
                }
            }

            getProdImages({
                productIds: partIds,
                communityId: communityId
            }).then((result) => {
                this.productImages = result;
                if(this.productImages){
                    let tempLines = this.invoiceLines;
                    tempLines.forEach(item=>{
                        if(this.productImages[item.productId] !=undefined && this.productImages[item.productId] !=null && this.productImages[item.productId] !=''){
                            item.imgUrl = this.productImages[item.productId];
                        }
                    });
                    this.invoiceLines = tempLines;
                }
                }).catch((error) => {
                    console.log('ProductImages error: '+JSON.stringify(error));

                });
        }

    goBackToOrderHistory(){
        window.history.back();
    }

    downloadInvoice(){
        this.invoiceCall = true;
        if(this.downloadUrl!=null && this.downloadUrl!='' && this.downloadUrl!=undefined){
            this.invoiceCall = false;
            this.invoiceFailure = false;
            this.navigateToDownloadPage();
        }
        else{
            let invoicePDFMap = {
                invoiceNumber: this.externalInvoiceNumber,
                invoiceId: this.invoiceId,
                salesOrg: this.invoiceSalesOrg
            }
    
            invoicePDFCall({
                invoice: invoicePDFMap
            })
            .then((result)=>{
                if(result.Status=='Success'){
                    this.downloadUrl = result.downloadUrl;
                    this.invoiceCall = false;
                    this.invoiceFailure = false;
                    this.navigateToDownloadPage();
                }
                else{
                    this.invoiceCall = false;
                    this.invoiceFailure = true;
                    this.invoiceFailureMessage = ECOM_InvoiceDownloadFailureMessage;
                }
            })
            .catch((error)=>{
                this.invoiceCall = false;
                this.invoiceFailure = true;
                this.invoiceFailureMessage = ECOM_InvoiceDownloadFailureMessage;
                console.log('Error in pdf: '+error);
            });
        }
    }

    navigateToDownloadPage(){
        try{
            var newwindow = window.open(this.downloadUrl);
            newwindow.focus();
            newwindow.onblur = function(){ 
                newwindow.close(); 
            };
        }
        catch(error){
            this.invoiceFailure = true;
            this.invoiceFailureMessage = ECOM_InvoiceDownloadPopupFailureMessage;
        }

    }

    handleDisputeScreenOpen(){
        this.showDisputeForm = true;
         //RWPS-4087 start
         requestAnimationFrame(() => {
            const modal = this.template.querySelector(`[data-id="disputeFormDialog"]`);
            if (modal) {
                modal.focus();
            }
        }); //RWPS-4087 end
    }

    handleDisputeScreenClose(){
        this.refs.reasonDesc.classList.remove("slds-has-error");
        this.descEmpty = false;
        this.isSubmitDisputeDisabled = true;
        this.reasonValue='';
        this.reasonDesc = '';
        this.showDisputeForm = false; 
        //RWPS-4087 start
        if (this.lastFocusedElement) {
            this.lastFocusedElement.focus();
            this.lastFocusedElement = null; 
        }//RWPS-4087 end
        
    }

    handleDisputeReason(event){
        this.reasonValue = event.target.value;
        if(this.reasonValue.length>0 && this.reasonDesc.length>0){
            this.isSubmitDisputeDisabled = false;
        }
        else{
            this.isSubmitDisputeDisabled = true;
        }
    }

    handleReasonDescription(event){
        this.reasonDesc = event.target.value;
        if(this.reasonDesc.length==0){
            this.refs.reasonDesc.classList.add("slds-has-error");
            this.descEmpty = true;
        }
        if(this.reasonDesc.length>0){
            this.refs.reasonDesc.classList.remove("slds-has-error");
            this.descEmpty = false;
        }
        if(this.reasonValue.length>0 && this.reasonDesc.length>0){
            this.isSubmitDisputeDisabled = false;
        }
        else{
            this.isSubmitDisputeDisabled = true;
        }
    }

    handleSubmitCase(){
        this.showSpinner = true;
        this.refs.reasonDesc.classList.remove("slds-has-error");
        this.descEmpty = false;
        let caseMap = {
            subject : this.reasonValue,
            notes : this.reasonDesc,
            salesOrg : this.invoiceSalesOrg,
            InvoiceNumber : this.externalInvoiceNumber
        }
        submitCase({
            caseMap: caseMap
        }).then((result)=>{
            if(result.Status == 'Success'){
                this.caseNumber = result.CaseNumber;
                this.showSuccessModal = true;
                //RWPS-4087 start
                requestAnimationFrame(() => {
                    const modal = this.template.querySelector(`[data-id="successDialog"]`);
                    if (modal) {
                        modal.focus();
                    }
                }); //RWPS-4087 end
                this.handleDisputeScreenClose();
                this.showSpinner = false;
            }
            else{
                this.showSpinner = false;
            }
        })
        .catch((error)=>{
            console.log('CS Error: '+JSON.stringify(error));
            this.showSpinner = false;
        });        
    }

    closeSuccessModal(){
        this.showSuccessModal = false;
    }

    //UI Fix - Gaurang - 12 July 2024
    navigateToPDP(event) {
        let payLoad = {
            message: NAVIGATE_TO_PDP,
            type: CMS_NAVIGATION,
            partNumber: event.target.dataset.part,
            url: event.target.dataset.url || ''
        };
        publish(this.messageContext, ECOM_MESSAGE, payLoad);
    }
}