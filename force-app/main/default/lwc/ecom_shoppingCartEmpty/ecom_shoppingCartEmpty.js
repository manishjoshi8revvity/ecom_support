import { LightningElement,api,track,wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import basePath from '@salesforce/community/basePath';
import sres_ECOM_CartIcons from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import ECOM_Cart_Empty  from '@salesforce/label/c.ECOM_Cart_Empty';
import ECOM_Back_to_Shopping  from '@salesforce/label/c.ECOM_Back_to_Shopping';
import ECOM_QuickOrder  from '@salesforce/label/c.ECOM_QuickOrder';
import ECOM_Favorites  from '@salesforce/label/c.ECOM_Favorites';
import {publish, MessageContext} from 'lightning/messageService';
import ECOM_MESSAGE from '@salesforce/messageChannel/ecom_MessagingChannel__c';
//VRA: Punchout changes 31 Jan 24 - Begin
//apex
import encodeUrlParams from '@salesforce/apex/ECOM_UserController.getEncyrptedSessionParametersForCMS';
//label
import LBL_URL_PATH_SEPARATOR from '@salesforce/label/c.ECOM_UrlPathSeparator';
import LBL_CMS_PARAM_PREFIX  from '@salesforce/label/c.ECOM_CMSPunchoutLoginParameter';
import LBL_CMS_BUY_PAGE  from '@salesforce/label/c.ECOM_CMSBuyPage';
//VRA: Punchout changes - end
//import js 
import {getUserConfigData, setToSessionStorage,SYSTEM_CONSTANTS,parseJSON} from 'c/ecom_punchoutUtil';

const NAVIGATE_TO_PLP = 'PLP';
const CMS_NAVIGATION = 'CMSNavigation';

export default class Ecom_shoppingCartEmpty extends NavigationMixin(LightningElement) {

    labels = {
        ECOM_Cart_Empty,
        ECOM_Back_to_Shopping,
        ECOM_QuickOrder,
        ECOM_Favorites,
        LBL_URL_PATH_SEPARATOR,
        LBL_CMS_PARAM_PREFIX,
        LBL_CMS_BUY_PAGE
    }

    isViewQuickOrder = true;
    @wire(MessageContext)
    messageContext;
    @api
    images = {
        cartimg: sres_ECOM_CartIcons + '/img/bag-line.png',
        deleteimg: sres_ECOM_CartIcons + '/img/delete-icon.png',
        quickorderimg:sres_ECOM_CartIcons + '/img/quick-order.png',
        favoriteimg:sres_ECOM_CartIcons + '/img/heart-line.png',
        helpimg:sres_ECOM_CartIcons + '/img/help-icon.png',
        termsimg:sres_ECOM_CartIcons + '/img/pencil-line.png',
        emptycartimg:sres_ECOM_CartIcons + '/img/emptycart.png',
        shopbag:sres_ECOM_CartIcons + '/img/shopbag.svg',
        quickordersvg:sres_ECOM_CartIcons + '/img/quickorder.svg',
        favsvg:sres_ECOM_CartIcons + '/img/heart-line.svg',
        emptycarticonsvg:sres_ECOM_CartIcons + '/img/emptycarticon.svg'
    }
    @track isModalOpen = false;

    get viewQuickOrder(){
        return this.isViewQuickOrder;
    }

    connectedCallback() {
        let userConfig = getUserConfigData();
        if(userConfig){
            this.isViewQuickOrder = userConfig.viewQuickOrder;
        }
    }

    openModal() {
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
    }
    showQuickOrder = false;
    
    handleOpenQuickOrder(){
        this.showQuickOrder = true;
        this.template.querySelector('c-ecom_quick-order')?.openModal();
    }

    handleQuickorderClose(event){
        if(event?.detail?.success){
            this.dispatchEvent(
                new CustomEvent('quickorderclose', {
                    detail: {
                        success: true
                    }
                })
            );
        }
    }

    navigateToFavoritesPage(){
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: basePath + '/favorites'
            }
        }).then((url) => {
            window.open(url, '_self');
        });
    }

    handleBackToShopping(){
        let userConfig = getUserConfigData();
        if(userConfig && userConfig.isPunchoutUser){
            let urlParams = '';
            encodeUrlParams().then(result => {
                if(result && result?.success && result?.responseData){
                    let baseUrl = result.Home;
                     //RWPS-1817
                    if(result.locale && result.locale != '' && baseUrl.indexOf(result.locale)==-1 ){
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
                    window.location.href = baseUrl + this.labels.LBL_CMS_BUY_PAGE + this.labels.LBL_CMS_PARAM_PREFIX + urlParams;//Remove after DEV
                } else {
                    this.navigateToPLP();
                }
            }).catch(error => {
            //do not console log
            });
        } else {
            this.navigateToPLP();
        }
    }

    navigateToPLP(){
        let payLoad = {
            message: NAVIGATE_TO_PLP,
            type: CMS_NAVIGATION,
        };
        publish(this.messageContext, ECOM_MESSAGE, payLoad);
    }
}