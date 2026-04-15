/**
 * Created by frankvanloon on 4/19/24.
 */
public without sharing class FS_AutoAssignment {

    private static Set<String> IGNORE_WORK_CENTERS = new Set<String> { 'SCHEDULE', 'OS_SCHED' };

    private static String getSAP_TechId(WorkOrder wo)
    {
        // SVMXCFG-856 Auto-Assign to SAP Work Center (only)
        if (String.isNotBlank(wo.SAP_Work_Center__c))
        {
            if (IGNORE_WORK_CENTERS.contains(wo.SAP_Work_Center__c.toUpperCase())) {
                return null;
            }
            return wo.SAP_Work_Center__c;
        }
        return null;
    }

    public static void createResourcePreferences(List<WorkOrder> woList, Map<Id, WorkOrder> oldMap)
    {
        if (!FS_Utility.isActive('WO Resource Preferences',
                'Auto Create Resource Preferences for Preferred Tech and SAP Work Center')) {
            return;
        }

        List<WorkOrder> wosToCheck = new List<WorkOrder>();
        List<ResourcePreference> prefs = new List<ResourcePreference>();
        Set<Id> ipIds = new Set<Id>();
        Set<String> sapTechIds = new Set<String>();
        
        for (WorkOrder wo : woList)
        {
            WorkOrder old = (oldMap == null) ? null : oldMap.get(wo.Id);
            // Status is Open & PerformAutoAssign is checked
            // Removed: wo.Perform_Auto_Assignment__c == true
            if (wo.Record_Type__c != 'Estimate'
                && (wo.Status == 'Open' || (wo.Status == 'Assigned' && old != null && old.Record_Type__c == 'Estimate'))
                && String.isBlank(wo.AutoAssignmentNotes__c))
            {
                if (wo.AutoAssignmentNotes__c == null) {
                    wo.AutoAssignmentNotes__c = '';
                } else {
                    wo.AutoAssignmentNotes__c += '\n';
                }
                wo.AutoAssignmentNotes__c += '* Creating Resource Preferences...';
                //wo.Perform_Auto_Assignment__c = false;
                wosToCheck.add(wo);

                // SVMXCFG-379 - Auto-Assign to SAP Work Center / Plant
                String sapTechId = getSAP_TechId(wo);
                if (sapTechId != null)
                {
                    sapTechIds.add(sapTechId);
                }

                if (wo.AssetId != null)
                {
                    ipIds.add(wo.AssetId);
                }
            }
        }
        
        // SVMXCFG-379 - Auto-Assign to SAP Work Center / Plant
        Map<String, ServiceResource> sapTechMap = new Map<String, ServiceResource>();
        if (!sapTechIds.isEmpty())
        {
            // SVMXCFG-856 Auto-Assign to SAP Work Center (only)
            for (ServiceResource tech : [SELECT Id, Name, Work_Center__c, RelatedRecordId, IsActive
                FROM ServiceResource WHERE Work_Center__c IN :sapTechIds])
            {
                sapTechMap.put(tech.Work_Center__c, tech);
            }

            for (WorkOrder wo : wosToCheck)
            {
                String sapTechId = getSAP_TechId(wo);
                if (sapTechId != null)
                {
                    ServiceResource tech = sapTechMap.get(sapTechId);
                    if (tech != null)
                    {
                        // SVMXCFG-693 Only assign if "Active" & "Enable Scheduling"
                        if (tech.IsActive == false)
                        {
                            wo.AutoAssignmentNotes__c += ' Skipped SAP Work Center Technician because not Active.';
                        }
                        else
                        {
                            ResourcePreference pref = new ResourcePreference();
                            pref.ServiceResourceId = tech.Id;
                            pref.RelatedRecordId = wo.Id;
                            pref.PreferenceType = 'Required';
                            prefs.add(pref);
                            
                            wo.AutoAssignmentNotes__c += ' Added Resource Preference for SAP Work Center Technician.';
                        }
                    }
                }
            }
        }

        Map<Id, Asset> ipMap = null;
        if (!wosToCheck.isEmpty())
        {
            //Get all the Installed Products and the Default Tech Setting - put in Map
            if (!ipIds.isEmpty())
            {
                //ITSVMX-664 Added new field fxModelSeries__c in select statement
                ipMap = new Map<Id, Asset>([SELECT Id,
                        Preferred_Technician__c, Preferred_Technician__r.Name,
                        Preferred_Technician__r.RelatedRecordId,
                        Preferred_Technician__r.IsActive,
                        Product2Id, fxModelSeries__c
                    FROM Asset WHERE Id IN :ipIds]);
            }
        }

        // Second pass.. try to assign to Preferred if possible..
        for (WorkOrder wo : wosToCheck)
        {
            Asset ip = (wo.AssetId != null && ipMap != null) ? ipMap.get(wo.AssetId) : null;
            if (ip != null)
            {
                ServiceResource tech = (ip.Preferred_Technician__c != null) ? ip.Preferred_Technician__r : null;
                System.debug('ip.SVMXC__Preferred_Technician__c: ' + ip.Preferred_Technician__c);
                Boolean enabled = (tech != null && tech.IsActive == true);
                System.debug('enabled: ' + enabled);
                // SVMXCFG-693 Only assign if "Active" & "Enable Scheduling"
                if (tech != null && !enabled)
                {
                    wo.AutoAssignmentNotes__c += ' Skipped Asset Preferred Technician because not Active.';
                }

                if (tech != null && enabled)
                {
                    ResourcePreference pref = new ResourcePreference();
                    pref.ServiceResourceId = tech.Id;
                    pref.RelatedRecordId = wo.Id;
                    pref.PreferenceType = 'Preferred';
                    prefs.add(pref);

                    wo.AutoAssignmentNotes__c += ' Added Resource Preference for Asset Preferred Technician.';
                }
            }
        }

        if (!prefs.isEmpty()) {
            //List<Database.SaveResult> results =
            Database.insert(prefs, false);
        }

        // NOTE: Could add a trim function to wo.AutoAssignmentNotes__c if necessary
    }

    public static Integer ONE_WORK_DAY_MINUTES = (8 * 60);

    public static void autoAssignSync(List<ServiceAppointment> apptList, Map<Id, ServiceAppointment> oldMap) {
        if (!FS_Utility.isActive('Service Appt Auto Assign', 'Sync AutoSchedule, DueDate and IsMultiDay')) {
            return;
        }

        Set<Id> woIds = new Set<Id>();
        List<ServiceAppointment> woAppts = new List<ServiceAppointment>();
        SObjectType workOrderType = Schema.WorkOrder.SObjectType;
        for (ServiceAppointment appt : apptList) {
            // Set the IsMultiDay based on the Duration
            appt.FSL__IsMultiDay__c = (appt.DurationInMinutes >= ONE_WORK_DAY_MINUTES);

            SObjectType objectType = appt.ParentRecordId.getSobjectType();
            if (objectType == workOrderType) {
                woIds.add(appt.ParentRecordId);
                woAppts.add(appt);
            }
        }

        if (!woIds.isEmpty()) {
            Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>([SELECT Id, WorkOrderNumber, fxTimeZone__c,
                    Perform_Auto_Assignment__c, Customer_Required_Start_Date__c
                FROM WorkOrder WHERE Id IN :woIds]);
            for (ServiceAppointment appt : woAppts) {
                WorkOrder wo = woMap.get(appt.ParentRecordId);
                // Trigger on SA... look at FS Work Order Lookup ... Perform_Auto_Assignment__c and set FSL__Auto_Schedule__c... to TRUE
                if (wo.Perform_Auto_Assignment__c) {
                    appt.FSL__Auto_Schedule__c = true;
                }

                // Customer_Required_Start_Date__c to DueDate (on or before)
                // NOTE: We need to make sure Earliest is before Due (get diff, set other based on that)
                /* Requirements for Customer_Required_Start_Date__c: If ServiceAppointment.SFS_Work_Order__c <> NULL && SFS_Work_Order__r.Customer_Required_Start_Date__c <> NULL && SFS_Work_Order__r.Customer_Required_Start_Date__c > TODAY(), assign ServiceAppointment.DueDate = DateValue(SFS_Work_Order__r.Customer_Required_Start_Date__c) + 11pm, with time of day calculated based on ServiceTerritory.OperatingHours.TimeZone */
                if (wo.Customer_Required_Start_Date__c != null) {
                    // TODO: Use fxTimeZone__c to convert Date to Datetime...

                }
            }
        }
    }

    // ITSFDC-509 Auto-Assign for Depot Work Orders (when they "Accept" from the Queue)
    public static void acceptFromQueue(List<WorkOrder> woList, Map<Id, WorkOrder> oldMap)
    {
        if (!FS_Utility.isActive('WO Auto Assign Owner Changes', 'Perform a Auto-Assignment to a Technician related to the new WO Owner.')) {
            return;
        }

        String recordTypes = 'Depot,Estimate';
        List<String> lstRecordTypeStrings = recordTypes.split(',');

        String queuePrefix = Schema.SObjectType.Group.getKeyPrefix();
        System.debug('QUEUE PREFIX = ' + queuePrefix);
        Set<Id> userIds = new Set<Id>();
        List<WorkOrder> woToAssign = new List<WorkOrder>();
        for (WorkOrder wo : woList)
        {
            WorkOrder old = (oldMap == null) ? null : oldMap.get(wo.Id);
            Boolean oldInQueue = (old == null) ? false : ('' + old.OwnerId).startsWith(queuePrefix);
            System.debug('OLD IN QUEUE? ' + oldInQueue + ', ACCEPT FROM QUEUE? ' + wo.Accept_from_Queue__c);

            // Mass-Quick-Action Support - SVMX_PS_Accept_Work_Order__c (checkbox)
            // New Field: "Accept From Queue", if NOT in a Queue throw Exception!
            if (wo.Accept_from_Queue__c == true && old.Accept_from_Queue__c != wo.Accept_from_Queue__c)
            {
                if (oldInQueue) {
                    wo.OwnerId = UserInfo.getUserId();
                    wo.Accept_from_Queue__c = false;  // Revert the value... like a "button click"
                    if (lstRecordTypeStrings.contains(wo.Record_Type__c))
                    {
                        // Try to assign to the current User's Technician...
                        System.debug('Adding WO record to Assign list');
                        woToAssign.add(wo);
                        userIds.add(wo.OwnerId);
                    }
                } else {
                    wo.addError('The "Accept from Queue" feature is only available for Work Orders currently in a Queue');
                }
            }
        }

        if (woToAssign.isEmpty()) {
            return;
        }

        Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Name, Profile.Name FROM User WHERE Id IN :userIds]);
        Map<Id, ServiceResource> userTechMap = new Map<Id, ServiceResource>();
        for (ServiceResource tech : [SELECT Id, Name, RelatedRecordId
            FROM ServiceResource WHERE RelatedRecordId IN :userIds])
        {
            userTechMap.put(tech.RelatedRecordId, tech);
        }

        for (WorkOrder wo : woToAssign)
        {
            User u = userMap.get(wo.OwnerId);
            ServiceResource tech = userTechMap.get(wo.OwnerId);

            // SVMXCFG-1107 Null protect the User variable (could be a Group or Queue)
            if (u != null && tech != null)
            {
                // IF WO is still in "Initializing", don't allow this...
                if (wo.Status == 'Initializing')
                {
                    wo.addError('Cannot Accept the Work Order until it has finished initializing. Please check for Integration Errors.');
                }
                // ITSVMX-34 05/28/2020 - Don't allow a User to take ownership of the WO if the order status is "On Hold - Credit"
                //else
                else if (wo.Status == 'On Hold - Credit' && wo.OwnerId == UserInfo.getUserId())
                {
                    wo.addError('Cannot Accept a Work Order in "On Hold - Credit" status.');
                }
                else
                {
//                  Date startDate = wo.Customer_Required_Start_Date__c;
//                  startDate = (startDate == null ? Date.today() : startDate);
                    assignTechnician(wo.Id, tech.Id);
                }
            }
        }
    }

    public static void updateWorkOrderAssignment(List<ServiceAppointment> apptList, Map<Id, ServiceAppointment> oldMap)
    {
        if (!FS_Utility.isActive('Update WO Assignment', 'Update the WO SalesOrg, Tech Email, Owner and other details from the Technician and related records.')) {
            return;
        }

        Set<Id> techIds = new Set<Id>();
        Set<Id> woIds = new Set<Id>();
        List<ServiceAppointment> apptTechUpdates = new List<ServiceAppointment>();
        List<ServiceAppointment> apptPrevTechUpdates = new List<ServiceAppointment>();
        Map<Id, WorkOrder> woUpdates = new Map<Id, WorkOrder>();
        SObjectType workOrderType = Schema.WorkOrder.SObjectType;
        for (ServiceAppointment appt : apptList)
        {
            ServiceAppointment old = (oldMap == null) ? null : oldMap.get(appt.Id);
            if (appt.Assigned_Resource__c != null && (old == null || appt.Assigned_Resource__c != old.Assigned_Resource__c))
            {
                techIds.add(appt.Assigned_Resource__c);
                apptTechUpdates.add(appt);
                SObjectType objectType = appt.ParentRecordId.getSobjectType();
                if (objectType == workOrderType) {
                    woIds.add(appt.ParentRecordId);
                }
            }
            // SVMXCFG-529 - Collect "Previous" Tech Ids
            if (old != null && old.Assigned_Resource__c != null && appt.Assigned_Resource__c != old.Assigned_Resource__c)
            {
                techIds.add(old.Assigned_Resource__c);
                apptPrevTechUpdates.add(appt);
            }
        }

        if (!techIds.isEmpty())
        {
            Map<Id, ServiceResource> techMap = new Map<Id, ServiceResource>([SELECT Id, Name, Work_Center__c, Plant__c,
                    LocationId, Location.SalesOrg__c, RelatedRecord.Email,
                    RelatedRecordId, Role__c, Technician_Manager_Email__c
            FROM ServiceResource WHERE Id IN :techIds]);

            Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>();
            if (!woIds.isEmpty()) {
                woMap = new Map<Id, WorkOrder>([SELECT Id, WorkOrderNumber, Scheduled_Date_Time__c,
                        SAP_Work_Center__c, SAP_Maintenance_Plant__c, ParentWorkOrderId
                FROM WorkOrder WHERE Id IN :woIds]);
            }

            for (ServiceAppointment appt : apptTechUpdates)
            {
                ServiceAppointment old = (oldMap == null) ? null : oldMap.get(appt.Id);
                Id techId = appt.Assigned_Resource__c;
                if (techMap.containsKey(techId))
                {
                    ServiceResource tech = techMap.get(techId);
                    WorkOrder wo = woMap.get(appt.ParentRecordId);
                    if (wo != null) {
                        if (String.isNotBlank(tech.Work_Center__c)) {
                            wo.SAP_Work_Center__c = tech.Work_Center__c;
                            wo.SAP_Maintenance_Plant__c = tech.Plant__c;
                            wo.Scheduled_Date_Time__c = appt.SchedStartTime;
                            woUpdates.put(wo.Id, wo);
                        }

                        // Migrated from assignTechToParentWO() .. update parent WO when child WO is assigned
                        if (wo.ParentWorkOrderId != null) {
                            FS_AutoAssignment.assignTechnician(wo.ParentWorkOrderId, techId);
                        }
                    }

                    // Begin of change for ITSVMX-345 reset Technician Manager Email on Work Order Reassignment to Billable Queue
                    if (tech.Technician_Manager_Email__c != null)
                    {
                        appt.Technician_Manager_Email__c = tech.Technician_Manager_Email__c;
                    }else{
                        appt.Technician_Manager_Email__c = null ;
                    }
                    // End of change for Technician Manager Email on Work Order Reassignment to Billable Queue

                    // SVMXCFG-297 -- Fill in the "Technician Sales Org"
                    if (tech.LocationId != null)
                    {
                        //System.debug('Current appt.SMAX_PS_TechnicianSalesOrg__c is: ' + appt.SMAX_PS_TechnicianSalesOrg__c);
                        //System.debug('Setting appt.SMAX_PS_TechnicianSalesOrg__c to: ' + tech.SVMXC__Inventory_Location__r.SMAX_PS_SalesOrg__c);
                        appt.Technician_Sales_Org__c = tech.Location.SalesOrg__c;
                    }
                    // SVMXCFG-824 Fill in the Member Email when Tech changes
                    appt.Technician_Email__c = tech.RelatedRecord.Email;
                }
            }

            // SVMXCFG-529 - Fill in "Previous" Tech email
            for (ServiceAppointment wo : apptPrevTechUpdates)
            {
                ServiceAppointment old = (oldMap == null) ? null : oldMap.get(wo.Id);
                if (old != null && old.Assigned_Resource__c != null)
                {
                    ServiceResource previous = techMap.get(old.Assigned_Resource__c);
                    if (previous != null)
                    {
                        //appt.SMAX_PS_Previous_Technician__c = previous.Id;
                        wo.Previous_Technician_Email__c = previous.RelatedRecord.Email;
                        // SVMXCFG-694 : Copy Previous Tech Name and a datestamp for reassign email
                        wo.Previous_Technician_Name__c = previous.Name;
                        wo.Technician_Reassignment_Date_Time__c = System.now();
                    }
                }
            }

            if (!woUpdates.isEmpty()) {
                update woUpdates.values();
            }
        }
    }

    public static void assignTechnician(Id woId, Id techId) {
        // Find appts for this WO which are NOT already assigned to this Tech
        List<ServiceAppointment> appts = [SELECT Id, ParentRecordId, Assigned_Resource__c,
                (SELECT Id FROM ServiceResources WHERE ServiceResourceId = :techId)
            FROM ServiceAppointment WHERE ParentRecordId = :woId AND Assigned_Resource__c != :techId
            ORDER BY LastModifiedDate DESC];
        // Only handle the basic 1-appointment scenario.. without an AssignedResource record
        if (appts.size() == 1 && appts[0].ServiceResources.isEmpty()) {
            AssignedResource techAssignment = new AssignedResource();
            techAssignment.ServiceResourceId = techId;
            techAssignment.ServiceAppointmentId = appts[0].Id;
            Database.insert(techAssignment, false);
        }
    }

    /*
     * Auto-create SkillRequirement records for the WorkOrder based on the WO.Model_Series__c
     * Should be called from the AFTER insert / update triggers
     */
    public static void createSkillRequirements(List<WorkOrder> woList, Map<Id, WorkOrder> oldMap) {
        if (!FS_Utility.isActive('WO Skill Requirements',
                'Auto Create Skill Requirements based on the Model Series')) {
            return;
        }

        Map<Id, String> woSkillNameMap = new Map<Id, String>();
        for (WorkOrder wo: woList) {
            WorkOrder old = (oldMap == null) ? null : oldMap.get(wo.Id);
            if (String.isNotBlank(wo.ModelSeries__c) &&
                (old == null || old.ModelSeries__c != wo.ModelSeries__c)) {
                woSkillNameMap.put(wo.Id, wo.ModelSeries__c);
            }
        }

        if (woSkillNameMap.isEmpty()) {
            return;
        }

        Set<String> skillNames = new Set<String>(woSkillNameMap.values());
        Map<String, Skill> skillMap = new Map<String, Skill>();
        for (Skill skll : [SELECT Id, MasterLabel FROM Skill WHERE MasterLabel IN :skillNames]) {
            skillMap.put(skll.MasterLabel, skll);
        }

        List<SkillRequirement> skillRequirements = new List<SkillRequirement>();
        for (Id woId : woSkillNameMap.keySet()) {
            String skillName = woSkillNameMap.get(woId);
            Skill skll = skillMap.get(skillName);
            if (skll != null) {
                SkillRequirement skillReq = new SkillRequirement();
                skillReq.SkillId = skll.Id;
                skillReq.RelatedRecordId = woId;
                skillRequirements.add(skillReq);
            }
        }

        if (!skillRequirements.isEmpty()) {
            insert skillRequirements;
        }
    }

    // ITSVMX-539 Auto assignment of estimates for profiles: CRC profile, Technical Support & Hybrid
    public static void serviceEstimateOwners(List<WorkOrder> woList, Map<Id, WorkOrder> oldMap) {

        Set<Id> ownerIds = new Set<Id>();
        List<WorkOrder> estimates = new List<WorkOrder>();
        for (WorkOrder wo : woList) {
            WorkOrder old = (oldMap == null) ? null : oldMap.get(wo.Id);
            if (wo.Record_Type__c == 'Estimate' && (old == null || wo.OwnerId != old.OwnerId)) {
                // Estimate is New or Owner Changed
                ownerIds.add(wo.OwnerId);
                estimates.add(wo);
            }
        }

        if (estimates.isEmpty()) {
            return;
        }

        List<ServiceResource> technicians = [SELECT Id, Name, RelatedRecordId, Work_Center__c, Plant__c
            FROM ServiceResource WHERE RelatedRecordId IN :ownerIds ORDER BY CreatedDate DESC];
        System.debug('technicianMap: ' + technicians);

        // Get a Map of the User Id to the newest Technician record associated to it
        Map<Id, ServiceResource> userIdToTechnicianMap = new Map<Id, ServiceResource>();
        for (ServiceResource tech : technicians) {
            userIdToTechnicianMap.put(tech.RelatedRecordId, tech);
        }
        System.debug('userIdToTechnicianMap: ' + userIdToTechnicianMap);

        List<Event> events = new List<Event>();
        for (WorkOrder wo : estimates) {
            // Also, only do this assignment on a new record created
            ServiceResource tech = userIdToTechnicianMap.get(wo.OwnerId);
            if (tech != null) {
                wo.SAP_Work_Center__c = tech.Work_Center__c;
                wo.SAP_Maintenance_Plant__c = tech.Plant__c;
                wo.Assigned_Resource_Name__c = tech.Name;
            }
        }
    }

}