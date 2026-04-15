global class Ecom_CsrController {
    
    public static PageReference csrLogin(){
        Map<String, String> params = ApexPages.currentPage().getParameters();
        String contactId = fetchValueForProperty(params, 'contactId');
		String csrId = fetchValueForProperty(params, 'csrId');
        String baseUrl = fetchValueForProperty(params, 'baseUrl');
        System.debug('Params : ContactId : '+contactId+' CSRID : '+csrId);
        List<User> users = [SELECT Id,Name,Email FROM User Where ContactId=:contactId LIMIT 1];
		String networkId = '';
        String suLoginUrl = baseUrl+'/servlet/servlet.su?';
        DomainSite siteDomain= Test.isRunningTest() ? [SELECT Id, Domain.domain, Site.Name, PathPrefix, CreatedDate FROM DomainSite Where Site.Name = :System.Label.ECOM_SiteName  LIMIT 1]:  ECOM_CustomLoginController.fetchBaseSiteURL(System.Label.ECOM_SiteName);
        String storeLoginBaseUrl = System.Label.ECOM_HTTPS_Prefix  + siteDomain.Domain.domain + siteDomain.PathPrefix +'/createsession?potype=cmsStoreUser&';
        String orgId = UserInfo.getOrganizationId();
        String sunetworkid = '';
        List<NetworkMember>  networkMembers = [SELECT Id, NetworkId, MemberId, DigestFrequency FROM NetworkMember where MemberId=:users[0].Id];
        if(!Test.isRunningTest()){
        	sunetworkid = networkMembers[0].NetworkId;
        }
        String sunetworkuserid = users[0].Id;
		String loginUrl = suLoginUrl+'oid='+orgId+'&retURL=createsession?potype=cmsStoreUser&'+contactId+'&sunetworkid='+sunetworkid+'+&sunetworkuserid='+sunetworkuserid;
        Cookie isCSRCk = new Cookie('IsCSR' , 'true', null , 1800000, true, 'Lax');
        Cookie csrIdCk = new Cookie('csrId' , csrId, null , 1800000, true, 'Lax');
        ApexPages.currentPage().setCookies(new Cookie[]{isCSRCk});  
        ApexPages.currentPage().setCookies(new Cookie[]{csrIdCk});  
		String urlParameters='';
        urlParameters = ECOM_Constant.PARAM_EXT_USER_ID + '=' + users[0].Id;
        urlParameters = urlParameters + '&' + ECOM_Constant.PARAM_EXT_EMAIL_ID + '=' + users[0].Email;
        urlParameters = urlParameters + '&' + ECOM_Constant.PARAM_EXT_SESSION_STARTED_TIMESTAMP + '=' + String.valueOf(DateTime.now().getTime());
        urlParameters = urlParameters + '&' + ECOM_Constant.PARAM_EXT_IF_SESSION_STARTED_FLAG + '=' + String.valueOf(1);

        Cookie ck = new Cookie(System.Label.ECOM_CookieName , urlParameters, null , 1800000, true, 'Lax');
        if(!Test.isRunningTest()){ 
            ApexPages.currentPage().setCookies(new Cookie[]{ck});   
        }   
        PageReference reference=new PageReference(loginUrl);
        reference.setRedirect(true);
        return reference;
    }
    
    private static String fetchValueForProperty(Map<String,String> propertyMap, String key){
        String value = '';
        if(propertyMap.containsKey(key) && propertyMap.get(key) != null){
            value = propertyMap.get(key).unescapeHtml4();
        }
        return value;
    }
    
    @AuraEnabled
    public static String getCSRUrl(String csrId){
        String cmsParameters = '';
        String urlParameters = '';
        try{
            //build url parameters to pass to cms
            cmsParameters = ECOM_Constant.PARAM_EXT_USER_ID + '=' + UserInfo.getUserId();
            cmsParameters = cmsParameters + '&' + ECOM_Constant.PARAM_EXT_EMAIL_ID + '=' +UserInfo.getUserEmail();
            cmsParameters = cmsParameters + '&' + ECOM_Constant.PARAM_EXT_SESSION_STARTED_TIMESTAMP + '=' + String.valueOf(DateTime.now().getTime());
            cmsParameters = cmsParameters + '&' + ECOM_Constant.PARAM_EXT_IF_SESSION_STARTED_FLAG + '=' + String.valueOf(1);
            cmsParameters = cmsParameters + '&IsCSRFlow=true';
        	cmsParameters = cmsParameters + '&csrId=' + csrId;
            urlParameters = ECOM_Constant.PARAM_EXT_CMS_URL_PARAMETER+'=' +  EncodingUtil.urlEncode(ECOM_CustomLoginController.encryptWithAES256(cmsParameters), 'UTF-8');
        }catch(Exception e){
            System.debug(e.getStackTraceString());
        }
        return urlParameters;
    }
   
}