@isTest
public class UTIL_RollupTool_Test {
 @testSetup static void methodName() {

     }
    @isTest static void testmethod1() {
        campaign cmp= new Campaign(name ='TEST_STRING' , isActive = true);
        Insert cmp;
        interaction__c intr= new interaction__c();
        intr.Campaign__c =cmp.Id;
        intr.ownerId=userinfo.getUserId();
        insert intr;
        List<UTIL_RollupTool.FlowInputs> requestList= new List<UTIL_RollupTool.FlowInputs>();
        UTIL_RollupTool.FlowInputs request= new UTIL_RollupTool.FlowInputs();
        request.varMappingFor='CampaignRollup';
        request.multiSourceRecordIds=cmp.Id;
        requestList.add(request);
        UTIL_RollupTool.flowcalled(requestList);
    }
}