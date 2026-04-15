/**************************************************************

	* 1. Jira Ticket(s) that relates to this class
	*  
	*
	* 2. Description - This is a test class
	*
	* 3. Objects referenced
	*    - User
	*    - product
	*	 

	* 4. Callouts to additional Components (including their methods) or None:
	*    - None
	*
	* 5. Dependant Class(es):
	*    - ECOM_TestUtil
	 
	* 6. Test Class Name:
	*
	* 7. Is @Invocable : No
	*
	* 8. Author Name(s):
	*    - Manojkumar 2023.09.17
	*************************************************************/
@isTest(SeeAllData=false)
public class ECOM_WishListItemModel_Test {
    @isTest
    static void testWishListItemModel() {
        // Create test data using ECOM_TestUtil
        Product2 testProduct = ECOM_TestUtil.createProduct('Test Product', '123456', 'TEST123', true);
        ConnectApi.WishlistItemCollection testData = ECOM_TestUtil.itemCollectionData();

        // Create an instance of ECOM_WishListItemModel
        ECOM_WishListItemModel item = new ECOM_WishListItemModel();
        item.wishListItemId = testData.items[0].wishlistItemId;
        item.productId = testProduct.Id;
        item.productName = testProduct.Name;

        // Verify the data
        System.assertEquals(testData.items[0].wishlistItemId, item.wishListItemId);
        System.assertEquals(testProduct.Id, item.productId);
        System.assertEquals(testProduct.Name, item.productName);
            }
    }

    // @isTest
    // static void testCreateProduct() {
    //     // Create a test Product using the utility method
    //     Product2 testProduct = ECOM_TestUtil.createProduct('Test Product', '123456', 'TEST123', true);
        
    //     // Retrieve the product from the database
    //     Product2 retrievedProduct = [SELECT Name, ProductCode, IsActive, Part_Number__c FROM Product2 WHERE Id = :testProduct.Id];
        
    //     // Verify that the created product matches the expected values
    //     System.assertEquals('Test Product', retrievedProduct.Name);
    //     System.assertEquals('123456', retrievedProduct.Part_Number__c);
    //     System.assertEquals('TEST123', retrievedProduct.ProductCode);
    //     System.assertEquals(true, retrievedProduct.IsActive);
    // }