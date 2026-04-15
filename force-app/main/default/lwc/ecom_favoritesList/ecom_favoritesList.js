import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import ssrc_ECOM_Theme from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import ECOM_MESSAGE from '@salesforce/messageChannel/ecom_MessagingChannel__c';
import FORM_FACTOR from '@salesforce/client/formFactor';
import {publish, MessageContext} from 'lightning/messageService';
import ECOM_DATALAYERCHANNEL from '@salesforce/messageChannel/ecom_DataLayer__c';
import communityId from '@salesforce/community/Id';
import contextApi from 'commerce/contextApi';
import addItemsToCart from '@salesforce/apex/ECOM_OrderHistoryController.addItemsToCart';
import ECOM_105105 from '@salesforce/label/c.ECOM_105105';
import ECOM_AddedToCartSuccessfully from '@salesforce/label/c.ECOM_AddedToCartSuccessfully';
import ECOM_MaxQuantity from '@salesforce/label/c.ECOM_MaxQuantity';
const NAVIGATE_TO_PDP = 'PDP';
const CMS_NAVIGATION = 'CMSNavigation';

import { trackAddProductToCart } from 'commerce/activitiesApi'; //RWPS-3125

//VRa-punchout changes - 1 Feb 24- begin
//apex
import encodeUrlParams from '@salesforce/apex/ECOM_UserController.getEncyrptedSessionParametersForCMS';

//label
import LBL_URL_PATH_SEPARATOR from '@salesforce/label/c.ECOM_UrlPathSeparator';
import LBL_CMS_PARAM_PREFIX  from '@salesforce/label/c.ECOM_CMSPunchoutLoginParameter';
import LBL_CMS_BUY_PAGE  from '@salesforce/label/c.ECOM_CMSBuyPage';

// RWPS-2270 START
import ECOM_AddToCart  from '@salesforce/label/c.ECOM_AddToCart';
import ECOM_Remove_Favorites  from '@salesforce/label/c.ECOM_Remove_Favorites';
import ECOM_PartNumber  from '@salesforce/label/c.ECOM_PartNumber';
// RWPS-2270 END
import ECOM_Product_Name  from '@salesforce/label/c.ECOM_Product_Name';// RWPS-2722

//import js
import {getUserConfigData, setToSessionStorage,SYSTEM_CONSTANTS,parseJSON} from 'c/ecom_punchoutUtil';
import ECOM_Add_to_Cart from '@salesforce/label/c.ECOM_Add_To_Cart_CTA';//RWPS-3835
//VRa-punchout changes - 1 Feb 24- end

import discontinuedText from "@salesforce/label/c.ECOM_Product_Tile_Discontinued_Text"; // RWPS-3740
import discontinuedTooltipText from "@salesforce/label/c.ECOM_Discontinued_Product_Tooltip_Text"; // RWPS-3740
import {processAndLogJSError} from 'c/ecom_util'; // RWPS-5153

export default class Ecom_favoritesList extends NavigationMixin(LightningElement) {
    @wire(MessageContext)
    messageContext;
    @api favorite;
    @api fieldlabelmap;
    @api
    productData;

    @api replacementPriceMap; // RWPS-3740

    _quantity = 1;
    minQuantity=1;
    maxQuantity=999;
    effectiveAccountId;
    orderItemsList = [];
    showSpinner=false;
    message;
    type;
    show;
    currencyDisplayAs='code';
    timeSpan = 0;
    fileName ='ecom_favoriteList';//RWPS-5153
    moduleName ='User Management';//RWPS-5153
    @track _displayName;// RWPS-2270
    @api
    device = {
        isMobile : FORM_FACTOR==='Small',
        isDesktop : FORM_FACTOR==='Large',
        isTablet :FORM_FACTOR==='Medium'
    }
    images = {
        deleteimg: ssrc_ECOM_Theme + '/img/delete-icon.png',
    }
    set quantity(val) {
        this._quantity = val;
    }
    get quantity() {
        return this._quantity;
    }

    get showAddToCart(){ // RWPS-3740
        return this.favorite.isSellable && !this.favorite.isExcluded;
    }

    labels = {
        ECOM_AddedToCartSuccessfully,
        ECOM_105105,
        ECOM_MaxQuantity,
        LBL_URL_PATH_SEPARATOR,
        LBL_CMS_PARAM_PREFIX,
        LBL_CMS_BUY_PAGE,
        ECOM_AddToCart, // RWPS-2270 START
        ECOM_Remove_Favorites,
        ECOM_PartNumber, // RWPS-2270 END
        ECOM_Product_Name, // RWPS-2722
        ECOM_Add_to_Cart, // RWPS-3835
        discontinuedText // RWPS-4639
    }
    //VRa-punchout changes - 1 Feb 24- end

    // RWPS-3740 START
    replacementData = [];
    showReplacements = false;
    directReplacement = false;
    alternativeReplacements = false;
    discontinuedProduct = false;
    // RWPS-3740 END

    connectedCallback(){
    try{//RWPS-5153
        const result = contextApi.getSessionContext();
        result.then((response) => {
            this.effectiveAccountId = response.effectiveAccountId;
        }).catch((error) => {
            processAndLogJSError(error, this.fileName, this.moduleName, 'getSessionContext');//RWPS-5153
        });
        this.displayName='';// RWPS-2270

        // RWPS-3740 START
        if(this.productData?.replacementMap && this.productData.replacementMap[this.favorite.Product2.Id]) {
            let replacementInfo = this.productData.replacementMap[this.favorite.Product2.Id];
            if(replacementInfo.DirectReplacement) {
                this.replacementData = [{...replacementInfo.DirectReplacement}];
                this.directReplacement = true;
            } else {
                this.replacementData = JSON.parse(JSON.stringify(replacementInfo.AlternativeReplacements));
                this.alternativeReplacements = true;
            }

            this.showReplacements = true;
        }

        if(
            this.productData?.sapStatus?.productSalesStatus &&
            this.productData.sapStatus.productSalesStatus[this.favorite.Product2.Id] &&
            this.productData.discontinuedStatuses.includes(this.productData.sapStatus.productSalesStatus[this.favorite.Product2.Id])
        ) {
            this.discontinuedProduct = true;
        }
        // RWPS-3740 END
    }catch(error)//RWPS-5153 start
    {   
        processAndLogJSError(error, this.fileName, this.moduleName, 'connectedCallback');}
    }//RWPS-5153 end

    handleQuantityIncrement(event){
        try{//RWPS-5153 
        this.quantity += 1;
        if(this.quantity > this.maxQuantity){
            this.quantity = this.maxQuantity;
            this.showMessage(
                'Quantity cannot be greater than 999.',
                'error',
                true
            );
            return false;
        }
    }catch(error)//RWPS-5153 start
    {   
        processAndLogJSError(error, this.fileName, this.moduleName, 'handleQuantityIncrement');
    }//RWPS-5153 end
    }

    handleQuantityDecrement(event){
    try{//RWPS-5153 
        this.quantity -= 1;
        if(this.quantity < this.minQuantity){
            this.quantity = this.minQuantity;
            this.showMessage(
                'Quantity cannot be less than 1.',
                'error',
                true
            );
            return false;
        }
    }catch(error)   //RWPS-5153 start
    {   
        processAndLogJSError(error, this.fileName, this.moduleName, 'handleQuantityDecrement');
    }//RWPS-5153 end
}


    handleQuantityChange(event){
        try{//RWPS-5153 
        //RWPS-5852 Start    
        if(event.target.value === '' || event.target.value === '0'){
            this.quantity = this.minQuantity;
            return false;
        } //RWPS-5852 End
        if(event.target.value != '' && !parseInt(event.target.value)){
            this.quantity = this.minQuantity;
            event.target.value = this.minQuantity;
            return false;
        }else if(parseInt(event.target.value) < this.minQuantity || parseInt(event.target.value) > this.maxQuantity){
            this.showMessage(
                'Quantity must be between 1 and 999.',
                'error',
                true
            );
            this.quantity = this.minQuantity;
            event.target.value = this.minQuantity;
            return false;
        }else{
            this.quantity = parseInt(event.target.value) ? parseInt(event.target.value) : 0;
            event.target.value = parseInt(event.target.value);
            this.show = false;//RWPS-5852
        }
        }catch(error){//RWPS-5153 start
                processAndLogJSError(error, this.fileName, this.moduleName, 'handleQuantityChange');   
        }//RWPS-5153 end
        }

    get fields(){

        let displayFields = [];
        let productDetail = this.favorite.productDetail;
        for (const [key, value] of Object.entries(productDetail?.fields)) {
            // RWPS-2270 START
            if(key=='Part_Number__c')
            {
                displayFields.push({
                    'name' : this.labels.ECOM_PartNumber,
                    'value'  : value
                });
            }// RWPS-2270 END
            /*else if(key=='Name'){// RWPS-2722 START , RWPS-2516
                displayFields.push({
                'name' : this.labels.ECOM_Product_Name,
                'value'  : value
                });
            }*/ // RWPS-2722, RWPS-2516 END
        }
        return displayFields;
     }
    //RWPS-5852 Start
    handleQuantityBlur(event){
        try{
            const inputValue = event.target.value.trim();
            if(inputValue === '' || inputValue === '0' || !parseInt(inputValue) || parseInt(inputValue) < this.minQuantity){
                this.quantity = this.minQuantity;
                event.target.value = this.minQuantity;
            } else if(parseInt(inputValue) > this.maxQuantity){
                this.quantity = this.maxQuantity;
                event.target.value = this.maxQuantity;
            }
        } catch(error) {
            processAndLogJSError(error, this.fileName, this.moduleName, 'handleQuantityBlur');
        }
    }
    //RWPS-5852 End

    handleRemoveFromFav(event){
    try{//RWPS-5153 
        let wishlistItemId = event.currentTarget.dataset.id;
        let productName = event.currentTarget.dataset.name;
        this.dispatchEvent(
            new CustomEvent('removefromfav', {
                detail: {
                    wishlistItemId: wishlistItemId,
                    quantity : this.quantity,
                    productId :this.favorite.Product2.Id
                }
            })
        );
        this.showMessage(
            productName + ' removed from favourites',
            'success',
            true
        );
        try {
            this.prepareremoveFromWishListDataLayerData();
        }catch (error) {
            processAndLogJSError(error, this.fileName, this.moduleName, 'prepareremoveFromWishListDataLayerData');//RWPS-5153 
        }
    }catch(error)//RWPS-5153 start
    {       
        processAndLogJSError(error, this.fileName, this.moduleName, 'handleRemoveFromFav');}//RWPS-5153 end
    }

    showMessage(message,type,show){
        this.message = message;
        this.type = type;
        this.show = show;
    }

    handleUpdateMessage(event){
        this.message = '';
        this.type = '';
        this.show = event.detail.show;
    }

    setOrderItemsList(prodId){
        this.orderItemsList.push({Product2Id: prodId, Quantity: this.quantity});
    }

    // Add item to the cart
    handleAddToCart(event){
    try{//RWPS-5153 
        // RWPS-4086 start
        if(this.showSpinner) {
            return;
        }
        // RWPS-4086 end
        //RWPS-5852 Start
        const input = this.template.querySelector('input[name="qty-input"]');
        const inputValue = input ? input.value.trim() : '';
        if(inputValue === '' || inputValue === '0' || !this.quantity || this.quantity < this.minQuantity || this.quantity > this.maxQuantity){
            this.showMessage(
                'Please enter a valid quantity between 1 and 999.',
                'error',
                true
            );
            this.quantity = this.minQuantity;
            if(input) input.value = this.minQuantity;
            return;
        }
        //RWPS-5852 End
        this.orderItemsList = []; //RWPS-1777
        this.showSpinner = true;
        let prodId = event.currentTarget.dataset.id;
        this.setOrderItemsList(prodId);
        if(this.orderItemsList.length > 0 && this.quantity >= this.minQuantity && this.quantity <= this.maxQuantity){
            // Call the 'addItemsToCart' apex method imperatively
            addItemsToCart({
                communityId: communityId,
                effectiveAccountId: this.effectiveAccountId,
                cartItems: this.orderItemsList
            }).then((result) => {
                if(result.itemsAddedSuccessfully[0] == prodId){
                    this.showMessage(
                        this.labels.ECOM_AddedToCartSuccessfully,
                        'success',
                        true
                    );
                    // RWPS-3125 start
                    trackAddProductToCart({
                        id: prodId,
                        sku: this.favorite?.productDetail?.fields?.Part_Number__c,
                        quantity: this.quantity,
                        price: '',
                    });
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

                //Preparing data for add_to_cart event which will be push to DataLayer
                try {
                    this.prepareAddToCartDataLayerData();
                }catch (error) {
                }

            }).catch((error) => {
                this.showSpinner = false;
                processAndLogJSError(error, this.fileName, this.moduleName, 'addItemsToCart');//RWPS-5153 
                console.log(error);
                this.showMessage(
                    this.labels.ECOM_105105,
                    'error',
                    true
                );
                try {
                    this.prepareAddToCartErrorDataLayerData(error);
                } catch (error) {
                    processAndLogJSError(error, this.fileName, this.moduleName, 'prepareAddToCartErrorDataLayerData');    //RWPS-5153 
             }
            });
        }
        else{
            this.showMessage(
                this.labels.ECOM_MaxQuantity,
                'error',
                true
            );
            this.quantity = this.minQuantity;
            return false;
        }
    }catch(error)   { //RWPS-5153 start 
        processAndLogJSError(error, this.fileName, this.moduleName, 'handleAddToCart');     
    }//RWPS-5153 end
}
    

    //Data layer regarding changes starts
    prepareAddToCartDataLayerData(){
        let data =  {
            event: 'add_to_cart',
            'addToCartLocation': ' Favorite - ' + this.labels.ECOM_Add_to_Cart,//RWPS-3835
            'items': [this.prepareItemdata()],
                _clear:true
        }
        this.handlePublishMsg(data);
    }

    prepareremoveFromWishListDataLayerData(){
        let data =  {
            event: 'remove_from_wishlist',
            'location': 'favorites page',
            'items': [this.prepareItemdata()],
                _clear:true
        }
        this.handlePublishMsg(data);
    }

    prepareAddToCartErrorDataLayerData(error){
    try{//RWPS-5153 start
        let data =  {
            event: 'add_to_cart_error',
            'location': 'favorites page',
            'items': [this.prepareItemdata()],
            'errormessage':error?.body?.message || error,
                _clear:true
        }
        this.handlePublishMsg(data);
    }catch(error)//RWPS-5153 start
    {
        processAndLogJSError(error, this.fileName, this.moduleName, 'prepareAddToCartErrorDataLayerData');
    }//RWPS-5153 end
    }

    prepareItemdata(){
        return {
            'name': this.productData.dataLayer[this.favorite.Product2.Id].name,
            'partNumber': [this.productData.dataLayer[this.favorite.Product2.Id]?.partNumber]||undefined,
            'paccode': this.productData.dataLayer[this.favorite.Product2.Id]?.paccode +'-'+ this.productData.dataLayer[this.favorite.Product2.Id]?.igorDescription ||undefined,
            'businessUnit': this.productData.dataLayer[this.favorite.Product2.Id]?.superBussinessUnit +'-'+this.productData.dataLayer[this.favorite.Product2.Id]?.subBussinessUnit||undefined ,
            'portfolioLevel2':this.productData.dataLayer[this.favorite.Product2.Id]?.portfolioLevel2||undefined ,
            'productLine':  this.productData.dataLayer[this.favorite.Product2.Id]?.productLine +'-'+ this.productData.dataLayer[this.favorite.Product2.Id]?.productLineName || undefined ,
            'productClass':this.productData.dataLayer[this.favorite.Product2.Id]?.productClass ||undefined ,
            'productBrand': this.productData.dataLayer[this.favorite.Product2.Id]?.productBrand ||undefined ,
            'sapstatus':  this.productData.sapStatus.productSalesStatus[this.favorite.Product2.Id] ||undefined,
            'hasImage': this.favorite?.productDetail?.defaultImage?.url? true :false ,
            'quantity': this.quantity||undefined,
            'price': this.favorite?.productPricing?.unitPrice||undefined,
            'listPrice':this.favorite?.productPricing?.listPrice||undefined,
            'currency':this.favorite?.CurrencyIsoCode||undefined,
        }
    }

    //Publishing data through LMS
    handlePublishMsg(data) {
    try{//RWPS-5153 
        let payLoad = {
                    data: data,
                    type: 'DataLayer',
                    page:'favourites'
        };
        publish(this.messageContext, ECOM_DATALAYERCHANNEL, payLoad);
    }catch(error)//RWPS-5153 start
    {
        processAndLogJSError(error, this.fileName, this.moduleName, 'handlePublishMsg');
    }//RWPS-5153 end
    }
    //Data layer regarding changes starts
    navigateToPDP(event) {
    try{//RWPS-5153 
        let payLoad = {message: NAVIGATE_TO_PDP,
            type: CMS_NAVIGATION,
            partNumber: '',
            url:  this.favorite.productDetail?.fields?.DisplayUrl||''
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
                    window.location.href = baseUrl + this.favorite.productDetail?.fields?.DisplayUrl + this.labels.LBL_CMS_PARAM_PREFIX + urlParams;//Remove after DEV
                } else {
                    publish(this.messageContext, ECOM_MESSAGE, payLoad);
                }
            }).catch(error => {
            //do not console log
            });
        }else {
            publish(this.messageContext, ECOM_MESSAGE, payLoad);
        } 
    }catch(error){  //RWPS-5153 start
        processAndLogJSError(error, this.fileName, this.moduleName, 'navigateToPDP');
    }//RWPS-5153 end
        //VRa: punchout changes - 1 Feb 24 - begin
    }

    // RWPS-2270 START
    get displayName(){
        return this._displayName;
    }

    set displayName(value){
        if(typeof value !==undefined && value !== null && value=='')
            {
                let temp = this.favorite?.Product2?.Product_Display_Name__c;
                this._displayName = temp !== undefined && temp !== null?temp:this.favorite.Product2.Name;//RWPS-2607
                this._displayName = this._displayName.replaceAll('&lt;','<').replaceAll('&gt;','>');
            }
    }

    // RWPS-2270 END

    // RWPS-3740 START
    get showDiscontinuedSection() {
        return (this.directReplacement || this.alternativeReplacements || this.discontinuedProduct) && !this.showAddToCart;
    }

    get discontinuedTooltip() {
        if(!this.directReplacement && !this.alternativeReplacements && this.discontinuedProduct) {
            return discontinuedTooltipText;
        }
        return '';
    }

    get defaultCursorFlagOnDiscontinued() {
        return this.discontinuedTooltip ? true : false;
    }

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
    // RWPS-3740 END
}