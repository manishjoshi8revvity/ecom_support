import { LightningElement, track, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id'; 
import CURRENCY_FIELD from '@salesforce/schema/User.CurrencyIsoCode';
import ssrc_ECOM_Theme from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import FORM_FACTOR from '@salesforce/client/formFactor';
import ECOM_DATALAYERCHANNEL from '@salesforce/messageChannel/ecom_DataLayer__c';
import { subscribe, MessageContext } from 'lightning/messageService';
import saveTaxExemptInfo from '@salesforce/apex/ECOM_CheckoutController.saveTaxExemptInfo';
import getCartTaxExemptValue from '@salesforce/apex/ECOM_CheckoutController.getCartTaxExemptValue';
import getCharityNumberValue from '@salesforce/apex/ECOM_CheckoutController.getCharityNumberValue';
import ECOM_TaxExemptLabel  from '@salesforce/label/c.ECOM_TaxExemptLabel';
import ECOM_TaxExemptPopUpLabel  from '@salesforce/label/c.ECOM_TaxExempt';
import Ecom_Cancel_close  from '@salesforce/label/c.Ecom_Cancel_close';
import ECOM_CharityNumberError  from '@salesforce/label/c.ECOM_CharityNumberError';
import ECOM_CharityNumberLabel  from '@salesforce/label/c.ECOM_CharityNumberLabel';

export default class Ecom_checkoutTaxExempt extends LightningElement {
    
    @api effectiveAccountId;
    @api cartId;
    message;
    type;
    show;
    contactInfo;
    shippingAddress={};
    billingAddress={};
    deliveryDetails;
    attentionRecipient;
    contactRecTypeId;
    spInstructionsPicklist = [];
    specialInstructions;
    charityNumber;
    showPicklist = false;
    isFieldsUpdated = false;
    dataLayerSubscription = null;
    @wire(MessageContext)
    messageContext;
    showSpinner = false;

    @api isTaxExemptEditMode;
    @api isTaxExemptReadMode;
    
    images = {
        helpimg: ssrc_ECOM_Theme + '/img/checkouttooltip.png',
    }
    
    @track popoverClass = 'slds-popover slds-popover_tooltip slds-nubbin_bottom slds-fall-into-ground ecom-popover';
    @track showTooltip = false;
    @track isTaxExemptUser = false;
    @track isTaxExempt = false;
    //@track taxExemptFieldUpdated = false;
    showTaxExemptPopUp=false;
    //@track isSaveAndContinueDisabled = false;

    device = {
        isMobile : FORM_FACTOR==='Small',
        isDesktop : FORM_FACTOR==='Large',
        isTablet :FORM_FACTOR==='Medium'
    }

    labels = {
        ECOM_TaxExemptPopUpLabel,
        Ecom_Cancel_close,
        ECOM_TaxExemptLabel,
        ECOM_CharityNumberLabel,
        ECOM_CharityNumberError
    };
    
    
    /*@wire(getRecord, {recordId: USER_ID,fields: [CURRENCY_FIELD]}) 
    wireuser({error,data}) {
        if (error) {
           this.error = error ; 
        } else if (data) {
            let currencyCode;
            currencyCode = data.fields.CurrencyIsoCode.value;
            console.log('here currency code>>>'+currencyCode);
            this.isTaxExemptUser = currencyCode == 'GBP' ? true : false;
            console.log('here isTaxExemptUser value>>'+this.isTaxExemptUser);
        }
    }*/
    
    connectedCallback(){
        this.subscribeDataLayerEvent();
        getCartTaxExemptValue({
                cartId :this.cartId
            }).then(result =>{
                this.isTaxExempt = result;
                if(this.isTaxExempt){
                    this.getCharityNumber();
                }
            }).catch(error =>{
                console.log('here tax getCartTaxExemptValue error>>'+JSON.stringify(error));
            })
    }

    //RWPS-460 - ssingh@rafter.one -  added method to fetch charity number on initial load - 19 April 2024
    getCharityNumber(){
        getCharityNumberValue({
            cartId :this.cartId
        }).then(result =>{
            this.charityNumber = result;
        }).catch(error =>{
            console.log('error>>'+JSON.stringify(error));
        })
    }

    handleSaveAndContinueToOrderReview(){
        this.showSpinner = true;
        if(!this.isTaxExempt || (this.isTaxExempt && this.charityNumber)){ //RWPS-460 - garora@rafter.one -  edited condition to run saveTaxExemptInfo method even when taxExempt is false - 18 April 2024
            saveTaxExemptInfo({
                isTaxExempt:this.isTaxExempt,
                cartId:this.cartId,
                charityNumber:this.charityNumber
            }).then((result) => {
                if(result){
                    //this.taxExemptFieldUpdated = false;     
                    if(result.Status == 'Success'){
                        this.contactInfo = result.Contact;
                        this.moveToNextSection();
                    }
                }
                })
                .catch((error) => {
                    console.log(error);
                });
        }
        else{  //RWPS-416 - ssingh@rafter.one -  Added custom validation for empty charity number - 19 April 2024
            let inputField = this.refs.charNumber;
            inputField.setCustomValidity(this.labels.ECOM_CharityNumberError);
            inputField.reportValidity();
        }     
        this.showSpinner = false;
    }

    moveToNextSection(){
        this.dispatchEvent(
            new CustomEvent('showpaymentsectionaftertaxexempt', {
                detail: {
                    moveToNextSection: true,
                    // poNumber: '',
                    // quoteNumber: '',
                    // promoCode: ''
                }
            })
        );
        this.showSpinner = false;
        
    }

    handleUpdateMessage(){
        this.message = '';
        this.type = '';
        this.show = false;
    }

    navigateToAccounts(){
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
                    attributes: {
                    url: '/dashboard?accountEdit'
                }
            });
    }
    subscribeDataLayerEvent() {
        if (this.dataLayerSubscription) {
            return;
        }
        this.dataLayerSubscription = subscribe(this.messageContext, ECOM_DATALAYERCHANNEL, (message) => {
            if(message?.type === 'CheckoutStep1DataLayer'){
                revvityGTM.pushData(message.data);
            }
        });
    }

    handleTaxExemptChange(event){
        //this.taxExemptFieldUpdated = true;
        this.isTaxExempt = event.target.checked;
    }

    handleCharityNumberChange(event){
        let inputField = this.refs.charNumber;
        inputField.setCustomValidity('');
        inputField.reportValidity();
        this.charityNumber = event.target.value;
    }

    taxExemptPopUp(){
        this.showTaxExemptPopUp=true;
    }

    handlePopUpClose(){
        this.showTaxExemptPopUp=false;
    }
}