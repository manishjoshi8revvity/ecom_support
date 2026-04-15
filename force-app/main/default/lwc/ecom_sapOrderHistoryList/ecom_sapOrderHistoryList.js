import { LightningElement, api,track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { MessageContext, publish } from 'lightning/messageService';
import ECOM_MESSAGE from '@salesforce/messageChannel/ecom_MessagingChannel__c';
import communityId from '@salesforce/community/Id';
import getAllMySapOrders from '@salesforce/apex/ECOM_OrderHistoryController.getAllMySapOrders';
import findOrder from '@salesforce/apex/ECOM_OrderHistoryController.findSapOrderByOrderNumberAndZip';
import contextApi from 'commerce/contextApi';
import addItemsToCart from '@salesforce/apex/ECOM_OrderHistoryController.addItemsToCart';
import ssrc_ECOM_Theme from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import FORM_FACTOR from '@salesforce/client/formFactor';
import ECOM_105105 from '@salesforce/label/c.ECOM_105105';
import fetchProductUnavailability from '@salesforce/apex/ECOM_OrderHistoryController.fetchProductUnavailability'; //RWPS-4881
import ECOM_REPLACEMENT_MSG from '@salesforce/label/c.ECOM_REPLACEMENT_MSG';//RWPS-4881
import ECOM_INDIRECT_REPLACEMENT_MSG from '@salesforce/label/c.ECOM_INDIRECT_REPLACEMENT_MSG';//RWPS-4881
import ECOM_DISCONTINUE_MSG from '@salesforce/label/c.ECOM_DISCONTINUE_MSG';//RWPS-4881
import ECOM_105103 from '@salesforce/label/c.ECOM_105103';//RWPS-4881
import ECOM_SELF_SERVICE_LINKOUT from '@salesforce/label/c.ECOM_SELF_SERVICE_LINKOUT'; //RWPS-5286
import ECOM_Order_History_Advance_Search_Tool_Text from '@salesforce/label/c.ECOM_Order_History_Advance_Search_Tool_Text'; //RWPS-5286

//js import
import { SYSTEM_LABELS,getUserConfigData } from 'c/ecom_punchoutUtil';

const NAVIGATE_TO_PLP = 'PLP';
const CMS_NAVIGATION = 'CMSNavigation';
const OPERATE_LOADER_EVENT = 'operateloading'; //RWPS-4881
const UNIQUE_STRING_SEPERATOR = '*#*'; // RWPS-5286

export default class Ecom_sapOrderHistoryList extends NavigationMixin(LightningElement) {
    @api searchTerm = '';
    @api sapOrder;
    @api orderData; //RWPS-4881
    showSpinner = false;
    isShowModal = false;
    myOrders;
    isOrderHistoryPage;
    totalOrders;
    defaultListSize = 5;
    fromRecords = 0; //RWPS-95 : garora@rafter.one - 29 April 2024 - for records counter
    toRecords = this.defaultListSize; //RWPS-95 : garora@rafter.one - 29 April 2024 - for records counter
    nextLoadCount;
    ordersToDisplay = [];
    isLoadMore = false;
    showErrorMsg = false;
    effectiveAccountId;
    orderNumber = '';
    shippingZip = '';
    isFindOrderDisabled = true;
    partNoVsProductMap = new Map();
    currentPageNumber = 1;
    isOrderHistoryEmpty = false;
    currencyDisplayAs='code';
    erroneousPartsToDisplay=[];
    successfulParts=[];
    showMessagePage=false;
    showErrorParts=false;
    showSuccessParts=false;
    modalSize='';
    orderAgainRestrict=false;
    #escapeKeyCallback; // RWPS-4087

    @track
    discontinuedAndNonSellableProductDetails; //RWPS-4881 : Collection to hold unavailable product details

	//labels
    system_labels = SYSTEM_LABELS;

    @track
    images = {
        arrowimg: ssrc_ECOM_Theme + '/img/rightarrow.png',
        againimg: ssrc_ECOM_Theme + '/img/again.png',
        orderagain:ssrc_ECOM_Theme + '/img/orderagainpurple.svg', //RWPS-95 : garora@rafter.one - 29 April 2024 - change as per latest figma
        onlineOrderIcon: ssrc_ECOM_Theme + '/img/onlineorder.svg', //RWPS-4881
        offlineOrderIcon: ssrc_ECOM_Theme + '/img/offlineorder.svg', //RWPS-4881
    }
    @api
    device = {
        isMobile : FORM_FACTOR==='Small',
        isDesktop : FORM_FACTOR==='Large',
        isTablet :FORM_FACTOR==='Medium'
    }

    @wire(MessageContext)
    messageContext;
    get sortOption() {
        return [
            { label: 'Sort by: Oldest', value: 'oldest' }, //RWPS-95 : garora@rafter.one - 29 April 2024 - change as per latest figma
            { label: 'Sort by: Newest', value: 'newest' } //RWPS-95 : garora@rafter.one - 29 April 2024 - change as per latest figma
        ];
    }

    get orderHistoryEmpty()
    {
        if(this.ordersToDisplay.length==0)
        {
            return true;
        }else{
            return false;
        }
    }

    // RWPS-5286 start
    get showAdvancedSearchInListing() {
        return this.searchTerm?.trim();
    }

    get selfServiceHomeLink() {
        return ECOM_SELF_SERVICE_LINKOUT.split(',')[0];
    }

    get advanceSearchToolText() {
        return ECOM_Order_History_Advance_Search_Tool_Text.split(UNIQUE_STRING_SEPERATOR)[0];
    }

    get advanceSearchToolLink() {
        return ECOM_Order_History_Advance_Search_Tool_Text.split(UNIQUE_STRING_SEPERATOR)[1];
    }
    // RWPS-5286 end

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

    //VRa - punchout changes - begin
    displayResults = false;
    get hasOrdersToDisplay(){
        return this.ordersToDisplay && this.ordersToDisplay.length >0 ? true : false;
    }

    get currentSapOrdersToDisplay(){
        return this.ordersToDisplay;
    }

    //VRa - Punchout changes - end

    connectedCallback(){

        //VRa- changes for punchout  - begin
        let userConfig = getUserConfigData();
        if(userConfig){
            this.isPunchoutUser = userConfig['isPunchoutUser'];
           // if(this.isPunchoutUser) this.isOrderHistoryPage = true;
        }
        //VRa- changes for punchout - end

        //console.log('connectedCallback',this.sapOrders);
        if (window.location.href.indexOf("orderHistory") != -1){
            this.isOrderHistoryPage = true;
        }
        this.showSpinner = true;
        const result = contextApi.getSessionContext();
        result.then((response) => {
            this.effectiveAccountId = response.effectiveAccountId;
            if(this.effectiveAccountId) {
                this.setupComponent(); //RWPS-4881
            }
        }).catch((error) => {
            this.showSpinner = false;
        });
        this.loadBasedOnDeviceType();
        // RWPS-4087 start
        this.#escapeKeyCallback = this.escapeKeyCallback.bind(this);
        document.addEventListener('keydown', this.#escapeKeyCallback);

    }
    disconnectedCallback() {
        document.removeEventListener('keydown', this.#escapeKeyCallback);
    }

    escapeKeyCallback(event) {
        if (event.key === 'Escape' || event.keyCode === 27) {
            if(this.showMessagePage) {
                this.handleMessageScreenClose(event);
            }
            if(this.isShowModal) {
                this.hideModalBox();
            }
        }
    }// RWPS-4087 end

    loadBasedOnDeviceType() {
        if (this.device.isMobile) {
            this.modalSize = "slds-modal slds-fade-in-open slds-modal_full";
        } else {
            this.modalSize = "slds-modal slds-fade-in-open modalCSS";
        }
    }

    /**
     * RWPS-4881 : This function structures the order details
     * Sachin Vispute | 28.10.2025
     */
    @api
    async setupComponent() {
        if (this.orderData) {
            this.fireOperateLoader(true);
            this.currentPageNumber = 1;
            let result = JSON.parse(JSON.stringify(this.orderData));
            if(result && result.Status == 'Success') {
                let productIds = [];
                let productMaterialNumbers = []; //RWPS-5230
                //Offline Orders
                for (let i = 0; i < result.orders.length; i++) {
                    let order = result.orders[i];
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

                //RWPS-5230
                if (productMaterialNumbers && productMaterialNumbers.length > 0) {
                    for (let j=0; j<productMaterialNumbers.length; j++) {
                        if (result.partNoVsProductMap && result.partNoVsProductMap[productMaterialNumbers[j]] && result.partNoVsProductMap[productMaterialNumbers[j]].Id) {
                            productIds.push(result.partNoVsProductMap[productMaterialNumbers[j]].Id);
                        }
                    }
                }

                let productData = await fetchProductUnavailability({ productIdList: productIds });
                this.discontinuedAndNonSellableProductDetails = JSON.parse(JSON.stringify(productData));
                let orders = result.orders;
                for (var key in result.partNoVsProductMap) {
                    this.partNoVsProductMap.set(key,result.partNoVsProductMap[key])
                }
                if(this.partNoVsProductMap.size==0){
                    this.orderAgainRestrict=true;
                }
                this.myOrders = [];
                this.ordersToDisplay = [];
                for(let i=0; i<orders.length; i++){
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
                    this.myOrders.push({
                        isOnlineOrder : false,
                        Id: order.Id,
                        OrderNumber: order.Order_Number__c,
                        OrderedDate: order.Actual_Order_Date__c,
                        Status: order.fxStatusB2B__c,
                        TotalAmount: orderTotal,//RWPS-5228
                        OrderProductLineCount: order.fxItemsQuantityTotal__c, //ECOM-3150 - garora@rafter.one - 2 May 2024 - mapping to roll up field to get total quantity on order
                        orderItems: order.SAP_Order_Items__r,
                        currencyIsoCode: order.Order_Net_Currency__c,
                        poNumber: order.Customer_PO_Number__c,// ECOM-95 - garora@rafter.one - 30 April 2024 - mapping to poNumber
                        // ECOM-95 - garora@rafter.one - 30 April 2024 - mapping to invoices to display on UI
                        invoices: order.Invoices__r,
                        InvoiceCount : order.Invoices__r?.length,
                        discontinuedDetails: unavailableProductDetails.discontinuedProductDetails, //RWPS - 4881
                        notSellableDetails: unavailableProductDetails.nonSellableProductDetails, //RWPS - 4881
                        isAllDiscontinuedProducts: (unavailableProductDetails && unavailableProductDetails.allDiscontinuedProducts && unavailableProductDetails.allDiscontinuedProducts == true) || (unavailableProductDetails && unavailableProductDetails.allNonSellableProducts && unavailableProductDetails.allNonSellableProducts == true) ? true : false, //RWPS-5230
                        iconStyle: this.images.offlineOrderIcon
                    });
                }
                this.sortData('OrderedDate', 'desc'); //RWPS-3741
                this.totalOrders = this.myOrders.length;
                //update default size
                this.nextLoadCount = this.defaultListSize;
                if(this.defaultListSize > this.totalOrders){
                    this.nextLoadCount = this.totalOrders;
                    this.toRecords = this.totalOrders; //RWPS-95 : garora@rafter.one - 29 April 2024 - taking totalRecords as toRecords if smaller than defaultsize
                } else {
                    this.toRecords = this.defaultListSize;
                } //RWPS-4881
                const start = (this.currentPageNumber - 1) * this.defaultListSize;
                const end = this.defaultListSize * this.currentPageNumber;
                this.fromRecords = start == 0 ? start : start + 1; //RWPS-95 : garora@rafter.one - 28 April 2024 - value on page change
                for(let i=0; i<this.nextLoadCount; i++){
                    this.ordersToDisplay.push(this.myOrders[i]);
                }
                if(this.totalOrders > this.defaultListSize){
                        this.isLoadMore = true;
                }
                this.isOrderHistoryEmpty = this.ordersToDisplay?.length == 0 && !this.showSpinner? true : false;
				this.displayResults = true;
                this.showSpinner = false;
                this.fireOperateLoader(false);
            }
        }
    }

    /**
     * RWPS-4881 : This function structures the unavailable product details
     * Sachin Vispute | 30.09.2025
     * @param {*} order
     * @returns productDetails Collection
     */
    setNonAvailableProductDetails(order, isOnlineOrder) {
        //RWPS-4881 Start
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
                if (isOnlineOrder == true && order && order.OrderItems && order.OrderItems.length > 0) {
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
                    for (let j = 0; j < order.SAP_Order_Items__r.length; j++) {
                        let orderItem = order.SAP_Order_Items__r[j];
                        //RWPS-5230
                        if ((orderItem && orderItem.Order_Product__r && orderItem.Order_Product__r.Product2 && orderItem.Order_Product__r.Product2.Id == currentItem) ||
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
                if (isOnlineOrder == true && order && order.OrderItems && order.OrderItems.length > 0) {
                    for (let j = 0; j < order.OrderItems.length; j++) {
                        let orderItem = order.OrderItems[j];
                        if (orderItem && orderItem.Product2 && orderItem.Product2.Id == currentItem) {
                            nonSellableProductDetails.value = true;
                            nonSellableProductDetails.message = ECOM_105103;
                            discontinuedProductDetails.value = false;
                            nonSellableProductsCount++; //RWPS-4881
                        }
                    }
                    allNonSellableProducts = nonSellableProductsCount == order.OrderItems.length ? true : false; //RWPS-4881
                    nonSellableProductCount = nonSellableProductsCount; //RWPS-5230
                } else if (isOnlineOrder == false && order && order.SAP_Order_Items__r && order.SAP_Order_Items__r.length > 0) {
                    for (let j = 0; j < order.SAP_Order_Items__r.length; j++) {
                        let orderItem = order.SAP_Order_Items__r[j];
                        //RWPS-5230
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

    @api getMyOrders() {
        getAllMySapOrders(

        )
        .then((result) => {
            if(result && result.Status == 'Success'){
                let orders = result.orders;
                for (var key in result.partNoVsProductMap) {
                    this.partNoVsProductMap.set(key,result.partNoVsProductMap[key])
                }
                if(this.partNoVsProductMap.size==0){
                    this.orderAgainRestrict=true;
                }
                this.myOrders = [];
                this.ordersToDisplay = [];
                for(let i=0; i<orders.length; i++){
                    let order = orders[i];
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
                    this.myOrders.push({
                        Id: order.Id,
                        OrderNumber: order.Order_Number__c,
                        OrderedDate: order.Actual_Order_Date__c,
                        Status: order.fxStatusB2B__c,
                        TotalAmount: orderTotal, //RWPS-5228
                        OrderProductLineCount: order.fxItemsQuantityTotal__c, //ECOM-3150 - garora@rafter.one - 2 May 2024 - mapping to roll up field to get total quantity on order
                        orderItems: order.SAP_Order_Items__r,
                        currencyIsoCode: order.Order_Net_Currency__c,
                        poNumber: order.Customer_PO_Number__c,// ECOM-95 - garora@rafter.one - 30 April 2024 - mapping to poNumber
                        // ECOM-95 - garora@rafter.one - 30 April 2024 - mapping to invoices to display on UI
                        invoices: order.Invoices__r,
                        InvoiceCount : order.Invoices__r?.length
                    });
                }
                this.sortData('OrderedDate', 'desc'); //RWPS-3741
                this.totalOrders = this.myOrders.length;
                //update default size
                this.nextLoadCount = this.defaultListSize;
                if(this.defaultListSize > this.totalOrders){
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
                this.showSpinner = false;
                this.isOrderHistoryEmpty = this.ordersToDisplay?.length == 0 && !this.showSpinner? true : false;
				this.displayResults = true;
            }
            })
            .catch((error) => {
                console.log('error =>'+JSON.stringify(error));
            });
    }

    // Add order items to the cart and redirect to the cart page
    handleOrderAgain(event){
        let orderId = event.currentTarget.dataset.id;
        let orderItems = this.myOrders.find(e=>e.Id===orderId)?.orderItems;
        if(this.orderAgainRestrict){
            for(let i in orderItems){
                this.erroneousPartsToDisplay.push({
                    partNumber : orderItems[i].Material_Number__c,
                    reason : ECOM_105105
                });
            }
            if(this.erroneousPartsToDisplay.length>0){
                this.showErrorParts=true;
                this.showMessagePage=true;
            }
            return;
        }
        let productIdTopartNumberMap = new Map();
        this.erroneousPartsToDisplay=[];
        this.successfulParts=[];
        this.showErrorParts=false;
        this.showSuccessParts=false;
        for (let i in orderItems) {
            //RWPS-4881 : Added null checks
            if (orderItems[i] && orderItems[i].Material_Number__c && this.partNoVsProductMap && this.partNoVsProductMap.get(orderItems[i].Material_Number__c) && this.partNoVsProductMap.get(orderItems[i].Material_Number__c).Id) {
                productIdTopartNumberMap.set(this.partNoVsProductMap.get(orderItems[i].Material_Number__c).Id,orderItems[i].Material_Number__c);
            }
        }
        if(orderItems){
            this.showSpinner = true;
            let cartItems = this.setOrderItemsList(orderItems);
            if(cartItems.length > 0){
            // Call the 'addItemsToCart' apex method imperatively
                addItemsToCart({
                    communityId: communityId,
                    effectiveAccountId: this.effectiveAccountId,
                    cartItems: cartItems
                }).then((results) => {
                    this.showSpinner = false;
                    let productData = JSON.parse(JSON.stringify(this.discontinuedAndNonSellableProductDetails)); //RWPS-4881
                    for(let i in cartItems)
                    {
                        if(!((results.itemsAddedSuccessfully).includes(cartItems[i]?.Product2Id)))
                        {
                            //RWPS-5230 : start
                            if (productData && productData.discontinuedProducts) {
                                productData.discontinuedProducts.forEach(currentItem => {
                                    if (cartItems[i] && cartItems[i].Product2Id && cartItems[i].Product2Id == currentItem) {
                                        if (productData.directReplacementProductMap && productData.directReplacementProductMap.hasOwnProperty(currentItem)) {
                                            this.erroneousPartsToDisplay.push({
                                                partNumber: productIdTopartNumberMap.get(cartItems[i]?.Product2Id),
                                                reason: ECOM_REPLACEMENT_MSG + ' ' + productData.directReplacementProductMap[currentItem] + '.' //RWPS-5079 Added Space
                                            });
                                        } else if (productData.indirectReplacementProductMap && productData.indirectReplacementProductMap.hasOwnProperty(currentItem)) {
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
                            //RWPS-5230 : End
                        }
                        else
                        {
                            this.successfulParts.push({
                                partNumber : productIdTopartNumberMap.get(cartItems[i]?.Product2Id)
                            });
                        }
                    }

                    if(this.erroneousPartsToDisplay.length>0){
                        this.showErrorParts=true;
                        this.showMessagePage=true;
                    }
                    if(this.successfulParts.length>0){
                        this.showSuccessParts=true;
                        this.showMessagePage=true;
                    }
                    //RWPS-3764 start
                    if(this.showMessagePage)
                    {

                        setTimeout(() => {
                            const modal = this.template.querySelector('[data-id="view-order-details"]');
                            if (modal) {
                                modal.focus();
                            }
                            }, 0);
                        }//RWPS-3764 end

                    let payLoad = {message:1,
                        type: 'CartRefresh'
                    };
                    publish(this.messageContext, ECOM_MESSAGE, payLoad);

                    this.dispatchEvent(new CustomEvent('saporderhistory', {
                        detail: {
                            mes8sage: 'Increased count to ' + (++this.count)
                        }
                    }));

                   //datalayer regarding changes starts
                   try {
                    let  orderData =[] ;
                        for (const property in results.products) {
                            var r =0;
                            var itemQuantity= cartItems[r].Quantity;
                            r++;
                            orderData.push({
                                    'name': results.products[property].productName,
                                    'quantity':itemQuantity

                            });
                        }

                        this.dispatchEvent(new CustomEvent('orderdetails', {
                            detail: orderData,
                            orderId : orderId
                        }));

                    } catch (error) {
                    console.error('Error occured during preparing DataLayer data ',error);
                      }
                    //datalayer regarding changes starts

                }).catch((error) => {
                    this.showSpinner=false;
                    for(let i in cartItems){
                        this.erroneousPartsToDisplay.push({
                            partNumber : productIdTopartNumberMap.get(cartItems[i]?.Product2Id),
                            reason : ECOM_105105
                        });
                    }
                    if(this.erroneousPartsToDisplay.length>0){
                        this.showErrorParts=true;
                        this.showMessagePage=true;
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

    handleMessageScreenRedirectToCart(event)
    {
        // this[NavigationMixin.Navigate]({
        //     type: 'standard__webPage',
        //         attributes: {
        //         url: '/cart'
        //         }
        //     });
        let currentUrl = window.location.href;
        let baseUrl = currentUrl.split('/');
        let finalUrl = baseUrl[0]+'/cart';
        window.location.href = finalUrl;
    }

    handleMessageScreenClose(event){
        this.showMessagePage=false;
    }

    handleLoadMoreOrders(event){
        if(this.isLoadMore){
            this.nextLoadCount =  this.ordersToDisplay.length + this.defaultListSize;
            this.ordersToDisplay = [];
            if(this.nextLoadCount > this.totalOrders){
                this.nextLoadCount = this.totalOrders;
            }
            for(let i=0; i<this.nextLoadCount;i++){
                this.ordersToDisplay.push(this.myOrders[i]);
            }
        }
        //disable Load More when total Orders are equals to display Order
        if(this.ordersToDisplay.length === this.totalOrders){
            this.isLoadMore = false;
        }

    }

    handleViewOrderDetails(event){
        let orderId = event.currentTarget.dataset.id;
        let finalSearchTerm = this.searchTerm ? this.searchTerm.trim() : ''; // RWPS-5286

        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/orderDetails?id=${orderId}` + (finalSearchTerm ? `&search=${encodeURIComponent(finalSearchTerm)}` : '') // RWPS-5286
            }
        });
    }

    get isLoadMoreEnabled(){
        return this.isLoadMore && this.isOrderHistoryPage;
    }

    openFindOrderPopUp(){
        this.isShowModal = true;
        this.showErrorMsg = false;
        //RWPS-3764 Start
        setTimeout(() => {
            const modal = this.template.querySelector('[data-id="find-order-modal"]');
            if (modal) {
              modal.focus();
            }
          }, 0);//RWPS-3764 end
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

    setOrderItemsList(orderItems){
        let formatedOrderItems = [];
        for (let i = 0; i < orderItems.length; i++) {
            if ( this.partNoVsProductMap && this.partNoVsProductMap.get(orderItems[i].Material_Number__c) && this.partNoVsProductMap.get(orderItems[i].Material_Number__c).Id && orderItems[i].Quantity_Ordered__c) {
                formatedOrderItems.push({Product2Id: this.partNoVsProductMap.get(orderItems[i].Material_Number__c).Id, Quantity: orderItems[i].Quantity_Ordered__c});
            }
        }
        return formatedOrderItems;
    }

    handleSortChange(event){
        let sortBy = event.detail.value;

        if(sortBy == 'oldest'){
            this.sortData('OrderedDate', 'asc'); //RWPS-3741
        }
        if(sortBy == 'newest'){
            this.sortData('OrderedDate', 'desc'); //RWPS-3741
        }
        //reset pagination
        this.currentPageNumber = 1;
        this.fromRecords = 0; //RWPS-95 : garora@rafter.one - 29 April 2024 - resetting to initial value
        this.toRecords = this.defaultListSize; //RWPS-95 : garora@rafter.one - 29 April 2024 - resetting to initial value
        this.ordersToDisplay = [];
        //update default size
        this.nextLoadCount = this.defaultListSize;
        if(this.defaultListSize > this.totalOrders){
            this.nextLoadCount = this.totalOrders;
            this.toRecords = this.totalOrders; //RWPS-95 : garora@rafter.one - 29 April 2024 - taking totalRecords as toRecords if smaller than defaultsize
        } else {
            this.toRecords = this.defaultListSize;
        } //RWPS-4881

        for(let i=0; i<this.nextLoadCount; i++){
            this.ordersToDisplay.push(this.myOrders[i]);
        }
       if(this.totalOrders > this.defaultListSize){
            this.isLoadMore = true;
       }

    }

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.myOrders));
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1: -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : '';
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.myOrders = parseData;
    }

    handleOrderNumberChange(event){
        if (event.target.value.length>0 && event.target.value==' ') {
            event.target.value = event.target.value.trim();
        }
        this.orderNumber = event.target.value;
        if(this.orderNumber.length>0 && this.shippingZip.length>0){
            this.isFindOrderDisabled = false;
        } else{
            this.isFindOrderDisabled = true;
        }
    }

    handleZipChange(event){
        //this.shippingZip = event.target.value;
        if (event.target.value.length>0 && event.target.value==' ') {
            event.target.value = event.target.value.trim();
        }
        this.shippingZip = event.target.value;
        if(this.orderNumber.length>0 && this.shippingZip.length>0){
            this.isFindOrderDisabled = false;
        } else {
            this.isFindOrderDisabled = true;
        }
    }

    handleFindOrder(){
        this.showSpinner = true;
        findOrder({orderNumber:this.orderNumber, zipCode:this.shippingZip})
        .then((result) => {
            if(result.length > 0){
                let searchedOrder = result;
                //console.log('searchedOrder', searchedOrder);
                this.showSpinner = false;
                this.isLoadMore = false;
                this.myOrders = [];
                for(let i=0; i<result.length; i++){
                    let order = result[i];
                    this.myOrders.push({
                        Id: order.Id,
                        OrderNumber: order.Order_Number__c,
                        OrderedDate: order.Actual_Order_Date__c,
                        Status: order.fxStatusB2B__c,
                        TotalAmount: order.Order_Total_Price__c,
                        OrderProductLineCount: order.fxItemsQuantityTotal__c, //ECOM-3150 - garora@rafter.one - 2 May 2024 - mapping to roll up field to get total quantity on order
                        orderItems: order.SAP_Order_Items__r,
                        currencyIsoCode: order.Order_Net_Currency__c,
                        poNumber: order.Customer_PO_Number__c,// ECOM-95 - garora@rafter.one - 2 May 2024 - mapping to poNumber
                        // ECOM-95 - garora@rafter.one - 2 May 2024 - mapping to invoices to display on UI
                        invoices: order.Invoices__r,
                        InvoiceCount : order.Invoices__r?.length
                    });
                }
                this.sortData('OrderedDate', 'desc'); //RWPS-3741
                this.totalOrders = this.myOrders.length;
                //update default size
                this.nextLoadCount = this.defaultListSize;
                if(this.defaultListSize > this.totalOrders){
                    this.nextLoadCount = this.totalOrders;
                    this.toRecords = this.totalOrders; //RWPS-95 : garora@rafter.one - 29 April 2024 - taking totalRecords as toRecords if smaller than defaultsize
                } else {
                    this.toRecords = this.defaultListSize;
                } //RWPS-4881
                this.ordersToDisplay = [];
                for(let i=0; i<this.nextLoadCount; i++){
                    this.ordersToDisplay.push(this.myOrders[i]);
                }
                if(this.totalOrders > this.defaultListSize){
                    this.isLoadMore = true;
                }
                this.isShowModal = false;
            }
            else{
                this.showErrorMsg = true;
            }
            this.showSpinner = false;
        })
        .catch((error) => {
            console.log('error =>'+JSON.stringify(error));
            this.userDetails = undefined;
        });
    }

    pageChanged(event) {
        let pageNumber = JSON.parse(JSON.stringify(event.detail.pageNumber));
        this.currentPageNumber = parseInt(pageNumber);
        const start = (this.currentPageNumber-1)*this.defaultListSize;
        const end = this.defaultListSize*this.currentPageNumber;
        this.fromRecords = start==0 ? start : start+1; //RWPS-95 : garora@rafter.one - 29 April 2024 - value on page change
        this.toRecords = end>this.totalOrders ? this.totalOrders : end ; //RWPS-95 : garora@rafter.one - 29 April 2024 - value on page change
        this.ordersToDisplay = this.myOrders.slice(start, end);

    }

     handleShopNow(){
        let payLoad = {message: NAVIGATE_TO_PLP,
            type: CMS_NAVIGATION,
            partNumber: this.partNumberCode
        };
        publish(this.messageContext, ECOM_MESSAGE, payLoad);
    }

    //ECOM-95 - garora@rafter.one - 30 April 2024 - onclick action for viewing invoice details
    handleViewInvoiceDetails(event){
        let dataId = event.target.dataset.id;
        let chevronIcon = this.template.querySelector("[data-icon=\"" + dataId + "\"]");
        if(chevronIcon){
            chevronIcon.classList.toggle("chevron-up");
        }
        let section = this.template.querySelector("[data-invoice=\"" + dataId + "\"]");
        if(section){
            section.classList.toggle("doNotDisplay");
        }
    }

    goToInvoiceDetailPage(event){
        let invoiceId = event.currentTarget.dataset.id;
        let orderId = event.currentTarget.dataset.order;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/invoiceDetails?invoiceid=`+invoiceId+`&orderid=`+orderId
            }
        });
    }
    //RWPS-3764 start
    handleFindOrderKeyDown(event) {
        if (event.key === 'Enter' || event.keyCode === 13) {
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
            if(this.showSpinner)//RWPS-4087 start
            {
                return;
            }//RWPS-4087 end
            this.handleOrderAgain(event);
        }
    }
    //RWPS-3764 end

    //RWPS-4881 - function to fire event to operate loader
    fireOperateLoader(isLoading) {
        this.dispatchEvent(new CustomEvent(OPERATE_LOADER_EVENT, {
            detail: {
                isLoading : isLoading
            }
        }));
    }

}