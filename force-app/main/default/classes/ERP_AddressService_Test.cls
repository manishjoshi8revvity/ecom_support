/**************************************************************

* 1. Jira Ticket(s) that relates to this class
*  
* 2. Description - This class is a test class for ERP_AddressService.
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
*   -Ecom_Testutil
*
* 6. Test Class Name:
*    -None
*
* 7. Is @Invocable : No
*
* 8. Author Name(s):
*    - Manoj 2023.11.19
*    - Sidak 2024.06.06 Addded methods testGetMasterERPAddressModelForPunchoutUser, testGetPunchoutAddressesForERPAddressModel
*    - Sidak 2024.07.04 Addded method testUpdateERPRelationshipsBasedOnACR
*    - Manish Joshi 2025.07.22 - Updated method testFetchERPAddresses - RWPS-3657
*    - Manish Joshi 2025.10.27 Updated method fetchERPAddressesBySapNumber - RWPS-4915
*************************************************************/
@isTest
public class ERP_AddressService_Test {
    @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
    }

    public static ERP_Address__c createErpaddress(Account acc,Contact con, ERP_Address__c parent, String addressType, String externalId){

        ERP_Address__c erpAddress = new ERP_Address__c();
       //erpAddress.Contact__c = con.Id;
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
        erpAddress.ECOM_Review_Status__c = 'Approved';
        erpAddress.External_Id__c = externalId;
        //erpAddress.ECOM_Punchout_Customer_Id__c ='CITRA';
        //insert erpAddress;
        return erpAddress;
    }
    
    static void testfetchERPAddressesByContact(){
       
        Account acc = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1 ];
        Contact con = [Select Id ,LastName,AccountId From Contact Where AccountId =:acc.Id ORDER BY CREATEDDATE DESC LIMIT 1];
        
         User testUser=[SELECT Id,Name,Contact.ECOM_CountryProvided__c FROM User Where ContactId =:con.Id ORDER BY CREATEDDATE DESC LIMIT 1];
        System.runAs(testUser)
        {
            test.startTest();
            List<ERP_Relationship__c> erpRlist = ERP_AddressService.fetchERPRelationshipsByContactId(con.Id);
            test.stopTest();
        }
    }
     @isTest
    static void testFetchERPAddresses() {
        // Create test data (customize as needed)
        User testUser = [SELECT Id,Name,ContactId,Contact.ECOM_CountryProvided__c,Contact.Default_Bill_to_ERP_Address__c,Contact.Default_Sold_to_ERP_Address__c,
                         Contact.Default_Ship_to_ERP_Address__c,Contact.Default_Ship_to_ERP_Address__r.ECOM_Review_Status__c,
                         FirstName,LastName,Contact.Default_Ship_to_ERP_Address__r.Master_Address__c,Contact.Default_Invoice_ERP_Address__c FROM User ORDER BY CREATEDDATE DESC LIMIT 1];// RWPS-3657
        Contact con = [SELECT Id,ECOM_CountryProvided__c FROM Contact WHERE Id =: testUser.ContactId];
        con.ECOM_CountryProvided__c='United States';
        update con;
        String accountId =  [SELECT Id, AccountId
                                 FROM AccountContactRelation
                                 WHERE ContactId=:testUser.contactId
                                 LIMIT 1].AccountId;
        List<ERP_Address__c> dataVal= ECOM_TestUtil.createErpaddressSoldTo(accountId);
        insert dataVal;
        //RWPS-3657 - START
        String mockBody = JSON.serialize(new Map<String, Object>{
                'totalSize' => 1,
                'done' => true,
                'records' => new List<Map<String, Object>>{
                    new Map<String, Object>{
                        'Id' => '0HzXXXX',
                        'ContactId' => testUser.ContactId,
                        'Field' => 'Default_Bill_to_ERP_Address__c',
                        'OldValue' => 'Payer--',
                        'NewValue' => 'Payer--0100123456',
                        'CreatedDate' => '2025-07-01T10:00:00.000+0000'
                    }
                }
            });
        System.runAs(testUser)
        {
            ECOM_MockHttpResponseGenerator mockResponse = new ECOM_MockHttpResponseGenerator(200, 'OK', mockBody, new Map<String,String>());
        	Test.setMock(HttpCalloutMock.class, mockResponse);// RWPS-3657 - END
            Test.startTest();
            List<ECOM_MyAccountModel> result = ERP_AddressService.fetchERPAddresses(testUser);
            Test.stopTest();
            System.assertNotEquals(null, result);
        }
    }
    
    @isTest
    static void testAddressServiceMethods()
    {
        Account acc = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1 ];
        Contact con = [Select Id ,LastName,AccountId From Contact Where AccountId =:acc.Id ORDER BY CREATEDDATE DESC LIMIT 1];
        User testUser = [SELECT Id,Name,ContactId,Contact.ECOM_CountryProvided__c,Contact.Default_Bill_to_ERP_Address__c,
                         Contact.Default_Ship_to_ERP_Address__c,Contact.Default_Ship_to_ERP_Address__r.ECOM_Review_Status__c,
                         FirstName,LastName FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        List<String> testIdList = new List<String>();
        String erpId = [SELECT Id FROM ERP_Address__c ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        System.runAs(testUser)
        {
            test.startTest();
            ERP_AddressService obj = new ERP_AddressService();
            List<ERP_Address__c> resList = ERP_AddressService.getErpAddressBasedOnContactIdAndAddressType(con.Id,testIdList);
            resList = ERP_AddressService.getErpAddressBasedOnContactIdAddressTypeAndMasterId(con.Id,testIdList,'testmasterId');
            resList = ERP_AddressService.getErpAddressBasedOnContactIdAddressTypeAndMasterIds(con.Id,testIdList, new Set<String>{'testmasterId'});
            List<ECOM_MyAccountModel> acModel = ERP_AddressService.getErpModelBasedOnSoldTo(testUser,erpId,erpId);
            ERP_Address__c erpAddress = new ERP_Address__c();
            erpAddress.Contact__c = null;
            erpAddress.ERP_Account_Name__c = acc.Id;
            erpAddress.Address_Type__c = 'Sold To';
            erpAddress.Address_Street_Line_1__c = null;
            erpAddress.Address_City__c = null;
            erpAddress.apiState__c = null;
            erpAddress.Address_Postal_Code__c = null;
            erpAddress.apiCountry__c = null;
            erpAddress.ECOM_isEnabled__c = true;
            erpAddress.ERP_Sales_Org__c = 'EEU2';
            erpAddress.SAP_Name_1__c = 'testSAP';
            erpAddress.Account__c = acc.Id;
            insert erpAddress;
            ERP_AddressService.getErpModelBasedOnSoldTo(testUser,erpId,erpId);
            
            System.AssertNotEquals(null,acModel,'result should not be null');
            testIdList.add(erpId);
            Integer val = ERP_AddressService.fetchInProgressAddresses(testIdList);
            System.AssertNotEquals(null,val,'erp result should not be null');
            ERP_AddressService.fetchERPRelationshipsByContactId(con.Id);
            obj.fetchERPRelationshipsByERPAddress(con.Id,erpId);
            Set<String> srpSet = new Set<String>();
            srpSet.add(erpId);
            Map<Id,ERP_Address__c> response = ERP_AddressService.getTargetId(srpSet);
            ERP_AddressService.fetchERPAddressesByContact(testUser);
            List<ERP_Address__c> erpAddresses = [SELECT Id FROM ERP_Address__c ORDER BY CREATEDDATE DESC];
            ERP_AddressService.upsertERPAddresses(erpAddresses);
            ERP_AddressService.fetchERPAddressesById(erpId);
            
            ERP_AddressService.fetchERPAddressesBySapNumber(con.Id, testIdList,testIdList, 'salesOrg', 'domain',new List<String>());// RWPS-4915
            
            ERP_AddressService.fetchERPAddressesBySapNumber(con.Id,testIdList,testIdList,'USA');
            ERP_AddressService.fetchERPAddressesByDomain(testUser,'contactDomain','USA');
            ERP_AddressService.fetchERPAddressesBySoldTo(testUser, con.Id, 'soldToSAPNumber', 'contactDomain');
            test.stopTest();
        }
        
    }
   
 @isTest
    static void testAddressServiceMethodscase2()
    {
        Account acc = [SELECT Id FROM Account ORDER BY CREATEDDATE DESC LIMIT 1 ];
        Contact con = [Select Id ,LastName,AccountId From Contact Where AccountId =:acc.Id ORDER BY CREATEDDATE DESC LIMIT 1];
        User testUser = [SELECT Id,Name,ContactId,Contact.ECOM_CountryProvided__c,Contact.Default_Bill_to_ERP_Address__c,
                         Contact.Default_Ship_to_ERP_Address__c,Contact.Default_Ship_to_ERP_Address__r.ECOM_Review_Status__c,
                         FirstName,LastName, Contact.Default_Sold_to_ERP_Address__c,Contact.Default_Sold_to_ERP_Address__r.Target_Address__c,Contact.Default_Sold_to_ERP_Address__r.Target_Address__r.External_Id__c FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        List<String> testIdList = new List<String>();
        String erpId = [SELECT Id FROM ERP_Address__c ORDER BY CREATEDDATE DESC LIMIT 1].Id;
        System.runAs(testUser)
        {
            test.startTest();
            ERP_AddressService obj = new ERP_AddressService();
            List<ERP_Address__c> resList = ERP_AddressService.getErpAddressBasedOnContactIdAndAddressType(con.Id,testIdList);
            resList = ERP_AddressService.getErpAddressBasedOnContactIdAddressTypeAndMasterId(con.Id,testIdList,'testmasterId');
            resList = ERP_AddressService.getErpAddressBasedOnContactIdAddressTypeAndMasterIds(con.Id,testIdList, new Set<String>{'testmasterId'});
            List<ECOM_MyAccountModel> acModel = ERP_AddressService.getErpModelBasedOnSoldTo(testUser,erpId,erpId);
            ERP_Address__c erpAddress = new ERP_Address__c();
            erpAddress.Contact__c = null;
            erpAddress.ERP_Account_Name__c = acc.Id;
            erpAddress.Address_Type__c = 'Sold To';
            erpAddress.Address_Street_Line_1__c = null;
            erpAddress.Address_City__c = null;
            erpAddress.apiState__c = null;
            erpAddress.Address_Postal_Code__c = null;
            erpAddress.apiCountry__c = null;
            erpAddress.ECOM_isEnabled__c = true;
            erpAddress.ERP_Sales_Org__c = 'EEU2';
            erpAddress.SAP_Name_1__c = 'testSAP';
            erpAddress.SAP_Name_2__c = 'testSAP';
            erpAddress.SAP_Name_3__c = 'testSAP';
            erpAddress.SAP_Name_4__c = 'testSAP';
            erpAddress.Account__c = acc.Id;
            insert erpAddress;
            ERP_AddressService.getErpModelBasedOnSoldTo(testUser,erpAddress.Id,erpAddress.Id);
            erpAddress.ECOM_Review_Status__c ='Approved';
            update erpAddress;
            ERP_AddressService.getErpModelBasedOnSoldTo(testUser,erpAddress.Id,erpAddress.Id);
            //erpAddress.Master_Address__c = 'a1JDW000001DL282AG';
            //serpAddress.Target_Address__c = 'a1JDW000001DL282AG';
            update erpAddress;
             ERP_AddressService.getErpModelBasedOnSoldTo(testUser,erpAddress.Id,erpAddress.Id);
            
            System.AssertNotEquals(null,acModel,'result should not be null');
            testIdList.add(erpId);
            Integer val = ERP_AddressService.fetchInProgressAddresses(testIdList);
            System.AssertNotEquals(null,val,'erp result should not be null');
            ERP_AddressService.fetchERPRelationshipsByContactId(con.Id);
            obj.fetchERPRelationshipsByERPAddress(con.Id,erpId);
            Set<String> srpSet = new Set<String>();
            srpSet.add(erpId);
            Map<Id,ERP_Address__c> response = ERP_AddressService.getTargetId(srpSet);
            ERP_AddressService.fetchERPAddressesByContact(testUser);
            List<ERP_Address__c> erpAddresses = [SELECT Id FROM ERP_Address__c ORDER BY CREATEDDATE DESC];
            ERP_AddressService.upsertERPAddresses(erpAddresses);
            ERP_AddressService.fetchERPAddressesById(erpId);
            
            ERP_AddressService.fetchERPAddressesBySapNumber(con.Id, testIdList,testIdList, 'salesOrg', 'domain',new List<String>()); // RWPS-4915
            
            ERP_AddressService.fetchERPAddressesBySapNumber(con.Id,testIdList,testIdList,'USA');
            ERP_AddressService.fetchERPAddressesByDomain(testUser,'contactDomain','USA');
            ERP_AddressService.fetchERPAddressesBySoldTo(testUser, con.Id, 'soldToSAPNumber', 'contactDomain');
            test.stopTest();
        }
        
    }
    
    
    @isTest
    static void testGetMasterERPAddressModelForPunchoutUser() {
        // Create test data (customize as needed)
        User testUser = [SELECT Id,Name,ContactId,AccountId,Contact.ECOM_CountryProvided__c,Contact.Default_Bill_to_ERP_Address__c,
                         Contact.Default_Ship_to_ERP_Address__c,Contact.Default_Ship_to_ERP_Address__r.ECOM_Review_Status__c,
                         FirstName,LastName FROM User ORDER BY CREATEDDATE DESC LIMIT 1];      
        System.runAs(testUser)
        {   
            Test.startTest();
            ERP_AddressModel result = ERP_AddressService.getMasterERPAddressModelForPunchoutUser(testUser);
            Test.stopTest();
        }
    }
    
    @isTest
    static void testGetPunchoutAddressesForERPAddressModel() {
        // Create test data (customize as needed)
        User testUser = [SELECT Id,Name,ContactId,AccountId,Contact.ECOM_CountryProvided__c,Contact.Default_Bill_to_ERP_Address__c,
                         Contact.Default_Ship_to_ERP_Address__c,Contact.Default_Ship_to_ERP_Address__r.ECOM_Review_Status__c,
                         FirstName,LastName FROM User ORDER BY CREATEDDATE DESC LIMIT 1];      
        System.runAs(testUser)
        {   
            Test.startTest();
            ERP_AddressModel result = ERP_AddressService.getPunchoutAddressesForERPAddressModel('Test');
            Test.stopTest();
        }
    }
    
	@isTest
    static void testUpdateERPRelationshipsBasedOnACR() {
        // Create test data (customize as needed)
        User testUser = [SELECT Id,Name,ContactId,AccountId,Contact.ECOM_CountryProvided__c,Contact.Default_Bill_to_ERP_Address__c,
                         Contact.Default_Ship_to_ERP_Address__c,Contact.Default_Ship_to_ERP_Address__r.ECOM_Review_Status__c,
                         FirstName,LastName FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        String conId = testUser.ContactId;
        List<String> contactId = new List<String>();
        contactId.add(conId);
        Id deafultRecordypeId = Schema.SObjectType.ERP_Address__c.getRecordTypeInfosByName().get('Default').getRecordTypeId();
        
        ERP_Address__c erp = new ERP_Address__c();
        erp.Account__c = testUser.AccountId;
        erp.Name = 'Test';
        erp.Address_Type__c = 'Master';
        erp.RecordtypeId  = deafultRecordypeId;
        insert erp;
        
        ERP_Address__c erp2 = new ERP_Address__c();
        erp2.Account__c = testUser.AccountId;
        erp2.Name = 'Test';
        erp2.Address_Type__c = 'Ship To';
        erp2.Master_Address__c = erp.Id;
        erp.RecordtypeId  = deafultRecordypeId;
        insert erp2;
        
        String successResponseBody = '{"results":[{"addressId":"a1fO9000000kE82IAE","contactId":"003Qo00000JzRWfIAN","sapContactNumber":"0001944143"}]}';
        Test.setMock(HttpCalloutMock.class, new ECOM_MockHttpResponseGenerator(200, 'OK', successResponseBody, null));
        
        System.runAs(testUser)
        {   
            Test.startTest();
            ERP_AddressService.updateERPRelationshipsBasedOnACR(contactId);
            Test.stopTest();
        }
    }  
}