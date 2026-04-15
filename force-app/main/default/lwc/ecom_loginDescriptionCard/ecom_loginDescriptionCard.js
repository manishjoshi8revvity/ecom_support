import { LightningElement, api} from 'lwc';
import {NavigationMixin } from 'lightning/navigation';
import basePath from '@salesforce/community/basePath';

//static resources
import sres_ECOM_CartIcons from '@salesforce/resourceUrl/ssrc_ECOM_Theme';


//labels
import ECOM_LBL_NOTAREGISTEREDUSER from '@salesforce/label/c.ECOM_NotARegisteredUser';
import ECOM_LBL_REGISTERFORADVANCEOPTIONS from '@salesforce/label/c.ECOM_RegistedUserGetAdvancedOptions';
import ECOM_LBL_REGISTRATIONCUSTOMERADVANCEOPTIONS from '@salesforce/label/c.ECOM_RegistedCustomerAdvancedOptions';
import ECOM_LBL_CUSTOMERSPECIFICPRICING from '@salesforce/label/c.ECOM_CustomerSpecificPricing';
import ECOM_LBL_EASYREORDERING from '@salesforce/label/c.ECOM_EasyReordering';
import ECOM_LBL_PRIORITYORDERPROCESSING from '@salesforce/label/c.ECOM_PriorityOrderProcessing';
import ECOM_LBL_DYNAMICORDERTRACKING from '@salesforce/label/c.ECOM_DynamicOrderTracking';
import ECOM_LBL_CREATEANACCOUNT from '@salesforce/label/c.ECOM_CreateAnAccount';
import ECOM_LBL_HAVINGTROUBLELOGGINGIN from '@salesforce/label/c.ECOM_HavingTroubleLoggingIn';
import ECOM_LBL_SUPPORTEMAIL from '@salesforce/label/c.ECOM_SupportEmail';
import ECOM_LBL_PLEASECONTACT from '@salesforce/label/c.ECOM_PleaseContact';
import ECOM_LBL_ACCOUNTBENEFITS from '@salesforce/label/c.ECOM_AccountBenefits';
import ECOM_LBL_HAVINGTROUBLE from '@salesforce/label/c.ECOM_HavingTrouble';
import ECOM_LBL_OMVICSPORTALACCOUNTS from '@salesforce/label/c.ECOM_RevvityOmicsPortalAccounts';
import ECOM_LBL_OMVICSDESCRIPTION from '@salesforce/label/c.ECOM_OmvicsCardDescription';
import ECOM_LBL_VIEWLOGINOPTIONS from '@salesforce/label/c.ECOM_ViewLoginOptions';
import ECOM_LBL_OMVICSPORTALLINK from '@salesforce/label/c.ECOM_OmvicsPotalLink';
import ECOM_LBL_WESENTYOUANEMAILFROM from '@salesforce/label/c.ECOM_WeSentYouAnEmailFrom';
import ECOM_LBL_USCUSTOMERCAREINQUIRYEMAIL from '@salesforce/label/c.ECOM_UsCustomerCareInquiryEmail';
import ECOM_LBL_EXCLUSIVEPRICING from '@salesforce/label/c.ECOM_ExclusivePricing';//RWPS-2656



export default class Ecom_loginDescriptionCard extends NavigationMixin(LightningElement) {

    @api isLoginPage;
    @api isRegistrationPage;
    @api createAccountPage = 'SelfRegister';
    @api isDisplayContactSupportCard;
    @api isDisplayCreateAccountButton;
    @api isDisplayAccountDetailsCard;
    @api isForgotPasswordPage;
    @api isDisplayOmvicsCard = false;
    @api isResetPasswordpage;
    @api isHavingTroubleCard;

    RegistrationPage = {//RWPS-5367
        registrationURL: '/SelfRegister?ptcms=true'
    }
    images = {
        clock : sres_ECOM_CartIcons + '/img/Clock.svg',
        tag : sres_ECOM_CartIcons + '/img/tag.svg',
        heart: sres_ECOM_CartIcons + '/img/heart-black.svg',
        truck: sres_ECOM_CartIcons + '/img/truck.svg',
        priceTag: sres_ECOM_CartIcons + '/img/price-tag.svg' //RWPS-2656
    }

    labels = {
        ECOM_LBL_NOTAREGISTEREDUSER,
        ECOM_LBL_REGISTERFORADVANCEOPTIONS,
        ECOM_LBL_CUSTOMERSPECIFICPRICING: ECOM_LBL_CUSTOMERSPECIFICPRICING !== '.' ? ECOM_LBL_CUSTOMERSPECIFICPRICING : '', //RWPS-2656
        ECOM_LBL_EASYREORDERING: ECOM_LBL_EASYREORDERING !== '.' ? ECOM_LBL_EASYREORDERING : '', //RWPS-2656
        ECOM_LBL_PRIORITYORDERPROCESSING: ECOM_LBL_PRIORITYORDERPROCESSING !== '.' ? ECOM_LBL_PRIORITYORDERPROCESSING : '', //RWPS-2656
        ECOM_LBL_DYNAMICORDERTRACKING: ECOM_LBL_DYNAMICORDERTRACKING !== '.' ? ECOM_LBL_DYNAMICORDERTRACKING : '', //RWPS-2656
        ECOM_LBL_CREATEANACCOUNT,
        ECOM_LBL_HAVINGTROUBLELOGGINGIN,
        ECOM_LBL_SUPPORTEMAIL,
        ECOM_LBL_PLEASECONTACT,
        ECOM_LBL_ACCOUNTBENEFITS,
        ECOM_LBL_HAVINGTROUBLE,
        ECOM_LBL_REGISTRATIONCUSTOMERADVANCEOPTIONS,
        ECOM_LBL_OMVICSPORTALACCOUNTS,
        ECOM_LBL_OMVICSDESCRIPTION,
        ECOM_LBL_VIEWLOGINOPTIONS,
        ECOM_LBL_OMVICSPORTALLINK,
        ECOM_LBL_WESENTYOUANEMAILFROM,
        ECOM_LBL_USCUSTOMERCAREINQUIRYEMAIL,
        ECOM_LBL_EXCLUSIVEPRICING: ECOM_LBL_EXCLUSIVEPRICING !== '.' ? ECOM_LBL_EXCLUSIVEPRICING : '' //RWPS-2656
    }

    get cardHeader() {
        let currentHeader = this.labels.ECOM_LBL_NOTAREGISTEREDUSER;

        return currentHeader;
    }

    get displayAccountDetailsCard() {
        let displayCard = false;

        if(this.isDisplayAccountDetailsCard == undefined || (this.isDisplayAccountDetailsCard && this.isDisplayAccountDetailsCard == true)) {
            displayCard = true;
        }
        return displayCard;
    }



    get displayCreateAccountButton() {
        let displayButton = false;

        if(this.isDisplayCreateAccountButton == undefined || (this.isDisplayCreateAccountButton && this.isDisplayCreateAccountButton == true)) {
            displayButton = true;
        }
        console.log('this.isDisplayCreateAccountButton::',this.isDisplayCreateAccountButton);//Remove after DEV
        console.log('displayButton::',displayButton);//Remove after DEV
        return displayButton;
    }

    get registrationPageStylingClass2() {
        let base = 'ecom-bottom-card';

        if(this.isDisplayAccountDetailsCard == false){
            base = 'ecom-no-margin-bottom-card';
            base = base + ' ecom-text-size-18';
        } else {
            if(this.isRegistrationPage){
                base = base + ' ecom-text-size-24';
            } else {
                base = base + ' ecom-text-size-18';
            }
        }


        return base;
    }


    get registrationPageStylingClass(){
        let base = 'ecom-bottom-card';
        base = base + ' ecom-text-size-24';
        return base;
    }

    get forgotPasswordPageStylingClass() {
        return  'ecom-text-size-18 ';
    }

    get secondaryCardTitle() {
        let currentHeader = this.labels.ECOM_LBL_HAVINGTROUBLELOGGINGIN;

        if(this.isRegistrationPage ) {
            currentHeader = this.labels.ECOM_LBL_HAVINGTROUBLE;
        }

        if(this.isForgotPasswordPage == true){
            currentHeader = this.labels.ECOM_LBL_HAVINGTROUBLELOGGINGIN;
        }

        return currentHeader;
    }

    get mailToSupportEmail() {
        const currentEmail  = 'mailto:'+this.labels.ECOM_LBL_SUPPORTEMAIL;
        return currentEmail;
    }

    get customerAdvantageMessage() {
        let currentOptionsMessage = this.labels.ECOM_LBL_REGISTERFORADVANCEOPTIONS;
        if(window.location.href.indexOf('SelfRegister') != 1){
            currentOptionsMessage = this.labels.ECOM_LBL_REGISTRATIONCUSTOMERADVANCEOPTIONS;
        }
        return currentOptionsMessage;
    }

    get displayContactSupportCard() {
        let displayCard = false;
        console.log('isDisplayContactSupportCard:: ', this.isDisplayContactSupportCard);//Remove after DEV
        console.log('isDisplayOmvicsCard:: ', this.isDisplayOmvicsCard);//Remove after DEV
        if((this.isDisplayContactSupportCard == true && this.isDisplayOmvicsCard == false) ||
        (this.isDisplayContactSupportCard && this.isRegistrationPage)) {
            displayCard = true;
        }
        console.log('displayCard::', displayCard);//Remove after DEV
        return displayCard;
    }

    get customerCareInquiryEmail(){
        let email = 'mailto:';
        return email + this.labels.ECOM_LBL_USCUSTOMERCAREINQUIRYEMAIL;
    }

    handleNavigateToRegistration(){
        //const createAccountPage =  basePath + '/' + this.createAccountPage;
        this.createAccountPage = 'Register';
        console.log('createAccountPage:: ', this.createAccountPage);//Remove after DEV
        //this.navigateToPageUrl(createAccountPage);
        let redirectUrl = window.location.origin;
        window.location.href = redirectUrl + '/SelfRegister?ptcms=true';
        //this.navigateToNamedPage(this.createAccountPage);
    }

    navigateToPageUrl(pageUrl){

        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
                attributes: {
                    url: pageUrl
                }
        });
    }

    navigateToNamedPage(pageName){
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
                attributes: {
                    name: pageName
                }
        });
    }
}