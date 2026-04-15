public with sharing class FS_WorkOrderStandardJobTime {

    public static String WILDCARD = '(Empty)';

    /**
     * 1/8/21 ITSVMX-225 Standard Job Time Automation
     * On creation of a Work Order, or when the Order Type or Installed Product are changed, the system should
     * automatically update the Service Duration and a new “Standard Job Time” field by finding a corresponding
     * record in the SVMX_PS_Standard_Job_Time__c object.
     * CONVERTED to SFS (WorkType) on 2024-04-18
     */
    public static void updateWorkType(List<WorkOrder> woList, Map<Id, WorkOrder> oldMap) {

        if (!FS_Utility.isActive('WO Update WorkType', 'Auto-Populate the WorkType on WO')) {
            return;
        }

        List<WorkOrder> woUpdateList = new List<WorkOrder>();
        Set<String> externalIds = new Set<String>();
        Map<String, WorkType> workTypeMap = new Map<String, WorkType>();

        // 8/19/21 Tony - ITSVMX-573 Standard Job Time Default Schedule Duration
        // Added as the default for Service Duration is not working from ServiceMax after Long Job Scheduling was activated

        //Get list of Work Orders to update and ExternalId Map
        for (WorkOrder wo : woList) {
            WorkOrder old = (oldMap == null) ? null : oldMap.get(wo.Id);

            if (old == null || (old != null && wo.Order_Type__c != old.Order_Type__c)
                    || (old != null && wo.AssetId != old.AssetId)
                    || (wo.WorkTypeId == null))
            {
                woUpdateList.add(wo);
                // Need to lookup the exact match + Wildcard IF exact match NOT found
                externalIds.addAll(getWorkTypeExternalIds(wo));
            }
        }
        System.debug('woUpdateList: ' + woUpdateList);

        if (woUpdateList.size() <= 0) {
            return;
        }

        // Get list of WorkTypes for the Work Orders we are updating
        // ITSVMX-401 Filter only 'Active' records
        List<WorkType> workTypes = [
                SELECT Id, External_ID__c, Product_Line__c, Model_Series__c,
                        Order_Type__c, EstimatedDuration, DurationType, DurationInMinutes
                FROM WorkType
                WHERE External_ID__c IN :externalIds AND Status__c = 'Active'];
        System.debug('externalIds: ' + externalIds);
        System.debug('workTypes: ' + workTypes);

        if (workTypes.size() <= 0) {
            System.debug('No matching WorkType record was found for External Ids: ' + externalIds);
            return;
        }

        // Get map of External Ids to WorkType
        for (WorkType wrkType : workTypes) {
            workTypeMap.put(wrkType.External_ID__c, wrkType);
        }
        System.debug('workTypeMap: ' + workTypeMap);

        // Update the Standard Job Time and Service Duration
        for (WorkOrder wo : woUpdateList) {
            List<String> woExtIds = getWorkTypeExternalIds(wo); // Exact match + wildcard...
            for (String externalId : woExtIds) {
                WorkType wrkType = workTypeMap.get(externalId);
                if (wrkType != null) {
                    wo.WorkTypeId = wrkType.Id;
                    // NOTE: These should be automatic from the WorkType..
                    wo.Duration = wrkType.EstimatedDuration;
                    wo.DurationType = wrkType.DurationType;
                    wo.Scheduled_Duration_Hours__c = wrkType.DurationInMinutes * 60.0;
                    wo.Standard_Job_Time__c = wrkType.DurationInMinutes * 60.0;

                    break; // Stop the woExtIds loop, don't try the next externalId
                }
            }
        }
        System.debug('Updated WOs: ' + woUpdateList);
    }

    private static List<String> getWorkTypeExternalIds(WorkOrder wo) {
        List<String> externalIds = new List<String>();
        if (wo.Record_Type__c == 'Estimate') {
            externalIds.add('Estimate');
        } else {
            if (wo.ModelSeries__c != null) {
                externalIds.add(wo.Order_Type__c + '-' + wo.Asset_Product_Line__c + '-' + wo.ModelSeries__c);
            }
            externalIds.add(wo.Order_Type__c + '-' + wo.Asset_Product_Line__c + '-' + WILDCARD);
            externalIds.add(wo.Order_Type__c + '-' + WILDCARD + '-' + WILDCARD);
        }
        return externalIds;
    }
}