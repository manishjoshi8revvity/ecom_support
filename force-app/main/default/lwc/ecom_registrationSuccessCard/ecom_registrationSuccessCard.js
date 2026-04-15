import { LightningElement } from 'lwc';

//apex
import getCMSUrls from '@salesforce/apex/ECOM_RegistrationController.getCMSUrls';

//label
import ECOM_LBL_REGISTRATIONSUCCESSMESSAGE_RT from '@salesforce/label/c.ECOM_RegistrationSuccessRT';
import ECOM_LBL_THANKYOUFORREGISTERING from '@salesforce/label/c.ECOM_ThankYouForRegistering';
import ECOM_LBL_BACKTOHOMEPAGE from '@salesforce/label/c.ECOM_BackToHomePage';
import ECOM_LBL_WESENTANEMAILTO from '@salesforce/label/c.ECOM_WeSentAnEmailTo';
import ECOM_LBL_WITHALINKTOCREATEPASSWORD from '@salesforce/label/c.ECOM_WithALinkToCreatePassword';

export default class Ecom_registrationSuccessCard extends LightningElement {

    //boolean
    showSpinner = false;

    //text
    currentEmail = '';
    cmsStoreUrl = '';
    locale = '';

    //labels
    labels = {
        ECOM_LBL_REGISTRATIONSUCCESSMESSAGE_RT,
        ECOM_LBL_THANKYOUFORREGISTERING,
        ECOM_LBL_BACKTOHOMEPAGE,
        ECOM_LBL_WESENTANEMAILTO,
        ECOM_LBL_WITHALINKTOCREATEPASSWORD
    }

    get registrationSuccessTextRT() {
        let displayMessage = '';
        if(this.labels && this.labels.ECOM_LBL_REGISTRATIONSUCCESSMESSAGE_RT && this.currentEmail){
            displayMessage = this.labels.ECOM_LBL_REGISTRATIONSUCCESSMESSAGE_RT.replace('{1}', this.currentEmail);
        } else {
            displayMessage = this.labels.ECOM_LBL_REGISTRATIONSUCCESSMESSAGE_RT.replace('{1}', 'your email');
        }

        return displayMessage;
    }

    get currentEmail(){
        let email = 'your email';
        if(this.currentEmail && this.currentEmail != ''){
            email = this.currentEmail;
        }
        return email;
    }

    connectedCallback() {
        this.showSpinner = true;
        const queryParameters = window.location.search;
        const urlParams = new URLSearchParams(queryParameters);

        console.log('urlParams:: ', urlParams);//Remove after DEV
        if(urlParams.get('userEmail')) {
            this.currentEmail = urlParams.get('userEmail');
        }
        console.log('this.currentEmail::', this.currentEmail);//Remove after DEV
        this.loadBaseUrl();
    }

    loadBaseUrl(){
        getCMSUrls().then(result => {
            console.log('result:: ', result);//Remove after DEV

            if(result && result.success && result.responseData) {
                this.showSpinner = false;
                this.cmsStoreUrl = result.responseData.Home;
            }
        }).catch( error => {
            console.log('error:: ', error);//Remove after DEV
        })
    }

    handleRedirectToCMS() {
        let cmsUrl = this.cmsStoreUrl;
        if(this.locale) {
            cmsUrl = cmsUrl + '/' + this.locale
        } 

        window.location.replace(cmsUrl);
    }
}