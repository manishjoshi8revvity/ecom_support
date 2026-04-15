/**************************************************************
* 1. Jira Ticket(s) that relates to this class
     OM-265
*
* 2. Description - This testclass is used to cover test coverage of apex class(UTIL_unpivot_soql) used in "lwc_unpivot_soql" LWC component , which cna be used in screen flow to unpivot data
*   on provided SOQL's fetched data with respect to provided group field api. 
*
* 3. Objects referenced
*     None
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es)/LWC component:
*     LWC: lwc_unpivot_soql,
*	  ApexClass:UTIL_unpivot_soql
* 6. Test Class fro apex class: UTIL_unpivot_soql
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Vishwas 24-11-2023
*************************************************************/
@isTest
public class UTIL_unpivot_soql_Test {
    @isTest static void testmethod1() {
        string groupfield='Id';
        string soqlquery='select id,name,Campaign__c,ownerId from interaction__c limit 5';
        campaign cmp= new Campaign(name ='TEST_STRING' , isActive = true);
        Insert cmp;
        interaction__c intr= new interaction__c();
        intr.Campaign__c =cmp.Id;
        intr.ownerId=userinfo.getUserId();
        insert intr;
        UTIL_unpivot_soql.fetch_data(groupfield,soqlquery);
       // UTIL_unpivot_soql.fetch_unpivot_soql(groupfield,soqlquery);
    }
}