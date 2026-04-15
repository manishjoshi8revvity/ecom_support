/**************************************************************
* 1. Jira Ticket(s) that relates to this class
     OM-265
*
* 2. Description - This class is used in "lwc_unpivot_soql" LWC component , which cna be used in screen flow to unpivot data
*   on provided SOQL's fetched data with respect to provided group field api. 
*
* 3. Objects referenced
*     None
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es)/LWC component:
*     LWC:lwc_unpivot_soql
* 6. Test Class Name: UTIL_unpivot_soql_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vishwas 22-11-2023
*************************************************************/
public class UTIL_unpivot_soql {
    
    /*- this Method will be used to fetch data from provided SOQL 
     * along with field api for which group is required
     * 
     * return of method is WrapperSobject which has two properties
     * 1. List<sobject>
     * 2. group field api
     */
    @AuraEnabled    
    Public static WrapperSobject fetch_data(string group_field,string query_String){
        List<Sobject>  oblist=database.query(query_string); // fetching sobject from provided SOQL
        WrapperSobject wrap= new WrapperSobject();
        string grpfield;
        // this for loop is used for getting actual field api which will case sensitive
        // this is optimized as we are using break statement as soon as we will get actual api of field
        for(Sobject Obj:oblist){
            if( group_field==grpfield && grpfield != null){
                break;
            }
            Map<String, Object> fieldstovalue = Obj.getPopulatedFieldsAsMap();
            for(string var_field:fieldstovalue.keySet()){
                if(var_field.toLowerCase() ==group_Field.toLowerCase()){
                    group_field=var_field;
                    grpfield=var_field;
                    break;
                }
            }
            
        }
        wrap.sObject_List=oblist;
        wrap.group_field=group_field;
        return wrap;
    }
    Public class WrapperSobject{
        @AuraEnabled  public List<Sobject> sObject_List{get;set;} 
        @AuraEnabled  public string group_field{get;set;} 
    }
    /*- this Method can be used to fetch unpivot data from provided SOQL 
     * return of method is List<wrapper> which has three properties
     * 1. Entity
     * 2. Attribute
     * 3. Value
     */
/*@AuraEnabled    
    Public static List<wrapper> fetch_unpivot_soql(string group_field,string query_String){
      List<Wrapper> wrapList= new List<Wrapper>();  
      List<Sobject>  oblist=database.query(query_string);
         string grpfield;
        for(Sobject Obj:oblist){
            if( group_field==grpfield && grpfield != null){
                break;
            }
            Map<String, Object> fieldstovalue = Obj.getPopulatedFieldsAsMap();
            for(string var_field:fieldstovalue.keySet()){
                if(var_field.toLowerCase() ==group_Field.toLowerCase()){
                    group_field=var_field;
                    grpfield=var_field;
                    break;
                }
            }
            for(string var_field:fieldstovalue.keySet()){
                if(var_field.toLowerCase() !=group_Field.toLowerCase() && var_field.toLowerCase() != 'currencyisocode'){
                    Wrapper wrap= new Wrapper();
                    wrap.Entity=String.valueof(fieldstovalue.get(group_Field));
                    wrap.Attribute=var_field;
                    wrap.Value=string.valueof(fieldstovalue.get(var_field));
                    wrapList.add(wrap);
                }
            }
        }       
        return wrapList;
    }
    
    Public class Wrapper{
      @AuraEnabled  public string Entity{get;set;} 
      @AuraEnabled  public string Attribute{get;set;}
      @AuraEnabled  public string Value{get;set;}
    }     */                         
}