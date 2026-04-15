public without sharing class FS_ContentVersionTriggerHandler implements FS_Utility.ITriggerHandler {

    public FS_ContentVersionTriggerHandler() {
    }

    public void beforeInsert() {}
    public void afterInsert()
    {
        List<ContentVersion> newList = Trigger.new;
        FS_ContentVersionTriggerHandler.sendFileEvents(newList, null);
    }
    public void beforeUpdate() {}
    public void afterUpdate()
    {
        List<ContentVersion> newList = Trigger.new;
        Map<Id, ContentVersion> oldMap = (Map<Id, ContentVersion>) Trigger.oldMap;
        FS_ContentVersionTriggerHandler.sendFileEvents(newList, oldMap);
    }
    public void beforeDelete() {}
    public void afterDelete() {}
    public void afterUndelete() {}

    public static void sendFileEvents(List<ContentVersion> fileList, Map<Id, ContentVersion> oldMap)
    {
        System.debug('Entering sendFileEvents method');

        if (!FS_Utility.isActive('Send File Attachment Events', 'Send WO Events for File Attachments.')) {
            return;
        }

        if (FS_Utility.isCurrentUserIntegrationProfile())
        {
            // If this is an "Integration" User, exit..
            System.debug('SKIPPING File Attachment Events because Current User Profile is "Integration"');
            return;
        }

        Map<Id, ContentVersion> contentVersionMap = new Map<Id, ContentVersion>();
        Map<Id, Id> contentDocumentIdToContentVersionIdMap = new Map<Id, Id>();
        for (ContentVersion cv : fileList)
        {
            contentVersionMap.put(cv.Id, cv);
            contentDocumentIdToContentVersionIdMap.put(cv.ContentDocumentId, cv.Id);
        }
        System.debug('ContentVersion records to check: ' + fileList.size() + ' ' + fileList);
        System.debug('contentDocumentIdToContentVersionIdMap: ' + contentDocumentIdToContentVersionIdMap.size() + ' ' + contentDocumentIdToContentVersionIdMap);

        // Get the ContentDocumentLinks so we can find the Work Orders associated to the ContentDocuments
        Map<Id, Id> contentDocumentIdToWoIdMap = new Map<Id, Id>();
        for(ContentDocumentLink contentDocumentLink: [SELECT ContentDocumentId, LinkedEntity.type, LinkedEntityId
        FROM ContentDocumentLink
        WHERE ContentDocumentId IN: contentDocumentIdToContentVersionIdMap.keySet()])
        {
            System.debug('contentDocumentLink.LinkedEntityId: ' + contentDocumentLink.LinkedEntityId);
            System.debug('contentDocumentLink.LinkedEntity.Type: ' + contentDocumentLink.LinkedEntity.Type);
            if(contentDocumentLink.LinkedEntity.Type == 'WorkOrder')
            {
                contentDocumentIdToWoIdMap.put(contentDocumentLink.ContentDocumentId, contentDocumentLink.LinkedEntityId);
            }
        }
        System.debug('contentDocumentIdToWoIdMap: ' + contentDocumentIdToWoIdMap.size() + ' ' + contentDocumentIdToWoIdMap);

        if (contentDocumentIdToWoIdMap.isEmpty()) {
            return;
        }

        // Get the Work Order Ids for the ContentVersion Ids
        Map<Id, Id> cvIdToWoIdMap = new Map<Id, Id>();
        for (ContentVersion contentVersion :fileList) {
            Id woId = contentDocumentIdToWoIdMap.get(contentVersion.ContentDocumentId);
            if (woId != null) {
                cvIdToWoIdMap.put(contentVersion.Id, woId);
            }
        }
        System.debug('cvIdToWoIdMap: ' + cvIdToWoIdMap.size() + ' ' + cvIdToWoIdMap);

        if (cvIdToWoIdMap.isEmpty()) {
            return;
        }

        System.debug('Processing ContentVersion records');
        Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>([SELECT Id, WorkOrderNumber, SAP_Notification_ID__c FROM WorkOrder WHERE Id IN :cvIdToWoIdMap.values()]);
        System.debug('woMap: ' + woMap.size() + ' ' + woMap);

        List<FS_WorkOrder_Event__e> events = new List<FS_WorkOrder_Event__e>();
        for (ContentVersion cv : fileList)
        {

            WorkOrder wo = woMap.get(cvIdToWoIdMap.get(cv.Id));
            System.debug('Work Order Id: ' + cvIdToWoIdMap.get(cv.Id));
            System.debug('wo: ' + wo);
            if (wo != null && String.isNotBlank(wo.SAP_Notification_ID__c) && String.isBlank(cv.Legacy_SF_ID__c))
            {
                System.debug('Creating a Platform Event for: ' + wo.WorkOrderNumber);
                FS_WorkOrder_Event__e iEvent = new FS_WorkOrder_Event__e();
                iEvent.Action__c = 'FILE_ATTACHMENT';
                iEvent.WorkOrderId__c = wo.Id;
                iEvent.AttachmentId__c = cv.Id;
                events.add(iEvent);
            }
        }

        if (!events.isEmpty()) {
            FS_PlatformEventUtility.publishEvents(events, 'WorkOrderId__c', 'Action__c');
        }
    }
}