/**************************************************************
* 1. Jira Ticket(s)
*    - MTL-1 Monthly Tracking Log
*
* 2. Description - This apex class is used to create Monthly Tracking Log records by parsing data coming as an email from SAP invoked
*    from MTL Email Service. Any attachments coming from email will replace the existing attachment on the monthly tracking log record.
*
* 3. Objects referenced
*    - Monthly_Tracking_Log__c
*
* 4. Callouts to additional Components (including their methods) or None:
*    
* 5. Dependant Class(es):
*    - 
*    
*
* 6. Test Class Name: MTL_EmailService_Test
* 
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s): 
*    - Aakash Pal/Sumit Kumar Sourav & Created Date(2024.04.03)
*    - Aakash Pal & Modified Date(2024.09.10) INC0431411(make contract owner same as of parent Quote)
*    - Aakash Pal & Modified Date(2024.09.27) INC0432119(exclude additional attachments & Notes from deletion)
*************************************************************/
Public class MTL_EmailService implements Messaging.InboundEmailHandler {
    Public Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        List<Monthly_Tracking_Log__c> listMTL = new List<Monthly_Tracking_Log__c>();
        Monthly_Tracking_Log__c singleMTL = new Monthly_Tracking_Log__c();
        Map<String, String> mapOldFieldsWValues = new Map<String, String>();
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        String myPlainText= '';   
        myPlainText = email.plainTextBody;

        String subject = '';
        subject = email.subject;
        system.debug('myPlainText: ' + myPlainText);
        String constDocTypeQuote = 'ZQTE,ZPRQ,ZQOS,ZBQ1,ZBQ2,ZBQ3';
        String constDocTypeContract = 'ZCTR,ZPRC,ZCSS,ZOSC,ZBC1,ZBC2,ZBC3,ZW01';
        // Parse data by splitting by row end character.
        List<String> splitValues = myPlainText.split('\\\n');
        
        for(String str: splitValues) {
            if(!String.IsBlank(str) && str!='\n'){
                String fieldLabel = str.substringBetween('(', ')').trim();
                String value;
                if(fieldLabel != NULL) {
                    if(str.Contains(']')){
                        value = str.substringBetween(')', ']').trim();
                    }else{
                        value = str.substringAfter(')').trim();
                    }
                    if(!mapOldFieldsWValues.containsKey(fieldLabel)) {
                        mapOldFieldsWValues.put(fieldLabel,value);
                    }
                    //system.debug('fieldLabel:value ' + fieldLabel + ':' + value);    
                }
            }
        }
        // Assigning MTL data
        if(!mapOldFieldsWValues.isEmpty()) {
            singleMTL.Document_Type__c = mapOldFieldsWValues.get('Document Type'); 
            singleMTL.Document_Number__c = mapOldFieldsWValues.get('Document No');
            singleMTL.Name = mapOldFieldsWValues.get('Document No');
            
            if(mapOldFieldsWValues.get('Description').Length()>255){
                singleMTL.Description__c = mapOldFieldsWValues.get('Description').substring(0, 254);
                singleMTL.Description_Long__c=mapOldFieldsWValues.get('Description');
            }
            else{
                singleMTL.Description__c = mapOldFieldsWValues.get('Description');
            }
            
            singleMTL.Sales_Org__c = mapOldFieldsWValues.get('Sales org');
            
            String custNo=mapOldFieldsWValues.get('Customer no.');
            
            if(custNo!=null){
                List<ERP_Address__c> erplist=[select id,Address_Type__c,fxCustomerNumber_Master__c,ERP_Sales_Org__c from Erp_Address__c where Address_Type__c = 'Sold To' AND fxCustomerNumber_Master__c=:custNo AND ERP_Sales_Org__c=:singleMTL.Sales_Org__c];
                system.debug('erplist '+erplist);
                if(!erplist.isEmpty()) {
                    singleMTL.Customer_Sold_To__c =  erplist[0].Id; 
                }else{
                    singleMTL.Customer_Sold_To__c =null;
                }	
            }
            
            singleMTL.Quote_Creation_Date__c=formatDate(mapOldFieldsWValues.get('Quote start date'));
            singleMTL.Quote_Validity_Date__c=formatDate(mapOldFieldsWValues.get('Quote end date'));
            singleMTL.Discount__c=formatNumber(mapOldFieldsWValues.get('Discount'));
            
            String conEmail=mapOldFieldsWValues.get('Contact email');
            String conEmailUpdated;
            if(conEmail!=null && !String.isblank(conEmail) && conEmail.containsIgnoreCase('mailto')){
                List<String> splitemail = conEmail.split('<');
                conEmailUpdated= splitemail[0]; 
            }else{
                conEmailUpdated= conEmail;  
            }
            singleMTL.Contact_Email__c=conEmailUpdated;
            
            if(conEmailUpdated!=null){
                List<Contact> conlist=[select id from Contact where email=:conEmailUpdated];
                if(!conlist.isEmpty()) {
                    singleMTL.Contact__c =  conlist[0].Id; 
                }else{
                    singleMTL.Contact__c =null;
                }
            }
            
            //singleMTL.Contact_Phone__c=mapOldFieldsWValues.get('Contact Tel.');
            //singleMTL.Contact_Fax__c=mapOldFieldsWValues.get('Contact Fax');
            singleMTL.Lab_Manager_Name__c=mapOldFieldsWValues.get('Lab manager name');
            singleMTL.Lab_Manager_Phone__c=mapOldFieldsWValues.get('Lab manager phone number');
            singleMTL.Lab_Manager_Email__c=mapOldFieldsWValues.get('Lab manager Email');
            singleMTL.Primary_User_Name__c=mapOldFieldsWValues.get('Primary user name');
            singleMTL.Primary_User_Phone__c=mapOldFieldsWValues.get('Primary user phone number');
            singleMTL.Primary_User_Email__c=mapOldFieldsWValues.get('Primary user Email');
            singleMTL.Purchasing_Agent_Name__c=mapOldFieldsWValues.get('Purchasing agent name');
            singleMTL.Purchasing_Agent_Phone__c=mapOldFieldsWValues.get('Purchasing agent phone number');
            singleMTL.Purchasing_Agent_Email__c=mapOldFieldsWValues.get('Purchasing agent email');
            singleMTL.Contract_Admin_Name__c=mapOldFieldsWValues.get('Contract admin name');
            singleMTL.Sales_Rep_1_Name__c=mapOldFieldsWValues.get('Sales rep 1 name');
            singleMTL.Sales_Rep_3_Name__c=mapOldFieldsWValues.get('Sales rep 3 name');
            singleMTL.Sub_District__c=mapOldFieldsWValues.get('Sub district');
            singleMTL.RNW__c=mapOldFieldsWValues.get('RNW');
            singleMTL.Billing_Plan__c=mapOldFieldsWValues.get('Billing plan');
            singleMTL.Contract_Start_Date__c=formatDate(mapOldFieldsWValues.get('Contract start date'));
            singleMTL.Contract_End_Date__c=formatDate(mapOldFieldsWValues.get('Contract end date'));
            singleMTL.Previous_Contract__c=mapOldFieldsWValues.get('Previous contract');
            singleMTL.Calls_On_Contract__c=formatNumber(mapOldFieldsWValues.get('# Calls on contract'));
            singleMTL.Previous_PO__c=mapOldFieldsWValues.get('Previous PO');
            singleMTL.Previous_S_O_Contact_Name__c=mapOldFieldsWValues.get('Contact name from last S/O');
            singleMTL.Previous_S_O_Contact_Phone__c=mapOldFieldsWValues.get('Contact tel. from last S/O');
            singleMTL.Sales_Order_Equipment_Shipped__c=mapOldFieldsWValues.get('Equipment shipped on sales order');
            singleMTL.Previous_Billing_Plan__c=mapOldFieldsWValues.get('Previous billing plan');
            singleMTL.Previous_Contract_Start_Date__c=formatDate(mapOldFieldsWValues.get('Previous Contract start date'));
            singleMTL.Previous_Contract_End_Date__c=formatDate(mapOldFieldsWValues.get('Previous Contract end date'));
            singleMTL.Maintenance_Planner_Group__c=mapOldFieldsWValues.get('MPG');
            singleMTL.Rejection_Reason_Code__c=mapOldFieldsWValues.get('Rejection Reason code');
            singleMTL.Rejection_Reason_Description__c=mapOldFieldsWValues.get('Rejection Reason description');
            singleMTL.Model_Serial__c=mapOldFieldsWValues.get('Model/Serial');
            singleMTL.Zone__c=mapOldFieldsWValues.get('Zone');
            singleMTL.CurrencyIsoCode=mapOldFieldsWValues.get('Currency');
            singleMTL.Net_Price__c=formatNumber(mapOldFieldsWValues.get('Net price'));
            singleMTL.Tax__c=formatNumber(mapOldFieldsWValues.get('Tax'));
            singleMTL.Total_Inc_Tax__c=formatNumber(mapOldFieldsWValues.get('Total inc tax'));
            singleMTL.Value_Of_New_Items__c=formatNumber(mapOldFieldsWValues.get('Value of new items'));
            singleMTL.Previous_Contract_Value__c=formatNumber(mapOldFieldsWValues.get('Previous contract value'));
            singleMTL.Previous_Discount__c=formatNumber(mapOldFieldsWValues.get('Previous Discount'));
            singleMTL.Product_Line__c=mapOldFieldsWValues.get('Product Line');
            singleMTL.Plan_Type__c=mapOldFieldsWValues.get('Plan type');
            singleMTL.Previous_Document_Type__c=mapOldFieldsWValues.get('Previous document type');
            singleMTL.Unique_Models__c=mapOldFieldsWValues.get('UniqueModels');
            singleMTL.Unique_Models_In_Rampdown__c=mapOldFieldsWValues.get('UniqueModelsinrampdown');
            singleMTL.Unique_Models_EOL__c=mapOldFieldsWValues.get('UniqueModelsEOL');
            singleMTL.Multi_Vendormodels__c=mapOldFieldsWValues.get('Multi-vendormodels');
            singleMTL.Original_Quote_Number__c=mapOldFieldsWValues.get('Original quote number');
            singleMTL.SAP_Created_By__c=mapOldFieldsWValues.get('Created by');
            singleMTL.SAP_Created_On__c=formatDate(mapOldFieldsWValues.get('Created on'));
            singleMTL.Header_Billing_Plan__c=mapOldFieldsWValues.get('Header billing plan');
            singleMTL.PO_Number__c=mapOldFieldsWValues.get('PO Number');
            singleMTL.PO_Date__c=formatDate(mapOldFieldsWValues.get('PO Date'));
            singleMTL.Net_Value__c=formatNumber(mapOldFieldsWValues.get('Net value'));
            String prevContract=String.isBlank(mapOldFieldsWValues.get('Previous contract'))? '':mapOldFieldsWValues.get('Previous contract').trim();
            String orgnlQuotenmbr=String.isBlank(mapOldFieldsWValues.get('Original quote number'))?'':mapOldFieldsWValues.get('Original quote number').trim();
            
            //LKUP Parent Master Logic
            if(prevContract!=null && constDocTypeQuote.containsIgnoreCase(singleMTL.document_Type__c)){ 
                list<Monthly_Tracking_Log__c> quoteparentlist=[Select id,LKUP_Parent__c,LKUP_Master__c,fxMTLType__c,fxIsMaster__c,Document_Number__c 
                                                               from Monthly_Tracking_Log__c where Document_Number__c = :prevContract AND fxMTLType__c='CONTRACT'];
                system.debug('quoteparentlist '+quoteparentlist);
                if(!quoteparentlist.isEmpty()) {
                    singleMTL.LKUP_Parent__c =  quoteparentlist[0].Id;
                    if(quoteparentlist[0].fxIsMaster__c){
                        singleMTL.LKUP_Master__c =  quoteparentlist[0].Id;
                    }else{
                        singleMTL.LKUP_Master__c =  quoteparentlist[0].LKUP_Master__c;
                    }
                    
                }else{
                    singleMTL.LKUP_Parent__c =null;
                    singleMTL.LKUP_Master__c =null;
                }	
            }
            system.debug('singleMTL.document_Type__c' + singleMTL.document_Type__c);
            if(orgnlQuotenmbr!=null && constDocTypeContract.containsIgnoreCase(singleMTL.document_Type__c)){
                list<Monthly_Tracking_Log__c> contractparentlist= [Select id,LKUP_Parent__c,LKUP_Master__c,fxIsMaster__c,fxMTLType__c,Document_Number__c,OwnerId 
                                                                   from Monthly_Tracking_Log__c where Document_Number__c = :orgnlQuotenmbr AND fxMTLType__c='QUOTE'];
                
                system.debug('contractparentlist '+contractparentlist);
                if(!contractparentlist.isEmpty()) {
                    singleMTL.LKUP_Parent__c =  contractparentlist[0].Id;
                    singleMTL.OwnerId = contractparentlist[0].OwnerId;		//INC0431411 - make contract owner same as of parent Quote
                    if(contractparentlist[0].fxIsMaster__c){
                        singleMTL.LKUP_Master__c =  contractparentlist[0].Id;
                    }else{
                        singleMTL.LKUP_Master__c =  contractparentlist[0].LKUP_Master__c;
                    }
                }else{
                    singleMTL.LKUP_Parent__c =null;
                    singleMTL.LKUP_Master__c =null;
                }	
            }
            
            upsert singleMTL Document_Number__c;
        }
        
        //Insert Chatter Feed
        
        FeedItem feed = new FeedItem();
        feed.ParentId =  singleMTL.Id;
        feed.Body = 'SUBJECT : '+email.subject +'\n'+ 'BODY : '+'\n'+ email.plainTextBody;
        insert feed;
        
        system.debug('email.binaryAttachments '+email.binaryAttachments);
        
        if(email.binaryAttachments != null){
            // Delete existing Content Document
            List<ContentDocumentLink> del_contentDocumentLinkList=[SELECT id,contentdocumentid,linkedentityid FROM ContentDocumentLink WHERE linkedentityid=:singleMTL.Id ];
            List<Id> del_contentDocumentIdList=new List<Id>();
            Set<String> newTitleSet = new Set<String>();
            // Insert attachments as content document link
            for (Messaging.InboundEmail.BinaryAttachment binAttach : email.binaryAttachments) {
                system.debug('@@binAttach.fileName= '+binAttach.fileName);
                ContentVersion contentVersion_1 = new ContentVersion(
                    Title=binAttach.fileName, 
                    PathOnClient =binAttach.fileName,
                    VersionData = binAttach.body
                );
                newTitleSet.add(binAttach.fileName);
                contentVersionList.add(contentVersion_1);
            }
            //INC0432119 - exclude additional attachments & Notes from deletion
            If(del_contentDocumentLinkList.size()>0 && !del_contentDocumentLinkList.isEmpty()){
                for(ContentDocumentLink cdl:del_contentDocumentLinkList){
                    del_contentDocumentIdList.add(cdl.contentdocumentid);
                }
                List<ContentDocument> del_contentDocumentList=[select id from ContentDocument where Id IN: del_contentDocumentIdList AND FileType != 'SNOTE' AND Title IN :newTitleSet];
                If(!del_contentDocumentList.isEmpty()){ 
                    delete del_contentDocumentList;
                }
            }
            
            if(!contentVersionList.isEmpty()){
                system.debug('contentversion '+contentVersionList);
                insert contentVersionList;
            } 
        }
        List<Id> contentVersionIdList=new List<Id>();
        
        for(ContentVersion c:contentVersionList){
            contentVersionIdList.add(c.Id);
        }
        List<ContentVersion> contentVersionDocIdList=new List<ContentVersion>();
        contentVersionDocIdList=[Select id,ContentDocumentId from ContentVersion where id IN:contentVersionIdList];
        for(ContentVersion cv:contentVersionDocIdList){
            ContentDocumentLink contentlink = new ContentDocumentLink();
            contentlink.LinkedEntityId = singleMTL.id;
            contentlink.contentdocumentid = cv.contentdocumentid;
            contentlink.ShareType = 'V';
            contentDocumentLinkList.add(contentlink);
        }
        if(!contentDocumentLinkList.isEmpty()){
            system.debug('contentDocumentLinkList '+contentDocumentLinkList);
            insert contentDocumentLinkList;
        }
        // Content document link insertion completed.
        
        result.success = true;
        return result;
    }
    // To parse date
    public Date formatDate(String dateString){
        if(dateString != NULL && dateString!='00000000' && !String.isblank(dateString)) {
            Integer year=Integer.Valueof(dateString.mid(0,4));
            Integer month=Integer.Valueof(dateString.mid(4,2));
            Integer day=Integer.Valueof(dateString.mid(6,2));
            return date.newInstance(year, month, day);
        }
        else {
            return NULL; 
        }
        
    }
    // To parse number
    public Double formatNumber(String numberString){
        if(numberString != NULL && !String.isblank(numberString)) {
            system.debug('numberStringg' + numberString);
            Double numbr;
            If(numberString.contains('-')){
                String str= numberString.replace('-','');
                numbr=Double.Valueof(str)*-1;  
            }else{
                numbr=Double.Valueof(numberString);   
            }
            return numbr; 
        }
        else {
            return NULL;
        }
    }
}