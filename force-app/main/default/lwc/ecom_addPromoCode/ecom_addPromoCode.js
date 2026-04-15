import FORM_FACTOR from '@salesforce/client/formFactor';
import { LightningElement, api, track } from 'lwc';


export default class Ecom_addPromoCode extends LightningElement {
    @track modalSize="";
    @track showModal = false;
    @track isBtnDisabled = true;
    @api promoCode;
    updatedPromoCode;
    @api
    openModal()
    {
        this.updatedPromoCode = this.promoCode;
        this.checkButton();
        this.showModal = true;
        //sendPostMessage('hidden')
    }
    closeModal()
    {
        this.updatedPromoCode = '';
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


    promoCodeChanged(event){
        const inputValue = event.target.value;
        const trimmedValue = inputValue.replace(/[^a-zA-Z0-9]/g, '');//RWPS-3234
        this.updatedPromoCode = trimmedValue.toUpperCase();//RWPS-3234
        event.target.value = trimmedValue;
        this.checkButton();
    }

    //RWPS-3234 Start
    promoCodeKeyDown(event) {
        const key = event.key;
        const controlKeys = ['Backspace', 'Delete', 'ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown','Tab'];
        const isValidChar = /^[a-zA-Z0-9]$/.test(key);
        if (!isValidChar  && !controlKeys.includes(key)) {
            event.preventDefault();
        }
    }//RWPS-3234 end

    checkButton(){
        this.isBtnDisabled = !this.updatedPromoCode? true : false;
    }

    handleAddPromoCode()
    {
        this.dispatchEvent(
            new CustomEvent('promocodeupdated', {
                detail: {
                    updatedPromoCode: this.updatedPromoCode
                }
            })
        );
        this.closeModal();
    }
}