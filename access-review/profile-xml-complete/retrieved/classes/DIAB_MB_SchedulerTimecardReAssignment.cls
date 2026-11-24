global class DIAB_MB_SchedulerTimecardReAssignment implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        // Execute the batch job with a scope size of 200
        Database.executeBatch(new DIAB_MB_BatchTimecardReAssignmentFeature(), 200);
    }
    public static void scheduleEvery15Minutes() {
        // Schedule the job
        System.schedule('DIAB_MB_TimecardReAssignment_For_0_Minute', '0 0 * * * ?', new DIAB_MB_SchedulerTimecardReAssignment());
        System.schedule('DIAB_MB_TimecardReAssignment_For_15_Minute', '0 15 * * * ?', new DIAB_MB_SchedulerTimecardReAssignment());
        System.schedule('DIAB_MB_TimecardReAssignment_For_30_Minute', '0 30 * * * ?', new DIAB_MB_SchedulerTimecardReAssignment());
        System.schedule('DIAB_MB_TimecardReAssignment_For_45_Minute', '0 45 * * * ?', new DIAB_MB_SchedulerTimecardReAssignment());
    }
}