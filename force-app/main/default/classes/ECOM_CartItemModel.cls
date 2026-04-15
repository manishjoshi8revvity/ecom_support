/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM -  
*
* 2. Description - This class is used for initializing CartItem object and getting request and returning response.
*					- This class use a custom JSON To send request and fetch the response
					- return deserialize value of serialized or parsed json
* 3. Objects referenced
*    - CartItem
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
*
* 5. Dependant Class(es):
*    - used in SUB_FLOW_4496_ECOM_Cart_Operations flow
*    - ECOM_CartFlowWrapper
*    - ECOM_CartModel
*    - ECOM_CartService
*    - ECOm_CartUtil
*
* 6. Test Class Name: 
*    - ECOM_CartItemModel_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Manoj kumar 2023.08.02
*    - Sidak 2024.09.19 Added type. Ticket - RWPS-1401
*************************************************************/
public with sharing class ECOM_CartItemModel {
    
    @auraEnabled public String cartItemId;
    @auraEnabled public String cartItemName;
    @auraEnabled public String productId;
    @auraEnabled public String quantity;
    @auraEnabled public String type; //RWPS-1401
    @auraEnabled public String currencyIsoCode;
    @auraEnabled public String itemizedAdjustmentAmount;
    @auraEnabled public String listPrice; 
    @auraEnabled public String salesPrice;
    @auraEnabled public String totalAdjustmentAmount;
    @auraEnabled public String totalAmount;
    @auraEnabled public String totalListPrice;
    @auraEnabled public String totalPrice;
    @auraEnabled public String totalTax;
    @auraEnabled public String unitAdjustedPrice;
    @auraEnabled public String unitAdjustmentAmount;
    @auraEnabled public String thumbnailImageURL;


	@AuraEnabled public CartItems[] cartItems;
	@AuraEnabled public boolean hasErrors;
	public class CartItems {
		@AuraEnabled public CartItem cartItem;
		@AuraEnabled public String status;	//Success
	}
	public class CartItem {
		@AuraEnabled public String cartId;	//0a6DW0000008Q7JYAU
		@AuraEnabled public String cartItemId;	//0a9DW0000008PURYA2
		@AuraEnabled public String currencyIsoCode;	//USD
		@AuraEnabled public String itemizedAdjustmentAmount;	//0.00
		@AuraEnabled public String listPrice;	//1093.95
		@AuraEnabled public String name;	//INSTA-GEL PL / 2x5 L
		@AuraEnabled public String productId;	//01tDW000009ckIgYAI
		@AuraEnabled public String quantity;	//127
		@AuraEnabled public String salesPrice;	//1093.95
		@AuraEnabled public String totalAdjustmentAmount;	//0.00
		@AuraEnabled public String totalAmount;	//138942.65
		@AuraEnabled public String totalListPrice;	//0.00
		@AuraEnabled public String totalPrice;	//138931.65
		@AuraEnabled public String totalTax;	//11.00
		@AuraEnabled public String type;	//Product
		@AuraEnabled public String unitAdjustedPrice;	//1093.95
		@AuraEnabled public String unitAdjustmentAmount;	//0.00
	}

	public static ECOM_CartItemModel parse(String json){
		return (ECOM_CartItemModel) System.JSON.deserialize(json, ECOM_CartItemModel.class);
	}

	public static ECOM_CartItemModel testParse() {
		String json=		'{'+
		'    "cartItems": ['+
		'        {'+
		'            "cartItem": {'+
		'                "cartId": "0a6DW0000008Q7JYAU",'+
		'                "cartItemId": "0a9DW0000008PURYA2",'+
		'                "currencyIsoCode": "USD",'+
		'                "itemizedAdjustmentAmount": "0.00",'+
		'                "listPrice": "1093.95",'+
		'                "messagesSummary": {'+
		'                    "errorCount": null,'+
		'                    "hasErrors": null,'+
		'                    "limitedMessages": [],'+
		'                    "relatedEntityId": null,'+
		'                    "totalLineItemsWithErrors": null'+
		'                },'+
		'                "name": "INSTA-GEL PL / 2x5 L",'+
		'                "productDetails": {'+
		'                    "fields": {'+
		'                        "Part_Number__c": "6013399",'+
		'                        "Unit_of_Measure_Code__c": null,'+
		'                        "Dangerous_Goods_Indicator_Profile__c": null,'+
		'                        "Name": "INSTA-GEL PL / 2x5 L"'+
		'                    },'+
		'                    "name": "INSTA-GEL PL / 2x5 L",'+
		'                    "productId": "01tDW000009ckIgYAI",'+
		'                    "purchaseQuantityRule": null,'+
		'                    "sku": "6013399",'+
		'                    "thumbnailImage": {'+
		'                        "alternateText": "",'+
		'                        "contentVersionId": null,'+
		'                        "id": null,'+
		'                        "mediaType": "Image",'+
		'                        "sortOrder": 0,'+
		'                        "thumbnailUrl": null,'+
		'                        "title": "image",'+
		'                        "url": "/img/b2b/default-product-image.svg"'+
		'                    },'+
		'                    "variationAttributes": {}'+
		'                },'+
		'                "productId": "01tDW000009ckIgYAI",'+
		'                "quantity": "127",'+
		'                "salesPrice": "1093.95",'+
		'                "totalAdjustmentAmount": "0.00",'+
		'                "totalAmount": "138942.65",'+
		'                "totalListPrice": "0.00",'+
		'                "totalPrice": "138931.65",'+
		'                "totalTax": "11.00",'+
		'                "type": "Product",'+
		'                "unitAdjustedPrice": "1093.95",'+
		'                "unitAdjustmentAmount": "0.00"'+
		'            },'+
		'            "message": null,'+
		'            "status": "Success"'+
		'        },'+
		'        {'+
		'            "cartItem": {'+
		'                "cartId": "0a6DW0000008Q7JYAU",'+
		'                "cartItemId": "0a9DW0000008PUHYA2",'+
		'                "currencyIsoCode": "USD",'+
		'                "itemizedAdjustmentAmount": "0.00",'+
		'                "listPrice": "595.24",'+
		'                "messagesSummary": {'+
		'                    "errorCount": null,'+
		'                    "hasErrors": null,'+
		'                    "limitedMessages": [],'+
		'                    "relatedEntityId": null,'+
		'                    "totalLineItemsWithErrors": null'+
		'                },'+
		'                "name": "VIEWPLATE-96 F TC /50x1B",'+
		'                "productDetails": {'+
		'                    "fields": {'+
		'                        "Part_Number__c": "6005182",'+
		'                        "Unit_of_Measure_Code__c": null,'+
		'                        "Dangerous_Goods_Indicator_Profile__c": null,'+
		'                        "Name": "VIEWPLATE-96 F TC /50x1B"'+
		'                    },'+
		'                    "name": "VIEWPLATE-96 F TC /50x1B",'+
		'                    "productId": "01tDW000009ck9XYAQ",'+
		'                    "purchaseQuantityRule": null,'+
		'                    "sku": "6005182",'+
		'                    "thumbnailImage": {'+
		'                        "alternateText": "",'+
		'                        "contentVersionId": null,'+
		'                        "id": null,'+
		'                        "mediaType": "Image",'+
		'                        "sortOrder": 0,'+
		'                        "thumbnailUrl": null,'+
		'                        "title": "image",'+
		'                        "url": "/img/b2b/default-product-image.svg"'+
		'                    },'+
		'                    "variationAttributes": {}'+
		'                },'+
		'                "productId": "01tDW000009ck9XYAQ",'+
		'                "quantity": "11",'+
		'                "salesPrice": "595.24",'+
		'                "totalAdjustmentAmount": "0.00",'+
		'                "totalAmount": "6558.64",'+
		'                "totalListPrice": "0.00",'+
		'                "totalPrice": "6547.64",'+
		'                "totalTax": "11.00",'+
		'                "type": "Product",'+
		'                "unitAdjustedPrice": "595.24",'+
		'                "unitAdjustmentAmount": "0.00"'+
		'            },'+
		'            "message": null,'+
		'            "status": "Success"'+
		'        }'+
		'    ],'+
		'    "cartSummary": {'+
		'        "accountId": "001DW00001QB1jhYAD",'+
		'        "cartId": "0a6DW0000008Q7JYAU",'+
		'        "currencyIsoCode": "USD",'+
		'        "grandTotalAmount": "145501.29",'+
		'        "isSecondary": false,'+
		'        "messagesSummary": {'+
		'            "errorCount": 0,'+
		'            "hasErrors": false,'+
		'            "limitedMessages": [],'+
		'            "relatedEntityId": "0a6DW0000008Q7JYAU",'+
		'            "totalLineItemsWithErrors": 0'+
		'        },'+
		'        "name": "Cart",'+
		'        "ownerId": "005DW000009N3AlYAK",'+
		'        "purchaseOrderNumber": null,'+
		'        "status": "Active",'+
		'        "taxType": "Net",'+
		'        "totalChargeAmount": "0.00",'+
		'        "totalListPrice": "0.00",'+
		'        "totalProductAmount": "145479.29",'+
		'        "totalProductAmountAfterAdjustments": "145479.29",'+
		'        "totalProductCount": "138",'+
		'        "totalPromotionalAdjustmentAmount": "0.00",'+
		'        "totalTaxAmount": "22.00",'+
		'        "type": "Cart",'+
		'        "uniqueProductCount": 2,'+
		'        "webstoreId": "0ZEDW0000004Dfj4AE"'+
		'    },'+
		'    "currentPageToken": null,'+
		'    "currentPageUrl": null,'+
		'    "hasErrors": false,'+
		'    "nextPageToken": null,'+
		'    "nextPageUrl": null,'+
		'    "previousPageToken": null,'+
		'    "previousPageUrl": null'+
		'}';
		ECOM_CartItemModel obj = parse(json);
		System.assert(obj != null);
        return obj;
	}

}