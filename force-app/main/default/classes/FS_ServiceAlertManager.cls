/**
 * Manager Class for Service Alert logic
 * 
 * History:
 * 01/23/2023   tony    ITSVMX-1123 Custom Metadata types - Service Alert CRC Email Address updates on new CRC email addresses
 */
public with sharing class FS_ServiceAlertManager {

  public static void updateServiceAlerts(List<FS_ServiceAlert__c> serviceAlertList, Map<Id, FS_ServiceAlert__c> oldMap) {

    // Get any Service Alert records
    Map<Id, FS_ServiceAlert__c> ownerIdToServiceAlertMap = new Map<Id, FS_ServiceAlert__c>();
    Map<Id, FS_ServiceAlert__c> techIdToServiceAlertMap = new Map<Id, FS_ServiceAlert__c>();

    for (FS_ServiceAlert__c serviceAlert :serviceAlertList) {
      Id oldTechId = (oldMap == null) ? null : oldMap.get(serviceAlert.Id).Technician__c;
      if ((serviceAlert.Technician__c != null && oldTechId == null) ||
          (serviceAlert.Technician__c != null && oldTechId != serviceAlert.Technician__c)) {
        techIdToServiceAlertMap.put(serviceAlert.Technician__c, serviceAlert);
      } else {
        ownerIdToServiceAlertMap.put(serviceAlert.OwnerId, serviceAlert);
      }
    }
    System.debug('ownerIdToServiceAlertMap: ' + ownerIdToServiceAlertMap);
    System.debug('techIdToServiceAlertMap: ' + techIdToServiceAlertMap);

    // Get list of Technician records that match the ownerIdServiceAlertMap Ids or the techIdToServiceAlertMap Ids
    List<ServiceResource> technicianList = new List<ServiceResource>([
        SELECT Id, RelatedRecordId
        FROM ServiceResource
        WHERE Id IN :techIdToServiceAlertMap.keySet() OR RelatedRecordId IN :ownerIdToServiceAlertMap.keySet()
    ]);
    System.debug('technicianList: ' + technicianList);

    Map<Id, Id> techIdToUserIdMap = new Map<Id, Id>();
    Map<Id, Id> userIdToTechIdMap = new Map<Id, Id>();
    for (ServiceResource tech :technicianList) {
      if (tech.RelatedRecordId != null) {
        userIdToTechIdMap.put(tech.RelatedRecordId, tech.Id);
      }
      techIdToUserIdMap.put(tech.Id, tech.RelatedRecordId);
    }
    System.debug('techIdToUserIdMap: ' + techIdToUserIdMap);
    System.debug('userIdToTechIdMap: ' + userIdToTechIdMap);

    // Update the OwnerId for records that had a Technician already set
    for (FS_ServiceAlert__c serviceAlert :techIdToServiceAlertMap.values()) {
      Id newOwnerId = techIdToUserIdMap.get(serviceAlert.Technician__c);
      if (newOwnerId != null) {
        serviceAlert.OwnerId = newOwnerId;
      }
    }
    System.debug('techIdToServiceAlertMap: ' + techIdToServiceAlertMap);

    // Update the SVMX_PS_Technician__c for records that had an OwnerId but no Technician
    for (FS_ServiceAlert__c serviceAlert :ownerIdToServiceAlertMap.values()) {

      Id newTechId = userIdToTechIdMap.get(serviceAlert.OwnerId);
      if (newTechId != null) {
        serviceAlert.Technician__c = newTechId;
      }
    }
    System.debug('ownerIdToServiceAlertMap: ' + ownerIdToServiceAlertMap);

    // Get the User Ids for the Service Alerts including the ones we just updated
    Set<Id> userIds = new Set<Id>();
    for (FS_ServiceAlert__c serviceAlert : serviceAlertList) {
      userIds.add(serviceAlert.OwnerId);
    }
    System.debug('userIds: ' + userIds);

    Map<Id, User> userMap = new Map<Id, User>([
        SELECT Id, Region__c, Sub_Region__c
        FROM User
        WHERE Id IN : userIds
    ]);
    System.debug('userMap :' + userMap);

    // The Region and Sub Region of the Service Alerts will be set to the Owner's Region and Sub Region
    for (FS_ServiceAlert__c serviceAlert : serviceAlertList) {

      User user = userMap.get(serviceAlert.OwnerId);
      if (user != null) {
        serviceAlert.Region__c = user.Region__c;
        serviceAlert.Sub_Region__c = user.Sub_Region__c;
        System.debug('Setting the Region and Sub Region: ' + serviceAlert.Region__c + ' / ' + serviceAlert.Sub_Region__c);
      }
    }
    System.debug('serviceAlertList to be updated:' + serviceAlertList);

    // ITSVMX-454 Sarala Lakkireddy - Ability to skip the managerial approval and go directly to BU approval
    // If condition executed when Approval Action taken by Manager directly but in coming status is set to BU approved/rejected
    for (FS_ServiceAlert__c serviceAlert :serviceAlertList) {
      FS_ServiceAlert__c old = (oldMap == null) ? null : oldMap.get(serviceAlert.Id);

      //If the current logged in user id is same as manager approval user id SVMX_PS_Manager_Approval_User__c and then if the incoming status is 
      // is showing as Quality Approved/Rejected then it needs to be Manager Approved/Rejected
      if(serviceAlert.Manager_Approval_User__c != null &&
          UserInfo.getUserId() != null &&
          serviceAlert.Manager_Approval_User__c == UserInfo.getUserId() &&
          serviceAlert.Record_Type__c == 'Replacement Alert'){
        // System.debug('Replacement approval after update is triggered, SVMX_PS_Stage__c:' + serviceAlert.SVMX_PS_Stage__c + ' SVMX_PS_Status__c:' + serviceAlert.SVMX_PS_Status__c
        //  + 'LastModifiedById' + serviceAlert.LastModifiedById);
        if(serviceAlert.Status__c != null && serviceAlert.Status__c == 'Quality Approved' &&
            old.Status__c != null && old.Status__c == 'Pending Manager Approval'){
          serviceAlert.Status__c =  'Manager Approved';
          // System.debug('Replacement manager approval condition reached:' + UserInfo.getUserId() );
        }
        if(serviceAlert.Status__c != null && serviceAlert.Status__c == 'Quality Rejected' &&
            old.Status__c != null && old.Status__c == 'Pending Manager Approval'){
          serviceAlert.Status__c =  'Manager Rejected';
          // System.debug('Replacement manager rejected condition reached:' + UserInfo.getUserId() );
        }
      }
    }
  }
  
  public static void updatePath(List<FS_ServiceAlert__c> serviceAlertList, Map<Id, FS_ServiceAlert__c> oldMap) {

        // Get the Custom Metadata Type settings
        List<C_META_FS_Service_Alert_Setting__mdt> serviceAlertSettings = [
                SELECT Alert_Status__c, Path_Stage__c
                FROM C_META_FS_Service_Alert_Setting__mdt
        ];

        if (serviceAlertSettings.size() < 1) {
            System.debug('Custom Metadata Type [Service Alert Setting] records need to be created.');
            return;
        }

        // Create Alert Status to Path Stage mapping
        Map<String, String> statusToStageMap = new Map<String, String>();
        for (C_META_FS_Service_Alert_Setting__mdt serviceAlertSetting : serviceAlertSettings) {

            statusToStageMap.put(serviceAlertSetting.Alert_Status__c, serviceAlertSetting.Path_Stage__c);
        }
        System.debug('statusToStageMap: '  + statusToStageMap);

        // Update the Path Stage if the Alert Status has changed
        for (FS_ServiceAlert__c serviceAlert :serviceAlertList) {
            String oldStatus = (oldMap == null) ? null : oldMap.get(serviceAlert.Id).Status__c;
            if (oldStatus == null || (serviceAlert.Status__c != null && serviceAlert.Status__c != oldStatus)) {

                String newStatus = statusToStageMap.get(serviceAlert.Status__c);
                if (newStatus != null) {
                    serviceAlert.Stage__c = newStatus;
                    System.debug('Setting Stage to: ' + newStatus);
                }
            }
        }
    }
    
    // Service Alert | SVMX_PS_Service_Alert__c
    // Parent(s): Installed Product [OR] Location [OR] Work Order [OR] Technician
   /* public static void updateServiceAlertObject(List<FS_ServiceAlert__c> newList, Map<Id, FS_ServiceAlert__c> oldMap){

        Map<Id, Asset> ipMap = new Map<Id, Asset>();
        Map<Id, Location> locMap = new Map<Id, Location>();
        Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>();
        Map<Id, ServiceResource> techMap = new Map<Id, ServiceResource>();
        Set<Id> ipIds = new Set<Id>();
        Set<Id> locIds = new Set<Id>(); 
        Set<Id> woIds = new Set<Id>();
        Set<Id> techIds = new Set<Id>();
        String decisionString = 'Not Found';
        String companyString = '';

        // Add valid Ids to Sets for Map population
        for(FS_ServiceAlert__c sa : newList){
            // add related Installed Product Ids if valid
            if(String.IsNotBlank(sa.Asset__c)){
                ipIds.add(sa.Asset__c);
            }
            // add related Location Ids if valid
            if(String.IsNotBlank(sa.Location__c)){
                locIds.add(sa.Location__c);
            }
            // add related Work Order Ids if valid
            if(String.IsNotBlank(sa.Work_Order__c)){
                woIds.add(sa.Work_Order__c);
            }
            // add related Technician Ids if valid
            if(String.IsNotBlank(sa.Technician__c)){
                techIds.add(sa.Technician__c);
            }
        }

        // validate and populate Installed Product Map
        if(ipIds.size() > 0){
            for(Asset__c ip : 
                [SELECT Id,
                        SMAX_PS_Owned_By_Company__c,
                        SMAX_PS_Owned_By_Company_Decided_By__c
                   FROM Asset__c
                  WHERE Id IN :ipIds AND
                        SMAX_PS_Owned_By_Company__c != '']){
                ipMap.put(ip.Id, ip);
            }
        }
        // validate and populate Location Map
        if(locIds.size() > 0){
            for(SVMXC__Site__c loc : 
                [SELECT Id,
                        SMAX_PS_Owned_By_Company__c,
                        SMAX_PS_Owned_By_Company_Decided_By__c
                   FROM SVMXC__Site__c
                  WHERE Id IN :locIds AND
                        SMAX_PS_Owned_By_Company__c != '']){
                locMap.put(loc.Id, loc);
            }
        }
        // validate and populate Work Order Map
        if(woIds.size() > 0){
            for(SVMXC__Service_Order__c wo : 
                [SELECT Id,
                        SMAX_PS_Owned_By_Company__c,
                        SMAX_PS_Owned_By_Company_Decided_By__c
                   FROM SVMXC__Service_Order__c
                  WHERE Id IN :woIds AND
                        SMAX_PS_Owned_By_Company__c != '']){
                woMap.put(wo.Id, wo);
            }
        }
        // validate and populate Technician Map
        if(techIds.size() > 0){
            for(SVMXC__Service_Group_Members__c tech : 
                [SELECT Id,
                        SVMXC__Service_Group__r.SMAX_PS_Owned_By_Company__c
                   FROM SVMXC__Service_Group_Members__c
                  WHERE Id IN :techIds]){
                techMap.put(tech.Id, tech);
            }
        }

        // update Service Alert records based on Parent records and mismatch Owned by Company values
        for(SVMX_PS_Service_Alert__c sa : newList){

            if(String.IsBlank(sa.SMAX_PS_Owned_By_Company__c)){

                // 01/10/2023 tony - Added clear of variables so we don't put the last values into the next service alert
                companyString = null;
                decisionString = null;

                // check to update by Installed Product
                if(String.IsNotBlank(sa.SVMX_PS_Installed_Product__c) && ipMap.keySet().contains(sa.SVMX_PS_Installed_Product__c) && (sa.SMAX_PS_Owned_By_Company__c != ipMap.get(sa.SVMX_PS_Installed_Product__c).SMAX_PS_Owned_By_Company__c || String.IsBlank(ipMap.get(sa.SVMX_PS_Installed_Product__c).SMAX_PS_Owned_By_Company__c))){
                    companyString = ipMap.get(sa.SVMX_PS_Installed_Product__c).SMAX_PS_Owned_By_Company__c;
                    decisionString = ipMap.get(sa.SVMX_PS_Installed_Product__c).SMAX_PS_Owned_By_Company_Decided_By__c;
                }
                // check to update by Location
                else if(String.IsNotBlank(sa.SVMX_PS_Location__c) && locMap.keySet().contains(sa.SVMX_PS_Location__c) && (sa.SMAX_PS_Owned_By_Company__c != locMap.get(sa.SVMX_PS_Location__c).SMAX_PS_Owned_By_Company__c || String.IsBlank(locMap.get(sa.SVMX_PS_Location__c).SMAX_PS_Owned_By_Company__c))){
                    companyString = locMap.get(sa.SVMX_PS_Location__c).SMAX_PS_Owned_By_Company__c;
                    decisionString = locMap.get(sa.SVMX_PS_Location__c).SMAX_PS_Owned_By_Company_Decided_By__c;
                }
                // check to update by Work Order
                else if(String.IsNotBlank(sa.SVMX_PS_Work_Order__c) && woMap.keySet().contains(sa.SVMX_PS_Work_Order__c) && (sa.SMAX_PS_Owned_By_Company__c != woMap.get(sa.SVMX_PS_Work_Order__c).SMAX_PS_Owned_By_Company__c || String.IsBlank(woMap.get(sa.SVMX_PS_Work_Order__c).SMAX_PS_Owned_By_Company__c))){
                    companyString = woMap.get(sa.SVMX_PS_Work_Order__c).SMAX_PS_Owned_By_Company__c;
                    decisionString = woMap.get(sa.SVMX_PS_Work_Order__c).SMAX_PS_Owned_By_Company_Decided_By__c;
                }
                // check to update by Technician
                else if(String.IsNotBlank(sa.SVMX_PS_Technician__c) && techMap.keySet().contains(sa.SVMX_PS_Technician__c) && (sa.SMAX_PS_Owned_By_Company__c != techMap.get(sa.SVMX_PS_Technician__c).SVMXC__Service_Group__r.SMAX_PS_Owned_By_Company__c || String.IsBlank(techMap.get(sa.SVMX_PS_Technician__c).SVMXC__Service_Group__r.SMAX_PS_Owned_By_Company__c))){
                    companyString = techMap.get(sa.SVMX_PS_Technician__c).SVMXC__Service_Group__r.SMAX_PS_Owned_By_Company__c;
                    decisionString = 'By Service Team Record';
                }

                sa.SMAX_PS_Owned_By_Company__c = companyString;
                sa.SMAX_PS_Owned_By_Company_Decided_By__c = decisionString;
            }
        }
    }*/
    
    
     // ITSVMX-242 tony - Service Alert Notification Setup
    // Should be called from AfterInsert event trigger
    public static void sendServiceAlertCreationNotifications(List<FS_ServiceAlert__c> serviceAlertList){
        System.debug('Entering SMAX_PS_ServiceAlertManager.sendServiceAlertCreationNotifications()');
        System.debug('About to process Service Alerts: ' + serviceAlertList);

        // You have to have at least 1 contact record or the merge fields will not work properly
        List<Contact> mergeContacts = [
                SELECT Id, FirstName, LastName, Email
                FROM Contact
                WHERE LastName = 'Service Alert Email Notification'
                LIMIT 1
        ];
        if (mergeContacts.size() <> 1) {
            System.debug('ERROR: No Service Alert Email Notification contact has been created. '
                    + 'Please create a new contact with a LastName = "Service Alert Email Notification"');
            return;
        }

        // Get the Distribution Lists
        List<C_META_FS_Service_Alert_PL_Email__mdt> distributionList = [
                SELECT  Id, Email_Addresses__c, Ignore_Product_Line__c, Product_Line__c
                FROM C_META_FS_Service_Alert_PL_Email__mdt
        ];
        System.debug('distributionList: ' + distributionList);

        if (distributionList.size() == 0) {
            System.debug('ERROR: No Service Alert PL Email Address custom metadata has been setup');
            return;
        }

        // Create Product Line Lookup Map and Ignore Product Line distribution list
        List<C_META_FS_Service_Alert_PL_Email__mdt> ignorePLDistributionList = new List<C_META_FS_Service_Alert_PL_Email__mdt>();
        Map<String, C_META_FS_Service_Alert_PL_Email__mdt> productLineToDistributionListMap = new Map<String, C_META_FS_Service_Alert_PL_Email__mdt>();
        for (C_META_FS_Service_Alert_PL_Email__mdt dl :distributionList) {

            if (dl.Ignore_Product_Line__c == true) {
                ignorePLDistributionList.add(dl);
            } else {
                productLineToDistributionListMap.put(dl.Product_Line__c, dl);
            }
        }

        // Get Email Templates
        String generalServiceAlertTemplate = 'FS_General_Service_Alert_Created';
        String replacementServiceAlertTemplate = 'FS_Replacement_Service_Alert_Created';
        List<EmailTemplate> emailTemplates = [
                SELECT Id,Subject,Description,HtmlValue,DeveloperName,Body
                FROM EmailTemplate
                WHERE DeveloperName = :generalServiceAlertTemplate
                OR DeveloperName = :replacementServiceAlertTemplate
        ];
        System.debug('emailTemplates: ' + emailTemplates);

        Map<String, EmailTemplate> typeToEmailTemplate = new Map<String, EmailTemplate>();
        for (EmailTemplate emailTemplate :emailTemplates) {
            typeToEmailTemplate.put(emailTemplate.DeveloperName, emailTemplate);
        }

        if (typeToEmailTemplate.get(generalServiceAlertTemplate) == null) {
            System.debug('ERROR: Classic Email Template named [' + generalServiceAlertTemplate + '] does not exist.');
            return;
        }

        if (typeToEmailTemplate.get(replacementServiceAlertTemplate) == null) {
            System.debug('ERROR: Classic Email Template named [' + replacementServiceAlertTemplate + '] does not exist.');
            return;
        }

        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();

        // Loop over Service Alerts
        for (FS_ServiceAlert__c serviceAlert :serviceAlertList) {

            System.debug('Inside Loop processing Service Alert: ' + serviceAlert);

            // Send Notification to Product Line distribution list using the email template for General Alerts or Replacement Alerts
            EmailTemplate emlTemplate = null;
            if (serviceAlert.Record_Type__c == 'General Alert') {
                System.debug('General Service Alert: ' + serviceAlert);
                //message.setTemplateId(typeToEmailTemplate.get(generalServiceAlertTemplate).Id);
                emlTemplate = typeToEmailTemplate.get(generalServiceAlertTemplate);
            } else if (serviceAlert.Record_Type__c == 'Replacement Alert') {
                System.debug('Replacement Service Alert: ' + serviceAlert);
                //message.setTemplateId(typeToEmailTemplate.get(replacementServiceAlertTemplate).Id);
                emlTemplate = typeToEmailTemplate.get(replacementServiceAlertTemplate);
            }

            Messaging.SingleEmailMessage dummy = createDummyMessage(emlTemplate,
                mergeContacts[0].Id, null, serviceAlert.Id);

            // Get the Distribution List for this Service Alert
            String emailAddresses = '';
            C_META_FS_Service_Alert_PL_Email__mdt distList = productLineToDistributionListMap.get(serviceAlert.fxProduct_Line__c);

            if (distList != null) {
                emailAddresses = distList.Email_Addresses__c;
                System.debug('Product Line Match Found - emailAddresses: ' + emailAddresses);
            }

            // Add the Ignore Product Line email addresses
            if (ignorePLDistributionList.size() > 0) {
                for (C_META_FS_Service_Alert_PL_Email__mdt dl :ignorePLDistributionList) {
                    emailAddresses = emailAddresses + ',' + dl.Email_Addresses__c;
                }
                emailAddresses = emailAddresses.removeStart(',');
            }
            System.debug('emailAddresses: ' + emailAddresses);

            if (String.isBlank(emailAddresses) && Test.isRunningTest()) {
                emailAddresses = 'test@revvity.com';
            }

            if (emailAddresses != null && emailAddresses != '') {
                List<String> toAddresses = new List<String>(emailAddresses.split(','));
                Messaging.SingleEmailMessage message = createMessage(toAddresses, null, null,
                    null, dummy);

                // 3/11/21 Tony - added as Unit Test will fail if there is not a Email body value found
                if(Test.isRunningTest()){
                    message.plainTextBody = 'Test';
                }

                messages.add(message);
                System.debug('Adding message to list: ' + message);
            } else {
                System.debug('No Match found for Product Line in Service Alert PL Email Address custom metadata');
            }
        }

        if (messages.size() > 0) {
            System.debug('About to sendEmail: ' + messages);
            Messaging.SendEmailResult[] results = (Test.isRunningTest()) ?
                new List<Messaging.SendEmailResult>() : Messaging.sendEmail(messages);

            for (Messaging.SendEmailResult result :results) {
                if (result.success) {
                    System.debug('The email was sent successfully.');
                } else {
                    System.debug('The email failed to send: ' +  result.errors[0].message);
                }
            }
        } else {
            System.debug('No messages to email: ' + messages);
        }
    }


     // ITSVMX-209 tony - Service Alerts Customer Care Email Notification
    // Should be called from AfterUpdate event trigger
    public static void sendServiceAlertNotifications(List<FS_ServiceAlert__c> serviceAlertList, Map<Id, FS_ServiceAlert__c> oldMap){
        System.debug('Entering SMAX_PS_ServiceAlertManager.sendServiceAlertNotifications()');
        System.debug('About to process Service Alerts: ' + serviceAlertList.size() + serviceAlertList);

        // You have to have at least 1 contact record or the merge fields will not work properly
        List<Contact> mergeContacts = [
                SELECT Id, FirstName, LastName, Email
                FROM Contact
                WHERE LastName = 'Service Alert Email Notification'
                LIMIT 1
        ];
        if (mergeContacts.size() <> 1) {
            System.debug('ERROR: No Service Alert Email Notification contact has been created. '
                    + 'Please create a new contact with a LastName = "Service Alert Email Notification"');
            return;
        }

        // Get the Distribution Lists
        List<C_META_FS_Service_Alert_CRC_Email__mdt> distributionList = [
                SELECT  Id, DeveloperName, Email_Addresses__c, Service_Alert_Country__c,
                        Service_Alert_Region__c, Service_Alert_Sub_Region__c, Indirect_CRC__c
                FROM C_META_FS_Service_Alert_CRC_Email__mdt
        ];
        System.debug('distributionList: ' + distributionList);

        if (distributionList.size() == 0) {
            System.debug('ERROR: No Service Alert CRC Email Address custom metadata has been setup');
            return;
        }

        // Create Lookup Maps
        Map<String, C_META_FS_Service_Alert_CRC_Email__mdt> countryToDistributionListMap = new Map<String, C_META_FS_Service_Alert_CRC_Email__mdt>();
        Map<String, C_META_FS_Service_Alert_CRC_Email__mdt> subRegionToDistributionListMap = new Map<String, C_META_FS_Service_Alert_CRC_Email__mdt>();
        for (C_META_FS_Service_Alert_CRC_Email__mdt dl :distributionList) {
            // 01/23/2023 ITSVMX-1123 Include the Owned By Company in the mappings
//            countryToDistributionListMap.put(dl.SMAX_PS_Service_Alert_Country__c, dl);
            countryToDistributionListMap.put(dl.Service_Alert_Country__c, dl);
            if (dl.Indirect_CRC__c == true) {
//                subRegionToDistributionListMap.put(dl.SMAX_PS_Service_Alert_Sub_Region__c, dl);
                subRegionToDistributionListMap.put(dl.Service_Alert_Sub_Region__c, dl);
            }
        }
        System.debug('countryToDistributionListMap: ' + countryToDistributionListMap.size() + ' ' + countryToDistributionListMap);
        System.debug('subRegionToDistributionListMap: ' + subRegionToDistributionListMap.size() + ' ' + subRegionToDistributionListMap);

        // Get Email Template
        List<EmailTemplate> emailTemplate = [
                SELECT Id,Subject,Description,HtmlValue,DeveloperName,Body
                FROM EmailTemplate
                WHERE DeveloperName = 'FS_Service_Alert_Approved'
                LIMIT 1
        ];
        System.debug('emailTemplate: ' + emailTemplate);

        if (emailTemplate.size() == 0) {
            System.debug('ERROR: Classic Email Template named "FS_Service_Alert_Approved" does not exist.');
            return;
        }

        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();

        // Loop over Service Alerts
        for (FS_ServiceAlert__c serviceAlert :serviceAlertList) {
            FS_ServiceAlert__c old = (oldMap == null) ? null : oldMap.get(serviceAlert.Id);

            // If the Service Alert status has changed and been set to approved,
            // send Notification to Customer Care distribution list.
            System.debug('Inside Loop processing Service Alert: ' + serviceAlert);
            // Changed during SFS UAT because this status is being "skipped"
            if (serviceAlert.Status__c == 'Sent to CRC'
                    && (old.Status__c != serviceAlert.Status__c)) {

                System.debug('Quality Approved Service Alert: ' + serviceAlert);

                Messaging.SingleEmailMessage dummy = createDummyMessage(emailTemplate[0],
                        mergeContacts[0].Id, null, serviceAlert.Id);

                // Get the Customer Care Distribution List for this Service Alert
                String emailAddresses;
                C_META_FS_Service_Alert_CRC_Email__mdt distList = countryToDistributionListMap.get(serviceAlert.Country__c);
                C_META_FS_Service_Alert_CRC_Email__mdt distList2 = subRegionToDistributionListMap.get(serviceAlert.Sub_Region__c);
                if (distList != null) {
                    emailAddresses = distList.Email_Addresses__c;
                    System.debug('Country-Owned By Company Match Found - emailAddresses: ' + emailAddresses);
                } else if (distList2 != null) {
                    emailAddresses = distList2.Email_Addresses__c;
                    System.debug('Sub Region-Owned By Company Match Found - emailAddresses: ' + emailAddresses);
                }

                if (String.isBlank(emailAddresses) && Test.isRunningTest()) {
                    emailAddresses = 'test@revvity.com';
                }

                if (emailAddresses != null && emailAddresses != '') {
                    List<String> toAddresses = new List<String>(emailAddresses.split(','));
                    Messaging.SingleEmailMessage message = createMessage(toAddresses, null, null,
                            null, dummy);

                    messages.add(message);
                    System.debug('Adding message to list: ' + message);
                } else {
                    System.debug('No Match found for Country-Owned By Company or Sub Region-Owned By Company in Service Alert CRC Email Address custom metadata');
                }
            }
        }

        if (messages.size() > 0) {
            System.debug('About to sendEmail: ' + messages);
            try{
                Messaging.SendEmailResult[] results = (Test.isRunningTest()) ?
                    new List<Messaging.SendEmailResult>() : Messaging.sendEmail(messages);

                for (Messaging.SendEmailResult result :results) {
                    if (result.success) {
                        System.debug('The email was sent successfully.');
                    } else {
                        System.debug('The email failed to send: ' +  result.errors[0].message);
                    }
                }
            }catch(Exception e){
                System.debug('ERROR trying to send Service Alert Notification: ' + e);
            }
        } else {
            System.debug('No messages to email: ' + messages);
        }
    }
    
    
     // ITSVMX-242 tony - Service Alert Notification Setup
    // Called when Custom Action SFM updates the SVMX_PS_Manager_Approval_User__c field
    public static void submitServiceAlertForApproval(List<FS_ServiceAlert__c> serviceAlerts, Map<Id, FS_ServiceAlert__c> oldMap){

        for (FS_ServiceAlert__c serviceAlert :serviceAlerts) {
            FS_ServiceAlert__c old = (oldMap == null) ? null : oldMap.get(serviceAlert.Id);

            // ITSVMX-409 5/4/21 tony - Approve/Reject/Recall tab of replacement alert are missing when re-submit to approval
//            if (serviceAlert.SVMX_PS_Manager_Approval_User__c != null && old.SVMX_PS_Manager_Approval_User__c == null) {
            if (serviceAlert.Manager_Approval_User__c != null
                    && serviceAlert.Manager_Approval_User__c != old.Manager_Approval_User__c) {

                // Create an approval request for Service Alert
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setComments(serviceAlert.Submitter_Comments__c);
                req.setObjectId(serviceAlert.Id);
                req.setNextApproverIds(new Id[] {serviceAlert.Manager_Approval_User__c});
                //req.setSubmitterId();

                // Submit the approval request for the Service Alert
                Approval.ProcessResult result = Approval.process(req);
                System.debug('submitServiceAlertForApproval result: ' + result);
            }
        }
    }

    @TestVisible public static Messaging.SingleEmailMessage createDummyMessage(EmailTemplate emailTemplate, Id contactId, Id fileVersionId, Id whatId) {
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

    @TestVisible public static Messaging.SingleEmailMessage createMessage(String[] toAddresses, String[] ccAddresses,
            String[] bccAddresses, Id fileVersionId, Messaging.SingleEmailMessage message) {
        //create a new message
        Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
        //fill from address
        //msg.setOrgWideEmailAddressId(orgWideAddress);
        msg.setSenderDisplayName('Service Alert Notification');
        msg.setReplyTo('no-reply@perkinelmer.com');
        msg.setUseSignature(false);
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
        if (fileVersionId != null) {
            msg.setEntityAttachments(new Id[] { fileVersionId });
        }

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
}