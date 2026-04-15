import cartApi from 'commerce/cartApi';
import { api, wire, track, LightningElement } from 'lwc';
import repriceCart from '@salesforce/apex/ECOM_CartController.repriceCart';

import locale from '@salesforce/i18n/locale';
import getCMSBaseUrl from '@salesforce/apex/ECOM_CartController.getCMSBaseUrl';
// RWPS-592 Begin
import getContentDocumentId from "@salesforce/apex/ECOM_DashboardController.handlePDFDownload";
// RWPS-592 End

import getContractPrice from '@salesforce/apex/ECOM_CartController.getContractPrice'; // RWPS-3740

//VRa : adding common util method for redirection
import encodeWebUserParams from '@salesforce/apex/ECOM_UserController.getCMSRedirectDataMap';
import logJSFailure from '@salesforce/apex/ECOM_Util.logJsFailure';//RWPS-5153

export default class Ecom_util extends LightningElement {
    constructor(){
        super();
    }
    
    connectedCallback(){
        this.baseCMSUrl();
    }

    baseCMSUrl() {
        // Call the 'getFieldsByObjectName' apex method imperatively
        getCMSBaseUrl({
            moduleName:'SiteURL'
        }).then((result) => {
            })
            .catch((error) => {
                console.log(error);
            });
    }
}

export function updateItemInCart(itemId , quantity) {
    const result = cartApi.updateItemInCart(itemId,quantity);
    return result;
}

export function repriceCurrCart(cartId , couponCode) {
    const result = repriceCart(cartId,couponCode);
    return result;
}

export function addItemToCart(productId , productQuantity) {
    const result = cartApi.addItemToCart(productId,productQuantity);
    return result;
}

export function deleteItemFromCart(cartItemId) {
    const result = cartApi.deleteItemFromCart(cartItemId);
    return result;
}

export function  applyCouponToCart(couponCode) {
    const result = cartApi.applyCouponToCart(couponCode);
    result.then((response) => {

    }).catch((error) => {
    });
}

export function sendPostMessage(message) {
    window.postMessage(message, window.location.origin);
}

export function  doNavigationToCMS(pageType) {
    let baseUrl =''
    switch(pageType){
        case 'PLP':
            baseUrl+='/buy';
            break;
        case 'Policies':
            baseUrl+='/policies';
            break;
        case 'ContactUs':
        case 'CustomerCare':
            baseUrl+='/contact-us';
            break;
        case 'Terms & Conditions':
            baseUrl+='/buy';
            break;
        default:
    }
    window.open(baseUrl,'_self');
}

export function  navigateToPDP(partNumber,partDesc) {
    let baseUrl =''+'/product/'+partDesc+'-'+partNumber;
    window.open(baseUrl,'_self');
}
// RWPS-592 Begin
export async function getCDLId() {
    let contentDocumentMap = new Map();
    await getContentDocumentId()
    .then((result)=>
    {
        if(result.isSuccess){
            contentDocumentMap = result;
        }
    })
    .catch((error)=>
    {
        console.log('Content document link download error : ' + JSON.stringify(error));
    })
    return contentDocumentMap;
}

// RWPS-592 End

//VRa: Punchout changes - Begin
/*
//set a value to session storage
export function setToSessionStorage(key, value){
    sessionStorage.setItem(key,value);
}

//return a value from session storage if it exists
export function getFromSessionStorage(key){
    //return value from  session
    return sessionStorage.getItem(key) || '';
}

export function parseJSON(value){
    return JSON.parse(JSON.stringify(value));
}

export function parseJSONWOStringify(value){
    return JSON.parse(value);
}

export function stringifyJSON(value){
    return JSON.stringify(value);
}

export function getUserConfigData(){
    let userConfig = getFromSessionStorage(SYSTEM_CONSTANTS.SESSION_KEY_USER_TYPE);
    if(userConfig){
        userConfig = parseJSONWOStringify(userConfig);
    }
    return userConfig;
}

//export reused constants
export const SYSTEM_CONSTANTS = {
    SESSION_KEY_USER_TYPE: 'userType',
    SESSION_KEY_IS_INITIAL_PAGE_LOAD: 'isInitialPageLoad',
    NAVIGATE_TO_PDP : 'PDP',
    CMS_NAVIGATION : 'CMSNavigation',
    ACTION_LOGIN : 'login',
    ACTION_RESET : 'reset',
    LATEST_500: 'latest_500',
    FOR_DATES: 'for_dates',
}

//export reused labels
export const SYSTEM_LABELS = {
    ORDERS: TEXT_ORDERS,
    FREQUENTLY_PURCHASED: LBL_FREQUENTLY_PURCHASED,
    PUNCHOUT_URL_GENERATOR: LBL_PUNCHOUT_URL_GENERATOR,
    CUSTOMER_ATTRIBUTES: LBL_CUSTOMER_ATTRIBUTES,
    CHOOSE_A_COMPANY: LBL_CHOOSE_A_COMPANY,
    SELECTED_COMPANY: LBL_SELECTED_COMPANY,
    EMAIL_USERNAME: LBL_EMAILUSERNAME,
    FIRSTNAME: LBL_FIRSTNAME,
    LASTNAME: LBL_LASTNAME,
    USE_PRODQA_RECORDS: LBL_USEPRODQARECORDS,
    GENERATED_URL: LBL_GENERATEDURL,
    LOGIN: LBL_LOGIN,
    RESET: LBL_RESET,
    ECOM_120001: LBL_ECOM_120001,
    ECOM_120002: LBL_ECOM_120002,
    TEST_USER_FIRSTNAME: LBL_ECOM_TESTUSER_FIRSTNAME,
    TEST_USER_LASTNAME: LBL_ECOM_TESTUSER_LASTNAME,
    LOG_VIEWER_HEADER: LBL_ECOM_LOG_VIEWER_HEADER,
    SEARCH_SETTINGS: LBL_ECOM_SEARCH_SETTINGS,
    VIEW_LOGS: LBL_ECOM_VIEW_LOGS,
    FOR_DATES: LBL_ECOM_FOR_DATES,
    LATEST: LBL_ECOM_LATEST,
    SELECT_SEARCH_SETTING: LBL_ECOM_SELECT_SEARCH_SETTING,
    SELECT_START_DATE: LBL_ECOM_SELECT_START_DATE,
    SELECT_END_DATE: LBL_ECOM_SELECT_END_DATE,
    DATE: LBL_ECOM_DATE,
    LOGIN_NAME: LBL_ECOM_LOGIN_NAME,
    ORGANIZATION_NAME: LBL_ECOM_ORGANIZATION_NAME,
    OPERATION_TYPE: LBL_ECOM_OPERATION_TYPE,
    REQUEST_DATA: LBL_ECOM_REQUEST_DATA,
    VIEW_DATA: LBL_ECOM_VIEW_DATA,
    SEARCH: LBL_ECOM_SEARCH,
    NO_RECORDS_TO_DISPLAY: LBL_ECOM_NO_RECORDS_TO_DISPLAY,
    LBL_ERROR: LBL_ECOM_ERROR,
    START_AND_END_DATES_REQUIRED: LBL_ECOM_START_AND_END_DATES_REQUIRED,
    PART_NUMBER: LBL_ECOM_PART_NUMBER,
    PRODUCT_NAME: LBL_ECOM_PRODUCT_NAME,
    ADD_TO_CART: LBL_ECOM_ADD_TO_CART,
    REMOVE_FROM_FAVORITES: LBL_ECOM_REMOVE_FROM_FAVORITES,
    SAVE_TO_FAVORITES: LBL_ECOM_SAVE_TO_FAVORITES,
    PUNCHOUT_AUTH_FAILED_MESSAGE: LBL_ECOM_PUNCHOUT_AUTH_FAILED_MESSAGE
}
*/

//VRa: Punchout changes - end

// export default class Ecom_util extends LightningElement {
//     constructor(){
//         super();
//     }
//     connectedCallback(){
//         this.baseCMSUrl();
//     }

//     baseCMSUrl() {
//         // Call the 'getFieldsByObjectName' apex method imperatively
//         getCMSBaseUrl({
//             moduleName:'SiteURL'
//         }).then((result) => {
//             })
//             .catch((error) => {
//                 console.log(error);
//             });
//     }
// }
//Method to validate the erpaddress for any field validation and add those fields to the erp address map
// Change start by sathiya on 2024/04/29
export function validateAddressByFields(erpAddress, validationObj){
    let validationCountry = (erpAddress?.country!=null && erpAddress?.country!='' && erpAddress?.country!=undefined) ? erpAddress?.country.toLowerCase() : null; //ECOM-112 - garora@rafter.one - added a null check - 12 May 2024
    return this.validateFields(erpAddress, validationCountry, validationObj, false);
}

//Method to validate the erpaddress for any field validation and add those fields to the erp address map
// Change start by sathiya on 2024/04/29
export function validateAddressForOrder(order, validationObj){
    let validationCountry = (order?.billingAddress?.country!=null && order?.billingAddress?.country!='' && order?.billingAddress?.country!=undefined) ? order?.billingAddress?.country.toLowerCase() : null; //ECOM-112 - garora@rafter.one - added a null check - 12 May 2024
    return this.validateFields(order, validationCountry, validationObj, false);;
}
// Changes end
// Change start by sathiya on 2024/05/13
//Method to validate the invoice fields for any field validation and add those fields to the invoice map
export function validateFields(mainObj, country, validationObj){
    return validateFieldsWithRequired(mainObj, country, validationObj, false);
}
//Method to validate the invoice fields for any field validation and add those fields to the invoice map with required value
export function validateFieldsWithRequired(mainObj, country, validationObj, isRequired){
    console.log('validationCountry: ', country, 'mainObj:: ', mainObj);
    // mainObj.validationFields = [];
    // mainObj.isValidatedFields = false;
    if(country && country != null  && country != undefined && country != '' && mainObj && mainObj != undefined && mainObj != null){ //VRa: added undefined/null checks for ECOM-3262
        mainObj.validationFields = [];
        mainObj.isValidatedFields = false;
        let isAvailable = false;
        for(let i = 0; i < validationObj.length; i++){
            let emailValidation = false, isRequiredOverride = isRequired;
            if(validationObj[i].fieldName == 'emailToInvoice' && mainObj?.invoiceCustId != null && mainObj?.invoiceCustId != ''){
                emailValidation = true;
            }
            if(validationObj[i].validation?.default != null){
                if(isRequiredOverride && validationObj[i].validation?.default?.isOptionalOverride != null){
                    isRequiredOverride = false;
                }
                mainObj.validationFields.push({
                    "label": validationObj[i].validation?.default.displayLabel
                    , "value": mainObj?.[validationObj[i].fieldName]
                    , "fieldName" : validationObj[i].fieldName
                    , "fieldAPIName" : validationObj[i].fieldAPIName
                    , "validation" : validationObj[i].validation?.default?.validationList[0]
                    , "helpText" : validationObj[i].validation?.default?.helpText != null? validationObj[i].validation?.default?.helpText: ""
                    , "isReadOnly" : mainObj?.[validationObj[i].fieldName] != null && mainObj?.[validationObj[i].fieldName] != ''
                    , "isRequired" : emailValidation?false:isRequiredOverride?isRequiredOverride:validationObj[i].validation?.default?.isRequired
                });
                if(!isAvailable){
                    isAvailable = mainObj?.[validationObj[i].fieldName] != null && mainObj?.[validationObj[i].fieldName] != '';
                }
            }
            if(validationObj[i].validation?.[country] != null){
                if(isRequiredOverride && validationObj[i].validation?.[country]?.isOptionalOverride != null){
                    isRequiredOverride = false;
                }
                mainObj.validationFields.push({
                    "label": validationObj[i].validation?.[country].displayLabel
                    , "value": mainObj?.[validationObj[i].fieldName]
                    , "fieldName" : validationObj[i].fieldName
                    , "fieldAPIName" : validationObj[i].fieldAPIName
                    , "validation" : validationObj[i].validation?.[country].validationList[0]
                    , "helpText" : validationObj[i].validation?.[country]?.helpText != null? validationObj[i].validation?.[country]?.helpText: ""
                    , "isReadOnly" : mainObj?.[validationObj[i].fieldName] != null && mainObj?.[validationObj[i].fieldName] != ''
                    , "isRequired" : isRequiredOverride?isRequiredOverride:validationObj[i].validation?.[country]?.isRequired
                });
                if(!isAvailable){
                    isAvailable = mainObj?.[validationObj[i].fieldName] != null && mainObj?.[validationObj[i].fieldName] != '';
                }
            }
        }
        mainObj.isValidatedFields = isAvailable;
    }
    return mainObj;
}
//Validate countries that allow invoice mailing address
export function validateInvoiceMailingAddressByCountry(accountCountry, countires){
    let isAllowed = false;
    if(accountCountry != null && countires != null){
        let countryList = countires.split(';');
        let filterList = countryList.filter(function (str) { return str.toLowerCase() === accountCountry.toLowerCase(); });
        isAllowed = filterList.length > 0;
    }
    return isAllowed;
}
// Changes end
export function validateEmail(email){
    let isValidEmail = false;
    if(email != '' && email != undefined && email != null){
        //const mailFormat = /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/;
        const mailFormat = '[a-zA-Z0-9._%+\\-]+@[a-zA-Z0-9.\\-]+\\.[a-zA-Z]{2,}$';
        //const mailFormat = String(this.labels.ECOM_LBL_EMAILVALIDATIONREGEX);
        if(email.match(mailFormat)){
            isValidEmail = true;
        } else {
            isValidEmail = false;
        }
    }
    return isValidEmail;
}

export function getCookieByName(name){
    return document.cookie.split('; ').find(row => row.startsWith(`${name}=`))?.split('=')[1];
}

export function setCookie(cookieName, value) {
    const days = 3;
        var expires = "";
        if (days) {
            var date = new Date();
            date.setTime(date.getTime() + (days*24*60*60*1000));
            expires = "; expires=" + date.toUTCString();
        }
        document.cookie = cookieName + "=" + (value || "")  + expires + "; path=/";
}
export function deleteCookieByName(name) {
    document.cookie = name +'=; Path=/; Expires=Thu, 01 Jan 1970 00:00:01 GMT;';
  }

export function setToLocalStorage(itemName, itemValue) {
    localStorage.setItem(itemName, itemValue);
}

export function getFromLocalStorage(labelName) {
    let value = '';
    value = localStorage.getItem(labelName);

    return labelName ? value : '';
}

export function removeFromLocalStorage(labelName) {
    localStorage.removeItem(labelName);
}

export function logoutUserAndRedirect(logoutDelay, logoutUrl, redirectUrl, cookieName, storedLocale){
    deleteCookieByName(cookieName);
    setToLocalStorage(storedLocale,'');
    fetch(logoutUrl);
    setTimeout(() => {
        window.location.replace(redirectUrl);
    }, parseInt(logoutDelay));
}

export function redirectUserWithBaseUrl(baseUrl){
    console.log('redirectUserWithBaseUrl', 'baseUrl:: ', baseUrl);//Remove after DEV
    let redirectUrl='';
    if(baseUrl && baseUrl != '' && baseUrl != undefined && baseUrl != null){
        encodeWebUserParams().then(result => {
            if(result && result.success && result.responseData){

                let urlParams = result.responseData;
                redirectUrl = baseUrl + '?user_data=' + urlParams;

            } else {
                //nothing to do. cannot proceed without url params
            }
        }).catch(error => {
            //console.log('encodeWebUser:error::', error);//Remove after DEV
        })
    }

    return redirectUrl;
}

export async function redirectUserIfLocaleNotPresent(baseUrl, redirectUrl, isForward, localeJson, isGuestUser){
    let isSuccess = false;
    const queryParameters = window.location.search;
    const urlParams = new URLSearchParams(queryParameters);
    const ptcms = urlParams && (urlParams.get('ptcms') == undefined || urlParams.get('ptcms') == null) ? true : false;
    const localeLabels = JSON.parse(localeJson);
    const isForwardForLocale = isForward === 'true' ? true : false;
    console.log('ptcms:', ptcms, 'localeLabels:', localeLabels, 'isForwardForLocale:', isForwardForLocale);//Remove after DEV
    if(ptcms && isGuestUser && localeLabels != '' ){
        let isRedirect = true;
        if(localeLabels){
            for(const [key, value] of Object.entries(localeLabels)){
                if(baseUrl.indexOf(value) > -1){
                    isRedirect = false;
                }
            }
            console.log('isRedirect:', isRedirect);//Remove after DEV
            try{
                const redirectTo = redirectUrl ;
                console.log('redirectTo::', redirectUrl, 'isRedirect', isRedirect);//Remove after DEV
                if(baseUrl.indexOf('commeditor') == -1 && isRedirect && isForwardForLocale){
                    window.location.href=redirectTo;
                } else {
                    isSuccess = true;
                }
            }catch(error){
                console.log('constructor: error:: ', error);//Remove after DEV
                isSuccess = true;
            }
        }
    }

    return isSuccess
}

// RWPS-3740
export function getReplacementProductContractPrice(replacementMap) {
    return new Promise((resolve, reject) => {
        if(!replacementMap) {
            resolve({});
            return;
        }

        let productList = [];
        for(let key in replacementMap) {
            let replacement = replacementMap[key];
            if(replacement.DirectReplacement) {
                productList.push({...replacement.DirectReplacement});
            } else {
                productList.push(...replacement.AlternativeReplacements);
            }
        }

        if(productList.length == 0) {
            resolve({});
            return;
        }

        getContractPrice({products: productList})
            .then(result => {
                let priceMap = {};
                result.Product_list?.forEach(productPrice => {
                    let tempPrice = parseFloat(productPrice.price);
                    if(isNaN(tempPrice)) {
                        return;
                    }

                    priceMap[productPrice.part_number] =
                        productPrice.currency + ' ' + new Intl.NumberFormat("en-US", {minimumFractionDigits : 2}).format(tempPrice);
                });

                resolve(priceMap);
                return;
            })
            .catch(error => {
                resolve({});
                return;
            });
    });
}

 /**
 * Processes, stringifies, truncates, and logs errors consistently.
 * @param {any} error - The error object captured by the catch block.
 * @param {string} moduleName - Module name where the error occurred.
 * @param {string} fileName - The name of the LWC file where the error occurred.
 * @param {string} methodName - The name of the specific function where the error occurred.
 * @param {string} severity - The severity of the error. Defaults to 'ERROR'.//RWPS-5937
 */
export function processAndLogJSError(error, fileName, moduleName, methodName) {//RWPS-5937 added severity , severity = 'ERROR'
    let errorStr = "";
    const supportDataMaxLength = 131072; 

    if (typeof error === 'string' || typeof error === 'number') {
        errorStr = String(error);
    } else if (error instanceof Error )//RWPS-5937 start
    {
        errorStr = `${error.name}: ${error.message}`;
        if (error.stack) {
            errorStr += ` | Stack: ${error.stack}`;
        }////RWPS-5937 end
    }else if (typeof error === 'object' && error !== null) 
    {
        // Handle generic objects (including those thrown via throw {})
        try {
            // Attempt to get a detailed JSON string
            errorStr = JSON.stringify(error);
        } catch(jsonError) {
            // Fallback for objects that cannot be stringified 
            errorStr = String(error); 
        }
    }
    if (errorStr.length > supportDataMaxLength) {
        errorStr = errorStr.substring(0, supportDataMaxLength);
    }    
    logJSFailure({ fileName: fileName, moduleName: moduleName, methodName: methodName, supportData: errorStr });//RWPS-5937, severity: severity
}