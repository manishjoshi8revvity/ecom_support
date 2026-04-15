/**************************************************************
 * 1. Ticket(s) that relates to this class
 * - ECOM-70
 *
 * 2. Description - it is test class for ECOM_UserService
 *
 * 3. Objects referenced
 * - Account
 * - Contact
 * - User
 *
 * 4. Callouts to additional Components:
 * - None
 *
 * 5. Dependant Class(es):
 * - ECOM_EncryptUtil
 *
 * 6. Test Class Name: N/A
 *
 * 7. Is @Invocable : No
 *
 * 8. Author Name(s): 
 * - Vipul 2023.08.10
 *  - Vinay 2025.1.09 updated method testPreparePunchoutLoginParameters
*************************************************************/ 
@isTest
public with sharing class ECOM_UserService_Test {
    
    /**
   * @description this method is used to create test data.
   */
   	@TestSetup
    public static void testData(){
        //ECOM_TestUtil.testDataIntialSetup();
        ECOM_TestUtil.initialStorefrontSetup();
    }
    

    @isTest
    public static void testUserLogin() {
        Test.startTest();
        // Create test data
        
        Map<String, String> mapPageParams = new Map<String, String>();
        // Set up encrypted token and code
        String pass = 'TestPassword@123';
        mapPageParams.put('defaultPathForAddressRegistration','test/url');
        mapPageParams.put(ECOM_Constant.ENCRYPTED_TOKEN,'TestToken!!!!!!!');
        mapPageParams.put(ECOM_Constant.ENCRYPTED_CODE,'AES256');
        Type userService = Type.forName(ECOM_Constant.USER_SERVICE);
        ECOM_IUserService userServiceInstance = (ECOM_IUserService) userService.newInstance();
        String returnUrl = userServiceInstance.userLogin(mapPageParams);
        //mapPageParams.put(ECOM_Constant.ENCRYPTED_TOKEN,'');
        //userServiceInstance.userLogin(mapPageParams);
        
        ECOM_SetPasswordFlowWrapper.PasswordRequest passwordReq = new ECOM_SetPasswordFlowWrapper.PasswordRequest();
        mapPageParams.remove('defaultPathForAddressRegistration');
        userServiceInstance.userLogin(mapPageParams);
        mapPageParams.clear();
        userServiceInstance.userLogin(mapPageParams);
        User testUser = [Select Id,LastName,UserName,ContactId From User ORDER BY CREATEDDATE DESC LIMIT 1]; 
         //PasswordRequest passwordReq = new PasswordRequest();
        
        // Populate the fields with test data
        passwordReq.userName = testUser.Username;
        passwordReq.userId = testUser.Id;
        
        Map<String,Blob> enPass = ECOM_EncryptUtil.encryptWithManagedIV(pass);
        passwordReq.newPassword =ECOM_EncryptUtil.encryptWithAES256(pass);
        Blob enPassBlob = enPass.get(ECOM_Constant.ENCRYPTED_TOKEN);
        passwordReq.token = EncodingUtil.base64Encode(enPassBlob);
        Blob enCode = enPass.get(ECOM_Constant.ENCRYPTED_CODE);
        passwordReq.code =EncodingUtil.base64Encode(enCode);
        List<ECOM_SetPasswordFlowWrapper.PasswordRequest> req = new List<ECOM_SetPasswordFlowWrapper.PasswordRequest>();
        req.add(passwordReq);
        ECOM_UserService usi = new ECOM_UserService();
        List<ECOM_SetPasswordFlowWrapper.PasswordResponse> setpw = usi.setPassword(req);
        passwordReq.code ='';
        usi.setPassword(req);
        // Perform assertions based on the expected behavior
        System.assertNotEquals('Null', returnUrl,'Expectedresult');
        
        Test.stopTest();
    }
  
    @isTest
    static void testGetContactIdByUserNameUserFound() {
        Contact testContact = [Select Id,LastName From Contact ORDER BY CREATEDDATE DESC LIMIT 1];
        User testUser = [Select Id,LastName,UserName,ContactId From User Where ContactId =:testContact.Id  ORDER BY CREATEDDATE DESC LIMIT 1]; 

        // Call the getContactIdByUserName method
        String contactId = ECOM_UserService.getContactIdByUserName(testUser.Username);

        // Verify that the contactId is not empty and matches the expected value
        System.assertNotEquals('', contactId, 'Expected a non-empty contactId');
        
    }

    // Test method for no user with the specified username is found
    @isTest
    static void testGetContactIdByUserNameUserNotFound() {
        // Call the getContactIdByUserName method with a username that does not exist
        String contactId = ECOM_UserService.getContactIdByUserName('nonexistent@example.com');

        // Verify that the contactId is empty ('')
        System.assertEquals('', contactId, 'Expected an empty contactId');
    }
    
    @isTest
    static void testUserServiceClass()
    {
        ECOM_UserService obj = new ECOM_UserService();
        String profileName = Label.ECOM_CommunityProfileName;
        User usr = [Select Id,LastName,Username From User ORDER BY CREATEDDATE DESC LIMIT 1];
        //usr.isActive =true;
        //update usr;
        User sysu = ECOM_TestUtil.createSysAdminUser();
        System.runAs(usr)
        {
            Test.startTest();
            String res = ECOM_UserService.getContactIdByUserName(usr.username);
            User returnedUser = obj.getUserByUserId();
            User res2  = obj.getUserByUser(usr.Id);
            usr.email = 'test_00r1@yopmail.com.invalid';
            ECOM_UserService.updateUser(usr);
            User ts = [SELECT email FROM User WHERE Id = :usr.Id];
            System.AssertEquals('test_00r1@yopmail.com.invalid',ts.email,'invalid email update');
            ECOM_UserService.updateUser(usr);
            ECOM_UserService.updateUserPassword('T1234567833225', usr.Id);
            System.AssertNotEquals(null,res,'invalid ');
            Test.stopTest();
        }
        
    }

    
     @isTest
    static void testGetUserModelForPunchoutUserId(){
        
        User testUser = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        
        String userId = 'testUser.Id';
        Test.startTest();
        ECOM_UserService userService = new ECOM_UserService();
        ECOM_POUserModel actualUserModel = userService.getUserModelForPunchoutUserId(userId);
        Test.stopTest();
        System.assertnotEquals(null,actualUserModel,'expected actualUserModel should not be null');
    }
    
    
    @isTest
    static void testgetUserModelForPunchoutUserName(){
        
        User testUser = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        
        String userName = 'testUser.Name';
        Test.startTest();
        //ECOM_UserService userService = new ECOM_UserService();
        ECOM_POUserModel actualUserModel = ECOM_UserService.getUserModelForPunchoutUserName(userName);
        Test.stopTest();
        System.assertnotEquals(null,actualUserModel,'expected actualUserModel should not be null');
    }
    
    @isTest
    static void testIsPunchoutUserExists(){
        
        User testUser = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        
        String userName = 'testUser.Name';
        Test.startTest();
        //ECOM_UserService userService = new ECOM_UserService();
        Boolean isUserExists = ECOM_UserService.isPunchoutUserExists(userName);
        Test.stopTest();
        System.assertnotEquals(null,isUserExists,'expected isUserExists should not be null');
    }
    
    @isTest
    static void testGetPunchoutUserForUserName(){
        
        User testUser = [Select Id,LastName, Name From User ORDER BY CREATEDDATE DESC LIMIT 1];
        
        String userName = testUser.Name;
        System.debug('userName'+userName);
        Test.startTest();
        ECOM_UserService userService = new ECOM_UserService();
        User actualUserRecord = ECOM_UserService.getPunchoutUserForUserName(userName);
        Test.stopTest();
        
    }
    
   
    @isTest
    static void testGetPunchoutUserInformationById() {
        // Create a test user
        User testUser = [Select Id,LastName, Name From User ORDER BY CREATEDDATE DESC LIMIT 1];

        // Create a test user ID
        String testUserId = testUser.Id;

        Test.startTest();

        // Call the method to be tested
        ECOM_UserService userService = new ECOM_UserService();
        List<User> result = userService.getPunchoutUserInformationById(testUserId);

        Test.stopTest();

        // Add assertions based on your expected outcomes
        System.assertNotEquals(null, result,'expected isUserExists should not be null');
    
}

   

    @isTest
    static void testInsertNewUserWithDmlOptions() {
         Contact testContact = [Select Id,LastName From Contact ORDER BY CREATEDDATE DESC LIMIT 1];
         Profile pf = [SELECT Id FROM Profile WHERE Name = :ECOM_Constant.PROFILE_NAME LIMIT 1];
        //Profile pf = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
        Integer RandomId = Integer.valueOf(Math.rint(Math.random() * 1000000));
        String uniqueName = orgId + dateString + RandomId;
        String userNickname ='TestRevvity';
        // Create a test user
        User testUser = new User(firstname = 'ABC',
                           lastName = 'XYZ',
                           email = uniqueName + '@test' + orgId + '.org',
                           Username = 'testR1@test.org',
                           EmailEncodingKey = 'ISO-8859-1',
                           Alias = uniqueName.substring(18, 23),
                           TimeZoneSidKey = 'America/Los_Angeles',
                           LocaleSidKey = 'en_US',
                           LanguageLocaleKey = 'en_US',
                           CommunityNickname = userNickname,
                           IsActive = True,
                           ProfileId = pf.Id,
                           ContactId = testContact.Id
                          );

        // Create DMLOptions for the test
        Database.DMLOptions dmlOptions = new Database.DMLOptions();

        Test.startTest();

         ECOM_UserService userService = new ECOM_UserService();
        Boolean result = userService.insertNewUserWithDmlOptions(dmlOptions, testUser);

        Test.stopTest();

        
        System.assertNotEquals(null, result,'expected isUserExists should not be null');

    }



    @isTest
    static void testPreparePunchoutLoginParameters() {
        User testUser = [Select Id,LastName,email,UserName,ContactId From User ORDER BY CREATEDDATE DESC LIMIT 1];//RWPS:1456
        // Create a test request wrapper
        ECOM_PunchoutUserWrapper.Request testWrappedRequest = new ECOM_PunchoutUserWrapper.Request();
         String testJson='{"id":"'+ testUser.Id+'","LastName": "'+testUser.LastName+'","ContactId": "'+testUser.ContactId+'","userName":"'+testUser.UserName+'"}';
        testWrappedRequest.userDataJson = testJson;
        
        Test.startTest();
        //RWPS:1456 START
		List<string> se = new List<string>();
        se.add(testUser.Email);
        //RWPS:1456 END
         ECOM_UserService userService = new ECOM_UserService();
        Map<String, String> result = userService.preparePunchoutLoginParameters(testWrappedRequest);
		//RWPS:1456 START
        userService.getUserByUserName(testUser.UserName);
        ECOM_UserService.checkInternalUsers(se);
        ECOM_UserService.checkCommunityUsers(se);
        userService.getBaseStoreUrl();
        //RWPS:1456 END
        Test.stopTest();

        // Add assertions based on your expected outcomes
        System.assertEquals(testUser.Username, result.get('userName'),'Expected result for punchoutuser');
       
    }

    @isTest
    static void getPunchoutUserInfoForERPAddressMasterTest(){
        Test.startTest();
        new ECOM_UserService().getPunchoutUserInfoForERPAddressMaster('');
        Test.stopTest();
    }
    
    @isTest
    static void getPunchoutAddressModelForUserIdTest(){
        Test.startTest();
        new ECOM_UserService().getPunchoutAddressModelForUserId('');
        Test.stopTest();
    }

   @isTest
    static void checkQuickOrderAllowedForUserTest(){
         Test.startTest();
        ERP_AddressModel addressModel = new ERP_AddressModel();
        addressModel.po_ProductIncludeQuery = 'Test';
        ERP_AddressModel addressModel2 = new ERP_AddressModel();
        new ECOM_UserService().checkQuickOrderAllowedForUser(addressModel, new Map<String,Object>());
        new ECOM_UserService().checkQuickOrderAllowedForUser(addressModel2, new Map<String,Object>());
        new ECOM_UserService().checkQuickOrderAllowedForUser(null, new Map<String,Object>());
        Test.stopTest();
    }
    
    @isTest
    static void getUserNavigationConfigTest(){
        Test.startTest();
        new ECOM_UserService().getUserNavigationConfig('', ECOM_Constant.POTYPE_PUNCHOUT_USER);
        Test.stopTest();
    }
}