import { LightningElement,track,wire,api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import ssrc_ECOM_Theme from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import { CurrentPageReference } from 'lightning/navigation';
import communityId from '@salesforce/community/Id';
import siteId from "@salesforce/site/Id";
import contextApi from 'commerce/contextApi';
import getOrderDetails from '@salesforce/apex/ECOM_OrderHistoryController.getorderDetailsAndReplacement'; // RWPS-4602
import fetchProductUnavailability from '@salesforce/apex/ECOM_OrderHistoryController.fetchProductUnavailability'; // RWPS-4602
import getERPAddress from '@salesforce/apex/ECOM_OrderHistoryController.getERPAddress';
import getAccountBasedOnIds from '@salesforce/apex/ECOM_OrderHistoryController.getAccountBasedOnIds';
import getProdImages from '@salesforce/apex/ECOM_OrderHistoryController.getProdImages';
import getWishlistDetails from '@salesforce/apex/ECOM_OrderHistoryController.getWishlistDetails';
import createAndAddToList from '@salesforce/apex/ECOM_OrderHistoryController.createAndAddToList';
import addItemsToCart from '@salesforce/apex/ECOM_OrderHistoryController.addItemsToCart';
import removeWishlistItem from '@salesforce/apex/ECOM_OrderHistoryController.removeWishlistItem';
import FORM_FACTOR from '@salesforce/client/formFactor';
import ECOM_DATALAYERCHANNEL from '@salesforce/messageChannel/ecom_DataLayer__c';
import ECOM_MESSAGE from '@salesforce/messageChannel/ecom_MessagingChannel__c';
import ECOM_105105 from '@salesforce/label/c.ECOM_105105';
import { MessageContext, publish } from 'lightning/messageService';
import ECOM_Savings  from '@salesforce/label/c.ECOM_Savings';
import ECOM_E_Invoice_Requirements from '@salesforce/label/c.ECOM_E_Invoice_Requirements';
import ECOM_InvoiceMailingAddress from '@salesforce/label/c.ECOM_InvoiceMailingAddress';
import ECOM_Tariff_Surcharge  from '@salesforce/label/c.ECOM_Tariff_Surcharge';//RWPS-3026
import { trackAddProductToCart } from 'commerce/activitiesApi'; //RWPS-3125
import deliveryInstructionNew from '@salesforce/label/c.ECOM_DeliveryInstructionNew';//RWPS-4825
import ECOM_OfflineOrdersSourceTypes from '@salesforce/label/c.ECOM_OfflineOrdersSourceTypes';//RWPS-5149

// Import Ecom_util for validation methods
import { validateAddressForOrder } from 'c/ecom_util';
import getContractPrice from '@salesforce/apex/ECOM_CartController.getContractPrice'; // RWPS-4602
import {getReplacementProductContractPrice} from 'c/ecom_util'; // RWPS-4602

import ECOM_REPLACEMENT_MSG from '@salesforce/label/c.ECOM_REPLACEMENT_MSG';//RWPS-4602
import ECOM_INDIRECT_REPLACEMENT_MSG from '@salesforce/label/c.ECOM_INDIRECT_REPLACEMENT_MSG';//RWPS-4602
import ECOM_DISCONTINUE_MSG from '@salesforce/label/c.ECOM_DISCONTINUE_MSG';//RWPS-4602
import ECOM_105103 from '@salesforce/label/c.ECOM_105103';//RWPS-4602
import recipientTitle from '@salesforce/label/c.ecom_Attention_Recipient_Title';//RWPS-4824

const CARDTYPE_IMAGE_MAP = {
    Visa : 'visaimg',
    AMEX : 'ameximg',
    MC : 'mastercardimg'
}
export default class Ecom_orderHistoryDetails extends NavigationMixin(LightningElement) {
    labels = {
        ECOM_Savings,
        ECOM_E_Invoice_Requirements,
        ECOM_InvoiceMailingAddress,
        ECOM_Tariff_Surcharge, //RWPS-3026
        recipientTitle,//RWPS-4824
        deliveryInstructionNew//RWPS-4825
    };

    imagesFetched = false;
    multipleTracking = false;
    urlId;
    baseUrl;
    hasImage;
    originalOrderId;
    orderNumber;
    sapOrderNumber;
    orderDate;
    orderTotal = 0;
    orderSubTotal = 0;
    orderShipping = 0;
    orderTax = 0;
    orderSavings = 0;
    orderItemsCount;
    billingAddress;
    shippingAddress = {};
    erpShipToId;
    erpBillToId;
    defaultWishListId;
    shippingInstructions;
    specialInstructions;
    wishListdetails;
    recipient;
    promoCode;
    isPromoApplied = false;
    showSpinner = true;
    quoteNumber;
    poNumber;
    accNumber;
    accName;
    accId;
    accIdList = [];
    productObject = 'Product2';
    isSapOrder = false;
    //RWPS-622
    isLargePackOrder = false;
    orderCurrencyCode = '';
    orderItems = [];
    filteredOrderItems = [];
    orderItemsList = [];
    orderItemsIds = [];
    currencyDisplayAs ='code';
    orderSalesStatus;
    msg;
    type;
    show;
    timeSpan = 3000;
    cardPayment;
    productIdTopartNumberMap=new Map();
    @track erroneousPartsToDisplay=[]; // RWPS-4602
    successfulParts=[];
    showMessagePage=false;
    showErrorParts=false;
    showSuccessParts=false;
    modalSize='';
    footerCloseCss='';
    approvalRejectionComment; //RWPS-1885

    isOrderCancelled=false; // RWPS-2554
    // ECOM -1933 variable additions
    billToFieldValidationJSON;
    billToFieldValidationObj;
    validationFields = [];
    isValidatedFields = false;
    // Changes End
    // variables declaired for ECOM-1947 by sathiya
    @track isEInvoiceAvailable = false;
    invoiceValidationFields = [];
    invoiceFieldValidationJSON;
    invoiceFieldValidationObj;
    @track isInvoiceEditMode = false;
    @track isInvoiceReadMode = false;
    @track isInvoiceOrderMode = true;
    mailingAddress;
    isInvoiceMailingAddress= false;
    orderTotalTariffSurcharge = 0;//RWPS-3026
    showTotalTariffSurcharge= false;//RWPS-3026
    #escapeKeyCallback; // RWPS-4087
    // Changes End

    @api productImages = {};
    @wire(MessageContext)
    messageContext;
    @api
    device = {
        isMobile : FORM_FACTOR==='Small',
        isDesktop : FORM_FACTOR==='Large' || FORM_FACTOR==='Medium'
    }
    @track
    selectedLabel = 'Orders'

    sidebarCSS='';
    middleSpaceCSS = '';
    mainSectionCSS = '';
    //RWPS-4602 - START
    replacementMap;
    replacementContractPrice = {};
    allProductsDiscontinued = false;
    productUnavailabilityDetails;
    //RWPS-4602 - END

    @track
    offlineOrderSourceTypes = ECOM_OfflineOrdersSourceTypes.split(','); //RWPS-5149
    isOfflineOrder = false; //RWPS-5149

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
       if (currentPageReference) {
          this.urlId = currentPageReference.state?.id;
       }
    }

    @track
    images = {
        dashboard:ssrc_ECOM_Theme + '/img/dashboard.png',
        logout:ssrc_ECOM_Theme + '/img/logout.png',
        back:ssrc_ECOM_Theme+'/img/back.png',
        print:ssrc_ECOM_Theme+'/img/print.png',
        orderagain:ssrc_ECOM_Theme + '/img/orderagainpurple.svg',
        backicon:ssrc_ECOM_Theme + '/img/backicon.svg',
        visaimg: ssrc_ECOM_Theme + '/img/visa.png',
        ameximg: ssrc_ECOM_Theme + '/img/amex.svg',
        mastercardimg: ssrc_ECOM_Theme + '/img/mastercard.svg',
    }

    label = {
        ECOM_105105
    };

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

    showMessage(message,type,show){
        this.msg = message;
        this.type = type;
        this.show = show;
    }
     //RWPS-3191 -Start
     scrollToMessage() {
        const targetDiv = this.template.querySelector('[data-id="targetDiv"]');
        if (targetDiv) {
            targetDiv.scrollIntoView({ behavior: 'smooth'});
        }
    }
     //RWPS-3191 -End

    get showCardImg(){
        return this.cardPayment?.CardType ? true : false;
    }
    get cardTypeImg(){
        return this.images[CARDTYPE_IMAGE_MAP[this.cardPayment?.CardType]];
    }

    connectedCallback(){
        this.selectedLabel='Orders'
        this.multipleTracking = true;
        this.baseUrl = window.location.origin;
        this.getOrderDetail();
        this.getWishlistDetails();
        const result = contextApi.getSessionContext();
        result.then((response) => {
            this.effectiveAccountId = response.effectiveAccountId;
            if(this.effectiveAccountId && this.cartId) {
                //this.updateCartItems();
            }
        }).catch((error) => {

        });
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
             if(this.showMessagePage) {
                 this.handleMessageScreenClose(event);
             }
         }
     }// RWPS-4087 end



    loadBasedOnDeviceType() {
        var width = (window.innerWidth > 0) ? window.innerWidth : screen.width;
        //Tab UI fix - Gaurang - 17 July 2024
        if(FORM_FACTOR==='Medium' || (width==1025)){
            this.sidebarCSS = 'slds-large-size_12-of-12 slds-small-size_12-of-12 slds-medium-size_12-of-12 slds-size_12-of-12 slds-no-print';
            this.middleSpaceCSS = 'doNotDisplay';
            this.mainSectionCSS = 'slds-large-size_12-of-12 slds-small-size_12-of-12 slds-medium-size_12-of-12 slds-size_12-of-12'
        }
        else{
            this.sidebarCSS = 'slds-large-size_3-of-12 slds-small-size_3-of-12 slds-medium-size_3-of-12 slds-size_3-of-12 slds-no-print';
            this.middleSpaceCSS = 'slds-large-size_1-of-12 slds-small-size_1-of-12 slds-medium-size_1-of-12 slds-size_1-of-12 slds-no-print';
            this.mainSectionCSS = 'slds-large-size_8-of-12 slds-small-size_12-of-12 slds-medium-size_8-of-12 slds-size_8-of-12';
        }
        if (this.device.isMobile) {
            this.modalSize = "slds-modal slds-fade-in-open slds-modal_full";
            this.footerCloseCss='slds-col slds-size_12-of-12 slds-large-size_6-of-12 slds-medium-size_6-of-12 slds-small-size_12-of-12 slds-p-top_small'
        } else {
            this.modalSize = "slds-modal slds-fade-in-open modalCSS";
            this.footerCloseCss='slds-col slds-size_12-of-12 slds-large-size_6-of-12 slds-medium-size_6-of-12 slds-small-size_12-of-12'
        }
    }

    // Fetch order details from Apex method getOrderDetails
    getOrderDetail() {
        // Call the 'getOrderDetails' apex method imperatively
        getOrderDetails({
            orderId: this.urlId,
            communityId: communityId  // RWPS-4602
        }).then((result) =>
        {
            if(result.Status === 'Success') {

                if (result.productIds) {
                    fetchProductUnavailability({ productIdList: result.productIds })
                    .then(productData => {
                        if (productData) {
                            this.productUnavailabilityDetails = JSON.parse(JSON.stringify(productData));
                        }
                    })
                    .catch(error=> {
                        console.error(error);
                    })

                }
                // RWPS-4602
                if (result.orderModel && result.orderModel.orderItems) {
                    let isNonSellableOrDiscontinuedProduct = 0
                    result.orderModel.orderItems.forEach(element => {
                        if (element && element.isNonSellableOrDiscontinuedProduct) {
                            isNonSellableOrDiscontinuedProduct ++;
                        }
                    });
                    this.allProductsDiscontinued = result.orderModel.orderItems.length == isNonSellableOrDiscontinuedProduct ? true : false;
                }
                // RWPS-4602
                // ECOM -1933 for new field validations
                console.log('order: ', result?.orderModel);
                let orderModel = result?.orderModel;
                this.billToFieldValidationJSON = result?.billToValidationFields;
                if(this.billToFieldValidationJSON != null){
                    this.billToFieldValidationObj = JSON.parse(this.billToFieldValidationJSON);
                }
                orderModel = validateAddressForOrder(orderModel, this.billToFieldValidationObj);
                this.validationFields = orderModel?.validationFields;
                this.isValidatedFields = orderModel?.isValidatedFields;
                // Changes End
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
                console.log('country::', validationCountry);
                if(validationCountry != null && validationCountry != undefined){
                    invoiceModel = validateAddressForOrder(invoiceModel, this.invoiceFieldValidationObj);
                    this.invoiceValidationFields = invoiceModel?.validationFields;
                    this.isEInvoiceAvailable = invoiceModel.isValidatedFields;
                }
                // Changes End
                this.showSpinner = false;
                this.orderSalesStatus = result?.salesStatus;
                this.accId = result?.orderModel?.accountId;
                this.originalOrderId = result?.orderModel?.id;
                this.orderNumber = result?.orderModel?.orderNumber;
                this.sapOrderNumber = result?.orderModel?.sapOrderNumber;
                this.approvalRejectionComment = result?.orderModel?.approvalRejectionComment; //RWPS-1885
                //let date = new Date(result?.orderModel?.createdDate);
               // this.orderDate = (date.getMonth()+1) + '/' +date.getDate() + '/' + date.getFullYear();
               this.orderDate =new Date(result?.orderModel?.createdDate);
                this.orderItemsCount = result?.orderModel?.totalItems; //ECOM-3149 - garora@rafter.one - mapping to new rollup field for total quantities - 2 May 2024
                this.shippingAddress = result?.orderModel?.shippingAddress;
                this.billingAddress = result?.orderModel?.billingAddress;
                // ECOM -1939 for new field mapping by sathiya
                this.mailingAddress = result?.orderModel?.mailingAddress;
                this.isInvoiceMailingAddress = result?.orderModel?.isInvoiceMailingAddress;
                // Changes End
                this.shippingInstructions = result?.orderModel?.shippingInstructions;
                this.recipient = result?.orderModel?.attentionRecipient;
                this.specialInstructions = result?.orderModel?.deliveryDetails;
                this.orderItems = result?.orderModel?.orderItems;
                //RWPS-3026 Start
                for(let i in this.orderItems){
                    if (this.orderItems[i].tariffSurcharge != null && this.orderItems[i].tariffSurcharge != 0) {
                        this.orderItems[i].showTariffSurcharge = true;
                    } else {
                        this.orderItems[i].showTariffSurcharge = false;
                    }
                }//RWPS-3026 end
                this.promoCode = result?.orderModel?.promoCode;
                if(this.promoCode){
                    this.isPromoApplied = true;
                }
                this.quoteNumber = result?.orderModel?.quoteNumber;
                this.poNumber = result?.orderModel?.poNumber;
                this.orderSubTotal = result?.orderModel?.totalProdAmount;
                this.orderTotalTariffSurcharge = result?.orderModel?.totalTariffSurcharge;//RWPS-3026
                this.showTotalTariffSurcharge = this.orderTotalTariffSurcharge && this.orderTotalTariffSurcharge > 0 ? true : false;//RWPS-3026
                this.orderTax = result?.orderModel?.totalTaxAmount;
                this.orderSavings = result?.orderModel?.totalSavings;
                this.orderShipping = result?.orderModel?.totalShippingAmount;
                this.orderTotal = result?.orderModel?.grandTotalAmount;
                this.orderCurrencyCode = result?.orderModel?.currencyIsoCode;
                this.accName = result?.orderModel?.accountName;
                this.accNumber = result?.orderModel?.accountNumber;
                this.isSapOrder = result?.orderModel?.isSapOrder;
                //RWPS-2554

                //RWPS-5149 - Start
                this.isOfflineOrder = result?.orderModel?.sourceType && this.offlineOrderSourceTypes && this.offlineOrderSourceTypes.includes(result.orderModel.sourceType) && !result?.orderModel?.sfOrder ? true : false;
                if (this.isOfflineOrder == true) {
                    if (this.orderSubTotal) {
                        this.orderTotal = this.orderSubTotal;
                    }
                    if (this.orderTax) {
                        this.orderTotal += this.orderTax;
                    }
                    if (this.orderTotalTariffSurcharge) {
                        this.orderTotal += this.orderTotalTariffSurcharge;
                    }
                } else {
                    this.orderTotal = result?.orderModel?.grandTotalAmount;
                }
                //RWPS-5149 - End

                if(result?.orderModel?.status=='Cancelled') {
                    this.isOrderCancelled = true;
                }
                //RWPS-622
                this.isLargePackOrder = result?.orderModel?.isLargePackShipingOrder;
                // if(this.isSapOrder){
                //     this.shippingInstructions = result?.orderModel?.shippingInstructions;
                //     this.recipient = result?.orderModel?.attentionRecipient;
                //     this.specialInstructions = result?.orderModel?.deliveryDetails;
                //     this.accName = result?.orderModel?.accountName;
                //     this.accNumber = result?.orderModel?.accountNumber;
                //     this.billingAddress = result?.orderModel?.billingAddress
                //     this.shippingAddress = result?.orderModel?.shippingAddress;
                // }
                this.cardPayment = result?.CardPaymentMethod;
                this.getProductImages();
                if(!this.isSapOrder){
                    if(this.accId){
                        this.accIdList.push(this.accId);
                        //this.getAccountDetails();
                    }
                    if(this.erpShipToId || this.erpBillToId){
                        //this.getERPAddressDetail();
                    }
                }
            }
            // RWPS-4602 - START
            if(result?.replacementSuccess)
            {
                this.replacementMap = result?.replacementMap;
                this.getReplacementPrice(this.replacementMap);
            }
            // RWPS-4602 - END
            }).catch((error) => {
                console.log(error);
            });
    }

    // Fetch Account details from Apex method getAccountBasedOnIds
    getAccountDetails() {
        // Call the 'getAccountBasedOnIds' apex method imperatively
        getAccountBasedOnIds({
            accIds: this.accIdList
        }).then((result) => {
            this.accName = result[0].SAP_Customer_Base_Name__c;
            this.accNumber = result[0].SAP_Customer_Number_Formatted__c;
        }).catch((error) => {
            console.log(error);
        });
    }

    // Fetch ERP Address details from Apex method getERPAddress
    getERPAddressDetail() {
        // Call the 'getERPAddress' apex method imperatively
        getERPAddress({
            erpShipToId: this.erpShipToId,
            erpBillToId: this.erpBillToId
        }).then((result) => {
            this.shippingAddress = result?.shipToAddress;
            this.billingAddress = result?.billToAddress;
        }).catch((error) => {
            console.log(error);
        });
    }

    // Fetch product images from Apex.
    getProductImages() {
        for (let i = 0; i < this.orderItems.length; i++) {
            this.orderItemsIds.push(this.orderItems[i].product2Id);
        }
        this.baseUrl += '/vforcesite/cms/delivery/';
        //this.orderItemsIds.push(this.prodId);
        // Call the 'getProdImages' apex method imperatively
        getProdImages({
            productIds: this.orderItemsIds,
            communityId: communityId
        }).then((result) => {
            this.productImages = result;
            this.imagesFetched = true;
            }).catch((error) => {
                console.log(error);
            });
    }

    // Fetch wish list details from Apex.
    getWishlistDetails() {
        // Call the 'getFieldsByObjectName' apex method imperatively
        getWishlistDetails().then((result) => {
                let wishListResult = result?.length > 0 ? result[0] : null;
                let wishListItems = wishListResult?.wishListModels[0]?.wishListItems || [];
                let productToWishlistObj = {};
                this.defaultWishListId =   wishListResult?.wishListModels[0]?.wishListId || '';
                for( let i=0; i<wishListItems.length ;i++){
                    productToWishlistObj[wishListItems[i].productId] = wishListItems[i];
                }
                this.wishListdetails = productToWishlistObj;
            }).catch((error) => {
            });
    }

    // Create wish list and add product to a wish list.
    handleAddToWishlist(event) {
        //RWPS-4200 Start
        let btn = event.detail.buttonRef;
        btn.disabled = true;
        this.showSpinner = true;
        //RWPS-4200 End
        // Call the 'createAndAddToList' apex method imperatively
        createAndAddToList({
            communityId: communityId,
            productId:event.detail.productId,
            wishListId:this.defaultWishListId,
            effectiveAccountId: this.resolvedEffectiveAccountId,
        }).then((result) => {
                this.showMessage(
                    'Item added to favorites successfully.',
                    'success',
                    true
                );
                this.scrollToMessage();//RWPS-3191
                //this.template.querySelector('c-ecom_show-Toast').showToast('Item added to wishlist successfully.', 'success');
                this.getWishlistDetails();
            })
            .catch((error) => {
                this.showMessage(
                    this.label.ECOM_105105,
                    'error',
                    true
                );
                //this.template.querySelector('c-ecom_show-Toast').showToast('Please try again.', 'error');
            })
            .finally(() => { //RWPS-4200
                btn.disabled = false;
                this.showSpinner = false;
            });
    }

    handleRemoveFromFav(event){
        // RWPS-4086 start
        if(this.showSpinner) {
            return;
        }
        // RWPS-4086 end

        //RWPS-4200 Start
        let btn = event.detail.buttonRef;
        btn.disabled = true;
        this.showSpinner = true;
        //RWPS-4200 End
        //this.isRemoveClicked = true;
        //this.favItemCount --;
        let wishlistItemId = event.detail.wishlistItemId;
        //let wishlistId = this.wishListSummary.wishlistSummaries.displayedList.summary.id;

        //console.log('wishlistId =>'+wishlistId);
        removeWishlistItem({
            //communityId: communityId,
            //effectiveAccountId: this.effectiveAccountId,
            //wishlistId: wishlistId,
            wishlistItemId: wishlistItemId
        }).then((result) => {
            this.showMessage(
                'Item removed from favorites successfully.',
                'success',
                true
            );
            this.scrollToMessage();//RWPS-3191
            //this.template.querySelector('c-ecom_show-Toast').showToast('Item removed to wishlist successfully.', 'success');
            this.getWishlistDetails();
        }).catch((error) => {

            this.showMessage(
                this.label.ECOM_105105,
                'error',
                true
            );
        })
        .finally(() => { //RWPS-4200
                btn.disabled = false;
                this.showSpinner = false;
        });
    }

    setOrderItemsList(){
        for (let i = 0; i < this.orderItems.length; i++) {
            this.orderItemsList.push({Product2Id: this.orderItems[i].product2Id, Quantity: this.orderItems[i].quantity, ECOM_Parent_Item__c: this.orderItems[i].parentItem}); //RWPS-3811
            this.productIdTopartNumberMap.set(this.orderItems[i].product2Id,this.orderItems[i].product.partNumber);
        }
    }

    // Add order items to the cart and redirect to the cart page
    handleOrderAgain(){
        // RWPS-4086 start
        if(this.showSpinner) {
            return;
        }
        // RWPS-4086 end

        this.showSpinner = true;
        this.successfulParts=[];
        this.showErrorParts=false;
        this.showSuccessParts=false;
        let erroneousPartsToDisplay=[]; // RWPS-3740
        this.setOrderItemsList();
        if(this.orderItemsList.length > 0){
            // Call the 'addItemsToCart' apex method imperatively
            addItemsToCart({
                communityId: communityId,
                effectiveAccountId: this.effectiveAccountId,
                cartItems: this.orderItemsList
            }).then((results) => {
                let productData = JSON.parse(JSON.stringify(this.productUnavailabilityDetails));
                for(let i in this.orderItemsList) {
                    // RWPS-3740
                    if ((!((results.itemsAddedSuccessfully).includes(this.orderItemsList[i]?.Product2Id) && !this.orderItemsList[i]?.ECOM_Parent_Item__c))) {
                        //RWPS-4602 : Logic to identify discontinued products along with replacements
                        if (productData && productData.discontinuedProducts) {
                            productData.discontinuedProducts.forEach(currentItem => {
                                if (this.orderItemsList[i].Product2Id == currentItem) {
                                    //RWPS-4602 : Logic to identify discontinued products along with direct replacements
                                    if (productData.directReplacementProductMap && productData.directReplacementProductMap.hasOwnProperty(currentItem)) {
                                        erroneousPartsToDisplay.push({
                                            partNumber: this.productIdTopartNumberMap.get(this.orderItemsList[i]?.Product2Id),
                                            reason: ECOM_REPLACEMENT_MSG + ' ' + productData.directReplacementProductMap[currentItem] + '.' //RWPS-5079 : Added space
                                        });
                                    //RWPS-4602 : Logic to identify discontinued products along with Indirect replacements
                                    } else if (productData.indirectReplacementProductMap && productData.indirectReplacementProductMap.hasOwnProperty(currentItem)) {
                                        //RWPS-5079 - Start
                                        let indirectReplacementMessage = ' ';
                                        for (let i = 0; i < productData.indirectReplacementProductMap[currentItem].split(',').length; i++) {
                                            indirectReplacementMessage += productData.indirectReplacementProductMap[currentItem].split(',')[i].trim();
                                            if (i+1 < productData.indirectReplacementProductMap[currentItem].split(',').length) {
                                                indirectReplacementMessage += ', '
                                            } else {
                                                indirectReplacementMessage += '.'
                                            }
                                        }
                                        erroneousPartsToDisplay.push({
                                            partNumber: this.productIdTopartNumberMap.get(this.orderItemsList[i]?.Product2Id),
                                            reason: ECOM_INDIRECT_REPLACEMENT_MSG + indirectReplacementMessage
                                        });
                                        //RWPS-5079 - End
                                    //RWPS-4602 : Logic to identify discontinued products without any replacements
                                    } else {
                                        erroneousPartsToDisplay.push({
                                            partNumber: this.productIdTopartNumberMap.get(this.orderItemsList[i]?.Product2Id),
                                            reason: ECOM_DISCONTINUE_MSG
                                        });
                                    }
                                }
                            });
                        }
                        // Logic to identify non-sellable products
                        if (productData && productData.nonSellableProducts) {
                            productData.nonSellableProducts.forEach(currentItem => {
                                if (this.orderItemsList[i].Product2Id == currentItem) {
                                    erroneousPartsToDisplay.push({
                                        partNumber: this.productIdTopartNumberMap.get(this.orderItemsList[i]?.Product2Id),
                                        reason: ECOM_105103
                                    });
                                }
                            });
                        }
                    } else {
                        //RWPS-4500 START
                        if(!this.orderItemsList[i]?.ECOM_Parent_Item__c){
                            this.successfulParts.push({
                                partNumber : this.productIdTopartNumberMap.get(this.orderItemsList[i]?.Product2Id)
                            });
                        }
                        //RWPS-4500 END
                        // RWPS-3125 start
                        if(this.orderItemsList[i]?.Product2Id) {
                            trackAddProductToCart(
                                {
                                    id: this.orderItemsList[i].Product2Id,
                                    sku: this.productIdTopartNumberMap.get(this.orderItemsList[i].Product2Id),
                                    quantity: this.orderItemsList[i].Quantity,
                                    price: ''
                                }
                            );
                        }
                        // RWPS-3125 end
                    }
                }

                this.erroneousPartsToDisplay = erroneousPartsToDisplay; // RWPS-3740
                if(this.erroneousPartsToDisplay.length>0){
                    this.showErrorParts=true;
                    this.showMessagePage=true;
                }
                if(this.successfulParts.length>0){
                    this.showSuccessParts=true;
                    this.showMessagePage=true;
                }
                //RWPS-4087 start
                if(this.showMessagePage)
                {
                    requestAnimationFrame(() => {
                        const modal = this.template.querySelector('.modalCSS');
                        if (modal) {
                            modal.focus();
                        }
                    });
                } //RWPS-4087 end

                let payLoad = {message:1,
                    type: 'CartRefresh'
                };
                publish(this.messageContext, ECOM_MESSAGE, payLoad);
                this.prepareDataLayerDataForOrderHistory(this.orderItems);
                this.showSpinner = false;

            }).catch((error) => {
                console.error(error); // RWPS-3740
                this.showSpinner = false;
                let erroneousPartsToDisplay = []; // RWPS-3740
                for(let i in this.orderItemsList){
                    erroneousPartsToDisplay.push({
                        partNumber : this.productIdTopartNumberMap.get(this.orderItemsList[i]?.Product2Id),
                        reason : this.label.ECOM_105105
                    });
                }
                this.erroneousPartsToDisplay = erroneousPartsToDisplay;  // RWPS-3740
                if(this.erroneousPartsToDisplay.length>0){
                    this.showErrorParts=true;
                    this.showMessagePage=true;
                     //RWPS-4087 start
                    requestAnimationFrame(() => {
                        const modal = this.template.querySelector('.modalCSS');
                        if (modal) {
                            modal.focus();
                }
                    });
                    } //RWPS-4087 end
            });
        }
    }

    handleMessageScreenRedirectToCart(event)
    {
        // this[NavigationMixin.Navigate]({
        //     type: 'standard__webPage',
        //         attributes: {
        //         url: '/cart'
        //         }
        //     });

        let baseUrl = window.location.href.split('/')[0];
        window.open(baseUrl+'/cart','_self');
    }

    handleMessageScreenClose(event){
        this.showMessagePage=false;
    }

    goBackToOrderHistory(){
        window.history.back();
    }

    handlePrintPage(){
        window.print();
    }
    prepareDataLayerDataForOrderHistory(orderItems){
        let data =  {
            event: 're_order',
            orderId : this.urlId,
            items:[],
            _clear:true
        };
        let items = [];
        for(let i=0;i< orderItems.length;i++){
            items.push({
                'name': orderItems[i]?.product.name,
                'quantity': orderItems[i]?.quantity || undefined
            });
        }
        data.items = items;
        this.handlePublishMsg(data);
      }
    handlePublishMsg(data) {
        let payLoad = {
            data: data,
            type: 'DataLayer',
            page:'Order Details'
        };
        publish(this.messageContext, ECOM_DATALAYERCHANNEL, payLoad);
    }

    // RWPS-4602 - START
    async getReplacementPrice(replacementMap) {
        this.replacementContractPrice = await getReplacementProductContractPrice(replacementMap);
    }
    // RWPS-4602 - ENDS
}