/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *    - 
  *    - ITSFDC-####
  *
  * 2. Description - Put detailed description here of what this class is used for procedurally
  *    This will Invocable class just pass list of string of field value of PSETFieldMaster__c it will populate blank Field master of 
  *    PSET_Permission_Settings__c ,PSET_Permission_Set_History__c
  *   - This way we can feed list of stirng (Field master) from mass action.
  *
  * 3. Objects referenced
  *    -PSETFieldMaster__c
  *    -PSET_Permission_Settings__c 
  *    -PSET_Permission_Set_History__c 
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None
  *   
  *
  * 5. Dependant Class(es):
  *    - None
  *
  * 6. Test Class Name: PSET_MasterField_Update_Test
  *
  * 7. Author Name(s): 
  *    - Vishwas Gupta 2021.05.20
  *    - First Last & Updated Date(YYYY.MM.DD)
  *    - First Last & Updated Date(YYYY.MM.DD)
  *
*************************************************************/ 
public class PSET_MasterField_Update {
	@InvocableMethod
    public static void flowcalledforMasterField(list<string> FieldMaster){
        Map<string,string> MapnameId = new Map<string,string>();
        if(FieldMaster != null && !FieldMaster.isEmpty()){
         list<PSET_Field_Master__c>  pstFldMst=new list<PSET_Field_Master__c>();
           pstFldMst= [SELECT  Id,PSETPermissionSet__c, Name FROM PSET_Field_Master__c Where Name IN :FieldMaster ];
            if(!pstFldMst.IsEmpty()){
                for(PSET_Field_Master__c pfm:pstFldMst){
                    MapnameId.Put(string.valueof(pfm.Name).toLowercase(),pfm.Id);
                } 
            }
        }
        List<PSET_Permission_Settings__c> pstPermSttoUpdate= New List<PSET_Permission_Settings__c>();
        if(!MapnameId.KeySet().IsEmpty()){
         List<PSET_Permission_Settings__c> pstPermSt= New List<PSET_Permission_Settings__c>();
             pstPermSt=[SELECT PSETFieldMaster__c, Field__c, Name, Id FROM PSET_Permission_Settings__c Where PSETFieldMaster__c = null];
            if(!pstPermSt.isEmpty()){
                for(PSET_Permission_Settings__c pps:pstPermSt){
                    pps.PSETFieldMaster__c=MapnameId.get(string.valueof(pps.Field__c).toLowercase());
                    pstPermSttoUpdate.add(pps);
                }
             }
        }
        if(!pstPermSttoUpdate.isEmpty()){
            try{
               Update pstPermSttoUpdate; 
            }Catch(Exception Ex){
                system.debug('Ex'+Ex.getMessage());
            }
            
        }
        
		
		List<PSET_Permission_Set_History__c> pstPermHstrytoUpdate= New List<PSET_Permission_Set_History__c>();
        if(!MapnameId.KeySet().IsEmpty()){
         List<PSET_Permission_Set_History__c> pstPermht= New List<PSET_Permission_Set_History__c>();
             pstPermht=[SELECT Id, Field_Name__c, PSETFieldMaster__c FROM PSET_Permission_Set_History__c Where PSETFieldMaster__c = null];
            if(!pstPermht.isEmpty()){
                for(PSET_Permission_Set_History__c ph:pstPermht){
                    ph.PSETFieldMaster__c=MapnameId.get(string.valueof(ph.Field_Name__c).toLowercase());
                    pstPermHstrytoUpdate.add(ph);
                }
             }
        }
        if(!pstPermHstrytoUpdate.isEmpty()){
            try{
              Update pstPermHstrytoUpdate;  
            }catch(exception ex){
                system.debug('ex'+ex.getMessage());
            }
            
        }
    }
}