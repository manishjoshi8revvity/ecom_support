/**************************************************************
 * 1. Ticket(s) that relates to this class
 * - ATEAM-####
 *
 * 2. Description - This class is used to fetch user data
 *                - return save and update User data
 *
 *
 *
 * 3. Objects referenced
 * - User
 * - Contact
 *
 * 4. Callouts to additional Components (including their methods) or None:
 * - None
 *
 * 5. Dependant Class(es):
 * 
 *
 * 6. Test Class Name: 
 * - ECOM_ContactInfoController_Test
 *
 * 7. Is @Invocable (Yes or No): No
 *
 * 8. Author Name(s): 
 * - First Last & Updated Date(YYYY.MM.DD) example: Brad Durbin 2023.06.21
 * - First Last & Updated Date(YYYY.MM.DD)
 * - First Last & Updated Date(YYYY.MM.DD)
 *
*************************************************************/
public class ECOM_ContactInfoController {

    /**
    * @description 
    * @author Rani | 09-21-2023 
    * @return user 
    **/
    @AuraEnabled(cacheable=true)
    public static user getUserData() {
        //Move SOQL to REPO
        User userInfo = [SELECT Id, Username, LastName, FirstName, Name, CompanyName, Street, City, State, PostalCode, Country, Address, Email, Phone, Fax, MobilePhone, ContactId, AccountId FROM User WHERE Id =: UserInfo.getUserId()];
        Contact contactInfo = [Select Id FROM Contact WHERE Id=:userInfo.ContactId];
        return userInfo; 
    }
    
    /**
    * @description 
    * @author Rani | 09-21-2023 
    * @param modifiedUserData 
    * @return boolean 
    **/
    @AuraEnabled
    public static boolean updateUserData(User modifiedUserData) {
        //Move SOQL to REPO
        system.debug('updatedUserData =>'+modifiedUserData.Street); 
        User userInfo = [SELECT Id, Username, LastName, FirstName, Name, CompanyName, Street, City, State, PostalCode, Country, Address, Email, Phone, Fax, MobilePhone, ContactId, AccountId FROM User WHERE Id =: modifiedUserData.Id];
        //Id queueId = [SELECT Id, QueueId, Queue.Name FROM QueueSobject WHERE Queue.DeveloperName = 'CAQ_ECOM_UsersRequestCase'].QueueId;
        Case newCase = new Case();
        if(modifiedUserData.Street != null || modifiedUserData.City != null || modifiedUserData.State != null || modifiedUserData.PostalCode != null || modifiedUserData.Country != null){
            
            //create a case
            
            
            newCase.Subject = 'User requested for Address update';
            newCase.Description = 'user requested for update current address to new address, please see below details: Street: '+modifiedUserData.Street+' City: '+modifiedUserData.City+' State: '+modifiedUserData.State+' PostalCode: '+modifiedUserData.PostalCode+' Country: '+modifiedUserData.Country;
            newCase.AccountId = userInfo.AccountId;
            newCase.ContactId = userInfo.ContactId;
            //newCase.OwnerId = queueId;
           
            newCase.Priority = 'Medium';
            //newCase.Origin =;
            //newCase.Reason =;
            newCase.Status = 'New';
            newCase.Type = 'Feature Request';
            insert newCase;
        }
        else{
            update modifiedUserData;
        }
        system.debug('newCase =>'+newCase.Id);
        system.debug('updatedUserData =>'+modifiedUserData);
        return true;
    }
    
}