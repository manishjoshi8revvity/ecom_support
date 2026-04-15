import { LightningElement, api,track,wire } from 'lwc';
import sres_ECOM_CartIcons from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import { addItemToCart } from 'c/ecom_util';
import getAssociatedReasons from '@salesforce/apex/ECOM_OrderController.getAssociatedReasons';
import makeCallout from '@salesforce/apex/ECOM_OrderController.makeCallout';
import addItemsToCart from '@salesforce/apex/ECOM_OrderHistoryController.addItemsToCart';
import communityId from '@salesforce/community/Id';
import contextApi from 'commerce/contextApi';
import {publish, MessageContext} from 'lightning/messageService';
import ECOM_DATALAYERCHANNEL from '@salesforce/messageChannel/ecom_DataLayer__c';
import ECOM_MESSAGE from '@salesforce/messageChannel/ecom_MessagingChannel__c';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { resolve } from 'experience/resourceResolver';
import getDataLayerDataByOrder from '@salesforce/apex/ECOM_DataLayerController.getDataLayerDataByOrder';
import ECOM_105105 from '@salesforce/label/c.ECOM_105105';
import ECOM_AddedToCartSuccessfully from '@salesforce/label/c.ECOM_AddedToCartSuccessfully';
const NAVIGATE_TO_PDP = 'PDP';
const CMS_NAVIGATION = 'CMSNavigation';

import { trackAddProductToCart } from 'commerce/activitiesApi'; //RWPS-3125

import ECOM_PartNumber  from '@salesforce/label/c.ECOM_PartNumber';
import ECOM_Unit_Size  from '@salesforce/label/c.ECOM_Unit_Size';
import ECOM_Shipment_Date  from '@salesforce/label/c.ECOM_Shipment_Date';
import ECOM_AddToCart  from '@salesforce/label/c.ECOM_AddToCart';
import ECOM_Save_favorites  from '@salesforce/label/c.ECOM_Save_favorites';
import ECOM_Remove_Favorites  from '@salesforce/label/c.ECOM_Remove_Favorites';
import ECOM_Help  from '@salesforce/label/c.ECOM_Help';
import ECOM_Qty  from '@salesforce/label/c.ECOM_Qty';
import ECOM_Open  from '@salesforce/label/c.ECOM_Open';
import ECOM_Partially_Shipped  from '@salesforce/label/c.ECOM_Partially_Shipped';
import ECOM_Shipped  from '@salesforce/label/c.ECOM_Shipped';
import Ecom_Cancel_close  from '@salesforce/label/c.Ecom_Cancel_close';
import ECOM_HelpReason  from '@salesforce/label/c.ECOM_HelpReason';
import ECOM_Reason  from '@salesforce/label/c.ECOM_Reason';
import ECOM_Reason_for_Needing_Help  from '@salesforce/label/c.ECOM_Reason_for_Needing_Help';
import ECOM_Cancel  from '@salesforce/label/c.ECOM_Cancel';
import ECOM_Submit  from '@salesforce/label/c.ECOM_Submit';
import ECOM_Close  from '@salesforce/label/c.ECOM_Close';
import ECOM_Track_Shipment  from '@salesforce/label/c.ECOM_Track_Shipment';
import ECOM_Cancelled  from '@salesforce/label/c.ECOM_Cancelled'; //RWPS-2554
import ECOM_Tariff_Surcharge  from '@salesforce/label/c.ECOM_Tariff_Surcharge'; //RWPS-3026

//VRa-punchout changes - 1 Feb 24- begin
//apex
import encodeUrlParams from '@salesforce/apex/ECOM_UserController.getEncyrptedSessionParametersForCMS';

//label
import LBL_URL_PATH_SEPARATOR from '@salesforce/label/c.ECOM_UrlPathSeparator';
import LBL_CMS_PARAM_PREFIX  from '@salesforce/label/c.ECOM_CMSPunchoutLoginParameter';
import LBL_CMS_BUY_PAGE  from '@salesforce/label/c.ECOM_CMSBuyPage';
import ECOM_Add_to_Cart from '@salesforce/label/c.ECOM_Add_To_Cart_CTA';//RWPS-3835
import ECOM_Free_Item from '@salesforce/label/c.ECOM_Free_Item';//RWPS-3811
import discontinuedTooltipText from "@salesforce/label/c.ECOM_Discontinued_Product_Tooltip_Text";//RWPS-4602
import discontinuedText from "@salesforce/label/c.ECOM_Product_Tile_Discontinued_Text";//RWPS-4602
import ECOM_Tracking_Timeline_Values from "@salesforce/label/c.ECOM_Tracking_Timeline_Values";//RWPS-5181


import { SYSTEM_CONSTANTS, parseJSON, SYSTEM_LABELS, APEX_ACTIONS, getUserConfigData, setToSessionStorage} from 'c/ecom_punchoutUtil';
//VRa-punchout changes - 1 Feb 24- end

const STEP_COUNTER_CLASS = 'step-counter'; //RWPS-5181
const STEP_COUNTER_AND_ACTIVE_CLASS = 'step-counter active'; //RWPS-5181
const ACTIVE_TRACKING_INFO_CLASS = 'tracking-info slds-no-print'; //RWPS-5181
const INACTIVE_TRACKING_INFO_CLASS = 'no-tracking-info slds-no-print'; //RWPS-5181

export default class Ecom_orderItems extends LightningElement {

    labels = {
        ECOM_PartNumber,
        ECOM_Unit_Size,
        ECOM_Shipment_Date,
        ECOM_AddToCart,
        ECOM_Save_favorites,
        ECOM_Remove_Favorites,
        ECOM_Help,
        ECOM_Qty,
        ECOM_Open,
        ECOM_Partially_Shipped,
        ECOM_Shipped,
        Ecom_Cancel_close,
        ECOM_HelpReason,
        ECOM_Reason,
        ECOM_Reason_for_Needing_Help,
        ECOM_Cancel,
        ECOM_Submit,
        ECOM_Close,
        ECOM_Track_Shipment,
        ECOM_AddedToCartSuccessfully,
        ECOM_105105,
        LBL_URL_PATH_SEPARATOR,
        LBL_CMS_PARAM_PREFIX,
        LBL_CMS_BUY_PAGE,
        ECOM_Cancelled, //RWPS-2554
        ECOM_Tariff_Surcharge, //RWPS-3026
        ECOM_Add_to_Cart,//RWPS-3835
        ECOM_Free_Item, //RWPS-3811,
        discontinuedTooltipText, //RWPS-4602
        discontinuedText, //RWPS-4602
        ECOM_Tracking_Timeline_Values //RWPS-5181
    }

    @api
    isOrderCancelled; //RWPS-2554
    @api
    item;
    @api
    multiTracking;
    @api
    wishlist;
    @api
    isPromoApplied;
    @api prodImages;
    @api isSapOrder;
    @api orderCurrencyCode;
    @api orderSalesStatus;
    //RWPS-622
    @api isLargePackOrder;
    orderDetailForDatalayer;
    currentItemId;
    picklistValue;
    editReason;
    itemStatus;
    options=[];
    formMappings=[];
    orderItemsList = [];
    effectiveAccountId;
    modalSize='';
    showSpinner=false;
    isHelpModalOpen = false;
    showHelp=true;
    showResponse=false;
    firstStepComplete = false;
    secondStepComplete = false;
    thirdStepComplete = false;
    firstStepListClass;
    secondStepListClass;
    thirdStepListClass;
    firstStepBtnClass;
    secondStepBtnClass;
    thirdStepBtnClass;
    message='';
    msg;
    type;
    show;
    timeSpan = 3000;
    itemShipped = false;
    currencyDisplayAs='code';
    cardClass = 'slds-grid slds-wrap ecom-cart-product-border radiun-top'; // RWPS-5181
    @track isButtonDisabled = true;
    @track cssClass = 'ecom-submit-btn-diabled slds-m-left_medium';
    @wire(MessageContext)
    messageContext;
    #escapeKeyCallback; // RWPS-4087

    images = {
        carticon:sres_ECOM_CartIcons + '/img/cartIcon.svg',
        deleteimg: sres_ECOM_CartIcons + '/img/deleteicon.svg',
        quickorderimg:sres_ECOM_CartIcons + '/img/quick-order.png',
        favoriteimg:sres_ECOM_CartIcons + '/img/hearticon.svg',
        helpimg:sres_ECOM_CartIcons + '/img/help-icon.png',
        termsimg:sres_ECOM_CartIcons + '/img/pencil-line.png',
        stepcomplete:sres_ECOM_CartIcons + '/img/stepcomplete.png',
        needhelpicon:sres_ECOM_CartIcons + '/img/needhelpicon.svg',
        placeholderimg:sres_ECOM_CartIcons + '/img/placeholder.png',
    }

    @api
    device = {
        isMobile : FORM_FACTOR==='Small',
        isDesktop : FORM_FACTOR==='Large' || FORM_FACTOR==='Medium'
    }
    // RWPS-4602 - START
    @api replacementMap;
    replacementData = [];
    showReplacements = false;
    directReplacement = false;
    alternativeReplacements = false;
    discontinuedProduct = false;
    showAddToCart=false;
    @api replacementPriceMap;
    // RWPS-4602 - END

    @track
    progressBarCollection; //RWPS-5181;
    showTrackingTimeline = false //RWPS-5181
    applicableTrackingClass; //RWPS-5181

    // get options() {
    //     return [
    //         { label: 'Modify', value: 'modifyItem' },
    //         { label: 'Cancel', value: 'cancelOrder' },
    //         { label: 'Request Return', value: 'requestReturn' },
    //         { label: 'Complaint', value: 'complaint' }
    //     ];
    // }

    // RWPS-5286 start
    get searchTerm() {
        let search = new URLSearchParams(location.search).get('search');
        return search ? search : '';
    }
    // RWPS-5286 end

    get isFavorite(){
        return this.wishlist && this.wishlist[this.item.product.id] ? true : false;
    }

    get itemImages(){
        return {
            imgUrl : resolve(this.prodImages[this.item.product.id])
        }
    }

    get showStrikePrice(){
        if((parseFloat(this.item.listPrice) > parseFloat(this.item.unitPrice)) && this.isPromoApplied){
            return true;
        }
        else{
            return false;
        }
    }
    get hideShipDate(){
        if(this.orderSalesStatus[this.item?.product2Id]){
            return this.orderSalesStatus[this.item.product2Id];
        }
        else{
            return false;
        }
    }

    get sapUnitPrice(){
        return (this.item?.totalPrice/this.item?.quantity);
    }

    get orderItemStatus() {
        //RWPS-5181
        if(this.item?.status && this.item.status != 'Cancelled' && this.item.status != 'Removed') {
            this.itemStatus = this.item.status;
            this.showTrackingTimeline = true;
        } else {
            this.showTrackingTimeline = false;
        }
        //RWPS-5181
        if (this.itemStatus) {
            this.itemShipped = this.itemStatus == ECOM_Tracking_Timeline_Values.split(',')[2] ? true : false;
            let stepNumber = 0;
            for (let step in this.progressBarCollection) {
                if (this.progressBarCollection[step].stepName == this.itemStatus) {
                    stepNumber = this.progressBarCollection[step].stepNumber;
                }
            }
            this.updateProgressBar(stepNumber);
        }
        //RWPS-5181 : Keeping order cancelled behaviour as is
        if (this.item?.status == 'Cancelled') { //RWPS-2554 added condition for cancel status
           this.isOrderCancelled = true;
        } else {
            this.isOrderCancelled = false; //RWPS-5181
        }
        //RWPS-5181
        if (this.showTrackingTimeline == true && this.isOrderCancelled == false) {
            this.applicableTrackingClass = ACTIVE_TRACKING_INFO_CLASS;
        } else {
            if (this.isOrderCancelled == true) {
                this.applicableTrackingClass = ACTIVE_TRACKING_INFO_CLASS;
            } else {
                this.applicableTrackingClass = INACTIVE_TRACKING_INFO_CLASS;
            }
        }
        //RWPS-5181
        return true;
    }

    /**
     * RWPS-5181
     * Sachin V - 2025-11-19
     * This method sets the styling according to current status of order item
     */
    updateProgressBar(stepNumber) {
        let parsedProgressBarCollection = [];
        parsedProgressBarCollection = JSON.parse(JSON.stringify(this.progressBarCollection));
        for (let step in parsedProgressBarCollection) {
            if (parsedProgressBarCollection[step] && parsedProgressBarCollection[step].stepNumber == stepNumber) {
                parsedProgressBarCollection[step].stepStyling = STEP_COUNTER_AND_ACTIVE_CLASS;
                parsedProgressBarCollection[step].isActive = true;
                parsedProgressBarCollection[step].isComplete = false;
            }
            if (parsedProgressBarCollection[step] && parsedProgressBarCollection[step].stepNumber < stepNumber) {
                parsedProgressBarCollection[step].stepStyling = STEP_COUNTER_CLASS;
                parsedProgressBarCollection[step].isActive = false;
                parsedProgressBarCollection[step].isComplete = true;
            }
            if (parsedProgressBarCollection[step] && parsedProgressBarCollection[step].stepNumber > stepNumber) {
                parsedProgressBarCollection[step].stepStyling = STEP_COUNTER_CLASS;
                parsedProgressBarCollection[step].isActive = false;
                parsedProgressBarCollection[step].isComplete = false;
            }
        }
        this.progressBarCollection = JSON.parse(JSON.stringify(parsedProgressBarCollection));
    }

    /**
     * RWPS-5181
     * Sachin V - 2025-11-19
     * This method performs the initial setup of tracking timeline components
     */
    setupProgressBar() {
        let trackingCollection = [];
        for (let index=0; index<ECOM_Tracking_Timeline_Values.split(',').length; index++) {
            let progressBarItem = {};
            progressBarItem.stepName = ECOM_Tracking_Timeline_Values.split(',')[index];
            progressBarItem.displayLabel = ECOM_Tracking_Timeline_Values.split(',')[index];
            progressBarItem.stepNumber = index;
            progressBarItem.stepStyling = STEP_COUNTER_CLASS;
            progressBarItem.isActive = false;
            progressBarItem.isComplete = false;
            trackingCollection.push(progressBarItem);
        }
        this.progressBarCollection = JSON.parse(JSON.stringify(trackingCollection));
    }

    //RWPS-3258 - Start

    get itemTracking() {
        if (this.item?.OrderItemTrackings) {
            // Create a new array with cloned items and new property
            return this.item.OrderItemTrackings.map(tracking => {
                const clonedTracking = { ...tracking }; // shallow clone
                if (clonedTracking?.trackingURL) {
                    clonedTracking.isValidUrl = !this.isInvalidUrl(clonedTracking.trackingURL);
                }
                return clonedTracking;
            });
        }
        return null;
    }



    isInvalidUrl(urlString) {
        try {
            new URL(urlString);
            return false;
        } catch (error) {
            return true;
        }
    }

     //RWPS-3258 - End

    showMessage(message,type,show){
        this.msg = message;
        this.type = type;
        this.show = show;
    }
//RWPS-2734
    clearMessage(){
        this.msg = '';
        this.show = false;
    }

    handlePicklistChange(event) {
        var enableSubmit=false;
        var isButtonDisabled=true;
        this.picklistValue = event.detail.value;
        if(this.editReason!=null && this.editReason!=undefined && this.editReason!='')
        {
            enableSubmit=true;
            isButtonDisabled=false;
        }
        this.cssClass = enableSubmit ? 'ecom-submit-btn-active slds-m-left_medium' : 'ecom-submit-btn-diabled slds-m-left_medium';
        this.isButtonDisabled=isButtonDisabled;
    }

    handleTextChange(event){
        this.editReason = event.detail.value;
        var enabledSumbit=true;
        var isButtonDisabled=false;
        if(this.editReason==null || this.editReason==undefined || this.editReason=='' || this.picklistValue==null || this.picklistValue==undefined || this.picklistValue=='')
        {
            isButtonDisabled=true;
            enabledSumbit=false;
        }
        this.cssClass = enabledSumbit ? 'ecom-submit-btn-active slds-m-left_medium' : 'ecom-submit-btn-diabled slds-m-left_medium';
        this.isButtonDisabled=isButtonDisabled;

    }

    connectedCallback(){
        this.setupProgressBar(); // RWPS-5181
        if(this.multiTracking && !this.isSapOrder){
            this.cardClass = 'slds-grid slds-wrap ecom-cart-product-border radiun-top';
        }

        const result = contextApi.getSessionContext();
        result.then((response) => {
            this.effectiveAccountId = response.effectiveAccountId;
        }).catch((error) => {

        });
        this.loadBasedOnDeviceType();
        //RWPS-4087 start
        this.#escapeKeyCallback = this.escapeKeyCallback.bind(this);
        document.addEventListener('keydown', this.#escapeKeyCallback);

        // RWPS-4602 - START
        if(this.replacementMap && this.replacementMap[this.item.product.id]) {
            let replacementInfo = this.replacementMap[this.item.product.id];
            if(replacementInfo.DirectReplacement) {
                this.replacementData = [{...replacementInfo.DirectReplacement}];
                this.directReplacement = true;
            } else {
                this.replacementData = JSON.parse(JSON.stringify(replacementInfo.AlternativeReplacements));
                this.alternativeReplacements = true;
            }

            this.showReplacements = true;
        }
        // RWPS-4602 ENDS
    }
    disconnectedCallback() {
        document.removeEventListener('keydown', this.#escapeKeyCallback);
    }

    escapeKeyCallback(event) {
        if (event.key === 'Escape' || event.keyCode === 27) {
            if(this.isHelpModalOpen && this.showHelp) {
                this.handleCloseHelpModal(event);
            }
            if(this.showResponse) {
                this.handleCloseHelpModal();
            }

        }
    }// RWPS-4087 end


    loadBasedOnDeviceType() {
        if (this.device.isMobile) {
            this.modalSize = "slds-modal slds-fade-in-open slds-modal_full";
            this.footerCloseCss='slds-col slds-size_12-of-12 slds-large-size_6-of-12 slds-medium-size_6-of-12 slds-small-size_12-of-12 slds-p-top_small'
        } else {
            this.modalSize = "slds-modal slds-fade-in-open modalCSS";
            this.footerCloseCss='slds-col slds-size_12-of-12 slds-large-size_6-of-12 slds-medium-size_6-of-12 slds-small-size_12-of-12'
        }
    }

    renderedCallback(){
        if(this.item!=null && this.item!=undefined){
            getDataLayerDataByOrder({orderId:this.item.orderId})
             .then(result=>{
                this.orderDetailForDatalayer=result;
            })
            .catch(error => {
            });
        }
    }

    handleOpenHelpModal(event){
        this.currentItemId = event.currentTarget.dataset.id;
        this.showSpinner=true;
        this.getFormMapping();

        //Preparing data for form_view event which will be push to DataLayer
        try {
            this.prepareDataLayerData('form_view',this.item,'');
        } catch (error) {
          }
    }

    getFormMapping()
    {
        getAssociatedReasons({
            orderItemId : this.currentItemId
        }).then(result=>{
            if(result.Success)
            {
                var formMappings=result.FormMapping;
                var mappings=[];
                for(var i in formMappings)
                {
                    mappings.push({
                        label : formMappings[i].Option__c,
                        value : formMappings[i].Option__c
                    });
                }
                this.options=mappings;
                this.formMappings=formMappings;
                this.isHelpModalOpen = true;
                 //RWPS-4087 start
                requestAnimationFrame(() => {
                    const modal = this.template.querySelector('.showHelpModal');
                    if (modal) {
                        modal.focus();
                    }
                }); //RWPS-4087 end
            }
            this.showSpinner=false;
        }).catch(error=>{
            this.showSpinner=false;
        });
    }

    handleSubmit(event)
    {
        this.showSpinner=true;
        var items=this.formMappings;
        var formFactor='';
        for(var i in items)
        {
            if(items[i].Option__c==this.picklistValue)
            {
                formFactor=items[i].formType__c;
                break;
            }
        }
        makeCallout({
            orderItemId : this.currentItemId,
            formFactor : formFactor,
            reason : this.picklistValue,
            comment : this.editReason
        }).then(result=>{
            if(result.Success)
            {
                this.message=result.SuccessMessage;
            }
            else
            {
                this.message=result.Message;
            }
            this.showHelp=false;
            this.showResponse=true;
             //RWPS-4087 start
            requestAnimationFrame(() => {
                const modal = this.template.querySelector('.showResponseModal');
                if (modal) {
                    modal.focus();
                }
            });
             //RWPS-4087 end
            this.showSpinner=false;

        }).catch(error=>{
            this.showHelp=false;
            this.showResponse=true;
            //RWPS-4087 start
            requestAnimationFrame(() => {
                const modal = this.template.querySelector('.showResponseModal');
                if (modal) {
                    modal.focus();
                }
            }); //RWPS-4087 end
            this.message=result.Message;
            this.showSpinner=false;
        });

        //Preparing data for form_submit event which will be push to DataLayer
        try {
            this.prepareDataLayerData('form_submit',this.item,'');
        } catch (error) {
          }

    }

    handleCloseHelpModal(){
        this.isHelpModalOpen = false;
        this.showHelp=true;
        this.showResponse=false;
        this.message='';
        this.cssClass = 'ecom-submit-btn-diabled slds-m-left_medium';
    }

    setOrderItemsList(){
        this.orderItemsList.push({Product2Id: this.item.product.id, Quantity: this.item.quantity});
    }

    //RWPS-2786- START
      handleUpdateMessage(){
            this.msg = '';
            this.type = '';
            this.show = false;
        }
     //RWPS-2786- START

    // Add item to the cart
    handleAddToCart(){
        // RWPS-4086 start
        if(this.showSpinner) {
            return;
        }
        // RWPS-4086 end

        this.orderItemsList = []; //RWPS-1777
        this.showSpinner = true;
        this.setOrderItemsList();
        this.clearMessage(); //RWPS-2734
        if(this.orderItemsList.length > 0){
            // Call the 'addItemsToCart' apex method imperatively
            addItemsToCart({
                communityId: communityId,
                effectiveAccountId: this.effectiveAccountId,
                cartItems: this.orderItemsList
            }).then((result) => {
                if(result.itemsAddedSuccessfully[0] == this.item.product.id){
                    this.showMessage(
                        this.labels.ECOM_AddedToCartSuccessfully,
                        'success',
                        true
                    );

                    // RWPS-3125 start
                    trackAddProductToCart(
                        {
                            id: this.item.product.id,
                            sku: this.item.product.partNumber,
                            quantity: 1,
                            price: ''
                        }
                    );
                    // RWPS-3125 end
                }
                else{
                    this.showMessage(
                        this.labels.ECOM_105105,
                        'error',
                        true
                    );
                }

                let payLoad = {message:1,
                    type: 'CartRefresh'
                };
                publish(this.messageContext, ECOM_MESSAGE, payLoad);
                this.showSpinner = false;
            }).catch((error) => {
                this.showSpinner = false;
                console.log(error);
                this.showMessage(
                    this.labels.ECOM_105105,
                    'error',
                    true
                );
                //Preparing data for remove_from_wishlist event which will be push to DataLayer
                try {
                    this.prepareDataLayerData('add_to_cart_error',this.item,'');
                } catch (error) {
                    console.error('Error occured during preparing DataLayer data for add_to_cart_error event ',error);
                }
            });
        }
        //Preparing data for add_to_cart event which will be push to DataLayer
        try {
            this.prepareDataLayerData('add_to_cart',this.item,'');
        } catch (error) {
            console.error('Error occured during preparing DataLayer data for add_to_cart event',error);
        }
    }

    handleAddToFavourite(){
        //RWPS-4200 Start
        let btn = event.currentTarget;
        btn.disabled = true;
        //RWPS-4200 End
        this.dispatchEvent(
            new CustomEvent('createandaddtolist', {
                detail: {
                    productId: this.item?.product?.id,
                    productName : this.item?.product?.name,
                    buttonRef: btn //RWPS-4200
                }
            }, {
                bubbles: true,
                composed:true
              })
        );

        //Preparing data for add_to_wishlist event which will be push to DataLayer
        try {
            this.prepareDataLayerData('add_to_wishlist',this.item,'');
        } catch (error) {
          }
    }

    handleRemoveFromFavourite(){
        //RWPS-4200 Start
        let btn = event.currentTarget;
        btn.disabled = true;
        //RWPS-4200 End
        this.dispatchEvent(
            new CustomEvent('removefromfavorite', {
                detail: {
                    wishlistItemId:this.wishlist[this.item.product.id].wishListItemId,
                    buttonRef: btn //RWPS-4200
                }
            }, {
                bubbles: true,
                composed:true
              })
        );

        //Preparing data for remove_from_wishlist event which will be push to DataLayer
        try {
            this.prepareDataLayerData('remove_from_wishlist',this.item,'');
        } catch (error) {
          }
    }

    //DataLayer regarding changes starts
    prepareDataLayerData(eventName,item,error){
        var data;
        let hasImage = this.itemImage!=null && this.itemImage!=undefined? true: false;

        //for add_to_wishlist event
        if(eventName==='add_to_wishlist'){
            this.data =  {
                event: 'add_to_wishlist',
                product:{
                    businessUnit:this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.superBussinessUnit +'-'+ this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.subBussinessUnit||undefined,
                    productClass:this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.productClass||undefined,
                    productLine:this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.productLine +'-'+ this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.productLineName||undefined,
                    productBrand:this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.productBrand||undefined,
                    paccode:this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.paccode +'-'+ this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.igorDescription||undefined,
                    productName:this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.name||undefined,
                    modelName: this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.name||undefined,
                    partNumber: this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.partNumber||undefined,
                    sapStatus: this.orderDetailForDatalayer?.productSalesStatus[this.item.product2Id] ||undefined
                        }
            }
        this.handlePublishMsg(this.data);
        }

        //for remove_from_wishlist event
        if(eventName==='remove_from_wishlist'){
            this.data =  {
                            event: 'remove_from_wishlist',
                            product:{
                                businessUnit:this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.superBussinessUnit +'-'+ this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.subBussinessUnit||undefined,
                                productClass:this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.productClass||undefined,
                                productLine:this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.productLine +'-'+ this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.productLineName||undefined,
                                productBrand:this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.productBrand||undefined,
                                paccode:this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.paccode +'-'+ this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.igorDescription||undefined,
                                productName:this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.name||undefined,
                                modelName: this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.name||undefined,
                                partNumber: this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.partNumber||undefined,
                                sapStatus: this.orderDetailForDatalayer?.productSalesStatus[this.item.product2Id] ||undefined,
                            }
            }
        this.handlePublishMsg(this.data);
        }

        //for add_to_cart event
        if(eventName==='add_to_cart'){
            this.data =  {
                'event': 'add_to_cart',
                'addToCartLocation': 'Order History - ' + this.labels.ECOM_Add_to_Cart,//RWPS-3835
                'items': [{
                            'name': this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.name ||undefined,
                            'partNumber':this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.partNumber ||undefined,
                            'paccode':this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.paccode +'-'+ this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.igorDescription||undefined,
                            'businessUnit':this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.superBussinessUnit +'-'+ this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.subBussinessUnit||undefined,
                            'portfolioLevel2':this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.portfolioLevel2 ||undefined,
                            'productLine':this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.productLine +'-'+ this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.productLineName||undefined,
                            'productClass':this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.productClass ||undefined ,
                            'productBrand':this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.productBrand ||undefined ,
                            'sapStatus': this.orderDetailForDatalayer?.productSalesStatus[this.item.product2Id]  ||undefined,
                            'hasImage': this.prodImages[this.item.product2Id]? true:false ,
                            'quantity':  this.item.quantity ||undefined,
                            'price': this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.price ||undefined ,
                            'listPrice': this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.listPrice ||undefined,
                            'currency': this.orderDetailForDatalayer?.order.CurrencyIsoCode ||undefined
                }],
                _clear:true
            }
        this.handlePublishMsg(this.data);
        }

        //for add_to_cart_error event
        if(eventName==='add_to_cart_error'){
            this.data =  {
                'event': 'add_to_cart_error',
                'addToCartLocation': 'Order History -' +  this.labels.ECOM_Add_to_Cart,//RWPS-3835
                'product': [{
                            'name': this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.name ||undefined,
                            'partNumber':this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.partNumber ||undefined,
                            'paccode':this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.paccode +'-'+ this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.igorDescription||undefined,
                            'businessUnit':this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.superBussinessUnit +'-'+ this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.subBussinessUnit||undefined,
                            'portfolioLevel2':this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.portfolioLevel2 ||undefined,
                            'productLine':this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.productLine +'-'+ this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.productLineName||undefined,
                            'productClass':this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.productClass ||undefined ,
                            'productBrand':this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.productBrand ||undefined ,
                            'sapStatus': this.orderDetailForDatalayer?.productSalesStatus[this.item.product2Id]  ||undefined,
                            'hasImage': this.prodImages[this.item.product2Id]? true:false ,
                            'quantity':  this.item.quantity ||undefined,
                            'price': this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.price ||undefined ,
                            'listPrice': this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.listPrice ||undefined,
                            'currency': this.orderDetailForDatalayer?.order.CurrencyIsoCode ||undefined
                }],
                "error message":error?.body?.message || error,

                _clear:true
            }
        this.handlePublishMsg(this.data);
        }

        //for form_view event
        if(eventName==='form_view'){
            this.data =  {
                event: 'form_view',
                'form': {
                    'id':'webform_submission_contact_us_sales_node_146_add_form',
                    'type':'RAQ',
                        },
                'product': {
                            'name': this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.name ||undefined,
                            'partNumber':this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.partNumber ||undefined,
                            'paccode':this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.paccode +'-'+ this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.igorDescription||undefined,
                            'businessUnit':this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.superBussinessUnit +'-'+ this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.subBussinessUnit||undefined,
                            'portfolioLevel2':this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.portfolioLevel2 ||undefined,
                            'productLine':this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.productLine +'-'+ this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.productLineName||undefined,
                            'productClass':this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.productClass ||undefined ,
                            'productBrand':this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.productBrand ||undefined ,
                            'sapStatus': this.orderDetailForDatalayer?.productSalesStatus[this.item.product2Id]  ||undefined,
                            'hasImage': this.prodImages[this.item.product2Id]? true:false
                            },
                _clear:true
            }
        this.handlePublishMsg(this.data);
        }

        //for form_submit event
        if(eventName==='form_submit'){
            this.data =  {
                event: 'form_submit',
                'form': {
                    'id':'webform_submission_contact_us_sales_node_146_add_form',
                    'type':'RAQ',
                        },
                'product': {
                            'name': this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.name ||undefined,
                            'partNumber':this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.partNumber ||undefined,
                            'paccode':this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.paccode +'-'+ this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.igorDescription||undefined,
                            'businessUnit':this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.superBussinessUnit +'-'+ this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.subBussinessUnit||undefined,
                            'portfolioLevel2':this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.portfolioLevel2 ||undefined,
                            'productLine':this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.productLine +'-'+ this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.productLineName||undefined,
                            'productClass':this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.productClass ||undefined ,
                            'productBrand':this.orderDetailForDatalayer?.dataLayer[this.item.product2Id]?.productBrand ||undefined ,
                            'sapStatus': this.orderDetailForDatalayer?.productSalesStatus[this.item.product2Id]  ||undefined,
                            'hasImage': this.prodImages[this.item.product2Id]? true:false
                        },
                _clear:true
            }
        this.handlePublishMsg(this.data);
        }
        this.handlePublishMsg(data);
    }


    handlePublishMsg(data) {

        let payLoad = {
            data: data,
            type: 'DataLayer',
            page: 'cart'
        };
        publish(this.messageContext, ECOM_DATALAYERCHANNEL, payLoad);
    }

     // RWPS-4087 start
     navigateToPDPEnter(event) {
        if (event.key === 'Enter' || event.keyCode === 13) {
            this.navigateToPDP(event);
        }
    }
    // RWPS-4087 end
    //DataLayer regarding changes ends
    navigateToPDP(event) {
        let payLoad = {
            message: NAVIGATE_TO_PDP,
            type: CMS_NAVIGATION,
            partNumber: '',
            url: this.item?.product?.displayUrl || ''
        };
        //VRa: punchout changes - 1 Feb 24 - begin
        let userConfig = getUserConfigData();
        //console.log('userConfig:: ', parseJSON(userConfig));//Remove after DEV
        if(userConfig && userConfig.isPunchoutUser){
            let urlParams = '';
            encodeUrlParams().then(result => {
                //console.log('result:: '+ parseJSON(result));//Remove after DEV
                if(result && result?.success && result?.responseData){
                    let baseUrl = result.Home ;
                    //RWPS-1817
                    if(result.locale && result.locale != ''){
                        if (baseUrl.substr(-1) != '/'){
                            baseUrl += this.labels.LBL_URL_PATH_SEPARATOR;
                        }
                        baseUrl = baseUrl +  result.locale;
                    }
                    urlParams = result.responseData;
                    //console.log('baseUrl:: ', baseUrl + this.favorite.productDetail?.fields?.DisplayUrl + this.labels.LBL_CMS_PARAM_PREFIX + urlParams);//Remove after DEV
                    window.location.href = baseUrl + this.item?.product?.displayUrl + this.labels.LBL_CMS_PARAM_PREFIX + urlParams;//Remove after DEV
                } else {
                    publish(this.messageContext, ECOM_MESSAGE, payLoad);
                }
            }).catch(error => {
            //do not console log
            });
        }else {
            publish(this.messageContext, ECOM_MESSAGE, payLoad);
        }
    }

    // RWPS - 4602 - START
    @track discontinuedIconRect = {};

    handleDiscontinuedLabelClick() {
        this.refs.discontinuedSVG?.focus();
    }

    updateDiscontinuedIconRect() {
        let iconRect = this.refs.discontinuedSVG?.getBoundingClientRect();
        this.discontinuedIconRect = iconRect ? iconRect : {};
    }

    handlePopupRequestNewRect() {
        this.updateDiscontinuedIconRect();
    }

    discontinuedMouseOverActive = false;
    discontinuedFocusActive = false;
    showReplacementPopup() {
        this.updateDiscontinuedIconRect();
        this.refs.popupCarousel?.togglePopup(true);
    }

    hideReplacementPopup() {
        if(!this.discontinuedFocusActive && !this.discontinuedMouseOverActive) {
            this.refs.popupCarousel?.togglePopup(false);
        }
    }

    handleDiscontinuedMouseEnter() {
        this.discontinuedMouseOverActive = true;
        this.showReplacementPopup();
    }

    handleDiscontinuedMouseLeave() {
        this.discontinuedMouseOverActive = false;
        this.hideReplacementPopup();
    }

    handleDiscontinuedFocus() {
        this.discontinuedFocusActive = true;
        this.showReplacementPopup();
    }

    handleDiscontinuedBlur() {
        setTimeout(() => {
            if(this.refs.discontinuedSVG != this.template.activeElement && !this.refs.popupCarousel?.isFocused()) {
                this.discontinuedFocusActive = false;
                this.hideReplacementPopup();
            }
        }, 0);
    }
}