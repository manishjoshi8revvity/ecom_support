/**
 *  Apex Class containing misc Field Service Utility methods.
 *  2017-07-03      Frank VanLoon       Initial creation.
 *  2022-12-23      Tony Herrington     Added check for Triggers.areDisabled to the isActive() method
 */
public with sharing class FS_Utility {

    /**
        The following methods can be used to ensure sections of code are only executed once per transaction.
    */
    private static Set<String> runSet = new Set<String>();
    private static Map<String, Map<String, Schema.SObjectField>> fieldMap =
            new Map<String, Map<String, Schema.SObjectField>>();


    /*
     *  Use this method sparingly.. it will reset all run-once variables and allow all functionality to run again.
     */
    public static void clearCache()
    {
        runSet.clear();
    }

    /*
     *  Use this method only inside Unit Tests, to allow functionality to run again.
     */
    public static void reset(String name){
        if (runSet.contains(name)) {
            runSet.remove(name);
        }
    }

    /*
     *  Use this method to limit execution of trigger code to once per transaction.
        // Typical Usage:
        if (!SMAX_PS_Utility.isFirstrun('WorkOrder_OnCloseUpdates'))
            return;
     */
    public static Boolean isFirstRun(String name)
    {
        //System.debug('In RunOnce: ' + name + ' -- SOQL: ' + Limits.getQueries() + ' / ' + Limits.getLimitQueries());
        Boolean hasRun = runSet.contains(name);
        if (hasRun) {
            return false;
        } else {
            runSet.add(name);
            return true;
        }
    }

    /**
        The following interface and method can be used to simplify Trigger Handler code.
    */
    public interface ITriggerHandler {
        void beforeInsert();
        void afterInsert();
        void beforeUpdate();
        void afterUpdate();
        void beforeDelete();
        void afterDelete();
        void afterUndelete();
    }

    /**
     *  This method houses the controller logic and invokes appropriate handler class methods.
     *  Typical Usage:
     *      FS_Utility.executeHandler(new FS_Location_TriggerHandler());
     */
    public static void executeHandler(ITriggerHandler handler) {

        if(Trigger.isBefore && Trigger.isInsert)
        {
            handler.beforeInsert();
        }
        else if (Trigger.isAfter && Trigger.isInsert)
        {
            handler.afterInsert();
        }
        else if (Trigger.isBefore && Trigger.isUpdate)
        {
            handler.beforeUpdate();
        }
        else if (Trigger.isAfter && Trigger.isUpdate)
        {
            handler.afterUpdate();
        }
        else if (Trigger.isBefore && Trigger.isDelete)
        {
            handler.beforeDelete();
        }
        else if (Trigger.isAfter && Trigger.isDelete)
        {
            handler.afterDelete();
        }
        else if (Trigger.isAfter && Trigger.isUndelete)
        {
            handler.afterUndelete();
        }
    }

    /*
     *  The following methods are misc. helper functions
     */
//    public static String getDateInSOQLFormat(Date d)
//    {
//        if (d != null)
//        {
//            String day = String.valueOf(d.day());
//            String month = String.valueOf(d.month());
//            String year = String.valueOf(d.year());
//
//            return year+'-'+month+'-'+day;
//        }
//        return '';
//    }

//    public static Boolean doDatesOverlap(Date s1, Date e1, Date s2, Date e2)
//    {
//        if (s1 == null || e1 == null || s2 == null || e2 == null) {
//            return false;
//            // Really invalid.. but we'll let it through
//        }
//
//        return ((s1 <= e1 && s2 <= e2) && (s1 <= e2 && s2 <= e1));
//        //return !((s1 < e1 && e1 < s2 && s2 < e2) || (s2 < e2 && e2 < s1 && s1 < e1));
//    }

//    public static String getCronString(Datetime dt)
//    {
//        String hour = String.valueOf(dt.hour());
//        String minute = String.valueOf(dt.minute());
//        String second = '0';
//        String cronvalue = second+' '+minute+' '+hour+' * * ?' ;
//        return cronvalue;
//    }

    /**
        The following methods help in converting field values
    */
    public static void updateMappedValues(String sobjName, List<SObject> newList, Map<Id, SObject> oldMap)
    {
        updateMappedValues(sobjName, newList, oldMap, false);
    }

    public static void updateMappedValues(String sobjName, List<SObject> newList, Map<Id, SObject> oldMap, Boolean reverseValues)
    {
        List<C_META_FS_AutoFieldMapping__mdt> mappings = [SELECT DeveloperName,
                SourceField__r.QualifiedApiName, SourceValue__c,
                TargetField__r.QualifiedApiName, TargetValue__c
        FROM C_META_FS_AutoFieldMapping__mdt WHERE SObject__r.QualifiedApiName = :sobjName];
        Map<String, Map<String, Map<String, String>>> sourceFieldMap = new Map<String, Map<String, Map<String, String>>>();
        for (C_META_FS_AutoFieldMapping__mdt mapping : mappings)
        {
            String sourceField = mapping.SourceField__r.QualifiedApiName;
            String targetField = mapping.TargetField__r.QualifiedApiName;
            if (!sourceFieldMap.containsKey(sourceField))
            {
                sourceFieldMap.put(sourceField, new Map<String, Map<String, String>>());
            }
            Map<String, Map<String, String>> targetFieldMap = sourceFieldMap.get(sourceField);
            if (!targetFieldMap.containsKey(targetField))
            {
                targetFieldMap.put(targetField, new Map<String, String>());
            }
            Map<String, String> values = targetFieldMap.get(targetField);
            if (reverseValues == false) {
                values.put(mapping.SourceValue__c, mapping.TargetValue__c);
            } else {
                values.put(mapping.TargetValue__c, mapping.SourceValue__c);
            }
        }

        for (SObject sobj : newList)
        {
            SObject old = (oldMap == null) ? null : oldMap.get(sobj.Id);
            System.debug('Trying to AutoMap Fields for SObject: ' + sobj);
            for (String sourceField : sourceFieldMap.keySet())
            {
                String sourceValue = (String) sobj.get(sourceField);
                System.debug('Trying to AutoMap Field: ' + sourceField + ' with source value of: ' + sourceValue);
                String sourceOldValue = (old == null) ? null : (String) old.get(sourceField);
                Map<String, Map<String, String>> targetFieldMap = sourceFieldMap.get(sourceField);
                for (String targetField : targetFieldMap.keySet())
                {
                    String targetValue = (String) sobj.get(targetField);
                    String targetOldValue = (old == null) ? null : (String) old.get(targetField);
                    if (reverseValues == false && sourceField != null && (old == null || targetValue == null || sourceValue != sourceOldValue))
                    {
                        Map<String, String> values = targetFieldMap.get(targetField);
                        String newTargetValue = values.get(sourceValue);
                        sobj.put(targetField, newTargetValue);
                        System.debug('Auto-Mapped Field: ' + targetField + ' with value of: ' + newTargetValue);
                    }
                    else if (reverseValues == true && targetField != null && (old == null || sourceValue == null || targetValue != targetOldValue))
                    {
                        Map<String, String> values = targetFieldMap.get(targetField);
                        String newSourceValue = values.get(targetValue);
                        sobj.put(sourceField, newSourceValue);
                        System.debug('Auto-Mapped Field: ' + sourceField + ' with value of: ' + newSourceValue);
                    }
                }
            }
        }
    }

    /**
        The following methods check / add to the "Services Register" Custom Setting [C_SET_6910_Services_Register__c]
    */

    // Used to disable methods that use the FS_Utility.isActive() method
    public static Boolean triggersDisabled = false;

    /*
        Added this overloaded method for compatibility.
        DEPRECATED.. please use the method with 2 parameters instead.
     */
    public static Boolean isActive(String serviceName)
    {
        return isActive(serviceName, 'Please enter a valid description for: ' + serviceName);
    }

    // ADDED to support batch jobs that want to ONLY run 1 Service Register function. (Or 0 if set to a 'N/A' value)
    public static String SVC_REGISTER_SINGLETON = null;

    /*
        All extensions will check if the service is active before running it:
        serviceName: The name of the service. Each extension should have a unique name.
        serviceDescription: The high level overview of the service.
    */
    public static Boolean isActive(String serviceName, String serviceDescription)
    {
        if (SVC_REGISTER_SINGLETON != null) {
            return serviceName.equalsIgnoreCase(SVC_REGISTER_SINGLETON);
        }

        // Retrieve the extension from the custom settings (if found)
        C_SET_6910_Services_Register__c registeredService = C_SET_6910_Services_Register__c.getInstance(serviceName);

        // Do not try to auto-create. This is problematic due to multi-threading
        //if (registeredService == null)
        //{
        //  registeredService = registerService(serviceName, serviceDescription);
        //  if (registeredService == null)
        //      return false;
        //}

        // When the Service Register is called during Test Execution, it should always return true unless Triggers.areDisabled = true
        if (Test.isRunningTest() && !FS_Utility.triggersDisabled) {
            System.debug('FS_Utility.triggersDisabled = ' + FS_Utility.triggersDisabled);
            return true;
        } else if (Test.isRunningTest() && FS_Utility.triggersDisabled) {
            System.debug('FS_Utility.triggersDisabled = ' + FS_Utility.triggersDisabled);
            return false;
        }
        // Only disable services for SFS Manager User (for now)
//        String userName = UserInfo.getUserName();
//        Boolean isSFS = userName != null && userName.startsWithIgnoreCase('sfs.mgr');
//        if (isSFS == false) {
//            return true;
//        }
        // Instead of auto-creating, assume it is "Active" if not found
        return (registeredService == null) ? true : registeredService.Is_Active__c;
    }

    public static Map<String, Schema.SObjectField> getFields(String objectName)
    {
        if (! fieldMap.containsKey(objectName))
        {
            fieldMap.put(objectName, Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap());
        }

        return fieldMap.get(objectName);
    }

    /**
      The following methods retrieve User and Profile data
    */
    private static Map<Id, Profile> profileMap = new Map<Id, Profile>();

    public static Profile getCurrentUserProfile()
    {
        Id profileId = UserInfo.getProfileId();
        if (profileMap.containsKey(profileId)) {
            return profileMap.get(profileId);
        }

        Profile result = null;
        if (profileId != null) {
            List<Profile> profiles = [SELECT Id, Name, UserType FROM Profile WHERE Id = :profileId];
            if (!profiles.isEmpty()) {
                result = profiles[0];
                profileMap.put(profileId, result);
            }
        }
        return result;
    }
//    private static Map<String, Map<String, RecordType>> rtMap  = new Map<String, Map<String, RecordType>>();
//     public static Map<String, RecordType> getRecTypeDevNameMap(String sObjectType)
//      {
//        if (! rtMap.containsKey(sObjectType))
//        {
//          rtMap.put(sObjectType, new Map<String, RecordType>());
//
//          for (RecordType rt : [SELECT Id, Name, DeveloperName, SOBjectType
//            FROM RecordType WHERE SOBjectType = :sObjectType])
//          {
//            rtMap.get(sObjectType).put(rt.DeveloperName, rt);
//          }
//        }
//
//        return rtMap.get(sObjectType);
//      }

    public static Boolean isCurrentUserIntegrationProfile()
    {
        Profile p = FS_Utility.getCurrentUserProfile();
        return (p != null && p.Name != null && p.Name.containsIgnoreCase('Integration'));
    }
    
    //Gets a record type by a given developer name and the object it is associated
    //with, the dev name and object are assumed to be unique
//    public static RecordType getRecordType(String objectTypeName, String recordTypeDevName){
//        return getRecTypeDevNameMap(objectTypeName).get(recordTypeDevName);
//    }
  

    /*
     * // ITSVMX-434 5/13/21 Tony Rationalize State and Country Picklist on Create Depot WO SFM
     * The following Gets a Map of the controlling field values and the dependent picklist values for a provided dependent field
     */
//  public static Map<String, List<String>> getDependentPicklistValues(Schema.SObjectField dependToken) {
//      Schema.DescribeFieldResult depend = dependToken.getDescribe();
//      Schema.SObjectField controlToken = depend.getController();
//      if (controlToken == null) {
//          return new Map<String, List<String>>();
//      }
//
//      Schema.DescribeFieldResult control = controlToken.getDescribe();
//      List<Schema.PicklistEntry> controlEntries;
//      if(control.getType() != Schema.DisplayType.BOOLEAN) {
//          controlEntries = control.getPicklistValues();
//      }
//
//      String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
//      Map<String,List<String>> dependentPicklistValues = new Map<String,List<String>>();
//      for (Schema.PicklistEntry entry : depend.getPicklistValues()) {
//          if (entry.isActive() && String.isNotEmpty(String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')))) {
//              List<String> base64chars =
//                      String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')).split('');
//              for (Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++) {
//                  Object controlValue =
//                          (controlEntries == null
//                                  ?   (Object) (index == 1)
//                                  :   (Object) (controlEntries[index].isActive() ? controlEntries[index].getLabel() : null)
//                          );
//                  Integer bitIndex = index / 6;
//                  if (bitIndex > base64chars.size() - 1) {
//                      break;
//                  }
//                  Integer bitShift = 5 - Math.mod(index, 6);
//                  if  (controlValue == null || (base64map.indexOf( base64chars[ bitIndex ] ) & (1 << bitShift)) == 0)
//                      continue;
//                  if (!dependentPicklistValues.containsKey((String) controlValue)) {
//                      dependentPicklistValues.put((String) controlValue, new List<String>());
//                  }
//                  dependentPicklistValues.get((String) controlValue).add(entry.getLabel());
//              }
//          }
//      }
//      return dependentPicklistValues;
//  }

}