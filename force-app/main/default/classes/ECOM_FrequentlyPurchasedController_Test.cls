/**************************************************************

* 1. Jira Ticket(s) that relates to this class

* 2. Description - This class is a test class.

* 3. Objects referenced

*    - Account

*    - SAP_Order_Summary__c

*    - Network

*    - Wishlist

*    - WishlistItem

*.   - User

* 4. Callouts to additional Components (including their methods) or None:

*    - None

* 5. Dependant Class(es):

*    - ECOM_TestUtil

*    - classes called from test class

* 6. Test Class Name:

*    -None

* 7. Is @Invocable : No

*

* 8. Author Name(s):
*    - Manoj 2023.09.19
*    - Poonam 2026.03.03 Updated method getFrequentlyPurchasedProductForLoggedInUserTest, getFrequentlyBoughtProductsForUserEmailTest - RWPS-5777
*************************************************************/
@isTest
public class ECOM_FrequentlyPurchasedController_Test {
    
    @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
    }
    
    @isTest
    static void getFrequentlyPurchasedProductForLoggedInUserTest(){
        //RWPS-5507 - Start
        User testUser = [Select Id, Email, contactId, AccountId, ECOM_Is_Punchout_User__c From User ORDER BY CREATEDDATE DESC LIMIT 1];//RWPS-5777
        testUser.ECOM_Is_Punchout_User__c = true;
        update testUser;
        System.runAs(new User(Id=UserInfo.getUserId())) {
            List<Contact> contactList = [SELECT Id, Default_Ship_to_ERP_Address__r.Master_Address__c FROM Contact WHERE Id =: testUser.ContactId LIMIT 1];//RWPS-5777
            if (contactList.isEmpty() == false) {
                 string erpAddressId = contactList[0].Default_Ship_to_ERP_Address__r.Master_Address__c;//RWPS-5777 start
                 List<ERP_Address__c> addressList = [ SELECT Id FROM ERP_Address__c WHERE Id = :erpAddressId LIMIT 1];
                if (!addressList.isEmpty()) {
                    Punchout_Maintenance__c pmRec = new Punchout_Maintenance__c(
                    ERP_Address__c = addressList[0].Id
                );
                insert pmRec;
                List<Punchout_Maintenance__c> pmList = [SELECT Id, ERP_Address__c, Ecom_Punchout_Additional_Email_Address__c,ECOM_Punchout_User_Email__c FROM Punchout_Maintenance__c WHERE ERP_Address__c = :addressList[0].Id LIMIT 1];
                if (!pmList.isEmpty()) {
                    pmList[0].ECOM_Punchout_User_Email__c = ECOM_Constant.SHIP_TO_CONTACT_EMAIL_BOTH;
                    pmList[0].Ecom_Punchout_Additional_Email_Address__c = testUser.Email + ', email1@example.com, extra2@example.com';
                    update pmList[0];
                }//RWPS-5777 end
                }
            }
        }
        System.runAs(testUser) {
            SAP_Order_Summary__c orderSummary = new SAP_Order_Summary__c();
            orderSummary.Order_Number__c= 2243;
            orderSummary.typeOrder__c = 'SP';
            orderSummary.ShipTo_Email__c = testUser.Email;
            orderSummary.Contact_Email__c = testUser.Email;
            orderSummary.Source_Type__c = 'ZEDI';
            orderSummary.PO_Type__c = 'INET';
            insert orderSummary;
            SAP_Order_Items__c orderItem = new SAP_Order_Items__c();
            orderItem.Line_Item_Number_Web__c = '1';
            orderItem.PKI_Order_Summary__c = orderSummary.Id;
            orderItem.isRemoved__c = false;
            orderItem.Quantity_Ordered__c = 10.00;
        	insert orderItem;
            //RWPS-5507 - End
            Test.startTest();
            // Call the method to test
            Map<String, Object> result = ECOM_FrequentlyPurchasedController.getFrequentlyPurchasedProductForLoggedInUser();
            Test.stopTest();
            System.assertnotEquals(null,result,'expected order should not be null');
        }
    }
    
    @isTest
    static void removeWishListItemTest(){
        
        User testUser = [Select Id,LastName,accountId From User ORDER BY CREATEDDATE DESC LIMIT 1];
        WishlistItem wishlistitem = [Select Id,Name From WishlistItem ORDER BY CREATEDDATE DESC LIMIT 1];
        Network comm = [SELECT Id, name FROM Network ORDER BY CREATEDDATE DESC limit 1]; 
        String communityId = (String)comm.Id;
        String accountId=testUser.accountId;
        String wishListItemId = 'wishlistitem.Id';
        
        System.runAs(testUser) {
            Test.startTest();
            // Call the method to test
            Map<String, Object> result = ECOM_FrequentlyPurchasedController.removeWishListItem(wishListItemId);
            result.put('Test', ECOM_FrequentlyPurchasedController.addWishListItem(communityId, '','', accountId));
            Test.stopTest();
            
            System.assertnotEquals(null,result,'expected order should not be null');
        }
    }

    @isTest
    static void getFrequentlyBoughtProductsForUserEmailTest(){
        User testUser = [Select Id,LastName, Email From User ORDER BY CREATEDDATE DESC LIMIT 1];//RWPS-5777
        String userEmail = testUser.Email;//RWPS-5777
        Account ac = [SELECT Id FROM Account WHERE Name = 'TestClass Account'];
        String accountId = ac.Id;//RWPS-5777
        System.runAs(testUser) {
            Test.startTest();
            // Call the method to test
            Set<String> result = ECOM_FrequentlyPurchasedController.getFrequentlyBoughtProductsForUserEmail(userEmail,accountId);
            Test.stopTest();
            System.assertnotEquals(null,result,'expected order should not be null');
        }
    }
    
    @isTest
    static void addWishListTest(){
        User testUser = [Select Id,LastName,accountId From User ORDER BY CREATEDDATE DESC LIMIT 1];
        String accountId=testUser.accountId;
        Network comm = [SELECT Id, name FROM Network ORDER BY CREATEDDATE DESC limit 1]; 
        Wishlist wishlist =  [Select Id,Name from Wishlist ORDER BY CREATEDDATE DESC LIMIT 1];
        WishlistItem wishlistitem = [Select Id,Name,Product2Id From WishlistItem ORDER BY CREATEDDATE DESC LIMIT 1];
        String communityId = (String)comm.Id;
        string productId=wishlistitem.Product2Id;
        //ECOM_TestUtil.createWishlist(accountId,webStoreId, userId);
        String wishListId=wishlist.Id;
        Test.startTest();
        Map<String,Object> result= ECOM_FrequentlyPurchasedController.addWishListItem(communityId, wishListId,productId, accountId);
        Test.stopTest();
        System.assertnotEquals(null,result,'Expected result');
    }
}