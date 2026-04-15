/**************************************************************
 * 1. Jira Ticket(s) that relates to this class
 *    ECOM-113
 * 	  ECOM-114
 * 
 * 2. Description - This class is a wrapper class.
 * 
 * 3. Objects referenced
 *    - None
 * 
 * 4. Callouts to additional Components (including their methods) or None:
 *    - None
 * 
 * 5. Dependant Class(es):
 *    - ECOM_OrderController
 *    - ECOM_OrderService
 *    - ECOM_OrderUtil
 *    - ECOM_UserUtil
 * 
 * 6. Test Class Name: 
 * 
 * 7. Is @Invocable (Yes or No): No
 * 
 * 8. Author Name(s):
 *    - Vipul Goyal 09-20-2023
 *************************************************************/
public class ECOM_FormWrapper {
    
    public class FormWrapper{
        public String formType;
        public String areaOfInterest;
        public String companyName;
        public String inquiryType;
        public String userComments;
        public String caseOrigin;
        public UserInfo user;
        public AddressInfo Address;
        public InstrumentInfo Instrument;
        public OrderInfo Order; 
    }

    public class UserInfo{
        public String firstName;
        public String lastName;
        public String email;
        public String phone;
        public String role;
    }

    public class AddressInfo{
        public String line;
        public String city;
        public String state;
        public String postal;
        public String country;
    }

    public class InstrumentInfo{
        public String serial;
        public String name;
        public String modelName;
    }

    public class OrderInfo{
        public String status;
        public String number_replace;
        public String line;
        public String partNumber;
        public Decimal quantity;
        public DateTime date_replace;
        public String contactNumber;
        public String soldTo;
        public String payer;
        public String webOrderNumber;
        public Integer webLineNumber;
    }

}