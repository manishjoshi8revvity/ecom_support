import { LightningElement, api, track, wire } from 'lwc';
//import fetchCartSummary from '@salesforce/apex/ECOM_CartController.getCartSummary';//VRa: exception issue fix : 16 Feb 2024
import fetchCartSummary from '@salesforce/apex/ECOM_CartController.getUniqueProductCount';//VRa: exception issue fix : 16 Feb 2024
import getOneTrustInfo from '@salesforce/apex/ECOM_Util.getOneTrustInfo';
import fetchUserNavigationConfig from '@salesforce/apex/ECOM_UserController.getUserNavigationConfig';
import communityId from "@salesforce/community/Id";
import siteId from "@salesforce/site/Id";
import basePath from '@salesforce/community/basePath';
import ECOM_DATALAYERCHANNEL from '@salesforce/messageChannel/ecom_DataLayer__c';
import ECOM_MESSAGE from '@salesforce/messageChannel/ecom_MessagingChannel__c';
import ssrc_ECOM_Theme from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import FirstName from '@salesforce/schema/User.FirstName';
import LastName from '@salesforce/schema/User.LastName';
import USER_ID from "@salesforce/user/Id";
import isGuest from '@salesforce/user/isGuest';
import { CartSummaryAdapter } from 'commerce/cartApi';
import { MessageContext, subscribe, publish } from 'lightning/messageService';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation'; //RWPS-5938
import { loadScript } from 'lightning/platformResourceLoader';
import { getRecord } from 'lightning/uiRecordApi';
import Dealer_Type__c from '@salesforce/schema/User.Contact.Default_Ship_to_ERP_Address__r.Master_Address__r.Dealer_Type__c'; //RWPS-4759
import getApprovalCount  from '@salesforce/apex/ECOM_OrderController.getApprovalCount';

//jsUtils
import {setToSessionStorage, getFromSessionStorage, parseJSON, stringifyJSON, parseJSONWOStringify, SYSTEM_LABELS, removeFromSessionStorage} from 'c/ecom_punchoutUtil';
import {setToLocalStorage, getFromLocalStorage, removeFromLocalStorage, logoutUserAndRedirect, redirectUserIfLocaleNotPresent} from 'c/ecom_util';


//custom labels
import getCMSBaseUrl from '@salesforce/apex/ECOM_CartController.getCMSBaseUrl';
import FORM_FACTOR from '@salesforce/client/formFactor';
import userLocale from '@salesforce/i18n/locale';
import ECOM_LogOutHeader from '@salesforce/label/c.ECOM_LogOutHeader';
import ECOM_MyAccount from '@salesforce/label/c.ECOM_MyAccount';
import ECOM_MyAccountHref from '@salesforce/label/c.ECOM_MyAccountHref';
import webStoreUser from '@salesforce/label/c.ECOM_Usertype_WebstoreUser';


//VRa - punchout Changes | 17 Jan 2024 - begin
//labels
import LBL_CMS_PARAM_PREFIX  from '@salesforce/label/c.ECOM_CMSPunchoutLoginParameter';
import LBL_CMS_BUY_PAGE  from '@salesforce/label/c.ECOM_CMSBuyPage';
import LBL_CMS_SHOP_PAGE from '@salesforce/label/c.ECOM_CMSShopPage'
import LBL_URL_PATH_SEPARATOR from '@salesforce/label/c.ECOM_UrlPathSeparator';
import ECOM_140004  from '@salesforce/label/c.ECOM_140004';
import ECOM_LBL_CMSUSERLOGINPARAMETER from '@salesforce/label/c.ECOM_CMSUserLoginParameter';
import ECOM_LBL_COMMUNITYLOCALES from '@salesforce/label/c.ECOM_CommunityLocales';
//apex
import encodeUrlParams from '@salesforce/apex/ECOM_UserController.getEncyrptedSessionParametersForCMS';
import encodeWebUserParams from '@salesforce/apex/ECOM_UserController.getCMSRedirectDataMap';
import getHomeUrl from '@salesforce/apex/ECOM_CustomLoginController.getCMSUrl';
//VRa - punchout Changes | 17 Jan 2024 - end

//VRa - Country switch: begin | 07 Jun 2024
import fetchCountrySwitcherConfig from '@salesforce/apex/ECOM_CustomLoginController.fetchStorefrontConfigByModule';

//labels
import ECOM_LBL_REVVITYSITESGLOBALLY from '@salesforce/label/c.ECOM_RevvitySitesGlobally';
import ECOM_LBL_SELECTYOURLOCATION from '@salesforce/label/c.ECOM_SelectYourLocation';
import ECOM_LBL_ECOMMERCENOTAVAILABLE from '@salesforce/label/c.ECOM_EcommerceNotAviableForThisLocation';
import ECOM_LBL_CMSBASEURL from '@salesforce/label/c.ECOM_CMSBaseUrl';
import ECOM_LBL_FORWARDFORLOCALE from '@salesforce/label/c.ECOM_IsForwardForLocale';
import ECOM_LBL_POLICY from '@salesforce/label/c.ECOM_POLICY_URL';//RWPS-3878
import ECOM_LBL_TERM_CONDITION from '@salesforce/label/c.ECOM_TERM_CONDITION';//RWPS-3878
import ECOM_LBL_UTMCONFIG from '@salesforce/label/c.ECOM_UtmCookieConfig';
//VRa - Country switch: end
import ECOM_BackToShop from '@salesforce/label/c.ECOM_BackToShop';// RWPS-3068
import Id from "@salesforce/user/Id";
import LBL_SESSION_TIMEOUT from '@salesforce/label/c.ECOM_Session_Timeout_Cookie'; // RWPS-5938

const NAVIGATE_TO_PLP = 'PLP';
const NAVIGATE_TO_POLICIES = 'Policies';
const NAVIGATE_TO_CONTACTUS = 'ContactUs';
const NAVIGATE_TO_CUSTOMERCARE = 'CustomerCare';
const NAVIGATE_TO_TERMCONDITION= 'Terms & Conditions';
const NAVIGATE_TO_HOME= 'Home';
const NAVIGATE_TO_PDP = 'PDP';
const POLICIES_URL = 'https://www.revvity.com/policies?_gl=1*6a6cwf*_up*MQ..&gclid=Cj0KCQjw06-oBhC6ARIsAGuzdw1bEni0rm4MNoup0IMtGQlvIvsoS52z9BXQldQpWoJrVKqDPNpzodMaAocHEALw_wcB';
const CONSENT_COOKIE_NAME = 'OTC_Token';
const SHOW_CART_MAX_PRODUCT_COUNT= 99;
const SESSION_KEY_USER_TYPE = 'userType';
const COUNTRY_SWITCH_CONFIG = 'ECOM_COUNTRY_SWITCHER_CONFIGURATION';
const PREFERRED_LANGUAGE_PREFIX = 'PreferredLanguage';
const DEFAULT_LOCALE = 'en-US';
const STORED_LOCALE = 'storedLocale';
const RELOAD_PAGE = 'reloadPage';
const RELOAD_URL = 'reloadUrl';
const LOCALE_MAP = 'localeMap';
const IS_LOGOUT = 'isLogout';
const LOGOUT_REDIRECT_URL = 'logoutRedirectURL';
const REDIRECT_LOGGEDIN_USER = 'redirectLoggedInUser';
const LOCALE_CONFIGURATION = 'localeConfiguration';
const ACQUIA_COOKIE = 'acquia_a';
const PTCMS = 'ptcms';
const DEALER_IDENTIFIER = '10. ECOM'; //RWPS-4759
export default class Ecom_header extends NavigationMixin(LightningElement) {
    @api ecomRedirectPages = 'orderDetails,approvalNeeded';
    @api ecomRedirectToDashboardEnabled;
    @api isRedirectLoggedUserEnabled;
    @track isOpen = false;//RWPS-4087

    labels ={
        ECOM_MyAccount,
        ECOM_MyAccountHref,
        ECOM_LogOutHeader,
        webStoreUser,
        LBL_CMS_PARAM_PREFIX,
        LBL_CMS_BUY_PAGE,
        LBL_URL_PATH_SEPARATOR,
        ECOM_140004,
        ECOM_LBL_CMSUSERLOGINPARAMETER,
        ECOM_LBL_REVVITYSITESGLOBALLY,
        ECOM_LBL_SELECTYOURLOCATION,
        ECOM_LBL_ECOMMERCENOTAVAILABLE,
        LBL_CMS_SHOP_PAGE,
        ECOM_LBL_CMSBASEURL,
        ECOM_LBL_COMMUNITYLOCALES,
        ECOM_LBL_FORWARDFORLOCALE,
        ECOM_LBL_UTMCONFIG,
        ECOM_BackToShop, // RWPS-3068
        ECOM_LBL_POLICY,//RWPS-3878
        ECOM_LBL_TERM_CONDITION, //RWPS-3878
        LBL_SESSION_TIMEOUT //RWPS-5938
    };



    /** VRa changes for locale: begin */
    loadSpinner = false;

    displayHeader = false; //RWPS-5617,5618

    async checkPageLoad(){
        await redirectUserIfLocaleNotPresent(window.location.href, this.labels.ECOM_LBL_CMSBASEURL, this.labels.ECOM_LBL_FORWARDFORLOCALE, this.labels.ECOM_LBL_COMMUNITYLOCALES, isGuest);
    }
    constructor(){

        super();
        const queryParameters = window.location.search;
        const urlParams = new URLSearchParams(queryParameters);

        //VRa Jul 26 UTM parameter handling : begin
        //check if login or registration page
        if((window.location.href.indexOf('login') > -1 || window.location.href.indexOf('SelfRegister') > -1) && this.labels.ECOM_LBL_UTMCONFIG){
            const utmParams = JSON.parse(this.labels.ECOM_LBL_UTMCONFIG);

            //loop through and check for params
            for(const [key, value] of Object.entries(utmParams)){
                const paramValue = urlParams.get(key);
                if( paramValue && paramValue != '' && paramValue != undefined && paramValue != null){
                    const cookieValue = this.getCookieValue(value.cookiename);
                    if(!cookieValue || cookieValue == '' || cookieValue == undefined || cookieValue == null){
                        this.setCookieValue(value.cookiename, paramValue);
                    }
                }
            }
        }
        //VRa Jul 26 UTM parameter handling : end

        //Check if user has a locale or is redirected from cms, else redirect back to cms to identify locale and proceed to login
        //redirectUserIfLocaleNotPresent(window.location.href, this.labels.ECOM_LBL_CMSBASEURL, this.labels.ECOM_LBL_FORWARDFORLOCALE, this.labels.ECOM_LBL_COMMUNITYLOCALES, isGuest);
        const ptcms = urlParams.get('ptcms') == undefined || urlParams.get('ptcms') == null ? true : false;
        const localeLabels = JSON.parse(this.labels.ECOM_LBL_COMMUNITYLOCALES);
        const isForwardForLocale = this.labels.ECOM_LBL_FORWARDFORLOCALE == 'true' ? true : false;
        if(isForwardForLocale && ptcms && isGuest && this.labels.ECOM_LBL_COMMUNITYLOCALES != '' && (window.location.href.indexOf('login') || window.location.href.indexOf('SelfRegister') || window.location.href.indexOf('customlogin')) && (urlParams.get('locale') == null ||  urlParams.get('locale') ==undefined)){
            this.loadSpinner = true;
            let isRedirect = true;
            try{
                if(ptcms && ptcms == true){
                    setToLocalStorage(PTCMS, ptcms);
                }
                if(localeLabels){
                    for(const [key, value] of Object.entries(localeLabels)){
                        const prefixEquals = '='+value;
                        const prefixSlash = '/'+value;
                        if(window.location.href.indexOf(prefixEquals) > -1 || window.location.href.indexOf(prefixSlash) > -1){
                            isRedirect = false;
                        }
                    }
                    try{
                            // RWPS-3878 start
                            const currentLocation = window.location;
                            const currentUrl = new URL(currentLocation.href);
                            const startURL = currentUrl.searchParams.get('startURL');

                            const decodedStartPath = startURL ? decodeURIComponent(startURL).split('?')[0] : "";//removes query parameters-/login?ptcms=true->/login
                            const route = decodedStartPath.split('/').pop();//take last part
                            const allowedRoutes = ["login", "ForgotPassword", "SelfRegister"];
                            const isCaseMismatch = allowedRoutes.some(r => r.toLowerCase() === route.toLowerCase() && r !== route);
                            if (startURL && isCaseMismatch) {
                                let decodedStartURL = decodeURIComponent(startURL);
                                    decodedStartURL = decodedStartURL
                                                      .replace(/forgotpassword/i, 'ForgotPassword')
                                                      .replace(/selfregister/i, 'SelfRegister')
                                                      .replace(/login/i, 'login');
                                    const redirectUrl = new URL(decodedStartURL, currentLocation.origin);
                                    window.location.replace(redirectUrl.toString());
                            }
                            else
                            {//RWPS-3878 end
                        const redirectTo = this.labels.ECOM_LBL_CMSBASEURL ;
                        if(window.location.href.indexOf('commeditor') == -1 && isRedirect && isForwardForLocale){
                            this.loadSpinner = false;
                            window.location.href=redirectTo;
                        } else {
                            this.loadSpinner = false;
                        }
                            }//RWPS-3878
                    }catch(error){
                        this.loadSpinner = false;
                    }
                } else {
                    this.loadSpinner = false;
                }
            }catch(error){
                this.loadSpinner = false
            }

        } else {
            this.loadSpinner = false;
        }

        //check if logout
        const isLogout = getFromLocalStorage(IS_LOGOUT);
        if(isLogout){
            removeFromLocalStorage(IS_LOGOUT);
            const logoutCMSUrl = getFromLocalStorage(LOGOUT_REDIRECT_URL);
            removeFromLocalStorage(LOGOUT_REDIRECT_URL);
            window.location.replace(logoutCMSUrl);
        }

        const locale = urlParams.get('locale');
        let startUrl = urlParams.get('startURL');
        let isRedirectLoggedUser = getFromLocalStorage(REDIRECT_LOGGEDIN_USER);
        if((window.location.href.indexOf('builder') == -1 && window.location.href.indexOf('commeditor') == -1) && isGuest && window.location.href.indexOf('login') != -1 && startUrl && startUrl != '' && (startUrl.indexOf('orderDetails') > -1 || startUrl.indexOf('approvalNeeded') > -1 || startUrl.indexOf('cart') > -1)  ){
             //const reloadPageWithRedirectUrl = window.location.origin + '/login?retURL=' + startUrl; //RWPS-1014 - change by VRa Aug 9 2024
             const reloadPageWithRedirectUrl = window.location.origin + '/login?retUrl=' + startUrl; //RWPS-1014 - change by VRa Aug 9 2024
            window.location.replace(reloadPageWithRedirectUrl);
        }
        else if((window.location.href.indexOf('builder') == -1 && window.location.href.indexOf('commeditor') == -1) && !isGuest && startUrl && startUrl != null && startUrl != undefined && startUrl != '' && startUrl?.indexOf('cart') > -1){
            const reloadPageToCart =  window.location.origin + '/cart';
            window.location.replace(reloadPageToCart);
        }
        else if((window.location.href.indexOf('builder') == -1 && window.location.href.indexOf('commeditor') == -1) && !isGuest && (window.location.href.indexOf('SelfRegister') > -1  || window.location.href.indexOf('ForgotPassword') > -1 || window.location.href.indexOf('passwordreset') > -1 || window.location.href.indexOf('registersuccess') > -1 || window.location.href.indexOf('setpassword') > -1) && isRedirectLoggedUser == 'true'){
            const reloadToDashBoard = window.location.origin + '/dashboard?accountEdit';
            window.location.replace(reloadToDashBoard);
        }

        if(locale) {
            setToLocalStorage(STORED_LOCALE, locale);
            this.deleteCookie(PREFERRED_LANGUAGE_PREFIX+siteId);
            // let localeContents = locale.split('-');
            // let sfLocale = (localeContents.length > 1) ? localeContents[1].toLowerCase() + '-' + localeContents[0].toUpperCase() : localeContents[1];
            let localeContents = localeLabels[locale];

            let sfLocale = localeContents;
            if( sfLocale && sfLocale != null && sfLocale != undefined){
                let redirectQueryParam = this.getNewQueryParam('locale');
                let newRedirectPath = this.getPath(sfLocale, redirectQueryParam);
                window.location.replace(newRedirectPath);
                const isReload = getFromLocalStorage(RELOAD_PAGE);
                if(isReload) {
                    const reloadUrl = getFromLocalStorage(RELOAD_URL);
                    removeFromLocalStorage(RELOAD_URL);
                    setToLocalStorage(RELOAD_PAGE, false);
                }
            }


        }
    }
    /** VRa changes for locale: end */

    showOrderApproval = false;
    userId = Id;
    MORE_THAN_NINTYNINE = '99+';
    //@track showUserProfile = false;


    myAccount = basePath+ECOM_MyAccountHref;

    publisherMessage = '';
    subscription = null;
    dataLayerSubscription = null;
    @wire(MessageContext)
    messageContext;

    @track avatarIconCSS='';
    @track cartIconImgCSS='';
    @track backToShopPadding='';
    @track revvLogoCSS='';
    @track rightLogosCSS='';
    @track cartIconCSS = '';
    isGuestUser =  isGuest;
    totalProductCount = 0;
    cartdata;
    redirectCartId = '';
    cartSummary;
    user;
    firstName;
    lastName;
    CurrentUser = USER_ID;
    activeCartOrId;
    cmsHomeBaseUrl = '';
    showCartWithCountPlus = false;
    showCircularBadge = false;
    showCountBadge = false;
    showCapsuleBadge = false;
    // Fix for RWPS-2039
    isLocaleLoaded = false;
    // Fix end
    //VRa: Punchout changes - begin
    //Navigation Data
    navigationData;
    _showPunchoutlogo = true;

    //url parameter
    userType='';

    //system labels
    system_labels = SYSTEM_LABELS;
    //VRa: Punchout changes - end
    //VRa: Locale changes : Begin | 07 Jun 2024
    //text
    currentLocale='';
    orgId = '';
    logoutUrl = '';
    logoutDelay = 1000;

    //array
    countrySwitchConfig = [];
    countryLocaleList = [];

    //Map
    localeKeyMap = new Map();

    //boolean
    isDisplayCountrySwitcherModal = false;
    isDisplayCountrySwitcherButton = false;
    isRenderLogoutDiv = false;
    showSpinner = false;
    //VRa: Locale changes : End
    customerCareModal=false;//Gar Punchout Changes
    @api effectiveAccountId;
    @api
    device = {
        isMobile : FORM_FACTOR==='Small',
        isDesktop : FORM_FACTOR==='Large',
        isTablet :FORM_FACTOR==='Medium'
    }
    isDealer = false; //RWPS-4759
    get modalOpen() {
        let stylingClass = 'body';
        if(this.isDisplayCountrySwitcherModal) {
            stylingClass = stylingClass + ' ecom-modal-open-prevent-scroll';
        }
        return stylingClass;
    }

    get headerBackgroundCss(){
        return window.location.href.indexOf('/order?')!==-1 ? 'background orderConfirmation' : (this.isGuestUser ? 'background bg-guest' : 'background'); // RWPS-2368
    }

    //VRa: punchout changes
    get updatedUserNavigation(){
        return this.navigationData;
    }

    get isPunchoutUser(){
        let isDisplay = false;
        if(this.navigationData && this.navigationData?.isPunchoutUser ){
            isDisplay = true;
        }
        return isDisplay;
    }

    //RWPS-5938
    get isPunchoutViaWeb(){
        let isDisplay = false;
        if(this.navigationData && this.navigationData?.isPunchoutViaWeb) {
            isDisplay = true;
            sessionStorage.clear();
            localStorage.clear();
            const cookieName = this.labels.LBL_SESSION_TIMEOUT;
            let cookieValue = this.getCookie(cookieName);
            const secondsTimestamp = Math.floor(Date.now() / 1000);
            if (!cookieValue) {
                const domainName = '.revvity.com';
                const date = new Date();
                date.setTime(date.getTime() + (1 * 24 * 60 * 60 * 1000));
                const expires = "; expires=" + date.toUTCString();
                document.cookie = `${cookieName}=${secondsTimestamp}${expires}; path=/; domain=${domainName}; SameSite=Lax; Secure`;
            }
        }
        return isDisplay;
    }

    //RWPS-5938
    getCookie(name) {
        const value = `; ${document.cookie}`;
        const parts = value.split(`; ${name}=`);
        if (parts.length === 2) return parts.pop().split(';').shift();
        return null;
    }

    //RWPS-5938
    setCookie(name) {
        let expires = "; expires=Thu, 01 Jan 1970 00:00:00 UTC";
        let value = Math.floor(Date.now() / 1000);
        let domainName = '.revvity.com';
        document.cookie = `${name}=${value}${expires}; path=/; domain=${domainName}; SameSite=Lax; Secure`;
    }

    get punchoutAccountName(){
        let accountName = '';
        if(this.navigationData && this.navigationData?.isPunchoutUser && this.navigationData?.accountName){
            accountName =  this.navigationData.accountName;
        }
        return accountName;
    }

    get isNotDisplayPunchoutOrgLogo(){
        let isDisplay = true;
        if(this.navigationData && this.navigationData?.isPunchoutUser && this.navigationData?.accountLogoUrl){
            isDisplay = false;
        }
        return isDisplay;
    }

    get pageLocale(){
        let currentLabel = '';
        // Fix for RWPS-2039
        if(this.isLocaleLoaded){
            if(this.currentLocale == '' || this.currentLocale == null || this.currentLocale == undefined) {
                currentLabel = 'US';
                this.openCountrySwitcherModal();
            } else {
                currentLabel = this.currentLocale;
            }
        }
        // Fix end
        return currentLabel;
    }

    showPunchoutAccountName(){
        this.punchoutOrgLogo = '';
        this.showPunchoutlogo = false;
    }

    get customHeaderStyling(){
        let headerStylingString = 'body custom-header';
        if(this.navigationData && this.navigationData?.isPunchoutUser ){
            headerStylingString = 'body ecom-header-punchout';
        }
        return headerStylingString;
    }
    _accountLogo = '';
    get punchoutOrgLogo(){
        //RWPS-5938
        if(this.navigationData && this.navigationData?.isPunchoutUser && this.navigationData?.accountLogoUrl && this.showPunchoutlogo && this.navigationData?.isPunchoutViaWeb == false){
            this._accountLogo =  this.navigationData.accountLogoUrl;
            this.showPunchoutlogo = true;
        } else {
            this.showPunchoutlogo = false;
        }
        //RWPS-5938
        return this._accountLogo;
    }
    set punchoutOrgLogo(logo){
        this._accountLogo =  logo;
    }
    get showPunchoutlogo(){
        return this._showPunchoutlogo;
    }
    set showPunchoutlogo(showLogo){
        this._showPunchoutlogo =  showLogo;
    }
    //VRa: punchout changes- end

    get customerCareStyle(){
        let styling = 'rvty-header-nav-myaccount-item gray-border';
        if(this.navigationData && this.navigationData.isPunchoutUser){
            styling = 'rvty-header-nav-myaccount-item ';
        }
        return styling;
    }

    //VRa: punchout changes - begin
    get isRenderForTesUser(){
        let isDisplayForTestUser = false;
        if(this.navigationData){
            isDisplayForTestUser = this.navigationData && this.navigationData.isPunchoutUser && this.navigationData.isStoreTestUser ? false : true
        }
        return isDisplayForTestUser;
    }
    //VRa: punchout changes - end

    /** Changes to fix guest header
    @wire(CartSummaryAdapter, { cartStateOrId: 'current' })
    getCartSummary(result) {
        this.isLoaded = false;
        if (result && result.data && result.data.cartId ) {

            this.cartSummary = result;
            this.totalProductCount = Number(result?.data?.totalProductCount);
            this.redirectCartId = result?.data?.cartId;
            this.showCountBadge = parseInt(this.totalProductCount) > 0?true:false
            this.showCircularBadge = (this.showCountBadge==true && parseInt(this.totalProductCount) < 10)?true:false;
            this.showCapsuleBadge = (this.showCountBadge==true && (this.showCircularBadge==false))?true:false
            this.showCartWithCountPlus = parseInt(this.totalProductCount) > SHOW_CART_MAX_PRODUCT_COUNT? true : false;
        }else if(result && result.error)     {

        }
    } */

    redirectToCartPage() {

        let currentUrl = window.location.href;

        if (!currentUrl.includes('/cart')) {
            window.location.href = '/cart';
        }
    }

    loadBasedOnDeviceType() {
        if (this.device.isTablet) {
            this.avatarIconCSS = "slds-align_right slds-p-left_medium slds-p-top_medium";
            this.cartIconImgCSS = "slds-icon-container align_right slds-p-top_x-small slds-p-right_none slds-p-left--small";
            this.backToShopPadding = "slds-p-top_small";
            this.revvLogoCSS = "slds-text-align_center slds-text-link_reset slds-p-bottom_medium";
            this.rightLogosCSS= "slds-p-top_medium slds-p-left_large";
            this.cartIconCSS = "slds-align_left slds-p-right_none slds-p-top_x-small";

        } else if (this.device.isMobile) {
            this.backToShopPadding = "slds-p-top_xx-small";
            this.revvLogoCSS = "slds-text-align_center slds-text-link_reset slds-p-bottom_xx-small";
            this.avatarIconCSS = "p-left-10 slds-p-top_x-small";
            this.rightLogosCSS = "slds-p-top_medium";
            //this.cartIconCSS = "slds-align_left slds-p-right_none slds-p-left_large slds-p-top_x-small";
            // this.logoCSS = "slds-p-top_xx-small slds-p-left_xx-large";
            this.cartIconCSS = "slds-align_left slds-p-right_none slds-p-left_medium slds-p-top_x-small";
            this.logoCSS = "slds-p-top_xx-small slds-p-left_small";


        } else {
            var width = (window.innerWidth > 0) ? window.innerWidth : screen.width;
            //console.log('WIDTH: '+ width);
            this.avatarIconCSS = "slds-align_right slds-p-top_medium slds-p-left_xx-large";
            this.cartIconImgCSS = "slds-icon-container align_right slds-p-top_x-small slds-p-right_none  slds-p-left_large";
            this.backToShopPadding = "slds-p-top_small";
            this.revvLogoCSS = "slds-text-align_center slds-text-link_reset slds-p-bottom_medium";
            this.rightLogosCSS= "slds-p-top_medium slds-p-left_xx-large";
            this.cartIconCSS = "slds-align_left slds-p-right_xx-large slds-p-top_x-small";

        }
    }

    errorCallback(error, stack){
    }

    #escapeKeyCallback; // RWPS-4086

    connectedCallback() {

        //Added For RWPS-5617,5618 : Started
        const href = (window?.location?.href || '').toLowerCase();
        const hasLoginInUrl = href.includes('login');
        const params = new URLSearchParams(window.location.search);
        const rawQuote = params.get('c__quoteNumber') || params.get('quoteNumber') || '';
        const isExistingCustomer = params.get('c__isExistingCustomer') || params.get('isExistingCustomer') || '';
        const errorConst = params.get('c__errorMessage') || params.get('errorMessage') || '';

        if(rawQuote && hasLoginInUrl && !isExistingCustomer && !errorConst){
            this.displayHeader = false;
        } else {
            this.displayHeader = true;
        }
        //Added For RWPS-5617,5618 : Ended

        window.addEventListener('resize', this.resizeHandler.bind(this));

        if(this.isRedirectLoggedUserEnabled){
            setToLocalStorage(REDIRECT_LOGGEDIN_USER, true);
        } else {
            setToLocalStorage(REDIRECT_LOGGEDIN_USER, false);
        }

        const currentPageUrl = window.location.href;
        if(currentPageUrl.indexOf('login') != -1 || currentPageUrl.indexOf('SelfRegister') != -1  || currentPageUrl.indexOf('registersuccess') != -1 || currentPageUrl.indexOf('passwordreset') != -1 || currentPageUrl.indexOf('ForgotPassword') != -1 || currentPageUrl.indexOf('forgotPasswordRequested') != -1 ){
            this.isDisplayCountrySwitcherButton = true;
        }
         //RWPS-3787 - START
        if((window.location.href.indexOf('builder') == -1
        && window.location.href.indexOf('commeditor') == -1)
        && !this.isGuestUser && (window.location.href.indexOf('SelfRegister') > -1
            || window.location.href.indexOf('ForgotPassword') > -1
            || window.location.href.indexOf('forgotPasswordRequested') > -1
            || window.location.href.indexOf('passwordreset') > -1
            || window.location.href.indexOf('registersuccess') > -1
            || window.location.href.indexOf('setpassword') > -1)
        && this.isRedirectLoggedUserEnabled){
        //RWPS-3787 - END
            const reloadToDashBoard = window.location.origin + '/dashboard?accountEdit';
            window.location.replace(reloadToDashBoard);
        }

        if(this.isGuestUser == false){
            this.checkUrlParameter(); //VRa: punchout changes
            this.areOrderApprovalsNeeded();
        } else {
            //this.checkForLocale();
            this.continuePageLoad();
        }
        this.getCountryConfiguration();
        window.addEventListener("beforeunload", function (e) {
            //removeFromSessionStorage(SESSION_KEY_USER_TYPE);
        });

        /**  Removed By VRa
        this.loadBasedOnDeviceType();
        this.fetchCartDetail();
        this.handleSubscribe();
        document.addEventListener('click', this.hideUserAccount.bind(this));
        this.baseCMSUrl();*/

        //this.subscribeDataLayerEvent();
        //RWPS-4087 start
         this.handleDocumentClick = this.handleDocumentClick.bind(this);
         document.addEventListener('click', this.handleDocumentClick);//RWPS-4087 end

         // RWPS-4086 start
         this.#escapeKeyCallback = this.escapeKeyCallback.bind(this);
         document.addEventListener('keydown', this.#escapeKeyCallback);
         // RWPS-4086 end
    }

    //VRa: punchout changes - begin
    checkUrlParameter(){
        const paramValue = new URL(window.location.href).searchParams.get('userType');
        this.userType = paramValue;
        this.setParametersBasedOnUrl();
    }
    //VRa: punchout changes - end

    //VRa: punchout changes - begin
    //checks if session parameter exists for current user and
    async setParametersBasedOnUrl(){
        try{
            let userConfig = getFromSessionStorage(SESSION_KEY_USER_TYPE);
            if(userConfig === null || userConfig === undefined || userConfig == ''){ //check if session value exists
                await fetchUserNavigationConfig(
                    { userType: this.userType}
                ).then(result => {
                    if(result.success){
                        const navData = result.responseData;
                        this.navigationData = navData;
                        setToSessionStorage(SESSION_KEY_USER_TYPE, stringifyJSON(navData));
                        this.continuePageLoad();
                    }
                }).catch(err => {
                })
            } else {
                this.navigationData = parseJSONWOStringify(userConfig);
                this.continuePageLoad();
            }
        }catch(err){
        }
    }

    errorCallback(error, stack){
    }

    continuePageLoad(){
        this.loadBasedOnDeviceType();
        if(!this.isGuestUser){
            this.fetchCartDetail();
        }
        this.handleSubscribe();
        document.addEventListener('click', this.handleDocumentClick.bind(this));//RWPS-4087
        if(isGuest){
            this.baseCMSUrlForGusetUser();
        } else {
            this.baseCMSUrl();
        }

    }
    //VRa: punchout changes - end

    baseCMSUrl() {
        getCMSBaseUrl({
            moduleName:'SiteURL'
        }).then((result) => {
           this.cmsHomeBaseUrl = result?.Home || '';
        }).catch((error) => {
            //console.log(error);
        });
    }

    disconnectedCallback() {
        document.removeEventListener('click', this.handleDocumentClick);//RWPS-4087
        document.removeEventListener('keydown', this.#escapeKeyCallback); // RWPS-4086
    }

    // RWPS-4086 start
    escapeKeyCallback(event) {
        if (event.key === 'Escape' || event.keyCode === 27) {
            if(this.isDisplayCountrySwitcherModal && this.isLocaleLoaded) {
                this.openCountrySwitcherModal();
            }
        }
    }
    // RWPS-4086 end

    handleSubscribe() {
        if (this.subscription) {
            return;
        }
        this.subscription = subscribe(this.messageContext, ECOM_MESSAGE, (message) => {
            if(message?.type=== 'CartRefresh'){
                this.fetchCartDetail();
            }else if(message?.type=== 'CMSNavigation'){
                this.navigateToCms(message.message,message?.url || '');
            }
        });
    }

    subscribeDataLayerEvent() {
        if (this.dataLayerSubscription) {
            return;
        }
        this.dataLayerSubscription = subscribe(this.messageContext, ECOM_DATALAYERCHANNEL, (message) => {
            if(message?.type=== 'DataLayer'){
                revvityGTM.pushData(message.data);
            }
        });
    }
    @api
        images = {
            cartimg: ssrc_ECOM_Theme + '/img/carticonblack.svg',
            logoimg: ssrc_ECOM_Theme + '/img/revvityheaderLogo.svg',
            nameimg: ssrc_ECOM_Theme + '/img/namecircle.png',
            asimg: ssrc_ECOM_Theme + '/img/AS.png',
            vsvg: ssrc_ECOM_Theme + '/img/vsvg.svg',
            dashboard:ssrc_ECOM_Theme + '/img/dashboard.png',
            logout:ssrc_ECOM_Theme + '/img/logout.png',
            back:ssrc_ECOM_Theme+'/img/back.png',
            activedashboard: ssrc_ECOM_Theme+'/img/activedashboard.png',
            blackcross:ssrc_ECOM_Theme+'/img/blackcross.svg',
            }
        //RWPS-4759 : Added Dealer_Type__c
        @wire(getRecord, {recordId: '$CurrentUser',fields: [FirstName, LastName, Dealer_Type__c]}) userRecord({ error, data }) {
            try{
                if (error) {

                }
                else if (data) {
                    this.isDealer = data?.fields?.Contact?.value?.fields?.Default_Ship_to_ERP_Address__r?.value?.fields?.Master_Address__r?.value?.fields?.Dealer_Type__c.value === DEALER_IDENTIFIER ? true : false ; //RWPS-4759
                    this.user = data;
                    this.firstName = data.fields.FirstName.value;
                    this.lastName = data.fields.LastName.value;
                }
            }catch(error){
            }

        }

        get userInitials() {
            let isCurrentTestUser = false;
            if(this.navigationData){
                isCurrentTestUser = this.navigationData && this.navigationData.isPunchoutUser && this.navigationData.isStoreTestUser ? true : false
                if(isCurrentTestUser){
                    this.firstName = this.system_labels.TEST_USER_FIRSTNAME;
                    this.lastName = this.system_labels.TEST_USER_LASTNAME;
                }
            }
            if (this.firstName && this.lastName) {
                return `${this.firstName.charAt(0)}${this.lastName.charAt(0)}`;
            }
        }

        areOrderApprovalsNeeded()
        {
            getApprovalCount()
            .then(result=>{
                if(result.Success && result.orderCount>0)
                {
                    this.showOrderApproval = true;
                }
                else
                {
                    this.showOrderApproval = false;
                }
            }).catch(error=>{
                this.showOrderApproval = false;

            });
        }


        /* VRa: Code cleaup
        redirectToMyAccount(){
            let myAccountPageUrl= `${basePath}/dashboard?accountEdit`;
            window.location.href=myAccountPageUrl;
        }
        redirectToDashboard(event){
            let myDashboardPageUrl= `${basePath}/dashboard`;
            window.location.href=myDashboardPageUrl;
        }
        redirectToMyProfile(){
            let myProfilePageUrl= `${basePath}/profile-and-settings`;
            window.location.href=myProfilePageUrl;
        }
        redirectToOrders(){
            let ordersPageUrl= `${basePath}/orderHistory`;
            window.location.href=ordersPageUrl;
        }
        redirectToFavorites(){
            let myAccountPageUrl= `${basePath}/favorites`;
            window.location.href=myAccountPageUrl;
        }
        redirectToFrequentlyPurchased(){
            handleRedirect(`${basePath}/frequentylyPurchased`); //VRa: Code cleanup
        }
        redirectToQuickOrder(){
            handleRedirect(`${basePath}/quickorder`);//VRa: Code cleanup

        }
        */

        //VRa: Code cleanup
        handleRedirect(url){
            window.location.href=url;
        }

        navigateToContactUsPage(){
            if(this.navigationData?.isPunchoutUser==true){
                this.customerCareModal=true;
            }
            else{
                this.navigateToCms(NAVIGATE_TO_CONTACTUS,'');
            }
            //RWPS-4087
            this.isOpen = false;
            const profileIcon = this.template.querySelector('[data-id="profileIcon"]');
            profileIcon && profileIcon.focus(); 
            //RWPS-4087
        }

        async fetchCartDetail() {
            fetchCartSummary().then(result => {
                if(result && result.success){
                    this.totalProductCount = Number(result?.responseData);
                    this.redirectCartId = result?.cartId;
                    this.showCountBadge = parseInt(this.totalProductCount) > 0?true:false
                    this.showCircularBadge = (this.showCountBadge==true && parseInt(this.totalProductCount) < 10)?true:false
                    this.showCapsuleBadge = (this.showCountBadge==true && (this.showCircularBadge==false))?true:false
                    this.showCartWithCountPlus = parseInt(this.totalProductCount) > SHOW_CART_MAX_PRODUCT_COUNT? true : false;
                }
            }).catch(e => {

            });
            //VRa: exception issue fix : 16 Feb 2024 - end
        }catch(e) {
            //console.log('error in getting cart', e);
        }

        navigateToCms(pageType,url){
            let baseUrl  =  this.cmsHomeBaseUrl;
            let target = '_self';
            let locale =  this.getCMSLocale();
            // Fix for RWPS-1967
            locale = locale && locale != undefined && locale != null ? locale.replace('us-en','') : '';
            locale = (locale == '/')?'':(locale);
            baseUrl+=locale;
            // Fix end
            switch(pageType){
                case NAVIGATE_TO_PLP:
                    baseUrl+= this.navigationData?.isPunchoutUser ?this.labels.LBL_CMS_BUY_PAGE:this.labels.LBL_CMS_SHOP_PAGE;
                    baseUrl = !this.isGuestUser?this.getEncodedUserParams(baseUrl):baseUrl;//RWPS-3068
                    break;
                case NAVIGATE_TO_POLICIES:
                    baseUrl+=ECOM_LBL_POLICY;//RWPS-3878
                    break;
                case NAVIGATE_TO_CONTACTUS:
                case NAVIGATE_TO_CUSTOMERCARE:
                    // Fix for RWPS-1967
                    baseUrl+='contact-us';
                    // Fix End
                    break;
                case NAVIGATE_TO_TERMCONDITION:
                    baseUrl+=ECOM_LBL_TERM_CONDITION;//RWPS-3878
                    target = '_blank';
                    break;
                case NAVIGATE_TO_PDP:
                    baseUrl+=url;
                    //RWPS-1817 remove double slash for pdp for web user
                    baseUrl = baseUrl.replace(/([^:]\/)\/+/g, "$1");
                    break;
                default:
                    baseUrl;
            }
            window.open(baseUrl,target);
        }
        handleBackToShopping(){
            /**VRa: punchout changes | 17 Jan 2024 - Begin */
            //this.navigateToCms(NAVIGATE_TO_PLP);
            if(this.navigationData && this.navigationData?.isPunchoutUser){
                let urlParams = '';
                encodeUrlParams().then(result => {
                    if(result && result?.success){
                        let baseUrl = result.Home;//this.cmsHomeBaseUrl;
                        //RWPS-1817
                        if(result.locale && result.locale!= '' && baseUrl.indexOf(result.locale)==-1){
                            if (baseUrl.substr(-1) != '/'){
                                baseUrl += this.labels.LBL_URL_PATH_SEPARATOR;
                            }
                            baseUrl = baseUrl +  result.locale;
                        }
                        baseUrl = baseUrl.replace('us-en', '');
                        urlParams = result.responseData;
                       //RWPS-1817 append slash on if needed
                       if (baseUrl.substr(-1) != '/'){
                            baseUrl += this.labels.LBL_URL_PATH_SEPARATOR;
                        }
                        window.location.href = baseUrl + this.labels.LBL_CMS_BUY_PAGE + this.labels.ECOM_LBL_CMSUSERLOGINPARAMETER + urlParams;//Remove after DEV
                    } else {
                       // this.navigateToCms(NAVIGATE_TO_PLP);
                    }
                }).catch(error => {

                });
                /**VRa: punchout changes | 17 Jan 2024 - End */
            } else {
                this.navigateToCms(NAVIGATE_TO_PLP,'');
            }
        }

        // RWPS-3826 start
        handleBackToShoppingEnter(event){
            if(event.key === 'Enter' || event.keyCode === 13){
                this.handleBackToShopping();
            }
        }
        // RWPS-3826 end

        getEncodedUserParams(baseUrl){
            encodeWebUserParams().then(result => {
                if(result && result.success && result.responseData){

                    let urlParams = result.responseData;
                    let redirectUrl = baseUrl + this.labels.ECOM_LBL_CMSUSERLOGINPARAMETER + urlParams;
                    window.location.replace(redirectUrl);
                } else {
                    //nothing to do. cannot proceed without url params
                }
            }).catch(error => {
            })
        }


        // navigateToCms(pageType){
        //     /**VRa Login Rework changes | 27 May 2024 ECOM-1554 : Begin  */
        //     let baseUrl  =  this.cmsHomeBaseUrl;
        //     let locale =  this.getCMSLocale();
        //     baseUrl+=locale;
        //     if(pageType == NAVIGATE_TO_CONTACTUS || pageType == NAVIGATE_TO_POLICIES){
        //         switch(pageType){
        //             case NAVIGATE_TO_CONTACTUS:
        //                 baseUrl+='/contact-us';
        //                 break;
        //             case NAVIGATE_TO_POLICIES:
        //                 baseUrl=POLICIES_URL;
        //                 break;
        //             default:
        //                 baseUrl;
        //         }
        //         window.open(baseUrl,'_self');
        //     }
        //      /**VRa Login Rework changes | 27 May 2024 ECOM-1554 : End  */
        //      /**VRa Login Rework changes | 27 May 2024 ECOM-1554 : Begin  */
        //     encodeWebUserParams().then(result => {
        //         if(result && result.success && result.responseData){
        //             let baseUrl = result.Home;
        //                 if(result.locale && result.locale!= ''){
        //                     baseUrl = baseUrl +  this.labels.LBL_URL_PATH_SEPARATOR + result.locale;
        //                 }
        //                 let urlParams = result.responseData;
        //                 let redirectUrl = baseUrl + this.labels.LBL_CMS_SHOP_PAGE + this.labels.ECOM_LBL_CMSUSERLOGINPARAMETER + urlParams;
        //                 window.location.replace(redirectUrl);
        //         } else {
        //             //nothing to do. cannot proceed without url params
        //         }
        //     }).catch(error => {
        //     })
        //      /**VRa Login Rework changes | 27 May 2024 ECOM-1554 : End  */
        // }

        handleCMSRedirect(){
            this.navigateToCms(NAVIGATE_TO_HOME);
        }

        redaCookie(name) {
            return document.cookie.split('; ').find(row => row.startsWith(`${name}=`))?.split('=')[1] || '';
          }

        closeCCModal(){
            this.customerCareModal=false;
        }

    handleBackToHomePage(){
        getHomeUrl().then(result => {
            const currentCmsLocale = getFromLocalStorage(STORED_LOCALE);
            if(result && result.success){
                let redirectToPage = result.responseData.Home;
                if(currentCmsLocale && currentCmsLocale != '' && currentCmsLocale != 'us-en'){
                    // Fix for RWPS-2025
                    redirectToPage = redirectToPage + currentCmsLocale + '?ptcms=true' ;
                    // Fix End
                    redirectToPage = redirectToPage.replace('us-en','');
                }
                window.location.replace(redirectToPage);
            }
        }).catch(error => {
        })
    }

    // RWPS-3826 start
    handleBackToHomePageEnter(event){
        if(event.key === 'Enter' || event.keyCode === 13){
            this.handleBackToHomePage();
        }
    }
    // RWPS-3826 end

    baseCMSUrlForGusetUser() {
        getHomeUrl({

        }).then((result) => {
            let locale = userLocale.replace('-','_');
            const urlResult = result.responseData;
            for (const key in urlResult) {
                if ((Object.hasOwnProperty.call(urlResult, key) && key===('Home_'+locale)) || (Object.hasOwnProperty.call(urlResult, key) && key===('Home'))) {
                    const element = urlResult[key];
                    this.cmsHomeBaseUrl = element;
                }
            }
        }).catch((error) => {
            //console.log(error);
        });
    }

    openCountrySwitcherModal(){
        this.isDisplayCountrySwitcherModal = !this.isDisplayCountrySwitcherModal;

        this.resizeHandler();
    }

    // RWPS-3826 start
    handleCountrySwitcherEnter(event){
        if(event.key === 'Enter' || event.keyCode === 13){
            this.openCountrySwitcherModal();
        }
    }
    // RWPS-3826 end

    getCMSLocale(){
        let locale = '';
        let localeConfigsStr = getFromSessionStorage(LOCALE_CONFIGURATION);
        let localeConfigs =JSON.parse(localeConfigsStr);
        let sfLocale = userLocale.replace('-','_');
        locale = localeConfigs[sfLocale]?.cmsLocale;
        // Fix for RWPS-1967
        return locale + '/';
        // Fix end
    }

    getCountryConfiguration(){
        // let localeConfigsStr = getFromSessionStorage(LOCALE_CONFIGURATION);
        // if(localeConfigsStr){
        //     return;
        // }
        if(!this.countrySwitchConfig || this.countrySwitchConfig.length <=0  ){
            fetchCountrySwitcherConfig({
                moduleName: COUNTRY_SWITCH_CONFIG
            }).then(result => {
                if(result && result.success && result.responseData){
                    this.orgId = result.orgId;
                    this.countrySwitchConfig = result.responseData;

                    setToSessionStorage(LOCALE_CONFIGURATION, JSON.stringify(this.countrySwitchConfig));
                    for (const [key, value] of Object.entries(this.countrySwitchConfig)) {
                        if(value && value.cmsLocale){
                            this.localeKeyMap.set(value.cmsLocale, key);
                        }
                        this.countryLocaleList.push(value);
                    }
                    //changes to fix issue with ECOM-3335: Begin VRa 21 Jun 2024
                    try{
                        setToLocalStorage(LOCALE_MAP, this.localeKeyMap);
                        // let cookieName = PREFERRED_LANGUAGE_PREFIX + siteId;
                        // let currentCookie = this.getCookieValue(cookieName);
                        // this.localeKeyMap.forEach((value,key) =>{
                        //     if(value.replace('_','-') == currentCookie){
                        //         this.setCookieValue(cookieName, value.replace('_','-'));
                        //         setToLocalStorage(STORED_LOCALE, key);
                        //     }
                        // })
                    }catch(error){
                    }
                    //changes to fix issue with ECOM-3335: End
                    this.checkForLocale();
                }
            }).catch(error => {
            })
        }
    }



    getCookieValue(cookieName){
        // var match = document.cookie.match(new RegExp('(^| )' + cookieName + '=([^;]+)'));
        // if (match) return match[2];
        const regex = new RegExp(`(^| )${cookieName}=([^;]+)`)
        const match = document.cookie.match(regex)
        if (match) {
            return match[2]
        }
    }

    updateCookieValue(cookieName, value){
        document.cookie = cookieName + '=' + value;
    }

    setCookieValue(cookieName, value) {
        const days = 3;
        var expires = "";
        if (days) {
            var date = new Date();
            date.setTime(date.getTime() + (days*24*60*60*1000));
            expires = "; expires=" + date.toUTCString();
        }
        document.cookie = cookieName + "=" + (value || "")  + expires + "; path=/";
    }

    deleteCookie(cookieName) {
        document.cookie = cookieName +'=; Path=/; Expires=Thu, 01 Jan 1970 00:00:01 GMT;';
    }

    checkForLocale(){
        try{
            //build cookie name
            let cookieName = PREFERRED_LANGUAGE_PREFIX + siteId;
            let cookieValue = DEFAULT_LOCALE;//'en_US';
            //check for locale from localsetting
            let localSettingLocale = getFromLocalStorage(STORED_LOCALE);
            cookieValue = this.getCookieValue(cookieName);

            if(((localSettingLocale && localSettingLocale != '') || (!cookieValue || cookieValue == '' || cookieValue == undefined || cookieValue == null ) || (cookieValue && localSettingLocale && cookieValue != localSettingLocale))){
                cookieValue = this.localeKeyMap.get(localSettingLocale) ? this.localeKeyMap.get(localSettingLocale) : DEFAULT_LOCALE;

                this.setCookieValue(cookieName, cookieValue.replace('_', '-'));
                if(this.countrySwitchConfig[cookieValue]?.countryCode) { //RWPS-3660
                    this.currentLocale = this.countrySwitchConfig[cookieValue].countryCode;
                    // Fix for RWPS-2039
                    this.isLocaleLoaded = true;
                } //RWPS-3660 end

                let isReload = getFromLocalStorage(RELOAD_PAGE);
                //check the current url and remove any different locale
                if((window.location.href.indexOf(cookieValue.replace('_', '-')) == -1 && isReload)  ){
                    //loop through query params and build new url
                        let newRedirectQueryParams = '';
                        const queryParameters = window.location.search;
                        const urlParams = new URLSearchParams(queryParameters);
                        for(const [key, value] of Object.entries(urlParams)) {
                            if(key != 'locale'){
                                if(newRedirectQueryParams.indexOf('?') == -1) {
                                    newRedirectQueryParams = newRedirectQueryParams + '?' + key + '=' + value;
                                } else {
                                    newRedirectQueryParams = newRedirectQueryParams + '&' + key + '=' + value;
                                }
                            }
                        }

                        const urlPathArray = window.location.pathname.split('/');
                        let urlRedirect = window.location.origin;
                        if(urlPathArray && urlPathArray.length > 0){
                            urlRedirect  = urlRedirect + '/' + cookieValue.replace('_', '-') + '/' +urlPathArray[urlPathArray.length - 1] + newRedirectQueryParams;
                            setToLocalStorage(RELOAD_PAGE, true);
                        } else {
                            urlRedirect  = urlRedirect + '/' + cookieValue.replace('_', '-') +  newRedirectQueryParams;
                            setToLocalStorage(RELOAD_PAGE, true);
                        }
                        isReload = getFromLocalStorage(RELOAD_PAGE);
                        if(isReload){
                            removeFromLocalStorage(RELOAD_PAGE);
                            urlRedirect = urlRedirect.indexOf('?') > -1 ? urlRedirect+'&ptcms=true' : urlRedirect+'?ptcms=true';
                            window.location.replace(urlRedirect);
                        }
                }
            }
            cookieValue = this.getCookieValue(cookieName);
            //get cookie
            cookieValue = cookieValue ? cookieValue.replace('-', '_') :  DEFAULT_LOCALE;//'en_US';
            let config = this.countrySwitchConfig[cookieValue];
            //push message
            this.handlePublishCountrySwitch(config);
        }catch(error){
            console.log('error:: ', error);
        }
        //RWPS-3660
        if(this.isGuestUser && window.location.href.indexOf('SelfRegister') > -1 && !this.isLocaleLoaded ) {
            this.openCountrySwitcherModal();
        }
    }

    handleLocaleChange(event){
        let cookieName = PREFERRED_LANGUAGE_PREFIX + siteId;
        let cookieValue;
        let item = JSON.parse(JSON.stringify(event.currentTarget.dataset.key));

        item = this.countrySwitchConfig[item];
        if(item && item != null && item != undefined){
            this.currentLocale = item.countryCode;
            // Fix for RWPS-2039
            this.isLocaleLoaded = true;

            setToLocalStorage(STORED_LOCALE, item.cmsLocale); //RWPS-3926
            // Fix end
            if(this.getCookieValue(cookieName)){
                cookieValue = this.getCookieValue(cookieName);
                if(cookieValue != item.locale) {
                    this.setCookieValue(cookieName, item.locale);
                    //this.setCookieValue(ACQUIA_COOKIE, item.cmsLocale);//VRa change Jul23 - ECOM-3335
                }
            } else {
                this.setCookieValue(cookieName, item.locale);
                //this.setCookieValue(ACQUIA_COOKIE, item.cmsLocale);//VRa change Jul23 - ECOM-3335
            }
            this.handlePublishCountrySwitch(item);
            this.openCountrySwitcherModal();
            const isLoginBlocked = item.isLoginBlocked;
            if(isLoginBlocked){
                // Fix for redirection to login page when locale is not available RWPS-1988
                this.redirectoToLoginUnavailablePage(item?.cmsHome, item?.cmsLocale);
                // End
            } else {
                this.redirectToLocalePage();
            }
        } else {
            this.deleteCookie(cookieName);
        }
    }
   // Fix for redirection to login page when locale is not available RWPS-1988
    redirectoToLoginUnavailablePage(cmsHome, cmsLocale) {
        const cookieName = this.getCookieName();
        this.deleteCookie(cookieName);
        removeFromLocalStorage(STORED_LOCALE);
        removeFromLocalStorage(RELOAD_PAGE);
        removeFromLocalStorage(RELOAD_URL);
        let baseUrl  =  this.cmsHomeBaseUrl;
        const redirectUrl = cmsHome != null? cmsHome: (baseUrl + cmsLocale);
        window.location.replace(redirectUrl);
    }
    // Fix end

    redirectToLocalePage(){
        setToLocalStorage(RELOAD_PAGE, true);
        this.checkForLocale();
    }


    handlePublishCountrySwitch(localeData) {
        let payload = {
            type : "countrySwitch",
            localeData : localeData
        }
        publish(this.messageContext, ECOM_MESSAGE, payload);
    }

    getCookieName(){
        let cookieName = PREFERRED_LANGUAGE_PREFIX + siteId;
        return cookieName;
    }

    handleCustomLogout(event){
        this.showSpinner = true;
        event.preventDefault();
        getHomeUrl().then(result => {
            if(result && result.success){
                //RWPS-5938
                let logoutRedirectionURL = result.responseData.Logout;
                if(this.isPunchoutViaWeb == true) {
                    this.setCookie(this.labels.LBL_SESSION_TIMEOUT);
                }
                this.logoutUrl = window.location.origin + '/secur/logout.jsp';
                logoutUserAndRedirect(this.logoutDelay, this.logoutUrl, logoutRedirectionURL, PREFERRED_LANGUAGE_PREFIX + siteId, STORED_LOCALE);
                //RWPS-5938
            }
        }).catch(error => {
        })
         //RWPS-4087
         this.isOpen = false;
         const profileIcon = this.template.querySelector('[data-id="profileIcon"]');
         profileIcon && profileIcon.focus(); 
         //RWPS-4087
    }

    getNewQueryParam(excludeParam) {
        let newRedirectQueryParams = '';
        const queryParameters = window.location.search;
        let urlParams = new URLSearchParams(queryParameters);
        urlParams.forEach((value, key) => {
            if(key != excludeParam){
                if(newRedirectQueryParams.indexOf('?') == -1) {
                    newRedirectQueryParams = newRedirectQueryParams + '?' + key + '=' + value;
                } else {
                    newRedirectQueryParams = newRedirectQueryParams + '&' + key + '=' + value;
                }
            }
        })

        return newRedirectQueryParams;
    }

    getPath(cookieValue, newRedirectQueryParams){
        const urlPathArray = window.location.pathname.split('/');
        let urlRedirect = window.location.origin;
        if(cookieValue && cookieValue != undefined && cookieValue != null && cookieValue != ''){
            if(urlPathArray && urlPathArray.length > 0 ){
                urlRedirect  = urlRedirect + '/' + cookieValue.replace('_', '-') + '/' +urlPathArray[urlPathArray.length - 1] + newRedirectQueryParams;
            } else {
                urlRedirect  = urlRedirect + '/' + cookieValue.replace('_', '-') +  newRedirectQueryParams;
            }
        } else {
            if(urlPathArray && urlPathArray.length > 0 ){
                urlRedirect  = urlRedirect + '/'  +urlPathArray[urlPathArray.length - 1] + newRedirectQueryParams;
            } else {
                urlRedirect  = urlRedirect + '/' +  newRedirectQueryParams;
            }
        }

        return urlRedirect;
    }

    resizeHandler = () => {
        let componentReference = this;

        setTimeout(() =>{
            let ecomModal = this.refs.ecommodal;
            if(ecomModal && ecomModal != null && ecomModal != undefined){
                if(ecomModal.getBoundingClientRect() && ecomModal?.getBoundingClientRect()?.height){
                    let parentHeight = ecomModal?.getBoundingClientRect()?.height;
                    let ecomBody =  this.refs.ecomModalBody;
                    let ecomBodyInner = this.refs.ecomModalBodyInner;
                    let bodyHeight =  parentHeight - 200;
                    let innerHeight = parentHeight - 240;

                    bodyHeight = bodyHeight < 0 ? 0 : bodyHeight ;
                    ecomBody.style = 'height:'+ bodyHeight  + 'px;';
                    ecomBodyInner.style = 'height:'+ innerHeight  + 'px;';
                }
            }
        }, 1050);

    }
    //RWPS-3764 start
    handleCartKeyDown(event) {
        if (event.key === 'Enter' || event.keyCode === 13) {
            event.preventDefault();
            this.isOpen= false;//RWPS-4087
            this.redirectToCartPage();
        }
    }
    //RWPS-3764 end
    //RWPS-4087 start
    toggleMenu() {
        this.isOpen = !this.isOpen;
    }

    handleAvatarKeydown(event) {
        const k = event.key;
        if (k === 'Enter' || k === ' ') {
            event.preventDefault();
            this.toggleMenu();
        } else if (k === 'ArrowDown') {
            event.preventDefault();
            if (!this.isOpen) {
                this.toggleMenu();
            }
        }
    }



    handleMenuKeyDown(event) {
        const items = Array.from(this.template.querySelectorAll('[data-id="userMenu"] [role="menuitem"]'));
        const currentIndex = items.indexOf(event.target);

        if (event.key === 'Tab' || event.keyCode === 9) {
            const dropdownMenu = this.template.querySelector('[data-id="userMenu"]');
            const profileButton = this.template.querySelector('[data-id="profileIcon"]');

            setTimeout(() => {
                const activeEl = this.template.activeElement;
                const insideMenu = dropdownMenu && dropdownMenu.contains(activeEl);
                const onAvatar = profileButton && profileButton.contains(activeEl);

                if (!insideMenu && !onAvatar) {
                    this.isOpen = false;
                }
            }, 0);
        }

        if (event.key === 'ArrowDown') {
            event.preventDefault();
            const next = items[(currentIndex + 1) % items.length];
            next && next.focus();
        } else if (event.key === 'ArrowUp') {
            event.preventDefault();
            const prev = items[(currentIndex - 1 + items.length) % items.length];
            prev && prev.focus();
        } else if (event.key === 'Escape') {
            this.isOpen = false;
            const profileIcon =  this.template.querySelector('[data-id="profileIcon"]');
            profileIcon && profileIcon.focus();
        } else if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            event.target.click(); // triggers handleMenuSelect
        }
    }

    handleMenuSelect(event) {
        event.stopPropagation();
        const action = event.currentTarget.dataset.action;

        this.handlePageRedirect(action);

        this.isOpen = false;
        const profileIcon = this.template.querySelector('[data-id="profileIcon"]');
        profileIcon && profileIcon.focus();
    }

    handlePageRedirect(action) {
        if (!action) return;
        window.location.href = `${basePath}/${action}`;
    }

    handleDocumentClick(e){
        const avatarButton = this.template.querySelector('[data-id="profileIcon"]');
        const dropdownMenu = this.template.querySelector('[data-id="userMenu"]');

        const path = e.composedPath();

        const clickInsideAvatar = path.includes(avatarButton);
        const clickInsideMenu = path.includes(dropdownMenu);

        if (this.isOpen && !clickInsideAvatar && !clickInsideMenu) {
            this.isOpen = false;
        }
    };
    //RWPS-4087 end
}