import {api, track, wire, LightningElement} from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation'; //RWPS-5938
import isGuest from '@salesforce/user/isGuest';
import FORM_FACTOR from '@salesforce/client/formFactor';
import siteId from "@salesforce/site/Id";

//Apex
import loginUser from '@salesforce/apex/ECOM_CustomLoginController.loginUser'
import processSecureAccessLink from "@salesforce/apex/ECOM_CustomLoginController.processSecureAccessLink";
import encodeUrlParams from '@salesforce/apex/ECOM_UserController.getEncyrptedSessionParametersForCMS';

//label
import ECOM_LBL_EMAILADDRESS  from '@salesforce/label/c.ECOM_EmailAddress';
import ECOM_LBL_EMAILISREQUIRED  from '@salesforce/label/c.ECOM_EmailIsRequired';
import ECOM_LBL_EMAILADDRESSISNOTVALID  from '@salesforce/label/c.ECOM_EmailAddressIsNotValid';
import ECOM_Punchout_Login_Header from '@salesforce/label/c.ECOM_Punchout_Login_Header';
import ECOM_Punchout_Login_Sub_Header from '@salesforce/label/c.ECOM_Punchout_Login_Sub_Header';
import ECOM_Punchout_Login_Email_Instructions from '@salesforce/label/c.ECOM_Punchout_Login_Email_instructions';
import ECOM_Punchout_Login_Magic_Link_Button_Label from '@salesforce/label/c.ECOM_Punchout_Login_Magic_Link_Button_Label';
import ECOM_Punchout_Login_Email_Sent_Message from '@salesforce/label/c.ECOM_Punchout_Login_Email_Sent_Message';
import LBL_CMS_PARAM_PREFIX  from '@salesforce/label/c.ECOM_CMSPunchoutLoginParameter';
import LBL_CMS_BUY_PAGE  from '@salesforce/label/c.ECOM_CMSBuyPage';
import LBL_CMS_SHOP_PAGE from '@salesforce/label/c.ECOM_CMSShopPage'
import LBL_URL_PATH_SEPARATOR from '@salesforce/label/c.ECOM_UrlPathSeparator';
import ECOM_140004  from '@salesforce/label/c.ECOM_140004';
import ECOM_LBL_CMSUSERLOGINPARAMETER from '@salesforce/label/c.ECOM_CMSUserLoginParameter';
import ECOM_LBL_COMMUNITYLOCALES from '@salesforce/label/c.ECOM_CommunityLocales';

//import utils
import {getFromLocalStorage, setToLocalStorage, redirectUserIfLocaleNotPresent, setCookie} from 'c/ecom_util'; //RWPS-3768 - Added setToLocalStorage
//static resources
import sres_ECOM_CartIcons from '@salesforce/resourceUrl/ssrc_ECOM_Theme';

const ERROR_MESSAGE_STYLING = 'ecom-error-message-block'
const SUCCESS_MESSAGE_STYLING = 'ecom-success-message-block'

export default class Ecom_SecureAccessLinkWizard extends NavigationMixin(LightningElement) {

    @api
    quoteNumber;

    @api
    userRecord;

    @api
    redirectedEmail;

    @track
    userEmail = '';

    @api inputCardStyle ='';

    displayErrorMessage = false;
    usernameError = false;
    errorMessageText='';
    emailErrorMessage;
    usernameErrorMessage = '';
    cardClassStyling = 'ecom-card'
    maxWidthClass = 'ecom-card';
    showSpinner = false;
    showLoginButton = true;
    displayMessage = false;
    messageText = '';
    messageStyling = ERROR_MESSAGE_STYLING;
    showEmailContainer = true;
    showComponent = false;

    labels = {
        ECOM_Punchout_Login_Header,
        ECOM_Punchout_Login_Sub_Header,
        ECOM_Punchout_Login_Email_Instructions,
        ECOM_Punchout_Login_Magic_Link_Button_Label,
        ECOM_Punchout_Login_Email_Sent_Message,
        ECOM_LBL_EMAILADDRESS,
        ECOM_LBL_EMAILISREQUIRED,
        ECOM_LBL_EMAILADDRESSISNOTVALID,
        LBL_CMS_PARAM_PREFIX,
        LBL_CMS_BUY_PAGE,
        LBL_CMS_SHOP_PAGE,
        LBL_URL_PATH_SEPARATOR,
        ECOM_140004,
        ECOM_LBL_CMSUSERLOGINPARAMETER,
        ECOM_LBL_COMMUNITYLOCALES
    }

    device = {
        isMobile : FORM_FACTOR === 'Small',
        isDesktop : FORM_FACTOR === 'Large',
        isTablet :FORM_FACTOR === 'Medium'
    }

    images ={
        closeIcon: sres_ECOM_CartIcons + '/img/close-icon.svg',
    }

    get currentMaxWidthClass(){
        let currentClass = 'ecom-card ';
        if(this.isDesktop){
            currentClass = currentClass + 'ecom-max-width-528';
        }
        return currentClass;
    }

    get cardStyling(){
        let style = this.maxWidthClass + ' ' + this.inputCardStyle;
        return style;
    }

    @wire(CurrentPageReference)
    getPageReferenceParameters(currentPageReference) {
        this.showSpinner = true;
        if (currentPageReference) {
            //RWPS-5938
            if (currentPageReference.attributes && currentPageReference.attributes.name && (currentPageReference.attributes.name === 'secure-access-link' || currentPageReference.attributes.name === 'Secure_Access_Link_Redirection__c')) {
                this.showComponent = false;
                let urlParams = '';
                encodeUrlParams().then(result => {
                    if(result && result?.success){
                        let baseUrl = result.Home;
                        if(result.locale && result.locale!= '' && baseUrl.indexOf(result.locale)==-1){
                            if (baseUrl.substr(-1) != '/'){
                                baseUrl += this.labels.LBL_URL_PATH_SEPARATOR;
                            }
                            baseUrl = baseUrl +  result.locale;
                        }
                        baseUrl = baseUrl.replace('us-en', '');
                        urlParams = result.responseData;
                        if (baseUrl.substr(-1) != '/'){
                            baseUrl += this.labels.LBL_URL_PATH_SEPARATOR;
                        }
                        window.location.href = baseUrl + this.labels.LBL_CMS_BUY_PAGE + this.labels.ECOM_LBL_CMSUSERLOGINPARAMETER + urlParams;
                    } else {
                        this[NavigationMixin.Navigate]({
                            type: 'standard__webPage',
                            attributes: {
                                url: '/dashboard?ptcms=true'
                            }
                        });
                    }
                }).catch(error => {
                    console.log('error::', error);
                    this.showSpinner = false;
                    this[NavigationMixin.Navigate]({
                        type: 'standard__webPage',
                        attributes: {
                            url: '/dashboard?ptcms=true'
                        }
                    });
                });
            } else {
                this.showComponent = true;
                this.showSpinner = false;
            }
        } else {
            this.showComponent = true;
            this.showSpinner = false;
        }
    }

    connectedCallback() {
        if (this.userRecord) {
            this.userEmail = this.userRecord?.Email ? this.userRecord.Email : '';
        }
        if(this.redirectedEmail){
            this.userEmail = this.redirectedEmail;
        }
    }

    handleUserLogin(event) {
        this.showSpinner = true;
        event.preventDefault();
        const queryParameters = window.location.search;
        const urlParams = new URLSearchParams(queryParameters);
        if(this.validateUserCredentials()){
            const username = this.userEmail;
            const retUrl = urlParams.get('retUrl');
            const userLocale = urlParams.get('locale');
            this.refs['loginBtn'].disabled = true;
            this.performLogin(this.quoteNumber, username)
        } else {
            this.refs['loginBtn'].disabled = false;
            this.showSpinner = false;
            return;
        }
    }

    @api
    performLogin(quoteNumber, userEmail) {
        this.showSpinner = true;

        processSecureAccessLink({
            quoteNumber: quoteNumber,
            userEmail: userEmail
        }).then(result => {
            if (result) {
                if(result.success == true) {
                    this.showEmailContainer = false;
                    this.showLoginButton = false;
                    this.displayMessage = true;
                    this.messageText = result?.message? result.message : '';
                    this.messageStyling = SUCCESS_MESSAGE_STYLING;
                } else if (result.success == false) {
                    this.showEmailContainer = true;
                    this.showLoginButton = true;
                    this.displayMessage = true;
                    this.messageText = result?.message? result.message : '';
                    this.messageStyling = ERROR_MESSAGE_STYLING
                }
            }
            this.refs['loginBtn'].disabled = false;
            this.showSpinner = false;
        })
        .catch(error => {
            console.error('error -> ', error);
            this.displayErrorMessage = false;
            this.errorMessageText = '';
            this.showSpinner = false;
        });
    }

    /**
     * This method sets the value for error block
     */
    setErrorData(errorFlag, errorMessage){
        this.displayErrorMessage = errorFlag;
        this.errorMessageText = errorMessage;
    }

    /**
     * Validate if required inputs are provided and email format
     */
    validateUserCredentials(){
        let isValidCredentials = false;
        let isUserNameValidationPassed = false;
        const username = this.userEmail;
        if(username && this.validateEmail() ){
            isUserNameValidationPassed = true;
        } else {
            isUserNameValidationPassed = false;
            this.usernameErrorMessage = this.labels.ECOM_LBL_EMAILADDRESSISNOTVALID;
            this.usernameError = true;
        }
        return isUserNameValidationPassed;
    }

    /**
     *  Validate email format
     * @param {*} userName
     */
    validateEmail(){
        const username = this.userEmail;
        let isValidEmail = false;
        const mailFormat = '[a-zA-Z0-9._%+\\-]+@[a-zA-Z0-9.\\-]+\\.[a-zA-Z]{2,}$';
        if(username.match(mailFormat)){
            isValidEmail = true;
        } else {
            isValidEmail = false;
        }
        return isValidEmail;
    }


    validateUserName(event){
        let username = event?.target?.value?.trim()? event.target.value.trim() : '';
        this.userEmail = username;
        if(this.userEmail == '' || this.userEmail == undefined || this.userEmail == null){
            this.usernameErrorMessage = this.labels.ECOM_LBL_EMAILISREQUIRED;
            this.usernameError = true;
        } else {
            this.usernameErrorMessage = '';
            this.usernameError = false;
        }
    }


    closePrompt(event){
        this.displayMessage = false;
    }

    handleEnter(event){
        if(event.key === 'Enter' || event.keyCode === 13){
            this.handleUserLogin(event);
        }
    }
}