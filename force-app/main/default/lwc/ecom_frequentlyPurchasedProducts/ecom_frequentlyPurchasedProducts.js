import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import {publish, MessageContext} from 'lightning/messageService';
import communityId from '@salesforce/community/Id';
import contextApi from 'commerce/contextApi';
import fetchFrequentlyBoughtProducts from '@salesforce/apex/ECOM_FrequentlyPurchasedController.getFrequentlyPurchasedProductForLoggedInUser';
import removeWishlistItem from '@salesforce/apex/ECOM_FavoritesController.removeWishlistItem';
import addItemsToCart from '@salesforce/apex/ECOM_FavoritesController.addItemsToCart';
import ECOM_MESSAGE from '@salesforce/messageChannel/ecom_MessagingChannel__c';
import sres_ECOM_CartIcons from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import FORM_FACTOR from '@salesforce/client/formFactor';

//js Utils
import { SYSTEM_LABELS} from 'c/ecom_punchoutUtil';
const NAVIGATE_TO_PLP = 'PLP';
const CMS_NAVIGATION = 'CMSNavigation';
export default class Ecom_frequentlyPurchasedProducts extends LightningElement {
    @api recordId;
    @api effectiveAccountId;
    @api fieldsToShow;
    @api recordsToDisplay;
    @track itemsCountInWishlist;
    //@track isLoadMoreBtnDisabled = false;
    @track myFavs = [];
    myAllFavs = [];
    wishListSummary;
    selectedItems = [];
    SproductObject = 'Product2';
    favItemCount;
    fieldlabelmap;
    favListRecords;
    index = 0;
    timeSpan=0;
    isFavoritePage = false;
    message;
    type;
    show;
    //cmsHomeBaseUrl = '';
    productsOverview = [];
    pricingResult = [];
    showSpinner = false;
    showModal = false;
    @wire(MessageContext)
    messageContext;
    recordDetailsList = [];
    currentPageNumber  = 1;
    noFavItems = false;
    productData;
    isPageLoadComplete = false;

    //VRa - Punchout changes - Begins
    //arrays
    frequentlyPurchasedProducts = [];
    wishlistItems = [];
    currentRecordsToDisplay = [];

    //Getters
    get displayRecords(){
        return this.currentRecordsToDisplay;
    }

    get isEmpty(){
        let isPageEmpty = false;
        if(this.isPageLoadComplete && this.currentRecordsToDisplay && this.currentRecordsToDisplay.length == 0 && this.frequentlyPurchasedProducts && this.frequentlyPurchasedProducts.length == 0){
            isPageEmpty = true;
        }

        return isPageEmpty ;
    }

    get currentWishListItems(){
        let currentItems = [];
        if(this.wishlistItems && this.wishlistItems.length > 0){
            currentItems = this.wishlistItems;
        }
        return currentItems;
    }

    get productCount(){
        let count = 0;
        if(this.frequentlyPurchasedProducts && this.frequentlyPurchasedProducts.length>0){
            count =  this.frequentlyPurchasedProducts.length;
        }
        return count;
    }

    get displayResults(){
        let isDisplay = false;
        if(this.frequentlyPurchasedProducts && this.frequentlyPurchasedProducts.length>0){
            isDisplay = true;
        }
        return isDisplay;
    }
    //VRa - Punchout changes - End

    device = {
        isMobile : FORM_FACTOR==='Small',
        isDesktop : FORM_FACTOR==='Large',
        isTablet :FORM_FACTOR==='Medium'
    }

    system_labels = SYSTEM_LABELS;

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
    }

    get renderTitleText(){
        return this.isFavoritePage && this.frequentlyPurchasedProducts && this.frequentlyPurchasedProducts.length >= 0 && !this.showSpinner;
    }

    get showViewAllAction(){
        return !this.isFavoritePage && this.favItemCount;
    }

    get showPagination(){
        return this.favItemCount && this.favItemCount>0;
    }

    get headTitleCssClass(){
        return this.isFavoritePage? 'ecom_fav-label' : 'ecom-fav-label-dashboard';
    }

    get gridForDashBoard(){
        return this.isFavoritePage? 'slds-size_12-of-12 slds-large-size_7-of-12 slds-medium-size_7-of-12 slds-small-size_12-of-12' : 'slds-size_12-of-12 slds-large-size_12-of-12 slds-medium-size_12-of-12 slds-small-size_12-of-12' 
    }

    errorCallback(error, stack){
        console.log('error::', error, ' stack::', stack);//Remove after DEV
    }

    connectedCallback() {
        
        this.recordsToDisplay = new Number(this.recordsToDisplay);
        this.showSpinner = true;
        if (window.location.href.indexOf("frequentlyPurchased") != -1){
            this.isFavoritePage = true;
        }
       // this.baseCMSUrl();
        const result = contextApi.getSessionContext();
        result.then((response) => {
            //console.log('response:: ', response);//Remove after DEV
            this.effectiveAccountId = response.effectiveAccountId;
            if(this.effectiveAccountId ) {
                this.getFrequentlyBoughtProducts();
            }
        }).catch((error) => {
            const errorMessage = error.body.message;
        });
    }

    getFrequentlyBoughtProducts(){
        let fields = this.fieldsToShow?.split(',');
        fields.push('DisplayUrl');
        console.log('Calling getFrequentlyBoughtProducts');//Remove after DEV
        fetchFrequentlyBoughtProducts().then(result => {
            console.log('result:: ', result);//Remove after DEV
            if(result && result.success && result.responseData && result.responseData.products && result.responseData.products.length >0 ) {
                this.frequentlyPurchasedProducts = result.responseData.products;
                this.wishlistItems = result?.responseData && result?.responseData?.wishlistsItems ? result?.responseData?.wishlistsItems : [];
                this.currentRecordsToDisplay = this.frequentlyPurchasedProducts.slice(0,this.recordsToDisplay);
                this.noFavItems = false;
                this.favItemCount = result.responseData.products.length;
                this.isPageLoadComplete = true;
                this.showSpinner = false;

            } else {
                this.isPageLoadComplete = true;
                this.showSpinner = false;
            }
        }).catch(err => {
            this.isPageLoadComplete = true;
            this.showSpinner = false;
            console.log('Error:: ', err);
        });
    }

    getFieldLabels(){
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
        this.showSpinner = true;
        let wishlistItemId = event.detail.wishlistItemId;
        removeWishlistItem({
            wishlistItemId: wishlistItemId
        }).then((result) => {
            if(result.Status == 'Success'){
                this.index = 0;
                this.myFavs = [];
                this.connectedCallback();
            }
            this.showSpinner = false;
        }).catch((error) => {
                    const errorMessage = error.body.message;
                    this.showSpinner = true;
        });
    }


    handleAddToCart(event){
        //console.log('handleAddToCart');//Remove after DEV
        this.showSpinner = true;
        const productId = event.detail.productId;
        const qty = event.detail.qty;
        const productName = event.detail.productName;
        //console.log('handleAddToCart',productId,qty,productName);//Remove after DEV
        try{
            addItemsToCart({
                communityId: communityId,
                effectiveAccountId: this.effectiveAccountId,
                productId: productId,
                qty: qty
            }).then((result) => {
                //console.log('result:: ',result);//Remove after DEV
                if(result.Status === 'SUCCESS'){
                    this.showMessage(
                        'Successfully added '+ productName +' to cart.',
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
                const errorMessage = error.message;
                this.showSpinner = true;
            });
        }catch(err){
            console.error('Error::Atc', err.message);//Remove after DEV
        }

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
        this.currentRecordsToDisplay = this.frequentlyPurchasedProducts.slice(start, end);
    }

    handleShopNow(){
        let payLoad = {
            message: NAVIGATE_TO_PLP,
            type: CMS_NAVIGATION,
        };
        publish(this.messageContext, ECOM_MESSAGE, payLoad);
    }

}