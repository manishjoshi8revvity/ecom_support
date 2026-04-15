@isTest
public class ECOM_OrderCreateScheduler_Test {
    @isTest
    public static void orderCreateScheduleTest(){
        Test.startTest();
        // Create an instance of the Schedulable class
        ECOM_OrderCreateScheduler schedulableInstance = new ECOM_OrderCreateScheduler();
        String chron = '0 0 23 * * ?'; 
        String jobid = System.schedule('Test ECOM_OrderCreateScheduler', chron, schedulableInstance);
        Test.stopTest();
    }
}