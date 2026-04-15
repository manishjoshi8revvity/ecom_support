/**************************************************************

* 1. Jira Ticket(s) that relates to this class
*  
* 2. Description 
*
* 3. Objects referenced
*    - Account
*    - Contact
*    - User
* 

*************************************************************/

@isTest
public class ECOM_MyAccountModelTest {
    @isTest
    public static void testData()
    {
        ECOM_MyAccountModel er = new ECOM_MyAccountModel();
        er.showAccNumber=true;
        er.accountId ='001';
        er.contactId ='003';
        er.externalId ='0090';
        er.customerNumber='000';
        System.assertEquals(true,er.showAccNumber,false);
    }
}