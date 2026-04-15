@IsTest
public class FS_WorkDetail_UT {
    @testSetup
    static void setup() {
         
        Profile p = [SELECT Id, Name, UserType FROM Profile where Name='System Administrator'];
        User u = new User();
        u.Alias='TestUs';
        u.Email='testUs@gmail.com';
        u.EmailEncodingKey='UTF-8';
        u.LastName='xyz';
        u.LanguageLocaleKey='en_US';
        u.LocaleSidKey='en_US';
        u.TimeZoneSidKey='America/Los_Angeles';
        u.Username='testuserabec@00do90000022rb3mam.ext';
        u.ProfileId=p.Id;
      //  u.ContactId=con.Id;
        insert u;

        
     	Account acc= new Account();
        acc.Name='Test Account';
        insert acc;
        
        Contact con = new Contact();
        con.FirstName='New';
        con.LastName='Test';
        con.AccountId=acc.Id;
        insert con;
        
    
        Schema.Location loc2 = new Schema.Location();
        loc2.Name='Test2';
        loc2.IsInventoryLocation=true;
        loc2.IsMobile= true;
        loc2.LocationType='Depot';
        loc2.MaintenancePlant__c='test';
        loc2.SalesOrg__c='Sale';
      
        insert loc2;
        
        Product2 prod= new Product2();
		prod.Name='Test';        
        insert prod;
                
        ProductItem prodItem = new ProductItem();
        prodItem.Product2Id=prod.Id;
        prodItem.LocationId=loc2.Id;
        prodItem.QuantityOnHand = 10;
        insert prodItem;
        
        Product_Sales__c prodSales = new Product_Sales__c();
        prodSales.Product__c=prod.Id;
        insert prodSales;
        
        Asset asst = new Asset();
        asst.Name='Test Asset Id';
        asst.LocationId = loc2.Id;
        asst.AccountId=acc.id;
        asst.CatalogProfile__c='DAS';
        asst.Product2Id=prod.Id;
        asst.ContactId=con.Id;
        insert asst;
             
        FS_ProductPlant__c pp = new FS_ProductPlant__c();
        pp.HSN_Code__c='HS10';
        pp.Plant__c='test';
        pp.Product__c=prod.Id;
        pp.Return_Part__c=prod.Id;
        pp.Return_Part_Number__c='12345';
        insert pp;
        
     	WorkOrder wo = new WorkOrder();
        wo.CurrencyIsoCode='INR';
        wo.Record_Type__c='Estimate';
        wo.ContactId=con.Id;
        wo.AccountId=acc.Id;
        wo.AssetId=asst.Id;
        wo.External_ID__c='GBA2F003';
        wo.SAP_Notification_ID__c='tessj6544';
        wo.LocationId=loc2.Id;
      //  wo.Any_Parts_Eligible_for_Return__c=false;
     
     	insert wo;

		FS_FaultCodeGroup__c fcgrp = new FS_FaultCodeGroup__c();

		insert fcgrp;
        
         ServiceResource tech1 = new ServiceResource(
            Name='Test',
            Plant__c = 'GBA1',
            LocationId=loc2.Id,
            RelatedRecordId=UserInfo.getUserId(),
            LocationCode__c = 'F006',
            External_ID__c='GBA2F006'
         );
       
        insert new List<ServiceResource>{tech1};
        
        FS_FaultCode__c fc = new FS_FaultCode__c();
        fc.Name='Fault code1';
        fc.Code_Description__c='Advised';//Advised~AC01
        fc.Code__c='AC01';
        fc.Complaint_Required__c=0;
        fc.Fault_Code_Group__c=fcgrp.Id;
        insert fc;
        
        FS_FaultCode__c fc2 = new FS_FaultCode__c();
        fc2.Name='Fault code1';
        fc2.Code_Description__c='Advised';//Advised~AC01
        fc2.Code__c='AC01';
        fc2.Complaint_Required__c=0;
        fc2.Fault_Code_Group__c=fcgrp.Id;
        insert fc2;
        
        FS_FaultCode__c fc3 = new FS_FaultCode__c();
        fc3.Name='Fault code1';
        fc3.Code_Description__c='Application Problems';//IN01 - Application Problems
        fc3.Code__c='IN01';
        fc3.Complaint_Required__c=0;
        fc3.Fault_Code_Group__c=fcgrp.Id;
        insert fc3;
        
        FS_FaultCode__c fc4 = new FS_FaultCode__c();
        fc4.Name='Fault code1';
        fc4.Code_Description__c='Additional Parts Required';//JC02 ~ Additional Parts Required
        fc4.Code__c='JC02';
        fc4.Complaint_Required__c=0;
        fc4.Fault_Code_Group__c=fcgrp.Id;
        insert fc4;
            
        WorkOrderLineItem edli = new WorkOrderLineItem(
            WorkOrderId=wo.id,
            Work_Description__c='Dorelan makes bedroom products and pieces of furniture. Enter on the official website: Dorelan - Dormire bene Vivere meglio.',
            Product_Plant__c=pp.Id,	
            Status='Priced',
            Consumed_Product_Stock__c=prodItem.Id,
            Travel_Labor_Product__c= ProdSales.Id,
            SAP_Confirmation__c='Test',
            CancellationNumber__c='5',
            Line_Type__c='Parts',
            Fault_Code__c =fc.id,
            ActionFaultCode__c =fc2.id,
            InstallationFaultCode__c = fc3.id,
            CompletionFaultCode__c = fc4.id,
            Service_Resource__c = tech1.id,
            Use_Product_Sales_UOM__c= false
        );
        insert edli;
        
        FS_IntegrationError__c intError = new FS_IntegrationError__c();
        
        insert intError;
        
     //   SELECT Id, Name
	//		FROM ServiceResource WHERE RelatedRecordId = :UserInfo.getUserId()];

        
    }
    @isTest
    static void addWorkSummaryTest(){
        
        List<WorkOrderLineItem> newList =[Select Id, Work_Description__c,CurrencyIsoCode,Material_Part_Description__c,WorkSummary__c,fxHSN_Code__c,Concat_Part_Work_Description__c
                                          from WorkOrderLineItem];
        Test.startTest();
        FS_WorkDetailManager.addWorkSummary(newList);
        Test.stopTest();
    }
    
    @isTest
    static void addsummaryAfterTest(){
         List<WorkOrderLineItem> newList =[Select Id, Work_Description__c,CurrencyIsoCode,WorkOrderId,Material_Part_Description__c,WorkSummary__c,fxHSN_Code__c,Concat_Part_Work_Description__c
                                          from WorkOrderLineItem];
        Map<Id, WorkOrderLineItem> oldMap = new Map<Id,WorkOrderLineItem >( [Select Id,WorkOrderId, Work_Description__c,CurrencyIsoCode,Material_Part_Description__c,WorkSummary__c,fxHSN_Code__c,Concat_Part_Work_Description__c
                                          from WorkOrderLineItem]);
        Test.startTest();
        FS_WorkDetailManager.addsummaryAfter(newList,oldMap);
        Test.stopTest();
        
    }
    @isTest
    static void cancelLinesTest(){
         List<WorkOrderLineItem> newListUp =[Select Id, Work_Description__c,IntegrationStatus__c,CurrencyIsoCode,SubmitTxnId__c,WorkOrderId,Material_Part_Description__c,Status,WorkSummary__c,fxHSN_Code__c,Concat_Part_Work_Description__c
                                          from WorkOrderLineItem];
         Map<Id, WorkOrderLineItem> oldMap = new Map<Id,WorkOrderLineItem >( [Select Id,WorkOrderId,SubmitTxnId__c, Work_Description__c,IntegrationStatus__c,Status,CurrencyIsoCode,Material_Part_Description__c,WorkSummary__c,fxHSN_Code__c,Concat_Part_Work_Description__c
                                          from WorkOrderLineItem where Id=:newListUp[0].Id ]);
        newListUp[0].IntegrationStatus__c='Pending';
        newListUp[0].Status='Canceled';
        update newListUp[0];
       
        Test.startTest();
        FS_WorkDetailManager.cancelLines(newListUp,oldMap);
        Test.stopTest();
        
        System.assertEquals('Canceled',newListUp[0].Status,'Status should be Canceled.');
        
    }
    
    @isTest
    static void copyRelatedDataTest(){
         List<WorkOrderLineItem> newListUp =[Select Id, Work_Description__c,Part__c,Consumed_Product_Stock__c,Travel_Labor_Product__c,IntegrationStatus__c,CurrencyIsoCode,SubmitTxnId__c,WorkOrderId,Material_Part_Description__c,Status,WorkSummary__c,fxHSN_Code__c,Concat_Part_Work_Description__c
                                          from WorkOrderLineItem];
         Map<Id, WorkOrderLineItem> oldMap = new Map<Id,WorkOrderLineItem >( [Select Id,Part__c,WorkOrderId,Travel_Labor_Product__c,Consumed_Product_Stock__c,SubmitTxnId__c, Work_Description__c,IntegrationStatus__c,Status,CurrencyIsoCode,Material_Part_Description__c,WorkSummary__c,fxHSN_Code__c,Concat_Part_Work_Description__c
                                          from WorkOrderLineItem where Id=:newListUp[0].Id ]);
       
        newListUp[0].Part__c=null;
       // newListUp[0].Travel_Labor_Product__c='';
        update newListUp[0];
       	ProductItem itemMap = [SELECT Id, Product2Id	FROM ProductItem WHERE Id =:newListUp[0].Consumed_Product_Stock__c];
       	Product_Sales__c salesMap = [SELECT Id, Product__c FROM Product_Sales__c WHERE Id =: newListUp[0].Travel_Labor_Product__c];
        
        Test.startTest();
        	FS_WorkDetailManager.copyRelatedData(newListUp);
        Test.stopTest();
        
        System.assertEquals(itemMap.Product2Id,newListUp[0].Part__c,'Part__c should be Same.');
        System.assertEquals(salesMap.Product__c,newListUp[0].Part__c,'Part__c should be Same.');
        
    }
     @isTest
    static void deleteWorkDetailRecordsTest(){
         List<WorkOrderLineItem> newListUp =[Select Id, Work_Description__c,Part__c,Delete_Line__c,Consumed_Product_Stock__c,Travel_Labor_Product__c,IntegrationStatus__c,CurrencyIsoCode,SubmitTxnId__c,WorkOrderId,Material_Part_Description__c,Status,WorkSummary__c,fxHSN_Code__c,Concat_Part_Work_Description__c
                                          from WorkOrderLineItem];
         Map<Id, WorkOrderLineItem> oldMap = new Map<Id,WorkOrderLineItem >( [Select Id,Delete_Line__c,Part__c,WorkOrderId,Travel_Labor_Product__c,Consumed_Product_Stock__c,SubmitTxnId__c, Work_Description__c,IntegrationStatus__c,Status,CurrencyIsoCode,Material_Part_Description__c,WorkSummary__c,fxHSN_Code__c,Concat_Part_Work_Description__c
                                          from WorkOrderLineItem where Id=:newListUp[0].Id ]);
       
        newListUp[0].Delete_Line__c=true;
       
        update newListUp[0];
       
        Test.startTest();
       // delete newListUp[0];
        	FS_WorkDetailManager.deleteWorkDetailRecords(newListUp,oldMap);
        Test.stopTest();   
    }
     @isTest
    static void logDuplicateErrorsTest(){
         List<WorkOrderLineItem> newListUp =[Select Id, Work_Description__c,Part__c,Delete_Line__c,SAP_Confirmation__c,Consumed_Product_Stock__c,
                                             Travel_Labor_Product__c,IntegrationStatus__c,CurrencyIsoCode,SubmitTxnId__c,WorkOrderId,Material_Part_Description__c,
                                             Status,WorkSummary__c,fxHSN_Code__c,Concat_Part_Work_Description__c,CancellationNumber__c
                                          from WorkOrderLineItem];
         Map<Id, WorkOrderLineItem> oldMap = new Map<Id,WorkOrderLineItem >( [Select Id,Delete_Line__c,SAP_Confirmation__c,Part__c,WorkOrderId,
                                                                              Travel_Labor_Product__c,Consumed_Product_Stock__c,SubmitTxnId__c, Work_Description__c,
                                                                              IntegrationStatus__c,Status,CurrencyIsoCode,Material_Part_Description__c,WorkSummary__c,fxHSN_Code__c,
                                                                              Concat_Part_Work_Description__c,CancellationNumber__c
                                          from WorkOrderLineItem where Id=:newListUp[0].Id ]);
       
        newListUp[0].SAP_Confirmation__c='true Test';
        newListUp[0].CancellationNumber__c='10';
       
       // update newListUp[0];
       
        Test.startTest();
        //	FS_WorkDetailManager.logDuplicateErrors(newListUp,oldMap);
        Test.stopTest();   
    }
     @isTest
    static void lookupProductPlantTest(){
         Schema.Location loc = new Schema.Location();
        loc.Name='Test2';
        loc.IsInventoryLocation=true;
        loc.LocationType='Depot';
      
        insert loc;
        
        Product2 prod= new Product2();
		prod.Name='Test';        
        insert prod;
                
        ProductItem prodItem2 = new ProductItem();
        prodItem2.Product2Id=prod.Id;
        prodItem2.LocationId=loc.Id;
        prodItem2.QuantityOnHand = 12;
        insert prodItem2;
        List<WorkOrderLineItem> newListUp =[Select Id, Work_Description__c,Part__c,Delete_Line__c,SAP_Confirmation__c,Consumed_Product_Stock__c,
                                             Travel_Labor_Product__c,Line_Type__c,IntegrationStatus__c,CurrencyIsoCode,SubmitTxnId__c,WorkOrderId,Material_Part_Description__c,
                                             Status,WorkSummary__c,fxHSN_Code__c,Concat_Part_Work_Description__c,CancellationNumber__c,Product_Plant__c,Eligible_for_Return__c
                                          from WorkOrderLineItem];
         Map<Id, WorkOrderLineItem> oldMap = new Map<Id,WorkOrderLineItem >( [Select Id,Delete_Line__c,SAP_Confirmation__c,Part__c,WorkOrderId,
                                                                              Travel_Labor_Product__c,Consumed_Product_Stock__c,SubmitTxnId__c, Work_Description__c,
                                                                              IntegrationStatus__c,Status,CurrencyIsoCode,Material_Part_Description__c,WorkSummary__c,fxHSN_Code__c,
                                                                              Concat_Part_Work_Description__c,CancellationNumber__c,Line_Type__c,Product_Plant__c,Eligible_for_Return__c
                                          from WorkOrderLineItem where Id=:newListUp[0].Id ]);
       
        newListUp[0].SAP_Confirmation__c='true Test';
        newListUp[0].CancellationNumber__c='10';
        newListUp[0].Consumed_Product_Stock__c=prodItem2.Id;
        newListUp[0].Eligible_for_Return__c=true;
       
        update newListUp[0];
       
        Test.startTest();
        	FS_WorkDetailManager.lookupProductPlant(newListUp,oldMap);
        Test.stopTest();   //toggleIntegrationStatus
    }
    
      @isTest
    static void toggleIntegrationStatusTest(){
        
        List<WorkOrderLineItem> newListUp =[Select Id, Work_Description__c,Part__c,Delete_Line__c,SAP_Confirmation__c,Consumed_Product_Stock__c,
                                             Travel_Labor_Product__c,Line_Type__c,IntegrationStatus__c,CurrencyIsoCode,SubmitTxnId__c,WorkOrderId,Material_Part_Description__c,
                                             Status,WorkSummary__c,fxHSN_Code__c,Concat_Part_Work_Description__c,CancellationNumber__c,Product_Plant__c,Eligible_for_Return__c
                                          from WorkOrderLineItem];
         Map<Id, WorkOrderLineItem> oldMap = new Map<Id,WorkOrderLineItem >( [Select Id,Delete_Line__c,SAP_Confirmation__c,Part__c,WorkOrderId,
                                                                              Travel_Labor_Product__c,Consumed_Product_Stock__c,SubmitTxnId__c, Work_Description__c,
                                                                              IntegrationStatus__c,Status,CurrencyIsoCode,Material_Part_Description__c,WorkSummary__c,fxHSN_Code__c,
                                                                              Concat_Part_Work_Description__c,CancellationNumber__c,Line_Type__c,Product_Plant__c,Eligible_for_Return__c
                                          from WorkOrderLineItem where Id=:newListUp[0].Id ]);
       
        newListUp[0].Status = 'Submitted';
        
        update newListUp[0];
       
        Test.startTest();
        	FS_WorkDetailManager.toggleIntegrationStatus(newListUp,oldMap);
        Test.stopTest();   
    }
     @isTest
    static void updateDetailLineAndIntegrationStatusTest(){
        
        List<WorkOrderLineItem> newListUp =[Select Id, Work_Description__c,Part__c,Delete_Line__c,SAP_Confirmation__c,Consumed_Product_Stock__c,
                                             Travel_Labor_Product__c,Line_Type__c,IntegrationStatus__c,CurrencyIsoCode,SubmitTxnId__c,WorkOrderId,Material_Part_Description__c,
                                             Status,WorkSummary__c,fxHSN_Code__c,Concat_Part_Work_Description__c,CancellationNumber__c,Product_Plant__c,Eligible_for_Return__c
                                          from WorkOrderLineItem];
         Map<Id, WorkOrderLineItem> oldMap = new Map<Id,WorkOrderLineItem >( [Select Id,Delete_Line__c,SAP_Confirmation__c,Part__c,WorkOrderId,
                                                                              Travel_Labor_Product__c,Consumed_Product_Stock__c,SubmitTxnId__c, Work_Description__c,
                                                                              IntegrationStatus__c,Status,CurrencyIsoCode,Material_Part_Description__c,WorkSummary__c,fxHSN_Code__c,
                                                                              Concat_Part_Work_Description__c,CancellationNumber__c,Line_Type__c,Product_Plant__c,Eligible_for_Return__c
                                          from WorkOrderLineItem where Id=:newListUp[0].Id ]);
       
        newListUp[0].Status = 'Confirmed';
        newListUp[0].SAP_Confirmation__c='';
        
        update newListUp[0];
       
        Test.startTest();
        	FS_WorkDetailManager.updateDetailLineAndIntegrationStatus(newListUp,oldMap);
        Test.stopTest();   
    }
    
     @isTest
    static void updateFaultCodesTest(){
        
        List<WorkOrderLineItem> newListUp =[Select Id,Eligible_for_Return__c,SAP_Confirmation__c,
                                            Fault_Code__c,ActionFaultCode__c,InstallationFaultCode__c,CompletionFaultCode__c,Fault_Code_Complaint_Required__c
                                          from WorkOrderLineItem];
         Map<Id, WorkOrderLineItem> oldMap = new Map<Id,WorkOrderLineItem >( [Select Id,Line_Type__c,SAP_Confirmation__c,Product_Plant__c,Eligible_for_Return__c,
                                                                              Fault_Code__c,ActionFaultCode__c,InstallationFaultCode__c,CompletionFaultCode__c,Fault_Code_Complaint_Required__c
                                          from WorkOrderLineItem where Id=:newListUp[0].Id ]);
       
        newListUp[0].Line_Type__c='Fault Code';
        
        update newListUp[0];
       
        Test.startTest();
        	FS_WorkDetailManager.updateFaultCodes(newListUp,oldMap);
        Test.stopTest();   
    }
    @isTest
    static void updateFieldValuesTest(){
        
        List<WorkOrderLineItem> newListUp =[Select Id,Eligible_for_Return__c,SAP_Confirmation__c,Quantity__c,
                                            Fault_Code__c,ActionFaultCode__c,InstallationFaultCode__c,CompletionFaultCode__c,Fault_Code_Complaint_Required__c
                                          from WorkOrderLineItem];
         Map<Id, WorkOrderLineItem> oldMap = new Map<Id,WorkOrderLineItem >( [Select Id,Line_Type__c,SAP_Confirmation__c,Product_Plant__c,Eligible_for_Return__c,Quantity__c,
                                                                              Fault_Code__c,ActionFaultCode__c,InstallationFaultCode__c,CompletionFaultCode__c,Fault_Code_Complaint_Required__c
                                          from WorkOrderLineItem where Id=:newListUp[0].Id ]);
       
        newListUp[0].Line_Type__c='Travel';
        newListUp[0].Quantity__c=10;
        newListUp[0].ServiceAmountAdjustmentType__c=null;
        newListUp[0].ServicePercentAdjustmentType__c=null;
        newListUp[0].ServiceAmountAdjustment__c=10;
        newListUp[0].ServicePercentAdjustment__c=5;
        
        update newListUp[0];
       
        Test.startTest();
        	FS_WorkDetailManager.updateFieldValues(newListUp,oldMap);
        Test.stopTest();   
        
        System.assertEquals('Uplift',newListUp[0].ServiceAmountAdjustmentType__c,'ServiceAmountAdjustmentType__c should not be null');
        System.assertEquals('Uplift',newListUp[0].ServicePercentAdjustmentType__c,'ServicePercentAdjustmentType__c should not be null');
    }
    @isTest
    static void updateTechOnDebriefLineTest(){
        
        List<WorkOrderLineItem> newListUp =[Select Id,Eligible_for_Return__c,SAP_Confirmation__c,Quantity__c,Service_Resource__c,
                                            Fault_Code__c,ActionFaultCode__c,InstallationFaultCode__c,CompletionFaultCode__c,Fault_Code_Complaint_Required__c
                                          from WorkOrderLineItem];
         Map<Id, WorkOrderLineItem> oldMap = new Map<Id,WorkOrderLineItem >( [Select Id,Line_Type__c,SAP_Confirmation__c,Product_Plant__c,Eligible_for_Return__c,Quantity__c,Service_Resource__c,
                                                                              Fault_Code__c,ActionFaultCode__c,InstallationFaultCode__c,CompletionFaultCode__c,Fault_Code_Complaint_Required__c
                                          from WorkOrderLineItem where Id=:newListUp[0].Id ]);
       
        newListUp[0].Record_Type__c='Usage';        
        update newListUp[0];
       
        Test.startTest();
        	FS_WorkDetailManager.updateTechOnDebriefLine(newListUp,oldMap);
        Test.stopTest();   
        
    }
    
     @isTest
    static void updateWorkDetailPlantAndWorkCenterTest(){
        
        List<WorkOrderLineItem> newListUp =[Select Id,Eligible_for_Return__c,SAP_Confirmation__c,Quantity__c,Service_Resource__c,Work_Center__c,Plant__c, 
                                            Fault_Code__c,ActionFaultCode__c,InstallationFaultCode__c,CompletionFaultCode__c,Fault_Code_Complaint_Required__c
                                          from WorkOrderLineItem];
         Map<Id, WorkOrderLineItem> oldMap = new Map<Id,WorkOrderLineItem >( [Select Id,Line_Type__c,SAP_Confirmation__c,Product_Plant__c,Work_Center__c,Eligible_for_Return__c,Quantity__c,Service_Resource__c,
                                                                              Fault_Code__c,ActionFaultCode__c,InstallationFaultCode__c,CompletionFaultCode__c,Fault_Code_Complaint_Required__c,Plant__c
                                          from WorkOrderLineItem where Id=:newListUp[0].Id ]);
       
        newListUp[0].Record_Type__c='Usage';
        newListUp[0].Line_Type__c = 'Labor'; 
        newListUp[0].Work_Center__c= 'ghjh';
         //newListUp[0].Service_Resource__c='';
        update newListUp[0];
       
        Test.startTest();
        	FS_WorkDetailManager.updateWorkDetailPlantAndWorkCenter(newListUp,oldMap);
        Test.stopTest();   
        
    }
      @isTest
    static void updateUnitOfMeasureCodesThreeParameterTest(){
        
        List<WorkOrderLineItem> newListUp =[Select Id,Eligible_for_Return__c,SAP_Confirmation__c,Use_Product_Sales_UOM__c,Quantity__c,Service_Resource__c,Work_Center__c,Plant__c, 
                                            Fault_Code__c,ActionFaultCode__c,UOM_Code__c,WorkOrderId,InstallationFaultCode__c,Product2Id,CompletionFaultCode__c,Fault_Code_Complaint_Required__c
                                          from WorkOrderLineItem];
         Map<Id, WorkOrderLineItem> oldMap = new Map<Id,WorkOrderLineItem >( [Select Id,Line_Type__c,UnitOfMeasure__c,SAP_Confirmation__c,Product_Plant__c,Work_Center__c,
                                                                              Eligible_for_Return__c,Quantity__c,Service_Resource__c,Use_Product_Sales_UOM__c,Product2Id,
                                                                              Fault_Code__c,UOM_Code__c,WorkOrderId,ActionFaultCode__c,InstallationFaultCode__c,CompletionFaultCode__c,Fault_Code_Complaint_Required__c,Plant__c
                                          from WorkOrderLineItem where Id=:newListUp[0].Id ]);
       
        newListUp[0].Use_Product_Sales_UOM__c= true;
        newListUp[0].UnitOfMeasure__c=null;
        update newListUp[0];
       
        Test.startTest();
        	FS_WorkDetailManager.updateUnitOfMeasureCodes(newListUp,oldMap);
        Test.stopTest();   
        
    }
 @isTest
    static void updateUnitOfMeasureCodesTest(){
        
        WorkOrderLineItem newListUp =[Select Id,Eligible_for_Return__c,SAP_Confirmation__c,Use_Product_Sales_UOM__c,Quantity__c,Service_Resource__c,Work_Center__c,Plant__c, 
                                            Fault_Code__c,ActionFaultCode__c,UOM_Code__c,WorkOrderId,InstallationFaultCode__c,Product2Id,CompletionFaultCode__c,Fault_Code_Complaint_Required__c
                                          from WorkOrderLineItem];
              
        newListUp.Use_Product_Sales_UOM__c= true;
        newListUp.UnitOfMeasure__c=null;
        update newListUp;
        
        Product2 prod= new Product2();
		prod.Name='Test';
		prod.QuantityUnitOfMeasure='SET';        
        insert prod;
       
        
        Product_Sales__c prodSales = new Product_Sales__c();
        prodSales.Product__c=prod.Id;
        prodSales.Sales_Org__c='Sale';
        prodSales.External_ID__c='123456rgsd';
        insert prodSales;
        
         String salesOrg='Sale';
       
        Test.startTest();
        	FS_WorkDetailManager.updateUnitOfMeasureCodes(newListUp,salesOrg,prod);
        Test.stopTest();   
        
    }
    
}