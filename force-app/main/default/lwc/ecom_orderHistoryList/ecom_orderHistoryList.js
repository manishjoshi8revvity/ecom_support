import { LightningElement, api, track, wire } from 'lwc';
import communityId from '@salesforce/community/Id';
import { NavigationMixin } from 'lightning/navigation';
import getMyOrders from '@salesforce/apex/ECOM_OrderHistoryController.getMyOrders';
import fetchProductUnavailability from '@salesforce/apex/ECOM_OrderHistoryController.fetchProductUnavailability'; //RWPS-4621
import findOrder from '@salesforce/apex/ECOM_OrderHistoryController.findOrderByOrderNumberAndZip';
import checkIfCurrentUserIsPunchoutUser from '@salesforce/apex/ECOM_OrderHistoryController.checkIfCurrentUserIsPunchoutUser'; // RWPS-4196
import getEncodedValues from '@salesforce/apex/ECOM_OrderHistoryController.getEncodedValues'; // RWPS-4881
import fetchSalesOrg from '@salesforce/apex/ECOM_OrderHistoryController.fetchSalesOrg'; // RWPS-4881
import contextApi from 'commerce/contextApi';
import addItemsToCart from '@salesforce/apex/ECOM_CartController.addItemsToCart';
import ssrc_ECOM_Theme from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { isCmsResource, resolve } from 'experience/resourceResolver';
import ECOM_DATALAYERCHANNEL from '@salesforce/messageChannel/ecom_DataLayer__c';
import { MessageContext, publish } from 'lightning/messageService';
import ECOM_MESSAGE from '@salesforce/messageChannel/ecom_MessagingChannel__c';
import ECOM_105105 from '@salesforce/label/c.ECOM_105105';
import TEXT_ORDERS from '@salesforce/label/c.ECOM_Orders';
import { trackAddProductToCart } from 'commerce/activitiesApi'; //RWPS-3125
import ECOM_REPLACEMENT_MSG from '@salesforce/label/c.ECOM_REPLACEMENT_MSG';//RWPS-4621
import ECOM_INDIRECT_REPLACEMENT_MSG from '@salesforce/label/c.ECOM_INDIRECT_REPLACEMENT_MSG';//RWPS-4621
import ECOM_DISCONTINUE_MSG from '@salesforce/label/c.ECOM_DISCONTINUE_MSG';//RWPS-4621
import ECOM_105103 from '@salesforce/label/c.ECOM_105103';//RWPS-4621
import { getRecord } from 'lightning/uiRecordApi'; //RWPS-4881
import Hierarchy_Number from '@salesforce/schema/User.Contact.Default_Ship_to_ERP_Address__r.Master_Address__r.ERP_Customer_Base_Number__c'; //RWPS-4881
import USER_ID from "@salesforce/user/Id"; //RWPS-4881
import ECOM_ORDER_HISTORY_SEARCH_MISC_LABELS from '@salesforce/label/c.ECOM_ORDER_HISTORY_SEARCH_MISC_LABELS'; //RWPS-4881
import ECOM_SELF_SERVICE_LINKOUT from '@salesforce/label/c.ECOM_SELF_SERVICE_LINKOUT'; //RWPS-4881
import ECOM_Order_History_Advance_Search_Tool_Text from '@salesforce/label/c.ECOM_Order_History_Advance_Search_Tool_Text'; //RWPS-5286

//import js utils
import { getFromSessionStorage, SYSTEM_CONSTANTS, parseJSONWOStringify, getUserConfigData } from 'c/ecom_punchoutUtil'

const NAVIGATE_TO_PLP = 'PLP';
const CMS_NAVIGATION = 'CMSNavigation';
const ALL_ORDERS = 'all-orders'; //RWPS-4881
const ONLINE_ORDERS = 'online-orders'; //RWPS-4881
const ACTIVE_TAB_1 = 'activeTab1' //RWPS-4881
const ACTIVE_TAB_2 = 'activeTab2' //RWPS-4881
const INACTIVE_TAB_1 = 'inactiveTab1' //RWPS-4881
const INACTIVE_TAB_2 = 'inactiveTab2' //RWPS-4881
const INACTIVE_DISABLED_TAB_1 = 'inactiveTab1 disabledTab' //RWPS-4881
const INACTIVE_DISABLED_TAB_2 = 'inactiveTab2 disabledTab' //RWPS-4881
const UNIQUE_STRING_SEPERATOR = '*#*';//RWPS-4881
const QUERY_PARAM_START_CHARACTER = '?';//RWPS-4881
const HIERARCHY_NUMBER = 'hierarchyNumber';//RWPS-4881
const EQUALS_SYMBOL = '=';//RWPS-4881
const AND_SYMBOL = '&';//RWPS-4881
const SEARCH_DATA = 'searchData';//RWPS-4881
const SALES_ORG = 'salesOrg';//RWPS-4881

export default class Ecom_orderHistoryList extends NavigationMixin(LightningElement) {

    @api myOrders;
    ordersToDisplay = [];
    isOrderHistoryPage = false;
    totalOrders;
    defaultListSize = 5;
    nextLoadCount = 0;
    currentPageNumber = 1;
    fromRecords = 0; //RWPS-95 : garora@rafter.one - 29 April 2024 - for records counter
    toRecords = this.defaultListSize; //RWPS-95 : garora@rafter.one - 29 April 2024 - for records counter
    isLoadMore = false;
    isShowModal = false;
    orderNumber = '';
    shippingZip = '';
    isFindOrderDisabled = true;
    showSpinner = true;
    sfOrder = true;
    sapOrder = false;
    showErrorMsg = false;
    findOrderBtnClass;
    erroneousPartsToDisplay = [];
    successfulParts = [];
    showMessagePage = false;
    showErrorParts = false;
    showSuccessParts = false;
    modalSize = '';
    @track showOrders = false;
    @wire(MessageContext)
    messageContext;
    currencyDisplayAs = 'code';
    isPunchoutUser = false;
    partNoVsProductMap = new Map();
    //orderItems;

    sidebarCSS = '';
    middleSpaceCSS = '';

    @api
    device = {
        isMobile: FORM_FACTOR === 'Small',
        isDesktop: FORM_FACTOR === 'Large' || FORM_FACTOR === 'Medium'
    }
    @track
    images = {
        arrowimg: ssrc_ECOM_Theme + '/img/rightarrow.png',
        againimg: ssrc_ECOM_Theme + '/img/again.png',
        orderagain: ssrc_ECOM_Theme + '/img/orderagainpurple.svg', //RWPS-95 : garora@rafter.one - 28 April 2024 - change as per latest figma
        rightarrow: ssrc_ECOM_Theme + '/img/rightarrow.svg',
        onlineOrderIcon: ssrc_ECOM_Theme + '/img/onlineorder.svg',
        offlineOrderIcon: ssrc_ECOM_Theme + '/img/offlineorder.svg',
    }

    //RWPS-4881
    @track selectedTab = ONLINE_ORDERS;
    @track tab1class = ACTIVE_TAB_1;
    @track tab2class = INACTIVE_TAB_2;
    //RWPS-4881
    #escapeKeyCallback; // RWPS-4087

    @track
    discontinuedAndNonSellableProductDetails; //RWPS-4621 : Collection to hold unavailable product details

    //RWPS-4881 - Start
    @track
    onlineOrders;

    @track
    offlineOrders;

    @track
    combinedOrders;

    ordersNotFound = false;
    onlineOrderExists = true;
    offlineOrderExists = true;
    CurrentUser = USER_ID; //RWPS-4881
    hierarchyNumber;
    searchTerm;
    orderHistoryEmpty = false;
    showTabs = true;
    onlineOrdersCount = 0;
    allOrdersCount = 0;
    showOnlineOrdersTab = false;
    showAllOrdersTab = false;
    //RWPS-4881 - End

    label = {
        ordersHeader: TEXT_ORDERS, //RWPS-4881
        noResultFoundText : ECOM_ORDER_HISTORY_SEARCH_MISC_LABELS.split(UNIQUE_STRING_SEPERATOR)[2], //RWPS-4881
        noResultFoundSubText : ECOM_ORDER_HISTORY_SEARCH_MISC_LABELS.split(UNIQUE_STRING_SEPERATOR)[3], //RWPS-4881
        noResultFoundAdvanceSearchText : ECOM_ORDER_HISTORY_SEARCH_MISC_LABELS.split(UNIQUE_STRING_SEPERATOR)[4], //RWPS-4881
        onlineOrdersText : ECOM_ORDER_HISTORY_SEARCH_MISC_LABELS.split(UNIQUE_STRING_SEPERATOR)[5], //RWPS-4881
        offlineOrdersText : ECOM_ORDER_HISTORY_SEARCH_MISC_LABELS.split(UNIQUE_STRING_SEPERATOR)[6], //RWPS-4881,
        advanceSearchToolText: ECOM_Order_History_Advance_Search_Tool_Text.split(UNIQUE_STRING_SEPERATOR)[0], //RWPS-5286
        advanceSearchToolLink: ECOM_Order_History_Advance_Search_Tool_Text.split(UNIQUE_STRING_SEPERATOR)[1] //RWPS-5286
    }

    //RWPS-4881 : This function fetches the mapping information and hierarchy number
    @wire(getRecord, {recordId: '$CurrentUser',fields: [Hierarchy_Number]}) userRecord({ error, data }) {
        try {
            if (data) {
                this.hierarchyNumber = data?.fields?.Contact?.value?.fields?.Default_Ship_to_ERP_Address__r?.value?.fields?.Master_Address__r?.value?.fields?.ERP_Customer_Base_Number__c.value != null ? data?.fields?.Contact?.value?.fields?.Default_Ship_to_ERP_Address__r?.value?.fields?.Master_Address__r?.value?.fields?.ERP_Customer_Base_Number__c.value : null
            }
        } catch(error) {
            console.error(error);
        }

    }

    //RWPS-4881
    @wire(fetchSalesOrg) salesOrgDetails;

    // RWPS-5286 start
    get showAdvancedSearchInListing() {
        return this.searchTerm?.trim();
    }

    get selfServiceHomeLink() {
        return ECOM_SELF_SERVICE_LINKOUT.split(',')[0];
    }
    // RWPS-5286 end

    get webUserView() {
        return !this.isPunchoutUser;
    }

    get punchoutUserView() {
        if (this.isPunchoutUser) {
            this.sapOrder = true;
            this.sfOrder = false;
        }
        return this.isPunchoutUser;
    }

    handleTabClick(event) {
        const tabClicked = event.target.dataset.tab;
        this.selectedTab = tabClicked;
        if (this.selectedTab == 'tab2') {
            this.tab2class = ACTIVE_TAB_2;
            this.tab1class = INACTIVE_TAB_1
            this.sapOrder = true;
            this.sfOrder = false;
            let componentReference = this;
            setTimeout(() => {
                componentReference.template.querySelector('c-ecom_sap-order-history-list').getMyOrders();
            }, 100);
        }
        else {
            this.tab1class = ACTIVE_TAB_1;
            this.tab2class = INACTIVE_TAB_2;
            this.sfOrder = true;
            this.sapOrder = false;
            this.getOrdersInIt();
        }
    }

    get sortOption() {
        return [
            { label: 'Sort by: Oldest', value: 'oldest' }, //RWPS-95 : garora@rafter.one - 28 April 2024 - change as per latest figma
            { label: 'Sort by: Newest', value: 'newest' } //RWPS-95 : garora@rafter.one - 28 April 2024 - change as per latest figma
        ];
    }

    get resolvedEffectiveAccountId() {
        const effectiveAccountId = this.effectiveAccountId || '';
        let resolved = null;
        if (
            effectiveAccountId.length > 0 &&
            effectiveAccountId !== '000000000000000'
        ) {
            resolved = effectiveAccountId;
        }
        return resolved;
    }

    get gridForDashBoard() {
        return this.isOrderHistoryPage ? 'slds-size_12-of-12 slds-large-size_8-of-12 slds-medium-size_12-of-12 slds-small-size_12-of-12 order-col-ipad' : 'slds-size_12-of-12 slds-large-size_12-of-12 slds-medium-size_12-of-12 slds-small-size_12-of-12 order-col-ipad' //RWPS-3339
    }

    /* get orderHistoryEmpty() {
        return this.ordersToDisplay?.length == 0 ? true : false;
    } */

    // async getOrdersInIt() {
    //     await getMyOrders({})
    //         .then((result) => {
    //             if (result) {
    //                 console.log('1');
    //                 //this.showSpinner = false;
    //                 this.myOrders = [];
    //                 this.ordersToDisplay = [];

    //                 //RWPS-4621 Start
    //                 let productIds = [];
    //                 for (let i = 0; i < result.length; i++) {
    //                     let order = result[i];
    //                     if (order && order.OrderItems && order.OrderItems.length > 0) {
    //                         for (let j = 0; j < order.OrderItems.length; j++) {
    //                             let orderItem = order.OrderItems[j];
    //                             if (orderItem && orderItem.Product2 && orderItem.Product2.Id) {
    //                                 productIds.push(orderItem.Product2.Id);
    //                             }
    //                         }
    //                     }
    //                 }
    //                 fetchProductUnavailability({ productIdList: productIds })
    //                 .then((productData) => {
    //                     this.discontinuedAndNonSellableProductDetails = JSON.parse(JSON.stringify(productData));
    //                     for (let i = 0; i < result.length; i++) {
    //                         let order = result[i];
    //                         let orderNum;
    //                         if (order.ECOM_SAP_Order_Number__c) {
    //                             orderNum = order.ECOM_SAP_Order_Number__c;
    //                         }
    //                         else {
    //                             orderNum = order.OrderNumber;
    //                         }
    //                         let unavailableProductDetails = this.setNonAvailableProductDetails(order);
    //                         //RWPS-4621 End
    //                         this.myOrders.push({
    //                             Id: order.Id,
    //                             OrderNumber: orderNum,
    //                             OrderedDate: order.OrderedDate,
    //                             Status: order.Status == 'Pending Review' || order.Status == 'Rejected' ? order.Status : order.ECOM_Order_Summary_Status__c,
    //                             TotalAmount: order.TotalAmount,
    //                             GrandTotalAmount: order.GrandTotalAmount,
    //                             OrderProductLineCount: order.ECOM_Total_Items__c, //ECOM-3150 - garora@rafter.one - mapping to new rollup field for getting sum of quantities
    //                             orderItems: order.OrderItems,
    //                             currencyIsoCode: order.CurrencyIsoCode,
    //                             poNumber: order.PoNumber, //ECOM-95 - garora@rafter.one - to display po number on front end
    //                             InvoiceCount: order.Invoices__r?.length, //ECOM-95 - garora@rafter.one - getting invoice count
    //                             invoices: order.Invoices__r,
    //                             discontinuedDetails: unavailableProductDetails.discontinuedProductDetails, //RWPS - 4621
    //                             notSellableDetails: unavailableProductDetails.nonSellableProductDetails, //RWPS - 4621
    //                             isAllDiscontinuedProducts: unavailableProductDetails.allDiscontinuedProducts //RWPS - 4621
    //                         });
    //                     }

    //                     //this.sortData('OrderedDate', 'desc'); //RWPS-3741
    //                     this.totalOrders = this.myOrders.length;
    //                     //update default size
    //                     this.nextLoadCount = this.defaultListSize;
    //                     if (this.defaultListSize > this.totalOrders) {
    //                         this.nextLoadCount = this.totalOrders;
    //                         this.toRecords = this.totalOrders; //RWPS-95 : garora@rafter.one - 28 April 2024 - taking totalRecords as toRecords if smaller than defaultsize
    //                     }

    //                     for (let i = 0; i < this.nextLoadCount; i++) {
    //                         this.ordersToDisplay.push(this.myOrders[i]);
    //                     }
    //                     if (this.ordersToDisplay.length) {
    //                         this.showOrders = true;
    //                     }
    //                     if (this.totalOrders > this.defaultListSize) {
    //                         this.isLoadMore = true;
    //                     }

    //                 }).catch((productError) => {
    //                     this.showSpinner = false;
    //                 });
    //                 this.showSpinner = false;
    //             }
    //         }).catch((error) => {
    //             this.showSpinner = false;
    //         });
    // }

    async getOrdersInIt() {
        this.showSpinner = true;
        this.myOrders = [];
        this.ordersToDisplay = [];

        try {
            const result = await getMyOrders({});
            if (!result || result.length === 0) {
                this.showSpinner = false;
                return;
            }
            //RWPS-4621 start
            let productIds = [];
            for (let i = 0; i < result.length; i++) {
                let order = result[i];
                if (order && order.OrderItems && order.OrderItems.length > 0) {
                    for (let j = 0; j < order.OrderItems.length; j++) {
                        let orderItem = order.OrderItems[j];
                        if (orderItem && orderItem.Product2 && orderItem.Product2.Id) {
                            productIds.push(orderItem.Product2.Id);
                        }
                    }
                }
            }

            const productData = await fetchProductUnavailability({ productIdList: productIds });
            this.discontinuedAndNonSellableProductDetails = JSON.parse(JSON.stringify(productData));

            for (let i = 0; i < result.length; i++) {
                let order = result[i];
                let orderNum;
                if (order.ECOM_SAP_Order_Number__c) {
                    orderNum = order.ECOM_SAP_Order_Number__c;
                }
                else {
                    orderNum = order.OrderNumber;
                }
                let unavailableProductDetails = this.setNonAvailableProductDetails(order, true);
                //RWPS-4621 End
                this.myOrders.push({
                    isOnlineOrder: true,
                    Id: order.Id,
                    OrderNumber: orderNum,
                    OrderedDate: order.OrderedDate,
                    Status: order.Status == 'Pending Review' || order.Status == 'Rejected' ? order.Status : order.ECOM_Order_Summary_Status__c,
                    TotalAmount: order.TotalAmount,
                    GrandTotalAmount: order.GrandTotalAmount,
                    OrderProductLineCount: order.ECOM_Total_Items__c, //ECOM-3150 - garora@rafter.one - mapping to new rollup field for getting sum of quantities
                    orderItems: order.OrderItems,
                    currencyIsoCode: order.CurrencyIsoCode,
                    poNumber: order.PoNumber, //ECOM-95 - garora@rafter.one - to display po number on front end
                    InvoiceCount: order.Invoices__r?.length, //ECOM-95 - garora@rafter.one - getting invoice count
                    invoices: order.Invoices__r,
                    discontinuedDetails: unavailableProductDetails.discontinuedProductDetails, //RWPS - 4621
                    notSellableDetails: unavailableProductDetails.nonSellableProductDetails, //RWPS - 4621
                    isAllDiscontinuedProducts: (unavailableProductDetails && unavailableProductDetails.allDiscontinuedProducts && unavailableProductDetails.allDiscontinuedProducts == true) || (unavailableProductDetails && unavailableProductDetails.allNonSellableProducts && unavailableProductDetails.allNonSellableProducts == true) ? true : false, //RWPS-5230
                    iconStyle: this.images.onlineOrderIcon, //RWPS-4881
                    isWebOrder : true //RWPS-5286
                });
            }

            //this.sortData('OrderedDate', 'desc'); //RWPS-3741
            this.totalOrders = this.myOrders.length;
            //update default size
            this.nextLoadCount = this.defaultListSize;
            if (this.defaultListSize > this.totalOrders) {
                this.nextLoadCount = this.totalOrders;
                this.toRecords = this.totalOrders; //RWPS-95 : garora@rafter.one - 28 April 2024 - taking totalRecords as toRecords if smaller than defaultsize
            }

            for (let i = 0; i < this.nextLoadCount; i++) {
                this.ordersToDisplay.push(this.myOrders[i]);
            }
            if (this.ordersToDisplay.length) {
                this.showOrders = true;
            }
            if (this.totalOrders > this.defaultListSize) {
                this.isLoadMore = true;
            }

        } catch (error) {
            console.error('Error loading orders:', error);
        } finally {
            this.showSpinner = false;
        }
    }


    connectedCallback() {
        this.showSpinner = true; //RWPS-4881

        // RWPS-4196 - START
        checkIfCurrentUserIsPunchoutUser({
        }).then((userResult) => {

            // RWPS-4196 Set the variables that needs to be set if current user is punchout user
            if (userResult) {
                this.isPunchoutUser = true;
                this.isOrderHistoryPage = true;
            }

            // RWPS-4196 - Moved the existing logic to run after the checkIfCurrentUserIsPunchoutUser is executed. Commented below code and added code above.
            /*let userConfig = getUserConfigData();
             if(userConfig){
                 this.isPunchoutUser = userConfig['isPunchoutUser'];
                 if(this.isPunchoutUser) {
                     this.isOrderHistoryPage = true;
                     this.sapOrder = true;
                     this.sfOrder = false;
                 }
             }*/

            if (window.location.href.indexOf("orderHistory") != -1) {
                this.isOrderHistoryPage = true;
            }
            const result = contextApi.getSessionContext();
            result.then((response) => {
                this.effectiveAccountId = response.effectiveAccountId;
                if (!this.isPunchoutUser && this.isOrderHistoryPage == false) {
                    this.getOrdersInIt(); //RWPS-4881
                }
            }).catch((error) => {
                this.showSpinner = false;
            });
            this.loadBasedOnDeviceType();
            // RWPS-4087 start
            this.#escapeKeyCallback = this.escapeKeyCallback.bind(this);
            document.addEventListener('keydown', this.#escapeKeyCallback);
        }).catch((error) => {
            console.error(error);
            this.showSpinner = false; //RWPS-4881
        });
        // RWPS-4196 END
    }

    disconnectedCallback() {
        document.removeEventListener('keydown', this.#escapeKeyCallback);
    }

    escapeKeyCallback(event) {
        if (event.key === 'Escape' || event.keyCode === 27) {
            if (this.showMessagePage) {
                this.handleMessageScreenClose(event);
            }
            if (this.isShowModal) {
                this.hideModalBox();
            }

        }
    }// RWPS-4087 end

    loadBasedOnDeviceType() {
        var width = (window.innerWidth > 0) ? window.innerWidth : screen.width;
        //Tab UI fix - Gaurang - 17 July 2024
        if (FORM_FACTOR === 'Medium' || (width == 1025)) {
            this.sidebarCSS = 'slds-size_12-of-12 slds-large-size_12-of-12 slds-medium-size_12-of-12 slds-small-size_12-of-12';
            this.middleSpaceCSS = 'doNotDisplay';
        }
        else {
            this.sidebarCSS = 'slds-size_12-of-12 slds-large-size_3-of-12 slds-medium-size_3-of-12 slds-small-size_12-of-12';
            this.middleSpaceCSS = 'slds-large-size_1-of-12 slds-medium-size_1-of-12';
        }
        if (this.device.isMobile) {
            this.modalSize = "slds-modal slds-fade-in-open slds-modal_full";
        } else {
            this.modalSize = "slds-modal slds-fade-in-open modalCSS";
        }
    }


    setOrderItemsList(orderItems, isOnlineOrder) {
        let formatedOrderItems = [];
        for (let i = 0; i < orderItems.length; i++) {
            if (isOnlineOrder) {
                formatedOrderItems.push({ Product2Id: orderItems[i].Product2Id, Quantity: orderItems[i].Quantity, ECOM_Parent_Item__c: orderItems[i].ECOM_Parent_Item__c }); //RWPS-3811
            } else {
                //RWPS-5286
                if (this.partNoVsProductMap && this.partNoVsProductMap.has(orderItems[i].Material_Number__c)) {
                    formatedOrderItems.push({Product2Id: this.partNoVsProductMap.get(orderItems[i].Material_Number__c).Id, Quantity: orderItems[i].Quantity_Ordered__c});
                }
                //RWPS-5286
            }
        }
        return formatedOrderItems;
    }

    orderDetailsData(event) {

        //Preparing data for re_order event which will be push to DataLayer
        try {
            this.prepareDataLayerDataForOrderHistory(event.detail, orderId);
        } catch (error) {
            //console.error('Error occured during preparing DataLayer data for re_order event ',error);
        }
    }
    // Add order items to the cart and redirect to the cart page
    handleOrderAgain(event) {
        this.lastFocusedButton = event.currentTarget; //RWPS-4153
        let orderId = event.currentTarget.dataset.id;
        let isWebOrder = event.currentTarget.dataset.source && event.currentTarget.dataset.source == true || event.currentTarget.dataset.source == "true" ? true : false;
        let orderItems;
        let productIdTopartNumberMap = new Map();
        this.erroneousPartsToDisplay = [];
        this.successfulParts = [];
        this.showErrorParts = false;
        this.showSuccessParts = false;
        if (isWebOrder == true) {
            orderItems = this.myOrders.find(e => e.Id === orderId)?.orderItems;
            for (let i in orderItems) {
                if (orderItems[i] && orderItems[i].Product2Id && orderItems[i].Product2 && orderItems[i].Product2.Part_Number__c) {
                    productIdTopartNumberMap.set(orderItems[i].Product2Id, orderItems[i].Product2.Part_Number__c);
                }
            }
        } else if (isWebOrder == false) {
            orderItems = this.myOrders.find(e => e.Id === orderId)?.orderItems;
            for (let i in orderItems) {
                if (orderItems[i] && orderItems[i].Material_Number__c && this.partNoVsProductMap && this.partNoVsProductMap.get(orderItems[i].Material_Number__c) && this.partNoVsProductMap.get(orderItems[i].Material_Number__c).Id) {
                    productIdTopartNumberMap.set(this.partNoVsProductMap.get(orderItems[i].Material_Number__c).Id,orderItems[i].Material_Number__c);
                }
            }
        }
        if (orderItems) {
            this.showSpinner = true;
            let cartItems = this.setOrderItemsList(orderItems, isWebOrder);
            if (cartItems.length > 0) {
                // Call the 'addItemsToCart' apex method imperatively
                addItemsToCart({
                    communityId: communityId,
                    effectiveAccountId: this.effectiveAccountId,
                    cartItems: cartItems
                }).then((results) => {
                    this.showSpinner = false;
                    let productData = this.discontinuedAndNonSellableProductDetails;
                    for (let i in cartItems) {
                        if (!((results.itemsAddedSuccessfully).includes(cartItems[i]?.Product2Id) && !cartItems[i]?.ECOM_Parent_Item__c)) {
                            //RWPS-4621 : Logic to identify discontinued products along with replacements
                            if (productData && productData.discontinuedProducts) {
                                productData.discontinuedProducts.forEach(currentItem => {
                                    if (cartItems[i].Product2Id == currentItem) {
                                        //RWPS-4621 : Logic to identify discontinued products along with direct replacements
                                        if (productData.directReplacementProductMap && productData.directReplacementProductMap.hasOwnProperty(currentItem)) {
                                            this.erroneousPartsToDisplay.push({
                                                partNumber: productIdTopartNumberMap.get(cartItems[i]?.Product2Id),
                                                reason: ECOM_REPLACEMENT_MSG + ' ' + productData.directReplacementProductMap[currentItem] + '.' //RWPS-5079 Added Space
                                            });
                                        //RWPS-4621 : Logic to identify discontinued products along with Indirect replacements
                                        } else if (productData.indirectReplacementProductMap && productData.indirectReplacementProductMap.hasOwnProperty(currentItem)) {
                                            //RWPS-5079 - Start
                                            let indirectReplacementMessage = ' ';
                                            for (let i = 0; i < productData.indirectReplacementProductMap[currentItem].split(',').length; i++) {
                                                indirectReplacementMessage += productData.indirectReplacementProductMap[currentItem].split(',')[i].trim();
                                                if (i+1 < productData.indirectReplacementProductMap[currentItem].split(',').length) {
                                                    indirectReplacementMessage += ', '
                                                }  else {
                                                    indirectReplacementMessage += '.'
                                                }
                                            }
                                            this.erroneousPartsToDisplay.push({
                                                partNumber: productIdTopartNumberMap.get(cartItems[i]?.Product2Id),
                                                reason: ECOM_INDIRECT_REPLACEMENT_MSG + indirectReplacementMessage
                                            });
                                            //RWPS-5079 - End
                                        //RWPS-4621 : Logic to identify discontinued products without any replacements
                                        } else {
                                            this.erroneousPartsToDisplay.push({
                                                partNumber: productIdTopartNumberMap.get(cartItems[i]?.Product2Id),
                                                reason: ECOM_DISCONTINUE_MSG
                                            });
                                        }
                                    }
                                });
                            }
                            // Logic to identify non-sellable products
                            if (productData && productData.nonSellableProducts) {
                                productData.nonSellableProducts.forEach(currentItem => {
                                    if (cartItems[i].Product2Id == currentItem) {
                                        this.erroneousPartsToDisplay.push({
                                            partNumber: productIdTopartNumberMap.get(cartItems[i]?.Product2Id),
                                            reason: ECOM_105103
                                        });
                                    }
                                });
                            }
                        } else {
                            //RWPS-4500 START
                            if (!cartItems[i]?.ECOM_Parent_Item__c) {
                                this.successfulParts.push({
                                    partNumber: productIdTopartNumberMap.get(cartItems[i]?.Product2Id)
                                });
                            }
                            //RWPS-4500 END


                            // RWPS-3125 start
                            if (cartItems[i]?.Product2Id) {
                                trackAddProductToCart(
                                    {
                                        id: cartItems[i].Product2Id,
                                        sku: productIdTopartNumberMap.get(cartItems[i]?.Product2Id),
                                        quantity: cartItems[i].Quantity,
                                        price: ''
                                    }
                                );
                            }
                            // RWPS-3125 end
                        }
                    }

                    if (this.erroneousPartsToDisplay.length > 0) {
                        this.showErrorParts = true;
                        this.showMessagePage = true;
                    }
                    if (this.successfulParts.length > 0) {
                        this.showSuccessParts = true;
                        this.showMessagePage = true;
                    }
                    //RWPS-3764 start
                    if (this.showMessagePage) {
                        setTimeout(() => {
                            const modal = this.template.querySelector('[data-id="view-order-details"]');
                            if (modal) {
                                modal.focus();
                            }
                        }, 0);
                    }//RWPS-3764 end

                    let payLoad = {
                        message: 1,
                        type: 'CartRefresh'
                    };
                    publish(this.messageContext, ECOM_MESSAGE, payLoad);
                    //Preparing data for re_order event which will be push to DataLayer
                    try {
                        this.prepareDataLayerData(results, orderItems);
                    } catch (error) {
                        //console.error('Error occured during preparing DataLayer data for re_order event ',error);
                    }

                }).catch((error) => {
                    console.log(error);
                    this.showSpinner = false;
                    for (let i in cartItems) {
                        this.erroneousPartsToDisplay.push({
                            partNumber: productIdTopartNumberMap.get(cartItems[i]?.Product2Id),
                            reason: ECOM_105105
                        });
                    }
                    if (this.erroneousPartsToDisplay.length > 0) {
                        this.showErrorParts = true;
                        this.showMessagePage = true;
                        //RWPS-3764 start
                        setTimeout(() => {
                            const modal = this.template.querySelector('[data-id="view-order-details"]');
                            if (modal) {
                                modal.focus();
                            }
                        }, 0);//RWPS-3764 start
                    }
                });
            }
        }
    }

    handleMessageScreenRedirectToCart(event) {
        let currentUrl = window.location.href;
        let baseUrl = currentUrl.split('/');
        let finalUrl = baseUrl[0] + '/cart';
        window.location.href = finalUrl;
    }

    handleMessageScreenClose(event) {
        this.showMessagePage = false;
        // RWPS-4153 Start
        if (this.lastFocusedButton) {
            this.lastFocusedButton.focus();
            this.lastFocusedElement = null;
        }
        // RWPS-4153 End
    }

    handleSortChange(event) {
        let sortBy = event.detail.value;

        if (sortBy == 'oldest') {
            this.sortData('OrderedDate', 'asc'); //RWPS-3741
        }
        if (sortBy == 'newest') {
            this.sortData('OrderedDate', 'desc'); //RWPS-3741
        }
        this.currentPageNumber = 1;
        this.fromRecords = 0; //RWPS-95 : garora@rafter.one - 29 April 2024 - resetting to initial value
        this.toRecords = this.defaultListSize; //RWPS-95 : garora@rafter.one - 29 April 2024 - resetting to initial value
        this.ordersToDisplay = [];
        //update default size
        this.nextLoadCount = this.defaultListSize;
        if (this.defaultListSize > this.totalOrders) {
            this.nextLoadCount = this.totalOrders;
            this.toRecords = this.totalOrders; //RWPS-95 : garora@rafter.one - 28 April 2024 - taking totalRecords as toRecords if smaller than defaultsize
        }

        for (let i = 0; i < this.nextLoadCount; i++) {
            this.ordersToDisplay.push(this.myOrders[i]);
        }
        if (this.totalOrders > this.defaultListSize) {
            this.isLoadMore = true;
        }


    }

    handleLoadMoreOrders(event) {
        if (this.isLoadMore) {
            this.nextLoadCount = this.ordersToDisplay.length + this.defaultListSize;
            this.ordersToDisplay = [];
            if (this.nextLoadCount > this.totalOrders) {
                this.nextLoadCount = this.totalOrders;
            }
            for (let i = 0; i < this.nextLoadCount; i++) {
                this.ordersToDisplay.push(this.myOrders[i]);
            }
        }
        //disable Load More when total Orders are equals to display Order
        if (this.ordersToDisplay.length === this.totalOrders) {
            this.isLoadMore = false;
        }

    }

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.myOrders));
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1 : -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : '';
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.myOrders = parseData;
    }

    handleOrderNumberChange(event) {
        if (event.target.value.length > 0 && event.target.value == ' ') {
            event.target.value = event.target.value.trim();
        }
        event.target.value = event.target.value.trim();
        this.orderNumber = event.target.value;
        if (this.orderNumber.length > 0 && this.shippingZip.length > 0) {
            this.isFindOrderDisabled = false;
        } else {
            this.isFindOrderDisabled = true;
        }
    }

    handleZipChange(event) {
        //this.shippingZip = event.target.value;
        if (event.target.value.length > 0 && event.target.value == ' ') {
            event.target.value = event.target.value.trim();
        }
        event.target.value = event.target.value.trim();
        this.shippingZip = event.target.value;
        if (this.orderNumber.length > 0 && this.shippingZip.length > 0) {
            this.isFindOrderDisabled = false;
        } else {
            this.isFindOrderDisabled = true;
        }
    }

    openFindOrderPopUp() {
        this.isShowModal = true;
        this.showErrorMsg = false;
        this.shippingZip = '';
        this.orderNumber = '';
        //RWPS-3764 Start
        setTimeout(() => {
            const modal = this.template.querySelector('[data-id="find-order-modal"]');
            if (modal) {
                modal.focus();
            }
        }, 0);//RWPS-3764 end
    }

    handleFindOrder() {
        this.showSpinner = true;
        findOrder({ orderNumber: this.orderNumber, zipCode: this.shippingZip })
            .then((result) => {
                if (result.length > 0) {
                    let searchedOrder = result;
                    this.showSpinner = false;
                    this.isLoadMore = false;
                    this.myOrders = [];
                    for (let i = 0; i < result.length; i++) {
                        let order = result[i];
                        let orderNum;
                        if (order.ECOM_SAP_Order_Number__c) {
                            orderNum = order.ECOM_SAP_Order_Number__c;
                        }
                        else {
                            orderNum = order.OrderNumber;
                        }

                        let unavailableProductDetails = this.setNonAvailableProductDetails(order, true); //RWPS-4881
                        this.myOrders.push({
                            Id: order.Id,
                            OrderNumber: orderNum,
                            OrderedDate: order.OrderedDate,
                            Status: order.ECOM_Order_Summary_Status__c,
                            TotalAmount: order.TotalAmount,
                            GrandTotalAmount: order.GrandTotalAmount,
                            OrderProductLineCount: order.ECOM_Total_Items__c, //ECOM-3150 - garora@rafter.one - mapping to new rollup field for getting sum of quantities
                            orderItems: order.OrderItems,
                            currencyIsoCode: order.CurrencyIsoCode,
                            poNumber: order.PoNumber, //ECOM-95 - garora@rafter.one - to display po number on front end
                            InvoiceCount: order.Invoices__r?.length, //ECOM-95 - garora@rafter.one - getting invoice count
                            invoices: order.Invoices__r,
                            discontinuedDetails: unavailableProductDetails.discontinuedProductDetails, //RWPS - 4621
                            notSellableDetails: unavailableProductDetails.nonSellableProductDetails, //RWPS - 4621
                            isAllDiscontinuedProducts: (unavailableProductDetails && unavailableProductDetails.allDiscontinuedProducts && unavailableProductDetails.allDiscontinuedProducts == true) || (unavailableProductDetails && unavailableProductDetails.allNonSellableProducts && unavailableProductDetails.allNonSellableProducts == true) ? true : false, //RWPS-5230
                        });
                    }
                    this.sortData('OrderedDate', 'desc'); //RWPS-3741
                    this.totalOrders = this.myOrders.length;
                    //update default size
                    this.nextLoadCount = this.defaultListSize;
                    if (this.defaultListSize > this.totalOrders) {
                        this.nextLoadCount = this.totalOrders;
                        this.toRecords = this.totalOrders; //RWPS-95 : garora@rafter.one - 28 April 2024 - taking totalRecords as toRecords if smaller than defaultsize
                    }
                    this.ordersToDisplay = [];
                    for (let i = 0; i < this.nextLoadCount; i++) {
                        this.ordersToDisplay.push(this.myOrders[i]);
                    }
                    if (this.totalOrders > this.defaultListSize) {
                        this.isLoadMore = true;
                    }
                    this.isShowModal = false;
                }
                else {
                    this.showErrorMsg = true;
                }
                this.showSpinner = false;
            })
            .catch((error) => {
                console.log(error);
                this.userDetails = undefined;
            });
    }

    /**
     * RWPS-4621 : This function structures the unavailable product details
     * Sachin Vispute | 30.09.2025
     * @param {*} order
     * @returns productDetails Collection
     */
    setNonAvailableProductDetails(order, isOnlineOrder) { //RWPS-4881
        //RWPS-4621 Start
        let discontinuedProductDetails = {
            value: false,
            replacementAvailable: false,
            directReplacementAvailable : false,
            replacementProducts: null,
            message: null
        };
        let nonSellableProductDetails = {
            value: false,
            message: null
        };
        let allDiscontinuedProducts = false;
        let allNonSellableProducts = false; //RWPS-5230
        let discontinuedProductsCount = 0; //RWPS-5230
        let nonSellableProductCount = 0; //RWPS-5230
        let productData = JSON.parse(JSON.stringify(this.discontinuedAndNonSellableProductDetails));
        // Logic to identify discontinued products
        if (productData && productData.discontinuedProducts) {
            let discountedProductCount = 0;
            productData.discontinuedProducts.forEach(currentItem => {
                if (isOnlineOrder == true && order && order.OrderItems && order.OrderItems.length > 0) { //RWPS-4881
                    for (let j = 0; j < order.OrderItems.length; j++) {
                        let orderItem = order.OrderItems[j];
                        if (orderItem && orderItem.Product2Id && orderItem.Product2Id == currentItem) {
                            // Logic to identify discontinued products with direct replacements
                            if (productData.directReplacementProductMap && productData.directReplacementProductMap.hasOwnProperty(currentItem)) {
                                discontinuedProductDetails.value = true;
                                discontinuedProductDetails.replacementAvailable = true;
                                discontinuedProductDetails.directReplacementAvailable = true;
                                discontinuedProductDetails.replacementProducts = productData.directReplacementProductMap[currentItem];
                                discontinuedProductDetails.message = ECOM_REPLACEMENT_MSG + ' ' + productData.directReplacementProductMap[currentItem] + '.'; //RWPS-5079
                                nonSellableProductDetails.value = false;
                                // Logic to identify discontinued products with Indirect replacements
                            } else if (productData.indirectReplacementProductMap && productData.indirectReplacementProductMap.hasOwnProperty(currentItem)) {
                                discontinuedProductDetails.value = true;
                                discontinuedProductDetails.replacementAvailable = true;
                                discontinuedProductDetails.directReplacementAvailable = false;
                                discontinuedProductDetails.replacementProducts = productData.indirectReplacementProductMap[currentItem];
                                //RWPS-5079
                                let indirectReplacementMessage = ' ';
                                for (let i = 0; i < productData.indirectReplacementProductMap[currentItem].split(',').length; i++) {
                                    indirectReplacementMessage += productData.indirectReplacementProductMap[currentItem].split(',')[i].trim();
                                    if (i+1 < productData.indirectReplacementProductMap[currentItem].split(',').length) {
                                        indirectReplacementMessage += ', '
                                    }  else {
                                        indirectReplacementMessage += '.'
                                    }
                                }
                                //RWPS-5079
                                discontinuedProductDetails.message = ECOM_INDIRECT_REPLACEMENT_MSG + indirectReplacementMessage; //RWPS-5079
                                nonSellableProductDetails.value = false;
                                // Logic to identify discontinued products without any replacements
                            } else {
                                discontinuedProductDetails.value = true;
                                discontinuedProductDetails.replacementAvailable = false;
                                discontinuedProductDetails.directReplacementAvailable = false;
                                discontinuedProductDetails.replacementProducts = null;
                                discontinuedProductDetails.message = ECOM_DISCONTINUE_MSG;
                                nonSellableProductDetails.value = false;
                            }
                            discountedProductCount++;
                        }
                    }
                    // Logic to check whether all of the products are discountinued
                    allDiscontinuedProducts = discountedProductCount == order.OrderItems.length ? true : false;
                    discontinuedProductsCount = discountedProductCount; //RWPS-5230
                } else if (isOnlineOrder == false && order && order.SAP_Order_Items__r && order.SAP_Order_Items__r.length > 0) {
                    //RWPS-4881
                    for (let j = 0; j < order.SAP_Order_Items__r.length; j++) {
                        let orderItem = order.SAP_Order_Items__r[j];
                        //RWPS-5230
                        if (orderItem && orderItem.Order_Product__r && orderItem.Order_Product__r.Product2 && orderItem.Order_Product__r.Product2.Id == currentItem ||
                            (orderItem && orderItem.Material_Number__c && this.partNoVsProductMap && this.partNoVsProductMap.get(orderItem.Material_Number__c) && this.partNoVsProductMap.get(orderItem.Material_Number__c).Id && this.partNoVsProductMap.get(orderItem.Material_Number__c).Id == currentItem)) {
                            // Logic to identify discontinued products with direct replacements
                            if (productData.directReplacementProductMap && productData.directReplacementProductMap.hasOwnProperty(currentItem)) {
                                discontinuedProductDetails.value = true;
                                discontinuedProductDetails.replacementAvailable = true;
                                discontinuedProductDetails.directReplacementAvailable = true;
                                discontinuedProductDetails.replacementProducts = productData.directReplacementProductMap[currentItem];
                                discontinuedProductDetails.message = ECOM_REPLACEMENT_MSG + ' ' + productData.directReplacementProductMap[currentItem] + '.'; //RWPS-5079
                                nonSellableProductDetails.value = false;
                                // Logic to identify discontinued products with Indirect replacements
                            } else if (productData.indirectReplacementProductMap && productData.indirectReplacementProductMap.hasOwnProperty(currentItem)) {
                                discontinuedProductDetails.value = true;
                                discontinuedProductDetails.replacementAvailable = true;
                                discontinuedProductDetails.directReplacementAvailable = false;
                                discontinuedProductDetails.replacementProducts = productData.indirectReplacementProductMap[currentItem];
                                //RWPS-5079
                                let indirectReplacementMessage = ' ';
                                for (let i = 0; i < productData.indirectReplacementProductMap[currentItem].split(',').length; i++) {
                                    indirectReplacementMessage += productData.indirectReplacementProductMap[currentItem].split(',')[i].trim();
                                    if (i+1 < productData.indirectReplacementProductMap[currentItem].split(',').length) {
                                        indirectReplacementMessage += ', '
                                    }  else {
                                        indirectReplacementMessage += '.'
                                    }
                                }
                                //RWPS-5079
                                discontinuedProductDetails.message = ECOM_INDIRECT_REPLACEMENT_MSG + indirectReplacementMessage; //RWPS-5079
                                nonSellableProductDetails.value = false;
                                // Logic to identify discontinued products without any replacements
                            } else {
                                discontinuedProductDetails.value = true;
                                discontinuedProductDetails.replacementAvailable = false;
                                discontinuedProductDetails.directReplacementAvailable = false;
                                discontinuedProductDetails.replacementProducts = null;
                                discontinuedProductDetails.message = ECOM_DISCONTINUE_MSG;
                                nonSellableProductDetails.value = false;
                            }
                            discountedProductCount++;
                        }
                    }
                    // Logic to check whether all of the products are discountinued
                    allDiscontinuedProducts = discountedProductCount == order.SAP_Order_Items__r.length ? true : false;
                    discontinuedProductsCount = discountedProductCount; //RWPS-5230
                }
            });
        }
        // Logic to identify non-sellable products
        if (productData && productData.nonSellableProducts) {
            let nonSellableProductsCount = 0; //RWPS-5230
            productData.nonSellableProducts.forEach(currentItem => {
                //RWPS-5230
                if (isOnlineOrder == true && order && order.OrderItems && order.OrderItems.length > 0) {
                    for (let j = 0; j < order.OrderItems.length; j++) {
                        let orderItem = order.OrderItems[j];
                        if (orderItem && orderItem.Product2 && orderItem.Product2.Id == currentItem) {
                            nonSellableProductDetails.value = true;
                            nonSellableProductDetails.message = ECOM_105103;
                            discontinuedProductDetails.value = false;
                            nonSellableProductsCount++; //RWPS-5230
                        }
                    }
                    allNonSellableProducts = nonSellableProductsCount == order.OrderItems.length ? true : false; //RWPS-5230
                    nonSellableProductCount = nonSellableProductsCount; //RWPS-5230
                } else if (isOnlineOrder == false && order && order.SAP_Order_Items__r && order.SAP_Order_Items__r.length > 0) {
                    //RWPS-5230
                    for (let j = 0; j < order.SAP_Order_Items__r.length; j++) {
                        let orderItem = order.SAP_Order_Items__r[j];
                        if ((orderItem && orderItem.Order_Product__r && orderItem.Order_Product__r.Product2 && orderItem.Order_Product__r.Product2.Id == currentItem) ||
                            (orderItem && orderItem.Material_Number__c && this.partNoVsProductMap && this.partNoVsProductMap.get(orderItem.Material_Number__c) && this.partNoVsProductMap.get(orderItem.Material_Number__c).Id && this.partNoVsProductMap.get(orderItem.Material_Number__c).Id == currentItem)) {
                            nonSellableProductDetails.value = true;
                            nonSellableProductDetails.message = ECOM_105103;
                            discontinuedProductDetails.value = false;
                            nonSellableProductsCount++; //RWPS-5230
                        }
                    }
                    allNonSellableProducts = nonSellableProductsCount == order.SAP_Order_Items__r.length ? true : false; //RWPS-5230
                    nonSellableProductCount = nonSellableProductsCount; //RWPS-5230
                }
            });
        }

        //RWPS-5230
        if (isOnlineOrder == true && order && order.OrderItems && order.OrderItems.length > 0) {
            if (allNonSellableProducts == false) {
                allNonSellableProducts = (discontinuedProductsCount + nonSellableProductCount) == order.OrderItems.length ? true : false;
            }
        } else if (isOnlineOrder == false && order && order.SAP_Order_Items__r && order.SAP_Order_Items__r.length > 0) {
            if (allNonSellableProducts == false) {
                allNonSellableProducts = (discontinuedProductsCount + nonSellableProductCount) == order.SAP_Order_Items__r.length ? true : false;
            }
        }
        //RWPS-5230
        return {
            discontinuedProductDetails,
            nonSellableProductDetails,
            allDiscontinuedProducts,
            allNonSellableProducts //RWPS-5230
        }
    }

    hideModalBox() {
        this.isShowModal = false;
        //RWPS-3764 start
        setTimeout(() => {
            const triggerButton = this.template.querySelector(
                ".ecom-find-order-alignment"
            );
            if (triggerButton) {
                triggerButton.focus();
            }
        }, 0);
        //RWPS-3764 end
    }

    handleViewOrderDetails(event) {
        let orderId = event.currentTarget.dataset.id;
        let finalSearchTerm = this.searchTerm ? this.searchTerm.trim() : ''; // RWPS-5286

        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/orderDetails?id=${orderId}` + (finalSearchTerm ? `&search=${encodeURIComponent(finalSearchTerm)}` : '') // RWPS-5286
            }
        });
    }

    handleViewAll(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/orderHistory`
            }
        });
    }

    get isLoadMoreEnabled() {
        return this.isLoadMore && this.isOrderHistoryPage;
    }

    pageChanged(event) {
        let pageNumber = JSON.parse(JSON.stringify(event.detail.pageNumber));
        this.currentPageNumber = parseInt(pageNumber);
        const start = (this.currentPageNumber - 1) * this.defaultListSize;
        const end = this.defaultListSize * this.currentPageNumber;
        this.fromRecords = start == 0 ? start : start + 1; //RWPS-95 : garora@rafter.one - 28 April 2024 - value on page change
        this.toRecords = end > this.totalOrders ? this.totalOrders : end; //RWPS-95 : garora@rafter.one - 28 April 2024 - value on page change
        this.ordersToDisplay = this.myOrders.slice(start, end);
    }

    handleShopNow() {
        let payLoad = {
            message: NAVIGATE_TO_PLP,
            type: CMS_NAVIGATION,
            partNumber: this.partNumberCode
        };
        publish(this.messageContext, ECOM_MESSAGE, payLoad);
    }

    //DataLayer regarding changes starts
    prepareDataLayerData(reOrderItems, orderItems) {
        let data = {
            event: 're_order',
            orderId: orderItems[0]?.OrderId,
            items: [],
            _clear: true
        };
        let items = [];
        for (const property in reOrderItems.products) {
            items.push({
                'name': reOrderItems.products[property].productName,
                'quantity': reOrderItems.products[property].quantity,
            });
        }
        data.items = items;
        this.handlePublishMsg(data);
    }

    //for re_order event fired from ecom_sapOrderHistory
    prepareDataLayerDataForOrderHistory(detailArray, orderId) {
        let data = {
            event: 're_order',
            orderId: orderId,
            items: [],
            _clear: true
        };
        let items = [];
        for (let i = 0; i < detailArray.length; i++) {
            items.push({
                'name': detailArray[i].name,
                'quantity': detailArray[i].quantity,
            });
        }
        data.items = items;
        this.handlePublishMsg(data);
    }

    handlePublishMsg(data) {
        let payLoad = {
            data: data,
            type: 'DataLayer',
            page: 'Order Details'
        };
        publish(this.messageContext, ECOM_DATALAYERCHANNEL, payLoad);
    }
    //DataLayer regarding changes ends

    handleViewInvoiceDetails(event) {
        let dataId = event.target.dataset.id;
        let chevronIcon = this.template.querySelector("[data-icon=\"" + dataId + "\"]");
        if (chevronIcon) {
            chevronIcon.classList.toggle("chevron-up");
        }
        let section = this.template.querySelector("[data-invoice=\"" + dataId + "\"]");
        if (section) {
            section.classList.toggle("doNotDisplay");
        }
    }

    //ECOM-112 - garora@rafter.one - 12 May 2024 - for redirection to invoice detail page - starts
    goToInvoiceDetailPage(event) {
        let invoiceId = event.currentTarget.dataset.id;
        let orderId = event.currentTarget.dataset.order;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/invoiceDetails?invoiceid=` + invoiceId + `&orderid=` + orderId
            }
        });
    }
    //ECOM-112 - garora@rafter.one - 12 May 2024 - for redirection to invoice detail page - ends
    //RWPS-3764 start
    handleFindOrderKeyDown(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            this.openFindOrderPopUp();
        }
    }
    handleModalKeyDown(event) {
        if (event.key === "Tab") {
            const focusableElements = this.template.querySelectorAll(
                '.ecom-fo-modal button, .ecom-fo-modal input, .ecom-fo-modal select, .ecom-fo-modal a[href]'
            );
            const focusable = Array.from(focusableElements).filter(
                el => !el.hasAttribute("disabled")
            );

            if (focusable.length > 0) {
                const firstEl = focusable[0];
                const lastEl = focusable[focusable.length - 1];

                if (event.shiftKey && document.activeElement === firstEl) {
                    event.preventDefault();
                    lastEl.focus();
                } else if (!event.shiftKey && document.activeElement === lastEl) {
                    event.preventDefault();
                    firstEl.focus();
                }
            }
        }
    }
    handleEnterKeyPress(event) {
        if (event.key === 'Enter' || event.keyCode === 13) {
            event.preventDefault();
            if (this.showSpinner)//RWPS-4087 start
            {
                return true;
            }//RWPS-4087 end
            this.lastFocusedButton = event.currentTarget; //RWPS-4153
            this.handleOrderAgain(event);
        }
    }
    //RWPS-3764 end

    onlineAddOnOrdersExist = false;
    onlineAddOnOrders = null;

    /**
     * RWPS-4881
     * This function is used to handle the event, receive and set data
     */
    handleFetchOrderData(event) {
        if (event && event.detail) {
            this.searchTerm = event.detail.searchTerm;
            this.onlineOrderExists = event.detail.onlineOrderExists ? true : false;
            this.offlineOrderExists = event.detail.offlineOrderExists ? true : false;
            this.onlineAddOnOrdersExist = event.detail.addOnOrdersExist ? true : false;
            let partNoVsProductMap = event.detail.partNoVsProductMap ? event.detail.partNoVsProductMap : null;

            if (this.onlineOrderExists == true) {
                this.onlineOrders = JSON.parse(JSON.stringify(event.detail.onlineOrderData));
            } else {
                this.onlineOrders = null;
            }
            if (this.offlineOrderExists == true) {
                this.offlineOrders = JSON.parse(JSON.stringify(event.detail.offlineOrderData));
                this.allOrdersCount = this.offlineOrders.orders.length;
                if (this.offlineOrders.partNoVsProductMap) {
                    for (var key in this.offlineOrders.partNoVsProductMap) {
                        this.partNoVsProductMap.set(key,this.offlineOrders.partNoVsProductMap[key])
                    }
                }

            } else {
                this.offlineOrders = null;
            }
            if (this.onlineAddOnOrdersExist) {
                this.onlineAddOnOrders = JSON.parse(JSON.stringify(event.detail.onlineAddonsOrders));
            } else {
                this.onlineAddOnOrders = null;
            }

            if (this.onlineOrderExists == false && this.onlineAddOnOrdersExist == false) {
                this.onlineOrdersCount = 0;
            }

            if (partNoVsProductMap) {
                for (var key in partNoVsProductMap) {
                    this.partNoVsProductMap.set(key,partNoVsProductMap[key])
                }
            }
            this.configureData();
        }
    }

    /**
     * RWPS-4881
     * This function is used to handle the tab change event and setup order data accordingly
     */
    async handleTabChange(event) {
        const tabClicked = event.target.dataset.tab;
        if (tabClicked != this.selectedTab) {
            this.showSpinner = true;
            this.selectedTab = tabClicked;
            if (this.selectedTab == ALL_ORDERS) {
                if (this.onlineOrderExists == true && this.onlineAddOnOrdersExist == true && this.offlineOrderExists == true) {
                    this.tab2class = ACTIVE_TAB_2;
                    this.tab1class = INACTIVE_TAB_1;
                    this.sapOrder = false;
                    this.sfOrder = false;
                    this.combinedOrders = true;
                    this.setupCombinedOrderData(true);
                } else if (this.onlineOrderExists == true && this.onlineAddOnOrdersExist == false && this.offlineOrderExists == true) {
                    this.tab2class = ACTIVE_TAB_2;
                    this.tab1class = INACTIVE_TAB_1;
                    this.sapOrder = false;
                    this.sfOrder = false;
                    this.combinedOrders = true;
                    this.setupCombinedOrderData(true);
                } else if (this.onlineOrderExists == false && this.onlineAddOnOrdersExist == true && this.offlineOrderExists == true) {
                    this.tab2class = ACTIVE_TAB_2;
                    this.tab1class = INACTIVE_TAB_1;
                    this.sapOrder = false;
                    this.sfOrder = false;
                    this.combinedOrders = true;
                    this.setupCombinedOrderData(true);
                } else if (this.onlineOrderExists == false && this.onlineAddOnOrdersExist == false && this.offlineOrderExists == true) {
                    this.sfOrder = false;
                    this.combinedOrders = false;
                    this.tab2class = ACTIVE_TAB_2;
                    this.tab1class = INACTIVE_DISABLED_TAB_1;
                    this.sapOrder = true;
                    this.showSpinner = false;
                } else if (this.onlineOrderExists == true && this.onlineAddOnOrdersExist == true && this.offlineOrderExists == false) {
                    this.sfOrder = true;
                    this.combinedOrders = false;
                    this.tab2class = ACTIVE_TAB_2;
                    this.tab1class = INACTIVE_TAB_1;
                    this.sapOrder = false;
                    this.showSpinner = false;
                } else if (this.onlineOrderExists == true && this.onlineAddOnOrdersExist == true && this.offlineOrderExists == false) {
                    this.combinedOrders = false;
                    this.tab2class = ACTIVE_TAB_2;
                    this.tab1class = INACTIVE_TAB_1;
                    this.ordersNotFound = false;
                    this.sapOrder = false;
                    this.sfOrder = true;
                    this.setupOnlineOrderData(true);
                } else if (this.onlineOrderExists == true && this.onlineAddOnOrdersExist == false && this.offlineOrderExists == false) {
                    this.combinedOrders = false;
                    this.tab2class = ACTIVE_TAB_2;
                    this.tab1class = INACTIVE_TAB_1;
                    this.ordersNotFound = false;
                    this.sapOrder = false;
                    this.sfOrder = true;
                    this.setupOnlineOrderData(true);
                } else if (this.onlineOrderExists == false && this.onlineAddOnOrdersExist == true && this.offlineOrderExists == false) {
                    this.combinedOrders = false;
                    this.tab2class = ACTIVE_TAB_2;
                    this.tab1class = INACTIVE_TAB_1;
                    this.ordersNotFound = false;
                    this.sapOrder = false;
                    this.sfOrder = true;
                    this.setupOnlineOrderData(true);
                }
            } else {
                if (this.onlineOrderExists == true && this.onlineAddOnOrdersExist == true) {
                    this.ordersNotFound = false;
                    this.combinedOrders = false;
                    this.sapOrder = false;
                    this.tab1class = ACTIVE_TAB_1;
                    this.tab2class = INACTIVE_TAB_2;
                    this.sfOrder = true;
                    this.setupOnlineOrderData(true);
                } else if (this.onlineOrderExists == true && this.onlineAddOnOrdersExist == false) {
                    this.ordersNotFound = false;
                    this.combinedOrders = false;
                    this.sapOrder = false;
                    this.tab1class = ACTIVE_TAB_1;
                    this.tab2class = INACTIVE_TAB_2;
                    this.sfOrder = true;
                    this.setupOnlineOrderData(true);
                }  else if (this.onlineOrderExists == false && this.onlineAddOnOrdersExist == true) {
                    this.ordersNotFound = false;
                    this.combinedOrders = false;
                    this.sapOrder = false;
                    this.tab1class = ACTIVE_TAB_1;
                    this.tab2class = INACTIVE_TAB_2;
                    this.sfOrder = true;
                    this.setupOnlineOrderData(true);
                }
            }
        }
    }

    /**
     * RWPS-4881
     * This function is used to operate the spinner
     */
    handleOperateLoader(event) {
        if (event && event.detail) {
            this.showSpinner = event.detail.isLoading;
        }
    }

    /**
     * RWPS-4881
     * This function is used to setup and segregate the initial order data
     */
    async configureData() {
        this.currentPageNumber = 1;
        if (this.onlineOrderExists == true && this.onlineAddOnOrdersExist == true && this.offlineOrderExists == true) {
            this.tab2class = ACTIVE_TAB_2;
            this.tab1class = INACTIVE_TAB_1;
            this.selectedTab = ALL_ORDERS;
            this.sapOrder = false;
            this.sfOrder = false;
            this.combinedOrders = true;
            this.showOnlineOrdersTab = true;
            this.showAllOrdersTab = true;
            this.setupCombinedOrderData(true);
        } else if ((this.onlineOrderExists == true && this.onlineAddOnOrdersExist == false) && this.offlineOrderExists == true) {
            this.tab2class = ACTIVE_TAB_2;
            this.tab1class = INACTIVE_TAB_1;
            this.selectedTab = ALL_ORDERS;
            this.sapOrder = false;
            this.sfOrder = false;
            this.combinedOrders = true;
            this.showOnlineOrdersTab = true;
            this.showAllOrdersTab = true;
            this.setupCombinedOrderData(true);
        } else if ((this.onlineOrderExists == false && this.onlineAddOnOrdersExist == true) && this.offlineOrderExists == true) {
            this.tab2class = ACTIVE_TAB_2;
            this.tab1class = INACTIVE_TAB_1;
            this.selectedTab = ALL_ORDERS;
            this.sapOrder = false;
            this.sfOrder = false;
            this.combinedOrders = true;
            this.showOnlineOrdersTab = true;
            this.showAllOrdersTab = true;
            this.setupCombinedOrderData(true);
        } else if ((this.onlineOrderExists == false && this.onlineAddOnOrdersExist == false) && this.offlineOrderExists == true) {
            this.ordersNotFound = false;
            this.sfOrder = false;
            this.combinedOrders = false;
            this.tab2class = ACTIVE_TAB_2;
            this.tab1class = INACTIVE_DISABLED_TAB_1;
            this.selectedTab = ALL_ORDERS;
            this.onlineOrders = null;
            this.showOnlineOrdersTab = false;
            this.showAllOrdersTab = true;
            this.sapOrder = true;
            setTimeout(() => {
                this.template.querySelector('c-ecom_sap-order-history-list').setupComponent();
            }, 100);
            this.orderHistoryEmpty = false;
        } else if ((this.onlineOrderExists == true && this.onlineAddOnOrdersExist == true) && this.offlineOrderExists == false) {
            this.ordersNotFound = false;
            this.combinedOrders = false;
            this.sapOrder = false;
            this.tab1class = ACTIVE_TAB_1;
            this.tab2class = INACTIVE_TAB_2;
            this.selectedTab = ONLINE_ORDERS;
            this.sfOrder = true;
            this.showOnlineOrdersTab = true;
            this.showAllOrdersTab = true;
            this.setupOnlineOrderData(true);
        } else if ((this.onlineOrderExists == false && this.onlineAddOnOrdersExist == true) && this.offlineOrderExists == false) {
            this.ordersNotFound = false;
            this.combinedOrders = false;
            this.sapOrder = false;
            this.tab1class = ACTIVE_TAB_1;
            this.tab2class = INACTIVE_TAB_2;
            this.selectedTab = ONLINE_ORDERS;
            this.sfOrder = true;
            this.showOnlineOrdersTab = true;
            this.showAllOrdersTab = true;
            this.setupOnlineOrderData(true);
        } else if ((this.onlineOrderExists == true && this.onlineAddOnOrdersExist == false) && this.offlineOrderExists == false) {
            this.ordersNotFound = false;
            this.combinedOrders = false;
            this.sapOrder = false;
            this.tab1class = ACTIVE_TAB_1;
            this.tab2class = INACTIVE_TAB_2;
            this.selectedTab = ONLINE_ORDERS;
            this.sfOrder = true;
            this.showOnlineOrdersTab = true;
            this.showAllOrdersTab = true;
            this.setupOnlineOrderData(true);
        } else if (this.onlineOrderExists == false && this.onlineAddOnOrdersExist == false && this.offlineOrderExists == false && this.searchTerm != null && this.searchTerm != undefined && this.searchTerm != '') {
            this.tab1class = INACTIVE_DISABLED_TAB_1;
            this.tab2class = INACTIVE_DISABLED_TAB_2;
            this.orderHistoryEmpty = false
            this.ordersNotFound = true;
            this.combinedOrders = false;
            this.sapOrder = false;
            this.sfOrder = false;
            this.showOrders = false;
            this.showSpinner = false;
            this.onlineOrders = null;
            this.offlineOrders = null;
            this.showOnlineOrdersTab = false;
            this.showAllOrdersTab = false;
            this.onlineOrdersCount = 0;
            this.allOrdersCount = 0;
        } else if (this.onlineOrderExists == false && this.onlineAddOnOrdersExist == false && this.offlineOrderExists == false) {
            this.orderHistoryEmpty = true;
            this.ordersNotFound = true;
            this.ordersToDisplay = [];
            this.combinedOrders = false;
            this.sapOrder = false;
            this.sfOrder = false;
            this.showOrders = false;
            this.showSpinner = false;
            this.onlineOrders = null;
            this.offlineOrders = null;
            this.onlineOrdersCount = 0;
            this.allOrdersCount = 0;
        }
    }

    /**
     * RWPS-4881
     * This function is used to setup online and offline order data
     */
    async setupCombinedOrderData(operateLoader) {
        let onlineOrders =  JSON.parse(JSON.stringify(this.onlineOrders));
        let offlineOrders = JSON.parse(JSON.stringify(this.offlineOrders));
        let onlineAddOnOrders = this.onlineAddOnOrders && this.onlineAddOnOrders.length > 0 ? JSON.parse(JSON.stringify(this.onlineAddOnOrders)) : null; //4881
        let productIds = [];
        let sapOrderNumbers = [];
        let productMaterialNumbers = []; //RWPS-5230
        //Online Orders
        if (onlineOrders) {
            for (let i = 0; i < onlineOrders.length; i++) {
                let order = onlineOrders[i];
                if (order && order.OrderItems && order.OrderItems.length > 0) {
                    for (let j = 0; j < order.OrderItems.length; j++) {
                        let orderItem = order.OrderItems[j];
                        if (orderItem && orderItem.Product2 && orderItem.Product2.Id) {
                            productIds.push(orderItem.Product2.Id);
                        }
                    }
                }
            }
        }

        //Offline Orders
        if (offlineOrders) {
            for (let i = 0; i < offlineOrders.orders.length; i++) {
                let order = offlineOrders.orders[i];
                if (order && order.SAP_Order_Items__r && order.SAP_Order_Items__r.length > 0) {
                    for (let j = 0; j < order.SAP_Order_Items__r.length; j++) {
                        let orderItem = order.SAP_Order_Items__r[j];
                        if (orderItem && orderItem.Order_Product__r && orderItem.Order_Product__r.Product2 && orderItem.Order_Product__r.Product2.Id) {
                            productIds.push(orderItem.Order_Product__r.Product2.Id);
                        } else if (orderItem && orderItem.Material_Number__c) { //RWPS-5230
                            productMaterialNumbers.push(orderItem.Material_Number__c);
                        }
                    }
                }
            }
        }

        if (onlineAddOnOrders) {
            //4881
            for (let i = 0; i < onlineAddOnOrders.length; i++) {
                let order = onlineAddOnOrders[i];
                if (order && order.SAP_Order_Items__r && order.SAP_Order_Items__r.length > 0) {
                    for (let j = 0; j < order.SAP_Order_Items__r.length; j++) {
                        let orderItem = order.SAP_Order_Items__r[j];
                        if (orderItem && orderItem.Order_Product__r && orderItem.Order_Product__r.Product2 && orderItem.Order_Product__r.Product2.Id) {
                            productIds.push(orderItem.Order_Product__r.Product2.Id);
                        } else if (orderItem && orderItem.Material_Number__c) { //RWPS-5230
                            productMaterialNumbers.push(orderItem.Material_Number__c);
                        }
                    }
                }
            }
        }

        //RWPS-5230
        if (productMaterialNumbers && productMaterialNumbers.length > 0) {
            for (let j=0; j<productMaterialNumbers.length; j++) {
                if (this.partNoVsProductMap && this.partNoVsProductMap.get(productMaterialNumbers[j]) && this.partNoVsProductMap.get(productMaterialNumbers[j]).Id) {
                    productIds.push(this.partNoVsProductMap.get(productMaterialNumbers[j]).Id);
                }
            }
        }

        let productData = await fetchProductUnavailability({ productIdList: productIds });
        this.discontinuedAndNonSellableProductDetails = JSON.parse(JSON.stringify(productData));
        this.showOrders = false;
        this.myOrders = [];
        this.ordersToDisplay = [];
        this.isLoadMore = false;
        this.totalOrders = 0;
        this.fromRecords = 0;

        if (onlineOrders) {
            for (let i = 0; i < onlineOrders.length; i++) {
                let order = onlineOrders[i];
                let orderNum;
                if (order.ECOM_SAP_Order_Number__c) {
                    orderNum = order.ECOM_SAP_Order_Number__c;
                    sapOrderNumbers.push(order.ECOM_SAP_Order_Number__c); //capturing SAP Order Number
                }
                else {
                    orderNum = order.OrderNumber;
                }
                let unavailableProductDetails = this.setNonAvailableProductDetails(order, true);
                //RWPS-4621 End
                this.myOrders.push({
                    isOnlineOrder : true,
                    Id: order.Id,
                    OrderNumber: orderNum,
                    OrderedDate: order.OrderedDate,
                    Status: order.Status == 'Pending Review' || order.Status == 'Rejected' ? order.Status : order.ECOM_Order_Summary_Status__c,
                    TotalAmount: order.TotalAmount,
                    GrandTotalAmount: order.GrandTotalAmount,
                    OrderProductLineCount: order.ECOM_Total_Items__c, //ECOM-3150 - garora@rafter.one - mapping to new rollup field for getting sum of quantities
                    orderItems: order.OrderItems,
                    currencyIsoCode: order.CurrencyIsoCode,
                    poNumber: order.PoNumber, //ECOM-95 - garora@rafter.one - to display po number on front end
                    InvoiceCount: order.Invoices__r?.length, //ECOM-95 - garora@rafter.one - getting invoice count
                    invoices: order.Invoices__r,
                    discontinuedDetails: unavailableProductDetails.discontinuedProductDetails, //RWPS - 4621
                    notSellableDetails: unavailableProductDetails.nonSellableProductDetails, //RWPS - 4621
                    isAllDiscontinuedProducts: (unavailableProductDetails && unavailableProductDetails.allDiscontinuedProducts && unavailableProductDetails.allDiscontinuedProducts == true) || (unavailableProductDetails && unavailableProductDetails.allNonSellableProducts && unavailableProductDetails.allNonSellableProducts == true) ? true : false, //RWPS-5230
                    iconStyle: this.images.onlineOrderIcon,
                    isWebOrder : true
                });
            }
        }

        //4881
        if (onlineAddOnOrders) {
            for(let i=0; i < onlineAddOnOrders.length; i++) {
                let order = onlineAddOnOrders[i];
                let unavailableProductDetails = this.setNonAvailableProductDetails(order, false);
                //START - RWPS-5228
                let orderTotal = 0;
                if(order.Order_Net_Value__c){
                    orderTotal = order.Order_Net_Value__c
                }
                if (order.Order_Level_Tax__c) {
                    orderTotal += order.Order_Level_Tax__c;
                }
                if (order.Total_Tariff_Surcharge__c) {
                    orderTotal += order.Total_Tariff_Surcharge__c;
                }
                //END - RWPS-5228
                if (sapOrderNumbers && sapOrderNumbers.length > 0) {
                    if (!sapOrderNumbers.includes(order.Name)) {
                        this.myOrders.push({
                            isOnlineOrder : true,
                            Id: order.Id,
                            OrderNumber: order.Order_Number__c,
                            OrderedDate: order.Actual_Order_Date__c,
                            Status: order.fxStatusB2B__c,
                            TotalAmount: orderTotal, //RWPS-5228
                            GrandTotalAmount : orderTotal, //RWPS-4881 //RWPS-5228
                            OrderProductLineCount: order.fxItemsQuantityTotal__c, //ECOM-3150 - garora@rafter.one - 2 May 2024 - mapping to roll up field to get total quantity on order
                            orderItems: order.SAP_Order_Items__r,
                            currencyIsoCode: order.Order_Net_Currency__c,
                            poNumber: order.Customer_PO_Number__c,// ECOM-95 - garora@rafter.one - 30 April 2024 - mapping to poNumber // ECOM-95 - garora@rafter.one - 30 April 2024 - mapping to invoices to display on UI
                            invoices: order.Invoices__r,
                            InvoiceCount : order.Invoices__r?.length,
                            discontinuedDetails: unavailableProductDetails.discontinuedProductDetails, //RWPS - 4621
                            notSellableDetails: unavailableProductDetails.nonSellableProductDetails, //RWPS - 4621
                            isAllDiscontinuedProducts: (unavailableProductDetails && unavailableProductDetails.allDiscontinuedProducts && unavailableProductDetails.allDiscontinuedProducts == true) || (unavailableProductDetails && unavailableProductDetails.allNonSellableProducts && unavailableProductDetails.allNonSellableProducts == true) ? true : false, //RWPS-5230
                            iconStyle: this.images.onlineOrderIcon,
                            isWebOrder : false
                        });
                        sapOrderNumbers.push(order.Name);
                    }
                } else if (sapOrderNumbers && sapOrderNumbers.length == 0) {
                    this.myOrders.push({
                        isOnlineOrder :  true,
                        Id: order.Id,
                        OrderNumber: order.Order_Number__c,
                        OrderedDate: order.Actual_Order_Date__c,
                        Status: order.fxStatusB2B__c,
                        TotalAmount: orderTotal, //RWPS-5228
                        GrandTotalAmount : orderTotal, //RWPS-4881 //RWPS-5228
                        OrderProductLineCount: order.fxItemsQuantityTotal__c, //ECOM-3150 - garora@rafter.one - 2 May 2024 - mapping to roll up field to get total quantity on order
                        orderItems: order.SAP_Order_Items__r,
                        currencyIsoCode: order.Order_Net_Currency__c,
                        poNumber: order.Customer_PO_Number__c,// ECOM-95 - garora@rafter.one - 30 April 2024 - mapping to poNumber // ECOM-95 - garora@rafter.one - 30 April 2024 - mapping to invoices to display on UI
                        invoices: order.Invoices__r,
                        InvoiceCount : order.Invoices__r?.length,
                        discontinuedDetails: unavailableProductDetails.discontinuedProductDetails, //RWPS - 4621
                        notSellableDetails: unavailableProductDetails.nonSellableProductDetails, //RWPS - 4621
                        isAllDiscontinuedProducts: (unavailableProductDetails && unavailableProductDetails.allDiscontinuedProducts && unavailableProductDetails.allDiscontinuedProducts == true) || (unavailableProductDetails && unavailableProductDetails.allNonSellableProducts && unavailableProductDetails.allNonSellableProducts == true) ? true : false, //RWPS-5230
                        iconStyle: this.images.onlineOrderIcon,
                        isWebOrder : false
                    });
                    sapOrderNumbers.push(order.Name);
                }
            }
        }
        //4881

        this.onlineOrdersCount = this.myOrders.length;
        if(offlineOrders && offlineOrders.Status == 'Success') {
            let orders = offlineOrders.orders;
            let offlineOrdersCount = 0;
            for(let i=0; i<orders.length; i++) {
                let order = orders[i];
                let unavailableProductDetails = this.setNonAvailableProductDetails(order, false);
                //START - RWPS-5228
                let orderTotal = 0;
                if(order.Order_Net_Value__c){
                    orderTotal = order.Order_Net_Value__c
                }
                if (order.Order_Level_Tax__c) {
                    orderTotal += order.Order_Level_Tax__c;
                }
                if (order.Total_Tariff_Surcharge__c) {
                    orderTotal += order.Total_Tariff_Surcharge__c;
                }
                //END - RWPS-5228

                if (sapOrderNumbers && sapOrderNumbers.length > 0) {
                    if (!sapOrderNumbers.includes(order.Name)) {
                        this.myOrders.push({
                            isOnlineOrder :  false,
                            Id: order.Id,
                            OrderNumber: order.Order_Number__c,
                            OrderedDate: order.Actual_Order_Date__c,
                            Status: order.fxStatusB2B__c,
                            TotalAmount: orderTotal, //RWPS-5228
                            GrandTotalAmount : orderTotal, //RWPS-4881 //RWPS-5228
                            OrderProductLineCount: order.fxItemsQuantityTotal__c, //ECOM-3150 - garora@rafter.one - 2 May 2024 - mapping to roll up field to get total quantity on order
                            orderItems: order.SAP_Order_Items__r,
                            currencyIsoCode: order.Order_Net_Currency__c,
                            poNumber: order.Customer_PO_Number__c,// ECOM-95 - garora@rafter.one - 30 April 2024 - mapping to poNumber // ECOM-95 - garora@rafter.one - 30 April 2024 - mapping to invoices to display on UI
                            invoices: order.Invoices__r,
                            InvoiceCount : order.Invoices__r?.length,
                            discontinuedDetails: unavailableProductDetails.discontinuedProductDetails, //RWPS - 4621
                            notSellableDetails: unavailableProductDetails.nonSellableProductDetails, //RWPS - 4621
                            isAllDiscontinuedProducts: (unavailableProductDetails && unavailableProductDetails.allDiscontinuedProducts && unavailableProductDetails.allDiscontinuedProducts == true) || (unavailableProductDetails && unavailableProductDetails.allNonSellableProducts && unavailableProductDetails.allNonSellableProducts == true) ? true : false, //RWPS-5230
                            iconStyle: this.images.offlineOrderIcon,
                            isWebOrder : false
                        });
                        offlineOrdersCount++;
                    }
                } else if (sapOrderNumbers && sapOrderNumbers.length == 0) {
                    this.myOrders.push({
                        isOnlineOrder :  false,
                        Id: order.Id,
                        OrderNumber: order.Order_Number__c,
                        OrderedDate: order.Actual_Order_Date__c,
                        Status: order.fxStatusB2B__c,
                        TotalAmount: orderTotal, //RWPS-5228
                        GrandTotalAmount : orderTotal, //RWPS-4881 //RWPS-5228
                        OrderProductLineCount: order.fxItemsQuantityTotal__c, //ECOM-3150 - garora@rafter.one - 2 May 2024 - mapping to roll up field to get total quantity on order
                        orderItems: order.SAP_Order_Items__r,
                        currencyIsoCode: order.Order_Net_Currency__c,
                        poNumber: order.Customer_PO_Number__c,// ECOM-95 - garora@rafter.one - 30 April 2024 - mapping to poNumber
                        // ECOM-95 - garora@rafter.one - 30 April 2024 - mapping to invoices to display on UI
                        invoices: order.Invoices__r,
                        InvoiceCount : order.Invoices__r?.length,
                        discontinuedDetails: unavailableProductDetails.discontinuedProductDetails, //RWPS - 4621
                        notSellableDetails: unavailableProductDetails.nonSellableProductDetails, //RWPS - 4621
                        isAllDiscontinuedProducts: (unavailableProductDetails && unavailableProductDetails.allDiscontinuedProducts && unavailableProductDetails.allDiscontinuedProducts == true) || (unavailableProductDetails && unavailableProductDetails.allNonSellableProducts && unavailableProductDetails.allNonSellableProducts == true) ? true : false, //RWPS-5230
                        iconStyle: this.images.offlineOrderIcon,
                        isWebOrder : false
                    });
                    offlineOrdersCount++;
                }
            }
            if (offlineOrdersCount == 0) {
                this.offlineOrderExists = false;
                this.tab1class = ACTIVE_TAB_1;
                this.tab2class = INACTIVE_DISABLED_TAB_2;
                this.selectedTab = ONLINE_ORDERS;
            } else {
                this.offlineOrderExists = true;
            }
            this.sortData('OrderedDate', 'desc'); //RWPS-3741
            this.totalOrders = this.myOrders.length;
            this.allOrdersCount = this.myOrders.length;
            //update default size
            this.nextLoadCount = this.defaultListSize;
            if (this.defaultListSize > this.totalOrders){
                this.nextLoadCount = this.totalOrders;
                this.toRecords = this.totalOrders; //RWPS-95 : garora@rafter.one - 29 April 2024 - taking totalRecords as toRecords if smaller than defaultsize
            } else {
                this.toRecords = this.defaultListSize;
            }
            const start = (this.currentPageNumber - 1) * this.defaultListSize;
            const end = this.defaultListSize * this.currentPageNumber;
            this.fromRecords = start == 0 ? start : start + 1; //RWPS-95 : garora@rafter.one - 28 April 2024 - value on page change
            for(let i=0; i<this.nextLoadCount; i++){
                this.ordersToDisplay.push(this.myOrders[i]);
            }
            if(this.totalOrders > this.defaultListSize){
                this.isLoadMore = true;
            }
            this.displayResults = true;
        }
        this.ordersNotFound = false;
        this.orderHistoryEmpty = this.ordersToDisplay == null || this.ordersToDisplay == undefined || this.ordersToDisplay.length == 0 ? true : false;
        this.totalOrders = this.myOrders.length;
        if (this.ordersToDisplay.length) {
            this.showOrders = true;
        }
        if (operateLoader == true) {
            this.showSpinner = false;
        }
    }

    /**
     * RWPS-4881
     * This function is used to setup online order data
     */
    async setupOnlineOrderData(operateLoader) {
        let result = JSON.parse(JSON.stringify(this.onlineOrders));
        let onlineAddOnOrders = this.onlineAddOnOrders && this.onlineAddOnOrders.length > 0 ? JSON.parse(JSON.stringify(this.onlineAddOnOrders)) : null; //4881
        let productIds = [];
        let sapOrderNumbers = [];
        let productMaterialNumbers = []; //RWPS-5230
        if (result) {
            for (let i = 0; i < result.length; i++) {
                let order = result[i];
                if (order && order.OrderItems && order.OrderItems.length > 0) {
                    for (let j = 0; j < order.OrderItems.length; j++) {
                        let orderItem = order.OrderItems[j];
                        if (orderItem && orderItem.Product2 && orderItem.Product2.Id) {
                            productIds.push(orderItem.Product2.Id);
                        }
                    }
                }
            }
        }

        if (onlineAddOnOrders) {
            //4881
            for (let i = 0; i < onlineAddOnOrders.length; i++) {
                let order = onlineAddOnOrders[i];
                if (order && order.SAP_Order_Items__r && order.SAP_Order_Items__r.length > 0) {
                    for (let j = 0; j < order.SAP_Order_Items__r.length; j++) {
                        let orderItem = order.SAP_Order_Items__r[j];
                        if (orderItem && orderItem.Order_Product__r && orderItem.Order_Product__r.Product2 && orderItem.Order_Product__r.Product2.Id) {
                            productIds.push(orderItem.Order_Product__r.Product2.Id);
                        }  else if (orderItem && orderItem.Material_Number__c) { //RWPS-5230
                            productMaterialNumbers.push(orderItem.Material_Number__c);
                        }
                    }
                }
            }
        }

        //RWPS-5230
        if (productMaterialNumbers && productMaterialNumbers.length > 0) {
            for (let j=0; j<productMaterialNumbers.length; j++) {
                if (this.partNoVsProductMap && this.partNoVsProductMap.get(productMaterialNumbers[j]) && this.partNoVsProductMap.get(productMaterialNumbers[j]).Id) {
                    productIds.push(this.partNoVsProductMap.get(productMaterialNumbers[j]).Id);
                }
            }
        }

        let productData = await fetchProductUnavailability({ productIdList: productIds });
        this.discontinuedAndNonSellableProductDetails = JSON.parse(JSON.stringify(productData));
        this.showOrders = false;
        this.myOrders = [];
        this.ordersToDisplay = [];
        this.isLoadMore = false;
        this.totalOrders = 0;
        this.fromRecords = 0;
        if (result) {
            for (let i = 0; i < result.length; i++) {
                let order = result[i];
                let orderNum;
                if (order.ECOM_SAP_Order_Number__c) {
                    orderNum = order.ECOM_SAP_Order_Number__c;
                    sapOrderNumbers.push(order.ECOM_SAP_Order_Number__c); //capturing SAP Order Number
                }
                else {
                    orderNum = order.OrderNumber;
                }
                let unavailableProductDetails = this.setNonAvailableProductDetails(order, true);
                //RWPS-4621 End
                this.myOrders.push({
                    isOnlineOrder :  true,
                    Id: order.Id,
                    OrderNumber: orderNum,
                    OrderedDate: order.OrderedDate,
                    Status: order.Status == 'Pending Review' || order.Status == 'Rejected' ? order.Status : order.ECOM_Order_Summary_Status__c,
                    TotalAmount: order.TotalAmount,
                    GrandTotalAmount: order.GrandTotalAmount,
                    OrderProductLineCount: order.ECOM_Total_Items__c, //ECOM-3150 - garora@rafter.one - mapping to new rollup field for getting sum of quantities
                    orderItems: order.OrderItems,
                    currencyIsoCode: order.CurrencyIsoCode,
                    poNumber: order.PoNumber, //ECOM-95 - garora@rafter.one - to display po number on front end
                    InvoiceCount: order.Invoices__r?.length, //ECOM-95 - garora@rafter.one - getting invoice count
                    invoices: order.Invoices__r,
                    discontinuedDetails: unavailableProductDetails.discontinuedProductDetails, //RWPS - 4621
                    notSellableDetails: unavailableProductDetails.nonSellableProductDetails, //RWPS - 4621
                    isAllDiscontinuedProducts: (unavailableProductDetails && unavailableProductDetails.allDiscontinuedProducts && unavailableProductDetails.allDiscontinuedProducts == true) || (unavailableProductDetails && unavailableProductDetails.allNonSellableProducts && unavailableProductDetails.allNonSellableProducts == true) ? true : false, //RWPS-5230
                    iconStyle: this.images.onlineOrderIcon,
                    isWebOrder : true
                });
            }
        }

        //4881
        if (onlineAddOnOrders) {
            for(let i=0; i < onlineAddOnOrders.length; i++) {
                let order = onlineAddOnOrders[i];
                let unavailableProductDetails = this.setNonAvailableProductDetails(order, false);
                //START - RWPS-5228
                let orderTotal = 0;
                if(order.Order_Net_Value__c){
                    orderTotal = order.Order_Net_Value__c
                }
                if (order.Order_Level_Tax__c) {
                    orderTotal += order.Order_Level_Tax__c;
                }
                if (order.Total_Tariff_Surcharge__c) {
                    orderTotal += order.Total_Tariff_Surcharge__c;
                }
                //END - RWPS-5228
                if (sapOrderNumbers && sapOrderNumbers.length > 0) {
                    if (!sapOrderNumbers.includes(order.Name)) {
                        this.myOrders.push({
                            isOnlineOrder :  true,
                            Id: order.Id,
                            OrderNumber: order.Order_Number__c,
                            OrderedDate: order.Actual_Order_Date__c,
                            Status: order.fxStatusB2B__c,
                            TotalAmount: orderTotal, //RWPS-5228
                            GrandTotalAmount : orderTotal, //RWPS-4881 //RWPS-5228
                            OrderProductLineCount: order.fxItemsQuantityTotal__c, //ECOM-3150 - garora@rafter.one - 2 May 2024 - mapping to roll up field to get total quantity on order
                            orderItems: order.SAP_Order_Items__r,
                            currencyIsoCode: order.Order_Net_Currency__c,
                            poNumber: order.Customer_PO_Number__c,// ECOM-95 - garora@rafter.one - 30 April 2024 - mapping to poNumber // ECOM-95 - garora@rafter.one - 30 April 2024 - mapping to invoices to display on UI
                            invoices: order.Invoices__r,
                            InvoiceCount : order.Invoices__r?.length,
                            discontinuedDetails: unavailableProductDetails.discontinuedProductDetails, //RWPS - 4621
                            notSellableDetails: unavailableProductDetails.nonSellableProductDetails, //RWPS - 4621
                            isAllDiscontinuedProducts: (unavailableProductDetails && unavailableProductDetails.allDiscontinuedProducts && unavailableProductDetails.allDiscontinuedProducts == true) || (unavailableProductDetails && unavailableProductDetails.allNonSellableProducts && unavailableProductDetails.allNonSellableProducts == true) ? true : false, //RWPS-5230
                            iconStyle: this.images.onlineOrderIcon,
                            isWebOrder : false
                        });
                        sapOrderNumbers.push(order.Name);
                    }
                } else if (sapOrderNumbers && sapOrderNumbers.length == 0) {
                    this.myOrders.push({
                        isOnlineOrder :  true,
                        Id: order.Id,
                        OrderNumber: order.Order_Number__c,
                        OrderedDate: order.Actual_Order_Date__c,
                        Status: order.fxStatusB2B__c,
                        TotalAmount: orderTotal, //RWPS-5228
                        GrandTotalAmount : orderTotal, //RWPS-4881 //RWPS-5228
                        OrderProductLineCount: order.fxItemsQuantityTotal__c, //ECOM-3150 - garora@rafter.one - 2 May 2024 - mapping to roll up field to get total quantity on order
                        orderItems: order.SAP_Order_Items__r,
                        currencyIsoCode: order.Order_Net_Currency__c,
                        poNumber: order.Customer_PO_Number__c,// ECOM-95 - garora@rafter.one - 30 April 2024 - mapping to poNumber // ECOM-95 - garora@rafter.one - 30 April 2024 - mapping to invoices to display on UI
                        invoices: order.Invoices__r,
                        InvoiceCount : order.Invoices__r?.length,
                        discontinuedDetails: unavailableProductDetails.discontinuedProductDetails, //RWPS - 4621
                        notSellableDetails: unavailableProductDetails.nonSellableProductDetails, //RWPS - 4621
                        isAllDiscontinuedProducts: (unavailableProductDetails && unavailableProductDetails.allDiscontinuedProducts && unavailableProductDetails.allDiscontinuedProducts == true) || (unavailableProductDetails && unavailableProductDetails.allNonSellableProducts && unavailableProductDetails.allNonSellableProducts == true) ? true : false, //RWPS-5230
                        iconStyle: this.images.onlineOrderIcon,
                        isWebOrder : false
                    });
                    sapOrderNumbers.push(order.Name);
                }
            }
        }
        //4881
        this.sortData('OrderedDate', 'desc'); //RWPS-3741
        this.totalOrders = this.myOrders.length;
        this.onlineOrdersCount = this.myOrders.length;
        if (this.offlineOrderExists == false) {
            this.allOrdersCount = this.onlineOrdersCount;
        }
        //update default size
        this.nextLoadCount = this.defaultListSize;
        if (this.defaultListSize > this.totalOrders) {
            this.nextLoadCount = this.totalOrders;
            this.toRecords = this.totalOrders; //RWPS-95 : garora@rafter.one - 28 April 2024 - taking totalRecords as toRecords if smaller than defaultsize
        }  else {
            this.toRecords = this.defaultListSize;
        }
        const start = (this.currentPageNumber - 1) * this.defaultListSize;
        const end = this.defaultListSize * this.currentPageNumber;
        this.fromRecords = start == 0 ? start : start + 1; //RWPS-95 : garora@rafter.one - 28 April 2024 - value on page change

        for (let i = 0; i < this.nextLoadCount; i++) {
            this.ordersToDisplay.push(this.myOrders[i]);
        }
        if (this.ordersToDisplay.length) {
            this.showOrders = true;
        }
        this.orderHistoryEmpty = this.ordersToDisplay == null || this.ordersToDisplay == undefined || this.ordersToDisplay.length == 0 ? true : false;
        if (this.totalOrders > this.defaultListSize) {
            this.isLoadMore = true;
        }
        if (operateLoader == true) {
            this.showSpinner = false;
        }
    }

    /**
     * RWPS-4881
     * This function is perform the redirection
     */
    async handleRedirection() {
        this.showSpinner = true;
        let redirectionURL = ECOM_SELF_SERVICE_LINKOUT.split(',')[0];
        if (this.hierarchyNumber && this.isPunchoutUser) {
            let urlParametersMap = await getEncodedValues({urlParametersMap : {
                'hierarchyNumber' : this.hierarchyNumber,
                'searchData' : this.searchTerm,
                'salesOrg' : this.salesOrgDetails && this.salesOrgDetails.data ? this.salesOrgDetails.data : null}})
            if (urlParametersMap) {
                redirectionURL = ECOM_SELF_SERVICE_LINKOUT.split(',')[0] + ECOM_SELF_SERVICE_LINKOUT.split(',')[1] + QUERY_PARAM_START_CHARACTER + HIERARCHY_NUMBER + EQUALS_SYMBOL + encodeURIComponent(urlParametersMap.hierarchyNumber) + AND_SYMBOL + SEARCH_DATA + EQUALS_SYMBOL + encodeURIComponent(urlParametersMap.searchData) + AND_SYMBOL + SALES_ORG + EQUALS_SYMBOL + encodeURIComponent(urlParametersMap.salesOrg);
            }
        }

        window.open(redirectionURL,'_blank');
        this.showSpinner = false;
    }
}