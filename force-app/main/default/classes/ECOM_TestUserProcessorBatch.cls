/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    RWPS - 5507
*
* 2. Description - This batch job updates users as test users in sandbox environments
*
* 3. Objects referenced
*    - User
*
* 4. Test Class Name:
*    - ECOM_OrderCreateBatch_Test
*
* 5. Is @Invocable (Yes or No): No
*
* 6. Author Name(s):
*    - Sachin Vispute 2025.12.29 - Created class to handle test user processing in sandbox
*************************************************************/
public class ECOM_TestUserProcessorBatch implements Database.Batchable<sObject>, Database.Stateful{
    public ECOM_TestUserProcessorBatch() {

    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        List<String> testUserIdentificationValuesList = System.Label.ECOM_Testing_user_identification_values.split(',');
        String query = 'SELECT Id, FirstName, LastName, Email, ECOM_Is_Test_User__c, ContactId FROM User WHERE ECOM_Is_Test_User__c = false';
        query += ' AND Profile.Name IN :testUserIdentificationValuesList';
        query += ' AND (FirstName IN : testUserIdentificationValuesList OR LastName IN :testUserIdentificationValuesList OR Email IN :testUserIdentificationValuesList OR Email IN : testUserIdentificationValuesList)';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<User> usersList) {
        String supportData = '';
        try {
            List<User> usersToUpdateList = new List<User>();
            List<Contact> contactsToUpdateList = new List<Contact>();
            for(User user : usersList) {
                user.ECOM_Is_Test_User__c = true;
                usersToUpdateList.add(user);
                if (user.ContactId != null) {
                    Contact contact = new Contact();
                    contact.Id = user.ContactId;
                    contact.Test_Record__c = true;
                    contactsToUpdateList.add(contact);
                }
            }
            supportData = JSON.serialize(usersToUpdateList);
            if(usersToUpdateList.isEmpty() == false) {
                update usersToUpdateList;
            }
            if(contactsToUpdateList.isEmpty() == false) {
                update contactsToUpdateList;
            }
        } catch (Exception ex) {
            ECOM_ApplicationLogsUtil.logFailure(ex, ECOM_Constant.USER_MODULE_NAME, 'ECOM_TestUserProcessorBatch', 'execute', supportData);
        }
    }

    public void finish(Database.BatchableContext bc) {
    }
}