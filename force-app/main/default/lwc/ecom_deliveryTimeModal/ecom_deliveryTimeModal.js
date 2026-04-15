import { LightningElement, api,track } from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';
import getShippingTime from '@salesforce/apex/ECOM_CartController.getShippingTime';
import ECOM_Shipping_Time_Label from '@salesforce/label/c.ECOM_Shipping_Time_Label';

export default class Ecom_deliveryTimeModal extends LightningElement {
    isModalOpen = false;
    @api item;
    shippingTimes;
    level1;
    level2;
    level3;
    showSpinner = false;
    @track modalSize="";
    shippingDays = [];//RWPS-1606


    @api
    openModal() {
        this.isModalOpen = true;
    }
    //RWPS-1603-START
    labels = {
        ECOM_Shipping_Time_Label
    }
    //RWPS-1603-END

    closeModal() {
        this.isModalOpen = false;
    }
    device = {
        isMobile : FORM_FACTOR==='Small',
        isDesktop : FORM_FACTOR==='Large',
        isTablet :FORM_FACTOR==='Medium'
    }

    #escapeKeyCallback; // RWPS-4086

    connectedCallback(){
        this.showSpinner = true;
        this.getShippingInfo();
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
            if(this.isModalOpen) {
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
    //RWPS-1606 - Start
    // Send Shipping Days information to parent component
    sendShippingDays(shippingDays) {
        this.dispatchEvent(new CustomEvent('shippingdays', {
            detail: shippingDays
        }));

    }

    sendShippingTimes(shippingTimes){ //RWPS - 1606
        this.dispatchEvent(new CustomEvent('shippingtimes', {
            detail: shippingTimes
        }));
    }

    shippingDaysWithCartItemId(name, val) {
        this.shippingDays[name] = val;
        this.shippingDays.push(this.shippingDays);
     }
    //RWPS-1606 - End

    // Get Shipping Times based on Item Shipping Code
   getShippingInfo() {
    getShippingTime({ itemId: this.item.cartItemId })
        .then((result) => {
            //RWPS-1603 - START
            if (result) {
                this.shippingTimes = result;
                this.showSpinner = false;
                this.sendShippingTimes(this.shippingTimes); // RWPS-1606

                let tempVarDeliveryTime = this.shippingTimes?.Ecom_Confidence_90__c; // RWPS-1606
                this.shippingDaysWithCartItemId(
                    this.item.cartItemId,
                    this.getMaxDays(tempVarDeliveryTime)
                ); // RWPS-1606

                this.sendShippingDays(this.shippingDays); // RWPS-1606
            } else {
                console.warn('Shipping time result is null or undefined.');
                this.showShippinginfo = false;
                this.showSpinner = false;
            }
        })
        .catch((error) => {
            console.log('error ' + JSON.stringify(error));
            this.showShippinginfo = false;
            this.showSpinner = false;
        });
        //RWPS-1603 - END
    }

    //RWPS-1603-Start
    get splitDeliveryInfo() {
    const [deliveryType, estimatedTimeFrame, deliverySpeed] = this.labels.ECOM_Shipping_Time_Label.split(',').map(item => item.trim());
    return {
        deliveryType,
        estimatedTimeFrame,
        deliverySpeed
    };
    }
    //RWPS-1603-End




    /**
     * Extracts the Max number from the provided string.
     * The string can contain a range (e.g., "2-3 Bussiness days") or a single number (e.g., "4 Bussiness days").
     * @param {string} str - The input string.
     * @returns {number|null} - The highest number found, or null if no number exists.
     * JIRA - RWPS-1606
     */
    getMaxDays(str) {
        if (typeof str !== 'string' || !str) {
            return null;
        }
        //RWPS-1603 - Start
        // Check if the string contains the word "week"
        if (str.toLowerCase().includes('week')) {
            return 7;
        }

        // Match all occurrences of one or more digits in the string
        const numberMatches = str.match(/\d+/g);
        if (!numberMatches) {
            return null;
        }

        // Convert the matched strings to integers
        const numbers = numberMatches.map(numStr => parseInt(numStr, 10));

        // Return the highest number found
        return Math.max(...numbers);
        //RWPS-1603 - End
    }



}