/**
 * Replacement for the SVMX_PS_ES_Email_Handler_Files utility to send Field Service Report (PDF) as emails
 * Created by frankvanloon on 7/2/24.
 */
public without sharing class FS_WorkOrderEmails implements Schedulable, Database.Batchable<ServiceReport>, Database.AllowsCallouts, Database.Stateful {

	// --------------------------------------- Schedulable methods

	public static void scheduleEmailJobs() {
		FS_WorkOrderEmails emailHandler = new FS_WorkOrderEmails();
		String schedule00 = '0 0 * * * ?';
		String schedule10 = '0 10 * * * ?';
		String schedule20 = '0 20 * * * ?';
		String schedule30 = '0 30 * * * ?';
		String schedule40 = '0 40 * * * ?';
		String schedule50 = '0 50 * * * ?';
		if (!Test.isRunningTest()) {
			System.schedule('Work Order Email Job 00', schedule00, emailHandler);
			System.schedule('Work Order Email Job 10', schedule10, emailHandler);
			System.schedule('Work Order Email Job 20', schedule20, emailHandler);
			System.schedule('Work Order Email Job 30', schedule30, emailHandler);
			System.schedule('Work Order Email Job 40', schedule40, emailHandler);
			System.schedule('Work Order Email Job 50', schedule50, emailHandler);
		}
	}

	public void execute(SchedulableContext ctx) {
		FS_WorkOrderEmails batch = new FS_WorkOrderEmails();
		Database.executeBatch(batch, 8);
	}

	// --------------------------------------- Batchable methods

	public Iterable<ServiceReport> start(Database.BatchableContext ctx) {
		List<ServiceReport> reportList = findServiceReportsToSend(null);
		return reportList;
	}

	public void execute(Database.BatchableContext ctx, List<ServiceReport> scope) {
		C_SET_6800_WO_EMAIL_DOCUMENTS__c settings = C_SET_6800_WO_EMAIL_DOCUMENTS__c.getOrgDefaults();
		List<FS_WorkOrderEmails_ServiceReport> reports = prepareServiceReports(scope);
		System.debug('PREPARED EMAILS for ' + reports.size() + '/' + scope.size() + ' Service Reports');
		List<Messaging.SingleEmailMessage> messagesList = new List<Messaging.SingleEmailMessage>();
		List<Task> taskList = new List<Task>();
		for (FS_WorkOrderEmails_ServiceReport report : reports) {
			System.debug('EMAIL TO SEND: ' + report);

			Id fileVersionId = report.svcReport.ContentVersionDocumentId;
			Id ownerId = report.svcReport.ContentVersionDocument.OwnerId;
			if (Test.isRunningTest()) {
				ownerId = UserInfo.getUserId();
			}

			Messaging.SingleEmailMessage dummy = createDummyMessage(report.emailTemplate,
				settings.Default_Contact_ID__c, fileVersionId, report.workOrderId);

			// Send Emails
			Messaging.SingleEmailMessage msg = createMessage(report.toAddresses, report.ccAddresses, report.bccAddresses,
					fileVersionId, dummy, report.orgWideAddress);
			messagesList.add(msg);
			if (settings.Save_Send_Email_as_Activity__c) {
				// Save Activities / Tasks
				Task task = createActivityForLogging(ownerId, report.workOrderId,
						report.toAddresses, report.ccAddresses, report.bccAddresses,
						report.svcReport.ServiceReportNumber, msg.getPlainTextBody(), msg.getSubject());
				taskList.add(task);
			}
		}

		if (messagesList.size() > 0) {
			System.debug('Email Files handler: Total Emails to be sent : ' + messagesList.size());
			if (!Test.isRunningTest()) {
				Messaging.sendEmail(messagesList);
			}
			System.debug('Email Files handler: Email(s) Sent');
		} else {
			System.debug('Email Files handler: No Emails sent');
		}

		if (settings.Save_Send_Email_as_Activity__c) {
			if (taskList != null && taskList.size() > 0) {
				System.debug('Email Files handler: Total Tasks to be created : ' + taskList.size());
				insert taskList;
				System.debug('Email Files handler: Tasks Created');
			} else {
				System.debug('Email Files handler: No Tasks to add');
			}
		} else {
			System.debug('Email Files handler: Do not add tasks');
		}

	}

	public void finish(Database.BatchableContext ctx) {
	}

	// --------------------------------------- Action (Flow) methods

	public with sharing class ServiceReportEmailRequest {
		@InvocableVariable(Required=false)
		public Datetime lastRunDate;
	}

	public with sharing class ServiceReportEmailResult {
		@InvocableVariable
		public List<FS_WorkOrderEmails_ServiceReport> reports;
	}

	@InvocableMethod(Label='Get Service Reports to Send')
	public static List<ServiceReportEmailResult> getServiceReportsToSend(List<ServiceReportEmailRequest> requests) {
		List<ServiceReportEmailResult> results = new List<ServiceReportEmailResult>();

		// Find & Prepare Service Reports to Send
		for (ServiceReportEmailRequest request : requests) {
			ServiceReportEmailResult result = new ServiceReportEmailResult();
			List<ServiceReport> reportList = findServiceReportsToSend(request.lastRunDate);
			result.reports = prepareServiceReports(reportList);
			results.add(result);
		}
		return results;
	}

	// --------------------------------------- Utility methods

	public static List<ServiceReport> findServiceReportsToSend(Datetime lastRunOverride) {
		List<ServiceReport> result = null;
		C_SET_6800_WO_EMAIL_DOCUMENTS__c settings = C_SET_6800_WO_EMAIL_DOCUMENTS__c.getOrgDefaults();
		System.debug('LOADED EMAIL SETTINGS: ' + settings);
		if (settings != null) {
			// Load and increment the "Last Run Time"
			Datetime lastRunDate = settings.Last_Run_Time__c;
			if (lastRunOverride != null) {
				lastRunDate = lastRunOverride;
			} else if (lastRunDate == null) {
				lastRunDate = Datetime.now();
			}
			settings.Last_Run_Time__c = Datetime.now();
			if (!Test.isRunningTest()) {
				update settings;
			}

			// Query for Service Reports created since the previous "Last Run Time"...
			result = [SELECT Id, ServiceReportNumber, CreatedBy.Alias, CreatedDate,
					ContentVersionDocumentId, ContentVersionDocument.OwnerId, ContentVersionDocument.Owner.Email,
					DocumentTemplate, ParentId
				FROM ServiceReport
				WHERE CreatedDate >= :lastRunDate
				ORDER BY CreatedDate DESC];
		}
		return result;
	}

	public static List<FS_WorkOrderEmails_ServiceReport> prepareServiceReports(List<ServiceReport> svcReports) {
		List<FS_WorkOrderEmails_ServiceReport> results = new List<FS_WorkOrderEmails_ServiceReport>();

		// Load Settings and Metadata
		String woPrefix = Schema.SObjectType.WorkOrder.getKeyPrefix();
		C_SET_6800_WO_EMAIL_DOCUMENTS__c settings = C_SET_6800_WO_EMAIL_DOCUMENTS__c.getInstance();
		Map<String, String> docTemplateEmailMap = new Map<String, String>();
		for (C_META_FS_Service_Document__mdt svcDoc : C_META_FS_Service_Document__mdt.getAll().values()) {
			if (svcDoc.Service_Document_Id__c != null && svcDoc.Email_Template_Name__c != null) {
				docTemplateEmailMap.put(svcDoc.Service_Document_Id__c, svcDoc.Email_Template_Name__c);
			}
		}
		System.debug('FOUND EMAIL TEMPLATES: ' + docTemplateEmailMap);

		Map<String, EmailTemplate> emailTemplateMap = new Map<String, EmailTemplate>();
		Set<String> templateDevNames = new Set<String>(docTemplateEmailMap.values());
		// Load email template used for all e-mails
		List<EmailTemplate> emailTemplateBaseList = [SELECT Id, Name, Subject, Body, HtmlValue, DeveloperName
			FROM EmailTemplate WHERE DeveloperName IN :templateDevNames];
		if (emailTemplateBaseList != null) {
			for (EmailTemplate emailTemplate : emailTemplateBaseList) {
				emailTemplateMap.put(emailTemplate.DeveloperName, emailTemplate);
			}
		}

		// Filter to Work Orders only
		Set<Id> woIds = new Set<Id>();
		for (ServiceReport svcReport : svcReports) {
			String parentId = '' + svcReport.ParentId;
			if (parentId.startsWith(woPrefix)) {
				woIds.add(svcReport.ParentId);
			}
		}

		if (!woIds.isEmpty()) {
			Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>([
					SELECT Id, WorkOrderNumber, Record_Type__c,
							ES_Send_Service_Report_To_Cust__c, ES_Email_To_Customer__c,
							ES_Send_Service_Report_To_Owner__c, Owner.Email,
							ES_Send_Service_ReportTo_Contact__c, Contact_Email__c,
							ES_Cc_Additional_People__c, ES_Cc_Email_Additional_People__c,
						Translation__r.Email_ID__c
					FROM WorkOrder
					WHERE Id IN :woIds
			]);
			System.debug('LOADED WO(s) for EMAILS: ' + woMap.size());

			for (ServiceReport svcReport : svcReports) {
				WorkOrder wo = woMap.get(svcReport.ParentId);
				String emailTemplateName = docTemplateEmailMap.get(svcReport.DocumentTemplate);
				System.debug('WO for EMAIL[' + emailTemplateName + ']: ' + wo);
				if (wo != null && emailTemplateName != null) {
					FS_WorkOrderEmails_ServiceReport result = new FS_WorkOrderEmails_ServiceReport();
					result.svcReport = svcReport;
					result.contactId = settings.Default_Contact_ID__c;
					result.workOrderId = wo.Id;
					result.emailTemplateName = emailTemplateName;
					result.emailTemplate = emailTemplateMap.get(emailTemplateName);
					result.orgWideAddress = settings.Default_Org_Wide_Address__c;
					if (wo.Translation__r.Email_ID__c != null) {
						result.orgWideAddress = wo.Translation__r.Email_ID__c;
					}
					// Fill in the to, cc and bcc addresses
					result.toAddresses = new List<String>();
					if (wo.ES_Send_Service_Report_To_Cust__c && String.isNotBlank(wo.ES_Email_To_Customer__c)) {
						result.toAddresses.add(wo.ES_Email_To_Customer__c);
					}
					if (wo.ES_Send_Service_Report_To_Owner__c && String.isNotBlank(wo.Owner.Email)) {
						result.toAddresses.add(wo.Owner.Email);
					}
					if (wo.ES_Send_Service_ReportTo_Contact__c && String.isNotBlank(wo.Contact_Email__c)) {
						result.toAddresses.add(wo.Contact_Email__c);
					}
					result.ccAddresses = new List<String>();
					if (wo.ES_Cc_Additional_People__c && String.isNotBlank(wo.ES_Cc_Email_Additional_People__c)) {
						result.ccAddresses.add(wo.ES_Cc_Email_Additional_People__c);
					}
					result.bccAddresses = new List<String>();
					if (settings.Send_To_Default_Email_Address__c && String.isNotBlank(settings.Default_Email_Address__c)) {
						result.bccAddresses.add(settings.Default_Email_Address__c);
					}

					if (!result.toAddresses.isEmpty()) {
						results.add(result);
					} else {
						System.debug('Skipping WO EMAIL because no "to" addresses found: '
							+ svcReport.ServiceReportNumber + ' - ' + wo.WorkOrderNumber);
					}
				}
			}
		}
		return results;
	}

	private static Messaging.SingleEmailMessage createDummyMessage(EmailTemplate emailTemplate, Id contactId, Id fileVersionId, Id whatId) {
		Messaging.SingleEmailMessage dummy = null;
		if (emailTemplate != null) {
			// Create dummy email using template, then rollback to change the recipients...
			dummy = new Messaging.SingleEmailMessage();
			dummy.setTemplateId(emailTemplate.Id);
			dummy.setTargetObjectId(contactId);
			if (fileVersionId != null) {
				dummy.setEntityAttachments(new Id[] { fileVersionId });
			}
			dummy.setSaveAsActivity(false);
			dummy.setWhatId(whatId);
			// Send the emails in a transaction, then roll it back in order to use the template with external email addresses
			// This will count against DML limits so we must be certain that an iPad/offline user will sync (insert/update)
			// no more than 75 Service Report files in a single sync.
			if (!Test.isRunningTest()) {
				Savepoint sp = Database.setSavepoint();
				Messaging.sendEmail(new Messaging.SingleEmailMessage[] { dummy });
				Database.rollback(sp);
			}
		}
		return dummy;
	}

	private static Messaging.SingleEmailMessage createMessage(String[] toAddresses, String[] ccAddresses,
			String[] bccAddresses, Id fileVersionId, Messaging.SingleEmailMessage message, String orgWideAddress) {
		//create a new message
		Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
		//fill from address
		msg.setOrgWideEmailAddressId(orgWideAddress);
		//fill to addresses
		msg.setToAddresses(toAddresses);
		//fill bcc addresses if any
		if (bccAddresses != null && bccAddresses.size() > 0) {
			msg.setBccAddresses(bccAddresses);
		}
		//fill cc addresses if any
		if (ccAddresses != null && ccAddresses.size() > 0) {
			msg.setCcAddresses(ccAddresses);
		}
		// Set entity attachments
		msg.setEntityAttachments(new Id[] { fileVersionId });

		//set the body and Subject
		if (message != null) {
			msg.setSubject(message.getSubject());
			msg.setPlainTextBody(message.getPlainTextBody());
			msg.setHtmlBody(message.getHtmlBody());
		} else {
			msg.setSubject('Work Order Service Report');
			msg.setPlainTextBody('');
			msg.setHtmlBody('');
		}

		// This settings doesn't work.. need to create the Activity/Task ourselves
		// msg.setSaveAsActivity(true);

		//System.debug('Email Files handler: Message created : ' + msg);
		return msg;
	}

	@TestVisible private static Task createActivityForLogging(String fileOwnerId, String workOrderId, String[] toAddresses,
		String[] ccAddresses, String[] bccAdddresses, String fileName, String body, String subject)
	{
		String comments = 'To: ' + toAddresses + '\r\n\r\n';

		if (ccAddresses != null && ccAddresses.size() > 0) {
			comments += 'CC: ' + ccAddresses + '\r\n\r\n';
		} else {
			comments += 'CC: ' + '\r\n\r\n';
		}

		if (bccAdddresses != null && bccAdddresses.size() > 0) {
			comments += 'BCC: ' + bccAdddresses + '\r\n\r\n';
		} else {
			comments += 'BCC: ' + '\r\n\r\n';
		}

		comments += 'File attachment: ' + fileName + '\r\n\r\n';
		comments += 'Subject: ' + subject + '\r\n\r\n';
		comments += 'Body: ' + '\r\n\r\n';

		if (body != null) {
			comments += body;
		}

		Task emailTask = new Task();
		emailTask.Type = 'Email';
		emailTask.Status = 'Completed';
		emailTask.ActivityDate = Date.today();
		emailTask.Description = comments;
		emailTask.OwnerId = fileOwnerId;
		emailTask.WhatId = workOrderId;
		emailTask.Subject = 'Email: ' + subject;
		return emailTask;
	}
}