@isTest
public class UTIL_General_Bypass_Pause_Event_test {
	@isTest static void testMethod1() {
       // General_Bypass_Pause_Event.createNewtransaction();
        Contact con = new Contact();
        con.lastname = 'test';
        List<Contact> conList = new List<Contact>();
        conList.add(con);
        insert conList;
        UTIL_General_Bypass_Pause_Event.createNewtransaction(conList);
        
    }
}