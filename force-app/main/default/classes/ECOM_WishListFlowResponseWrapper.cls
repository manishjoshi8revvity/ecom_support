public class ECOM_WishListFlowResponseWrapper {
    
    //this class is to accept wishlist API reponse
    @auraEnabled
    public Boolean success;//true or false
    @auraEnabled
    public String wishlistId;// pass when success 
    @auraEnabled
    public String message;// success or error message

}