import { LightningElement } from 'lwc';

//labels
import ECOM_LBL_404 from '@salesforce/label/c.ECOM_404';
import ECOM_LBL_PAGELOOKINGFORNOTAVAILABLE from '@salesforce/label/c.ECOM_PageLookingForNotAvailable';
import ECOM_LBL_BACKTOHOMEPAGE from '@salesforce/label/c.ECOM_BackToHomePage';

//apex
import getHomeUrl from '@salesforce/apex/ECOM_CustomLoginController.getCMSUrl';

export default class Ecom_commerceNotAvailablePage extends LightningElement {

    //label
    labels = {
        ECOM_LBL_404,
        ECOM_LBL_PAGELOOKINGFORNOTAVAILABLE,
        ECOM_LBL_BACKTOHOMEPAGE
    }


    //handleBackToHomePage
    handleBackToHomePage(){
        getHomeUrl().then(result => {
            //console.log('handleBackToHomePage.result:: ', result);//Remove after DEV
            if(result && result.success){
                window.location.replace(result.responseData.Home)
            }
        }).catch(error => {
            //console.log('handleBackToHomePage.error::', error);//Remove after DEV
        })
    }
}