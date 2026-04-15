/**************************************************************
*
* 1. Jira Ticket(s) that relates to this class
*    ECOM-2302
*
* 2. Description - This class is a controller class to reset newly registered user password.
*
*
*
* 3. Objects referenced
*    -None
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*    
*
* 5. Dependant Class(es):
*    - None
*	
* 6. Test Class Name:         
*    - 
*
* 7. Is @Invocable (Yes or No): Yes
*
* 8. Author Name(s):
*    - vramachandran@rafter.one | 09 May 2024
*    - Kushal 2025.12.31 Updated the copyright year to be dynamic - RWPS-5616
*************************************************************/
public class ECOM_PasswordResetEmailController {
    
    public Id contactIdFromEmail{get; set;}
    //RWPS-5616 Start
    public String copyright2016Text {
        get {
            return (
                String.format(
                    Label.ECOM_ET_Copyright_2016, new Object[] {Date.today().year()}
                )
            );
        }
    }
    //RWPS-5616 End

    /**
     * @description This method returns the user record for the passed contactId
     * @author vramachandran@rafter.one | 29 May 2024 
     * @returns User
     */
    public User getUserRecord() {
        User userRecord;
        
        try{
			List<User> usersList = [SELECT Id, FirstName, LastName, Name, Email, ECOM_Reset_Password_Site_URL__c 
                                    FROM User 
                                    WHERE ContactId =: contactIdFromEmail 
                                    LIMIT 1
                                   ];            
            
            if(null != usersList && !usersList.isEmpty()) {
                userRecord = usersList[0];
            }
        }catch(Exception e) {
            System.debug('Exception e:: ' + e.getStackTraceString());
        }
        
        return userRecord;
    }
}