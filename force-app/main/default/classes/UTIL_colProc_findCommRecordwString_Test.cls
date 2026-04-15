/**************************************************************
  * 1. Ticket(s) that relates to this class
  *    - OM-180
  *    - OM-215
  *
  * 2. Description - Test class for UTIL_colProc_findCommRecordwString
  *
  * 3. Objects referenced
  *    - None
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None
  *
  * 5. Dependant Class(es):
  *    - None
  *
  * 6. Test Class Name: UTIL_colProc_findCommRecordwString_Test
  *
  * 7. Is @Invocable (Yes or No):  No
  *
  * 8. Author Name(s): 
  *    - Aakash Pal 2023.10.26
  *
*************************************************************/

@isTest
public class UTIL_colProc_findCommRecordwString_Test { 
	@isTest
    static void compareRecordsWithStringsTest(){
        Profile sysAdmin = [select id,name from profile where name like 'System Administrator%' limit 1];
        Id profileId = sysAdmin.Id;
        List<User> userList1 = new List<User>();
        for(Integer i = 0; i<3; i++) {
        	User usr = new User(Email = 'Test' + i + '@atest.com',
            Username = 'Test' + i + '@atest.com',   
            Title = 'Manager' + i,
            Alias = 'Test' + i,
            ProfileId = profileId,
            EmailEncodingKey='UTF-8', LastName='Testing' + i, LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', isActive = true, 
            TimeZoneSidKey='America/Los_Angeles');  
            userList1.add(usr);
        }
        if(userList1.size() > 0) {
            insert userList1;
        }
        List<String> jobTitles = new List<String>{'Manager','Sr. Manager'};
        List<String> jobTitles1 = new List<String>{'Manager0','Sr. Manager', 'Manager1'};
        List<String> jobTitles2 = new List<String>{};
        UTIL_colProc_findCommRecordwString.compareRecordsWithStrings(userList1, jobTitles, 'Title');
        UTIL_colProc_findCommRecordwString.compareRecordsWithStrings(userList1, jobTitles1, 'Title');
        UTIL_colProc_findCommRecordwString.compareRecordsWithStrings(userList1, jobTitles2, 'Title');
    }
}