import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

//apex methods
import updateCartWithPosrValues from '@salesforce/apex/ECOM_CartController.updateCartWithPosrValues';
import getUserNavigationConfig from '@salesforce/apex/ECOM_UserController.getUserNavigationConfig';
import getCMSRedirectDataMap from '@salesforce/apex/ECOM_UserController.getCMSRedirectDataMap';
import {getCookieByName,deleteCookieByName} from 'c/ecom_util'; //RWPS-2168

//custom label
import LBL_ERROR_PAGE from '@salesforce/label/c.ECOM_PunchoutErrorPage';
import LBL_PROCEED_TO_CMS from '@salesforce/label/c.ECOM_ProceedToCMS';
import LBL_CMS_PARAM_PREFIX  from '@salesforce/label/c.ECOM_CMSPunchoutLoginParameter';
import LBL_CMS_BUY_PAGE  from '@salesforce/label/c.ECOM_CMSBuyPage';
import LBL_CMSSHOPPAGE from '@salesforce/label/c.ECOM_CMSShopPage';
import LBL_CMS_PRODUCT_PAGE from '@salesforce/label/c.ECOM_CMSProductPage';
import LBL_URL_PATH_SEPARATOR from '@salesforce/label/c.ECOM_UrlPathSeparator';
import LBL_CMS_SITE_URL from '@salesforce/label/c.ECOM_CMSSiteUrl';//VRa ECOM-2555
import LBL_CMS_USER_LOGIN_PARAMETER from '@salesforce/label/c.ECOM_CMSUserLoginParameter';//VRa ECOM-2555
//import LBL_CMS_BASE_URL from '@salesforce/label/c.ECOM_CMSBaseUrl';

//js imports
import {setToSessionStorage, stringifyJSON} from 'c/ecom_punchoutUtil';

const SESSION_KEY_USER_TYPE = 'userType';
export default class Ecom_createSession extends NavigationMixin(LightningElement) {

    @api
    delay = 10000;

    labels = {
        LBL_ERROR_PAGE,
        LBL_PROCEED_TO_CMS,
        LBL_CMS_PARAM_PREFIX,
        LBL_CMS_BUY_PAGE,
        LBL_CMS_PRODUCT_PAGE,
        LBL_URL_PATH_SEPARATOR,
        LBL_CMS_SITE_URL,//VRa ECOM-2555
        LBL_CMS_USER_LOGIN_PARAMETER, //VRa ECOM-2555,
        LBL_CMSSHOPPAGE
    }

    constructor(){
        super();

    }

    isCSR ='';//RWPS-2168

    //boolean values
    showLoader = true;

    //String values
    userAccountId='';

    connectedCallback(){

        console.log('Create Session userAccountId:: ', this.userAccountId);//Remove after DEV

        this.punchCartValues();

    }

    

    punchCartValues(){
        //get url parameters
        const queryParameters = window.location.search;
        const urlParams = new URLSearchParams(queryParameters);
        console.log('Create Session urlParams:: ', urlParams);//Remove after DEV

        console.log(' Create Session urlParams.posr:: ', urlParams.get('posr'));//Remove after DEV
        
        const posr = urlParams.get('posr');
        const cmsParams = urlParams.get('cmsParams');
        const userType = urlParams.get('potype');

        let userLocale; //VRa ECOM-2555
        let redirectTo; //VRa ECOM-2555

        let poPart = '';
        if(urlParams.get('popart')){
            poPart = urlParams.get('popart');
        }

        if(urlParams.get('locale')){
            userLocale = urlParams.get('locale');
        }

        if(urlParams.get('redirectTo')){
            redirectTo = urlParams.get('redirectTo');
        }

        if(window.location.href.indexOf('commeditor') > -1){
            return;
        }

        console.log('cmsParams:: ', cmsParams);

        let paramMap = {
            posr: posr,
            cmsParams: cmsParams,
            urlParams: urlParams,
            popart: poPart,
            redirectTo: redirectTo,
            userType: userType,
            locale: userLocale
        }

        console.log('Create Session paramMap:: ', paramMap);//Remove after DEV

        getUserNavigationConfig(
            { userType: userType}
        ).then(result => {
            console.log('Create Session getUserNavigationConfig:result::', result);//Remove after DEV
            if(result.success){
                const navData = result.responseData;
                //this.navigationData = navData;
                setToSessionStorage(SESSION_KEY_USER_TYPE, stringifyJSON(navData));
                this.isCSR = getCookieByName('apex__IsCSR'); //RWPS-2795
                //VRa 2024.04.24 ECOM-2555 - begin 
                if(userType == 'cmsStoreUser' || this.isCSR){ //RWPS-2795
                    //get cms base url
                    if(urlParams.get('locale')){
                        userLocale = urlParams.get('locale');
                    }

                    getCMSRedirectDataMap({
                        cmsParams: cmsParams,
                        cmsLocale: userLocale,
                        redirectTo: redirectTo
                    }).then( result => {
                        console.log('getCMSRedirectDataMap:result:: ', result);//Remove after DEV

                        if(result && result.success && result.responseData){

                            this.proceedToCMS(urlParams, result);
                        } else {
                            //TBD: Handle this 
                        }
                            
                    }).catch(error => {
                        console.log('Exception:: ', error);//Remove after DEV
                    })
                    
                } else{
                    this.proceedToUpdatePosr(urlParams, paramMap);
                }
                //VRa 2024.04.24 ECOM-2555 - end
            } else {
                this.proceedToErrorPage();
                //this.proceedToUpdatePosr(urlParams, paramMap);
            }
        }).catch(err => {
            //console.error('fetchUserNavigationConfig -failed', err);//Remove after DEV
            this.proceedToErrorPage();
            //this.proceedToUpdatePosr(urlParams, paramMap);
        });        
    }


    proceedToUpdatePosr(urlParams, paramMap){
        if(urlParams.get('isNewUser')){
            setTimeout(() => {
                this.addPosrValuesToCart(paramMap);    
            }, parseInt(parseInt(this.delay)));
        } else {
            this.addPosrValuesToCart(paramMap);
        }
    }


    addPosrValuesToCart(paramMap){

        const urlParams = paramMap.urlParams;
        updateCartWithPosrValues({
            paramMap: paramMap
        }).then( result => {
            this.isCSR = getCookieByName('apex__IsCSR'); //RWPS-2168
            if((result.success && result.responseData) || this.isCSR){
                this.proceedToCMS(urlParams, result);
            } else {
                //redirect to error page
                this.proceedToErrorPage();
            }
        }).catch(error => {
            console.log('error:: ',error);//Remove after DEV
        })
    }

    proceedToCMS(urlParams, result){

        let redirectUrl ='';//= result.Home;
        let baseUrl = result?.Home;
        this.isCSR = getCookieByName('apex__IsCSR'); //RWPS-2168
        if(this.isCSR){
            let pageurl = urlParams.get('potype') && urlParams.get('potype') == 'cmsStoreUser'? this.labels.LBL_CMSSHOPPAGE :this.labels.LBL_CMS_BUY_PAGE ;
            redirectUrl =  baseUrl+pageurl;
            if (redirectUrl.substr(-1) != '/'){
                redirectUrl += this.labels.LBL_URL_PATH_SEPARATOR;
            } 
            redirectUrl+=this.labels.LBL_CMS_USER_LOGIN_PARAMETER + result.responseData;
            window.location.replace(redirectUrl);
        }else{
            //RWPS-1817
            if(result.locale && result.locale!= ''){
                if (baseUrl.substr(-1) != '/'){
                    baseUrl += this.labels.LBL_URL_PATH_SEPARATOR;
                } 
                baseUrl += result.locale;
            }
            if(this.labels.LBL_PROCEED_TO_CMS == 'true'){
                //check for product, redirect to product page
                if(result.productUrl && result.productUrl != 'null'){
                    redirectUrl = baseUrl + result.productUrl + this.labels.LBL_CMS_PARAM_PREFIX + result.responseData;
                } else {
                    //else home page
                    
                    if(urlParams.get('potype') && urlParams.get('potype') == 'cmsStoreUser'){
    
                        if(result && result.redirectTo  && (!result.profileRedirect || result.profileRedirect == '' || result.profileRedirect == undefined ||result.profileRedirect == null)){
                            if(result.redirectTo.indexOf('?') != -1){
                                redirectUrl = result.redirectTo + this.labels.LBL_CMS_USER_LOGIN_PARAMETER.replace('?', '&') + result.responseData;
                            } else {
                                redirectUrl = result.redirectTo + this.labels.LBL_CMS_USER_LOGIN_PARAMETER + result.responseData;
                            }
                        } else if(result && result.profileRedirect && result.profileRedirect != '' && result.profileRedirect != undefined && result.profileRedirect != null) {
                            redirectUrl = window.location.origin + this.labels.LBL_URL_PATH_SEPARATOR + result.profileRedirect + '&redirectTo=shop';
                        } else {
                            //shoppage: /shop	
                            redirectUrl = baseUrl + this.labels.LBL_CMSSHOPPAGE + this.labels.LBL_CMS_USER_LOGIN_PARAMETER + result.responseData;
                        }
                    } else {
                        //buypage:/	/buy-page
                        //RWPS-1817
                        if (baseUrl.substr(-1) != '/'){
                            baseUrl += this.labels.LBL_URL_PATH_SEPARATOR;
                        } 
                        redirectUrl = baseUrl+ this.labels.LBL_CMS_BUY_PAGE+this.labels.LBL_CMS_PARAM_PREFIX + result.responseData;
                    }
                }
                //Add buyer network domain to cms as new params Rwps-1115
                if(result?.punchout_domain){
                    redirectUrl+='&punchout_domain='+result?.punchout_domain;
                }
                window.location.replace(redirectUrl);
            } else {
                this.proceedToErrorPage();
            }
        }
    }

    proceedToErrorPage(){
        const errorPage = window.location.origin + this.labels.LBL_ERROR_PAGE;
        window.location.href = errorPage;
    }
}