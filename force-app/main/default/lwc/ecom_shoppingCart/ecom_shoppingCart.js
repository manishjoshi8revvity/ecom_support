import checkRADIdentifierAccount from '@salesforce/apex/ECOM_CartController.checkRADIdentifierAccount';
import createAndAddToList from '@salesforce/apex/ECOM_CartController.createAndAddToList';
import createCart from '@salesforce/apex/ECOM_CartController.createCart';
import deleteCart from '@salesforce/apex/ECOM_CartController.deleteCart';
import deleteCartItem from '@salesforce/apex/ECOM_CartController.deleteCartItem';
import deleteCartItemsById from '@salesforce/apex/ECOM_CartController.deleteCartItemsById';
import getCartItemsWrapped from '@salesforce/apex/ECOM_CartController.getCartItemsWrapped';
import getOrCreateCartSummary from '@salesforce/apex/ECOM_CartController.getCartSummary';
import getCreditCollections from '@salesforce/apex/ECOM_CartController.getCreditCollections';
import getFieldsByObjectName from '@salesforce/apex/ECOM_CartController.getFieldsByObjectName';
import getWishlistDetails from '@salesforce/apex/ECOM_CartController.getWishlistDetails';
import getWishlistSummaries from '@salesforce/apex/ECOM_CartController.getWishlistSummaries';
import removeCoupon from '@salesforce/apex/ECOM_CartController.removeCoupon';
import removeWishlistItem from '@salesforce/apex/ECOM_CartController.removeWishlistItem';
import repriceCart from '@salesforce/apex/ECOM_CartController.repriceCart';
import checkProductMaterialStatus from '@salesforce/apex/ECOM_CartController.checkProductMaterialStatus';
import updateBillToShipToOnCart from '@salesforce/apex/ECOM_CartController.updateBillToShipToOnCart';
import updateCartItem from '@salesforce/apex/ECOM_CartController.updateCartItem';
import deleteShippingCartItem from '@salesforce/apex/ECOM_CartController.deleteShippingCartItem';
import getDataLayerDataByCart from '@salesforce/apex/ECOM_DataLayerController.getDataLayerDataByCart';
//GAr - RWPS-179 - 26 Feb 2024 - begins
import getCMSBaseUrl from '@salesforce/apex/ECOM_CartController.getCMSBaseUrl';
import encodeUrlParams from '@salesforce/apex/ECOM_UserController.getEncyrptedSessionParametersForCMS';
//GAr - RWPS-179 - 26 Feb 2024 - ends
import FORM_FACTOR from '@salesforce/client/formFactor';
import communityId from '@salesforce/community/Id';
import ECOM_DATALAYERCHANNEL from '@salesforce/messageChannel/ecom_DataLayer__c';
import ECOM_MESSAGE from '@salesforce/messageChannel/ecom_MessagingChannel__c';
import COUNTRY_FIELD from '@salesforce/schema/User.Country';
import USER_ID from '@salesforce/user/Id';
import userLocale from '@salesforce/i18n/locale'; //GAr - RWPS-179 - 26 Feb 2024
import { MessageContext, publish } from 'lightning/messageService';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import { LightningElement, api, track, wire } from 'lwc';

//js import
import { getUserConfigData } from 'c/ecom_punchoutUtil';

import sres_ECOM_CartIcons from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import contextApi from 'commerce/contextApi';
//custom labels
import SystemErrorLabel from '@salesforce/label/c.ECOM_TryAgainMessage';
import CreditBlockLabel from '@salesforce/label/c.ECOM_CreditBlock';
import ECOM_105102 from '@salesforce/label/c.ECOM_105102';
import ECOM_105104 from '@salesforce/label/c.ECOM_105104';
import ECOM_105105 from '@salesforce/label/c.ECOM_105105';
import ECOM_105108 from '@salesforce/label/c.ECOM_105108';//RWPS-940
import ECOM_NoRadioactiveLicenseMsg from '@salesforce/label/c.ECOM_NoRadioactiveLicenseMsg';
import ECOM_QuickOrder from '@salesforce/label/c.ECOM_QuickOrder';
import Ecom_Cancel_close from '@salesforce/label/c.Ecom_Cancel_close';
import ECOM_Save from '@salesforce/label/c.ECOM_Save';
import ECOM_Cancel from '@salesforce/label/c.ECOM_Cancel';
import ECOM_Error from '@salesforce/label/c.ECOM_Error';
import ECOM_Close from '@salesforce/label/c.ECOM_Close';
//GAr - RWPS-179 - 26 Feb 2024 - begins
import LBL_URL_PATH_SEPARATOR from '@salesforce/label/c.ECOM_UrlPathSeparator';
import LBL_CMS_BUY_PAGE from '@salesforce/label/c.ECOM_CMSBuyPage';
import LBL_CMS_PARAM_PREFIX from '@salesforce/label/c.ECOM_CMSPunchoutLoginParameter';
import ECOM_PunchoutReLogin from '@salesforce/label/c.ECOM_PunchoutReLogin';
//GAr - RWPS-179 - 26 Feb 2024 - ends
// RWPS-2486 START
import ECOM_Items from '@salesforce/label/c.ECOM_Items';
import ECOM_Cart from '@salesforce/label/c.ECOM_Cart';
// RWPS-2486 END
//RWPS-1548 - START
import getUserInfo from "@salesforce/apex/ECOM_CartController.getUserInfo";
import ECOM_AddAddressError from '@salesforce/label/c.ECOM_AddressesNotRegisteredError';
import ECOM_AddAddreses from '@salesforce/label/c.ECOM_AddAddressWarning';
import ECOM_Addressmissing from '@salesforce/label/c.ECOM_Addressmissing';
import ECOM_Warning from '@salesforce/label/c.ECOM_Warning';
import newAddressesNotRegisteredError from '@salesforce/label/c.ECOM_NewAddressesNotRegisteredError';
//RWPS-1548 - END
import ECOM_AddOrSelectBillingShipping from '@salesforce/label/c.ECOM_AddOrSelectBillingShipping';//RWPS-3816
import ECOM_DisabledAddressError from '@salesforce/label/c.ECOM_DisabledAddressError';//RWPS-3816
import {processAndLogJSError,getCookieByName} from 'c/ecom_util'; // RWPS-5153, RWPS-7266
import logFieldError from '@salesforce/apex/ECOM_Util.logFieldError';//RWPS-5153

// Event name constants
const CART_CHANGED_EVT = 'cartchanged';

const NAVIGATE_TO_PLP = 'PLP';
const CMS_NAVIGATION = 'CMSNavigation';

// Locked Cart Status
const LOCKED_CART_STATUSES = new Set(['Processing', 'Checkout']);
export default class Ecom_shoppingCart extends NavigationMixin(LightningElement) {
    labels = {
        ECOM_QuickOrder,
        ECOM_NoRadioactiveLicenseMsg,
        ECOM_Cancel,
        ECOM_Save,
        Ecom_Cancel_close,
        ECOM_Error,
        ECOM_Close,
        ECOM_105105,
        //GAr - RWPS-179 - 26 Feb 2024 - begins
        LBL_URL_PATH_SEPARATOR,
        LBL_CMS_BUY_PAGE,
        LBL_CMS_PARAM_PREFIX,
        ECOM_PunchoutReLogin,
        //GAr - RWPS-179 - 26 Feb 2024 - ends
        ECOM_Close, //RWPS-1548 - START
        ECOM_AddAddreses,
        ECOM_AddAddressError,
        ECOM_Addressmissing,
        newAddressesNotRegisteredError,
        ECOM_Warning, //RWPS-1548 - END
        ECOM_AddOrSelectBillingShipping, //RWPS-3816
        ECOM_DisabledAddressError //RWPS-3816
    };
    @api
    cartId;
    @api
    recordId;
    @api isCartChanged;
    @api cartButtonDisabled;
    @api
    fieldsToShow;
    @api
    showSpinner = false;
    isComponentLoaded = false;
    isRADAccount = false;
    isRADProductFound = false;
    @track
    isPromoCodeRemoved = false;
    isRADModalOpen = false;
    showRADWarning = false;
    showPrompt = false;
    isPromoApplied = false;
    isCartPageErrorPushedToDataLayer = false;
    promptMsg;
    error1382 = false;
    error1382msg;
    isAnyError = false;
    removedPromocode;
    productIdsToRemove = [];
    productList = [];
    creditCollections;
    shippingDates;
    cartSalesStatus;
    subscription = null;
    freeItemMap; //RWPS-3811
    @track mobile = '';
    timer;
    message;
    type;
    show;
    showNonSellableMessage;//RWPS-2786

    isAddressError = false; // RWPS-415 8 Apr 2024 Added a check for address error

    /**VRa: Punchout Changes | 17 Jan 2024 - Begin */
    //Booleans
    isViewQuickOrder = true;
    /**VRa: Punchout Changes | 17 Jan 2024 - End */

    isPunchoutUser = false; //GAr - RWPS-150 - 14 Feb 2024
    showLoginPopup = false; //GAr - RWPS-179 - 26 Feb 2024
    showNoBillingShippingPrompt = false;//RWPS-1548
    showDisabledERPAddressPrompt = false; //RWPS-3816
    @track
    timeSpan = 0; //8th Nov

    qtyLimitExceededList = [];
    @track userCountry;
    _isCartDisabled;
    @track bodyScroll = 'body slds-align_absolute-center slds-p-right_medium';

    label = {
        SystemErrorLabel,
        CreditBlockLabel,
        ECOM_105102,
        ECOM_105104,
        ECOM_105108, //RWPS-940
        ECOM_Items, //RWPS-2486 START
        ECOM_Cart //RWPS-2486 END
    };

    get isCartDisabled() {
        return this._isCartDisabled;
    }

    get cardFieldLabelMap() {
        return this._cardFieldLabelMap;
    }
    set cardFieldLabelMap(val) {
        this._cardFieldLabelMap = val;
    }
    fieldLabelMap;
    _cardFieldLabelMap;
    productObject = 'Product2';
    moduleName = 'CreditCollectionsContactInfo';
    cartSummary;
    wishListSummary;
    wishListdetails = {};
    // totalSaving = 0;
    totalSaving;
    tariffSurchargeTotal;//RWPS-3026
    totalQty;
    appliedPromotion;
    isPromoCodeApply = false;
    isViewCartAdded = false;
    @track shoppingCartBoxCSS = '';
    //isComponentLoaded = false;
    couponCode = '';
    productidToCartItemsMap = [];
    @api
    images = {
        cartimg: sres_ECOM_CartIcons + '/img/bag-line.png',
        deleteimg: sres_ECOM_CartIcons + '/img/delete-icon.svg',
        quickorderimg: sres_ECOM_CartIcons + '/img/quick-order.svg',
        favoriteimg: sres_ECOM_CartIcons + '/img/heart-line.png',
        helpimg: sres_ECOM_CartIcons + '/img/help-icon.png',
        termsimg: sres_ECOM_CartIcons + '/img/pencil-line.png',
        warning: sres_ECOM_CartIcons + '/img/warning.svg', //RWPS-1548
        close: sres_ECOM_CartIcons + '/img/close.svg' //RWPS-1548
    }
    @api
    effectiveAccountId;
    @wire(CurrentPageReference)
    pageRef;
    _cartItemCount = 0;
    defaultWishListId;
    cartItems;
    productFields;
    productSalesStatus;
    sortOptions = [
        { value: 'CreatedDateDesc', label: this.labels.CreatedDateDesc },
        { value: 'CreatedDateAsc', label: this.labels.CreatedDateAsc },
        { value: 'NameAsc', label: this.labels.NameAsc },
        { value: 'NameDesc', label: this.labels.NameDesc }
    ];
    pageParam = null;
    sortParam = 'CreatedDateDesc';
    isCartClosed = false;
    currencyCode;
    //RWPS-622
    isLargePackOrder = false;
    errorLogFieldMap = {};//RWPS-5153
    get isCartEmpty() {
        // If the items are an empty array (not undefined or null), we know we're empty.
        return Array.isArray(this.cartItems) && this.cartItems.length === 0;
    }

    device = {
        isMobile: FORM_FACTOR === 'Small',
        isDesktop: FORM_FACTOR === 'Large',
        isTablet: FORM_FACTOR === 'Medium'
    }

    loadBasedOnDeviceType() {
        if (this.device.isMobile) {
            this.mobile = true;
            this.shoppingCartBoxCSS = 'slds-col slds-small-size_1-of-1 slds-large-size_4-of-12 slds-p-left_medium';
        } else {
            this.mobile = false;
            this.shoppingCartBoxCSS = 'slds-col slds-small-size_1-of-1 slds-large-size_4-of-12';
        }
    }

    @wire(MessageContext)
    messageContext;
    message;
    fileName ='ecom_shoppingCart';//RWPS-5153
    module ='ECOM_CartService';//RWPS-5153

    /**
     * The labels used in the template.
     * To support localization, these should be stored as custom labels.
     *
     * To import labels in an LWC use the @salesforce/label scoped module.
     * https://developer.salesforce.com/docs/component-library/documentation/en/lwc/create_labels
     *
     * @type {Object}
     * @private
     * @readonly
     */
    get labels() {
        return {
            loadingCartItems: 'Loading Cart Items',
            clearCartButton: 'Clear Cart',
            sortBy: 'Sort By',
            cartHeader: 'Cart',
            emptyCartHeaderLabel: 'Your cart is empty',
            emptyCartBodyLabel:
                'Search or browse products, and add them to your cart. Your selections appear here.',
            closedCartLabel: "The cart that you requested isn't available.",
            CreatedDateDesc: 'Date Added - Newest First',
            CreatedDateAsc: 'Date Added - Oldest First',
            NameAsc: 'Name - A to Z',
            NameDesc: 'Name - Z to A'
        };
    }

    /**
     * Gets the cart header along with the current number of cart items
     *
     * @type {string}
     * @readonly
     * @example
     * 'Cart (3)'
     */
    get cartHeader() {
        return `${this.labels.cartHeader} (${this._cartItemCount})`;
    }

    get cartItemCount() {
        return this._cartItemCount;
    }
    /**
     * Gets whether the item list state is indeterminate (e.g. in the process of being determined).
     *
     * @returns {boolean}
     * @readonly
     */
    get isCartItemListIndeterminate() {
        return !Array.isArray(this.cartItems);
    }

    /**
     * Gets the normalized effective account of the user.
     *
     * @type {string}
     * @readonly
     * @private
     */
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

    @wire(getRecord, {
        recordId: USER_ID,
        fields: [COUNTRY_FIELD]
    }) wireuser({
        error,
        data
    }) {
        if (error) {
            this.error = error;
            processAndLogJSError( error, this.fileName, this.module, 'getCountryWiredCall');//RWPS-5153
        } else if (data) {
            this.userCountry = data.fields.Country.value;
        }
    }

    handleRepriceCart() {
        this.repriceCurrentCart();
    }

    getUpdatedDates() {
        // this.cartButtonDisabled = true;
        this.updateCartItems();
    }
    // this method mark isCartChange to True if any modification done in the Cart
    handleCartChangeEvent(evt) {
        this.cartButtonDisabled = true;
        this.isCartChanged = true;
    }

    handlePublishMessage() {
        let payLoad = {message: this.totalQty,
            type: 'CartRefresh'
        };
        publish(this.messageContext, ECOM_MESSAGE, payLoad);
    }

    /**
     * This lifecycle hook fires when this component is inserted into the DOM.
     */
    connectedCallback() {
        try {//RWPS-5153
            /**VRa: Punchout Changes | 17 Jan 2024 - Begin */
            let userConfig = getUserConfigData();
            if(userConfig){
                this.isViewQuickOrder = userConfig.viewQuickOrder;
                //GAr - RWPS-150 - 14 Feb 2024 begins
                if(userConfig.isPunchoutUser){
                    this.isPunchoutUser = userConfig.isPunchoutUser;
                }
                //GAr - RWPS-150 - 14 Feb 2024 ends
            }
            /**VRa: Punchout Changes | 17 Jan 2024 - End */

            this.getCartSummary();
            this.getFieldLabels();
            this.getWishlistDetails();
            this.getCreditCollectionsInfo();
            this.loadBasedOnDeviceType();
            this.loadUserDetails();//RWPS-1548

            const result = contextApi.getSessionContext();
            result.then((response) => {
                this.effectiveAccountId = response.effectiveAccountId;
                if (this.effectiveAccountId && this.cartId) {
                    //this.updateCartItems();
                }
            }).catch((error) => {
                processAndLogJSError( error, this.fileName, this.module, 'connectedCallback');//RWPS-5153
            });
            // Initialize 'cartItems' list as soon as the component is inserted in the DOM.
            //this.updateCartItems();
        } catch (error) {//RWPS-5153
            processAndLogJSError( error, this.fileName, this.module, 'connectedCallback');//RWPS-5153
        }
    }
    disconnectedCallback() {
        this.isComponentLoaded = false;
    }

    /**
    * Get a list of field labels from the server via imperative apex call
    */
    getCartSummary() {
        // Call the 'getFieldsByObjectName' apex method imperatively
        getOrCreateCartSummary({
            communityId: communityId,
            effectiveAccountId: this.resolvedEffectiveAccountId,
            activeCartOrId: this.cartId,
        }).then((result) => {
            if (result) {
                this.cartId = result?.cartId;
                if (this.resolvedEffectiveAccountId || result?.accountId && this.cartId) {
                    //this.repriceCurrentCart();
                    setTimeout(() => {
                        this.checkAndUpdateBillToShipToOnCart();
                    }, 3000);
                    this.checkValidProductSalesStatus();
                    this.checkRADAccount();
                    // this.getWishlistSummary();
                    if (!this.isComponentLoaded) {
                        this.isComponentLoaded = true;
                        // this.repriceCurrentCart();
                    }
                }
            }
        }).catch((error) => {
          processAndLogJSError( error, this.fileName, this.module, 'getCartSummary');//RWPS-5153
        });
    }

    checkAndUpdateBillToShipToOnCart() {
        // Call the 'updateBillToShipToOnCart' apex method imperatively
        updateBillToShipToOnCart({
            cartId: this.cartId
        }).then((result) => {
            if (result) {

            }
        }).catch((error) => {
            processAndLogJSError( error, this.fileName, this.module, 'checkAndUpdateBillToShipToOnCart');//RWPS-5153
        });
    }

    getWishlistDetails() {
        // Call the 'getFieldsByObjectName' apex method imperatively
        getWishlistDetails().then((result) => {
            let wishListResult = result?.length > 0 ? result[0] : null;
            let wishListItems = wishListResult?.wishListModels[0]?.wishListItems || [];
            let productToWishlistObj = {};
            this.defaultWishListId = wishListResult?.wishListModels[0]?.wishListId || '';
            for (let i = 0; i < wishListItems.length; i++) {
                productToWishlistObj[wishListItems[i].productId] = wishListItems[i];
            }
            this.wishListdetails = productToWishlistObj;
        }).catch((error) => {
            processAndLogJSError( error, this.fileName, this.module, 'getWishlistDetails');//RWPS-5153
        });
    }

    /**
     * Get a list of field labels from the server via imperative apex call
     */
    getFieldLabels() {
        // Call the 'getFieldsByObjectName' apex method imperatively
        getFieldsByObjectName({
            objectName: this.productObject
        }).then((result) => {
            this.fieldLabelMap = result;
            this.fieldsToShow += ',Dangerous_Goods_Indicator_Profile__c,DisplayUrl,ECOM_Product_Media_URI__c,Product_Display_Name__c';//RWPS-2270
            let fieldMap = {};
            let fields = this.fieldsToShow?.split(',');
            for (let i = 0; i < fields.length; i++) {
                if (this.fieldLabelMap[fields[i]]) {
                    fieldMap[fields[i]] = this.fieldLabelMap[fields[i]];
                }
            }
            this.cardFieldLabelMap = fieldMap;
        })
            .catch((error) => {
                 processAndLogJSError( error, this.fileName, this.module, 'getFieldLabels');//RWPS-5153
            });
    }

    /**
     * Check if the logged in user has RAD Account from the server via imperative apex call
     */
    checkRADAccount() {
        // Call the 'checkRADIdentifierAccount' apex method imperatively
        checkRADIdentifierAccount({
            cartId: this.cartId
        }).then((result) => {
            this.isRADAccount = result;
        })
            .catch((error) => {
                processAndLogJSError( error, this.fileName, this.module, 'checkRADAccount');//RWPS-5153
            });
    }

    /**
    * Get a list of Credit Collection Emails from the server via imperative apex call
    */
    getCreditCollectionsInfo() {
        // Call the 'getCreditCollections' apex method imperatively
        getCreditCollections({
            moduleName: this.moduleName
        }).then((result) => {
            this.creditCollections = result;
        }).catch((error) => {
             processAndLogJSError( error, this.fileName, this.module, 'getCreditCollectionsInfo');//RWPS-5153
        });

    }

    /**
    * Check valid product material status
    */
    checkValidProductSalesStatus() {
        // Call the 'checkProductMaterialStatus' apex method imperatively
        checkProductMaterialStatus({
            cartId: this.cartId
        }).then((result) => {
            if (result?.success) {
                this.showNonSellableMessage = result?.salesStatus?.messagesSummary?.message;//RWPS-2786
            }
            this.repriceCurrentCart();
        }).catch((error) => {
             processAndLogJSError( error, this.fileName, this.module, 'checkValidProductSalesStatus');//RWPS-5153
        });
    }

    /**
     * Get a list of cart items from the server via imperative apex call
     */
    repriceCurrentCart() {
        this.showSpinner = true;
        repriceCart({
            cartId: this.cartId,
            couponCode: this.couponCode
        }).then((result) => {
            this.isCartChanged = false;
            this.showSpinner = false;
            if (result?.success) {
                this.isUpdateCartItemDeleted = false;//RWPS-3026
                this.updateCartItems();
                setTimeout(() => {
                    this.checkAndUpdateBillToShipToOnCart();
                }, 3000);
                // if(result?.salesStatus?.messagesSummary?.message){
                //     this.showMessage(
                //         result.salesStatus.messagesSummary.message,
                //         'error',
                //         true
                //     );
                // }
                //RWPS-2786-Start
                if (this.showNonSellableMessage !== undefined && this.showNonSellableMessage !== null && this.showNonSellableMessage.length > 0) {
                    this.showMessage(
                        this.showNonSellableMessage,
                        'error',
                        true
                    );
                }
                //RWPS-2786-End
                if (result?.isPromoApplied) {
                    this.isPromoApplied = true;
                    this.showMessage(
                        result?.promoMessage,
                        result?.isValidPromo ? 'success' : 'error',
                        true
                    );
                    if (!result?.isValidPromo) {
                        this.couponCode = '';
                        this.isPromoApplied = false;
                        this.appliedPromotion = '';
                        removeCoupon({
                            cartId: this.cartId
                        }).then((result) => {
                        }).catch((error) => {
                            processAndLogJSError( error, this.fileName, this.module, 'getWishlistDetails');//RWPS-5153
                            console.log(error);
                        });
                    }
                }
                if (result?.osRequest?.product_list) {
                    this.productList = result.osRequest.product_list;
                    this.qtyLimitExceededList = [];
                    for (let i = 0; i < this.productList.length; i++) {
                        if (this.productList[i]?.qtyLimitExceeded) {
                            this.qtyLimitExceededList.push(this.productList[i].part_number);
                        }
                    }
                    if (this.qtyLimitExceededList.length > 0) {
                        this.showMessage(
                            'Maximum quantity allowed for Part Number ' + this.qtyLimitExceededList + ' is 999.',
                            'error',
                            true
                        );
                    }
                }
                if (result?.fromCache) {
                    if (result?.responseWrapper?.error?.errorDetails[0]?.errorCode == 'V1154') {
                        this.promptMsg = this.label.CreditBlockLabel + ' ' + this.creditCollections[this.userCountry];
                        this.prepareDataLayerDataForCartPageError(this.promptMsg);
                        this._isCartDisabled = true;
                        this.showPrompt = true;
                        this.isAnyError = true;
                    }
                    else if (result?.responseWrapper?.error?.errorDetails[0]?.errorCode == 'VP211') {
                        this.promptMsg = this.label.SystemErrorLabel;
                        this.prepareDataLayerDataForCartPageError(this.promptMsg);
                        this._isCartDisabled = true;
                        this.showPrompt = true;
                        this.isAnyError = true;
                    }
                    else if (result?.responseWrapper?.error?.errorDetails[0]?.errorCode == 'V1423') {
                        this.promptMsg = this.label.ECOM_105108;//RWPS-940
                        this.prepareDataLayerDataForCartPageError(this.promptMsg);
                        this._isCartDisabled = true;
                        this.showPrompt = true;
                        this.isAnyError = true;
                    }
                    else if (result?.responseWrapper?.error?.errorDetails[0]?.errorCode == 'V1382') {
                        this.error1382msg = result?.responseWrapper?.error?.errorDetails[0]?.errorMessage;
                        this.error1382 = true;
                        this.promptMsg = this.label.ECOM_105104;
                        this.prepareDataLayerDataForCartPageError(this.promptMsg);
                        this._isCartDisabled = true;
                        this.showPrompt = true;
                        this.isAnyError = true;
                    }
                    else if (result?.responseWrapper?.error?.errorDetails[0]?.errorMessage) {
                        this.promptMsg = result.responseWrapper.error.errorDetails[0].errorMessage;
                        this.prepareDataLayerDataForCartPageError(this.promptMsg);
                        this._isCartDisabled = true;
                        this.showPrompt = true;
                        this.isAnyError = true;
                    }
                }
                else {
                    if (result.responseWrapper?.errorDetails[0]?.errorCode == 'V1154') {
                        this.promptMsg = this.label.CreditBlockLabel + ' ' + this.creditCollections[this.userCountry];
                        this.prepareDataLayerDataForCartPageError(this.promptMsg);
                        this._isCartDisabled = true;
                        this.showPrompt = true;
                        this.isAnyError = true;
                    }
                    else if (result.responseWrapper?.errorDetails[0]?.errorCode == 'VP211') {
                        this.promptMsg = this.label.SystemErrorLabel;
                        this.prepareDataLayerDataForCartPageError(this.promptMsg);
                        this._isCartDisabled = true;
                        this.showPrompt = true;
                        this.isAnyError = true;
                    }
                    else if (result.responseWrapper?.errorDetails[0]?.errorCode == 'V1423') {
                        this.promptMsg = this.label.ECOM_105108;//RWPS-940
                        this.prepareDataLayerDataForCartPageError(this.promptMsg);
                        this._isCartDisabled = true;
                        this.showPrompt = true;
                        this.isAnyError = true;
                    }
                    else if (result.responseWrapper?.errorDetails[0]?.errorCode == 'V1382') {
                        this.error1382msg = result.responseWrapper?.errorDetails[0]?.errorMessage;
                        this.error1382 = true;
                        this.promptMsg = this.label.ECOM_105104;
                        this.prepareDataLayerDataForCartPageError(this.promptMsg);
                        this._isCartDisabled = true;
                        this.showPrompt = true;
                        this.isAnyError = true;
                    }
                    else if (result.responseWrapper?.errorDetails[0]?.errorMessage) {
                        this.promptMsg = result.responseWrapper.errorDetails[0].errorMessage;
                        this.prepareDataLayerDataForCartPageError(this.promptMsg);
                        this._isCartDisabled = true;
                        this.showPrompt = true;
                        this.isAnyError = true;
                    }
                } let isCSR = getCookieByName('apex__IsCSR');//RWPS-7266                
                //RWPS-5938 - Added this.isPunchoutViaWeb == false
                if (this.isPunchoutUser == true && result?.PunchoutCart == false 
                    && this.showPrompt == false && this.isPunchoutViaWeb == false && !isCSR) {//GAr - RWPS-179 - 26 Feb 2024
                    this.showLoginPopup = true;
                }
            } else {
                //disable checkout and all operation
                this._isCartDisabled = true;
                this.showPrompt = true;
                this.isAnyError = true;
                if (result?.responseWrapper) {
                    if (result.responseWrapper?.errorDetails[0]?.errorCode == 'V1154') {
                        this.promptMsg = this.label.CreditBlockLabel + ' ' + this.creditCollections[this.userCountry];
                        this.prepareDataLayerDataForCartPageError(this.promptMsg);
                    }
                    else if (result.responseWrapper?.errorDetails[0]?.errorCode == 'V1423') {
                        this.promptMsg = this.label.ECOM_105108;//RWPS-940
                        this.prepareDataLayerDataForCartPageError(this.promptMsg);
                    }
                    else if (result.responseWrapper?.errorDetails[0]?.errorCode == 'V1382') {
                        this.error1382msg = result.responseWrapper?.errorDetails[0]?.errorMessage;
                        this.error1382 = true;
                        this.promptMsg = this.label.ECOM_105104;
                        this.prepareDataLayerDataForCartPageError(this.promptMsg);
                    }
                    else if (result.responseWrapper?.errorDetails[0]?.errorMessage) {
                        this.promptMsg = result.responseWrapper.errorDetails[0].errorMessage;
                        this.prepareDataLayerDataForCartPageError(this.promptMsg);
                    }
                }
                else if (result?.responseError) {
                    // RWPS-415 8 Apr 2024 Added a check for address error
                    if (result?.addressError) {
                        this.isAddressError = true;
                        //RWPS-1548 start

                        if (result?.NoBillingShipping) {
                            this.showPrompt = false;
                            this.showNoBillingShippingPrompt = true;
                        } //RWPS-1548 end
                        //RWPS-3816 start
                        if (result?.DisabledERPAddress) {
                            this.showPrompt = false;
                            this.showDisabledERPAddressPrompt = true;
                        }
                        //RWPS-3816 end
                    }
                    this.promptMsg = result.responseError;
                    this.prepareDataLayerDataForCartPageError(this.promptMsg);
                }
            }
        }).catch((error) => {
             processAndLogJSError( error, this.fileName, this.module, 'repriceCurrentCart');//RWPS-5153
        });
    }

    cartShippingDates;
    cartItemTariffCharge; //RWPS-3026
    cartItemDiscountinuedProducts; //RWPS-2786
    replacementProductsMap;//RWPS-3740
    trainingProductMap;//RWPS-4896
    genericTrainingProductMap;//RWPS-4896
    /**
     * Get a list of cart items from the server via imperative apex call
     */
    updateCartItems() {
        // Call the 'getCartItems' apex method imperatively
        this.showSpinner = true;
        this.showRADWarning = false;
        this.validationDone = false;//RWPS-5153
        getCartItemsWrapped({
            communityId: communityId,
            effectiveAccountId: this.resolvedEffectiveAccountId,
            activeCartOrId: this.cartId,
            productFields: this.fieldsToShow,
            pageParam: this.pageParam,
            sortParam: this.sortParam
        }).then((result) => {
            this.cartItems = result?.connectApi?.cartItems;
            if (this.cartItems.length == 0) {
                this.deleteShippingCharge();
                //RWPS-4393 - Start
                if (this.couponCode != null && this.couponCode != undefined && this.couponCode != '') {
                    this.couponCode = '';
                    this.isPromoApplied = false;
                    this.isPromoCodeRemoved = true;
                    this.timeSpan = 10000;
                    removeCoupon({
                        cartId: this.cartId
                    }).then((result) => { })
                        .catch((error) => {
                            console.error(error);
                            this.showMessage(
                                'Error in removing promo code.',
                                'error',
                                true
                            );
                        });
                    //RWPS-4393 - End
                }
            }
            else {//RWPS-5153 start               
                const supportData = JSON.stringify({ args: {  activeCartOrId: this.cartId} });
                this.errorLogFieldMap = result?.logFieldError;
                this.validateCartItems(supportData);
            }//RWPS-5153 end
            this.cartShippingDates = result?.dates;
            this.cartItemTariffCharge = result?.tariffSurcharge; //RWPS-3026
            this.trainingProductMap = result?.trainingProducts//RWPS-4896
            this.genericTrainingProductMap = result?.genericTrainingProducts//RWPS-4896
            this.cartitemDiscontinuedProducts = result?.discontinuedProducts;//RWPS-2786
            this.cartSalesStatus = result?.salesStatus;
            this.freeItemMap = result?.dataLayer?.freeItemMap; //RWPS-3811
            this.transfromCartItems(this.cartItems);
            // RWPS-3740 START
            if (result.allReplacement) {
                this.replacementProductsMap = JSON.parse(JSON.stringify(result?.allReplacement));
            } else {
                this.replacementProductsMap = {};
            }
            // RWPS-3740 END
            //RWPS-3026 - Start
            if (!this.isUpdateCartItemDeleted) {
                this.cartSummary = result?.connectApi?.cartSummary;
                this.tariffSurchargeTotal = result?.cart?.Total_Tariff_Surcharge__c;//RWPS-3026
                this.isUpdateCartItemDeleted = false;
            }
            //RWPS-3026 - End
            this.totalSaving = result?.cart?.ECOM_Total_Savings__c;
            this.totalQty = this.cartSummary.totalProductCount;
            this.appliedPromotion = result?.cart?.ECOM_Promo_Code__c || '';
            this._cartItemCount = Number(
                result?.connectApi?.cartSummary.uniqueProductCount
            );
            if (result?.cart?.ECOM_Promo_Code__c === undefined) // RWPS-4500
                this.couponCode = '';
            this.currencyCode = result?.connectApi?.cartSummary.currencyIsoCode;
            this.showSpinner = false;
            //RWPS-622
            this.isLargePackOrder = result?.isLargePackOrder || false;
            for (let i = 0; i < this.cartItems.length; i++) {
                this.isRADProductFound = false;
                if (this.cartItems[i].cartItem.productDetails.fields.Dangerous_Goods_Indicator_Profile__c === 'RAD') {
                    this.isRADProductFound = true;
                    break;
                }
            }//GAr - RWPS-150 - 14 Feb 2024 - addded isPunchoutUser condition
            if (this.isRADAccount == false && this.isRADProductFound == true && this.isPunchoutUser == false) {
                this.showRADWarning = true;
            }
            //RWPS-2786 - START
            let discontinueProd = 0;
            if (this.cartitemDiscontinuedProducts && Object.keys(this.cartitemDiscontinuedProducts).length > 0) {
                let keys = Reflect.ownKeys(this.cartitemDiscontinuedProducts);
                keys.forEach(function (key) {
                    if (this.cartitemDiscontinuedProducts[key] == true) {
                        discontinueProd++;
                    }
                }, this);
            }
            if (
                this.cartItems &&
                this.cartItems.length > 0 &&
                this.cartitemDiscontinuedProducts &&
                this.cartItems.length == discontinueProd
            ) {
                this._isCartDisabled = true;
            } else {
                this._isCartDisabled = false;
            }

            //RWPS-2786 - END

            this.handlePublishMessage();
            //Preparing data for add_promo_code event which will be push to DataLayer
            try {
                if (this.isPromoCodeApply == true && result.cart.ECOM_Promo_Code__c != null && result.cart.ECOM_Promo_Code__c != undefined) {
                    this.prepareDataLayerData('add_promo_code', result);
                }
                if (this.isPromoCodeRemoved == true) {
                    //Preparing data for remove_promo_code event which will be push to DataLayer
                    this.prepareDataLayerData('remove_promo_code', result);
                }
            } catch (error) {
                processAndLogJSError( error, this.fileName, this.module, 'updateCartItems-prepareDataLayer');//RWPS-5153
                console.error('Error occured during preparing DataLayer data for add_promo_code event ',error);
            }

        })
            .catch((error) => {
                processAndLogJSError( error, this.fileName, this.module, 'updateCartItems');//RWPS-5153
                this.cartItems = undefined;
                this.showSpinner = false;
            });
    }
    //RWPS-5153 start
    validateCartItems(supportData) {
        if (this.validationDone) {
            return;
        }
        this.validationDone = true;
        this.cartItems.forEach(item => {              
            Object.keys(this.errorLogFieldMap).forEach(fieldName => {
            const value = item.cartItem.productDetails?.fields?.[fieldName];
            if (!value || value.toString().trim() === '') {
                logFieldError({ componentName: this.fileName, module: this.module, methodName: 'getCartItemsWrapped',fieldName: fieldName,fieldValue: value,supportData: supportData
            }).catch(error => {
                    processAndLogJSError( error, this.fileName, this.module, 'validateCartItems');
                });
            }
            })
        });
        
    }//RWPS-5153 end

    // RWPS-632 15 May 2024 - Added a method to delete shipping item
    deleteShippingCharge() {
        deleteShippingCartItem({
            activeCartOrId: this.cartId
        }).then((result) => {

        })
            .catch((error) => {
                processAndLogJSError( error, this.fileName, this.module, 'deleteShippingCharge');//RWPS-5153
            });
    }
    //RWPS-4896 - START
    transfromCartItems(cartItems) {
        try {//RWPS-5153
            this.productidToCartItemsMap = [];
            let productidToCartItemsMapNew = [];
            let productidCartItemsMap = {};
            for (let index = 0; index < cartItems.length; index++) {
                let element = cartItems[index];
                if(this.trainingProductMap && this.trainingProductMap[element?.cartItem?.productId]){
                    element.cartItem['earliestDate'] = '';

                }else{
                     element.cartItem['earliestDate'] = this.cartShippingDates && this.cartShippingDates[element?.cartItem?.cartItemId]?.ECOM_Earliest_Shipping_Date__c || '';
                }
               
                element.cartItem['selectedDate'] = this.cartShippingDates && this.cartShippingDates[element?.cartItem?.cartItemId]?.ECOM_Selected_Shipping_Date__c || '';
                if (productidCartItemsMap[element?.cartItem?.productId]) {
                    let existingItems = productidCartItemsMap[element?.cartItem?.productId];
                    existingItems.push(element.cartItem);
                    productidCartItemsMap[element?.cartItem?.productId] = existingItems;
                } else {

                    productidCartItemsMap[element?.cartItem?.productId] = [element.cartItem];
                }
            }
            for (const key in productidCartItemsMap) {
                if (Object.hasOwnProperty.call(productidCartItemsMap, key)) {
                    let cartItems = productidCartItemsMap[key];
                    if (cartItems.length > 1) {
                        //make sure dates are populated
                         cartItems.sort((a, b) => new Date(a.earliestDate).getTime() - new Date(b.earliestDate).getTime());
                    }
                     productidToCartItemsMapNew.push({ key: key, value: cartItems });
                  
                }
            }
            const cartItemsSorted = this.sortTrainingProduts(productidToCartItemsMapNew);  
            this.productidToCartItemsMap = cartItemsSorted;
        } catch (error) {//RWPS-5153 start
            processAndLogJSError( error, this.fileName, this.module, 'transfromCartItems');
        }//RWPS-5153 end
    }

    sortTrainingProduts(data) {
        return [...data].sort((a, b) => {
            const dateA = a.value[0].earliestDate;
            const dateB = b.value[0].earliestDate;

            if (!dateA && !dateB) return 0;
            if (!dateA) return 1;
            if (!dateB) return -1;

            return new Date(dateA).getTime() - new Date(dateB).getTime();
        });
    }
     //RWPS-4896 - END

    /**
    * Get a wish list  summary
    */
    getWishlistSummary() {
        getWishlistSummaries({
            communityId: communityId,
            effectiveAccountId: this.resolvedEffectiveAccountId,
        }).then((result) => {
            this.wishListSummary = result
        })
            .catch((error) => {
                processAndLogJSError( error, this.fileName, this.module, 'getWishlistSummary');//RWPS-5153
                this.wishListSummary = undefined;
            });
    }

    /**
     * Ceate wish list and add product to a wish list.
     */
    handleAddToWishlist(event) {
        // RWPS-4086 start
        if (this.showSpinner) {
            return;
        }
        // RWPS-4086 end

        this.showSpinner = true;
        createAndAddToList({
            communityId: communityId,
            productId: event.detail.productId,
            wishListId: this.defaultWishListId,
            effectiveAccountId: this.resolvedEffectiveAccountId,
        }).then((result) => {
            this.showSpinner = false;
            this.showMessage(
                event.detail.productName + ' added to favorites.',
                'success',
                true
            );
            this.getWishlistDetails();
        })
            .catch((error) => {
                this.showMessage(
                    event.detail.productName + ' not to favorites.',
                    'error',
                    true
                );
                 processAndLogJSError( error, this.fileName, this.module, 'handleAddToWishlist');//RWPS-5153
            });
    }

    handleRemoveFromFavourite(event) {
        // RWPS-4086 start
        if (this.showSpinner) {
            return;
        }
        // RWPS-4086 end

        this.showSpinner = true;
        let wishlistItemId = event.detail.wishlistItemId;
        removeWishlistItem({
            wishlistItemId: wishlistItemId
        }).then((result) => {
            this.showSpinner = false;
            this.showMessage(
                'Item removed from favorites successfully.',
                'success',
                true
            );
            this.getWishlistDetails();
        }).catch((error) => {

            this.showMessage(
                this.labels.ECOM_105105,
                'error',
                true
            );
            processAndLogJSError( error, this.fileName, this.module, 'handleRemoveFromFavourite');//RWPS-5153
        });
    }

    /**
     * Handles a "click" event on the sort menu.
     *
     * @param {Event} event the click event
     * @private
     */
    handleChangeSortSelection(event) {
        this.sortParam = event.target.value;
        // After the sort order has changed, we get a refreshed list
        this.updateCartItems();
    }

    /**
     * Helper method to handle updates to cart contents by firing
     *  'cartchanged' - To update the cart badge
     *  'cartitemsupdated' - To notify any listeners for cart item updates (Eg. Cart Totals)
     *
     * As of the Winter 21 release, Lightning Message Service (LMS) is not available in B2B Commerce for Lightning.
     * These samples make use of the [pubsub module](https://github.com/developerforce/pubsub).
     * In the future, when LMS is supported in the B2B Commerce for Lightning, we will update these samples to make use of LMS.
     *
     * @fires CartContents#cartchanged
     * @fires CartContents#cartitemsupdated
     *
     * @private
     */
    handleCartUpdate() {
        // Update Cart Badge
        this.dispatchEvent(
            new CustomEvent(CART_CHANGED_EVT, {
                bubbles: true,
                composed: true
            })
        );
        // Notify any other listeners that the cart items have updated
    }

    /**
     * Handler for the 'quantitychanged' event fired from cartItems component.
     *
     * @param {Event} evt
     *  A 'quanitychanged' event fire from the Cart Items component
     *
     * @private
     */
    handleQuantityChanged(evt) {
        const { cartItemId, quantity } = evt.detail;
        updateCartItem({
            communityId,
            effectiveAccountId: this.effectiveAccountId,
            activeCartOrId: this.cartId,
            cartItemId,
            cartItem: { quantity }
        })
            .then((cartItem) => {
                this.updateCartItemInformation(cartItem);
            })
            .catch((error) => {
                // Handle quantity update error properly
                // For this sample, we can just log the error
                //console.log(e);
                processAndLogJSError( error, this.fileName, this.module, 'handleQuantityChanged');//RWPS-5153
            });
    }
    handleEnableUpdateButton() {
        this.cartButtonDisabled = false;
    }

    /**
     * Handler for the 'singlecartitemdelete' event fired from cartItems component.
     *
     * @param {Event} evt
     *  A 'singlecartitemdelete' event fire from the Cart Items component
     *
     * @private
     */
    handleCartItemDelete(evt) {
        const { cartItemId, productId } = evt.detail;
        // deleteCartItem({
        //     communityId,
        //     effectiveAccountId: this.effectiveAccountId,
        //     activeCartOrId: this.cartId,
        //     cartItemId
        // })
        //     .then(() => {
        //         this.removeCartItem(cartItemId);
        //     })
        //     .catch((e) => {
        //         // Handle cart item delete error properly
        //         // For this sample, we can just log the error
        //         console.log(e);
        //     });
    }

    /**
     * Handler for the 'click' event fired from 'Clear Cart' button
     * We want to delete the current cart, create a new one,
     * and navigate to the newly created cart.
     *
     * @private
     */
    handleClearCartButtonClicked() {
        // Step 1: Delete the current cart
        deleteCart({
            communityId,
            effectiveAccountId: this.effectiveAccountId,
            activeCartOrId: this.cartId
        }).then(() => {
            // Step 2: If the delete operation was successful,
            // set cartItems to undefined and update the cart header
            this.cartItems = undefined;
            this._cartItemCount = 0;
        })
            .then(() => {
                // Step 3: Create a new cart
                return createCart({
                    communityId,
                    effectiveAccountId: this.effectiveAccountId
                });
            })
            .then((result) => {
                // Step 4: If create cart was successful, navigate to the new cart
                this.navigateToCart(result.cartId);
                this.handleCartUpdate();
            })
            .catch((error) => {
                // Handle quantity any errors properly
                // For this sample, we can just log the error
                 processAndLogJSError( error, this.fileName, this.module, 'handleClearCartButtonClicked');//RWPS-5153
            });
    }

    /**
     * Given a cart id, navigate to the record page
     *
     * @private
     * @param{string} cartId - The id of the cart we want to navigate to
     */
    navigateToCart(cartId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: cartId,
                objectApiName: 'WebCart',
                actionName: 'view'
            }
        });
    }

    /**
     * Given a cartItem id, remove it from the current list of cart items.
     *
     * @private
     * @param{string} cartItemId - The id of the cart we want to navigate to
     */
    removeCartItem(cartItemId) {
        const removedItem = (this.cartItems || []).filter(
            (item) => item.cartItem.cartItemId === cartItemId
        )[0];
        const quantityOfRemovedItem = removedItem
            ? removedItem.cartItem.quantity
            : 0;
        const updatedCartItems = (this.cartItems || []).filter(
            (item) => item.cartItem.cartItemId !== cartItemId
        );
        // Update the cartItems with the change
        this.cartItems = updatedCartItems;
        // Update the Cart Header with the new count
        this._cartItemCount -= Number(quantityOfRemovedItem);
        // Update the cart badge and notify any other components interested in this change
        this.handleCartUpdate();
    }

    /**
     * Given a cartItem id, remove it from the current list of cart items.
     *
     * @private
     * @param{CartItem} cartItem - An updated cart item
     */
    updateCartItemInformation(cartItem) {
        // Get the item to update the product quantity correctly.
        let count = 0;
        const updatedCartItems = (this.cartItems || []).map((item) => {
            // Make a copy of the cart item so that we can mutate it
            let updatedItem = { ...item };
            if (updatedItem.cartItem.cartItemId === cartItem.cartItemId) {
                updatedItem.cartItem = cartItem;
            }
            count += Number(updatedItem.cartItem.quantity);
            return updatedItem;
        });
        // Update the cartItems List with the change
        this.cartItems = updatedCartItems;
        // Update the Cart Header with the new count
        this._cartItemCount = count;
        // Update the cart badge and notify any components interested with this change
        this.handleCartUpdate();
    }
    isUpdateCartItemDeleted = false;//RWPS-3026
    handleDeleteItem(event) {
        let cartItemId = event.detail.cartItemId;
        let productId = event.detail.productId;
        this._isCartDisabled = event.detail.cartDisabled;
        deleteCartItem({
            activeCartOrId: this.cartId,
            cartItemId: cartItemId,
            productId: productId
        })
            .then(() => {
                //this.repriceCurrentCart();

                this.handleEnableUpdateButton();
                this.isUpdateCartItemDeleted = true;//RWPS-3026
                this.updateCartItems();
                this.showMessage(
                    event.detail.message,
                    event.detail.type,
                    event.detail.show
                );
            })
            .catch((error) => {
                // Handle cart item delete error properly
                // For this sample, we can just log the error
                 processAndLogJSError( error, this.fileName, this.module, 'handleDeleteItem');//RWPS-5153
            });
        //this.repriceCurrentCart();
        // this.isCartChanged = true;
    }

    showMessage(message, type, show) {
        this.message = message;
        this.type = type;
        this.show = show;
    }
    handleUpdateMessage() {
        this.message = '';
        this.type = '';
        this.show = false;
    }

    showQuickOrder = false;
    handleOpenQuickOrder() {
        this.showQuickOrder = true;
        this.template.querySelector('c-ecom_quick-order')?.openModal();
        this.bodyScroll = 'body-no-overflow slds-align_absolute-center slds-p-right_medium';
    }

    //RWPS-3740 - START
    handleModalClose(event) {

        if (event?.detail?.success) {
            //this.repriceCurrentCart();
            this.checkValidProductSalesStatus();
            this.showSpinner = true;
        }
        this.bodyScroll = 'body slds-align_absolute-center slds-p-right_medium';
    }
    //RWPS-3740 - END
    handleQuickorderClose(event) {
        if (event?.detail?.success) {
            //this.repriceCurrentCart();
            this.checkValidProductSalesStatus();
            this.showSpinner = true;
        }
        this.bodyScroll = 'body slds-align_absolute-center slds-p-right_medium';
    }

    showModal() {
        this.isRADModalOpen = true;
    }
    closeModal() {
        this.isRADModalOpen = false;
    }
    removeRADProduct() {
        deleteCartItemsById({
            cartItemIds: this.productIdsToRemove
        })
            .then((result) => {

                window.location.reload();
            })
            .catch((error) => {
                //console.log(error);
                processAndLogJSError( error, this.fileName, this.module, 'removeRADProduct');//RWPS-5153
            });
        this.isRADModalOpen = false;
    }
    handleApplyCoupon(event) {
        this.isPromoCodeApply = true;
        this.couponCode = event.detail?.couponCode;
        if (this.couponCode) {
            this.repriceCurrentCart();
        }

    }
    handleClosePrompt() {
        this.showPrompt = false;
    }
    handleRemoveAppliedCoupon(event) {
        this.removedPromocode = event.detail.couponCodeApplied;
        this.couponCode = '';
        this.isPromoApplied = false;
        this.isPromoCodeRemoved = true;
        this.timeSpan = 10000;
        removeCoupon({
            cartId: this.cartId
        }).then((result) => {
            this.repriceCurrentCart();
            // RWPS-42 22 Mar 2024
            this.showMessage(
                'Promo code ' + this.removedPromocode + ' has been removed.',
                'success',
                 true
            );
            // this.isCartChanged = true;
        }).catch((error) => {
            this.showMessage(
                'Error in removing promo code.',
                'error',
                true
            );
             processAndLogJSError( error, this.fileName, this.module, 'handleRemoveAppliedCoupon');//RWPS-5153
        });
    }

    promotionDetail(event) {
        let appliedPromotion = event.detail.appliedCoupon;
        let totalSavings = event.detail.savings;
        if (!this.isViewCartAdded) {
            if (!this.isAnyError) {
                this.prepareDataLayerDataForAddtoCart(this.cartSummary, this.cartItems, appliedPromotion, totalSavings);
            }
            this.isViewCartAdded = true;
        }
    }

    handleShopNow() {
        // RWPS-293 21 Mar 2024
        if (this.isPunchoutUser) {
            this.handleBackToCMSBuyPage();
        }
        // RWPS-415 8 Apr 2024 Added a check for address error
        else if (this.isAddressError) {
            let addrStatus = 'selectAddress';
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: '/dashboard?addressStatus=' + addrStatus
                    //url: '/dashboard?accountEdit'
                }
            });
        }
        else {
            let payLoad = {
                message: NAVIGATE_TO_PLP,
                type: CMS_NAVIGATION
            };
            publish(this.messageContext, ECOM_MESSAGE, payLoad);
        }
    }

    //GAr - RWPS-179 26 Feb 2024 begins
    handleBackToCMSBuyPage() {
        this.showSpinner = true;
        getCMSBaseUrl({
            moduleName: 'SiteURL'
        }).then((result) => {
            let locale = userLocale.replace('-', '_');
            for (const key in result) {
                //RWPS-1817
                if (Object.hasOwnProperty.call(result, key) && key === ('Home')) {
                    const element = result[key];
                    let cmsHomeBaseUrl = element;
                    let urlParams = '';
                    encodeUrlParams().then(result => {
                        if (result && result?.success && result?.responseData) {
                            let baseUrl = cmsHomeBaseUrl;
                            //RWPS-1817
                            if (result.locale && result.locale != '' && baseUrl.indexOf(result.locale) == -1) {
                                if (baseUrl.substr(-1) != '/') {
                                    baseUrl += this.labels.LBL_URL_PATH_SEPARATOR;
                                }
                                baseUrl = baseUrl + result.locale;
                            }
                            //RWPS-1817
                            if (baseUrl.substr(-1) != '/') {
                                baseUrl += this.labels.LBL_URL_PATH_SEPARATOR;
                            }
                            urlParams = result.responseData;
                            window.location.href = baseUrl + this.labels.LBL_CMS_BUY_PAGE + this.labels.LBL_CMS_PARAM_PREFIX + urlParams;
                        } else {
                            let payLoad = {
                                message: NAVIGATE_TO_PLP,
                                type: CMS_NAVIGATION
                            };
                            publish(this.messageContext, ECOM_MESSAGE, payLoad);
                        }
                    }).catch(error => {
                        this.showSpinner = false;
                        processAndLogJSError( error, this.fileName, this.module, 'handleBackToCMSBuyPage-encodeUrlParams');//RWPS-5153
                    });
                    break;
                }
            }

        }).catch((error) => {
            processAndLogJSError( error, this.fileName, this.module, 'getWishlistDetails');//RWPS-5153
            this.showSpinner = false;
            console.log(error);
        });
    }
    //GAr - RWPS-179 26 Feb 2024 ends

    //DataLayer regarding changes starts

    prepareDataLayerDataForAddtoCart(cartSummary, cartItems, appliedPromotion, totalSaving) {
        try {//RWPS-5153
            let promoCode = '';
            let saving = '';
            if (appliedPromotion != undefined && appliedPromotion != null) {
                promoCode = appliedPromotion;
                saving = totalSaving;
            }
            let data = {
                'event': 'view_cart',
                'cart': {
                    'total': cartSummary.grandTotalAmount || undefined,
                    'subTotal': cartSummary.totalProductAmount || undefined,
                    'id': cartSummary.cartId || undefined,
                    'shippingAmount': cartSummary.totalChargeAmount || undefined,
                    'tax': cartSummary.totalTaxAmount || undefined,
                    'discountCode': promoCode || undefined,
                    'discountType': promoCode != '' ? 'Promotion' : undefined,
                    'discountAmount': saving || undefined,
                    'items': []
                }
            };
            let items = [];
            getDataLayerDataByCart({ cartId: this.cartId })
                .then(result => {
                    this.productFields = result;
                    for (let i = 0; i < cartItems.length; i++) {
                        let productId = cartItems[i]?.cartItem?.productId;
                        items.push({
                            'name': cartItems[i]?.cartItem?.productDetails?.name || null,
                            'partNumber': [result?.dataLayer[productId]?.partNumber || undefined],
                            'paccode': result?.dataLayer[productId]?.paccode + '-' + result?.dataLayer[productId]?.igorDescription || undefined,
                            'businessUnit': result?.dataLayer[productId]?.superBussinessUnit + '-' + result?.dataLayer[productId]?.subBussinessUnit || undefined,
                            'portfolioLevel2': result?.dataLayer[productId]?.portfolioLevel2 || undefined,
                            'productLine': result?.dataLayer[productId]?.productLine + '-' + result?.dataLayer[productId]?.productLineName || undefined,
                            'productClass': result?.dataLayer[productId]?.productClass || undefined,
                            'productBrand': result?.dataLayer[productId]?.productBrand || undefined,
                            'sapStatus': result?.productSalesStatus[productId] || undefined,
                            'hasImage': cartItems[i]?.cartItem?.productDetails?.thumbnailImage?.url ? true : false,
                            'quantity': cartItems[i].cartItem?.quantity || undefined,
                            'price': cartItems[i].cartItem?.salesPrice || undefined,
                            'listPrice': cartItems[i].cartItem?.listPrice || undefined,
                            'currency': cartItems[i].cartItem?.currencyIsoCode || undefined,
                            'freeItemParent': cartItems[i].cartItem?.freeItemParent || undefined //RWPS-3811
                        });
                    }
                    data['cart']['items'] = items;
                    this.handlePublishMsg(data);
                })
                .catch(error => {
                     processAndLogJSError( error, this.fileName, this.module, 'prepareDataLayerDataForAddtoCart');//RWPS-5153
                });
        } catch (error) {//RWPS-5153
             processAndLogJSError( error, this.fileName, this.module, 'prepareDataLayerDataForAddtoCart');
        }//RWPS-5153 end
    }

    prepareDataLayerData(eventName, result) {
        try {//RWPS-5153
            let data =  {
                'event': eventName,
                'cart': {
                    'total': result.cart.GrandTotalAmount || undefined,
                    'subTotal': result.cart.TotalProductAmount || undefined,
                    'id': result.cart.Id || undefined,
                    'shippingAmount': result.cart.TotalChargeAmount || undefined,
                    'tax': result.cart.TotalTaxAmount || undefined,
                    'discountCode': this.appliedPromotion || undefined,
                    'discountType': result?.cart?.ECOM_Promo_Code__c ? 'promotion' : undefined,
                    'discountAmount': result?.cart?.ECOM_Total_Savings__c || undefined,
                    'items': []
                }

            };
            if (eventName == 'remove_promo_code') {
                data['cart']['discountCode'] = this.removedPromocode || undefined;
            }
            let items = [];

            getDataLayerDataByCart({ cartId: this.cartId })
                .then(result => {
                    this.productFields = result;

                    let cartItems = this.cartItems;
                    for (let i = 0; i < cartItems.length; i++) {
                        let productId = cartItems[i]?.cartItem?.productId;
                        items.push({
                            'name': cartItems[i]?.cartItem?.productDetails?.name,
                            'partNumber': this.productFields?.dataLayer[productId]?.partNumber || undefined,
                            'paccode': this.productFields?.dataLayer[productId]?.paccode + '-' + this.productFields?.dataLayer[productId]?.igorDescription || undefined,
                            'businessUnit': result?.dataLayer[productId].superBussinessUnit + '-' + result?.dataLayer[productId].subBussinessUnit || undefined,
                            'portfolioLevel2': this.productFields?.dataLayer[productId].portfolioLevel2 || undefined,
                            'productLine': this.productFields?.dataLayer[productId].productLine + '-' + this.productFields?.dataLayer[productId]?.productLineName || undefined,
                            'productClass': this.productFields?.dataLayer[productId].productClass || undefined,
                            'productBrand': this.productFields?.dataLayer[productId].productBrand || undefined,
                            'sapStatus': result?.productSalesStatus[productId] || undefined,
                            'hasImage': cartItems[i]?.cartItem?.productDetails?.thumbnailImage?.url ? true : false,
                            'quantity': cartItems[i].cartItem?.quantity || undefined,
                            'price': cartItems[i].cartItem?.salesPrice || undefined,
                            'listPrice': cartItems[i].cartItem?.listPrice || undefined,
                            'currency': cartItems[i].cartItem?.currencyIsoCode || undefined,
                            'freeItemParent': cartItems[i].cartItem?.freeItemParent || undefined    //RWPS-3811
                        });
                    }
                    data['cart']['items'] = items;
                    this.handlePublishMsg(data);
                })//RWPS-5153 start
                .catch(error =>  processAndLogJSError( error, this.fileName, this.module, 'getWishlistDetails'));
                } catch (error) {
                    processAndLogJSError( error, this.fileName, this.module, 'getWishlistDetails');
                }//RWPS-5153 end
    }

    prepareDataLayerDataForCartPageError(errorMessage) {
        try {
            let data = {
                event: 'cart_page_error',
                'error message': errorMessage
            };
            this.handlePublishMsg(data);
        } catch (error) {//RWPS-5153
             processAndLogJSError( error, this.fileName, this.module, 'prepareDataLayerDataForCartPageError');//RWPS-5153
        }
    }

    handlePublishMsg(data) {
        try {//RWPS-5153
            let payLoad = {
                data: data,
                type: 'DataLayer',
                page: 'cart'
            };
            publish(this.messageContext, ECOM_DATALAYERCHANNEL, payLoad);
        } catch (error) {//RWPS-5153 start
             processAndLogJSError( error, this.fileName, this.module, 'handlePublishMsg');
        }//RWPS-5153 end
    }

    handlegtmEvent(event) {
        try {//RWPS-5153
            let data = event.detail?.data;
            let item = data.items[0];
            let productId = event.detail?.productId;
            item['paccode'] = this.productFields?.dataLayer[productId]?.paccode + '-' + this.productFields?.dataLayer[productId]?.igorDescription || undefined;
            item['businessUnit'] = this.productFields?.dataLayer[productId]?.superBussinessUnit + '-' + this.productFields?.dataLayer[productId]?.subBussinessUnit || undefined;
            item['portfolioLevel2'] = this.productFields?.dataLayer[productId]?.portfolioLevel2 || undefined;
            item['productLine'] = this.productFields?.dataLayer[productId]?.productLine + '-' + this.productFields?.dataLayer[productId]?.productLineName || undefined;
            item['productClass'] = this.productFields?.dataLayer[productId]?.productClass || undefined;
            item['productBrand'] = this.productFields?.dataLayer[productId]?.productBrand || undefined;
            item['sapStatus'] = this.productFields?.productSalesStatus[productId] || undefined;
            data.items[0] = item;
            let payLoad = {
                data: data,
                type: 'DataLayer',
                page: 'cart'
            };
            publish(this.messageContext, ECOM_DATALAYERCHANNEL, payLoad);

        } catch (error) {//RWPS-5153start
             processAndLogJSError( error, this.fileName, this.module, 'handlegtmEvent');
        }//RWPS-5153 end
    }
    handleaddresserrorEvent(event) {
        try {//RWPS-5153
            if (this.isCartPageErrorPushedToDataLayer == false) {
                this.prepareDataLayerDataForCartPageError(event.detail.message);
                this.isCartPageErrorPushedToDataLayer = true;
            }
        } catch (error) {//RWPS-5153 start
            processAndLogJSError( error, this.fileName, this.module, 'handleaddresserrorEvent');
        }//RWPS-5153 end
    }

    //DataLayer regarding changes ends

    handleCartItemRemoveClicked(event) {
        try {//RWPS-5153
            this.cartButtonDisabled = event.detail.updatePriceDisabled;
            this._isCartDisabled = event.detail.updatePriceDisabled;
        } catch (error) {//RWPS-5153 start
            processAndLogJSError( error, this.fileName, this.module, 'handleCartItemRemoveClicked');
        }//RWPS-5153 end
    }

    // Add  delay in message show as form submit is happenig RWPS-1141
    handlePunchoutCheckout(event) {
        try {//RWPS-5153
            let comRef = this;
            setTimeout(() => {
                comRef.showLoginPopup = true;
                comRef.showSpinner = false;
                window.location.reload();
            }, 6000);
        } catch (error) {//RWPS-5153  start
            processAndLogJSError( error, this.fileName, this.module, 'handlePunchoutCheckout');//RWPS-5153
        }//RWPS-5153 end 
    }
    //RWPS-1548 start
    handleCloseModal() {
        this.showNoBillingShippingPrompt = false;
    }

    handleCloseDisabledERPAddressModal() { //RWPS-3816
        this.showDisabledERPAddressPrompt = false;
    }

    loadUserDetails() {
        getUserInfo()
            .then((result) => {
                if (result.status == 'SUCCESS') {
                    this.userRecord = result.user;
                }
            })
            .catch((error) => {
                this.userRecord = undefined;
                this.error = error;
                processAndLogJSError( error, this.fileName, this.module, 'loadUserDetails');//RWPS-5153
                console.error('ecom_shoppingcart- Error retrieving user details', error);
            });
    }

    //RWPS-3816 Start
    handleAddressNavigation() {
        try {//RWPS-5153
            let addrStatus = 'selectAddress';

            if (this.userRecord.Contact.ECOM_AddressRegistration__c === 'Populate ST & BT'
                && this.userRecord.Contact.ECOM_RegistrationPattern__c === 'No Match') {
                addrStatus = 'addAddress';
            }

            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: '/dashboard?addressStatus=' + addrStatus
                }
            });
        } catch (error) {//RWPS-5153 start
            processAndLogJSError( error, this.fileName, this.module, 'handleAddressNavigation');
        }//RWPS-5153 end
    }
    //RWPS-3816 End

    closeAddressErrorModal() {
        this.showNoBillingShippingPrompt = false;
        this.handleAddressNavigation(); //RWPS-3816
    }
    //RWPS-1548 end

    closeDisabledERPAddressModal() { //RWPS-3816
        this.showDisabledERPAddressPrompt = false;
        this.handleAddressNavigation();
    }

}