import { LightningElement } from 'lwc';

//apex callouts
//import getSearchedPunchoutAccounts from '@salesforce/apex/ECOM_AccountsController.getSearchedPunchoutAccounts'
import getLatestLogs from '@salesforce/apex/ECOM_ApplicationLogsController.getLatestPosrPoomLogs';
import getLogsForDates from '@salesforce/apex/ECOM_ApplicationLogsController.getLogsForDates';
import removeWishListItem from '@salesforce/apex/ECOM_FrequentlyPurchasedController.removeWishListItem';
import addWishListItem from '@salesforce/apex/ECOM_FrequentlyPurchasedController.addWishListItem';
import encodeUrlParams from '@salesforce/apex/ECOM_UserController.getEncyrptedSessionParametersForCMS';

//labels
import TEXT_ORDERS from '@salesforce/label/c.ECOM_Orders';//VRa: Punchout changes
import LBL_FREQUENTLY_PURCHASED from '@salesforce/label/c.ECOM_Frequently_Purchased';//VRa: Punchout changes
import LBL_PUNCHOUT_URL_GENERATOR from '@salesforce/label/c.ECOM_Punchout_Url_Generator';//VRa: Punchout changes
import LBL_CUSTOMER_ATTRIBUTES from '@salesforce/label/c.ECOM_Customer_Attributes';//VRa Punchout changes
import LBL_CHOOSE_A_COMPANY from '@salesforce/label/c.ECOM_ChooseACompany';//VRa Punchout changes
import LBL_SELECTED_COMPANY from '@salesforce/label/c.ECOM_SelectedCompany';//VRa Punchout changes
import LBL_EMAILUSERNAME from '@salesforce/label/c.ECOM_EmailUsername';//VRa Punchout changes
import LBL_FIRSTNAME from '@salesforce/label/c.ECOM_FirstName';//VRa Punchout changes
import LBL_LASTNAME from '@salesforce/label/c.ECOM_LastName';//VRa Punchout changes
import LBL_USEPRODQARECORDS from '@salesforce/label/c.ECOM_UseProdQARecords';//VRa Punchout changes
import LBL_GENERATEDURL from '@salesforce/label/c.ECOM_GeneratedUrl';//VRa Punchout changes
import LBL_LOGIN from '@salesforce/label/c.ECOM_Login';//VRa Punchout changes
import LBL_RESET from '@salesforce/label/c.ECOM_Reset';//VRa Punchout changes
import LBL_ECOM_120001 from '@salesforce/label/c.ECOM_120001';//VRa Punchout changes
import LBL_ECOM_120002 from '@salesforce/label/c.ECOM_120002';//VRa Punchout changes
import LBL_ECOM_TESTUSER_FIRSTNAME from '@salesforce/label/c.ECOM_TestUserFirstName';//VRa Punchout changes
import LBL_ECOM_TESTUSER_LASTNAME from '@salesforce/label/c.ECOM_TestUserLastName';//VRa Punchout changes
import LBL_ECOM_LOG_VIEWER_HEADER from '@salesforce/label/c.ECOM_LogViewerHeader';//VRa Punchout changes
import LBL_ECOM_SEARCH_SETTINGS from '@salesforce/label/c.ECOM_SearchSettings';//VRa Punchout changes
import LBL_ECOM_VIEW_LOGS from '@salesforce/label/c.ECOM_ViewLogs';//VRa Punchout changes
import LBL_ECOM_LATEST from '@salesforce/label/c.ECOM_Latest';//VRa Punchout changes
import LBL_ECOM_FOR_DATES from '@salesforce/label/c.ECOM_ForDates';//VRa Punchout changes
import LBL_ECOM_SELECT_SEARCH_SETTING from '@salesforce/label/c.ECOM_SelectSearchSetting';//VRa Punchout changes
import LBL_ECOM_SELECT_START_DATE from '@salesforce/label/c.ECOM_SelectStartDate';//VRa Punchout changes
import LBL_ECOM_SELECT_END_DATE from '@salesforce/label/c.ECOM_SelectEndDate';//VRa Punchout changes
import LBL_ECOM_DATE from '@salesforce/label/c.ECOM_Date';//VRa Punchout changes	
import LBL_ECOM_LOGIN_NAME from '@salesforce/label/c.ECOM_LoginName';//VRa Punchout changes
import LBL_ECOM_ORGANIZATION_NAME from '@salesforce/label/c.ECOM_OrganizationName';//VRa Punchout changes
import LBL_ECOM_OPERATION_TYPE from '@salesforce/label/c.ECOM_OperationType';//VRa Punchout changes
import LBL_ECOM_REQUEST_DATA from '@salesforce/label/c.ECOM_RequestData';//VRa Punchout changes
import LBL_ECOM_VIEW_DATA from '@salesforce/label/c.ECOM_ViewData';//VRa Punchout changes
import LBL_ECOM_SEARCH from '@salesforce/label/c.ECOM_Search';//VRa Punchout changes
import LBL_ECOM_NO_RECORDS_TO_DISPLAY from '@salesforce/label/c.ECOM_NoRecordsToDisplay';//VRa Punchout changes
import LBL_ECOM_ERROR from '@salesforce/label/c.ECOM_Error';//VRa Punchout changes
import LBL_ECOM_START_AND_END_DATES_REQUIRED from '@salesforce/label/c.ECOM_StartAndEndDatesRequired';//VRa Punchout changes
import LBL_ECOM_PART_NUMBER from '@salesforce/label/c.ECOM_PartNumber';//VRa Punchout changes
import LBL_ECOM_PRODUCT_NAME from '@salesforce/label/c.ECOM_ProductName';//VRa Punchout changes
import LBL_ECOM_ADD_TO_CART from '@salesforce/label/c.ECOM_AddToCart';//VRa Punchout changes
import LBL_ECOM_REMOVE_FROM_FAVORITES from '@salesforce/label/c.ECOM_RemoveFromFavorites';//VRa Punchout changes
import LBL_ECOM_SAVE_TO_FAVORITES from '@salesforce/label/c.ECOM_SaveToFavorites';//VRa Punchout changes
import LBL_ECOM_PUNCHOUT_AUTH_FAILED_MESSAGE from '@salesforce/label/c.ECOM_107008';//VRa Punchout changes

export default class Ecom_punchoutUtil extends LightningElement {

}

    //export Apex calls
    export const APEX_ACTIONS = {
        //getAccountsForSearchString : getSearchedPunchoutAccounts,
        getPunchoutLogs : getLatestLogs,
        getPunchoutLogsForDates: getLogsForDates,
        removeItemAndGetUpdatedWishlist: removeWishListItem,
        addWishListItemAndGetUpdatedWishlist:addWishListItem,
    }

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

    /**
        //VRa: changes for punchout- begin 
        this.isInitialPageLoad = getFromSessionStorage(SYSTEM_CONSTANTS.SESSION_KEY_IS_INITIAL_PAGE_LOAD) ? false: true  ;
        //console.log('this.isPunchoutUser:: ', this.isPunchoutUser);//Remove after DEV
        //console.log('this.isInitialPageLoad:: ', this.isInitialPageLoad);//Remove after DEV

        if(this.isPunchoutUser && this.isInitialPageLoad){
            this.isInitialPageLoad = false;
            setToSessionStorage(SYSTEM_CONSTANTS.SESSION_KEY_IS_INITIAL_PAGE_LOAD, this.isInitialPageLoad);
            //console.log('this.isInitialPageLoad:: ', this.isInitialPageLoad);//Remove after DEV
            this.handleRecentOrderClick();
        }
         //VRa: changes for punchout- end 
    */
    
    //reused apex calls
    export async function getEncryptedSessionParameters(){
        let urlParams = '';
        await encodeUrlParams().then(result => {
            if(result && result?.success && result?.responseData){
                urlParams = result.responseData;
            }
        }).catch(error => {
            //do not console log
        });
        return urlParams;
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