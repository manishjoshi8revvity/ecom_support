/**************************************************************
 * 1. Ticket(s) that relates to this class
 * - ECOM-1020
 * 
 * 2. Description - It is a wrapper class used to store request and response wrapper object for Punchout User Login api.
 *					
 *
 * 3. Objects referenced
 * - User
 *
 * 4. Callouts to additional Components (including their methods) or None:
 * - None
 *
 * 5. Dependant Class(es):
 * - ECOM_PunchoutUserController
 *
 * 6. Test Class Name: Test_Class_Name
 *
 * 7. Is @Invocable (Yes or No): No
 *
 * 8. Author Name(s): 
 * - Vasudev Ramachandran 2023.11.22
 *
*************************************************************/ 
public class ECOM_PunchoutUserWrapper {
    
    
    @AuraEnabled public String accountName;
    @AuraEnabled public String accountLogo;
    
    //this class is to accept PunchoutUser API request
    public class Request{
        @InvocableVariable
        public String userDataJson;
    }
    
    //this class is to accept PunchoutUser API reponse
    public class Response{
        @InvocableVariable
        public Boolean isSuccess;
        @InvocableVariable
        public String loginUrl;
        @InvocableVariable
        public String responseMessage;
        @InvocableVariable
        public String punchoutUserId;
        @InvocableVariable
        public Boolean isValidPunchoutUser;
        @InvocableVariable
        public String cmsPdpRedirectUrl;
        @InvocableVariable
        public String productCode;
        @InvocableVariable
        public String punchoutUserEmail;
        @InvocableVariable
        public String punchoutAccountName;
        @InvocableVariable
        public String punchoutAccountLogoUrl;
        @InvocableVariable
        public String encryptedData;
    }
    
    //this class is to map user navigation fields
    public class StoreNavigationWrapper{
        @AuraEnabled public Boolean viewProfileSettingPage {get;set;}
        @AuraEnabled public Boolean viewAccountPage {get;set;}
        @AuraEnabled public Boolean viewOrderPage {get;set;}
        @AuraEnabled public Boolean viewRecentOrders {get;set;}
        @AuraEnabled public Boolean viewFavourites {get;set;}
        @AuraEnabled public Boolean viewFrequentlyPurchased {get;set;}
        @AuraEnabled public Boolean viewQuickOrder {get;set;}
        @AuraEnabled public Boolean viewLogout {get;set;} 
        @AuraEnabled public String storeForwardUrl {get;set;}
    }

}