import { LightningElement, api, track } from 'lwc';

//static resources
import sres_ECOM_CartIcons from '@salesforce/resourceUrl/ssrc_ECOM_Theme';

export default class Ecom_fullWidthImageCard extends LightningElement {

    @api imagePath;

    @track imageUrlPath;

    images = {
        sres_ECOM : sres_ECOM_CartIcons,
        image : sres_ECOM_CartIcons,
    }

    get currentLogoImage(){
        let logoUrl;
        let logostring = '/img/revvity-logo-loginpage.svg';
        if(this.imagePath == '' || this.imagePath == undefined || this.imagePath == null){
            logoUrl = this.images.image + logostring;
        }
        
        return logoUrl;
    }

    connectedCallback(){
        
        this.imageUrlPath = this.images.sres_ECOM + this.imagePath;
        console.log('images:: ', this.images.image + this.imageUrlPath);//Remove after DEV
    }
}