/**************************************************************
  * 1. Jira Ticket(s) that relates to this class(BULK_Transfer_Controller)
  *    - ATEAM-1348
  *    - ITSFDC-4871
  *
  * 2. Description -Apex clantroller for BULk Trnasfer Tool.
  * 3. Objects referenced
  *    -C_META_Bulk_Transfer_Configuration__mdt // custom metadata type Bulk_Transfer
  *     User
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None
  *   
  *
  * 5. Dependant Class(es):
  *    - 
  *
  * 6. Test Class Name: BULK_Transfer_Controller_Test
  *
  * 7. Author Name(s): 
  *    - Vishwas Gupta 2021.09.29
  *    - First Last & Updated Date(YYYY.MM.DD)
  *    - First Last & Updated Date(YYYY.MM.DD)
  *
*************************************************************/ 
public class BULK_Transfer_Controller {
 @AuraEnabled(cacheable=true)
    public static list<labelandapi> fetchsobjectname(){
        system.debug('fetchsobjectname');
        list<labelandapi> sobjectnamelist = new list<labelandapi>();
        List<C_META_Bulk_Transfer_Configuration__mdt> mcs =C_META_Bulk_Transfer_Configuration__mdt.getAll().values();
        set<string> ObjectAPIs = new set<string>();
        Map<string,string> objectMapType=new Map<string,string>();
        if(mcs != null && !mcs.isEmpty()){
            for(C_META_Bulk_Transfer_Configuration__mdt CMeta:mcs){
                if(CMeta.Custom_Permission__c !=null && FeatureManagement.checkPermission(CMeta.Custom_Permission__c)){
                   ObjectAPIs.add(CMeta.Object_Api__c.toLowerCase());  
                }
              objectMapType.put(CMeta.Object_Api__c.toLowerCase(),CMeta.MatchedOBC__c !=null ? CMeta.MatchedOBC__c : 'None');
               
            }
        }
       //  system.debug('ObjectAPIs'+ObjectAPIs);
     //  for(Schema.SObjectType objTyp : Schema.getGlobalDescribe().Values()){
     if(!ObjectAPIs.isEmpty()){ 
         map<string,schema.SObjectType> objtypemap=Schema.getGlobalDescribe();
        for(string objstr: ObjectAPIs){
           labelandapi lai = new labelandapi();
           String objname = objtypemap.get(objstr).getDescribe().getName();
           String objlabel = objtypemap.get(objstr).getDescribe().getLabel();
            lai.labelIt=objlabel;
            lai.apiIt=objname;
            lai.typeIt=objectMapType.get(objstr);
            sobjectnamelist.add(lai); 
           }
           
        
        }
        if(sobjectnamelist.size()>0){
            system.debug('sobjectnamelist'+sobjectnamelist);
            return sobjectnamelist;
        }
        else{
            return null;
        }
    }
         @AuraEnabled(cacheable=true)
    public static list<labelandapi> fetchobjectandfld(string varObjName){
       list<labelandapi> listlabNapi;
        try{
             C_META_Bulk_Transfer_Configuration__mdt mcs =[SELECT Id, DeveloperName, MasterLabel, fieldsToDisplay__c, fieldsToFilter__c, QualifiedApiName FROM C_META_Bulk_Transfer_Configuration__mdt Where Object_api__c=:varObjName LIMIT 1];
          //  system.debug('mcs'+mcs);
        set<string> FieldAPIs = new set<string>();
        if(mcs != null && mcs.fieldsToFilter__c != null){
            for(string CMeta:mcs.fieldsToFilter__c.split(',')){
              FieldAPIs.add(CMeta.toLowerCase().trim());  
            }
        }
            system.debug('FieldAPIs='+FieldAPIs);
            if(!FieldAPIs.isEmpty()){
                labelandapi labapi = new labelandapi();
          Map<String,Schema.SObjectField> mfields = Schema.getGlobalDescribe().get(varObjName).getDescribe().fields.getMap();
            if(!mfields.keySet().isEmpty()){
                listlabNapi = new list<labelandapi>();
                for(string str:FieldAPIs){
                    if(str.contains('.')){
                        labelandapi labapifld = new labelandapi();
                        list<string> fdr = str.split('\\.');
                        string objectapi;
                        if(fdr[0].containsIgnoreCase('__r')){
                            objectapi=fdr[0].toLowerCase().replace('__r', '__c'); 
                        }else{
                            objectapi=fdr[0]+'id';
                        }
                        string objstr= string.valueof(mfields.get(objectapi.trim()).getDescribe().getReferenceTo()).remove('(').remove(')');
                        Map<String, Schema.SObjectField> parentfieldMap = Schema.getGlobalDescribe().get(objstr).getDescribe().fields.getMap();
                        Schema.DescribeFieldResult fd =parentfieldMap.get(fdr[1].trim()).getDescribe();
                        labapifld.labelIt=string.valueof(fd.getLabel());
                        labapifld.apiIt=string.valueof(mfields.get(objectapi.trim()).getDescribe().getRelationshipName())+'.'+string.valueof(fd.getName());
                        labapifld.typeIt='REFERENCE';   
                        listlabNapi.add(labapifld);
                        }else{
                    labelandapi labapifld = new labelandapi();
                    labapifld.labelIt =mfields.get(str).getDescribe().getLabel();
                    labapifld.typeIt=string.valueof(mfields.get(str).getDescribe().getType());
                    labapifld.apiIt=str;
                    listlabNapi.add(labapifld);  
                    }
                    
                }
            } 
            }
             
        }
        catch (System.NullPointerException e) {
          return null;
        }
        system.debug('listlabNapi=='+listlabNapi);
      return listlabNapi;
    }

     public class labelandapi{
        @AuraEnabled
        Public string labelIt{get;set;}
        @AuraEnabled
        Public string apiIt{get;set;} 
        @AuraEnabled
        Public string typeIt{get;set;}  
    }
   @AuraEnabled(cacheable=false)
    public static wrapInfo fetchObjectRecords(string objnamest, string limitst,string OwnerIdstr){
        system.debug('objnamest='+objnamest+'limitst='+limitst+'OwnerIdstr='+OwnerIdstr);
        if(objnamest == null){
            return null;
        } 
        string whereString='';
        if(OwnerIdstr != null && OwnerIdstr !=''){
           whereString =' WHERE OwnerId=\''+ OwnerIdstr+ '\''; 
        }
        string limitstr='9999';
        if(limitst != null && limitst !=''){
            limitstr =limitst;
        } 
     wrapInfo wrapIn = new wrapInfo();
     list<fieldProperties> wrpfldList = new list<fieldProperties>();
       List<SObject>  recList = new list<SObject>();
       Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objnamest).getDescribe().fields.getMap();
        String fieldapis=string.join((New List<String>(fieldMap.KeySet())),',').toLowerCase();

       string fieldstring ='id,name';
        system.debug('fieldstring='+fieldstring);
        string fldnamest;
         C_META_Bulk_Transfer_Configuration__mdt mcs =[SELECT Id, DeveloperName, MasterLabel, fieldsToDisplay__c, fieldsToFilter__c, QualifiedApiName FROM C_META_Bulk_Transfer_Configuration__mdt Where Object_api__c=:objnamest LIMIT 1];
        fldnamest=mcs.fieldsToDisplay__c;
        if(fldnamest == null){
            fldnamest=fieldstring;
           }
        string queryfield=fldnamest;
      /*  if(fieldapis.containsIgnoreCase('Owned_By_company__c') && !fldnamest.containsIgnoreCase('Owned_By_company__c')){
            queryfield =queryfield + ' ,Owned_By_company__c ';
        } */
         if(fieldapis.containsIgnoreCase('GROW_Employee_Email__c') && !fldnamest.containsIgnoreCase('GROW_Employee_Email__c')){
            queryfield =queryfield + ' ,GROW_Employee_Email__c ';
        }
        system.debug('queryfield=='+queryfield);
       Boolean hasPermission = FeatureManagement.checkPermission('C_PERM_9610_Bulk_Transfer_Reassign_as_Any_User');
        string querystring;
        if(hasPermission){
           querystring ='select '+ queryfield+' from '+objnamest + whereString + ' Order by LASTMODIFIEDDATE DESC limit ' + limitstr ; 
        }else if(whereString !=''){
              querystring ='select '+ queryfield+' from '+objnamest + whereString + ' Order by LASTMODIFIEDDATE DESC limit ' + limitstr ; 
        }
        if(querystring != null){
           recList =Database.query(querystring);  
        }
     
       if(recList != null && recList.size()>0){
           wrapIn.SObjectRecords =recList;
       }

      list<String> fieldlist =  fldnamest.split(',');
       for(string str: fieldlist){
           if(str != null && str != ''){

            fieldProperties fldwrp = new fieldProperties();
            if(str.contains('.')){
                list<string> fdr = str.split('\\.');
                string objectapi; if(fdr[0].containsIgnoreCase('__r')){
                   objectapi=fdr[0].toLowerCase().replace('__r', '__c'); 
                }else{
                    objectapi=fdr[0]+'id';
                }
                system.debug('objectapi=='+objectapi);
               string objstr= string.valueof(fieldMap.get(objectapi.trim()).getDescribe().getReferenceTo()).remove('(').remove(')');
          Map<String, Schema.SObjectField> parentfieldMap = Schema.getGlobalDescribe().get(objstr).getDescribe().fields.getMap();
            Schema.DescribeFieldResult fd =parentfieldMap.get(fdr[1].trim()).getDescribe();
                fldwrp.fldlab=string.valueof(fd.getLabel());
               fldwrp.fldapi=string.valueof(fieldMap.get(objectapi.trim()).getDescribe().getRelationshipName())+'.'+string.valueof(fd.getName());
               fldwrp.fldtype='REFERENCE';   
            wrpfldList.add(fldwrp);

            }
            else{
                Schema.DescribeFieldResult fd =fieldMap.get(str.trim()).getDescribe();
           string fapi = string.valueof(fd.getName());
           fldwrp.fldapi=fapi;
           fldwrp.fldlab=string.valueof(fd.getLabel());
           fldwrp.fldtype=string.valueof(fd.gettype());
                wrpfldList.add(fldwrp); 
            }
               
           }
        }

       wrapIn.fldpropertieslist=wrpfldList;
        return wrapIn;
    }


    Public class wrapInfo{
        @AuraEnabled
        Public list<fieldProperties> fldpropertieslist{get;set;}
        @AuraEnabled
        Public list<SObject> SObjectRecords{get;set;}  
    }
    Public class fieldProperties{
        @AuraEnabled
        Public string fldlab{get;set;}
        @AuraEnabled
        Public string fldapi{get;set;}
        @AuraEnabled
        Public string fldtype{get;set;}
    } 
    @AuraEnabled(cacheable=true)
    public static List<sObject> fetchuserinfo(){
        list<sObject> userList = new list<sObject>();
        // Commneting because of Revvity Migaration
      /*  Boolean hasPermission = FeatureManagement.checkPermission('C_PERM_9610_Bulk_Transfer_Reassign_as_Any_User');
        if(hasPermission){
          String stringQuery =  'SELECT id, Name,UserName,isActive,Owned_By_Company__c FROM user WHERE License_type__c  IN (\'Salesforce Platform\',\'Salesforce\')  ORDER BY Name DESC';
        userList = Database.query(stringQuery);  
        }else{
           String OBC = [Select Owned_By_Company__c From User Where Id = :UserInfo.getUserId()][0].Owned_By_Company__c;   
            String stringQuery =  'SELECT id, Name,UserName,isActive,Owned_By_Company__c FROM user WHERE License_type__c  IN (\'Salesforce Platform\',\'Salesforce\') AND Owned_By_Company__c=:OBC  ORDER BY Name DESC';

            userList = Database.query(stringQuery); 
             }
         */
         String stringQuery =  'SELECT id, Name,UserName,isActive FROM user WHERE License_type__c  IN (\'Salesforce Platform\',\'Salesforce\')  ORDER BY Name DESC';
        userList = Database.query(stringQuery);  
       // system.debug('userList'+userList);
        return userList;
        
    }
        @AuraEnabled(cacheable=true)
    public static List<groupReturn> fetchgroupinfo(string sobjectname){
        system.debug('child methiod');
        list<groupReturn> groupReturnList = new list<groupReturn>();
        // commenting due to revvity migration
     /*   Boolean hasPermission = FeatureManagement.checkPermission('C_PERM_9610_Bulk_Transfer_Reassign_as_Any_User');
       List<PKI_queue__c> pkiqu=new List<PKI_queue__c>();
            set<string> nativeIds=New set<string>();
        if(hasPermission){
                     pkiqu=[SELECT Id, Owned_By_Company__c, Email__c, NativeQueueID__c FROM PKI_Queue__c Where NativeQueueID__c != null AND Type__c='Queue'];

        }else{
            String OBC = [Select Owned_By_Company__c From User Where Id = :UserInfo.getUserId()][0].Owned_By_Company__c;
           pkiqu=[SELECT Id, Owned_By_Company__c, Email__c, NativeQueueID__c FROM PKI_Queue__c Where NativeQueueID__c != null AND Type__c='Queue' AND Owned_By_Company__c=:OBC];

             }
         
        Map<string,string> queueIdOBC= new Map<string,string>();
        for(PKI_queue__c pQ:pkiqu){
            nativeIds.add(pQ.NativeQueueID__c);
            queueIdOBC.put(pQ.NativeQueueID__c,pQ.Owned_By_Company__c);
        }
       List<group> groupList =  [select id,name from Group where type='Queue' AND Id IN:nativeIds AND ID IN (Select QueueId from QueueSobject Where SobjectType=:sobjectName)];
       */
        // remove from here this is just for testing in sandbox
       List<group> groupList =  [select id,name from Group where type='Queue'  AND ID IN (Select QueueId from QueueSobject Where SobjectType=:sobjectName)];
        for(group grp:groupList){
            groupReturn grprt= new groupReturn();    
            grprt.Id=grp.Id; 
            grprt.Name=grp.name;
           /* if(string.valueof(grp.name).containsIgnoreCase('AES')){
                grprt.Owned_By_Company='AES';
            }else if(string.valueof(grp.name).containsIgnoreCase('LSDX')){
                grprt.Owned_By_Company='LSDX';
            }else{
                grprt.Owned_By_Company='TBD';
            }*/
                   // remove till here this is just for testing in sandbox
             // grprt.Owned_By_Company=queueIdOBC.get(grp.Id) != null ? queueIdOBC.get(grp.Id) :'TBD'; 
            groupReturnList.add(grprt);
        }
        system.debug('groupReturnList'+groupReturnList);
        return groupReturnList;
        
    }
   //  @AuraEnabled(cacheable=false)
    Public static SFDC_LOG__c createSFDCLog(string sobjectname,string fromuser,string touser,string selectedrec,string totalrecords,string wherestr){
       system.debug('createSFDCLog wherestr'+wherestr);
        SFDC_LOG__c sfdclog = new SFDC_LOG__c();
        string whstring='';
        if(wherestr != null && wherestr != ''){
            whstring=' on Filter:Where '+ wherestr;
        }
         sfdclog.Message_Long__c ='From: '+fromuser+' To: '+touser+' Records: '+selectedrec+' of '+ totalrecords + whstring;
         sfdclog.Running_User__c=userinfo.getUserName();
        sfdclog.Source_Name__c ='Bulk Transfer Tool';
        sfdclog.Source_Step__c ='Search('+sobjectname+')';
        sfdclog.Source_Type__c='LWC';
        sfdclog.Log_Type__c ='Log';
      try{
            system.debug('sfdclog==='+sfdclog);
          insert sfdclog;  
        }catch(exception ex){
            system.debug('ex'+ex.getCause());
        } 
        return sfdclog;
      }
    @AuraEnabled(cacheable=false)
    Public static UpdateReturn UpdateRecords(list<Sobject> sobjectLst,string Owneridstring,string sobjectname,string fromuser,string touser,string selectedrec,string totalrecords,string wherestr){
       
         system.debug('sobjectLst'+sobjectLst);
        boolean b=false;
        UpdateReturn ret= new UpdateReturn();
        list<sobject> sobjlist = new list<sobject>();
        if(sobjectLst != null && Owneridstring != null){
            for(sobject obj:sobjectLst){
                obj.put('OwnerId',Owneridstring);
                sobjlist.add(obj);
            }
           
        }
        try{
           // Update sobjlist;
           Database.SaveResult[] srList = Database.update(sobjlist, false);
            integer intsuccess=0;
            integer interror=0;
            string errorIds='Error Ids: ';
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    intsuccess=intsuccess+1;
                }else{
                    interror=interror+1;
                    errorIds +=sr.getId()+',' ;
                }
            }
            List<SFDC_LOG__c> sfdcloglist = new List<SFDC_LOG__c>();
            if(intsuccess !=0){
                sfdcloglist.add(BULK_Transfer_Controller.createSFDCLog(sobjectname,fromuser,touser,string.valueof(intsuccess),totalrecords,wherestr));
           ret.successRec=string.valueof(intsuccess);
            }
            if(interror !=0){
                sfdcloglist.add(BULK_Transfer_Controller.createSFDCLog(sobjectname,fromuser,touser,string.valueof(interror),totalrecords,errorIds));
            ret.errorRec=string.valueof(interror);
            }
             ret.isSuc=true;
            if(!sfdcloglist.isEmpty()){
                try{
                    Insert sfdcloglist;
                }catch(exception ex){
                    system.debug('ex'+ex.getCause());
                }
            }
                }catch(exception ex){
                    system.debug('ex'+ex.getCause());
                     system.debug('ex getMessage'+ex.getMessage());
                   ret.isSuc=false;
                }
        return ret;
    }

    Public class UpdateReturn{
        @AuraEnabled
        Public string successRec{get;set;}
        @AuraEnabled
        Public string errorRec{get;set;}
        @AuraEnabled
        Public boolean isSuc{get;set;}
    }
        Public class groupReturn{
        @AuraEnabled
        Public string Id{get;set;}
        @AuraEnabled
        Public string Name{get;set;}
        @AuraEnabled
        Public string Owned_By_Company{get;set;}
    }
}