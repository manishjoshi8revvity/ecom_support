import { LightningElement, api, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import ViewDetailsCTA from "@salesforce/label/c.ECOM_Product_Carousel_View_Details_CTA";
import AddToCartCTA from "@salesforce/label/c.ECOM_Product_Carousel_Add_to_Cart_CTA";
import ECOM_AddedToCartSuccessfully from '@salesforce/label/c.ECOM_AddedToCartSuccessfully';
import ECOM_105105 from '@salesforce/label/c.ECOM_105105';
import ECOM_Add_to_Cart from '@salesforce/label/c.ECOM_Add_To_Cart_CTA'; // RWPS-3835
import getCMSBaseUrl from '@salesforce/apex/ECOM_CartController.getCMSBaseUrl';
import getContractPrice from '@salesforce/apex/ECOM_CartController.getContractPrice';
import addItemsToCart from '@salesforce/apex/ECOM_OrderHistoryController.addItemsToCart';
import communityId from '@salesforce/community/Id';
import ECOM_MESSAGE from '@salesforce/messageChannel/ecom_MessagingChannel__c';
import ECOM_DATALAYERCHANNEL from '@salesforce/messageChannel/ecom_DataLayer__c'; 


export default class Ecom_replacementProductCarousel extends LightningElement {
  @wire(MessageContext)
  messageContext;

  @api title;
  @api pricing;
  @api mediumScreen = 767;
  @api isMobile = false;
  @api discontinuedReplacements;

  @api get products() {
    return this._products;
  }

  labels = {
    ViewDetailsCTA,
    AddToCartCTA,
    ECOM_AddedToCartSuccessfully,
    ECOM_105105,
    ECOM_Add_to_Cart
  }

  _products = [];
  carouselState = {
    translate: `transform: translateX(0px)`,
    left: 0,
    cardCount: 1, 
    cardWidth: 0,
    cardGap: 24, // Maintained for consistent spacing
    cardStyle: '',
    totalItems: 0,
    currentIndicator: 0,
    enableControls: false,
    maxTranslate: 0,
    isHovering: false
  }

  isInitialLoad = true;
  message = '';
  type = '';
  show = false;
  timeSpan = 5000;
  isLoggedInUser = false;
  isGuestUser = false;
  showSpinner = false;
  leftStyle;
  rightStyle;
  @api currencyCode;
    @api currencyDisplayAs;

    cmsBaseUrl = '';
    effectiveAccountId;
    @api pricedProducts = [];
  connectedCallback() {
    if (this._products?.length) {
        this.fetchContractPrices();
    }
    // getCMSBaseUrl({ moduleName: 'SiteURL' })
    //         .then((result) => {
    //             this.cmsBaseUrl = result?.Home || '';
    //         })
    //         .catch(console.error);
    }
    async fetchContractPrices() {
        try {
            const productRequest = this.products.map(p => ({
                ...p.fields,
                Id: p.Id
            }));

            const contractPrice = await getContractPrice({ products: productRequest });

            let pricingMap = {};
            if (contractPrice && contractPrice.Product_list?.length) {
                contractPrice.Product_list.forEach(p => {
                    pricingMap[p.part_number] = p.list_price;
                });
            }

            // attach price to each product
            this.pricedProducts = this.products.map(p => ({
                ...p,
                price: pricingMap[p.fields.Part_Number__c] || null
            }));
        } catch (error) {
            console.error('Error fetching contract prices:', error);
        }
    }
    get isDirectType() {
        return this.type === "direct";
    }

    get isAlternativeType() {
        return this.type === "alternatives";
    }
    get trackStyle() {
        return `transform: translateX(-${this.currentSlide * 100}%);`;
    }
     @api currentIndex = 1;

    get totalCount() {
        return this.pricedProducts?.length || 0;
    }

    get currentProduct() {
        return this.pricedProducts.length ? this.pricedProducts[this.currentIndex - 1] : {};
    }

    handleNext() {
        if (this.currentIndex < this.totalCount) {
            this.currentIndex++;
        }
    }
    
    handlePrev() {
        if (this.currentIndex > 1) {
            this.currentIndex--;
        }
    }

    handleViewDetails() {
        const evt = new CustomEvent('viewdetails', {
            detail: this.currentProduct
        });
        this.dispatchEvent(evt);
    }

    handleAddToCart() {
        const evt = new CustomEvent('addtocart', {
            detail: this.currentProduct
        });
        this.dispatchEvent(evt);
    }
  
 

//   checkUserAuth(){
//     contextApi.getUser().then((user) => {
//       this.isLoggedInUser = user && user.isLoggedIn;
//       this.isGuestUser = user && !user.isLoggedIn;
//     });
//   }

  set products(value) {
    console.log(value);
    let data = JSON.parse(JSON.stringify(value));

    for (let i = 0; i < data.length; i++) {
      data[i].fields.Product_Display_Name__c = data[i].fields.Product_Display_Name__c ? data[i].fields.Product_Display_Name__c.replace(/&lt;/g, '<').replace(/&gt;/g, '>') : data[i].Name;
    }
    this._products = data;
    console.log(data);
    const allProducts = data.map(prod => ({ part_number: prod.Part_Number__c }));
    // Fetch prices for all replacement products
    // getContractPrice({ products: allProducts })
    //     .then(result => {
    //         const priceMap = {};
    //         result?.Product_list?.forEach(p => {
    //             priceMap[p.part_number] = p.price;
    //         });

    //         // Map prices to each replacement product
    //         this._products = this._products.map(prod => ({
    //             ...prod,
    //             price: priceMap[prod.Part_Number__c] || prod.price || '—'
    //         }));
    //     })
    //     .catch(error => {
    //         console.error('Error fetching replacement prices', error);
    //     });
  }
//   set products(value) {
//     console.log('1');
//     if (!value) return;

//     // Deep copy
//     let data = JSON.parse(JSON.stringify(value));
//     this._products = data;

//     // Collect part numbers for all replacement products
//     const allProducts = data.map(prod => ({ part_number: prod.Part_Number__c }));

//     // Fetch prices for all replacement products
//     // getContractPrice({ products: allProducts })
//     //     .then(result => {
//     //         const priceMap = {};
//     //         result?.Product_list?.forEach(p => {
//     //             priceMap[p.part_number] = p.price;
//     //         });

//     //         // Map prices to each replacement product
//     //         this._products = this._products.map(prod => ({
//     //             ...prod,
//     //             price: priceMap[prod.Part_Number__c] || prod.price || '—'
//     //         }));
//     //     })
//     //     .catch(error => {
//     //         console.error('Error fetching replacement prices', error);
//     //     });
// }
  showMessage(message, type, show) {
    this.message = message;
    this.messageType = type;
    this.messageStatus = show;
  }
  handleUpdateMessage(event) {
    this.message = '';
    this.messageType = '';
    this.messageStatus = false;
  }
//   handlePDPNavigation(event) {
//     event.preventDefault();
//     let target = event.currentTarget;
//     let href = target?.href;
//     if (!href) return;

//     href = new URL(href).pathname.split('/').filter(el => el.length).join('/');
//     if (this.cmsBaseUrl) {
//         let base = this.cmsBaseUrl.endsWith('/') ? this.cmsBaseUrl.slice(0, -1) : this.cmsBaseUrl;
//         window.location.href = base + '/' + href;
//     }
// }

//     handleAddToCart(event) {
//         let target = event.currentTarget;
//         let prodId = target.dataset.sfid;

//         let orderItems = [{ Product2Id: prodId, Quantity: 1 }];

//         addItemsToCart({
//             communityId: communityId,
//             effectiveAccountId: this.effectiveAccountId,
//             cartItems: orderItems
//         })
//             .then(result => {
//                 if (result.itemsAddedSuccessfully[0] == prodId) {
//                     // Build data layer payload
//                     let addToCartLocationData = this.labels.ECOM_Add_to_Cart;
//                     let addToCartData = {
//                         event: 'add_to_cart',
//                         addToCartLocation: addToCartLocationData,
//                         PartNumber: target.dataset.sku,
//                         Quantity: 1
//                     };
//                     this.handlePublishMsg(addToCartData);

//                     this.showMessage(this.labels.ECOM_AddedToCartSuccessfully, 'success', true);
//                 } else {
//                     this.showMessage(this.labels.ECOM_105105, 'error', true);
//                 }

//                 // Refresh cart
//                 publish(this.messageContext, ECOM_MESSAGE, { message: 1, type: 'CartRefresh' });
//             })
//             .catch(error => {
//                 console.error(error);
//                 this.showMessage(this.labels.ECOM_105105, 'error', true);
//             });
//     }

//     handlePublishMsg(data) {
//         publish(this.messageContext, ECOM_DATALAYERCHANNEL, {
//             data: data,
//             type: 'DataLayer',
//             page: 'Replacement Carousel'
//         });
//     }

//     showMessage(message, type, show) {
//         // optional: wire this to a toast or inline message component
//         console.log('Show message:', message, type, show);
//     }
    }