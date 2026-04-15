/**
 * InvocableAction to get Platform Event Details (JSON & ReplayId)
 * Created by frankvanloon on 3/14/24.
 */
public with sharing class FS_PlatformEventAction {

	public with sharing class PlatformEventRequest {
		@InvocableVariable(Required=true)
		public SObject evt;
	}

	public with sharing class PlatformEventResult {
		@InvocableVariable
		public String eventJSON;
		@InvocableVariable
		public Integer replayId;
	}

	@InvocableMethod(Label='Get Platform Event Details')
	public static List<PlatformEventResult> getPlatformEventDetails(List<PlatformEventRequest> requests) {
		List<PlatformEventResult> results = new List<PlatformEventResult>();

		// Get Platform Event JSON and ReplayId
		for (PlatformEventRequest request : requests) {
			PlatformEventResult result = new PlatformEventResult();
			result.eventJSON = JSON.serialize(request.evt);
			String replayIdVal = (String) request.evt.get('ReplayId');
			if (String.isNotBlank(replayIdVal)) {
				result.replayId = Integer.valueOf(replayIdVal);
			}
			results.add(result);
		}

		return results;
	}
}