/**
 * @description       : 
 * @author            : mkumar@rafter.one
 * @group             : 
 * @last modified on  : 11-10-2023
 * @last modified by  : mkumar@rafter.one
 * - Gaurav Bhansali 2025.08.25 - Added freeItemParent property - RWPS-3811

**/
public with sharing class ECOM_DataLayerModel {
	@auraEnabled public String id;	
	@auraEnabled public String name;	
	@auraEnabled public String currencyCode;	
	@auraEnabled public String type;
	@auraEnabled public String productClass;	
	@auraEnabled public String bussinessUnit;
	@auraEnabled public String subBussinessUnit;
	@auraEnabled public String superBussinessUnit;
	@auraEnabled public String discountType;	
	@auraEnabled public String partNumber;	
	@auraEnabled public String partType;	
	@auraEnabled public String igorDescription;	
	@auraEnabled public String productLine;	
	@auraEnabled public String productLineName;
	@auraEnabled public Integer quantity; 
	@auraEnabled public String productId;  
	@auraEnabled public Decimal price;  
	@auraEnabled public Decimal listPrice;  
	@auraEnabled public Decimal totalPrice;
	@auraEnabled public Decimal sapStatus;
	@auraEnabled public Decimal hasImage;  
	@auraEnabled public String paccode;	
	@auraEnabled public String freeItemParent; //RWPS-3811

}