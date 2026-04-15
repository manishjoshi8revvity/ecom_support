/**************************************************************

* 1. Jira Ticket(s) that relates to this class
*  
*
* 2. Description - This is a test class
*
* 3. Objects referenced
*    - SAP_Order_Summary__c
*	 

* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_SAPOrderSummaryRepo
 
* 6. Test Class Name:
*
* 7. Is @Invocable : No
*
* 8. Author Name(s):
*    - Sidak 2024.06.20 Updated testFindPunchoutSapOrderByOrderNumberAndZip parameter to contact email list, Added methods testFetchSAPOrderSummariesById, testFetchSAPOrderSummariesByEmail, testfFindSapOrderByOrderNumberAndZip, testGetSAPOrderItemTrackings, testGetProductsBasedOnPartnumber, testFetchSAPOrderByEmailAndSourceType
*    - Gaurav 2025.07.28 Added testFetchSAPOrdersByEmail to increase code coverage - RWPS-3741
*    - Sachin Vispute 2025.10.28 : Added methods : testFetchSAPOrderForWebUsers, testFetchSAPOrderForPunchoutUsers - RWPS-4881
*    - Sachin Vispute 2025.11.06 : Updated method : testFetchSAPOrderForPunchoutUsers, Created : testFetchSAPOrderForWebPunchoutUsers - RWPS-4881
*    - Sachin Vispute 2025.11.26 : Updated method : testFetchSAPOrderForPunchoutUsers, testFetchSAPOrderForWebPunchoutUsers - RWPS-5094
*    - Sachin Vispute 2025.12.16 : Created methods : testFetchSAPOrdersForRecentOrders, testFetchSAPOrdersForFrequentOrders - RWPS-5507
*************************************************************/
@isTest
public class ECOM_SAPOrderSummaryRepo_Test {

    @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
    }
    


    @isTest
    static void testFindPunchoutSapOrderByOrderNumberAndZip() {
        // Test data
        String contactEmail = 'test@example.com';
        String orderNumber = '123ABC';
        String zipCode = '12345';
        List<String> contactEmailList = new List<String>{contactEmail};

        // Create some sample SAP_Order_Summary__c records
        SAP_Order_Summary__c orderSummary1 = new SAP_Order_Summary__c(
            Contact_Email__c = contactEmail,
            Order_Number__c = 123,
            Customer_PO_Number__c = orderNumber,
            Ship_To_Address_Postal_Code__c = zipCode
            // Set other required fields
        );
        // Add more SAP_Order_Summary__c records as needed

        insert new List<SAP_Order_Summary__c>{orderSummary1};
        // Insert more SAP_Order_Summary__c records into the database

        // Call the method to test
        List<SAP_Order_Summary__c> result = ECOM_SAPOrderSummaryRepo.findPunchoutSapOrderByOrderNumberAndZip(contactEmailList, orderNumber, zipCode);

        // Assert the results
       /* System.assertEquals(1, result.size()); // Adjust based on the number of SAP_Order_Summary__c records in your test data
        SAP_Order_Summary__c orderSummary = result[0];
        System.assertEquals(contactEmail, orderSummary.Contact_Email__c);
        System.assertEquals(orderNumber, orderSummary.Customer_PO_Number__c);
        System.assertEquals(zipCode, orderSummary.Ship_To_Address_Postal_Code__c);*/
     
	}
    
    @isTest
    static void testFetchSAPOrderSummariesById() {
        // Test data
        String contactEmail = 'test@example.com';
        String orderNumber = '123ABC';
        String zipCode = '12345';
        List<String> contactEmailList = new List<String>{contactEmail};

        // Create some sample SAP_Order_Summary__c records
        SAP_Order_Summary__c orderSummary1 = new SAP_Order_Summary__c(
            Contact_Email__c = contactEmail,
            Order_Number__c = 123,
            Customer_PO_Number__c = orderNumber,
            Ship_To_Address_Postal_Code__c = zipCode
            // Set other required fields
        );
        // Add more SAP_Order_Summary__c records as needed

        insert new List<SAP_Order_Summary__c>{orderSummary1};
        Set<String> summaryIds = new Set<String>{orderSummary1.Id};
        // Insert more SAP_Order_Summary__c records into the database

        // Call the method to test
        List<SAP_Order_Summary__c> result = ECOM_SAPOrderSummaryRepo.fetchSAPOrderSummariesById(summaryIds);
     
	}
    
    @isTest
    static void testFetchSAPOrderSummariesByEmail() {
        // Test data
        String contactEmail = 'test@example.com';
        String orderNumber = '123ABC';
        String zipCode = '12345';
        Date startDate = System.today();
        Date endDate = System.today();
        List<String> contactEmailList = new List<String>{contactEmail};

        // Create some sample SAP_Order_Summary__c records
        SAP_Order_Summary__c orderSummary1 = new SAP_Order_Summary__c(
            Contact_Email__c = contactEmail,
            Order_Number__c = 123,
            Customer_PO_Number__c = orderNumber,
            Ship_To_Address_Postal_Code__c = zipCode
            // Set other required fields
        );
        // Add more SAP_Order_Summary__c records as needed

        insert new List<SAP_Order_Summary__c>{orderSummary1};
        // Insert more SAP_Order_Summary__c records into the database

        // Call the method to test
        List<SAP_Order_Summary__c> result = ECOM_SAPOrderSummaryRepo.fetchSAPOrderSummariesByEmail(contactEmailList,startDate,endDate);
     
	}
    
    @isTest
    static void testfFindSapOrderByOrderNumberAndZip() {
        // Test data
        String contactEmail = 'test@example.com';
        String orderNumber = '123ABC';
        String zipCode = '12345';
        List<String> contactEmailList = new List<String>{contactEmail};

        // Create some sample SAP_Order_Summary__c records
        SAP_Order_Summary__c orderSummary1 = new SAP_Order_Summary__c(
            Contact_Email__c = contactEmail,
            Order_Number__c = 123,
            Customer_PO_Number__c = orderNumber,
            Ship_To_Address_Postal_Code__c = zipCode
            // Set other required fields
        );
        // Add more SAP_Order_Summary__c records as needed

        insert new List<SAP_Order_Summary__c>{orderSummary1};
        // Insert more SAP_Order_Summary__c records into the database

        // Call the method to test
        List<SAP_Order_Summary__c> result = ECOM_SAPOrderSummaryRepo.findSapOrderByOrderNumberAndZip(contactEmailList,orderNumber,zipCode);
     
	}
    
    @isTest
    static void testGetSAPOrderItemTrackings() {
        // Test data
        String contactEmail = 'test@example.com';
        String orderNumber = '123ABC';
        String zipCode = '12345';

        // Create some sample SAP_Order_Summary__c records
        SAP_Order_Summary__c orderSummary1 = new SAP_Order_Summary__c(
            Contact_Email__c = contactEmail,
            Order_Number__c = 123,
            Customer_PO_Number__c = orderNumber,
            Ship_To_Address_Postal_Code__c = zipCode
            // Set other required fields
        );
        // Add more SAP_Order_Summary__c records as needed

        insert new List<SAP_Order_Summary__c>{orderSummary1};
        Set<String> itemIds = new Set<String>{'Test'};
        // Insert more SAP_Order_Summary__c records into the database

        // Call the method to test
        List<SAP_Order_Item_Tracking__c> result = ECOM_SAPOrderSummaryRepo.getSAPOrderItemTrackings(itemIds);
     
	}
    
    @isTest
    static void testGetProductsBasedOnPartnumber() {
        // Test data
        String contactEmail = 'test@example.com';
        String orderNumber = '123ABC';
        String zipCode = '12345';
        Date startDate = System.today();
        Date endDate = System.today();
        List<String> contactEmailList = new List<String>{contactEmail};

        // Create some sample SAP_Order_Summary__c records
        SAP_Order_Summary__c orderSummary1 = new SAP_Order_Summary__c(
            Contact_Email__c = contactEmail,
            Order_Number__c = 123,
            Customer_PO_Number__c = orderNumber,
            Ship_To_Address_Postal_Code__c = zipCode
            // Set other required fields
        );
        // Add more SAP_Order_Summary__c records as needed

        insert new List<SAP_Order_Summary__c>{orderSummary1};
        Set<String> partNumbers = new Set<String>{'Test'};
        // Insert more SAP_Order_Summary__c records into the database

        // Call the method to test
        List<Product2> result = ECOM_SAPOrderSummaryRepo.getProductsBasedOnPartnumber(partNumbers);
     
	}
    
    @isTest
    static void testFetchSAPOrderByEmailAndSourceType() {
        // Test data
        String contactEmail = 'test@example.com';
        String orderNumber = '123ABC';
        String zipCode = '12345';
        Date startDate = System.today();
        Date endDate = System.today();
        List<String> contactEmailList = new List<String>{contactEmail};
        List<String> sourceTypes = new List<String>{'Test'};

        // Create some sample SAP_Order_Summary__c records
        SAP_Order_Summary__c orderSummary1 = new SAP_Order_Summary__c(
            Contact_Email__c = contactEmail,
            Order_Number__c = 123,
            Customer_PO_Number__c = orderNumber,
            Ship_To_Address_Postal_Code__c = zipCode
            // Set other required fields
        );
        // Add more SAP_Order_Summary__c records as needed

        insert new List<SAP_Order_Summary__c>{orderSummary1};
        // Insert more SAP_Order_Summary__c records into the database

        // Call the method to test
        List<SAP_Order_Summary__c> result = ECOM_SAPOrderSummaryRepo.fetchSAPOrderByEmailAndSourceType(contactEmailList,sourceTypes,startDate,endDate);
     
	}

    @isTest
    static void testFetchSAPOrdersByEmail() {
        // Test data
        String contactEmail = 'test@example.com';
        String orderNumber = '123ABC';
        String zipCode = '12345';
        Date startDate = System.today();
        Date endDate = System.today();
        List<String> contactEmailList = new List<String>{contactEmail};
        List<String> sourceTypes = new List<String>{'Test'};

        // Create some sample SAP_Order_Summary__c records
        SAP_Order_Summary__c orderSummary1 = new SAP_Order_Summary__c(
            Contact_Email__c = contactEmail,
            Order_Number__c = 123,
            Customer_PO_Number__c = orderNumber,
            Ship_To_Address_Postal_Code__c = zipCode
            // Set other required fields
        );
        // Add more SAP_Order_Summary__c records as needed

        insert new List<SAP_Order_Summary__c>{orderSummary1};
        // Insert more SAP_Order_Summary__c records into the database
        String selectedEmailType='Contact Email';// 'Ship To Email', 'Contact Email', or 'BOTH'
        List<String> alternateEmailList=new List<String>(); //RWPS-4082
        

        // Call the method to test
        List<SAP_Order_Summary__c> result = ECOM_SAPOrderSummaryRepo.fetchSAPOrdersByEmail(contactEmailList,selectedEmailType,alternateEmailList,contactEmail);
     
	}

    /**
     * RWPS-4881
     * @description Test method to verify the method 'fetchSAPOrderForWebUsers' from 'ECOM_SAPOrderSummaryRepo'
     * @author Sachin Vispute 2025.10.28
     */
    @isTest
    static void testFetchSAPOrderForWebUsers() {
        // Test data
        String contactEmail = 'test@example.com';
        String orderNumber = '123ABC';
        String zipCode = '12345';
        List<String> contactEmailList = new List<String>{contactEmail};

        // Create some sample SAP_Order_Summary__c records
        SAP_Order_Summary__c orderSummary1 = new SAP_Order_Summary__c(
            Contact_Email__c = contactEmail,
            Order_Number__c = 123,
            Customer_PO_Number__c = orderNumber,
            Ship_To_Address_Postal_Code__c = zipCode
            // Set other required fields
        );
        // Add more SAP_Order_Summary__c records as needed
        insert new List<SAP_Order_Summary__c>{orderSummary1};
        // Insert more SAP_Order_Summary__c records into the database
        // Call the method to test
        List<SAP_Order_Summary__c> result = ECOM_SAPOrderSummaryRepo.fetchSAPOrderForWebUsers(contactEmailList,'12');
	}

    /**
     * RWPS-4881
     * @description Test method to verify the method 'fetchSAPOrderForPunchoutUsers' from 'ECOM_SAPOrderSummaryRepo'
     * @author Sachin Vispute 2025.10.28
     */
    @isTest
    static void testFetchSAPOrderForPunchoutUsers() {
        // Test data
        String contactEmail = 'test@example.com';
        String orderNumber = '123ABC';
        String zipCode = '12345';
        Date startDate = System.today();
        Date endDate = System.today();
        List<String> contactEmailList = new List<String>{contactEmail};
        List<String> sourceTypes = new List<String>{'Test'};

        // Create some sample SAP_Order_Summary__c records
        SAP_Order_Summary__c orderSummary1 = new SAP_Order_Summary__c(
            Contact_Email__c = contactEmail,
            Order_Number__c = 123,
            Customer_PO_Number__c = orderNumber,
            Ship_To_Address_Postal_Code__c = zipCode
            // Set other required fields
        );
        // Add more SAP_Order_Summary__c records as needed

        insert new List<SAP_Order_Summary__c>{orderSummary1};
        // Insert more SAP_Order_Summary__c records into the database
        String selectedEmailType='Contact Email';// 'Ship To Email', 'Contact Email', or 'BOTH'
        List<String> alternateEmailList=new List<String>(); //RWPS-4082

        // Call the method to test
        List<SAP_Order_Summary__c> result = ECOM_SAPOrderSummaryRepo.fetchSAPOrderForPunchoutUsers(contactEmailList,selectedEmailType,alternateEmailList,contactEmail,'12', new List<String>(), new List<String>()); //RWPS-5094
	}

    /**
     * RWPS-5094
     * @description Test method to verify the method 'fetchSAPOrderForPunchoutUsers' from 'ECOM_SAPOrderSummaryRepo'
     * @author Sachin Vispute 2025.11.06
     */
    @isTest
    static void testFetchSAPOrderForWebPunchoutUsers() {
        // Test data
        String contactEmail = 'test@example.com';
        String orderNumber = '123ABC';
        String zipCode = '12345';
        Date startDate = System.today();
        Date endDate = System.today();
        List<String> contactEmailList = new List<String>{contactEmail};
        List<String> sourceTypes = new List<String>{'Test'};

        // Create some sample SAP_Order_Summary__c records
        SAP_Order_Summary__c orderSummary1 = new SAP_Order_Summary__c(
            Contact_Email__c = contactEmail,
            Order_Number__c = 123,
            Customer_PO_Number__c = orderNumber,
            Ship_To_Address_Postal_Code__c = zipCode
        );

        insert new List<SAP_Order_Summary__c>{orderSummary1};
        String selectedEmailType='BOTH';
        List<String> alternateEmailList= new List<String>{'test@test.com'};

        List<String> orderTypesList = System.Label.ECOM_OrderTypes_Punchout.split(',');

        // Call the method to test
        List<SAP_Order_Summary__c> result = ECOM_SAPOrderSummaryRepo.fetchSAPOrderForPunchoutUsers(contactEmailList,selectedEmailType,alternateEmailList,contactEmail,'12', orderTypesList, new List<String>()); //RWPS-5094
	}

    /**
     * RWPS-5507
     * @description Test method to verify the method 'fetchSAPOrderForPunchoutUsers' from 'ECOM_SAPOrderSummaryRepo'
     * @author Sachin Vispute 2025.11.06
     */
    @isTest
    static void testFetchSAPOrdersForRecentOrders() {
        User testUser = [Select Id, Email, LastName, contactId, AccountId, ECOM_Is_Punchout_User__c From User ORDER BY CREATEDDATE DESC LIMIT 1];
        testUser.ECOM_Is_Punchout_User__c = true;
        update testUser;
        System.runAs(new User(Id=UserInfo.getUserId())) {
            List<Contact> contactList = [SELECT Id, Default_Ship_to_ERP_Address__c, Default_Bill_to_ERP_Address__c FROM Contact WHERE Id =: testUser.ContactId LIMIT 1];
            if (contactList.isEmpty() == false) {
                List<ERP_Address__c> addressList = [SELECT Id, Master_Address__c FROM ERP_Address__c WHERE Id =: contactList[0].Default_Bill_to_ERP_Address__c LIMIT 1];
                if (addressList.isEmpty() == false && addressList[0].Master_Address__c != null) {
                    update new ERP_Address__c(Id = addressList[0].Master_Address__c, ECOM_Punchout_User_Email__c = ECOM_Constant.SHIP_TO_CONTACT_EMAIL_BOTH, Ecom_Punchout_Additional_Email_Address__c = testUser.Email);
                    update new Contact(Id = contactList[0].Id, Default_Ship_to_ERP_Address__c = contactList[0].Default_Bill_to_ERP_Address__c);
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
            Test.startTest();
            List<String> emails = new List<String>();
            emails.add(testUser.Email);
            Type userService = Type.forName(ECOM_Constant.USER_Service);
            ECOM_IUserService userServiceInstance = (ECOM_IUserService)userService.newInstance();
            User user = userServiceInstance.getUserByUserId();
            String additionalEmails = '';//RWPS-5777
            //user.Contact.Default_Ship_to_ERP_Address__r?.Master_Address__r?.Ecom_Punchout_Additional_Email_Address__c;
            String selectedEmailType  = '';
           // user?.Contact.Default_Ship_to_ERP_Address__r?.Master_Address__r?.ECOM_Punchout_User_Email__c;
            List<String> alternateEmailList = new List<String>();
            if (String.isNotBlank(additionalEmails)) {
                for (String email : additionalEmails.split(',')) {
                    email = email.trim();
                    if (String.isNotBlank(email)) {
                        alternateEmailList.add(email);
                    }
                }
            }
            List<String> orderTypesList = new List<String>();
            List<String> poTypesList = new List<String>();
            List<C_META_Storefront_Configuration__mdt> storeFrontConfigurations = ECOM_CustomMetadataRepo.fetchStoreConfigMdtBasedOnModuleName('POTypesPunchout');
            storeFrontConfigurations.add(ECOM_CustomMetadataRepo.fetchStoreConfigMdtBasedOnModuleName('PunchoutOrderTypes')[0]);
            poTypesList = storeFrontConfigurations[0].Value__c.split(',');
            orderTypesList = storeFrontConfigurations[1].Value__c.split(',');
            List<SAP_Order_Summary__c> sapOrderSummaryList = ECOM_SAPOrderSummaryRepo.fetchSAPOrders(emails, selectedEmailType, alternateEmailList, orderTypesList,
                poTypesList, ECOM_Constant.RECENTLY_PURCHASED_PRODUCTS, true, null, null);
            Test.stopTest();
            System.assertnotEquals(null,sapOrderSummaryList,'expected order should not be null');
        }
	}

    /**
     * RWPS-5507
     * @description Test method to verify the method 'fetchSAPOrderForPunchoutUsers' from 'ECOM_SAPOrderSummaryRepo'
     * @author Sachin Vispute 2025.11.06
     */
    @isTest
    static void testFetchSAPOrdersForFrequentOrders() {
        User testUser = [Select Id, Email, LastName, contactId, AccountId, ECOM_Is_Punchout_User__c From User ORDER BY CREATEDDATE DESC LIMIT 1];
        testUser.ECOM_Is_Punchout_User__c = true;
        update testUser;
        System.runAs(new User(Id=UserInfo.getUserId())) {
            List<Contact> contactList = [SELECT Id, Default_Ship_to_ERP_Address__c, Default_Bill_to_ERP_Address__c FROM Contact WHERE Id =: testUser.ContactId LIMIT 1];
            if (contactList.isEmpty() == false) {
                List<ERP_Address__c> addressList = [SELECT Id, Master_Address__c FROM ERP_Address__c WHERE Id =: contactList[0].Default_Bill_to_ERP_Address__c LIMIT 1];
                if (addressList.isEmpty() == false && addressList[0].Master_Address__c != null) {
                    update new ERP_Address__c(Id = addressList[0].Master_Address__c, ECOM_Punchout_User_Email__c = ECOM_Constant.SHIP_TO_EMAIL, Ecom_Punchout_Additional_Email_Address__c = testUser.Email);
                    update new Contact(Id = contactList[0].Id, Default_Ship_to_ERP_Address__c = contactList[0].Default_Bill_to_ERP_Address__c);
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
            Test.startTest();
            List<String> emails = new List<String>();
            emails.add(testUser.Email);
            Type userService = Type.forName(ECOM_Constant.USER_Service);
            ECOM_IUserService userServiceInstance = (ECOM_IUserService)userService.newInstance();
            User user = userServiceInstance.getUserByUserId();
             String additionalEmails='';
             String selectedEmailType ='';//RWPS-5777
            //List<SAP_Order_Summary__c> sapOrderSummaryList = ECOM_SAPOrderSummaryRepo.fetchSAPRecentOrdersByEmail(emails);
           // String additionalEmails = user.Contact.Default_Ship_to_ERP_Address__r?.Master_Address__r?.Ecom_Punchout_Additional_Email_Address__c;
          //  String selectedEmailType  = user?.Contact.Default_Ship_to_ERP_Address__r?.Master_Address__r?.ECOM_Punchout_User_Email__c;
            List<String> alternateEmailList = new List<String>();
            if (String.isNotBlank(additionalEmails)) {
                for (String email : additionalEmails.split(',')) {
                    email = email.trim();
                    if (String.isNotBlank(email)) {
                        alternateEmailList.add(email);
                    }
                }
            }
            List<String> orderTypesList = new List<String>();
            List<String> poTypesList = new List<String>();
            List<C_META_Storefront_Configuration__mdt> storeFrontConfigurations = ECOM_CustomMetadataRepo.fetchStoreConfigMdtBasedOnModuleName('POTypesPunchout');
            storeFrontConfigurations.add(ECOM_CustomMetadataRepo.fetchStoreConfigMdtBasedOnModuleName('PunchoutOrderTypes')[0]);
            poTypesList = storeFrontConfigurations[0].Value__c.split(',');
            orderTypesList = storeFrontConfigurations[1].Value__c.split(',');
            Date startDate = Date.today().addYears(-1);
            Date endDate = Date.today();
            List<SAP_Order_Summary__c> sapOrderSummaryList = ECOM_SAPOrderSummaryRepo.fetchSAPOrders(emails, selectedEmailType, alternateEmailList, orderTypesList,
                poTypesList, ECOM_Constant.FREQUENTLY_PURCHASED_PRODUCTS, true, startDate, endDate);
            Test.stopTest();
            System.assertnotEquals(null,sapOrderSummaryList,'expected order should not be null');
        }
	}
}