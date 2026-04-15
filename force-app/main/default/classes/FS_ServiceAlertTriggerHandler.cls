/**
 * Trigger Handler for Service Alerts
 * Created by frankvanloon on 3/18/24.
 */
public with sharing class FS_ServiceAlertTriggerHandler implements FS_Utility.ITriggerHandler {

  public void beforeInsert()
  {
    List<FS_ServiceAlert__c> newList = Trigger.new;

    FS_ServiceAlertManager.updateServiceAlerts(newList, null);
    FS_ServiceAlertManager.updatePath(newList, null);
    //FS_ServiceAlertManager.updateServiceAlertObject(newList, null);
  }

  public void afterInsert()
  {
    List<FS_ServiceAlert__c> newList = Trigger.new;

    // ITSVMX-242 tony - Service Alert Notification Setup
    FS_ServiceAlertManager.sendServiceAlertCreationNotifications(newList);
  }

  public void beforeUpdate()
  {
    List<FS_ServiceAlert__c> newList = Trigger.new;
    Map<Id, FS_ServiceAlert__c> oldMap = (Map<Id, FS_ServiceAlert__c>) Trigger.oldMap;

    FS_ServiceAlertManager.updateServiceAlerts(newList, oldMap);
    FS_ServiceAlertManager.updatePath(newList, oldMap);
    //FS_ServiceAlertManager.updateServiceAlertObject(newList, oldMap);
  }

  public void afterUpdate()
  {
    List<FS_ServiceAlert__c> newList = Trigger.new;
    Map<Id, FS_ServiceAlert__c> oldMap = (Map<Id, FS_ServiceAlert__c>) Trigger.oldMap;

    // ITSVMX-209 tony - Service Alerts Customer Care Email Notification
    FS_ServiceAlertManager.sendServiceAlertNotifications(newList, oldMap);
    // ITSVMX-242 tony - Service Alert Notification Setup
    FS_ServiceAlertManager.submitServiceAlertForApproval(newList, oldMap);
  }

  public void beforeDelete() {}

  public void afterDelete()
  {
    //List<FS_ServiceAlert__c> oldList = Trigger.old;
  }

  public void afterUndelete()
  {
    //List<FS_ServiceAlert__c> newList = Trigger.new;
  }
}