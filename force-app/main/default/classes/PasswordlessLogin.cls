public without sharing class PasswordlessLogin {
    @AuraEnabled(Cacheable=true)
    public static String initiateLogin(String identifier, String authorizationMethod){
        try{
            List<User> userList = new List<User>();
            String response;
            if(identifier != null) {
                if(authorizationMethod == 'Email') {
                    userList = [SELECT Id , Name , Email , HasUserVerifiedPhone , HasUserVerifiedEmail FROM USER WHERE Email=:identifier LIMIT 1];
                    if(userList.isEmpty() == false && userList[0].HasUserVerifiedEmail == TRUE) {
                        response = UserManagement.initPasswordlessLogin(userList[0].Id, Auth.VerificationMethod.Email);
                        return response;
                    } else if (userList.isEmpty() == false && userList[0].HasUserVerifiedEmail == FALSE) {
                        Boolean sendEmail = UserManagement.sendAsyncEmailConfirmation(userList[0].Id, '00XO900000J5T3FMAV', '0DBHs000000Ckk5OAC', 'https://secure.sandbox.revvity.com/login?ptcms=true');
                        return 'Email Sent for verification, please click on link to verify your email address';
                    } else {
                        response = 'Email not registered / User does not exist';
                    }
                } else if(authorizationMethod == 'SMS') {
                    String formatNum = System.UserManagement.formatPhoneNumber('+91', identifier);
                    userList = [SELECT Id , Name , Email , MobilePhone,  HasUserVerifiedPhone , HasUserVerifiedEmail FROM USER WHERE MobilePhone =:formatNum LIMIT 1];
                    if(userList.isEmpty() == false && userList[0].HasUserVerifiedPhone == TRUE) {
                        response = UserManagement.initPasswordlessLogin(userList[0].Id, Auth.VerificationMethod.SMS);
                        return response;
                    } else if(userList.isEmpty() == false && userList[0].HasUserVerifiedPhone == FALSE) {
                        response = 'Phone not verified';
                    } else {
                        response = 'Phone not registered / User does not exist';
                    }
                }
            }
            return response;
        } catch(Exception e) {
            return 'Error ' + e.getMessage();
        }
    }

    @AuraEnabled(Cacheable=false)
    public static String verifyPasswordlessLogin(String identifier , String otp, String authorizationMethod , String token){
        try{
            Auth.VerificationResult authResponse;
            User userRecord;
            List<User> userList = new List<User>();
            //List<User> userList = new List<User>();
            System.PageReference pageRef ;
            String response;
            if(token != null) {
                if(authorizationMethod == 'Email') {
                    userList = [SELECT Id , Name , Email , HasUserVerifiedPhone , HasUserVerifiedEmail, ContactId, ECOM_Is_Punchout_User__c FROM USER WHERE Email=:identifier LIMIT 1];
                    if(userList.isEmpty() == false) {
                        userRecord = userList[0];
                    } else {
                        return 'Email not registered / User does not exist';
                    }
                    authResponse = UserManagement.verifyPasswordlessLogin(userRecord.Id, Auth.VerificationMethod.EMAIL, token, otp, '/');
                    if (authResponse.success == TRUE && authResponse.redirect != null) {
                        if (userRecord.ECOM_Is_Punchout_User__c == TRUE && userRecord.ContactId != null) {
                            update new Contact(
                                Id = userRecord.ContactId,
                                ECOM_Punchout_Via_Web__c = true,
                                ECOM_Punchout_Cart_Reset__c = false
                            );
                        }
                        pageRef = authResponse.redirect;
                        return pageRef.getUrl();
                    } else {
                        response = authResponse.message;
                        return 'Error: ' + authResponse.message;
                    }
                } else if(authorizationMethod == 'SMS') {
                    userList = [SELECT Id , Name , Email , MobilePhone,  HasUserVerifiedPhone , HasUserVerifiedEmail FROM USER WHERE MobilePhone =:identifier LIMIT 1];
                    if(userList.isEmpty() == false) {
                        userRecord = userList[0];
                    } else {
                        return 'Mobile number not registered / User does not exist';
                    }
                    authResponse = UserManagement.verifyPasswordlessLogin(userRecord.Id, Auth.VerificationMethod.SMS, token, otp, '/');
                    if (authResponse.success == TRUE && authResponse.redirect != null) {
                        pageRef = authResponse.redirect;
                        return pageRef.getUrl();
                    } else {
                        response = authResponse.message;
                        return 'Error: ' + authResponse.message;
                    }
                }
            }
            return response;
        } catch(Exception e) {
            return 'Error '+ e.getMessage();
        }
    }

    @AuraEnabled
    public static String loginAsUserAndRedirect(String userEmail, Boolean sendEmail) {
        Auth.JWT jwt = new Auth.JWT();
        List<User> userList = [SELECT Id, Name, Username, Email, ECOM_Is_Punchout_User__c, ContactId FROM USER WHERE Email=:userEmail LIMIT 1];
        System.debug('User List :: ' + userList);
        String jwtToken;
        String loginURL = '';
        if (userList.isEmpty() == false) {
            jwt.setSub(userList[0].Username);
            jwt.setAud('https://secure.sandbox.revvity.com'); // IMPORTANT
            jwt.setIss('3MVG9snQZy6aQDh0gPFG8E121kO_4IC84KZk0bxXUyiWS5Mhqjl.GdLB3V8auWOq0y_WXeFdKrj3aYPwzhP4F');
            jwt.setValidityLength(360);
            Auth.JWS jws = new Auth.JWS(jwt.toJSONString(), 'Magic_Link_Authentication');
            jwtToken = jws.getCompactSerialization();
            System.debug('TOKEN-->'+jwtToken);
        } else {
            return 'User/Email not found. Please perform registeration';
        }
        if (String.isNotBlank(jwtToken)) {
            String accessToken = '';
            String tokenEndpoint =  'https://secure.sandbox.revvity.com' + '/services/oauth2/token';

            String payload = 'grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=' + jwtToken;
            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setEndpoint(tokenEndpoint);
            req.setHeader('Content-type', 'application/x-www-form-urlencoded');
            req.setBody(payload);
            Http http = new Http();
            HTTPResponse res = http.send(req);

            // get said access token from the response
            System.debug('Response Status: ' + res.getStatusCode());
            System.debug('Response Body: ' + res.getBody());
            if ( res.getStatusCode() == 200 ) {
                System.JSONParser parser = System.JSON.createParser(res.getBody());
                while (parser.nextToken() != null) {
                    if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'access_token')) {
                        parser.nextToken();
                        accessToken = parser.getText();
                        break;
                    }
                }
            }
            // present the access token to frontdoor to get a session
            if (String.isNotBlank(accessToken)) {
                System.debug('Access Token -->!' + accessToken);
                loginURL = 'https://secure.sandbox.revvity.com/vforcesite/secur/frontdoor.jsp?sid=' + EncodingUtil.urlEncode(accessToken,'UTF-8') + '&retURL=' + EncodingUtil.urlEncode('/dashboard?ptcms=true','UTF-8');

                if (userList.isEmpty() == false && userList[0].ECOM_Is_Punchout_User__c == TRUE && userList[0].ContactId != null) {
                    update new Contact(
                        Id = userList[0].ContactId,
                        ECOM_Punchout_Via_Web__c = true,
                        ECOM_Punchout_Cart_Reset__c = false
                    );
                }
            }

            System.debug('Final loginURL URL: ' +loginURL);
            if (sendEmail == false) {
                return loginURL;
            } else {
                try {
                List<EmailTemplate> emailTemplateList = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'MagicLinkTemplate' LIMIT 1];
                Messaging.SingleEmailMessage renderedEmail = Messaging.renderStoredEmailTemplate(emailTemplateList[0].Id, userList[0].Id, null);
                String finalHtmlBody = renderedEmail.getHtmlBody().replace('[[LOGIN_URL]]', loginURL);
    
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTargetObjectId(userList[0].Id);
                mail.setHtmlBody(finalHtmlBody);
                mail.setSubject(renderedEmail.getSubject());
                mail.setSaveAsActivity(false);

                List<OrgWideEmailAddress> orgWideEmailAddressList = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :System.Label.ECOM_OrgWideEmail LIMIT 1];
                if (orgWideEmailAddressList.isEmpty() == false) {
                    mail.setOrgWideEmailAddressId(orgWideEmailAddressList[0].Id);
                }

                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
                return 'Email Sent for verification, please click on link received in the email to login.';
                } catch (Exception e) {
                    System.debug('Email Error: ' + e.getMessage());
                    System.debug('Stack Trace: ' + e.getStackTraceString());
                    return 'Error sending email: ' + e.getMessage();
                }
            }
        } else {
            return 'Something went wrong';
        }
    }

    @AuraEnabled
    public static String processMagicLink(String jwt, String retURL) {
        try {
           String tokenEndpoint = Site.getBaseSecureUrl() + '/services/oauth2/token';

            String encodedJwt = EncodingUtil.urlEncode(jwt, 'UTF-8');

            String payload =
                'grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer'
                + '&assertion=' + encodedJwt;

            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setEndpoint(tokenEndpoint);
            req.setHeader('Content-type', 'application/x-www-form-urlencoded');
            req.setBody(payload);

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() != 200) {
                System.debug('OAuth Error: ' + res.getBody());
                throw new AuraHandledException('Invalid or Expired Magic Link');
            }

            Map<String, Object> response =
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

            String accessToken = (String) response.get('access_token');

            String safeRetUrl =
                EncodingUtil.urlEncode(retURL, 'UTF-8');

            return Site.getBaseSecureUrl()
                + '/secur/frontdoor.jsp?sid=' + accessToken
                + '&retURL=' + safeRetUrl;
        } catch (Exception e) {
            throw new AuraHandledException('Error processing magic link: ' + e.getMessage());
        }

    }
}