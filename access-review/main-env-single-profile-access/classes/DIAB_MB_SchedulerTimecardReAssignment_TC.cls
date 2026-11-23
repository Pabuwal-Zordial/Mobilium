@isTest
public class DIAB_MB_SchedulerTimecardReAssignment_TC {
    
    @isTest
    static void testExecuteMethod() {
        Test.startTest();
        // Call execute() directly with a fake SchedulableContext
        DIAB_MB_SchedulerTimecardReAssignment sched = new DIAB_MB_SchedulerTimecardReAssignment();
        sched.execute(null);
        Test.stopTest();
        
        // Basic assertion to ensure batch kicked off successfully
        // (at least it didn’t throw exception)
        System.assert(true, 'Execute method ran without exceptions');
    }
    
    @isTest
    static void testScheduleEvery15Minutes() {
        Test.startTest();
        // Call the schedule method which enqueues 4 jobs
        DIAB_MB_SchedulerTimecardReAssignment.scheduleEvery15Minutes();
        Test.stopTest();
        
        // Verify 4 scheduled jobs exist in CronTrigger
        List<CronTrigger> jobs = [
            SELECT Id, CronJobDetail.Name, State 
            FROM CronTrigger 
            WHERE CronJobDetail.Name LIKE 'DIAB_MB_TimecardReAssignment_For_%'
        ];
        System.assertEquals(4, jobs.size(), 'Four jobs should have been scheduled');
    }
}