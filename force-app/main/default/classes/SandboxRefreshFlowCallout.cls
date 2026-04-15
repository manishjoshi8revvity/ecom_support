/**************************************************************
* 1. Jira Ticket(s)
*    - OM-256 automated Sandbox Refresh Scheduler
*    - ATEAM-2070(bug) Fix the time to run
*    - ATEAM-2071 - Add logging
*
* 2. Description - This apex class is used to automated Sandbox Refresh Scheduler
*
* 3. Objects referenced
*    -C_META_Sandbox_Refresh_Scheduler__mdt
*    -SFDC_LOG__c
*
* 4. Callouts to additional Components (including their methods) or None:
- SandboxRefreshScheduler
*    - UTIL_Custom_MetaData_Update

* 5. Dependant Class(es):
*    - UTIL_Custom_MetaData_Update
*    - SandboxRefreshScheduler
*
* 6. Test Class Name: SandboxRefreshCalloutTest
* 
* 7. Is @Invocable (Yes or No): Yes
*
* 8. Author Name(s) (Date YYYY.MM.DD / Tix# / Author Name / Changes made: 
*    -2024.02.06 / OM-256 / Avinash Kumar/Sumit Kumar Sourav(PWC) Base
*    -2024.04.25 / OM-256 / Vishwas Gupta / Taking scheduled time from flow itself and not updating custom Metadata
*    -2024.05.16 / ATEAM-2070(bug) / Brad Durbin / Added Check for Future scheduled Time, adjusts automatically by 5 minutes if in past
*    -2024.05.16 / ATEAM-2071 / Brad Durbin / Added SFDC LOG to lines 106
*    -
*************************************************************/ 

public class SandboxRefreshFlowCallout {
    
    public Class userInputWrapper{
        Public string sbxName;
        Public string action;
        Public string sbxDescription;
        Public boolean sbxAutoactivate;
        Public boolean sbxSchedule;
        Public boolean sbxCopyChatter;
        Public string sbxFrequency;
        Public string sbxTemplateId;
        Public string sbxApexClassId;
        public datetime sbxScheduledTime;
        Public String sbxnotificationEmail;
        Public String LicenseType;
        Public String sbxCopyHistory;
        public Map<String,String> SbxNameIdMap = New Map<String,String>(); 
        public Map<String,String> SbxIdNameMap = New Map<String,String>();
        
    }
    
    public Class flowInputWrapper{
        @invocableVariable(label='List of SBX Refresh Data' required=true)
        public List<C_META_Sandbox_Refresh_Scheduler__mdt> uiwraprlist=new List<C_META_Sandbox_Refresh_Scheduler__mdt>();
    }
    
    @InvocableMethod()
    public static void getFlowSBXDetails(List<flowInputWrapper> uiwrapr){
        
        try{
            List<C_META_Sandbox_Refresh_Scheduler__mdt> updatemetadatalist=new List<C_META_Sandbox_Refresh_Scheduler__mdt>();//add metadata to update
            List<C_META_Sandbox_Refresh_Scheduler__mdt> metadatalist=new List<C_META_Sandbox_Refresh_Scheduler__mdt>();
            
            //LIST for SFDC LOG
            List<SFDC_LOG__c> loglist=new List<SFDC_LOG__c>();
            
            //we declare a variable for NOW so that we can reference it throughout this class. 
            //We adjust for 5 mins in teh future because we always need future time to be the end result. 
            Datetime fxNow=Datetime.now().addMinutes(5);
            
            IF(uiwrapr.size()>0){
                metadatalist=uiwrapr[0].uiwraprlist;
                for(C_META_Sandbox_Refresh_Scheduler__mdt cmeta:metadatalist){
                    userInputWrapper ui=new userInputWrapper();
                    ui.sbxName=cmeta.Sandbox_Name__c;
                    ui.sbxDescription=cmeta.Sandbox_Description__c;
                    ui.action=cmeta.action__c;
                    ui.LicenseType=cmeta.Sandbox_LicenseType__c;
                    ui.sbxAutoactivate=cmeta.Auto_Activate__c;
                    ui.sbxApexClassId=cmeta.Apex_ClassId__c;

                    //Declare a variable to create the schedule time of Current Date + Time from the CMETA original Schedule
                    Datetime ScheduledTime=DateTime.newInstanceGMT(fxNow.date(), cmeta.Scheduled_time__c.time());

                    //Check that calculated Scheduled Time is in Future by 5 minutes, else adjust to be NOW+5 minutes
                    If(ScheduledTime > fxNow ) {
                        ScheduledTime=ScheduledTime;
                        system.debug('ScheduledTime for ' + cmeta.Sandbox_Name__c + ' - original time used (' + ScheduledTime +')' );
                        } else { 
                        ScheduledTime = fxNow;
                        system.debug('ScheduledTime for ' + cmeta.Sandbox_Name__c + ' - Adjusted for future 5 minutes (' + ScheduledTime +')' );
                        }

        
                    // Cron needs to be created from this variable
                    //we compare to current time to ensure we schedule correctly
                    if(ScheduledTime != null && ScheduledTime>=datetime.now()){
                        SandboxRefreshScheduler sc=new SandboxRefreshScheduler(ui);
                        datetime fireTime=  ScheduledTime; // Scheduled date ScheduledTime;
                        List<String> timeParts = new List<String>();
                        timeParts.add(String.valueof(fireTime.second())); 
                        timeParts.add(String.valueof(fireTime.minute())); 
                        timeParts.add(String.valueof(fireTime.hour()));   
                        timeParts.add(String.valueof(fireTime.day()));   
                        timeParts.add(String.valueof(fireTime.month())); 
                        timeParts.add('?');
                        timeParts.add(String.valueof(fireTime.year()));
                        String crontime=String.join(timeParts, ' ');
                        system.debug('crontime used: '+crontime);
                        
                        //ATEAM-2071 / Log the Activity to SFDC LOG                     
                        SFDC_LOG__c log=new SFDC_LOG__c();
                        log.Message__c=' SBX Refresh of [' + cmeta.Sandbox_Name__c + '] @ (' + ScheduledTime + ') using crontime (' + crontime + ')';
                        log.Source_Name__c='SUB.FLOW_9999: UTIL - Sandbox Refresh / SandboxRefreshFlowCallout';
                        log.Source_Type__c='APEX';
                        log.Source_Step__c='BEFORE Scheduling: ' + cmeta.Sandbox_Name__c ;
                        insert log;
                        
                        system.schedule('SRS_' + cmeta.Sandbox_Name__c +'_'+system.Now(),crontime,sc); 
                        
                        
                        system.debug('Starting SFDC LOG creation: ' + cmeta.Sandbox_Name__c);
                        
                        //ATEAM-2071 / Log the Activity to SFDC LOG  
                        //making 2nd log variable to avoid duplicate                   
                        SFDC_LOG__c log2=new SFDC_LOG__c();
                        log2.Message__c='SBX Refresh of [' + cmeta.Sandbox_Name__c + '] @ (' + ScheduledTime + ') using crontime (' + crontime + ')';
                        log2.Source_Name__c='SUB.FLOW_9999: UTIL - Sandbox Refresh / SandboxRefreshFlowCallout';
                        log2.Source_Type__c='APEX';
                        log2.Source_Step__c='AFTER Scheduling: ' + cmeta.Sandbox_Name__c ;
                        loglist.add(log2);
                        system.debug('Completed SFDC LOG creation: ' + cmeta.Sandbox_Name__c);
                      }
                    
                    
                }
                        //INSERT SFDC LOG
                        insert loglist;

            }
            
        }catch(exception e){
            System.debug('!!The following exception has occurred: ' + e.getMessage());
            //ATEAM-2071 / Log the Activity to SFDC LOG                     
            SFDC_LOG__c log=new SFDC_LOG__c();
            log.Message__c='SBX Refresh failed: ' + e.getMessage();
            log.Source_Name__c='SUB.FLOW_9999: UTIL - Sandbox Refresh / SandboxRefreshFlowCallout';
            log.Source_Type__c='APEX';
            log.Source_Step__c='Try/Catch Failed';
            insert log;
            
        }
    }
}