/**************************************************************

	* 1. Jira Ticket(s) that relates to this class
	*  
	*
	* 2. Description - This class is a test class for ECOM_CartItemModel
					 - this class pass the test data to each method of the main class(ECOM_CartItemModel ) and test the functionality
	*
	* 3. Objects referenced
	
	* 4. Callouts to additional Components (including their methods) or None:
	*    - None
	*
	* 5. Dependant Class(es):
	* 6. Test Class Name:
	*
	* 7. Is @Invocable : No
	*
	* 8. Author Name(s):
	*    - Mayank 2023.09.19
*************************************************************/
@isTest
public class ECOM_CartItemModel_Test {

    @isTest
    static void testParseMethod() {
        // Create a JSON string to use for testing
        String json = '{'+
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

        // Call the parse method and test its behavior
        Test.startTest();
        ECOM_CartItemModel result = ECOM_CartItemModel.parse(json);
        Test.stopTest();

        // Assert that the result is not null, indicating successful parsing
        System.assertNotEquals(null, result);
    }
    @isTest
    public static void testTestParse()
    {
        Test.startTest();
        User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(u)
        {
        	ECOM_CartItemModel result = ECOM_CartItemModel.testParse();	
         	System.assertNotEquals(null, result);
        }
        
    }
}