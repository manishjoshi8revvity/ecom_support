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


public with sharing class ImageController {

    @InvocableMethod(label='Save Image and Link to Record' description='Saves an image and links it to a record')
    public static List<String> saveImageAndLinkToRecord(List<RequestData> requestDataList) {
        List<String> fileUrls = new List<String>();

        for (RequestData requestData : requestDataList) {
            // Remove the data:image/png;base64, part to handle the image data
            String base64Image = requestData.imageData.replace('data:image/png;base64,', '');
            Blob imageBlob = EncodingUtil.base64Decode(base64Image);
            String title = (requestData.imageTitle != null && requestData.imageTitle != '') ? requestData.imageTitle : 'Pasted Clipboard Image';

            // Set the file extension
            String fileExtension = '.png';

            // Create a new ContentVersion (File)
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = title;
            contentVersion.PathOnClient = title + fileExtension;
            contentVersion.VersionData = imageBlob;
            contentVersion.IsMajorVersion = true;
            insert contentVersion;

            // Get the ContentVersion Id and ContentDocumentId
            ContentVersion insertedVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1];

            // Create a ContentDocumentLink to associate the file with the record
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ContentDocumentId = insertedVersion.ContentDocumentId;
            contentDocumentLink.LinkedEntityId = requestData.recordId;
            contentDocumentLink.ShareType = 'V'; // Viewer access
            insert contentDocumentLink;

            // Update Response__c.response_image__c field with the ContentVersion ID (starting with 068)
            Response__c responseRecord = [SELECT Id FROM Response__c WHERE Id = :requestData.recordId LIMIT 1];
            responseRecord.response_image__c = insertedVersion.Id; // Update with ContentVersion.Id (068)
            update responseRecord;

            // Construct the file URL
            String baseURL = URL.getOrgDomainUrl().toExternalForm();
            String fileURL = baseURL + '/sfc/servlet.shepherd/version/download/' + insertedVersion.ContentDocumentId;

            fileUrls.add(fileURL); // Add the URL to the list of file URLs
        }

        return fileUrls; // Return a list of URLs
    }

    // Define the input data structure
    public class RequestData {
        @InvocableVariable(required=true)
        public String imageData;

        @InvocableVariable(required=true)
        public String imageTitle;

        @InvocableVariable(required=true)
        public Id recordId; // Record ID to link the file to
    }
}