/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-116
*    ECOM-118
*
* 2. Description - This class acts as a controller for checkout page.
                    - return and save Shipping & Billing Information.
                    - fetch all account,Po numbers and contact level email address stord in email Preferences object for user
*                   - Create delete and add  Wishlist Item and Cart Delivery Group
                    - check the delivery charges and return List of WebCart Records
* 3. Objects referenced
*    - Contact
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - called from ecom_checkout.js
*    - called from ecom_checkout_shippingDetials.js
*    - called from ecom_checkoutCartSummary.js
*
* 6. Test Class Name:
*    - ECOM_CheckoutController_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Manish 2023.08.17
*    - Sidak 2024.02.08 Updated method placeOrder. Ticket - RWPS-120
*    - Gaurang 2024.02.21 - Fix for VAT checkbox
*    - Gaurang 2024.04.01 - Additional check for cart status before updation. Ticket - RWPS-289
*    - Sidak 2024.04.04 - Added charity number parameter in saveTaxExemptInfo method. Ticket - RWPS-416
*    - Gaurang/Manoj 2024.04.09 - RWPS-460 - Referencing a new method in repo and additional check for splitted parts
*    - Sidak 2024.04.19 - Added getCharityNumberValue method to fetch charity number value on cart. Ticket - RWPS-416
*    - Gaurang 2024.04.24 - Cleanup, null check and additional condition before creating tax records - RWPS-460
*    - Sathiya 2024.04.29 - Adding validation config for ECOM-1933 and ECOM -1942
*    - Vipul Goyal 2024.05.02 - Updated getCheckoutInItData for ECOM - 103.
*    - Sathiya 2024.05.02 - Adding validation config for ECOM-1933 and ECOM -1942 on getOrderConfirmationDetails.
*    - Vipul Goyal 2024.05.03 - Updated getOrderConfirmationDetails.
*    - Sathiya 2024.05.13 - Adding new method for saving invoice details on cart and other related config for ECOM-1947.
*    - Manoj 2024.03.05 RWPS-553 Sending Contact ID to SAP(Updated SAP contact id on Cart)
*    - Manoj 2024.07.19 RWPS-1107 Exception- Credit Card last four digit not captured in some transaction fixes
*    - Sidak 2024.09.03 - Added logic to call Cart to order flow in case Order is not created. Ticket - RWPS-1382
*    - Sidak 2024.10.10 - Added method updateBillToShipToOnCart. Ticket - RWPS-1602
*    - Manoj 2024.11.26 - Updated cart status to checkout is user is in checkout. Ticket - RWPS-2049
*    - Manish 2025.01.31 - Updated method getOrderConfirmationDetails added display name logic RWPS-2270
*    - Gaurav 2025.02.14 - Added method getSAPOrderNumber to get SAP order number - RWPS-2547
*    - Manish 2025.02.21 - Updated method saveAdditionalShippingInfo to catch custom validation exception - RWPS-2648
*    - Prabhat 2025.02.28 - Updated method saveAdditionalShippingInfo, getCheckoutURL, getCheckoutURL to log the custom validatoin exception and code coverage - RWPS-2721
*    - Gaurav 2025.04.18 - Updated getAddressInfo and place order for largepack item in order - RWPS-1285
*    - Gaurav 2025.05.07 - Updated place order for product recommendation item - RWPS-3362
*    - Poonam 2025.06.11 - Updated getAddressInfo and place order for Contact's Default ERP Address Invoice Email Address in Order - RWPS- 1882
*    - Prabhat 2025.06.19 - Added method deleteDiscontinuedNonSellableProducts to delete non sellable and discontinued products, updated place order for coverage - RWPS-2786
*    - Gaurav 2025.08.22 - Updated getOrderConfirmationDetails and created getParentPartNumber for BOGO implementation - RWPS-3811
*    - Chirag 2025.10.03 - Added methods deleteDiscontinuedProductsWithReplacement, deleteReplacedCartItem for replacement implementation - RWPS-3740
*    - Prabhat 2025.12.05 - Updated method deleteReplacedCartItem to delete training proudcts - RWPS-4896
*    - Prabhat 2025.12.10 - Updated method deleteReplacedCartItem,getOrderConfirmationDetails and deleteDiscontinuedNonSellableProducts to delete training proudcts - RWPS-4896
*    - Prabhat 2025.12.10 - Updated method deleteDiscontinuedProductsWithReplacement and created getTrainingCartItemIdsToDelete to delete training proudcts - RWPS-4896
*    - Prabhat 2026.02.18 - Updated method getCheckoutURL creating punchout logs - RWPS-6095
*    - Manish 2026.03.09 - Updated method getCheckoutURL set timeout - RWPS-6684
*    - Poonam 2026.03.10 - Updated method getAddressInfo - RWPS-6394
*************************************************************/
public without sharing class ECOM_CheckoutController {

    public static String className = 'ECOM_CheckoutController';

    /**
    * @description  Method to get Shipping & Billing Information.
    * @author Manish 2023.08.17
    * @return Contact
    **/
    @AuraEnabled
    public static Contact getContactInfo(){
        Type userService = Type.forName(ECOM_Constant.USER_Service);
        ECOM_IUserService userServiceInstance = (ECOM_IUserService)userService.newInstance();
        User user = userServiceInstance.getUserByUserId();

        Type contactService = Type.forName(ECOM_Constant.CONTACT_Service);
        ECOM_IContactService contactServiceInstance = (ECOM_IContactService)contactService.newInstance();
        Contact contact = contactServiceInstance.getContactDetails(user.ContactId);
        return contact;
    }

    /**
    * @description  Method to get Shipping & Billing Information.
    * @author Manish 2023.10.19
    * @param cartId
    * @return responseMap
    **/
    @AuraEnabled
    public static Map<String,Object> getAddressInfo(string cartId){
        Map<String,Object> responseMap = new  Map<String,Object>();
        Contact contact = getContactInfo();
        Set<String> erpIds = new Set<String>();
        List<ERP_Address__c> erpAddressList = new List<ERP_Address__c>();
        WebCart cart = ECOM_CartService.getPrimaryCartBasedOnId(cartId);
        erpIds.add(cart.Default_Bill_to_ERP_Address__c);
        erpIds.add(cart.Default_Ship_to_ERP_Address__c);

        if(cart?.Default_Invoice_ERP_Address__c != null){
            erpIds.add(cart?.Default_Invoice_ERP_Address__c);
        }
        Map<Id,ERP_Address__c> erpAddressesMap = ERP_AddressService.getTargetId(erpIds);
        erpAddressList = erpAddressesMap.values();
        boolean isLargePackExist = ECOM_cartUtil.isLargePackItemExist(cartId); // RWPS-1285
        boolean isEmailInvoiceExist = ECOM_cartUtil.isInvoiceEmailExist(); //RWPS-1882
        //RWPS-6394 start
        Map<String,String> cartStoreConfigs = ECOM_CartRepo.getStorefrontFrontConfigByModule('ECOM_Enable_InvoiceCustId');
        boolean enableInvoiceCustId = Boolean.valueOf(cartStoreConfigs.get(ECOM_Constant.ECOM_Enable_InvoiceCustId));
        boolean isInvoiceCustIdExist = true;
        // if(enableInvoiceCustId)
        // {
        isInvoiceCustIdExist = ECOM_CartUtil.isEInvoiceCustIdExist();
        // } //RWPS-6394 end
        ERP_AddressModel shipToModel = ERP_AddressUtil.convertERPAddressesToModel(erpAddressList);
        responseMap.put('Status','Success');
        responseMap.put('contact',contact);
        responseMap.put('shipToModel',shipToModel);
        responseMap.put('isLargePackExist',isLargePackExist); // RWPS-1285
        responseMap.put('isEmailInvoiceExist',isEmailInvoiceExist); // RWPS-1882
        responseMap.put('isInvoiceCustIdExist',isInvoiceCustIdExist); // RWPS-6394
        responseMap.put('enableInvoiceCustId',enableInvoiceCustId);//RWPS-6394
        // Added by sathiya on 2024/04/29 for ECOM-1933
        responseMap.put('billToValidationFields', ECOM_CustomMetadataService.getStoreConfigurationByLabel(ECOM_Constant.BILL_TO_FIELD_VALIDATION));
        // Changes end by sathiya
        return responseMap;
    }

    /**
    * @description  Method to save Additional Shipping Information.
    * @author Manish 2023.08.17
    * @param deliveryDetails
    * @param attentionRecipient
    * @param specialInstructions
    * @return Map<String,Object>
    **/
    @AuraEnabled
    public static Map<String,Object> saveAdditionalShippingInfo(String deliveryDetails, String attentionRecipient, String specialInstructions){
        Map<String,Object> responseMap = new  Map<String,Object>();
        //Start - RWPS-2721
        String supportData = '';
        String methodName = 'saveAdditionalShippingInfo';
        //End- RWSP-2721
        try {
            supportData = 'deliveryDetails = '+deliveryDetails+' attentionRecipient = '+attentionRecipient+' specialInstructions'; //RWSP-2721
            Type userService = Type.forName(ECOM_Constant.USER_Service);
            ECOM_IUserService userServiceInstance = (ECOM_IUserService)userService.newInstance();
            User user = userServiceInstance.getUserByUserId();

            Type contactService = Type.forName(ECOM_Constant.CONTACT_Service);
            ECOM_IContactService contactServiceInstance = (ECOM_IContactService)contactService.newInstance();

            Contact contact = new Contact();
            contact.Id = user.ContactId;
            contact.ECOM_Special_Instructions__c = specialInstructions;
            contact.ECOM_Attention_Recipient__c = attentionRecipient;
            contact.ECOM_Delivery_Details__c = deliveryDetails;
            contactServiceInstance.saveAdditionalShippingInfo(contact);
            contact = getContactInfo();
            responseMap.put('Status','Success');
            responseMap.put('Contact',contact);
        } catch (Exception ex) {
            // RWPS-2648 - START
            String exceptionMsg = ex.getMessage();
            exceptionMsg = exceptionMsg.contains(ECOM_Constant.PARAM_CONTACT_RULE_VII)?Label.ECOM_BlankCountryProvidedMsg
                           :exceptionMsg;
             responseMap.put('ErrorMessage',exceptionMsg);
             ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.CHECKOUT_MODULE_NAME, className, methodName, supportData); //RWPS-2721
            // RWPS-2648 - END
            system.debug('ex => '+ex);
            responseMap.put('Status','Error');

        }
        return responseMap;
    }

  /**
  * @description This method is used to fetch the fields associated with the object
  * @author Manish 2023.08.24
  * @param objectName
  * @return Map<String, String>
  **/
  @AuraEnabled
  public static Map<String,String> getFieldsByObjectName(
    String objectName
  ) {
    Map<String,String> fieldsMap = ECOM_Util.getFieldsByObjectName(objectName);
    return fieldsMap;
  }

    /**
    * @description  Method to get all the items from the cart.
    * @author Manish 2023.08.17
    * @param communityId
    * @param effectiveAccountId
    * @return List<ECOM_CartModel>
    **/
    @AuraEnabled
    public static Map<String,Object> getCheckoutInItData(
        String communityId,
        String effectiveAccountId
    ) {
        Map<String,Object> responseMap = new  Map<String,Object>();
        Type cartService = Type.forName(ECOM_Constant.CART_SERVICE);
        ECOM_ICartService cartServiceInstance = (ECOM_ICartService)cartService.newInstance();

        List<ECOM_CartModel> cartModelsResponse = new List<ECOM_CartModel>();

        Type userService = Type.forName(ECOM_Constant.USER_Service);
        ECOM_IUserService userServiceInstance = (ECOM_IUserService)userService.newInstance();
        User u = userServiceInstance.getUserByUser(UserInfo.getUserId());

        if(!u.ECOM_Is_Punchout_User__c)
        {
            String country  = ECOM_Util.getCountryFromUser(u);
            if(String.isNotBlank(country))
            {
                String salesOrg = ECOM_CustomMetadataService.getSalesOrg(country);
                responseMap.put('salesOrg', salesOrg);
            }
        }

        ECOM_CartModel cartModel = new ECOM_CartModel();
        cartModel.accountId = effectiveAccountId;
        cartModel.userId = UserInfo.getUserId();
        List<ECOM_CartModel> cartModels = cartServiceInstance.fetchCart(new List<ECOM_CartModel>{cartModel});

        cartModelsResponse = cartServiceInstance.getCartItems(cartModels);
        List<WebCart> WebCarts = new List<WebCart>();
        List<C_META_Storefront_Configuration__mdt> storeConfigMdtList = getPaymentInItData();
        if(!cartModelsResponse.isEmpty()){
            WebCarts = getCartandCartItemsById(cartModelsResponse[0].cartId);
        }

        if(!WebCarts.isEmpty())
        {
            if(String.isNotBlank(WebCarts[0].Default_Ship_to_ERP_Address__c))
            {
                if(WebCarts[0].Default_Ship_to_ERP_Address__r.ECOM_Approver_Enabled__c)
                {
                    if(String.isNotBlank(WebCarts[0].Default_Ship_to_ERP_Address__r.ECOM_RAD_Approval_Status__c))
                    {
                        responseMap.put('Approval_Scheme',WebCarts[0].Default_Ship_to_ERP_Address__r.ECOM_RAD_Approval_Status__c);

                        if(WebCarts[0].Default_Ship_to_ERP_Address__r.ECOM_RAD_Approval_Status__c.equalsIgnoreCase('RAD'))
                        {
                            for(CartItem ci:WebCarts[0].CartItems)
                            {
                                if(
                                    String.isNotBlank(ci.Product2.Dangerous_Goods_Indicator_Profile__c) &&
                                    (ci.Product2.Dangerous_Goods_Indicator_Profile__c.equalsIgnoreCase('Yes') || ci.Product2.Dangerous_Goods_Indicator_Profile__c.equalsIgnoreCase('Y') || ci.Product2.Dangerous_Goods_Indicator_Profile__c.equalsIgnoreCase('RAD'))
                                )
                                {
                                    responseMap.put('ApprovalNeeded', true);
                                    break;
                                }
                            }
                        }
                        else
                        {
                            responseMap.put('ApprovalNeeded', true);
                        }
                    }
                }
            }
        }

        if(!responseMap.containsKey('ApprovalNeeded'))
        {
            responseMap.put('ApprovalNeeded', false);
        }

        //return cartModelsResponse;
        responseMap.put('Status','Success');
        responseMap.put('WebCarts', WebCarts);
        responseMap.put('storeConfigMdtList', storeConfigMdtList);
        responseMap.put('cartModelsResponse', cartModelsResponse);
        // Added by sathiya on 2024/05/13 for ECOM-1947
        responseMap.put('invoiceValidationFields', ECOM_CustomMetadataService.getStoreConfigurationByLabel(ECOM_Constant.INVOICE_FIELD_VALIDATION));
        // Changes end by sathiya
        return responseMap;
    }

    /**
    * @description  Method to check if current PO by user is already used for .
    * @author Manish 2023.08.24
    * @param effectiveAccountId
    * @param poNumber
    * @return List<ECOM_CartModel>
    **/
    @AuraEnabled
    public static Boolean checkIfPoUsed(String effectiveAccountId, String poNumber){
        List<Order> orderList = ECOM_OrderService.checkIfPoUsed(effectiveAccountId, poNumber);
        Boolean isPoNumberUsed = false;
        if(orderList != null && !orderList.isEmpty())
        {
            isPoNumberUsed = true;
        }
        return isPoNumberUsed;
    }

    /**
    * @description  this Method is to fetch all account and contact level email address stord in email Preferences object for this user.
    * @author Manish 2023.08.24
    * @param effectiveAccountId
    * @return LMap<String,Object>
    **/
    @AuraEnabled
    public static Map<String,Object> getEmailPreferences(String effectiveAccountId){
        String supportData = '';
        String methodName = 'getEmailPreferences';
        Map<String,Object> responseMap = new  Map<String,Object>();
        try{
            supportData = 'effectiveAccountId = '+effectiveAccountId;
            Type userService = Type.forName(ECOM_Constant.USER_Service);
            ECOM_IUserService userServiceInstance = (ECOM_IUserService)userService.newInstance();
            User user = userServiceInstance.getUserByUserId();

            Type contactService = Type.forName(ECOM_Constant.CONTACT_Service);
            ECOM_IContactService contactServiceInstance = (ECOM_IContactService)contactService.newInstance();

            List<ECOM_Email_Preferences__c> listEmailPreferences = new List<ECOM_Email_Preferences__c>();
            List<ECOM_Email_Preferences__c> ListEmailPrefContactLvl = new List<ECOM_Email_Preferences__c>();
            List<ECOM_Email_Preferences__c> ListEmailPrefAccountLvl = new List<ECOM_Email_Preferences__c>();
            List<ECOM_Email_Preferences__c> ListEmailPrefAll = new List<ECOM_Email_Preferences__c>();
            listEmailPreferences = contactServiceInstance.getEmailPreferences(user.Contact.Default_Ship_to_ERP_Address__c);
            for(ECOM_Email_Preferences__c ep: listEmailPreferences){
                if(ep.ECOM_Contact__c == user.ContactId){
                    ListEmailPrefContactLvl.add(ep);
                }else if(ep.ECOM_Contact__c == null){
                    ListEmailPrefAccountLvl.add(ep);
                }
            }

            responseMap.put('Status','Success');
            responseMap.put('ListEmailPrefAccountLvl',ListEmailPrefAccountLvl);
            responseMap.put('ListEmailPrefContactLvl',ListEmailPrefContactLvl);
            ListEmailPrefAll.addAll(ListEmailPrefAccountLvl);
            ListEmailPrefAll.addAll(ListEmailPrefContactLvl);
            responseMap.put('listEmailPreferences',ListEmailPrefAll);
        }catch(Exception ex){
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.CHECKOUT_MODULE_NAME, className, methodName, supportData);
            responseMap.put('Status','Error');
            responseMap.put('Exception',ex.getMessage());
        }
        return responseMap;
    }

    /**
    * @description  Method to save all the email preferences data, payment data and create a order.
    * @author Manish 2023.08.24
    * @param effectiveAccountId
    * @param cartId
    * @param newEmailAddressRows
    * @param updatedEmailAddressRows
    * @return Map<String,Object>
    **/
    @AuraEnabled
    public static Map<String,Object> createOrUpdateEmailPreferences(String newEmailAddressRows, String removeEmailPrefList){
        String supportData = '';
        String methodName = 'createOrUpdateEmailPreferences';
        Map<String,Object> responseMap = new  Map<String,Object>();
        try{
            supportData = 'newEmailAddressRows = '+JSON.serialize(newEmailAddressRows)+' removeEmailPrefList = '+JSON.serialize(removeEmailPrefList);
            Type userService = Type.forName(ECOM_Constant.USER_Service);
            ECOM_IUserService userServiceInstance = (ECOM_IUserService)userService.newInstance();
            User user = userServiceInstance.getUserByUserId();

            Type contatService = Type.forName(ECOM_Constant.CONTACT_Service);
            ECOM_IContactService contactServiceInstance = (ECOM_IContactService)contatService.newInstance();

            List<Object> newEmailAddressList = String.isNotBlank(newEmailAddressRows) ? (List<Object>)JSON.deserializeUntyped(newEmailAddressRows) : new List<Object>();
            //List<Object> updatedEmailAddressList = (List<Object>)JSON.deserializeUntyped(updatedEmailAddressRows);
            //ECOM_CartUtil.addOrderDeliveryMethodToCartDeliveryGroup();
            List<ECOM_Email_Preferences__c> allEpList = new List<ECOM_Email_Preferences__c>();
            List<ECOM_Email_Preferences__c> newEpList = new List<ECOM_Email_Preferences__c>();
            for(Object obj: newEmailAddressList){
                Map<String, Object> objMap = (Map<String, Object>)obj;
                ECOM_Email_Preferences__c newEP = new ECOM_Email_Preferences__c();
                newEP.ECOM_Email__c = (string)objMap.get('ECOM_Email__c');
                newEP.ECOM_Order_Confirmation__c = (boolean)objMap.get('ECOM_Order_Confirmation__c');
                newEP.ECOM_Send_Invoice__c = (boolean)objMap.get('ECOM_Send_Invoice__c');
                newEP.ECOM_Shipment_Notification__c = (boolean)objMap.get('ECOM_Shipment_Notification__c');
                //newEP.ECOM_Account__c = effectiveAccountId;
                newEP.ECOM_Contact__c = user.ContactId;
                newEP.ERP_Address__c = user.Contact.Default_Ship_to_ERP_Address__c;
                newEpList.add(newEP);
            }
            if(!newEpList.isempty()){
                allEpList.addAll(newEpList);
                //contactServiceInstance.saveOrUpdate(newEpList);
            }

            List<Object> emailPrefList = String.isNotBlank(removeEmailPrefList) ? (List<Object>)JSON.deserializeUntyped(removeEmailPrefList) : new List<Object>();
            List<ECOM_Email_Preferences__c> updateEpList = new List<ECOM_Email_Preferences__c> ();
            //Set<String> ePrefIds = new Set<String>();
            //List<String> emailPrefList = new List<String>();
            for(Object obj : emailPrefList){
                ECOM_Email_Preferences__c eep = new ECOM_Email_Preferences__c();
                Map<String, Object> emailPrefMap = (Map<String, Object>)obj;
                eep.Id = (String)emailPrefMap.get('Id');
                eep.ECOM_isActive__c = false;
                updateEpList.add(eep);
            }
            if(!updateEpList.isempty()){
                allEpList.addAll(updateEpList);
                //contactServiceInstance.saveOrUpdate(updateEpList);
            }
            if(!allEpList.isempty()){
                contactServiceInstance.saveOrUpdate(allEpList);
            }
            responseMap.put('Status','Success');
        }catch(exception ex){
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.CHECKOUT_MODULE_NAME, className, methodName, supportData);
            responseMap.put('Status','Error');
            responseMap.put('Exception',ex.getMessage());
        }
        return responseMap;
    }


     /**
    * @description  Method to save all the email preferences data, payment data and create a order.
    * @author Manish 2023.08.24
    * @param effectiveAccountId
    * @param cartId
    * @param paymentDataMap
    * @param acceptedDate
    * @param endUserForTrade
    * @param endUserAddress
    * @return Map<String,Object>
    **/
    @AuraEnabled
    public static Map<String,Object> placeOrder(String effectiveAccountId, String cartId, Map<String,Object> paymentDataMap, String acceptedDate, String endUserForTrade, String endUserAddress, String invoiceEmailAddress, String invoiceCustId){//RWPS-6394
        String supportData = '';
        String methodName = 'placeOrder';
        Map<String,Object> responseMap = new  Map<String,Object>();
        try{
            supportData = 'effectiveAccountId = '+effectiveAccountId+' cartId = '+cartId;
            List<Webcart> listCart = new List<Webcart>();
            List<WebCart> cartList = ECOM_CartRepo.getCartandCartItemsById(cartId);
            Webcart cart = cartList.size() > 0? cartList[0] : new WebCart();
            cart.Id = cartId;
            cart.ECOM_Cart_Id__c = cartId;
            //RWPS-2049
            if(cart.Status == null || cart.Status != 'Checkout'){
                cart.Status = 'Checkout';
            }
            if(paymentDataMap.containsKey('promoCode') && paymentDataMap.get('promoCode') != null){
                cart.ECOM_Promo_Code__c = String.valueOf(paymentDataMap.get('promoCode'));
            }
            if(paymentDataMap.containsKey('quoteNumber') && paymentDataMap.get('quoteNumber') != null){
                cart.ECOM_Quote_Number__c = String.valueOf(paymentDataMap.get('quoteNumber'));
            }
            if(paymentDataMap.containsKey('paymentMethod') && paymentDataMap.get('paymentMethod') != null && paymentDataMap.get('paymentMethod') == 'po'){
                if(paymentDataMap.containsKey('poNumber') && paymentDataMap.get('poNumber') != null){
                    cart.PoNumber =  String.valueOf(paymentDataMap.get('poNumber'));
                }
            }

            //RWPS-553 logic start
            User us = new ECOM_UserService().getUserByUser(UserInfo.getUserId());
            String contactSAPNumber = '';
            Type erpAddressService = Type.forName(ECOM_Constant.ERP_ADDRESS_SERVICE);
            ERP_IAddressService erpAddressServiceInstance = (ERP_IAddressService)erpAddressService.newInstance();
            List<ERP_RelationShip__c> erpRelationships = erpAddressServiceInstance.fetchERPRelationshipsByERPAddress(us.ContactId, String.valueOf(cart.Default_Ship_to_ERP_Address__r.Target_Address__c));
            if(erpRelationships != null && erpRelationships.size() > 0){
                contactSAPNumber = erpRelationships[0].ERP_Contact_ID__c;
            }
            cart.SAP_Contact_ID__c = contactSAPNumber;
            //RWPS-553 logic end
            listCart.add(cart);
            ECOM_CartService.updateCart(listCart);

            prepareCartForOrder(cartId);

            Map<String, Object> inputs = new Map<String, Object>();
            inputs.put('varCartId',cartId);
            Object BackgroundOperationId;
            CartCheckoutSession checkoutSession;
            if(!Test.isRunningTest()){
            Flow.Interview flw = new Flow.Interview.SUB_FLOW_4498_ECOM_Auto_Create_Cart_To_Order(inputs);
            flw.start();
                BackgroundOperationId = flw.getVariableValue('varBackgroundOperationId');
                checkoutSession = ECOM_CartService.getCartCheckoutSession(String.valueOf(BackgroundOperationId));
                if(checkoutSession == null ){
                    CartCheckoutSession session = new CartCheckoutSession();
                    session.Name = cartId;
                    session.State = ECOM_Constant.SESSION_STATE_START;
                    session.NextState = ECOM_Constant.SESSION_STATE_DELIVERY;
                    session.WebCartId = cartId;
                    checkoutSession = ECOM_CartService.createCartCheckoutSession(session);
                }
            }
            else{
                checkoutSession = [SELECT Id,OrderId FROM CartCheckoutSession LIMIT 1];
            }
            if(checkoutSession.OrderId == null ){ //RWPS-1382  RWPS-2786
                Flow.Interview orderflow = new Flow.Interview.SUB_FLOW_4498_ECOM_Auto_Create_Cart_To_Order(inputs);
                orderflow.start();
                checkoutSession = ECOM_CartService.getCartCheckoutSessionByCartId(cartId);
            }
            if(paymentDataMap.containsKey('paymentMethod') && paymentDataMap.get('paymentMethod') != null && paymentDataMap.get('paymentMethod') == 'cc'
                && paymentDataMap.containsKey('paymentId') && paymentDataMap.containsKey('paymentAuthorization')
            ){
                CardPaymentMethod cpm = new CardPaymentMethod();
                cpm.ECOM_Order__c = checkoutSession.OrderId;
                cpm.id = String.valueOf(paymentDataMap.get('paymentId')) ;
                PaymentAuthorization pa = new PaymentAuthorization();
                pa.ECOM_Order__c = checkoutSession.OrderId;
                pa.id = String.valueOf(paymentDataMap.get('paymentAuthorization'));
                ECOM_OrderService.updatePaymentAuthorizationForOrder(pa);
                ECOM_OrderService.updateCardPaymentForOrder(cpm);
            }
            //RWPS-3362 start
            Map<String, Object> activateOrderInput = new Map<String, Object>();
            activateOrderInput.put('cartId',cartId);
            activateOrderInput.put('checkoutSessionId',checkoutSession.Id);
            if(!Test.isRunningTest()) {
                Flow.Interview activateOrderFlow = new Flow.Interview.SUB_FLOW_4482_ECOMOrder_UpdateOrderActivation(activateOrderInput);
                activateOrderFlow.start();
            }
            // cart.status = 'Closed';
            // ECOM_CartService.updateCart(new list<webCart>{cart});
            // RWPS-3303 end
            // Changes for ECOM-1947 by sathiya for e-invoice field sync to order
            cart = ECOM_CartService.getPrimaryCartBasedOnId(cartId);
            String invCustId = cart?.Default_Bill_to_ERP_Address__r?.ECOM_E_Invoice_Cust_Id__c == null?'':cart?.Default_Bill_to_ERP_Address__r?.ECOM_E_Invoice_Cust_Id__c;
            String billToCountry = (cart?.Default_Bill_to_ERP_Address__r?.apiCountry__c != null?cart?.Default_Bill_to_ERP_Address__r?.apiCountry__c:(cart?.Default_Bill_to_ERP_Address__r?.fxAddress_CountryName__c!=null?cart?.Default_Bill_to_ERP_Address__r?.fxAddress_CountryName__c:''));
            //Boolean isMergeInvoiceCode1 = billToCountry.toLowerCase() == 'fr' || billToCountry.toLowerCase() == 'france';
            Order order = new Order(Id = checkoutSession.OrderId);
            order.ECOM_E_Invoice_Code1__c = cart?.ECOM_E_Invoice_Code1__c;
            order.ECOM_E_Invoice_Code2__c = cart?.ECOM_E_Invoice_Code2__c;
            order.ECOM_E_Invoice_Code3__c = cart?.ECOM_E_Invoice_Code3__c;
            order.ECOM_E_Invoice_Code4__c = cart?.ECOM_E_Invoice_Code4__c;
            order.ECOM_E_Invoice_Cost_Center__c = cart?.ECOM_E_Invoice_Cost_Center__c;
            order.ECOM_E_Invoice_Tax_Exempt__c = cart?.ECOM_E_Invoice_Tax_Exempt__c;
            order.Default_Bill_to_ERP_Address__c = cart?.Default_Bill_to_ERP_Address__c;
            order.Default_Ship_to_ERP_Address__c = cart?.Default_Ship_to_ERP_Address__c;
            order.Default_Invoice_ERP_Address__c = cart?.Default_Invoice_ERP_Address__c;
            order.ECOM_End_User_For_Trade__c = endUserForTrade; //RWPS-1285
            order.ECOM_Accepted_Date__c = acceptedDate; //RWPS-1285
            order.ECOM_End_User_Address__c = endUserAddress;  //RWPS-1285
            order.Invoice_Email__c = invoiceEmailAddress;//RWPS-1882
            
            //RWPS-6394 start
            if(String.isNotBlank(invoiceCustId) && order.Default_Bill_to_ERP_Address__c != null){
                ECOM_CartRepo.updateEInvoiceCustIdOnERPAddress(order.Default_Bill_to_ERP_Address__c, invoiceCustId);
            }
            //RWPS-6394 end
            // ECOM_OrderService.updateOrders(new List<Order>{order}); RWPS-3362
            // Changes end
            //update special instructions on order delivery group
            if(checkoutSession.OrderId != null){ //RWPS-1382
                updateOrderDeliveryGroup(cartId, checkoutSession.OrderId);
            }
            //RWPS-3362 start
            order.Status = 'Draft';
            ECOM_OrderService.updateOrders(new List<Order>{order});
            //RWPS-3362 end
            responseMap.put('Status','Success');
            responseMap.put('OrderId',checkoutSession.OrderId);

        }catch(exception ex){
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.CHECKOUT_MODULE_NAME, className, methodName, supportData);
            responseMap.put('Status','Error');
            responseMap.put('Exception',ex.getMessage());
            responseMap.put('ExceptionStack',ex.getStackTraceString());
        }
        return responseMap;
    }

    /**
    * @description
    * @author mkumar@rafter.one | 11-08-2023
    * @param effectiveAccountId
    * @param cartId
    * @param paymentDataMap
    * @return Map<String, Object>
    **/
    @AuraEnabled
    public static Map<String,Object> createCreditCardPayment(String effectiveAccountId, String cartId, Map<String,Object> paymentDataMap){
        String supportData = '';
        String methodName = 'createCreditCardPayment';
        Map<String,Object> responseMap = new  Map<String,Object>();
        responseMap.put('Status','Error');
        try{
            supportData = 'effectiveAccountId = '+effectiveAccountId+' cartId = '+cartId;
            CardPaymentMethod cpm = new CardPaymentMethod();
            PaymentAuthorization pa = new PaymentAuthorization();
            if(paymentDataMap.containsKey('paymentMethod') && paymentDataMap.get('paymentMethod') != null && paymentDataMap.get('paymentMethod') == 'cc'){
                //card payment method lookup to order
                cpm.ProcessingMode = 'External';
                cpm.Status = 'InActive';
                if(paymentDataMap.containsKey('paymentmethodfirstname') && paymentDataMap.get('paymentmethodfirstname') != null){
                    cpm.CardHolderFirstName = String.ValueOf(paymentDataMap.get('paymentmethodfirstname'));
                }
                if(paymentDataMap.containsKey('paymentmethodlastname') && paymentDataMap.get('paymentmethodlastname') != null){
                    cpm.CardHolderLastName = String.ValueOf(paymentDataMap.get('paymentmethodlastname'));
                }
                if(paymentDataMap.containsKey('paymentmethodemail') && paymentDataMap.get('paymentmethodemail') != null){
                    cpm.Email = String.ValueOf(paymentDataMap.get('paymentmethodemail'));
                }
                //RWPS-1107
                /*if(paymentDataMap.containsKey('paymentmethodlast4') && paymentDataMap.get('paymentmethodlast4') != null){
                    cpm.CardLastFour = Integer.ValueOf(paymentDataMap.get('paymentmethodlast4'));
                }*/
                if(paymentDataMap.containsKey('paymentmethodtoken') && paymentDataMap.get('paymentmethodtoken') != null){
                    cpm.CardLastFour = Integer.ValueOf(String.ValueOf(paymentDataMap.get('paymentmethodtoken')).right(4));
                }
                if(paymentDataMap.containsKey('paymentmethodtype') && paymentDataMap.get('paymentmethodtype') != null){
                    cpm.CardType = String.ValueOf(paymentDataMap.get('paymentmethodtype'));
                }
                if(paymentDataMap.containsKey('paymentmode') && paymentDataMap.get('paymentmode') != null){
                    cpm.CardCategory = String.ValueOf(paymentDataMap.get('paymentmode')) == 'CC'? 'CreditCard':'DebitCard';
                }
                if(paymentDataMap.containsKey('paymentmethodexpirationmonth') && paymentDataMap.get('paymentmethodexpirationmonth') != null){
                    cpm.ExpiryMonth = Integer.ValueOf(paymentDataMap.get('paymentmethodexpirationmonth'));
                }
                if(paymentDataMap.containsKey('paymentmethodexpirationyear') && paymentDataMap.get('paymentmethodexpirationyear') != null){
                    cpm.ExpiryYear = Integer.ValueOf(paymentDataMap.get('paymentmethodexpirationyear'));
                }
                if(paymentDataMap.containsKey('paymentmethodstreet') && paymentDataMap.get('paymentmethodstreet') != null){
                    cpm.Address_Street_Line_1__c = String.ValueOf(paymentDataMap.get('paymentmethodstreet'));
                }
                if(paymentDataMap.containsKey('paymentmethodcity') && paymentDataMap.get('paymentmethodcity') != null){
                    cpm.Address_City__c = String.ValueOf(paymentDataMap.get('paymentmethodcity'));
                }
                if(paymentDataMap.containsKey('paymentmethodstate') && paymentDataMap.get('paymentmethodstate') != null){
                    cpm.apiState__c = String.ValueOf(paymentDataMap.get('paymentmethodstate'));
                }
                if(paymentDataMap.containsKey('paymentmethodcountry') && paymentDataMap.get('paymentmethodcountry') != null){
                    cpm.apiCountry__c = String.ValueOf(paymentDataMap.get('paymentmethodcountry'));
                }
                if(paymentDataMap.containsKey('paymentmethodzip') && paymentDataMap.get('paymentmethodzip') != null){
                    cpm.Address_Postal_Code__c = String.ValueOf(paymentDataMap.get('paymentmethodzip'));
                }
                if(!Test.isRunningTest())
                ECOM_OrderService.createCardPaymentForOrder(cpm);
                pa.Status = 'Processed';
                pa.ProcessingMode = 'External';
                if(paymentDataMap.containsKey('totaltransactionamount') && paymentDataMap.get('totaltransactionamount') != null){
                    pa.Amount =  Double.ValueOf(paymentDataMap.get('totaltransactionamount'));
                }
                if(paymentDataMap.containsKey('currencycode') && paymentDataMap.get('currencycode') != null){
                    pa.CurrencyIsoCode = String.ValueOf(paymentDataMap.get('currencycode'));
                }
                if(paymentDataMap.containsKey('authorizationnumber') && paymentDataMap.get('authorizationnumber') != null){
                    pa.ECOM_Authorization_Number__c = String.ValueOf(paymentDataMap.get('authorizationnumber'));
                }
                if(paymentDataMap.containsKey('merchantid') && paymentDataMap.get('merchantid') != null){
                    pa.ECOM_Merchant_Id__c = String.ValueOf(paymentDataMap.get('merchantid'));
                }
                if(paymentDataMap.containsKey('paymentmethodtoken') && paymentDataMap.get('paymentmethodtoken') != null){
                    pa.ECOM_Payment_Method_Token__c = String.ValueOf(paymentDataMap.get('paymentmethodtoken'));
                }

                if(paymentDataMap.containsKey('pgtext') && paymentDataMap.get('pgtext') != null){
                    pa.ECOM_PG_Return_Description__c = String.ValueOf(paymentDataMap.get('pgtext'));
                }
                if(paymentDataMap.containsKey('pgtransactionid') && paymentDataMap.get('pgtransactionid') != null){
                    pa.ECOM_PG_Transaction_Id__c = String.ValueOf(paymentDataMap.get('pgtransactionid'));
                }
                if(paymentDataMap.containsKey('paymenttransactionid') && paymentDataMap.get('paymenttransactionid') != null){
                    pa.ECOM_Payment_Transaction_Id__c = String.ValueOf(paymentDataMap.get('paymenttransactionid'));
                }
                if(paymentDataMap.containsKey('transactionstatus') && paymentDataMap.get('transactionstatus') != null){
                    pa.ECOM_Authorization_Flag__c = String.ValueOf(paymentDataMap.get('transactionstatus'));
                }
                if(paymentDataMap.containsKey('transactiontype') && paymentDataMap.get('transactiontype') != null){
                    pa.ECOM_Authorization_Type__c = String.ValueOf(paymentDataMap.get('transactiontype'));
                }
                ECOM_OrderService.createPaymentAuthorizationForOrder(pa);
            }
            Webcart cart = new Webcart();
            cart.Id = cartId;
            cart.PaymentMethodId = cpm.Id;
            cart.ECOM_Payment_Authorization__c = pa.Id;
            ECOM_CartService.updateCart(new list<webCart>{cart});
            responseMap.put('Status','Success');
            responseMap.put('paymentId',cpm.Id);
            responseMap.put('paymentAuthorization',pa.Id);
        }catch(exception ex){
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.CHECKOUT_MODULE_NAME, className, methodName, supportData);
            responseMap.put('messgae',ex.getMessage());
        }
        return responseMap;
    }

    /**
     * RWPS-2547 | 12-2-2025
    @description this method is used to get SAP order number
    @param orderId
    @return String
    */
    @AuraEnabled
    public static String getSAPOrderNumber(String orderId) {
        ECOM_OrderModel orderModel = ECOM_OrderService.getOrderDetails(orderId);
        return orderModel.sapOrderNumber;
    }

    /**
    * @description  this Method is used to get all the relevant data that needs to be displaed on order confirmation page.
    * @author Manish 2023.08.24
    * @param communityId
    * @param effectiveAccountId
    * @param orderId
    * @param productFields
    * @param objectName
    * @return Map<String,Object>
    **/
    @AuraEnabled
    public static Map<String,Object> getOrderConfirmationDetails(String communityId, String effectiveAccountId, String orderId, List<String> productFields, String objectName){
        String supportData = '';
        String methodName = 'getOrderConfirmationDetails';
        Map<String,Object> responseMap = new  Map<String,Object>();
        Map<String,Boolean> salesStatusMap = new Map<String,Boolean>();
         Map<String,Boolean> trainingProductMap = New Map<String,Boolean>();//RWPS-4896
        try{
            supportData = 'communityId = '+communityId+' effectiveAccountId = '+effectiveAccountId+' orderId = '+orderId;

            Type userService = Type.forName(ECOM_Constant.USER_Service);
            ECOM_IUserService userServiceInstance = (ECOM_IUserService)userService.newInstance();
            User user = userServiceInstance.getUserByUserId();

            String webstoreId = ECOM_Util.resolveCommunityIdToWebstoreId(communityId);
            String wishListId = '';
            List<WishList> wishListDetails = getWishlistDetails();
            if(wishListDetails != null & !wishListDetails.isEmpty()){
                for(WishList wl: wishListDetails){
                    if(wl.AccountId == effectiveAccountId){
                        wishListId = wl.Id;
                        break;
                    }
                }
            }

            //To clear the cache
            ECOM_SessionCacheUtil.clearEcomCache();

            //Contact contact = getContactInfo();
            Map<String,String> fieldsMap = getFieldsByObjectName(objectName);
            List<Order> orders = ECOM_OrderService.getOrdersById(new Set<String>{orderId});
            List<String> ProductIds = new List<String>();
            Set<String> productIdSet = new Set<String>();
            
            Map<String,String> freeItemMap = new Map<String,String>(); //RWPS-3811
            for(OrderItem oi: orders[0].OrderItems){
                // RWPS - 2270 START
                if(oi.Product2!=null && oi.Product2.Product_Display_Name__c==null){
                    oi.Product2.Product_Display_Name__c = oi.Product2.Name;
                }
                // RWPS - 2270 END
                if(oi.Type == 'Order Product'){
                    ProductIds.add(oi.Product2Id);
                    productIdSet.add(oi.Product2Id);
                } //RWPS-3811
                if(String.isNotEmpty(oi.ecom_parent_item__c)) {
                    freeItemMap.put(oi.ecom_parent_item__c, getParentPartNumber(orders[0],oi.ecom_parent_item__c));
                }
            }

            //RWPS-4896
            List<Product_Recommendation__c> productRecommendList = ECOM_ProductRecommendationsRepo.getRecommendationsTrainingProducts('Combination',productIdSet);
            for(Product_Recommendation__c pr : productRecommendList){
                trainingProductMap.put(pr.Product_Suggested__c, true);
            }
            //RWPS-4896

            String moduleName = 'ECOM_CartService';
            List<String> materialCodes = ECOM_CartUtil.fetchProductMaterialStatus(moduleName);
            List<Product_Sales__c> prodSales = ECOM_ProductService.getProductSales(productIdSet, materialCodes);
            Map<String,String> productToSalesStatus = new Map<String,String>();
            for (Product_Sales__c prod : prodSales) {
              productToSalesStatus.put(prod.Product__c, prod.Distribution_ChainSpecificMaterialStatus__c);
              if(prod.Distribution_ChainSpecificMaterialStatus__c == 'ZM'){
                salesStatusMap.put(prod.Product__c, true);
              }
              else {
                salesStatusMap.put(prod.Product__c, false);
              }
            }

            ConnectApi.ProductOverviewCollection ProductsOverview = Test.isRunningTest()? ECOM_TestUtil.getProductOverviewCollection():ECOM_ProductService.getProducts(webstoreId, effectiveAccountId, ProductIds, productFields, false);
            Map<String, Object> emailPrefMap = getEmailPreferences(effectiveAccountId);

            responseMap.put('Status','Success');
            responseMap.put('userEmail',user.Email);
            responseMap.put('Order',orders[0]);
            responseMap.put('salesStatus', salesStatusMap);
            responseMap.put('ProductsOverview',ProductsOverview);
            responseMap.put('wishListId',wishListId);
            responseMap.put('fieldsMap',fieldsMap);
            responseMap.put('freeItemMap', freeItemMap); //RWPS-3811
            responseMap.put('trainingProducts', trainingProductMap);//RWPS-4896
            Boolean isAcceptanceRequried = false;
            if(orders[0]?.ECOM_Cart_Id__c != null){
                List<WebCart> WebCarts = getCartandCartItemsById(orders[0]?.ECOM_Cart_Id__c);
                if(!WebCarts.isEmpty()){
                    if(String.isNotBlank(WebCarts[0].Default_Ship_to_ERP_Address__c)){
                        if(WebCarts[0].Default_Ship_to_ERP_Address__r.ECOM_Approver_Enabled__c){
                            if(String.isNotBlank(WebCarts[0].Default_Ship_to_ERP_Address__r.ECOM_RAD_Approval_Status__c)){
                                if(WebCarts[0].Default_Ship_to_ERP_Address__r.ECOM_RAD_Approval_Status__c.equalsIgnoreCase('RAD')){
                                    for(CartItem ci:WebCarts[0].CartItems){
                                        if(
                                            String.isNotBlank(ci.Product2.Dangerous_Goods_Indicator_Profile__c) &&
                                            (ci.Product2.Dangerous_Goods_Indicator_Profile__c.equalsIgnoreCase('Yes') || ci.Product2.Dangerous_Goods_Indicator_Profile__c.equalsIgnoreCase('Y') || ci.Product2.Dangerous_Goods_Indicator_Profile__c.equalsIgnoreCase('RAD'))
                                        ){
                                            isAcceptanceRequried = true;
                                            break;
                                        }
                                    }
                                } else {
                                    isAcceptanceRequried = true;
                                }
                            }
                        }
                    }
                }
            }
            responseMap.put('AcceptanceRequired', isAcceptanceRequried);

            if(emailPrefMap.containskey('Status') && emailPrefMap.get('Status') == 'Success'){
                //responseMap.put('listEmailPreferences',emailPrefMap.get('listEmailPreferences'));
                responseMap.put('ListEmailPrefAccountLvl',emailPrefMap.get('ListEmailPrefAccountLvl'));
                responseMap.put('ListEmailPrefContactLvl',emailPrefMap.get('ListEmailPrefContactLvl'));
            }

            Map<String,Object> addressInfoResponseMap = getAddressInfo(orders[0].ECOM_Cart_Id__c);
            if(addressInfoResponseMap.containsKey('Status') && addressInfoResponseMap.get('Status') == 'Success'){
                responseMap.put('contact',addressInfoResponseMap.get('contact'));
                responseMap.put('shipToModel',addressInfoResponseMap.get('shipToModel'));
            }

            List<CardPaymentMethod> cpmList = ECOM_OrderService.getCardPaymentBasedOnOrder(orders[0].Id);
            //CardPaymentMethod cpm = [SELECT Id, CardCategory, CardHolderFirstName, CardHolderLastName, CardLastFour, CardType, ECOM_Order__c, Email, ExpiryMonth, ExpiryYear, ProcessingMode, Status FROM CardPaymentMethod WHERE Status = 'Active' AND ECOM_Order__c =: orders[0].Id LIMIT 1];
            if(!cpmList.isEmpty()){
                responseMap.put('CardPaymentMethod',cpmList[0]);
            }

            // Added by sathiya on 2024/05/02 for ECOM-1933
            responseMap.put('billToValidationFields', ECOM_CustomMetadataService.getStoreConfigurationByLabel(ECOM_Constant.BILL_TO_FIELD_VALIDATION));
            // Changes end by sathiya
            // Added by sathiya on 2024/05/13 for ECOM-1947
            responseMap.put('invoiceValidationFields', ECOM_CustomMetadataService.getStoreConfigurationByLabel(ECOM_Constant.INVOICE_FIELD_VALIDATION));
            // Changes end by sathiya
        }catch(Exception ex){
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.CHECKOUT_MODULE_NAME, className, methodName, supportData);
            responseMap.put('Status','Error');
            responseMap.put('Exception',ex.getMessage());
        }

        return responseMap;
    }

    /**
    * @description
    * @author mkumar@rafter.one | 09-21-2023
    * @return List<WishList>
    **/
    @AuraEnabled
    public static List<WishList> getWishlistDetails()
    {
        List<WishList> wishListDetails = ECOM_AccountService.fetchWishList(UserInfo.getUserId());//ECOM_AccountUtil.getWishListDetails(UserInfo.getUserId());
        return wishListDetails;
    }

    /**
    * @description
    * @author ssingh@rafter.one | 10-16-2023
    * @return List<ECOM_AccountWrapper.WishlistDetails>
    **/
    @AuraEnabled
    public static List<ECOM_AccountWrapper.WishlistDetails> getWishlistDetailsWrapped()
    {
    Type accountService = Type.forName(ECOM_Constant.ACCOUNT_SERVICE);
    ECOM_IAccountService accountServiceInstance = (ECOM_IAccountService)accountService.newInstance();
    List<WishList> wls = accountServiceInstance.fetchWishList(UserInfo.getUserId());
    List<ECOM_AccountWrapper.WishlistDetails> wishListDetails = ECOM_AccountUtil.getWishListDetails(wls);
    return wishListDetails;
    }

    /**
    * @description
    * @author mkumar@rafter.one | 09-21-2023
    * @param communityId
    * @param productId
    * @param wishListId
    * @param effectiveAccountId
    * @return ConnectApi.WishlistItem
    **/
    @AuraEnabled
    public static ConnectApi.WishlistItem createAndAddToList(
        String communityId,
        String productId,
        String wishListId,
        String effectiveAccountId
    ) {
        // Lookup the webstore ID associated with the community
        String webstoreId = ECOM_Util.resolveCommunityIdToWebstoreId(communityId);
        ConnectApi.Wishlist wishlist;
        ConnectApi.WishlistItem wishListItem;
        // Store the product in a WishlistItemInput to pass to the Wishlist
        ConnectApi.WishlistItemInput wishlistItemInput = new ConnectApi.WishlistItemInput();
        wishlistItemInput.productId = productId;

        if(String.isNotBlank(wishListId)){
            wishListItem = ECOM_AccountService.addItemToWishlist( webstoreId, effectiveAccountId,  wishListId,  wishlistItemInput);
        }else{
            //Create a wishlistInput to be created
            ConnectApi.WishlistInput wishlistInput = new ConnectApi.WishlistInput();
            wishlistInput.name = 'My favorite list';
            wishlistInput.products = new List<ConnectApi.WishlistItemInput>{wishlistItemInput};
            wishlist =  ECOM_AccountService.createWishlist(webstoreId, effectiveAccountId, wishlistInput);

            ConnectApi.WishlistItemCollection collection =  wishlist.page;
            List<ConnectApi.WishlistItem> wishListItems = Test.isRunningTest()? ECOM_TestUtil.getWishlistItemListData(): collection.items;
            wishListItem = wishListItems.size() > 0? wishListItems[0] : null;
        }
        return wishListItem;
    }

    /**
    * @description
    * @author mkumar@rafter.one | 09-21-2023
    * @param cartId
    **/
    public static void prepareCartForOrder(String cartId){
        // @manoj Move all SOQL to Repo
        WebCart webCartObject = [Select Id, CurrencyIsoCode FROM WebCart WHERE Id =: cartId];
        Id cartDeliveryGroupId = [SELECT CartDeliveryGroupId FROM CartItem WHERE CartId = :cartId][0].CartDeliveryGroupId;
        delete [SELECT Id FROM CartDeliveryGroupMethod WHERE CartDeliveryGroupId = :cartDeliveryGroupId];

        Id defaultOrderDeliveryMethodId = getDefaultOrderDeliveryMethod();
        Integer amount = 0;
        Id defaultDeliveryMethodId = ECOM_CartUtil.populateDefaultCartDeliveryGroupMethod(cartDeliveryGroupId, defaultOrderDeliveryMethodId, webCartObject, amount);
        CartDeliveryGroupMethod selectedCartDeliveryGroupMethod = [SELECT ShippingFee, DeliveryMethodId FROM CartDeliveryGroupMethod WHERE CartDeliveryGroupId = :cartDeliveryGroupId][0];
         Decimal shippingRate = selectedCartDeliveryGroupMethod.ShippingFee;
            Id orderDeliveryMethodId = selectedCartDeliveryGroupMethod.DeliveryMethodId;

        addOrderDeliveryMethodToCartDeliveryGroup(orderDeliveryMethodId, cartDeliveryGroupId, defaultDeliveryMethodId);
    }

    /**
    * @description
    * @author mkumar@rafter.one | 09-21-2023
    * @return Id
    **/
    @TestVisible
    private static Id getDefaultOrderDeliveryMethod() {
        Id defaultDeliveryMethodId = null;
        Id product2IdForThisDeliveryMethod = getDefaultShippingChargeProduct2Id();

        // Check to see if a default OrderDeliveryMethod already exists.
        // If it doesn't exist, create one.
        Type orderService = Type.forName(ECOM_Constant.ORDER_Service);
        ECOM_IOrderService orderServiceInstance = (ECOM_IOrderService)orderService.newInstance();
        List<OrderDeliveryMethod> defaultOrderDeliveryMethods = orderServiceInstance.getOrderDeliveryMethods(ECOM_Constant.DEFAULT_DELIVERY_METHOD);
        if (defaultOrderDeliveryMethods.isEmpty()) {
            OrderDeliveryMethod defaultOrderDeliveryMethod = new OrderDeliveryMethod(
                Name = ECOM_Constant.DEFAULT_DELIVERY_METHOD,
                isActive = true,
                ProductId = product2IdForThisDeliveryMethod
            );
            insert(defaultOrderDeliveryMethod);
            defaultDeliveryMethodId = defaultOrderDeliveryMethod.Id;
        }
        else {
            // If the OrderDeliveryMethod doesn't have a Product2 associated with it, assign one
            OrderDeliveryMethod defaultOrderDeliveryMethod = defaultOrderDeliveryMethods[0];
            if (defaultOrderDeliveryMethod.ProductId == null) {
                defaultOrderDeliveryMethod.ProductId = product2IdForThisDeliveryMethod;
                update(defaultOrderDeliveryMethod);
                defaultDeliveryMethodId = defaultOrderDeliveryMethod.Id;
            }
            else {
                defaultDeliveryMethodId = defaultOrderDeliveryMethod.Id;
            }
        }

        return defaultDeliveryMethodId;
    }

    /**
    * @description
    * @author mkumar@rafter.one | 09-21-2023
    * @param orderDeliveryMethodId
    * @return Id
    **/
    @TestVisible
    private static Id getShippingChargeProduct2Id(Id orderDeliveryMethodId) {
        // The Order Delivery Method should have a Product2 associated with it, because we added that in getDefaultOrderDeliveryMethod if it didn't exist.
        Type orderService = Type.forName(ECOM_Constant.ORDER_Service);
        ECOM_IOrderService orderServiceInstance = (ECOM_IOrderService)orderService.newInstance();
        List<OrderDeliveryMethod> orderDeliveryMethods = orderServiceInstance.getOrderDeliveryMethodsById(orderDeliveryMethodId);
        return orderDeliveryMethods[0].ProductId;
    }

    /**
    * @description
    * @author mkumar@rafter.one | 09-21-2023
    * @param someOrderDeliveryMethodId
    * @param someCartDeliveryGroupId
    * @param someSelectedDeliveryMethodId
    **/
    private static void addOrderDeliveryMethodToCartDeliveryGroup(Id someOrderDeliveryMethodId, Id someCartDeliveryGroupId, Id someSelectedDeliveryMethodId ) {
        Contact contact = getContactInfo();
        // The OrderDeliveryMethod is added to the CartDeliveryGroup for the order to be properly created during checkout.
        Type cartService = Type.forName(ECOM_Constant.CART_Service);
        ECOM_ICartService cartServiceInstance = (ECOM_ICartService)cartService.newInstance();
        List<CartDeliveryGroup> cartDeliveryGroups = cartServiceInstance.getCartDeliveryGroupById(someCartDeliveryGroupId);

        CartDeliveryGroup cartDeliveryGroup = new CartDeliveryGroup();
        cartDeliveryGroup.Id = cartDeliveryGroups[0].Id;
        cartDeliveryGroup.DeliveryMethodId = someOrderDeliveryMethodId;
        cartDeliveryGroup.DeliverToName = contact.ECOM_Attention_Recipient__c;
        cartDeliveryGroup.ShippingInstructions = contact.ECOM_Delivery_Details__c;
        cartDeliveryGroup.ECOM_Special_Instructions__c  = contact.ECOM_Special_Instructions__c;
        List<CartDeliveryGroup> updatedList = cartServiceInstance.updateCartDeliveryGroups(new List<CartDeliveryGroup>{CartDeliveryGroup});
    }

    public static void updateOrderDeliveryGroup(String cartId, String orderId){
        CartDeliveryGroup cartDeliveryGroup = [SELECT Id, DeliverToName, ECOM_Special_Instructions__c,ShippingInstructions FROM CartDeliveryGroup WHERE CartId = :cartId];
        OrderDeliveryGroup odGroup = [SELECT ID FROM OrderDeliveryGroup WHERE OrderId = :orderId];
        OrderDeliveryGroup odGrpToUpadate = new OrderDeliveryGroup();
        odGrpToUpadate.id = odGroup.Id;
        odGrpToUpadate.ECOM_Special_Instructions__c = cartDeliveryGroup.ECOM_Special_Instructions__c;
        odGrpToUpadate.DeliveryInstructions = cartDeliveryGroup.ShippingInstructions;
        update odGrpToUpadate;
    }

    /**
    * @description
    * @author mkumar@rafter.one | 09-21-2023
    * @return Id
    **/
    private static Id getDefaultShippingChargeProduct2Id() {
        // In this example we will name the product representing shipping charges 'Shipping Charge for this delivery method'.
        // Check to see if a Product2 with that name already exists.
        // If it doesn't exist, create one.
        // Move SOQL to Repo
        String shippingChargeProduct2Name = 'Shipping Charge for this delivery method';
        List<Product2> shippingChargeProducts = [SELECT Id FROM Product2 WHERE Name = :shippingChargeProduct2Name];
        if (shippingChargeProducts.isEmpty()) {
            Product2 shippingChargeProduct = new Product2(
                isActive = true,
                Name = shippingChargeProduct2Name
            );
            insert(shippingChargeProduct);
            return shippingChargeProduct.Id;
        }
        else {
            return shippingChargeProducts[0].Id;
        }
    }

    /**
    * @description
    * @author mkumar@rafter.one | 09-21-2023
    * @param cartId
    * @return WebCart
    **/
    @AuraEnabled
    public static WebCart getCartPromoCode(String cartId){
       WebCart cart = ECOM_CartService.getCartandCartItemsById(cartId)[0];
        return cart;
    }

    /**
    * @description
    * @author manish.kumar@rafter.one | 09-21-2023
    * @param cartId
    * @return WebCart
    **/
    @AuraEnabled
    public static List<C_META_Storefront_Configuration__mdt> getPaymentInItData(){
        return ECOM_CustomMetadataService.fetchStoreConfigMdtBasedOnModuleName('Payment');
    }

    /**
    * @description
    * @author ssingh@rafter.one | 09-29-2023
    * @param cartId
    * @return List<WebCart>
    **/
    @AuraEnabled
    public static List<WebCart> getCartandCartItemsById(String cartId){
        return ECOM_CartService.getCartandCartItemsById(cartId);
    }

 /**
  * @description  This method invokes order simulate Api
  * @author ssingh@rafter.one | 11-16-2023
  * @param cartId
  * @return Map<String, Object>
  **/
  @AuraEnabled
  public static Map<String,Object> repriceCart(String cartId, String couponCode) {
    Map<String,Object> response = ECOM_CartService.repriceCart(cartId, couponCode);
    return response;
  }

  /**
  * @description  This method updated bill to/ship to values on cart
  * @author ssingh@rafter.one | 10-10-2024
  * @param cartId
  **/
  @AuraEnabled
  public static void updateBillToShipToOnCart(String cartId) {
    ECOM_CartService.updateBillToShipToOnCart(cartId);
  }

 /**
  * @description  This method is used to get the Credit Collection Emails from Custom Metadata
  * @author ssingh@rafter.one | 11-16-2023
  * @param moduleName
  * @return Map<String,String>
  **/
  @AuraEnabled
  public static Map<String,String> getCreditCollections(String moduleName)
  {
      return ECOM_CartService.getCreditCollections(moduleName);
  }

  /**
  * @description  This method is used to get default ship to SAP number
  * @author mkumar@rafter.one | 12-19-2023
  * @return Map<String, Object>
  **/
  @AuraEnabled
  public static Map<String,Object> getDefaultShipToSAPNumber(){
        Map<String,Object> response = new Map<String,Object>();
        try {
            response.put('success', true);
            User us = new ECOM_UserService().getUserByUserId();
            ECOM_DummyAccountCountryMapping__mdt defaultmdt;
            String erpShipToId = '';
            if(us.Contact != null && us.Contact.ECOM_CountryProvided__c != null){
                defaultmdt = ECOM_CustomMetadataService.fetchDummyAccountCountryMappingData(ECOM_Util.getCountryFromUser(us));
                erpShipToId = defaultmdt.Default_Ship_to__c !=null ?defaultmdt.Default_Ship_to__c  : '';
                response.put('defaultSAPNumber',erpShipToId);
            }else{
                response.put('message', 'Default Account not setup');
            }
        } catch (Exception e) {
            response.put('success', false);
            response.put('message', e.getMessage());
        }
        return response;
  }

  /**
  * @description  This method is used to get the user details for validating address on cart
  * @author manish.kumar@rafter.one | Nov 29th 2023
  * @return Map<String,String>
  **/
  @AuraEnabled
  public static Map<String,Object> getUserInfo(){

    String supportData = 'quering user data';
    String methodName = 'getUserInfo';
    Map<String,Object> responseMap = new  Map<String,Object>();
    try {
            Type userService = Type.forName(ECOM_Constant.USER_Service);
            ECOM_IUserService userServiceInstance = (ECOM_IUserService)userService.newInstance();
            User user = userServiceInstance.getUserByUserId();
            responseMap.put('status','SUCCESS');
            responseMap.put('user',user);
    } catch (Exception ex) {
      system.debug('Exception '+ex);
      ECOM_ApplicationLogsUtil.logFailure(ex, '', 'ECOM_CartController', methodName, supportData);
    }
    return responseMap;
  }

    /**
    * @description This method is used to delete discontinued and non-sellable products from the cart.
    * @param  cartId The Id of active cart
    * @author Prabhat Kumar
    * @date 2025-06-16
    * JIRA :  RWPS-2786
    */
    @AuraEnabled
    public static Map<String, Object> deleteDiscontinuedNonSellableProducts(String cartId) {
        Map<String, Object> response = new Map<String, Object>();
        List<CartItem> lstToDelete = ECOM_CartUtil.fetchNonSellableDiscontinuedCartItems(cartId);
        List<String> lstToDeleteIds = new List<String>();
        Set<string> productIdSet = New Set<String>();//RWPS-4896
        try {
            if (lstToDelete != null && lstToDelete.size() > 0) {
                for(Cartitem item : lstToDelete) {
                    lstToDeleteIds.add(item.Id);

                }
                //RWPS-4896-START
                Map<String, String> mapTrainingProductIds = New Map<String, String>();
                Set<String> suggestProductIds = New Set<String>();
                Integer mainProductCount = 0;
                String trainingproductId = '';
                List<CartItem> listCartItems = ECOM_CartRepo.getCartItemsByCartId(cartId);
                for(CartItem item : listCartItems){
                    productIdSet.add(item.product2id);
                }
                List<Product_Recommendation__c> productRecommendList =  ECOM_ProductRecommendationsRepo.getRecommendationsTrainingProducts('Combination',productIdSet);
                for(Product_Recommendation__c pr : productRecommendList){
                    mapTrainingProductIds.put(pr.Product_Main__c, pr.Product_Suggested__c);
                    suggestProductIds.add( pr.Product_Suggested__c);
                }

                if(productRecommendList.size() > 0){
                    for(CartItem item : listCartItems){
                        if(mapTrainingProductIds.containsKey(item.Product2Id)){
                            mainProductCount++; 
                        }
                    }
                    for(Cartitem item : lstToDelete) {
                        if(mainProductCount == 1 && mapTrainingProductIds.containsKey(item.product2Id)){
                            for(CartItem itemCart : listCartItems){
                                if(suggestProductIds.contains(itemCart.product2Id)){
                                    lstToDeleteIds.add(itemCart.id);  
                                }
                            }
                        }else if(lstToDelete.size() == mapTrainingProductIds.values().size()){
                             for(CartItem itemCart : listCartItems){
                                if(suggestProductIds.contains(itemCart.product2Id)){
                                    lstToDeleteIds.add(itemCart.id);  
                                }
                            }         
                        }
                     }
                }
                //RWPS-4896-END

                ECOM_CartService.deleteCartItemsById(lstToDeleteIds);
                response.put('success', true);
                response.put('deletedItems', lstToDelete);
            } else {
                response.put('success', false);
            }
        } catch (Exception e) {
            ECOM_ApplicationLogsUtil.logFailure(e,'Discountinued Products','ECOM_CheckoutController','deleteDiscontinuedNonSellableProducts',JSON.serialize(lstToDelete));
            response.put('success', false);
            response.put('errorMessage', e.getMessage());
        }

        return response;
    }

    // RWPS-3740
    @AuraEnabled
    public static Map<String, Object> deleteDiscontinuedProductsWithReplacement(String cartId) {
        Map<String, Object> response = new Map<String, Object>();
        List<CartItem> lstToDelete = ECOM_CartUtil.fetchNonSellableDiscontinuedCartItems(cartId);
        List<String> lstToDeleteIds = new List<String>();

        try {

            lstToDeleteIds.addAll(getTrainingCartItemIdsToDelete(cartId,lstToDelete));//RWPS-4896

            if (lstToDelete != null && lstToDelete.size() > 0) {
                for(Cartitem item : lstToDelete) {
                    if (item.Product2.Replacement_Product__c != null || item.Product2.Replacement_Alternatives__c != null) {
                        lstToDeleteIds.add(item.Id);
                    }
                }
                if (!lstToDeleteIds.isEmpty()) {
                    ECOM_CartService.deleteCartItemsById(lstToDeleteIds);
                    response.put('deletedItems', lstToDeleteIds);
                }
                response.put('success', true);
            } else {
                response.put('success', false);
            }
        } catch (Exception e) {
            ECOM_ApplicationLogsUtil.logFailure(e,'Discountinued Products','ECOM_CheckoutController','deleteDiscontinuedNonSellableProducts',JSON.serialize(lstToDeleteIds));
            response.put('success', false);
            response.put('errorMessage', e.getMessage());
        }

        return response;
    }

    /**
    * @description This method deletes Training products in case cellometer product is discontinued.
    * @param  cartId The Id of active cart
    * @param  lstToDelete list of cart items
    * @author Prabhat Kumar
    * @date 2025-12-16
    * JIRA :  RWPS-4896
    */
    public static List<String> getTrainingCartItemIdsToDelete(Id cartId, List<CartItem> lstToDelete) {
        Map<String, String> mapTrainingProductIds = new Map<String, String>();
        Set<String> suggestProductIds = new Set<String>();
        Integer mainProductCount = 0;
        String trainingproductId = '';
        List<CartItem> listCartItems = ECOM_CartRepo.getCartItemsByCartId(cartId);
        Set<String> productIdSet = new Set<String>();
        for (CartItem item : listCartItems) {
            productIdSet.add(item.Product2Id);
        }
        List<Product_Recommendation__c> productRecommendList = ECOM_ProductRecommendationsRepo.getRecommendationsTrainingProducts('Combination', productIdSet);
        for (Product_Recommendation__c pr : productRecommendList) {
            mapTrainingProductIds.put(pr.Product_Main__c, pr.Product_Suggested__c);
            suggestProductIds.add(pr.Product_Suggested__c);
        }
        List<String> lstToDeleteIds = new List<String>();
        if (productRecommendList.size() > 0) {
            for (CartItem item : listCartItems) {
                if (mapTrainingProductIds.containsKey(item.Product2Id)) {
                    mainProductCount++;
                }
            }
            for (CartItem item : lstToDelete) {
                if (mainProductCount == 1 && mapTrainingProductIds.containsKey(item.Product2Id)) {
                    for (CartItem itemCart : listCartItems) {
                        if (suggestProductIds.contains(itemCart.Product2Id)) {
                            lstToDeleteIds.add(itemCart.Id);
                        }
                    }
                } else if (lstToDelete.size() == mapTrainingProductIds.values().size()) {
                    for (CartItem itemCart : listCartItems) {
                        if (suggestProductIds.contains(itemCart.Product2Id)) {
                            lstToDeleteIds.add(itemCart.Id);
                        }
                    }
                }
            }
        }
        return lstToDeleteIds;
    }


    // RWPS-3740
    @AuraEnabled
    public static void deleteReplacedCartItem(String cartItemId){
        List<String> lstToDeleteIds = new List<String>();
        try {
        //RWPS-4896-START
        //get cart item
            Map<String, CartItem> mapCartItems = New Map<String,CartItem>();//RWPS-4896
            CartItem itemCart = ECOM_CartRepo.getCartItemById(cartItemId);
            List<CartItem> listCartItems = ECOM_CartRepo.getCartItemsByCartId(itemCart.cartId);
            Set<String> productIdSet = new Set<String>();

            for(CartItem item : listCartItems){
                productIdSet.add(item.Product2Id);
            }
            //RWPS-4896-START
            Map<String, String> mapTrainingProductIds = New Map<String, String>();
            Set<String> suggestProductIds = New Set<String>();
            Integer mainProductCount = 0;
            List<Product_Recommendation__c> productRecommendList =  ECOM_ProductRecommendationsRepo.getRecommendationsTrainingProducts('Combination',productIdSet);
            for(Product_Recommendation__c pr : productRecommendList){
                mapTrainingProductIds.put(pr.Product_Main__c, pr.Product_Suggested__c);
                suggestProductIds.add( pr.Product_Suggested__c);
            }
            if(productRecommendList.size() > 0){
                for(CartItem item : listCartItems){
                    if(mapTrainingProductIds.containsKey(item.Product2Id)){
                       mainProductCount++; 
                    }
                }
                if(mainProductCount == 1 && mapTrainingProductIds.containsKey(itemCart.product2Id)){
                    for(CartItem item : listCartItems){
                        if(suggestProductIds.contains(item.product2Id)){
                            lstToDeleteIds.add(item.id);  
                        }
                    }
                }
            }
            //RWPS-4896-END

            if (String.isNotBlank(cartItemId)) {
                lstToDeleteIds.add(cartItemId);
                ECOM_CartService.deleteCartItemsById(lstToDeleteIds);
            }
        } catch (Exception e) {
            ECOM_ApplicationLogsUtil.logFailure(e,'Replacement Products','ECOM_CheckoutController','deleteReplacedCartItem',JSON.serialize(lstToDeleteIds));
        }
    }


    /**
    * @description  This method is used to create Application Logs for Payment.
    * @author Sidak 2024.01.09
    * @param
    * @return LMap<String,Object>
    **/
    @AuraEnabled
    public static Map<String,Object> createPaymentLogs(String error, String response){
        String supportData = '';
        String methodName = 'createPaymentLogs';
        String actionType = 'PT';
        Map<String,Object> responseMap = new  Map<String,Object>();
        try{
            ECOM_ApplicationLogsUtil.setupApplicationRecord(ECOM_Constant.PAYMENT_MODULE_NAME, className, methodName, supportData, response, actionType);

        }catch(Exception ex){
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.PAYMENT_MODULE_NAME, className, methodName, supportData);
            responseMap.put('Status','Error');
            responseMap.put('Exception',ex.getMessage());
        }
        return responseMap;
    }

      /**
  * @description  This method is used to generate checkout URL for Punchout User
  * @author garora@rafter.one | 01-09-2024
  * @param Map<String,Object>
  * @return Map<String,Object>
  **/
  @AuraEnabled
  public static Map<String,Object> getCheckoutURL(Map<String,Object> cartSummary)
  {
    String supportData = '';
    String methodName = 'getCheckoutURL';
    Map<String,Object> responseMap = new  Map<String,Object>();
    try{
        Type userService = Type.forName(ECOM_Constant.USER_Service);
        ECOM_IUserService userServiceInstance = (ECOM_IUserService)userService.newInstance();
        User user = userServiceInstance.getUserByUserId();//Getting the user details
        if(user.ECOM_Is_Punchout_User__c){
            responseMap.put(ECOM_Constant.POTYPE_TEST_USER,user.ECOM_Is_Test_User__c);
            List<ECOM_PunchoutPOOMFlowController.PunchoutPOOMRequest> requestList = new List<ECOM_PunchoutPOOMFlowController.PunchoutPOOMRequest>();
            ECOM_PunchoutPOOMFlowController.PunchoutPOOMRequest request = new ECOM_PunchoutPOOMFlowController.PunchoutPOOMRequest();
            request.cartId = (String)cartSummary.get('cartId');
            request.accountId = (String)cartSummary.get('accountId');
            requestList.add(request);
            List<ECOM_POOMModel> POOMResponseList= ECOM_PunchoutPOOMFlowController.getCartModelForPOOM(requestList);//Preparing cart model to send to Boomi
            //Start - RWPS-2721
            if(Test.isRunningTest()){
                POOMResponseList[0].format = 'cmxl';
            }
             //End - RWPS-2721
            if(!POOMResponseList.isEmpty() && String.isNotBlank(POOMResponseList[0].browserFormPost) && String.isNotBlank(POOMResponseList[0].format)){
                List<Object> finalPoom = new List<Object>();
                Map<String,String> requestHeader = new Map<String,String>();
                Map<String,Object> poomBody = new Map<String,Object>();
                poomBody.put('poomResponse',POOMResponseList[0]);
                finalPoom.add(poomBody);
                requestHeader.put(ECOM_Constant.REQUEST_METHOD_TYPE, ECOM_Constant.HTTP_REQUEST_POST);
                requestHeader.put(ECOM_Constant.HTTP_REQUEST_ENDPOINT, ECOM_Util.getStoreNavigationConfig(ECOM_Constant.PARAM_SITE_CHECKOUT_NAVIGATION_CONFIG_LABEL));
                requestHeader.put(ECOM_Constant.HTTP_REQUEST_BODY, JSON.serialize(finalPoom));
                HttpResponse boomiResponse = ECOM_RestService.punchoutCheckoutRestCall(requestHeader);//Boomi callout to fetch cxml/oci
                if(boomiResponse != null && boomiResponse.getStatusCode() == 200){
                    ECOM_CartUtil.updatePunchoutLogWithPOOMvalues(POOMResponseList[0], boomiResponse.getBody());//RWPS-6095
                    ECOM_PunchoutPOOMFlowController.insertBoomiPOOMLogs(poomBody, boomiResponse.getBody(), true);
                    responseMap.put(ECOM_Constant.PUNCHOUT_USER, true);
                    responseMap.put(ECOM_Constant.PARAM_SUCCESS, true);
                    responseMap.put(ECOM_Constant.POST_URL, POOMResponseList[0].browserFormPost);
                    // RWPS-6684 - START
                    Integer timeoutLimit = 10000; // Default fallback
                    List<C_META_Storefront_Configuration__mdt> configs = ECOM_CustomMetadataRepo.fetchStoreConfigMdtBasedOnModuleName('Punchout_Buyer_Network_Timeout');
                    if (!configs.isEmpty() && String.isNotBlank(configs[0].Value__c)) 
                    {
                        timeoutLimit = Integer.valueOf(configs[0].Value__c);
                    }
                    responseMap.put(ECOM_Constant.PARAM_TIMEOUT_LIMIT, timeoutLimit);
                    // RWPS-6684 - ENDS
                    responseMap.put(ECOM_Constant.PARAM_RESPONSE_DATA, boomiResponse.getBody());
                    if(POOMResponseList[0].format.equalsIgnoreCase('cxml')){//cxml check and sending to UI for respective form post of oci/cxml
                        responseMap.put('cxml',true);
                    }
                    else{
                        responseMap.put('cxml',false);
                    }
                    //RWPS-289 - garora@rafter.one - 1 April 2024 - Additional check for cart status before updation
                    WebCart cart = ECOM_CartRepo.getPrimaryCartBasedOnId(request.cartId);
                    if(cart.Status!='Closed'){
                        cart.Status = 'Closed';
                        ECOM_CartService.updateCart(new list<webCart>{cart});
                    }
                }
                else{//when status code is not 200 (timeout,bad request,etc)
                    ECOM_PunchoutPOOMFlowController.insertBoomiPOOMLogs(poomBody, boomiResponse.getBody(), false);
                    responseMap.put(ECOM_Constant.PUNCHOUT_USER,true);
                    responseMap.put(ECOM_Constant.PARAM_SUCCESS,false);
                    responseMap.put(ECOM_Constant.HTTP_REQUEST_STATUS_CODE,boomiResponse.getStatusCode());
                }
            }
            else{//if internal data is insufficient
                responseMap.put(ECOM_Constant.PUNCHOUT_USER,true);
                responseMap.put(ECOM_Constant.PARAM_SUCCESS,false);
            }
        }
        else{//if not a punchout user
            responseMap.put(ECOM_Constant.PUNCHOUT_USER,false);
            responseMap.put(ECOM_Constant.PARAM_SUCCESS,true);
        }
    }
    catch(Exception ex){
        ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.CHECKOUT_MODULE_NAME, className, methodName, supportData);
        responseMap.put(ECOM_Constant.PARAM_SUCCESS,false);
    }
    return responseMap;
  }

    @AuraEnabled
    public static Boolean getCartTaxExemptValue(String cartId){
        try {

            List<WebCart> carts = ECOM_CartService.getCartDetails(cartId);
            if(!carts.isEmpty())
            {
                return carts[0].ECOM_isTaxExempt__c;
            }
            else
            {
                return false;
            }

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    //Added getCharityNumberValue method to fetch charity number value on cart. Ticket - RWPS-416
    @AuraEnabled
    public static String getCharityNumberValue(String cartId){
        try {

            List<WebCart> carts = ECOM_CartService.getCartDetails(cartId);
            if(!carts.isEmpty())
            {
                return carts[0].ECOM_CharityNumber__c;
            }
            else
            {
                return '';
            }

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    //Added charity number parameter in saveTaxExemptInfo method. Ticket - RWPS-416
    @AuraEnabled
    public static Map<String,Object> saveTaxExemptInfo(Boolean isTaxExempt, String cartId, String charityNumber){
        Map<String,Object> responseMap = new  Map<String,Object>();
        try {
            List<CartTax> ctax = ECOM_CartService.getCartTaxRecordsPerCart(cartId); //RWPS-460 - 23 April 2024 - Gaurang - Keeping generic method outside to use in both cases
            if(isTaxExempt){
                if(!ctax.isEmpty()){ //RWPS-460 - 23 April 2024 - Gaurang - null check before deletion of cart taxes
                    ECOM_CartRepo.deleteCartTax(ctax);//RWPS-460 - 9 April 2024 - Gaurang - Added a method to delete cart tax record
                }
                }else{
                    if(ctax.isEmpty()){ //RWPS-460 - 23 April 2024 - Gaurang - Re-creating tax recods only if none exist
                        ECOM_SimulateOrderWrapper.OrderResponse res;
                        if(!Test.isRunningTest()){
                            res = ECOM_SessionCacheUtil.getOrderSimulationResponse();
                        }
                        List<CartItem> items = ECOM_CartService.getCartItemsByCartId(cartId);
                        List<CartTax> cartTaxestoInsert = new List<CartTax>();

                        //RWPS-460 - 9 April 2024 - Manoj - Additional check for splitted parts
                        Map<String,String> partNumberToCartItemMap =  new Map<String,String>();
                        for(CartItem item : items){
                            if(!partNumberToCartItemMap.containsKey(item.Product2.Part_Number__c)){
                                partNumberToCartItemMap.put(item.Product2.Part_Number__c, item.Id);
                            }
                        }
                        for(ECOM_SimulateOrderWrapper.ProductList product : res.productList){
                            if(partNumberToCartItemMap.containsKey(product.partNumber)){
                                CartTax tax = new CartTax(
                                Amount = Decimal.valueOf(product.taxVat),
                                CartItemId = partNumberToCartItemMap.get(product.partNumber),
                                Name = 'Tax',
                                TaxCalculationDate = Date.today(),
                                TaxType = 'Estimated'
                            );
                            cartTaxestoInsert.add(tax);
                            }
                        }
                        ECOM_CartService.insertCartTaxes(cartTaxestoInsert);
                    }

                }

                WebCart cart = new WebCart();
                cart.Id = cartId;
                cart.ECOM_isTaxExempt__c = isTaxExempt;
                cart.ECOM_CharityNumber__c = charityNumber;
                ECOM_CartService.updateWebCart(cart);

                responseMap.put('Status','Success');


        } catch (Exception ex) {
            system.debug('ex => '+ex);
            responseMap.put('Status','Error');
            responseMap.put('ErrorMessage',ex.getMessage());
        }
        return responseMap;
    }

    /**
    * @description  Method to save invoice information on cart.
    * @author Sathiya 2024.05.13
    * @param cartDetails
    * @return responseMap
    **/
    @AuraEnabled
    public static Map<String,Object> saveEInvoiceDetails(WebCart cartDetails){
        Map<String,Object> responseMap = new  Map<String,Object>();
        List<WebCart> cartList = new List<WebCart>();

        try {
            //WebCart cart = (WebCart)JSON.deserializeUntyped(JSON.serialize(cartDetails));
            cartList.add(cartDetails);
            ECOM_CartService.updateCart(cartList);
            responseMap.put('Status','Success');
            responseMap.put('cartDetails',cartDetails);
        } catch(Exception e){
            responseMap.put('Status','Error');
            responseMap.put('message', e.getMessage());
        }
        return responseMap;
    }

    /**
     * @description get parent part Number from order Item
    * @author mkumar@rafter.one | 11-08-2023 
    * @param Cart, parentCartItemId 
    * @return String free item parent part Number
     */
    
    public static String getParentPartNumber(Order order, String parentCartItemId) {
        String parentPartNumber = '';
        for(OrderItem item : order.orderItems){
            if(item.id == parentCartItemId) {
                parentPartNumber = item.Product2.Part_Number__c;
                break;
            }    
        }    
        return parentPartNumber;
    }
}