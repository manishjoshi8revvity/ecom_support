import { LightningElement, track } from 'lwc';
import ssrc_ECOM_Theme from '@salesforce/resourceUrl/ssrc_ECOM_Theme';

export default class Ecom_accountSearch extends LightningElement {

    @track
    images = {
        dashboard: ssrc_ECOM_Theme + '/img/dashboard.png',
        logout: ssrc_ECOM_Theme + '/img/logout.png',
        back: ssrc_ECOM_Theme+'/img/back.png',
        helpimg: ssrc_ECOM_Theme + '/img/checkouttooltip.png',
    }

    @track isSubmitDisabled = true;
    @track accountNumber;

    handleNumberChange(event){
       
        if(event.detail.value.length === 1){
            event.detail.value = event.detail.value.trim();
        }
        this.accountNumber = event.detail.value;
        this.isSubmitDisabled = false;
    }

    handleSubmit(){
       
        if(this.accountNumber){
            //search for account
        }
    }

    goBackToAccounts(){
        //navigate back to main accounts page.
    }

    navigateToAddAddressPage(){
        //navigate to add address page.
    }

}