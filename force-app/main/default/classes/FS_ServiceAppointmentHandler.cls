public with sharing class FS_ServiceAppointmentHandler implements FS_Utility.ITriggerHandler {
    
    public FS_ServiceAppointmentHandler () {}

    public void beforeInsert() {
        List<ServiceAppointment> newList = Trigger.new;
        FS_AutoAssignment.updateWorkOrderAssignment(newList, null);
        FS_AutoAssignment.autoAssignSync(newList, null);
    }
    public void afterInsert() {}
    public void beforeUpdate() {
        List<ServiceAppointment> newList = Trigger.new;
        Map<Id, ServiceAppointment> oldMap = (Map<Id, ServiceAppointment>) Trigger.oldMap;
        FS_AutoAssignment.updateWorkOrderAssignment(newList, oldMap);
        FS_AutoAssignment.autoAssignSync(newList, oldMap);
    }
    public void afterUpdate() {}
    public void beforeDelete() {}
    public void afterDelete() {}
    public void afterUndelete() {}
}