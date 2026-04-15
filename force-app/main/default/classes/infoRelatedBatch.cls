public class infoRelatedBatch  implements Database.Batchable<sObject>{
/*
//Step 3: For each resulting Attribute+Type+CAL record, query if a INFO_RELATED CAL+Type+Attribute exits (Specifically do not check Value/Central)

Step 3A: Skip any CAL+Type+Attrribute that exists already..go to Step 4

Step 3B: For each CAL+Type+Attribute that does not exists, then
check if the value exists in  INFO_CENTRAL

step 3b.1: If record does exist - do not insert to Central, but do retrieve RecordToUse__c value

step 3b.2: If record does NOT exist, INSERT into CENTRAL (Type+apiInputValue) and retreive the RecordToUse__c value for that record
(this is because the record-trigger automation that defines duplicates will determine the exact record to use)


Step 5: Loop to next Batch and repeat
*/
   public final String Query;
   public final String fieldapi; 
 
   public infoRelatedBatch(String q,string f){
     Query=q; fieldapi =f;
   }
   
 //Step 1: Get Records for CAL for a single TYPE (Phone/Emial/Address)
 // start query after passing paramters('query string', comma seperated field apis)
   public Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator(query);
   }
 
   public void execute(Database.BatchableContext BC, List<sObject> scope){
       list<string> fldapi = new list<string>();
       // map of field value with list of record id 
       map<string,string> valueMapRelated = new map<string,string>();
       map<string,string> keyMapRelatedalready = new map<string,string>();
       map<string,string> keyMapRelatedalready2 = new map<string,string>();
       map<string,set<string>> valueMapattribute = new map<string,set<string>>();
       map<string,string> mapkeyinfoId = new map<string,string>();
       // map of type with list of vlues in that type 
       map<string,set<string>> typeMapValue = new map<string,set<string>>(); // used to filter query based on type for Info_Central__c other than address
       map<string,string> keyMapValue = new map<string,string>();
       map<string,set<string>> typeAddressMapValue = new map<string,set<string>>(); // used to filter query based on type for Info_Central__c for Address
       map<string,map<string,string>> keyMapValueAddress = new map<string,map<string,string>>();
       string addressattribute;
       if(fieldapi != null){
          fldapi= fieldapi.split(',');  // convert comma seperated field api to list<string> 
       }
     //  system.debug('fldapi'+fldapi+scope);
     for(sObject sobj: scope){
              if(!fldapi.isEmpty()){
                   for(string st:fldapi){
                       if(sobj.get(st.trim()) != null ){
                        
                               // other logic to prepare different set of value to check with IN clause for Info_central query
                           string strtype ;
                           string attributestring;
                           if(st.trim().containsIgnoreCase('Phone') || st.trim().containsIgnoreCase('fax')){
                                  strtype ='Phone';    
                           }
                           if(st.trim().containsIgnoreCase('Email')){
                                 strtype ='Email';
                           }
                          if(st.trim().containsIgnoreCase('city') ||st.trim().containsIgnoreCase('street') || st.trim().containsIgnoreCase('state') || st.trim().containsIgnoreCase('postal') || st.trim().containsIgnoreCase('country')){
                                 strtype ='Address';
                           }

                           //Step 2: For each Non-NUll Field , solve for Attribute using Substitute formula
                           // logic to solve define attribute for info_Related__c 
                                if(strtype =='Address'){
                                    if(st.trim().replace('__c', '').replace('Address','').length() >=2){
                                    attributestring = st.trim().replace('__c', '').replace('Address','').replace('Country','').replace('_','').replace('PKI','');
                                        if(attributestring ==''){
                                            attributestring='Main';
                                        }
                                        
                                    }else{
                                       attributestring ='Other'; 
                                    }
                                }else{
                                    if(st.trim().replace('__c', '').replace('Email','').replace('Phone','').replace('PKI','').replace('_','').length() >=2){
                                    attributestring =st.trim().replace('__c', '').replace('Email','').replace('Phone','').replace('PKI','').replace('_','');
                                        if(attributestring==''){
                                          attributestring='Main';  
                                        }
                                    }else{
                                    attributestring='Main';
                                    }
                                }
                            
                               keyMapRelatedalready.put(sobj.Id+strtype+attributestring,sobj.Id);   
                       }
                   }
              }
       }
       if(!keyMapRelatedalready.isEmpty()){
           list<string> allids =keyMapRelatedalready.values();
          List<info_Related__c> infoAlready= new List<info_Related__c>();
         infoAlready= [select id,Attribute__c, Type__c,Contact__c,Account__c,Lead__c from info_Related__c where Contact__c IN:allids OR Account__c IN:allids OR Lead__c IN:allids];
           for(info_Related__c info:infoAlready){
               if(info.Contact__c != null)
             keyMapRelatedalready2.put(info.Contact__c+info.Attribute__c+info.Type__c,info.Id); 
               if(info.Account__c != null)
             keyMapRelatedalready2.put(info.Account__c+info.Attribute__c+info.Type__c,info.Id); 
                if(info.Lead__c != null)
             keyMapRelatedalready2.put(info.Lead__c+info.Attribute__c+info.Type__c,info.Id);         
           }
       }
       map<string,string> keyaddressvalue;
           for(sObject sobj: scope){
               string tempstring;
               keyaddressvalue = new map<string,string>(); // map to create address element with value ie. <state,delhi>
               if(!fldapi.isEmpty()){
                   for(string st:fldapi){
                       if(sobj.get(st.trim()) != null ){
                        
                               // other logic to prepare different set of value to check with IN clause for Info_central query
                           string strtype ;
                           string attributestring;
                           if(st.trim().containsIgnoreCase('Phone') || st.trim().containsIgnoreCase('fax')){
                                  strtype ='Phone';    
                           }
                           if(st.trim().containsIgnoreCase('Email')){
                                 strtype ='Email';
                           }
                          if(st.trim().containsIgnoreCase('city') ||st.trim().containsIgnoreCase('street') || st.trim().containsIgnoreCase('state') || st.trim().containsIgnoreCase('postal') || st.trim().containsIgnoreCase('country')){
                                 strtype ='Address';
                           }
                           
                           // logic to solve define attribute for info_Related__c 
                                if(strtype =='Address'){
                                    if(st.trim().replace('__c', '').replace('Address','').length() >=2){
                                    attributestring = st.trim().replace('__c', '').replace('Address','').replace('Country','').replace('_','').replace('PKI','');
                                       if(attributestring ==''){
                                            attributestring='Main';
                                        }                                    
                                    }
                                    else{
                                        attributestring ='Other';
                                    }
                                    
                                }else{
                                    if(st.trim().replace('__c', '').replace('Email','').replace('Phone','').replace('PKI','').replace('_','').length() >=2){
                                    attributestring =st.trim().replace('__c', '').replace('Email','').replace('Phone','').replace('PKI','').replace('_','');
                                    if(attributestring==''){
                                          attributestring='Main';  
                                        }
                                    }else{
                                    attributestring='Main';
                                    }
                                }
                         // preparing map for address field api start ....  
                          if(strtype != null && strtype =='Address' && string.valueof(sobj.get(st.trim())) !=null){
                              // prepare map of address element <state,delhi>
                              if(st.trim().containsIgnoreCase('street')){
                                  keyaddressvalue.put('street',string.valueof(sobj.get(st.trim())));
                               }else if(st.trim().containsIgnoreCase('city')){
                                   keyaddressvalue.put('city',string.valueof(sobj.get(st.trim())));
                               }else if(st.trim().containsIgnoreCase('state')){
                                   keyaddressvalue.put('state',string.valueof(sobj.get(st.trim())));
                               }else if(st.trim().containsIgnoreCase('postal')){
                                   keyaddressvalue.put('postal',string.valueof(sobj.get(st.trim())));
                               }else if(st.trim().containsIgnoreCase('country')){
                                   keyaddressvalue.put('country',string.valueof(sobj.get(st.trim())));
                               }
                             // Preparing map of address attribute with list of values for info_central__c query  
                               if(st.trim().containsIgnoreCase('street') && typeAddressMapValue.containsKey('street')){
                                       typeAddressMapValue.get('street').add(string.valueof(sobj.get(st.trim())));  
                                   }else if(st.trim().containsIgnoreCase('street') && !typeAddressMapValue.containsKey('street')){
                                       typeAddressMapValue.put('street',new set<string>{string.valueof(sobj.get(st.trim()))});
                                   }
                                   if(st.trim().containsIgnoreCase('city') && typeAddressMapValue.containsKey('city')){
                                       typeAddressMapValue.get('city').add(string.valueof(sobj.get(st.trim())));  
                                   }else if(st.trim().containsIgnoreCase('city') && !typeAddressMapValue.containsKey('city')){
                                       typeAddressMapValue.put('city',new set<string>{string.valueof(sobj.get(st.trim()))});
                                   }
                                   if(st.trim().containsIgnoreCase('state') && typeAddressMapValue.containsKey('state')){
                                       typeAddressMapValue.get('state').add(string.valueof(sobj.get(st.trim())));  
                                   }else if(st.trim().containsIgnoreCase('state') && !typeAddressMapValue.containsKey('state')){
                                       typeAddressMapValue.put('state',new set<string>{string.valueof(sobj.get(st.trim()))});
                                   }
                                   if(st.trim().containsIgnoreCase('postal') && typeAddressMapValue.containsKey('postal')){
                                       typeAddressMapValue.get('postal').add(string.valueof(sobj.get(st.trim())));  
                                   }else if(st.trim().containsIgnoreCase('postal') && !typeAddressMapValue.containsKey('postal')){
                                       typeAddressMapValue.put('postal',new set<string>{string.valueof(sobj.get(st.trim()))});
                                   }
                                   if(st.trim().containsIgnoreCase('country') && typeAddressMapValue.containsKey('country')){
                                       typeAddressMapValue.get('country').add(string.valueof(sobj.get(st.trim())));  
                                   }else if(st.trim().containsIgnoreCase('country') && !typeAddressMapValue.containsKey('country')){
                                       typeAddressMapValue.put('country',new set<string>{string.valueof(sobj.get(st.trim()))});
                                   }
                             // address attribute for info related object         
                             addressattribute=attributestring;
                              system.debug('addressattribute='+addressattribute);
                              // preparing map for address field api end ....
                            }else if(strtype != null && st.trim().containsIgnoreCase(strtype)){
                                // preparing map for non Address field api start ....
                                if(!keyMapRelatedalready2.containsKey(string.valueof(sobj.get('Id'))+attributestring+strtype)){
                                keyMapValue.put(string.valueof(sobj.get(st.trim()))+strtype,string.valueof(sobj.get(st.trim()))); 
                                valueMapRelated.put(sobj.Id+attributestring+string.valueof(sobj.get(st.trim()))+strtype,sobj.Id);                               
                                }
                               
                                
                               // Preparing map of non address api field for info_central__c query 
                                if(typeMapValue.containsKey(strtype)){
                                       typeMapValue.get(strtype).add(string.valueof(sobj.get(st.trim())));  
                                   }else{
                                       typeMapValue.put(strtype,new set<string>{string.valueof(sobj.get(st.trim()))});
                                   }
                                // Preparing map of non address api field for attribute for info Related
                                if(valueMapattribute.containsKey(sobj.Id+attributestring+string.valueof(sobj.get(st.trim()))+strtype)){
                                     valueMapattribute.get(sobj.Id+attributestring+string.valueof(sobj.get(st.trim()))+strtype).add(attributestring);  
                                   }else{
                                       valueMapattribute.put(sobj.Id+attributestring+string.valueof(sobj.get(st.trim()))+strtype,new set<string>{attributestring});
                                   }
                                // preparing map for non Address field api END ....
                                 }
                               } 
                            }
                  }
               // final preparation of address field before query....
                  if(keyaddressvalue.get('street') != null && keyaddressvalue.get('city') != null && keyaddressvalue.get('state') != null && keyaddressvalue.get('postal')!= null && keyaddressvalue.get('country') != null){
                     tempstring = keyaddressvalue.get('street')+keyaddressvalue.get('city')+keyaddressvalue.get('state')+ keyaddressvalue.get('postal')+ keyaddressvalue.get('country');
                     system.debug('addressattribute='+addressattribute);
                      if(!keyMapRelatedalready2.containsKey(string.valueof(sobj.get('Id'))+addressattribute+'Address')){
                        keyMapValueAddress.put(tempstring,keyaddressvalue);
                        valueMapRelated.put(sobj.Id+addressattribute+tempstring+'Address',sobj.Id);                 
                     }
                      
                     
                    if(valueMapattribute.containsKey(sobj.Id+addressattribute+tempstring+'Address')){
                                     valueMapattribute.get(sobj.Id+addressattribute+tempstring+'Address').add(addressattribute);  
                                   }else{
                                       valueMapattribute.put(sobj.Id+addressattribute+tempstring+'Address',new set<string>{addressattribute});
                                   }
                     
                     }
                }
       system.debug('valueMapRelated== line no. 97=='+valueMapRelated);
       // come out of loop and do querry using different set of value  with IN clause for Info_central
       // Prepare query string for info central whether value exist or not
       string querystring ='SELECT Id, Input_Value__c,RecordToUse__c, Type__c,Input_Street__c,Input_City__c,Input_State__c,Input_Postal__c,APICountry__c FROM INFO_Central__c ';
       querystring += 'WHERE Id != null '; 
       string temp =' ';
       if(typeMapValue.get('Phone') != null){
         //  system.debug('typeMapValue Phone==='+typeMapValue.get('Phone'));
           set<string> strlst =typeMapValue.get('Phone');
        //   system.debug('strlst==='+strlst);
           temp +='(Type__c =\'Phone\' AND Input_Value__c IN :strlst )';
       }
       
       if(typeMapValue.get('Email') != null){
           set<string> strlist =typeMapValue.get('Email');
           if(temp != ' '){
              temp += ' OR (Type__c =\'Email\' AND Input_Value__c IN :strlist)';  
           }else{
               temp += ' (Type__c =\'Email\' AND Input_Value__c IN :strlist)';
           }
            
       }
       system.debug('typeAddressMapValue=='+typeAddressMapValue);
       if(typeAddressMapValue != null && !typeAddressMapValue.keySet().isEmpty()){
           set<string> strstreetlist;
           set<string> strcitylist;
           set<string> strstatelist;
           set<string> strpostallist;
           set<string> strcountrylist;
            if(typeAddressMapValue.get('street') != null)
           strstreetlist =typeAddressMapValue.get('street');
            if(typeAddressMapValue.get('city') != null)
           strcitylist =typeAddressMapValue.get('city');
            if(typeAddressMapValue.get('state') != null)
           strstatelist =typeAddressMapValue.get('state');
            if(typeAddressMapValue.get('postal') != null)
           strpostallist =typeAddressMapValue.get('postal');
            if(typeAddressMapValue.get('country') != null)
           strcountrylist =typeAddressMapValue.get('country');
           system.debug('strcountrylist=='+strcountrylist);
           if(temp != ' '){
              temp += ' OR (Type__c =\'Address\' AND Input_Street__c IN :strstreetlist AND Input_City__c IN :strcitylist AND Input_State__c IN :strstatelist AND Input_Postal__c IN :strpostallist AND APICountry__c IN :strcountrylist)';  
           }else{
               temp += ' (Type__c =\'Address\' AND Input_Street__c IN :strstreetlist AND Input_City__c IN :strcitylist AND Input_State__c IN :strstatelist AND Input_Postal__c IN :strpostallist AND APICountry__c IN :strcountrylist)';
           }
        }
       if(temp != ' '){
          querystring  += ' AND ('+temp+') limit 50000'; 
       }else{
           querystring  = ' ';
       }
      
       system.debug('querystring'+querystring);
       list<Sobject> lstobj = new list<Sobject>();
       try{
           if(querystring != ' ')
          lstobj =database.query(querystring); 
           system.debug('lstobj after'+lstobj);
       }
       catch(System.NullPointerException e){
           system.debug('e'+e);
            system.debug('e'+e.getCause());
           system.debug('e'+e.getLineNumber());
           system.debug('e'+e.getLineNumber());
       }
       system.debug('lstobj'+lstobj); // this is list of info_Central__c object which is already in our database 
      system.debug('keyMapValueAddress  before='+keyMapValueAddress);
       list<INFO_Central__c> infocentrallist = new list<INFO_Central__c>();
      Set<string> InfoCentralId = new set<string>();
       if(!lstobj.isEmpty()){
            for(Sobject sb: lstobj){
                // preparing list of info central id (RecordToUse__c)
                //  removing map elements that are already in our database...
                system.debug('fetch address record='+string.valueof(sb.get('Input_Street__c'))+string.valueof(sb.get('Input_City__c'))+string.valueof(sb.get('Input_State__c'))+string.valueof(sb.get('Input_Postal__c'))+string.valueof(sb.get('APICountry__c')));
                InfoCentralId.add(string.valueof(sb.get('Id'))); 
                if(keyMapValue.containsKey(string.valueof(sb.get('Input_Value__c'))+string.valueof(sb.get('Type__c')))){
                    keyMapValue.remove(string.valueof(sb.get('Input_Value__c'))+string.valueof(sb.get('Type__c')));
                }
                if(keyMapValueAddress.containsKey(string.valueof(sb.get('Input_Street__c'))+string.valueof(sb.get('Input_City__c'))+string.valueof(sb.get('Input_State__c'))+string.valueof(sb.get('Input_Postal__c'))+string.valueof(sb.get('APICountry__c')))){
                    keyMapValueAddress.remove(string.valueof(sb.get('Input_Street__c'))+string.valueof(sb.get('Input_City__c'))+string.valueof(sb.get('Input_State__c'))+string.valueof(sb.get('Input_Postal__c'))+string.valueof(sb.get('APICountry__c')));
                } 
           }
       }
       // creating info_Central__c record  from existing map elements keyMapValue,keyMapValueAddress---
       
       
       if(!keyMapValue.keySet().isEmpty()){
           for(string str:keyMapValue.keySet()){
             //  system.debug('keyMapValue.get(str))==='+keyMapValue.get(str));
               Id devRecordTypeId = Schema.SObjectType.INFO_Central__c.getRecordTypeInfosByName().get(str.removeStartIgnoreCase(keyMapValue.get(str))).getRecordTypeId();
               INFO_Central__c infoctrl = new INFO_Central__c();
                       infoctrl.Type__c=str.removeStartIgnoreCase(keyMapValue.get(str));
                       infoctrl.Input_Value__c=keyMapValue.get(str);
                       infoctrl.recordtypeId=devRecordTypeId;
                       infocentrallist.add(infoctrl);
           }
          }
       system.debug('keyMapValueAddress  after='+keyMapValueAddress);
          if(!keyMapValueAddress.keySet().isEmpty()){
           for(string str:keyMapValueAddress.keySet()){
               Id devRecordTypeId = Schema.SObjectType.INFO_Central__c.getRecordTypeInfosByName().get('Address').getRecordTypeId();
               INFO_Central__c infoctrl = new INFO_Central__c();
                       infoctrl.Type__c='Address';
                      // infoctrl.Input_Value__c=keyaddressvalue.get(str);
                       if(keyMapValueAddress.get(str) != null && keyMapValueAddress.get(str).containsKey('street')){
                         infoctrl.Input_Street__c=keyMapValueAddress.get(str).get('street');  
                       }
                       if(keyMapValueAddress.get(str) != null && keyMapValueAddress.get(str).containsKey('city')){
                         infoctrl.Input_City__c=keyMapValueAddress.get(str).get('city');  
                       }
                       if(keyMapValueAddress.get(str) != null && keyMapValueAddress.get(str).containsKey('state')){
                         infoctrl.Input_State__c=keyMapValueAddress.get(str).get('state');  
                       }
                       if(keyMapValueAddress.get(str) != null && keyMapValueAddress.get(str).containsKey('postal')){
                         infoctrl.Input_Postal__c=keyMapValueAddress.get(str).get('postal');  
                       }
                       if(keyMapValueAddress.get(str) != null && keyMapValueAddress.get(str).containsKey('country')){
                         infoctrl.APICountry__c=keyMapValueAddress.get(str).get('country');  
                       }
                       infoctrl.recordtypeId=devRecordTypeId;
                       infocentrallist.add(infoctrl);
           }
          }
       
      // system.debug('infocentrallist===='+infocentrallist);
      list<string> newRecordIds = new List<string>();
       if(!infocentrallist.isEmpty()){
           Database.SaveResult[] srList = Database.insert(infocentrallist, false);
          //  system.debug('srList=='+srList.size());
            for (Database.SaveResult sr : srList) {
                system.debug('sucess Record central'+sr.getId());
                 if(sr.getId() != null){
                     InfoCentralId.add(sr.getId()); // storing success record id to get RecordToUse__c values
                 }
                if (!sr.isSuccess()) {
                    // Operation failed, so get all errors                
                     for(Database.Error err : sr.getErrors()) {
                       //  System.debug('The following error has occurred.');                    
                        // System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        // System.debug('Fields that affected this error: ' + err.getFields());
                     }
                }
            } 
          }
       // creating info_Central__c record  from existing map elements keyMapValue,keyMapValueAddress END Here---
       // now adding list of RecordToUse__c  from newly inserted info_Central__c record to InfoCentralId list- start here--
        /*  if(!newRecordIds.isEmpty()){
              list<INFO_Central__c> infoCent = new list<INFO_Central__c>();
              infoCent =[SELECT Id,RecordToUse__c FROM INFO_Central__c WHERE ID IN:newRecordIds];
              if(!infoCent.isEmpty()){
                  for(INFO_Central__c info:infoCent){
                      InfoCentralId.add(info.Id);
                  }
              }
            } */
           // now adding list of RecordToUse__c  from newly inserted info_Central__c record to InfoCentralId list-END here--
        list<INFO_Related__c> existingInfoRelatedLst = New list<INFO_Related__c>();
       list<INFO_Central__c> existingInfo = New list<INFO_Central__c>();
       system.debug('InfoCentralId=='+InfoCentralId);
       // From here we will create map and list for inserting Info_Related__c and compare attribute from previously created map
          if(!InfoCentralId.isEmpty()){
        existingInfoRelatedLst=  [SELECT Id, Name, Type__c,InfoCentral__c,InfoCentral__r.Input_Value__c,Contact__c,Lead__c,Account__c,ApiInputValue__c,Attribute__c,ApiInputStreet__c,ApiInputCity__c,ApiInputState__c,ApiInputPostal__c,ApiInputCountry__c,InfoCentral__r.Input_Street__c,InfoCentral__r.Input_City__c,InfoCentral__r.Input_State__c,InfoCentral__r.Input_Postal__c,InfoCentral__r.APICountry__c FROM INFO_Related__c WHERE InfoCentral__c IN:InfoCentralId];
        existingInfo =[SELECT Id,name,RecordToUse__c,Type__c,Input_Value__c,Input_Street__c, Input_City__c, Input_State__c, Input_Postal__c, APICountry__c FROM INFO_Central__c WHERE Id IN:InfoCentralId ];
          }
       system.debug('existingInfo'+existingInfo);
       if(!existingInfo.isEmpty()){
           for(INFO_Central__c infoc: existingInfo){
               if(infoc.Type__c =='Address'){
                mapkeyinfoId.Put(infoc.Input_Street__c+infoc.Input_City__c+infoc.Input_State__c+infoc.Input_Postal__c+infoc.APICountry__c + infoc.Type__c,infoc.RecordToUse__c);    
               }else{
                 mapkeyinfoId.Put(infoc.Input_value__c + infoc.Type__c,infoc.RecordToUse__c);  
               }
            
          }
        }
       system.debug('valueMapRelated== line no. 216=='+valueMapRelated);
       system.debug('existingInfoRelatedLst=='+existingInfoRelatedLst);
       
       
       // Removing map element which are already in our data base for info related object -- start Here----
         if(!existingInfoRelatedLst.isEmpty()){
             for(INFO_Related__c infoRel:existingInfoRelatedLst){
                 
                 string relatedaccountId;
                string relatedContacttId;
                string relatedLeadId;    
                if(infoRel.Account__c != null)
                relatedaccountId = string.valueof(infoRel.Account__c);
                if(infoRel.Contact__c != null)
                 relatedContacttId = string.valueof(infoRel.Contact__c);
                if(infoRel.Lead__c != null)
                 relatedLeadId = string.valueof(infoRel.Lead__c);
                 system.debug('==related already exit=='+relatedContacttId+string.valueof(infoRel.Attribute__c)+string.valueof(infoRel.InfoCentral__r.Input_Value__c)+string.valueof(infoRel.Type__c));

                 if(relatedaccountId != null && valueMapRelated.containsKey(relatedaccountId+string.valueof(infoRel.Attribute__c)+string.valueof(infoRel.InfoCentral__r.Input_Value__c)+string.valueof(infoRel.Type__c))){
                    valueMapRelated.remove(relatedaccountId+string.valueof(infoRel.Attribute__c)+string.valueof(infoRel.InfoCentral__r.Input_Value__c)+string.valueof(infoRel.Type__c));
                }
                if(relatedContacttId != null && valueMapRelated.containsKey(relatedContacttId+string.valueof(infoRel.Attribute__c)+string.valueof(infoRel.InfoCentral__r.Input_Value__c)+string.valueof(infoRel.Type__c))){
                    valueMapRelated.remove(relatedContacttId+string.valueof(infoRel.Attribute__c)+string.valueof(infoRel.InfoCentral__r.Input_Value__c)+string.valueof(infoRel.Type__c));
                }
                if(relatedLeadId != null && valueMapRelated.containsKey(relatedLeadId+string.valueof(infoRel.Attribute__c)+string.valueof(infoRel.InfoCentral__r.Input_Value__c)+string.valueof(infoRel.Type__c))){
                    valueMapRelated.remove(relatedLeadId+string.valueof(infoRel.Attribute__c)+string.valueof(infoRel.InfoCentral__r.Input_Value__c)+string.valueof(infoRel.Type__c));
                }
                if(relatedaccountId != null && valueMapRelated.containsKey(relatedaccountId+string.valueof(infoRel.Attribute__c)+infoRel.InfoCentral__r.Input_Street__c+infoRel.InfoCentral__r.Input_City__c+infoRel.InfoCentral__r.Input_State__c+infoRel.InfoCentral__r.Input_Postal__c+infoRel.InfoCentral__r.APICountry__c+string.valueof(infoRel.Type__c))){
                    valueMapRelated.remove(relatedaccountId+string.valueof(infoRel.Attribute__c)+infoRel.InfoCentral__r.Input_Street__c+infoRel.InfoCentral__r.Input_City__c+infoRel.InfoCentral__r.Input_State__c+infoRel.InfoCentral__r.Input_Postal__c+infoRel.InfoCentral__r.APICountry__c+string.valueof(infoRel.Type__c));
                }
                if(relatedContacttId != null && valueMapRelated.containsKey(relatedContacttId+string.valueof(infoRel.Attribute__c)+infoRel.InfoCentral__r.Input_Street__c+infoRel.InfoCentral__r.Input_City__c+infoRel.InfoCentral__r.Input_State__c+infoRel.InfoCentral__r.Input_Postal__c+infoRel.InfoCentral__r.APICountry__c+string.valueof(infoRel.Type__c))){
                    valueMapRelated.remove(relatedContacttId+string.valueof(infoRel.Attribute__c)+infoRel.InfoCentral__r.Input_Street__c+infoRel.InfoCentral__r.Input_City__c+infoRel.InfoCentral__r.Input_State__c+infoRel.InfoCentral__r.Input_Postal__c+infoRel.InfoCentral__r.APICountry__c+string.valueof(infoRel.Type__c));
                }
                if(relatedLeadId != null && valueMapRelated.containsKey(relatedLeadId+string.valueof(infoRel.Attribute__c)+infoRel.InfoCentral__r.Input_Street__c+infoRel.InfoCentral__r.Input_City__c+infoRel.InfoCentral__r.Input_State__c+infoRel.InfoCentral__r.Input_Postal__c+infoRel.InfoCentral__r.APICountry__c+string.valueof(infoRel.Type__c))){
                    valueMapRelated.remove(relatedLeadId+string.valueof(infoRel.Attribute__c)+infoRel.InfoCentral__r.Input_Street__c+infoRel.InfoCentral__r.Input_City__c+infoRel.InfoCentral__r.Input_State__c+infoRel.InfoCentral__r.Input_Postal__c+infoRel.InfoCentral__r.APICountry__c+string.valueof(infoRel.Type__c));
                }
                 
                
             }
             
         }
       // Removing map element which are already in our data base for info related object.. END Here----
       system.debug('valueMapRelated== line no. 242=='+valueMapRelated);
       system.debug('mapkeyinfoId=='+mapkeyinfoId);
       
       
       /*Step 4: After we have the CENTRAL.RecordToUse__c, For Each Attribute, INSERT to INFO_RELATED(CAL+Type+Attribute+Info_CEntral.ID,apiInputValue(oraddress))
         VALUES( CAL.ID, {phone|emial|address}, Attibute(solved above in step 2), RecordToUse__c, FieldName)
       (Because we populate all needed fields, the P.LOW will bypass triggers.)*/

       // Inserting Info_Related__c object from remaining map element--Start Here-----
         list<INFO_Related__c> InsertInfoRelatedLst = New list<INFO_Related__c>();
         if(!valueMapRelated.keySet().isEmpty()){
             for(string str:valueMapRelated.keySet()){
                 system.debug('str=='+str);
                
                 system.debug('mapkeyinfoId=='+mapkeyinfoId);
                 system.debug('valueMapattribute=='+valueMapattribute);
                     if(str != null){
                         for(string st:valueMapattribute.get(str)){
                              if(mapkeyinfoId.containsKey(str.removeStartIgnoreCase(valueMapRelated.get(str)).removeStartIgnoreCase(st))){
                             INFO_Related__c infoRel = new INFO_Related__c(); 
                             if(str.endsWithIgnoreCase('Phone')){ // same we have to do with email and address also
                             infoRel.Type__c ='Phone';
                             }else if(str.endsWithIgnoreCase('Email')){
                               infoRel.Type__c ='Email';  
                             }else if(str.endsWithIgnoreCase('Address')){
                                 infoRel.Type__c='Address';
                               
                             }
                                  if(st !='')
                             infoRel.Attribute__c=st; 
                                  else
                                 infoRel.Attribute__c='Other';      
                                
                            infoRel.InfoCentral__c=mapkeyinfoId.get(str.removeStartIgnoreCase(valueMapRelated.get(str)).removeStartIgnoreCase(st));
                             if(str.startsWithIgnoreCase('001'))
                                 infoRel.Account__c =valueMapRelated.get(str);
                             if(str.startsWithIgnoreCase('003'))
                                 infoRel.Contact__c =valueMapRelated.get(str);
                             if(str.startsWithIgnoreCase('00Q'))
                                 infoRel.Lead__c =valueMapRelated.get(str);
                             
                             InsertInfoRelatedLst.add(infoRel);
                             }
                           }
                         }
                       }
                     }
         if(!InsertInfoRelatedLst.isEmpty()){
           Database.SaveResult[] srList = Database.insert(InsertInfoRelatedLst, false);
               for (Database.SaveResult sr : srList) {
                system.debug('sucess Record'+sr.getId());
                 if (!sr.isSuccess()) {
                    // Operation failed, so get all errors                
                     for(Database.Error err : sr.getErrors()) {
                         System.debug('The following error has occurred.');                    
                         System.debug(err.getStatusCode() + ': ' + err.getMessage());
                         System.debug('Fields that affected this error: ' + err.getFields());
                     }
                }
            }  
         }
        // Inserting Info_Related__c object from remaining map element--END Here----- 
       }
   
public void finish(Database.BatchableContext BC){
   }
    
}