import FORM_FACTOR from '@salesforce/client/formFactor';
import { NavigationMixin } from 'lightning/navigation';
import { LightningElement, api, track, wire } from 'lwc';
import getCheckoutURL from '@salesforce/apex/ECOM_CheckoutController.getCheckoutURL';
import { MessageContext } from 'lightning/messageService';

import ECOM_Apply  from '@salesforce/label/c.ECOM_Apply';
import ECOM_Applied_Promotion  from '@salesforce/label/c.ECOM_Applied_Promotion';
import ECOM_Remove_coupon  from '@salesforce/label/c.ECOM_Remove_coupon';
import ECOM_Promotion_Code  from '@salesforce/label/c.ECOM_Promotion_Code';
import ECOM_Order_Summary  from '@salesforce/label/c.ECOM_Order_Summary';
import ECOM_Subtotal  from '@salesforce/label/c.ECOM_Subtotal';
import ECOM_Estimated_Shipping  from '@salesforce/label/c.ECOM_Estimated_Shipping';
import ECOM_Estimated_Tax  from '@salesforce/label/c.ECOM_Estimated_Tax';
import ECOM_Savings  from '@salesforce/label/c.ECOM_Savings';
import ECOM_Estimated_Total  from '@salesforce/label/c.ECOM_Estimated_Total';
import ECOM_Checkout  from '@salesforce/label/c.ECOM_Checkout';
import ECOM_Update_Prices  from '@salesforce/label/c.ECOM_Update_Prices';
import ECOM_140001  from '@salesforce/label/c.ECOM_140001';
import ECOM_140002  from '@salesforce/label/c.ECOM_140002';
import ECOM_140003 from '@salesforce/label/c.ECOM_140003';
import ECOM_Tax_Status_Label from '@salesforce/label/c.ECOM_Tax_Status_Label';
import ECOM_Tariff_Surcharge from '@salesforce/label/c.ECOM_Tariff_Surcharge';
import {processAndLogJSError} from 'c/ecom_util'; // RWPS-5153

export default class Ecom_shoppingCartSummary extends NavigationMixin(LightningElement) {

    labels = {
        ECOM_Apply,
        ECOM_Applied_Promotion,
        ECOM_Remove_coupon,
        ECOM_Promotion_Code,
        ECOM_Order_Summary,
        ECOM_Subtotal,
        ECOM_Estimated_Shipping,
        ECOM_Estimated_Tax,
        ECOM_Savings,
        ECOM_Estimated_Total,
        ECOM_Checkout,
        ECOM_Update_Prices,
        ECOM_Tax_Status_Label,
        ECOM_Tariff_Surcharge, //RWPS-3026
    }
    @track isPromoButtonDisabled = true;
    @track cssClassApplyPromotion = 'slds-text-align_right cart-summary-apply-promotion-btn-inactive cart-summary-apply-promotion-label slds-size-medium';
    @api
    cartSummary;
    @api
    cartItems;
    @api
    appliedPromotion;
    @api
    totalSaving;
    @api
    tariffSurchargeTotal;
    @api
    isCartChanged = false;
    @api
    cartButtonDisabled =false;
    @api
    isCartDisabled= false;

    @api
    isPunchoutViaWeb; //RWPS-5938

    @track applyButton='';
    @track orderSummaryTextDetail="slds-col slds-size_1-of-1 slds-large-size_7-of-12 slds-medium-size_6-of-12 order-summary-prices";
    @track orderSummaryPriceDetail="slds-col slds-size_1-of-1 slds-large-size_5-of-12 slds-medium-size_6-of-12 order-summary-priceval";
    @wire(MessageContext)
    messageContext;
    couponCode ='';
    currencyDisplayAs ='code';
    showSpinner=false;
    showPrompt=false;
    promptMsg='';
    fileName='ecom_shoppingCartSummary';//RWPS-5153
    moduleName='ECOM_CartService';//RWPS-5153

    get checkoutButtonClass(){
        if(this.isCartDisabled){
            return 'cart-summary-checkoutbutton-disabled slds-align_absolute-center ';
        } else {
            //RWPS-5938
            if (this.isPunchoutViaWeb != null && this.isPunchoutViaWeb != undefined && this.isPunchoutViaWeb == true) { //RWPS-5938
                return 'cart-summary-checkoutbutton-disabled slds-align_absolute-center ';
            } else {
                return 'cart-summary-checkoutbutton slds-align_absolute-center';
            }
            //RWPS-5938
        }
    }

    get currencyCode(){
        return this.cartSummary?.currencyIsoCode;
    }

    get totalShippingCost(){
        return parseFloat(this.cartSummary?.totalChargeAmount) - parseFloat(this.tariffSurchargeTotal);//RWPS-3026
    }

    get isTaxExemptUser(){
        let taxexemptUser = this.cartSummary?.currencyIsoCode && this.cartSummary.currencyIsoCode == 'GBP' ? true :false;
        return taxexemptUser;
    }
    get isCouponApplied(){
       return this.appliedPromotion!=='' ? true: false;
    }
    //RWPS-3026 - Start
    get showTotalSurcharge(){
        if(this.tariffSurchargeTotal > 0){
            return true;
        }
        else{
            return false;
        }
    }
     //RWPS-3026 - End
    get showSavings(){
        if(this.totalSaving > 0){
            return true;
        }
        else{
            return false;
        }
    }
    get appliedCoupon(){
       return this.appliedPromotion;
    }
    @api
    clearCouponInput(){
        this.couponCode = '';
    }
    device = {
        isMobile : FORM_FACTOR==='Small',
        isDesktop : FORM_FACTOR==='Large',
        isTablet :FORM_FACTOR==='Medium'
    }

    connectedCallback() {
        this.loadBasedOnDeviceType();
    }

    loadBasedOnDeviceType() { //RWPS-5625 Start
        if (this.device.isMobile) {
            this.applyButton = 'slds-col slds-size_4-of-12 slds-large-size_4-of-12 slds-medium-size_4-of-12 cart-summary-text-total slds-float_right slds-p-top_medium ipad-promo-button';
            this.orderSummaryTextDetail="slds-col slds-large-size_7-of-12 order-summary-prices order-summary-width";
            this.orderSummaryPriceDetail="slds-col slds-large-size_5-of-12 order-summary-priceval order-summary-width";
        } else if (this.device.isTablet) {
            this.applyButton = 'slds-col slds-size_1-of-1 slds-large-size_4-of-12 slds-medium-size_4-of-12 cart-summary-text-total slds-float_right slds-p-top_medium ipad-promo-button';
            this.orderSummaryTextDetail="slds-col slds-size_1-of-1 slds-large-size_7-of-12 slds-medium-size_6-of-12 order-summary-prices order-summary-width";
            this.orderSummaryPriceDetail="slds-col slds-size_1-of-1 slds-large-size_5-of-12 slds-medium-size_6-of-12 order-summary-priceval order-summary-width";
        } else{
            this.applyButton = 'slds-col slds-size_1-of-1 slds-large-size_4-of-12 slds-medium-size_4-of-12 cart-summary-text-total slds-float_right slds-p-top_none ipad-promo-button';
            this.orderSummaryTextDetail="slds-col slds-size_1-of-1 slds-large-size_7-of-12 order-summary-prices order-summary-width";
            this.orderSummaryPriceDetail="slds-col slds-size_1-of-1 slds-large-size_5-of-12 order-summary-priceval order-summary-width";
        }
    } //RWPS-5625 End
    get checkoutSummaryContainerClass(){
        return this.device?.isMobile ? 'mobile-checkout-section' :'ecom-full-width';
    }
    get promocodeCssClass(){
        return this.device?.isMobile ? 'slds-grid slds-wrap slds-wrap fv-text ecom-full-width' : 'slds-grid slds-wrap slds-wrap fv-text ecom-checkout-hline ecom-full-width'
    }

    renderedCallback(){
        this.promocodeInfo();
        // //Preparing data for view_cart event which will be push to DataLayer
        // try {
        //     this.prepareDataLayerData(this.cartSummary,this.cartItems,this.appliedPromotion,this.totalSaving);
        // } catch (error) {
        //     console.error('Error occured during preparing DataLayer data for view_cart event ',error);
        //   }
    }
    handleCheckoutClick(){
        //RWPS-5938
        if (this.isPunchoutViaWeb != null && this.isPunchoutViaWeb != undefined && this.isPunchoutViaWeb == true) {
            return;
        } else {
            this.showSpinner=true;
            //console.log('CartSummary: '+JSON.stringify(this.cartSummary));
            getCheckoutURL({
                'cartSummary':this.cartSummary
            }).then(result=>{
                //console.log('Result: '+JSON.stringify(result));
                try{//RWPS-5153
                if(result){
                    if(result.success == true){
                        if(result.PunchoutUser == true){
                            if(result.storeTestUser && result.storeTestUser==true){
                                this.showPrompt=true;
                                this.promptMsg=ECOM_140003; //custom label to add
                                this.showSpinner=false;
                                return ;
                            }
                            if(result.postFormUrl){
                                const form = document.createElement('form');
                                form.method = 'post';
                                form.action = result.postFormUrl;
                                const hiddenField = document.createElement('input');
                                hiddenField.type = 'hidden';
                                if(result.cxml==true){
                                    hiddenField.name = 'cxml-urlencoded';
                                    hiddenField.value = result.responseData;
                                    form.appendChild(hiddenField);
                                    document.body.appendChild(form);
                                    form.submit();
                                }
                                else{
                                    hiddenField.name = 'enctype';
                                    hiddenField.value = 'application/x-www-form-urlencoded';
                                    form.appendChild(hiddenField);
                                    const div = document.createElement('div');
                                    div.innerHTML = result.responseData;
                                    //div.innerHTML = this.ociVal;
                                    while(div.childNodes[0]){
                                        form.appendChild(div.childNodes[0]);
                                    }
                                    document.body.appendChild(form);
                                    form.submit();
                                }
                                this.showSpinner=false;
                            this.handlePunchoutRedirectMessage(result.timeoutLimit);//RWPS-6684
                            }
                            else{

                            }
                        }
                        else{
                            this.navigateToCheckout();
                        }
                    }
                    else{
                        if(result.statusCode){
                            this.promptMsg= ECOM_140001;
                        }
                        else{
                            this.promptMsg = ECOM_140002;
                        }
                        this.showPrompt=true;
                        ; //custom label to add
                        this.showSpinner=false;
                    }
                }
                else{
                    //console.log('No result');
                    this.showSpinner=false;
                }
            }catch(error){//RWPS-5153 start
                processAndLogJSError(error, this.fileName, this.moduleName, 'getCheckoutURL');
            }//RWPS-5153 end
            })
            .catch(error=>{
                //console.log('Error: '+JSON.stringify(error));
                //console.log('Error: '+error);
                this.showSpinner=false;
                processAndLogJSError(error, this.fileName, this.moduleName, 'handleCheckoutClick');//RWPS-5153
            });
        }
    }

    closeModal(){
        this.showPrompt=false;
    }

    handleRepriceEvent(evt)
    {
        // this.isCartChanged = false;
        this.dispatchEvent(
            new CustomEvent('handlecartupdateevent')
        );
    }

    handleCouponChange(event){
        this.couponCode = event.target.value;
        this.isPromoButtonDisabled = !this.couponCode; // Disable the button if coupon is empty - RWPS-3234
        this.cssClassApplyPromotion = this.isPromoButtonDisabled? 'slds-text-align_right cart-summary-apply-promotion-btn-inactive cart-summary-apply-promotion-label slds-size-medium' : 'slds-text-align_right cart-summary-apply-promotion-btn-active cart-summary-apply-promotion-label slds-size-medium';
    }

    removeCoupon(){
        try {//RWPS-5153
        //console.log('aplied promo',this.appliedPromotion);
        this.dispatchEvent(
            new CustomEvent('removeappliedcoupon', {
                detail: {
                    remove: true,
                    couponCodeApplied: this.appliedPromotion
                }
            })
        );
        } catch(error){//RWPS-5153 start
            processAndLogJSError(error, this.fileName, this.moduleName, 'removeCoupon');
        }//RWPS-5153 end
    }
    // RWPS-4086 start
    removeCouponKeydown(event){
        if(event.key === 'Enter' || event.keyCode === 13 || event.key === 'Space' || event.keyCode === 32) {
            this.removeCoupon();
            event.preventDefault();
            event.stopPropagation();
        }
    }
    // RWPS-4086 end
    handleApplyCoupon(){
        try{//RWPS-5153
        if(this.couponCode){
            const trimmedValue = this.couponCode.replace(/[^a-zA-Z0-9]/g, '');//RWPS-3234
            this.couponCode = trimmedValue.toUpperCase();//RWPS-3234
            this.dispatchEvent(
                new CustomEvent('couponapply', {
                    detail: {
                        couponCode: this.couponCode
                    }
                })
            );
        }
        } catch(error){//RWPS-5153 start
            processAndLogJSError(error, this.fileName, this.moduleName, 'handleApplyCoupon');
        }//RWPS-5153 end

    }
    navigateToCheckout(url) {
        /*this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/checkout'
            }
        });*/
    try {//RWPS-5153
        let currentUrl = window.location.href;
        let baseUrl =  currentUrl.split('/');
        let finalUrl = baseUrl[0]+'/checkout';
        window.location.href = finalUrl;
    } catch(error){//RWPS-5153 start
        processAndLogJSError(error, this.fileName, this.moduleName, 'navigateToCheckout');
    }//RWPS-5153 end
}

// update price button CSS
get updatePriceButtonHandler()
{
    return this.cartButtonDisabled?"cart-summary-checkoutbutton-disabled slds-align_absolute-center":"cart-summary-checkoutbutton slds-align_absolute-center";
}


    promocodeInfo() {
        try{//RWPS-5153
            this.dispatchEvent(new CustomEvent('promotion', {
                detail: {
                    appliedCoupon:this.appliedPromotion ,
                    savings:this.totalSaving
                }
            }));
        } catch(error){//RWPS-5153 start
            processAndLogJSError(error, this.fileName, this.moduleName, 'promocodeInfo');
        }//RWPS-5153 end
}

    // DataLayer regarding changes starts
    // prepareDataLayerData(cartSummary,cartItems,appliedPromotion,totalSaving){
    //     var promoCode='';
    //     var saving='';
    //     if(appliedPromotion!=undefined && appliedPromotion!=null){
    //         this.promoCode = appliedPromotion;
    //         this.saving=totalSaving;
    //     }
    //     let data =  {
    //         'event': 'view_cart',
    //         'cart': {
    //                   'total': cartSummary.grandTotalAmount,
    //                   'subTotal': cartSummary.totalProductAmount,
    //                   'id': cartSummary.cartId,
    //                   'shippingAmount':cartSummary.totalChargeAmount,
    //                   'tax': cartSummary.totalTaxAmount,
    //                   'discountCode': this.promoCode,
    //                   'discountType': '',
    //                   'discountAmount': this.saving,
    //                   },
    //         'items': []
    //     };
    //     let items = [];
    //     for (let i = 0; i < this.cartItems.length; i++) {
    //             items.push({
    //                         'name': cartItems[i].cartItem?.productDetails?.name ||'',
    //                         'partNumber':cartItems[i].cartItem?.productDetails?.fields?.Part_Number__c ||'',
    //                         'paccode': '',
    //                         'sapStatus': '',
    //                         'businessUnit': '',
    //                         'portfolioLevel2': '',
    //                         'productLine': '',
    //                         'productClass': '',
    //                         'productBrand': '',
    //                         'hasImage': false,
    //                         'quantity':  cartItems[i].cartItem?.quantity,
    //                         'price': '',
    //                         'listPrice': cartItems[i].cartItem?.productDetails?.totalListPrice,
    //                         'currency': cartSummary.currencyIsoCode

    //             });
    //     }
    // data.items = items;
    // this.handlePublishMsg(data);
    // }
    handlePunchoutRedirectMessage(data) { // RWPS-6684
        this.dispatchEvent(new CustomEvent('punchoutcheckout', {
            detail: {
                redirection:true,
                timeoutLimit:data // RWPS-6684
            }
        }));
    }
    // //Publishing data through LMS
    // handlePublishMsg(data) {
    //     let payLoad = {
    //             data: data,
    //             type: 'DataLayer'
    //     };
    //     publish(this.messageContext, ECOM_DATALAYERCHANNEL, payLoad);
     //}

    // //DataLayer regarding changes ends
}