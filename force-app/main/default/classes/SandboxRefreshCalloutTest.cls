/**************************************************************
* 1. Jira Ticket(s)
*    - OM-256 automated Sandbox Refresh Scheduler
*
* 2. Description - This Test class covers SandboxRefreshCallout/SandboxRefreshScheduler/SandboxRefreshFlowCallout
*
* 3. Objects referenced
*    -
*
* 4. Callouts to additional Components (including their methods) or None:
*    
* 5. Dependant Class(es):
*    - SandboxRefreshCalloutMock
*    
*
* 6. Test Class Name: SandboxRefreshCalloutTest
* 
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s): 
*    - Sumit Kumar Sourav /Avinash Kumar(PWC) & Created Date(02/14/2024)
*    - 
*    -
*************************************************************/ 
@isTest
public class SandboxRefreshCalloutTest {
    public static testMethod void testSBXRefresh(){
        
        SandboxRefreshFlowCallout.userInputWrapper wrapper= new SandboxRefreshFlowCallout.userInputWrapper();
        wrapper.sbxName = 'QA';
        wrapper.action='Refresh';
        SandboxRefreshFlowCallout.userInputWrapper wrapper2= new SandboxRefreshFlowCallout.userInputWrapper();
        wrapper2.sbxName = 'QAA';
        wrapper2.action='NEW';
        SandboxRefreshFlowCallout.userInputWrapper wrapper3= new SandboxRefreshFlowCallout.userInputWrapper();
        wrapper3.sbxName = 'QA';
        wrapper3.action='DELETE';
        List<SandboxRefreshFlowCallout.userInputWrapper> wrapperlist=new List<SandboxRefreshFlowCallout.userInputWrapper>();
        wrapperlist.add(wrapper);
        Test.setMock(HttpCalloutMock.class, new SandboxRefreshCalloutMock());
        
        Test.startTest();
        string str = json.serialize(wrapper);
        string str2 = json.serialize(wrapper2);
        string str3 =json.serialize(wrapper3);
        SandboxRefreshCallout.getSandboxDetails(str);
        SandboxRefreshCallout.getSandboxDetails(str2);
        SandboxRefreshCallout.getSandboxDetails(str3);
        SandboxRefreshScheduler sc=new SandboxRefreshScheduler(wrapper);
        
        List<C_META_Sandbox_Refresh_Scheduler__mdt> uiwraprlist1=new List<C_META_Sandbox_Refresh_Scheduler__mdt>();
        C_META_Sandbox_Refresh_Scheduler__mdt uiwraprinst=new C_META_Sandbox_Refresh_Scheduler__mdt();
        
        uiwraprinst.Sandbox_Name__c='QA';
        uiwraprinst.Sandbox_Description__c='Test';
        uiwraprinst.Scheduled__c=True;
        uiwraprinst.Frequency__c = 'Daily';
        uiwraprinst.action__c = 'NEW';
        
        Datetime now=Datetime.now();
        date nowdate=now.date().addDays(1);
        time nowtime=now.time();
        //uiwraprinst.Scheduled_Time__c=Datetime.newInstance(nowdate,nowtime);
        uiwraprinst.next_Schedule_time__c=Datetime.now().addhours(4).addMinutes(5);
        uiwraprinst.Scheduled_Time__c=Datetime.now().addMinutes(5);
        system.debug('test scheduled time '+uiwraprinst.next_Schedule_time__c);
        uiwraprlist1.add(uiwraprinst);
        
        SandboxRefreshFlowCallout.flowInputWrapper fi=new SandboxRefreshFlowCallout.flowInputWrapper();
        List<SandboxRefreshFlowCallout.flowInputWrapper> filist=new List<SandboxRefreshFlowCallout.flowInputWrapper>();
        fi.uiwraprlist=uiwraprlist1;
        filist.add(fi);
        
        SandboxRefreshFlowCallout.getFlowSBXDetails(filist);
        
        String sch ='0 48 * * * ?'; 
        System.schedule('Schedule to update Account Name', sch,sc);
        
        Test.stopTest();
    }
}