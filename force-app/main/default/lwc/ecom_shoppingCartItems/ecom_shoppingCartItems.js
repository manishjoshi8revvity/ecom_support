import { LightningElement, api,track } from 'lwc';
import sres_ECOM_CartIcons from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import { updateItemInCart,deleteItemFromCart } from 'c/ecom_util';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { isCmsResource, resolve } from 'experience/resourceResolver';

import ECOM_Apply  from '@salesforce/label/c.ECOM_Apply';
import Ecom_Cancel_close  from '@salesforce/label/c.Ecom_Cancel_close';
import ECOM_Cancel  from '@salesforce/label/c.ECOM_Cancel';
import ECOM_DateNote_Message  from '@salesforce/label/c.ECOM_DateNote_Message';
import ECOM_Product_Receive_Message  from '@salesforce/label/c.ECOM_Product_Receive_Message';
import ECOM_Select_Date  from '@salesforce/label/c.ECOM_Select_Date';
import ECOM_Change_Date  from '@salesforce/label/c.ECOM_Change_Date';
import ECOM_Remove  from '@salesforce/label/c.ECOM_Remove';
import ECOM_Save_favorites  from '@salesforce/label/c.ECOM_Save_favorites';
import ECOM_ShipEarlyDate  from '@salesforce/label/c.ECOM_ShipEarlyDate';
import ECOM_Change_Shipping_Date  from '@salesforce/label/c.ECOM_Change_Shipping_Date';

export default class Ecom_shoppingCartItems extends LightningElement {

    labels = {
        ECOM_Apply,
        Ecom_Cancel_close,
        ECOM_Cancel,
        ECOM_DateNote_Message,
        ECOM_Product_Receive_Message,
        ECOM_Select_Date,
        ECOM_Change_Date,
        ECOM_Remove,
        ECOM_Save_favorites,
        ECOM_ShipEarlyDate,
        ECOM_Change_Shipping_Date
    }
    
    _item;
    _quantity;
    @api
    cartShippingDates;
    @api selectedItemId;
    @api
    set item(val) {
        this._item = val?.cartItem;
        this.quantity = Number(this._item?.quantity);
        this.earliestDate = this.cartShippingDates && this.cartShippingDates[this.item.cartItemId]?.ECOM_Earliest_Shipping_Date__c ||'';
        this.selectedDate = this.cartShippingDates && this.cartShippingDates[this.item.cartItemId]?.ECOM_Selected_Shipping_Date__c ||'';
    }
    get item() {
        return this._item;
    }
    set quantity(val) {
        this._quantity = val;
    }
    get quantity() {
        return this._quantity;
    }
    @api
    fieldlabelmap;
    @api
    isCartDisabled = false;
   
    device = {
        isMoobile : FORM_FACTOR==='Small',
        isDesktop : FORM_FACTOR==='Large',
        isTablet :FORM_FACTOR==='Medium'
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


    handleQuantityIncrement(event){
        this.quantity += 1;
        updateItemInCart(this.item.cartItemId,this.quantity);
        this.fireDebounceEvent();
    }

    handleQuantityDecrement(event){
        if(this.quantity ===1){
            return false;
        }
        this.quantity -= 1;
        updateItemInCart(this.item.cartItemId,this.quantity);
        this.fireDebounceEvent();
    }

    handleQuantityChange(event){
        if(parseInt(event.target.value)===0){
            return false;
        }

        this.quantity = Number(event.target.value);
        updateItemInCart(this.item.cartItemId,this.quantity);
        this.fireDebounceEvent();
    }

    handleDeleteCartItem(){
        //deleteItemFromCart(this.item.cartItemId);
        const result= deleteItemFromCart(this.item.cartItemId);
            result.then((response) => {
                this.dispatchEvent(
                    new CustomEvent('deleteitem', {
                        detail: {
                            message: this.item?.productDetails?.name+' was removed.',
                            type:'success',
                            show: true
                        }
                    })
                );
            }).catch((error) => {
                this.dispatchEvent(
                    new CustomEvent('deleteitem', {
                        detail: {
                            message: this.item?.productDetails?.name+' was not removed.',
                            type:'error',
                            show: true
                        }
                    })
                );
            });
    }
    handleAddToFavourite(){
        this.dispatchEvent(
            new CustomEvent('createandaddtolist', {
                detail: {
                    productId: this.item.productId,
                    productName : this.item?.productDetails?.name
                }
            })
        );
    }
    @track isModalOpen = false;

    openDeliveryModal() {
        this.template.querySelector('c-ecom_delivery-time-modal').openModal();
    }

    closeModal() {
        this.isModalOpen = false;
    }

    @track isDateSelectorOpen = false;

    handleOpenDateSelector(event){
        this.isDateSelectorOpen = true;
        this.selectedItemId = event.currentTarget.dataset.id;
        //console.log(event.currentTarget.dataset.id);
    }

    handleCloseDateSelector(){
        this.isDateSelectorOpen = false;
    }

    handleApplyDateSelector(){
        this.template.querySelector('c-ecom_date-picker').updateShippingDate();
        this.isDateSelectorOpen = false;
    }

    fireDebounceEvent(){
        this.dispatchEvent(
            new CustomEvent('handledebounce')
        );
    }

    handleDateSelected(event){
        this.selectedDate = event?.detail?.dateString;
    }
}