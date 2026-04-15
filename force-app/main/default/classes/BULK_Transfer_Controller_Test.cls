@istest
public class BULK_Transfer_Controller_Test {
 static testmethod void myTestMethod1(){
     list<BULK_Transfer_Controller.labelandapi> wraplist=  BULK_Transfer_Controller.fetchsobjectname();
        BULK_Transfer_Controller.fetchobjectandfld('Opportunity');
        BULK_Transfer_Controller.fetchObjectRecords('Opportunity','100',userinfo.getUserId());
        BULK_Transfer_Controller.fetchuserinfo();
     	BULK_Transfer_Controller.fetchgroupinfo('Interaction');
     List<Contact> conlist = new list<contact>();
     contact con = new contact();
     con.lastname='test name';
     conlist.add(con);
     insert conlist;
     BULK_Transfer_Controller.UpdateRecords(conlist,userinfo.getuserId(),'sobjectname','fromuser','touser','selectedrec','totalrecords','wherestr');
     BULK_Transfer_Controller.createSFDCLog('Account','test user','New User','09','30','');
     
    }
}