import basePath from '@salesforce/community/basePath';
import ECOM_MESSAGE from '@salesforce/messageChannel/ecom_MessagingChannel__c';
import sres_ECOM_CartIcons from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import { MessageContext, publish } from 'lightning/messageService';
import { NavigationMixin } from 'lightning/navigation';
import { LightningElement, api, track, wire } from 'lwc';

import ECOM_Terms_Conditions  from '@salesforce/label/c.ECOM_Terms_Conditions';
import ECOM_Back_to_Shopping  from '@salesforce/label/c.ECOM_Back_to_Shopping';
import ECOM_QuickOrder  from '@salesforce/label/c.ECOM_QuickOrder';
import ECOM_Favorites  from '@salesforce/label/c.ECOM_Favorites';

//VRa - punchout Changes | 17 Jan 2024 - begin
//labels
import LBL_CMS_PARAM_PREFIX  from '@salesforce/label/c.ECOM_CMSPunchoutLoginParameter';
import LBL_CMS_BUY_PAGE  from '@salesforce/label/c.ECOM_CMSBuyPage';
import LBL_URL_PATH_SEPARATOR from '@salesforce/label/c.ECOM_UrlPathSeparator';

//apex
import encodeUrlParams from '@salesforce/apex/ECOM_UserController.getEncyrptedSessionParametersForCMS';

//jsimport 
import {getUserConfigData,parseJSON} from 'c/ecom_punchoutUtil';
import {processAndLogJSError} from 'c/ecom_util'; // RWPS-5153

//VRa - punchout Changes | 17 Jan 2024 - end

export default class Ecom_shoppingCartRedirects extends NavigationMixin(LightningElement) {

    labels = {
        ECOM_Terms_Conditions,
        ECOM_Back_to_Shopping,
        ECOM_QuickOrder,
        ECOM_Favorites,
        LBL_CMS_PARAM_PREFIX,
        LBL_CMS_BUY_PAGE,
        LBL_URL_PATH_SEPARATOR
    }

    @api
    images = {
        cartimg: sres_ECOM_CartIcons + '/img/bag-line.svg',
        deleteimg: sres_ECOM_CartIcons + '/img/delete-purple.svg',
        quickorderimg:sres_ECOM_CartIcons + '/img/quick-order.svg',
        favoriteimg:sres_ECOM_CartIcons + '/img/heart-line.svg',
        helpimg:sres_ECOM_CartIcons + '/img/help-icon.svg',
        termsimg:sres_ECOM_CartIcons + '/img/pencil-line.svg',
        radIcon:sres_ECOM_CartIcons + '/img/radIcon.svg',
    }

    @track isModalOpen = false;
    @wire(MessageContext)
    messageContext;

    /** VRa- punchout changes - begin */
    //local properties

    //boolean
    isViewQuickOrder = true;
    fileName='ecom_shoppingcartredirects';//RWPS-5153
    moduleName='ECOM_CartService';//RWPS-5153

    connectedCallback(){
        let userConfig = getUserConfigData();
        if(userConfig){
            this.isViewQuickOrder = userConfig.viewQuickOrder;
        }
        
    }
    /** VRa- punchout changes - end */

    navigateToHomePage() {
        try {//RWPS-5153
        console.log('navigateToHomePage:: called');//Remove after DEV
        /** VRa: punchout changes | 17 Jan 2024 - Begin */
        let payLoad = {message: 'PLP',
            type: 'CMSNavigation'
        };
       // publish(this.messageContext, ECOM_MESSAGE, payLoad);
        console.log('navigateToHomePage:: called');//Remove after DEV
        let userConfig = getUserConfigData();
        if(userConfig && userConfig.isPunchoutUser){
            let urlParams = '';
            encodeUrlParams().then(result => {
                console.log('result:: '+ parseJSON(result));//Remove after DEV
                if(result && result?.success && result?.responseData){
                    let baseUrl = result.Home;
                    //RWPS-1817
                    if(result.locale && result.locale != '' && baseUrl.indexOf(result.locale)==-1){
                        if (baseUrl.substr(-1) != '/'){
                            baseUrl += this.labels.LBL_URL_PATH_SEPARATOR;
                        }
                        baseUrl = baseUrl +  result.locale;
                    }
                    urlParams = result.responseData;
                    //RWPS-1817 append slash on if needed
                    if (baseUrl.substr(-1) != '/'){
                        baseUrl += this.labels.LBL_URL_PATH_SEPARATOR;
                    }
                //console.log('urlParams:: ', urlParams);//Remove after DEV
                //console.log('urlParams url:: ', this.cmsHomeBaseUrl + this.labels.LBL_CMS_BUY_PAGE + this.labels.LBL_CMS_PARAM_PREFIX + urlParams);//Remove after DEV
                    window.location.href = baseUrl + this.labels.LBL_CMS_BUY_PAGE + this.labels.LBL_CMS_PARAM_PREFIX + urlParams;//Remove after DEV
                } else {
                    publish(this.messageContext, ECOM_MESSAGE, payLoad);
                }
            }).catch(error => {//RWPS-5153 
                processAndLogJSError(error, this.fileName, this.moduleName, 'navigateToHomePage.encodeUerlParams');
            });
        } else {
            publish(this.messageContext, ECOM_MESSAGE, payLoad);
        }
       /** VRa: punchout changes | 17 Jan 2024 - End */
    } catch(error) {//RWPS-5153 start
         processAndLogJSError(error, this.fileName, this.moduleName, 'navigateToHomePage');
    }//RWPS-5153 end
    }

    navigateToFavoritesPage(){
    try{//RWPS-5153  
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: basePath + '/favorites'
            }
        }).then((url) => {
            window.open(url, '_self');
        });
    }catch(error) {//RWPS-5153 start
        processAndLogJSError(error, this.fileName, this.moduleName, 'navigateToFavoritesPage');
    }//RWPS-5153 end
    }

    handleTermCodition(){
    try {//RWPS-5153
          let payLoad = {message: 'Terms & Conditions',
            type: 'CMSNavigation'
        };
        publish(this.messageContext, ECOM_MESSAGE, payLoad);
    } catch (error) {//RWPS-5153 start
        processAndLogJSError(error, this.fileName, this.moduleName, 'handleTermCondition');
    }//RWPS-5153 end
    }

    navigateToQuickOrderPage(){
        try{//RWPS-5153 
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__webPage',
                attributes: {
                    url: basePath + '/quickorder'
                }
            }).then((url) => {
                window.open(url, '_self');
            });
        }catch(error) {//RWPS-5153 start
            processAndLogJSError(error, this.fileName, this.moduleName, 'navigateToQuickOrderPage');
        }//RWPS-5153 end
    }
}