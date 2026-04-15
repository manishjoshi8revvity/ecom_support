/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*    RWPS - 5507
*
* 2. Description - This schedulable class is used to trigger the batch job - ECOM_TestUserProcessorBatch.
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
*    - Sachin Vispute 2025.12.29 - Created this class to schedule test user processing batch in sandbox
*************************************************************/

public class ECOM_TestUserProcessorSchedulable implements Schedulable{
    public void execute(SchedulableContext sc) {
        Id organizationId = UserInfo.getOrganizationId();
        List<Organization> organizationDetailsList = new List<Organization>();
        if (organizationId != null) {
            organizationDetailsList = ECOM_UserRepo.getOrganizationDetails(new List<String>{String.valueOf(organizationId)});
        }
        if (organizationDetailsList.isEmpty() == false && organizationDetailsList[0] != null && organizationDetailsList[0].IsSandbox == true) {
            Database.executeBatch(new ECOM_TestUserProcessorBatch(),200);
        }
    }
}