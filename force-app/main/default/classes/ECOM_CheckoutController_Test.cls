/**************************************************************

* 1. Jira Ticket(s) that relates to this class
*  
* 2. Description - This class is a test class for ECOM_CheckoutController.
					- Call the ECOM_TestUtil Class to create test data and test each methods.
					- Used System Assertion to Confirm the functionalities.
* 3. Objects referenced
*    - Account
*    - Contact
*    - User
*    - Network
*    - WebCart
*    - Order
*    - Product2
*    - WishList
* 
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_TestUtil
*    - ECOM_CheckoutController
*
* 6. Test Class Name:
*    -None
*
* 7. Is @Invocable : No
*
* 8. Author Name(s):
*    - Manoj 2023.09.19
*    - Sidak 2024.03.27 RWPS-394 - Replaced ECOM_POSR_Browser_Form_Post__c with ECOM_POSR_Browser_Form_Post_Url__c
*    - Gaurang 2024.04.09 RWPS-460 - Test class change for new parameter
*    - Sidak 2024.04.22 RWPS-416 - Added method testgetCharityNumberValue
* 	 - Gaurav 2025.02.18 RWPS-2547 - added code coverage logic for getSAPOrderNumber
*    - Prabhat 2025.02.28 Updated methods testGetAddressInfocase2, testCheckIfPoUsed, testGetOrderConfirmationDetails to increase code coverage - RWPS-2721
*    - Poonam 2025.06.30  Added testgetCartTaxExemptValue_NoCartFound to increase code coverage - RWPS-1882
* 	 - Gaurav 2025.08.29  Added testGetParentPartNumber for code coverage logic - RWPS-3811
*************************************************************/


@isTest(SeeAllData=false)
private with sharing class ECOM_CheckoutController_Test {

    // Set up test data
    @TestSetup
    static void setupTestData() {
        Map<String,Object> respponse = ECOM_TestUtil.initialStorefrontSetup();
    }
    
   // Test the getAddressInfo method
   @isTest
    static void testGetAddressInfo() {
        User testUser=[SELECT Id,Name FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
       	WebCart cart = [SELECT Id,Default_Bill_to_ERP_Address__c,Default_Ship_to_ERP_Address__c FROM WebCart LIMIT 1];
        ERP_Address__c testAdd = new ERP_Address__c();
        testAdd.Address_Type__c = 'Payer';
        testAdd.SAP_Name_1__c = 'testsapname';
        insert testAdd;
        cart.Default_Bill_to_ERP_Address__c=testAdd.Id;
        cart.Default_Ship_to_ERP_Address__c=testAdd.Id;
        update cart;
        //Running as testUser
        System.runAs(testUser){
        //Call the  getAddressInfo Method
        Test.startTest();
        Map<String,Object> resultContact = ECOM_CheckoutController.getAddressInfo(cart.Id);
        Test.stopTest();
        
        //Validating result
        System.assertEquals('Success',resultContact.get('Status'),'Expected Success');
        }
    }
  @isTest
    static void testGetAddressInfocase2() {
        User testUser=[SELECT Id,Name FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
       	WebCart cart = [SELECT Id,Default_Bill_to_ERP_Address__c,Default_Ship_to_ERP_Address__c FROM WebCart LIMIT 1];
        ERP_Address__c testAdd = new ERP_Address__c();
        testAdd.Address_Type__c = 'Ship To';
        testAdd.SAP_Name_1__c = 'testsapname';
        insert testAdd;
        cart.Default_Bill_to_ERP_Address__c=testAdd.Id;
        cart.Default_Ship_to_ERP_Address__c=testAdd.Id;
        cart.Default_Invoice_ERP_Address__c=testAdd.Id;//RWPS-2786
        update cart;
        //Running as testUser
        System.runAs(testUser){
        //Call the  getAddressInfo Method
        Test.startTest();
        Map<String,Object> resultContact = ECOM_CheckoutController.getAddressInfo(cart.Id);
        ECOM_CheckoutController.updateBillToShipToOnCart(cart.id);//RWPS-2721 
        Test.stopTest();
        
        //Validating result
        System.assertEquals('Success',resultContact.get('Status'),'Expected Success');
        }
    }    
    @isTest
    static void getCheckoutInItDataTest(){
    	// User testUser=[SELECT Id,Name FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        // testUser.ECOM_Is_Punchout_User__c =true; //RWPS-2346
        // update testUser; //RWPS-2346
        // Account acc = [SELECT Id FROM Account LIMIT 1];
         User testUser = [SELECT Id,AccountId, ContactId FROM User WHERE Username = 'testR1@test.org' ORDER BY CREATEDDATE DESC LIMIT 1];
          testUser.ECOM_Is_Punchout_User__c =true; //RWPS-2346
          update testUser;
        String acId = testUser.AccountId;
        Account acc = [SELECT Id FROM Account WHERE Id =: acId LIMIT 1];
        Test.startTest();
        Map<String,Object> result;
        System.runAs(testUser){
            result = ECOM_CheckoutController.getCheckoutInItData('',acc.Id);
        }
        Test.stopTest();
        //System.assertEquals('Success',result.get('Status'),'Not successful');
    }

   // Test the getAddressInfo method
   @isTest
    static void testSaveAdditionalShippingInfo() {
       User testUser=[SELECT Id,Name FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
       
        //Running test as testUser
       System.runAs(testUser){
       
        //Call the  saveAdditionalShippingInfo Method
        Test.startTest();
        Map<String, Object> responseMap = ECOM_CheckoutController.saveAdditionalShippingInfo('details', 'recipient', 'Other');
        Map<String, Object> responseMap1 = ECOM_CheckoutController.saveAdditionalShippingInfo('details', 'recipient', 'option not in pickList');
        Test.stopTest();
        
        //Validating result
        System.assertEquals('Success',responseMap.get('Status'),'Expected status be success');
       }
    }
     
    /*
    //Test method for getFieldsByObjectName Method
    @isTest
    static void testGetFieldsByObjectName() {
        User u = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        String objectName = 'WishListItem';        
        
        // Calling  the getFieldsByObjectName method
        Test.startTest(); 
        Map<String, String> fieldsMap;
        System.runAs(u){
             fieldsMap = ECOM_CheckoutController.getFieldsByObjectName(objectName);
        }
      
        Test.stopTest();
       
        // Assert the results
        System.assertEquals('Name', fieldsMap.get('Name'));
        
    }*/
    
     //Test method for getCartItems Method
  /*  @isTest
    static void testGetCartItems() {
        Account testAccount = [SELECT Id, Name FROM Account ORDER BY CREATEDDATE DESC LIMIT 1 ];       
        User testUser=[SELECT Id, Name FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        Network comm = [SELECT Id, Name FROM Network ORDER BY CREATEDDATE DESC limit 1]; 

        //Running test as testUser
        System.runAs(testUser){
        
        // Calling  the getFieldsByObjectName method
        Test.startTest();
        List<ECOM_CartModel> resultList = ECOM_CheckoutController.getCartItems(comm.Id,testAccount.Id);
        Test.stopTest();
       
        //Assert the results
        //System.assertEquals(1, resultList.size(),'Expected list size 1');
        }
    }*/
    
    //Test method for checkIfPoUsed and getEmailPreferences  Method
    @isTest
    static void testCheckIfPoUsed() {
        Account testAccount = [SELECT Id, Name FROM Account ORDER BY CREATEDDATE DESC LIMIT 1 ];       
        User testUser=[SELECT Id,Name, ContactId FROM User ORDER BY CREATEDDATE DESC LIMIT 1]; //RWPS-2721
		ERP_Address__c testAdd = new ERP_Address__c();
        insert testAdd;
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        con.Default_Ship_to_ERP_Address__c=testAdd.Id;
        update con;
        //START - RWPS-2721
        ECOM_Email_Preferences__c testPref = new ECOM_Email_Preferences__c();
        testPref.ERP_Address__c = testAdd.id;
        testPref.ECOM_isActive__c = true;
        testPref.ECOM_Contact__c = testUser.contactId;
        insert testPref;
        
        ECOM_Email_Preferences__c testPref1 = new ECOM_Email_Preferences__c();
        testPref1.ERP_Address__c = testAdd.id;
        testPref1.ECOM_isActive__c = true;
        insert testPref1;
        //END-RWPS-2721
        //Running test as testUser
        System.runAs(testUser){
        
        // Calling  the checkIfPoUsed method and getEmailPreferences
        Test.startTest();
        Boolean result = ECOM_CheckoutController.checkIfPoUsed(testAccount.Id,'PO1234');
        Map<String,Object> resultMap = ECOM_CheckoutController.getEmailPreferences(testAccount.Id); 

        Test.stopTest();
       
        //Assert the results
        System.assertEquals(false, result,'Expected False');
        System.assertEquals('Success', resultMap.get('Status'),'Expected Success status');
            
        }
    }

   
    //Test method for saveDataAndPlaceOrder Method
  /*  @isTest
    static void testSaveDataAndPlaceOrder() {
        Account testAccount = [SELECT Id, Name FROM Account ORDER BY CREATEDDATE DESC LIMIT 1 ];       
        User testUser=[SELECT Id,Name,Email FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        WebCart testCart = [SELECT Id, Name FROM WebCart ORDER BY CREATEDDATE DESC limit 1]; 
        Map<String,Object> paymentInfo = new Map<String,Object>();
        paymentInfo.put('poNumber','PO123');
        paymentInfo.put('promoCode','OFF12');
        paymentInfo.put('quoteNumber','QN123');
        
        //Running test as testUser
        System.runAs(testUser){
        
        // Calling  the saveDataAndPlaceOrder method
        Test.startTest();
        Map<String,Object> resultMap = ECOM_CheckoutController.saveDataAndPlaceOrder(testAccount.Id, testCart.Id, paymentInfo,'[{"ECOM_Order_Confirmation__c":true,"ECOM_Send_Invoice__c":true,"ECOM_Shipment_Notification__c":true,"ECOM_Email__c":"test3@gmail.com"}]','[{"ECOM_Account__c":"001DW00001QB1rvYAD","ECOM_Order_Confirmation__c":true,"ECOM_Send_Invoice__c":true,"ECOM_Contact__c":"003DW000015qlZ2YAI","ECOM_Shipment_Notification__c":true,"ECOM_Email__c":"tes3t4@gmail.com"}]');
        Test.stopTest();
       }
    }*/
    
    @isTest
    static void createOrUpdateEmailPreferencesTest(){
        User u = [SELECT Id FROM USER WHERE LastName = 'XYZ' LIMIT 1];
        Contact con = [SELECT Id,Email,Default_Ship_to_ERP_Address__c FROM Contact LIMIT 1];
        ERP_Address__c testAdd = new ERP_Address__c();
        insert testAdd;
        con.Default_Ship_to_ERP_Address__c=testAdd.Id;
        con.Email='test@email.com';
        update con;
        Map<String,Object> newEmailAddressRow = new Map<String,Object>();
        newEmailAddressRow.put('ECOM_Email__c',con.Email);
        newEmailAddressRow.put('ECOM_Order_Confirmation__c',true);
        newEmailAddressRow.put('ECOM_Send_Invoice__c',true);
        newEmailAddressRow.put('ECOM_Shipment_Notification__c',true);
        List<Map<String,Object>> newEmailAddressRows = new List<Map<String,Object>>();
        newEmailAddressRows.add(newEmailAddressRow);
        ECOM_Email_Preferences__c testPref = new ECOM_Email_Preferences__c();
        insert testPref;
        Map<String,Object> removeEmailPref = new Map<String,Object>();
        removeEmailPref.put('Id',testPref.Id);
        List<Map<String,Object>> removeEmailPrefList = new List<Map<String,Object>>();
        removeEmailPrefList.add(removeEmailPref);
        String jsonString = JSON.serialize(newEmailAddressRows);
        String removeEmailPrefListJson = JSON.serialize(removeEmailPrefList);
        Map<String,Object> result;
        System.runAs(u){
        Test.startTest();
        result = ECOM_CheckoutController.createOrUpdateEmailPreferences(jsonString,removeEmailPrefListJson);
        Test.stopTest();
        }
    }
    
        @isTest
    static void createOrUpdateEmailPreferencesExceptionTest(){
        User u = [SELECT Id FROM USER WHERE LastName = 'XYZ' LIMIT 1];
        Contact con = [SELECT Id,Email,Default_Ship_to_ERP_Address__c FROM Contact LIMIT 1];
        ERP_Address__c testAdd = new ERP_Address__c();
        insert testAdd;
        con.Default_Ship_to_ERP_Address__c=testAdd.Id;
        con.Email='test@email.com';
        update con;
        Map<String,Object> newEmailAddressRow = new Map<String,Object>();
        newEmailAddressRow.put('ECOM_Email__c',con.Email);
        newEmailAddressRow.put('ECOM_Order_Confirmation__c',true);
        newEmailAddressRow.put('ECOM_Send_Invoice__c',true);
        newEmailAddressRow.put('ECOM_Shipment_Notification__c',true);
        List<Map<String,Object>> newEmailAddressRows = new List<Map<String,Object>>();
        newEmailAddressRows.add(newEmailAddressRow);
        Map<String,Object> removeEmailPref = new Map<String,Object>();
        removeEmailPref.put('Id',con.Id);
        List<Map<String,Object>> removeEmailPrefList = new List<Map<String,Object>>();
        removeEmailPrefList.add(removeEmailPref);
        String jsonString = JSON.serialize(newEmailAddressRows);
        String removeEmailPrefListJson = JSON.serialize(removeEmailPrefList);
        Map<String,Object> result;
        System.runAs(u){
        Test.startTest();
        result = ECOM_CheckoutController.createOrUpdateEmailPreferences(jsonString,removeEmailPrefListJson);
        Test.stopTest();
        }
    }
    
   @isTest
    static void placeOrderTestCase1(){
        WebStore webStr = [SELECT Id FROM WebStore LIMIT 1];
        Contact con = [SELECT Id,OwnerId FROM Contact LIMIT 1];
        Product2 product = [SELECT Id, ProductCode FROM Product2 LIMIT 1];
        Account acc = [SELECT Id,IsBuyer FROM Account WHERE Name='TestClass Account' LIMIT 1];
        system.debug('Account: '+acc);
        Order ord = [SELECT Id FROM Order LIMIT 1];
        Contact custcon = new Contact(Email='test@yopmail.com',LastName='ECOM',AccountId=acc.Id);
        insert custcon;
        User custUser = ECOM_TestUtil.createPortalUser(custcon);
        custUser.ECOM_Is_Punchout_User__c=true;//RWPS-2346
        system.debug('User soql: '+[SELECT Id,Name,IsPortalEnabled FROM User WHERE Email LIKE '%test123@noemail.com' LIMIT 1]);
        List<PermissionSet> ps1 = [SELECT Id FROM PermissionSet WHERE Name = 'Buyer'];
        if(ps1 != NULL && ps1.size()>0){
            insert new PermissionSetAssignment(AssigneeId = custUser.Id, PermissionSetId = ps1[0].Id);
        }
        WebCart cart;
      //  System.runAs(custUser){//RWPS-2346
            cart = ECOM_TestUtil.createCart(acc,webStr,custUser);
            insert cart;
            system.debug('Cart: '+[SELECT Id,OwnerId,Owner.FirstName FROM WebCart WHERE OwnerId=:custUser.Id]);
            OrderDeliveryMethod OrderDeliveryMethod = ECOM_TestUtil.createOrderDeliveryMethod();
            insert OrderDeliveryMethod;
            CartDeliveryGroup cartDeliveryGroup = ECOM_TestUtil.createCartDeliveryGroup(cart, OrderDeliveryMethod.Id);
            insert cartDeliveryGroup;
            CartDeliveryGroupMethod CartDeliveryGroupMethod = ECOM_TestUtil.createCartDeliveryGroupMethod(cart.Id, cartDeliveryGroup.Id, OrderDeliveryMethod.Id);
            insert CartDeliveryGroupMethod;
            CartItem cartItem = ECOM_TestUtil.createCartItem(cart,cartDeliveryGroup,product);
            insert cartItem;
      //  } //RWPS-2346
        System.runAs(custUser){
            CartCheckoutSession checkout = new CartCheckoutSession();
            checkout.Name='testSession';
            checkout.State='Start';
            checkout.OrderId = ord.Id;
            checkout.WebCartId = cart.Id;
            checkout.NextState='cartToOrder';
            checkout.IsError=false;
            checkout.IsArchived=false;
            insert checkout;
        }
        Map<String,Object> paymentDataMap = new Map<String,Object>();
        paymentDataMap.put('promoCode','test123');
        paymentDataMap.put('quoteNumber','test123');
        paymentDataMap.put('paymentMethod','po');
        paymentDataMap.put('paymentId','24234');
        paymentDataMap.put('poNumber','test123');
        paymentDataMap.put('quoteNumber','test123');
        test.startTest();
        Map<String,Object> result;
        System.runAs(custUser){
        	result = ECOM_CheckoutController.placeOrder(acc.Id, cart.Id, paymentDataMap, '2025-04-24', 'true' ,'testing','',''); //RWPS-1285
        }
        test.stopTest();
        system.debug('Result: '+result.get('Exception'));
        system.debug('Result stack trace: '+result.get('ExceptionStack'));
    }
    
   @isTest
    static void placeOrderTestCase2(){
        WebStore webStr = [SELECT Id FROM WebStore LIMIT 1];
        Contact con = [SELECT Id,OwnerId FROM Contact LIMIT 1];
        Product2 product = [SELECT Id, ProductCode FROM Product2 LIMIT 1];
        Account acc = [SELECT Id,IsBuyer FROM Account WHERE Name='TestClass Account' LIMIT 1];
        system.debug('Account: '+acc);
        Order ord = [SELECT Id FROM Order LIMIT 1];
        Contact custcon = new Contact(Email='test@yopmail.com',LastName='ECOM',AccountId=acc.Id);
        insert custcon;
        User custUser = ECOM_TestUtil.createPortalUser(custcon);
        system.debug('User soql: '+[SELECT Id,Name,IsPortalEnabled FROM User WHERE Email LIKE '%test123@noemail.com' LIMIT 1]);
        List<PermissionSet> ps1 = [SELECT Id FROM PermissionSet WHERE Name = 'Buyer'];
        if(ps1 != NULL && ps1.size()>0){
            insert new PermissionSetAssignment(AssigneeId = custUser.Id, PermissionSetId = ps1[0].Id);
        }
        WebCart cart;
      //  System.runAs(custUser){ //RWPS-2346
            cart = ECOM_TestUtil.createCart(acc,webStr,custUser);
            insert cart;
            system.debug('Cart: '+[SELECT Id,OwnerId,Owner.FirstName FROM WebCart WHERE OwnerId=:custUser.Id]);
            OrderDeliveryMethod OrderDeliveryMethod = ECOM_TestUtil.createOrderDeliveryMethod();
            insert OrderDeliveryMethod;
            CartDeliveryGroup cartDeliveryGroup = ECOM_TestUtil.createCartDeliveryGroup(cart, OrderDeliveryMethod.Id);
            insert cartDeliveryGroup;
            CartDeliveryGroupMethod CartDeliveryGroupMethod = ECOM_TestUtil.createCartDeliveryGroupMethod(cart.Id, cartDeliveryGroup.Id, OrderDeliveryMethod.Id);
            insert CartDeliveryGroupMethod;
            CartItem cartItem = ECOM_TestUtil.createCartItem(cart,cartDeliveryGroup,product);
            insert cartItem;
       // } //RWPS-2346
        System.runAs(custUser){
            CartCheckoutSession checkout = new CartCheckoutSession();
            checkout.Name='testSession';
            checkout.State='Start';
            checkout.OrderId = ord.Id;
            checkout.WebCartId = cart.Id;
            checkout.NextState='cartToOrder';
            checkout.IsError=false;
            checkout.IsArchived=false;
            insert checkout;
        }
        Map<String,Object> paymentDataMap = new Map<String,Object>();
        paymentDataMap.put('promoCode','test123');
        paymentDataMap.put('quoteNumber','test123');
        paymentDataMap.put('paymentMethod','cc');
        paymentDataMap.put('paymentId','test1234');
        paymentDataMap.put('paymentAuthorization','test1234');
        paymentDataMap.put('poNumber','test123');
        paymentDataMap.put('quoteNumber','test123');
        paymentDataMap.put('paymentmethodfirstname','test');
        paymentDataMap.put('paymentmethodlastname','test');
        paymentDataMap.put('paymentmethodemail','test@email.com');
        paymentDataMap.put('paymentmethodlast4',1234);
        paymentDataMap.put('paymentmethodtype','CC');
        paymentDataMap.put('paymentmode','CC');
        paymentDataMap.put('paymentmethodexpirationmonth',09);
        paymentDataMap.put('paymentmethodexpirationyear',2030);
        paymentDataMap.put('paymentmethodstreet','test');
        paymentDataMap.put('paymentmethodcity','test');
        paymentDataMap.put('paymentmethodcountry','United States');
        paymentDataMap.put('paymentmethodzip','123456');
        paymentDataMap.put('paymentmethodstate','California');
        paymentDataMap.put('totaltransactionamount',100);
        paymentDataMap.put('currencycode','USD');
        paymentDataMap.put('authorizationnumber','test1234');
        paymentDataMap.put('merchantid','test1234');
        paymentDataMap.put('paymentmethodtoken','test1234');
        paymentDataMap.put('pgtext','test1234');
        paymentDataMap.put('pgtransactionid','test1234');
        paymentDataMap.put('transactionstatus','Success');
        paymentDataMap.put('transactiontype','Online');
        test.startTest();
        Map<String,Object> result;
        System.runAs(custUser){
        	result = ECOM_CheckoutController.placeOrder(acc.Id, cart.Id, paymentDataMap, 'placeOrder', 'true', 'testing','ABC@YOPMAIL.COM',''); //RWPS-1285
        }
        test.stopTest();
        system.debug('Result: '+result.get('Exception'));
        system.debug('Result stack trace: '+result.get('ExceptionStack'));
    }
    
    @isTest
    static void getWishlistDetailsWrapped(){
        User u = [SELECT ID FROM User WHERE LastName = 'XYZ' LIMIT 1];
        System.runAs(u){
            Test.startTest();
            List<ECOM_AccountWrapper.WishlistDetails> response = ECOM_CheckoutController.getWishlistDetailsWrapped();
            Test.stopTest();
        }
    }
    
    @isTest
    static void getShippingChargeProduct2IdTest(){
        OrderDeliveryMethod odm = [SELECT Id,ProductId FROM OrderDeliveryMethod LIMIT 1];
        Test.startTest();
        Id response = ECOM_CheckoutController.getShippingChargeProduct2Id(odm.Id);
        Test.stopTest();
        System.assertEquals(odm.ProductId,response,'Product Ids are different');
    }
    
    @isTest
    static void getDefaultOrderDeliveryMethodElse1Test(){
    	OrderDeliveryMethod OrderDeliveryMethod = new OrderDeliveryMethod(Name = ECOM_Constant.DEFAULT_DELIVERY_METHOD);
        insert OrderDeliveryMethod;
        test.startTest();
        Id response = ECOM_CheckoutController.getDefaultOrderDeliveryMethod();
        test.stopTest();
        System.assertEquals(OrderDeliveryMethod.Id,response,'OrderDeliveryMethodIds are not same');
    }
    
    @isTest
    static void getDefaultOrderDeliveryMethodElse2Test(){
        Product2 testProd = [SELECT Id FROM Product2 LIMIT 1];
    	OrderDeliveryMethod OrderDeliveryMethod = new OrderDeliveryMethod(Name = ECOM_Constant.DEFAULT_DELIVERY_METHOD,ProductId=testProd.Id);
        insert OrderDeliveryMethod;
        Id response = ECOM_CheckoutController.getDefaultOrderDeliveryMethod();
        System.assertEquals(OrderDeliveryMethod.Id,response,'OrderDeliveryMethodIds are not same');
    }
    
   /* RWPS-1285 @isTest
    static void placeOrderExceptionTest(){
        Map<String,Object> result = ECOM_CheckoutController.placeOrder('','',new Map<String,Object>(),'','');
    }
    */
    //Test method for getOrderConfirmationDetails Method
    @isTest
    static void testGetOrderConfirmationDetails() {
        Account testAccount = [SELECT Id, Name FROM Account ORDER BY CREATEDDATE DESC LIMIT 1 ];       
        User testUser=[SELECT Id,Name,Email FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        Network comm = [SELECT id, name FROM Network ORDER BY CREATEDDATE DESC limit 1]; 
        //START-RWPS-2721
        Webcart cart = [SELECT Id, Default_Ship_to_ERP_Address__c FROM Webcart ORDER BY CREATEDDATE DESC LIMIT 1];
        ERP_Address__c testAdd = new ERP_Address__c();
        testAdd.Address_Type__c = 'Payer';
        testAdd.ECOM_Approver_Enabled__c = true;
        testAdd.ECOM_RAD_Approval_Status__c = 'RAD';
        testAdd.SAP_Name_1__c = 'testsapname';
        insert testAdd;
        cart.Default_Bill_to_ERP_Address__c=testAdd.Id;
        cart.Default_Ship_to_ERP_Address__c=testAdd.Id;
        update cart;
        //END-RWPS-2721
        Order testOrder=[SELECT Id,Name FROM Order ORDER BY CREATEDDATE DESC LIMIT 1];
        testOrder.ECOM_Cart_Id__c = cart.Id;
        update testOrder;

        String objectName = 'WishListItem';        
        List<String> strList = new List<String>();
        strList.Add('Name');
        
        //Running test as testUser
        System.runAs(testUser){
        
        // Calling  the getOrderConfirmationDetails method
        Test.startTest();
        Map<String,Object> resultMap = ECOM_CheckoutController.getOrderConfirmationDetails(comm.Id, testAccount.Id, testOrder.Id, strList, objectName);
        Test.stopTest();
       
        // Assert the results
        //System.assertEquals('Success', resultMap.get('Status'),'Expected Success status');
        system.debug('response: '+resultMap.get('Exception'));
        
    }
 }
    
    @isTest
    static void testGetOrderConfirmationDetailsTestException(){
    	Map<String,Object> resultMap = ECOM_CheckoutController.getOrderConfirmationDetails('test', 'test', 'test', null, '');
    }
    
    //Test method for createAndAddToList Method
    @isTest
    static void testCreateAndAddToList() {
        Account testAccount = [SELECT Id, Name FROM Account ORDER BY CREATEDDATE DESC LIMIT 1 ];       
        Product2 testProduct=[SELECT Id,Name FROM Product2 ORDER BY CREATEDDATE DESC LIMIT 1];
        WishList testWishList=[SELECT Id,Name FROM WishList ORDER BY CREATEDDATE DESC LIMIT 1];
        Network comm = [SELECT id, name FROM Network ORDER BY CREATEDDATE DESC limit 1]; 
        User testUser=[SELECT Id,Name,Email FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        
        //Running test as testUser
        System.runAs(testUser){
        
        // Calling  the createAndAddToList method
        Test.startTest();
        //Scenario without passing wishlist Id
        ConnectApi.WishlistItem result1 = ECOM_CheckoutController.createAndAddToList(comm.Id,testProduct.Id,'',testAccount.Id);
       
        //Scenario in which wishlist Id is passed in parameter
        ConnectApi.WishlistItem result2 = ECOM_CheckoutController.createAndAddToList(comm.Id,testProduct.Id,testWishList.Id,testAccount.Id);
        Test.stopTest();
       
        //Assert the results
        System.assertEquals('product A', result1.productSummary.name,'Expected'+testProduct.Name);
        System.assertEquals('product A', result2.productSummary.name,'Expected'+testProduct.Name);
        }
    }
    
     //Test method for prepareCartForOrder Method
    @isTest
    static void testPrepareCartForOrder() {
        User testUser=[SELECT Id,Name,Email FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        WebCart testCart = [SELECT Id, Name FROM WebCart ORDER BY CREATEDDATE DESC limit 1]; 
        
        //Running test as testUser
        System.runAs(testUser){
        
        // Calling  the prepareCartForOrder method
        Test.startTest();
        ECOM_CheckoutController.prepareCartForOrder(testCart.Id);
        Test.stopTest();
       
        
        }
    }
    
     //Test method for getCartPromoCode Method
    @isTest
    static void testGetCartPromoCode() {
        User testUser=[SELECT Id,Name,Email FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        WebCart testCart = [SELECT Id, Name FROM WebCart ORDER BY CREATEDDATE DESC limit 1]; 
        Product2 testProduct=[SELECT Id,Name FROM Product2 ORDER BY CREATEDDATE DESC LIMIT 1];
        
        //Running test as testUser
        System.runAs(testUser){
        
        // Calling  the getCartPromoCode method
        Test.startTest();
        WebCart resultCart=ECOM_CheckoutController.getCartPromoCode(testCart.Id);
        Test.stopTest();
       
        //Assert the results
        System.assertEquals(testCart.Name, resultCart.Name,'Expected name'+testCart.Name);
        }
    }
    
    
    @isTest
    static void getCartandCartItemsByIdTest(){
        WebCart cart = [SELECT Id FROM WebCart LIMIT 1];
        Test.startTest();
        List<WebCart> carts = ECOM_CheckoutController.getCartandCartItemsById(cart.Id);
        Test.stopTest();
        System.assertEquals(cart.Id,carts[0].Id,'Cart Id do not match');
    }
       @isTest
    static void testcreateCreditCardPayment(){
        WebStore webStr = [SELECT Id FROM WebStore LIMIT 1];
        Contact con = [SELECT Id,OwnerId FROM Contact LIMIT 1];
        Product2 product = [SELECT Id, ProductCode FROM Product2 LIMIT 1];
        Account acc = [SELECT Id,IsBuyer FROM Account WHERE Name='TestClass Account' LIMIT 1];
        system.debug('Account: '+acc);
        Order ord = [SELECT Id FROM Order LIMIT 1];
        Contact custcon = new Contact(Email='test@yopmail.com',LastName='ECOM',AccountId=acc.Id,ECOM_CountryProvided__c ='USA');
        insert custcon;
        User custUser = ECOM_TestUtil.createPortalUser(custcon);
        system.debug('User soql: '+[SELECT Id,Name,IsPortalEnabled FROM User WHERE Email LIKE '%test123@noemail.com' LIMIT 1]);
        List<PermissionSet> ps1 = [SELECT Id FROM PermissionSet WHERE Name = 'Buyer'];
        if(ps1 != NULL && ps1.size()>0){
            insert new PermissionSetAssignment(AssigneeId = custUser.Id, PermissionSetId = ps1[0].Id);
        }
        WebCart cart;
        //System.runAs(custUser){ //RWPS-2346
            cart = ECOM_TestUtil.createCart(acc,webStr,custUser);
            insert cart;
            system.debug('Cart: '+[SELECT Id,OwnerId,Owner.FirstName FROM WebCart WHERE OwnerId=:custUser.Id]);
            OrderDeliveryMethod OrderDeliveryMethod = ECOM_TestUtil.createOrderDeliveryMethod();
            insert OrderDeliveryMethod;
            CartDeliveryGroup cartDeliveryGroup = ECOM_TestUtil.createCartDeliveryGroup(cart, OrderDeliveryMethod.Id);
            insert cartDeliveryGroup;
            CartDeliveryGroupMethod CartDeliveryGroupMethod = ECOM_TestUtil.createCartDeliveryGroupMethod(cart.Id, cartDeliveryGroup.Id, OrderDeliveryMethod.Id);
            insert CartDeliveryGroupMethod;
            CartItem cartItem = ECOM_TestUtil.createCartItem(cart,cartDeliveryGroup,product);
            insert cartItem;
        //}  //RWPS-2346
        System.runAs(custUser){
            CartCheckoutSession checkout = new CartCheckoutSession();
            checkout.Name='testSession';
            checkout.State='Start';
            checkout.OrderId = ord.Id;
            checkout.WebCartId = cart.Id;
            checkout.NextState='cartToOrder';
            checkout.IsError=false;
            checkout.IsArchived=false;
            insert checkout;
        }
        Map<String,Object> paymentDataMap = new Map<String,Object>();
        paymentDataMap.put('promoCode','test123');
        paymentDataMap.put('quoteNumber','test123');
        paymentDataMap.put('paymentId','test123');
        paymentDataMap.put('paymentMethod','cc');
        paymentDataMap.put('poNumber','test123');
        paymentDataMap.put('quoteNumber','test123');
        paymentDataMap.put('paymentmethodfirstname','Test22');
        paymentDataMap.put('paymentmethodlastname','Test');
        paymentDataMap.put('paymentmethodemail','Test22@test.com');
        paymentDataMap.put('paymentmethodtype','Test');
        paymentDataMap.put('paymentmode','Test');
        paymentDataMap.put('paymentmethodexpirationmonth','12');
        paymentDataMap.put('paymentmethodexpirationyear','2025');
        paymentDataMap.put('paymentmethodcity','test');
        paymentDataMap.put('paymentmethodstate','Test');
        paymentDataMap.put('paymentmethodcountry','US');
        paymentDataMap.put('paymentmethodzip','5003');
        paymentDataMap.put('totaltransactionamount','828.5');
        paymentDataMap.put('currencycode','USD');
        paymentDataMap.put('authorizationnumber','78778');
        paymentDataMap.put('merchantid','Test');
        paymentDataMap.put('paymentmethodtoken','Test3243');
        paymentDataMap.put('paymentmethodstreet','test');
        paymentDataMap.put('pgtext','Test');
        paymentDataMap.put('pgtransactionid','Test');
        paymentDataMap.put('paymenttransactionid','Test');
        paymentDataMap.put('transactionstatus','Test');
        paymentDataMap.put('transactiontype','Test');
        
        
        test.startTest();
        Map<String,Object> result;
        System.runAs(custUser){
        	result = ECOM_CheckoutController.createCreditCardPayment(acc.Id, cart.Id, paymentDataMap);
        }
        test.stopTest();
        system.debug('Result: '+result.get('Exception'));
        system.debug('Result stack trace: '+result.get('ExceptionStack'));
    }
    
    @isTest static void testgetDefaultShipToSAPNumber()
    {
        Account acc = [SELECT Id,IsBuyer FROM Account WHERE Name='TestClass Account' LIMIT 1];
        Contact custcon = new Contact(Email='test@yopmail.com',LastName='ECOM',AccountId=acc.Id,ECOM_CountryProvided__c='Canada');
        insert custcon;
        User custUser = ECOM_TestUtil.createPortalUser(custcon);
        System.runAs(custUser)
        {
            Map<String,Object> res = ECOM_CheckoutController.getDefaultShipToSAPNumber();
            System.AssertEquals(true,res.get('success'),'Success should be true');
        }
    }
    @isTest
    static void testgetUserInfo(){
        Test.startTest();
        Map<String,Object> res = ECOM_CheckoutController.getUserInfo();
        Test.stopTest();
    }
    @isTest
    static void testcreatePaymentLogs(){
        String error;
        String response;
        Test.startTest();
        Map<String,Object> res = ECOM_CheckoutController.createPaymentLogs(error, response);
        Test.stopTest();
    }
    @isTest
    static void testrepriceCart(){
        WebCart cart = [SELECT Id FROM WebCart LIMIT 1];
        String cartId = cart.Id;
        String couponCode;
        Test.startTest();
        Map<String,Object> res = ECOM_CheckoutController.repriceCart(cartId,couponCode);
        Test.stopTest();
    }
    @isTest
    static void testgetCreditCollections(){
        String moduleName = 'Test';
        Test.startTest();
        Map<String,Object> res = ECOM_CheckoutController.getCreditCollections(moduleName);
        Test.stopTest();
    }
    
    @isTest
    static void getCheckoutURLTest(){
        Map<String, String> responseHeaders = new Map<String, String>();
            responseHeaders.put('Content-Type', 'application/json');
         ECOM_MockHttpResponseGenerator mockResponse = new ECOM_MockHttpResponseGenerator(200, 'OK', '{"result": "success"}', responseHeaders);
         Test.setMock(HttpCalloutMock.class, mockResponse);
        Map<String,Object> cartSummary = new Map<String,Object>();
        User testUser=[SELECT Id,Name,ECOM_Is_Punchout_User__c FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        testUser.ECOM_Is_Punchout_User__c = true;
       	WebCart cart = [SELECT Id,AccountId,ECOM_POSR_Browser_Form_Post_Url__c,ECOM_POSR_Punchout_Format__c  FROM WebCart LIMIT 1];
        cart.ECOM_POSR_Browser_Form_Post_Url__c = 'testurl';
        cart.ECOM_POSR_Punchout_Format__c='cxml';
        update cart;
        cartSummary.put('accountId',cart.AccountId);
        cartSummary.put('cartId',cart.Id);
        Map<String,Object> response = new Map<String,Object>();
        System.runAs(testUser){
        Test.startTest();
        response = ECOM_CheckoutController.getCheckoutURL(cartSummary);
        Test.stopTest();
        }
        
       // System.assertEquals(false,response.get(ECOM_Constant.PARAM_SUCCESS),'It is not failure');
    }
    @isTest
    static void testgetCartTaxExemptValue(){
        WebCart cart = [SELECT Id, Name FROM WebCart WHERE Name = 'CAS_Cart'];
        Test.startTest();
        Boolean res = ECOM_CheckoutController.getCartTaxExemptValue(cart.Id);
        Test.stopTest();
    }
    @isTest
    static void testgetCharityNumberValue(){
        WebCart cart = [SELECT Id, Name FROM WebCart WHERE Name = 'CAS_Cart'];
        Test.startTest();
        String res = ECOM_CheckoutController.getCharityNumberValue(cart.Id);
        Test.stopTest();
    }
    @isTest
    static void testsaveTaxExemptInfo(){
        WebCart cart = [SELECT Id, Name FROM WebCart WHERE Name = 'CAS_Cart'];
        Test.startTest();
        Map<String,Object> res = ECOM_CheckoutController.saveTaxExemptInfo(true,cart.Id,'TestCharityNumber');//Gaurang - 9 April 2024 - RWPS-460 - Test class change for new parameter
        Test.stopTest();
    }
    @isTest
    static void testsaveTaxExemptInfoExemption(){
        WebCart cart = [SELECT Id, Name FROM WebCart WHERE Name = 'CAS_Cart'];
        Test.startTest();
        Map<String,Object> res = ECOM_CheckoutController.saveTaxExemptInfo(false,cart.Id,'TestCharityNumber');//Gaurang - 9 April 2024 - RWPS-460 - Test class change for new parameter
        Test.stopTest();
    }
    
    @isTest
    static void testsaveEInvoiceDetails(){
        WebCart cart = [SELECT Id, Name FROM WebCart WHERE Name = 'CAS_Cart'];
        Test.startTest();
        ECOM_CheckoutController.saveEInvoiceDetails(cart);
        ECOM_CheckoutController.saveEInvoiceDetails(null);
        Test.stopTest();
    }
	/*RWPS-2547 -  START*/
    @isTest
    static void testGetSAPOrderNumber(){
        Order order = [Select Id From Order ORDER BY CreatedDate DESC LIMIT 1];
        Test.startTest();
        String sapOrderNumber = ECOM_CheckoutController.getSAPOrderNumber(order.id);
        Test.stopTest();
    }
    /*RWPS-2547 - END*/
     /*RWPS-2786 - START*/
    @isTest
    static void getCheckoutInItDataTest1(){
        User testUser=[SELECT Id,Name FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        testUser.ECOM_Is_Punchout_User__c =false; 
        update testUser; 
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        Map<String,Object> result;
        System.runAs(testUser){
            result = ECOM_CheckoutController.getCheckoutInItData('',acc.Id);
        }
        Test.stopTest();
    }


    @isTest
    static void test_fetchNonSellableDiscontinuedProducts() {
        WebStore webStr = [SELECT Id FROM WebStore LIMIT 1];
        Contact con = [SELECT Id,OwnerId FROM Contact LIMIT 1];
        Product2 product = [SELECT Id,ProductCode FROM Product2 LIMIT 1];
        Account acc = [SELECT Id,IsBuyer FROM Account WHERE Name='TestClass Account' LIMIT 1];
        Order ord = [SELECT Id FROM Order LIMIT 1];
        Contact custcon = new Contact(Email='test@yopmail.com',LastName='ECOM',AccountId=acc.Id);
        insert custcon;
        User custUser = ECOM_TestUtil.createPortalUser(custcon);
        custUser.ECOM_Is_Punchout_User__c=true;//RWPS-2346
        system.debug('User soql: '+[SELECT Id,Name,IsPortalEnabled FROM User WHERE Email LIKE '%test123@noemail.com' LIMIT 1]);
        List<PermissionSet> ps1 = [SELECT Id FROM PermissionSet WHERE Name = 'Buyer'];
        if(ps1 != NULL && ps1.size()>0){
            insert new PermissionSetAssignment(AssigneeId = custUser.Id, PermissionSetId = ps1[0].Id);
        }
        WebCart cart;
        cart = ECOM_TestUtil.createCart(acc,webStr,custUser);
        insert cart;
        system.debug('Cart: '+[SELECT Id,OwnerId,Owner.FirstName FROM WebCart WHERE OwnerId=:custUser.Id]);
        OrderDeliveryMethod OrderDeliveryMethod = ECOM_TestUtil.createOrderDeliveryMethod();
        insert OrderDeliveryMethod;
        CartDeliveryGroup cartDeliveryGroup = ECOM_TestUtil.createCartDeliveryGroup(cart, OrderDeliveryMethod.Id);
        insert cartDeliveryGroup;
        CartDeliveryGroupMethod CartDeliveryGroupMethod = ECOM_TestUtil.createCartDeliveryGroupMethod(cart.Id, cartDeliveryGroup.Id, OrderDeliveryMethod.Id);
        insert CartDeliveryGroupMethod;
        CartItem cartItem = ECOM_TestUtil.createCartItem(cart,cartDeliveryGroup,product);
        insert cartItem;
        System.runAs(custUser){
        Test.startTest();
        Map<String, Object> result = ECOM_CheckoutController.deleteDiscontinuedNonSellableProducts(cart.Id);
        Test.stopTest();
        }
    }


    @isTest
    static void test_deleteDiscontinuedProducts() {
        WebStore webStr = [SELECT Id FROM WebStore LIMIT 1];
        Contact con = [SELECT Id,OwnerId FROM Contact LIMIT 1];
        Product2 product = [SELECT Id,ProductCode FROM Product2 LIMIT 1];
        Product2 discontinuedProduct = ECOM_TestUtil.createProduct('Test Discontinued Product', 'TEST-0002', 'TEST-PC-0002', true);
        Product_Sales__c discontinuedProductSales = ECOM_TestUtil.createProduct_Sales(String.valueOf(discontinuedProduct.Id));
        discontinuedProductSales.Distribution_ChainSpecificMaterialStatus__c = '02';
        discontinuedProductSales.Sales_Org__c = 'US10';
        insert discontinuedProductSales;
        
        Product_Sales__c discontinuedProductSales1 = ECOM_TestUtil.createProduct_Sales(String.valueOf(discontinuedProduct.Id));
        discontinuedProductSales1.Distribution_ChainSpecificMaterialStatus__c = '02';
        discontinuedProductSales1.Sales_Org__c = 'EEU2';
        insert discontinuedProductSales1;
        
                // Create two products: main (discontinued) and its training replacement candidate
        Product2 mainProd = [SELECT Id, Name, ProductCode FROM Product2 ORDER BY CreatedDate DESC LIMIT 1];
        // Create a second product to act as suggested/training product
        Product2 trainingProd = new Product2(Name='Training SKU', ProductCode = 'GR00023', IsActive=true);
        insert trainingProd;

        // Create Product Recommendation (Combination) main -> suggested (training)
        Product_Recommendation__c pr = new Product_Recommendation__c();
        pr.Product_Main__c = mainProd.Id;
        pr.Product_Suggested__c = trainingProd.Id;
        pr.Suggest_Type__c = 'Combination';
        pr.ExternalId__c = 'test566455';
        insert pr;
        
        Account acc = [SELECT Id,IsBuyer FROM Account WHERE Name='TestClass Account' LIMIT 1];
        system.debug('Account: '+acc);
        Order ord = [SELECT Id FROM Order LIMIT 1];
        Contact custcon = new Contact(Email='test@yopmail.com',LastName='ECOM',AccountId=acc.Id);
        insert custcon;
        User custUser = ECOM_TestUtil.createPortalUser(custcon);
        //custUser.ECOM_Is_Punchout_User__c=true;//RWPS-2346
        system.debug('User soql: '+[SELECT Id,Name,IsPortalEnabled FROM User WHERE Email LIKE '%test123@noemail.com' LIMIT 1]);
        List<PermissionSet> ps1 = [SELECT Id FROM PermissionSet WHERE Name = 'Buyer'];
        if(ps1 != NULL && ps1.size()>0){
            insert new PermissionSetAssignment(AssigneeId = custUser.Id, PermissionSetId = ps1[0].Id);
        }
        WebCart cart;
        cart = ECOM_TestUtil.createCart(acc,webStr,custUser);
        insert cart;
        system.debug('Cart: '+[SELECT Id,OwnerId,Owner.FirstName FROM WebCart WHERE OwnerId=:custUser.Id]);
        OrderDeliveryMethod OrderDeliveryMethod = ECOM_TestUtil.createOrderDeliveryMethod();
        insert OrderDeliveryMethod;
        CartDeliveryGroup cartDeliveryGroup = ECOM_TestUtil.createCartDeliveryGroup(cart, OrderDeliveryMethod.Id);
        insert cartDeliveryGroup;
        CartDeliveryGroupMethod CartDeliveryGroupMethod = ECOM_TestUtil.createCartDeliveryGroupMethod(cart.Id, cartDeliveryGroup.Id, OrderDeliveryMethod.Id);
        insert CartDeliveryGroupMethod;
        
        CartItem cartItem = ECOM_TestUtil.createCartItem(cart,cartDeliveryGroup,product);
        insert cartItem;
        CartItem cartItem1 = ECOM_TestUtil.createCartItem(cart,cartDeliveryGroup,discontinuedProduct);
        insert cartItem1;
        system.debug(cartItem1+ '--cartItem1');
         system.debug(cartItem+ '--cartItem');
        System.runAs(custUser){
        Test.startTest();
        Map<String, Object> result = ECOM_CheckoutController.deleteDiscontinuedNonSellableProducts(cart.Id);
        Test.stopTest();
        }
    }
    
    // RWPS-3740/4896 - Cover deleteDiscontinuedProductsWithReplacement and deleteReplacedCartItem
    @isTest
    static void test_deleteDiscontinuedProductsWithReplacement_and_deleteReplacedCartItem() {
        // Arrange base data
        WebStore webStr = [SELECT Id FROM WebStore LIMIT 1];
        Account acc = [SELECT Id,IsBuyer FROM Account WHERE Name='TestClass Account' LIMIT 1];
        Contact custCon = new Contact(Email='rep@yopmail.com', LastName='ECOM', AccountId=acc.Id);
        insert custCon;
        User custUser = ECOM_TestUtil.createPortalUser(custCon);
        List<PermissionSet> psBuyer = [SELECT Id FROM PermissionSet WHERE Name = 'Buyer' LIMIT 1];
        if (psBuyer != null && !psBuyer.isEmpty()) {
            insert new PermissionSetAssignment(AssigneeId = custUser.Id, PermissionSetId = psBuyer[0].Id);
        }
        
        Product2 discontinuedProduct = ECOM_TestUtil.createProduct('Test Discontinued Product', 'TEST-0002', 'TEST-PC-0002', true);
        Product_Sales__c discontinuedProductSales = ECOM_TestUtil.createProduct_Sales(String.valueOf(discontinuedProduct.Id));
        discontinuedProductSales.Distribution_ChainSpecificMaterialStatus__c = '02';
        discontinuedProductSales.Sales_Org__c = 'US10';
        insert discontinuedProductSales;
        
        Product_Sales__c discontinuedProductSales1 = ECOM_TestUtil.createProduct_Sales(String.valueOf(discontinuedProduct.Id));
        discontinuedProductSales1.Distribution_ChainSpecificMaterialStatus__c = '02';
        discontinuedProductSales1.Sales_Org__c = 'EEU2';
        insert discontinuedProductSales1;
   
        // Create two products: main (discontinued) and its training replacement candidate
        Product2 mainProd = [SELECT Id, Name, ProductCode FROM Product2 ORDER BY CreatedDate DESC LIMIT 1];
        // Create a second product to act as suggested/training product
        Product2 trainingProd = new Product2(Name='Training SKU', ProductCode = 'GR00023', IsActive=true);
        insert trainingProd;

        // Create Product Recommendation (Combination) main -> suggested (training)
        Product_Recommendation__c pr = new Product_Recommendation__c();
        pr.Product_Main__c = mainProd.Id;
        pr.Product_Suggested__c = trainingProd.Id;
        pr.Suggest_Type__c = 'Combination';
        pr.ExternalId__c = 'test566455';
        insert pr;

        // Create WebCart and related delivery artifacts
        WebCart cart = ECOM_TestUtil.createCart(acc, webStr, custUser);
        insert cart;
        OrderDeliveryMethod odm = ECOM_TestUtil.createOrderDeliveryMethod();
        insert odm;
        CartDeliveryGroup cdg = ECOM_TestUtil.createCartDeliveryGroup(cart, odm.Id);
        insert cdg;

        // Create CartItems: one for main product and one for training product
        CartItem mainItem = ECOM_TestUtil.createCartItem(cart, cdg, mainProd);
        insert mainItem;
        CartItem trainingItem = ECOM_TestUtil.createCartItem(cart, cdg, trainingProd);
        insert trainingItem;
        CartItem cartItem1 = ECOM_TestUtil.createCartItem(cart,cdg,discontinuedProduct);
        insert cartItem1;

        // Simulate discontinued/replaceable condition on product via a field the controller checks
        // If org object has fields Replacement_Product__c or Replacement_Alternatives__c, populate one
        try {
            mainProd.put('Replacement_Product__c', trainingProd.Id);
            update mainProd;
        } catch (Exception ignore) {
            // Field may not exist in test org metadata; proceed because controller also checks Alternatives field.
        }

        System.runAs(custUser) {
            Test.startTest();
            // Act: delete discontinued with replacement should collect both main discontinued ids (by replacement fields)
            Map<String, Object> respReplace = ECOM_CheckoutController.deleteDiscontinuedProductsWithReplacement(cart.Id);
           

            // Basic assertions on response keys
            System.assert(respReplace.containsKey('success'), 'Response should include success key');

            // Now exercise deleteReplacedCartItem which should also cascade training product removal when main is last
            
            ECOM_CheckoutController.deleteReplacedCartItem(mainItem.Id);
            Test.stopTest();
        }
    }
     /*RWPS-2786 - END*/

     /* RWPS-1882 Start */
    @isTest
    static void testgetCartTaxExemptValue_NoCartFound() {
    Id fakeCartId = 'a0U000000000001AAA'; 
    Test.startTest();
    try {
        Boolean res = ECOM_CheckoutController.getCartTaxExemptValue(fakeCartId);
    } catch (Exception ex) {
        System.debug('exception: ' + ex.getMessage());
    }
    Test.stopTest();
    }
  /* RWPS-1882 end */
    /* RWPS-3811 */
    @isTest
    static void testGetParentPartNumber(){
        Order order = [Select Id, (select id, Product2.Part_Number__c from orderItems) From Order ORDER BY CreatedDate DESC LIMIT 1];
        Test.startTest();
        String sapOrderNumber = ECOM_CheckoutController.getParentPartNumber(order, order.orderitems[0].id);
        Test.stopTest();
    }
    
}