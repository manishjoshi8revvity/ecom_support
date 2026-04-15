import { LightningElement, api, track } from 'lwc';

//labels
import ECOM_LBL_REQUESTSUBMITTED from '@salesforce/label/c.ECOM_RequestSubmitted';
import ECOM_LBL_BACKTOLOGIN from '@salesforce/label/c.ECOM_BackToLogin';
import ECOM_LBL_CREATEANACCOUNT from '@salesforce/label/c.ECOM_CreateAnAccount';
import ECOM_LBL_FORGOTPASSWORDSUCCESSMESSAGE from '@salesforce/label/c.ECOM_ForgotPasswordSuccessMessage';
import ECOM_LBL_WESENTYOUANEMAILFROM from '@salesforce/label/c.ECOM_WeSentYouAnEmailFrom';
import ECOM_LBL_USCUSTOMERCAREINQUIRYEMAIL from '@salesforce/label/c.ECOM_UsCustomerCareInquiryEmail';
import ECOM_LBL_PLEASECHECKSPAMFOLDER from '@salesforce/label/c.ECOM_PleaseCheckSpamFolderIfNeeded';

export default class Ecom_forgotPasswordSuccessCard extends LightningElement {

    @api createAccountEndpoint;
    @api loginPageEndpoint;
    @track customerEmail;

    //labels
    labels = {
        ECOM_LBL_REQUESTSUBMITTED,
        ECOM_LBL_FORGOTPASSWORDSUCCESSMESSAGE,
        ECOM_LBL_BACKTOLOGIN,
        ECOM_LBL_CREATEANACCOUNT,
        ECOM_LBL_WESENTYOUANEMAILFROM,
        ECOM_LBL_USCUSTOMERCAREINQUIRYEMAIL,
        ECOM_LBL_PLEASECHECKSPAMFOLDER
    }

    get customerCareInquiryEmail(){
        let email = 'mailto:';
        //RWPS-1925
        this.customerEmail = '';
        const cookieName = 'customer_email=';
        const decodedCookie = decodeURIComponent(document.cookie);
        const cookies = decodedCookie.split(';');
        
        for (let cookie of cookies) {
            cookie = cookie.trim();
            if (cookie.indexOf(cookieName) === 0) {
                this.customerEmail =  cookie.substring(cookieName.length, cookie.length);
            }
        }
        return email + this.customerEmail;
    }

    get createAnAccountLabel( ){
        return this.labels.ECOM_LBL_CREATEANACCOUNT.toLowerCase();
    }

    redirectToRegistrationPage(){
        let origin = window.location.origin;
        if(this.createAccountEndpoint == '' || this.createAccountEndpoint == undefined || this.createAccountEndpoint == null) {
            this.createAccountEndpoint = '/SelfRegister?ptcms=true';
        }
        window.location.href = origin + this.createAccountEndpoint;
    }

    redirectToLogin(){
        let origin = window.location.origin;
        if(this.loginPageEndpoint == '' || this.loginPageEndpoint == undefined || this.loginPageEndpoint == null) {
            this.loginPageEndpoint = '/login?ptcms=true';
        }
        window.location.href = origin + this.loginPageEndpoint;
    }
}