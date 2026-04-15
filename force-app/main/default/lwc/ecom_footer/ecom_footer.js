import { LightningElement,api,wire } from 'lwc';
import ECOM_MESSAGE from '@salesforce/messageChannel/ecom_MessagingChannel__c';
import {publish, MessageContext} from 'lightning/messageService';
import FORM_FACTOR from '@salesforce/client/formFactor';
const NAVIGATE_TO_POLICIES = 'Policies';
const NAVIGATE_TO_CONTACTUS = 'ContactUs';
const CMS_NAVIGATION = 'CMSNavigation';
import isGuest from '@salesforce/user/isGuest';
export default class Ecom_footer extends LightningElement {

    leftSectionCSS='';
    middleSectionCSS='';
    rightSectionCSS='';
    @api
    device = {
        isMobile : FORM_FACTOR==='Small',
        isDesktop : FORM_FACTOR==='Large',
        isTablet :FORM_FACTOR==='Medium'
    }

    //variables
    isLoginOrRegistration = false;

    get isGuestUser(){
        return isGuest;
    }

    // get currentStyling() {
    //     let styling =
    // }

    @wire(MessageContext)
    messageContext;

    currentYear;

    connectedCallback(){
        this.currentYear =  new Date().getFullYear();

        //get current location
        const isLoginOrRegistration = window.location.href.indexOf('login') || window.location.href.indexOf('SelfRegister') ? true : false;
        this.loadBasedOnDeviceType();
    }

    loadBasedOnDeviceType() {
        var width = (window.innerWidth > 0) ? window.innerWidth : screen.width;
            //Tab UI fix - Gaurang - 17 July 2024 - to handle iPad Air which sometimes gets rendered as Large
            if(FORM_FACTOR==='Medium' || (width==1025)){
                this.leftSectionCSS = 'slds-col slds-large-size_1-of-2 slds-medium-size_1-of-2 slds-size_1-of-2 slds-text-align_left slds-no-print';
                this.middleSectionCSS = 'ecom-footer-condensed';
                this.rightSectionCSS = 'slds-col slds-large-size_1-of-2 slds-medium-size_1-of-2 slds-size_1-of-2 slds-small-size_1-of-2 ecom-div-grid ecom-text-align-end'
            }
            else{
                this.leftSectionCSS = 'slds-col slds-large-size_1-of-3 slds-medium-size_1-of-3 slds-size_1-of-3 slds-text-align_left slds-no-print';
                this.middleSectionCSS = 'slds-col slds-large-size_1-of-3 slds-medium-size_1-of-3 slds-size_1-of-3 ecom-div-grid slds-m-top_medium slds-p-left_medium';
                this.rightSectionCSS = 'slds-col slds-large-size_1-of-3 slds-medium-size_1-of-3 slds-size_1-of-3 slds-small-size_1-of-1 ecom-div-grid ecom-text-align-end';
            }
    }

    navigateToPolicies() {
        let payLoad = {message: NAVIGATE_TO_POLICIES,
            type: CMS_NAVIGATION
        };
        publish(this.messageContext, ECOM_MESSAGE, payLoad);
    }

    // RWPS-3826 START
    policiesEnter(event) {
        if (event.key === 'Enter' || event.keyCode === 13) {
            this.navigateToPolicies();
        }
    }
    // RWPS-3826 END

    navigateToContactUs() {
        let payLoad = {message: NAVIGATE_TO_CONTACTUS,
            type: CMS_NAVIGATION
        };
        publish(this.messageContext, ECOM_MESSAGE, payLoad);
    }

    // RWPS-3826 START
    contactUsEnter(event) {
        if (event.key === 'Enter' || event.keyCode === 13) {
            this.navigateToContactUs();
        }
    }
    // RWPS-3826 END
}