import { api, LightningElement, wire } from 'lwc';
import {publish, MessageContext} from 'lightning/messageService';

import encodeUrlParams from '@salesforce/apex/ECOM_UserController.getEncyrptedSessionParametersForCMS';
import LBL_URL_PATH_SEPARATOR from '@salesforce/label/c.ECOM_UrlPathSeparator';
import LBL_CMS_PARAM_PREFIX  from '@salesforce/label/c.ECOM_CMSPunchoutLoginParameter';
import ECOM_105105 from '@salesforce/label/c.ECOM_105105';
import ECOM_AddToCart  from '@salesforce/label/c.ECOM_AddToCart';
import ECOM_MESSAGE from '@salesforce/messageChannel/ecom_MessagingChannel__c';
import ECOM_AddedToCartSuccessfully from '@salesforce/label/c.ECOM_AddedToCartSuccessfully';
import addItemsToCart from '@salesforce/apex/ECOM_OrderHistoryController.addItemsToCart';
import { trackAddProductToCart } from 'commerce/activitiesApi';
import communityId from '@salesforce/community/Id';

import discontinuedText from "@salesforce/label/c.ECOM_Replacement_Popup_Discontinued_Text";
import replacementText from "@salesforce/label/c.ECOM_Replacement_Popup_Replacement_Text";
import replacementAlternativeText from "@salesforce/label/c.ECOM_Recommended_alternatives";//RWPS-4777

import { getUserConfigData } from 'c/ecom_punchoutUtil';

const NAVIGATE_TO_PDP = 'PDP';
const CMS_NAVIGATION = 'CMSNavigation';

export default class Ecom_popupProductCarousel extends LightningElement {
  @wire(MessageContext)
      messageContext;

  @api parentRect = {};
  @api products = [];
  @api pricing = {};
  @api effectiveAccountId;

  @api isFocused() {
    let el = this.template.activeElement;
    if(el) {
      return this.template.contains(el);
    }
    return false;
  }

  @api togglePopup(toggle) {
    if(toggle) {
      this.refs.popupParent?.classList.remove('popup-fadeout');
      this.refs.popupParent?.classList.add('popup-fadein');
    } else {
      this.refs.popupParent?.classList.add('popup-fadeout');
      this.refs.popupParent?.classList.remove('popup-fadein');
    }
  }

  LABELS = {
    discontinuedText,
    replacementText,
    replacementAlternativeText //RWPS-4777
  }

  labels = {
    ECOM_AddToCart
  }

  showSpinner = false;

  currentSlide = 1;

  leftControlDisabled = true;
  rightControlDisabled = false;

  get showSlider() {
    return this.products.length > 1;
  }

  get productData() {
    return this.products.map((product, idx) => {
      return {
        ...product,
        price: this.pricing[product.Part_Number__c] ? this.pricing[product.Part_Number__c] : false,
        tabIndex: idx + 1 == this.currentSlide ? '0' : '-1'
      };
    })
  }

  get topParentStyle() {
    let popupWidth = 500;
    let minPointerClearance = 17;
    let leftRightClearance = 16;

    let parentLeft = this.parentRect.left || 100;
    let parentWidth = this.parentRect.width || 16;

    let popupLeft = (parentWidth / 2) - 40;

    let screenWidth = this.windowWidth;

    if(screenWidth < popupWidth) {
      popupLeft = parentLeft * (-1);
      popupWidth = screenWidth;
    } else {
      let leftSpace = parentLeft + popupLeft;
      let rightSpace = screenWidth - (parentLeft + popupLeft + popupWidth);

      let minimumClearanceExists = screenWidth > popupWidth + (2 * (leftRightClearance + minPointerClearance));

      if(leftSpace < 0 || rightSpace < 0) {
        popupLeft = -1 * (parentLeft - (minimumClearanceExists ? leftRightClearance : 0));
      }
    }

    let pointerLeft = this.getPointerLeft(parentWidth, popupLeft, popupWidth, minPointerClearance);

    return [
      `--popup-width: ${popupWidth}px;`,
      `--popup-left: ${popupLeft}px;`,
      `--pointer-left: ${pointerLeft}px;`
    ].join(' ');
  }

  getPointerLeft(parentWidth, popupLeft, popupWidth, minPointerClearance) {
    let maxRightClearance = popupWidth - minPointerClearance;

    let pointerLeft = (parentWidth / 2) - popupLeft;
    if(pointerLeft < minPointerClearance) {
      pointerLeft = minPointerClearance;
    } else if(pointerLeft > maxRightClearance) {
      pointerLeft = maxRightClearance;
    }
    return pointerLeft;
  }

  get carouselTranslate() {
    return `transform: translateX(-${(this.currentSlide - 1) * 100}%);`
  }

  windowWidth = document?.body?.clientWidth ? document.body.clientWidth : (window.innerWidth < window.outerWidth ? window.innerWidth : window.outerWidth);
  resizeTimeout;

  #resizeCallback;
  connectedCallback() {
    this.#resizeCallback = this.resizeCallback.bind(this);
    window.addEventListener('resize', this.#resizeCallback);
  }

  disconnectedCallback() {
    window.removeEventListener('resize', this.#resizeCallback);
  }

  resizeCallback() {
    clearTimeout(this.resizeTimeout);
    this.resizeTimeout = setTimeout(() => {
      this.windowWidth = document?.body?.clientWidth ? document.body.clientWidth : (window.innerWidth < window.outerWidth ? window.innerWidth : window.outerWidth);

      this.dispatchEvent(new CustomEvent('requestnewrect', {
        detail: {}
      }))
    }, 1000);
  }

  handleNext() {
    if (this.currentSlide < this.products.length) {
      this.currentSlide++;

      this.leftControlDisabled = false;

      if (this.currentSlide === this.products.length) {
        this.rightControlDisabled = true;
      }
    }
  }

  handlePrevious() {
    if (this.currentSlide > 1) {
      this.currentSlide--;

      this.rightControlDisabled = false;

      if (this.currentSlide === 1) {
        this.leftControlDisabled = true;
      }
    }
  }

  navigateToPDP(event) {
    event.target?.focus();

    let displayURL = event.target.dataset.url;

    if(!displayURL) {
      return;
    }

    let payLoad = {message: NAVIGATE_TO_PDP,
        type: CMS_NAVIGATION,
        partNumber: '',
        url: displayURL
    };

    let userConfig = getUserConfigData();

    if(userConfig && userConfig.isPunchoutUser){
        let urlParams = '';
        encodeUrlParams().then(result => {
            if(result && result?.success && result?.responseData){
                let baseUrl = result.Home ;
                //RWPS-1817
                if(result.locale && result.locale != ''){
                    if (baseUrl.substr(-1) != '/'){
                        baseUrl += LBL_URL_PATH_SEPARATOR;
                    }
                    baseUrl = baseUrl +  result.locale;
                }
                urlParams = result.responseData;
                window.location.href = baseUrl + displayURL + LBL_CMS_PARAM_PREFIX + urlParams;//Remove after DEV
            } else {
                publish(this.messageContext, ECOM_MESSAGE, payLoad);
            }
        }).catch(error => {
        });
    }else {
        publish(this.messageContext, ECOM_MESSAGE, payLoad);
    }
  }

  message;
  messageType;
  showMsg;
  showMessage(message,type,show){
    this.message = message;
    this.messageType = type;
    this.showMsg = show;

    if(show) {
      clearTimeout(this.messageTimeout);
      this.messageTimeout = setTimeout(() => {
        this.closeMessageBox();
      }, 5000)
    }
  }

  closeMessageBox(){
    this.showMessage('', '', false);
  }

  orderItemsList = [];
  handleAddToCart(event) {
    event.target?.focus();

    if(this.showSpinner) {
        return;
    }

    this.orderItemsList = [];
    this.showSpinner = true;
    let prodId = event.currentTarget.dataset.id;
    let partNumber = event.currentTarget.dataset.pn;
    this.orderItemsList.push({Product2Id: prodId, Quantity: 1});

    addItemsToCart({
        communityId: communityId,
        effectiveAccountId: this.effectiveAccountId,
        cartItems: this.orderItemsList
    }).then((result) => {
        if(result.itemsAddedSuccessfully[0] == prodId) {
            this.showMessage(
                ECOM_AddedToCartSuccessfully,
                'success',
                true
            );
            trackAddProductToCart({
                id: prodId,
                sku: partNumber,
                quantity: 1,
                price: '',
            });
        }
        else{
            this.showMessage(
                ECOM_105105,
                'error',
                true
            );
        }

        let payLoad = {message:1,
            type: 'CartRefresh'
        };
        publish(this.messageContext, ECOM_MESSAGE, payLoad);
        this.showSpinner = false;
    }).catch((error) => {
        this.showSpinner = false;
        console.log(error);
        this.showMessage(
            ECOM_105105,
            'error',
            true
        );
    });
  }

  handleFocusOut() {
    this.dispatchEvent(new CustomEvent('popupfocusout', {
      detail: {}
    }));
  }
}