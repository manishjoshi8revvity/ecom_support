/**************************************************************
  * 1. Ticket(s) that relates to this class
  *    - ATEAM-2117
  *   
  *
  * 2. Description - Put detailed description here of what this class is used for procedurally
  *    This will be a tool that is added to FLOW so that we can capture Screenshots as part of a flow. 
  *
  *
  * 3. Objects referenced
  *    -Response__c
  *    -File
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None
  *
  * 5. Dependant Class(es):
  *    - ClassName
  *
  * 6. Test Class Name: ImageControllerTest
  *
  * 7. Is @Invocable (Yes or No):  Yes
  *
  * 8. Author Name(s): 
  *    - First Last & Updated Date(YYYY.MM.DD) example: Brad Durbin 2023.06.21
  *    - Brad Durbin 2024.09.16
  *    - First Last & Updated Date(YYYY.MM.DD)
  *
*************************************************************/

@IsTest
public class ImageControllerTest {

    @IsTest
    static void testSaveImageAndLinkToRecord() {
        // A.CLS TEMPLATE

        // Arrange: Set up test data and environment

        // 1. Create a test Response__c record (replace with any required or editable fields)
        Response__c testResponse = new Response__c(Response_username__c= 'Test Value'); // Use appropriate required fields
        insert testResponse;

        // 2. Set up the test data for the invocable method
        ImageController.RequestData requestData = new ImageController.RequestData();
        requestData.imageData = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA'; // Sample base64 string for testing
        requestData.imageTitle = 'Test Image';
        requestData.recordId = testResponse.Id; // Use the Response__c record Id

        List<ImageController.RequestData> requestDataList = new List<ImageController.RequestData>{requestData};

        // Act: Execute the method being tested

        // 1. Call the invocable method
        Test.startTest();
        List<String> fileUrls = ImageController.saveImageAndLinkToRecord(requestDataList);
        Test.stopTest();

        // Assert: Verify that the method worked as expected

        // 1. Assert that the file URL was returned
        System.assertNotEquals(null, fileUrls, 'Expected file URL list to be returned');
        System.assert(fileUrls.size() > 0, 'Expected at least one file URL to be returned');
        System.assert(fileUrls[0].contains('shepherd/version/download/'), 'Expected a valid Salesforce file URL');

        // 2. Query ContentDocumentLink to verify that the image was linked to the test record
        List<ContentDocumentLink> docLinks = [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :testResponse.Id
        ];

        // 3. Assert that the image was linked to the record
        System.assert(docLinks.size() > 0, 'Expected the image to be linked to the test record');
        System.assertEquals(testResponse.Id, docLinks[0].LinkedEntityId, 'Expected the image to be linked to the correct record');
    }
}