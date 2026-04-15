import { LightningElement,track } from 'lwc';
import ssrc_ECOM_Theme from '@salesforce/resourceUrl/ssrc_ECOM_Theme';


export default class Ecom_accountDashboardInProgress extends LightningElement {
    @track
    images = {
        arrowimg: ssrc_ECOM_Theme + '/img/rightarrow.png',
        againimg: ssrc_ECOM_Theme + '/img/again.png',
    }
}