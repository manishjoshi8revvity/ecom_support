import { LightningElement, api,wire } from 'lwc';
import getCountriesBannerMsgGuest from "@salesforce/apex/ECOM_RegistrationController.getCountriesBannerMsgGuest";
import getCountriesBannerMsgLoggedin from "@salesforce/apex/ECOM_UserController.getCountriesBannerMsgLoggedin";
import { MessageContext, subscribe } from 'lightning/messageService';
import ECOM_MESSAGE from '@salesforce/messageChannel/ecom_MessagingChannel__c';
import isGuest from '@salesforce/user/isGuest';

const MESSAGE_TYPE_COUNTRY_SWITCH = 'countrySwitch'; //RWPS-3145 end
export default class Ecom_siteNotificationBanner extends LightningElement {
  @api showForLoggedIn; // DEPRECATED PROPERTIES - DO NOT USE
  @api showForPunchout; // DEPRECATED PROPERTIES - DO NOT USE
  @api showForGuest; // DEPRECATED PROPERTIES - DO NOT USE
  @api overrideValue; // DEPRECATED PROPERTIES - DO NOT USE

  @api bannerCodes='';
  @api fallback;

  @api cancellable;
  @api bannerTheme;
  @api permanentScroll=false;

  bannerClosed = false;
  bannerOpened = false;
  scrollBanner = 'no';
  windowWidth = window.innerWidth;

  //RWPS-3145
  bannerMsg = false;

  @wire(MessageContext)
  messageContext;

  expandBanner = (resize=false) => {
    if(this.bannerClosed || !this.bannerMsg) {
      return;
    }

    if(!resize) {
      this.bannerOpened = true;
      this.refs.bannerTextRegion.innerHTML = this.bannerMsg;
    }

    this.refs.bannerOuter.style.height = this.refs.heightRef.clientHeight + 'px';

    let textWidth = this.refs.bannerTextRegion.clientWidth
    if(this.permanentScroll || (this.refs.bannerTextWidthRef.clientWidth < textWidth)) {
      this.scrollBanner = 'yes';
      this.refs.bannerTextRegion.style.animationDuration = parseInt(textWidth / 40) + 's';
    } else {
      this.scrollBanner = 'no';
    }
  }

  closeBanner = () => {
    this.bannerClosed = true;
    this.refs.bannerOuter.style.height = null;
  }

  // RWPS-3826 START
  closeBannerEnter = (event) => {
    if(event.key === 'Enter' || event.keyCode === 13 || event.key === 'Space' || event.keyCode === 32) { // RWPS-4086
      this.closeBanner();
    }
  }
  // RWPS-3826 END

  resizeBanner = () => {
    if(this.bannerClosed || !this.bannerOpened) {
      return;
    }
    let newWidth = window.innerWidth;
    if(this.windowWidth != newWidth) {
      this.windowWidth = newWidth;
      this.expandBanner(true);
    }
  }

  connectedCallback() {
    window.addEventListener('resize', this.resizeBanner);

    this.handleMessageChannelSubscription();
  }
   //RWPS-3145 start
  handleMessageChannelSubscription(){
    this.subscription = subscribe(this.messageContext, ECOM_MESSAGE, (message) => this.handleReceivedMessage(message));
  }

      //process message
  async handleReceivedMessage(payload){
    if(payload && payload.type && payload.type != '' && payload.type != null && payload.type != undefined && payload.type == MESSAGE_TYPE_COUNTRY_SWITCH) {
      const item = payload.localeData;
      if(!item || !item.countryCode) {
        return;
      }

      let finalBannerCodes = this.bannerCodes ? this.bannerCodes.split(',').map(e=>e.trim()) : [];
      if(this.fallback) {
        finalBannerCodes.push('generic');
      }
      if(!finalBannerCodes.length) {
        return;
      }

      let bannerData;
      if(isGuest) {
        bannerData =
          await getCountriesBannerMsgGuest({
            country: item.countryCode,
            bannerCodes: finalBannerCodes
          })
      } else {
        bannerData =
          await getCountriesBannerMsgLoggedin({
            bannerCodes: finalBannerCodes
          })
      }

      if(bannerData) {
        let bannerDataFound = false;
        for(let bannerCode of finalBannerCodes) {
          let message = bannerData[bannerCode];
          if(message) {
            this.bannerMsg = message;
            bannerDataFound = true;
            break;
          }
        }

        if(bannerDataFound) {
          setTimeout(this.expandBanner, 1000);
        }
      }
    }
  }
//RWPS-3145 End
}