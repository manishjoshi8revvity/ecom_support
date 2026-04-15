public with sharing class FS_WorkOrderComplaints {

	private static String WORK_COMPLETE = 'Work Complete';
	private static String HSI_YES = 'Yes';
	private static String HSI_NO = 'No';

	private FS_WorkOrderComplaints() {
	}

	public static void healthSafetyCheck(List<WorkOrder> woList)
	{
		if (!FS_Utility.isActive('Work Order HSI', 'Move Work Order Status to Status of HSI when appropriate.')) {
			return;
		}

		// SVMXINT-484 : Skip HSI for Batch Jobs
		if (System.isBatch())
		{
			// If this is an "Batch" Job, exit.. 
			System.debug('SKIPPING HSI because these Work Orders are being created in a BATCH Transaction.');
			return;
		}

		// SVMXINT-484 : Skip HSI for WO Load (Integration Profile)
		Profile prof = FS_Utility.getCurrentUserProfile();
		if (prof != null && prof.Name.containsIgnoreCase('Integration'))
		{
			// If this is an "Integration" User, exit.. 
			System.debug('SKIPPING HSI because Current User Profile is "Integration"');
			return;
		}

		//RecordType estimateRecType = FS_Utility.getRecordType('WorkOrder', 'Service_Request');

		List<WorkOrder> woToCheck = new List<WorkOrder>();
		Set<Id> ipIds = new Set<Id>();
		Set<Id> acctIds = new Set<Id>();

		for (WorkOrder wo : woList)
		{
			// Are the 3 HSI Answers filled in?
			Boolean hsiNotDone = (wo.HSI1_Answer__c == null) || (wo.HSI2_Answer__c == null) || (wo.HSI3_Answer__c == null);
			if (hsiNotDone && wo.Record_Type__c != 'Estimate' && wo.Status == 'Initializing' && wo.AssetId != null && wo.AccountId != null)
			{
				woToCheck.add(wo);
				ipIds.add(wo.AssetId);
				acctIds.add(wo.AccountId);
			}
		}

		if (woToCheck.isEmpty()) {
			return;
		}

		Set<String> hsiKeys = new Set<String>();
		for (C_SET_6910_HSI__c hsi : C_SET_6910_HSI__c.getAll().values())
		{
			if (hsi.Active__c == true) {
				hsiKeys.add(hsi.Product_Line__c + '-' + hsi.Country_Code__c);
			}
		}
		Map<Id, Asset> ipMap = new Map<Id, Asset>([SELECT Id, Name,
				Product2Id, Product2.Product_Line__c FROM Asset WHERE Id IN :ipIds]);
		Map<Id, Account> acctMap = new Map<Id, Account>([SELECT Id, Name, SAP_Country_Code__c
			FROM Account WHERE Id IN :acctIds]);
		for (WorkOrder wo : woToCheck)
		{
			Asset ip = ipMap.get(wo.AssetId);
			Account acct = acctMap.get(wo.AccountId);

			String productLine = (ip != null && ip.Product2Id != null) ? ip.Product2.Product_Line__c : null;
			String countryCode = (acct != null) ? acct.SAP_Country_Code__c : null;
			System.debug('~~ HSI: Product Line is ' + productLine + ' and Country Code is ' + countryCode);
			if (productLine != null && countryCode != null)
			{
				String hsiKey = productLine + '-' + countryCode;
				String hsiWildcardKey = productLine + '-*';
				System.debug('~~ HSI: Checking for key: ' + hsiKey);
				if (hsiKeys.contains(hsiKey) || hsiKeys.contains(hsiWildcardKey))
				{
					System.debug('~~ HSI: Found matching entry. Changing Order Status to HSI.');
					wo.Status = 'HSI';
					wo.HSI_Required__c = true;
				}
			}
		}
	}

	private static Set<String> COMPLAINT_PRIORITIES = new Set<String> { 'Complaint', 'X' };

	public static void updateManualComplaint(List<WorkOrder> woList, Map<Id, WorkOrder> oldMap)
	{
		if (!FS_Utility.isActive('Work Order Manual Complaint', 'Update the Manual Complaint field when Priority is set to Complaint.')) {
			return;
		}

		for (WorkOrder wo : woList)
		{
			WorkOrder old = (oldMap == null) ? null : oldMap.get(wo.Id);
			if (wo.Priority != null && COMPLAINT_PRIORITIES.contains(wo.Priority))
			{
				wo.ManualComplaint__c = true;
			}
		}
	}

	/*
	  Use the Custom Setting: SMAX_PS_Complaint_Rules__c... 
	  to conditionally apply the following business rules (based on Super Business Unit):
	  1. If the Work Order Priority had a value of “Complaint”
	  2. If any of the HSI Questions had answers of “Yes”
	  3. If the Fault Code(s) selected on the Debrief are configured as “Complaint Required”
	  4. If the IP is a Medical Device
	  .. and update the "Complaint Required Details" fields.
	  NOTE: MUST be called BEFORE validateComplaintAnswers(...)
	*/
	public static void updateComplaintDetails(List<WorkOrder> woList, Map<Id, WorkOrder> oldMap)
	{
		if (!FS_Utility.isActive('Work Order Complaint Details', 'Update the Complaint Required Details (and Check).')) {
			return;
		}

		Map<Id, List<WorkOrderLineItem>> faultCodeMap = new Map<Id, List<WorkOrderLineItem>>();
		for (WorkOrder wo : woList)
		{
			faultCodeMap.put(wo.Id, new List<WorkOrderLineItem>());
		}

		List<WorkOrderLineItem> allFaultCodes = [SELECT Id, LineItemNumber, Line_Type__c, Status, WorkOrderId,
				Fault_Code__c, Fault_Code__r.Complaint_Required__c,
				Fault_Code_Group__c, Fault_Code_Group__r.Code_Group__c,
				ActionFaultCode__c, ActionFaultCode__r.Complaint_Required__c,
				InstallationFaultCode__c, InstallationFaultCode__r.Complaint_Required__c,
				CompletionFaultCode__c, CompletionFaultCode__r.Complaint_Required__c
		FROM WorkOrderLineItem WHERE WorkOrderId IN :faultCodeMap.keySet() AND Line_Type__c = 'Fault Code'];
		for (WorkOrderLineItem faultCodeLine : allFaultCodes)
		{
			faultCodeMap.get(faultCodeLine.WorkOrderId).add(faultCodeLine);
		}

		for (WorkOrder wo : woList)
		{
			// SVMXCFG-361 - Complaints: DAS vs DX Rules
			C_SET_6910_COMPLAINT_RULES__c rules = getComplaintRules(wo);

			WorkOrder old = (oldMap == null) ? null : oldMap.get(wo.Id);
			if (old != null)
			{
				List<String> conditionMsgs = new List<String>();
				if (rules.Condition_Manual_Complaint__c == true && wo.ManualComplaint__c == true)
				{
					conditionMsgs.add('The Work Order was marked as a Manual Complaint.');
				}

				if (rules.Condition_HSI_Yes__c == true && anyHsiYes(wo))
				{
					conditionMsgs.add('One or more HSI Answer was "Yes".');
				}

				Boolean fcRequiresComplaint = false;
				if (rules.Condition_Fault_Code_Com_Reqd__c == true)
				{
					// Loop through Fault Codes, looking at Action, Completion and Installation Codes
					for (WorkOrderLineItem fcLine : faultCodeMap.get(wo.Id))
					{
						fcRequiresComplaint = fcRequiresComplaint
								|| isComplaintRequired(fcLine.ActionFaultCode__r)
								|| isComplaintRequired(fcLine.InstallationFaultCode__r)
								|| isComplaintRequired(fcLine.CompletionFaultCode__r);
					}
				}

				if (rules.Condition_Restrict_PC_Com_Reqd__c == false)
				{
					// Loop through Fault Codes, looking at Problem Codes
					for (WorkOrderLineItem fcLine : faultCodeMap.get(wo.Id))
					{
						fcRequiresComplaint = fcRequiresComplaint
								|| isComplaintRequired(fcLine.Fault_Code__r);
					}
				}
				else
				{
					// ONLY look at the Problem Code if Indicator(s) are true AND Problem Group matches
					List<String> indicatorFields = rules.Condition_Restrict_PC_Indicators__c.split(',');
					Boolean indicators = false;
					for (String indicatorField : indicatorFields)
					{
						Boolean indicatorValue = (Boolean)wo.get(indicatorField);
						indicators = indicators || indicatorValue;
					}

					if (indicators)
					{
						String probGroup = rules.Condition_Restrict_PC_Group__c;
						// Loop through Fault Codes, looking at Problem Codes
						for (WorkOrderLineItem fcLine : faultCodeMap.get(wo.Id))
						{
							if (fcLine.Fault_Code_Group__r != null &&
									fcLine.Fault_Code_Group__r.Code_Group__c == probGroup)
							{
								fcRequiresComplaint = fcRequiresComplaint
										|| isComplaintRequired(fcLine.Fault_Code__r);
							}
						}
					}
				}

				if (fcRequiresComplaint)
				{
					conditionMsgs.add('One or more of the Fault Codes debriefed are marked as "Complaint Required".');
				}

				if (rules.Condition_Medical_Device__c == true && wo.IsMedicalDevice__c == true)
				{
					conditionMsgs.add('The Installed Product is a Medical Device.');
				}

				if (!conditionMsgs.isEmpty())
				{
					String details = 'The Complaint data must be captured because: ';
					for (String conditionMsg : conditionMsgs) {
						details += '\n' + conditionMsg;
					}
					wo.Complaint_Required_Details__c = details;
					wo.Complaint_Required_Details_Check__c = true;
				}
				else
				{
					wo.Complaint_Required_Details__c = null;
					wo.Complaint_Required_Details_Check__c = false;
				}
			}
		}
	}

	/*
	  Use the Custom Setting: SMAX_PS_Complaint_Rules__c... 
	  to conditionally apply the following business rules (based on Super Business Unit):
	  If the "Complaint Required Details" are not blank, validate the following:
	  1. All of the 3 HSI questions are Yes or No, if any are filled in.
	  2. All of the 5 Regulatory questions are answered (sometimes tied to HSI)
	  3. All of the 5 Additional Information fields are answered
	  NOTE: MUST be called AFTER updateComplaintDetails(...)
	*/
	public static void validateComplaintAnswers(List<WorkOrder> woList, Map<Id, WorkOrder> oldMap)
	{
		if (!FS_Utility.isActive('Work Order Validate Complaints', 'Validate that the required Complaints data has been entered if necessary.')) {
			return;
		}

		for (WorkOrder wo : woList)
		{
			// SVMXCFG-361 - Complaints: DAS vs DX Rules
			C_SET_6910_COMPLAINT_RULES__c rules = getComplaintRules(wo);

			WorkOrder old = (oldMap == null) ? null : oldMap.get(wo.Id);
			if (old != null && old.Status != wo.Status && wo.Status == WORK_COMPLETE)
			{
				List<String> errorMsgs = new List<String>();

				// SVMXCFG-841 HSI - Must Answer to Complete
				Boolean hsiStarted = (wo.HSI_Required__c == true) || (wo.HSI1_Answer__c != null) || (wo.HSI2_Answer__c != null) || (wo.HSI3_Answer__c != null);
				Boolean hsiDone = isValidHsiAnswer(wo.HSI1_Answer__c) && isValidHsiAnswer(wo.HSI2_Answer__c) && isValidHsiAnswer(wo.HSI3_Answer__c);
				if (rules.Validation_HSI_Answered__c == true && hsiStarted && (!hsiDone))
				{
					errorMsgs.add('The HSI Questions must be answered with a Yes or No value before Completing the Work Order.');
				}

				if (wo.Complaint_Required_Details__c != null)
				{
					Boolean anyRegulatoryBlank = (String.isBlank(wo.Q1_Response__c)
							|| String.isBlank(wo.Q2_Response__c)
							|| String.isBlank(wo.Q3_Response__c)
							|| String.isBlank(wo.Q4_Response__c)
							|| String.isBlank(wo.Q5_Response__c));
					Boolean anyHsiYes = anyHsiYes(wo);
					if ((rules.Validation_Regulatory_Answered__c == true && anyRegulatoryBlank)
							|| (rules.Validation_Regulatory_When_HSI__c == true && anyHsiYes && anyRegulatoryBlank))
					{
						errorMsgs.add('The Regulatory Questions must be answered before Completing the Work Order.');
					}

					Boolean anyGuidanceBlank = (String.isBlank(wo.Q1_Answer__c)
							|| String.isBlank(wo.Q2_Answer__c)
							|| String.isBlank(wo.Q3_Answer__c)
							|| String.isBlank(wo.Q4_Answer__c)
							|| String.isBlank(wo.Q5_Answer__c));
					if (rules.Validation_Guidance_Not_Blank__c == true && anyGuidanceBlank)
					{
						errorMsgs.add('The Guidance Questions must be answered before Completing the Work Order.');
					}
				}

				if (!errorMsgs.isEmpty())
				{
					String errorMsg = '\nACTIONS NEEDED:\n' + errorMsgs;
					if (wo.Complaint_Required_Details__c != null)
					{
						errorMsg = errorMsg + '\nNOTE: ' + wo.Complaint_Required_Details__c;
					}
					// SVMXCFG-327 - Use a Order Status / Message field instead of Apex Errors
					//wo.addError(errorMsg);
					wo.Completion_Errors__c = errorMsg;
					wo.Status = 'Work Complete - Error';
				}
				else
				{
					wo.Completion_Errors__c = null;
				}
			}
		}
	}

	private static C_SET_6910_COMPLAINT_RULES__c getComplaintRules(WorkOrder wo)
	{
		String superBU = wo.Super_Business_Unit__c;
		if (superBU == null)
		{
			superBU = 'ZZZ';
			System.debug('COMPLAINTS: No Super Business Unit Found.. Using Default: ' + superBU);
		}

		C_SET_6910_COMPLAINT_RULES__c rules = C_SET_6910_COMPLAINT_RULES__c.getInstance(superBU);
		if (rules == null)
		{
			rules = new C_SET_6910_COMPLAINT_RULES__c();
			// Default Conditions..
			rules.Condition_HSI_Yes__c = true;
			rules.Condition_Manual_Complaint__c = true;
			rules.Condition_Fault_Code_Com_Reqd__c = true;
			rules.Condition_Restrict_PC_Com_Reqd__c = false;
			rules.Condition_Medical_Device__c = false;
			// Default Validations..
			rules.Validation_HSI_Answered__c = true;
			rules.Validation_Regulatory_Answered__c = true;
			rules.Validation_Guidance_Not_Blank__c = true;
			rules.Validation_Regulatory_When_HSI__c = false;
			System.debug('COMPLAINTS: No Complaint Rules Found for: ' + superBU + '.. Using Default: ' + rules);
		}
		return rules;
	}

	private static Boolean isComplaintRequired(FS_FaultCode__c fc)
	{
		if (fc != null && fc.Complaint_Required__c != null)
		{
			return fc.Complaint_Required__c > 0;
		}
		return false;
	}

	private static Boolean anyHsiYes(WorkOrder wo)
	{
		return (wo.HSI1_Answer__c == HSI_YES || wo.HSI2_Answer__c == HSI_YES || wo.HSI3_Answer__c == HSI_YES);
	}

	private static Boolean isValidHsiAnswer(String val)
	{
		return (val != null && (val == HSI_YES || val == HSI_NO));
	}


}