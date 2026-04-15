@isTest(seeAllData=false)
public class FS_Complaint_UT
{         
    static testMethod void createComplaintTestData()
    {   

        //Insert Product
        product2 prod = new product2(
                            Name='Test Product');
        insert prod;

        // Insert Complaint
        FS_Complaint__c compl = new FS_Complaint__c();
        insert compl;

        // Insert Complaint Part
        FS_ComplaintPart__c cPart = new FS_ComplaintPart__c(
                            Complaint__c=compl.Id,
                            Part__c=prod.Id);
        insert cPart;

        // Insert Complaint Fault Code
        FS_ComplaintFaultCode__c cFault = new FS_ComplaintFaultCode__c(
                           Complaint__c=compl.Id);
        insert cFault;

        // Insert Complaint Task
        FS_ComplaintTask__c cTask = new FS_ComplaintTask__c(
                            Complaint__c=compl.Id);
        insert cTask;

        compl.CompletedTxnNum__c='ABC';
        update compl;
    }       
}