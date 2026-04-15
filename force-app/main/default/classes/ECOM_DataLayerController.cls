/**
 * @description       : 
 * @author            : mkumar@rafter.one
 * @group             : 
 * @last modified on  : 10-24-2023
 * @last modified by  : mkumar@rafter.one
**/
public with sharing class ECOM_DataLayerController {
  
    /**
    * @description 
    * @author mkumar@rafter.one | 10-24-2023 
    * @param cartId 
    * @return Map<String, Object> 
    **/
    
    @AuraEnabled
    public static  Map<String,Object> getDataLayerDataByCart(String cartId){ 
        Map<String,Object> response = new Map<String,Object>();
        List<WebCart> activeCarts = ECOM_CartRepo.getCartandCartItemsById(cartId);
        WebCart cart = activeCarts.size() > 0?activeCarts.get(0) : null;
        Set<String> productIds = new Set<String>();
            
            for(CartItem item : cart.CartItems) {
              productIds.add(item.Product2Id);
            }
        String moduleName = 'ECOM_CartService';
        List<String> materialCodes = ECOM_CartUtil.fetchProductMaterialStatus(moduleName);
        List<Product_Sales__c> prodSales = ECOM_ProductService.getProductSales(productIds, materialCodes);
        Map<String,String> productToSalesStatus = new Map<String,String>();
            
            for (Product_Sales__c prod : prodSales) {
              productToSalesStatus.put(prod.Product__c, prod.Distribution_ChainSpecificMaterialStatus__c);
            }
        response.put('dataLayer',ECOM_Util.parseDataLayerModel(activeCarts));
        response.put('productSalesStatus',productToSalesStatus);
        response.put('cart',activeCarts.size() > 0 ? activeCarts[0]: null);
        System.debug('_______________________________responseData_______'+response);
        
        return response;           
    }

    /**
    * @description 
    * @author mkumar@rafter.one | 10-24-2023 
    * @param orderId 
    * @return Map<String, Object> 
    **/
    @AuraEnabled
    public static  Map<String,Object> getDataLayerDataByOrder(String orderId){ 
        Map<String,Object> response = new Map<String,Object>();
        List<Order> orders = ECOM_OrderRepo.getOrderById(orderId);
        System.debug('___________DatalyrController_orders______-'+orders);
        Order orderFetched = orders.size() > 0?orders.get(0) : null;
        Set<String> productIds = new Set<String>();
            
            for(OrderItem item : orderFetched.OrderItems) {
              productIds.add(item.Product2Id);
            }
        String moduleName = 'ECOM_CartService';
        List<String> materialCodes = ECOM_CartUtil.fetchProductMaterialStatus(moduleName);
        List<Product_Sales__c> prodSales = ECOM_ProductService.getProductSales(productIds, materialCodes);
        Map<String,String> productToSalesStatus = new Map<String,String>();
           
            for (Product_Sales__c prod : prodSales) {
              productToSalesStatus.put(prod.Product__c, prod.Distribution_ChainSpecificMaterialStatus__c);
            }
            System.debug('______________--ordersss_________________-'+orders);
        response.put('dataLayer',ECOM_Util.parseOrderDataLayerModel(orders));
        response.put('productSalesStatus',productToSalesStatus);
        response.put('order',orders.size() > 0 ? orders[0]: null);
        
        return response;           
    }

    /**
    * @description 
    * @author mkumar@rafter.one | 10-24-2023 
    * @param favItems 
    * @return Map<String, Object> 
    **/
    
    public static  Map<String,Object> getDataLayerDataByWishlistItem(Set<WishListItem> favItems){ 
        Map<String,Object> response = new Map<String,Object>();
        List<WishListItem> favItemsList = new List<WishListItem>(favItems);
        Set<String> productIds = new Set<String>();
             
            for (Integer i = 0; i<favItemsList.size(); i++) {
                productIds.add(favItemsList[i].Product2Id);
            }
        
        String moduleName = 'ECOM_CartService';
        List<String> materialCodes = ECOM_CartUtil.fetchProductMaterialStatus(moduleName);
        List<Product_Sales__c> prodSales = ECOM_ProductService.getProductSales(productIds, materialCodes);
        Map<String,String> productToSalesStatus = new Map<String,String>();
              
            for (Product_Sales__c prod : prodSales) {
                productToSalesStatus.put(prod.Product__c, prod.Distribution_ChainSpecificMaterialStatus__c);
            }
        response.put('productSalesStatus',productToSalesStatus);
       
        return response;           
    }

}