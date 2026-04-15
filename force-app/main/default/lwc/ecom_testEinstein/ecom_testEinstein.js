import { LightningElement, api, wire } from 'lwc';
import { ProductRecommendationsAdapter, ANCHOR_TYPES } from 'commerce/recommendationsApi';
import { trackViewProduct } from 'commerce/activitiesApi';

export default class Ecom_testEinstein extends LightningElement {
  @api products = [];
  @api products2 = [];
  currentSlide = 1;
  maxSlide = 0;
  showLeft = 0;
  showRight = 0;

  recommenderName = 'customers-who-bought-also-bought';
  anchorType = ANCHOR_TYPES.PRODUCT;
  anchorValue = ['01tHs000008kcI6IAI'];

  @wire(ProductRecommendationsAdapter, {
      recommenderName: '$recommenderName',
      anchorType: '$anchorType',
      anchorValue: '$anchorValue',
  })
  async loadRecommendation(response) {
      console.log(JSON.stringify(response));
      trackViewProduct({ id: '01tHs000008kc9cIAA' });
      let { data, error } = response;

      if (data && data.recoUUID && data.products && data.products.length > 0) {
          this.products = data.products;
          this.recoUUID = data.recoUUID;

          this.maxSlide = Math.ceil(data.products.length / 3);
          if(this.maxSlide>1) {
            this.showRight = 1;
          }

          console.log('einstein: ',this.products);
      } else if (error) {
          // unable to load recommendation, handle accordingly
          this.products = { data: [] };
          console.log('einstein: ' + error);
      }
  }

  adjustSlide() {
    this.refs.flex.style.transform = `translateX(-${(this.currentSlide - 1) * 100}%)`;
  }

  handleLeft() {
    if(this.currentSlide > 1) {
      this.currentSlide = this.currentSlide - 1;
      if(this.currentSlide == 1) {
        this.showLeft = 0;
      } else {
        this.showLeft = 1;
      }
      this.showRight = 1;
    }
    this.adjustSlide();
  }

  handleRight() {
    if(this.currentSlide < this.maxSlide) {
      this.currentSlide = this.currentSlide + 1;
      if(this.currentSlide == this.maxSlide) {
        this.showRight = 0;
      } else {
        this.showRight = 1;
      }
      this.showLeft = 1;
    }
    this.adjustSlide();
  }

  // @wire(ProductRecommendationsAdapter, {
  //     recommenderName: 'top-selling',
  //     anchorType: ANCHOR_TYPES.NO_CONTEXT,
  //     anchorValue: null,
  // })
  // async loadRecommendation2(response) {
  //     // console.log(JSON.stringify(response));
  //     trackViewProduct({ id: '01tHs000008kn1wIAA' });
  //     let { data, error } = response;

  //     if (data && data.recoUUID && data.products && data.products.length > 0) {
  //         this.products2 = data.products;
  //         this.recoUUID = data.recoUUID;

  //         console.log('einstein1: ',this.products2);
  //     } else if (error) {
  //         // unable to load recommendation, handle accordingly
  //         this.products2 = { data: [] };
  //         console.log('einstein: ' + error);
  //     }
  // }
}