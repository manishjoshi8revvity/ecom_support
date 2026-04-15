import {LightningElement, api, wire} from 'lwc';
import isGuest from '@salesforce/user/isGuest';
import {CurrentPageReference} from "lightning/navigation";

//VRa-Punchout Changes - Feb 7 : Begin
import getUserNavigationConfig from '@salesforce/apex/ECOM_UserController.getUserNavigationConfig';
import encodeWebUserParams from '@salesforce/apex/ECOM_UserController.getCMSRedirectDataMap';
//VRa-Punchout Changes - Feb 7 : End

//VRa - punchout Changes | 22 Jan 2024 - begin
//labels
import LBL_CMS_PARAM_PREFIX  from '@salesforce/label/c.ECOM_CMSPunchoutLoginParameter';
import LBL_CMS_BUY_PAGE  from '@salesforce/label/c.ECOM_CMSBuyPage';
import LBL_URL_PATH_SEPARATOR from '@salesforce/label/c.ECOM_UrlPathSeparator';
import LBL_CMS_SHOP_PAGE from '@salesforce/label/c.ECOM_CMSShopPage';
import ECOM_LBL_CMSUSERLOGINPARAMETER from '@salesforce/label/c.ECOM_CMSUserLoginParameter';

//apex
import encodeUrlParams from '@salesforce/apex/ECOM_UserController.getEncyrptedSessionParametersForCMS';

//jsimport
import {getUserConfigData,parseJSON, setToSessionStorage, stringifyJSON} from 'c/ecom_punchoutUtil';
//VRa - punchout Changes | 22 Jan 2024 - end

const SESSION_KEY_USER_TYPE = 'userType';
export default class EcomNavigation extends LightningElement {

    url;

    _pageName;

    sitePageName;

    @api
    get pageName() {
        return this._pageName;
    }

    set pageName(val) {
        this._pageName = val;
    }

    //VRa: Punchout changes 22 Jan 2024 - begin
    labels = {
        LBL_CMS_PARAM_PREFIX,
        LBL_CMS_BUY_PAGE,
        LBL_URL_PATH_SEPARATOR,
        LBL_CMS_SHOP_PAGE,
        ECOM_LBL_CMSUSERLOGINPARAMETER
    }
    //VRa: Punchout changes 22 Jan 2024 - end

    @wire(CurrentPageReference)
    getPageReferenceParameters(currentPageReference)
    {
        if (currentPageReference)
        {
            this.url = currentPageReference.state?.url;
            this.sitePageName = currentPageReference.state?.page;
            if(currentPageReference.state.app !== 'commeditor')
            {
                let userConfig = getUserConfigData();
                //console.log('userConfig:: ', parseJSON(userConfig));//Remove after DEV
                if(userConfig && userConfig.isPunchoutUser){
                    this.navigateForPunchoutUser();
                }else {
                    //this.navigateToWebPage(); //VRa-Punchout Changes - Feb 7
                    //this.getUserNavigationComponent(); //VRa - ECOM-3482 - Session reroute changes Jul 11
                    this.reInitiateSessionForCmsUser();//VRa - ECOM-3482 - Session reroute changes Jul 11
                }
            }
        }
    }

    getUserNavigationComponent(){
        if(!isGuest){
            getUserNavigationConfig(
                { userType: 'cmsStoreUser'}
            ).then(result => {
                if(result.success){
                    const navData = result.responseData;
                    //console.log('navData:: ', navData);//Remove after DEV
                    setToSessionStorage(SESSION_KEY_USER_TYPE, stringifyJSON(navData));
                    this.navigateToWebPage();
                } else {
                    this.navigateToWebPage();
                }
            }).catch(err => {
                this.navigateToWebPage();
            });
        } else {
            this.navigateToWebPage()
        }
    }

    navigateToWebPage()
    {
        let  url=decodeURI(window.location.href);
        if(url.includes("?") && url.includes("redirectURL=")){
            let urlToRedirect = url.split("redirectURL=")[1];
            if(urlToRedirect.includes('&'))
            {
                urlToRedirect=urlToRedirect.split('&')[0];
            }
            //window.location.replace(urlToRedirect);
            window.location.href = urlToRedirect;
            return;
        }
        let redirectURL;
        if(isGuest)
        {
            redirectURL = this._pageName;
        }else if(this.url)
        {
            redirectURL = this.url;
        }else if(this.sitePageName)
        {
            redirectURL = '/' + this.sitePageName;
        }else
        {
            redirectURL = this._pageName;
        }
        window.open(redirectURL ,'_self');
    }



    navigateForPunchoutUser(){

        const queryParameters = window.location.search;
        const urlParameters = new URLSearchParams(queryParameters);
        console.log('urlParameters:: ', urlParameters);//Remove after DEV

        const redirectUrl = urlParameters.get('redirectURL');
        //VRa: Punchout changes 22 Jan 2024 - begin
        encodeUrlParams().then(result => {
            console.log('result:: '+ parseJSON(result));//Remove after DEV
            let urlParams = '';
            let baseUrl = '';
            if(result && result?.success && result?.responseData){
                baseUrl = (redirectUrl && redirectUrl != '') ? redirectUrl : responseData.Home;
                //RWPS-1817
                if(result.locale && result.locale != '' && baseUrl.indexOf(result.locale)==-1 && !redirectUrl){// RWPS-6502
                    if (baseUrl.substr(-1) != '/'){
                        baseUrl += this.labels.LBL_URL_PATH_SEPARATOR;
                    }
                    baseUrl = baseUrl +  result.locale;
                }
                urlParams = result.responseData;
                //RWPS-1817
                if (baseUrl.substr(-1) != '/' && !redirectUrl){// RWPS-6502
                    baseUrl += this.labels.LBL_URL_PATH_SEPARATOR;
                }

                // RWPS-6502 start
                let userData =
                  this.labels.LBL_CMS_PARAM_PREFIX + urlParams;

                if(baseUrl.includes('?') && userData.startsWith('?')){
                    userData = userData.replace('?', '&');
                }

                baseUrl = baseUrl + userData;
                // RWPS-6502 end
                window.location.href = baseUrl;
            } else {
                window.location.href = baseUrl;
            }
        }).catch(error => {
            window.location.href = redirectUrl;
        });
        //console.log('urlToRedirect:: ', urlToRedirect);//Remove after DEV
        //VRa: Punchout changes 22 Jan 2024 - end
    }

    //VRa - ECOM-3482 - Session reroute changes Jul 11
    reInitiateSessionForCmsUser(){
        const queryParameters = window.location.search;
        const urlParams = new URLSearchParams(queryParameters);
        const redirectURL = urlParams.get('redirectURL');
        encodeWebUserParams().then(result => {
            console.log('result::', result);//Remove after DEV
            if(result && result.success && result.responseData){
                let baseUrl = redirectURL && redirectURL != '' && redirectURL != undefined  && redirectURL != null ? redirectURL : result.Home;
                //RWPS-1817
                if(result.locale && result.locale!= '' && baseUrl.indexOf(result.locale) ==-1 && !redirectURL){// RWPS-6502
                    if (baseUrl.substr(-1) != '/'){
                        baseUrl += this.labels.LBL_URL_PATH_SEPARATOR;
                    }
                    baseUrl = baseUrl +  result.locale;
                }
                let urlParams = result.responseData;
                //RWPS-1817
                if (baseUrl.substr(-1) != '/' && !redirectURL){// RWPS-6502
                    baseUrl += this.labels.LBL_URL_PATH_SEPARATOR;
                }

                // RWPS-6502 start
                let userData =
                  this.labels.ECOM_LBL_CMSUSERLOGINPARAMETER + urlParams;

                if(baseUrl.includes('?') && userData.startsWith('?')){
                    userData = userData.replace('?', '&');
                }

                baseUrl = baseUrl + userData;

                console.log('reInitiateSessionForCmsUser.redirectUrl::', baseUrl);//Remove after DEV
                window.location.replace(baseUrl);
                // RWPS-6502 end
            } else {
                //nothing to do. cannot proceed without url params
            }
        }).catch(error => {
            //console.log('encodeWebUser:error::', error);//Remove after DEV
        })
    }
}