import { LightningElement,track,api,wire } from 'lwc';
import { isCmsResource, resolve } from 'experience/resourceResolver';
// Import Ecom_util for validation methods
import { validateAddressByFields, validateFields } from 'c/ecom_util';
import communityId from "@salesforce/community/Id";
import contextApi from 'commerce/contextApi';
import ssrc_ECOM_Theme from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import createAndAddToList from '@salesforce/apex/ECOM_CheckoutController.createAndAddToList';
import removeWishlistItem from '@salesforce/apex/ECOM_OrderHistoryController.removeWishlistItem';
import getOrderConfirmationDetails from '@salesforce/apex/ECOM_CheckoutController.getOrderConfirmationDetails';
import getProdImages from '@salesforce/apex/ECOM_OrderHistoryController.getProdImages';
import getWishlistDetails from '@salesforce/apex/ECOM_OrderHistoryController.getWishlistDetails';
import {publish, MessageContext} from 'lightning/messageService';
import ECOM_DATALAYERCHANNEL from '@salesforce/messageChannel/ecom_DataLayer__c';
import FORM_FACTOR from '@salesforce/client/formFactor';
import getDataLayerDataByOrder from '@salesforce/apex/ECOM_DataLayerController.getDataLayerDataByOrder';
import ECOM_MESSAGE from '@salesforce/messageChannel/ecom_MessagingChannel__c';
const CMS_NAVIGATION = 'CMSNavigation';
const NAVIGATE_TO_PDP = 'PDP';
import ECOM_Savings  from '@salesforce/label/c.ECOM_Savings';
import ECOM_E_Invoice_Requirements from '@salesforce/label/c.ECOM_E_Invoice_Requirements';
import ECOM_InvoiceMailingAddress from '@salesforce/label/c.ECOM_InvoiceMailingAddress';
import getSAPOrderNumber from  '@salesforce/apex/ECOM_CheckoutController.getSAPOrderNumber'; // RWPS-2547
import ECOM_Tariff_Surcharge  from '@salesforce/label/c.ECOM_Tariff_Surcharge'; //RWPS-3026
import ECOM_Free_Item from '@salesforce/label/c.ECOM_Free_Item';//RWPS-3811
import recipientTitle from '@salesforce/label/c.ecom_Attention_Recipient_Title';//RWPS-4824
import deliveryInstructionNew from '@salesforce/label/c.ECOM_DeliveryInstructionNew';//RWPS-4825


const CARDTYPE_IMAGE_MAP = {
    Visa : 'visaimg',
    AMEX : 'ameximg',
    MC : 'mastercardimg'
}

export default class Ecom_checkoutOrderConfirmation extends LightningElement {
    labels = {
        ECOM_Savings,
        ECOM_E_Invoice_Requirements,
        ECOM_InvoiceMailingAddress,
        ECOM_Tariff_Surcharge,//RWPS-3026
        ECOM_Free_Item, //RWPS-3811
        recipientTitle,//RWPS-4824
        deliveryInstructionNew//RWPS-4825
    };

    @api recordId;
    @api fieldsToShow;
    @api effectiveAccountId;
    @api productImages = {};
    isPurchase=false;
    orderDetailForDatalayer;
    userEmail;
    contactInfo={};
    shipToModel={};
    shippingAddress={};
    billingAddress={};
    orderItemCount;
    @track orderItems = []; //RWPS-4200
    @track showSpinner = false; //RWPS-4200
    ProductsOverview = [];
    orderDetails={};
    orderSalesStatus;
    promoCode;
    wishListdetails;
    isPromoApplied = false;
    contactLvlEmailAddressRows = [];
    accountLvlEmailAddressRows = [];
    formattedEmails = [];
    //@track emailAddressRows = [];
    fieldlabelmap;
    productObject = 'Product2';
    index = 0;
    message;
    type;
    show;
    defaultWishListId;
    //RWPS-622
    isLargePackOrder = false;
    // ECOM -1933 variable additions
    billToFieldValidationJSON;
    billToFieldValidationObj;
    validationFields = [];
    isValidatedFields;
    // Changes End
    // variables declaired for ECOM-1947 by sathiya
    @track isEInvoiceAvailable = false;
    invoiceValidationFields = [];
    invoiceFieldValidationJSON;
    invoiceFieldValidationObj;
    @track isInvoiceEditMode = false;
    @track isInvoiceReadMode = false;
    @track isInvoiceOrderMode = true;
    showTotalTariffSurcharge = false;//RWPS-3026
    totalShippingCost;
    // Changes End
    // Variables declaired for ECOM-1939 by sathiya
    invoiceMailingAddress={};
    isInvoiceMailingAddress = false;
    // Changes End
    device = {
        isMobile : FORM_FACTOR==='Small',
        isDesktop : FORM_FACTOR==='Large',
        isTablet :FORM_FACTOR==='Medium'
    }
    @wire(MessageContext)
    messageContext;
    paymentMethod;
    cardPayment;
    currencyDisplayAs ='code';
    additionalEmailCount = false;

    acceptanceRequired = false;
    SAPOrderNumber=''; //RWPS-2547
    orderNumDetails; //RWPS-2547
    freeItemMap; //RWPS-3811
    get fields(){
       if(this.orderItems && this.index < this.orderItemCount ){
            let displayFields = [];
            let productDetail = this.orderItems[this.index].productDetail;
             for (const [key, value] of Object.entries(productDetail?.fields)) {
                 //if(this.fieldlabelmap[key] != 'Dangerous_Goods_Indicator_Profile__c'){
                 if(this.fieldlabelmap[key] && this.fieldlabelmap[key] != 'Name'){ //RWPS-2516
                     displayFields.push({
                         'name' :this.fieldlabelmap[key] ||  key.replaceAll('_',' ').replace('__C',''),
                     'value'  : value
                     });
                 }
             }
            this.index ++;
            return displayFields;
        }
        
    }

    get showCardImg(){
        return this.cardPayment?.CardType ? true : false;
    }
    get cardTypeImg(){
        return this.images[CARDTYPE_IMAGE_MAP[this.cardPayment?.CardType]];
    }
    get gridForShippingInfo(){
        return this.device.isMobile? 'slds-grid slds-wrap ecom-pb-24 ecom-gray-border ecom-pb-32' : 'slds-grid slds-wrap ecom-gray-border ecom-pb-32' 
    }
    get showSavings(){
        //Check for Savings value on Orderedetails page
        if(this.orderDetails.ECOM_Total_Savings__c > 0){
            return true;
        }
        else{
            return false;
        }
    }
    renderedCallback(){
        if(this.orderDetails.Id!=null && this.orderDetails.Id!=undefined && this.isPurchase==false ){
            if(this.orderDetails.PoNumber!=null || this.orderDetails.PoNumber!=undefined  ){
                this.paymentMethod='Purchase Order';
            }
            else{
                this.paymentMethod='Card Payment';
            }
            //Preparing data for purchase event which will be push to DataLayer
            try {
                 this.prepareDataLayerData('purchase',this.orderDetails,this.paymentMethod);
            } catch (error) {
                 //console.error('Error occured during preparing DataLayer data for purchase event ',error);
              }
              this.isPurchase=true;
        }
    }
    connectedCallback() {
        const result = contextApi.getSessionContext();
        this.getWishlistDetails();

        result.then((response) => {
            this.effectiveAccountId = response.effectiveAccountId;
            if(this.effectiveAccountId ) {
                this.handleGetInitData();
            }

        }).catch((error) => {
            const errorMessage = error.body.message;
        });  
        this.startGetSAPOrderTimer();      // RWPS-2547
    }
   
   // Fetch product images from Apex.
    getProductImages() {
        for (let i = 0; i < this.orderItems.length; i++) {
            this.orderItemsIds.push(this.orderItems[i].product2Id);
        }
        //this.orderItemsIds.push(this.prodId);
        // Call the 'getProdImages' apex method imperatively
        getProdImages({
            productIds: this.orderItemsIds,
            siteId : siteId
        }).then((result) => {
            this.productImages = result;
            this.imagesFetched = true;
            }).catch((error) => {
                //console.log(error);
            });
    }


    /** RWPS-2547 start - get SAP order number in every 5 second*/
     startGetSAPOrderTimer() {
        const TIMEOUT_DURATION = 5000;
        setTimeout(() => {
                this.handleGetSAPOrderNumber();
            }, TIMEOUT_DURATION);
    }

    handleGetSAPOrderNumber () {
        getSAPOrderNumber({
            orderId: this.recordId
        }).then((result) => {
            if(result) {
                this.SAPOrderNumber = result;
            } else {
                this.startGetSAPOrderTimer();
            }
        })
        .catch((error) => {
            //console.log(error);
        });
    }
    trainingProductMap;//RWPS-4896
    /** RWPS-2547 End */
    handleGetInitData(){
        let fields = this.fieldsToShow?.split(',');
        fields.push('DisplayUrl');
        fields.push('ECOM_Product_Media_URI__c');
        fields.push('Product_Display_Name__c');//RWPS-2270
        return getOrderConfirmationDetails({ //RWPS-4200
            communityId: communityId,
            effectiveAccountId: this.effectiveAccountId,
            orderId: this.recordId,
            productFields: fields,
            objectName: this.productObject
        }).then((result) => {
                if(result && result.Status == 'Success'){
                    this.formattedEmails = [];

                    this.acceptanceRequired = result?.AcceptanceRequired;
                    this.orderNumDetails = true; //RWPS-2547
                    this.fieldLabelMap = result?.fieldsMap;
                    this.getFieldLabels();
                    this.userEmail = result?.userEmail;
                    this.contactInfo = result?.contact;
                    this.defaultWishListId = result.wishListId;
                    this.accountLvlEmailAddressRows = result?.ListEmailPrefAccountLvl;
                    this.contactLvlEmailAddressRows = result?.ListEmailPrefContactLvl;
                    //this.emailAddressRows = result?.listEmailPreferences;
                    this.formatEmailRows(this.contactLvlEmailAddressRows);
                    this.ProductsOverview = result?.ProductsOverview.products;
                    this.orderDetails = result?.Order;
                    this.orderItems = result?.Order?.OrderItems;
                    this.promoCode = result?.Order?.ECOM_Promo_Code__c;
                    this.orderSalesStatus = result?.salesStatus;
                    this.freeItemMap = result?.freeItemMap; //RWPS-3811
                    this.trainingProductMap = result?.trainingProducts//RWPS-4896
                    if(this.promoCode){
                        this.isPromoApplied = true;
                    }
                    for(let i in this.orderItems){
                        let orderItem = [this.orderItems[i]];
                        let productRecord = orderItem.map(obj => this.ProductsOverview.find(o => o.id === obj.Product2Id) || obj);
                        //RWPS-4896-START
                        // Create a new array with the derived flag to ensure reactivity
                        this.orderItems = this.orderItems.map(item => ({
                            ...item,
                            isTrainingProduct: Boolean(this.trainingProductMap?.[item.Product2Id])
                        }));

                        //RWPS-4896-END
                        this.orderItems[i]['productDetail'] = productRecord[0];
                        //RWPS-1387
                        this.orderItems[i].productDetail.defaultImage.url = resolve((productRecord[0]?.fields?.ECOM_Product_Media_URI__c ||this.images.defaultProdImage)  ?? '', false, { });
                        let displayFields = [];
                        for (const [key, value] of Object.entries(this.orderItems[i].productDetail?.fields)) {
                            if(this.fieldlabelmap[key] && this.fieldlabelmap[key] != 'Name'){ //RWPS-2516
                                displayFields.push({
                                    'name' :this.fieldlabelmap[key] ||  key.replaceAll('_',' ').replace('__C',''),
                                'value'  : value
                                });
                            }
                        }
                        this.orderItems[i]['displayFields'] = displayFields;

                        this.orderItems[i]['specialPriceAvailable'] = false;
                        if((this.orderItems[i].ListPrice > this.orderItems[i].UnitPrice) && this.isPromoApplied){
                            this.orderItems[i]['specialPriceAvailable'] = true;
                        }
                        
                        if(this.orderItems[i]?.ECOM_Selected_Shipping_Date__c){
                                    this.orderItems[i]['isShippingDateSelected'] = true; 
                        }else{
                                    this.orderItems[i]['isShippingDateSelected'] = false; 
                        }
                        if(this.wishListdetails.hasOwnProperty(this.orderItems[i].Product2Id)){
                            this.orderItems[i]['isWishListItem'] = true;
                            this.orderItems[i]['wishListItemId'] = this.wishListdetails[this.orderItems[i].Product2Id].wishListItemId;
                        }
                        else{
                            this.orderItems[i]['isWishListItem'] = false;
                        }
                    
                        if(this.orderSalesStatus.hasOwnProperty(this.orderItems[i].Product2Id) && this.orderSalesStatus[this.orderItems[i].Product2Id]){
                            this.orderItems[i]['hideShipDate'] = true;
                        }
                        else{
                            this.orderItems[i]['hideShipDate'] = false;
                        }
                        //RWPS-622
                        if(!this.isLargePackOrder && (this.orderItems[i]?.Product2?.Item_Class__c=='1' || this.orderItems[i]?.Product2?.Item_Class__c=='2')){
                            this.isLargePackOrder = true;
                        }
                        // RWPS-3026 START
                        if (this.orderItems[i].Tariff_Surcharge__c != null && this.orderItems[i].Tariff_Surcharge__c != 0) {
                            this.orderItems[i].showTariffSurcharge = true;
                        } else {
                            this.orderItems[i].showTariffSurcharge = false;
                        }
                        //RWPS-3811
                        if(this.orderItems[i].ECOM_Parent_Item__c && this.orderItems[i].ECOM_Parent_Item__c !='') {
                           this.orderItems[i]['parentPartNumber'] = this.freeItemMap[this.orderItems[i].ECOM_Parent_Item__c];
                        }
                    }
                    this.orderItems = [...this.orderItems]; //RWPS-4200
                    this.orderTotalTariffSurcharge = result.Order.Total_Tariff_Surcharge__c;
                    this.showTotalTariffSurcharge = this.orderTotalTariffSurcharge && this.orderTotalTariffSurcharge > 0;
                    console.log(this.orderDetails.TotalAdjDeliveryAmtWithTax, 'TotalAdjDeliveryAmtWithTax');
                    this.totalShippingCost = parseFloat(this.orderDetails.TotalAdjDeliveryAmtWithTax) - parseFloat(result.Order.Total_Tariff_Surcharge__c);//RWPS-3026
                    // RWPS-3026 end
                    this.orderItemCount = this.orderItems.length;
                    this.cardPayment = result?.CardPaymentMethod;
                    //this.showVisaImg = this.cardPayment?.CardType == 'Visa' ? true : false;
                    this.shipToModel = result?.shipToModel;
                    this.shippingAddress.street = this.shipToModel?.street;
                    this.shippingAddress.city = this.shipToModel?.city;
                    this.shippingAddress.state = this.shipToModel?.state;
                    this.shippingAddress.zip = this.shipToModel?.postalCode;
                    this.shippingAddress.country = this.shipToModel?.country;

                    this.billingAddress.street = this.shipToModel?.associatedAddresses?.[0]?.street;
                    this.billingAddress.city = this.shipToModel?.associatedAddresses?.[0]?.city;
                    this.billingAddress.state = this.shipToModel?.associatedAddresses?.[0]?.state;
                    this.billingAddress.zip = this.shipToModel?.associatedAddresses?.[0]?.postalCode;
                    this.billingAddress.country = this.shipToModel?.associatedAddresses?.[0]?.country;
                    // ECOM -1939 for adding Invoice mailing address to the section
                    if(this.shipToModel?.associatedInvoiceAddresses != null && this.shipToModel?.associatedInvoiceAddresses.length > 0){
                        console.log('invoiceMailingAddress:: ' , this.shipToModel?.associatedInvoiceAddresses);
                        this.invoiceMailingAddress.street = this.shipToModel?.associatedInvoiceAddresses?.[0]?.street;
                        this.invoiceMailingAddress.city = this.shipToModel?.associatedInvoiceAddresses?.[0]?.city;
                        this.invoiceMailingAddress.state = this.shipToModel?.associatedInvoiceAddresses?.[0]?.state;
                        this.invoiceMailingAddress.zip = this.shipToModel?.associatedInvoiceAddresses?.[0]?.postalCode;
                        this.invoiceMailingAddress.country = this.shipToModel?.associatedInvoiceAddresses?.[0]?.country;
                        this.isInvoiceMailingAddress = this.shipToModel?.associatedInvoiceAddresses?.[0]?.isShowAddress;
                    }
                    // Changes End
                    // ECOM -1933 for new field validations
                    this.billToFieldValidationJSON = result?.billToValidationFields;
                    if(this.billToFieldValidationJSON != null){
                        this.billToFieldValidationObj = JSON.parse(this.billToFieldValidationJSON);
                    }
                    let validatedBillTo = validateAddressByFields(this.shipToModel?.associatedAddresses?.[0], this.billToFieldValidationObj);
                    this.validationFields = validatedBillTo?.validationFields;
                    this.isValidatedFields = validatedBillTo?.isValidatedFields;
                    // Changes End
                    // ECOM -1947 for new field validations by sathiya
                    this.invoiceFieldValidationJSON = result?.invoiceValidationFields;
                    if(this.invoiceFieldValidationJSON != null){
                        this.invoiceFieldValidationObj = JSON.parse(this.invoiceFieldValidationJSON);
                    }
                    let validationCountry = '';
                    if(result?.Order?.Default_Bill_to_ERP_Address__r?.apiCountry__c != null){
                        validationCountry = result?.Order?.Default_Bill_to_ERP_Address__r?.apiCountry__c.toLowerCase();
                    } else if(result?.Order?.Default_Bill_to_ERP_Address__r?.fxAddress_CountryName__c){
                        validationCountry = result?.Order?.Default_Bill_to_ERP_Address__r?.fxAddress_CountryName__c.toLowerCase();
                    }
                    let validationFields = {};
                    console.log('country::', validationCountry);
                    if(validationCountry != null && validationCountry != undefined){
                        validationFields.orderId = this.recordId;
                        if(result?.Order?.ECOM_E_Invoice_Code1__c != null){
                            validationFields.einvoice1 = result?.Order?.ECOM_E_Invoice_Code1__c;
                        }
                        if(result?.Order?.ECOM_E_Invoice_Code2__c != null){
                            validationFields.einvoice2 = result?.Order?.ECOM_E_Invoice_Code2__c;
                        }
                        if(result?.Order?.ECOM_E_Invoice_Code3__c != null){
                            validationFields.einvoice3 = result?.Order?.ECOM_E_Invoice_Code3__c;
                        }
                        if(result?.Order?.ECOM_E_Invoice_Code4__c != null){
                            validationFields.einvoice4 = result?.Order?.ECOM_E_Invoice_Code4__c;
                        }
                        if(result?.Order?.ECOM_E_Invoice_Cost_Center__c != null){
                            validationFields.einvoice5 = result?.Order?.ECOM_E_Invoice_Cost_Center__c;
                        }
                        if(result?.Order?.ECOM_E_Invoice_Tax_Exempt__c != null){
                            validationFields.einvoice6 = result?.Order?.ECOM_E_Invoice_Tax_Exempt__c;
                        }
                        validationFields = validateFields(validationFields, validationCountry, this.invoiceFieldValidationObj);
                        this.invoiceValidationFields = validationFields?.validationFields;
                        this.isEInvoiceAvailable = validationFields.isValidatedFields;
                    }
                    // Changes End
                }  
            })
            .catch((error) => { //RWPS-4200
                console.error(error);
            });
    }

    // Fetch wish list details from Apex.
    getWishlistDetails() {
        // Call the 'getFieldsByObjectName' apex method imperatively
        return getWishlistDetails().then((result) => { //RWPS-4200
                let wishListResult = result?.length > 0 ? result[0] : null; 
                let wishListItems = wishListResult?.wishListModels[0]?.wishListItems || [];
                let productToWishlistObj = {};
                this.defaultWishListId =   wishListResult?.wishListModels[0]?.wishListId || '';
                for( let i=0; i<wishListItems.length ;i++){
                    productToWishlistObj[wishListItems[i].productId] = wishListItems[i];
                }
                this.wishListdetails = productToWishlistObj;
            }).catch((error) => { //RWPS-4200
                console.error(error);
            });
    }

    getFieldLabels(){
        //this.fieldsToShow += ',Dangerous_Goods_Indicator_Profile__c';
        let fieldMap ={};
        let fields = this.fieldsToShow?.split(',');
        for(let i=0;i< fields.length;i++ ){
            if(this.fieldLabelMap[fields[i]]){
                fieldMap[fields[i]]  = this.fieldLabelMap[fields[i]];
            }
        }
        this.fieldlabelmap = fieldMap;
    }

    @track
    images = {
        visaimg: ssrc_ECOM_Theme + '/img/visa.png',
        itemImage: ssrc_ECOM_Theme + '/img/productimage.png',
        edit: ssrc_ECOM_Theme + '/img/edit.png',
        favourite: ssrc_ECOM_Theme + '/img/heart-line.png',
        print: ssrc_ECOM_Theme + '/img/print.png',
        deleteimg: ssrc_ECOM_Theme + '/img/delete-icon.png',
        ameximg: ssrc_ECOM_Theme + '/img/amex.svg',
        mastercardimg: ssrc_ECOM_Theme + '/img/mastercard.svg',
        defaultProdImage : ssrc_ECOM_Theme + '/img/placeholder.png'//RWPS-1387
    }

    get productsWithStrikethrough() {
        return this.products.filter(product => product.strikethroughPrice && product.strikethroughPrice > 0);
    }
    
    get emailCount() {
        return this.accountLvlEmailAddressRows.length;//this.accountLvlEmailAddressRows.length + this.contactLvlEmailAddressRows.length;
    }
    get emailIdList() {
        return this.accountLvlEmailAddressRows.map(emailRow => emailRow.ECOM_Email__c).join(', ');
    }

    get displayNoticationSec(){
        return this.emailCount || this.additionalEmailCount;
    }
    // get emailIdList1() {
    //     return this.accountLvlEmailAddressRows.map(emailRow => emailRow.ECOM_Email__c).join(', ');
    // }
    // get emailIdList2() {
    //     return this.contactLvlEmailAddressRows.map(emailRow => emailRow.ECOM_Email__c).join(', ');
    // }

    handlePrintPage(){
        window.print();
    }

    @api cartSummary = {
        totalProductAmount: '000000000.00',
        totalChargeAmount: '000000000.00',
        totalTaxAmount: '000000000.00',
        savings: '000000000.00',
        grandTotalAmount: '000000000.00',
        currencyIsoCode: "USD" // Example currency code
    };

    handleAddToFavourite(event){
        //RWPS-4200 Start
        let btn = event.currentTarget;
        btn.disabled = true;
        this.showSpinner = true;
        //RWPS-4200 End
        let productId = event.currentTarget.dataset.id;
        let productName = event.currentTarget.dataset.name;
        createAndAddToList({
            communityId: communityId,
            productId: productId,
            wishListId: this.defaultWishListId,
            effectiveAccountId: this.effectiveAccountId,
        }).then((result) => {
                this.index = 0;
                this.showMessage(
                    productName+' added to favorites.',
                    'success',
                    true
                );
                //RWPS-4200 Start
                return this.getWishlistDetails();
                })
                .then(() => {
                    return this.handleGetInitData();
                })
                .then(() => {
                    this.orderItems = [...this.orderItems];
                //RWPS-4200 End
                //Preparing data for add_to_wishlist event which will be push to DataLayer
                try {
                    this.prepareDataLayerData('add_to_wishlist','','',productId);
                } catch (error) {
                    //console.error('Error occured during preparing DataLayer data for add_to_wishlist event ',error);
                  }
            })
            .catch((error) => {
                this.showMessage(
                    productName+' not added to favorites.',
                    'error',
                    true
                );
                const errorMessage = error.body.message;
            })
            .finally(() => { //RWPS-4200
                btn.disabled = false;
                this.showSpinner = false;
            });

    }

    handleRemoveFromFavourite(event){
        //RWPS-4200 Start
        let btn = event.currentTarget;
        btn.disabled = true;
        this.showSpinner = true;
        //RWPS-4200 End
        let productId = event.currentTarget.dataset.id;
        let wishlistItemId = event.currentTarget.dataset.wishlist;
        let productName = event.currentTarget.dataset.name;
        removeWishlistItem({
            communityId: communityId,
            effectiveAccountId: this.effectiveAccountId,
            wishListId:this.defaultWishListId,
            wishlistItemId:wishlistItemId,
        }).then((result) => {
                this.index = 0;
                this.showMessage(
                    productName+' removed from favorites.',
                    'success',
                    true
                );
                //RWPS-4200 Start
                return this.getWishlistDetails();
                })
                .then(() => {
                    return this.handleGetInitData();
                })
                .then(() => {
                    this.orderItems = [...this.orderItems];
                //RWPS-4200 End
                //Preparing data for remove_from_wishlist event which will be push to DataLayer
                try {
                    this.prepareDataLayerData('remove_from_wishlist','','',productId);
                } catch (error) {
                    //console.error('Error occured during preparing DataLayer data for remove_from_wishlist event ',error);
                  }
            })
            .catch((error) => {
                this.showMessage(
                    productName+' not removed from favorites.',
                    'error',
                    true
                );
                const errorMessage = error.body.message;
            })
            .finally(() => { //RWPS-4200
                btn.disabled = false;
                this.showSpinner = false;
            });

    }

    formatEmailRows(emailAddressRows){
        for(let i in emailAddressRows){
            let notificationTypes = '';
            if(emailAddressRows[i].ECOM_Order_Confirmation__c){
                notificationTypes += 'Order Confirmation+';
            }
            if(emailAddressRows[i].ECOM_Shipment_Notification__c){
                notificationTypes += 'Shipment Notification';
            }
            
            notificationTypes = notificationTypes.replace(/\+$/, '');
            notificationTypes = notificationTypes.replaceAll('+', ' & ');
            let formattedEmailRecord = {'id':emailAddressRows[i].Id, 'email': emailAddressRows[i].ECOM_Email__c, 'notificationTypes': notificationTypes};
            this.formattedEmails.push(formattedEmailRecord);
            this.additionalEmailCount = this.formattedEmails.length > 0 ? true :false;
        }
    }

    showMessage(message,type,show){
        this.message = message;
        this.type = type;
        this.show = show;
    }
    handleUpdateMessage(){
        this.message = '';
        this.type = '';
        this.show = false;
    }


    //Data layer regarding changes starts
    prepareDataLayerData(eventName,orderDetails,payMethod,prodId){
        var data;
        //for purchase event
        if(eventName=='purchase'){
        data =  {
             'event': 'purchase',
             'order': {
                        'total': orderDetails.GrandTotalAmount|| undefined,
                        'subTotal': orderDetails.TotalAdjustedProductAmount|| undefined,
                        'totalTariffSurcharge': orderDetails.totalTariffSurcharge|| undefined,// RWPS-3026
                        'id': orderDetails.Id|| undefined,
                        'shippingAmount': orderDetails.TotalAdjDeliveryAmtWithTax|| undefined,
                        'tax': orderDetails.TotalTaxAmount|| undefined,
                        'discountCode': orderDetails.ECOM_Promo_Code__c|| undefined,
                        'discountType':orderDetails.ECOM_Promo_Code__c? 'promotion': undefined,
                        'discountAmount': orderDetails.ECOM_Total_Savings__c|| undefined,
                        'checkoutType': 'ecom',
                        'paymentMethod': payMethod,
                        'deliveryMethod': (orderDetails.OrderDeliveryGroups) ? orderDetails.OrderDeliveryGroups[0].OrderDeliveryMethod.Name : undefined,
                        'purchaseOrderNumber': orderDetails.PoNumber|| undefined,
             'items': []
             } 
        };
             let items = [];
             if(orderDetails.Id){
                getDataLayerDataByOrder({orderId:orderDetails.Id})
                .then(result=>{
                    this.orderDetailForDatalayer=result;
                        for(let i=0;i< orderDetails.OrderItems.length;i++){
                            let productId = orderDetails.OrderItems[i].Product2Id;
                            items.push({
                                'name': orderDetails.OrderItems[i]?.Product2?.Name ||undefined,
                                'partNumber':[orderDetails.OrderItems[i]?.Product2?.Part_Number__c]|| undefined,
                                'paccode': result?.dataLayer[productId]?.paccode +'-'+ result?.dataLayer[productId]?.igorDescription||undefined,
                                'businessUnit': result?.dataLayer[productId].superBussinessUnit +'-'+ result?.dataLayer[productId].subBussinessUnit || undefined ,
                                'portfolioLevel2':result?.dataLayer[productId].portfolioLevel2||undefined ,
                                'productLine':  result?.dataLayer[productId].productLine +'-'+ result?.dataLayer[productId].productLineName || undefined ,
                                'productClass':result?.dataLayer[productId].productClass ||undefined ,
                                'productBrand': result?.dataLayer[productId]?.productBrand || 'undefined' ,
                                'sapStatus': result?.productSalesStatus[productId] ||undefined,
                                'hasImage': orderDetails.OrderItems[i]?.productDetail?.defaultImage?.url? true:false,
                                'quantity':  result?.dataLayer[productId]?.quantity|| undefined,
                                'price': result?.dataLayer[productId]?.totalPrice||undefined ,
                                'listPrice': orderDetails.OrderItems[i]?.ListPrice|| undefined,
                                'finalPrice': orderDetails.OrderItems[i]?.UnitPrice|| undefined,
                                'currency': orderDetails.CurrencyIsoCode || undefined,
                            });
                        }
                        data['order']['items'] = items;
                        this.handlePublishMsg(data);
                    })
                    .catch(error => {
                        //console.log('Error occured:- '+error?.body?.message || error);
                    });
                }
               
               
    }

    //for remove_from_wishlist event
    if(eventName=='remove_from_wishlist'){
        data =  {
                        event: 'remove_from_wishlist',
                        product:{
                                    businessUnit:this.orderDetailForDatalayer?.dataLayer[prodId]?.superBussinessUnit+'-'+this.orderDetailForDatalayer?.dataLayer[prodId]?.subBussinessUnit||undefined,
                                    productClass:this.orderDetailForDatalayer?.dataLayer[prodId]?.productClass||undefined,
                                    productLine:this.orderDetailForDatalayer?.dataLayer[prodId]?.productLine+'-'+this.orderDetailForDatalayer?.dataLayer[prodId]?.productLineName||undefined,
                                    productBrand:this.orderDetailForDatalayer?.dataLayer[prodId]?.productBrand||undefined,
                                    paccode:this.orderDetailForDatalayer?.dataLayer[prodId]?.paccode+'-'+this.orderDetailForDatalayer?.dataLayer[prodId]?.igorDescription||undefined,
                                    productName:this.orderDetailForDatalayer?.dataLayer[prodId]?.name||undefined,
                                    modelName: this.orderDetailForDatalayer?.dataLayer[prodId]?.name||undefined,
                                    partNumber: this.orderDetailForDatalayer?.dataLayer[prodId]?.partNumber||undefined,
                                    sapStatus: this.orderDetailForDatalayer?.productSalesStatus[prodId] ||undefined
                                }
        }
        this.handlePublishMsg(data);
    }

    //for add_to_wishlist event
    if(eventName=='add_to_wishlist'){
        data =  {
            'event': 'add_to_wishlist',
                    product:{
                        businessUnit:this.orderDetailForDatalayer?.dataLayer[prodId]?.superBussinessUnit+'-'+this.orderDetailForDatalayer?.dataLayer[prodId]?.subBussinessUnit||undefined,
                        productClass:this.orderDetailForDatalayer?.dataLayer[prodId]?.productClass||undefined,
                        productLine:this.orderDetailForDatalayer?.dataLayer[prodId]?.productLine+'-'+this.orderDetailForDatalayer?.dataLayer[prodId]?.productLineName||undefined,
                        productBrand:this.orderDetailForDatalayer?.dataLayer[prodId]?.productBrand||undefined,
                        paccode:this.orderDetailForDatalayer?.dataLayer[prodId]?.paccode+'-'+this.orderDetailForDatalayer?.dataLayer[prodId]?.igorDescription||undefined,
                        productName:this.orderDetailForDatalayer?.dataLayer[prodId]?.name||undefined,
                        modelName: this.orderDetailForDatalayer?.dataLayer[prodId]?.name||undefined,
                        partNumber: this.orderDetailForDatalayer?.dataLayer[prodId]?.partNumber||undefined,
                        sapStatus: this.orderDetailForDatalayer?.productSalesStatus[prodId] ||undefined
                    }
       };
       this.handlePublishMsg(data);

    }
}
      
    handlePublishMsg(data) {

        let payLoad = {
                data: data,
                type: 'DataLayer',
                page:'checkout'
        };
        publish(this.messageContext, ECOM_DATALAYERCHANNEL, payLoad);
    }
    //DataLater regarding changes end



    //navigate to PDP
      navigateToPDP(event) {
        let payLoad = {message: NAVIGATE_TO_PDP,
            type: CMS_NAVIGATION,
            partNumber: '',
            url: event.currentTarget.dataset.url||''
        };
        publish(this.messageContext, ECOM_MESSAGE, payLoad);       
    }
}