import { LightningElement,api } from 'lwc';
import ssrc_ECOM_Theme from '@salesforce/resourceUrl/ssrc_ECOM_Theme';


export default class Ecom_revHeaderImg extends LightningElement {
    @api
images = {
    cartimg: ssrc_ECOM_Theme + '/img/cartIcon.svg',
    logoimg: ssrc_ECOM_Theme + '/img/revvitylogo.png',
    nameimg: ssrc_ECOM_Theme + '/img/namecircle.png',
    asimg: ssrc_ECOM_Theme + '/img/AS.png',
    vsvg: ssrc_ECOM_Theme + '/img/vsvg.svg',
    }
}