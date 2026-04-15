/**************************************************************
* 1. Jira Ticket(s)
*    - OM-396
*
* 2. Description - This apex class is used to Cover 72 hr logic for case.
*
* 3. Objects referenced
*    - Case
*
* 4. Callouts to additional Components (including their methods) or None:
*    
* 5. Dependant Class(es):
*    - EmailMessageTrigger
*    
*
* 6. Test Class Name: EmailMessageTriggerHandlerTest
* 
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s): 
*    - Sumit Kumar Sourav & Created Date(2024.07.15)
*    - Avinash Kumar & Modified Date (2024.07.30)- Added Legacy Case Id Check
*    - Aakash Pal(2025.04.22): Added logic to create a case when email comes on a closed Customer Care Complaint case record(INC0461652)
*    - SS/AS 2025.06.02 Put ParentCaseId null check & Emailmessage parentId should start with 500 ie case.
*************************************************************/
public class EmailMessageTriggerHandler {
    
    public static void executehandler(List<EmailMessage> NewTrigger) {
        TRY {
            System.debug('*** Starting: EmailMessageTriggerHandler');
            List<EmailMessage> emailMessages = NewTrigger;
            List<Case> newCases = new List<Case>();
            List<Case> updateCases = new List<Case>();
            
            // Get parent case Ids
            Set<Id> parentCaseIds = new Set<Id>();
            If(emailMessages.size()>0){
                for (EmailMessage em : emailMessages) {
                    if (em.ParentId != null && String.valueOf(em.ParentId).startsWith('500')){
                        parentCaseIds.add(em.ParentId);
                    }
                } 
            }
            
            IF(parentCaseIds !=NULL){
                
                Map<Id, Case> parentCaseMap = new Map<Id, Case>([SELECT Id,Owner.Username, Status, ClosedDate, Origin, OwnerId, ParentId, RecordTypeId,Case_Layout_Type__c,Case_Status__c,Isclosed,subject,External_Email_Inbox__c,Case_Thread_Token__c,Parent.Case_Thread_Token__c FROM Case WHERE Id =: parentCaseIds]);
                //reparenting of email from child to parent
                map<Id,String> childCaseIdToParentCaseThread = new Map<Id,String>();
                map<Id,String> caseIdToThread = new Map<Id,String>();
                
                for(Case caseItr : parentCaseMap.values()){
                    if(caseItr.ParentId != null)
                        childCaseIdToParentCaseThread.put(caseItr.Id,caseItr.ParentId+';'+caseItr.parent.Case_Thread_Token__c);
                    if(caseItr.Case_Thread_Token__c != null)
                        caseIdToThread.put(caseItr.id,caseItr.Case_Thread_Token__c);
                }
                
                system.debug('childCaseIdToParentCaseThread'+childCaseIdToParentCaseThread+'caseIdToThread'+caseIdToThread);
                
                for(EmailMessage em: emailMessages){ 
                    String refId = '';
                    String childrefId = caseIdToThread.get(em.parentid);
                    if(childrefId!=null && childrefId.length() > 0)
                        childrefId = childrefId.substring(1,childrefId.length()-1);
                    if(em.parentid != null)
                    {
                        if(childCaseIdToParentCaseThread.get(em.ParentId) != null)
                        {
                            Id newParentId = childCaseIdToParentCaseThread.get(em.ParentId).split(';')[0];
                            refId = childCaseIdToParentCaseThread.get(em.ParentId).split(';')[1];
                            refId = refId.substring(1,refid.length()-1);
                            em.ParentId = newParentId;
                            em.Subject = em.Subject.replace(childrefId,refId); 
                        }
                    }
                    system.debug('em.ParentId' + em.ParentId + 'childrefId' + childrefId);
                }
                
                // Get the list of Merged Cases
                Set<Id> mergedCaseIds = new Set<Id>();
                for(Id parentCaseId :parentCaseMap.keySet()) {
                    if (parentCaseMap.get(parentCaseId).Status == 'Merged') {
                        System.debug('*** Adding Merged case to list: ' + parentCaseMap.get(parentCaseId).ParentId);
                        mergedCaseIds.add(parentCaseMap.get(parentCaseId).ParentId);
                    } 
                }
                Map<Id, Case> mergedCaseMap = new Map<Id, Case>([SELECT Id,Owner.Username,Status, ClosedDate, Origin, OwnerId, ParentId, RecordTypeId,Case_Layout_Type__c,Case_Status__c,Isclosed,subject,External_Email_Inbox__c FROM Case WHERE Id =: mergedCaseIds]);
                
                //Truncated email text body to less than 32000 characters(ATEAM-2222)
                String helpText = '\r\n' + 'This text might have been truncated, please see the email to view the full text.';
                
                // Create new cases for email messages that are associated with closed cases
                for(EmailMessage em : emailMessages) {
                    Case c1;
                    If(parentCaseMap.keyset().contains(em.ParentId)) {
                        c1=parentCaseMap.get(em.ParentId);
                        decimal timediffInHrs;
                        If(em.MessageDate!=null && c1.Isclosed==True && c1.ClosedDate!=null) {
                            timediffInHrs=(((em.MessageDate.getTime())-(c1.ClosedDate.getTime()))/(1000.0 * 60.0 * 60.0)); 
                        }
                        system.debug('c1.Status + timediffInHrs'+c1.Status+timediffInHrs);
                        if(c1.Status == 'Merged' && em.Incoming == true) {
                            // Set case ID on email message to be the Merged Parent case
                            em.ParentId = c1.ParentId;
                            System.debug('*** Found Merged case ' + em.ParentId);  
                            // If the merged parent case has been closed for more than 72 hours create a new case
                            If((c1.Case_Layout_Type__c=='Customer Care - General' || c1.Case_Layout_Type__c=='Tech Support/Service' || c1.Case_Layout_Type__c=='Dx Support' || c1.Case_Layout_Type__c=='Dx Software Services' || c1.Case_Layout_Type__c=='BioDiscovery Technical Support') && c1.Isclosed==True && timediffInHrs>72 && !UserInfo.getUserName().containsIgnoreCase('data.migration@revvity.com')) {
                                newCases.add(new Case(Subject = em.Subject, Description = em.TextBody.Left(31800) + helpText, RecordTypeId = c1.RecordTypeId,
                                                      SuppliedEmail = em.FromAddress, SuppliedName = em.FromName, Status = 'New',
                                                      External_Reference__c = em.ParentId, Origin = c1.Origin,Case_Layout_Type__c = c1.Case_Layout_Type__c,
                                                      OwnerId = getownerId(c1)/*c1.OwnerId*/,Case_Status__c='10.New',External_Email_Inbox__c=c1.External_Email_Inbox__c)); 
                            }
                            //If the merged parent case has not been closed for more than 72 hours don't create a new case but instead update the Status to "In Process"
                            If((c1.Case_Layout_Type__c=='Customer Care - General' || c1.Case_Layout_Type__c=='Tech Support/Service' || c1.Case_Layout_Type__c=='Dx Support' || c1.Case_Layout_Type__c=='Dx Software Services' || c1.Case_Layout_Type__c=='BioDiscovery Technical Support') && c1.Isclosed==True && timediffInHrs<=72 && !UserInfo.getUserName().containsIgnoreCase('data.migration@revvity.com')) {
                                System.debug('*** Merged Case has not been Closed for more than 72 hours. Not creating a new case but updating Status to [In Progress] instead.');
                                updateCases.add(new Case(Id = em.ParentId, Status = 'In Progress',Case_Status__c='21.In Progress')); 
                            }
                            // SC-46 If the original Case has been closed for more than 72 hours create a new case
                        }else if((c1.Case_Layout_Type__c=='Customer Care - General' || c1.Case_Layout_Type__c=='Tech Support/Service' || c1.Case_Layout_Type__c=='Dx Support' || c1.Case_Layout_Type__c=='Dx Software Services' || c1.Case_Layout_Type__c=='BioDiscovery Technical Support') && c1.Isclosed==True && timediffInHrs>72 && em.Incoming == true && !UserInfo.getUserName().containsIgnoreCase('data.migration@revvity.com')) {
                            System.debug('*** Adding case to newCases');
                            newCases.add(new Case(Subject = em.Subject, Description = em.TextBody.Left(31800) + helpText, RecordTypeId = c1.RecordTypeId,
                                                  SuppliedEmail = em.FromAddress, SuppliedName = em.FromName, Status = 'New',
                                                  External_Reference__c = em.ParentId, Origin = c1.Origin,Case_Layout_Type__c = c1.Case_Layout_Type__c,
                                                  OwnerId = getownerId(c1)/*c1.OwnerId*/,Case_Status__c='10.New',External_Email_Inbox__c=c1.External_Email_Inbox__c)); 
                            // If the case has not been closed for more than 72 hours don't create a new case but instead update the Status to "In Progress"  
                        }else if((c1.Case_Layout_Type__c=='Customer Care - General' || c1.Case_Layout_Type__c=='Tech Support/Service' || c1.Case_Layout_Type__c=='Dx Support' || c1.Case_Layout_Type__c=='Dx Software Services' || c1.Case_Layout_Type__c=='BioDiscovery Technical Support') && c1.Isclosed==True && timediffInHrs<=72 && em.Incoming == true && !UserInfo.getUserName().containsIgnoreCase('data.migration@revvity.com')) {
                            System.debug('*** Case has not been Closed for more than 72 hours. Not creating a new case but updating Status to [In Progress] instead.');
                            updateCases.add(new Case(Id = em.ParentId, Status = 'In Progress',Case_Status__c='21.In Progress')); 
                            
                        }
                        //Create new case if an email is coming on a closed Customer Care Complaint case record(INC0461652)
                        else if(c1.Case_Layout_Type__c=='Customer Care - Complaint' && c1.Isclosed==True && em.Incoming == true && !UserInfo.getUserName().containsIgnoreCase('data.migration@revvity.com')) {
                            System.debug('*** Adding case to newCases');
                            newCases.add(new Case(Subject = em.Subject, Description = em.TextBody.Left(31800) + helpText, RecordTypeId = c1.RecordTypeId,
                                                  SuppliedEmail = em.FromAddress, SuppliedName = em.FromName, Status = 'New',
                                                  External_Reference__c = em.ParentId, Origin = c1.Origin,Case_Layout_Type__c = 'Customer Care - General',
                                                  OwnerId = getownerId(c1),Case_Status__c='10.New',External_Email_Inbox__c=c1.External_Email_Inbox__c));  
                        }
                        
                    }
                    
                }
                // Insert new Cases 
                system.debug('newCases='+newCases);
                Database.SaveResult[] srListCases = Database.insert(newCases, false);
                // Update Case Status for Cases that were closed less then 72 hours
                system.debug('*** updateCases: '+updateCases);
                Database.SaveResult[] srListCaseUpdates = Database.update(updateCases, false);
                
                // Re-Parent the Emails
                for (Case newCase : newCases) {
                    System.debug('*** newCase.Id: ' + newCase.Id);
                    for (EmailMessage emailMessage : emailMessages) {
                        if(emailMessage.ParentId == newCase.External_Reference__c) {
                            System.debug('*** Original ParentId:' + emailMessage.ParentId);
                            emailMessage.ParentId = newCase.Id;
                            System.debug('*** New ParentId:' + emailMessage.ParentId);
                        }
                    }
                }
                System.debug('*** Ending: EmailMessageTriggerHandler');
                
                
            }   
        }CATCH(Exception ex) {
            SFDC_LOG__c eachLog = new SFDC_LOG__c();
            eachLog.Source_Type__c = 'APEX';
            eachLog.Log_Type__c = 'Error/Exception Log';
            eachLog.Source_Step__c = 'FAILED: EmailMessageTriggerHandler';
            eachLog.Source_Name__c = 'A.CLS EmailMessageTriggerHandler';
            eachLog.Running_User__c = UserInfo.getName();
            eachLog.Message_Long__c =ex.getMessage()+ex.getLineNumber();
            eachLog.Message__c =ex.getMessage()+ex.getLineNumber();
            system.debug('***eachLog'+eachLog);
            Insert eachLog;
            
        }
    }
    
    Public Static string getownerId(Case c) {
        system.debug('@@@@@c.subject'+c.subject);
        if(c.External_Email_Inbox__c!=null) {	
            List<C_META_E2C_Routing__mdt> cmeta=new List<C_META_E2C_Routing__mdt>();
            cmeta=[Select Id,Service_Address_Email__c,OwnerQueueLabel__c,Additional_Emails__c,Case_Layout_Type__c,Email_Subject__c,From_Address__c,Reply_To_All_Recipients__c
                   From C_META_E2C_Routing__mdt
                   Where Service_Address_Email__c=:c.External_Email_Inbox__c];
            If(cmeta!=null && cmeta.size()>0) {
                List<Group> que=new List<Group>();
                que=[Select id,Name,Developername from Group where Type='QUEUE' AND Name=:cmeta[0].OwnerQueueLabel__c ];
                if(que!=null && que.size()>0) {
                    return que[0].Id;
                }else {
                    return c.ownerId;
                }
            }else {
                return c.ownerId;
            }
        }else{
            return c.ownerId;
        }
        
    }
}