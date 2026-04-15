@isTest
public class ECOM_OrderActivateScheduler_Test {
    @isTest
    public static void orderCreateScheduleTest(){
        Test.startTest();
        // Create an instance of the Schedulable class
        ECOM_OrderActivateScheduler schedulableInstance = new ECOM_OrderActivateScheduler();
        String chron = '0 0 23 * * ?'; 
        String jobid = System.schedule('Test ECOM_OrderActivateScheduler', chron, schedulableInstance);
        Test.stopTest();
    }
}