import FORM_FACTOR from '@salesforce/client/formFactor';
import ECOM_DATALAYERCHANNEL from '@salesforce/messageChannel/ecom_DataLayer__c';
import ECOM_MESSAGE from '@salesforce/messageChannel/ecom_MessagingChannel__c';
import sres_ECOM_CartIcons from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import { deleteItemFromCart, sendPostMessage, updateItemInCart } from 'c/ecom_util';
import { resolve } from 'experience/resourceResolver';
import { MessageContext, publish } from 'lightning/messageService';
import { LightningElement, api, track, wire } from 'lwc';
import getUserInfo from "@salesforce/apex/ECOM_CartController.getUserInfo";
import updateCartItemListPrice from "@salesforce/apex/ECOM_CartController.updateCartItemListPrice";
import { NavigationMixin } from 'lightning/navigation';

//VRa-punchout changes - 1 Feb 24- begin
//apex
import encodeUrlParams from '@salesforce/apex/ECOM_UserController.getEncyrptedSessionParametersForCMS';

//label
import LBL_URL_PATH_SEPARATOR from '@salesforce/label/c.ECOM_UrlPathSeparator';
import LBL_CMS_PARAM_PREFIX  from '@salesforce/label/c.ECOM_CMSPunchoutLoginParameter';
import LBL_CMS_BUY_PAGE  from '@salesforce/label/c.ECOM_CMSBuyPage';
// RWPS-2486 START
import ECOM_Remove from '@salesforce/label/c.ECOM_Remove';
import ECOM_Remove_Favorites  from '@salesforce/label/c.ECOM_Remove_Favorites';
import ECOM_SaveToFavorites  from '@salesforce/label/c.ECOM_SaveToFavorites';
import ECOM_ShipEarlyDate  from '@salesforce/label/c.ECOM_ShipEarlyDate';
import ECOM_Select_Date  from '@salesforce/label/c.ECOM_Select_Date';
import ECOM_Product_Receive_Message  from '@salesforce/label/c.ECOM_Product_Receive_Message';
import ECOM_Each  from '@salesforce/label/c.ECOM_Each';
import ECOM_EstimatedToShipBy  from '@salesforce/label/c.ECOM_EstimatedToShipBy';
import ECOM_EstDeliveryDate  from '@salesforce/label/c.ECOM_Estimated_Delivery_Date';  //RWPS-1606
import ECOM_EstDeliveryDate_Message  from '@salesforce/label/c.ECOM_Estimated_Delivery_Date_Message';  //RWPS-1606
import ECOM_Training_Product  from '@salesforce/label/c.ECOM_Training_Product';  //RWPS-4896
import ECOM_LockInSpecificDate  from '@salesforce/label/c.ECOM_LockInSpecificDate';
import ECOM_PartNumber  from '@salesforce/label/c.ECOM_PartNumber';
import ECOM_Tariff_Surcharge  from '@salesforce/label/c.ECOM_Tariff_Surcharge';
import ECOM_Discontinued_Message  from '@salesforce/label/c.ECOM_Discontinued_Message';//RWPS-2786
import ECOM_Contact_Us_Url  from '@salesforce/label/c.ECOM_Contact_Us_Url';//RWPS-2786
import ECOM_Add_to_Cart from '@salesforce/label/c.ECOM_Add_To_Cart_CTA';//RWPS-3835
import ECOM_Free_Item from '@salesforce/label/c.ECOM_Free_Item';//RWPS-3811
import {processAndLogJSError} from 'c/ecom_util'; // RWPS-5153

// RWPS-2486 END
//import js
import {getUserConfigData, setToSessionStorage,SYSTEM_CONSTANTS,parseJSON} from 'c/ecom_punchoutUtil';
//VRa-punchout changes - 1 Feb 24- end

const NAVIGATE_TO_PDP = 'PDP';
const CMS_NAVIGATION = 'CMSNavigation';

export default class Ecom_cartItem extends NavigationMixin(LightningElement){

    showSpinner = false;
    _item;
    _quantity;
    @api
    cartShippingDates;
    @api cartitemDiscontinuedProducts;//RWPS-2786
    @api cartItemTariffCharge; //RWPS-3026
    @api trainingProductMap; //RWPS-4896
    @api genericTrainingProductMap; //RWPS-4896
    @api cartSalesStatus;
    @api isPromoApplied;
    @api selectedItemId;
    showShipmentVal;
    @api totalShipment;
    @api
    wishlist;
    @api
    productFields;
    @api
    freeItemMap; //RWPS-3811
    itemQuantity;
    cardClassTop;
    cardClassBottom = 'radiun-bottom';
    @track cardSize = '';
    //RWPS-2786 - Start
    discontinuedMain = '';
    textDiscountinue = '';
    btnDiscontinue = '';
    //RWPS-2786 - end

    showModal = false;//RWPS-4896
    @track mobile='';
    @track cardQuantityCSS = '';
    @track cartPriceBoxCSS = '';
    currencyDisplayAs ='code';
    @track boxoneCSS='slds-col cart-shipping-box-active';
    @track boxtwoCSS='slds-col cart-shipping-box-2-inactive';
    @track imgSrc;
    shippingDays;//RWPS-1606
    estimatedDeliveryDate;//RWPS-1606
    shippingTimes;//RWPS-1606
    userRecord;
    error;
    @track addAddressError = '';
    showStrikePrice = false;
    _index;
    //RWPS-622
    _isLargePackOrder=false;
    //VRa-punchout changes - 1 Feb 24- begin

    @track _displayName;// RWPS-2207
    //RWPS-1606 - Start
    @track popoverClass = 'slds-popover slds-popover_tooltip slds-nubbin_bottom-right slds-fall-into-ground ecom-popover';
    @track showTooltip = false;
    popoverStyle = 'position:absolute; width:100%; padding:2px; text-align:left; background:white; bottom:39%; color:black; left:4%; border:1px solid #E3E3E3;'; //RWPS-1606
    fileName='ecom_cartItem';//RWPS-5153
    moduleName='ECOM_CartService / Checkout Management';//RWPS-5153


    showPopover(evt){
      this.showTooltip = true;
      //this.popoverClass = 'slds-popover slds-popover_tooltip slds-nubbin_bottom slds-rise-from-ground ecom-popover';
      this.popoverClass = 'slds-popover slds-popover_tooltip slds-nubbin_bottom-right slds-rise-from-ground ecom-popover';//14th-Nov
    }
    hidePopover(){
        this.showTooltip = false;
        this.popoverClass ='slds-popover slds-popover_tooltip slds-nubbin_bottom-right slds-fall-into-ground ecom-popover';
    }
     //RWPS-1606 - End
    //labels
    labels = {
        LBL_URL_PATH_SEPARATOR,
        LBL_CMS_PARAM_PREFIX,
        LBL_CMS_BUY_PAGE,
        ECOM_Remove,// RWPS-2486 - START
        ECOM_Remove_Favorites,
        ECOM_SaveToFavorites,
        ECOM_ShipEarlyDate,
        ECOM_Select_Date,
        ECOM_Product_Receive_Message,
        ECOM_Each,
        ECOM_EstimatedToShipBy,
        ECOM_LockInSpecificDate,
        ECOM_PartNumber,// RWPS-2486 - END
        ECOM_EstDeliveryDate, //RWPS-1606
        ECOM_EstDeliveryDate_Message, //RWPS-1606
        ECOM_Tariff_Surcharge, //RWPS-3026
        ECOM_Contact_Us_Url,//RWPS-2786
        ECOM_Discontinued_Message,//RWPS-2786
        ECOM_Add_to_Cart,//RWPS-3835
        ECOM_Free_Item, //RWPS-3811 
        ECOM_Training_Product//RWPS-4896       
    }
    //VRa-punchout changes - 1 Feb 24- end

    @wire(MessageContext)
    messageContext;
    removeAllQuantityOfItem=false;
    @api
    set index(value){
        this._index = value;
    }
    get index(){
        return this._index+1;
    }
    //RWPS-622
    get showShipment(){
        this.showShipmentVal = this.totalShipment > 1 ? true: false;
        for (var key in this.freeItemMap) { //RWPS-4194
            if(this.freeItemMap[key] == this._item.productDetails.fields.Part_Number__c) {
              this.showShipmentVal =false;
              break;  
            }
        }
        if(this.showShipmentVal  ){
            this.cardClassTop = this.isLargePackOrder ? 'slds-grid slds-wrap ecom-cart-product-with-split radiun-bottom' : 'slds-grid slds-wrap ecom-cart-product-with-split' ;
        }else if(this.isProductDiscontinued){//RWPS-2786
            this.cardClassTop = this.isLargePackOrder ?'slds-grid slds-wrap ecom-cart-product-without-split-largepack border-radius-8' :'slds-grid slds-wrap ecom-cart-product-without-split radiun-top gray-background';
        }
        else{
            this.cardClassTop = this.isLargePackOrder ?'slds-grid slds-wrap ecom-cart-product-without-split-largepack border-radius-8' :'slds-grid slds-wrap ecom-cart-product-without-split radiun-top';
        }
        return this.showShipmentVal;
    }
    //RWPS-622
    @api
    set isLargePackOrder(value){
        this._isLargePackOrder = value;
    }
    get isLargePackOrder(){
        return this._isLargePackOrder || this.freeItemMap?.[this._item?.cartItemId]; //RWPS-3811
    }
    get partNumberCode(){
        let partNumber = this.fields.filter((field,index)=>{
            return field.name === 'Part Number';
        });
        return partNumber[0].value;
    }
    @api
    set item(val) {
        this.showStrikePrice = false;
        this._item = val;
        this.quantity = Number(this._item?.quantity);
        this.earliestDate = this.cartShippingDates && this.cartShippingDates[this.item.cartItemId]?.ECOM_Earliest_Shipping_Date__c ||'';
        this.selectedDate = this.cartShippingDates && this.cartShippingDates[this.item.cartItemId]?.ECOM_Selected_Shipping_Date__c ||'';
        if(parseFloat(this.item.listPrice) > parseFloat(this.item.salesPrice)){
            this.showStrikePrice = true;
        }
    }
    get item() {
        return this._item;
    }
    set quantity(val) {
        this._quantity = val;
    }
    get quantity() {
        return this._quantity;
    }

    get productUrl(){
        return this.item?.productDetails?.fields?.DisplayUrl ||'';
    }
    @api
    fieldlabelmap;
    @api
    isCartDisabled = false;
    minQuantity=1;
    maxQuantity=999;
    get currencyCode(){
            return  this.item?.currencyIsoCode;
    }
    device = {
        isMobile : FORM_FACTOR==='Small',
        isDesktop : FORM_FACTOR==='Large',
        isTablet :FORM_FACTOR==='Medium'
    }

    #escapeKeyCallback; // RWPS-4086

    connectedCallback() {
        this.loadBasedOnDeviceType();
        this.imgSrc=this.images.helpimg
        this.displayName='';

        // RWPS-4086 start
        this.#escapeKeyCallback = this.escapeKeyCallback.bind(this);
        document.addEventListener('keydown', this.#escapeKeyCallback);
        // RWPS-4086 end
    }

    // RWPS-4086 start

    disconnectedCallback() {
        document.removeEventListener('keydown', this.#escapeKeyCallback);
    }

    escapeKeyCallback(event) {
        if (event.key === 'Escape' || event.keyCode === 27) {
            if(this.isRemoveModalOpen) {
                this.handleCloseRemoveModal();
            }
            if(this.isDateSelectorOpen) {
                this.handleCloseDateSelector();
            }
        }
    }

    // RWPS-4086 end

    //RWPS-1606-Start
    handleShippingDays(event){
        this.shippingDays = event.detail;
        this.calculateEstimatedDeliveryDate();//RWPS-1606
    }

    handleShippingTimes(event){ //RWPS-1606
        this.shippingTimes = event.detail;
    }

   calculateEstimatedDeliveryDate() { // RWPS-1606
    try{//RWPS-5153
        const earliestDateStr = this.cartShippingDates &&
            this.cartShippingDates[this.item.cartItemId]?.ECOM_Earliest_Shipping_Date__c || '';
        const earliestDate = earliestDateStr ? new Date(earliestDateStr) : null;
        const shippingDays = this.shippingDays[this.item.cartItemId] || 0;

        if (!earliestDate) {
            console.error('Earliest shipping date is not available');
            return null;
        }
        //RWPS-1603 - Start
        if (shippingDays === 0) {
            console.error('Shipping days is not available');
            return null;
        }

        let businessDaysAdded = 0;
        let estimatedDate = new Date(earliestDate);

        while (businessDaysAdded < shippingDays) {
            estimatedDate.setDate(estimatedDate.getDate() + 1);
            const dayOfWeek = estimatedDate.getDay();
            if (dayOfWeek !== 0 && dayOfWeek !== 6) { // Skip Sunday (0) and Saturday (6)
                businessDaysAdded++;
            }
        }

        this.estimatedDeliveryDate = estimatedDate;
        //RWPS-1603 - End
        } catch(error){//RWPS-5153 start
            processAndLogJSError(error, this.fileName, this.moduleName, 'calculateEstimatedDeliveryDate');
        }//RWPS-5153 end
    }

    //RWPS-1606-End

    @wire(MessageContext)
    messageContext;

    loadBasedOnDeviceType() {
        if (this.device.isMobile) {
            this.mobile = true;
            this.cardClassBottom = "radiun-bottom slds-small-size_12-of-12";
            this.cardSize = "cart-item-card-mobile";
            this.cardQuantityCSS = "slds-form-element ecom-cart-prod-qty-ctr-mobile";
            this.cartPriceBoxCSS = "slds-size_12-of-12 slds-large-size_3-of-12 slds-medium-size_3-of-12 slds-small-size_12-of-12 cartPriceBoxMobile";
            this.modalCSS = 'slds-modal slds-fade-in-open slds-modal_full';
            //RWPS-2786 - Start
            this.discontinuedMain = 'ecom-discontinued-mob';
            this.textDiscountinue = 'ecom-text-mob';
            this.btnDiscontinue = 'slds-button btn-discountinue-mob';
              //RWPS-2786 - End


        } else {
            this.cardSize = "cart-item-card";
            this.mobile = false;
            this.cardQuantityCSS = "slds-form-element ecom-cart-prod-qty-ctr";
            this.cartPriceBoxCSS = "slds-size_12-of-12 slds-large-size_3-of-12 slds-medium-size_3-of-12 slds-small-size_12-of-12 cartPriceBox";
            this.modalCSS = 'slds-modal slds-fade-in-open';
            this.textDiscountinue = '.ecom-text-mob';
            //RWPS-2786 - Start
            if(this.device.isTablet){
                this.btnDiscontinue = 'slds-button btn-discountinue-tablet';
            }else{
                this.btnDiscontinue = 'slds-button btn-discountinue';
            }
            this.discontinuedMain = 'ecom-discontinued-prod';
            this.textDiscountinue = 'ecom-text';

            //RWPS-2786 - End

        }
    }

    get itemShippingDates(){
        return {

            earliest : this.cartShippingDates && this.cartShippingDates[this.item.cartItemId]?.ECOM_Earliest_Shipping_Date__c ||'',
            selectedDate : this.cartShippingDates && this.cartShippingDates[this.item.cartItemId]?.ECOM_Selected_Shipping_Date__c ||''
        }

    }
    //RWPS-2786 - Start
    get isProductDiscontinued(){
        if (typeof this.cartitemDiscontinuedProducts !== 'undefined') {
            if(this.cartitemDiscontinuedProducts[this.item.productId]){
                return this.cartitemDiscontinuedProducts[this.item.productId];
            }else{
                return false;
            }
        }
     }
    //RWPS-2786 - Start

    //RWPS-3026 - Start
    get itemTariffAmount(){
        return {
            tarriffAmount: this.cartItemTariffCharge &&
            (parseFloat(this.cartItemTariffCharge[this.item.cartItemId]?.Tariff_Surcharge__c) > 0 ?
             this.cartItemTariffCharge[this.item.cartItemId]?.Tariff_Surcharge__c : '')
        }

    }

    //RWPS-3026 - End

    // RWPS-4896-START
    get isTrainingProduct() {
        if (typeof this.trainingProductMap !== 'undefined') {
            if (!Object.prototype.hasOwnProperty.call(this.trainingProductMap, this.item.productId)) {
                return false;
            }

            const isTraining = this.trainingProductMap[this.item.productId] || false;

            // Count entries in trainingProductMap
            const mapCount = Object.keys(this.cartitemDiscontinuedProducts).length;

            // If only one entry and it's training, return false
            if (mapCount === 1 && isTraining) {
                return false;
            }

            return isTraining;
        }
        return false;
    }

    //RWPS-4896
    get isGenericTrainingProduct() {
        if (this.isTrainingProduct == true) {
            return true;
        } else {
            if (this.genericTrainingProductMap) {
                if (!Object.prototype.hasOwnProperty.call(this.genericTrainingProductMap, this.item.productId)) {
                    return false;
                }

                const isTraining = this.genericTrainingProductMap[this.item.productId] || false;

                // Count entries in genericTrainingProductMap
                const mapCount = Object.keys(this.cartitemDiscontinuedProducts).length;
                if (isTraining == true) {
                    if (this.device.isMobile == true) {
                        this.cardClassBottom = 'training-product-container slds-small-size_12-of-12';
                    } else {
                        this.cardClassBottom = 'training-product-container';
                    }
                }
                return isTraining;
            }
            return false;
        }
    }
    // RWPS-4896-END

    get promoCodeApplied(){
        if(this.isPromoApplied && this.showStrikePrice){
            return true;
        }
        else{
            return false;
        }
    }
    get showGenericMsg(){
        if(this.cartSalesStatus[this.item.productId]){
            this.cardClassBottom = ''
            return this.cartSalesStatus[this.item.productId];
        }
        else{
            return false;
        }
    }
    _earliestDate;
    get earliestDate(){
        return this._earliestDate;
    }
    set earliestDate(dateValue){
        this._earliestDate = dateValue;
    }
    _selectedDate;
    get selectedDate(){
        return this._selectedDate;
    }
    set selectedDate(dateValue){
        this._selectedDate = dateValue;
    }

    // RWPS-2270 START
    get displayName(){
    return this._displayName;
    }

    set displayName(value){
        if(typeof value !==undefined && value !== null && value=='')
            {
                let temp = this.item?.productDetails?.fields?.Product_Display_Name__c;
                this._displayName = typeof temp !==undefined && temp !== null?temp:this.item.name;
                this._displayName = this._displayName.replaceAll('&lt;','<').replaceAll('&gt;','>');
            }
    }
      // RWPS-2270 END
    get fields(){
        try{//RWPS-5153 
        let fields = [];
        for (const [key, value] of Object.entries(this.item.productDetails.fields)) {
            if(key !== 'Dangerous_Goods_Indicator_Profile__c' && key !=='DisplayUrl'
                  && key!='ECOM_Product_Media_URI__c' && key!=='Product_Display_Name__c' ) // RWPS-2270 START
            {
                if(key=='Part_Number__c')
                {
                    fields.push({
                        'name' : this.labels.ECOM_PartNumber,
                        'value'  : value
                    });
                }
                // RWPS-2270 END
                else
                {
                    fields.push({
                        'name' :this.fieldlabelmap[key] ||  key.replaceAll('_',' ').replace('__C',''),
                        'value'  : value
                    });
                }
            }
        }
        return fields;
    } catch(error){//RWPS-5153 start
            processAndLogJSError(error, this.fileName, this.moduleName, 'fields');
    }//RWPS-5153 end
    }

    get isRadProduct(){
        return this.item.productDetails?.fields?.Dangerous_Goods_Indicator_Profile__c==='RAD' || false;
    }
    //RWPS-1387
    get itemImage(){
        return  resolve((this.item.productDetails?.fields?.ECOM_Product_Media_URI__c || this.images?.defaultProdImage)?? '', false, {
            height: 460,
            width: 460,
        }) ;
    }

    get dataLayerFields(){
        return this.productFields?.[this._item?.productId];
    }

    //RWPS-3811
    get isFreeItem() {
        return this.freeItemMap?.[this._item?.cartItemId];
    }
    get isFavorite(){
        return this.wishlist && this.wishlist[this.item.productId] ? true : false;
    }
    images = {
        cartimg: sres_ECOM_CartIcons + '/img/bag-line.svg',
        deleteimg: sres_ECOM_CartIcons + '/img/trash-purple.svg',
        quickorderimg:sres_ECOM_CartIcons + '/img/quick-order.svg',
        favoriteimg:sres_ECOM_CartIcons + '/img/heart-line.svg',
        helpimg:sres_ECOM_CartIcons + '/img/help-icon.svg',
        termsimg:sres_ECOM_CartIcons + '/img/pencil-line.svg',
        radIcon:sres_ECOM_CartIcons + '/img/radIcon.svg',
        filledfavorite:sres_ECOM_CartIcons + '/img/ecomFilledHeartIcon.svg',
        purplehelpimg:sres_ECOM_CartIcons + '/img/checkouttooltip.png',
        defaultProdImage : sres_ECOM_CartIcons + '/img/placeholder.png'//RWPS-1387
    }
    showHoverIcon(event) {
       this.imgSrc=this.images.purplehelpimg
    }

    showOriginalIcon(event) {
        this.imgSrc=this.images.helpimg
    }

    handleQuantityIncrement(event){
        this.showSpinner = true;
        this.quantity += 1;
        if(this.quantity > this.maxQuantity){
            this.quantity = 999;
            this.template.querySelector('c-ecom_show-Toast').showToast('Quantity cannot be greater than 999', 'error');
            this.showSpinner = false;
            return false;
        }
        else{
            this.updateCartItem();
        }

        //Preparing data for add_to_cart event which will be push to DataLayer
       try {
        this.itemQuantity=1;
        this.prepareDataLayerData('add_to_cart',this._item);
       } catch (error) {
            processAndLogJSError(error, this.fileName, this.moduleName, 'handleQuantityIncrement');//RWPS-5153
        }
    }

    handleQuantityDecrement(event){
        this.showSpinner = true;
        this.quantity -= 1;
        if(this.quantity < this.minQuantity){
            this.quantity = 1;
            this.template.querySelector('c-ecom_show-Toast').showToast('Quantity cannot be less than 1.', 'error');
            this.showSpinner = false;
            return false;
        }
       else{
            this.updateCartItem();
       }

       //Preparing data for remove_from_cart event which will be push to DataLayer
       try {
        this.itemQuantity=1;
        this.prepareDataLayerData('remove_from_cart',this._item);
       } catch (error) {
            processAndLogJSError(error, this.fileName, this.moduleName, 'handleQuantityDecrement');//RWPS-5153
        }
    }

    handleQuantityChange(event){
        try{ //RWPS-5852 Start
        const inputValue = event.target.value.trim();
        let previousQuantity = this.item.quantity;
        if(inputValue === '' || inputValue === '0'){
        this.quantity = this.minQuantity;
        return false;
        }
        if(parseInt(inputValue) < this.minQuantity || parseInt(inputValue) > this.maxQuantity){
            this.template.querySelector('c-ecom_show-Toast').showToast('Quantity must be between 1 and 999.', 'error');
            this.quantity = this.item.quantity;
            return false;
        }
        else{
            this.quantity = parseInt(inputValue) ? parseInt(inputValue) : 0;
            event.target.value = parseInt(inputValue);
            this.updateCartItem();
        }

        if(previousQuantity > Number(inputValue)){
            try {
                this.itemQuantity=previousQuantity - Number(inputValue);
                this.prepareDataLayerData('remove_from_cart',this._item);
            } catch (error) {
                processAndLogJSError(error, this.fileName, this.moduleName, 'handleQuantityChange-remove_from_cart');//RWPS-5153
            }
        }
        else{
            try {
                this.itemQuantity=Number(inputValue) - previousQuantity ;
                this.prepareDataLayerData('add_to_cart',this._item);
                } catch (error) {
               processAndLogJSError(error, this.fileName, this.moduleName, 'handleQuantityChange-add_to_cart');
            }
        }
    } catch(error) {
        processAndLogJSError(error, this.fileName, this.moduleName, 'handleQuantityChange');
    }
} //RWPS-5852 End
    //RWPS-5852 Start
    handleQuantityBlur(event){
    try{
        const inputValue = event.target.value.trim();
        if(inputValue === '' || inputValue === '0' || !parseInt(inputValue) || parseInt(inputValue) < this.minQuantity){
            this.quantity = this.minQuantity;
            event.target.value = this.minQuantity;
            this.updateCartItem();
        } 
        else if(parseInt(inputValue) > this.maxQuantity){
            this.quantity = this.maxQuantity;
            event.target.value = this.maxQuantity;
            this.updateCartItem();
        }
    } catch(error) {
        processAndLogJSError(error, this.fileName, this.moduleName, 'handleQuantityBlur');
    }
}
    //RWPS-5852 End

    updateCartItem(){
    try{//RWPS-5153
        this.fireCartChangeEvent();

        // RWPS-3683 - START
        this.updateListPriceOnCartItem(this.item.cartItemId, this.quantity);
        this.showSpinner = false;
        // RWPS-3683 - END
    } catch (error) {//RWPS-5153 start 
        processAndLogJSError(error, this.fileName, this.moduleName, 'updateCartItem');
    }//RWPS-5153 end        
    }

    updateListPriceOnCartItem(cartItemId, quantity){ // RWPS-3683
        updateCartItemListPrice({
            cartItemId: cartItemId,
            quantity : quantity // RWPS-3683
        }).then((result) => {
                this.fireCartChangesAppliedEvent();
                this.handlePublishMessage(); //ECOM-3441 - garora@rafter.one - publishing message for cart header count to update on quantity change - 5 July 2024
            })
            .catch((error) => {
                processAndLogJSError(error, this.fileName, this.moduleName, 'updateListPriceOnCartItem');//RWPS-5153
            });
    }

    //ECOM-3441 - garora@rafter.one - publishing message for cart header count to update on quantity change - 5 July 2024
    handlePublishMessage() {
        let payLoad = {message: this.totalQty,
            type: 'CartRefresh'
        };
        publish(this.messageContext, ECOM_MESSAGE, payLoad);
    }
    trainingPrductMessage;
    handleTrainingProductsRemove(event){
        this.trainingPrductMessage = event.detail;
        this.showModal = false;
        this.handleDeleteCartItem();
    }

    handleTrainingProductCancel(event){
        this.showModal = false;
    }

    //RWPS-4896-END
    handleDeleteCartItem(){
        try{//RWPS-5153
        // RWPS-4086 start
        if(this.showSpinner) {
            return;
        }
        // RWPS-4086 end
        //RWPS-4896-START
        if (typeof this.trainingProductMap !== 'undefined') {
            if(this.trainingProductMap[this.item.productId] && this.trainingPrductMessage != 'Removed' && this.isTrainingProduct){//RWPS-4896
               this.showModal = true;
               return;
            }
        }
        //RWPS-4896-END

        this.showSpinner = true;
        this.fireCartChangeEvent();
        this.dispatchEvent(
            new CustomEvent('removeclicked', {
                bubbles: true,
                composed: true,
                detail: {
                    updatePriceDisabled: true
                }
            })
        );
        this.removeAllQuantityOfItem=true;
        this.dispatchEvent(
            new CustomEvent('deleteitem', {
                bubbles: true,
                composed: true,
                detail: {
                    message: this.item?.productDetails?.name+' was removed.',
                    type:'success',
                    show: true,
                    cartItemId : this.item.cartItemId,
                    productId: this.item?.productId
                }
            })
        );

        //this.showSpinner = false;
            //const result= deleteItemFromCart(this.item.cartItemId);
            // result.then((response) => {
            // this.dispatchEvent(
            //     new CustomEvent('deleteitem', {
            //         bubbles: true,
            //         composed: true,
            //         detail: {
            //             message: this.item?.productDetails?.name+' was removed.',
            //             type:'success',
            //             show: true
            //         }
            //     })
            // );
            // }).catch((error) => {
            //     this.dispatchEvent(
            //         new CustomEvent('deleteitem', {
            //             detail: {
            //                 message: this.item?.productDetails?.name+' was not removed.',
            //                 type:'error',
            //                 show: true
            //             }
            //         })
            //     );
            // });

        //Preparing data for remove_from_cart event which will be push to DataLayer
       try {
        this.prepareDataLayerData('remove_from_cart',this._item);
       } catch (error) {//RWPS-5153 start 
             processAndLogJSError(error, this.fileName, this.moduleName, 'handleDeleteCartItem-remove_from_cart');
       }
    }catch(error){
        processAndLogJSError(error, this.fileName, this.moduleName, 'handleDeleteCartItem');
    }//RWPS-5153 end
}

    handleAddToFavourite(){
        this.dispatchEvent(
            new CustomEvent('createandaddtolist', {
                detail: {
                    productId: this.item.productId,
                    productName : this.item?.productDetails?.name
                }
            }, {
                bubbles: true,
                composed:true
              })
        );

        //Preparing data for add_to_wishlist event which will be push to DataLayer
        try {
            this.prepareDataLayerData('add_to_wishlist',this._item);
        } catch (error) {
            processAndLogJSError(error, this.fileName, this.moduleName, 'handleDeleteCartItem');
    }
}
    @track isModalOpen = false;

    openDeliveryModal() {
        this.template.querySelector('c-ecom_delivery-time-modal').openModal();


    }

    closeModal() {
        this.isModalOpen = false;
        sendPostMessage('auto');
    }

    @track isDateSelectorOpen = false;

handleBoxCSS(event){
    this.boxoneCSS='slds-col cart-shipping-box-active';
    this.boxtwoCSS='slds-col cart-shipping-box-2-inactive';

}
handleBoxtwoCSS(event){
    this.boxoneCSS='slds-col cart-shipping-box-inactive';
    this.boxtwoCSS='slds-col cart-shipping-box-2-active';
}

handleOpenDateSelector(event){
    this.isDateSelectorOpen = true;
    this.selectedItemId = event.currentTarget.dataset.id;
    this.boxoneCSS='slds-col cart-shipping-box-inactive';
    this.boxtwoCSS='slds-col cart-shipping-box-2-active';
    sendPostMessage('hidden');
}

    handleCloseDateSelector(){
        this.isDateSelectorOpen = false;
        sendPostMessage('auto');
    }

    handleApplyDateSelector(){
        try{//RWPS-5153
        this.fireCartChangesAppliedEvent();
        if(this.selectedDate){
            this.template.querySelector('c-ecom_date-picker').updateShippingDate();
            this.isDateSelectorOpen = false;
            sendPostMessage('auto');
            // this.fireCartChangeEvent();
            setTimeout(() => {
                this.dispatchEvent(
                    new CustomEvent('getshippingdates')
                );
            }, 3000);
        }
       else{
            this.template.querySelector('c-ecom_show-Toast').showToast('Please select a date.', 'error');
    }
}catch(error){//RWPS-5153 
    processAndLogJSError(error, this.fileName, this.moduleName, 'handleApplyDateSelector');
}//RWPS-5153 end

    }

    fireCartChangeEvent()
    {
        const handleCartChange = new CustomEvent('cartchange', {
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(handleCartChange);
    }

    // this function fire an event when update/apex call is completed
    fireCartChangesAppliedEvent()
    {
        const handleCartChangesApplied = new CustomEvent('cartchangesapplied', {
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(handleCartChangesApplied);
    }

    handleDateSelected(event){
        this.selectedDate = event?.detail?.dateString;
    }

    @track isRemoveModalOpen = false;

    handleOpenRemoveModal(){
        this.isRemoveModalOpen = true;
    }

    handleCloseRemoveModal(){
        this.isRemoveModalOpen = false;
    }

    handleRemoveFromFavourite(){
        this.dispatchEvent(
            new CustomEvent('removefromfavorite', {
                detail: {
                    wishlistItemId:this.wishlist[this.item.productId].wishListItemId,
                }
            }, {
                bubbles: true,
                composed:true
              })
        );

        //Preparing data for remove_from_wishlist event which will be push to DataLayer
        try {
            this.prepareDataLayerData('remove_from_wishlist',this._item);
        } catch (error) {
            processAndLogJSError(error, this.fileName, this.moduleName, 'handleRemoveFromFavourite');//RWPS-5153
        } 
    }   

    navigateToPDP() {
        let payLoad = {message: NAVIGATE_TO_PDP,
            type: CMS_NAVIGATION,
            partNumber: this.partNumberCode,
            url: this.productUrl
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
                    if(result.locale && result.locale != '' && baseUrl.indexOf(result.locale)==-1){
                        if (baseUrl.substr(-1) != '/'){
                            baseUrl += this.labels.LBL_URL_PATH_SEPARATOR;
                        }
                        baseUrl = baseUrl +  result.locale;
                    }
                    urlParams = result.responseData;
                    //console.log('baseUrl:: ', baseUrl + this.favorite.productDetail?.fields?.DisplayUrl + this.labels.LBL_CMS_PARAM_PREFIX + urlParams);//Remove after DEV
                    window.location.href = baseUrl  + this.productUrl + this.labels.LBL_CMS_PARAM_PREFIX + urlParams;//Remove after DEV
                } else {
                    publish(this.messageContext, ECOM_MESSAGE, payLoad);
                }
            }).catch(error => {
            //do not console log
            });
        }else {

            publish(this.messageContext, ECOM_MESSAGE, payLoad);
        }

        //Preparing data for select_item event which will be push to DataLayer
         try {
            this.prepareDataLayerData('select_item',this._item);
        } catch (error) {
            processAndLogJSError(error, this.fileName, this.moduleName, 'navigateToPDP'); //RWPS-5153
        }
}

    // RWPS-4086 start
    navigateToPDPEnter(event){
        if(event.key === 'Enter' || event.keyCode === 13){
            this.navigateToPDP();
        }
    }
    // RWPS-4086 end

    //Data layer regarding changes starts
    prepareDataLayerData(eventName,item){
        try{//RWPS-5153
        let hasImage = this.itemImage!=null && this.itemImage!=undefined? true: false;
        let data;
        if(eventName==='add_to_wishlist'){
            data =  {
                event: 'add_to_wishlist',
                items:[this.prepareItemdata(hasImage)]
            }
        }

        //for remove_from_wishlist event
        if(eventName==='remove_from_wishlist'){
            data =  {
                event: 'remove_from_wishlist',
                items:[this.prepareItemdata(hasImage)]
            }
        }

        //for select_item event
        if(eventName==='select_item'){
            data =  {
                event: 'select_item',
                'cart': {
                },
            'items': [this.prepareItemdata(hasImage)]
            }
        }

        //for add_to_cart event
        if(eventName==='add_to_cart'){
            data =  {
                'event': 'add_to_cart',
                'addToCartLocation': 'Cart Page - '+this.labels.ECOM_Add_to_Cart,//RWPS-3835
                'items': [this.prepareItemdata(hasImage)],
                _clear:true
            }
        }

        //for remove_from_cart event
        if(eventName==='remove_from_cart'){

            if(this.removeAllQuantityOfItem==true){
                this.itemQuantity=this.item.quantity;
                data =  {
                    'event': 'remove_from_cart',
                    'removeFromCartLocation': 'Cart Page',
                    'items': [this.prepareItemdata(hasImage)],
                    _clear:true
                }
            }
            else{
                    data =  {
                        'event': 'remove_from_cart',
                        'removeFromCartLocation': 'Cart Page',
                        'items': [this.prepareItemdata(hasImage)],
                        _clear:true
                    }
                }
            }

    this.firegtmEvent(data);
    }
    catch(error){//RWPS-5153 start
        processAndLogJSError(error, this.fileName, this.moduleName, 'prepareDataLayerData');
    }//RWPS-5153 end
  }

    prepareItemdata(hasImage){
        return {
            'name': this.item.name,
            'partNumber': [this.item.productDetails.fields.Part_Number__c],
            'paccode': '',
            'sapStatus': '',
            'businessUnit': '',
            'portfolioLevel2': '',
            'productLine': '',
            'productClass': '',
            'productBrand': '',
            'hasImage': hasImage,
            'quantity': this.itemQuantity,
            'price': this.item.unitAdjustedPrice,
            'listPrice':this.item.listPrice,
            'currency':this.item.currencyIsoCode,
        }
    }

    handlePublishMsg(data) {
        try{//RWPS-5153
        let payLoad = {
            data: data,
            type: 'DataLayer',
            page: 'cart'
        };
        publish(this.messageContext, ECOM_DATALAYERCHANNEL, payLoad);
    }catch(error){//RWPS-5153 start
        processAndLogJSError(error, this.fileName, this.moduleName, 'handlePublishMsg');
    }//RWPS-5153 end
}

    firegtmEvent(data){
        this.dispatchEvent(
            new CustomEvent('capturegtmevent', {
                detail: {
                    data: data,
                    productId : this.item?.productId
                }
            }
            )
        );
    }
    //Data layer regarding changes ends

    // RWPS-3826 - Start
    enterToClick(event) {
        if (event.key === 'Enter' || event.keyCode === 13) {
            event.target.click();
            event.preventDefault();
            event.stopPropagation();
        }
    }
    // RWPS-3826 - End
}