import { LightningElement, api, wire } from 'lwc';
import {NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import isGuestUser from '@salesforce/user/isGuest';
import basePath from '@salesforce/community/basePath';

//Apex
//import loginUser from '@salesforce/apex/ECOM_LoginController.loginUser';
import getMagicLinkImplementationActivationStatus from '@salesforce/apex/ECOM_CustomLoginController.getMagicLinkImplementationActivationStatus'; //RWPS-5938

//labels
import ECOM_LBL_ACCOUNT_LOGIN from '@salesforce/label/c.ECOM_AccountLogin';

//static resources
import sres_ECOM_CartIcons from '@salesforce/resourceUrl/ssrc_ECOM_Theme';

export default class Ecom_loginPage extends NavigationMixin(LightningElement) {

    
    @api pageToRedirectLoggedInUser = '/dashboard';
    @api isAutoRedirectToDashboardIfLoggedIn ;
    @api createAccountPage='SelfRegister';

    displayLoginPage = false;

    storeBasePath = basePath;

    quoteNumber; //RWPS-5938
    userRecord; //RWPS-5938
    userEmail; //RWPS-5938
    showMagicLinkWizard = false; //RWPS-5938
    quoteNumberPresent = false; //RWPS-5938
    magicLinkImplementationActive = false; //RWPS-5938

    labels = {
        ECOM_LBL_ACCOUNT_LOGIN
    }

    constructor() {
        super();
    }

    images = {
        loginpagelogo : sres_ECOM_CartIcons + '/img/revvity-logo-loginpage.svg'
    }

    get userPageStyling(){

        let styling = 'ecom-background-color';

        if(isGuestUser){
            styling = styling + ' ';
        } 

        return styling;
    }

    //RWPS-5938
    @wire(CurrentPageReference)
    getPageReferenceParameters(currentPageReference) {
        if (currentPageReference) {
            if (currentPageReference.state && currentPageReference.state.quoteNumber) {
                this.quoteNumber = currentPageReference.state.quoteNumber;
                this.quoteNumberPresent = true;
            } else if (currentPageReference.state && currentPageReference.state.secureAccessLinkEmailAddress) {
                this.userEmail = currentPageReference.state.secureAccessLinkEmailAddress ? currentPageReference.state.secureAccessLinkEmailAddress : '';
                this.quoteNumberPresent = true;
            } else {
                this.quoteNumberPresent = false;
            }
        } else {
            this.quoteNumberPresent = false;
        }
    }

    @wire(getMagicLinkImplementationActivationStatus)
    wiredMagicLinkImplementationActivationStatus({ error, data }) {
        if (data) {
            this.magicLinkImplementationActive = data;
            if (this.quoteNumberPresent == true && this.magicLinkImplementationActive == true) {
                this.showMagicLinkWizard = true;
            } else {
                this.showMagicLinkWizard = false;
            }
        } else if (error) {
            console.error('Error fetching secure access link implementation activation status: ', error);
            this.showMagicLinkWizard = false;
        }
    }

    connectedCallback(){

        if(!isGuestUser){
            console.log('basepath' , this.storeBasePath);//Remove after DEV
            console.log('basepath' , window.location.origin);//Remove after DEV
            const dashboardPath = window.location.origin +  this.pageToRedirectLoggedInUser;
            console.log('dashboardPath', dashboardPath);//Remove after DEV
            console.log('this.isAutoRedirectToDashboardIfLoggedIn', this.isAutoRedirectToDashboardIfLoggedIn);//Remove after DEV
            if((window.location.href.indexOf('builder') == -1 && window.location.href.indexOf('commeditor') == -1) && this.isAutoRedirectToDashboardIfLoggedIn){
                window.location.replace(dashboardPath); 
            }
            this.displayLoginPage = true;
        } else {
            this.displayLoginPage = true;
        }

    }

    // handleLogin(){
        
    //     loginUser().then(result => {
    //         console.log('result:: ', result);//Remove after DEV
    //     })
    // }

    redirectToPage(pageUrl){
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
                attributes: {
                    url: pageUrl
                }
        });
    }

    //RWPS-5938
    handleOpenMagicLinkWizard(event) {
        this.showMagicLinkWizard = true;
        this.userRecord = event?.detail?.userDetails ? event.detail.userDetails : null;
    }
}