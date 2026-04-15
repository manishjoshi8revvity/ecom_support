public with sharing class FS_PlatformEventUtility {
  private FS_PlatformEventUtility() { }

//  public static FS_PlatformEventLog__c createEventLog(SObject evt, String elementId, String action)
//  {
//    FS_PlatformEventLog__c log = new FS_PlatformEventLog__c();
//    log.Related_Element_Id__c = elementId;
//    log.Action__c = action;
//    log.Platform_Event_Type__c = evt.getSObjectType().getDescribe().getName();
//    log.Event_JSON__c = JSON.serialize(evt);
//    log.Replay_Id__c =  Integer.valueOf((String)evt.get('ReplayId'));
//    return log;
//  }


  public static void publishEvents(List<SObject> events, String idField, String actionField)
  {
        if (!events.isEmpty())
        {
            List<FS_PlatformEventLog__c> logs = new List<FS_PlatformEventLog__c>();
            Database.SaveResult[] results = EventBus.publish(events);
            for (Integer i = 0; i < results.size(); i++)
            {
                Database.SaveResult result = results[i];
                if (!result.isSuccess())
                {
                    SObject iEvent = events[i];
                    FS_PlatformEventLog__c log = new FS_PlatformEventLog__c();
                    log.Error_Message__c = 'Error publishing Event: ' + result.getErrors();
                    if (log.Error_Message__c.length() > 255) {
                        log.Error_Message__c = log.Error_Message__c.substring(0, 250) + '...';
                    }
                    log.Event_JSON__c = JSON.serialize(iEvent);
                    log.Platform_Event_Type__c = iEvent.getSObjectType().getDescribe().getName();
                    log.Related_Element_Id__c = (String)iEvent.get(idField);
                    if (actionField != null) {
                        log.Action__c = (String) iEvent.get(actionField);
                    }
                    logs.add(log);
                }
            }
            if (!logs.isEmpty()) {
                insert logs;
            }
        }
    }

    public static String resendEvent(String evtName)
    {
        List<FS_PlatformEventLog__c> logs = [SELECT Id, Name, Platform_Event_Type__c, Event_JSON__c
            FROM FS_PlatformEventLog__c WHERE Name = :evtName];
        return resendEvents(logs);
    }

    public static String resendEvents(List<FS_PlatformEventLog__c> logs)
    {
        List<SObject> events = new List<SObject>();
        for (FS_PlatformEventLog__c log : logs)
        {
            String eventType = log.Platform_Event_Type__c;
            String jsonStr = log.Event_JSON__c;
            System.debug('EVENT JSON: ' + jsonStr);
            Type t = Type.forName(eventType);
            // Schema.getGlobalDescribe().get(eventType)
            SObject deserialized = (SObject) JSON.deserialize(jsonStr, t);
            System.debug('DESERIALIZED EVENT: ' + deserialized);
            Map<String,Object> fieldMap = deserialized.getPopulatedFieldsAsMap();
            SObject iEvent = Schema.getGlobalDescribe().get(eventType).newSObject();
            for (String field : fieldMap.keySet())
            {
                if (field.endsWith('__c'))
                {
                    iEvent.put(field, fieldMap.get(field));
                }
            }
            System.debug('EVENT TO SEND: ' + iEvent);
            events.add(iEvent);
        }

        String retVal = '';
        if (!events.isEmpty())
        {
            Database.SaveResult[] results = EventBus.publish(events);
            for (Integer i = 0; i < results.size(); i++)
            {
                Database.SaveResult result = results[i];
                if (!result.isSuccess())
                {
                    SObject iEvent = events[i];
                    System.debug('Error publishing Event: ' + result.getErrors());
                    retVal += 'Error publishing Event: ' + result.getErrors() + '\n';
                }
            }
        }
        return retVal;
    }
}