/**************************************************************
* 1. Jira Ticket(s) that relates to this class
*       ECOM-658
*
* 2. Description - This class is used for Cache Management.
*
* 3. Objects referenced
*    - contact
*
* 4. Callouts to additional Components (including their methods) or None:
*    
* 5. Dependant Class(es):
*    - ECOM_CartService
*
* 6. Test Class Name:        
*    - ECOM_SessionCacheUtil_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Manoj 2023.08.30
*
*************************************************************/
public class ECOM_SessionCacheUtil {
    final static String requestKey = 'requestData';
    final static String responseKey = 'responseData';
    final Static Integer MAX_TTL_SECS = 28800; 
    String partitionInput = 'local.EcomCache';
	Cache.SessionPartition sessionPartition;


    /**
    * @description //Constructor
    * @author Vipul Goyal | 09-20-2023 
    **/
    public ECOM_SessionCacheUtil(){
        if(sessionPartition==null){
            sessionPartition = getPartition();
        }
    }

    /**
    * @description //Method to get partition
    * @author mkumar@rafter.one | 09-01-2023 
    * @return Cache.SessionPartition 
    **/
    public Cache.SessionPartition getPartition() {
       if (sessionPartition == null) {
            sessionPartition = Cache.Session.getPartition(partitionInput);
       }
       return sessionPartition;
     }
    
    /**
    * @description //Method to set Session
    * @author mkumar@rafter.one | 09-01-2023 
    * @param key 
    * @param value 
    **/
    public  void setSessionCache(String key, String value){
        Cache.Session.put('local.EcomCache.'+key,value,MAX_TTL_SECS);
    }
    
    /**
    * @description //Get Session Cache
    * @author mkumar@rafter.one | 09-01-2023 
    * @param key 
    * @return Object 
    **/
    public  Object getSessionCache(String key){
        Object cachedData = Cache.Session.get('local.EcomCache.'+key);
        return cachedData;
    }
    
    /**
    * @description //To get Order Simulation Request
    * @author mkumar@rafter.one | 09-01-2023 
    * @return ECOM_SimulateOrderWrapper.OrderRequest 
    **/
    public static ECOM_SimulateOrderWrapper.OrderRequest getOrderSimulationRequest(){
        ECOM_SimulateOrderWrapper.OrderRequest cachedRequest = new ECOM_SimulateOrderWrapper.OrderRequest();
        Object cachedData = Cache.Session.get('local.EcomCache.requestData');
        cachedRequest = (ECOM_SimulateOrderWrapper.OrderRequest)JSON.deserializeStrict (String.valueOf(cachedData),ECOM_SimulateOrderWrapper.OrderRequest.class);
        
        return cachedRequest;
    }
    
    /**
    * @description //to get simulation response
    * @author mkumar@rafter.one | 09-01-2023 
    * @return ECOM_SimulateOrderWrapper.OrderResponse 
    **/
    public static ECOM_SimulateOrderWrapper.OrderResponse getOrderSimulationResponse(){
        ECOM_SimulateOrderWrapper.OrderResponse cachedRequest = new ECOM_SimulateOrderWrapper.OrderResponse();
        Object cachedData = Cache.Session.get('local.EcomCache.responseData');
        cachedRequest = (ECOM_SimulateOrderWrapper.OrderResponse)JSON.deserializeStrict (String.valueOf(cachedData),ECOM_SimulateOrderWrapper.OrderResponse.class);
        
        return cachedRequest;
    }
    
    /**
    * @description //to check if order simulation is cached
    * @author mkumar@rafter.one | 09-01-2023 
    * @param orderRequest 
    * @return Boolean 
    **/
    public static Boolean isOrderSimulationCached(ECOM_SimulateOrderWrapper.OrderRequest orderRequest){
        Boolean isOSCached = true;
        String requestKey = 'requestData';
        String responseKey = 'responseData';
        if(Cache.Session.contains(requestKey) && Cache.Session.contains(responseKey)){
            ECOM_SimulateOrderWrapper.OrderRequest cachedRequest  = getOrderSimulationRequest();
            ECOM_SimulateOrderWrapper.OrderResponse cachedResponse  = getOrderSimulationResponse();
            Map<String,ECOM_SimulateOrderWrapper.Item> producttoItemMap = new Map<String,ECOM_SimulateOrderWrapper.Item>();
            for(ECOM_SimulateOrderWrapper.Item cachedItem : cachedRequest.product_list){
                producttoItemMap.put(cachedItem.part_number,cachedItem);
            }
            if(cachedRequest.bill_to==orderRequest.bill_to && cachedRequest.Ship_to==orderRequest.Ship_to
               && cachedRequest.promo_code==orderRequest.promo_code  && cachedRequest.payment_type==orderRequest.payment_type 
               && cachedRequest.po_no==orderRequest.po_no   && cachedRequest.product_list.size()==orderRequest.product_list.size() 
               && cachedRequest.cart_id==orderRequest.cart_id
              ){
                  for(ECOM_SimulateOrderWrapper.Item currentItem : orderRequest.product_list){
                      if(producttoItemMap.containsKey(currentItem.part_number)){
                          if(!(producttoItemMap.get(currentItem.part_number).quantity==currentItem.quantity)){
                              isOSCached = false;
                              break;
                          }
                      }else{
                          isOSCached = false;
                          break;
                      }
                  }
                  
              }else{
                  isOSCached = false;
              }
        }else{
            isOSCached = false;
        }
        return isOSCached;
    }

    public static void clearEcomCache(){
        if(Cache.Session.contains('local.EcomCache.'+requestKey)){
            Boolean isRequestCleared = Cache.Session.remove('local.EcomCache.'+requestKey);
        }
        if(Cache.Session.contains('local.EcomCache.'+responseKey)){
            Boolean isResponseCleared = Cache.Session.remove('local.EcomCache.'+responseKey);
        }
    }
    
    
}