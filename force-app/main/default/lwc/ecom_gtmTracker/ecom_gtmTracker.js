import { LightningElement,wire,api } from 'lwc';
import ECOM_DATALAYERCHANNEL from '@salesforce/messageChannel/ecom_DataLayer__c';
import { subscribe, MessageContext } from 'lightning/messageService';
import { CartSummaryAdapter } from 'commerce/cartApi';
import { loadScript } from 'lightning/platformResourceLoader';
import ssrc_ECOM_Theme from '@salesforce/resourceUrl/ssrc_ECOM_Theme';
import getDataLayerDataByCart from '@salesforce/apex/ECOM_DataLayerController.getDataLayerDataByCart';
import FirstName from '@salesforce/schema/User.FirstName';
import LastName from '@salesforce/schema/User.LastName';
import IsMappedField from '@salesforce/schema/User.Contact.ECOM_Is_Mapped__c';
import CountryField from '@salesforce/schema/User.Country';
import CreatedDateField from '@salesforce/schema/User.CreatedDate';
import AccountIdField from '@salesforce/schema/User.Account.Id';
import AccountNameField from '@salesforce/schema/User.Account.Name';
import { getRecord } from 'lightning/uiRecordApi';
import userId from "@salesforce/user/Id";
import ECOM_Add_to_Cart from '@salesforce/label/c.ECOM_Add_To_Cart_CTA';//RWPS-3835

export default class Ecom_gtmTracker extends LightningElement {
    //RWPS-3835 - start
    labels = {
        ECOM_Add_to_Cart
    }
     //RWPS-3835 - End
    scriptLoaded = false;
    dataLayerSubscription = null;
    cartId;
    userdataInfo;
    @wire(MessageContext)
    messageContext;   
    connectedCallback() {
        if(!this.scriptLoaded){
            Promise.all([
                loadScript(this, ssrc_ECOM_Theme + '/js/gtm.js'),
                
            ]).then(() => {
                this.scriptLoaded = true;
                this.subscribeDataLayerEvent();


            });
        }
    }
    
    @wire(CartSummaryAdapter, { cartStateOrId: 'current' })
    getCartSummary(result) {
        if (result && result.data && result.data.cartId ) {

            this.cartId = result.data.cartId;
        }  
    }

    @wire(getRecord, {recordId: userId,fields: [FirstName, LastName,AccountIdField,AccountNameField,IsMappedField,CountryField,CreatedDateField]}) accountRecord({ error, data }) {
        if (data) {
            this.userdataInfo=data;
            this.userName = data?.fields?.FirstName?.value + ' '+data?.fields?.LastName?.value;
        }
    }

    subscribeDataLayerEvent() {
        if (this.dataLayerSubscription) {
            return;
        }
        this.dataLayerSubscription = subscribe(this.messageContext, ECOM_DATALAYERCHANNEL, (message) => {
            if(message?.type=== 'DataLayer' && (message?.page=== 'cart' || message?.page=== 'checkout' || message?.page=== 'favourites' || message?.page=== 'Order Details' || message?.page=== 'My Account')){
                let data = message?.data ; 
                let finalData={...data};
                    finalData.userInfo = {
                        ecomUserType : this.userdataInfo?.fields?.Contact?.value?.fields?.ECOM_Is_Mapped__c?.value==true? 'Mapped':'Unmapped',
                        sfdcEcomUserId : userId,
                        sfdcEcomCountry:this.userdataInfo?.fields?.Country?.value|| undefined,
                        isLoggedIn:true,
                        companyName:this.userdataInfo?.fields?.Account?.value?.fields?.Name?.value || undefined,
                        accountId:this.userdataInfo?.fields?.Account?.value?.fields?.Id?.value || undefined,
                        creationDate:this.userdataInfo?.fields?.CreatedDate?.value|| undefined
                        
                    }
                
                revvityGTM.pushData(finalData);
            }else{
                this.getCurrentCartData(message.data);
            }
        });
    }
   

    getCurrentCartData(data) {
        getDataLayerDataByCart({cartId: this.cartId})
        .then((result) => {
            // RWPS-3835 - START
            let finalData;
            // Check if addToCartLocation is missing or empty
            const isAddToCartLocationMissing = data.some(item =>
                !('addToCartLocation' in item) || item.addToCartLocation == null || item.addToCartLocation === ''
            );

            // Common userInfo object
            const userInfo = {
                ecomUserType: this.userdataInfo?.fields?.Contact?.value?.fields?.ECOM_Is_Mapped__c?.value === true ? 'Mapped' : 'Unmapped',
                sfdcEcomUserId: userId,
                sfdcEcomCountry: this.userdataInfo?.fields?.Country?.value || undefined,
                isLoggedIn: true,
                companyName: this.userdataInfo?.fields?.Account?.value?.fields?.Name?.value || undefined,
                accountId: this.userdataInfo?.fields?.Account?.value?.fields?.Id?.value || undefined,
                creationDate: this.userdataInfo?.fields?.CreatedDate?.value || undefined
            };

            if (isAddToCartLocationMissing) {
                finalData = {
                    event: 'add_to_cart',
                    addToCartLocation: 'Quick Order - ' + this.labels.ECOM_Add_to_Cart, // RWPS-3835
                    userInfo,
                    items: [],
                    _clear: true
                };
            } else {
                finalData = {
                    event: 'add_to_cart',
                    addToCartLocation: data[0]?.addToCartLocation, // RWPS-3835
                    userInfo,
                    items: [],
                    _clear: true
                };
            }

            for(let i=0; i<data.length; i++){
                let partNum=data[i].PartNumber;
                for (const property in result.dataLayer) {
                    if(result.dataLayer[property].partNumber==partNum ){
                        finalData.items.push({
                        'name': result.dataLayer[property].name|| undefined,
                        'partNumber':[data[i].PartNumber] || undefined,
                        'paccode': result.dataLayer[property].paccode +'-'+result.dataLayer[property].igorDescription|| undefined,
                        'businessUnit': result.dataLayer[property].superBussinessUnit+'-'+ result.dataLayer[property].subBussinessUnit|| undefined,
                        'portfolioLevel2':result.dataLayer[property].portfolioLevel2 || undefined,
                        'productLine':  result.dataLayer[property].productLine+'-'+result.dataLayer[property].productLineName || undefined,
                        'productClass':result.dataLayer[property].productClass || undefined,
                        'productBrand':result.dataLayer[property].productClass || undefined,
                        'sapStatus': result?.productSalesStatus[result.dataLayer[property].id] || undefined,
                        'quantity':  data[i].quantity || undefined,
                        'hasImage': false,
                        'price': result.dataLayer[property].price|| undefined ,
                        'listPrice': result.dataLayer[property].listPrice || undefined,
                        'currency': result.dataLayer[property].currencyCode || undefined
                        });                      
                    }
                }
            }
            // RWPS-3835 - END
            
        revvityGTM.pushData(finalData);

        }).catch((error) => {
                //console.log(' error occured during datalayer data preparatio for quickorder',error);
        });
    }

}