import { LightningElement } from 'lwc';

//static resources
import sres_ECOM_CartIcons from '@salesforce/resourceUrl/ssrc_ECOM_Theme';

//labels
import ECOM_LBL_CREATEAREVVITYACCOUNT from '@salesforce/label/c.ECOM_CreateARevvityAccount';

export default class Ecom_registrationSuccessPage extends LightningElement {

    //labels
    labels = {
        ECOM_LBL_CREATEAREVVITYACCOUNT,
    }

    //images
    images = {
        loginpagelogo : sres_ECOM_CartIcons + '/img/revvity-logo-loginpage.svg'
    }

    
}