/**************************************************************
 * 1. Ticket(s) that relates to this class
 * - ECOM-70
 *
 * 2. Description - it is test class for ECOM_SetPasswordFlowController
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
 * - ECOM_SetPasswordFlowController
 *
 * 6. Test Class Name: N/A
 *
 * 7. Is @Invocable : No
 *
 * 8. Author Name(s): 
 * - Manish Kumar 2023.07.21
 *
*************************************************************/ 
@isTest(SeeAllData=false)
public with sharing class ECOM_SetPasswordFlowController_Test {
  
    /**
    * @description this method is used to create test data.
    * @author Vipul Goyal | 09-20-2023 
    **/
   	@TestSetup
    public static void testData(){
        ECOM_TestUtil.testDataIntialSetup();
    }


    /**
    * @description this method is used to test the coverage of ECOM_SetPasswordFlowService class.
    * @author Vipul Goyal | 09-20-2023 
    **/
    @isTest
    public static void testSetUserPassword(){
       Test.startTest();
       User u = [SELECT Id, Username, Email FROM User WHERE Lastname = 'TestPortal'];
       //To set  the user as a portal user 
       System.runAs(u){
        //Creating input map
           Map<String, Object> inputs = new Map<String, Object>();
		   inputs.put('varUserEmail',u.Email);
           inputs.put('varLocale','en_US');
           inputs.put('varCurrencyCode','USD');
           inputs.put('varCountryCode','US');
           inputs.put('varIsNewUser', false);
           Flow.Interview flw = new Flow.Interview.SUB_FLOW_4491_ECOM_Reset_Password(inputs);
           //flw.start();
           
           //String message = (String) flw.getVariableValue('varMessage');
           //String encryptedToken = (String) flw.getVariableValue('varEncryptedToken');
           //Boolean forgotPasswordSuccess = (Boolean) flw.getVariableValue('varForgotPasswordSuccess');
           
           Map<String, Blob> encryptedTokenMap = ECOM_EncryptUtil.encryptWithManagedIV(u.Email);
		   String encryptedToken = String.valueOf(encryptedTokenMap.get(ECOM_Constant.ENCRYPTED_TOKEN));
           
           u = [SELECT Id, Username, ECOM_Reset_Password_Key__c FROM User WHERE Lastname = 'TestPortal' LIMIT 1];
           
           List<ECOM_SetPasswordFlowWrapper.PasswordRequest> requestList = new List<ECOM_SetPasswordFlowWrapper.PasswordRequest>();
           List<ECOM_SetPasswordFlowWrapper.PasswordResponse> responseList = new List<ECOM_SetPasswordFlowWrapper.PasswordResponse>();
        //Setting ECOM_SetPasswordFlowWrapper
           ECOM_SetPasswordFlowWrapper.PasswordRequest req1 = new ECOM_SetPasswordFlowWrapper.PasswordRequest();
           req1.userName = u.Username;
           req1.userId = u.Id;
           req1.newPassword = 'je8OrRczUat/YVy5wVFf+Q==';//encrypted Password
           req1.token = encryptedToken;
           req1.code = u.ECOM_Reset_Password_Key__c;
           requestList.add(req1);
           responseList = ECOM_SetPasswordFlowController.setUserPassword(requestList);
           System.assertnotEquals(null,req1,'Expectedreq1');
           
           //Setting ECOM_SetPasswordFlowWrapper
           requestList = new List<ECOM_SetPasswordFlowWrapper.PasswordRequest>();
           ECOM_SetPasswordFlowWrapper.PasswordRequest req2 = new ECOM_SetPasswordFlowWrapper.PasswordRequest();
           req2.userName = 'rest12@noemail.com';
           req2.userId = u.Id;
           req2.newPassword = 'je8OrRczUat/YVy5wVFf+Q==';//encrypted Password
           req2.token = encryptedToken;
           req2.code = u.ECOM_Reset_Password_Key__c;
           requestList.add(req2);
           responseList = ECOM_SetPasswordFlowController.setUserPassword(requestList);
           System.assertEquals(responseList[0].success, false);
           
            //Setting ECOM_SetPasswordFlowWrapper
           requestList = new List<ECOM_SetPasswordFlowWrapper.PasswordRequest>();
           ECOM_SetPasswordFlowWrapper.PasswordRequest req3 = new ECOM_SetPasswordFlowWrapper.PasswordRequest();
           req3.userName = u.Username;
           req3.userId = u.Id;
           req3.newPassword = 'je8OrRczUat/YVy5wVFf+Q==';//encrypted Password
           req3.token = encryptedToken;
           req3.code = u.ECOM_Reset_Password_Key__c;
           requestList.add(req3);
           responseList = ECOM_SetPasswordFlowController.setUserPassword(requestList);
           System.assertEquals(responseList[0].success, false);
           
           Test.stopTest();
       }
        }
          @isTest
        private static void test_EncryptUtil()
        {
            String text = 'Revvity Pass';
            User u = [SELECT Id FROM User ORDER BY CREATEDDATE DESC LIMIT 1];
            System.runAs(u)
            {
            	String res = ECOM_EncryptUtil.encryptWithAES256(text);
                //System.AssertNotEquals(null,res,'Result should not be null');
                
            }
        }
    }