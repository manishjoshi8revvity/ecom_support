import { LightningElement, api } from 'lwc';
//import getShippingAddress from '@salesforce/apex/ECOM_CheckoutController.getShippingAddress';

export default class Ecom_shippingAddressModificationModal extends LightningElement {

    //@api effectiveAccountId;
    showModal=false; 
    shipToAddresses = [];

    @api
    openModal()
    {
        this.showModal = true;
    }

    closeModal()
    {
        this.showModal=false;
    }

    connectedCallback() {

        // getShippingAddress({

        // }).then((result) => {
        //     console.log(' result >>',result);
        //     if(result){
        //         this.shipToAddresses.push(result[0]?.shipToDetails[0]);
        //     }
        //     this.shipToAddresses.push(result[0]?.shipToDetails[0]);
        //     console.log('this.shipToAddresses =>',this.shipToAddresses);
        // }).catch((error) => {
        //     console.log('error ',error);
        //     const errorMessage = error.body.message;
        // });
    }

}