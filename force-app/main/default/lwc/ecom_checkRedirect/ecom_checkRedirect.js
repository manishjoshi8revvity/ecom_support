import { LightningElement } from 'lwc';
import isGuest from '@salesforce/user/isGuest';

export default class Ecom_checkRedirect extends LightningElement {

    constructor(){
        super();

        const queryParameters = window.location.search;
        const urlParams = new URLSearchParams(queryParameters);
        const redirectTo = urlParams.get('redirectTo');
        //redirectTo = redirectTo ? redirectTo.toLowerCase() : null;
        const hash = window.location.hash || '';//RWPS-3306
        const baseUrl = window.location.origin;
        let navigateUserTo = baseUrl;
        console.log('FINAL CHECK REDIRECT navigate-->', navigateUserTo);
        
        //RWPS-3306 start - Store hash in sessionStorage if needed
        if (isGuest && hash) {
            sessionStorage.setItem('scrollTarget', hash);
        }//RWPS-3306 end
        if(isGuest){
            if(redirectTo && redirectTo != ''){
                const retUrl = redirectTo + hash;//RWPS-3306 
                //navigateUserTo += '/login?retURL=' + redirectTo;//RWPS-1014 - change by VRa Aug 9 2024
                navigateUserTo += '/login?ptcms=true&retUrl=' + encodeURIComponent(retUrl);//RWPS-1014 - change by VRa Aug 9 2024 RWPS-3306 - Added encodeURIComponent
            } else {
                navigateUserTo += '/' + 'login?ptcms=true';
            }
        } else {
            if(redirectTo && redirectTo != ''){
                //RWPS-3306 start
                navigateUserTo += '/' + redirectTo + hash;//RWPS-3306
            } else {
                navigateUserTo += '/' + 'dashboard';
            }
        }

        console.log('FINAL CHECK REDIRECT navigate 22-->', navigateUserTo);

        if(window.location.href.indexOf('builder') == -1 && window.location.href.indexOf('commeditor') == -1){
            window.location.replace(navigateUserTo);
        }

    }

}