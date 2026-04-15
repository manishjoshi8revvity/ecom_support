import { LightningElement, api } from 'lwc';

//static resources
import sres_ECOM_CartIcons from '@salesforce/resourceUrl/ssrc_ECOM_Theme';

//labels
import ECOM_LBL_CREATEAREVVITYACCOUNT from '@salesforce/label/c.ECOM_CreateARevvityAccount';
import ECOM_LBL_CONTACTINFORMATION from '@salesforce/label/c.Ecom_Contact_Information';

export default class Ecom_registrationPage extends LightningElement {

    @api loginPagePath;
    @api registrationSuccessPagePath;
    
    //boolean 
    showSpinner=false;



    //labels
    labels = {
        ECOM_LBL_CREATEAREVVITYACCOUNT,
        ECOM_LBL_CONTACTINFORMATION
    }

    constructor() {
        super();
    }

   //images
    images = {
        loginpagelogo : sres_ECOM_CartIcons + '/img/revvity-logo-loginpage.svg'
    }

}