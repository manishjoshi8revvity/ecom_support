/**************************************************************

* 1. Jira Ticket(s) that relates to this class
*  
*
* 2. Description - This is a test class
*
* 3. Objects referenced
*    - WebCart
*	 

* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
*    - ECOM_TestUtil
*    - ECOM_SimulateOrderWrapper
 
* 6. Test Class Name:
*
* 7. Is @Invocable : No
*
* 8. Author Name(s):
*    - Sukumar 2023.09.21
*************************************************************/
@isTest
public class ECOM_SessionCacheUtil_Test {
    @TestSetup
    public static void testSetupData()
    {
        ECOM_TestUtil.initialStorefrontSetup();
    }
    @isTest
    static void testSetGetSessionCache() {
        
        ECOM_SessionCacheUtil util = new ECOM_SessionCacheUtil();
        String key = 'testKey';
        String value = 'testValue';
        
        Test.startTest();
        util.setSessionCache(key, value);        
        Object cachedData = util.getSessionCache(key);
        Test.stopTest();

        System.assertEquals(value, cachedData);
    }
    
    @isTest
    static void testGetOrderSimulationRequest() {
        User u = [Select Id,LastName From User ORDER BY CREATEDDATE DESC LIMIT 1];
        ECOM_SimulateOrderWrapper.OrderRequest request = new ECOM_SimulateOrderWrapper.OrderRequest();
        
        String key = 'testKey';
        String value = 'testValue';

        // Cache the request
        Cache.Session.put('local.EcomCache.requestData', JSON.serialize(request), 28800);

        Test.startTest();
        ECOM_SimulateOrderWrapper.OrderRequest cachedRequest;
        System.runAs(u){
            cachedRequest = ECOM_SessionCacheUtil.getOrderSimulationRequest();
        }
         
        Test.stopTest();

        // Assert the retrieved request matches the cached request
        System.assertEquals(request.bill_to, cachedRequest.bill_to);
        System.assertEquals(request.Ship_to, cachedRequest.Ship_to);
        System.assertEquals(request.country, cachedRequest.country);
        System.assertEquals(request.requested_date, cachedRequest.requested_date);
        System.assertEquals(request.promo_code, cachedRequest.promo_code);
        System.assertEquals(request.cart_id, cachedRequest.cart_id);
        System.assertEquals(request.payment_type, cachedRequest.payment_type);
        System.assertEquals(request.po_no, cachedRequest.po_no);
        }
        @IsTest
        static void testGetOrderSimulationResponse() {
        ECOM_SimulateOrderWrapper.OrderResponse response = new ECOM_SimulateOrderWrapper.OrderResponse();
                
        String key = 'testKey';
        String value = 'testValue';
        // Set up your test data

        // Cache the response
        Cache.Session.put('local.EcomCache.responseData', JSON.serialize(response), 28800);
        
        Test.startTest();
        ECOM_SimulateOrderWrapper.OrderResponse cachedResponse = ECOM_SessionCacheUtil.getOrderSimulationResponse();
        Test.stopTest();        

        // System.assertEquals(request.bill_to, cachedResponse.bill_to, 'billto shoud match');
        // System.assertEquals(request.Ship_to, cachedResponse.Ship_to, 'Shipto shoud match');
        // System.assertEquals(response, cachedResponse);
        }
        @IsTest
        static void testIsOrderSimulationCached() {
               
        ECOM_SimulateOrderWrapper.OrderRequest obj = new ECOM_SimulateOrderWrapper.OrderRequest();
        // Set up your test data
        obj.bill_to='2349';
        obj.country='Canada';
        obj.cart_id=[SELECT Id from WebCart ORDER By CREATEDDATE DESC LIMIT 1].Id;
        obj.payment_type='Card';
        obj.po_no='34';
        List<ECOM_SimulateOrderWrapper.Item> itm = new List<ECOM_SimulateOrderWrapper.Item>();
        ECOM_SimulateOrderWrapper.Item record= new ECOM_SimulateOrderWrapper.Item();
        record.item_number=1234;
        record.part_number='987';
        record.quantity=45;
        itm.add(record);
        obj.product_list=itm;
        obj.promo_code='Discount125';
        obj.requested_date=Date.today();
        obj.Ship_to='US';      
         
        // Cache the request and response
        Cache.Session.put('local.EcomCache.requestData', JSON.serialize(obj), 28800);
        Cache.Session.put('local.EcomCache.responseData', JSON.serialize(new ECOM_SimulateOrderWrapper.OrderResponse()), 28800);

        // ECOM_SessionCacheUtil util = new ECOM_SessionCacheUtil();
        Boolean isCached = ECOM_SessionCacheUtil.isOrderSimulationCached(obj);

        //System.assertEquals(true, isCached);
        }
    
    	@isTest
    	static void testClearEcomCache() {
                
        Test.startTest();
        ECOM_SessionCacheUtil.clearEcomCache();        
        Test.stopTest();
            
    	}
    }