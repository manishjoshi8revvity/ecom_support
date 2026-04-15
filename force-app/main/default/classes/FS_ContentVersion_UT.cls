@IsTest
private class FS_ContentVersion_UT {

    @TestSetup
    static void setupTestData() {
        FS_TestDataFactory.createDefaultOperatingHours();
    }

    @IsTest
    static void testFileAttachmentEvents() {

        Account acct = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
        Contact cont = FS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = FS_TestDataFactory.createTestProduct('TestProduct', '106018','MFT');
        Schema.Location loc = FS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
        Asset ip = FS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);
        WorkOrder wo = FS_TestDataFactory.createWO(ip, cont);
        wo.SAP_Notification_ID__c = 'SNOT100101';
        update wo;

        WorkOrder testWo = [SELECT Id, WorkOrderNumber FROM WorkOrder LIMIT 1];
        //System.assertNotEquals(null, testWo, 'Work Order just created should be found');

        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test-File-' + testWo.WorkOrderNumber + '-Ending-Stuff.TXT';
        cv.PathOnClient = 'test';
        cv.VersionData = EncodingUtil.base64Decode(EncodingUtil.urlEncode('Simple text file test','UTF-8'));
        insert cv;

        // Query cv to get contentDocumentId ????
        ContentVersion testCv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        System.debug('testCv.contentDocumentId: ' + testCv.ContentDocumentId);

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = testCv.ContentDocumentId;
        cdl.LinkedEntityId = testWo.Id;
        //cdl.ShareType = 'I';

        insert cdl;

        cv.VersionData = EncodingUtil.base64Decode(EncodingUtil.urlEncode('UPDATED text file test','UTF-8'));
        update cv;

    }

}