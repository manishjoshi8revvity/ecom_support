/**
 * Represents a Service Report to email
 * Created by frankvanloon on 7/2/24.
 */
public with sharing class FS_WorkOrderEmails_ServiceReport {

	@AuraEnabled
	public ServiceReport svcReport;
	@AuraEnabled
	public Id contactId;
	@AuraEnabled
	public Id workOrderId;
	@AuraEnabled
	public String emailTemplateName;
	@AuraEnabled
	public EmailTemplate emailTemplate;
	@AuraEnabled
	public String orgWideAddress;
	@AuraEnabled
	public List<String> toAddresses;
	@AuraEnabled
	public List<String> ccAddresses;
	@AuraEnabled
	public List<String> bccAddresses;
}