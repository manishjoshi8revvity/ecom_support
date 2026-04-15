/**************************************************************
* 1. Ticket(s) that relates to this class
*    - OM-247
*
* 2. Description - This class is test class for UTIL_ResetPasswordUser
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
* 6. Test Class Name: UTIL_ResetPasswordUser_Test
*
* 7. Is @Invocable (Yes or No):  No
*
* 8. Author Name(s): 
*    - Aakash Pal 2023.11.10
*
*************************************************************/
@isTest
public class UTIL_ResetPasswordUser_Test {
    @isTest
    static void resetPassWordTest(){
        Profile sysAdmin = [select id,name from profile where name like 'System Administrator%' limit 1];
        Id profileId = sysAdmin.Id;
        
        User usr = new User(Email = 'Test' + 1 + '@atest.com',
                            Username = 'Test' + 1 + '@atest.com',   
                            Title = 'Manager' + 1,
                            Alias = 'Test' + 1,
                            ProfileId = profileId,
                            EmailEncodingKey='UTF-8', LastName='Testing' + 1, LanguageLocaleKey='en_US', 
                            LocaleSidKey='en_US', isActive = true, 
                            TimeZoneSidKey='America/Los_Angeles');  
        insert usr;
        
        List<UTIL_ResetPasswordUser.FlowInputs> RequestList = new List<UTIL_ResetPasswordUser.FlowInputs>();
        UTIL_ResetPasswordUser.FlowInputs Request = new UTIL_ResetPasswordUser.FlowInputs();
        Request.UserId=usr.Id;
        Request.sendEmail = False;
        RequestList.add(Request);
        UTIL_ResetPasswordUser.resetPassWord(RequestList);
        
    }
}