/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-
*	 ECOM-2555
* 2. Description - This class is used to retrieve user records.
*
*
*
* 3. Objects referenced
*    -User
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
*
* 5. Dependant Class(es):
*    - ECOM_LoginUtil
*
* 6. Test Class Name:
*    - ECOM_UserRepo_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vipul 2023.07.19
*    - Dar Wright Sept 26th 2023
* 	 - Vasudev 2024.04.23 ECOM-2555 added punchout field to SOQL Query
*    - Vipul 2024.05.06 Updated getUserByUserId function
*	 - Sathiya 2024.05.13 Adding default invoice mailing address field to all relevant methods
*    - Gaurang 2024.05.24 Added a method that queries user object, and returns list of user objects matching criteria - ECOM-112
*    - Sidak 2024.04.30 Added Contact.ECOM_AccountNameProvided__c field in getUserByUserId method. Ticket - RWPS-564
*    - Gaurang 2024.07.01 This method queries user object, and returns list of user objects matching criteria - ECOM-3322
*    - Sidak 2024.06.20 Added Contact.Prior_Email__c field in getUserByUserId method. Ticket - RWPS-313
*    - Sidak 2024.07.01 Added try catch block in futureUpdateUserPassword method. Ticket - RWPS-985
*    - Abhishek 2025.03.26 Updated getUserByUserId function - RWPS-2858
*    - Poonam 2025.06.11 Updated getUserByUserId function - RWPS-1882
*    - Gaurav 2025.06.30 Updated getUsersByUserIds function - RWPS-2786
*    - Manish Joshi 2025.07.17 Updated method getUserByUserId RWPS-3657
*    - Chirag L 2025.08.25 Updated method getUserByUserId RWPS-4154
*    - Prabhat 2025.09.23  Updated method getUserByUserId to include ECOM_Punchout_User_Email__c in query - RWPS-4131
*    - Chirag 2025.10.01  Updated method getUserByUserId to include in Dealer_Type__c in query - RWPS-4475
*    - Poonam 2025.09.29  Updated method getUserByUserId to include Ecom_Punchout_Additional_Email_Address__c in query - RWPS-4082
*    - Sachin V 2025.12.23 Updated method getUserRecordByUserEmail to include Ecom_Punchout_Additional_Email_Address__c, ECOM_Punchout_User_Email__c in query - RWPS-5507
*    - Sachin V 2025.12.26 Created method getOrganizationDetails - RWPS-5436
*    - Prabhat K 2026.02.05 Updated method getPunchoutUserInformationForErpAddress- RWPS-6095
*    - Sachin V 2026.03.05 Updated method getPunchoutUserInformationByUserId- RWPS-5938
*************************************************************/
public with sharing class ECOM_UserRepo {

    /**
    * @description This method is used to retrieve user based on username.
    * @author Vipul 2023.07.19
    * @param username
    * @return List<User>
    **/
    public static List<User> getUsersByUsername(String username)
    {
        return [
                Select Id,FirstName,LastName,Email,ContactId,
                Contact.AccountId, Contact.Account.Name,
            	ECOM_Is_Punchout_User__c //VRa ECOM-2555
                from User
                where username=:username LIMIT 1
               ];
    }

    /**
    * @description This method is used to retrieve user based on userId. //VRa- updated for punchout
    * @author Manish 2023.08.08
    * @param userId
    * @return User
    **/
    public static User getUserByUserId(String userId)
    {
        return [
                SELECT Id, Name, FirstName, Lastname, Phone, Fax, Email, ContactId, Contact.Name, Contact.AccountId, Contact.fxDomain__c, Account.Name, Account.CurrencyIsoCode,
                Contact.ECOM_NeedsVerification__c, Contact.ECOM_Is_Mapped__c, Contact.ECOM_CountryProvided__c, Contact.ECOM_AddressRegistration__c,
                Contact.Phone, Contact.ECOM_Phone_Extension__c, Contact.ECOM_DefaultShipToAccount__c, Contact.FirstName, Contact.LastName,
                Contact.ECOM_Delivery_Details__c, Contact.ECOM_Special_Instructions__c, Contact.ECOM_Attention_Recipient__c,Contact.ECOM_DefaultBillToAccount__c,
                AccountId,Contact.ECOM_RegistrationPattern__c,Contact.ECOM_AccountNameProvided__c,Contact.ECOM_AccountNumberProvided__c,Contact.ECOM_DefaultShipToCPA__c, Contact.ECOM_DefaultBillToCPA__c, Contact.ECOM_Country_Phone_Code__c, UserRole.Name,
                ECOM_Phone_Extension__c, ECOM_Country_Phone_Code__c, Account.SAP_Customer_Number_Formatted__c, Account.RAD_Identifier__c,Account.ShippingCountry,Account.ShippingCountryCode,
                Contact.Default_Bill_to_ERP_Address__c, Contact.Default_Ship_to_ERP_Address__c,Contact.Default_Sold_to_ERP_Address__c,
                Contact.Default_Invoice_ERP_Address__c,
                Contact.Default_Bill_to_ERP_Address__r.ERP_Account_Name__c, Contact.Default_Bill_to_ERP_Address__r.Account__c, Contact.Default_Bill_to_ERP_Address__r.Account__r.Name,
                Contact.Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c,
                Contact.Default_Bill_to_ERP_Address__r.fxAddress_City__c,
                Contact.Default_Bill_to_ERP_Address__r.fxAddress_CountryCode__c,
            	Contact.Default_Bill_to_ERP_Address__r.fxAddress_CountryName__c,
                Contact.Default_Bill_to_ERP_Address__r.fxAddress_Postal__c,
                Contact.Default_Bill_to_ERP_Address__r.fxAddress_StateName__c,
                Contact.Default_Bill_to_ERP_Address__r.fxAddress_Street__c,
                Contact.Default_Bill_to_ERP_Address__r.ECOM_Email_to_invoice__c,//RWPS-1882
                Contact.Default_Bill_to_ERP_Address__r.ECOM_E_Invoice_Cust_Id__c,//RWPS-1882
                Contact.Default_Bill_to_ERP_Address__r.Target_Address__c, // RWPS-4154
                Contact.Default_Bill_to_ERP_Address__r.Target_Address__r.ECOM_Email_to_invoice__c, // RWPS-4154
                Contact.Default_Bill_to_ERP_Address__r.Target_Address__r.ECOM_E_Invoice_Cust_Id__c, // RWPS-4154
                Contact.Default_Bill_to_ERP_Address__r.Master_Address__r.External_Id__c,
                Contact.Default_Ship_to_ERP_Address__r.Master_Address__r.ECOM_Punchout_User_Email__c,//RWPS-4131
                Contact.Default_Ship_to_ERP_Address__r.Master_Address__r.Ecom_Punchout_Additional_Email_Address__c, //RWPS-4082
                Contact.Default_Bill_to_ERP_Address__r.ECOM_Review_Status__c,
                Contact.Default_Ship_to_ERP_Address__r.ERP_Account_Name__c, Contact.Default_Ship_to_ERP_Address__r.Account__c, Contact.Default_Ship_to_ERP_Address__r.Account__r.Name,
                Contact.Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c,
                Contact.Default_Ship_to_ERP_Address__r.fxAddress_City__c,
                Contact.Default_Ship_to_ERP_Address__r.fxAddress_CountryCode__c,
            	Contact.Default_Ship_to_ERP_Address__r.fxAddress_CountryName__c,
                Contact.Default_Ship_to_ERP_Address__r.fxAddress_Postal__c,
                Contact.Default_Ship_to_ERP_Address__r.fxAddress_StateName__c,
                Contact.Default_Ship_to_ERP_Address__r.fxAddress_Street__c,
                Contact.Default_Ship_to_ERP_Address__r.Master_Address__r.External_Id__c,
                Contact.Default_Ship_to_ERP_Address__r.ECOM_Review_Status__c,
                Contact.Default_Ship_to_ERP_Address__r.RAD_Identifier__c,
                Contact.Default_Ship_to_ERP_Address__r.Master_Address__c,//RWPS-3657
                // Changes added for ECOM-1939
            	Contact.Default_Invoice_ERP_Address__r.ERP_Account_Name__c, Contact.Default_Invoice_ERP_Address__r.Account__c, Contact.Default_Invoice_ERP_Address__r.Account__r.Name,
                Contact.Default_Invoice_ERP_Address__r.Target_Address__r.External_Id__c,
                Contact.Default_Invoice_ERP_Address__r.fxAddress_City__c,
                Contact.Default_Invoice_ERP_Address__r.fxAddress_CountryCode__c,
            	Contact.Default_Invoice_ERP_Address__r.fxAddress_CountryName__c,
                Contact.Default_Invoice_ERP_Address__r.fxAddress_Postal__c,
                Contact.Default_Invoice_ERP_Address__r.fxAddress_StateName__c,
                Contact.Default_Invoice_ERP_Address__r.fxAddress_Street__c,
                Contact.Default_Invoice_ERP_Address__r.Master_Address__r.External_Id__c,
                Contact.Default_Invoice_ERP_Address__r.ECOM_Review_Status__c,
                Contact.Default_Invoice_ERP_Address__r.RAD_Identifier__c,
            	// changes end
                Contact.Default_Sold_to_ERP_Address__r.ERP_Account_Name__c, Contact.Default_Sold_to_ERP_Address__r.Account__c, Contact.Default_Sold_to_ERP_Address__r.Account__r.Name,
                Contact.Default_Sold_to_ERP_Address__r.Target_Address__r.External_Id__c,
                Contact.Default_Sold_to_ERP_Address__r.fxAddress_City__c,
                Contact.Default_Sold_to_ERP_Address__r.fxAddress_CountryCode__c,
                Contact.Default_Sold_to_ERP_Address__r.fxAddress_Postal__c,
                Contact.Default_Sold_to_ERP_Address__r.fxAddress_StateName__c,
                Contact.Default_Sold_to_ERP_Address__r.fxAddress_Street__c,
                Contact.Default_Sold_to_ERP_Address__r.Master_Address__r.External_Id__c,
                Country,Contact.Prior_Email__c, //RWPS-313
                CountryCode, // RWPS-2858
                Contact.Email,
                ECOM_Is_Punchout_User__c, //VRa - changes for punchout
                ECOM_Is_Test_User__c, //GAr - changes for punchout
                Contact.Default_Ship_to_ERP_Address__r.Master_Address__r.Dealer_Type__c // RWPS-4475
                FROM User
                WHERE Id=:userId LIMIT 1
               ];
    }

    /**
    * @description This method is used to retrieve users based on userIds.
    * @author Manish 2023.08.08
    * @param userIds
    * @return List<User>
    **/
    public static List<User> getUsersByUserIds(Set<String> userIds)
    {
        return [
                SELECT Id, ContactId, Contact.ECOM_NeedsVerification__c, AccountId, CreatedDate, Contact.ECOM_CountryProvided__c // RWPS-2786
                FROM User
                WHERE Id IN :userIds LIMIT 1000
               ];
    }



    /**
    * @description This method is used to set the password for the user(Invoking system Method).
    * @author Vipul Goyal | 08-02-2023
    * @param userId
    * @param password
    **/
    public static void doSetPassword(String userId, String password){
        System.setPassword(userId, password);
    }



    /**
    * @description This method is used to login the user into the system(Invoking system Method).
    * @author Vipul Goyal | 08-02-2023
    * @param strDecryptUserName
    * @param strDecryptPassword
    * @param strDefaultCartPath
    * @return PageReference
    **/
    public static PageReference loginUser(String strDecryptUserName,String strDecryptPassword,String strDefaultCartPath)
    {
        return Site.login(strDecryptUserName, strDecryptPassword, strDefaultCartPath);
    }

    /**
    * @description This method is used to change the User FirstName, LastName and related Contact Name.
    * @author Dar Wright | 09-05-2023
    * @param userObject
    **/
    public static void updateUser(User updatedUserData) {
        update updatedUserData;
    }

    /**
    * @description This method is used to update the user password in a future method from the Profile/Settings page
    * @author Dar Wright | 09-05-2023
    * @author Sidak Singh | 01-04-2024 | RWPS-985
    * @param passwordString
    * @param userId
    **/
    //@future(callout=true)
    public static Map<String,Object> futureUpdateUserPassword(String passwordString, Id userId) {
        Map<String,Object> responseMap = new Map<String,Object>();
        try {
            System.setPassword(userId, passwordString);
            responseMap.put('success',true);
        }catch(Exception e){
            responseMap.put('success',false);
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
        return responseMap;
    }

    /**
    * @description This method is used to create new user but preventing welcome email
    * @author Vasudev Ramachandran | 22-11-2023
    * @param userRecord
    * @param dmlOptions
    * @return boolean
    **/
    public static Database.SaveResult createUserWithDmlOptions(User userRecord, Database.DMLOptions dmlOptions){
        Database.SaveResult result = Database.insert(userRecord, dmlOptions);
        return result;
    }

    /**
    * @description This method returns user fields for a given user email
    * @author Vasudev Ramachandran | 22-11-2023
    * @param userEmail
    * @return boolean
    **/
    public static List<User> getUserRecordByUserEmail(String userEmail){
        return [
                SELECT Id, Name, FirstName, Lastname, Phone, Fax, Email, ContactId, Contact.Name, Contact.Email, Contact.AccountId, Contact.fxDomain__c, Account.Name,
                Contact.ECOM_NeedsVerification__c, Contact.ECOM_Is_Mapped__c, Contact.ECOM_CountryProvided__c, Contact.ECOM_AddressRegistration__c,
                Contact.Phone, Contact.ECOM_Phone_Extension__c, Contact.ECOM_DefaultShipToAccount__c, Contact.FirstName, Contact.LastName,
                Contact.ECOM_Delivery_Details__c, Contact.ECOM_Special_Instructions__c, Contact.ECOM_Attention_Recipient__c,Contact.ECOM_DefaultBillToAccount__c,
                AccountId,  Contact.ECOM_DefaultShipToCPA__c, Contact.ECOM_DefaultBillToCPA__c, Contact.ECOM_Country_Phone_Code__c, UserRole.Name,
                ECOM_Phone_Extension__c, ECOM_Country_Phone_Code__c, Account.SAP_Customer_Number_Formatted__c, Account.RAD_Identifier__c,Account.ShippingCountry,
                Contact.Default_Bill_to_ERP_Address__c, Contact.Default_Ship_to_ERP_Address__c,Contact.Default_Sold_to_ERP_Address__c,
                Contact.Default_Invoice_ERP_Address__c,
                Contact.Default_Bill_to_ERP_Address__r.ERP_Account_Name__c, Contact.Default_Bill_to_ERP_Address__r.Account__c, Contact.Default_Bill_to_ERP_Address__r.Account__r.Name,
                Contact.Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c,
                Contact.Default_Bill_to_ERP_Address__r.fxAddress_City__c,
                Contact.Default_Bill_to_ERP_Address__r.fxAddress_CountryCode__c,
                Contact.Default_Bill_to_ERP_Address__r.fxAddress_Postal__c,
                Contact.Default_Bill_to_ERP_Address__r.fxAddress_StateName__c,
                Contact.Default_Bill_to_ERP_Address__r.fxAddress_Street__c,
                Contact.Default_Bill_to_ERP_Address__r.Master_Address__r.External_Id__c,
                Contact.Default_Bill_to_ERP_Address__r.ECOM_Review_Status__c,
                Contact.Default_Ship_to_ERP_Address__r.ERP_Account_Name__c, Contact.Default_Ship_to_ERP_Address__r.Account__c, Contact.Default_Ship_to_ERP_Address__r.Account__r.Name,
                Contact.Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c,
                Contact.Default_Ship_to_ERP_Address__r.fxAddress_City__c,
                Contact.Default_Ship_to_ERP_Address__r.fxAddress_CountryCode__c,
                Contact.Default_Ship_to_ERP_Address__r.fxAddress_Postal__c,
                Contact.Default_Ship_to_ERP_Address__r.fxAddress_StateName__c,
                Contact.Default_Ship_to_ERP_Address__r.fxAddress_Street__c,
                Contact.Default_Ship_to_ERP_Address__r.Master_Address__r.External_Id__c,
                Contact.Default_Ship_to_ERP_Address__r.ECOM_Review_Status__c,
                Contact.Default_Ship_to_ERP_Address__r.RAD_Identifier__c,
                // Changes added for ECOM-1939
                Contact.Default_Invoice_ERP_Address__r.ERP_Account_Name__c, Contact.Default_Invoice_ERP_Address__r.Account__c, Contact.Default_Invoice_ERP_Address__r.Account__r.Name,
                Contact.Default_Invoice_ERP_Address__r.Target_Address__r.External_Id__c,
                Contact.Default_Invoice_ERP_Address__r.fxAddress_City__c,
                Contact.Default_Invoice_ERP_Address__r.fxAddress_CountryCode__c,
                Contact.Default_Invoice_ERP_Address__r.fxAddress_CountryName__c,
                Contact.Default_Invoice_ERP_Address__r.fxAddress_Postal__c,
                Contact.Default_Invoice_ERP_Address__r.fxAddress_StateName__c,
                Contact.Default_Invoice_ERP_Address__r.fxAddress_Street__c,
                Contact.Default_Invoice_ERP_Address__r.Master_Address__r.External_Id__c,
                Contact.Default_Invoice_ERP_Address__r.ECOM_Review_Status__c,
                Contact.Default_Invoice_ERP_Address__r.RAD_Identifier__c,
                // changes end
                Contact.Default_Sold_to_ERP_Address__r.ERP_Account_Name__c, Contact.Default_Sold_to_ERP_Address__r.Account__c, Contact.Default_Sold_to_ERP_Address__r.Account__r.Name,
                Contact.Default_Sold_to_ERP_Address__r.Target_Address__r.External_Id__c,
                Contact.Default_Sold_to_ERP_Address__r.fxAddress_City__c,
                Contact.Default_Sold_to_ERP_Address__r.fxAddress_CountryCode__c,
                Contact.Default_Sold_to_ERP_Address__r.fxAddress_Postal__c,
                Contact.Default_Sold_to_ERP_Address__r.fxAddress_StateName__c,
                Contact.Default_Sold_to_ERP_Address__r.fxAddress_Street__c,
                Contact.Default_Sold_to_ERP_Address__r.Master_Address__r.External_Id__c,
                Country,
            	UserName, ECOM_Is_Punchout_User__c,
                Contact.Default_Ship_to_ERP_Address__r.Master_Address__r.Ecom_Punchout_Additional_Email_Address__c, //RWPS-5507
                Contact.Default_Ship_to_ERP_Address__r.Master_Address__r.ECOM_Punchout_User_Email__c //RWPS-5507
                FROM User
                WHERE Email=:userEmail LIMIT 1
               ];
    }

    /**
     * @description fetch user and related account information for given userId
     * @author vramachandran@rafter.one | 29-Nov-2023
     * @param userId
     * @return List<User>
     */
    public static List<User> getAccountInformationForUserId(String userId){
        return [SELECT Id, Account.Name, Account.ECOM_PO_Product_Catalog_Exclude_Query__c, Account.ECOM_PO_Product_Catalog_Include_Query__c,
                AccountId //VRa - Changes for ECOM-3411
               	FROM User
               	WHERE Id =: userId LIMIT 1];
    }

    /**
     * @description fetch punchout user and related account information for a given userId
     * @author vramachandran@rafter.one | 11 Dec 2023
     * @param userId
     * @return List<User>
     */
    public static List<User> getPunchoutUserInformationByUserId(String userId){
        return [SELECT Id, Name, FirstName, Lastname, Phone, Fax, Email, ContactId, Contact.Name, Contact.AccountId, Contact.fxDomain__c, Account.Name,
                Contact.ECOM_NeedsVerification__c, Contact.ECOM_Is_Mapped__c, Contact.ECOM_CountryProvided__c, Contact.ECOM_AddressRegistration__c,
                Contact.Phone, Contact.ECOM_Phone_Extension__c, Contact.ECOM_DefaultShipToAccount__c, Contact.FirstName, Contact.LastName,
                Contact.ECOM_Delivery_Details__c, Contact.ECOM_Special_Instructions__c, Contact.ECOM_Attention_Recipient__c,Contact.ECOM_DefaultBillToAccount__c,
                AccountId, Contact.ECOM_DefaultShipToCPA__c, Contact.ECOM_DefaultBillToCPA__c, Contact.ECOM_Country_Phone_Code__c, UserRole.Name,
                ECOM_Phone_Extension__c, ECOM_Country_Phone_Code__c,
                Account.SAP_Customer_Number_Formatted__c, Account.RAD_Identifier__c,Account.ShippingCountry,
                Account.ECOM_PO_Display_List_Price__c, Account.ECOM_Is_Punchout_Account__c, Account.ECOM_PO_Product_Catalog_Exclude_Query__c, Account.ECOM_PO_Product_Catalog_Include_Query__c,
                Account.ECOM_Punchout_Company_Name__c, Account.ECOM_Punchout_Customer_Org_Logo__c, Account.ECOM_Punchout_CXML_Or_OCI__c, Account.ECOM_Punchout_Description__c,
                Account.ECOM_Punchout_Domain__c, Account.ECOM_Punchout_Platform_Name__c, Account.ECOM_Punchout_UOM__c,
                Contact.Default_Bill_to_ERP_Address__c, Contact.Default_Ship_to_ERP_Address__c,Contact.Default_Sold_to_ERP_Address__c,
                Contact.Default_Invoice_ERP_Address__c,
                Contact.Default_Bill_to_ERP_Address__r.ERP_Account_Name__c, Contact.Default_Bill_to_ERP_Address__r.Account__c, Contact.Default_Bill_to_ERP_Address__r.Account__r.Name,
                Contact.Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c,
                Contact.Default_Bill_to_ERP_Address__r.fxAddress_City__c,
                Contact.Default_Bill_to_ERP_Address__r.fxAddress_CountryCode__c,
                Contact.Default_Bill_to_ERP_Address__r.fxAddress_Postal__c,
                Contact.Default_Bill_to_ERP_Address__r.fxAddress_StateName__c,
                Contact.Default_Bill_to_ERP_Address__r.fxAddress_Street__c,
                Contact.Default_Bill_to_ERP_Address__r.Master_Address__r.External_Id__c,
                Contact.Default_Bill_to_ERP_Address__r.ECOM_Review_Status__c,
                Contact.Default_Ship_to_ERP_Address__r.ERP_Account_Name__c, Contact.Default_Ship_to_ERP_Address__r.Account__c, Contact.Default_Ship_to_ERP_Address__r.Account__r.Name,
                Contact.Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c,
                Contact.Default_Ship_to_ERP_Address__r.fxAddress_City__c,
                Contact.Default_Ship_to_ERP_Address__r.fxAddress_CountryCode__c,
                Contact.Default_Ship_to_ERP_Address__r.fxAddress_Postal__c,
                Contact.Default_Ship_to_ERP_Address__r.fxAddress_StateName__c,
                Contact.Default_Ship_to_ERP_Address__r.fxAddress_Street__c,
                Contact.Default_Ship_to_ERP_Address__r.Master_Address__r.External_Id__c,
                Contact.Default_Ship_to_ERP_Address__r.ECOM_Review_Status__c,
                Contact.Default_Ship_to_ERP_Address__r.RAD_Identifier__c,
                // Changes added for ECOM-1939
                Contact.Default_Invoice_ERP_Address__r.ERP_Account_Name__c, Contact.Default_Invoice_ERP_Address__r.Account__c, Contact.Default_Invoice_ERP_Address__r.Account__r.Name,
                Contact.Default_Invoice_ERP_Address__r.Target_Address__r.External_Id__c,
                Contact.Default_Invoice_ERP_Address__r.fxAddress_City__c,
                Contact.Default_Invoice_ERP_Address__r.fxAddress_CountryCode__c,
                Contact.Default_Invoice_ERP_Address__r.fxAddress_CountryName__c,
                Contact.Default_Invoice_ERP_Address__r.fxAddress_Postal__c,
                Contact.Default_Invoice_ERP_Address__r.fxAddress_StateName__c,
                Contact.Default_Invoice_ERP_Address__r.fxAddress_Street__c,
                Contact.Default_Invoice_ERP_Address__r.Master_Address__r.External_Id__c,
                Contact.Default_Invoice_ERP_Address__r.ECOM_Review_Status__c,
                Contact.Default_Invoice_ERP_Address__r.RAD_Identifier__c,
                // changes end
                Contact.Default_Sold_to_ERP_Address__r.ERP_Account_Name__c, Contact.Default_Sold_to_ERP_Address__r.Account__c, Contact.Default_Sold_to_ERP_Address__r.Account__r.Name,
                Contact.Default_Sold_to_ERP_Address__r.Target_Address__r.External_Id__c,
                Contact.Default_Sold_to_ERP_Address__r.fxAddress_City__c,
                Contact.Default_Sold_to_ERP_Address__r.fxAddress_CountryCode__c,
                Contact.Default_Sold_to_ERP_Address__r.fxAddress_Postal__c,
                Contact.Default_Sold_to_ERP_Address__r.fxAddress_StateName__c,
                Contact.Default_Sold_to_ERP_Address__r.fxAddress_Street__c,
                Contact.Default_Sold_to_ERP_Address__r.Master_Address__r.External_Id__c,
                Country,
            	UserName, ECOM_Is_Punchout_User__c,ECOM_Is_Test_User__c,
                Contact.ECOM_Punchout_Via_Web__c //RWPS-5938
                FROM User
                WHERE Id =:userId
				AND ECOM_Is_Punchout_User__c = true
                LIMIT 1 ];
    }

    /**
     * @description This method returns the required fields to get the ERP Address for the user
     * @author vramachandran@rafter.one | 22 Dec 2023
     * @param userId | String
     * @returns List<User>
     */
    public static List<User> getPunchoutUserInformationForErpAddress(String userId){
            return [SELECT Id, Name, FirstName, Lastname, Phone, Fax, Email, ContactId, Contact.Name, Contact.AccountId,Contact.ECOM_Punchout_Cart_Reset__c, //RWPS-5938
                    Contact.fxDomain__c, Account.Name, Contact.ECOM_CountryProvided__c,
                    Contact.Default_Ship_to_ERP_Address__c, Contact.Default_Bill_to_ERP_Address__c,
                    Country, UserName, ECOM_Is_Punchout_User__c, AccountId, Contact.Default_Ship_to_ERP_Address__R.Master_Address__c,Contact.Test_Record__c, //RWPS-6095
                    Contact.Default_Ship_to_ERP_Address__R.Master_Address__r.ECOM_Punchout_Customer_Name__c,Contact.Default_Ship_to_ERP_Address__R.Master_Address__r.ECOM_Punchout_Format__c////RWPS-6095
                    FROM User
                    WHERE Id =:userId
                    AND ECOM_Is_Punchout_User__c = true
                    LIMIT 1 ];
    }

    /**
     * @description fetch punchout user and related account information for a given userId
     * @author vramachandran@rafter.one | 11 Dec 2023
     * @param userName | String
     * @return List<User>
     */
    public static List<User> getPunchoutUserInformationByUserName(String userName){
        return [SELECT Id, Name, FirstName, Lastname, Phone, Fax, Email, ContactId, Contact.Name, Contact.AccountId, Contact.fxDomain__c, Account.Name,
                Contact.ECOM_NeedsVerification__c, Contact.ECOM_Is_Mapped__c, Contact.ECOM_CountryProvided__c, Contact.ECOM_AddressRegistration__c,
                Contact.Phone, Contact.ECOM_Phone_Extension__c, Contact.ECOM_DefaultShipToAccount__c, Contact.FirstName, Contact.LastName,
                Contact.ECOM_Delivery_Details__c, Contact.ECOM_Special_Instructions__c, Contact.ECOM_Attention_Recipient__c,Contact.ECOM_DefaultBillToAccount__c,
                AccountId, Contact.ECOM_DefaultShipToCPA__c, Contact.ECOM_DefaultBillToCPA__c, Contact.ECOM_Country_Phone_Code__c, UserRole.Name,
                ECOM_Phone_Extension__c, ECOM_Country_Phone_Code__c,
                Account.SAP_Customer_Number_Formatted__c, Account.RAD_Identifier__c,Account.ShippingCountry,
                Account.ECOM_PO_Display_List_Price__c, Account.ECOM_Is_Punchout_Account__c, Account.ECOM_PO_Product_Catalog_Exclude_Query__c, Account.ECOM_PO_Product_Catalog_Include_Query__c,
                Account.ECOM_Punchout_Company_Name__c, Account.ECOM_Punchout_Customer_Org_Logo__c, Account.ECOM_Punchout_CXML_Or_OCI__c, Account.ECOM_Punchout_Description__c,
                Account.ECOM_Punchout_Domain__c, Account.ECOM_Punchout_Platform_Name__c, Account.ECOM_Punchout_UOM__c,
                Contact.Default_Bill_to_ERP_Address__c, Contact.Default_Ship_to_ERP_Address__c,Contact.Default_Sold_to_ERP_Address__c,
                Contact.Default_Invoice_ERP_Address__c,
                Contact.Default_Bill_to_ERP_Address__r.ERP_Account_Name__c, Contact.Default_Bill_to_ERP_Address__r.Account__c, Contact.Default_Bill_to_ERP_Address__r.Account__r.Name,
                Contact.Default_Bill_to_ERP_Address__r.Target_Address__r.External_Id__c,
                Contact.Default_Bill_to_ERP_Address__r.fxAddress_City__c,
                Contact.Default_Bill_to_ERP_Address__r.fxAddress_CountryCode__c,
                Contact.Default_Bill_to_ERP_Address__r.fxAddress_Postal__c,
                Contact.Default_Bill_to_ERP_Address__r.fxAddress_StateName__c,
                Contact.Default_Bill_to_ERP_Address__r.fxAddress_Street__c,
                Contact.Default_Bill_to_ERP_Address__r.Master_Address__r.External_Id__c,
                Contact.Default_Bill_to_ERP_Address__r.ECOM_Review_Status__c,
                Contact.Default_Ship_to_ERP_Address__r.ERP_Account_Name__c, Contact.Default_Ship_to_ERP_Address__r.Account__c, Contact.Default_Ship_to_ERP_Address__r.Account__r.Name,
                Contact.Default_Ship_to_ERP_Address__r.Target_Address__r.External_Id__c,
                Contact.Default_Ship_to_ERP_Address__r.fxAddress_City__c,
                Contact.Default_Ship_to_ERP_Address__r.fxAddress_CountryCode__c,
                Contact.Default_Ship_to_ERP_Address__r.fxAddress_Postal__c,
                Contact.Default_Ship_to_ERP_Address__r.fxAddress_StateName__c,
                Contact.Default_Ship_to_ERP_Address__r.fxAddress_Street__c,
                Contact.Default_Ship_to_ERP_Address__r.Master_Address__r.External_Id__c,
                Contact.Default_Ship_to_ERP_Address__r.ECOM_Review_Status__c,
                Contact.Default_Ship_to_ERP_Address__r.RAD_Identifier__c,
                // Changes added for ECOM-1939
                Contact.Default_Invoice_ERP_Address__r.ERP_Account_Name__c, Contact.Default_Invoice_ERP_Address__r.Account__c, Contact.Default_Invoice_ERP_Address__r.Account__r.Name,
                Contact.Default_Invoice_ERP_Address__r.Target_Address__r.External_Id__c,
                Contact.Default_Invoice_ERP_Address__r.fxAddress_City__c,
                Contact.Default_Invoice_ERP_Address__r.fxAddress_CountryCode__c,
                Contact.Default_Invoice_ERP_Address__r.fxAddress_CountryName__c,
                Contact.Default_Invoice_ERP_Address__r.fxAddress_Postal__c,
                Contact.Default_Invoice_ERP_Address__r.fxAddress_StateName__c,
                Contact.Default_Invoice_ERP_Address__r.fxAddress_Street__c,
                Contact.Default_Invoice_ERP_Address__r.Master_Address__r.External_Id__c,
                Contact.Default_Invoice_ERP_Address__r.ECOM_Review_Status__c,
                Contact.Default_Invoice_ERP_Address__r.RAD_Identifier__c,
                // changes end
                Contact.Default_Sold_to_ERP_Address__r.ERP_Account_Name__c, Contact.Default_Sold_to_ERP_Address__r.Account__c, Contact.Default_Sold_to_ERP_Address__r.Account__r.Name,
                Contact.Default_Sold_to_ERP_Address__r.Target_Address__r.External_Id__c,
                Contact.Default_Sold_to_ERP_Address__r.fxAddress_City__c,
                Contact.Default_Sold_to_ERP_Address__r.fxAddress_CountryCode__c,
                Contact.Default_Sold_to_ERP_Address__r.fxAddress_Postal__c,
                Contact.Default_Sold_to_ERP_Address__r.fxAddress_StateName__c,
                Contact.Default_Sold_to_ERP_Address__r.fxAddress_Street__c,
                Contact.Default_Sold_to_ERP_Address__r.Master_Address__r.External_Id__c,
                Country,
            	UserName, ECOM_Is_Punchout_User__c
                FROM User
                WHERE UserName =:userName
				AND ECOM_Is_Punchout_User__c = true
                LIMIT 1 ];
    }

    /**
     * @description This method queries user object, and returns list of user objects matching criteria
     * @author vramachandran@rafter.one | 22 Dec 2023
     * @param userName | String
     * @returns List<User>
     */
    public static List<User> isPunchoutUserExists(String userName){
        return [SELECT Id, UserName
                FROM User
                WHERE UserName =: userName
                AND ECOM_Is_Punchout_User__c = TRUE
                LIMIT 1];
    }

    /**
     * @description This method queries user object, and returns list of user objects matching criteria - ECOM-112
     * @author garora@rafter.one | 23 May 2024
     * @param emails | List<String>
     * @returns List<User>
    */
    public static List<User> checkCommunityUsers(List<String> emails){
        return [SELECT Email
                FROM User
                WHERE Email IN :emails
                AND IsPortalEnabled = true LIMIT 49999];
    }

    /**
     * @description This method queries user object, and returns list of user objects matching criteria - ECOM-3322
     * @author garora@rafter.one | 7 June 2024
     * @param emails | List<String>
     * @returns List<User>
    */
    public static List<User> checkInternalUsers(List<String> emails){
        return [SELECT Id,Email
                FROM User
                WHERE Email IN :emails LIMIT 49999];
    }

    /**
     * @description This method queries Organization object, and returns list of user Organization matching criteria
     * RWPS-5436
     * @author Sachin Vispute | 2025-12-28
     * @param orgIdsList | List<String>
     * @returns List<Organization>
    */
    public static List<Organization> getOrganizationDetails(List<String> orgIdsList) {
        return [SELECT Id, Name, IsSandbox FROM Organization WHERE Id IN :orgIdsList];
    }
}