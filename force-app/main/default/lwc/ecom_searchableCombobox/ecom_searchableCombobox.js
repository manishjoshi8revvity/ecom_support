import { LightningElement, api, track, wire } from 'lwc';// RWPS-2317
import retrieveProductsByPartialPartNumber from '@salesforce/apex/ECOM_CartController.retrieveProductsByPartialPartNumber';
import communityId from '@salesforce/community/Id';
import getPrimaryCartBasedOnOwner from '@salesforce/apex/ECOM_CartController.getPrimaryCartBasedOnOwner';
import Id from "@salesforce/user/Id";
// RWPS -2317 - START
import { getRecord } from 'lightning/uiRecordApi';
import ECOM_Is_Punchout_User__c from '@salesforce/schema/User.ECOM_Is_Punchout_User__c';
// RWPS -2317 - END

export default class Ecom_searchableCombobox extends LightningElement {

    userId = Id;

    @api classes;
    @api label;
    @api placeholder;
    @api value;
    @api options=[];
    inputVal;
    @api
    selectedPartNumber;

    @track isFocussed = false;
    @track isOpen = false;

    showSpinner = false;

    type='';
    message='';
    showMessage=false;

    filteredOptions = [];
    domElement;

    _handleOutsideClick;
    //RWPS-2317 START
    @track isPunchoutUser = false; //RWPS-2336
    @wire(getRecord, {
        recordId: Id,
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
    } //RWPS-2317 END

    constructor() {
        super();
        this._handleOutsideClick = this.handleOutsideClick.bind(this);
    }

    connectedCallback() {
        //this.filteredOptions = [...this.options];
        this.getPrimaryCart();
        document.addEventListener('click', this._handleOutsideClick);
    }

    disconnectedCallback() {
        document.removeEventListener('click', this._handleOutsideClick);
    }

    getPrimaryCart() {
        // Call the 'getPrimaryCartBasedOnOwner' apex method imperatively
        getPrimaryCartBasedOnOwner({
            userId: this.userId
        }).then((result) => {
            if(result){
                this.isPunchoutCart = result[0]?.ECOM_Is_Punchout_Cart__c;
                this.cartId = result[0]?.Id;
            }
            }).catch((error) => {
                console.log(error);
            });
    }

    handleSearch(event){
        window.clearTimeout(this.timer);

        this.inputVal = event.detail.value;
        if(this.inputVal == ''){
            const custEvent = new CustomEvent(
                'selectoption', {
                    detail: {
                        value: '',
                        label: '',
                        partnumber: ''
                    }
                }
            );
            this.dispatchEvent(custEvent);
        }
        this.timer = setTimeout(() => {
            if(this.inputVal){
                this.filterOptions();
            }
        }, 700); //RWPS-2108
    }

    filterOptions(event) {
        this.showSpinner = true;
        this.showMessage = false;
        this.options = [];
        this.filteredOptions = [];
        retrieveProductsByPartialPartNumber({
            productData : this.inputVal,
            excludedItems : '',
            isPunchoutCart: this.isPunchoutUser,//RWPS-2317
            communityId: communityId
        }).then(result=>{ //RWPS-2108
            this.options = [];
            this.filteredOptions = [];
            this.showSpinner = false;
            this.isFocussed = true;
            this.isOpen = true;
            for (let i = 0; i < result.products.length; i++) {
                this.options.push(result.products[i].Product__r);
            }
            this.filteredOptions = this.options.filter(option => {
                return option.Part_Number__c.toLowerCase().includes(this.inputVal.toLowerCase());
            });
        }).catch(error=>{
            console.log(error);
        });
    }

    handleSelectOption(event) {
        this.inputVal = event.currentTarget.dataset.label;
        this.value = this.inputVal;
        let domElement = this.template.querySelector('lightning-input');
        domElement.value = event.currentTarget.dataset.label;
        const custEvent = new CustomEvent(
            'selectoption', {
                detail: {
                    value: event.currentTarget.dataset.value,
                    label: event.currentTarget.dataset.value,
                    partnumber: event.currentTarget.dataset.value
                }
            }
        );
        this.dispatchEvent(custEvent);

        // Close the picklist options
        this.isFocussed = false;
        this.isOpen = false;
    }

    // RWPS-3826 start
    handleKeyDownOption(event) {
        if (event.key === 'Enter' || event.key === 13 || event.key === 'Space' || event.keyCode === 32) { // RWPS-4086
            this.handleSelectOption(event);
            return; // RWPS-4086
        }

        // RWPS-4086 start
        if (event.key === 'ArrowDown' || event.keyCode === 40 || event.key === 'ArrowUp' || event.keyCode === 38) {
            event.preventDefault();
            event.stopPropagation();

            let optionElements = this.template.querySelectorAll('.rvty-listbox-item');
            let focussedElement = this.template.activeElement;
            let currentIndex = -1;

            for (let i = 0; i < optionElements.length; i++) {
                if (optionElements[i] === focussedElement) {
                    currentIndex = i;
                    break;
                }
            }

            if (event.key === 'ArrowDown' || event.keyCode === 40 && currentIndex < optionElements.length - 1) {
                optionElements[currentIndex + 1]?.focus();
            } else if (event.key === 'ArrowUp' || event.keyCode === 38) {
                if(currentIndex > 0) {
                    optionElements[currentIndex - 1]?.focus();
                } else {
                    this.refs.searchInput?.focus();
                }

            }
            return;
        }
        // RWPS-4086 end
    }
    // RWPS-3826 end

    get noOptions() {
        return this.filteredOptions.length === 0;
    }

    get dropdownClasses() {

        let dropdownClasses = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';

        // Show dropdown list on focus
        if (this.isOpen) {
            dropdownClasses += ' slds-is-open';
        }

        return dropdownClasses;
    }

    handleOutsideClick(event) {

        if ((!this.isFocussed) && (this.isOpen) && (!this.showSpinner)) {

            //Fetch the dropdown DOM node
            let domElement = this.template.querySelector('div[data-id="resultBox"]');
            let  isValueMatched  = false;
            //Is the clicked element within the dropdown
            if (domElement && !domElement.contains(event.target) && this.filteredOptions.length > 0) {
                this.isOpen = false;
                for (let i = 0; i < this.filteredOptions.length; i++) {
                    if(this.filteredOptions[i].Part_Number__c == this.inputVal){
                        isValueMatched =  true;
                        break;
                    }
                }
            }

            if(isValueMatched){
                this.value = this.inputVal;
                const custEvent = new CustomEvent(
                    'selectoption', {
                        detail: {
                            value: event.currentTarget.dataset.value,
                            label: event.currentTarget.dataset.value,
                            partnumber: event.currentTarget.dataset.value
                        }
                    }
                );
                this.dispatchEvent(custEvent);
            }else{
                this.type='error';
                this.message= this.selectedPartNumber?.includes(this.inputVal) ? '' :  'Please enter a valid part number'; //RWPS-2108
                this.showMessage=true;
            }
            this.isFocussed = false;
            this.isOpen = false;
        }
    }

    handleFocus() {
        this.isFocussed = true;
        //this.isOpen = true;
    }

    handleBlur() {
        this.isFocussed = false;
    }

    // RWPS-4086 start
    handleKeyDownInput(event) {
        if (event.key === 'ArrowDown' || event.keyCode === 40) {
            event.preventDefault();
            event.stopPropagation();
            this.template.querySelector('.rvty-listbox-item:first-child')?.focus();
        }
    }
    // RWPS-4086 end
}