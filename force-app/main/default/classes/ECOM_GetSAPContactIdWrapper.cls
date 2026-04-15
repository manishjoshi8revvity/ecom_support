/**************************************************************
 * 1. Ticket(s) that relates to this class
 *    RWPS-553 
 * 
 * 2. Description - This wrapper class is used to map request to SAP to fetch Contact Id
 *					
 * 3. Objects referenced
 * 	 
 * 4. Callouts to additional Components (including their methods) or None:
 * 	 - None
 *
 * 5. Dependant Class(es):
 * 	 - ERP_AddressService
 *
 * 6. Test Class Name: Test_Class_Name
 *
 * 7. Is @Invocable (Yes or No): No
 *
 * 8. Author Name(s): 
 * - Sidak Singh 2024.07.02
 *
*************************************************************/ 
public class ECOM_GetSAPContactIdWrapper {

	public class Addresses {
		@AuraEnabled public String addressId;
		@AuraEnabled public String shipToNumber;
	}

	@AuraEnabled public String firstName;
	@AuraEnabled public String lastName;
	@AuraEnabled public String contactId;
	@AuraEnabled public String email;
	@AuraEnabled public List<Addresses> address;

    @AuraEnabled public List<Results> results;

	public class Results {
		@AuraEnabled public String addressId;	//a0001
		@AuraEnabled public String contactId;	//003Qo00000JzRWfIAN
		@AuraEnabled public String sapContactNumber;	//0001944143
	}
}