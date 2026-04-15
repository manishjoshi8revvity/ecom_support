/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-493
*
* 2. Description - This class is used to retrieve WebCart records
*					- DMLs on WebCart object
					- return List of WebCart Records
*
*
* 3. Objects referenced
*    -WebCart
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
*
* 5. Dependant Class(es):
*    - ECOM_CartUtil
*
* 6. Test Class Name:
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vipul 2023.07.19
*    - Dar wright 2023.09.15
*    - Manoj 2023.09.21
* 	 - vramachandran@rafter.one | 22 Dec 2023
*    - Sidak 2024.01.16 Added methods getCartItemsByProductandCartId, deleteCartItems. Ticket - ECOM-1384
*    - Sidak 2024.02.01 Added method getAccountId. Ticket - RWPS-33
*    - Sidak 2024.02.08 Added method createCartCheckoutSession. Ticket - RWPS-120
*    - Gaurang 2024.02.20 Added DML methods
*    - Vasudev 2024.02.21 Fix for RWPS-179
*    - Gaurang 2024.02.23 Added condition for ECOM-2687 - to pick cart belonging to user's current account
*    - Gaurang 2024.03.06 RWPS-213 - querying the new fields created for UOM
*    - Sidak 2024.03.27 RWPS-394 - Replaced ECOM_POSR_Browser_Form_Post__c with ECOM_POSR_Browser_Form_Post_Url__c
*    - Sidak 2024.04.05 RWPS-419 - Added method deleteCart which takes List of WebCart as parameter
*    - Gaurang 2024.04.09 RWPS - 460 - Added method to delete Cart Tax record
*    - Sidak 2024.04.19 RWPS-416 - Added ECOM_CharityNumber__c field in query in getCartDetails method
*    - Vipul Goyal 2024.04.23 Updated Abandoned Cart Methods.
*    - Vipul Goyal 2024.04.24 Updated getCartandCartItemsById.
*    - Vipul Goyal 2024.05.02 Updated getCartandCartItemsById.(ECOM - 103)
*	 - Sathiya 2024.05.10 Updated ECOM_E_Invoice_Code1__c, ECOM_E_Invoice_Code2__c, ECOM_E_Invoice_Code3__c
        , ECOM_E_Invoice_Code4__c, ECOM_E_Invoice_Cost_Center__c
		, ECOM_E_Invoice_Tax_Exempt__c fields for all related methods
*	 - Sathiya 2024.05.24 Update Product2.ECOM_Product_Media_URI__c to the cart repo related methods
* 	 - Manoj 2024.05.03 RWPS-553 Sending Contact ID to SAP(updated getCartandCartItemsById method with SAP_Contact_ID__c field )
*    - Manoj 2024.05.03 RWPS-553 Sending Contact ID to SAP(updated getCartandCartItemsById method with SAP_Contact_ID__c field )
*    - Manoj 2024-05-06 RWPS-622 Hide Availability date when the Order contains an Instrument(Updated getCartItemsShippingDates  method)
*    - Sidak 2024.05.10 RWPS-632 Updated method getCartItemsByCartId - Added Type field
*    - Sidak 2024.04.19 RWPS-766 - Added Default_Bill_to_ERP_Address__c, Default_Ship_to_ERP_Address__c fields in query in getCartDetails method
*    - Sidak 2024.06.04 RWPS-708 - Added Contact__c in query in getPrimaryCartBasedOnId method
*    - Gaurang 2024.06.13 ECOM-3271 - Added AccountId condition in query to pick current account's cart
*    - Manoj 2024.06.14 RWPS-586 - New processor needed for our OCI response to send to Galapagos via EDI
* 	 - Vasudev 2024.06.28 ECOM-3411 - Account field added in query for fetch cart
*    - Sidak 2024.06.27 RWPS-310 - Added method getCartsBasedOnOwnerAndAccount
*    - Manoj 2024.08.21 read billing country code from payer instead account(updated getCartandCartItemsById with fxAddress_CountryCode__c) RWPS-1305
*    - Manoj 2024.09.09 RWPS-1387 read image from Product2.ECOM_Product_Media_URI__c(DAM) instead product media
*    - Sidak 2024.09.20 RWPS-1535 - Added method getCartandProductTypeCartItemsSortedWithLimit
*    - Anjali Parmar 2024.11.19 RWPS-1869 - Updated getShippingTime - Added County condition on ECOM_ProductShippingTime__c query
*    - Gaurav Bhansali 2024.12.31 RWPS-2052 - Created isValidPromo - Added query to check promo code exist in active single use coupon list
*    - Gaurav Bhansali 2024.01.14 RWPS-2307 - Updated isValidPromo to return value based on promo name
*    - Prabhat Kumar 2024.02.25 - Updated Method with getCartandCartItemsById to include field product2id in query - RWPS-2683
*    - Gaurav Bhansali 2025.03.13 - Created isValidCouponCode - Added query to check coupon exist in SF RWPS-2800
*    - Prabhat Kumar 2025.03.17 - Created method getPricebookEntryListPrices to List Price of Products -  RWPS-2683
*    - Prabhat Kumar 2025.04.10 - Updated getPunchoutCartandCartItemsById to include the field ECOM_Shipping_Cost__c in the query - RWPS-2941
*    - Gaurav Bhansali 2025.04.21 - Updated getCartItemsByCartId - Added Product2.Item_Class__c in query to return product class type RWPS-1285
*    - Prabhat Kumar 2025.04.25 - Updated getCartandCartItemsById, getCartItemsShippingDates to include the field Tariff Surcharge fields in the query - RWPS-3026
*    - Prabhat Kumar 2025.05.23 - Updated method getCartCount, getCartsBasedOnEmailNotificationForLeftOverCountries, getCartsBasedOnEmailNotificationForSpecificCountry - RWPS-3342
*    - Gaurav Bhansali 2025.05.27 - Added getCouponList method to return active coupon code list RWPS-3283
*    - Gaurav Bhansali 2025.05.28 - Added isFirstTimePromoActive method to check if there is first time active coupon code RWPS-3225
*    - Prabhat Kumar 2025.05.23 - Updated method getCartsBasedOnEmailNotificationForLeftOverCountries and getCartsBasedOnEmailNotificationForSpecificCountry - RWPS-3197
*    - Prabhat Kumar 2025.06.10 - Updated method getCartandCartItemsById to include fields - RWPS-3262
*    - Gaurav Bhansali 2025.06.16 - Added isValidCouponCode - Added country condition to check active coupon exist in SF RWPS-3186
*    - Gaurav Bhansali 2025.06.30 - Updated getCartsBasedOnEmailNotificationForLeftOverCountries, getCartsBasedOnEmailNotificationForSpecificCountry RWPS-2786
*    - Prabhat Kumar 2025.06.30 - Updated getCartsBasedOnEmailNotificationForLeftOverCountries and getCartsBasedOnEmailNotificationForSpecificCountry to get non punchout users - RWPS-2786
*    - Prabhat Kumar 2025.07.11 - Created Method getShippingTimesByCountryAndCity, getShippingTimesByCountry and getCartItemById to get the shipping details - RWPS-1603
*    - Prabhat Kumar 2025.07.25 - Created Method getCouponByCouponCode get coupon details based on the coupon code - RWPS-3812
*    - Gaurav Bhansali 2025.08.22 - Updated getCartandCartItemsById and created getFreeItemsByCartId to return free cart items RWPS-3811
*    - Prabhat Kumar 2025.08.22 - Added method getParentCartItemsWithPartNumbers to return parent Cart items - RWPS-3811
*    - Manish Joshi 2025.09.12 - Updated method getCartCount with AND condition - RWPS-3811
*    - Prabhat Kumar 2025.09.11 - Updated method getCouponByCouponCode to include fields Usage_Type__c and BOGO_Applicable_Products__c - RWPS-3811
*    - Prabhat Kumar 2025.10.03 - Updated method getCartItemsByCartId - RWPS-3740
*    - Prabhat Kumar 2025.12.03 - Updated method getCartItemById - RWPS-4896
*    - Prabhat Kumar 2026.01.07 -  Updated method getPunchoutCartandCartItemsById to include tariff charges - RWPS-5603
*    - Sachin V 2026.01.29 - Updated method : getCartandCartItemsById - RWPS-5938
*    - Poonam S 2026.03.16 - Added method updateEInvoiceCustIdOnERPAddress - RWPS-6394

*************************************************************/
public without sharing class ECOM_CartRepo {

    //private static instance of the class
    private static Id accountId = null;

    /**
    * @description This method returns the account Id for the provided owner.
    * @author Sidak 2024.01.31
    * @return Id
    **/
    public static Id getAccountId(String userId){
        List<User> userList = new List<User>();
        if(accountId == null){
            userList = [SELECT Id, AccountId FROM User WHERE Id = :userId LIMIT 1];
        }
        if(userList.size() > 0){
            accountId = userList[0].AccountId;
        }
        return accountId;
    }

    /**
    * @description This method is used to get cart details
    * @author Vipul Goyal | 02-22-2024
    *         Sidak Singh | 04-19-2024 | Added ECOM_CharityNumber__c field in query | RWPS-416
    *         Sidak Singh | 05-31-2024 | Added Default_Bill_to_ERP_Address__c, Default_Ship_to_ERP_Address__c fields in query | RWPS-766
    * @param cartId
    * @return List<Cart>
    **/
    public static List<WebCart> getCartDetails(String cartId)
    {
        List<WebCart> carts = [SELECT Id, ECOM_isTaxExempt__c, ECOM_CharityNumber__c, Default_Bill_to_ERP_Address__c, Default_Ship_to_ERP_Address__c FROM WebCart WHERE Id =:cartId];
        return carts;
    }

    /**
    * @description This method returns the active cart for the provided owner.
    * @author Vipul 2023.07.19
    * @param strOwnerId
    * @return List<WebCart>
    **/
    public static List<WebCart> getPrimaryCartBasedOnOwner(String strOwnerId)
    {
        Id accId = getAccountId(strOwnerId);
        List<WebCart> carts = [SELECT Id,Name,AccountId,Account.Name, GrandTotalAmount,UniqueProductCount,ECOM_BillToAccount__c,ECOM_ShipToAccount__c,
                                   ECOM_BillToAccount__r.BillingStreet,ECOM_BillToAccount__r.BillingCity,
                                   ECOM_BillToAccount__r.BillingState,ECOM_BillToAccount__r.BillingPostalCode,
                                   ECOM_BillToAccount__r.BillingCountry,ECOM_ShipToAccount__r.ShippingStreet, ECOM_ShipToAccount__r.ShippingCity,
                                   ECOM_ShipToAccount__r.ShippingState, ECOM_ShipToAccount__r.ShippingPostalCode,Type,WebStoreId,
                                   ECOM_ShipToAccount__r.ShippingCountry,PoNumber,CurrencyIsoCode,IsSecondary,OwnerId,Status,TaxType,TotalChargeAmount,
                                   Default_Ship_to_ERP_Address__r.ERP_Sales_Org__c,Default_Bill_to_ERP_Address__r.ERP_Sales_Org__c,
                                   TotalListAmount,TotalProductAmount,TotalAdjustmentAmount,TotalProductCount,TotalPromoAdjustmentAmount,TotalTaxAmount,
                                   ECOM_DefaultBillToCPA__c,ECOM_DefaultShipToCPA__c,ECOM_Total_Savings__c, Default_Bill_to_ERP_Address__c, Default_Ship_to_ERP_Address__c,
                                   ECOM_Is_Punchout_Cart__c,
                                   ECOM_E_Invoice_Code1__c, ECOM_E_Invoice_Code2__c, ECOM_E_Invoice_Code3__c, ECOM_E_Invoice_Code4__c, ECOM_E_Invoice_Cost_Center__c, ECOM_E_Invoice_Tax_Exempt__c,
                                   Default_Invoice_ERP_Address__r.Target_Address__c, Default_Invoice_ERP_Address__r.Target_Address__r.External_Id__c,
                				   Default_Invoice_ERP_Address__r.ERP_Sales_Org__c, Default_Invoice_ERP_Address__r.ApiCountry__c,Default_Invoice_ERP_Address__r.fxAddress_CountryName__c,
                               	   Default_Bill_to_ERP_Address__r.fxAddress_CountryName__c, Default_Bill_to_ERP_Address__r.apiCountry__c, Default_Bill_to_ERP_Address__r.Address_Country__c, Default_Bill_to_ERP_Address__r.ECOM_PU_Cust_E_Invoice__c,
                               	   Default_Bill_to_ERP_Address__r.Target_Address__c, Default_Bill_to_ERP_Address__r.Target_Address__r.ECOM_PU_Cust_E_Invoice__c,
                                   //VRa- Punchout Changes -- begin
                                   ECOM_Cart_Id__c, ECOM_POOM_Lead_Time__c, ECOM_POOM_Shipping_Money__c, ECOM_POOM_Total_Money__c,
                                   ECOM_POSR_Browser_Form_Post_Url__c, ECOM_POSR_Buyer_Cookie__c, ECOM_POSR_First_Name__c, ECOM_POSR_Header_From_Credential_Domain__c, ECOM_POSR_Header_From_Credential_Ident__c,
                                   ECOM_POSR_Header_Lang__c, ECOM_POSR_Header_Payload_Id__c, ECOM_POSR_Header_Sender_Identity__c, ECOM_POSR_Header_SenderCredential_Domain__c,
                                   ECOM_POSR_Header_TimeStamp__c, ECOM_POSR_Header_To_Identity__c, ECOM_POSR_Header_Version__c, ECOM_POSR_Last_Name__c, ECOM_POSR_Punchout_Format__c, ECOM_POSR_Selected_Item__c,
                                   ECOM_POSR_Supplier_Part_Id__c, ECOM_POSR_Unique_Name__c, ECOM_POSR_UserEmail__c,
                                   ECOM_POSR_Header_To_Credential_Domain__c
                                   //VRa - Punchout changes -- End

                                  FROM WebCart
                                  WHERE OwnerId=:strOwnerId AND AccountId=:accId AND (Status = 'Active' OR Status = 'Checkout')  AND IsSecondary = FALSE LIMIT 1];
        return carts;
    }

/**
    * @description This method returns the active cart for the provided owner and account. Ticket - RWPS-310
    * @author Sidak 2024.06.27
    * @param strOwnerId
    * @param accId
    * @return List<WebCart>
    **/
    public static List<WebCart> getCartsBasedOnOwnerAndAccount(String strOwnerId, String accId)
    {
        List<WebCart> carts = [SELECT Id,Name,AccountId,Account.Name, GrandTotalAmount,UniqueProductCount,ECOM_BillToAccount__c,ECOM_ShipToAccount__c,
                                   ECOM_BillToAccount__r.BillingStreet,ECOM_BillToAccount__r.BillingCity,
                                   ECOM_BillToAccount__r.BillingState,ECOM_BillToAccount__r.BillingPostalCode,
                                   ECOM_BillToAccount__r.BillingCountry,ECOM_ShipToAccount__r.ShippingStreet, ECOM_ShipToAccount__r.ShippingCity,
                                   ECOM_ShipToAccount__r.ShippingState, ECOM_ShipToAccount__r.ShippingPostalCode,Type,WebStoreId,
                                   ECOM_ShipToAccount__r.ShippingCountry,PoNumber,CurrencyIsoCode,IsSecondary,OwnerId,Status,TaxType,TotalChargeAmount,
                                   Default_Ship_to_ERP_Address__r.ERP_Sales_Org__c,Default_Bill_to_ERP_Address__r.ERP_Sales_Org__c,
                                   TotalListAmount,TotalProductAmount,TotalAdjustmentAmount,TotalProductCount,TotalPromoAdjustmentAmount,TotalTaxAmount,
                                   ECOM_DefaultBillToCPA__c,ECOM_DefaultShipToCPA__c,ECOM_Total_Savings__c, Default_Bill_to_ERP_Address__c, Default_Ship_to_ERP_Address__c,
                                   ECOM_Is_Punchout_Cart__c,

                                   //VRa- Punchout Changes -- begin
                                   ECOM_Cart_Id__c, ECOM_POOM_Lead_Time__c, ECOM_POOM_Shipping_Money__c, ECOM_POOM_Total_Money__c,
                                   ECOM_POSR_Browser_Form_Post_Url__c, ECOM_POSR_Buyer_Cookie__c, ECOM_POSR_First_Name__c, ECOM_POSR_Header_From_Credential_Domain__c, ECOM_POSR_Header_From_Credential_Ident__c,
                                   ECOM_POSR_Header_Lang__c, ECOM_POSR_Header_Payload_Id__c, ECOM_POSR_Header_Sender_Identity__c, ECOM_POSR_Header_SenderCredential_Domain__c,
                                   ECOM_POSR_Header_TimeStamp__c, ECOM_POSR_Header_To_Identity__c, ECOM_POSR_Header_Version__c, ECOM_POSR_Last_Name__c, ECOM_POSR_Punchout_Format__c, ECOM_POSR_Selected_Item__c,
                                   ECOM_POSR_Supplier_Part_Id__c, ECOM_POSR_Unique_Name__c, ECOM_POSR_UserEmail__c,
                                   ECOM_POSR_Header_To_Credential_Domain__c
                                   //VRa - Punchout changes -- End

                                  FROM WebCart
                                  WHERE OwnerId=:strOwnerId AND AccountId=:accId AND (Status = 'Active' OR Status = 'Checkout')];
        return carts;
    }



    /**
     * @description This method returns all the carts that are currently active for a user
     * @author vramachandran@rafter.one | 14 Dec 2023
     * @param userId | String
     * @returns List<WebCart>
     */
    public static List<WebCart> getAllActiveCartsForOwnerId(String userId){
        return [SELECT Id, Status, ECOM_Is_Punchout_Cart__c
                , AccountId //VRa - Changes for ECOM-3411 28 Jun 2024
                FROM WebCart
                WHERE OwnerId=:userId
                AND (Status = 'Active' OR Status = 'Checkout') LIMIT 49999];
    }

    public static List<WebCart> getCartsBasedOnOwner(String strOwnerId)
    {
        List<WebCart> carts = [SELECT Id,Name,AccountId,Account.Name, GrandTotalAmount,UniqueProductCount,Default_Bill_To_ERP_Address__c,
                                  Default_Ship_To_ERP_Address__c,Type,WebStoreId,
                                  PoNumber,CurrencyIsoCode,IsSecondary,OwnerId,Status,TaxType,TotalChargeAmount,
                               	  TotalListAmount,TotalProductAmount,TotalAdjustmentAmount,TotalProductCount,TotalPromoAdjustmentAmount,TotalTaxAmount,
                                  ECOM_DefaultBillToCPA__c,ECOM_DefaultShipToCPA__c,ECOM_Total_Savings__c,
								  Default_Ship_to_ERP_Address__r.ERP_Sales_Org__c,Default_Bill_to_ERP_Address__r.ERP_Sales_Org__c,
                                  ECOM_Is_Punchout_Cart__c //VRa-punchoutChanges
                                  , ECOM_E_Invoice_Code1__c, ECOM_E_Invoice_Code2__c, ECOM_E_Invoice_Code3__c, ECOM_E_Invoice_Code4__c, ECOM_E_Invoice_Cost_Center__c, ECOM_E_Invoice_Tax_Exempt__c, Default_Invoice_ERP_Address__c,
                               	  Default_Bill_to_ERP_Address__r.fxAddress_CountryName__c, Default_Bill_to_ERP_Address__r.apiCountry__c, Default_Bill_to_ERP_Address__r.Address_Country__c, Default_Bill_to_ERP_Address__r.ECOM_PU_Cust_E_Invoice__c,
                               	  Default_Bill_to_ERP_Address__r.Target_Address__c, Default_Bill_to_ERP_Address__r.Target_Address__r.ECOM_PU_Cust_E_Invoice__c
                                  FROM WebCart
                                  WHERE OwnerId=:strOwnerId AND (Status = 'Active' OR Status = 'Checkout')];
        return carts;
    }

    /**
    * @description This method returns the active cart for the provided id.
    * @author Manish 2023.10.18
    * @author Sidak 2023.06.04 | Added Contact__c in query | RWPS-708
    * @param cartId
    * @return WebCart
    **/
    public static WebCart getPrimaryCartBasedOnId(String cartId)
    {
            WebCart cart = [SELECT Id,Name,AccountId,Account.Name, GrandTotalAmount,UniqueProductCount,Default_Bill_to_ERP_Address__c,Default_Ship_to_ERP_Address__c, Default_Invoice_ERP_Address__c,
                                  Type,WebStoreId,PoNumber,CurrencyIsoCode,IsSecondary,OwnerId,Status,TaxType,TotalChargeAmount,
                               	  TotalListAmount,TotalProductAmount,TotalAdjustmentAmount,TotalProductCount,TotalPromoAdjustmentAmount,TotalTaxAmount,ECOM_Total_Savings__c,
                                  Default_Ship_to_ERP_Address__r.ERP_Sales_Org__c,Default_Bill_to_ERP_Address__r.ERP_Sales_Org__c,
                                  Contact__c,ECOM_Is_Punchout_Cart__c //VRa-punchoutChanges
                        		  ,ECOM_E_Invoice_Code1__c, ECOM_E_Invoice_Code2__c, ECOM_E_Invoice_Code3__c, ECOM_E_Invoice_Code4__c, ECOM_E_Invoice_Cost_Center__c, ECOM_E_Invoice_Tax_Exempt__c,
                        		  Default_Bill_to_ERP_Address__r.fxAddress_CountryName__c, Default_Bill_to_ERP_Address__r.apiCountry__c, Default_Bill_to_ERP_Address__r.Address_Country__c, Default_Bill_to_ERP_Address__r.ECOM_E_Invoice_Cust_Id__c
                                  FROM WebCart
                                  WHERE Id =: cartId LIMIT 1];
        return cart;
    }

    /**
    * @description  This method returns cart and cart items based on cartId
    * @author mkumar@rafter.one | 07-28-2023
    * @param cartId
    * @return List<WebCart>
    **/
    public static List<WebCart> getCartandCartItemsById(String cartId)
    {
        return [SELECT Id, Name,AccountId,Account.Name, GrandTotalAmount,UniqueProductCount,ECOM_BillToAccount__c, ECOM_ShipToAccount__c, BillingCountryCode,ECOM_isTaxExempt__c,
                PaymentMethodId,PoNumber, Type,ECOM_ShipToAccount__r.ShippingCountry,CurrencyIsoCode,IsSecondary,OwnerId,Status,TaxType,TotalChargeAmount,
                TotalListAmount,TotalProductAmount,TotalAdjustmentAmount,TotalProductCount,TotalPromoAdjustmentAmount,TotalTaxAmount,WebStoreId,ECOM_Quote_Number__c,
                ECOM_Promo_Code__c,ECOM_Total_Savings__c,Default_Bill_to_ERP_Address__c, Default_Bill_to_ERP_Address__r.Target_Address__c, Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c,
                Default_Ship_to_ERP_Address__c,  Default_Ship_to_ERP_Address__r.Target_Address__c, Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c,
                Default_Ship_to_ERP_Address__r.ERP_Sales_Org__c,Default_Bill_to_ERP_Address__r.ERP_Sales_Org__c,SAP_Contact_ID__c,Default_Bill_to_ERP_Address__r.fxAddress_CountryCode__c,
                Owner.Name,Default_Ship_to_ERP_Address__r.ApiCountry__c,Default_Ship_to_ERP_Address__r.fxAddress_CountryName__c,
                Default_Ship_to_ERP_Address__r.ECOM_Designated_Approver__c,Default_Ship_to_ERP_Address__r.ECOM_RAD_Approval_Status__c,Default_Ship_to_ERP_Address__r.ECOM_Approver_Enabled__c,
                ECOM_Is_Punchout_Cart__c, //VRa-punchoutChanges
                Contact__r.Default_Ship_to_ERP_Address__r.Master_Address__c,//RWPS-3816
                ECOM_E_Invoice_Code1__c, ECOM_E_Invoice_Code2__c, ECOM_E_Invoice_Code3__c, ECOM_E_Invoice_Code4__c, ECOM_E_Invoice_Cost_Center__c, ECOM_E_Invoice_Tax_Exempt__c, Default_Invoice_ERP_Address__c,
                Default_Invoice_ERP_Address__r.Target_Address__c, Default_Invoice_ERP_Address__r.Target_Address__r.External_Id__c,
                Default_Invoice_ERP_Address__r.ERP_Sales_Org__c, Default_Invoice_ERP_Address__r.ApiCountry__c,Default_Invoice_ERP_Address__r.fxAddress_CountryName__c,
                Default_Bill_to_ERP_Address__r.apiCountry__c, Default_Bill_to_ERP_Address__r.Address_Country__c, Default_Bill_to_ERP_Address__r.ECOM_PU_Cust_E_Invoice__c,
                Default_Bill_to_ERP_Address__r.Target_Address__r.ECOM_PU_Cust_E_Invoice__c, Default_Bill_to_ERP_Address__r.fxAddress_CountryName__c,Total_Tariff_Surcharge__c,//RWPS-3026 - Total_Tariff_Surcharge__c and Name
                Contact__c, Contact__r.ECOM_Punchout_Via_Web__c, //RWPS-5938
                (SELECT Id, Name, Sku, Quantity,ListPrice,SalesPrice,NetAdjustmentAmount,TotalAmount,TotalLineAmount,TotalPrice,TotalAdjustmentAmount,TotalPriceAfterAllAdjustments,ECOM_Earliest_Shipping_Date__c, ECOM_Selected_Shipping_Date__c,
                 UnitAdjustedPrice,UnitAdjustmentAmount,TotalListPrice, TotalTaxAmount, CartId, CartDeliveryGroupId, Product2.Id, ECOM_Parent__c, ecom_parent_item__c, //RWPS-3811
                 Product2.Part_Number__c,Product2.Name,Product2.Dangerous_Goods_Indicator_Profile__c,Type , Product2.Business_Unit__c, Product2.Discount_Type__c,
                 Product2.Item_Class__c, Product2.Part_Type__c, Product2.ECOM_Product_Media_URI__c,//RWPS-1387
                 Product2Id,//RWPS-2683
                 Product2.Product_Line__c, Product2.Product_Type__c,Product2.IGOR_PAC__c,Product2.DisplayUrl,Product2.IGOR_Item_Class_Desc__c,
                 Product2.Product_Line_Name__c,Product2.IGOR_Description__c,Product2.Sub_Business_Unit__c,Product2.Super_Business_Unit__c,CurrencyISOCode,
                 Product2.Product_Display_Name__c, Cart.TotalProductListAmount, Cart.TotalProductAmount, Cart.ECOM_Promo_Code__c, Cart.ECOM_Total_Savings__c //RWPS-2270 AND RWPS-3262
                 FROM CartItems ORDER BY Sku ASC, ECOM_Earliest_Shipping_Date__c ASC)
                FROM WebCart WHERE Id =: cartId LIMIT 1];
    }
    /**
    * @description  This method returns cart and cart items based on cartId
    * @author mkumar@rafter.one | 07-28-2023
    * @param cartId
    * @return List<WebCart>
    **/
    public static List<WebCart> getCartandProductTypeCartItemsById(String cartId)
    {
        return [SELECT Id, Name,AccountId,Account.Name, GrandTotalAmount,UniqueProductCount,ECOM_BillToAccount__c, ECOM_ShipToAccount__c, BillingCountryCode,
                PaymentMethodId,PoNumber, Type,ECOM_ShipToAccount__r.ShippingCountry,CurrencyIsoCode,IsSecondary,OwnerId,Status,TaxType,TotalChargeAmount,
                TotalListAmount,TotalProductAmount,TotalAdjustmentAmount,TotalProductCount,TotalPromoAdjustmentAmount,TotalTaxAmount,WebStoreId,ECOM_Quote_Number__c,ECOM_Promo_Code__c,ECOM_Total_Savings__c,
                Default_Ship_to_ERP_Address__r.ERP_Sales_Org__c,Default_Bill_to_ERP_Address__r.ERP_Sales_Org__c,
                ECOM_Is_Punchout_Cart__c, //VRa-punchoutChanges
                ECOM_E_Invoice_Code1__c, ECOM_E_Invoice_Code2__c, ECOM_E_Invoice_Code3__c, ECOM_E_Invoice_Code4__c, ECOM_E_Invoice_Cost_Center__c, ECOM_E_Invoice_Tax_Exempt__c, Default_Invoice_ERP_Address__c,
                Default_Bill_to_ERP_Address__r.fxAddress_CountryName__c, Default_Bill_to_ERP_Address__r.apiCountry__c, Default_Bill_to_ERP_Address__r.Address_Country__c, Default_Bill_to_ERP_Address__r.ECOM_PU_Cust_E_Invoice__c,
                Default_Bill_to_ERP_Address__r.Target_Address__c, Default_Bill_to_ERP_Address__r.Target_Address__r.ECOM_PU_Cust_E_Invoice__c,
                Default_Invoice_ERP_Address__r.Target_Address__c, Default_Invoice_ERP_Address__r.Target_Address__r.External_Id__c,
                Default_Invoice_ERP_Address__r.ERP_Sales_Org__c, Default_Invoice_ERP_Address__r.ApiCountry__c,Default_Invoice_ERP_Address__r.fxAddress_CountryName__c,
                (SELECT Id, Sku, Quantity,ListPrice,SalesPrice,NetAdjustmentAmount,TotalAmount,TotalLineAmount,TotalPrice,TotalAdjustmentAmount,TotalPriceAfterAllAdjustments,ECOM_Earliest_Shipping_Date__c, ECOM_Selected_Shipping_Date__c,
                 UnitAdjustedPrice,UnitAdjustmentAmount,TotalListPrice, TotalTaxAmount, CartId, CartDeliveryGroupId, Product2.Id, ECOM_Parent__c,
                 Product2.Part_Number__c,Product2.Name,Product2.Dangerous_Goods_Indicator_Profile__c,Type,Product2.Business_Unit__c, Product2.Discount_Type__c,
                 Product2.Item_Class__c, Product2.Part_Type__c, Product2.ECOM_Product_Media_URI__c,//RWPS-1387
                 Product2.Product_Line__c, Product2.Product_Type__c,Product2.IGOR_PAC__c, Product2.IGOR_Item_Class_Desc__c,CurrencyISOCode FROM CartItems WHERE Type = 'Product' ORDER BY Sku ASC, ECOM_Earliest_Shipping_Date__c ASC)
                FROM WebCart WHERE Id =: cartId LIMIT 1];
    }
    /**
    * @description  This method returns cart and cart items based on cartId
    * @author ssingh@rafter.one | 09-20-2024 | RWPS-1535
    * @param cartId
    * @return List<WebCart>
    **/
    public static List<WebCart> getCartandProductTypeCartItemsSortedWithLimit(String cartId)
    {
        return [SELECT Id, Name,AccountId,Account.Name, GrandTotalAmount,UniqueProductCount,ECOM_BillToAccount__c, ECOM_ShipToAccount__c, BillingCountryCode,
                PaymentMethodId,PoNumber, Type,ECOM_ShipToAccount__r.ShippingCountry,CurrencyIsoCode,IsSecondary,OwnerId,Status,TaxType,TotalChargeAmount,
                TotalListAmount,TotalProductAmount,TotalAdjustmentAmount,TotalProductCount,TotalPromoAdjustmentAmount,TotalTaxAmount,WebStoreId,ECOM_Quote_Number__c,ECOM_Promo_Code__c,ECOM_Total_Savings__c,
                Default_Ship_to_ERP_Address__r.ERP_Sales_Org__c,Default_Bill_to_ERP_Address__r.ERP_Sales_Org__c,
                ECOM_Is_Punchout_Cart__c, //VRa-punchoutChanges
                (SELECT Id, Sku, Quantity,ListPrice,SalesPrice,NetAdjustmentAmount,TotalAmount,TotalLineAmount,TotalPrice,TotalAdjustmentAmount,TotalPriceAfterAllAdjustments,ECOM_Earliest_Shipping_Date__c, ECOM_Selected_Shipping_Date__c,
                 UnitAdjustedPrice,UnitAdjustmentAmount,TotalListPrice, TotalTaxAmount, CartId, CartDeliveryGroupId, Product2.Id, ECOM_Parent__c,
                 Product2.Part_Number__c,Product2.Name,Product2.Dangerous_Goods_Indicator_Profile__c,Type,Product2.Business_Unit__c, Product2.Discount_Type__c,
                 Product2.Item_Class__c, Product2.Part_Type__c, Product2.ECOM_Product_Media_URI__c,//RWPS-1387
                 Product2.Product_Line__c, Product2.Product_Type__c,Product2.IGOR_PAC__c, Product2.IGOR_Item_Class_Desc__c,CurrencyISOCode,CreatedDate FROM CartItems WHERE Type = 'Product' ORDER BY LastModifiedDate DESC LIMIT 3)
                FROM WebCart WHERE Id =: cartId LIMIT 1];
    }
    /**
    * @description  This method returns cart and cart items based on cartId
    * @author ssingh@rafter.one | 01-16-2024
    * @param cartId
    * @param productId
    * @return List<WebCart>
    **/
    public static List<CartItem> getCartItemsByProductandCartId(String cartId, String productId)
    {
        return [SELECT Id,ECOM_Parent__c,Product2Id,Name,Quantity,ECOM_Earliest_Shipping_Date__c,Type,CartId
        FROM CartItem WHERE Product2Id =: productId AND Type ='Product' AND CartId =: cartId ORDER BY ECOM_Earliest_Shipping_Date__c ASC LIMIT 4999];
    }

     /**
    * @description This method returns the list price of the Product.
    * @param String salesOrg
    * @param String currencyCode
    * @param Set<Id> productIds
    * @return Map<id, DecimalL>
    * Jira - RWPS-2683
    **/
    public static Map<id, Decimal> getPricebookEntryListPrices(String salesOrg, String currencyCode, Set<Id> productIds){
        Map<id, Decimal> mapProductPrice = New Map<Id, Decimal>();
        List<PricebookEntry> priceBookEntries =[SELECT Id, IsActive, CreatedDate, UnitPrice,CurrencyIsoCode,Product2.Name,Pricebook2.Name, Product2Id
                                                FROM PricebookEntry where Product2Id IN :productIds AND IsActive=true AND Pricebook2.Name =: salesOrg
                                                AND CurrencyISOCode =: currencyCode order by CreatedDate DESC];

        for(PricebookEntry pbe : priceBookEntries){
            mapProductPrice.put(pbe.Product2Id, pbe.UnitPrice);
        }
        return mapProductPrice;
    }


    // Add cart items to the Cart
    public static List<ConnectApi.BatchResult> addItemsToCart(String webstoreId, String effectiveAccountId, String activeCartOrId, List<ConnectApi.BatchInput> cartItems) {
        return ECOM_SalesforceAPI.addItemsToCart(webstoreId, effectiveAccountId, activeCartOrId, cartItems);
    }
    //RWPS-1387
    // Fetch Cart Items
    public static ConnectApi.CartItemCollection getCartItems(String webstoreId, String effectiveAccountId, String activeCartOrId,String productFields ,String pageParam, Integer pageSize,ConnectApi.CartItemSortOrder sortOrder) {
        return ECOM_SalesforceAPI.getCartItems(webstoreId, effectiveAccountId, activeCartOrId,productFields, pageParam, pageSize,sortOrder);
    }
    // Fetch Cart Items
    public static ConnectApi.CartItemCollection getCartItems(String webstoreId, String effectiveAccountId, String activeCartOrId, String pageParam, Integer pageSize) {
        return ECOM_SalesforceAPI.getCartItems(webstoreId, effectiveAccountId, activeCartOrId, pageParam, pageSize);
    }
    // Update Cart Item
    public static ConnectApi.CartItem updateCartItem(String webstoreId, String effectiveAccountId, String activeCartOrId, String cartItemId, ConnectApi.CartItemInput cartItem) {
        return ECOM_SalesforceAPI.updateCartItem(webstoreId, effectiveAccountId, activeCartOrId, cartItemId, cartItem);
    }
    //Create Cart
    public static ConnectApi.CartSummary createCart(String webstoreId, ConnectApi.CartInput cart){
         return Test.isRunningTest()?ECOM_TestUtil.createDataConnectApi_CartSummary():ECOM_SalesforceAPI.createCart(webstoreId, cart);
    }
    // Fetch or Create Cart
    public static ConnectApi.CartSummary getOrCreateActiveCartSummary(String webstoreId, String effectiveAccountId, String activeCartOrId) {
        return ECOM_SalesforceAPI.getOrCreateActiveCartSummary(webstoreId, effectiveAccountId, activeCartOrId);
    }
    //Delete Cart
    public static Void deleteCart(String webstoreId, String effectiveAccountId, String activeCartOrId){
         ECOM_SalesforceAPI.deleteCart(webstoreId, effectiveAccountId, activeCartOrId);
    }

    // Fetch Payer SAP Target Account Number
    public static List<Account_Function__c> getPayerTargetAccountNumber(String accId)
    {
        return [SELECT Id, Name, Source_Account__c, SAP_Partner_Type_Name__c, SAP_Partner_Type__c, SAP_Source_Account_Number__c, SAP_Target_Account_Number__c
                FROM Account_Function__c WHERE Source_Account__c =: accId AND SAP_Partner_Type__c = 'RG' LIMIT 1];
    }

    // Fetch Ship To SAP Source Account Number
    public static List<Account_Function__c> getShipToSourceAccountNumber(String accId)
    {
        return [SELECT Id, Name, Source_Account__c, SAP_Partner_Type_Name__c, SAP_Partner_Type__c, SAP_Source_Account_Number__c, SAP_Target_Account_Number__c
                FROM Account_Function__c WHERE Source_Account__c =: accId AND SAP_Partner_Type__c = 'WE' LIMIT 1];
    }

    // Fetch Effective Account Id
    public static String getEffectiveAccountId()
    {
        Id contactAccountId = [SELECT Id, AccountId FROM User WHERE Id =: Userinfo.getUserid() LIMIT 1].AccountId;
        return contactAccountId;
    }

    // Check if the user has a RAD Identifier Account
    public static Boolean checkRADIdentifierAccount(String cartId)
    {
        List<WebCart> carts = [SELECT Id,Default_Ship_to_ERP_Address__r.RAD_Identifier__c FROM WebCart WHERE Id =: cartId LIMIT 1];
        if(carts != null && carts.size() > 0 && carts[0].Default_Ship_to_ERP_Address__c != null && carts[0].Default_Ship_to_ERP_Address__r.RAD_Identifier__c == 'RAD'){
            return true;
        }
        else {
            return false;
        }
    }

    // Fetch Shipping Dates of Cart Items
    public static List<CartItem> getCartItemsShippingDates(Id cartId)
    {
        //RWPS-622 added Product2.Item_Class__c
        //RWPS-3026 added Tariff_Surcharge__c
        return [SELECT Id, CartId, Tariff_Surcharge__c, ECOM_Selected_Shipping_Date__c, ECOM_Earliest_Shipping_Date__c, Product2Id,Product2.Item_Class__c FROM CartItem WHERE CartId =: cartId];
    }

    //Fetch Cart delivery Group
    public static List<CartDeliveryGroup> getCartDeliveryGroupByCart(Id cartID){
        List<CartDeliveryGroup> cartDeliveryGroup = [SELECT Id, DeliveryMethodId FROM CartDeliveryGroup WHERE CartId = : cartID LIMIT 1];
        return cartDeliveryGroup;
    }

    //Fetch CartItem by cart id
    //RWPS-632 Added Type field
    //RWPS-1285
    public static List<CartItem> getCartItemsByCartId(String cartId){
        return [SELECT Id, Name, Sku, Type, Product2.Part_Number__c, Product2.Item_Class__c,Product2.Replacement_Product__c,Product2.Replacement_Alternatives__c FROM CartItem WHERE CartId =: cartId]; // RWPS-3740
    }

    //Insert cartTaxes
    public static List<CartTax> insertCartTaxes(List<CartTax> cartTaxes){
        insert cartTaxes;
        return cartTaxes;
    }

    //Create CartDeliveryGroup
    public static List<CartDeliveryGroup> insertCartDeliveryGroups(List<CartDeliveryGroup> cartDeliveryGroupsToInsert){
    	insert cartDeliveryGroupsToInsert;
        return cartDeliveryGroupsToInsert;
	}

    //Update CartDeliveryGroup
    public static List<CartDeliveryGroup> updateCartDeliveryGroups(List<CartDeliveryGroup> cartDeliveryGroupsToUpdate){
    	update cartDeliveryGroupsToUpdate;
        return cartDeliveryGroupsToUpdate;
	}

    //Fetch Cart Tax records for Cart Items
    public Static List<CartTax> getCartTaxRecords(Set<String> cartItems){
        List<CartTax> cartItemTax = [SELECT Id,CartItemId FROM CartTax WHERE CartItemId IN : cartItems LIMIT 5000];
        return cartItemTax;
    }

    //Upsert Cart Tax records
    public static void upsertCartTax(List<CartTax> cartTaxesToUpsert){
        upsert cartTaxesToUpsert;
    }

    //Delete Cart Tax record - garora@rafter.one - 9 April 2024 - RWPS-460
    public static void deleteCartTax(List<CartTax> cartTaxesToDelete){
        delete cartTaxesToDelete;
    }

    //Update cart Items
    public static void updateCartItems(List<CartItem> cartItemsToUpdate){
        update cartItemsToUpdate;
    }

    //Insert cart Items
    public static void insertCartItems(List<CartItem> cartItemsToInsert){
        insert cartItemsToInsert;
    }

    //Update Carts
    public static void updateCart(List<WebCart> cartsToUpdate){
    if(!Test.isRunningTest()){
        update cartsToUpdate;
    }
    }

    //Delete cart
    public static void deleteCart(List<WebCart> cartToDelete){
        delete cartToDelete;
    }

    //Delete cart items
    public static void deleteCartItems(List<CartItem> cartItemsToDelete){
        delete cartItemsToDelete;
    }

    //Delete cart items by Id
    public static void deleteCartItemsById(List<Id> cartItemIds){
        List<CartItem> cartItemsToDelete = [SELECT Id FROM CartItem WHERE Id IN : cartItemIds];
        delete cartItemsToDelete;
    }

    //Delete cart items for Product Id
    public static List<CartItem> deleteCartItemsforProductId(Id productId, Id cartId){
        List<CartItem> cartItemsToDelete = [SELECT Id, ECOM_Parent__c FROM CartItem WHERE Product2Id =: productId AND CartId =: cartId LIMIT 1000];
        return cartItemsToDelete;
    }

    //This method is used to update shipping date on cart item
    public static void updateShippingDateOnCartItem(Id cartItemId, Date shipDate){
        List<CartItem> cartItem = [SELECT Id, ECOM_Selected_Shipping_Date__c FROM CartItem WHERE Id =: cartItemId LIMIT 1];
        cartItem[0].ECOM_Selected_Shipping_Date__c = shipDate;
        update cartItem;
    }

    //This method is used to get Billling Country Code from Account
    public static String getAccountCountryCode(Id accId){
        List<Account> acc = [SELECT Id, BillingCountryCode FROM Account WHERE Id =: accId LIMIT 1];
        return acc[0].BillingCountryCode;
    }

    //Fetch Cart Delivery Group Method
    public static List<CartDeliveryGroupMethod> getCartDeliveryGroupMethodByCart(Id cartID){
        List<CartDeliveryGroupMethod> lstCartDelivery = [SELECT Id, Name, WebCartId, WebCart.CurrencyIsoCode, CartDeliveryGroupId, DeliveryMethodId,
                                                         CartCheckoutSessionId, ShippingFee, ExternalProvider
                                                         FROM CartDeliveryGroupMethod WHERE WebCartId = : cartID LIMIT 1000];
        return lstCartDelivery;
    }

    //Fetch Cart Delivery Group Method by id
    public static List<CartDeliveryGroupMethod> getCartDeliveryGroupMethodById(Id cartGroupID){
        List<CartDeliveryGroupMethod> lstCartDelivery = [SELECT Id, Name, WebCartId, WebCart.CurrencyIsoCode, CartDeliveryGroupId, DeliveryMethodId,
                                                         CartCheckoutSessionId, ShippingFee, ExternalProvider
                                                         FROM CartDeliveryGroupMethod WHERE Id = : cartGroupID LIMIT 1000];
        return lstCartDelivery;
    }

    //Fetch Cart Delivery Group  by id
    public static List<CartDeliveryGroup> getCartDeliveryGroupById(Id cartGroupID){
        List<CartDeliveryGroup> lstCartDelivery = [SELECT Id, DeliveryMethodId FROM CartDeliveryGroup WHERE Id = : cartGroupID LIMIT 1000];
        return lstCartDelivery;
    }

    //To fetch the carts that need to notified for Abandonment
    public static List<WebCart> getCartsBasedOnEmailNotificationForLeftOverCountries(ECOM_Abandoned_Cart_Notification__mdt notification,DateTime cartLastModifiedDateMax,DateTime cartLastModifiedDateMin,List<String> countries,List<String> statuses)
    {
        //RWPS-2786 START
        List<WebCart> lstWebCarts = new List<WebCart>();
        List<WebCart> carts=[Select id, AccountId, GrandTotalAmount,OwnerId,Owner.Name,Owner.Email,Owner.Phone,ECOM_Total_Savings__c, Contact__c, //RWPS-3197
                             Default_Ship_to_ERP_Address__r.ApiCountry__c,Default_Ship_to_ERP_Address__r.fxAddress_CountryName__c,  (SELECT Id, Product2Id, Type FROM CartItems) // RWPS-2786
                             from WebCart
                             where Default_Ship_to_ERP_Address__c!=null
                             and (Default_Ship_to_ERP_Address__r.ApiCountry__c not in :countries)
                             and (Default_Ship_to_ERP_Address__r.fxAddress_CountryName__c not in :countries)
                             and GrandTotalAmount>=:notification.Cart_Price_Bucket_Min__c and GrandTotalAmount<=:notification.Cart_Price_Bucket_Max__c
                             and LastModifiedDate>=:cartLastModifiedDateMin and LastModifiedDate<=:cartLastModifiedDateMax
                             and Status in :statuses //RWPS-3342
                            ];

        if (carts.isEmpty() == false) {
            Set<String> setUserIds = new Set<String>();
            Set<String> setNonPunchoutUserIds = new Set<String>();
            for (Webcart cart : carts) {
                setUserIds.add(cart.OwnerId);
            }
            for (User user : [SELECT Id, ECOM_Is_Punchout_User__c FROM User WHERE Id IN:setUserIds AND ECOM_Is_Punchout_User__c = false]) {
                setNonPunchoutUserIds.add(user.Id);
            }
            for (WebCart cart: carts) {
                if (setNonPunchoutUserIds.contains(cart.OwnerId)) {
                    lstWebCarts.add(cart);
              }
            }
        }
        //RWPS-2786 END
        return lstWebCarts;
    }

    //To fetch the carts that need to notified for Abandonment for a particular country
    public static List<WebCart> getCartsBasedOnEmailNotificationForSpecificCountry(ECOM_Abandoned_Cart_Notification__mdt notification,DateTime cartLastModifiedDateMax,DateTime cartLastModifiedDateMin,List<String> statuses,List<String> allCountries)
    {
        //RWPS-2786 START
        List<WebCart> lstWebCarts = new List<WebCart>();
        List<WebCart> carts=[Select id, Contact__c, AccountId, GrandTotalAmount,OwnerId,Owner.Name,Owner.Email,Owner.Phone,ECOM_Total_Savings__c,//RWPS-3197
                             Default_Ship_to_ERP_Address__r.ApiCountry__c,Default_Ship_to_ERP_Address__r.fxAddress_CountryName__c, (SELECT Id, Product2Id,Type FROM CartItems) // RWPS-2786
                             from WebCart
                             where (Default_Ship_to_ERP_Address__r.ApiCountry__c in :allCountries or Default_Ship_to_ERP_Address__r.fxAddress_CountryName__c in :allCountries)
                             and GrandTotalAmount>=:notification.Cart_Price_Bucket_Min__c and GrandTotalAmount<=:notification.Cart_Price_Bucket_Max__c
                             and LastModifiedDate>=:cartLastModifiedDateMin and LastModifiedDate<=:cartLastModifiedDateMax
                             and Status in :statuses //RWPS-3342 //RWPS-2786
                            ];

        if (carts.isEmpty() == false) {
            Set<String> setUserIds = new Set<String>();
            Set<String> setNonPunchoutUserIds = new Set<String>();
            for (Webcart cart : carts) {
                setUserIds.add(cart.OwnerId);
            }
            for (User user : [SELECT Id, ECOM_Is_Punchout_User__c FROM User WHERE Id IN:setUserIds AND ECOM_Is_Punchout_User__c = false]) {
                setNonPunchoutUserIds.add(user.Id);
            }
            for (WebCart cart: carts) {
                if (setNonPunchoutUserIds.contains(cart.OwnerId)) {
                    lstWebCarts.add(cart);
                }
            }
        }
        //RWPS-2786 End
        return lstWebCarts;
    }

    //Insert CartDeliveryGroupMethod records
    public static List<CartDeliveryGroupMethod> insertCartDeliveryGroupMethod(List<CartDeliveryGroupMethod> cartDeliveryGroupMethodsToInsert){
        insert cartDeliveryGroupMethodsToInsert;
        return cartDeliveryGroupMethodsToInsert;
    }

    //Update CartDeliveryGroupMethod records
    public static List<CartDeliveryGroupMethod> updateCartDeliveryGroupMethod(List<CartDeliveryGroupMethod> cartDeliveryGroupMethodsToUpdate){
        update cartDeliveryGroupMethodsToUpdate;
        return cartDeliveryGroupMethodsToUpdate;
    }

    public static Integer getCartCount(String condition)
    {
        String query='Select count() from WebCart';
        if(String.isNotBlank(condition))
        {
            query+=' where ECOM_Is_Punchout_Cart__c = false AND '+condition; //RWPS-3342 , RWPS-3811
        }
        Integer count= 0 ;
        try{
                count = Database.countQuery(query);
        }catch(Exception e){
            system.debug('stack:: ' + e.getStackTraceString());
            system.debug('err Message:: ' + e.getMessage());
        }
        return count;
    }


    //Fetch Store front config data based on module name/class name
    public static Map<String, String> getStorefrontFrontConfigByModule(String moduleName){
        return ECOM_Util.fetchStorefrontFrontConfigByModule(moduleName);
    }

    //Upsert cart Items - insert or update
    public static void upsertCartItems(List<CartItem> cartItemsToUpsert){
        upsert cartItemsToUpsert;
    }

    //get CartCheckoutSession to check if Order was created
    public static CartCheckoutSession getCartCheckoutSession(String BackgroundOperationId){
        CartCheckoutSession session;
        List<CartCheckoutSession> sessionList = [SELECT Id, Name, WebCartId, State, NextState, IsProcessing, BackgroundOperationId, OrderId, IsError, OrderReferenceNumber
         							FROM CartCheckoutSession
         							WHERE BackgroundOperationId=: BackgroundOperationId
                                    AND OrderId != null
                                    AND IsError = false ORDER BY CreatedDate DESC LIMIT 1];
        if(sessionList.size() > 0){
            session = sessionList[0];
        }
        return session;
    }

     //get CartCheckoutSession to check if Order was created
    public static CartCheckoutSession getCartCheckoutSessionByCartId(String cartId){
        CartCheckoutSession session ;
        List<CartCheckoutSession> sessionList = [SELECT Id, Name, WebCartId, State, NextState, IsProcessing, BackgroundOperationId, OrderId, IsError, OrderReferenceNumber
         							FROM CartCheckoutSession
         							WHERE WebCartId=: cartId
                                    AND IsError = false ORDER BY CreatedDate DESC LIMIT 1];
        if(sessionList.size() > 0){
            session = sessionList[0];
        }
        return session;
    }

    //create CartCheckoutSession if it was not created already
    public static CartCheckoutSession createCartCheckoutSession(CartCheckoutSession session){
        insert session;
        return session;
    }

    /**
    * @description  This method is used to get the Shipping Time Frames
    * @author prabhat.kumar4@zensar.com | July 8th 2025 || RWPS-1603
    * @param siteId | String
    * @param countryCode | String
    * @param destinationCity | String
    * @param priority | String
    * @return list<ECOM_ProductShippingTime__c>
    **/
    public static list<ECOM_ProductShippingTime__c> getShippingTimesByCountryAndCity(String siteId, String countryCode, String destinationCity, String priority) {

        // Fetching all the Shipping Time Frames
        List<ECOM_ProductShippingTime__c> lstProdShip = [SELECT ID, Ecom_Confidence_90__c, ECOM_Country__c, Ecom_Destination_City__c, Ecom_Priority__c, Ecom_Site__c,
                                                     Ecom_Total_DLV__c FROM ECOM_ProductShippingTime__c WHERE Ecom_Site__c =:siteId AND Ecom_Country__c = :countryCode
                                                    AND Ecom_Destination_City__c = :destinationCity AND Ecom_Priority__c = :priority];

        return lstProdShip;
    }

    /**
    * @description  This method is used to get the Shipping Time Frames
    * @author prabhat.kumar4@zensar.com | July 8th 2025 || RWPS-1603
    * @param siteId | String
    * @param countryCode | String
    * @param priority | String
    * @return list<ECOM_ProductShippingTime__c>
    **/
    public static list<ECOM_ProductShippingTime__c> getShippingTimesByCountry(String siteId, String countryCode, String priority) {

        // Fetching all the Shipping Time Frames
        List<ECOM_ProductShippingTime__c> lstProdShip = [SELECT ID, Ecom_Confidence_90__c, ECOM_Country__c, Ecom_Destination_City__c, Ecom_Priority__c, Ecom_Site__c,
                                                        Ecom_Total_DLV__c FROM ECOM_ProductShippingTime__c WHERE Ecom_Site__c =:siteId AND Ecom_Country__c = :countryCode
                                                        AND Ecom_Priority__c = :priority AND Ecom_Destination_City__c = NULL];

        return lstProdShip;
    }

    /**
    * @description  This method is used to get the Cart Item by Id
    * @author prabhat.kumar4@zensar.com | July 8th 2025 || RWPS-1603
    * @param cartItemId | String
    * @return CartItem
    **/
    public static CartItem getCartItemById(String cartItemId) {

        CartItem cartItm = [SELECT Id, ECOM_ShippingCode__c, CartId, Product2id, Product2.Transportation_Group__c, Cart.Default_Ship_to_ERP_Address__r.fxAddress_City__c,//RWPS-4896
                           Cart.Default_Ship_to_ERP_Address__r.fxAddress_CountryCode__c FROM CartItem  WHERE ID =: cartItemId];
        return cartItm;

    }

    //To fetch the carttax records based on cartId.
    public Static List<CartTax> getCartTaxRecordsPerCart(String cartId){
        List<CartTax> cartTax = [Select id,name,amount from CartTax where CartId = :cartId];
        return cartTax;
    }

/**
     * @description This method returns the punchout cart for a punchout user
     * @author vramachandran@rafter.one | 22 Dec 2023
     * @param userId | String
     * @returns List<WebCart>
     */
    public static List<WebCart> getActiveCartForPunchoutUser(String userId){
        Id accId = getAccountId(userId);
        return[SELECT Id, ECOM_Cart_Id__c, ECOM_Is_Punchout_Cart__c, ECOM_POOM_Lead_Time__c, ECOM_POOM_Shipping_Money__c, ECOM_POOM_Total_Money__c,
               ECOM_POSR_Browser_Form_Post_Url__c, ECOM_POSR_Buyer_Cookie__c, ECOM_POSR_First_Name__c, ECOM_POSR_Header_From_Credential_Domain__c, ECOM_POSR_Header_From_Credential_Ident__c,
               ECOM_POSR_Header_Lang__c, ECOM_POSR_Header_Payload_Id__c, ECOM_POSR_Header_Sender_Identity__c, ECOM_POSR_Header_SenderCredential_Domain__c,
               ECOM_POSR_Header_TimeStamp__c, ECOM_POSR_Header_To_Identity__c, ECOM_POSR_Header_Version__c, ECOM_POSR_Last_Name__c, ECOM_POSR_Punchout_Format__c, ECOM_POSR_Selected_Item__c,
               ECOM_POSR_Supplier_Part_Id__c, ECOM_POSR_Unique_Name__c, ECOM_POSR_UserEmail__c, ECOM_BillToAccount__c, ECOM_DefaultBillToCPA__c, ECOM_DefaultShipToCPA__c, ECOM_ShipToAccount__c,
               ECOM_POSR_Header_To_Credential_Domain__c
               FROM WebCart
               WHERE OwnerId = :userId
               AND Status IN ('Active','Checkout')
               AND isSecondary = false
                AND AccountId = :accId //GAr - 23 Feb 2024 change - ECOM-2687 - to pick cart belonging to user's current account
               LIMIT 1];
    }

    /**
    * @description  This method returns cart and cart items based on cartId
    * @author vramachandran@rafter.one | 05 Jan 2024
    * @param cartId
    * @return List<WebCart>
    **/
    public static List<WebCart> getPunchoutCartandCartItemsById(String cartId)
    {
        return [SELECT Id, Name,AccountId,Account.Name, PaymentMethodId,PoNumber, Type, IsSecondary,OwnerId, Owner.FirstName, Owner.LastName, Owner.Username, Owner.Email,Status,TaxType,TotalChargeAmount,
                ECOM_BillToAccount__c, ECOM_ShipToAccount__c, BillingCountryCode, ECOM_ShipToAccount__r.ShippingCountry,
                CurrencyIsoCode, GrandTotalAmount, UniqueProductCount,
                TotalListAmount,TotalProductAmount,TotalAdjustmentAmount,TotalProductCount,TotalPromoAdjustmentAmount,TotalTaxAmount,WebStoreId,
                ECOM_Quote_Number__c,ECOM_Promo_Code__c,ECOM_Total_Savings__c,
                Default_Bill_to_ERP_Address__c, Default_Bill_to_ERP_Address__r.Target_Address__c, Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c,
                Default_Ship_to_ERP_Address__c,  Default_Ship_to_ERP_Address__r.Target_Address__c, Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c,
                Default_Bill_to_ERP_Address__r.fxAddress_CountryName__c, Default_Bill_to_ERP_Address__r.apiCountry__c, Default_Bill_to_ERP_Address__r.Address_Country__c,
                Default_Bill_to_ERP_Address__r.ECOM_PU_Cust_E_Invoice__c, Default_Bill_to_ERP_Address__r.Target_Address__r.ECOM_PU_Cust_E_Invoice__c,
                ECOM_Is_Punchout_Cart__c, ECOM_POOM_Lead_Time__c, ECOM_POOM_Shipping_Money__c, ECOM_POOM_Total_Money__c, ECOM_POSR_Browser_Form_Post_Url__c,
                ECOM_POSR_Buyer_Cookie__c, ECOM_POSR_First_Name__c, ECOM_POSR_Header_From_Credential_Domain__c, ECOM_POSR_Header_From_Credential_Ident__c,
                ECOM_POSR_Header_Lang__c, ECOM_POSR_Header_Payload_Id__c, ECOM_POSR_Header_Sender_Identity__c, ECOM_POSR_Header_SenderCredential_Domain__c,
                ECOM_POSR_Header_TimeStamp__c, ECOM_POSR_Header_To_Identity__c, ECOM_POSR_Header_Version__c, ECOM_POSR_Last_Name__c, ECOM_POSR_Punchout_Format__c,
                ECOM_POSR_Selected_Item__c, ECOM_POSR_Supplier_Part_Id__c, ECOM_POSR_Unique_Name__c, ECOM_POSR_UserEmail__c,ECOM_POSR_Header_To_Credential_Domain__c,Total_Tariff_Surcharge__c,//RWPS-5603

                (SELECT Id, Sku, Quantity,ListPrice,SalesPrice,NetAdjustmentAmount,TotalAmount,TotalLineAmount,TotalPrice,TotalAdjustmentAmount,TotalPriceAfterAllAdjustments,ECOM_Earliest_Shipping_Date__c, ECOM_Selected_Shipping_Date__c,
                 UnitAdjustedPrice,UnitAdjustmentAmount,TotalListPrice, TotalTaxAmount, CartId, CartDeliveryGroupId, Product2.Id, ECOM_Parent__c,CurrencyIsoCode,Tariff_Surcharge__c,//RWPS-5603
                 ItemizedAdjustmentAmount,Name, NetUnitPrice,
                 Product2.Part_Number__c,Product2.Name,Product2.Dangerous_Goods_Indicator_Profile__c,Type , Product2.Business_Unit__c, Product2.Discount_Type__c,
                 Product2.Item_Class__c, Product2.Part_Type__c, Product2.Description, Product2.ECOM_Product_Media_URI__c,
                 Product2.Product_Line__c, Product2.Product_Type__c,Product2.IGOR_PAC__c,Product2.DisplayUrl,Product2.IGOR_Item_Class_Desc__c,
                 Product2.ECOM_UNSPSC_Code__c, Product2.QuantityUnitOfMeasure,
                 ECOM_POOM_fx_UNSPSC_Code__c, ECOM_Shipping_Cost__c, //RWPS-2941
                 Product2.ECOM_ISO_UOM__c, Product2.ECOM_UNUOM__c, Product2.ECOM_ANSI_UOM__c //RWPS-213 GAr - 6 March 2024 - querying the new fields created for UOM
                 ,Product2.Intrastat_CommodityCode_EU__c, Product2.Intrastat_CommodityCode_ROW__c //RWPS-586
                 FROM CartItems ORDER BY Sku ASC, ECOM_Earliest_Shipping_Date__c ASC)
                FROM WebCart WHERE Id =: cartId LIMIT 1];
    }

    //Update Punchout Carts
    public static List<WebCart> updatePunchoutCart(List<WebCart> cartsToUpdate){
        update cartsToUpdate;
        return cartsToUpdate;
    }

    /**
     * @description This method returns all the carts that are currently active for a user
     * @author vramachandran@rafter.one | 11 Jan 2024
     * @param userId | String
     * @returns List<WebCart>
     */
    public static List<WebCart> getPrimayActivePunchoutCartsForOwnerId(String userId){
        return [SELECT Id, Status, ECOM_Is_Punchout_Cart__c, (SELECT Id, Quantity FROM CartItems)
                FROM WebCart
                WHERE OwnerId=:userId
                AND (Status = 'Active' OR Status = 'Checkout')
                AND isSecondary = false
                LIMIT 49999];
    }

    /**
     * @description This method returns all the carts that are currently active for a user
     * @author vramachandran@rafter.one | 11 Jan 2024
     * @param userId | String
     * @returns List<WebCart>
     */
    public static List<WebCart> getPrimayActiveCartsForOwnerId(String userId){
        Id accId = getAccountId(userId);
        return [SELECT Id, Status, ECOM_Is_Punchout_Cart__c, (SELECT Id, Quantity FROM CartItems WHERE Type ='Product')
                FROM WebCart
                WHERE OwnerId=:userId
                AND (Status = 'Active' OR Status = 'Checkout')
                AND isSecondary = false
                AND AccountId = :accId //Gaurang - ECOM-3271 - added account condition to pick current account's cart - 13 June 2024
                LIMIT 1];
    }

    /**
     * @description This method returns all the carts that are currently active for a user
     * @author vramachandran@rafter.one | 28 Jun 2024 ECOM-3411
     * @param userId | String
     * @returns List<WebCart>
     */
    public static List<WebCart> getAllActivePunchoutCartsForOwnerId(String userId){
        return [SELECT Id, Status, ECOM_Is_Punchout_Cart__c
                FROM WebCart
                WHERE OwnerId=:userId
                AND (Status = 'Active' OR Status = 'Checkout')
                LIMIT 49999];
    }

     /**
     * @description This method returns count of the Coupon that are currently active
     * @author gaurav.bhansali@revvity.com | 31 Dec 2024 RWPS-2052
     * @param couponId | String
     * @returns Integer
     */
    public static Integer isValidPromo(String couponId, String promoName){
        return [SELECT count() FROM Coupon where Promotion.IsActive =true and Promotion.name=: promoName and status='Active' and couponCode=: couponId];
    }

    /**
     * @description This method returns count of the Coupon based on active status
     * @author gaurav.bhansali@revvity.com | 13 Mar 2025 RWPS-2800
     * @param couponId | String
     * @returns Integer
     */
    public static Integer isValidCouponCode(String couponId){
        return [SELECT count() FROM Coupon where status='Active' and couponCode=: couponId];
    }

    /**
     * @description This method returns count of the active Coupon based on country
     * @author gaurav.bhansali@revvity.com | 16 Jun 2025 RWPS-3186
     * @param couponId,country | String, String
     * @returns Integer
     */
    public static Integer isValidCouponCode(String couponId, String country){
        return [SELECT count() FROM Coupon where status='Active' and couponCode=: couponId and ECOM_Country__c includes ('Global',:country)];
    }

    /**
     * @description This method returns active coupon list based on coupon type
     * @author gaurav.bhansali@revvity.com | 20 May 2025 RWPS-3283
     * @param couponType
     * @return List of coupon code
     */
     public static List<Coupon> getCouponList(String couponType){
        return [SELECT couponCode FROM Coupon where status='Active' and ECOM_User_Type__c=: couponType];
    }

    /**
     * @description This method returns active coupon list based on coupon type
     * @author prabhat.kumar@revvity.com | 25 July 2025 RWPS-3812
     * @param couponCode
     * @return List of coupon record
     */
    public static List<Coupon> getCouponByCouponCode(String couponCode) {
        List<Coupon> coupons = [
            SELECT ECOM_Excluded_Products__c, Usage_Type__c,BOGO_Applicable_Products__c, Promotion.Name
            FROM Coupon
            WHERE Status = 'Active' AND CouponCode = :couponCode
        ];
        return coupons;
    }


    /**
     * @description This method returns active coupon for the promotion
     * @author gaurav.bhansali@revvity.com | 26 May 2025 RWPS-3225
     * @returns Integer | active coupon count
     */
    public static Integer isFirstTimePromoActive(){
        return [SELECT count() FROM Coupon where Promotion.IsActive =true and Promotion.name=: Label.ECOM_FirstOrderPromoName and status='Active'];
    }

     /**
     * @description This method return free items from cart
     * @param cartId
     * @return List<CartItem>
     * @author gaurav.bhansali@revvity.com | 14 Aug 2025 RWPS-3811
     */
    public static List<CartItem> getFreeItemsByCartId(String cartId){
        return [SELECT Id, Name, Sku, Type, Product2.Part_Number__c, Product2.Item_Class__c, ecom_parent_item__c FROM CartItem WHERE CartId =: cartId and ecom_parent_item__c !=''];
    }

     /**
     * Retrieves a map of parent CartItem records keyed by their Id.
     * Each CartItem includes the Part_Number__c of its associated Product2.
     * @param parentItemIds Set of CartItem Ids representing parent items.
     * @return Map<Id, CartItem> where key is the parent CartItem Id and value is the CartItem record.
     * JIRA:RWPS-3811 Prabhat Kumar
     */
    public static Map<Id, CartItem> getParentCartItemsWithPartNumbers(Set<Id> parentItemIds) {
        if (parentItemIds.isEmpty()) {
            return new Map<Id, CartItem>();
        }
        return new Map<Id, CartItem>(
            [SELECT Id, Product2.Part_Number__c FROM CartItem WHERE Id IN :parentItemIds]
        );
    }

       /**
     * This method updates the E-Invoice Customer ID (PEPPOL ID) on the Bill-To ERP Address and its associated Target Address when an order is placed.
     * RWPS-6394
     * @author Poonam
     * @param billToAddressId Id of the Bill-To ERP Address associated with the order
     * @param invoiceCustId E-Invoice Customer ID (PEPPOL ID) entered during checkout
     */
    public static void updateEInvoiceCustIdOnERPAddress(String billToAddressId, String invoiceCustId){

    if(String.isBlank(invoiceCustId) || billToAddressId == null){
        return;
    }

    ERP_Address__c billToAddress = [SELECT Id, Target_Address__c, ECOM_E_Invoice_Cust_Id__c FROM ERP_Address__c WHERE Id = :billToAddressId  LIMIT 1];

    List<ERP_Address__c> addressesToUpdate = new List<ERP_Address__c>();
    // Update BillTo Address
    billToAddress.ECOM_E_Invoice_Cust_Id__c = invoiceCustId;
    addressesToUpdate.add(billToAddress);
    // Update Target Address if present
    if(billToAddress.Target_Address__c != null){

        ERP_Address__c targetAddress = [SELECT Id, ECOM_E_Invoice_Cust_Id__c FROM ERP_Address__c WHERE Id = :billToAddress.Target_Address__c LIMIT 1];
        targetAddress.ECOM_E_Invoice_Cust_Id__c = invoiceCustId;
        addressesToUpdate.add(targetAddress);
    }

    if(!addressesToUpdate.isEmpty()){
        update addressesToUpdate;
    }
}
}