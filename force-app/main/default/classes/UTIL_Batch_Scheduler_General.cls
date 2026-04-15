/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *    -  
  *
  * 2. Description:   UTIL_Batch_Scheduler_General
  *     From this apex class we can schedule apex class by providing name of apex class 
  *     and cron experssion for scheduler.
  *
  * 3. Objects referenced
  *    
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None
  *
  * 5. Dependant Class(es):
  *    - PSET_PermissionSettings_Copy_Batch,PSET_Filter_Batch
  *
  * 6. Test Class Name: 
  * 
  * 7.Invocable: Yes
  * 
  * 8. Author Name(s): 
  *    - Vishwas Gupta 2023.01.30
  *
*************************************************************/ 
public class UTIL_Batch_Scheduler_General {

     Public class FlowInputs {         
     //   @InvocableVariable public Integer timeafter;         
        @InvocableVariable public String BatchclassName; 
    }
     @InvocableMethod
    public static void flowcalled(List<FlowInputs> requests){
      //  integer timeaftervalue;
        string BatchclassNamevalue;
        if(requests != null && !requests.isEmpty()){
         //   timeaftervalue=requests[0].timeafter;
          //Set the Time to begin ('nextFireTime') generally and use it below
                
                //create a variable for current time
                DateTime myDate = System.now().addSeconds(5);
                Boolean run = false;
                    
                //parse out the values to use in Cron
                String hour = String.valueOf(myDate.hour());
                String min = String.valueOf(myDate.minute());
                String ss = String.valueOf(myDate.second()); 
                String day = String.valueOf(myDate.day());  //run today on only
                String mon = String.valueOf(myDate.month()); //run today on only 
                String year = String.valueOf(myDate.year());  //run today on only
                
                //set the future fire time:
                  String nextFireTime = ss + ' ' + min + ' ' + hour + ' ' + day + ' ' + mon + ' ? ' + year;
                  String timelabel = year+'.'+mon+'.'+day+'__'+hour+':'+min+':'+ss;
         
            //decide which Class to run
            //TODO:  Make this dynamic and not hardcoded
             
             /*
            switch on BatchclassNamevalue {
              when 'PSET_Filter_Batch' {
                PSET_Filter_Batch schd = new PSET_Filter_Batch();
                system.schedule(BatchclassNamevalue+'__'+timelabel,nextFireTime,schd);
                run=true;
               }    
              when 'PSET_PermissionSets_Copy_Batch' {
                PSET_PermissionSets_Copy_Batch schd= new PSET_PermissionSets_Copy_Scheduler();
                system.schedule(BatchclassNamevalue+'__'+timelabel,nextFireTime,schd);
                run=true;
               }
              when else { 
              // do nothing
             }
            }
            
            if(run==true) {
              //system.schedule(BatchclassNamevalue+'__'+timelabel,nextFireTime,schd);
            }*/
            
            
            BatchclassNamevalue=requests[0].BatchclassName;
            if(BatchclassNamevalue != null && BatchclassNamevalue=='PSET_Filter_Batch'){
                PSET_Filter_Batch schd = new PSET_Filter_Batch();
                system.schedule(BatchclassNamevalue+'__'+timelabel ,nextFireTime,schd);
            }
            if(BatchclassNamevalue != null && BatchclassNamevalue=='PSET_PermissionSets_Copy_Batch'){
                PSET_PermissionSets_Copy_Scheduler schd= new PSET_PermissionSets_Copy_Scheduler();
                system.schedule(BatchclassNamevalue+'__'+timelabel ,nextFireTime,schd);
            }
        }
    }
}