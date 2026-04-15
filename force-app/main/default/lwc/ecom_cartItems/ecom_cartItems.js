import FORM_FACTOR from '@salesforce/client/formFactor';
import sres_ECOM_CartIcons from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import { resolve } from 'experience/resourceResolver';
import { LightningElement, api, track } from 'lwc';
import {processAndLogJSError} from 'c/ecom_util';//RWPS-5153

export default class Ecom_cartItems extends LightningElement {
    _items;
    _quantity;
    @api
    cartShippingDates;
    @api cartSalesStatus;
    @api isPromoApplied;
    @api selectedItemId;
    @api wishlist;
    @api cartitemDiscontinuedProducts; //RWPS-2786
    @api cartItemTariffCharge; //RWPS-3026
    @api trainingProductMap ; //RWPS-4896
    @api genericTrainingProductMap; //RWPS-4896
    @api
    set items(val) {
        
        this._items = val;
        // this.quantity = Number(this._items?.quantity);
        // this.earliestDate = this.cartShippingDates && this.cartShippingDates[this.item.cartItemId]?.ECOM_Earliest_Shipping_Date__c ||'';
        // this.selectedDate = this.cartShippingDates && this.cartShippingDates[this.item.cartItemId]?.ECOM_Selected_Shipping_Date__c ||'';
    }
    get items() {
        return this._items;
    }
    set quantity(val) {
        this._quantity = val;
    }
    get quantity() {
        return this._quantity;
    }
    get totalShipment(){
        return this.items.length;
    }
    @api
    fieldlabelmap;
    @api
    isCartDisabled = false;
    @track pageSize = '';
    @api
    productFields;
    @api
    freeItemMap; //RWPS-3811
    @api
    isLargePackOrder;
    filename='ecom_cartItems';//RWPS-5153
    moduleName='ECOM_CartService / Checkout Management';//RWPS-5153
    device = {
        isMobile : FORM_FACTOR==='Small',
        isDesktop : FORM_FACTOR==='Large',
        isTablet :FORM_FACTOR==='Medium'
    }

    connectedCallback() {
        this.loadBasedOnDeviceType()
    }

    loadBasedOnDeviceType() {
        if (this.device.isMobile) {
            this.pageSize = 'cartSizeMobile';
            
           
        } else {
            this.pageSize = '';
        }
    }

    get itemShippingDates(){
        return {
            earliest : this.cartShippingDates && this.cartShippingDates[this.item.cartItemId]?.ECOM_Earliest_Shipping_Date__c ||'',
            selectedDate : this.cartShippingDates && this.cartShippingDates[this.item.cartItemId]?.ECOM_Selected_Shipping_Date__c ||''
        }
    }
    _earliestDate;
    get earliestDate(){
        return this._earliestDate;
    }
    set earliestDate(dateValue){
        this._earliestDate = dateValue;
    }
    _selectedDate;
    get selectedDate(){
        return this._selectedDate;
    }
    set selectedDate(dateValue){
        this._selectedDate = dateValue;
    }

    renderedCallback(){
        // this.earliestDate = this.cartShippingDates && this.cartShippingDates[this.item.cartItemId]?.ECOM_Earliest_Shipping_Date__c ||'';
        // this.selectedDate = this.cartShippingDates && this.cartShippingDates[this.item.cartItemId]?.ECOM_Selected_Shipping_Date__c ||'';
    }
    // handleCartChangeEvent()
    // {
    //     console.log('in fire cartchange event: B');
    //     this.dispatchEvent(
    //         new CustomEvent('cartchange')
    //     );
    // }

    get fields(){
        let fields = [];
        for (const [key, value] of Object.entries(this.item.productDetails.fields)) {
            if(this.fieldlabelmap[key] != 'Dangerous Goods Indicator Profile'){
                fields.push({
                    'name' :this.fieldlabelmap[key] ||  key.replaceAll('_',' ').replace('__C',''),
                   'value'  : value
                 });
            }
        }
        return fields;
    }

    get itemImage(){
         return  resolve(this.item?.productDetails?.thumbnailImage.url ?? '', false, {
            height: 460,
            width: 460,
        }) ;
    }
    images = {
        cartimg: sres_ECOM_CartIcons + '/img/bag-line.png',
        deleteimg: sres_ECOM_CartIcons + '/img/delete-icon.png',
        quickorderimg:sres_ECOM_CartIcons + '/img/quick-order.png',
        favoriteimg:sres_ECOM_CartIcons + '/img/heart-line.png',
        helpimg:sres_ECOM_CartIcons + '/img/help-icon.png',
        termsimg:sres_ECOM_CartIcons + '/img/pencil-line.png',
    }

    handleAddToWishlist(event){
    try{//RWPS-5153
        this.dispatchEvent(
            new CustomEvent('createandaddtolist', {
                detail: {
                    productId: event?.detail?.productId,
                    productName : event?.detail?.productName
                }
            })
        );
    }catch(error){//RWPS-5153 start
        processAndLogJSError(error, this.filename, this.moduleName, 'handleAddToWishlist');
    }//RWPS-5153 end
    }

    // handleDeleteItem(event){
    //     // this.dispatchEvent(
    //     //     new CustomEvent('deleteitem')
    //     // );
    //     console.log('handle delete item', event?.detail?.message);
    //     this.dispatchEvent(
            
    //         new CustomEvent('deleteitem'), {
    //             detail: {
    //                 message: event.detail.message,
    //                 type:event.detail.type,
    //                 show: event.detail.show
    //             }
    //         }, {
    //             bubbles: true,
    //             composed:true
    //           }
    //     );
    // }

    // handleDebounceEvent(){
    //     this.dispatchEvent(
    //         new CustomEvent('handledebounce')
    //     );
    // }

    getUpdatedDates(){
        this.dispatchEvent(
            new CustomEvent('getshippingdates')
        );
    }


    handlegtmEvent(event){
        this.dispatchEvent(
            new CustomEvent('capturegtmevent', {
                detail: {
                    data: event?.detail?.data,
                    productId : event?.detail?.productId
                }
            }, {
                bubbles: true,
                composed:true
              })
        );
    }
    handleaddresserrorEvent(event){
        this.dispatchEvent(
            new CustomEvent('addresserror',  {
                detail: {
                    message: event?.detail?.message
                }
            }, {
                bubbles: true,
                composed:true
              })
        );
    }

    handleRemoveFromFavourite(event){
        this.dispatchEvent(
            new CustomEvent('removefromfavorite', {
                detail: {
                    wishlistItemId:event?.detail?.wishlistItemId,
                }
            }, {
                bubbles: true,
                composed:true
              })
        );
    }
    
    handleCartItemRemoveClicked(event){
        this.dispatchEvent(
            new CustomEvent('removeclicked', {
                bubbles: true,
                composed: true,
                detail: {
                    updatePriceDisabled: event.detail.updatePriceDisabled
                }
            })
        );
    }

    // handleQuantityIncrement(event){
    //     console.log('qunatity change'); 
    //     this.quantity += 1;
    //     updateItemInCart(this.item.cartItemId,this.quantity);
    //     this.fireDebounceEvent();
    // }

    // handleQuantityDecrement(event){
    //     console.log('qunatity change');
    //     if(this.quantity ===1){
    //         console.log('Quantity cannot be less than 1.');
    //         return false;
    //     }
    //     this.quantity -= 1;
    //     updateItemInCart(this.item.cartItemId,this.quantity);
    //     this.fireDebounceEvent();
    // }

    // handleQuantityChange(event){
    //     console.log('qunatity change');
    //     if(parseInt(event.target.value)===0){
    //         console.log('Quantity cannot be0.');
    //         return false;
    //     }

    //     this.quantity = Number(event.target.value);
    //     updateItemInCart(this.item.cartItemId,this.quantity);
    //     this.fireDebounceEvent();
    // }

    // handleDeleteCartItem(){
    //     //deleteItemFromCart(this.item.cartItemId);
    //     const result= deleteItemFromCart(this.item.cartItemId);
    //         result.then((response) => {
    //             this.dispatchEvent(
    //                 new CustomEvent('deleteitem', {
    //                     detail: {
    //                         message: this.item?.productDetails?.name+' was removed.',
    //                         type:'success',
    //                         show: true
    //                     }
    //                 })
    //             );
    //         }).catch((error) => {
    //             this.dispatchEvent(
    //                 new CustomEvent('deleteitem', {
    //                     detail: {
    //                         message: this.item?.productDetails?.name+' was not removed.',
    //                         type:'error',
    //                         show: true
    //                     }
    //                 })
    //             );
    //             console.log('Error in cart item deletion');
    //         });
    // }
    // handleAddToFavourite(){
    //     this.dispatchEvent(
    //         new CustomEvent('createandaddtolist', {
    //             detail: {
    //                 productId: this.item.productId,
    //                 productName : this.item?.productDetails?.name
    //             }
    //         })
    //     );
    // }
    // @track isModalOpen = false;

    // openDeliveryModal() {
    //     this.template.querySelector('c-ecom_delivery-time-modal').openModal();
    // }

    // closeModal() {
    //     this.isModalOpen = false;
    // }

    // @track isDateSelectorOpen = false;

    // handleOpenDateSelector(event){
    //     this.isDateSelectorOpen = true;
    //     this.selectedItemId = event.currentTarget.dataset.id;
    //     //console.log(event.currentTarget.dataset.id);
    // }

    // handleCloseDateSelector(){
    //     this.isDateSelectorOpen = false;
    // }

    // handleApplyDateSelector(){
    //     this.template.querySelector('c-ecom_date-picker').updateShippingDate();
    //     this.isDateSelectorOpen = false;
    // }

    // fireDebounceEvent(){
    //     console.log('in fire debounce event');
    //     this.dispatchEvent(
    //         new CustomEvent('handledebounce')
    //     );
    // }

    // handleDateSelected(event){
    //     console.log('date selected',event);
    //     this.selectedDate = event?.detail?.dateString;
    // }
}