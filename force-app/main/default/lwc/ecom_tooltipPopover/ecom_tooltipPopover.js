import { LightningElement, api, track} from 'lwc';

//static resources
import sres_ECOM_CartIcons from '@salesforce/resourceUrl/ssrc_ECOM_Theme';

export default class Ecom_tooltipPopover extends LightningElement {

    @api tooltipContent = 'testcontent';
    @api tooltipImage = '';
    @api tooltipText = '';
    @api tooltipLabel='';
    @api arrow;

    @api maxWidth;
    @api maxHeight;
    @api isLeftAligned=false;
    @api isRightAligned=false;

    //text 
    imageclass;

    //boolean
    displaycontent = false;

    //Images
    image = {
        revvityDropBottom: sres_ECOM_CartIcons + '/img/tooltip-arrow-bottom.svg',
        revvityDropTop: sres_ECOM_CartIcons + '/img/tooltip-arrow-top.svg',
        revvityDropLeft: sres_ECOM_CartIcons + '/img/tooltip-arrow-left.svg',
        revvityDropRight: sres_ECOM_CartIcons + '/img/tooltip-arrow-right.svg',
        question : sres_ECOM_CartIcons + '/img/tooltip-image.svg'
    }
    
    get tooltipContentDisplay(){
        return this.tooltipContent;
    }

    get arrowImage(){
        let image = 'revvityDropBottom';
        if(this.image[this.arrow] == undefined || this.image[this.arrow] == '' || this.image[this.arrow] == null){
            image = this.image.revvityDropTop;
        } else {
            image = this.image[arrow];
        }

        return image;
    }

    get toolTipImage(){
        console.log('tooltipimage:: ', this.tooltipImage);//Remove after DEV
        let displayToolTipImage = false;
        if(this.tooltipImage ){
            displayToolTipImage = true;
        }

        return displayToolTipImage;
    }


    onToolTipClick(event){
        if(this.displaycontent){
            this.displaycontent = false; 
        } else {
            this.displaycontent = true;
        }
    }


}