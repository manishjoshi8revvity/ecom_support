import { LightningElement, api, track, wire } from 'lwc';

import getWishlistSummaries from '@salesforce/apex/ECOM_FavoritesController.getWishlistSummaries';
import getRecentlyPurchasedProducts from '@salesforce/apex/ECOM_OrderController.getRecentlyPurchasedProducts';
import getCustomersAlsoBought from '@salesforce/apex/ECOM_ProductRecommendationsController.getCustomersAlsoBought'; //RWPS-4437
import getContractPrice from '@salesforce/apex/ECOM_CartController.getContractPrice';
import communityId from '@salesforce/community/Id';
import contextApi from 'commerce/contextApi';

export default class Ecom_productRecommendations extends LightningElement {
  @api recommendationsToShow = '';
  @api recommendationTitles = '';

  // RWPS-4437 start
  @api maxCount = 6;

  _baseProductIds
  @api
  get baseProductIds() {
    return this._baseProductIds;
  }
  set baseProductIds(value) {
    this._baseProductIds = value;
    this.executeRecommendations();
  }
  // RWPS-4437 end

  effectiveAccountId = null;
  productObject = 'Product2';
  enableComponent = true;
  componentLoading = true;
  @track recommendationsData = [];

  recommendationMap = {
    favorites: this.getWishlistSummary,
    recentlyOrdered: this.getRecentlyOrdered,
    customersAlsoBought: this.getCustomersAlsoBoughtRecs //RWPS-4437
  }
  pricingData;

  connectedCallback() {
    const result = contextApi.getSessionContext();
    result.then((response) => {
      this.effectiveAccountId = response.effectiveAccountId;
      if(this.effectiveAccountId) {
        this.executeRecommendations();
      } else {
        this.disableComponent();
      }
    }).catch((error) => {
        this.disableComponent();
    });
  }

  async executeRecommendations() {
    let recommendationParams = this.recommendationsToShow.split(',').map(e => e.trim());
    let finalRecommendations = [];

    recommendationParams.forEach((rec) => {
      if(this.recommendationMap[rec]) {
        let method = this.recommendationMap[rec].bind(this);
        finalRecommendations.push(method());
      }
    });

    if(finalRecommendations.length == 0) {
      this.disableComponent();
      return;
    }

    try {
      let allProductData = await Promise.all(finalRecommendations);
      let allProductDataFlat = allProductData.flat();
      if(allProductDataFlat.length == 0) {
        this.disableComponent();
        return;
      }

      let titles = this.recommendationTitles.split(';');

      let finalData = [];
      allProductData.forEach((e, i) => {
        if(e.length) {
          finalData.push({title: titles[i] ? titles[i] : false, data: e, key: 'productRec' + i})
        }
      })

      this.recommendationsData = finalData;
      this.componentLoading = false;

      // RWPS-4437 start
      let productsForContractPrice = allProductDataFlat;
      let pricingBkp = {};
      if(this.pricingData) {
        productsForContractPrice = [];
        allProductDataFlat.forEach(p=>{
          if(this.pricingData[p.Part_Number__c]) {
            pricingBkp[p.Part_Number__c] = this.pricingData[p.Part_Number__c];
          } else {
            productsForContractPrice.push(p);
          }
        });
      }

      if(productsForContractPrice.length) {
        let contractPriceData = await getContractPrice({products: productsForContractPrice});
        if(contractPriceData.Product_list) {
          let pricingDataTemp = {};
          contractPriceData.Product_list.forEach(p=>{
            pricingDataTemp[p.part_number] = p;
          });
          this.pricingData = {...pricingBkp, ...pricingDataTemp};
        }
      }
      // RWPS-4437 end
      return;
    } catch (error) {
      console.log(error);
      this.disableComponent();
      return;
    }
  }

  disableComponent() {
    this.enableComponent = false;
  }

  // RWPS-4437 start
  favoritesLoaded = false;
  favoritesValue = [];
  // RWPS-4437 end
  getWishListPromise(resolve, reject) {
    // RWPS-4437 start
    if(this.favoritesLoaded) {
      resolve(this.favoritesValue);
      return;
    }

    this.favoritesLoaded = true;
    this.favoritesValue = [];
    // RWPS-4437 end

    getWishlistSummaries({
      communityId: communityId,
      effectiveAccountId: this.effectiveAccountId,
      productFields: ['ECOM_Product_Media_URI__c', 'Product_Display_Name__c', 'DisplayUrl', 'Part_Number__c', 'Dangerous_Goods_Indicator_Profile__c', 'Name'],
      objectName: this.productObject
    })
      .then((result)=>{
        if(result.Status === 'Success' && result?.favItems?.length && result?.pricingResult?.pricingLineItemResults.length) {
          let productsOverview = result?.productsOverview.products;
          let finalProductsOverview = [];

          let productsOverviewList = result?.productsOverviewList;

          if(productsOverviewList.length > 0){
            for (let i = 0; i < productsOverviewList.length; i++) {
              finalProductsOverview.push(...productsOverviewList[i].products);
            }
          }
          else{
            finalProductsOverview = productsOverview;
          }

          let allFavItems = result?.favItems;
          let finalFavs = [];
          for(let i in allFavItems){
            let favItem = [allFavItems[i]];

            let productRecord = favItem.map(obj => finalProductsOverview.find(o => o.id === obj.Product2Id) || obj);
            if(productRecord.length == 0) {
              continue;
            }

            let excluded = false;
            excluded = result?.excludedProdStatusMap && result?.excludedProdStatusMap.hasOwnProperty(productRecord[0].id) ? result?.excludedProdStatusMap[productRecord[0].id] : false;

            if(!excluded && result?.productSaleStatus && result?.productSaleStatus.hasOwnProperty(productRecord[0].id) && result?.productSaleStatus[productRecord[0].id]) {

              let productData = productRecord[0]?.fields;

              if(productData) {
                productData.Id = productRecord[0].id
                finalFavs.push(productData);
              }
            }
          }

          if(finalFavs.length) {
            this.favoritesValue = finalFavs; // RWPS-4437
            resolve(finalFavs);
            return;
          } else {
            resolve([]);
            return;
          }
        } else {
          resolve([]);
          return;
        }
      })
      .catch((error)=>{
        console.log(error);
        resolve([]);
        return;
      })
  }

  getWishlistSummary() {
    return new Promise(this.getWishListPromise.bind(this))
  }

  // RWPS-4437 start
  recentlyOrderedLoaded = false;
  recentlyOrderedValue;
  // RWPS-4437 end
  getRecentlyOrderedPromise(resolve, reject) {
    // RWPS-4437 start
    if(this.recentlyOrderedLoaded) {
      resolve(this.recentlyOrderedValue);
      return;
    }
    this.recentlyOrderedLoaded = true;
    this.recentlyOrderedValue = [];
    // RWPS-4437 end

    getRecentlyPurchasedProducts({communityId: communityId})
      .then(result => {
        if(result.success) {
          let productArray = [];
          result.products?.forEach(product => {
            let productObj = product.Product__r;
            // RWPS-2969 start
            if(productObj) {
              productArray.push({...productObj});
            }
            // RWPS-2969 end
          })
          this.recentlyOrderedValue = productArray; // RWPS-4437
          resolve(productArray);
          return;
        } else {
          resolve([]);
          return;
        }
      })
      .catch((error) => {
        console.log(error);
        resolve([]);
        return;
      })
  }

  getRecentlyOrdered() {
    return new Promise(this.getRecentlyOrderedPromise.bind(this))
  }

  // RWPS-4437 start
  customersAlsoBoughtData = {
    '': []
  };

  getCustomersAlsoBoughtPromise(resolve, reject) {
    let baseProductIdArray = [];

    if(this.baseProductIds) {
      baseProductIdArray = [...this.baseProductIds];
    }

    let key = baseProductIdArray.sort().join('-');
    if(this.customersAlsoBoughtData[key]) {
      resolve(this.customersAlsoBoughtData[key]);
      return;
    }

    let returnArr = [];

    getCustomersAlsoBought({
      productIds: baseProductIdArray,
      communityId: communityId,
      configuration: {
        maxRecs: this.maxCount
      }
    }).then(result => {
      if(result.sellableRecommendations) {
        result.sellableRecommendations.forEach(rec => {
          if(result.productIdMap && result.productIdMap[rec]) {
            returnArr.push(result.productIdMap[rec]);
          }
        });
      }
      return;
    }).catch((error) => {
      console.log(error);
      return;
    }).finally(() => {
      this.customersAlsoBoughtData[key] = returnArr;
      resolve(returnArr);
    })
  }

  getCustomersAlsoBoughtRecs() {
    return new Promise(this.getCustomersAlsoBoughtPromise.bind(this));
  }
  // RWPS-4437 end
}