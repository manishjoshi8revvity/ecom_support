import { LightningElement,api,wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import ECOM_DATALAYERCHANNEL from '@salesforce/messageChannel/ecom_DataLayer__c';
import {publish, MessageContext} from 'lightning/messageService'
import ECOM_MESSAGE from '@salesforce/messageChannel/ecom_MessagingChannel__c';
import sres_ECOM_CartIcons from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import ECOM_CurrencyDisplayAs from '@salesforce/label/c.ECOM_CurrencyDisplayAs';
import ECOM_ItemsInCart from '@salesforce/label/c.ECOM_ItemsInCart';
import ECOM_ViewOrEdit from '@salesforce/label/c.ECOM_ViewOrEdit';
import ECOM_Qty from '@salesforce/label/c.ECOM_Qty';
import ECOM_Order_Summary from '@salesforce/label/c.ECOM_Order_Summary';
import ECOM_Subtotal from '@salesforce/label/c.ECOM_Subtotal';
import ECOM_Shipping from '@salesforce/label/c.ECOM_Shipping';
import ECOM_Tax from '@salesforce/label/c.ECOM_Tax';
import ECOM_Savings from '@salesforce/label/c.ECOM_Savings';
import ECOM_TotalCost from '@salesforce/label/c.ECOM_TotalCost';
import ECOM_Tariff_Surcharge from '@salesforce/label/c.ECOM_Tariff_Surcharge';
import ECOM_Free_Item from '@salesforce/label/c.ECOM_Free_Item';//RWPS-3811
import {processAndLogJSError} from 'c/ecom_util'; // RWPS-5153

const NAVIGATE_TO_PDP = 'PDP';
const CMS_NAVIGATION = 'CMSNavigation';
export default class Ecom_checkoutCartSummary extends NavigationMixin(LightningElement) {
    @api
    images = {
            prodimg: sres_ECOM_CartIcons + '/img/productimage.png' ,
            defaultProdImage : sres_ECOM_CartIcons + '/img/placeholder.png'//RWPS-1387
    }
    @api cartItems = [];
    @api cartSummary;
    @api cartItemCount;
    @api totalSaving;
    @api
    tariffSurchargeTotal; //RWPS-3026

    labels = {
        ECOM_ItemsInCart,
        ECOM_ViewOrEdit,
        ECOM_Qty,
        ECOM_Order_Summary,
        ECOM_Subtotal,
        ECOM_Shipping,
        ECOM_Tax,
        ECOM_Savings,
        ECOM_TotalCost,
        ECOM_Tariff_Surcharge, //RWPS-3026
        ECOM_Free_Item //RWPS-3811
    };
    fileName = 'ecom_checkoutCartSummary';//RWPS-5153
    moduleName = 'Checkout Management';//RWPS-5153

    //RWPS-3026 - Start
    get showTotalSurcharge(){
        if(this.tariffSurchargeTotal > 0){
            return true;
        }
        else{
            return false;
        }
    }

    get totalShippingCost(){
        return parseFloat(this.cartSummary?.totalChargeAmount) - parseFloat(this.tariffSurchargeTotal);//RWPS-3026
    }
     //RWPS-3026 - End

    //currencyDisplayAs ='code';//ECOM_CurrencyDisplayAs
    currencyDisplayAs = ECOM_CurrencyDisplayAs;
    @wire(MessageContext)
        messageContext;

    get showSavings(){
        if(this.totalSaving > 0){
            return true;
        }
        else{
            return false;
        }
    }

    get showCartItems(){
        return this.cartItems.length > 0;
    }

    get cartItemList(){
        return this.cartItems;
    }

    navigateBackToCart(){
        try {//RWPS-5153
            let url = window.location.href;
        let baseUrl =  url.split('/');
        let finalUrl = baseUrl[0]+'/cart';
            window.location.href = finalUrl;
        } catch (error) {//RWPS-5153
            processAndLogJSError(error, this.fileName, this.moduleName, 'navigateBackToCart');
        }//RWPS-5153 end
    }

    handlePublishMsg(data) {
        try {//RWPS-5153
            let payLoad = { 
                data: data, 
                type: 'CheckoutStep1DataLayer'
            };
            publish(this.messageContext, ECOM_DATALAYERCHANNEL, payLoad);
        } catch (error) {//RWPS-5153 
            processAndLogJSError(error, this.fileName, this.moduleName, 'handlePublishMsg');
        }//RWPS-5153 end
    }
    navigateToPDP(event) {
        let payLoad = {message: NAVIGATE_TO_PDP,
            type: CMS_NAVIGATION,
            partNumber: '',
            url:  event.currentTarget.dataset.url
        };
        publish(this.messageContext, ECOM_MESSAGE, payLoad);
        //Preparing data for select_item event which will be push to DataLayer
        try {
            this.prepareDataLayerData('select_item',this._item);
        } catch (error) {
            console.error('Error occured during preparing DataLayer data for select_item event ',error);
            processAndLogJSError(error, this.fileName, this.moduleName, 'navigateToPDP');//RWPS-5153 
        }
    }
}