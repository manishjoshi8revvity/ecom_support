/**
 * InvocableAction to resend a Platform Event
 * Created by frankvanloon on 3/15/24.
 */
public with sharing class FS_PlatformEventResendAction {

	public with sharing class PlatformEventResendRequest {
		@InvocableVariable(Required=true)
		public Id eventLogId;
	}

	public with sharing class PlatformEventResendResult {
		@InvocableVariable
		public Boolean success;
		@InvocableVariable
		public String message;
	}

	@InvocableMethod(Label='Resend Platform Event')
	public static List<PlatformEventResendResult> resendPlatformEvent(List<PlatformEventResendRequest> requests) {
		List<Id> idList = new List<Id>();
		for (PlatformEventResendRequest request : requests) {
			idList.add(request.eventLogId);
		}

		Map<Id, FS_PlatformEventLog__c> logs = new Map<Id, FS_PlatformEventLog__c>(
			[SELECT Id, Name, Platform_Event_Type__c, Event_JSON__c FROM FS_PlatformEventLog__c WHERE Id IN :idList]);
		List<SObject> events = new List<SObject>();
		for (PlatformEventResendRequest request : requests) {
			FS_PlatformEventLog__c log = logs.get(request.eventLogId);
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

		List<PlatformEventResendResult> results = new List<PlatformEventResendResult>();
		if (!events.isEmpty())
		{
			Database.SaveResult[] eventResults = EventBus.publish(events);
			for (Integer i = 0; i < eventResults.size(); i++)
			{
				Database.SaveResult eventResult = eventResults[i];
				PlatformEventResendResult result = new PlatformEventResendResult();
				result.success = eventResult.isSuccess();
				result.message = eventResult.isSuccess() ? 'Successfully Resent Event'
					: 'Error publishing Event: ' + eventResult.getErrors();
				System.debug('RESULT = ' + result);
				results.add(result);
			}
		}
		return results;
	}
}