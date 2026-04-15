import { LightningElement } from 'lwc';

//images
import sres_ECOM_CartIcons from '@salesforce/resourceUrl/ssrc_ECOM_Theme';

//labels
import ECOM_LBL_CREATEAREVVITYACCOUNT from '@salesforce/label/c.ECOM_CreateARevvityAccount';

/**
 * @slot forgotpasswordcard
 */
export default class Ecom_forgotPasswordPage extends LightningElement {

    //images
    images = {
        loginpagelogo : sres_ECOM_CartIcons + '/img/revvity-logo-loginpage.svg'
    }

    //labels
    labels = {
        ECOM_LBL_CREATEAREVVITYACCOUNT
    }
    

}