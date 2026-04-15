import { LightningElement, api, track, wire } from 'lwc'; //RWPS-4881
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation'; //RWPS-4881
import getOnlineOrders from '@salesforce/apex/ECOM_OrderHistoryController.getOnlineOrders'; //RWPS-4881
import getOfflineOrders from '@salesforce/apex/ECOM_OrderHistoryController.getOfflineOrders'; //RWPS-4881
import ECOM_ORDER_HISTORY_SEARCH_MISC_LABELS from '@salesforce/label/c.ECOM_ORDER_HISTORY_SEARCH_MISC_LABELS'; //RWPS-4881
import ECOM_ORDER_HISTORY_HELPTEXT from '@salesforce/label/c.ECOM_ORDER_HISTORY_HELPTEXT'; //RWPS-4881
import ssrc_ECOM_Theme from '@salesforce/resourceUrl/ssrc_ECOM_Theme';

const ORDER_FETCH_EVENT = 'orderfetch'; //RWPS-4881
const OPERATE_LOADER_EVENT = 'operateloader'; //RWPS-4881
const REDIRECTION_EVENT = 'redirection'; //RWPS-4881
const SEARCH_BOX_NORMAL_STYLING = 'search-box'; //RWPS-4881
const SEARCH_BOX_ERROR_STYLING = 'search-box-error'; //RWPS-4881
const UNIQUE_STRING_SEPERATOR = '*#*';//RWPS-4881
const TOOL_TIP_HIDDEN = 'toolTipHidden toolTipContainer';//RWPS-4881
const TOOL_TIP_VISIBLE = 'toolTipVisible toolTipContainer';//RWPS-4881

export default class Ecom_OrderHistorySearch extends NavigationMixin (LightningElement) {

    //RWPS-4881 - Start
    @api
    hierarchyNumber

    @track
    searchString = null;

    orderNotFound = false;

    @track
    onlineOrders;

    @track
    onlineAddonsOrders;

    @track
    partNoVsProductMap;

    @track
    offlineOrders;

    @track
    searchBoxStyling = SEARCH_BOX_NORMAL_STYLING;

    helptextStyling = TOOL_TIP_HIDDEN;

    questionMarkHelpText = ECOM_ORDER_HISTORY_HELPTEXT.split('##')[0];
    questionMarkHelpSubText = ECOM_ORDER_HISTORY_HELPTEXT.split('##')[1];
    selfServiceURL = ECOM_ORDER_HISTORY_HELPTEXT.split('##')[2];

    //RWPS-4881 - End

    //RWPS-4881 
    labels = {
        searchOrderHeader : ECOM_ORDER_HISTORY_SEARCH_MISC_LABELS.split(UNIQUE_STRING_SEPERATOR)[0],
        searchOrderSubHeader : ECOM_ORDER_HISTORY_SEARCH_MISC_LABELS.split(UNIQUE_STRING_SEPERATOR)[1],
        noResultFoundText : ECOM_ORDER_HISTORY_SEARCH_MISC_LABELS.split(UNIQUE_STRING_SEPERATOR)[2],
        noResultFoundSubText : ECOM_ORDER_HISTORY_SEARCH_MISC_LABELS.split(UNIQUE_STRING_SEPERATOR)[3],
        noResultFoundAdvanceSearchText : ECOM_ORDER_HISTORY_SEARCH_MISC_LABELS.split(UNIQUE_STRING_SEPERATOR)[4],
    }

    @track
    images = {
        questionMarkIcon: ssrc_ECOM_Theme + '/img/orderhistoryquestionmark.svg'
    }

    //RWPS-4881 
    @wire(CurrentPageReference)
    getURLParameters(currentPageReference) {
        // Checking whether the search term already present in URL parameters
        if (currentPageReference) {
            this.searchString = currentPageReference.state?.searchData ? currentPageReference.state.searchData : currentPageReference.state?.SearchData ? currentPageReference.state.SearchData : null;
        }
    }

    //RWPS-4881 
    connectedCallback() {
        this.fireOperateLoader(true);
        this.searchOrders();
    }

    //RWPS-4881 
    handleInput(event) {
        let timeout = null;
        clearTimeout(timeout);
        event.preventDefault();
        this.searchString = event && event.target && event.target.value ? event.target.value : null;
        timeout = setTimeout(() => {
            this.fireOperateLoader(true);
            this.searchOrders();
        }, 1000); // Added a delay of 1 sec after user completes the typing to trigger the search
    }

    //RWPS-4881
    async searchOrders() {
        await Promise.all([
            this.getSFOrders(),
            this.getSAPOrders()
        ]);
        let onlineOrdersExist = this.onlineOrders && this.onlineOrders.length > 0 ? true : false;
        let offlineOrdersExist = this.offlineOrders && this.offlineOrders.orders && this.offlineOrders.orders.length > 0 ? true : false;
        let addOnOrdersExist = this.onlineAddonsOrders && this.onlineAddonsOrders.length > 0 ? true : false;
        if (onlineOrdersExist == false && offlineOrdersExist == false && this.searchString != null && this.searchString != undefined && this.searchString != '') {
            this.orderNotFound = true;
            this.searchBoxStyling = SEARCH_BOX_ERROR_STYLING;
            this.fireOperateLoader(false);
        } else {
            this.orderNotFound = false;
            this.searchBoxStyling  = SEARCH_BOX_NORMAL_STYLING;
        }
        this.fireSendOrderData(onlineOrdersExist, offlineOrdersExist, addOnOrdersExist, this.onlineOrders, this.offlineOrders, this.onlineAddonsOrders);
    }

    //RWPS-4881 - function to fetch online orders from SF
    async getSFOrders() {
        await getOnlineOrders({ searchString: this.searchString })
        .then((result) => {
            if (!result) {
                this.onlineOrders = null;
            }
            else if (result) {
                this.onlineOrders = result && result.onlineOrders && result.onlineOrders.length > 0 ? JSON.parse(JSON.stringify(result.onlineOrders)) : null;
                this.onlineAddonsOrders = result && result.addOnOrders && result.addOnOrders.length > 0 ? JSON.parse(JSON.stringify(result.addOnOrders)) : null;
                this.partNoVsProductMap = result && result.partNoVsProductMap ? result.partNoVsProductMap : null;
            }
        }).catch((error) => {
            console.error(error);
            this.fireOperateLoader(false);
        });
    }

    //RWPS-4881 - function to fetch offline/SAP orders from SF
    async getSAPOrders() {
        await getOfflineOrders({ searchString: this.searchString, onlineOrdersTab : false })
        .then((result) => {
            if (!result) {
                    this.offlineOrders = null;
            }
            else if (result) {
                this.offlineOrders = result && result.orders && result.orders.length > 0 ? JSON.parse(JSON.stringify(result)) : null;
            }
        }).catch((error) => {
            console.error(error);
            this.fireOperateLoader(false);
        });
    }

    //RWPS-4881 - function to fire event to send order data to parent component
    fireSendOrderData(onlineOrdersExist, offlineOrdersExist, addOnOrdersExists, onlineOrders, offlineOrders, onlineAddonsOrders) {
        this.dispatchEvent(new CustomEvent(ORDER_FETCH_EVENT, {
            detail: {
                onlineOrderExists : onlineOrdersExist,
                offlineOrderExists : offlineOrdersExist,
                addOnOrdersExist : addOnOrdersExists,
                onlineOrderData : onlineOrders,
                offlineOrderData : offlineOrders,
                onlineAddonsOrders : onlineAddonsOrders,
                searchTerm : this.searchString,
                partNoVsProductMap : this.partNoVsProductMap
            }
        }));
    }

    //RWPS-4881 - function to fire event to operate loader
    fireOperateLoader(isLoading) {
        this.dispatchEvent(new CustomEvent(OPERATE_LOADER_EVENT, {
            detail: {
                isLoading : isLoading
            }
        }));
    }

    //RWPS-4881 - function to handle redirection
    handleRedirection(event) {
        this.dispatchEvent(new CustomEvent(REDIRECTION_EVENT, {}));
    }

    //RWPS-4881 - function to show helptext
    handleVisibleToolTip(event) {
        this.helptextStyling = TOOL_TIP_VISIBLE;
        setTimeout(() => {
            this.helptextStyling = TOOL_TIP_HIDDEN;
        }, 5000); // 1000 milliseconds = 1 second
    }

    handleSelfServiceRedirection(event) {
        window.open(this.selfServiceURL,'_blank');
    }
}