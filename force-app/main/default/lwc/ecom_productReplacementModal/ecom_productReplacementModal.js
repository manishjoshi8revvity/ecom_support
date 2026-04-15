import { LightningElement, api, wire, track } from 'lwc';
import LBL_URL_PATH_SEPARATOR from '@salesforce/label/c.ECOM_UrlPathSeparator';
import LBL_CMS_PARAM_PREFIX from '@salesforce/label/c.ECOM_CMSPunchoutLoginParameter';
import LBL_CMS_BUY_PAGE from '@salesforce/label/c.ECOM_CMSBuyPage';
import ECOM_Remove from '@salesforce/label/c.ECOM_Remove';
import ECOM_Remove_Favorites from '@salesforce/label/c.ECOM_Remove_Favorites';
import ECOM_SaveToFavorites from '@salesforce/label/c.ECOM_SaveToFavorites';
import ECOM_Product_Receive_Message from '@salesforce/label/c.ECOM_Product_Receive_Message';
import ECOM_Each from '@salesforce/label/c.ECOM_Each';
import ECOM_EstDeliveryDate_Message from '@salesforce/label/c.ECOM_Estimated_Delivery_Date_Message';
import ECOM_PartNumber from '@salesforce/label/c.ECOM_PartNumber';
import ECOM_Discontinued_Message from '@salesforce/label/c.ECOM_Discontinued_Message'
import ECOM_Add_to_Cart from '@salesforce/label/c.ECOM_Add_To_Cart_CTA';
import sres_ECOM_CartIcons from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import ECOM_Contact_Us_Url from '@salesforce/label/c.ECOM_Contact_Us_Url';
import FORM_FACTOR from '@salesforce/client/formFactor';
import getContractPrice from '@salesforce/apex/ECOM_CartController.getContractPrice';
import addItemsToCart from '@salesforce/apex/ECOM_OrderHistoryController.addItemsToCart';
import { publish, MessageContext } from 'lightning/messageService';
import communityId from '@salesforce/community/Id';
import contextApi from 'commerce/contextApi';
import ECOM_AddedToCartSuccessfully from '@salesforce/label/c.ECOM_AddedToCartSuccessfully';
import ECOM_105105 from '@salesforce/label/c.ECOM_105105';
import ECOM_MaxQuantity from '@salesforce/label/c.ECOM_MaxQuantity';
import ECOM_MESSAGE from '@salesforce/messageChannel/ecom_MessagingChannel__c';
import deleteDiscontinuedProductsWithReplacement from '@salesforce/apex/ECOM_CheckoutController.deleteDiscontinuedProductsWithReplacement';
import encodeUrlParams from '@salesforce/apex/ECOM_UserController.getEncyrptedSessionParametersForCMS';
import deleteReplacedCartItem from '@salesforce/apex/ECOM_CheckoutController.deleteReplacedCartItem';
import { getUserConfigData } from 'c/ecom_punchoutUtil';
import discontinuedText from "@salesforce/label/c.ECOM_Product_Tile_Discontinued_Text";//RWPS-3740
import discontinuedTooltipText from "@salesforce/label/c.ECOM_Discontinued_Product_Tooltip_Text";//RWPS-4602
import contractPriceLoading from "@salesforce/label/c.ECOM_Price_Loading";//RWPS-4777
import replacementAlternativeText from "@salesforce/label/c.ECOM_Recommended_alternatives";//RWPS-4777
import replacementText from "@salesforce/label/c.ECOM_Replacement_Popup_Replacement_Text";//RWPS-4777
import {processAndLogJSError} from 'c/ecom_util'; // RWPS-5153
const NAVIGATE_TO_PDP = 'PDP';
const CMS_NAVIGATION = 'CMSNavigation';


export default class Ecom_productReplacementModal extends LightningElement {

    @api cartitemDiscontinuedProducts;
    @api
    replacementProductsMap;
    @api
    items;
    @api
    wishlist;
    isCartDisabled = true;//RWPS-4874
    minQuantity = 1;
    _quantity = 1;
    maxQuantity = 999;
    contractPricesFetched = false;
    cartItemsList = [];
    showSpinner = false;
    @wire(MessageContext)
    messageContext;
    effectiveAccountId;
    message;
    type;
    show;
    cartId;
    currentIndex = 0;
    currentSlide = 1;
    @track showModal = false;//RWPS-5284
    set quantity(val) {
        this._quantity = val;
    }
    get quantity() {
        return this._quantity;
    }

    labels = {
        LBL_URL_PATH_SEPARATOR,
        LBL_CMS_PARAM_PREFIX,
        LBL_CMS_BUY_PAGE,
        ECOM_Remove,
        ECOM_Remove_Favorites,
        ECOM_SaveToFavorites,
        ECOM_Product_Receive_Message,
        ECOM_Each,
        ECOM_PartNumber,
        ECOM_EstDeliveryDate_Message,
        ECOM_Contact_Us_Url,
        ECOM_Discontinued_Message,
        ECOM_Add_to_Cart,
        ECOM_AddedToCartSuccessfully,
        ECOM_105105,
        ECOM_MaxQuantity,
        discontinuedText, //RWPS=3740
        discontinuedTooltipText, //RWPS=3740
        contractPriceLoading,//RWPS-4777
        replacementAlternativeText,//RWPS-4777
        replacementText//RWPS-4777

    }
    //RWPS-5284 start
    #escapeKeyCallback;
    fileName ='ecom_productReplacementModal';//RWPS-5153
    moduleName ='ECOM_CartService';//RWPS-5153

    disconnectedCallback() {
        document.removeEventListener('keydown', this.#escapeKeyCallback);
    }
    escapeKeyCallback(event) {
        if (event.key === 'Escape' || event.keyCode === 27) {
    
            if (this.showModal) {
                this.handleCloseModal();
            }
        }
    }//RWPS-5284 end

    //RWPS-4874-START
    handlePrev(event) {
        let index = event.currentTarget.dataset.index;
        const currentItemData = this.cartitems[index];
        const currentItem = this.cartitems[index].carouselStatus.currentSlide;
        const alternatives = currentItemData?.childDetails?.AlternativeReplacements;
        if(currentItem > 1){
            this.cartitems[index].carouselStatus.currentSlide--;
             this.cartitems[index].carouselStatus.slideStyle = `transform: translateX(-${(currentItem-2) * 100}%);
                transition: transform 0.5s ease;`;
            this.cartitems[index].carouselStatus.disabledLeftControl = this.cartitems[index].carouselStatus.currentSlide === 1;
            this.cartitems[index].carouselStatus.disabledRightControl =  this.cartitems[index].currentSlide === alternatives.length;

        }
    }

    handleNext(event) {
        let index = event.currentTarget.dataset.index;
        const currentItemData = this.cartitems[index];
        const currentItem = this.cartitems[index].carouselStatus.currentSlide;
        const alternatives = currentItemData?.childDetails?.AlternativeReplacements;
        if (Array.isArray(alternatives)) {
            if(currentItem < alternatives.length){
                this.cartitems[index].carouselStatus.currentSlide++;
                this.cartitems[index].carouselStatus.slideStyle = `transform: translateX(-${(currentItem) * 100}%);
                transition: transform 0.5s ease;`;
                this.cartitems[index].carouselStatus.disabledLeftControl =  this.cartitems[index].carouselStatus.currentSlide === 1;
                this.cartitems[index].carouselStatus.disabledRightControl =  this.cartitems[index].carouselStatus.currentSlide === alternatives.length;

            }
        }
    }
    //RWPS-4874-END



    images = {
        cartimg: sres_ECOM_CartIcons + '/img/bag-line.svg',
        deleteimg: sres_ECOM_CartIcons + '/img/trash-purple.svg',
        quickorderimg: sres_ECOM_CartIcons + '/img/quick-order.svg',
        favoriteimg: sres_ECOM_CartIcons + '/img/heart-line.svg',
        helpimg: sres_ECOM_CartIcons + '/img/help-icon.svg',
        termsimg: sres_ECOM_CartIcons + '/img/pencil-line.svg',
        radIcon: sres_ECOM_CartIcons + '/img/radIcon.svg',
        filledfavorite: sres_ECOM_CartIcons + '/img/ecomFilledHeartIcon.svg',
        purplehelpimg: sres_ECOM_CartIcons + '/img/checkouttooltip.png',
        defaultProdImage: sres_ECOM_CartIcons + '/img/placeholder.png'
    }
    showStrikePrice = false;
    isFavorite = true;

    isFavorite(productId) {
        return this.wishlist && this.wishlist[productId] ? true : false;
    }


    currencyDisplayAs = 'code';

    get formattedReplacementProducts() {
        const result = [];

        const map = this.replacementProductsMap;
        if (!map || typeof map !== 'object') return result;

        for (const productId in map) {
            const entry = map[productId];

            // Handle DirectReplacement
            const directReplacement = entry?.DirectReplacement;
            if (directReplacement) {
                result.push({
                    fields: {
                        Dangerous_Goods_Indicator_Profile__c: directReplacement.Dangerous_Goods_Indicator_Profile__c || '',
                        Part_Number__c: directReplacement.Part_Number__c || '',
                        Id: directReplacement.Id || ''
                    },
                    Name: directReplacement.Name || '',
                    Product_Display_Name__c: directReplacement.Product_Display_Name__c || ''
                });
            }

            // Handle AlternativeReplacements (array)
            const alternativeReplacements = entry?.AlternativeReplacements;
            if (Array.isArray(alternativeReplacements) && !directReplacement) {
                alternativeReplacements.forEach(alt => {
                    result.push({
                        fields: {
                            Dangerous_Goods_Indicator_Profile__c: alt.Dangerous_Goods_Indicator_Profile__c || '',
                            Part_Number__c: alt.Part_Number__c || '',
                            Id: alt.Id || ''
                        },
                        Name: alt.Name || '',
                        Product_Display_Name__c: alt.Product_Display_Name__c || ''
                    });
                });
            }
        }
        return result;
    }


    isPriceFetched = false;//RWPS-4777
    async fetchContractPrices() {
        try {
            // Prepare product request from all replacement products
            const productRequest = this.formattedReplacementProducts.map(p => ({
                ...p.fields,
                Id: p.fields.Id
            }));

            // RWPS-4775 start
            let contractPrice = {};

            if(productRequest?.length && !this.isPriceFetched) {//RWPS-4777
                contractPrice = await getContractPrice({ products: productRequest });
            }
            // RWPS-4775 end

            let pricingMap = {};
            if (contractPrice && contractPrice.Product_list?.length && !this.isPriceFetched) {//RWPS-4777
                contractPrice.Product_list.forEach(p => {
                    pricingMap[p.part_number] = {
                        contractprice: p.price,
                        listPrice: p.list_price
                    };
                });
            }

            // Attach price to each product
            this.pricedProducts = this.formattedReplacementProducts.map(p => ({
                ...p,
                price: pricingMap[p.fields.Part_Number__c]?.contractprice || null
            }));

            // Safely inject contractprice and listPrice into replacementProductsMap
            const updatedMap = {};

            for (const productId in this.replacementProductsMap) {
                const originalEntry = this.replacementProductsMap[productId];
                const updatedEntry = { ...originalEntry };

                // Handle DirectReplacement
                const directReplacement = originalEntry?.DirectReplacement;
                if (directReplacement) {
                    const partNumber = directReplacement.Part_Number__c;
                    const pricing = pricingMap[partNumber];

                    updatedEntry.DirectReplacement = {
                        ...directReplacement,
                        contractprice: pricing?.contractprice || null,
                        listPrice: pricing?.listPrice || null
                    };
                }

                // Handle AlternativeReplacements
                const alternativeReplacements = originalEntry?.AlternativeReplacements;
                if (Array.isArray(alternativeReplacements)) {
                    updatedEntry.AlternativeReplacements = alternativeReplacements.map(alt => {
                        const partNumber = alt.Part_Number__c;
                        const pricing = pricingMap[partNumber];

                        return {
                            ...alt,
                            contractprice: pricing?.contractprice || null,
                            listPrice: pricing?.listPrice || null
                        };
                    });
                }

                updatedMap[productId] = updatedEntry;
            }
            //RWPS-4777- START
            // Replace the reactive map with the updated clone
            this.replacementProductsMap = { ...updatedMap};
            if (this.replacementProductsMap && Object.keys(this.replacementProductsMap).length > 0 && !this.isPriceFetched) {
                this.processItems(); // Rebuild cartitems with updated pricing
                this.isPriceFetched = true;
                this.isCartDisabled = false;//RWPS-4874
              }
              //RWPS-4777- END
              

        } catch (error) {
            processAndLogJSError(error, this.fileName, this.moduleName, 'fetchContractPrices');//RWPS-5153
        }
    }


    handleCloseModal() {
        setTimeout(() => {//RWPS-5284 start
            this.deleteDiscontinuedProductsWithReplacement();
        }, 0);//RWPS-5284 end
        this.contractPricesFetched = false;
        this.showModal = false;//RWPS-5284 
    }

    @track processedCartItems = [];
    alternativeReplacementCount = 0
    @track discontinuedWithReplacementsList = [];

    @track wishlistProducts = [];
  

    processItems() {
        try{//RWPS-5153
        if (!Array.isArray(this.items)) {
            this.cartitems = [];
            return;
        }
        //call fetch api
        this.fetchContractPrices();//RWPS-4777
        if (this.wishlist && Object.keys(this.wishlist).length > 0) {
            for (let key of Object.keys(this.wishlist)) {
                this.wishlistProducts.push(this.wishlist[key].productId);
            }
        }

        this.cartitems = this.items
            .map(item => {
                const productId = item.cartItem?.productId;
                this.cartId = item.cartItem?.cartId;
                const isDiscontinued = this.cartitemDiscontinuedProducts?.[productId] || false;
                const childData = this.replacementProductsMap?.[productId];
                const hasDirect = !!childData?.DirectReplacement;
                const hasAlternatives = Array.isArray(childData?.AlternativeReplacements) && childData.AlternativeReplacements.length > 0;
                const isVisible = true;

                if (hasAlternatives) {
                    this.alternativeReplacementCount = childData.AlternativeReplacements.length;//RWPS-4777
                }

                if (hasDirect || hasAlternatives) {
                    this.discontinuedWithReplacementsList.push(item.cartItem.cartItemId);
                    this.contractPricesFetched = true;//RWPS-4777
                }

                if (hasDirect && this.wishlistProducts && this.wishlistProducts.includes(childData.DirectReplacement.Id)) {
                    Reflect.set(childData.DirectReplacement, 'isWishlisted', true);//RWPS-4777
                }

                if (hasAlternatives && this.wishlistProducts) {
                    for (let i = 0; i < childData.AlternativeReplacements.length; i++) {
                        if (this.wishlistProducts.includes(childData.AlternativeReplacements[i].Id)) {
                            Reflect.set(childData.AlternativeReplacements[i], 'isWishlisted', true);//RWPS-4777
                        }
                    }
                }
            

                return {
                    ...item,
                    cartItem: {
                        ...item.cartItem,
                        productId,
                        isDiscontinued,
                        isVisible
                    },
                    childDetails: hasDirect || hasAlternatives ? childData : null,
                    carouselStatus:{currentSlide:1, slideStyle:'',showSlider: childData?.AlternativeReplacements?.length > 1 ? true : false,prodQty:1, disabledLeftControl:true, disabledRightControl:false}//RWPS-4874
                };
            })
            .filter(item => item.cartItem.isDiscontinued && !!item.childDetails);
            }catch(error){//RWPS-5153 start
                processAndLogJSError(error, this.fileName, this.moduleName, 'processItems');
            }//RWPS-5153 end
    }

    @track cartitems = [];

    connectedCallback() {
        this.showModal = true;//RWPS-5284
        this.loadBasedOnDeviceType();
        //RWPS-4777
        this.processItems();
        const result = contextApi.getSessionContext();
        result.then((response) => {
            this.effectiveAccountId = response.effectiveAccountId;
        }).catch((error) => {
             processAndLogJSError(error, this.fileName, this.moduleName, 'getSessionContext');//RWPS-5153
        });
        this.#escapeKeyCallback = this.escapeKeyCallback.bind(this);//RWPS-5284
        document.addEventListener('keydown', this.#escapeKeyCallback);//RWPS-5284

    }

    device = {
        isMobile: FORM_FACTOR === 'Small',
        isDesktop: FORM_FACTOR === 'Large',
        isTablet: FORM_FACTOR === 'Medium'
    }

    loadBasedOnDeviceType() {
        if (this.device.isMobile) {
            this.mobile = true;
            this.cardClassBottom = "radiun-bottom slds-small-size_12-of-12";
            this.cardSize = "cart-item-card-mobile";
            this.cardQuantityCSS = "slds-form-element ecom-cart-prod-qty-ctr-mobile";
            this.cartPriceBoxCSS = "slds-size_4-of-12 slds-large-size_4-of-12 slds-medium-size_4-of-12 slds-small-size_4-of-12 cartPriceBoxMobile"; //RWPS-4777
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
            this.cartPriceBoxCSS = "slds-size_4-of-12 slds-large-size_4-of-12 slds-medium-size_4-of-12 slds-small-size_4-of-12 cartPriceBox"; //RWPS-4777
            this.modalCSS = 'slds-modal slds-fade-in-open';
            this.textDiscountinue = '.ecom-text-mob';
            //RWPS-2786 - Start
            if (this.device.isTablet) {
                this.btnDiscontinue = 'slds-button btn-discountinue-tablet';
            } else {
                this.btnDiscontinue = 'slds-button btn-discountinue';
            }
            this.discontinuedMain = 'ecom-discontinued-prod';
            this.textDiscountinue = 'ecom-text';

            //RWPS-2786 - End

        }
    }

    setcartItemsList(prodId,qty) {
        this.cartItemsList.push({ Product2Id: prodId, Quantity: qty });//RWPS-4874
    }


    handleQuantityIncrement(event) {
        //RWPS-4874 - START
        const index = event.currentTarget.dataset.index;
        const item = this.cartitems[index];

        // Safely parse quantity
        let qty = parseInt(item.carouselStatus.prodQty, 10);
        // Increment quantity
        qty += 1;

        // Check against maxQuantity
        if (qty > this.maxQuantity) {
            item.carouselStatus.prodQty = this.maxQuantity;
            this.showMessage(
                'Quantity cannot be greater than 999.',
                'error',
                true
            );
            return false;
        }

        item.carouselStatus.prodQty = qty;
        //RWPS-4874 - END
    }

    handleQuantityDecrement(event) {
        //RWPS-4874 - START
        const index = event.currentTarget.dataset.index;
        const item = this.cartitems[index];
        let qty = parseInt(item.carouselStatus.prodQty, 10);
        if (qty <= this.minQuantity) {
            item.carouselStatus.prodQty = this.minQuantity;
            this.showMessage(
                'Quantity cannot be less than 1.',
                'error',
                true
            );
            return false;
        }

        item.carouselStatus.prodQty = qty - 1;
        //RWPS-4874 - END
    }
    //RWPS-4874 - START
    handleQuantityChange(event) {
        const index = event.currentTarget.dataset.index;
        const inputValue = event.target.value.trim();
        const item = this.cartitems[index];
        let qty = parseInt(inputValue, 10);
        // Clamp quantity within allowed range
        if (qty < this.minQuantity || qty > this.maxQuantity) {
            qty = this.minQuantity;
            this.showMessage(
                `Quantity must be between ${this.minQuantity} and ${this.maxQuantity}.`,
                'error',
                true
            );
        }

        // Update both model and input field
        item.carouselStatus.prodQty = qty;
        event.target.value = qty;
    }
     //RWPS-4874 - END

    scrollToTop() {
        const modalContent = this.template.querySelector('.slds-modal__content');
        if (modalContent) {
            modalContent.scrollTop = 0;
        }
    }

    // Add item to the cart
    handleAddToCart(event) {
    try{   //RWPS-5153
        if (this.showSpinner) {
            return;
        }
        // RWPS-4086 end
        this.cartItemsList = [];
        this.showSpinner = true;
        let prodId = event.currentTarget.dataset.id;
        let discontinuedProduct = event.currentTarget.dataset.discontinuedproduct;
        let index = event.currentTarget.dataset.index;
        this.setcartItemsList(prodId,this.cartitems[index].carouselStatus.prodQty );
        if (this.cartItemsList.length > 0 && this.quantity >= this.minQuantity && this.quantity <= this.maxQuantity) {//RWPS-4874
            // Call the 'addItemsToCart' apex method imperatively
            addItemsToCart({
                communityId: communityId,
                effectiveAccountId: this.effectiveAccountId,
                cartItems: this.cartItemsList
            }).then((result) => {
                this.scrollToTop();
                if (result.itemsAddedSuccessfully[0] == prodId) {
                    this.showMessage(
                        this.labels.ECOM_AddedToCartSuccessfully,
                        'success',
                        true
                    );

                    deleteReplacedCartItem({cartItemId: discontinuedProduct}).then((deletionResult) => {
                        let payLoad = {
                            message: 1,
                            type: 'CartRefresh'
                        };
                        publish(this.messageContext, ECOM_MESSAGE, payLoad);
                        this.showSpinner = false;

                        let remainingReplacementList = [];
                        if (this.discontinuedWithReplacementsList.length > 0) {
                            for (let i = 0; i < this.discontinuedWithReplacementsList.length; i++) {
                                if (this.discontinuedWithReplacementsList[i] != discontinuedProduct) {
                                    remainingReplacementList.push(this.discontinuedWithReplacementsList[i]);
                                }
                            }
                            this.discontinuedWithReplacementsList = remainingReplacementList;
                        }

                        this.cartitems[index].cartItem.isVisible = false;
                        if (this.discontinuedWithReplacementsList.length == 0) {
                            this.dispatchEvent(
                                new CustomEvent('replacementmodalclose', {
                                    detail: {
                                        success: true,
                                    }
                                })
                            );
                            this.contractPricesFetched = false;
                        }
                    }).catch((deletionError) => {
                        console.error(deletionError);
                    });
                }
                else {
                    this.showMessage(
                        this.labels.ECOM_105105,
                        'error',
                        true
                    );
                }

            }).catch((error) => {
                this.showSpinner = false;
                processAndLogJSError(error, this.fileName, this.moduleName, 'addItemsToCart');//RWPS-5153
                this.showMessage(
                    this.labels.ECOM_105105,
                    'error',
                    true
                );

            });
        }
        else {
            this.showMessage(
                this.labels.ECOM_MaxQuantity,
                'error',
                true
            );
            this.quantity = this.minQuantity;
            return false;
        }
    }catch(error){//RWPS-5153 start
         processAndLogJSError(error, this.fileName, this.moduleName, 'handleAddToCart');
    }//RWPS-5153 end
    }

    showMessage(message, type, show) {
        this.message = message;
        this.type = type;
        this.show = show;
    }

    handleUpdateMessage(event) {
        this.message = '';
        this.type = '';
        this.show = event.detail.show;
    }

    handleDeleteCartItem(event) {
        const index = event.currentTarget.dataset.index;
        this.cartitems[index].cartItem.isVisible = false;

        let discontinuedProduct = event.currentTarget.dataset.discontinuedproduct;
        deleteReplacedCartItem({cartItemId: discontinuedProduct}).then((deletionResult) => {
            let payLoad = {
                message: 1,
                type: 'CartRefresh'
            };
            publish(this.messageContext, ECOM_MESSAGE, payLoad);
            this.showSpinner = false;

            let remainingReplacementList = [];
            if (this.discontinuedWithReplacementsList.length > 0) {
                for (let i = 0; i < this.discontinuedWithReplacementsList.length; i++) {
                    if (this.discontinuedWithReplacementsList[i] != discontinuedProduct) {
                        remainingReplacementList.push(this.discontinuedWithReplacementsList[i]);
                    }
                }
                this.discontinuedWithReplacementsList = remainingReplacementList;
            }

            if (this.discontinuedWithReplacementsList.length == 0) {
                this.dispatchEvent(
                    new CustomEvent('replacementmodalclose', {
                        detail: {
                            success: true,
                        }
                    })
                );
                this.contractPricesFetched = false;
            }
        }).catch((deletionError) => {
            processAndLogJSError(error, this.fileName, this.moduleName, 'deleteReplacedCartItem');//RWPS-5153
        });
    }

    navigateToPDP(event) {
    try{//RWPS-5153
        event.target?.focus();

        let displayURL = event.currentTarget.dataset.url;

        if (!displayURL) {
            return;
        }

        let payLoad = {
            message: NAVIGATE_TO_PDP,
            type: CMS_NAVIGATION,
            partNumber: '',
            url: displayURL
        };

        let userConfig = getUserConfigData();

        if (userConfig && userConfig.isPunchoutUser) {
            let urlParams = '';
            encodeUrlParams().then(result => {
                if (result && result?.success && result?.responseData) {
                    let baseUrl = result.Home;
                    //RWPS-1817
                    if (result.locale && result.locale != '') {
                        if (baseUrl.substr(-1) != '/') {
                            baseUrl += LBL_URL_PATH_SEPARATOR;
                        }
                        baseUrl = baseUrl + result.locale;
                    }
                    urlParams = result.responseData;
                    window.location.href = baseUrl + displayURL + LBL_CMS_PARAM_PREFIX + urlParams;//Remove after DEV
                } else {
                    publish(this.messageContext, ECOM_MESSAGE, payLoad);
                }
            }).catch(error => {
                processAndLogJSError(error, this.fileName, this.moduleName, 'encodeUrlParams');//RWPS-5153
            });
        } else {
            publish(this.messageContext, ECOM_MESSAGE, payLoad);
        }
    }catch(error){//RWPS-5153 start
        processAndLogJSError(error, this.fileName, this.moduleName, 'navigateToPDP');//RWPS-5153
    }//RWPS-5153 end
    }

    handleRemoveFromFavourite(event) {
        let productid = event.currentTarget.dataset.productid;
        let source = event.currentTarget.dataset.source;
        let index = event.currentTarget.dataset.index;

        this.dispatchEvent(
            new CustomEvent('removefromfavorite', {
                detail: {
                    wishlistItemId: this.wishlist[productid].wishListItemId,
                }
            }, {
                bubbles: true,
                composed: true
            })

        );

        // this.isFavorite = true;
        if (source == 'direct' && this.cartitems[index]?.childDetails?.DirectReplacement?.isWishlisted) {
            this.cartitems[index].childDetails.DirectReplacement.isWishlisted = false;
        }


        if (source == 'indirect' && this.cartitems[index]?.childDetails?.AlternativeReplacements) {
            for (let i = 0; i < this.cartitems[index].childDetails.AlternativeReplacements.length; i++) {
                if (this.cartitems[index].childDetails.AlternativeReplacements[i].Id == productid) {
                    this.cartitems[index].childDetails.AlternativeReplacements[i].isWishlisted = false;
                }
            }
        }

        this.scrollToTop();
        this.showMessage(
            'Item removed from favorites successfully.',
            'success',
            true
        );
    }

    handleAddToFavourite(event) {
    try{//RWPS-5153
        event.target?.focus();
        let productid = event.currentTarget.dataset.productid;
        let productName = event.currentTarget.dataset.productname;
        let source = event.currentTarget.dataset.source;
        let index = event.currentTarget.dataset.index;

        this.dispatchEvent(
            new CustomEvent('createandaddtolist', {
                detail: {
                    productId: productid,
                    productName: productName
                }
            }, {
                bubbles: true,
                composed: true
            })
        );

        // this.isFavorite = this.isFavorite(productid);
        if (source == 'direct' && this.cartitems[index]?.childDetails?.DirectReplacement) {
            Reflect.set(this.cartitems[index].childDetails.DirectReplacement, 'isWishlisted', true);
        }

        if (source == 'indirect' && this.cartitems[index]?.childDetails?.AlternativeReplacements) {
            for (let i = 0; i < this.cartitems[index].childDetails.AlternativeReplacements.length; i++) {
                if (this.cartitems[index].childDetails.AlternativeReplacements[i].Id == productid) {
                    Reflect.set(this.cartitems[index].childDetails.AlternativeReplacements[i], 'isWishlisted', true);
                }
            }
        }

        this.scrollToTop();
        this.showMessage(
             productName + ' added to favorites.',
            'success',
            true
        );
    }catch(error){//RWPS-5153 start
             processAndLogJSError(error, this.fileName, this.moduleName, 'getContactInfo');
    }//RWPS-5153 end

    }

    deleteDiscontinuedProductsWithReplacement() {
        deleteDiscontinuedProductsWithReplacement({ cartId: this.cartId })
            .then(result => {
                if (result.success) {
                    this.dispatchEvent(
                        new CustomEvent('replacementmodalclose', {
                            detail: {
                                success: true,
                            }
                        })
                    );
                }
            })
            .catch(error => {
                processAndLogJSError(error, this.fileName, this.moduleName, 'deleteDiscontinuedProductsWithReplacement');//RWPS-5153
            });
    }
}