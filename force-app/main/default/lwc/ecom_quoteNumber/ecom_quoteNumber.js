import FORM_FACTOR from '@salesforce/client/formFactor';
import { LightningElement, api, track } from 'lwc';

export default class Ecom_quoteNumber extends LightningElement {

    @track modalSize = "";
    @track showModal = false;
    @track isBtnDisabled = true;
    @api quoteNumber;
    updatedQuoteNumber;
    @api
    openModal()
    {
        this.updatedQuoteNumber = this.quoteNumber;
        this.checkButton();
        this.showModal = true;
        //sendPostMessage('hidden');
    }
    closeModal()
    {
        this.updatedQuoteNumber = '';
        this.showModal = false;
        //sendPostMessage('auto');
    }

    device = {
        isMobile : FORM_FACTOR==='Small',
        isDesktop : FORM_FACTOR==='Large',
        isTablet :FORM_FACTOR==='Medium'
    }

    #escapeKeyCallback; // RWPS-4086

    connectedCallback() {
        this.loadBasedOnDeviceType()

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
                this.closeModal();
            }
        }
    }

    // RWPS-4086 end

    loadBasedOnDeviceType() {
        if (this.device.isMobile) {
            this.modalSize = 'slds-modal slds-fade-in-open slds-modal_full';


        } else {
            this.modalSize = 'slds-modal slds-fade-in-open slds-modal_small';
        }
    }

    quoteNumberChanged(event){
        const inputValue = event.target.value;
        this.updatedQuoteNumber = inputValue;
        this.checkButton();
    }

    checkButton(){
        this.isBtnDisabled = !this.updatedQuoteNumber? true : false;
    }

    handleAddQuoteNumber()
    {
        this.dispatchEvent(
            new CustomEvent('quotenumberupdated', {
                detail: {
                    updatedQuoteNumber: this.updatedQuoteNumber?.trim()
                }
            })
        );
        this.closeModal();
    }
}