/**************************************************************
* 1. Jira Ticket(s)
*    - OM-256 automated Sandbox Refresh Scheduler
*
* 2. Description - This apex class is used to automated Sandbox Refresh Scheduler
*
* 3. Objects referenced
*    -C_META_Sandbox_Refresh_Scheduler__mdt
*
* 4. Callouts to additional Components (including their methods) or None:
*    
* 5. Dependant Class(es):
*    - SandboxRefreshScheduler
*    
*
* 6. Test Class Name: SandboxRefreshCalloutTest
* 
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s): 
*    - Avinash Kumar/Sumit Kumar Sourav (PWC) & Created Date(02/06/2024)
*    -
*    -
*************************************************************/ 
public class SandboxRefreshCallout {
    
    public Class SandboxDetails{
        public String SandboxName{get;set;}
        public String LicenseType{get;set;}        
        public string SourceId {get;set;}
        public string ApexClassId {get;set;}
        public string AutoActivate {get;set;}
        public string SbxDescription {get;set;}
        
        public string Id {get;set;}
    }
    
    public Class SandboxDetailsRes{
        public String message{get;set;}
        public String status{get;set;}        
        public List<SandboxDetails> records {get;set;}
    }
    
    @future(callout=true)
    
    public static void getSandboxDetails(string  uiwraprstr){
        
        If(uiwraprstr !=null){
            SandboxRefreshFlowCallout.userInputWrapper uiwrapr = (SandboxRefreshFlowCallout.userInputWrapper)JSON.deserialize(uiwraprstr, SandboxRefreshFlowCallout.userInputWrapper.class);
            string operation= uiwrapr.action.toUpperCase();
            // Get the base URL.
            String sfdcBaseURL = URL.getOrgDomainURL().toExternalForm();
            System.debug('Base URL: ' + sfdcBaseURL ); 
            HttpRequest req = new HttpRequest();
            req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
            req.setHeader('Content-Type', 'application/json');
            //req.setEndpoint('https://revvity.my.salesforce.com/services/data/v58.0/tooling/query/?q=+Select+id,SandboxName+from+SandboxInfo');
            req.setEndpoint(sfdcBaseURL+'/services/data/v58.0/tooling/query/?q=+Select+id,SandboxName+from+SandboxInfo');
            req.setMethod('GET');
            Http h = new Http();
            HttpResponse res = h.send(req);
            system.debug(res.getBody());
            SandboxDetailsRes deserializedSBXData = (SandboxDetailsRes)JSON.deserialize(res.getBody(), SandboxDetailsRes.class);
            system.debug('==deserializedSBXData '+deserializedSBXData);
            // Iterate over the data
            for(SandboxDetails sbxdata: deserializedSBXData.records) { 
                String str= sbxdata.SandboxName.toUpperCase();
                uiwrapr.SbxNameIdMap.put(str,sbxdata.Id);
                uiwrapr.SbxIdNameMap.put(sbxdata.Id,str);
            }
            String wrprsbxname=uiwrapr.sbxName.toUpperCase();
            system.debug('!!operation '+operation);
            system.debug('!!Contains SBX Name '+uiwrapr.SbxNameIdMap.KeySet().contains(wrprsbxname));
            if (/*operation == 'NEW' ||*/ !(uiwrapr.SbxNameIdMap.KeySet().contains(wrprsbxname))){
                system.debug('Inside New IF');
                PostSandboxDetails(uiwrapr);
            }else if(operation == 'DELETE' && uiwrapr.SbxNameIdMap.KeySet().contains(wrprsbxname)){
                system.debug('Inside Delete IF');
                DeleteSandboxDetails(uiwrapr);
            }else if(/*operation == 'REFRESH' ||*/ uiwrapr.SbxNameIdMap.KeySet().contains(wrprsbxname)){
                system.debug('Inside Refresh IF');
                PatchSandboxDetails(uiwrapr);
            }
            
        }
    }
    
    public static void PostSandboxDetails(SandboxRefreshFlowCallout.userInputWrapper uiwrapr2){
        
        If(uiwrapr2!=null){
            String str2=uiwrapr2.sbxName.toUpperCase();
            // Get the base URL.
            String sfdcBaseURL = URL.getOrgDomainURL().toExternalForm();
            System.debug('Base URL: ' + sfdcBaseURL ); 
            String reqBody = '{"SandboxName":'+'"'+uiwrapr2.sbxName+'"'+',"LicenseType":'+'"'+uiwrapr2.LicenseType+'"'+',"Description" :'+'"'+uiwrapr2.SbxDescription+'"'+',"AutoActivate" :'+'"'+uiwrapr2.sbxAutoactivate+'"'+',"ApexClassId":'+'"'+uiwrapr2.sbxApexClassId+'"'+'}';//JSON.serialize(Sbxdetl);
            System.debug('==reqBody@@@@ ' + reqBody);
            HttpRequest req = new HttpRequest();
            req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
            req.setHeader('Content-Type', 'application/json');
            //req.setEndpoint('callout:Mass_Action/services/data/v59.0/sobjects/Account');
            //req.setEndpoint('https://revvity.my.salesforce.com/services/data/v58.0/tooling/query/?q=+Select+id,SandboxName+from+SandboxInfo');
            req.setEndpoint(sfdcBaseURL+'/services/data/v58.0/tooling/sobjects/SandboxInfo');
            req.setMethod('POST');
            req.setbody(reqBody);
            Http h = new Http();
            HttpResponse res = h.send(req);
            system.debug('==Post res.getBody() '+res.getBody());
            SandboxDetailsRes deserializedsbxDatas = (SandboxDetailsRes)JSON.deserialize(res.getBody(), SandboxDetailsRes.class);
            system.debug('==Post deserializedsbxDatas '+deserializedsbxDatas);
        }
    }
    
    public static void PatchSandboxDetails(SandboxRefreshFlowCallout.userInputWrapper uiwrapr3){
        
        If(uiwrapr3!=null){
            String str2=uiwrapr3.sbxName.toUpperCase();
            // Get the base URL.
            String sfdcBaseURL = URL.getOrgDomainURL().toExternalForm();
            System.debug('Base URL: ' + sfdcBaseURL ); 
            if(uiwrapr3.SbxNameIdMap.KeySet().contains(str2)){
                String reqBody = '{"AutoActivate":true,"LicenseType":'+'"'+uiwrapr3.LicenseType+'"'+',"ApexClassId":'+'"'+uiwrapr3.sbxApexClassId+'"'+',"Description" :'+'"'+uiwrapr3.SbxDescription+'"'+',"SandboxName":'+'"'+uiwrapr3.sbxName+'"'+'}';//JSON.serialize(Sbxdetl);
                System.debug('==reqBody@@@@ ' + reqBody);
                If(uiwrapr3.SbxNameIdMap.get(str2) !=null){
                    String sbxId=uiwrapr3.SbxNameIdMap.get(str2);
                    HttpRequest req = new HttpRequest();
                    req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
                    req.setHeader('Content-Type', 'application/json');
                    req.setEndpoint(sfdcBaseURL+'/services/data/v58.0/tooling/sobjects/SandboxInfo/'+sbxId);
                    req.setMethod('PATCH');
                    req.setbody(reqBody);
                    Http h = new Http();
                    HttpResponse res = h.send(req);
                    system.debug('==patch res.getBody() '+res.getBody());
                    SandboxDetailsRes deserializedsbxDatas = (SandboxDetailsRes)JSON.deserialize(res.getBody(), SandboxDetailsRes.class);
                }
                
            }   
        }
        
    }
    
    public static void DeleteSandboxDetails(SandboxRefreshFlowCallout.userInputWrapper uiwrapr4){
        
        If(uiwrapr4!=null){
            String str2=uiwrapr4.sbxName.toUpperCase();
            // Get the base URL.
            String sfdcBaseURL = URL.getOrgDomainURL().toExternalForm();
            System.debug('Base URL: ' + sfdcBaseURL ); 
            if(uiwrapr4.SbxNameIdMap.KeySet().contains(str2)){
                //String reqBody = '{"AutoActivate":true}';//JSON.serialize(Sbxdetl);
                //System.debug('==reqBody@@@@ ' + reqBody);
                If(uiwrapr4.SbxNameIdMap.get(str2) !=null){
                    String sbxId=uiwrapr4.SbxNameIdMap.get(str2);
                    HttpRequest req = new HttpRequest();
                    req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
                    req.setHeader('Content-Type', 'application/json');
                    req.setEndpoint(sfdcBaseURL+'/services/data/v58.0/tooling/sobjects/SandboxInfo/'+sbxId);
                    req.setMethod('DELETE');
                    //req.setbody(reqBody);
                    Http h = new Http();
                    HttpResponse res = h.send(req);
                    system.debug('==patch res.getBody() '+res.getBody());
                    SandboxDetailsRes deserializedsbxDatas = (SandboxDetailsRes)JSON.deserialize(res.getBody(), SandboxDetailsRes.class);
                } 
                
            }   
        }
        
    }
}