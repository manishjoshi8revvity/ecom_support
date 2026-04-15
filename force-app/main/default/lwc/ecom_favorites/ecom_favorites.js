import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { isCmsResource, resolve } from 'experience/resourceResolver';
import {publish, MessageContext} from 'lightning/messageService';
import communityId from '@salesforce/community/Id';
import contextApi from 'commerce/contextApi';
// import {WishlistSummaryAdapter} from 'commerce/wishlistApi';
import getWishlistSummaries from '@salesforce/apex/ECOM_FavoritesController.getWishlistSummaries';
import removeWishlistItem from '@salesforce/apex/ECOM_FavoritesController.removeWishlistItem';
import addItemsToCart from '@salesforce/apex/ECOM_FavoritesController.addItemsToCart';
import ECOM_MESSAGE from '@salesforce/messageChannel/ecom_MessagingChannel__c';
import sres_ECOM_CartIcons from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import ECOM_107001 from '@salesforce/label/c.ECOM_107001';
import FORM_FACTOR from '@salesforce/client/formFactor';

//custom labels
import ECOM_ViewAll  from '@salesforce/label/c.ECOM_ViewAll';
import ECOM_ProductsInFavorites  from '@salesforce/label/c.ECOM_ProductsInFavorites';
import ECOM_NoFavoritesItemMessage  from '@salesforce/label/c.ECOM_NoFavoritesItemMessage';
import ECOM_ShopNow  from '@salesforce/label/c.ECOM_ShopNow';
import ECOM_Favorites  from '@salesforce/label/c.ECOM_Favorites';
//RWPS-2390 START
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import ECOM_Is_Punchout_User__c from '@salesforce/schema/User.ECOM_Is_Punchout_User__c';
import ECOM_Non_Sellable_Error_Message_Fav from '@salesforce/label/c.ECOM_Non_Sellable_Error_Message_Fav';//RWPS-2786 //RWPS-5550
//RWPS-2390 END

import {getReplacementProductContractPrice, processAndLogJSError} from 'c/ecom_util'; // RWPS-3740//RWPS-5153

const NAVIGATE_TO_PLP = 'PLP';
const CMS_NAVIGATION = 'CMSNavigation';
export default class Ecom_favorites extends NavigationMixin(LightningElement) {

    labels = {
        ECOM_ViewAll,
        ECOM_ProductsInFavorites,
        ECOM_NoFavoritesItemMessage,
        ECOM_ShopNow,
        ECOM_Favorites,
        ECOM_Non_Sellable_Error_Message_Fav //RWPS-2786 //RWPS-5550

    };
    @api recordId;
    @api effectiveAccountId;
    @api fieldsToShow;
    @api recordsToDisplay;

    @api enableRecommendations = false; // RWPS-2858
    @api recommendationsToShow = ''; // RWPS-2858
    @api recommendationTitles = ''; // RWPS-2858

    // RWPS-3003 start
    @api einsteinRecommendationMaxCount = 6; // Repurposed input for product recommendations count - RWPS-4437
    @api einsteinRecommendationsToShow = ''; // Deprecated - RWPS-4437
    @api einsteinRecommendationTitles = ''; // Deprecated - RWPS-4437
    get einsteinRecommendations() {
        let recommendationList = this.einsteinRecommendationsToShow?.split(',').map(el=>el.trim());
        let recTitleList = this.einsteinRecommendationTitles?.split(';').map(el=>el.trim());
        if(!recTitleList) {
            recTitleList = [];
        }

        if(this.einsteinRecommendationsToShow && recommendationList) {
            return recommendationList.map((el, idx) => {
                return {
                    name: el,
                    title: recTitleList[idx],
                    key: 'einstein-rec-'+idx
                }
            });
        } else {
            return [];
        }
    }
    // RWPS-3003 end

    @track itemsCountInWishlist;
    //@track isLoadMoreBtnDisabled = false;
    @track myFavs = [];
    myAllFavs = [];
    wishListSummary;
    selectedItems = [];
    productObject = 'Product2';
    favItemCount;
    fieldlabelmap;
    favListRecords;
    index = 0;
    timeSpan=0;
    isFavoritePage = false;
    message;
    type;
    show;
    productsOverview = [];
    productsOverviewList = [];
    finalProductsOverview = [];
    pricingResult = [];
    showSpinner = false;
    showModal = false;
    @wire(MessageContext)
    messageContext;
    recordDetailsList = [];
    currentPageNumber  = 1;
    noFavItems = false;
    productData;
    sidebarCSS='';
    middleSpaceCSS = '';
    device = {
        isMobile : FORM_FACTOR==='Small',
        isDesktop : FORM_FACTOR==='Large' || FORM_FACTOR==='Medium'
    }

    @track
    itemImage = true
    images = {
        cartimg: sres_ECOM_CartIcons + '/img/bag-line.png',
        deleteimg: sres_ECOM_CartIcons + '/img/delete-icon.png',
        quickorderimg:sres_ECOM_CartIcons + '/img/quick-order.png',
        favoriteimg:sres_ECOM_CartIcons + '/img/heart-line.png',
        helpimg:sres_ECOM_CartIcons + '/img/help-icon.png',
        termsimg:sres_ECOM_CartIcons + '/img/pencil-line.png',
        prodimg:sres_ECOM_CartIcons + '/img/productimage.png',
        dashboard:sres_ECOM_CartIcons + '/img/dashboard.png',
        logout:sres_ECOM_CartIcons + '/img/logout.png',
        defaultProdImage : sres_ECOM_CartIcons + '/img/placeholder.png'//RWPS-1387
    }
    fileName ='ecom_favorites';//RWPS-5153
    moduleName ='User Management';//RWPS-5153
    //RWPS-2390 START
    @track isPunchoutUser;
    @wire(getRecord, {
        recordId: USER_ID,
        fields: [ECOM_Is_Punchout_User__c]
    }) wireuser({
        error,
        data
    }) {
        if (error) {
           this.error = error ;
           processAndLogJSError(error, this.fileName, this.moduleName, 'wiredGetPunchoutUser');//RWPS-5153
        } else if (data) {
            this.isPunchoutUser = data.fields.ECOM_Is_Punchout_User__c.value;
        }
    }//RWPS-2390 END

    get renderTitleText(){
        return this.isFavoritePage && this.favItemCount >= 0;
    }

    get showViewAllAction(){
        return !this.isFavoritePage && this.favItemCount;
    }

    get showPagination(){
        return this.isFavoritePage && this.myFavs.length;
    }

    get headTitleCssClass(){
        return this.isFavoritePage? 'ecom_fav-label' : 'ecom-fav-label-dashboard';
    }

    get gridForDashBoard(){
        return this.isFavoritePage? 'slds-size_12-of-12 slds-large-size_7-of-12 slds-medium-size_12-of-12 slds-small-size_12-of-12' : 'slds-size_12-of-12 slds-large-size_12-of-12 slds-medium-size_12-of-12 slds-small-size_12-of-12'
    }

    // RWPS-4437
    get recFavsIds() {
        if(!this.myFavs?.length){
            return [];
        }

        return this.myFavs.map((item) => {
            return item.Product2Id;
        });
    }

    connectedCallback() {
        try{//RWPS-5153
            console.log('1');
        this.loadBasedOnDeviceType();
        this.showSpinner = true;
        if (window.location.href.indexOf("favorites") != -1){
            this.isFavoritePage = true;
        }
        const result = contextApi.getSessionContext();
        result.then((response) => {
            this.effectiveAccountId = response.effectiveAccountId;
            if(this.effectiveAccountId ) {
                this.getWishlistSummary();
            }
        }).catch((error) => {
            processAndLogJSError(error, this.fileName, this.moduleName, 'getSessionContext');//RWPS-5153
        });
    }catch(error){  //RWPS-5153 start
        processAndLogJSError(error, this.fileName, this.moduleName, 'connectedCallback');
    }//RWPS-5153 end
    }

    //TAB UI Fix - Gaurang - 18 July 2024
    loadBasedOnDeviceType(){
        var width = (window.innerWidth > 0) ? window.innerWidth : screen.width;
        if(FORM_FACTOR==='Medium' || (width==1025)){
            this.sidebarCSS = 'slds-size_12-of-12 slds-large-size_12-of-12 slds-medium-size_12-of-12 slds-small-size_12-of-12';
            this.middleSpaceCSS = 'doNotDisplay';
        }
        else{
            this.sidebarCSS = 'slds-size_12-of-12 slds-large-size_3-of-12 slds-medium-size_3-of-12 slds-small-size_12-of-12';
            this.middleSpaceCSS = 'slds-large-size_1-of-12 slds-medium-size_1-of-12';
        }
    }
    //RWPS-2786 - START
    isNonSellablePartDelete = false;
    deletedPartNumbers;
    showNonSellablePartsMessage(){
        this.isNonSellablePartDelete = true;
        this.getWishlistSummary();
    }
    //RWPS-2786 - END

    // RWPS-3740 - START
    replacementContractPrice = {};
    async getReplacementPrice(replacementMap) {
        this.replacementContractPrice = await getReplacementProductContractPrice(replacementMap);
    }
    // RWPS-3740 - END

    getWishlistSummary() {
        try{//RWPS-5153
        let fields = this.fieldsToShow?.split(',');
        fields.push('DisplayUrl', 'ECOM_Product_Media_URI__c'); // RWPS-3740
        getWishlistSummaries({
            communityId: communityId,
            effectiveAccountId: this.effectiveAccountId,
            productFields: fields,//this.fieldsToShow,
            objectName: this.productObject
        }).then((result) => {

            if(result.Status === 'Success' && result?.favItems?.length && result?.pricingResult?.pricingLineItemResults.length){
                this.getReplacementPrice(result.replacementMap); // RWPS-3740

                this.wishListSummary = result;
                this.productsOverview = result?.productsOverview.products;
                if(result?.productsOverviewList.length > 0){
                    this.productsOverviewList = result?.productsOverviewList;
                    for (let i = 0; i < this.productsOverviewList.length; i++) {
                        this.finalProductsOverview.push(...this.productsOverviewList[i].products);
                    }
                }
                else{
                    this.finalProductsOverview = this.productsOverview;
                }
                this.productData = result;
                this.pricingResult = result?.pricingResult?.pricingLineItemResults;
                let allFavItems = result?.favItems;
                for(let i in allFavItems){
                    let favItem = [allFavItems[i]];
                    //allFavItems[i].productSummary.thumbnailImage.url = resolve(allFavItems[i].productSummary.thumbnailImage.url ?? '', false, { });
                    let productRecord = favItem.map(obj => this.finalProductsOverview.find(o => o.id === obj.Product2Id) || obj);
                    allFavItems[i]['productDetail'] = productRecord[0];
                    //RWPS-1387
                    allFavItems[i].productDetail.defaultImage.url = resolve((productRecord[0]?.fields?.ECOM_Product_Media_URI__c || this.images?.defaultProdImage) ?? '', false, { });
                    let productPrice = favItem.map(obj => this.pricingResult.find(o => o.productId === obj.Product2Id) || obj);
                    allFavItems[i]['productPricing'] = productPrice[0];
                    allFavItems[i]['CurrencyIsoCode'] = result?.pricingResult?.currencyIsoCode;

                    allFavItems[i]['isSellable'] =  result?.productSaleStatus && result?.productSaleStatus.hasOwnProperty(productRecord[0].id) ? result?.productSaleStatus[productRecord[0].id] : false;
                    this.isPunchoutUser ? allFavItems[i]['isExcluded'] = result?.excludedProdStatusMap && result?.excludedProdStatusMap.hasOwnProperty(productRecord[0].id) ? result?.excludedProdStatusMap[productRecord[0].id] : false : false; //RWPS-2390
                }
                this.myAllFavs = allFavItems;
                this.recordDetailsList = allFavItems;
                this.fieldlabelmap = result?.fieldsMap;
                this.getFieldLabels();
                this.favItemCount = this.myAllFavs.length;
                this.myFavs = this.recordDetailsList.slice(0,this.recordsToDisplay);
                this.noFavItems = false;
            }else if(result.Status === 'Success' && result?.favItems?.length && !result?.pricingResult?.pricingLineItemResults.length){
                this.myAllFavs = [];
                this.myFavs = [];
                this.noFavItems = true;
                this.favItemCount = this.myAllFavs.length;
            }else if(result.Status === 'Success' && !result?.favItems?.length){
                this.myAllFavs = [];
                this.myFavs = [];
                this.noFavItems = true;
                this.favItemCount = this.myAllFavs.length;
            }else{
                this.showMessage(
                    ECOM_107001,
                    'error',
                    true
                    );
            }

            //RWPS-2786 - START
            if(result.deletedPartNumbers.length > 0 && !this.isNonSellablePartDelete){
                this.deletedPartNumbers = result.deletedPartNumbers;
                this.showNonSellablePartsMessage();
            } else if(this.isNonSellablePartDelete){
                this.showMessage(this.deletedPartNumbers.join(',') + ' ' + this.labels.ECOM_Non_Sellable_Error_Message_Fav,'error',true);//RWPS-2786 //RWPS-5550
            }
            this.showSpinner = false;
            //RWPS-2786 - END

        }).catch((error) => {
            this.myAllFavs = undefined;
            processAndLogJSError(error, this.fileName, this.moduleName, 'getWishlistSummary');//RWPS-5153
        });
    }catch(error){//RWPS-5153
        processAndLogJSError(error, this.fileName, this.moduleName, 'getWishlistSummary');//RWPS-5153
    }//RWPS-5153
    }


    getFieldLabels(){
        //this.fieldsToShow += ',Dangerous_Goods_Indicator_Profile__c';
        let fieldMap ={};
        let fields = this.fieldsToShow?.split(',');
        for(let i=0;i< fields.length;i++ ){
            if(this.fieldlabelmap[fields[i]]){
                fieldMap[fields[i]]  = this.fieldlabelmap[fields[i]];
            }
        }
        this.fieldlabelmap = fieldMap;
    }

    handleLoadMore(){
        this.favListRecords += this.recordsToDisplay;
    }

    handleViewAll(){
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/favorites'
            }
        });
    }

    handleRemoveFromFav(event){
        // RWPS-4086 start
        if(this.showSpinner) {
            return;
        }
        // RWPS-4086 end

        this.showSpinner = true;
        let wishlistItemId = event.detail.wishlistItemId;
        removeWishlistItem({
            wishlistItemId: wishlistItemId
        }).then((result) => {
            if(result.Status == 'Success'){
                this.index = 0;
                this.myFavs = [];
                this.isNonSellablePartDelete = false; //RWPS-5550
                this.connectedCallback();
            }
            this.showSpinner = false;
        }).catch((error) => {
            processAndLogJSError(error, this.fileName, this.moduleName, 'removeWishlistItem');//RWPS-5153
            this.showSpinner = true;
        });
    }


    handleAddToCart(event){
        this.showSpinner = true;
            addItemsToCart({
                communityId: communityId,
                effectiveAccountId: this.effectiveAccountId,
                productId: event.detail.productId,
                qty: event.detail.qty
            }).then((result) => {
                if(result.Status === 'SUCCESS'){
                    this.showMessage(
                        'Successfully added '+event.detail.productName+' to cart.',
                        'success',
                        true
                        );
                    this.showSpinner = false;

                    let payLoad = {
                        message:1,
                        type: 'CartRefresh'
                    };
                    publish(this.messageContext, ECOM_MESSAGE, payLoad);
                }
            }).catch((error) => {
                processAndLogJSError(error, this.fileName, this.moduleName, 'handleAddToCart');//RWPS-5153
                this.showSpinner = true;
            });

    }

    handlePagination(event){
        const start = (event.detail-1)*this.recordsToDisplay;
        const end = this.recordsToDisplay*event.detail;
        this.myFavs = this.recordDetailsList.slice(start, end);
    }

    handleNavigateToCart(){
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
                attributes: {
                    url: '/cart'
                }
        });
    }

    handleCloseModal(){
        this.showModal = false;
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

    pageChanged(event) {
        let pageNumber = JSON.parse(JSON.stringify(event.detail.pageNumber));
        this.currentPageNumber = parseInt(pageNumber);
        const start = (this.currentPageNumber-1)*this.recordsToDisplay;
        const end = this.recordsToDisplay*this.currentPageNumber;
        this.myFavs = this.recordDetailsList.slice(start, end);
        window.scrollTo(0, 0);
    }

    handleShopNow(){
        let payLoad = {
            message: NAVIGATE_TO_PLP,
            type: CMS_NAVIGATION,
        };
        publish(this.messageContext, ECOM_MESSAGE, payLoad);
    }
}