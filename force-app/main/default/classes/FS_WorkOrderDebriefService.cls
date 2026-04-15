/**
 *  This Web Service handles the "Debrief Response" from SAP for a One-Click Complete transaction.
 *  This class handles all of the logic for transitioning the Work Order from "Work Complete - Pending" to "Work Complete".
 *
 *  Frank VanLoon 		2018-05-11
 *  CONVERTED to SFS by frankvanloon on 4/23/24.
 */
global class FS_WorkOrderDebriefService {

	global class DebriefResponse
	{
		webService String NotificationNumber { get; set; }
		webService String ServiceOrderNumber { get; set; }
		webService Boolean CreditHold { get; set; }
		webService String CreditHoldReason { get; set; }
		webService String SystemStatus { get; set; }
		webService String UserStatus { get; set; }
		webService String ErrorMessage { get; set; }
		webService String TransactionNumber { get; set; }

		webService List<DebriefLine> Lines { get; set; }
	}

	global class DebriefLine
	{
		webService String LineType { get; set; }
		webService String LineId { get; set; }
		webService String ConfirmationNumber { get; set; }
		webService String ErrorMessage { get; set; }
	}

	public FS_WorkOrderDebriefService() {
	}

	webService static String submitDebriefResponse(DebriefResponse debrief)
	{
		String soNum = debrief.ServiceOrderNumber;
		List<WorkOrder> woList = [SELECT Id, WorkOrderNumber, Status, Completion_Errors__c,
				SAP_Notification_ID__c, External_ID__c, CreditHold__c, CreditHoldReason__c,
				SAP_SystemStatus__c, SAP_Order_Status__c, SAP_Activity_Status__c
			FROM WorkOrder WHERE External_ID__c = :soNum];
		WorkOrder wo = (woList != null && woList.size() == 1) ? woList.get(0) : null;

		System.debug('DEBRIEF-RESPONSE Loaded WO: ' + wo);

		return processDebriefResponse(wo, debrief);
	}

	public static String processDebriefResponse(WorkOrder wo, DebriefResponse debrief)
	{
		// Set this flag so the One-Click Complete logic doens't run again at end
		FS_WorkOrderDebriefManager.IS_PROCESSING_DEBRIEF_RESPONSE = true;

		List<FS_IntegrationError__c> intErrors = new List<FS_IntegrationError__c>();

		System.debug('DEBRIEF-RESPONSE Started: ' + debrief);
		String soNum = debrief.ServiceOrderNumber;

		if (wo == null)
		{
			String msg = 'Could NOT find Work Order with External ID: ' + soNum;
			intErrors.add(createIntegrationError(debrief, 'Submit Debrief Response Error: ' + msg));
		}
		else if (wo.Status != FS_WorkOrderDebriefManager.WORK_COMPLETE_PENDING
				&& wo.Status != FS_WorkOrderDebriefManager.WORK_COMPLETE_ERROR) // SVMXCFG-869
		{
			String msg = 'Cannot process Debrief Response. Work Order NOT "Work Complete - Pending". Order Status = "' + wo.Status + '"';
			intErrors.add(createIntegrationError(debrief, msg));
		}
		else
		{
			wo.Completion_Errors__c = null;
			wo.CreditHold__c = debrief.CreditHold;
			if (debrief.CreditHoldReason != null) {
				wo.CreditHoldReason__c = debrief.CreditHoldReason;
			}
			wo.SAP_SystemStatus__c = debrief.SystemStatus;
			if (String.isNotBlank(debrief.UserStatus))
			{
				Integer firstSemi = debrief.UserStatus.indexOf(';');
				if (firstSemi > 0)
				{
					wo.SAP_Order_Status__c = debrief.UserStatus.substring(0, firstSemi);
					wo.SAP_Activity_Status__c = debrief.UserStatus.substring(firstSemi+1);
				}
				else
				{
					wo.SAP_Order_Status__c = debrief.UserStatus;
					wo.SAP_Activity_Status__c = null;
				}
			}
			if (String.isNotBlank(debrief.ErrorMessage))
			{
				if (!debrief.ErrorMessage.contains('status changed to TECO successfully')) {
					intErrors.add(createIntegrationError(debrief, debrief.ErrorMessage));
				}
			}

//			Id usageRecTypeId = Utility.getRecordType('WorkOrderLineItem', 'UsageConsumption').Id;
//			// ITSFDC-1047 Also look for "Remote Support" Record Type
//			Id remoteRecTypeId = Utility.getRecordType('WorkOrderLineItem', 'Remote_Support').Id;

			// Select the Work Detail lines which qualify for updation
			Map<String, WorkOrderLineItem> lineMap = new Map<String, WorkOrderLineItem>();
			for(WorkOrderLineItem line : [SELECT Id, LineItemNumber,
					Status, Line_Type__c, WorkOrderId,
					SAP_Confirmation__c
				FROM WorkOrderLineItem WHERE WorkOrderId = :wo.Id
					//AND RecordTypeId IN (:usageRecTypeId, :remoteRecTypeId)
					AND Status!='Canceled'])
			{
				lineMap.put(line.LineItemNumber, line);
			}

			List<WorkOrderLineItem> linesToUpdate = new List<WorkOrderLineItem>();
			if (debrief.Lines != null)
			{
				for (DebriefLine dLine : debrief.Lines)
				{
					WorkOrderLineItem line = lineMap.get(dLine.LineId);
					if (line == null)
					{
						String msg = 'Could NOT find Work Detail with External ID: ' + dLine.LineId;
						intErrors.add(createIntegrationError(debrief, 'Submit Debrief Response Error: ' + msg));
					}
					else
					{
						String confNum = String.isNotBlank(dLine.ConfirmationNumber) ? dLine.ConfirmationNumber : null;
						if (confNum != null && (confNum == '0000000000' || confNum == '0000000000-00000000')) {
							confNum = null;
						}

						if (confNum != null)
						{
							line.SAP_Confirmation__c = confNum;
							linesToUpdate.add(line);
						}
						else if (String.isNotBlank(dLine.ErrorMessage))
						{
							String msg = dLine.ErrorMessage;
							intErrors.add(createIntegrationError(debrief, line, msg));
						}
						else if (line.Line_Type__c == 'Fault Code')
						{
							line.Status = 'Confirmed';
							linesToUpdate.add(line);
						}
					}
				}
			}

			if (!linesToUpdate.isEmpty())
			{
				Database.SaveResult[] results = Database.update(linesToUpdate, false);
				for (Integer i = 0; i < results.size(); i++)
				{
					Database.SaveResult result = results[i];
					if (!result.isSuccess())
					{
						WorkOrderLineItem line = linesToUpdate[i];
						String msg = 'Debrief Response Error while Updating Work Detail: ' + result.getErrors();
						intErrors.add(createIntegrationError(debrief, line, msg));
					}
				}
			}

			// Lookup lines not "done" (Canceled or Confirmed).. 
			List<WorkOrderLineItem> linesNotDone = [SELECT Id, LineItemNumber,
					Status, Line_Type__c, IntegrationStatus__c, WorkOrderId
				FROM WorkOrderLineItem WHERE WorkOrderId = :wo.Id
//					AND RecordTypeId IN (:usageRecTypeId, :remoteRecTypeId)
					AND Status = 'Submitted'
					AND IntegrationStatus__c != 'Error'];

			if (!linesNotDone.isEmpty())
			{
				String msg = 'Debrief Response processed, but there are still ' + linesNotDone.size() + ' Debrief line(s) not Confirmed or Canceled.';
				intErrors.add(createIntegrationError(debrief, msg));

				// Added June4: If Debrief Response received, move any Submitted lines to Error.. assume error if not included in response
				List<WorkOrderLineItem> errorLines = new List<WorkOrderLineItem>();
				for (WorkOrderLineItem line : linesNotDone)
				{
					if (line.Status == 'Submitted' && line.IntegrationStatus__c != 'Error')
					{
						line.IntegrationStatus__c = 'Error';
						errorLines.add(line);
					}
				}

				if (!errorLines.isEmpty()) {
					update errorLines;
				}
			}

			// if ANY lines OR header Error from SAP, push to "Error", else go to "Work Complete"
			if (!intErrors.isEmpty())
			{
				wo.Status = FS_WorkOrderDebriefManager.WORK_COMPLETE_ERROR;
				wo.Completion_Errors__c = 'Error Processing Debrief Response. One or more Integration Errors were received.  Please review and correct.';
			}
			else
			{
				wo.Status = FS_WorkOrderDebriefManager.WORK_COMPLETE;
			}

			//update wo;
			Database.SaveResult woResult = Database.update(wo, false);
			if (!woResult.isSuccess())
			{
				// Probably a problem with input status values, etc.. 
				String msg = 'Debrief Response Error while Updating Work Order: ' + woResult.getErrors();
				intErrors.add(createIntegrationError(debrief, msg));

				WorkOrder errorWo = new WorkOrder();
				errorWo.Id = wo.Id;
				errorWo.Status = FS_WorkOrderDebriefManager.WORK_COMPLETE_ERROR;
				Database.update(errorWo, false);
			}
		}

		if (!intErrors.isEmpty()) {
			insert intErrors;
		}

		String result = null;
		for (FS_IntegrationError__c ie : intErrors)
		{
			result = (result == null) ? '' : result + ', ';
			result += ie.ErrorMessage__c;
		}
		return (result == null) ? 'Successfully processed Debrief Response' : result;
	}

	private static FS_IntegrationError__c createIntegrationError(DebriefResponse debrief, String msg)
	{
		return new FS_IntegrationError__c( ErrorMessage__c = msg,
				TrackingNumber__c = debrief.TransactionNumber,
				RelatedElementType__c = 'ServiceOrderNumber',
				RelatedElementIdentifier__c = debrief.ServiceOrderNumber );
	}
	private static FS_IntegrationError__c createIntegrationError(DebriefResponse debrief, WorkOrderLineItem line, String msg)
	{
		return new FS_IntegrationError__c( ErrorMessage__c = msg,
				TrackingNumber__c = debrief.TransactionNumber,
				RelatedElementType__c = 'WorkOrderLineItemId',
				RelatedElementIdentifier__c = line.Id );
	}

}