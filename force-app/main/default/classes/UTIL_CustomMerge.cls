/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    - RWPS-678
* 2. Description 
*    - This Class is invoked from SUB.FLOW_2191: Accounts - Merge Using ClusterId.
*    As ERP Address records (R.TYPE=MASTER) have a changed MDM_Cluster_ID__c value, 
*    we will perform and Account Merge based on the Prior Cluster ID (“D” Duplicate-Id)  and New Cluster ID (“M” Master-ID).
*    
* 3. Objects referenced 
*    - ERP_Address__c, Account
* 4. Callouts to additional Components (including their methods) or None:
*    - None
* 5. Dependant Class(es):
* 6. Invocable: True
*
* 7. Test Class Name: UTIL_CustomMergeTest
*
* 8. Author Name(s): 
*      
*    - 2024.05.21 / RWPS-678 / Sumit Sourav   BASE  
*	 - 2024.09.11 Handle ACR Logic Sumit Sourav
*************************************************************/
Public class UTIL_CustomMerge {
    @InvocableMethod(
        label = 'UTIL_CustomMerge'
        description = 'This method takes two parameters Master Account and Duplicate Account. Duplicate Account gets merged in the Master Account. Using the Apex merge operation, field values on the master record always supersede the corresponding field values on the records to be merged. To preserve a merged record field value, simply set this field value on the master sObject before performing the merge. '
    )
    public static void execute( List<Request> requests ) {
        if(requests.size()>0) {
            for(Request req:requests) {
                if(req!=null && !System.isFuture() && !System.isBatch()) {
                    System.debug('Master Record Id / Name '+req.masterRecord.Id+' / '+req.masterRecord.Name);
                    System.debug('Duplicate Record Id / Name '+req.duplicateRecord.Id+' / '+req.duplicateRecord.Name);
                    List<Id> AccountIdList=new List<Id>{req.masterRecord.Id,req.duplicateRecord.Id};
                        mergeAccounts(AccountIdList);
                }
            }
        }
    }
    
    Public class Request {
        @InvocableVariable(
            label = 'Master Record'
            description = 'After merge happens Duplicate Account gets merged in the Master Account.'
            required = false
        )
        public Account masterRecord;
        @InvocableVariable(
            label = 'Duplicate Record'
            description = 'Duplicate Account gets merged in the Master Account.'
            required = false
        )
        public Account duplicateRecord;
    }
    //Global Variables
    Public static List<Contact> multiContact_OtherDirectGlobal=new List<Contact>();
    public static List<AccountContactRelation> multiACR_OtherIndirect_toRecreate=new List<AccountContactRelation>();
    
    @future 
    public static void mergeAccounts(List<ID> AccIdList) {
        If(AccIdList.Size()>1) {
            String message;
            List<Account> MasterAccList=[Select Id,Mdm_Cluster_Id__c from account where Id=:AccIdList[0]];
            List<Account> DuplicateAccList=[Select Id,Mdm_Cluster_Id__c from account where Id=:AccIdList[1]];
            
            If(MasterAccList.Size()>0 && DuplicateAccList.Size()>0) {
                system.debug('Handle ACR Logic!');
                // Handle ACR Logic (this does steps 1 through 6 of 9)
                handleACRs(MasterAccList[0],DuplicateAccList[0]);
                system.debug('steps 1 through 6 of 9');
                
                // Merge (this is step 7 of 9)
                Database.MergeResult results= Database.merge(MasterAccList[0],DuplicateAccList[0], False);
                system.debug('step 7 of 9 Handle Update Other Direct ACR Logic!');
                
                //Update Other Direct ACR (steps 8 of 9)
                List<Database.SaveResult> resultmultiContact_OtherDirectGlobal=new List<Database.SaveResult>();
                If(multiContact_OtherDirectGlobal.size()>0){
                    resultmultiContact_OtherDirectGlobal = Database.update(multiContact_OtherDirectGlobal, false);
                    system.debug('step 8 of 9 Handle Other Direct ACR Logic!');
                }
                // Capture any error encountered
                for(Database.SaveResult result: resultmultiContact_OtherDirectGlobal){
                    if (!result.isSuccess()){
                        system.debug('Error Encountered in resultmultiContact_OtherDirectGlobal: '+result.getErrors());
                    }
                }
                //ReInsert Other Indirect  (steps 9 of 9)
                List<Database.SaveResult> resultmultiACR_OtherIndirect_toRecreate=new List<Database.SaveResult>();
                If(multiACR_OtherIndirect_toRecreate.size()>0){
                    resultmultiACR_OtherIndirect_toRecreate = Database.insert(multiACR_OtherIndirect_toRecreate, false);
                }
                // Capture any error encountered
                for(Database.SaveResult result: resultmultiACR_OtherIndirect_toRecreate){
                    if (!result.isSuccess()){
                        system.debug('Error Encountered in resultmultiACR_OtherIndirect_toRecreate: '+result.getErrors());
                    }
                }
                system.debug('step 9 of 9 ReInsert Other Indirect Logic!');
                
                //Handle Merge Error
                String mergedIdString;
                String errMsg;
                String stepMsg;
                If(results.getMergedRecordIds()!=null && !results.getMergedRecordIds().isEmpty()) {
                    mergedIdString = string.join(results.getMergedRecordIds(),',');  
                }
                If(results.getErrors()!=null && !results.getErrors().isEmpty()) {
                    errMsg=string.join(results.getErrors(),','); 
                }
                if(results.IsSuccess()) {
                    message='APEX SUCCESS: Account Merge is Successful. Master Account Id is- '+results.getId()+' and Duplicate Account Id is- '+mergedIdString;
                    stepMsg='APEX FINISHED MERGE SUCCESS: '+DuplicateAccList[0].Mdm_Cluster_Id__c+' --> '+MasterAccList[0].Mdm_Cluster_Id__c;
                }
                else {
                    message='APEX FAILED: Account Merge Failed. '+errMsg;
                    system.debug('Merge Failed: '+message);
                    stepMsg='APEX FINISHED MERGE FAILED: '+DuplicateAccList[0].Mdm_Cluster_Id__c+' --> '+MasterAccList[0].Mdm_Cluster_Id__c;
                }
                
                //Inserting Log for Account Merge Status.
                
                SFDC_LOG__c log=new SFDC_LOG__c();
                
                If(message.length()>255) {
                    log.Message_Long__c=message;
                    log.Message__c=message.substring(0, 254);
                } else {
                    log.Message__c=message;
                }
                
                log.Source_Name__c='L.FLOW_1902: ERP Address - After - General / SUB.FLOW_2191: Accounts - Merge Using ClusterId / UTIL_CustomMerge';
                log.Source_Type__c='APEX';
                log.Source_Step__c='Account Merge';
                log.Running_User__c=UserInfo.getUserName();
                log.Source_Step__c=stepMsg;
                insert log;
            }  
        }
    }
    public static void handleACRs(Account MasterAccount,Account DuplicateAccount) {
        // Step 1 Get All ACR related to Master or Duplicate Account 
        List<AccountContactRelation> allACRList=[Select Id,ContactId,AccountId,Isdirect from AccountContactRelation where AccountId IN(:MasterAccount.Id,:DuplicateAccount.Id)];
        
        List<AccountContactRelation> currentACRList=new List<AccountContactRelation>();
        List<AccountContactRelation> currentDirectACRList=new List<AccountContactRelation>();
        List<AccountContactRelation> currentIndirectACRList=new List<AccountContactRelation>();
        List<AccountContactRelation> priorACRList=new List<AccountContactRelation>();
        List<AccountContactRelation> priorDirectACRList=new List<AccountContactRelation>();
        List<AccountContactRelation> priorIndirectACRList=new List<AccountContactRelation>();
        List<Id> currentDirectContactIdList=new List<ID>();
        List<Id> currentInDirectContactIdList=new List<ID>();
        List<Id> priorDirectContactIdList=new List<ID>();
        List<Id> priorInDirectContactIdList=new List<ID>();
        List<Id> priorContactIdList=new List<ID>();
        List<Id> currentContactIdList=new List<ID>();
        List<Id> listContactId=new List<Id>();
        List<Contact> listContact_Unique=new List<Contact>();
        List<Contact> multiContact_OtherDirect=new List<Contact>(); //To be updated after merge
        
        //Iterate ove all ACR and get contactId
        If(allACRList.size()>0){
            
            for(AccountContactRelation acr:allACRList){
                
                listContactId.add(acr.ContactId);//Get AllcontactId
                
                if(acr.AccountId==MasterAccount.Id && acr.IsDirect==TRUE){
                    currentACRList.add(acr);
                    currentDirectACRList.add(acr);
                    currentDirectContactIdList.add(acr.contactId);
                    currentContactIdList.add(acr.contactId);
                }
                if(acr.AccountId==MasterAccount.Id && acr.IsDirect==FALSE){
                    currentACRList.add(acr);
                    currentIndirectACRList.add(acr);
                    currentInDirectContactIdList.add(acr.contactId);
                    currentContactIdList.add(acr.contactId);
                }
                if(acr.AccountId==DuplicateAccount.Id && acr.IsDirect==TRUE){
                    priorACRList.add(acr);
                    priorDirectACRList.add(acr);
                    priorDirectContactIdList.add(acr.contactId);
                    priorContactIdList.add(acr.contactId);
                }
                if(acr.AccountId==DuplicateAccount.Id && acr.IsDirect==FALSE){
                    priorACRList.add(acr);
                    priorIndirectACRList.add(acr);
                    priorInDirectContactIdList.add(acr.contactId);
                    priorContactIdList.add(acr.contactId);
                }
            }
        }
        system.debug('Step 1 Completed!');
        //Step2- Make unique ContactId List Unique
        Set<Id> setContactId_Unique=new Set<Id>(listContactId);
        List<Id> listContactId_unique=new List<Id>(setContactId_Unique);
        
        system.debug('Step 2 Completed!');
        
        
        If(listContactId_unique.size()>0){
            // STEP2- Get All contacts from listContactId_unique (do not filter by account)
           listContact_Unique=[select id,email,accountId from contact where Id IN :listContactId_unique];
            
            //Step3- Get All Contacts with Direct != the Before/After Accounts
            multiContact_OtherDirect=[select id,email,accountId from contact where Id IN :listContactId_unique AND AccountId NOT IN (:MasterAccount.Id,:DuplicateAccount.Id)];// To be updated after Merge
            system.debug('Step 3 Completed!');
        }	
        //What: copies list to list;  WHY: copies contacts with other Direct Account to a list for update after merge so we can set Direct Account back to the way it was
        UTIL_CustomMerge.multiContact_OtherDirectGlobal.addAll(multiContact_OtherDirect);
        
        
        //Step4-Loop Unique Contacts  IF AccountID !=CURRENT, THEN Add to list multiContact_SetAccount to make AccountID=Current (OD and PD becomes OI or PI);
        List<Contact> multiContact_SetAccount=new List<Contact>();
        If(listContact_Unique.size()>0){
            For(Contact c:listContact_Unique){
                If(c.AccountId!=MasterAccount.Id){
                    c.AccountId=MasterAccount.Id;
                    multiContact_SetAccount.add(c);
                }
            }
        }
        //Set the Contact Account to the New Account
        List<Database.SaveResult> resultmultiContact_SetAccount=new List<Database.SaveResult>();
        If(multiContact_SetAccount.size()>0){
           resultmultiContact_SetAccount = Database.update(multiContact_SetAccount, false);
        }
        // Capture any error encountered
        for(Database.SaveResult result: resultmultiContact_SetAccount){
            if (!result.isSuccess()){
                system.debug('Error Encountered in resultmultiContact_SetAccount: '+result.getErrors());
            }
        }
        system.debug('Step 4 Completed!');
        
        //STEP5- GET ACR where Direct=False AND AccountID IN (PRIOR) AND Contact IN listContact_unique;
        List<AccountContactRelation> multiACR_PriorIndirect=[Select Id,ContactId,AccountId,IsDirect from AccountContactRelation where IsDirect=False AND AccountId IN(:DuplicateAccount.Id) AND ContactId IN :listContactId_unique];
        // Delete the multiACR_PriorIndirect (since we set all the contacts tot he New Account, the Older Indirect for the prior account is no longer needed)
        List<Database.DeleteResult> resultmultiACR_PriorIndirect=new List<Database.DeleteResult>();
        If(multiACR_PriorIndirect.size()>0){
            resultmultiACR_PriorIndirect = Database.delete(multiACR_PriorIndirect, false);
        }
        // Capture any error encountered
        for(Database.DeleteResult result: resultmultiACR_PriorIndirect){
            if (!result.isSuccess()){
                system.debug('Error Encountered in resultmultiACR_PriorIndirect: '+result.getErrors());
            }
        }
        system.debug('Step 5 Completed!');
        
        //STEP6- GET ACR WHERE Direct=False AND AccountID NOT IN(CURRENT,PRIOR) AND ContactID IN(listContact_unique);
        List<AccountContactRelation> multiACR_OtherIndirect_toRecreate=[Select Id,ContactId,contact.lastname,AccountId,account.name,IsDirect from AccountContactRelation where IsDirect=False AND AccountId NOT IN (:DuplicateAccount.Id,:MasterAccount.Id) AND ContactId IN :listContactId_unique];
        List<AccountContactRelation> multiACR_OtherIndirect_toDelete=new List<AccountContactRelation>(multiACR_OtherIndirect_toRecreate);
        //Iterate to make a list to recreate Other Indirects
        for(AccountContactRelation acr:multiACR_OtherIndirect_toRecreate){
            system.debug('multiACR_OtherIndirect_toRecreate: '+acr.contactId+acr.contact.lastname+acr.account.name);
            AccountContactRelation acrinst=new AccountContactRelation();
            acrinst.contactId=acr.contactId;
            acrinst.AccountId=acr.Accountid;
            UTIL_CustomMerge.multiACR_OtherIndirect_toRecreate.add(acrinst);
        }
        // Delete the multiACR_OtherIndirect_toDelete
        List<Database.DeleteResult> resultmultiACR_OtherIndirect_toDelete=new List<Database.DeleteResult>();
        If(multiACR_OtherIndirect_toDelete.size()>0){
            resultmultiACR_OtherIndirect_toDelete = Database.delete(multiACR_OtherIndirect_toDelete, false);
            system.debug('resultmultiACR_OtherIndirect_toDelete: '+resultmultiACR_OtherIndirect_toDelete);
        }
        // Capture any error encountered
        for(Database.DeleteResult result: resultmultiACR_OtherIndirect_toDelete){
            if (!result.isSuccess()){
                system.debug('Error Encountered in resultmultiACR_OtherIndirect_toDelete: '+result.getErrors());
            }
        }
        system.debug('Step 6 Completed!');
    }
}