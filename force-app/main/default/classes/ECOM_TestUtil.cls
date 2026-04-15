/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-RWPS-592
* 2. Description - This class is used to create test cases for ECOM_TestUtil
*
*
* 3. Objects referenced
*    -ContentDocumentLink
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*
* 6. Test Class Name: 
*    - ECOM_TestUtil_Test
*
* 7. Is @Invocable: No
*
* 8. Author Name(s):
*   - mkumar@rafter.one 14 Oct 2023
*    @last modified by  : Gaurav.Bhansali@revvity.com
*   - Manish.Joshi@revvity.com | 30 April 2024 added methods createContentVersion , createContentDocumentLink for ticket RWPS-592
*   - Manoj RWPS-1869 - Fixed test class for getShippingTime change
*   - Gaurav Bhansali 2025.01.15 - Added data for promotion and coupon - RWPS-2307
*   - Prabhat Kumar 2025.03.21 - Created method testReview, createUser to increase code coverage - RWPS-2830
*   - Prabhat Kumar 2025.03.21 - Created method testReview, updated createPortalUser, createUser to increase code coverage - RWPS-2683
*   - Gaurav Bhansali 2025.06.03 - Added data for promotion and coupon - RWPS-3283
*   - Manish Joshi 2025.06.03 - updated method initialStorefrontSetup with permission assignment - RWPS-3199
*   - Prabhat 2025.07.14 - Update createProductShippingTime to increase the code coverage. - RWPS-1603
*   - Sachin Vispute 2025.10.09 - Added 'createNonPunchoutUser' method, updated 'initialStorefrontSetup' method to create non-punchout user - RWPS-3772
*************************************************************/

@isTest
public without sharing class ECOM_TestUtil {
    public static final String USER_ALIAS ='test123';
    public static final String WISHLIST_NAME ='testwishlist';
    public static final String CONTACT_NAME ='TestFirst Contact';
    public static final String REVVITY_ACCOUNT ='Test Revvity Account';
    public static final String STORE_NAME = 'Revvity-eCom';
    public static final String STORE_CATALOG_NAME = 'Revvity Store Catalog';
    public static final String STORE_PARTNER_ENTITLEMENT_POLICY = 'All Access for Revvity-eCom';
    public static final String STORE_PRODUCT_CATEGORY_ALL_PRODUCTS =  'Products';
    public static final String PRICE_BOOK_STANDARD ='Standard Price Book';
    public static final String PRICE_BOOK_REVVITY ='Revvity Price Book';
    public static final String BUYER_GROUP_REVVITY ='Revvity Buyer Group';
    
    public static  Account portalAccount;
    public static  Contact portalContact;
    public static  User portalUser;
    public static  Product2 product;
    public static  WebCart revvityCart;
    public static  Order revvityOrder;
    
    public static User createSysAdminUser(){
        Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
        UserRole role = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        User adminUser = new User(
            UserRoleId = role.Id,
            ProfileId = profile1.Id,
            Username = System.now().millisecond() + 'admintest@test.com',
            Alias = 'admin',
            Email= System.now().millisecond() + 'admintest@test.com',
            EmailEncodingKey='UTF-8',
            Firstname='Admin',
            Lastname='Sys',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago'
        );
        insert adminUser;
        return adminUser;
        
    }
    //RWPS-2830 - Start
    @IsTest
    static void testReview(){
        testDataIntialSetup();
    }
     //RWPS-2830 - End
    
    public static void testDataIntialSetup() {
        Account acc = new Account();
        Contact con = new Contact();
        acc = ECOM_TestUtil.createAccount();
        con = ECOM_TestUtil.createContact(acc);
        Test.startTest(); 
        User portalUser = ECOM_TestUtil.createPortalUser(con);
        Test.stopTest();
    }    
    
    public static User createPortalUser(Contact con){
        Profile portalProfile = [SELECT Id FROM Profile WHERE Name = :ECOM_Constant.PROFILE_NAME Limit 1];
         UserRole role = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        Integer randomInt = System.now().millisecond(); 
        User portalUser = new User(Alias = USER_ALIAS, 
                                   Email = randomInt + 'test123@noemail.com',
                                   Emailencodingkey = 'UTF-8',
                                   Firstname = 'B2B',            
                                   Lastname = 'TestPortal', 
                                   Languagelocalekey ='en_US',
                                   Localesidkey ='en_US',
                                   Profileid = portalProfile.Id,
                                   Country= 'United States',
                                   IsActive = true,
                                   ContactId = con.Id,
                                   Timezonesidkey = 'America/Los_Angeles',
                                   Username = randomInt + 'test123@noemail.com');
        insert portalUser;
        return portalUser;
    }
    
    public static User createPOPortalUser(Contact con){
        Profile portalProfile = [SELECT Id FROM Profile WHERE Name = :ECOM_Constant.PROFILE_NAME Limit 1];
         UserRole role = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        Integer randomInt = System.now().millisecond(); 
        User portalUser = new User(Alias = USER_ALIAS, 
                                   Email = randomInt + 'testpo123@noemail.com',
                                   Emailencodingkey = 'UTF-8',
                                   Firstname = 'B2BPO',            
                                   Lastname = 'TestPortal', 
                                   Languagelocalekey ='en_US',
                                   Localesidkey ='en_US',
                                   Profileid = portalProfile.Id,
                                   Country= 'United States',
                                   IsActive = true,
                                   ContactId = con.Id,
                                   Timezonesidkey = 'America/Los_Angeles',
                                   Username = randomInt + 'testpo123@noemail.com',
                                   ECOM_Is_Punchout_User__c=true);
        insert portalUser;
        return portalUser;
    }
    
    public static Account createAccount(){
        Account acc = new Account(
            Name = REVVITY_ACCOUNT,
            Account_Domains__c='testDomain',
            RAD_Identifier__c = 'RAD',
            BillingStreet='121',
            BillingCity='NY',
            BillingState='Alaska',
            BillingCountry='United States',
            BillingPostalCode='234323',
            ShippingStreet='121',
            ShippingCity='NY',
            ShippingState='Alaska',
            ShippingPostalCode='234323',
            ShippingCountry='United States',
            SAP_Customer_Number_Formatted__c='123456',
            CurrencyISOCode = 'USD' //RWPS-3772
        );
        insert acc;
        return acc;
        
    }
    
    // Not Using Account Function
    // public static Account_Function__c createAccountFunction(String accID){
    //     Account_Function__c accFunction = new Account_Function__c();
    //     accFunction.Source_Account__c=accId;
    //     accFunction.SAP_Partner_Type__c='RG';
    //     accFunction.SAP_Source_Account_Number__c='12345';
    //     accFunction.SAP_Target_Account_Number__c='0004062757';
    //     accFunction.SAP_Sales_Org__c='org1';
    //     accFunction.Target_Account__c=accId;
        
    //     insert accFunction;
    //     return accFunction;
    // }

    /* this function has only different type. will be merging into one @mayank */

    // Not Using Account Function @Remove
    // public static Account_Function__c createAccountFunctionWE(String accID){
    //     Account_Function__c accFunction = new Account_Function__c();
    //     accFunction.Source_Account__c=accId;
    //     accFunction.SAP_Partner_Type__c='WE';
    //     accFunction.SAP_Source_Account_Number__c='0100064982';
    //     accFunction.SAP_Sales_Org__c='org1';
    //     accFunction.Target_Account__c=accId;
        
    //     insert accFunction;
    //     return accFunction;
    // }
    
    public static List<ECOM_Email_Preferences__c> createEmailpreferencesList(Account acc,Contact con){
        List<ECOM_Email_Preferences__c> eepList=new List<ECOM_Email_Preferences__c>();
        ECOM_Email_Preferences__c eep = new ECOM_Email_Preferences__c();
        eep.ECOM_Account__c=acc.Id;
        eep.ECOM_Contact__c=con.Id;
        eep.ECOM_Email__c='test@yopmail.com';
        eepList.add(eep);
        insert eepList;
        return eepList;
    }
    public static Contact createContact(Account acc){
        Contact con = new Contact();
        con.AccountId = acc.Id;
        con.firstName = 'TestFirst';
        con.lastName = 'Contact';
        //con.ECOM_DefaultBillToAccount__c=acc.Id; // Not using this
        con.ECOM_DefaultShipToAccount__c=acc.Id;
        con.ECOM_AddressRegistration__c = 'Select ST & BT';
        insert con;
        return con;
    }
    
    /**
* @description Create a test product
* @param Name
* @param ProductCode
* @param IsActive
* @return Product2
*/
    public static Product2 createProduct(String name, String partNumber, String productCode, Boolean isActive) {
        Product2 p1 = new Product2();
        p1.Name = name;
        p1.ProductCode = productCode;
        p1.IsActive = isActive;
        p1.Part_Number__C=partNumber;
        insert p1;
        return p1;
    }
    
    
    public static Wishlist createWishlist(String accountId,String webStoreId,String userId){
        WishList testWishList = new WishList();
        testWishList.AccountId=accountId;
        testWishList.Name=WISHLIST_NAME;
        testWishList.WebStoreId=webStoreId;
        testWishList.OwnerId= userId;
        
        insert testWishList;
        
        return testWishList;
        
    }
    
    public static WishlistItem createWishlistItem(String prodId,String wListId){
        WishlistItem testWishListItem = new WishlistItem();
        testWishListItem.Product2Id=prodId;
        testWishListItem.Name='testwishlistitem';
        testWishListItem.WishListId=wListId;
        
        insert testWishListItem;
        
        return testWishListItem;
        
    }
    /**
* @description Create a non standard pricebook
* @param Name
* @param Description
* @return PriceBook2
*/
    public static PriceBook2 createPriceBook(String name, String description) {
        PriceBook2 pb = new PriceBook2 (
            Name = name,
            Description = description,
            IsActive = true
        );
        insert pb;
        return pb;
    }
    
    /**
* @description Create the standard price book
* @return PriceBook2
*/
    public static PriceBook2 getStandardPriceBook() {
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        return standardPricebook;
    }
    
    /**
* @description Create a test PriceBookEntry record from a priceBook and product
* @param  Id priceBookId
* @param  Id productId
* @param  Decimal unitPrice
* @return PriceBookEntry
*/
    public static PriceBookEntry createPriceBookEntry(Id priceBookId, Id productId, Decimal unitPrice) {
        PriceBookEntry pbe = new PriceBookEntry();
        pbe.Pricebook2Id = priceBookId;
        pbe.Product2Id = productId;
        pbe.UnitPrice = unitPrice;
        pbe.IsActive = true;
        insert pbe;
        return pbe;
    }
    /*
* Method - createCase
* Params - String name, String family
* Return - Case
* Description - This method is used to insert test Case.
*/
    // public static Case createCase(String recordTypeId, ID subId, String accessFlag){
    //     Case cse = new Case();
    //     cse.Access_Flag__c = accessFlag;
    //     cse.RecordTypeId = recordTypeId;
    //     cse.Subscription__c = subId;
    //     return cse;
    // }
    
    /*
* Method - createCaseActivity
* Params - String name, String family
* Return - Case_Activity__c
* Description - This method is used to insert test Case.
*/
    // public static Case_Activity__c createCaseActivity(String status, boolean external, 
    //                                                   ID userId, ID caseID)
    // {
    //     Case_Activity__c cseAct = new Case_Activity__c();
    //     cseAct.Status__c = status;
    //     cseAct.External__c = external;
    //     cseAct.Assign_User__c = userId;
    //     cseAct.Case__c = caseID;
    //     return cseAct;
    // }
    
    /*
* Method - createCart
* Params - String accountId, Id webstoreId
* Return - WebCart
* Description - This method is used to insert WebCart.
*/
    public static WebCart createCart(String accountId ,String webstoreId){
        WebCart testwebcart = new WebCart();
        testWebCart.Name='Test Cart';
        testWebCart.WebStoreId=webstoreId;
        testWebCart.Status='Active';
        // testWebCart.cart_Type__c='Amend';
        testWebCart.AccountId=accountId;
        return testWebCart;
    }
    
    /*
* Method - createCartItems
* Params - String cartId, String cartDeliveryGroupId, String productId
* Return - Case_ActivcartItemity__c
* Description - This method is used to insert cartItem.
*/
    public static cartItem createCartItems(String cartId, String cartDeliveryGroupId,String productId ){
        
        CartItem cartItem = new CartItem(cartId = cartId, 
                                         Sku = 'SKU_Test1',
                                         Quantity = 2,
                                         Type = 'Product',
                                         Name = 'TestCartItem',
                                         CurrencyIsoCode = 'USD',
                                         Product2Id = productId,
                                         ListPrice = 2000.00,
                                         SalesPrice = 2000.00,
                                         CartDeliveryGroupId = cartDeliveryGroupId,
                                         ECOM_ShippingCode__c='17259'      
                                        );
        return cartItem;
    }
    
    /*
* Method - createContract
* Params - String accountId, String contactId
* Return - contract
* Description - This method is used to insert contract.
*/
    public static contract createContract(String accountId,String contactId){       
        contract contract = new contract();
        contract.AccountId= accountId;
        contract.Status= 'Draft';
        contract.ContractTerm= 12;
        contract.CustomerSignedId= contactId;
        contract.StartDate= date.newinstance(2020, 2, 1);
        return contract;
    }
    
    /*
* Method - createCartDeliveryGroup
* Params - String CartId, String deliveryMethodId
* Return - CartDeliveryGroup
* Description - This method is used to insert CartDeliveryGroup.
*/
    public static CartDeliveryGroup createCartDeliveryGroup(String cartId, String deliveryMethodId){
        CartDeliveryGroup cartDeliveryGroup = new CartDeliveryGroup(Name = 'Test Delivery',
                                                                    CartId = cartId,
                                                                    DeliverToName ='test Delivery',
                                                                    DesiredDeliveryDate = DateTime.now(),
                                                                    DeliveryMethodId = deliveryMethodId);
        return cartDeliveryGroup;
        
    }
    
    /*
* Method - createQuote
* Params - String webCartId
* Return - SBQQ__Quote__c
* Description - This method is used to insert Quote.
*/
    // public static SBQQ__Quote__c createQuote(String webCartId)
    // {
    //     SBQQ__Quote__c quote = new SBQQ__Quote__c();
    //     quote.Cart__c = webCartId;
    //     return quote;
    // }
    
    /*
* Method - createQuoteLine
* Params - String quoteId, String productId
* Return - SBQQ__QuoteLine__c
* Description - This method is used to insert Quote Line.
*/
    // public static SBQQ__QuoteLine__c createQuoteLine(String quoteId, String productId)
    // {
    //     SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
    //     quoteLine.SBQQ__Quote__c = quoteId;
    //     quoteLine.SBQQ__Product__c = productId;
    //     quoteLine.SBQQ__NetPrice__c = 125;
    //     return quoteLine;
    // }
    
    /*
* Method - createContactPointAddress
* Params - String accountId
* Return - ContactPointAddress
* Description - This method is used to insert ContactPointAddress.
*/
 // Not using Contact Point Addresses
    // public static ContactPointAddress insertContactPointAddress(String accountId,String type)
    // {
    //     ContactPointAddress cpa = new ContactPointAddress();
    //     cpa.Name = 'Test CPA';
    //     cpa.AddressType = Type;
    //     cpa.Street = 'TestStreet';
    //     cpa.City = 'TestCity';
    //     cpa.State = 'New York';
    //     cpa.Country = 'United States';
    //     cpa.PostalCode = '10013';
    //     cpa.IsDefault = true;
    //     cpa.ParentId = accountId;
    //     cpa.ECOM_Review_Status__c='New';
    //     cpa.SAP_Contact_ID__c='testCId123';
    //     insert cpa;
    //     return cpa;
    // }

    
    // Not using cpa
 
    // Updated By Ayyavarolla VinayKumar from here
    public static ProductCatalog prepareProductCatalog(String name) {
        ProductCatalog prodCatalog = new ProductCatalog();
        prodCatalog.Name = name;
        return prodCatalog;
    }
    public static WebStore prepareWebStore(String name) {
        WebStore webStr = new WebStore();
        webStr.Name = name;
        webStr.PricingStrategy = 'LowestPrice';
        
        //insert webStr;
        return webStr;
    }
    
    public static CommerceEntitlementPolicy prepareCommerceEntitlementPolicy(String name) {
        CommerceEntitlementPolicy commerceEntPolicy = new CommerceEntitlementPolicy(
            Name = name, Description = 'Test Description',
            CanViewProduct = true, CanViewPrice = true, IsActive = true
        );
        return commerceEntPolicy;
    }
    
    public static WebStoreCatalog prepareWebStoreCatalog(WebStore webStr, ProductCatalog prodCatalog) {
        WebStoreCatalog webCatalog = new WebStoreCatalog();
        webCatalog.SalesStoreId = webStr.Id;
        webCatalog.ProductCatalogId = prodCatalog.Id;
        return webCatalog;
    }
    
    public static List<ProductCategory> prepareProductCategory(List<String> catList, ProductCatalog prodCatalog) {
        List<ProductCategory> retCatList = new List<ProductCategory>();
        for (String str : catList) 
        {
            ProductCategory pc = new ProductCategory();
            pc.Name = str ;
            pc.CatalogId = prodCatalog.Id ;
            retCatList.add(pc);
        }
        return retCatList;
    }
    public static List<BuyerGroup> prepareBuyerGroup(List<String> buyerGroupList)
    {
        List<BuyerGroup> bgList = new List<BuyerGroup>();
        for (String strBuyerGroup : buyerGroupList) {
            BuyerGroup buyGrp = new BuyerGroup();
            buyGrp.Name = strBuyerGroup;
            bgList.add(buyGrp);
        }
        return bgList;
    }
    public static List<WebStoreBuyerGroup> prepareWebStoreBuyerGroup(List<BuyerGroup> bgList, WebStore webStr) {
        List<WebStoreBuyerGroup> retCatList = new List<WebStoreBuyerGroup>();
        for (BuyerGroup buyGrp : bgList) 
        {
            WebStoreBuyerGroup webStrBuyerGrp = new WebStoreBuyerGroup();
            webStrBuyerGrp.WebStoreId = webStr.Id;
            webStrBuyerGrp.BuyerGroupId = buyGrp.Id;
            retCatList.add(webStrBuyerGrp);
        }
        return retCatList;
    }
    
    public static List<CommerceEntitlementBuyerGroup> prepareCommerceEntitlementBuyerGroup(List<BuyerGroup> bgList, CommerceEntitlementPolicy commerceEntPolicy) {
        List<CommerceEntitlementBuyerGroup> retCatList = new List<CommerceEntitlementBuyerGroup>();
        for (BuyerGroup buyGrp : bgList) 
        {
            CommerceEntitlementBuyerGroup commerceEntBuyerGrp = new CommerceEntitlementBuyerGroup(
                PolicyId = commerceEntPolicy.Id,
                BuyerGroupId = buyGrp.Id
            );
            retCatList.add(commerceEntBuyerGrp);
        }
        return retCatList;
    }
    
    public static List<Pricebook2> createPriceBook(List<String> lstPriceBookName) { 
        List<Pricebook2> pbList = new List<Pricebook2>();
        for(String strPriceBookName : lstPriceBookName) 
        {
            Pricebook2 newPricebook = new Pricebook2();
            newPricebook.Name = strPriceBookName;
            newPricebook.ValidFrom = Datetime.now().addDays(-1) ;
            newPricebook.ValidTo = Datetime.now().addDays(100);
            newPricebook.IsActive = true;
            pbList.add(newPricebook);
        }
        return pbList;
    }
    
    public static List<BuyerGroupPricebook> createBuyerGroupPriceBook(List<BuyerGroup> bgList, List<Pricebook2> pbList) {
        List<BuyerGroupPricebook> bgppList = new List<BuyerGroupPricebook>();
        for (BuyerGroup bg : bgList) 
        {
            for (Pricebook2 pb : pbList) 
            {
                BuyerGroupPricebook bgp = new BuyerGroupPricebook();
                bgp.IsActive = true;
                bgp.BuyerGroupId = bg.Id ;
                bgp.Pricebook2Id = pb.Id ;
                bgppList.add(bgp);
            }
        }
        return bgppList;
    }
    
    public static List<BuyerGroupMember> createBuyerGroupMember(List<BuyerGroup> bgList, List<Account> accLst) {
        List<BuyerGroupMember> bgMemberList = new List<BuyerGroupMember>();
        for (BuyerGroup bg : bgList) 
        {
            for (Account acc : accLst) 
            {
                BuyerGroupMember bgm = new BuyerGroupMember();
                bgm.BuyerGroupId = bg.Id ;
                bgm.BuyerId = acc.Id ;
                bgMemberList.add(bgm);
            }
        }
        return bgMemberList;
    }
    
    public static Product2 createSimpleProduct() {
        
        Product2 simpleProduct = new Product2(
            IsActive = true,
            Name = 'CAS_TEST_Product', 
            Family = 'Standard Price',
            ProductCode = 'CAS_TEST',
            Part_Number__c = '1234567',
            StockKeepingUnit = 'CAS1'
            
        );
        return simpleProduct;
    }
    
    public static Product2 createShippingChargeProduct() {
        
        Product2 simpleProduct = new Product2(
            IsActive = true,
            Name = 'shippingChargeProduct2Name',
            Family = 'Shipping',
            ProductCode = '12345'
        );
        return simpleProduct;
    }
    
    public static List<PricebookEntry> createPriceBookEntriesForProducts(List<Product2> lstProducts)
    {
        List<PricebookEntry> pricebookLst = new List<PricebookEntry>();
        Pricebook2 pricebook = [SELECT Id,Name FROM Pricebook2 WHERE Name ='' LIMIT 1];
        if(lstProducts != null && lstProducts.size() > 0 && pricebook != null)
        {
            for(Product2 product : lstProducts)
            {
                PricebookEntry pricebookEntry = createPriceBookEntry(product.Id,pricebook.Id);
                pricebookLst.add(pricebookEntry);
            }
        }
        return pricebookLst;
    }
    public static PricebookEntry createPriceBookEntry(String productId, String pricebookId)
    {
        PricebookEntry pricebookEntry = new PricebookEntry();
        pricebookEntry.Product2Id = productId;
        pricebookEntry.Pricebook2Id = pricebookId;
        pricebookEntry.UnitPrice = 499;
        pricebookEntry.IsActive = true;
        return pricebookEntry;
    }
    
    public static Account createAccount(String name) {
        Account acc = new Account();
        acc.Name = name;
        acc.Type = 'Customer';
        acc.ShippingStreet = 'test';
        acc.ShippingCountry = 'United States';
        acc.ShippingState = 'Alabama';
        acc.ShippingPostalCode = '12345';
        acc.BillingStreet = 'test';
        acc.BillingCity = 'Cambridge';
        acc.BillingState = 'Alabama';
        acc.BillingCountry = 'United States';
        acc.CurrencyISOCode = 'USD'; //RWPS-3772
        //acc.apiCountry__c = 'USA';
        //acc.apiState__c = 'Alabama';
        return acc;
    }
    
    public static Contact createNewContact(Account acc)
    {
        Contact con = new Contact();
        con.FirstName = 'test';
        con.LastName = 'Contact';
        con.Email = 'test@test.com';
        con.AccountId = acc.Id;
        con.MailingStreet = 'test';
        con.MailingCity = 'Norcross';
        con.MailingState = 'Alabama';
        con.MailingCountry = 'United States';
        con.MailingPostalCode = '123321';
        con.AccountId = acc.Id;
        con.ECOM_AddressRegistration__c = 'Select ST & BT';
        con.Phone = '1231234567';
        con.ECOM_Attention_Recipient__c ='';
        //con.Default_Ship_to_ERP_Address__c = '';
        //con.Default_Bill_to_ERP_Address__c = '';
        con.ECOM_NeedsVerification__c = false;
        con.ECOM_Is_Mapped__c = true; //RWPS-2683
        con.ECOM_CountryProvided__c = 'United States'; //RWPS-2683
        
        return con;
    }
    
    public static User createUser(Contact con, Id accId) 
    {
        Profile pf = [SELECT Id FROM Profile WHERE Name = :ECOM_Constant.PROFILE_NAME LIMIT 1];
        //Profile pf = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
        Integer RandomId = Integer.valueOf(Math.rint(Math.random() * 1000000));
        String uniqueName = orgId + dateString + RandomId;
        String userNickname ='TestRevvity';
        User uu = new User(firstname = 'ABC',
                           lastName = 'XYZ',
                           email = uniqueName + '@test' + orgId + '.org',
                           Username = 'testR1@test.org',
                           EmailEncodingKey = 'ISO-8859-1',
                           Alias = uniqueName.substring(18, 23),
                           TimeZoneSidKey = 'America/Los_Angeles',
                           LocaleSidKey = 'en_US',
                           LanguageLocaleKey = 'en_US',
                           ECOM_Is_Punchout_User__c = true,
                           CommunityNickname = userNickname,
                           IsActive = True,
                           ProfileId = pf.Id,
                           ContactId = con.Id,
                           Country__c = 'United States'
                          );
        
        return uu;
    }

    /**
     * RWPS-3772
    * @description : Method to create Non-Punchout Users
    * @author Sachin Vispute 2025.10.08
    */

    public static User createNonPunchoutUser(Contact contact, Id accountId) {
        List<Profile> profileList = [SELECT Id FROM Profile WHERE Name = :ECOM_Constant.PROFILE_NAME LIMIT 1];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
        Integer RandomId = Integer.valueOf(Math.rint(Math.random() * 1000000));
        String uniqueName = orgId + dateString + RandomId;
        String userNickname ='TestingUserRevvity';
        User user = new User(firstname = 'ABCD',
            lastName = 'XYZX',
            email = uniqueName + '@testing' + orgId + '.org',
            Username = 'testing123123@test.org',
            EmailEncodingKey = 'ISO-8859-1',
            Alias = uniqueName.substring(18, 22),
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            ECOM_Is_Punchout_User__c = false,
            CommunityNickname = userNickname,
            IsActive = True,
            ProfileId = profileList[0].Id,
            ContactId = contact.Id,
            Country__c = 'United States'
        );
        return user;
    }
    
    public static WebCart createCart(Account acc, WebStore webStr, User u) 
    {
        
        WebCart cart = new WebCart(Name = 'CAS_Cart', WebStoreId = webStr.Id, 
                                   AccountId = acc.Id, Status = 'Active', OwnerId = u.Id, IsSecondary = false);
        return cart;
    }
    

    //Not Using CPA's
    // public static ContactPointAddress createContactPointAddress(Account acc) {
    //     ContactPointAddress ContactPointAddress = new ContactPointAddress ();
    //     ContactPointAddress.Name = 'Test CPA';
    //     ContactPointAddress.AddressType = 'Shipping';
    //     ContactPointAddress.Street = 'TestStreet';
    //     ContactPointAddress.City = 'TestCity';
    //     ContactPointAddress.State = 'Alabama';
    //     ContactPointAddress.Country = 'United States';
    //     ContactPointAddress.PostalCode = '10013';
    //     ContactPointAddress.IsDefault = true;
    //     ContactPointAddress.ParentId = acc.Id;
    //     ContactPointAddress.SAP_Contact_ID__c = 'randomSAP123';
        
    //     return ContactPointAddress;
    // }
    
    public static CartDeliveryGroup createCartDeliveryGroup(WebCart cart, Id OrderDeliveryMethodId) 
    {
        CartDeliveryGroup cartDeliveryGroup = new CartDeliveryGroup(CartId = cart.Id, Name = 'Default Delivery',DeliveryMethodId = OrderDeliveryMethodId);
        return cartDeliveryGroup;
    }
    
    public static OrderDeliveryMethod createOrderDeliveryMethod() 
    {
        OrderDeliveryMethod OrderDeliveryMethod = new OrderDeliveryMethod(Name = 'Freight');
        return OrderDeliveryMethod;
    }
    
    public static Pricebook2 getPriceBook() 
    {
        return [SELECT Id FROM Pricebook2 WHERE Name =:PRICE_BOOK_REVVITY LIMIT 1];
    }
    
    public static PricebookEntry getPricebookEntry() 
    {
        return [SELECT Product2.ProductCode, Product2.Name, IsActive, Pricebook2Id, 
                CurrencyIsoCode, Pricebook2.Name, Product2Id, UnitPrice, Id FROM
                PricebookEntry WHERE Product2Id!=NULL AND Pricebook2.Name =:PRICE_BOOK_REVVITY LIMIT 1];
    }
    
    
    
    public static Order createOrder(Account account) 
    {
        Pricebook2 pbe = getPriceBook();
        System.debug('pbe::: '+pbe);
        Order order = new Order();
        order.AccountId = account.Id;
        order.OwnerId = portalUser.Id;
        order.EffectiveDate = system.today();
        order.Status = 'Draft';
        //order.OrderNumber = '11234';
        order.Pricebook2Id = pbe.Id;
        System.debug('order::: '+order);
        //insert order;
        return order;
    }
    
    public static OrderItem createOrderItem(Order order, Product2 product, Id orderDeliveryGroupId) 
    {
        PricebookEntry pbe = getPricebookEntry();
        System.debug('pbe::: '+pbe);
        OrderItem orderItem = new OrderItem(
            Product2Id = pbe.Product2Id,
            Type = 'Order Product',
            Quantity = 1,
            ListPrice = pbe.UnitPrice,
            PricebookEntryId = pbe.id,
            UnitPrice = 10,
            OrderId = order.Id,
            TotalLineAmount = 10,
            OrderDeliveryGroupId = orderDeliveryGroupId
        );
        System.debug('orderItem::: '+orderItem);
        //insert orderItem;
        return orderItem;
        
    }
    
    public static OrderDeliveryGroup createOrderDeliveryGroup(OrderDeliveryMethod ord, Order o)
    {
        OrderDeliveryGroup orderDeliveryGroup = new OrderDeliveryGroup(
            DeliverToName = 'Buyer USer',
            DeliverToStreet = 'test Street',
            DeliverToCity = 'Minneapolis',
            //DeliverToState = 'MN',
            DeliverToState = 'Minnesota', // Added By Siddharth
            DeliverToPostalCode = '55402',
            //DeliverToCountry = 'US',
            DeliverToCountry = 'United States', // Added By Siddharth
            OrderDeliveryMethodId = ord.Id,
            OrderId = o.Id
        );
        //insert orderDeliveryGroup;
        return orderDeliveryGroup;
    }
    
    public static OrderSummary createOrderSummary(Account account,User u){
        
        OrderSummary ordsummary = new OrderSummary(
            AccountId = account.Id,
            OwnerId = u.Id
            // OriginalOrderId = ord.Id
        );
        return ordsummary;
    }
    
    public static CartDeliveryGroupMethod createCartDeliveryGroupMethod(Id cartId, Id cartDeliveryGroupId, Id OrderDeliveryMethodId) 
    {
        CartDeliveryGroupMethod cartDeliveryGroupMethod = new CartDeliveryGroupMethod();
        
        cartDeliveryGroupMethod.WebCartId = cartId;
        cartDeliveryGroupMethod.Name = 'CDG NAME';
        cartDeliveryGroupMethod.CartDeliveryGroupId = cartDeliveryGroupId;
        //cartDeliveryGroupMethod.IsDefault__c= true;
        cartDeliveryGroupMethod.ShippingFee = 13;
        cartDeliveryGroupMethod.DeliveryMethodId = OrderDeliveryMethodId;
        return cartDeliveryGroupMethod;
    }
    
    public static CartItem createCartItem(WebCart cart, CartDeliveryGroup cartDeliveryGroup, Product2 p) 
    {
        List<CartItem> cartItems = new List<CartItem>();
        CartItem cartItem = new CartItem(
            CartId = cart.Id,
            Sku = p.ProductCode,
            SalesPrice = 10.00,
            Quantity = 3.0,
            Type = 'Product',
            Name = 'TestProduct',
            Listprice = 10.00,
            CartDeliveryGroupId = cartDeliveryGroup.Id,
            Product2Id = p.Id,
            TotalLineAmount = 30.00,
            ECOM_ShippingCode__c ='17259'
        );
        
        return cartItem;
        
    }
    public static EmailTemplate createEmailTemplate()
    {
        EmailTemplate et = new EmailTemplate(); 
        et.isActive = true; 
        et.Name = 'TestTemplate'; 
        et.DeveloperName = 'TestTemplate'; 
        et.TemplateType = 'text';
        et.Subject = 'Test Subject';
        et.FolderId = UserInfo.getUserId(); 
        et.Body = 'Test Body'; 
        
        return et;
    }
    public static Wishlist createWishlist(Account acc,User u ,WebStore wb){
        Wishlist wishlist = new Wishlist();
        wishlist.AccountId = acc.Id;
        wishlist.OwnerId = u.Id;
        wishlist.WebStoreId = wb.Id;
        wishlist.Name = 'Testwishlist';
        
        return wishlist;
        
    }
    public static WishlistItem createWishlistItem(Wishlist wishlist,Product2 prd){
        WishlistItem wishlistitem = new WishlistItem();
        wishlistitem.Name = 'testwishlistitem';
        wishlistitem.WishlistId = wishlist.Id;
        wishlistitem.Product2Id = prd.Id;
        
        return wishlistitem;
        
    }
    // RWPS-592 start
    /**
    * @description This method is used to get the test record for ContentVersion record
    * @author Manish Joshi| 30-04-2024 
    * @param isNew
    * return ContentVersion
    **/
    public static ContentVersion createContentVersion(boolean isNew){
         Blob bodyBlob = Blob.valueOf('Unit Test Content');
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Content';
        cv.PathOnClient = 'test.txt';
        cv.VersionData = bodyBlob;
        if(isNew)
        	insert cv;
        return cv;
    }
    
    /**
    * @description This method is used to get the test record for object ContentDocumentLink record
    * @author Manish Joshi| 30-04-2024 
    * @param testEntityId
    * @param isNew
    * return ContentDocumentLink
    **/
    public static ContentDocumentLink createContentDocumentLink(Id testEntityId, boolean isNew){
        ContentVersion cv = createContentVersion(true);
        ContentDocument cd = [SELECT Id FROM ContentDocument LIMIT 1];
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = cd.Id;
        cdl.LinkedEntityId = testEntityId;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        if(isNew)
        	insert cdl;
        return cdl;
    }
    // RWPS-592 end

    public static Map<String, Object> initialStorefrontSetup(){
        Map<String, Object> response = new Map<String, Object> ();
        ProductCatalog prodCatalog = ECOM_TestUtil.prepareProductCatalog(STORE_CATALOG_NAME);
        insert prodCatalog;
        
        WebStore webStr = ECOM_TestUtil.prepareWebStore(STORE_NAME);
        insert webStr;
        
        WebStoreCatalog webCatalog = ECOM_TestUtil.prepareWebStoreCatalog(webStr,prodCatalog);
        insert webCatalog;
        
        CommerceEntitlementPolicy commerceEntPolicy = ECOM_TestUtil.prepareCommerceEntitlementPolicy(STORE_PARTNER_ENTITLEMENT_POLICY);
        insert commerceEntPolicy;
        
        List<String> lstCategories = new List<String>();
        lstCategories.add(STORE_PRODUCT_CATEGORY_ALL_PRODUCTS);
        List<ProductCategory> retCatList = ECOM_TestUtil.prepareProductCategory(lstCategories , prodCatalog);
        insert retCatList;
        
        List<String> lstBuyerGroup = new List<String>();
        lstBuyerGroup.add(BUYER_GROUP_REVVITY);
        List<BuyerGroup> retBgList = ECOM_TestUtil.prepareBuyerGroup(lstBuyerGroup);
        insert retBgList;
        
        List<WebStoreBuyerGroup> retWBgList = ECOM_TestUtil.prepareWebStoreBuyerGroup(retBgList , webStr);
        insert retWBgList;
        
        List<CommerceEntitlementBuyerGroup> retWEBgList = ECOM_TestUtil.prepareCommerceEntitlementBuyerGroup(retBgList , commerceEntPolicy);
        insert retWEBgList;
        
        List<String> lstPriceBooks = new List<String>();
        lstPriceBooks.add(PRICE_BOOK_STANDARD);
        lstPriceBooks.add(PRICE_BOOK_REVVITY);
        // check if these are used or not
        List<Pricebook2> pbList = ECOM_TestUtil.createPriceBook(lstPriceBooks);
        insert pbList;
        
        List<BuyerGroupPricebook> bgppList = ECOM_TestUtil.createBuyerGroupPriceBook(retBgList , pbList);
        insert bgppList;
        
        List<Product2> products = new List<Product2>();
        Product2 createShippingChargeProduct = ECOM_TestUtil.createShippingChargeProduct();
        products.add(createShippingChargeProduct);
        
        Product2 simpleProduct = ECOM_TestUtil.createSimpleProduct();
        products.add(simpleProduct);
        insert products;
        Product2 product = products[1];// getting simple product
        
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        PricebookEntry stdEntry = ECOM_TestUtil.createPriceBookEntry(product.Id, standardPricebook.Id);
        PricebookEntry revEntry = ECOM_TestUtil.createPriceBookEntry(product.Id, pbList[1].Id);
        //stdEntry.UseStandardPrice = true;
        List<PricebookEntry> pbes =  new List<PricebookEntry>();
        pbes.add(stdEntry);
        pbes.add(revEntry);
        insert pbes;
        Account acc = ECOM_TestUtil.createAccount('TestClass Account');
        insert acc;
        portalAccount = acc;
        
        BuyerAccount buyerAccount = new BuyerAccount(BuyerId = acc.Id, Name = 'TestClass Account', IsActive = true);
        insert buyerAccount;
        
        List<BuyerGroupMember> bgmList = ECOM_TestUtil.createBuyerGroupMember(retBgList , new List<Account>{acc});
        insert bgmList;
        
        Contact con = ECOM_TestUtil.createNewContact(acc);
        insert con;

        portalContact = con;
        System.runAs(new User(Id=UserInfo.getUserId()))
        {
            User u = ECOM_TestUtil.createUser(con,acc.Id);
            insert u;
            portalUser = u;
            response.put('user' , u);
            List<PermissionSet> ps1 = [SELECT Id FROM PermissionSet WHERE Name = 'MODULE_ECOM_1000_Default_Access_Buyer'];//RWPS-3199
            if(ps1 != NULL && ps1.size()>0){
                insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps1[0].Id);
            }
        }
        ERP_Address__c erpaddressMaster = ECOM_TestUtil.createMasterErpaddress();
        insert erpaddressMaster;
        ERP_Address__c erpaddress = ECOM_TestUtil.createErpaddress(acc,con, erpaddressMaster );
        insert erpaddress;
        ERP_Address__c erpaddressPayer = createPayerErpaddress(acc, con, erpaddress, erpaddressMaster);
        insert erpaddressPayer;
        ERP_Relationship__c  erpRelationship = ECOM_TestUtil.createERPRelationship(con);
        insert  erpRelationship;
        
        con.Default_Ship_to_ERP_Address__c = erpaddress.id;
        con.Default_Bill_to_ERP_Address__c = erpaddressPayer.id;
        update con;
       
        WebCart cart = ECOM_TestUtil.createCart(acc,webStr,portalUser);
        insert cart;
        revvityCart = cart;
        
        OrderDeliveryMethod OrderDeliveryMethod = ECOM_TestUtil.createOrderDeliveryMethod();
        insert OrderDeliveryMethod;
        
        CartDeliveryGroup cartDeliveryGroup = ECOM_TestUtil.createCartDeliveryGroup(cart, OrderDeliveryMethod.Id);
        insert cartDeliveryGroup;
        
        CartDeliveryGroupMethod CartDeliveryGroupMethod = ECOM_TestUtil.createCartDeliveryGroupMethod(cart.Id, cartDeliveryGroup.Id, OrderDeliveryMethod.Id);
        insert CartDeliveryGroupMethod;
        
        
        CartItem cartItem = ECOM_TestUtil.createCartItem(cart,cartDeliveryGroup,product);
        insert cartItem;
        CartItem cartFreeItem = ECOM_TestUtil.createCartItem(cart,cartDeliveryGroup,product); //RWPS-4202
        cartFreeItem.ecom_parent_item__c = cartItem.Id;
        insert cartFreeItem;
        Order order = ECOM_TestUtil.createOrder(portalAccount);
        order.Default_Bill_to_ERP_Address__c = erpaddressPayer.Id;
        order.Default_Ship_to_ERP_Address__c = erpaddress.Id;
        order.ECOM_Promo_Code__c='RGEVAL50'; //RWPS-2307
        insert order;
        OrderDeliveryGroup createOrderDeliveryGroup = ECOM_TestUtil.createOrderDeliveryGroup(OrderDeliveryMethod,order);
        insert createOrderDeliveryGroup;
        OrderItem orderItem = ECOM_TestUtil.createOrderItem(order, simpleProduct, createOrderDeliveryGroup.Id);
        insert orderItem;
         CardPaymentMethod cardpayment = ECOM_TestUtil.createCardPaymentMethod(order);
        insert cardpayment;
        PaymentAuthorization paymentauthrization = ECOM_TestUtil.createPaymentAuthorization(acc,order);
        insert paymentauthrization;
        Wishlist wishlist = ECOM_TestUtil.createWishlist(acc,portalUser,webStr);
        insert wishlist;
        
        WishlistItem wishlistItem =ECOM_TestUtil.createWishlistItem(wishlist,simpleProduct);
        insert wishlistItem;
        //Start- RWPS-2307
        Promotion promo = New Promotion(Name = 'ECOM Revvity OneTime Promo', IsActive = true);
        insert promo;
        //Insert Coupoun
        Coupon coupon = New Coupon(CouponCode = 'RGEVAL50', PromotionId = promo.id, Status = 'Active');
        //RWPS-3283 start
        List<Coupon> couponList = new List<Coupon>();
        couponList.add(coupon);
        couponList.add(New Coupon(CouponCode = 'HELLO10', PromotionId = promo.id, Status = 'Active', ECOM_User_Type__c='Web Promotion'));
        couponList.add(New Coupon(CouponCode = 'Test25', PromotionId = promo.id, Status = 'Active', ECOM_User_Type__c='Punchout Promotion'));
        insert couponList;
        //RWPS-3283 end
        promo = New Promotion(Name = 'ECOM First-Time Coupons for New Users', IsActive = true);
        insert promo;
        coupon = New Coupon(CouponCode = 'RGEVAL', PromotionId = promo.id, Status = 'Active');
        insert coupon;
        //End - RWPS-2307

        //List<Network> network = [SELECT Id, Name FROM Network];
        response.put('acc',acc);
        response.put('con',con);  
        //response.put('network',network);  
        response.put('webstore',webStr); 
        response.put('product',product); 
        response.put('cart',cart);
        //response.put('simpleProduct',product);
        System.debug('Portal Account'+ portalAccount);
        System.debug('Portal Contact'+ portalContact);
        System.debug('Portal user'+ portalUser);
        
        return response;
    }

    //RWPS-3772
    public static Map<String, Object> initialStorefrontSetupForNonPunchout(){
        Map<String, Object> response = new Map<String, Object> ();
        ProductCatalog prodCatalog = ECOM_TestUtil.prepareProductCatalog(STORE_CATALOG_NAME);
        insert prodCatalog;
        
        WebStore webStr = ECOM_TestUtil.prepareWebStore(STORE_NAME);
        insert webStr;
        
        WebStoreCatalog webCatalog = ECOM_TestUtil.prepareWebStoreCatalog(webStr,prodCatalog);
        insert webCatalog;
        
        CommerceEntitlementPolicy commerceEntPolicy = ECOM_TestUtil.prepareCommerceEntitlementPolicy(STORE_PARTNER_ENTITLEMENT_POLICY);
        insert commerceEntPolicy;
        
        List<String> lstCategories = new List<String>();
        lstCategories.add(STORE_PRODUCT_CATEGORY_ALL_PRODUCTS);
        List<ProductCategory> retCatList = ECOM_TestUtil.prepareProductCategory(lstCategories , prodCatalog);
        insert retCatList;
        
        List<String> lstBuyerGroup = new List<String>();
        lstBuyerGroup.add(BUYER_GROUP_REVVITY);
        List<BuyerGroup> retBgList = ECOM_TestUtil.prepareBuyerGroup(lstBuyerGroup);
        insert retBgList;
        
        List<WebStoreBuyerGroup> retWBgList = ECOM_TestUtil.prepareWebStoreBuyerGroup(retBgList , webStr);
        insert retWBgList;
        
        List<CommerceEntitlementBuyerGroup> retWEBgList = ECOM_TestUtil.prepareCommerceEntitlementBuyerGroup(retBgList , commerceEntPolicy);
        insert retWEBgList;
        
        List<String> lstPriceBooks = new List<String>();
        lstPriceBooks.add(PRICE_BOOK_STANDARD);
        lstPriceBooks.add(PRICE_BOOK_REVVITY);
        // check if these are used or not
        List<Pricebook2> pbList = ECOM_TestUtil.createPriceBook(lstPriceBooks);
        insert pbList;
        
        List<BuyerGroupPricebook> bgppList = ECOM_TestUtil.createBuyerGroupPriceBook(retBgList , pbList);
        insert bgppList;
        
        List<Product2> products = new List<Product2>();
        Product2 createShippingChargeProduct = ECOM_TestUtil.createShippingChargeProduct();
        products.add(createShippingChargeProduct);
        
        Product2 simpleProduct = ECOM_TestUtil.createSimpleProduct();
        products.add(simpleProduct);
        insert products;
        Product2 product = products[1];// getting simple product
        
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        PricebookEntry stdEntry = ECOM_TestUtil.createPriceBookEntry(product.Id, standardPricebook.Id);
        PricebookEntry revEntry = ECOM_TestUtil.createPriceBookEntry(product.Id, pbList[1].Id);
        //stdEntry.UseStandardPrice = true;
        List<PricebookEntry> pbes =  new List<PricebookEntry>();
        pbes.add(stdEntry);
        pbes.add(revEntry);
        insert pbes;
        Account acc = ECOM_TestUtil.createAccount('TestClass Account');
        insert acc;
        portalAccount = acc;
        
        BuyerAccount buyerAccount = new BuyerAccount(BuyerId = acc.Id, Name = 'TestClass Account', IsActive = true);
        insert buyerAccount;
        
        List<BuyerGroupMember> bgmList = ECOM_TestUtil.createBuyerGroupMember(retBgList , new List<Account>{acc});
        insert bgmList;
        
        Contact con = ECOM_TestUtil.createNewContact(acc);
        insert con;

        //RWPS-3772
        Contact nonPortalContact = ECOM_TestUtil.createNewContact(acc);
        nonPortalContact.FirstName = 'TestingRevvity';
        nonPortalContact.LastName = 'TestingRevvityTest';
        nonPortalContact.Email = 'testing@testRevvity.com';
		insert nonPortalContact;
        //RWPS-3772

        portalContact = con;
        System.runAs(new User(Id=UserInfo.getUserId()))
        {
            User u = ECOM_TestUtil.createUser(con,acc.Id);
            insert u;
            portalUser = u;
            response.put('user' , u);
            List<PermissionSet> ps1 = [SELECT Id FROM PermissionSet WHERE Name = 'MODULE_ECOM_1000_Default_Access_Buyer'];//RWPS-3199
            if(ps1 != NULL && ps1.size()>0){
                insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps1[0].Id);
            }

            //RWPS-3772 - Start
            User nonPunchoutUser = ECOM_TestUtil.createNonPunchoutUser(nonPortalContact,acc.Id);
            insert nonPunchoutUser;
            portalUser = nonPunchoutUser;
            response.put('user2' , nonPunchoutUser);
            if(ps1.isEmpty() == false) {
                insert new PermissionSetAssignment(AssigneeId = nonPunchoutUser.Id, PermissionSetId = ps1[0].Id);
            }
            //RWPS-3772 - End
        }
        ERP_Address__c erpaddressMaster = ECOM_TestUtil.createMasterErpaddress();
        insert erpaddressMaster;
        ERP_Address__c erpaddress = ECOM_TestUtil.createErpaddress(acc,con, erpaddressMaster );
        insert erpaddress;
        ERP_Address__c erpaddressPayer = createPayerErpaddress(acc, con, erpaddress, erpaddressMaster);
        insert erpaddressPayer;
        ERP_Relationship__c  erpRelationship = ECOM_TestUtil.createERPRelationship(con);
        insert  erpRelationship;
        
        con.Default_Ship_to_ERP_Address__c = erpaddress.id;
        con.Default_Bill_to_ERP_Address__c = erpaddressPayer.id;
        update con;
       
        WebCart cart = ECOM_TestUtil.createCart(acc,webStr,portalUser);
        insert cart;
        revvityCart = cart;
        
        OrderDeliveryMethod OrderDeliveryMethod = ECOM_TestUtil.createOrderDeliveryMethod();
        insert OrderDeliveryMethod;
        
        CartDeliveryGroup cartDeliveryGroup = ECOM_TestUtil.createCartDeliveryGroup(cart, OrderDeliveryMethod.Id);
        insert cartDeliveryGroup;
        
        CartDeliveryGroupMethod CartDeliveryGroupMethod = ECOM_TestUtil.createCartDeliveryGroupMethod(cart.Id, cartDeliveryGroup.Id, OrderDeliveryMethod.Id);
        insert CartDeliveryGroupMethod;
        
        
        CartItem cartItem = ECOM_TestUtil.createCartItem(cart,cartDeliveryGroup,product);
        insert cartItem;
        CartItem cartFreeItem = ECOM_TestUtil.createCartItem(cart,cartDeliveryGroup,product); //RWPS-4202
        cartFreeItem.ecom_parent_item__c = cartItem.Id;
        insert cartFreeItem;
        Order order = ECOM_TestUtil.createOrder(portalAccount);
        order.Default_Bill_to_ERP_Address__c = erpaddressPayer.Id;
        order.Default_Ship_to_ERP_Address__c = erpaddress.Id;
        order.ECOM_Promo_Code__c='RGEVAL50'; //RWPS-2307
        insert order;
        OrderDeliveryGroup createOrderDeliveryGroup = ECOM_TestUtil.createOrderDeliveryGroup(OrderDeliveryMethod,order);
        insert createOrderDeliveryGroup;
        OrderItem orderItem = ECOM_TestUtil.createOrderItem(order, simpleProduct, createOrderDeliveryGroup.Id);
        insert orderItem;
         CardPaymentMethod cardpayment = ECOM_TestUtil.createCardPaymentMethod(order);
        insert cardpayment;
        PaymentAuthorization paymentauthrization = ECOM_TestUtil.createPaymentAuthorization(acc,order);
        insert paymentauthrization;
        Wishlist wishlist = ECOM_TestUtil.createWishlist(acc,portalUser,webStr);
        insert wishlist;
        
        WishlistItem wishlistItem =ECOM_TestUtil.createWishlistItem(wishlist,simpleProduct);
        insert wishlistItem;
        //Start- RWPS-2307
        Promotion promo = New Promotion(Name = 'ECOM Revvity OneTime Promo', IsActive = true);
        insert promo;
        //Insert Coupoun
        Coupon coupon = New Coupon(CouponCode = 'RGEVAL50', PromotionId = promo.id, Status = 'Active');
        //RWPS-3283 start
        List<Coupon> couponList = new List<Coupon>();
        couponList.add(coupon);
        couponList.add(New Coupon(CouponCode = 'HELLO10', PromotionId = promo.id, Status = 'Active', ECOM_User_Type__c='Web Promotion'));
        couponList.add(New Coupon(CouponCode = 'Test25', PromotionId = promo.id, Status = 'Active', ECOM_User_Type__c='Punchout Promotion'));
        insert couponList;
        //RWPS-3283 end
        promo = New Promotion(Name = 'ECOM First-Time Coupons for New Users', IsActive = true);
        insert promo;
        coupon = New Coupon(CouponCode = 'RGEVAL', PromotionId = promo.id, Status = 'Active');
        insert coupon;
        //End - RWPS-2307

        //List<Network> network = [SELECT Id, Name FROM Network];
        response.put('acc',acc);
        response.put('con',con);  
        //response.put('network',network);  
        response.put('webstore',webStr); 
        response.put('product',product); 
        response.put('cart',cart);
        //response.put('simpleProduct',product);
        System.debug('Portal Account'+ portalAccount);
        System.debug('Portal Contact'+ portalContact);
        System.debug('Portal user'+ portalUser);
        
        return response;
    }

    public static ConnectApi.WishlistItem getWishlistItemData(){
        ConnectApi.WishlistItem response = new  ConnectApi.WishlistItem();
        ConnectApi.CartItemProduct productSummary = new ConnectApi.CartItemProduct();
        productSummary.name='product A';
        productSummary.productId='xxxxxxxxxx';
        productSummary.thumbnailImage = null;
        response.currencyIsoCode = 'USD';
        response.error = null;
        response.salesPrice=10.00;
        response.productSummary = productSummary;
        response.wishlistItemId = 'xxxx';
        return response;
    }
    public static List<ConnectApi.WishlistItem> getWishlistItemListData(){
        List<ConnectApi.WishlistItem> responseList = new List<ConnectApi.WishlistItem>();
        ConnectApi.WishlistItem response = new  ConnectApi.WishlistItem();
        ConnectApi.CartItemProduct productSummary = new ConnectApi.CartItemProduct();
        productSummary.name='product A';
        productSummary.productId='xxxxxxxxxx';
        productSummary.thumbnailImage = null;
        response.currencyIsoCode = 'USD';
        response.error = null;
        response.salesPrice=10.00;
        response.productSummary = productSummary;
        response.wishlistItemId = 'xxxx';
        responseList.add(response);
        return responseList;
    }
    public static ConnectApi.Wishlist getWishlistData(){
        ConnectApi.Wishlist response = new ConnectApi.Wishlist();
        ConnectApi.WishlistItemCollection wishlistItemcollection = new ConnectApi.WishlistItemCollection();
        wishlistItemcollection.currencyIsoCode = 'USD';
        ConnectApi.WishlistItem wishlistItem = new  ConnectApi.WishlistItem();
        ConnectApi.CartItemProduct productSummary = new ConnectApi.CartItemProduct();
        productSummary.name='product A';
        productSummary.productId='xxxxxxxxxx';
        productSummary.thumbnailImage = null;
        wishlistItem.currencyIsoCode = 'USD';
        wishlistItem.error = null;
        wishlistItem.salesPrice=10.00;
        wishlistItem.productSummary = productSummary;
        wishlistItem.wishlistItemId = 'xxxx';
        List<ConnectApi.WishlistItem> items  = getWishlistItemListData();
        wishlistItemcollection.Items = items;
        response.page = wishlistItemcollection;
        ConnectApi.WishlistSummary wishlistSummary =  new  ConnectApi.WishlistSummary();
        wishlistSummary.name = 'testwishlist';
        wishlistSummary.wishlistProductCount = 2;
        response.summary = wishlistSummary;
        return response;
        
    }
    public static ConnectApi.WishlistsSummary getWishlistsSummaryData(){
        ConnectApi.WishlistsSummary response = new  ConnectApi.WishlistsSummary();
        
        ConnectApi.WishlistSummary summaryData= new ConnectApi.WishlistSummary();
        summaryData.createdDate=System.today();
        summaryData.id='avf342';
        summaryData.modifiedDate=System.today();
        summaryData.name='WishList Name';
        summaryData.wishlistProductCount=1;
        
        List<ConnectApi.WishlistSummary> summaries = new List<ConnectApi.WishlistSummary>();
        summaries.add(summaryData);
        
        List<ConnectApi.WishlistItem> itemsList= new List<ConnectApi.WishlistItem>();
        ConnectApi.WishlistItem items=new ConnectApi.WishlistItem();
        items.currencyIsoCode='USD';
        items.error=null;
        items.listPrice=100;
        items.salesPrice=80;
        items.wishlistItemId='12345abcd';
        itemsList.add(items);
        
        
        ConnectApi.WishlistItemCollection pageData= new ConnectApi.WishlistItemCollection();
        pageData.currencyIsoCode='USD';
        pageData.currentPageToken='2';
        pageData.currentPageUrl='abc2.in';
        pageData.hasErrors=false;
        pageData.nextPageToken='3';
        pageData.nextPageUrl='abc3.in';
        pageData.previousPageToken='1';
        pageData.previousPageUrl='abc1.in';
        pageData.items=itemsList;
        ConnectApi.Wishlist displayedList = new ConnectApi.Wishlist();
        displayedList.summary=summaryData;
        displayedList.page=pageData;
        
        
        
        ConnectApi.CartItemProduct productSummary= new ConnectApi.CartItemProduct();
        productSummary.name='testprod';
        productSummary.productId='123xxxxx12';
        productSummary.purchaseQuantityRule=null;
        productSummary.sku='PRO123';
        productSummary.thumbnailImage=null;
        productSummary.variationAttributes=null;
        
        Map<String, String> productData= new Map<String, String>();
        productData.put('Name','testProduct');
        
        response.wishlistCount=1;
        
        return response;
        
    }
    public static  ConnectApi.WishlistItemCollection itemCollectionData(){
        ConnectApi.WishlistItemCollection pageData= new ConnectApi.WishlistItemCollection();
        
        List<ConnectApi.WishlistItem> itemsList= new List<ConnectApi.WishlistItem>();
        ConnectApi.WishlistItem items=new ConnectApi.WishlistItem();
        ConnectApi.CartItemProduct productSummary= new ConnectApi.CartItemProduct();
        productSummary.name='testprod';
        productSummary.productId='123xxxxx12';
        productSummary.purchaseQuantityRule=null;
        productSummary.sku='PRO123';
        productSummary.thumbnailImage=null;
        productSummary.variationAttributes=null;
        
        items.currencyIsoCode='USD';
        items.error=null;
        items.listPrice=100;
        items.salesPrice=80;
        items.productSummary =  productSummary; 
        items.wishlistItemId='12345abcd';
        itemsList.add(items);
        
        pageData.currencyIsoCode='USD';
        pageData.currentPageToken='2';
        pageData.currentPageUrl='abc2.in';
        pageData.hasErrors=false;
        pageData.nextPageToken='3';
        pageData.nextPageUrl='abc3.in';
        pageData.previousPageToken='1';
        pageData.previousPageUrl='abc1.in';
        pageData.items=itemsList;    
        return pageData;
    }

    public static ConnectApi.CartItemCollection testConnectApiCartItemCollection()
    {
        ConnectApi.CartItemCollection res = new ConnectApi.CartItemCollection();
        ConnectApi.CartCouponCollection coupon = new ConnectApi.CartCouponCollection();
        List<ConnectApi.CartItemResult> cartItms = new List<ConnectApi.CartItemResult>();
        ConnectApi.CartItemResult cartItm=new ConnectApi.CartItemResult();
        cartItm.message='cart item message';
        cartItm.status='status';
        ConnectApi.CartPromotionCollection promo = new ConnectApi.CartPromotionCollection();
        ConnectApi.CartSummary summary =new  ConnectApi.CartSummary();
        res.currentPageToken = 'abc3.in';
        res.currentPageToken = '2';
        res.hasErrors = false;
        res.nextPageToken = '3';
        res.previousPageUrl = 'abc4.in';
        res.previousPageToken = '1';
        res.previousPageUrl = 'abc2.in';
        return res;

    }
    
    public static ConnectApi.CartItem getCartItemData(){
        ConnectApi.CartItem response= new ConnectApi.CartItem();
        response.currencyIsoCode='USD';
        response.itemizedAdjustmentAmount='20';
        response.listPrice='1000';
        response.salesprice='900';
        response.totalAdjustmentAmount='100';
        response.totalAmount='50';
        response.totalListPrice='200';
        response.totalPrice='1000';
        response.totalTax='10';
        response.unitAdjustedPrice='20';
        response.unitAdjustmentAmount='20';
        return response;
    }
    
    public static ConnectApi.Wishlist getWishlistDataNew(){
        ConnectApi.Wishlist response = new ConnectApi.Wishlist();
        response.page=null;
        ConnectApi.WishlistSummary summaryData = new   ConnectApi.WishlistSummary();
        summaryData.createdDate=System.today();
        summaryData.id='abcd1234';
        summaryData.modifiedDate=System.today();
        summaryData.name='WishList Name';
        summaryData.wishlistProductCount=1;
        response.summary=summaryData;
        return response;
        
    }
    public static ConnectApi.ProductOverviewCollection getProductOverviewCollection(){
        ConnectApi.ProductOverview productOverview = new ConnectApi.ProductOverview();
        productOverview.id='1234abcd';
        productOverview.sku='Sk12';
        productOverview.success=true;
        productOverview.fields=null;
        productOverview.error=null;
        productOverview.defaultImage=null;
        List<ConnectApi.ProductOverview> productOverviewList=new List<ConnectApi.ProductOverview>();
        productOverviewList.add(productOverview);
        ConnectApi.ProductOverviewCollection response = new ConnectApi.ProductOverviewCollection();
        
        response.products=productOverviewList;
        response.total=50;
        return response;
        
    }
    public static ConnectApi.CartSummary getCartData(){
        ConnectApi.CartSummary cartdata=new ConnectApi.CartSummary();
        cartdata.accountId='12132sdsf';
        //cartdata.asyncOperationStatus='Completed';    
        cartdata.cartId='sffs3123';
        cartdata.currencyIsoCode= 'USD';
        cartdata.grandTotalAmount='500';
        cartdata.isSecondary=false;
        cartdata.name='CSUMM NAME';
        cartdata.ownerId='32wfs';
        cartdata.purchaseOrderNumber='00123489';
        cartdata.totalChargeAmount='50';
        cartdata.totalListPrice='400';
        cartdata.totalProductAmount='600';
        cartdata.totalProductAmountAfterAdjustments='650';  
        cartdata.totalProductCount='9';
        cartdata.totalPromotionalAdjustmentAmount='520';
        cartdata.totalTaxAmount='700';
        //ConnectApi.CartType type=new ConnectApi.CartType();
        cartdata.uniqueProductCount=3;
        cartdata.webstoreId='wewr13244';
        return cartdata;
    }

    /*
    *@author : Mayank
    *@desc : data for ECOM_ProductShippingTime__c
    */
    public static ECOM_ProductShippingTime__c createProductShippingTime()
    {   //RWPS-2786 - START
        ECOM_ProductShippingTime__c pst = new ECOM_ProductShippingTime__c();
        pst.Name = 'Test Shipping Time';
        pst.ECOM_Country__c = 'US';
        pst.Ecom_Priority__c = 'Priority'; 
        pst.Ecom_Total_DLV__c  = 20;
        pst.Ecom_Site__c = 'LUS10-A';
        pst.Ecom_Confidence_90__c = 'Arrives in 2-3 days';
        insert pst;
        return pst;
        //RWPS-2786 - END
    }
    // public static ConnectApi.BatchResult getBatchData(){
    //     List<ConnectApi.BatchResult> listbatch = new List<ConnectApi.BatchResult>();
    //     ConnectApi.BatchResult batchdata=new ConnectApi.BatchResult();
    //     // batchdata.webstoreId='REV13244';
    //     // batchdata.cartId='3456Edr';
    //     // batchdata.accountId='12132sdsf';
        
    //     listbatch.add(batchdata);
    //     return batchdata;
    //     }
    public static ECOM_WishListFlowResponseWrapper createResponseWrapperData(){      
        ECOM_WishListFlowResponseWrapper wishlistResponse = new ECOM_WishListFlowResponseWrapper();
        wishlistResponse.success=true;
        wishlistResponse.wishlistId='abcd1234';
        wishlistResponse.message='message string';
        
        return wishlistResponse;
        
        
    }

    /* 
    * @author: Mayank Srivastava
    * 
    */
    public static ConnectApi.CartItem createDataConnectApi_CartItem(String productId)
    {
       ConnectApi.CartItem cartItem = new ConnectApi.CartItem();
       cartItem.productId = productId;
       cartItem.quantity = '1';
       cartItem.itemizedAdjustmentAmount = '1000';
       cartItem.listPrice = '1000';
       cartItem.salesPrice = '1000';
       cartItem.totalAdjustmentAmount = '20';
       cartItem.totalAmount = '1020';
       cartItem.totalListPrice = '1000';
       cartItem.totalPrice = '1000';
       cartItem.totalTax = '20';
       cartItem.unitAdjustedPrice = '10'; 
       cartItem.unitAdjustmentAmount ='10';
       return cartItem;
    }

    /* 
    * @author: Mayank Srivastava
    * @return type : Product_Sales__c
    */
        public static Product_Sales__c createProduct_Sales(String productId)
        {
            Product_Sales__c record = new Product_Sales__c();
            record.Distribution_ChainSpecificMaterialStatus__c = 'WE';
            record.Product__c = productId;
            return record;
        }
    public static ConnectApi.CartSummary createDataConnectApi_CartSummary()
    {
        String acId = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        String cartId = [SELECT Id FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        ConnectApi.CartSummary obj = new ConnectApi.CartSummary();
        obj.accountId = acId;
        obj.cartId = cartId;
        obj.currencyIsoCode = 'USD';
        obj.grandTotalAmount = '1000';
        obj.name = 'TestApi';
        return obj;
    }
    /*public static ConnectApi.CartItemResult createcartItemdata(){
        //String cartId = [SELECT Id FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        //ConnectApi.BillingFrequency billingresponse = new ConnectApi.BillingFrequency();

        ConnectApi.CartItemResult cartItemresult = new ConnectApi.CartItemResult();
        ConnectApi.CartItemProduct productSummary= new ConnectApi.CartItemProduct();
        productSummary.name='testprod';
        productSummary.productId='123xxxxx12';
        productSummary.purchaseQuantityRule=null;
        productSummary.sku='PRO123';
        productSummary.thumbnailImage=null;
        productSummary.variationAttributes=null;
        ConnectApi.AbstractCartItem response = new ConnectApi.AbstractCartItem();
        response.cartId = 'abcd1234';
        response.cartItemId = 'aabb1234';
        response.productId = 'prd12334';
        response.productDetails = productSummary;
        cartItemresult.message = 'message string';
        cartItemresult.status = 'status';
        return cartItemresult;
    }*/

    /*
    * @author : Mayank
    * @description : creating data for CartCheckoutSession.
    * @param : Webcart cart,Order ord
    */

    public static CartCheckoutSession createCartCheckoutSession(Webcart cart, Order ord)
    {
        CartCheckoutSession checkoutSession;
        checkoutSession = new CartCheckoutSession(WebCartId = cart.Id, IsArchived = FALSE, State = 'Start', Name = cart.Id,OrderId = ord.Id,IsError = false);
        insert checkoutSession;
        return checkoutSession;
    }
        /*
    * @author : Mayank
    * @description : creating data for CartCheckoutSession.
    * @param :
    */
    public static ConnectApi.ManagedContentDeliveryDocumentCollection connectApiContentData()
    {
        ConnectApi.ManagedContentDeliveryDocumentCollection testD = new ConnectApi.ManagedContentDeliveryDocumentCollection();
        ConnectApi.ManagedContentChannelSummary channelInfo = new ConnectApi.ManagedContentChannelSummary();
        channelInfo.resourceUrl='test.com/channels/test1234';
        List<ConnectApi.AbstractManagedContentDeliveryDocument> innerDs = new List<ConnectApi.AbstractManagedContentDeliveryDocument>();
        ConnectApi.AbstractManagedContentDeliveryDocument innerD;
        innerDs.add(innerD);
        testD.contents=innerDs;
        testD.channelInfo = channelInfo;
        return testD;
    }

    
    
    public static ERP_Address__c createErpaddress(Account acc,Contact con, ERP_Address__c parent){
        
        ERP_Address__c erpAddress = new ERP_Address__c();
         erpAddress.Contact__c = con.Id;
        erpAddress.ERP_Account_Name__c = acc.Id;
        erpAddress.Address_Type__c = 'Ship To';
        erpAddress.Address_Street_Line_1__c = 'newstreet';
        erpAddress.Address_City__c = 'newERPcity';
        erpAddress.apiState__c = 'newERPstate';
        erpAddress.Address_Postal_Code__c = 'newERPpostalCode';
        erpAddress.apiCountry__c = 'United States';
        erpAddress.ECOM_isEnabled__c = true;
        erpAddress.Master_Address__c = parent.Id;
        erpAddress.Target_Address__c = parent.Id;
        //erpAddress.ERP_Marked_for_Deletion__c = false ;
        //erpAddress.ECOM_Review_Status__c = 'Approved';
        //erpAddress.ECOM_Punchout_Customer_Id__c ='CITRA';
        //insert erpAddress;
        return erpAddress;
    }
    
    public static ERP_Address__c createPayerErpaddress(Account acc,Contact con, ERP_Address__c shipto, ERP_Address__c parent){
        
        ERP_Address__c erpAddress = new ERP_Address__c();
        erpAddress.Contact__c = con.Id;
        erpAddress.ERP_Account_Name__c = acc.Id;
        erpAddress.Address_Type__c = 'Payer';
        erpAddress.Master_Address__c = parent.Id;
        erpAddress.Target_Address__c = parent.Id;
        erpAddress.Address_Street_Line_1__c = 'newstreet';
        erpAddress.Address_City__c = 'newERPcity';
        erpAddress.apiState__c = 'newERPstate';
        erpAddress.Address_Postal_Code__c = 'newERPpostalCode';
        erpAddress.apiCountry__c = 'United States';
        erpAddress.ECOM_isEnabled__c = true;
        //erpAddress.ERP_Marked_for_Deletion__c = false ;
        //erpAddress.ECOM_Review_Status__c = 'Approved';
        //erpAddress.ECOM_Punchout_Customer_Id__c ='CITRA';
        //insert erpAddress;
        return erpAddress;
    }
    public static ERP_Address__c createPunchoutMasterErpaddress(){
        
        ERP_Address__c erpAddress = new ERP_Address__c();
        
        erpAddress.Address_Type__c = 'Master';
        erpAddress.Address_Street_Line_1__c = 'newstreet';
        erpAddress.Address_City__c = 'newERPcity';
        erpAddress.apiState__c = 'New York';
        erpAddress.Address_Postal_Code__c = '09088';
        erpAddress.apiCountry__c = 'United States';
        erpAddress.ECOM_isEnabled__c = true;
        erpAddress.ERP_Marked_for_Deletion__c = false ;
        erpAddress.ECOM_Punchout_Is_Enabled__c=true;
        erpAddress.ECOM_Review_Status__c = 'Approved';
        erpAddress.ECOM_Punchout_Customer_Id__c ='CITRA';
        insert erpAddress;
        return erpAddress;
    }
    public static ERP_Address__c createPunchoutErpaddress(Account acc,Contact con, ERP_Address__c parent){
        
        ERP_Address__c erpAddress = new ERP_Address__c();
         erpAddress.Contact__c = con.Id;
        erpAddress.ERP_Account_Name__c = acc.Id;
        erpAddress.Address_Type__c = 'Bill To';
        erpAddress.Address_Street_Line_1__c = 'newstreet';
        erpAddress.Address_City__c = 'newERPcity';
        erpAddress.apiState__c = 'newERPstate';
        erpAddress.Address_Postal_Code__c = 'newERPpostalCode';
        erpAddress.apiCountry__c = 'United States';
        erpAddress.ECOM_isEnabled__c = true;
        erpAddress.Master_Address__c = parent.Id;
        erpAddress.Target_Address__c = parent.Id;
        erpAddress.ERP_Marked_for_Deletion__c = false ;
        erpAddress.ECOM_Punchout_Is_Enabled__c=true;
        
        erpAddress.ECOM_Punchout_Customer_Id__c ='CITRA';
        insert erpAddress;
        erpAddress.ECOM_Review_Status__c = parent.ECOM_Review_Status__c;
        update erpAddress;
        return erpAddress;
    }
    public static ERP_Address__c createMasterErpaddress(){
        
        ERP_Address__c erpAddress = new ERP_Address__c();
        
        erpAddress.Address_Type__c = 'Master';
        erpAddress.Address_Street_Line_1__c = 'newstreet';
        erpAddress.Address_City__c = 'newERPcity';
        erpAddress.apiState__c = 'New York';
        erpAddress.Address_Postal_Code__c = '09088';
        erpAddress.apiCountry__c = 'United States';
        erpAddress.ECOM_isEnabled__c = true;
        erpAddress.External_Id__c = '112223231';
        erpaddress.SAP_Name_1__c = 'Test';
        //erpAddress.ERP_Marked_for_Deletion__c = false ;
        //erpAddress.ECOM_Review_Status__c = 'Approved';
        //erpAddress.ECOM_Punchout_Customer_Id__c ='CITRA';
        return erpAddress;
    }
    
    public static List<ERP_Address__c> createErpaddressSoldTo(String accId){
        List<ERP_Address__c> listD = new List<ERP_Address__c>();
        ERP_Address__c erpAddress = new ERP_Address__c();
         erpAddress.Contact__c = null;
        erpAddress.ERP_Account_Name__c = accId;
        erpAddress.Address_Type__c = 'Sold To';
        erpAddress.Address_Street_Line_1__c = 'newstreet';
        erpAddress.Address_City__c = 'newERPcity';
        erpAddress.apiState__c = 'New York';
        erpAddress.Address_Postal_Code__c = '09909';
        erpAddress.apiCountry__c = 'United States';
        erpAddress.ECOM_isEnabled__c = true;
        erpAddress.ERP_Sales_Org__c = 'EEU2';
        //erpAddress.Target_Address__c = 'a1JDW000001DL282AG';
        //erpAddress.Master_Address__c = 'a1JDW000001DL282AG';
        erpAddress.SAP_Name_1__c = 'testSAP1';
        erpAddress.SAP_Name_2__c = 'testSAP2';
        erpAddress.SAP_Name_3__c = 'testSAP3';
        erpAddress.SAP_Name_4__c = 'testSAP4';
        erpAddress.Account__c = accId;
        // erpAddress.ERP_Marked_for_Deletion__c = false ;
        //erpAddress.ECOM_Review_Status__c = 'Approved';
        //erpAddress.ECOM_Punchout_Customer_Id__c ='CITRA';
        
        //insert erpAddress;
         listD.add(erpAddress);
        return listD;
    }
    
    public static ERP_Relationship__c createERPRelationship(Contact con){
        ERP_Relationship__c erpRelation = new ERP_Relationship__c();
        erpRelation.Contact__c = con.Id;
        erpRelation.Name ='testerp';
        erpRelation.ERP_Contact_ID__c = '3034567';
       // insert erpRelation;
        return erpRelation;
    }
    
    public static PaymentAuthorization createPaymentAuthorization(Account acc,Order ord){
         PaymentAuthorization paymentAuthorization = new PaymentAuthorization();
        paymentAuthorization.AccountId =acc.Id;
        paymentAuthorization.ECOM_Order__c = ord.Id;
        paymentAuthorization.Amount = 110.00;
        paymentAuthorization.Status = 'Processed';
        paymentAuthorization.ProcessingMode ='External' ;
        //insert paymentAuthorization;
        return paymentAuthorization;
    }
    
    public static CardPaymentMethod createCardPaymentMethod(Order ord){
         CardPaymentMethod cardPayment =new CardPaymentMethod();
        cardPayment.ECOM_Order__c = ord.Id;
        cardPayment.CardLastFour = 1123;
        cardPayment.CardType ='Visa';
        cardPayment.CardCategory = 'CreditCard';
        cardPayment.Status = 'Active';
        cardPayment.ProcessingMode ='External' ;
        //insert cardPayment;
        return cardPayment;
    }
    
    public static Product_Sales__c createProductSalesData(CartItem ctm)
    {
        String productId = [SELECT Id,Product2Id FROM CartItem WHERE Id =: ctm.Id].Product2Id;
        Product_Sales__c psl = new Product_Sales__c();
        psl.Distribution_ChainSpecificMaterialStatus__c ='ZW';
        psl.Product_Type__c = 'Test';
        psl.CurrencyIsoCode = 'USD';
        psl.Product__c = productId;
        return psl;
    }
    
    // Method to create dummy POSR, POOM logs
    public static void createPOSRPOOMData(){
        final String CLASS_NAME = 'ECOM_ApplicationLogsUtil_Test';
        final String METHOD_NAME = 'TestAllMethods';
        final String MODULE_NAME = 'Test ECOM_ApplicationLogs';
        final String RESPONSE = 'RESPONSE';
        final String SUPPORT_DATA = 'suppport data';    
        final String ACTION_TYPE = 'action';
        final String SUPPORT_DATA_POSR_REQUEST = '{"userEmail":"testfn01rone@yopmail.com","firstName":"Test","lastName":"Rone","emailEncodingKey":"UTF-8","loginUserType":"punchoutUser","isNewUser":"false"}';
        final String SUPPORT_DATA_POSR_RESPONSE = '{"userEmail":"testfn01rone@yopmail.com","firstName":"Test","lastName":"Rone","storefrontURL":"","encryptedParameters":"xpkEm","success":"true","isPunchoutUser":"true","message":"Punchout User Successfully Logged In","userId":"005D600000BQDGtIAP","punchoutAccount":{"accountLogo":""}}';
        final String SUPPORT_DATA_POOM_REQUEST = '{"userId":"","varCurrencyCode":"USD","varEffectiveAccountId":"001D600001j8Zy5IAE","varOperationType":"GetCartItems","varWebstoreId":"0ZED60000004FqtOAE","varIsPunchoutUser":"true","varUserName":"testfn01rone@yopmail.com","varAccountName":"Citra","varAccountNumber":"11223344"}';
        final String SUPPORT_DATA_POOM_RESPONSE = '{"webstoreId":"0ZED60000004FqtOAE","userName":"testfn01rone@yopmail.com","userId":null,"uniqueProductCount":0,"type":"Cart","totalTaxAmount":"0.00","totalSaving":null,"totalPromotionalAdjustmentAmount":"0.00","totalProductCount":"0","totalProductAmountAfterAdjustments":"0.00","totalProductAmount":"0.00","totalListPrice":"0.00","totalChargeAmount":"0.00","taxType":"Net","status":"Active","purchaseOrderNumber":null,"ownerId":"005D600000BQDGtIAP","name":"Cart","messagesSummary":null,"isSecondary":false,"isPunchoutUser":true,"grandTotalAmount":"0.00","currencyIsoCode":"USD","cartItems":[],"cartId":"0a6D6000000CeIYIA0","accountNumber":"11223344","accountName":"Citra","accountId":"001D600001j8Zy5IAE"}';
        
        ECOM_Application_Logs__c exc;
        
        List<ECOM_Application_Logs__c> logs = new List<ECOM_Application_Logs__c>();
        
        exc = ECOM_ApplicationLogsUtil.logApplicationApiData(MODULE_NAME , CLASS_NAME , METHOD_NAME,SUPPORT_DATA_POSR_REQUEST,RESPONSE);
        exc.ECOM_Log_Type__c = 'POSR Request';
        logs.add(exc);
        
        exc = ECOM_ApplicationLogsUtil.logApplicationApiData(MODULE_NAME , CLASS_NAME , METHOD_NAME,SUPPORT_DATA_POSR_RESPONSE,RESPONSE);
        exc.ECOM_Log_Type__c = 'POSR Response';
        logs.add(exc);
        
        exc = ECOM_ApplicationLogsUtil.logApplicationApiData(MODULE_NAME , CLASS_NAME , METHOD_NAME,SUPPORT_DATA_POOM_REQUEST,RESPONSE);
        exc.ECOM_Log_Type__c = 'POOM Request';
        logs.add(exc);
        
        exc = ECOM_ApplicationLogsUtil.logApplicationApiData(MODULE_NAME , CLASS_NAME , METHOD_NAME,SUPPORT_DATA_POOM_RESPONSE,RESPONSE);
        exc.ECOM_Log_Type__c = 'POOM Response';
        logs.add(exc);
        
        upsert(logs);
    }
    
    //method to creae dummy PunchoutServiceRequest
    public static ECOM_PunchoutWrapper.PunchoutServiceRequest createPunchoutServiceRequest(){
        ECOM_PunchoutWrapper.PunchoutServiceRequest requestModel = new ECOM_PunchoutWrapper.PunchoutServiceRequest();
        requestModel.userEmail='revvvity@test.org';
        requestModel.firstName='TestRevv';
        requestModel.lastName='TestLast';
        requestModel.locale='en_US';
        requestModel.currencyCode='USD';
        requestModel.uniqueName='CITRA';
         requestModel.fromCredentialIdentity='CITRA';
        requestModel.countryCode='US';
        //requestModel.accountId='001D600001j8Zy5IAE';
        requestModel.country='US';
        return requestModel;
    }
    
     //method to create dummy pageparammap
    public static Map<String,String> createPageParamsMap(){
        Map<String,String> paramMap = new Map<String,String>();
        paramMap.put('punchoutCode','testpunchoutCode');
        paramMap.put('punchoutToken','testpunchoutToken');
        paramMap.put('storefrontURL','teststorefrontURL');
        paramMap.put('userId','testuserId');


        return paramMap;
    }
    
    /**
     * @description This method returns a new ERP Address related to provided master address
     * @author vramachandran@rafter.one | 29 Jan 2024
     * @param masterAddress | ERP_Address__c
     * @param releatedAddressType | String
     * @returns ERP_Address__c
     */
    public static ERP_Address__c createNewApprovedAddress(ERP_Address__c masterAddress, String relatedAddressType){

        ERP_Address__c relatedErpAddress = new ERP_Address__c();
        
        relatedErpAddress.Address_Type__c = relatedAddressType;
        relatedErpAddress.Address_Street_Line_1__c = masterAddress.Address_Street_Line_1__c;
        relatedErpAddress.Address_City__c = masterAddress.Address_City__c;
        relatedErpAddress.apiState__c = masterAddress.apiState__c;
        relatedErpAddress.Address_Postal_Code__c = masterAddress.Address_Postal_Code__c;
        relatedErpAddress.apiCountry__c = masterAddress.apiCountry__c;
        relatedErpAddress.ECOM_isEnabled__c = true;
        relatedErpAddress.ECOM_Punchout_Is_Enabled__c=true;
       
        relatedErpAddress.Target_Address__c = masterAddress.Id;
        relatedErpAddress.Master_Address__c = masterAddress.Id;
        relatedErpAddress.ERP_Marked_for_Deletion__c = false ;
        relatedErpAddress.ECOM_Review_Status__c = 'Approved';
        relatedErpAddress.ECOM_Punchout_Customer_Id__c ='CITRA';
        insert relatedErpAddress;
        return relatedErpAddress;
    }

    public static ERP_Address__c createNewPunchoutMasterAddressConfiguration(){
        Id erpDefaultRT = [SELECT Id FROM RecordType where SobjectType ='ERP_Address__c' AND DeveloperName='Default' LIMIT 1].Id;
        ERP_Address__c erpAddress = new ERP_Address__c();
        erpAddress.RecordTypeId = erpDefaultRT;
        erpAddress.Address_Street_Line_1__c = '8000 Regency Parkway';
        erpAddress.Address_City__c = 'Cary';
        erpaddress.Address_State__c = 'NC';
        erpAddress.Address_Country__c = 'US';
        erpAddress.Address_Postal_Code__c = '27518';

        erpAddress.CurrencyIsoCode = 'USD';
        erpAddress.Address_Type__c = 'Master';
        
        erpAddress.ECOM_Review_Status__c = 'Approved';
        erpAddress.ECOM_POSR_Sender_Shared_Identity__c = 'RVVTY';
        erpAddress.ECOM_POSR_Sender_Shared_Secret__c = 'SharedSecret';
        erpAddress.ECOM_Punchout_Account_TimeZone_SID__c = 'America/New_York';
        //erpAddress.ECOM_Punchout_Country_Locale__c = 'us-en';
        erpAddress.ECOM_Punchout_Customer_Id__c = 'RVTYPNCHOUT';
        erpAddress.ECOM_Punchout_Customer_Logo__c = '';
        erpAddress.ECOM_Punchout_Customer_Name__c = 'Revvity Punchout';
        erpAddress.ECOM_Punchout_Format__c = 'cXML';
        erpAddress.ECOM_Punchout_Is_Enabled__c = true;
        erpAddress.ECOM_Punchout_Processors__c = 'HazardousTrueFalse';
        erpAddress.ECOM_Punchout_Products_Include_Query__c = 'SHOW Product WHERE Radioactive = TRUE';
        erpAddress.ECOM_Punchout_Show_List_Price__c = true;
        erpAddress.ECOM_Punchout_Unit_Of_Measurement__c = 'EA';
        erpAddress.ECOM_isEnabled__c = true;
        erpAddress.External_Id__c = '123444444';
        erpAddress.SAP_Name_1__c = '11122333';
        erpAddress.CurrencyIsoCode = 'USD';
        erpAddress.ECOM_Punchout_Default_Payer__c = '123444444'; //RWPS-2830
        
        insert erpAddress;
        return erpAddress;
    }
    
    public static void createRelatedAddresses(Account newAccount, ERP_Address__c masterAddress){
        List<ERP_Address__c> newAddressList = new List<ERP_Address__c>();
        Id erpDefaultRT = [SELECT Id FROM RecordType where SobjectType ='ERP_Address__c' AND DeveloperName='Default' LIMIT 1].Id;
        //ShipTo
        ERP_Address__c shipToAddress = new ERP_Address__c(Account__c = newAccount.Id, 
                                                          ECOM_Punchout_Is_Enabled__c=true,
                                                          ECOM_isEnabled__c=true,
                                                          ECOM_Review_Status__c = 'Approved', 
                                                          Address_Street_Line_1__c = masterAddress.Address_Street_Line_1__c,
                                                          Address_City__c = masterAddress.Address_City__c,
                                                          Address_State__c = masterAddress.Address_State__c,
                                                          Address_Country__c = masterAddress.Address_Country__c,
                                                          Address_Postal_Code__c = masterAddress.Address_Postal_Code__c,
                                                          Target_Address__c = masterAddress.Id,
                                                          Master_Address__c = masterAddress.Id,
                                                          Address_Type__c = 'Ship To',
                                                          RecordTypeId = erpDefaultRT);
        insert shipToAddress;
        newAddressList.add(shipToAddress);
        //SoldTo
        ERP_Address__c soldToAddress = new ERP_Address__c(Account__c = newAccount.Id, 
                                                          ECOM_Punchout_Is_Enabled__c=true,
                                                          ECOM_isEnabled__c=true,
                                                          ECOM_Review_Status__c = 'Approved',
                                                          Target_Address__c = masterAddress.Id,
                                                          Master_Address__c = masterAddress.Id,
                                                          Address_Type__c = 'Sold To',
                                                          RecordTypeId = erpDefaultRT);
        insert soldToAddress;
        newAddressList.add(soldToAddress);
        //BillTo
        ERP_Address__c billToAddress = new ERP_Address__c(Account__c = newAccount.Id, 
                                                          ECOM_Punchout_Is_Enabled__c=true,
                                                          ECOM_isEnabled__c=true,
                                                          ECOM_Review_Status__c = 'Approved',
                                                          Target_Address__c = masterAddress.Id,
                                                          Master_Address__c = masterAddress.Id,
                                                          Address_Type__c = 'Bill To',
                                                          RecordTypeId = erpDefaultRT);
        insert billToAddress;
        newAddressList.add(billToAddress);
        //Payer
        ERP_Address__c payerToAddress = new ERP_Address__c(Account__c = newAccount.Id, 
                                                          ECOM_Punchout_Is_Enabled__c=true,
                                                          ECOM_isEnabled__c=true,
                                                          ECOM_Review_Status__c = 'Approved',
                                                          Target_Address__c = masterAddress.Id,
                                                          Master_Address__c = masterAddress.Id,
                                                          Address_Type__c = 'Payer',
                                                          RecordTypeId = erpDefaultRT);
        insert payerToAddress;
        newAddressList.add(payerToAddress);
        System.debug('JSON:: '+ JSON.serialize(newAddressList));
        //insert newAddressList;
    }    
    
    public static void createPunchoutLoginData(){
        Account newAccount = createAccount();
        Contact newContact = createNewContact(newAccount);
        insert newContact;
        User portalUser = createPortalUser(newContact);
        ERP_Address__c masterAddress = createNewPunchoutMasterAddressConfiguration();
        createRelatedAddresses(newAccount, masterAddress);
        List<ERP_Address__c> addresses = [SELECT Id, ECOM_Punchout_Is_Enabled__c, ECOM_isEnabled__c,ECOM_Review_Status__c,
                                         ERP_Marked_for_Deletion__c,ECOM_Punchout_Customer_Id__c, fxIsECOMenabled__c,
                                          Master_address__c, Target_Address__c
                                         FROM ERP_Address__c  LIMIT 49999];
        System.debug('createPunchoutLoginData:Address:: '+ JSON.serialize(addresses));
        System.debug('createPunchoutLoginData:getPunchoutAddressesForERPAddressModel:: '+ JSON.serialize(ERP_AddressRepo.getPunchoutAddressesForERPAddressModel('RVTYPNCHOUT')));
    }
    
    public static ECOM_PunchoutWrapper.PunchoutServiceRequest createPOSRModelForRevvityPunchoutForExistingUser(){
        
        User userRecord = [SELECT Id, FirstName, LastName, Email, UserName 
                           FROM User 
                           ORDER BY CREATEDDATE DESC
                           LIMIT 1];
        ECOM_PunchoutWrapper.PunchoutServiceRequest requestModel = new ECOM_PunchoutWrapper.PunchoutServiceRequest();
        
        String testUserConfig = ECOM_Util.getStoreNavigationConfig(System.Label.ECOM_TestUserConfigMetadata);
        
        if(String.isNotEmpty(testUserConfig)){
            requestModel = (ECOM_PunchoutWrapper.PunchoutServiceRequest) JSON.deserialize(testUserConfig, ECOM_PunchoutWrapper.PunchoutServiceRequest.class);   
            requestModel.fromCredentialDomain = 'RVTYPNCHOUT';
            requestModel.toCredentialDomain = 'RVTYPNCHOUT';
            requestModel.fromCredentialIdentity = 'RVTYPNCHOUT';
            requestModel.firstName = userRecord.FirstName;
            requestModel.lastName = userRecord.LastName;
            requestModel.userEmail = userRecord.Email;
            
        }
        
        return requestModel;
    }
    
    public static ECOM_PunchoutWrapper.PunchoutServiceRequest createPOSRModelForRevvityPunchoutForNewUser(){
        
        ECOM_PunchoutWrapper.PunchoutServiceRequest requestModel = new ECOM_PunchoutWrapper.PunchoutServiceRequest();
        
        String testUserConfig = ECOM_Util.getStoreNavigationConfig(System.Label.ECOM_TestUserConfigMetadata);
        
        //List<User> userRecords = [SELECT Id, Username, Email FROM USER WHERE ECOM_Is_Punchout_User__c = true ORDER BY CreatedDate DESC LIMIT 1];
        
        if(String.isNotEmpty(testUserConfig)){
            requestModel = (ECOM_PunchoutWrapper.PunchoutServiceRequest) JSON.deserialize(testUserConfig, ECOM_PunchoutWrapper.PunchoutServiceRequest.class);   
            requestModel.fromCredentialDomain = 'RVTYPNCHOUT';
            requestModel.toCredentialDomain = 'RVTYPNCHOUT';
            requestModel.fromCredentialIdentity = 'RVTYPNCHOUT';
            requestModel.firstName = 'NewUser';
            requestModel.lastName = 'Test';
            //if(null == userRecords && userRecords.isEmpty()){
            requestModel.userEmail = String.valueOf(System.now().millisecond()) + '@RevvityPunchout.xyz' ;
            //} else {
            //    requestModel.userEmail = userRecords[0].Email;
            //}
            
            requestModel.locale = 'en_US';
            requestModel.timezoneSidKey = 'America/New_York';
            requestModel.supplierPartId = '123123';
            requestModel.selectedItem ='123444';
            
        }
        
        return requestModel;
    }


   public static void createPunchoutData(){
        Account newAccount =ECOM_TestUtil.createAccount('TestClassPO');
        Contact newContact = createNewContact(newAccount);
        insert newContact;
        User portalUser = createPOPortalUser(newContact);
        ERP_Address__c masterAddress = createNewPunchoutMasterAddressConfiguration();
        createRelatedAddresses(newAccount, masterAddress);
        List<ERP_Address__c> address = [SELECT Id, ECOM_isEnabled__c, fxIsECOMenabled__c, ECOM_Review_Status__c, Address_Type__c, MDM_Customer_Status__c, Address_Street_Line_1__c, RecordType.Name, Address_Street_Line_2__c, Address_City__c, Address_State__c, Address_Country__c, apiState__c, Address_Postal_Code__c, apiCountry__c, fxAddress_City__c, fxAddress_CountryCode__c, fxAddress_Postal__c, fxAddress_StateName__c, fxAddress_Street__c, fxAddressFull__c, External_Id__c, CurrencyIsoCode, fxAddress_CountryName__c, ERP_Account_Group__c, ERP_Customer_Number__c, ERP_Sales_Org__c, ERP_Account_Name__c, ERP_Marked_for_Deletion__c, ERP_Partner_Code__c, Account__c, Account__r.Name, Account__r.CurrencyIsoCode, Contact__c, ECOM_Punchout_Is_Enabled__c, ECOM_Punchout_Customer_Id__c, ECOM_Punchout_Customer_Logo__c, ECOM_Punchout_Customer_Name__c, ECOM_Punchout_Products_Exclude_Query__c, ECOM_Punchout_Products_Include_Query__c, ECOM_Punchout_Show_List_Price__c, ECOM_Punchout_Unit_Of_Measurement__c, ECOM_POSR_Sender_Shared_Identity__c, ECOM_POSR_Sender_Shared_Secret__c, ECOM_Punchout_Format__c, ECOM_Punchout_Account_TimeZone_SID__c, ECOM_Punchout_Processors__c, ECOM_Punchout_Country_Locale__c, ECOM_Punchout_Default_UNSPSC__c, ECOM_Punchout_Sales_Org__c, ECOM_Punchout_Default_Payer__c, MDM_Cluster_Id__c, Default_Domain__c FROM ERP_Address__c WHERE ERP_Marked_for_Deletion__c = FALSE AND RecordType.DeveloperName = 'Default' AND ECOM_Review_Status__c = 'Approved' AND fxIsECOMenabled__c = TRUE AND ECOM_Punchout_Customer_Id__c = null];
        System.debug('address debug' +address);     

        List<ERP_Address__c> addresses = [SELECT Id, ECOM_Punchout_Is_Enabled__c, ECOM_isEnabled__c,ECOM_Review_Status__c,
                                         ERP_Marked_for_Deletion__c,ECOM_Punchout_Customer_Id__c, fxIsECOMenabled__c,
                                          Master_address__c, Target_Address__c
                                         FROM ERP_Address__c  LIMIT 49999];
        System.debug('createPunchoutLoginData:Address:: '+ JSON.serialize(addresses));
        System.debug('createPunchoutLoginData:getPunchoutAddressesForERPAddressModel:: '+ JSON.serialize(ERP_AddressRepo.getPunchoutAddressesForERPAddressModel('RVTYPNCHOUT')));
    }
    
    public static String createPunchoutDataForAccount(){
        List<Account> accounts = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1];
        ERP_Address__c masterAddress = createNewPunchoutMasterAddressConfiguration();
        createRelatedAddresses(accounts[0], masterAddress);
        List<ERP_Address__c> addresses = [SELECT Id, ECOM_Punchout_Is_Enabled__c, ECOM_isEnabled__c,ECOM_Review_Status__c,
                                         ERP_Marked_for_Deletion__c,ECOM_Punchout_Customer_Id__c, fxIsECOMenabled__c,
                                          Master_address__c, Target_Address__c
                                         FROM ERP_Address__c  LIMIT 49999];
        System.debug('createPunchoutLoginData:Address:: '+ JSON.serialize(addresses));
        System.debug('createPunchoutLoginData:getPunchoutAddressesForERPAddressModel:: '+ JSON.serialize(ERP_AddressRepo.getPunchoutAddressesForERPAddressModel('RVTYPNCHOUT')));
        return accounts[0].Id;
    }
    
    /**
     * @description This method returns a new Punchout store configuration for different users
     * @author vramachandran@rafter.one | 05 Feb 2024
     * @returns ECOM_Store_Punchout_Configuration__mdt
     */
    public static ECOM_Store_Punchout_Configuration__mdt getPunchoutStoreConfig(){
        ECOM_Store_Punchout_Configuration__mdt punchoutMetadata = new ECOM_Store_Punchout_Configuration__mdt();
        punchoutMetadata.Value_Rt__c = '{"punchoutUser":{"viewProfileSettingPage":false,"viewDashboard":false,"viewAccountPage":false,"viewOrderPage":true,"viewRecentOrders":false,"viewFavourites":true,"viewFrequentlyPurchased":true,"viewQuickOrder":true,"viewLogout":false,"isPunchoutUser":true,"storeForwardingUrl":"/createsession"},"punchoutUserWeb":{"viewProfileSettingPage":false,"viewDashboard":false,"viewAccountPage":false,"viewOrderPage":true,"viewRecentOrders":false,"viewFavourites":true,"viewFrequentlyPurchased":true,"viewQuickOrder":true,"viewLogout":true,"isPunchoutUser":true,"storeForwardingUrl":"/createsession"},"storeTestUser":{"viewProfileSettingPage":false,"viewDashboard":false,"viewAccountPage":false,"viewOrderPage":true,"viewRecentOrders":false,"viewFavourites":true,"viewFrequentlyPurchased":true,"viewQuickOrder":true,"viewLogout":false,"isPunchoutUser":true,"isStoreTestUser":true,"storeForwardingUrl":"/createsession"},"cmsStoreUser":{"viewProfileSettingPage":true,"viewDashboard":true,"viewAccountPage":true,"viewOrderPage":true,"viewRecentOrders":true,"viewFavourites":true,"viewFrequentlyPurchased":false,"viewQuickOrder":true,"viewLogout":true,"storeForwardingUrl":""}}' ;
        return punchoutMetadata;
    }
    
    public static User getPunchoutUser(){
        User userRecord;
        List<User> punchoutUsers = [SELECT Id, Name, FirstName, Lastname, Phone, Fax, Email, ContactId, Contact.Name, Contact.AccountId, 
                                    Contact.fxDomain__c, Account.Name, Contact.ECOM_CountryProvided__c,
                                    Contact.Default_Ship_to_ERP_Address__c, Contact.Default_Bill_to_ERP_Address__c,
                                    Contact.Default_Bill_to_ERP_Address__r.Account__r.Name,Contact.Default_Bill_to_ERP_Address__r.ERP_Account_Name__c,
                                    Contact.Default_Bill_to_ERP_Address__r.fxAddress_Street__c,Contact.Default_Bill_to_ERP_Address__r.fxAddress_StateName__c,
                                    Contact.Default_Bill_to_ERP_Address__r.fxAddress_City__c,Contact.Default_Bill_to_ERP_Address__r.fxAddress_CountryName__c,
                                    Contact.Default_Bill_to_ERP_Address__r.fxAddress_Postal__c,Contact.Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c,
                                    
                                    Country, UserName, ECOM_Is_Punchout_User__c, AccountId
                                    FROM User 
                                    WHERE ECOM_Is_Punchout_User__c = true
                                    LIMIT 1 ];
        if(null != punchoutUsers && !punchoutUsers.isEmpty()){
            userRecord = punchoutUsers[0];
        }
        
        return userRecord;
    }
    
    public static String getPunchoutAccoutId(){
        String accountId='';
        List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'TestClassPO' LIMIT 1];
        if(null != accounts && !accounts.isEmpty()){
            accountId = accounts[0].Id;
        }
        return accountId;
    }
    
    public static ERP_AddressModel getAddressModel(){
        final String PUNCHOUT_IDENTIFIER = 'RVTYPNCHOUT';
        ERP_AddressModel addressModel = ERP_AddressUtil.getPunchoutAddressesForERPAddressModel(PUNCHOUT_IDENTIFIER);
        return addressModel;
    }
    
    public static List<ERP_Address__c> addNewAddress(List<ERP_Address__c> newAddresses){
        ERP_address__c shipTo = newAddresses[0];
        ERP_Address__c erpAddress = new ERP_Address__c();
        erpAddress.Contact__c =shipTo.Contact__c;
        erpAddress.ERP_Account_Name__c = shipTo.ERP_Account_Name__c;
        erpAddress.Address_Type__c = 'Sold To';
        erpAddress.Address_Street_Line_1__c = 'newstreet';
        erpAddress.Address_City__c = 'newERPcity';
        erpAddress.apiState__c = 'newERPstate';
        erpAddress.Address_Postal_Code__c = 'newERPpostalCode';
        erpAddress.apiCountry__c = 'United States';
        erpAddress.ECOM_isEnabled__c = true;
        erpAddress.Master_Address__c = shipTo.Master_Address__c;
        erpAddress.Target_Address__c = shipTo.Master_Address__c;
        
        newAddresses.add(erpAddress);
        ERP_Address__c Payer = new ERP_Address__c();
        Payer.Contact__c = shipTo.Contact__c;
        Payer.ERP_Account_Name__c = shipTo.ERP_Account_Name__c;
        Payer.Address_Type__c = 'Payer';
        Payer.Address_Street_Line_1__c = 'newstreet';
        Payer.Address_City__c = 'newERPcity';
        Payer.apiState__c = 'newERPstate';
        Payer.Address_Postal_Code__c = 'newERPpostalCode';
        Payer.apiCountry__c = 'United States';
        Payer.ECOM_isEnabled__c = true;
        Payer.Master_Address__c = shipTo.Master_Address__c;
        Payer.Target_Address__c = shipTo.Master_Address__c;
        newAddresses.add(Payer);
        
        return newAddresses;
    }
    
}