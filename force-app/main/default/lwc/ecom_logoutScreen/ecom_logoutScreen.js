import { LightningElement, api } from 'lwc';
import siteId from "@salesforce/site/Id";

import getHomeUrl from '@salesforce/apex/ECOM_CustomLoginController.getCMSUrl';

//import utils
import {setToLocalStorage,getCookieByName,deleteCookieByName, logoutUserAndRedirect} from 'c/ecom_util';

const PREFERRED_LANGUAGE_PREFIX = 'PreferredLanguage';
const STORED_LOCALE = 'storedLocale';
const IS_LOGOUT = 'isLogout';
const LOGOUT_REDIRECT_URL = 'logoutRedirectURL';
export default class Ecom_logoutScreen extends LightningElement {
    @api
    logoutMessage;

    //boolean
    isLoadLogout= false;

    //text
    logoutUrl='';

    //int
    delay = 1000;


    connectedCallback(){
        let isCSR = getCookieByName('apex__IsCSR');
        let csrId = getCookieByName('apex__csrId');
        if(isCSR ){
            deleteCookieByName('apex__IsCSR');
        }
        if(csrId){
            deleteCookieByName('apex__csrId');
        }
        this.handleLogout();
    }

    handleLogout(){
        getHomeUrl().then(result => {
            console.log('fetchCMSUrls:result:: ', result);//Remove after DEV
            if(result && result.success){
                this.logoutUrl = window.location.origin + '/secur/logout.jsp';

                logoutUserAndRedirect(this.delay, this.logoutUrl,result.responseData.Home, PREFERRED_LANGUAGE_PREFIX + siteId, STORED_LOCALE);
                // deleteCookieByName(PREFERRED_LANGUAGE_PREFIX + siteId);
                // setToLocalStorage(STORED_LOCALE,'');
                // setToLocalStorage(IS_LOGOUT, true);
                // setToLocalStorage(LOGOUT_REDIRECT_URL, result.responseData.Logout);

                // this.isLoadLogout = true;
                // setTimeout(() => {
                //     this.isLoadLogout = false;
                //     window.location.replace(result.responseData.Logout);
                // }, this.delay); 
            }
        }).catch(error => {
            console.log('fetchCMSUrls:error::', error);//Remove after DEV
        })
    }
    
}