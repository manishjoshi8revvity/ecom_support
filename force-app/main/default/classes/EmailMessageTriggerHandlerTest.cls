/**************************************************************
* 1. Jira Ticket(s)
*    - OM-396 
*
* 2. Description - This apex trigger is used to perform testing of EmailMessageTriggerHandler & EmailMessageTrigger.
*
* 3. Objects referenced
*    - Case
*
* 4. Callouts to additional Components (including their methods) or None:
*    
* 5. Dependant Class(es):
*    - EmailMessageTriggerHandler
     - EmailMessageTrigger
*    
*
* 6. Test Class Name: EmailMessageTriggerHandlerTest
* 
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s): 
*    - Sumit Kumar Sourav & Created Date(2024.07.13)
*    - Aakash Pal(2025.04.22): Modified test data to include Text Body of the email(ATEAM-2222)
*************************************************************/
@isTest(SeeAllData=TRUE)
public class EmailMessageTriggerHandlerTest {
    public static testMethod void testEmailMessage() {
        
        Test.startTest();
            Group testGroup = new Group(Name='test group', Type='Queue');
            insert testGroup;
        
            System.runAs(new User(Id=UserInfo.getUserId()))
            {
                QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Case');
                insert testQueue;
            }
            C_META_E2C_Routing__mdt cmeta=new C_META_E2C_Routing__mdt();
            cmeta.Service_Address_Email__c='supportlatam@revvity.com';
        	cmeta.OwnerQueueLabel__c='test group';
            Profile pf = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
            User tempUser = new User();
            tempUser.FirstName = 'Data';
            tempUser.LastName = 'Migration';
            tempUser.email = 'sfdc@test.ocm';
            tempUser.Username = 'data.migration@test.com';
            tempUser.EmailEncodingKey = 'ISO-8859-1';
            tempUser.Alias = 'DMUR01';
            tempUser.TimeZoneSidKey = 'America/Los_Angeles';
            tempUser.LocaleSidKey = 'en_US';
            tempUser.LanguageLocaleKey = 'en_US';
            tempUser.ProfileId = pf.id;
            insert tempUser;
            
            Account acc=new Account();
            acc.name='Test Account';
            insert acc;
            
            Contact con=new Contact();
            con.lastname='test';
            con.email='scott.greenwood@revvity.com';
            con.accountId=acc.Id;
            insert con;
            
            Case c1=new case();
            c1.Subject='Test1';
            c1.status='Closed';
            c1.case_Status__c='31.Closed';
            c1.Ownerid=tempUser.id;
            c1.AccountId=acc.Id;
            c1.ContactId=con.Id;
            c1.Case_Layout_Type__c='Customer Care - General';
            c1.SAP_Reference_Number__c='test';
            c1.Resolution_Detail__c='Test';
            c1.External_Email_Inbox__c='supportlatam@revvity.com';
            insert c1;
            system.debug('C1:'+c1.External_Email_Inbox__c);
            Case c2=new case();
            c2.Subject='Test2';
            //c2.status='New';
            c2.case_Status__c='10.New';    
            //c2.status='In Progress';
            //c2.case_Status__c='21.In Progress';
            c2.AccountId=acc.Id;
            c2.ContactId=con.Id;
            c2.Ownerid=tempUser.id;
            c2.Case_Layout_Type__c='Customer Care - General';
            c2.SAP_Reference_Number__c='test';
            c2.Resolution_Detail__c='Test';
            c2.External_Email_Inbox__c='supportlatam@revvity.com';
            c2.Description='test';
            insert c2;
            c2.status='Closed';
            c2.case_Status__c='31.Closed';
            c2.Case_Path_Status__c='Closed';
            update c2;
            system.debug('Closed Date'+c2.ClosedDate);
            Case c3=new case();
            c3.Subject='Test3';
            c3.status='New';
            c3.ParentId=c2.Id;
            c3.Ownerid=tempUser.id;
            //c3.case_Status__c='31.Closed';
            c3.AccountId=acc.Id;
            c3.ContactId=con.Id;
            c3.Case_Layout_Type__c='Customer Care - General';
        	c3.External_Email_Inbox__c='supportlatam@revvity.com';
            insert c3;
            c3.status='Merged';
            update c3;
            EmailMessage emailMessage = new EmailMessage();
            emailMessage.status = '3'; // email was sent
            emailMessage.ParentId = c1.Id; 
            emailMessage.fromAddress = 'billing@acme.com'; // from address
            emailMessage.fromName = 'Billing Department'; // from name
            emailMessage.toAddress = 'sks@example.com';
            emailMessage.Subject = 'Hello';
            emailMessage.HtmlBody = 'Hello World';
        	emailMessage.TextBody = 'Hello World';
            emailmessage.Incoming=True;
            emailmessage.messagedate=system.now().addMinutes(2);
            insert emailMessage;
            
            EmailMessage emailMessage2 = new EmailMessage();
            emailMessage2.status = '3'; // email was sent
            emailMessage2.ParentId = c3.Id; 
            emailMessage2.fromAddress = 'billing@acme.com'; // from address
            emailMessage2.fromName = 'Billing Department'; // from name
            emailMessage2.toAddress = 'sks@example.com';
            emailMessage2.Subject = 'Hello';
            emailMessage2.HtmlBody = 'Hello World';
        	emailMessage2.TextBody = 'Hello World';
            emailmessage2.Incoming=True;
            emailmessage2.messagedate=system.now().addDays(7);
            insert emailMessage2;
            
            EmailMessage emailMessage3 = new EmailMessage();
            emailMessage3.status = '3'; // email was sent
            emailMessage3.ParentId = c2.Id; 
            emailMessage3.fromAddress = 'billing@acme.com'; // from address
            emailMessage3.fromName = 'Billing Department'; // from name
            emailMessage3.toAddress = 'sks@example.com';
            emailMessage3.Subject = 'Hello';
            emailMessage3.HtmlBody = 'Hello World';
        	emailMessage3.TextBody = 'Hello World';
            emailmessage3.Incoming=True;
            emailmessage3.messagedate=system.now().addDays(7);
            insert emailMessage3;
        
            List<emailMessage> emailMessagelist=new List<emailMessage>();
            emailMessagelist.add(emailMessage3);
            EmailMessageTriggerHandler.executehandler(emailMessagelist);
            emailMessagelist.add(emailMessage);
            emailMessagelist.add(emailMessage2);
            EmailMessageTriggerHandler.executehandler(emailMessagelist);
        
        Test.stopTest();
        
    }
}