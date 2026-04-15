import { LightningElement, api, wire } from 'lwc';
import { ProductRecommendationsAdapter, ANCHOR_TYPES } from 'commerce/recommendationsApi';
import { trackViewReco } from 'commerce/activitiesApi';
import getSellableProducts from '@salesforce/apex/ECOM_CartController.getSellableProducts';
import getContractPrice from '@salesforce/apex/ECOM_CartController.getContractPrice';
import communityId from '@salesforce/community/Id';

export default class Ecom_einsteinRecommendations extends LightningElement {
  productContextRecommenders = ['similar-products', 'customers-who-bought-also-bought'];

  products;
  pricing;
  recoUUID;

  @api heading = '';
  @api recommenderName;
  @api maxCount = 6;

  _anchorValue = undefined;
  @api
  get anchorValue() {
    return this._anchorValue;
  }
  set anchorValue(value) {
    if(value && this.productContextRecommenders.includes(this.recommenderName)) {
      if(Array.isArray(value)) {
        this._anchorValue = [...value];
      } else {
        this._anchorValue = [value];
      }
    }
  }

  _anchorType;
  @api
  get anchorType() {
    if(this._anchorType) {
      return this._anchorType;
    } else if(this.productContextRecommenders.includes(this.recommenderName)) {
      return ANCHOR_TYPES.PRODUCT;
    }
    return ANCHOR_TYPES.NO_CONTEXT;
  }
  set anchorType(value) {
    if(value) {
      this._anchorType = value;
    }
  }

  @wire(ProductRecommendationsAdapter, {
      recommenderName: '$recommenderName',
      anchorType: '$anchorType',
      anchorValue: '$anchorValue',
  })
  async loadRecommendations(response) {
    let { data, error } = response;

    if (data && data.recoUUID && data.products && data.products.length > 0) {
      this.recoUUID = data.recoUUID;

      let productIds = data.products.map(el => el.id);
      let allowedProducts = await getSellableProducts({productIds, communityId});
      if(allowedProducts && allowedProducts.length) {
        let allowedProductIds = {};
        allowedProducts.forEach(el => {
          allowedProductIds[el.Product__c] = true;
        });
        let maxCount = parseInt(this.maxCount);
        maxCount = isNaN(maxCount) ? 6 : maxCount;
        let finalProducts =
        data.products
          .filter(r => allowedProductIds[r.id])
          .filter((r, i) => i < maxCount)
          .map(r => ({...r.fields, Id: r.id}));

        this.products = finalProducts;

        this.sendViewReco();
        try {
          this.requestContractPrice(finalProducts);
        } catch (error) {
          console.error('Error fetching contract prices: ', error);
        }
      }
    } else if(error) {
      console.log('einstein: ' + error);
    }
  }

  async requestContractPrice(productData) {
    let contractPrice = await getContractPrice({products: productData});
    let tempPricing = {};
    if(contractPrice && contractPrice.Product_list?.length) {
      contractPrice.Product_list.forEach(p => {
        tempPricing[p.part_number] = {...p};
      });

      this.pricing = {...tempPricing};
    }
  }

  sendViewReco() {
    trackViewReco(
        this.recommenderName,
        this.recoUUID,
        this.products.map((product) => {
            return {
                id: product.Id,
                sku: product.Part_Number__c,
            };
        })
    );
  }
}