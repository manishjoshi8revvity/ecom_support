import  { LightningElement } from 'lwc';

//apex
import fetchCMSUrls from '@salesforce/apex/ECOM_CustomLoginController.getCMSUrl';

//utils import
import {setToLocalStorage,getCookieByName,deleteCookieByName} from 'c/ecom_util';

const IS_LOGOUT = 'isLogout';
const LOGOUT_REDIRECT_URL = 'logoutRedirectURL';
export default class Ecom_logout extends LightningElement {

    connectedCallback()
    {
        let isCSR = getCookieByName('apex__IsCSR');
        let csrId = getCookieByName('apex__csrId');
        if(isCSR ){
            deleteCookieByName('apex__IsCSR');
        }
        if(csrId){
            deleteCookieByName('apex__csrId');
        }
        fetchCMSUrls().then(result => {
            if(result && result.success){
                setToLocalStorage(IS_LOGOUT, true);
                setToLocalStorage(LOGOUT_REDIRECT_URL, result.responseData.Logout);
                //this.continueLogout();
            }
        }).catch(error => {
            console.log('fetchCMSUrls:error::', error);//Remove after DEV
        })
    }

    continueLogout(){
        
        var url=window.location.href;
        var redirectURL='';
        if(url.includes('?'))
        {
            redirectURL=url.split('?redirectURL=')[1];
            this.handleLogout(redirectURL);
        }
        else
        {
            //window.location.replace('/secur/logout.jsp');
        }
    }

    async handleLogout(redirectURL) {
        await fetch('/secur/logout.jsp');
        //window.location.replace(redirectURL);
        //window.location.href = redirectURL;
    }
}