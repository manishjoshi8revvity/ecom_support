/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    ECOM-928
*
* 2. Description - This class is used for retrieving and or creating ERP_Address__c records
*
* 3. Objects referenced
*    - ERP Address
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
* 5. Dependant Class(es):
*    
*
* 6. Test Class Name: 
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Rani Thumma 2023.10.10
*    - vramachandran@rafter.one | 23 Dec 2023
*    - Sidak 2024.02.12 Updated fetchERPAddressesByMaster method. Ticket - RWPS-140
*    - vramachandran@rafter.one | 09 Feb 2023 : Updated getERPMasterAddressForPunchoutAccountId method to include Master_Address__c column
*    - vramachandran@rafter.one | 10 Feb 2023 : ECOM-2504:Updated getPunchoutAddressesForERPMasterAddressId and getPunchoutAddressesForERPAddressModel
*    - garora@rafter.one | 03 Apr 2024 : RWPS-410 - querying new field (ECOM_Punchout_Default_UNSPSC__c) created for requirement
*    - sveeraraghavan@rafer.one | 29 Apr 2024 : ECOM-1933, ECOM-1942 - adding new fields to all the methods related to the user stories.
*    - ssingh@rafter.one | 30 May 2024 : RWPS-392 - Updated methods fetchERPRelationshipsByContactId & fetchERPRelationshipsByERPAddress, added field Is_Disabled__c in the query
*    - ssingh@rafter.one | 05 Jun 2024 : RWPS-392 - Added method getDisabledERPAddressesFromERPRelationship, Updated method fetchERPAddressesByMaster
*    - ssingh@rafter.one | 10 Jun 2024 : RWPS-392 - Added methods getERPAddressesBasedOnAccountId, getERPRelationshipsByContactId, insertERPRelationships
*    - ssingh@rafter.one | 18 Jun 2024 : RWPS-392 - Updated methods getERPAddressesBasedOnAccountId. Added Master_Address__r.Address_Type__c in query
*    - sveeraraghavan@rafer.one | 27 Jun 2024 : ECOM-3389 - adding new fields to all the methods related to the user stories.
*	 - sveeraraghavan@rafer.one | 01 Jul 2024 : Adding fields for Target Address for ECOM-3410
*    - vramachandran@rafter.one | 02 Jul 2024 : Adding fields for target address for ECOM-3301
*    - ssingh@rafter.one | 02 Jul 2024 : RWPS-553 - Updated methods getERPAddressesBasedOnAccountId, getERPRelationshipsByContactId. Added Master_Address__r.External_Id__c, ERP_Contact_ID__c in query
*    - ssingh@rafter.one | 24 Jul 2024 : RWPS-1144 - Added methods getMasterERPAddressesBasedOnAccountId, getNonPlaceholderAccountsFromAcrBasedOnContact
*    - Sidak 2024.11.19 - Added logic to fetch punchout erp address in query in method getPunchoutERPAddresses - RWPS-1809
*    - Poonam 2025.01.03 - Added method getAllAddressForPunchout for fetching punchout addresses - RWPS - 1456
*    - Manish Joshi 2025.07.11 - Updated method fetchERPAddressesByContactId - RWPS-3657
*    - Manish Joshi 2025.07.11 - Added method getERPAddressBasedOnName,getSoldToRelatedToShipTo - RWPS-3657
*    - Mahesh 2025.10.8 Updated method fetchERPAddressesBySapNumber - RWPS-4498
*    - Manish Joshi 2025.10.23 Updated method fetchERPAddressesByContactId - RWPS-4900
*    - Manish Joshi 2025.10.27 Updated method fetchERPAddressesByContactId,fetchERPAddressesBySoldTo,fetchERPAddressesBySapNumber - RWPS-4915
*    - Manish Joshi 2025.10.27 Updated method fetchERPAddressesByMaster, fetchERPAddressesByDomain - RWPS-4915
*    - Mahesh 2025.10.8 Updated method getDisabledERPAddressesFromERPRelationship - RWPS-4776
*    - Poonam Shukla 2025.11.04 Updated method fetchERPAddressesByContactId,fetchERPAddressesBySoldTo,fetchERPAddressesBySapNumber, fetchERPAddressesByMaster, fetchERPAddressesByDomain- RWPS-5048
*    - Manish Joshi 2026.01.30 Added method getPunchoutConfigs, Updated method getPunchoutERPAddresses - RWPS-5776
*    - Poonam Shukla 2026.02.19 Added method getPunchoutConfigBasedOnMaster - RWPS-5777
*    - Tushar Arora 2026.03.11  Updated method fetchERPAddressesByContactId,fetchERPAddressesBySoldTo,fetchERPAddressesBySapNumber, fetchERPAddressesByMaster, fetchERPAddressesByDomain- RWPS-5618
*    - Samantha Casseus 2026.04.08 Updated method fetchERPAddressesByContactId,fetchERPAddressesBySoldTo,fetchERPAddressesBySapNumber, fetchERPAddressesByMaster, fetchERPAddressesByDomain- RWPS-6694
*************************************************************/
public without sharing class ERP_AddressRepo {
    /**
    * @description This method is used to retrieve ERP_Address__c records for logged in user
    * @author Rani Thumma | 2023-10-10
    * @param contactId 
    * @return List<ERP_Address__c> 
    **/
    public static List<ERP_Address__c> fetchERPAddressesByContactId(String contactId, set<String> erpIds, String salesOrg){
        //RWPS-6694 - added condition to check if the user is test user or not, if test user then show all the records irrespective of sales org and erp ids for testing purpose, else show records based on sales org and erp ids
        Boolean isTest = [
        SELECT ECOM_Is_Test_User__c
        FROM User
        WHERE Id = :UserInfo.getUserId()
        LIMIT 1
        ].ECOM_Is_Test_User__c;

        if (isTest) {
        
        return [SELECT Id, Account__c, Account__r.Name, Contact__c,ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, ERP_Account_Group__c, 
                Address_Type__c, ERP_Customer_Number__c, ERP_Sales_Org__c, MDM_Customer_Status__c, Address_Street_Line_1__c, 
                Address_Street_Line_2__c, Address_City__c, apiState__c, Address_Postal_Code__c, apiCountry__c, fxAddress_City__c,
                fxAddress_CountryCode__c, fxAddress_Postal__c, fxAddress_StateName__c, fxAddress_Street__c, fxAddressFull__c,External_Id__c, ERP_Account_Name__c, 
                ERP_Marked_for_Deletion__c, RecordType.Name, ERP_Partner_Code__c, Master_Address__c, Master_Address__r.External_Id__c, 
                Master_Address__r.Address_Street_Line_1__c, Master_Address__r.Address_Street_Line_2__c, Master_Address__r.Address_City__c,
                Master_Address__r.apiState__c, Master_Address__r.apiCountry__c, Master_Address__r.Address_Postal_Code__c,  Target_Address__c,
                Target_Address__r.External_Id__c,Target_Address__r.Address_Street_Line_1__c, Target_Address__r.Address_Street_Line_2__c, 
                Target_Address__r.Address_City__c, Target_Address__r.apiState__c, Target_Address__r.Address_Postal_Code__c, 
                Target_Address__r.apiCountry__c,SAP_Name_1__c, SAP_Name_2__c,SAP_Name_3__c,SAP_Name_4__c,
                Target_Address__r.SAP_Name_1__c, Target_Address__r.SAP_Name_2__c,Target_Address__r.SAP_Name_3__c,Target_Address__r.SAP_Name_4__c,RAD_Identifier__c,
                ECOM_Punchout_Processors__c //GAr - added for punchout
, Target_Address__r.ECOM_E_Invoice_Cust_Id__c, Target_Address__r.ECOM_EAN_Do_Not_Use__c, Target_Address__r.ECOM_VAT_Number__c
                , Target_Address__r.ECOM_PU_Cust_E_Invoice__c, Target_Address__r.ECOM_Email_To_Invoice__c
                , ECOM_E_Invoice_Cust_Id__c, ECOM_EAN_Do_Not_Use__c, ECOM_VAT_Number__c, ECOM_PU_Cust_E_Invoice__c // Sathiya - ECOM-1933, ECOM-1942
                , ECOM_Email_To_Invoice__c // Sathiya - ECOM-3389
                , fxCustomerName_Target__c // RWPS-5048
        FROM ERP_Address__c 
        WHERE 
                //fxIsECOMenabled__c = true AND 
                ERP_Marked_for_Deletion__c = false AND
                Address_Type__c IN ('Payer', 'Ship To', 'Sold To', 'Bill To') AND
                (
                (ECOM_Review_Status__c IN ('New','In Progress') AND Contact__c = :contactId AND ECOM_isEnabled__c = true) OR
                (ECOM_Review_Status__c = 'Approved' AND Contact__c = null AND fxIsECOMenabled__c = true AND 
                 ERP_Sales_Org__c = :salesOrg AND// for mapped user
                 (Id IN :erpIds AND Address_Type__c!='Master') AND // RWPS-3657
                 (((fxFilterType__c like '1112%' OR fxFilterType__c like '1113%') AND
                 (Master_Address__r.Sub_Account_Group__c !='04'))  // RWPS-4900
                        OR 
                 (Master_Address__r.Sub_Account_Group__c ='04' AND Master_Address__r.Customer_Type__c IN ('ZW','ZX') 
                 AND (fxFilterType__c like '1112%' OR fxFilterType__c like '1133%'))) // RWPS-4915
                 //RWPS-5048
                  AND (
                 fxCustomerName_Target__c != 'FISHER SCIENTIFIC' AND fxCustomerName_Target__c != 'VWR' AND (NOT fxCustomerName_Target__c LIKE 'FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Target__c LIKE '% FISHER SCIENTIFIC')
                 AND (NOT fxCustomerName_Target__c LIKE '% FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Target__c LIKE 'VWR %') AND (NOT fxCustomerName_Target__c LIKE '% VWR') AND (NOT fxCustomerName_Target__c LIKE '% VWR %')
                )
                AND (
                 fxCustomerName_Master__c != 'FISHER SCIENTIFIC' AND fxCustomerName_Master__c != 'VWR' AND (NOT fxCustomerName_Master__c LIKE 'FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Master__c LIKE '% FISHER SCIENTIFIC')
                 AND (NOT fxCustomerName_Master__c LIKE '% FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Master__c LIKE 'VWR %') AND (NOT fxCustomerName_Master__c LIKE '% VWR') AND (NOT fxCustomerName_Master__c LIKE '% VWR %')
                )
                 ))
                ];
        } else {
        //fetch fx fields for approved status, for new and in progress regular fields
        return [SELECT Id, Account__c, Account__r.Name, Contact__c,ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, ERP_Account_Group__c, 
                Address_Type__c, ERP_Customer_Number__c, ERP_Sales_Org__c, MDM_Customer_Status__c, Address_Street_Line_1__c, 
                Address_Street_Line_2__c, Address_City__c, apiState__c, Address_Postal_Code__c, apiCountry__c, fxAddress_City__c,
                fxAddress_CountryCode__c, fxAddress_Postal__c, fxAddress_StateName__c, fxAddress_Street__c, fxAddressFull__c,External_Id__c, ERP_Account_Name__c, 
                ERP_Marked_for_Deletion__c, RecordType.Name, ERP_Partner_Code__c, Master_Address__c, Master_Address__r.External_Id__c, 
                Master_Address__r.Address_Street_Line_1__c, Master_Address__r.Address_Street_Line_2__c, Master_Address__r.Address_City__c,
                Master_Address__r.apiState__c, Master_Address__r.apiCountry__c, Master_Address__r.Address_Postal_Code__c,  Target_Address__c,
                Target_Address__r.External_Id__c,Target_Address__r.Address_Street_Line_1__c, Target_Address__r.Address_Street_Line_2__c, 
                Target_Address__r.Address_City__c, Target_Address__r.apiState__c, Target_Address__r.Address_Postal_Code__c, 
                Target_Address__r.apiCountry__c,SAP_Name_1__c, SAP_Name_2__c,SAP_Name_3__c,SAP_Name_4__c,
                Target_Address__r.SAP_Name_1__c, Target_Address__r.SAP_Name_2__c,Target_Address__r.SAP_Name_3__c,Target_Address__r.SAP_Name_4__c,RAD_Identifier__c,
                ECOM_Punchout_Processors__c //GAr - added for punchout
, Target_Address__r.ECOM_E_Invoice_Cust_Id__c, Target_Address__r.ECOM_EAN_Do_Not_Use__c, Target_Address__r.ECOM_VAT_Number__c
                , Target_Address__r.ECOM_PU_Cust_E_Invoice__c, Target_Address__r.ECOM_Email_To_Invoice__c
                , ECOM_E_Invoice_Cust_Id__c, ECOM_EAN_Do_Not_Use__c, ECOM_VAT_Number__c, ECOM_PU_Cust_E_Invoice__c // Sathiya - ECOM-1933, ECOM-1942
                , ECOM_Email_To_Invoice__c // Sathiya - ECOM-3389
                , fxCustomerName_Target__c // RWPS-5048
        FROM ERP_Address__c 
        WHERE 
                //fxIsECOMenabled__c = true AND 
                ERP_Marked_for_Deletion__c = false AND
                Address_Type__c IN ('Payer', 'Ship To', 'Sold To', 'Bill To') AND
                (
                (ECOM_Review_Status__c IN ('New','In Progress') AND Contact__c = :contactId AND ECOM_isEnabled__c = true) OR
                (ECOM_Review_Status__c = 'Approved' AND Contact__c = null AND fxIsECOMenabled__c = true AND 
                 ERP_Sales_Org__c = :salesOrg AND// for mapped user
                 (Id IN :erpIds AND Address_Type__c!='Master') AND // RWPS-3657
                 (((fxFilterType__c like '1112%' OR fxFilterType__c like '1113%') AND
                 (Master_Address__r.Sub_Account_Group__c !='04'))  // RWPS-4900
                        OR 
                 (Master_Address__r.Sub_Account_Group__c ='04' AND Master_Address__r.Customer_Type__c IN ('ZW','ZX') 
                 AND (fxFilterType__c like '1112%' OR fxFilterType__c like '1133%'))) // RWPS-4915
                 //RWPS-5048
                 AND (
                 fxCustomerName_Target__c != 'FISHER SCIENTIFIC' AND fxCustomerName_Target__c != 'VWR' AND fxCustomerName_Target__c != 'Revvity' AND fxCustomerName_Target__c != 'Perkin' AND (NOT fxCustomerName_Target__c LIKE 'FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Target__c LIKE '% FISHER SCIENTIFIC')
                 AND (NOT fxCustomerName_Target__c LIKE '% FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Target__c LIKE 'VWR %') AND (NOT fxCustomerName_Target__c LIKE '% VWR') AND (NOT fxCustomerName_Target__c LIKE '% VWR %')
                 AND (NOT fxCustomerName_Target__c LIKE 'Revvity %') AND (NOT fxCustomerName_Target__c LIKE '% Revvity') AND (NOT fxCustomerName_Target__c LIKE '% Revvity %')
                 AND (NOT fxCustomerName_Target__c LIKE 'Perkin %') AND (NOT fxCustomerName_Target__c LIKE '% Perkin') AND (NOT fxCustomerName_Target__c LIKE '% Perkin %')
                )//RWPS-5618 : added exclude Revvity, Perkin word condition
                AND (
                 fxCustomerName_Master__c != 'FISHER SCIENTIFIC' AND fxCustomerName_Master__c != 'VWR' AND fxCustomerName_Master__c != 'Revvity' AND fxCustomerName_Master__c != 'Perkin' AND (NOT fxCustomerName_Master__c LIKE 'FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Master__c LIKE '% FISHER SCIENTIFIC')
                 AND (NOT fxCustomerName_Master__c LIKE '% FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Master__c LIKE 'VWR %') AND (NOT fxCustomerName_Master__c LIKE '% VWR') AND (NOT fxCustomerName_Master__c LIKE '% VWR %')
                 AND (NOT fxCustomerName_Master__c LIKE 'Revvity %') AND (NOT fxCustomerName_Master__c LIKE '% Revvity') AND (NOT fxCustomerName_Master__c LIKE '% Revvity %')
                 AND (NOT fxCustomerName_Master__c LIKE 'Perkin %') AND (NOT fxCustomerName_Master__c LIKE '% Perkin') AND (NOT fxCustomerName_Master__c LIKE '% Perkin %')
                ) //RWPS-5618 : added exclude Revvity, Perkin word condition
                 ))
                ];
        }
    }
        
    public static List<ERP_Address__c> fetchERPAddressesBySoldTo(String contactId, String soldToSAPNumber, String contactDomain){
        List<ERP_Address__c> erpAddresses = new List<ERP_Address__c>();
        //RWPS-6694 - added condition to check if the user is test user or not, if test user then show all the records irrespective of sales org and erp ids for testing purpose, else show records based on sales org and erp ids 
        Boolean isTest = [
        SELECT ECOM_Is_Test_User__c
        FROM User
        WHERE Id = :UserInfo.getUserId()
        LIMIT 1
        ].ECOM_Is_Test_User__c;

        if (isTest) {

        /*String start = contactDomain+',%';
        String mid = '%,'+contactDomain+',%';
        String endString ='%,'+contactDomain;*/
        erpAddresses = [SELECT Id, Account__c, Account__r.Name, Contact__c,ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, ERP_Account_Group__c, 
                Address_Type__c, ERP_Customer_Number__c, ERP_Sales_Org__c, MDM_Customer_Status__c, Address_Street_Line_1__c, 
                Address_Street_Line_2__c, Address_City__c, apiState__c, Address_Postal_Code__c, apiCountry__c, fxAddress_City__c,
                fxAddress_CountryCode__c, fxAddress_Postal__c, fxAddress_StateName__c, fxAddress_Street__c, fxAddressFull__c,External_Id__c, ERP_Account_Name__c, 
                ERP_Marked_for_Deletion__c, RecordType.Name, ERP_Partner_Code__c, Master_Address__c, Master_Address__r.External_Id__c, 
                Master_Address__r.Address_Street_Line_1__c, Master_Address__r.Address_Street_Line_2__c, Master_Address__r.Address_City__c,
                Master_Address__r.apiState__c, Master_Address__r.apiCountry__c, Master_Address__r.Address_Postal_Code__c,  Target_Address__c,
                Target_Address__r.External_Id__c,Target_Address__r.Address_Street_Line_1__c, Target_Address__r.Address_Street_Line_2__c, 
                Target_Address__r.Address_City__c, Target_Address__r.apiState__c, Target_Address__r.Address_Postal_Code__c, 
                Target_Address__r.apiCountry__c,SAP_Name_1__c, SAP_Name_2__c,SAP_Name_3__c,SAP_Name_4__c,
                Target_Address__r.SAP_Name_1__c, Target_Address__r.SAP_Name_2__c,Target_Address__r.SAP_Name_3__c,Target_Address__r.SAP_Name_4__c,RAD_Identifier__c,
                ECOM_Punchout_Processors__c //GAr - added for punchout
, Target_Address__r.ECOM_E_Invoice_Cust_Id__c, Target_Address__r.ECOM_EAN_Do_Not_Use__c, Target_Address__r.ECOM_VAT_Number__c
                , Target_Address__r.ECOM_PU_Cust_E_Invoice__c, Target_Address__r.ECOM_Email_To_Invoice__c
                , ECOM_E_Invoice_Cust_Id__c, ECOM_EAN_Do_Not_Use__c, ECOM_VAT_Number__c, ECOM_PU_Cust_E_Invoice__c // Sathiya - ECOM-1933, ECOM-1942
                , ECOM_Email_To_Invoice__c // Sathiya - ECOM-3389
                , fxCustomerName_Target__c // RWPS-5048
                FROM ERP_Address__c 
                WHERE 
                ERP_Marked_for_Deletion__c = false AND
                Address_Type__c IN ('Payer', 'Ship To', 'Sold To', 'Bill To') AND
                (
                (ECOM_Review_Status__c IN ('New','In Progress') AND Contact__c = :contactId AND ECOM_isEnabled__c = true) OR
                (ECOM_Review_Status__c = 'Approved' AND Contact__c = null AND fxIsECOMenabled__c = true AND 
                 Master_Address__r.External_Id__c = :soldToSAPNumber AND 
                 (((fxFilterType__c like '1112%' OR fxFilterType__c like '1113%') 
                 AND Master_Address__r.Sub_Account_Group__c !='04')// RWPS-4900
                 OR (
                 (Master_Address__r.Sub_Account_Group__c ='04' AND Master_Address__r.Customer_Type__c IN ('ZW','ZX')
                 AND (fxFilterType__c like '1112%' OR fxFilterType__c like '1133%')))) // RWPS-4915
                  AND (
                 fxCustomerName_Target__c != 'FISHER SCIENTIFIC' AND fxCustomerName_Target__c != 'VWR' AND (NOT fxCustomerName_Target__c LIKE 'FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Target__c LIKE '% FISHER SCIENTIFIC')
                 AND (NOT fxCustomerName_Target__c LIKE '% FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Target__c LIKE 'VWR %') AND (NOT fxCustomerName_Target__c LIKE '% VWR') AND (NOT fxCustomerName_Target__c LIKE '% VWR %')
                )
                AND (
                 fxCustomerName_Master__c != 'FISHER SCIENTIFIC' AND fxCustomerName_Master__c != 'VWR' AND (NOT fxCustomerName_Master__c LIKE 'FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Master__c LIKE '% FISHER SCIENTIFIC')
                 AND (NOT fxCustomerName_Master__c LIKE '% FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Master__c LIKE 'VWR %') AND (NOT fxCustomerName_Master__c LIKE '% VWR') AND (NOT fxCustomerName_Master__c LIKE '% VWR %')
                )
                 ))
                ];
        return erpAddresses;
    } else {
        erpAddresses = [SELECT Id, Account__c, Account__r.Name, Contact__c,ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, ERP_Account_Group__c, 
                Address_Type__c, ERP_Customer_Number__c, ERP_Sales_Org__c, MDM_Customer_Status__c, Address_Street_Line_1__c, 
                Address_Street_Line_2__c, Address_City__c, apiState__c, Address_Postal_Code__c, apiCountry__c, fxAddress_City__c,
                fxAddress_CountryCode__c, fxAddress_Postal__c, fxAddress_StateName__c, fxAddress_Street__c, fxAddressFull__c,External_Id__c, ERP_Account_Name__c, 
                ERP_Marked_for_Deletion__c, RecordType.Name, ERP_Partner_Code__c, Master_Address__c, Master_Address__r.External_Id__c, 
                Master_Address__r.Address_Street_Line_1__c, Master_Address__r.Address_Street_Line_2__c, Master_Address__r.Address_City__c,
                Master_Address__r.apiState__c, Master_Address__r.apiCountry__c, Master_Address__r.Address_Postal_Code__c,  Target_Address__c,
                Target_Address__r.External_Id__c,Target_Address__r.Address_Street_Line_1__c, Target_Address__r.Address_Street_Line_2__c, 
                Target_Address__r.Address_City__c, Target_Address__r.apiState__c, Target_Address__r.Address_Postal_Code__c, 
                Target_Address__r.apiCountry__c,SAP_Name_1__c, SAP_Name_2__c,SAP_Name_3__c,SAP_Name_4__c,
                Target_Address__r.SAP_Name_1__c, Target_Address__r.SAP_Name_2__c,Target_Address__r.SAP_Name_3__c,Target_Address__r.SAP_Name_4__c,RAD_Identifier__c,
                ECOM_Punchout_Processors__c //GAr - added for punchout
, Target_Address__r.ECOM_E_Invoice_Cust_Id__c, Target_Address__r.ECOM_EAN_Do_Not_Use__c, Target_Address__r.ECOM_VAT_Number__c
                , Target_Address__r.ECOM_PU_Cust_E_Invoice__c, Target_Address__r.ECOM_Email_To_Invoice__c
                , ECOM_E_Invoice_Cust_Id__c, ECOM_EAN_Do_Not_Use__c, ECOM_VAT_Number__c, ECOM_PU_Cust_E_Invoice__c // Sathiya - ECOM-1933, ECOM-1942
                , ECOM_Email_To_Invoice__c // Sathiya - ECOM-3389
                , fxCustomerName_Target__c // RWPS-5048
                FROM ERP_Address__c 
                WHERE 
                ERP_Marked_for_Deletion__c = false AND
                Address_Type__c IN ('Payer', 'Ship To', 'Sold To', 'Bill To') AND
                (
                (ECOM_Review_Status__c IN ('New','In Progress') AND Contact__c = :contactId AND ECOM_isEnabled__c = true) OR
                (ECOM_Review_Status__c = 'Approved' AND Contact__c = null AND fxIsECOMenabled__c = true AND 
                 Master_Address__r.External_Id__c = :soldToSAPNumber AND 
                 (((fxFilterType__c like '1112%' OR fxFilterType__c like '1113%') 
                 AND Master_Address__r.Sub_Account_Group__c !='04')// RWPS-4900
                 OR (
                 (Master_Address__r.Sub_Account_Group__c ='04' AND Master_Address__r.Customer_Type__c IN ('ZW','ZX')
                 AND (fxFilterType__c like '1112%' OR fxFilterType__c like '1133%')))) // RWPS-4915
                 AND (
                 fxCustomerName_Target__c != 'FISHER SCIENTIFIC' AND fxCustomerName_Target__c != 'VWR' AND fxCustomerName_Target__c != 'Revvity' AND fxCustomerName_Target__c != 'Perkin' AND (NOT fxCustomerName_Target__c LIKE 'FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Target__c LIKE '% FISHER SCIENTIFIC')
                 AND (NOT fxCustomerName_Target__c LIKE '% FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Target__c LIKE 'VWR %') AND (NOT fxCustomerName_Target__c LIKE '% VWR') AND (NOT fxCustomerName_Target__c LIKE '% VWR %')
            	 AND (NOT fxCustomerName_Target__c LIKE 'Revvity %') AND (NOT fxCustomerName_Target__c LIKE '% Revvity') AND (NOT fxCustomerName_Target__c LIKE '% Revvity %')
                 AND (NOT fxCustomerName_Target__c LIKE 'Perkin %') AND (NOT fxCustomerName_Target__c LIKE '% Perkin') AND (NOT fxCustomerName_Target__c LIKE '% Perkin %')
                 )//RWPS-5048 added exclude FISHER SCIENTIFIC, VWR word condition //RWPS-5618 : added exclude Revvity, Perkin word condition
                 AND (
                 fxCustomerName_Master__c != 'FISHER SCIENTIFIC' AND fxCustomerName_Master__c != 'VWR' AND fxCustomerName_Master__c != 'Revvity' AND fxCustomerName_Master__c != 'Perkin' AND (NOT fxCustomerName_Master__c LIKE 'FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Master__c LIKE '% FISHER SCIENTIFIC')
                 AND (NOT fxCustomerName_Master__c LIKE '% FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Master__c LIKE 'VWR %') AND (NOT fxCustomerName_Master__c LIKE '% VWR') AND (NOT fxCustomerName_Master__c LIKE '% VWR %')
                 AND (NOT fxCustomerName_Master__c LIKE 'Revvity %') AND (NOT fxCustomerName_Master__c LIKE '% Revvity') AND (NOT fxCustomerName_Master__c LIKE '% Revvity %')
                 AND (NOT fxCustomerName_Master__c LIKE 'Perkin %') AND (NOT fxCustomerName_Master__c LIKE '% Perkin') AND (NOT fxCustomerName_Master__c LIKE '% Perkin %')
                )//RWPS-5048 //RWPS-5618 : added exclude Revvity, Perkin word condition
                 ))
                ];
        return erpAddresses;
    }
}

    //New Method Created by Vipul
    public static List<ERP_Address__c> fetchERPAddressesBySapNumber(String contactId, List<String> sapNumbers, List<String> addressTypes, String salesOrg){
        List<ERP_Address__c> erpAddresses = new List<ERP_Address__c>();
        //RWPS-6694 - added condition to check if the user is test user or not, if test user then show all the records irrespective of sales org and erp ids for testing purpose, else show records based on sales org and erp ids
         Boolean isTest = [
        SELECT ECOM_Is_Test_User__c
        FROM User
        WHERE Id = :UserInfo.getUserId()
        LIMIT 1
        ].ECOM_Is_Test_User__c;

        if (isTest) {

        erpAddresses = [SELECT Id, Account__c, Account__r.Name, Contact__c,ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, ERP_Account_Group__c, 
                Address_Type__c, ERP_Customer_Number__c, ERP_Sales_Org__c, MDM_Customer_Status__c, Address_Street_Line_1__c, 
                Address_Street_Line_2__c, Address_City__c, apiState__c, Address_Postal_Code__c, apiCountry__c, fxAddress_City__c,
                fxAddress_CountryCode__c, fxAddress_Postal__c, fxAddress_StateName__c, fxAddress_Street__c, fxAddressFull__c,External_Id__c, ERP_Account_Name__c, 
                ERP_Marked_for_Deletion__c, RecordType.Name, ERP_Partner_Code__c, Master_Address__c, Master_Address__r.External_Id__c, 
                Master_Address__r.Address_Street_Line_1__c, Master_Address__r.Address_Street_Line_2__c, Master_Address__r.Address_City__c,
                Master_Address__r.apiState__c, Master_Address__r.apiCountry__c, Master_Address__r.Address_Postal_Code__c,  Target_Address__c,
                Target_Address__r.External_Id__c,Target_Address__r.Address_Street_Line_1__c, Target_Address__r.Address_Street_Line_2__c, 
                Target_Address__r.Address_City__c, Target_Address__r.apiState__c, Target_Address__r.Address_Postal_Code__c, 
                Target_Address__r.apiCountry__c,SAP_Name_1__c, SAP_Name_2__c,SAP_Name_3__c,SAP_Name_4__c ,
                Target_Address__r.SAP_Name_1__c, Target_Address__r.SAP_Name_2__c,Target_Address__r.SAP_Name_3__c,Target_Address__r.SAP_Name_4__c,RAD_Identifier__c,
                ECOM_Punchout_Processors__c //GAr - added for punchout 
, Target_Address__r.ECOM_E_Invoice_Cust_Id__c, Target_Address__r.ECOM_EAN_Do_Not_Use__c, Target_Address__r.ECOM_VAT_Number__c
                , Target_Address__r.ECOM_PU_Cust_E_Invoice__c, Target_Address__r.ECOM_Email_To_Invoice__c
                , ECOM_E_Invoice_Cust_Id__c, ECOM_EAN_Do_Not_Use__c, ECOM_VAT_Number__c, ECOM_PU_Cust_E_Invoice__c // Sathiya - ECOM-1933, ECOM-1942
                , ECOM_Email_To_Invoice__c // Sathiya - ECOM-3389
                , fxCustomerName_Target__c // RWPS-5048
                FROM ERP_Address__c 
                WHERE 
                ERP_Marked_for_Deletion__c = false AND
                Address_Type__c IN :addressTypes AND
                (
                (ECOM_Review_Status__c IN ('New','In Progress') AND Contact__c = :contactId AND ECOM_isEnabled__c = true) OR
                (ECOM_Review_Status__c = 'Approved' AND Contact__c = null AND fxIsECOMenabled__c = true AND 
                 Master_Address__r.External_Id__c IN :sapNumbers AND ERP_Sales_Org__c=:salesOrg AND 
                 (((fxFilterType__c like '1112%' OR fxFilterType__c like '1113%') 
                 AND Master_Address__r.Sub_Account_Group__c !='04' )// RWPS-4900
                 OR ( (Master_Address__r.Sub_Account_Group__c ='04' AND Master_Address__r.Customer_Type__c IN ('ZW','ZX')
                 AND (fxFilterType__c like '1112%' OR fxFilterType__c like '1133%')))) // RWPS-4915
                  AND (
                 fxCustomerName_Target__c != 'FISHER SCIENTIFIC' AND fxCustomerName_Target__c != 'VWR' AND (NOT fxCustomerName_Target__c LIKE 'FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Target__c LIKE '% FISHER SCIENTIFIC')
                 AND (NOT fxCustomerName_Target__c LIKE '% FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Target__c LIKE 'VWR %') AND (NOT fxCustomerName_Target__c LIKE '% VWR') AND (NOT fxCustomerName_Target__c LIKE '% VWR %')
                )
                AND (
                 fxCustomerName_Master__c != 'FISHER SCIENTIFIC' AND fxCustomerName_Master__c != 'VWR' AND (NOT fxCustomerName_Master__c LIKE 'FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Master__c LIKE '% FISHER SCIENTIFIC')
                 AND (NOT fxCustomerName_Master__c LIKE '% FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Master__c LIKE 'VWR %') AND (NOT fxCustomerName_Master__c LIKE '% VWR') AND (NOT fxCustomerName_Master__c LIKE '% VWR %')
                )
                 ))
                ];
                System.debug(erpAddresses+'%');
        return erpAddresses;
    } else {
        erpAddresses = [SELECT Id, Account__c, Account__r.Name, Contact__c,ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, ERP_Account_Group__c, 
                Address_Type__c, ERP_Customer_Number__c, ERP_Sales_Org__c, MDM_Customer_Status__c, Address_Street_Line_1__c, 
                Address_Street_Line_2__c, Address_City__c, apiState__c, Address_Postal_Code__c, apiCountry__c, fxAddress_City__c,
                fxAddress_CountryCode__c, fxAddress_Postal__c, fxAddress_StateName__c, fxAddress_Street__c, fxAddressFull__c,External_Id__c, ERP_Account_Name__c, 
                ERP_Marked_for_Deletion__c, RecordType.Name, ERP_Partner_Code__c, Master_Address__c, Master_Address__r.External_Id__c, 
                Master_Address__r.Address_Street_Line_1__c, Master_Address__r.Address_Street_Line_2__c, Master_Address__r.Address_City__c,
                Master_Address__r.apiState__c, Master_Address__r.apiCountry__c, Master_Address__r.Address_Postal_Code__c,  Target_Address__c,
                Target_Address__r.External_Id__c,Target_Address__r.Address_Street_Line_1__c, Target_Address__r.Address_Street_Line_2__c, 
                Target_Address__r.Address_City__c, Target_Address__r.apiState__c, Target_Address__r.Address_Postal_Code__c, 
                Target_Address__r.apiCountry__c,SAP_Name_1__c, SAP_Name_2__c,SAP_Name_3__c,SAP_Name_4__c ,
                Target_Address__r.SAP_Name_1__c, Target_Address__r.SAP_Name_2__c,Target_Address__r.SAP_Name_3__c,Target_Address__r.SAP_Name_4__c,RAD_Identifier__c,
                ECOM_Punchout_Processors__c //GAr - added for punchout 
, Target_Address__r.ECOM_E_Invoice_Cust_Id__c, Target_Address__r.ECOM_EAN_Do_Not_Use__c, Target_Address__r.ECOM_VAT_Number__c
                , Target_Address__r.ECOM_PU_Cust_E_Invoice__c, Target_Address__r.ECOM_Email_To_Invoice__c
                , ECOM_E_Invoice_Cust_Id__c, ECOM_EAN_Do_Not_Use__c, ECOM_VAT_Number__c, ECOM_PU_Cust_E_Invoice__c // Sathiya - ECOM-1933, ECOM-1942
                , ECOM_Email_To_Invoice__c // Sathiya - ECOM-3389
                , fxCustomerName_Target__c // RWPS-5048
                FROM ERP_Address__c 
                WHERE 
                ERP_Marked_for_Deletion__c = false AND
                Address_Type__c IN :addressTypes AND
                (
                (ECOM_Review_Status__c IN ('New','In Progress') AND Contact__c = :contactId AND ECOM_isEnabled__c = true) OR
                (ECOM_Review_Status__c = 'Approved' AND Contact__c = null AND fxIsECOMenabled__c = true AND 
                 Master_Address__r.External_Id__c IN :sapNumbers AND ERP_Sales_Org__c=:salesOrg AND 
                 (((fxFilterType__c like '1112%' OR fxFilterType__c like '1113%') 
                 AND Master_Address__r.Sub_Account_Group__c !='04' )// RWPS-4900
                 OR ( (Master_Address__r.Sub_Account_Group__c ='04' AND Master_Address__r.Customer_Type__c IN ('ZW','ZX')
                 AND (fxFilterType__c like '1112%' OR fxFilterType__c like '1133%')))) // RWPS-4915
                 AND (
                	fxCustomerName_Target__c != 'FISHER SCIENTIFIC' AND fxCustomerName_Target__c != 'VWR' AND fxCustomerName_Target__c != 'Revvity' AND fxCustomerName_Target__c != 'Perkin'  AND (NOT fxCustomerName_Target__c LIKE 'FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Target__c LIKE '% FISHER SCIENTIFIC')
                	AND (NOT fxCustomerName_Target__c LIKE '% FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Target__c LIKE 'VWR %') AND (NOT fxCustomerName_Target__c LIKE '% VWR') AND (NOT fxCustomerName_Target__c LIKE '% VWR %')
                    AND (NOT fxCustomerName_Target__c LIKE 'Revvity %') AND (NOT fxCustomerName_Target__c LIKE '% Revvity') AND (NOT fxCustomerName_Target__c LIKE '% Revvity %')
                    AND (NOT fxCustomerName_Target__c LIKE 'Perkin %') AND (NOT fxCustomerName_Target__c LIKE '% Perkin') AND (NOT fxCustomerName_Target__c LIKE '% Perkin %')
                ) //RWPS-5048 added exclude FISHER SCIENTIFIC, VWR word condition //RWPS-5618 : added exclude Revvity, Perkin word condition
                AND (
                 fxCustomerName_Master__c != 'FISHER SCIENTIFIC' AND fxCustomerName_Master__c != 'VWR' AND fxCustomerName_Master__c != 'Revvity' AND fxCustomerName_Master__c != 'Perkin' AND (NOT fxCustomerName_Master__c LIKE 'FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Master__c LIKE '% FISHER SCIENTIFIC')
                 AND (NOT fxCustomerName_Master__c LIKE '% FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Master__c LIKE 'VWR %') AND (NOT fxCustomerName_Master__c LIKE '% VWR') AND (NOT fxCustomerName_Master__c LIKE '% VWR %')
                 AND (NOT fxCustomerName_Master__c LIKE 'Revvity %') AND (NOT fxCustomerName_Master__c LIKE '% Revvity') AND (NOT fxCustomerName_Master__c LIKE '% Revvity %')
                 AND (NOT fxCustomerName_Master__c LIKE 'Perkin %') AND (NOT fxCustomerName_Master__c LIKE '% Perkin') AND (NOT fxCustomerName_Master__c LIKE '% Perkin %')
                )//RWPS-5048 //RWPS-5618 : added exclude Revvity, Perkin word condition
                 )
                )  
                
                ];
                System.debug(erpAddresses+'%');
        return erpAddresses;
    }
}

    //New Method Created by Vipul
    // RWPS-4498
    public static List<ERP_Address__c> fetchERPAddressesBySapNumber(String contactId, List<String> sapNumbers, List<String> addressTypes, String salesOrg,String contactDomain, List<String> disabledAddresses){
         String start = contactDomain+',%';
        String mid = '%,'+contactDomain+',%';
        String endString ='%,'+contactDomain;
        
        List<ERP_Address__c> erpAddresses = new List<ERP_Address__c>();
        //RWPS-6694 - added condition to check if the user is test user or not, if test user then show all the records irrespective of sales org and erp ids for testing purpose, else show records based on sales org and erp ids
         Boolean isTest = [
        SELECT ECOM_Is_Test_User__c
        FROM User
        WHERE Id = :UserInfo.getUserId()
        LIMIT 1
        ].ECOM_Is_Test_User__c;

        if (isTest) {

        erpAddresses = [SELECT Id, Account__c, Account__r.Name, Contact__c,ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, ERP_Account_Group__c, 
                Address_Type__c, ERP_Customer_Number__c, ERP_Sales_Org__c, MDM_Customer_Status__c, Address_Street_Line_1__c, 
                Address_Street_Line_2__c, Address_City__c, apiState__c, Address_Postal_Code__c, apiCountry__c, fxAddress_City__c,
                fxAddress_CountryCode__c, fxAddress_Postal__c, fxAddress_StateName__c, fxAddress_Street__c, fxAddressFull__c,External_Id__c, ERP_Account_Name__c, 
                ERP_Marked_for_Deletion__c, RecordType.Name, ERP_Partner_Code__c, Master_Address__c, Master_Address__r.External_Id__c, 
                Master_Address__r.Address_Street_Line_1__c, Master_Address__r.Address_Street_Line_2__c, Master_Address__r.Address_City__c,
                Master_Address__r.apiState__c, Master_Address__r.apiCountry__c, Master_Address__r.Address_Postal_Code__c,  Target_Address__c,
                Target_Address__r.External_Id__c,Target_Address__r.Address_Street_Line_1__c, Target_Address__r.Address_Street_Line_2__c, 
                Target_Address__r.Address_City__c, Target_Address__r.apiState__c, Target_Address__r.Address_Postal_Code__c, 
                Target_Address__r.apiCountry__c,SAP_Name_1__c, SAP_Name_2__c,SAP_Name_3__c,SAP_Name_4__c,
                Target_Address__r.SAP_Name_1__c, Target_Address__r.SAP_Name_2__c,Target_Address__r.SAP_Name_3__c,Target_Address__r.SAP_Name_4__c,RAD_Identifier__c,
                ECOM_Punchout_Processors__c
, Target_Address__r.ECOM_E_Invoice_Cust_Id__c, Target_Address__r.ECOM_EAN_Do_Not_Use__c, Target_Address__r.ECOM_VAT_Number__c
                , Target_Address__r.ECOM_PU_Cust_E_Invoice__c, Target_Address__r.ECOM_Email_To_Invoice__c
                , ECOM_E_Invoice_Cust_Id__c, ECOM_EAN_Do_Not_Use__c, ECOM_VAT_Number__c, ECOM_PU_Cust_E_Invoice__c  // Sathiya - ECOM-1933, ECOM-1942
                , ECOM_Email_To_Invoice__c // Sathiya - ECOM-3389
                , fxCustomerName_Target__c // RWPS-5048
                FROM ERP_Address__c 
                WHERE 
                ERP_Marked_for_Deletion__c = false AND
                Address_Type__c IN :addressTypes AND
                Master_Address__c NOT IN :disabledAddresses AND // RWPS-4498
                (Account__r.Account_Domains__c = :contactDomain OR 
                Account__r.Account_Domains__c like :start OR
                Account__r.Account_Domains__c like :mid OR
                Account__r.Account_Domains__c like :endString)
                AND
                (
                (ECOM_Review_Status__c IN ('New','In Progress') AND Contact__c = :contactId AND ECOM_isEnabled__c = true) OR
                (ECOM_Review_Status__c = 'Approved' AND Contact__c = null AND fxIsECOMenabled__c = true AND 
                Master_Address__r.External_Id__c IN :sapNumbers AND ERP_Sales_Org__c=:salesOrg AND
                (((fxFilterType__c like '1112%' OR fxFilterType__c like '1113%')
                AND Master_Address__r.Sub_Account_Group__c !='04')
                OR ( (Master_Address__r.Sub_Account_Group__c ='04' AND Master_Address__r.Customer_Type__c IN ('ZW','ZX')
                AND (fxFilterType__c like '1112%' OR fxFilterType__c like '1133%')))) // RWPS-4915
                 AND (
                 fxCustomerName_Target__c != 'FISHER SCIENTIFIC' AND fxCustomerName_Target__c != 'VWR' AND (NOT fxCustomerName_Target__c LIKE 'FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Target__c LIKE '% FISHER SCIENTIFIC')
                 AND (NOT fxCustomerName_Target__c LIKE '% FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Target__c LIKE 'VWR %') AND (NOT fxCustomerName_Target__c LIKE '% VWR') AND (NOT fxCustomerName_Target__c LIKE '% VWR %')
                )
                AND (
                 fxCustomerName_Master__c != 'FISHER SCIENTIFIC' AND fxCustomerName_Master__c != 'VWR' AND (NOT fxCustomerName_Master__c LIKE 'FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Master__c LIKE '% FISHER SCIENTIFIC')
                 AND (NOT fxCustomerName_Master__c LIKE '% FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Master__c LIKE 'VWR %') AND (NOT fxCustomerName_Master__c LIKE '% VWR') AND (NOT fxCustomerName_Master__c LIKE '% VWR %')
                )
                 ))
                ];
        return erpAddresses;
    } else {
        erpAddresses = [SELECT Id, Account__c, Account__r.Name, Contact__c,ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, ERP_Account_Group__c, 
                Address_Type__c, ERP_Customer_Number__c, ERP_Sales_Org__c, MDM_Customer_Status__c, Address_Street_Line_1__c, 
                Address_Street_Line_2__c, Address_City__c, apiState__c, Address_Postal_Code__c, apiCountry__c, fxAddress_City__c,
                fxAddress_CountryCode__c, fxAddress_Postal__c, fxAddress_StateName__c, fxAddress_Street__c, fxAddressFull__c,External_Id__c, ERP_Account_Name__c, 
                ERP_Marked_for_Deletion__c, RecordType.Name, ERP_Partner_Code__c, Master_Address__c, Master_Address__r.External_Id__c, 
                Master_Address__r.Address_Street_Line_1__c, Master_Address__r.Address_Street_Line_2__c, Master_Address__r.Address_City__c,
                Master_Address__r.apiState__c, Master_Address__r.apiCountry__c, Master_Address__r.Address_Postal_Code__c,  Target_Address__c,
                Target_Address__r.External_Id__c,Target_Address__r.Address_Street_Line_1__c, Target_Address__r.Address_Street_Line_2__c, 
                Target_Address__r.Address_City__c, Target_Address__r.apiState__c, Target_Address__r.Address_Postal_Code__c, 
                Target_Address__r.apiCountry__c,SAP_Name_1__c, SAP_Name_2__c,SAP_Name_3__c,SAP_Name_4__c,
                Target_Address__r.SAP_Name_1__c, Target_Address__r.SAP_Name_2__c,Target_Address__r.SAP_Name_3__c,Target_Address__r.SAP_Name_4__c,RAD_Identifier__c,
                ECOM_Punchout_Processors__c
, Target_Address__r.ECOM_E_Invoice_Cust_Id__c, Target_Address__r.ECOM_EAN_Do_Not_Use__c, Target_Address__r.ECOM_VAT_Number__c
                , Target_Address__r.ECOM_PU_Cust_E_Invoice__c, Target_Address__r.ECOM_Email_To_Invoice__c
                , ECOM_E_Invoice_Cust_Id__c, ECOM_EAN_Do_Not_Use__c, ECOM_VAT_Number__c, ECOM_PU_Cust_E_Invoice__c  // Sathiya - ECOM-1933, ECOM-1942
                , ECOM_Email_To_Invoice__c // Sathiya - ECOM-3389
                , fxCustomerName_Target__c // RWPS-5048
                FROM ERP_Address__c 
                WHERE 
                ERP_Marked_for_Deletion__c = false AND
                Address_Type__c IN :addressTypes AND
                Master_Address__c NOT IN :disabledAddresses AND // RWPS-4498
                (Account__r.Account_Domains__c = :contactDomain OR 
                Account__r.Account_Domains__c like :start OR
                Account__r.Account_Domains__c like :mid OR
                Account__r.Account_Domains__c like :endString)
                AND
                (
                (ECOM_Review_Status__c IN ('New','In Progress') AND Contact__c = :contactId AND ECOM_isEnabled__c = true) OR
                (ECOM_Review_Status__c = 'Approved' AND Contact__c = null AND fxIsECOMenabled__c = true AND 
                Master_Address__r.External_Id__c IN :sapNumbers AND ERP_Sales_Org__c=:salesOrg AND
                (((fxFilterType__c like '1112%' OR fxFilterType__c like '1113%')
                AND Master_Address__r.Sub_Account_Group__c !='04')
                OR ( (Master_Address__r.Sub_Account_Group__c ='04' AND Master_Address__r.Customer_Type__c IN ('ZW','ZX')
                AND (fxFilterType__c like '1112%' OR fxFilterType__c like '1133%')))) // RWPS-4915
                AND (
                	fxCustomerName_Target__c != 'FISHER SCIENTIFIC' AND fxCustomerName_Target__c != 'VWR' AND fxCustomerName_Target__c != 'Revvity' AND fxCustomerName_Target__c != 'Perkin' AND (NOT fxCustomerName_Target__c LIKE 'FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Target__c LIKE '% FISHER SCIENTIFIC')
                	AND (NOT fxCustomerName_Target__c LIKE '% FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Target__c LIKE 'VWR %') AND (NOT fxCustomerName_Target__c LIKE '% VWR') AND (NOT fxCustomerName_Target__c LIKE '% VWR %')
            	    AND (NOT fxCustomerName_Target__c LIKE 'Revvity %') AND (NOT fxCustomerName_Target__c LIKE '% Revvity') AND (NOT fxCustomerName_Target__c LIKE '% Revvity %')
                    AND (NOT fxCustomerName_Target__c LIKE 'Perkin %') AND (NOT fxCustomerName_Target__c LIKE '% Perkin') AND (NOT fxCustomerName_Target__c LIKE '% Perkin %')
                )//RWPS-5048 added exclude FISHER SCIENTIFIC, VWR word condition //RWPS-5618 : added exclude Revvity, Perkin word condition
                AND (
                 fxCustomerName_Master__c != 'FISHER SCIENTIFIC' AND fxCustomerName_Master__c != 'VWR' AND fxCustomerName_Master__c != 'Revvity' AND fxCustomerName_Master__c != 'Perkin' AND (NOT fxCustomerName_Master__c LIKE 'FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Master__c LIKE '% FISHER SCIENTIFIC')
                 AND (NOT fxCustomerName_Master__c LIKE '% FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Master__c LIKE 'VWR %') AND (NOT fxCustomerName_Master__c LIKE '% VWR') AND (NOT fxCustomerName_Master__c LIKE '% VWR %')
                 AND (NOT fxCustomerName_Master__c LIKE 'Revvity %') AND (NOT fxCustomerName_Master__c LIKE '% Revvity') AND (NOT fxCustomerName_Master__c LIKE '% Revvity %')
                 AND (NOT fxCustomerName_Master__c LIKE 'Perkin %') AND (NOT fxCustomerName_Master__c LIKE '% Perkin') AND (NOT fxCustomerName_Master__c LIKE '% Perkin %')
                )//RWPS-5048 //RWPS-5618 : added exclude Revvity, Perkin word condition
                )
                )
                ];
        return erpAddresses;
    }
}

    //New Method Created by Vipul
    public static List<ERP_Address__c> fetchERPAddressesById(String erpId){
        List<ERP_Address__c> erpAddresses = new List<ERP_Address__c>();
        erpAddresses = [SELECT Id, Account__c, Account__r.Name, Contact__c,ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, ERP_Account_Group__c, 
                Address_Type__c, ERP_Customer_Number__c, ERP_Sales_Org__c, MDM_Customer_Status__c, Address_Street_Line_1__c, 
                Address_Street_Line_2__c, Address_City__c, apiState__c, Address_Postal_Code__c, apiCountry__c, fxAddress_City__c,
                fxAddress_CountryCode__c, fxAddress_Postal__c, fxAddress_StateName__c, fxAddress_Street__c, fxAddressFull__c,External_Id__c, ERP_Account_Name__c, 
                ERP_Marked_for_Deletion__c, RecordType.Name, ERP_Partner_Code__c, Master_Address__c, Master_Address__r.External_Id__c, 
                Master_Address__r.Address_Street_Line_1__c, Master_Address__r.Address_Street_Line_2__c, Master_Address__r.Address_City__c,
                Master_Address__r.apiState__c, Master_Address__r.apiCountry__c, Master_Address__r.Address_Postal_Code__c,  Target_Address__c,
                Target_Address__r.External_Id__c,Target_Address__r.Address_Street_Line_1__c, Target_Address__r.Address_Street_Line_2__c, 
                Target_Address__r.Address_City__c, Target_Address__r.apiState__c, Target_Address__r.Address_Postal_Code__c, 
                Target_Address__r.apiCountry__c,SAP_Name_1__c, SAP_Name_2__c,SAP_Name_3__c,SAP_Name_4__c,
                Target_Address__r.SAP_Name_1__c, Target_Address__r.SAP_Name_2__c,Target_Address__r.SAP_Name_3__c,Target_Address__r.SAP_Name_4__c,RAD_Identifier__c,
                ECOM_Punchout_Processors__c
, Target_Address__r.ECOM_E_Invoice_Cust_Id__c, Target_Address__r.ECOM_EAN_Do_Not_Use__c, Target_Address__r.ECOM_VAT_Number__c
                , Target_Address__r.ECOM_PU_Cust_E_Invoice__c, Target_Address__r.ECOM_Email_To_Invoice__c
                , ECOM_E_Invoice_Cust_Id__c, ECOM_EAN_Do_Not_Use__c, ECOM_VAT_Number__c, ECOM_PU_Cust_E_Invoice__c // Sathiya - ECOM-1933, ECOM-1942
                , ECOM_Email_To_Invoice__c // Sathiya - ECOM-3389
                FROM ERP_Address__c 
                WHERE 
                Id=:erpId
                ];
        return erpAddresses;
    }

    //New Method Created by Vipul
public static List<ERP_Address__c> fetchERPAddressesByMaster(List<String> masterIds,List<String> addressTypes,String contactId,String salesOrg){
        List<ERP_Address__c> erpAddresses = new List<ERP_Address__c>();
        //RWPS-6694 - added condition to check if the user is test user or not, if test user then show all the records irrespective of sales org and erp ids for testing purpose, else show records based on sales org and erp ids
         Boolean isTest = [
        SELECT ECOM_Is_Test_User__c
        FROM User
        WHERE Id = :UserInfo.getUserId()
        LIMIT 1
        ].ECOM_Is_Test_User__c;

        if (isTest) {

        erpAddresses = [SELECT Id, Account__c, Account__r.Name, Contact__c,ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, ERP_Account_Group__c, 
                Address_Type__c, ERP_Customer_Number__c, ERP_Sales_Org__c, MDM_Customer_Status__c, Address_Street_Line_1__c, 
                Address_Street_Line_2__c, Address_City__c, apiState__c, Address_Postal_Code__c, apiCountry__c, fxAddress_City__c,
                fxAddress_CountryCode__c, fxAddress_Postal__c, fxAddress_StateName__c, fxAddress_Street__c, fxAddressFull__c,External_Id__c, ERP_Account_Name__c, 
                ERP_Marked_for_Deletion__c, RecordType.Name, ERP_Partner_Code__c, Master_Address__c, Master_Address__r.External_Id__c, 
                Master_Address__r.Address_Street_Line_1__c, Master_Address__r.Address_Street_Line_2__c, Master_Address__r.Address_City__c,
                Master_Address__r.apiState__c, Master_Address__r.apiCountry__c, Master_Address__r.Address_Postal_Code__c,  Target_Address__c,
                Target_Address__r.External_Id__c,Target_Address__r.Address_Street_Line_1__c, Target_Address__r.Address_Street_Line_2__c, 
                Target_Address__r.Address_City__c, Target_Address__r.apiState__c, Target_Address__r.Address_Postal_Code__c, 
                Target_Address__r.apiCountry__c,SAP_Name_1__c, SAP_Name_2__c,SAP_Name_3__c,SAP_Name_4__c,
                Target_Address__r.SAP_Name_1__c, Target_Address__r.SAP_Name_2__c,Target_Address__r.SAP_Name_3__c,Target_Address__r.SAP_Name_4__c,RAD_Identifier__c, 
                ECOM_Punchout_Processors__c //GAr - added for punchout
                , Target_Address__r.ECOM_E_Invoice_Cust_Id__c, Target_Address__r.ECOM_EAN_Do_Not_Use__c, Target_Address__r.ECOM_VAT_Number__c
                , Target_Address__r.ECOM_PU_Cust_E_Invoice__c, Target_Address__r.ECOM_Email_To_Invoice__c
                , ECOM_E_Invoice_Cust_Id__c, ECOM_EAN_Do_Not_Use__c, ECOM_VAT_Number__c, ECOM_PU_Cust_E_Invoice__c // Sathiya - ECOM-1933, ECOM-1942
                , ECOM_Email_To_Invoice__c // Sathiya - ECOM-3389
                , fxCustomerName_Target__c // RWPS-5048
                FROM ERP_Address__c 
                WHERE 
                Master_Address__c IN :masterIds
                AND
                Address_Type__c IN :addressTypes
                AND
                (ECOM_isEnabled__c = true OR fxIsECOMenabled__c = true)
                AND
                (
                    (ECOM_Review_Status__c = 'APPROVED' AND ERP_Sales_Org__c=:salesOrg AND
                    (((fxFilterType__c like '1112%' OR fxFilterType__c like '1113%') // RWPS-4900
                    AND Master_Address__r.Sub_Account_Group__c !='04') // RWPS-4915
                    OR ( (Master_Address__r.Sub_Account_Group__c ='04' AND Master_Address__r.Customer_Type__c IN ('ZW','ZX'))))// RWPS-4915
                    AND (
                 fxCustomerName_Target__c != 'FISHER SCIENTIFIC' AND fxCustomerName_Target__c != 'VWR' AND (NOT fxCustomerName_Target__c LIKE 'FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Target__c LIKE '% FISHER SCIENTIFIC')
                 AND (NOT fxCustomerName_Target__c LIKE '% FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Target__c LIKE 'VWR %') AND (NOT fxCustomerName_Target__c LIKE '% VWR') AND (NOT fxCustomerName_Target__c LIKE '% VWR %')
                )
                AND (
                 fxCustomerName_Master__c != 'FISHER SCIENTIFIC' AND fxCustomerName_Master__c != 'VWR' AND (NOT fxCustomerName_Master__c LIKE 'FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Master__c LIKE '% FISHER SCIENTIFIC')
                 AND (NOT fxCustomerName_Master__c LIKE '% FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Master__c LIKE 'VWR %') AND (NOT fxCustomerName_Master__c LIKE '% VWR') AND (NOT fxCustomerName_Master__c LIKE '% VWR %')
                ))
                    OR
                    (
                        ECOM_Review_Status__c IN ('New','Pending')
                        AND
                        Contact__c = :contactId
                    )
                )  
                ];
        return erpAddresses;
    } else {
        erpAddresses = [SELECT Id, Account__c, Account__r.Name, Contact__c,ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, ERP_Account_Group__c, 
                Address_Type__c, ERP_Customer_Number__c, ERP_Sales_Org__c, MDM_Customer_Status__c, Address_Street_Line_1__c, 
                Address_Street_Line_2__c, Address_City__c, apiState__c, Address_Postal_Code__c, apiCountry__c, fxAddress_City__c,
                fxAddress_CountryCode__c, fxAddress_Postal__c, fxAddress_StateName__c, fxAddress_Street__c, fxAddressFull__c,External_Id__c, ERP_Account_Name__c, 
                ERP_Marked_for_Deletion__c, RecordType.Name, ERP_Partner_Code__c, Master_Address__c, Master_Address__r.External_Id__c, 
                Master_Address__r.Address_Street_Line_1__c, Master_Address__r.Address_Street_Line_2__c, Master_Address__r.Address_City__c,
                Master_Address__r.apiState__c, Master_Address__r.apiCountry__c, Master_Address__r.Address_Postal_Code__c,  Target_Address__c,
                Target_Address__r.External_Id__c,Target_Address__r.Address_Street_Line_1__c, Target_Address__r.Address_Street_Line_2__c, 
                Target_Address__r.Address_City__c, Target_Address__r.apiState__c, Target_Address__r.Address_Postal_Code__c, 
                Target_Address__r.apiCountry__c,SAP_Name_1__c, SAP_Name_2__c,SAP_Name_3__c,SAP_Name_4__c,
                Target_Address__r.SAP_Name_1__c, Target_Address__r.SAP_Name_2__c,Target_Address__r.SAP_Name_3__c,Target_Address__r.SAP_Name_4__c,RAD_Identifier__c, 
                ECOM_Punchout_Processors__c //GAr - added for punchout
                , Target_Address__r.ECOM_E_Invoice_Cust_Id__c, Target_Address__r.ECOM_EAN_Do_Not_Use__c, Target_Address__r.ECOM_VAT_Number__c
                , Target_Address__r.ECOM_PU_Cust_E_Invoice__c, Target_Address__r.ECOM_Email_To_Invoice__c
                , ECOM_E_Invoice_Cust_Id__c, ECOM_EAN_Do_Not_Use__c, ECOM_VAT_Number__c, ECOM_PU_Cust_E_Invoice__c // Sathiya - ECOM-1933, ECOM-1942
                , ECOM_Email_To_Invoice__c // Sathiya - ECOM-3389
                , fxCustomerName_Target__c // RWPS-5048
                FROM ERP_Address__c 
                WHERE 
                Master_Address__c IN :masterIds
                AND
                Address_Type__c IN :addressTypes
                AND
                (ECOM_isEnabled__c = true OR fxIsECOMenabled__c = true)
                AND
                (
                    (ECOM_Review_Status__c = 'APPROVED' AND ERP_Sales_Org__c=:salesOrg AND
                    (((fxFilterType__c like '1112%' OR fxFilterType__c like '1113%') // RWPS-4900
                    AND Master_Address__r.Sub_Account_Group__c !='04') // RWPS-4915
                    OR ( (Master_Address__r.Sub_Account_Group__c ='04' AND Master_Address__r.Customer_Type__c IN ('ZW','ZX'))))// RWPS-4915
                    AND (
                    fxCustomerName_Target__c != 'FISHER SCIENTIFIC' AND fxCustomerName_Target__c != 'VWR' AND fxCustomerName_Target__c != 'Revvity' AND fxCustomerName_Target__c != 'Perkin' AND (NOT fxCustomerName_Target__c LIKE 'FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Target__c LIKE '% FISHER SCIENTIFIC')
                    AND (NOT fxCustomerName_Target__c LIKE '% FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Target__c LIKE 'VWR %') AND (NOT fxCustomerName_Target__c LIKE '% VWR') AND (NOT fxCustomerName_Target__c LIKE '% VWR %')
            	    AND (NOT fxCustomerName_Target__c LIKE 'Revvity %') AND (NOT fxCustomerName_Target__c LIKE '% Revvity') AND (NOT fxCustomerName_Target__c LIKE '% Revvity %')
                    AND (NOT fxCustomerName_Target__c LIKE 'Perkin %') AND (NOT fxCustomerName_Target__c LIKE '% Perkin') AND (NOT fxCustomerName_Target__c LIKE '% Perkin %')
                    )//RWPS-5048 added exclude FISHER SCIENTIFIC condition //RWPS-5618 : added exclude Revvity, Perkin word condition
                    AND (
                    fxCustomerName_Master__c != 'FISHER SCIENTIFIC' AND fxCustomerName_Master__c != 'VWR' AND fxCustomerName_Master__c != 'Revvity' AND fxCustomerName_Master__c != 'Perkin' AND (NOT fxCustomerName_Master__c LIKE 'FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Master__c LIKE '% FISHER SCIENTIFIC')
                    AND (NOT fxCustomerName_Master__c LIKE '% FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Master__c LIKE 'VWR %') AND (NOT fxCustomerName_Master__c LIKE '% VWR') AND (NOT fxCustomerName_Master__c LIKE '% VWR %')
                    AND (NOT fxCustomerName_Master__c LIKE 'Revvity %') AND (NOT fxCustomerName_Master__c LIKE '% Revvity') AND (NOT fxCustomerName_Master__c LIKE '% Revvity %')
                    AND (NOT fxCustomerName_Master__c LIKE 'Perkin %') AND (NOT fxCustomerName_Master__c LIKE '% Perkin') AND (NOT fxCustomerName_Master__c LIKE '% Perkin %')
                    )//RWPS-5048 //RWPS-5618 : added exclude Revvity, Perkin word condition
                    )
                    OR
                    (
                        ECOM_Review_Status__c IN ('New','Pending')
                        AND
                        Contact__c = :contactId
                    )
                )  
                ];
        return erpAddresses;
    }
}
    public static List<ERP_Address__c> fetchERPAddressesByMaster(List<String> masterIds,List<String> addressTypes,String contactId,String salesOrg,List<String> disabledAddresses){
        List<ERP_Address__c> erpAddresses = new List<ERP_Address__c>();
        //RWPS-6694 - added condition to check if the user is test user or not, if test user then show all the records irrespective of sales org and erp ids for testing purpose, else show records based on sales org and erp ids
         Boolean isTest = [
        SELECT ECOM_Is_Test_User__c
        FROM User
        WHERE Id = :UserInfo.getUserId()
        LIMIT 1
        ].ECOM_Is_Test_User__c;

        if (isTest) {

        erpAddresses = [SELECT Id, Account__c, Account__r.Name, Contact__c,ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, ERP_Account_Group__c, 
                Address_Type__c, ERP_Customer_Number__c, ERP_Sales_Org__c, MDM_Customer_Status__c, Address_Street_Line_1__c, 
                Address_Street_Line_2__c, Address_City__c, apiState__c, Address_Postal_Code__c, apiCountry__c, fxAddress_City__c,
                fxAddress_CountryCode__c, fxAddress_Postal__c, fxAddress_StateName__c, fxAddress_Street__c, fxAddressFull__c,External_Id__c, ERP_Account_Name__c, 
                ERP_Marked_for_Deletion__c, RecordType.Name, ERP_Partner_Code__c, Master_Address__c, Master_Address__r.External_Id__c, 
                Master_Address__r.Address_Street_Line_1__c, Master_Address__r.Address_Street_Line_2__c, Master_Address__r.Address_City__c,
                Master_Address__r.apiState__c, Master_Address__r.apiCountry__c, Master_Address__r.Address_Postal_Code__c,  Target_Address__c,
                Target_Address__r.External_Id__c,Target_Address__r.Address_Street_Line_1__c, Target_Address__r.Address_Street_Line_2__c, 
                Target_Address__r.Address_City__c, Target_Address__r.apiState__c, Target_Address__r.Address_Postal_Code__c, 
                Target_Address__r.apiCountry__c,SAP_Name_1__c, SAP_Name_2__c,SAP_Name_3__c,SAP_Name_4__c,
                Target_Address__r.SAP_Name_1__c, Target_Address__r.SAP_Name_2__c,Target_Address__r.SAP_Name_3__c,Target_Address__r.SAP_Name_4__c,RAD_Identifier__c, 
                ECOM_Punchout_Processors__c //GAr - added for punchout 
, Target_Address__r.ECOM_E_Invoice_Cust_Id__c, Target_Address__r.ECOM_EAN_Do_Not_Use__c, Target_Address__r.ECOM_VAT_Number__c
                , Target_Address__r.ECOM_PU_Cust_E_Invoice__c, Target_Address__r.ECOM_Email_To_Invoice__c
                , ECOM_E_Invoice_Cust_Id__c, ECOM_EAN_Do_Not_Use__c, ECOM_VAT_Number__c, ECOM_PU_Cust_E_Invoice__c // Sathiya - ECOM-1933, ECOM-1942
                , ECOM_Email_To_Invoice__c // Sathiya - ECOM-3389
                , fxCustomerName_Target__c // RWPS-5048
                FROM ERP_Address__c 
                WHERE 
                Master_Address__c IN :masterIds
                AND
                Master_Address__c NOT IN :disabledAddresses
                AND
                Address_Type__c IN :addressTypes
                AND
                (ECOM_isEnabled__c = true OR fxIsECOMenabled__c = true)
                AND
                (
                    (ECOM_Review_Status__c = 'APPROVED' AND ERP_Sales_Org__c=:salesOrg AND
                    (((fxFilterType__c like '1112%' OR fxFilterType__c like '1113%') 
                    AND Master_Address__r.Sub_Account_Group__c !='04' ) // RWPS-4900
                    OR ( (Master_Address__r.Sub_Account_Group__c ='04' AND Master_Address__r.Customer_Type__c IN ('ZW','ZX'))))// RWPS-4915    
                    AND (
                 fxCustomerName_Target__c != 'FISHER SCIENTIFIC' AND fxCustomerName_Target__c != 'VWR' AND (NOT fxCustomerName_Target__c LIKE 'FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Target__c LIKE '% FISHER SCIENTIFIC')
                 AND (NOT fxCustomerName_Target__c LIKE '% FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Target__c LIKE 'VWR %') AND (NOT fxCustomerName_Target__c LIKE '% VWR') AND (NOT fxCustomerName_Target__c LIKE '% VWR %')
                )
                AND (
                 fxCustomerName_Master__c != 'FISHER SCIENTIFIC' AND fxCustomerName_Master__c != 'VWR' AND (NOT fxCustomerName_Master__c LIKE 'FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Master__c LIKE '% FISHER SCIENTIFIC')
                 AND (NOT fxCustomerName_Master__c LIKE '% FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Master__c LIKE 'VWR %') AND (NOT fxCustomerName_Master__c LIKE '% VWR') AND (NOT fxCustomerName_Master__c LIKE '% VWR %')
                 ))

                    OR
                    (
                        ECOM_Review_Status__c IN ('New','Pending')
                        AND
                        Contact__c = :contactId
                    )
                )
                ];
        return erpAddresses;
    } else {
        erpAddresses = [SELECT Id, Account__c, Account__r.Name, Contact__c,ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, ERP_Account_Group__c, 
                Address_Type__c, ERP_Customer_Number__c, ERP_Sales_Org__c, MDM_Customer_Status__c, Address_Street_Line_1__c, 
                Address_Street_Line_2__c, Address_City__c, apiState__c, Address_Postal_Code__c, apiCountry__c, fxAddress_City__c,
                fxAddress_CountryCode__c, fxAddress_Postal__c, fxAddress_StateName__c, fxAddress_Street__c, fxAddressFull__c,External_Id__c, ERP_Account_Name__c, 
                ERP_Marked_for_Deletion__c, RecordType.Name, ERP_Partner_Code__c, Master_Address__c, Master_Address__r.External_Id__c, 
                Master_Address__r.Address_Street_Line_1__c, Master_Address__r.Address_Street_Line_2__c, Master_Address__r.Address_City__c,
                Master_Address__r.apiState__c, Master_Address__r.apiCountry__c, Master_Address__r.Address_Postal_Code__c,  Target_Address__c,
                Target_Address__r.External_Id__c,Target_Address__r.Address_Street_Line_1__c, Target_Address__r.Address_Street_Line_2__c, 
                Target_Address__r.Address_City__c, Target_Address__r.apiState__c, Target_Address__r.Address_Postal_Code__c, 
                Target_Address__r.apiCountry__c,SAP_Name_1__c, SAP_Name_2__c,SAP_Name_3__c,SAP_Name_4__c,
                Target_Address__r.SAP_Name_1__c, Target_Address__r.SAP_Name_2__c,Target_Address__r.SAP_Name_3__c,Target_Address__r.SAP_Name_4__c,RAD_Identifier__c, 
                ECOM_Punchout_Processors__c //GAr - added for punchout 
, Target_Address__r.ECOM_E_Invoice_Cust_Id__c, Target_Address__r.ECOM_EAN_Do_Not_Use__c, Target_Address__r.ECOM_VAT_Number__c
                , Target_Address__r.ECOM_PU_Cust_E_Invoice__c, Target_Address__r.ECOM_Email_To_Invoice__c
                , ECOM_E_Invoice_Cust_Id__c, ECOM_EAN_Do_Not_Use__c, ECOM_VAT_Number__c, ECOM_PU_Cust_E_Invoice__c // Sathiya - ECOM-1933, ECOM-1942
                , ECOM_Email_To_Invoice__c // Sathiya - ECOM-3389
                , fxCustomerName_Target__c // RWPS-5048
                FROM ERP_Address__c 
                WHERE 
                Master_Address__c IN :masterIds
                AND
                Master_Address__c NOT IN :disabledAddresses
                AND
                Address_Type__c IN :addressTypes
                AND
                (ECOM_isEnabled__c = true OR fxIsECOMenabled__c = true)
                AND
                (
                    (ECOM_Review_Status__c = 'APPROVED' AND ERP_Sales_Org__c=:salesOrg AND
                    (((fxFilterType__c like '1112%' OR fxFilterType__c like '1113%') 
                    AND Master_Address__r.Sub_Account_Group__c !='04' ) // RWPS-4900
                    OR ( (Master_Address__r.Sub_Account_Group__c ='04' AND Master_Address__r.Customer_Type__c IN ('ZW','ZX'))))// RWPS-4915    
                    AND (
                    fxCustomerName_Target__c != 'FISHER SCIENTIFIC' AND fxCustomerName_Target__c != 'VWR' AND fxCustomerName_Target__c != 'Revvity' AND fxCustomerName_Target__c != 'Perkin' AND (NOT fxCustomerName_Target__c LIKE 'FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Target__c LIKE '% FISHER SCIENTIFIC')
                    AND (NOT fxCustomerName_Target__c LIKE '% FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Target__c LIKE 'VWR %') AND (NOT fxCustomerName_Target__c LIKE '% VWR') AND (NOT fxCustomerName_Target__c LIKE '% VWR %')
                    AND (NOT fxCustomerName_Target__c LIKE 'Revvity %') AND (NOT fxCustomerName_Target__c LIKE '% Revvity') AND (NOT fxCustomerName_Target__c LIKE '% Revvity %')
                    AND (NOT fxCustomerName_Target__c LIKE 'Perkin %') AND (NOT fxCustomerName_Target__c LIKE '% Perkin') AND (NOT fxCustomerName_Target__c LIKE '% Perkin %')
                    )//RWPS-5048 added exclude FISHER SCIENTIFIC condition //RWPS-5618 : added exclude Revvity, Perkin word condition
                    AND (
                    fxCustomerName_Master__c != 'FISHER SCIENTIFIC' AND fxCustomerName_Master__c != 'VWR' AND fxCustomerName_Master__c != 'Revvity' AND fxCustomerName_Master__c != 'Perkin' AND (NOT fxCustomerName_Master__c LIKE 'FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Master__c LIKE '% FISHER SCIENTIFIC')
                    AND (NOT fxCustomerName_Master__c LIKE '% FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Master__c LIKE 'VWR %') AND (NOT fxCustomerName_Master__c LIKE '% VWR') AND (NOT fxCustomerName_Master__c LIKE '% VWR %')
                    AND (NOT fxCustomerName_Master__c LIKE 'Revvity %') AND (NOT fxCustomerName_Master__c LIKE '% Revvity') AND (NOT fxCustomerName_Master__c LIKE '% Revvity %')
                    AND (NOT fxCustomerName_Master__c LIKE 'Perkin %') AND (NOT fxCustomerName_Master__c LIKE '% Perkin') AND (NOT fxCustomerName_Master__c LIKE '% Perkin %')
                    )//RWPS-5048 //RWPS-5618 : added exclude Revvity, Perkin word condition
                    )
                    OR
                    (
                        ECOM_Review_Status__c IN ('New','Pending')
                        AND
                        Contact__c = :contactId
                    )
                )
                ];
        return erpAddresses;
    }
}

    public static List<ERP_Address__c> fetchERPAddressesByIds(List<String> erpIds,String contactId){
        List<ERP_Address__c> erpAddresses = new List<ERP_Address__c>();
        erpAddresses = [SELECT Id, Account__c, Account__r.Name, Contact__c,ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, ERP_Account_Group__c, 
                Address_Type__c, ERP_Customer_Number__c, ERP_Sales_Org__c, MDM_Customer_Status__c, Address_Street_Line_1__c, 
                Address_Street_Line_2__c, Address_City__c, apiState__c, Address_Postal_Code__c, apiCountry__c, fxAddress_City__c,
                fxAddress_CountryCode__c, fxAddress_Postal__c, fxAddress_StateName__c, fxAddress_Street__c, fxAddressFull__c,External_Id__c, ERP_Account_Name__c, 
                ERP_Marked_for_Deletion__c, RecordType.Name, ERP_Partner_Code__c, Master_Address__c, Master_Address__r.External_Id__c, 
                Master_Address__r.Address_Street_Line_1__c, Master_Address__r.Address_Street_Line_2__c, Master_Address__r.Address_City__c,
                Master_Address__r.apiState__c, Master_Address__r.apiCountry__c, Master_Address__r.Address_Postal_Code__c,  Target_Address__c,
                Target_Address__r.External_Id__c,Target_Address__r.Address_Street_Line_1__c, Target_Address__r.Address_Street_Line_2__c, 
                Target_Address__r.Address_City__c, Target_Address__r.apiState__c, Target_Address__r.Address_Postal_Code__c, 
                Target_Address__r.apiCountry__c,SAP_Name_1__c, SAP_Name_2__c,SAP_Name_3__c,SAP_Name_4__c,
                Target_Address__r.SAP_Name_1__c, Target_Address__r.SAP_Name_2__c,Target_Address__r.SAP_Name_3__c,Target_Address__r.SAP_Name_4__c,RAD_Identifier__c,
                ECOM_Punchout_Processors__c //GAr - added for punchout
, Target_Address__r.ECOM_E_Invoice_Cust_Id__c, Target_Address__r.ECOM_EAN_Do_Not_Use__c, Target_Address__r.ECOM_VAT_Number__c
                , Target_Address__r.ECOM_PU_Cust_E_Invoice__c, Target_Address__r.ECOM_Email_To_Invoice__c
                , ECOM_E_Invoice_Cust_Id__c, ECOM_EAN_Do_Not_Use__c, ECOM_VAT_Number__c, ECOM_PU_Cust_E_Invoice__c // Sathiya - ECOM-1933, ECOM-1942
                , ECOM_Email_To_Invoice__c // Sathiya - ECOM-3389
                FROM ERP_Address__c 
                WHERE 
                Id IN :erpIds
                OR
                (ECOM_Review_Status__c IN ('New','In Progress') AND Contact__c=:contactId)
                ];
        return erpAddresses;
    }
    
     
    public static List<ERP_Address__c> fetchERPAddressesByDomain(String contactDomain, String salesOrg){
        
        String start = contactDomain+',%';
        String mid = '%,'+contactDomain+',%';
        String endString ='%,'+contactDomain;
        List<ERP_Address__c> erpAddresses = new List<ERP_Address__c>();
        //RWPS-6694 - added condition to check if the user is test user or not, if test user then show all the records irrespective of sales org and erp ids for testing purpose, else show records based on sales org and erp ids
         Boolean isTest = [
        SELECT ECOM_Is_Test_User__c
        FROM User
        WHERE Id = :UserInfo.getUserId()
        LIMIT 1
        ].ECOM_Is_Test_User__c;

        if (isTest) {
        
        erpAddresses = [SELECT Id, Account__c, Account__r.Name, Contact__c,ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, ERP_Account_Group__c, 
                Address_Type__c, ERP_Customer_Number__c, ERP_Sales_Org__c, MDM_Customer_Status__c, Address_Street_Line_1__c, 
                Address_Street_Line_2__c, Address_City__c, apiState__c, Address_Postal_Code__c, apiCountry__c, fxAddress_City__c,
                fxAddress_CountryCode__c, fxAddress_Postal__c, fxAddress_StateName__c, fxAddress_Street__c, fxAddressFull__c,External_Id__c, ERP_Account_Name__c, 
                ERP_Marked_for_Deletion__c, RecordType.Name, ERP_Partner_Code__c, Master_Address__c, Master_Address__r.External_Id__c, 
                Master_Address__r.Address_Street_Line_1__c, Master_Address__r.Address_Street_Line_2__c, Master_Address__r.Address_City__c,
                Master_Address__r.apiState__c, Master_Address__r.apiCountry__c, Master_Address__r.Address_Postal_Code__c,  Target_Address__c,
                Target_Address__r.External_Id__c,Target_Address__r.Address_Street_Line_1__c, Target_Address__r.Address_Street_Line_2__c, 
                Target_Address__r.Address_City__c, Target_Address__r.apiState__c, Target_Address__r.Address_Postal_Code__c, 
                Target_Address__r.apiCountry__c,SAP_Name_1__c, SAP_Name_2__c,SAP_Name_3__c,SAP_Name_4__c,
                Target_Address__r.SAP_Name_1__c, Target_Address__r.SAP_Name_2__c,Target_Address__r.SAP_Name_3__c,Target_Address__r.SAP_Name_4__c, RAD_Identifier__c, 
                ECOM_Punchout_Processors__c //GAr - added for punchout 
, Target_Address__r.ECOM_E_Invoice_Cust_Id__c, Target_Address__r.ECOM_EAN_Do_Not_Use__c, Target_Address__r.ECOM_VAT_Number__c
                , Target_Address__r.ECOM_PU_Cust_E_Invoice__c, Target_Address__r.ECOM_Email_To_Invoice__c
                , ECOM_E_Invoice_Cust_Id__c, ECOM_EAN_Do_Not_Use__c, ECOM_VAT_Number__c, ECOM_PU_Cust_E_Invoice__c // Sathiya - ECOM-1933, ECOM-1942
                , ECOM_Email_To_Invoice__c // Sathiya - ECOM-3389
                FROM ERP_Address__c 
                WHERE 
                fxIsECOMenabled__c = true AND 
                ERP_Marked_for_Deletion__c = false AND
                fxFilterType__c like '1112%' AND // RWPS-4900
                Address_Type__c IN ('Sold To') 
                //RWPS-5048
                AND (
                 fxCustomerName_Target__c != 'FISHER SCIENTIFIC' AND fxCustomerName_Target__c != 'VWR' AND (NOT fxCustomerName_Target__c LIKE 'FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Target__c LIKE '% FISHER SCIENTIFIC')
                 AND (NOT fxCustomerName_Target__c LIKE '% FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Target__c LIKE 'VWR %') AND (NOT fxCustomerName_Target__c LIKE '% VWR') AND (NOT fxCustomerName_Target__c LIKE '% VWR %')
                )
                AND (
                 fxCustomerName_Master__c != 'FISHER SCIENTIFIC' AND fxCustomerName_Master__c != 'VWR' AND (NOT fxCustomerName_Master__c LIKE 'FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Master__c LIKE '% FISHER SCIENTIFIC')
                 AND (NOT fxCustomerName_Master__c LIKE '% FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Master__c LIKE 'VWR %') AND (NOT fxCustomerName_Master__c LIKE '% VWR') AND (NOT fxCustomerName_Master__c LIKE '% VWR %')
                )
				AND
                ERP_Sales_Org__c = :salesOrg AND
                (Account__r.Account_Domains__c = :contactDomain OR 
                Account__r.Account_Domains__c like :start OR
                Account__r.Account_Domains__c like :mid OR
                Account__r.Account_Domains__c like :endString)
                ORDER BY ERP_Transaction_count__c DESC LIMIT 5];
        return erpAddresses;
    } else {
        erpAddresses = [SELECT Id, Account__c, Account__r.Name, Contact__c,ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, ERP_Account_Group__c, 
                Address_Type__c, ERP_Customer_Number__c, ERP_Sales_Org__c, MDM_Customer_Status__c, Address_Street_Line_1__c, 
                Address_Street_Line_2__c, Address_City__c, apiState__c, Address_Postal_Code__c, apiCountry__c, fxAddress_City__c,
                fxAddress_CountryCode__c, fxAddress_Postal__c, fxAddress_StateName__c, fxAddress_Street__c, fxAddressFull__c,External_Id__c, ERP_Account_Name__c, 
                ERP_Marked_for_Deletion__c, RecordType.Name, ERP_Partner_Code__c, Master_Address__c, Master_Address__r.External_Id__c, 
                Master_Address__r.Address_Street_Line_1__c, Master_Address__r.Address_Street_Line_2__c, Master_Address__r.Address_City__c,
                Master_Address__r.apiState__c, Master_Address__r.apiCountry__c, Master_Address__r.Address_Postal_Code__c,  Target_Address__c,
                Target_Address__r.External_Id__c,Target_Address__r.Address_Street_Line_1__c, Target_Address__r.Address_Street_Line_2__c, 
                Target_Address__r.Address_City__c, Target_Address__r.apiState__c, Target_Address__r.Address_Postal_Code__c, 
                Target_Address__r.apiCountry__c,SAP_Name_1__c, SAP_Name_2__c,SAP_Name_3__c,SAP_Name_4__c,
                Target_Address__r.SAP_Name_1__c, Target_Address__r.SAP_Name_2__c,Target_Address__r.SAP_Name_3__c,Target_Address__r.SAP_Name_4__c, RAD_Identifier__c, 
                ECOM_Punchout_Processors__c //GAr - added for punchout 
, Target_Address__r.ECOM_E_Invoice_Cust_Id__c, Target_Address__r.ECOM_EAN_Do_Not_Use__c, Target_Address__r.ECOM_VAT_Number__c
                , Target_Address__r.ECOM_PU_Cust_E_Invoice__c, Target_Address__r.ECOM_Email_To_Invoice__c
                , ECOM_E_Invoice_Cust_Id__c, ECOM_EAN_Do_Not_Use__c, ECOM_VAT_Number__c, ECOM_PU_Cust_E_Invoice__c // Sathiya - ECOM-1933, ECOM-1942
                , ECOM_Email_To_Invoice__c // Sathiya - ECOM-3389
                FROM ERP_Address__c 
                WHERE 
                fxIsECOMenabled__c = true AND 
                ERP_Marked_for_Deletion__c = false AND
                fxFilterType__c like '1112%' AND // RWPS-4900
                Address_Type__c IN ('Sold To') AND 
                //RWPS-5048
                (
                 fxCustomerName_Target__c != 'FISHER SCIENTIFIC' AND fxCustomerName_Target__c != 'VWR' AND fxCustomerName_Target__c != 'Revvity' AND fxCustomerName_Target__c != 'Perkin' AND (NOT fxCustomerName_Target__c LIKE 'FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Target__c LIKE '% FISHER SCIENTIFIC')
                 AND (NOT fxCustomerName_Target__c LIKE '% FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Target__c LIKE 'VWR %') AND (NOT fxCustomerName_Target__c LIKE '% VWR') AND (NOT fxCustomerName_Target__c LIKE '% VWR %')
                 AND (NOT fxCustomerName_Target__c LIKE 'Revvity %') AND (NOT fxCustomerName_Target__c LIKE '% Revvity') AND (NOT fxCustomerName_Target__c LIKE '% Revvity %')
                 AND (NOT fxCustomerName_Target__c LIKE 'Perkin %') AND (NOT fxCustomerName_Target__c LIKE '% Perkin') AND (NOT fxCustomerName_Target__c LIKE '% Perkin %')
                ) //RWPS-5618 : added exclude Revvity, Perkin word condition
                AND (
                 fxCustomerName_Master__c != 'FISHER SCIENTIFIC' AND fxCustomerName_Master__c != 'VWR' AND fxCustomerName_Master__c != 'Revvity' AND fxCustomerName_Master__c != 'Perkin' AND (NOT fxCustomerName_Master__c LIKE 'FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Master__c LIKE '% FISHER SCIENTIFIC')
                 AND (NOT fxCustomerName_Master__c LIKE '% FISHER SCIENTIFIC %') AND (NOT fxCustomerName_Master__c LIKE 'VWR %') AND (NOT fxCustomerName_Master__c LIKE '% VWR') AND (NOT fxCustomerName_Master__c LIKE '% VWR %')
                 AND (NOT fxCustomerName_Master__c LIKE 'Revvity %') AND (NOT fxCustomerName_Master__c LIKE '% Revvity') AND (NOT fxCustomerName_Master__c LIKE '% Revvity %')
                 AND (NOT fxCustomerName_Master__c LIKE 'Perkin %') AND (NOT fxCustomerName_Master__c LIKE '% Perkin') AND (NOT fxCustomerName_Master__c LIKE '% Perkin %')
                ) //RWPS-5618 : added exclude Revvity, Perkin word condition  
				AND
                ERP_Sales_Org__c = :salesOrg AND
                (Account__r.Account_Domains__c = :contactDomain OR 
                Account__r.Account_Domains__c like :start OR
                Account__r.Account_Domains__c like :mid OR
                Account__r.Account_Domains__c like :endString)
                ORDER BY ERP_Transaction_count__c DESC LIMIT 5];
        return erpAddresses;
    }
}
    
    public static Map<Id,ERP_Address__c> getTargetId(Set<String> erpIds){
        Map<Id, ERP_Address__c> erpMap = new Map<Id, ERP_Address__c>([SELECT Id, Account__c, Account__r.Name, Contact__c,ECOM_isEnabled__c,
                                                                      fxIsECOMenabled__c, ECOM_Review_Status__c, ERP_Account_Group__c, 
                Address_Type__c, ERP_Customer_Number__c, ERP_Sales_Org__c, MDM_Customer_Status__c, Address_Street_Line_1__c, 
                Address_Street_Line_2__c, Address_City__c, apiState__c, Address_Postal_Code__c, apiCountry__c, fxAddress_City__c,
                fxAddress_CountryCode__c, fxAddress_Postal__c, fxAddress_StateName__c, fxAddress_Street__c, fxAddressFull__c,External_Id__c, ERP_Account_Name__c, 
                ERP_Marked_for_Deletion__c, RecordType.Name, ERP_Partner_Code__c, Master_Address__c, Master_Address__r.External_Id__c, 
                Master_Address__r.Address_Street_Line_1__c, Master_Address__r.Address_Street_Line_2__c, Master_Address__r.Address_City__c,
                Master_Address__r.apiState__c, Master_Address__r.apiCountry__c, Master_Address__r.Address_Postal_Code__c,  Target_Address__c,
                Target_Address__r.External_Id__c,Target_Address__r.Address_Street_Line_1__c, Target_Address__r.Address_Street_Line_2__c, 
                Target_Address__r.Address_City__c, Target_Address__r.apiState__c, Target_Address__r.Address_Postal_Code__c, 
                Target_Address__r.apiCountry__c,SAP_Name_1__c, SAP_Name_2__c,SAP_Name_3__c,SAP_Name_4__c,
                Target_Address__r.SAP_Name_1__c, Target_Address__r.SAP_Name_2__c,Target_Address__r.SAP_Name_3__c,Target_Address__r.SAP_Name_4__c,RAD_Identifier__c, 
                ECOM_Punchout_Processors__c //GAr - added for punchout 
, Target_Address__r.ECOM_E_Invoice_Cust_Id__c, Target_Address__r.ECOM_EAN_Do_Not_Use__c, Target_Address__r.ECOM_VAT_Number__c
                , Target_Address__r.ECOM_PU_Cust_E_Invoice__c, Target_Address__r.ECOM_Email_To_Invoice__c
                , ECOM_E_Invoice_Cust_Id__c, ECOM_EAN_Do_Not_Use__c, ECOM_VAT_Number__c, ECOM_PU_Cust_E_Invoice__c // Sathiya - ECOM-1933, ECOM-1942
                , ECOM_Email_To_Invoice__c // Sathiya - ECOM-3389
                FROM ERP_Address__c 
                WHERE ID IN :erpIds]);
        return erpMap;
        
    }

    // fetch new ERP Addresse created by the user 
    public static List<ERP_Address__c> fetchNewERPAddressesByContactId(String contactId){
        List<ERP_Address__c> erpAddresses = new List<ERP_Address__c>();
        erpAddresses = [SELECT Id, Account__c, Account__r.Name, Contact__c,ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, ERP_Account_Group__c, 
                Address_Type__c, ERP_Customer_Number__c, ERP_Sales_Org__c, MDM_Customer_Status__c, Address_Street_Line_1__c, 
                Address_Street_Line_2__c, Address_City__c, apiState__c, Address_Postal_Code__c, apiCountry__c, fxAddress_City__c,
                fxAddress_CountryCode__c, fxAddress_Postal__c, fxAddress_StateName__c, fxAddress_Street__c,External_Id__c, fxAddressFull__c, ERP_Account_Name__c, 
                ERP_Marked_for_Deletion__c, RecordType.Name, ERP_Partner_Code__c, Master_Address__c, Master_Address__r.External_Id__c, 
                Master_Address__r.Address_Street_Line_1__c, Master_Address__r.Address_Street_Line_2__c, Master_Address__r.Address_City__c,
                Master_Address__r.apiState__c, Master_Address__r.apiCountry__c, Master_Address__r.Address_Postal_Code__c,  Target_Address__c,
                Target_Address__r.External_Id__c,Target_Address__r.Address_Street_Line_1__c, Target_Address__r.Address_Street_Line_2__c, 
                Target_Address__r.Address_City__c, Target_Address__r.apiState__c, Target_Address__r.Address_Postal_Code__c, 
                Target_Address__r.apiCountry__c,SAP_Name_1__c, SAP_Name_2__c,SAP_Name_3__c,SAP_Name_4__c,
                Target_Address__r.SAP_Name_1__c, Target_Address__r.SAP_Name_2__c,Target_Address__r.SAP_Name_3__c,Target_Address__r.SAP_Name_4__c, RAD_Identifier__c, 
                ECOM_Punchout_Processors__c //GAr - added for punchout 
, Target_Address__r.ECOM_E_Invoice_Cust_Id__c, Target_Address__r.ECOM_EAN_Do_Not_Use__c, Target_Address__r.ECOM_VAT_Number__c
                , Target_Address__r.ECOM_PU_Cust_E_Invoice__c, Target_Address__r.ECOM_Email_To_Invoice__c
                , ECOM_E_Invoice_Cust_Id__c, ECOM_EAN_Do_Not_Use__c, ECOM_VAT_Number__c, ECOM_PU_Cust_E_Invoice__c // Sathiya - ECOM-1933, ECOM-1942
                , ECOM_Email_To_Invoice__c // Sathiya - ECOM-3389
                FROM ERP_Address__c 
                WHERE 
                Contact__c = :contactId AND 
                ECOM_Review_Status__c IN ('New','In Progress')];
        return erpAddresses;
    }


    public static List<ERP_Address__c> fetchErpAddressesByMasterId(String contactId,List<String> addressTypes,String masterId){
        List<ERP_Address__c> erpAddresses = new List<ERP_Address__c>();
        erpAddresses = [SELECT Id, Account__c, Account__r.Name, Contact__c,ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, ERP_Account_Group__c, 
                Address_Type__c, ERP_Customer_Number__c, ERP_Sales_Org__c, MDM_Customer_Status__c, Address_Street_Line_1__c, 
                Address_Street_Line_2__c, Address_City__c, apiState__c, Address_Postal_Code__c, apiCountry__c, fxAddress_City__c,
                fxAddress_CountryCode__c, fxAddress_Postal__c, fxAddress_StateName__c, fxAddress_Street__c,External_Id__c, fxAddressFull__c, ERP_Account_Name__c, 
                ERP_Marked_for_Deletion__c, RecordType.Name, ERP_Partner_Code__c, Master_Address__c, Master_Address__r.External_Id__c, 
                Master_Address__r.Address_Street_Line_1__c, Master_Address__r.Address_Street_Line_2__c, Master_Address__r.Address_City__c,
                Master_Address__r.apiState__c, Master_Address__r.apiCountry__c, Master_Address__r.Address_Postal_Code__c,  Target_Address__c,
                Target_Address__r.External_Id__c,Target_Address__r.Address_Street_Line_1__c, Target_Address__r.Address_Street_Line_2__c, 
                Target_Address__r.Address_City__c, Target_Address__r.apiState__c, Target_Address__r.Address_Postal_Code__c, 
                Target_Address__r.apiCountry__c,SAP_Name_1__c, SAP_Name_2__c,SAP_Name_3__c,SAP_Name_4__c,
                Target_Address__r.SAP_Name_1__c, Target_Address__r.SAP_Name_2__c,Target_Address__r.SAP_Name_3__c,Target_Address__r.SAP_Name_4__c, RAD_Identifier__c, 
                ECOM_Punchout_Processors__c //GAr - added for punchout 
, Target_Address__r.ECOM_E_Invoice_Cust_Id__c, Target_Address__r.ECOM_EAN_Do_Not_Use__c, Target_Address__r.ECOM_VAT_Number__c
                , Target_Address__r.ECOM_PU_Cust_E_Invoice__c, Target_Address__r.ECOM_Email_To_Invoice__c
                , ECOM_E_Invoice_Cust_Id__c, ECOM_EAN_Do_Not_Use__c, ECOM_VAT_Number__c, ECOM_PU_Cust_E_Invoice__c // Sathiya - ECOM-1933, ECOM-1942
                , ECOM_Email_To_Invoice__c // Sathiya - ECOM-3389
                FROM ERP_Address__c 
                WHERE 
                Contact__c = :contactId AND 
                ECOM_Review_Status__c IN ('New','In Progress')
                AND Address_Type__c IN :addressTypes
                AND Master_Address__c=:masterId
                ];
        return erpAddresses;
    }

    public static List<ERP_Address__c> fetchErpAddressesByMasterIds(String contactId,List<String> addressTypes, Set<String> masterIds){
        List<ERP_Address__c> erpAddresses = new List<ERP_Address__c>();
        erpAddresses = [SELECT Id, Account__c, Account__r.Name, Contact__c,ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, ERP_Account_Group__c, 
                Address_Type__c, ERP_Customer_Number__c, ERP_Sales_Org__c, MDM_Customer_Status__c, Address_Street_Line_1__c, 
                Address_Street_Line_2__c, Address_City__c, apiState__c, Address_Postal_Code__c, apiCountry__c, fxAddress_City__c,
                fxAddress_CountryCode__c, fxAddress_Postal__c, fxAddress_StateName__c, fxAddress_Street__c,External_Id__c, fxAddressFull__c, ERP_Account_Name__c, 
                ERP_Marked_for_Deletion__c, RecordType.Name, ERP_Partner_Code__c, Master_Address__c, Master_Address__r.External_Id__c, 
                Master_Address__r.Address_Street_Line_1__c, Master_Address__r.Address_Street_Line_2__c, Master_Address__r.Address_City__c,
                Master_Address__r.apiState__c, Master_Address__r.apiCountry__c, Master_Address__r.Address_Postal_Code__c,  Target_Address__c,
                Target_Address__r.External_Id__c,Target_Address__r.Address_Street_Line_1__c, Target_Address__r.Address_Street_Line_2__c, 
                Target_Address__r.Address_City__c, Target_Address__r.apiState__c, Target_Address__r.Address_Postal_Code__c, 
                Target_Address__r.apiCountry__c,SAP_Name_1__c, SAP_Name_2__c,SAP_Name_3__c,SAP_Name_4__c,
                Target_Address__r.SAP_Name_1__c, Target_Address__r.SAP_Name_2__c,Target_Address__r.SAP_Name_3__c,Target_Address__r.SAP_Name_4__c, RAD_Identifier__c, 
                ECOM_Punchout_Processors__c //GAr - added for punchout 
				, Target_Address__r.ECOM_E_Invoice_Cust_Id__c, Target_Address__r.ECOM_EAN_Do_Not_Use__c, Target_Address__r.ECOM_VAT_Number__c
                , Target_Address__r.ECOM_PU_Cust_E_Invoice__c, Target_Address__r.ECOM_Email_To_Invoice__c
                , ECOM_E_Invoice_Cust_Id__c, ECOM_EAN_Do_Not_Use__c, ECOM_VAT_Number__c, ECOM_PU_Cust_E_Invoice__c // Sathiya - ECOM-1933, ECOM-1942
                , ECOM_Email_To_Invoice__c // Sathiya - ECOM-3389
                FROM ERP_Address__c 
                WHERE 
                Contact__c = :contactId 
                AND Address_Type__c IN :addressTypes
                AND Master_Address__c IN :masterIds
                ];
        return erpAddresses;
    }

    public static List<ERP_Address__c> fetchNewERPAddressesByContactId(String contactId,List<String> addressTypes){
        List<ERP_Address__c> erpAddresses = new List<ERP_Address__c>();
        erpAddresses = [SELECT Id, Account__c, Account__r.Name, Contact__c,ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, ERP_Account_Group__c, 
                Address_Type__c, ERP_Customer_Number__c, ERP_Sales_Org__c, MDM_Customer_Status__c, Address_Street_Line_1__c, 
                Address_Street_Line_2__c, Address_City__c, apiState__c, Address_Postal_Code__c, apiCountry__c, fxAddress_City__c,
                fxAddress_CountryCode__c, fxAddress_Postal__c, fxAddress_StateName__c, fxAddress_Street__c,External_Id__c, fxAddressFull__c, ERP_Account_Name__c, 
                ERP_Marked_for_Deletion__c, RecordType.Name, ERP_Partner_Code__c, Master_Address__c, Master_Address__r.External_Id__c, 
                Master_Address__r.Address_Street_Line_1__c, Master_Address__r.Address_Street_Line_2__c, Master_Address__r.Address_City__c,
                Master_Address__r.apiState__c, Master_Address__r.apiCountry__c, Master_Address__r.Address_Postal_Code__c,  Target_Address__c,
                Target_Address__r.External_Id__c,Target_Address__r.Address_Street_Line_1__c, Target_Address__r.Address_Street_Line_2__c, 
                Target_Address__r.Address_City__c, Target_Address__r.apiState__c, Target_Address__r.Address_Postal_Code__c, 
                Target_Address__r.apiCountry__c,SAP_Name_1__c, SAP_Name_2__c,SAP_Name_3__c,SAP_Name_4__c,
                Target_Address__r.SAP_Name_1__c, Target_Address__r.SAP_Name_2__c,Target_Address__r.SAP_Name_3__c,Target_Address__r.SAP_Name_4__c,RAD_Identifier__c,
                ECOM_Punchout_Processors__c //GAr - added for punchout 
, Target_Address__r.ECOM_E_Invoice_Cust_Id__c, Target_Address__r.ECOM_EAN_Do_Not_Use__c, Target_Address__r.ECOM_VAT_Number__c
                , Target_Address__r.ECOM_PU_Cust_E_Invoice__c, Target_Address__r.ECOM_Email_To_Invoice__c
                , ECOM_E_Invoice_Cust_Id__c, ECOM_EAN_Do_Not_Use__c, ECOM_VAT_Number__c, ECOM_PU_Cust_E_Invoice__c // Sathiya - ECOM-1933, ECOM-1942
                , ECOM_Email_To_Invoice__c // Sathiya - ECOM-3389
                FROM ERP_Address__c 
                WHERE 
                Contact__c = :contactId AND 
                Address_Type__c IN :addressTypes AND
                ECOM_Review_Status__c IN ('New','In Progress')];
        return erpAddresses;
    }

    
    
    public static RecordType getDefautlRecordType(){
        return [SELECT Id, DeveloperName FROM RecordType WHERE DeveloperName = :ECOM_Constant.ERP_DEFAULT_RECORD_TYPE LIMIT 1];
    }
    
     /**
    * @description This method is used to Insert or Update ERP_Address__c records for logged in user
    * @author Rani Thumma | 2023-10-13
    * @param List<ERP_Address__c>  
    * @return 
    **/
    public static void upsertERPAddress(List<ERP_Address__c> erpAddresses){
        upsert erpAddresses;
    }
    
    
    
     /**
    * @description This method is used to retrieve ERP_Address__c records for logged in user
    * @author Rani Thumma | 2023-10-10
    * @author Sidak | 2024-05-30 | Added Is_Disabled__c | RWPS-392
    * @param contactId 
    * @return List<ERP_RelationShip__c> 
    **/
    public static List<ERP_RelationShip__c> fetchERPRelationshipsByContactId(String contactId){
        return [SELECT Id, Name, Contact__c, External_Id__c, ERP_Address__c,ERP_Address__r.Account__c,ERP_Address__r.Master_Address__c,
                ERP_Address__r.Target_Address__c, ERP_Address__r.ECOM_isEnabled__c, ERP_Address__r.ECOM_Review_Status__c,
                ERP_Address__r.Address_Type__c,ERP_Address__r.ERP_Sales_Org__c, Is_Disabled__c
                FROM ERP_Relationship__c 
                WHERE Contact__c = :contactId AND Is_Disabled__c = false]; 
    }
    /**
    * @description This method is used to retrieve ERP_Address__c records for logged in user Ship to ERP Address
    * @author Rani Thumma | 2023-10-10
    * @author Sidak | 2024-05-30 | Added Is_Disabled__c | RWPS-392
    * @param contactId, ERP address Id
    * @return List<ERP_RelationShip__c> 
    **/
    public static List<ERP_RelationShip__c> fetchERPRelationshipsByERPAddress(String contactId, String erpAddId){
        return [SELECT Id, Name, Contact__c, External_Id__c, ERP_Address__c,ERP_Address__r.Account__c,ERP_Address__r.Master_Address__c,
                ERP_Address__r.Target_Address__c, ERP_Address__r.ECOM_isEnabled__c, ERP_Address__r.ECOM_Review_Status__c,
                ERP_Address__r.Address_Type__c,ERP_Address__r.ERP_Sales_Org__c, ERP_Contact_ID__c  
                FROM ERP_Relationship__c 
                WHERE Contact__c = :contactId AND Is_Disabled__c = false AND
                ERP_Address__c = :erpAddId AND ERP_Contact_ID__c!='' ORDER BY CREATEDDATE DESC ]; 
    }


    public static List<String> getAccountsFromAcrBasedOnContact(String contactId)
    {
        List<AccountContactRelation> acrs = [
                                                SELECT Id, AccountId
                                                FROM AccountContactRelation
                                                WHERE ContactId=:contactId
                                            ];
        List<String> accIds=new List<String>();
        for(AccountContactRelation af:acrs) 
        {
            accIds.add(af.AccountId);
        }
        return accIds;
    }

    /**
    * @description This method is used to insert ERP Relationships
    * @author Sidak | 2024-07-24 | RWPS-1144
    * @param relationsToInsert 
    * @return List<String>
    **/
    public static List<String> getNonPlaceholderAccountsFromAcrBasedOnContact(String contactId)
    {
        List<AccountContactRelation> acrs = [
                                                SELECT Id, AccountId
                                                FROM AccountContactRelation
                                                WHERE ContactId=:contactId AND (NOT Account.Name LIKE '%Placeholder%')
                                            ];
        List<String> accIds=new List<String>();
        for(AccountContactRelation af:acrs) 
        {
            accIds.add(af.AccountId);
        }
        return accIds;
    }


    public static List<ERP_Address__c> getSoldToERPBasedOnAccountId(List<String> accIds,String salesOrg)
    {
        List<ERP_Address__c> erpAddresses = new List<ERP_Address__c>();
        erpAddresses =  [
                            SELECT Id,Target_Address__c,Master_Address__c,
                            ECOM_Punchout_Processors__c //GAr - added for punchout
                            FROM ERP_Address__c 
                            WHERE 
                            Account__c IN :accIds
                            AND
                            Address_Type__c = 'Sold To'
                            AND
                            (ECOM_isEnabled__c = true OR fxIsECOMenabled__c = true)
                            AND
                            Contact__c=null
                            AND 
                            ERP_Sales_Org__c=:salesOrg

            				                        ];
        return erpAddresses;        
    }
      public static List<ERP_Address__c> getSoldToERPBasedOnAccountId(List<String> accIds,String salesOrg, List<String> disabledAddressIds)
    {
        List<ERP_Address__c> erpAddresses = new List<ERP_Address__c>();
        erpAddresses =  [
                            SELECT Id,Target_Address__c,Master_Address__c,
                            ECOM_Punchout_Processors__c //GAr - added for punchout
                            FROM ERP_Address__c 
                            WHERE 
                            Account__c IN :accIds
                            AND
                            Address_Type__c = 'Sold To'
            				AND
                			Master_Address__c NOT IN :disabledAddressIds
                            AND
                            (ECOM_isEnabled__c = true OR fxIsECOMenabled__c = true)
                            AND
                            Contact__c=null
                            AND 
                            ERP_Sales_Org__c=:salesOrg
            				
                        ];
        return erpAddresses;        
    }

    public static Integer fetchInProgressAddresses(List<String> erpIds)
    {
        return [ 
                Select count() 
                FROM 
                ERP_Address__c
                WHERE 
                Id in: erpIds
                AND
                ECOM_Review_Status__c='In Progress'
               ];
    }
    
    /**
     * @description This method returns list of Sold To and Ship to, or specified address types Address for an account Id
     * @author vramachandran@rafter.one | 11 Dec 2023
     * @param accountId | String
     * @return List<ERP_Address__c>
     */
    public static List<ERP_Address__c> getErpAddressForAccountId(String accountId, List<String> addressTypeList){
        if(addressTypeList != null && !addressTypeList.isEmpty()){
            return [SELECT Id, Address_Type__c,
                    ECOM_Punchout_Processors__c //GAr - added for punchout
                    FROM ERP_Address__c
                    WHERE Account__c  =: accountId
                    AND fxIsECOMenabled__c = true
                    AND Address_Type__c IN :addressTypeList
                    LIMIT 49999];
        } else {
            return [SELECT Id, Address_Type__c,
                    ECOM_Punchout_Processors__c //GAr - added for punchout
                    FROM ERP_Address__c
                    WHERE Account__c  =: accountId
                    AND fxIsECOMenabled__c = true
                    LIMIT 49999];
        }
        
    }
    
    /**
     * @description This method returns linked Ship To, Sold To and Payer Address for a given accountId
     * @author poonam.shukla@revvity.com | 07 JAN 2025
     * @param accountId | String 
     * @returns List<ERP_Address>
     */
    
    public static List<ERP_Address__c> getAllAddressForPunchout(String accountId){
        return [SELECT Id,Master_Address__c,Master_Address__r.ECOM_Punchout_Products_Exclude_Query__c, 
                Master_Address__r.ECOM_Punchout_Products_Include_Query__c FROM ERP_Address__c
                WHERE ECOM_isEnabled__c =true AND ECOM_Punchout_Is_Enabled__c =true
                AND Account__c = :accountId AND ERP_Marked_for_Deletion__c = false AND RecordType.DeveloperName = 'Default'
                AND ECOM_Review_Status__c = 'Approved' LIMIT 4999];
    }
    
    /**
     * @description This method returns list of Address Id for a punchout account uniquename
     * @author vramchandran@rafter.one | 22 Dec 2023 
     * @param uniqueName | String 
     * @returns List<ERP_Address__c>
     */
    /**public static List<ERP_Address__c> getPunchoutERPAddressList(String uniqueName){
        return [SELECT Id,
                ECOM_Punchout_Processors__c //GAr - added for punchout
                FROM ERP_Address__c 
                WHERE ECOM_Punchout_Is_Enabled__c = true
                AND ECOM_Punchout_Customer_Id__c =: uniqueName
                LIMIT 1];
    }*/
    
    /**
     * @description This method returns the Master ERP Address information, and linked Ship To, Sold To and Payer Address for a given accointId
     * @author vramachandran@rafter.one | 22 Dec 2023
     * @param accountUniqueName | String 
     * @returns List<ERP_Address>
     */
    /**public static List<ERP_Address__c> getMasterAndLinkedAddressForPunchoutAccountUniqueName(String accountUniqueName, String salesOrg){
        List<String> addressTypes = System.Label.ECOM_PunchoutERPAddressTypes.split(',');
        return [SELECT Id, Account__c, Account__r.Name, Contact__c,ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, ERP_Account_Group__c, 
                Address_Type__c, ERP_Customer_Number__c, ERP_Sales_Org__c, MDM_Customer_Status__c, Address_Street_Line_1__c, 
                Address_Street_Line_2__c, Address_City__c, Address_State__c, Address_Country__c, apiState__c, Address_Postal_Code__c, apiCountry__c, 
                fxAddress_City__c,fxAddress_CountryCode__c, fxAddress_Postal__c, fxAddress_StateName__c, fxAddress_Street__c, fxAddressFull__c,
                External_Id__c, ERP_Account_Name__c, ERP_Marked_for_Deletion__c, RecordType.Name, ERP_Partner_Code__c,
                ECOM_Punchout_Is_Enabled__c, ECOM_Punchout_Customer_Id__c, ECOM_Punchout_Customer_Logo__c, ECOM_Punchout_Customer_Name__c, 
                ECOM_Punchout_Products_Exclude_Query__c, ECOM_Punchout_Products_Include_Query__c, ECOM_Punchout_Show_List_Price__c, 
                ECOM_Punchout_Unit_Of_Measurement__c, ECOM_POSR_Sender_Shared_Identity__c, ECOM_POSR_Sender_Shared_Secret__c, ECOM_Punchout_Format__c,
                ECOM_Punchout_Account_TimeZone_SID__c, CurrencyIsoCode,
                ECOM_Punchout_Processors__c //GAr - added for punchout
                FROM ERP_Address__c
                WHERE ECOM_Punchout_Customer_Id__c =: accountUniqueName
                AND (ECOM_Punchout_Is_Enabled__c = true OR ECOM_fx_Punchout_Is_Enabled__c = true)
                //AND Address_Type__c IN :addressTypes
                LIMIT 49999];
    }*/
    
    /**
     * @description This method returns the Master ERP Address information, and linked Ship To, Sold To and Payer Address for a given accointId
     * @author vramachandran@rafter.one | 02 Jan 2023
     * @param accountUniqueName | String 
     * @returns List<ERP_Address>
     */
    public static List<ERP_Address__c> getMasterAndLinkedAddressForPunchoutAccountId(String accountId){
        List<String> addressTypes = System.Label.ECOM_PunchoutERPAddressTypes.split(',');
        return [SELECT Id, Account__c, Account__r.Name, Contact__c,ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, ERP_Account_Group__c, 
                Address_Type__c, ERP_Customer_Number__c, ERP_Sales_Org__c, MDM_Customer_Status__c, Address_Street_Line_1__c, 
                Address_Street_Line_2__c, Address_City__c, Address_State__c, Address_Country__c, apiState__c, Address_Postal_Code__c, apiCountry__c, 
                fxAddress_City__c,fxAddress_CountryCode__c, fxAddress_Postal__c, fxAddress_StateName__c, fxAddress_Street__c, fxAddressFull__c,
                External_Id__c, ERP_Account_Name__c, ERP_Marked_for_Deletion__c, RecordType.Name, ERP_Partner_Code__c,
                ECOM_Punchout_Is_Enabled__c, ECOM_Punchout_Customer_Id__c, ECOM_Punchout_Customer_Logo__c, ECOM_Punchout_Customer_Name__c, 
                ECOM_Punchout_Products_Exclude_Query__c, ECOM_Punchout_Products_Include_Query__c, ECOM_Punchout_Show_List_Price__c, 
                ECOM_Punchout_Unit_Of_Measurement__c, ECOM_POSR_Sender_Shared_Identity__c, ECOM_POSR_Sender_Shared_Secret__c, ECOM_Punchout_Format__c,RAD_Identifier__c,
                ECOM_Punchout_Account_TimeZone_SID__c , CurrencyIsoCode,
                ECOM_Punchout_Processors__c, //GAr ECOM-2100
                fxAddress_CountryName__c,ECOM_Punchout_Country_Locale__c,
                Account__r.CurrencyIsoCode,
                ECOM_Punchout_Default_UNSPSC__c //RWPS-410 - 3 April 2024 - garora@rafter.one - querying new field created for requirement
, Target_Address__r.ECOM_E_Invoice_Cust_Id__c, Target_Address__r.ECOM_EAN_Do_Not_Use__c, Target_Address__r.ECOM_VAT_Number__c
                , Target_Address__r.ECOM_PU_Cust_E_Invoice__c, Target_Address__r.ECOM_Email_To_Invoice__c, Target_Address__c
                , ECOM_E_Invoice_Cust_Id__c, ECOM_EAN_Do_Not_Use__c, ECOM_VAT_Number__c, ECOM_PU_Cust_E_Invoice__c // Sathiya - ECOM-1933, ECOM-1942
                , ECOM_Email_To_Invoice__c // Sathiya - ECOM-3389
                FROM ERP_Address__c
                WHERE Account__c =: accountId
                AND (ECOM_Punchout_Is_Enabled__c = true )//OR ECOM_fx_Punchout_Is_Enabled__c = true
                //AND Address_Type__c IN :addressTypes
                LIMIT 49999];
    }
    
    /**
     * @description This method returns the Master ERP Address information //VRa 15 Jan: To be deprecated
     * @author vramachandran@rafter.one | 02 Jan 2023
     * @param accountUniqueName | String 
     * @returns List<ERP_Address>
     */
    /**public static List<ERP_Address__c> getERPMasterAddressForPunchoutAccount(String accountId){
        List<String> addressTypes = System.Label.ECOM_PunchoutERPAddressTypes.split(',');
        return [SELECT Id, Account__c, Account__r.Name, Contact__c,ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, ERP_Account_Group__c, 
                Address_Type__c, ERP_Customer_Number__c, ERP_Sales_Org__c, MDM_Customer_Status__c, Address_Street_Line_1__c, 
                Address_Street_Line_2__c, Address_City__c, Address_State__c, Address_Country__c, apiState__c, Address_Postal_Code__c, apiCountry__c, 
                fxAddress_City__c,fxAddress_CountryCode__c, fxAddress_Postal__c, fxAddress_StateName__c, fxAddress_Street__c, fxAddressFull__c,
                External_Id__c, ERP_Account_Name__c, ERP_Marked_for_Deletion__c, RecordType.Name, ERP_Partner_Code__c,
                ECOM_Punchout_Is_Enabled__c, ECOM_Punchout_Customer_Id__c, ECOM_Punchout_Customer_Logo__c, ECOM_Punchout_Customer_Name__c, 
                ECOM_Punchout_Products_Exclude_Query__c, ECOM_Punchout_Products_Include_Query__c, ECOM_Punchout_Show_List_Price__c, 
                ECOM_Punchout_Unit_Of_Measurement__c, ECOM_POSR_Sender_Shared_Identity__c, ECOM_POSR_Sender_Shared_Secret__c, ECOM_Punchout_Format__c,
                ECOM_Punchout_Account_TimeZone_SID__c, CurrencyIsoCode,
                ECOM_Punchout_Processors__c, //GAr - added for punchout 
                Account__r.CurrencyIsoCode
                FROM ERP_Address__c
                WHERE Account__c =: accountId
                AND (ECOM_Punchout_Is_Enabled__c = true )//OR ECOM_fx_Punchout_Is_Enabled__c = true
                AND Address_Type__c = 'Master'
                LIMIT 1];
    }*/

    
    
    /**
     * @description This method returns list of all erp addresses marked for punchout
     * @author vramachandran@rafter.one | 07 Jan 2024
     * @author ssingh@rafter.one | 19 Nov 2024 | RWPS-1809
     * @returns List<ERP_Address>
     */
    public static List<ERP_Address__c> getPunchoutERPAddresses(Set<Id> punchoutConfigs){// RWPS-5776

        List<ERP_Address__c> masterERPList = [SELECT Id
                                                FROM ERP_Address__c
                                                WHERE ERP_Marked_for_Deletion__c = false 
                                                AND RecordType.DeveloperName = 'Default'
                                                AND ECOM_Review_Status__c = 'Approved'
                                                AND fxIsECOMenabled__c = true AND Address_Type__c='Master'
                                                AND Id IN :punchoutConfigs]; // RWPS-5776

        return [SELECT Id, Account__c, Account__r.Name, fxAddress_CountryName__c
                FROM ERP_Address__c 
                WHERE ECOM_Punchout_Is_Enabled__c = true AND Address_Type__c = 'Ship To' AND Master_Address__c IN : masterERPList
                LIMIT 49999];// RWPS-5776
    }
    
/**
     * @description This method returns the ERP Address (Ship to, Sold to, Bill To, Payer) and the related target.master address for
     *  a punchout account Unique name defined on the target.master( ECOM Punchout Customer Id field)
     * @author vramachandran@rafter.one | 15 Jan 2024
     * @param poAccountUniqueName | String
     * @returns List<ERP_Address> 
     */
    public static List<ERP_Address__c> getPunchoutAddressesForERPAddressModel(String poAccountUniqueName){
        return [SELECT Id, ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, Address_Type__c, MDM_Customer_Status__c, 
                Address_Street_Line_1__c, RecordType.Name, Address_Street_Line_2__c, Address_City__c, Address_State__c, Address_Country__c, 
                apiState__c, Address_Postal_Code__c, apiCountry__c, fxAddress_City__c,fxAddress_CountryCode__c, fxAddress_Postal__c, 
                fxAddress_StateName__c, fxAddress_Street__c, fxAddressFull__c, External_Id__c, CurrencyIsoCode,fxAddress_CountryName__c,
                
                //ERP Details
                ERP_Account_Group__c,ERP_Customer_Number__c, ERP_Sales_Org__c,ERP_Account_Name__c, ERP_Marked_for_Deletion__c, ERP_Partner_Code__c,
                
                //AccountFields
                Account__c, Account__r.Name, Account__r.CurrencyIsoCode,
                
                //ContactFields
                Contact__c,  
                
                //Punchout fields
                ECOM_Punchout_Is_Enabled__c, ECOM_Punchout_Customer_Id__c, ECOM_Punchout_Customer_Logo__c, ECOM_Punchout_Customer_Name__c, 
                ECOM_Punchout_Products_Exclude_Query__c, ECOM_Punchout_Products_Include_Query__c, ECOM_Punchout_Show_List_Price__c, 
                ECOM_Punchout_Unit_Of_Measurement__c, ECOM_POSR_Sender_Shared_Identity__c, ECOM_POSR_Sender_Shared_Secret__c, ECOM_Punchout_Format__c,
                ECOM_Punchout_Account_TimeZone_SID__c, ECOM_Punchout_Processors__c, ECOM_Punchout_Country_Locale__c, 
                ECOM_Punchout_Default_UNSPSC__c //RWPS-410 - 3 April 2024 - garora@rafter.one - querying new field created for requirement
                
                , Target_Address__r.ECOM_E_Invoice_Cust_Id__c, Target_Address__r.ECOM_EAN_Do_Not_Use__c, Target_Address__r.ECOM_VAT_Number__c
                , Target_Address__r.ECOM_PU_Cust_E_Invoice__c, Target_Address__r.ECOM_Email_To_Invoice__c, Target_Address__c
				, ECOM_E_Invoice_Cust_Id__c, ECOM_EAN_Do_Not_Use__c, ECOM_VAT_Number__c, ECOM_PU_Cust_E_Invoice__c // Sathiya - ECOM-1933, ECOM-1942
                , ECOM_Email_To_Invoice__c // Sathiya - ECOM-3389
                FROM ERP_Address__c
                WHERE ERP_Marked_for_Deletion__c = false 
                //AND (RecordType.DeveloperName = 'Default' OR RecordType.DeveloperName = 'Staging' OR RecordType.DeveloperName = '')
                AND ECOM_Review_Status__c = 'Approved'
                AND fxIsECOMenabled__c = true
                AND ((Target_Address__r.ECOM_Punchout_Is_Enabled__c = true AND ECOM_Punchout_Is_Enabled__c = true AND Target_Address__r.ECOM_Punchout_Customer_Id__c =: poAccountUniqueName)
                    OR (Master_Address__r.ECOM_Punchout_Is_Enabled__c = true AND ECOM_Punchout_Is_Enabled__c = true AND Address_Type__c = 'Payer' AND Master_Address__r.ECOM_Punchout_Customer_Id__c =: poAccountUniqueName)
                    OR (Address_Type__c = 'Master' AND ECOM_Punchout_Customer_Id__c =: poAccountUniqueName AND ECOM_Punchout_Is_Enabled__c = true))
                LIMIT 49999 ];
    }


    /**
     * @description This method returns the Master ERP Address information
     * @author vramachandran@rafter.one | 02 Jan 2023 //Valid
     * @param accountUniqueName | String 
     * @returns List<ERP_Address>
     */
    public static List<ERP_Address__c> getERPMasterAddressForPunchoutMasterId(String masterId){
        List<String> addressTypes = System.Label.ECOM_PunchoutERPAddressTypes.split(',');
        return [SELECT Id, Account__c, Account__r.Name, Contact__c,ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, ERP_Account_Group__c, 
                Address_Type__c, ERP_Customer_Number__c, ERP_Sales_Org__c, MDM_Customer_Status__c, Address_Street_Line_1__c, 
                Address_Street_Line_2__c, Address_City__c, Address_State__c, Address_Country__c, apiState__c, Address_Postal_Code__c, apiCountry__c, 
                fxAddress_City__c,fxAddress_CountryCode__c, fxAddress_Postal__c, fxAddress_StateName__c, fxAddress_Street__c, fxAddressFull__c,fxAddress_CountryName__c,
                External_Id__c, ERP_Account_Name__c, ERP_Marked_for_Deletion__c, RecordType.Name, ERP_Partner_Code__c,
                ECOM_Punchout_Is_Enabled__c, ECOM_Punchout_Customer_Id__c, ECOM_Punchout_Customer_Logo__c, ECOM_Punchout_Customer_Name__c, 
                ECOM_Punchout_Products_Exclude_Query__c, ECOM_Punchout_Products_Include_Query__c, ECOM_Punchout_Show_List_Price__c, 
                ECOM_Punchout_Unit_Of_Measurement__c, ECOM_POSR_Sender_Shared_Identity__c, ECOM_POSR_Sender_Shared_Secret__c, ECOM_Punchout_Format__c,RAD_Identifier__c,
                ECOM_Punchout_Account_TimeZone_SID__c, CurrencyIsoCode,
                ECOM_Punchout_Processors__c, //GAr - added for punchout 
                Account__r.CurrencyIsoCode, ECOM_Punchout_Country_Locale__c,
                ECOM_Punchout_Default_UNSPSC__c //RWPS-410 - 3 April 2024 - garora@rafter.one - querying new field created for requirement
, Target_Address__r.ECOM_E_Invoice_Cust_Id__c, Target_Address__r.ECOM_EAN_Do_Not_Use__c, Target_Address__r.ECOM_VAT_Number__c //VRa 02 Jul Adding fields for target address for ECOM-3301
                , Target_Address__r.ECOM_PU_Cust_E_Invoice__c, Target_Address__r.ECOM_Email_To_Invoice__c //VRa 02 Jul Adding fields for target address for ECOM-3301
                , ECOM_E_Invoice_Cust_Id__c, ECOM_EAN_Do_Not_Use__c, ECOM_VAT_Number__c, ECOM_PU_Cust_E_Invoice__c //VRa 02 Jul Adding fields for target address for ECOM-3301
                , ECOM_Email_To_Invoice__c // Sathiya - ECOM-3389
                FROM ERP_Address__c
                WHERE Id =: masterId
                AND (ECOM_Punchout_Is_Enabled__c = true )//OR ECOM_fx_Punchout_Is_Enabled__c = true
                AND Address_Type__c = 'Master'
                LIMIT 1];
    }    

    
    /**
     * @description This method returns the Master ERP Address information
     * @author vramachandran@rafter.one | 15 Jan 2024 //Valid
     * @param accountUniqueName | String 
     * @returns List<ERP_Address>
     */
    public static List<ERP_Address__c> getERPMasterAddressForPunchoutAccountId(String accountId){
        return [SELECT id, Target_Address__c, Master_Address__c, Address_Type__c, fxAddress_CountryName__c
                FROM ERP_Address__c 
                WHERE ERP_Marked_for_Deletion__c = false
                AND ECOM_Review_Status__c = 'Approved'
                AND fxIsECOMenabled__c = true
                //AND (RecordType.DeveloperName = 'Default' OR RecordType.DeveloperName = 'Staging')
                AND Account__c =: accountId
                AND ECOM_Punchout_Is_Enabled__c = true
                LIMIT 1];
    }
    
    /**
     * @description This method returns the ERP Address (Ship to, Sold to, Bill To, Payer) and the related target.master address for
     *  a punchout master address Id
     * @author vramachandran@rafter.one | 16 Jan 2024
     * @param poAccountUniqueName | String
     * @returns List<ERP_Address> 
     */
    public static List<ERP_Address__c> getPunchoutAddressesForERPMasterAddressId(String masterId){
        return [SELECT Id, ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, Address_Type__c, MDM_Customer_Status__c, 
                Address_Street_Line_1__c, RecordType.Name, Address_Street_Line_2__c, Address_City__c, Address_State__c, Address_Country__c, 
                apiState__c, Address_Postal_Code__c, apiCountry__c, fxAddress_City__c,fxAddress_CountryCode__c, fxAddress_Postal__c, 
                fxAddress_StateName__c, fxAddress_Street__c, fxAddressFull__c, External_Id__c, CurrencyIsoCode,fxAddress_CountryName__c,
                
                //ERP Details
                ERP_Account_Group__c,ERP_Customer_Number__c, ERP_Sales_Org__c,ERP_Account_Name__c, ERP_Marked_for_Deletion__c, ERP_Partner_Code__c,
                
                //AccountFields
                Account__c, Account__r.Name,  Account__r.CurrencyIsoCode,
                
                //ContactFields
                Contact__c,  
                
                //Punchout fields
                ECOM_Punchout_Is_Enabled__c, ECOM_Punchout_Customer_Id__c, ECOM_Punchout_Customer_Logo__c, ECOM_Punchout_Customer_Name__c, 
                ECOM_Punchout_Products_Exclude_Query__c, ECOM_Punchout_Products_Include_Query__c, ECOM_Punchout_Show_List_Price__c, 
                ECOM_Punchout_Unit_Of_Measurement__c, ECOM_POSR_Sender_Shared_Identity__c, ECOM_POSR_Sender_Shared_Secret__c, ECOM_Punchout_Format__c,
                ECOM_Punchout_Account_TimeZone_SID__c, ECOM_Punchout_Processors__c, ECOM_Punchout_Country_Locale__c, 
                ECOM_Punchout_Default_UNSPSC__c //RWPS-410 - 3 April 2024 - garora@rafter.one - querying new field created for requirement
, Target_Address__r.ECOM_E_Invoice_Cust_Id__c, Target_Address__r.ECOM_EAN_Do_Not_Use__c, Target_Address__r.ECOM_VAT_Number__c
                , Target_Address__r.ECOM_PU_Cust_E_Invoice__c, Target_Address__r.ECOM_Email_To_Invoice__c, Target_Address__c
                , ECOM_E_Invoice_Cust_Id__c, ECOM_EAN_Do_Not_Use__c, ECOM_VAT_Number__c, ECOM_PU_Cust_E_Invoice__c // Sathiya - ECOM-1933, ECOM-1942
                , ECOM_Email_To_Invoice__c // Sathiya - ECOM-3389
                FROM ERP_Address__c
                WHERE ERP_Marked_for_Deletion__c = false 
                //AND (RecordType.DeveloperName = 'Default' OR RecordType.DeveloperName = 'Staging')
                AND ECOM_Review_Status__c = 'Approved'
                AND fxIsECOMenabled__c = true
                AND ((Target_Address__r.ECOM_Punchout_Is_Enabled__c = true AND ECOM_Punchout_Is_Enabled__c = true AND Target_Address__c =: masterId)
                    OR (Address_Type__c = 'Master' AND Id =: masterId AND ECOM_Punchout_Is_Enabled__c = true)
                    OR (Address_Type__c = 'Payer' AND Master_Address__c =: masterId AND ECOM_Punchout_Is_Enabled__c = true))
                LIMIT 49999 ];
    }

    /**
    * @description This method is used to retrieve disabled ERP_Relationship__c records
    * @author Sidak | 2024-06-05 | RWPS-392
    * @param contactId 
    * @return List<ERP_RelationShip__c> 
    **/
    public static List<ERP_RelationShip__c> getDisabledERPAddressesFromERPRelationship(String contactId){
        return [SELECT Id, Name, Contact__c, External_Id__c, ERP_Address__c,ERP_Address__r.Account__c,ERP_Address__r.Master_Address__c,
                ERP_Address__r.Target_Address__c, ERP_Address__r.ECOM_isEnabled__c, ERP_Address__r.ECOM_Review_Status__c,
                ERP_Address__r.Address_Type__c,ERP_Address__r.ERP_Sales_Org__c, Is_Disabled__c, ERP_Address__r.External_Id__c//RWPS-4776
                FROM ERP_Relationship__c WHERE Contact__c = :contactId AND Is_Disabled__c = true]; 
    }

    /**
    * @description This method is used to retrieve ERP Addresses based on Account Id
    * @author Sidak | 2024-06-10 | RWPS-392
    * @author ssingh@rafter.one | 18 Jun 2024 | RWPS-392 | Added Master_Address__r.Address_Type__c in query
    * @param accIds 
    * @return List<ERP_Address__c> 
    **/
    public static List<ERP_Address__c> getERPAddressesBasedOnAccountId(List<String> accIds){
        return [SELECT Id, Account__c, Account__r.Name, Address_Type__c, Contact__c, Master_Address__c, Master_Address__r.Address_Type__c, Master_Address__r.External_Id__c
                FROM ERP_Address__c 
                WHERE Account__c IN : accIds];
    }

    /**
    * @description This method is used to retrieve ERP Addresses based on Account Id
    * @author Sidak | 2024-07-24 | RWPS-1144
    * @param accIds 
    * @return List<ERP_Address__c> 
    **/
    public static List<ERP_Address__c> getMasterERPAddressesBasedOnAccountId(List<String> accIds,List<String> excludedAddress){
        return [SELECT Id, Account__c, Account__r.Name, Address_Type__c, Contact__c, Master_Address__c, Master_Address__r.Address_Type__c, Master_Address__r.External_Id__c, RecordType.DeveloperName
                FROM ERP_Address__c 
                WHERE Master_Address__r.Address_Type__c = 'Master' AND RecordType.DeveloperName = 'Default' AND Account__c IN : accIds AND Master_Address__c NOT IN :excludedAddress LIMIT 1000];
    }

    /**
    * @description This method is used to retrieve ERP_Relationship__c records by Contact Id
    * @author Sidak | 2024-06-10 | RWPS-392
    * @param contactId 
    * @return List<ERP_RelationShip__c> 
    **/
    public static List<ERP_RelationShip__c> getERPRelationshipsByContactId(String contactId){
        return [SELECT Id, Name, Contact__c, ERP_Address__c,ERP_Address__r.Account__c,ERP_Address__r.Master_Address__c, ERP_Contact_ID__c,
                ERP_Address__r.Target_Address__c, ERP_Address__r.ECOM_isEnabled__c, ERP_Address__r.ECOM_Review_Status__c,
                ERP_Address__r.Address_Type__c,ERP_Address__r.ERP_Sales_Org__c, Is_Disabled__c 
                FROM ERP_Relationship__c WHERE Contact__c =: contactId];
    }

    /**
    * @description This method is used to insert ERP Relationships
    * @author Sidak | 2024-06-10 | RWPS-392
    * @param relationsToInsert 
    * @return List<ERP_RelationShip__c> 
    **/
    public static void insertERPRelationships(List<ERP_Relationship__c> relationsToInsert){
        insert relationsToInsert;
    }
       /**
    * @description This method is used to retrieve ERP Addresses based on master ids
    * @author Manoj | 2024-10-30 | RWPS-1722
    * @param masterIds 
    * @return List<ERP_Address__c> 
    **/
    public static List<ERP_Address__c> getPunchoutMasterERPAddressesMasterIds(List<String> masterIds){
        return [SELECT Id, ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, Address_Type__c, MDM_Customer_Status__c, 
        Address_Street_Line_1__c, RecordType.Name, Address_Street_Line_2__c, Address_City__c, Address_State__c, Address_Country__c, 
        apiState__c, Address_Postal_Code__c, apiCountry__c, fxAddress_City__c,fxAddress_CountryCode__c, fxAddress_Postal__c, 
        fxAddress_StateName__c, fxAddress_Street__c, fxAddressFull__c, External_Id__c, CurrencyIsoCode,fxAddress_CountryName__c,            
        ERP_Account_Group__c,ERP_Customer_Number__c, ERP_Sales_Org__c,ERP_Account_Name__c, ERP_Marked_for_Deletion__c, ERP_Partner_Code__c,                      
        Account__c, Account__r.Name, Account__r.CurrencyIsoCode,                        
        ECOM_Punchout_Is_Enabled__c, ECOM_Punchout_Customer_Id__c, ECOM_Punchout_Customer_Logo__c, ECOM_Punchout_Customer_Name__c, 
        ECOM_Punchout_Products_Exclude_Query__c, ECOM_Punchout_Products_Include_Query__c, ECOM_Punchout_Show_List_Price__c, 
        ECOM_Punchout_Unit_Of_Measurement__c, ECOM_POSR_Sender_Shared_Identity__c, ECOM_POSR_Sender_Shared_Secret__c, ECOM_Punchout_Format__c,
        ECOM_Punchout_Account_TimeZone_SID__c, ECOM_Punchout_Processors__c, ECOM_Punchout_Country_Locale__c, 
        ECOM_Punchout_Default_UNSPSC__c
                FROM ERP_Address__c 
                WHERE Master_Address__r.Address_Type__c = 'Master' AND RecordType.DeveloperName = 'Default'AND Master_Address__c IN :masterIds LIMIT 1000];
    }

    /**
    * @description This method is used to retrieve ERP Addresses based on Name
    * @author Manish Joshi | 2025-07-11 | RWPS-3657
    * @param shipToPayerInvoiceNameSet
    * @param salesOrg 
    * @return List<ERP_Address__c> 
    **/
    // RWPS-3657 - START
    public static List<ERP_Address__c> getERPAddressBasedOnName(Set<String> shipToPayerInvoiceNameSet,String salesOrg){
        return [SELECT id,Address_Type__c,Target_Address__c,Master_Address__c 
            FROM ERP_Address__c where Name IN :shipToPayerInvoiceNameSet
            AND ERP_Sales_Org__c=:salesOrg AND ECOM_isEnabled__c =true];
    }

    /**
    * @description This method is used to retrieve ERP Addresses based on Name
    * @author Manish Joshi | 2025-07-11 | RWPS-3657
    * @param shipToTargetERPs
    * @param salesOrg 
    * @return List<ERP_Address__c> 
    **/
    public static List<ERP_Address__c> getSoldToRelatedToShipTo(Set<String> shipToTargetERPs,String salesOrg){
        return [SELECT Id FROM ERP_Address__c where Address_Type__c ='Sold To' 
        AND Target_Address__c IN :shipToTargetERPs AND Master_Address__c 
        IN :shipToTargetERPs AND ERP_Sales_Org__c=:salesOrg AND ECOM_isEnabled__c =true];
    }
    // RWPS-3657 - END
        /**
    * @description This method is used to retrieve punchout config record based on params
    * @author Poonam Shukla | 2026-02-19 | RWPS-5777
    * @param masterId
    * @return List<Punchout_Maintenance__c> 
    **/
    public static list<Punchout_Maintenance__c> getPunchoutConfigBasedOnMaster(String masterId){
        return [SELECT id, ERP_Address__c, ECOM_Punchout_Format__c, Ecom_Punchout_Additional_Email_Address__c, ECOM_Punchout_User_Email__c FROM Punchout_Maintenance__c WHERE ERP_Address__c =:masterId LIMIT 1];//RWPS-5777

    }

    // RWPS - RWPS-5776 - START
    /**
    * @description This method is used to retrieve punchout config record based on params
    * @author Manish Joshi | 2026-02-04 | RWPS-5776
    * @param configIds
    * @param accountIds 
    * @param punchoutCustomerId 
    * @param masterId 
    * @return List<Punchout_Maintenance__c> 
    **/
    public static List<Punchout_Maintenance__c> getPunchoutConfigs(Set<String> configIds, Set<Id> accountIds, String punchoutCustomerId, String masterId) 
    {
       String soql = 'SELECT Id, ECOM_Punchout_Default_Payer__c, ERP_Address__c, ' +
              'ECOM_Punchout_Customer_Id__c, External_Id__c, ECOM_Punchout_Sales_Org__c, ' + // Added comma here
              'ECOM_Punchout_Customer_Name__c, ECOM_Punchout_Account_TimeZone_SID__c, ' +
              'ECOM_Punchout_Products_Include_Query__c, ' +
              'ECOM_Punchout_Products_Exclude_Query__c, ' +
              'ECOM_Punchout_Additional_Email_Address__c, ' +
              'ECOM_Punchout_User_Email__c, ' +
              'ECOM_Punchout_Show_List_Price__c, ' +
              'ECOM_Punchout_Customer_Logo__c, ' +
              'Default_Domain__c, ' +
              'ECOM_Punchout_Unit_Of_Measurement__c, ' +
              'ECOM_POSR_Sender_Shared_Identity__c, ' +
              'ECOM_POSR_Sender_Shared_Secret__c, ' +
              'ECOM_Punchout_Default_UNSPSC__c, ' +
              'ECOM_Punchout_Format__c, ' +
              'ECOM_Punchout_Processors__c, ' +
              'ECOM_isEnabled__c, ' +
           	  'ECOM_Punchout_Is_Enabled__c, ' +
              'Account__c ' +
              'FROM Punchout_Maintenance__c ' +
              'WHERE ECOM_isEnabled__c = true ' +
              'AND ECOM_Punchout_Is_Enabled__c = true ' +
              'AND ECOM_Punchout_Default_Payer__c != null ' +
              'AND ERP_Address__c != null ';

        // Only add the Id filter if configIds is not null and not empty
        if (configIds != null && !configIds.isEmpty()) {
            soql += ' AND Id IN :configIds';
        }
        if (accountIds != null && !accountIds.isEmpty()) {
            soql += ' AND Account__c IN :accountIds';
        } 
        // Add Punchout Customer Id filter
        if (String.isNotBlank(punchoutCustomerId)) {
            soql += ' AND ECOM_Punchout_Customer_Id__c = :punchoutCustomerId';
        } else {
            soql += ' AND ECOM_Punchout_Customer_Id__c != null';
        }

        if (String.isNotBlank(masterId)) {
            soql += ' AND ERP_Address__c = :masterId';
        } else {
            soql += ' AND ERP_Address__c != null';
        }

        List<Punchout_Maintenance__c> punchoutConfigsList =
            Database.query(soql);
        return punchoutConfigsList;
    }

    /**
     * @description This method retrieves punchout master erp address record
     * @author manish.joshi@revvity.com | 02 Febt 2026
     * @param customerId | String
     * @returns List<ERP_Address__c>
     */
    public static List<ERP_Address__c> getPunchoutMasterFromMasterId(String masterId){
        List<ERP_Address__c>  masterAddress = [SELECT Id, ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, Address_Type__c, MDM_Customer_Status__c, 
        Address_Street_Line_1__c, RecordType.Name, Address_Street_Line_2__c, Address_City__c, Address_State__c, Address_Country__c, 
        apiState__c, Address_Postal_Code__c, apiCountry__c, fxAddress_City__c,fxAddress_CountryCode__c, fxAddress_Postal__c, 
        fxAddress_StateName__c, fxAddress_Street__c, fxAddressFull__c, External_Id__c, CurrencyIsoCode,fxAddress_CountryName__c,
        ERP_Account_Group__c,ERP_Customer_Number__c, ERP_Sales_Org__c,ERP_Account_Name__c, ERP_Marked_for_Deletion__c, ERP_Partner_Code__c,
        Account__c, Account__r.Name, Account__r.CurrencyIsoCode,Contact__c,  
        ECOM_Punchout_Is_Enabled__c, ECOM_Punchout_Customer_Id__c, ECOM_Punchout_Customer_Logo__c, ECOM_Punchout_Customer_Name__c, 
        ECOM_Punchout_Products_Exclude_Query__c, ECOM_Punchout_Products_Include_Query__c, ECOM_Punchout_Show_List_Price__c, 
        ECOM_Punchout_Unit_Of_Measurement__c, ECOM_POSR_Sender_Shared_Identity__c, ECOM_POSR_Sender_Shared_Secret__c, ECOM_Punchout_Format__c,
        ECOM_Punchout_Account_TimeZone_SID__c, ECOM_Punchout_Processors__c, ECOM_Punchout_Country_Locale__c, 
        ECOM_Punchout_Default_UNSPSC__c ,ECOM_Punchout_Sales_Org__c,ECOM_Punchout_Default_Payer__c,MDM_Cluster_Id__c,Default_Domain__c//RWPS-1923
        FROM ERP_Address__c
        WHERE ERP_Marked_for_Deletion__c = false 
        AND RecordType.DeveloperName = 'Default'
        AND ECOM_Review_Status__c = 'Approved'
        AND ECOM_Punchout_Is_Enabled__c = true
        AND Id =:masterId
        LIMIT 1 ];
        return masterAddress;
    }

    /**
     * @description This method retrieves punchout master partner fuctions records
     * @author manish.joshi@revvity.com | 02 Feb 2026
     * @param masterAddress | ERP_Address__c
     * @returns List<ERP_Address__c>
     */
    public static List<ERP_Address__c> getPunchoutAddressFromPunchoutConfig(Punchout_Maintenance__c configRec){
        List<ERP_Address__c>  punchoutAddresses = [SELECT Id, ECOM_isEnabled__c,fxIsECOMenabled__c, ECOM_Review_Status__c, Address_Type__c, MDM_Customer_Status__c, 
        Address_Street_Line_1__c, RecordType.Name, Address_Street_Line_2__c, Address_City__c, Address_State__c, Address_Country__c, 
        apiState__c, Address_Postal_Code__c, apiCountry__c, fxAddress_City__c,fxAddress_CountryCode__c, fxAddress_Postal__c, 
        fxAddress_StateName__c, fxAddress_Street__c, fxAddressFull__c, External_Id__c, CurrencyIsoCode,fxAddress_CountryName__c,
        ERP_Account_Group__c,ERP_Customer_Number__c, ERP_Sales_Org__c,ERP_Account_Name__c, ERP_Marked_for_Deletion__c, ERP_Partner_Code__c,
        Account__c, Account__r.Name, Account__r.CurrencyIsoCode,Contact__c, ECOM_Punchout_Is_Enabled__c
        FROM ERP_Address__c
        WHERE ERP_Marked_for_Deletion__c = false 
        AND RecordType.DeveloperName = 'Default'
        AND ECOM_Review_Status__c = 'Approved'
        AND ECOM_Punchout_Is_Enabled__c = true
        AND ((Address_Type__c IN ('Sold To','Ship To') AND Master_Address__r.External_Id__c = :configRec.External_Id__c AND Target_Address__r.External_Id__c =: configRec.External_Id__c AND ERP_Sales_Org__c = :configRec.ECOM_Punchout_Sales_Org__c)
        OR (Address_Type__c IN  ( 'Payer' ) AND Master_Address__r.External_Id__c =:configRec.External_Id__c AND Target_Address__r.External_Id__c =  :configRec.ECOM_Punchout_Default_Payer__c AND ERP_Sales_Org__c = :configRec.ECOM_Punchout_Sales_Org__c))
        LIMIT 49999 ];
        return punchoutAddresses;
    }
    
    // RWPS - RWPS-5776 - ENDS
}