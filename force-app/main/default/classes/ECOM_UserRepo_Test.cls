/**************************************************************

	* 1. Jira Ticket(s) that relates to this class
	*
	*
	* 2. Description - This is a test class
	*
	* 3. Objects referenced
	*    - User
	*    - Account
	*    - Contact
	*

	* 4. Callouts to additional Components (including their methods) or None:
	*    - None
	*
	* 5. Dependant Class(es):
	*    - ECOM_TestUtil
	*    - classes called from test class

	* 6. Test Class Name:
	*
	*
	* 7. Is @Invocable : No
	*
	* 8. Author Name(s):
	*    - manojkumar 2023.09.17
    *    - Abhishek 2025.04.03 Added method testGetUserRecordByUserEmail. Ticket - RWPS-2858
    *    - Sachin V 2025.12.29 Added method testGetOrganizationDetails. Ticket - RWPS-5436
	*************************************************************/
@isTest(SeeAllData=false)
private with sharing class ECOM_UserRepo_Test {
    static User sysAdminUser;
    @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
    }

    @isTest
    static void testUserRepoMethod() {
        User user = [SELECT Id, Username FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        List<User> users = ECOM_UserRepo.getUsersByUsername(user.Username);
        System.assertEquals(1, users.size(), 'Incorrect number of users returned');
        User userById = ECOM_UserRepo.getUserByUserId(user.Id);
        System.assertEquals(user.Id, userById.Id, 'user Does not match');
        users = ECOM_UserRepo.getUsersByUserIds(new Set<String>{user.Id});
        System.assertEquals(1, users.size(), 'Incorrect number of users returned');

    }

    @isTest
    static void testUserPasswordMethod() {
        User sysAdminUser =   [SELECT Id, Username FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        String newPassword = 'TestPassword123';
        Test.startTest();
        ECOM_UserRepo.doSetPassword(sysAdminUser.Id, newPassword);
        User updatedUser = [Select Id FROM User WHERE Id=:sysAdminUser.Id];
        System.assertNotEquals(null, updatedUser, 'Password should be set');
        User user = [SELECT Id, Username, Email FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        user.Email = 'updated@example.com';
        ECOM_UserRepo.updateUser(user);
        Test.stopTest();
        User updUser = [SELECT Email FROM User WHERE Id = :user.Id LIMIT 1];
        System.assertEquals('updated@example.com', updUser.Email);
        }
		@isTest
   		static void testfutureUpdateUserPassword() {
		User user =   [SELECT Id, Username FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        Test.startTest();
        ECOM_UserRepo.futureUpdateUserPassword('NewPassword12345', user.Id);
        Test.stopTest();
		User updatedUser = [SELECT Id FROM User WHERE Id = :user.Id];
		System.assertNotEquals(null, updatedUser.Id);
    	}

    /**
      * @description Test cases to get user record through multiple ways
      * @author Abhishek Joshi
      * @date 02-04-2025
     */
    @isTest
    static void testGetUserRecordByUserEmail() {
        User u =   [SELECT Id, Account.Name, Username, Email FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
        u.ECOM_Is_Punchout_User__c = true;
        update u;
        Test.startTest();
        List<User> uList = ECOM_UserRepo.getUserRecordByUserEmail(u.Email);
        List<User> uList2 = ECOM_UserRepo.getAccountInformationForUserId(u.Id);
        List<User> uList3 = ECOM_UserRepo.getPunchoutUserInformationByUserId(u.Id);
        List<User> uList4 = ECOM_UserRepo.getPunchoutUserInformationForErpAddress(u.Id);
        List<User> uList5 = ECOM_UserRepo.getPunchoutUserInformationByUserName(u.Username);
        List<User> uList6 = ECOM_UserRepo.isPunchoutUserExists(u.Username);
        List<User> uList7 = ECOM_UserRepo.checkCommunityUsers(new List<String>{u.Email});
        List<User> uList8 = ECOM_UserRepo.checkInternalUsers(new List<String>{u.Email});

        System.assertEquals(uList[0].Id, u.Id);
        System.assertEquals(uList2[0].Account.Name, u.Account.Name);
        System.assertEquals(uList3[0].Email, u.Email);
        System.assertEquals(uList4[0].Email, u.Email);
        System.assertEquals(uList5[0].Email, u.Email);
        System.assertEquals(uList6[0].Id, u.Id);
        System.assertEquals(uList7[0].Email, u.Email);
        System.assertEquals(uList8[0].Email, u.Email);
        Test.stopTest();
    }

    /**
     * @description This test method is to test getOrganizationDetails method in ECOM_UserRepo class.
     * @author Sachin V | 2025.12.29 | RWPS-5436
     */
    @isTest
    static void testGetOrganizationDetails() {
        List<Organization> organizationDetailsList = new List<Organization>();
        Id organizationId = UserInfo.getOrganizationId();
        Test.startTest();
        organizationDetailsList = ECOM_UserRepo.getOrganizationDetails(new List<String>{String.valueOf(organizationId)});
        Test.stopTest();
        Assert.areEqual(false, organizationDetailsList.isEmpty(), 'Organization details should be fetched');
    }
}