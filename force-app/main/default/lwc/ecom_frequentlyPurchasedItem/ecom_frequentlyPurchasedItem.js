import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import communityId from '@salesforce/community/Id';

import sres_ECOM_CartIcons from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import ECOM_MESSAGE from '@salesforce/messageChannel/ecom_MessagingChannel__c';
import FORM_FACTOR from '@salesforce/client/formFactor';
import {publish, MessageContext} from 'lightning/messageService';
import ECOM_DATALAYERCHANNEL from '@salesforce/messageChannel/ecom_DataLayer__c';

//VRa-punchout changes - 1 Feb 24- begin
//apex
import encodeUrlParams from '@salesforce/apex/ECOM_UserController.getEncyrptedSessionParametersForCMS';

//label
import LBL_URL_PATH_SEPARATOR from '@salesforce/label/c.ECOM_UrlPathSeparator';
import LBL_CMS_PARAM_PREFIX  from '@salesforce/label/c.ECOM_CMSPunchoutLoginParameter';
import LBL_CMS_BUY_PAGE  from '@salesforce/label/c.ECOM_CMSBuyPage';

//VRa-punchout changes - 1 Feb 24- end

import { SYSTEM_CONSTANTS, parseJSON, SYSTEM_LABELS, APEX_ACTIONS, getUserConfigData, setToSessionStorage} from 'c/ecom_punchoutUtil';

export default class Ecom_frequentlyPurchasedItem extends LightningElement {

    @wire(MessageContext)
    messageContext;
    
    @api frequentlypurchasedproduct = {};
    @api fieldlabelmap;
    @api productData;
    @api wishlistitems;
    @api effectiveAccountId;

    _quantity = 1;
    minQuantity=1;
    maxQuantity=999;
    message;
    type;
    show;
    currencyDisplayAs='code';
    timeSpan = 0;

    //array
    wishListItem = {};

    //labels
    labels = {
        LBL_URL_PATH_SEPARATOR,
        LBL_CMS_PARAM_PREFIX,
        LBL_CMS_BUY_PAGE
    }

    @api  
    device = {
        isMobile : FORM_FACTOR==='Small',
        isDesktop : FORM_FACTOR==='Large',
        isTablet :FORM_FACTOR==='Medium'
    }
    images = {
        defaultProductImage: sres_ECOM_CartIcons + '/img/placeholder.png',//RWPS-1387
        favoriteimg:sres_ECOM_CartIcons + '/img/hearticon.svg',
        deleteimg: sres_ECOM_CartIcons + '/img/deleteicon.svg',
    }
    set quantity(val) {
        this._quantity = val;
    }
    get quantity() {
        return this._quantity;
    }

    handleQuantityIncrement(event){
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
    }

    handleQuantityDecrement(event){
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
    }

    handleQuantityChange(event){
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
        }
    }

    connectedCallback(){
        if(this.frequentlypurchasedproduct && this.frequentlypurchasedproduct?.productId && this.wishlistitems && this.wishlistitems.length > 0){
            const productId = this.frequentlypurchasedproduct?.productId;
            for(const [key,value] of Object.entries(this.wishlistitems)){
                if(value.Product2Id == productId){
                    this.wishListItem = value;
                    break;
                }
            }
        }
    }

    get fields(){
        let displayFields = [];
        if(this.frequentlypurchasedproduct && this.frequentlypurchasedproduct.productDetail){
            let productDetail = this.frequentlypurchasedproduct.productDetail;
        for (const [key, value] of Object.entries(productDetail?.fields)) {
            if(this.fieldlabelmap[key]){
                displayFields.push({
                    'name' :this.fieldlabelmap[key] ||  key.replaceAll('_',' ').replace('__C',''),
                'value'  : value
                });
            }
        }
        }
        
        return displayFields;
    }
    
    //VRa - Punchout changes - begin

    system_labels = SYSTEM_LABELS;

    get displayUrl(){
        //this.frequentlypurchasedproduct = parseJSON(this.frequentlypurchasedproduct);
        // //console.log('displayUrl.this.frequentlypurchasedproduct', this.frequentlypurchasedproduct);//Remove after DEV
        return this.frequentlypurchasedproduct && this.frequentlypurchasedproduct?.productDisplayUrl ? this.frequentlypurchasedproduct.productDisplayUrl : this.images.defaultProductImage;
    }

    get updatedFields(){
        let currentFieldValueMap = [];
        if(this.frequentlypurchasedproduct && this.frequentlypurchasedproduct?.productPartNumber){
            currentFieldValueMap.push({'name': this.system_labels.PART_NUMBER, 'value': this.frequentlypurchasedproduct?.productPartNumber});
        }
        if(this.frequentlypurchasedproduct && this.frequentlypurchasedproduct?.productName){
            currentFieldValueMap.push({'name': this.system_labels.PRODUCT_NAME, 'value': this.frequentlypurchasedproduct?.productName});
        }
        // //console.log('currentFieldValueMap:: ', currentFieldValueMap);//Remove after DEV
        return currentFieldValueMap;
    }

    get productPartNumber(){
        return this.frequentlypurchasedproduct && this.frequentlypurchasedproduct?.productPartNumber ?  this.frequentlypurchasedproduct?.productPartNumber : '';
    }

    get isProductWishListed(){
        let isWishListed = false;
        if(this.frequentlypurchasedproduct && this.frequentlypurchasedproduct?.productId && this.wishlistitems && this.wishlistitems.length > 0){
            const productId = this.frequentlypurchasedproduct?.productId;
            for(const [key,value] of Object.entries(this.wishlistitems)){
                if(value.Product2Id == productId){
                    this.wishListItem = value;
                    isWishListed = true;
                    break;
                }
            }
        }
        // //console.log('isWishListed:: ', isWishListed, this.wishListItem);//Remove after DEV
        return isWishListed;
    }

    get currentWishlistItem(){
        // //console.log('currentWishlistItem:: ', this.wishListItem);//Remove after DEV
        return this.wishListItem;
    }
    //VRa - Punchout changes - end


    handleRemoveFromFav(event){
        let wishlistItemId = event.currentTarget.dataset.id;
        let productName = event.currentTarget.dataset.name;
        this.dispatchEvent(
            new CustomEvent('removefromfav', {
                detail: {
                    wishlistItemId: wishlistItemId,
                    quantity : this.quantity,
                    productId :this.frequentlypurchasedproduct.productId
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
        }  
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

    handleAddToCart(event){
        try{
            const productId = event.currentTarget.dataset.id;
            const productName = event.currentTarget.dataset.name;
            const qty = this.quantity;
            //console.log('productId:: ', productId, ' productName::', productName, 'qty::',qty);//Remove after DEV
        if(this.quantity >= this.minQuantity && this.quantity <= this.maxQuantity){
            this.dispatchEvent(
                new CustomEvent('addtocart', {
                    detail: {
                        productId: event.currentTarget.dataset.id,
                        productName: event.currentTarget.dataset.name,
                        qty: this.quantity
                    }
                })
            );
        }
        else{
            this.showMessage(
                'Quantity must be between 1 and 999.',
                'error',
                true
            );
            this.quantity = this.minQuantity;
            return false;
        }  
        //Preparing data for add_to_cart event which will be push to DataLayer
            try {
                this.prepareAddToCartDataLayerData();
            }catch (error) {
            }
        }catch(error){
            try {
                this.prepareAddToCartErrorDataLayerData(error);
            } catch (error) {
         }
        }
    }

    //VRa-Punchout Changes - begin
    handleAddRemoveFromWishlist(event){
        const productId = event.currentTarget.dataset.id;
        const wishListId = event.currentTarget.dataset.wishlist;
        const wishlistItemId = event.currentTarget.dataset.wishlistitem//event.currentTarget.dataset.wishId;
        const actionName = event.currentTarget.dataset.actionname;
        // //console.log('this.wishlist', this.wishListItem);//Remove after DEV
        // //console.log('productId::', productId, 'wishlistItemId::', wishlistItemId, 'actionname::',actionName );//Remove after DEV
        if(actionName === 'add'){
            this.addWishListAction(productId, wishListId);
        } else {
            this.removeWishlistAction(wishlistItemId);
        }
    }

    addWishListAction(productId, wishListId){
        APEX_ACTIONS.addWishListItemAndGetUpdatedWishlist({
            communityId : communityId,
            wishListId: wishListId,
            productId: productId,
            effectiveAccountId:this.effectiveAccountId,
        }).then(result => {
            // //console.log('result::', result);//Remove after DEV
            if(result && result.success && result.responseData && result.responseData.wishlistsItems){
                this.wishlistitems = result.responseData.wishlistsItems;
            }
        }).catch(err => {
            //console.log('err', err);//Remove after DEV
        })
    }

    removeWishlistAction(currentItemId){
        // //console.log('removeWishlistAction:currentItemId',currentItemId);//Remove after DEV
        APEX_ACTIONS.removeItemAndGetUpdatedWishlist({
            wishListItemId: currentItemId
        }).then(result => {
            // //console.log('result::', result);//Remove after DEV
            if(result && result.success && result.responseData && result.responseData.wishlistsItems){
                this.wishlistitems = result.responseData.wishlistsItems;
            }
        }).catch(err => {
            //console.log('err', err);//Remove after DEV
        })
    }
    //VRa-Punchout Changes - end

    //Data layer regarding changes starts
    prepareAddToCartDataLayerData(){
        let data =  {
            event: 'add_to_cart',
            'addToCartLocation': 'frequentlypurchasedproducts page',
            'items': [this.prepareItemdata()],
                _clear:true
        }
        this.handlePublishMsg(data);
    }

    prepareremoveFromWishListDataLayerData(){
        let data =  {
            event: 'remove_from_wishlist',
            'location': 'frequentlypurchasedproducts page',
            'items': [this.prepareItemdata()],
                _clear:true
        }
        this.handlePublishMsg(data);
    }

    prepareAddToCartErrorDataLayerData(error){
        let data =  {
            event: 'add_to_cart_error',
            'location': 'frequentlypurchasedproducts page',
            'items': [this.prepareItemdata()],
            'errormessage':error?.body?.message || error,
                _clear:true
        }
        this.handlePublishMsg(data);
    }

    prepareItemdata(){
        //VRa - Punchout changes -begin
        // return {
        //     'name': this.productData.dataLayer[this.frequentlypurchasedproduct.Id].name,
        //     'partNumber': this.productData.dataLayer[this.frequentlypurchasedproduct.Product2.Id]?.partNumber,
        //     'paccode': this.productData.dataLayer[this.frequentlypurchasedproduct.Product2.Id]?.paccode||'',
        //     'businessUnit': this.productData.dataLayer[this.frequentlypurchasedproduct.Product2.Id]?.bussinessUnit||'' ,
        //     'portfolioLevel2':this.productData.dataLayer[this.frequentlypurchasedproduct.Product2.Id]?.portfolioLevel2||'' ,
        //     'productLine':  this.productData.dataLayer[this.frequentlypurchasedproduct.Product2.Id]?.productLine || '' ,
        //     'productClass':this.productData.dataLayer[this.frequentlypurchasedproduct.Product2.Id]?.productClass ||'' ,
        //     'productBrand': this.productData.dataLayer[this.frequentlypurchasedproduct.Product2.Id]?.productBrand ||'' ,
        //     'sapstatus':  this.productData.sapStatus.productSalesStatus[this.frequentlypurchasedproduct.Product2.Id] ||'',
        //     'hasImage': this.frequentlypurchasedproduct?.productDetail?.defaultImage?.url? true :false ,
        //     'quantity': this.quantity,
        //     'price': this.frequentlypurchasedproduct?.productPricing?.unitPrice,
        //     'listPrice':this.frequentlypurchasedproduct?.productPricing?.listPrice,
        //     'currency':this.frequentlypurchasedproduct?.CurrencyIsoCode,
        // }
        return {
                'name': this.frequentlypurchasedproduct.productName,
                'partNumber': this.frequentlypurchasedproduct?.partNumber,
                'paccode': this.frequentlypurchasedproduct?.paccode||'',
                'businessUnit': this.frequentlypurchasedproduct?.bussinessUnit||'' ,
                'portfolioLevel2':this.frequentlypurchasedproduct?.portfolioLevel2||'' ,
                'productLine':  this.frequentlypurchasedproduct?.productLine || '' ,
                'productClass':this.frequentlypurchasedproduct?.productClass ||'' ,
                'productBrand': this.frequentlypurchasedproduct?.productBrand ||'' ,
                'sapstatus':  '',
                'hasImage': this.frequentlypurchasedproduct?.url? true :false ,
                'quantity': this.quantity,
                //'price': this.frequentlypurchasedproduct?.productPricing?.unitPrice,
                //'listPrice':this.frequentlypurchasedproduct?.productPricing?.listPrice,
                'currency':this.frequentlypurchasedproduct?.CurrencyIsoCode,
            }
            //VRa - Punchout changes - end
    }

    //Publishing data through LMS
    handlePublishMsg(data) {
        let payLoad = {
                    data: data,
                    type: 'DataLayer',
                    page:'favourites'
        };
        publish(this.messageContext, ECOM_DATALAYERCHANNEL, payLoad);
    }
    //Data layer regarding changes starts
    navigateToPDP(event) {
        let payLoad = {message: SYSTEM_CONSTANTS.NAVIGATE_TO_PDP,
            type: SYSTEM_CONSTANTS.CMS_NAVIGATION,
            partNumber: this.frequentlypurchasedproduct.productPartNumber,
            url:  this.frequentlypurchasedproduct?.productNavigationUrl||''
        };

        //VRa: punchout changes - 1 Feb 24 - begin
        let userConfig = getUserConfigData();
        //console.log('this.frequentlypurchasedproduct.productDetail?.fields?.DisplayUrl:: ', parseJSON(this.frequentlypurchasedproduct));//Remove after DEV
        if(userConfig && userConfig.isPunchoutUser){
            let urlParams = '';
            encodeUrlParams().then(result => {
                //console.log('result:: '+ parseJSON(result), result);//Remove after DEV
                if(result && result?.success && result?.responseData){
                    let baseUrl = result.Home ;
                    //console.log('baseUrl:: ', baseUrl);//Remove after DEV
                    if(result.locale && result.locale != ''){
                         //RWPS-1817
                         if (baseUrl.substr(-1) != '/'){
                            baseUrl += this.labels.LBL_URL_PATH_SEPARATOR;
                        }
                        baseUrl = baseUrl +  result.locale;
                    }
                    //console.log('baseUrl:: ', baseUrl);//Remove after DEV
                    urlParams = result.responseData;
                    window.location.href = baseUrl +  this.frequentlypurchasedproduct?.productNavigationUrl + this.labels.LBL_CMS_PARAM_PREFIX + urlParams;//Remove after DEV
                } else {
                    publish(this.messageContext, ECOM_MESSAGE, payLoad);
                }
            }).catch(error => {
            //do not console log
            });
        }else {
            publish(this.messageContext, ECOM_MESSAGE, payLoad);
        }
         //VRa: punchout changes - 1 Feb 24 - begin
    }
}