// Abhishek 2025.04.28 - RWPS-3124 Created the component.

import { api, LightningElement, track } from 'lwc'; // RWPS-3493
import { trackViewProduct, trackAddProductToCart } from 'commerce/activitiesApi';
import { ANCHOR_TYPES } from 'commerce/recommendationsApi'; // RWPS-3493

const readyMessage = {type: 'einstein-tracking', subtype: 'ready'}

export default class Ecom_commerceEinsteinTracket extends LightningElement {
  @api logData; // RWPS-3003
  @api enableRecommendations;
  // RWPS-3493 start
  @api maxRecs = 20;

  @track availableRecs = {};
  recsData = {};
  productContextRecommenders = ['similar-products', 'customers-who-bought-also-bought'];

  get recsIterator() {
    return Object.keys(this.availableRecs).map(key => {
      return this.availableRecs[key];
    });
  }
  // RWPS-3493 end

  connectedCallback() {
    // RWPS-3003 start
    if(this.logData) {
      console.log('Einstein tracking component initialized');
    }
    // RWPS-3003 end

    window.addEventListener('message', this.receiveMsg.bind(this));
    if(window.parent) {
      window.parent.postMessage(readyMessage, '*');
    }
  }
  disconnectedCallback() {
    window.removeEventListener('message', this.receiveMsg);
  }

  receiveMsg(event) {
    let {data} = event;

    if(data?.type == 'einstein-tracking') {
      // RWPS-3003 start
      if(this.logData) {
        console.log('Einstein tracking data received', event);
      }
      // RWPS-3003 end

      if(data?.subtype == 'productView') {
        trackViewProduct({ id: data.productId, sku: data.productPartNumber });
      } else if(data?.subtype == 'addToCart' && data.items && data.items.length) {
        data.items.forEach(item => {
          trackAddProductToCart(
            {
              id: item.productId,
              sku: item.productPartNumber,
              quantity: item.quantity,
              price: item.contractPrice ? item.contractPrice : '', // RWPS-3003
              originalPrice: item.listPrice
            }
          );
        })
      } else if(window.parent !== window && data?.subtype == 'ready') { // RWPS-3003
        window.parent.postMessage(readyMessage, '*');
      } else {
        return;
      }
    }
    // RWPS-3493 start
    else if(this.enableRecommendations && data?.type == 'einstein-recommendation') {
      if(this.logData) {
        console.log('Einstein recommender request received', event);
      }

      if(!data.subtype) {
        return;
      }

      let recKey = data.subtype + (data.ref ? ('-' + data.ref.join('-')) : '');

      if(this.availableRecs[recKey]) {
        if(this.recsData[recKey]) {
          this.sendRecs(recKey);
        }
        return;
      }

      this.availableRecs = {
        ...this.availableRecs,
        [recKey]: {
          subtype: data.subtype,
          salesOrg: data.salesOrg ? data.salesOrg : null, // RWPS-3697
          key: recKey,
          ref: data.ref ? data.ref : undefined,
          anchorType: this.getAnchorType(data.subtype)
        }
      }
      return;
    } else {
      return;
    }
  }

  sendRecs(recKey) {
    let message = JSON.parse(JSON.stringify({
      type: 'einstein-recommendation-response',
      ...this.availableRecs[recKey],
      ...this.recsData[recKey]
    }))

    window.parent.postMessage(message, '*');

    if(this.logData) {
      console.log('Einstein recommendation data emitted', message);
    }
  }

  getAnchorType(recommender) {
    if(this.productContextRecommenders.includes(recommender)) {
      return ANCHOR_TYPES.PRODUCT;
    }
    return ANCHOR_TYPES.NO_CONTEXT;
  }

  handleRecoLoad(e) {
    let recKey = e.detail.recKey;
    let recData = {
      data: e.detail.data?.map(el=>el.Part_Number__c),
      recoUUID: e.detail.recoUUID
    }
    this.recsData[recKey] = recData;
    this.sendRecs(recKey);
  }
  // RWPS-3493 end
}