/**
 * Created by tony on 11/9/20.
 *
 * Updates:
 * 01/23/2023   tony    ITSVMX-1123 Custom Metadata types - Service Alert CRC Email Address updates on new CRC email addresses
 */

@IsTest
private class FS_ServiceAlert_UT {

    @TestSetup
    static void testData() {
        // create new contact
        Contact contact = new Contact();
        contact.FirstName = 'Needed for';
        contact.LastName = 'Service Alert Email Notification';
        contact.Email = 'test@someplace.com.invalid';

        insert contact;
        System.debug('Inserted Contact: ' + contact);
    }

    @IsTest
    static void test_newUpdateServiceAlerts() {
        FS_TestDataFactory.createDefaultOperatingHours();

        User usr =[SELECT Id FROM User WHERE Id=:UserInfo.getUserId()];
//        usr.Region__c = 'AMERICAS';
//        usr.Sub_Region__c = 'NORTH AMERICA';
//        update usr;

        Product2 prod = FS_TestDataFactory.createTestProduct('TestProd', 'Consumable', 'GC');
        System.debug('inserted prod: ' + prod);

        Account acct = FS_TestDataFactory.createTestAccount('TestAccount', 'acct1234');

        Schema.Location loc = FS_TestDataFactory.createTestLocation(acct, 'TestLoc', 'loc1234', '122');

        Asset installedProduct = FS_TestDataFactory.createIP('Serial1', acct, loc, 'Model1234', prod);
        System.debug('inserted installedProduct: ' + installedProduct);

        Test.startTest();

        FS_ServiceAlert__c serviceAlert1 = new FS_ServiceAlert__c(
                Quality_Comments__c = 'Test Service Alert 1',
                Asset__c = installedProduct.Id // Added so we can test Product Line of 'GC'
        );
        System.debug('inserting Service Alert: ' + serviceAlert1);
        insert serviceAlert1;

        // create Service Alert where user is not a Technician
        FS_ServiceAlert__c serviceAlert2 = new FS_ServiceAlert__c(
                Quality_Comments__c = 'Test Service Alert 2'
        );
        System.debug('inserting Service Alert: ' + serviceAlert2);
        insert serviceAlert2;

        Test.stopTest();
    }

    @IsTest
    static void test_newUpdatePath() {
        User usr =[SELECT Id FROM User WHERE Id=:UserInfo.getUserId()];
//        usr.Region__c = 'AMERICAS';
//        usr.Sub_Region__c = 'NORTH AMERICA';
//        update usr;

        // create Service Alert
        FS_ServiceAlert__c serviceAlert1 = new FS_ServiceAlert__c(
                Quality_Comments__c = 'Test Service Alert 1',
                Record_Type__c = 'Replacement Alert'
        );
        System.debug('inserting Service Alert: ' + serviceAlert1);
        insert serviceAlert1;

        // Verify Results
        Test.startTest();
        FS_ServiceAlert__c sa1 = [
                SELECT Id, Technician__c, OwnerId, Status__c, Stage__c
                FROM FS_ServiceAlert__c
                WHERE Id = :serviceAlert1.Id
        ];
        System.debug('sa1: ' + sa1);
        // Check that Stage is not set
        Assert.isTrue(sa1.Stage__c == null);

        sa1.Status__c = 'No Activity';
        update sa1;

        sa1 = [
                SELECT Id, Technician__c, OwnerId, Status__c, Stage__c
                FROM FS_ServiceAlert__c
                WHERE Id = :serviceAlert1.Id
        ];
        System.debug('sa1 updated: ' + sa1);
        // Check that Stage has changed
        // 12/3/20 tony - changed to Investigating since someone changed the mapping
        System.assertEquals('Investigating', sa1.Stage__c);

        // Test sendServiceAlertNotifications()
        sa1.Status__c = 'Sent to CRC';
        update sa1;

        Test.stopTest();
    }
}