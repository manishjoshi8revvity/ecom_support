@IsTest(SeeAllData=false)
public class FS_InventoryManager_UT
{
    @IsTest
    static void createTestData()
    {
        Account acct = FS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001');
        Contact cont = FS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');

        // Insert source location
        Schema.Location sloc = new Schema.Location(
                Name='Test source Location',
                Street__c='123 street',
                City__c='123 city',
                State__c='123 state',
                Zip__c='12345',
                Country__c='US',IsInventoryLocation=true
                );
        insert sloc;
        // Insert destination location
        Schema.Location dloc = new Schema.Location(
                Name='Test destination Location',
                Street__c='456 street',
                City__c='456 city',
                State__c='456 state',
                Zip__c='45678',
                Country__c='US',IsInventoryLocation=true
                );
        insert dloc;

        Product2 p1 = FS_TestDataFactory.createTestProduct('Test Product1', 'TPRD1001', 'AA');
        Product2 p2 = FS_TestDataFactory.createTestProduct('Test Product2', 'TPRD1002', 'AA');
        p2.Enable_Serialized_Tracking__c=true;
        update p2;

        // insert Product Stock
//        ProductItem ps = new ProductItem(
//                LocationId=sloc.Id,
//                Product2Id = p1.Id,
//                QuantityOnHand=10,
//                CompletedTxnNum__c='tran');
//        insert ps;
//
//        // insert Product Serial
//        ProductItem ss = new ProductItem(
//                LocationId=sloc.Id,
//                Product2Id = p2.Id,
//                QuantityOnHand=2,
//                SerialNumber='ABC123',
//                Serial_Tracking_Type__c='Batch',
//                CompletedTxnNum__c='tran');
//        insert ss;
//
//        // update Product stock
//        ps.CompletedTxnNum__c='tran1';
//        update ps;

        ProductItem ps = FS_TestDataFactory.createTestProductStock(sloc, p1, null, 10);

        ProductItem ss_non = FS_TestDataFactory.createTestSerializedProductStock(sloc, p2, 3, null, null);
        ProductItem ss_s1 = FS_TestDataFactory.createTestSerializedProductStock(sloc, p2, 2, 'Batch', 'B123456');
        ProductItem ss_s2 = FS_TestDataFactory.createTestSerializedProductStock(sloc, p2, 1, 'Serial', 'S123456');

        ss_non.CompletedTxnNum__c = 'ABC123';
        ss_s1.CompletedTxnNum__c = 'ABC123';
        ss_s2.CompletedTxnNum__c = 'ABC123';
        update new List<ProductItem> { ss_non, ss_s1, ss_s2 };

        // insert Stock Transfer
        ProductTransfer st = new ProductTransfer(
                SourceLocationId=sloc.Id,
                DestinationLocationId=dloc.Id,
                QuantitySent=1);
        insert st;

        // Update Stock Transfer
        st.Status='Submitted';
        update st;

        FS_IntegrationError__c err1 = new FS_IntegrationError__c();
        err1.RelatedElementType__c = 'StockTransferId';
        err1.RelatedElementIdentifier__c = st.Id;
        err1.ErrorMessage__c = 'Testing Product Transfer Errors';
        insert err1;

        err1.ErrorMessage__c += ' .. more text';
        update err1;

        delete err1;

        // insert Inventory Count
        FS_InventoryCount__c ic = new FS_InventoryCount__c();
        insert ic;

        // Update Inventory Count
        ic.Status__c='Submitted';
        update ic;
    }
}