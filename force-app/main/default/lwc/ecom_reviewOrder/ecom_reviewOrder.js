import { LightningElement,track,api } from 'lwc';
import sres_ECOM_CartIcons from '@salesforce/resourceUrl/ssrc_ECOM_Theme';


export default class Ecom_reviewOrder extends LightningElement {
    @track
    images = {
        visaimg: sres_ECOM_CartIcons + '/img/visa.png',
        helpimg: sres_ECOM_CartIcons + '/img/checkouttooltip.png',
    }
}