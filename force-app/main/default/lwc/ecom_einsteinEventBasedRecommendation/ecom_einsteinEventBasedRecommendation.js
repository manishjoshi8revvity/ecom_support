import { api, LightningElement, wire } from 'lwc';
import { ProductRecommendationsAdapter } from 'commerce/recommendationsApi';
import getSellableProducts from '@salesforce/apex/ECOM_CartController.getSellableProducts';
import communityId from '@salesforce/community/Id';

export default class Ecom_einsteinEventBasedRecommendation extends LightningElement {
  @api recommenderName;
  @api anchorType;
  @api anchorValue;
  @api maxCount = 20;
  @api recKey;
  @api salesOrg; // RWPS-3697

  @wire(ProductRecommendationsAdapter, {
    recommenderName: '$recommenderName',
    anchorType: '$anchorType',
    anchorValue: '$anchorValue'
  })
  async loadRecommendations(response) {
      let { data, error } = response;

      if (data && data.recoUUID && data.products && data.products.length > 0) {
        this.recoUUID = data.recoUUID;

        let productIds = data.products.map(el => el.id);
        let allowedProducts = await getSellableProducts({productIds, communityId, salesOrg: this.salesOrg ? this.salesOrg : null}); // RWPS-3697
        if(allowedProducts && allowedProducts.length) {
          let allowedProductIds = {};
          allowedProducts.forEach(el => {
            allowedProductIds[el.Product__c] = true;
          });
          let maxCount = parseInt(this.maxCount);
          maxCount = isNaN(maxCount) ? 20 : maxCount;

          this.dispatchEvent(
            new CustomEvent('recoload', {
              detail: {
                data:
                  data.products
                    .filter(r => allowedProductIds[r.id])
                    .filter((r, i) => i < maxCount)
                    .map(r => ({...r.fields, Id: r.id})),
                recoUUID: data.recoUUID,
                recKey: this.recKey
              }
            })
          );
        }
      } else if(error) {
        console.log('einstein: ' + error);
      }
    }
}