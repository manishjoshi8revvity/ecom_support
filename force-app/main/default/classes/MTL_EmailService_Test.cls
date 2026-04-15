/**************************************************************
* 1. Jira Ticket(s)
*    - MTL-1 Monthly Tracking Log
*
* 2. Description - This apex class is used to test MTL_EmailService.
*
* 3. Objects referenced
*    - Monthly_Tracking_Log__c
*
* 4. Callouts to additional Components (including their methods) or None:
*    
* 5. Dependant Class(es):
*    - MTL_EmailService
*    
*
* 6. Test Class Name: 
* 
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s): 
*    - Sumit Kumar Sourav & Created Date(2024.04.19)
*    -
*************************************************************/
@istest
public class MTL_EmailService_Test {
    
    public static testMethod void TestinBoundEmail() {
        
        Test.startTest();
        
        Account acc=new Account();
        acc.name='Test Account';
        insert acc;
        
        Contact con=new Contact();
        con.lastname='test';
        con.email='scott.greenwood@revvity.com';
        con.accountId=acc.Id;
        insert con;
        
        Erp_Address__c erp1=new Erp_Address__c();
        erp1.Address_Type__c = 'Master';
        erp1.ERP_Sales_Org__c='US10';
        erp1.ERP_Customer_Number__c='0100861477';
        insert erp1;
        
        Erp_Address__c erp2=new Erp_Address__c();
        erp2.Address_Type__c = 'Sold To';
        erp2.ERP_Sales_Org__c='US10';
        erp2.Master_Address__c=erp1.Id;
        insert erp2;
        
        String sapdata1='(Document Type)ZQTE][\n(Document No)0040861501][\n(Description)SEE COVERAGE PLAN(S) BELOW][\n';
        String sapdata2='(Sales org)US10][\n(Customer no.)0100861477][\n(Name1)Merck Sharp & Dohme LLC][\n(Name2)][\n(Name3)][\n(Name4)][\n(Street)770 Sumneytown Pike][\n(City1)West Point][\n(District)][\n';
        String sapdata3='(State)PA][\n(Postcode)19486-8000][\n(Country)USA][\n(Contact) Scott Greenwood][\n(Contact Tel.) +16142739158 ; ][\n(Contact Fax) ][\n(Contact email)scott.greenwood@revvity.com<mailto>][\n(Lab manager name)Test Lab Manager Name][\n';
        String sapdata4='(Lab manager phone number ) Test Lab Manager Phone][\n(Lab manager Email) Test Lab Manager Email][\n(Primary user name ) Test][\n(Primary user phone number ) Test][\n(Primary user Email) Test][\n(Purchasing agent name  ) Test5][\n';
        String sapdata5='(Purchasing agent phone number ) Test ][\n(Purchasing agent email) Test][\n(Contract admin name )LUCAS GILLESPIE][\n(Sales rep 1 name) Test][\n(Sales rep 3 name) Test][\n(Sub district)USPA03][\n(RNW)N][\n';
        String sapdata6='(Billing plan)58][\n(Quote start date)20240327][\n(Quote end date)20240530][\n(Contract start date)20240401][\n(Contract end date)20250331][\n(Previous contract) 0035602900][\n(# Calls on contract)5][\n(Previous PO) Previous PO Test][\n';
        String sapdata7='(Contact name from last S/O) Contact name from last S/O Test][\n(Contact tel. from last S/O) Contact tel. from last S/O Test][\n(Equipment shipped on sales order)Yes][\n(Previous billing plan) Test][\n(Previous Contract start date)20230101][\n(Previous Contract end date)20231231][\n';
        String sapdata8='(MPG)LMA][\n(Rejection Reason code) Test][\n(Rejection Reason description) Test][\n(Model/Serial)FLOW1BETA525/415647,;FLOW1BETA525/422068,;FLOW1BETA525/430550,;PROFSA625HOM/434373,;HARVESTER96/551064,;HARVESTER96/551433,;MLD2103-8450/1050698,;OPERAHH2010100/1646007,;NAP2024-0020/202][\n(Zone)Z1][\n(Currency)USD][\n';
        String sapdata9='(Net price)1028978.82][\n(Tax)100.00-][\n(Total inc tax)1028978.82][\n(Discount)566337.18][\n(Value of new items)1028978.82][\n(Previous contract value)10.00][\n(Previous Discount)10.00][\n(Product Line)ARS,AWS,HCS,INV,MFT,MLD,NAP,RRD,][\n(Plan type)ZJ00][\n(Previous document type) Previous document type Test][\n';
        String sapdata10='(UniqueModels)ARSHH20110174;AWSYJL8001;AWSYJS8001;AWSYJSM001;ENSPIRE2390-0000;HARVESTER96;HCSHH14000000;HCSHH14001000;HCSHH16000000;I235;INVCLS136334;INVCLS148588;IVISSPECTRUM;IVISSPECTRUMCT;MFTCLS137][\n(UniqueModelsinrampdown)MLD2103-8450;VICTOR2030-0040;][\n(UniqueModelsEOL)FLOW1BETA525;PROFSA625HOM;][\n(Multi-vendormodels) Multi-vendormodels Test][\n';
        String sapQuoteData1=sapdata1+sapdata2+sapdata3+sapdata4+sapdata5+sapdata6+sapdata7+sapdata8+sapdata9+sapdata10;
        
        String sapContractData1='(Document Type)ZCTR][\n(Document No)0035602500][\n(Description)Test - Invoice popup][\n(Contract start date)20240101][\n(Contract end date)20241231][\n(Original quote number) 0040861501][\n(Created by)SHAHSN][\n(Created on)20240228][\n(Header billing plan)55][\n(PO Number)Test - Invoice popup][\n(PO Date)20240415][\n(Net value)2520.00][\n';
        String sapContractData2='(Document Type)ZCTR][\n(Document No)0035602501][\n(Description)Test - Invoice popup][\n(Contract start date)20240101][\n(Contract end date)20241231][\n(Original quote number) ][\n(Created by)SHAHSN][\n(Created on)20240228][\n(Header billing plan)55][\n(PO Number)Test - Invoice popup][\n(PO Date)20240415][\n(Net value)2520.00][\n';
        
        String sapdata11='(Document Type)ZQTE][\n(Document No)0040861503][\n(Description)SEE COVERAGE PLAN(S) BELOW1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111][\n';
        String sapdata12='(Sales org)US10][\n(Customer no.)0100861478][\n(Name1)Merck Sharp & Dohme LLC][\n(Name2)][\n(Name3)][\n(Name4)][\n(Street)770 Sumneytown Pike][\n(City1)West Point][\n(District)][\n';
        String sapdata13='(State)PA][\n(Postcode)19486-8000][\n(Country)USA][\n(Contact) Scott Greenwood][\n(Contact Tel.) +16142739158 ; ][\n(Contact Fax) ][\n(Contact email)scot.greenwood@revvity.com<mailto>][\n(Lab manager name)Test Lab Manager Name][\n';
        String sapdata14='(Lab manager phone number ) Test Lab Manager Phone][\n(Lab manager Email) Test Lab Manager Email][\n(Primary user name ) Test][\n(Primary user phone number ) Test][\n(Primary user Email) Test][\n(Purchasing agent name  ) Test5][\n';
        String sapdata15='(Purchasing agent phone number ) Test ][\n(Purchasing agent email) Test][\n(Contract admin name )LUCAS GILLESPIE][\n(Sales rep 1 name) Test][\n(Sales rep 3 name) Test][\n(Sub district)USPA03][\n(RNW)N][\n';
        String sapdata16='(Billing plan)58][\n(Quote start date)20240327][\n(Quote end date)20240530][\n(Contract start date)20240401][\n(Contract end date)20250331][\n(Previous contract) 0035602500][\n(# Calls on contract)5][\n(Previous PO) Previous PO Test][\n';
        String sapdata17='(Contact name from last S/O) Contact name from last S/O Test][\n(Contact tel. from last S/O) Contact tel. from last S/O Test][\n(Equipment shipped on sales order)Yes][\n(Previous billing plan) Test][\n(Previous Contract start date)20230101][\n(Previous Contract end date)20231231][\n';
        String sapdata18='(MPG)LMA][\n(Rejection Reason code) Test][\n(Rejection Reason description) Test][\n(Model/Serial)FLOW1BETA525/415647,;FLOW1BETA525/422068,;FLOW1BETA525/430550,;PROFSA625HOM/434373,;HARVESTER96/551064,;HARVESTER96/551433,;MLD2103-8450/1050698,;OPERAHH2010100/1646007,;NAP2024-0020/202][\n(Zone)Z1][\n(Currency)USD][\n';
        String sapdata19='(Net price)1028978.82][\n(Tax)100.00-][\n(Total inc tax)1028978.82][\n(Discount)566337.18][\n(Value of new items)1028978.82][\n(Previous contract value)10.00][\n(Previous Discount)10.00][\n(Product Line)ARS,AWS,HCS,INV,MFT,MLD,NAP,RRD,][\n(Plan type)ZJ00][\n(Previous document type) Previous document type Test][\n';
        String sapdata20='(UniqueModels)ARSHH20110174;AWSYJL8001;AWSYJS8001;AWSYJSM001;ENSPIRE2390-0000;HARVESTER96;HCSHH14000000;HCSHH14001000;HCSHH16000000;I235;INVCLS136334;INVCLS148588;IVISSPECTRUM;IVISSPECTRUMCT;MFTCLS137][\n(UniqueModelsinrampdown)MLD2103-8450;VICTOR2030-0040;][\n(UniqueModelsEOL)FLOW1BETA525;PROFSA625HOM;][\n(Multi-vendormodels) Multi-vendormodels Test][\n';
        String sapQuoteData2=sapdata11+sapdata12+sapdata13+sapdata14+sapdata15+sapdata16+sapdata17+sapdata18+sapdata19+sapdata20;
        
        String sapContractData3='(Document Type)ZCTR][\n(Document No)0035602502][\n(Description)Test - Invoice popup][\n(Contract start date)20240101][\n(Contract end date)20241231][\n(Original quote number)0040861503 ][\n(Created by)SHAHSN][\n(Created on)20240228][\n(Header billing plan)55][\n(PO Number)Test - Invoice popup][\n(PO Date)20240415][\n(Net value)2520.00][\n';
        
        String sapdata21='(Document Type)ZQTE][\n(Document No)0040861504][\n(Description)SEE COVERAGE PLAN BELOW1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111][\n';
        String sapdata22='(Sales org)US10][\n(Customer no.)0100861477][\n(Name1)Merck Sharp & Dohme LLC][\n(Name2)][\n(Name3)][\n(Name4)][\n(Street)770 Sumneytown Pike][\n(City1)West Point][\n(District)][\n';
        String sapdata23='(State)PA][\n(Postcode)19486-8000][\n(Country)USA][\n(Contact) Scott Greenwood][\n(Contact Tel.) +16142739158 ; ][\n(Contact Fax) ][\n(Contact email)scot.greenwood@revvity.com<mailto>][\n(Lab manager name)Test Lab Manager Name][\n';
        String sapdata24='(Lab manager phone number ) Test Lab Manager Phone][\n(Lab manager Email) Test Lab Manager Email][\n(Primary user name ) Test][\n(Primary user phone number ) Test][\n(Primary user Email) Test][\n(Purchasing agent name  ) Test5][\n';
        String sapdata25='(Purchasing agent phone number ) Test ][\n(Purchasing agent email) Test][\n(Contract admin name )LUCAS GILLESPIE][\n(Sales rep 1 name) Test][\n(Sales rep 3 name) Test][\n(Sub district)USPA03][\n(RNW)N][\n';
        String sapdata26='(Billing plan)58][\n(Quote start date)20240327][\n(Quote end date)20240530][\n(Contract start date)20240401][\n(Contract end date)20250331][\n(Previous contract) 0035602501][\n(# Calls on contract)5][\n(Previous PO) Previous PO Test][\n';
        String sapdata27='(Contact name from last S/O) Contact name from last S/O Test][\n(Contact tel. from last S/O) Contact tel. from last S/O Test][\n(Equipment shipped on sales order)Yes][\n(Previous billing plan) Test][\n(Previous Contract start date)20230101][\n(Previous Contract end date)20231231][\n';
        String sapdata28='(MPG)LMA][\n(Rejection Reason code) Test][\n(Rejection Reason description) Test][\n(Model/Serial)FLOW1BETA525/415647,;FLOW1BETA525/422068,;FLOW1BETA525/430550,;PROFSA625HOM/434373,;HARVESTER96/551064,;HARVESTER96/551433,;MLD2103-8450/1050698,;OPERAHH2010100/1646007,;NAP2024-0020/202][\n(Zone)Z1][\n(Currency)USD][\n';
        String sapdata29='(Net price)1028978.82][\n(Tax)100.00-][\n(Total inc tax)1028978.82][\n(Discount)566337.18][\n(Value of new items)1028978.82][\n(Previous contract value)10.00][\n(Previous Discount)10.00][\n(Product Line)ARS,AWS,HCS,INV,MFT,MLD,NAP,RRD,][\n(Plan type)ZJ00][\n(Previous document type) Previous document type Test][\n';
        String sapdata30='(UniqueModels)ARSHH20110174;AWSYJL8001;AWSYJS8001;AWSYJSM001;ENSPIRE2390-0000;HARVESTER96;HCSHH14000000;HCSHH14001000;HCSHH16000000;I235;INVCLS136334;INVCLS148588;IVISSPECTRUM;IVISSPECTRUMCT;MFTCLS137(UniqueModelsinrampdown)MLD2103-8450;VICTOR2030-0040;\n(UniqueModelsEOL)FLOW1BETA525;PROFSA625HOM;][\n(Multi-vendormodels) Multi-vendormodels Test][\n';
        String sapQuoteData3=sapdata21+sapdata22+sapdata23+sapdata24+sapdata25+sapdata26+sapdata27+sapdata28+sapdata29+sapdata30;
        
        MTL_EmailService_Test.draftInboundemail(sapQuoteData1);
        MTL_EmailService_Test.draftInboundemail(sapQuoteData1);
        MTL_EmailService_Test.draftInboundemail(sapContractData1);
        MTL_EmailService_Test.draftInboundemail(sapQuoteData2);
        MTL_EmailService_Test.draftInboundemail(sapContractData2);
        MTL_EmailService_Test.draftInboundemail(sapContractData3);
        MTL_EmailService_Test.draftInboundemail(sapQuoteData3);
        
        Test.stopTest();
        
    }
    public static void draftInboundemail(String str) {
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        // intialize the list string to store emails.
        List<string> emails = new List<string>{'test12@revvity.com','test123@revvity.com'};  
        email.subject = 'Parse MTL Data';
        email.fromAddress = 'testaddress@revvity.com';
        //assigning the emails to toAddresses 
        email.toAddresses = emails;
        email.plainTextBody = str;
        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = 'textfileone.txt';
        attachment.mimeTypeSubType = 'text/plain';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };
        MTL_EmailService  testInbound=new MTL_EmailService();
        testInbound.handleInboundEmail(email, env);
    }
}