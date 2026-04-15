import addItemsToCart from '@salesforce/apex/ECOM_CartController.addItemsToCart';
import retrieveProductsByPartNumber from '@salesforce/apex/ECOM_CartController.retrieveProductsByPartNumber';
import getPrimaryCartBasedOnOwner from '@salesforce/apex/ECOM_CartController.getPrimaryCartBasedOnOwner';
import getProductSalesByProdIdAndMaterialCodes from '@salesforce/apex/ECOM_CartController.getProductSalesByProdIdAndMaterialCodes';
import fetchProductUnavailability from '@salesforce/apex/ECOM_OrderHistoryController.fetchProductUnavailability'; //RWPS-3772
import getOrCreateCartSummary from '@salesforce/apex/ECOM_CartController.getCartSummary';
import retrieveProductsByPartialPartNumber from '@salesforce/apex/ECOM_CartController.retrieveProductsByPartialPartNumber';
import FORM_FACTOR from '@salesforce/client/formFactor';
import communityId from '@salesforce/community/Id';
import ECOM_DATALAYERCHANNEL from '@salesforce/messageChannel/ecom_DataLayer__c';
import ECOM_MESSAGE from '@salesforce/messageChannel/ecom_MessagingChannel__c';
import sres_ECOM_CartIcons from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import ECOM_105101 from '@salesforce/label/c.ECOM_105101';
import ECOM_105103 from '@salesforce/label/c.ECOM_105103';
import ECOM_105107 from '@salesforce/label/c.ECOM_105107';

// Abhishek Joshi (abhishek.joshi@revvity.com) 2025.02.18 - Added ECOM_Quick_Order_File_Upload_Dropzone_Text and ECOM_Quick_Order_File_Upload_Button_Text labels - RWPS-2631
import ECOM_UploadDropzoneText from "@salesforce/label/c.ECOM_Quick_Order_File_Upload_Dropzone_Text";
import ECOM_UploadButtonText from "@salesforce/label/c.ECOM_Quick_Order_File_Upload_Button_Text";

import { sendPostMessage } from 'c/ecom_util';
import { MessageContext, publish } from 'lightning/messageService';
import { LightningElement, api, track, wire } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import sheetjs from '@salesforce/resourceUrl/ssrc_ECOM_Sheetjs';
import Id from "@salesforce/user/Id";
import processProductExclusions from '@salesforce/apex/ECOM_CartController.processProductExclusions';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import ECOM_Is_Punchout_User__c from '@salesforce/schema/User.ECOM_Is_Punchout_User__c';
import { trackAddProductToCart } from 'commerce/activitiesApi'; //RWPS-3125
import ECOM_Add_to_Cart from '@salesforce/label/c.ECOM_Add_To_Cart_CTA';//RWPS-3835
import ECOM_REPLACEMENT_MSG from '@salesforce/label/c.ECOM_REPLACEMENT_MSG';//RWPS-3772
import ECOM_DISCONTINUE_MSG from '@salesforce/label/c.ECOM_DISCONTINUE_MSG';//RWPS-3772
import ECOM_INDIRECT_REPLACEMENT_MSG from '@salesforce/label/c.ECOM_INDIRECT_REPLACEMENT_MSG';//RWPS-3772
let XLS = {};

export default class Ecom_myQuickOrder extends LightningElement {
    @api enableRecommendations = false; // RWPS-2858
    @api recommendationsToShow = ''; // RWPS-2858
    @api recommendationTitles = ''; // RWPS-2858

    userId = Id;

    // Abhishek Joshi (abhishek.joshi@revvity.com) 2025.02.18 - RWPS-2631
    labels = {ECOM_UploadDropzoneText, ECOM_UploadButtonText, ECOM_Add_to_Cart};//RWPS-3835

    @api
    images = {
        cartimg: sres_ECOM_CartIcons + '/img/bag-line.png',
        deleteimg: sres_ECOM_CartIcons + '/img/delete-icon.png',
        quickorderimg:sres_ECOM_CartIcons + '/img/quick-order.png',
        favoriteimg:sres_ECOM_CartIcons + '/img/heart-line.png',
        helpimg:sres_ECOM_CartIcons + '/img/help-icon.png',
        termsimg:sres_ECOM_CartIcons + '/img/pencil-line.png',
        qodelete:sres_ECOM_CartIcons + '/img/qo-delete.png',
        blackdelete:sres_ECOM_CartIcons + '/img/black-delete.svg',
        addmore:sres_ECOM_CartIcons + '/img/addmore.svg',
        purpledelete: sres_ECOM_CartIcons + '/img/delete-icon-purple.svg'
    }

    @track acceptedFormats = ['.csv','.xls', '.xlsx'];

    @track error;
    @track data = [];
    @track newpartNumber = '';
    @track newQuantity = '';
    @track columns = [
        { label: 'PartNumber', fieldName: 'Part_Number' },
        { label: 'Quantity', fieldName: 'Quantity', type: 'number' },
    ];
showUploadModal=false;

    // Simulated data for the quick order form
    @api
    _effectiveAccountId;
    @track
    quickOrderRows = [];
    addToCartRows = [];
    showModal=false;
    cartId;
    isPunchoutCart = false;
    cartItems = [];
    productSalesMap = new Map();
    erroneousParts=[];
    productArray=[];
    productNotAvailableToBuy=false;
    productsArray=[];
    productIds = [];
    partNumberNotFound=false;
    partNumberToProductIdMap = new Map();
    productIdTopartNumberMap=new Map();
    erroneousPartsToDisplay=[];
    successfulParts=[];
    showErrorParts=false;
    showSuccessParts=false;
    showMessagePage=false;
    showGoToCartButton=false;
    showErrorMessage=false;
    errorMessage=[];
    showSpinner=false;
    minQuantity=1;
    maxQuantity=999;
    type='';
    message='';
    @track modalSize = '';
    showMessage=false;
    timeSpan=0;
    @wire(MessageContext)
    messageContext;
    selectedPartNumber = [];
    @track
    device = {

        isMobile : FORM_FACTOR==='Small',
        isDesktop : FORM_FACTOR==='Large' || FORM_FACTOR==='Medium'
        }
    sidebarCSS='';
    middleSpaceCSS = '';
    mainSectionCSS = '';

    @track
    availabilityCheckProductIds; //RWPS-3772

    @track
    discontinuedAndNonSellableProductDetails; //RWPS-3772

    //RWPS-2312 START
    @track isPunchoutUser;
    @wire(getRecord, {
        recordId: USER_ID,
        fields: [ECOM_Is_Punchout_User__c]
    }) wireuser({
        error,
        data
    }) {
        if (error) {
           this.error = error ;
        } else if (data) {
            this.isPunchoutUser = data.fields.ECOM_Is_Punchout_User__c.value;
        }
    }//RWPS-2312 END
    @api
    openModal()
    {
        this.showModal = true;
    }
    #escapeKeyCallback; // RWPS-4086
    connectedCallback(){
        this.getCartSummary();
       this.setEmptyRows();
       this.loadBasedOnDeviceType();

       Promise.all([
        loadScript(this, sheetjs + '/sheetjs/sheetmin.js')
        ]).then(() => {
            XLS = XLSX;
        })

        // RWPS-4086 start
        this.#escapeKeyCallback = this.escapeKeyCallback.bind(this);
        document.addEventListener('keydown', this.#escapeKeyCallback);
        // RWPS-4086 end
    }

    // RWPS-4086 start

    disconnectedCallback() {
        document.removeEventListener('keydown', this.#escapeKeyCallback);
    }

    escapeKeyCallback(event) {
        if (event.key === 'Escape' || event.keyCode === 27) {
            if(this.showModal) {
                this.closeModal(event);
            }
            if(this.showUploadModal) {
                this.closeUpload(event);
            }
            if(this.showMessagePage) {
                this.handleMessageScreenClose(event);
            }
        }
    }
    // RWPS-4086 end

    loadBasedOnDeviceType() {
        //Tab UI fix - Gaurang - 17 July 2024
        var width = (window.innerWidth > 0) ? window.innerWidth : screen.width;
        if(FORM_FACTOR==='Medium' || (width==1025)){
            this.sidebarCSS = 'slds-size_12-of-12 slds-large-size_12-of-12 slds-medium-size_12-of-12 slds-small-size_12-of-12';
            this.middleSpaceCSS = 'doNotDisplay';
            this.mainSectionCSS = 'slds-size_12-of-12 slds-large-size_12-of-12 slds-medium-size_12-of-12 slds-small-size_12-of-12';
        }
        else{
            this.sidebarCSS = 'slds-size_12-of-12 slds-large-size_3-of-12 slds-medium-size_3-of-12 slds-small-size_12-of-12';
            this.middleSpaceCSS = 'slds-large-size_1-of-12 slds-medium-size_1-of-12';
            this.mainSectionCSS = 'slds-size_12-of-12 slds-large-size_8-of-12 slds-medium-size_8-of-12 slds-small-size_12-of-12';
        }

        if (this.device.isMobile) {
            this.modalSize = "slds-modal slds-fade-in-open slds-modal_full";

        } else {
            this.modalSize = "slds-modal slds-fade-in-open";
        }
    }

    setEmptyRows(){
        this.quickOrderRows = [];
        for (let orderIndex=0;orderIndex<5;orderIndex++)
        {
            this.quickOrderRows.push({PartNumber:'',Quantity:'',index:orderIndex,showDelete:orderIndex===0 ? false : true,imgSrc: this.images.qodelete});
        }
    }

    get effectiveAccountId(){
        return this._effectiveAccountId;
    }
    set effectiveAccountId(val){
        this._effectiveAccountId = val;
    }
    addToList(event)
    {
        var length=this.quickOrderRows?.length;
        this.quickOrderRows.push({PartNumber:'',Quantity:'',index:length,showDelete: true,imgSrc: this.images.qodelete});
    }

    defaultingValues()
    {
        this.showErrorParts=false;
        this.showSuccessParts=false;
        this.showGoToCartButton=false;
        this.showErrorMessage=false;
        this.errorMessage=[];
        this.cartItems=[];
        this.successfulParts=[];
        this.erroneousParts=[];
        this.erroneousPartsToDisplay=[];
        this.selectedPartNumber=[];
        this.productIds=[];
    }

    //RWPS-1528 Changes start
    get resolvedEffectiveAccountId() {
        const effectiveAccountId = this._effectiveAccountId || '';
        let resolved = null;
        if (
            effectiveAccountId.length > 0 &&
            effectiveAccountId !== '000000000000000'
        ) {
            resolved = effectiveAccountId;
        }
        return resolved;
    }

    getCartSummary() { //RWPS-1528
        this.showSpinner=true;//RWPS-2317
        getOrCreateCartSummary({
            communityId: communityId,
            effectiveAccountId: this.resolvedEffectiveAccountId,
            activeCartOrId: this.cartId,
        }).then((result) => {
            if(result){
                this.cartId = result?.cartId;
                this.showSpinner=false;//RWPS-2317
            }
            }).catch((error) => {
                this.showSpinner=false;//RWPS-2317
                console.log(error);
            });
    }
    //RWPS-1528 Changes end

    handleAddToCart(event){
        // RWPS-4086 start
        if(this.showSpinner) {
            return;
        }
        // RWPS-4086 end

        this.defaultingValues();
        if(this.doValidation()){
            //validate parts
            if(this.addToCartRows.length>0)
            {
                this.showSpinner=true;
                retrieveProductsByPartNumber({
                    productData : JSON.stringify(this.addToCartRows)
                }).then(result=>{
                    if(result.success)
                    {
                        this.getUnavailableProducts(result); //RWPS-3772
                        this.getErroneousParts(result); //RWPS-3772
                        this.getPrimaryCart();
                        for (let i = 0; i < result.products.length; i++) {
                            this.productIds.push(result.products[i].Id);
                        }
                    }
                    else
                    {
                        this.handleErrorScreen();
                    }
                }).catch(error=>{
                    this.handleErrorScreen();
                });
            }
        }
    }

    //RWPS-2889 - Start
    getPrimaryCart() {
        // Call the 'getPrimaryCartBasedOnOwner' apex method imperatively
        getPrimaryCartBasedOnOwner({
            userId: this.userId
        }).then((result) => {
            if(result && result.length > 0){
                this.isPunchoutCart = result[0]?.ECOM_Is_Punchout_Cart__c;
                this.cartId = result[0]?.Id;
                if(this.cartId){
                    this.checkValidProductStatus();
                }
            } else {
                // No cart found, create a new one
                this.createNewCart().then(() => {

                    this.checkValidProductStatus();
                }).catch(error => {
                    console.error(error);
                    this.handleErrorScreen();
                });
            }
        }).catch((error) => {
            console.log(error);
            this.handleErrorScreen();
        });
    }

    createNewCart() {
        return new Promise((resolve, reject) => {
            getOrCreateCartSummary({
                communityId: communityId,
                effectiveAccountId: this.resolvedEffectiveAccountId,
                activeCartOrId: null,
            }).then((result) => {
                if(result){
                    this.cartId = result?.cartId;
                    this.showSpinner=false;
                    resolve();
                }
            }).catch((error) => {
                this.showSpinner=false;
                console.log(error);
                reject(error);
            });
        });
    }
    //RWPS-2889 - End

    checkValidProductStatus() {
        // Call the 'getProductSalesByProdIdAndMaterialCodes' apex method imperatively
        getProductSalesByProdIdAndMaterialCodes({
            productIds: this.productIds,
            isPunchoutCart: this.isPunchoutCart
        }).then((result) => {
            if(result){
                this.productSalesMap = result.productSaleStatus;

                for (let i = 0; i < this.cartItems.length;) {

                    let isSellable = result?.productSaleStatus.hasOwnProperty(this.cartItems[i].Product2Id) ? result?.productSaleStatus[this.cartItems[i].Product2Id] : false;

                    if(!isSellable){
                        this.cartItems = this.cartItems.filter(product => product.Product2Id != this.cartItems[i].Product2Id);
                        i=0;
                    }
                    else{
                        i++;
                    }
                }

                setTimeout(() => {
                    if(this.cartItems?.length > 0 ){
                        this.addProductsTocart();
                    }else{
                        this.validateDiscontinuedNonSellableProducts(); //RWPS-4774
                        this.handleNextSteps();
                    }
                }, 1000);
            }
            }).catch((error) => {
                console.log(error);
            });
    }

    handleErrorScreen()
    {
        this.showErrorMessage=true;
        this.errorMessage.push(ECOM_105107);
        this.showSpinner=false;
        this.handleShowMessageScreen();
    }

    /**
     * RWPS-4774
     * This function is used to check whether are there any dicontinued or non-sellable products
     */
    validateDiscontinuedNonSellableProducts() {
        let productData = JSON.parse(JSON.stringify(this.discontinuedAndNonSellableProductDetails)); //RWPS-3772
        //RWPS-3772 - Start
        if (this.availabilityCheckProductIds && productData) {
            this.availabilityCheckProductIds.forEach(productId => {
                if (productData && productData.discontinuedProducts) {
                    productData.discontinuedProducts.forEach(discountinuedProductId => {
                        if (productId == discountinuedProductId) {
                            //RWPS-3772 : Logic to identify discontinued products along with direct replacements
                            if (productData.directReplacementProductMap && productData.directReplacementProductMap.hasOwnProperty(discountinuedProductId)) {
                                this.erroneousPartsToDisplay.push({
                                    partNumber: this.productIdTopartNumberMap.get(discountinuedProductId),
                                    reason: ECOM_REPLACEMENT_MSG + ' ' + productData.directReplacementProductMap[discountinuedProductId] + '.' //RWPS-5079 - Added space
                                });
                            //RWPS-3772 : Logic to identify discontinued products along with Indirect replacements
                            } else if (productData.indirectReplacementProductMap && productData.indirectReplacementProductMap.hasOwnProperty(discountinuedProductId)) {
                                //RWPS-5079 - Start
                                let indirectReplacementMessage = ' ';
                                for (let i = 0; i < productData.indirectReplacementProductMap[discountinuedProductId].split(',').length; i++) {
                                    indirectReplacementMessage += productData.indirectReplacementProductMap[discountinuedProductId].split(',')[i].trim();
                                    if (i+1 < productData.indirectReplacementProductMap[discountinuedProductId].split(',').length) {
                                        indirectReplacementMessage += ', '
                                    } else {
                                        indirectReplacementMessage += '.'
                                    }
                                }
                                this.erroneousPartsToDisplay.push({
                                    partNumber: this.productIdTopartNumberMap.get(discountinuedProductId),
                                    reason: ECOM_INDIRECT_REPLACEMENT_MSG + indirectReplacementMessage
                                });
                                //RWPS-5079 - End
                            //RWPS-3772 : Logic to identify discontinued products without any replacements
                            } else {
                                this.erroneousPartsToDisplay.push({
                                    partNumber: this.productIdTopartNumberMap.get(discountinuedProductId),
                                    reason: ECOM_DISCONTINUE_MSG
                                });
                            }
                        }
                    });
                }
                //RWPS-3772 : Logic to identify non-sellable products
                if (productData && productData.nonSellableProducts) {
                    productData.nonSellableProducts.forEach(nonSellableProductId => {
                        if (productId == nonSellableProductId) {
                            this.erroneousPartsToDisplay.push({
                                partNumber: this.productIdTopartNumberMap.get(nonSellableProductId),
                                reason: ECOM_105103
                            });
                        }
                    });
                }
            })
        }
        //RWPS-3772 - End
    }

    addProductsTocart(){
        addItemsToCart({
            communityId : communityId,
            effectiveAccountId : this._effectiveAccountId,
            cartItems : this.cartItems
        }).then(result=>{
            // if(result?.success)
            // {
                let productData = JSON.parse(JSON.stringify(this.discontinuedAndNonSellableProductDetails)); //RWPS-3772
                for(let i in this.cartItems)
                {

                    if(!((result.itemsAddedSuccessfully).includes(this.cartItems[i]?.Product2Id)))
                    {
                        this.productNotAvailableToBuy=true;
                        this.erroneousParts.push({
                            'PartNumber' : this.productIdTopartNumberMap.get(this.cartItems[i]?.Product2Id)
                        });
                        this.productArray.push({
                            'PartNumber':this.productIdTopartNumberMap.get(this.cartItems[i]?.Product2Id)
                        })

                    }
                    else
                    {
                        this.successfulParts.push({
                            PartNumber : this.productIdTopartNumberMap.get(this.cartItems[i]?.Product2Id)
                        });

                        // RWPS-3125 start
                        if(this.cartItems[i]?.Product2Id) {
                            trackAddProductToCart({
                                id: this.cartItems[i].Product2Id,
                                sku: this.productIdTopartNumberMap.get(this.cartItems[i].Product2Id),
                                price: '',
                            });
                        }
                        // RWPS-3125 end
                    }
                }
                this.validateDiscontinuedNonSellableProducts(); //RWPS-4774
                let payLoad = {message:1,
                    type: 'CartRefresh'
                };
                publish(this.messageContext, ECOM_MESSAGE, payLoad);
                this.handleNextSteps();
            // DataLayer regarding changes starts
            //Preparing data for add_to_cart event which will be push to DataLayer
            try {
                this.prepareDataLayerData(this.addToCartRows);
            } catch (error) {
                console.error('Error occured during preparing DataLayer data for add_to_cart event',error);
            }
            // DataLayer regarding changes ends


        }).catch(error=>{
                if(error?.body && error?.body?.exceptionType=='ConnectApi.ConnectApiException'){
                    this.handleErrorScreen();
                }
                else{
                    this.productNotAvailableToBuy=true;
                    for(let i in this.cartItems){
                        this.erroneousParts.push({
                            'PartNumber' : this.productIdTopartNumberMap.get(this.cartItems[i]?.Product2Id)
                        });

                        this.erroneousPartsToDisplay.push({
                            partNumber : this.productIdTopartNumberMap.get(this.cartItems[i]?.Product2Id),
                            reason : ECOM_105101
                        });

                        this.productArray.push({
                            'PartNumber':this.productIdTopartNumberMap.get(this.cartItems[i]?.Product2Id)
                        })
                    }
                    if(this.productNotAvailableToBuy){
                        this.prepareDataLayerDataErrorEvent('error',this.productArray,ECOM_105101);
                    }
                    this.handleNextSteps();
                }
        });
    }

    /**
    * RWPS-3772
    * This function fetches the unavailable product details
    * @param {result} : product data
    */
    async getUnavailableProducts(result) {
        let productIds = [];
        if (result && result.products) {
            for (let i = 0; i < result.products.length; i++) {
                if (result.products[i] && result.products[i].Id) {
                    productIds.push(result.products[i].Id);
                }
            }
            this.availabilityCheckProductIds = productIds;
            await fetchProductUnavailability({productIdList : productIds})
            .then((productData) => {
                this.discontinuedAndNonSellableProductDetails = JSON.parse(JSON.stringify(productData));
            }).catch((error) => {
                console.error(error);
            });
        }
    }

    getErroneousParts(result)
    {
        let products = result.products;
        this.erroneousParts=[];
        let retrievedProducts=new Set();
        this.partNumberToProductIdMap = new Map();
        this.productIdTopartNumberMap=new Map();
        this.erroneousPartsToDisplay=[];
        for(let i in products)
        {
            retrievedProducts.add(products[i].Part_Number__c.toUpperCase());
            this.partNumberToProductIdMap.set(products[i].Part_Number__c.toUpperCase(),products[i].Id);
            this.productIdTopartNumberMap.set(products[i].Id,products[i].Part_Number__c);
        }
        for(let i in this.addToCartRows)
        {
            if(!retrievedProducts.has(this.addToCartRows[i].PartNumber.toUpperCase()))
            {
                this.partNumberNotFound=true;
                let errorMess=ECOM_105103
                this.erroneousParts.push({
                    'PartNumber' :this.addToCartRows[i].PartNumber
                });
                this.erroneousPartsToDisplay.push({
                    partNumber : this.addToCartRows[i].PartNumber, //RWPS-3772
                    reason : ECOM_105101
                });
                this.productsArray.push({
                    'PartNumber':this.addToCartRows[i].PartNumber,
                    'Quantity' : this.addToCartRows[i].Quantity
                })
            }else{
                this.cartItems.push({
                    Product2Id: this.partNumberToProductIdMap.get(this.addToCartRows[i].PartNumber.toUpperCase()),
                    Quantity : this.addToCartRows[i].Quantity,
                    PartNumber : this.addToCartRows[i].PartNumber
                });
            }
        }
        if(this.partNumberNotFound){
            this.prepareDataLayerDataErrorEvent('part number not exist',this.productsArray,ECOM_105103);
        }

    }

    doValidation() {
        let finalParts = new Set();
        this.addToCartRows = [];
        //RWPS-275 - garora@rafter.one - 20 March 2024 - Initial check to clear errors on empty inputs
        /**RWPS-275 changes begins */
        const allInputs = this.template.querySelectorAll('lightning-input');
        if(allInputs && allInputs.length>0){
            for (let i = 0; i < allInputs.length; i++) {
                if(allInputs[i].value==undefined || allInputs[i].value=="" || allInputs[i].value==null){
                    allInputs[i].setCustomValidity('');
                }
            }
        }
        /**RWPS-275 changes ends */
        this.quickOrderRows.forEach(product => {
            if (!product.PartNumber) {
                // highlight row
                return;
            } else if (finalParts.has(product.PartNumber)) {
                const partFields = this.template.querySelectorAll("[data-part-code=\"" + product.PartNumber + "\"]");
                if (partFields && partFields.length > 0) {
                    for (let i = 1; i < partFields.length; i++) {
                        this.type='error';
                        this.message='Duplicate part number.';
                        this.showMessage=true;
                        this.timeSpan=0;
                        window.scrollTo(0, 0);
                        partFields[i].setCustomValidity('Duplicate part number.');
                    }
                }
            } else if (!product.Quantity) {
                const qtyField = this.template.querySelector("[data-part-qty=\"" + product.PartNumber + "\"]");
                if (qtyField) {
                    qtyField.setCustomValidity('Invalid Quantity.');
                }
                //RWPS-275 - garora@rafter.one - 20 March 2024 - check for previous error on related part field to see if it still withholds
                /**RWPS-275 changes begins */
                if(!finalParts.has(product.PartNumber)){
                    const inputField = this.template.querySelector("[data-part-code=\"" + product.PartNumber + "\"]");
                    if(inputField){
                        //inputField.setCustomValidity('');
                    }
                }
                /**RWPS-275 changes ends */
            }else{
                const partFields = this.template.querySelectorAll("[data-part-code=\"" + product.PartNumber + "\"]");
                const qtyFields = this.template.querySelectorAll("[data-part-qty=\"" + product.PartNumber + "\"]");
                if (partFields && partFields.length > 0) {
                    for (let i = 0; i < partFields.length; i++) {
                        //partFields[i].setCustomValidity('');
                    }
                }
                if (qtyFields && qtyFields.length > 0) {
                    for (let i = 0; i < qtyFields.length; i++) {
                        qtyFields[i].setCustomValidity('');
                    }
                }
            }

            finalParts.add(product.PartNumber);
            this.addToCartRows.push({PartNumber:product.PartNumber,Quantity:product.Quantity});
        });

        const allValid = [
            ...this.template.querySelectorAll('lightning-input'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        if (allValid) {

        } else {

        }
        return allValid;
    }

    removeFromList(event)
    {
        var ind=event.currentTarget.dataset.index;
        if (isNaN(ind) || ind < 0 || ind >= this.quickOrderRows.length) return;
        this.quickOrderRows.splice(ind,1);

        let tempList=JSON.parse(JSON.stringify(this.quickOrderRows));
        for (let orderIndex=0;orderIndex<tempList.length;orderIndex++)
        {
            tempList[orderIndex].index=orderIndex;
        }
        this.quickOrderRows=tempList;


    }

    // RWPS-3826 start
    removeFromListEnter(event) {
        if(event.key === 'Enter' || event.keyCode === 13 || event.key === 'Space' || event.keyCode === 32) { // RWPS-4086
            this.removeFromList(event);
        }
    }
    // RWPS-3826 end

    showHoverIcon(event){
        let ind=event.target.dataset.index;
        if(this.quickOrderRows[ind]['imgSrc'].includes('black')){
            this.quickOrderRows[ind]['imgSrc']=this.images.purpledelete;
        }
    }

    showOriginalIcon(event){
        let ind=event.target.dataset.index;
        if(this.quickOrderRows[ind]['imgSrc'].includes('purple')){
            this.quickOrderRows[ind]['imgSrc']=this.images.blackdelete;
        }
    }

    valueChanged(event)
    {
        const inputElement = event.target;
        let ind=event.target.dataset.index;
        let label=event.target.dataset.label;
        let partNumber = event.target.value.trim();
        if(event.detail.partnumber == ''){
            partNumber = '';
        }
        this.quickOrderRows[ind][label] = partNumber;
        if(inputElement.dataset.partnumber && inputElement.value){
            this.quickOrderRows[ind]['imgSrc'] = this.images.blackdelete;
        }
        this.selectedPartNumber.push(partNumber);
    }

    closeModal(event)
    {
        this.showModal=false;
    }

    handleNextSteps()
    {
        if(this.erroneousPartsToDisplay.length>0)
        {
            this.showErrorParts=true;
        }
        if(this.successfulParts.length>0)
        {
            this.showSuccessParts=true;
        }
        this.handleCartButton();
        this.handleShowMessageScreen();
        this.showSpinner=false;



    }

    handleCartButton()
    {
        const currentUrl = window.location.href;
        if(currentUrl.includes('/cart'))
        {
            this.showGoToCartButton=false;
        }
        else
        {
            this.showGoToCartButton=true;
        }
    }

    handleQuickorderClose(){
        this.dispatchEvent(
            new CustomEvent('quickorderclose', {
                detail: {
                    success: true,
                }
            })
        );
    }
    fileData = {};
    successMessage='';
openUpload(event) {
     // Trigger the lightning-input element's click event to open the file dialog
    this.template.querySelector('lightning-input[type="file"]').click();
    }

showSuccessMessage(){

    this.successMessage = 'File uploaded successfully';
}


quickOrderData = [];

handlepartNumberChange(event) {
    this.newpartNumber = event.target.value;
}

handleQuantityChange(event) {
    this.newQuantity = event.target.value;
}

addToQuickOrder() {
    if (this.newpartNumber && this.newQuantity) {
        this.quickOrderData.push({ PartNumber: this.newpartNumber, Quantity: parseInt(this.newQuantity) });
        this.data = [...this.quickOrderData];
        this.newpartNumber = '';
        this.newQuantity = '';
    }
}

downloadCSVFile() {
    let csvString = '';
    let rowData = this.columns.map(col => col.fieldName);

    csvString += 'PartNumber,Quantity\n';
    csvString+= 'XX-008-PCF-XX' + ',' + '1';
    csvString += '\n';
    // if (this.quickOrderRows.length > 0) {
    //     for (let i = 0; i < this.quickOrderRows.length; i++) {
    //         csvString+= this.quickOrderRows[i]['PartNumber']+','+ this.quickOrderRows[i]['Quantity'];
    //         csvString += '\n';
    //     }
    // }

    let downloadElement = document.createElement('a');
    downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csvString);
    downloadElement.target = '_self';
    downloadElement.download = 'bulkimport.csv';
    document.body.appendChild(downloadElement);
    downloadElement.click();
}

downloadExcelFile(){
    const tableData = [
        ['XX-008-PCF-XX', 1],
    ];

    const filename = 'bulkimport.xlsx';
    const workbook = XLSX.utils.book_new();
    const headers = [];
    const worksheetData = [];

    for (const record of tableData) {
        worksheetData.push({
            "PartNumber": record[0],
            "Quantity":record[1]

        });
    }
    const worksheet = XLSX.utils.json_to_sheet(worksheetData, { header: headers });
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Sheet1');

    const excelBuffer = XLSX.write(workbook, { bookType: 'xlsx', type: 'array' });
    const blob = new Blob([excelBuffer], { type: 'application/octet-stream' });

    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = filename;
    a.click();
    URL.revokeObjectURL(a.href);
}

ExcelToJSON(file){
    var reader = new FileReader();
    reader.onload = event => {
        var data=event.target.result;
        var workbook=XLS.read(data, {
            type: 'binary'
        });
        var XL_row_object = XLS.utils.sheet_to_row_object_array(workbook.Sheets["Sheet1"]);
        var data = JSON.stringify(XL_row_object);
        const rawData = JSON.parse(data);
        this.formatData(rawData);
    };
    reader.onerror = function(ex) {
        this.error=ex;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error while reding the file',
                message: ex.message,
                variant: 'error',
            }),
        );
    };
    reader.readAsBinaryString(file);
}

formatData(data){
    var formattedData;
    var keysArray = [];
    data.forEach((element, index, array) => {
        keysArray = Object.keys(element);
        //formattedData += element.PartNumber + ',' + element.Qty + '\n';
    });
    formattedData = keysArray[0] + ',' + keysArray[1] + '\n';
    data.forEach((element, index, array) => {
        keysArray = Object.keys(element);
        let partNumVal = String(element.PartNumber).trim(); // Bug Fix for when the excel contains number in part number by sathiya on 10/17/2024
        formattedData += partNumVal + ',' + element.Quantity + '\n';
    });
    this.parse(formattedData);
}

handleFileUpload(event) {
    this.errorMessage = [];
    const files = event.detail.files;

    if (files.length > 0) {
      if(files.length>1)
      {

        return;
      }
      const file = files[0];

      if(file?.type==='text/csv'){
      this.read(file);
    }
    else if(file?.type === 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' || file?.type === 'application/vnd.ms-excel'){
        this.ExcelToJSON(file);
    }
    else{
        this.handleNextSteps();
        //this.errorMessage.push('Only .csv, .xls, .xlsx files are supported.');
        this.errorMessage.push('Error uploading your file! Please try again.');
        this.showUploadModal=false;
        sendPostMessage('auto');
        this.showErrorMessage=true;
        return;
      }
    }
  }

  async read(file) {
    try {
      const result = await this.load(file);

      // execute the logic for parsing the uploaded csv file
      this.parse(result);
    } catch (e) {
      this.error = e;
    }
  }

  async load(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();

      reader.onload = () => {
        resolve(reader.result);
      };
      reader.onerror = () => {
        reject(reader.error);
      };
      reader.readAsText(file);
    });
  }


parse(csv){
    this.showSpinner=true;
    // parse the csv file and treat each line as one item of an array
    const lines = csv.split(/\r\n|\n/);

    // parse the first line containing the csv column headers
    const headers = lines[0].split(',');

    // iterate through csv headers and transform them to column format supported by the datatable
    this.columns = headers.map((header) => {
      return { label: header, fieldName: header };
    });

    const data = [];

    if(this.checkFileForErrors(lines,headers))
    {
        this.handleNextSteps();
        this.showUploadModal=false;
        sendPostMessage('auto');
        this.showErrorMessage=true;
        return;
    }

    // iterate through csv file rows and transform them to format supported by the datatable
    lines.forEach((line, i) => {
      if (i === 0)
            return;
        const obj = {};
      const currentline = line.split(',');
  let hasData = false;
      for (let j = 0; j < headers.length; j++) {
if(currentline[j] && currentline[j].trim()!==''){
                hasData = true;
        obj[headers[j]] = currentline[j];
      }
  }
        if(hasData){
      data.push(obj);
}
    });

    // assign the converted csv data for the lightning datatable
    this.data = data;

if(this.data?.length>0){
    this.processUploadedData();
}else{
        this.handleNextSteps();
        //this.errorMessage.push('You uploaded an empty csv file.');
        this.errorMessage.push('Quantity or Part numbers are not valid or not found.');
        this.showUploadModal=false;
        sendPostMessage('auto');
        this.showErrorMessage=true;
        return;
    }
  }

  checkFileForErrors(lines,headers){
    this.errorMessage=[];
    var moreFields='';
    var duplicateFields='';
    var missingFields='';

    var reqdHeader={
        'PartNumber' : false,
        'Quantity' : false
    };

    for (let j = 0; j < headers.length; j++) {
        if(reqdHeader[headers[j]]==null || reqdHeader[headers[j]]==undefined)
        {
            moreFields=this.returnModifiedString(moreFields,headers[j]);
        }
        else if(reqdHeader[headers[j]])
        {
            duplicateFields=this.returnModifiedString(duplicateFields,headers[j]);
        }
        else{
            reqdHeader[headers[j]]=true;
        }
    }
    if(!reqdHeader["PartNumber"])
    {
        missingFields=this.returnModifiedString(missingFields,"PartNumber");
    }
    if(!reqdHeader["Quantity"])
    {
        missingFields=this.returnModifiedString(missingFields,"Quantity");
    }
    if(!(moreFields=='') || !(duplicateFields=='') || !(missingFields==''))
    {
        if(moreFields!='')
        {
            //this.errorMessage.push('Please remove the unexpected columns : '+moreFields);
            this.errorMessage.push('The uploaded file is not following the required format. Kindly download the excel template provided in the help text.');
        }
        else if(duplicateFields!='')
        {
            //this.errorMessage.push('Please remove the duplicate columns : '+duplicateFields);
            this.errorMessage.push('The uploaded file is not following the required format. Kindly download the excel template provided in the help text.');
        }
        else if(missingFields!='')
        {
            //this.errorMessage.push('Please provide the following columns : '+missingFields);
            this.errorMessage.push('The uploaded file is not following the required format. Kindly download the excel template provided in the help text.');
        }
        return true;

    }

    var data=[];
    lines.forEach((line, i) => {
    if (i === 0)
    {
        return;
    }

    const obj = {};
    const currentline = line.split(',');

    for (let j = 0; j < headers.length; j++) {
        obj[headers[j]] = currentline[j];
    }
    data.push(obj);
    });

    for(var i in data)
    {
        if((data[i].PartNumber==undefined || data[i].PartNumber==null || data[i].PartNumber=='' )
          && (data[i].Quantity==undefined || data[i].Quantity==null || data[i].Quantity=='' ))
        {
            continue;
        }
        if(data[i].PartNumber==undefined || data[i].PartNumber==null || data[i].PartNumber=='' )
        {
            //this.errorMessage.push('Few entries are missing part numbers.');
            this.errorMessage.push('Part numbers are not valid or not found.');
            break;
        }
        if(data[i].Quantity==undefined || data[i].Quantity==null || data[i].Quantity=='' )
        {
            this.errorMessage.push('Few entries are missing quantities.');
            break;
        }
        var parsedQty=parseInt(data[i].Quantity);
        if(isNaN(parsedQty) || (data[i].Quantity.length!=(parsedQty.toString()).length))
        {
            //this.errorMessage.push('Please make sure that all the provided quantites are numeric.');
            this.errorMessage.push('Quantity is not valid or not found. Please enter an integer.');
            break;
        }
        if(parsedQty<=0)
        {
            this.errorMessage.push('Please make sure that all the provided quantites are more than 0.');
            break;
        }
    }

    if(this.errorMessage.length>0)
    {
        return true;
    }


    return false;
  }

  returnModifiedString(field,val)
  {
    if(!(field==''))
    {
        field+=', ';
    }
    field+=val;
    return field;
  }

  async processUploadedData(){//RWPS- 2132
    var data=this.data;
    var quickOrderRows=[];
    var index=0;
    var partNumbers=[];
    var excludedPartsArray=[];//RWPS- 2132
    var partsWithError='';
    var excludePartsWithError='';//RWPS- 2132
    var countExceeded=false;
    //RWPS- 2132 START
    try {
        if(this.isPunchoutUser)
        {
            var obj= JSON.parse(JSON.stringify(this.data));
            const partnumbers = obj.map(item=>item.PartNumber);
            const result = await processProductExclusions({communityId: communityId, partNumberList:partnumbers});
            for (let i = 0; i < result.length; i++) {
                const product = result[i];
                excludedPartsArray.push(product);
            }
        }
    } catch (error) {
        console.error('Error:', error);
    }
    let excludedParts = new Set(excludedPartsArray);
    //RWPS- 2132 END
    for(var i in data)
    {
        if(data[i]["PartNumber"] ==null || data[i]["PartNumber"] ==undefined  || data[i]["Quantity"] ==null || data[i]["Quantity"] ==undefined)
        {
            continue;
        }
        //RWPS- 2132 START
        var partNumber = data[i]["PartNumber"];
        var quantity = data[i]["Quantity"];
        if (excludedParts.has(partNumber)) {
            if (excludePartsWithError !== '') {
                excludePartsWithError += ', ';
            }
            excludePartsWithError += partNumber;
            console.log(excludePartsWithError);
            continue;
        }
        //RWPS- 2132 END
        var temp={};
        temp["PartNumber"]=data[i]["PartNumber"];
        temp["index"]=index;
        temp["showDelete"]=index===0? false:true;
        temp["imgSrc"]=this.images.blackdelete; //RWPS-3163
        if(!(/^\d+$/.test(data[i]["Quantity"])))
        {

            data[i]["Quantity"]='';
        }
        temp["Quantity"]=data[i]["Quantity"];
        quickOrderRows.push(temp);
        index=index+1;
        if(partNumbers.includes(temp["PartNumber"]))
        {
            if(partsWithError!='')
                partsWithError+=', ';
            partsWithError+=temp["PartNumber"];
        }
        partNumbers.push(temp["PartNumber"]);
        if(i==49 && data.length>50)
        {
            countExceeded=true;
            break;
        }
    }
    if(partsWithError!='')
    {
        this.errorMessage.push('Duplicate items are not allowed.');
        this.handleNextSteps();
        this.showUploadModal=false;
        sendPostMessage('auto');
        this.showErrorMessage=true;
        return;

    }
    //RWPS- 2132 START
    if(excludePartsWithError !== '') {
        this.errorMessage.push('The following part numbers are not allowed: ' + excludePartsWithError);
        this.handleNextSteps();
        this.showUploadModal=false;
        sendPostMessage('auto');
        this.showErrorMessage=true;
        return;
    }
    //RWPS- 2132 END
    this.quickOrderRows=quickOrderRows;

    if(countExceeded)
    {
        this.type='warning';
        //this.message='You can only upload 50 records.So all the others records after the first 50 records have been discarded.';
        this.message='Maximum 50 items are allowed.';
        this.showMessage=true;
        this.timeSpan=0;
    }else{
        this.type='';
        this.message='';
        this.showMessage=false;
        this.timeSpan=0;

    }


   //this.doValidation();
   this.showUploadModal=false;
    sendPostMessage('auto');
   this.showSpinner=false;

  }

  showUpload(event)
  {
    this.showUploadModal=true;
    sendPostMessage('hidden');

  }

  closeUpload(event)
  {
    this.showUploadModal=false;
    sendPostMessage('auto');

  }

  handleMessageScreenBack(event)
  {
    this.showModal=true;
    this.showMessagePage=false;
  }

  handleShowMessageScreen()
  {
    this.showModal=false;
    this.showMessagePage=true;
  }

  handleMessageScreenClose(event)
  {
    if(!this.showGoToCartButton)
    {
        this.dispatchEvent(
            new CustomEvent('quickorderclose', {
                detail: {
                    success: true,
                }
            })
        );
    }
    this.showMessagePage=false;
    this.defaultingValues();
    this.setEmptyRows();
  }

  handleMessageScreenRedirectToCart(event)
  {
    window.location.replace("/cart");
  }

  //DataLayer regarding changes for error event starts
  prepareDataLayerDataErrorEvent(typeOfError,productsArray,error){
    try{
            let data =  {
                'event': 'add_to_cart_error',
                'addToCartLocation': 'Quick Order - ' + this.labels.ECOM_Add_to_Cart,//RWPS-3835
                'errormessage':error,
                products:[],
                _clear:true
            };
            if(typeOfError=='part number not exist'){
                    for(let i = 0; i < productsArray.length; i++ ){
                        data.products.push({
                                'PartNumber': productsArray[i].PartNumber,
                                'Quantity': productsArray[i].Quantity
                        });
                    }
            }else{
                for(let i = 0; i < productsArray.length; i++ ){
                    data.products.push({
                            'PartNumber': productsArray[i].PartNumber
                    });
                }

            }
            this.handlePublishErrorMsg(data);
        }catch(error){
           //console.log(error);
         }

  }

  handlePublishErrorMsg(data) {

    let payLoad = {
        data: data,
        type: 'DataLayer',
        page:'cart'
    };
    publish(this.messageContext, ECOM_DATALAYERCHANNEL, payLoad);
}



  //DataLayer regarding changes starts
  prepareDataLayerData(addToCartRows){
    let data =  []
    for(let i = 0; i < addToCartRows.length; i++ ){
        data.push({
                'PartNumber': addToCartRows[i].PartNumber,
                'Quantity': addToCartRows[i].Quantity
        });
    }
    this.handlePublishMsg(data);

  }

  handlePublishMsg(data) {

    let payLoad = {
        data: data,
        type: 'DataLayer',
        page:'Quick Order'
    };
    publish(this.messageContext, ECOM_DATALAYERCHANNEL, payLoad);
}
//DataLayer regarding changes ends

}