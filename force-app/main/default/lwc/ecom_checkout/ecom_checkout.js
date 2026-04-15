import { LightningElement, api, track, wire } from 'lwc';
// Import Ecom_util for validation methods
import { validateFieldsWithRequired } from 'c/ecom_util';
// Changes End
import { NavigationMixin } from 'lightning/navigation';
import ECOM_DATALAYERCHANNEL from '@salesforce/messageChannel/ecom_DataLayer__c';
import {publish, MessageContext} from 'lightning/messageService'
import { isCmsResource, resolve } from 'experience/resourceResolver';
import communityId from '@salesforce/community/Id';
import contextApi from 'commerce/contextApi';
import getCheckoutInItData from '@salesforce/apex/ECOM_CheckoutController.getCheckoutInItData';
import repriceCart from '@salesforce/apex/ECOM_CheckoutController.repriceCart';
import getCreditCollections from '@salesforce/apex/ECOM_CheckoutController.getCreditCollections';
import getUserInfo from "@salesforce/apex/ECOM_CheckoutController.getUserInfo"; 
import updateBillToShipToOnCart from '@salesforce/apex/ECOM_CheckoutController.updateBillToShipToOnCart';
import ssrc_ECOM_Theme from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import getDataLayerDataByCart from '@salesforce/apex/ECOM_DataLayerController.getDataLayerDataByCart';
import getOrganizationDetails from '@salesforce/apex/ECOM_UserController.getOrganizationDetails'; //RWPS-5436
import getTestUserConfigurations from '@salesforce/apex/ECOM_UserController.getTestUserConfigurations'; //RWPS-5436
import { getRecord } from 'lightning/uiRecordApi';
import COUNTRY_FIELD from '@salesforce/schema/User.Country';
import USER_ID from '@salesforce/user/Id';
import IS_PUNCHOUT_VIA_WEB from '@salesforce/schema/User.Contact.ECOM_Punchout_Via_Web__c'; //RWPS-5938
import CURRENCY_FIELD from '@salesforce/schema/User.CurrencyIsoCode';
import getDefaultShipToSAPNumber from '@salesforce/apex/ECOM_CheckoutController.getDefaultShipToSAPNumber';
import ECOM_CreditBlock  from '@salesforce/label/c.ECOM_CreditBlock';
import ECOM_Checkout  from '@salesforce/label/c.ECOM_Checkout';
import ECOM_Items  from '@salesforce/label/c.ECOM_Items';
import ECOM_TotalCost  from '@salesforce/label/c.ECOM_TotalCost';
import ECOM_ShippingAndBilling  from '@salesforce/label/c.ECOM_ShippingAndBilling';
import ECOM_Edit  from '@salesforce/label/c.ECOM_Edit';
import ECOM_EmailNotifications  from '@salesforce/label/c.ECOM_EmailNotifications';
import ECOM_PaymentInformation  from '@salesforce/label/c.ECOM_PaymentInformation';
import ECOM_E_Invoice_Requirements from '@salesforce/label/c.ECOM_E_Invoice_Requirements';
import ECOM_Error  from '@salesforce/label/c.ECOM_Error';
import addressesNotRegisteredError from '@salesforce/label/c.ECOM_AddressesNotRegisteredError';
import creditCardApplicableCountries from '@salesforce/label/c.ECOM_CreditCardApplicableCountries';
//RWPS-1548 - START
import ECOM_AddAddreses  from '@salesforce/label/c.ECOM_AddAddressWarning';
import ECOM_Addressmissing  from '@salesforce/label/c.ECOM_Addressmissing';
import ECOM_Warning  from '@salesforce/label/c.ECOM_Warning';
import ECOM_Close  from '@salesforce/label/c.ECOM_Close';
import sres_ECOM_CartIcons from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import newAddressesNotRegisteredError from '@salesforce/label/c.ECOM_NewAddressesNotRegisteredError';
import deleteDiscontinuedNonSellableProducts from '@salesforce/apex/ECOM_CheckoutController.deleteDiscontinuedNonSellableProducts';//RWPS-2786
import ECOM_MESSAGE from '@salesforce/messageChannel/ecom_MessagingChannel__c';//RWPS-2786
import ECOM_Non_Sellable_Error_Message from '@salesforce/label/c.ECOM_Non_Sellable_Error_Message';//RWPS-2786
import {processAndLogJSError} from 'c/ecom_util'; // RWPS-5153
import logFieldError from '@salesforce/apex/ECOM_Util.logFieldError';//RWPS-5153
import ECOM_TEST_USER_FIELD from '@salesforce/schema/User.ECOM_Is_Test_User__c'; //RWPS-5436


//RWPS-1548 - END


export default class Ecom_checkout extends NavigationMixin(LightningElement) {

    labels = {
        ECOM_Checkout,
        ECOM_Items,
        ECOM_TotalCost,
        ECOM_ShippingAndBilling,
        ECOM_Edit,
        ECOM_EmailNotifications,
        ECOM_PaymentInformation,
        ECOM_E_Invoice_Requirements,
        ECOM_Error,
        creditCardApplicableCountries,
        ECOM_Close, //RWPS-1548 - START
        ECOM_AddAddreses, 
        newAddressesNotRegisteredError,
        ECOM_Addressmissing, 
        ECOM_Warning, //RWPS-1548 - END
        ECOM_Non_Sellable_Error_Message //RWPS-2786
    };
    
    @api effectiveAccountId;
    @api fieldsToShow;

    @track
    images = {
        edit:ssrc_ECOM_Theme + '/img/edit.png',
        warning: sres_ECOM_CartIcons + '/img/warning.svg', //RWPS-1548
        close: sres_ECOM_CartIcons + '/img/close.svg' //RWPS-1548
    }
    @track isAccountEditMode = true;
    @track isAccontReadMode = false;
    @track isPaymentEditMode = false;
    @track isPaymentReadMode = false;
    @track isReviewEditMode = false;
    @track isReviewReadMode = false;
    @track isTaxExemptEditMode = false;
    @track isTaxExemptReadMode = false;
    // variables declaired for ECOM-1947 by sathiya
    @track isInvoiceReadMode = false;
    @track isInvoiceEditMode = false;
    @track isEInvoiceAvailable = false;
    @track isInvoiceOrderMode = false;
    invoiceValidationFields = [];
    invoiceFieldValidationJSON;
    invoiceFieldValidationObj;
    // Changes End
    // Variables added for product tnc  ECOM-123 by sathiya
    productTnC = '';
    isProductTnC = false;
    productTnC_RUO = '';
    isProductTnC_RUO = false;
    // Changes End
    @wire(MessageContext)
    messageContext;
    moveToNextSection = false;
    totalSaving;
    tariffSurchargeTotal;//RWPS-3026
    shipToSalesOrg;
    billToSalesOrg;
    //poNumber;
    //quoteNumber;
    //promoCode;
    @track userCountry;
    paymetDataMap;
    cartId;
    @track cartItems;//RWPS-4500
    cartSummary;
    _cartItemCount = 0;
    pageParam = null;
    sortParam = 'CreatedDateDesc';
    moduleName = 'CreditCollectionsContactInfo';
    checkoutStepOne=false;
    paymentMdtMap = new Map();
    promoCode;
    showSpinner = false;
    message;
    type;
    show;
    timeSpan=3000; //RWPS-2786
    showPrompt = false;
    showCreditCard =false;
    promptMsg;
    creditCollections;
    currencyDisplayAs = 'code';
    productFields;
    defaultShipToSAPNumber;
    error;
    userRecord;
    approvalNeeded = false;
    isProductDeleted = false ;//RWPS-2786
    isCartRepriced = false;//RWPS-3811
    deletedPartNumber; //RWPS-2786
    showNoBillingShippingPrompt = false;//RWPS-1548
    @track addAddressError = '';
    @track showErrormodal = false;
    @track isTaxExemptUser = false;
    fileName = 'ecom_checkout';//RWPS-5153
    moduleName = 'Checkout Management';//RWPS-5153

    @track
    isTestingUser = false; //RWPS-5436

    @track
    orgDetails; //RWPS-5436

    @track
    configurationDetails; //RWPS-5436

    //RWPS-5938
    @track
    isPunchoutViaWeb = false;

    @wire(getRecord, {
        recordId: USER_ID,
                fields: [COUNTRY_FIELD, CURRENCY_FIELD, ECOM_TEST_USER_FIELD, IS_PUNCHOUT_VIA_WEB] //RWPS-5436 //RWPS-5938 = Added IS_PUNCHOUT_VIA_WEB field
    }) wireuser({
        error,
        data
    }) {
        if (error) {
           this.error = error ; 
            processAndLogJSError(error, this.fileName, this.moduleName, 'wireuser');  //RWPS-5153  
        } else if (data) {
            this.userCountry = data.fields.Country.value;
            let currencyCode;
            currencyCode = data.fields.CurrencyIsoCode.value;
            //console.log('here currency code>>>'+currencyCode);
            this.isTaxExemptUser = currencyCode == 'GBP' ? true : false;
            //console.log('here isTaxExemptUser value>>'+this.isTaxExemptUser);
            this.isTestingUser = data?.fields?.ECOM_Is_Test_User__c?.value;
            //RWPS-5938
            this.isPunchoutViaWeb = data?.fields?.Contact?.value?.fields?.ECOM_Punchout_Via_Web__c?.value ? data.fields.Contact.value.fields.ECOM_Punchout_Via_Web__c.value : false;
            if (this.isPunchoutViaWeb == true) {
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: '/cart?ptcms=true'
                    }
                });
            }
            //RWPS-5938
        }
    }

    //RWPS-5436
    @wire (getOrganizationDetails,{})
	wiredOrgDetails({data, error}){
		if(data) {
			this.orgDetails = data;
			this.error = undefined;
		}else {
			this.error = error;
		}
	}

    //RWPS-5436
    @wire (getTestUserConfigurations,{})
	wiredConfiguratioDetails({data, error}){
		if(data) {
			this.configurationDetails = data;
			this.error = undefined;
		} else {
			this.error = error;
		}
	}

    get cartItemCount(){
        return this._cartItemCount;
    }
    renderedCallback(){
        
        let cartItemsData = this.cartItems;
        let cartSummaryData = this.cartSummary;
        if(this.checkoutStepOne==false){
            if(cartSummaryData!=null && cartSummaryData!=undefined ){
                this.checkAndUpdateBillToShipToOnCart();
                this.checkoutStepOne=true;
                getDataLayerDataByCart({cartId:this.cartSummary.cartId})
                .then(result=>{
                this.productFields = result;
                //Preparing data for checkout event(Step 1) which will be push to DataLayer
                try {
                    this.prepareDataLayerData(this.cartSummary,this.cartItems,'Shipping and Billing','1');
                } catch (error) {//RWPS-5153 start
                    processAndLogJSError(error, this.fileName, this.moduleName, 'prepareDataLayerData');
                }
                })
                .catch(error => {
                    processAndLogJSError(error, this.fileName, this.moduleName, 'getDataLayerDataByCart');
                });//RWPS-5153 end
            }
        }
    }
    connectedCallback() {
        this.showSpinner = true;
        const result = contextApi.getSessionContext();
        result.then((response) => {
            this.effectiveAccountId = response.effectiveAccountId;
            if(this.effectiveAccountId ) {
                this.getCartDetails();
                this.getCreditCollectionsInfo();
                this.getDefaultExternalIdInfo();
            }
        }).catch((error) => {
             processAndLogJSError(error, this.fileName, this.moduleName, 'connectedCallback');//RWPS-5153
        });
    }

    checkAndUpdateBillToShipToOnCart(){
        // Call the 'updateBillToShipToOnCart' apex method imperatively //RWPS-1602
        updateBillToShipToOnCart({
            cartId: this.cartSummary.cartId
        }).then((result) => {
            if(result){
                //console.log(result);
            }
            }).catch((error) => {//RWPS-5153
               processAndLogJSError(error, this.fileName, this.moduleName, 'checkAndUpdateBillToShipToOnCart');
            });
    }

    getDefaultExternalIdInfo(){
        getDefaultShipToSAPNumber({
        }).then((result) => {
            if(result?.success){
                this.defaultShipToSAPNumber = result?.defaultSAPNumber||'';
            }
        }).catch((error) => {//RWPS-5153
            processAndLogJSError(error, this.fileName, this.moduleName, 'getDefaultShipToSAPNumber');
        });
    }

    getCreditCollectionsInfo() {
        // Call the 'getCreditCollections' apex method imperatively
        getCreditCollections({
            moduleName: this.moduleName
        }).then((result) => {
            this.creditCollections = result;
            }).catch((error) => {//RWPS-5153
                processAndLogJSError(error, this.fileName, this.moduleName, 'getCreditCollectionsInfo');
            });

    }
    handleUpdateCartSummary(event){
        this.showSpinner = true;
        if(event.detail.isPromoApplied && event.detail.isValidPromo === 'success'){
        //Preparing data for checkout event (Step 2) which will be push to DataLayer
            try {
                this.prepareDataLayerDataForPromoCode(this.cartSummary,this.cartItems);
            } catch (error) {//RWPS-5153
                processAndLogJSError(error, this.fileName, this.moduleName, 'handleUpdateCartSummary');
            }
        }
        this.showSpinner = false;
        this.getCartDetails();
        this.showMessage(
            event.detail.promoMessage,
            event.detail.isValidPromo,
            true
            );
        if(event?.detail?.isValidPromo !== 'success'){
            window.scrollTo(0, 0);
        }
}
    //RWPS-2786-Start
   deleteCartItems() {
        if(!this.isProductDeleted){
            deleteDiscontinuedNonSellableProducts({ cartId: this.cartId })
                .then(result => {
                    if (result.success) {
                        this.isProductDeleted = true;
                        this.getCartDetails();
                        this.handlePublishMessage();
                        this.deletedPartNumber = this.getPartNumbers(result?.deletedItems);
                    }
                     if(this.cartId && !this.isCartRepriced){//RWPS-3811
                        this.repriceCurrentCart();
                    }
                })
                .catch(error => {
                    processAndLogJSError(error, this.fileName, this.moduleName, 'deleteCartItems');//RWPS-5153
                });
        }
    }

    getPartNumbers(items) {
        try{//RWPS-5153
        return items
            .map(item => item.Product2?.Part_Number__c)
            .filter(partNumber => partNumber) // removes undefined or null values
            .join(',');
        }catch (error) {//RWPS-5153 start
            processAndLogJSError(error, this.fileName, this.moduleName, 'getPartNumbers');
            return '';
        }//RWPS-5153 end
    }


    handlePublishMessage() {
        let payLoad = {message: this._cartItemCount,
            type: 'CartRefresh'
        };
        publish(this.messageContext, ECOM_MESSAGE, payLoad);
    }
     handleClosePrompt(){
        this.showPrompt = false;
    }
    //RWPS-2786-End

   

   
    getCartDetails() {
        // Call the 'getCartItems' apex method imperatively
        getCheckoutInItData({
            communityId: communityId,
            effectiveAccountId: this.effectiveAccountId,
        }).then((results) => {
                if(results.Status == 'Success'){
                    console.log('result::', results);
                    // ECOM -1947 for new field validations by sathiya
                    this.invoiceFieldValidationJSON = results?.invoiceValidationFields;
                    if(this.invoiceFieldValidationJSON != null){
                        this.invoiceFieldValidationObj = JSON.parse(this.invoiceFieldValidationJSON);
                    }
                    // Changes End
                    this.approvalNeeded = results?.ApprovalNeeded;
                    this.cartItems = results?.cartModelsResponse?.[0]?.cartItems;
                    let cartItemsWithProductData = results?.WebCarts?.[0]?.CartItems;
                    this.cartId = results?.cartModelsResponse?.[0]?.cartId;
                    // Changes for product tnc  ECOM-123 by sathiya
                    if(results?.cartModelsResponse?.[0]?.productTnC != null){
                        this.productTnC = results?.cartModelsResponse?.[0]?.productTnC;
                        this.isProductTnC = true;
                    }
                    if(results?.cartModelsResponse?.[0]?.productTnCRUO != null){
                        this.productTnC_RUO = results?.cartModelsResponse?.[0]?.productTnCRUO;
                        this.isProductTnC_RUO = true;
                    }    
                    // Changes End
                   //RWPS-5153 start
                    const supportData=JSON.stringify({args:{effectiveAccountId: this.effectiveAccountId}});
                    for(let i in this.cartItems){
                        const updatedSupportData = JSON.stringify({
                            ...JSON.parse(supportData),
                            cartItemId: this.cartItems[i].cartItemId
                        });
                        const displayName = this.cartItems[i].cartItemName;
                         logFieldError({ componentName: this.fileName, moduleName: this.moduleName, methodName: 'getCartDetails', fieldName: 'cartItemName', fieldValue: displayName, supportData: updatedSupportData
                        }).catch(error => {
                            processAndLogJSError(error, this.fileName, this.moduleName, 'getCartDetails');
                        });
                        //RWPS-5153 end
                        this.cartItems[i].thumbnailImageURL = resolve(this.cartItems[i]?.thumbnailImageURL ?? '', false, {
                            height: 460,
                            width: 460,
                        })
                        for( let k in  cartItemsWithProductData){
                            if(this.cartItems[i].productId===cartItemsWithProductData[k].Product2Id){
                                this.cartItems[i]['DisplayUrl'] = cartItemsWithProductData[k].Product2?.DisplayUrl;
                                //RWPS-4500 - Start
                                if(this.cartItems[i].cartItemId == cartItemsWithProductData[k].Id){
                                    if(cartItemsWithProductData[k].ECOM_Parent_Item__c == null) {
                                        this.cartItems[i].isFreeItem = false;
                                    } else {
                                        this.cartItems[i].isFreeItem = true;
                                    }
                                }
                                //RWPS-4500 - end
                            }
                        }
                        // RWPS - 2270 START
                        this.cartItems[i].cartItemName = (this.cartItems[i].cartItemName != null && typeof this.cartItems[i].cartItemName === 'string' && this.cartItems[i].cartItemName !== 'undefined')? //RWPS-5933
                                                         this.cartItems[i].cartItemName.replaceAll('&lt;','<').replaceAll('&gt;','>'):this.cartItems[i].cartItemName;
                        // RWPS - 2270 END
                    }
                    this._cartItemCount = Number(
                        results?.cartModelsResponse?.[0]?.uniqueProductCount
                    );
                    this.cartSummary =  results?.cartModelsResponse?.[0];
                    this.totalSaving = results?.WebCarts?.[0]?.ECOM_Total_Savings__c;
                    this.tariffSurchargeTotal = results?.WebCarts[0]?.Total_Tariff_Surcharge__c;//RWPS-3026
                    this.promoCode = results?.WebCarts?.[0]?.ECOM_Promo_Code__c;//RWPS-4500
                    this.shipToSalesOrg = results?.WebCarts?.[0]?.Default_Ship_to_ERP_Address__r?.ERP_Sales_Org__c;
                    this.billToSalesOrg = results?.WebCarts?.[0]?.Default_Bill_to_ERP_Address__r?.ERP_Sales_Org__c;
                    if(this.shipToSalesOrg==null || this.shipToSalesOrg=='')
                    {
                        this.shipToSalesOrg = results.salesOrg?results.salesOrg:"";
                    }
                    if(this.billToSalesOrg==null || this.billToSalesOrg=='')
                    {
                        this.billToSalesOrg = results.salesOrg?results.salesOrg:"";
                    }

                    var creditCardApplicableCountries = this.labels.creditCardApplicableCountries.split(',');

                    if(!creditCardApplicableCountries.includes(this.shipToSalesOrg)) //ECOM-3211 - garora@rafter.one - removed check for approval needed, to show credit card option for $0 auth - 6 June 2024
                    {
                        this.showCreditCard = false;
                    }
                    else
                    {
                        this.showCreditCard = true;
                    }
                    for(let i in results?.storeConfigMdtList)
                    {
                        this.paymentMdtMap.set(results?.storeConfigMdtList[i].DeveloperName,results?.storeConfigMdtList[i].Value__c);
                    }
                    // Changes done by sathiya on 2024/05/13 for ECOM-1947
                    let validationCountry = '';
                    if(results?.WebCarts?.[0]?.Default_Bill_to_ERP_Address__r?.apiCountry__c != null){
                        validationCountry = results?.WebCarts?.[0]?.Default_Bill_to_ERP_Address__r?.apiCountry__c.toLowerCase();
                    } else if(results?.WebCarts?.[0]?.Default_Bill_to_ERP_Address__r?.fxAddress_CountryName__c){
                        validationCountry = results?.WebCarts?.[0]?.Default_Bill_to_ERP_Address__r?.fxAddress_CountryName__c.toLowerCase();
                    }
                    let validationFields = {};
                    if(validationCountry != null && validationCountry != undefined){
                        validationFields.cartId = this.cartId;
                        if(results?.WebCarts?.[0]?.ECOM_E_Invoice_Code1__c != null){
                            validationFields.einvoice1 = results?.WebCarts?.[0]?.ECOM_E_Invoice_Code1__c;
                        }
                        if(results?.WebCarts?.[0]?.ECOM_E_Invoice_Code2__c != null){
                            validationFields.einvoice2 = results?.WebCarts?.[0]?.ECOM_E_Invoice_Code2__c;
                        }
                        if(results?.WebCarts?.[0]?.ECOM_E_Invoice_Code3__c != null){
                            validationFields.einvoice3 = results?.WebCarts?.[0]?.ECOM_E_Invoice_Code3__c;
                        }
                        if(results?.WebCarts?.[0]?.ECOM_E_Invoice_Code4__c != null){
                            validationFields.einvoice4 = results?.WebCarts?.[0]?.ECOM_E_Invoice_Code4__c;
                        }
                        if(results?.WebCarts?.[0]?.ECOM_E_Invoice_Cost_Center__c != null){
                            validationFields.einvoice5 = results?.WebCarts?.[0]?.ECOM_E_Invoice_Cost_Center__c;
                        }
                        if(results?.WebCarts?.[0]?.ECOM_E_Invoice_Tax_Exempt__c != null){
                            validationFields.einvoice6 = results?.WebCarts?.[0]?.ECOM_E_Invoice_Tax_Exempt__c;
                        }
                        let puCustInvoice = (results?.WebCarts?.[0]?.Default_Bill_to_ERP_Address__r?.Target_Address__r != null
                                            ?results?.WebCarts?.[0]?.Default_Bill_to_ERP_Address__r?.Target_Address__r?.ECOM_PU_Cust_E_Invoice__c
                                            :results?.WebCarts?.[0]?.Default_Bill_to_ERP_Address__r?.ECOM_PU_Cust_E_Invoice__c);
                        let isRequired = puCustInvoice != null && (puCustInvoice == 'E1' || puCustInvoice == 'E2');
                        validationFields = validateFieldsWithRequired(validationFields, validationCountry, this.invoiceFieldValidationObj, isRequired);
                        this.invoiceValidationFields = validationFields?.validationFields;
                        if(this.invoiceValidationFields){
                            this.isEInvoiceAvailable = this.invoiceValidationFields.length > 0?true:false;
                        } else {
                            this.isEInvoiceAvailable = false;
                        }
                        
                    }
                    this.deleteCartItems();//RWPS-2786
                    // Changes End
                }
            })
            .catch((error) => {
                    this.showSpinner = false;
                    this.cartItems = [];
                    processAndLogJSError(error, this.fileName, this.moduleName, 'getCartDetails');//RWPS-5153
                });
    }

   repriceCurrentCart() {
       this.showSpinner = true;     
       repriceCart({
           cartId: this.cartId,
           couponCode : ''//RWPS-4500
       }).then((result) => {
        
           this.showSpinner = false;
            //RWPS-3811 - start
            if(result?.promoMessage !== null){
                this.getCartDetails();
                this.handlePublishMessage();
                this.promptMsg = result?.promoMessage;
                this.isCartRepriced = true; 
                this.showMessage(this.promptMsg,'success',true); //RWPS-4502
           }

           //RWPS-3811 - END
           //RPWS-2786 - START
          if (result?.message === 'No cart items.') {
                this.showSpinner=false;
                this.promptMsg = this.deletedPartNumber + ' ' + this.labels.ECOM_Non_Sellable_Error_Message;
                this.showPrompt = true;
                return;
            }
             if(this.isProductDeleted){
                this.showSpinner=false;
                this.showMessage(this.deletedPartNumber + ' ' + this.labels.ECOM_Non_Sellable_Error_Message,'error',true);//RWPS-2786
             }
           //RPWS-2786 - END

           if(result?.success){
               if(result?.responseWrapper?.error?.errorDetails[0]?.errorCode == 'V1154'){
                  // this.promptMsg = 'We\'re sorry, your organization\'s account is currently on credit block due to lack of payment. Please have your AP team contact Credit & Collections at ' + this.creditCollections[this.userCountry];
                   this.promptMsg = ECOM_CreditBlock + ' ' + this.creditCollections[this.userCountry];
                   this.showPrompt = true;
               }
               else if(result?.responseWrapper?.error?.errorDetails[0]?.errorMessage){
                   this.promptMsg = result.responseWrapper.error.errorDetails[0].errorMessage;
                   this.showPrompt = true;
               }
               
           }else{
               //disable checkout and all operation
               this.showPrompt = true;
               if(result?.responseWrapper){
                   if(result.responseWrapper?.errorDetails[0]?.errorCode == 'V1154'){
                     //  this.promptMsg = 'We\'re sorry, your organization\'s account is currently on credit block due to lack of payment. Please have your AP team contact Credit & Collections at ' + this.creditCollections[this.userCountry];
                       this.promptMsg = ECOM_CreditBlock + ' ' + this.creditCollections[this.userCountry];
                 
                    }
                   else if(result.responseWrapper?.errorDetails[0]?.errorMessage){
                       this.promptMsg = result.responseWrapper.errorDetails[0].errorMessage;
                   }
               }
               else if(result?.responseError){
                //RWPS-1548 Start
                if(result?.addressError){
                    this.isAddressError = true;
                    if(result?.NoBillingShipping){
                        this.showPrompt = false;
                        this.showErrormodal = false;
                        this.showNoBillingShippingPrompt = true;
                    }
                    else{
                        this.showPrompt = false;
                        this.showNoBillingShippingPrompt = false;
                        this.showErrormodal = true;
                        this.addAddressError = result.responseError;
                    }
                }
                this.promptMsg = result.responseError;
                }//RWPS-1548 end
                 //RPWS-2786 - START
                    if(this.isProductDeleted){
                        this.showSpinner=false;
                        this.showMessage(this.deletedPartNumber + ' ' + this.labels.ECOM_Non_Sellable_Error_Message,'error',true);//RWPS-2786
                    }
                //RPWS-2786 - END
            }
       }).catch((error) => {
           this.showSpinner=false;
            console.log(' error',error);
            processAndLogJSError(error, this.fileName, this.moduleName, 'repriceCurrentCart');//RWPS-5153
       });
   }

closeAddressErrorModal(){
    this.showErrormodal = false;
    this.showNoBillingShippingPrompt = false;//RWPS-1548
    let addrStatus = 'selectAddress';
    if(this.userRecord.Contact.ECOM_AddressRegistration__c == 'Populate ST & BT'
    && this.userRecord.Contact.ECOM_RegistrationPattern__c == 'No Match'){
        addrStatus = 'addAddress';
    }
    this[NavigationMixin.Navigate]({
        type: 'standard__webPage',
        attributes: {
            url: '/dashboard?addressStatus='+addrStatus
        }
    });
}
    
    handleShowPaymentSection(event){
        this.moveToNextSection = event.detail.moveToNextSection;
        if(this.moveToNextSection){
            this.isAccontReadMode = true;
            this.isAccountEditMode = false;
            //this.isPaymentReadMode = false;
            this.isTaxExemptEditMode = this.isTaxExemptUser ? true : false;
            if(this.isTaxExemptEditMode == true){
                this.isTaxExemptReadMode = false;
            }
            this.isPaymentEditMode = !this.isTaxExemptUser ? true : false;
            this.isReviewReadMode = true;
            this.isReviewEditMode = false;
            this.moveToNextSection = false;
            this.isInvoiceReadMode = true;
            this.isInvoiceEditMode = false;
        }
        
        //Preparing data for checkout event (Step 3) which will be push to DataLayer
        try {
            this.prepareDataLayerData(this.cartSummary,this.cartItems,'Payment','4');
        } catch (error) {
           processAndLogJSError(error, this.fileName, this.moduleName, 'handlePaymentSection');//RWPS-5153
        }
    }

    handleShowPaymentSectionAfterTaxExempt(event){
        this.moveToNextSection = event.detail.moveToNextSection;
        if(this.moveToNextSection){
            this.isAccontReadMode = true;
            this.isAccountEditMode = false;
            //this.isPaymentReadMode = false;
            this.isPaymentEditMode = true;
            this.isReviewReadMode = true;
            this.isReviewEditMode = false;
            this.moveToNextSection = false;
            this.isTaxExemptEditMode = false;
            this.isTaxExemptReadMode = true;
            this.isInvoiceReadMode = true;
            this.isInvoiceEditMode = false;
        }
        
        //Preparing data for checkout event (Step 3) which will be push to DataLayer
        try {
            this.getCartDetails();
            this.prepareDataLayerData(this.cartSummary,this.cartItems,'Payment','4');
        } catch (error) {
            processAndLogJSError(error, this.fileName, this.moduleName, 'handleShowPaymentSectionAfterTaxExempt');//RWPS-5153
        }
    }

    handleShowReviewSection(event){
        this.moveToNextSection = event.detail.moveToNextSection;
        if(this.moveToNextSection){
            this.isAccontReadMode = true;
            this.isAccountEditMode = false;
            //this.isPaymentReadMode = false;
            this.isPaymentEditMode = false;
            this.isReviewReadMode = false;
            this.isReviewEditMode = true;
            this.isInvoiceEditMode = false;
            this.isInvoiceReadMode = false;
        }
        
        //Preparing data for checkout event (Step 2) which will be push to DataLayer
        try {
            this.prepareDataLayerData(this.cartSummary,this.cartItems,'Email Notifications','2');
        } catch (error) {
             processAndLogJSError(error, this.fileName, this.moduleName, 'handleShowReviewSection');//RWPS-5153
        }
    }

    handleShowInvoiceSection(event){
        this.moveToNextSection = event.detail.moveToNextSection;
        console.log('Came in email save::', this.moveToNextSection);
        if(this.moveToNextSection){
            this.isAccontReadMode = true;
            this.isAccountEditMode = false;
            //this.isPaymentReadMode = false;
            this.isPaymentEditMode = (!this.isEInvoiceAvailable && !this.isTaxExemptUser)?true:false;
            this.isReviewReadMode = true;
            this.isReviewEditMode = false;
            this.isInvoiceEditMode = this.isEInvoiceAvailable?true: false;
            this.isInvoiceReadMode = false;
            this.isTaxExemptReadMode = false;
            this.isTaxExemptEditMode = this.isTaxExemptUser && !this.isEInvoiceAvailable?true:false;
        }
        //Preparing data for checkout event (Step 2) which will be push to DataLayer
        try {
            let currentState = this.isEInvoiceAvailable?'E-Invoice Requirements':this.isTaxExemptUser?'Tax Exempt':'Payment',
            currentStep = this.isEInvoiceAvailable?'3':this.isTaxExemptUser?'4':'5'

            this.prepareDataLayerData(this.cartSummary,this.cartItems, currentState, currentStep);
        } catch (error) {
             processAndLogJSError(error, this.fileName, this.moduleName, 'handleShowInvoiceSection');//RWPS-5153
        }
    }

    handleAccountEdit(){
        this.isAccontReadMode = false;
        this.isAccountEditMode = true;
        this.isReviewReadMode = true;
        this.isReviewEditMode = false;
        //this.isPaymentReadMode = false;
        this.isPaymentEditMode = false;
        this.isInvoiceReadMode = false;
        this.isInvoiceEditMode = false;
    }

    handleReviewEdit(){
        this.isReviewReadMode = false;
        this.isReviewEditMode = true;
        //this.isPaymentReadMode = false;
        this.isPaymentEditMode = false;
        this.isAccontReadMode = true;
        this.isAccountEditMode = false;
        this.isTaxExemptEditMode = false;
        this.isTaxExemptReadMode = true;

        this.isInvoiceReadMode = false;
        this.isInvoiceEditMode = false;
    }

    handleInvoiceEdit(){
        this.isReviewReadMode = true;
        this.isReviewEditMode = false;
        //this.isPaymentReadMode = false;
        this.isAccontReadMode = true;
        this.isAccountEditMode = false;
        this.isTaxExemptEditMode = false;
        this.isTaxExemptReadMode = true;
        this.isPaymentEditMode = false;
        this.isInvoiceReadMode = false;
        this.isInvoiceEditMode = true;
    }

    handleTaxExemptEdit(){
        this.isReviewReadMode = false;
        this.isReviewEditMode = false;
        //this.isPaymentReadMode = false;
        this.isPaymentEditMode = false;
        this.isAccontReadMode = true;
        this.isAccountEditMode = false;
        this.isTaxExemptEditMode = true;
        this.isTaxExemptReadMode = false;
        this.isInvoiceReadMode = true;
        this.isInvoiceEditMode = false;
    }

    billingAddress;
    contactInfo;
    setBillingAddress(event){
        this.billingAddress = event.detail?.address || {};
        this.contactInfo = event.detail?.contactInfo;
    }

    handlePaymentError(event){
        this.showMessage(
            event.detail?.message,
            'error',
            true
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
	  //RWPS-1285 start
      selectedDate;
      endUserForTradeChecked;
      endUserDetails;
      invoiceEmailId;//RWPS-1882
      invoiceCustId;//RWPS-6394
      setLargePackPropertyEvent(event){
        try{//RWPS-5153
          this.selectedDate= event.detail?.selectedDate;
          this.endUserForTradeChecked= event.detail?.endUserForTradeChecked;
          this.endUserDetails=event.detail?.endUserDetails;
        }catch(error){//RWPS-5153
           processAndLogJSError(error, this.fileName, this.moduleName, 'setLargePackPropertyEvent');
        }
      }
      //RPWS-1285 end
      //RWPS-1882 start
      setInvoiceEmailEvent(event){
        try{//RWPS-5153
         this.invoiceEmailId= event.detail?.invoiceEmailId;
        }catch (error) {//RWPS-5153
            processAndLogJSError(error, this.fileName, this.moduleName, 'setInvoiceEmailEvent');
        }
      }//RWPS-1882 end
      //RWPS-6394 start
      setInvoiceCustIdEvent(event){
        try{
         this.invoiceCustId= event.detail?.invoiceCustId;
        }catch (error) {
            processAndLogJSError(error, this.fileName, this.moduleName, 'setInvoiceCustIdEvent');
        }
      }//RWPS-6394 end
     //DataLayer regarding changes starts
     prepareDataLayerDataForPromoCode(cartSummary,cartItems){
        getDataLayerDataByCart({cartId:this.cartSummary.cartId})
        .then(result=>{
            let data =  {
                'event': 'add_promo_code',
                'cart': {
                    'total': cartSummary.grandTotalAmount,
                    'subTotal': cartSummary.totalProductAmount,
                    'id': cartSummary.cartId,
                    'shippingAmount':  cartSummary.totalChargeAmount,
                    'tax': cartSummary.totalTaxAmount,
                    'discountCode': result?.cart?.ECOM_Promo_Code__c||'',
                    'discountType': result?.cart?.ECOM_Promo_Code__c? 'promotion':'',
                    'discountAmount':  result?.cart?.ECOM_Total_Savings__c||'',
                            
                'items': []
                } 
            };
        
        
        let items = [];
        for(let i=0;i< cartItems.length;i++){
            let productId = cartItems[i].productId;
            items.push({
                'name': result?.dataLayer[productId]?.name,
                'partNumber':[result?.dataLayer[productId]?.partNumber]||undefined ,
                'paccode': result?.dataLayer[productId]?.paccode +'-'+ result?.dataLayer[productId]?.igorDescription||undefined,
                'businessUnit':  result?.dataLayer[productId].superBussinessUnit +'-'+ result?.dataLayer[productId].subBussinessUnit ||undefined ,
                'portfolioLevel2':result?.dataLayer[productId]?.portfolioLevel2||undefined ,
                'productLine':  result?.dataLayer[productId]?.productLine +'-'+ result?.dataLayer[productId].productLineName||undefined ,
                'productClass':result?.dataLayer[productId]?.productClass ||undefined ,
                'productBrand': result?.dataLayer[productId]?.productBrand ||undefined ,
                'sapStatus': result?.productSalesStatus[productId]||undefined,
                'hasImage': cartItems[i]?.thumbnailImageURL? true:false,
                'quantity': result?.dataLayer[productId]?.quantity ,
                'price': result?.dataLayer[productId]?.price||undefined ,
                'listPrice': result?.dataLayer[productId]?.listPrice||undefined ,
                'currency':result?.dataLayer[productId]?.currencyIsoCode||undefined 
            });
        }
        data['cart']['items'] = items;
        this.handlePublishMsg(data);
        })
        .catch(error => {

        });
        
    }

     //DataLayer regarding changes starts
     prepareDataLayerData(cartSummary,cartItems,checkoutStepName,checkoutStepNumber){
        let data=  {
                    'event': 'checkout',
                    'cart': {
                        'total': cartSummary.grandTotalAmount,
                        'subTotal': cartSummary.totalProductAmount,
                        'id': cartSummary.cartId,
                        'shippingAmount':  cartSummary.totalChargeAmount,
                        'tax': cartSummary.totalTaxAmount,
                        'discountCode': this.productFields?.cart?.ECOM_Promo_Code__c||'',
                        'discountType': this.productFields?.cart?.ECOM_Promo_Code__c? 'promotion':'',
                        'discountAmount': this.productFields?.cart?.ECOM_Total_Savings__c||'',
                        'checkoutType': 'ecom',
                        'checkoutStepNumber': checkoutStepNumber,
                        'checkoutStepName': checkoutStepName,
                        'paymentMethod': '',
                        'deliveryMethod': '',
                        'items': []
                    } 
                };
            let items = [];
            for(let i=0;i< cartItems.length;i++){
                let productId = cartItems[i].productId;
                items.push({
                    'name': this.productFields?.dataLayer[productId]?.name,
                    'partNumber':[this.productFields?.dataLayer[productId]?.partNumber]||undefined ,
                    'paccode': this.productFields?.dataLayer[productId]?.paccode+'-'+this.productFields?.dataLayer[productId]?.igorDescription||undefined,
                    'businessUnit': this.productFields?.dataLayer[productId]?.superBussinessUnit+'-'+this.productFields?.dataLayer[productId]?.subBussinessUnit||undefined ,
                    'portfolioLevel2':this.productFields?.dataLayer[productId]?.portfolioLevel2||undefined ,
                    'productLine':  this.productFields?.dataLayer[productId]?.productLine+'-'+this.productFields?.dataLayer[productId]?.productLineName ||undefined ,
                    'productClass':this.productFields?.dataLayer[productId]?.productClass  ||undefined ,
                    'productBrand': this.productFields?.dataLayer[productId]?.productBrand ||undefined ,
                    'sapStatus': this.productFields?.productSalesStatus[productId]||undefined,
                    'hasImage': cartItems[i]?.thumbnailImageURL? true:false,
                    'quantity': this.productFields?.dataLayer[productId]?.quantity ,
                    'price': this.productFields?.dataLayer[productId]?.price||undefined ,
                    'listPrice': this.productFields?.dataLayer[productId]?.listPrice ||undefined,
                    'currency':this.productFields?.dataLayer[productId]?.currencyIsoCode ||undefined
                });
            }
            data['cart']['items'] = items;
            this.handlePublishMsg(data);
    }

    handlePublishMsg(data) {
        try {//RWPS-5153
        let payLoad = {
            data: data,
            type: 'DataLayer',
            page:'checkout'
        };
        publish(this.messageContext, ECOM_DATALAYERCHANNEL, payLoad);
        } catch (error) {//RWPS-5153
            processAndLogJSError(error, this.fileName, this.moduleName, 'handlePublishMsg');//RWPS-5153
        }
    }
    //DataLayer regarding changes starts
    //RWPS-1548 start
    handleCloseModal() {
        this.showNoBillingShippingPrompt = false;
    } //RWPS-1548 end
}