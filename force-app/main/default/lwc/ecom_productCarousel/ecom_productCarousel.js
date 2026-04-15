import { LightningElement, api, wire } from 'lwc';
import { trackClickReco, trackAddProductToCart } from 'commerce/activitiesApi'; // RWPS-3003
import ViewDetailsCTA from "@salesforce/label/c.ECOM_Product_Carousel_View_Details_CTA";
import AddToCartCTA from "@salesforce/label/c.ECOM_Product_Carousel_Add_to_Cart_CTA";
import ECOM_AddedToCartSuccessfully from '@salesforce/label/c.ECOM_AddedToCartSuccessfully';
import ECOM_105105 from '@salesforce/label/c.ECOM_105105';
import ECOM_Add_to_Cart from '@salesforce/label/c.ECOM_Add_To_Cart_CTA';////RWPS-3835
import getCMSBaseUrl from '@salesforce/apex/ECOM_CartController.getCMSBaseUrl';
import addItemsToCart from '@salesforce/apex/ECOM_OrderHistoryController.addItemsToCart';
import communityId from '@salesforce/community/Id';
import contextApi from 'commerce/contextApi';
import {publish, MessageContext} from 'lightning/messageService';
import ECOM_MESSAGE from '@salesforce/messageChannel/ecom_MessagingChannel__c';
import ECOM_DATALAYERCHANNEL from '@salesforce/messageChannel/ecom_DataLayer__c';//RWPS-3835

export default class Ecom_productCarousel extends LightningElement {
  @wire(MessageContext)
  messageContext;

  @api title;
  @api pricing;

  @api mediumScreen = 1024;
  @api smallScreen = 400;

  @api recoUUID = ''; // RWPS-3003
  @api recommenderName = ''; // RWPS-3003

  messageStatus = false;
  message = '';
  messageType = '';
  messageTimeSpan = 0;

  pendingNavigation = false;

  effectiveAccountId

  currentSlide = 1;
  itemsPerSlide = this.getItemsPerSlide();

  leftStyle = 'opacity: 1;';
  rightStyle = 'opacity: 1;';

  numFormat = new Intl.NumberFormat('en-US', {minimumFractionDigits: 2, maximumFractionDigits: 2});

  _products;
  @api
  get products() {
    let data = JSON.parse(JSON.stringify(this._products));

    // RWPS-4086 start
    for (let i = 0; i < data.length; i++) {
      if(this.pricing && this.pricing[data[i].Part_Number__c]) { // RWPS-4437
        let temp = this.pricing[data[i].Part_Number__c];
        data[i].price = temp.currency + ' ' + this.numFormat.format(temp.price);
      }

      if(this.cmsBaseUrl) {
        data[i].DisplayUrl = this.cmsBaseUrl + data[i].DisplayUrl;
      }

      let currentLowRank = (this.currentSlide - 1) * this.itemsPerSlide;
      let currentHighRank = (this.currentSlide * this.itemsPerSlide) - 1;

      if(i >= currentLowRank && i <= currentHighRank) {
        data[i].tabindex = '0';
      } else {
        data[i].tabindex = '-1';
      }
    }
    // RWPS-4086 end

    return data;
  }

  set products(value) {
    let data = JSON.parse(JSON.stringify(value));

    for (let i = 0; i < data.length; i++) {
      data[i].Product_Display_Name__c = data[i].Product_Display_Name__c ? data[i].Product_Display_Name__c.replace(/&lt;/g, '<').replace(/&gt;/g, '>') : data[i].Name;
    }
    this._products = data;
  }

  get carouselState() {
    let totalItems = this._products?.length
    let state = {
      totalItems,
      totalSlides: Math.ceil(totalItems / this.itemsPerSlide),
      translate: `transform: translateX(-${(this.currentSlide - 1) * 100}%);`,
      enableControls: totalItems > this.itemsPerSlide,
      currentIndicator: Math.min((this.currentSlide * this.itemsPerSlide), totalItems),
      cardStyle: `width: calc(100% / ${this.itemsPerSlide}); min-width: calc(100% / ${this.itemsPerSlide});`
    }

    return state;
  }

  cmsBaseUrl = '';

  labels = {
    ViewDetailsCTA,
    AddToCartCTA,
    ECOM_AddedToCartSuccessfully,
    ECOM_105105,
    ECOM_Add_to_Cart//RWPS-3835
  }

  connectedCallback() {
    getCMSBaseUrl({
        moduleName:'SiteURL'
    }).then((result) => {
      let baseUrl = result?.Home || '';
      if(this.pendingNavigation) {
        window.location.href = baseUrl + this.pendingNavigation;
        return;
      }
      this.cmsBaseUrl = baseUrl;
    }).catch((error) => {
      console.log(error);
    });

    const result = contextApi.getSessionContext();
    result.then((response) => {
        this.effectiveAccountId = response.effectiveAccountId;
    }).catch((error) => {

    });

    this.itemsPerSlide = this.getItemsPerSlide();

    window.addEventListener('resize', this.manageResize.bind(this));
  }

  renderedCallback() {
    this.itemsPerSlide = this.getItemsPerSlide();
  }

  getItemsPerSlide() {
    let windowWidth = window.innerWidth;
    if(windowWidth > this.mediumScreen) {
      return 3;
    } else if (windowWidth > this.smallScreen) {
      return 2;
    }
    return 1;
  }

  carouselLeft() {
    if(this.currentSlide != 1) {
      let newSlide = this.currentSlide - 1;
      this.currentSlide = newSlide;

      if(newSlide == 1) {
        this.leftStyle = 'opacity: 0.7; cursor: not-allowed;';
      }
      this.rightStyle = 'opacity: 1;'; // RWPS-2969
    }
  }

  carouselRight() {
    if(this.currentSlide != this.carouselState.totalSlides) {
      let newSlide = this.currentSlide + 1;
      this.currentSlide = newSlide;

      if(newSlide == this.carouselState.totalSlides) {
        this.rightStyle = 'opacity: 0.7; cursor: not-allowed;';
      }
      this.leftStyle = 'opacity: 1;'; // RWPS-2969
    }
  }

  manageResize() {
    let perSlide = this.getItemsPerSlide();
    if(perSlide != this.itemsPerSlide) {
      this.itemsPerSlide = perSlide;
      this.currentSlide = 1;
    }
  }

  showMessage(message,type,show){
    this.message = message;
    this.messageType = type;
    this.messageStatus = show;

    let msgBox = this.refs.carouselMessageBox
    if(msgBox) {
      let top = msgBox.getBoundingClientRect().top;
      if(top < 80 && top > window.innerHeight) {
        msgBox.scrollIntoView();
      }
    }
  }

  handleUpdateMessage(event){
    this.message = '';
    this.messageType = '';
    this.messageStatus = event.detail.show;
  }

  handlePDPNavigation(event) {
    event.preventDefault();
    let target = event.currentTarget;

    // RWPS-3003 start
    if(target && this.recommenderName && this.recoUUID) {
      trackClickReco(this.recommenderName, this.recoUUID, {id: target.dataset.sfid, sku: target.dataset.sku});
    }
    // RWPS-3003 end

    let href = target?.href;
    if(!href) {
      return;
    }

    href = new URL(href).pathname.split('/').filter(el=>el.length).join('/');

    if(this.cmsBaseUrl) {
      let base = this.cmsBaseUrl.endsWith('/') ? this.cmsBaseUrl.slice(0, -1) : this.cmsBaseUrl;
      window.location.href = base + '/' + href;
    } else {
      this.pendingNavigation = href;
      this.refs.carouselOuter?.classList.add('loading');
    }
    return;
  }

  handleAddToCart(event) {
    if(this.refs.carouselOuter?.classList.contains('loading')) {
      return;
    }

    let target = event.currentTarget; // RWPS-3003
    let prodId = target.dataset.sfid; // RWPS-3003

    this.refs.carouselOuter?.classList.add('loading');
    let carouselOuter = this.refs.carouselOuter;

    let orderItems = [{Product2Id: prodId, Quantity: 1}]

    addItemsToCart({
        communityId: communityId,
        effectiveAccountId: this.effectiveAccountId,
        cartItems: orderItems
    })
      .then(result => {
        if(result.itemsAddedSuccessfully[0] == prodId){
          trackAddProductToCart({id: prodId, sku: target.dataset.sku, quantity: 1, price: target.dataset.pricing ? target.dataset.pricing : ''}); // RWPS-3003
          //RWPS-3835 start
          let addToCartLocationData = '';
          if(this.title) {
            addToCartLocationData= this.title + ' card -' + this.labels.ECOM_Add_to_Cart;;
          }
          let addToCartData =  [];
          addToCartData.push({
            event: 'add_to_cart',
            'addToCartLocation': addToCartLocationData,//RWPS-3835
            'PartNumber': target.dataset.sku,
            'Quantity': 1,
          });
          this.handlePublishMsg(addToCartData);
          //RWPS-3835 - END

          this.showMessage(
            this.labels.ECOM_AddedToCartSuccessfully,
            'success',
            true
          );
        } else {
          this.showMessage(
            this.labels.ECOM_105105,
            'error',
            true
          );
        }

        let payLoad = {
          message: 1,
          type: 'CartRefresh'
        };
        publish(this.messageContext, ECOM_MESSAGE, payLoad);
      })
      .catch(error=>{
        console.log(3,error);
        this.showMessage(
          this.labels.ECOM_105105,
          'error',
          true
        );
      }).finally(() => {
        carouselOuter.classList.remove('loading');
      })
  }
  //RWPS-START-3835
  prepareAddToCartDataLayerData(addToCartLocationData){
          let data =  {
              event: 'add_to_cart',
              'addToCartLocation': addToCartLocationData,//RWPS-3835
              'items': this.data,
               _clear:true
          }
      this.handlePublishMsg(data);
  }

  handlePublishMsg(data) {
        let payLoad = {
                    data: data,
                    type: 'DataLayer',
                    page:'Product Carousel'//RWPS-3835
        };
        publish(this.messageContext, ECOM_DATALAYERCHANNEL, payLoad);
    }
  //RWPS-START-3835

  // RWPS-4086 start
  handleAccessibilityButton(event) {
    if(event.key === 'Enter' || event.keyCode === 'Enter' || event.key === 'Space' || event.keyCode === 32) {
      event.target.click();
      event.preventDefault();
      event.stopPropagation();
    }
  }
  // RWPS-4086 end
}