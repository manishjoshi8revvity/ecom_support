public with sharing class FS_ComplaintManager {

    private FS_ComplaintManager() {
    }
    public static void updateLookups(List<FS_Complaint__c> newList, Map<Id, FS_Complaint__c> oldMap)
    {
        // STEP 1: Collect all External Ids and Locations that need to be looked up (SoldTo, Account, Parent)
        Set<String> accountExtIds = new Set<String>();
        List<FS_Complaint__c> updateAcct = new List<FS_Complaint__c>();
        for (FS_Complaint__c complaint : newList)
        {
            FS_Complaint__c old = (oldMap == null) ? null : oldMap.get(complaint.Id);

            // Account: Account_Customer_Number__c --> Account__c
            if (String.isNotEmpty(complaint.Account_Customer_Number__c) && (complaint.Account__c == null ||
                    (old != null && complaint.Account_Customer_Number__c != old.Account_Customer_Number__c)) )
            {
                accountExtIds.add(complaint.Account_Customer_Number__c);
                updateAcct.add(complaint);
            }
        }

        // STEP 2: Lookup Accounts, Partner Sites & Contacts by their External Ids
        Map<String, Account> accountMap = FS_AccountManager.findAccounts(accountExtIds);

        // STEP 3: Fill in the Account / Contact / Parent lookups if found
        for (FS_Complaint__c complaint : updateAcct)
        {
            Account acct = accountMap.get(complaint.Account_Customer_Number__c);
            complaint.Account__c = (acct != null) ? acct.Id : null;
        }
    }
    
    public static void deleteComplaintChildRecords(List<FS_Complaint__c> newComplaintList, Map<Id, FS_Complaint__c> oldComplaintMap)
    {        
        Set<Id> cmpntIds = new Set<Id>();

        List<FS_ComplaintPart__c> cPartDeleteList = new List<FS_ComplaintPart__c>();
        List<FS_ComplaintFaultCode__c> cfCodeDeleteList = new List<FS_ComplaintFaultCode__c>();
        List<FS_ComplaintTask__c> cTaskDeleteList = new List<FS_ComplaintTask__c>();

        Map<Id, List<FS_ComplaintPart__c>> cPartMap = new Map<Id, List<FS_ComplaintPart__c>>();
        Map<Id, List<FS_ComplaintFaultCode__c>> cfCodeMap = new Map<Id, List<FS_ComplaintFaultCode__c>>();
        Map<Id, List<FS_ComplaintTask__c>> cTaskMap = new Map<Id, List<FS_ComplaintTask__c>>();

        if (!newComplaintList.isEmpty()) {
            for (FS_Complaint__c cmpnt : newComplaintList) {
                if (oldComplaintMap.get(cmpnt.Id) != null && oldComplaintMap.get(cmpnt.Id).CompletedTxnNum__c != cmpnt.CompletedTxnNum__c) {
                    cmpntIds.add(cmpnt.Id);
                }
            }
        }
        if (cmpntIds.isEmpty()) {
            return;
        }

        ///////////////////// Fill in Complaint Parts Map
        List<FS_ComplaintPart__c> cPartList = new List<FS_ComplaintPart__c>([SELECT Id, Name, Complaint__c, LastTxnNum__c FROM FS_ComplaintPart__c WHERE Complaint__c IN :cmpntIds]);
        if (!cPartList.isEmpty()) {
            for (FS_ComplaintPart__c cp : cPartList) {
                List<FS_ComplaintPart__c> listCPart = new List<FS_ComplaintPart__c>();                
                if(cPartMap.containsKey(cp.Complaint__c)) {
                    listCPart = cPartMap.get(cp.Complaint__c);
                }
                listCPart.add(cp);
                cPartMap.put(cp.Complaint__c, listCPart);
            }
        }
        if (!newComplaintList.isEmpty()) {
            for ( FS_Complaint__c cmplnt : newComplaintList ) {
                // create list of records to be deleted in Complaint Parts
                List<FS_ComplaintPart__c> listCPart = new List<FS_ComplaintPart__c>();
                if ( cPartMap.containsKey(cmplnt.Id) ) {
                    listCPart = cPartMap.get(cmplnt.Id);
                    if (!listCPart.isEmpty()) {
                        for (FS_ComplaintPart__c cp : listCPart) {
                            if (cp.LastTxnNum__c != cmplnt.CompletedTxnNum__c) {
                                cPartDeleteList.add(cp);
                            }
                        }
                    }
                }
            }
            // delete Complaint Parts
            if (!cPartDeleteList.isEmpty()) {
                delete cPartDeleteList;
            }
        }

        ///////////////////// Fill in Complaint Fault Code Map
        List<FS_ComplaintFaultCode__c> cfCodeList = new List<FS_ComplaintFaultCode__c>([SELECT Id, Name, Complaint__c, LastTxnNum__c FROM FS_ComplaintFaultCode__c WHERE Complaint__c IN :cmpntIds]);
        if (!cfCodeList.isEmpty()) {
            for (FS_ComplaintFaultCode__c cp : cfCodeList) {
                List<FS_ComplaintFaultCode__c> cfcList = new List<FS_ComplaintFaultCode__c>();                
                if(cfCodeMap.containsKey(cp.Complaint__c)) {
                    cfcList = cfCodeMap.get(cp.Complaint__c);
                }
                cfcList.add(cp);
                cfCodeMap.put(cp.Complaint__c, cfcList);
            }
        }
        if (!newComplaintList.isEmpty()) {
            for ( FS_Complaint__c cmplnt : newComplaintList ) {
                // create list of records to be deleted in Complaint Fault codes
                List<FS_ComplaintFaultCode__c> cfcList = new List<FS_ComplaintFaultCode__c>();
                if ( cfCodeMap.containsKey(cmplnt.Id) ) {
                    cfcList = cfCodeMap.get(cmplnt.Id);
                    if (!cfcList.isEmpty()) {
                        for (FS_ComplaintFaultCode__c cp : cfcList) {
                            if (cp.LastTxnNum__c != cmplnt.CompletedTxnNum__c) {
                                cfCodeDeleteList.add(cp);
                            }
                        }
                    }
                }
            }
            // delete Complaint Fault codes
            if (!cfCodeDeleteList.isEmpty()) {
                delete cfCodeDeleteList;
            }
        }

        ///////////////////// Fill in Complaint Task Map
        List<FS_ComplaintTask__c> cTaskList = new List<FS_ComplaintTask__c>([SELECT Id, Name, Complaint__c, LastTxnNum__c FROM FS_ComplaintTask__c WHERE Complaint__c IN :cmpntIds]);
        if (!cTaskList.isEmpty()) {
            for (FS_ComplaintTask__c cp : cTaskList) {
                List<FS_ComplaintTask__c> listTask = new List<FS_ComplaintTask__c>();                
                if(cTaskMap.containsKey(cp.Complaint__c)) {
                    listTask = cTaskMap.get(cp.Complaint__c);
                }
                listTask.add(cp);
                cTaskMap.put(cp.Complaint__c, listTask);
            }
        }
        if (!newComplaintList.isEmpty()) {
            for ( FS_Complaint__c cmplnt : newComplaintList ) {
                // create list of records to be deleted in Complaint Tasks
                List<FS_ComplaintTask__c> listTask = new List<FS_ComplaintTask__c>();
                if ( cTaskMap.containsKey(cmplnt.Id) ) {
                    listTask = cTaskMap.get(cmplnt.Id);
                    if (!listTask.isEmpty()) {
                        for (FS_ComplaintTask__c cp : listTask) {
                            if (cp.LastTxnNum__c != cmplnt.CompletedTxnNum__c) {
                                cTaskDeleteList.add(cp);
                            }
                        }
                    }
                }
            }
            // delete Complaint Tasks
            if (!cTaskDeleteList.isEmpty()) {
                delete cTaskDeleteList;
            }
        }

    }
}