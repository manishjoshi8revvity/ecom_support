/*************************************************
* https://github.com/financialforcedev/apex-mdapi
* added wrapper class for Listview TICKET (OM-146)
//  Updated on 03/10/2023 (Vishwas Kumar Gupta)
//  * added wrapper class for AddressSettings TICKET (OM-164)
//  Updated on 17/10/2023 (Vishwas Kumar Gupta)
*/
public class MetaDataService1 {
    
    public static String SOAP_M_URI = 'http://soap.sforce.com/2006/04/metadata';   
    
      public class AssignmentRule extends Metadata {
        public String type = 'AssignmentRule';
        public String fullName;
        private String[] fullName_type_info = new String[]{'fullName',SOAP_M_URI,null,'0','1','false'};
        public Boolean active;
        public MetadataService1.RuleEntry[] ruleEntry;
        private String[] active_type_info = new String[]{'active',SOAP_M_URI,null,'0','1','false'};
        private String[] ruleEntry_type_info = new String[]{'ruleEntry',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] type_att_info = new String[]{'xsi:type'};
        private String[] field_order_type_info = new String[]{'fullName', 'active','ruleEntry'};
    }
    
      public class AssignmentRules extends Metadata {
        public String type = 'AssignmentRules';
        public String fullName;
        private String[] fullName_type_info = new String[]{'fullName',SOAP_M_URI,null,'0','1','false'};
        public MetadataService1.AssignmentRule[] assignmentRule;
        private String[] assignmentRule_type_info = new String[]{'assignmentRule',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] type_att_info = new String[]{'xsi:type'};
        private String[] field_order_type_info = new String[]{'fullName', 'assignmentRule'};
    }
       public class SessionHeader_element {
        public String sessionId;
        private String[] sessionId_type_info = new String[]{'sessionId',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'sessionId'};
    }
     public class DebuggingInfo_element {
        public String debugLog;
        private String[] debugLog_type_info = new String[]{'debugLog',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'debugLog'};
    }
    public class LogInfo {
        public String category;
        public String level;
        private String[] category_type_info = new String[]{'category',SOAP_M_URI,null,'1','1','false'};
        private String[] level_type_info = new String[]{'level',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'category','level'};
    }
    
     public class DebuggingHeader_element {
        public MetadataService1.LogInfo[] categories;
        public String debugLevel;
        private String[] categories_type_info = new String[]{'categories',SOAP_M_URI,null,'0','-1','false'};
        private String[] debugLevel_type_info = new String[]{'debugLevel',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'categories','debugLevel'};
    }
    
     public class CallOptions_element {
        public String client;
        private String[] client_type_info = new String[]{'client',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'client'};
    }
    
     public class AllOrNoneHeader_element {
        public Boolean allOrNone;
        private String[] allOrNone_type_info = new String[]{'allOrNone',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'allOrNone'};
    }
    
     public class Error {
        public MetadataService1.ExtendedErrorDetails[] extendedErrorDetails;
        public String[] fields;
        public String message;
        public String statusCode;
        private String[] extendedErrorDetails_type_info = new String[]{'extendedErrorDetails',SOAP_M_URI,null,'0','-1','false'};
        private String[] fields_type_info = new String[]{'fields',SOAP_M_URI,null,'0','-1','false'};
        private String[] message_type_info = new String[]{'message',SOAP_M_URI,null,'1','1','false'};
        private String[] statusCode_type_info = new String[]{'statusCode',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'extendedErrorDetails','fields','message','statusCode'};
    }
    
    public class ExtendedErrorDetails {
        public String extendedErrorCode;
        private String[] extendedErrorCode_type_info = new String[]{'extendedErrorCode',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'extendedErrorCode'};
    }
    
      public class DeleteResult {
        public MetadataService1.Error[] errors;
        public String fullName;
        public Boolean success;
        private String[] errors_type_info = new String[]{'errors',SOAP_M_URI,null,'0','-1','false'};
        private String[] fullName_type_info = new String[]{'fullName',SOAP_M_URI,null,'1','1','false'};
        private String[] success_type_info = new String[]{'success',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'errors','fullName','success'};
    }
    
    public class deleteMetadata_element {
        public String type_x;
        public String[] fullNames;
        private String[] type_x_type_info = new String[]{'type',SOAP_M_URI,null,'1','1','false'};
        private String[] fullNames_type_info = new String[]{'fullNames',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'type_x','fullNames'};
    }
    
     public class deleteMetadataResponse_element {
        public MetadataService1.DeleteResult[] result;
        private String[] result_type_info = new String[]{'result',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'result'};
    }   
     public class createMetadata_element {
        public MetadataService1.Metadata[] metadata;
        private String[] metadata_type_info = new String[]{'metadata',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'metadata'};
    }
        public class createMetadataResponse_element {
        public MetadataService1.SaveResult[] result;
        private String[] result_type_info = new String[]{'result',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'result'};
    }
     public class updateMetadata_element {
        public MetadataService1.Metadata[] metadata;
        private String[] metadata_type_info = new String[]{'metadata',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'metadata'};
    }
     public class updateMetadataResponse_element {
        public MetadataService1.SaveResult[] result;
        private String[] result_type_info = new String[]{'result',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'result'};
    }
    public class MetadataPort {
        public String endpoint_x = URL.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/m/42.0';
        public Map<String,String> inputHttpHeaders_x;
        public Map<String,String> outputHttpHeaders_x;
        public String clientCertName_x;
        public String clientCert_x;
        public String clientCertPasswd_x;
        public Integer timeout_x;
        public MetadataService1.SessionHeader_element SessionHeader;
        public MetadataService1.DebuggingInfo_element DebuggingInfo;
        public MetadataService1.DebuggingHeader_element DebuggingHeader;
        public MetadataService1.CallOptions_element CallOptions;
        public MetadataService1.AllOrNoneHeader_element AllOrNoneHeader;
        private String SessionHeader_hns = 'SessionHeader=http://soap.sforce.com/2006/04/metadata';
        private String DebuggingInfo_hns = 'DebuggingInfo=http://soap.sforce.com/2006/04/metadata';
        private String DebuggingHeader_hns = 'DebuggingHeader=http://soap.sforce.com/2006/04/metadata';
        private String CallOptions_hns = 'CallOptions=http://soap.sforce.com/2006/04/metadata';
        private String AllOrNoneHeader_hns = 'AllOrNoneHeader=http://soap.sforce.com/2006/04/metadata';
        private String[] ns_map_type_info = new String[]{SOAP_M_URI, 'MetadataService1'};
        public MetadataService1.DeleteResult[] deleteMetadata(String type_x,String[] fullNames) {
            MetadataService1.deleteMetadata_element request_x = new MetadataService1.deleteMetadata_element();
            request_x.type_x = type_x;
            request_x.fullNames = fullNames;
            MetadataService1.deleteMetadataResponse_element response_x;
            Map<String, MetadataService1.deleteMetadataResponse_element> response_map_x = new Map<String, MetadataService1.deleteMetadataResponse_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              '',
              SOAP_M_URI,
              'deleteMetadata',
              SOAP_M_URI,
              'deleteMetadataResponse',
              'MetadataService1.deleteMetadataResponse_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.result;
        }
        public MetadataService1.IReadResult readMetadata(String type_x,String[] fullNames) {
            MetadataService1.readMetadata_element request_x = new MetadataService1.readMetadata_element();
            request_x.type_x = type_x;
            request_x.fullNames = fullNames;
            MetadataService1.IReadResponseElement response_x;
            Map<String, MetadataService1.IReadResponseElement> response_map_x = new Map<String, MetadataService1.IReadResponseElement>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              '',
              SOAP_M_URI,
              'readMetadata',
              SOAP_M_URI,
              'readMetadataResponse',
              'MetadataService1.read' + type_x + 'Response_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.getResult();
        }
         public MetadataService1.SaveResult[] createMetadata(MetadataService1.Metadata[] metadata) {
            MetadataService1.createMetadata_element request_x = new MetadataService1.createMetadata_element();
            request_x.metadata=metadata;
            MetadataService1.createMetadataResponse_element response_x;
            Map<String, MetadataService1.createMetadataResponse_element> response_map_x = new Map<String, MetadataService1.createMetadataResponse_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              '',
              SOAP_M_URI,
              'createMetadata',
              SOAP_M_URI,
              'createMetadataResponse',
              'MetadataService1.createMetadataResponse_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.result;
        }
         public MetadataService1.SaveResult[] updateMetadata(MetadataService1.Metadata[] metadata) {
            MetadataService1.updateMetadata_element request_x = new MetadataService1.updateMetadata_element();
            request_x.metadata=metadata;
            MetadataService1.updateMetadataResponse_element response_x;
            Map<String, MetadataService1.updateMetadataResponse_element> response_map_x = new Map<String, MetadataService1.updateMetadataResponse_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              '',
              SOAP_M_URI,
              'updateMetadata',
              SOAP_M_URI,
              'updateMetadataResponse',
              'MetadataService1.updateMetadataResponse_element'}
            );
            response_x = response_map_x.get('response_x');
             system.debug('response_x.result=='+response_x);
            // system.debug('response_x.result=='+response_x.result[0].errors[0].message);
            return response_x.result;
        }
    }
public class SaveResult {
        public MetadataService1.Error[] errors;
        public String fullName;
        public Boolean success;
        private String[] errors_type_info = new String[]{'errors',SOAP_M_URI,null,'0','-1','false'};
        private String[] fullName_type_info = new String[]{'fullName',SOAP_M_URI,null,'1','1','false'};
        private String[] success_type_info = new String[]{'success',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'errors','fullName','success'};
    }
    public class readMetadata_element {
        public String type_x;
        public String[] fullNames;
        private String[] type_x_type_info = new String[]{'type',SOAP_M_URI,null,'1','1','false'};
        private String[] fullNames_type_info = new String[]{'fullNames',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'type_x','fullNames'};
    }
        public class SharedTo {
        public String allCustomerPortalUsers;
        public String allInternalUsers;
        public String allPartnerUsers;
        public String[] channelProgramGroup;
        public String[] channelProgramGroups;
        public String[] group_x;
        public String[] groups;
        public String[] managerSubordinates;
        public String[] managers;
        public String[] portalRole;
        public String[] portalRoleAndSubordinates;
        public String[] queue;
        public String[] role;
        public String[] roleAndSubordinates;
        public String[] roleAndSubordinatesInternal;
        public String[] roles;
        public String[] rolesAndSubordinates;
        public String[] territories;
        public String[] territoriesAndSubordinates;
        public String[] territory;
        public String[] territoryAndSubordinates;
        private String[] allCustomerPortalUsers_type_info = new String[]{'allCustomerPortalUsers',SOAP_M_URI,null,'0','1','false'};
        private String[] allInternalUsers_type_info = new String[]{'allInternalUsers',SOAP_M_URI,null,'0','1','false'};
        private String[] allPartnerUsers_type_info = new String[]{'allPartnerUsers',SOAP_M_URI,null,'0','1','false'};
        private String[] channelProgramGroup_type_info = new String[]{'channelProgramGroup',SOAP_M_URI,null,'0','-1','false'};
        private String[] channelProgramGroups_type_info = new String[]{'channelProgramGroups',SOAP_M_URI,null,'0','-1','false'};
        private String[] group_x_type_info = new String[]{'group',SOAP_M_URI,null,'0','-1','false'};
        private String[] groups_type_info = new String[]{'groups',SOAP_M_URI,null,'0','-1','false'};
        private String[] managerSubordinates_type_info = new String[]{'managerSubordinates',SOAP_M_URI,null,'0','-1','false'};
        private String[] managers_type_info = new String[]{'managers',SOAP_M_URI,null,'0','-1','false'};
        private String[] portalRole_type_info = new String[]{'portalRole',SOAP_M_URI,null,'0','-1','false'};
        private String[] portalRoleAndSubordinates_type_info = new String[]{'portalRoleAndSubordinates',SOAP_M_URI,null,'0','-1','false'};
        private String[] queue_type_info = new String[]{'queue',SOAP_M_URI,null,'0','-1','false'};
        private String[] role_type_info = new String[]{'role',SOAP_M_URI,null,'0','-1','false'};
        private String[] roleAndSubordinates_type_info = new String[]{'roleAndSubordinates',SOAP_M_URI,null,'0','-1','false'};
        private String[] roleAndSubordinatesInternal_type_info = new String[]{'roleAndSubordinatesInternal',SOAP_M_URI,null,'0','-1','false'};
        private String[] roles_type_info = new String[]{'roles',SOAP_M_URI,null,'0','-1','false'};
        private String[] rolesAndSubordinates_type_info = new String[]{'rolesAndSubordinates',SOAP_M_URI,null,'0','-1','false'};
        private String[] territories_type_info = new String[]{'territories',SOAP_M_URI,null,'0','-1','false'};
        private String[] territoriesAndSubordinates_type_info = new String[]{'territoriesAndSubordinates',SOAP_M_URI,null,'0','-1','false'};
        private String[] territory_type_info = new String[]{'territory',SOAP_M_URI,null,'0','-1','false'};
        private String[] territoryAndSubordinates_type_info = new String[]{'territoryAndSubordinates',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'allCustomerPortalUsers','allInternalUsers','allPartnerUsers','channelProgramGroup','channelProgramGroups','group_x','groups','managerSubordinates','managers','portalRole','portalRoleAndSubordinates','queue','role','roleAndSubordinates','roleAndSubordinatesInternal','roles','rolesAndSubordinates','territories','territoriesAndSubordinates','territory','territoryAndSubordinates'};
    }
    public class ListViewFilter {
        public String field;
        public String operation;
        public String value;
        private String[] field_type_info = new String[]{'field',SOAP_M_URI,null,'1','1','false'};
        private String[] operation_type_info = new String[]{'operation',SOAP_M_URI,null,'1','1','false'};
        private String[] value_type_info = new String[]{'value',SOAP_M_URI,null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'field','operation','value'};
    }
        public class ListView extends Metadata {
        public String type = 'ListView';
        public String fullName;
        private String[] fullName_type_info = new String[]{'fullName',SOAP_M_URI,null,'0','1','false'};
        public String booleanFilter;
        public String[] columns;
        public String division;
        public String filterScope;
        public MetadataService1.ListViewFilter[] filters;
        public String label;
        public String language;
        public String queue;
        public MetadataService1.SharedTo sharedTo;
        private String[] booleanFilter_type_info = new String[]{'booleanFilter',SOAP_M_URI,null,'0','1','false'};
        private String[] columns_type_info = new String[]{'columns',SOAP_M_URI,null,'0','-1','false'};
        private String[] division_type_info = new String[]{'division',SOAP_M_URI,null,'0','1','false'};
        private String[] filterScope_type_info = new String[]{'filterScope',SOAP_M_URI,null,'1','1','false'};
        private String[] filters_type_info = new String[]{'filters',SOAP_M_URI,null,'0','-1','false'};
        private String[] label_type_info = new String[]{'label',SOAP_M_URI,null,'1','1','false'};
        private String[] language_type_info = new String[]{'language',SOAP_M_URI,null,'0','1','false'};
        private String[] queue_type_info = new String[]{'queue',SOAP_M_URI,null,'0','1','false'};
        private String[] sharedTo_type_info = new String[]{'sharedTo',SOAP_M_URI,null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] type_att_info = new String[]{'xsi:type'};
        private String[] field_order_type_info = new String[]{'fullName', 'booleanFilter','columns','division','filterScope','filters','label','language','queue','sharedTo'};
    }
    public class ReadListViewResult implements IReadResult {
        public MetadataService1.ListView[] records;
        public MetadataService1.Metadata[] getRecords() { return records; }
        private String[] records_type_info = new String[]{'records',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'records'};
    }
    public class readListViewResponse_element implements IReadResponseElement {
        public MetadataService1.ReadListViewResult result;
        public IReadResult getResult() { return result; }
        private String[] result_type_info = new String[]{'result',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'result'};
    }
    public interface IReadResult {
        MetadataService1.Metadata[] getRecords();
    }
    public interface IReadResponseElement {
        IReadResult getResult();
    }
    
    public virtual class Metadata {
        public String fullName;
    }

      public class ReadAssignmentRulesResult implements IReadResult {
        public MetadataService1.AssignmentRules[] records;
        public MetadataService1.Metadata[] getRecords() { return records; }
        private String[] records_type_info = new String[]{'records',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'records'};
    }

    

    public class RuleEntry {
        public String assignedTo;
        public String assignedToType;
        public String booleanFilter;
        public String businessHours;
        public String businessHoursSource;
        public MetadataService1.FilterItem[] criteriaItems;
        public Boolean disableEscalationWhenModified;
        public MetadataService1.EscalationAction[] escalationAction;
        public String escalationStartTime;
        public String formula;
        public Boolean notifyCcRecipients;
        public Boolean overrideExistingTeams;
        public String replyToEmail;
        public String senderEmail;
        public String senderName;
        public String[] team;
        public String template;
        private String[] assignedTo_type_info = new String[]{'assignedTo',SOAP_M_URI,null,'0','1','false'};
        private String[] assignedToType_type_info = new String[]{'assignedToType',SOAP_M_URI,null,'0','1','false'};
        private String[] booleanFilter_type_info = new String[]{'booleanFilter',SOAP_M_URI,null,'0','1','false'};
        private String[] businessHours_type_info = new String[]{'businessHours',SOAP_M_URI,null,'0','1','false'};
        private String[] businessHoursSource_type_info = new String[]{'businessHoursSource',SOAP_M_URI,null,'0','1','false'};
        private String[] criteriaItems_type_info = new String[]{'criteriaItems',SOAP_M_URI,null,'0','-1','false'};
        private String[] disableEscalationWhenModified_type_info = new String[]{'disableEscalationWhenModified',SOAP_M_URI,null,'0','1','false'};
        private String[] escalationAction_type_info = new String[]{'escalationAction',SOAP_M_URI,null,'0','-1','false'};
        private String[] escalationStartTime_type_info = new String[]{'escalationStartTime',SOAP_M_URI,null,'0','1','false'};
        private String[] formula_type_info = new String[]{'formula',SOAP_M_URI,null,'0','1','false'};
        private String[] notifyCcRecipients_type_info = new String[]{'notifyCcRecipients',SOAP_M_URI,null,'0','1','false'};
        private String[] overrideExistingTeams_type_info = new String[]{'overrideExistingTeams',SOAP_M_URI,null,'0','1','false'};
        private String[] replyToEmail_type_info = new String[]{'replyToEmail',SOAP_M_URI,null,'0','1','false'};
        private String[] senderEmail_type_info = new String[]{'senderEmail',SOAP_M_URI,null,'0','1','false'};
        private String[] senderName_type_info = new String[]{'senderName',SOAP_M_URI,null,'0','1','false'};
        private String[] team_type_info = new String[]{'team',SOAP_M_URI,null,'0','-1','false'};
        private String[] template_type_info = new String[]{'template',SOAP_M_URI,null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'assignedTo','assignedToType','booleanFilter','businessHours','businessHoursSource','criteriaItems','disableEscalationWhenModified','escalationAction','escalationStartTime','formula','notifyCcRecipients','overrideExistingTeams','replyToEmail','senderEmail','senderName','team','template'};
    }
    
     public class FilterItem {
        public String field;
        public String operation;
        public String value;
        public String valueField;
        private String[] field_type_info = new String[]{'field',SOAP_M_URI,null,'1','1','false'};
        private String[] operation_type_info = new String[]{'operation',SOAP_M_URI,null,'1','1','false'};
        private String[] value_type_info = new String[]{'value',SOAP_M_URI,null,'0','1','false'};
        private String[] valueField_type_info = new String[]{'valueField',SOAP_M_URI,null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'field','operation','value','valueField'};
    }
    
      public class readAssignmentRulesResponse_element implements IReadResponseElement {
        public MetadataService1.ReadAssignmentRulesResult result;
        public IReadResult getResult() { return result; }
        private String[] result_type_info = new String[]{'result',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'result'};
    }
    
    public class EscalationAction {
        public String assignedTo;
        public String assignedToTemplate;
        public String assignedToType;
        public Integer minutesToEscalation;
        public Boolean notifyCaseOwner;
        public String[] notifyEmail;
        public String notifyTo;
        public String notifyToTemplate;
        private String[] assignedTo_type_info = new String[]{'assignedTo',SOAP_M_URI,null,'0','1','false'};
        private String[] assignedToTemplate_type_info = new String[]{'assignedToTemplate',SOAP_M_URI,null,'0','1','false'};
        private String[] assignedToType_type_info = new String[]{'assignedToType',SOAP_M_URI,null,'0','1','false'};
        private String[] minutesToEscalation_type_info = new String[]{'minutesToEscalation',SOAP_M_URI,null,'0','1','false'};
        private String[] notifyCaseOwner_type_info = new String[]{'notifyCaseOwner',SOAP_M_URI,null,'0','1','false'};
        private String[] notifyEmail_type_info = new String[]{'notifyEmail',SOAP_M_URI,null,'0','-1','false'};
        private String[] notifyTo_type_info = new String[]{'notifyTo',SOAP_M_URI,null,'0','1','false'};
        private String[] notifyToTemplate_type_info = new String[]{'notifyToTemplate',SOAP_M_URI,null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'assignedTo','assignedToTemplate','assignedToType','minutesToEscalation','notifyCaseOwner','notifyEmail','notifyTo','notifyToTemplate'};
    }
    public class AddressSettings extends Metadata {
        public String type = 'AddressSettings';
        public String fullName;
        private String[] fullName_type_info = new String[]{'fullName',SOAP_M_URI,null,'0','1','false'};
        public MetadataService1.CountriesAndStates countriesAndStates;
        private String[] countriesAndStates_type_info = new String[]{'countriesAndStates',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] type_att_info = new String[]{'xsi:type'};
        private String[] field_order_type_info = new String[]{'fullName', 'countriesAndStates'};
    }
	 public class CountriesAndStates {
        public MetadataService1.Country[] countries;
        private String[] countries_type_info = new String[]{'countries',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'countries'};
    }
	    public class Country {
        public Boolean active;
        public String integrationValue;
        public String isoCode;
        public String label;
        public Boolean orgDefault;
        public Boolean standard;
        public MetadataService1.State[] states;
        public Boolean visible;
        private String[] active_type_info = new String[]{'active',SOAP_M_URI,null,'1','1','false'};
        private String[] integrationValue_type_info = new String[]{'integrationValue',SOAP_M_URI,null,'1','1','false'};
        private String[] isoCode_type_info = new String[]{'isoCode',SOAP_M_URI,null,'1','1','false'};
        private String[] label_type_info = new String[]{'label',SOAP_M_URI,null,'1','1','false'};
        private String[] orgDefault_type_info = new String[]{'orgDefault',SOAP_M_URI,null,'1','1','false'};
        private String[] standard_type_info = new String[]{'standard',SOAP_M_URI,null,'1','1','false'};
        private String[] states_type_info = new String[]{'states',SOAP_M_URI,null,'0','-1','false'};
        private String[] visible_type_info = new String[]{'visible',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'active','integrationValue','isoCode','label','orgDefault','standard','states','visible'};
    }
	    public class State {
        public Boolean active;
        public String integrationValue;
        public String isoCode;
        public String label;
        public Boolean standard;
        public Boolean visible;
        private String[] active_type_info = new String[]{'active',SOAP_M_URI,null,'1','1','false'};
        private String[] integrationValue_type_info = new String[]{'integrationValue',SOAP_M_URI,null,'1','1','false'};
        private String[] isoCode_type_info = new String[]{'isoCode',SOAP_M_URI,null,'1','1','false'};
        private String[] label_type_info = new String[]{'label',SOAP_M_URI,null,'1','1','false'};
        private String[] standard_type_info = new String[]{'standard',SOAP_M_URI,null,'1','1','false'};
        private String[] visible_type_info = new String[]{'visible',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'active','integrationValue','isoCode','label','standard','visible'};
    }
	   public class ReadAddressSettingsResult implements IReadResult {
        public MetadataService1.AddressSettings[] records;
        public MetadataService1.Metadata[] getRecords() { return records; }
        private String[] records_type_info = new String[]{'records',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'records'};
    }
    public class readAddressSettingsResponse_element implements IReadResponseElement {
        public MetadataService1.ReadAddressSettingsResult result;
        public IReadResult getResult() { return result; }
        private String[] result_type_info = new String[]{'result',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'result'};
    }
        public class GlobalValueSet extends Metadata {
        public String type = 'GlobalValueSet';
        public String fullName;
        private String[] fullName_type_info = new String[]{'fullName',SOAP_M_URI,null,'0','1','false'};
        public MetadataService1.CustomValue[] customValue;
        public String description;
        public String masterLabel;
        public Boolean sorted;
        private String[] customValue_type_info = new String[]{'customValue',SOAP_M_URI,null,'0','-1','false'};
        private String[] description_type_info = new String[]{'description',SOAP_M_URI,null,'0','1','false'};
        private String[] masterLabel_type_info = new String[]{'masterLabel',SOAP_M_URI,null,'1','1','false'};
        private String[] sorted_type_info = new String[]{'sorted',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] type_att_info = new String[]{'xsi:type'};
        private String[] field_order_type_info = new String[]{'fullName', 'customValue','description','masterLabel','sorted'};
    }
        public class ReadGlobalValueSetResult implements IReadResult {
        public MetadataService1.GlobalValueSet[] records;
        public MetadataService1.Metadata[] getRecords() { return records; }
        private String[] records_type_info = new String[]{'records',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'records'};
    }
        public class readGlobalValueSetResponse_element implements IReadResponseElement {
        public MetadataService1.ReadGlobalValueSetResult result;
        public IReadResult getResult() { return result; }
        private String[] result_type_info = new String[]{'result',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'result'};
    }


    public class ReadCustomValueResult implements IReadResult {
        public MetadataService1.CustomValue[] records;
        public MetadataService1.Metadata[] getRecords() { return records; }
        private String[] records_type_info = new String[]{'records',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'records'};
    }
    public class readCustomValueResponse_element implements IReadResponseElement {
        public MetadataService1.ReadCustomValueResult result;
        public IReadResult getResult() { return result; }
        private String[] result_type_info = new String[]{'result',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'result'};
    }
       public class StandardValueSet extends Metadata {
        public String type = 'StandardValueSet';
        public String fullName;
        private String[] fullName_type_info = new String[]{'fullName',SOAP_M_URI,null,'0','1','false'};
        public String groupingStringEnum;
        public Boolean sorted;
        public MetadataService1.StandardValue[] standardValue;
        private String[] groupingStringEnum_type_info = new String[]{'groupingStringEnum',SOAP_M_URI,null,'0','1','false'};
        private String[] sorted_type_info = new String[]{'sorted',SOAP_M_URI,null,'1','1','false'};
        private String[] standardValue_type_info = new String[]{'standardValue',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] type_att_info = new String[]{'xsi:type'};
        private String[] field_order_type_info = new String[]{'fullName', 'groupingStringEnum','sorted','standardValue'};
    }
     public class StandardValue extends CustomValue {
        public String type = 'StandardValue';
        public String fullName;
        private String[] fullName_type_info = new String[]{'fullName',SOAP_M_URI,null,'0','1','false'};
        public String color;
        public Boolean default_x;
        public String description;
        public Boolean isActive;
        public String label;
        private String[] color_type_info = new String[]{'color',SOAP_M_URI,null,'0','1','false'};
        private String[] default_x_type_info = new String[]{'default',SOAP_M_URI,null,'1','1','false'};
        private String[] description_type_info = new String[]{'description',SOAP_M_URI,null,'0','1','false'};
        private String[] isActive_type_info = new String[]{'isActive',SOAP_M_URI,null,'0','1','false'};
        private String[] label_type_info = new String[]{'label',SOAP_M_URI,null,'0','1','false'};
        public Boolean allowEmail;
        public Boolean closed;
        public Boolean converted;
        public Boolean cssExposed;
        public String forecastCategory;
        public String groupingString;
        public Boolean highPriority;
        public Integer probability;
        public String reverseRole;
        public Boolean reviewed;
        public Boolean won;
        private String[] allowEmail_type_info = new String[]{'allowEmail',SOAP_M_URI,null,'0','1','false'};
        private String[] closed_type_info = new String[]{'closed',SOAP_M_URI,null,'0','1','false'};
        private String[] converted_type_info = new String[]{'converted',SOAP_M_URI,null,'0','1','false'};
        private String[] cssExposed_type_info = new String[]{'cssExposed',SOAP_M_URI,null,'0','1','false'};
        private String[] forecastCategory_type_info = new String[]{'forecastCategory',SOAP_M_URI,null,'0','1','false'};
        private String[] groupingString_type_info = new String[]{'groupingString',SOAP_M_URI,null,'0','1','false'};
        private String[] highPriority_type_info = new String[]{'highPriority',SOAP_M_URI,null,'0','1','false'};
        private String[] probability_type_info = new String[]{'probability',SOAP_M_URI,null,'0','1','false'};
        private String[] reverseRole_type_info = new String[]{'reverseRole',SOAP_M_URI,null,'0','1','false'};
        private String[] reviewed_type_info = new String[]{'reviewed',SOAP_M_URI,null,'0','1','false'};
        private String[] won_type_info = new String[]{'won',SOAP_M_URI,null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] type_att_info = new String[]{'xsi:type'};
        private String[] field_order_type_info = new String[]{'fullName','color','default_x','description','isActive','label', 'allowEmail','closed','converted','cssExposed','forecastCategory','groupingString','highPriority','probability','reverseRole','reviewed','won'};
    }
    public virtual class CustomValue extends Metadata {
        public String type = 'CustomValue';
        public String fullName;
        public String color;
        public Boolean default_x;
        public String description;
        public Boolean isActive;
        public String label;
		private String[] fullName_type_info = new String[]{'fullName','SOAP_M_URI',null,'0','1','false'};
        private String[] color_type_info = new String[]{'color','SOAP_M_URI',null,'0','1','false'};
        private String[] default_x_type_info = new String[]{'default','SOAP_M_URI',null,'1','1','false'};
        private String[] description_type_info = new String[]{'description','SOAP_M_URI',null,'0','1','false'};
        private String[] isActive_type_info = new String[]{'isActive','SOAP_M_URI',null,'0','1','false'};
        private String[] label_type_info = new String[]{'label','SOAP_M_URI',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'SOAP_M_URI','true','false'};
        private String[] type_att_info = new String[]{'xsi:type'};
        private String[] field_order_type_info = new String[]{'fullName','color','default_x','description','isActive','label'};
}
}